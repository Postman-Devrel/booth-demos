#!/usr/bin/env bash
set -uo pipefail

# {{name}} — teardown.
#
# Run this after every session. It must be safe to run when setup never ran,
# and it must leave the folder exactly as a fresh clone would.
#
# Contract:
#   - stop anything setup.sh started;
#   - delete generated artifacts and scratch state;
#   - restore any file the session edited in place;
#   - never fail hard — a teardown that exits early leaves the next session dirty.

CONTENT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
STATE="$CONTENT_DIR/.demo-state"

echo "=== {{name}} — Teardown ==="
echo ""

# --- Stop what setup started ------------------------------------------------

if [ -f "$STATE" ]; then
  PID="$(cat "$STATE" 2>/dev/null || true)"
  if [ -n "${PID:-}" ] && kill "$PID" 2>/dev/null; then
    echo "[OK]   Stopped background process $PID"
  else
    echo "[OK]   Nothing left running"
  fi
  rm -f "$STATE"
fi

# --- Remove generated artifacts ---------------------------------------------

# rm -rf "$CONTENT_DIR/workspace"          # provisioned clones
# rm -f  "$CONTENT_DIR/.mcp.json"          # MCP servers registered live
# git -C "$CONTENT_DIR" checkout -- app/   # files edited on stage

echo "[OK]   Generated artifacts removed"

# --- Verify clean -----------------------------------------------------------

echo ""
echo "=== Teardown complete. ==="
echo "Next session:  ./scripts/setup.sh"
