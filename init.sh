#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CERT_DIR="$SCRIPT_DIR/certs"
ACME_FILE="$CERT_DIR/acme.json"

echo "Initializing ..."

# Create certificates directory
mkdir -p "$CERT_DIR"

# Initialize ACME storage
if [[ ! -e "$ACME_FILE" ]]; then
    touch "$ACME_FILE"
    echo "Created certs/acme.json"
elif [[ ! -f "$ACME_FILE" ]]; then
    echo "Error: acme.json exists but is not a regular file"
    exit 1
fi

chmod 600 "$ACME_FILE"

echo "ACME storage permissions: 600"
echo "Traefik initialization completed."
