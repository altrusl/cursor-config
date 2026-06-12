---
name: lissa-deploy-environments
description: "[Lissa Health] Deploy Lissa Health backend/frontend to staging, production, or healthvault with a strict preflight, workflow run, verification, and rollback flow. Use when the user asks to deploy, release, run GitHub Actions workflows, promote builds, or verify deployment health. Only for /src/lissa-health/ projects."
---
# Lissa Deploy Environments

> **Project:** Lissa Health (`/src/lissa-health/`)

## Mandatory Context

Before doing anything, read:

- `/src/lissa-health/organization/.cursor/rules/platform-shared-deploy-ops-sot.mdc`
- `/src/lissa-health/organization/.cursor/rules/platform-shared-devops-branding-docs.mdc`
- `/src/lissa-health/docs/tech-docs/how-to/operations/deploy/environments-runbook.md`

Treat those rules as source of truth for environment mapping and deployment policy.

## Use This Skill When

- User asks to deploy backend/frontend.
- User asks to deploy to `dev`, `staging`, `prod`/`production`, or `healthvault`.
- User asks to run/check GitHub Actions deploy workflow.
- User asks to verify release health or rollback.

## Deployment Workflow

1. **Scope and target**
   - Identify repo (`backend` or `frontend`) and target environment.
   - Confirm branch/ref to deploy.
   - For `staging` / `prod` / `healthvault`: enforce `main-only` promotion flow with local merge (`local feature branch -> local merge to main -> push main -> deploy dev -> promote immutable image to higher envs`).
2. **Preflight**
   - Check local git state (`git status --short --branch`).
   - Run local pre-deploy QA gate when available (`pnpm qa:predeploy` for staging/prod/healthvault; `pnpm qa:local` is the lighter push gate).
   - Use repo-specific deploy skill flow (`lissa-backend-deploy` / `lissa-frontend-deploy`) instead of ad-hoc manual command chains.
   - Check workflow list (`gh workflow list`) and locate deploy workflow.
   - Confirm required workflow inputs.
   - If target is `staging` / `prod` / `healthvault` and target SHA is not in `main`, stop and merge locally to `main` first, then push.
   - For promotion workflows, prefer `source_run_id` + release manifest artifact over mutable runtime `.env` discovery.
3. **Run workflow**
   - Trigger with `gh workflow run ... --ref ... -f ...`.
   - Track latest run via `gh run list --workflow ... --limit 1`.
   - Watch completion with `gh run watch <run-id>`.
   - For `dev` manual dispatch use fast defaults; enable deep checks only by explicit input:
     - frontend: `run_critical_smoke=true`
     - backend: `run_chunked_smoke=true`
4. **Verify runtime**
   - `/health`
   - `system.health`
   - `system.ready`
   - container state/restarts on target host
   - if deployment includes host cron artifacts (`ops/cron/**`, `scripts/ops/**`), verify cron install/update and executable scripts on target host
5. **Summarize**
   - include workflow URL, run ID, commit SHA, target env, verification output.

## Command Patterns

```bash
# 1) Find deploy workflows
gh workflow list

# 2) Trigger deploy workflow (example pattern)
gh workflow run "<workflow-name>" --ref "<branch>" -f target_environment="<env>"

# 3) Inspect recent runs for this workflow
gh run list --workflow "<workflow-name>" --limit 5

# 4) Watch a specific run
gh run watch "<run-id>"
```

Use exact workflow names/inputs from repository files, not memory.

For dev environment, prefer workflows chained from successful CI (`workflow_run`) instead of raw push assumptions.

When repository uses server-side cron for maintenance/regression jobs, do not require scheduled GitHub workflows for those jobs.

## Verification Checklist

- `curl -fsS https://<domain>/health`
- JSON-RPC `system.health`
- JSON-RPC `system.ready`
- no restart loop in relevant containers
- expected build metadata/version is visible for frontend/admin diagnostics

## Rollback Rules

Only rollback when deploy fails verification and user expects recovery.

Rollback procedure:

1. Use previous immutable image digest from runtime `.env`.
2. Re-deploy previous image.
3. Re-run health checks.
4. Report rollback reason and restored version.

## Response Template

Use this short structure:

```markdown
Environment: <env>
Repo: <backend|frontend>
Workflow: <name>
Run: <url>
Result: <success|failed>
Verification:
- /health: <ok|fail>
- system.health: <ok|fail>
- system.ready: <ok|fail>
```
