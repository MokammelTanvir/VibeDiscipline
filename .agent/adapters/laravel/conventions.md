# Laravel — Conventions

These are defaults to fall back on **only when the project shows no
convention of its own** (check via `recon` first — an observed project
convention always wins, per the composition precedence rules).

## Structure

- Thin controllers: a controller method orchestrates, it does not contain
  business logic. If a method is doing validation + business rules +
  response shaping, extract the business rules into a service or action.
- Validation lives in Form Requests (`app/Http/Requests`), not inline in
  the controller with `$request->validate([...])`, unless the project
  already does the latter consistently.
- Authorization lives in Policies (`app/Policies`) registered against the
  model, invoked via `$this->authorize(...)` or `Gate::` — not scattered
  `if ($user->id !== $model->user_id)` checks in controllers.
- Eloquent models hold relationships, scopes, and casts. Business logic
  that spans multiple models belongs in a service, not in a fat model.

## Routing

- RESTful resource routes (`Route::resource`) for CRUD-shaped controllers,
  matching the project's existing route file organization
  (`routes/web.php`, `routes/api.php`, or route groups per domain).
- Route names follow the existing dot-notation convention
  (`orders.show`, `orders.store`) if the project uses one.

## Database

- One migration per schema change, named descriptively
  (`add_verified_at_to_users_table`), never a generic `update_users_table`
  reused across multiple unrelated changes.
- Foreign keys get `constrained()` and an explicit `onDelete()` behavior —
  do not leave cascade behavior implicit.
- Factories and seeders stay in sync with the model's actual columns.

## Queues and jobs

- Anything slower than a fast synchronous response (sending mail,
  calling an external API, generating a report) is dispatched to a queue
  via a Job, not run inline in the request cycle.

## Frontend composition

- If Inertia is detected: page components live under
  `resources/js/Pages/**`, matching controller `Inertia::render()` calls
  1:1. Shared UI goes in `resources/js/Components/**`.
- If Blade only: views live in `resources/views/**`, mirroring the
  controller/route structure; components in `resources/views/components/`.
- If Livewire is detected: component classes in `app/Livewire/` (or
  `app/Http/Livewire/` on older versions — check which exists).
