# Script PowerShell para fazer commit e push das mudanças de CORS no backend

Write-Host "📦 Preparando commit das mudanças de CORS no backend..." -ForegroundColor Cyan

# Adicionar arquivos modificados
Write-Host "📝 Adicionando arquivos..." -ForegroundColor Yellow
git add backend/app/Http/Middleware/CorsMiddleware.php
git add backend/scripts/test-cors.php
git add .cursorignore

# Verificar status
Write-Host ""
Write-Host "📋 Arquivos a serem commitados:" -ForegroundColor Yellow
git status --short

# Confirmar antes de fazer commit
Write-Host ""
$confirm = Read-Host "🤔 Deseja continuar com o commit? (s/N)"
if ($confirm -ne "s" -and $confirm -ne "S") {
    Write-Host "❌ Commit cancelado." -ForegroundColor Red
    exit 1
}

# Fazer commit
Write-Host ""
Write-Host "💾 Fazendo commit..." -ForegroundColor Cyan
git commit -m "fix(backend): Melhorar configuração CORS para Flutter Web

- Adicionar suporte para localhost em qualquer porta
- Permitir origens de desenvolvimento (localhost, 127.0.0.1)
- Adicionar script de teste CORS (test-cors.php)
- Configurar Access-Control-Allow-Credentials corretamente
- Melhorar tratamento de preflight OPTIONS
- Remover .env do .cursorignore (usar .gitignore)

Resolve problemas de conexão do Flutter Web com a API VPS"

Write-Host ""
Write-Host "✅ Commit realizado com sucesso!" -ForegroundColor Green

# Fazer push
Write-Host ""
$pushConfirm = Read-Host "🚀 Deseja fazer push para o remoto? (s/N)"
if ($pushConfirm -ne "s" -and $pushConfirm -ne "S") {
    Write-Host "ℹ️  Push cancelado. Execute 'git push' quando estiver pronto." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "🚀 Fazendo push para o remoto..." -ForegroundColor Cyan
git push

Write-Host ""
Write-Host "✅ Push realizado com sucesso!" -ForegroundColor Green

