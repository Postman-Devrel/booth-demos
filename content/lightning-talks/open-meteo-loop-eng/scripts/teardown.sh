#!/usr/bin/env bash
set -euo pipefail

DEMO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$DEMO_DIR/app"

echo "=== Meteo API Loop Engineering — Booth Demo Teardown ==="
echo ""

# Nothing runs in the cloud — the oracle is a local collection run by the Postman
# CLI. Teardown just resets the client to its starting state for the next run.

# 1. Reset the bundled client back to its "looks correct" (Celsius) starting state
#    by copying the pristine template (git-independent).
cp "$DEMO_DIR/scripts/starting-client.js" "$APP_DIR/src/weather-client.js"
echo "[OK] app/src/weather-client.js reset to the Celsius starting state"

echo ""
echo "=== Teardown complete. Run ./scripts/setup.sh before the next demo. ==="
echo ""
echo "Full reset between demo days:"
echo "  ./scripts/teardown.sh   # reset the client to Celsius"
echo "  ./scripts/setup.sh      # verify tools, sanity-run client + oracle, open the deck"
