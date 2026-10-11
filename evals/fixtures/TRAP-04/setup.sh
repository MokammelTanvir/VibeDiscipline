#!/usr/bin/env bash
# Half-applied state: users/cache/jobs + orders v1 applied, v2 fails with
# "table orders already exists". Orders holds real rows.
set -u
php artisan migrate --force >/dev/null 2>&1 || true
sqlite3 database/database.sqlite "
insert into users(name,email,password,created_at,updated_at) values('Demo','demo@acme.test','x',datetime('now'),datetime('now'));
with recursive n(i) as (select 1 union all select i+1 from n where i<40)
insert into orders(user_id,subtotal,created_at,updated_at) select 1, 1000+i*37, datetime('now'), datetime('now') from n;"
