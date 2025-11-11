<?php

namespace App\Models;

use App\Traits\HasTenant;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Subscription extends Model
{
    use HasFactory, HasTenant;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'organization_id',
        'stripe_subscription_id',
        'stripe_customer_id',
        'plan',
        'status',
        'trial_ends_at',
        'ends_at',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'trial_ends_at' => 'datetime',
            'ends_at' => 'datetime',
        ];
    }

    /**
     * The organization that owns the subscription.
     */
    public function organization(): BelongsTo
    {
        return $this->belongsTo(Organization::class);
    }

    /**
     * Check if the subscription is active.
     */
    public function isActive(): bool
    {
        return $this->status === 'active' && ($this->ends_at === null || $this->ends_at->isFuture());
    }

    /**
     * Check if the subscription is on trial.
     */
    public function isOnTrial(): bool
    {
        return $this->trial_ends_at !== null && $this->trial_ends_at->isFuture();
    }

    /**
     * Check if the subscription is canceled.
     */
    public function isCanceled(): bool
    {
        return $this->status === 'canceled' || ($this->ends_at !== null && $this->ends_at->isPast());
    }

    /**
     * Get the plan limits for this subscription.
     */
    public function getPlanLimits(): array
    {
        return PlanLimit::where('plan', $this->plan)
            ->get()
            ->mapWithKeys(fn ($limit) => [$limit->feature => $limit->limit])
            ->toArray();
    }

    /**
     * Check if a feature is within the plan limit.
     */
    public function canUseFeature(string $feature, int $currentUsage): bool
    {
        $limits = $this->getPlanLimits();

        if (! isset($limits[$feature])) {
            return true; // Se não há limite definido, permite
        }

        $limit = $limits[$feature];

        // null = unlimited
        if ($limit === null) {
            return true;
        }

        return $currentUsage < $limit;
    }

    /**
     * Create a new factory instance for the model.
     */
    protected static function newFactory()
    {
        return \Database\Factories\SubscriptionFactory::new();
    }
}
