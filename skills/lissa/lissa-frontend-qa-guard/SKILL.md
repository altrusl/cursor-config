---
name: lissa-frontend-qa-guard
description: Run a minimal frontend quality gate for Lissa Health frontend (lint, type-check, optional Playwright smoke) and produce a short readiness report. Use before PRs and before deploys.
---

# Lissa Frontend QA Guard

Use this skill for `/src/lissa-health/frontend` after making Vue/TS/config changes or before creating a PR.

## Scope first

Identify:

- what was changed (routes, modules, API integration, white-label, i18n, e2e),
- whether changes are brand-sensitive (health-vault vs default brand),
- whether a quick local gate is enough or an e2e smoke is needed.

## Preflight (mandatory)

Run:

- `git status --short --branch`
- `git diff` (and `git diff --staged` if applicable)
- `git log -1 --oneline`

## Lint (mandatory for code changes)

Run:

- `pnpm lint-fix`

Re-check `git diff` for auto-fixes.

## Type check (mandatory for TS/Vue changes)

Run:

- `pnpm type-check`

## Brand validation (when relevant)

If changes touch `brands/`, `white-label`, landing content, or template placeholders:

- `pnpm validate:brand`
- `pnpm validate:brand-content`

## E2E smoke (when relevant)

If changes touch auth, upload, health records flows, routing, or anything user-facing:

- `pnpm test:e2e -- --project=chromium`

If time is limited, run the shortest smoke suite you have (for example `e2e/tests/smoke.spec.ts`).

## Safety notes

- Do not use any scripts that kill processes (`pkill` / `killall`) on remote hosts. Prefer stopping dev servers with Ctrl+C in the terminal.

## Output

Produce a short report:

- changed areas,
- commands executed and pass/fail,
- what was auto-fixed,
- remaining risks (brand-specific, e2e not run, etc).

