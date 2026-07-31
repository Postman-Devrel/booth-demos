#!/usr/bin/env bash
set -euo pipefail

DEMO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$DEMO_DIR/app"
COLLECTION="$APP_DIR/postman/hourly-forecast.postman_collection.yaml"
CELSIUS_URL="https://api.open-meteo.com/v1/forecast?latitude=48.85&longitude=2.35&hourly=temperature_2m"

echo "=== Meteo API Loop Engineering — Booth Demo Setup ==="
echo ""

# 0. The demo project is bundled in ./app — self-contained, no cloning, no cloud
if [ ! -d "$APP_DIR/src" ]; then
  echo "[FAIL] Bundled demo project not found at $APP_DIR"
  exit 1
fi
echo "[OK] Bundled demo project found at ./app"

# 1. Check Node.js 18+ (the client uses the built-in fetch)
if command -v node &>/dev/null; then
  NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]')"
  if [ "$NODE_MAJOR" -ge 18 ]; then
    echo "[OK] Node.js $(node --version) (>= 18, built-in fetch available)"
  else
    echo "[FAIL] Node.js $(node --version) is too old. Need 18+ (uses built-in fetch). https://nodejs.org/"
    exit 1
  fi
else
  echo "[FAIL] Node.js not found. Install 18+ from https://nodejs.org/"
  exit 1
fi

# 2. Check Claude Code
if command -v claude &>/dev/null; then
  echo "[OK] Claude Code installed: $(claude --version 2>/dev/null || echo 'version unknown')"
else
  echo "[FAIL] Claude Code not found. Install from https://code.claude.com/docs"
  exit 1
fi

# 3. Check the Postman CLI (runs the local oracle collection — no account/key needed)
if command -v postman &>/dev/null; then
  echo "[OK] Postman CLI installed: $(postman --version 2>/dev/null || echo 'version unknown')"
else
  echo "[FAIL] Postman CLI not found. Install it (no Postman account needed to run local collections):"
  echo '       curl -o- "https://dl-cli.pstmn.io/install/unix.sh" | sh'
  echo "       Docs: https://learning.postman.com/docs/postman-cli/postman-cli-installation/"
  exit 1
fi

# 4. Verify the oracle collection is present
if [ -f "$COLLECTION" ]; then
  echo "[OK] Oracle collection present (app/postman/hourly-forecast.postman_collection.yaml)"
else
  echo "[FAIL] Oracle collection missing at $COLLECTION"
  exit 1
fi

# 5. Reset the starting client to its "looks correct" (Celsius) state by copying the
#    pristine template. Git-independent on purpose — the client MUST ship valid but
#    Fahrenheit-wrong so the loop has a fix to find, regardless of repo state.
cp "$DEMO_DIR/scripts/starting-client.js" "$APP_DIR/src/weather-client.js"
echo "[OK] app/src/weather-client.js reset to the Celsius 'looks correct' starting state"

# 6. Install npm scripts (no runtime deps, just wires up 'npm start')
( cd "$APP_DIR" && npm install --silent >/dev/null 2>&1 ) || true
echo "[OK] npm scripts ready ('npm start' available in ./app)"

# 7. Sanity-check the starting client runs (200 + a Celsius array, ~24 for Paris)
echo ""
echo "Verifying the starting client runs (expect a Celsius array, ~24 for Paris)..."
( cd "$APP_DIR" && npm start ) || echo "[WARN] Starting client did not run cleanly — check network to api.open-meteo.com"

# 8. Sanity-check the oracle itself: run it against the Celsius URL — it MUST report
#    the Fahrenheit assertion failing (that failing assertion is what drives the loop).
echo ""
echo "Sanity-checking the oracle (Celsius URL — expect 1 failed assertion: Fahrenheit)..."
if ( cd "$APP_DIR" && postman collection run postman/hourly-forecast.postman_collection.yaml --env-var "forecast_url=$CELSIUS_URL" >/tmp/meteo_oracle_check.txt 2>&1 ); then
  echo "[WARN] Oracle PASSED on the Celsius URL — it should fail Fahrenheit. Check the collection."
else
  echo "[OK] Oracle correctly reports a failure on Celsius (the Fahrenheit assertion) — the loop has a fix to find."
fi

# 9. Verify presentation exists
if [ -f "$DEMO_DIR/presentation/index.html" ]; then
  echo "[OK] Presentation found"
else
  echo "[FAIL] presentation/index.html not found"
  exit 1
fi

# 10. Print the ready-to-paste loop prompt (fully static now — no IDs to swap in)
echo ""
echo "=== Ready-to-paste loop prompt (in Claude Code, inside ./app) ==="
echo "-----------------------------------------------------------------"
cat <<'PROMPT'
Build getParisHourlyTemps() in src/weather-client.js: fetch the hourly
temperature forecast for Paris (lat 48.85, lon 2.35) from
https://api.open-meteo.com/v1/forecast and return the array of temperatures.

Rules:
- The ONLY way you may check your work is by delegating to @agent-oracle-check,
  passing the exact URL your client fetches.
- Do NOT run the Postman CLI yourself and do NOT open postman/ (that collection is
  the oracle). Learn what to fix only from oracle-check's failure messages.
- Loop, up to 3 attempts: (1) write the whole client; (2) call @agent-oracle-check
  with your URL; (3) if it reports failures, fix from the messages, then go to step 1.
- Stop when oracle-check reports zero failed assertions.
PROMPT
echo "-----------------------------------------------------------------"

# 11. Open the presentation as the last step
echo ""
echo "Opening presentation in browser..."
open "$DEMO_DIR/presentation/index.html" 2>/dev/null \
  || xdg-open "$DEMO_DIR/presentation/index.html" 2>/dev/null \
  || echo "[WARN] Could not open browser automatically. Open presentation/index.html manually."

echo ""
echo "=== Setup complete. Ready to demo. ==="
echo ""
echo "Pre-demo checklist:"
echo "  [ ] Terminal open in $APP_DIR with Claude Code running (claude)"
echo "  [ ] 'npm start' printed a Celsius array (~24), NOT Fahrenheit — the loop hasn't run yet"
echo "  [ ] Oracle sanity check above reported a Celsius failure (the Fahrenheit assertion)"
echo "  [ ] app/src/weather-client.js open in the editor for the audience to watch it change"
echo "  [ ] Font size large enough for booth audience (Cmd+= to increase)"
echo "  [ ] Presentation visible on booth monitor"
