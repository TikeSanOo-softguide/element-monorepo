# chat-frontend — Docker orchestration

COMPOSE_DEV  := docker compose -f docker-compose.yml
COMPOSE_PROD := docker compose -f docker-compose.production.yml
SERVICE      := element-web

.PHONY: help dev prod build-dev build-prod down down-dev logs logs-dev sh sh-dev clean clean-volumes ps

help:
	@echo "Targets:"
	@echo "  make dev            Build & run development stack (hot reload)"
	@echo "  make prod           Build & run production stack (nginx)"
	@echo "  make build-dev      Build development image only"
	@echo "  make build-prod     Build production image only"
	@echo "  make down-dev       Stop development stack"
	@echo "  make down           Stop production stack"
	@echo "  make logs-dev       Tail development logs"
	@echo "  make logs           Tail production logs"
	@echo "  make sh-dev         Shell into development container"
	@echo "  make sh             Shell into production container"
	@echo "  make clean-volumes  Remove dev containers, images, and node_modules volumes"
	@echo "  make clean          Remove prod containers and local images"

build-dev:
	$(COMPOSE_DEV) build

dev: build-dev
	$(COMPOSE_DEV) up

build-prod:
	DOCKER_BUILDKIT=1 $(COMPOSE_PROD) build

prod: build-prod
	$(COMPOSE_PROD) up -d

down-dev:
	$(COMPOSE_DEV) down

down:
	$(COMPOSE_PROD) down

logs-dev:
	$(COMPOSE_DEV) logs -f $(SERVICE)

logs:
	$(COMPOSE_PROD) logs -f $(SERVICE)

sh-dev:
	$(COMPOSE_DEV) exec $(SERVICE) bash

sh:
	$(COMPOSE_PROD) exec $(SERVICE) sh

clean:
	$(COMPOSE_PROD) down --rmi local --remove-orphans

clean-volumes:
	$(COMPOSE_DEV) down --rmi local --remove-orphans --volumes

ps:
	$(COMPOSE_PROD) ps
