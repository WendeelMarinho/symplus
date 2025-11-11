<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\TransactionRequest;
use App\Http\Resources\TransactionResource;
use App\Models\Transaction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TransactionController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request): JsonResponse
    {
        $query = Transaction::query()
            ->with(['account', 'category'])
            ->latest('occurred_at');

        // Filtros
        if ($request->has('account_id')) {
            $query->where('account_id', $request->account_id);
        }

        if ($request->has('category_id')) {
            $query->where('category_id', $request->category_id);
        }

        if ($request->has('type')) {
            $query->where('type', $request->type);
        }

        if ($request->has('from')) {
            $query->whereDate('occurred_at', '>=', $request->from);
        }

        if ($request->has('to')) {
            $query->whereDate('occurred_at', '<=', $request->to);
        }

        // Paginação
        $perPage = min($request->integer('per_page', 15), 100);
        $transactions = $query->paginate($perPage);

        return TransactionResource::collection($transactions)->response();
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(TransactionRequest $request): JsonResponse
    {
        $transaction = Transaction::create([
            'organization_id' => $request->header('X-Organization-Id'),
            'account_id' => $request->account_id,
            'category_id' => $request->category_id,
            'type' => $request->type,
            'amount' => $request->amount,
            'occurred_at' => $request->occurred_at,
            'description' => $request->description,
            'attachment_path' => $request->attachment_path,
        ]);

        $transaction->load(['account', 'category']);

        return (new TransactionResource($transaction))
            ->response()
            ->setStatusCode(201);
    }

    /**
     * Display the specified resource.
     */
    public function show(Transaction $transaction): JsonResponse
    {
        $transaction->load(['account', 'category']);

        return (new TransactionResource($transaction))->response();
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(TransactionRequest $request, Transaction $transaction): JsonResponse
    {
        $transaction->update($request->validated());
        $transaction->load(['account', 'category']);

        return (new TransactionResource($transaction))->response();
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Transaction $transaction): JsonResponse
    {
        $transaction->delete();

        return response()->json(null, 204);
    }
}
