# Enclavr Infrastructure - Agent Instructions

## Overview

This repository contains production-ready deployment infrastructure for Enclavr:

- **Docker Compose** orchestration for all services
- **Security hardened** configurations (non-root users, resource limits)
- **Health checks** for all services
- **Environment templates** with comprehensive documentation

## Quick Start

```bash
# 1. Clone submodules if not already present
git submodule update --init --recursive

# 2. Configure environment
cp .env.example .env
# Edit .env and change all default passwords and secrets

# 3. Start all services
docker compose up -d

# 4. Check status
docker compose ps

# 5. View logs
docker compose logs -f

# 6. Stop all services
docker compose down
```

## Services

| Service | Port | Description | Health Check |
|---------|------|-------------|--------------|
| postgres | 5432 | PostgreSQL 18 database | `pg_isready` |
| redis | 6379 | Redis 8 cache & pub/sub | `redis-cli ping` |
| server | 8080 | Go backend API | Depends on postgres/redis |
| frontend | 3000 | Next.js web UI (Nginx) | HTTP GET / |
| coturn | 3478 | TURN server for WebRTC | TCP port check |

## Environment Variables

All configuration is externalized via environment variables. See [`.env.example`](./.env.example) for complete list with descriptions.

### Critical Security Settings

**Change these before deployment:**
- `JWT_SECRET` - Generate strong random secret: `openssl rand -base64 64`
- `POSTGRES_PASSWORD` - Use strong password
- `DB_PASSWORD` - Should match `POSTGRES_PASSWORD`
- `TURN_USER` / `TURN_PASS` - TURN server credentials
- `ADMIN_PASSWORD` - Set to create default admin user

### Admin User Configuration

The server automatically creates an admin user on first startup:

| Variable | Description |
|----------|-------------|
| `ADMIN_USERNAME` | Admin username (default: admin) |
| `ADMIN_PASSWORD` | Admin password - **set this to create default admin** |
| `ADMIN_EMAIL` | Admin email (default: admin@enclavr.local) |
| `FIRST_USER_IS_ADMIN` | First registered user becomes admin (default: true) |

**Quick Setup:**
```bash
# Set admin password in .env
ADMIN_PASSWORD=your-secure-password
```

On first server start, the admin user is created automatically.

### Production Recommendations

1. **Enable SSL** for database: set `DB_SSLMODE=require`
2. **Configure TURN** with proper credentials and TLS certificates
3. **Set ALLOWED_ORIGINS** to your frontend URL(s)
4. **Use secrets manager** (Vault, AWS Secrets Manager, etc.) instead of .env files
5. **Rotate secrets** regularly
6. **Enable authentication audit logging** on sensitive services

## Resource Limits

Each service has configured resource limits for production stability:

| Service | Memory Limit | Memory Reservation | CPU Limit | CPU Reservation |
|---------|--------------|-------------------|-----------|-----------------|
| postgres | 512M | 256M | - | - |
| redis | 256M | 128M | - | - |
| server | 512M | 256M | 1 core | 0.5 core |
| frontend | 256M | 128M | - | - |
| coturn | 256M | 128M | 1 core | 0.5 core |

These can be adjusted in `docker-compose.yml` under `deploy.resources`.

## Health Checks

All services include health checks with appropriate start periods:

- **postgres**: `pg_isready` checks database readiness
- **redis**: `redis-cli ping` verifies Redis is responding
- **frontend**: HTTP GET `/` checks Nginx is serving content
- **coturn**: TCP connection check on port 3478

Services have `depends_on` conditions to ensure proper startup order.

## Security Features

### Non-Root Users

- **Postgres**: Runs as `postgres` user (default in official image)
- **Redis**: Runs as `redis` user (default in official image)
- **Server**: Runs as UID 1000 (`enclavr` user)
- **Frontend**: Nginx runs as `nginx` user (default in official image)
- **Coturn**: Runs as `coturn` user (default in official image)

### Additional Security

- All services have `restart: unless-stopped` for resilience
- Resource limits prevent resource exhaustion attacks
- Health checks detect and restart unhealthy containers
- Named volumes for persistent data isolation
- Network isolation via custom bridge network

## Persistent Data

Important data is stored in named volumes:

- `postgres_data` - PostgreSQL database files
- `redis_data` - Redis persistence (AOF)
- `turn_data` - Coturn credentials and state
- `server_uploads` - Uploaded files (avatars, attachments)

Back up these volumes regularly.

## Troubleshooting

### Services won't start

Check logs: `docker compose logs <service-name>`

Common issues:
- **Port conflicts**: Ensure ports 5432, 6379, 8080, 3000, 3478 are free
- **Permission errors**: Ensure user has permission to access volumes
- **Missing .env file**: Copy `.env.example` to `.env` first

### Database connection errors

Ensure postgres is healthy: `docker compose ps postgres`
Check postgres logs: `docker compose logs postgres`

### Redis connection errors

Verify redis is running: `docker compose ps redis`
Check redis health: `docker compose exec redis redis-cli ping`

### Server can't connect to database

Check environment variables in `.env` match between postgres and server sections.

### TURN server not working

Verify TURN credentials in `.env` match what's configured in Coturn.
Test with TURN client: `turnutils_uclient -p 3478 -u enclavr -w enclavr -t 30s`

## CI/CD

The infra repository includes GitHub Actions CI that runs on:
- Push to main branch (when docker-compose.yml or .env files change)
- Pull requests
- Weekly schedule (Sunday midnight UTC)

CI jobs:
- **validate**: Docker Compose config validation, Dockerfile linting with Hadolint
- **security**: Trivy vulnerability scanning

### Running CI Locally

```bash
# Install act
curl -Ls https://raw.githubusercontent.com/nektos/act/master/install.sh | sh

# Run CI jobs
act push

# Run specific job
act -j validate
```

## Architecture

```
┌─────────────┐
│   coturn    │  (TURN server for voice)
└──────┬──────┘
       │
┌──────┴──────┐     ┌─────────────┐
│   frontend   │────▶│   server    │
│  (Next.js)   │     │    (Go)     │
└──────┬──────┘     └──────┬──────┘
       │                    │
       │              ┌─────┴─────┐
       │              │           │
       │         ┌────▼────┐  ┌───▼───┐
       │         │postgres │  │ redis │
       │         └─────────┘  └────────┘
       │
       ▼
    (Browser)
```

## Submodules

This repo references external repositories:

- **Frontend**: https://github.com/enclavr/frontend
- **Server**: https://github.com/enclavr/server

Update submodules: `git submodule update --remote`

## Memory Bank

See `memory-bank/` directory for project context, progress tracking, and decision records.

- `activeContext.md` - Current work focus and latest changes
- `progress.md` - What works, what's left to build
- `productContext.md` - Product purpose and features
- `projectbrief.md` - Project goals and requirements
- `systemPatterns.md` - Code patterns and conventions
- `techContext.md` - Technologies and CLI commands

## Support

For issues, questions, or contributions, please use the main Enclavr repository: https://github.com/enclavr/enclavr
