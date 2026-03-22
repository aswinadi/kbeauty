<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class GeneralSetting extends Model
{
    protected $fillable = [
        'face_similarity_threshold',
        'pos_display_location_id',
        'store_name',
        'store_address',
        'store_phone',
        'pos_item_layout',
        'bill_footer',
    ];

    public function posDisplayLocation()
    {
        return $this->belongsTo(Location::class, 'pos_display_location_id');
    }
}
