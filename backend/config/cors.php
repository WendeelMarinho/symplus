<?php

return [

    // CORS para Laravel (usando fruitcake/laravel-cors como fallback)
    // O CorsMiddleware customizado tem prioridade, mas este config serve como backup
    'paths' => ['api/*', 'sanctum/csrf-cookie'],

    'allowed_methods' => ['*'],

    'allowed_origins' => [
        'http://localhost',
        'http://127.0.0.1',
        'https://srv1113923.hstgr.cloud',
    ],

    'allowed_origins_patterns' => [
        '#^http://localhost(:\d+)?$#',
        '#^http://127\.0\.0\.1(:\d+)?$#',
        '#^https?://.*\.hstgr\.cloud$#',
    ],

    'allowed_headers' => ['*'],

    'exposed_headers' => [],

    'max_age' => 0,

    'supports_credentials' => true,

];
