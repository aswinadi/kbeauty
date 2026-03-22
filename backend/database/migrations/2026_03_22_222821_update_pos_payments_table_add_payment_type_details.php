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
        Schema::table('pos_payments', function (Blueprint $table) {
            $table->foreignId('payment_type_id')->after('pos_transaction_id')->nullable()->constrained('payment_types')->onDelete('set null');
            $table->string('bank_name')->after('payment_method')->nullable();
            $table->decimal('money_received', 15, 2)->after('amount')->nullable();
            $table->decimal('change_amount', 15, 2)->after('money_received')->nullable();
            $table->string('payment_method')->nullable()->change();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('pos_payments', function (Blueprint $table) {
            $table->dropConstrainedForeignId('payment_type_id');
            $table->dropColumn(['bank_name', 'money_received', 'change_amount']);
            $table->string('payment_method')->nullable(false)->change();
        });
    }
};
