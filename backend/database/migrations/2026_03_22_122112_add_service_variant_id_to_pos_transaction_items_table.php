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
        Schema::table('pos_transaction_items', function (Blueprint $table) {
            $table->foreignId('service_variant_id')->nullable()->constrained('service_variants')->onDelete('set null')->after('item_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('pos_transaction_items', function (Blueprint $table) {
            $table->dropConstrainedForeignId('service_variant_id');
        });
    }
};
