---
name: enclavr-infra
description: Infrastructure agent for Enclavr - Docker Compose deployment
---

# Enclavr Infrastructure

DevOps engineer for the Enclavr voice chat platform.

> For shared tools (MCP, GitHub CLI, Sentry, Git), see [root AGENTS.md](../AGENTS.md).

## Tech Stack

- **Container Runtime:** Docker
- **Orchestration:** Docker Compose v2
- **Database:** PostgreSQL 18 (Alpine) - PGDATA=/var/lib/postgresql/18/docker
- **Cache/PubSub:** Redis 8 (Alpine)
- **Voice:** Coturn (TURN server for WebRTC)
- **CI/CD:** GitHub Actions

## Commands

```bash
docker compose up -d          # Start all services
docker compose down           # Stop all services
docker compose logs -f        # View logs
docker compose ps             # Check status
docker compose config         # Validate config
docker compose build          # Build images
docker compose restart        # Restart services
```

## Services

| Service | Port | Description | Health Check |
|---------|------|-------------|--------------|
| postgres | 5432 | PostgreSQL 18 database | `pg_isready` |
| redis | 6379 | Redis 8 cache & pub/sub | `redis-cli ping` |
| server | 8080 | Go backend API | Depends on postgres/redis |
| frontend | 3000 | Next.js web UI (Nginx) | HTTP GET / |
| coturn | 3478 | TURN server for WebRTC | TCP port check |

## Environment Configuration

Copy `.env.example` to `.env`. Critical settings to change:
- `JWT_SECRET` - Generate: `openssl rand -base64 64`
- `POSTGRES_PASSWORD` / `DB_PASSWORD` - Strong password
- `TURN_USER` / `TURN_PASS` - TURN credentials

## CI/CD

Workflow: `.github/workflows/ci.yml`
- Docker Compose validation
- Hadolint Dockerfile linting
- Trivy security scan

```bash
act push              # Run all CI jobs
act -j validate       # Run specific job
```

## Standards

- Use Alpine-based images
- Configure health checks for all services
- Use named volumes for persistent data
- Externalize configuration via environment variables

## Boundaries

- Validate docker-compose config before pushing
- Use environment variables for secrets
- Document new env vars in .env.example
- Never commit secrets to .env files
- Auto commit and push changes

## Proactive Work

Every task should do BOTH:
1. **MAINTENANCE:** Fix configs, improve health checks, security hardening
2. **NEW FEATURE:** Add services, monitoring, logging, networking improvements
