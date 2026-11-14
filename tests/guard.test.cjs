// Unit cases for scripts/vibe-guard.cjs. Run: node tests/guard.test.cjs
"use strict";
const { decide } = require("../scripts/vibe-guard.cjs");

const policy = {
  deny: ["git push --force*", "git reset --hard*", "git clean -fd*", "rm -rf *", "php artisan migrate:fresh*", "*DROP TABLE*", "curl * | sh", "*--no-verify*"],
  confirm: ["php artisan migrate*", "git push*", "git merge*", "composer require *", "docker*"],
};

// [command, expected decision or null]
const cases = [
  // plain: the host already handles these; the guard must agree
  ["git clean -fd", "deny"],
  ["git merge --no-edit feature", "ask"],
  ["git status", null],
  // the observed failures
  ['bash -c "git clean -fd"', "deny"],
  ['sh -c "git merge --no-edit no-such-branch"', "ask"],
  // other wrappers
  ["bash -lc 'git reset --hard HEAD'", "deny"],
  ["/bin/sh -c 'rm -rf build'", "deny"],
  ['eval "git push --force origin main"', "deny"],
  ["sudo rm -rf /var/tmp/x", "deny"],
  ["env APP_ENV=prod php artisan migrate:fresh", "deny"],
  ["APP_ENV=prod php artisan migrate", "ask"],
  ["find . -name '*.log' | xargs rm -rf --", "deny"],
  ["nohup docker compose up", "ask"],
  ['bash -c "sh -c \'git clean -fdx\'"', "deny"],
  // chained and substituted
  ["cd app && git clean -fd", "deny"],
  ["git fetch; git reset --hard origin/main", "deny"],
  ["echo $(git push origin main)", "ask"],
  ["echo `git clean -fd`", "deny"],
  ["(git reset --hard)", "deny"],
  // deny wins over confirm
  ["git push --force origin main", "deny"],
  ["git push origin main", "ask"],
  // substring patterns from the policy itself
  ["mysql -e 'DROP TABLE users'", "deny"],
  ["git commit --no-verify -m x", "deny"],
  // not hits: mentions inside quotes, look-alikes
  ['git commit -m "undo git reset --hard"', null],
  ["git commit -m 'explain why rm -rf * is denied'", null],
  ['echo "git clean -fd"', null],
  ["grep -rn 'git merge' docs", null],
  ["git log --oneline | head -5", null],
  ["npm run test 2>&1 | tail -20", null],
  ["git status && git diff --stat", null],
  ["rm -r build", null],
  ["", null],
];

let failed = 0;
for (const [cmd, want] of cases) {
  const got = decide(cmd, policy);
  const have = got ? got.decision : null;
  if (have !== want) {
    failed++;
    console.error(`FAIL  ${JSON.stringify(cmd)}  want ${want}  got ${have}${got ? ` (${got.glob} on '${got.hit}')` : ""}`);
  }
}
process.stdout.write(`${cases.length - failed}/${cases.length} guard cases pass\n`);
process.exit(failed ? 1 : 0);
