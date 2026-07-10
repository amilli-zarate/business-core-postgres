#!/usr/bin/env bash

set -e

TEST_DB="business_core_test"
DB_USER="${1:-postgres}"

for test_file in tests/[0-9][0-9]_*; do
    echo "Running $test_file"

    case "$test_file" in
        *.sh)
            bash "$test_file" "$DB_USER"
            ;;

        *.sql)
            psql \
                --username="$DB_USER" \
                --dbname="$TEST_DB" \
                --set=ON_ERROR_STOP=1 \
                --file="$test_file"
            ;;
    esac
done

echo "All tests passed."