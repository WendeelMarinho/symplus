<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureTenantIsSet
{
    /**
     * Handle an incoming request.
     *
     * @param  Closure(Request): (Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $organizationId = $request->header('X-Organization-Id');

        if (! $organizationId) {
            return response()->json([
                'message' => 'Organization ID is required. Please provide X-Organization-Id header.',
            ], 400);
        }

        // Verificar se o usuário autenticado pertence à organização
        if ($request->user() && ! $request->user()->belongsToOrganization((int) $organizationId)) {
            return response()->json([
                'message' => 'You do not have access to this organization.',
            ], 403);
        }

        return $next($request);
    }
}
