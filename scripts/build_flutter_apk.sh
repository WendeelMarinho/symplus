#!/bin/bash
# Script para build do Flutter APK para produção
# Gera o APK assinado para distribuição

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_DIR="$PROJECT_ROOT/app"
BUILD_DIR="$APP_DIR/build/app/outputs/flutter-apk"

echo "=========================================="
echo "📱 Build Flutter APK para Produção"
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

echo "3️⃣  Verificando configuração Android..."
# Verificar se keystore existe
KEYSTORE_PATH="$APP_DIR/android/app/upload-keystore.jks"
if [ ! -f "$KEYSTORE_PATH" ]; then
    echo "⚠️  Keystore não encontrado em: $KEYSTORE_PATH"
    echo "   Para produção, você precisa criar um keystore:"
    echo "   keytool -genkey -v -keystore $KEYSTORE_PATH -keyalg RSA -keysize 2048 -validity 10000 -alias upload"
    echo ""
    echo "   Continuando com build de debug (não recomendado para produção)..."
    BUILD_TYPE="debug"
else
    echo "✅ Keystore encontrado"
    BUILD_TYPE="release"
fi
echo ""

echo "4️⃣  Fazendo build de produção..."
# Build com API_BASE_URL para produção
if [ "$BUILD_TYPE" = "release" ]; then
    flutter build apk \
        --release \
        --dart-define=API_BASE_URL=https://srv1113923.hstgr.cloud
    APK_PATH="$BUILD_DIR/app-release.apk"
else
    flutter build apk \
        --debug \
        --dart-define=API_BASE_URL=https://srv1113923.hstgr.cloud
    APK_PATH="$BUILD_DIR/app-debug.apk"
fi
echo ""

if [ -f "$APK_PATH" ]; then
    APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
    echo "=========================================="
    echo "✅ Build concluído com sucesso!"
    echo "=========================================="
    echo ""
    echo "APK gerado: $APK_PATH"
    echo "Tamanho: $APK_SIZE"
    echo ""
    echo "Próximos passos:"
    echo "  1. Testar o APK em um dispositivo Android"
    echo "  2. Distribuir via Google Play Store ou distribuição interna"
    echo "  3. Verificar se a API está acessível: https://srv1113923.hstgr.cloud/api/health"
else
    echo "❌ Erro: APK não foi gerado"
    exit 1
fi

