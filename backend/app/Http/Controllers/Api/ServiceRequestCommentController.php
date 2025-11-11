<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\ServiceRequestCommentRequest;
use App\Http\Resources\ServiceRequestCommentResource;
use App\Models\ServiceRequest;
use App\Models\ServiceRequestComment;
use Illuminate\Http\JsonResponse;

class ServiceRequestCommentController extends Controller
{
    /**
     * Store a newly created comment.
     */
    public function store(ServiceRequestCommentRequest $request, ServiceRequest $serviceRequest): JsonResponse
    {
        $comment = ServiceRequestComment::create([
            'service_request_id' => $serviceRequest->id,
            'user_id' => $request->user()->id,
            'comment' => $request->comment,
            'is_internal' => $request->boolean('is_internal', false),
        ]);

        return (new ServiceRequestCommentResource($comment->load('user')))
            ->response()
            ->setStatusCode(201);
    }

    /**
     * Update the specified comment.
     */
    public function update(ServiceRequestCommentRequest $request, ServiceRequest $serviceRequest, ServiceRequestComment $comment): JsonResponse
    {
        // Verificar se o comentário pertence ao service request
        if ($comment->service_request_id !== $serviceRequest->id) {
            return response()->json(['message' => 'Comment not found for this service request.'], 404);
        }

        $comment->update($request->validated());

        return (new ServiceRequestCommentResource($comment->load('user')))->response();
    }

    /**
     * Remove the specified comment.
     */
    public function destroy(ServiceRequest $serviceRequest, ServiceRequestComment $comment): JsonResponse
    {
        // Verificar se o comentário pertence ao service request
        if ($comment->service_request_id !== $serviceRequest->id) {
            return response()->json(['message' => 'Comment not found for this service request.'], 404);
        }

        $comment->delete();

        return response()->json(null, 204);
    }
}
