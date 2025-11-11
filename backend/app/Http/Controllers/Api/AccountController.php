<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\AccountRequest;
use App\Http\Resources\AccountResource;
use App\Models\Account;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AccountController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request): JsonResponse
    {
        $query = Account::query()
            ->with('transactions')
            ->latest();

        // Paginação
        $perPage = min($request->integer('per_page', 15), 100);
        $accounts = $query->paginate($perPage);

        return AccountResource::collection($accounts)->response();
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(AccountRequest $request): JsonResponse
    {
        $account = Account::create([
            'organization_id' => $request->header('X-Organization-Id'),
            'name' => $request->name,
            'currency' => $request->currency,
            'opening_balance' => $request->opening_balance ?? 0,
        ]);

        return (new AccountResource($account))
            ->response()
            ->setStatusCode(201);
    }

    /**
     * Display the specified resource.
     */
    public function show(Account $account): JsonResponse
    {
        $account->load('transactions');

        return (new AccountResource($account))->response();
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(AccountRequest $request, Account $account): JsonResponse
    {
        $account->update($request->validated());

        return (new AccountResource($account))->response();
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Account $account): JsonResponse
    {
        // Verificar se tem transações
        if ($account->transactions()->exists()) {
            return response()->json([
                'message' => 'Cannot delete account with transactions.',
            ], 422);
        }

        $account->delete();

        return response()->json(null, 204);
    }
}
