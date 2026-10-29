#!/usr/bin/env bash
set -uo pipefail

# Postman in the terminal — teardown.
#
# Closes every demo PR opened from a demo/live-* branch on the patients repo
# (with a comment), drafts included: a loop that ended in NEEDS_DECISION leaves
# the PR open as a draft. It also deletes those branches on the remote and
# removes the local clone. Safe to run when setup never ran.
#
# It never touches main. It cannot clean up anything else: the Postman
# workspace, the Context Graph, or any local Postman resource a rehearsal
# created on your own account.

DEMO_REPO="healthcare-org-app/healthcare-patients"
WORKDIR="/tmp/healthcare-patients"

echo "=== Postman in the terminal — Teardown ==="
echo ""

# --- Close every demo PR (open or draft) ---------------------------------------------------------

PR_NUMBERS="$(gh pr list --repo "$DEMO_REPO" --state open --json number,headRefName --jq '.[] | select(.headRefName | startswith("demo/live-")) | .number' 2>/dev/null)"
if [ -n "${PR_NUMBERS:-}" ]; then
  while IFS= read -r num; do
    [ -z "$num" ] && continue
    if gh pr close "$num" --repo "$DEMO_REPO" --delete-branch \
         --comment "Closing: demo rehearsal, not meant to be merged." >/dev/null 2>&1; then
      echo "[OK]   Closed PR #$num and deleted its branch on $DEMO_REPO"
    else
      echo "[WARN] Could not close PR #$num automatically, check github.com/$DEMO_REPO/pulls"
    fi
  done <<< "$PR_NUMBERS"
else
  echo "[OK]   No open demo PR on $DEMO_REPO"
fi

# --- Delete leftover demo/live-* branches ----------------------------------------

REMOTE_BRANCHES="$(gh api "repos/$DEMO_REPO/branches" --paginate --jq '.[] | select(.name | startswith("demo/live-")) | .name' 2>/dev/null)"
if [ -n "${REMOTE_BRANCHES:-}" ]; then
  while IFS= read -r branch; do
    [ -z "$branch" ] && continue
    if gh api -X DELETE "repos/$DEMO_REPO/git/refs/heads/$branch" >/dev/null 2>&1; then
      echo "[OK]   Deleted branch $branch on $DEMO_REPO"
    else
      echo "[WARN] Branch $branch exists on $DEMO_REPO but could not be deleted automatically."
    fi
  done <<< "$REMOTE_BRANCHES"
else
  echo "[OK]   No leftover demo/live-* branch on $DEMO_REPO"
fi

# --- The local clone ---------------------------------------------------------------

if [ -d "$WORKDIR" ]; then
  rm -rf "$WORKDIR"
  echo "[OK]   Removed local clone at $WORKDIR"
else
  echo "[OK]   No local clone to remove"
fi

cat <<EOF

=== Teardown complete. ===

Left standing on purpose:
  - github.com/$DEMO_REPO's main branch and the org-level POSTMAN_API_KEY secret
  - the healthcare-api-quality-gate repo and the Postman team's Context Graph

Not cleaned up (this script cannot identify them): anything created on your
own Postman account during a rehearsal.

Next session:  ./scripts/setup.sh
EOF
