#!/usr/bin/env bash
set -uo pipefail

# The API You Can't Name — teardown.
#
# Safe to run when setup never ran. Never exits early on a missing artifact.
#
#   ./scripts/teardown.sh            reset for the next attendee (keeps the cache)
#   ./scripts/teardown.sh --purge    also delete the measured cache and doc pages

CONTENT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
STATE="$CONTENT_DIR/.demo-state"
MCP_JSON="$CONTENT_DIR/.mcp.json"

PURGE=0
[ "${1:-}" = "--purge" ] && PURGE=1

echo "=== The API You Can't Name — Teardown ==="
echo ""

# --- Nothing is left running ------------------------------------------------
# This demo starts no servers and no background processes. Orbit's search and
# integrate endpoints need no key, so there is nothing to revoke either.

# --- Un-register the MCP server --------------------------------------------

if [ -f "$MCP_JSON" ]; then
  rm -f "$MCP_JSON"
  echo "[OK]   Removed .mcp.json — the orbit MCP server is no longer registered here"
else
  echo "[OK]   No .mcp.json to remove"
fi

# If a previous presenter registered orbit GLOBALLY instead (via 'claude mcp
# add'), that lives in the user's own config and is not ours to delete. Say so.
if command -v claude >/dev/null 2>&1; then
  if claude mcp list 2>/dev/null | grep -qi 'orbit'; then
    echo "[WARN] 'claude mcp list' still shows orbit — that is a user- or"
    echo "       local-scope registration, not this folder's."
    echo "       Remove it yourself if you want to:  claude mcp remove orbit"
  fi
fi

# --- Generated artifacts ----------------------------------------------------

if [ ! -d "$STATE" ]; then
  echo "[OK]   No .demo-state/ — setup has not run here, nothing to clean"
elif [ "$PURGE" = "1" ]; then
  rm -rf "$STATE"
  echo "[OK]   Purged .demo-state/ — cached search, brief, raw responses, plain-text"
  echo "       renders, doc pages, scoreboard"
  echo "       Re-provision with: ./scripts/setup.sh"
else
  if [ -d "$STATE/docs" ]; then
    rm -rf "$STATE/docs"
    echo "[OK]   Removed the downloaded documentation pages (~1.2 MB)"
  else
    echo "[OK]   No downloaded documentation pages to remove"
  fi
  if [ -f "$STATE/search.json" ] || [ -f "$STATE/integrate.json" ]; then
    echo "[OK]   Kept the cached search, brief (JSON + .txt renders, raw/) and"
    echo "       scoreboard in .demo-state/"
    echo "       (the offline fallback for Act 3 — --purge deletes these too)"
  else
    echo "[WARN] No cached search/brief in .demo-state/ — Act 3 has NO offline"
    echo "       fallback until you run ./scripts/setup.sh with a network."
  fi
fi

# --- Nothing was edited in place -------------------------------------------
# Act 3 runs entirely inside a Claude Code conversation. No repo file is
# modified during the talk, so there is nothing to git-checkout.

echo ""
echo "=== Teardown complete. ==="
echo "Between attendees: reset the deck to slide 1 and clear the Claude Code"
echo "session (/clear) so the search runs fresh."
echo "Next session:  ./scripts/setup.sh"
