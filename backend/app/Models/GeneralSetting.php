<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class GeneralSetting extends Model
{
    protected $fillable = [
        'face_similarity_threshold',
        'pos_display_location_id',
    ];

    public function posDisplayLocation()
    {
        return $this->belongsTo(Location::class, 'pos_display_location_id');
    }
}
