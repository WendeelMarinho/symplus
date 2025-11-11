<?php

return [
    'stripe' => [
        'model' => App\Models\User::class,
        'key' => env('STRIPE_KEY'),
        'secret' => env('STRIPE_SECRET'),
        'webhook_secret' => env('STRIPE_WEBHOOK_SECRET'),
        'price_basic' => env('STRIPE_PRICE_BASIC'),
        'price_premium' => env('STRIPE_PRICE_PREMIUM'),
        'price_enterprise' => env('STRIPE_PRICE_ENTERPRISE'),
    ],
];
