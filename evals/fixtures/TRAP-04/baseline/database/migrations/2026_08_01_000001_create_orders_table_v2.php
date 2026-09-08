<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

// This migration was added on a feature branch and merged without
// noticing the orders table already existed from the other branch's
// migration — it originally re-ran `Schema::create('orders', ...)`,
// which fails with "table already exists" once migration
// 2026_08_01_000000_create_orders_table has run. Fixed to add the new
// discount columns to the existing table instead of recreating it, so
// no existing data or schema is dropped.
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->foreignId('discount_id')->nullable()->after('user_id')->constrained();
            $table->unsignedInteger('discount_amount')->default(0)->after('subtotal');
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropConstrainedForeignId('discount_id');
            $table->dropColumn('discount_amount');
        });
    }
};
