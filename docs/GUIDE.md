# VibeDiscipline user guide

How to install VibeDiscipline into your project, what changes once it is
there, and how to configure, upgrade and remove it.

- [Requirements](#requirements)
- [Install](#install)
- [Your first session](#your-first-session)
- [Tiers: how much process a change gets](#tiers-how-much-process-a-change-gets)
- [Approvals](#approvals)
- [Permissions](#permissions)
- [vibe check](#vibe-check)
- [Methodology](#methodology)
- [Configuration reference](#configuration-reference)
- [Command reference](#command-reference)
- [Upgrade](#upgrade)
- [Uninstall](#uninstall)
- [Troubleshooting](#troubleshooting)

## Requirements

- Node 18 or newer, bash, and git. On Windows use WSL or Git Bash.
- An AI coding agent that reads `AGENTS.md`. The skills and tiers work with
  any of them. Enforcement (compiled permissions, the guard hook, native
  skills) is built for **Claude Code** only; other tools get the git hooks
  and the CI workflow.

## Install

From your project's root:

```bash
npx github:MokammelTanvir/VibeDiscipline init
```

Or from a clone, which is the same installer:

```bash
git clone https://github.com/MokammelTanvir/VibeDiscipline.git
VibeDiscipline/scripts/install.sh /path/to/your/project
```

Preview first with `--dry-run`. Nothing you already have is overwritten:

| You already have | What the installer does |
|---|---|
| `AGENTS.md` | Puts VibeDiscipline's text above yours, between markers |
| `CLAUDE.md` | Adds one line pointing at `AGENTS.md` |
| `.claude/settings.json` with permissions | Leaves it alone and tells you; nothing is compiled |
| A git hooks path (husky, lefthook) | Leaves it alone and tells you how to call the hooks |
| Files under `.agent/` or `scripts/` | Keeps yours and lists them |

What gets added:

```
AGENTS.md              the rules every session starts from (about 70 lines)
.agent/skills/         how to do each kind of task
.agent/config.yml      your settings
.agent/permissions.yml what the agent may run and edit
.claude/               compiled settings, the guard hook, skill stubs
.githooks/             pre-commit (vibe check) and pre-push
scripts/               check.sh, the compiler, small helpers
docs/PERMISSIONS.md    a readable copy of the policy
```

The installer picks a permissions preset from your manifests: `laravel`,
`node`, `python`, or `generic`. Override it with `--stack <name>`. The preset
is a starting point; see [Permissions](#permissions).

Then do three things:

1. Open the project in Claude Code and **accept the trust dialog**. Until
   you do, Claude Code ignores the compiled allow-list (deny rules and the
   guard still apply).
2. Ask the agent to "run the recon skill". It reads your manifests, lockfile
   and CI, and writes the real test, lint and build commands to
   `.agent/stack.lock.yml`.
3. Run `npx github:MokammelTanvir/VibeDiscipline doctor`, then commit.

Want only the behaviour and no enforcement? `init --skills-only` copies
`.agent/skills/` and nothing else. In Claude Code you can get the same as a
plugin: `/plugin install vibediscipline --marketplace MokammelTanvir/VibeDiscipline`.

## Your first session

The agent now starts every piece of work by naming a tier:

```
Tier: S — bug fix in cart total, single file.
```

If you disagree, say so in a word ("that's XS", "treat it as M"). Then:

- A typo or copy change is edited, verified and done. No plan.
- A bug is reproduced first, fixed at its cause, and gets a regression test.
- A feature gets a short plan with acceptance criteria, and the agent
  **stops** until you approve it.
- A request that could mean several things gets questions, not a guess.

At the start of a session the agent reads `.agent/state.md`, its own notes
from last time, and tells you what it is resuming. At the end it updates them.

## Tiers: how much process a change gets

| Tier | Covers | What happens |
|---|---|---|
| **XS** | Typo, copy, comment, config value | Edit, verify, commit |
| **S** | Bug fix, small enhancement, one file | Reproduce, root cause, fix, regression test, self-review |
| **M** | A feature, a schema addition | Plan with acceptance criteria, **your approval**, implement, tests, review |
| **L** | A new subsystem, an architectural change | PRD, TRD, ADRs, task breakdown, **your approval**, then the M loop per task |

The agent defaults to the lowest tier that fits and moves up for a schema
or public API change, a new dependency, payments or personal data, more
than about five files, or an unclear requirement.

## Approvals

At Tier M and L nothing is built until you approve the plan. Say "approved"
or "go ahead" about that specific plan. Silence is not approval, and a
change to scope or approach asks again.

When your project has a `docs/tasks/` directory, each plan is saved there
with `approved_by` and `approved_at`, and `docs/tasks/BOARD.md` lists them.
Create that directory if you want the record; without it the plan stays in
the conversation.

Running unattended? An agent that correctly stops for approval produces
nothing. Put the approval in the instruction ("this is approved, implement
it"), or set `workflow.approval_gate_tier: L`.

## Permissions

`.agent/permissions.yml` is the one place you edit. Three lists each for
commands and files:

```yaml
commands:
  allow:   ["npm test*"]            # runs without asking
  confirm: ["npm install *"]        # asks you first
  deny:    ["git reset --hard*"]    # refused, always
files:
  allow:   ["src/**"]
  confirm: ["package.json", ".env*"]
  deny:    ["**/*.pem"]
```

`*` matches anything. A pattern that starts with `*` matches anywhere in
the command. Deny beats confirm beats allow. After every edit:

```bash
node scripts/compile-permissions.cjs
```

This rewrites `.claude/settings.json`, the guard hook's policy, the git
hooks and `docs/PERMISSIONS.md`. Never edit those by hand.

`mode` at the top of the file: `auto` (allow runs freely, confirm asks),
`guided` (every command and write asks), `strict` (reads ask too).

**The guard hook.** Claude Code's own rules match the start of a command,
so `bash -c "git reset --hard"` gets past a deny on `git reset --hard*`.
The guard looks inside `bash -c`, `eval`, `env`, `sudo`, `xargs`, `$(...)`
and chained commands and applies your policy to what is really being run.
It cannot see a command that is written to a script file and then executed.

**What is advisory.** The `network` section and anything about tools other
than Claude Code are instructions the agent reads, not rules a program
enforces.

## vibe check

`scripts/check.sh` runs on every commit through the pre-commit hook, and you
can run it yourself:

```bash
scripts/check.sh            # working tree
scripts/check.sh --staged   # what is about to be committed
scripts/check.sh --task 12  # scope-check against docs/tasks/TASK-012-*.md
```

| Check | Finds |
|---|---|
| `secrets` | Key formats and credential literals, a staged `.env` |
| `leftovers` | `dd()`, `var_dump()`, `console.log()`, `debugger`, `binding.pry`, `breakpoint()`; a TODO with no owner |
| `scope` | Files changed that the task doc's "Affected Areas" does not list |
| `dependency` | A manifest or lockfile change that no task doc mentions |
| `tests` | Source changed with no test file touched |

A `FAIL` blocks the commit; a `WARN` is printed. Which is which is yours to
set in `.agent/config.yml` under `check`. `scope` only runs while a task doc
has `status: in-progress` or `review`.

## Methodology

Tiers decide how much process; the methodology decides its order and where
you are asked to approve.

```bash
node scripts/set-methodology.cjs              # menu
node scripts/set-methodology.cjs waterfall
node scripts/set-methodology.cjs --show
```

| | At Tier L |
|---|---|
| `hybrid` (default) | The document set up front, one approval, then task by task |
| `agile` | A one-page brief and a backlog; approval per increment, thinnest slice first |
| `waterfall` | Five phases in order (requirements, design, build, verify, release), approval after each |

Below Tier L the three behave almost the same on purpose.

## Configuration reference

`.agent/config.yml`:

| Key | Values | Meaning |
|---|---|---|
| `workflow.methodology` | `hybrid`, `agile`, `waterfall` | See above |
| `workflow.require_plan` | `true`, `false` | `false`: a Tier M plan may stay in the conversation |
| `workflow.require_tests` | `true`, `false` | `false`: a change may ship without a new test, and says so |
| `workflow.require_review` | `true`, `false` | `false`: the self-review pass may be skipped |
| `workflow.require_security_review` | `true`, `false` | `false`: skipped except on auth, payment and personal-data paths |
| `workflow.approval_gate_tier` | `M`, `L` | Lowest tier that needs your recorded approval |
| `commit.attribution_trailer` | `true`, `false` | Add an AI co-author trailer to commits |
| `git.protect_main_branch` | `true`, `false` | `true`: the pre-push hook refuses a direct push to main, for everyone |
| `check.fail_on` | list of checks | Findings that block a commit |
| `check.warn_on` | list of checks | Findings that are only printed |
| `check.ignore` | list of globs | Paths left out of every check |

The `workflow.*` flags are read by the agent, not by a program. After
changing `git.protect_main_branch`, recompile.

## Command reference

Every command below also works as `npx github:MokammelTanvir/VibeDiscipline <command>`.

| Command | Does |
|---|---|
| `vibe init [dir]` | Install. Options: `--stack`, `--methodology`, `--skills-only`, `--dry-run`, `--force` |
| `vibe upgrade [dir]` | Refresh skills, packs, adapters and scripts; keep your config, permissions and state |
| `vibe doctor [dir]` | Check the installation and print the fix for each problem |
| `vibe check [--staged] [--task <id>]` | Run vibe check |
| `vibe compile` | Recompile permissions and skill stubs |
| `vibe methodology [value\|--show]` | Show or set the methodology |
| `vibe version` | Print the version |

The scripts in your project's `scripts/` do the same work without the CLI:
`check.sh`, `compile-permissions.cjs`, `bridge-claude.cjs`,
`set-methodology.cjs`.

## Upgrade

```bash
npx github:MokammelTanvir/VibeDiscipline upgrade
```

It replaces `.agent/skills/`, `.agent/ecosystems/`, `.agent/adapters/` and
the scripts, refreshes the VibeDiscipline block in `AGENTS.md`, recompiles,
and lists every file it changed. It never touches `config.yml`,
`permissions.yml` or `state.md`. If you edited a skill by hand, that edit is
replaced: commit before upgrading so you can see the diff.

## Uninstall

1. Delete `.agent/`, `.githooks/`, `.claude/hooks/vibe-*` and
   `.claude/skills/vibe-*`.
2. In `.claude/settings.json`, remove the generated `permissions` block and
   the `vibe-guard` entry under `hooks`. Do this together with step 1, or
   every shell command will report a missing hook.
3. `git config --unset core.hooksPath`
4. Remove the block between `<!-- vibediscipline:start -->` and
   `<!-- vibediscipline:end -->` in `AGENTS.md`, and the pointer line in
   `CLAUDE.md`.
5. Delete the copied files in `scripts/` and `docs/PERMISSIONS.md`.

## Troubleshooting

Run `vibe doctor` first; it covers most of these.

**The agent does not state a tier.** It has not read `AGENTS.md`. Check
that the VibeDiscipline block is in it, and that `CLAUDE.md` points at it.

**Claude Code asks about commands that are on the allow-list.** The trust
dialog was not accepted, or the command is chained (`a && b`): each part
must be allowed on its own.

**A commit is blocked.** Read the `FAIL` lines; each names the file or the
line. To change what blocks, edit `check.fail_on`. `git commit --no-verify`
is on the deny list for the agent on purpose.

**A harmless command is refused with "matches the deny rule".** A pattern
that starts with `*`, such as `*DROP TABLE*`, matches that text anywhere in
the command, including inside a heredoc or a message. Rephrase the command
or narrow the pattern in `permissions.yml`.

**The agent stops and asks too often.** That is the design at Tier M and L.
If a task is smaller than it judged, tell it the tier. To loosen it for the
whole project, set `workflow.approval_gate_tier: L`.

**My own git hooks stopped running, or VibeDiscipline's are not running.**
`git config --get core.hooksPath` shows which directory is active. The
installer never replaces an existing value; call `.githooks/pre-commit`
from your own pre-commit hook to have both.

**Something else.** Open an issue:
https://github.com/MokammelTanvir/VibeDiscipline/issues
