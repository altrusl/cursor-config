---
name: lissa-code-documentation
description: Automatically update tech-docs when adding new features or changing code. Use proactively after implementing backend modules, API endpoints, frontend components, or database changes. Ensures documentation stays in sync with code.
---

# Code Documentation Skill

Автоматическое обновление документации при добавлении/изменении кода.

## Когда использовать

Skill активируется автоматически после:
- Создания нового модуля/сервиса в backend
- Добавления JSON-RPC endpoint'ов
- Изменения схемы базы данных
- Добавления frontend компонентов/views
- Создания новых AI prompts/schemas

## Workflow

### 1. Определи тип изменения

| Тип | Документация | Путь |
|-----|--------------|------|
| Новый backend модуль | Module overview | `tech-docs/modules/{domain}/{module}/` |
| JSON-RPC методы | API reference | `tech-docs/modules/{domain}/{module}/api-reference.md` |
| Database schema | Module docs + schema | `tech-docs/modules/{domain}/{module}/database.md` |
| Frontend component | Module frontend docs | `tech-docs/modules/{domain}/{module}/frontend.md` |
| AI prompt/schema | AI module docs | `tech-docs/modules/ai/{module}/` |

### 2. Собери контекст

```bash
# Для backend модуля — используй backend-info MCP
backend_get_package <module-name>

# Для API — получи методы
backend_get_api

# Для схемы БД
backend_get_schema <table-name>
```

### 3. Создай/обнови документацию

#### Для нового модуля

Создай структуру:
```
modules/{domain}/{module}/
├── overview.md      # Что, зачем, как использовать
├── api-reference.md # JSON-RPC методы (если есть)
├── architecture.md  # Компоненты и связи (если сложный)
└── frontend.md      # UI компоненты (если есть)
```

#### Шаблон overview.md

```markdown
# {Module Name}

{Одно предложение: что делает модуль.}

## Ключевые возможности

- **{Feature 1}** — {описание}
- **{Feature 2}** — {описание}

## Архитектура

{Диаграмма или описание компонентов}

## Быстрый старт

\`\`\`php
// Пример использования
\`\`\`

## Связанные документы

- [API Reference](./api-reference.md)
```

#### Шаблон api-reference.md

```markdown
# {Module} API Reference

## Методы

### {namespace}.{method}

{Описание.}

**Параметры:**

| Параметр | Тип | Обязательный | Описание |
|----------|-----|--------------|----------|
| `param` | `type` | Да/Нет | Описание |

**Возвращает:**

\`\`\`typescript
interface Response {
  field: type;
}
\`\`\`

**Пример:**

\`\`\`json
// Request
{"method": "{namespace}.{method}", "params": {...}}

// Response
{"result": {"data": {...}}}
\`\`\`
```

### 4. Обнови sidebar

Добавь новые файлы в `/tech-docs/.vitepress/sidebars/{sidebar}.mjs`.

### 5. Проверь build

```bash
cd /src/lissa-health/docs && pnpm build
```

## Стиль документации

### Основной: Лаконичный инженерный

- Минимум слов, максимум информации
- Прямые утверждения, активный залог
- Таблицы для параметров и сравнений
- Код вместо описаний где возможно

### Правила

1. **RU-first** — документация на русском
2. **Один H1** на документ
3. **Первое предложение** — суть (что это)
4. **Нет "воды"** — каждое предложение информативно
5. **Примеры** — конкретные, не абстрактные

### Терминология

| Термин | Значение |
|--------|----------|
| Пациент | Конечный пользователь |
| Врач | Медицинский специалист |
| Запись | health_record |
| Документ | document_asset (файл) |
| Модуль | Функциональный блок backend |

## Чек-лист

После добавления функционала:

- [ ] Создан/обновлён overview.md для модуля
- [ ] API методы задокументированы (если добавлены)
- [ ] Database changes описаны (если есть)
- [ ] Файлы добавлены в sidebar
- [ ] Build проходит без ошибок
- [ ] Ссылки работают

## Примеры

### Добавлен новый endpoint

```
Реализован: clinic.patients — список пациентов врача

→ Обновить: tech-docs/modules/business/clinic/api-reference.md
→ Добавить секцию для clinic.patients с параметрами и примером
```

### Создан новый модуль

```
Создан: src/Billing/ — модуль биллинга

→ Создать: tech-docs/modules/business/billing/
→ Файлы: overview.md, api-reference.md
→ Обновить: sidebars/modules.mjs
```

### Изменена схема БД

```
Добавлена таблица: clinic_audit_log

→ Обновить: tech-docs/modules/business/clinic/database.md
→ Добавить описание таблицы и полей
```
