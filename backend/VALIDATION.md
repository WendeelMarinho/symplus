# Guia de Validação - Antes da Próxima Etapa

Este guia lista os passos necessários para validar tudo que foi criado até agora (Etapas 0-4) antes de prosseguir para a Etapa 5.

## 📋 Checklist de Validação

### 1. Preparar arquivo de ambiente

```bash
cd backend
cp env.example .env
```

**Validação:** Verificar se o arquivo `.env` foi criado:
```bash
ls -la .env
```

---

### 2. Subir containers Docker

```bash
# No diretório backend/
make up
# ou
docker compose up -d
```

**Validação:** Verificar se todos os containers estão rodando:
```bash
docker compose ps
```

Deve mostrar:
- ✅ `symplus_php` (running)
- ✅ `symplus_nginx` (running)
- ✅ `symplus_mysql` (running)
- ✅ `symplus_redis` (running)
- ✅ `symplus_minio` (running)
- ✅ `symplus_createbucket` (exited - ok, é um job único)

**Aguardar 10-15 segundos** para os serviços iniciarem completamente.

---

### 3. Instalar dependências do Composer

```bash
make install
# ou
docker compose exec php composer install
```

**Validação:** Verificar se o diretório `vendor/` foi criado:
```bash
docker compose exec php ls -la vendor/
```

**Tempo estimado:** 2-5 minutos (dependendo da conexão)

---

### 4. Gerar chave da aplicação

```bash
docker compose exec php php artisan key:generate
```

**Validação:** Verificar se `APP_KEY` foi preenchido no `.env`:
```bash
docker compose exec php grep APP_KEY .env
```

Deve mostrar algo como: `APP_KEY=base64:...`

---

### 5. Executar migrations

```bash
make migrate
# ou
docker compose exec php php artisan migrate
```

**Validação:** Verificar se todas as tabelas foram criadas:
```bash
docker compose exec php php artisan migrate:status
```

Deve mostrar **11 migrations** executadas:
- ✅ cache tables
- ✅ sessions
- ✅ users
- ✅ failed_jobs
- ✅ personal_access_tokens
- ✅ jobs
- ✅ organizations
- ✅ organization_user
- ✅ accounts
- ✅ categories
- ✅ transactions

**Alternativa:** Verificar no banco:
```bash
docker compose exec db mysql -u symplus -proot symplus -e "SHOW TABLES;"
```

---

### 6. Executar seeders

```bash
make seed
# ou
docker compose exec php php artisan db:seed
```

**Validação:** Verificar se o usuário admin foi criado:
```bash
docker compose exec php php artisan tinker
```

No tinker, execute:
```php
User::first();
Organization::first();
exit
```

Deve retornar:
- User: `admin@symplus.dev`
- Organization: `Symplus Dev`

---

### 7. Testar autenticação (Login)

**7.1.** Verificar se a API está respondendo:
```bash
curl http://localhost:8000/api/health
```

**7.2.** Fazer login:
```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@symplus.dev","password":"password"}'
```

**Validação:** Deve retornar JSON com `user` e `token`.

**7.3.** Obter dados do usuário (usando o token retornado):
```bash
# Substitua {TOKEN} pelo token recebido no login
curl http://localhost:8000/api/me \
  -H "Authorization: Bearer {TOKEN}" \
  -H "X-Organization-Id: 1"
```

**Validação:** Deve retornar dados do usuário com organizações.

---

### 8. Testar CRUD Financeiro (Opcional, mas recomendado)

**8.1.** Criar uma conta:
```bash
curl -X POST http://localhost:8000/api/accounts \
  -H "Authorization: Bearer {TOKEN}" \
  -H "X-Organization-Id: 1" \
  -H "Content-Type: application/json" \
  -d '{"name":"Conta Corrente","currency":"BRL","opening_balance":1000}'
```

**8.2.** Listar contas:
```bash
curl http://localhost:8000/api/accounts \
  -H "Authorization: Bearer {TOKEN}" \
  -H "X-Organization-Id: 1"
```

**8.3.** Criar uma categoria:
```bash
curl -X POST http://localhost:8000/api/categories \
  -H "Authorization: Bearer {TOKEN}" \
  -H "X-Organization-Id: 1" \
  -H "Content-Type: application/json" \
  -d '{"type":"expense","name":"Alimentação","color":"#FF5733"}'
```

**Validação:** Todos devem retornar status 201 (criado) ou 200 (listagem).

---

### 9. Executar testes automatizados

```bash
make test
# ou
docker compose exec php php artisan test
```

**Validação:** Todos os testes devem passar (ou pelo menos não dar erro fatal).

**Testes esperados:**
- ✅ `AuthTest` - Login, logout, /me
- ✅ `TenantIsolationTest` - Isolamento por organização
- ✅ `AccountTest` - CRUD de contas e isolamento
- ✅ `ExampleTest` - Teste básico

**Nota:** Alguns testes podem falhar se faltarem factories. Isso é normal e será corrigido nas próximas etapas.

---

### 10. Verificar estrutura de arquivos

```bash
# Verificar se todos os diretórios estão presentes
ls -la app/Models/
ls -la app/Http/Controllers/Api/
ls -la app/Http/Resources/
ls -la database/migrations/
```

**Validação:** Deve existir:
- ✅ Models: User, Organization, Account, Category, Transaction
- ✅ Controllers: AuthController, AccountController, CategoryController, TransactionController
- ✅ Resources: UserResource, OrganizationResource, AccountResource, CategoryResource, TransactionResource
- ✅ Migrations: 11 arquivos de migration

---

## 🎯 Resultado Esperado

Após completar todos os passos, você deve ter:

1. ✅ Containers Docker rodando
2. ✅ Dependências instaladas (`vendor/` presente)
3. ✅ Banco de dados configurado com todas as tabelas
4. ✅ Usuário admin criado (`admin@symplus.dev` / `password`)
5. ✅ API respondendo corretamente
6. ✅ Autenticação funcionando (login retorna token)
7. ✅ CRUD básico funcionando (contas, categorias)

---

## ⚠️ Problemas Comuns

### Erro: "Container não inicia"
- Verificar se as portas 8000, 3306, 6379, 9000, 9001 estão livres
- Verificar logs: `docker compose logs`

### Erro: "Composer install falha"
- Verificar conexão com internet
- Tentar: `docker compose exec php composer install --no-cache`

### Erro: "Migration falha"
- Verificar se MySQL está pronto: `docker compose exec db mysqladmin ping -h localhost`
- Verificar credenciais no `.env`

### Erro: "API retorna 500"
- Verificar logs: `docker compose logs php`
- Verificar se `APP_KEY` foi gerado
- Verificar permissões: `docker compose exec php chmod -R 775 storage bootstrap/cache`

---

## ✅ Próximos Passos

Após validar tudo acima, você pode prosseguir para a **Etapa 5: Relatório P&L (Profit & Loss)**.

---

**Última atualização:** Etapa 4 concluída

