#!/usr/bin/env bash
set -euo pipefail

DEMO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== Claude Code + Postman Booth Demo Teardown ==="
echo ""

# 1. Remove generated spec
if [ -f "$DEMO_DIR/sample-api/openapi.yaml" ]; then
  rm "$DEMO_DIR/sample-api/openapi.yaml"
  echo "[OK] Removed sample-api/openapi.yaml"
else
  echo "[OK] No openapi.yaml to remove"
fi

# 2. Remove any other generated files in sample-api
find "$DEMO_DIR/sample-api" -type f ! -name '.gitkeep' -delete 2>/dev/null
echo "[OK] sample-api/ cleaned"

# 3. Remind about Postman cloud artifacts
echo ""
echo "=== Manual cleanup (Postman cloud) ==="
echo ""
echo "Remove these from your Postman workspace if they exist:"
echo "  - Liftoff Content API collection"
echo "  - Liftoff Content API environment"
echo "  - Any mock servers created during the demo"
echo ""
echo "Quick way: open Claude Code and run:"
echo '  "Delete the Liftoff Content API collection, environment, and mock server from my workspace"'
echo ""
echo "=== Teardown complete. Run ./scripts/setup.sh before next demo. ==="
