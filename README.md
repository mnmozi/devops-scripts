# devops-scripts

A collection of utility scripts for database operations, infrastructure management, and testing.

## Structure

```
.
├── mysql/          # MySQL database scripts
├── postgres/       # PostgreSQL database scripts
├── smtp/           # SMTP testing tools
├── system/         # System administration scripts
└── terraform/      # Terraform/Terragrunt utilities
```

## MySQL

### dump.sh
Dump a MySQL database with optional S3 upload.

```bash
# Basic dump
MYSQL_HOST=localhost \
MYSQL_USER=root \
MYSQL_PASSWORD=secret \
MYSQL_DATABASE=mydb \
./mysql/dump.sh

# With S3 upload
MYSQL_HOST=localhost \
MYSQL_USER=root \
MYSQL_PASSWORD=secret \
MYSQL_DATABASE=mydb \
S3_BUCKET_PATH=s3://my-bucket/backups/ \
./mysql/dump.sh
```

| Variable | Required | Description |
|----------|----------|-------------|
| `MYSQL_HOST` | Yes | MySQL host |
| `MYSQL_USER` | Yes | MySQL user |
| `MYSQL_PASSWORD` | Yes | MySQL password |
| `MYSQL_DATABASE` | Yes | Database name |
| `DUMP_DIR` | No | Output directory (default: `.`) |
| `S3_BUCKET_PATH` | No | S3 path for upload |
| `KEEP_LOCAL` | No | Keep local file after S3 upload (default: `false`) |

### restore.sh
Restore a MySQL database from local file or S3.

```bash
# From local file
MYSQL_HOST=localhost \
MYSQL_USER=root \
MYSQL_PASSWORD=secret \
MYSQL_DATABASE=mydb \
DUMP_FILE=/path/to/dump.sql \
./mysql/restore.sh

# From S3
MYSQL_HOST=localhost \
MYSQL_USER=root \
MYSQL_PASSWORD=secret \
MYSQL_DATABASE=mydb \
DUMP_FILE=s3://my-bucket/backups/dump.sql \
./mysql/restore.sh
```

| Variable | Required | Description |
|----------|----------|-------------|
| `MYSQL_HOST` | Yes | MySQL host |
| `MYSQL_USER` | Yes | MySQL user |
| `MYSQL_PASSWORD` | Yes | MySQL password |
| `MYSQL_DATABASE` | Yes | Target database |
| `DUMP_FILE` | Yes | Local path or S3 URI |
| `AFTER_SYNC_SQL` | No | SQL script to run after restore |

## PostgreSQL

### dump.sh
Dump a PostgreSQL database with optional S3 upload and AWS Secrets Manager integration.

```bash
# Basic dump
PG_HOST=localhost \
PG_USER=postgres \
PG_DATABASE=mydb \
PG_PASSWORD=secret \
./postgres/dump.sh

# With S3 upload and Secrets Manager
PG_HOST=mydb.rds.amazonaws.com \
PG_USER=admin \
PG_DATABASE=mydb \
SECRET_NAME=my-secret \
SECRET_KEY=db_password \
S3_BUCKET_PATH=s3://my-bucket/backups/ \
./postgres/dump.sh
```

| Variable | Required | Description |
|----------|----------|-------------|
| `PG_HOST` | Yes | PostgreSQL host |
| `PG_USER` | Yes | PostgreSQL user |
| `PG_DATABASE` | Yes | Database name |
| `PG_PORT` | No | Port (default: `5432`) |
| `PG_PASSWORD` | No* | Password (*required if not using IAM or Secrets Manager) |
| `USE_IAM_AUTH` | No | Use AWS IAM auth (default: `false`) |
| `SECRET_NAME` | No | AWS Secrets Manager secret name |
| `SECRET_KEY` | No | Key within the secret |
| `BACKUP_DIR` | No | Output directory (default: `.`) |
| `DUMP_FORMAT` | No | Format: c/p/d/t (default: `c`) |
| `IGNORE_OWNER` | No | Exclude owner/privileges (default: `true`) |
| `S3_BUCKET_PATH` | No | S3 path for upload |
| `KEEP_LOCAL` | No | Keep local file after S3 upload (default: `false`) |

### restore.sh
Restore a PostgreSQL database with optional column cleanup.

```bash
PG_HOST=localhost \
PG_USER=postgres \
PG_DATABASE=mydb \
PG_PASSWORD=secret \
DUMP_FILE=/path/to/dump.dump \
./postgres/restore.sh
```

| Variable | Required | Description |
|----------|----------|-------------|
| `PG_HOST` | Yes | PostgreSQL host |
| `PG_USER` | Yes | PostgreSQL user |
| `PG_DATABASE` | Yes | Target database |
| `DUMP_FILE` | Yes | Path to dump file |
| `PG_PORT` | No | Port (default: `5432`) |
| `PG_PASSWORD` | No | Password (or set `PGPASSWORD`) |
| `CLEAN_RESTORE` | No | Drop objects before restore (default: `false`) |
| `CREATE_DB` | No | Create database if not exists (default: `true`) |
| `TARGET_TABLE` | No | Table to update after restore |
| `TARGET_COLUMN` | No | Column to clear |
| `CLEAR_VALUE` | No | Value to set (default: `NULL`) |

## SMTP

### go-smtp-test
A Go-based SMTP testing tool.

```bash
cd smtp/go-smtp-test

SMTP_HOST=smtp.example.com \
SMTP_USERNAME=user@example.com \
SMTP_PASSWORD=secret \
MAIL_FROM=user@example.com \
MAIL_TO=recipient@example.com \
go run main.go
```

| Variable | Required | Description |
|----------|----------|-------------|
| `SMTP_HOST` | Yes | SMTP server hostname |
| `SMTP_USERNAME` | Yes | SMTP username |
| `SMTP_PASSWORD` | Yes | SMTP password |
| `MAIL_FROM` | Yes | Sender email address |
| `MAIL_TO` | Yes | Recipient email address |

## System

### disks_partitioning.sh
Format and mount disks with automatic fstab configuration.

Features:
- Manual or auto-discovery of unpartitioned disks
- GPT partitioning with ext4 filesystem
- Persistent mount via fstab

## Terraform

### rm-all-state.sh
Remove all resources from Terragrunt state.

```bash
cd /path/to/terragrunt/module
/path/to/terraform/rm-all-state.sh
```

## License

MIT
