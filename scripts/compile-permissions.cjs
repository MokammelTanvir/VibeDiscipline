#!/usr/bin/env node
/**
 * Compiles .agent/permissions.yml (the source of truth) into:
 *   - .claude/settings.json     (Claude Code deterministic tool permissions)
 *   - .claude/hooks/             (vibe-guard.cjs + its policy: catches wrapped
 *                                 commands the settings rules miss)
 *   - .githooks/pre-commit      (secret scan + vibe check, tool-agnostic)
 *   - .githooks/pre-push        (full test suite + branch/force-push policy)
 *   - docs/PERMISSIONS.md       (human-readable policy)
 *
 * This is a v0.1 minimal compiler: a small hand-rolled parser limited to
 * permissions.yml's fixed schema (nested lists of glob-like strings under
 * known keys). It intentionally avoids adding a YAML library dependency
 * to keep the engineering layer dependency-free. Replace with a real
 * YAML parser once the `vibe` CLI ships (see plan Section 44).
 *
 * Idempotent: running this twice produces identical output. In
 * .claude/settings.json only the "permissions" key is generated; other
 * top-level keys are preserved.
 *
 * Usage: node scripts/compile-permissions.cjs   (no arguments)
 */
"use strict";
const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "..");
const SRC = path.join(ROOT, ".agent", "permissions.yml");
const CONFIG_SRC = path.join(ROOT, ".agent", "config.yml");

function stripInlineComment(value) {
  // Strip a trailing " # comment" that isn't inside quotes. Our schema
  // never needs a literal " #" inside a value, so this simple rule is safe.
  if (value.startsWith('"')) return value;
  const idx = value.indexOf(" #");
  return idx === -1 ? value.trim() : value.slice(0, idx).trim();
}

function parsePermissionsYaml(text) {
  // Minimal parser for our fixed schema: top-level keys, nested keys,
  // and "- item" list entries. Good enough for permissions.yml only.
  const lines = text.split("\n");
  const root = {};
  const stack = [{ indent: -1, node: root }];

  for (let raw of lines) {
    const line = raw.replace(/\r$/, "");
    if (!line.trim() || line.trim().startsWith("#")) continue;
    const indent = line.match(/^ */)[0].length;
    const trimmed = line.trim();

    while (stack.length > 1 && indent <= stack[stack.length - 1].indent) {
      stack.pop();
    }
    const parent = stack[stack.length - 1].node;

    if (trimmed.startsWith("- ")) {
      const val = stripInlineComment(trimmed.slice(2).trim()).replace(
        /^"(.*)"$/,
        "$1"
      );
      if (!Array.isArray(parent.__list)) parent.__list = [];
      parent.__list.push(val);
      continue;
    }

    const m = trimmed.match(/^([A-Za-z0-9_.-]+):\s*(.*)$/);
    if (!m) continue;
    const key = m[1];
    let val = stripInlineComment(m[2]);

    if (val === "" || val === undefined) {
      const child = {};
      parent[key] = child;
      stack.push({ indent, node: child });
    } else if (/^\[.*\]$/.test(val)) {
      // Inline list: ["a", "b"] or [a, b].
      try {
        parent[key] = JSON.parse(val);
      } catch {
        parent[key] = val
          .slice(1, -1)
          .split(",")
          .map((v) => v.trim().replace(/^["'](.*)["']$/, "$1"))
          .filter(Boolean);
      }
    } else {
      val = val.replace(/^"(.*)"$/, "$1").replace(/^>\s*$/, "");
      parent[key] = val;
    }
  }

  // fold __list markers into arrays on their owning key
  function fold(node) {
    for (const k of Object.keys(node)) {
      if (k === "__list") continue;
      const v = node[k];
      if (v && typeof v === "object") {
        if (Array.isArray(v.__list)) {
          node[k] = v.__list;
        } else {
          fold(v);
        }
      }
    }
  }
  fold(root);
  return root;
}

function readSource() {
  const text = fs.readFileSync(SRC, "utf8");
  return parsePermissionsYaml(text);
}

/**
 * config.yml is optional and, per the config-resolution contract, its
 * absence must never break compilation — missing keys fall back to safe
 * defaults (protect_main_branch defaults to true: the stricter option,
 * suited to a PR-based team workflow).
 */
function readConfig() {
  if (!fs.existsSync(CONFIG_SRC)) return {};
  try {
    return parsePermissionsYaml(fs.readFileSync(CONFIG_SRC, "utf8"));
  } catch {
    return {};
  }
}

const MODES = ["auto", "guided", "strict"];

function resolveMode(policy) {
  const mode = policy.mode || "auto";
  if (!MODES.includes(mode)) {
    console.error(`[vibe] unknown mode '${mode}' in permissions.yml. Use: ${MODES.join(", ")}.`);
    process.exit(1);
  }
  return mode;
}

function toClaudeSettings(policy) {
  const mode = resolveMode(policy);
  const deny = (policy.commands?.deny || []).map((p) => `Bash(${p})`);
  const ask = (policy.commands?.confirm || []).map((p) => `Bash(${p})`);
  const allow = (policy.commands?.allow || []).map((p) => `Bash(${p})`);

  // A denied path is neither read nor edited; an allowed path is edited
  // without a prompt; a confirm path prompts.
  const fileDeny = (policy.files?.deny || []).flatMap((p) => [`Read(${p})`, `Edit(${p})`]);
  const fileAsk = (policy.files?.confirm || []).map((p) => `Edit(${p})`);
  const fileAllow = (policy.files?.allow || []).map((p) => `Edit(${p})`);

  // auto:   the allow-list runs freely, the confirm-list prompts.
  // guided: nothing runs freely; every command and every write prompts.
  // strict: as guided, and reads prompt too.
  // Deny always wins, in every mode.
  let allowed = [...allow, ...fileAllow];
  let asked = [...ask, ...fileAsk];
  if (mode === "guided") {
    allowed = [];
    asked = ["Bash", "Edit", "Write"];
  } else if (mode === "strict") {
    allowed = [];
    asked = ["Bash", "Edit", "Write", "Read", "Grep", "Glob", "WebFetch"];
  }

  return {
    "//": "GENERATED by scripts/compile-permissions.cjs from .agent/permissions.yml — do not hand-edit.",
    permissions: {
      allow: allowed,
      ask: asked,
      deny: [...deny, ...fileDeny],
    },
  };
}

function writeClaudeSettings(policy) {
  const dir = path.join(ROOT, ".claude");
  fs.mkdirSync(dir, { recursive: true });
  const target = path.join(dir, "settings.json");
  const generated = toClaudeSettings(policy);

  let existing = {};
  if (fs.existsSync(target)) {
    try {
      existing = JSON.parse(fs.readFileSync(target, "utf8"));
    } catch {
      existing = {};
    }
  }
  // Preserve hand-authored top-level keys and any hooks already there;
  // only "permissions" and our own guard entry are generated.
  const merged = { ...existing, ...generated };
  const hooks = mergeHooks(existing.hooks);
  if (Object.keys(hooks).length) merged.hooks = hooks;
  else delete merged.hooks;
  fs.writeFileSync(target, JSON.stringify(merged, null, 2) + "\n");
  return target;
}

const GUARD_COMMAND = 'node "$CLAUDE_PROJECT_DIR/.claude/hooks/vibe-guard.cjs"';

const HAS_GUARD = fs.existsSync(path.join(__dirname, "vibe-guard.cjs"));

function mergeHooks(existingHooks) {
  const hooks = { ...(existingHooks || {}) };
  const others = (hooks.PreToolUse || []).filter((e) => !JSON.stringify(e).includes("vibe-guard.cjs"));
  if (HAS_GUARD) {
    hooks.PreToolUse = [...others, { matcher: "Bash", hooks: [{ type: "command", command: GUARD_COMMAND }] }];
  } else if (others.length) hooks.PreToolUse = others;
  else delete hooks.PreToolUse;
  return hooks;
}

/**
 * Host rules match the start of each sub-command, so `bash -c "git clean -fd"`
 * slips past a deny on `git clean -fd*`. The guard (scripts/vibe-guard.cjs)
 * unwraps shell wrappers and re-tests the policy. It is copied next to a
 * generated policy file so the hook needs nothing outside .claude/.
 */
function writeGuardHook(policy) {
  const dir = path.join(ROOT, ".claude", "hooks");
  const source = path.join(__dirname, "vibe-guard.cjs");
  if (!fs.existsSync(source)) return null;
  fs.mkdirSync(dir, { recursive: true });
  const target = path.join(dir, "vibe-guard.cjs");
  fs.copyFileSync(source, target);
  fs.chmodSync(target, 0o755);
  const lists = {
    "//": "GENERATED by scripts/compile-permissions.cjs from .agent/permissions.yml — do not hand-edit.",
    deny: policy.commands?.deny || [],
    confirm: policy.commands?.confirm || [],
  };
  fs.writeFileSync(path.join(dir, "vibe-policy.json"), JSON.stringify(lists, null, 2) + "\n");
  return target;
}

function writeGitHooks(policy, config) {
  const dir = path.join(ROOT, ".githooks");
  fs.mkdirSync(dir, { recursive: true });

  const denyPatterns = (policy.commands?.deny || [])
    .map((p) => p.replace(/\*/g, ".*"))
    .join("|");

  // Default true (the stricter option) when config.yml or the key is
  // absent — matches the config-resolution contract's "conservative
  // default" rule. Explicitly "false" is the only way to disable it.
  const protectMainBranch = config?.git?.protect_main_branch !== "false";

  const branchGuard = protectMainBranch
    ? `branch="$(git rev-parse --abbrev-ref HEAD)"
if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
  echo "[vibe] refusing direct push to '$branch' — protect_main_branch is on"
  echo "[vibe] (.agent/config.yml: git.protect_main_branch)."
  echo "[vibe] push to a branch and open a PR, or set protect_main_branch:"
  echo "[vibe] false in config.yml if this project pushes to $branch directly."
  exit 1
fi

`
    : `# git.protect_main_branch is false in .agent/config.yml — direct pushes
# to main/master are allowed by this hook. Note this cannot distinguish
# a human push from an agent one; permissions.yml's commands.confirm
# entry for "git push*" is still the gate an agent goes through.

`;

  const preCommit = `#!/usr/bin/env bash
# GENERATED by scripts/compile-permissions.cjs from .agent/permissions.yml
# Do not hand-edit — edit permissions.yml and re-run the compiler.
set -euo pipefail

echo "[vibe] pre-commit: secret scan"
if command -v scripts/check.sh >/dev/null 2>&1 || [ -x scripts/check.sh ]; then
  scripts/check.sh --staged
else
  echo "[vibe] scripts/check.sh not found or not executable — skipping vibe check"
fi
`;

  const prePush = `#!/usr/bin/env bash
# GENERATED by scripts/compile-permissions.cjs from .agent/permissions.yml
# and .agent/config.yml (git.protect_main_branch) — do not hand-edit.
set -euo pipefail

${branchGuard}echo "[vibe] pre-push: denied command patterns are enforced by permissions.yml"
echo "[vibe] (deny patterns compiled: ${denyPatterns || "none"})"
`;

  fs.writeFileSync(path.join(dir, "pre-commit"), preCommit, { mode: 0o755 });
  fs.writeFileSync(path.join(dir, "pre-push"), prePush, { mode: 0o755 });
  fs.chmodSync(path.join(dir, "pre-commit"), 0o755);
  fs.chmodSync(path.join(dir, "pre-push"), 0o755);
  return dir;
}

function writeDocs(policy, config) {
  const dir = path.join(ROOT, "docs");
  fs.mkdirSync(dir, { recursive: true });
  const target = path.join(dir, "PERMISSIONS.md");

  const section = (title, items) =>
    items && items.length
      ? `### ${title}\n\n` + items.map((i) => `- \`${i}\``).join("\n") + "\n\n"
      : "";

  const protectMainBranch = config?.git?.protect_main_branch !== "false";

  const body = `# Permissions — Generated Reference

> GENERATED by \`scripts/compile-permissions.cjs\` from \`.agent/permissions.yml\`.
> Edit that file, then re-run \`node scripts/compile-permissions.cjs\`.

Mode: **${resolveMode(policy)}** (\`auto\`: the allow-list runs freely and the
confirm-list prompts · \`guided\`: every command and write prompts ·
\`strict\`: reads prompt too). Deny always wins.

## Commands

${section("Allowed", policy.commands?.allow)}${section(
    "Requires confirmation",
    policy.commands?.confirm
  )}${section("Denied", policy.commands?.deny)}

## Files

${section("Freely editable", policy.files?.allow)}${section(
    "Requires confirmation to touch",
    policy.files?.confirm
  )}${section("Never touched", policy.files?.deny)}

## Network

Advisory: no host setting expresses these, so only the agent reading this
policy applies them.

${section("Allowed", policy.network?.allow)}${section(
    "Requires confirmation",
    policy.network?.confirm
  )}${section("Denied", policy.network?.deny)}## Enforcement layers

1. Agent skills — knows the rule (weakest, can drift over a long session)
2. Host settings (\`.claude/settings.json\`) — deterministic tool-call interception,
   plus the guard hook (\`.claude/hooks/vibe-guard.cjs\`) for commands hidden
   inside shell wrappers such as \`bash -c "..."\`
3. Git hooks (\`.githooks/pre-commit\`, \`.githooks/pre-push\`) — tool-agnostic
4. CI (\`.github/workflows/quality-gates.yml\`) — the unbypassable backstop

Run \`git config core.hooksPath .githooks\` once per clone to activate layer 3
locally (the compiler attempts this automatically — see below).

## Branch policy

\`git.protect_main_branch\` in \`.agent/config.yml\` is **${protectMainBranch ? "on" : "off"}**
for this project — direct \`git push\` to \`main\`/\`master\` is
${protectMainBranch ? "blocked by the pre-push hook; push a branch and open a PR instead" : "allowed by the pre-push hook (this project pushes to it directly)"}.
This hook cannot distinguish a human push from an agent one — it only
sees a branch name — so it applies equally to both; an agent's own
\`git push*\` still goes through the CONFIRM gate above independently.
`;

  fs.writeFileSync(target, body);
  return target;
}

// Returns "set", "kept:<path>" when the project already points its hooks
// somewhere else (husky, lefthook: never taken over), or "failed".
function activateHooksPath() {
  const { execSync } = require("child_process");
  let current = "";
  try {
    current = execSync("git config --get core.hooksPath", { cwd: ROOT, stdio: ["ignore", "pipe", "ignore"] })
      .toString()
      .trim();
  } catch {
    current = ""; // unset, or not a git repository
  }
  if (current && current !== ".githooks") return `kept:${current}`;
  try {
    execSync("git config core.hooksPath .githooks", { cwd: ROOT, stdio: "ignore" });
    return "set";
  } catch {
    return "failed";
  }
}

function main() {
  if (process.argv.length > 2) {
    console.log("usage: node scripts/compile-permissions.cjs");
    console.log("Compiles .agent/permissions.yml into .claude/settings.json,");
    console.log(".githooks/ and docs/PERMISSIONS.md. Takes no arguments.");
    process.exit(/^(-h|--help)$/.test(process.argv[2]) ? 0 : 2);
  }
  if (!fs.existsSync(SRC)) {
    console.error(`[vibe] ${SRC} not found — nothing to compile.`);
    process.exit(1);
  }
  const policy = readSource();
  const config = readConfig();

  const settingsPath = writeClaudeSettings(policy);
  const guardPath = writeGuardHook(policy);
  const hooksDir = writeGitHooks(policy, config);
  const docsPath = writeDocs(policy, config);
  const hooksActivated = activateHooksPath();

  console.log("[vibe] compiled permissions.yml ->");
  console.log(`  ${path.relative(ROOT, settingsPath)}`);
  if (guardPath) console.log(`  ${path.relative(ROOT, guardPath)}`);
  console.log(`  ${path.relative(ROOT, hooksDir)}/pre-commit`);
  console.log(`  ${path.relative(ROOT, hooksDir)}/pre-push`);
  console.log(`  ${path.relative(ROOT, docsPath)}`);
  if (hooksActivated === "set") {
    console.log("[vibe] git core.hooksPath set to .githooks");
  } else if (hooksActivated.startsWith("kept:")) {
    console.log(`[vibe] core.hooksPath is already '${hooksActivated.slice(5)}' — left alone.`);
    console.log("[vibe] call .githooks/pre-commit and .githooks/pre-push from your own hooks to use them.");
  } else {
    console.log("[vibe] could not set git core.hooksPath automatically — run: git config core.hooksPath .githooks");
  }
}

main();
