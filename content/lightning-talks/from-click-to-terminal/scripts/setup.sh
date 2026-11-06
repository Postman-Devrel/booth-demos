#!/usr/bin/env bash
set -uo pipefail

# Postman in the terminal (booth cut). Setup.
#
# This is a thin wrapper: the booth cut runs the same setup script as the short
# talk (content/short-talks/from-click-to-terminal/scripts/setup.sh). The demo
# runs on a throwaway repo created from healthcare-org-app/healthcare-transport-template,
# not on a shared real repo. See that talk's README for what the script does.
# It opens this cut's deck (./presentation/index.html), through DECK_OVERRIDE.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export DECK_OVERRIDE="$SCRIPT_DIR/../presentation/index.html"
exec "$SCRIPT_DIR/../../../short-talks/from-click-to-terminal/scripts/setup.sh" "$@"
