# Symplus Backend

Backend Laravel 11 da aplicação Symplus Finance.

## 🚀 Início Rápido

1. **Copie o arquivo de ambiente:**
   ```bash
   cp env.example .env
   ```

2. **Suba os containers:**
   ```bash
   make up
   # ou
   docker compose up -d
   ```

3. **Instale as dependências:**
   ```bash
   make install
   # ou
   docker compose exec php composer install
   ```

4. **Gere a chave da aplicação:**
   ```bash
   docker compose exec php php artisan key:generate
   ```

5. **Execute as migrations:**
   ```bash
   make migrate
   # ou
   docker compose exec php php artisan migrate
   ```

## 📦 Serviços

- **PHP 8.3-FPM**: `http://localhost:8000`
- **MySQL 8**: `localhost:3306`
- **Redis**: `localhost:6379`
- **MinIO**: `http://localhost:9000` (API) / `http://localhost:9001` (Console)

## 🛠️ Comandos Make

- `make up` - Sobe os containers
- `make down` - Para os containers
- `make sh` - Acessa o container PHP
- `make install` - Instala dependências
- `make migrate` - Executa migrations
- `make seed` - Executa seeders
- `make test` - Executa testes
- `make horizon` - Inicia o Horizon
- `make logs` - Mostra logs
- `make tinker` - Abre o Tinker

## 📝 Notas

- O MinIO é configurado automaticamente com um bucket padrão (`symplus`)
- As credenciais padrão do MinIO são `minioadmin` / `minioadmin`
- O MySQL usa autenticação `mysql_native_password` para compatibilidade

