---
name: lissa-backend-qa-guard
description: "[Lissa Health] Run a minimal, repeatable backend quality gate for Lissa Health (format, PHPStan, tests, and DB-dependent notes) and produce a short readiness report. Use before PRs and before deploys. Only for /src/lissa-health/ projects."
---

# Lissa Backend QA Guard

> **Project:** Lissa Health (`/src/lissa-health/`)

Use this skill for `/src/lissa-health/backend` after making PHP/config changes or before creating a PR.

## Scope first

Identify:

- which module/package was changed (`src/*`, `alvita/*`, config, migrations),
- whether changes affect database schema or JSON-RPC payload contracts,
- whether the goal is local correctness, CI readiness, or pre-deploy verification.

## Preferred one-command gate

If repository has script `qa:local`, run it first:

- `pnpm qa:local`

For JSON-RPC/contract surface changes, also run:

- `pnpm qa:contracts`

Before staging/prod/healthvault deploy readiness, prefer:

- `pnpm qa:predeploy`

If these scripts are unavailable or fail due environment-specific reasons, continue with manual checks below.

## Preflight (mandatory)

Run:

- `git status --short --branch`
- `git diff` (and `git diff --staged` if applicable)
- `git log -1 --oneline`

If any file looks like a secret (keys, tokens, `.env`), stop and exclude it from git.

## Formatting (mandatory)

Project style is enforced by `./format.sh`.

Run:

- `./format.sh`

Re-check `git diff` to confirm only formatting changed.

## Static analysis (mandatory)

Run PHPStan:

- `./vendor/phpstan/phpstan/phpstan analyse --configuration=phpstan.neon`

Fix issues in touched areas first. Avoid broad refactors unless required.

## Tests (recommended)

Run unit tests when the change is non-trivial:

- `./vendor/bin/phpunit --exclude-group database` (for unit tests without DB)
- `./vendor/bin/phpunit --group database` (for DB tests, requires local MySQL)

If the change affects API flows, consider Bruno:

- `pnpm run bru:smoke:remote` (against dev/staging)

Note: CI now has a dedicated `phpunit-db` job for DB-dependent tests using a MySQL service container.

## Database and migrations (when relevant)

If schema or migration files were changed:

- assess safety (locks, backfills, rollback),
- ensure queries use `Database\\MedooAdapter` via DI,
- run focused smoke tests on affected flows if a DB is available.

## Output

Produce a short report:

- changed areas (modules/packages),
- commands executed and pass/fail,
- notable risks (DB-required, migration risk, API contract changes),
- whether it is PR-ready and deploy-ready.

