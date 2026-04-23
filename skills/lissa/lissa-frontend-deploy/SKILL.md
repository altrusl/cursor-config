---
name: lissa-frontend-deploy
description: "[Lissa Health] Execute safe frontend deployments for Lissa Health with GitHub Actions (`build-and-deploy.yaml`, `deploy-staging-docker-image.yaml`, `deploy-prod-docker-image.yaml`) and explicit post-deploy verification. Use when user asks to deploy/redeploy/release frontend changes to dev/staging/prod, monitor rollout status, or collect deployment diagnostics. Only for /src/lissa-health/ projects."
---

# Lissa Frontend Deploy

> **Project:** Lissa Health (`/src/lissa-health/`)

Follow this workflow for `/src/lissa-health/frontend`.

## 1) Clarify target and scope

Collect:
- target environment(s): `dev`, `staging`, `prod`, or `healthvault`;
- branch/ref and commit SHA;
- brand (`lissa-health` by default; `health-vault` only via dedicated worker);
- whether deploy is code-only or includes config-sensitive changes.

If `staging` or `prod` is requested, require `main` branch because workflows enforce it.

## 2) Preflight checks (mandatory)

Run:
- `git status --short --branch`
- `git log -1 --oneline`
- `pnpm type-check` (after code edits)
- `pnpm lint-fix` (after code edits if lint-sensitive files were touched)
- `gh auth status`

Guardrails:
- Never use `pkill`, `kill`, `killall` on `vite`, `node`, `pnpm`, or dev servers.
- Never use destructive remote commands unless user explicitly asks.
- Never force-push protected branches.

## 3) Trigger workflow with `gh`

Deploy sequentially: `dev` first, then `staging` (then `prod` only by explicit request).

### Dev

```bash
gh workflow run build-and-deploy.yaml --ref main -f environment=dev
```

### Staging

```bash
gh workflow run deploy-staging-docker-image.yaml --ref main -f brand=lissa-health -f remote_root=/opt/lissa-health/staging
```

### Production (manual confirmation required)

```bash
gh workflow run deploy-prod-docker-image.yaml --ref main -f brand=lissa-health -f confirm_deploy=DEPLOY
```

### HealthVault

```bash
gh workflow run white-label-brand-worker.yaml --ref main -f target_environment=staging -f deploy=true
```

## 4) Watch run and fail fast

Get fresh run id:

```bash
gh run list --workflow <workflow-file> --limit 1 --json databaseId,status,conclusion,createdAt,headSha,displayTitle
```

Watch:

```bash
gh run watch <run-id> --exit-status
```

If failed:

```bash
gh run view <run-id> --log-failed
```

Report failing step immediately and stop the rollout chain.

## 5) Post-deploy verification

Minimum checks per environment:
- HTTP health endpoint:
  - `https://dev.lissa-health.com/health`
  - `https://staging.lissa-health.com/health`
  - `https://lissa-health.com/health` (prod)
- Workflow smoke job result (Playwright step in workflow).
- If health fails, inspect runtime with `project-0-frontend-ops` MCP:
  - `ops_health_check`
  - `ops_compose_ps`
  - `ops_logs_tail` / `ops_container_logs`

Always include environment name in every diagnostic summary.

## 6) Deployment report format

Return:
- environment;
- workflow file + run URL;
- deployed commit SHA;
- health/smoke result;
- incidents or rollback status.

If rollback happened, explicitly mention `FRONTEND_IMAGE_PREVIOUS` recovery path managed by deploy action.
