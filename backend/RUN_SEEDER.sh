#!/bin/bash
# Script para executar o seeder e criar organização para o usuário admin

set -e

cd /var/www/symplus/backend

echo "=========================================="
echo "🌱 Executando Database Seeder"
echo "=========================================="
echo ""

echo "Este seeder irá:"
echo "  1. Criar organização 'Symplus Dev'"
echo "  2. Associar usuário admin@symplus.dev como owner"
echo "  3. Criar subscription gratuita"
echo ""

docker compose -f docker-compose.prod.yml exec php php artisan db:seed --class=DatabaseSeeder

echo ""
echo "=========================================="
echo "✅ Seeder executado com sucesso!"
echo "=========================================="
echo ""
echo "Agora o usuário admin@symplus.dev deve ter uma organização associada."
echo "Tente fazer login novamente no Flutter."

