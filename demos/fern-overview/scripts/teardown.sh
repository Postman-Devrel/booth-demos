#!/usr/bin/env bash
set -euo pipefail

DEMO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
STATE="$DEMO_DIR/.demo-state"

echo "=== Fern Overview — Teardown ==="
echo ""

# 1. Remove the setup marker
if [ -f "$STATE" ]; then
  rm -f "$STATE"
  echo "[OK]   Removed .demo-state"
else
  echo "[OK]   No .demo-state to remove — already clean"
fi

# 2. Nothing else to clean. Say so explicitly rather than pretending.
echo "[OK]   No cloud state, generated artifacts, or accounts to reset"
echo "       (this demo is intentionally stateless)"

cat <<'EOF'

Manual step:
  [ ] Close the extra browser tabs (elevenlabs.io/docs and the .md one)
      so the next presenter opens them fresh.

=== Teardown complete. Run ./scripts/setup.sh to go again. ===
EOF
