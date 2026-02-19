<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Supplier extends Model
{
    protected $fillable = ['name', 'contact_info', 'address'];

    public function purchases()
    {
        return $this->hasMany(Purchase::class);
    }
}
