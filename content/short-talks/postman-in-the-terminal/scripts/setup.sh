#!/usr/bin/env bash
set -uo pipefail

# Postman plugin: an agent reviews your API change. Setup.
#
# The live demo has four parts: slides, a local Claude Code session with the
# Postman plugin (act 4, against a bare spec, nothing else), a real GitHub
# repo (Postman-Devrel/postman-plugin-pr-review-demo), and the Postman app's
# Context Graph UI. Only act 4 runs the Postman CLI/plugin locally; from the
# repo-breaking act onward, nothing here runs the Postman CLI or calls the
# Context Graph, that happens live, on stage, inside the demo repo's own CI,
# run by its CI agent. This script's job is to get the bare-spec folder and a
# clean local clone ready, and open what needs to be open.

CONTENT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PRESENTATION_URL="https://claude.ai/design/p/355ac88d-3b8d-4bd5-b9d3-1dd677fee145?file=From+Click+to+Terminal.dc.html&via=share"
DEMO_REPO="Postman-Devrel/postman-plugin-pr-review-demo"
BRANCH="remove-blood-type"
LOCAL_PLUGIN_DIR="/tmp/postman-plugin-local-demo"   # bare spec only, reset every run (act 4)
WORKDIR="/tmp/postman-plugin-pr-review-demo"        # a fresh clone, reset every run (act 5+)

echo "=== Postman plugin: an agent reviews your API change. Setup ==="
echo ""

open_url() { open "$1" 2>/dev/null || xdg-open "$1" 2>/dev/null || return 1; }

need() {
  command -v "$1" >/dev/null 2>&1 && { echo "[OK]   $1 present"; return 0; }
  echo "[FAIL] $1 not found. $2"
  exit 1
}

# --- Tooling ------------------------------------------------------------------
# git and gh for the repo-breaking act onward. claude and postman are only
# for act 4, which runs the plugin on this laptop; the demo repo's own CI
# checks its own copy of the Postman CLI, so that part isn't checked here.

need git "install git"
need gh "install the GitHub CLI: https://cli.github.com/"
need claude "install Claude Code: https://code.claude.com/docs"
need postman "install the Postman CLI: curl -o- \"https://dl-cli.pstmn.io/install/unix.sh\" | sh"

gh auth status >/dev/null 2>&1 || { echo "[FAIL] gh is not authenticated. Run: gh auth login"; exit 1; }
echo "[OK]   gh is authenticated"

# --- Act 4's bare-spec folder, reset every run --------------------------------
# Nothing but openapi.yaml, so the plugin builds the workspace, collection,
# and mock live, from one instruction, with no other context to lean on.

rm -rf "$LOCAL_PLUGIN_DIR"
mkdir -p "$LOCAL_PLUGIN_DIR"
cp "$CONTENT_DIR/openapi.yaml" "$LOCAL_PLUGIN_DIR/openapi.yaml"
echo "[OK]   Bare spec copied to $LOCAL_PLUGIN_DIR for act 4's local-plugin step"

# --- The demo repo must be clean before you go on stage ----------------------
# A previous rehearsal's PR left open means teardown didn't run. Fix that
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
    echo "[FAIL] Secret $s is missing on $DEMO_REPO. The CI agent's job will fail without it."
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
  echo "[OK]   main still has blood_type, there's a real change left to make on stage"
else
  echo "[FAIL] main on $DEMO_REPO is already missing blood_type. A previous"
  echo "       rehearsal's change reached main without a teardown. Fix main by"
  echo "       hand (put blood_type back) before presenting."
  exit 1
fi

# --- Open everything ----------------------------------------------------------

echo ""
echo "Opening the presentation and the repo..."
open_url "$PRESENTATION_URL" || echo "[WARN] Open $PRESENTATION_URL manually."
open_url "https://github.com/$DEMO_REPO" || echo "[WARN] Open https://github.com/$DEMO_REPO manually."

cat <<EOF

=== Setup complete. ===

Pre-flight checklist:
  [ ] Signed into claude.ai, deck open, FULLSCREEN, on slide 1
  [ ] Logged into the Postman CLI already (\`postman login\`), so act 4's
      \`postman:bootstrap\` doesn't eat demo time on an auth flow
  [ ] github.com/$DEMO_REPO open in a browser tab
  [ ] A Postman workspace with this team's Context Graph open in another tab
      don't switch to it until act 6
  [ ] A terminal tab in $LOCAL_PLUGIN_DIR running \`claude\` (act 4), LARGE FONT
  [ ] A second terminal tab in $WORKDIR (act 5+), LARGE FONT (Cmd+=)
  [ ] No open PR yet on $DEMO_REPO

The live demo, on stage:
  1. Slides, the concept (committed skills, two paths: plugin and postman init)
  2. In $LOCAL_PLUGIN_DIR: tell Claude Code "From openapi.yaml, create a
     Postman workspace, a collection, and a mock." Narrate the skills it
     chains on its own (bootstrap -> collection -> mock)
  3. Switch to the browser: github.com/$DEMO_REPO, show AGENTS.md and
     postman/skills/
  4. In $WORKDIR: remove \`blood_type\` from openapi.yaml, commit, push $BRANCH,
     \`gh pr create --fill\`
  5. Watch the PR, the CI agent comments on its own, unprompted
  6. While it runs (a few seconds to a few minutes of real Context Graph
     reasoning inside it), switch to the Postman app and show the Context
     Graph UI, live

Cleanup reminder: the workspace/collection/mock act 4 creates live are real,
on your Postman account. ./scripts/teardown.sh does not delete them, see
README section 5.

When you are done:  ./scripts/teardown.sh
EOF
