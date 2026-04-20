#!/bin/bash
# Run Lighthouse performance audit on a local dist directory
# Usage: ./run-lighthouse.sh <dist-dir> [port] [path] [categories]
# Example: ./run-lighthouse.sh /path/to/dist 3333 /landing performance

set -euo pipefail

DIST_DIR="${1:?Usage: run-lighthouse.sh <dist-dir> [port] [path] [categories]}"
PORT="${2:-4173}"
URL_PATH="${3:-/}"
CATEGORIES="${4:-performance}"
REPORT_DIR="${DIST_DIR}/.."
REPORT_NAME="lighthouse-report"

if [ ! -d "$DIST_DIR" ]; then
  echo "Error: dist directory '$DIST_DIR' does not exist"
  exit 1
fi

# Check dependencies
command -v npx >/dev/null 2>&1 || { echo "Error: npx not found"; exit 1; }

CHROME_BIN=""
for bin in google-chrome-stable google-chrome chromium-browser chromium; do
  if command -v "$bin" >/dev/null 2>&1; then
    CHROME_BIN="$bin"
    break
  fi
done

if [ -z "$CHROME_BIN" ]; then
  echo "Error: No Chrome/Chromium found. Install google-chrome or chromium-browser."
  exit 1
fi

echo "Using Chrome: $CHROME_BIN"

# Start static server
echo "Starting server on port $PORT..."
npx serve "$DIST_DIR" -l "$PORT" -s &
SERVER_PID=$!
sleep 2

cleanup() {
  echo "Stopping server (PID $SERVER_PID)..."
  kill "$SERVER_PID" 2>/dev/null || true
}
trap cleanup EXIT

URL="http://localhost:${PORT}${URL_PATH}"
echo "Running Lighthouse on $URL (categories: $CATEGORIES)..."

# Build --only-categories flags
IFS=',' read -ra CATS <<< "$CATEGORIES"
CAT_FLAGS=""
for cat in "${CATS[@]}"; do
  CAT_FLAGS="$CAT_FLAGS --only-categories=$cat"
done

npx lighthouse "$URL" \
  --output=json --output=html \
  --output-path="$REPORT_DIR/$REPORT_NAME" \
  --chrome-flags="--headless --no-sandbox --disable-gpu" \
  $CAT_FLAGS \
  2>&1

echo ""
echo "Reports saved:"
echo "  HTML: $REPORT_DIR/${REPORT_NAME}.report.html"
echo "  JSON: $REPORT_DIR/${REPORT_NAME}.report.json"
echo ""

# Parse and display key metrics
node -e "
const r = require('$REPORT_DIR/${REPORT_NAME}.report.json');
const perf = r.categories.performance;
if (perf) {
  console.log('Performance Score: ' + Math.round(perf.score * 100) + '/100');
  const metrics = ['first-contentful-paint','largest-contentful-paint','speed-index','total-blocking-time','cumulative-layout-shift','interactive'];
  metrics.forEach(m => { const a = r.audits[m]; if (a) console.log('  ' + a.title + ': ' + a.displayValue); });
  console.log('');
  const uj = r.audits['unused-javascript'];
  if (uj && uj.details && uj.details.items && uj.details.items.length) {
    console.log('Unused JS:');
    uj.details.items.forEach(i => { console.log('  ' + i.url.split('/').pop() + ': ' + Math.round(i.wastedBytes/1024) + ' KB'); });
  }
}
" 2>/dev/null || true
