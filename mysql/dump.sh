#!/usr/bin/env bash

set -e

# === Required Environment Variables ===
# MYSQL_HOST     - MySQL host
# MYSQL_USER     - MySQL user
# MYSQL_PASSWORD - MySQL password
# MYSQL_DATABASE - Database name
#
# === Optional Environment Variables ===
# DUMP_DIR       - Directory to store dump (default: current dir)
# S3_BUCKET_PATH - S3 path to upload dump (optional, e.g., s3://bucket/path/)
# KEEP_LOCAL     - Keep local dump after S3 upload (default: false)

# Validate required env vars
for var in MYSQL_HOST MYSQL_USER MYSQL_PASSWORD MYSQL_DATABASE; do
    if [[ -z "${!var}" ]]; then
        echo "Error: $var is not set"
        exit 1
    fi
done

DUMP_DIR="${DUMP_DIR:-.}"
KEEP_LOCAL="${KEEP_LOCAL:-false}"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
DUMP_FILE="${DUMP_DIR}/${MYSQL_DATABASE}_${TIMESTAMP}.sql"

mkdir -p "$DUMP_DIR"

echo "Starting MySQL dump for database: $MYSQL_DATABASE"

mysqldump \
    --single-transaction \
    --set-gtid-purged=OFF \
    -h "$MYSQL_HOST" \
    -u "$MYSQL_USER" \
    -p"$MYSQL_PASSWORD" \
    "$MYSQL_DATABASE" > "$DUMP_FILE"

echo "Dump saved to: $DUMP_FILE"

# Upload to S3 if configured
if [[ -n "$S3_BUCKET_PATH" ]]; then
    echo "Uploading to S3: $S3_BUCKET_PATH"
    aws s3 cp "$DUMP_FILE" "${S3_BUCKET_PATH}$(basename "$DUMP_FILE")"
    echo "Upload complete"

    if [[ "$KEEP_LOCAL" != "true" ]]; then
        rm -f "$DUMP_FILE"
        echo "Local dump removed"
    fi
fi

echo "Done"
