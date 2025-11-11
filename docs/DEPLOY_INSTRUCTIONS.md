# 🚀 Instruções Completas de Deploy - VPS

## ✅ Status Atual (Já Concluído)

- ✅ Sistema operacional configurado (Ubuntu 22.04 LTS)
- ✅ Docker e Docker Compose instalados
- ✅ Nginx instalado
- ✅ Certbot instalado
- ✅ Firewall configurado
- ✅ Repositório clonado na VPS
- ✅ Diretório do projeto: `/var/www/symplus`

## 📋 O Que Fazer Agora

Siga estes passos na ordem para finalizar o deploy da aplicação Symplus Finance.

---

## 1️⃣ Configurar o Backend Laravel

### 1.1. Navegar para o diretório do backend

```bash
cd /var/www/symplus/backend
```

### 1.2. Criar arquivo .env de produção

```bash
# Copiar arquivo de exemplo
cp env.example .env

# Editar o arquivo .env
nano .env
```

### 1.3. Configurar variáveis de ambiente

**IMPORTANTE:** Configure as seguintes variáveis no arquivo `.env`:

```env
# Aplicação
APP_NAME=Symplus
APP_ENV=production
APP_KEY=                    # Será gerado automaticamente depois
APP_DEBUG=false
APP_TIMEZONE=America/Sao_Paulo
APP_URL=https://api.SEU-DOMINIO.com    # ⚠️ SUBSTITUA SEU-DOMINIO.com pelo seu domínio real

# Logs (produção)
LOG_CHANNEL=stack
LOG_LEVEL=error

# Banco de dados
DB_CONNECTION=mysql
DB_HOST=db
DB_PORT=3306
DB_DATABASE=symplus_prod
DB_USERNAME=symplus_user
DB_PASSWORD=SUA_SENHA_FORTE_AQUI    # ⚠️ USE UMA SENHA FORTE!

# Sessão e Cache
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis
CACHE_STORE=redis

# Redis
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=null

# MinIO/S3 (armazenamento de arquivos)
AWS_ACCESS_KEY_ID=minioadmin_prod
AWS_SECRET_ACCESS_KEY=SUA_SENHA_FORTE_MINIO    # ⚠️ USE UMA SENHA FORTE!
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=symplus
AWS_USE_PATH_STYLE_ENDPOINT=true
AWS_ENDPOINT=http://minio:9000

# Stripe (billing) - Configure suas chaves reais
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
MAIL_FROM_ADDRESS=noreply@SEU-DOMINIO.com
MAIL_FROM_NAME="Symplus Finance"
```

**Salve o arquivo:** `Ctrl+X`, depois `Y`, depois `Enter`

### 1.4. Verificar se o arquivo docker-compose.prod.yml existe

```bash
ls -la docker-compose.prod.yml
```

Se não existir, copie do docker-compose.yml:

```bash
cp docker-compose.yml docker-compose.prod.yml
```

---

## 2️⃣ Iniciar os Containers Docker

### 2.1. Iniciar containers em modo detached (background)

```bash
docker compose -f docker-compose.prod.yml up -d
```

### 2.2. Verificar se os containers estão rodando

```bash
docker compose -f docker-compose.prod.yml ps
```

Você deve ver todos os containers com status "Up":
- symplus_php_prod
- symplus_nginx_prod
- symplus_mysql_prod
- symplus_redis_prod
- symplus_minio_prod

### 2.3. Ver logs (se houver problemas)

```bash
docker compose -f docker-compose.prod.yml logs
```

---

## 3️⃣ Instalar Dependências e Configurar Laravel

### 3.1. Instalar dependências do Composer (produção)

```bash
docker compose -f docker-compose.prod.yml exec php composer install --optimize-autoloader --no-dev
```

**Aguarde a instalação terminar** (pode levar alguns minutos)

### 3.2. Gerar chave da aplicação

```bash
docker compose -f docker-compose.prod.yml exec php php artisan key:generate
```

Isso preencherá automaticamente o `APP_KEY` no arquivo `.env`

### 3.3. Executar migrations do banco de dados

```bash
docker compose -f docker-compose.prod.yml exec php php artisan migrate --force
```

**Aguarde as migrations terminarem**

### 3.4. Criar link simbólico para storage

```bash
docker compose -f docker-compose.prod.yml exec php php artisan storage:link
```

### 3.5. Configurar permissões do storage

```bash
docker compose -f docker-compose.prod.yml exec php chown -R www-data:www-data storage bootstrap/cache
docker compose -f docker-compose.prod.yml exec php chmod -R 775 storage bootstrap/cache
```

### 3.6. Limpar e otimizar cache (IMPORTANTE para produção)

```bash
# Limpar cache
docker compose -f docker-compose.prod.yml exec php php artisan config:clear
docker compose -f docker-compose.prod.yml exec php php artisan route:clear
docker compose -f docker-compose.prod.yml exec php php artisan view:clear
docker compose -f docker-compose.prod.yml exec php php artisan cache:clear

# Recriar cache otimizado
docker compose -f docker-compose.prod.yml exec php php artisan config:cache
docker compose -f docker-compose.prod.yml exec php php artisan route:cache
docker compose -f docker-compose.prod.yml exec php php artisan view:cache
```

---

## 4️⃣ Testar a API Localmente

### 4.1. Verificar se a API está respondendo

```bash
curl http://localhost:8000/api/health
```

**Resposta esperada:**
```json
{"status":"ok","timestamp":"..."}
```

Se retornar isso, a API está funcionando! ✅

### 4.2. Verificar logs (se houver erro)

```bash
docker compose -f docker-compose.prod.yml logs php
docker compose -f docker-compose.prod.yml logs nginx
```

---

## 5️⃣ Configurar Nginx como Proxy Reverso

### 5.1. Criar configuração do Nginx

```bash
sudo nano /etc/nginx/sites-available/symplus-api
```

### 5.2. Adicionar configuração

**⚠️ IMPORTANTE:** Substitua `api.SEU-DOMINIO.com` pelo seu domínio real em TODOS os lugares.

```nginx
# Redirecionar HTTP para HTTPS
server {
    listen 80;
    server_name api.SEU-DOMINIO.com;    # ⚠️ SUBSTITUA SEU-DOMINIO.com

    # Permitir Let's Encrypt validation
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    # Redirecionar todo o resto para HTTPS
    location / {
        return 301 https://$server_name$request_uri;
    }
}

# Configuração HTTPS
server {
    listen 443 ssl http2;
    server_name api.SEU-DOMINIO.com;    # ⚠️ SUBSTITUA SEU-DOMINIO.com

    # Certificados SSL (serão gerados pelo Certbot)
    ssl_certificate /etc/letsencrypt/live/api.SEU-DOMINIO.com/fullchain.pem;    # ⚠️ SUBSTITUA
    ssl_certificate_key /etc/letsencrypt/live/api.SEU-DOMINIO.com/privkey.pem;  # ⚠️ SUBSTITUA
    
    # Configurações SSL modernas
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Logs
    access_log /var/log/nginx/symplus-api-access.log;
    error_log /var/log/nginx/symplus-api-error.log;

    # Tamanho máximo de upload (para documentos)
    client_max_body_size 50M;

    # Proxy para container Docker
    location / {
        proxy_pass http://127.0.0.1:8000;
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
        
        # Buffers
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        proxy_busy_buffers_size 8k;
    }

    # Health check (sem log)
    location /api/health {
        proxy_pass http://127.0.0.1:8000/api/health;
        access_log off;
    }
}
```

**Salve o arquivo:** `Ctrl+X`, depois `Y`, depois `Enter`

### 5.3. Habilitar o site

```bash
# Criar link simbólico
sudo ln -s /etc/nginx/sites-available/symplus-api /etc/nginx/sites-enabled/

# Testar configuração
sudo nginx -t
```

**Se aparecer "test is successful", continue. Se houver erro, corrija antes de prosseguir.**

### 5.4. Recarregar Nginx

```bash
sudo systemctl reload nginx
```

---

## 6️⃣ Configurar SSL com Let's Encrypt

### 6.1. Verificar DNS

**ANTES de obter SSL, certifique-se de que:**
- Seu domínio `api.SEU-DOMINIO.com` está apontando para o IP `72.61.6.135`
- A propagação DNS já ocorreu (pode levar alguns minutos)

**Verificar DNS:**
```bash
dig api.SEU-DOMINIO.com +short
# Deve retornar: 72.61.6.135
```

### 6.2. Obter certificado SSL

```bash
# Substitua api.SEU-DOMINIO.com pelo seu domínio real
sudo certbot --nginx -d api.SEU-DOMINIO.com
```

**Durante o processo, o Certbot irá:**
1. Validar o domínio
2. Obter o certificado
3. Configurar automaticamente o Nginx

**Siga as instruções na tela:**
- Digite seu email (para notificações de renovação)
- Aceite os termos
- Escolha se quer redirecionar HTTP para HTTPS (recomendado: 2)

### 6.3. Verificar certificado

```bash
sudo certbot certificates
```

### 6.4. Testar renovação automática

```bash
sudo certbot renew --dry-run
```

A renovação automática já está configurada por padrão.

---

## 7️⃣ Configurar Laravel Horizon (Filas)

### 7.1. Criar systemd service

```bash
sudo nano /etc/systemd/system/symplus-horizon.service
```

### 7.2. Adicionar configuração

```ini
[Unit]
Description=Symplus Horizon Queue Worker
After=network.target docker.service
Requires=docker.service

[Service]
Type=simple
User=www-data
WorkingDirectory=/var/www/symplus/backend
ExecStart=/usr/bin/docker compose -f docker-compose.prod.yml exec -T php php artisan horizon
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

**Salve o arquivo:** `Ctrl+X`, depois `Y`, depois `Enter`

### 7.3. Ativar e iniciar o serviço

```bash
# Recarregar systemd
sudo systemctl daemon-reload

# Habilitar para iniciar automaticamente
sudo systemctl enable symplus-horizon

# Iniciar o serviço
sudo systemctl start symplus-horizon

# Verificar status
sudo systemctl status symplus-horizon
```

**Se estiver "active (running)", está funcionando! ✅**

### 7.4. Ver logs do Horizon

```bash
sudo journalctl -u symplus-horizon -f
```

---

## 8️⃣ Configurar Backup Automático

### 8.1. Tornar script de backup executável

```bash
chmod +x /var/www/symplus/scripts/backup.sh
```

### 8.2. Testar backup manualmente

```bash
/var/www/symplus/scripts/backup.sh
```

**Verifique se o backup foi criado:**
```bash
ls -lh /var/backups/symplus/
```

### 8.3. Configurar backup automático (cron)

```bash
sudo crontab -e
```

**Adicione esta linha** (backup diário às 2h da manhã):

```
0 2 * * * /var/www/symplus/scripts/backup.sh >> /var/log/symplus-backup.log 2>&1
```

**Salve:** `Ctrl+X`, depois `Y`, depois `Enter`

---

## 9️⃣ Testes Finais

### 9.1. Testar API via HTTPS

```bash
# Testar health check
curl https://api.SEU-DOMINIO.com/api/health

# Resposta esperada:
# {"status":"ok","timestamp":"..."}
```

### 9.2. Verificar todos os serviços

```bash
# Containers Docker
docker compose -f /var/www/symplus/backend/docker-compose.prod.yml ps

# Nginx
sudo systemctl status nginx

# Horizon
sudo systemctl status symplus-horizon

# Certbot (renovação automática)
sudo systemctl status certbot.timer
```

### 9.3. Verificar logs

```bash
# Logs do Laravel
tail -f /var/www/symplus/backend/storage/logs/laravel.log

# Logs do Nginx
sudo tail -f /var/log/nginx/symplus-api-error.log

# Logs dos containers
docker compose -f /var/www/symplus/backend/docker-compose.prod.yml logs -f
```

---

## 🔟 Configurar CORS no Laravel (Importante!)

### 10.1. Editar configuração CORS

```bash
nano /var/www/symplus/backend/config/cors.php
```

### 10.2. Adicionar domínios permitidos

**Encontre a seção `allowed_origins` e adicione seus domínios:**

```php
'allowed_origins' => [
    'https://app.SEU-DOMINIO.com',        // App web Flutter
    'https://SEU-DOMINIO.com',            // Domínio principal (se houver)
    'http://localhost:8080',              // Desenvolvimento local
],
```

**Salve o arquivo**

### 10.3. Limpar cache novamente

```bash
docker compose -f /var/www/symplus/backend/docker-compose.prod.yml exec php php artisan config:clear
docker compose -f /var/www/symplus/backend/docker-compose.prod.yml exec php php artisan config:cache
```

---

## ✅ Checklist Final

Marque cada item conforme concluir:

- [ ] Arquivo `.env` configurado com valores de produção
- [ ] Containers Docker rodando
- [ ] Dependências do Composer instaladas
- [ ] Chave da aplicação gerada
- [ ] Migrations executadas
- [ ] Permissões do storage configuradas
- [ ] Cache otimizado
- [ ] API respondendo em `http://localhost:8000/api/health`
- [ ] Nginx configurado como proxy reverso
- [ ] SSL configurado e funcionando
- [ ] API acessível via HTTPS
- [ ] Laravel Horizon rodando
- [ ] Backup automático configurado
- [ ] CORS configurado
- [ ] Testes básicos realizados

---

## 🆘 Troubleshooting

### API não responde

```bash
# Verificar se containers estão rodando
docker compose -f /var/www/symplus/backend/docker-compose.prod.yml ps

# Ver logs
docker compose -f /var/www/symplus/backend/docker-compose.prod.yml logs php

# Verificar se porta 8000 está acessível
netstat -tulpn | grep 8000
```

### Erro de permissões

```bash
# Corrigir permissões
docker compose -f /var/www/symplus/backend/docker-compose.prod.yml exec php chown -R www-data:www-data storage bootstrap/cache
docker compose -f /var/www/symplus/backend/docker-compose.prod.yml exec php chmod -R 775 storage bootstrap/cache
```

### SSL não funciona

1. Verifique DNS: `dig api.SEU-DOMINIO.com`
2. Verifique se porta 80 está aberta: `sudo ufw status`
3. Tente obter SSL novamente: `sudo certbot --nginx -d api.SEU-DOMINIO.com`

### Horizon não inicia

```bash
# Ver logs
sudo journalctl -u symplus-horizon -n 50

# Verificar se containers estão rodando
docker compose -f /var/www/symplus/backend/docker-compose.prod.yml ps

# Reiniciar serviço
sudo systemctl restart symplus-horizon
```

### Banco de dados não conecta

```bash
# Verificar se container do banco está rodando
docker compose -f /var/www/symplus/backend/docker-compose.prod.yml ps db

# Testar conexão
docker compose -f /var/www/symplus/backend/docker-compose.prod.yml exec db mysql -u symplus_user -p
```

---

## 📝 Comandos Úteis

### Atualizar código (deploy)

```bash
cd /var/www/symplus
git pull
cd backend
./scripts/deploy.sh
```

### Ver status de tudo

```bash
# Containers
docker compose -f /var/www/symplus/backend/docker-compose.prod.yml ps

# Serviços
sudo systemctl status nginx
sudo systemctl status symplus-horizon

# Uso de recursos
htop
docker stats
```

### Reiniciar tudo

```bash
# Reiniciar containers
docker compose -f /var/www/symplus/backend/docker-compose.prod.yml restart

# Reiniciar Nginx
sudo systemctl restart nginx

# Reiniciar Horizon
sudo systemctl restart symplus-horizon
```

---

## 🎉 Pronto!

Sua aplicação está em produção! 

**URL da API:** `https://api.SEU-DOMINIO.com`

**Próximos passos:**
1. Configure o app Flutter para apontar para esta API
2. Teste todas as funcionalidades
3. Configure monitoramento (opcional)
4. Configure alertas (opcional)

Para mais informações, consulte:
- `docs/DEPLOY_VPS.md` - Guia completo
- `scripts/README.md` - Documentação dos scripts

