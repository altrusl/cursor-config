---
name: lissa-ai-pipeline-smoke
description: "[Lissa Health] Run a minimal smoke workflow for AI document processing (Documents → HealthRecords extraction/classification) with real data, logs correlation, and schema validation checks. Use after prompt/schema/pipeline changes. Only for /src/lissa-health/ projects."
---

# Lissa AI Pipeline Smoke

> **Project:** Lissa Health (`/src/lissa-health/`)

Use this skill for `/src/lissa-health/backend` after changes in:

- `src/HealthRecords/**` (classification/extraction/schemas/prompts),
- `alvita/documents/**` (extractors/text layers),
- AI task/model config (`src/Config/ai/**`),
- queue/processing orchestration.

## 1) Pick a concrete input (realistic)

Prefer a real `document_assets` entry that represents the changed category:

- lab results (tables + ref ranges),
- imaging reports (findings text),
- multilingual scans/photos,
- audio (if transcription is involved).

If database access is available, select a recent example and note its `documentAssetId`.

## 2) Run a targeted smoke via a temporary test script

Create a `test_*.php` file using the standard initialization template from `@cursor-agent-tests.mdc`.

Then execute one focused flow:

- document processing/text extraction (text layers quality + provenance),
- health record classification (type/subtype/language/confidence),
- extraction pipeline (schema-valid output, required fields present),
- post-processing (deterministic transforms like refExceed, normalization).

Keep the test narrow: one asset, one pipeline path.

## 3) Observe logs and correlation

Ensure you can trace the run end-to-end:

- use `requestId` / correlation identifier where available,
- inspect recent `logs` entries for errors/warnings,
- capture model/tokens/time metadata for the run.

## 4) Validate output quality (minimum bar)

Check:

- schema validity (no unexpected fields when `additionalProperties: false`),
- numeric parsing is stable (value vs ref ranges vs units),
- descriptive text preservation (no summarization when raw text must be preserved),
- language-sensitive cases behave as expected.

## 5) Cleanup

Remove the temporary `test_*.php` file after successful verification.

## Output

Report:

- tested asset type and ID,
- which pipeline step(s) were executed,
- pass/fail + notable issues,
- what changed to fix issues (if applicable).

