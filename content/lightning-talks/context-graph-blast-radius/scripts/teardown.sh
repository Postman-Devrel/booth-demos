#!/usr/bin/env bash
set -uo pipefail

# The Blast Radius You Can't Grep — teardown.
#
# Safe to run when setup never ran. Leaves the folder as a fresh clone would.
#
# What it deliberately does NOT touch: the seeded GitHub estate and the Context
# Graph connection. Those are one-time setup, shared across every session, and
# deleting them would cost you a nightly refresh to get back. See estate/README.md.

CONTENT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
STATE="$CONTENT_DIR/.demo-state"
APP="$CONTENT_DIR/app"

echo "=== The Blast Radius You Can't Grep — Teardown ==="
echo ""

# --- The artifact the agent wrote on stage ----------------------------------

if [ -f "$APP/IMPACT.md" ]; then
  rm -f "$APP/IMPACT.md"
  echo "[OK]   Removed app/IMPACT.md (the payoff — it must be created live next time)"
else
  echo "[OK]   No app/IMPACT.md to remove"
fi

# --- Anything the agent edited in the provider repo -------------------------

if git -C "$CONTENT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if ! git -C "$CONTENT_DIR" diff --quiet -- app 2>/dev/null; then
    git -C "$CONTENT_DIR" checkout -- app 2>/dev/null \
      && echo "[OK]   Restored app/ — the agent had edited the provider repo" \
      || echo "[WARN] Could not restore app/ — check: git status app/"
  else
    echo "[OK]   app/ is unmodified"
  fi
else
  echo "[WARN] Not a git work tree — check app/ by hand if the agent edited code"
fi

rm -rf "$APP/node_modules"

# --- Cached graph answer and prompts ----------------------------------------

if [ -d "$STATE" ]; then
  rm -rf "$STATE"
  echo "[OK]   Removed .demo-state/ (cached graph answer, prompts)"
else
  echo "[OK]   No .demo-state/ to remove"
fi

cat <<EOF

=== Teardown complete. ===

Left standing on purpose:
  - the seeded GitHub estate and its Context Graph connection (estate/README.md)
  - your \`postman login\` session

Next session:  ./scripts/setup.sh
EOF
