#!/usr/bin/env bash
# Scenarios for bin/vibe.cjs in throwaway directories.
# Run: tests/cli.test.sh
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; V="$REPO/bin/vibe.cjs"
S="$(mktemp -d)"; trap 'rm -r "$S"' EXIT
FAILED=0
ok() { if eval "$2"; then echo "  ok   $1"; else echo "  FAIL $1"; FAILED=$((FAILED + 1)); fi; }

ok "bin is executable"           '[ -x "$V" ]'
node "$V" help >"$S/help.log" 2>&1;   ok "help exits 0 and lists commands" '[ $? -eq 0 ] && grep -q "doctor" "$S/help.log"'
node "$V" >"$S/none.log" 2>&1;        ok "no command prints help"          '[ $? -eq 0 ] && grep -q "Usage: vibe" "$S/none.log"'
node "$V" frobnicate >/dev/null 2>&1; ok "unknown command exits 2"         '[ $? -eq 2 ]'
ok "version matches .agent/VERSION and package.json" \
  '[ "$(node "$V" version)" = "$(head -1 "$REPO/.agent/VERSION")" ] && [ "$(node -p "require(\"$REPO/package.json\").version")" = "$(head -1 "$REPO/.agent/VERSION")" ]'

echo "== doctor on an empty directory"
mkdir -p "$S/empty"
node "$V" doctor "$S/empty" >"$S/d0.log" 2>&1; ok "exits 1 and points at init" '[ $? -eq 1 ] && grep -q "fix: vibe init" "$S/d0.log"'

echo "== init, then doctor"
mkdir -p "$S/p" && cd "$S/p" && git init -q && git config user.email t@t && git config user.name t && echo '{}' > package.json
node "$V" init --methodology agile >"$S/init.log" 2>&1; ok "init in the current directory exits 0" '[ $? -eq 0 ]'
ok "node preset chosen"          'grep -q "permissions preset: node (detected)" "$S/init.log"'
ok "installed"                   '[ -f .agent/skills/planning/SKILL.md ] && [ -f AGENTS.md ] && [ -f .claude/hooks/vibe-guard.cjs ]'
node "$V" doctor >"$S/d1.log" 2>&1; rc=$?
ok "doctor exits 0 on a fresh install" '[ "$rc" -eq 0 ] && grep -q "^0 problem" "$S/d1.log"'
ok "doctor proves the guard works"     'grep -q "guard hook blocks a wrapped denied command" "$S/d1.log"'
ok "doctor warns about recon only"     'grep -q "stack.lock.yml" "$S/d1.log" && [ "$(grep -c "  WARN" "$S/d1.log")" = 1 ]'

echo "== output modes"
node "$V" init >"$S/again.log" 2>&1; ok "init on an existing install changes nothing and points at upgrade" '[ $? -eq 0 ] && grep -q "already installed" "$S/again.log" && grep -q "vibe upgrade" "$S/again.log"'
node "$V" doctor >"$S/plain.log" 2>&1; ok "piped output has no escape codes" '! grep -q "$(printf "\033")" "$S/plain.log" && ! grep -q "$(printf "\033")" "$S/help.log"'
FORCE_COLOR=1 node "$V" doctor >"$S/color.log" 2>&1; ok "FORCE_COLOR gives the styled report" 'grep -q "▌ VibeDiscipline" "$S/color.log" && grep -q "✔" "$S/color.log" && grep -q "Enforcement" "$S/color.log"'
FORCE_COLOR=1 node "$V" init >"$S/color2.log" 2>&1; ok "styled init on an existing install does not prompt without a terminal" '[ $? -eq 0 ] && grep -q "already installed" "$S/color2.log"'
NO_COLOR=1 FORCE_COLOR=0 node "$V" help >"$S/nc.log" 2>&1; ok "FORCE_COLOR=0 is plain" '! grep -q "$(printf "\033")" "$S/nc.log"'

echo "== doctor finds breakage"
cp scripts/check.sh "$S/check.keep"; echo "# old copy" > scripts/check.sh
node "$V" doctor >"$S/stale.log" 2>&1
ok "an outdated script is reported even when the version file matches" 'grep -q "differ from version" "$S/stale.log" && grep -q "scripts/check.sh" "$S/stale.log" && grep -q "fix: vibe upgrade" "$S/stale.log"'
cp "$S/check.keep" scripts/check.sh
rm .claude/hooks/vibe-policy.json
sleep 1; touch .agent/permissions.yml
node "$V" doctor >"$S/d2.log" 2>&1
ok "missing guard policy and stale settings are reported" 'grep -q "guard hook not installed" "$S/d2.log" && grep -q "newer than the compiled settings" "$S/d2.log"'
node "$V" compile >"$S/compile.log" 2>&1; ok "compile exits 0 and bridges" '[ $? -eq 0 ] && grep -q "bridged" "$S/compile.log"'
node "$V" doctor >"$S/d3.log" 2>&1;       ok "doctor is clean again after compile" 'grep -q "^0 problem" "$S/d3.log" && ! grep -q "guard hook not" "$S/d3.log"'
sed -i.bak 's/methodology: agile/methodology: scrum/' .agent/config.yml && rm .agent/config.yml.bak
node "$V" doctor >"$S/d4.log" 2>&1;       ok "unknown methodology fails doctor" '[ $? -eq 1 ] && grep -q "unknown methodology" "$S/d4.log"'

echo "== project commands"
node "$V" methodology waterfall >/dev/null 2>&1; ok "methodology sets the value" 'grep -q "methodology: waterfall" .agent/config.yml'
node "$V" methodology --show >"$S/m.log" 2>&1;   ok "methodology --show"         'grep -q waterfall "$S/m.log"'
git add -A && git commit -qm install
node "$V" check >"$S/c.log" 2>&1;                ok "check on a clean tree"      '[ $? -eq 0 ] && grep -q "no changes" "$S/c.log"'
printf 'const a = 1;\nconsole.log(a);\n' > index.js
node "$V" check >"$S/c2.log" 2>&1;               ok "check fails on a debug leftover" '[ $? -eq 1 ] && grep -q "leftovers" "$S/c2.log"'
rm index.js
echo "# local" >> .agent/skills/git/SKILL.md
node "$V" upgrade >"$S/u.log" 2>&1;              ok "upgrade restores an edited skill" '[ $? -eq 0 ] && cmp -s .agent/skills/git/SKILL.md "$REPO/.agent/skills/git/SKILL.md"'
cd "$S/empty"
node "$V" check >/dev/null 2>&1;                 ok "check outside a project exits 2" '[ $? -eq 2 ]'

echo "== uninstall"
mkdir -p "$S/u1" && cd "$S/u1" && git init -q && git config user.email t@t && git config user.name t
echo "hello" > app.txt && git add -A && git commit -qm seed
node "$V" init --yes >/dev/null 2>&1
node "$V" uninstall >"$S/un0.log" 2>&1;           ok "without --yes and without a terminal it refuses" '[ $? -eq 2 ] && [ -d .agent ]'
node "$V" uninstall --dry-run >"$S/un1.log" 2>&1; ok "--dry-run lists and removes nothing" '[ $? -eq 0 ] && grep -q "delete .agent" "$S/un1.log" && [ -d .agent ] && [ -f AGENTS.md ]'
node "$V" uninstall --yes >"$S/un2.log" 2>&1;     ok "--yes exits 0" '[ $? -eq 0 ]'
ok "a fresh install is removed without a trace" '[ -z "$(git status --porcelain)" ] && [ ! -e .agent ] && [ ! -e .claude ] && [ ! -e AGENTS.md ] && [ ! -e scripts ] && [ ! -e docs ]'
ok "git hooks path is unset"        '[ -z "$(git config --get core.hooksPath)" ]'
node "$V" uninstall --yes >"$S/un3.log" 2>&1;     ok "running it again says nothing to do" '[ $? -eq 0 ] && grep -q "not installed" "$S/un3.log"'

mkdir -p "$S/u2/.claude/skills/mine" "$S/u2/scripts" "$S/u2/docs" && cd "$S/u2" && git init -q
printf '# My rules\nUse tabs.\n' > AGENTS.md
printf '# My notes\nBe terse.\n' > CLAUDE.md
echo '{"model":"x"}' > .claude/settings.json
echo "my skill" > .claude/skills/mine/SKILL.md
echo 'echo mine' > scripts/build.sh
echo "notes" > docs/notes.md
node "$V" init --yes >/dev/null 2>&1
mkdir -p docs/tasks && echo "task" > docs/tasks/TASK-001.md
node "$V" uninstall --yes >"$S/un4.log" 2>&1
ok "their AGENTS.md is back to their own text" '[ "$(cat AGENTS.md)" = "$(printf "# My rules\nUse tabs.")" ]'
ok "their CLAUDE.md is back to their own text" '[ "$(cat CLAUDE.md)" = "$(printf "# My notes\nBe terse.")" ]'
ok "their settings key survives, ours are gone" 'grep -q "\"model\"" .claude/settings.json && ! grep -q "permissions\|vibe-guard\|GENERATED" .claude/settings.json'
ok "their skill, script and docs survive" '[ -f .claude/skills/mine/SKILL.md ] && [ -f scripts/build.sh ] && [ -f docs/notes.md ] && [ -f docs/tasks/TASK-001.md ]'
ok "ours are gone"                  '[ ! -e .agent ] && [ ! -e .githooks ] && [ ! -e scripts/check.sh ] && [ ! -e docs/PERMISSIONS.md ] && [ -z "$(ls .claude/skills | grep vibe-)" ] && [ ! -e .claude/hooks ]'
ok "task docs are reported as kept" 'grep -q "docs/tasks" "$S/un4.log"'

echo
[ "$FAILED" -eq 0 ] && echo "cli: all scenarios pass" || echo "cli: $FAILED check(s) FAILED"
exit "$FAILED"
