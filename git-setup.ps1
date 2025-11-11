# Script PowerShell para inicializar o repositório Git e fazer push para o remoto

Write-Host "Inicializando repositório Git..." -ForegroundColor Green
git init

Write-Host "Adicionando remote..." -ForegroundColor Green
git remote add origin https://github.com/WendeelMarinho/symplus.git

Write-Host "Adicionando arquivos ao staging..." -ForegroundColor Green
git add .

Write-Host "Fazendo commit inicial..." -ForegroundColor Green
git commit -m "Initial commit: Symplus Finance - Plataforma de gestão financeira multi-tenant"

Write-Host "Configurando branch main..." -ForegroundColor Green
git branch -M main

Write-Host "Fazendo push para o repositório remoto..." -ForegroundColor Green
git push -u origin main

Write-Host "✅ Concluído!" -ForegroundColor Green

