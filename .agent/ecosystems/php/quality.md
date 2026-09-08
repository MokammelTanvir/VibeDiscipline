# PHP Ecosystem — Quality Tooling

Run whatever the project has configured, via its own scripts:

```
composer test    (if defined)      → the project's chosen test runner
composer lint    (if defined)      → Pint / PHP CS Fixer
composer analyse (if defined)      → PHPStan / Psalm
```

If no composer scripts exist, fall back to the binaries directly
(`./vendor/bin/pest`, `./vendor/bin/pint --test`,
`./vendor/bin/phpstan analyse`) — never install a new tool when one is
already present in `vendor/bin`.

Respect the project's PHPStan/Psalm level — do not silently lower it to
make a change pass, and do not raise it without being asked (that's an
architectural/quality decision, escalate the ceremony tier).
