---
name: lissa-backup-restore-readiness
description: "[Lissa Health] Assess PITR restore readiness using existing full+incremental backup metadata, manifests, and checkpoint continuity without destructive restore actions. Use when user asks if backups are restorable, requests recovery planning, or wants backup chain validation. Only for /src/lissa-health/ projects."
---
# Lissa Backup Restore Readiness

> **Project:** Lissa Health (`/src/lissa-health/`)

Use this skill to answer: "Can we restore now?" based on evidence, not assumptions.

## Read First

- `/src/lissa-health/backend/alvita/backup/Processors/DatabaseBackupProcessor.php`
- `/src/lissa-health/backend/alvita/backup/Services/BackupTracker.php`
- `/src/lissa-health/docs/tech-docs/modules/infrastructure/backup/incremental-backups.md`
- `/src/lissa-health/docs/tech-docs/modules/infrastructure/backup/s3-storage.md`

## Scope

- Validate chain integrity (`full -> incremental...`) for one env.
- Build operator-ready restore plan for a target timestamp.
- Do not execute destructive restore in production without explicit approval.

## Workflow

1. **Collect target context**
   - `env`, target datetime (`UTC`), desired RPO window.
2. **Locate latest full snapshot before target**
```sql
SELECT id, backupDate, backupPath,
       JSON_UNQUOTE(JSON_EXTRACT(data, '$.manifest_path')) AS manifest_path,
       JSON_UNQUOTE(JSON_EXTRACT(data, '$.binlog.start.file')) AS start_file,
       CAST(JSON_UNQUOTE(JSON_EXTRACT(data, '$.binlog.start.position')) AS UNSIGNED) AS start_pos
FROM backup_tracking
WHERE backupType = 'database'
  AND status = 'completed'
  AND JSON_UNQUOTE(JSON_EXTRACT(data, '$.backup_mode')) = 'full'
  AND backupDate <= :target_utc
ORDER BY backupDate DESC
LIMIT 1;
```
3. **Collect incremental chain after chosen full**
```sql
SELECT id, backupDate, backupPath,
       JSON_UNQUOTE(JSON_EXTRACT(data, '$.manifest_path')) AS manifest_path,
       JSON_UNQUOTE(JSON_EXTRACT(data, '$.binlog.start.file')) AS start_file,
       CAST(JSON_UNQUOTE(JSON_EXTRACT(data, '$.binlog.start.position')) AS UNSIGNED) AS start_pos,
       JSON_UNQUOTE(JSON_EXTRACT(data, '$.binlog.end.file')) AS end_file,
       CAST(JSON_UNQUOTE(JSON_EXTRACT(data, '$.binlog.end.position')) AS UNSIGNED) AS end_pos
FROM backup_tracking
WHERE backupType = 'database'
  AND status = 'completed'
  AND JSON_UNQUOTE(JSON_EXTRACT(data, '$.backup_mode')) = 'incremental'
  AND JSON_UNQUOTE(JSON_EXTRACT(data, '$.incremental_strategy')) = 'binlog'
  AND backupDate > :full_backup_date
  AND backupDate <= :target_utc
ORDER BY backupDate ASC;
```
4. **Continuity checks**
   - First incremental `start` is equal to (or forward-compatible with) full `binlog.start`.
   - Every next incremental `start` follows previous `end`.
   - No record in chain has missing `manifest_path` / `backupPath`.
5. **Manifest and payload sanity**
   - Use `admin.backup.get` / `admin.backup.preview` for latest records if metadata is suspicious.
   - Confirm `filter_policy` and `filter_stats` exist for binlog incrementals.
6. **Bucket isolation sanity**
   - Ensure selected keys belong to expected env bucket (`dev/staging/prod/healthvault` mapping).

## Red Flags

- No completed full backup before target time.
- Gaps in incremental checkpoint chain.
- Missing `manifest_path` or empty `backupPath`.
- Repeated failures in `backup_tracking` with unresolved `errorCode`.
- Chain exists only across very old snapshots (RPO risk).

## Non-Goals

- No direct data mutation or restore execution by default.
- No deleting backups while assessing readiness.

## Output Format

```markdown
Environment: <env>
Target time (UTC): <timestamp>
Full snapshot chosen:
- id/date/path: <...>
- start checkpoint: <file:pos>
Incremental chain:
- count: <N>
- latest end checkpoint: <file:pos>
Continuity: <ok | broken + where>
Blocking issues:
- <issue 1>
- <issue 2>
Restore plan:
1) Restore full snapshot <path>
2) Replay incrementals in order <id list>
3) Stop at <target time/position>
Readiness verdict: <ready | not ready>
```
