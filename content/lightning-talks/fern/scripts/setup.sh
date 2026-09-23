#!/usr/bin/env bash
set -uo pipefail

DEMO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DECK="$DEMO_DIR/presentation/index.html"
WORKSPACE="$DEMO_DIR/workspace"

# --authoring provisions the live-authoring deep-dive (slide 6): clones Fern's
# docs-starter and sdk-starter and installs the official Fern agent skills, so
# you can edit a real Fern repo with Claude Code on stage. Without the flag,
# setup just validates and opens the deck — the fast, offline path.
WITH_AUTHORING=0
[ "${1:-}" = "--authoring" ] && WITH_AUTHORING=1

echo "=== Fern Overview — Booth Demo Setup ==="
echo ""

# --- The deck (always) ------------------------------------------------------

# This demo is slide-forward. The deck is a single self-contained HTML file:
# nothing to install, no key, no network. Setup fails loudly if it's missing.

if [ ! -f "$DECK" ]; then
  echo "[FAIL] Presentation not found at $DECK"
  echo "       This demo ships the deck at presentation/index.html — restore it from git."
  exit 1
fi
echo "[OK]   Deck found: presentation/index.html"

if head -c 64 "$DECK" | grep -qi '<!doctype html' && grep -q '</html>' "$DECK"; then
  SIZE="$(ls -lh "$DECK" | awk '{print $5}')"
  echo "[OK]   Deck looks well-formed (${SIZE}, opens and closes cleanly)"
else
  echo "[FAIL] Deck is present but does not look like a complete HTML file."
  echo "       Restore presentation/index.html from git."
  exit 1
fi

if grep -qoE '(src|href)="https?://' "$DECK"; then
  echo "[WARN] Deck references external URLs — it may not render fully offline."
else
  echo "[OK]   Deck is fully self-contained (no external assets — works offline)"
fi

# --- Optional: provision the live-authoring deep-dive (slide 6) --------------

if [ "$WITH_AUTHORING" -eq 1 ]; then
  echo ""
  echo "--- Provisioning the live-authoring deep-dive (slide 6) ---"

  # Tools this beat needs. Fail clearly rather than half-provision.
  MISSING=0
  for tool in git node npx fern; do
    if command -v "$tool" >/dev/null 2>&1; then
      echo "[OK]   $tool present"
    else
      echo "[FAIL] $tool not found — needed for the authoring deep-dive."
      MISSING=1
    fi
  done
  if [ "$MISSING" -eq 1 ]; then
    echo "       Install the missing tools, then re-run: ./scripts/setup.sh --authoring"
    echo "       Fern CLI:  npm install -g fern-api   (or: brew install fern-api/tap/fern)"
    exit 1
  fi

  if ! curl -sSf -m 5 -o /dev/null https://github.com 2>/dev/null; then
    echo "[FAIL] No network — the starters and skills are cloned from GitHub."
    echo "       Provision this at the hotel the night before, not at the booth."
    exit 1
  fi

  mkdir -p "$WORKSPACE"

  # Clone (or refresh) the two official Fern starters, shallow.
  clone_or_pull() {
    _name="$1"; _url="$2"; _dir="$WORKSPACE/$_name"
    if [ -d "$_dir/.git" ]; then
      ( cd "$_dir" && git pull --ff-only -q ) 2>/dev/null \
        && echo "[OK]   $_name up to date" \
        || echo "[WARN] $_name present but could not fast-forward — using existing checkout"
    else
      rm -rf "$_dir"
      if git clone --depth 1 -q "$_url" "$_dir"; then
        echo "[OK]   Cloned $_name"
      else
        echo "[FAIL] Could not clone $_url"; exit 1
      fi
    fi
  }
  clone_or_pull docs-starter https://github.com/fern-api/docs-starter.git
  clone_or_pull sdk-starter  https://github.com/fern-api/sdk-starter.git

  # Install the official Fern agent skills INTO the docs-starter, so Claude Code
  # picks up the fern-docs skill when you open that folder on stage.
  echo "Installing Fern agent skills (fern-api/skills) into docs-starter..."
  if ( cd "$WORKSPACE/docs-starter" && npx -y skills@latest add fern-api/skills --all >/tmp/fern-skills.log 2>&1 ); then
    INSTALLED="$(ls "$WORKSPACE/docs-starter/.claude/skills" 2>/dev/null | tr '\n' ' ')"
    echo "[OK]   Skills installed into docs-starter/.claude/skills: ${INSTALLED:-none listed}"
  else
    echo "[WARN] Skill install reported an error — see /tmp/fern-skills.log"
    echo "       You can still edit the repo with Claude Code; you just won't have the fern-docs skill."
  fi

  # Validate the docs project so the live preview can't fail on stage.
  if ( cd "$WORKSPACE/docs-starter" && fern check >/tmp/fern-check.log 2>&1 ); then
    echo "[OK]   docs-starter passes 'fern check' — the live preview will build"
  else
    echo "[WARN] 'fern check' reported issues — see /tmp/fern-check.log"
  fi

  echo ""
  echo "[OK]   Authoring workspace ready at content/lightning-talks/fern/workspace/ (gitignored)"
fi

# --- Open the deck (always, last) -------------------------------------------

echo ""
echo "Opening presentation in browser..."
open "$DECK" 2>/dev/null \
  || xdg-open "$DECK" 2>/dev/null \
  || echo "[WARN] Could not open browser automatically. Open presentation/index.html manually."

echo ""
echo "=== Setup complete. Ready to present. ==="
echo ""
echo "How the deck works:"
echo "  • Scroll down / up to move between slides (this is a scroll deck)."
echo "  • Press 't' to toggle light / dark theme — match the booth lighting."
echo "  • Put the browser in fullscreen (Cmd+Ctrl+F on macOS) before attendees arrive."

if [ "$WITH_AUTHORING" -eq 1 ]; then
  echo ""
  echo "Live-authoring deep-dive (slide 6) — two authoring surfaces, one project:"
  echo "  A) Fern Editor (browser): log into your project at https://dashboard.buildwithfern.com"
  echo "     and open the Editor. This is a MANUAL login — use your own Fern project."
  echo "  B) The repo + Claude Code:"
  echo "       cd content/lightning-talks/fern/workspace/docs-starter"
  echo "       fern docs dev          # live preview at http://localhost:3000"
  echo "       claude                 # then ask it to make an edit — it will use the fern-docs skill"
fi

echo ""
echo "Pre-demo checklist:"
echo "  [ ] Deck open and in FULLSCREEN on the booth monitor, scrolled to the top (slide 1)"
echo "  [ ] Theme ('t') set to match booth lighting"
echo "  [ ] Browser zoom set so text is readable from 6 feet (Cmd+= / Cmd+-)"
echo "  [ ] Scrolling moves one clean slide at a time (trackpad/mouse wheel tested)"
echo "  [ ] You have skimmed the talk track in README.md and know the four proof stats"
if [ "$WITH_AUTHORING" -eq 1 ]; then
  echo "  [ ] Logged into your Fern project in the dashboard, Fern Editor open on a page"
  echo "  [ ] 'fern docs dev' preview running and reachable at http://localhost:3000"
  echo "  [ ] Claude Code open in workspace/docs-starter; 'fern-docs' skill present"
  echo "  [ ] You have picked the ONE edit you'll make live (e.g. a line on the welcome page)"
fi
