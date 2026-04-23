---
name: lissa-tech-docs-authoring
description: "[Lissa Health] Правильное добавление и обновление техдоков Lissa Health (структура tech-docs, permanent vs temporary, обязательная индексация VitePress, проверка сборки). Использовать при любых изменениях в /docs. Only for /src/lissa-health/ projects."
---

# Lissa Tech Docs Authoring

> **Project:** Lissa Health (`/src/lissa-health/`)

Этот навык применяется в репозитории `/src/lissa-health/docs`.

## 1) Определить класс документа

Сначала выбрать, что именно создается:

- **Постоянная техдокументация**: архитектура, модули, ops/runbook, стандарты.
- **Временный артефакт**: разовый анализ, выгрузка, промежуточный отчет.

Правило: временное хранить только в `_workspace`, постоянное только в стабильных разделах.

## 2) Выбрать корректный путь

Постоянное:

- `tech-docs/architecture/`
- `tech-docs/modules/`
- `tech-docs/maintenance/`
- `tech-docs/ops/`
- `tech-docs/security/`
- `tech-docs/testing/`
- `tech-docs/integrations/`
- `tech-docs/api/`
- `tech-docs/product/`

Временное:

- `tech-docs/_workspace/ai-reports/` (и подпапки)

## 3) Индексация VitePress (обязательно для постоянных страниц)

Если добавляется новая постоянная страница, нужно обновить sidebar/nav:

- `/src/lissa-health/docs/tech-docs/.vitepress/config.mjs`

Нельзя добавлять `_workspace` страницы в sidebar/nav.

## 4) Быстрая проверка качества

Проверить:

- язык RU-first,
- корректная иерархия заголовков (один H1 на страницу),
- все ссылки указывают на существующие файлы,
- нет “временных” страниц в навигации.

## 5) Проверка сборки (рекомендуется)

Запустить сборку документации:

- `pnpm build`

Если сборка тяжелая, хотя бы убедиться, что не сломаны импорты/сайдбар и нет битых ссылок.

## 6) Вывод

Сформировать короткий итог:

- какие страницы добавлены/изменены,
- куда проиндексировано (sidebar/nav),
- результат `pnpm build` (если запускался),
- что остается проверить руками.

