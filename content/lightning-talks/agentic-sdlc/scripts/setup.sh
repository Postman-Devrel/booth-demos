#!/usr/bin/env bash
set -uo pipefail

# Agentic SDLC with Context Graph and API Simulations — setup.
#
# Nothing to prepare: the demo is a recording embedded in the deck, so the talk needs no network,
# no login and no running services. This script checks the deck is intact and opens it.

CONTENT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DECK="$CONTENT_DIR/presentation/Agentic_SDLC_Conference_Talk.pptx"

echo "=== Agentic SDLC with Context Graph and API Simulations — Setup ==="
echo ""

if [ ! -f "$DECK" ]; then
  echo "[FAIL] Deck not found at $DECK — restore it from git."
  exit 1
fi
if unzip -tq "$DECK" >/dev/null 2>&1; then
  echo "[OK]   Deck found and readable ($(du -h "$DECK" | cut -f1))"
else
  echo "[FAIL] $DECK is not a valid .pptx (is the git checkout complete?) — restore it from git."
  exit 1
fi

CONTENTS="$(unzip -l "$DECK" 2>/dev/null)"
if grep -q 'ppt/media/.*\.mp4' <<<"$CONTENTS"; then
  echo "[OK]   Demo recording is embedded (slide 6)"
else
  echo "[WARN] No .mp4 found in the deck. Slide 6 should hold copilot-api-simulation.mp4."
fi

echo ""
echo "Opening the deck..."
open "$DECK" 2>/dev/null || xdg-open "$DECK" 2>/dev/null || echo "[WARN] Open presentation/Agentic_SDLC_Conference_Talk.pptx manually."

cat <<MSG

=== Setup complete. Ready to present. ===

Pre-flight checklist:
  [ ] Deck open, in presenter view, on slide 1
  [ ] Play the recording on slide 6 once so it is not cold, then go back to slide 1
  [ ] Volume and display output checked

When you are done:  ./scripts/teardown.sh
MSG
