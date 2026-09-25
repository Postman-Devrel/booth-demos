#!/usr/bin/env bash
set -uo pipefail

# Postman Headless: The Agentic Era — setup.
#
# The live demo has three parts: slides, a real GitHub repo
# (Postman-Devrel/postman-cli-headless-agents-demo), and the Postman app's
# Context Graph UI. Nothing here runs the Postman CLI or calls the Context
# Graph — that happens live, on stage, inside the demo repo's own CI, run by
# its headless agent. This script's only job is to get a clean local clone
# ready and open what needs to be open.

CONTENT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DECK="$CONTENT_DIR/presentation/index.html"
DEMO_REPO="Postman-Devrel/postman-cli-headless-agents-demo"
BRANCH="remove-blood-type"
WORKDIR="/tmp/postman-cli-headless-agents-demo"   # a fresh clone, reset every run

echo "=== Postman Headless: The Agentic Era — Setup ==="
echo ""

open_url() { open "$1" 2>/dev/null || xdg-open "$1" 2>/dev/null || return 1; }

need() {
  command -v "$1" >/dev/null 2>&1 && { echo "[OK]   $1 present"; return 0; }
  echo "[FAIL] $1 not found — $2"
  exit 1
}

# --- The deck ---------------------------------------------------------------

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

# --- Tooling ------------------------------------------------------------------
# git and gh only — nobody runs the Postman CLI by hand in this version of
# the demo, so it isn't checked here. The demo repo's own CI checks it.

need git "install git"
need gh "install the GitHub CLI: https://cli.github.com/"

gh auth status >/dev/null 2>&1 || { echo "[FAIL] gh is not authenticated — run: gh auth login"; exit 1; }
echo "[OK]   gh is authenticated"

# --- The demo repo must be clean before you go on stage ----------------------
# A previous rehearsal's PR left open means teardown didn't run — fix that
# first instead of opening a second PR on top of it.

PR_ERR="$(mktemp)"
OPEN_PRS="$(gh pr list --repo "$DEMO_REPO" --head "$BRANCH" --state open --json number --jq 'length' 2>"$PR_ERR")"
if [ $? -ne 0 ]; then
  echo "[FAIL] Could not list PRs on $DEMO_REPO:"
  cat "$PR_ERR"
  rm -f "$PR_ERR"
  exit 1
fi
rm -f "$PR_ERR"
if [ "$OPEN_PRS" != "0" ]; then
  echo "[FAIL] $DEMO_REPO already has an open PR from branch $BRANCH."
  echo "       Run ./scripts/teardown.sh first, or close it by hand."
  exit 1
fi
echo "[OK]   No leftover PR on $DEMO_REPO"

SECRETS_ERR="$(mktemp)"
SECRETS="$(gh secret list --repo "$DEMO_REPO" --json name --jq '.[].name' 2>"$SECRETS_ERR")"
if [ $? -ne 0 ]; then
  echo "[FAIL] Could not list secrets on $DEMO_REPO:"
  cat "$SECRETS_ERR"
  rm -f "$SECRETS_ERR"
  exit 1
fi
rm -f "$SECRETS_ERR"
for s in POSTMAN_API_KEY ANTHROPIC_API_KEY; do
  if echo "$SECRETS" | grep -qx "$s"; then
    echo "[OK]   Secret $s is set on $DEMO_REPO"
  else
    echo "[FAIL] Secret $s is missing on $DEMO_REPO — the headless agent's job will fail without it."
    echo "       gh secret set $s --repo $DEMO_REPO"
    exit 1
  fi
done

# --- A fresh local clone, every time ------------------------------------------

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

if grep -q 'blood_type' "$WORKDIR/openapi.yaml"; then
  echo "[OK]   main still has blood_type — there's a real change left to make on stage"
else
  echo "[FAIL] main on $DEMO_REPO is already missing blood_type — a previous"
  echo "       rehearsal's change reached main without a teardown. Fix main by"
  echo "       hand (put blood_type back) before presenting."
  exit 1
fi

# --- Open everything ----------------------------------------------------------

echo ""
echo "Opening the presentation and the repo..."
open_url "$DECK" || echo "[WARN] Open presentation/index.html manually."
open_url "https://github.com/$DEMO_REPO" || echo "[WARN] Open https://github.com/$DEMO_REPO manually."

cat <<EOF

=== Setup complete. ===

Pre-flight checklist:
  [ ] Deck open, FULLSCREEN, on slide 1
  [ ] github.com/$DEMO_REPO open in a browser tab
  [ ] A Postman workspace with this team's Context Graph open in another tab
      — don't switch to it until step 5, while the agent is running
  [ ] Terminal in $WORKDIR, LARGE FONT (Cmd+=)
  [ ] No open PR yet on $DEMO_REPO

The live demo, on stage:
  1. Slides — the concept (Act 1: build & test headless, Act 2: ask the graph)
  2. Switch to the browser: github.com/$DEMO_REPO
  3. In $WORKDIR: remove \`blood_type\` from openapi.yaml, commit, push $BRANCH,
     \`gh pr create --fill\`
  4. Watch the PR — the headless agent comments on its own, unprompted
  5. While it runs (20-40s of real Context Graph reasoning inside it), switch
     to the Postman app and show the Context Graph UI, live

When you are done:  ./scripts/teardown.sh
EOF
