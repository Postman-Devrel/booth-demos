#!/usr/bin/env bash
set -uo pipefail

# Agentic SDLC with Context Graph and API Simulations — teardown.
#
# Setup creates no state, so there is nothing to reset. Close the deck without saving.
# If you edited the deck during rehearsal and want the committed one back:
#   git checkout -- presentation/Agentic_SDLC_Conference_Talk.pptx

echo "=== Agentic SDLC with Context Graph and API Simulations — Teardown ==="
echo ""
echo "[OK]   Nothing running, nothing generated."
echo ""
echo "=== Teardown complete. ==="
echo "Next session:  ./scripts/setup.sh"
