# cursor-config

Централизованный репозиторий с конфигурацией Cursor — **единственный source of truth** для skills и rules.

## Установка

```bash
# Skills доступны глобально через симлинк
ln -sf /src/cursor-config/skills ~/.cursor/skills

# Agents (если используются)
ln -sf /src/cursor-config/agents ~/.cursor/agents
```

## Структура

```
cursor-config/
├── skills/
│   ├── file-to-markdown/     # Общий: конвертация документов
│   ├── lighthouse-audit/     # Общий: аудит производительности
│   └── lissa/               # Lissa Health project skills
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

## Lissa Health Skills

Все skills с префиксом `lissa-` предназначены **только для проекта Lissa Health** (`/src/lissa-health/`).

| Skill | Назначение |
|-------|------------|
| `lissa-code-documentation` | Автообновление документации при добавлении кода |
| `lissa-backend-qa-guard` | Backend quality gate (format, PHPStan, tests) |
| `lissa-frontend-qa-guard` | Frontend quality gate (lint, type-check) |
| `lissa-backend-deploy` | Деплой backend на staging/prod |
| `lissa-frontend-deploy` | Деплой frontend на staging/prod |
| `lissa-deploy-environments` | Координация деплоя между окружениями |
| `lissa-ai-pipeline-smoke` | Smoke-тест AI document processing |
| `lissa-tech-docs-authoring` | Добавление техдоков в VitePress |
| `lissa-jsonrpc-contract-guard` | Консистентность JSON-RPC контрактов |
| `lissa-incident-postmortem` | Structured postmortem с RCA |
| `lissa-server-logs-db-debug` | Диагностика серверов и БД |
| `lissa-release-notes-from-commits` | Генерация release notes |
| `lissa-cursor-rules-maintenance` | Maintenance cursor rules |

## Как это работает

1. `~/.cursor/skills` → симлинк на `/src/cursor-config/skills`
2. Cursor видит все skills из этой директории
3. Skills с `[Lissa Health]` в description применяются только при работе с `/src/lissa-health/`
4. Общие skills (file-to-markdown, lighthouse-audit) доступны везде

## Добавление нового skill

```bash
# 1. Создать директорию
mkdir -p skills/lissa/lissa-new-skill

# 2. Создать SKILL.md
cat > skills/lissa/lissa-new-skill/SKILL.md << 'EOF'
---
name: lissa-new-skill
description: "[Lissa Health] Description here. Only for /src/lissa-health/ projects."
---

# Skill Name

> **Project:** Lissa Health (`/src/lissa-health/`)

...content...
EOF

# 3. Commit
git add . && git commit -m "feat(skills): add lissa-new-skill"
```

## Что НЕ хранить в git

- `~/.cursor/mcp.json` — может содержать токены
- `~/.cursor/projects/` — локальный state
- Секреты: `*.pem`, `*.key`, `.env`
