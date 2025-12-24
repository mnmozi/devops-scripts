#!/usr/bin/env bash

set -e

# === Required Environment Variables ===
# MYSQL_HOST     - MySQL host
# MYSQL_USER     - MySQL user
# MYSQL_PASSWORD - MySQL password
# MYSQL_DATABASE - Target database name
# DUMP_FILE      - Path to SQL dump file (local path or s3:// URI)
#
# === Optional Environment Variables ===
# AFTER_SYNC_SQL - Path to SQL script to run after restore (optional)

# Validate required env vars
for var in MYSQL_HOST MYSQL_USER MYSQL_PASSWORD MYSQL_DATABASE DUMP_FILE; do
    if [[ -z "${!var}" ]]; then
        echo "Error: $var is not set"
        exit 1
    fi
done

LOCAL_DUMP="$DUMP_FILE"
CLEANUP_DUMP=false

# Download from S3 if needed
if [[ "$DUMP_FILE" == s3://* ]]; then
    echo "Downloading dump from S3: $DUMP_FILE"
    LOCAL_DUMP="/tmp/$(basename "$DUMP_FILE")"
    aws s3 cp "$DUMP_FILE" "$LOCAL_DUMP"
    CLEANUP_DUMP=true
fi

if [[ ! -f "$LOCAL_DUMP" ]]; then
    echo "Error: Dump file not found: $LOCAL_DUMP"
    exit 1
fi

echo "Restoring database: $MYSQL_DATABASE from $LOCAL_DUMP"

mysql \
    -h "$MYSQL_HOST" \
    -u "$MYSQL_USER" \
    -p"$MYSQL_PASSWORD" \
    "$MYSQL_DATABASE" < "$LOCAL_DUMP"

echo "Restore complete"

# Run after-sync script if configured
if [[ -n "$AFTER_SYNC_SQL" && -f "$AFTER_SYNC_SQL" ]]; then
    echo "Running after-sync script: $AFTER_SYNC_SQL"
    mysql \
        -h "$MYSQL_HOST" \
        -u "$MYSQL_USER" \
        -p"$MYSQL_PASSWORD" \
        "$MYSQL_DATABASE" < "$AFTER_SYNC_SQL"
    echo "After-sync script complete"
fi

# Cleanup temp file if downloaded from S3
if [[ "$CLEANUP_DUMP" == "true" ]]; then
    rm -f "$LOCAL_DUMP"
    echo "Temp dump file removed"
fi

echo "Done"
