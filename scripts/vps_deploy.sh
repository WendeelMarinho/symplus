#!/usr/bin/env bash
# vps_deploy.sh — Deploy automatizado para VPS com zero-downtime
#
# Este script implementa estratégia de releases com symlinks para deploy sem downtime.
# Cria releases em /var/www/symplus/releases/<timestamp> e atualiza symlink 'current'.
#
# Uso:
#   export VPS_HOST="srv1113923.hstgr.cloud"
#   export VPS_USER="root"
#   export VPS_PATH="/var/www/symplus"
#   export GIT_REPO="https://github.com/WendeelMarinho/symplus.git"
#   export BRANCH="main"
#   export DOMAIN_HEALTHCHECK="https://srv1113923.hstgr.cloud/api/health"
#   bash scripts/vps_deploy.sh
#
# Ou executar localmente na VPS:
#   cd /var/www/symplus
#   bash scripts/vps_deploy.sh

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções de log
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Configuração via variáveis de ambiente
VPS_HOST="${VPS_HOST:-}"
VPS_USER="${VPS_USER:-root}"
VPS_PATH="${VPS_PATH:-/var/www/symplus}"
GIT_REPO="${GIT_REPO:-https://github.com/WendeelMarinho/symplus.git}"
BRANCH="${BRANCH:-main}"
DOMAIN_HEALTHCHECK="${DOMAIN_HEALTHCHECK:-https://srv1113923.hstgr.cloud/api/health}"
KEEP_RELEASES="${KEEP_RELEASES:-5}"

# Validações iniciais
log_info "Validando pré-requisitos..."

# Verificar se está rodando na VPS ou via SSH
if [ -z "$VPS_HOST" ] || [ "$VPS_HOST" = "localhost" ] || [ "$VPS_HOST" = "127.0.0.1" ]; then
    # Executando localmente na VPS
    DEPLOY_DIR="$VPS_PATH"
    IS_REMOTE=false
else
    # Executando via SSH remoto
    DEPLOY_DIR="$VPS_PATH"
    IS_REMOTE=true
    log_info "Modo remoto: conectando via SSH em ${VPS_USER}@${VPS_HOST}"
fi

# Função para executar comandos (local ou remoto)
run_cmd() {
    if [ "$IS_REMOTE" = true ]; then
        ssh "${VPS_USER}@${VPS_HOST}" "$1"
    else
        eval "$1"
    fi
}

# Função para executar comandos com output
run_cmd_output() {
    if [ "$IS_REMOTE" = true ]; then
        ssh "${VPS_USER}@${VPS_HOST}" "$1"
    else
        eval "$1"
    fi
}

# Verificar pré-requisitos
log_info "Verificando pré-requisitos na VPS..."

run_cmd "command -v git >/dev/null 2>&1 || { echo 'Git não encontrado'; exit 1; }"
run_cmd "command -v docker >/dev/null 2>&1 || { echo 'Docker não encontrado'; exit 1; }"
run_cmd "docker compose version >/dev/null 2>&1 || { echo 'Docker Compose não encontrado'; exit 1; }"
run_cmd "command -v curl >/dev/null 2>&1 || { echo 'curl não encontrado'; exit 1; }"

log_success "Pré-requisitos OK"

# Criar estrutura de diretórios
log_info "Criando estrutura de diretórios..."

run_cmd "mkdir -p ${DEPLOY_DIR}/releases"
run_cmd "mkdir -p ${DEPLOY_DIR}/shared/backend"
run_cmd "mkdir -p ${DEPLOY_DIR}/shared/frontend"

# Gerar ID da release
RELEASE_ID=$(date +%Y%m%d%H%M%S)
RELEASE_DIR="${DEPLOY_DIR}/releases/${RELEASE_ID}"
CURRENT_LINK="${DEPLOY_DIR}/current"
SHARED_DIR="${DEPLOY_DIR}/shared"

log_info "Nova release: ${RELEASE_ID}"
log_info "Diretório da release: ${RELEASE_DIR}"

# Clonar código
log_info "Obtendo código do repositório..."

if run_cmd_output "test -d ${DEPLOY_DIR}/.git" 2>/dev/null; then
    # Repositório existe, fazer clone limpo na release
    log_info "Repositório existente detectado, clonando para nova release..."
    run_cmd "git clone --depth=1 --branch ${BRANCH} ${GIT_REPO} ${RELEASE_DIR} || { log_error 'Falha ao clonar repositório'; exit 1; }"
else
    # Primeira vez, clonar normalmente
    log_info "Primeira vez: clonando repositório..."
    run_cmd "git clone --depth=1 --branch ${BRANCH} ${GIT_REPO} ${RELEASE_DIR} || { log_error 'Falha ao clonar repositório'; exit 1; }"
fi

# Configurar git safe directory
run_cmd "cd ${RELEASE_DIR} && git config --global --add safe.directory ${RELEASE_DIR} || true"

log_success "Código clonado com sucesso"

# Configurar shared (symlinks para .env e storage)
log_info "Configurando diretórios compartilhados..."

# Backend .env
if run_cmd_output "test -f ${SHARED_DIR}/backend/.env" 2>/dev/null; then
    log_info "Arquivo .env existente em shared, usando..."
else
    if run_cmd_output "test -f ${RELEASE_DIR}/backend/.env.example" 2>/dev/null; then
        log_warning ".env não existe em shared. Copiando de .env.example..."
        run_cmd "cp ${RELEASE_DIR}/backend/.env.example ${SHARED_DIR}/backend/.env"
        log_warning "⚠️  IMPORTANTE: Configure ${SHARED_DIR}/backend/.env antes de continuar!"
    else
        log_warning ".env.example não encontrado. Criando .env vazio..."
        run_cmd "touch ${SHARED_DIR}/backend/.env"
    fi
fi

# Remover .env e storage da release (symlinks serão criados DEPOIS do build Docker)
# Por enquanto, apenas backup se existirem como diretórios/arquivos reais
run_cmd "cd ${RELEASE_DIR}/backend && (test -d storage && ! test -L storage && mv storage storage.backup) || true"
run_cmd "cd ${RELEASE_DIR}/backend && (test -f .env && ! test -L .env && mv .env .env.backup) || true"

log_info "Symlinks serão criados após build do Docker"

# Criar storage se não existir
run_cmd "mkdir -p ${SHARED_DIR}/backend/storage/framework/{cache,sessions,views}"
run_cmd "mkdir -p ${SHARED_DIR}/backend/storage/logs"
run_cmd "mkdir -p ${SHARED_DIR}/backend/storage/app/public"

# Permissões
log_info "Configurando permissões..."

# Obter UID/GID do usuário na VPS
HOST_UID=$(run_cmd_output "id -u")
HOST_GID=$(run_cmd_output "id -g")

log_info "UID/GID do host: ${HOST_UID}:${HOST_GID}"

# Aplicar owner recursivo (exceto .git e node_modules)
run_cmd "chown -R ${HOST_UID}:${HOST_GID} ${RELEASE_DIR} || true"
run_cmd "find ${RELEASE_DIR} -type d -name '.git' -prune -o -type d -name 'node_modules' -prune -o -exec chown ${HOST_UID}:${HOST_GID} {} + || true"

# Garantir permissões executáveis
run_cmd "chmod +x ${RELEASE_DIR}/docker/php/entrypoint.sh 2>/dev/null || true"
run_cmd "chmod +x ${RELEASE_DIR}/scripts/*.sh 2>/dev/null || true"

# Permissões do storage compartilhado
run_cmd "chown -R ${HOST_UID}:${HOST_GID} ${SHARED_DIR}/backend/storage"
run_cmd "chmod -R 775 ${SHARED_DIR}/backend/storage"

log_success "Permissões configuradas"

# Docker Compose
log_info "Preparando Docker Compose..."

# Verificar se docker-compose.prod.yml existe na release
if ! run_cmd_output "test -f ${RELEASE_DIR}/backend/docker-compose.prod.yml" 2>/dev/null; then
    log_error "docker-compose.prod.yml não encontrado em ${RELEASE_DIR}/backend/"
    exit 1
fi

# Exportar variáveis de ambiente para Docker Compose
export HOST_UID="${HOST_UID}"
export HOST_GID="${HOST_GID}"

log_info "HOST_UID=${HOST_UID} HOST_GID=${HOST_GID}"

# Pull imagens
log_info "Fazendo pull das imagens Docker..."
run_cmd "cd ${RELEASE_DIR}/backend && HOST_UID=${HOST_UID} HOST_GID=${HOST_GID} docker compose -f docker-compose.prod.yml pull"

# Build e up
log_info "Construindo e iniciando containers..."
run_cmd "cd ${RELEASE_DIR}/backend && HOST_UID=${HOST_UID} HOST_GID=${HOST_GID} docker compose -f docker-compose.prod.yml up -d --build"

log_success "Containers iniciados"

# AGORA criar symlinks (após build do Docker)
log_info "Criando symlinks para .env e storage..."
run_cmd "cd ${RELEASE_DIR}/backend && rm -rf .env storage"
run_cmd "cd ${RELEASE_DIR}/backend && ln -sf ${SHARED_DIR}/backend/.env .env"
run_cmd "cd ${RELEASE_DIR}/backend && ln -sf ${SHARED_DIR}/backend/storage storage"
run_cmd "cd ${RELEASE_DIR}/backend && rm -rf storage.backup .env.backup || true"

log_success "Symlinks criados"

# Aguardar containers ficarem prontos
log_info "Aguardando containers ficarem prontos..."
sleep 10

# Healthcheck dos containers
log_info "Verificando saúde dos containers..."
MAX_WAIT=60
WAIT_COUNT=0

while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
    if run_cmd_output "cd ${RELEASE_DIR}/backend && docker compose -f docker-compose.prod.yml ps | grep -q 'Up'"; then
        log_success "Containers estão rodando"
        break
    fi
    WAIT_COUNT=$((WAIT_COUNT + 5))
    sleep 5
    log_info "Aguardando... (${WAIT_COUNT}s/${MAX_WAIT}s)"
done

if [ $WAIT_COUNT -ge $MAX_WAIT ]; then
    log_error "Timeout aguardando containers ficarem prontos"
    exit 1
fi

# Laravel tasks
log_info "Executando tarefas do Laravel..."

# Sanity check
run_cmd "cd ${RELEASE_DIR}/backend && docker compose -f docker-compose.prod.yml exec -T php php -v >/dev/null || { log_error 'PHP não está respondendo'; exit 1; }"

# Instalar dependências do Composer (se necessário)
log_info "Verificando dependências do Composer..."
if ! run_cmd_output "cd ${RELEASE_DIR}/backend && docker compose -f docker-compose.prod.yml exec -T php test -d vendor" 2>/dev/null; then
    log_info "Instalando dependências do Composer..."
    run_cmd "cd ${RELEASE_DIR}/backend && mkdir -p vendor && chown -R ${HOST_UID}:${HOST_GID} vendor"
    run_cmd "cd ${RELEASE_DIR}/backend && docker compose -f docker-compose.prod.yml exec -T php composer install --optimize-autoloader --no-dev"
fi

# Limpar cache
log_info "Limpando cache..."
run_cmd "cd ${RELEASE_DIR}/backend && docker compose -f docker-compose.prod.yml exec -T php php artisan config:clear || true"
run_cmd "cd ${RELEASE_DIR}/backend && docker compose -f docker-compose.prod.yml exec -T php php artisan route:clear || true"
run_cmd "cd ${RELEASE_DIR}/backend && docker compose -f docker-compose.prod.yml exec -T php php artisan view:clear || true"

# Migrations
log_info "Executando migrations..."
run_cmd "cd ${RELEASE_DIR}/backend && docker compose -f docker-compose.prod.yml exec -T php php artisan migrate --force"

# Otimizar
log_info "Otimizando aplicação..."
run_cmd "cd ${RELEASE_DIR}/backend && docker compose -f docker-compose.prod.yml exec -T php php artisan optimize:clear || true"
run_cmd "cd ${RELEASE_DIR}/backend && docker compose -f docker-compose.prod.yml exec -T php php artisan optimize || true"

# Queue/Horizon
log_info "Reiniciando filas (se aplicável)..."
run_cmd "cd ${RELEASE_DIR}/backend && docker compose -f docker-compose.prod.yml exec -T php php artisan queue:restart || true"
run_cmd "cd ${RELEASE_DIR}/backend && docker compose -f docker-compose.prod.yml exec -T php php artisan horizon:terminate || true"

log_success "Tarefas do Laravel concluídas"

# Healthcheck da aplicação
log_info "Verificando saúde da aplicação..."

MAX_HEALTH_WAIT=30
HEALTH_WAIT=0
HEALTH_OK=false

while [ $HEALTH_WAIT -lt $MAX_HEALTH_WAIT ]; do
    if curl -f -s "${DOMAIN_HEALTHCHECK}" >/dev/null 2>&1; then
        HEALTH_OK=true
        break
    fi
    HEALTH_WAIT=$((HEALTH_WAIT + 5))
    sleep 5
    log_info "Aguardando aplicação responder... (${HEALTH_WAIT}s/${MAX_HEALTH_WAIT}s)"
done

if [ "$HEALTH_OK" = false ]; then
    log_error "❌ Healthcheck falhou após ${MAX_HEALTH_WAIT}s"
    log_error "A aplicação não está respondendo em ${DOMAIN_HEALTHCHECK}"
    log_error "Execute rollback: bash scripts/vps_rollback.sh"
    exit 1
fi

log_success "Healthcheck OK: ${DOMAIN_HEALTHCHECK}"

# Ativar release (atualizar symlink)
log_info "Ativando nova release..."

# Backup do symlink atual (se existir)
if run_cmd_output "test -L ${CURRENT_LINK}" 2>/dev/null; then
    PREVIOUS_RELEASE=$(run_cmd_output "readlink -f ${CURRENT_LINK}")
    log_info "Release anterior: ${PREVIOUS_RELEASE}"
fi

# Criar novo symlink
run_cmd "ln -sfn ${RELEASE_DIR} ${CURRENT_LINK}"

# Verificar se symlink foi criado corretamente
if run_cmd_output "test -L ${CURRENT_LINK}" 2>/dev/null; then
    ACTUAL_RELEASE=$(run_cmd_output "readlink -f ${CURRENT_LINK}")
    if [ "$ACTUAL_RELEASE" = "$RELEASE_DIR" ]; then
        log_success "Release ${RELEASE_ID} ativada"
    else
        log_error "Symlink aponta para local errado: ${ACTUAL_RELEASE}"
        exit 1
    fi
else
    log_error "Falha ao criar symlink"
    exit 1
fi

# Limpeza de releases antigas
log_info "Limpando releases antigas (mantendo últimas ${KEEP_RELEASES})..."

RELEASE_COUNT=$(run_cmd_output "ls -1t ${DEPLOY_DIR}/releases 2>/dev/null | wc -l")
if [ "$RELEASE_COUNT" -gt "$KEEP_RELEASES" ]; then
    OLD_RELEASES=$(run_cmd_output "ls -1t ${DEPLOY_DIR}/releases 2>/dev/null | tail -n +$((KEEP_RELEASES + 1))")
    for OLD_RELEASE in $OLD_RELEASES; do
        # Não remover se for a release atual
        if [ "$OLD_RELEASE" != "$RELEASE_ID" ]; then
            log_info "Removendo release antiga: ${OLD_RELEASE}"
            run_cmd "rm -rf ${DEPLOY_DIR}/releases/${OLD_RELEASE}"
        fi
    done
    log_success "Limpeza concluída"
else
    log_info "Nenhuma release antiga para remover"
fi

# Resumo final
log_success "════════════════════════════════════════"
log_success "✅ DEPLOY CONCLUÍDO COM SUCESSO!"
log_success "════════════════════════════════════════"
echo ""
log_info "Release ativa: ${RELEASE_ID}"
log_info "Caminho: ${RELEASE_DIR}"
log_info "Symlink: ${CURRENT_LINK} -> ${RELEASE_DIR}"
echo ""
log_info "Status dos containers:"
run_cmd "cd ${RELEASE_DIR}/backend && docker compose -f docker-compose.prod.yml ps"
echo ""
log_info "Releases disponíveis:"
run_cmd "ls -1t ${DEPLOY_DIR}/releases 2>/dev/null | head -${KEEP_RELEASES}"
echo ""
log_success "Aplicação disponível em: ${DOMAIN_HEALTHCHECK}"
echo ""

