# PHP Ecosystem — Detection

**Manifest:** `composer.json`
**Lockfile → package manager:** `composer.lock` → Composer (the only PHP
package manager in common use; no ambiguity to resolve here, unlike JS).

**Scripts:** read `composer.json` → `"scripts"` first. A `Makefile` or
`Taskfile.yml` at the repo root wins over both if present.

**Test runner** — infer from what's installed, not from habit:
- `pestphp/pest` in `require-dev` → Pest (`./vendor/bin/pest`)
- else `phpunit/phpunit` → PHPUnit (`./vendor/bin/phpunit`)
- `phpunit.xml` / `phpunit.xml.dist` present → confirms PHPUnit config exists

**Lint / format / static analysis:**
- `laravel/pint` → Pint (`./vendor/bin/pint`, `--test` to check without fixing)
- `friendsofphp/php-cs-fixer` → PHP CS Fixer
- `phpstan/phpstan` → PHPStan (`./vendor/bin/phpstan analyse`)
- `vimeo/psalm` → Psalm

**CI is ground truth** — whatever `.github/workflows/*.yml` runs for PHP
is verified by every green build; prefer it over any command guessed here.

**Version:** `composer.json` → `"require": {"php": "..."}`, or `php -v`.
