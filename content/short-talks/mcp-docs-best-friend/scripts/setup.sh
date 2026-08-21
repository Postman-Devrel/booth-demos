#!/usr/bin/env bash
set -uo pipefail

# Make MCPs Your Documentation Best Friend — setup.
#
# Two things have to be ready before the first attendee:
#   1. The deck (presentation/index.html).
#   2. The "before" portal — a human-first API docs site served on localhost,
#      so you can curl it, point an agent at it, and watch the agent fail.
#
# The Fern site (the "after") is live on the internet and needs no setup.

DEMO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DECK="$DEMO_DIR/presentation/index.html"
SITE="$DEMO_DIR/site"
STATE="$DEMO_DIR/.demo-state"
PORT="${PORT:-4173}"
PORTAL="http://localhost:$PORT"
FERN="https://devreliance-health.docs.buildwithfern.com"

echo "=== Make MCPs Your Documentation Best Friend — Setup ==="
echo ""

open_url() { open "$1" 2>/dev/null || xdg-open "$1" 2>/dev/null || return 1; }

# --- The deck ---------------------------------------------------------------

if [ ! -f "$DECK" ]; then
  echo "[FAIL] Presentation not found at $DECK — restore it from git."
  exit 1
fi
if head -c 64 "$DECK" | grep -qi '<!doctype html' && grep -q '</html>' "$DECK"; then
  echo "[OK]   Deck found and well-formed (12 slides, presentation/index.html)"
else
  echo "[FAIL] Deck is present but is not a complete HTML file — restore it from git."
  exit 1
fi

# --- Tooling ----------------------------------------------------------------

if ! command -v python3 >/dev/null 2>&1; then
  echo "[FAIL] python3 not found — needed to build the spec bundle and serve the portal."
  echo "       Install it (brew install python3) and re-run."
  exit 1
fi
echo "[OK]   python3 present ($(python3 --version 2>&1))"

if ! python3 -c "import yaml" >/dev/null 2>&1; then
  echo "[WARN] PyYAML is missing — installing it so the spec bundle can be rebuilt..."
  if python3 -m pip install --quiet pyyaml >/dev/null 2>&1; then
    echo "[OK]   PyYAML installed"
  else
    echo "[WARN] Could not install PyYAML. The checked-in spec bundle will be used as-is,"
    echo "       which is fine unless you edited a file under openapi/."
  fi
fi

# --- Build the portal's spec bundle ----------------------------------------
# The three OpenAPI files under openapi/ are compiled into
# site/assets/spec-bundle.js. This is the ONLY route the spec takes to the
# browser — the portal deliberately publishes no .yaml or .json at a URL.

if python3 -c "import yaml" >/dev/null 2>&1; then
  if python3 "$DEMO_DIR/scripts/build-spec-bundle.py"; then
    :
  else
    echo "[FAIL] Spec bundle build failed — see the output above."
    exit 1
  fi
else
  [ -f "$SITE/assets/spec-bundle.js" ] \
    && echo "[OK]   Using the checked-in spec bundle" \
    || { echo "[FAIL] No spec bundle and no PyYAML to build one."; exit 1; }
fi

# --- Confirm the portal's anti-agent properties -----------------------------
# These are the demo. If a well-meaning edit ever adds an llms.txt or a
# fetchable spec to site/, Act 2 stops landing — so check them out loud.

echo ""
echo "--- The 'before' portal: confirming it is human-only ---"
for f in llms.txt openapi.yaml openapi.json sitemap.xml; do
  if [ -e "$SITE/$f" ]; then
    echo "[WARN] site/$f exists — the portal is supposed to publish NO machine surface."
  else
    echo "[OK]   No site/$f (agents get a 404 — this is the point)"
  fi
done
if grep -q '<div id="root"></div>' "$SITE/index.html"; then
  echo "[OK]   index.html ships an empty root div (all content is client-rendered)"
else
  echo "[WARN] index.html no longer looks client-rendered — Act 2's 'view source' beat may not land."
fi

# --- Serve the portal -------------------------------------------------------

if lsof -ti tcp:"$PORT" >/dev/null 2>&1; then
  echo ""
  echo "[WARN] Port $PORT is already in use — reusing whatever is there."
  echo "       If that is not this portal, stop it (./scripts/teardown.sh) or set PORT=4180."
else
  ( cd "$SITE" && nohup python3 -m http.server "$PORT" >/tmp/mcp-docs-portal.log 2>&1 & echo $! > "$STATE" )
  sleep 1
  if curl -sSf -m 3 -o /dev/null "$PORTAL/"; then
    echo ""
    echo "[OK]   Portal serving at $PORTAL (pid $(cat "$STATE"))"
  else
    echo ""
    echo "[FAIL] Portal did not come up on $PORT — see /tmp/mcp-docs-portal.log"
    exit 1
  fi
fi

# --- The 'after' site -------------------------------------------------------

if curl -sSf -m 6 -o /dev/null "$FERN/llms.txt" 2>/dev/null; then
  echo "[OK]   Fern site reachable — the live 'after' half of the demo will work"
else
  echo "[WARN] Could not reach $FERN"
  echo "       No network? Acts 4-6 need it. Read the fallback numbers in README.md section 6."
fi

# --- Open everything --------------------------------------------------------

echo ""
echo "Opening the deck and the portal..."
open_url "$DECK"   || echo "[WARN] Open presentation/index.html manually."
open_url "$PORTAL" || echo "[WARN] Open $PORTAL manually."

cat <<EOF

=== Setup complete. Ready to present. ===

The three surfaces you will switch between:
  1. Deck      presentation/index.html   (arrow keys or click; 'f' for fullscreen)
  2. Before    $PORTAL
  3. After     $FERN

Pre-demo checklist:
  [ ] Deck open, FULLSCREEN, on slide 1
  [ ] Portal open in a second tab and scrolled to the API reference
  [ ] Fern site open in a third tab
  [ ] A terminal open, LARGE FONT, in this folder — Act 7b runs curl in it
  [ ] An agent session open with a CLEAN CONTEXT — a warm one spoils Act 7c
  [ ] You have run the Act 7b curls once already so nothing is cold on stage
  [ ] Browser zoom set so text reads from 6 feet (Cmd+= / Cmd+-)
  [ ] You know the four numbers: 1,402 bytes · 404 · 937 KB -> 9.9 KB · 24 endpoints

When you are done:  ./scripts/teardown.sh
EOF
