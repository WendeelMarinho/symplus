<?php

namespace Tests\Feature;

use App\Models\Account;
use App\Models\Category;
use App\Models\Organization;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PlReportTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;
    protected Organization $organization;
    protected Account $account;
    protected Category $incomeCategory;
    protected Category $expenseCategory;

    protected function setUp(): void
    {
        parent::setUp();

        $this->organization = Organization::factory()->create();
        $this->user = User::factory()->create();
        $this->organization->users()->attach($this->user->id, ['org_role' => 'owner']);

        $this->account = Account::factory()->create([
            'organization_id' => $this->organization->id,
            'name' => 'Conta Teste',
        ]);

        $this->incomeCategory = Category::factory()->create([
            'organization_id' => $this->organization->id,
            'type' => 'income',
            'name' => 'Receitas',
        ]);

        $this->expenseCategory = Category::factory()->create([
            'organization_id' => $this->organization->id,
            'type' => 'expense',
            'name' => 'Despesas',
        ]);
    }

    /**
     * Test P&L report calculates totals correctly.
     */
    public function test_pl_report_calculates_totals_correctly(): void
    {
        // Criar transações
        Transaction::factory()->create([
            'organization_id' => $this->organization->id,
            'account_id' => $this->account->id,
            'category_id' => $this->incomeCategory->id,
            'type' => 'income',
            'amount' => 5000.00,
            'occurred_at' => now()->subDays(10),
        ]);

        Transaction::factory()->create([
            'organization_id' => $this->organization->id,
            'account_id' => $this->account->id,
            'category_id' => $this->expenseCategory->id,
            'type' => 'expense',
            'amount' => 3000.00,
            'occurred_at' => now()->subDays(5),
        ]);

        $token = $this->user->createToken('test-token')->plainTextToken;

        $from = now()->subMonth()->toDateString();
        $to = now()->toDateString();

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->getJson("/api/reports/pl?from={$from}&to={$to}");

        $response->assertStatus(200)
            ->assertJsonStructure([
                'period',
                'summary' => [
                    'total_income',
                    'total_expense',
                    'net_profit',
                    'expense_over_income_percent',
                ],
                'group_by',
                'series',
            ]);

        $data = $response->json();
        $this->assertEquals(5000.00, $data['summary']['total_income']);
        $this->assertEquals(3000.00, $data['summary']['total_expense']);
        $this->assertEquals(2000.00, $data['summary']['net_profit']);
        $this->assertEquals(60.0, $data['summary']['expense_over_income_percent']);
    }

    /**
     * Test P&L report groups by category.
     */
    public function test_pl_report_groups_by_category(): void
    {
        Transaction::factory()->count(2)->create([
            'organization_id' => $this->organization->id,
            'account_id' => $this->account->id,
            'category_id' => $this->incomeCategory->id,
            'type' => 'income',
            'amount' => 1000.00,
            'occurred_at' => now()->subDays(5),
        ]);

        Transaction::factory()->create([
            'organization_id' => $this->organization->id,
            'account_id' => $this->account->id,
            'category_id' => $this->expenseCategory->id,
            'type' => 'expense',
            'amount' => 500.00,
            'occurred_at' => now()->subDays(3),
        ]);

        $token = $this->user->createToken('test-token')->plainTextToken;

        $from = now()->subMonth()->toDateString();
        $to = now()->toDateString();

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->getJson("/api/reports/pl?from={$from}&to={$to}&group_by=category");

        $response->assertStatus(200);

        $series = $response->json('series');
        $this->assertIsArray($series);
        $this->assertNotEmpty($series);

        // Verificar se tem categoria de receita
        $incomeCategoryData = collect($series)->firstWhere('category_name', 'Receitas');
        $this->assertNotNull($incomeCategoryData);
        $this->assertEquals(2000.00, $incomeCategoryData['income']);
    }

    /**
     * Test P&L report groups by month.
     */
    public function test_pl_report_groups_by_month(): void
    {
        Transaction::factory()->create([
            'organization_id' => $this->organization->id,
            'account_id' => $this->account->id,
            'category_id' => $this->incomeCategory->id,
            'type' => 'income',
            'amount' => 1000.00,
            'occurred_at' => now()->subMonth()->startOfMonth(),
        ]);

        Transaction::factory()->create([
            'organization_id' => $this->organization->id,
            'account_id' => $this->account->id,
            'category_id' => $this->expenseCategory->id,
            'type' => 'expense',
            'amount' => 500.00,
            'occurred_at' => now()->startOfMonth(),
        ]);

        $token = $this->user->createToken('test-token')->plainTextToken;

        $from = now()->subMonths(2)->toDateString();
        $to = now()->toDateString();

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->getJson("/api/reports/pl?from={$from}&to={$to}&group_by=month");

        $response->assertStatus(200);

        $series = $response->json('series');
        $this->assertIsArray($series);
        $this->assertNotEmpty($series);

        // Verificar se tem dados agrupados por mês
        $this->assertArrayHasKey('month', $series[0]);
    }

    /**
     * Test P&L report validates date parameters.
     */
    public function test_pl_report_validates_date_parameters(): void
    {
        $token = $this->user->createToken('test-token')->plainTextToken;

        // Test sem parâmetros
        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->getJson('/api/reports/pl');

        $response->assertStatus(422);

        // Test com data inválida
        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->getJson('/api/reports/pl?from=invalid-date&to=2024-01-01');

        $response->assertStatus(422);

        // Test com 'to' anterior a 'from'
        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->getJson('/api/reports/pl?from=2024-01-31&to=2024-01-01');

        $response->assertStatus(422);
    }

    /**
     * Test P&L report respects tenant isolation.
     */
    public function test_pl_report_respects_tenant_isolation(): void
    {
        $org2 = Organization::factory()->create();
        $org2->users()->attach($this->user->id, ['org_role' => 'owner']);

        // Transação na org1
        Transaction::factory()->create([
            'organization_id' => $this->organization->id,
            'account_id' => $this->account->id,
            'category_id' => $this->incomeCategory->id,
            'type' => 'income',
            'amount' => 5000.00,
            'occurred_at' => now()->subDays(5),
        ]);

        // Transação na org2
        $account2 = Account::factory()->create(['organization_id' => $org2->id]);
        $category2 = Category::factory()->create([
            'organization_id' => $org2->id,
            'type' => 'income',
        ]);

        Transaction::factory()->create([
            'organization_id' => $org2->id,
            'account_id' => $account2->id,
            'category_id' => $category2->id,
            'type' => 'income',
            'amount' => 10000.00,
            'occurred_at' => now()->subDays(5),
        ]);

        $token = $this->user->createToken('test-token')->plainTextToken;

        $from = now()->subMonth()->toDateString();
        $to = now()->toDateString();

        // Relatório para org1
        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->getJson("/api/reports/pl?from={$from}&to={$to}");

        $response->assertStatus(200);
        $this->assertEquals(5000.00, $response->json('summary.total_income'));

        // Relatório para org2
        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $org2->id)
            ->getJson("/api/reports/pl?from={$from}&to={$to}");

        $response->assertStatus(200);
        $this->assertEquals(10000.00, $response->json('summary.total_income'));
    }
}
