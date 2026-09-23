#!/usr/bin/env bash
set -uo pipefail

# The Blast Radius You Can't Grep — setup.
#
# Run this before every session.
#
#   ./scripts/setup.sh              # probe the graph for real, cache the answer
#   ./scripts/setup.sh --skip-ask   # rehearse from the cached answer, no live call
#
# What it does NOT do: seed the estate. The repositories the graph answers about
# are published once by estate/seed-estate.sh and refreshed by the graph nightly.
# See estate/README.md.
#
# The live ask takes 20-40s by design (the graph reasons over the estate). Setup
# absorbs that wait so the stage never does.

CONTENT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DECK="$CONTENT_DIR/presentation/index.html"
STATE="$CONTENT_DIR/.demo-state"          # gitignored; teardown removes it
APP="$CONTENT_DIR/app"

# The estate the graph is asked about. Override if you seeded different names.
API_NAME="${ORDERS_API_NAME:-orders-api}"
ENDPOINT="${ORDERS_ENDPOINT:-GET /orders/{id}}"

ASK_QUESTION="Which services call the ${ENDPOINT} endpoint on ${API_NAME}, which teams own those services, and what evidence supports each dependency?"

SKIP_ASK=0
[ "${1:-}" = "--skip-ask" ] && SKIP_ASK=1

KNOWN_GOOD_CLI="1.62.0"

echo "=== The Blast Radius You Can't Grep — Setup ==="
echo ""

open_url() { open "$1" 2>/dev/null || xdg-open "$1" 2>/dev/null || return 1; }

need() {
  command -v "$1" >/dev/null 2>&1 && { echo "[OK]   $1 present"; return 0; }
  echo "[FAIL] $1 not found — $2"
  exit 1
}

mkdir -p "$STATE/raw"

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
  echo "       Then re-run this script. Act 3 cannot be improvised without it."
  exit 1
fi

# --- Reset the stage --------------------------------------------------------

if [ -f "$APP/IMPACT.md" ]; then
  rm -f "$APP/IMPACT.md"
  echo "[OK]   Removed app/IMPACT.md from a previous run — the payoff must be created live"
else
  echo "[OK]   No stale app/IMPACT.md — the payoff will be created live"
fi

if [ -f "$APP/src/serializers/order.js" ] && grep -q 'legacy_customer_ref' "$APP/src/serializers/order.js"; then
  echo "[OK]   app/ provider repo intact — legacy_customer_ref is present in the serializer"
else
  echo "[FAIL] app/src/serializers/order.js is missing or no longer serializes"
  echo "       legacy_customer_ref. Restore it:  git checkout -- app/"
  exit 1
fi

if [ -d "$CONTENT_DIR/estate/repos/invoice-service" ]; then
  echo "[OK]   estate/ sources present (published separately — see estate/README.md)"
fi

# Guard the premise of Act 1. The provider repo must contain NO consumer of its own
# endpoint: the moment a caller is greppable from app/, the agent gives the right
# answer in Act 1 and the talk loses its point. The provider calls nothing, so any
# outbound fetch under app/ means a consumer leaked in (usually by copying
# estate/repos/ in, or by running the agent from the content folder by mistake).
LEAKED="$(grep -rl 'fetch(' "$APP" --include='*.js' --exclude-dir=node_modules 2>/dev/null || true)"
if [ -n "$LEAKED" ]; then
  echo "[WARN] Outbound fetch() calls found under app/ — a consumer has leaked into the"
  echo "       provider repo, and Act 1's agent will answer correctly instead of confidently"
  echo "       wrong. Remove them:"
  echo "$LEAKED" | sed 's/^/         /'
else
  echo "[OK]   No consumer of the endpoint inside app/ — Act 1's premise holds"
fi

# --- Ask the graph for real -------------------------------------------------

ASK_RAW="$STATE/raw/ask.json"
ASK_TXT="$STATE/ask.txt"

run_ask() {
  echo ""
  echo "Asking the Context Graph (20-40s is normal — it reasons over the estate)..."
  echo "  Q: $ASK_QUESTION"
  postman context-graph ask "$ASK_QUESTION" \
    --wait --interval 5 --timeout 180 --json > "$ASK_RAW.tmp" 2> "$STATE/raw/ask.err"
  return $?
}

if [ "$SKIP_ASK" = "1" ]; then
  echo ""
  if [ -s "$ASK_RAW" ]; then
    echo "[OK]   --skip-ask: keeping the cached answer in .demo-state/ (rehearsal mode)"
  else
    echo "[WARN] --skip-ask was passed but there is no cached answer yet."
    echo "       Run setup once without --skip-ask before you present."
  fi
else
  run_ask
  ASK_EXIT=$?
  case "$ASK_EXIT" in
    0)
      mv "$ASK_RAW.tmp" "$ASK_RAW"
      echo "[OK]   The graph answered — raw response cached in .demo-state/raw/ask.json"
      ;;
    2)
      echo "[WARN] The ask reached a failed state (exit 2). See .demo-state/raw/ask.err"
      rm -f "$ASK_RAW.tmp"
      ;;
    4)
      echo "[WARN] The ask timed out (exit 4) but is still running server-side."
      echo "       Resume it with:  postman context-graph status <askId>"
      rm -f "$ASK_RAW.tmp"
      ;;
    *)
      echo "[WARN] The ask errored (exit $ASK_EXIT). Most common causes, in order:"
      echo "         - not signed in            -> postman login"
      echo "         - Context Graph not enabled for your team (it is not free-tier)"
      echo "         - the estate was never seeded or has not been ingested yet"
      echo "           -> estate/README.md"
      echo "       Details: .demo-state/raw/ask.err"
      rm -f "$ASK_RAW.tmp"
      ;;
  esac
fi

# --- Make the answer readable on stage --------------------------------------

if [ -s "$ASK_RAW" ]; then
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$ASK_RAW" "$ASK_TXT" <<'PY'
import json, sys

raw_path, txt_path = sys.argv[1], sys.argv[2]
with open(raw_path) as fh:
    try:
        payload = json.load(fh)
    except json.JSONDecodeError:
        fh.seek(0)
        open(txt_path, "w").write(fh.read())
        print("[WARN] Cached response is not JSON — wrote it through verbatim.")
        raise SystemExit(0)

def find_text(node, depth=0):
    """Pull the written answer out without assuming the envelope's shape."""
    if depth > 6:
        return None
    if isinstance(node, str):
        return node if len(node) > 80 else None
    if isinstance(node, dict):
        for key in ("answer", "text", "content", "result", "summary", "response", "data"):
            if key in node:
                found = find_text(node[key], depth + 1)
                if found:
                    return found
        for value in node.values():
            found = find_text(value, depth + 1)
            if found:
                return found
    if isinstance(node, list):
        for item in node:
            found = find_text(item, depth + 1)
            if found:
                return found
    return None

answer = find_text(payload)
with open(txt_path, "w") as out:
    if answer:
        out.write(answer.rstrip() + "\n")
    else:
        out.write("No prose answer found in the response. Full payload:\n\n")
        out.write(json.dumps(payload, indent=2))
        print("[WARN] No prose answer in the payload — wrote the whole thing to .demo-state/ask.txt")

if answer:
    words = len(answer.split())
    print(f"[OK]   Wrote .demo-state/ask.txt — the answer, {words} words, ready to read on stage")
PY
  else
    cp "$ASK_RAW" "$ASK_TXT"
    echo "[WARN] python3 not found — .demo-state/ask.txt is the raw JSON."
  fi

  # The service names are whatever the graph returned today. Never hardcode them.
  echo ""
  echo "       Services named in today's answer (grep, for your own sanity check):"
  for svc in invoice-service crm-sync-job mobile-bff; do
    if grep -qi "$svc" "$ASK_TXT" 2>/dev/null; then
      echo "         [found]   $svc"
    else
      echo "         [MISSING] $svc — do not promise it on stage"
    fi
  done
  echo "       Read .demo-state/ask.txt before you present. The graph is live; the"
  echo "       wording changes between runs. Say what it said today."
else
  echo "[WARN] No cached graph answer available."
  echo "       Act 3's live call has no fallback — see README section 6 before you start."
fi

# --- Paste-ready prompts ----------------------------------------------------

PROMPTS="$STATE/prompts.txt"
cat > "$PROMPTS" <<EOF
# Paste these into Claude Code, from inside ./app. In order. Nothing else is typed.

## Act 1 — the confident wrong answer (agent is boxed into the repo)
I want to remove the legacy_customer_ref field from the GET /orders/{id} response.
Answer from this repository only: do not call any external tool, CLI, or network.
Who breaks if I remove it? Give me a one-line verdict: safe or not safe to ship.

## Act 3 — the same question, with the estate in view
Same question: who breaks if I remove legacy_customer_ref from GET /orders/{id}?
This time you may use the Postman CLI to query our API Context Graph, which maps
every service, endpoint, deployment and owning team across the estate:

  postman context-graph ask "<your question>" --wait --interval 5

Then write app/IMPACT.md containing:
  - the verdict (ship / do not ship yet)
  - every service in the blast radius of the ENDPOINT, with its owning team
  - which of those are in the blast radius of the FIELD specifically
  - the evidence the graph gave you for each one
  - a recommended migration path
Cite the graph as your source. Do not guess anything it did not tell you.

## The command, if you want to run it yourself first
postman context-graph ask "$ASK_QUESTION" --wait --interval 5
EOF
echo ""
echo "[OK]   Wrote .demo-state/prompts.txt — both prompts, paste-ready"

# --- Open everything --------------------------------------------------------

echo ""
echo "Opening the presentation..."
open_url "$DECK" || echo "[WARN] Open presentation/index.html manually."

cat <<EOF

=== Setup complete. ===

Pre-flight checklist:
  [ ] Deck open, FULLSCREEN, on slide 1
  [ ] You have READ .demo-state/ask.txt and know what the graph said today
  [ ] Terminal in ./app with \`claude\` running, LARGE FONT (Cmd+=)
  [ ] app/src/serializers/order.js open in the editor, legacy_customer_ref visible
  [ ] .demo-state/prompts.txt open in a pane you can copy from
  [ ] No app/IMPACT.md yet — it is the payoff and must appear live
  [ ] A second terminal pane free for the \`postman context-graph ask\` run

When you are done:  ./scripts/teardown.sh
EOF
