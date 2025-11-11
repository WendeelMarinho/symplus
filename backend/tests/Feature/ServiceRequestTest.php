<?php

namespace Tests\Feature;

use App\Models\Organization;
use App\Models\ServiceRequest;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ServiceRequestTest extends TestCase
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
     * Test user can list service requests.
     */
    public function test_user_can_list_service_requests(): void
    {
        ServiceRequest::factory()->count(3)->create([
            'organization_id' => $this->organization->id,
            'created_by' => $this->user->id,
        ]);

        $token = $this->user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->getJson('/api/service-requests');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'data' => [
                    '*' => ['id', 'title', 'description', 'status', 'priority', 'category'],
                ],
            ]);

        $this->assertCount(3, $response->json('data'));
    }

    /**
     * Test user can create service request.
     */
    public function test_user_can_create_service_request(): void
    {
        $token = $this->user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->postJson('/api/service-requests', [
                'title' => 'Payment issue',
                'description' => 'Cannot process payment',
                'priority' => 'high',
                'category' => 'billing',
            ]);

        $response->assertStatus(201)
            ->assertJsonStructure([
                'data' => ['id', 'title', 'description', 'status', 'priority', 'category'],
            ]);

        $this->assertDatabaseHas('service_requests', [
            'organization_id' => $this->organization->id,
            'created_by' => $this->user->id,
            'title' => 'Payment issue',
            'status' => 'open',
            'priority' => 'high',
        ]);
    }

    /**
     * Test user can mark service request as resolved.
     */
    public function test_user_can_mark_service_request_as_resolved(): void
    {
        $serviceRequest = ServiceRequest::factory()->create([
            'organization_id' => $this->organization->id,
            'created_by' => $this->user->id,
            'status' => 'in_progress',
        ]);

        $token = $this->user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->postJson("/api/service-requests/{$serviceRequest->id}/mark-resolved");

        $response->assertStatus(200);

        $this->assertDatabaseHas('service_requests', [
            'id' => $serviceRequest->id,
            'status' => 'resolved',
        ]);

        $this->assertNotNull($serviceRequest->fresh()->resolved_at);
    }

    /**
     * Test service requests can be filtered by status.
     */
    public function test_service_requests_can_be_filtered_by_status(): void
    {
        ServiceRequest::factory()->create([
            'organization_id' => $this->organization->id,
            'status' => 'open',
        ]);

        ServiceRequest::factory()->create([
            'organization_id' => $this->organization->id,
            'status' => 'resolved',
        ]);

        $token = $this->user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->getJson('/api/service-requests?status=open');

        $response->assertStatus(200);
        $this->assertCount(1, $response->json('data'));
        $this->assertEquals('open', $response->json('data.0.status'));
    }

    /**
     * Test service requests respect tenant isolation.
     */
    public function test_service_requests_respect_tenant_isolation(): void
    {
        $org2 = Organization::factory()->create();
        $org2->users()->attach($this->user->id, ['org_role' => 'owner']);

        ServiceRequest::factory()->create([
            'organization_id' => $this->organization->id,
            'title' => 'Ticket Org 1',
        ]);

        ServiceRequest::factory()->create([
            'organization_id' => $org2->id,
            'title' => 'Ticket Org 2',
        ]);

        $token = $this->user->createToken('test-token')->plainTextToken;

        // Listar com org1
        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->getJson('/api/service-requests');

        $response->assertStatus(200);
        $this->assertCount(1, $response->json('data'));
        $this->assertEquals('Ticket Org 1', $response->json('data.0.title'));
    }

    /**
     * Test user can add comment to service request.
     */
    public function test_user_can_add_comment_to_service_request(): void
    {
        $serviceRequest = ServiceRequest::factory()->create([
            'organization_id' => $this->organization->id,
            'created_by' => $this->user->id,
        ]);

        $token = $this->user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->postJson("/api/service-requests/{$serviceRequest->id}/comments", [
                'comment' => 'Investigating the issue',
                'is_internal' => false,
            ]);

        $response->assertStatus(201)
            ->assertJsonStructure([
                'data' => ['id', 'comment', 'is_internal', 'user'],
            ]);

        $this->assertDatabaseHas('service_request_comments', [
            'service_request_id' => $serviceRequest->id,
            'user_id' => $this->user->id,
            'comment' => 'Investigating the issue',
            'is_internal' => false,
        ]);
    }
}
