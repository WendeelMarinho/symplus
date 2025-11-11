# Script PowerShell para fazer commit das mudanças de CORS no backend

Write-Host "📦 Preparando commit das mudanças de CORS no backend..." -ForegroundColor Cyan

# Adicionar arquivos modificados
git add backend/app/Http/Middleware/CorsMiddleware.php
git add backend/scripts/test-cors.php
git add .cursorignore

# Verificar status
Write-Host ""
Write-Host "📋 Arquivos a serem commitados:" -ForegroundColor Yellow
git status --short

# Fazer commit
Write-Host ""
Write-Host "💾 Fazendo commit..." -ForegroundColor Cyan
git commit -m "fix(backend): Melhorar configuração CORS para Flutter Web

- Adicionar suporte para localhost em qualquer porta
- Permitir origens de desenvolvimento (localhost, 127.0.0.1)
- Adicionar script de teste CORS (test-cors.php)
- Configurar Access-Control-Allow-Credentials corretamente
- Melhorar tratamento de preflight OPTIONS

Resolve problemas de conexão do Flutter Web com a API VPS"

Write-Host ""
Write-Host "✅ Commit realizado com sucesso!" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Para fazer push:" -ForegroundColor Yellow
Write-Host "   git push" -ForegroundColor White

