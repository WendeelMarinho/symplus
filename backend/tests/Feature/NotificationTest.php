<?php

namespace Tests\Feature;

use App\Models\Notification;
use App\Models\Organization;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class NotificationTest extends TestCase
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
     * Test user can list notifications.
     */
    public function test_user_can_list_notifications(): void
    {
        Notification::factory()->count(3)->create([
            'user_id' => $this->user->id,
            'organization_id' => $this->organization->id,
        ]);

        $token = $this->user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->getJson('/api/notifications');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'data' => [
                    '*' => ['id', 'type', 'title', 'message', 'is_unread', 'read_at'],
                ],
            ]);

        $this->assertCount(3, $response->json('data'));
    }

    /**
     * Test user can get unread notifications count.
     */
    public function test_user_can_get_unread_count(): void
    {
        Notification::factory()->count(2)->create([
            'user_id' => $this->user->id,
            'organization_id' => $this->organization->id,
            'read_at' => null,
        ]);

        Notification::factory()->create([
            'user_id' => $this->user->id,
            'organization_id' => $this->organization->id,
            'read_at' => now(),
        ]);

        $token = $this->user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->getJson('/api/notifications/unread-count');

        $response->assertStatus(200)
            ->assertJson(['count' => 2]);
    }

    /**
     * Test user can mark notification as read.
     */
    public function test_user_can_mark_notification_as_read(): void
    {
        $notification = Notification::factory()->create([
            'user_id' => $this->user->id,
            'organization_id' => $this->organization->id,
            'read_at' => null,
        ]);

        $token = $this->user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->postJson("/api/notifications/{$notification->id}/mark-as-read");

        $response->assertStatus(200);

        $this->assertNotNull($notification->fresh()->read_at);
        $this->assertFalse($notification->fresh()->isUnread());
    }

    /**
     * Test user can mark all notifications as read.
     */
    public function test_user_can_mark_all_notifications_as_read(): void
    {
        Notification::factory()->count(3)->create([
            'user_id' => $this->user->id,
            'organization_id' => $this->organization->id,
            'read_at' => null,
        ]);

        $token = $this->user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->postJson('/api/notifications/mark-all-as-read');

        $response->assertStatus(200)
            ->assertJson(['message' => '3 notification(s) marked as read.']);

        $this->assertEquals(0, Notification::where('user_id', $this->user->id)
            ->where('organization_id', $this->organization->id)
            ->whereNull('read_at')
            ->count());
    }

    /**
     * Test notifications can be filtered by read status.
     */
    public function test_notifications_can_be_filtered_by_read_status(): void
    {
        Notification::factory()->create([
            'user_id' => $this->user->id,
            'organization_id' => $this->organization->id,
            'read_at' => null,
        ]);

        Notification::factory()->create([
            'user_id' => $this->user->id,
            'organization_id' => $this->organization->id,
            'read_at' => now(),
        ]);

        $token = $this->user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->getJson('/api/notifications?read=false');

        $response->assertStatus(200);
        $this->assertCount(1, $response->json('data'));
        $this->assertTrue($response->json('data.0.is_unread'));
    }

    /**
     * Test notifications respect tenant isolation.
     */
    public function test_notifications_respect_tenant_isolation(): void
    {
        $org2 = Organization::factory()->create();
        $org2->users()->attach($this->user->id, ['org_role' => 'owner']);

        Notification::factory()->create([
            'user_id' => $this->user->id,
            'organization_id' => $this->organization->id,
            'title' => 'Notification Org 1',
        ]);

        Notification::factory()->create([
            'user_id' => $this->user->id,
            'organization_id' => $org2->id,
            'title' => 'Notification Org 2',
        ]);

        $token = $this->user->createToken('test-token')->plainTextToken;

        // Listar com org1
        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->getJson('/api/notifications');

        $response->assertStatus(200);
        $this->assertCount(1, $response->json('data'));
        $this->assertEquals('Notification Org 1', $response->json('data.0.title'));
    }

    /**
     * Test user can only mark their own notifications as read.
     */
    public function test_user_cannot_mark_other_users_notification_as_read(): void
    {
        $otherUser = User::factory()->create();
        $this->organization->users()->attach($otherUser->id, ['org_role' => 'user']);

        $notification = Notification::factory()->create([
            'user_id' => $otherUser->id,
            'organization_id' => $this->organization->id,
        ]);

        $token = $this->user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->postJson("/api/notifications/{$notification->id}/mark-as-read");

        $response->assertStatus(403);
    }
}
