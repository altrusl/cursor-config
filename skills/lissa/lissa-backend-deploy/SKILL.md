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
- `gh api repos/<owner>/<repo>/actions/artifacts --paginate` (artifact storage pressure snapshot before rollout)

If `gh` fails with proxy-related errors (e.g. `socks5h`), use:

```bash
env -u ALL_PROXY -u all_proxy -u HTTPS_PROXY -u https_proxy -u HTTP_PROXY -u http_proxy -u NO_PROXY -u no_proxy gh <command>
```

If there are local changes, do not deploy until the working tree is clean and the target commit SHA is identified.

Promotion rule for `staging` / `prod` / `healthvault` (mandatory):

- never deploy these environments directly from `feature/*` or unmerged commits;
- use `main` as the single delivery branch (`main-only`);
- promote immutable images through environment workflows (`dev` -> `staging` -> `prod/healthvault`) using release manifests/artifacts.

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

For dev deploy, prefer CI-chained flow (`Backend: Deploy Dev` triggered by successful `Backend: CI` on `main`) instead of assuming direct push-trigger deploy.
Fast path is default for dev (chunked smoke skipped). For risky/manual checks dispatch with:

```bash
gh workflow run deploy-dev-docker-image.yaml --ref main -f run_chunked_smoke=true
```

*Note: Prod deploy now promotes the staging image instead of rebuilding. Ensure `preprod-readiness-gate` checks (CI + Staging deploy) are green for the commit.*

### Artifact fallback path (mandatory when manifest chain is broken)

If deploy fails on `download-artifact` (or upstream build failed upload due to quota):

1. Get immutable promote tag from successful upstream run logs/summary:
   - `gh run view <build-or-deploy-run-id> --log | rg "promote_build_tag|promote_dev_tag|BACKEND_IMAGE|immutable"`
2. Re-dispatch deploy workflow with explicit promote input instead of artifact dependency:
   - dev deploy fallback: pass `-f promote_build_tag=<immutable-tag>`
   - staging/prod/healthvault fallback: pass `-f promote_dev_tag=<immutable-tag>`
3. Keep evidence in the report: include source run id, extracted tag, and re-run URL.

If changes touch host cron artifacts (`ops/cron/**`, `scripts/ops/**`):

- treat cron rollout as part of deployment scope;
- install/update cron file on target host from repo template;
- verify cron entries reference existing scripts and recent run logs.

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

### Mandatory completion discipline

- Do not finish the task while any deploy/qa command started in this session is still running.
- Wait for all started workflows/processes to reach terminal state (`success`/`failure`/`cancelled`).
- If a run fails, inspect failed logs, apply a fix when possible, and re-run the failed stage.
- Only report deployment as complete after explicit verification of final run conclusions.

## 5) Post-deploy verification (mandatory)

Minimum checks:

- `/health` on target domain
- JSON-RPC `system.health`
- JSON-RPC `system.ready`
- JSON-RPC `dispatcher.heartbeat`
- Realtime transport endpoint `/connection/websocket` (Centrifugo)
- Safe dispatcher contract-smoke for `dispatcher.reserve` (expected validation error, no queue mutation)
- container state (no restart loop) on target host
- for cron rollouts: cron file installed, syntax accepted, and scripts executable on target host

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

## 8) Self-learning: post-deploy feedback loop

After every deploy (success or failure), analyze the run and update knowledge:

1. **Record outcome** in `/src/lissa-health/docs/_workspace/deploy-log.jsonl` — one JSON line per deploy:
   ```json
   {"ts":"ISO","repo":"backend","env":"staging","sha":"abc123","workflow":"deploy-staging-docker-image.yaml","runId":123,"conclusion":"success","durationSec":82,"failStep":null,"rootCause":null}
   ```
   On failure, populate `failStep` (step name) and `rootCause` (one-line summary).

2. **Pattern detection**: Before each deploy, read recent entries from the log. If the same `failStep` or `rootCause` appeared in >=2 of the last 5 deploys:
   - Warn the user proactively ("This step failed 2/5 recent deploys, consider...").
   - If a code fix is possible (e.g., missing `confirm_deploy` input, wrong workflow ref), apply it automatically.

3. **Skill self-improvement**: If you discover a concrete gap in this skill during a deploy (wrong workflow name, missing input, incorrect sequence), apply a minimal diff to this SKILL.md file immediately. Keep changes small and evidence-based.

4. **Known failure patterns** (auto-learned):
   - `shivammathur/setup-php@v2` fails transiently on self-hosted runners under CPU pressure — re-run the failed job once before escalating.
   - `confirm_deploy=DEPLOY` is required for prod and healthvault workflows — always include this input.
   - Promotion gates require successful preceding workflows — check with `gh run list` before triggering downstream deploys.
   - Deploy lock `backend-runtime-deploy-lock` serializes all backend deploy workflows — do not trigger multiple deploy envs simultaneously; wait for each to complete.
  - If artifact storage is saturated, `download-artifact` can fail even when build otherwise succeeds; use explicit `promote_*_tag` fallback and continue rollout.

