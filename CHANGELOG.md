# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [0.1.0] - 2026-03-29

### Added

- Initial release of Enclavr infrastructure configuration.
- Docker Compose deployment for core services: PostgreSQL 18, Redis 8, Go server, Next.js frontend.
- Optional profiles: monitoring, voice, storage, backup, tls, maintenance, full.
- Monitoring stack: Prometheus, Grafana, Loki, Alertmanager, Alloy, exporters.
- MinIO S3-compatible object storage with bucket initialization.
- Automated PostgreSQL backups with cron scheduling and retention.
- Caddy reverse proxy with automatic HTTPS via Let's Encrypt.
- Watchtower for automated container updates.
- Coturn TURN server for WebRTC NAT traversal.
- Docker Socket Proxy for restricted Docker API access.
- Environment configuration template (`.env.example`).
- CI/CD workflow for Docker Compose validation and Trivy security scanning.
- Dependabot configuration for Docker Compose, Docker, and GitHub Actions.
- Makefile for common operations.
- GitHub community files: LICENSE, CONTRIBUTING, CODE_OF_CONDUCT, issue/PR templates.

### Security

- All containers run with `cap_drop: ALL` and `no-new-privileges: true`.
- Read-only filesystems on non-data services.
- Three isolated networks (frontend, backend, monitoring).
- Resource limits on all services.
- Non-root users where applicable.
