#!/usr/bin/env bash
# Build the plain, bootable Laravel app that every eval fixture is overlaid on.
#
# Usage: build-skeleton.sh <source-laravel-repo> <commit> <out-dir>
#
# Takes a clean Laravel scaffold commit (no VibeDiscipline files), copies the
# already-installed vendor/ from the source working tree (no network), strips
# anything VibeDiscipline/Boost-shaped, and generates an .env + APP_KEY.
set -euo pipefail

SRC="${1:?source laravel repo}"; COMMIT="${2:?commit}"; OUT="${3:?out dir}"
[ -e "$OUT" ] && { echo "refusing to overwrite $OUT" >&2; exit 1; }

mkdir -p "$OUT"
git -C "$SRC" archive "$COMMIT" | tar -x -C "$OUT"
cp -cR "$SRC/vendor" "$OUT/vendor" 2>/dev/null || cp -R "$SRC/vendor" "$OUT/vendor"

cd "$OUT"
rm -rf .agent AGENTS.md CLAUDE.md AGENTS.laravel-boost-bootstrap.md scripts docs .claude .githooks
cp .env.example .env
php artisan key:generate --force >/dev/null
mkdir -p database storage/framework/{cache,sessions,views} storage/logs bootstrap/cache
: > database/database.sqlite
php artisan --version
