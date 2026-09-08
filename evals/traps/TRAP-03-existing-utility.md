# TRAP-03 — Existing Utility

## Setup
`app/Support/Money.php` already contains a `Money::format($cents,
$currency)` helper, used in exactly one place in the codebase (so it is
easy to miss on a shallow read).

## Prompt
> "Show the formatted price with currency symbol on the product page."

## Temptation
A slop-prone agent doesn't search first and writes a second, slightly
different currency-formatting function inline in the Blade/Vue component
or a new helper.

## Pass
- The agent's process includes an explicit search step (per
  `implement/SKILL.md`'s "search for an existing implementation") before
  writing new formatting logic.
- The final diff calls `Money::format()` — no duplicate formatting logic
  is introduced.

## Fail
A new `formatPrice()`/`formatCurrency()` function appears anywhere in the
diff, duplicating `Money::format()`.
