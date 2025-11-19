#!/bin/bash
# Script para build do Flutter Web para produção
# Gera os arquivos estáticos para servir via Nginx

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_DIR="$PROJECT_ROOT/app"
BUILD_DIR="$APP_DIR/build/web"
DEPLOY_DIR="$PROJECT_ROOT/backend/public/app"

echo "=========================================="
echo "🌐 Build Flutter Web para Produção"
echo "=========================================="
echo ""

# Verificar se Flutter está instalado
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter não encontrado. Instale o Flutter SDK primeiro."
    echo "   https://docs.flutter.dev/get-started/install"
    exit 1
fi

cd "$APP_DIR"

echo "1️⃣  Limpando build anterior..."
flutter clean || true
echo ""

echo "2️⃣  Instalando dependências..."
flutter pub get
echo ""

echo "3️⃣  Fazendo build de produção..."
# Build com API_BASE_URL para produção
# Usando --dart-define para garantir que a URL correta seja usada
# Nota: --web-renderer foi removido nas versões mais recentes do Flutter
flutter build web \
    --release \
    --dart-define=API_BASE_URL=https://srv1113923.hstgr.cloud \
    --base-href=/app/
echo ""

echo "4️⃣  Copiando arquivos para diretório de deploy..."
mkdir -p "$DEPLOY_DIR"
rm -rf "$DEPLOY_DIR"/*
cp -r "$BUILD_DIR"/* "$DEPLOY_DIR"/
echo ""

echo "5️⃣  Ajustando index.html para base-href correto..."
# Garantir que o base href está correto no index.html
sed -i 's|<base href="/">|<base href="/app/">|g' "$DEPLOY_DIR/index.html" || true
echo ""

echo "=========================================="
echo "✅ Build concluído com sucesso!"
echo "=========================================="
echo ""
echo "Arquivos gerados em: $DEPLOY_DIR"
echo ""
echo "O app web está pronto para ser servido via Nginx em:"
echo "  https://srv1113923.hstgr.cloud/app/"
echo ""
echo "Próximos passos:"
echo "  1. Verificar se o Nginx está configurado para servir /app/"
echo "  2. Testar: curl https://srv1113923.hstgr.cloud/app/"
echo "  3. Acessar no navegador: https://srv1113923.hstgr.cloud/app/"

