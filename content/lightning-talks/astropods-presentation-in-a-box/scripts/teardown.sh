#!/usr/bin/env bash
set -uo pipefail

# Presentation in a Box — Where Agents become Teammates — teardown.
#
# Safe to run when setup never ran. Stops the local agent containers and removes
# the scaffolded project. It does NOT touch anything deployed to the Astropods
# platform — that is a manual step, printed at the end.

CONTENT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORKSPACE="$CONTENT_DIR/workspace"
STATE="$CONTENT_DIR/.demo-state"
AGENT_NAME="$(cat "$STATE" 2>/dev/null || echo "${AGENT_NAME:-hello-teammate}")"

echo "=== Presentation in a Box — Where Agents become Teammates — Teardown ==="
echo ""

# --- Stop what setup started ------------------------------------------------

if [ -d "$WORKSPACE/$AGENT_NAME" ] && command -v ast >/dev/null 2>&1; then
  if (cd "$WORKSPACE/$AGENT_NAME" && ast project stop >/dev/null 2>&1); then
    echo "[OK]   Stopped local containers for $AGENT_NAME"
  else
    echo "[OK]   Nothing left running"
  fi
else
  echo "[OK]   Nothing left running"
fi

# --- Remove generated artifacts ---------------------------------------------

rm -rf "$WORKSPACE"
rm -f "$STATE"
echo "[OK]   Generated artifacts removed"

# --- Verify clean -----------------------------------------------------------

echo ""
echo "=== Teardown complete. ==="
echo ""
echo "If you deployed during the session, remove it from the platform by hand:"
echo "  ast agent list"
echo "  ast agent delete --name $AGENT_NAME"
echo "  ast blueprint archive $AGENT_NAME"
echo ""
echo "Next session:  ./scripts/setup.sh"
