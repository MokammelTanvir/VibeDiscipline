#!/usr/bin/env bash
# Scenarios for scripts/install.sh, each in a throwaway directory.
# Run: tests/install.test.sh
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"; I="$REPO/scripts/install.sh"
S="$(mktemp -d)"; trap 'rm -r "$S"' EXIT
FAILED=0
ok() { if eval "$2"; then echo "  ok   $1"; else echo "  FAIL $1"; FAILED=$((FAILED + 1)); fi; }

echo "== A empty git project"
mkdir -p "$S/a" && (cd "$S/a" && git init -q)
"$I" "$S/a" --methodology agile >"$S/a.log" 2>&1; echo "  exit=$?"
cd "$S/a"
ok "skills copied"                 '[ -f .agent/skills/planning/SKILL.md ]'
ok "no state.md / stack.lock"       '[ ! -e .agent/state.md ] && [ ! -e .agent/stack.lock.yml ]'
ok "AGENTS.md created, no markers"  '[ -f AGENTS.md ] && ! grep -q vibediscipline:start AGENTS.md'
ok "CLAUDE.md is the 2-line pointer" '[ "$(wc -l < CLAUDE.md | tr -d " ")" = 2 ]'
ok "config has no stack block"      '! grep -qE "^stack:|laravel" .agent/config.yml'
ok "config still has workflow+check" 'grep -q "^workflow:" .agent/config.yml && grep -q "^check:" .agent/config.yml'
ok "methodology agile"              'grep -q "methodology: agile" .agent/config.yml'
ok "VERSION written, governed"      'grep -q "tier: governed" .agent/VERSION'
ok "settings compiled"              'grep -q GENERATED .claude/settings.json'
ok "hooksPath set"                  '[ "$(git config core.hooksPath)" = .githooks ]'
ok "check.sh runs"                  'scripts/check.sh >/dev/null 2>&1'
ok "install.sh itself not copied"   '[ ! -e scripts/install.sh ]'
ok "guard hook installed"           '[ -f .claude/hooks/vibe-guard.cjs ] && [ -f .claude/hooks/vibe-policy.json ] && grep -q vibe-guard .claude/settings.json'
ok "guard denies a wrapped command" 'echo "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"bash -c \\\"git clean -fd\\\"\"}}" | node .claude/hooks/vibe-guard.cjs | grep -q "\"permissionDecision\":\"deny\""'
ok "skill stubs bridged"            '[ -f .claude/skills/vibe-planning/SKILL.md ] && [ "$(ls .claude/skills | wc -l | tr -d " ")" = 6 ]'

echo "== B re-run on A (idempotent)"
cp AGENTS.md "$S/agents.before"
"$I" "$S/a" >"$S/b.log" 2>&1; echo "  exit=$?"
ok "AGENTS.md unchanged"            'cmp -s AGENTS.md "$S/agents.before"'
ok "reports kept files"             'grep -q "kept existing files" "$S/b.log"'
ok "methodology still agile"        'grep -q "methodology: agile" .agent/config.yml'

echo "== C project with its own files"
mkdir -p "$S/c/.claude/skills/mine" "$S/c/scripts" && cd "$S/c" && git init -q && git config core.hooksPath .husky
echo "my skill" > .claude/skills/mine/SKILL.md
printf '# My rules\nUse tabs.\n' > AGENTS.md
printf '# My claude notes\nBe terse.\n' > CLAUDE.md
printf '{"permissions":{"allow":["Bash(make *)"]},"model":"x"}\n' > .claude/settings.json
echo 'echo mine' > scripts/check.sh
"$I" "$S/c" >"$S/c.log" 2>&1; echo "  exit=$?"
ok "their AGENTS.md text kept, below ours" 'grep -q "Use tabs." AGENTS.md && [ "$(head -1 AGENTS.md)" = "<!-- vibediscipline:start -->" ] && [ "$(grep -n "Use tabs" AGENTS.md | cut -d: -f1)" -gt "$(grep -n "vibediscipline:end" AGENTS.md | cut -d: -f1)" ]'
ok "their CLAUDE.md kept + pointer" 'grep -q "Be terse." CLAUDE.md && head -1 CLAUDE.md | grep -q AGENTS.md'
ok "their settings.json untouched"  'grep -q "make \*" .claude/settings.json && ! grep -q GENERATED .claude/settings.json'
ok "skill stubs still bridged"      '[ -f .claude/skills/vibe-recon/SKILL.md ]'
ok "their scripts/check.sh kept"    'grep -q "echo mine" scripts/check.sh'
ok "hooksPath still .husky"         '[ "$(git config core.hooksPath)" = .husky ]'
ok "log explains settings skip"     'grep -q "NOT compiled" "$S/c.log"'
ok "their own skill untouched"      'grep -q "my skill" .claude/skills/mine/SKILL.md'
"$I" "$S/c" >"$S/c2.log" 2>&1
ok "second run: AGENTS.md has one marker" '[ "$(grep -c "vibediscipline:start" AGENTS.md)" = 1 ]'
ok "second run: CLAUDE.md pointer once"   '[ "$(grep -c "the constitution for this repository" CLAUDE.md)" = 1 ]'

echo "== D skills only"
mkdir -p "$S/d" && "$I" "$S/d" --skills-only >"$S/d.log" 2>&1; echo "  exit=$?"
cd "$S/d"
ok "only .agent/skills exists"      '[ -d .agent/skills ] && [ "$(ls -A | tr "\n" " ")" = ".agent " ] && [ "$(ls -A .agent | tr "\n" " ")" = "skills " ]'

echo "== E dry run"
mkdir -p "$S/e" && "$I" "$S/e" --dry-run >"$S/e.log" 2>&1; echo "  exit=$?"
ok "nothing written"                '[ -z "$(ls -A "$S/e")" ]'
ok "prints would-lines"             'grep -q "would: copy .agent/skills/planning/SKILL.md" "$S/e.log"'

echo "== F bad input"
"$I" >/dev/null 2>&1; ok "no target exits 2" '[ $? -eq 2 ]'
"$I" "$S/nope" >/dev/null 2>&1; ok "missing dir exits 2" '[ $? -eq 2 ]'
"$I" "$REPO" >/dev/null 2>&1; ok "installing into itself exits 2" '[ $? -eq 2 ]'
"$I" "$S/e" --methodology scrum >/dev/null 2>&1; ok "bad methodology exits 2" '[ $? -eq 2 ]'

echo
[ "$FAILED" -eq 0 ] && echo "install: all scenarios pass" || echo "install: $FAILED check(s) FAILED"
exit "$FAILED"
