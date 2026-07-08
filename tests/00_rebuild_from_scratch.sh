#!/usr/bin/env bash
set -euo pipefail

TEST_DB="business_core_test"
DB_USER="${DB_USER:-postgres}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

dropdb -U "$DB_USER" --if-exists "$TEST_DB"
createdb -U "$DB_USER" "$TEST_DB"

for migration in "$ROOT_DIR"/sql/migrations/V*.sql; do
    echo "Applying $(basename "$migration")"
    psql -U "$DB_USER" -v ON_ERROR_STOP=1 -d "$TEST_DB" -f "$migration"
done

echo "SUCCESS: rebuilt $TEST_DB from scratch."