#!/bin/bash
# Script para corrigir permissões do diretório app/

set -e

APP_DIR="/var/www/symplus/backend/public/app"

echo "=========================================="
echo "🔧 Corrigindo permissões do app/"
echo "=========================================="
echo ""

# Criar diretório se não existir
if [ ! -d "$APP_DIR" ]; then
    echo "Criando diretório $APP_DIR..."
    mkdir -p "$APP_DIR"
fi

# Criar arquivo index.html básico se não existir
if [ ! -f "$APP_DIR/index.html" ]; then
    echo "⚠️  Arquivo index.html não encontrado!"
    echo "   Execute o build do Flutter primeiro:"
    echo "   bash scripts/build_flutter_web_docker.sh"
    echo ""
fi

# Aplicar permissões
echo "Aplicando permissões..."
chown -R 1001:1001 "$APP_DIR" || chown -R www-data:www-data "$APP_DIR" || true
chmod -R 755 "$APP_DIR" || true

echo ""
echo "Verificando estrutura..."
ls -la "$APP_DIR" | head -10

echo ""
echo "=========================================="
echo "✅ Permissões corrigidas!"
echo "=========================================="

