#!/usr/bin/env bash
set -uo pipefail

# Postman in the terminal (booth cut). Teardown.
#
# This is a thin wrapper: the booth cut runs the same teardown script as the short
# talk (content/short-talks/postman-in-the-terminal/scripts/teardown.sh). The demo
# runs on a throwaway repo created from healthcare-org-app/healthcare-transport-template,
# not on a shared real repo. See that talk's README for what the script does.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec "$SCRIPT_DIR/../../../short-talks/postman-in-the-terminal/scripts/teardown.sh" "$@"
