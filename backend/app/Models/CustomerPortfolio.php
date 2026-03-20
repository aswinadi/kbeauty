<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CustomerPortfolio extends Model
{
    protected $fillable = [
        'customer_id',
        'pos_transaction_id',
        'image_path',
        'notes',
    ];

    public function customer()
    {
        return $this->belongsTo(Customer::class);
    }

    public function posTransaction()
    {
        return $this->belongsTo(PosTransaction::class);
    }
}
