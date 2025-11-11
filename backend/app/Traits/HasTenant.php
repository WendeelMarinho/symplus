<?php

namespace App\Traits;

trait HasTenant
{
    /**
     * Boot the trait.
     */
    public static function bootHasTenant(): void
    {
        static::addGlobalScope(new \App\Scopes\TenantScope);

        static::creating(function ($model) {
            if (! $model->organization_id && request()->header('X-Organization-Id')) {
                $model->organization_id = (int) request()->header('X-Organization-Id');
            }
        });
    }

    /**
     * Get the organization ID from request header.
     */
    public static function getCurrentOrganizationId(): ?int
    {
        $orgId = request()->header('X-Organization-Id');

        return $orgId ? (int) $orgId : null;
    }
}
