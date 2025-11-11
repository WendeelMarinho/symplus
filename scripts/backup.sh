#!/bin/bash

# Script de backup do Symplus Finance
# Uso: ./backup.sh

set -e

BACKUP_DIR="/var/backups/symplus"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=7
PROJECT_DIR="/var/www/symplus"
BACKEND_DIR="$PROJECT_DIR/backend"

# Cores
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo "💾 Iniciando backup do Symplus Finance..."

# Criar diretório de backup
mkdir -p $BACKUP_DIR

# Ler variáveis do .env
if [ -f "$BACKEND_DIR/.env" ]; then
    source <(grep -E "^DB_" $BACKEND_DIR/.env | sed 's/^/export /')
    source <(grep -E "^AWS_BUCKET" $BACKEND_DIR/.env | sed 's/^/export /')
else
    echo "⚠️  Arquivo .env não encontrado. Usando valores padrão."
    export DB_DATABASE=symplus
    export DB_USERNAME=symplus
    export DB_PASSWORD=root
    export AWS_BUCKET=symplus
fi

# Backup do banco de dados
echo "📦 Fazendo backup do banco de dados..."
docker compose -f $BACKEND_DIR/docker-compose.prod.yml exec -T db \
    mysqldump -u ${DB_USERNAME:-symplus} -p${DB_PASSWORD:-root} ${DB_DATABASE:-symplus} \
    > $BACKUP_DIR/db_$DATE.sql 2>/dev/null || {
    echo "⚠️  Erro ao fazer backup do banco. Tentando método alternativo..."
    docker compose -f $BACKEND_DIR/docker-compose.prod.yml exec -T db \
        mysqldump -u root -p${DB_PASSWORD:-root} ${DB_DATABASE:-symplus} \
        > $BACKUP_DIR/db_$DATE.sql
}

# Comprimir backup do banco
gzip $BACKUP_DIR/db_$DATE.sql
echo "✅ Backup do banco: db_$DATE.sql.gz"

# Backup do storage
echo "📦 Fazendo backup do storage..."
if [ -d "$BACKEND_DIR/storage" ]; then
    tar -czf $BACKUP_DIR/storage_$DATE.tar.gz -C $BACKEND_DIR storage
    echo "✅ Backup do storage: storage_$DATE.tar.gz"
else
    echo "⚠️  Diretório storage não encontrado"
fi

# Backup do .env
echo "📦 Fazendo backup do .env..."
if [ -f "$BACKEND_DIR/.env" ]; then
    cp $BACKEND_DIR/.env $BACKUP_DIR/.env_$DATE
    echo "✅ Backup do .env: .env_$DATE"
fi

# Backup do MinIO (opcional)
echo "📦 Fazendo backup do MinIO..."
if docker compose -f $BACKEND_DIR/docker-compose.prod.yml ps minio | grep -q "Up"; then
    mkdir -p $BACKUP_DIR/minio_$DATE
    docker compose -f $BACKEND_DIR/docker-compose.prod.yml exec -T minio \
        mc mirror /data $BACKUP_DIR/minio_$DATE/ 2>/dev/null || {
        echo "⚠️  Erro ao fazer backup do MinIO. Pulando..."
    }
    if [ -d "$BACKUP_DIR/minio_$DATE" ] && [ "$(ls -A $BACKUP_DIR/minio_$DATE)" ]; then
        tar -czf $BACKUP_DIR/minio_$DATE.tar.gz -C $BACKUP_DIR minio_$DATE
        rm -rf $BACKUP_DIR/minio_$DATE
        echo "✅ Backup do MinIO: minio_$DATE.tar.gz"
    fi
else
    echo "⚠️  Container MinIO não está rodando. Pulando backup do MinIO."
fi

# Criar arquivo de metadados
echo "📝 Criando arquivo de metadados..."
cat > $BACKUP_DIR/metadata_$DATE.txt << EOF
Backup do Symplus Finance
Data: $(date)
Versão: $(cd $PROJECT_DIR && git rev-parse HEAD 2>/dev/null || echo "N/A")
Branch: $(cd $PROJECT_DIR && git branch --show-current 2>/dev/null || echo "N/A")
EOF

# Compactar tudo em um único arquivo
echo "📦 Compactando backup completo..."
cd $BACKUP_DIR
tar -czf backup_completo_$DATE.tar.gz \
    db_$DATE.sql.gz \
    storage_$DATE.tar.gz \
    .env_$DATE \
    metadata_$DATE.txt \
    $(ls minio_$DATE.tar.gz 2>/dev/null || true) 2>/dev/null

echo "✅ Backup completo: backup_completo_$DATE.tar.gz"

# Remover arquivos antigos
echo "🧹 Removendo backups antigos (mais de $RETENTION_DAYS dias)..."
find $BACKUP_DIR -name "backup_completo_*.tar.gz" -mtime +$RETENTION_DAYS -delete
find $BACKUP_DIR -name "db_*.sql.gz" -mtime +$RETENTION_DAYS -delete
find $BACKUP_DIR -name "storage_*.tar.gz" -mtime +$RETENTION_DAYS -delete
find $BACKUP_DIR -name ".env_*" -mtime +$RETENTION_DAYS -delete
find $BACKUP_DIR -name "minio_*.tar.gz" -mtime +$RETENTION_DAYS -delete
find $BACKUP_DIR -name "metadata_*.txt" -mtime +$RETENTION_DAYS -delete

# Exibir tamanho do backup
BACKUP_SIZE=$(du -h $BACKUP_DIR/backup_completo_$DATE.tar.gz | cut -f1)
echo ""
echo -e "${GREEN}✅ Backup concluído!${NC}"
echo "📦 Arquivo: backup_completo_$DATE.tar.gz"
echo "💾 Tamanho: $BACKUP_SIZE"
echo "📁 Local: $BACKUP_DIR"

