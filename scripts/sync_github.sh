#!/bin/bash
# Script para sincronizar com GitHub (commit + pull + push)
# Uso: bash scripts/sync_github.sh

set -e

cd "$(dirname "$0")/.."

echo "🔄 Sincronizando com GitHub..."
echo ""

BRANCH=$(git branch --show-current 2>/dev/null || echo "main")

# 1. Adicionar todas as mudanças
echo "1️⃣  Adicionando mudanças ao staging..."
git add -A

# 2. Verificar se há algo para commitar
if ! git diff --staged --quiet; then
    echo "2️⃣  Fazendo commit das mudanças..."
    COMMIT_MSG="fix: Adiciona suporte para parâmetro metadata no TelemetryService.logError

- Adiciona parâmetro opcional metadata ao método logError
- Permite passar metadados adicionais nos logs de erro
- Mantém compatibilidade com chamadas existentes
- Atualiza script de push para lidar com mudanças não commitadas"
    
    git commit -m "$COMMIT_MSG"
    echo "✅ Commit realizado!"
else
    echo "✅ Nenhuma mudança para commitar"
fi

# 3. Fazer fetch do remote
echo ""
echo "3️⃣  Buscando atualizações do GitHub..."
git fetch origin "$BRANCH" || true

# 4. Verificar se precisa fazer pull
if git rev-parse --verify "origin/$BRANCH" >/dev/null 2>&1; then
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse "origin/$BRANCH")
    
    if [ "$LOCAL" != "$REMOTE" ]; then
        echo "4️⃣  Fazendo pull com rebase..."
        if git pull --rebase origin "$BRANCH"; then
            echo "✅ Pull concluído!"
        else
            echo ""
            echo "❌ Erro durante o rebase!"
            echo ""
            echo "Se houver conflitos, resolva-os e execute:"
            echo "  git add ."
            echo "  git rebase --continue"
            echo "  git push origin $BRANCH"
            exit 1
        fi
    else
        echo "✅ Repositório local já está atualizado"
    fi
fi

# 5. Fazer push
echo ""
echo "5️⃣  Fazendo push para GitHub..."
if git push -u origin "$BRANCH"; then
    echo ""
    echo "=========================================="
    echo "✅ Sincronização concluída com sucesso!"
    echo "=========================================="
    echo ""
    echo "Repositório: https://github.com/WendeelMarinho/symplus"
    echo "Branch: $BRANCH"
    echo ""
else
    echo ""
    echo "❌ Erro ao fazer push!"
    echo "Verifique suas permissões e tente novamente."
    exit 1
fi

