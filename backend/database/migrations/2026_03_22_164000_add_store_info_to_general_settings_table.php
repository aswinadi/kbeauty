<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('general_settings', function (Blueprint $table) {
            $table->string('store_name')->nullable()->after('id');
            $table->string('store_address')->nullable()->after('store_name');
            $table->string('store_phone')->nullable()->after('store_address');
        });

        // Seed default values if entry exists
        $settings = \App\Models\GeneralSetting::first();
        if ($settings) {
            $settings->update([
                'store_name' => 'K-BEAUTY HOUSE',
                'store_address' => 'Nail Salon & Beauty',
                'store_phone' => '-',
            ]);
        } else {
            \App\Models\GeneralSetting::create([
                'store_name' => 'K-BEAUTY HOUSE',
                'store_address' => 'Nail Salon & Beauty',
                'store_phone' => '-',
            ]);
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('general_settings', function (Blueprint $table) {
            $table->dropColumn(['store_name', 'store_address', 'store_phone']);
        });
    }
};
