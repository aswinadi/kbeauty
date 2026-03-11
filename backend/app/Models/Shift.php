<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Shift extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'start_time',
        'end_time',
        'working_days',
    ];

    protected $casts = [
        'working_days' => 'array',
    ];

    public function employees()
    {
        return $this->hasMany(Employee::class);
    }
}
