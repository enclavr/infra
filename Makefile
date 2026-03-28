.PHONY: help up down restart logs status build validate clean
.PHONY: monitoring voice backup tls full
.PHONY: db-shell redis-shell pg-backup pg-restore
.PHONY: dev prod

# Default target
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ============================================
# Service Management
# ============================================

up: ## Start core services (postgres, redis, server, frontend)
	docker compose -f docker-compose.yml up -d

down: ## Stop all services
	docker compose down

restart: ## Restart core services
	docker compose restart

logs: ## Follow logs for core services
	docker compose logs -f

status: ## Show service status
	docker compose ps

build: ## Build all images
	docker compose build --no-cache

validate: ## Validate docker-compose config
	docker compose config --quiet

# ============================================
# Profile Management
# ============================================

monitoring: ## Start with monitoring stack
	docker compose -f docker-compose.yml --profile monitoring up -d

voice: ## Start with voice (coturn)
	docker compose -f docker-compose.yml --profile voice up -d

backup: ## Start with backup service
	docker compose -f docker-compose.yml --profile backup up -d

tls: ## Start with TLS (Caddy)
	docker compose -f docker-compose.yml --profile tls up -d

full: ## Start all services
	docker compose -f docker-compose.yml --profile full up -d

# ============================================
# Development
# ============================================

dev: ## Start in development mode (with hot reload)
	docker compose -f docker-compose.yml -f docker-compose.override.yml up -d

prod: ## Start in production mode (all profiles)
	docker compose -f docker-compose.yml --profile full --profile tls up -d

# ============================================
# Database Operations
# ============================================

db-shell: ## Open PostgreSQL shell
	docker compose exec postgres psql -U $$POSTGRES_USER -d $$POSTGRES_DB

redis-shell: ## Open Redis CLI
	docker compose exec redis redis-cli

pg-backup: ## Create manual PostgreSQL backup
	docker compose exec postgres pg_dumpall -U $$POSTGRES_USER | gzip > backup_$$(date +%Y%m%d_%H%M%S).sql.gz

pg-restore: ## Restore PostgreSQL from backup (usage: make pg-restore FILE=backup.sql.gz)
	gunzip -c $(FILE) | docker compose exec -T postgres psql -U $$POSTGRES_USER

# ============================================
# Maintenance
# ============================================

clean: ## Remove stopped containers and unused volumes
	docker compose down -v --remove-orphans
	docker system prune -f

update-images: ## Pull latest images and recreate
	docker compose pull
	docker compose up -d --force-recreate

health: ## Check health of all services
	@echo "=== Service Health ==="
	@docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Health}}"

env-check: ## Validate environment variables
	@test -f .env || (echo "ERROR: .env file not found. Copy .env.example to .env" && exit 1)
	@echo "Environment file exists"
	@grep -q "CHANGE_ME" .env && echo "WARNING: Default passwords detected in .env" || echo "Passwords look customized"
