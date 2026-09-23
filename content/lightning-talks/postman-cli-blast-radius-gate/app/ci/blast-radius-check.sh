#!/usr/bin/env bash
set -uo pipefail

# blast-radius-check — a release gate for orders-api.
#
# Your test suite checks this service against itself. This checks it against
# everyone who depends on it. It answers the one question CI cannot answer from
# inside a repository: if this diff removes a field from a response, who was
# reading that field?
#
# It is the Postman CLI that makes this possible in a pipeline. The CLI is the
# connector: one binary, the same command and the same exit-code contract in
# your terminal, in your coding agent's shell, and in CI. This script is only
# policy on top of it — about a hundred lines, and you own every one of them.
#
#   ./ci/blast-radius-check.sh                 # check the working tree
#   ./ci/blast-radius-check.sh --base main     # check this branch against main
#
# Exit codes (pipeline-aware, like the rest of the CLI):
#   0  no breaking field removals, or every consumer is acknowledged in IMPACT.md
#   1  BLOCKED — a field was removed and consumers of it are not acknowledged
#   2  INDETERMINATE — the graph could not be reached; see BLAST_RADIUS_ON_ERROR
#
# Environment:
#   BLAST_RADIUS_ON_ERROR=fail|pass   what exit 2 means for the build (default: fail)
#   BLAST_RADIUS_ANSWER_FILE=<path>   read a cached graph answer instead of calling
#                                     the CLI. Demo/offline switch only — a real
#                                     pipeline should never set this.
#   BLAST_RADIUS_SAVE_ANSWER=<path>   write the graph's answer out, so a rehearsal
#                                     run can produce the offline cache above.
#   POSTMAN_API_KEY                   how the CLI authenticates in CI

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SPEC="$REPO_ROOT/openapi.yaml"
ACK="$REPO_ROOT/IMPACT.md"
API_NAME="${ORDERS_API_NAME:-orders-api}"
ENDPOINT="${ORDERS_ENDPOINT:-GET /orders/{id}}"
ON_ERROR="${BLAST_RADIUS_ON_ERROR:-fail}"

BASE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --base) BASE="${2:-}"; shift 2 ;;
    -h|--help) sed -n '3,30p' "$0"; exit 0 ;;
    *) echo "unknown argument: $1"; exit 64 ;;
  esac
done

say()   { echo "  $*"; }
rule()  { echo "----------------------------------------------------------------------"; }

echo "=== blast-radius-check — $API_NAME ==="
echo ""

[ -f "$SPEC" ] || { echo "[SKIP] No openapi.yaml at $SPEC — nothing to check."; exit 0; }

# --- 1. What did this change remove from the contract? ----------------------
#
# Deliberately simple: removed keys in the spec diff that are no longer anywhere
# in the current spec. Good enough to gate a demo and to read on a slide; a real
# pipeline would diff the resolved schema rather than the file.

if ! git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[SKIP] Not a git work tree — cannot diff the contract."
  exit 0
fi

# Everything in the OpenAPI schema vocabulary is structure, not a field name.
# Removing `nullable:` along with a property is not a second breaking change.
SCHEMA_KEYWORDS='^(type|format|nullable|deprecated|description|example|examples|enum|items|default|required|properties|title|minimum|maximum|minLength|maxLength|pattern|readOnly|writeOnly|allOf|oneOf|anyOf|not|additionalProperties|schema|content|responses|parameters|components|paths|in|name|operationId|summary|tags|servers|info|version|contact|url)$'

DIFF="$(git -C "$REPO_ROOT" diff -U0 ${BASE:+"$BASE"} -- "$SPEC" 2>/dev/null)"
REMOVED=""
while IFS= read -r key; do
  [ -n "$key" ] || continue
  # A rename or a move is not a removal: only count keys absent from the spec now.
  grep -qE "^[[:space:]]*${key}:" "$SPEC" && continue
  REMOVED="$REMOVED $key"
done <<< "$(printf '%s\n' "$DIFF" \
            | grep -E '^-[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*:' \
            | sed -E 's/^-[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*):.*/\1/' \
            | grep -vE "$SCHEMA_KEYWORDS" \
            | sort -u)"

REMOVED="$(echo "$REMOVED" | xargs 2>/dev/null || true)"

if [ -z "$REMOVED" ]; then
  echo "[PASS] No fields removed from the published contract."
  echo ""
  echo "Nothing to ask the graph about. Exit 0."
  exit 0
fi

echo "[DIFF] This change removes from the contract:"
for f in $REMOVED; do say "- $f"; done
echo ""

# --- 2. Ask the Context Graph, through the CLI ------------------------------

FIELD_LIST="$(echo "$REMOVED" | tr ' ' ',')"

# A gate needs something it can branch on, so the question asks for a parsable
# tail on top of the prose. The prose is what goes on the screen; the SERVICES:
# line is what decides the exit code. If the graph does not produce the line, the
# gate says so and refuses to guess — see below.
QUESTION="Which services call the ${ENDPOINT} endpoint on ${API_NAME}, which of them read the ${FIELD_LIST} field(s) in that response, and which teams own those services? Give the evidence for each dependency. Then end your reply with one final line formatted exactly as: SERVICES: name1, name2 — listing only the names of the services that call the endpoint, comma separated, and nothing else on that line."

ANSWER_FILE="$(mktemp)"
trap 'rm -f "$ANSWER_FILE"' EXIT

if [ -n "${BLAST_RADIUS_ANSWER_FILE:-}" ]; then
  if [ -s "$BLAST_RADIUS_ANSWER_FILE" ]; then
    cp "$BLAST_RADIUS_ANSWER_FILE" "$ANSWER_FILE"
    echo "[CLI]  Using a CACHED graph answer ($BLAST_RADIUS_ANSWER_FILE)."
    echo "       This is the offline switch. A real pipeline calls the CLI."
  else
    echo "[FAIL] BLAST_RADIUS_ANSWER_FILE is set but empty or missing:"
    say "$BLAST_RADIUS_ANSWER_FILE"
    echo "       That is a configuration error, not a graph outage, so"
    echo "       BLAST_RADIUS_ON_ERROR does not apply. Exit 2."
    exit 2
  fi
else
  command -v postman >/dev/null 2>&1 || {
    echo "[FAIL] The Postman CLI is not installed — npm install -g postman-cli@latest"
    exit 2
  }
  if ! postman --help 2>&1 | grep -q 'context-graph'; then
    echo "[FAIL] This Postman CLI has no \`context-graph\` command."
    echo "       Upgrade: npm install -g postman-cli@latest"
    echo "       A missing command is a configuration error, so"
    echo "       BLAST_RADIUS_ON_ERROR does not apply. Exit 2."
    exit 2
  fi

  echo "[CLI]  postman context-graph ask ... --wait"
  say "Q: $QUESTION"
  echo ""
  RAW="$(mktemp)"
  if postman context-graph ask "$QUESTION" --wait --interval 5 --timeout 180 --json > "$RAW" 2>/dev/null; then
    python3 - "$RAW" "$ANSWER_FILE" <<'PY' || cp "$RAW" "$ANSWER_FILE"
import json, sys
raw, out = sys.argv[1], sys.argv[2]
payload = json.load(open(raw))

def find_text(node, depth=0):
    if depth > 6: return None
    if isinstance(node, str): return node if len(node) > 80 else None
    if isinstance(node, dict):
        for k in ("answer", "text", "content", "result", "summary", "response", "data"):
            if k in node:
                hit = find_text(node[k], depth + 1)
                if hit: return hit
        for v in node.values():
            hit = find_text(v, depth + 1)
            if hit: return hit
    if isinstance(node, list):
        for item in node:
            hit = find_text(item, depth + 1)
            if hit: return hit
    return None

open(out, "w").write((find_text(payload) or json.dumps(payload, indent=2)) + "\n")
PY
    rm -f "$RAW"
  else
    CLI_EXIT=$?
    rm -f "$RAW"
    echo "[FAIL] The CLI could not answer (exit $CLI_EXIT)."
    say "1 = auth or access (postman login / POSTMAN_API_KEY / graph not enabled)"
    say "2 = the ask failed · 4 = timed out, resume with: postman context-graph status <askId>"
    echo ""
    if [ "$ON_ERROR" = "pass" ]; then
      echo "[WARN] BLAST_RADIUS_ON_ERROR=pass — failing open. Exit 0."
      exit 0
    fi
    echo "[BLOCKED] Cannot prove this change is safe. Exit 2."
    echo "          Set BLAST_RADIUS_ON_ERROR=pass to fail open instead."
    exit 2
  fi
fi

if [ -n "${BLAST_RADIUS_SAVE_ANSWER:-}" ]; then
  cp "$ANSWER_FILE" "$BLAST_RADIUS_SAVE_ANSWER" 2>/dev/null \
    && echo "[CLI]  Answer saved to $BLAST_RADIUS_SAVE_ANSWER"
fi

rule
cat "$ANSWER_FILE"
rule
echo ""

# --- 3. Which consumers did the graph name? --------------------------------
#
# The names come from the graph's SERVICES: line, never from this script. Any
# name hardcoded here would be a lie the moment the estate changes — and
# scraping them out of the prose picks up team handles and file names, so it is
# not done either.

CONSUMERS="$(grep -oiE '^[^a-z]*SERVICES:.*' "$ANSWER_FILE" \
             | tail -1 \
             | sed -E 's/^[^:]*://' \
             | tr ',' '\n' \
             | sed -E 's/[^A-Za-z0-9_.-]//g' \
             | grep -vE "^${API_NAME}$" \
             | grep -E '.' \
             | sort -u | xargs 2>/dev/null || true)"

if [ -z "$CONSUMERS" ]; then
  echo "[WARN] The graph answered, but produced no parsable SERVICES: line."
  echo "       Read the answer above and decide yourself — this gate will not guess"
  echo "       which words in a paragraph were service names."
  if [ "$ON_ERROR" = "pass" ]; then
    echo "[WARN] BLAST_RADIUS_ON_ERROR=pass — failing open. Exit 0."
    exit 0
  fi
  echo "[BLOCKED] Refusing to treat 'could not parse' as 'no consumers'. Exit 2."
  exit 2
fi

echo "[GRAPH] Services the graph attached to this endpoint:"
for c in $CONSUMERS; do say "- $c"; done
echo ""

# --- 4. Has a human (or an agent) acknowledged them? ------------------------

if [ ! -f "$ACK" ]; then
  echo "[BLOCKED] This change removes$(for f in $REMOVED; do printf ' %s' "$f"; done) from the contract,"
  echo "          and $(echo "$CONSUMERS" | wc -w | tr -d ' ') service(s) are attached to the endpoint."
  echo ""
  echo "          There is no IMPACT.md acknowledging them."
  echo ""
  echo "          Write one that names every service above and the team that owns"
  echo "          it, or put the field back and deprecate it on a timeline."
  echo ""
  echo "          Merge blocked. Exit 1."
  exit 1
fi

MISSING=""
for c in $CONSUMERS; do
  grep -qi -- "$c" "$ACK" || MISSING="$MISSING $c"
done
MISSING="$(echo "$MISSING" | xargs 2>/dev/null || true)"

if [ -n "$MISSING" ]; then
  echo "[BLOCKED] IMPACT.md exists but does not account for:"
  for m in $MISSING; do say "- $m"; done
  echo ""
  echo "          Merge blocked. Exit 1."
  exit 1
fi

echo "[PASS] Every service the graph named is accounted for in IMPACT.md."
for c in $CONSUMERS; do say "- $c — acknowledged"; done
echo ""
echo "Shipping a known break is a decision, not an accident. Exit 0."
exit 0
