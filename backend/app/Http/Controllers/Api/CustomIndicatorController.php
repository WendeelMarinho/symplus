<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CustomIndicator;
use App\Models\Transaction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class CustomIndicatorController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request): JsonResponse
    {
        $organizationId = $request->header('X-Organization-Id');
        
        $indicators = CustomIndicator::where('organization_id', $organizationId)
            ->orderBy('name')
            ->get();

        // Calculate total value and percentage for each indicator
        $from = $request->input('from') 
            ? \Carbon\Carbon::parse($request->input('from'))->startOfDay()
            : now()->startOfMonth();
        $to = $request->input('to')
            ? \Carbon\Carbon::parse($request->input('to'))->endOfDay()
            : now()->endOfMonth();

        // Get total expenses for percentage calculation
        $totalExpenses = Transaction::where('organization_id', $organizationId)
            ->where('type', 'expense')
            ->whereBetween('occurred_at', [$from, $to])
            ->sum('amount');

        $indicatorsWithValues = $indicators->map(function ($indicator) use ($organizationId, $from, $to, $totalExpenses) {
            // Calculate total value from transactions in the indicator's categories
            $totalValue = Transaction::where('organization_id', $organizationId)
                ->where('type', 'expense')
                ->whereIn('category_id', $indicator->category_ids)
                ->whereBetween('occurred_at', [$from, $to])
                ->sum('amount');

            // Calculate percentage
            $percentage = $totalExpenses > 0 ? ($totalValue / $totalExpenses * 100) : 0.0;

            return [
                'id' => $indicator->id,
                'name' => $indicator->name,
                'category_ids' => $indicator->category_ids,
                'total_value' => (float) $totalValue,
                'percentage' => (float) $percentage,
            ];
        });

        return response()->json([
            'data' => $indicatorsWithValues->values()->toArray(),
        ]);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'category_ids' => 'required|array|min:1',
            'category_ids.*' => 'required|integer|exists:categories,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        $organizationId = $request->header('X-Organization-Id');

        // Verify all categories belong to the organization
        $categoryIds = $request->input('category_ids');
        $validCategories = DB::table('categories')
            ->where('organization_id', $organizationId)
            ->whereIn('id', $categoryIds)
            ->pluck('id')
            ->toArray();

        if (count($validCategories) !== count($categoryIds)) {
            return response()->json([
                'message' => 'Some categories do not belong to your organization.',
            ], 422);
        }

        $indicator = CustomIndicator::create([
            'organization_id' => $organizationId,
            'name' => $request->input('name'),
            'category_ids' => $categoryIds,
        ]);

        return response()->json([
            'data' => [
                'id' => $indicator->id,
                'name' => $indicator->name,
                'category_ids' => $indicator->category_ids,
                'total_value' => 0.0,
                'percentage' => 0.0,
            ],
        ], 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(Request $request, CustomIndicator $customIndicator): JsonResponse
    {
        $organizationId = $request->header('X-Organization-Id');

        // Verify ownership
        if ($customIndicator->organization_id !== (int) $organizationId) {
            return response()->json([
                'message' => 'Not found.',
            ], 404);
        }

        // Calculate values
        $from = $request->input('from') 
            ? \Carbon\Carbon::parse($request->input('from'))->startOfDay()
            : now()->startOfMonth();
        $to = $request->input('to')
            ? \Carbon\Carbon::parse($request->input('to'))->endOfDay()
            : now()->endOfMonth();

        $totalValue = Transaction::where('organization_id', $organizationId)
            ->where('type', 'expense')
            ->whereIn('category_id', $customIndicator->category_ids)
            ->whereBetween('occurred_at', [$from, $to])
            ->sum('amount');

        $totalExpenses = Transaction::where('organization_id', $organizationId)
            ->where('type', 'expense')
            ->whereBetween('occurred_at', [$from, $to])
            ->sum('amount');

        $percentage = $totalExpenses > 0 ? ($totalValue / $totalExpenses * 100) : 0.0;

        return response()->json([
            'data' => [
                'id' => $customIndicator->id,
                'name' => $customIndicator->name,
                'category_ids' => $customIndicator->category_ids,
                'total_value' => (float) $totalValue,
                'percentage' => (float) $percentage,
            ],
        ]);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, CustomIndicator $customIndicator): JsonResponse
    {
        $organizationId = $request->header('X-Organization-Id');

        // Verify ownership
        if ($customIndicator->organization_id !== (int) $organizationId) {
            return response()->json([
                'message' => 'Not found.',
            ], 404);
        }

        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|required|string|max:255',
            'category_ids' => 'sometimes|required|array|min:1',
            'category_ids.*' => 'required|integer|exists:categories,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        // Verify categories if provided
        if ($request->has('category_ids')) {
            $categoryIds = $request->input('category_ids');
            $validCategories = DB::table('categories')
                ->where('organization_id', $organizationId)
                ->whereIn('id', $categoryIds)
                ->pluck('id')
                ->toArray();

            if (count($validCategories) !== count($categoryIds)) {
                return response()->json([
                    'message' => 'Some categories do not belong to your organization.',
                ], 422);
            }

            $customIndicator->category_ids = $categoryIds;
        }

        if ($request->has('name')) {
            $customIndicator->name = $request->input('name');
        }

        $customIndicator->save();

        return response()->json([
            'data' => [
                'id' => $customIndicator->id,
                'name' => $customIndicator->name,
                'category_ids' => $customIndicator->category_ids,
                'total_value' => 0.0,
                'percentage' => 0.0,
            ],
        ]);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Request $request, CustomIndicator $customIndicator): JsonResponse
    {
        $organizationId = $request->header('X-Organization-Id');

        // Verify ownership
        if ($customIndicator->organization_id !== (int) $organizationId) {
            return response()->json([
                'message' => 'Not found.',
            ], 404);
        }

        $customIndicator->delete();

        return response()->json(null, 204);
    }
}

