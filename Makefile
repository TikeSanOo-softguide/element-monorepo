DEV_COMPOSE=docker compose -f docker-compose.dev.yml
PROD_COMPOSE=docker compose -f docker-compose.prod.yml

help: ## Show available commands
	@grep -E '^[a-zA-Z_-]+:.*?## ' Makefile | awk 'BEGIN {FS = ":.*?## "}; {printf "%-16s %s\n", $$1, $$2}'

dev: ## Build and start local development
	$(DEV_COMPOSE) up --build

dev-bg: ## Build and start local development in background
	$(DEV_COMPOSE) up --build -d

dev-down: ## Stop local development containers
	$(DEV_COMPOSE) down

dev-logs: ## Tail local development logs
	$(DEV_COMPOSE) logs -f

dev-shell: ## Open a shell in the local development container
	$(DEV_COMPOSE) exec element-dev bash

dev-clean: ## Stop local development and remove dependency volumes
	$(DEV_COMPOSE) down -v

prod: ## Build and start production in background
	$(PROD_COMPOSE) up --build -d

prod-down: ## Stop production containers
	$(PROD_COMPOSE) down

prod-logs: ## Tail production logs
	$(PROD_COMPOSE) logs -f

prod-rebuild: ## Rebuild production image without cache
	$(PROD_COMPOSE) build --no-cache

prod-clean: ## Stop production and remove volumes
	$(PROD_COMPOSE) down -v

config-dev: ## Print rendered local development compose config
	$(DEV_COMPOSE) config

config-prod: ## Print rendered production compose config
	$(PROD_COMPOSE) config

.PHONY: help dev dev-bg dev-down dev-logs dev-shell dev-clean prod prod-down prod-logs prod-rebuild prod-clean config-dev config-prod