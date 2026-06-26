---
name: lissa-frontend-qa-guard
description: "[Lissa Health] Run a minimal frontend quality gate for Lissa Health frontend (lint, type-check, optional Playwright smoke) and produce a short readiness report. Use before push to main and before deploys. Only for /src/lissa-health/ projects."
---

# Lissa Frontend QA Guard

> **Project:** Lissa Health (`/src/lissa-health/`)

Use this skill for `/src/lissa-health/frontend` after making Vue/TS/config changes or before pushing to `main` / deploying.

## Scope first

Identify:

- what was changed (routes, modules, API integration, white-label, i18n, e2e),
- whether changes are brand-sensitive (health-vault vs default brand),
- whether a quick local gate is enough or an e2e smoke is needed.

## Preferred one-command gate

If repository has script `qa:local`, run it first:

- `pnpm qa:local`

Before staging/prod deploy readiness checks, prefer:

- `pnpm qa:predeploy`

If these scripts are unavailable or fail due environment-specific constraints, continue with manual checks below.

## Preflight (mandatory)

Run:

- `git status --short --branch`
- `git diff` (and `git diff --staged` if applicable)
- `git log -1 --oneline`

Ensure `pnpm-lock.yaml` is up-to-date. CI uses strict `--frozen-lockfile` and will fail if the lockfile drifts from `package.json`.

## CI storage pressure (early warning)

Before interpreting CI failures, snapshot Actions artifact usage:

- `gh api repos/<owner>/<repo>/actions/artifacts --paginate --jq '[.artifacts[]] | {count:length, size_mb: ((map(.size_in_bytes) | add // 0) / 1048576)}'`

If runs fail on `Failed to CreateArtifact`:

- classify this as **platform CI noise** first (not immediate product regression),
- prioritize lint/type-check/build/test outcomes over diagnostic artifact upload failures,
- mention `promote_*_tag` fallback path in deploy readiness notes.

## Lint (mandatory for code changes)

Run:

- `pnpm lint`
- Recommended local bound: `FRONTEND_LINT_TIMEOUT_SECONDS=60 pnpm lint`

If lint reports fixable issues, then run:

- `pnpm lint-fix`

Re-check `git diff` for auto-fixes.

### Runaway ESLint recovery (critical)

If `pnpm lint` runs unusually long (for example, >3 minutes) or pegs CPU:

1. identify exact PID:
   - `ps -eo pid,pcpu,args | rg "eslint|pnpm lint"`
2. terminate only that PID:
   - `kill -TERM <pid>`
3. never use broad process kills (`pkill node`, `killall pnpm`, etc.).

For ESLint compatibility gate on changed files, also enforce timeout:

- `ESLINT_COMPAT_TIMEOUT_MS=90000 pnpm lint:eslint:compat:changed`

## Type check (mandatory for TS/Vue changes)

Run:

- `pnpm type-check`

## Static landing / chunk-wave checks (when relevant)

If changes touch `vite.config.ts`, `scripts/postbuild-static-landing.mjs`, landing Vue/CSS, or chunking rules:

- `pnpm build`
- verify `dist/chunk-inventory.json` is generated
- run Playwright smoke for static-vs-app parity (root first load static, second load app)
- verify optional third-wave assets (`vendor-extra-*` + `vendor-extra-worker-*`) are not requested before app init and appear ~5s after app load

## Brand validation (when relevant)

If changes touch `brands/`, `white-label`, landing content, or template placeholders:

- `pnpm validate:brand`
- `pnpm validate:brand-content`

## E2E smoke (when relevant)

If changes touch auth, upload, health records flows, routing, or anything user-facing:

- `pnpm test:e2e:critical`
- `pnpm test:e2e:core` (if flow changes include uploads/records)
- `pnpm test:e2e:public` (for fast public-routes checks)

For expensive health-profile verification (prod deploy only):

- `E2E_RUN_EXPENSIVE_HEALTH_PROFILE=1 pnpm test:e2e:expensive:health-profile`

If you need real LLM smoke, run with heavy flag:

- `E2E_RUN_HEAVY=1 pnpm exec playwright test e2e/tests/medical-assistant-llm.spec.ts`
- For recurring heavy staging coverage, use workflow `Frontend: Nightly Heavy E2E` (`.github/workflows/nightly-heavy-e2e.yaml`) instead of adding these suites to PR-loop gates.

For production smoke, read token/user id from server env (`/opt/lissa-health/prod/compose/.env`) and do not use tests token minting endpoints.

## Safety notes

- Do not use any scripts that kill processes (`pkill` / `killall`) on remote hosts. Prefer stopping dev servers with Ctrl+C in the terminal.

## Output

Produce a short report:

- changed areas,
- commands executed and pass/fail,
- what was auto-fixed,
- remaining risks (brand-specific, e2e not run, etc).

