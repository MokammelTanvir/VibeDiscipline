#!/usr/bin/env bash
# vibe check (v0.1 minimal) — executable slop detection.
#
# Checks the working diff (or the staged diff, with --staged) against a
# small set of mechanically-verifiable rules from
# .agent/skills/_shared/anti-slop.md. Prefers actionable findings (file +
# line) over any kind of "AI slop score".
#
# Usage:
#   scripts/check.sh              # working tree vs HEAD
#   scripts/check.sh --staged     # staged changes only (pre-commit mode)
set -uo pipefail

MODE="${1:-worktree}"
FAIL=0
WARN=0

if [ "$MODE" = "--staged" ]; then
  DIFF_FILES_CMD="git diff --cached --name-only"
  DIFF_CONTENT_CMD="git diff --cached -U0"
else
  DIFF_FILES_CMD="git diff --name-only"
  DIFF_CONTENT_CMD="git diff -U0"
fi

CHANGED_FILES=$($DIFF_FILES_CMD 2>/dev/null)

if [ -z "$CHANGED_FILES" ]; then
  echo "[vibe check] no changes to inspect."
  exit 0
fi

# Documentation and the check script's own source describe these patterns
# in prose/regex form — excluded from the leftover/TODO scans so the
# checker doesn't flag itself and its own docs.
CODE_FILES=$(echo "$CHANGED_FILES" | grep -Ev '\.md$|(^|/)scripts/check\.sh$' || true)
diff_for() {
  # $1: files to restrict the diff to (newline-separated); empty = none
  if [ -z "$1" ]; then return 0; fi
  # shellcheck disable=SC2086
  $DIFF_CONTENT_CMD -- $1 2>/dev/null
}

echo "vibe check — $(echo "$CHANGED_FILES" | wc -l | tr -d ' ') file(s) changed"
echo ""

# ── secrets ──────────────────────────────────────────────────────────
SECRET_PATTERN='(-----BEGIN [A-Z ]*PRIVATE KEY-----|AKIA[0-9A-Z]{16}|xox[baprs]-[0-9A-Za-z-]{10,}|api[_-]?key\s*[:=]\s*["'"'"'][A-Za-z0-9]{16,}|secret\s*[:=]\s*["'"'"'][A-Za-z0-9]{16,})'
SECRET_HITS=$($DIFF_CONTENT_CMD 2>/dev/null | grep -E '^\+' | grep -Ev '^\+\+\+' | grep -E "$SECRET_PATTERN" || true)
ENV_HITS=$(echo "$CHANGED_FILES" | grep -E '(^|/)\.env(\..*)?$' | grep -v '\.env\.example$' || true)

if [ -n "$SECRET_HITS" ] || [ -n "$ENV_HITS" ]; then
  echo "FAIL  secrets"
  [ -n "$SECRET_HITS" ] && echo "$SECRET_HITS" | sed 's/^/              possible secret literal: /'
  [ -n "$ENV_HITS" ] && echo "$ENV_HITS" | sed 's/^/              .env file staged (never commit it): /'
  FAIL=$((FAIL + 1))
else
  echo "PASS  secrets"
fi

# ── debug leftovers ──────────────────────────────────────────────────
# dd()/dump()/var_dump()/debugger/binding.pry are never legitimate in
# committed code. console.log is excluded for scripts/** and bin/**,
# where intentional CLI stdout output is expected.
STRICT_PATTERN='\bdd\(|\bdump\(|var_dump\(|debugger;|binding\.pry'
NON_CLI_FILES=$(echo "$CODE_FILES" | grep -Ev '(^|/)(scripts|bin)/' || true)

STRICT_HITS=$(diff_for "$CODE_FILES" | grep -E '^\+' | grep -Ev '^\+\+\+' | grep -E "$STRICT_PATTERN" || true)
CONSOLE_HITS=$(diff_for "$NON_CLI_FILES" | grep -E '^\+' | grep -Ev '^\+\+\+' | grep -E 'console\.log\(' || true)
LEFTOVER_HITS="${STRICT_HITS}${STRICT_HITS:+$'\n'}${CONSOLE_HITS}"

if [ -n "${LEFTOVER_HITS// /}" ]; then
  echo "FAIL  leftovers   debug statement(s) added:"
  echo "$LEFTOVER_HITS" | sed '/^$/d;s/^/              /'
  FAIL=$((FAIL + 1))
else
  echo "PASS  leftovers"
fi

# ── dependency changes without a stated reason ──────────────────────
MANIFEST_CHANGED=$(echo "$CHANGED_FILES" | grep -E '(^|/)(composer\.json|package\.json)$' || true)
LOCKFILE_CHANGED=$(echo "$CHANGED_FILES" | grep -E '(^|/)(composer\.lock|package-lock\.json|pnpm-lock\.yaml|yarn\.lock)$' || true)
if [ -n "$MANIFEST_CHANGED" ]; then
  echo "WARN  dependency  manifest changed ($MANIFEST_CHANGED) — confirm this is"
  echo "                  justified and recorded in the task doc before committing"
  WARN=$((WARN + 1))
elif [ -n "$LOCKFILE_CHANGED" ]; then
  echo "WARN  dependency  lockfile changed with no manifest change — verify this"
  echo "                  is expected (e.g. a transitive update), not accidental"
  WARN=$((WARN + 1))
else
  echo "PASS  dependency"
fi

# ── new TODO/FIXME without an owner ─────────────────────────────────
TODO_HITS=$(diff_for "$CODE_FILES" | grep -E '^\+' | grep -Ev '^\+\+\+' | grep -E 'TODO|FIXME' | grep -Ev 'TODO\([A-Za-z0-9_.-]+\)|FIXME\([A-Za-z0-9_.-]+\)' || true)
if [ -n "$TODO_HITS" ]; then
  echo "WARN  leftovers   TODO/FIXME added with no owner — TODO(name) or a ticket ref:"
  echo "$TODO_HITS" | sed 's/^/              /'
  WARN=$((WARN + 1))
fi

# ── tests: new source without a matching test touch (heuristic) ────
SRC_CHANGED=$(echo "$CHANGED_FILES" | grep -E '\.(php|ts|tsx|js|jsx|py|rb|go)$' | grep -Ev '(^|/)(tests?|spec|__tests__)/' || true)
TEST_CHANGED=$(echo "$CHANGED_FILES" | grep -E '(^|/)(tests?|spec|__tests__)/' || true)
if [ -n "$SRC_CHANGED" ] && [ -z "$TEST_CHANGED" ]; then
  echo "WARN  tests       source changed with no test file touched — confirm"
  echo "                  this is XS/S-tier or already covered by an existing test"
  WARN=$((WARN + 1))
else
  echo "PASS  tests"
fi

echo ""
echo "$FAIL failure(s), $WARN warning(s)."

if [ "$FAIL" -gt 0 ]; then
  echo "Commit blocked. Fix the FAIL findings above (see .agent/config.yml"
  echo "'check.fail_on' for what is fatal vs. advisory in this project)."
  exit 1
fi

exit 0
