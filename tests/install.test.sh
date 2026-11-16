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
ok "config is the clean template"   'grep -q "warn_on: \[dependency, tests\]" .agent/config.yml && ! grep -q "evals/fixtures" .agent/config.yml'
git add -A >/dev/null 2>&1; echo "{}" > package.json; git add package.json
ok "first commit of a manifest is not blocked" 'git -c user.email=t@t -c user.name=t commit -qm first >/dev/null 2>&1'
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

echo "== G stack presets"
for pair in "package.json:node" "pyproject.toml:python" "artisan:laravel" "README.md:generic"; do
  marker="${pair%%:*}"; want="${pair##*:}"
  mkdir -p "$S/g-$want" && cd "$S/g-$want" && git init -q && touch "$marker"
  "$I" "$S/g-$want" >"$S/g-$want.log" 2>&1
  ok "$marker -> $want preset, compiled" 'grep -q "permissions preset: $want (detected)" "$S/g-$want.log" && grep -q GENERATED .claude/settings.json'
  ok "$want keeps the universal deny list" 'grep -q "git reset --hard" .claude/hooks/vibe-policy.json && grep -q "id_rsa" .claude/settings.json'
  ok "$want: presets directory not copied" '[ ! -e .agent/presets ]'
done
ok "node preset has npm, not artisan" 'grep -q "npm test" "$S/g-node/.agent/permissions.yml" && ! grep -q artisan "$S/g-node/.agent/permissions.yml"'
ok "python preset has pytest"          'grep -q "pytest" "$S/g-python/.agent/permissions.yml"'
mkdir -p "$S/g-forced" && touch "$S/g-forced/package.json" && "$I" "$S/g-forced" --stack python >"$S/g-forced.log" 2>&1
ok "--stack overrides detection"       'grep -q "permissions preset: python$" "$S/g-forced.log" && grep -q pytest "$S/g-forced/.agent/permissions.yml"'
"$I" "$S/e" --stack cobol >/dev/null 2>&1; ok "unknown stack exits 2" '[ $? -eq 2 ]'

echo "== H upgrade"
cd "$S/a"
echo "# local edit" >> .agent/skills/git/SKILL.md
echo "# my rule" >> .agent/permissions.yml
echo "mine: true" >> .agent/config.yml
echo "working notes" > .agent/state.md
"$I" "$S/a" --upgrade >"$S/h.log" 2>&1; echo "  exit=$?"
ok "skill restored from source"        'cmp -s .agent/skills/git/SKILL.md "$REPO/.agent/skills/git/SKILL.md"'
ok "updated file is listed"            'grep -q ".agent/skills/git/SKILL.md" "$S/h.log"'
ok "permissions.yml kept"              'grep -q "# my rule" .agent/permissions.yml'
ok "config.yml kept"                   'grep -q "mine: true" .agent/config.yml && grep -q "methodology: agile" .agent/config.yml'
ok "state.md kept"                     'grep -q "working notes" .agent/state.md'
ok "VERSION records the upgrade"       'grep -q "^upgraded: " .agent/VERSION && grep -q "^installed: " .agent/VERSION'
"$I" "$S/a" --upgrade >"$S/h2.log" 2>&1
ok "second upgrade: already up to date" 'grep -q "already up to date" "$S/h2.log"'
cd "$S/c" && sed -i.bak 's/^## Ceremony tiers.*/## OLD HEADING/' AGENTS.md && rm AGENTS.md.bak
"$I" "$S/c" --upgrade >"$S/h3.log" 2>&1
ok "AGENTS.md block refreshed, theirs kept" '! grep -q "OLD HEADING" AGENTS.md && grep -q "Use tabs." AGENTS.md && [ "$(grep -c "vibediscipline:start" AGENTS.md)" = 1 ]'
mkdir -p "$S/h-none" && "$I" "$S/h-none" --upgrade >/dev/null 2>&1; ok "upgrade without an install exits 2" '[ $? -eq 2 ]'

echo "== F bad input"
"$I" >/dev/null 2>&1; ok "no target exits 2" '[ $? -eq 2 ]'
"$I" "$S/nope" >/dev/null 2>&1; ok "missing dir exits 2" '[ $? -eq 2 ]'
"$I" "$REPO" >/dev/null 2>&1; ok "installing into itself exits 2" '[ $? -eq 2 ]'
"$I" "$S/e" --methodology scrum >/dev/null 2>&1; ok "bad methodology exits 2" '[ $? -eq 2 ]'

echo
[ "$FAILED" -eq 0 ] && echo "install: all scenarios pass" || echo "install: $FAILED check(s) FAILED"
exit "$FAILED"
