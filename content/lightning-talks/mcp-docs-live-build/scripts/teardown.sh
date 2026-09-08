#!/usr/bin/env bash
set -uo pipefail

# Make MCPs Your Documentation Best Friend — Live Build. Teardown.
#
# The demo creates state in three places. This script resets two of them and
# DELIBERATELY LEAVES THE THIRD:
#
#   /tmp working folder      -> removed
#   claude MCP registration  -> removed, so Act 3e is a first-time connect again
#   the published Fern site  -> LEFT ALONE, on purpose. See below.
#
# Why the site stays: a Fern subdomain that has already published has a search
# index, and Act 3e depends on that index being warm. Unpublishing between runs
# would hand every run the slow, unreliable first-publish path. Republishing
# over a warm subdomain is the whole reason this demo is safe to give twice.
#
# There is no GitHub state to clean up — the demo never creates a repository.
#
# NEVER DELETE THE FERN ORGANIZATION TO RESET THIS DEMO. `postman-devrel` is the
# DevRel team's shared organization, and it also publishes the REAL MyHealthcare
# documentation at myhealthcare.docs.buildwithfern.com.
# Deleting an organization leaves your account belonging to none, and every later
# `fern generate --docs` dies with a 500 "Failed to resolve organization" that
# takes real detective work to diagnose. It has happened once. There is nothing
# to reset up there: the org is permanent, the demo site lives inside it, and
# republishing over the same subdomain IS the reset.
#
#   FERN_HANDLE   docs subdomain label   (default booth-demo)
#   WORKDIR       Acts 3a-3c folder      (default /tmp/appointments-docs)
#   AGENTDIR      Act 3e folder          (default /tmp/appointments-agent)

FERN_HANDLE="${FERN_HANDLE:-booth-demo}"
WORKDIR="${WORKDIR:-/tmp/appointments-docs}"
AGENTDIR="${AGENTDIR:-/tmp/appointments-agent}"
DOCS="https://$FERN_HANDLE.docs.buildwithfern.com"
MCP="$DOCS/_mcp/server"   # registrations are matched by THIS, not by name

echo "=== MCP Docs Best Friend (Live Build) — Teardown ==="
echo ""

# --- The MCP registration, FIRST --------------------------------------------
# ORDER MATTERS, and it is the reason this section comes before the folders.
#
# `claude mcp add` defaults to --scope local, which keys the registration to the
# directory it was run in and stores it in ~/.claude.json — NOT inside the folder.
# `claude mcp remove` is scoped the same way, so it has to run from that same
# directory. Delete the folder first and there is nowhere to run the removal
# from: the entry survives, orphaned, setup.sh recreates the path, the stale
# entry comes back with it, and Act 3e opens with `claude mcp add` erroring on a
# duplicate name in front of the audience.

# Match by URL, not by name. This one server gets registered under at least three
# different names depending on whether the presenter used this demo's command,
# the docs site's UI snippet, or the command in /_mcp/server's usage field. A
# name-based removal leaves the other two behind, and the next run's `claude mcp
# add` then errors on stage.
#
# /private/tmp is in the search list because a --scope local registration made
# there is inherited by every /tmp/* folder, AGENTDIR included. Leave it and Act
# 3e is never a first-time connect again. Only registrations pointing at THIS
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

# --- The folders, SECOND ----------------------------------------------------
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

# --- What is intentionally still standing -----------------------------------

echo ""

# Retry, for the same reason setup.sh does: one timed-out curl reports a live
# site as unpublished. Observed on 2026-09-07 — this script said "no pages" and
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
  echo "       Act 3e fast. Do not unpublish it between runs."
else
  echo "[WARN] $DOCS lists no pages. The next run takes the slow first-publish"
  echo "       path — do a rehearsal run before you present."
fi

echo "[OK]   No API calls were made, no credentials used, nothing to clean up"
echo "       anywhere else: the spec is a document and the service is never called"

cat <<EOF

Not a reset step, and never was: DELETING THE FERN ORGANIZATION. The org is
permanent and shared with the rest of DevRel. Republishing over the same
subdomain is the reset.

Two things this script cannot do for you:
  1. Clear your Claude Code session. A warm context already knows the Act 3e
     answer and will reply without calling searchDocs, which is the payoff.
  2. Reset the deck to slide 1.

Then re-run ./scripts/setup.sh — it prints WARM or COLD, and that verdict is
the only thing you actually have to read before walking on.

=== Teardown complete. ===
EOF
