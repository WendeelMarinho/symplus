#!/usr/bin/env bash
# vps_rollback.sh — Rollback para release anterior
#
# Este script reverte para a release anterior em caso de problemas no deploy.
# Mantém a release que falhou para análise posterior.
#
# Uso:
#   export VPS_HOST="srv1113923.hstgr.cloud"
#   export VPS_USER="root"
#   export VPS_PATH="/var/www/symplus"
#   bash scripts/vps_rollback.sh

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
DOMAIN_HEALTHCHECK="${DOMAIN_HEALTHCHECK:-https://srv1113923.hstgr.cloud/api/health}"

# Validações
log_info "Iniciando rollback..."

# Verificar se está rodando na VPS ou via SSH
if [ -z "$VPS_HOST" ] || [ "$VPS_HOST" = "localhost" ] || [ "$VPS_HOST" = "127.0.0.1" ]; then
    DEPLOY_DIR="$VPS_PATH"
    IS_REMOTE=false
else
    DEPLOY_DIR="$VPS_PATH"
    IS_REMOTE=true
    log_info "Modo remoto: conectando via SSH em ${VPS_USER}@${VPS_HOST}"
fi

# Função para executar comandos
run_cmd() {
    if [ "$IS_REMOTE" = true ]; then
        ssh "${VPS_USER}@${VPS_HOST}" "$1"
    else
        eval "$1"
    fi
}

run_cmd_output() {
    if [ "$IS_REMOTE" = true ]; then
        ssh "${VPS_USER}@${VPS_HOST}" "$1"
    else
        eval "$1"
    fi
}

CURRENT_LINK="${DEPLOY_DIR}/current"
RELEASES_DIR="${DEPLOY_DIR}/releases"

# Verificar se existe symlink current
if ! run_cmd_output "test -L ${CURRENT_LINK}" 2>/dev/null; then
    log_error "Symlink 'current' não encontrado em ${CURRENT_LINK}"
    exit 1
fi

# Obter release atual
CURRENT_RELEASE=$(run_cmd_output "readlink -f ${CURRENT_LINK}")
CURRENT_RELEASE_ID=$(basename "$CURRENT_RELEASE")

log_info "Release atual: ${CURRENT_RELEASE_ID}"
log_info "Caminho: ${CURRENT_RELEASE}"

# Listar releases disponíveis (ordenadas por data, mais recente primeiro)
AVAILABLE_RELEASES=$(run_cmd_output "ls -1t ${RELEASES_DIR} 2>/dev/null | grep -v '^${CURRENT_RELEASE_ID}$' || true")

if [ -z "$AVAILABLE_RELEASES" ]; then
    log_error "Nenhuma release anterior encontrada para rollback"
    exit 1
fi

# Pegar a primeira release (mais recente que não seja a atual)
PREVIOUS_RELEASE_ID=$(echo "$AVAILABLE_RELEASES" | head -n 1)
PREVIOUS_RELEASE="${RELEASES_DIR}/${PREVIOUS_RELEASE_ID}"

log_info "Release anterior encontrada: ${PREVIOUS_RELEASE_ID}"
log_info "Caminho: ${PREVIOUS_RELEASE}"

# Verificar se a release anterior existe
if ! run_cmd_output "test -d ${PREVIOUS_RELEASE}" 2>/dev/null; then
    log_error "Diretório da release anterior não existe: ${PREVIOUS_RELEASE}"
    exit 1
fi

# Confirmar rollback
log_warning "════════════════════════════════════════"
log_warning "⚠️  ATENÇÃO: ROLLBACK SERÁ EXECUTADO"
log_warning "════════════════════════════════════════"
log_warning "Release atual: ${CURRENT_RELEASE_ID}"
log_warning "Revertendo para: ${PREVIOUS_RELEASE_ID}"
log_warning "════════════════════════════════════════"
echo ""

if [ "${SKIP_CONFIRM:-false}" != "true" ]; then
    read -p "Deseja continuar? (s/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        log_info "Rollback cancelado pelo usuário"
        exit 0
    fi
fi

# Atualizar symlink para release anterior
log_info "Atualizando symlink para release anterior..."
run_cmd "ln -sfn ${PREVIOUS_RELEASE} ${CURRENT_LINK}"

# Verificar symlink
ACTUAL_RELEASE=$(run_cmd_output "readlink -f ${CURRENT_LINK}")
if [ "$ACTUAL_RELEASE" != "$PREVIOUS_RELEASE" ]; then
    log_error "Falha ao atualizar symlink"
    exit 1
fi

log_success "Symlink atualizado"

# Reiniciar containers na release anterior
log_info "Reiniciando containers na release anterior..."

HOST_UID=$(run_cmd_output "id -u")
HOST_GID=$(run_cmd_output "id -g")

log_info "HOST_UID=${HOST_UID} HOST_GID=${HOST_GID}"

# Parar containers da release atual (se ainda estiverem rodando)
log_info "Parando containers da release atual..."
run_cmd "cd ${CURRENT_RELEASE}/backend && HOST_UID=${HOST_UID} HOST_GID=${HOST_GID} docker compose -f docker-compose.prod.yml down || true"

# Subir containers da release anterior
log_info "Iniciando containers da release anterior..."
run_cmd "cd ${PREVIOUS_RELEASE}/backend && HOST_UID=${HOST_UID} HOST_GID=${HOST_GID} docker compose -f docker-compose.prod.yml up -d"

log_success "Containers reiniciados"

# Aguardar containers ficarem prontos
log_info "Aguardando containers ficarem prontos..."
sleep 10

# Healthcheck rápido
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
    log_error "❌ Healthcheck falhou após rollback"
    log_error "A aplicação não está respondendo em ${DOMAIN_HEALTHCHECK}"
    log_error "Verifique os logs: docker compose -f ${PREVIOUS_RELEASE}/backend/docker-compose.prod.yml logs"
    exit 1
fi

log_success "Healthcheck OK: ${DOMAIN_HEALTHCHECK}"

# Resumo final
log_success "════════════════════════════════════════"
log_success "✅ ROLLBACK CONCLUÍDO COM SUCESSO!"
log_success "════════════════════════════════════════"
echo ""
log_info "Release ativa: ${PREVIOUS_RELEASE_ID}"
log_info "Caminho: ${PREVIOUS_RELEASE}"
log_info "Symlink: ${CURRENT_LINK} -> ${PREVIOUS_RELEASE}"
echo ""
log_warning "Release que falhou mantida para análise:"
log_warning "  ${CURRENT_RELEASE}"
echo ""
log_info "Status dos containers:"
run_cmd "cd ${PREVIOUS_RELEASE}/backend && docker compose -f docker-compose.prod.yml ps"
echo ""
log_success "Aplicação disponível em: ${DOMAIN_HEALTHCHECK}"
echo ""

