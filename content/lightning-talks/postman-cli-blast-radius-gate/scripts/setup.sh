#!/usr/bin/env bash
set -uo pipefail

# The Check Your CI Is Missing — setup.
#
#   ./scripts/setup.sh              # rehearse the gate for real against the graph
#   ./scripts/setup.sh --skip-ask   # reuse the cached answer, no live call
#
# The stage sequence is: the breaking change is already made, the test suite is
# green, and the blast-radius gate is red. Setup puts the machine in exactly that
# state and proves it, by running the same gate the demo runs.
#
# What it does NOT do: seed the estate. The repositories the graph answers about
# are published once by estate/seed-estate.sh and picked up by the graph's nightly
# refresh. See estate/README.md.

CONTENT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DECK="$CONTENT_DIR/presentation/index.html"
STATE="$CONTENT_DIR/.demo-state"          # gitignored; teardown removes it
APP="$CONTENT_DIR/app"
BREAKING="$CONTENT_DIR/scripts/breaking-change"
GATE="$APP/ci/blast-radius-check.sh"

ASK_TXT="$STATE/ask.txt"
GATE_LOG="$STATE/gate-red.txt"

SKIP_ASK=0
[ "${1:-}" = "--skip-ask" ] && SKIP_ASK=1

KNOWN_GOOD_CLI="1.62.0"
EXPECTED_CONSUMERS="invoice-service crm-sync-job mobile-bff"

echo "=== The Check Your CI Is Missing — Setup ==="
echo ""

open_url() { open "$1" 2>/dev/null || xdg-open "$1" 2>/dev/null || return 1; }

need() {
  command -v "$1" >/dev/null 2>&1 && { echo "[OK]   $1 present"; return 0; }
  echo "[FAIL] $1 not found — $2"
  exit 1
}

mkdir -p "$STATE"

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

need node "install from https://nodejs.org/ (18+ — the provider repo uses built-in fetch)"
need claude "install Claude Code from https://code.claude.com/docs"
need postman "install the Postman CLI: npm install -g postman-cli@latest"
need git "pre-installed on macOS and Linux — the gate diffs the contract with it"
command -v python3 >/dev/null 2>&1 \
  && echo "[OK]   python3 present (used to read the CLI's JSON envelope)" \
  || echo "[WARN] python3 not found — the gate will print the raw JSON instead of prose"

CLI_VERSION="$(postman --version 2>/dev/null | tr -d '[:space:]')"
echo "[OK]   Postman CLI ${CLI_VERSION:-unknown}"

# Capability probe, not a version comparison: `context-graph` is only present on
# builds that ship it, and the root help is the honest place to look. Older CLIs
# answer `postman context-graph ...` with "Invalid command" and exit 0, so a
# naive command check would pass and the demo would die on stage.
if postman --help 2>&1 | grep -q 'context-graph'; then
  echo "[OK]   \`postman context-graph\` is available in this CLI"
else
  echo "[FAIL] This Postman CLI (${CLI_VERSION:-unknown}) has no \`context-graph\` command."
  echo "       Upgrade:  npm install -g postman-cli@latest     (known-good: $KNOWN_GOOD_CLI)"
  echo "       Then re-run this script. The gate cannot run without it."
  exit 1
fi

[ -x "$GATE" ] || { echo "[FAIL] Gate missing or not executable: $GATE"; exit 1; }
echo "[OK]   Gate present at app/ci/blast-radius-check.sh"

# --- Put the stage in its starting state ------------------------------------

if [ -f "$APP/IMPACT.md" ]; then
  rm -f "$APP/IMPACT.md"
  echo "[OK]   Removed app/IMPACT.md from a previous run — the agent writes it live"
fi

if git -C "$CONTENT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "$CONTENT_DIR" checkout -- app 2>/dev/null
  echo "[OK]   Restored app/ to its committed state"
else
  echo "[WARN] Not a git work tree — the gate diffs the contract with git and will skip."
fi

for f in order.js openapi.yaml; do
  [ -f "$BREAKING/$f" ] || { echo "[FAIL] Missing template: scripts/breaking-change/$f"; exit 1; }
done
cp "$BREAKING/order.js"    "$APP/src/serializers/order.js"
cp "$BREAKING/openapi.yaml" "$APP/openapi.yaml"
echo "[OK]   Applied the breaking change — legacy_customer_ref removed from the"
echo "       serializer and the spec, exactly as a developer would have left it"

if grep -q 'legacy_customer_ref:' "$APP/openapi.yaml"; then
  echo "[FAIL] The field is still in the spec — the breaking change did not apply."
  exit 1
fi

# Guard the premise. The provider calls nothing, so any outbound fetch under app/
# means a consumer leaked in — and then the Act 1 agent answers correctly instead
# of confidently wrong, which costs you the whole talk.
LEAKED="$(grep -rl 'fetch(' "$APP" --include='*.js' --exclude-dir=node_modules 2>/dev/null || true)"
if [ -n "$LEAKED" ]; then
  echo "[WARN] Outbound fetch() calls found under app/ — a consumer has leaked into"
  echo "       the provider repo. Remove them:"
  echo "$LEAKED" | sed 's/^/         /'
else
  echo "[OK]   No consumer of the endpoint inside app/ — Act 1's premise holds"
fi

# --- The suite must be green. That is the whole point of Act 1. -------------

if (cd "$APP" && npm test) > "$STATE/tests.txt" 2>&1; then
  PASSED="$(grep -oE 'pass [0-9]+' "$STATE/tests.txt" | tail -1 | awk '{print $2}')"
  echo "[OK]   app/ test suite is GREEN after the breaking change (${PASSED:-?} passing)"
  echo "       That is Act 1: nothing in this repo is wrong, and nobody is warned."
else
  echo "[FAIL] app/ test suite went red. Act 1 needs it green — a red suite means the"
  echo "       change broke orders-api against its own spec, which is a different talk."
  echo "       See .demo-state/tests.txt"
  exit 1
fi

# --- Rehearse the gate for real ---------------------------------------------

if [ "$SKIP_ASK" = "1" ]; then
  if [ -s "$ASK_TXT" ]; then
    echo "[OK]   --skip-ask: rehearsing the gate from the cached answer"
    (cd "$APP" && BLAST_RADIUS_ANSWER_FILE="$ASK_TXT" "$GATE") > "$GATE_LOG" 2>&1
    GATE_EXIT=$?
  else
    echo "[WARN] --skip-ask was passed but there is no cached answer yet."
    echo "       Run setup once without --skip-ask before you present."
    GATE_EXIT=2
  fi
else
  echo ""
  echo "Rehearsing the check against the live graph — the same run the agent will do"
  echo "on stage (the ask takes 20-40s; it reasons over the estate)..."
  (cd "$APP" && BLAST_RADIUS_SAVE_ANSWER="$ASK_TXT" "$GATE") > "$GATE_LOG" 2>&1
  GATE_EXIT=$?
fi

case "$GATE_EXIT" in
  1)
    echo "[OK]   The gate is RED (exit 1) — merge blocked, exactly as the demo needs"
    echo "       Full output: .demo-state/gate-red.txt"
    ;;
  0)
    echo "[FAIL] The gate PASSED. The demo has no red to go green from."
    echo "       Either the breaking change did not apply, or the graph found no"
    echo "       consumers (estate not ingested — see estate/README.md), or a stale"
    echo "       IMPACT.md is acknowledging them. Read .demo-state/gate-red.txt."
    ;;
  2)
    echo "[WARN] The gate could not reach the graph (exit 2). Most common causes:"
    echo "         - not signed in                  -> postman login"
    echo "         - Context Graph not enabled for your team (not a free-tier feature)"
    echo "         - the estate was never ingested  -> estate/README.md"
    if [ -s "$ASK_TXT" ]; then
      echo "       A cached answer from a previous run is available, so the demo can run"
      echo "       offline: export BLAST_RADIUS_ANSWER_FILE=$ASK_TXT"
    else
      echo "       No cached answer either. Act 3 has no fallback — README section 6."
    fi
    echo "       Full output: .demo-state/gate-red.txt"
    ;;
  *)
    echo "[WARN] The gate exited $GATE_EXIT, which it is not supposed to do."
    echo "       Read .demo-state/gate-red.txt before you present."
    ;;
esac

# --- What did the graph actually name today? --------------------------------

if [ -s "$ASK_TXT" ]; then
  echo ""
  echo "       Services in today's answer — the graph is live, so check every run:"
  for svc in $EXPECTED_CONSUMERS; do
    if grep -qi "$svc" "$ASK_TXT" 2>/dev/null; then
      echo "         [found]   $svc"
    else
      echo "         [MISSING] $svc — do not promise it on stage"
    fi
  done
  if grep -qiE '^[^a-z]*SERVICES:' "$ASK_TXT"; then
    echo "       [OK] The answer carries a parsable SERVICES: line — the gate can branch on it"
  else
    echo "       [WARN] No SERVICES: line in the answer. The gate will refuse to guess"
    echo "              service names and will exit 2 instead of 1. Read the answer and"
    echo "              expect to narrate Act 3 from .demo-state/ask.txt."
  fi
  echo "       Read .demo-state/ask.txt before you present. Say what it said today."
fi

# --- Paste-ready prompts ----------------------------------------------------

PROMPTS="$STATE/prompts.txt"
cat > "$PROMPTS" <<'EOF'
# Paste these into Claude Code, running from inside ./app. In order.
# Nothing else is typed on stage.

## Act 1 — the confident wrong answer (the agent is boxed into the repo)
I removed the deprecated legacy_customer_ref field from the GET /orders/{id}
response, in the serializer and in the spec. The test suite passes.
Answer from this repository only: do not call any external tool, CLI, or network.
Is this safe to merge? Give me a one-line verdict.

## Act 3 — the agent runs the check BEFORE the push, then fixes it
Before you push this, run the check we have for exactly this situation:

  ./ci/blast-radius-check.sh

It uses the Postman CLI to ask our API Context Graph who depends on this API,
because that is not answerable from inside this repository. It is also the second
job in our pipeline, so whatever it says now is what CI will say later.

If it blocks, use the same tool to get the detail you need:

  postman context-graph ask "<your question>" --wait --interval 5

Then fix the change so the check goes green, and tell me what you did:
  - keep the intent — this field is deprecated and should eventually go away
  - do not break the consumers the graph named
  - write IMPACT.md containing the verdict, every service in the blast radius of
    the ENDPOINT with its owning team, which of those read the FIELD specifically,
    the graph's evidence for each, and a migration path with a sunset date
  - re-run ./ci/blast-radius-check.sh and show me the exit code

Cite the graph as your source. Do not guess anything it did not tell you.

## If the network dies, add this line to the Act 3 prompt
The graph is unreachable from here, so run the check with the cached answer:
  BLAST_RADIUS_ANSWER_FILE=../.demo-state/ask.txt ./ci/blast-radius-check.sh
EOF
echo ""
echo "[OK]   Wrote .demo-state/prompts.txt — both prompts, paste-ready"

# --- Open everything --------------------------------------------------------

echo ""
echo "Opening the presentation..."
open_url "$DECK" || echo "[WARN] Open presentation/index.html manually."

cat <<EOF

=== Setup complete. ===

The machine is now in the starting state:
  - the breaking change is applied (git diff app/ shows it)
  - npm test is GREEN
  - ./ci/blast-radius-check.sh is RED (exit 1)

Pre-flight checklist:
  [ ] Deck open, FULLSCREEN, on slide 1
  [ ] You have READ .demo-state/ask.txt and know what the graph said today
  [ ] No [MISSING] service in the check above
  [ ] Terminal in ./app with \`claude\` running, LARGE FONT (Cmd+=)
  [ ] \`git diff app/\` ready in a pane — that is the change under review
  [ ] .demo-state/prompts.txt open in a pane you can copy from
  [ ] No app/IMPACT.md yet — the agent writes it live
  [ ] A second terminal pane in ./app — NOT for you to run the check (the agent
      does that, once, in Act 3), only for the fallbacks in README section 6

When you are done:  ./scripts/teardown.sh
EOF
