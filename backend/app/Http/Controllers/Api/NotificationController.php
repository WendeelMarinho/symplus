<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\NotificationResource;
use App\Models\Notification;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    /**
     * Display a listing of notifications for the authenticated user.
     */
    public function index(Request $request): JsonResponse
    {
        $query = Notification::where('user_id', $request->user()->id)
            ->where('organization_id', $request->header('X-Organization-Id'))
            ->latest('created_at');

        // Filtros
        if ($request->has('read')) {
            if ($request->boolean('read')) {
                $query->whereNotNull('read_at');
            } else {
                $query->whereNull('read_at');
            }
        }

        if ($request->has('type')) {
            $query->where('type', $request->type);
        }

        // Paginação
        $perPage = min($request->integer('per_page', 15), 100);
        $notifications = $query->paginate($perPage);

        return NotificationResource::collection($notifications)->response();
    }

    /**
     * Get unread notifications count.
     */
    public function unreadCount(Request $request): JsonResponse
    {
        $count = Notification::where('user_id', $request->user()->id)
            ->where('organization_id', $request->header('X-Organization-Id'))
            ->whereNull('read_at')
            ->count();

        return response()->json(['count' => $count]);
    }

    /**
     * Mark a notification as read.
     */
    public function markAsRead(Notification $notification): JsonResponse
    {
        // Verificar se a notificação pertence ao usuário autenticado
        if ($notification->user_id !== request()->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $notification->markAsRead();

        return (new NotificationResource($notification))->response();
    }

    /**
     * Mark all notifications as read.
     */
    public function markAllAsRead(Request $request): JsonResponse
    {
        $updated = Notification::where('user_id', $request->user()->id)
            ->where('organization_id', $request->header('X-Organization-Id'))
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return response()->json([
            'message' => "{$updated} notification(s) marked as read.",
        ]);
    }

    /**
     * Remove the specified notification.
     */
    public function destroy(Notification $notification): JsonResponse
    {
        // Verificar se a notificação pertence ao usuário autenticado
        if ($notification->user_id !== request()->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $notification->delete();

        return response()->json(null, 204);
    }
}
