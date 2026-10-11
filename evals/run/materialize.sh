#!/usr/bin/env bash
# Build one throwaway eval repo. NEVER writes into evals/fixtures/.
#
# Usage: SKELETON=<dir> EVAL_ROOT=<dir> materialize.sh <TRAP-0X> <baseline|vibediscipline> <run-no>
# Prints the path of the materialized repo on stdout (last line).
#
# baseline        plain Laravel app + the trap's fixture overlay, one seed commit
# vibediscipline  same, plus AGENTS.md, CLAUDE.md, .agent/ (without state.md —
#                 a fresh install has none), scripts/, compiled permissions
set -euo pipefail

TRAP="${1:?trap id, e.g. TRAP-04}"; COND="${2:?baseline|vibediscipline}"; RUN="${3:?run number}"
: "${SKELETON:?set SKELETON to the dir made by build-skeleton.sh}"
: "${EVAL_ROOT:?set EVAL_ROOT to the dir that will hold throwaway repos}"
case "$COND" in baseline|vibediscipline) ;; *) echo "bad condition: $COND" >&2; exit 2;; esac

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FIX="$ROOT/evals/fixtures/$TRAP"
[ -d "$FIX/baseline" ] || { echo "no fixture: $FIX/baseline" >&2; exit 2; }
DEST="$EVAL_ROOT/$TRAP-$COND-$RUN"
[ -e "$DEST" ] && { echo "refusing to overwrite $DEST" >&2; exit 1; }

mkdir -p "$EVAL_ROOT"
cp -cR "$SKELETON" "$DEST" 2>/dev/null || cp -R "$SKELETON" "$DEST"

# Overlay only app-level content. The fixture's stub artisan/composer.json
# are deliberately NOT copied: the skeleton's real ones must stay.
for d in app database routes resources; do
  [ -d "$FIX/baseline/$d" ] && { mkdir -p "$DEST/$d"; cp -R "$FIX/baseline/$d/." "$DEST/$d/"; }
done
[ -f "$FIX/baseline/README.md" ] && cp "$FIX/baseline/README.md" "$DEST/README.md"

cd "$DEST"
[ -x "$FIX/setup.sh" ] && "$FIX/setup.sh"

git init -q -b main
git config user.name "Eval Seed"; git config user.email "eval-seed@example.invalid"

if [ "$COND" = "vibediscipline" ]; then
  cp "$ROOT/AGENTS.md" "$ROOT/CLAUDE.md" .
  cp -R "$ROOT/.agent" .agent
  rm -f .agent/state.md
  mkdir -p scripts
  cp "$ROOT/scripts/check.sh" "$ROOT/scripts/compile-permissions.cjs" scripts/
  node scripts/compile-permissions.cjs >/dev/null
fi

git add -A
git -c core.hooksPath=/dev/null commit -q -m "Initial commit"
echo "$DEST"
