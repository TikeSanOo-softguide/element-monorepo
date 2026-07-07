# =========================================
# chat-frontend Makefile
# =========================================

COMPOSE        := docker compose -f docker-compose.yml
COMPOSE_DEV    := docker compose -f docker-compose.yml -f docker-compose.dev.yml
SERVICE        := chat-frontend

.PHONY: help build build-prod build-dev up down dev prod logs logs-dev \
        sh sh-dev clean clean-volumes restart restart-dev ps

## Show available targets
help:
	@echo "Targets:"
	@echo "  make prod           - Build & run production (nginx, static build)"
	@echo "  make dev            - Build & run local development (live reload)"
	@echo "  make build-prod     - Build production image only"
	@echo "  make build-dev      - Build development image only"
	@echo "  make down           - Stop and remove containers (prod)"
	@echo "  make down-dev       - Stop and remove containers (dev)"
	@echo "  make logs           - Tail production logs"
	@echo "  make logs-dev       - Tail development logs"
	@echo "  make sh             - Shell into running prod container"
	@echo "  make sh-dev         - Shell into running dev container"
	@echo "  make restart        - Restart prod stack"
	@echo "  make restart-dev    - Restart dev stack"
	@echo "  make clean          - Remove containers, images, orphans (prod)"
	@echo "  make clean-volumes  - Also wipe node_modules volumes (dev)"
	@echo "  make ps             - Show running containers"

# ---------- Production ----------

## Build production image
build-prod:
	$(COMPOSE) build

## Build & start production stack (detached)
prod: build-prod
	$(COMPOSE) up -d

## Stop production stack
down:
	$(COMPOSE) down

## Restart production stack
restart:
	$(COMPOSE) restart

## Tail production logs
logs:
	$(COMPOSE) logs -f $(SERVICE)

## Shell into running production container
sh:
	$(COMPOSE) exec $(SERVICE) sh

# ---------- Development ----------

## Build development image
build-dev:
	$(COMPOSE_DEV) build

## Build & start development stack (foreground, live logs)
dev: build-dev
	$(COMPOSE_DEV) up

## Stop development stack
down-dev:
	$(COMPOSE_DEV) down

## Restart development stack
restart-dev:
	$(COMPOSE_DEV) restart

## Tail development logs
logs-dev:
	$(COMPOSE_DEV) logs -f $(SERVICE)

## Shell into running development container
sh-dev:
	$(COMPOSE_DEV) exec $(SERVICE) bash

# ---------- Cleanup ----------

## Remove containers, dangling images, and orphans (production)
clean:
	$(COMPOSE) down --rmi local --remove-orphans

## Remove containers, images, and named volumes (wipes cached node_modules)
clean-volumes:
	$(COMPOSE_DEV) down --rmi local --remove-orphans --volumes

## Show running containers for this project
ps:
	$(COMPOSE) ps