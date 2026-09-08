#!/usr/bin/env bash
set -uo pipefail

# The API You Can't Name — setup.
#
# Idempotent: running it twice leaves the same ready state.
#
# What makes this demo's setup unusual: it MEASURES the Act 4 scoreboard rather
# than trusting numbers written into the README. It runs the real Orbit search
# and integrate calls, fetches the documentation pages an agent would otherwise
# read, and writes .demo-state/scoreboard.txt. Read that file for the figures you
# say on stage. Nothing here is authored by hand.
#
# It also caches the live search + brief so Act 3 survives a dead network or an
# Orbit 500 on stage.

CONTENT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DECK="$CONTENT_DIR/presentation/index.html"
DECK_URL_FILE="$CONTENT_DIR/presentation/deck-url.txt"
STATE="$CONTENT_DIR/.demo-state"
MCP_JSON="$CONTENT_DIR/.mcp.json"

ORBIT_API="https://api.buildwithorbit.ai"
ORBIT_MCP="https://mcp.buildwithorbit.ai/mcp"

# The Act 3 query. This exact wording names the MECHANISM, not the feature —
# that is the lesson in Act 3, and it is why this query works where
# "book an appointment and email the attendee" returns nothing.
SEARCH_Q="Find available free busy time slots before booking a meeting"
TASK="Check whether a clinician is free before confirming an appointment slot in a healthcare booking app"

# The "before" baseline: the documentation pages an agent has to read to cover
# the same three capabilities (conflict check, create event, send confirmation).
DOC_PAGES=(
  "https://developer.nylas.com/docs/api/v3/ecc/"
  "https://developer.nylas.com/docs/v3/calendar/"
  "https://developer.nylas.com/docs/v3/getting-started/"
  "https://developer.nylas.com/docs/v3/email/"
)

echo "=== The API You Can't Name — Setup ==="
echo ""

open_url() { open "$1" 2>/dev/null || xdg-open "$1" 2>/dev/null || return 1; }

need() {
  command -v "$1" >/dev/null 2>&1 && { echo "[OK]   $1 present"; return 0; }
  echo "[FAIL] $1 not found — $2"
  exit 1
}

mkdir -p "$STATE"

# --- The deck ---------------------------------------------------------------
#
# Two sources, in priority order:
#   1. Claude Design — the team design system lives there, so that is the deck
#      of record. Put its share URL in presentation/deck-url.txt (one line,
#      comments with '#' ignored) and setup opens it.
#   2. presentation/index.html — the self-contained HTML fallback, committed so
#      there is ALWAYS a deck: no Claude Design access, no login at the venue,
#      no network, still a talk. It is checked below either way.

DECK_SOURCE="html"
DECK_URL=""
if [ -f "$DECK_URL_FILE" ]; then
  DECK_URL="$(grep -v '^[[:space:]]*#' "$DECK_URL_FILE" | grep -o 'https\?://[^[:space:]]*' | head -1)"
  [ -n "$DECK_URL" ] && DECK_SOURCE="claude-design"
fi

if [ ! -f "$DECK" ]; then
  echo "[FAIL] Fallback deck not found at $DECK — restore it from git."
  exit 1
fi
if head -c 64 "$DECK" | grep -qi '<!doctype html' && grep -q '</html>' "$DECK"; then
  echo "[OK]   Fallback deck found and well-formed (5 slides)"
else
  echo "[FAIL] Fallback deck is present but is not a complete HTML file — restore it from git."
  exit 1
fi

if [ "$DECK_SOURCE" = "claude-design" ]; then
  echo "[OK]   Deck of record: Claude Design — $DECK_URL"
  echo "       Open it BEFORE you go on stage; it needs a login and the network."
else
  echo "[INFO] No Claude Design deck configured — using the local HTML deck."
  echo "       To make Claude Design the deck of record, put its share URL in"
  echo "       presentation/deck-url.txt. The HTML deck stays as the fallback."
fi

# --- Tooling ----------------------------------------------------------------

need curl    "pre-installed on macOS; 'apt install curl' on Linux"
need python3 "install from https://www.python.org/downloads/ (3.8+)"

if command -v claude >/dev/null 2>&1; then
  echo "[OK]   Claude Code installed: $(claude --version 2>/dev/null || echo 'version unknown')"
else
  echo "[FAIL] Claude Code not found. Install from https://code.claude.com/docs"
  echo "       Act 3 is driven from a Claude Code session — this is required."
  exit 1
fi

# --- Register the Orbit MCP server, project-scoped --------------------------
#
# Written as a project-scoped .mcp.json in this folder rather than shelling out
# to 'claude mcp add', which would mutate the presenter's global config. This
# file is gitignored and teardown.sh removes it. The CTA slide still shows the
# 'claude mcp add' one-liner, because that is what the audience should type.

cat > "$MCP_JSON" <<EOF
{
  "mcpServers": {
    "orbit": {
      "type": "http",
      "url": "$ORBIT_MCP"
    }
  }
}
EOF
echo "[OK]   Orbit MCP server registered for this folder (.mcp.json, project scope)"
echo "       First 'claude' run here will ask you to approve it — do that NOW, not on stage."

# --- Measure the Orbit path (live) ------------------------------------------

echo ""
echo "Measuring the Orbit path (2 calls, no authentication)..."

SEARCH_JSON="$STATE/search.json"
BRIEF_JSON="$STATE/integrate.json"

# Two copies of every Orbit response, on purpose:
#
#   .demo-state/raw/*.json  — EXACTLY what came off the wire, one line, untouched.
#                             This is what the scoreboard measures. Pretty-printing
#                             adds thousands of whitespace bytes, and inflating
#                             Orbit's own byte count with indentation would be a
#                             made-up number in a talk whose premise is measurement.
#   .demo-state/*.json      — the same JSON, indented, for reading on stage and for
#                             the offline-fallback prompt.
RAW_DIR="$STATE/raw"
mkdir -p "$RAW_DIR"
RAW_SEARCH="$RAW_DIR/search.json"
RAW_BRIEF="$RAW_DIR/integrate.json"

# Indent a raw response into its readable twin. If the body is not valid JSON
# (an HTML error page, a truncated read), copy it through untouched rather than
# leaving a stale pretty file next to a fresh raw one.
prettify() {
  python3 - "$1" "$2" <<'PY' || cp "$1" "$2"
import json, shutil, sys
src, dst = sys.argv[1], sys.argv[2]
try:
    with open(src, encoding="utf-8") as f:
        data = json.load(f)
except Exception:
    shutil.copyfile(src, dst)
    raise SystemExit(0)
with open(dst, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY
}

SEARCH_Q_BODY="$(python3 -c 'import json,sys; print(json.dumps({"q": sys.argv[1]}))' "$SEARCH_Q")"

SEARCH_META="$(curl -s -m 90 -X POST "$ORBIT_API/v1/search?limit=10" \
  -H 'Content-Type: application/json' -d "$SEARCH_Q_BODY" \
  -o "$RAW_SEARCH.new" -w '%{http_code} %{size_download}')"
SEARCH_CODE="$(echo "$SEARCH_META" | cut -d' ' -f1)"

if [ "$SEARCH_CODE" = "200" ]; then
  mv "$RAW_SEARCH.new" "$RAW_SEARCH"
  prettify "$RAW_SEARCH" "$SEARCH_JSON"
  echo "[OK]   search  HTTP 200 — $(echo "$SEARCH_META" | cut -d' ' -f2) bytes"
  echo "       Readable copy: .demo-state/search.json (raw response kept in .demo-state/raw/)"
else
  rm -f "$RAW_SEARCH.new"
  echo "[WARN] search returned HTTP $SEARCH_CODE — Act 3's live call may fail."
  [ -f "$SEARCH_JSON" ] && echo "       Falling back to the cached search from a previous run." \
                        || echo "       No cache available. Act 3 has no fallback — see README section 6."
fi

# Build the integrate request from the search we JUST ran. Endpoint IDs are
# never hardcoded: the Orbit catalog is live and IDs change.
if [ -f "$SEARCH_JSON" ]; then
  REQ="$(python3 - "$SEARCH_JSON" "$TASK" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
picks = [{"id": r["id"], "type": r["resourceType"]} for r in data.get("data", [])[:2]]
print(json.dumps({"task": sys.argv[2], "resources": picks}) if picks else "")
PY
)"
else
  REQ=""
fi

if [ -n "$REQ" ]; then
  BRIEF_META="$(curl -s -m 180 -X POST "$ORBIT_API/v1/integrate" \
    -H 'Content-Type: application/json' -d "$REQ" \
    -o "$RAW_BRIEF.new" -w '%{http_code} %{size_download}')"
  BRIEF_CODE="$(echo "$BRIEF_META" | cut -d' ' -f1)"
  if [ "$BRIEF_CODE" = "200" ]; then
    mv "$RAW_BRIEF.new" "$RAW_BRIEF"
    prettify "$RAW_BRIEF" "$BRIEF_JSON"
    echo "[OK]   integrate HTTP 200 — $(echo "$BRIEF_META" | cut -d' ' -f2) bytes"
    echo "       Readable copy: .demo-state/integrate.json (raw response kept in .demo-state/raw/)"
  else
    rm -f "$RAW_BRIEF.new"
    echo "[WARN] integrate returned HTTP $BRIEF_CODE (500s happen — retry usually clears it)."
    [ -f "$BRIEF_JSON" ] && echo "       Falling back to the cached brief from a previous run."
  fi
else
  echo "[WARN] No search results to integrate — skipping the integrate measurement."
fi

# --- Plain-text renders, for reading on stage -------------------------------
#
# Indented JSON fixes search.json but NOT integrate.json: the whole task brief
# is a single JSON string with escaped \n, so pretty-printing leaves it as one
# unreadable seven-line wall. These two .txt files are what you actually read
# from at the podium — the evaluateGuide per result, and the brief with real
# newlines. Derived from raw/, never measured, never on the scoreboard.

python3 - "$STATE" <<'PY'
import json, os, sys

state = sys.argv[1]

def load(name):
    for p in (f"{state}/raw/{name}", f"{state}/{name}"):
        if os.path.exists(p):
            try:
                with open(p, encoding="utf-8") as f:
                    return json.load(f)
            except Exception:
                return None
    return None

search = load("search.json")
if isinstance(search, dict):
    out = ["ORBIT SEARCH RESULTS — readable render of search.json",
           "Act 3 beat 1 walks these. The 'Not supported:' line is the one that",
           "eliminates a candidate on sight.", ""]
    for i, r in enumerate(search.get("data", []), 1):
        out.append(f"[{i}] {r.get('method','?')} {r.get('name','?')}")
        out.append(f"    provider : {r.get('provider','?')} — {r.get('product','?')}")
        out.append(f"    url      : {r.get('url','?')}")
        if r.get("description"):
            out.append(f"    about    : {r['description']}")
        for line in (r.get("evaluateGuide") or "").split("\n"):
            out.append(f"    guide    | {line}" if line.strip() else "    guide    |")
        out.append(f"    id       : {r.get('id','?')}")
        out.append("")
    with open(f"{state}/search.txt", "w", encoding="utf-8") as f:
        f.write("\n".join(out))
    print(f"[OK]   Wrote .demo-state/search.txt — {len(search.get('data', []))} results, one block each")

brief = load("integrate.json")
if isinstance(brief, dict):
    out = ["ORBIT TASK BRIEF — readable render of integrate.json",
           "Act 3 beat 2 walks FIT, AUTH, BASE URL, STEPS, GOTCHAS in this order.", ""]
    for i, d in enumerate(brief.get("data", []), 1):
        if len(brief.get("data", [])) > 1:
            out.append(f"----- brief {i} " + "-" * 48)
        out.append(d.get("taskBrief", json.dumps(d, indent=2, ensure_ascii=False)))
        out.append("")
    with open(f"{state}/integrate.txt", "w", encoding="utf-8") as f:
        f.write("\n".join(out))
    print("[OK]   Wrote .demo-state/integrate.txt — the brief with real newlines")
PY

# --- Measure the docs path (live) -------------------------------------------

echo ""
echo "Measuring the read-the-docs path (${#DOC_PAGES[@]} pages)..."

DOCS_DIR="$STATE/docs"
mkdir -p "$DOCS_DIR"
DOCS_OK=1
i=0
for u in "${DOC_PAGES[@]}"; do
  i=$((i + 1))
  if curl -sL -m 60 -A "Mozilla/5.0" "$u" -o "$DOCS_DIR/page$i.html"; then
    sz=$(wc -c < "$DOCS_DIR/page$i.html" | tr -d ' ')
    if [ "$sz" -lt 1000 ]; then
      echo "[WARN] $u returned only ${sz}B — page moved or blocked."
      DOCS_OK=0
    fi
  else
    echo "[WARN] Could not fetch $u"
    DOCS_OK=0
  fi
done
[ "$DOCS_OK" = "1" ] && echo "[OK]   All ${#DOC_PAGES[@]} documentation pages fetched"

# --- Compute the scoreboard -------------------------------------------------

echo ""
echo "Computing the Act 4 scoreboard..."

python3 - "$STATE" <<'PY' | tee "$STATE/scoreboard.txt"
import glob, json, os, sys, re, datetime

state = sys.argv[1]

# TOKENS AND COST ARE NOT MEASURED HERE.
#
# They were measured once, on the date below, and are printed as fixed figures.
# They are also the numbers on the deck, so the slide and this sheet cannot drift
# apart. Re-measuring them on every launch needed either an ANTHROPIC_API_KEY or
# a chars/3.5 estimate, and produced a slightly different number each run for an
# argument whose shape ("about ten times") never moved.
#
# To refresh them, re-measure deliberately and edit these four constants AND
# slide 4 of presentation/index.html together. See README section 4b.
FIXED_DATE   = "2026-09-01"
FIXED_METHOD = "chars / 3.5 (ESTIMATE), measured once — not recomputed per run"
ORBIT_TOK, DOCS_TOK = 2413, 25647
ORBIT_COST, DOCS_COST = 0.0121, 0.1282

def size(p):
    return os.path.getsize(p) if os.path.exists(p) else 0

# NO WALL-CLOCK COMPARISON HERE, DELIBERATELY.
#
# Two calls that return an evaluated, gotcha-annotated brief and four raw HTML
# downloads are not the same operation, so timing them against each other
# compares nothing. It used to be a scoreboard row and an "honest caveat"; both
# are gone. The comparison that holds is bytes, context, and whether the answer
# is in there at all.

# --- Orbit path
#
# ALWAYS measure the raw wire responses in raw/, never the indented copies in
# .demo-state/ that the presenter reads: indentation would add several thousand
# bytes of whitespace to Orbit's side of the comparison. raw() falls back to the
# readable copy only for a cache written before raw/ existed, and says so.
def raw(name):
    r, pretty = f"{state}/raw/{name}", f"{state}/{name}"
    if os.path.exists(r):
        return r, False
    return pretty, os.path.exists(pretty)

search_p, search_est = raw("search.json")
brief_p, brief_est = raw("integrate.json")
inflated = search_est or brief_est

s_bytes = size(search_p)
b_bytes = size(brief_p)
orbit_text = ""
for p in (search_p, brief_p):
    if os.path.exists(p):
        orbit_text += open(p, encoding="utf-8", errors="ignore").read()

n_results = 0
if s_bytes:
    n_results = len(json.load(open(search_p)).get("data", []))

# --- Docs path: raw bytes, and the text an agent's context actually receives
doc_raw = doc_text = 0
pages = sorted(glob.glob(f"{state}/docs/*.html"))
kept = 0
for f in pages:
    raw = open(f, "rb").read()
    if len(raw) < 1000:
        continue
    kept += 1
    doc_raw += len(raw)
    s = raw.decode("utf-8", "ignore")
    s = re.sub(r"(?is)<(script|style|svg|noscript)\b.*?</\1>", " ", s)
    t = re.sub(r"(?s)<[^>]+>", " ", s)
    doc_text += len(re.sub(r"\s+", " ", t).strip())

W = 66
print("=" * W)
print(" ACT 4 SCOREBOARD — run of " + datetime.date.today().isoformat())
print(" Say these numbers on stage. Do not round them up.")
print(" Two blocks below: MEASURED TODAY, and FIXED (tokens + cost).")
print("=" * W)
print(" MEASURED TODAY — live Orbit calls and live documentation fetches")
print("-" * W)
print(f" {'':<26} {'ORBIT':>16} {'READ THE DOCS':>19}")
print(f" {'Round trips':<26} {str(2) + ' calls':>16} {str(kept) + ' pages':>19}")
print(f" {'Bytes retrieved':<26} {f'{s_bytes + b_bytes:,} B':>16} {f'{doc_raw:,} B':>19}")
print(f" {'Text into context':<26} {f'{len(orbit_text):,} ch':>16} {f'{doc_text:,} ch':>19}")
print("-" * W)
if s_bytes + b_bytes:
    print(f" Docs path pulls {(doc_raw / (s_bytes + b_bytes)):.0f}x the bytes.")
print(f" Search returned {n_results} evaluated endpoints for one sentence.")
if inflated:
    print(" NOTE: no raw/ response for one or both Orbit calls, so the two rows")
    print("       above were read from the INDENTED copy — Orbit's bytes and")
    print("       characters are overstated by the whitespace. Re-run setup with")
    print("       a network for the true figures.")

# Tokens and cost: fixed figures, stated as such. These match slide 4.
print("-" * W)
print(f" FIXED — tokens and cost, measured once on {FIXED_DATE}, NOT today")
print(f" Method  : {FIXED_METHOD}")
print(f" Pricing : Claude Opus 5 input, $5.00 / 1M tokens")
print(f" {'Tokens into context':<26} {f'{ORBIT_TOK:,}':>16} {f'{DOCS_TOK:,}':>19}")
print(f" {'Input cost (Opus 5)':<26} {f'${ORBIT_COST:.4f}':>16} {f'${DOCS_COST:.4f}':>19}")
print(f" Docs path pulls {DOCS_TOK / ORBIT_TOK:.1f}x the tokens. These two rows are")
print(f" the ones on the deck. If asked, say they were measured on {FIXED_DATE}.")

# Grep the fetched documentation for the three gotchas from the task brief.
# This is the load-bearing claim of Act 4, so measure it instead of asserting it.
print("-" * W)
print(" Are the three gotchas anywhere in the fetched documentation bytes?")
haystack = ""
for f in pages:
    raw = open(f, "rb").read()
    if len(raw) >= 1000:
        haystack += raw.decode("utf-8", "ignore").lower()
for term in ("start_time", "idempotency", "epoch"):
    n = haystack.count(term)
    flag = "<-- absent" if n == 0 else ""
    print(f"   {term:<14} {n:>4} hits in {doc_raw:,} bytes  {flag}")
print("=" * W)
print(" THE HONEST CAVEATS — say these, they make the point stronger:")
print("  - The docs path was handed the answer: these are NYLAS pages, and you")
print("    only know it is Nylas because the search said so. The discovery")
print("    problem — the premise of this talk — was solved for free first.")
print("  - There is no speed row here on purpose. Two evaluated API calls and")
print("    four raw HTML downloads are different operations; timing one against")
print("    the other compares nothing. If asked, say that.")
print("  - The API reference is JS-rendered, so those megabytes do not contain")
print("    the endpoint contract at all (see the grep above). More bytes, less")
print("    answer.")
print("  - WHAT WAS NOT MEASURED: an agent reading ~26k tokens and going back")
print("    for more. There is no number for that here. Do not invent one.")
print("  - 'A week of comparison became an afternoon' is the article author's")
print("    reported experience, NOT a measurement. Attribute it.")
print("=" * W)
PY

# --- Ready-to-paste prompts -------------------------------------------------

cat <<PROMPTS

===================================================================
 THE ORBIT PROMPTS — every prompt this talk uses, in running order
 Paste into Claude Code, launched from THIS folder so it sees the
 orbit MCP server. Do not retype them from the README on stage.
===================================================================

-------------------------------------------------------------------
[1] ACT 3, beat 1 — REQUIRED. The product problem, in a colleague's
    words. Never name Nylas, never name an endpoint. The whole beat
    is watching the agent translate this into calendar vocabulary.

The appointments service publishes appointment.booked but nothing reaches the
clinician's real calendar. Find me an API that can check whether a clinician is
free before we confirm a slot. Show me the evaluateGuide for each result.

-------------------------------------------------------------------
[2] ACT 3, beat 2 — REQUIRED. The brief. Let the agent carry the ids
    across on its own; that is Act 2 proving itself. Do NOT read an
    id out loud and do NOT paste one.

Get the integration brief for the two best-fitting results. The task is: when a
patient books an appointment slot in a healthcare app, check the clinician's
calendar for conflicts before confirming.

-------------------------------------------------------------------
[3] OPTIONAL, ~30s — the contrast shot. Only if you are ahead of the
    clock. This is the "name the mechanism, not the feature" lesson
    made visible: it returns school calendars and CRMs, not Nylas.
    If the room is quiet or you are at 6 minutes, SKIP IT.

Search Orbit again, but with this exact query instead: "create a calendar event
for a booked appointment". Show me the provider and product of each result.

-------------------------------------------------------------------
[4] FALLBACK — network dead, or Orbit 500s twice. Do not retry a
    third time on stage. Say "the catalog is live and it's having a
    moment", then run this. Every Act 3 beat works from the cache.

Read .demo-state/search.json and .demo-state/integrate.json and walk me through
them: first the evaluateGuide on each search result, then the FIT, AUTH, STEPS
and GOTCHAS sections of the brief.

    Prefer to read it yourself, no agent? Open .demo-state/search.txt
    and .demo-state/integrate.txt — same content, plain text, the
    brief with real newlines instead of escaped ones.

-------------------------------------------------------------------
[5] ACT 5 / CTA — the one on the closing slide. This is the prompt
    you are asking the audience to go home and run. Say it, do not
    run it.

We need to <the capability you're missing>. Search Orbit for an API that does
it, show me the evaluateGuide for the top results, then get the integration
brief for whichever ones you'd pick.

-------------------------------------------------------------------
 NO-CLAUDE-CODE BACKUP — if the MCP server will not load at all,
 both tools are public HTTP with no auth. These are the exact calls
 setup.sh just made:

curl -s -X POST '$ORBIT_API/v1/search?limit=10' \\
  -H 'Content-Type: application/json' \\
  -d '{"q": "$SEARCH_Q"}' | python3 -m json.tool

# then take an id + resourceType from that response:
curl -s -X POST '$ORBIT_API/v1/integrate' \\
  -H 'Content-Type: application/json' \\
  -d '{"task": "$TASK",
       "resources": [{"id": "<id>", "type": "endpoint"}]}' | python3 -m json.tool
===================================================================
PROMPTS

# --- Open everything --------------------------------------------------------

if [ "$DECK_SOURCE" = "claude-design" ]; then
  echo "Opening the Claude Design deck (and the HTML fallback behind it)..."
  open_url "$DECK_URL" || echo "[WARN] Open $DECK_URL manually."
  open_url "$DECK"     || echo "[WARN] Open presentation/index.html manually."
else
  echo "Opening the presentation..."
  open_url "$DECK" || echo "[WARN] Open presentation/index.html manually."
fi

cat <<EOF

=== Setup complete. Ready to present. ===

Pre-flight checklist:
  [ ] Deck open, FULLSCREEN, on slide 1 of 5  (source: $DECK_SOURCE)
  [ ] If presenting from Claude Design: logged in, deck loaded, and the
      local HTML deck open in a second tab in case the venue wifi drops
  [ ] Terminal in this folder, LARGE FONT (Cmd+= a few times)
  [ ] 'claude' launched here ONCE and the .mcp.json prompt APPROVED
  [ ] '/mcp' in Claude Code lists orbit with two tools: search, integrate
  [ ] You have read .demo-state/scoreboard.txt and know today's numbers
  [ ] You can say the three gotchas cold: epoch seconds, nullable busy,
      Idempotency-Key

When you are done:  ./scripts/teardown.sh
EOF
