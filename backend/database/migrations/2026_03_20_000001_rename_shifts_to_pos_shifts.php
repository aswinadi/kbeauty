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
        if (Schema::hasTable('shifts') && !Schema::hasTable('pos_shifts')) {
            Schema::rename('shifts', 'pos_shifts');
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('pos_shifts') && !Schema::hasTable('shifts')) {
            Schema::rename('pos_shifts', 'shifts');
        }
    }
};
