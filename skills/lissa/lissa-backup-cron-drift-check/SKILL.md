---
name: lissa-backup-cron-drift-check
description: "[Lissa Health] Detect backup cron drift and runtime health issues by comparing repo cron templates with active container crontab and recent backup outcomes/logs. Use when user asks to verify backup scheduling, investigate missed backups, or audit cron reliability across environments. Only for /src/lissa-health/ projects."
---
# Lissa Backup Cron Drift Check

> **Project:** Lissa Health (`/src/lissa-health/`)

Use this skill to validate that scheduled backups really run as intended.

## Read First

- `/src/lissa-health/backend/docker/images/backend/cron/dev.crontab`
- `/src/lissa-health/backend/docker/images/backend/cron/staging.crontab`
- `/src/lissa-health/backend/docker/images/backend/cron/prod.crontab`
- `/src/lissa-health/backend/docker/images/backend/cron/healthvault.crontab`
- `/src/lissa-health/backend/scripts/maintenance.php`
- `/src/lissa-health/docs/tech-docs/operations/runbooks/deployment.md`

## Workflow

1. **Select environment**
   - `dev | staging | prod | healthvault`
2. **Check runtime compose/env controls**
   - Confirm `CONTAINER_CRON_ENABLED=1`
   - Confirm `CONTAINER_CRON_PROFILE` matches target profile
   - Use `ops_env_summary` first.
3. **Check container runtime**
   - `ops_compose_ps` for service health.
   - Ensure `crond` process is alive.
4. **Compare schedule sources**
   - Source of truth in repo: `docker/images/backend/cron/<env>.crontab`.
   - Active runtime: `docker exec lissa-health-<env>-backend crontab -l`.
   - Verify presence of:
     - `php /app/scripts/maintenance.php runBackup`
   - Flag mismatch as drift.
5. **Check execution evidence**
   - Tail cron logs:
     - `/var/log/supervisor/cron.log`
     - `/var/log/supervisor/cron-tasks.log`
   - Confirm recent backup attempts exist and no repeated fatal lines.
6. **Check DB result consistency**
```sql
SELECT id, backupDate, status,
       JSON_UNQUOTE(JSON_EXTRACT(data, '$.backup_mode')) AS backup_mode,
       JSON_UNQUOTE(JSON_EXTRACT(data, '$.errorCode')) AS error_code,
       JSON_UNQUOTE(JSON_EXTRACT(data, '$.error')) AS error_message
FROM backup_tracking
WHERE backupType = 'database'
ORDER BY id DESC
LIMIT 20;
```
   - Confirm recent `completed` rows align with expected cron cadence.
7. **Correlate**
   - If logs show run but DB has no new rows -> execution path/config issue.
   - If DB has failures -> move to `lissa-backup-s3-manual-debug` workflow.

## Drift/Failure Patterns

- Cron entry exists in repo but missing in runtime crontab.
- Wrong `CONTAINER_CRON_PROFILE` for environment.
- Cron runs but `maintenance.runTask` returns timeout/errors.
- Repeated `status=failed` with same `errorCode` in `backup_tracking`.

## Safety Rules

- Read-only diagnostics by default.
- Do not patch crontab or runtime config without explicit user request.
- In `prod`, run raw remote commands only with required confirmation flow.

## Output Format

```markdown
Environment: <env>
Profile status: <ok/mismatch>
Cron drift: <none | details>
Runtime evidence:
- crond process: <up/down>
- cron-tasks log: <key lines>
Backup evidence:
- last completed: <id/date/mode>
- last failed: <id/error_code>
Conclusion: <healthy | drift | failing>
Next action: <specific fix/check>
```
