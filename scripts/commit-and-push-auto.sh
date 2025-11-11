#!/bin/bash

# Script automático para fazer commit e push (sem confirmação)

set -e

echo "📦 Preparando commit automático das mudanças de CORS no backend..."

# Adicionar arquivos modificados
git add backend/app/Http/Middleware/CorsMiddleware.php
git add backend/scripts/test-cors.php
git add .cursorignore

# Verificar status
echo ""
echo "📋 Arquivos a serem commitados:"
git status --short

# Fazer commit
echo ""
echo "💾 Fazendo commit..."
git commit -m "fix(backend): Melhorar configuração CORS para Flutter Web

- Adicionar suporte para localhost em qualquer porta
- Permitir origens de desenvolvimento (localhost, 127.0.0.1)
- Adicionar script de teste CORS (test-cors.php)
- Configurar Access-Control-Allow-Credentials corretamente
- Melhorar tratamento de preflight OPTIONS
- Remover .env do .cursorignore (usar .gitignore)

Resolve problemas de conexão do Flutter Web com a API VPS"

echo ""
echo "✅ Commit realizado com sucesso!"

# Fazer push
echo ""
echo "🚀 Fazendo push para o remoto..."
git push

echo ""
echo "✅ Push realizado com sucesso!"

