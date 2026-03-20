<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Customer extends Model
{
    protected $fillable = [
        'name',
        'phone',
        'email',
        'loyalty_points',
        'metadata',
    ];

    protected $casts = [
        'metadata' => 'array',
    ];

    protected $appends = ['full_name'];

    public function getFullNameAttribute()
    {
        return $this->name;
    }

    public function portfolios()
    {
        return $this->hasMany(CustomerPortfolio::class);
    }

    public function memberships()
    {
        return $this->hasMany(Membership::class);
    }

    public function posTransactions()
    {
        return $this->hasMany(PosTransaction::class);
    }
}
