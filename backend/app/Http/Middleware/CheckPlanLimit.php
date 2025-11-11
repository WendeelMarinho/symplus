<?php

namespace App\Http\Middleware;

use App\Models\Organization;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CheckPlanLimit
{
    /**
     * Handle an incoming request.
     *
     * @param  Closure(Request): (Response)  $next
     * @param  string  $feature  Feature to check limit for
     */
    public function handle(Request $request, Closure $next, string $feature): Response
    {
        $organizationId = $request->header('X-Organization-Id');

        if (! $organizationId) {
            return response()->json(['message' => 'Organization ID is required'], 400);
        }

        $organization = Organization::findOrFail($organizationId);

        // Obter limite e uso atual
        $limit = $organization->getFeatureLimit($feature);

        // Contar uso atual baseado na feature
        $currentUsage = match ($feature) {
            'accounts' => $organization->accounts()->count(),
            'transactions_per_month' => $organization->transactions()
                ->whereMonth('created_at', now()->month)
                ->whereYear('created_at', now()->year)
                ->count(),
            'documents' => $organization->documents()->count(),
            'users' => $organization->users()->count(),
            'organizations' => Organization::whereHas('users', function ($query) use ($organization) {
                $query->where('users.id', $organization->users()->first()?->id);
            })->count(),
            default => 0,
        };

        // Verificar se pode usar a feature
        if (! $organization->canUseFeature($feature, $currentUsage)) {
            return response()->json([
                'message' => "Plan limit reached for feature: {$feature}",
                'limit' => $limit,
                'current_usage' => $currentUsage,
            ], 403);
        }

        return $next($request);
    }
}
