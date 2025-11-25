<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Account;
use App\Models\Category;
use App\Models\DueItem;
use App\Models\Organization;
use App\Models\Transaction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    /**
     * Get aggregated dashboard data.
     * 
     * Query parameters:
     * - from: Start date (Y-m-d format, optional, defaults to start of current month)
     * - to: End date (Y-m-d format, optional, defaults to end of current month)
     */
    public function index(Request $request): JsonResponse
    {
        $organizationId = $request->header('X-Organization-Id');
        $organization = Organization::findOrFail($organizationId);

        // Parse date filters from query parameters
        $from = $request->input('from') 
            ? \Carbon\Carbon::parse($request->input('from'))->startOfDay()
            : now()->startOfMonth();
        $to = $request->input('to')
            ? \Carbon\Carbon::parse($request->input('to'))->endOfDay()
            : now()->endOfMonth();

        $data = [
            'financial_summary' => $this->getFinancialSummary($organizationId, $from, $to),
            'recent_transactions' => $this->getRecentTransactions($organizationId, $from, $to),
            'upcoming_due_items' => $this->getUpcomingDueItems($organizationId),
            'overdue_items' => $this->getOverdueItems($organizationId),
            'account_balances' => $this->getAccountBalances($organizationId),
            'monthly_income_expense' => $this->getMonthlyIncomeExpense($organizationId, $from, $to),
            'top_categories' => $this->getTopCategories($organizationId, $from, $to),
            'cash_flow_projection' => $this->getCashFlowProjection($organizationId),
        ];

        return response()->json(['data' => $data]);
    }

    /**
     * Get financial summary (total income, expenses, net).
     */
    protected function getFinancialSummary(int $organizationId, $from = null, $to = null): array
    {
        $from = $from ?? now()->startOfMonth();
        $to = $to ?? now()->endOfMonth();

        $income = Transaction::where('organization_id', $organizationId)
            ->where('type', 'income')
            ->whereBetween('occurred_at', [$from, $to])
            ->sum('amount');

        $expenses = Transaction::where('organization_id', $organizationId)
            ->where('type', 'expense')
            ->whereBetween('occurred_at', [$from, $to])
            ->sum('amount');

        $net = $income - $expenses;

        return [
            'income' => (float) $income,
            'expenses' => (float) $expenses,
            'net' => (float) $net,
            'period' => [
                'from' => $from->toIso8601String(),
                'to' => $to->toIso8601String(),
            ],
        ];
    }

    /**
     * Get recent transactions (last 10, filtered by period if provided).
     */
    protected function getRecentTransactions(int $organizationId, $from = null, $to = null): array
    {
        $query = Transaction::where('organization_id', $organizationId)
            ->with(['account', 'category']);
        
        if ($from && $to) {
            $query->whereBetween('occurred_at', [$from, $to]);
        }
        
        $transactions = $query
            ->orderBy('occurred_at', 'desc')
            ->orderBy('created_at', 'desc')
            ->limit(10)
            ->get();

        return $transactions->map(function ($transaction) {
            return [
                'id' => $transaction->id,
                'description' => $transaction->description,
                'amount' => (float) $transaction->amount,
                'type' => $transaction->type,
                'occurred_at' => $transaction->occurred_at->toIso8601String(),
                'account' => [
                    'id' => $transaction->account->id,
                    'name' => $transaction->account->name,
                ],
                'category' => $transaction->category ? [
                    'id' => $transaction->category->id,
                    'name' => $transaction->category->name,
                ] : null,
            ];
        })->toArray();
    }

    /**
     * Get upcoming due items (next 7 days).
     */
    protected function getUpcomingDueItems(int $organizationId): array
    {
        $from = now()->toDateString();
        $to = now()->addDays(7)->toDateString();

        $dueItems = DueItem::where('organization_id', $organizationId)
            ->where('status', 'pending')
            ->whereBetween('due_date', [$from, $to])
            ->orderBy('due_date', 'asc')
            ->get();

        return $dueItems->map(function ($item) {
            return [
                'id' => $item->id,
                'title' => $item->title,
                'amount' => (float) $item->amount,
                'type' => $item->type,
                'due_date' => $item->due_date->format('Y-m-d'),
                'status' => $item->status,
                'days_until_due' => (int) now()->diffInDays($item->due_date, false),
            ];
        })->toArray();
    }

    /**
     * Get overdue items.
     */
    protected function getOverdueItems(int $organizationId): array
    {
        $dueItems = DueItem::where('organization_id', $organizationId)
            ->whereIn('status', ['pending', 'overdue'])
            ->whereDate('due_date', '<', now()->toDateString())
            ->orderBy('due_date', 'asc')
            ->get();

        return $dueItems->map(function ($item) {
            return [
                'id' => $item->id,
                'title' => $item->title,
                'amount' => (float) $item->amount,
                'type' => $item->type,
                'due_date' => $item->due_date->format('Y-m-d'),
                'status' => $item->status,
                'days_overdue' => (int) abs(now()->diffInDays($item->due_date, false)),
            ];
        })->toArray();
    }

    /**
     * Get account balances.
     */
    protected function getAccountBalances(int $organizationId): array
    {
        $accounts = Account::where('organization_id', $organizationId)
            ->with('transactions')
            ->get();

        return $accounts->map(function ($account) {
            return [
                'id' => $account->id,
                'name' => $account->name,
                'balance' => (float) $account->current_balance,
            ];
        })->toArray();
    }

    /**
     * Get monthly income and expense for the period (or last 6 months if not specified).
     */
    protected function getMonthlyIncomeExpense(int $organizationId, $from = null, $to = null): array
    {
        $driver = DB::connection()->getDriverName();
        $dateFormat = match ($driver) {
            'sqlite' => "strftime('%Y-%m', occurred_at)",
            'mysql' => "DATE_FORMAT(occurred_at, '%Y-%m')",
            default => "to_char(occurred_at, 'YYYY-MM')", // PostgreSQL
        };

        // If period is specified, use it; otherwise use last 6 months
        if ($from && $to) {
            $periodStart = $from->copy()->startOfMonth();
            $periodEnd = $to->copy()->endOfMonth();
            $months = [];
            $current = $periodStart->copy();
            while ($current->lte($periodEnd)) {
                $months[] = $current->format('Y-m');
                $current->addMonth();
            }
        } else {
            $months = [];
            for ($i = 5; $i >= 0; --$i) {
                $month = now()->subMonths($i);
                $months[] = $month->format('Y-m');
            }
            $periodStart = now()->subMonths(6)->startOfMonth();
            $periodEnd = now()->endOfMonth();
        }

        $results = Transaction::where('organization_id', $organizationId)
            ->where('occurred_at', '>=', $periodStart)
            ->where('occurred_at', '<=', $periodEnd)
            ->selectRaw("
                {$dateFormat} as month,
                type,
                SUM(amount) as total
            ")
            ->groupBy('month', 'type')
            ->orderBy('month')
            ->get();

        $monthlyData = [];
        foreach ($months as $month) {
            $income = $results
                ->where('month', $month)
                ->where('type', 'income')
                ->first();

            $expense = $results
                ->where('month', $month)
                ->where('type', 'expense')
                ->first();

            $monthlyData[] = [
                'month' => $month,
                'income' => $income ? (float) $income->total : 0.0,
                'expenses' => $expense ? (float) $expense->total : 0.0,
                'net' => ($income ? (float) $income->total : 0.0) - ($expense ? (float) $expense->total : 0.0),
            ];
        }

        return $monthlyData;
    }

    /**
     * Get top categories by amount for the period (or last 3 months if not specified).
     */
    protected function getTopCategories(int $organizationId, $from = null, $to = null, int $limit = 5): array
    {
        $from = $from ?? now()->subMonths(3)->startOfMonth();
        $to = $to ?? now()->endOfMonth();

        // Usar raw query para evitar problemas com eager loading em agregações
        $topIncomeResults = DB::table('transactions')
            ->where('organization_id', $organizationId)
            ->where('type', 'income')
            ->whereBetween('occurred_at', [$from, $to])
            ->whereNotNull('category_id')
            ->select('category_id', DB::raw('SUM(amount) as total'))
            ->groupBy('category_id')
            ->orderByDesc('total')
            ->limit($limit)
            ->get();

        $topExpensesResults = DB::table('transactions')
            ->where('organization_id', $organizationId)
            ->where('type', 'expense')
            ->whereBetween('occurred_at', [$from, $to])
            ->whereNotNull('category_id')
            ->select('category_id', DB::raw('SUM(amount) as total'))
            ->groupBy('category_id')
            ->orderByDesc('total')
            ->limit($limit)
            ->get();

        // Buscar categorias
        $categoryIds = $topIncomeResults->pluck('category_id')
            ->merge($topExpensesResults->pluck('category_id'))
            ->unique()
            ->toArray();

        $categories = Category::whereIn('id', $categoryIds)->get()->keyBy('id');

        $topIncome = $topIncomeResults->map(function ($result) use ($categories) {
            $category = $categories->get($result->category_id);
            if (! $category) {
                return null;
            }

            return [
                'category' => [
                    'id' => $category->id,
                    'name' => $category->name,
                ],
                'total' => (float) $result->total,
            ];
        })->filter();

        $topExpenses = $topExpensesResults->map(function ($result) use ($categories) {
            $category = $categories->get($result->category_id);
            if (! $category) {
                return null;
            }

            return [
                'category' => [
                    'id' => $category->id,
                    'name' => $category->name,
                ],
                'total' => (float) $result->total,
            ];
        })->filter();

        return [
            'income' => $topIncome->values()->toArray(),
            'expenses' => $topExpenses->values()->toArray(),
        ];
    }

    /**
     * Get cash flow projection for the next 30 days.
     */
    protected function getCashFlowProjection(int $organizationId): array
    {
        // Saldo atual de todas as contas
        $currentBalance = Account::where('organization_id', $organizationId)
            ->get()
            ->sum(fn ($account) => $account->current_balance);

        // Receitas previstas (due items do tipo 'receive' nos próximos 30 dias)
        $projectedIncome = DueItem::where('organization_id', $organizationId)
            ->where('type', 'receive')
            ->where('status', 'pending')
            ->whereDate('due_date', '<=', now()->addDays(30)->toDateString())
            ->whereDate('due_date', '>=', now()->toDateString())
            ->sum('amount');

        // Despesas previstas (due items do tipo 'pay' nos próximos 30 dias)
        $projectedExpenses = DueItem::where('organization_id', $organizationId)
            ->where('type', 'pay')
            ->where('status', 'pending')
            ->whereDate('due_date', '<=', now()->addDays(30)->toDateString())
            ->whereDate('due_date', '>=', now()->toDateString())
            ->sum('amount');

        // Projeção final
        $projectedBalance = $currentBalance + $projectedIncome - $projectedExpenses;

        return [
            'current_balance' => (float) $currentBalance,
            'projected_income' => (float) $projectedIncome,
            'projected_expenses' => (float) $projectedExpenses,
            'projected_balance' => (float) $projectedBalance,
            'projection_period_days' => 30,
        ];
    }

    /**
     * Get dashboard layout for user/organization.
     * 
     * Query parameters:
     * - view: Dashboard view (cash, result, collection)
     */
    public function getLayout(Request $request): JsonResponse
    {
        $organizationId = $request->header('X-Organization-Id');
        $userId = $request->user()->id;
        $view = $request->input('view', 'cash');

        // TODO: Implementar busca no banco de dados quando migration estiver criada
        // Por enquanto, retorna 404 para usar template padrão no frontend
        return response()->json(['message' => 'Layout not found'], 404);
    }

    /**
     * Save dashboard layout for user/organization.
     */
    public function saveLayout(Request $request): JsonResponse
    {
        $organizationId = $request->header('X-Organization-Id');
        $userId = $request->user()->id;
        
        $validated = $request->validate([
            'view' => 'required|string|in:cash,result,collection',
            'widgets' => 'required|array',
            'widgets.*.id' => 'required|string',
            'widgets.*.type' => 'required|string',
        ]);

        // TODO: Implementar salvamento no banco de dados quando migration estiver criada
        // Por enquanto, retorna sucesso simulado
        return response()->json([
            'data' => [
                'id' => uniqid('layout_'),
                'view' => $validated['view'],
                'widgets' => $validated['widgets'],
                'is_template' => false,
                'updated_at' => now()->toIso8601String(),
            ]
        ], 201);
    }

    /**
     * Get available dashboard templates.
     */
    public function getTemplates(Request $request): JsonResponse
    {
        $templates = [
            [
                'view' => 'cash',
                'is_template' => true,
                'widgets' => [
                    ['id' => 'kpi_cards', 'type' => 'kpi', 'default_span' => 12, 'default_order' => 1, 'visible' => true],
                    ['id' => 'account_balances', 'type' => 'account', 'default_span' => 6, 'default_order' => 2, 'visible' => true],
                    ['id' => 'cash_flow_chart', 'type' => 'chart', 'default_span' => 6, 'default_order' => 3, 'visible' => true],
                    ['id' => 'alerts_recent', 'type' => 'alert', 'default_span' => 12, 'default_order' => 4, 'visible' => true],
                    ['id' => 'calendar', 'type' => 'calendar', 'default_span' => 12, 'default_order' => 5, 'visible' => true],
                ],
            ],
            [
                'view' => 'result',
                'is_template' => true,
                'widgets' => [
                    ['id' => 'kpi_cards', 'type' => 'kpi', 'default_span' => 12, 'default_order' => 1, 'visible' => true],
                    ['id' => 'custom_indicators', 'type' => 'indicator', 'default_span' => 12, 'default_order' => 2, 'visible' => true],
                    ['id' => 'charts_pl', 'type' => 'chart', 'default_span' => 6, 'default_order' => 3, 'visible' => true],
                    ['id' => 'charts_categories', 'type' => 'chart', 'default_span' => 6, 'default_order' => 4, 'visible' => true],
                    ['id' => 'quarterly_summary', 'type' => 'summary', 'default_span' => 12, 'default_order' => 5, 'visible' => true],
                ],
            ],
            [
                'view' => 'collection',
                'is_template' => true,
                'widgets' => [
                    ['id' => 'kpi_collection', 'type' => 'kpi', 'default_span' => 12, 'default_order' => 1, 'visible' => true],
                    ['id' => 'alerts_recent', 'type' => 'alert', 'default_span' => 12, 'default_order' => 2, 'visible' => true],
                    ['id' => 'calendar', 'type' => 'calendar', 'default_span' => 12, 'default_order' => 3, 'visible' => true],
                ],
            ],
        ];

        return response()->json(['data' => $templates]);
    }

    /**
     * Get dashboard insights.
     * 
     * Query parameters:
     * - from: Start date (Y-m-d format, optional)
     * - to: End date (Y-m-d format, optional)
     */
    public function getInsights(Request $request): JsonResponse
    {
        $organizationId = $request->header('X-Organization-Id');
        $organization = Organization::findOrFail($organizationId);

        $from = $request->input('from') 
            ? \Carbon\Carbon::parse($request->input('from'))->startOfDay()
            : now()->startOfMonth();
        $to = $request->input('to')
            ? \Carbon\Carbon::parse($request->input('to'))->endOfDay()
            : now()->endOfMonth();

        $insights = [];

        // Calcular período anterior para comparação
        $periodDuration = $to->diffInDays($from);
        $previousFrom = $from->copy()->subDays($periodDuration + 1);
        $previousTo = $from->copy()->subDay();

        // Obter dados financeiros
        $currentSummary = $this->getFinancialSummary($organizationId, $from, $to);
        $previousSummary = $this->getFinancialSummary($organizationId, $previousFrom, $previousTo);

        // Insight para Entrada
        if ($previousSummary['income'] > 0) {
            $incomeChange = (($currentSummary['income'] - $previousSummary['income']) / $previousSummary['income']) * 100;
            if (abs($incomeChange) > 5) {
                $insights[] = [
                    'widget_id' => 'kpi_income',
                    'type' => $incomeChange > 0 ? 'success' : 'warning',
                    'message' => $incomeChange > 0
                        ? "Suas entradas aumentaram " . number_format(abs($incomeChange), 1) . "% em relação ao período anterior."
                        : "Suas entradas diminuíram " . number_format(abs($incomeChange), 1) . "% em relação ao período anterior.",
                    'icon' => $incomeChange > 0 ? 'trending_up' : 'trending_down',
                ];
            }
        }

        // Insight para Saída
        if ($previousSummary['expenses'] > 0) {
            $expenseChange = (($currentSummary['expenses'] - $previousSummary['expenses']) / $previousSummary['expenses']) * 100;
            if (abs($expenseChange) > 5) {
                $insights[] = [
                    'widget_id' => 'kpi_expense',
                    'type' => $expenseChange < 0 ? 'success' : 'warning',
                    'message' => $expenseChange < 0
                        ? "Suas despesas diminuíram " . number_format(abs($expenseChange), 1) . "% em relação ao período anterior."
                        : "Suas despesas aumentaram " . number_format(abs($expenseChange), 1) . "% em relação ao período anterior.",
                    'icon' => $expenseChange < 0 ? 'trending_down' : 'trending_up',
                ];
            }
        }

        // Insight para Resultado
        if ($currentSummary['net'] < 0) {
            $insights[] = [
                'widget_id' => 'kpi_net',
                'type' => 'error',
                'message' => "Você está com saldo negativo de " . number_format(abs($currentSummary['net']), 2, ',', '.') . ".",
                'icon' => 'warning',
            ];
        } elseif ($previousSummary['net'] < 0 && $currentSummary['net'] >= 0) {
            $insights[] = [
                'widget_id' => 'kpi_net',
                'type' => 'success',
                'message' => "Parabéns! Você saiu do vermelho e agora está com saldo positivo.",
                'icon' => 'check_circle',
            ];
        }

        // Insight para Percentual
        $currentPercentage = $currentSummary['income'] > 0 
            ? ($currentSummary['net'] / $currentSummary['income']) * 100 
            : 0;
        if ($currentPercentage < 0) {
            $insights[] = [
                'widget_id' => 'kpi_percentage',
                'type' => 'warning',
                'message' => "Sua margem está negativa. Considere revisar suas despesas.",
                'icon' => 'info',
            ];
        }

        // Verificar itens vencidos
        $overdueItems = $this->getOverdueItems($organizationId);
        if (count($overdueItems) > 0) {
            $totalOverdue = array_sum(array_column($overdueItems, 'amount'));
            $insights[] = [
                'widget_id' => 'alerts_recent',
                'type' => 'error',
                'message' => "Você tem " . count($overdueItems) . " item(s) vencido(s) totalizando " . number_format($totalOverdue, 2, ',', '.') . ".",
                'icon' => 'error',
            ];
        }

        return response()->json(['data' => $insights]);
    }
}
