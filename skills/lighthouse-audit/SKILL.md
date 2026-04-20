---
name: lighthouse-audit
description: Run Google Lighthouse audits on local dist/build directories in headless mode. Use when the user asks to audit a website's performance, run Lighthouse, check page speed, analyze Core Web Vitals, or optimize loading performance. Works on remote servers (headless Chrome) and local machines.
---

# Lighthouse Audit

## Prerequisites

- Node.js with npx
- Chrome or Chromium installed (headless mode)

## Quick Start

Run `scripts/run-lighthouse.sh` with the dist directory path:

```bash
bash <skill-dir>/scripts/run-lighthouse.sh /path/to/dist 4173 /landing performance
```

Arguments: `<dist-dir> [port] [path] [categories]`

- `dist-dir`: path to built static files (required)
- `port`: local server port (default: 4173)
- `path`: URL path to audit (default: `/`)
- `categories`: comma-separated Lighthouse categories (default: `performance`)
  - Available: `performance`, `accessibility`, `best-practices`, `seo`

The script starts a local static server, runs Lighthouse, stops the server, and prints key metrics.

## Output

Reports are saved next to the dist directory:
- `lighthouse-report.report.html` — visual report (open in browser)
- `lighthouse-report.report.json` — machine-readable data

## Parsing JSON Results

```bash
node -e "
const r = require('./lighthouse-report.report.json');
console.log('Score:', Math.round(r.categories.performance.score * 100));
Object.values(r.audits)
  .filter(a => a.details?.type === 'opportunity' && a.score < 1)
  .forEach(a => console.log(a.title + ':', a.displayValue));
"
```

## Key Audits to Check

| Audit | What to look for |
|-------|-----------------|
| `unused-javascript` | Large bundles with low usage ratio |
| `unused-css-rules` | CSS bloat |
| `render-blocking-resources` | Scripts/styles blocking FCP |
| `total-byte-weight` | Oversized network payloads |
| `mainthread-work-breakdown` | Heavy JS execution |
| `bootup-time` | Per-script execution time |

## Troubleshooting

- **No Chrome found**: Install `google-chrome-stable` or `chromium-browser`
- **Port in use**: Change port argument
- **Headless fails**: Ensure `--no-sandbox` is passed (already included)
- **Low scores on localhost**: Lighthouse simulates mobile 4G throttling; localhost latency is still factored out
