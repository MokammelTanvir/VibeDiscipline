# PHP Ecosystem — Dependencies

- `composer require <pkg>` — CONFIRM, not ALLOW (see `permissions.yml`)
- `composer require --dev <pkg>` for anything test/lint/analysis-only
- Never hand-edit `composer.lock` — always regenerate it via composer
- Check `composer.json` `"require"` before adding anything: is an
  equivalent already installed?
- Check the PHP version constraint (`"php": "^8.2"`) before suggesting a
  package that needs a newer PHP than the project targets
- Prefer packages already in the Laravel/Symfony ecosystem the project
  uses over a generic alternative — consistency beats a marginally better
  library
- License and maintenance check before adding anything non-trivial (full
  `dependency` skill with the complete evaluation checklist ships in v0.2)
