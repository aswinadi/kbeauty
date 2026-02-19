<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\Product;
use App\Models\Unit;
use Illuminate\Database\Seeder;

class AlatProductSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Create/Get Unit
        $unit = Unit::firstOrCreate(['name' => 'Pcs'], ['short_name' => 'pcs']);

        // 2. Create/Get Category
        $category = Category::firstOrCreate(
            ['name' => 'Alat'],
            ['prefix' => 'AL']
        );

        // 3. Products List
        $products = [
            'Bowl manicure',
            'UV putih',
            'UV hitam',
            'Drill',
            'Uv steril',
        ];

        foreach ($products as $productName) {
            Product::create([
                'category_id' => $category->id,
                'unit_id' => $unit->id,
                'name' => $productName,
                'price' => 0,
            ]);
        }
    }
}
