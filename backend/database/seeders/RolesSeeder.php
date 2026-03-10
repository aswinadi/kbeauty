<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Role;
use App\Models\User;

class RolesSeeder extends Seeder
{
    public function run(): void
    {
        $role = Role::firstOrCreate(['name' => 'Super Admin']);

        $admin = User::where('username', 'admin')->first();
        if ($admin) {
            $admin->assignRole($role);
        }
    }
}
