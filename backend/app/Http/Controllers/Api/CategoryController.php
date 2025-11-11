<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\CategoryRequest;
use App\Http\Resources\CategoryResource;
use App\Models\Category;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CategoryController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request): JsonResponse
    {
        $query = Category::query()->latest();

        // Filtro por tipo
        if ($request->has('type')) {
            $query->where('type', $request->type);
        }

        // Paginação
        $perPage = min($request->integer('per_page', 15), 100);
        $categories = $query->paginate($perPage);

        return CategoryResource::collection($categories)->response();
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(CategoryRequest $request): JsonResponse
    {
        $category = Category::create([
            'organization_id' => $request->header('X-Organization-Id'),
            'type' => $request->type,
            'name' => $request->name,
            'color' => $request->color ?? '#3B82F6',
        ]);

        return (new CategoryResource($category))
            ->response()
            ->setStatusCode(201);
    }

    /**
     * Display the specified resource.
     */
    public function show(Category $category): JsonResponse
    {
        return (new CategoryResource($category))->response();
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(CategoryRequest $request, Category $category): JsonResponse
    {
        $category->update($request->validated());

        return (new CategoryResource($category))->response();
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Category $category): JsonResponse
    {
        // Verificar se tem transações
        if ($category->transactions()->exists()) {
            return response()->json([
                'message' => 'Cannot delete category with transactions.',
            ], 422);
        }

        $category->delete();

        return response()->json(null, 204);
    }
}
