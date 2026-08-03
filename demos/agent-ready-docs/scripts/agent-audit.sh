#!/usr/bin/env bash
#
# agent-audit.sh — grade any documentation site on agent-readiness.
#
# One file. No dependencies beyond curl and awk (jq is used if present, but is
# never required). Portable to macOS's bash 3.2.
#
# It checks open standards only — llms.txt, sitemap.xml, markdown content
# negotiation, OpenAPI, RFC 9727 api-catalog, MCP. Nothing vendor-specific.
# That is the point: the scorecard has to be credible to someone who has never
# heard of Fern.
#
#   ./agent-audit.sh elevenlabs.io/docs
#   ./agent-audit.sh docs.yourcompany.com --page https://docs.yourcompany.com/api/users
#   ./agent-audit.sh docs.cohere.com --json
#
# Exit codes: 0 = audit completed (any grade), 1 = usage error, 2 = target unreachable.

set -uo pipefail

VERSION="1.0.0"

# The scorecard is drawn with box characters and padded by CHARACTER count via
# ${#var}, which only equals display width under a UTF-8 locale. Under C/POSIX
# bash counts bytes and every line containing a box char or an em dash comes out
# short. Force UTF-8 if we did not inherit it.
case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in
  *[Uu][Tt][Ff]*) : ;;
  *) LC_ALL=en_US.UTF-8; export LC_ALL ;;
esac

SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
DEMO_DIR="$(cd "$SELF_DIR/.." && pwd)"

# ---------------------------------------------------------------------------
# Defaults (demo.conf may override; flags override demo.conf)
# ---------------------------------------------------------------------------
TIMEOUT=8
BUDGET=15
MODE=auto
AUDIT_PAGE=""
TARGET=""
COMPARE=""
JSON=0
ANIM=1
COLOR=auto

[ -f "$DEMO_DIR/demo.conf" ] && . "$DEMO_DIR/demo.conf" 2>/dev/null

# Identify honestly, but look enough like a browser that WAFs don't reflexively
# block us. A booth demo that 403s because of the User-Agent is a bad time.
UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36 agent-audit/$VERSION (+https://buildwithfern.com)"

usage() {
  cat <<'EOF'
agent-audit.sh <url-or-domain> [options]

  --page <url>      Diff this exact page instead of auto-discovering one
  --compare <url>   Audit a second site afterwards, for contrast
  --offline         Replay a cached snapshot instead of hitting the network
  --live            Require the network; fail loudly rather than fall back
  --timeout <s>     Per-request timeout (default 8)
  --budget <s>      Hard wall-clock cap for one audit (default 15)
  --json            Machine-readable output
  --no-color        Disable ANSI color (also honors NO_COLOR and non-tty)
  --no-anim         Render the card instantly instead of building it
  -h, --help        This

Grades: A 85+  B 70-84  C 50-69  D 25-49  F <25
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --page)     AUDIT_PAGE="${2:-}"; shift 2 ;;
    --compare)  COMPARE="${2:-}"; shift 2 ;;
    --offline)  MODE=offline; shift ;;
    --live)     MODE=live; shift ;;
    --timeout)  TIMEOUT="${2:-8}"; shift 2 ;;
    --budget)   BUDGET="${2:-15}"; shift 2 ;;
    --json)     JSON=1; ANIM=0; shift ;;
    --no-color) COLOR=off; shift ;;
    --no-anim)  ANIM=0; shift ;;
    -h|--help)  usage; exit 0 ;;
    -*)         echo "unknown option: $1" >&2; usage >&2; exit 1 ;;
    *)          [ -z "$TARGET" ] && TARGET="$1" || true; shift ;;
  esac
done

[ -z "$TARGET" ] && { usage >&2; exit 1; }

# ---------------------------------------------------------------------------
# Color
# ---------------------------------------------------------------------------
if [ "$COLOR" = "off" ] || [ -n "${NO_COLOR:-}" ] || [ ! -t 1 ]; then
  USE_COLOR=0
else
  USE_COLOR=1
fi

c() { [ "$USE_COLOR" -eq 1 ] && printf '\033[38;5;%sm' "$1" || true; }
b() { [ "$USE_COLOR" -eq 1 ] && printf '\033[1m' || true; }
r() { [ "$USE_COLOR" -eq 1 ] && printf '\033[0m' || true; }

GREEN=42; RED=203; AMBER=214; GRAY=244; BLUE=75; WHITE=255

# ---------------------------------------------------------------------------
# Scratch
# ---------------------------------------------------------------------------
TMP="$(mktemp -d "${TMPDIR:-/tmp}/agent-audit.XXXXXX")"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT INT TERM

# ---------------------------------------------------------------------------
# Small helpers
# ---------------------------------------------------------------------------

# comma 1388460 -> 1,388,460   (macOS has no numfmt)
comma() {
  echo "${1:-0}" | awk '{ x=$1; s=""; while (length(x)>3) { s=","substr(x,length(x)-2)s; x=substr(x,1,length(x)-3) } print x s }'
}

lower() { echo "$1" | tr '[:upper:]' '[:lower:]'; }

# est_tokens <bytes> <html|md>
# HTML tokenizes denser than prose: angle brackets, long class-name strings and
# attribute soup all fragment. Markdown prose runs looser. These are midpoints
# of the observed cl100k/o200k range and are always rendered with a "~".
est_tokens() {
  awk -v bb="$1" -v k="$2" 'BEGIN { d = (k=="html" ? 3.5 : 4.2); printf "%d", bb/d }'
}

# human_tokens 397000 -> ~397K
human_tokens() {
  awk -v t="$1" 'BEGIN {
    if (t >= 1000000) printf "~%.1fM", t/1000000;
    else if (t >= 1000) printf "~%dK", int(t/1000 + 0.5);
    else printf "~%d", t
  }'
}

have_jq() { command -v jq >/dev/null 2>&1; }

# probe <slot> <url> [extra curl args...]
# Writes "$TMP/<slot>.meta" = code \t bytes \t ctype \t url_effective
# and the body to "$TMP/<slot>.body". Never returns nonzero.
probe() {
  _slot="$1"; _url="$2"; shift 2
  curl -sS -L --max-redirs 5 \
       -m "$TIMEOUT" --connect-timeout 4 \
       -A "$UA" -H 'Accept-Language: en' \
       -o "$TMP/$_slot.body" \
       -w '%{http_code}\t%{size_download}\t%{content_type}\t%{url_effective}\n' \
       "$@" "$_url" > "$TMP/$_slot.meta" 2>"$TMP/$_slot.err" \
    || printf '000\t0\tnetwork-error\t%s\n' "$_url" > "$TMP/$_slot.meta"
}

# probe_head <slot> <url>
# Same result shape as probe(), but HEAD-only and the size comes from
# Content-Length. Used wherever we only need existence + size — llms.txt files
# run to 200 KB and downloading them six times during base discovery is what
# turns a 3-second audit into a 17-second one.
probe_head() {
  _slot="$1"; _url="$2"
  _h="$TMP/$_slot.hdr"
  _m="$(curl -sSI -L --max-redirs 5 -m "$TIMEOUT" --connect-timeout 4 -A "$UA" \
        -D "$_h" -o /dev/null \
        -w '%{http_code}\t%{content_type}\t%{url_effective}' "$_url" 2>/dev/null)" \
    || _m="$(printf '000\tnetwork-error\t%s' "$_url")"
  _cl="$(tr -d '\r' < "$_h" 2>/dev/null | awk 'tolower($1)=="content-length:"{v=$2} END{print v+0}')"
  printf '%s\t%s\t%s\t%s\n' \
    "$(echo "$_m" | cut -f1)" "$_cl" "$(echo "$_m" | cut -f2)" "$(echo "$_m" | cut -f3)" \
    > "$TMP/$_slot.meta"
}

# f <slot> <field-number>
f() { cut -f"$2" < "$TMP/$1.meta" 2>/dev/null | tr -d '\n'; }

# trunc <string> <chars>  — character-aware, so multibyte never splits a cell
trunc() { printf '%s' "$1" | cut -c1-"$2"; }

# ---------------------------------------------------------------------------
# Results table. One row per check:
#   key \t layer \t label \t status \t code \t detail \t points \t max
# PASS | MISS | PARTIAL | BONUS | SKIP
# This TSV is the ONLY interchange format — the renderer reads it whether the
# data came from a live probe or a cached snapshot. One renderer, two sources.
# ---------------------------------------------------------------------------
RES="$TMP/results.tsv"
: > "$RES"

add() { printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" >> "$RES"; }

# ---------------------------------------------------------------------------
# Normalize the target
# ---------------------------------------------------------------------------
normalize() {
  _t="$1"
  case "$_t" in
    http://*|https://*) : ;;
    *) _t="https://$_t" ;;
  esac
  # strip trailing slash
  echo "$_t" | sed 's:/*$::'
}

# ---------------------------------------------------------------------------
# Phase 0 — base-path discovery
#
# elevenlabs.io/llms.txt is a 200 but elevenlabs.io/_mcp/server is a 404, while
# elevenlabs.io/docs/_mcp/server is a 200. If someone types a bare domain and
# the docs live under /docs, scoring the bare domain is not just wrong, it
# reads as an accusation. So: find the real base first, and print it.
# ---------------------------------------------------------------------------
discover_base() {
  _in="$1"
  # If the user gave us a path already, trust it.
  _path="$(echo "$_in" | sed 's|^https\{0,1\}://[^/]*||')"
  if [ -n "$_path" ] && [ "$_path" != "/" ]; then
    echo "$_in|given"
    return
  fi

  _root="$_in"
  _pids=""
  for cand in "" /docs /learn /reference /api /developers; do
    _s="base${cand//\//_}"
    probe_head "$_s"      "$_root$cand/llms.txt"   & _pids="$_pids $!"
    probe_head "${_s}mcp" "$_root$cand/_mcp/server" & _pids="$_pids $!"
  done
  wait $_pids

  # Neither "shallowest" nor "deepest" works on its own. Fern publishes an
  # llms.txt at EVERY section level, so on docs.cohere.com all six candidates
  # return 200 and "deepest wins" lands on a section index. Meanwhile
  # elevenlabs.io serves an llms.txt at the root but hosts the real docs (and
  # the MCP server) under /docs, so "shallowest wins" is wrong there.
  #
  # The MCP endpoint is the reliable tell: it exists once, at the docs root.
  # Prefer the shallowest candidate that has one; fall back to the shallowest
  # with a substantial llms.txt.
  _withmcp=""; _withllms=""
  for cand in "" /docs /learn /reference /api /developers; do
    _s="base${cand//\//_}"
    case "$(lower "$(f "$_s" 3)")" in *text/html*) continue ;; esac
    [ "$(f "$_s" 1)" = "200" ] || continue
    _size="$(f "$_s" 2)"
    # size 0 means chunked with no Content-Length — not evidence of absence.
    { [ "${_size:-0}" -eq 0 ] || [ "${_size:-0}" -ge 200 ]; } || continue

    [ -z "$_withllms" ] && _withllms="$_root$cand"
    if [ -z "$_withmcp" ] && [ "$(f "${_s}mcp" 1)" = "200" ]; then
      case "$(lower "$(f "${_s}mcp" 3)")" in *json*) _withmcp="$_root$cand" ;; esac
    fi
  done

  if   [ -n "$_withmcp" ];  then echo "$_withmcp|auto"
  elif [ -n "$_withllms" ]; then echo "$_withllms|auto"
  else echo "$_root|default"
  fi
}

# ---------------------------------------------------------------------------
# Phase 1 — soft-404 control probe
#
# Plenty of docs sites return 200 with a full HTML shell for absolutely any
# path. Without a control, this tool cheerfully reports llms.txt "present" on a
# site that has never heard of it. Fingerprint a guaranteed-garbage path and
# treat any lookalike response as a miss.
# ---------------------------------------------------------------------------
CTRL_CODE=""; CTRL_SIZE=0; CTRL_CT=""

# looks_like_control <slot> -> 0 if this "hit" is really the soft-404 page
looks_like_control() {
  [ "${CTRL_CODE:-000}" != "200" ] && return 1
  _s="$(f "$1" 2)"; _ct="$(lower "$(f "$1" 3)")"
  [ -z "$_s" ] && return 1
  # same content-type and within 2% of the control's size
  [ "$_ct" != "$CTRL_CT" ] && return 1
  awk -v a="$_s" -v bb="$CTRL_SIZE" 'BEGIN { d=(a>bb?a-bb:bb-a); exit !(bb>0 && d/bb < 0.02) }'
}

# is_html <slot>
is_html() { case "$(lower "$(f "$1" 3)")" in *text/html*) return 0 ;; esac; return 1; }

# body_is_stub <slot>
# Fern (and most docs platforms) serve a tiny "Redirecting..." shim for some
# .md URLs. elevenlabs.io/docs/capabilities/text-to-speech.md is 343 bytes
# against 636 KB of HTML — a naive audit reports a fake 99.9% win. Catch it.
body_is_stub() {
  _sz="$(f "$1" 2)"
  [ "${_sz:-0}" -lt 1024 ] && return 0
  head -c 200 "$TMP/$1.body" 2>/dev/null | grep -qiE '^[[:space:]]*(redirecting|<)' && return 0
  return 1
}

# ---------------------------------------------------------------------------
# Phase 3 — three-tier size resolution: HEAD -> Range -> capped GET
#
# The whole point of this demo is that the HTML page is enormous. Downloading
# it on booth wifi to prove it is enormous would be self-defeating.
# NOTE: never pass --compressed. The numbers we quote are uncompressed transfer
# sizes, and gzip helps the wire, not the context window.
# ---------------------------------------------------------------------------
html_size() {
  _u="$1"
  _n="$(curl -sSI -L --max-redirs 5 -m 6 -A "$UA" "$_u" 2>/dev/null \
        | tr -d '\r' | awk 'tolower($1)=="content-length:"{v=$2} END{print v+0}')"
  if [ "${_n:-0}" -gt 0 ]; then printf '%s\thead\n' "$_n"; return; fi

  _n="$(curl -sS -L --max-redirs 5 -m 6 -A "$UA" -r 0-0 -D - -o /dev/null "$_u" 2>/dev/null \
        | tr -d '\r' | awk 'tolower($1)=="content-range:"{split($2,a,"/"); v=a[2]} END{print v+0}')"
  if [ "${_n:-0}" -gt 0 ]; then printf '%s\trange\n' "$_n"; return; fi

  _n="$(curl -sS -L --max-redirs 5 -m "$TIMEOUT" -A "$UA" -o /dev/null -w '%{size_download}' "$_u" 2>/dev/null)"
  _rc=$?
  if [ $_rc -eq 28 ]; then printf '%s\tpartial\n' "${_n:-0}"; else printf '%s\tget\n' "${_n:-0}"; fi
}

# ---------------------------------------------------------------------------
# Phase 2 — pick a representative page to diff
#
# Preference order: explicit flag, demo.conf, a path the user already gave us,
# then the sitemap (favouring API reference pages, which carry the rendered
# spec and therefore the most HTML). At a booth you should always be pinned.
# ---------------------------------------------------------------------------
host_of() { echo "$1" | sed 's|^https\{0,1\}://||; s|/.*||'; }

pick_page() {
  _base="$1"
  # Only honor the pinned page if it actually belongs to the site being
  # audited. demo.conf pins an ElevenLabs page; without this guard, auditing
  # any other domain would silently diff ElevenLabs' bytes and report them as
  # that site's — the worst kind of wrong, because it looks plausible.
  if [ -n "$AUDIT_PAGE" ] && [ "$(host_of "$AUDIT_PAGE")" = "$(host_of "$_base")" ]; then
    echo "$AUDIT_PAGE|pinned"; return
  fi

  _path="$(echo "$TARGET_URL" | sed 's|^https\{0,1\}://[^/]*||')"
  _depth="$(echo "$_path" | awk -F/ '{print NF-1}')"
  if [ "${_depth:-0}" -ge 2 ]; then echo "$TARGET_URL|given"; return; fi

  if [ "$(f sitemap 1)" = "200" ] && ! is_html sitemap; then
    # Portable <loc> extraction — no GNU sed, no xmllint.
    tr '<' '\n' < "$TMP/sitemap.body" 2>/dev/null | grep '^loc>' | sed 's/^loc>//' > "$TMP/locs" 2>/dev/null

    # A sitemap index points at more sitemaps. Follow exactly one level.
    if head -1 "$TMP/locs" 2>/dev/null | grep -q '\.xml$'; then
      _child="$(head -1 "$TMP/locs")"
      probe sitemap2 "$_child"
      tr '<' '\n' < "$TMP/sitemap2.body" 2>/dev/null | grep '^loc>' | sed 's/^loc>//' > "$TMP/locs" 2>/dev/null
    fi

    _cands="$(grep -E '/(api-reference|reference|api|endpoint)/' "$TMP/locs" 2>/dev/null | head -5)"
    [ -z "$_cands" ] && _cands="$(grep -v '\.xml$' "$TMP/locs" 2>/dev/null | head -3)"

    if [ -n "$_cands" ]; then
      _bestu=""; _bestn=0; _i=0; _pids=""
      for u in $_cands; do
        _i=$((_i+1))
        ( html_size "$u" > "$TMP/cand$_i.size" ) & _pids="$_pids $!"
      done
      wait $_pids
      _i=0
      for u in $_cands; do
        _i=$((_i+1))
        _n="$(cut -f1 < "$TMP/cand$_i.size" 2>/dev/null)"
        if [ "${_n:-0}" -gt "$_bestn" ]; then _bestn="$_n"; _bestu="$u"; fi
      done
      [ -n "$_bestu" ] && { echo "$_bestu|sitemap"; return; }
    fi
  fi

  echo "$_base|fallback"
}

# ---------------------------------------------------------------------------
# The audit
# ---------------------------------------------------------------------------
BASE=""; BASE_HOW=""; PAGE=""; PAGE_HOW=""
HTML_BYTES=0; HTML_METHOD=""; MD_BYTES=0
SCORE=0; MAXSCORE=100; GRADE=""; BLOCKED=0; SOFT404=0; LIVE=1
MCP_TOOL=""

run_live_audit() {
  _out="$(discover_base "$TARGET_URL")"
  BASE="${_out%|*}"; BASE_HOW="${_out#*|}"

  # The control probe is the slowest single request on most sites — servers
  # render their full 404 shell for it (ElevenLabs takes ~4.8s). Run it
  # alongside the real checks rather than before them, so it costs wall clock
  # only once instead of serially.
  # NOTE: wait on explicit PIDs. A bare `wait` also blocks on the watchdog's
  # sleep, which pins every audit to the full budget.
  _pids=""
  probe      control  "$BASE/__agent-audit-control-$$-$RANDOM" & _pids="$_pids $!"
  probe      robots   "$BASE/robots.txt"       & _pids="$_pids $!"
  probe      sitemap  "$BASE/sitemap.xml"      & _pids="$_pids $!"
  probe      llms     "$BASE/llms.txt"         & _pids="$_pids $!"
  probe_head llmsfull "$BASE/llms-full.txt"    & _pids="$_pids $!"
  probe      openapi  "$BASE/openapi.json"     & _pids="$_pids $!"
  probe      catalog  "$BASE/.well-known/api-catalog" & _pids="$_pids $!"
  probe      mcp      "$BASE/_mcp/server"      & _pids="$_pids $!"
  wait $_pids

  CTRL_CODE="$(f control 1)"
  CTRL_SIZE="$(f control 2)"
  CTRL_CT="$(lower "$(f control 3)")"
  if [ "$CTRL_CODE" = "403" ] || [ "$CTRL_CODE" = "429" ]; then BLOCKED=1; fi
  if [ "$CTRL_CODE" = "000" ]; then return 2; fi

  # --- DISCOVERY -----------------------------------------------------------
  _code="$(f robots 1)"
  if [ "$_code" = "200" ] && ! looks_like_control robots; then
    if grep -A100 -iE '^user-agent:[[:space:]]*\*' "$TMP/robots.body" 2>/dev/null | grep -qiE '^disallow:[[:space:]]*/[[:space:]]*$'; then
      add robots DISCOVERY "robots.txt" MISS "$_code" "disallows all crawlers" 0 10
    else
      _sm=""; grep -qi '^sitemap:' "$TMP/robots.body" 2>/dev/null && _sm=", sitemap declared"
      add robots DISCOVERY "robots.txt" PASS "$_code" "crawlable$_sm" 10 10
    fi
  else
    add robots DISCOVERY "robots.txt" MISS "$_code" "not found" 0 10
  fi

  _code="$(f sitemap 1)"
  _nloc=0
  [ "$_code" = "200" ] && _nloc="$(tr '<' '\n' < "$TMP/sitemap.body" 2>/dev/null | grep -c '^loc>')"
  if [ "$_code" = "200" ] && ! is_html sitemap && [ "${_nloc:-0}" -ge 1 ] && ! looks_like_control sitemap; then
    add sitemap DISCOVERY "sitemap.xml" PASS "$_code" "$(comma "$_nloc") URLs" 15 15
  else
    add sitemap DISCOVERY "sitemap.xml" MISS "$_code" "not found" 0 15
  fi

  _code="$(f llms 1)"; _size="$(f llms 2)"
  if [ "$_code" = "200" ] && [ "${_size:-0}" -ge 200 ] && ! is_html llms && ! looks_like_control llms; then
    _hint=""
    grep -qi 'instructions for ai agents' "$TMP/llms.body" 2>/dev/null && _hint=", agent instructions"
    add llms DISCOVERY "llms.txt" PASS "$_code" "$(comma "$_size") B$_hint" 15 15
  else
    add llms DISCOVERY "llms.txt" MISS "$_code" "not found" 0 15
  fi

  # Bonus only, never scored. Cohere serves a 662 B stub here, ElevenLabs
  # serves a byte-identical copy of llms.txt, Fern's own site 404s. Scoring it
  # would break the all-green moment on stage for no analytical gain.
  _code="$(f llmsfull 1)"; _size="$(f llmsfull 2)"; _lsize="$(f llms 2)"
  if [ "$_code" != "200" ] || is_html llmsfull; then
    add llmsfull DISCOVERY "llms-full.txt" SKIP "$_code" "absent" 0 0
  elif [ "${_size:-0}" -gt 0 ] && [ "${_size:-0}" -gt $(( ${_lsize:-0} * 4 )) ]; then
    add llmsfull DISCOVERY "llms-full.txt" BONUS "$_code" "$(comma "$_size") B full corpus" 0 0
  elif [ "${_size:-0}" -gt 0 ] && [ "${_size:-0}" -eq "${_lsize:-0}" ]; then
    add llmsfull DISCOVERY "llms-full.txt" SKIP "$_code" "byte-identical to llms.txt" 0 0
  elif [ "${_size:-0}" -gt 0 ] && [ "${_size:-0}" -lt 2048 ]; then
    add llmsfull DISCOVERY "llms-full.txt" SKIP "$_code" "stub ($(comma "$_size") B)" 0 0
  else
    # HEAD advertised no Content-Length (chunked). Fetch and inspect rather than
    # guessing: Cohere serves a 662-byte "Redirecting..." stub here and
    # ElevenLabs serves a byte-identical copy of llms.txt. Calling either a
    # "full corpus" would be a false claim on a slide the audience is reading.
    curl -sS -L --max-redirs 5 -m 6 -A "$UA" -r 0-4095 -o "$TMP/lf.raw" "$BASE/llms-full.txt" 2>/dev/null
    _lfsz="$(wc -c < "$TMP/lf.raw" 2>/dev/null | tr -d ' ')"
    # The server may ignore Range and send the whole body, so cap both sides.
    head -c 512 "$TMP/lf.raw"     > "$TMP/lf.head" 2>/dev/null
    head -c 512 "$TMP/llms.body"  > "$TMP/l.head"  2>/dev/null
    if head -c 200 "$TMP/lf.raw" 2>/dev/null | grep -qiE '^[[:space:]]*(redirecting|<)'; then
      add llmsfull DISCOVERY "llms-full.txt" SKIP "$_code" "redirect stub, not content" 0 0
    elif cmp -s "$TMP/lf.head" "$TMP/l.head"; then
      add llmsfull DISCOVERY "llms-full.txt" SKIP "$_code" "same content as llms.txt" 0 0
    elif [ "${_lfsz:-0}" -lt 2048 ]; then
      add llmsfull DISCOVERY "llms-full.txt" SKIP "$_code" "stub ($(comma "$_lfsz") B)" 0 0
    else
      add llmsfull DISCOVERY "llms-full.txt" BONUS "$_code" "full corpus, one fetch" 0 0
    fi
  fi

  # --- CONTENT -------------------------------------------------------------
  _out="$(pick_page "$BASE")"
  PAGE="${_out%|*}"; PAGE_HOW="${_out#*|}"

  _sz="$(html_size "$PAGE")"
  HTML_BYTES="$(echo "$_sz" | cut -f1)"; HTML_METHOD="$(echo "$_sz" | cut -f2)"

  _pids=""
  probe md  "${PAGE}.md"                        & _pids="$_pids $!"
  probe neg "$PAGE" -H 'Accept: text/markdown'  & _pids="$_pids $!"
  wait $_pids

  _code="$(f md 1)"; MD_BYTES="$(f md 2)"; _ct="$(lower "$(f md 3)")"
  _md_ok=0
  if [ "$_code" = "200" ] && ! body_is_stub md && ! looks_like_control md; then
    case "$_ct" in
      *text/markdown*) _md_ok=1 ;;
      *text/plain*)    head -c 200 "$TMP/md.body" | grep -qE '^[[:space:]]*[#>]' && _md_ok=1 ;;
    esac
  fi
  if [ "$_md_ok" -eq 1 ] && [ "${HTML_BYTES:-0}" -gt 0 ]; then
    awk -v m="$MD_BYTES" -v h="$HTML_BYTES" 'BEGIN{ exit !(m < h*0.6) }' || _md_ok=0
  fi
  if [ "$_md_ok" -eq 1 ]; then
    add md CONTENT "<page>.md" PASS "$_code" "$(comma "$MD_BYTES") B of markdown" 25 25
  elif [ "$_code" = "200" ] && body_is_stub md; then
    add md CONTENT "<page>.md" MISS "$_code" "redirect stub, not content" 0 25
    MD_BYTES=0
  else
    add md CONTENT "<page>.md" MISS "$_code" "no markdown for this page" 0 25
    MD_BYTES=0
  fi

  case "$(lower "$(f neg 3)")" in
    *text/markdown*|*text/plain*)
      add neg CONTENT "Accept: text/markdown" PASS "$(f neg 1)" "honors content negotiation" 5 5 ;;
    *)
      add neg CONTENT "Accept: text/markdown" MISS "$(f neg 1)" "returns HTML regardless" 0 5 ;;
  esac

  # --- CONTRACT ------------------------------------------------------------
  # Pass on EITHER a reachable spec or a populated api-catalog. ElevenLabs
  # 401-gates openapi.json and ships an empty linkset, so it legitimately
  # fails this layer and still scores an A. That is the honest result.
  _spec_ok=0; _spec_detail=""
  _code="$(f openapi 1)"; _ct="$(lower "$(f openapi 3)")"
  if [ "$_code" = "200" ] && ! looks_like_control openapi; then
    case "$_ct" in
      *json*|*yaml*) _spec_ok=1; _spec_detail="/openapi.json" ;;
    esac
  fi

  _ncat=0
  if [ "$(f catalog 1)" = "200" ]; then
    if have_jq; then
      _ncat="$(jq -r '.linkset | length' < "$TMP/catalog.body" 2>/dev/null || echo 0)"
    else
      _ncat="$(grep -o '"anchor"' < "$TMP/catalog.body" 2>/dev/null | wc -l | tr -d ' ')"
    fi
  fi
  if [ "${_ncat:-0}" -ge 1 ]; then
    _spec_ok=1
    [ -z "$_spec_detail" ] && _spec_detail="api-catalog"
  fi

  if [ "$_spec_ok" -eq 1 ]; then
    add spec CONTRACT "machine-readable spec" PASS "$_code" "${_spec_detail}" 10 10
  else
    _why="not discoverable"
    if [ "$(f catalog 1)" = "200" ] && [ "${_ncat:-0}" -eq 0 ]; then _why="api-catalog linkset is empty"; fi
    # The status code shown on this row is openapi's, so if that is the more
    # specific failure let it win the explanation.
    case "$_code" in 401|403) _why="openapi.json is auth-gated" ;; esac
    add spec CONTRACT "machine-readable spec" MISS "$_code" "$_why" 0 10
  fi

  if [ "${_ncat:-0}" -ge 1 ]; then
    add catalog CONTRACT ".well-known/api-catalog" BONUS "$(f catalog 1)" "RFC 9727 - $_ncat services" 0 0
  else
    add catalog CONTRACT ".well-known/api-catalog" SKIP "$(f catalog 1)" "absent or empty" 0 0
  fi

  # --- INTERFACE -----------------------------------------------------------
  _code="$(f mcp 1)"; _ct="$(lower "$(f mcp 3)")"
  _mcp_ok=0
  case "$_ct" in *json*) [ "$_code" = "200" ] && ! looks_like_control mcp && _mcp_ok=1 ;; esac
  if [ "$_mcp_ok" -eq 0 ]; then
    for alt in /mcp /api/mcp; do
      probe mcpalt "$BASE$alt"
      case "$(lower "$(f mcpalt 3)")" in
        *json*) if [ "$(f mcpalt 1)" = "200" ]; then _mcp_ok=1; cp "$TMP/mcpalt.body" "$TMP/mcp.body"; _code="$(f mcpalt 1)"; break; fi ;;
      esac
    done
  fi
  if [ "$_mcp_ok" -eq 1 ]; then
    if have_jq; then
      MCP_TOOL="$(jq -r '.tools[0].name // empty' < "$TMP/mcp.body" 2>/dev/null)"
    else
      MCP_TOOL="$(sed -n 's/.*"tools":\[[[:space:]]*{"name":"\([^"]*\)".*/\1/p' < "$TMP/mcp.body" 2>/dev/null | head -1)"
    fi
    [ -z "$MCP_TOOL" ] && MCP_TOOL="server"
    add mcp INTERFACE "docs MCP server" PASS "$_code" "exposes ${MCP_TOOL}()" 20 20
  else
    add mcp INTERFACE "docs MCP server" MISS "$_code" "agents must crawl instead" 0 20
  fi

  # Soft-404 sanity: if literally everything missed but the control was a 200,
  # we cannot distinguish presence from absence. Say so; never invent an F.
  if [ "$CTRL_CODE" = "200" ] && [ "$(awk -F'\t' '$4=="PASS"' "$RES" | wc -l | tr -d ' ')" -eq 0 ]; then
    SOFT404=1
  fi
  return 0
}

# ---------------------------------------------------------------------------
# Offline replay — read a cached snapshot into the same TSV
# ---------------------------------------------------------------------------
slug_for() { echo "$1" | sed 's|^https\{0,1\}://||; s|/|__|g; s|__*$||'; }

SNAP=""
load_snapshot() {
  _slug="$(slug_for "$1")"
  _dir="$DEMO_DIR/fixtures/snapshots/$_slug"
  [ -f "$_dir/results.tsv" ] || return 1
  cp "$_dir/results.tsv" "$RES"
  SNAP="$_dir"
  BASE="$(sed -n 's/^base=//p'    "$_dir/meta" 2>/dev/null)"; BASE_HOW="cached"
  PAGE="$(sed -n 's/^page=//p'    "$_dir/meta" 2>/dev/null)"; PAGE_HOW="cached"
  HTML_BYTES="$(sed -n 's/^html=//p' "$_dir/meta" 2>/dev/null)"
  MD_BYTES="$(sed -n 's/^md=//p'     "$_dir/meta" 2>/dev/null)"
  MCP_TOOL="$(sed -n 's/^mcptool=//p' "$_dir/meta" 2>/dev/null)"
  SNAP_DATE="$(sed -n 's/^date=//p'   "$_dir/meta" 2>/dev/null)"
  LIVE=0
  return 0
}

# ---------------------------------------------------------------------------
# Scoring
# ---------------------------------------------------------------------------
compute_score() {
  SCORE="$(awk -F'\t' '{s+=$7} END{print s+0}' "$RES")"
  if   [ "$SCORE" -ge 85 ]; then GRADE=A
  elif [ "$SCORE" -ge 70 ]; then GRADE=B
  elif [ "$SCORE" -ge 50 ]; then GRADE=C
  elif [ "$SCORE" -ge 25 ]; then GRADE=D
  else GRADE=F
  fi
  [ "$SOFT404" -eq 1 ] && GRADE="?"
  [ "$BLOCKED" -eq 1 ] && GRADE="!"
}

# Peer median, MEASURED by refresh-fixtures.sh across a checked-in list of
# public API docs. Never hardcoded — if the file is absent we simply say
# nothing rather than assert a number we have not verified.
peer_line() {
  _f="$DEMO_DIR/fixtures/baseline.tsv"
  [ -f "$_f" ] || return 1
  awk -F'\t' 'NR>1 && $2 ~ /^[0-9]+$/ {a[n++]=$2}
    END{
      if (n==0) exit 1
      for(i=0;i<n;i++) for(j=i+1;j<n;j++) if(a[j]<a[i]){t=a[i];a[i]=a[j];a[j]=t}
      m = (n%2) ? a[int(n/2)] : int((a[n/2-1]+a[n/2])/2)
      g = (m>=85)?"A":(m>=70)?"B":(m>=50)?"C":(m>=25)?"D":"F"
      printf "peer median (%d public API docs): %s (%d)", n, g, m
    }' "$_f"
}

# ---------------------------------------------------------------------------
# Rendering — fixed 74-column interior, padded on UNCOLORED width.
# Color only ever wraps fixed-width or single-character fields, so the box
# never skews. Getting this wrong is the #1 way box-drawing demos look broken.
# ---------------------------------------------------------------------------
W=74
DELAY=0.06
tick() { [ "$ANIM" -eq 1 ] && sleep "$DELAY" || true; }

# Pad/align by CHARACTER count. printf's %-*s pads by bytes, so any line
# containing "—", "≥" or "·" would come out short. ${#s} is character-aware
# under the UTF-8 locale forced at the top of this script.
rpad() { _s="$1"; _n=$(( ${2} - ${#_s} )); [ $_n -lt 0 ] && _n=0; printf '%s%*s' "$_s" "$_n" ""; }
lpad() { _s="$1"; _n=$(( ${2} - ${#_s} )); [ $_n -lt 0 ] && _n=0; printf '%*s%s' "$_n" "" "$_s"; }

rule() { printf '═%.0s' $(seq 1 "$1"); }
top()  { printf '╔'; rule $W; printf '╗\n'; }
bot()  { printf '╚'; rule $W; printf '╝\n'; }
mid()  { printf '╠'; rule $W; printf '╣\n'; }
txt()  { printf '║%s║\n' "$(rpad "$1" $W)"; }

sect() {
  _t="$1"; _fill=$(( W - 3 - ${#_t} ))
  printf '╠═ '; b; c "$BLUE"; printf '%s' "$_t"; r
  printf ' '; rule $_fill; printf '╣\n'
}

grade_glyph() {
  case "$1" in
    A) echo " ██████ :██    ██:████████:██    ██:██    ██" ;;
    B) echo "███████ :██    ██:███████ :██    ██:███████ " ;;
    C) echo " ███████:██      :██      :██      : ███████" ;;
    D) echo "███████ :██    ██:██    ██:██    ██:███████ " ;;
    F) echo "████████:██      :██████  :██      :██      " ;;
    *) echo " ██████ :██    ██:    ███ :        :    ██  " ;;
  esac
}

grade_color() {
  case "$1" in
    A|B) echo "$GREEN" ;;
    C)   echo "$AMBER" ;;
    D)   echo 208 ;;
    F)   echo "$RED" ;;
    *)   echo "$AMBER" ;;
  esac
}

render_card() {
  _gc="$(grade_color "$GRADE")"
  _npass="$(awk -F'\t' '$4=="PASS"' "$RES" | wc -l | tr -d ' ')"
  _ntot="$(awk -F'\t' '$8>0' "$RES" | wc -l | tr -d ' ')"

  top
  # header
  if [ "$LIVE" -eq 1 ]; then _mode="$(c $GREEN)● LIVE$(r)"; _modeplain="● LIVE"
  else _mode="$(c $AMBER)◈ CACHED $SNAP_DATE$(r)"; _modeplain="◈ CACHED $SNAP_DATE"; fi
  _hdr="  AGENT-READINESS SCORECARD"
  _pad=$(( W - ${#_hdr} - ${#_modeplain} - 2 ))
  printf '║'; b; printf '%s' "$_hdr"; r
  printf '%*s' "$_pad" ""
  printf '%s' "$_mode"; printf '  ║\n'
  txt "  $BASE"
  [ "$BASE_HOW" = "auto" ] && txt "  (base path auto-detected)"
  tick

  mid
  txt ""
  # grade block
  _i=1
  echo "$(grade_glyph "$GRADE")" | tr ':' '\n' | while IFS= read -r row; do
    case "$_i" in
      1) _side="$(printf '%s / %s' "$SCORE" "$MAXSCORE")" ;;
      2) _side="$(printf '%s of %s signals present' "$_npass" "$_ntot")" ;;
      3) _side="$(peer_line 2>/dev/null || echo '')" ;;
      *) _side="" ;;
    esac
    printf '║     '; c "$_gc"; b; printf '%-8s' "$row"; r
    printf '     '; b; printf '%-*s' "$(( W - 5 - 8 - 5 ))" "$_side"; r; printf '║\n'
    _i=$((_i+1))
  done
  txt ""
  tick

  # check rows, grouped by layer
  for layer in DISCOVERY CONTENT CONTRACT INTERFACE; do
    awk -F'\t' -v L="$layer" '$2==L' "$RES" > "$TMP/layer.tsv"
    [ -s "$TMP/layer.tsv" ] || continue
    sect "$layer"
    while IFS="$(printf '\t')" read -r key lay label status code detail pts max; do
      case "$status" in
        PASS)  _ic="$(c $GREEN)✔$(r)"; _pt="+$pts" ;;
        MISS)  _ic="$(c $RED)✘$(r)";   _pt="0" ;;
        BONUS) _ic="$(c $BLUE)★$(r)";  _pt="bonus" ;;
        *)     _ic="$(c $GRAY)·$(r)";  _pt="-" ;;
      esac
      [ "$LIVE" -eq 0 ] && _ic="$(c $GRAY)⟲$(r)"
      # 2 + icon(1) + 2 + 24 + 1 + 5 + 1 + 30 + 1 + 6 + 1 = 74
      printf '║  %s  %s %s %s %s ║\n' "$_ic" \
        "$(rpad "$(trunc "$label" 24)" 24)" \
        "$(rpad "$code" 5)" \
        "$(rpad "$(trunc "$detail" 30)" 30)" \
        "$(lpad "$_pt" 6)"
      tick
    done < "$TMP/layer.tsv"
  done

  # payload block
  if [ "${HTML_BYTES:-0}" -gt 0 ] && [ "${MD_BYTES:-0}" -gt 0 ]; then
    mid
    _p="$(echo "$PAGE" | sed 's|^https\{0,1\}://[^/]*||')"
    [ ${#_p} -gt 58 ] && _p="$(echo "$_p" | cut -c1-55)..."
    printf '║  '; b; printf 'PAYLOAD'; r; printf '  %-*s║\n' "$(( W - 11 ))" "$_p"

    _hb=40
    _mb="$(awk -v m="$MD_BYTES" -v h="$HTML_BYTES" 'BEGIN{ v=int(40*m/h + 0.5); print (v<1?1:v) }')"
    _hbar="$(printf '█%.0s' $(seq 1 $_hb))"
    _mbar="$(printf '█%.0s' $(seq 1 $_mb))"
    _htok="$(human_tokens "$(est_tokens "$HTML_BYTES" html)")"
    _mtok="$(human_tokens "$(est_tokens "$MD_BYTES" md)")"
    _hlabel="$(comma "$HTML_BYTES") B"
    [ "$HTML_METHOD" = "partial" ] && _hlabel="≥ $_hlabel"

    # 9 + bar(40) + 2 + 13 + 1 + 8 + 1 = 74
    printf '║   HTML  '; c "$RED";   printf '%s' "$(rpad "$_hbar" 40)"; r
    printf '  %s %s ║\n' "$(lpad "$_hlabel" 13)" "$(lpad "$_htok" 8)"
    tick
    printf '║   MD    '; c "$GREEN"; printf '%s' "$(rpad "$_mbar" 40)"; r
    printf '  %s %s ║\n' "$(lpad "$(comma "$MD_BYTES") B" 13)" "$(lpad "$_mtok" 8)"
    tick

    _pct="$(awk -v m="$MD_BYTES" -v h="$HTML_BYTES" 'BEGIN{printf "%.1f", (1-m/h)*100}')"
    _x="$(awk -v m="$MD_BYTES" -v h="$HTML_BYTES" 'BEGIN{printf "%.0f", h/m}')"
    _atleast=""; [ "$HTML_METHOD" = "partial" ] && _atleast="at least "
    _sum="$(printf '%s%s%% smaller  ·  %sx less for a model to read' "$_atleast" "$_pct" "$_x")"
    _lp=$(( (W - ${#_sum}) / 2 ))
    printf '║%*s' "$_lp" ""; b; c "$GREEN"; printf '%s' "$_sum"; r
    printf '%*s║\n' "$(( W - _lp - ${#_sum} ))" ""
  fi

  # footer
  mid
  if [ "$BLOCKED" -eq 1 ]; then
    txt "  SITE BLOCKS AUTOMATED REQUESTS (HTTP $CTRL_CODE)"
    txt "  That is itself a finding — agents get blocked the same way."
  elif [ "$SOFT404" -eq 1 ]; then
    txt "  This site returns 200 for every path, including paths that cannot"
    txt "  exist. Presence cannot be distinguished from absence — results are"
    txt "  unreliable, so no grade is given."
  elif [ "$GRADE" = "A" ]; then
    txt "  ALREADY AGENT-READY — this is the top few percent."
    txt ""
    txt "  Worth asking next: is the SDK generated from this same spec, or"
    txt "  hand-maintained alongside it?"
  else
    printf '║  '; b; printf 'TOP 3 WINS'; r; printf '%*s║\n' "$(( W - 12 ))" ""
    _n=1
    awk -F'\t' '$4=="MISS" && $8>0 {print $8"\t"$3}' "$RES" | sort -rn | head -3 | \
    while IFS="$(printf '\t')" read -r mx lbl; do
      case "$lbl" in
        "<page>.md")             _fix="serve markdown at <page>.md" ;;
        "llms.txt")              _fix="publish /llms.txt as an agent index" ;;
        "docs MCP server")       _fix="expose a docs MCP server" ;;
        "machine-readable spec") _fix="publish OpenAPI + .well-known/api-catalog" ;;
        "Accept: text/markdown") _fix="honor Accept: text/markdown" ;;
        "sitemap.xml")           _fix="publish a sitemap.xml" ;;
        *)                       _fix="fix $lbl" ;;
      esac
      # 3 + 3 + 60 + 1 + 6 + 1 = 74
      printf '║   %s %s %s ║\n' "$_n." "$(rpad "$(trunc "$_fix" 60)" 60)" "$(lpad "+$mx" 6)"
      _n=$((_n+1))
      tick
    done
    txt ""
    txt "  Fern generates all three from one spec  ->  buildwithfern.com"
  fi
  bot

  if [ "$LIVE" -eq 1 ]; then
    printf '  '; c "$GRAY"
    printf 'byte counts are exact; token counts are a chars-per-token estimate (±15%%)\n'
    r
  fi
}

render_json() {
  printf '{\n  "target": "%s",\n  "base": "%s",\n  "page": "%s",\n' "$TARGET_URL" "$BASE" "$PAGE"
  printf '  "score": %s,\n  "grade": "%s",\n  "live": %s,\n' "$SCORE" "$GRADE" "$LIVE"
  printf '  "html_bytes": %s,\n  "md_bytes": %s,\n' "${HTML_BYTES:-0}" "${MD_BYTES:-0}"
  printf '  "checks": [\n'
  awk -F'\t' '{
    printf "    {\"key\":\"%s\",\"layer\":\"%s\",\"label\":\"%s\",\"status\":\"%s\",\"code\":\"%s\",\"detail\":\"%s\",\"points\":%s,\"max\":%s}%s\n",
      $1,$2,$3,$4,$5,$6,$7,$8, (NR==n?"":",")
  }' n="$(wc -l < "$RES" | tr -d ' ')" "$RES"
  printf '  ]\n}\n'
}

# ---------------------------------------------------------------------------
# Go
# ---------------------------------------------------------------------------
audit_one() {
  TARGET_URL="$(normalize "$1")"
  : > "$RES"
  SCORE=0; BLOCKED=0; SOFT404=0; LIVE=1; MCP_TOOL=""
  HTML_BYTES=0; MD_BYTES=0; SNAP_DATE=""

  _online=1
  if [ "$MODE" = "offline" ]; then
    _online=0
  elif [ "$MODE" = "auto" ]; then
    curl -sSf -m 3 -o /dev/null -A "$UA" "https://elevenlabs.io/docs/llms.txt" 2>/dev/null || _online=0
  fi

  if [ "$_online" -eq 1 ]; then
    # The watchdog's fds MUST go to /dev/null. Otherwise its orphaned `sleep`
    # inherits stdout and holds the pipe open, so `audit.sh | head` blocks for
    # the full budget even after the audit has finished printing.
    ( sleep "$BUDGET"; kill -TERM -$$ 2>/dev/null ) >/dev/null 2>&1 </dev/null & _wd=$!
    run_live_audit; _rc=$?
    kill "$_wd" 2>/dev/null
    if [ "$_rc" -eq 2 ]; then
      if load_snapshot "$TARGET_URL"; then
        echo "  (target unreachable — replaying cached snapshot)" >&2
      else
        echo "agent-audit: cannot reach $TARGET_URL and no cached snapshot exists." >&2
        return 2
      fi
    fi
  else
    if [ "$MODE" = "live" ]; then
      echo "agent-audit: --live requested but the network is unreachable." >&2
      return 2
    fi
    if ! load_snapshot "$TARGET_URL"; then
      echo "agent-audit: offline, and no cached snapshot for $TARGET_URL." >&2
      echo "             Snapshots available:" >&2
      ls -1 "$DEMO_DIR/fixtures/snapshots" 2>/dev/null | sed 's/^/               /' >&2
      return 2
    fi
  fi

  compute_score
  if [ "$JSON" -eq 1 ]; then render_json; else echo; render_card; echo; fi
  return 0
}

audit_one "$TARGET" || exit $?
if [ -n "$COMPARE" ]; then
  audit_one "$COMPARE" || exit $?
fi
exit 0
