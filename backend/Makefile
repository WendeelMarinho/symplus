.PHONY: help up down sh install migrate seed seed-realistic test test-coverage test-filter pint pint-fix phpstan quality horizon logs tinker health check restart-nginx

# Cores para output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

help: ## Mostra esta ajuda
	@echo "$(BLUE)Symplus Backend - Comandos disponíveis$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'

up: ## Sobe os containers Docker
	@echo "$(BLUE)Subindo containers...$(NC)"
	docker compose up -d
	@echo "$(GREEN)Containers iniciados!$(NC)"
	@echo "$(YELLOW)Aguardando serviços ficarem prontos...$(NC)"
	@sleep 5

restart-nginx: ## Reinicia o nginx (útil após mudanças na config)
	@echo "$(BLUE)Validando configuração do nginx...$(NC)"
	@docker compose exec nginx nginx -t || (echo "$(RED)❌ Erro na configuração do nginx!$(NC)" && exit 1)
	@echo "$(BLUE)Reiniciando nginx...$(NC)"
	@docker compose restart nginx
	@echo "$(GREEN)Nginx reiniciado!$(NC)"

down: ## Para os containers Docker
	@echo "$(YELLOW)Parando containers...$(NC)"
	docker compose down
	@echo "$(GREEN)Containers parados!$(NC)"

sh: ## Acessa o container PHP (bash)
	docker compose exec php sh -c "cd /var/www/html && bash"

install: ## Instala dependências (composer)
	@echo "$(BLUE)Instalando dependências...$(NC)"
	docker compose exec php sh -c "cd /var/www/html && composer install --no-interaction"
	@echo "$(GREEN)Dependências instaladas!$(NC)"

migrate: ## Executa migrations
	@echo "$(BLUE)Executando migrations...$(NC)"
	docker compose exec php sh -c "cd /var/www/html && php artisan migrate"
	@echo "$(GREEN)Migrations executadas!$(NC)"

seed: ## Executa seeders
	@echo "$(BLUE)Populando banco de dados...$(NC)"
	docker compose exec php sh -c "cd /var/www/html && php artisan db:seed"
	@echo "$(GREEN)Banco populado!$(NC)"

seed-realistic: ## Executa seeders com dados realistas
	@echo "$(BLUE)Executando seeders com dados realistas...$(NC)"
	docker compose exec php sh -c "cd /var/www/html && php artisan db:seed --class=RealisticDataSeeder"
	@echo "$(GREEN)Seeders realistas concluídos!$(NC)"

test: ## Executa testes PHPUnit
	@echo "$(BLUE)Executando testes...$(NC)"
	docker compose exec php sh -c "cd /var/www/html && php artisan test"
	@echo "$(GREEN)Testes concluídos!$(NC)"

test-coverage: ## Executa testes com cobertura de código
	@echo "$(BLUE)Executando testes com cobertura...$(NC)"
	docker compose exec php sh -c "cd /var/www/html && php artisan test --coverage"
	@echo "$(GREEN)Testes com cobertura concluídos!$(NC)"

test-filter: ## Executa testes filtrados (uso: make test-filter FILTER='nome_do_teste')
	@echo "$(BLUE)Executando testes filtrados: $(FILTER)...$(NC)"
	docker compose exec php sh -c "cd /var/www/html && php artisan test --filter $(FILTER)"

pint: ## Verifica estilo de código com Pint
	@echo "$(BLUE)Verificando estilo de código...$(NC)"
	docker compose exec php sh -c "cd /var/www/html && vendor/bin/pint --test"
	@echo "$(GREEN)Verificação concluída!$(NC)"

pint-fix: ## Corrige estilo de código automaticamente
	@echo "$(BLUE)Corrigindo estilo de código...$(NC)"
	docker compose exec php sh -c "cd /var/www/html && vendor/bin/pint"
	@echo "$(GREEN)Correção concluída!$(NC)"

phpstan: ## Executa análise estática com PHPStan
	@echo "$(BLUE)Executando análise estática...$(NC)"
	docker compose exec php sh -c "cd /var/www/html && php -d memory_limit=512M vendor/bin/phpstan analyse"
	@echo "$(GREEN)Análise concluída!$(NC)"

quality: pint phpstan test ## Executa todas as verificações de qualidade
	@echo "$(GREEN)✅ Verificações de qualidade concluídas!$(NC)"

horizon: ## Inicia o Laravel Horizon (filas)
	@echo "$(BLUE)Iniciando Horizon...$(NC)"
	docker compose exec php sh -c "cd /var/www/html && php artisan horizon"
	@echo "$(GREEN)Horizon iniciado!$(NC)"

logs: ## Mostra logs dos containers
	docker compose logs -f

tinker: ## Abre o Laravel Tinker
	docker compose exec php sh -c "cd /var/www/html && php artisan tinker"

health: ## Testa o endpoint de health da API
	@echo "$(BLUE)Testando health endpoint...$(NC)"
	@docker compose exec nginx sh -c "wget -qO- http://localhost/api/health || curl -s http://localhost/api/health" || echo "$(YELLOW)⚠ Teste de dentro do container falhou. Tentando do host...$(NC)"
	@curl -s http://localhost:8000/api/health || echo "$(RED)❌ API não está acessível em localhost:8000$(NC)"

check: ## Verifica status dos containers e serviços
	@echo "$(BLUE)Verificando containers...$(NC)"
	@docker compose ps
	@echo ""
	@echo "$(BLUE)Testando conectividade...$(NC)"
	@docker compose exec php sh -c "cd /var/www/html && php artisan route:list --path=health" || echo "$(YELLOW)⚠ Não foi possível listar rotas$(NC)"

