# Security Policy - Infrastructure

This document covers the security policy for the Enclavr infrastructure (Docker Compose deployment).

## Reporting a Vulnerability

**Do NOT report security vulnerabilities through public GitHub issues.**

- **GitHub Private Vulnerability Reporting:** Use the ["Report a vulnerability"](https://github.com/enclavr/infra/security/advisories/new) button in the Security tab.
- **Email:** Send details to `enclavr.dev@gmail.com`

For cross-cutting concerns affecting multiple components, report to the [root repository](https://github.com/enclavr/enclavr/security/advisories/new).

### What to Include

- Description of the vulnerability
- Affected service(s) (PostgreSQL, Redis, Caddy, Coturn, monitoring stack, etc.)
- Network exposure context (external vs internal bridge)
- Steps to reproduce
- Potential impact (container escape, secrets exposure, network compromise, etc.)
- Suggested fix (if any)

### Response Timeline

| Stage | Timeline |
|-------|----------|
| Acknowledgement | Within 48 hours |
| Initial triage | Within 5 business days |
| Fix/patch target | 30 days (varies by severity) |

## Supported Versions

| Version | Supported |
|---------|-----------|
| Latest release | Yes |
| Previous release | Security fixes only |
| Older releases | No |

## Security Considerations

Infrastructure security covers the deployment and runtime environment:

- **Container Security:** All containers run with `cap_drop: ALL` and `no-new-privileges: true`. Read-only filesystems are enabled on: redis, frontend, coturn, prometheus, node-exporter, grafana, alertmanager, loki, docker-socket-proxy, minio, and watchtower. Services requiring write access (postgres for data, server for uploads, postgres-exporter, redis-exporter, alloy, minio-client, postgres-backup, caddy) use standard filesystems. Server runs as non-root user (UID 1000).
- **Network Isolation:** Three Docker bridge networks with network segmentation:
  - `frontend` (external-facing) - frontend, coturn, caddy, server
  - `backend` (internal only) - server, postgres, redis, minio, exporters
  - `monitoring` (internal only) - prometheus, grafana, loki, alertmanager, alloy, exporters
  - Some services like server span multiple networks by design for inter-service communication
- **Secrets Management:** All secrets via environment variables, `.env` files excluded from version control, `.env.example` templates provided
- **TLS/HTTPS:** Optional HTTPS via Caddy with Let's Encrypt (available via `--profile tls`, not enabled by default), TLS termination at reverse proxy
- **Database Security:** PostgreSQL with password authentication, connection limits, no external port exposure in base configuration
- **Redis Security:** Password authentication, no external port exposure, internal network only, read-only filesystem
- **TURN Server:** Coturn with credential-based authentication, relay-only mode, no open relay (available via `--profile voice`, not enabled by default)
- **Vulnerability Scanning:** Trivy security config scanner in CI pipeline with SARIF output to GitHub Security tab
- **Image Updates:** Watchtower for automated container image updates (available via `--profile maintenance`, not enabled by default). Only updates containers with `com.centurylinklabs.watchtower.enable=true` label.
- **Backup Security:** Automated PostgreSQL backups with gzip compression and configurable retention (available via `--profile backup`, not enabled by default)
- **Monitoring Security:** Grafana with password authentication, Prometheus and Loki on internal network only (available via `--profile monitoring`, not enabled by default)
- **Object Storage:** MinIO with password authentication, read-only filesystem (available via `--profile storage`, not enabled by default)

## Container Hardening

```yaml
# Applied to all services
security_opt:
  - no-new-privileges:true
cap_drop:
  - ALL
# Per-service capabilities added only as needed
```

## Network Architecture

| Network | Purpose | Internal | External Access |
|---------|---------|----------|-----------------|
| frontend | User-facing services (frontend, coturn, caddy, server) | No | Yes (ports 80, 443 only with `--profile tls`) |
| backend | Database, cache, storage (server, postgres, redis, minio) | Yes | No |
| monitoring | Observability stack (prometheus, grafana, loki, alertmanager, alloy) | Yes | No |

## Dependency Security

- Base images pinned to specific versions (Alpine-based for minimal attack surface)
- Trivy security configuration scanning in CI
- Dependabot for automated dependency updates (Docker images, Docker Compose, GitHub Actions)
- Automated image updates via Watchtower (optional)
- Regular manual review of image updates

## Disclosure Policy

See the [root repository SECURITY.md](https://github.com/enclavr/enclavr/blob/main/SECURITY.md) for the full disclosure policy.

## Safe Harbor

We support safe harbor for security researchers who follow responsible disclosure practices. See the [root repository SECURITY.md](https://github.com/enclavr/enclavr/blob/main/SECURITY.md) for details.
