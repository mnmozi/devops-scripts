#!/bin/bash

set -e

# === Required Environment Variables ===
# PG_HOST        - PostgreSQL host
# PG_USER        - PostgreSQL user
# PG_DATABASE    - Database name
#
# === Optional Environment Variables ===
# PG_PORT        - PostgreSQL port (default: 5432)
# PG_PASSWORD    - PostgreSQL password (if not using IAM or Secrets Manager)
# BACKUP_DIR     - Directory to store dump (default: current dir)
# DUMP_FORMAT    - Dump format: c=custom, p=plain, d=directory, t=tar (default: c)
# IGNORE_OWNER   - Exclude owner/privileges (default: true)
# USE_IAM_AUTH   - Use AWS IAM authentication (default: false)
# SECRET_NAME    - AWS Secrets Manager secret name (optional)
# SECRET_KEY     - Key within the secret (optional)
# S3_BUCKET_PATH - S3 path to upload dump (optional)
# KEEP_LOCAL     - Keep local dump after S3 upload (default: false)

# Validate required env vars
for var in PG_HOST PG_USER PG_DATABASE; do
    if [[ -z "${!var}" ]]; then
        echo "Error: $var is not set"
        exit 1
    fi
done

PG_PORT="${PG_PORT:-5432}"
BACKUP_DIR="${BACKUP_DIR:-.}"
DUMP_FORMAT="${DUMP_FORMAT:-c}"
IGNORE_OWNER="${IGNORE_OWNER:-true}"
USE_IAM_AUTH="${USE_IAM_AUTH:-false}"
KEEP_LOCAL="${KEEP_LOCAL:-false}"

mkdir -p "$BACKUP_DIR"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DUMP_FILENAME="${PG_DATABASE}_${TIMESTAMP}.dump"
BACKUP_FILE="${BACKUP_DIR}/${DUMP_FILENAME}"

# Get password
if [[ "$USE_IAM_AUTH" == "true" ]]; then
    export PGPASSWORD=$(aws rds generate-db-auth-token --hostname "$PG_HOST" --port "$PG_PORT" --username "$PG_USER")
elif [[ -n "$SECRET_NAME" && -n "$SECRET_KEY" ]]; then
    export PGPASSWORD=$(aws secretsmanager get-secret-value --secret-id "$SECRET_NAME" \
        --query SecretString --output text | jq -r ".\"$SECRET_KEY\"")
elif [[ -n "$PG_PASSWORD" ]]; then
    export PGPASSWORD="$PG_PASSWORD"
else
    echo "Error: No password method configured (PG_PASSWORD, USE_IAM_AUTH, or SECRET_NAME/SECRET_KEY)"
    exit 1
fi

# Build dump command
DUMP_CMD="pg_dump -h \"$PG_HOST\" -p \"$PG_PORT\" -U \"$PG_USER\" -d \"$PG_DATABASE\" -F \"$DUMP_FORMAT\" -f \"$BACKUP_FILE\""
[[ "$IGNORE_OWNER" == "true" ]] && DUMP_CMD="$DUMP_CMD --no-owner --no-privileges"

echo "Starting backup for database: $PG_DATABASE"
eval $DUMP_CMD

echo "Dump saved to: $BACKUP_FILE"

# Upload to S3 if configured
if [[ -n "$S3_BUCKET_PATH" ]]; then
    echo "Uploading to S3: $S3_BUCKET_PATH"
    aws s3 cp "$BACKUP_FILE" "${S3_BUCKET_PATH}${DUMP_FILENAME}"
    echo "Upload complete"

    if [[ "$KEEP_LOCAL" != "true" ]]; then
        rm -f "$BACKUP_FILE"
        echo "Local dump removed"
    fi
fi

unset PGPASSWORD
echo "Done"
