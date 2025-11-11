# 🚀 Guia de Deploy em VPS - Symplus Finance

Este guia completo explica como fazer o deploy da aplicação Symplus Finance em uma VPS (Virtual Private Server).

## 📋 Índice

1. [Pré-requisitos](#pré-requisitos)
2. [Preparação da VPS](#preparação-da-vps)
3. [Configuração do Backend](#configuração-do-backend)
4. [Configuração do App Flutter](#configuração-do-app-flutter)
5. [SSL/HTTPS com Let's Encrypt](#sslhttps-com-lets-encrypt)
6. [Monitoramento e Manutenção](#monitoramento-e-manutenção)
7. [Backup e Restauração](#backup-e-restauração)
8. [Troubleshooting](#troubleshooting)

---

## 📦 Pré-requisitos

### Requisitos da VPS

- **Sistema Operacional**: Ubuntu 22.04 LTS (recomendado) ou 20.04 LTS
- **RAM**: Mínimo 2GB (recomendado 4GB+)
- **CPU**: Mínimo 2 cores
- **Disco**: Mínimo 20GB SSD
- **Rede**: IP público estático

### Software Necessário

- Docker 24.0+ e Docker Compose 2.20+
- Git
- Certbot (para SSL)
- Nginx (como proxy reverso)

### Domínios

- Domínio principal (ex: `symplus.dev`)
- Subdomínio para API (ex: `api.symplus.dev`)
- Subdomínio para app web (ex: `app.symplus.dev`)

---

## 🖥️ Preparação da VPS

### 1. Conectar na VPS

```bash
ssh root@seu-ip-vps
# ou
ssh usuario@seu-ip-vps
```

### 2. Atualizar o Sistema

```bash
sudo apt update && sudo apt upgrade -y
```

### 3. Instalar Docker e Docker Compose

```bash
# Instalar dependências
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Adicionar repositório Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalar Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Adicionar usuário ao grupo docker (se não for root)
sudo usermod -aG docker $USER
newgrp docker

# Verificar instalação
docker --version
docker compose version
```

### 4. Instalar Nginx (Proxy Reverso)

```bash
sudo apt install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx
```

### 5. Instalar Certbot (SSL)

```bash
sudo apt install -y certbot python3-certbot-nginx
```

### 6. Configurar Firewall

```bash
# UFW (Ubuntu Firewall)
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

### 7. Criar Usuário para Aplicação (Opcional, mas recomendado)

```bash
sudo adduser symplus
sudo usermod -aG docker symplus
sudo mkdir -p /var/www/symplus
sudo chown symplus:symplus /var/www/symplus
```

---

## 🔧 Configuração do Backend

### 1. Clonar o Repositório

```bash
cd /var/www
sudo git clone https://github.com/WendeelMarinho/symplus.git symplus
cd symplus/backend
```

### 2. Configurar Variáveis de Ambiente

```bash
cp env.example .env
nano .env
```

**Configurações importantes para produção:**

```env
APP_NAME=Symplus
APP_ENV=production
APP_KEY=  # Será gerado automaticamente
APP_DEBUG=false
APP_TIMEZONE=America/Sao_Paulo
APP_URL=https://api.symplus.dev

LOG_CHANNEL=stack
LOG_LEVEL=error  # Em produção, use 'error' ou 'warning'

DB_CONNECTION=mysql
DB_HOST=db
DB_PORT=3306
DB_DATABASE=symplus_prod
DB_USERNAME=symplus_user
DB_PASSWORD=senha_forte_aqui  # Use uma senha forte!

SESSION_DRIVER=redis
QUEUE_CONNECTION=redis
CACHE_STORE=redis

REDIS_HOST=redis
REDIS_PORT=6379

# MinIO/S3
AWS_ACCESS_KEY_ID=minioadmin_prod
AWS_SECRET_ACCESS_KEY=senha_forte_minio
AWS_BUCKET=symplus
AWS_ENDPOINT=http://minio:9000

# Stripe (configure suas chaves reais)
STRIPE_KEY=pk_live_...
STRIPE_SECRET=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Email (configure seu servidor SMTP)
MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=seu-email@gmail.com
MAIL_PASSWORD=sua-senha-app
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=noreply@symplus.dev
MAIL_FROM_NAME="Symplus Finance"
```

### 3. Usar Docker Compose de Produção

```bash
# Copiar arquivo de produção
cp docker-compose.yml docker-compose.prod.yml
# Ou use o arquivo docker-compose.prod.yml já configurado
```

### 4. Iniciar os Containers

```bash
docker compose -f docker-compose.prod.yml up -d
```

### 5. Instalar Dependências

```bash
docker compose -f docker-compose.prod.yml exec php composer install --optimize-autoloader --no-dev
```

### 6. Configurar Aplicação

```bash
# Gerar chave da aplicação
docker compose -f docker-compose.prod.yml exec php php artisan key:generate

# Executar migrations
docker compose -f docker-compose.prod.yml exec php php artisan migrate --force

# Criar link simbólico para storage
docker compose -f docker-compose.prod.yml exec php php artisan storage:link

# Limpar e otimizar cache
docker compose -f docker-compose.prod.yml exec php php artisan config:cache
docker compose -f docker-compose.prod.yml exec php php artisan route:cache
docker compose -f docker-compose.prod.yml exec php php artisan view:cache
```

### 7. Configurar Laravel Horizon (Filas)

```bash
# Criar supervisor ou systemd service para Horizon
# Veja seção de monitoramento abaixo
```

---

## 🌐 Configuração do Nginx (Proxy Reverso)

### 1. Criar Configuração para API

```bash
sudo nano /etc/nginx/sites-available/symplus-api
```

**Conteúdo:**

```nginx
server {
    listen 80;
    server_name api.symplus.dev;

    # Redirecionar para HTTPS (será configurado após SSL)
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.symplus.dev;

    # Certificados SSL (serão gerados pelo Certbot)
    ssl_certificate /etc/letsencrypt/live/api.symplus.dev/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.symplus.dev/privkey.pem;
    
    # Configurações SSL
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Logs
    access_log /var/log/nginx/symplus-api-access.log;
    error_log /var/log/nginx/symplus-api-error.log;

    # Tamanho máximo de upload
    client_max_body_size 50M;

    # Proxy para container Docker
    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Health check
    location /api/health {
        proxy_pass http://localhost:8000/api/health;
        access_log off;
    }
}
```

### 2. Habilitar Site

```bash
sudo ln -s /etc/nginx/sites-available/symplus-api /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 3. Configurar SSL com Let's Encrypt

```bash
# Obter certificado SSL
sudo certbot --nginx -d api.symplus.dev

# Renovação automática (já configurado por padrão)
sudo certbot renew --dry-run
```

---

## 📱 Configuração do App Flutter

### Opção 1: Deploy do App Web no Nginx

#### 1. Build do App Web

```bash
cd /var/www/symplus/app
flutter build web --release --web-renderer html
```

#### 2. Configurar Nginx para App Web

```bash
sudo nano /etc/nginx/sites-available/symplus-app
```

**Conteúdo:**

```nginx
server {
    listen 80;
    server_name app.symplus.dev;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name app.symplus.dev;

    ssl_certificate /etc/letsencrypt/live/app.symplus.dev/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/app.symplus.dev/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    root /var/www/symplus/app/build/web;
    index index.html;

    # Gzip
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # Cache para assets estáticos
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

#### 3. Habilitar e Configurar SSL

```bash
sudo ln -s /etc/nginx/sites-available/symplus-app /etc/nginx/sites-enabled/
sudo certbot --nginx -d app.symplus.dev
sudo nginx -t
sudo systemctl reload nginx
```

### Opção 2: Deploy em Vercel/Netlify (Recomendado)

Veja o arquivo `app/docs/SHARING_WEB_APP.md` para instruções detalhadas.

**Vantagens:**
- CDN global
- HTTPS automático
- Deploy automático via Git
- Melhor performance

---

## 🔒 SSL/HTTPS com Let's Encrypt

### Configuração Inicial

```bash
# Para cada domínio
sudo certbot --nginx -d api.symplus.dev
sudo certbot --nginx -d app.symplus.dev

# Verificar renovação automática
sudo certbot renew --dry-run
```

### Renovação Automática

O Certbot já configura renovação automática via cron. Verifique:

```bash
sudo systemctl status certbot.timer
```

---

## 📊 Monitoramento e Manutenção

### 1. Laravel Horizon (Filas)

Criar systemd service:

```bash
sudo nano /etc/systemd/system/symplus-horizon.service
```

**Conteúdo:**

```ini
[Unit]
Description=Symplus Horizon Queue Worker
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/var/www/symplus/backend
ExecStart=/usr/bin/docker compose -f docker-compose.prod.yml exec -T php php artisan horizon
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

**Ativar:**

```bash
sudo systemctl daemon-reload
sudo systemctl enable symplus-horizon
sudo systemctl start symplus-horizon
sudo systemctl status symplus-horizon
```

### 2. Logs

```bash
# Logs do Docker
docker compose -f docker-compose.prod.yml logs -f

# Logs do Laravel
tail -f /var/www/symplus/backend/storage/logs/laravel.log

# Logs do Nginx
sudo tail -f /var/log/nginx/symplus-api-error.log
```

### 3. Monitoramento de Recursos

```bash
# Uso de recursos
docker stats

# Espaço em disco
df -h
du -sh /var/www/symplus/*

# Memória
free -h
```

### 4. Comandos Úteis

```bash
# Reiniciar containers
docker compose -f docker-compose.prod.yml restart

# Atualizar código
cd /var/www/symplus
git pull
cd backend
docker compose -f docker-compose.prod.yml exec php composer install --optimize-autoloader --no-dev
docker compose -f docker-compose.prod.yml exec php php artisan migrate --force
docker compose -f docker-compose.prod.yml exec php php artisan config:cache
docker compose -f docker-compose.prod.yml exec php php artisan route:cache
docker compose -f docker-compose.prod.yml exec php php artisan view:cache

# Limpar cache
docker compose -f docker-compose.prod.yml exec php php artisan cache:clear
docker compose -f docker-compose.prod.yml exec php php artisan config:clear
docker compose -f docker-compose.prod.yml exec php php artisan route:clear
docker compose -f docker-compose.prod.yml exec php php artisan view:clear
```

---

## 💾 Backup e Restauração

### Script de Backup Automático

Criar script:

```bash
sudo nano /usr/local/bin/symplus-backup.sh
```

**Conteúdo:**

```bash
#!/bin/bash

BACKUP_DIR="/var/backups/symplus"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=7

mkdir -p $BACKUP_DIR

# Backup do banco de dados
docker compose -f /var/www/symplus/backend/docker-compose.prod.yml exec -T db mysqldump -u symplus_user -psenha_forte symplus_prod > $BACKUP_DIR/db_$DATE.sql

# Backup do storage
tar -czf $BACKUP_DIR/storage_$DATE.tar.gz -C /var/www/symplus/backend storage

# Backup do MinIO
docker compose -f /var/www/symplus/backend/docker-compose.prod.yml exec -T minio mc mirror /data $BACKUP_DIR/minio_$DATE/

# Compactar tudo
tar -czf $BACKUP_DIR/backup_$DATE.tar.gz -C $BACKUP_DIR db_$DATE.sql storage_$DATE.tar.gz minio_$DATE/

# Remover arquivos antigos
find $BACKUP_DIR -name "backup_*.tar.gz" -mtime +$RETENTION_DAYS -delete

echo "Backup concluído: backup_$DATE.tar.gz"
```

**Tornar executável e agendar:**

```bash
sudo chmod +x /usr/local/bin/symplus-backup.sh

# Adicionar ao crontab (backup diário às 2h da manhã)
sudo crontab -e
# Adicionar linha:
0 2 * * * /usr/local/bin/symplus-backup.sh
```

### Restauração

```bash
# Extrair backup
tar -xzf backup_YYYYMMDD_HHMMSS.tar.gz

# Restaurar banco
docker compose -f docker-compose.prod.yml exec -T db mysql -u symplus_user -psenha_forte symplus_prod < db_YYYYMMDD_HHMMSS.sql

# Restaurar storage
tar -xzf storage_YYYYMMDD_HHMMSS.tar.gz -C /var/www/symplus/backend
```

---

## 🔧 Troubleshooting

### Problemas Comuns

#### 1. Containers não iniciam

```bash
# Verificar logs
docker compose -f docker-compose.prod.yml logs

# Verificar se portas estão em uso
sudo netstat -tulpn | grep :8000
```

#### 2. Erro de permissões

```bash
# Corrigir permissões do storage
sudo chown -R www-data:www-data /var/www/symplus/backend/storage
sudo chmod -R 775 /var/www/symplus/backend/storage
```

#### 3. Erro de conexão com banco

```bash
# Verificar se container do banco está rodando
docker compose -f docker-compose.prod.yml ps

# Testar conexão
docker compose -f docker-compose.prod.yml exec db mysql -u symplus_user -p
```

#### 4. SSL não funciona

```bash
# Verificar certificados
sudo certbot certificates

# Renovar manualmente
sudo certbot renew
```

#### 5. App Flutter não conecta na API

- Verificar CORS no Laravel
- Verificar URL da API no `api_config.dart`
- Verificar se API está acessível via HTTPS

---

## ✅ Checklist de Deploy

- [ ] VPS configurada com Docker e Nginx
- [ ] Domínios apontando para IP da VPS
- [ ] SSL configurado para todos os domínios
- [ ] Variáveis de ambiente configuradas
- [ ] Banco de dados criado e migrations executadas
- [ ] Storage linkado e permissões corretas
- [ ] Cache otimizado (config, route, view)
- [ ] Laravel Horizon configurado e rodando
- [ ] Backup automático configurado
- [ ] Monitoramento configurado
- [ ] App Flutter buildado e deployado
- [ ] Testes de funcionalidades básicas

---

## 📚 Recursos Adicionais

- [Documentação Laravel Deployment](https://laravel.com/docs/deployment)
- [Docker Compose Production](https://docs.docker.com/compose/production/)
- [Nginx Best Practices](https://www.nginx.com/resources/wiki/start/topics/tutorials/config_pitfalls/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)

---

**🎉 Parabéns! Sua aplicação está em produção!**

Para suporte, abra uma issue no GitHub ou consulte a documentação em `docs/`.

