---
name: lissa-jsonrpc-contract-guard
description: "[Lissa Health] Keep JSON-RPC contracts consistent across backend, frontend, docs, and tests (method docs, params/returns, validation, typing, and consumers). Use when any JSON-RPC method is added/changed/removed. Only for /src/lissa-health/ projects."
---

# Lissa JSON-RPC Contract Guard

> **Project:** Lissa Health (`/src/lissa-health/`)

Use this skill when changing JSON-RPC APIs (new methods, payload shape changes, renamed fields, new error codes).

## 1) Identify contract delta

From git diff, list:

- JSON-RPC method names touched (e.g. `healthRecords.list`, `admin.users.list`),
- what changed: params, return shape, validation rules, error codes.

## 2) Backend truth (mandatory)

Use `backend-info` to validate the contract:

- get method docs for each changed method
- confirm handler/file mapping
- confirm PHPDoc stays accurate (params/returns) and is present for public handlers

If contract was changed but PHPDoc was not updated, fix PHPDoc.

## 3) Frontend consumers (when relevant)

Use `frontend-info` to locate usages/wrappers:

- search API calls for the method name
- update payload construction, response typing, and UI assumptions
- confirm error handling expectations (codes/messages) still match

## 4) Docs and runbooks (when relevant)

If method is user/admin-facing or affects ops flows:

- update relevant pages in `/src/lissa-health/docs/tech-docs/**`
- ensure examples match the new contract

## 5) Tests (recommended)

If Bruno tests exist for the method, update them:

- backend: `composer bru:ci` (when DB is available)

## Output

Provide a short report:

- methods changed,
- contract delta summary,
- updated consumers (frontend/docs/tests),
- remaining risks (backward compatibility, migrations, rollout sequencing).

