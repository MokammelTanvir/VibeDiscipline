#!/usr/bin/env node
/**
 * vibe — the VibeDiscipline command line. Zero dependencies.
 *
 *   npx github:MokammelTanvir/VibeDiscipline init
 *
 * `init` and `upgrade` run this package's installer against a project.
 * `check`, `compile` and `methodology` run the scripts already installed in
 * the project, so they keep working without the package. `doctor` only reads.
 */
"use strict";
const fs = require("fs");
const path = require("path");
const { spawnSync } = require("child_process");

const PKG = path.resolve(__dirname, "..");
const VERSION = fs.readFileSync(path.join(PKG, ".agent", "VERSION"), "utf8").split("\n")[0].trim();

const HELP = `vibe ${VERSION} — VibeDiscipline

Usage: vibe <command> [options]

  init [dir]            install into a project (default: current directory)
      --stack <s>         auto | laravel | node | python | generic
      --methodology <m>   agile | waterfall | hybrid
      --skills-only       copy .agent/skills/ and nothing else
      --dry-run           show what would happen
      --force             overwrite files that already exist
  upgrade [dir]         refresh skills, packs, adapters and scripts;
                        keeps your config, permissions and state
  doctor [dir]          check an installation and say how to fix it
  check [--staged] [--task <id>]
                        vibe check: scope, secrets, leftovers, dependency, tests
  compile               permissions.yml -> .claude/settings.json, hooks, docs
  methodology [m|--show]
                        show or set agile | waterfall | hybrid
  version               print the version
  help                  print this

Guide: https://github.com/MokammelTanvir/VibeDiscipline/blob/main/docs/GUIDE.md`;

function run(cmd, args, opts = {}) {
  const r = spawnSync(cmd, args, { stdio: "inherit", ...opts });
  if (r.error) {
    console.error(`[vibe] could not run ${cmd}: ${r.error.message}`);
    return 1;
  }
  return r.status === null ? 1 : r.status;
}

// A leading argument that is not an option is the target directory.
function splitDir(args) {
  if (args.length && !args[0].startsWith("-")) return [args[0], args.slice(1)];
  return [".", args];
}

function projectScript(name) {
  const p = path.join(process.cwd(), "scripts", name);
  if (fs.existsSync(p)) return p;
  console.error(`[vibe] scripts/${name} not found here. Run this from a project root, after \`vibe init\`.`);
  process.exit(2);
}

function install(args, extra) {
  const [dir, rest] = splitDir(args);
  if (!fs.existsSync(dir) || !fs.statSync(dir).isDirectory()) {
    console.error(`[vibe] not a directory: ${dir}`);
    return 2;
  }
  return run("bash", [path.join(PKG, "scripts", "install.sh"), dir, ...extra, ...rest]);
}

// ── doctor ──────────────────────────────────────────────────────────
function doctor(args) {
  const [dir] = splitDir(args);
  const root = path.resolve(dir);
  const at = (...p) => path.join(root, ...p);
  const has = (...p) => fs.existsSync(at(...p));
  const read = (...p) => (has(...p) ? fs.readFileSync(at(...p), "utf8") : "");
  const quiet = (cmd, a) => spawnSync(cmd, a, { cwd: root, encoding: "utf8" });
  let fails = 0;
  let warns = 0;
  const ok = (msg) => console.log(`  ok    ${msg}`);
  const warn = (msg, fix) => {
    warns++;
    console.log(`  WARN  ${msg}${fix ? `\n        fix: ${fix}` : ""}`);
  };
  const fail = (msg, fix) => {
    fails++;
    console.log(`  FAIL  ${msg}${fix ? `\n        fix: ${fix}` : ""}`);
  };

  console.log(`vibe doctor — ${root}\n`);

  const major = Number(process.versions.node.split(".")[0]);
  major >= 18 ? ok(`node ${process.versions.node}`) : fail(`node ${process.versions.node} is too old`, "install Node 18 or newer");
  quiet("bash", ["--version"]).status === 0 ? ok("bash found") : fail("bash not found", "install bash (on Windows use WSL or Git Bash)");
  has(".git") ? ok("git repository") : warn("not a git repository: git hooks and vibe check need one", "git init");

  if (!has(".agent", "skills")) {
    fail(".agent/skills is missing: VibeDiscipline is not installed here", "vibe init");
    console.log(`\n${fails} problem(s). Nothing else can be checked.`);
    return 1;
  }
  const skills = fs.readdirSync(at(".agent", "skills")).filter((n) => has(".agent", "skills", n, "SKILL.md"));
  ok(`${skills.length} skills in .agent/skills`);

  const installed = read(".agent", "VERSION").split("\n")[0].trim();
  if (!installed) warn(".agent/VERSION is missing (a skills-only or manual install)");
  else if (installed !== VERSION) warn(`installed version ${installed}, this CLI is ${VERSION}`, "vibe upgrade");
  else ok(`version ${installed}`);

  /VibeDiscipline/.test(read("AGENTS.md"))
    ? ok("AGENTS.md carries the VibeDiscipline constitution")
    : fail("AGENTS.md is missing or does not mention VibeDiscipline: agents will not see the tiers", "vibe init");

  if (!has(".agent", "permissions.yml")) {
    warn("no .agent/permissions.yml: skills-only install, nothing is enforced", "vibe init (without --skills-only)");
  } else {
    ok(".agent/permissions.yml present");
    const settings = read(".claude", "settings.json");
    if (!settings) fail(".claude/settings.json missing: the policy is not enforced", "vibe compile");
    else if (!/GENERATED by scripts\/compile-permissions/.test(settings))
      warn(".claude/settings.json has its own permissions and was not compiled from the policy", "move your rules into .agent/permissions.yml, then: vibe compile");
    else if (fs.statSync(at(".agent", "permissions.yml")).mtimeMs > fs.statSync(at(".claude", "settings.json")).mtimeMs)
      warn("permissions.yml is newer than the compiled settings", "vibe compile");
    else ok("permissions compiled into .claude/settings.json");

    // The guard: present, registered, and actually denying a wrapped command.
    if (!has(".claude", "hooks", "vibe-guard.cjs") || !has(".claude", "hooks", "vibe-policy.json")) {
      warn("guard hook not installed: denied commands inside `bash -c` are not caught", "vibe compile");
    } else if (!/vibe-guard\.cjs/.test(settings)) {
      warn("guard hook is not registered in .claude/settings.json", "vibe compile");
    } else {
      let deny = [];
      try {
        deny = JSON.parse(read(".claude", "hooks", "vibe-policy.json")).deny || [];
      } catch {
        deny = [];
      }
      const sample = (deny.find((g) => !g.startsWith("*")) || "").replace(/\*/g, "");
      if (!sample) ok("guard hook installed (the policy has no deny rule to test it with)");
      else {
        const event = JSON.stringify({ tool_name: "Bash", tool_input: { command: `bash -c "${sample.trim()}"` } });
        const r = spawnSync("node", [at(".claude", "hooks", "vibe-guard.cjs")], { input: event, encoding: "utf8" });
        /"permissionDecision":"deny"/.test(r.stdout || "")
          ? ok(`guard hook blocks a wrapped denied command (${sample.trim()})`)
          : fail("guard hook is installed but did not block a wrapped denied command", "vibe compile");
      }
    }
  }

  const stubs = has(".claude", "skills") ? fs.readdirSync(at(".claude", "skills")).filter((n) => n.startsWith("vibe-")) : [];
  if (has("scripts", "bridge-claude.cjs")) {
    stubs.length === skills.length
      ? ok(`${stubs.length} skills bridged into .claude/skills`)
      : warn(`${stubs.length} of ${skills.length} skills bridged into .claude/skills`, "node scripts/bridge-claude.cjs");
  }

  if (has(".git") && has(".githooks")) {
    const hooks = (quiet("git", ["config", "--get", "core.hooksPath"]).stdout || "").trim();
    if (hooks === ".githooks") ok("git hooks active (core.hooksPath = .githooks)");
    else if (hooks) warn(`core.hooksPath is '${hooks}': VibeDiscipline's git hooks are not running`, "call .githooks/pre-commit from your own pre-commit hook");
    else warn("git hooks not active", "git config core.hooksPath .githooks");
  }

  has(".agent", "stack.lock.yml")
    ? ok("stack detected (.agent/stack.lock.yml)")
    : warn("no .agent/stack.lock.yml yet", "ask your agent to run the recon skill");

  const meth = (read(".agent", "config.yml").match(/^\s+methodology:\s*([A-Za-z]+)/m) || [])[1];
  if (meth && !["agile", "waterfall", "hybrid"].includes(meth)) fail(`unknown methodology '${meth}' in .agent/config.yml`, "vibe methodology hybrid");
  else ok(`methodology: ${meth || "hybrid (default)"}`);

  console.log(`\n${fails} problem(s), ${warns} warning(s).`);
  console.log("Not checkable from here: whether you accepted the Claude Code trust dialog for this");
  console.log("project. Until you do, Claude Code ignores the compiled allow-list.");
  return fails ? 1 : 0;
}

function main() {
  const [cmd, ...args] = process.argv.slice(2);
  switch (cmd) {
    case "init":
      return install(args, []);
    case "upgrade":
      return install(args, ["--upgrade"]);
    case "doctor":
      return doctor(args);
    case "check":
      return run("bash", [projectScript("check.sh"), ...args]);
    case "compile": {
      const code = run("node", [projectScript("compile-permissions.cjs")]);
      const bridge = path.join(process.cwd(), "scripts", "bridge-claude.cjs");
      return code === 0 && fs.existsSync(bridge) ? run("node", [bridge]) : code;
    }
    case "methodology":
      return run("node", [projectScript("set-methodology.cjs"), ...args]);
    case "version":
    case "--version":
    case "-v":
      console.log(VERSION);
      return 0;
    case undefined:
    case "help":
    case "--help":
    case "-h":
      console.log(HELP);
      return 0;
    default:
      console.error(`[vibe] unknown command '${cmd}'\n`);
      console.error(HELP);
      return 2;
  }
}

process.exit(main());
