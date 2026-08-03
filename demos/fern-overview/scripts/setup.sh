#!/usr/bin/env bash
set -euo pipefail

DEMO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DECK="$DEMO_DIR/presentation/index.html"
STATE="$DEMO_DIR/.demo-state"
PROOF_URL="https://elevenlabs.io/docs"

echo "=== Fern Overview — Booth Demo Setup ==="
echo ""

# 1. Verify the deck exists and is not empty
if [ -s "$DECK" ]; then
  SLIDES=$(grep -c 'class="slide ' "$DECK" || true)
  echo "[OK]   Presentation found — ${SLIDES} slides"
else
  echo "[FAIL] presentation/index.html is missing or empty"
  exit 1
fi

# 2. Find a browser opener
if command -v open >/dev/null 2>&1; then
  OPENER="open"
elif command -v xdg-open >/dev/null 2>&1; then
  OPENER="xdg-open"
else
  OPENER=""
  echo "[WARN] No browser opener found (open / xdg-open)."
  echo "       Open this file manually:  $DECK"
fi
[ -n "$OPENER" ] && echo "[OK]   Browser opener: $OPENER"

# 3. Probe the Act 5 proof point. Never fail the setup on this — a booth
#    with dead wifi should still get a working deck.
if command -v curl >/dev/null 2>&1; then
  if curl -sS -o /dev/null -m 8 -w '' "$PROOF_URL" 2>/dev/null; then
    echo "[OK]   Reachable: $PROOF_URL (live payoff in Act 5 will work)"
  else
    echo "[WARN] Could not reach $PROOF_URL"
    echo "       Network is down or slow. Skip the browser payoff in Act 5,"
    echo "       or use pre-captured screenshots. See README Troubleshooting."
  fi
else
  echo "[WARN] curl not installed — skipped the network probe."
fi

# 4. Mark the demo as set up
date +"%Y-%m-%dT%H:%M:%S%z" > "$STATE"
echo "[OK]   Wrote .demo-state"

# 5. Open the deck last, so the presenter is ready
if [ -n "$OPENER" ]; then
  echo ""
  echo "Opening presentation..."
  "$OPENER" "$DECK" >/dev/null 2>&1 || echo "[WARN] Could not open the browser automatically."
fi

cat <<'EOF'

=== Setup complete. Ready to present. ===

Pre-demo checklist:
  [ ] Deck is open on slide 1 of 10
  [ ] Browser is full-screen (Cmd+Ctrl+F on macOS Chrome)
  [ ] Arrow keys advance and go back — test both once
  [ ] Second tab open on https://elevenlabs.io/docs, scrolled to an API reference page
  [ ] Third tab open on that same page with .md appended
  [ ] Display mirrored, brightness up, notifications silenced
  [ ] You can say slide 2's numbers without reading: 74% / 2,650 / 33% by 2028, up from 1%
EOF
