---
name: lissa-incident-postmortem
description: "[Lissa Health] Build a structured incident postmortem with RCA, timeline, and action items from logs, DB evidence, and deploy context. Use when the user asks for RCA, postmortem, incident summary, or follow-up action planning. Only for /src/lissa-health/ projects."
---
# Lissa Incident Postmortem

> **Project:** Lissa Health (`/src/lissa-health/`)

## Mandatory Context

Read first:

- `/src/lissa-health/organization/.cursor/rules/platform-shared-deploy-ops-sot.mdc`
- `/src/lissa-health/docs/tech-docs/ops/ai-runbook.md`

## Use This Skill When

- User asks for incident RCA.
- User asks to write postmortem after deploy/runtime failure.
- User asks to formalize action items and prevention plan.

## Workflow

1. Define incident frame:
   - environment,
   - start/end timestamps,
   - impact scope and affected users/modules.
2. Build timeline:
   - trigger event,
   - detection time,
   - mitigation actions,
   - full recovery time.
3. Gather evidence:
   - logs (`logs` table + runtime logs),
   - queue failures (`job_queue`),
   - linked domain rows (`document_assets`, `health_records`, etc),
   - deploy/workflow run metadata.
4. Root cause:
   - primary technical root cause,
   - contributing factors (process/tooling/monitoring gaps).
5. Action items:
   - immediate containment,
   - short-term fixes,
   - long-term prevention.
6. Add owners, due dates, and verification criteria.

## RCA Rules

- Do not stop at symptom.
- Tie every conclusion to explicit evidence.
- Separate confirmed facts from assumptions.
- Include what would have detected the issue earlier.

## Output Template

```markdown
# Incident Postmortem

> **Project:** Lissa Health (`/src/lissa-health/`)

Incident ID: <id>
Environment: <env>
Severity: <sev>
Window: <start> - <end>

## Impact
- ...

## Timeline
- <time> <event>
- <time> <event>

## Evidence
- Logs: ...
- DB: ...
- Deploy run: ...

## Root Cause
- Primary: ...
- Contributing: ...

## Resolution
- ...

## Action Items
- [ ] <action> | owner: <name> | due: <date> | success criteria: <criteria>
- [ ] <action> | owner: <name> | due: <date> | success criteria: <criteria>

## Lessons Learned
- ...
```
