---
name: lissa-jsonrpc-contract-first
description: "[Lissa Health] Contract-first JSON-RPC workflow: edit /src/lissa-health/contracts first, run lint/bundle/generate, sync frontend generated domain wrappers, backend shadow-readiness, Bruno + docs. Use when adding/changing/removing JSON-RPC methods or payloads. Only for /src/lissa-health/ projects."
---

# Lissa JSON-RPC Contract-First

> **Contracts SoT:** `/src/lissa-health/contracts`  
> **Transport:** JSON-RPC 2.0 only — not REST.

Use this skill for **surface changes** (method add/change/remove, payload/response shape). For quick alignment without codegen, prefer `lissa-jsonrpc-contract-guard`.

## Principles

1. **Contracts first** — OpenAPI contract defines method names and shapes before backend/frontend edits.
2. **Dot notation** — canonical ids like `reports.generateTimeline`; no aliases.
3. **Generated frontend** — domain files under `generated/domains/*.generated.ts`; `jsonrpc-methods.generated.ts` is a method/type registry, while call-sites should use domain wrappers.

## Commands (gates)

### Contracts repo

```bash
cd /src/lissa-health/contracts
pnpm contracts:lint && pnpm contracts:bundle && pnpm contracts:generate:all
```

### Frontend

```bash
cd /src/lissa-health/frontend
pnpm contracts:sync-generated    # apply
pnpm contracts:check-generated   # CI-style drift check
```

### Backend

```bash
cd /src/lissa-health/backend
php scripts/contracts-shadow-readiness.php
```

Optional: `./vendor/phpstan/phpstan/phpstan analyse …` on touched PHP; PHPUnit `tests/Unit/Services/JsonRpcShadowValidatorTest.php` when shadow rules change.

### Bruno

Run requests under `maintenance/bruno/` that cover changed methods; expand to `composer bru:ci` when a database is available.

## Cross-repo steps (minimal)

| Step | Where | Action |
| --- | --- | --- |
| 1 | `contracts` | Edit OpenAPI → lint → bundle → generate |
| 2 | `backend` | Route + handler + Validator; PHPDoc with handler line `namespace.method`; shadow/registry config if needed |
| 3 | `frontend` | `contracts:sync-generated`; consume **domain** generated exports |
| 4 | `docs` | Update `/src/lissa-health/docs/tech-docs/**` when externally visible |
| 5 | `backend` tests | Bruno + targeted PHPUnit |

## MCP / review aids

- `backend-info`: method docs, handlers, Reflection
- `frontend-info`: `api.search` / consumers under `src/app/services/api`

## Output

Short report: methods touched, contract delta, files regenerated, readiness script result, Bruno list run, remaining compatibility risks.

## PR checklist

- [ ] `pnpm contracts:lint` + bundle + generate (contracts)
- [ ] `pnpm contracts:check-generated` (frontend)
- [ ] `php scripts/contracts-shadow-readiness.php` → exit 0
- [ ] New/updated API calls use domain wrappers from `generated/domains/*.generated.ts`
- [ ] Bruno (+ docs when needed)
- [ ] Branch policy: feature → `dev` → `main` (no direct `main` work)
