#!/usr/bin/env bash
set -uo pipefail

DEMO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# shellcheck disable=SC1090
[ -f "$DEMO_DIR/demo.conf" ] && . "$DEMO_DIR/demo.conf"
MCP_NAME="${MCP_NAME:-elevenlabs-docs}"

echo "=== Agent-Ready Docs — Teardown ==="
echo ""

# 1. The MCP server the presenter added on stage.
#    `claude mcp add -s project` writes ./.mcp.json in this folder. Remove it
#    so the next attendee sees the same clean `claude mcp add` moment, and so
#    the repo is never left dirty.
cd "$DEMO_DIR" || exit 1
if [ -f "$DEMO_DIR/.mcp.json" ]; then
  claude mcp remove -s project "$MCP_NAME" >/dev/null 2>&1
  rm -f "$DEMO_DIR/.mcp.json"
  echo "[OK]   Removed .mcp.json (project-scoped MCP server)"
else
  echo "[OK]   No .mcp.json to remove — already clean"
fi

# 2. Anything setup.sh left behind mid-run.
rm -f "$DEMO_DIR/.mcp.dryrun.json" "$DEMO_DIR/.mcp.offline.json"
echo "[OK]   Removed dry-run configs"

# 3. Confirm we did not touch the global config. The demo deliberately uses
#    project scope precisely so this stays true — worth verifying, because
#    silently accumulating servers in ~/.claude.json across a conference is
#    exactly the kind of thing nobody notices until it breaks something else.
if command -v claude >/dev/null 2>&1; then
  if claude mcp list 2>/dev/null | grep -q "^${MCP_NAME}:"; then
    echo "[WARN] '$MCP_NAME' is STILL configured outside this project."
    echo "       It was probably added without -s project. Remove it with:"
    echo "         claude mcp remove $MCP_NAME"
  else
    echo "[OK]   Global MCP config is clean — '$MCP_NAME' is not registered"
  fi
fi

# 4. Fixtures are deliberately KEPT. They are recorded artifacts, they take a
#    minute to rebuild, and they are what makes the demo survive dead wifi.
#    Use ./scripts/refresh-fixtures.sh to re-record them.
if [ -d "$DEMO_DIR/fixtures" ]; then
  NSNAP=$(ls -1 "$DEMO_DIR/fixtures/snapshots" 2>/dev/null | wc -l | tr -d ' ')
  NCORP=$(ls -1 "$DEMO_DIR/fixtures/corpus/elevenlabs"/*.md 2>/dev/null | wc -l | tr -d ' ')
  echo "[OK]   Kept fixtures ($NSNAP snapshots, $NCORP cached pages) — run refresh-fixtures.sh to re-record"
fi

echo ""
echo "=== Teardown complete. Run ./scripts/setup.sh for the next attendee. ==="
echo ""
echo "Nothing in this demo runs in the cloud, so there is no remote state to"
echo "clean up — no collections, no mock servers, no API keys."
