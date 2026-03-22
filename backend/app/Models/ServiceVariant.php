<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ServiceVariant extends Model
{
    protected $fillable = ['service_id', 'name', 'price'];

    public function service()
    {
        return $this->belongsTo(Service::class);
    }
}
