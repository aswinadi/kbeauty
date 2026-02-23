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
        Schema::table('products', function (Blueprint $table) {
            $table->foreignId('secondary_unit_id')->nullable()->after('unit_id')->constrained('units')->nullOnDelete();
            $table->decimal('conversion_ratio', 12, 4)->nullable()->after('secondary_unit_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('products', function (Blueprint $table) {
            $table->dropConstrainedForeignId('secondary_unit_id');
            $table->dropColumn('conversion_ratio');
        });
    }
};
