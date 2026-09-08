# Security Policy

VibeDiscipline is an engineering-process layer, not a runtime dependency
— it ships no server, no service, and executes no code of its own beyond
the small local scripts in `scripts/`. Even so, please report security
concerns responsibly.

## Reporting

Do not open a public issue for a security concern. Instead, use GitHub's
private vulnerability reporting for this repository, or contact the
maintainer directly.

## Scope

Of particular interest:

- A `permissions.yml` pattern that fails to block a command it claims to block
- A gap in `scripts/compile-permissions.cjs` that produces a weaker
  `.claude/settings.json` or git hook than the source policy intends
- A `vibe check` false-negative on a real secret-exposure pattern
- Any adapter or skill instruction that would lead an agent to expose
  secrets, bypass permissions, or run a destructive command

## Out of scope

- False positives in `vibe check` heuristics (open a normal issue)
- Missing framework adapters (open a normal issue or PR)
