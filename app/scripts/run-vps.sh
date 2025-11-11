#!/bin/bash
# Script para rodar o app Flutter apontando para a VPS
# Uso: ./scripts/run-vps.sh [chrome|android|ios]

set -e

API_URL="https://srv1113923.hstgr.cloud"
DEVICE="${1:-chrome}"

echo "🚀 Rodando app Flutter com API: $API_URL"
echo "📱 Device: $DEVICE"
echo ""

case $DEVICE in
  chrome)
    echo "Executando no Chrome..."
    flutter run -d chrome --dart-define=API_BASE_URL="$API_URL"
    ;;
  android)
    echo "Executando no Android..."
    flutter run -d android --dart-define=API_BASE_URL="$API_URL"
    ;;
  ios)
    echo "Executando no iOS..."
    flutter run -d ios --dart-define=API_BASE_URL="$API_URL"
    ;;
  *)
    echo "❌ Device inválido: $DEVICE"
    echo "Uso: $0 [chrome|android|ios]"
    exit 1
    ;;
esac

