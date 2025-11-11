<?php

namespace Tests\Feature;

use App\Models\Organization;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TenantIsolationTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Test that users can only access their own organizations.
     */
    public function test_user_can_only_access_their_organizations(): void
    {
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();

        $org1 = Organization::factory()->create(['name' => 'Org 1']);
        $org2 = Organization::factory()->create(['name' => 'Org 2']);

        $org1->users()->attach($user1->id, ['org_role' => 'owner']);
        $org2->users()->attach($user2->id, ['org_role' => 'owner']);

        $token = $user1->createToken('test-token')->plainTextToken;

        // Tentar acessar com org1 (pertencente ao user)
        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', $org1->id)
            ->getJson('/api/me');

        $response->assertStatus(200);

        // Tentar acessar com org2 (não pertencente ao user)
        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', $org2->id)
            ->getJson('/api/me');

        $response->assertStatus(403)
            ->assertJson([
                'message' => 'You do not have access to this organization.',
            ]);
    }

    /**
     * Test that X-Organization-Id header is required.
     */
    public function test_organization_id_header_is_required(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('test-token')->plainTextToken;

        // Requisição sem header X-Organization-Id deve retornar 400
        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/me');

        // Middleware tenant exige o header
        $response->assertStatus(400)
            ->assertJson([
                'message' => 'Organization ID is required. Please provide X-Organization-Id header.',
            ]);
    }
}
