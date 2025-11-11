<?php

return [

    'paths' => ['api/*', 'sanctum/csrf-cookie'],

    'allowed_methods' => ['*'],

    'allowed_origins' => [
        'https://srv1113923.hstgr.cloud',
        // Permitir localhost em desenvolvimento (Flutter Web)
        'http://localhost',
        'http://127.0.0.1',
    ],

    'allowed_origins_patterns' => [
        // Permitir qualquer porta do localhost para desenvolvimento Flutter Web
        '#^http://localhost:\d+$#',
        '#^http://127\.0\.0\.1:\d+$#',
    ],

    'allowed_headers' => ['*'],

    'exposed_headers' => [],

    'max_age' => 0,

    'supports_credentials' => true,

];
