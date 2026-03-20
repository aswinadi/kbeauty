<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Bundle;
use App\Models\Customer;
use App\Models\Employee;
use App\Models\GeneralSetting;
use App\Models\InventoryMovement;
use App\Models\PosPayment;
use App\Models\PosTransaction;
use App\Models\PosTransactionItem;
use App\Models\Product;
use App\Models\Service;
use App\Models\Shift;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class PosController extends Controller
{
    public function items()
    {
        $services = Service::where('is_active', true)->with('serviceCategory')->get()->map(fn($s) => [
            'id' => $s->id,
            'name' => $s->name,
            'price' => $s->price,
            'type' => 'service',
            'category' => $s->serviceCategory?->name,
        ]);

        $products = Product::where('is_active', true)->with('category')->get()->map(fn($p) => [
            'id' => $p->id,
            'name' => $p->name,
            'price' => $p->price,
            'type' => 'product',
            'category' => $p->category?->name,
        ]);

        $bundles = Bundle::where('is_active', true)->get()->map(fn($b) => [
            'id' => $b->id,
            'name' => $b->name,
            'price' => $b->price,
            'type' => 'bundle',
            'category' => 'Bundle',
        ]);

        return response()->json($services->concat($products)->concat($bundles)->values());
    }

    public function customers(Request $request)
    {
        $search = $request->search;
        $query = Customer::query();

        if ($search) {
            $query->where('name', 'like', "%{$search}%")
                  ->orWhere('phone', 'like', "%{$search}%");
        }

        return response()->json($query->limit(20)->get());
    }

    public function showCustomer(Customer $customer)
    {
        return response()->json($customer->load(['memberships', 'portfolios.media']));
    }

    public function customerPortfolios(Customer $customer)
    {
        return response()->json($customer->portfolios()->with('media')->orderBy('created_at', 'desc')->get()->map(function($p) {
            $p->image_urls = $p->getMedia('portfolio_images')->map(fn($m) => $m->getUrl());
            return $p;
        }));
    }

    public function addCustomerPortfolio(Request $request, Customer $customer)
    {
        $request->validate([
            'notes' => 'nullable|string',
            'images.*' => 'nullable|image|max:5120',
            'pos_transaction_id' => 'nullable|exists:pos_transactions,id',
        ]);

        $portfolio = new \App\Models\CustomerPortfolio([
            'notes' => $request->notes,
            'pos_transaction_id' => $request->pos_transaction_id,
        ]);

        $customer->portfolios()->save($portfolio);

        if ($request->hasFile('images')) {
            foreach ($request->file('images') as $image) {
                $portfolio->addMedia($image)->toMediaCollection('portfolio_images');
            }
        }

        return response()->json($portfolio->load('media'), 201);
    }

    public function customerHistory(Customer $customer)
    {
        $transactions = $customer->posTransactions()
            ->with(['items.item', 'portfolios.media'])
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json($transactions);
    }

    public function registerCustomer(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'phone' => 'nullable|string|max:255',
            'email' => 'nullable|email|max:255',
        ]);

        $customer = Customer::create($request->all());

        return response()->json($customer, 201);
    }

    public function employees()
    {
        return response()->json(Employee::where('status', 'active')->get());
    }

    public function storeTransaction(Request $request)
    {
        $request->validate([
            'customer_id' => 'nullable|exists:customers,id',
            'items' => 'required|array|min:1',
            'items.*.item_id' => 'required',
            'items.*.item_type' => 'required|in:service,product,bundle',
            'items.*.employee_id' => 'required|exists:employees,id',
            'items.*.quantity' => 'required|integer|min:1',
            'discount_amount' => 'nullable|numeric|min:0',
            'payments' => 'required|array|min:1',
            'payments.*.payment_method' => 'required|string',
            'payments.*.amount' => 'required|numeric|min:0',
        ]);

        return DB::transaction(function () use ($request) {
            $shift = Shift::where('status', 'open')->orderBy('start_time', 'desc')->first();
            if (!$shift) {
                return response()->json(['message' => 'No active shift found. Please start a shift first.'], 422);
            }

            $totalAmount = 0;
            $transactionItems = [];

            foreach ($request->items as $i) {
                $modelClass = match ($i['item_type']) {
                    'service' => Service::class,
                    'product' => Product::class,
                    'bundle' => Bundle::class,
                };

                $itemModel = $modelClass::find($i['item_id']);
                if (!$itemModel) {
                    throw new \Exception("Item {$i['item_id']} of type {$i['item_type']} not found.");
                }

                $subtotal = $itemModel->price * $i['quantity'];
                $totalAmount += $subtotal;

                $transactionItems[] = [
                    'item_id' => $i['item_id'],
                    'item_type' => $modelClass,
                    'employee_id' => $i['employee_id'],
                    'quantity' => $i['quantity'],
                    'price' => $itemModel->price,
                    'subtotal' => $subtotal,
                ];
            }

            $discount = $request->discount_amount ?? 0;
            $finalAmount = max(0, $totalAmount - $discount);

            $transaction = PosTransaction::create([
                'transaction_number' => 'POS-' . date('YmdHis') . '-' . Str::upper(Str::random(4)),
                'customer_id' => $request->customer_id,
                'shift_id' => $shift->id,
                'total_amount' => $totalAmount,
                'discount_amount' => $discount,
                'final_amount' => $finalAmount,
                'status' => 'completed',
            ]);

            // Loyalty Points: 1 point for every Rp 100,000 spent
            if ($transaction->customer_id) {
                $points = floor($finalAmount / 100000);
                if ($points > 0) {
                    $transaction->customer->increment('loyalty_points', $points);
                }
            }

            foreach ($transactionItems as $ti) {
                $item = $transaction->items()->create($ti);
                $this->processItemStock($item);
            }

            foreach ($request->payments as $p) {
                $transaction->payments()->create($p);
            }

            return response()->json($transaction->load('items', 'payments'), 201);
        });
    }

    protected function processItemStock($item)
    {
        $settings = GeneralSetting::first();
        $locationId = $settings?->pos_display_location_id;
        if (!$locationId) return;

        $type = $item->item_type;
        $model = $item->item;

        if ($type === Product::class) {
            $this->deductStock($model->id, $item->quantity, $locationId, $item->pos_transaction_id);
        } elseif ($type === Service::class && $model->deduct_stock) {
            foreach ($model->materials as $material) {
                $this->deductStock($material->product_id, $material->quantity * $item->quantity, $locationId, $item->pos_transaction_id);
            }
        } elseif ($type === Bundle::class) {
            foreach ($model->items as $bundleItem) {
                if ($bundleItem->item_type === Product::class) {
                    $this->deductStock($bundleItem->item_id, $bundleItem->quantity * $item->quantity, $locationId, $item->pos_transaction_id);
                } elseif ($bundleItem->item_type === Service::class && $bundleItem->item->deduct_stock) {
                    foreach ($bundleItem->item->materials as $material) {
                        $this->deductStock($material->product_id, $material->quantity * $bundleItem->quantity * $item->quantity, $locationId, $item->pos_transaction_id);
                    }
                }
            }
        }
    }

    protected function deductStock($productId, $qty, $locationId, $transactionId)
    {
        InventoryMovement::create([
            'product_id' => $productId,
            'from_location_id' => $locationId,
            'qty' => $qty,
            'type' => 'pos_out',
            'user_id' => auth()->id(),
            'reference_id' => $transactionId,
            'reference_type' => PosTransaction::class,
        ]);
    }

    public function performance(Request $request)
    {
        $user = auth()->user();
        if (!$user->employee) {
            return response()->json(['message' => 'User is not an employee.'], 403);
        }

        $employeeId = $user->employee->id;
        $fromDate = $request->from_date ?? now()->startOfMonth()->toDateString();
        $toDate = $request->to_date ?? now()->endOfMonth()->toDateString();

        $items = PosTransactionItem::where('employee_id', $employeeId)
            ->whereHas('posTransaction', function ($q) use ($fromDate, $toDate) {
                $q->whereBetween('created_at', [$fromDate . ' 00:00:00', $toDate . ' 23:59:59']);
            })
            ->with(['item', 'posTransaction'])
            ->get();

        $totalCommission = $items->sum(fn($i) => $i->commission);

        return response()->json([
            'employee' => $user->employee,
            'period' => [
                'from' => $fromDate,
                'to' => $toDate,
            ],
            'total_services' => $items->count(),
            'total_commission' => $totalCommission,
            'details' => $items->map(fn($i) => [
                'date' => $i->posTransaction->created_at->toDateTimeString(),
                'item_name' => $i->item?->name ?? 'Unknown',
                'subtotal' => $i->subtotal,
                'commission' => $i->commission,
            ]),
        ]);
    }
}
