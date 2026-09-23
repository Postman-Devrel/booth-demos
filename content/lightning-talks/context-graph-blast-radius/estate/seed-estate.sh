#!/usr/bin/env bash
set -uo pipefail

# Seed the demo API estate the Context Graph reads.
#
# ONE-TIME, NOT PER-SESSION. Run this once (and after any edit to app/ or
# estate/repos/), then wait for the graph's nightly refresh. scripts/setup.sh
# never calls this — it only checks that the graph can already answer.
#
#   ESTATE_ORG=<github-org-or-user> ./estate/seed-estate.sh --dry-run
#   ESTATE_ORG=<github-org-or-user> ./estate/seed-estate.sh
#
# It creates four repositories and pushes them:
#
#   orders-api       <- ../app            the provider; the only repo on stage
#   invoice-service  <- repos/...         calls GET /orders/{id}, reads the field
#   crm-sync-job     <- repos/...         calls GET /orders/{id}, reads the field
#   mobile-bff       <- repos/...         calls GET /orders/{id}, ignores the field
#
# Use a DEDICATED org or your own account. These are plain service names on
# purpose — they show up on stage — so do not seed them into an org where a real
# `orders-api` already lives.

ESTATE_DIR="$(cd "$(dirname "$0")" && pwd)"
CONTENT_DIR="$(cd "$ESTATE_DIR/.." && pwd)"
VISIBILITY="${ESTATE_VISIBILITY:-private}"
DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

echo "=== Seed the demo API estate ==="
echo ""

if [ -z "${ESTATE_ORG:-}" ]; then
  echo "[FAIL] Set ESTATE_ORG to the GitHub org (or user) that owns the demo estate."
  echo "       ESTATE_ORG=my-demo-org $0 --dry-run"
  exit 1
fi

command -v gh >/dev/null 2>&1 || { echo "[FAIL] gh not found — https://cli.github.com/"; exit 1; }
command -v git >/dev/null 2>&1 || { echo "[FAIL] git not found"; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "[FAIL] gh not authenticated — run: gh auth login"; exit 1; }
echo "[OK]   gh authenticated"

# name:source-dir
TARGETS=(
  "orders-api:$CONTENT_DIR/app"
  "invoice-service:$ESTATE_DIR/repos/invoice-service"
  "crm-sync-job:$ESTATE_DIR/repos/crm-sync-job"
  "mobile-bff:$ESTATE_DIR/repos/mobile-bff"
)

echo ""
echo "Target org : $ESTATE_ORG"
echo "Visibility : $VISIBILITY   (override with ESTATE_VISIBILITY=public)"
echo "Repos      :"
for t in "${TARGETS[@]}"; do echo "  - $ESTATE_ORG/${t%%:*}"; done
echo ""

if [ "$DRY_RUN" = "1" ]; then
  echo "[OK]   --dry-run: nothing was created. Re-run without --dry-run to push."
  exit 0
fi

printf 'This CREATES and PUSHES four repositories to %s. Type "seed" to continue: ' "$ESTATE_ORG"
read -r CONFIRM
[ "$CONFIRM" = "seed" ] || { echo "[OK]   Aborted. Nothing was created."; exit 0; }

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

for t in "${TARGETS[@]}"; do
  NAME="${t%%:*}"
  SRC="${t#*:}"
  SLUG="$ESTATE_ORG/$NAME"

  if [ ! -d "$SRC" ]; then
    echo "[FAIL] Source folder missing: $SRC"
    continue
  fi

  if gh repo view "$SLUG" >/dev/null 2>&1; then
    echo "[OK]   $SLUG already exists — updating its contents"
  else
    if gh repo create "$SLUG" "--$VISIBILITY" \
         --description "Context Graph demo estate — $NAME" >/dev/null 2>&1; then
      echo "[OK]   Created $SLUG"
    else
      echo "[FAIL] Could not create $SLUG — check your org permissions"
      continue
    fi
  fi

  WORK="$STAGE/$NAME"
  mkdir -p "$WORK"
  # Copy the source tree, minus anything local-only.
  (cd "$SRC" && tar --exclude='.git' --exclude='node_modules' --exclude='IMPACT.md' -cf - .) \
    | (cd "$WORK" && tar -xf -)

  (
    cd "$WORK" || exit 1
    git init -q -b main
    git add -A
    git -c user.name="estate-seed" -c user.email="estate-seed@example.com" \
        commit -q -m "Seed $NAME for the Context Graph demo estate"
    git remote add origin "https://github.com/$SLUG.git"
    git push -q --force origin main
  ) && echo "[OK]   Pushed $SLUG" || echo "[FAIL] Push to $SLUG failed"
done

cat <<EOF

=== Seeded. Two manual steps remain, and they are not scriptable ===

1. Connect the estate to the Context Graph (one time, Postman side):
     - ingest the GitHub org "$ESTATE_ORG"
     - ingest the Postman workspace that holds the Orders API spec
       (import app/openapi.yaml into it)

2. WAIT FOR THE NIGHTLY REFRESH. The graph resolves entities and edges on a
   nightly cycle — it will not answer about these repos the minute you push.

Then verify, from the content folder:
     ./scripts/setup.sh

Docs: https://www.postman.com/context-graph/
EOF
