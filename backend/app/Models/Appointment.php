<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Appointment extends Model
{
    use HasFactory;

    protected $fillable = [
        'customer_id',
        'appointment_date',
        'appointment_time',
        'treatment_name',
        'pax',
        'is_paid',
        'status',
        'notes',
    ];

    protected $casts = [
        'appointment_date' => 'date',
        'is_paid' => 'boolean',
    ];

    public function customer()
    {
        return $this->belongsTo(Customer::class);
    }
}
