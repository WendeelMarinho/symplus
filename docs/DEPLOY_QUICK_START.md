# ⚡ Deploy Rápido - Guia Resumido

Este é um guia rápido para fazer deploy em VPS. Para detalhes completos, veja [DEPLOY_VPS.md](./DEPLOY_VPS.md).

## 🚀 Passos Rápidos

### 1. Preparar VPS

```bash
# Conectar na VPS
ssh root@seu-ip-vps

# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker

# Instalar Nginx e Certbot
sudo apt install -y nginx certbot python3-certbot-nginx

# Configurar firewall
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw enable
```

### 2. Clonar e Configurar

```bash
# Clonar repositório
cd /var/www
sudo git clone https://github.com/WendeelMarinho/symplus.git symplus
cd symplus/backend

# Configurar .env
cp env.example .env
nano .env  # Configure as variáveis (veja DEPLOY_VPS.md)

# Tornar scripts executáveis
chmod +x ../../scripts/*.sh
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

### 4. Configurar Nginx e SSL

```bash
# Criar configuração Nginx (copie de DEPLOY_VPS.md)
sudo nano /etc/nginx/sites-available/symplus-api
sudo ln -s /etc/nginx/sites-available/symplus-api /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# Obter SSL
sudo certbot --nginx -d api.symplus.dev
```

### 5. Configurar Horizon (Filas)

```bash
# Criar systemd service (veja DEPLOY_VPS.md)
sudo systemctl enable symplus-horizon
sudo systemctl start symplus-horizon
```

### 6. Configurar Backup Automático

```bash
# Adicionar ao crontab
sudo crontab -e
# Adicionar: 0 2 * * * /var/www/symplus/scripts/backup.sh
```

## 📝 Comandos Úteis

```bash
# Deploy (atualizar código)
/var/www/symplus/scripts/deploy.sh

# Backup manual
/var/www/symplus/scripts/backup.sh

# Restaurar backup
/var/www/symplus/scripts/restore.sh /var/backups/symplus/backup_completo_YYYYMMDD_HHMMSS.tar.gz

# Ver logs
docker compose -f docker-compose.prod.yml logs -f

# Reiniciar
docker compose -f docker-compose.prod.yml restart
```

## ✅ Checklist

- [ ] Docker instalado
- [ ] Nginx instalado
- [ ] Domínios apontando para IP da VPS
- [ ] .env configurado
- [ ] Containers rodando
- [ ] Migrations executadas
- [ ] SSL configurado
- [ ] Horizon rodando
- [ ] Backup automático configurado

## 🆘 Problemas?

Consulte a seção [Troubleshooting](./DEPLOY_VPS.md#-troubleshooting) no guia completo.

