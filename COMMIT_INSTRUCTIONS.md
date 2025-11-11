# 📝 Instruções para Commit e Push

## Comandos para executar:

```bash
# 1. Adicionar arquivos modificados
git add backend/app/Http/Middleware/CorsMiddleware.php
git add backend/scripts/test-cors.php
git add .cursorignore

# 2. Verificar o que será commitado
git status

# 3. Fazer commit
git commit -m "fix(backend): Melhorar configuração CORS para Flutter Web

- Adicionar suporte para localhost em qualquer porta
- Permitir origens de desenvolvimento (localhost, 127.0.0.1)
- Adicionar script de teste CORS (test-cors.php)
- Configurar Access-Control-Allow-Credentials corretamente
- Melhorar tratamento de preflight OPTIONS
- Remover .env do .cursorignore (usar .gitignore)

Resolve problemas de conexão do Flutter Web com a API VPS"

# 4. Fazer push para o remoto
git push
```

## Ou use os scripts criados:

**Windows (PowerShell):**
```powershell
.\scripts\commit-and-push.ps1
```

**Linux/Mac:**
```bash
bash scripts/commit-and-push.sh
```

**Automático (sem confirmação):**
```bash
bash scripts/commit-and-push-auto.sh
```

