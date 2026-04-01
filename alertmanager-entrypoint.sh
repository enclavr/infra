#!/bin/sh
set -e

# Build optional SMTP global config
SMTP_CONFIG=""
if [ -n "${ALERTMANAGER_SMTP_HOST:-}" ]; then
  SMTP_CONFIG="smtp_smarthost: '${ALERTMANAGER_SMTP_HOST}:${ALERTMANAGER_SMTP_PORT:-587}'
  smtp_from: '${ALERTMANAGER_SMTP_FROM}'
  smtp_auth_username: '${ALERTMANAGER_SMTP_USERNAME}'
  smtp_auth_password: '${ALERTMANAGER_SMTP_PASSWORD}'
  smtp_require_tls: ${ALERTMANAGER_SMTP_REQUIRE_TLS:-true}"
fi

# Build optional email config for critical receiver
EMAIL_CONFIG=""
if [ -n "${ALERTMANAGER_SMTP_HOST:-}" ]; then
  EMAIL_CONFIG="email_configs:
      - to: '${ALERTMANAGER_CRITICAL_EMAIL:-${ALERTMANAGER_SMTP_FROM}}'
        from: '${ALERTMANAGER_SMTP_FROM}'
        smarthost: '${ALERTMANAGER_SMTP_HOST}:${ALERTMANAGER_SMTP_PORT:-587}'
        auth_username: '${ALERTMANAGER_SMTP_USERNAME}'
        auth_password: '${ALERTMANAGER_SMTP_PASSWORD}'
        require_tls: ${ALERTMANAGER_SMTP_REQUIRE_TLS:-true}
        send_resolved: true"
fi

# Default critical webhook URL to the default webhook URL if not set
export ALERTMANAGER_CRITICAL_WEBHOOK_URL="${ALERTMANAGER_CRITICAL_WEBHOOK_URL:-$ALERTMANAGER_WEBHOOK_URL}"

export ALERTMANAGER_SMTP_CONFIG="${SMTP_CONFIG}"
export ALERTMANAGER_EMAIL_CONFIG="${EMAIL_CONFIG}"

# Generate alertmanager config from template using envsubst
# Prometheus template syntax uses {{ }} so $ substitution is safe
envsubst < /etc/alertmanager/alertmanager.yml.template > /etc/alertmanager/alertmanager.yml

exec /bin/alertmanager "$@"
