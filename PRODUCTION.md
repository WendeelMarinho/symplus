# 🚀 Guia de Produção - Symplus Finance

## 📋 Informações da VPS

- **Host**: `srv1113923.hstgr.cloud`
- **IP**: `72.61.6.135`
- **SO**: Ubuntu 22.04 LTS
- **Usuário SSH**: `root`
- **Path de Deploy**: `/var/www/symplus`
- **URL de Produção**: `https://srv1113923.hstgr.cloud`
- **URL da API**: `https://srv1113923.hstgr.cloud/api`
- **URL do App Web**: `https://srv1113923.hstgr.cloud/app/`

---

## 🔧 Configuração de Produção

### Variáveis de Ambiente

#### Backend (.env)

```env
APP_NAME="Symplus Finance"
APP_ENV=production
APP_KEY=base64:... (gerado via php artisan key:generate)
APP_DEBUG=false
APP_URL=https://srv1113923.hstgr.cloud

DB_CONNECTION=mysql
DB_HOST=db
DB_PORT=3306
DB_DATABASE=symplus
DB_USERNAME=symplus
DB_PASSWORD=symplus

CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis

REDIS_HOST=redis
REDIS_PASSWORD=null
REDIS_PORT=6379

SANCTUM_STATEFUL_DOMAINS=srv1113923.hstgr.cloud
SESSION_DOMAIN=.srv1113923.hstgr.cloud
```

#### Frontend (Build)

A URL da API é configurada via `--dart-define` durante o build:

```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://srv1113923.hstgr.cloud \
  --base-href=/app/
```

---

## 📦 Build de Produção

### 1. Build Flutter Web

```bash
cd app
flutter clean
flutter pub get
flutter build web --release \
  --dart-define=API_BASE_URL=https://srv1113923.hstgr.cloud \
  --base-href=/app/ \
  --web-renderer canvaskit

# Copiar para diretório de deploy
mkdir -p ../backend/public/app
rm -rf ../backend/public/app/*
cp -r build/web/* ../backend/public/app/
```

**Script automatizado:**
```bash
bash scripts/build_flutter_web.sh
```

### 2. Build Flutter APK

```bash
cd app
flutter clean
flutter pub get
flutter build apk --release \
  --dart-define=API_BASE_URL=https://srv1113923.hstgr.cloud

# APK gerado em: build/app/outputs/flutter-apk/app-release.apk
```

**Script automatizado:**
```bash
bash scripts/build_flutter_apk.sh
```

### 3. Build Completo (Web + APK)

```bash
bash scripts/build_all.sh
```

---

## 🚀 Deploy na VPS

### Deploy Automatizado (Recomendado)

```bash
# Configurar variáveis
export VPS_HOST="srv1113923.hstgr.cloud"
export VPS_USER="root"
export VPS_PATH="/var/www/symplus"
export GIT_REPO="https://github.com/WendeelMarinho/symplus.git"
export BRANCH="main"
export DOMAIN_HEALTHCHECK="https://srv1113923.hstgr.cloud/api/health"

# Executar deploy
bash scripts/vps_deploy.sh
```

### Deploy Manual

#### 1. Conectar ao Servidor

```bash
ssh root@srv1113923.hstgr.cloud
```

#### 2. Atualizar Código

```bash
cd /var/www/symplus
git pull origin main
```

#### 3. Build Flutter Web (no servidor ou localmente)

**Localmente:**
```bash
cd app
flutter build web --release \
  --dart-define=API_BASE_URL=https://srv1113923.hstgr.cloud \
  --base-href=/app/
scp -r build/web/* root@srv1113923.hstgr.cloud:/var/www/symplus/backend/public/app/
```

**No servidor:**
```bash
cd /var/www/symplus/app
flutter build web --release \
  --dart-define=API_BASE_URL=https://srv1113923.hstgr.cloud \
  --base-href=/app/
mkdir -p ../backend/public/app
rm -rf ../backend/public/app/*
cp -r build/web/* ../backend/public/app/
```

#### 4. Executar Migrations

```bash
cd /var/www/symplus/backend
docker compose -f docker-compose.prod.yml exec php php artisan migrate --force
```

#### 5. Otimizar Laravel

```bash
docker compose -f docker-compose.prod.yml exec php php artisan optimize:clear
docker compose -f docker-compose.prod.yml exec php php artisan optimize
docker compose -f docker-compose.prod.yml exec php php artisan config:cache
docker compose -f docker-compose.prod.yml exec php php artisan route:cache
docker compose -f docker-compose.prod.yml exec php php artisan view:cache
```

#### 6. Reiniciar Serviços

```bash
docker compose -f docker-compose.prod.yml restart nginx
docker compose -f docker-compose.prod.yml restart php
```

---

## ✅ Verificação Pós-Deploy

### 1. Healthcheck da API

```bash
curl https://srv1113923.hstgr.cloud/api/health
```

**Resposta esperada:**
```json
{
  "status": "ok",
  "timestamp": "2025-11-24T..."
}
```

### 2. Verificar App Web

```bash
curl -I https://srv1113923.hstgr.cloud/app/
```

**Resposta esperada:** `HTTP/2 200`

### 3. Verificar Containers

```bash
ssh root@srv1113923.hstgr.cloud
cd /var/www/symplus/backend
docker compose -f docker-compose.prod.yml ps
```

Todos os containers devem estar com status `Up`.

### 4. Verificar Logs

```bash
# Logs do PHP
docker compose -f docker-compose.prod.yml logs php --tail=50

# Logs do Nginx
docker compose -f docker-compose.prod.yml logs nginx --tail=50

# Logs do Laravel
docker compose -f docker-compose.prod.yml exec php tail -f storage/logs/laravel.log
```

---

## 🔒 Segurança

### SSL/TLS

Certifique-se de que o SSL está configurado no Nginx:

```nginx
server {
    listen 443 ssl http2;
    server_name srv1113923.hstgr.cloud;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    # ... configurações
}
```

### Firewall

```bash
# Permitir apenas portas necessárias
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw enable
```

### Backups

Configure backups regulares:

```bash
# Script de backup automático
bash scripts/backup.sh
```

---

## 🔄 Rollback

Em caso de problemas, faça rollback para release anterior:

```bash
bash scripts/vps_rollback.sh
```

Ou manualmente:

```bash
cd /var/www/symplus
PREVIOUS_RELEASE=$(ls -1t releases | head -2 | tail -1)
ln -sfn releases/$PREVIOUS_RELEASE current
cd backend
docker compose -f docker-compose.prod.yml restart nginx
```

---

## 📊 Monitoramento

### Uptime

```bash
uptime
```

### Recursos

```bash
# CPU e Memória
htop

# Espaço em disco
df -h

# Uso de Docker
docker stats
```

### Logs de Aplicação

```bash
# Laravel logs
tail -f /var/www/symplus/backend/storage/logs/laravel.log

# Nginx access logs
tail -f /var/log/nginx/access.log

# Nginx error logs
tail -f /var/log/nginx/error.log
```

---

## 🐛 Troubleshooting

### App não carrega

1. Verificar se o build foi copiado:
   ```bash
   ls -la /var/www/symplus/backend/public/app/index.html
   ```

2. Verificar permissões:
   ```bash
   chown -R www-data:www-data /var/www/symplus/backend/public/app
   ```

3. Verificar Nginx:
   ```bash
   nginx -t
   systemctl reload nginx
   ```

### API não responde

1. Verificar containers:
   ```bash
   docker compose -f docker-compose.prod.yml ps
   ```

2. Verificar logs:
   ```bash
   docker compose -f docker-compose.prod.yml logs php
   ```

3. Verificar banco de dados:
   ```bash
   docker compose -f docker-compose.prod.yml exec db mysql -u symplus -psymplus symplus -e "SHOW TABLES;"
   ```

### Erro 500

1. Verificar logs do Laravel:
   ```bash
   docker compose -f docker-compose.prod.yml exec php tail -f storage/logs/laravel.log
   ```

2. Limpar cache:
   ```bash
   docker compose -f docker-compose.prod.yml exec php php artisan optimize:clear
   ```

---

## 📞 Suporte

Em caso de problemas:

1. Verificar logs
2. Consultar documentação: [DEPLOY.md](./DEPLOY.md)
3. Abrir issue no GitHub: https://github.com/WendeelMarinho/symplus/issues

---

**Última atualização**: 2025-11-24

