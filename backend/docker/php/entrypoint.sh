#!/usr/bin/env bash
# entrypoint.sh — prepara diretórios e permissões para Laravel
# Idempotente: pode ser executado múltiplas vezes sem problemas

set -e

cd /var/www/html

echo "[entrypoint] Preparando estrutura Laravel…"
mkdir -p storage/logs storage/framework/{cache,sessions,views} bootstrap/cache

# Detecta UID/GID efetivo
EUID_CUR=$(id -u)
EGID_CUR=$(id -g)
echo "[entrypoint] Rodando como UID:GID ${EUID_CUR}:${EGID_CUR}"

# Se rodando como root (UID 0), podemos fazer chown
if [ "$EUID_CUR" = "0" ]; then
  echo "[entrypoint] Rodando como root - aplicando permissões..."
  chown -R www-data:www-data storage bootstrap/cache || true
  chmod -R 775 storage bootstrap/cache || true
else
  # Se não for root, apenas garantir que os diretórios existem e têm permissões corretas
  echo "[entrypoint] Rodando como usuário não-root - ajustando permissões..."
  # Tentar chmod apenas (sem chown)
  chmod -R 775 storage bootstrap/cache 2>/dev/null || true
  # Se os diretórios pertencem ao usuário atual, está OK
  # Caso contrário, o usuário do host precisa ter permissões adequadas
fi

# Tenta storage:link se não existir
if [ ! -L "public/storage" ]; then
  echo "[entrypoint] Criando symlink public/storage -> storage/app/public"
  php artisan storage:link || true
fi

echo "[entrypoint] Estrutura preparada com sucesso"

exec "$@"
