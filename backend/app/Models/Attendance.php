<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Models\Employee;
use App\Models\Office;

class Attendance extends Model
{
    use HasFactory;

    protected $fillable = [
        'employee_id',
        'office_id',
        'date',
        'check_in',
        'check_out',
        'check_in_lat',
        'check_in_long',
        'check_out_lat',
        'check_out_long',
        'status',
    ];

    public function employee()
    {
        return $this->belongsTo(Employee::class);
    }

    public function office()
    {
        return $this->belongsTo(Office::class);
    }
}
