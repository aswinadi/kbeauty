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
use App\Models\PosShift as Shift;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class PosController extends Controller
{
    public function settings()
    {
        return response()->json(GeneralSetting::first());
    }

    public function items()
    {
        $services = Service::where('is_active', true)
            ->whereHas('serviceCategory', function($q) {
                $q->where('is_active', true);
            })
            ->with(['serviceCategory', 'variants'])->orderBy('name')->get()->map(fn($s) => [
            'id' => $s->id,
            'name' => $s->name,
            'price' => $s->price,
            'is_variable_price' => (bool)$s->is_variable_price,
            'type' => 'service',
            'category' => $s->serviceCategory?->name,
            'variants' => $s->variants->map(fn($v) => [
                'id' => $v->id,
                'name' => $v->name,
                'price' => $v->price,
            ]),
        ]);

        $products = Product::where('is_active', true)->with('category')->orderBy('name')->get()->map(fn($p) => [
            'id' => $p->id,
            'name' => $p->name,
            'price' => $p->price,
            'type' => 'product',
            'category' => $p->category?->name,
        ]);

        $bundles = Bundle::where('is_active', true)->orderBy('name')->get()->map(fn($b) => [
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
            'appointment_id' => 'nullable|exists:appointments,id',
        ]);

        $portfolio = new \App\Models\CustomerPortfolio([
            'notes' => $request->notes,
            'pos_transaction_id' => $request->pos_transaction_id,
            'appointment_id' => $request->appointment_id,
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
            'name' => 'required_without:full_name|string|max:255',
            'full_name' => 'required_without:name|string|max:255',
            'phone' => 'nullable|string|max:255',
            'email' => 'nullable|email|max:255',
        ]);

        $data = $request->all();
        if ($request->has('full_name') && !$request->has('name')) {
            $data['name'] = $request->full_name;
        }

        $customer = Customer::create($data);

        return response()->json($customer, 201);
    }

    public function employees()
    {
        return response()->json(
            Employee::with('user:id,name')
                ->whereHas('user', function ($q) {
                    $q->where('is_active', true)
                      ->whereDoesntHave('roles', function ($q) {
                          $q->where('name', 'super_admin');
                      });
                })
                ->get()
                ->map(function ($employee) {
                    return [
                        'id' => $employee->id,
                        'name' => $employee->full_name ?? ($employee->user->name ?? 'Employee #' . $employee->id),
                    ];
                })
        );
    }

    public function storeTransaction(Request $request)
    {
        $request->validate([
            'customer_id' => 'nullable|exists:customers,id',
            'items' => 'required|array|min:1',
            'items.*.item_id' => 'required',
            'items.*.item_type' => 'required|in:service,product,bundle',
            'items.*.service_variant_id' => 'nullable|exists:service_variants,id',
            'items.*.employee_ids' => 'nullable|array',
            'items.*.employee_ids.*' => 'exists:employees,id',
            'items.*.price' => 'nullable|numeric|min:0',
            'items.*.quantity' => 'required|integer|min:1',
            'total_amount' => 'required|numeric',
            'discount_amount' => 'nullable|numeric',
            'discount_id' => 'nullable|exists:discounts,id',
            'final_amount' => 'required|numeric|min:0',
            'payments' => 'required|array|min:1',
            'payments.*.payment_method' => 'required|string',
            'payments.*.amount' => 'required|numeric|min:0',
            'employee_id' => 'required|exists:employees,id',
        ]);

        return DB::transaction(function () use ($request) {
            $shift = Shift::where('status', 'open')->orderBy('start_time', 'desc')->first();
            if (!$shift) {
                return response()->json(['message' => 'No active shift found. Please start a shift first.'], 422);
            }

            // The totalAmount, discount, and finalAmount are now expected from the request
            // The following block is no longer needed for calculation but can be used for validation if desired
            // $totalAmount = 0;
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

                $price = $itemModel->price;
                if ($i['item_type'] === 'service' && $itemModel->is_variable_price && isset($i['price'])) {
                    $price = $i['price'];
                } elseif ($i['item_type'] === 'service' && !empty($i['service_variant_id'])) {
                    $variant = \App\Models\ServiceVariant::find($i['service_variant_id']);
                    if ($variant && $variant->service_id == $i['item_id']) {
                        $price = $variant->price;
                    }
                }

                $subtotal = $price * $i['quantity'];
                // $totalAmount += $subtotal; // No longer calculating here

                $transactionItems[] = [
                    'item_id' => $i['item_id'],
                    'item_type' => $modelClass,
                    'service_variant_id' => $i['service_variant_id'] ?? null,
                    'employee_id' => !empty($i['employee_ids']) ? $i['employee_ids'][0] : null,
                    'employee_ids' => $i['employee_ids'] ?? [],
                    'quantity' => $i['quantity'],
                    'price' => $price,
                    'subtotal' => $subtotal,
                ];
            }

            $totalAmount = $request->total_amount;
            $discount = $request->discount_amount ?? 0;
            $finalAmount = max(0, $request->final_amount);

            $transaction = PosTransaction::create([
                'transaction_number' => 'POS-' . date('YmdHis') . '-' . Str::upper(Str::random(4)),
                'customer_id' => $request->customer_id,
                'shift_id' => $shift->id,
                'total_amount' => $totalAmount,
                'discount_amount' => $discount,
                'discount_id' => $request->discount_id,
                'final_amount' => $finalAmount,
                'employee_id' => $request->employee_id,
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
                $employeeIds = $ti['employee_ids'];
                unset($ti['employee_ids']);
                $item = $transaction->items()->create($ti);
                if (!empty($employeeIds)) {
                    $item->employees()->attach($employeeIds);
                }
                $this->processItemStock($item);
            }

            foreach ($request->payments as $p) {
                // Try to find the payment type by name (case-insensitive)
                $paymentType = \App\Models\PaymentType::where('name', 'like', $p['payment_method'])->first();
                if ($paymentType) {
                    $p['payment_type_id'] = $paymentType->id;
                }
                $transaction->payments()->create($p);
            }
            
            return response()->json($transaction->load(['items.item', 'items.employees', 'payments', 'employee', 'customer']), 201);
        });
    }

    public function transactions(Request $request)
    {
        $transactions = PosTransaction::with(['customer', 'items.item', 'items.employees', 'portfolios.media', 'employee'])
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        return response()->json($transactions);
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

        $items = PosTransactionItem::where(function($q) use ($employeeId) {
                $q->where('employee_id', $employeeId)
                  ->orWhereHas('employees', fn($sq) => $sq->where('employee_id', $employeeId));
            })
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
