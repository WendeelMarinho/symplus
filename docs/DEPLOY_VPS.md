# 🚀 Guia de Deploy em VPS - Symplus Finance

Este guia descreve o processo completo de deploy da aplicação Symplus Finance em uma VPS usando estratégia de releases com zero-downtime.

## 📋 Índice

- [Pré-requisitos](#pré-requisitos)
- [Estrutura de Diretórios](#estrutura-de-diretórios)
- [Preparação Inicial](#preparação-inicial)
- [Deploy Automatizado](#deploy-automatizado)
- [Deploy Manual](#deploy-manual)
- [Rollback](#rollback)
- [Troubleshooting](#troubleshooting)
- [GitHub Actions (CI/CD)](#github-actions-cicd)

---

## 📦 Pré-requisitos

### Na VPS (Ubuntu)

- **Docker** e **Docker Compose** instalados
- **Git** instalado
- **curl** instalado
- Usuário com permissões sudo (ou root)
- SSH key configurada para acesso ao GitHub (ou token)
- Portas 80, 443, 8000 abertas no firewall

### Verificar Instalação

```bash
# Docker
docker --version
docker compose version

# Git
git --version

# curl
curl --version
```

### Usuário e Permissões

O deploy assume que você está rodando como usuário com UID/GID **1001:1001** (ou configure `HOST_UID`/`HOST_GID`).

Verificar:
```bash
id -u  # Deve retornar 1001 (ou seu UID)
id -g  # Deve retornar 1001 (ou seu GID)
```

---

## 📁 Estrutura de Diretórios

Após o primeiro deploy, a estrutura será:

```
/var/www/symplus/
├── current -> releases/20251111120000/  # Symlink para release ativa
├── releases/                             # Histórico de releases
│   ├── 20251111120000/                   # Release 1
│   ├── 20251111130000/                   # Release 2
│   └── 20251111140000/                   # Release 3 (ativa)
├── shared/                                # Dados persistentes
│   └── backend/
│       ├── .env                          # Configurações (NÃO commitado)
│       └── storage/                      # Storage Laravel (persistente)
└── scripts/                               # Scripts de deploy
    ├── vps_deploy.sh
    └── vps_rollback.sh
```

### Por que essa estrutura?

- **`releases/`**: Cada deploy cria uma nova pasta com timestamp
- **`current/`**: Symlink apontando para release ativa (zero-downtime)
- **`shared/`**: Dados que persistem entre deploys (.env, storage)

---

## 🔧 Preparação Inicial

### 1. Criar Estrutura de Diretórios

```bash
sudo mkdir -p /var/www/symplus/{releases,shared/backend,scripts}
sudo chown -R 1001:1001 /var/www/symplus
```

### 2. Configurar Shared (.env e storage)

#### Primeira vez - Copiar .env

```bash
# Se já existe um .env em produção, movê-lo para shared
sudo mv /var/www/symplus/backend/.env /var/www/symplus/shared/backend/.env

# OU criar novo a partir do exemplo
cd /var/www/symplus
git clone https://github.com/WendeelMarinho/symplus.git temp_clone
cp temp_clone/backend/.env.example /var/www/symplus/shared/backend/.env
rm -rf temp_clone

# Editar .env
nano /var/www/symplus/shared/backend/.env
```

**Configure as variáveis importantes:**
- `APP_ENV=production`
- `APP_DEBUG=false`
- `APP_URL=https://seu-dominio.com`
- `DB_*` (credenciais do banco)
- `REDIS_*` (se aplicável)
- `AWS_*` (MinIO/S3)

#### Mover Storage (se já existe)

```bash
# Se já existe storage em produção
sudo mv /var/www/symplus/backend/storage /var/www/symplus/shared/backend/storage

# OU criar estrutura vazia
sudo mkdir -p /var/www/symplus/shared/backend/storage/{framework/{cache,sessions,views},logs,app/public}
sudo chown -R 1001:1001 /var/www/symplus/shared/backend/storage
sudo chmod -R 775 /var/www/symplus/shared/backend/storage
```

### 3. Configurar SSH Key para GitHub (Opcional)

Se o repositório for privado ou você quiser usar SSH:

```bash
# Gerar chave SSH (se não tiver)
ssh-keygen -t ed25519 -C "vps-deploy@symplus" -f ~/.ssh/github_symplus

# Adicionar chave pública ao GitHub
cat ~/.ssh/github_symplus.pub
# Copie e adicione em: https://github.com/settings/keys

# Testar conexão
ssh -T git@github.com
```

### 4. Clonar Scripts de Deploy

```bash
cd /var/www/symplus
git clone https://github.com/WendeelMarinho/symplus.git temp_clone
cp temp_clone/scripts/vps_deploy.sh scripts/
cp temp_clone/scripts/vps_rollback.sh scripts/
chmod +x scripts/*.sh
rm -rf temp_clone
```

---

## 🚀 Deploy Automatizado

### Via GitHub Actions (Recomendado)

O workflow `.github/workflows/deploy.yml` executa automaticamente em push na branch `main`.

**Configurar secrets no GitHub:**
- `VPS_HOST`: IP ou domínio da VPS
- `VPS_USER`: Usuário SSH (ex: `root`)
- `VPS_SSH_KEY`: Chave SSH privada para acesso à VPS

### Via SSH Remoto

Execute o deploy de sua máquina local:

```bash
export VPS_HOST="srv1113923.hstgr.cloud"
export VPS_USER="root"
export VPS_PATH="/var/www/symplus"
export GIT_REPO="https://github.com/WendeelMarinho/symplus.git"
export BRANCH="main"
export DOMAIN_HEALTHCHECK="https://srv1113923.hstgr.cloud/api/health"

# Executar deploy
ssh ${VPS_USER}@${VPS_HOST} "bash -s" < scripts/vps_deploy.sh
```

---

## 🖥️ Deploy Manual (Na VPS)

Execute diretamente na VPS:

```bash
cd /var/www/symplus

# Configurar variáveis
export VPS_PATH="/var/www/symplus"
export GIT_REPO="https://github.com/WendeelMarinho/symplus.git"
export BRANCH="main"
export DOMAIN_HEALTHCHECK="https://srv1113923.hstgr.cloud/api/health"

# Executar deploy
bash scripts/vps_deploy.sh
```

### O que o script faz?

1. ✅ Valida pré-requisitos (git, docker, curl)
2. ✅ Cria estrutura de diretórios
3. ✅ Clona código do GitHub para nova release
4. ✅ Configura symlinks para `.env` e `storage` (shared)
5. ✅ Configura permissões (UID/GID 1001:1001)
6. ✅ Faz pull de imagens Docker
7. ✅ Build e inicia containers
8. ✅ Executa migrations do Laravel
9. ✅ Otimiza aplicação (cache, routes)
10. ✅ Reinicia filas/Horizon
11. ✅ Healthcheck da aplicação
12. ✅ Ativa nova release (atualiza symlink `current`)
13. ✅ Limpa releases antigas (mantém últimas 5)

---

## 🔄 Rollback

Se algo der errado no deploy, reverta para a release anterior:

### Rollback Manual

```bash
cd /var/www/symplus

export VPS_PATH="/var/www/symplus"
export DOMAIN_HEALTHCHECK="https://srv1113923.hstgr.cloud/api/health"

# Executar rollback
bash scripts/vps_rollback.sh
```

### O que o rollback faz?

1. ✅ Identifica release atual
2. ✅ Encontra release anterior (mais recente)
3. ✅ Atualiza symlink `current` para release anterior
4. ✅ Reinicia containers na release anterior
5. ✅ Healthcheck rápido
6. ✅ Mantém release que falhou para análise

**Nota:** A release que falhou não é removida, permitindo análise posterior.

---

## 🌐 Nginx + PHP-FPM

### Configuração

O Nginx está configurado para:
- Servir arquivos estáticos do diretório `public/`
- Encaminhar requisições PHP para `php:9000` (PHP-FPM)
- Tratar rotas `/api/*` com suporte a CORS preflight
- Usar `try_files` para rotear todas as requisições para `index.php` (Laravel)

**Arquivo de configuração:** `backend/nginx/default.conf`

**Principais diretivas:**
- `root /var/www/symplus/backend/public` - Diretório raiz do Laravel
- `fastcgi_pass php:9000` - Conecta ao serviço PHP-FPM via Docker network
- `location ^~ /api/` - Trata rotas de API com CORS preflight
- `try_files $uri $uri/ /index.php?$query_string` - Roteamento Laravel

**Verificar configuração:**
```bash
# Testar sintaxe Nginx
docker compose -f docker-compose.prod.yml exec nginx nginx -t

# Ver logs do Nginx
docker compose -f docker-compose.prod.yml logs nginx --tail 50

# Verificar se PHP-FPM está acessível
docker compose -f docker-compose.prod.yml exec nginx ping -c 2 php
```

---

## 🔍 Troubleshooting

### Problema: Permissões (Permission denied)

**Sintoma:** Erros de escrita em `storage/` ou `bootstrap/cache/`

**Solução:**
```bash
# Verificar UID/GID
id -u  # Deve ser 1001
id -g  # Deve ser 1001

# Ajustar permissões manualmente
sudo chown -R 1001:1001 /var/www/symplus/shared/backend/storage
sudo chmod -R 775 /var/www/symplus/shared/backend/storage

# Se necessário, aplicar ACL
cd /var/www/symplus/current/backend
make fixperm
```

### Problema: Healthcheck falha

**Sintoma:** Script para com erro "Healthcheck falhou"

**Solução:**
```bash
# Verificar logs dos containers
cd /var/www/symplus/current/backend
docker compose -f docker-compose.prod.yml logs php
docker compose -f docker-compose.prod.yml logs nginx

# Verificar se containers estão rodando
docker compose -f docker-compose.prod.yml ps

# Testar manualmente
curl -v https://seu-dominio.com/api/health

# Se necessário, fazer rollback
bash scripts/vps_rollback.sh
```

### Problema: Migrations falham

**Sintoma:** Erro ao executar `php artisan migrate`

**Solução:**
```bash
# Verificar conexão com banco
cd /var/www/symplus/current/backend
docker compose -f docker-compose.prod.yml exec php php artisan tinker
>>> DB::connection()->getPdo();

# Verificar .env
cat /var/www/symplus/shared/backend/.env | grep DB_

# Executar migrations manualmente
docker compose -f docker-compose.prod.yml exec php php artisan migrate --force
```

### Problema: CORS errors

**Sintoma:** Erros de CORS no frontend (Flutter Web)

**Solução:**
```bash
# Verificar config/cors.php
cat /var/www/symplus/current/backend/config/cors.php

# Verificar CorsMiddleware
cat /var/www/symplus/current/backend/app/Http/Middleware/CorsMiddleware.php

# Verificar Nginx (deve tratar OPTIONS)
cat /var/www/symplus/current/backend/nginx/default.conf | grep -A 10 "location.*api"

# Limpar cache
cd /var/www/symplus/current/backend
docker compose -f docker-compose.prod.yml exec php php artisan config:clear
docker compose -f docker-compose.prod.yml exec php php artisan route:clear
docker compose -f docker-compose.prod.yml exec php php artisan config:cache
docker compose -f docker-compose.prod.yml exec php php artisan route:cache

# Reiniciar Nginx
docker compose -f docker-compose.prod.yml restart nginx

# Testar CORS manualmente
curl -v -X OPTIONS http://localhost:8000/api/health \
  -H "Origin: http://localhost:33337" \
  -H "Access-Control-Request-Method: GET"
```

**CORS para Flutter Web:**

O sistema está configurado para aceitar requisições de:
- `http://localhost:*` (qualquer porta)
- `http://127.0.0.1:*` (qualquer porta)
- `https://srv1113923.hstgr.cloud`
- Domínios `*.hstgr.cloud`

O Nginx trata requisições OPTIONS (preflight) diretamente, retornando 204 com headers CORS apropriados. O Laravel também aplica headers CORS via `CorsMiddleware` em todas as respostas da API.

**Verificar CORS funcionando:**
```bash
# Testar preflight
curl -v -X OPTIONS http://localhost:8000/api/auth/login \
  -H "Origin: http://localhost:33337" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type"

# Deve retornar:
# HTTP/1.1 204 No Content
# Access-Control-Allow-Origin: http://localhost:33337
# Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS
# Access-Control-Allow-Headers: Authorization,Content-Type,Accept,Origin,X-Requested-With,X-Organization-Id
# Access-Control-Allow-Credentials: true
```

### Problema: Cache Laravel não atualiza

**Sintoma:** Mudanças não aparecem após deploy

**Solução:**
```bash
cd /var/www/symplus/current/backend
docker compose -f docker-compose.prod.yml exec php php artisan optimize:clear
docker compose -f docker-compose.prod.yml exec php php artisan optimize
```

### Problema: Containers não iniciam

**Sintoma:** `docker compose up -d` falha

**Solução:**
```bash
# Verificar logs
cd /var/www/symplus/current/backend
docker compose -f docker-compose.prod.yml logs

# Verificar docker-compose.prod.yml
cat docker-compose.prod.yml

# Verificar se portas estão em uso
sudo netstat -tulpn | grep -E '8000|3306|6379'

# Rebuild forçado
docker compose -f docker-compose.prod.yml up -d --build --force-recreate
```

---

## 🔐 Segurança

### .env não é commitado

O arquivo `.env` fica em `/var/www/symplus/shared/backend/.env` e **nunca** é sobrescrito pelo deploy.

### Releases antigas

Releases antigas são mantidas por segurança (últimas 5). Para limpar manualmente:

```bash
# Listar releases
ls -1t /var/www/symplus/releases

# Remover release específica (cuidado!)
rm -rf /var/www/symplus/releases/20251111120000
```

### Logs

Logs do deploy são exibidos no console. Para salvar:

```bash
bash scripts/vps_deploy.sh 2>&1 | tee deploy_$(date +%Y%m%d_%H%M%S).log
```

---

## 📊 Monitoramento

### Verificar Release Ativa

```bash
ls -la /var/www/symplus/current
readlink -f /var/www/symplus/current
```

### Listar Releases Disponíveis

```bash
ls -1t /var/www/symplus/releases
```

### Status dos Containers

```bash
cd /var/www/symplus/current/backend
docker compose -f docker-compose.prod.yml ps
```

### Healthcheck Manual

```bash
curl -f https://seu-dominio.com/api/health
```

### Validação Rápida da Stack

Execute o script de validação para verificar se todos os componentes estão funcionando:

```bash
cd /var/www/symplus/current/backend
./scripts/check_stack.sh
```

O script verifica:
1. ✅ Nginx respondendo em `http://localhost:8000`
2. ✅ Rota `/api/health` retornando HTTP 200 com JSON válido
3. ✅ PHP e Laravel funcionando (rotas registradas)
4. ✅ Redis resolvendo via DNS (`redis`) e acessível na porta 6379
5. ✅ CORS funcionando (OPTIONS preflight retorna 204/200)
6. ✅ Containers Docker rodando

**Comandos manuais de validação:**

```bash
# Testar Nginx
curl -sS -D- http://localhost:8000/ | head -n 15

# Testar /api/health
curl -sS -D- http://localhost:8000/api/health | head -n 15

# Verificar rotas Laravel
docker compose -f docker-compose.prod.yml exec php php artisan route:list | grep -c /api/health

# Verificar Redis DNS
docker compose -f docker-compose.prod.yml exec php php -r "echo gethostbyname('redis'), PHP_EOL;"

# Testar conexão Redis
docker compose -f docker-compose.prod.yml exec php nc -zv redis 6379
```

---

## 🤖 GitHub Actions (CI/CD)

O workflow `.github/workflows/deploy.yml` automatiza o deploy em push na branch `main`.

### Configurar Secrets

No GitHub: Settings → Secrets and variables → Actions

Adicionar:
- `VPS_HOST`: IP ou domínio da VPS
- `VPS_USER`: Usuário SSH
- `VPS_SSH_KEY`: Chave SSH privada

### Disparar Deploy

- **Automático:** Push na branch `main`
- **Manual:** Actions → Deploy → Run workflow

### Logs

Ver logs em: GitHub → Actions → Deploy workflow

---

## 📝 Checklist de Deploy

Antes de fazer deploy em produção:

- [ ] `.env` configurado corretamente
- [ ] `APP_ENV=production`
- [ ] `APP_DEBUG=false`
- [ ] Credenciais de banco corretas
- [ ] Storage com permissões corretas
- [ ] Firewall configurado
- [ ] SSL/HTTPS funcionando
- [ ] Backup do banco realizado
- [ ] Testes passando localmente

---

## 🆘 Suporte

Em caso de problemas:

1. Verificar logs: `docker compose logs`
2. Verificar healthcheck: `curl https://seu-dominio.com/api/health`
3. Fazer rollback: `bash scripts/vps_rollback.sh`
4. Consultar documentação: `docs/`
5. Abrir issue no GitHub

---

**Última atualização:** Novembro 2025
