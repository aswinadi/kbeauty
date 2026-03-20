<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ServiceMaterial extends Model
{
    protected $fillable = [
        'service_id',
        'product_id',
        'quantity',
    ];

    public function service()
    {
        return $this->belongsTo(Service::class);
    }

    public function product()
    {
        return $this->belongsTo(Product::class);
    }
}
