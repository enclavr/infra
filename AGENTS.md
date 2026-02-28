# Enclavr Infra - Agent Instructions

## Build & Deploy

```bash
docker-compose up -d          # Start all services
docker-compose down           # Stop all services
docker-compose logs -f        # View logs
docker-compose ps            # Check status
```

## Services

| Service | Port | Description |
|---------|------|-------------|
| postgres | 5432 | PostgreSQL database |
| redis | 6379 | Redis for pub/sub |
| server | 8080 | Go backend API |
| frontend | 3000 | Next.js web UI |
| coturn | 3478 | TURN server for WebRTC |

## Environment

Copy `.env.example` to `.env` and configure:
- Database credentials
- JWT secret
- OIDC settings (optional)
- STUN/TURN servers for voice

## CI/CD

The CI workflow is in `.github/workflows/ci.yml` and runs:
- Docker Compose validation
- Hadolint Dockerfile linting
- Trivy security scan

### Running Locally with `act`

```bash
# Run all CI jobs
act push

# Run specific job
act -j validate

# Dry run
act --dryrun push
```

### Fixing CI Failures

When CI breaks:
1. Run `act push` locally to reproduce
2. Fix the actual issue, not the workflow file
3. Run `docker compose config` to validate
4. Commit and push

## Important Notes

- This repo is for deployment infrastructure only
- Frontend and server are separate repositories
- All code changes happen in their respective repos
