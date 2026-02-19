<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('inventory_movements', function (Blueprint $table) {
            $table->foreignId('user_id')->nullable()->after('type')->constrained()->nullOnDelete();
        });

        Schema::table('purchases', function (Blueprint $table) {
            $table->foreignId('user_id')->nullable()->after('total_amount')->constrained()->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('inventory_movements', function (Blueprint $table) {
            $table->dropConstrainedForeignId('user_id');
        });

        Schema::table('purchases', function (Blueprint $table) {
            $table->dropConstrainedForeignId('user_id');
        });
    }
};
