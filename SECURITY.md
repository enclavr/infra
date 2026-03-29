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

- **Container Security:** All containers run with `cap_drop: ALL`, `no-new-privileges: true`, read-only filesystems where possible, non-root users
- **Network Isolation:** Three isolated Docker bridge networks (frontend external, backend internal, monitoring internal) with no cross-network access except through defined service dependencies
- **Secrets Management:** All secrets via environment variables, `.env` files excluded from version control, `.env.example` templates provided
- **TLS/HTTPS:** Optional HTTPS via Caddy with Let's Encrypt (available via `--profile tls`, not enabled by default), TLS termination at reverse proxy
- **Database Security:** PostgreSQL with password authentication, connection limits, no external port exposure
- **Redis Security:** Password authentication, no external port exposure, internal network only
- **TURN Server:** Coturn with credential-based authentication, relay-only mode, no open relay
- **Vulnerability Scanning:** Trivy container scanner in CI pipeline with SARIF output to GitHub Security tab
- **Image Updates:** Watchtower for automated container image updates (available via `--profile maintenance`, not enabled by default)
- **Backup Security:** Automated PostgreSQL backups with encryption and retention policies (available via `--profile backup`, not enabled by default)
- **Monitoring Security:** Grafana with password authentication, Prometheus and Loki on internal network only (available via `--profile monitoring`, not enabled by default)

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

| Network | Purpose | External Access |
|---------|---------|-----------------|
| frontend | User-facing services (Caddy, frontend) | Yes (ports 80, 443) |
| backend | Internal services (server, postgres, redis) | No |
| monitoring | Observability stack (prometheus, grafana, loki) | No |

## Dependency Security

- Base images pinned to specific versions (Alpine-based for minimal attack surface)
- Trivy vulnerability scanning in CI
- Automated image updates via Watchtower (optional)
- Regular manual review of image updates

## Disclosure Policy

See the [root repository SECURITY.md](https://github.com/enclavr/enclavr/blob/main/SECURITY.md) for the full disclosure policy.

## Safe Harbor

We support safe harbor for security researchers who follow responsible disclosure practices. See the [root repository SECURITY.md](https://github.com/enclavr/enclavr/blob/main/SECURITY.md) for details.
