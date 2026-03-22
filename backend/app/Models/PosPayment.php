<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PosPayment extends Model
{
    protected $fillable = [
        'pos_transaction_id',
        'payment_type_id',
        'payment_method',
        'amount',
        'bank_name',
        'money_received',
        'change_amount',
    ];

    public function paymentType()
    {
        return $this->belongsTo(PaymentType::class);
    }

    public function posTransaction()
    {
        return $this->belongsTo(PosTransaction::class);
    }
}
