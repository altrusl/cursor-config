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
- `gh api repos/<owner>/<repo>/actions/artifacts --paginate` (artifact storage pressure snapshot before rollout)

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
- for promotion workflows, resolve source via immutable release manifest (`source_run_id`) or explicit promote tag;
- `source_run_id` may reference either successful `Frontend: Deploy Dev` run (preferred) or successful `Frontend: Build Dev` run (must be auto-resolved to linked Deploy Dev run before artifact promotion).

### Artifact fallback path (mandatory when manifest chain is broken)

If deploy fails on `download-artifact` (or upstream upload failed with quota):

1. Extract immutable promote tag from successful upstream logs/summary:
   - `gh run view <build-or-deploy-run-id> --log | rg "promote_build_tag|promote_dev_tag|FRONTEND_IMAGE|immutable"`
2. Re-dispatch workflow with explicit promote input:
   - dev deploy fallback: `-f promote_build_tag=<immutable-tag>`
   - staging/prod fallback: `-f promote_dev_tag=<immutable-tag>`
3. Record source run + tag in deploy report.

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

`<source_run_id>` can also be a successful `Frontend: Build Dev` run id when workflow auto-resolution to linked Deploy Dev is available.

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

### Mandatory completion discipline

- Do not end the deploy task while any started workflow/process is still running.
- Wait for all triggered runs to finish and verify final conclusions explicitly.
- If a run fails, inspect logs, fix what is actionable, and re-run until success or clear blocker.
- Final report is allowed only after all started deploy/verification runs are complete.

## 5) Post-deploy verification

Minimum checks per environment:
- HTTP health endpoint:
  - `https://dev.lissa-health.com/health`
  - `https://staging.lissa-health.com/health`
  - `https://lissa-health.com/health` (prod)
- Transport smoke must pass:
  - JSON-RPC: `system.health`, `system.ready`
  - WS: connect/subscribe/publication smoke on `/connection/websocket`
- Workflow smoke job result (Playwright step in workflow).
- For static-landing builds:
  - first root visit renders static landing correctly (full-width `body/#app`, no broken critical CSS),
  - second root visit opens app directly when warm cache marker is present,
  - optional third-wave assets start after delay (~5s), not immediately on login open.
- If health fails, inspect runtime with `project-0-frontend-ops` MCP:
  - `ops_health_check`
  - `ops_compose_ps`
  - `ops_logs_tail` / `ops_container_logs`

### Brand verification (MANDATORY for prod/healthvault)

After ANY deploy to `prod` or `healthvault`, verify the correct brand is served:
```bash
# Prod must show "Lissa Health"
ops_ssh_exec: docker exec lissa-health-prod-frontend grep '<title>' /usr/share/nginx/html/index.html
# Expected: <title>Lissa Health</title>

# Healthvault must show "Health Vault"
ops_ssh_exec: docker exec lissa-health-healthvault-frontend grep '<title>' /usr/share/nginx/html/index.html
# Expected: <title>Health Vault</title>
```
If brands are swapped → **STOP and rollback immediately** using `FRONTEND_IMAGE_PREVIOUS` in `.env`.

### Known failure: HealthVault/Lissa brand mixing

The HealthVault deploy workflow (`white-label-brand-worker.yaml`) ALWAYS targets `/opt/lissa-health/healthvault/`. Never pass `remote_root=/opt/lissa-health/prod` to it. If triggered simultaneously with Lissa Health prod deploy, they can race on the same runner and overwrite each other's docker image tags.

**Prevention**: Never run HealthVault deploy and Lissa Health prod deploy simultaneously on the same commit.

Always include environment name in every diagnostic summary.

## 6) Deployment report format

Return:
- environment;
- workflow file + run URL;
- deployed commit SHA;
- health/smoke result;
- incidents or rollback status.

If rollback happened, explicitly mention `FRONTEND_IMAGE_PREVIOUS` recovery path managed by deploy action.

## 7) Self-learning: post-deploy feedback loop

After every deploy (success or failure), analyze the run and update knowledge:

1. **Record outcome** in `/src/lissa-health/docs/_workspace/deploy-log.jsonl` — one JSON line per deploy:
   ```json
   {"ts":"ISO","repo":"frontend","env":"staging","sha":"abc123","workflow":"deploy-staging-docker-image.yaml","runId":123,"conclusion":"success","durationSec":201,"failStep":null,"rootCause":null}
   ```
   On failure, populate `failStep` (step name) and `rootCause` (one-line summary).

2. **Pattern detection**: Before each deploy, read recent entries from the log. If the same `failStep` or `rootCause` appeared in >=2 of the last 5 deploys:
   - Warn the user proactively ("This step failed 2/5 recent deploys, consider...").
   - If a code fix is possible, apply it automatically.

3. **Skill self-improvement**: If you discover a concrete gap in this skill during a deploy (wrong workflow name, missing input, incorrect sequence), apply a minimal diff to this SKILL.md file immediately. Keep changes small and evidence-based.

4. **Known failure patterns** (auto-learned):
   - Promotion gates require successful preceding workflows — verify with `gh run list` before triggering staging/prod.
   - `confirm_deploy=DEPLOY` is required for prod workflows — always include this input.
   - Deploy lock `frontend-runtime-deploy-lock` serializes all frontend deploy workflows — do not trigger multiple deploy envs simultaneously.
   - Frontend CI can be slow (~17 min) on the self-hosted runner under CPU contention — if CI is the blocking gate, check runner load before re-triggering.
  - `source_run_id` for staging/prod promotion should resolve to preceding environment's successful deploy run; if operator gives Build Dev run id, auto-resolve it to linked Deploy Dev run before dispatch.
  - If artifact storage is saturated, avoid blocking rollout on manifest download and use explicit `promote_*_tag` inputs.
