#!/usr/bin/env bash
set -uo pipefail

# Presentation in a Box — Where Agents become Teammates — setup.
#
#   ./scripts/setup.sh             # install check, login check, scaffold the agent
#   ./scripts/setup.sh --start     # ...and start it in the background
#
# Idempotent: re-running leaves the same ready state. Creates the demo agent in
# ./workspace/$AGENT_NAME (gitignored) so the repo itself is never touched.

CONTENT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DECK="$CONTENT_DIR/presentation/index.html"
WORKSPACE="$CONTENT_DIR/workspace"
STATE="$CONTENT_DIR/.demo-state"
AGENT_NAME="${AGENT_NAME:-hello-teammate}"
MODEL="${AGENT_MODEL:-gateway}"          # gateway | anthropic | openai
START=0
[ "${1:-}" = "--start" ] && START=1

echo "=== Presentation in a Box — Where Agents become Teammates — Setup ==="
echo ""

open_url() { open "$1" 2>/dev/null || xdg-open "$1" 2>/dev/null || return 1; }

# --- The deck ---------------------------------------------------------------

if [ ! -f "$DECK" ]; then
  echo "[FAIL] Presentation not found at $DECK — restore it from git."
  exit 1
fi
if head -c 64 "$DECK" | grep -qi '<!doctype html' && grep -q '</html>' "$DECK"; then
  echo "[OK]   Deck launcher found and well-formed"
else
  echo "[FAIL] Deck is present but is not a complete HTML file — restore it from git."
  exit 1
fi

# --- Tooling ----------------------------------------------------------------

if command -v ast >/dev/null 2>&1; then
  echo "[OK]   ast CLI present: $(ast --version 2>/dev/null | head -1)"
else
  echo "[FAIL] ast not found — install it:"
  echo '       curl -fsSL https://astropods.com/install | sh   # then open a new terminal'
  echo "       Docs: https://docs.astropods.com/install-cli"
  exit 1
fi

if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  echo "[OK]   Docker is running"
else
  echo "[FAIL] Docker is not installed or not running — 'ast project start' needs it."
  echo "       Start Docker Desktop, then re-run this script."
  exit 1
fi

# --- Authentication ---------------------------------------------------------

if ast whoami >/dev/null 2>&1; then
  echo "[OK]   Logged in to Astropods as: $(ast whoami 2>/dev/null | head -1)"
else
  echo "[WARN] Not logged in. Run 'ast login' (opens a browser, one-time device auth)."
  echo "       Needed for --model gateway and for blueprint push/deploy."
fi

# --- Prepare state: scaffold the first agent --------------------------------

mkdir -p "$WORKSPACE"
if [ -d "$WORKSPACE/$AGENT_NAME" ]; then
  echo "[OK]   Agent project already scaffolded at workspace/$AGENT_NAME"
else
  if ast project create "$AGENT_NAME" --model "$MODEL" --path "$WORKSPACE" --yes >/dev/null 2>&1; then
    echo "[OK]   Scaffolded workspace/$AGENT_NAME (--model $MODEL)"
  else
    echo "[FAIL] 'ast project create' failed. Try it by hand to see the error:"
    echo "       ast project create $AGENT_NAME --model $MODEL --path $WORKSPACE --yes"
    exit 1
  fi
fi
echo "$AGENT_NAME" > "$STATE"

if [ "$START" -eq 1 ]; then
  if (cd "$WORKSPACE/$AGENT_NAME" && ast project start --background); then
    echo "[OK]   Agent running in the background (ast project logs / ast project stop)"
  else
    echo "[WARN] Could not start the agent — try 'ast project start' in workspace/$AGENT_NAME."
  fi
fi

# --- Verify the network-dependent parts -------------------------------------

for url in https://docs.astropods.com/welcome https://blog.postman.com/build-ai-agents-with-astropods/; do
  if curl -sSf -m 6 -o /dev/null "$url"; then
    echo "[OK]   $url reachable"
  else
    echo "[WARN] Could not reach $url — use the recorded Loom demos instead (README section 6)."
  fi
done

# --- Open everything --------------------------------------------------------

echo ""
echo "Opening the presentation..."
open_url "$DECK" || echo "[WARN] Open presentation/index.html manually."

cat <<EOF2

=== Setup complete. Ready to present. ===

Demo agent:  $WORKSPACE/$AGENT_NAME

Pre-flight checklist:
  [ ] Deck open, FULLSCREEN, on slide 1 (Figma deck loaded, not still spinning)
  [ ] Terminal in $WORKSPACE/$AGENT_NAME, LARGE FONT
  [ ] 'ast whoami' shows you logged in
  [ ] Both Loom demos open in tabs as the offline fallback

When you are done:  ./scripts/teardown.sh
EOF2
