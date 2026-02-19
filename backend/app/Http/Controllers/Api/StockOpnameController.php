<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\StockOpname;
use App\Models\StockOpnameItem;
use App\Models\Location;
use App\Models\Product;
use App\Models\InventoryMovement;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class StockOpnameController extends Controller
{
    public function locations()
    {
        return response()->json(Location::all());
    }

    public function products(Request $request)
    {
        $products = Product::all()->map(function ($product) {
            // In a real app, we would calculate stock from InventoryMovement
            // For this version, we'll return products and the mobile app will track current vs actual
            return [
                'id' => $product->id,
                'name' => $product->name,
                'sku' => $product->sku,
                'unit' => $product->unit,
                'system_qty' => 0, // Current stock calculation logic here
            ];
        });

        return response()->json($products);
    }

    public function stats()
    {
        return response()->json([
            'total_products' => Product::count(),
            'total_movements' => InventoryMovement::count(),
            'total_locations' => Location::count(),
        ]);
    }

    public function transfer(Request $request)
    {
        $request->validate([
            'product_id' => 'required|exists:products,id',
            'from_location_id' => 'required|exists:locations,id',
            'to_location_id' => 'required|exists:locations,id|different:from_location_id',
            'qty' => 'required|numeric|min:1',
            'notes' => 'nullable|string',
        ]);

        return DB::transaction(function () use ($request) {
            $movement = InventoryMovement::create([
                'product_id' => $request->product_id,
                'from_location_id' => $request->from_location_id,
                'to_location_id' => $request->to_location_id,
                'qty' => $request->qty,
                'type' => 'transfer',
                'user_id' => auth()->id(),
                'notes' => $request->notes,
            ]);

            return response()->json([
                'message' => 'Stock transfer recorded successfully',
                'id' => $movement->id,
            ]);
        });
    }

    public function move(Request $request)
    {
        $request->validate([
            'product_id' => 'required|exists:products,id',
            'location_id' => 'required|exists:locations,id',
            'qty' => 'required|numeric|min:1',
            'type' => 'required|in:in,out',
            'notes' => 'nullable|string',
        ]);

        return DB::transaction(function () use ($request) {
            $movement = InventoryMovement::create([
                'product_id' => $request->product_id,
                'from_location_id' => $request->type === 'out' ? $request->location_id : null,
                'to_location_id' => $request->type === 'in' ? $request->location_id : null,
                'qty' => $request->qty,
                'type' => $request->type === 'in' ? 'manual_in' : 'manual_out',
                'user_id' => auth()->id(),
                'notes' => $request->notes,
            ]);

            return response()->json([
                'message' => 'Inventory movement recorded successfully',
                'id' => $movement->id,
            ]);
        });
    }

    public function store(Request $request)
    {
        $request->validate([
            'location_id' => 'required|exists:locations,id',
            'items' => 'required|array',
            'items.*.product_id' => 'required|exists:products,id',
            'items.*.actual_qty' => 'required|numeric',
            'items.*.system_qty' => 'required|numeric',
        ]);

        return DB::transaction(function () use ($request) {
            $stockOpname = StockOpname::create([
                'location_id' => $request->location_id,
                'user_id' => auth()->id(),
                'status' => 'completed',
            ]);

            foreach ($request->items as $item) {
                StockOpnameItem::create([
                    'stock_opname_id' => $stockOpname->id,
                    'product_id' => $item['product_id'],
                    'system_qty' => $item['system_qty'],
                    'actual_qty' => $item['actual_qty'],
                    'adjustment_qty' => $item['actual_qty'] - $item['system_qty'],
                ]);

                // Record Inventory Movement for the adjustment
                InventoryMovement::create([
                    'product_id' => $item['product_id'],
                    'from_location_id' => $item['actual_qty'] < $item['system_qty'] ? $request->location_id : null,
                    'to_location_id' => $item['actual_qty'] > $item['system_qty'] ? $request->location_id : null,
                    'qty' => abs($item['actual_qty'] - $item['system_qty']),
                    'type' => 'adjustment',
                    'user_id' => auth()->id(),
                    'reference_type' => StockOpname::class,
                    'reference_id' => $stockOpname->id,
                ]);
            }

            return response()->json([
                'message' => 'Stock opname submitted successfully',
                'id' => $stockOpname->id,
            ]);
        });
    }
    public function bulkTransaction(Request $request)
    {
        $request->validate([
            'type' => 'required|in:in,out',
            'location_id' => 'required|exists:locations,id',
            'items' => 'required|array',
            'items.*.product_id' => 'required|exists:products,id',
            'items.*.qty' => 'required|numeric|min:1',
            'notes' => 'nullable|string',
        ]);

        return DB::transaction(function () use ($request) {
            $transaction = \App\Models\InventoryTransaction::create([
                'type' => $request->type,
                'location_id' => $request->location_id,
                'user_id' => auth()->id(),
                'notes' => $request->notes,
                'transaction_date' => now(),
            ]);

            foreach ($request->items as $item) {
                \App\Models\InventoryTransactionItem::create([
                    'inventory_transaction_id' => $transaction->id,
                    'product_id' => $item['product_id'],
                    'qty' => $item['qty'],
                ]);

                InventoryMovement::create([
                    'product_id' => $item['product_id'],
                    'from_location_id' => $request->type === 'out' ? $request->location_id : null,
                    'to_location_id' => $request->type === 'in' ? $request->location_id : null,
                    'qty' => $item['qty'],
                    'type' => $request->type === 'in' ? 'manual_in' : 'manual_out',
                    'user_id' => auth()->id(),
                    'reference_type' => \App\Models\InventoryTransaction::class,
                    'reference_id' => $transaction->id,
                ]);
            }

            return response()->json([
                'message' => 'Bulk inventory transaction recorded successfully',
                'id' => $transaction->id,
            ]);
        });
    }
}
