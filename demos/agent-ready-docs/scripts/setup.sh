#!/usr/bin/env bash
set -uo pipefail

DEMO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FIX="$DEMO_DIR/fixtures"
AUDIT="$DEMO_DIR/scripts/agent-audit.sh"

# shellcheck disable=SC1090
[ -f "$DEMO_DIR/demo.conf" ] && . "$DEMO_DIR/demo.conf"
FERN_SITE="${FERN_SITE:-https://elevenlabs.io/docs}"
MCP_NAME="${MCP_NAME:-elevenlabs-docs}"
MCP_URL="${MCP_URL:-https://elevenlabs.io/docs/_mcp/server}"
DEMO_QUESTION="${DEMO_QUESTION:-}"
DEMO_EXPECT="${DEMO_EXPECT:-300}"
CLAUDE_MODEL="${CLAUDE_MODEL:-}"

echo "=== Agent-Ready Docs — Booth Demo Setup ==="
echo ""

# 1. Required tooling ---------------------------------------------------------
for tool in curl awk sed; do
  command -v "$tool" >/dev/null 2>&1 || { echo "[FAIL] $tool not found."; exit 1; }
done
echo "[OK]   curl / awk / sed present"

if command -v claude >/dev/null 2>&1; then
  echo "[OK]   Claude Code installed: $(claude --version 2>/dev/null || echo 'version unknown')"
else
  echo "[FAIL] Claude Code not found. Install from https://code.claude.com/docs"
  exit 1
fi

if command -v node >/dev/null 2>&1; then
  echo "[OK]   Node.js $(node --version) (offline MCP fallback available)"
else
  echo "[WARN] Node.js not found — the offline MCP fallback for Act 4 will not run."
fi

command -v jq >/dev/null 2>&1 \
  && echo "[OK]   jq present (nicer Act 5 output)" \
  || echo "[WARN] jq not found — Act 5's api-catalog will print unformatted. brew install jq"

# 2. The audit script itself --------------------------------------------------
[ -x "$AUDIT" ] || { echo "[FAIL] scripts/agent-audit.sh missing or not executable."; exit 1; }
"$AUDIT" --help >/dev/null 2>&1 || { echo "[FAIL] agent-audit.sh is not runnable."; exit 1; }
echo "[OK]   agent-audit.sh runnable"

# 3. Online or offline? Say it loudly — the whole demo branches here ----------
echo ""
ONLINE=1
curl -sSf -m 5 -o /dev/null "$FERN_SITE/llms.txt" 2>/dev/null || ONLINE=0
if [ "$ONLINE" -eq 1 ]; then
  echo "############  MODE: ONLINE — everything runs live  ############"
else
  echo "############  MODE: OFFLINE — replaying cached snapshots  ############"
  echo "  Every act still works. Say so out loud; never present cached data as live."
fi

# 4. Fixtures -----------------------------------------------------------------
echo ""
# snapshots/ and corpus/ are gitignored (regenerable, and they vendor third-party
# docs), so a fresh clone has baseline.tsv but no offline fallbacks. Rebuild if
# any piece is missing, not just the baseline.
NEED_REFRESH=0
[ -f "$FIX/baseline.tsv" ] || NEED_REFRESH=1
[ -d "$FIX/snapshots" ] && [ -n "$(ls -A "$FIX/snapshots" 2>/dev/null)" ] || NEED_REFRESH=1
ls "$FIX/corpus/elevenlabs"/*.md >/dev/null 2>&1 || NEED_REFRESH=1

if [ "$NEED_REFRESH" -eq 1 ]; then
  if [ "$ONLINE" -eq 1 ]; then
    echo "Fixtures incomplete — recording them now (takes ~1 min)..."
    "$DEMO_DIR/scripts/refresh-fixtures.sh" >/dev/null 2>&1
  else
    echo "[WARN] Fixtures incomplete and no network. The scorecard may omit the"
    echo "       peer-median line, which is what keeps Act 3 from stinging."
  fi
fi

if [ -f "$FIX/baseline.tsv" ]; then
  AGE_DAYS=$(( ( $(date +%s) - $(stat -f %m "$FIX/baseline.tsv" 2>/dev/null || echo 0) ) / 86400 ))
  NSITES=$(( $(wc -l < "$FIX/baseline.tsv" | tr -d ' ') - 1 ))
  MEDIAN="$(awk -F'\t' 'NR>1{a[m++]=$2}
    END{ for(i=0;i<m;i++)for(j=i+1;j<m;j++)if(a[j]<a[i]){t=a[i];a[i]=a[j];a[j]=t}
         print (m%2)?a[int(m/2)]:int((a[m/2-1]+a[m/2])/2) }' "$FIX/baseline.tsv")"
  echo "[OK]   Baseline: $NSITES sites, median $MEDIAN (recorded ${AGE_DAYS}d ago)"
  if [ "$AGE_DAYS" -ge 1 ] && [ "$ONLINE" -eq 1 ]; then
    echo "       Stale — refreshing..."
    "$DEMO_DIR/scripts/refresh-fixtures.sh" >/dev/null 2>&1 && echo "[OK]   Fixtures refreshed"
  fi
fi

NSNAP=$(ls -1 "$FIX/snapshots" 2>/dev/null | wc -l | tr -d ' ')
NCORP=$(ls -1 "$FIX/corpus/elevenlabs"/*.md 2>/dev/null | wc -l | tr -d ' ')
echo "[OK]   Offline fallbacks: $NSNAP snapshots, $NCORP cached markdown pages"

# 5. Terminal width — the scorecard is a fixed 76 columns ---------------------
COLS="$(tput cols 2>/dev/null || echo 80)"
if [ "$COLS" -lt 84 ]; then
  echo "[WARN] Terminal is $COLS columns. The scorecard needs 84+. Press Cmd+- to shrink the font."
else
  echo "[OK]   Terminal width $COLS columns"
fi

# 6. Dry-run the anchor audit -------------------------------------------------
echo ""
echo "Dry-running the Act 2 audit against $FERN_SITE ..."
GRADE_LINE="$("$AUDIT" "$FERN_SITE" --json --timeout 8 2>/dev/null | sed -n 's/.*"grade": "\(.\)".*/\1/p' | head -1)"
SCORE_LINE="$("$AUDIT" "$FERN_SITE" --json --timeout 8 2>/dev/null | sed -n 's/.*"score": \([0-9]*\).*/\1/p' | head -1)"
if [ "${GRADE_LINE:-}" = "A" ]; then
  echo "[OK]   Anchor site scores ${GRADE_LINE} (${SCORE_LINE}) — Act 2 will land"
else
  echo "[WARN] Anchor site scored '${GRADE_LINE:-?}' (${SCORE_LINE:-?}), expected an A."
  echo "       Switch FERN_SITE in demo.conf to https://docs.cohere.com (scores 100)."
fi

# 7. Act 4 — validate the MCP question headlessly, WITHOUT pre-empting the ----
#    on-stage `claude mcp add`. We use a throwaway config and delete it after,
#    so the presenter still gets to type the real command in front of people.
echo ""
if [ -z "$DEMO_QUESTION" ]; then
  echo "[WARN] DEMO_QUESTION is empty in demo.conf — skipping the Act 4 dry run."
else
  DRY="$DEMO_DIR/.mcp.dryrun.json"
  if [ "$ONLINE" -eq 1 ]; then
    cat > "$DRY" <<EOF
{"mcpServers":{"$MCP_NAME":{"type":"http","url":"$MCP_URL"}}}
EOF
  else
    cat > "$DRY" <<EOF
{"mcpServers":{"$MCP_NAME":{"command":"node","args":["$DEMO_DIR/scripts/offline-docs-mcp.js"]}}}
EOF
  fi

  echo "Dry-running the Act 4 question (headless, ~30s)..."
  MODEL_ARG=""
  [ -n "$CLAUDE_MODEL" ] && MODEL_ARG="--model $CLAUDE_MODEL"
  # shellcheck disable=SC2086
  ANSWER="$(cd "$DEMO_DIR" && claude -p "$DEMO_QUESTION" \
      --strict-mcp-config --mcp-config "$DRY" \
      --allowedTools "mcp__${MCP_NAME}__searchDocs" \
      $MODEL_ARG 2>/dev/null)"
  rm -f "$DRY"

  if printf '%s' "$ANSWER" | grep -q "$DEMO_EXPECT"; then
    echo "[OK]   Act 4 PASSED — the answer contained '$DEMO_EXPECT'"
  else
    echo "[WARN] Act 4 dry run did NOT contain '$DEMO_EXPECT'."
    echo "       You are seeing this now instead of on stage. Options: re-run setup,"
    echo "       or fall back to Act 5 and skip the live query."
    printf '%s\n' "$ANSWER" | head -5 | sed 's/^/       | /'
  fi
fi

# 8. Presentation -------------------------------------------------------------
echo ""
[ -f "$DEMO_DIR/presentation/index.html" ] \
  && echo "[OK]   Presentation found" \
  || { echo "[FAIL] presentation/index.html not found"; exit 1; }

# 9. The command the presenter types on stage --------------------------------
echo ""
echo "=== Act 4 — the line you type on stage ==="
echo "-----------------------------------------------------------------"
if [ "$ONLINE" -eq 1 ]; then
  cat <<EOF
claude mcp add --transport http -s project $MCP_NAME $MCP_URL

claude --strict-mcp-config --mcp-config .mcp.json \\
       --allowedTools "mcp__${MCP_NAME}__searchDocs"
EOF
else
  cat <<EOF
# OFFLINE — the hosted server is unreachable, so point at the local snapshot:
claude mcp add -s project $MCP_NAME -- node scripts/offline-docs-mcp.js

claude --strict-mcp-config --mcp-config .mcp.json \\
       --allowedTools "mcp__${MCP_NAME}__searchDocs"
EOF
fi
echo "-----------------------------------------------------------------"
echo "  -s project     writes ./.mcp.json here, not your global config"
echo "  --strict-mcp-config  loads ONLY this server (you have others configured)"
echo ""
echo "Then paste:"
echo "  $DEMO_QUESTION"

# 10. Open the deck last ------------------------------------------------------
echo ""
echo "Opening presentation in browser..."
open "$DEMO_DIR/presentation/index.html" 2>/dev/null \
  || xdg-open "$DEMO_DIR/presentation/index.html" 2>/dev/null \
  || echo "[WARN] Could not open browser automatically. Open presentation/index.html manually."

echo ""
echo "=== Setup complete. Ready to demo. ==="
echo ""
echo "Pre-demo checklist:"
echo "  [ ] Mode above says ONLINE (or you have rehearsed the OFFLINE wording)"
echo "  [ ] Terminal is 84+ columns and the font is readable from 6 feet (Cmd+=)"
echo "  [ ] Act 2 dry run scored an A"
echo "  [ ] Act 4 dry run said PASSED"
echo "  [ ] Presentation open on the booth monitor, slide 1"
echo "  [ ] You know the peer median to quote: ${MEDIAN:-see fixtures/baseline.tsv}"
echo "  [ ] ASK CONSENT before typing an attendee's domain in Act 3"
