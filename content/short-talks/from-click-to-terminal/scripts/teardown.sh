#!/usr/bin/env bash
set -euo pipefail

# Postman in the terminal — teardown.
#
# Reads the state file written by setup.sh, closes the open PR(s) of the
# throwaway repo, deletes the repo ONLY after an explicit interactive
# confirmation (needs the delete_repo scope), then removes the local clone and
# the state file. Safe to run when setup never ran.
#
# Guard rails: it never deletes a repo that is not healthcare-org-app/healthcare-transport-*,
# and never removes a clone outside /tmp/healthcare-transport-*.
#
# Usage:  ./teardown.sh [--dry-run]     (or DRY_RUN=1 ./teardown.sh)
#   --dry-run  print what would be executed, change nothing, ask nothing.

DRY_RUN="${DRY_RUN:-0}"
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help) sed -n '/^# Usage/,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown argument: $arg (supported: --dry-run)"; exit 2 ;;
  esac
done

STATE_FILE="${STATE_FILE:-/tmp/.postman-terminal-demo.state}"
ORG="healthcare-org-app"

echo "=== Postman in the terminal — Teardown ==="
[ "$DRY_RUN" = "1" ] && echo "(dry run: nothing is closed, deleted or removed)"
echo ""

if [ ! -f "$STATE_FILE" ]; then
  echo "[OK]   No state file at $STATE_FILE: nothing to tear down."
  exit 0
fi

# Parse KEY=VALUE lines without sourcing the file.
REPO="$(sed -n 's/^REPO=//p' "$STATE_FILE" | head -n 1)"
WORKDIR="$(sed -n 's/^WORKDIR=//p' "$STATE_FILE" | head -n 1)"
echo "State: repo=$REPO clone=$WORKDIR"

# --- Guard rails ----------------------------------------------------------------------

case "$REPO" in
  "$ORG"/healthcare-transport-?*) ;;
  *)
    echo "[FAIL] Refusing to act: '$REPO' is not $ORG/healthcare-transport-*. Check $STATE_FILE."
    exit 1 ;;
esac
case "$REPO" in
  *[!A-Za-z0-9._/-]*) echo "[FAIL] Refusing to act: unexpected characters in '$REPO'."; exit 1 ;;
esac
case "$WORKDIR" in
  /tmp/healthcare-transport-?*) ;;
  *)
    echo "[FAIL] Refusing to remove '$WORKDIR': not under /tmp/healthcare-transport-*. Check $STATE_FILE."
    exit 1 ;;
esac
case "$WORKDIR" in
  *..*|*[!A-Za-z0-9._/-]*) echo "[FAIL] Refusing to remove '$WORKDIR': unexpected characters."; exit 1 ;;
esac

REMOTE_GONE=0   # 1 once the repo is known not to exist anymore

# --- Does the repo still exist? ---------------------------------------------------------

if gh repo view "$REPO" >/dev/null 2>&1; then
  echo "[OK]   $REPO exists"
  REPO_EXISTS=1
else
  echo "[OK]   $REPO not found on GitHub (already deleted, or never created)"
  REPO_EXISTS=0
  REMOTE_GONE=1
fi

# --- Close open PRs -------------------------------------------------------------------------

if [ "$REPO_EXISTS" = "1" ]; then
  PR_NUMBERS="$(gh pr list --repo "$REPO" --state open --json number --jq '.[].number' 2>/dev/null || true)"
  if [ -n "$PR_NUMBERS" ]; then
    while IFS= read -r num; do
      [ -z "$num" ] && continue
      if [ "$DRY_RUN" = "1" ]; then
        echo "[DRY]  would run: gh pr close $num --repo $REPO --comment \"Closing: demo, not meant to be merged.\""
      elif gh pr close "$num" --repo "$REPO" --comment "Closing: demo, not meant to be merged." >/dev/null 2>&1; then
        echo "[OK]   Closed PR #$num on $REPO"
      else
        echo "[WARN] Could not close PR #$num automatically, check github.com/$REPO/pulls"
      fi
    done <<< "$PR_NUMBERS"
  else
    echo "[OK]   No open PR on $REPO"
  fi

  # --- Delete the repo, only after explicit confirmation ----------------------------------------

  echo ""
  if [ "$DRY_RUN" = "1" ]; then
    echo "[DRY]  would ask you to type the repo name to confirm, then run: gh repo delete $REPO --yes"
  else
    echo "About to PERMANENTLY DELETE https://github.com/$REPO"
    printf 'Type the full repo name to confirm (anything else keeps it): '
    ANSWER=""
    read -r ANSWER </dev/tty || ANSWER=""
    if [ "$ANSWER" = "$REPO" ]; then
      DEL_ERR="$(mktemp)"
      if gh repo delete "$REPO" --yes 2>"$DEL_ERR"; then
        echo "[OK]   Deleted $REPO"
        REMOTE_GONE=1
      elif grep -qi 'delete_repo' "$DEL_ERR"; then
        echo "[FAIL] Your gh token lacks the delete_repo scope. Run:"
        echo "         gh auth refresh -h github.com -s delete_repo"
        echo "       then run ./scripts/teardown.sh again."
      else
        echo "[FAIL] Could not delete $REPO:"
        sed 's/^/         /' "$DEL_ERR"
      fi
      rm -f "$DEL_ERR"
    else
      echo "[SKIP] Confirmation not given: $REPO kept."
    fi
  fi
fi

# --- The local clone ----------------------------------------------------------------------------

if [ -d "$WORKDIR" ]; then
  if [ "$DRY_RUN" = "1" ]; then
    echo "[DRY]  would run: rm -rf $WORKDIR"
  else
    rm -rf "$WORKDIR"
    echo "[OK]   Removed local clone at $WORKDIR"
  fi
else
  echo "[OK]   No local clone to remove"
fi

# --- The state file: kept while the remote repo still exists -------------------------------------

if [ "$DRY_RUN" = "1" ]; then
  echo "[DRY]  would remove $STATE_FILE once the repo is deleted"
  exit 0
fi
if [ "$REMOTE_GONE" = "1" ]; then
  rm -f "$STATE_FILE"
  echo "[OK]   Removed state file"
  echo ""
  echo "=== Teardown complete. Next session:  ./scripts/setup.sh ==="
else
  echo "[WARN] State file kept ($STATE_FILE): $REPO still exists. Re-run teardown to finish."
  exit 1
fi
