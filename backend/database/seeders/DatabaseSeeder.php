<?php

namespace Database\Seeders;

use App\Models\Organization;
use App\Models\Subscription;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Seed plan limits primeiro
        $this->call(PlanLimitSeeder::class);

        // Criar organização de desenvolvimento (idempotente)
        $organization = Organization::firstOrCreate(
            ['slug' => 'symplus-dev'],
            [
                'name' => 'Symplus Dev',
            ]
        );

        // Criar usuário owner (idempotente)
        $user = User::firstOrCreate(
            ['email' => 'admin@symplus.dev'],
            [
                'name' => 'Admin User',
                'password' => Hash::make('password'),
                'email_verified_at' => now(),
            ]
        );

        // Associar usuário à organização como owner (se ainda não estiver associado)
        if (!$organization->users()->where('user_id', $user->id)->exists()) {
            $organization->users()->attach($user->id, [
                'org_role' => 'owner',
            ]);
        }

        // Criar subscription gratuita para a organização (idempotente)
        Subscription::firstOrCreate(
            [
                'organization_id' => $organization->id,
                'plan' => 'free',
            ],
            [
                'status' => 'active',
            ]
        );

        $this->command->info('✅ Organization "Symplus Dev" created with owner user: admin@symplus.dev / password');
        $this->command->info('✅ Plan limits seeded');
        $this->command->info('✅ Free subscription created for organization');
    }
}
