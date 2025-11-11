<?php

namespace Tests\Feature;

use App\Models\DueItem;
use App\Models\Organization;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DueItemTest extends TestCase
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
     * Test user can list due items.
     */
    public function test_user_can_list_due_items(): void
    {
        DueItem::factory()->count(3)->create([
            'organization_id' => $this->organization->id,
        ]);

        $token = $this->user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->getJson('/api/due-items');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'data' => [
                    '*' => ['id', 'title', 'amount', 'due_date', 'type', 'status'],
                ],
            ]);

        $this->assertCount(3, $response->json('data'));
    }

    /**
     * Test user can create due item.
     */
    public function test_user_can_create_due_item(): void
    {
        $token = $this->user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->postJson('/api/due-items', [
                'title' => 'Conta de Energia',
                'amount' => 250.50,
                'due_date' => now()->addDays(10)->toDateString(),
                'type' => 'pay',
                'description' => 'Conta de energia elétrica',
            ]);

        $response->assertStatus(201)
            ->assertJsonStructure([
                'data' => ['id', 'title', 'amount', 'due_date', 'type', 'status'],
            ]);

        $this->assertDatabaseHas('due_items', [
            'organization_id' => $this->organization->id,
            'title' => 'Conta de Energia',
            'amount' => 250.50,
            'type' => 'pay',
        ]);
    }

    /**
     * Test user can mark due item as paid.
     */
    public function test_user_can_mark_due_item_as_paid(): void
    {
        $dueItem = DueItem::factory()->create([
            'organization_id' => $this->organization->id,
            'status' => 'pending',
        ]);

        $token = $this->user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->postJson("/api/due-items/{$dueItem->id}/mark-paid");

        $response->assertStatus(200);

        $this->assertDatabaseHas('due_items', [
            'id' => $dueItem->id,
            'status' => 'paid',
        ]);
    }

    /**
     * Test due items are filtered by status.
     */
    public function test_due_items_can_be_filtered_by_status(): void
    {
        DueItem::factory()->create([
            'organization_id' => $this->organization->id,
            'status' => 'pending',
        ]);

        DueItem::factory()->create([
            'organization_id' => $this->organization->id,
            'status' => 'paid',
        ]);

        $token = $this->user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->getJson('/api/due-items?status=pending');

        $response->assertStatus(200);
        $this->assertCount(1, $response->json('data'));
        $this->assertEquals('pending', $response->json('data.0.status'));
    }

    /**
     * Test due items respect tenant isolation.
     */
    public function test_due_items_respect_tenant_isolation(): void
    {
        $org2 = Organization::factory()->create();
        $org2->users()->attach($this->user->id, ['org_role' => 'owner']);

        DueItem::factory()->create([
            'organization_id' => $this->organization->id,
            'title' => 'Item Org 1',
        ]);

        DueItem::factory()->create([
            'organization_id' => $org2->id,
            'title' => 'Item Org 2',
        ]);

        $token = $this->user->createToken('test-token')->plainTextToken;

        // Listar com org1
        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->getJson('/api/due-items');

        $response->assertStatus(200);
        $this->assertCount(1, $response->json('data'));
        $this->assertEquals('Item Org 1', $response->json('data.0.title'));
    }
}
