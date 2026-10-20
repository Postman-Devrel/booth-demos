#!/usr/bin/env bash
set -uo pipefail

# Let the Gate Decide — teardown.
#
# Closes any demo PR opened on stage, deletes every demo/live-* branch (both
# locally in the scratch clone and on the product repo's GitHub remote), and
# removes the scratch clone. Safe to run when setup never ran.
#
# What it deliberately does NOT touch: the product repo's main branch, its
# Actions secrets, and the Postman workspace / Context Graph connection —
# shared infrastructure this talk doesn't own.

DEMO_REPO="Postman-Devrel/agent-quality-gate"
WORKDIR="/tmp/agent-quality-gate-demo"

echo "=== Let the Gate Decide — Teardown ==="
echo ""

# --- Close any demo PR opened on stage ------------------------------------------

PR_NUMBERS="$(gh pr list --repo "$DEMO_REPO" --json number,headRefName --jq '[.[] | select(.headRefName | startswith("demo/live-")) | .number] | .[]' 2>/dev/null)"
if [ -n "${PR_NUMBERS:-}" ]; then
  while IFS= read -r num; do
    [ -z "$num" ] && continue
    if gh pr close "$num" --repo "$DEMO_REPO" --delete-branch >/dev/null 2>&1; then
      echo "[OK]   Closed PR #$num and deleted its branch on $DEMO_REPO"
    else
      echo "[WARN] Could not close PR #$num automatically, check github.com/$DEMO_REPO/pulls"
    fi
  done <<< "$PR_NUMBERS"
else
  echo "[OK]   No open demo PR on $DEMO_REPO"
fi

# --- Delete any leftover demo/live-* branches on the remote ---------------------

REMOTE_BRANCHES="$(gh api "repos/$DEMO_REPO/branches" --jq '[.[] | select(.name | startswith("demo/live-")) | .name] | .[]' 2>/dev/null)"
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

# --- The scratch clone -----------------------------------------------------------

if [ -d "$WORKDIR" ]; then
  rm -rf "$WORKDIR"
  echo "[OK]   Removed scratch clone at $WORKDIR"
else
  echo "[OK]   No scratch clone to remove"
fi

cat <<EOF

=== Teardown complete. ===

Left standing on purpose:
  - github.com/$DEMO_REPO's main branch and its Actions secrets
  - the Postman workspace and Context Graph connection

Next session:  ./scripts/setup.sh
EOF
