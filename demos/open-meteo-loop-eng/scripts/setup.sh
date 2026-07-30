#!/usr/bin/env bash
set -euo pipefail

DEMO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$DEMO_DIR/app"

echo "=== Meteo API Loop Engineering — Booth Demo Setup ==="
echo ""

# 0. The demo project is bundled in ./app — no cloning, works offline for tooling
if [ ! -d "$APP_DIR/src" ]; then
  echo "[FAIL] Bundled demo project not found at $APP_DIR"
  echo "       This demo ships the project in ./app — re-check out this folder."
  exit 1
fi
echo "[OK] Bundled demo project found at ./app"

# 1. Check Node.js 18+
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

# 3. Check POSTMAN_API_KEY (the MCP server needs it to create/run collections)
if [ -n "${POSTMAN_API_KEY:-}" ]; then
  echo "[OK] POSTMAN_API_KEY is set"
else
  echo "[FAIL] POSTMAN_API_KEY is not set — the Postman MCP Server can't create or run collections without it."
  echo "       Get a key: https://learning.postman.com/docs/developer/postman-api/authentication/"
  echo "       Then:  export POSTMAN_API_KEY=PMAK-your-key-here"
  exit 1
fi

# 4. Reset the starting client to its "looks correct" (Celsius) state.
#    The bundled copy is tracked by this booth-demos repo, so we restore it from git.
#    This is essential: it must ship valid-but-Fahrenheit-wrong so the loop has a fix to find.
if git -C "$DEMO_DIR" rev-parse --is-inside-work-tree &>/dev/null; then
  git -C "$DEMO_DIR" checkout -- "$APP_DIR/src/weather-client.js" 2>/dev/null \
    && echo "[OK] app/src/weather-client.js reset to the Celsius 'looks correct' starting state" \
    || echo "[WARN] Could not git-restore weather-client.js (uncommitted?). Verify it has no temperature_unit param."
else
  echo "[WARN] Not inside a git repo — cannot auto-reset weather-client.js. Check it manually."
fi

# 5. Install npm scripts (no runtime deps, just wires up 'npm start')
( cd "$APP_DIR" && npm install --silent >/dev/null 2>&1 ) || true
echo "[OK] npm scripts ready ('npm start' available in ./app)"

# 6. Ensure app/.env exists so .mcp.json can read ${POSTMAN_API_KEY} (no secret committed)
if [ ! -f "$APP_DIR/.env" ]; then
  cp "$APP_DIR/.env.example" "$APP_DIR/.env"
fi
echo "[OK] app/.env present (reads \${POSTMAN_API_KEY} — nothing secret is committed)"

# 7. Provision the Postman oracle (workspace + collection with the test + environment).
#    This replaces the old oracle-setup agent, so the demo env is ready before the first
#    attendee. It prints the collectionUid/environmentUid and a ready-to-paste loop prompt.
echo ""
echo "Provisioning the Postman oracle..."
node "$DEMO_DIR/scripts/postman-setup.mjs" "$APP_DIR"

# 8. Sanity-check the starting client actually runs (200 + a Celsius array, ~24 for Paris)
echo ""
echo "Verifying the starting client runs (expect a Celsius array, ~24 for Paris)..."
( cd "$APP_DIR" && npm start ) || echo "[WARN] Starting client did not run cleanly — check network to api.open-meteo.com"

# 9. Verify presentation exists
if [ -f "$DEMO_DIR/presentation/index.html" ]; then
  echo "[OK] Presentation found"
else
  echo "[FAIL] presentation/index.html not found"
  exit 1
fi

# 10. Open the presentation as the last step
echo ""
echo "Opening presentation in browser..."
open "$DEMO_DIR/presentation/index.html" 2>/dev/null \
  || xdg-open "$DEMO_DIR/presentation/index.html" 2>/dev/null \
  || echo "[WARN] Could not open browser automatically. Open presentation/index.html manually."

echo ""
echo "=== Setup complete. Ready to demo. ==="
echo ""
echo "Pre-demo checklist:"
echo "  [ ] Oracle provisioned above — copy the collectionUid/environmentUid (and the loop prompt)"
echo "  [ ] Opened the workspace via the printed 'workspace URL' (Personal visibility — not in the team list)"
echo "  [ ] Terminal open in $APP_DIR with Claude Code running (claude)"
echo "  [ ] Postman MCP Server approved when Claude Code prompts (app/.mcp.json auto-loads)"
echo "  [ ] 'npm start' printed a Celsius array (~24), NOT Fahrenheit — the loop hasn't run yet"
echo "  [ ] app/src/weather-client.js open in the editor for the audience to watch it change"
echo "  [ ] Postman app/web open on the 'open-meteo-loop-eng' workspace (via the URL) for the payoff"
echo "  [ ] Font size large enough for booth audience (Cmd+= to increase)"
echo "  [ ] Presentation visible on booth monitor"
