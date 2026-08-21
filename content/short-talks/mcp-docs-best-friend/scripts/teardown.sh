#!/usr/bin/env bash
set -uo pipefail

# Make MCPs Your Documentation Best Friend — teardown.
#
# The only live state this demo creates is the static server in front of
# site/. Everything else is files in the repo. `--purge` additionally drops
# the generated spec bundle so the next setup rebuilds it from openapi/.

DEMO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
STATE="$DEMO_DIR/.demo-state"
BUNDLE="$DEMO_DIR/site/assets/spec-bundle.js"
PORT="${PORT:-4173}"

PURGE=0
[ "${1:-}" = "--purge" ] && PURGE=1

echo "=== Make MCPs Your Documentation Best Friend — Teardown ==="
echo ""

# --- Stop the portal server -------------------------------------------------

STOPPED=0
if [ -f "$STATE" ]; then
  PID="$(cat "$STATE" 2>/dev/null)"
  if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
    kill "$PID" 2>/dev/null
    sleep 0.5
    kill -0 "$PID" 2>/dev/null && kill -9 "$PID" 2>/dev/null
    echo "[OK]   Stopped the portal server (pid $PID)"
    STOPPED=1
  fi
  rm -f "$STATE"
fi

# Catch a server started by hand, or one whose pid file was lost.
LEFT="$(lsof -ti tcp:"$PORT" 2>/dev/null || true)"
if [ -n "$LEFT" ]; then
  # shellcheck disable=SC2086
  kill $LEFT 2>/dev/null
  sleep 0.5
  STILL="$(lsof -ti tcp:"$PORT" 2>/dev/null || true)"
  # shellcheck disable=SC2086
  [ -n "$STILL" ] && kill -9 $STILL 2>/dev/null
  echo "[OK]   Freed port $PORT"
  STOPPED=1
fi
[ "$STOPPED" -eq 0 ] && echo "[OK]   No portal server running"

rm -f /tmp/mcp-docs-portal.log

# --- Generated artifacts ----------------------------------------------------

if [ "$PURGE" -eq 1 ]; then
  rm -f "$BUNDLE"
  echo "[OK]   Removed the generated spec bundle (setup.sh rebuilds it from openapi/)"
else
  echo "[OK]   Kept site/assets/spec-bundle.js (rebuilt on every setup anyway)"
fi

# --- Things the demo does NOT leave behind ----------------------------------
# Say this out loud so nobody goes hunting: the portal's "Try it" panel never
# sends a request, so there is no data to clean up anywhere.

echo "[OK]   No API calls were made — the portal's Try it panel is fully mocked"
echo "[OK]   No credentials, no cloud state, no changes to the Fern site"

cat <<'EOF'

For the next attendee:
  • Re-run ./scripts/setup.sh (or just reload the portal tab and press Home in the deck).
  • Close any expanded endpoints in the portal — a fresh page load resets them.
  • Clear your agent session — a warm context already knows the Act 7c answer and the
    failure will not land convincingly the second time.

=== Teardown complete. ===
EOF
