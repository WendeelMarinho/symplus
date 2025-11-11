# 🔐 Gerenciamento de Permissões - Symplus Backend

## 📋 Visão Geral

Este projeto Laravel roda em Docker com uma solução estruturada para evitar conflitos de permissões entre o host e o container.

### Problema Resolvido

- **Antes:** Container PHP rodava como `www-data` (33:33), mas volumes montados tinham owner `1001:1001` do host, causando falhas de escrita.
- **Agora:** Container PHP roda com o mesmo UID/GID do host (1001:1001 por padrão), eliminando conflitos.

### Solução Estrutural

1. **UID/GID Dinâmico:** O serviço PHP usa `user: "${HOST_UID:-1001}:${HOST_GID:-1001}"` no docker-compose
2. **Entrypoint Automático:** Script `docker/php/entrypoint.sh` prepara diretórios e permissões automaticamente
3. **ACL de Fallback:** Serviço `fixperm` disponível caso seja necessário rodar como www-data

---

## 🚀 Como Subir o Projeto

### 1. Configurar UID/GID do Host (Recomendado)

```bash
# No host, antes de subir os containers
export HOST_UID=$(id -u)
export HOST_GID=$(id -g)

# Verificar valores
echo "UID: $HOST_UID, GID: $HOST_GID"
```

### 2. Subir Containers

```bash
cd /var/www/symplus/backend
make up
# ou
docker compose -f docker-compose.prod.yml up -d
```

**Nota:** Se não definir `HOST_UID`/`HOST_GID`, o sistema usará `1001:1001` como fallback.

### 3. Verificar Permissões

```bash
# Validar permissões automaticamente
make validate-perms

# Ou manualmente
docker compose -f docker-compose.prod.yml exec php sh -lc 'id; stat -c "%U:%G %n" storage bootstrap/cache'
```

---

## 🔧 Como Aplicar ACL (Fallback)

Se por algum motivo o container precisar rodar como `www-data` (33:33) e os diretórios forem `1001:1001`, use o serviço `fixperm`:

```bash
# Via Makefile
make fixperm

# Ou diretamente
docker compose -f docker-compose.prod.yml run --rm fixperm
```

O serviço `fixperm`:
- Instala `acl` no Alpine
- Aplica ACL recursiva para `www-data` nos diretórios `storage` e `bootstrap/cache`
- Garante permissões de escrita mesmo com owners diferentes

---

## ✅ Como Validar Permissões

### Validação Automática (Recomendado)

```bash
make validate-perms
```

Este comando executa 3 verificações:
1. Mostra UID/GID do processo e owners dos diretórios
2. Testa escrita em `storage/framework/cache`
3. Testa cache do Laravel (`config:cache`, `route:cache`)

### Validação Manual

#### 1. Verificar UID/GID e Owners

```bash
docker compose -f docker-compose.prod.yml exec php sh -lc 'id; stat -c "%U:%G %n" storage bootstrap/cache'
```

**Saída esperada:**
```
uid=1001(symplus) gid=1001(symplus) groups=1001(symplus)
symplus:symplus storage
symplus:symplus bootstrap/cache
```

#### 2. Teste de Escrita

```bash
docker compose -f docker-compose.prod.yml exec php sh -lc \
  'echo ok > storage/framework/cache/.__perm_test && \
   cat storage/framework/cache/.__perm_test && \
   rm -f storage/framework/cache/.__perm_test'
```

**Saída esperada:**
```
ok
```

#### 3. Teste Artisan Cache

```bash
docker compose -f docker-compose.prod.yml exec php sh -lc \
  'php artisan config:cache && php artisan route:cache || true'
```

**Saída esperada:**
```
Configuration cached successfully!
Routes cached successfully!
```

---

## 📁 Estrutura de Arquivos

```
/var/www/symplus/backend/
├── docker-compose.prod.yml    # Configuração Docker com UID/GID dinâmico
├── Dockerfile.prod            # Dockerfile do serviço PHP
├── docker/
│   └── php/
│       └── entrypoint.sh      # Script de preparação automática
├── Makefile                   # Comandos úteis (make up, make fixperm, etc.)
└── PERMISSIONS_README.md      # Este arquivo
```

---

## 🔍 Troubleshooting

### Problema: "Permission denied" ao escrever em storage

**Solução 1 (Recomendada):** Alinhar UID/GID
```bash
export HOST_UID=$(id -u)
export HOST_GID=$(id -g)
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d
```

**Solução 2:** Aplicar ACL
```bash
make fixperm
```

### Problema: Entrypoint não executa

Verifique se o arquivo está executável:
```bash
chmod +x docker/php/entrypoint.sh
```

### Problema: Container não inicia

Verifique logs:
```bash
docker compose -f docker-compose.prod.yml logs php
```

### Problema: ACL não funciona

O serviço `fixperm` requer que o sistema de arquivos suporte ACL. Verifique:
```bash
mount | grep acl
```

Se não houver suporte, a solução é alinhar UID/GID (Solução 1 acima).

---

## 📝 Comandos Úteis do Makefile

```bash
make up              # Sobe containers
make down            # Para containers
make restart         # Reinicia containers
make sh              # Acessa shell do container PHP
make fixperm         # Aplica ACL (quando necessário)
make validate-perms  # Valida permissões
make artisan-%       # Executa comando artisan (ex: make artisan-migrate)
make composer-%      # Executa comando composer (ex: make composer-install)
```

---

## 🎯 Fluxo de Uso Completo

```bash
# 1. No host, configurar UID/GID
export HOST_UID=$(id -u)
export HOST_GID=$(id -g)

# 2. Subir containers
make up

# 3. Instalar dependências (primeira vez)
make composer-install

# 4. Executar migrations
make artisan-migrate

# 5. Validar permissões
make validate-perms

# 6. Se tudo OK, a aplicação está pronta!
```

---

## 🔐 Segurança

- O container PHP roda com UID/GID não-privilegiado (1001:1001 por padrão)
- O serviço `fixperm` roda como root apenas para aplicar ACL, depois encerra
- Volumes são montados com permissões restritas (775)
- Nenhum serviço expõe portas desnecessárias para o host

---

## 📚 Referências

- [Docker Compose - User](https://docs.docker.com/compose/compose-file/compose-file-v3/#user)
- [Laravel - File Permissions](https://laravel.com/docs/filesystem#file-permissions)
- [ACL - Access Control Lists](https://wiki.archlinux.org/title/Access_Control_Lists)

---

**Última atualização:** Novembro 2025
