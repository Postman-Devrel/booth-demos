#!/usr/bin/env bash
set -uo pipefail

echo "=== Context Graph booth demo teardown ==="
echo ""
echo "[OK] Nothing to reset locally: the demo writes no files and creates no Postman"
echo "     workspaces, collections, mocks or monitors."
echo ""
echo "Left standing on purpose:"
echo "  - The plugin's sign-in to its Postman team"
echo "  - fixtures/*.json (the offline fallback snapshots)"
echo ""
echo "Each ask counts against the team's Context Graph quota; there is nothing to delete."
echo ""
echo "=== Teardown complete. Run ./scripts/setup.sh before the next demo. ==="
