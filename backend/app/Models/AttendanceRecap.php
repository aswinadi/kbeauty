<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AttendanceRecap extends Model
{
    public $incrementing = false;
    protected $table = 'attendance_recaps';
    
    public function employee()
    {
        return $this->belongsTo(Employee::class);
    }

    public function office()
    {
        return $this->belongsTo(Office::class);
    }
}
