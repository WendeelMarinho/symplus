@echo off
REM Script batch para fazer commit e push das mudanças de CORS no backend

echo 📦 Preparando commit das mudanças de CORS no backend...

REM Adicionar arquivos modificados
echo 📝 Adicionando arquivos...
git add backend/app/Http/Middleware/CorsMiddleware.php
git add backend/scripts/test-cors.php
git add .cursorignore

REM Verificar status
echo.
echo 📋 Arquivos a serem commitados:
git status --short

REM Fazer commit
echo.
echo 💾 Fazendo commit...
git commit -m "fix(backend): Melhorar configuração CORS para Flutter Web

- Adicionar suporte para localhost em qualquer porta
- Permitir origens de desenvolvimento (localhost, 127.0.0.1)
- Adicionar script de teste CORS (test-cors.php)
- Configurar Access-Control-Allow-Credentials corretamente
- Melhorar tratamento de preflight OPTIONS
- Remover .env do .cursorignore (usar .gitignore)

Resolve problemas de conexão do Flutter Web com a API VPS"

if %errorlevel% neq 0 (
    echo ❌ Erro ao fazer commit!
    pause
    exit /b 1
)

echo.
echo ✅ Commit realizado com sucesso!

REM Fazer push
echo.
echo 🚀 Fazendo push para o remoto...
git push

if %errorlevel% neq 0 (
    echo ❌ Erro ao fazer push!
    pause
    exit /b 1
)

echo.
echo ✅ Push realizado com sucesso!
pause

