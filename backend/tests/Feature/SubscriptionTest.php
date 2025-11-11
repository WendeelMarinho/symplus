<?php

namespace Tests\Feature;

use App\Models\Organization;
use App\Models\PlanLimit;
use App\Models\Subscription;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SubscriptionTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;
    protected Organization $organization;

    protected function setUp(): void
    {
        parent::setUp();

        // Seed plan limits
        PlanLimit::seedDefaultLimits();

        $this->organization = Organization::factory()->create();
        $this->user = User::factory()->create();
        $this->organization->users()->attach($this->user->id, ['org_role' => 'owner']);
    }

    /**
     * Test user can get current subscription.
     */
    public function test_user_can_get_current_subscription(): void
    {
        Subscription::factory()->create([
            'organization_id' => $this->organization->id,
            'plan' => 'basic',
            'status' => 'active',
        ]);

        $token = $this->user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->getJson('/api/subscription');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'data' => ['id', 'plan', 'status', 'is_active', 'plan_limits'],
            ]);

        $this->assertEquals('basic', $response->json('data.plan'));
    }

    /**
     * Test organization gets free plan if no subscription exists.
     */
    public function test_organization_gets_free_plan_by_default(): void
    {
        $token = $this->user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->getJson('/api/subscription');

        $response->assertStatus(200);
        $this->assertEquals('free', $response->json('data.plan'));
    }

    /**
     * Test organization can check feature limits.
     */
    public function test_organization_can_check_feature_limits(): void
    {
        Subscription::factory()->create([
            'organization_id' => $this->organization->id,
            'plan' => 'free',
            'status' => 'active',
        ]);

        // Free plan tem limite de 1 account
        $limit = $this->organization->getFeatureLimit('accounts');
        $this->assertEquals(1, $limit);

        // Verificar se pode usar feature
        $canUse = $this->organization->canUseFeature('accounts', 0);
        $this->assertTrue($canUse);

        $canUse = $this->organization->canUseFeature('accounts', 1);
        $this->assertFalse($canUse); // Limite atingido
    }

    /**
     * Test enterprise plan has unlimited features.
     */
    public function test_enterprise_plan_has_unlimited_features(): void
    {
        Subscription::factory()->create([
            'organization_id' => $this->organization->id,
            'plan' => 'enterprise',
            'status' => 'active',
        ]);

        $limit = $this->organization->getFeatureLimit('accounts');
        $this->assertNull($limit); // Unlimited

        // Sempre pode usar, mesmo com uso alto
        $canUse = $this->organization->canUseFeature('accounts', 9999);
        $this->assertTrue($canUse);
    }

    /**
     * Test subscription respects tenant isolation.
     */
    public function test_subscription_respects_tenant_isolation(): void
    {
        $org2 = Organization::factory()->create();
        $org2->users()->attach($this->user->id, ['org_role' => 'owner']);

        Subscription::factory()->create([
            'organization_id' => $this->organization->id,
            'plan' => 'basic',
        ]);

        Subscription::factory()->create([
            'organization_id' => $org2->id,
            'plan' => 'premium',
        ]);

        $token = $this->user->createToken('test-token')->plainTextToken;

        // Verificar subscription da org1
        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->getJson('/api/subscription');

        $response->assertStatus(200);
        $this->assertEquals('basic', $response->json('data.plan'));
    }

    /**
     * Test inactive subscription falls back to free plan.
     */
    public function test_inactive_subscription_falls_back_to_free_plan(): void
    {
        Subscription::factory()->create([
            'organization_id' => $this->organization->id,
            'plan' => 'premium',
            'status' => 'canceled',
            'ends_at' => now()->subDay(),
        ]);

        $plan = $this->organization->getCurrentPlan();
        $this->assertEquals('free', $plan);
    }
}
