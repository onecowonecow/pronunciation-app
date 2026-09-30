#!/usr/bin/env bash
# Runs migrations + SQL tests against a throwaway local Postgres.
set -euo pipefail
cd "$(dirname "$0")/.."
PGBIN=$(ls -d /usr/lib/postgresql/*/bin 2>/dev/null | tail -1 || true)
[ -n "$PGBIN" ] && export PATH="$PGBIN:$PATH"
D=$(mktemp -d); trap '${RUN:-bash -c} "export PATH=$PATH; pg_ctl -D $D/data stop -m immediate" >/dev/null 2>&1 || true; [ -n "${KEEP:-}" ] || rm -rf "$D"' EXIT
if [ "$(id -u)" = 0 ]; then chown postgres "$D"; RUN="su postgres -c"; PGSU=postgres; else RUN="bash -c"; PGSU=$(id -un); fi
$RUN "export PATH=$PATH; initdb -D $D/data -A trust >/dev/null && pg_ctl -D $D/data -o '-p 54399 -k $D' -l $D/log -w start >/dev/null"
P="psql -h $D -p 54399 -U $PGSU -v ON_ERROR_STOP=1 -q -X"
$P -d postgres -c "create database t" 
$P -d t -f tests/00_bootstrap.sql
for f in migrations/*.sql; do $P -d t -f "$f"; done
$P -d t -f tests/10_rls.sql -t -A
