# 🚀 Próximo Passo: Executar Migration do Custom Indicators

## 📋 Situação Atual

✅ **Migration existe:** `backend/database/migrations/2024_01_01_000018_create_custom_indicators_table.php`  
❌ **Tabela não existe no banco:** A migration não foi executada ainda

## 🎯 Objetivo

Executar a migration para criar a tabela `custom_indicators` no banco de dados.

---

## 📝 Passo a Passo

### Opção 1: Usando Makefile (Recomendado)

```bash
# 1. Navegar para o diretório do backend
cd backend

# 2. Verificar se os containers estão rodando
docker compose -f docker-compose.prod.yml ps

# 3. Se não estiverem rodando, subir os containers
make up
# ou
docker compose -f docker-compose.prod.yml up -d

# 4. Executar a migration
make migrate
# ou
docker compose -f docker-compose.prod.yml exec php php artisan migrate
```

### Opção 2: Executar Migration Específica

Se quiser executar apenas a migration do `custom_indicators`:

```bash
cd backend
docker compose -f docker-compose.prod.yml exec php php artisan migrate --path=database/migrations/2024_01_01_000018_create_custom_indicators_table.php
```

### Opção 3: Verificar Status das Migrations

Para ver quais migrations já foram executadas:

```bash
cd backend
docker compose -f docker-compose.prod.yml exec php php artisan migrate:status
```

---

## ✅ Verificação

Após executar a migration, verifique se a tabela foi criada:

```bash
# Acessar o container MySQL
docker compose -f docker-compose.prod.yml exec db mysql -u symplus -p symplus

# No MySQL, verificar se a tabela existe:
SHOW TABLES LIKE 'custom_indicators';

# Ver estrutura da tabela:
DESCRIBE custom_indicators;

# Deve mostrar:
# - id (bigint, primary key)
# - organization_id (bigint, foreign key)
# - name (varchar)
# - category_ids (json)
# - created_at (timestamp)
# - updated_at (timestamp)
```

---

## 🔍 Estrutura da Tabela

A migration criará a seguinte estrutura:

```sql
CREATE TABLE `custom_indicators` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `organization_id` bigint unsigned NOT NULL,
  `name` varchar(255) NOT NULL,
  `category_ids` json NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `custom_indicators_organization_id_index` (`organization_id`),
  CONSTRAINT `custom_indicators_organization_id_foreign` 
    FOREIGN KEY (`organization_id`) 
    REFERENCES `organizations` (`id`) 
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

---

## 🐛 Troubleshooting

### Erro: "Container não encontrado"

```bash
# Verificar se os containers estão rodando
docker compose -f docker-compose.prod.yml ps

# Se não estiverem, subir:
make up
```

### Erro: "Connection refused" ou "Can't connect to MySQL"

```bash
# Verificar se o container MySQL está rodando
docker compose -f docker-compose.prod.yml ps db

# Ver logs do MySQL
docker compose -f docker-compose.prod.yml logs db

# Reiniciar MySQL se necessário
docker compose -f docker-compose.prod.yml restart db
```

### Erro: "Migration already exists"

Se a migration já foi executada, você verá:
```
Nothing to migrate.
```

Isso significa que a tabela já existe. Verifique com:
```bash
docker compose -f docker-compose.prod.yml exec php php artisan migrate:status
```

### Erro: "Foreign key constraint fails"

Verifique se a tabela `organizations` existe:
```bash
docker compose -f docker-compose.prod.yml exec db mysql -u symplus -p symplus -e "SHOW TABLES LIKE 'organizations';"
```

---

## ✅ Após Executar a Migration

1. **Testar no Flutter:**
   - Recarregar o dashboard
   - Verificar se a seção "Indicadores Personalizados" aparece
   - Tentar criar um indicador personalizado

2. **Verificar no Backend:**
   ```bash
   # Testar endpoint da API
   curl -X GET "http://localhost:8000/api/custom-indicators?from=2025-11-01&to=2025-11-19" \
     -H "Authorization: Bearer SEU_TOKEN" \
     -H "X-Organization-Id: 1"
   ```

3. **Se tudo funcionar:**
   - ✅ Aplicação está 100% pronta para produção!
   - ✅ Executar build do Flutter Web
   - ✅ Fazer deploy

---

## 🎯 Comandos Rápidos

```bash
# Tudo em um comando:
cd backend && make up && make migrate

# Ou manualmente:
cd backend
docker compose -f docker-compose.prod.yml up -d
docker compose -f docker-compose.prod.yml exec php php artisan migrate
```

---

## 📚 Próximos Passos Após Migration

1. ✅ Migration executada
2. ✅ Testar no Flutter
3. ✅ Executar build de produção: `bash scripts/build_flutter_web.sh`
4. ✅ Fazer deploy

