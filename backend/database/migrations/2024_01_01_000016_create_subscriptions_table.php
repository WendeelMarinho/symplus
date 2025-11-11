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
        Schema::create('subscriptions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organization_id')->constrained()->onDelete('cascade');
            $table->string('stripe_subscription_id')->unique()->nullable(); // ID da subscription no Stripe
            $table->string('stripe_customer_id')->nullable(); // ID do customer no Stripe
            $table->string('plan'); // free, basic, premium, enterprise
            $table->string('status')->default('active'); // active, canceled, past_due, trialing
            $table->timestamp('trial_ends_at')->nullable();
            $table->timestamp('ends_at')->nullable(); // Quando a subscription será cancelada
            $table->timestamps();

            $table->index(['organization_id', 'status']);
            $table->index(['organization_id', 'plan']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('subscriptions');
    }
};
