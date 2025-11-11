<?php

namespace App\Models;

use App\Traits\HasTenant;
use Database\Factories\DueItemFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DueItem extends Model
{
    use HasFactory, HasTenant;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'organization_id',
        'title',
        'amount',
        'due_date',
        'type',
        'status',
        'description',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'amount' => 'decimal:2',
            'due_date' => 'date',
        ];
    }

    /**
     * The organization that owns the due item.
     */
    public function organization(): BelongsTo
    {
        return $this->belongsTo(Organization::class);
    }

    /**
     * Scope a query to only include pending items.
     */
    public function scopePending($query)
    {
        return $query->where('status', 'pending');
    }

    /**
     * Scope a query to only include overdue items.
     */
    public function scopeOverdue($query)
    {
        return $query->where('status', 'overdue')
            ->orWhere(function ($q) {
                $q->where('status', 'pending')
                    ->where('due_date', '<', now()->toDateString());
            });
    }

    /**
     * Scope a query to only include paid items.
     */
    public function scopePaid($query)
    {
        return $query->where('status', 'paid');
    }

    /**
     * Mark the item as paid.
     */
    public function markAsPaid(): void
    {
        $this->update(['status' => 'paid']);
    }

    /**
     * Check if the item is overdue.
     */
    public function isOverdue(): bool
    {
        if ($this->status === 'paid') {
            return false;
        }

        $dueDate = $this->due_date instanceof \Carbon\Carbon
            ? $this->due_date
            : \Carbon\Carbon::parse($this->due_date);

        return $dueDate->isPast() || $this->status === 'overdue';
    }

    /**
     * Boot the model.
     */
    protected static function boot(): void
    {
        parent::boot();

        static::saving(function ($dueItem) {
            // Atualizar status para overdue se necessário
            // Só atualiza automaticamente se ainda estiver pending e a data passou
            if ($dueItem->status === 'pending') {
                $dueDate = $dueItem->due_date instanceof \Carbon\Carbon
                    ? $dueItem->due_date
                    : \Carbon\Carbon::parse($dueItem->due_date);

                if ($dueDate->isPast()) {
                    $dueItem->status = 'overdue';
                }
            }
        });
    }

    /**
     * Create a new factory instance for the model.
     */
    protected static function newFactory()
    {
        return DueItemFactory::new();
    }
}
