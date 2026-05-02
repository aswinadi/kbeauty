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
            $table->string('latest_version')->nullable()->after('bill_footer');
            $table->string('apk_url')->nullable()->after('latest_version');
            $table->boolean('is_mandatory_update')->default(false)->after('apk_url');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('general_settings', function (Blueprint $table) {
            $table->dropColumn(['latest_version', 'apk_url', 'is_mandatory_update']);
        });
    }
};
