#!/usr/bin/env bash
#
# refresh-fixtures.sh — re-record everything the demo can fall back to offline.
#
# Run this each morning on hotel wifi, not at the booth. It:
#   1. scores the peer baseline and writes fixtures/baseline.tsv (MEASURED,
#      never hand-written — the scorecard quotes this median to an attendee)
#   2. snapshots full audits of the anchor sites so --offline replays a real
#      recording of a real audit
#   3. caches markdown pages into fixtures/corpus/ for the offline MCP server
#
# Takes 2-4 minutes. Safe to re-run.

set -uo pipefail

DEMO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FIX="$DEMO_DIR/fixtures"
AUDIT="$DEMO_DIR/scripts/agent-audit.sh"

# shellcheck disable=SC1090
[ -f "$DEMO_DIR/demo.conf" ] && . "$DEMO_DIR/demo.conf"
FERN_SITE="${FERN_SITE:-https://elevenlabs.io/docs}"

UA='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36 agent-audit/1.0 (+https://buildwithfern.com)'

echo "=== Agent-Ready Docs — refreshing fixtures ==="
echo ""

if ! curl -sSf -m 5 -o /dev/null -A "$UA" https://elevenlabs.io/docs/llms.txt 2>/dev/null; then
  echo "[FAIL] No network. Fixtures can only be recorded online — run this before you get to the venue."
  exit 1
fi
echo "[OK]   Network reachable"

slug_for() { echo "$1" | sed 's|^https\{0,1\}://||; s|/|__|g; s|__*$||'; }

# ---------------------------------------------------------------------------
# 1. Peer baseline
# ---------------------------------------------------------------------------
echo ""
echo "1. Scoring the peer baseline (this is the number we quote to attendees)..."
mkdir -p "$FIX"
SITES_FILE="$FIX/baseline-sites.txt"
if [ ! -f "$SITES_FILE" ]; then
  echo "[FAIL] $SITES_FILE is missing."
  exit 1
fi

TMPB="$(mktemp -d "${TMPDIR:-/tmp}/baseline.XXXXXX")"
trap 'rm -rf "$TMPB"' EXIT INT TERM

n=0
while IFS= read -r site; do
  case "$site" in ''|\#*) continue ;; esac
  n=$((n+1))
  (
    out="$("$AUDIT" "$site" --json --timeout 6 --budget 30 2>/dev/null)"
    sc="$(printf '%s' "$out" | sed -n 's/.*"score": \([0-9]*\).*/\1/p' | head -1)"
    gr="$(printf '%s' "$out" | sed -n 's/.*"grade": "\(.\)".*/\1/p' | head -1)"
    # Only record a real numeric score. A blocked or soft-404 site is not a
    # data point, and quietly counting it as 0 would drag the median down and
    # make the comparison dishonest.
    case "$sc" in
      ''|*[!0-9]*) : ;;
      *) [ "$gr" = "?" ] || [ "$gr" = "!" ] || printf '%s\t%s\t%s\n' "$site" "$sc" "$gr" > "$TMPB/$n.row" ;;
    esac
  ) &
done < "$SITES_FILE"
wait

{
  printf 'site\tscore\tgrade\n'
  cat "$TMPB"/*.row 2>/dev/null | sort -t"$(printf '\t')" -k2 -n
} > "$FIX/baseline.tsv"

scored="$(( $(wc -l < "$FIX/baseline.tsv" | tr -d ' ') - 1 ))"
median="$(awk -F'\t' 'NR>1{a[m++]=$2}
  END{ for(i=0;i<m;i++)for(j=i+1;j<m;j++)if(a[j]<a[i]){t=a[i];a[i]=a[j];a[j]=t}
       print (m%2)?a[int(m/2)]:int((a[m/2-1]+a[m/2])/2) }' "$FIX/baseline.tsv")"
echo "[OK]   Scored $scored of $n sites — median $median"
[ "$scored" -lt 5 ] && echo "[WARN] Fewer than 5 sites scored; the median line will be weak. Check connectivity."

# ---------------------------------------------------------------------------
# 2. Snapshots for offline replay
# ---------------------------------------------------------------------------
echo ""
echo "2. Snapshotting anchor sites for offline replay..."
for site in "$FERN_SITE" "https://docs.cohere.com" "https://docs.stripe.com"; do
  slug="$(slug_for "$site")"
  if "$AUDIT" "$site" --no-anim --no-color --save-snapshot "$FIX/snapshots/$slug" \
       --timeout 8 --budget 30 >/dev/null 2>&1; then
    g="$(sed -n 's/^grade=//p' "$FIX/snapshots/$slug/meta" 2>/dev/null)"
    s="$(sed -n 's/^score=//p' "$FIX/snapshots/$slug/meta" 2>/dev/null)"
    echo "[OK]   $slug — $g ($s)"
  else
    echo "[WARN] Could not snapshot $site"
  fi
done

# ---------------------------------------------------------------------------
# 3. Markdown corpus for the offline MCP server
# ---------------------------------------------------------------------------
echo ""
echo "3. Caching a markdown corpus for the offline MCP server..."
CORPUS="$FIX/corpus/elevenlabs"
mkdir -p "$CORPUS"
rm -f "$CORPUS"/*.md 2>/dev/null

LLMS="$(curl -sS -L -m 20 -A "$UA" "$FERN_SITE/llms.txt" 2>/dev/null)"

# The page holding the answer to demo.conf's DEMO_QUESTION must be in the
# corpus, or the offline path silently stops being able to answer it.
MUST="https://elevenlabs.io/docs/eleven-agents/guides/burst-pricing.md"

{
  echo "$MUST"
  printf '%s\n' "$LLMS" | grep -oE 'https://[^)]*\.md' | grep -v '^$' | head -60
} | awk '!seen[$0]++' > "$TMPB/urls"

got=0
while IFS= read -r url; do
  [ -z "$url" ] && continue
  [ "$got" -ge 30 ] && break
  name="$(printf '%s' "$url" | sed 's|^https\{0,1\}://||; s|\.md$||; s|[/?&=]|_|g').md"
  body="$(curl -sS -L -m 12 -A "$UA" "$url" 2>/dev/null)"
  # Skip the "Redirecting..." shims — a corpus full of stubs is worse than a
  # small corpus, because searchDocs would return confident nonsense.
  sz="$(printf '%s' "$body" | wc -c | tr -d ' ')"
  [ "${sz:-0}" -lt 1024 ] && continue
  printf '%s' "$body" | head -c 200 | grep -qiE '^[[:space:]]*(redirecting|<)' && continue
  {
    printf '<!-- source: %s -->\n' "$(printf '%s' "$url" | sed 's|\.md$||')"
    printf '%s\n' "$body"
  } > "$CORPUS/$name"
  got=$((got+1))
done < "$TMPB/urls"

echo "[OK]   Cached $got markdown pages to fixtures/corpus/elevenlabs/"
if [ ! -f "$CORPUS/$(printf '%s' "$MUST" | sed 's|^https\{0,1\}://||; s|\.md$||; s|[/?&=]|_|g').md" ]; then
  echo "[WARN] The burst-pricing page (the answer to DEMO_QUESTION) is NOT cached."
  echo "       Offline Act 4 will not be able to answer the scripted question."
fi

echo ""
echo "=== Fixtures refreshed. ==="
echo "  baseline : $scored sites, median $median"
echo "  snapshots: $(ls -1 "$FIX/snapshots" 2>/dev/null | wc -l | tr -d ' ')"
echo "  corpus   : $got pages"
