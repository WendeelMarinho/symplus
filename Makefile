.PHONY: help backend-up backend-down backend-sh backend-install backend-migrate backend-seed backend-test backend-horizon backend-logs backend-tinker app-run-android app-run-ios app-build

# Cores para output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
NC := \033[0m # No Color

help: ## Mostra esta ajuda
	@echo "$(BLUE)Symplus Finance - Comandos disponíveis$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'

# Backend - Docker & Laravel
backend-up: ## Sobe os containers Docker do backend
	@echo "$(BLUE)Subindo containers...$(NC)"
	cd backend && docker compose up -d
	@echo "$(GREEN)Containers iniciados!$(NC)"

backend-down: ## Para os containers Docker do backend
	@echo "$(YELLOW)Parando containers...$(NC)"
	cd backend && docker compose down
	@echo "$(GREEN)Containers parados!$(NC)"

backend-sh: ## Acessa o container PHP (bash)
	cd backend && docker compose exec php bash

backend-install: ## Instala dependências do backend (composer)
	@echo "$(BLUE)Instalando dependências...$(NC)"
	cd backend && docker compose exec php composer install
	@echo "$(GREEN)Dependências instaladas!$(NC)"

backend-migrate: ## Executa migrations do backend
	@echo "$(BLUE)Executando migrations...$(NC)"
	cd backend && docker compose exec php php artisan migrate
	@echo "$(GREEN)Migrations executadas!$(NC)"

backend-seed: ## Executa seeders do backend
	@echo "$(BLUE)Populando banco de dados...$(NC)"
	cd backend && docker compose exec php php artisan db:seed
	@echo "$(GREEN)Banco populado!$(NC)"

backend-test: ## Executa testes PHPUnit do backend
	@echo "$(BLUE)Executando testes...$(NC)"
	cd backend && docker compose exec php php artisan test
	@echo "$(GREEN)Testes concluídos!$(NC)"

backend-quality: ## Executa todas as verificações de qualidade (Pint + PHPStan + Testes)
	@echo "$(BLUE)Executando verificações de qualidade...$(NC)"
	cd backend && $(MAKE) quality
	@echo "$(GREEN)Verificações concluídas!$(NC)"

backend-horizon: ## Inicia o Laravel Horizon (filas)
	@echo "$(BLUE)Iniciando Horizon...$(NC)"
	cd backend && docker compose exec php php artisan horizon
	@echo "$(GREEN)Horizon iniciado!$(NC)"

backend-logs: ## Mostra logs dos containers do backend
	cd backend && docker compose logs -f

backend-tinker: ## Abre o Laravel Tinker
	cd backend && docker compose exec php php artisan tinker

# App Flutter
app-run-android: ## Executa o app Flutter no Android
	@echo "$(BLUE)Executando no Android...$(NC)"
	cd app && flutter run -d android

app-run-ios: ## Executa o app Flutter no iOS
	@echo "$(BLUE)Executando no iOS...$(NC)"
	cd app && flutter run -d ios

app-build: ## Build de produção do app Flutter
	@echo "$(BLUE)Gerando build de produção...$(NC)"
	cd app && flutter build apk --release
	@echo "$(GREEN)Build gerado em app/build/app/outputs/flutter-apk/app-release.apk$(NC)"

