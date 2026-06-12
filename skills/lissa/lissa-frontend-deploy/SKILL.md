---
name: lissa-frontend-deploy
description: "[Lissa Health] Execute safe frontend deployments for Lissa Health with GitHub Actions (`deploy-dev-docker-image.yaml`, `deploy-staging-docker-image.yaml`, `deploy-prod-docker-image.yaml`) and explicit post-deploy verification. Use when user asks to deploy/redeploy/release frontend changes to dev/staging/prod, monitor rollout status, or collect deployment diagnostics. Only for /src/lissa-health/ projects."
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
Use `main-only` flow with local merge: release commit must already be merged locally into `main` and pushed, then promote immutable image manifests between environments.

## 2) Preflight checks (mandatory)

Run:
- `git status --short --branch`
- `git log -1 --oneline`
- `pnpm type-check` (after code edits)
- `pnpm lint` (after code edits if lint-sensitive files were touched)
- For local preflight on large branches, prefer bounded lint:
  - `FRONTEND_LINT_TIMEOUT_SECONDS=60 pnpm lint`
  - `ESLINT_COMPAT_TIMEOUT_MS=90000 pnpm lint:eslint:compat:changed`
- `gh auth status` (if `gh` fails due to proxy, run with the prefix below)

If `gh` fails with proxy-related errors (e.g. `socks5h`), use:

```bash
env -u ALL_PROXY -u all_proxy -u HTTPS_PROXY -u https_proxy -u HTTP_PROXY -u http_proxy -u NO_PROXY -u no_proxy gh <command>
```

Guardrails:
- Never use `pkill`, `kill`, `killall` on `vite`, `node`, `pnpm`, or dev servers.
- Never use destructive remote commands unless user explicitly asks.
- Never force-push protected branches.

If repository exposes a local pre-deploy gate, run it before remote workflow dispatch:

- `pnpm qa:predeploy`

## 3) Trigger workflow with `gh`

Deploy sequentially: `dev` first, then `staging` (then `prod` only by explicit request).

Mandatory promotion gate for `staging`/`prod`:
- do not deploy from unmerged local branches or detached commits;
- deploy only from `main`;
- for promotion workflows, resolve source via immutable release manifest (`source_run_id`) or explicit promote tag.

### Dev

Prefer CI-chained deploy (`Frontend: Deploy Dev` is triggered by successful `Frontend: CI` run on `main` via `workflow_run`).
If you must run it manually, dispatch it from `main`:

```bash
gh workflow run deploy-dev-docker-image.yaml --ref main -f run_critical_smoke=false
```

For risky changes or explicit deep verification requests, use:

```bash
gh workflow run deploy-dev-docker-image.yaml --ref main -f run_critical_smoke=true
```

### Staging

```bash
gh workflow run deploy-staging-docker-image.yaml --ref main -f brand=lissa-health -f remote_root=/opt/lissa-health/staging -f source_run_id=<frontend-deploy-dev-run-id>
```

### Production (manual confirmation required)

```bash
gh workflow run deploy-prod-docker-image.yaml --ref main -f brand=lissa-health -f confirm_deploy=DEPLOY -f source_run_id=<frontend-deploy-staging-run-id>
```
*Note: Prod deploy promotes the staging image. Ensure `preprod-readiness-gate` checks (`Frontend: CI` + `Frontend: Deploy Staging`) are green for target `main` SHA.*

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

Confirm final status (watch exit codes can be misleading):

```bash
gh run view <run-id> --json status,conclusion,url
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
- For static-landing builds:
  - first root visit renders static landing correctly (full-width `body/#app`, no broken critical CSS),
  - second root visit opens app directly when warm cache marker is present,
  - optional third-wave assets start after delay (~5s), not immediately on login open.
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
