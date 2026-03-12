<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Models\Category;
use Illuminate\Http\Request;

class ProductController extends Controller
{
    public function index(Request $request)
    {
        $query = Product::with(['category', 'unit']);

        if ($request->has('category_id') && !empty($request->category_id)) {
            $query->where('category_id', $request->category_id);
        }

        if ($request->has('search') && !empty($request->search)) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', '%' . $search . '%')
                    ->orWhere('sku', 'like', '%' . $search . '%');
            });
        }

        $isSuperAdmin = auth()->user()?->hasRole('Super Admin');

        $products = $query->orderByRaw('LOWER(TRIM(name)) ASC')->get()->map(function (Product $product) use ($isSuperAdmin) {
            return [
                'id' => $product->id,
                'name' => $product->name,
                'sku' => $product->sku,
                'price' => $isSuperAdmin ? $product->price : null,
                'unit_id' => $product->unit_id,
                'unit' => $product->unit?->name ?? '-',
                'secondary_unit_id' => $product->secondary_unit_id,
                'secondary_unit_name' => $product->secondaryUnit?->name,
                'conversion_ratio' => $product->conversion_ratio,
                'category_id' => $product->category_id,
                'category_name' => $product->category?->name,
                'image_url' => $product->getFirstMediaUrl('product_images') ?: null,
            ];
        });

        return response()->json($products);
    }
    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'sku' => 'nullable|string|max:255|unique:products,sku',
            'price' => 'nullable|numeric',
            'category_id' => 'required|exists:categories,id',
            'unit_id' => 'required|exists:units,id',
            'secondary_unit_id' => 'nullable|exists:units,id',
            'conversion_ratio' => 'nullable|numeric',
            'image' => 'nullable|image|max:2048',
        ]);

        $product = Product::create($request->only([
            'name',
            'sku',
            'price',
            'category_id',
            'unit_id',
            'secondary_unit_id',
            'conversion_ratio'
        ]));

        if ($request->hasFile('image')) {
            $product->addMediaFromRequest('image')->toMediaCollection('product_images');
        }

        $isSuperAdmin = auth()->user()?->hasRole('Super Admin');

        return response()->json([
            'message' => 'Product created successfully',
            'product' => [
                'id' => $product->id,
                'name' => $product->name,
                'sku' => $product->sku,
                'price' => $isSuperAdmin ? $product->price : null,
                'unit_id' => $product->unit_id,
                'unit' => $product->unit?->name ?? '-',
                'secondary_unit_id' => $product->secondary_unit_id,
                'secondary_unit_name' => $product->secondaryUnit?->name,
                'conversion_ratio' => $product->conversion_ratio,
                'category_id' => $product->category_id,
                'category_name' => $product->category?->name,
                'image_url' => $product->getFirstMediaUrl('product_images') ?: null,
            ],
        ], 201);
    }


    public function update(Request $request, Product $product)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'sku' => 'required|string|max:255|unique:products,sku,' . $product->id,
            'price' => 'nullable|numeric',
            'category_id' => 'required|exists:categories,id',
            'unit_id' => 'required|exists:units,id',
            'secondary_unit_id' => 'nullable|exists:units,id',
            'conversion_ratio' => 'nullable|numeric',
            'image' => 'nullable|image|max:2048',
        ]);

        $product->update($request->only([
            'name',
            'sku',
            'price',
            'category_id',
            'unit_id',
            'secondary_unit_id',
            'conversion_ratio'
        ]));

        if ($request->hasFile('image')) {
            $product->clearMediaCollection('product_images');
            $product->addMediaFromRequest('image')->toMediaCollection('product_images');
        }

        $isSuperAdmin = auth()->user()?->hasRole('Super Admin');

        return response()->json([
            'message' => 'Product updated successfully',
            'product' => [
                'id' => $product->id,
                'name' => $product->name,
                'sku' => $product->sku,
                'price' => $isSuperAdmin ? $product->price : null,
                'unit_id' => $product->unit_id,
                'unit' => $product->unit?->name ?? '-',
                'secondary_unit_id' => $product->secondary_unit_id,
                'secondary_unit_name' => $product->secondaryUnit?->name,
                'conversion_ratio' => $product->conversion_ratio,
                'category_id' => $product->category_id,
                'category_name' => $product->category?->name,
                'image_url' => $product->getFirstMediaUrl('product_images') ?: null,
            ],
        ]);
    }

    public function categories()
    {
        return response()->json(Category::orderByRaw('LOWER(TRIM(name)) ASC')->get());
    }

    public function units()
    {
        return response()->json(\App\Models\Unit::orderByRaw('LOWER(TRIM(name)) ASC')->get());
    }

    public function stockBalance(Product $product)
    {
        $locations = \App\Models\Location::all();
        $balanceData = [];

        foreach ($locations as $location) {
            $in = \App\Models\InventoryMovement::where('product_id', $product->id)
                ->where('to_location_id', $location->id)
                ->sum('qty');

            $out = \App\Models\InventoryMovement::where('product_id', $product->id)
                ->where('from_location_id', $location->id)
                ->sum('qty');

            $balance = $in - $out;

            // Only include locations with stock or movements
            if ($balance != 0 || $in > 0 || $out > 0) {
                $balanceData[] = [
                    'location_id' => $location->id,
                    'location_name' => $location->name,
                    'balance' => $balance,
                ];
            }
        }

        return response()->json([
            'product_id' => $product->id,
            'product_name' => $product->name,
            'sku' => $product->sku,
            'balances' => $balanceData
        ]);
    }
}
