#!/usr/bin/env bash
set -uo pipefail

# {{name}} — setup.
#
# Run this before every session. It must be idempotent: running it twice in a
# row leaves the same ready state, never a broken one.
#
# Contract:
#   - validate every tool and asset the content depends on, and FAIL LOUDLY if
#     one is missing, with the command that fixes it;
#   - prepare local state so nothing has to be typed at run time;
#   - open the presentation last, so the presenter is ready when it returns.

CONTENT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DECK="$CONTENT_DIR/presentation/index.html"
STATE="$CONTENT_DIR/.demo-state"      # gitignored scratch state; teardown removes it

echo "=== {{name}} — Setup ==="
echo ""

open_url() { open "$1" 2>/dev/null || xdg-open "$1" 2>/dev/null || return 1; }

need() {
  command -v "$1" >/dev/null 2>&1 && { echo "[OK]   $1 present"; return 0; }
  echo "[FAIL] $1 not found — $2"
  exit 1
}

# --- The deck ---------------------------------------------------------------

if [ ! -f "$DECK" ]; then
  echo "[FAIL] Presentation not found at $DECK — restore it from git."
  exit 1
fi
if head -c 64 "$DECK" | grep -qi '<!doctype html' && grep -q '</html>' "$DECK"; then
  echo "[OK]   Deck found and well-formed"
else
  echo "[FAIL] Deck is present but is not a complete HTML file — restore it from git."
  exit 1
fi

# --- Tooling ----------------------------------------------------------------

# need node "install from https://nodejs.org/ (18+)"
# need {{tool}} "{{how to install it}}"

# --- Prepare state ----------------------------------------------------------

# {{Build fixtures, start a local server, seed a workspace, warm a cache.
#   Anything the presenter would otherwise do by hand on stage.}}

# --- Verify the network-dependent parts -------------------------------------

# Warn, do not fail: the presenter needs to know which acts still work offline.
# if curl -sSf -m 6 -o /dev/null "{{url}}"; then
#   echo "[OK]   {{service}} reachable"
# else
#   echo "[WARN] Could not reach {{url}} — Acts {{N}}-{{M}} need it. See README section 6."
# fi

# --- Open everything --------------------------------------------------------

echo ""
echo "Opening the presentation..."
open_url "$DECK" || echo "[WARN] Open presentation/index.html manually."

cat <<EOF

=== Setup complete. Ready to present. ===

Pre-flight checklist:
  [ ] Deck open, FULLSCREEN, on slide 1
  [ ] Terminal in this folder, LARGE FONT
  [ ] {{Anything else that must be true before you start}}

When you are done:  ./scripts/teardown.sh
EOF
