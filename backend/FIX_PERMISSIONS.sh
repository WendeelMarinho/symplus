#!/bin/bash
# Script para corrigir permissões usando container temporário como root

set -e

cd /var/www/symplus/backend

echo "🔧 Corrigindo permissões de storage e bootstrap/cache..."

# Usar container temporário como root para corrigir permissões
docker run --rm \
  -v "$(pwd):/var/www/symplus/backend" \
  -w /var/www/symplus/backend \
  alpine:3.20 \
  sh -c "
    apk add --no-cache acl || true
    mkdir -p storage/logs storage/framework/{cache,sessions,views} bootstrap/cache
    chown -R 1001:1001 storage bootstrap/cache || true
    chmod -R 775 storage bootstrap/cache || true
    echo '✅ Permissões corrigidas'
  "

echo "✅ Permissões aplicadas com sucesso!"

