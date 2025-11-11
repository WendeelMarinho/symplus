#!/usr/bin/env bash
# entrypoint.sh — prepara diretórios e permissões para Laravel
#
# Mudanças aplicadas:
# - Cria estrutura de diretórios Laravel necessários
# - Detecta UID/GID efetivo do processo
# - Aplica ACL automaticamente se rodando como www-data (33:33) e diretórios são 1001:1001
# - Se rodando como 1001:1001, apenas garante permissões 775 (sem ACL)
# - Cria symlink storage:link se não existir
# - Idempotente: pode ser executado múltiplas vezes sem problemas
#
# Uso: Este script é executado automaticamente pelo Docker como entrypoint do serviço PHP

set -e

cd /var/www/symplus/backend

echo "[entrypoint] Preparando estrutura Laravel…"
mkdir -p storage/framework/{cache,sessions,views} bootstrap/cache

# Detecta UID/GID efetivo
EUID_CUR=$(id -u)
EGID_CUR=$(id -g)
echo "[entrypoint] Rodando como UID:GID ${EUID_CUR}:${EGID_CUR}"

# Tenta storage:link se não existir
if [ ! -L "public/storage" ]; then
  echo "[entrypoint] Criando symlink public/storage -> storage/app/public"
  php artisan storage:link || echo "[entrypoint] Aviso: storage:link falhou (pode não ter vendor ainda)"
fi

# Se rodando como www-data (33:33) e dirs são 1001:1001, tenta ACL
NEED_ACL=0
if [ "$EUID_CUR" = "33" ] || [ "$EGID_CUR" = "33" ]; then
  # Verifica owners dos dirs críticos
  OWN_STORAGE=$(stat -c "%u:%g" storage 2>/dev/null || echo "0:0")
  OWN_CACHE=$(stat -c "%u:%g" bootstrap/cache 2>/dev/null || echo "0:0")
  if [ "$OWN_STORAGE" != "${EUID_CUR}:${EGID_CUR}" ] || [ "$OWN_CACHE" != "${EUID_CUR}:${EGID_CUR}" ]; then
    NEED_ACL=1
  fi
fi

if [ "$NEED_ACL" = "1" ]; then
  echo "[entrypoint] Tentando aplicar ACL para www-data…"
  if command -v setfacl >/dev/null 2>&1; then
    setfacl -R  -m u:www-data:rwx storage bootstrap/cache || true
    setfacl -dR -m u:www-data:rwx storage bootstrap/cache || true
    echo "[entrypoint] ACL aplicada."
  else
    echo "[entrypoint] Aviso: setfacl não encontrado. Considere rodar o serviço 'fixperm' ou alinhar UID/GID pelo compose."
  fi
else
  echo "[entrypoint] ACL não necessária (UID/GID já alinhado) — garantindo 775…"
  chmod -R 775 storage bootstrap/cache || true
fi

exec "$@"
