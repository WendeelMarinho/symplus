<?php

use App\Http\Controllers\Api\AccountController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\DocumentController;
use App\Http\Controllers\Api\DueItemController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\Api\ServiceRequestCommentController;
use App\Http\Controllers\Api\ServiceRequestController;
use App\Http\Controllers\Api\SubscriptionController;
use App\Http\Controllers\Api\TransactionController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/health', function () {
    return response()->json([
        'status' => 'ok',
        'timestamp' => now()->toIso8601String(),
    ]);
});

// Auth routes (public)
Route::prefix('auth')->group(function () {
    Route::post('/login', [AuthController::class, 'login']);
});

// Stripe webhook (public, mas protegido por assinatura)
Route::post('/webhooks/stripe', [SubscriptionController::class, 'webhook'])->withoutMiddleware(['auth:sanctum', 'tenant']);

// Protected routes
Route::middleware(['auth:sanctum', 'tenant'])->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/auth/logout', [AuthController::class, 'logout']);

    // Financial resources
    Route::apiResource('accounts', AccountController::class);
    Route::apiResource('categories', CategoryController::class);
    Route::apiResource('transactions', TransactionController::class);

    // Due items
    Route::apiResource('due-items', DueItemController::class);
    Route::post('/due-items/{dueItem}/mark-paid', [DueItemController::class, 'markPaid']);

    // Documents / Vault
    Route::apiResource('documents', DocumentController::class);
    Route::get('/documents/{document}/download', [DocumentController::class, 'download']);
    Route::get('/documents/{document}/url', [DocumentController::class, 'url']);

    // Service Requests (Tickets)
    Route::apiResource('service-requests', ServiceRequestController::class);
    Route::post('/service-requests/{serviceRequest}/mark-in-progress', [ServiceRequestController::class, 'markInProgress']);
    Route::post('/service-requests/{serviceRequest}/mark-resolved', [ServiceRequestController::class, 'markResolved']);
    Route::post('/service-requests/{serviceRequest}/mark-closed', [ServiceRequestController::class, 'markClosed']);

    // Service Request Comments
    Route::post('/service-requests/{serviceRequest}/comments', [ServiceRequestCommentController::class, 'store']);
    Route::put('/service-requests/{serviceRequest}/comments/{comment}', [ServiceRequestCommentController::class, 'update']);
    Route::delete('/service-requests/{serviceRequest}/comments/{comment}', [ServiceRequestCommentController::class, 'destroy']);

    // Notifications
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::get('/notifications/unread-count', [NotificationController::class, 'unreadCount']);
    Route::post('/notifications/{notification}/mark-as-read', [NotificationController::class, 'markAsRead']);
    Route::post('/notifications/mark-all-as-read', [NotificationController::class, 'markAllAsRead']);
    Route::delete('/notifications/{notification}', [NotificationController::class, 'destroy']);

    // Subscriptions & Billing
    Route::get('/subscription', [SubscriptionController::class, 'show']);
    Route::put('/subscription', [SubscriptionController::class, 'update']);
    Route::post('/subscription/cancel', [SubscriptionController::class, 'cancel']);

    // Dashboard
    Route::get('/dashboard', [DashboardController::class, 'index']);

    // Reports
    Route::get('/reports/pl', [ReportController::class, 'pl']);
});
