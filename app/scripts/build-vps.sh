#!/bin/bash
# Script para gerar builds de produção apontando para a VPS
# Uso: ./scripts/build-vps.sh [apk|aab|ios|web]

set -e

API_URL="https://srv1113923.hstgr.cloud"
BUILD_TYPE="${1:-apk}"

echo "📦 Gerando build de produção com API: $API_URL"
echo "🔨 Tipo: $BUILD_TYPE"
echo ""

case $BUILD_TYPE in
  apk)
    echo "Gerando APK Android..."
    flutter build apk --release --dart-define=API_BASE_URL="$API_URL"
    echo "✅ APK gerado em: build/app/outputs/flutter-apk/app-release.apk"
    ;;
  aab)
    echo "Gerando AAB Android..."
    flutter build appbundle --release --dart-define=API_BASE_URL="$API_URL"
    echo "✅ AAB gerado em: build/app/outputs/bundle/release/app-release.aab"
    ;;
  ios)
    echo "Gerando build iOS..."
    flutter build ios --release --dart-define=API_BASE_URL="$API_URL"
    echo "✅ Build iOS gerado em: build/ios/archive/"
    echo "⚠️  Requer Xcode para gerar IPA"
    ;;
  web)
    echo "Gerando build Web..."
    flutter build web --release --dart-define=API_BASE_URL="$API_URL"
    echo "✅ Build Web gerado em: build/web/"
    ;;
  *)
    echo "❌ Tipo de build inválido: $BUILD_TYPE"
    echo "Uso: $0 [apk|aab|ios|web]"
    exit 1
    ;;
esac

