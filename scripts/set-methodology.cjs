#!/usr/bin/env node
/**
 * Selects the project methodology: workflow.methodology in .agent/config.yml.
 *
 *   node scripts/set-methodology.cjs              # menu (needs a terminal)
 *   node scripts/set-methodology.cjs waterfall    # agile | waterfall | hybrid
 *   node scripts/set-methodology.cjs --show       # print the current value
 *
 * Edits only that one key and leaves the rest of config.yml as written. A
 * stopgap until `vibe init` prompts for it (plan Section 44).
 */
"use strict";
const fs = require("fs");
const path = require("path");
const readline = require("readline");

const CONFIG = path.resolve(__dirname, "..", ".agent", "config.yml");
const OPTIONS = {
  agile: "small increments, a story + criteria per task, approval per increment",
  waterfall: "phases in order (requirements, design, build, verify, release), approval per phase",
  hybrid: "tier-driven: iterative below Tier L, document-first at Tier L (default)",
};

const valid = (v) => Object.prototype.hasOwnProperty.call(OPTIONS, v);

function current(text) {
  const m = text.match(/^[ \t]+methodology:[ \t]*([A-Za-z]+)/m);
  return m ? m[1] : null;
}

function apply(text, value) {
  if (/^[ \t]+methodology:/m.test(text)) {
    return text.replace(/^([ \t]+methodology:[ \t]*)[A-Za-z]*/m, `$1${value}`);
  }
  if (/^workflow:[ \t]*$/m.test(text)) {
    return text.replace(/^workflow:[ \t]*$/m, `workflow:\n  methodology: ${value}`);
  }
  return `${text}${text === "" || text.endsWith("\n") ? "" : "\n"}workflow:\n  methodology: ${value}\n`;
}

function choose() {
  return new Promise((resolve) => {
    const names = Object.keys(OPTIONS);
    names.forEach((n, i) => console.log(`  ${i + 1}) ${n.padEnd(10)} ${OPTIONS[n]}`));
    const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
    rl.question("Select methodology [1-3]: ", (answer) => {
      rl.close();
      const a = answer.trim().toLowerCase();
      resolve(names[Number(a) - 1] || (valid(a) ? a : null));
    });
  });
}

async function main() {
  const arg = process.argv[2];
  const text = fs.existsSync(CONFIG) ? fs.readFileSync(CONFIG, "utf8") : "";

  if (arg === "--show") {
    console.log(`methodology: ${current(text) || "hybrid (unset, the default)"}`);
    return;
  }

  let value = arg;
  if (!value) {
    if (!process.stdin.isTTY) {
      console.error("usage: set-methodology.cjs agile|waterfall|hybrid|--show");
      process.exit(1);
    }
    value = await choose();
  }
  if (!value || !valid(value)) {
    console.error(`[vibe] unknown methodology '${value}'. Choose: ${Object.keys(OPTIONS).join(", ")}.`);
    process.exit(1);
  }

  fs.mkdirSync(path.dirname(CONFIG), { recursive: true });
  fs.writeFileSync(CONFIG, apply(text || "version: 1\n", value));
  console.log(`[vibe] methodology: ${current(text) || "hybrid (unset)"} -> ${value}`);
  console.log(`[vibe] ${OPTIONS[value]}`);
  console.log("[vibe] already-approved work keeps its approval; record the switch in .agent/state.md.");
}

main();
