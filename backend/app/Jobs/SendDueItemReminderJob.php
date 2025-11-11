<?php

namespace App\Jobs;

use App\Models\DueItem;
use App\Models\Notification;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class SendDueItemReminderJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    /**
     * Create a new job instance.
     */
    public function __construct(
        public DueItem $dueItem,
        public string $type = 'upcoming'
    ) {
        $this->onQueue('notifications');
    }

    /**
     * Execute the job.
     */
    public function handle(): void
    {
        $organization = $this->dueItem->organization;

        // Notificar todos os usuários da organização que são owners ou admins
        $users = $organization->users()
            ->wherePivotIn('org_role', ['owner', 'admin'])
            ->get();

        $dueDate = \Carbon\Carbon::parse($this->dueItem->due_date);

        $message = $this->type === 'overdue'
            ? "O item '{$this->dueItem->title}' está vencido desde {$dueDate->format('d/m/Y')}."
            : "O item '{$this->dueItem->title}' vence em {$dueDate->diffForHumans()}.";

        foreach ($users as $user) {
            Notification::create([
                'user_id' => $user->id,
                'organization_id' => $organization->id,
                'type' => 'due_item_reminder',
                'title' => $this->type === 'overdue' ? 'Item Vencido' : 'Item Próximo do Vencimento',
                'message' => $message,
                'data' => [
                    'due_item_id' => $this->dueItem->id,
                    'type' => $this->type,
                ],
                'read_at' => null,
            ]);
        }
    }
}
