---
name: lissa-public-site-translations
description: "[Lissa Health] Manage public-site translations across 5 locales (ru/en/es/fr/de). Detect missing and stale translations relative to Russian source, batch-translate with quality checks. Use when adding content or checking translation coverage. Only for /src/lissa-health/ projects."
---

# Lissa Public Site Translations

> **Project:** `/src/lissa-health/public-site/` — VitePress public website (landing, help, wiki, blog).

**Source of truth:** Russian (`ru`). **Target locales:** `en` (full coverage), `es`, `fr`, `de` (partial — ~16 pages each, ~91 missing vs RU).

## Content map

| Content type | RU source path | Target path pattern |
|---|---|---|
| VitePress pages | `docs/ru/**` | `docs/{locale}/**` (same relative path) |
| Help body (shared) | `docs/.vitepress/content/base/help/ru/` | `docs/.vitepress/content/base/help/{locale}/` |
| Help body (brand) | `docs/.vitepress/content/brands/{brand}/help/ru/` | `docs/.vitepress/content/brands/{brand}/help/{locale}/` |
| Landing copy | `docs/.vitepress/content/landing/locales/ru.json5` | `docs/.vitepress/content/landing/locales/{locale}.json5` |

**Help resolution chain** (see `white-label-branding.mdc`):
1. `content/brands/{brandId}/help/{locale}/{slug}.md`
2. `content/base/help/{locale}/{slug}.md`
3. `docs/{locale}/help/{slug}.md` — routing stub (frontmatter only)

When translating help: update **body** in `content/base/` or `content/brands/`; keep **route stub** in `docs/{locale}/help/` in sync (frontmatter + JSON-LD).

---

## Workflow (always follow this order)

```
1. Scan missing + stale translations
2. Present prioritized report
3. Translate batch-by-batch (help → wiki → blog → biomarkers)
4. Run pnpm build after each batch
5. Summarize what was done and what remains
```

Default target locales for gap-filling: `es`, `fr`, `de`. Include `en` only for stale updates or new RU content.

---

## Step 1 — Scan

Run from `/src/lissa-health/public-site/`:

```bash
cd /src/lissa-health/public-site
LOCALES="en es fr de"
```

### 1a. Scan markdown pages (`docs/ru/`)

```bash
scan_docs_pages() {
  local locale="$1"
  find docs/ru -name '*.md' -type f | sort | while read -r ru; do
    rel="${ru#docs/ru/}"
    tgt="docs/${locale}/${rel}"
    if [[ ! -f "$tgt" ]]; then
      echo "MISSING|${locale}|docs|${rel}"
    elif [[ "$ru" -nt "$tgt" ]]; then
      echo "STALE|${locale}|docs|${rel}"
    fi
  done
}
for loc in $LOCALES; do scan_docs_pages "$loc"; done
```

### 1b. Scan help body content (`content/base/help/`)

```bash
scan_help_base() {
  local locale="$1"
  find docs/.vitepress/content/base/help/ru -name '*.md' -type f 2>/dev/null | sort | while read -r ru; do
    rel="${ru#docs/.vitepress/content/base/help/ru/}"
    tgt="docs/.vitepress/content/base/help/${locale}/${rel}"
    if [[ ! -f "$tgt" ]]; then
      echo "MISSING|${locale}|help-base|${rel}"
    elif [[ "$ru" -nt "$tgt" ]]; then
      echo "STALE|${locale}|help-base|${rel}"
    fi
  done
}
for loc in $LOCALES; do scan_help_base "$loc"; done
```

### 1c. Scan brand help overrides

```bash
scan_help_brands() {
  local locale="$1"
  find docs/.vitepress/content/brands -path '*/help/ru/*.md' -type f 2>/dev/null | sort | while read -r ru; do
    rel="${ru#docs/.vitepress/content/brands/}"
    rel="${rel#*/help/ru/}"
    brand="${ru#docs/.vitepress/content/brands/}"
    brand="${brand%%/help/ru/*}"
    tgt="docs/.vitepress/content/brands/${brand}/help/${locale}/${rel}"
    if [[ ! -f "$tgt" ]]; then
      echo "MISSING|${locale}|help-brand:${brand}|${rel}"
    elif [[ "$ru" -nt "$tgt" ]]; then
      echo "STALE|${locale}|help-brand:${brand}|${rel}"
    fi
  done
}
for loc in $LOCALES; do scan_help_brands "$loc"; done
```

### 1d. Scan landing locale files

```bash
ru_land="docs/.vitepress/content/landing/locales/ru.json5"
for loc in $LOCALES; do
  tgt="docs/.vitepress/content/landing/locales/${loc}.json5"
  if [[ ! -f "$tgt" ]]; then
    echo "MISSING|${loc}|landing|${loc}.json5"
  elif [[ "$ru_land" -nt "$tgt" ]]; then
    echo "STALE|${loc}|landing|${loc}.json5"
  fi
done
```

### 1e. Classify and prioritize

Assign each item a **priority** from its path:

| Priority | Pattern | Batch label |
|---|---|---|
| P1 | `help/`, `help-base`, `help-brand` | Help pages |
| P2 | `wiki/` but NOT `wiki/biomarkers/` | Wiki articles |
| P3 | `blog/` | Blog posts |
| P4 | `wiki/biomarkers/` | Biomarker pages |
| P5 | `landing`, `index.md`, `clinics.md`, `government.md` | Landing & misc |

Sort report: **P1 → P5**, then **MISSING before STALE**, then path alphabetically.

Present a concise table:

```
| Priority | Status  | Locale | Path |
|----------|---------|--------|------|
| P1 Help  | MISSING | es     | help/lab-results.md |
```

Include counts per locale and per priority at the top.

---

## Step 2 — Translate

Work **one batch at a time** (default batch size: 5–10 files). Ask user which locales to target if not specified; default to `es`, `fr`, `de`.

### General rules

1. **Read RU source first**, then create or update the target file.
2. **Preserve structure exactly**: frontmatter keys, HTML class names, SVG markup, table layout, heading hierarchy.
3. **Never translate** `{appName}` — keep literal `{appName}` everywhere it appears.
4. **Never translate** code blocks, JSON keys, URLs, file paths, CSS class names, `@type` schema values, biomarker English names in parentheses (e.g. `Glucose`, `TSH`).
5. **Translate** frontmatter `title`, `description`, JSON-LD string values (`name`, `text`, `usedToDiagnose`, etc.) — but keep `{appName}` and schema `@type`/`@context` unchanged.
6. **Medical terminology**: use standard clinical terms in the target language; keep SI units (ммоль/л → mmol/L with locale-appropriate decimal separator).
7. **Internal links**: use locale-prefixed paths (`/es/help/faq`, not `/ru/...`).
8. **Match file location** to content type (see content map above).

### By content type

**VitePress markdown pages** (`docs/{locale}/...`):
- Copy frontmatter structure from RU; translate human-readable fields.
- For help route stubs: body may be empty or minimal — real content lives in `content/base/help/`.
- Biomarker pages: preserve `MedicalWebPage` + `MedicalTest` JSON-LD; translate `name`, `about.name`, `usedToDiagnose`; keep `@type`, dates, `audienceType`.

**Help body** (`content/base/help/{locale}/` or `content/brands/...`):
- Translate HTML body text inside existing tags; do not restructure DOM.
- Preserve all `<svg>`, `<div class="...">`, `<section>` wrappers.

**Landing JSON5** (`content/landing/locales/{locale}.json5`):
- Mirror RU key structure exactly; translate string values only.
- Keep `{appName}` placeholders; do not change key names or nesting.

### Locale tone

| Locale | Notes |
|---|---|
| `en` | Professional, clear medical English |
| `es` | Neutral Latin American / international Spanish |
| `fr` | Standard French medical terminology |
| `de` | Standard German (`Sie`-form for user-facing text) |

---

## Step 3 — Quality check after each batch

From `/src/lissa-health/public-site/`:

```bash
pnpm build
```

If build fails:
- Fix broken frontmatter YAML, unclosed quotes, or invalid JSON-LD first.
- Re-run build before starting the next batch.

Optional smoke (after larger batches):

```bash
pnpm test:smoke
```

### Post-translation checklist (per file)

- [ ] `{appName}` preserved (not translated or replaced with brand name)
- [ ] Frontmatter keys unchanged; only values translated
- [ ] JSON-LD valid JSON; `@context` / `@type` untouched
- [ ] Code blocks and URLs unchanged
- [ ] Locale-appropriate links (`/{locale}/...`)
- [ ] Medical terms accurate; units consistent

---

## Step 4 — Report

After each batch and at session end, output:

1. **Translated** — list of files created/updated (locale + path)
2. **Build result** — pass/fail + error summary if fail
3. **Remaining gaps** — re-run scan snippet for updated counts
4. **Next batch suggestion** — next P1/P2/P3/P4 items

---

## Common scenarios

### New RU help page added

1. Add RU body: `content/base/help/ru/{slug}.md`
2. Add RU route stub: `docs/ru/help/{slug}.md` (frontmatter + JSON-LD)
3. Mirror both for each target locale
4. Build

### RU biomarker page updated

1. Translate updated sections only if target exists; full re-translate if stale
2. Preserve biomarker slug in filename (`glucose.md`, not translated)
3. Update `lastReviewed` in JSON-LD if medically revised

### Brand-specific legal pages

Translate in `content/brands/{brand}/help/{locale}/` for `documentation`, `privacy-policy`, `terms`. Health Vault and Lissa Health have separate RU/EN sets; extend to es/fr/de when requested.

---

## Reference

- Project rules: `/src/lissa-health/public-site/.cursor/rules/project-rules.mdc`
- Help/brand architecture: `/src/lissa-health/public-site/.cursor/rules/white-label-branding.mdc`
- Product knowledge: `/src/lissa-health/organization/content/knowledge-base/`
