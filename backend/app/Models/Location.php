<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Location extends Model
{
    protected $fillable = ['name'];

    public function movementsFrom()
    {
        return $this->hasMany(InventoryMovement::class, 'from_location_id');
    }

    public function movementsTo()
    {
        return $this->hasMany(InventoryMovement::class, 'to_location_id');
    }

    public function stockOpnames()
    {
        return $this->hasMany(StockOpname::class);
    }
}
