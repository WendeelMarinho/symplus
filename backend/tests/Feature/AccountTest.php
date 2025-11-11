<?php

namespace Tests\Feature;

use App\Models\Account;
use App\Models\Organization;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AccountTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;
    protected Organization $organization;

    protected function setUp(): void
    {
        parent::setUp();

        $this->organization = Organization::factory()->create();
        $this->user = User::factory()->create();
        $this->organization->users()->attach($this->user->id, ['org_role' => 'owner']);
    }

    /**
     * Test user can list accounts.
     */
    public function test_user_can_list_accounts(): void
    {
        Account::factory()->count(3)->create([
            'organization_id' => $this->organization->id,
        ]);

        $token = $this->user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->getJson('/api/accounts');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'data' => [
                    '*' => ['id', 'name', 'currency', 'opening_balance'],
                ],
            ]);

        $this->assertCount(3, $response->json('data'));
    }

    /**
     * Test user can create account.
     */
    public function test_user_can_create_account(): void
    {
        $token = $this->user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->postJson('/api/accounts', [
                'name' => 'Conta Corrente',
                'currency' => 'BRL',
                'opening_balance' => 1000.50,
            ]);

        $response->assertStatus(201)
            ->assertJsonStructure([
                'data' => ['id', 'name', 'currency', 'opening_balance'],
            ]);

        $this->assertDatabaseHas('accounts', [
            'organization_id' => $this->organization->id,
            'name' => 'Conta Corrente',
            'currency' => 'BRL',
            'opening_balance' => 1000.50,
        ]);
    }

    /**
     * Test accounts are isolated by organization.
     */
    public function test_accounts_are_isolated_by_organization(): void
    {
        $org2 = Organization::factory()->create();
        $org2->users()->attach($this->user->id, ['org_role' => 'owner']);

        Account::factory()->create([
            'organization_id' => $this->organization->id,
            'name' => 'Account Org 1',
        ]);

        Account::factory()->create([
            'organization_id' => $org2->id,
            'name' => 'Account Org 2',
        ]);

        $token = $this->user->createToken('test-token')->plainTextToken;

        // Listar com org1
        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->getJson('/api/accounts');

        $response->assertStatus(200);
        $this->assertCount(1, $response->json('data'));
        $this->assertEquals('Account Org 1', $response->json('data.0.name'));
    }
}
