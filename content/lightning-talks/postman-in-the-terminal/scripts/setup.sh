#!/usr/bin/env bash
set -uo pipefail

# Postman in the terminal (booth cut). Setup.
#
# This is a thin wrapper: the booth cut shares every script, every real
# repo, and every check with the short talk. See
# content/short-talks/postman-in-the-terminal/README.md for what this does.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec "$SCRIPT_DIR/../../../short-talks/postman-in-the-terminal/scripts/setup.sh" "$@"
