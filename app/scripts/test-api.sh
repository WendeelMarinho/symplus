#!/bin/bash
# Script para testar a conexão com a API da VPS

set -e

API_URL="https://srv1113923.hstgr.cloud"
HEALTH_ENDPOINT="$API_URL/api/health"

echo "🔍 Testando conexão com a API..."
echo "URL: $API_URL"
echo ""

# Testar health check
echo "📡 Fazendo health check..."
if curl -f -s -o /dev/null -w "%{http_code}" "$HEALTH_ENDPOINT" | grep -q "200"; then
    echo "✅ Health check: OK (200)"
    echo ""
    echo "Resposta completa:"
    curl -s "$HEALTH_ENDPOINT" | jq '.' || curl -s "$HEALTH_ENDPOINT"
else
    echo "❌ Health check: FALHOU"
    echo "Status: $(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_ENDPOINT")"
    exit 1
fi

echo ""
echo "✅ API está acessível e respondendo corretamente!"

