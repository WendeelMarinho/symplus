<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('documents', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organization_id')->constrained()->onDelete('cascade');
            $table->string('name');
            $table->string('original_name');
            $table->string('mime_type');
            $table->unsignedBigInteger('size'); // em bytes
            $table->string('storage_path'); // caminho no S3/MinIO
            $table->string('disk')->default('s3');
            $table->text('description')->nullable();
            $table->string('category')->nullable(); // invoice, receipt, contract, other
            $table->nullableMorphs('documentable'); // polimórfico nullable: cria documentable_type, documentable_id (nullable) e índice
            $table->timestamps();

            $table->index(['organization_id', 'created_at']);
            $table->index(['organization_id', 'category']);
            // Não precisa criar índice para documentable_type/documentable_id pois morphs() já cria
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('documents');
    }
};
