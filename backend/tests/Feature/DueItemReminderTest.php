<?php

namespace Tests\Feature;

use App\Jobs\SendDueItemReminderJob;
use App\Models\DueItem;
use App\Models\Organization;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

class DueItemReminderTest extends TestCase
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
     * Test reminder job is dispatched for upcoming due items.
     */
    public function test_reminder_job_is_dispatched_for_upcoming_items(): void
    {
        Queue::fake();

        $dueItem = DueItem::factory()->create([
            'organization_id' => $this->organization->id,
            'status' => 'pending',
            'due_date' => now()->addDays(2), // Vence em 2 dias
        ]);

        SendDueItemReminderJob::dispatch($dueItem, 'upcoming');

        Queue::assertPushed(SendDueItemReminderJob::class, function ($job) use ($dueItem) {
            return $job->dueItem->id === $dueItem->id && $job->type === 'upcoming';
        });
    }

    /**
     * Test reminder job creates notifications.
     */
    public function test_reminder_job_creates_notifications(): void
    {
        $dueItem = DueItem::factory()->create([
            'organization_id' => $this->organization->id,
            'status' => 'pending',
            'due_date' => now()->addDays(2),
        ]);

        $job = new SendDueItemReminderJob($dueItem, 'upcoming');
        $job->handle();

        $this->assertDatabaseHas('notifications', [
            'user_id' => $this->user->id,
            'organization_id' => $this->organization->id,
            'type' => 'due_item_reminder',
        ]);
    }

    /**
     * Test command queues reminders correctly.
     */
    public function test_command_queues_reminders_correctly(): void
    {
        Queue::fake();

        $today = now()->toDateString();
        $upcomingDate = now()->addDays(2)->toDateString();
        $overdueDate = now()->subDays(5)->toDateString();

        // Item que vence em 2 dias (deve entrar no upcoming com --days=3)
        $upcoming = DueItem::factory()->create([
            'organization_id' => $this->organization->id,
            'status' => 'pending',
            'due_date' => $upcomingDate,
        ]);

        // Item vencido há 5 dias (deve entrar no overdue)
        // Criar diretamente no banco para evitar hook do modelo que muda status automaticamente
        $overdueId = DB::table('due_items')->insertGetId([
            'organization_id' => $this->organization->id,
            'title' => 'Test Overdue Item',
            'amount' => 100.00,
            'due_date' => $overdueDate,
            'type' => 'pay',
            'status' => 'pending',
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        $overdue = DueItem::find($overdueId);

        $this->artisan('due-items:send-reminders', ['--days' => 3])
            ->assertSuccessful();

        // Verificar que ambos os jobs foram enfileirados
        Queue::assertPushed(SendDueItemReminderJob::class, 2);

        // Verificar que o job upcoming foi enfileirado com o item correto
        Queue::assertPushed(SendDueItemReminderJob::class, function ($job) use ($upcoming) {
            return $job->dueItem->id === $upcoming->id && $job->type === 'upcoming';
        });

        // Verificar que o job overdue foi enfileirado com o item correto
        Queue::assertPushed(SendDueItemReminderJob::class, function ($job) use ($overdue) {
            return $job->dueItem->id === $overdue->id && $job->type === 'overdue';
        });
    }
}
