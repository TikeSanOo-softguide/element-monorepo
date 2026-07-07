# Project Settings
PROJECT_NAME := chat-frontend
DOCKER_COMPOSE := docker compose

.PHONY: help build up down logs restart clean

help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Build the docker image
	$(DOCKER_COMPOSE) build

up: ## Start the container in detached mode
	$(DOCKER_COMPOSE) up -d

down: ## Stop and remove the container
	$(DOCKER_COMPOSE) down

logs: ## Follow the container logs
	$(DOCKER_COMPOSE) logs -f

restart: ## Restart the container
	$(DOCKER_COMPOSE) restart

clean: ## Remove containers and clean up build artifacts
	$(DOCKER_COMPOSE) down --rmi all --volumes