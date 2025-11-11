<?php

namespace App\Providers;

use Illuminate\Support\Facades\Schedule;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Ajustar tamanho padrão de string para MySQL
        Schema::defaultStringLength(191);

        // Agendar envio de lembretes de vencimentos
        Schedule::command('due-items:send-reminders')
            ->daily()
            ->at('09:00');
    }
}
