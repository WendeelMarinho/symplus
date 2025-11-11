<?php

namespace App\Console\Commands;

use App\Jobs\SendDueItemReminderJob;
use App\Models\DueItem;
use Illuminate\Console\Command;

class SendDueItemReminders extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'due-items:send-reminders 
                            {--days=3 : Number of days before due date to send reminder}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Send reminders for upcoming and overdue due items';

    /**
     * Execute the console command.
     */
    public function handle(): int
    {
        $days = (int) $this->option('days');
        $reminderDate = now()->addDays($days)->toDateString();
        $today = now()->toDateString();

        // Itens que vencem nos próximos N dias (status pending)
        // Remover TenantScope pois comandos console devem processar todas as organizações
        $upcomingItems = DueItem::withoutGlobalScope(\App\Scopes\TenantScope::class)
            ->where('status', 'pending')
            ->whereDate('due_date', '>=', $today)
            ->whereDate('due_date', '<=', $reminderDate)
            ->get();

        // Itens vencidos (pending ou overdue que ainda não foram marcados como paid)
        $overdueItems = DueItem::withoutGlobalScope(\App\Scopes\TenantScope::class)
            ->whereIn('status', ['pending', 'overdue'])
            ->whereDate('due_date', '<', $today)
            ->get();

        $totalItems = $upcomingItems->count() + $overdueItems->count();

        if ($totalItems === 0) {
            $this->info('No due items to remind.');

            return Command::SUCCESS;
        }

        // Enfileirar jobs de notificação
        foreach ($upcomingItems as $item) {
            SendDueItemReminderJob::dispatch($item->fresh(), 'upcoming');
        }

        foreach ($overdueItems as $item) {
            // Atualizar status para overdue se ainda estiver pending
            if ($item->status === 'pending') {
                $item->status = 'overdue';
                $item->save();
            }
            SendDueItemReminderJob::dispatch($item->fresh(), 'overdue');
        }

        $this->info("Queued {$totalItems} reminder(s) for due items.");

        return Command::SUCCESS;
    }
}
