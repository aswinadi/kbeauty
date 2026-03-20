<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Shift extends Model
{
    protected $fillable = [
        'user_id',
        'start_time',
        'end_time',
        'starting_cash',
        'ending_cash',
        'status',
    ];

    protected $casts = [
        'start_time' => 'datetime',
        'end_time' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function pettyCashTransactions()
    {
        return $this->hasMany(PettyCashTransaction::class);
    }

    public function posTransactions()
    {
        return $this->hasMany(PosTransaction::class);
    }
}
