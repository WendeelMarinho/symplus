<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Document>
 */
class DocumentFactory extends Factory
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
            'name' => fake()->words(3, true).'.pdf',
            'original_name' => fake()->words(3, true).'.pdf',
            'mime_type' => 'application/pdf',
            'size' => fake()->numberBetween(10000, 5000000), // 10KB a 5MB
            'storage_path' => 'organizations/1/documents/'.date('Y/m').'/'.fake()->uuid().'.pdf',
            'disk' => 's3',
            'description' => fake()->optional()->sentence(),
            'category' => fake()->randomElement(['invoice', 'receipt', 'contract', 'other']),
            'documentable_type' => null,
            'documentable_id' => null,
        ];
    }
}
