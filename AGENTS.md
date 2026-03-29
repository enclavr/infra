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
| postgres | 5432 | PostgreSQL 18 database | `pg_isready` + query check |
| redis | 6379 | Redis 8 cache & pub/sub | `redis-cli ping` + write check |
| server | 8080 | Go backend API | Depends on postgres/redis |
| frontend | 3000 | Next.js web UI (Nginx) | HTTP GET / |
| coturn | 3478 | TURN server for WebRTC | TCP port check |
| uptime-kuma | 3001 | Uptime monitoring & status pages | HTTP GET / |
| redis-commander | 8081 | Redis management UI | HTTP GET / |
| db-migrate | - | Database migration runner | Runs on startup |

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

## GitHub Security (via `gh api`)

The `gh` CLI has NO dedicated security commands. Use `gh api` for all security operations.

### Dependabot Alerts
```bash
# List open Dependabot alerts
gh api repos/enclavr/infra/dependabot/alerts --jq '.[] | {number, state, severity, package: .security_advisory.summary}'

# Get alert details
gh api repos/enclavr/infra/dependabot/alerts/ALERT_NUMBER

# Dismiss an alert
gh api -X PATCH repos/enclavr/infra/dependabot/alerts/ALERT_NUMBER -f state=dismissed -f dismissed_reason=no_fix_available
```

### Code Scanning Alerts
```bash
# List code scanning alerts (Trivy results)
gh api repos/enclavr/infra/code-scanning/alerts --jq '.[] | {number, state, rule: .rule.id, severity: .rule.severity}'

# Dismiss a false positive
gh api -X PATCH repos/enclavr/infra/code-scanning/alerts/ALERT_NUMBER -f state=dismissed -f dismissed_reason=false_positive
```

### Secret Scanning
```bash
# List secret scanning alerts
gh api repos/enclavr/infra/secret-scanning/alerts
```

### Dependabot Configuration
Dependabot is configured in `.github/dependabot.yml`:
- **docker-compose**: weekly Wednesday, grouped by monitoring-stack/databases/observability
- **Docker**: weekly Wednesday
- **GitHub Actions**: weekly Monday, grouped

**Security workflow:** Check alerts -> Update Docker images -> Run `docker compose config` -> Commit -> Push

## Git Push Policy

**ALWAYS keep git commits up to date on the remote.** After every commit, push immediately: `git push origin main`. Never leave local-only commits.
