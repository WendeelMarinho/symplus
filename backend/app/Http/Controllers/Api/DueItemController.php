<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\DueItemRequest;
use App\Http\Resources\DueItemResource;
use App\Models\DueItem;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DueItemController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request): JsonResponse
    {
        $query = DueItem::query()->latest('due_date');

        // Filtros
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        if ($request->has('type')) {
            $query->where('type', $request->type);
        }

        if ($request->has('from')) {
            $query->whereDate('due_date', '>=', $request->from);
        }

        if ($request->has('to')) {
            $query->whereDate('due_date', '<=', $request->to);
        }

        // Paginação
        $perPage = min($request->integer('per_page', 15), 100);
        $dueItems = $query->paginate($perPage);

        return DueItemResource::collection($dueItems)->response();
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(DueItemRequest $request): JsonResponse
    {
        $dueItem = DueItem::create([
            'organization_id' => $request->header('X-Organization-Id'),
            'title' => $request->title,
            'amount' => $request->amount,
            'due_date' => $request->due_date,
            'type' => $request->type,
            'status' => $request->status ?? 'pending',
            'description' => $request->description,
        ]);

        return (new DueItemResource($dueItem))
            ->response()
            ->setStatusCode(201);
    }

    /**
     * Display the specified resource.
     */
    public function show(DueItem $dueItem): JsonResponse
    {
        return (new DueItemResource($dueItem))->response();
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(DueItemRequest $request, DueItem $dueItem): JsonResponse
    {
        $dueItem->update($request->validated());

        return (new DueItemResource($dueItem))->response();
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(DueItem $dueItem): JsonResponse
    {
        $dueItem->delete();

        return response()->json(null, 204);
    }

    /**
     * Mark due item as paid.
     */
    public function markPaid(DueItem $dueItem): JsonResponse
    {
        $dueItem->markAsPaid();

        return (new DueItemResource($dueItem))->response();
    }
}
