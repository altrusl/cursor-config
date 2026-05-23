---
name: lissa-backend-deploy
description: "[Lissa Health] Execute safe backend deployments for Lissa Health (staging/prod/healthvault) with preflight checks, quality gate, workflow run, verification, and rollback notes. Use when user asks to deploy/redeploy/release backend changes. Only for /src/lissa-health/ projects."
---

# Lissa Backend Deploy

> **Project:** Lissa Health (`/src/lissa-health/`)

Use this skill for `/src/lissa-health/backend`.

## 0) Mandatory context (platform SOT)

Before triggering any deploy workflow, read:

- `/src/lissa-health/organization/.cursor/rules/platform-shared-deploy-ops-sot.mdc`
- `/src/lissa-health/organization/.cursor/rules/platform-shared-devops-branding-docs.mdc`

## 1) Preflight (mandatory)

Run:

- `git status --short --branch`
- `git log -1 --oneline`
- `gh auth status` (if `gh` fails due to proxy, run with the prefix below)

If `gh` fails with proxy-related errors (e.g. `socks5h`), use:

```bash
env -u ALL_PROXY -u all_proxy -u HTTPS_PROXY -u https_proxy -u HTTP_PROXY -u http_proxy -u NO_PROXY -u no_proxy gh <command>
```

If there are local changes, do not deploy until the working tree is clean and the target commit SHA is identified.

If repository exposes a local pre-deploy gate, run it before remote workflow dispatch:

- `pnpm qa:predeploy`

## 2) Backend QA gate (mandatory after code/config edits)

Run the minimal quality gate first:

- use the skill `lissa-backend-qa-guard` (format + PHPStan + tests when relevant)

Do not proceed to deploy if PHPStan fails.

## 3) Trigger deploy workflow with `gh`

Do not guess workflow names or inputs. Always read the repo workflows first:

- `.github/workflows/**`
- `gh workflow list`

Then trigger the correct workflow using `gh workflow run ... --ref ... -f ...`.

For dev deploy, prefer CI-chained flow (`Backend: Deploy Dev` triggered by successful `Backend: CI` on `dev`) instead of assuming direct push-trigger deploy.

*Note: Prod deploy now promotes the staging image instead of rebuilding. Ensure `preprod-readiness-gate` checks (CI + Staging deploy) are green for the commit.*

## 4) Watch run and fail fast

Watch completion:

- `gh run list --workflow <workflow-file-or-name> --limit 1`
- `gh run watch <run-id> --exit-status`

Confirm final status (watch exit codes can be misleading):

```bash
gh run view <run-id> --json status,conclusion,url
```

If failed:

- `gh run view <run-id> --log-failed`

Stop rollout chain on the first failure and summarize the failing step.

## 5) Post-deploy verification (mandatory)

Minimum checks:

- `/health` on target domain
- JSON-RPC `system.health`
- JSON-RPC `system.ready`
- container state (no restart loop) on target host

Notes:

- Some CI smoke checks require a database. Treat DB-less failures as expected only when you have evidence the workflow runs without DB on that runner.

## 6) Rollback notes

Rollback only if verification fails and user expects recovery.

Prefer reverting to a **previous immutable image digest** (per env `.env` / compose pinning rules in platform SOT docs).

## 7) Deployment report format

Return:

- environment;
- workflow name + run URL;
- deployed commit SHA;
- verification results (`/health`, `system.health`, `system.ready`);
- incidents/rollback status.

