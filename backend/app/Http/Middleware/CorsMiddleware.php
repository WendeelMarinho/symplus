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
        // Get origin from request
        $origin = $request->header('Origin');
        
        // Debug: log para verificar se middleware está sendo executado
        \Log::debug('CorsMiddleware executed', [
            'origin' => $origin,
            'method' => $request->getMethod(),
            'path' => $request->path(),
        ]);
        
        // Lista de origens permitidas (desenvolvimento e produção)
        $allowedOrigins = [
            'http://localhost',
            'http://127.0.0.1',
            'https://srv1113923.hstgr.cloud',
            'https://api.symplus.dev',
        ];
        
        // Permitir qualquer porta do localhost (para desenvolvimento Flutter Web)
        $allowedOrigin = null;
        if ($origin) {
            // Verificar se a origem está na lista permitida ou é localhost em qualquer porta
            foreach ($allowedOrigins as $allowed) {
                if (str_starts_with($origin, $allowed)) {
                    $allowedOrigin = $origin;
                    break;
                }
            }
            // Se não encontrou, mas é localhost ou 127.0.0.1, permitir
            if (!$allowedOrigin && (
                str_starts_with($origin, 'http://localhost:') ||
                str_starts_with($origin, 'http://127.0.0.1:') ||
                str_starts_with($origin, 'https://localhost:') ||
                str_starts_with($origin, 'https://127.0.0.1:')
            )) {
                $allowedOrigin = $origin;
            }
        }
        
        // Se não encontrou origem permitida, usar wildcard (não recomendado em produção)
        if (!$allowedOrigin) {
            $allowedOrigin = '*';
        }

        // Handle preflight OPTIONS requests
        if ($request->getMethod() === 'OPTIONS') {
            return response('', 204)
                ->header('Access-Control-Allow-Origin', $allowedOrigin)
                ->header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS, PATCH')
                ->header('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Organization-Id, Accept, X-Requested-With')
                ->header('Access-Control-Max-Age', '86400')
                ->header('Access-Control-Allow-Credentials', $allowedOrigin !== '*' ? 'true' : 'false')
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

