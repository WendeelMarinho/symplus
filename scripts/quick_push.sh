#!/bin/bash
# Script rápido para commit e push
# Uso: bash scripts/quick_push.sh

set -e

cd "$(dirname "$0")/.."

echo "🚀 Fazendo commit e push para GitHub..."
echo ""

# Adicionar arquivos
git add .

# Verificar se há mudanças
if git diff --staged --quiet; then
    echo "⚠️  Nenhuma mudança para commitar"
    exit 0
fi

# Fazer commit
COMMIT_MSG="fix: Adiciona suporte para parâmetro metadata no TelemetryService.logError

- Adiciona parâmetro opcional metadata ao método logError
- Permite passar metadados adicionais nos logs de erro
- Mantém compatibilidade com chamadas existentes"

git commit -m "$COMMIT_MSG"

# Fazer push
BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
git push -u origin "$BRANCH"

echo ""
echo "✅ Push concluído com sucesso!"

