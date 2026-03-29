# Enclavr Infrastructure

Production-ready Docker Compose deployment for Enclavr.

## Quick Start

```bash
cp .env.example .env
# Edit .env and change all default passwords/secrets
docker compose up -d
docker compose ps          # Check status
docker compose logs -f     # View logs
```

## Services

| Service | Port | Description | Health Check |
|---------|------|-------------|--------------|
| postgres | 5432 | PostgreSQL 18 database | `pg_isready` |
| redis | 6379 | Redis 8 cache & pub/sub | `redis-cli ping` |
| server | 8080 | Go backend API | Depends on postgres/redis |
| frontend | 3000 | Next.js web UI (Nginx) | HTTP GET / |
| coturn | 3478 | TURN server for WebRTC | TCP port check |

## Critical Security Settings

**Change before deployment:**
- `JWT_SECRET` - Generate: `openssl rand -base64 64`
- `POSTGRES_PASSWORD` / `DB_PASSWORD` - Strong password
- `TURN_USER` / `TURN_PASS` - TURN credentials

## Resource Limits

| Service | Memory | CPU |
|---------|--------|-----|
| postgres | 512M (256M reserved) | - |
| redis | 256M (128M reserved) | - |
| server | 512M (256M reserved) | 1 core (0.5 reserved) |
| frontend | 256M (128M reserved) | - |
| coturn | 256M (128M reserved) | 1 core (0.5 reserved) |

## Security Features

- Non-root users for all services
- Resource limits to prevent exhaustion
- Health checks with auto-restart
- Named volumes for data isolation
- Network isolation via bridge network

## Persistent Data

Back up these volumes regularly:
- `postgres_data` - Database files
- `redis_data` - Redis persistence (AOF)
- `server_uploads` - Uploaded files

## Troubleshooting

**Services won't start:** `docker compose logs <service-name>` - check port conflicts, permissions, missing .env

**Database errors:** `docker compose ps postgres` then `docker compose logs postgres`

**Redis errors:** `docker compose exec redis redis-cli ping`

**TURN issues:** Verify credentials match. Test: `turnutils_uclient -p 3478 -u enclavr -w enclavr -t 30s`

## CI/CD

GitHub Actions (`.github/workflows/ci.yml`): Docker Compose validation, Trivy security scan.

```bash
act push              # Run all CI jobs
act -j validate       # Run specific job
```

## Architecture

```
coturn (TURN) <---> frontend (Next.js) ---> server (Go)
                                              |      |
                                          postgres  redis
```

## License

See [LICENSE](./LICENSE).
