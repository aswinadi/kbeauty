<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

use Spatie\MediaLibrary\HasMedia;
use Spatie\MediaLibrary\InteractsWithMedia;

use Illuminate\Support\Str;

class Product extends Model implements HasMedia
{
    use InteractsWithMedia;

    protected $fillable = ['is_active', 'category_id', 'unit_id', 'secondary_unit_id', 'name', 'sku', 'price', 'conversion_ratio', 'min_stock'];

    protected static function booted()
    {
        static::creating(function ($product) {
            if (empty($product->sku)) {
                $category = $product->category ?? \App\Models\Category::find($product->category_id);

                if (!$category) {
                    return;
                }

                $prefix = $category->prefix ?: Str::upper(Str::substr($category->name, 0, 2));

                $lastProduct = static::where('category_id', $product->category_id)
                    ->orderBy('id', 'desc')
                    ->first();

                $sequence = 1;
                if ($lastProduct && $lastProduct->sku && preg_match('/-(\d{3})$/', $lastProduct->sku, $matches)) {
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

    public function secondaryUnit()
    {
        return $this->belongsTo(Unit::class, 'secondary_unit_id');
    }

    public function inventoryMovements()
    {
        return $this->hasMany(InventoryMovement::class);
    }

    public function formatQuantity(float $qty): string
    {
        if ($this->secondary_unit_id && $this->conversion_ratio > 0) {
            $secondaryQty = floor($qty / $this->conversion_ratio);
            $primaryQty = $qty % $this->conversion_ratio;

            $parts = [];
            if ($secondaryQty > 0) {
                $parts[] = $secondaryQty . ' ' . ($this->secondaryUnit?->name ?? 'Unit');
            }
            if ($primaryQty > 0 || empty($parts)) {
                $parts[] = $primaryQty . ' ' . ($this->unit?->name ?? 'Unit');
            }

            return implode(', ', $parts);
        }

        return $qty . ' ' . ($this->unit?->name ?? 'Unit');
    }
}
