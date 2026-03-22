<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public static function up(): void
    {
        if (Schema::hasTable('pos_shifts') && !Schema::hasColumn('pos_shifts', 'status')) {
            Schema::table('pos_shifts', function (Blueprint $table) {
                $table->enum('status', ['open', 'closed'])->default('open')->after('ending_cash');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('pos_shifts', function (Blueprint $table) {
            //
        });
    }
};
