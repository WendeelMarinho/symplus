<?php

use Illuminate\Support\Facades\Route;
use Laravel\Horizon\Horizon;

// Horizon dashboard (protegido por autenticação)
// Em produção, adicionar verificação de admin
Horizon::auth(function ($request) {
    // Por enquanto, permitir acesso para desenvolvimento
    // Em produção, verificar se o usuário é admin:
    // return auth()->check() && auth()->user()->is_admin;
    return true;
});

Route::get('/', function () {
    return ['message' => 'Symplus Finance API', 'version' => '1.0.0'];
});
