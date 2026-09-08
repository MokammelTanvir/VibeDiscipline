# Laravel — Pitfalls AI Agents Reliably Hit

This is the highest-value file in the adapter — generic Laravel knowledge
the model already has is not worth encoding; specific failure modes are.

- Do not write raw SQL where Eloquent or the query builder already
  expresses the same thing idiomatically.
- Do not put business logic in controllers — this project (like most
  Laravel projects) expects a service or action layer for anything
  beyond orchestration.
- Do not skip Form Requests for validation, and do not validate inline in
  the controller if the project already uses Form Requests elsewhere.
- **N+1 queries**: before finishing any change that loads a model with
  relations in a loop or in a resource collection, check for a missing
  `->with(...)` / `->load(...)`. This is the single most common
  performance regression AI agents introduce in Laravel code.
- **Never edit a migration that has already run** in any environment —
  create a new migration instead. Editing history breaks teammates'
  local databases and any deployed environment.
- Use the project's existing `Notification`/`Mail` classes for outbound
  email — do not add a new mail library or call an SMTP client directly.
- Respect the queue: long-running work is dispatched (`Job::dispatch()`),
  not executed synchronously inside the request/response cycle.
- `php artisan migrate:fresh`, `migrate:reset`, and `db:wipe` **destroy
  data** — these are on the permissions deny-list; never suggest them as
  a shortcut, even in "just for testing" framing.
- Mass assignment: new model attributes must be added to `$fillable` (or
  guarded appropriately) — do not disable mass-assignment protection
  globally to make an error go away.
- Route model binding: prefer it over manual `Model::findOrFail($id)`
  lookups when the project already uses binding elsewhere.
- Config values belong in `config/*.php` files reading from `.env`, not
  hardcoded, and not read via `env()` outside the `config/` layer
  (Laravel caches config in production — `env()` calls elsewhere break
  under `config:cache`).
- Tinker (`php artisan tinker`) is for inspection, not for making data
  changes that should go through a migration or seeder.
