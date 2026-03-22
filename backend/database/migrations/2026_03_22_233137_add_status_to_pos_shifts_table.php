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
        if (Schema::hasTable('pos_shifts')) {
            Schema::table('pos_shifts', function (Blueprint $table) {
                if (!Schema::hasColumn('pos_shifts', 'user_id')) {
                    $table->foreignId('user_id')->nullable()->constrained('users')->after('id');
                }
                if (!Schema::hasColumn('pos_shifts', 'starting_cash')) {
                    $table->decimal('starting_cash', 15, 2)->default(0)->after('end_time');
                }
                if (!Schema::hasColumn('pos_shifts', 'ending_cash')) {
                    $table->decimal('ending_cash', 15, 2)->nullable()->after('starting_cash');
                }
                if (!Schema::hasColumn('pos_shifts', 'status')) {
                    $table->enum('status', ['open', 'closed'])->default('open');
                }
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
