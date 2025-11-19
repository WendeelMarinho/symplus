# 🤖 Prompt para IA - Deploy em Produção

## Contexto

Você está fazendo o deploy do **Symplus Finance** em produção. O código está completo e testado. Execute as tarefas na ordem abaixo.

**Repositório:** https://github.com/WendeelMarinho/symplus.git  
**Servidor:** srv1113923.hstgr.cloud (root@72.61.6.135) - Ubuntu 22.04 LTS

---

## Tarefa 1: Executar Migration

**Objetivo:** Criar tabela `custom_indicators` no banco de dados.

```bash
cd /home/wendeel/projetos/symplus2/backend
docker compose -f docker-compose.prod.yml exec php php artisan migrate
```

**Verificar:**
```bash
docker compose -f docker-compose.prod.yml exec db mysql -u symplus -psymplus symplus -e "SHOW TABLES LIKE 'custom_indicators';"
```

**Resultado esperado:** Tabela criada com colunas: id, organization_id, name, category_ids (json), created_at, updated_at

---

## Tarefa 2: Build Flutter Web

**Objetivo:** Gerar arquivos estáticos para produção.

```bash
cd /home/wendeel/projetos/symplus2/app
flutter clean
flutter pub get
flutter build web --release --dart-define=API_BASE_URL=https://srv1113923.hstgr.cloud --base-href=/app/
```

**Copiar para deploy:**
```bash
cd /home/wendeel/projetos/symplus2
mkdir -p backend/public/app
rm -rf backend/public/app/*
cp -r app/build/web/* backend/public/app/
```

**Verificar:**
```bash
ls -la backend/public/app/index.html  # Deve existir
```

---

## Tarefa 3: Commit e Push

**Objetivo:** Enviar código para GitHub.

```bash
cd /home/wendeel/projetos/symplus2

# Verificar arquivos sensíveis (NÃO deve ter .env)
git diff --cached --name-only | grep "\.env" && echo "❌ REMOVER .env DO STAGING" || echo "✅ OK"

# Configurar remote
git remote set-url origin https://github.com/WendeelMarinho/symplus.git

# Verificar branch
git branch --show-current  # Deve ser 'main'

# Commit
git add .
git commit -m "feat: Deploy produção - Dashboard completo, Indicadores, i18n, Moeda, Avatar

- Dashboard completo com KPIs, gráficos e calendário
- Filtro global de período
- Indicadores personalizados (CRUD)
- Resumo trimestral
- Sistema de moeda (BRL/USD)
- Sistema de idiomas (PT/EN)
- Upload de avatar/logo
- Correções de layout
- Build de produção configurado"

# Push
git push -u origin main
```

**Verificar:**
```bash
git fetch origin && git status  # Deve mostrar "up to date"
```

---

## Tarefa 4: Deploy no Servidor

**Objetivo:** Atualizar código no servidor e fazer deploy.

```bash
# Conectar ao servidor
ssh root@srv1113923.hstgr.cloud

# No servidor, executar:
cd /var/www/symplus
git pull origin main
cd backend
docker compose -f docker-compose.prod.yml exec php php artisan migrate --force
cd ../app
flutter build web --release --dart-define=API_BASE_URL=https://srv1113923.hstgr.cloud --base-href=/app/
mkdir -p ../backend/public/app && rm -rf ../backend/public/app/*
cp -r build/web/* ../backend/public/app/
chmod -R 755 ../backend/public/app
cd ../backend
docker compose -f docker-compose.prod.yml restart nginx
```

**Verificar:**
```bash
curl -I https://srv1113923.hstgr.cloud/app/  # HTTP/2 200
```

---

## ⚠️ Problemas Comuns

**Erro: "Table doesn't exist"** → Executar Tarefa 1  
**Erro: "Permission denied"** → Configurar autenticação GitHub  
**Erro: "Updates rejected"** → `git pull origin main --rebase`  
**Erro: "Container not found"** → `docker compose -f docker-compose.prod.yml up -d`  
**404 no navegador** → Verificar Nginx e arquivos em `/var/www/symplus/backend/public/app/`

---

## ✅ Validação Final

Após todas as tarefas:

1. ✅ Tabela `custom_indicators` existe no banco
2. ✅ Build gerado em `app/build/web/`
3. ✅ Arquivos em `backend/public/app/`
4. ✅ Código no GitHub
5. ✅ Aplicação acessível em https://srv1113923.hstgr.cloud/app/
6. ✅ Dashboard carrega sem erros

---

**Execute as tarefas na ordem: 1 → 2 → 3 → 4**

