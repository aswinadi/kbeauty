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
        // Services Table
        Schema::create('services', function (Blueprint $table) {
            $table->id();
            $table->foreignId('category_id')->nullable()->constrained()->onDelete('set null');
            $table->string('name');
            $table->decimal('price', 15, 2)->default(0);
            $table->enum('commission_type', ['fixed', 'percentage'])->default('fixed');
            $table->decimal('commission_value', 15, 2)->default(0);
            $table->boolean('deduct_stock')->default(false);
            $table->timestamps();
        });

        // Service Materials (Mapping for stock deduction)
        Schema::create('service_materials', function (Blueprint $table) {
            $table->id();
            $table->foreignId('service_id')->constrained()->onDelete('cascade');
            $table->foreignId('product_id')->constrained()->onDelete('cascade');
            $table->decimal('quantity', 15, 2)->default(1);
            $table->timestamps();
        });

        // Bundles Table
        Schema::create('bundles', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->decimal('price', 15, 2)->default(0);
            $table->timestamps();
        });

        // Bundle Items (Multiple items in a bundle)
        Schema::create('bundle_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('bundle_id')->constrained()->onDelete('cascade');
            $table->morphs('item'); // Polymorphic: Service or Product
            $table->decimal('quantity', 15, 2)->default(1);
            $table->timestamps();
        });

        // Customers Table
        Schema::create('customers', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('phone')->nullable();
            $table->string('email')->nullable();
            $table->integer('loyalty_points')->default(0);
            $table->json('metadata')->nullable();
            $table->timestamps();
        });

        // Customer Portfolios
        Schema::create('customer_portfolios', function (Blueprint $table) {
            $table->id();
            $table->foreignId('customer_id')->constrained()->onDelete('cascade');
            $table->unsignedBigInteger('pos_transaction_id')->nullable(); // Set after transaction
            $table->string('image_path')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();
        });

        // Memberships
        Schema::create('memberships', function (Blueprint $table) {
            $table->id();
            $table->foreignId('customer_id')->constrained()->onDelete('cascade');
            $table->string('type'); // e.g., Prepaid Balance, Service Quota
            $table->decimal('balance', 15, 2)->default(0);
            $table->dateTime('expires_at')->nullable();
            $table->timestamps();
        });

        // Shifts Table
        Schema::create('shifts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained(); // Cashier
            $table->dateTime('start_time');
            $table->dateTime('end_time')->nullable();
            $table->decimal('starting_cash', 15, 2)->default(0);
            $table->decimal('ending_cash', 15, 2)->nullable();
            $table->enum('status', ['open', 'closed'])->default('open');
            $table->timestamps();
        });

        // Petty Cash / Expenses during shift
        Schema::create('petty_cash_transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('shift_id')->constrained()->onDelete('cascade');
            $table->enum('type', ['in', 'out'])->default('out');
            $table->decimal('amount', 15, 2);
            $table->string('description');
            $table->timestamps();
        });

        // POS Transactions
        Schema::create('pos_transactions', function (Blueprint $table) {
            $table->id();
            $table->string('transaction_number')->unique();
            $table->foreignId('customer_id')->nullable()->constrained()->onDelete('set null');
            $table->foreignId('shift_id')->constrained();
            $table->decimal('total_amount', 15, 2)->default(0);
            $table->decimal('discount_amount', 15, 2)->default(0);
            $table->integer('points_redeemed')->default(0);
            $table->decimal('final_amount', 15, 2)->default(0);
            $table->enum('status', ['pending', 'completed', 'cancelled'])->default('pending');
            $table->timestamps();
        });

        // POS Transaction Items
        Schema::create('pos_transaction_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('pos_transaction_id')->constrained()->onDelete('cascade');
            $table->morphs('item'); // Polymorphic: Service, Product, Bundle
            $table->foreignId('employee_id')->nullable()->constrained('employees'); // Nailist
            $table->decimal('quantity', 15, 2)->default(1);
            $table->decimal('price', 15, 2)->default(0);
            $table->decimal('subtotal', 15, 2)->default(0);
            $table->timestamps();
        });

        // POS Payments
        Schema::create('pos_payments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('pos_transaction_id')->constrained()->onDelete('cascade');
            $table->string('payment_method'); // Cash, QRIS, Debit, etc.
            $table->decimal('amount', 15, 2);
            $table->timestamps();
        });

        // Update General Settings Table
        Schema::table('general_settings', function (Blueprint $table) {
            $table->foreignId('pos_display_location_id')->nullable()->constrained('locations')->onDelete('set null');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('general_settings', function (Blueprint $table) {
            $table->dropConstrainedForeignId('pos_display_location_id');
        });

        Schema::dropIfExists('pos_payments');
        Schema::dropIfExists('pos_transaction_items');
        Schema::dropIfExists('pos_transactions');
        Schema::dropIfExists('petty_cash_transactions');
        Schema::dropIfExists('shifts');
        Schema::dropIfExists('memberships');
        Schema::dropIfExists('customer_portfolios');
        Schema::dropIfExists('customers');
        Schema::dropIfExists('bundle_items');
        Schema::dropIfExists('bundles');
        Schema::dropIfExists('service_materials');
        Schema::dropIfExists('services');
    }
};
