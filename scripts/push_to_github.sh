#!/bin/bash
# Script para fazer commit e push para o GitHub
# Repositório: https://github.com/WendeelMarinho/symplus.git
#
# Uso:
#   chmod +x scripts/push_to_github.sh
#   bash scripts/push_to_github.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

echo "=========================================="
echo "🚀 Push para GitHub"
echo "=========================================="
echo ""

# Verificar se está em um repositório git
if [ ! -d ".git" ]; then
    echo "❌ Este diretório não é um repositório Git!"
    echo "   Inicializando repositório..."
    git init
fi

# Verificar se o remote está configurado
REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")

if [ -z "$REMOTE_URL" ]; then
    echo "📡 Configurando remote 'origin'..."
    git remote add origin https://github.com/WendeelMarinho/symplus.git
    echo "✅ Remote configurado!"
elif [ "$REMOTE_URL" != "https://github.com/WendeelMarinho/symplus.git" ]; then
    echo "⚠️  Remote atual: $REMOTE_URL"
    echo "📡 Atualizando remote para GitHub..."
    git remote set-url origin https://github.com/WendeelMarinho/symplus.git
    echo "✅ Remote atualizado!"
else
    echo "✅ Remote já está configurado corretamente"
fi

echo ""
echo "📋 Verificando status do Git..."
git status

echo ""
echo "=========================================="
read -p "Deseja continuar com o commit e push? (s/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[SsYy]$ ]]; then
    echo "❌ Operação cancelada pelo usuário"
    exit 1
fi

echo ""
echo "1️⃣  Adicionando arquivos ao staging..."
git add .

echo ""
echo "2️⃣  Verificando arquivos que serão commitados..."
git status --short

echo ""
echo "3️⃣  Fazendo commit..."
COMMIT_MESSAGE="feat: Atualização completa do projeto - Dashboard, Indicadores, i18n, Moeda, Avatar

- ✅ Dashboard completo com KPIs, gráficos e calendário
- ✅ Filtro global de período
- ✅ Indicadores personalizados (CRUD)
- ✅ Resumo trimestral
- ✅ Sistema de moeda (BRL/USD)
- ✅ Sistema de idiomas (PT/EN)
- ✅ Upload de avatar/logo
- ✅ Correções de layout e renderização
- ✅ Build de produção configurado
- ✅ Documentação atualizada"

git commit -m "$COMMIT_MESSAGE" || {
    echo "⚠️  Nenhuma mudança para commitar ou commit cancelado"
    read -p "Deseja fazer push mesmo assim? (s/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[SsYy]$ ]]; then
        exit 1
    fi
}

echo ""
echo "4️⃣  Fazendo push para GitHub..."
BRANCH=$(git branch --show-current 2>/dev/null || echo "main")

# Verificar se a branch existe no remote
if git ls-remote --heads origin "$BRANCH" | grep -q "$BRANCH"; then
    echo "   Branch '$BRANCH' existe no remote, fazendo push..."
    git push -u origin "$BRANCH"
else
    echo "   Branch '$BRANCH' não existe no remote, criando..."
    git push -u origin "$BRANCH"
fi

echo ""
echo "=========================================="
echo "✅ Push concluído com sucesso!"
echo "=========================================="
echo ""
echo "Repositório: https://github.com/WendeelMarinho/symplus"
echo "Branch: $BRANCH"
echo ""
echo "Próximos passos:"
echo "  1. Verificar no GitHub se o push foi bem-sucedido"
echo "  2. Executar migration no backend: cd backend && make migrate"
echo "  3. Fazer build do Flutter Web: bash scripts/build_flutter_web.sh"
echo "  4. Fazer deploy no servidor VPS"

