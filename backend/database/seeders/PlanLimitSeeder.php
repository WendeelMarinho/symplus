<?php

namespace Database\Seeders;

use App\Models\PlanLimit;
use Illuminate\Database\Seeder;

class PlanLimitSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        PlanLimit::seedDefaultLimits();
    }
}
