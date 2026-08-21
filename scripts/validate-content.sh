#!/usr/bin/env bash
set -uo pipefail

# Validate every piece of content in this repo against the shared pattern.
#
#   ./scripts/validate-content.sh              # all content
#   ./scripts/validate-content.sh mcp-docs-best-friend   # one slug
#
# Checks that each content folder sits in the right format directory, declares a
# matching `format:` in its front matter, carries the required front-matter
# fields, and ships the files its format requires. Exits non-zero on any FAIL.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONTENT="$ROOT/content"
FILTER="${1:-}"

FAILS=0
WARNS=0
CHECKED=0
ITEM_FAILS=0

fail() { echo "  [FAIL] $1"; FAILS=$((FAILS + 1)); ITEM_FAILS=$((ITEM_FAILS + 1)); }
warn() { echo "  [WARN] $1"; WARNS=$((WARNS + 1)); }
ok()   { echo "  [OK]   $1"; }

# Front-matter fields required of every piece of content.
REQUIRED_FIELDS="format length product name use_case key_messages cta presentation_title"

# format slug <-> directory name
dir_for_format() {
  case "$1" in
    lightning-talk) echo "lightning-talks" ;;
    short-talk)     echo "short-talks" ;;
    standard-talk)  echo "standard-talks" ;;
    bootcamp)       echo "bootcamps" ;;
    *)              echo "" ;;
  esac
}

echo "=== Validating content in $CONTENT ==="

[ -d "$CONTENT" ] || { echo "[FAIL] No content/ directory at $CONTENT"; exit 1; }

# Anything sitting directly under content/ that is not a known format directory.
for entry in "$CONTENT"/*; do
  [ -e "$entry" ] || continue
  base="$(basename "$entry")"
  case "$base" in
    lightning-talks|short-talks|standard-talks|bootcamps) ;;
    *)
      echo ""
      echo "content/$base"
      fail "not a known format directory — content lives in content/<format>/<slug>/"
      ;;
  esac
done

for format_dir in lightning-talks short-talks standard-talks bootcamps; do
  [ -d "$CONTENT/$format_dir" ] || continue

  for dir in "$CONTENT/$format_dir"/*/; do
    [ -d "$dir" ] || continue
    slug="$(basename "$dir")"
    [ -z "$FILTER" ] || [ "$FILTER" = "$slug" ] || continue

    CHECKED=$((CHECKED + 1))
    ITEM_FAILS=0
    echo ""
    echo "content/$format_dir/$slug"

    fm="$dir/frontmatter.yaml"
    if [ ! -f "$fm" ]; then
      fail "missing frontmatter.yaml"
    else
      for field in $REQUIRED_FIELDS; do
        grep -qE "^${field}:" "$fm" || fail "frontmatter.yaml missing required field: $field"
      done

      declared="$(grep -E '^format:' "$fm" | head -1 | sed -E 's/^format:[[:space:]]*//; s/[[:space:]]*(#.*)?$//')"
      if [ -n "$declared" ]; then
        expected_dir="$(dir_for_format "$declared")"
        if [ -z "$expected_dir" ]; then
          fail "unknown format '$declared' — use lightning-talk, short-talk, standard-talk, or bootcamp"
        elif [ "$expected_dir" != "$format_dir" ]; then
          fail "declares format '$declared' but lives in content/$format_dir/ (expected content/$expected_dir/)"
        else
          ok "format: $declared"
        fi
      fi

      for field in owner status audience venues; do
        grep -qE "^${field}:" "$fm" || warn "frontmatter.yaml has no $field (recommended)"
      done
    fi

    [ -f "$dir/README.md" ] || fail "missing README.md"
    [ -f "$dir/presentation/index.html" ] || fail "missing presentation/index.html"

    for s in setup.sh teardown.sh; do
      if [ ! -f "$dir/scripts/$s" ]; then
        fail "missing scripts/$s"
      elif [ ! -x "$dir/scripts/$s" ]; then
        fail "scripts/$s is not executable (chmod +x)"
      fi
    done

    if [ "$format_dir" = "bootcamps" ]; then
      for required in handout.md modules exercises solutions scripts/checkpoint.sh; do
        [ -e "$dir/$required" ] || fail "bootcamp is missing $required (see templates/formats/bootcamp.md)"
      done
      if [ -d "$dir/exercises" ] && [ -d "$dir/solutions" ]; then
        for ex in "$dir/exercises"/*/; do
          [ -d "$ex" ] || continue
          name="$(basename "$ex")"
          [ -d "$dir/solutions/$name" ] || fail "exercises/$name has no matching solutions/$name"
        done
      fi
    fi

    grep -q "content/$format_dir/$slug" "$ROOT/README.md" \
      || warn "not listed in the root README catalog"

    [ "$ITEM_FAILS" -eq 0 ] && ok "structure complete"
  done
done

echo ""
echo "=== $CHECKED checked · $FAILS failed · $WARNS warnings ==="
[ "$FAILS" -eq 0 ] || exit 1
