.PHONY: help up down restart logs status build validate clean
.PHONY: monitoring voice backup tls storage full
.PHONY: debugging migration
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
	docker compose up -d

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
	docker compose --profile monitoring up -d

voice: ## Start with voice (coturn)
	docker compose --profile voice up -d

backup: ## Start with backup service
	docker compose --profile backup up -d

tls: ## Start with TLS (Caddy)
	docker compose --profile tls up -d

storage: ## Start with MinIO object storage
	docker compose --profile storage up -d

debugging: ## Start with debugging tools (Redis Commander)
	docker compose --profile debugging up -d

migration: ## Run database migrations
	docker compose --profile migration up -d

full: ## Start all services
	docker compose --profile full up -d

# ============================================
# Development
# ============================================

dev: ## Start in development mode (with hot reload)
	docker compose up -d

prod: ## Start in production mode (all profiles)
	docker compose -f docker-compose.yml -f docker-compose.prod.yml --profile full --profile tls up -d

# ============================================
# Database Operations
# ============================================

db-shell: ## Open PostgreSQL shell
	docker compose exec postgres psql -U $$(grep POSTGRES_USER .env | cut -d= -f2) -d $$(grep POSTGRES_DB .env | cut -d= -f2)

redis-shell: ## Open Redis CLI
	docker compose exec redis redis-cli -a $$(grep REDIS_PASSWORD .env | cut -d= -f2) 2>/dev/null || docker compose exec redis redis-cli

pg-backup: ## Create manual PostgreSQL backup
	docker compose exec postgres pg_dumpall -U $$(grep POSTGRES_USER .env | cut -d= -f2) | gzip > backup_$$(date +%Y%m%d_%H%M%S).sql.gz

pg-restore: ## Restore PostgreSQL from backup (usage: make pg-restore FILE=backup.sql.gz)
	gunzip -c $(FILE) | docker compose exec -T postgres psql -U $$(grep POSTGRES_USER .env | cut -d= -f2)

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
