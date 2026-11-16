#!/usr/bin/env node
/**
 * vibe — the VibeDiscipline command line. Zero dependencies.
 *
 *   npx github:MokammelTanvir/VibeDiscipline init
 *
 * `init` and `upgrade` run this package's installer against a project.
 * `check`, `compile` and `methodology` run the scripts already installed in
 * the project, so they keep working without the package. `doctor` only reads.
 *
 * In a terminal the output is coloured and `init` asks its questions with
 * arrow-key menus. Piped, in CI, or with NO_COLOR set, it prints plain text
 * and asks nothing.
 */
"use strict";
const fs = require("fs");
const path = require("path");
const readline = require("readline");
const { spawn, spawnSync } = require("child_process");

const PKG = path.resolve(__dirname, "..");
const VERSION = fs.readFileSync(path.join(PKG, ".agent", "VERSION"), "utf8").split("\n")[0].trim();
const REPO = "https://github.com/MokammelTanvir/VibeDiscipline";

// ── terminal styling ────────────────────────────────────────────────
const PRETTY = process.env.FORCE_COLOR
  ? process.env.FORCE_COLOR !== "0"
  : Boolean(process.stdout.isTTY) && !process.env.NO_COLOR && process.env.TERM !== "dumb";
const INTERACTIVE = PRETTY && Boolean(process.stdin.isTTY);
const paint = (code) => (s) => (PRETTY ? `\x1b[${code}m${s}\x1b[0m` : String(s));
const c = {
  bold: paint("1"),
  dim: paint("2"),
  red: paint("31"),
  green: paint("32"),
  yellow: paint("33"),
  cyan: paint("36"),
  magenta: paint("35"),
  title: paint("1;35"),
};
const MARK = PRETTY
  ? { ok: c.green("✔"), warn: c.yellow("▲"), fail: c.red("✖"), dot: c.dim("·"), arrow: c.cyan("→") }
  : { ok: "ok   ", warn: "WARN ", fail: "FAIL ", dot: "-", arrow: "->" };

function banner(subtitle) {
  if (!PRETTY) return;
  console.log("");
  console.log(`  ${c.title("▌ VibeDiscipline")} ${c.dim("v" + VERSION)}`);
  console.log(`  ${c.dim("▌ " + (subtitle || "Engineering discipline for AI coding agents"))}`);
  console.log("");
}

function panel(title, lines) {
  console.log("");
  console.log(`  ${c.bold(title)}`);
  for (const l of lines) console.log(`  ${l}`);
}

// ── prompts (only ever used when INTERACTIVE) ───────────────────────
function select(question, options, initial = 0) {
  return new Promise((resolve) => {
    let i = initial;
    const n = options.length;
    const draw = (first) => {
      if (!first) process.stdout.write(`\x1b[${n}A`);
      options.forEach((o, idx) => {
        const label = idx === i ? c.cyan(`❯ ${o.label}`) : `  ${o.label}`;
        process.stdout.write(`\x1b[2K  ${label}${o.hint ? "  " + c.dim(o.hint) : ""}\n`);
      });
    };
    console.log(`  ${c.bold(question)} ${c.dim("↑↓ move · enter choose")}`);
    draw(true);
    readline.emitKeypressEvents(process.stdin);
    process.stdin.setRawMode(true);
    process.stdin.resume();
    const done = (value) => {
      process.stdin.setRawMode(false);
      process.stdin.pause();
      process.stdin.removeListener("keypress", onKey);
      // collapse the menu to the chosen line
      process.stdout.write(`\x1b[${n + 1}A\x1b[0J`);
      console.log(`  ${MARK.ok} ${question} ${c.cyan(options[i].label)}`);
      resolve(value);
    };
    function onKey(str, key = {}) {
      if (key.ctrl && key.name === "c") {
        process.stdin.setRawMode(false);
        console.log("\n  cancelled");
        process.exit(130);
      }
      if (key.name === "up" || key.name === "k") i = (i - 1 + n) % n;
      else if (key.name === "down" || key.name === "j") i = (i + 1) % n;
      else if (/^[1-9]$/.test(str || "") && Number(str) <= n) i = Number(str) - 1;
      else if (key.name === "return") return done(options[i].value);
      draw(false);
    }
    process.stdin.on("keypress", onKey);
  });
}

async function confirm(question, yes = true) {
  const answer = await select(question, [
    { label: "Yes", value: true },
    { label: "No", value: false },
  ], yes ? 0 : 1);
  return answer;
}

// ── helpers ─────────────────────────────────────────────────────────
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

// The same rule the installer uses.
function detectStack(dir) {
  const has = (f) => fs.existsSync(path.join(dir, f));
  if (has("artisan") || has("composer.json")) return "laravel";
  if (has("pyproject.toml") || has("manage.py") || has("setup.py") || fs.readdirSync(dir).some((f) => /^requirements.*\.txt$/.test(f))) return "python";
  if (has("package.json")) return "node";
  return "generic";
}

const WARN_LINE = /NOT compiled|left alone|not a git repository|node not found|differs from|kept existing|nothing of yours|rules into|merge by hand|already installed|nothing was changed|local edits/;

// Runs the installer. Plain mode: its output as is. Pretty mode: restyled.
function runInstaller(dir, flags) {
  const script = path.join(PKG, "scripts", "install.sh");
  if (!PRETTY) return Promise.resolve(run("bash", [script, dir, ...flags]));
  return new Promise((resolve) => {
    const child = spawn("bash", [script, dir, ...flags], { stdio: ["inherit", "pipe", "pipe"] });
    let inNext = false;
    const onLine = (line) => {
      if (/^\[vibe\] installing into/.test(line)) return;
      if (/^\[vibe\] done\. Next:/.test(line) || /^\[vibe\] done: skills only/.test(line)) {
        inNext = true;
        return;
      }
      if (inNext || line.trim() === "") return;
      let m;
      if ((m = line.match(/^\[vibe\] (.*)$/))) {
        const warn = WARN_LINE.test(m[1]);
        console.log(`  ${warn ? MARK.warn : MARK.ok} ${warn ? c.yellow(m[1]) : m[1]}`);
      } else if ((m = line.match(/^\s+\[vibe\] (.*)$/))) {
        // the compiler's and the bridge's own reports, said in one line each
        if (/^compiled permissions\.yml/.test(m[1])) console.log(`  ${MARK.ok} permissions compiled ${c.dim("(Claude Code settings, guard hook, git hooks, docs/PERMISSIONS.md)")}`);
        else if ((m = m[1].match(/^bridged (\d+) skill/))) console.log(`  ${MARK.ok} ${m[1]} skills available in Claude Code ${c.dim("(/vibe-planning, /vibe-recon, ...)")}`);
        else if (/core\.hooksPath set to/.test(line)) console.log(`  ${MARK.ok} git hooks activated`);
        else console.log(`  ${MARK.warn} ${c.yellow(line.replace(/^\s+\[vibe\] /, ""))}`);
      } else if (/^ {4}/.test(line)) return; // the file lists under those reports
      else console.log(`    ${c.dim(line.trim())}`);
    };
    readline.createInterface({ input: child.stdout }).on("line", onLine);
    readline.createInterface({ input: child.stderr }).on("line", (l) => console.log(`  ${MARK.fail} ${c.red(l.replace(/^\[vibe\] /, ""))}`));
    child.on("close", (code) => resolve(code === null ? 1 : code));
    child.on("error", (e) => {
      console.error(`[vibe] could not run bash: ${e.message}`);
      resolve(1);
    });
  });
}

function nextSteps(skillsOnly) {
  if (skillsOnly) {
    panel("Done", [`${MARK.ok} Skills copied to ${c.cyan(".agent/skills/")}. Nothing else was touched.`]);
    return;
  }
  panel("Next", [
    `${c.cyan("1")}  Open the project in Claude Code and ${c.bold("accept the trust dialog")}`,
    `${c.cyan("2")}  Ask your agent: ${c.green('"run the recon skill"')}`,
    `${c.cyan("3")}  Check it: ${c.bold("vibe doctor")}   then commit the new files`,
  ]);
  panel("Try saying", [
    `${MARK.arrow} ${c.green('"Fix the typo in the footer"')}  ${c.dim("edits and verifies, no plan")}`,
    `${MARK.arrow} ${c.green('"Add notifications"')}           ${c.dim("asks what you mean before building")}`,
    `${MARK.arrow} ${c.green('"Add a wishlist feature"')}      ${c.dim("writes a plan and waits for your approval")}`,
  ]);
  console.log("");
  console.log(`  ${c.dim("Guide:")} ${REPO}/blob/main/docs/GUIDE.md`);
  console.log("");
}

// ── init / upgrade ──────────────────────────────────────────────────
async function init(args) {
  const [dir, rest] = splitDir(args);
  if (!fs.existsSync(dir) || !fs.statSync(dir).isDirectory()) {
    console.error(`[vibe] not a directory: ${dir}`);
    return 2;
  }
  const flags = rest.filter((a) => a !== "--yes" && a !== "-y");
  const assumeYes = flags.length !== rest.length;
  const has = (name) => flags.some((a) => a === name || a.startsWith(name + "="));
  const root = path.resolve(dir);
  banner();

  const installed = fs.existsSync(path.join(root, ".agent", "skills")) && fs.existsSync(path.join(root, "AGENTS.md"));
  if (installed && !has("--force") && !has("--skills-only")) {
    const have = fs.existsSync(path.join(root, ".agent", "VERSION"))
      ? fs.readFileSync(path.join(root, ".agent", "VERSION"), "utf8").split("\n")[0].trim()
      : "an unknown version";
    if (!PRETTY) return run("bash", [path.join(PKG, "scripts", "install.sh"), dir, ...flags]);
    console.log(`  ${MARK.warn} ${c.yellow(`VibeDiscipline ${have} is already installed here.`)}`);
    console.log(`    ${c.dim("init does not touch an existing install. upgrade refreshes skills and scripts")}`);
    console.log(`    ${c.dim("and keeps your config.yml, permissions.yml and state.md.")}\n`);
    if (INTERACTIVE && !assumeYes && !(await confirm(`Upgrade it to ${VERSION} now?`))) return 0;
    if (!INTERACTIVE && !assumeYes) {
      console.log(`  ${MARK.arrow} run ${c.bold("vibe upgrade")}`);
      return 0;
    }
    return upgrade([dir]);
  }

  if (INTERACTIVE && !assumeYes && !has("--dry-run") && !has("--skills-only")) {
    console.log(`  ${c.dim("Installing into")} ${c.cyan(root)}\n`);
    if (!has("--stack")) {
      const found = detectStack(root);
      const order = [found, ...["laravel", "node", "python", "generic"].filter((s) => s !== found)];
      const hints = { laravel: "PHP, Composer, artisan", node: "npm / pnpm / yarn, TypeScript", python: "pytest, pip / uv / poetry, Django", generic: "git rules only; add your own commands" };
      const stack = await select("Which stack?", order.map((s, i) => ({ label: s, value: s, hint: (i === 0 ? "detected · " : "") + hints[s] })));
      flags.push("--stack", stack);
    }
    if (!has("--methodology")) {
      const meth = await select("How should work be sequenced?", [
        { label: "hybrid", value: "hybrid", hint: "recommended · iterative for features, documents first for big work" },
        { label: "agile", value: "agile", hint: "small increments, approval per increment" },
        { label: "waterfall", value: "waterfall", hint: "phases in order, approval after each phase" },
      ]);
      flags.push("--methodology", meth);
    }
    console.log("");
  }

  const code = await runInstaller(dir, flags);
  if (code === 0 && PRETTY && !has("--dry-run")) nextSteps(has("--skills-only"));
  return code;
}

async function upgrade(args) {
  const [dir, rest] = splitDir(args);
  if (!fs.existsSync(dir) || !fs.statSync(dir).isDirectory()) {
    console.error(`[vibe] not a directory: ${dir}`);
    return 2;
  }
  if (PRETTY) console.log(`  ${c.dim("Upgrading")} ${c.cyan(path.resolve(dir))} ${c.dim("to")} ${c.bold(VERSION)}\n`);
  const code = await runInstaller(dir, ["--upgrade", ...rest]);
  if (code === 0 && PRETTY) console.log(`\n  ${MARK.arrow} check it with ${c.bold("vibe doctor")}, then review and commit the changes\n`);
  return code;
}

// ── new ─────────────────────────────────────────────────────────────
// Creates a project with the framework's OWN scaffolder, then installs
// VibeDiscipline on top. No framework code lives in this package, so a new
// project is always whatever the framework ships today.
const BACKENDS = {
  laravel: { label: "Laravel", hint: "PHP · composer create-project", frontends: ["none", "react", "vue"] },
  nextjs: { label: "Next.js", hint: "full-stack React · create-next-app", frontends: ["none"] },
  django: { label: "Django", hint: "Python · django-admin startproject", frontends: ["none"] },
  nestjs: { label: "NestJS", hint: "Node API · @nestjs/cli", frontends: ["none"] },
  none: { label: "None", hint: "a frontend-only app", frontends: ["react", "vue", "angular"] },
};
const FRONTENDS = {
  none: { label: "None", hint: "use what the backend ships" },
  react: { label: "React", hint: "TypeScript" },
  vue: { label: "Vue", hint: "TypeScript" },
  angular: { label: "Angular", hint: "@angular/cli" },
};

// -> { needs, steps, stack, notes } or a string explaining why not.
function recipe(backend, frontend, name) {
  const b = BACKENDS[backend];
  if (!b) return `unknown backend '${backend}'. Choose: ${Object.keys(BACKENDS).join(", ")}.`;
  if (!FRONTENDS[frontend]) return `unknown frontend '${frontend}'. Choose: ${Object.keys(FRONTENDS).join(", ")}.`;
  if (!b.frontends.includes(frontend)) {
    return backend === "none"
      ? "choose a frontend (react, vue or angular) or a backend."
      : `${b.label} with ${FRONTENDS[frontend].label} is not offered: there is no official starter for it. ` +
          `${b.label} goes with: ${b.frontends.join(", ")}. For a separate frontend, create it as its own project.`;
  }
  const step = (cmd, args, cwd) => ({ cmd, args, cwd });
  switch (`${backend}+${frontend}`) {
    case "laravel+none":
      return { needs: ["php", "composer"], stack: "laravel", steps: [step("composer", ["create-project", "laravel/laravel", name])] };
    case "laravel+react":
      return { needs: ["php", "composer"], stack: "laravel", steps: [step("composer", ["create-project", "laravel/react-starter-kit", name])], notes: ["run `npm install` in the project for the React side"] };
    case "laravel+vue":
      return { needs: ["php", "composer"], stack: "laravel", steps: [step("composer", ["create-project", "laravel/vue-starter-kit", name])], notes: ["run `npm install` in the project for the Vue side"] };
    case "nextjs+none":
      return { needs: ["npx"], stack: "node", steps: [step("npx", ["--yes", "create-next-app@latest", name, "--yes"])] };
    case "nestjs+none":
      return { needs: ["npx"], stack: "node", steps: [step("npx", ["--yes", "@nestjs/cli@latest", "new", name, "--package-manager", "npm", "--skip-git"])] };
    case "django+none":
      return {
        needs: ["python3"],
        stack: "python",
        steps: [
          step("python3", ["-m", "venv", ".venv"], name),
          step(path.join(".venv", "bin", "python"), ["-m", "pip", "install", "--quiet", "django"], name),
          step(path.join(".venv", "bin", "django-admin"), ["startproject", "config", "."], name),
        ],
        mkdir: true,
        files: { ".gitignore": ".venv/\n__pycache__/\n*.pyc\ndb.sqlite3\n.env\n", "requirements.txt": "django\n" },
        notes: ["activate the environment with `source .venv/bin/activate`"],
      };
    case "none+react":
      return { needs: ["npm"], stack: "node", steps: [step("npm", ["create", "--yes", "vite@latest", name, "--", "--template", "react-ts"])], notes: ["run `npm install` in the project"] };
    case "none+vue":
      return { needs: ["npm"], stack: "node", steps: [step("npm", ["create", "--yes", "vite@latest", name, "--", "--template", "vue-ts"])], notes: ["run `npm install` in the project"] };
    case "none+angular":
      return { needs: ["npx"], stack: "node", steps: [step("npx", ["--yes", "@angular/cli@latest", "new", name, "--defaults", "--skip-git"])] };
    default:
      return `no recipe for ${backend} + ${frontend}.`;
  }
}

function ask(question, fallback) {
  return new Promise((resolve) => {
    const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
    rl.question(`  ${c.bold(question)}${fallback ? c.dim(` (${fallback})`) : ""} `, (answer) => {
      rl.close();
      resolve(answer.trim() || fallback || "");
    });
  });
}

async function newProject(args) {
  const value = (flag) => {
    const i = args.findIndex((a) => a === flag || a.startsWith(flag + "="));
    if (i === -1) return undefined;
    return args[i].includes("=") ? args[i].split("=").slice(1).join("=") : args[i + 1];
  };
  const dry = args.includes("--dry-run");
  const flagsWithValue = ["--backend", "--frontend", "--methodology"];
  const positional = args.filter((a, i) => !a.startsWith("-") && !flagsWithValue.includes(args[i - 1]));
  let name = positional[0];
  let backend = value("--backend");
  let frontend = value("--frontend");
  let methodology = value("--methodology");
  banner("new project");

  if (INTERACTIVE && !args.includes("--yes") && !args.includes("-y")) {
    if (!name) name = await ask("Project name?", "my-app");
    if (!backend) {
      backend = await select("Backend?", Object.entries(BACKENDS).map(([k, v]) => ({ label: v.label, value: k, hint: v.hint })));
    }
    if (!frontend) {
      const choices = (BACKENDS[backend] || BACKENDS.none).frontends;
      frontend = choices.length === 1
        ? choices[0]
        : await select("Frontend?", choices.map((k) => ({ label: FRONTENDS[k].label, value: k, hint: backend === "laravel" && k !== "none" ? "official Laravel starter kit" : FRONTENDS[k].hint })));
    }
    if (!methodology) {
      methodology = await select("How should work be sequenced?", [
        { label: "hybrid", value: "hybrid", hint: "recommended" },
        { label: "agile", value: "agile", hint: "approval per increment" },
        { label: "waterfall", value: "waterfall", hint: "approval after each phase" },
      ]);
    }
    console.log("");
  }
  if (!name || (!backend && !frontend)) {
    console.error("[vibe] usage: vibe new <name> --backend <b> [--frontend <f>] [--methodology <m>] [--dry-run]");
    console.error(`[vibe]   backends:  ${Object.keys(BACKENDS).join(", ")}`);
    console.error(`[vibe]   frontends: ${Object.keys(FRONTENDS).join(", ")}`);
    return 2;
  }
  backend = backend || "none";
  frontend = frontend || (backend === "none" ? "" : "none");
  if (!/^[A-Za-z0-9][A-Za-z0-9._-]*$/.test(name)) {
    console.error(`[vibe] '${name}' is not a usable directory name (letters, digits, dot, dash, underscore).`);
    return 2;
  }
  const plan = recipe(backend, frontend, name);
  if (typeof plan === "string") {
    console.error(`[vibe] ${plan}`);
    return 2;
  }
  const target = path.resolve(name);
  if (fs.existsSync(target) && fs.readdirSync(target).length) {
    console.error(`[vibe] ${name} already exists and is not empty. To add VibeDiscipline to it: vibe init ${name}`);
    return 2;
  }
  const missing = plan.needs.filter((tool) => spawnSync(tool, ["--version"], { stdio: "ignore" }).error);
  if (missing.length && !dry) {
    console.error(`[vibe] ${BACKENDS[backend].label === "None" ? FRONTENDS[frontend].label : BACKENDS[backend].label} needs ${missing.join(" and ")}, which is not installed.`);
    return 1;
  }

  const show = (s) => `${s.cmd} ${s.args.join(" ")}${s.cwd ? `   (in ${s.cwd}/)` : ""}`;
  if (dry) {
    console.log(`${PRETTY ? "  " : ""}Would run:`);
    for (const s of plan.steps) console.log(`  ${show(s)}`);
    console.log(`  vibe init ${name} --stack ${plan.stack}${methodology ? ` --methodology ${methodology}` : ""}`);
    return 0;
  }

  if (plan.mkdir) fs.mkdirSync(target, { recursive: true });
  for (const s of plan.steps) {
    console.log(`  ${MARK.arrow} ${c.dim(show(s))}`);
    const code = run(s.cmd, s.args, s.cwd ? { cwd: path.resolve(s.cwd) } : {});
    if (code !== 0) {
      console.error(`\n[vibe] the scaffolder failed (exit ${code}). VibeDiscipline was not installed. Fix the error above and run again.`);
      return code;
    }
  }
  for (const [file, content] of Object.entries(plan.files || {})) {
    if (!fs.existsSync(path.join(target, file))) fs.writeFileSync(path.join(target, file), content);
  }
  if (!fs.existsSync(path.join(target, ".git"))) spawnSync("git", ["init", "-q"], { cwd: target });

  console.log(`\n  ${MARK.ok} ${[BACKENDS[backend].label, frontend && frontend !== "none" ? FRONTENDS[frontend].label : ""].filter((x) => x && x !== "None").join(" + ")} project created in ${c.cyan(name)}\n`);
  const flags = ["--stack", plan.stack];
  if (methodology) flags.push("--methodology", methodology);
  const code = await runInstaller(name, flags);
  if (code !== 0) return code;
  if (PRETTY) {
    panel("Next", [
      `${c.cyan("1")}  ${c.bold(`cd ${name}`)}`,
      ...(plan.notes || []).map((n) => `${MARK.dot}  ${c.dim(n)}`),
      `${c.cyan("2")}  Open it in Claude Code and ${c.bold("accept the trust dialog")}`,
      `${c.cyan("3")}  Ask your agent: ${c.green('"run the recon skill"')}`,
      `${c.cyan("4")}  ${c.bold("vibe doctor")}, then make your first commit`,
    ]);
    console.log("");
  } else {
    console.log(`[vibe] next: cd ${name}${(plan.notes || []).map((n) => `; ${n}`).join("")}`);
  }
  return 0;
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
  const fixLine = (fix) => (fix ? `\n        ${c.dim("fix:")} ${c.cyan(fix)}` : "");
  const ok = (msg) => console.log(`  ${MARK.ok} ${PRETTY ? "" : " "}${msg}`);
  const warn = (msg, fix) => {
    warns++;
    console.log(`  ${MARK.warn} ${PRETTY ? "" : " "}${c.yellow(msg)}${fixLine(fix)}`);
  };
  const fail = (msg, fix) => {
    fails++;
    console.log(`  ${MARK.fail} ${PRETTY ? "" : " "}${c.red(msg)}${fixLine(fix)}`);
  };
  const section = (name) => PRETTY && console.log(`\n  ${c.bold(name)}`);

  if (PRETTY) banner("doctor · " + root);
  else console.log(`vibe doctor — ${root}\n`);

  section("Environment");
  const major = Number(process.versions.node.split(".")[0]);
  major >= 18 ? ok(`node ${process.versions.node}`) : fail(`node ${process.versions.node} is too old`, "install Node 18 or newer");
  quiet("bash", ["--version"]).status === 0 ? ok("bash found") : fail("bash not found", "install bash (on Windows use WSL or Git Bash)");
  has(".git") ? ok("git repository") : warn("not a git repository: git hooks and vibe check need one", "git init");

  section("Installation");
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

  // The version file can say one thing while the files say another (an
  // `init` run over an older install used to do exactly that).
  const owned = ["check.sh", "compile-permissions.cjs", "vibe-guard.cjs", "bridge-claude.cjs", "set-methodology.cjs"].map((f) => path.join("scripts", f));
  const walk = (rel) =>
    fs.readdirSync(path.join(PKG, rel), { withFileTypes: true }).flatMap((e) => (e.isDirectory() ? walk(path.join(rel, e.name)) : [path.join(rel, e.name)]));
  for (const d of [".agent/skills", ".agent/ecosystems", ".agent/adapters"]) owned.push(...walk(d));
  const stale = owned.filter((rel) => {
    if (rel.endsWith(".DS_Store")) return false;
    const mine = path.join(PKG, rel);
    const theirs = at(rel);
    return !fs.existsSync(theirs) || !fs.readFileSync(mine).equals(fs.readFileSync(theirs));
  });
  if (stale.length) {
    const shown = stale.slice(0, 4).join(", ") + (stale.length > 4 ? `, and ${stale.length - 4} more` : "");
    warn(`${stale.length} file(s) are missing or differ from version ${VERSION} (an older install, or your own edits): ${shown}`, "vibe upgrade");
  } else ok(`skills and scripts match version ${VERSION}`);

  /VibeDiscipline/.test(read("AGENTS.md"))
    ? ok("AGENTS.md carries the VibeDiscipline constitution")
    : fail("AGENTS.md is missing or does not mention VibeDiscipline: agents will not see the tiers", "vibe init");

  section("Enforcement");
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
    const guardFix = has("scripts", "vibe-guard.cjs") ? "vibe compile" : "vibe upgrade";
    if (!has(".claude", "hooks", "vibe-guard.cjs") || !has(".claude", "hooks", "vibe-policy.json")) {
      warn("guard hook not installed: denied commands inside `bash -c` are not caught", guardFix);
    } else if (!/vibe-guard\.cjs/.test(settings)) {
      warn("guard hook is not registered in .claude/settings.json", guardFix);
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
          : fail("guard hook is installed but did not block a wrapped denied command", guardFix);
      }
    }
  }

  if (has(".git") && has(".githooks")) {
    const hooks = (quiet("git", ["config", "--get", "core.hooksPath"]).stdout || "").trim();
    if (hooks === ".githooks") ok("git hooks active (core.hooksPath = .githooks)");
    else if (hooks) warn(`core.hooksPath is '${hooks}': VibeDiscipline's git hooks are not running`, "call .githooks/pre-commit from your own pre-commit hook");
    else warn("git hooks not active", "git config core.hooksPath .githooks");
  }

  section("Agent setup");
  const stubs = has(".claude", "skills") ? fs.readdirSync(at(".claude", "skills")).filter((n) => n.startsWith("vibe-")) : [];
  if (has("scripts", "bridge-claude.cjs")) {
    stubs.length === skills.length
      ? ok(`${stubs.length} skills bridged into .claude/skills`)
      : warn(`${stubs.length} of ${skills.length} skills bridged into .claude/skills`, "node scripts/bridge-claude.cjs");
  }
  has(".agent", "stack.lock.yml")
    ? ok("stack detected (.agent/stack.lock.yml)")
    : warn("no .agent/stack.lock.yml yet", "ask your agent to run the recon skill");
  const meth = (read(".agent", "config.yml").match(/^\s+methodology:\s*([A-Za-z]+)/m) || [])[1];
  if (meth && !["agile", "waterfall", "hybrid"].includes(meth)) fail(`unknown methodology '${meth}' in .agent/config.yml`, "vibe methodology hybrid");
  else ok(`methodology: ${meth || "hybrid (default)"}`);

  console.log("");
  if (PRETTY) {
    const verdict = fails ? c.red(`${fails} problem(s)`) : warns ? c.yellow("Working, with warnings") : c.green("All good");
    console.log(`  ${c.bold(verdict)}  ${c.dim(`${fails} problem(s), ${warns} warning(s)`)}`);
    console.log(`  ${c.dim("Not checkable from here: whether you accepted Claude Code's trust dialog for this")}`);
    console.log(`  ${c.dim("project. Until you do, Claude Code ignores the compiled allow-list.")}\n`);
  } else {
    console.log(`${fails} problem(s), ${warns} warning(s).`);
    console.log("Not checkable from here: whether you accepted the Claude Code trust dialog for this");
    console.log("project. Until you do, Claude Code ignores the compiled allow-list.");
  }
  return fails ? 1 : 0;
}

// ── uninstall ───────────────────────────────────────────────────────
// Removes what VibeDiscipline put in a project and nothing else. Every file
// is checked for our own marker before it is touched; anything that looks
// like the project's own is kept and named.
async function uninstall(args) {
  const [dir, rest] = splitDir(args);
  const root = path.resolve(dir);
  const dry = rest.includes("--dry-run");
  const yes = rest.includes("--yes") || rest.includes("-y");
  const at = (...p) => path.join(root, ...p);
  const has = (...p) => fs.existsSync(at(...p));
  const read = (...p) => (has(...p) ? fs.readFileSync(at(...p), "utf8") : "");
  const GENERATED = /GENERATED by `?scripts\/(compile-permissions|bridge-claude)/;
  const OURS = /VibeDiscipline|\[vibe\]|vibe check/;
  const POINTERS = [
    "See [AGENTS.md](./AGENTS.md) — the constitution for this repository.",
    "Do not duplicate its content here; edit AGENTS.md instead.",
  ];

  banner("uninstall · " + root);
  if (!has(".agent") && !/VibeDiscipline/.test(read("AGENTS.md"))) {
    console.log(`${PRETTY ? "  " : ""}VibeDiscipline is not installed in ${root}. Nothing to do.`);
    return 0;
  }

  const steps = []; // { label, run }
  const kept = [];
  const rm = (rel) => steps.push({ label: `delete ${rel}`, run: () => fs.rmSync(at(rel), { recursive: true, force: true }) });
  const rmdirIfEmpty = (rel) => steps.push({ label: null, run: () => has(rel) && fs.readdirSync(at(rel)).length === 0 && fs.rmdirSync(at(rel)) });

  if (has(".agent")) rm(".agent");

  for (const hook of ["pre-commit", "pre-push"]) {
    const rel = path.join(".githooks", hook);
    if (!has(rel)) continue;
    GENERATED.test(read(rel)) ? rm(rel) : kept.push(`${rel} (not generated by VibeDiscipline)`);
  }
  if (has(".githooks")) rmdirIfEmpty(".githooks");
  const hooksPath = (spawnSync("git", ["config", "--get", "core.hooksPath"], { cwd: root, encoding: "utf8" }).stdout || "").trim();
  if (hooksPath === ".githooks") {
    steps.push({ label: "git config --unset core.hooksPath", run: () => spawnSync("git", ["config", "--unset", "core.hooksPath"], { cwd: root }) });
  }

  for (const f of ["vibe-guard.cjs", "vibe-policy.json"]) if (has(".claude", "hooks", f)) rm(path.join(".claude", "hooks", f));
  if (has(".claude", "hooks")) rmdirIfEmpty(path.join(".claude", "hooks"));
  if (has(".claude", "skills")) {
    for (const name of fs.readdirSync(at(".claude", "skills")).filter((n) => n.startsWith("vibe-"))) {
      const rel = path.join(".claude", "skills", name);
      GENERATED.test(read(rel, "SKILL.md")) ? rm(rel) : kept.push(`${rel} (not generated by VibeDiscipline)`);
    }
    rmdirIfEmpty(path.join(".claude", "skills"));
  }

  if (has(".claude", "settings.json")) {
    let settings = null;
    try {
      settings = JSON.parse(read(".claude", "settings.json"));
    } catch {
      kept.push(".claude/settings.json (not valid JSON, left alone)");
    }
    if (settings) {
      const generated = GENERATED.test(String(settings["//"] || ""));
      const guarded = JSON.stringify(settings.hooks || {}).includes("vibe-guard.cjs");
      if (generated || guarded) {
        steps.push({
          label: "remove the generated permissions and the guard hook entry from .claude/settings.json",
          run: () => {
            if (generated) {
              delete settings["//"];
              delete settings.permissions;
            }
            if (settings.hooks && settings.hooks.PreToolUse) {
              settings.hooks.PreToolUse = settings.hooks.PreToolUse.filter((e) => !JSON.stringify(e).includes("vibe-guard.cjs"));
              if (!settings.hooks.PreToolUse.length) delete settings.hooks.PreToolUse;
              if (!Object.keys(settings.hooks).length) delete settings.hooks;
            }
            if (Object.keys(settings).length) fs.writeFileSync(at(".claude", "settings.json"), JSON.stringify(settings, null, 2) + "\n");
            else fs.rmSync(at(".claude", "settings.json"));
          },
        });
      } else kept.push(".claude/settings.json (its permissions are your own)");
    }
  }
  if (has(".claude")) rmdirIfEmpty(".claude");

  if (has("AGENTS.md")) {
    const lines = read("AGENTS.md").split("\n");
    const start = lines.indexOf("<!-- vibediscipline:start -->");
    const end = lines.indexOf("<!-- vibediscipline:end -->");
    let rest = null;
    if (start !== -1 && end > start) rest = [...lines.slice(0, start), ...lines.slice(end + 1)];
    else if (lines[0] === "# AGENTS.md — Project Constitution") {
      // An install from before the markers: our text runs to the end of the
      // "Adapt, don't override" section.
      const adapt = lines.findIndex((l) => /^## Adapt, don.t override/.test(l));
      if (adapt !== -1) {
        const next = lines.findIndex((l, i) => i > adapt && /^(#|<)/.test(l));
        rest = next === -1 ? [] : lines.slice(next);
      }
    }
    if (rest === null) {
      if (/VibeDiscipline/.test(lines.join("\n"))) kept.push("AGENTS.md (mentions VibeDiscipline but has no markers: edit it by hand)");
    } else if (rest.join("").trim() === "") rm("AGENTS.md");
    else {
      steps.push({
        label: "remove the VibeDiscipline block from AGENTS.md (your content stays)",
        run: () => fs.writeFileSync(at("AGENTS.md"), rest.join("\n").replace(/^\n+/, "")),
      });
    }
  }

  if (has("CLAUDE.md")) {
    const lines = read("CLAUDE.md").split("\n");
    const rest = lines.filter((l) => !POINTERS.includes(l));
    if (rest.length !== lines.length) {
      if (rest.join("").trim() === "") rm("CLAUDE.md");
      else {
        steps.push({
          label: "remove the AGENTS.md pointer from CLAUDE.md (your content stays)",
          run: () => fs.writeFileSync(at("CLAUDE.md"), rest.join("\n").replace(/^\n+/, "")),
        });
      }
    }
  }

  for (const f of ["check.sh", "compile-permissions.cjs", "vibe-guard.cjs", "bridge-claude.cjs", "set-methodology.cjs", "validate-portability.sh"]) {
    const rel = path.join("scripts", f);
    if (!has(rel)) continue;
    OURS.test(read(rel)) ? rm(rel) : kept.push(`${rel} (does not look like VibeDiscipline's)`);
  }
  if (has("scripts")) rmdirIfEmpty("scripts");
  if (has("docs", "PERMISSIONS.md") && GENERATED.test(read("docs", "PERMISSIONS.md"))) rm(path.join("docs", "PERMISSIONS.md"));
  for (const rel of ["docs/tasks", "docs/CONVENTIONS.md", "docs/product", "docs/technical", "docs/architecture"]) {
    if (has(rel)) kept.push(`${rel} (your project's records)`);
  }
  if (has("docs")) rmdirIfEmpty("docs");

  const visible = steps.filter((s) => s.label);
  console.log(`${PRETTY ? "  " : ""}${c.bold(dry ? "Would remove:" : "This will remove:")}`);
  for (const s of visible) console.log(`  ${PRETTY ? c.red("−") : "-"} ${s.label}`);
  if (kept.length) {
    console.log(`\n${PRETTY ? "  " : ""}${c.bold("Kept:")}`);
    for (const k of kept) console.log(`  ${MARK.dot} ${c.dim(k)}`);
  }
  console.log("");
  if (has(".agent", "state.md") || has(".agent", "config.yml")) {
    console.log(`  ${MARK.warn} ${c.yellow(".agent/ holds your config.yml, permissions.yml and state.md. They go too.")}`);
  }
  if (dry) return 0;

  if (!yes) {
    if (!INTERACTIVE) {
      console.error("[vibe] uninstall deletes files. Re-run with --yes to confirm, or --dry-run to preview.");
      return 2;
    }
    if (!(await confirm("Remove VibeDiscipline from this project?", false))) {
      console.log("  nothing was removed");
      return 0;
    }
  }
  for (const s of steps) s.run();
  console.log(`\n  ${MARK.ok} VibeDiscipline removed. ${c.dim("Nothing was committed: review with `git status`.")}\n`);
  return 0;
}

// ── help ────────────────────────────────────────────────────────────
function help() {
  const cmd = (name, text) => `  ${c.cyan(name.padEnd(22))}${text}`;
  const opt = (name, text) => `      ${c.dim(name.padEnd(20))}${c.dim(text)}`;
  banner();
  console.log(
    [
      `${PRETTY ? "  " : ""}${c.bold("Usage:")} vibe <command> [options]`,
      "",
      `  ${c.bold("Set up")}`,
      cmd("new [name]", "create a new project with its framework's own scaffolder,"),
      cmd("", "then install VibeDiscipline in it"),
      opt("--backend <b>", "laravel | nextjs | django | nestjs | none"),
      opt("--frontend <f>", "react | vue | angular | none"),
      cmd("init [dir]", "install into an existing project (default: current directory)"),
      opt("--stack <s>", "auto | laravel | node | python | generic"),
      opt("--methodology <m>", "agile | waterfall | hybrid"),
      opt("--skills-only", "copy .agent/skills/ and nothing else"),
      opt("--dry-run", "show what would happen"),
      opt("--yes", "no questions, take the defaults"),
      opt("--force", "overwrite files that already exist"),
      cmd("upgrade [dir]", "refresh skills and scripts; keeps your config,"),
      cmd("", "permissions and state"),
      cmd("doctor [dir]", "check an installation and say how to fix it"),
      cmd("uninstall [dir]", "remove VibeDiscipline; your own files are kept"),
      opt("--dry-run", "list what would be removed"),
      opt("--yes", "do not ask for confirmation"),
      "",
      `  ${c.bold("Day to day")}`,
      cmd("check", "vibe check: scope, secrets, leftovers, dependency, tests"),
      opt("--staged", "only what is about to be committed"),
      opt("--task <id>", "scope-check against that task doc"),
      cmd("compile", "permissions.yml -> Claude Code settings, hooks, docs"),
      cmd("methodology [m]", "show or set agile | waterfall | hybrid"),
      "",
      `  ${c.bold("Other")}`,
      cmd("version", "print the version"),
      cmd("help", "print this"),
      "",
      `  ${c.dim("Guide:")} ${REPO}/blob/main/docs/GUIDE.md`,
      "",
    ].join("\n")
  );
}

async function main() {
  const [cmd, ...args] = process.argv.slice(2);
  switch (cmd) {
    case "new":
      return newProject(args);
    case "init":
      return init(args);
    case "upgrade":
      banner();
      return upgrade(args);
    case "doctor":
      return doctor(args);
    case "uninstall":
      return uninstall(args);
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
      help();
      return 0;
    default:
      console.error(`[vibe] unknown command '${cmd}'\n`);
      help();
      return 2;
  }
}

main().then((code) => process.exit(code));
