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

## Important Notes

- This repo is for deployment infrastructure only
- Frontend and server are separate repositories
- All code changes happen in their respective repos
