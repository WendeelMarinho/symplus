#!/bin/bash

# Script de Setup Inicial para VPS
# Uso: Execute este script na VPS como root
# ssh root@72.61.6.135
# curl -fsSL https://raw.githubusercontent.com/WendeelMarinho/symplus/main/scripts/vps-setup.sh | bash
# OU
# wget -O - https://raw.githubusercontent.com/WendeelMarinho/symplus/main/scripts/vps-setup.sh | bash

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Configurando VPS para Symplus Finance...${NC}"
echo ""

# Verificar se é root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ Por favor, execute como root${NC}"
    exit 1
fi

# Informações do VPS
VPS_IP="72.61.6.135"
VPS_HOSTNAME="srv1113923.hstgr.cloud"
PROJECT_DIR="/var/www/symplus"
BACKEND_DIR="$PROJECT_DIR/backend"

echo -e "${GREEN}✅ Executando como root${NC}"

# 1. Atualizar sistema
echo -e "${BLUE}📦 Atualizando sistema...${NC}"
export DEBIAN_FRONTEND=noninteractive
apt update && apt upgrade -y

# 2. Instalar dependências básicas
echo -e "${BLUE}📦 Instalando dependências básicas...${NC}"
apt install -y \
    curl \
    wget \
    git \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    ufw \
    htop \
    nano \
    vim

# 3. Instalar Docker
echo -e "${BLUE}🐳 Instalando Docker...${NC}"
if ! command -v docker &> /dev/null; then
    # Adicionar repositório Docker
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Iniciar e habilitar Docker
    systemctl enable docker
    systemctl start docker
    
    echo -e "${GREEN}✅ Docker instalado${NC}"
else
    echo -e "${YELLOW}⚠️  Docker já está instalado${NC}"
fi

# 4. Instalar Nginx
echo -e "${BLUE}🌐 Instalando Nginx...${NC}"
if ! command -v nginx &> /dev/null; then
    apt install -y nginx
    systemctl enable nginx
    systemctl start nginx
    echo -e "${GREEN}✅ Nginx instalado${NC}"
else
    echo -e "${YELLOW}⚠️  Nginx já está instalado${NC}"
fi

# 5. Instalar Certbot
echo -e "${BLUE}🔒 Instalando Certbot (SSL)...${NC}"
if ! command -v certbot &> /dev/null; then
    apt install -y certbot python3-certbot-nginx
    echo -e "${GREEN}✅ Certbot instalado${NC}"
else
    echo -e "${YELLOW}⚠️  Certbot já está instalado${NC}"
fi

# 6. Configurar Firewall
echo -e "${BLUE}🔥 Configurando firewall (UFW)...${NC}"
ufw --force enable
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw allow 80/tcp
ufw allow 443/tcp
echo -e "${GREEN}✅ Firewall configurado${NC}"

# 7. Criar diretório do projeto
echo -e "${BLUE}📁 Criando diretórios...${NC}"
mkdir -p $PROJECT_DIR
mkdir -p /var/backups/symplus
echo -e "${GREEN}✅ Diretórios criados${NC}"

# 8. Criar usuário symplus (opcional, mas recomendado)
echo -e "${BLUE}👤 Criando usuário symplus...${NC}"
if ! id "symplus" &>/dev/null; then
    useradd -m -s /bin/bash symplus
    usermod -aG docker symplus
    chown -R symplus:symplus $PROJECT_DIR
    echo -e "${GREEN}✅ Usuário symplus criado${NC}"
    echo -e "${YELLOW}⚠️  Para usar o usuário symplus, execute: su - symplus${NC}"
else
    echo -e "${YELLOW}⚠️  Usuário symplus já existe${NC}"
fi

# 9. Configurar hostname (opcional)
echo -e "${BLUE}🏷️  Configurando hostname...${NC}"
hostnamectl set-hostname $VPS_HOSTNAME
echo -e "${GREEN}✅ Hostname configurado${NC}"

# 10. Instalar ferramentas úteis
echo -e "${BLUE}🛠️  Instalando ferramentas úteis...${NC}"
apt install -y \
    fail2ban \
    logrotate \
    unattended-upgrades

# Configurar fail2ban
systemctl enable fail2ban
systemctl start fail2ban

# Configurar atualizações automáticas
echo 'Unattended-Upgrade::Automatic-Reboot "false";' >> /etc/apt/apt.conf.d/50unattended-upgrades
echo 'Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";' >> /etc/apt/apt.conf.d/50unattended-upgrades

echo -e "${GREEN}✅ Ferramentas instaladas${NC}"

# 11. Verificar instalações
echo ""
echo -e "${BLUE}🔍 Verificando instalações...${NC}"
echo ""

# Docker
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    echo -e "${GREEN}✅ Docker: $DOCKER_VERSION${NC}"
else
    echo -e "${RED}❌ Docker não instalado${NC}"
fi

# Docker Compose
if command -v docker compose &> /dev/null; then
    COMPOSE_VERSION=$(docker compose version)
    echo -e "${GREEN}✅ Docker Compose: $COMPOSE_VERSION${NC}"
else
    echo -e "${RED}❌ Docker Compose não instalado${NC}"
fi

# Nginx
if command -v nginx &> /dev/null; then
    NGINX_VERSION=$(nginx -v 2>&1)
    echo -e "${GREEN}✅ Nginx: $NGINX_VERSION${NC}"
else
    echo -e "${RED}❌ Nginx não instalado${NC}"
fi

# Certbot
if command -v certbot &> /dev/null; then
    CERTBOT_VERSION=$(certbot --version)
    echo -e "${GREEN}✅ Certbot: $CERTBOT_VERSION${NC}"
else
    echo -e "${RED}❌ Certbot não instalado${NC}"
fi

# 12. Exibir informações finais
echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Setup concluído com sucesso!${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}📋 Informações do VPS:${NC}"
echo "  IP: $VPS_IP"
echo "  Hostname: $VPS_HOSTNAME"
echo "  Diretório do projeto: $PROJECT_DIR"
echo ""
echo -e "${BLUE}📝 Próximos passos:${NC}"
echo ""
echo "1. Clonar o repositório:"
echo "   cd /var/www"
echo "   git clone https://github.com/WendeelMarinho/symplus.git symplus"
echo ""
echo "2. Configurar o backend:"
echo "   cd $BACKEND_DIR"
echo "   cp env.example .env"
echo "   nano .env  # Configure as variáveis"
echo ""
echo "3. Iniciar os containers:"
echo "   docker compose -f docker-compose.prod.yml up -d"
echo ""
echo "4. Instalar dependências e configurar:"
echo "   docker compose -f docker-compose.prod.yml exec php composer install --optimize-autoloader --no-dev"
echo "   docker compose -f docker-compose.prod.yml exec php php artisan key:generate"
echo "   docker compose -f docker-compose.prod.yml exec php php artisan migrate --force"
echo ""
echo "5. Configurar Nginx e SSL:"
echo "   Consulte: docs/DEPLOY_VPS.md"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANTE:${NC}"
echo "  - Configure seus domínios para apontar para: $VPS_IP"
echo "  - Configure o arquivo .env com valores de produção"
echo "  - Use senhas fortes para banco de dados e MinIO"
echo ""
echo -e "${GREEN}🎉 VPS pronto para deploy!${NC}"

