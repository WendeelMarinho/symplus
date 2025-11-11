<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PlanLimit extends Model
{
    use HasFactory;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'plan',
        'feature',
        'limit',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'limit' => 'integer',
        ];
    }

    /**
     * Seed default plan limits.
     */
    public static function seedDefaultLimits(): void
    {
        $limits = [
            // Free plan
            ['plan' => 'free', 'feature' => 'accounts', 'limit' => 1],
            ['plan' => 'free', 'feature' => 'transactions_per_month', 'limit' => 50],
            ['plan' => 'free', 'feature' => 'documents', 'limit' => 10],
            ['plan' => 'free', 'feature' => 'users', 'limit' => 2],
            ['plan' => 'free', 'feature' => 'organizations', 'limit' => 1],

            // Basic plan
            ['plan' => 'basic', 'feature' => 'accounts', 'limit' => 5],
            ['plan' => 'basic', 'feature' => 'transactions_per_month', 'limit' => 500],
            ['plan' => 'basic', 'feature' => 'documents', 'limit' => 100],
            ['plan' => 'basic', 'feature' => 'users', 'limit' => 5],
            ['plan' => 'basic', 'feature' => 'organizations', 'limit' => 1],

            // Premium plan
            ['plan' => 'premium', 'feature' => 'accounts', 'limit' => 20],
            ['plan' => 'premium', 'feature' => 'transactions_per_month', 'limit' => 5000],
            ['plan' => 'premium', 'feature' => 'documents', 'limit' => 1000],
            ['plan' => 'premium', 'feature' => 'users', 'limit' => 20],
            ['plan' => 'premium', 'feature' => 'organizations', 'limit' => 3],

            // Enterprise plan (unlimited)
            ['plan' => 'enterprise', 'feature' => 'accounts', 'limit' => null],
            ['plan' => 'enterprise', 'feature' => 'transactions_per_month', 'limit' => null],
            ['plan' => 'enterprise', 'feature' => 'documents', 'limit' => null],
            ['plan' => 'enterprise', 'feature' => 'users', 'limit' => null],
            ['plan' => 'enterprise', 'feature' => 'organizations', 'limit' => null],
        ];

        foreach ($limits as $limit) {
            self::updateOrCreate(
                ['plan' => $limit['plan'], 'feature' => $limit['feature']],
                ['limit' => $limit['limit']]
            );
        }
    }
}
