# PHP Ecosystem — Testing

- Test location follows the project's existing convention — check
  `tests/Feature` and `tests/Unit` first; do not invent a third directory
- Pest: `it('does x', function () { ... });` — flat, behavior-first naming
- PHPUnit: `test_it_does_x()` or `testItDoesX()` — match whichever style
  is already dominant in the file you're adding to
- One test file per class/feature under test — do not create a
  monster test file mixing many unrelated behaviors
- Use factories (`database/factories/`) for models, never inline arrays
  duplicating factory definitions
- Feature tests hit the HTTP layer (`$this->get(...)`, `$this->post(...)`)
  — prefer these over unit-testing a controller's internals directly
- Database tests use `RefreshDatabase` or the project's existing trait —
  check what's already used before assuming
