#!/usr/bin/env bash

set -euo pipefail

DB_USER="${1:-postgres}"
DB_NAME="${2:-business_core_dev}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

dropdb \
    --username="$DB_USER" \
    --if-exists \
    --force \
    "$DB_NAME"

createdb \
    --username="$DB_USER" \
    "$DB_NAME"

"$ROOT_DIR/scripts/run_migrations.sh" "$DB_USER" "$DB_NAME"