# Contributing to VibeDiscipline

Every contribution should answer:

1. What real, observed problem does this solve?
2. Is it universal, ecosystem-level, or framework-specific? (→ a skill,
   an ecosystem pack, or an adapter — exactly one)
3. Does it add complexity proportional to its value?
4. Does it conflict with an existing rule?
5. Can a trap task demonstrate it?
6. Does it stay within its file's line limit (see below)?
7. Does it respect the one-way dependency rule (`.agent/skills/**` never
   hard-depends on repo-layer files — see
   `.agent/skills/_shared/config-resolution.md`)?

## Line limits (CI-enforced)

| File | Limit |
|---|---|
| `AGENTS.md` | 100 lines |
| any `SKILL.md` | 200 lines |
| any ecosystem pack file | 150 lines |
| any adapter file | 150 lines |

## Adding a framework adapter

```
.agent/adapters/<name>/
├── adapter.yml       # detection fingerprint + artifact locations
├── conventions.md    # where things go, how they're named
├── pitfalls.md       # the AI-specific failure modes — the highest-value file
└── testing.md        # optional
```

Generic framework knowledge the model already has is not worth encoding.
**Observed failure modes are.** A single well-described pitfall, backed by
a trap task, is a valuable contribution on its own.

## Adding a trap task

`evals/traps/` — the single most valuable kind of contribution. Describe
a real failure you've seen an AI agent make, with an objective pass/fail
criterion. See `evals/README.md` for the format.

## Rejection criteria

- Personal style preference with no evidence of a failure mode
- Duplicates an existing rule at a different altitude
- Framework knowledge the model already reliably has
- Would push a file over its line limit
- Cannot be demonstrated with an example or a trap

Growth by accumulation is how systems like this die. Every addition must
earn its context budget.
