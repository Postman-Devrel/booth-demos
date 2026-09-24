#!/usr/bin/env bash
set -uo pipefail

# Postman Headless: The Agentic Era — teardown.
#
# Closes the PR opened on stage, deletes its branch, and removes the local
# clone. Safe to run when setup never ran.
#
# What it deliberately does NOT touch: the demo repo's main branch, its
# Actions secrets, and the Postman team's Context Graph connection to the
# estate. That is shared infrastructure this session doesn't own.

DEMO_REPO="avdev4j/postman-cli-headless-agents"
BRANCH="remove-blood-type"
WORKDIR="/tmp/postman-cli-headless-agents-demo"

echo "=== Postman Headless: The Agentic Era — Teardown ==="
echo ""

# --- Close the PR opened on stage, if any ------------------------------------

PR_NUMBER="$(gh pr list --repo "$DEMO_REPO" --head "$BRANCH" --state open --json number --jq '.[0].number' 2>/dev/null)"
if [ -n "${PR_NUMBER:-}" ] && [ "$PR_NUMBER" != "null" ]; then
  if gh pr close "$PR_NUMBER" --repo "$DEMO_REPO" --delete-branch >/dev/null 2>&1; then
    echo "[OK]   Closed PR #$PR_NUMBER and deleted branch $BRANCH on $DEMO_REPO"
  else
    echo "[WARN] Could not close PR #$PR_NUMBER automatically — check github.com/$DEMO_REPO/pulls"
  fi
else
  echo "[OK]   No open PR from $BRANCH on $DEMO_REPO"
  if gh api "repos/$DEMO_REPO/branches/$BRANCH" >/dev/null 2>&1; then
    if gh api -X DELETE "repos/$DEMO_REPO/git/refs/heads/$BRANCH" >/dev/null 2>&1; then
      echo "[OK]   Deleted leftover branch $BRANCH on $DEMO_REPO"
    else
      echo "[WARN] Branch $BRANCH exists on $DEMO_REPO but could not be deleted automatically."
    fi
  fi
fi

# --- The local clone ----------------------------------------------------------

if [ -d "$WORKDIR" ]; then
  rm -rf "$WORKDIR"
  echo "[OK]   Removed local clone at $WORKDIR"
else
  echo "[OK]   No local clone to remove"
fi

cat <<EOF

=== Teardown complete. ===

Left standing on purpose:
  - github.com/$DEMO_REPO's main branch and its Actions secrets
  - the Postman team's Context Graph connection to the estate

Next session:  ./scripts/setup.sh
EOF
