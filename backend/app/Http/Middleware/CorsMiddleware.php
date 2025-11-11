<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CorsMiddleware
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        // Get origin from request or allow all in development
        $origin = $request->header('Origin');
        $allowedOrigin = $origin ?? '*';

        // Handle preflight OPTIONS requests
        if ($request->getMethod() === 'OPTIONS') {
            return response('', 204)
                ->header('Access-Control-Allow-Origin', $allowedOrigin)
                ->header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS, PATCH')
                ->header('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Organization-Id, Accept, X-Requested-With')
                ->header('Access-Control-Max-Age', '86400')
                ->header('Content-Length', '0');
        }

        // Process the request
        $response = $next($request);

        // Add CORS headers to all responses
        $response->headers->set('Access-Control-Allow-Origin', $allowedOrigin);
        $response->headers->set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS, PATCH');
        $response->headers->set('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Organization-Id, Accept, X-Requested-With');
        
        // Only set credentials if not using wildcard
        if ($allowedOrigin !== '*') {
            $response->headers->set('Access-Control-Allow-Credentials', 'true');
        }

        return $response;
    }
}

