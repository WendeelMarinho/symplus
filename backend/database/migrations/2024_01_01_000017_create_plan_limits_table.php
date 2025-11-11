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
        Schema::create('plan_limits', function (Blueprint $table) {
            $table->id();
            $table->string('plan'); // free, basic, premium, enterprise
            $table->string('feature'); // accounts, transactions, documents, users, etc.
            $table->integer('limit')->nullable(); // null = unlimited
            $table->timestamps();

            $table->unique(['plan', 'feature']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('plan_limits');
    }
};
