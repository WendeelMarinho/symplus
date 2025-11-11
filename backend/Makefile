# Makefile — utilidades de build/deploy
#
# Mudanças aplicadas:
# - Adicionado suporte para docker-compose.prod.yml
# - Novos targets: fixperm, artisan-%, composer-%
# - Targets atualizados para usar working_dir correto (/var/www/symplus/backend)
# - Validações de permissões adicionadas
#
# Uso:
#   export HOST_UID=$(id -u)
#   export HOST_GID=$(id -g)
#   make up

.PHONY: help up down sh install migrate seed seed-realistic test test-coverage test-filter pint pint-fix phpstan quality horizon logs tinker health check restart-nginx fixperm artisan-% composer-% validate-perms

# Cores para output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Compose file (produção por padrão)
COMPOSE := docker compose -f docker-compose.prod.yml

help: ## Mostra esta ajuda
	@echo "$(BLUE)Symplus Backend - Comandos disponíveis$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'

up: ## Sobe os containers Docker
	@echo "$(BLUE)Subindo containers...$(NC)"
	@if [ -z "$$HOST_UID" ] || [ -z "$$HOST_GID" ]; then \
		echo "$(YELLOW)⚠️  HOST_UID/HOST_GID não definidos. Usando fallback 1001:1001$(NC)"; \
		echo "$(YELLOW)   Para usar seu UID/GID: export HOST_UID=\$$(id -u) && export HOST_GID=\$$(id -g)$(NC)"; \
	fi
	$(COMPOSE) up -d
	@echo "$(GREEN)Containers iniciados!$(NC)"
	@echo "$(YELLOW)Aguardando serviços ficarem prontos...$(NC)"
	@sleep 5

down: ## Para os containers Docker
	@echo "$(YELLOW)Parando containers...$(NC)"
	$(COMPOSE) down
	@echo "$(GREEN)Containers parados!$(NC)"

restart: ## Reinicia os containers
	@echo "$(BLUE)Reiniciando containers...$(NC)"
	$(COMPOSE) restart
	@echo "$(GREEN)Containers reiniciados!$(NC)"

sh: ## Acessa o container PHP (bash)
	$(COMPOSE) exec php sh

fixperm: ## Aplica ACL nos diretórios storage/bootstrap (quando necessário)
	@echo "$(BLUE)Aplicando ACL nos diretórios...$(NC)"
	$(COMPOSE) run --rm fixperm
	@echo "$(GREEN)ACL aplicada!$(NC)"

install: ## Instala dependências (composer)
	@echo "$(BLUE)Instalando dependências...$(NC)"
	$(COMPOSE) exec php composer install --no-interaction
	@echo "$(GREEN)Dependências instaladas!$(NC)"

migrate: ## Executa migrations
	@echo "$(BLUE)Executando migrations...$(NC)"
	$(COMPOSE) exec php php artisan migrate
	@echo "$(GREEN)Migrations executadas!$(NC)"

seed: ## Executa seeders
	@echo "$(BLUE)Populando banco de dados...$(NC)"
	$(COMPOSE) exec php php artisan db:seed
	@echo "$(GREEN)Banco populado!$(NC)"

seed-realistic: ## Executa seeders com dados realistas
	@echo "$(BLUE)Executando seeders com dados realistas...$(NC)"
	$(COMPOSE) exec php php artisan db:seed --class=RealisticDataSeeder
	@echo "$(GREEN)Seeders realistas concluídos!$(NC)"

test: ## Executa testes PHPUnit
	@echo "$(BLUE)Executando testes...$(NC)"
	$(COMPOSE) exec php php artisan test
	@echo "$(GREEN)Testes concluídos!$(NC)"

test-coverage: ## Executa testes com cobertura de código
	@echo "$(BLUE)Executando testes com cobertura...$(NC)"
	$(COMPOSE) exec php php artisan test --coverage
	@echo "$(GREEN)Testes com cobertura concluídos!$(NC)"

test-filter: ## Executa testes filtrados (uso: make test-filter FILTER='nome_do_teste')
	@echo "$(BLUE)Executando testes filtrados: $(FILTER)...$(NC)"
	$(COMPOSE) exec php php artisan test --filter $(FILTER)

pint: ## Verifica estilo de código com Pint
	@echo "$(BLUE)Verificando estilo de código...$(NC)"
	$(COMPOSE) exec php vendor/bin/pint --test
	@echo "$(GREEN)Verificação concluída!$(NC)"

pint-fix: ## Corrige estilo de código automaticamente
	@echo "$(BLUE)Corrigindo estilo de código...$(NC)"
	$(COMPOSE) exec php vendor/bin/pint
	@echo "$(GREEN)Correção concluída!$(NC)"

phpstan: ## Executa análise estática com PHPStan
	@echo "$(BLUE)Executando análise estática...$(NC)"
	$(COMPOSE) exec php php -d memory_limit=512M vendor/bin/phpstan analyse
	@echo "$(GREEN)Análise concluída!$(NC)"

quality: pint phpstan test ## Executa todas as verificações de qualidade
	@echo "$(GREEN)✅ Verificações de qualidade concluídas!$(NC)"

horizon: ## Inicia o Laravel Horizon (filas)
	@echo "$(BLUE)Iniciando Horizon...$(NC)"
	$(COMPOSE) exec php php artisan horizon
	@echo "$(GREEN)Horizon iniciado!$(NC)"

logs: ## Mostra logs dos containers
	$(COMPOSE) logs -f

tinker: ## Abre o Laravel Tinker
	$(COMPOSE) exec php php artisan tinker

health: ## Testa o endpoint de health da API
	@echo "$(BLUE)Testando health endpoint...$(NC)"
	@curl -s http://localhost:8000/api/health || echo "$(RED)❌ API não está acessível em localhost:8000$(NC)"

check: ## Verifica status dos containers e serviços
	@echo "$(BLUE)Verificando containers...$(NC)"
	@$(COMPOSE) ps
	@echo ""
	@echo "$(BLUE)Testando conectividade...$(NC)"
	@$(COMPOSE) exec php php artisan route:list --path=health || echo "$(YELLOW)⚠ Não foi possível listar rotas$(NC)"

restart-nginx: ## Reinicia o nginx (útil após mudanças na config)
	@echo "$(BLUE)Validando configuração do nginx...$(NC)"
	@$(COMPOSE) exec nginx nginx -t || (echo "$(RED)❌ Erro na configuração do nginx!$(NC)" && exit 1)
	@echo "$(BLUE)Reiniciando nginx...$(NC)"
	@$(COMPOSE) restart nginx
	@echo "$(GREEN)Nginx reiniciado!$(NC)"

# Targets dinâmicos para artisan e composer
artisan-%: ## Executa comando artisan (uso: make artisan-migrate)
	$(COMPOSE) exec php php artisan $*

composer-%: ## Executa comando composer (uso: make composer-install)
	$(COMPOSE) exec php composer $*

validate-perms: ## Valida permissões de escrita nos diretórios críticos
	@echo "$(BLUE)Validando permissões...$(NC)"
	@echo "$(YELLOW)1. Verificando UID/GID do processo e owners dos diretórios:$(NC)"
	@$(COMPOSE) exec php sh -lc 'id; stat -c "%U:%G %n" storage bootstrap/cache' || true
	@echo ""
	@echo "$(YELLOW)2. Testando escrita em storage/framework/cache:$(NC)"
	@$(COMPOSE) exec php sh -lc 'echo ok > storage/framework/cache/.__perm_test && cat storage/framework/cache/.__perm_test && rm -f storage/framework/cache/.__perm_test && echo "✅ Escrita OK" || echo "❌ Falha na escrita"' || true
	@echo ""
	@echo "$(YELLOW)3. Testando artisan config:cache:$(NC)"
	@$(COMPOSE) exec php sh -lc 'php artisan config:cache && php artisan route:cache && echo "✅ Cache OK" || echo "❌ Falha no cache"' || true
