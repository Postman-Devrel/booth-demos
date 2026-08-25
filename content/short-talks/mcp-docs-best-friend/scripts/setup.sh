#!/usr/bin/env bash
set -uo pipefail

# Make MCPs Your Documentation Best Friend — setup.
#
# Eight surfaces have to be ready before you walk on:
#   1. The deck               — Claude design (falls back to presentation/index.html)
#   2. The "before" portal    — served on localhost, opened in Chrome        (Act 0a)
#   3. The same portal in SAFARI with JavaScript disabled                    (Act 0b)
#   4. myhealthcare.dev       — the running app                              (Act 7a)
#   5. Postman desktop        — where the OpenAPI spec is managed            (Act 7b)
#   6. The Fern config repo   — generators.yml#L18                           (Act 7c)
#   7. The Fern docs site     — human page, .md, llms.txt, MCP              (Act 7d)
#   8. /tmp/myhealthcare      — an empty folder for the Claude Code session  (Act 7e)
#
# Set SKIP_OPEN=1 to run every check without opening anything.

DEMO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DECK_LOCAL="$DEMO_DIR/presentation/index.html"
SITE="$DEMO_DIR/site"
STATE="$DEMO_DIR/.demo-state"
PORT="${PORT:-4173}"
PORTAL="http://localhost:$PORT"

DECK="https://claude.ai/design/p/34e5524b-4e2d-436a-97bc-9a59609fb288?file=MCP+Docs+Best+Friend.dc.html&via=share"
APP="https://myhealthcare.dev/"
REPO="https://github.com/avdev4j/myhealthcare-fern-doc/blob/main/fern/apis/healthcare-org/generators.yml#L18"
DOCS="https://myhealthcare.docs.buildwithfern.com"
MCP="$DOCS/_mcp/server"
MCP_NAME="myhealthcare-docs"
WORKDIR="/tmp/myhealthcare"

echo "=== Make MCPs Your Documentation Best Friend — Setup ==="
echo ""

open_url()  { open "$1" 2>/dev/null || xdg-open "$1" 2>/dev/null || return 1; }
open_in()   { open -a "$1" "$2" 2>/dev/null || return 1; }   # macOS only

# --- Tooling ----------------------------------------------------------------

if ! command -v python3 >/dev/null 2>&1; then
  echo "[FAIL] python3 not found — needed to build the spec bundle and serve the portal."
  echo "       Install it (brew install python3) and re-run."
  exit 1
fi
echo "[OK]   python3 present ($(python3 --version 2>&1))"

if command -v claude >/dev/null 2>&1; then
  echo "[OK]   claude CLI present ($(claude --version 2>&1 | head -1))"
else
  echo "[WARN] claude CLI not found — Acts 7e-7f need it. https://claude.com/claude-code"
fi

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
  if ! python3 "$DEMO_DIR/scripts/build-spec-bundle.py"; then
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
# fetchable spec to site/, Act 0b stops landing — so check them out loud.

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
  echo "[WARN] index.html no longer looks client-rendered — Act 0b's payoff may not land."
fi
if grep -q '<noscript>' "$SITE/index.html"; then
  echo "[OK]   <noscript> block present — Safari will show 'JavaScript is required', not a blank page"
else
  echo "[WARN] No <noscript> block — the Safari tab will render blank white in Act 0b."
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

SHELL_BYTES="$(curl -s -m 5 "$PORTAL/" | wc -c | tr -d ' ')"
echo "[OK]   Act 0b number confirmed: the served shell is $SHELL_BYTES bytes"

# --- The live surfaces ------------------------------------------------------

echo ""
echo "--- Live surfaces (Act 7) ---"

check_url() {  # check_url <label> <url> [timeout]
  # The docs homepage is ~400 KB, so 10s is not enough on venue wifi.
  local code
  code="$(curl -s -o /dev/null -w '%{http_code}' -m "${3:-10}" -L "$2" 2>/dev/null)"
  if [ "$code" = "200" ]; then
    echo "[OK]   $1"
  elif [ "$code" = "000" ]; then
    echo "[WARN] $1 timed out after ${3:-10}s — $2"
  else
    echo "[WARN] $1 returned HTTP $code — $2"
  fi
}

check_url "myhealthcare.dev is up (Act 7a)"                "$APP"
check_url "Fern config repo reachable (Act 7c)"            "$REPO"
check_url "Fern docs site is up (Act 7d)"                  "$DOCS" 30
check_url "llms.txt is published (Act 7d)"                 "$DOCS/llms.txt"
check_url "Per-page Markdown works (Act 7d)"               "$DOCS/api-reference/healthcare-org/appointments-service/appointments/update.md"

ENDPOINTS="$(curl -s -m 10 "$DOCS/llms.txt" 2>/dev/null | sed -n '/## API Docs/,/## OpenAPI/p' | grep -c '^- ')"
[ "${ENDPOINTS:-0}" -gt 0 ] && echo "[OK]   llms.txt lists $ENDPOINTS endpoints (say '24' on stage)"

# A real JSON-RPC handshake, not just a ping — Act 7e is dead without this.
MCP_PROBE="$(curl -s -m 15 -X POST "$MCP" \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"setup-check","version":"1"}}}' 2>/dev/null)"
if echo "$MCP_PROBE" | grep -q 'fern-docs-mcp-server'; then
  echo "[OK]   MCP server responds to initialize (Acts 7e-7f)"
else
  echo "[WARN] MCP server did not handshake at $MCP"
  echo "       Acts 7e-7f will fail. Read the no-network fallback in README.md section 6."
fi

# --- Act 7e working folder --------------------------------------------------

mkdir -p "$WORKDIR"
if [ -n "$(ls -A "$WORKDIR" 2>/dev/null)" ]; then
  echo "[WARN] $WORKDIR is not empty — Act 7e's 'clean machine' line will not be true."
  echo "       Run ./scripts/teardown.sh first."
else
  echo "[OK]   $WORKDIR ready and empty (Act 7e)"
fi

# The MCP server must NOT already be registered, or `claude mcp add` errors on stage.
if command -v claude >/dev/null 2>&1; then
  if claude mcp list 2>/dev/null | grep -q "$MCP_NAME"; then
    echo "[WARN] '$MCP_NAME' is already registered — Act 7e will error."
    echo "       Run: claude mcp remove $MCP_NAME"
  else
    echo "[OK]   '$MCP_NAME' is not registered yet — Act 7e is a real first-time connect"
  fi
fi

# --- Open everything --------------------------------------------------------

if [ "${SKIP_OPEN:-0}" = "1" ]; then
  echo ""
  echo "[OK]   SKIP_OPEN=1 — checks only, nothing opened."
else
  echo ""
  echo "Opening the deck, the portal (Chrome + Safari), and Postman..."
  open_url "$DECK"           || echo "[WARN] Open the deck manually: $DECK"
  open_url "$PORTAL"         || echo "[WARN] Open $PORTAL manually."
  open_in Safari "$PORTAL"   || echo "[WARN] Open $PORTAL in Safari manually (Act 0b)."
  open -a Postman 2>/dev/null || echo "[WARN] Open the Postman desktop app manually (Act 7b)."
fi

cat <<EOF

=== Setup complete. ===

Surfaces, in the order you use them:
  Act 0a  Chrome    $PORTAL
  Act 0b  Safari    $PORTAL          <- JavaScript MUST be disabled
  Acts 1-6, 8       the deck (Claude design; fallback presentation/index.html)
  Act 7a  Chrome    $APP
  Act 7b  Postman   healthcare-org -> appointments definition
  Act 7c  Chrome    generators.yml#L18
  Act 7d  Chrome    $DOCS
  Act 7e  Terminal  cd $WORKDIR

Before you walk on:
  [ ] SAFARI: Develop -> Disable JavaScript is ON. Reload $PORTAL.
      You should see "JavaScript is required" and nothing else.
  [ ] Deck fullscreen on slide 1. Signed in to claude.ai.
  [ ] Postman desktop signed in, on the healthcare-org spec.
  [ ] Terminal in $WORKDIR, LARGE FONT, Claude Code context CLEAN.
  [ ] You have run the Act 7f prompts once today (first searchDocs call can take 40s).
  [ ] The four numbers: ${SHELL_BYTES} bytes . 404 . 900 KB -> 9 KB . 24 endpoints

Act 7e command, ready to paste:
  claude mcp add --transport http $MCP_NAME $MCP

When you are done:  ./scripts/teardown.sh
EOF
