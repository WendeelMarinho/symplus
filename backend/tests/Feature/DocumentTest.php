<?php

namespace Tests\Feature;

use App\Models\Document;
use App\Models\Organization;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class DocumentTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;
    protected Organization $organization;

    protected function setUp(): void
    {
        parent::setUp();

        Storage::fake('s3');

        $this->organization = Organization::factory()->create();
        $this->user = User::factory()->create();
        $this->organization->users()->attach($this->user->id, ['org_role' => 'owner']);
    }

    /**
     * Test user can list documents.
     */
    public function test_user_can_list_documents(): void
    {
        Document::factory()->count(3)->create([
            'organization_id' => $this->organization->id,
        ]);

        $token = $this->user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->getJson('/api/documents');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'data' => [
                    '*' => ['id', 'name', 'original_name', 'mime_type', 'size', 'category'],
                ],
            ]);

        $this->assertCount(3, $response->json('data'));
    }

    /**
     * Test user can upload a document.
     */
    public function test_user_can_upload_document(): void
    {
        $file = UploadedFile::fake()->create('invoice.pdf', 100, 'application/pdf');

        $token = $this->user->createToken('test-token')->plainTextToken;

        // Usar post() em vez de postJson() para upload de arquivos
        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->post('/api/documents', [
                'file' => $file,
                'name' => 'Invoice January 2024',
                'category' => 'invoice',
                'description' => 'Monthly invoice',
            ]);

        $response->assertStatus(201)
            ->assertJsonStructure([
                'data' => ['id', 'name', 'original_name', 'mime_type', 'size', 'category'],
            ]);

        $this->assertDatabaseHas('documents', [
            'organization_id' => $this->organization->id,
            'name' => 'Invoice January 2024',
            'category' => 'invoice',
        ]);

        // Verificar que o arquivo foi salvo
        $document = Document::first();
        Storage::disk('s3')->assertExists($document->storage_path);
    }

    /**
     * Test user can download a document.
     */
    public function test_user_can_download_document(): void
    {
        $document = Document::factory()->create([
            'organization_id' => $this->organization->id,
        ]);

        // Criar arquivo fake no storage
        Storage::disk('s3')->put($document->storage_path, 'fake file content');

        $token = $this->user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->get("/api/documents/{$document->id}/download");

        $response->assertStatus(200);

        // Verificar que o Content-Disposition contém o nome do arquivo
        $contentDisposition = $response->headers->get('Content-Disposition');
        $this->assertStringContainsString($document->original_name, $contentDisposition);
    }

    /**
     * Test user can get temporary URL for document.
     */
    public function test_user_can_get_temporary_url(): void
    {
        $document = Document::factory()->create([
            'organization_id' => $this->organization->id,
        ]);

        $token = $this->user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->getJson("/api/documents/{$document->id}/url?expires=120");

        $response->assertStatus(200)
            ->assertJsonStructure([
                'url',
                'expires_at',
            ]);
    }

    /**
     * Test documents can be filtered by category.
     */
    public function test_documents_can_be_filtered_by_category(): void
    {
        Document::factory()->create([
            'organization_id' => $this->organization->id,
            'category' => 'invoice',
        ]);

        Document::factory()->create([
            'organization_id' => $this->organization->id,
            'category' => 'receipt',
        ]);

        $token = $this->user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->getJson('/api/documents?category=invoice');

        $response->assertStatus(200);
        $this->assertCount(1, $response->json('data'));
        $this->assertEquals('invoice', $response->json('data.0.category'));
    }

    /**
     * Test documents respect tenant isolation.
     */
    public function test_documents_respect_tenant_isolation(): void
    {
        $org2 = Organization::factory()->create();
        $org2->users()->attach($this->user->id, ['org_role' => 'owner']);

        Document::factory()->create([
            'organization_id' => $this->organization->id,
            'name' => 'Doc Org 1',
        ]);

        Document::factory()->create([
            'organization_id' => $org2->id,
            'name' => 'Doc Org 2',
        ]);

        $token = $this->user->createToken('test-token')->plainTextToken;

        // Listar com org1
        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->getJson('/api/documents');

        $response->assertStatus(200);
        $this->assertCount(1, $response->json('data'));
        $this->assertEquals('Doc Org 1', $response->json('data.0.name'));
    }

    /**
     * Test document is deleted from storage when deleted from database.
     */
    public function test_document_is_deleted_from_storage_on_delete(): void
    {
        $document = Document::factory()->create([
            'organization_id' => $this->organization->id,
        ]);

        // Criar arquivo fake no storage
        Storage::disk('s3')->put($document->storage_path, 'fake file content');

        $token = $this->user->createToken('test-token')->plainTextToken;

        $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Organization-Id', (string) $this->organization->id)
            ->deleteJson("/api/documents/{$document->id}")
            ->assertStatus(204);

        // Verificar que arquivo foi deletado
        Storage::disk('s3')->assertMissing($document->storage_path);

        $this->assertDatabaseMissing('documents', [
            'id' => $document->id,
        ]);
    }
}
