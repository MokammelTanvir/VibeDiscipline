#!/usr/bin/env bash
# Scenarios for scripts/check.sh (vibe check) in a throwaway repo.
# Run: tests/check.test.sh
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
S="$(mktemp -d)"; trap 'rm -r "$S"' EXIT
FAILED=0
OUT=""; RC=0
check() { OUT="$(scripts/check.sh "$@" 2>&1)"; RC=$?; }
# expect <label> <exit code> <regex that must match> [regex that must not match]
expect() {
  local bad=""
  [ "$RC" -eq "$2" ] || bad="exit $RC, wanted $2"
  echo "$OUT" | grep -qE -- "$3" || bad="${bad:+$bad; }missing /$3/"
  if [ -n "${4:-}" ] && echo "$OUT" | grep -qE -- "$4"; then bad="${bad:+$bad; }unexpected /$4/"; fi
  if [ -z "$bad" ]; then echo "  ok   $1"; else echo "  FAIL $1 ($bad)"; echo "$OUT" | sed 's/^/         /'; FAILED=$((FAILED + 1)); fi
}

cd "$S" || exit 1
git init -q && git config user.email t@t && git config user.name t
mkdir -p scripts app legacy docs/tasks .agent
cp "$REPO/scripts/check.sh" scripts/
echo '{}' > package.json
for f in app/A.php app/B.php other.php legacy/x.php; do echo '<?php' > "$f"; done
git add -A && git commit -qm seed

check; expect "clean tree" 0 "no changes to inspect"

echo 'dd($x);' >> app/A.php; echo '{"a":1}' > package.json
check; expect "no config: leftover fails, dependency and tests warn" 1 "^FAIL  leftovers" "^FAIL  dependency"
echo "$OUT" | grep -q '^WARN  dependency' && echo "$OUT" | grep -q '^WARN  tests' || { echo "  FAIL defaults are warnings"; FAILED=$((FAILED + 1)); }
git checkout -q app/A.php

cat > .agent/config.yml <<'E'
check:
  fail_on: [scope, leftovers, secrets, dependency]
  warn_on: [tests, duplication]
  ignore: ["legacy/**", ".agent/**"]
E
check; expect "config: unjustified manifest change fails" 1 "^FAIL  dependency"

cat > docs/tasks/TASK-001-x.md <<'E'
---
id: TASK-001
status: in-progress
---
## Affected Areas
`app/{A,B}.php` (new), `src/*`, `package.json`: adds a dependency on foo.
## Notes
`other.php` is named outside the section and must not count
E
echo '//c' >> app/B.php; echo '//c' >> other.php; echo 'dd(1);' >> legacy/x.php
check; expect "scope: only the file outside Affected Areas fails" 1 "^ +other\.php$" "^ +app/B\.php$"
expect "dependency justified by the task doc" 1 "^PASS  dependency"
expect "ignored path is not scanned" 1 "^PASS  leftovers" "legacy/x\.php"

git checkout -q other.php
check; expect "all in scope passes" 0 "^PASS  scope"

sed -i.bak 's/in-progress/done/' docs/tasks/TASK-001-x.md && rm docs/tasks/TASK-001-x.md.bak
check; expect "no task in progress: scope skipped" 0 "^SKIP  scope"
check --task 1; expect "--task selects a finished task" 0 "^PASS  scope"
check --task 999; expect "--task with no match exits 2" 2 "no task doc matches"
check --bogus; expect "unknown argument exits 2" 2 "unknown argument"

cat > .agent/config.yml <<'E'
check:
  fail_on:
    - secrets
  warn_on:
    - leftovers   # downgraded
    - scope
  ignore: [".agent/**"]
other:
  fail_on: [tests]
E
echo 'var_dump(1);' >> app/A.php; echo x >> other.php
check --task TASK-001; expect "block-form lists: leftovers and scope downgraded" 0 "^WARN  leftovers" "^FAIL"
expect "a fail_on under another key is not read" 0 "^WARN  tests"
git add -A
check --staged --task=001; expect "--staged sees the same" 0 "^WARN  scope" "^FAIL"

git commit -qm more
printf 'api_key = "%s"\n' abcdefghijklmnop1234 > app/C.php   # built at run time so this file holds no literal
check; expect "secret literal fails" 1 "^FAIL  secrets"
rm app/C.php
printf '#!/bin/sh\nnode -e "console.log(1)"\necho "dd(1);"\n' > tool.sh
check; expect "debug patterns are per language: none in a shell script" 0 "^PASS  leftovers"
echo 'console.log(1)' > app/ui.js; echo 'console.log(1)' > scripts/cli.js; echo 'breakpoint()' > app/job.py
# leftovers is in warn_on in the config written above, so these are warnings
check; expect "console.log in app js and breakpoint() in python are reported" 0 "^WARN  leftovers"
[ "$(echo "$OUT" | grep -c 'console\.log(1)')" = 1 ] && echo "$OUT" | grep -q 'breakpoint()' \
  && echo "  ok   scripts/ is exempt from console.log; python breakpoint reported" \
  || { echo "  FAIL per-language leftovers"; echo "$OUT"; FAILED=$((FAILED + 1)); }

echo
[ "$FAILED" -eq 0 ] && echo "check: all scenarios pass" || echo "check: $FAILED scenario(s) FAILED"
exit "$FAILED"
