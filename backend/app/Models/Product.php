<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

use Spatie\MediaLibrary\HasMedia;
use Spatie\MediaLibrary\InteractsWithMedia;

use Illuminate\Support\Str;

class Product extends Model implements HasMedia
{
    use InteractsWithMedia;

    protected $fillable = ['category_id', 'unit_id', 'name', 'sku', 'price'];

    protected static function booted()
    {
        static::creating(function ($product) {
            if (empty($product->sku)) {
                $category = $product->category;
                $prefix = $category->prefix ?: Str::upper(Str::substr($category->name, 0, 2));

                $lastProduct = static::where('category_id', $product->category_id)
                    ->latest('id')
                    ->first();

                $sequence = 1;
                if ($lastProduct && preg_match('/-(\d{3})$/', $lastProduct->sku, $matches)) {
                    $sequence = (int) $matches[1] + 1;
                }

                $product->sku = $prefix . '-' . str_pad($sequence, 3, '0', STR_PAD_LEFT);
            }
        });
    }

    public function category()
    {
        return $this->belongsTo(Category::class);
    }

    public function unit()
    {
        return $this->belongsTo(Unit::class);
    }

    public function inventoryMovements()
    {
        return $this->hasMany(InventoryMovement::class);
    }
}
