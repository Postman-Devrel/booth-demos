#!/usr/bin/env bash
set -uo pipefail

# Make MCPs Your Documentation Best Friend — setup.
#
# One talk, two lengths, ONE demo: the pipeline is BUILT on stage from a single
# OpenAPI file. The 25-minute cut wraps that build in the cold open and the
# deck; the 10-minute booth cut drops the cold open and shows three slides
# (README section 9). This script serves both — the booth cut just skips the
# portal tabs.
#
# So setup has two jobs, and they pull in opposite directions:
#
#   The cold open (Act 0) — state that must EXIST
#     1. The "before" portal, served on localhost, opened in Chrome     (Act 0a)
#     2. The same portal in SAFARI with JavaScript disabled             (Act 0b)
#     3. Its anti-agent properties, asserted — no llms.txt, no fetchable
#        spec, an empty root div. These ARE the demo.
#        (Skipped in practice by the booth cut, which has no Act 0.)
#
#   The build (Act 7) — state that must NOT exist yet
#     4. A folder holding exactly one file: the OpenAPI spec            (Act 7a)
#     5. A Fern CLI that is logged in, so the publish cannot stop to
#        open a browser mid-demo                                       (Act 7d)
#     6. An EMPTY folder for the agent, so the payoff cannot be
#        answered by reading the spec off the disk                      (Act 7f)
#     7. A docs subdomain whose search index is already WARM            (Act 7f)
#
# Conditions 6 and 7 decide whether this demo lands, and both were hit on real
# runs. Read the WARM/COLD verdict before you walk on.
#
#   SKIP_OPEN=1     run every check, open nothing
#   PORT            portal port            (default 4173)
#   FERN_ORG        the Fern ORGANIZATION  (default postman-devrel)
#   FERN_HANDLE     docs SUBDOMAIN label   (default booth-demo)
#   WORKDIR         Act 7 build folder     (default /tmp/appointments-docs)
#   AGENTDIR        Act 7 agent folder, EMPTY (default /tmp/appointments-agent)
#
# Both cuts use these same defaults: one warm subdomain, one set of folders.
# Override them if two people present from the same machine.
#
# FERN_ORG AND FERN_HANDLE ARE NOT THE SAME THING. The organization is the
# account-level tenant; it goes in fern.config.json and you do not get to invent
# it. The subdomain is per-site; it goes in docs.yml. `postman-devrel` also
# publishes myhealthcare.docs.buildwithfern.com — the REAL MyHealthcare
# documentation, and this cut's warm fallback — which is both the proof they are
# independent and the reason FERN_HANDLE must never be `myhealthcare`.

DEMO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DECK_LOCAL="$DEMO_DIR/presentation/index.html"
SITE="$DEMO_DIR/site"
STATE="$DEMO_DIR/.demo-state"
SRC_SPEC="$DEMO_DIR/openapi/appointments.openapi.yaml"

PORT="${PORT:-4173}"
PORTAL="http://localhost:$PORT"

FERN_ORG="${FERN_ORG:-postman-devrel}"
FERN_HANDLE="${FERN_HANDLE:-booth-demo}"
WORKDIR="${WORKDIR:-/tmp/appointments-docs}"
AGENTDIR="${AGENTDIR:-/tmp/appointments-agent}"

SPEC_NAME="appointments.yaml"     # what it is called on disk, on stage
MCP_NAME="appointments-docs"      # a SUGGESTION — the Act 7 prompt names no server

DECK="https://claude.ai/design/p/34e5524b-4e2d-436a-97bc-9a59609fb288?file=MCP+Docs+Best+Friend.dc.html&via=share"
DOCS="https://$FERN_HANDLE.docs.buildwithfern.com"
MCP="$DOCS/_mcp/server"
FALLBACK="https://myhealthcare.docs.buildwithfern.com"

FAILED=0
note_fail() { echo "[FAIL] $1"; FAILED=1; }

echo "=== Make MCPs Your Documentation Best Friend (25 min) — Setup ==="
echo ""

open_url()  { open "$1" 2>/dev/null || xdg-open "$1" 2>/dev/null || return 1; }
open_in()   { open -a "$1" "$2" 2>/dev/null || return 1; }   # macOS only

# --- Tooling ----------------------------------------------------------------

if command -v python3 >/dev/null 2>&1; then
  echo "[OK]   python3 present ($(python3 --version 2>&1))"
else
  note_fail "python3 not found — needed to build the spec bundle and serve the portal."
fi

for bin in node npm; do
  if command -v "$bin" >/dev/null 2>&1; then
    echo "[OK]   $bin present"
  else
    note_fail "$bin not found — the Fern CLI runs on it."
  fi
done

if command -v fern >/dev/null 2>&1; then
  echo "[OK]   fern CLI present ($(fern --version 2>&1 | head -1))"
else
  note_fail "fern CLI not found. Install it: npm install -g fern-api"
fi

if command -v claude >/dev/null 2>&1; then
  echo "[OK]   claude CLI present ($(claude --version 2>&1 | head -1))"
else
  note_fail "claude CLI not found — the last demo step needs it. https://claude.com/claude-code"
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

# --- Fern login -------------------------------------------------------------
# `fern generate --docs` opens a browser when it is not logged in. Fine in a
# tutorial, fatal on stage — so this is a hard failure.

if [ -s "$HOME/.fern/token" ] || [ -n "${FERN_TOKEN:-}" ]; then
  echo "[OK]   Fern CLI is logged in (token present)"
else
  note_fail "Fern CLI is not logged in — run 'fern login' (choose Continue with Postman) BEFORE the talk."
fi

# --- Does the organization actually resolve? ---------------------------------
# `fern org get` answers "No org-level CLI config set for X" when the account
# belongs to X (a success — there is just no stored config), and 403 when it
# does not. `fern generate --docs` only tells you much later, as a 500
# "Failed to resolve organization", after you have said "watch this" out loud.

if command -v fern >/dev/null 2>&1; then
  ORG_OUT="$( cd "$(mktemp -d)" \
    && printf '{\n    "organization": "%s",\n    "version": "5.114.1"\n}\n' "$FERN_ORG" > fern.config.json \
    && mkdir -p fern && mv fern.config.json fern/ \
    && fern org get 2>&1 | head -1 )"
  if echo "$ORG_OUT" | grep -q '403'; then
    note_fail "Your Fern account has NO access to the organization '$FERN_ORG'."
    echo "       fern org get says: $ORG_OUT"
    echo "       Find the real one at https://dashboard.buildwithfern.com and set FERN_ORG."
    echo "       It does NOT have to match the docs subdomain."
  else
    echo "[OK]   Organization '$FERN_ORG' resolves for this account"
  fi
fi

# --- Handle sanity ----------------------------------------------------------
# `fern generate --docs` publishes wherever docs.yml points, and
# myhealthcare.docs.buildwithfern.com is the REAL three-service documentation
# site — this talk's warm fallback. Reading it is safe. Publishing to it is not.

if [ "$FERN_HANDLE" = "myhealthcare" ]; then
  note_fail "FERN_HANDLE=myhealthcare would overwrite the REAL MyHealthcare documentation."
  echo "       That site is production AND this talk's fallback. Use the throwaway name:"
  echo "       FERN_HANDLE=booth-demo ./scripts/setup.sh"
fi

# --- The source spec --------------------------------------------------------
# One file is published on stage: appointments. The portal under site/ still
# renders all three services, which is what the Act 0 -> Act 7 bridge sentence
# is for ("we're going to fix one of these three tonight").

echo ""
echo "--- The spec (Act 7a) ---"

if [ ! -f "$SRC_SPEC" ]; then
  note_fail "Missing $SRC_SPEC"
else
  OPS="$(grep -c 'operationId' "$SRC_SPEC")"
  echo "[OK]   appointments.openapi.yaml found ($OPS operations)"

  # The payoff fact. Act 7a points at it in the file, Act 7f gets it back out
  # of the MCP server. If someone ever "cleans up" this description the demo
  # still runs and stops proving anything — so check it explicitly.
  if grep -q 'a plain update emits' "$SRC_SPEC"; then
    echo "[OK]   The payoff warning is in the spec ('a plain update emits appointment.cancelled')"
  else
    note_fail "The 'a plain update emits' warning is gone from the spec — Act 7 has no payoff."
  fi
fi

# --- Build the portal's spec bundle ----------------------------------------
# The three OpenAPI files under openapi/ are compiled into
# site/assets/spec-bundle.js. This is the ONLY route the spec takes to the
# browser — the portal deliberately publishes no .yaml or .json at a URL.

echo ""
echo "--- The 'before' portal (Act 0) ---"

if python3 -c "import yaml" >/dev/null 2>&1; then
  if ! python3 "$DEMO_DIR/scripts/build-spec-bundle.py"; then
    note_fail "Spec bundle build failed — see the output above."
  fi
else
  [ -f "$SITE/assets/spec-bundle.js" ] \
    && echo "[OK]   Using the checked-in spec bundle" \
    || note_fail "No spec bundle and no PyYAML to build one."
fi

# --- Confirm the portal's anti-agent properties -----------------------------
# These are the demo. If a well-meaning edit ever adds an llms.txt or a
# fetchable spec to site/, Act 0b stops landing — so check them out loud.

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
  echo "[OK]   <noscript> block present — Safari shows 'JavaScript is required', not a blank page"
else
  echo "[WARN] No <noscript> block — the Safari tab will render blank white in Act 0b."
fi

# --- Serve the portal -------------------------------------------------------

if lsof -ti tcp:"$PORT" >/dev/null 2>&1; then
  echo "[WARN] Port $PORT is already in use — reusing whatever is there."
  echo "       If that is not this portal, stop it (./scripts/teardown.sh) or set PORT=4180."
else
  ( cd "$SITE" && nohup python3 -m http.server "$PORT" >/tmp/mcp-docs-portal.log 2>&1 & echo $! > "$STATE" )
  sleep 1
  if curl -sSf -m 3 -o /dev/null "$PORTAL/"; then
    echo "[OK]   Portal serving at $PORTAL (pid $(cat "$STATE"))"
  else
    note_fail "Portal did not come up on $PORT — see /tmp/mcp-docs-portal.log"
  fi
fi

SHELL_BYTES="$(curl -s -m 5 "$PORTAL/" | wc -c | tr -d ' ')"
echo "[OK]   Act 0b number confirmed: the served shell is $SHELL_BYTES bytes"

# --- The build folders ------------------------------------------------------
# "Empty folder, one file" is said out loud, so it has to be literally true:
# one file, no .git, no fern/. Leftovers are removed by teardown.sh, not here.

echo ""
echo "--- The build folders (Act 7) ---"

if [ -d "$WORKDIR" ] && [ -n "$(ls -A "$WORKDIR" 2>/dev/null)" ]; then
  note_fail "$WORKDIR already has content — run ./scripts/teardown.sh first."
  echo "       Leftovers: $(ls -A "$WORKDIR" | tr '\n' ' ')"
else
  rm -rf "$WORKDIR"
  mkdir -p "$WORKDIR"
  cp "$SRC_SPEC" "$WORKDIR/$SPEC_NAME"
  echo "[OK]   $WORKDIR created with exactly one file: $SPEC_NAME"
  echo "[OK]   No fern/ and no .git — the scaffold step is a genuine first run"
fi

# The agent's folder must be EMPTY. Observed live on 2026-09-07 in WORKDIR: with
# the spec visible, a slow index made the agent answer "the docs site isn't
# indexed yet, but the local OpenAPI spec has the answer — let me read that."
# That produced the RIGHT answer from the WRONG source, which is the worst
# outcome available because it looks like the demo worked. The claim being
# demonstrated is that the fact travelled spec -> site -> MCP; an agent opening
# the file next to it demonstrates none of that.

rm -rf "$AGENTDIR"
mkdir -p "$AGENTDIR"
if [ -z "$(ls -A "$AGENTDIR" 2>/dev/null)" ]; then
  echo "[OK]   $AGENTDIR is empty — the agent can ONLY answer from the MCP server"
else
  note_fail "$AGENTDIR is not empty — the agent will read local files instead of calling searchDocs."
fi

# --- Preflight: does the scaffold + check sequence still pass? --------------
# `fern init` scaffolds a TypeScript SDK generator group, and the SDK validator
# rejects this spec's request examples: the schemas are open
# (additionalProperties, because the service stores a free-form JSONB `data`
# document) and the examples use keys that are therefore not declared. Five
# errors, every time. Docs do not care, but `fern check` does, and red text on
# stage is a bad look. Act 7c rewrites generators.yml down to `api.specs`,
# which removes the SDK group, and the check then passes.
#
# This runs that exact sequence in a throwaway folder so a new CLI version or an
# edited spec cannot break the demo silently. It also proves the demo needs no
# git: the throwaway folder is not a repository.

echo ""
echo "--- Preflight: fern init + fern check (Acts 7b-7c) ---"

if command -v fern >/dev/null 2>&1 && [ -f "$SRC_SPEC" ]; then
  PRE="$(mktemp -d)"
  cp "$SRC_SPEC" "$PRE/$SPEC_NAME"
  if ( cd "$PRE" && fern init --openapi "./$SPEC_NAME" --organization "$FERN_ORG" >/dev/null 2>&1 ); then
    if [ -f "$PRE/fern/generators.yml" ] && [ ! -d "$PRE/fern/apis" ]; then
      echo "[OK]   fern init scaffolds the single-API layout (generators.yml, no apis/)"
    else
      note_fail "fern init did not produce the single-API layout — docs.yml would need an api-name."
    fi

    printf 'api:\n  specs:\n    - openapi: ../%s\n' "$SPEC_NAME" > "$PRE/fern/generators.yml"
    printf 'instances:\n  - url: %s.docs.buildwithfern.com\ntitle: Appointments Service | Documentation\nnavigation:\n  - api: API Reference\n' \
      "$FERN_HANDLE" > "$PRE/fern/docs.yml"

    # `fern check` prints "All checks passed" only when it has nothing at all to
    # say. With warnings it prints "Found 0 errors and N warnings" instead —
    # still a pass. Gate on zero ERRORS, or a healthy project reports as broken.
    CHECK="$( cd "$PRE" && fern check 2>&1 )"
    if echo "$CHECK" | grep -qE 'All checks passed|Found 0 errors'; then
      echo "[OK]   fern check passes on the trimmed project — Act 7c lands green"
      echo "[OK]   ...and it passed in a folder that is not a git repo, which is why"
      echo "       this demo has no GitHub step"
    else
      note_fail "fern check FAILS even after the Act 7c trim. Do not present until this is understood:"
      echo "$CHECK" | tail -12 | sed 's/^/       /'
    fi
  else
    note_fail "fern init failed in a clean folder — Act 7b is broken. Run it by hand to see why."
  fi
  rm -rf "$PRE"
else
  echo "[WARN] Skipped — needs the fern CLI and the spec."
fi

# --- Is the docs index warm? ------------------------------------------------
# THE decision this script exists to make. A Fern subdomain answers whether or
# not anything was ever published there: an unpublished one returns an llms.txt
# with the header and no page links. Page links => a real site => a search index
# that already exists => the payoff prompt is fast.

echo ""
echo "--- The docs subdomain: $DOCS ---"

# Retry: a single timed-out curl reports a live site as COLD, which sends the
# presenter off to do a rehearsal they do not need — or teaches them to distrust
# this verdict, which is worse.
count_pages() {  # count_pages <base-url>
  local n
  for _ in 1 2 3; do
    n="$(curl -s -m 25 "$1/llms.txt" 2>/dev/null | grep -c '](' )"
    [ "${n:-0}" -gt 0 ] && { echo "$n"; return; }
    sleep 2
  done
  echo 0
}

PAGES="$(count_pages "$DOCS")"
if [ "${PAGES:-0}" -gt 0 ]; then
  WARM=1
  echo "[OK]   WARM — $DOCS already lists $PAGES pages."
  echo "       On stage 'fern generate --docs' REPUBLISHES over an existing index. This is"
  echo "       the safe path: the site rebuilds and searchDocs answers in 5-15s (measured)."
else
  WARM=0
  echo "[WARN] COLD — nothing has ever been published to $DOCS."
  echo ""
  echo "       Act 7f is the payoff of this talk and it is at real risk right now. Fern"
  echo "       builds the search index AFTER the first publish, and it takes MINUTES, not"
  echo "       seconds. Measured 2026-09-07: still unavailable immediately after"
  echo "       'fern generate --docs' finished, answering normally ~5 minutes later."
  echo ""
  echo "       A 25-minute slot has ~4.5 minutes of Q&A and no other slack, so you would"
  echo "       be spending the questions on recovery. Do this first, it takes 5 minutes:"
  echo "         1. Run the demo once, start to finish, alone."
  echo "         2. ./scripts/teardown.sh"
  echo "         3. ./scripts/setup.sh   <- this line should then say WARM"
fi

if [ "$WARM" = "1" ]; then
  MCP_PROBE="$(curl -s -m 15 -X POST "$MCP" \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json, text/event-stream' \
    -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"setup-check","version":"1"}}}' 2>/dev/null)"
  if echo "$MCP_PROBE" | grep -q 'fern-docs-mcp-server'; then
    echo "[OK]   Its MCP server handshakes (Act 7f)"
  else
    echo "[WARN] No MCP handshake at $MCP yet — it appears after the publish in Act 7d."
  fi
fi

# The permanently-warm three-service site. Same spec, same warning, so it is a
# legitimate stand-in if the fresh site's index will not cooperate — and it is
# the honest place to point when someone asks about the other two services.
FB_PAGES="$(count_pages "$FALLBACK")"
if [ "${FB_PAGES:-0}" -gt 0 ]; then
  echo "[OK]   Fallback site is up ($FALLBACK, $FB_PAGES pages) — use it if Act 7f stalls"
else
  echo "[WARN] The fallback site is not answering either — check the network."
fi

# --- Claude Code state ------------------------------------------------------
# Detect by URL, never by name. There are at least THREE names in circulation
# for this one server and the presenter picks one by accident:
#
#   appointments-docs                          <- what this crib sheet passes
#   booth-demo-docs-buildwithfern-com          <- what the docs site's UI snippet uses
#   fern_mcp_booth-demo-docs-buildwithfern-com <- what /_mcp/server's usage field suggests
#
# It also has to look in the PARENT directories: `claude mcp add --scope local`
# is inherited by subdirectories, so a registration made in /private/tmp shows
# up in every /tmp/* folder — AGENTDIR included — which quietly makes "a genuine
# first-time connect" false.

if command -v claude >/dev/null 2>&1; then
  echo ""
  FOUND="$( cd "$AGENTDIR" 2>/dev/null && claude mcp list 2>/dev/null | grep -F "$MCP" )"
  if [ -n "$FOUND" ]; then
    FOUND_NAME="$(echo "$FOUND" | head -1 | cut -d: -f1 | tr -d ' ')"
    echo "[WARN] This docs MCP server is ALREADY registered and visible from $AGENTDIR,"
    echo "       under the name '$FOUND_NAME'."
    echo "       Act 7f will not be a first-time connect, and 'claude mcp add' may error."
    echo "       ./scripts/teardown.sh removes it (it searches by URL, including parents)."
  else
    echo "[OK]   No registration for $MCP is visible from $AGENTDIR"
    echo "       — Act 7f is a genuine first-time connect"
  fi
  echo "[OK]   The Act 7f prompt names no server, so whichever name you register works"
fi

# --- Open what you present from ---------------------------------------------
# Three surfaces, and no more. The docs site does not exist until Act 7d
# publishes it, so opening a tab for it now shows the room a 404 — and extra
# tabs are how you lose the one you need.

if [ "${SKIP_OPEN:-0}" = "1" ]; then
  echo ""
  echo "[OK]   SKIP_OPEN=1 — checks only, nothing opened."
else
  echo ""
  echo "Opening the deck, and the portal in Chrome and Safari..."
  open_url "$DECK"           || echo "[WARN] Open the deck manually: $DECK"
  open_url "$PORTAL"         || echo "[WARN] Open $PORTAL manually (Act 0a)."
  open_in Safari "$PORTAL"   || echo "[WARN] Open $PORTAL in Safari manually (Act 0b)."
fi

# --- The stage crib sheet ---------------------------------------------------

cat <<EOF

=================================================================
 Everything below is paste-ready. You should not need the README.
=================================================================

Surfaces, in the order you use them:
  Act 0a   Chrome    $PORTAL
  Act 0b   Safari    $PORTAL      <- JavaScript MUST be disabled
  Acts 1-6 Deck      Claude design (fallback: $DECK_LOCAL)
  Act 7    Terminal  $WORKDIR, then $AGENTDIR
  Act 8    Deck      slides 11-12

--- Act 0b: the cold open number ----------------------------------
  curl -s $PORTAL/ | wc -c        <- expect $SHELL_BYTES

--- Act 7a: what we start with -----------------------------------
  cd $WORKDIR
  ls
  grep -n -A4 'a plain update emits' $SPEC_NAME

--- Act 7b: scaffold ---------------------------------------------
  fern init --openapi ./$SPEC_NAME --organization $FERN_ORG
  ls fern            <- two files: fern.config.json + generators.yml, NO apis/
  cat fern/generators.yml

  DO NOT run 'fern check' yet. fern init scaffolds a TypeScript SDK generator
  and the SDK validator throws 5 errors on this spec's request examples. Act
  7c removes that generator and THEN checks green.

--- Act 7c: two small YAML files ---------------------------------
  cat > fern/generators.yml <<'YAML'
api:
  specs:
    - openapi: ../$SPEC_NAME
YAML

  cat > fern/docs.yml <<'YAML'
instances:
  - url: $FERN_HANDLE.docs.buildwithfern.com
title: Appointments Service | Documentation
navigation:
  - api: API Reference
YAML

  fern check       <- "All checks passed", or "Found 0 errors" if it has
                      warnings. Zero ERRORS is the pass.

  (Single API => NO api-name under '- api:'. Adding one fails the publish.)

--- Act 7d: publish ----------------------------------------------
  fern generate --docs          <- answer Yes to the production warning

--- Act 7e: the four outputs, in the browser ---------------------
  1. $DOCS
     -> API Reference -> Appointments -> Update an appointment
  2. add .md to that URL          <- same page, no chrome, ~90x smaller
  3. $DOCS/llms.txt
     -> read the "Instructions for AI Agents" header out loud
  4. $MCP

--- Act 7f: connect it to an agent and ask -----------------------
  MOVE FOLDERS FIRST. Do not run the agent in $WORKDIR — the spec is
  in there and the agent will read it instead of calling the MCP server.

  cd $AGENTDIR
  ls -la           <- empty. Say it out loud: "nothing here but the MCP server"

  claude mcp add --transport http $MCP_NAME $MCP
  claude
  /mcp             <- expect ONE server connected, one tool 'searchDocs'

  Then paste this prompt verbatim. It names NO server on purpose — one
  server ends up with three names and naming it is how you get "no server
  named appointments-docs is connected" in front of the room.

  Using the connected docs MCP server: I want to change only the \`reason\` field on an existing
  appointment. Which endpoint do I call, and does that have any side effect
  on the appointment's slot? Cite the page you got it from.

  Claude Code ASKS PERMISSION for mcp__<server-name>__searchDocs on the
  first call. Approve it live — the prompt proves a tool call is going out.

  Budget ~30 SECONDS (33s measured) for the whole answer, not the ~13s the
  search takes. Narrate over it or the room goes quiet.

  Expected: it names PATCH /api/appointments/{record_id}, notes the shallow
  merge, then warns that the update publishes \`appointment.cancelled\` so
  appointment-slots-service reopens the slot while the appointment is still
  active — cited to the 'Update an appointment' page.

--- Before you walk on --------------------------------------------
  [ ] SAFARI: Develop -> Disable JavaScript is ON. Reload $PORTAL.
      You should see "JavaScript is required" and nothing else.
  [ ] Deck fullscreen on slide 1. Signed in to claude.ai.
  [ ] Terminal font ~18pt, cwd $WORKDIR, 'ls' shows one file
  [ ] You will cd to $AGENTDIR before Act 7f — the agent must NOT see the spec
  [ ] Claude Code context CLEAN — a warm session answers without calling the
      tool, which destroys the payoff
  [ ] The subdomain verdict above says WARM
  [ ] The numbers: $SHELL_BYTES bytes . 404 . 780 KB -> 9 KB (~90x) . 10 operations
  [ ] The bridge sentence is ready: the portal shows three services, tonight
      we publish one

When you are done:  ./scripts/teardown.sh
EOF

if [ "$FAILED" -ne 0 ]; then
  echo ""
  echo "=== Setup finished with FAILURES above. Fix them before presenting. ==="
  exit 1
fi

echo ""
echo "=== Setup complete. ==="
