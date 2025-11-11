<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class TransactionResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'account' => new AccountResource($this->whenLoaded('account')),
            'category' => $this->whenLoaded('category', fn () => new CategoryResource($this->category)),
            'type' => $this->type,
            'amount' => (float) $this->amount,
            'occurred_at' => $this->occurred_at->toIso8601String(),
            'description' => $this->description,
            'attachment_path' => $this->attachment_path,
            'created_at' => $this->created_at->toIso8601String(),
            'updated_at' => $this->updated_at->toIso8601String(),
        ];
    }
}
