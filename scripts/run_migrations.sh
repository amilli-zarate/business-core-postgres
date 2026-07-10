#!/usr/bin/env bash

set -euo pipefail

DB_USER="${1:-postgres}"
DB_NAME="${2:-business_core_dev}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for migration in "$ROOT_DIR"/sql/migrations/V*.sql; do
    echo "Applying $(basename "$migration")"

    psql \
        --username="$DB_USER" \
        --dbname="$DB_NAME" \
        --set=ON_ERROR_STOP=1 \
        --file="$migration"
done

echo "SUCCESS: all migrations applied to $DB_NAME."