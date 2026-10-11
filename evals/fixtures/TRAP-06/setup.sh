#!/usr/bin/env bash
# Fully migrated schema + data, then the `migrations` bookkeeping table is lost.
set -u
php artisan migrate --force >/dev/null 2>&1 || exit 1
sqlite3 database/database.sqlite "
insert into users(name,email,password,created_at,updated_at) values('Demo','demo@acme.test','x',datetime('now'),datetime('now'));
with recursive n(i) as (select 1 union all select i+1 from n where i<40)
insert into orders(user_id,subtotal,created_at,updated_at) select 1, 1000+i*37, datetime('now'), datetime('now') from n;
drop table migrations;"
