#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "== BAR 3D Cake Designer production check =="

if command -v python3 >/dev/null 2>&1; then
  echo "Validating JSON files..."
  python3 -m json.tool firebase.json >/dev/null
  python3 -m json.tool web/manifest.json >/dev/null
fi

if command -v node >/dev/null 2>&1; then
  echo "Checking JavaScript syntax..."
  while IFS= read -r -d '' file; do
    node --check "$file" >/dev/null
  done < <(find web/js -name '*.js' -print0)
else
  echo "WARN: node is not installed; skipping JS syntax check."
fi

if command -v flutter >/dev/null 2>&1; then
  echo "Running flutter pub get..."
  flutter pub get
  echo "Running flutter analyze..."
  flutter analyze
else
  echo "WARN: flutter is not installed; skipping flutter pub get/analyze."
fi

echo "Checking required production files..."
test -f web/js/vendor/three.min.js
test -f web/js/utils/performance.js
test -f PRODUCTION_OPTIMIZATION.md
test -f README.md

echo "Production check completed."
