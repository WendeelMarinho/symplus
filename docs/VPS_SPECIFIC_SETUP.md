# 🖥️ Setup Específico para seu VPS

Este guia é específico para seu VPS. Use-o como referência rápida.

## 📋 Informações do VPS

- **IP**: `72.61.6.135`
- **Hostname**: `srv1113923.hstgr.cloud`
- **Localização**: United States - Boston
- **SO**: Ubuntu 22.04 LTS
- **Usuário SSH**: `root`

## 🚀 Setup Inicial Rápido

### Opção 1: Script Automatizado (Recomendado)

Execute o script de setup diretamente na VPS:

```bash
# Conectar na VPS
ssh root@72.61.6.135

# Executar script de setup
cd /tmp
wget https://raw.githubusercontent.com/WendeelMarinho/symplus/main/scripts/vps-setup.sh
chmod +x vps-setup.sh
./vps-setup.sh
```

OU execute diretamente:

```bash
curl -fsSL https://raw.githubusercontent.com/WendeelMarinho/symplus/main/scripts/vps-setup.sh | bash
```

### Opção 2: Setup Manual

Siga os passos do [Guia Completo de Deploy](DEPLOY_VPS.md).

## 📝 Passos Após Setup

### 1. Clonar Repositório

```bash
cd /var/www
git clone https://github.com/WendeelMarinho/symplus.git symplus
cd symplus/backend
```

### 2. Configurar Variáveis de Ambiente

```bash
cp env.example .env
nano .env
```

**Configurações importantes:**

```env
APP_ENV=production
APP_DEBUG=false
APP_URL=https://api.seu-dominio.com

DB_DATABASE=symplus_prod
DB_USERNAME=symplus_user
DB_PASSWORD=senha_forte_aqui

# MinIO
MINIO_ROOT_USER=minioadmin_prod
MINIO_ROOT_PASSWORD=senha_forte_minio

# Stripe (configure suas chaves reais)
STRIPE_KEY=pk_live_...
STRIPE_SECRET=sk_live_...

# Email
MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=seu-email@gmail.com
MAIL_PASSWORD=sua-senha-app
MAIL_ENCRYPTION=tls
```

### 3. Iniciar Aplicação

```bash
# Iniciar containers
docker compose -f docker-compose.prod.yml up -d

# Instalar dependências
docker compose -f docker-compose.prod.yml exec php composer install --optimize-autoloader --no-dev

# Configurar aplicação
docker compose -f docker-compose.prod.yml exec php php artisan key:generate
docker compose -f docker-compose.prod.yml exec php php artisan migrate --force
docker compose -f docker-compose.prod.yml exec php php artisan storage:link
docker compose -f docker-compose.prod.yml exec php php artisan config:cache
docker compose -f docker-compose.prod.yml exec php php artisan route:cache
docker compose -f docker-compose.prod.yml exec php php artisan view:cache
```

### 4. Configurar Nginx

Crie o arquivo de configuração:

```bash
sudo nano /etc/nginx/sites-available/symplus-api
```

**Conteúdo (substitua `api.seu-dominio.com` pelo seu domínio):**

```nginx
server {
    listen 80;
    server_name api.seu-dominio.com;

    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.seu-dominio.com;

    ssl_certificate /etc/letsencrypt/live/api.seu-dominio.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.seu-dominio.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    access_log /var/log/nginx/symplus-api-access.log;
    error_log /var/log/nginx/symplus-api-error.log;

    client_max_body_size 50M;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
        
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    location /api/health {
        proxy_pass http://127.0.0.1:8000/api/health;
        access_log off;
    }
}
```

Habilitar site:

```bash
sudo ln -s /etc/nginx/sites-available/symplus-api /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 5. Configurar SSL

**IMPORTANTE:** Configure seus domínios para apontar para `72.61.6.135` antes de obter o SSL.

```bash
# Obter certificado SSL
sudo certbot --nginx -d api.seu-dominio.com

# Testar renovação automática
sudo certbot renew --dry-run
```

### 6. Configurar Laravel Horizon

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

Ativar:

```bash
sudo systemctl daemon-reload
sudo systemctl enable symplus-horizon
sudo systemctl start symplus-horizon
sudo systemctl status symplus-horizon
```

### 7. Configurar Backup Automático

```bash
# Tornar script executável
chmod +x /var/www/symplus/scripts/backup.sh

# Adicionar ao crontab
sudo crontab -e
```

Adicionar linha (backup diário às 2h):

```
0 2 * * * /var/www/symplus/scripts/backup.sh >> /var/log/symplus-backup.log 2>&1
```

## 🔧 Comandos Úteis

### Verificar Status

```bash
# Status dos containers
docker compose -f /var/www/symplus/backend/docker-compose.prod.yml ps

# Logs
docker compose -f /var/www/symplus/backend/docker-compose.prod.yml logs -f

# Status do Horizon
sudo systemctl status symplus-horizon

# Uso de recursos
htop
docker stats
```

### Deploy (Atualizar Código)

```bash
cd /var/www/symplus
./scripts/deploy.sh
```

### Backup Manual

```bash
/var/www/symplus/scripts/backup.sh
```

## 🌐 Configuração de DNS

Configure seus domínios para apontar para o IP da VPS:

```
Tipo    Nome                    Valor
A       api.seu-dominio.com     72.61.6.135
A       app.seu-dominio.com     72.61.6.135
```

**Aguarde a propagação DNS (pode levar até 24h, geralmente alguns minutos).**

## ✅ Checklist de Deploy

- [ ] Script de setup executado
- [ ] Repositório clonado
- [ ] Arquivo .env configurado
- [ ] Containers rodando
- [ ] Migrations executadas
- [ ] DNS configurado e propagado
- [ ] Nginx configurado
- [ ] SSL obtido e funcionando
- [ ] Horizon rodando
- [ ] Backup automático configurado
- [ ] Testes de funcionalidades básicas

## 🆘 Troubleshooting

### Não consigo conectar via SSH

```bash
# Verificar se porta SSH está aberta
sudo ufw status
sudo ufw allow OpenSSH
```

### Containers não iniciam

```bash
# Verificar logs
docker compose -f /var/www/symplus/backend/docker-compose.prod.yml logs

# Verificar espaço em disco
df -h

# Verificar memória
free -h
```

### SSL não funciona

1. Verifique se DNS está propagado: `dig api.seu-dominio.com`
2. Verifique se porta 80 está aberta: `sudo ufw allow 80/tcp`
3. Tente obter SSL novamente: `sudo certbot --nginx -d api.seu-dominio.com`

### Erro de permissões

```bash
sudo chown -R www-data:www-data /var/www/symplus/backend/storage
sudo chmod -R 775 /var/www/symplus/backend/storage
```

## 📞 Suporte

Para mais detalhes, consulte:
- [Guia Completo de Deploy](DEPLOY_VPS.md)
- [Guia Rápido](DEPLOY_QUICK_START.md)
- [Documentação dos Scripts](../scripts/README.md)

---

**🎉 Boa sorte com o deploy!**

