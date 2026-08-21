#!/usr/bin/env bash
set -uo pipefail

DEMO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORKSPACE="$DEMO_DIR/workspace"

# --purge also deletes the provisioned authoring workspace; default keeps it
# (re-cloning at a booth is slow) and just resets the live edits.
PURGE=0
[ "${1:-}" = "--purge" ] && PURGE=1

echo "=== Fern Overview — Teardown ==="
echo ""

# The deck itself has no state — it runs nothing and touches no cloud resources.
echo "[OK]   Deck: nothing to clean up (no files, keys, or cloud state)."

if [ -f "$DEMO_DIR/presentation/index.html" ]; then
  echo "[OK]   Deck still present at presentation/index.html"
else
  echo "[WARN] Deck is missing from presentation/index.html — restore it from git before the next run."
fi

# --- Stop the live preview (slide-6 Path B leaves a running process) ---------
# `fern docs dev` keeps a dev server alive on a port until it's killed. Actually
# stop it here rather than just reminding — a proper reset shouldn't depend on
# the presenter remembering Ctrl-C.
PIDS="$(pgrep -f 'fern docs dev' 2>/dev/null || true)"
if [ -n "$PIDS" ]; then
  # shellcheck disable=SC2086
  kill $PIDS 2>/dev/null
  sleep 1
  # escalate if any survived
  STILL="$(pgrep -f 'fern docs dev' 2>/dev/null || true)"
  # shellcheck disable=SC2086
  [ -n "$STILL" ] && kill -9 $STILL 2>/dev/null
  echo "[OK]   Stopped the 'fern docs dev' preview (pids: $(echo $PIDS | tr '\n' ' '))"
else
  echo "[OK]   No 'fern docs dev' preview running"
fi

# --- Reset the provisioned authoring workspace ------------------------------
# The deep-dive leaves state: edits Claude Code made to the docs-starter, plus
# whatever fern docs dev built. Reset (or purge) both starters.
if [ -d "$WORKSPACE" ]; then
  if [ "$PURGE" -eq 1 ]; then
    rm -rf "$WORKSPACE"
    echo "[OK]   Purged the authoring workspace (re-provision with ./scripts/setup.sh --authoring)"
  else
    for starter in docs-starter sdk-starter; do
      _dir="$WORKSPACE/$starter"
      [ -d "$_dir/.git" ] || continue
      # Reset tracked edits everywhere; clean only NEW files under fern/ (a page
      # Claude Code may have created). Never touch the root-level skill artifacts
      # (.claude, .agents, skills-lock.json) — those are the installed skills.
      ( cd "$_dir" && git checkout -q -- . && git clean -qfd fern/ 2>/dev/null )
      echo "[OK]   Reset live edits in workspace/$starter (kept the repo + installed skills)"
    done
    # Drop build caches the preview may have written, so the next run rebuilds clean.
    rm -rf "$WORKSPACE/docs-starter/.fern" "$WORKSPACE/docs-starter/.preview" 2>/dev/null
  fi
else
  echo "[OK]   No authoring workspace to reset (deck-only run)."
fi

echo ""
echo "For the next attendee:"
echo "  • Scroll the deck back to the top (slide 1), or re-run ./scripts/setup.sh."
if [ -d "$WORKSPACE/docs-starter/.git" ]; then
  echo "  • Path A (Fern Editor) edits live in YOUR cloud project — undo them there; a login"
  echo "    can't be scripted, so this is the one manual step."
fi
echo ""
echo "=== Teardown complete. ==="
