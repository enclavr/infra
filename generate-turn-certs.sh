#!/bin/sh
# Generate self-signed TLS certificates for Coturn TURN server
# For production, replace with real certificates (e.g., from Let's Encrypt)
set -e

CERT_DIR="./certs/turn"
mkdir -p "$CERT_DIR"

if [ -f "$CERT_DIR/cert.pem" ] && [ -f "$CERT_DIR/key.pem" ]; then
  echo "Certificates already exist in $CERT_DIR"
  echo "Delete them and re-run to regenerate."
  exit 0
fi

DOMAIN="${DOMAIN:-localhost}"

openssl req -x509 -newkey rsa:4096 \
  -keyout "$CERT_DIR/key.pem" \
  -out "$CERT_DIR/cert.pem" \
  -days 365 -nodes \
  -subj "/CN=${DOMAIN}" \
  -addext "subjectAltName=DNS:${DOMAIN},DNS:localhost,IP:127.0.0.1"

chmod 600 "$CERT_DIR/key.pem"
chmod 644 "$CERT_DIR/cert.pem"

echo "TLS certificates generated in $CERT_DIR"
echo "  cert.pem: $CERT_DIR/cert.pem"
echo "  key.pem:  $CERT_DIR/key.pem"
echo ""
echo "For production, replace with real certificates from a trusted CA."
