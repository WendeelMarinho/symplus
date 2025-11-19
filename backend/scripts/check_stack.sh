#!/bin/bash

# Script de validação da stack SYMPLUS
# Verifica se Nginx, PHP-FPM, Laravel e Redis estão funcionando corretamente

set -e

echo "=========================================="
echo "🔍 Validação da Stack SYMPLUS"
echo "=========================================="
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para exibir sucesso
success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Função para exibir erro
error() {
    echo -e "${RED}❌ $1${NC}"
}

# Função para exibir aviso
warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# 1. Verificar se Nginx está respondendo
echo "1️⃣  Testando Nginx (http://localhost:8000)..."
if curl -sS -D- http://localhost:8000/ 2>&1 | head -n 15 | grep -q "HTTP/"; then
    success "Nginx está respondendo"
else
    error "Nginx não está respondendo"
    exit 1
fi
echo ""

# 2. Verificar rota /api/health
echo "2️⃣  Testando /api/health..."
HEALTH_RESPONSE=$(curl -sS -D- http://localhost:8000/api/health 2>&1)
if echo "$HEALTH_RESPONSE" | grep -q "HTTP/1.1 200"; then
    success "Rota /api/health retorna HTTP 200"
    if echo "$HEALTH_RESPONSE" | grep -q '"ok":true'; then
        success "Resposta JSON válida"
    else
        warning "Resposta não contém 'ok:true'"
    fi
else
    error "Rota /api/health não retorna HTTP 200"
    echo "$HEALTH_RESPONSE" | head -n 15
    exit 1
fi
echo ""

# 3. Verificar PHP e rotas Laravel
echo "3️⃣  Verificando PHP e rotas Laravel..."
if docker compose -f docker-compose.prod.yml exec -T php php -v > /dev/null 2>&1; then
    success "PHP está funcionando"
    ROUTE_COUNT=$(docker compose -f docker-compose.prod.yml exec -T php php artisan route:list 2>/dev/null | wc -l)
    if [ "$ROUTE_COUNT" -gt 0 ]; then
        success "Laravel tem $ROUTE_COUNT rotas registradas"
        if docker compose -f docker-compose.prod.yml exec -T php php artisan route:list 2>/dev/null | grep -q "/api/health"; then
            success "Rota /api/health está registrada"
        else
            warning "Rota /api/health não encontrada em route:list"
        fi
    else
        error "Nenhuma rota encontrada"
        exit 1
    fi
else
    error "PHP não está funcionando"
    exit 1
fi
echo ""

# 4. Verificar Redis
echo "4️⃣  Verificando Redis..."
if docker compose -f docker-compose.prod.yml exec -T php php -r "echo gethostbyname('redis'), PHP_EOL;" 2>/dev/null | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'; then
    REDIS_IP=$(docker compose -f docker-compose.prod.yml exec -T php php -r "echo gethostbyname('redis'), PHP_EOL;" 2>/dev/null | tr -d '\n')
    success "Redis resolve para: $REDIS_IP"
    
    if docker compose -f docker-compose.prod.yml exec -T php sh -c "nc -zv redis 6379 2>&1" | grep -q "succeeded\|open"; then
        success "Redis está acessível na porta 6379"
    else
        warning "Não foi possível conectar ao Redis (pode ser normal se nc não estiver instalado)"
    fi
else
    error "Redis não resolve via DNS"
    exit 1
fi
echo ""

# 5. Verificar CORS (OPTIONS preflight)
echo "5️⃣  Testando CORS (OPTIONS preflight)..."
CORS_RESPONSE=$(curl -sS -D- -X OPTIONS http://localhost:8000/api/health \
    -H "Origin: http://localhost:33337" \
    -H "Access-Control-Request-Method: GET" \
    2>&1)
if echo "$CORS_RESPONSE" | grep -q "HTTP/1.1 204\|HTTP/1.1 200"; then
    success "OPTIONS retorna 204/200"
    if echo "$CORS_RESPONSE" | grep -qi "Access-Control-Allow-Origin"; then
        success "CORS headers presentes"
    else
        warning "CORS headers não encontrados"
    fi
else
    error "OPTIONS não retorna 204/200"
    echo "$CORS_RESPONSE" | head -n 15
fi
echo ""

# 6. Verificar containers
echo "6️⃣  Verificando containers Docker..."
if docker compose -f docker-compose.prod.yml ps | grep -q "Up"; then
    success "Containers estão rodando"
    docker compose -f docker-compose.prod.yml ps --format "table {{.Name}}\t{{.Status}}"
else
    error "Nenhum container está rodando"
    exit 1
fi
echo ""

echo "=========================================="
echo -e "${GREEN}✅ Validação concluída com sucesso!${NC}"
echo "=========================================="

