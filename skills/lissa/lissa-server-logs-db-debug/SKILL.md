---
name: lissa-server-logs-db-debug
description: Investigate backend incidents on Lissa Health servers via SSH, container logs, and MySQL diagnostics with environment-aware checklists. Use when the user asks to inspect prod/staging/healthvault errors, queue failures, payment issues, document processing failures, or DB data inconsistencies.
---
# Lissa Server Logs and DB Debug

## Mandatory Context

Always read first:

- `/src/lissa-health/organization/.cursor/rules/platform-shared-deploy-ops-sot.mdc`
- `/src/lissa-health/organization/.cursor/rules/platform-shared-devops-branding-docs.mdc`
- `/src/lissa-health/docs/tech-docs/ops/ai-runbook.md`

## Use This Skill When

- User asks "check logs on server".
- User asks to inspect DB records or queue failures.
- User reports payment/webhook/document-processing issues in a specific environment.
- User asks to diagnose `admin` errors seen in JSON-RPC trace.

## Environment Map

- `prod`: backend `:8082`, frontend `:8081`, DB `lissa_health_prod`
- `staging`: backend `:28082`, frontend `:28081`, DB `lissa_health_staging`
- `healthvault`: backend `:38082`, frontend `:38081`, DB `health_vault`

## Triage Workflow

1. **Identify scope**
   - env, userId/patientId, method name, record/document IDs, timestamp window.
2. **Runtime health**
   - check container state and restarts.
3. **App logs**
   - inspect backend logs around timestamp.
   - inspect queue failures and worker errors.
4. **DB evidence**
   - query `logs`, `job_queue`, domain tables (`health_records`, `document_assets`, billing tables).
5. **Root cause hypothesis**
   - link exception to exact stage (`document.process`, `health-record.process`, etc.).
6. **Action**
   - provide fix or mitigation with verification plan.

## SSH and Runtime Patterns

```bash
# App host
ssh -i /src/lissa-health/backend/ssh/tomsk.pem -p 2223 ubuntu@185.53.106.4

# Container status
cd /opt/lissa-health/<env>/compose && docker compose ps

# Backend container logs (recent)
docker logs --tail 300 <backend-container-name>
```

For DB host access via jump host, use ProxyJump pattern from shared rules.

## Canonical SQL Snippets

```sql
-- Recent errors/warnings
SELECT id, origin, message, severity, data, createdAt
FROM logs
WHERE severity IN ('error', 'warning')
ORDER BY createdAt DESC
LIMIT 100;

-- Failed queue jobs
SELECT id, queue, job, attempts, maxAttempts, errorMessage, createdAt, completedAt
FROM job_queue
WHERE status = 'failed'
ORDER BY id DESC
LIMIT 100;

-- One health record with raw status/data
SELECT id, patientId, recordType, status, deletedAt, data, createdAt, updatedAt
FROM health_records
WHERE id = ?;

-- One document asset with processing state
SELECT id, category, status, deletedAt, data, createdAt, updatedAt
FROM document_assets
WHERE id = ?;
```

## Document and HealthRecord Failure Checklist

For each failure, capture:

- `documentAssetId`, `healthRecordId`, `patientId`, `userId`
- queue name and job ID
- exception type + message + top stack frames
- current statuses in `document_assets` and `health_records`
- whether error is transient (retry) or terminal (bad input/schema/logic)

## Safety Constraints

1. No destructive server commands without explicit user approval.
2. No silent global DB tuning during incident debugging.
3. Prefer session-scoped DB changes for diagnostics.
4. Always report exact environment to avoid cross-env mistakes.

## Expected Output

Return a compact incident summary:

```markdown
Environment: <env>
Symptoms: <what failed>
Evidence:
- <log line / query finding 1>
- <log line / query finding 2>
Root cause: <short explanation>
Fix: <implemented or proposed>
Verification: <what was checked>
```
