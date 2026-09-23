#!/usr/bin/env bash
set -uo pipefail

# The Check Your CI Is Missing — teardown.
#
# Safe to run when setup never ran. Leaves the folder as a fresh clone would.
#
# What it deliberately does NOT touch: the seeded GitHub estate and the Context
# Graph connection. Those are one-time setup, shared across every session, and
# deleting them would cost you a nightly refresh to get back. See estate/README.md.

CONTENT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
STATE="$CONTENT_DIR/.demo-state"
APP="$CONTENT_DIR/app"

echo "=== The Check Your CI Is Missing — Teardown ==="
echo ""

# --- The artifact the agent wrote on stage ----------------------------------

if [ -f "$APP/IMPACT.md" ]; then
  rm -f "$APP/IMPACT.md"
  echo "[OK]   Removed app/IMPACT.md (the payoff — the agent writes it live next time)"
else
  echo "[OK]   No app/IMPACT.md to remove"
fi

# --- The breaking change, and whatever the agent did to fix it --------------
#
# setup.sh applies the breaking change and the agent rewrites it on stage, so
# app/ is always dirty after a session. git is the source of truth for it.

if git -C "$CONTENT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if ! git -C "$CONTENT_DIR" diff --quiet -- app 2>/dev/null; then
    git -C "$CONTENT_DIR" checkout -- app 2>/dev/null \
      && echo "[OK]   Restored app/ — the breaking change and the agent's fix are gone" \
      || echo "[WARN] Could not restore app/ — check: git status app/"
  else
    echo "[OK]   app/ already matches its committed state"
  fi
  UNTRACKED="$(git -C "$CONTENT_DIR" ls-files --others --exclude-standard -- app 2>/dev/null)"
  if [ -n "$UNTRACKED" ]; then
    echo "[WARN] Untracked files left under app/ — the agent created these. Review, then remove:"
    echo "$UNTRACKED" | sed 's/^/         /'
  fi
else
  echo "[WARN] Not a git work tree — restore app/src/serializers/order.js and"
  echo "       app/openapi.yaml by hand, or re-clone."
fi

rm -rf "$APP/node_modules"

# --- Cached graph answer, gate log, prompts ---------------------------------

if [ -d "$STATE" ]; then
  rm -rf "$STATE"
  echo "[OK]   Removed .demo-state/ (cached answer, gate log, test output, prompts)"
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
