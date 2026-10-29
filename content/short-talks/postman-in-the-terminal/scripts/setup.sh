#!/usr/bin/env bash
set -uo pipefail

# Postman in the terminal — setup.
#
# The live demo runs on a real repo, healthcare-org-app/healthcare-patients
# (patients-service), already equipped with the healthcare org's platform API
# quality gate (healthcare-org-app/healthcare-api-quality-gate, tag v1). This
# script only READS GitHub and clones to /tmp: it never pushes, never opens a
# PR. The branch, the PR and the gate run happen live, on stage.

CONTENT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DECK="$CONTENT_DIR/presentation/index.html"
DEMO_REPO="healthcare-org-app/healthcare-patients"
GATE_REPO="healthcare-org-app/healthcare-api-quality-gate"
WORKDIR="/tmp/healthcare-patients"   # a fresh clone, reset every run (no "demo" in the name: the reviewer once guessed the repo from it)

echo "=== Postman in the terminal — Setup ==="
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
# git and gh to push the branch and open the PR. claude for the gate loop.
# postman for the plugin's skills and the local gate run. python3 for the
# service's pytest run (your own Claude Code session runs pytest -q).

need git "install git"
need gh "install the GitHub CLI: https://cli.github.com/"
need claude "install Claude Code: https://code.claude.com/docs"
need postman "install the Postman CLI: curl -o- \"https://dl-cli.pstmn.io/install/unix.sh\" | sh"
need python3 "install Python 3.11+ (patients-service is Flask; pytest runs locally in the gate loop)"

gh auth status >/dev/null 2>&1 || { echo "[FAIL] gh is not authenticated. Run: gh auth login"; exit 1; }
echo "[OK]   gh is authenticated"

if postman whoami >/dev/null 2>&1; then
  echo "[OK]   Postman CLI is logged in"
else
  echo "[WARN] Postman CLI is not logged in. Run \`postman login\` before you present"
  echo "       (the local gate run and the plugin need it; use a team whose Context Graph has the org ingested)."
fi

# --- The gate plugin must be installed at USER level ------------------------------
# A built-in Claude Code security hook deletes .claude/settings.json in a clone it
# considers untrusted, so the repo-level plugin enablement does not apply.

PLUGINS="$(claude plugin list 2>/dev/null || true)"
plugin_enabled() {  # $1 = plugin name; true if any entry of that name is enabled
  printf '%s\n' "$PLUGINS" | awk -v n="$1" '
    $0 ~ "❯ " n "@" {hit=1; next}
    hit && /Status:/ { if ($0 ~ /enabled/ && $0 !~ /disabled/) found=1; hit=0 }
    END { exit found ? 0 : 1 }'
}
if plugin_enabled "healthcare-api-quality-gate"; then
  echo "[OK]   Gate plugin healthcare-api-quality-gate is enabled"
else
  echo "[FAIL] The gate plugin healthcare-api-quality-gate is not installed/enabled. Run:"
  echo "         claude plugin marketplace add $GATE_REPO"
  echo "         claude plugin install healthcare-api-quality-gate@healthcare-api-quality-gate"
  exit 1
fi
if plugin_enabled "postman-agent-quality-gate"; then
  echo "[WARN] The old postman-agent-quality-gate plugin (0.4.0) is still enabled: it loads a duplicate"
  echo "       gate-loop / gate-verdict. Run: claude plugin disable postman-agent-quality-gate@postman-agent-quality-gate"
else
  echo "[OK]   Old postman-agent-quality-gate plugin not enabled"
fi

# --- The demo repo must be clean before you go on stage ----------------------
# A previous rehearsal's PR or branch left over means teardown didn't run.

ERR="$(mktemp)"
OPEN_PRS="$(gh pr list --repo "$DEMO_REPO" --state open --json headRefName --jq '[.[] | select(.headRefName | startswith("demo/live-"))] | length' 2>"$ERR")"
if [ $? -ne 0 ]; then
  echo "[FAIL] Could not list PRs on $DEMO_REPO:"
  cat "$ERR"; rm -f "$ERR"
  exit 1
fi
if [ "$OPEN_PRS" != "0" ]; then
  rm -f "$ERR"
  echo "[FAIL] $DEMO_REPO already has an open PR from a demo/live-* branch."
  echo "       Run ./scripts/teardown.sh first, or close it by hand."
  exit 1
fi
echo "[OK]   No leftover demo PR on $DEMO_REPO"

REMOTE_BRANCHES="$(gh api "repos/$DEMO_REPO/branches" --paginate --jq '.[] | select(.name | startswith("demo/live-")) | .name' 2>"$ERR")"
if [ $? -ne 0 ]; then
  echo "[FAIL] Could not list branches on $DEMO_REPO:"
  cat "$ERR"; rm -f "$ERR"
  exit 1
fi
rm -f "$ERR"
if [ -n "$REMOTE_BRANCHES" ]; then
  echo "[FAIL] $DEMO_REPO already has a leftover demo/live-* branch:"
  echo "$REMOTE_BRANCHES" | sed 's/^/         /'
  echo "       Run ./scripts/teardown.sh first, or delete it by hand."
  exit 1
fi
echo "[OK]   No leftover demo/live-* branch on $DEMO_REPO"

# --- A fresh local clone, every time ---------------------------------------------

rm -rf "$WORKDIR"
CLONE_ERR="$(mktemp)"
if ! gh repo clone "$DEMO_REPO" "$WORKDIR" -- -q 2>"$CLONE_ERR"; then
  echo "[FAIL] Could not clone $DEMO_REPO:"
  cat "$CLONE_ERR"; rm -f "$CLONE_ERR"
  exit 1
fi
rm -f "$CLONE_ERR"
echo "[OK]   Fresh clone of $DEMO_REPO at $WORKDIR"

# main must still carry `mrn` in the Patient schema: a rehearsal that reached
# main would leave nothing to rename on stage.
if awk '/^    Patient:/{p=1;next} p && /^    [A-Za-z]/{p=0} p && /^        mrn:/{f=1} END{exit f?0:1}' "$WORKDIR/openapi.yaml"; then
  echo "[OK]   main's openapi.yaml still has mrn in the Patient schema"
else
  echo "[FAIL] main's openapi.yaml has no mrn in the Patient schema. A previous"
  echo "       rehearsal's rename reached main. Fix main by hand (revert the rename) before presenting."
  exit 1
fi

for f in CLAUDE.md AGENTS.md quality-gate.yml .github/workflows/quality-gate.yml; do
  [ -f "$WORKDIR/$f" ] && echo "[OK]   $f present" || echo "[WARN] $f missing in the clone: the demo expects it"
done

ls "$WORKDIR"/.claude/agents/*.md >/dev/null 2>&1 && echo "[WARN] The clone still has a coder sub-agent (.claude/agents/): the demo no longer uses one."

# --- Open everything ----------------------------------------------------------

echo ""
echo "Opening the deck and the two repos..."
open_url "$DECK" || echo "[WARN] Open $DECK manually."
open_url "https://github.com/$DEMO_REPO" || echo "[WARN] Open https://github.com/$DEMO_REPO manually."
open_url "https://github.com/$GATE_REPO" || echo "[WARN] Open https://github.com/$GATE_REPO manually."

cat <<EOF

=== Setup complete. ===

Pre-flight checklist:
  [ ] Deck open, FULLSCREEN, on slide 1
  [ ] \`postman login\` done, on a team whose Context Graph has healthcare-org-app ingested
  [ ] github.com/$DEMO_REPO and github.com/$GATE_REPO open in browser tabs
  [ ] Postman app open on the Context Graph, patients-service's consumers, in ANOTHER tab (act 6)
  [ ] Terminal tab 1 in $WORKDIR for the manual change (act 4), LARGE FONT (Cmd+=)
  [ ] Terminal tab 2 in $WORKDIR running \`claude\`: YOUR OWN session is the coder (act 5),
      with the Postman plugin and the gate plugin (user level), check /plugin
  [ ] No open PR, no demo/live-* branch on $DEMO_REPO

The live demo, on stage:
  1. Slides 1-14, then slide 15 (Live demo). Act 4: show the workspace in files.
  2. git checkout -b demo/live-rename-mrn, rename mrn to medical_record_number
     in the response side of openapi.yaml, commit, push, gh pr create --fill
     (never \`git add -A\`: the security hook leaves .claude/settings.json deleted)
  3. Watch the "API quality gate" comment (about 80 s), then in the claude tab:
     "The quality gate failed on demo/live-rename-mrn. Run the gate loop until
     the gate passes. Don't merge."  Ends green or NEEDS_DECISION. Do NOT merge.
  4. Show the gate repo, then the Context Graph in the Postman app.
  5. Slides 16-18.

When you are done:  ./scripts/teardown.sh
EOF
