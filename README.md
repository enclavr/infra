# Enclavr Infra - Agent Instructions

## Overview

This repository contains deployment infrastructure for Enclavr:
- Docker Compose configuration
- Environment templates

## Build & Deploy

```bash
# Start all services
docker-compose up -d

# Start with custom env
cp .env.example .env
docker-compose up -d

# View logs
docker-compose logs -f

# Stop all services
docker-compose down
```

## Services

| Service | Port | Description |
|---------|------|-------------|
| postgres | 5432 | PostgreSQL database |
| redis | 6379 | Redis for pub/sub |
| server | 8080 | Go backend API |
| frontend | 3000 | Next.js web UI |
| coturn | 3478 | TURN server for WebRTC |

## Environment Variables

See `.env.example` for all available configuration options.

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
