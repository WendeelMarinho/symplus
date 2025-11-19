#!/bin/bash
# Script para verificar arquivos sensíveis antes do push

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

echo "=========================================="
echo "🔍 Verificando arquivos sensíveis"
echo "=========================================="
echo ""

# Lista de arquivos que NÃO devem ser commitados
SENSITIVE_FILES=(
    "backend/.env"
    "backend/.env.backup"
    "backend/storage/*.key"
    "backend/storage/logs/*.log"
    ".env"
    ".env.local"
    "*.key"
    "*.pem"
    "*.p12"
    "*.jks"
    "app/android/key.properties"
    "app/ios/Runner.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist"
)

FOUND_SENSITIVE=false

echo "Verificando arquivos sensíveis..."
for pattern in "${SENSITIVE_FILES[@]}"; do
    # Usar find para verificar arquivos
    while IFS= read -r -d '' file; do
        if [ -f "$file" ]; then
            # Verificar se está no .gitignore
            if git check-ignore -q "$file"; then
                echo "✅ $file (está no .gitignore)"
            else
                echo "⚠️  ATENÇÃO: $file encontrado e NÃO está no .gitignore!"
                FOUND_SENSITIVE=true
            fi
        fi
    done < <(find . -name "$(basename "$pattern")" -type f -print0 2>/dev/null || true)
done

echo ""
echo "Verificando se há arquivos .env no staging..."
STAGED_ENV=$(git diff --cached --name-only | grep -E "\.env$|\.env\." || true)
if [ -n "$STAGED_ENV" ]; then
    echo "❌ ERRO: Arquivos .env encontrados no staging:"
    echo "$STAGED_ENV"
    echo ""
    echo "Execute: git reset HEAD <arquivo> para remover do staging"
    FOUND_SENSITIVE=true
fi

echo ""
echo "Verificando se há chaves privadas..."
STAGED_KEYS=$(git diff --cached --name-only | grep -E "\.key$|\.pem$|\.p12$|\.jks$" || true)
if [ -n "$STAGED_KEYS" ]; then
    echo "❌ ERRO: Arquivos de chave encontrados no staging:"
    echo "$STAGED_KEYS"
    echo ""
    echo "Execute: git reset HEAD <arquivo> para remover do staging"
    FOUND_SENSITIVE=true
fi

echo ""
if [ "$FOUND_SENSITIVE" = true ]; then
    echo "=========================================="
    echo "❌ Arquivos sensíveis encontrados!"
    echo "=========================================="
    echo ""
    echo "Por favor, remova esses arquivos do staging antes de fazer push."
    echo ""
    exit 1
else
    echo "=========================================="
    echo "✅ Nenhum arquivo sensível encontrado"
    echo "=========================================="
    echo ""
    echo "Pode prosseguir com segurança!"
fi

