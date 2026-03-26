#!/bin/sh
set -e

BACKUP_DIR="/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/enclavr_${TIMESTAMP}.sql.gz"
RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-7}

echo "[$(date)] Starting PostgreSQL backup..."

pg_dumpall \
  -h "${DB_HOST:-postgres}" \
  -p "${DB_PORT:-5432}" \
  -U "${DB_USER:-enclavr}" \
  --clean \
  --if-exists | gzip > "${BACKUP_FILE}"

BACKUP_SIZE=$(du -h "${BACKUP_FILE}" | cut -f1)
echo "[$(date)] Backup completed: ${BACKUP_FILE} (${BACKUP_SIZE})"

echo "[$(date)] Cleaning up backups older than ${RETENTION_DAYS} days..."
find "${BACKUP_DIR}" -name "enclavr_*.sql.gz" -mtime +${RETENTION_DAYS} -delete 2>/dev/null || true

REMAINING=$(ls -1 "${BACKUP_DIR}"/enclavr_*.sql.gz 2>/dev/null | wc -l)
echo "[$(date)] Cleanup complete. ${REMAINING} backup(s) remaining."
