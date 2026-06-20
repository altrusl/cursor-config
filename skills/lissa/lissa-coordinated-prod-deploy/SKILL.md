---
name: lissa-coordinated-prod-deploy
description: "[Lissa Health] Deploy backend and frontend to production simultaneously with version coordination, ensuring API contract consistency and zero-downtime rollout. Use when user asks for coordinated/simultaneous prod deploy or full-stack release. Only for /src/lissa-health/ projects."
---

# Lissa Coordinated Production Deploy

> **Project:** Lissa Health (`/src/lissa-health/`)

This skill orchestrates a coordinated backend+frontend production release to prevent API contract drift.

## Scope detection

Not every deploy involves all repositories. Before orchestrating:

1. **Ask or infer** which repos need deploying: `backend`, `frontend`, `public-site`, or a combination.
2. **Single-repo deploy**: If only one repo is requested, use the corresponding individual deploy skill (`lissa-backend-deploy` or `lissa-frontend-deploy`) directly. No coordination needed.
3. **Coordinated deploy**: Use this skill only when deploying both `backend` AND `frontend` together (with or without `public-site`).
4. **Public-site** is independent — it has no API contract coupling with backend/frontend and can deploy at any time.

## Strategy: Backend-First with Rapid Follow

Backend deploys first because:
- Backend APIs are backward-compatible (new endpoints added, old ones kept)
- Frontend may depend on new backend APIs immediately
- Backend deploy is faster (~2 min) vs frontend (~4 min)

## Workflow

### 1) Pre-deploy gate (both repos)

Run in parallel:
```bash
# Backend
cd /src/lissa-health/backend && git status --short --branch && git log -1 --oneline

# Frontend
cd /src/lissa-health/frontend && git status --short --branch && git log -1 --oneline
```

Both must be on `main`, clean tree, pushed to origin.

### 2) Verify staging health (both repos)

Before prod, confirm staging is green:
```bash
# Check recent successful staging deploys
cd /src/lissa-health/backend && gh run list --workflow deploy-staging-docker-image.yaml --limit 3
cd /src/lissa-health/frontend && gh run list --workflow deploy-staging-docker-image.yaml --limit 3
```

Both must have a recent successful staging deploy for the same or compatible commit.

### 3) Deploy backend to prod FIRST

```bash
cd /src/lissa-health/backend
gh workflow run deploy-prod-docker-image.yaml --ref main -f confirm_deploy=DEPLOY
```

Wait for completion:
```bash
gh run list --workflow deploy-prod-docker-image.yaml --limit 1 --json databaseId,status,conclusion
# Then watch until done
gh run watch <run-id> --exit-status
```

Verify backend health:
- `system.health` + `system.ready` on prod

### 4) Deploy frontend to prod IMMEDIATELY after backend

```bash
cd /src/lissa-health/frontend
gh workflow run deploy-prod-docker-image.yaml --ref main -f brand=lissa-health -f confirm_deploy=DEPLOY -f source_run_id=<staging-deploy-run-id>
```

Wait and verify:
```bash
gh run watch <run-id> --exit-status
```

### 5) Post-deploy cross-service verification

- Backend: `system.health`, `system.ready`
- Frontend: `https://lissa-health.com/health`
- Cross-service: attempt a Playwright login + basic API call to confirm contract compatibility

### 6) Rollback protocol

If backend deployed but frontend fails:
- Backend is backward-compatible, so old frontend still works
- Fix frontend issue and redeploy, OR rollback backend if the issue is backend-caused

If frontend deployed but backend hasn't:
- This shouldn't happen with backend-first strategy
- If it does: frontend will use existing (old) backend APIs until backend deploys

### 7) HealthVault coordination

HealthVault uses the same backend image as prod. After prod backend deploys:
```bash
cd /src/lissa-health/backend
gh workflow run deploy-healthvault-backend-docker-image.yaml --ref main -f confirm_deploy=DEPLOY
```

Frontend HealthVault uses white-label worker:
```bash
cd /src/lissa-health/frontend
gh workflow run white-label-brand-worker.yaml --ref main -f target_environment=production -f deploy=true
```

**WARNING**: The HealthVault workflow ALWAYS deploys to `/opt/lissa-health/healthvault/`, regardless of `target_environment` value. NEVER pass `remote_root=/opt/lissa-health/prod` — that would overwrite Lissa Health prod with HealthVault branding.

### Post-deploy brand verification (MANDATORY)

After ANY prod/healthvault deploy, verify brand correctness:
```bash
# Check prod is Lissa Health
docker exec lissa-health-prod-frontend grep '<title>' /usr/share/nginx/html/index.html
# Must show: <title>Lissa Health</title>

# Check healthvault is Health Vault
docker exec lissa-health-healthvault-frontend grep '<title>' /usr/share/nginx/html/index.html
# Must show: <title>Health Vault</title>
```

### 8) Timing expectations

| Step | Expected Duration |
|------|-------------------|
| Backend prod deploy | ~2 min |
| Backend health check | ~30 sec |
| Frontend prod deploy | ~4 min |
| Frontend health check | ~30 sec |
| **Total coordinated deploy** | **~7-8 min** |

### 9) Self-learning feedback

Record coordinated deploy outcomes in `/src/lissa-health/docs/_workspace/deploy-log.jsonl` with `"coordinated": true` flag. Track:
- Total wall-clock time
- Whether backend/frontend versions are contract-compatible
- Any downtime or error spikes between backend and frontend deploy windows
