#!/usr/bin/env node
/**
 * PreToolUse hook for Bash (Claude Code). Source of the guard that
 * scripts/compile-permissions.cjs copies to .claude/hooks/vibe-guard.cjs,
 * next to a generated vibe-policy.json holding the deny and confirm lists.
 *
 * Host permission rules match the start of each sub-command, so
 * `bash -c "git clean -fd"` slips past a deny on `git clean -fd*` (observed
 * 2026-11-15, evals/results/enforcement-2026-11-15.md). The guard unwraps
 * shell wrappers (bash -c, eval, env, sudo, xargs, $(...)) and chained
 * commands, then tests what is inside against the policy.
 *
 * Silent when nothing matches. Fails open: on input or a policy file it
 * cannot read it stays silent, and the host's own rules still apply.
 */
"use strict";
const fs = require("fs");
const path = require("path");

const toRegex = (glob) =>
  new RegExp("^" + glob.split("*").map((s) => s.replace(/[.+?^${}()|[\]\\]/g, "\\$&")).join(".*") + "$", "s");

const PREFIX = /^(?:(?:sudo|command|builtin|nohup|time|exec|env|xargs)\s+(?:-\S+\s+)*|[A-Za-z_][A-Za-z0-9_]*=\S*\s+)/;
const SHELL = /^(?:\S*\/)?(?:bash|sh|zsh|dash|ksh)\s+(?:-[A-Za-z]+\s+)*-[A-Za-z]*c\s+|^eval\s+/;

function unquote(s) {
  s = s.trim();
  const q = s[0];
  if (q === '"' || q === "'") {
    const end = s.lastIndexOf(q);
    if (end > 0) return s.slice(1, end);
  }
  return s;
}

// Split on ; & | and newlines, but not inside quotes.
function split(cmd) {
  const out = [];
  let cur = "";
  let quote = null;
  for (let i = 0; i < cmd.length; i++) {
    const c = cmd[i];
    if (quote) {
      if (c === quote && cmd[i - 1] !== "\\") quote = null;
      cur += c;
    } else if (c === '"' || c === "'") {
      quote = c;
      cur += c;
    } else if (c === ";" || c === "\n" || c === "|" || c === "&") {
      out.push(cur);
      cur = "";
    } else cur += c;
  }
  out.push(cur);
  return out.map((s) => s.trim()).filter(Boolean);
}

// Every command string the shell would actually run, wrappers peeled off.
function candidates(cmd, depth = 0, acc = []) {
  if (depth > 4) return acc;
  for (let seg of split(cmd)) {
    seg = seg.replace(/^[({]\s*/, "");
    acc.push(seg);
    let s = seg;
    for (let m = s.match(PREFIX); m; m = s.match(PREFIX)) {
      s = s.slice(m[0].length);
      acc.push(s);
    }
    const shell = s.match(SHELL);
    if (shell) candidates(unquote(s.slice(shell[0].length)), depth + 1, acc);
    // Substitutions run inside double quotes, never inside single quotes.
    const live = seg.replace(/'[^']*'/g, "''");
    for (const sub of live.matchAll(/\$\(([^()]*)\)|`([^`]*)`/g)) {
      candidates(sub[1] || sub[2] || "", depth + 1, acc);
    }
  }
  return acc;
}

// -> { decision: "deny" | "ask", glob, hit } or null
function decide(command, policy) {
  const found = candidates(String(command || ""));
  for (const [decision, list] of [["deny", policy.deny || []], ["ask", policy.confirm || []]]) {
    for (const glob of list) {
      const re = toRegex(glob);
      const hit = found.find((s) => re.test(s));
      if (hit) return { decision, glob, hit };
    }
  }
  return null;
}

function main() {
  let input = "";
  process.stdin.on("data", (c) => (input += c)).on("end", () => {
    let event;
    let policy;
    try {
      event = JSON.parse(input);
      policy = JSON.parse(fs.readFileSync(path.join(__dirname, "vibe-policy.json"), "utf8"));
    } catch {
      process.exit(0);
    }
    if (!event || event.tool_name !== "Bash") process.exit(0);
    const r = decide(event.tool_input && event.tool_input.command, policy);
    if (!r) process.exit(0);
    const reason =
      r.decision === "deny"
        ? `VibeDiscipline: '${r.hit}' matches the deny rule '${r.glob}' in .agent/permissions.yml. Stop and tell the human; do not try an equivalent command.`
        : `VibeDiscipline: '${r.hit}' matches the confirm rule '${r.glob}' in .agent/permissions.yml and needs the human's approval.`;
    process.stdout.write(
      JSON.stringify({
        hookSpecificOutput: {
          hookEventName: "PreToolUse",
          permissionDecision: r.decision,
          permissionDecisionReason: reason,
        },
      })
    );
  });
}

if (require.main === module) main();
module.exports = { decide, candidates };
