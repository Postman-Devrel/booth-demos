#!/usr/bin/env bash
set -uo pipefail

# Let the Gate Decide — setup.
#
# The live demo runs inside a separate product repo
# (Postman-Devrel/agent-quality-gate), not in this content folder — this
# script's job is to validate tooling, make sure the product repo is clean of
# any leftover demo branch/PR, get a fresh clone ready at a scratch
# directory, and open the deck and the repo. It never runs the quality gate
# itself and never pushes anything; that happens live, on stage.

CONTENT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DECK="$CONTENT_DIR/presentation/index.html"
DEMO_REPO="Postman-Devrel/agent-quality-gate"
BRANCH_PATTERN="demo/live-*"   # the brief does not fix one slug; refresh per rehearsal
WORKDIR="/tmp/agent-quality-gate-demo"   # a fresh clone, reset every run

echo "=== Let the Gate Decide — Setup ==="
echo ""

open_url() { open "$1" 2>/dev/null || xdg-open "$1" 2>/dev/null || return 1; }

need() {
  command -v "$1" >/dev/null 2>&1 && { echo "[OK]   $1 present"; return 0; }
  echo "[FAIL] $1 not found. $2"
  exit 1
}

# --- The deck -----------------------------------------------------------------

if [ ! -f "$DECK" ]; then
  echo "[FAIL] Presentation not found at $DECK — restore it from git."
  exit 1
fi
if head -c 64 "$DECK" | grep -qi '<!doctype html' && grep -q '</html>' "$DECK"; then
  echo "[OK]   Deck found and well-formed"
else
  echo "[FAIL] Deck is present but is not a complete HTML file — restore it from git."
  exit 1
fi

# --- Tooling --------------------------------------------------------------------
# git and gh for pushing the demo branch and watching Actions. claude and
# postman for the live agent loop (acts 4-7). Java for running the service
# and the gate locally if you want a pre-show dry run.

need git "install git"
need gh "install the GitHub CLI: https://cli.github.com/"
need claude "install Claude Code: https://code.claude.com/docs"
need postman "install the Postman CLI: curl -o- \"https://dl-cli.pstmn.io/install/unix.sh\" | sh"
need java "install Java 21+ (the product repo's pom targets Java 21)"

gh auth status >/dev/null 2>&1 || { echo "[FAIL] gh is not authenticated. Run: gh auth login"; exit 1; }
echo "[OK]   gh is authenticated"

postman config get api-key >/dev/null 2>&1 \
  && echo "[OK]   Postman CLI appears logged in" \
  || echo "[WARN] Could not confirm the Postman CLI is logged in. Run: postman login --with-api-key \"\$POSTMAN_API_KEY\" (a key whose team has appointments-service in its Context Graph) before you present."

# --- The product repo must be clean before you go on stage ----------------------
# A previous rehearsal's PR or branch left open means teardown didn't run.
# Fix that first instead of opening a second one on top of it.

PR_ERR="$(mktemp)"
OPEN_PRS="$(gh pr list --repo "$DEMO_REPO" --json headRefName --jq '[.[] | select(.headRefName | startswith("demo/live-"))] | length' 2>"$PR_ERR")"
if [ $? -ne 0 ]; then
  echo "[FAIL] Could not list PRs on $DEMO_REPO:"
  cat "$PR_ERR"
  rm -f "$PR_ERR"
  exit 1
fi
rm -f "$PR_ERR"
if [ "$OPEN_PRS" != "0" ]; then
  echo "[FAIL] $DEMO_REPO already has an open PR from a demo/live-* branch."
  echo "       Run ./scripts/teardown.sh first, or close it by hand."
  exit 1
fi
echo "[OK]   No leftover demo PR on $DEMO_REPO"

BRANCH_ERR="$(mktemp)"
REMOTE_DEMO_BRANCHES="$(gh api "repos/$DEMO_REPO/branches" --jq '[.[] | select(.name | startswith("demo/live-"))] | length' 2>"$BRANCH_ERR")"
if [ $? -ne 0 ]; then
  echo "[FAIL] Could not list branches on $DEMO_REPO:"
  cat "$BRANCH_ERR"
  rm -f "$BRANCH_ERR"
  exit 1
fi
rm -f "$BRANCH_ERR"
if [ "$REMOTE_DEMO_BRANCHES" != "0" ]; then
  echo "[FAIL] $DEMO_REPO already has a leftover demo/live-* branch."
  echo "       Run ./scripts/teardown.sh first, or delete it by hand."
  exit 1
fi
echo "[OK]   No leftover demo/live-* branch on $DEMO_REPO"

# --- A fresh local clone, every time ---------------------------------------------

rm -rf "$WORKDIR"
CLONE_ERR="$(mktemp)"
if ! gh repo clone "$DEMO_REPO" "$WORKDIR" -- -q 2>"$CLONE_ERR"; then
  echo "[FAIL] Could not clone $DEMO_REPO:"
  cat "$CLONE_ERR"
  rm -f "$CLONE_ERR"
  exit 1
fi
rm -f "$CLONE_ERR"
echo "[OK]   Fresh clone of $DEMO_REPO at $WORKDIR"

if [ -d "$WORKDIR/.claude/agents" ] && [ -f "$WORKDIR/.claude/agents/api-coder-naive.md" ]; then
  echo "[OK]   Demo-only agent api-coder-naive.md is present"
else
  echo "[WARN] $WORKDIR/.claude/agents/api-coder-naive.md not found. Act 5 needs it (see"
  echo "       README section 2, first row) — confirm it was committed before you present."
fi

if [ -f "$WORKDIR/gate/run-all.sh" ]; then
  echo "[OK]   gate/run-all.sh found — run it by hand once for a baseline dry run if time allows"
else
  echo "[WARN] gate/run-all.sh not found in the clone. Act 4's baseline run will not work."
fi

# --- Open everything ----------------------------------------------------------

echo ""
echo "Opening the deck and the repo..."
open_url "$DECK" || echo "[WARN] Open presentation/index.html manually."
open_url "https://github.com/$DEMO_REPO" || echo "[WARN] Open https://github.com/$DEMO_REPO manually."

cat <<EOF

=== Setup complete. ===

Pre-flight checklist:
  [ ] Deck open, FULLSCREEN, on slide 1
  [ ] Logged into the Postman CLI (postman login) with a key whose team has
      appointments-service in its Context Graph
  [ ] A NEW Claude Code session opened in $WORKDIR, so .claude/agents/ is loaded
  [ ] ./gate/run-all.sh run once in $WORKDIR on main — confirms baseline rating A
  [ ] github.com/$DEMO_REPO open in a browser tab, Actions tab ready
  [ ] No open PR, no leftover $BRANCH_PATTERN branch

The live demo, on stage (acts 4-7, see README section 4):
  1. Tour $WORKDIR, run ./gate/run-all.sh for the baseline (act 4)
  2. In the Claude Code session, launch api-coder-naive on the brief's part-3
     request (act 5)
  3. Watch the Actions run fail, launch gate-reviewer with the branch and SHA
     (act 6)
  4. Send the brief back to api-coder-naive, watch the next run pass (act 7)

When you are done:  ./scripts/teardown.sh
EOF
