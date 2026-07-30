#!/usr/bin/env bash
set -euo pipefail

DEMO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$DEMO_DIR/app"

echo "=== Meteo API Loop Engineering — Booth Demo Teardown ==="
echo ""

# 1. Reset the bundled client back to its "looks correct" (Celsius) starting state.
#    app/ is tracked by this booth-demos repo, so restore the file from git.
if git -C "$DEMO_DIR" rev-parse --is-inside-work-tree &>/dev/null; then
  git -C "$DEMO_DIR" checkout -- "$APP_DIR/src/weather-client.js" 2>/dev/null \
    && echo "[OK] app/src/weather-client.js reset to the Celsius starting state" \
    || echo "[WARN] Could not git-restore weather-client.js — check it manually (no temperature_unit param)."
else
  echo "[WARN] Not inside a git repo — reset app/src/weather-client.js manually."
fi

# 2. Remove the Postman cloud oracle (collection, environment, and the workspace
#    if setup created it). This reads app/oracle.ids.json and also deletes it.
echo ""
echo "Removing the Postman oracle (workspace, collection, environment)..."
node "$DEMO_DIR/scripts/postman-teardown.mjs" "$APP_DIR"

# 3. Remove the local .env (regenerated from .env.example on next setup)
if [ -f "$APP_DIR/.env" ]; then
  rm "$APP_DIR/.env"
  echo "[OK] Removed app/.env (regenerated on next setup from .env.example)"
fi

echo ""
echo "=== Teardown complete. Run ./scripts/setup.sh before the next demo. ==="
echo ""
echo "Full reset between demo days:"
echo "  ./scripts/teardown.sh   # reset client, clear cached IDs, remind on cloud cleanup"
echo "  ./scripts/setup.sh      # verify tools, sanity-run npm start, open the deck"
