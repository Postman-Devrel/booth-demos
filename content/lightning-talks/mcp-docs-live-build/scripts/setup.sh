#!/usr/bin/env bash
set -uo pipefail

# Make MCPs Your Documentation Best Friend — Live Build. Setup.
#
# This demo builds the whole pipeline on stage, so setup does NOT build any of
# it. What it does is guarantee the starting conditions, because every one
# of them is a line in the talk track:
#
#   1. A folder in /tmp holding exactly one file: the OpenAPI spec        (Act 2)
#   2. A Fern CLI that is logged in, so `fern generate --docs` cannot     (Act 3c)
#      stop to open a browser mid-demo
#   3. An EMPTY folder for the agent, so Act 3e cannot be answered      (Act 3e)
#      by reading the spec off the disk instead of calling the MCP server
#   4. A docs subdomain whose search index is already WARM, so the      (Act 3e)
#      searchDocs call answers in 5-15s instead of not at all
#
# Conditions 3 and 4 are the ones that decide whether this demo lands, and both
# were hit on the first live run. Read the WARM/COLD verdict before you walk on,
# and never run the agent anywhere but AGENTDIR.
#
# There is no GitHub in this demo. `fern init`, `fern check` and
# `fern generate --docs` need no repository, so the folder stays a plain folder.
#
#   SKIP_OPEN=1     run every check, open nothing
#   FERN_ORG        the Fern ORGANIZATION  (default postman-devrel)
#   FERN_HANDLE     docs SUBDOMAIN label   (default booth-demo)
#   WORKDIR         Acts 3a-3c folder     (default /tmp/appointments-docs)
#   AGENTDIR        Act 3e folder, EMPTY  (default /tmp/appointments-agent)
#
# FERN_ORG and FERN_HANDLE ARE NOT THE SAME THING, and conflating them is how
# this demo broke once already. The organization is the account-level tenant you
# belong to; it goes in fern.config.json and you do not get to invent it. The
# subdomain is per-site; it goes in docs.yml and one org can publish many.
# `postman-devrel` already publishes myhealthcare.docs.buildwithfern.com — the
# real MyHealthcare documentation — which is the proof they are independent, and
# the reason FERN_HANDLE must never be `myhealthcare`.
#
# Passing a made-up name to `fern init --organization` does not fail — Fern
# provisions that organization on first publish. Deleting it afterwards to "reset"
# leaves the account with no org, and every later publish dies with
# "Failed to resolve organization" (HTTP 500). Never delete the org. There is
# nothing to reset: republishing over the same subdomain IS the reset.

DEMO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DECK="$DEMO_DIR/presentation/index.html"
SRC_SPEC="$DEMO_DIR/openapi/appointments.openapi.yaml"

FERN_ORG="${FERN_ORG:-postman-devrel}"
FERN_HANDLE="${FERN_HANDLE:-booth-demo}"
WORKDIR="${WORKDIR:-/tmp/appointments-docs}"

SPEC_NAME="appointments.yaml"          # what it is called on disk, on stage
# A SUGGESTION, not a contract. It is only what the crib sheet passes to
# `claude mcp add`; nothing downstream depends on it, and the Act 3e prompt names
# no server precisely so that it cannot. Detection everywhere below matches on
# $MCP (the URL) instead — see the note above the registration check.
MCP_NAME="appointments-docs"

# Act 3e runs the agent HERE, not in WORKDIR. This is not tidiness, it is the
# difference between the demo proving something and proving nothing.
#
# WORKDIR contains appointments.yaml. Claude Code reads the files in its working
# directory, so when the MCP server is slow or not yet indexed it takes the
# cheaper route: "the docs site isn't indexed yet, but the local OpenAPI spec has
# the answer — let me read that." Observed live on 2026-09-07, on a first run
# where the index genuinely was still building.
#
# That is the worst possible outcome on stage, because it produces the RIGHT
# answer from the WRONG source and therefore LOOKS like it worked. The whole
# claim of this demo is that the fact travelled spec -> site -> MCP; an agent
# reading the spec off the disk next to it demonstrates none of that.
#
# The escape hatch is the bug, not the index. AGENTDIR holds nothing, so a slow
# or cold index makes the agent wait, retry, or admit it cannot answer — all of
# which are honest and recoverable in front of a booth. Keeping the site warm
# (see the WARM/COLD verdict below) is the separate, complementary fix.
AGENTDIR="${AGENTDIR:-/tmp/appointments-agent}"
DOCS="https://$FERN_HANDLE.docs.buildwithfern.com"
MCP="$DOCS/_mcp/server"
FALLBACK="https://myhealthcare.docs.buildwithfern.com"

FAILED=0
note_fail() { echo "[FAIL] $1"; FAILED=1; }

echo "=== MCP Docs Best Friend (Live Build) — Setup ==="
echo ""

open_url() { open "$1" 2>/dev/null || xdg-open "$1" 2>/dev/null || return 1; }

# --- Tooling ----------------------------------------------------------------

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
  note_fail "claude CLI not found — Act 3e needs it. https://claude.com/claude-code"
fi

# --- Fern login -------------------------------------------------------------
# `fern generate --docs` opens a browser when it is not logged in. That is fine
# in a tutorial and fatal at a booth, so this is a hard failure.

if [ -s "$HOME/.fern/token" ] || [ -n "${FERN_TOKEN:-}" ]; then
  echo "[OK]   Fern CLI is logged in (token present)"
else
  note_fail "Fern CLI is not logged in — run 'fern login' (choose Continue with Postman) BEFORE the demo."
fi

# --- Does the organization actually resolve? ---------------------------------
# The check that would have saved a demo. `fern org get` answers "No org-level
# CLI config set for X" when the account belongs to X (a success — there is just
# no stored config), and 403 when it does not. `fern generate --docs` only tells
# you the same thing much later, as a 500 "Failed to resolve organization",
# after you have already said "watch this" out loud.

if command -v fern >/dev/null 2>&1; then
  ORG_OUT="$( cd "$(mktemp -d)" \
    && printf '{\n    "organization": "%s",\n    "version": "5.114.1"\n}\n' "$FERN_ORG" > fern.config.json \
    && mkdir -p fern && mv fern.config.json fern/ \
    && fern org get 2>&1 | head -1 )"
  if echo "$ORG_OUT" | grep -q '403'; then
    note_fail "Your Fern account has NO access to the organization '$FERN_ORG'."
    echo "       fern org get says: $ORG_OUT"
    echo ""
    echo "       This is the error that shows up later as a 500 'Failed to resolve"
    echo "       organization' from 'fern generate --docs'. Two causes:"
    echo "         - FERN_ORG names an organization you are not a member of, or"
    echo "         - the organization was DELETED (never do this — see the header)."
    echo ""
    echo "       Find the real one at https://dashboard.buildwithfern.com and set"
    echo "       FERN_ORG to it. It does NOT have to match the docs subdomain."
  else
    echo "[OK]   Organization '$FERN_ORG' resolves for this account"
  fi
fi

# --- Handle sanity ----------------------------------------------------------
# `myhealthcare.docs.buildwithfern.com` is the REAL MyHealthcare documentation:
# a live three-service site inside this same organization, presented by the short
# talk and linked from other content. `fern generate --docs` publishes wherever
# docs.yml points, so pointing this one-service demo at that subdomain would
# replace production documentation with nine appointment endpoints.
#
# This demo only ever READS that site — as the Act 3e warm fallback, via its MCP
# server and its llms.txt. Reading is safe. Publishing is not.

if [ "$FERN_HANDLE" = "myhealthcare" ]; then
  note_fail "FERN_HANDLE=myhealthcare would overwrite the REAL MyHealthcare documentation."
  echo "       That site is production, not a demo target. Use the throwaway name instead:"
  echo "       FERN_HANDLE=booth-demo ./scripts/setup.sh"
fi

# --- The source spec --------------------------------------------------------

echo ""
echo "--- The spec (Act 2) ---"

if [ ! -f "$SRC_SPEC" ]; then
  note_fail "Missing $SRC_SPEC"
else
  OPS="$(grep -c 'operationId' "$SRC_SPEC")"
  echo "[OK]   appointments.openapi.yaml found ($OPS operations)"

  # The payoff fact. Act 2 points at it in the file, Act 3e gets it back out of
  # the MCP server. If someone ever "cleans up" this description, the demo
  # still runs and stops proving anything — so check it explicitly.
  if grep -q 'a plain update emits' "$SRC_SPEC"; then
    echo "[OK]   The payoff warning is in the spec ('a plain update emits appointment.cancelled')"
  else
    note_fail "The 'a plain update emits' warning is gone from the spec — Act 3e has no payoff,"
    echo "       and the Act 2 grep prints nothing. Restore it before presenting."
  fi
fi

# --- The working folder -----------------------------------------------------
# "Empty folder, one file" is said out loud, so it has to be literally true:
# one file, no .git, no fern/. Leftovers are removed by teardown.sh, not here.

echo ""
echo "--- The working folder (Act 2) ---"

if [ -d "$WORKDIR" ] && [ -n "$(ls -A "$WORKDIR" 2>/dev/null)" ]; then
  note_fail "$WORKDIR already has content — run ./scripts/teardown.sh first."
  echo "       Leftovers: $(ls -A "$WORKDIR" | tr '\n' ' ')"
else
  rm -rf "$WORKDIR"
  mkdir -p "$WORKDIR"
  cp "$SRC_SPEC" "$WORKDIR/$SPEC_NAME"
  echo "[OK]   $WORKDIR created with exactly one file: $SPEC_NAME"
  echo "[OK]   No fern/ and no .git — Act 3a is a genuine first scaffold"
fi

# The agent's folder must be EMPTY. See the AGENTDIR comment at the top: if the
# agent can see the spec, it reads the spec and the payoff is worthless.

rm -rf "$AGENTDIR"
mkdir -p "$AGENTDIR"
if [ -z "$(ls -A "$AGENTDIR" 2>/dev/null)" ]; then
  echo "[OK]   $AGENTDIR is empty — Act 3e's agent can ONLY answer from the MCP server"
else
  note_fail "$AGENTDIR is not empty — the agent will read local files instead of calling searchDocs."
fi

# --- Preflight: does the Act 3a/3b sequence still pass? ---------------------
# `fern init` scaffolds a TypeScript SDK generator group, and the SDK validator
# rejects this spec's request examples: the schemas are open (additionalProperties,
# because the service stores a free-form JSONB `data` document) and the examples
# use keys that are therefore not declared. Five errors, every time. Docs do not
# care, but `fern check` does, and a red `fern check` on stage is a bad look.
#
# Act 3b fixes it by rewriting generators.yml down to `api.specs`. This preflight
# runs that exact sequence in a throwaway folder so a new CLI version or an edited
# spec cannot break the demo silently. Takes a few seconds and is worth it.
#
# It also proves the demo needs no git: the throwaway folder is not a repository.

echo ""
echo "--- Preflight: fern init + fern check (Acts 3a-3b) ---"

if command -v fern >/dev/null 2>&1 && [ -f "$SRC_SPEC" ]; then
  PRE="$(mktemp -d)"
  cp "$SRC_SPEC" "$PRE/$SPEC_NAME"
  if ( cd "$PRE" && fern init --openapi "./$SPEC_NAME" --organization "$FERN_ORG" >/dev/null 2>&1 ); then
    if [ -f "$PRE/fern/generators.yml" ] && [ ! -d "$PRE/fern/apis" ]; then
      echo "[OK]   fern init scaffolds the single-API layout (generators.yml, no apis/)"
    else
      note_fail "fern init did not produce the single-API layout — Act 3b's docs.yml would need an api-name."
    fi

    printf 'api:\n  specs:\n    - openapi: ../%s\n' "$SPEC_NAME" > "$PRE/fern/generators.yml"
    printf 'instances:\n  - url: %s.docs.buildwithfern.com\ntitle: Appointments Service | Documentation\nnavigation:\n  - api: API Reference\n' \
      "$FERN_HANDLE" > "$PRE/fern/docs.yml"

    # `fern check` prints "All checks passed" only when it has nothing at all to
    # say. As soon as there are warnings it prints "Found 0 errors and N warnings"
    # instead — still a pass. Gate on zero ERRORS, not on the happy-path string,
    # or a healthy project gets reported as broken.
    CHECK="$( cd "$PRE" && fern check 2>&1 )"
    if echo "$CHECK" | grep -qE 'All checks passed|Found 0 errors'; then
      echo "[OK]   fern check passes on the trimmed project — Act 3b lands green"
      echo "[OK]   ...and it passed in a folder that is not a git repo, which is why"
      echo "       this demo has no GitHub step"
    else
      note_fail "fern check FAILS even after the Act 3b trim. Do not present until this is understood:"
      echo "$CHECK" | tail -12 | sed 's/^/       /'
    fi
  else
    note_fail "fern init failed in a clean folder — Act 3a is broken. Run it by hand to see why."
  fi
  rm -rf "$PRE"
else
  echo "[WARN] Skipped — needs the fern CLI and the spec."
fi

# --- Is the docs index warm? ------------------------------------------------
# THE decision this script exists to make. A Fern subdomain answers whether or
# not anything was ever published there: an unpublished one returns an llms.txt
# with the header and no page links. Page links => a real site => a search
# index that already exists => Act 3e is fast. No page links => first publish
# on stage, and searchDocs may take 40s+ or come back empty.

echo ""
echo "--- The docs subdomain: $DOCS ---"

# Retry: a single timed-out curl reports a live site as COLD, which sends the
# presenter off to do a five-minute rehearsal they do not need — or teaches them
# to distrust this verdict, which is worse. Observed once on 2026-09-07, where
# teardown said "no pages" and setup said "11 pages" seconds apart.
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
  echo "       Act 3e is the payoff of this demo and it is at real risk right now. Fern"
  echo "       builds the search index AFTER the first publish, and it takes MINUTES,"
  echo "       not seconds. Measured 2026-09-07: still unavailable immediately after"
  echo "       'fern generate --docs' finished, answering normally ~5 minutes later."
  echo "       A ten-minute demo does not have five minutes of slack."
  echo ""
  echo "       Do this before you present, it takes about five minutes:"
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
    echo "[OK]   Its MCP server handshakes (Act 3e)"
  else
    echo "[WARN] No MCP handshake at $MCP yet — it appears after the publish in Act 3c."
  fi
fi

# The permanently-warm site from the short talk. Same spec, same warning, so it
# is a legitimate stand-in if the fresh site's index will not cooperate.
FB_PAGES="$(count_pages "$FALLBACK")"
if [ "${FB_PAGES:-0}" -gt 0 ]; then
  echo "[OK]   Fallback site is up ($FALLBACK, $FB_PAGES pages) — use it if Act 3e stalls"
else
  echo "[WARN] The fallback site is not answering either — check the network."
fi

# --- Claude Code state ------------------------------------------------------

# Detect by URL, never by name. There are at least THREE names in circulation for
# this one server and the presenter picks one by accident:
#
#   appointments-docs                          <- what this demo's crib sheet passes
#   booth-demo-docs-buildwithfern-com          <- what the docs site's UI snippet uses
#   fern_mcp_booth-demo-docs-buildwithfern-com <- what /_mcp/server's usage field suggests
#
# A name-based check misses two of the three and cheerfully reports "not
# registered" while the server is in fact connected. Observed 2026-09-08: the
# agent replied "no server named appointments-docs is connected; the only docs
# server available is booth-demo-docs-buildwithfern-com".
#
# It also has to look in the PARENT directories. `claude mcp add --scope local`
# is inherited by subdirectories, so a registration made in /private/tmp shows up
# in every /tmp/* folder — including AGENTDIR — which quietly makes "a genuine
# first-time connect" false. Running `claude mcp list` from inside AGENTDIR is
# what surfaces the inherited ones.

if command -v claude >/dev/null 2>&1; then
  echo ""
  FOUND="$( cd "$AGENTDIR" 2>/dev/null && claude mcp list 2>/dev/null | grep -F "$MCP" )"
  if [ -n "$FOUND" ]; then
    FOUND_NAME="$(echo "$FOUND" | head -1 | cut -d: -f1 | tr -d ' ')"
    echo "[WARN] This docs MCP server is ALREADY registered and visible from $AGENTDIR,"
    echo "       under the name '$FOUND_NAME'."
    echo "       Act 3e will not be a first-time connect, and 'claude mcp add' may error."
    echo "       ./scripts/teardown.sh removes it (it searches by URL, including parents)."
  else
    echo "[OK]   No registration for $MCP is visible from $AGENTDIR"
    echo "       — Act 3e is a genuine first-time connect"
  fi
  echo "[OK]   The Act 3e prompt names no server, so whichever name you register works"
fi

# --- Open what you present from ---------------------------------------------

# The deck, and nothing else. The docs site does not exist until Act 3c
# publishes it, and buildwithfern.com is a slide, not a demo surface — opening
# tabs you will not click is how you lose the one you need.

if [ "${SKIP_OPEN:-0}" = "1" ]; then
  echo ""
  echo "[OK]   SKIP_OPEN=1 — checks only, nothing opened."
else
  echo ""
  echo "Opening the deck..."
  open_url "file://$DECK" || echo "[WARN] Open the deck manually: $DECK"
fi

# --- The stage crib sheet ---------------------------------------------------

cat <<EOF

=================================================================
 Everything below is paste-ready. You should not need the README.
=================================================================

Terminal, large font, in: $WORKDIR

--- Act 2: what we start with -------------------------------------
  ls
  grep -n -A4 'a plain update emits' $SPEC_NAME

--- Act 3a: scaffold ----------------------------------------------
  fern init --openapi ./$SPEC_NAME --organization $FERN_ORG
  ls fern            <- two files: fern.config.json + generators.yml, NO apis/
  cat fern/generators.yml

  DO NOT run 'fern check' yet. fern init scaffolds a TypeScript SDK generator,
  and the SDK validator throws 5 errors on this spec's request examples. Act 3b
  removes that generator and THEN checks green. Checking here shows red.

--- Act 3b: two small YAML files ----------------------------------
  Paste this whole block. It trims generators.yml to docs-only, then adds the
  five lines that make the project a documentation site.

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

  fern check       <- expect "All checks passed", or "Found 0 errors" if it has
                      warnings to mention. Zero ERRORS is the pass.

  (Single API => NO api-name under '- api:'. Adding one fails the publish.)

--- Act 3c: publish -----------------------------------------------
  fern generate --docs          <- answer Yes to the production warning

--- Act 3d: the four outputs, in the browser ----------------------
  1. $DOCS
     -> API Reference -> Appointments -> Update an appointment
  2. add .md to that URL          <- same page, no chrome
  3. $DOCS/llms.txt
     -> read the "Instructions for AI Agents" header out loud
  4. $MCP

--- Act 3e: connect it to an agent and ask ------------------------
  MOVE FOLDERS FIRST. Do not run the agent in $WORKDIR — the spec is
  in there and the agent will read it instead of calling the MCP server.

  cd $AGENTDIR
  ls -la           <- empty. Say this out loud: "nothing here but the MCP server"

  claude mcp add --transport http $MCP_NAME $MCP
  claude
  /mcp             <- expect ONE server connected, one tool 'searchDocs'

  The name is yours to pick and nothing downstream depends on it. If you
  instead copy the snippet off the docs site you will get the long derived
  name (booth-demo-docs-buildwithfern-com) — that is fine, and arguably a
  better beat: "the docs even tell me the command". The prompt below names
  no server on purpose.

  Then paste this prompt verbatim:

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
  [ ] Deck fullscreen on slide 1 (press f, then Home)
  [ ] Terminal font ~18pt, cwd $WORKDIR
  [ ] You will cd to $AGENTDIR before Act 3e — the agent must NOT see the spec
  [ ] 'ls' shows one file and nothing else
  [ ] Claude Code context CLEAN — a warm session answers Act 3e without
      calling the tool, which destroys the payoff
  [ ] The subdomain verdict above says WARM
  [ ] You know the two beats cold: three steps, and one fact nobody guesses

When you are done:  ./scripts/teardown.sh
EOF

if [ "$FAILED" -ne 0 ]; then
  echo ""
  echo "=== Setup finished with FAILURES above. Fix them before presenting. ==="
  exit 1
fi

echo ""
echo "=== Setup complete. ==="
