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
        
        // Debug: log detalhado para diagnóstico
        \Log::info('CorsMiddleware executed', [
            'origin' => $origin,
            'method' => $request->getMethod(),
            'path' => $request->path(),
            'url' => $request->fullUrl(),
            'headers' => $request->headers->all(),
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
                \Log::debug('CorsMiddleware: Allowed localhost origin', ['origin' => $origin, 'allowed' => $allowedOrigin]);
            }
        }
        
        // Se não encontrou origem permitida, verificar se é localhost (desenvolvimento)
        if (!$allowedOrigin && $origin) {
            // Permitir qualquer localhost em desenvolvimento
            if (str_contains($origin, 'localhost') || str_contains($origin, '127.0.0.1')) {
                $allowedOrigin = $origin;
                \Log::debug('CorsMiddleware: Allowed localhost fallback', ['origin' => $origin]);
            } else {
                // Em produção, usar wildcard apenas se necessário
                $allowedOrigin = '*';
            }
        } elseif (!$allowedOrigin) {
            $allowedOrigin = '*';
        }

        // Handle preflight OPTIONS requests
        if ($request->getMethod() === 'OPTIONS') {
            \Log::info('CorsMiddleware: Handling OPTIONS preflight', [
                'origin' => $origin,
                'allowedOrigin' => $allowedOrigin,
            ]);
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

        // Add CORS headers to all responses (sobrescrever qualquer header anterior)
        $response->headers->remove('Access-Control-Allow-Origin');
        $response->headers->remove('Access-Control-Allow-Methods');
        $response->headers->remove('Access-Control-Allow-Headers');
        $response->headers->remove('Access-Control-Allow-Credentials');
        
        $response->headers->set('Access-Control-Allow-Origin', $allowedOrigin);
        $response->headers->set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS, PATCH');
        $response->headers->set('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Organization-Id, Accept, X-Requested-With');
        
        // Only set credentials if not using wildcard
        if ($allowedOrigin !== '*') {
            $response->headers->set('Access-Control-Allow-Credentials', 'true');
        }
        
        \Log::info('CorsMiddleware: Response headers set', [
            'origin' => $origin,
            'allowedOrigin' => $allowedOrigin,
            'status' => $response->getStatusCode(),
            'headers' => $response->headers->all(),
        ]);

        return $response;
    }
}

