#!/usr/bin/env bash
set -uo pipefail

# Make MCPs Your Documentation Best Friend — teardown.
#
# The demo creates state in four places. This script resets three of them and
# DELIBERATELY LEAVES THE FOURTH:
#
#   claude MCP registration  -> removed, so Act 7f is a first-time connect again
#   /tmp build folders       -> removed
#   the local portal server  -> stopped
#   the published Fern site  -> LEFT ALONE, on purpose. See below.
#
# Why the site stays: a Fern subdomain that has already published has a search
# index, and Act 7f depends on that index being warm. Unpublishing between runs
# would hand every run the slow, unreliable first-publish path. Republishing
# over a warm subdomain is the whole reason this talk is safe to give twice.
#
# There is no GitHub state to clean up — the demo never creates a repository.
# There are no API calls to undo — the spec is a document, the service is never
# called, and the portal's "Try it" panel is mocked.
#
# NEVER DELETE THE FERN ORGANIZATION TO RESET THIS DEMO. `postman-devrel` is the
# DevRel team's shared organization, and it also publishes the REAL MyHealthcare
# documentation at myhealthcare.docs.buildwithfern.com — this talk's warm
# fallback. Deleting an organization leaves your account belonging to none, and
# every later `fern generate --docs` dies with a 500 "Failed to resolve
# organization" that takes real detective work to diagnose. It has happened
# once. There is nothing to reset up there: the org is permanent, the demo site
# lives inside it, and republishing over the same subdomain IS the reset.
#
#   --purge       also delete site/assets/spec-bundle.js (setup rebuilds it)
#   PORT          portal port            (default 4173)
#   FERN_HANDLE   docs subdomain label   (default booth-demo)
#   WORKDIR       Acts 7a-7e folder      (default /tmp/appointments-docs)
#   AGENTDIR      Act 7f folder          (default /tmp/appointments-agent)

DEMO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SITE="$DEMO_DIR/site"
STATE="$DEMO_DIR/.demo-state"

PORT="${PORT:-4173}"
FERN_HANDLE="${FERN_HANDLE:-booth-demo}"
WORKDIR="${WORKDIR:-/tmp/appointments-docs}"
AGENTDIR="${AGENTDIR:-/tmp/appointments-agent}"
DOCS="https://$FERN_HANDLE.docs.buildwithfern.com"
MCP="$DOCS/_mcp/server"   # registrations are matched by THIS, not by name

PURGE=0
[ "${1:-}" = "--purge" ] && PURGE=1

echo "=== Make MCPs Your Documentation Best Friend — Teardown ==="
echo ""

# --- The MCP registration, FIRST --------------------------------------------
# ORDER MATTERS, and it is the reason this section comes before the folders.
#
# `claude mcp add` defaults to --scope local, which keys the registration to the
# directory it was run in and stores it in ~/.claude.json — NOT inside the
# folder. `claude mcp remove` is scoped the same way, so it has to run from that
# same directory. Delete the folder first and there is nowhere to run the
# removal from: the entry survives, orphaned, setup.sh recreates the path, the
# stale entry comes back with it, and Act 7f opens with `claude mcp add` erroring
# on a duplicate name in front of the audience.
#
# Match by URL, not by name. This one server gets registered under at least
# three different names depending on whether the presenter used this talk's
# command, the docs site's UI snippet, or the command in /_mcp/server's usage
# field. A name-based removal leaves the other two behind.
#
# /private/tmp is in the search list because a --scope local registration made
# there is inherited by every /tmp/* folder, AGENTDIR included. Leave it and Act
# 7f is never a first-time connect again. Only registrations pointing at THIS
# demo's own MCP URL are touched.

if command -v claude >/dev/null 2>&1; then
  REMOVED=0
  for d in "$AGENTDIR" "$WORKDIR" /private/tmp /tmp; do
    [ -d "$d" ] || continue
    LINE="$( cd "$d" && claude mcp list 2>/dev/null | grep -F "$MCP" | head -1 )"
    [ -n "$LINE" ] || continue
    NAME="$(echo "$LINE" | cut -d: -f1 | tr -d ' ')"
    [ -n "$NAME" ] || continue
    if ( cd "$d" && claude mcp remove "$NAME" >/dev/null 2>&1 ); then
      echo "[OK]   Unregistered '$NAME' -> $MCP (local scope, in $d)"
      REMOVED=1
    else
      echo "[WARN] Could not remove '$NAME' in $d — run: cd $d && claude mcp remove $NAME"
    fi
  done
  [ "$REMOVED" -eq 0 ] && echo "[OK]   No registration for $MCP found"
else
  echo "[WARN] claude CLI not found — remove the docs MCP server by hand"
fi

# --- The build folders, SECOND ----------------------------------------------
# Removed rather than emptied: setup.sh recreates WORKDIR with exactly one file
# and AGENTDIR with none, and both of those are said out loud on stage.

if [ -d "$WORKDIR" ]; then
  rm -rf "$WORKDIR"
  echo "[OK]   Removed $WORKDIR (setup.sh recreates it with just the spec)"
else
  echo "[OK]   No $WORKDIR to remove"
fi

if [ -d "$AGENTDIR" ]; then
  rm -rf "$AGENTDIR"
  echo "[OK]   Removed $AGENTDIR (setup.sh recreates it empty)"
else
  echo "[OK]   No $AGENTDIR to remove"
fi

# --- The portal server ------------------------------------------------------
# By pid first, then by port — so a server someone started by hand is caught
# too, and Act 0 does not silently reuse a stale one on the next run.

if [ -f "$STATE" ]; then
  PID="$(cat "$STATE" 2>/dev/null)"
  if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
    kill "$PID" 2>/dev/null && echo "[OK]   Stopped the portal server (pid $PID)"
  else
    echo "[OK]   Recorded portal pid $PID is not running"
  fi
  rm -f "$STATE"
else
  echo "[OK]   No .demo-state file — nothing recorded to stop"
fi

STRAGGLERS="$(lsof -ti tcp:"$PORT" 2>/dev/null)"
if [ -n "$STRAGGLERS" ]; then
  echo "$STRAGGLERS" | xargs kill 2>/dev/null \
    && echo "[OK]   Freed port $PORT (pids: $(echo "$STRAGGLERS" | tr '\n' ' '))"
fi

rm -f /tmp/mcp-docs-portal.log && echo "[OK]   Removed /tmp/mcp-docs-portal.log"

if [ "$PURGE" -eq 1 ]; then
  rm -f "$SITE/assets/spec-bundle.js" \
    && echo "[OK]   --purge: removed site/assets/spec-bundle.js (setup rebuilds it)"
else
  echo "[OK]   Kept site/assets/spec-bundle.js — setup rebuilds it every run (--purge to delete)"
fi

# --- What is intentionally still standing -----------------------------------

echo ""

# Retry, for the same reason setup.sh does: one timed-out curl reports a live
# site as unpublished. Observed on 2026-09-07 — teardown said "no pages" and
# setup.sh said "11 pages" seconds later. A false warning here trains the
# presenter to ignore the verdict that actually matters.
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
  echo "[OK]   $DOCS is still published ($PAGES pages) — this is what keeps"
  echo "       Act 7f fast. Do not unpublish it between runs."
else
  echo "[WARN] $DOCS lists no pages. The next run takes the slow first-publish"
  echo "       path — do a rehearsal run before you present."
fi

echo "[OK]   No API calls were made, no credentials used, nothing to clean up"
echo "       anywhere else: the spec is a document and the service is never called"

cat <<EOF

Not a reset step, and never was: DELETING THE FERN ORGANIZATION. The org is
permanent and shared with the rest of DevRel, and it also publishes this talk's
warm fallback site. Republishing over the same subdomain is the reset.

Three things this script cannot do for you:
  1. Clear your Claude Code session. A warm context already knows the Act 7f
     answer and will reply without calling searchDocs, which is the payoff.
  2. Re-check Safari's Disable JavaScript — it survives restarts, not updates.
  3. Reset the deck to slide 1.

Then re-run ./scripts/setup.sh — it prints WARM or COLD, and that verdict is
the only thing you actually have to read before walking on.

=== Teardown complete. ===
EOF
