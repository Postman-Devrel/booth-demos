#!/usr/bin/env bash
set -euo pipefail

DEMO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== Claude Code + Postman Booth Demo Setup ==="
echo ""

# 1. Check Claude Code is installed
if command -v claude &>/dev/null; then
  echo "[OK] Claude Code installed: $(claude --version 2>/dev/null || echo 'version unknown')"
else
  echo "[FAIL] Claude Code not found. Install from https://claude.ai/code"
  exit 1
fi

# 2. Check Postman plugin
if claude plugin list 2>/dev/null | grep -q "postman"; then
  echo "[OK] Postman Claude Code plugin installed"
else
  echo "[WARN] Postman plugin not found — installing..."
  claude plugin install github:Postman-Devrel/postman-claude-code-plugin
  echo "[OK] Postman plugin installed"
fi

# 3. Check POSTMAN_API_KEY
if [ -n "${POSTMAN_API_KEY:-}" ]; then
  echo "[OK] POSTMAN_API_KEY is set"
else
  echo "[WARN] POSTMAN_API_KEY is not set"
  echo "       Export it:  export POSTMAN_API_KEY=PMAK-your-key-here"
  echo "       Or use OAuth during the demo:  /postman:setup"
fi

# 4. Clean sample-api directory
if [ -f "$DEMO_DIR/sample-api/openapi.yaml" ]; then
  rm "$DEMO_DIR/sample-api/openapi.yaml"
  echo "[OK] Removed leftover openapi.yaml from sample-api/"
else
  echo "[OK] sample-api/ is clean — no leftover spec"
fi

# 5. Verify presentation exists
if [ -f "$DEMO_DIR/presentation/index.html" ]; then
  echo "[OK] Presentation found"
else
  echo "[FAIL] presentation/index.html not found"
  exit 1
fi

# 6. Open presentation in browser
echo ""
echo "Opening presentation in browser..."
open "$DEMO_DIR/presentation/index.html" 2>/dev/null \
  || xdg-open "$DEMO_DIR/presentation/index.html" 2>/dev/null \
  || echo "[WARN] Could not open browser automatically. Open presentation/index.html manually."

echo ""
echo "=== Setup complete. Ready to demo. ==="
echo ""
echo "Pre-demo checklist:"
echo "  [ ] Terminal open in $DEMO_DIR with Claude Code running"
echo "  [ ] Font size large enough for booth audience (Cmd+= to increase)"
echo "  [ ] Presentation visible on booth monitor"
echo "  [ ] Postman workspace is clean (no leftover collections)"
