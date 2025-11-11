<?php

namespace App\Scopes;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Scope;

class TenantScope implements Scope
{
    /**
     * Apply the scope to a given Eloquent query builder.
     */
    public function apply(Builder $builder, Model $model): void
    {
        $organizationId = $this->getOrganizationId();

        if ($organizationId && $builder->getModel()->getTable() !== 'organizations') {
            $builder->where($model->getTable().'.organization_id', $organizationId);
        }
    }

    /**
     * Extend the query builder with the needed functions.
     */
    public function extend(Builder $builder): void
    {
        $builder->macro('withoutTenantScope', function (Builder $builder) {
            return $builder->withoutGlobalScope($this);
        });
    }

    /**
     * Get the organization ID from request header.
     */
    protected function getOrganizationId(): ?int
    {
        $orgId = request()->header('X-Organization-Id');

        return $orgId ? (int) $orgId : null;
    }
}
