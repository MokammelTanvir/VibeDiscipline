---
name: config-resolution
description: >
  The graceful-degradation contract every skill must follow. Ensures the
  skills layer never hard-depends on repo-layer files — it only becomes
  richer when they exist.
---

# Config Resolution Contract

Every skill resolves context through this ladder, and must remain fully
functional at every rung. **The repo layer makes skills richer. It never
makes them functional.** A skill that breaks when a repo-layer file is
absent violates this contract and must be fixed.

```
1. .agent/config.yml exists?
     → read stack, mode, workflow flags from it
   else
     → detect from the codebase (manifests, lockfiles, CI)

2. .agent/permissions.yml exists?
     → enforce it
   else
     → conservative default: anything destructive, network-mutating, or
       secret-touching requires confirmation

3. .agent/stack.lock.yml exists?
     → use the resolved commands
   else
     → probe the project, propose commands, confirm once, then (if the
       repo layer exists) offer to write stack.lock.yml

4. docs/tasks/ exists?
     → write task docs and update BOARD.md
   else
     → keep the plan in-conversation; do NOT create a docs tree uninvited

5. .agent/state.md exists?
     → read it at session start, write it at session end
   else
     → summarize state in the final message instead of creating a file

6. .agent/adapters/<framework>/ exists?
     → use adapter depth (conventions.md, pitfalls.md)
   else
     → fall back to the ecosystem pack, then to universal detection
```

## Why this matters

A skill copied standalone into an existing project (Tier 1, Section 6 of
the plan) has none of the repo-layer files. If any skill assumes their
presence, it breaks the moment it leaves this template — which defeats
the entire point of shipping a portable skills layer.

## Enforcement

`scripts/validate-portability.sh` scans `.agent/skills/**` for hard
references to `docs/`, `.agent/permissions.yml`, `.agent/config.yml`, or
`.agent/adapters/` that are not inside an explicit "if present" branch,
and fails if it finds one.
