#!/bin/bash

# Script para fazer commit e push das mudanças de CORS no backend

set -e

echo "📦 Preparando commit das mudanças de CORS no backend..."

# Adicionar arquivos modificados
echo "📝 Adicionando arquivos..."
git add backend/app/Http/Middleware/CorsMiddleware.php
git add backend/scripts/test-cors.php
git add .cursorignore

# Verificar status
echo ""
echo "📋 Arquivos a serem commitados:"
git status --short

# Confirmar antes de fazer commit
echo ""
read -p "🤔 Deseja continuar com o commit? (s/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "❌ Commit cancelado."
    exit 1
fi

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
read -p "🚀 Deseja fazer push para o remoto? (s/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "ℹ️  Push cancelado. Execute 'git push' quando estiver pronto."
    exit 0
fi

echo ""
echo "🚀 Fazendo push para o remoto..."
git push

echo ""
echo "✅ Push realizado com sucesso!"

