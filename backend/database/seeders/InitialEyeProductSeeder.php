<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\Product;
use App\Models\Unit;
use Illuminate\Database\Seeder;

class InitialEyeProductSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Create Unit
        $unit = Unit::firstOrCreate(['name' => 'Box'], ['short_name' => 'bx']);

        // 2. Create Category
        $category = Category::firstOrCreate(
            ['name' => 'Eye'],
            ['prefix' => 'EY']
        );

        // 3. Products List
        $products = [
            'Dancing Swan D 0.07 mix',
            'Dancing Swan D 0.07 12mm',
            'Yelix D 0.05 9mm',
            'Yelix D 0.05 10mm',
            'Yelix D 0.05 7mm',
            'Yelix D 0.05 8mm',
            'Yelix D 0.05 11mm',
            'Yelix D 0.05 12mm',
            'Lashtensity single wetlash D 0.05 8mm',
            'Yelix Douyin LC 0.07 9mm',
            'Yelix single mix',
            'Single lash love mix',
            'Nagaraku single J mix 0.10',
            'Yelix Y 0.07 mix',
            'Yelix Y 0.07 9mm',
            'Yelix Y 0.07 10mm',
            'Yelix Y 0.07 11mm',
            'Yelix 0.07 10mm',
            'Dancing Swan 0.07C mix',
            'Dancing Swan 0.07C 10mm',
            'Dancing Swan 0.07C 11mm',
            'Dancing Swan 0.07C 12mm',
            'Dancing Swan single 0.15C mix',
            'Yelix 0.07 7mm',
            'Box Pink 0.07 9mm/C',
            'Lady Black',
            'Cleansing Foam iconsign',
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
