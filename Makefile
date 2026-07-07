up: ## Build and start the dev server
	COMPOSE_BAKE=true docker compose up --build

down: ## Stop and remove containers
	docker compose down

logs: ## Tail logs
	docker compose logs -f

shell: ## Open a shell in the running container
	docker compose exec element-web bash

clean: ## Stop containers and wipe node_modules volumes
	docker compose down -v

reset-setup: ## Force the full install/link/prebuild pipeline to rerun on next start
	FORCE_SETUP=1 docker compose up --build

.PHONY: up down logs shell clean reset-setup