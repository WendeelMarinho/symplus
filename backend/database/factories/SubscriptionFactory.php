<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Subscription>
 */
class SubscriptionFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'organization_id' => \App\Models\Organization::factory(),
            'stripe_subscription_id' => 'sub_'.fake()->uuid(),
            'stripe_customer_id' => 'cus_'.fake()->uuid(),
            'plan' => fake()->randomElement(['free', 'basic', 'premium', 'enterprise']),
            'status' => 'active',
            'trial_ends_at' => fake()->optional()->dateTimeBetween('now', '+14 days'),
            'ends_at' => null,
        ];
    }
}
