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
#   scripts/check.sh --task 004   # scope-check against that task doc
#
# Severity comes from `check.fail_on` / `check.warn_on` in .agent/config.yml
# and `check.ignore` drops paths from every check. With no config (a
# skills-only install) the built-in defaults apply: secrets and leftovers
# fail, everything else warns.
set -uo pipefail

usage() { sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; }

MODE="worktree"
TASK_ID=""
while [ $# -gt 0 ]; do
  case "$1" in
    --staged) MODE="--staged" ;;
    --task) TASK_ID="${2:-}"; [ $# -gt 1 ] && shift ;;
    --task=*) TASK_ID="${1#--task=}" ;;
    -h|--help) usage; exit 0 ;;
    *) echo "[vibe check] unknown argument '$1'" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

FAIL=0
WARN=0
CONFIG=".agent/config.yml"
TASK_DIR="docs/tasks"

# Items of a list under the top-level `check:` key, one per line. Reads the
# inline form (`fail_on: [a, b]`) and the block form (`- a`).
cfg_list() {
  [ -f "$CONFIG" ] || return 0
  awk -v key="$1" '
    /^check:[[:space:]]*(#.*)?$/ { inblk = 1; next }
    inblk && /^[^[:space:]#]/ { inblk = 0 }
    !inblk { next }
    /^[[:space:]]+[A-Za-z_]+:/ {
      inkey = 0
      line = $0; sub(/^[[:space:]]+/, "", line)
      k = line; sub(/:.*/, "", k)
      if (k != key) next
      v = line; sub(/^[^:]*:[[:space:]]*/, "", v)
      if (v ~ /^\[/) {
        sub(/^\[/, "", v); sub(/\].*/, "", v)
        n = split(v, a, ","); for (i = 1; i <= n; i++) print a[i]
      } else inkey = 1
      next
    }
    inkey && /^[[:space:]]+-[[:space:]]/ {
      v = $0; sub(/^[[:space:]]+-[[:space:]]*/, "", v); sub(/[[:space:]]+#.*/, "", v); print v
    }
  ' "$CONFIG" | sed "s/^[[:space:]]*//;s/[[:space:]]*\$//;s/^[\"']//;s/[\"']\$//" | sed '/^$/d'
}
FAIL_ON=$(cfg_list fail_on)
WARN_ON=$(cfg_list warn_on)
IGNORE=$(cfg_list ignore)

# finding <check> <built-in severity> <headline>: prints one result line at
# the configured severity and counts it.
finding() {
  local sev="$2"
  if echo "$FAIL_ON" | grep -qxF -- "$1"; then sev="FAIL"
  elif echo "$WARN_ON" | grep -qxF -- "$1"; then sev="WARN"; fi
  printf '%-4s  %-11s %s\n' "$sev" "$1" "$3"
  if [ "$sev" = "FAIL" ]; then FAIL=$((FAIL + 1)); else WARN=$((WARN + 1)); fi
}

# matches_any <path> <newline-separated glob patterns>. A pattern also
# matches everything beneath it, so `legacy` and `legacy/**` both work.
matches_any() {
  local pat
  while IFS= read -r pat; do
    pat="${pat%/}"
    [ -n "$pat" ] || continue
    # shellcheck disable=SC2254
    case "$1" in $pat|$pat/*) return 0 ;; esac
  done <<EOF
$2
EOF
  return 1
}

# In worktree mode, brand-new files are not in `git diff` until they are
# staged — include them (minus .gitignore'd files) so a new test file counts
# and a new file with a secret or debug call is still scanned.
UNTRACKED_FILES=""
if [ "$MODE" = "--staged" ]; then
  DIFF_FILES_CMD="git diff --cached --name-only"
  DIFF_CONTENT_CMD="git diff --cached -U0"
else
  DIFF_FILES_CMD="git diff --name-only"
  DIFF_CONTENT_CMD="git diff -U0"
  UNTRACKED_FILES=$(git ls-files --others --exclude-standard 2>/dev/null)
fi

CHANGED_FILES=$(
  { $DIFF_FILES_CMD 2>/dev/null; [ -n "$UNTRACKED_FILES" ] && echo "$UNTRACKED_FILES"; } | sed '/^$/d' | sort -u
)

if [ -n "$IGNORE" ] && [ -n "$CHANGED_FILES" ]; then
  KEPT=""
  while IFS= read -r f; do
    matches_any "$f" "$IGNORE" || KEPT="${KEPT}${f}"$'\n'
  done <<EOF
$CHANGED_FILES
EOF
  CHANGED_FILES=$(printf '%s' "$KEPT" | sed '/^$/d')
fi

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
  # Untracked files have no diff against HEAD; show each as all-added lines.
  local f
  for f in $UNTRACKED_FILES; do
    if echo "$1" | grep -qxF -- "$f"; then
      git diff --no-index -U0 -- /dev/null "$f" 2>/dev/null || true
    fi
  done
}

echo "vibe check — $(echo "$CHANGED_FILES" | wc -l | tr -d ' ') file(s) changed"
echo ""

# ── scope: files changed outside the task doc's Affected Areas ─────
# The task is --task <id>, else every task doc whose status is in-progress
# or review. No task doc (Tier XS/S work, or a skills-only install) means
# there is no declared scope to check against.
TASK_DOCS=""
if [ -d "$TASK_DIR" ]; then
  if [ -n "$TASK_ID" ]; then
    TASK_NUM="${TASK_ID#TASK-}"
    TASK_DOCS=$(ls "$TASK_DIR"/TASK-*.md 2>/dev/null | grep -E "/TASK-0*${TASK_NUM}(-|\.md)" || true)
    if [ -z "$TASK_DOCS" ]; then
      echo "[vibe check] no task doc matches --task $TASK_ID in $TASK_DIR" >&2
      exit 2
    fi
  else
    TASK_DOCS=$(grep -lE '^status:[[:space:]]*(in-progress|review)' "$TASK_DIR"/TASK-*.md 2>/dev/null || true)
  fi
fi

if [ -n "$TASK_DOCS" ]; then
  # Backticked paths in "## Affected Areas"; `a/{b,c}.md` is expanded.
  SCOPE_PATTERNS=""
  for doc in $TASK_DOCS; do
    for tok in $(awk '/^## Affected Areas/{on=1;next} on&&/^## /{on=0} on' "$doc" | grep -oE '`[^` ]+`' | tr -d '`'); do
      echo "$tok" | grep -qE '^[A-Za-z0-9_./*{},@+-]+$' || continue
      if echo "$tok" | grep -q '{'; then
        set -f; tok=$(eval "printf '%s\n' $tok"); set +f
      fi
      SCOPE_PATTERNS="${SCOPE_PATTERNS}${tok}"$'\n'
    done
  done
  TASK_NAMES=$(for doc in $TASK_DOCS; do basename "$doc" | grep -oE '^TASK-[0-9]+'; done | tr '\n' ' ' | sed 's/ $//')
  if [ -z "$SCOPE_PATTERNS" ]; then
    echo "SKIP  scope       $TASK_NAMES lists no backticked paths under '## Affected Areas'"
  else
    # The task doc itself and the session bookkeeping files are always in scope.
    SCOPE_PATTERNS="${SCOPE_PATTERNS}${TASK_DOCS}"$'\n'"$TASK_DIR/BOARD.md"$'\n'".agent/state.md"
    OUT_OF_SCOPE=""
    while IFS= read -r f; do
      matches_any "$f" "$SCOPE_PATTERNS" || OUT_OF_SCOPE="${OUT_OF_SCOPE}${f}"$'\n'
    done <<EOF
$CHANGED_FILES
EOF
    if [ -n "$OUT_OF_SCOPE" ]; then
      finding scope WARN "changed but not in the Affected Areas of $TASK_NAMES:"
      printf '%s' "$OUT_OF_SCOPE" | sed 's/^/              /'
      echo "              add it to the task doc if it belongs, or take it out of this change"
    else
      echo "PASS  scope"
    fi
  fi
elif [ -d "$TASK_DIR" ]; then
  echo "SKIP  scope       no task doc in progress (Tier XS/S work, or pass --task <id>)"
fi

# ── secrets ──────────────────────────────────────────────────────────
SECRET_PATTERN='(-----BEGIN [A-Z ]*PRIVATE KEY-----|AKIA[0-9A-Z]{16}|xox[baprs]-[0-9A-Za-z-]{10,}|api[_-]?key\s*[:=]\s*["'"'"'][A-Za-z0-9]{16,}|secret\s*[:=]\s*["'"'"'][A-Za-z0-9]{16,})'
SECRET_HITS=$(diff_for "$CHANGED_FILES" | grep -E '^\+' | grep -Ev '^\+\+\+' | grep -E "$SECRET_PATTERN" || true)
ENV_HITS=$(echo "$CHANGED_FILES" | grep -E '(^|/)\.env(\..*)?$' | grep -v '\.env\.example$' || true)

if [ -n "$SECRET_HITS" ] || [ -n "$ENV_HITS" ]; then
  finding secrets FAIL ""
  [ -n "$SECRET_HITS" ] && echo "$SECRET_HITS" | sed 's/^/              possible secret literal: /'
  [ -n "$ENV_HITS" ] && echo "$ENV_HITS" | sed 's/^/              .env file staged (never commit it): /'
else
  echo "PASS  secrets"
fi

# ── debug leftovers ──────────────────────────────────────────────────
# Each pattern is only looked for in files of its own language: `dd(` in a
# shell script or a test fixture string is not a PHP debug call.
# console.log is also skipped under scripts/** and bin/**, where stdout
# output is the point.
added_in() { # $1 file-extension regex, $2 pattern, $3 optional path regex to exclude
  local files
  files=$(echo "$CODE_FILES" | grep -E "\\.($1)\$" || true)
  [ -n "${3:-}" ] && files=$(echo "$files" | grep -Ev "$3" || true)
  diff_for "$files" | grep -E '^\+' | grep -Ev '^\+\+\+' | grep -E "$2" || true
}
LEFTOVER_HITS=$(
  added_in 'php' '\bdd\(|\bdump\(|var_dump\('
  added_in 'js|jsx|ts|tsx|mjs|cjs|vue|svelte' 'debugger;'
  added_in 'js|jsx|ts|tsx|mjs|cjs|vue|svelte' 'console\.log\(' '(^|/)(scripts|bin)/'
  added_in 'rb|erb|rake' 'binding\.pry'
  added_in 'py' '\bbreakpoint\(\)|pdb\.set_trace\('
)

if [ -n "${LEFTOVER_HITS// /}" ]; then
  finding leftovers FAIL "debug statement(s) added:"
  echo "$LEFTOVER_HITS" | sed '/^$/d;s/^/              /' 
else
  echo "PASS  leftovers"
fi

# ── dependency changes without a stated reason ──────────────────────
MANIFEST_CHANGED=$(echo "$CHANGED_FILES" | grep -E '(^|/)(composer\.json|package\.json)$' || true)
LOCKFILE_CHANGED=$(echo "$CHANGED_FILES" | grep -E '(^|/)(composer\.lock|package-lock\.json|pnpm-lock\.yaml|yarn\.lock)$' || true)
# Justified = the task doc in progress (or one in this diff) talks about it.
DEP_DOCS="$TASK_DOCS $(echo "$CHANGED_FILES" | grep -E "^$TASK_DIR/TASK-.*\.md$" || true)"
DEP_JUSTIFIED=""
for doc in $DEP_DOCS; do
  [ -f "$doc" ] && grep -qiE 'dependenc|composer\.json|package\.json' "$doc" && DEP_JUSTIFIED="$doc"
done
if [ -n "$MANIFEST_CHANGED" ] && [ -z "$DEP_JUSTIFIED" ]; then
  finding dependency WARN "manifest changed ($(echo $MANIFEST_CHANGED)) and no task doc"
  echo "                  justifies it — record the dependency change in the task doc"
elif [ -z "$MANIFEST_CHANGED" ] && [ -n "$LOCKFILE_CHANGED" ] && [ -z "$DEP_JUSTIFIED" ]; then
  finding dependency WARN "lockfile changed with no manifest change — verify this"
  echo "                  is expected (e.g. a transitive update), not accidental"
else
  echo "PASS  dependency"
fi

# ── new TODO/FIXME without an owner ─────────────────────────────────
TODO_HITS=$(diff_for "$CODE_FILES" | grep -E '^\+' | grep -Ev '^\+\+\+' | grep -E 'TODO|FIXME' | grep -Ev 'TODO\([A-Za-z0-9_.-]+\)|FIXME\([A-Za-z0-9_.-]+\)' || true)
if [ -n "$TODO_HITS" ]; then
  # Always advisory, whatever check.fail_on says about debug leftovers.
  echo "WARN  leftovers   TODO/FIXME added with no owner — TODO(name) or a ticket ref:"
  echo "$TODO_HITS" | sed 's/^/              /'
  WARN=$((WARN + 1))
fi

# ── tests: new source without a matching test touch (heuristic) ────
SRC_CHANGED=$(echo "$CHANGED_FILES" | grep -E '\.(php|ts|tsx|js|jsx|py|rb|go)$' | grep -Ev '(^|/)(tests?|spec|__tests__)/' || true)
TEST_CHANGED=$(echo "$CHANGED_FILES" | grep -E '(^|/)(tests?|spec|__tests__)/' || true)
if [ -n "$SRC_CHANGED" ] && [ -z "$TEST_CHANGED" ]; then
  finding tests WARN "source changed with no test file touched — confirm"
  echo "                  this is XS/S-tier or already covered by an existing test"
else
  echo "PASS  tests"
fi

# ── methodology gate (advisory; silent unless waterfall or a typo) ──
# agile/hybrid/unset print nothing. Waterfall: source changed but the PRD or
# TRD has no approved_at, i.e. the Requirements/Design gate is not passed.
# Cannot tell an XS/S fix from feature work, so it only ever warns.
METHODOLOGY=$(sed -n 's/^[[:space:]]*methodology:[[:space:]]*\([A-Za-z]*\).*/\1/p' "$CONFIG" 2>/dev/null | head -1)
case "$METHODOLOGY" in
  ""|agile|hybrid) ;;
  waterfall)
    if [ -n "$SRC_CHANGED" ]; then
      UNAPPROVED=""
      for doc in docs/product/PRD.md docs/technical/TRD.md; do
        if [ ! -f "$doc" ] || ! grep -qE '^approved_at:[[:space:]]*[^[:space:]]+' "$doc"; then
          UNAPPROVED="$UNAPPROVED $doc"
        fi
      done
      if [ -n "$UNAPPROVED" ]; then
        # Hard-wired to WARN: it cannot tell an XS/S fix from feature work.
        echo "WARN  methodology waterfall: source changed but not approved:$UNAPPROVED"
        echo "                  ignore only for an XS/S fix; feature work needs the phase gate"
        WARN=$((WARN + 1))
      else
        echo "PASS  methodology"
      fi
    fi
    ;;
  *)
    echo "WARN  methodology unknown value '$METHODOLOGY' in .agent/config.yml"
    echo "                  (use agile, waterfall or hybrid; node scripts/set-methodology.cjs)"
    WARN=$((WARN + 1))
    ;;
esac

echo ""
echo "$FAIL failure(s), $WARN warning(s)."

if [ "$FAIL" -gt 0 ]; then
  echo "Commit blocked. Fix the FAIL findings above (see .agent/config.yml"
  echo "'check.fail_on' for what is fatal vs. advisory in this project)."
  exit 1
fi

exit 0
