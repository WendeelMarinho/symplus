<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\DocumentRequest;
use App\Http\Resources\DocumentResource;
use App\Models\Document;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class DocumentController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request): JsonResponse
    {
        $query = Document::query()->latest('created_at');

        // Filtros
        if ($request->has('category')) {
            $query->where('category', $request->category);
        }

        if ($request->has('documentable_type')) {
            $query->where('documentable_type', $request->documentable_type);
        }

        if ($request->has('documentable_id')) {
            $query->where('documentable_id', $request->documentable_id);
        }

        // Paginação
        $perPage = min($request->integer('per_page', 15), 100);
        $documents = $query->paginate($perPage);

        return DocumentResource::collection($documents)->response();
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(DocumentRequest $request): JsonResponse
    {
        $file = $request->file('file');
        $organizationId = $request->header('X-Organization-Id');

        // Gerar nome único para o arquivo
        $fileName = Str::uuid().'.'.$file->getClientOriginalExtension();
        $storagePath = "organizations/{$organizationId}/documents/".date('Y/m').'/'.$fileName;

        // Upload para S3/MinIO
        $path = Storage::disk('s3')->putFileAs(
            dirname($storagePath),
            $file,
            basename($storagePath),
            'public' // Tornar público para acesso via URL
        );

        // Ajustar storage_path caso o putFileAs retorne um caminho diferente
        if ($path !== $storagePath) {
            $storagePath = $path;
        }

        // Criar registro no banco
        $document = Document::create([
            'organization_id' => $organizationId,
            'name' => $request->input('name', $file->getClientOriginalName()),
            'original_name' => $file->getClientOriginalName(),
            'mime_type' => $file->getMimeType(),
            'size' => $file->getSize(),
            'storage_path' => $storagePath,
            'disk' => 's3',
            'description' => $request->description,
            'category' => $request->category ?? 'other',
            'documentable_type' => $request->documentable_type,
            'documentable_id' => $request->documentable_id,
        ]);

        return (new DocumentResource($document))
            ->response()
            ->setStatusCode(201);
    }

    /**
     * Display the specified resource.
     */
    public function show(Document $document): JsonResponse
    {
        return (new DocumentResource($document))->response();
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(DocumentRequest $request, Document $document): JsonResponse
    {
        $document->update($request->validated());

        return (new DocumentResource($document))->response();
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Document $document): JsonResponse
    {
        // O hook do modelo já deleta o arquivo do storage
        $document->delete();

        return response()->json(null, 204);
    }

    /**
     * Download the document file.
     */
    public function download(Document $document)
    {
        if (! $document->exists()) {
            return response()->json(['message' => 'File not found'], 404);
        }

        // Obter o conteúdo do arquivo
        $content = Storage::disk($document->disk)->get($document->storage_path);

        // Retornar resposta de download
        $filename = $document->original_name;
        // Escapar aspas no nome do arquivo
        $filename = str_replace('"', '\\"', $filename);

        return response($content)
            ->header('Content-Type', $document->mime_type)
            ->header('Content-Disposition', 'attachment; filename="'.$filename.'"')
            ->header('Content-Length', strlen($content));
    }

    /**
     * Get a temporary signed URL for the document.
     */
    public function url(Document $document, Request $request): JsonResponse
    {
        $expirationMinutes = min($request->integer('expires', 60), 1440); // Máximo 24 horas

        return response()->json([
            'url' => $document->getTemporaryUrl($expirationMinutes),
            'expires_at' => now()->addMinutes($expirationMinutes)->toIso8601String(),
        ]);
    }
}
