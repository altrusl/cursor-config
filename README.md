# cursor-config

Централизованный репозиторий с конфигурацией Cursor для всех проектов.

## Структура

```
cursor-config/
├── skills/
│   ├── file-to-markdown/     # Конвертация документов в MD
│   ├── lighthouse-audit/     # Аудит производительности
│   └── lissa/               # Lissa Health skills
│       ├── lissa-ai-pipeline-smoke/
│       ├── lissa-backend-deploy/
│       ├── lissa-backend-qa-guard/
│       ├── lissa-code-documentation/
│       ├── lissa-cursor-rules-maintenance/
│       ├── lissa-deploy-environments/
│       ├── lissa-frontend-deploy/
│       ├── lissa-frontend-qa-guard/
│       ├── lissa-incident-postmortem/
│       ├── lissa-jsonrpc-contract-guard/
│       ├── lissa-release-notes-from-commits/
│       ├── lissa-server-logs-db-debug/
│       └── lissa-tech-docs-authoring/
├── rules/                   # Общие правила
├── agents/                  # Subagents конфигурация
└── claude/                  # Claude-специфичные настройки
```

## Использование

### Глобальные skills (для всех проектов)

```bash
ln -s /src/cursor-config/skills ~/.cursor/skills
```

### Project-specific skills (через симлинки в .cursor/skills/)

В каждом репозитории Lissa Health:

```bash
# Backend
ln -sf /src/cursor-config/skills/lissa/* backend/.cursor/skills/

# Frontend
ln -sf /src/cursor-config/skills/lissa/* frontend/.cursor/skills/

# Docs
ln -sf /src/cursor-config/skills/lissa/* docs/.cursor/skills/
```

## Lissa Health Skills

| Skill | Назначение |
|-------|------------|
| `lissa-code-documentation` | Автоматическое обновление документации при добавлении кода |
| `lissa-backend-qa-guard` | Backend quality gate (format, PHPStan, tests) |
| `lissa-frontend-qa-guard` | Frontend quality gate (lint, type-check, Playwright) |
| `lissa-backend-deploy` | Деплой backend на staging/prod |
| `lissa-frontend-deploy` | Деплой frontend на staging/prod |
| `lissa-deploy-environments` | Координация деплоя между окружениями |
| `lissa-ai-pipeline-smoke` | Smoke-тест AI document processing |
| `lissa-tech-docs-authoring` | Правильное добавление техдоков |
| `lissa-jsonrpc-contract-guard` | Консистентность JSON-RPC контрактов |
| `lissa-incident-postmortem` | Structured postmortem с RCA |
| `lissa-server-logs-db-debug` | Диагностика серверов и БД |
| `lissa-release-notes-from-commits` | Генерация release notes |
| `lissa-cursor-rules-maintenance` | Maintenance cursor rules |

## Что НЕ хранить в git

- `~/.cursor/projects/` — локальный state
- `~/.cursor/mcp.json` — может содержать токены
- `*.pem`, `*.key`, `.env` — секреты

## Синхронизация

При добавлении нового skill в Lissa Health:

```bash
# 1. Создать skill в репозитории (например, backend/.cursor/skills/lissa-new-skill/)
# 2. Скопировать в cursor-config
cp -r backend/.cursor/skills/lissa-new-skill /src/cursor-config/skills/lissa/

# 3. Обновить симлинки в других репозиториях
ln -sf /src/cursor-config/skills/lissa/lissa-new-skill frontend/.cursor/skills/
ln -sf /src/cursor-config/skills/lissa/lissa-new-skill docs/.cursor/skills/

# 4. Commit в cursor-config
cd /src/cursor-config && git add . && git commit -m "Add lissa-new-skill"
```
