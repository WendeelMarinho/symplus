#!/bin/bash
# Script para build completo: Web + APK
# Executa builds para todas as plataformas

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=========================================="
echo "🚀 Build Completo - Symplus Finance"
echo "=========================================="
echo ""

# Build Web
echo "📱 1/2 - Build Flutter Web..."
bash "$SCRIPT_DIR/build_flutter_web.sh"
echo ""

# Build APK
echo "📱 2/2 - Build Flutter APK..."
bash "$SCRIPT_DIR/build_flutter_apk.sh"
echo ""

echo "=========================================="
echo "✅ Todos os builds concluídos!"
echo "=========================================="
echo ""
echo "Arquivos gerados:"
echo "  - Web: backend/public/app/"
echo "  - APK: app/build/app/outputs/flutter-apk/"
echo ""

