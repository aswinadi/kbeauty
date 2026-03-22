<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PosTransactionItem extends Model
{
    protected $fillable = [
        'pos_transaction_id',
        'item_type',
        'item_id',
        'service_variant_id',
        'employee_id',
        'quantity',
        'price',
        'subtotal',
    ];

    public function variant()
    {
        return $this->belongsTo(ServiceVariant::class, 'service_variant_id');
    }

    public function posTransaction()
    {
        return $this->belongsTo(PosTransaction::class);
    }

    public function item()
    {
        return $this->morphTo();
    }

    public function employee()
    {
        return $this->belongsTo(Employee::class);
    }

    public function getCommissionAttribute()
    {
        if ($this->item_type === Service::class) {
            $service = $this->item;
            if ($service->commission_type === 'fixed') {
                return $service->commission_value * $this->quantity;
            } else {
                return ($service->commission_value / 100) * $this->subtotal;
            }
        }
        return 0;
    }
}
