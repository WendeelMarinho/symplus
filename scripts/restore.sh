#!/bin/bash

# Script de restauração do Symplus Finance
# Uso: ./restore.sh <arquivo_backup.tar.gz>

set -e

if [ -z "$1" ]; then
    echo "❌ Erro: Especifique o arquivo de backup"
    echo "Uso: ./restore.sh <arquivo_backup.tar.gz>"
    exit 1
fi

BACKUP_FILE="$1"
BACKUP_DIR="/var/backups/symplus"
PROJECT_DIR="/var/www/symplus"
BACKEND_DIR="$PROJECT_DIR/backend"
TEMP_DIR="/tmp/symplus_restore_$$"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo "🔄 Iniciando restauração do Symplus Finance..."

# Verificar se arquivo existe
if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}❌ Arquivo de backup não encontrado: $BACKUP_FILE${NC}"
    exit 1
fi

# Confirmar restauração
echo -e "${YELLOW}⚠️  ATENÇÃO: Esta operação irá substituir os dados atuais!${NC}"
read -p "Tem certeza que deseja continuar? (digite 'sim' para confirmar): " CONFIRM

if [ "$CONFIRM" != "sim" ]; then
    echo "❌ Restauração cancelada."
    exit 1
fi

# Criar diretório temporário
mkdir -p $TEMP_DIR
cd $TEMP_DIR

# Extrair backup
echo "📦 Extraindo backup..."
tar -xzf "$BACKUP_FILE"

# Verificar arquivos extraídos
if [ ! -f "metadata_*.txt" ]; then
    echo -e "${YELLOW}⚠️  Arquivo de metadados não encontrado. Continuando...${NC}"
fi

# 1. Restaurar banco de dados
if ls db_*.sql.gz 1> /dev/null 2>&1; then
    echo "💾 Restaurando banco de dados..."
    DB_FILE=$(ls db_*.sql.gz | head -n 1)
    gunzip $DB_FILE
    
    # Ler variáveis do .env atual
    if [ -f "$BACKEND_DIR/.env" ]; then
        source <(grep -E "^DB_" $BACKEND_DIR/.env | sed 's/^/export /')
    fi
    
    docker compose -f $BACKEND_DIR/docker-compose.prod.yml exec -T db \
        mysql -u ${DB_USERNAME:-symplus} -p${DB_PASSWORD:-root} ${DB_DATABASE:-symplus} \
        < ${DB_FILE%.gz} 2>/dev/null || {
        echo "⚠️  Tentando com usuário root..."
        docker compose -f $BACKEND_DIR/docker-compose.prod.yml exec -T db \
            mysql -u root -p${DB_PASSWORD:-root} ${DB_DATABASE:-symplus} \
            < ${DB_FILE%.gz}
    }
    echo -e "${GREEN}✅ Banco de dados restaurado${NC}"
else
    echo -e "${YELLOW}⚠️  Backup do banco não encontrado${NC}"
fi

# 2. Restaurar storage
if ls storage_*.tar.gz 1> /dev/null 2>&1; then
    echo "📁 Restaurando storage..."
    STORAGE_FILE=$(ls storage_*.tar.gz | head -n 1)
    
    # Fazer backup do storage atual
    if [ -d "$BACKEND_DIR/storage" ]; then
        mv $BACKEND_DIR/storage $BACKEND_DIR/storage.backup_$(date +%Y%m%d_%H%M%S)
    fi
    
    tar -xzf $STORAGE_FILE -C $BACKEND_DIR
    docker compose -f $BACKEND_DIR/docker-compose.prod.yml exec -T php \
        chown -R www-data:www-data storage
    docker compose -f $BACKEND_DIR/docker-compose.prod.yml exec -T php \
        chmod -R 775 storage
    echo -e "${GREEN}✅ Storage restaurado${NC}"
else
    echo -e "${YELLOW}⚠️  Backup do storage não encontrado${NC}"
fi

# 3. Restaurar .env (opcional, com confirmação)
if ls .env_* 1> /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Arquivo .env encontrado no backup${NC}"
    read -p "Deseja restaurar o .env? (s/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        ENV_FILE=$(ls .env_* | head -n 1)
        cp "$ENV_FILE" "$BACKEND_DIR/.env.backup_$(date +%Y%m%d_%H%M%S)"
        cp "$ENV_FILE" "$BACKEND_DIR/.env"
        echo -e "${GREEN}✅ .env restaurado${NC}"
        echo -e "${YELLOW}⚠️  Reinicie os containers para aplicar as mudanças${NC}"
    fi
fi

# 4. Restaurar MinIO (se existir)
if ls minio_*.tar.gz 1> /dev/null 2>&1; then
    echo "🪣 Restaurando MinIO..."
    MINIO_FILE=$(ls minio_*.tar.gz | head -n 1)
    tar -xzf $MINIO_FILE
    
    MINIO_DIR=$(ls -d minio_* | head -n 1)
    docker compose -f $BACKEND_DIR/docker-compose.prod.yml exec -T minio \
        mc mirror $TEMP_DIR/$MINIO_DIR/ /data/ 2>/dev/null || {
        echo -e "${YELLOW}⚠️  Erro ao restaurar MinIO. Verifique manualmente.${NC}"
    }
    echo -e "${GREEN}✅ MinIO restaurado${NC}"
fi

# Limpar diretório temporário
cd /
rm -rf $TEMP_DIR

# Limpar cache
echo "🧹 Limpando cache..."
docker compose -f $BACKEND_DIR/docker-compose.prod.yml exec -T php php artisan cache:clear || true
docker compose -f $BACKEND_DIR/docker-compose.prod.yml exec -T php php artisan config:clear || true

echo ""
echo -e "${GREEN}✅ Restauração concluída!${NC}"
echo ""
echo "📝 Próximos passos:"
echo "  1. Verifique se os containers estão rodando: docker compose -f $BACKEND_DIR/docker-compose.prod.yml ps"
echo "  2. Teste a aplicação: curl http://localhost:8000/api/health"
echo "  3. Se restaurou o .env, reinicie os containers: docker compose -f $BACKEND_DIR/docker-compose.prod.yml restart"

