# 🚀 Deploy para Produção - Guia Técnico

## 📋 Contexto

Projeto **Symplus Finance** pronto para produção. Código completo, testado e corrigido.  
**Repositório:** https://github.com/WendeelMarinho/symplus.git  
**Servidor VPS:** srv1113923.hstgr.cloud (72.61.6.135) - Ubuntu 22.04 LTS - Usuário: root

---

## 🎯 Objetivo

Fazer deploy completo em produção: migration → build → push → deploy no servidor.

---

## ⚡ Execução Rápida

### 1. Executar Migration (Backend)

```bash
cd /home/wendeel/projetos/symplus2/backend
docker compose -f docker-compose.prod.yml exec php php artisan migrate
```

**Verificar:**
```bash
docker compose -f docker-compose.prod.yml exec db mysql -u symplus -psymplus symplus -e "SHOW TABLES LIKE 'custom_indicators';"
```

---

### 2. Build Flutter Web

```bash
cd /home/wendeel/projetos/symplus2/app
flutter clean && flutter pub get
flutter build web --release --dart-define=API_BASE_URL=https://srv1113923.hstgr.cloud --base-href=/app/
```

**Copiar para deploy:**
```bash
cd /home/wendeel/projetos/symplus2
mkdir -p backend/public/app && rm -rf backend/public/app/*
cp -r app/build/web/* backend/public/app/
```

---

### 3. Commit e Push (GitHub)

```bash
cd /home/wendeel/projetos/symplus2

# Verificar arquivos sensíveis
git diff --cached --name-only | grep "\.env" || echo "✅ OK"

# Configurar remote
git remote set-url origin https://github.com/WendeelMarinho/symplus.git

# Commit e push
git add .
git commit -m "feat: Deploy produção - Dashboard completo, Indicadores, i18n, Moeda, Avatar"
git push -u origin main
```

---

### 4. Deploy no Servidor VPS

```bash
# Conectar ao servidor
ssh root@srv1113923.hstgr.cloud

# No servidor:
cd /var/www/symplus
git pull origin main
cd backend && docker compose -f docker-compose.prod.yml exec php php artisan migrate --force
cd ../app && flutter build web --release --dart-define=API_BASE_URL=https://srv1113923.hstgr.cloud --base-href=/app/
mkdir -p ../backend/public/app && rm -rf ../backend/public/app/* && cp -r build/web/* ../backend/public/app/
cd ../backend && docker compose -f docker-compose.prod.yml restart nginx
```

**Verificar:**
```bash
curl -I https://srv1113923.hstgr.cloud/app/  # Deve retornar HTTP/2 200
```

---

## 🔍 Verificações

### Migration
```bash
docker compose -f docker-compose.prod.yml exec db mysql -u symplus -psymplus symplus -e "DESCRIBE custom_indicators;"
```

### Build
```bash
ls -la app/build/web/index.html
grep -q 'base href="/app/"' app/build/web/index.html && echo "✅ OK"
```

### Git
```bash
git status
git log -1 --oneline
```

### Servidor
```bash
curl -I https://srv1113923.hstgr.cloud/app/
docker compose -f docker-compose.prod.yml logs nginx --tail=20
```

---

## 🐛 Troubleshooting

**Migration falha:**
```bash
docker compose -f docker-compose.prod.yml exec php php artisan migrate:fresh
```

**Build falha:**
```bash
cd app && flutter clean && rm -rf .dart_tool build && flutter pub get
```

**Push rejeitado:**
```bash
git pull origin main --rebase && git push origin main
```

**Aplicação não carrega:**
```bash
# Verificar Nginx
docker compose -f docker-compose.prod.yml logs nginx
# Verificar arquivos
ls -la /var/www/symplus/backend/public/app/
# Reiniciar
docker compose -f docker-compose.prod.yml restart nginx
```

---

## ✅ Checklist Final

- [ ] Migration executada (tabela `custom_indicators` existe)
- [ ] Build Flutter gerado
- [ ] Arquivos em `backend/public/app/`
- [ ] Commit feito
- [ ] Push para GitHub bem-sucedido
- [ ] Código atualizado no servidor
- [ ] Migration executada no servidor
- [ ] Build gerado no servidor
- [ ] Nginx reiniciado
- [ ] Aplicação acessível em https://srv1113923.hstgr.cloud/app/

---

**Ordem:** Migration → Build → Commit → Push → Deploy no servidor

