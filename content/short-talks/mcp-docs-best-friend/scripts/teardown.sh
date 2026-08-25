#!/usr/bin/env bash
set -uo pipefail

# Make MCPs Your Documentation Best Friend — teardown.
#
# The live state this demo creates is the static server in front of site/,
# the /tmp/myhealthcare folder used in Act 7e, and the MCP server registered
# with the claude CLI. Everything else is files in the repo. `--purge`
# additionally drops the generated spec bundle so setup rebuilds it.

DEMO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
STATE="$DEMO_DIR/.demo-state"
BUNDLE="$DEMO_DIR/site/assets/spec-bundle.js"
PORT="${PORT:-4173}"
WORKDIR="/tmp/myhealthcare"
MCP_NAME="myhealthcare-docs"

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

# --- Act 7e state -----------------------------------------------------------
# The folder must be gone, not just emptied — "clean machine, empty folder" is
# a line in the talk track, and setup.sh recreates it.

if [ -d "$WORKDIR" ]; then
  rm -rf "$WORKDIR"
  echo "[OK]   Removed $WORKDIR (setup.sh recreates it empty)"
else
  echo "[OK]   No $WORKDIR to remove"
fi

# Unregister the docs MCP server, so Act 7e is a genuine first-time connect
# next run instead of `claude mcp add` erroring on an existing name.
if command -v claude >/dev/null 2>&1; then
  if claude mcp list 2>/dev/null | grep -q "$MCP_NAME"; then
    if claude mcp remove "$MCP_NAME" >/dev/null 2>&1; then
      echo "[OK]   Unregistered the '$MCP_NAME' MCP server"
    else
      echo "[WARN] Could not remove '$MCP_NAME' — run: claude mcp remove $MCP_NAME"
    fi
  else
    echo "[OK]   No '$MCP_NAME' MCP server registered"
  fi
else
  echo "[WARN] claude CLI not found — if '$MCP_NAME' is registered, remove it by hand"
fi

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
echo "[OK]   No credentials, no cloud state, nothing changed in Postman or on the Fern site"

cat <<'EOF'

Three things this script CANNOT do for you — do them by hand:
  1. Clear your Claude Code session. A warm context already knows the Act 7f answer
     and will reply without calling the MCP tool, which kills the payoff.
  2. Re-check Safari: Develop -> Disable JavaScript. It survives restarts, not updates.
  3. Reset the deck to slide 1 and collapse any endpoints you expanded in the portal.

Then re-run ./scripts/setup.sh.

=== Teardown complete. ===
EOF
