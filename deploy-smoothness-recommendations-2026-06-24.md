# Рекомендации по улучшению деплой-процесса (2026-06-24)

## Что сломалось в реальном прогоне

1. **Квота GitHub Actions storage была исчерпана**, и даже после массовой очистки artifacts ошибки `Failed to CreateArtifact` продолжались (у GitHub есть лаг пересчета 6-12 часов).
2. Из-за этого падали не только CI-диагностики, но и **ключевые promotion-цепочки**:
   - `Backend: Build Dev` падал на upload build-manifest.
   - `Frontend: CI` падал на upload drift/typing artifacts.
   - `Frontend: Deploy Dev` и `Backend: Deploy Dev` не могли скачать отсутствующие artifacts от Build Dev.
3. **Public Site staging deploy** падал на post-deploy brand isolation smoke:
   - `https://staging.lissa-health.com/robots.txt` возвращает `Sitemap: https://lissa-health.com/sitemap.xml`.
   - Это похоже на env routing mismatch (staging домен отдает не staging SEO-конфигурацию).

## Что уже помогло в этом инциденте

- Массовая очистка artifacts через `gh` (backend/frontend/public-site).
- Снижение `retention-days` до 2 дней в workflow-файлах.
- Добавление `continue-on-error: true` на upload-artifact шаги в критичных CI/deploy местах.
- Ручной fallback на явные promote-теги (`promote_build_tag` / `promote_dev_tag`) вместо зависимости от artifact manifests.

## Что улучшить в skills/agents

1. **`deploy-coordinator`**:
   - Добавить встроенный чек на artifact quota до запуска rollout.
   - При ошибке quota автоматически переключаться в режим `explicit promote tag` (без artifact dependency).
2. **`lissa-backend-deploy` / `lissa-frontend-deploy`**:
   - Явно описать fallback-путь, если `download-artifact` не находит manifest.
   - Добавить алгоритм: "взять immutable promote source из Build Dev summary/log и задать его как workflow input".
3. **`qa-guard` skills**:
   - Добавить отдельный блок "CI storage pressure", чтобы заранее предупреждать о риске ложных фейлов.
4. **`prod-runtime-auditor`/incident skills**:
   - Добавить шаблон разделения platform incidents (quota, infra routing) vs product bugs.

## Что улучшить в workflow-дизайне

1. **Не блокировать релиз на диагностических artifacts**:
   - Все diagnostic uploads (`drift-report`, `typing-report`, evidence bundles) должны быть best-effort.
2. **Критичные promotion данные не держать только в artifacts**:
   - Дублировать manifest в `GITHUB_STEP_SUMMARY` и в workflow outputs.
   - Поддерживать прямой input-path (`promote_*_tag`) как first-class сценарий.
3. **Staging SEO/brand smoke hardening для public-site**:
   - До brand-isolation smoke проверять `build-info.json` и активный env/brand.
   - Добавить явную проверку host routing на сервере (какой compose/port реально обслуживает staging домен).
4. **Автоматическая housekeeping-очистка**:
   - Scheduled cleanup workflow по artifacts с политикой хранения и отчетом по usage.

## Быстрые action items

1. Унифицировать best-effort upload policy во всех deploy/ci workflow.
2. Добавить в deploy skills/agents автоматический fallback на `promote_*_tag`.
3. В public-site deploy добавить pre-check на корректный `SITE_HOSTNAME` routing до post-deploy smoke.
4. Добавить документированный runbook "Actions storage saturation playbook" (симптомы, fallback, rerun strategy).
