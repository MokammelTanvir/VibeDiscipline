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

echo "== doctor finds breakage"
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

echo
[ "$FAILED" -eq 0 ] && echo "cli: all scenarios pass" || echo "cli: $FAILED check(s) FAILED"
exit "$FAILED"
