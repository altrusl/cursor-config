---
name: lissa-backend-qa-guard
description: Run a minimal, repeatable backend quality gate for Lissa Health (format, PHPStan, tests, and DB-dependent notes) and produce a short readiness report. Use before PRs and before deploys.
---

# Lissa Backend QA Guard

Use this skill for `/src/lissa-health/backend` after making PHP/config changes or before creating a PR.

## Scope first

Identify:

- which module/package was changed (`src/*`, `alvita/*`, config, migrations),
- whether changes affect database schema or JSON-RPC payload contracts,
- whether the goal is local correctness, CI readiness, or pre-deploy verification.

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

- `composer test`

If the change affects API flows, consider Bruno:

- `composer bru:ci`

Note: CI runners without a database may fail DB-dependent smoke checks. Treat DB-less failures as expected only when evidence confirms the workflow requires DB access.

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

