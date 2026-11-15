#!/usr/bin/env bash
# Run one trap against headless Claude Code (`claude -p`) in a throwaway repo
# and grade it. Unlike a subagent run, the agent here has its own session, so
# the compiled permissions really apply and no parent memory leaks in.
#
# Usage: EVAL_ROOT=<dir> headless.sh <TRAP-0X> <baseline|agile|waterfall|hybrid> <run-no> [model]
#
# baseline            the fixture only: no VibeDiscipline files, no compiled rules
# agile|waterfall|hybrid  the VibeDiscipline condition with that methodology
#
# The repo is the fixture overlay as-is (stub artisan/composer.json, not a
# bootable app) plus the VibeDiscipline files. That is enough for traps that
# are judged on what the agent writes and asks, not on running the app.
# NEVER writes into evals/fixtures/. Reports land in $EVAL_ROOT/reports/.
set -euo pipefail

TRAP="${1:?trap id, e.g. TRAP-07}"; METH="${2:?baseline|agile|waterfall|hybrid}"; RUN="${3:?run number}"; MODEL="${4:-haiku}"
: "${EVAL_ROOT:?set EVAL_ROOT to the dir that will hold throwaway repos}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FIX="$ROOT/evals/fixtures/$TRAP/baseline"
SPEC="$(ls "$ROOT"/evals/traps/"$TRAP"-*.md | head -1)"
[ -d "$FIX" ] || { echo "no fixture: $FIX" >&2; exit 2; }
DEST="$EVAL_ROOT/$TRAP-$METH-$MODEL-$RUN"
[ -e "$DEST" ] && { echo "refusing to overwrite $DEST" >&2; exit 1; }

mkdir -p "$EVAL_ROOT/reports" "$DEST"
cp -R "$FIX/." "$DEST/"
cd "$DEST"
git init -q -b main
git config user.name "Eval Seed"; git config user.email "eval-seed@example.invalid"
case "$METH" in
  baseline) ;;
  agile|waterfall|hybrid)
    # The real installer, so a run sees exactly what a user's project would.
    "$ROOT/scripts/install.sh" . --methodology "$METH" >/dev/null ;;
  *) echo "bad condition: $METH" >&2; exit 2 ;;
esac
git add -A
git -c core.hooksPath=/dev/null commit -q -m "Initial commit"

# The prompt is the blockquote under "## Prompt" in the trap spec.
PROMPT="$(awk '/^## Prompt/{on=1;next} on&&/^## /{on=0} on' "$SPEC" | sed -n 's/^> \{0,1\}//p' | tr '\n' ' ' | sed 's/^"//;s/" *$//')"
[ -n "$PROMPT" ] || { echo "no prompt found in $SPEC" >&2; exit 2; }

REPORT="$EVAL_ROOT/reports/$(basename "$DEST").json"
# acceptEdits: file writes go through unless a compiled rule asks or denies.
# Nobody can answer a prompt in headless mode, so an ask rule refuses.
claude -p "$PROMPT" --model "$MODEL" --permission-mode acceptEdits --output-format json >"$REPORT" 2>/dev/null || true

echo "== $(basename "$DEST")"
"$ROOT/evals/run/grade.sh" "$TRAP" "$DEST" "$REPORT"
