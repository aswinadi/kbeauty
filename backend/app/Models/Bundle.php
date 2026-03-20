<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Bundle extends Model
{
    protected $fillable = [
        'is_active',
        'name',
        'price',
    ];

    public function items()
    {
        return $this->hasMany(BundleItem::class);
    }

    public function posTransactionItems()
    {
        return $this->morphMany(PosTransactionItem::class, 'item');
    }
}
