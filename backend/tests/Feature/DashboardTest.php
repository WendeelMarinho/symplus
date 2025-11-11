<?php

namespace Tests\Feature;

use App\Models\Account;
use App\Models\Category;
use App\Models\DueItem;
use App\Models\Organization;
use App\Models\Subscription;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DashboardTest extends TestCase
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

        // Criar subscription gratuita
        Subscription::create([
            'organization_id' => $this->organization->id,
            'plan' => 'free',
            'status' => 'active',
        ]);
    }

    /**
     * Test user can get dashboard data.
     */
    public function test_user_can_get_dashboard_data(): void
    {
        $token = $this->user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->getJson('/api/dashboard');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'data' => [
                    'financial_summary' => ['income', 'expenses', 'net', 'period'],
                    'recent_transactions' => [],
                    'upcoming_due_items' => [],
                    'overdue_items' => [],
                    'account_balances' => [],
                    'monthly_income_expense' => [],
                    'top_categories' => ['income', 'expenses'],
                    'cash_flow_projection' => [
                        'current_balance',
                        'projected_income',
                        'projected_expenses',
                        'projected_balance',
                    ],
                ],
            ]);
    }

    /**
     * Test dashboard includes financial summary.
     */
    public function test_dashboard_includes_financial_summary(): void
    {
        $account = Account::factory()->create([
            'organization_id' => $this->organization->id,
        ]);

        $category = Category::factory()->create([
            'organization_id' => $this->organization->id,
            'type' => 'income',
        ]);

        // Criar algumas transações este mês
        Transaction::factory()->create([
            'organization_id' => $this->organization->id,
            'account_id' => $account->id,
            'category_id' => $category->id,
            'type' => 'income',
            'amount' => 1000.00,
            'occurred_at' => now(),
        ]);

        Transaction::factory()->create([
            'organization_id' => $this->organization->id,
            'account_id' => $account->id,
            'type' => 'expense',
            'amount' => 500.00,
            'occurred_at' => now(),
        ]);

        $token = $this->user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->getJson('/api/dashboard');

        $response->assertStatus(200);

        $financialSummary = $response->json('data.financial_summary');
        $this->assertEquals(1000.0, $financialSummary['income']);
        $this->assertEquals(500.0, $financialSummary['expenses']);
        $this->assertEquals(500.0, $financialSummary['net']);
    }

    /**
     * Test dashboard includes recent transactions.
     */
    public function test_dashboard_includes_recent_transactions(): void
    {
        $account = Account::factory()->create([
            'organization_id' => $this->organization->id,
        ]);

        // Criar 15 transações
        Transaction::factory()->count(15)->create([
            'organization_id' => $this->organization->id,
            'account_id' => $account->id,
            'occurred_at' => now(),
        ]);

        $token = $this->user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->getJson('/api/dashboard');

        $response->assertStatus(200);

        $recentTransactions = $response->json('data.recent_transactions');
        // Deve retornar apenas as últimas 10
        $this->assertCount(10, $recentTransactions);
    }

    /**
     * Test dashboard includes upcoming due items.
     */
    public function test_dashboard_includes_upcoming_due_items(): void
    {
        // Criar item que vence em 3 dias
        $dueDate = now()->addDays(3)->startOfDay();
        DueItem::factory()->create([
            'organization_id' => $this->organization->id,
            'status' => 'pending',
            'due_date' => $dueDate->toDateString(),
            'type' => 'pay',
        ]);

        // Criar item que vence em 10 dias (não deve aparecer, pois é > 7 dias)
        DueItem::factory()->create([
            'organization_id' => $this->organization->id,
            'status' => 'pending',
            'due_date' => now()->addDays(10)->toDateString(),
            'type' => 'pay',
        ]);

        $token = $this->user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->getJson('/api/dashboard');

        $response->assertStatus(200);

        $upcomingDueItems = $response->json('data.upcoming_due_items');
        $this->assertCount(1, $upcomingDueItems);
        // Aceitar 2 ou 3 dias (pode variar por causa do horário)
        $daysUntilDue = $upcomingDueItems[0]['days_until_due'];
        $this->assertGreaterThanOrEqual(2, $daysUntilDue);
        $this->assertLessThanOrEqual(3, $daysUntilDue);
    }

    /**
     * Test dashboard includes overdue items.
     */
    public function test_dashboard_includes_overdue_items(): void
    {
        // Criar item vencido
        DueItem::factory()->create([
            'organization_id' => $this->organization->id,
            'status' => 'pending',
            'due_date' => now()->subDays(5)->toDateString(),
            'type' => 'pay',
        ]);

        $token = $this->user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->getJson('/api/dashboard');

        $response->assertStatus(200);

        $overdueItems = $response->json('data.overdue_items');
        $this->assertCount(1, $overdueItems);
        $this->assertEquals(5, $overdueItems[0]['days_overdue']);
    }

    /**
     * Test dashboard includes account balances.
     */
    public function test_dashboard_includes_account_balances(): void
    {
        $account1 = Account::factory()->create([
            'organization_id' => $this->organization->id,
            'opening_balance' => 0.00,
        ]);

        $account2 = Account::factory()->create([
            'organization_id' => $this->organization->id,
            'opening_balance' => 0.00,
        ]);

        // Limpar qualquer transação existente da factory
        Transaction::where('account_id', $account1->id)->delete();
        Transaction::where('account_id', $account2->id)->delete();

        // Adicionar transação específica para calcular saldo
        Transaction::factory()->create([
            'organization_id' => $this->organization->id,
            'account_id' => $account1->id,
            'type' => 'income',
            'amount' => 500.00,
        ]);

        $token = $this->user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->getJson('/api/dashboard');

        $response->assertStatus(200);

        $accountBalances = $response->json('data.account_balances');
        $this->assertCount(2, $accountBalances);

        // Verificar que a conta 1 tem saldo calculado
        $account1Data = collect($accountBalances)->firstWhere('id', $account1->id);
        $this->assertNotNull($account1Data);
        // Saldo = opening_balance (0) + transaction income (500) = 500
        $this->assertEquals(500.0, $account1Data['balance'], 'Account balance should be 500.0');
    }

    /**
     * Test dashboard respects tenant isolation.
     */
    public function test_dashboard_respects_tenant_isolation(): void
    {
        $org2 = Organization::factory()->create();
        $org2->users()->attach($this->user->id, ['org_role' => 'owner']);

        // Criar transação na org1 este mês (para aparecer no financial_summary)
        $account1 = Account::factory()->create([
            'organization_id' => $this->organization->id,
        ]);
        Transaction::factory()->create([
            'organization_id' => $this->organization->id,
            'account_id' => $account1->id,
            'type' => 'income',
            'amount' => 1000.00,
            'occurred_at' => now(), // Este mês
        ]);

        // Criar transação na org2 este mês
        $account2 = Account::factory()->create([
            'organization_id' => $org2->id,
        ]);
        Transaction::factory()->create([
            'organization_id' => $org2->id,
            'account_id' => $account2->id,
            'type' => 'income',
            'amount' => 2000.00,
            'occurred_at' => now(), // Este mês
        ]);

        $token = $this->user->createToken('test-token')->plainTextToken;

        // Verificar dashboard da org1
        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->getJson('/api/dashboard');

        $response->assertStatus(200);

        $financialSummary = $response->json('data.financial_summary');
        // Org1 deve ter apenas uma transação de 1000 (income) este mês
        // Org2 tem 2000, mas não deve aparecer no dashboard da org1
        $this->assertEquals(1000.0, $financialSummary['income'], 'Org1 should have only 1000 in income this month');
        $this->assertEquals(0.0, $financialSummary['expenses'], 'Org1 should have 0 expenses this month');
    }
}
