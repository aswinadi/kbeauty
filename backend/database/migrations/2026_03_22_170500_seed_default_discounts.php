<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        DB::table('discounts')->insert([
            ['name' => 'Diskon Maret', 'type' => 'percentage', 'value' => 20, 'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
            ['name' => 'Free', 'type' => 'percentage', 'value' => 100, 'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
            ['name' => 'FREE MODEL', 'type' => 'percentage', 'value' => 100, 'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
            ['name' => 'FREE PAKET', 'type' => 'percentage', 'value' => 100, 'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
            ['name' => 'Gift Voucher', 'type' => 'fixed', 'value' => 100000, 'is_active' => true, 'created_at' => now(), 'updated_at' => now()],
        ]);
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::table('discounts')->whereIn('name', ['Diskon Maret', 'Free', 'FREE MODEL', 'FREE PAKET', 'Gift Voucher'])->delete();
    }
};
