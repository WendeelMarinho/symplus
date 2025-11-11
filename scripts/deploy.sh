#!/bin/bash

# Script de deploy para produção
# Uso: ./deploy.sh [branch]

set -e

BRANCH=${1:-main}
PROJECT_DIR="/var/www/symplus"
BACKEND_DIR="$PROJECT_DIR/backend"

echo "🚀 Iniciando deploy do Symplus Finance..."
echo "Branch: $BRANCH"
echo "Diretório: $PROJECT_DIR"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Função para exibir erros
error() {
    echo -e "${RED}❌ Erro: $1${NC}" >&2
    exit 1
}

# Função para exibir sucesso
success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Função para exibir aviso
warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Verificar se está no diretório correto
if [ ! -d "$BACKEND_DIR" ]; then
    error "Diretório $BACKEND_DIR não encontrado!"
fi

cd $PROJECT_DIR

# 1. Fazer backup antes do deploy
success "Criando backup..."
BACKUP_DIR="/var/backups/symplus"
mkdir -p $BACKUP_DIR
DATE=$(date +%Y%m%d_%H%M%S)
if [ -f "$BACKEND_DIR/.env" ]; then
    cp $BACKEND_DIR/.env $BACKUP_DIR/.env.backup_$DATE
    success "Backup do .env criado"
fi

# 2. Atualizar código
success "Atualizando código do repositório..."
git fetch origin
git checkout $BRANCH
git pull origin $BRANCH || error "Falha ao atualizar código"

# 3. Entrar no diretório do backend
cd $BACKEND_DIR

# 4. Verificar se .env existe
if [ ! -f ".env" ]; then
    warning ".env não encontrado. Copiando de env.example..."
    cp env.example .env
    warning "⚠️  Configure o arquivo .env antes de continuar!"
    exit 1
fi

# 5. Rebuild dos containers (se necessário)
success "Verificando containers..."
docker compose -f docker-compose.prod.yml ps

# 6. Instalar/atualizar dependências
success "Instalando dependências do Composer..."
docker compose -f docker-compose.prod.yml exec -T php composer install --optimize-autoloader --no-dev --no-interaction

# 7. Executar migrations
success "Executando migrations..."
docker compose -f docker-compose.prod.yml exec -T php php artisan migrate --force

# 8. Limpar e otimizar cache
success "Otimizando cache..."
docker compose -f docker-compose.prod.yml exec -T php php artisan config:clear
docker compose -f docker-compose.prod.yml exec -T php php artisan route:clear
docker compose -f docker-compose.prod.yml exec -T php php artisan view:clear
docker compose -f docker-compose.prod.yml exec -T php php artisan cache:clear

# 9. Recriar cache otimizado
success "Recriando cache otimizado..."
docker compose -f docker-compose.prod.yml exec -T php php artisan config:cache
docker compose -f docker-compose.prod.yml exec -T php php artisan route:cache
docker compose -f docker-compose.prod.yml exec -T php php artisan view:cache

# 10. Verificar permissões
success "Verificando permissões..."
docker compose -f docker-compose.prod.yml exec -T php chown -R www-data:www-data storage bootstrap/cache
docker compose -f docker-compose.prod.yml exec -T php chmod -R 775 storage bootstrap/cache

# 11. Reiniciar containers (se necessário)
read -p "Deseja reiniciar os containers? (s/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    success "Reiniciando containers..."
    docker compose -f docker-compose.prod.yml restart
fi

# 12. Verificar saúde da aplicação
success "Verificando saúde da aplicação..."
sleep 5
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/api/health || echo "000")

if [ "$HTTP_CODE" = "200" ]; then
    success "Aplicação está respondendo corretamente!"
else
    warning "Aplicação retornou código HTTP $HTTP_CODE. Verifique os logs."
    docker compose -f docker-compose.prod.yml logs --tail=50
fi

# 13. Exibir status final
success "Deploy concluído!"
echo ""
echo "📊 Status dos containers:"
docker compose -f docker-compose.prod.yml ps

echo ""
echo "📝 Próximos passos:"
echo "  - Verifique os logs: docker compose -f docker-compose.prod.yml logs -f"
echo "  - Teste a API: curl http://localhost:8000/api/health"
echo "  - Verifique o Horizon: docker compose -f docker-compose.prod.yml exec php php artisan horizon:status"

