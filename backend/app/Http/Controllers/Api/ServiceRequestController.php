<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\ServiceRequestRequest;
use App\Http\Resources\ServiceRequestResource;
use App\Models\ServiceRequest;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ServiceRequestController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request): JsonResponse
    {
        $query = ServiceRequest::query()->latest('created_at');

        // Filtros
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        if ($request->has('priority')) {
            $query->where('priority', $request->priority);
        }

        if ($request->has('category')) {
            $query->where('category', $request->category);
        }

        if ($request->has('assigned_to')) {
            $query->where('assigned_to', $request->assigned_to);
        }

        if ($request->has('created_by')) {
            $query->where('created_by', $request->created_by);
        }

        // Paginação
        $perPage = min($request->integer('per_page', 15), 100);
        $serviceRequests = $query->with(['creator', 'assignee', 'comments.user'])->paginate($perPage);

        return ServiceRequestResource::collection($serviceRequests)->response();
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(ServiceRequestRequest $request): JsonResponse
    {
        $serviceRequest = ServiceRequest::create([
            'organization_id' => $request->header('X-Organization-Id'),
            'created_by' => $request->user()->id,
            'assigned_to' => $request->assigned_to,
            'title' => $request->title,
            'description' => $request->description,
            'priority' => $request->priority ?? 'medium',
            'category' => $request->category,
            'status' => 'open',
        ]);

        return (new ServiceRequestResource($serviceRequest->load(['creator', 'assignee'])))
            ->response()
            ->setStatusCode(201);
    }

    /**
     * Display the specified resource.
     */
    public function show(ServiceRequest $serviceRequest): JsonResponse
    {
        $serviceRequest->load(['creator', 'assignee', 'comments.user']);

        return (new ServiceRequestResource($serviceRequest))->response();
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(ServiceRequestRequest $request, ServiceRequest $serviceRequest): JsonResponse
    {
        $serviceRequest->update($request->validated());

        $serviceRequest->load(['creator', 'assignee', 'comments.user']);

        return (new ServiceRequestResource($serviceRequest))->response();
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(ServiceRequest $serviceRequest): JsonResponse
    {
        $serviceRequest->delete();

        return response()->json(null, 204);
    }

    /**
     * Mark service request as in progress.
     */
    public function markInProgress(ServiceRequest $serviceRequest): JsonResponse
    {
        $serviceRequest->markAsInProgress();

        return (new ServiceRequestResource($serviceRequest->load(['creator', 'assignee'])))->response();
    }

    /**
     * Mark service request as resolved.
     */
    public function markResolved(ServiceRequest $serviceRequest): JsonResponse
    {
        $serviceRequest->markAsResolved();

        return (new ServiceRequestResource($serviceRequest->load(['creator', 'assignee'])))->response();
    }

    /**
     * Mark service request as closed.
     */
    public function markClosed(ServiceRequest $serviceRequest): JsonResponse
    {
        $serviceRequest->markAsClosed();

        return (new ServiceRequestResource($serviceRequest->load(['creator', 'assignee'])))->response();
    }
}
