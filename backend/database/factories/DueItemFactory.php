<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\DueItem>
 */
class DueItemFactory extends Factory
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
            'title' => fake()->sentence(3),
            'amount' => fake()->randomFloat(2, 10, 5000),
            'due_date' => fake()->dateTimeBetween('now', '+30 days'),
            'type' => fake()->randomElement(['pay', 'receive']),
            'status' => fake()->randomElement(['pending', 'paid', 'overdue']),
            'description' => fake()->optional()->sentence(),
        ];
    }
}
