---
name: recon
description: >
  Use before touching an unfamiliar codebase, before proposing architecture,
  before choosing a library, or whenever .agent/stack.lock.yml is missing or
  stale. Understands what already exists instead of guessing.
loads: [_shared/ceremony-tiers.md, _shared/config-resolution.md]
---

# Recon

Roughly 90% of real usage is an existing codebase. A recommendation made
before recon is a guess. This is the first skill that runs in any
unfamiliar repository, and it runs once — its output is cached.

## Procedure

1. **Structure** — map directories, identify the architectural style
   actually in use (MVC, layered, modular monolith, hexagonal, ad hoc).

2. **Stack** — detect languages, frameworks, package managers, runtimes,
   database, test runner, linters, formatters, type checkers, CI.
   Follow universal detection order:
   - manifest files (`composer.json`, `package.json`, ...)
   - the **lockfile** decides the package manager, never habit
     (`composer.lock` → composer, `pnpm-lock.yaml` → pnpm, etc.)
   - scripts from the manifest — `Makefile`/`Justfile` wins if present
   - tooling config files (`phpunit.xml`, `pest.php`, `.eslintrc`, ...)
   - **CI workflow is ground truth** — whatever `.github/workflows/*` runs
     is verified by every green build; prefer it over the README
   - README last, and only as a hint to verify against the above
   → write `.agent/stack.lock.yml` (if the repo layer exists; otherwise
     report the detected commands in the conversation)

3. **Conventions** — extract what this team *actually* does, from the
   code, not from ideals: naming, file placement per artifact type, error
   handling style, validation approach, test structure and naming, API
   response shape. → write `docs/CONVENTIONS.md` (Tier 2/3 only).

4. **Git reality** — `git log --oneline -100`. Learn the real commit
   message style, real branch naming, real commit size. Adopt it. Do not
   impose VibeDiscipline's own git defaults over an existing convention.

5. **Entry points** — routes, controllers, jobs, CLI commands, cron.

6. **Risk map** — where do auth, payments, PII, and migrations live?
   These paths auto-escalate one ceremony tier (see `_shared/ceremony-tiers.md`).

7. **Gaps** — missing tests, dead code, TODO clusters. **Report only.**
   Fixing unrequested gaps is unrequested work.

## Output format

```
Stack:        Laravel 11 · MySQL 8 · Pest · Pint · PHPStan
Package mgr:  composer (from composer.lock)
Architecture: Modular monolith, thin controllers, service layer
Conventions:  PascalCase models, {Model}Service, Pest feature tests
Git style:    Conventional commits, feature/* branches, squash merges
Risk areas:   app/Domain/Billing, app/Http/Middleware/Tenant
Gaps:         No tests on billing; 14 TODOs in app/Services/Report
```

## Rule

Recon completes before any architecture proposal, library choice, or
change larger than one line in an unfamiliar codebase. Results are cached
in `stack.lock.yml` / `CONVENTIONS.md` so this runs once per project, not
every session — re-run only when the stack visibly changes.
