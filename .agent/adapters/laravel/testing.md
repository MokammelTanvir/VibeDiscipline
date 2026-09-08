# Laravel — Testing

- Feature tests: `$this->actingAs($user)->postJson('/orders', [...])
  ->assertStatus(201)->assertJsonPath('data.id', ...)` — assert on the
  actual response shape, not just the status code.
- Use `RefreshDatabase` (or the project's existing trait) so tests don't
  leak state between each other.
- Use model factories (`User::factory()->create()`) instead of manually
  constructing rows — matches the project's existing pattern and stays
  in sync with schema changes automatically.
- Test authorization explicitly: an unauthenticated or unauthorized
  request should get a test asserting the 401/403, not just the happy path.
- Queued jobs/notifications: use `Queue::fake()` / `Notification::fake()`
  and assert they were dispatched — don't let tests actually send mail or
  hit external services.
- One acceptance criterion → one test, named after the behavior
  (`it_returns_422_for_duplicate_email`), matching whichever of Pest or
  PHPUnit naming style the project already uses.
