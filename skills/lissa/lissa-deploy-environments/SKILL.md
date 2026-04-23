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
- `/src/lissa-health/docs/tech-docs/ops/ai-runbook.md`

Treat those rules as source of truth for environment mapping and deployment policy.

## Use This Skill When

- User asks to deploy backend/frontend.
- User asks to deploy to `staging`, `prod`/`production`, or `healthvault`.
- User asks to run/check GitHub Actions deploy workflow.
- User asks to verify release health or rollback.

## Deployment Workflow

1. **Scope and target**
   - Identify repo (`backend` or `frontend`) and target environment.
   - Confirm branch/ref to deploy.
2. **Preflight**
   - Check local git state (`git status --short --branch`).
   - Check workflow list (`gh workflow list`) and locate deploy workflow.
   - Confirm required workflow inputs.
3. **Run workflow**
   - Trigger with `gh workflow run ... --ref ... -f ...`.
   - Track latest run via `gh run list --workflow ... --limit 1`.
   - Watch completion with `gh run watch <run-id>`.
4. **Verify runtime**
   - `/health`
   - `system.health`
   - `system.ready`
   - container state/restarts on target host
5. **Summarize**
   - include workflow URL, run ID, commit SHA, target env, verification output.

## Command Patterns

```bash
# 1) Find deploy workflows

> **Project:** Lissa Health (`/src/lissa-health/`)
gh workflow list

# 2) Trigger deploy workflow (example pattern)

> **Project:** Lissa Health (`/src/lissa-health/`)
gh workflow run "<workflow-name>" --ref "<branch>" -f target_environment="<env>"

# 3) Inspect recent runs for this workflow

> **Project:** Lissa Health (`/src/lissa-health/`)
gh run list --workflow "<workflow-name>" --limit 5

# 4) Watch a specific run

> **Project:** Lissa Health (`/src/lissa-health/`)
gh run watch "<run-id>"
```

Use exact workflow names/inputs from repository files, not memory.

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
