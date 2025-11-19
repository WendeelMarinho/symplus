#!/bin/bash
# Script para build do Flutter Web usando Docker (sem precisar instalar Flutter na VPS)
# Usa imagem Flutter mais recente com Dart SDK 3.0+

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_DIR="$PROJECT_ROOT/app"
BUILD_DIR="$APP_DIR/build/web"
DEPLOY_DIR="$PROJECT_ROOT/backend/public/app"

echo "=========================================="
echo "🌐 Build Flutter Web para Produção (Docker)"
echo "=========================================="
echo ""

cd "$APP_DIR"

# Verificar se Docker está instalado
if ! command -v docker &> /dev/null; then
    echo "❌ Docker não encontrado. Instale o Docker primeiro."
    exit 1
fi

echo "1️⃣  Baixando imagem Flutter mais recente..."
# Usar imagem Flutter com Dart 3.0+
docker pull ghcr.io/cirruslabs/flutter:stable
echo ""

echo "2️⃣  Limpando build anterior..."
rm -rf "$BUILD_DIR" || true
echo ""

echo "3️⃣  Instalando dependências do Flutter..."
docker run --rm \
    -v "$APP_DIR":/work \
    -w /work \
    ghcr.io/cirruslabs/flutter:stable \
    flutter pub get
echo ""

echo "4️⃣  Fazendo build de produção..."
# Build com API_BASE_URL para produção
# Nota: --web-renderer foi removido nas versões mais recentes do Flutter
docker run --rm \
    -v "$APP_DIR":/work \
    -w /work \
    ghcr.io/cirruslabs/flutter:stable \
    flutter build web \
        --release \
        --dart-define=API_BASE_URL=https://srv1113923.hstgr.cloud \
        --base-href=/app/
echo ""

# Verificar se o build foi gerado
if [ ! -d "$BUILD_DIR" ] || [ -z "$(ls -A "$BUILD_DIR")" ]; then
    echo "❌ Build falhou ou não gerou arquivos"
    exit 1
fi

echo "5️⃣  Copiando arquivos para diretório de deploy..."
mkdir -p "$DEPLOY_DIR"
rm -rf "$DEPLOY_DIR"/*
cp -r "$BUILD_DIR"/* "$DEPLOY_DIR"/
echo ""

echo "6️⃣  Ajustando permissões..."
chown -R 1001:1001 "$DEPLOY_DIR" || true
chmod -R 755 "$DEPLOY_DIR" || true
echo ""

echo "=========================================="
echo "✅ Build concluído com sucesso!"
echo "=========================================="
echo ""
echo "Arquivos gerados em: $DEPLOY_DIR"
echo ""
echo "Próximos passos:"
echo "  1. Reiniciar Nginx: cd backend && docker compose -f docker-compose.prod.yml restart nginx"
echo "  2. Acessar: https://srv1113923.hstgr.cloud/app/"

