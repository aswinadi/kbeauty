<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PosTransaction extends Model
{
    protected $fillable = [
        'transaction_number',
        'customer_id',
        'shift_id',
        'total_amount',
        'discount_amount',
        'points_redeemed',
        'final_amount',
        'status',
    ];

    public function customer()
    {
        return $this->belongsTo(Customer::class);
    }

    public function shift()
    {
        return $this->belongsTo(Shift::class);
    }

    public function items()
    {
        return $this->hasMany(PosTransactionItem::class);
    }

    public function payments()
    {
        return $this->hasMany(PosPayment::class);
    }

    public function portfolios()
    {
        return $this->hasMany(CustomerPortfolio::class);
    }

    protected static function boot()
    {
        parent::boot();
        static::creating(function ($model) {
            if (empty($model->transaction_number)) {
                $model->transaction_number = 'POS-' . now()->format('YmdHis') . '-' . strtoupper(bin2hex(random_bytes(2)));
            }
        });
    }
}
