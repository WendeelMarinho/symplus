<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\ServiceRequest>
 */
class ServiceRequestFactory extends Factory
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
            'created_by' => User::factory(),
            'assigned_to' => fake()->optional()->randomElement([User::factory(), null]),
            'title' => fake()->sentence(4),
            'description' => fake()->paragraphs(2, true),
            'status' => fake()->randomElement(['open', 'in_progress', 'resolved', 'closed']),
            'priority' => fake()->randomElement(['low', 'medium', 'high', 'urgent']),
            'category' => fake()->optional()->randomElement(['finance', 'technical', 'billing', 'other']),
            'resolved_at' => fake()->optional()->dateTimeBetween('-1 year', 'now'),
            'closed_at' => fake()->optional()->dateTimeBetween('-1 year', 'now'),
        ];
    }
}
