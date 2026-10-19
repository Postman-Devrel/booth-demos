#!/usr/bin/env bash
set -uo pipefail

DEMO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== Context Graph booth demo setup ==="
echo ""
echo "The demo runs entirely from preloaded benchmark results: no network, no login."
echo ""

# 1. Deck (the demo itself)
if [ ! -f "$DEMO_DIR/presentation/index.html" ]; then
  echo "[FAIL] presentation/index.html not found"
  exit 1
fi
echo "[OK] Presentation found"

# 2. Preloaded results. Slide 3 and 4 are built from these numbers.
if [ -f "$DEMO_DIR/fixtures/benchmark.json" ]; then
  echo "[OK] fixtures/benchmark.json present (8 questions x 3 models, with and without the graph)"
else
  echo "[WARN] fixtures/benchmark.json missing. The deck still has the numbers baked in,"
  echo "       but the source data for them is gone; see README section 7."
fi
for f in api-callers http-endpoints upstream-dependencies; do
  [ -f "$DEMO_DIR/fixtures/$f.json" ] \
    && echo "[OK] fixtures/$f.json present" \
    || echo "[WARN] fixtures/$f.json missing (provenance for the graph document counts)"
done

# 3. Optional: Claude Code + Postman plugin, only needed for the optional live ask in act 4
echo ""
if command -v claude &>/dev/null && claude plugin list 2>/dev/null | grep -qi "postman"; then
  echo "[OK] Claude Code and the Postman plugin are installed (optional live ask available)"
  echo "[WARN] The ask tools have no team parameter: the optional live ask only returns benchmark-estate"
  echo "       data if the plugin is signed in to the team that owns that estate. See README section 2."
else
  echo "[WARN] Claude Code or the Postman plugin not found. Fine for the main demo;"
  echo "       you only need them for the optional live ask and the CTA."
  echo "       Install:  claude plugin install github:Postman-Devrel/postman-claude-code-plugin"
fi

# 4. Open the deck last
echo ""
echo "Opening presentation in browser..."
open "$DEMO_DIR/presentation/index.html" 2>/dev/null \
  || xdg-open "$DEMO_DIR/presentation/index.html" 2>/dev/null \
  || echo "[WARN] Could not open browser automatically. Open presentation/index.html manually."

echo ""
echo "=== Setup complete. Ready to demo. ==="
echo ""
echo "Pre-demo checklist:"
echo "  [ ] Deck full-screen on the booth monitor, slide 1"
echo "  [ ] Browser zoom at 100% so slide 4 fits (click a question once to test, then reload)"
echo "  [ ] Keyboard within reach: 1-8 picks a question on slide 4, arrows move between slides"
echo "  [ ] (Optional) Claude Code open with the Postman plugin, signed in to the right team"
