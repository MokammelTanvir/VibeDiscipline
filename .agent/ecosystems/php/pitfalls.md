# PHP Ecosystem — Pitfalls AI Agents Reliably Hit

- Do not add a Composer package for something the standard library or an
  already-installed package already does
- Respect PSR-4 autoloading — the namespace must match the directory
  structure declared in `composer.json` `"autoload"`
- Never edit files under `vendor/` — changes there are lost on the next
  `composer install` and are invisible to the rest of the team
- Match the project's `declare(strict_types=1);` convention — check a few
  existing files before deciding whether to add it to a new one
- Do not silence a static analysis error with an inline suppress comment
  as a substitute for actually fixing the type issue
- `null` coalescing (`??`) is not a substitute for validating required
  input — it hides missing data instead of surfacing it
