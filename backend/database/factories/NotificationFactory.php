<?php

namespace Database\Factories;

use App\Models\Organization;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Notification>
 */
class NotificationFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'organization_id' => Organization::factory(),
            'type' => fake()->randomElement(['due_item_reminder', 'service_request_update', 'system_alert']),
            'title' => fake()->sentence(3),
            'message' => fake()->paragraph(),
            'data' => [
                'key' => fake()->word(),
                'value' => fake()->randomNumber(),
            ],
            'read_at' => fake()->optional(0.3)->dateTimeBetween('-1 month', 'now'),
        ];
    }
}
