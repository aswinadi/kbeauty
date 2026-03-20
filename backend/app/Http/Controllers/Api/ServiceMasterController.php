<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Service;
use App\Models\ServiceCategory;
use Illuminate\Http\Request;

class ServiceMasterController extends Controller
{
    // Categories
    public function categories()
    {
        return response()->json(ServiceCategory::withCount('services')->get());
    }

    public function storeCategory(Request $request)
    {
        $request->validate(['name' => 'required|string|max:255']);
        $category = ServiceCategory::create($request->all());
        return response()->json($category, 201);
    }

    public function updateCategory(Request $request, ServiceCategory $category)
    {
        $request->validate(['name' => 'required|string|max:255', 'is_active' => 'boolean']);
        $category->update($request->all());
        return response()->json($category);
    }

    public function deleteCategory(ServiceCategory $category)
    {
        if ($category->services()->count() > 0) {
            return response()->json(['message' => 'Cannot delete category with services'], 422);
        }
        $category->delete();
        return response()->json(null, 204);
    }

    // Services (Treatments)
    public function services(Request $request)
    {
        $query = Service::with('serviceCategory');
        if ($request->has('service_category_id')) {
            $query->where('service_category_id', $request->service_category_id);
        }
        return response()->json($query->get());
    }

    public function storeService(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'service_category_id' => 'required|exists:service_categories,id',
            'price' => 'required|numeric|min:0',
            'is_active' => 'boolean',
            'commission_type' => 'nullable|string',
            'commission_value' => 'nullable|numeric|min:0',
            'deduct_stock' => 'boolean',
        ]);
        $service = Service::create($request->all());
        return response()->json($service, 201);
    }

    public function updateService(Request $request, Service $service)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'service_category_id' => 'required|exists:service_categories,id',
            'price' => 'required|numeric|min:0',
            'is_active' => 'boolean',
            'commission_type' => 'nullable|string',
            'commission_value' => 'nullable|numeric|min:0',
            'deduct_stock' => 'boolean',
        ]);
        $service->update($request->all());
        return response()->json($service);
    }

    public function deleteService(Service $service)
    {
        // Check for transactions? For now just soft delete or check usage
        $service->delete();
        return response()->json(null, 204);
    }
}
