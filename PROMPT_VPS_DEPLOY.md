# 🤖 Prompt Completo para Cursor na VPS

## Contexto

Você está conectado diretamente na VPS onde o projeto Symplus Finance já foi clonado. O sistema operacional já está configurado (Docker, Nginx, Certbot instalados). Agora você precisa finalizar o deploy da aplicação.

## Situação Atual

- ✅ VPS: Ubuntu 22.04 LTS
- ✅ IP: 72.61.6.135
- ✅ Docker e Docker Compose instalados
- ✅ Nginx instalado
- ✅ Certbot instalado
- ✅ Repositório clonado em `/var/www/symplus`
- ⏳ **FALTA:** Configurar backend, Nginx, SSL e serviços

## Sua Tarefa

Siga as instruções detalhadas no arquivo `docs/DEPLOY_INSTRUCTIONS.md` para finalizar o deploy. Este arquivo contém TODOS os passos necessários, na ordem correta.

## Arquivos Importantes

- **Instruções completas:** `docs/DEPLOY_INSTRUCTIONS.md` ← **SIGA ESTE ARQUIVO**
- **Guia completo:** `docs/DEPLOY_VPS.md`
- **Scripts:** `scripts/` (deploy.sh, backup.sh, restore.sh)

## Passos Principais (Resumo)

1. **Configurar .env** - Criar arquivo de ambiente de produção
2. **Iniciar containers** - `docker compose -f docker-compose.prod.yml up -d`
3. **Instalar dependências** - Composer install
4. **Configurar Laravel** - Key generate, migrations, cache
5. **Configurar Nginx** - Proxy reverso para API
6. **Configurar SSL** - Certbot para HTTPS
7. **Configurar Horizon** - Filas do Laravel
8. **Configurar Backup** - Automatizar backups
9. **Testar tudo** - Verificar se está funcionando

## Importante

- **SEMPRE** substitua `SEU-DOMINIO.com` pelo domínio real
- **SEMPRE** use senhas fortes para banco de dados e MinIO
- **SEMPRE** verifique se os containers estão rodando antes de continuar
- **SEMPRE** teste cada etapa antes de prosseguir

## Comece Aqui

```bash
# 1. Navegar para o backend
cd /var/www/symplus/backend

# 2. Abrir instruções completas
cat ../docs/DEPLOY_INSTRUCTIONS.md

# OU abrir no editor
nano ../docs/DEPLOY_INSTRUCTIONS.md
```

**Agora siga as instruções passo a passo do arquivo `docs/DEPLOY_INSTRUCTIONS.md`**

## Se Encontrar Problemas

1. Verifique os logs: `docker compose -f docker-compose.prod.yml logs`
2. Verifique status: `docker compose -f docker-compose.prod.yml ps`
3. Consulte a seção Troubleshooting em `docs/DEPLOY_INSTRUCTIONS.md`
4. Consulte `docs/DEPLOY_VPS.md` para mais detalhes

---

**Boa sorte! 🚀**

