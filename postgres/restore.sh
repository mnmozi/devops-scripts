#!/bin/bash

set -e

# === Required Environment Variables ===
# PG_HOST        - PostgreSQL host
# PG_USER        - PostgreSQL user
# PG_DATABASE    - Target database name
# DUMP_FILE      - Path to dump file
#
# === Optional Environment Variables ===
# PG_PORT        - PostgreSQL port (default: 5432)
# PG_PASSWORD    - PostgreSQL password (required if PGPASSWORD not set)
# CLEAN_RESTORE  - Drop objects before restore (default: false)
# CREATE_DB      - Create database if not exists (default: true)
# TARGET_TABLE   - Table to update after restore (optional)
# TARGET_COLUMN  - Column to clear (optional)
# CLEAR_VALUE    - Value to set: NULL or '' (default: NULL)

# Validate required env vars
for var in PG_HOST PG_USER PG_DATABASE DUMP_FILE; do
    if [[ -z "${!var}" ]]; then
        echo "Error: $var is not set"
        exit 1
    fi
done

PG_PORT="${PG_PORT:-5432}"
CLEAN_RESTORE="${CLEAN_RESTORE:-false}"
CREATE_DB="${CREATE_DB:-true}"
CLEAR_VALUE="${CLEAR_VALUE:-NULL}"

# Set password if provided
[[ -n "$PG_PASSWORD" ]] && export PGPASSWORD="$PG_PASSWORD"

if [[ -z "$PGPASSWORD" ]]; then
    echo "Error: PGPASSWORD or PG_PASSWORD must be set"
    exit 1
fi

if [[ ! -f "$DUMP_FILE" ]]; then
    echo "Error: Dump file not found: $DUMP_FILE"
    exit 1
fi

# Create database if needed
if [[ "$CREATE_DB" == "true" ]]; then
    psql -U "$PG_USER" -h "$PG_HOST" -p "$PG_PORT" -tc \
        "SELECT 1 FROM pg_database WHERE datname = '$PG_DATABASE'" | grep -q 1 || \
        createdb -U "$PG_USER" -h "$PG_HOST" -p "$PG_PORT" "$PG_DATABASE"
fi

# Build restore options
RESTORE_OPTS="--verbose"
[[ "$CLEAN_RESTORE" == "true" ]] && RESTORE_OPTS="$RESTORE_OPTS --clean --if-exists"

echo "Restoring database: $PG_DATABASE from $DUMP_FILE"
pg_restore -U "$PG_USER" -h "$PG_HOST" -p "$PG_PORT" -d "$PG_DATABASE" $RESTORE_OPTS "$DUMP_FILE"

echo "Restore complete"

# Clear column if configured
if [[ -n "$TARGET_TABLE" && -n "$TARGET_COLUMN" ]]; then
    echo "Clearing $TARGET_COLUMN from $TARGET_TABLE"
    psql -U "$PG_USER" -h "$PG_HOST" -p "$PG_PORT" -d "$PG_DATABASE" \
        -c "UPDATE $TARGET_TABLE SET $TARGET_COLUMN = $CLEAR_VALUE;"
fi

echo "Done"
