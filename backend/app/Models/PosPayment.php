<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PosPayment extends Model
{
    protected $fillable = [
        'pos_transaction_id',
        'payment_method',
        'amount',
    ];

    public function posTransaction()
    {
        return $this->belongsTo(PosTransaction::class);
    }
}
