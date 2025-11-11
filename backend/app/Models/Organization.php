<?php

namespace App\Models;

use Database\Factories\OrganizationFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class Organization extends Model
{
    use HasFactory;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'name',
        'slug',
    ];

    /**
     * The users that belong to the organization.
     */
    public function users(): BelongsToMany
    {
        return $this->belongsToMany(User::class)
            ->withPivot('org_role')
            ->withTimestamps();
    }

    /**
     * Get the owners of the organization.
     */
    public function owners(): BelongsToMany
    {
        return $this->users()->wherePivot('org_role', 'owner');
    }

    /**
     * Get the admins of the organization.
     */
    public function admins(): BelongsToMany
    {
        return $this->users()->wherePivotIn('org_role', ['owner', 'admin']);
    }

    /**
     * Get accounts for this organization.
     */
    public function accounts()
    {
        return $this->hasMany(Account::class);
    }

    /**
     * Get transactions for this organization.
     */
    public function transactions()
    {
        return $this->hasMany(Transaction::class);
    }

    /**
     * Get documents for this organization.
     */
    public function documents()
    {
        return $this->hasMany(Document::class);
    }

    /**
     * Get the organization's subscription.
     */
    public function subscription()
    {
        return $this->hasOne(Subscription::class)->latestOfMany();
    }

    /**
     * Get the organization's current plan.
     */
    public function getCurrentPlan(): string
    {
        $subscription = $this->subscription;

        if (! $subscription || ! $subscription->isActive()) {
            return 'free'; // Default plan
        }

        return $subscription->plan;
    }

    /**
     * Check if organization can use a feature.
     */
    public function canUseFeature(string $feature, int $currentUsage): bool
    {
        $subscription = $this->subscription;

        if (! $subscription || ! $subscription->isActive()) {
            // Free plan limits
            $freeLimit = PlanLimit::where('plan', 'free')
                ->where('feature', $feature)
                ->first();

            if (! $freeLimit) {
                return true; // Sem limite definido, permite
            }

            // null = unlimited
            if ($freeLimit->limit === null) {
                return true;
            }

            return $currentUsage < $freeLimit->limit;
        }

        return $subscription->canUseFeature($feature, $currentUsage);
    }

    /**
     * Get feature limit for current plan.
     */
    public function getFeatureLimit(string $feature): ?int
    {
        $plan = $this->getCurrentPlan();

        return PlanLimit::where('plan', $plan)
            ->where('feature', $feature)
            ->first()?->limit;
    }

    /**
     * Create a new factory instance for the model.
     */
    protected static function newFactory()
    {
        return OrganizationFactory::new();
    }
}
