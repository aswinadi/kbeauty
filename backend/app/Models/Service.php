<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Service extends Model
{
    protected $fillable = [
        'is_active',
        'service_category_id',
        'name',
        'price',
        'commission_type',
        'commission_value',
        'deduct_stock',
    ];

    public function serviceCategory()
    {
        return $this->belongsTo(ServiceCategory::class);
    }

    public function materials()
    {
        return $this->hasMany(ServiceMaterial::class);
    }

    public function bundleItems()
    {
        return $this->morphMany(BundleItem::class, 'item');
    }

    public function posTransactionItems()
    {
        return $this->morphMany(PosTransactionItem::class, 'item');
    }

    public function variants()
    {
        return $this->hasMany(ServiceVariant::class);
    }
}
