<?php

require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\User;

$user = User::where('username', 'admin')->first();

if (!$user) {
    echo "Admin user not found.\n";
    exit;
}

$isAdmin = $user->roles()->whereIn('roles.name', ['super_admin', 'Super Admin', 'super-admin'])->exists();

echo "Is Admin: " . ($isAdmin ? 'Yes' : 'No') . "\n";

$users = User::whereDoesntHave('roles', function ($query) {
    $query->whereIn('name', ['super_admin', 'Super Admin', 'super-admin']);
})
->with(['roles', 'employee'])
->get();

echo "Users count: " . $users->count() . "\n";
echo "Users list: " . json_encode($users->pluck('name')->toArray()) . "\n";

foreach ($users as $u) {
    echo "User: " . $u->name . " | Roles: " . strval($u->roles->pluck('name')->implode(',')) . "\n";
}
