#!/usr/bin/env bash
set -uo pipefail

# Postman plugin: an agent reviews your API change. Teardown.
#
# Closes the PR opened on stage, deletes its branch, and removes both local
# folders (the bare-spec folder from act 4, and the demo repo clone from
# act 5+). Safe to run when setup never ran.
#
# What it deliberately does NOT touch: the demo repo's main branch, its
# Actions secrets, the Postman team's Context Graph connection to the
# estate, and the workspace/collection/mock act 4 creates live on your
# Postman account. All of that is either shared infrastructure this session
# doesn't own, or a real resource on your account this script has no way to
# identify after the fact — delete those by hand in the Postman app.

DEMO_REPO="Postman-Devrel/postman-plugin-pr-review-demo"
BRANCH="remove-blood-type"
LOCAL_PLUGIN_DIR="/tmp/postman-plugin-local-demo"
WORKDIR="/tmp/postman-plugin-pr-review-demo"

echo "=== Postman plugin: an agent reviews your API change. Teardown ==="
echo ""

# --- Close the PR opened on stage, if any ------------------------------------

PR_NUMBER="$(gh pr list --repo "$DEMO_REPO" --head "$BRANCH" --state open --json number --jq '.[0].number' 2>/dev/null)"
if [ -n "${PR_NUMBER:-}" ] && [ "$PR_NUMBER" != "null" ]; then
  if gh pr close "$PR_NUMBER" --repo "$DEMO_REPO" --delete-branch >/dev/null 2>&1; then
    echo "[OK]   Closed PR #$PR_NUMBER and deleted branch $BRANCH on $DEMO_REPO"
  else
    echo "[WARN] Could not close PR #$PR_NUMBER automatically, check github.com/$DEMO_REPO/pulls"
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

# --- The local folders ---------------------------------------------------

if [ -d "$LOCAL_PLUGIN_DIR" ]; then
  rm -rf "$LOCAL_PLUGIN_DIR"
  echo "[OK]   Removed act 4's bare-spec folder at $LOCAL_PLUGIN_DIR"
else
  echo "[OK]   No bare-spec folder to remove"
fi

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

Left standing because this script can't identify them:
  - the workspace, collection, and mock act 4 created live on your Postman
    account. Delete them by hand in the Postman app before the next
    rehearsal, or they pile up.

Next session:  ./scripts/setup.sh
EOF
