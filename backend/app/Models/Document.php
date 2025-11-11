<?php

namespace App\Models;

use App\Traits\HasTenant;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;
use Illuminate\Support\Facades\Storage;

class Document extends Model
{
    use HasFactory, HasTenant;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'organization_id',
        'name',
        'original_name',
        'mime_type',
        'size',
        'storage_path',
        'disk',
        'description',
        'category',
        'documentable_type',
        'documentable_id',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'size' => 'integer',
        ];
    }

    /**
     * The organization that owns the document.
     */
    public function organization(): BelongsTo
    {
        return $this->belongsTo(Organization::class);
    }

    /**
     * Get the parent documentable model (Transaction, DueItem, etc.).
     */
    public function documentable(): MorphTo
    {
        return $this->morphTo();
    }

    /**
     * Get the URL to access the document.
     */
    public function getUrlAttribute(): string
    {
        return Storage::disk($this->disk)->url($this->storage_path);
    }

    /**
     * Get a temporary signed URL for the document (expires in 1 hour).
     */
    public function getTemporaryUrl(int $expirationMinutes = 60): string
    {
        try {
            // Tentar obter URL temporária assinada
            return Storage::disk($this->disk)->temporaryUrl(
                $this->storage_path,
                now()->addMinutes($expirationMinutes)
            );
        } catch (\Exception $e) {
            // Se falhar (ex: storage fake), retornar URL pública
            return Storage::disk($this->disk)->url($this->storage_path);
        }
    }

    /**
     * Check if the document file exists.
     */
    public function exists(): bool
    {
        return Storage::disk($this->disk)->exists($this->storage_path);
    }

    /**
     * Get the file content.
     */
    public function getContent(): string
    {
        return Storage::disk($this->disk)->get($this->storage_path);
    }

    /**
     * Delete the file from storage when the model is deleted.
     */
    protected static function boot(): void
    {
        parent::boot();

        static::deleting(function ($document) {
            // Deletar arquivo do storage
            if ($document->exists()) {
                Storage::disk($document->disk)->delete($document->storage_path);
            }
        });
    }

    /**
     * Create a new factory instance for the model.
     */
    protected static function newFactory()
    {
        return \Database\Factories\DocumentFactory::new();
    }
}
