<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReportController extends Controller
{
    /**
     * Generate Profit & Loss report.
     */
    public function pl(Request $request): JsonResponse
    {
        $request->validate([
            'from' => ['required', 'date', 'date_format:Y-m-d'],
            'to' => ['required', 'date', 'date_format:Y-m-d', 'after_or_equal:from'],
            'group_by' => ['nullable', 'in:category,month'],
        ]);

        $from = $request->date('from')->startOfDay();
        $to = $request->date('to')->endOfDay();
        $groupBy = $request->string('group_by')->toString() ?: 'month';

        $organizationId = $request->header('X-Organization-Id');

        // Calcular totais gerais
        $totals = Transaction::where('organization_id', $organizationId)
            ->whereBetween('occurred_at', [$from, $to])
            ->selectRaw('
                SUM(CASE WHEN type = "income" THEN amount ELSE 0 END) as total_income,
                SUM(CASE WHEN type = "expense" THEN amount ELSE 0 END) as total_expense
            ')
            ->first();

        $totalIncome = (float) ($totals->total_income ?? 0);
        $totalExpense = (float) ($totals->total_expense ?? 0);
        $netProfit = $totalIncome - $totalExpense;
        $expenseOverIncome = $totalIncome > 0
            ? round(($totalExpense / $totalIncome) * 100, 2)
            : 0;

        // Agrupamento de séries
        $series = match ($groupBy) {
            'category' => $this->groupByCategory($organizationId, $from, $to),
            'month' => $this->groupByMonth($organizationId, $from, $to),
            default => $this->groupByMonth($organizationId, $from, $to),
        };

        return response()->json([
            'period' => [
                'from' => $from->toDateString(),
                'to' => $to->toDateString(),
            ],
            'summary' => [
                'total_income' => $totalIncome,
                'total_expense' => $totalExpense,
                'net_profit' => $netProfit,
                'expense_over_income_percent' => $expenseOverIncome,
            ],
            'group_by' => $groupBy,
            'series' => $series,
        ]);
    }

    /**
     * Group transactions by category.
     *
     * @param  \Carbon\Carbon  $from
     * @param  \Carbon\Carbon  $to
     */
    protected function groupByCategory(int $organizationId, $from, $to): array
    {
        $results = Transaction::where('organization_id', $organizationId)
            ->whereBetween('occurred_at', [$from, $to])
            ->with('category')
            ->selectRaw('
                category_id,
                type,
                SUM(amount) as total
            ')
            ->groupBy('category_id', 'type')
            ->get();

        $grouped = [];

        foreach ($results as $result) {
            $categoryId = $result->category_id;
            $categoryName = $result->category?->name ?? 'Sem categoria';
            $type = $result->type;

            if (! isset($grouped[$categoryId])) {
                $grouped[$categoryId] = [
                    'category_id' => $categoryId,
                    'category_name' => $categoryName,
                    'income' => 0.0,
                    'expense' => 0.0,
                    'net' => 0.0,
                ];
            }

            $grouped[$categoryId][$type] = (float) $result->total;
            $grouped[$categoryId]['net'] = $grouped[$categoryId]['income'] - $grouped[$categoryId]['expense'];
        }

        return array_values($grouped);
    }

    /**
     * Group transactions by month.
     *
     * @param  \Carbon\Carbon  $from
     * @param  \Carbon\Carbon  $to
     */
    protected function groupByMonth(int $organizationId, $from, $to): array
    {
        $driver = DB::connection()->getDriverName();
        $dateFormat = match ($driver) {
            'sqlite' => "strftime('%Y-%m', occurred_at)",
            'mysql' => "DATE_FORMAT(occurred_at, '%Y-%m')",
            default => "to_char(occurred_at, 'YYYY-MM')", // PostgreSQL
        };

        $results = Transaction::where('organization_id', $organizationId)
            ->whereBetween('occurred_at', [$from, $to])
            ->selectRaw("
                {$dateFormat} as month,
                type,
                SUM(amount) as total
            ")
            ->groupBy('month', 'type')
            ->orderBy('month')
            ->get();

        $grouped = [];

        foreach ($results as $result) {
            $month = $result->month;
            $type = $result->type;

            if (! isset($grouped[$month])) {
                $grouped[$month] = [
                    'month' => $month,
                    'income' => 0.0,
                    'expense' => 0.0,
                    'net' => 0.0,
                ];
            }

            $grouped[$month][$type] = (float) $result->total;
            $grouped[$month]['net'] = $grouped[$month]['income'] - $grouped[$month]['expense'];
        }

        return array_values($grouped);
    }
}
