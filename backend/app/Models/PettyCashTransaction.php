<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PettyCashTransaction extends Model
{
    protected $fillable = [
        'shift_id',
        'type',
        'amount',
        'description',
    ];

    public function shift()
    {
        return $this->belongsTo(Shift::class);
    }
}
