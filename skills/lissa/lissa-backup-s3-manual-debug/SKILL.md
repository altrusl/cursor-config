---
name: lissa-backup-s3-manual-debug
description: "[Lissa Health] Manual S3 backup operations via existing backend flows (`backup.run` / `maintenance.runTask` / `scripts/maintenance.php runBackup`) with focused troubleshooting by logs and backup_tracking error codes. Use when user asks to run backup manually, verify backup artifacts, or investigate backup failures. Only for /src/lissa-health/ projects."
---
# Lissa S3 Backup Manual + Debug

> **Project:** Lissa Health (`/src/lissa-health/`)

Use this skill when backup must be started manually and/or backup errors must be diagnosed from logs.

## Canonical Sources (read first)

- `/src/lissa-health/backend/alvita/backup/BackupService.php`
- `/src/lissa-health/backend/alvita/backup/Processors/DatabaseBackupProcessor.php`
- `/src/lissa-health/backend/alvita/backup/Services/BackupTracker.php`
- `/src/lissa-health/backend/scripts/maintenance.php`
- `/src/lissa-health/backend/src/Config/services/backup.json5`
- `/src/lissa-health/docs/tech-docs/modules/infrastructure/backup/overview.md`
- `/src/lissa-health/docs/tech-docs/modules/infrastructure/backup/s3-storage.md`

## Environment and Bucket Map

- `dev` -> `lissa-health-dev`
- `staging` -> `lissa-health-staging`
- `prod` -> `lissa-health`
- `healthvault` -> `health-vault`

Base S3 prefix: `backups`.

## Preferred Tooling

- SSH/session: `ops_ssh_connect`, `ops_ssh_exec`, `ops_compose_ps`
- Container/app logs: `ops_container_logs`, `ops_logs_tail`, `ops_db_logs_tail`
- DB evidence: `ops_db_query`
- Runtime env summary: `ops_env_summary`

For `prod` raw commands via `ops_ssh_exec`, use `confirm: "DEPLOY"` when required by tool policy.

## Workflow

1. **Identify scope**
   - Environment (`dev/staging/prod/healthvault`), mode (`full` vs `incremental`), DB/files scope.
2. **Preflight**
   - Check env config summary (`ops_env_summary`) and ensure backup secrets are set:
     - `BACKUP_S3_ACCESS_KEY`, `BACKUP_S3_SECRET_KEY`, `BACKUP_S3_BUCKET`, `BACKUP_ENCRYPTION_KEY` (if encryption enabled).
   - Run config/connection checks through existing API:
     - `backup.validate`
     - `backup.testConnectivity`
     - `backup.testMysqldump`
3. **Run manual backup via existing code (do not invent new flow)**
   - Preferred JSON-RPC:
```json
{
  "jsonrpc": "2.0",
  "method": "backup.run",
  "params": {
    "files": true,
    "database": true
  },
  "id": 1
}
```
   - Forced full DB:
```json
{
  "jsonrpc": "2.0",
  "method": "backup.run",
  "params": {
    "files": false,
    "database": true,
    "incremental": false,
    "fullMode": "single"
  },
  "id": 1
}
```
   - Forced incremental DB:
```json
{
  "jsonrpc": "2.0",
  "method": "backup.run",
  "params": {
    "files": false,
    "database": true,
    "incremental": true,
    "incrementalMode": "single"
  },
  "id": 1
}
```
   - Equivalent maintenance task:
```json
{
  "jsonrpc": "2.0",
  "method": "maintenance.runTask",
  "params": { "task": "runBackup" },
  "id": 1
}
```
   - Container-local command path (same existing flow):
```bash
docker exec lissa-health-<env>-backend php /app/scripts/maintenance.php runBackup
```
4. **Verify result**
   - Check JSON-RPC response:
     - `success`
     - `processes.database.backup_mode`
     - `archive_path`/`backup_path`
     - `manifest_path`
   - Check latest tracking rows:
```sql
SELECT id, backupType, status, backupPath, backupDate,
       JSON_UNQUOTE(JSON_EXTRACT(data, '$.backup_mode')) AS backup_mode,
       JSON_UNQUOTE(JSON_EXTRACT(data, '$.incremental_strategy')) AS incremental_strategy,
       JSON_UNQUOTE(JSON_EXTRACT(data, '$.errorCode')) AS error_code,
       JSON_UNQUOTE(JSON_EXTRACT(data, '$.error')) AS error_message
FROM backup_tracking
WHERE backupType = 'database'
ORDER BY id DESC
LIMIT 20;
```

## Backup Error Triage (logs + DB)

When run fails or partial-success is suspicious:

1. **Cron/task logs**
```bash
docker exec lissa-health-<env>-backend tail -n 200 /var/log/supervisor/cron-tasks.log
```
2. **Container logs**
   - `ops_container_logs` for backend container
3. **App logs**
   - `ops_logs_tail` with `level=error` and `contains=backup`
   - `ops_db_logs_tail` with `severity=error` and `originLike=backup`
4. **Failed DB backup records**
```sql
SELECT id, backupDate, backupPath,
       JSON_UNQUOTE(JSON_EXTRACT(data, '$.errorCode')) AS error_code,
       JSON_UNQUOTE(JSON_EXTRACT(data, '$.error')) AS error_message
FROM backup_tracking
WHERE backupType = 'database' AND status = 'failed'
ORDER BY id DESC
LIMIT 20;
```

## Error Code Quick Map

- `MYSQLDUMP_PROCESS_START_FAILED`, `MYSQLDUMP_FAILED`, `MYSQLDUMP_EMPTY`
  - Check dump client availability (`backup.testMysqldump`), DB connectivity, SSL mode/fallback.
- `BINLOG_STATUS_EMPTY`, `BINLOG_STATUS_INVALID`
  - Check `SHOW MASTER STATUS`, ensure binlog enabled.
- `BINLOG_START_NOT_FOUND`, `BINLOG_END_NOT_FOUND`, `BINLOG_RANGE_INVALID`, `BINLOG_RANGE_EMPTY`
  - Check binlog retention/rotation and checkpoint continuity.
- `BINLOG_DECODE_*`, `BINLOG_FILTER_*`, `BINLOG_DOWNLOAD_MISSING`
  - Check `mysqlbinlog`/`mariadb-binlog` compatibility and temp file writeability.
- `S3 upload failed`, retention-list/delete warnings
  - Check bucket, endpoint, credentials, permissions, network timeouts.
- `ENCRYPTION_KEY_MISSING`
  - Encryption enabled but key absent/mismatched.
- `TMP_DIR_CREATE_FAILED`, `CHECKSUM_FAILED`
  - Check disk space, permissions, filesystem health.

## Safety Rules

- Do not print or store secrets in responses.
- Do not run write/DDL SQL unless user explicitly asks.
- Do not use legacy ad-hoc scripts (`scripts/db-backup.sh`) for canonical backup operations.
- In production, prefer read-only diagnostics first.

## Output Format

```markdown
Environment: <env>
Manual run: <backup.run | maintenance.runTask runBackup | scripts/maintenance.php runBackup>
Result: <success/failed + short reason>
Artifacts:
- backup_path/archive_path: <key or n/a>
- manifest_path: <key or n/a>
Evidence:
- backup_tracking: <latest id/status/error_code>
- logs: <most relevant line>
Root cause: <short>
Action: <done/proposed>
```
