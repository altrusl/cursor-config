---
name: lissa-release-notes-from-commits
description: "[Lissa Health] Generate deploy-ready release notes and changelog from git commits, workflow runs, and verification results. Use when the user asks for release notes, changelog generation, deployment summary, or "what changed" between two refs. Only for /src/lissa-health/ projects."
---
# Lissa Release Notes From Commits

> **Project:** Lissa Health (`/src/lissa-health/`)

## Mandatory Context

Read first:

- `/src/lissa-health/organization/.cursor/rules/platform-shared-deploy-ops-sot.mdc`
- `/src/lissa-health/docs/tech-docs/ops/ai-runbook.md`

## Use This Skill When

- User asks to auto-generate changelog for deploy.
- User asks for release notes between two refs/tags/commits.
- User asks for "what changed in staging/brand deploy".

## Workflow

1. Scope:
   - repo (`backend`, `frontend`, `docs`, `organization`),
   - environment (`staging`, `prod`, `healthvault`),
   - range (`from_ref..to_ref`).
2. Collect evidence:
   - `git log --oneline from_ref..to_ref`,
   - optional `git diff --name-status from_ref..to_ref`,
   - workflow/run URL used for deployment.
3. Cluster commits:
   - Features,
   - Fixes,
   - Ops/Infra,
   - Docs,
   - Breaking changes (if any).
4. Produce concise release notes focused on user impact and operational changes.
5. Add verification and rollback references.

## Command Patterns

```bash
git log --oneline <from_ref>..<to_ref>
git log --pretty=format:"%h|%s|%an|%ad" --date=short <from_ref>..<to_ref>
git diff --name-status <from_ref>..<to_ref>
gh run list --limit 10
```

## Output Template

```markdown
# Release Notes

> **Project:** Lissa Health (`/src/lissa-health/`)

Environment: <env>
Repo: <repo>
Range: <from_ref>..<to_ref>
Deploy Run: <url>

## Highlights
- ...

## Features
- ...

## Fixes
- ...

## Ops / Infrastructure
- ...

## Verification
- /health: <ok|fail>
- system.health: <ok|fail>
- system.ready: <ok|fail>

## Rollback
- Previous image/ref: <value>
```
