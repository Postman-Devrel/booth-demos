#!/usr/bin/env bash
set -euo pipefail

# Postman in the terminal — setup.
#
# The live demo builds a brand-new service from its OpenAPI spec: postman init,
# collection, tests, mock, run against the mock, GitHub workflow (ci-integration
# skill), push, PR, CI. It runs on a throwaway repo created from
# healthcare-org-app/healthcare-transport-template (public, spec + README only).
#
# This script creates that repo (unique name), clones THE CREATED REPO into /tmp
# (a local clone of the template would have an unrelated history and the PR
# would be impossible), checks out a demo branch, and records everything in a
# state file so teardown.sh can find it. It never pushes and never opens a PR:
# that happens live, on stage.
#
# No POSTMAN_API_KEY and no `postman login` are required: the rehearsal journal
# shows the workflow as played (syntax lint, collection lint, run against the
# local mock, AI readiness) works without any Postman credential.
#
# Usage:  ./setup.sh [--dry-run]     (or DRY_RUN=1 ./setup.sh)
#   --dry-run  run the read-only checks, print what would be executed, change nothing.

DRY_RUN="${DRY_RUN:-0}"
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help) sed -n '/^# Usage/,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown argument: $arg (supported: --dry-run)"; exit 2 ;;
  esac
done

CONTENT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DECK="${DECK_OVERRIDE:-$CONTENT_DIR/presentation/index.html}"
ORG="healthcare-org-app"
TEMPLATE="$ORG/healthcare-transport-template"
STATE_FILE="${STATE_FILE:-/tmp/.postman-terminal-demo.state}"
BRANCH="demo/spec-to-pipeline"
SUFFIX="$(date +%Y%m%d-%H%M%S)"
REPO_NAME="healthcare-transport-$SUFFIX"     # no "demo" in the name: the reviewer once guessed the repo from it
REPO="$ORG/$REPO_NAME"
GATE_PR="https://github.com/healthcare-org-app/healthcare-appointments/pull/9"   # advanced usage: the quality gate, closed PR, shown at the end
WORKDIR="/tmp/$REPO_NAME"

echo "=== Postman in the terminal — Setup ==="
[ "$DRY_RUN" = "1" ] && echo "(dry run: read-only checks only, nothing is created, cloned or opened)"
echo ""

open_url() { open "$1" 2>/dev/null || xdg-open "$1" 2>/dev/null || return 1; }

# fail MESSAGE...: a blocking problem. In a dry run it is reported but does not stop the script.
fail() {
  echo "[FAIL] $*"
  [ "$DRY_RUN" = "1" ] || exit 1
}

# run CMD...: execute, or only print in a dry run.
run() {
  if [ "$DRY_RUN" = "1" ]; then
    printf '[DRY]  would run:'; printf ' %q' "$@"; echo
  else
    "$@"
  fi
}

need() {
  if command -v "$1" >/dev/null 2>&1; then echo "[OK]   $1 present"; else fail "$1 not found. $2"; fi
}

# --- The deck -----------------------------------------------------------------

if [ ! -f "$DECK" ]; then
  fail "Presentation not found at $DECK — restore it from git."
elif head -c 64 "$DECK" | grep -qi '<!doctype html' && grep -q '</html>' "$DECK"; then
  echo "[OK]   Deck found and well-formed"
else
  fail "Deck is present but is not a complete HTML file — restore it from git."
fi

# --- Tooling --------------------------------------------------------------------

need git "install git"
need gh "install the GitHub CLI: https://cli.github.com/"
need claude "install Claude Code: https://code.claude.com/docs"
need postman "install the Postman CLI: curl -o- \"https://dl-cli.pstmn.io/install/unix.sh\" | sh"

if command -v postman >/dev/null 2>&1; then
  PM_OUT="$(postman --version 2>&1 || true)"
  echo "[OK]   Postman CLI version: $(printf '%s\n' "$PM_OUT" | head -n 1)"
  if printf '%s\n' "$PM_OUT" | tail -n +2 | grep -qiE 'newer|available|update'; then
    echo "[WARN] A newer Postman CLI is available (not blocking, the demo was rehearsed on 1.85.0):"
    printf '%s\n' "$PM_OUT" | tail -n +2 | sed 's/^/         /'
  fi
fi

if command -v gh >/dev/null 2>&1; then
  if gh auth status >/dev/null 2>&1; then
    echo "[OK]   gh is authenticated"
  else
    fail "gh is not authenticated. Run: gh auth login"
  fi
fi

# The Postman plugin must be installed and enabled (its skills drive the demo:
# bootstrap, api-testing, api-mocking, ci-integration).
if command -v claude >/dev/null 2>&1; then
  PLUGINS="$(claude plugin list 2>/dev/null || true)"
  plugin_enabled() {  # $1 = plugin name; true if any entry of that name is enabled
    printf '%s\n' "$PLUGINS" | awk -v n="$1" '
      $0 ~ "❯ " n "@" {hit=1; next}
      hit && /Status:/ { if ($0 ~ /enabled/ && $0 !~ /disabled/) found=1; hit=0 }
      END { exit found ? 0 : 1 }'
  }
  if plugin_enabled "postman"; then
    echo "[OK]   Postman plugin is installed and enabled"
  else
    fail "The Postman plugin is not installed/enabled in Claude Code. Check \`claude plugin list\` and install the Postman plugin."
  fi
fi

# --- No leftover state from a previous run -----------------------------------------

if [ -f "$STATE_FILE" ]; then
  fail "A previous demo is still recorded in $STATE_FILE. Run ./scripts/teardown.sh first."
else
  echo "[OK]   No leftover state file"
fi

# --- Create the throwaway repo from the template and clone it ------------------------

echo ""
echo "Repo to create: $REPO (from $TEMPLATE)"
echo "Local clone:    $WORKDIR"
echo "Branch:         $BRANCH"

if [ "$DRY_RUN" = "1" ]; then
  echo "[DRY]  would write state to $STATE_FILE:"
  echo "         REPO=$REPO"
  echo "         WORKDIR=$WORKDIR"
else
  # State first: if creation half-succeeds, teardown can still find the repo.
  printf 'REPO=%s\nWORKDIR=%s\n' "$REPO" "$WORKDIR" > "$STATE_FILE"
fi

if [ "$DRY_RUN" = "1" ]; then
  echo "[DRY]  would run: (cd /tmp && gh repo create $REPO --template $TEMPLATE --public --clone)"
else
  ( cd /tmp && gh repo create "$REPO" --template "$TEMPLATE" --public --clone )
  [ -f "$WORKDIR/openapi.yaml" ] || { echo "[FAIL] $WORKDIR/openapi.yaml missing after the clone. Run ./scripts/teardown.sh."; exit 1; }
  echo "[OK]   Created $REPO and cloned it to $WORKDIR"
fi

if [ "$DRY_RUN" = "1" ]; then
  echo "[DRY]  would run: git -C $WORKDIR checkout -b $BRANCH"
else
  git -C "$WORKDIR" checkout -b "$BRANCH"
  echo "[OK]   On branch $BRANCH"
fi

# --- Open the deck ------------------------------------------------------------------

echo ""
if [ "$DRY_RUN" = "1" ]; then
  echo "[DRY]  would open https://github.com/$REPO"
  echo "[DRY]  would open $GATE_PR"
  echo "[DRY]  would open $DECK"
else
  echo "Opening the created repo..."
  open_url "https://github.com/$REPO" || echo "[WARN] Open https://github.com/$REPO manually."
  echo "Opening the quality gate PR (advanced usage, shown at the end, not live)..."
  open_url "$GATE_PR" || echo "[WARN] Open $GATE_PR manually."
  echo "Opening the deck..."
  open_url "$DECK" || echo "[WARN] Open $DECK manually."
fi

cat <<EOF

=== Setup complete. ===

Pre-flight checklist:
  [ ] Deck open, FULLSCREEN, on slide 1
  [ ] Terminal tab in $WORKDIR running \`claude\` (Postman plugin loaded, check /plugin), LARGE FONT (Cmd+=)
  [ ] The GitHub tab of $REPO (opened by the script) ready for the PR and the CI run
  [ ] The quality gate PR tab (opened by the script): advanced usage, shown at the end, not live
  [ ] No \`postman login\` and no POSTMAN_API_KEY needed for this demo

The live demo, in the claude tab. One prompt per step (adapt the wording, keep the intent).

------------------------------------------------------------------------------
1 · INIT
------------------------------------------------------------------------------
Initialize the Postman workspace for this repo. Stay local, no cloud push.

------------------------------------------------------------------------------
2 · COLLECTION + TESTS
------------------------------------------------------------------------------
Generate a Postman collection from the spec, then add tests to every request
(status code, response shape from the spec). The generated collection has no
assertions: that part is your work.

------------------------------------------------------------------------------
3 · MOCK + RUN AGAINST THE MOCK
------------------------------------------------------------------------------
Generate a local mock from the spec, then run the collection against that mock
and show me the result.

------------------------------------------------------------------------------
4 · WORKFLOW (ci-integration skill)
------------------------------------------------------------------------------
Add a GitHub workflow that runs the checks on every PR, including the AI
readiness score. It must work with no Postman login and no secret.

------------------------------------------------------------------------------
5 · PUSH AND PR
------------------------------------------------------------------------------
Commit the changes on the current branch, push it, and open a pull request with
a real description: what was generated, what the workflow checks, how it was
verified locally. Don't merge.

Then watch the run: gh run watch   (rehearsed at about 19 s of CI).

------------------------------------------------------------------------------
Points d'attention (rehearsal journal)
------------------------------------------------------------------------------
  - \`postman init -y\`, NOT \`--no-cloud\` (the bootstrap skill cites it, the CLI refuses it).
  - init creates .opencode/ (visible in \`ls -A\`): expected, say so.
  - The generated collection has zero assertions; a wrong field name (rides vs
    items) gets caught by the run against the mock: a good moment to show.
  - In CI without login: \`postman spec lint --issueType=syntax\` (full governance
    lint needs a login).
  - No junit reporter: v3 collections only support the cli reporter.
  - .postman/resources.yaml does not list the collection after generation: normal.

When you are done:  ./scripts/teardown.sh
EOF
