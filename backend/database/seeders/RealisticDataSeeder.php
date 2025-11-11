<?php

namespace Database\Seeders;

use App\Models\Account;
use App\Models\Category;
use App\Models\Document;
use App\Models\DueItem;
use App\Models\Notification;
use App\Models\Organization;
use App\Models\ServiceRequest;
use App\Models\ServiceRequestComment;
use App\Models\Subscription;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class RealisticDataSeeder extends Seeder
{
    /**
     * Seed realistic data for development and testing.
     */
    public function run(): void
    {
        // Seed plan limits primeiro
        $this->call(PlanLimitSeeder::class);

        // Criar múltiplas organizações
        $organizations = $this->createOrganizations();
        $this->command->info('✅ Organizations ready: '.count($organizations).' organizations');

        foreach ($organizations as $orgData) {
            $organization = $orgData['org'];
            $users = $orgData['users'];

            // Criar categorias realistas
            $categories = $this->createCategories($organization);
            $this->command->info("✅ Created ".count($categories)." categories for {$organization->name}");

            // Criar contas realistas
            $accounts = $this->createAccounts($organization);
            $this->command->info("✅ Created ".count($accounts)." accounts for {$organization->name}");

            // Criar transações dos últimos 12 meses
            $transactions = $this->createTransactions($organization, $accounts, $categories);
            $this->command->info("✅ Created ".count($transactions)." transactions for {$organization->name}");

            // Criar due items
            $dueItems = $this->createDueItems($organization);
            $this->command->info("✅ Created ".count($dueItems)." due items for {$organization->name}");

            // Criar service requests
            $serviceRequests = $this->createServiceRequests($organization, $users);
            $this->command->info("✅ Created ".count($serviceRequests)." service requests for {$organization->name}");

            // Criar notificações
            $notifications = $this->createNotifications($organization, $users);
            $this->command->info("✅ Created ".count($notifications)." notifications for {$organization->name}");
        }

        $this->command->info('');
        $this->command->info('✅ Realistic data seeded successfully!');
        $this->command->info('');
        $this->command->info('Login credentials:');
        $this->command->info('  - admin@symplus.dev / password (owner)');
        $this->command->info('  - demo@example.com / password (owner)');
        $this->command->info('  - team@example.com / password (admin)');
    }

    private function createOrganizations(): array
    {
        $organizations = [];

        // Organização 1: Symplus Dev (Free plan)
        $org1 = Organization::firstOrCreate(
            ['slug' => 'symplus-dev'],
            ['name' => 'Symplus Dev']
        );

        $user1 = User::firstOrCreate(
            ['email' => 'admin@symplus.dev'],
            [
                'name' => 'Admin User',
                'password' => Hash::make('password'),
                'email_verified_at' => now(),
            ]
        );

        if (!$org1->users()->where('user_id', $user1->id)->exists()) {
            $org1->users()->attach($user1->id, ['org_role' => 'owner']);
        }

        Subscription::firstOrCreate(
            ['organization_id' => $org1->id],
            [
                'plan' => 'free',
                'status' => 'active',
            ]
        );

        $organizations[] = ['org' => $org1, 'users' => [$user1]];

        // Organização 2: Demo Company (Basic plan)
        $org2 = Organization::firstOrCreate(
            ['slug' => 'demo-company'],
            ['name' => 'Demo Company']
        );

        $user2 = User::firstOrCreate(
            ['email' => 'demo@example.com'],
            [
                'name' => 'Demo Owner',
                'password' => Hash::make('password'),
                'email_verified_at' => now(),
            ]
        );

        $user3 = User::firstOrCreate(
            ['email' => 'team@example.com'],
            [
                'name' => 'Team Member',
                'password' => Hash::make('password'),
                'email_verified_at' => now(),
            ]
        );

        if (!$org2->users()->where('user_id', $user2->id)->exists()) {
            $org2->users()->attach($user2->id, ['org_role' => 'owner']);
        }

        if (!$org2->users()->where('user_id', $user3->id)->exists()) {
            $org2->users()->attach($user3->id, ['org_role' => 'admin']);
        }

        Subscription::firstOrCreate(
            ['organization_id' => $org2->id],
            [
                'plan' => 'basic',
                'status' => 'active',
            ]
        );

        $organizations[] = ['org' => $org2, 'users' => [$user2, $user3]];

        return $organizations;
    }

    private function createCategories(Organization $organization): array
    {
        $categories = [
            // Receitas
            ['type' => 'income', 'name' => 'Salário', 'color' => '#10b981'],
            ['type' => 'income', 'name' => 'Freelance', 'color' => '#059669'],
            ['type' => 'income', 'name' => 'Investimentos', 'color' => '#047857'],
            ['type' => 'income', 'name' => 'Vendas', 'color' => '#065f46'],

            // Despesas
            ['type' => 'expense', 'name' => 'Alimentação', 'color' => '#ef4444'],
            ['type' => 'expense', 'name' => 'Transporte', 'color' => '#dc2626'],
            ['type' => 'expense', 'name' => 'Moradia', 'color' => '#b91c1c'],
            ['type' => 'expense', 'name' => 'Saúde', 'color' => '#991b1b'],
            ['type' => 'expense', 'name' => 'Educação', 'color' => '#7f1d1d'],
            ['type' => 'expense', 'name' => 'Lazer', 'color' => '#f59e0b'],
            ['type' => 'expense', 'name' => 'Compras', 'color' => '#d97706'],
            ['type' => 'expense', 'name' => 'Contas', 'color' => '#92400e'],
        ];

        $created = [];
        foreach ($categories as $cat) {
            $created[] = Category::firstOrCreate(
                [
                    'organization_id' => $organization->id,
                    'type' => $cat['type'],
                    'name' => $cat['name'],
                ],
                ['color' => $cat['color']]
            );
        }

        return $created;
    }

    private function createAccounts(Organization $organization): array
    {
        $accounts = [
            ['name' => 'Conta Corrente', 'currency' => 'BRL', 'opening_balance' => 5000.00],
            ['name' => 'Conta Poupança', 'currency' => 'BRL', 'opening_balance' => 15000.00],
            ['name' => 'Cartão de Crédito', 'currency' => 'BRL', 'opening_balance' => -2500.00],
        ];

        $created = [];
        foreach ($accounts as $acc) {
            $created[] = Account::firstOrCreate(
                [
                    'organization_id' => $organization->id,
                    'name' => $acc['name'],
                ],
                [
                    'currency' => $acc['currency'],
                    'opening_balance' => $acc['opening_balance'],
                ]
            );
        }

        return $created;
    }

    private function createTransactions(Organization $organization, array $accounts, array $categories): array
    {
        $transactions = [];
        $incomeCategories = array_filter($categories, fn($c) => $c->type === 'income');
        $expenseCategories = array_filter($categories, fn($c) => $c->type === 'expense');

        $startDate = now()->subMonths(12)->startOfMonth();
        $endDate = now();

        // Criar transações mensais
        for ($month = $startDate->copy(); $month->lte($endDate); $month->addMonth()) {
            // Receitas mensais
            $salaryDate = $month->copy()->day(5);
            if ($salaryDate->lte(now())) {
                $transactions[] = Transaction::create([
                    'organization_id' => $organization->id,
                    'account_id' => $accounts[0]->id, // Conta Corrente
                    'category_id' => $incomeCategories[array_rand($incomeCategories)]->id,
                    'type' => 'income',
                    'amount' => fake()->randomFloat(2, 3000, 8000),
                    'occurred_at' => $salaryDate,
                    'description' => 'Salário mensal',
                ]);
            }

            // Despesas variadas ao longo do mês
            $numExpenses = fake()->numberBetween(15, 30);
            for ($i = 0; $i < $numExpenses; $i++) {
                $transactionDate = $month->copy()->addDays(fake()->numberBetween(1, $month->daysInMonth));
                if ($transactionDate->lte(now())) {
                    $category = $expenseCategories[array_rand($expenseCategories)];
                    $amount = match ($category->name) {
                        'Moradia' => fake()->randomFloat(2, 800, 2000),
                        'Alimentação' => fake()->randomFloat(2, 20, 150),
                        'Transporte' => fake()->randomFloat(2, 10, 100),
                        default => fake()->randomFloat(2, 10, 500),
                    };

                    $transactions[] = Transaction::create([
                        'organization_id' => $organization->id,
                        'account_id' => fake()->randomElement($accounts)->id,
                        'category_id' => $category->id,
                        'type' => 'expense',
                        'amount' => $amount,
                        'occurred_at' => $transactionDate,
                        'description' => fake()->sentence(3),
                    ]);
                }
            }
        }

        return $transactions;
    }

    private function createDueItems(Organization $organization): array
    {
        $dueItems = [];

        // Criar itens de pagamento e recebimento
        for ($i = 0; $i < 10; $i++) {
            $type = fake()->randomElement(['pay', 'receive']);
            $daysFromNow = fake()->numberBetween(-15, 30);
            $dueDate = now()->addDays($daysFromNow);

            $dueItems[] = DueItem::create([
                'organization_id' => $organization->id,
                'title' => $type === 'pay' 
                    ? fake()->randomElement([
                        'Pagamento fornecedor',
                        'Aluguel',
                        'Salário funcionários',
                        'Conta de luz',
                        'Internet e telefone',
                    ])
                    : fake()->randomElement([
                        'Recebimento cliente',
                        'Faturamento projeto',
                        'Pagamento de serviços',
                    ]),
                'amount' => fake()->randomFloat(2, 100, 5000),
                'due_date' => $dueDate->format('Y-m-d'),
                'type' => $type,
                'status' => $dueDate->isPast() ? 'overdue' : 'pending',
                'description' => fake()->optional(0.7)->sentence(),
            ]);
        }

        // Marcar alguns como pagos
        foreach (fake()->randomElements($dueItems, 3) as $item) {
            $item->update(['status' => 'paid']);
        }

        return $dueItems;
    }

    private function createServiceRequests(Organization $organization, array $users): array
    {
        $serviceRequests = [];

        $priorities = ['low', 'medium', 'high'];
        $statuses = ['open', 'in_progress', 'resolved', 'closed'];

        for ($i = 0; $i < 8; $i++) {
            $creator = fake()->randomElement($users);
            $assignee = fake()->randomElement($users);

            $sr = ServiceRequest::create([
                'organization_id' => $organization->id,
                'created_by' => $creator->id,
                'assigned_to' => $assignee->id,
                'title' => fake()->randomElement([
                    'Implementar relatório de vendas',
                    'Corrigir bug no dashboard',
                    'Adicionar exportação para Excel',
                    'Melhorar performance da listagem',
                    'Criar nova funcionalidade de relatórios',
                ]),
                'description' => fake()->paragraph(3),
                'category' => fake()->randomElement(['bug', 'feature', 'improvement', 'question']),
                'priority' => fake()->randomElement($priorities),
                'status' => fake()->randomElement($statuses),
            ]);

            // Adicionar comentários
            $numComments = fake()->numberBetween(0, 5);
            for ($j = 0; $j < $numComments; $j++) {
                ServiceRequestComment::create([
                    'service_request_id' => $sr->id,
                    'user_id' => fake()->randomElement($users)->id,
                    'comment' => fake()->paragraph(2),
                    'is_internal' => fake()->boolean(30),
                ]);
            }

            // Se resolvido ou fechado, definir data
            if (in_array($sr->status, ['resolved', 'closed'])) {
                $sr->update([
                    'resolved_at' => now()->subDays(fake()->numberBetween(1, 30)),
                ]);
            }

            if ($sr->status === 'closed') {
                $sr->update([
                    'closed_at' => now()->subDays(fake()->numberBetween(1, 15)),
                ]);
            }

            $serviceRequests[] = $sr;
        }

        return $serviceRequests;
    }

    private function createNotifications(Organization $organization, array $users): array
    {
        $notifications = [];

        foreach ($users as $user) {
            $numNotifications = fake()->numberBetween(3, 8);

            for ($i = 0; $i < $numNotifications; $i++) {
                $notifications[] = Notification::create([
                    'organization_id' => $organization->id,
                    'user_id' => $user->id,
                    'type' => fake()->randomElement(['due_item', 'transaction', 'service_request', 'system']),
                    'title' => fake()->sentence(4),
                    'message' => fake()->paragraph(1),
                    'data' => [],
                    'read_at' => fake()->boolean(40) ? now()->subDays(fake()->numberBetween(1, 7)) : null,
                ]);
            }
        }

        return $notifications;
    }
}

