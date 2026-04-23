---
name: lissa-cursor-rules-maintenance
description: Рефакторинг и поддержка Cursor rules/skills/agents в Lissa Health: минимизация alwaysApply, корректные globs, устранение дублей, защита от секретов, выравнивание platform SOT через organization.
---

# Lissa Cursor Rules Maintenance

Использовать, когда меняются файлы в `.cursor/rules`, `.cursor/skills`, `.cursor/agents` в любом подпроекте Lissa Health.

## Цель

Сделать правила:

- более точными (меньше конфликтов и шума),
- безопасными (без секретов и опасных инструкций),
- поддерживаемыми (organization как source of truth для платформенных стандартов).

## 1) Быстрый аудит

Проверить:

- какие файлы имеют `alwaysApply: true`,
- есть ли `globs` у больших правил,
- нет ли дублей platform-правил в backend/frontend/docs,
- нет ли “how-to/runbook” в rules там, где это должно жить в `docs/tech-docs`,
- нет ли секретов или паролей в правилах.

## 2) Политика alwaysApply

Держать `alwaysApply: true` минимальным:

- обычно 1 файл на репозиторий (короткий входной `project-rules.mdc`),
- индексы (`rules-index.mdc`) не должны быть alwaysApply,
- всё остальное либо scoped через `globs`, либо как справочные правила без alwaysApply.

## 3) globs (обязательно для “крупных” правил)

Добавлять `globs`, чтобы правило применялось только там, где релевантно:

- Vue-правила -> `src/**/*.vue`, `src/**/*.ts`
- backend-правила по модулю -> `src/ModuleName/**/*.php`
- docs governance -> `tech-docs/**/*.md`
- deploy-automation -> `.github/workflows/**`, `docker/**`, `scripts/**`

## 4) Organization как platform SOT

Платформенные стандарты должны жить в `organization/.cursor/rules/platform-shared-*.mdc`.

В остальных репозиториях:

- оставить тонкий `platform-shared-reference.mdc`,
- хранить только репо-специфичные добавки, которые не дублируют платформу.

## 5) Cross-links (`@...`) и навигация

Ссылки вида `@rules-index.mdc` и подобные полезны как навигация. Их стоит сохранять, но:

- ссылка должна указывать на реальный файл,
- индекс должен быть “навигатором”, а не alwaysApply правилом.

## 6) Вывод

Сделать короткий отчет:

- что стало alwaysApply и почему,
- какие globs добавлены,
- какие дубли удалены/заменены ссылками на organization,
- какие runbook части вынесены в `docs/tech-docs`,
- подтверждение, что секретов/паролей в правилах нет.

