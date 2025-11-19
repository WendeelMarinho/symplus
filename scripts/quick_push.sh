#!/bin/bash
# Script rápido para commit e push
# Uso: bash scripts/quick_push.sh

set -e

cd "$(dirname "$0")/.."

echo "🚀 Fazendo commit e push para GitHub..."
echo ""

BRANCH=$(git branch --show-current 2>/dev/null || echo "main")

# Verificar se há mudanças não commitadas ou não staged
HAS_UNSTAGED=$(git diff --quiet 2>/dev/null || echo "yes")
HAS_STAGED=$(git diff --staged --quiet 2>/dev/null || echo "yes")

# Se houver mudanças, fazer commit primeiro
if [ "$HAS_UNSTAGED" = "yes" ] || [ "$HAS_STAGED" = "yes" ]; then
    echo "📝 Detectadas mudanças não commitadas. Fazendo commit..."
    git add .
    
    # Verificar se há algo para commitar
    if ! git diff --staged --quiet; then
        COMMIT_MSG="fix: Adiciona suporte para parâmetro metadata no TelemetryService.logError

- Adiciona parâmetro opcional metadata ao método logError
- Permite passar metadados adicionais nos logs de erro
- Mantém compatibilidade com chamadas existentes"

        git commit -m "$COMMIT_MSG" || {
            echo "⚠️  Nenhuma mudança para commitar"
        }
    fi
fi

# Fazer pull com rebase primeiro (se necessário)
echo "📥 Verificando atualizações do remote..."
git fetch origin "$BRANCH" 2>/dev/null || true

# Verificar se há diferenças entre local e remote
if git rev-parse --verify "origin/$BRANCH" >/dev/null 2>&1; then
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse "origin/$BRANCH")
    
    if [ "$LOCAL" != "$REMOTE" ]; then
        echo "   Fazendo pull com rebase..."
        git pull --rebase origin "$BRANCH" || {
            echo ""
            echo "⚠️  Conflitos detectados durante o rebase!"
            echo "   Resolva os conflitos e execute:"
            echo "   git add ."
            echo "   git rebase --continue"
            echo "   git push origin $BRANCH"
            exit 1
        }
        echo "✅ Rebase concluído com sucesso!"
    else
        echo "✅ Repositório local está atualizado"
    fi
fi

# Fazer push
echo "📤 Fazendo push para GitHub..."
git push -u origin "$BRANCH"

echo ""
echo "✅ Push concluído com sucesso!"
echo ""
echo "Repositório: https://github.com/WendeelMarinho/symplus"
echo "Branch: $BRANCH"

