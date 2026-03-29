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

### Core Services (Default)

| Service | Port | Description | Health Check |
|---------|------|-------------|--------------|
| postgres | 5432 (dev only) | PostgreSQL 18 database | `pg_isready` |
| redis | 6379 (dev only) | Redis 8 cache & pub/sub | `redis-cli ping` |
| server | 8080 (localhost) | Go backend API | `wget http://localhost:8080/health` |
| frontend | 80 (internal) | Next.js web UI (Nginx) | `wget http://localhost:80/` |

> **Note:** postgres and redis ports are only exposed in development mode (`docker-compose.override.yml`). In production, use `docker-compose.prod.yml` which maps frontend to `127.0.0.1:3000:80`.

### Optional Services (Profile-Gated)

| Service | Profile | Port | Description |
|---------|---------|------|-------------|
| coturn | `voice` | 3478, 5349 | TURN server for WebRTC NAT traversal |
| prometheus | `monitoring` | 9090 | Metrics collection (15d retention) |
| node-exporter | `monitoring` | 9100 | System metrics (CPU, memory, disk) |
| postgres-exporter | `monitoring` | 9187 | PostgreSQL metrics |
| redis-exporter | `monitoring` | 9121 | Redis metrics |
| grafana | `monitoring` | 3030→3000 | Metrics & logs visualization |
| alertmanager | `monitoring` | 9093 | Alert routing & notifications |
| loki | `monitoring` | 3100 | Log aggregation |
| alloy | `monitoring` | 12345 | Log collection agent |
| docker-socket-proxy | `monitoring` | 2375 | Restricted Docker API access |
| minio | `storage` | 9000, 9001 | S3-compatible object storage |
| minio-client | `storage` | - | Bucket initialization (runs once) |
| postgres-backup | `backup` | - | Automated database backups |
| caddy | `tls` | 80, 443 | Reverse proxy with auto HTTPS |
| watchtower | `maintenance` | - | Automated container updates |

### Profiles

```bash
docker compose up -d                          # Core services only
docker compose --profile monitoring up -d     # Core + monitoring
docker compose --profile voice up -d          # Core + TURN server
docker compose --profile storage up -d        # Core + MinIO storage
docker compose --profile backup up -d         # Core + automated backups
docker compose --profile tls up -d            # Core + TLS termination
docker compose --profile maintenance up -d    # Core + auto-updates
docker compose --profile full up -d           # All services
```

## Critical Security Settings

**Change before deployment:**
- `JWT_SECRET` - Generate: `openssl rand -base64 64`
- `POSTGRES_PASSWORD` / `DB_PASSWORD` - Strong password
- `ENCRYPTION_KEY` - Generate: `openssl rand -base64 32`
- `REDIS_PASSWORD` - Strong password
- `TURN_USER` / `TURN_PASS` - TURN credentials

## Resource Limits

| Service | Memory | CPU |
|---------|--------|-----|
| postgres | 512M (256M reserved) | - |
| redis | 256M (128M reserved) | - |
| server | 512M (256M reserved) | 1 core (0.5 reserved) |
| frontend | 256M (128M reserved) | - |
| coturn | 256M (128M reserved) | 1 core (0.5 reserved) |
| prometheus | 512M (256M reserved) | - |
| loki | 512M (256M reserved) | - |
| grafana | 256M (128M reserved) | - |
| alertmanager | 128M (64M reserved) | - |
| node-exporter | 128M (64M reserved) | - |
| postgres-exporter | 128M (64M reserved) | - |
| redis-exporter | 128M (64M reserved) | - |
| alloy | 256M (128M reserved) | - |
| docker-socket-proxy | 64M (32M reserved) | - |
| minio | 512M (256M reserved) | 1 core (0.5 reserved) |
| minio-client | 64M (32M reserved) | - |
| postgres-backup | 256M (128M reserved) | 0.5 core (0.25 reserved) |
| caddy | 128M (64M reserved) | - |
| watchtower | 64M (32M reserved) | - |

## Security Features

- `cap_drop: ALL` on all services with minimal `cap_add` per service
- `no-new-privileges: true` on all services
- Read-only filesystems on: redis, frontend, coturn, prometheus, node-exporter, grafana, alertmanager, loki, docker-socket-proxy, minio, watchtower
- Non-root users where applicable (server runs as UID 1000, postgres-backup as `backup` user)
- Resource limits on all services to prevent exhaustion
- Health checks with auto-restart on all services
- Three isolated networks: `frontend` (external), `backend` (internal), `monitoring` (internal)
- All secrets via environment variables (`.env` excluded from version control)

## Persistent Data

Back up these volumes regularly:

| Volume | Description | Backup |
|--------|-------------|--------|
| `postgres_data` | PostgreSQL database files | Yes |
| `server_uploads` | Uploaded files | Yes |
| `grafana_data` | Grafana dashboards and settings | Yes |
| `minio_data` | MinIO object storage data | Yes |
| `backup_data` | PostgreSQL backup archives | Yes |
| `redis_data` | Redis cache and pub/sub data | No |
| `prometheus_data` | Prometheus metrics data | No |
| `loki_data` | Loki log data | No |
| `alertmanager_data` | Alertmanager data | No |
| `caddy_data` | Caddy TLS certificates and data | No |
| `caddy_config` | Caddy configuration cache | No |

## Makefile Commands

```bash
make help           # Show all available commands
make up             # Start core services
make down           # Stop all services
make status         # Show service status
make logs           # Follow logs
make validate       # Validate docker-compose config
make monitoring     # Start with monitoring stack
make voice          # Start with voice (coturn)
make storage        # Start with MinIO
make full           # Start all services
make dev            # Development mode (hot reload)
make prod           # Production mode (all profiles + TLS)
make db-shell       # Open PostgreSQL shell
make redis-shell    # Open Redis CLI
make pg-backup      # Create manual backup
make health         # Check health of all services
```

## Troubleshooting

**Services won't start:** `docker compose logs <service-name>` - check port conflicts, permissions, missing .env

**Database errors:** `docker compose ps postgres` then `docker compose logs postgres`

**Redis errors:** `docker compose exec redis redis-cli ping`

**TURN issues:** Verify credentials match. Test: `turnutils_uclient -p 3478 -u enclavr -w enclavr -t 30s`

## CI/CD

GitHub Actions (`.github/workflows/ci.yml`):
- **validate**: Docker Compose config validation (`docker compose config`)
- **security**: Trivy vulnerability scanner (config scan, SARIF output to GitHub Security tab)

Triggers: push to main, pull requests, weekly schedule (Sunday midnight UTC).

```bash
act push              # Run all CI jobs
act -j validate       # Run specific job
act -j security       # Run Trivy scan
```

## Architecture

```
                    ┌─────────────┐
                    │   Caddy     │ (profile: tls)
                    │  :80/:443   │
                    └──────┬──────┘
                           │
┌─────────────┐     ┌──────┴──────┐
│   coturn    │──── │  frontend   │
│  :3478/:5349│     │   (Nginx)   │
└─────────────┘     └──────┬──────┘
                           │
                    ┌──────┴──────┐
                    │   server    │
                    │   (Go)      │
                    └──┬──────┬───┘
                       │      │
              ┌────────┘      └────────┐
              │                        │
       ┌──────┴──────┐         ┌───────┴──────┐
       │  postgres   │         │    redis     │
       │     :5432   │         │    :6379     │
       └─────────────┘         └──────────────┘

Monitoring (profile: monitoring):
  prometheus ← node-exporter, postgres-exporter, redis-exporter
       ↓
  grafana ← loki ← alloy ← docker-socket-proxy
       ↓
  alertmanager

Storage (profile: storage): minio ← minio-client
Backup (profile: backup): postgres-backup → postgres
Maintenance (profile: maintenance): watchtower
```

## License

See [LICENSE](./LICENSE).
