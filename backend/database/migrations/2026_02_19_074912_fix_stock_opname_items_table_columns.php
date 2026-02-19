<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('stock_opname_items', function (Blueprint $table) {
            $table->renameColumn('qty_actual', 'actual_qty');
            $table->integer('system_qty')->default(0)->after('product_id');
            $table->integer('adjustment_qty')->default(0)->after('actual_qty');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('stock_opname_items', function (Blueprint $table) {
            $table->dropColumn(['system_qty', 'adjustment_qty']);
            $table->renameColumn('actual_qty', 'qty_actual');
        });
    }
};
