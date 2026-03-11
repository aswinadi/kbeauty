<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Spatie\MediaLibrary\HasMedia;
use Spatie\MediaLibrary\InteractsWithMedia;

class AbsentAttendance extends Model implements HasMedia
{
    use HasFactory, InteractsWithMedia;

    protected $fillable = [
        'employee_id',
        'office_id',
        'date',
        'type',
        'reason',
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

    public function registerMediaCollections(): void
    {
        $this->addMediaCollection('attachments');
    }
}
