#!/usr/bin/env bash
# OFFSET or keyset? The two experiments that need two sessions at once.
# https://constantine2nd.github.io/offset-or-keyset-it-depends-who-is-reading/
#
# Run offset-vs-keyset.sql first, in the same database: this uses its table of 1,000,000 events.
#
#   curl -O https://constantine2nd.github.io/assets/sql/offset-vs-keyset-concurrent.sh
#   bash offset-vs-keyset-concurrent.sh pagination_demo
#
# 1. Other requests beside a machine reading every page. Primary-key lookups on a table of their own,
#    half the size of shared_buffers, loaded into it first; 30 seconds alone, then beside an OFFSET walker,
#    then beside a keyset walker. pg_buffercache counts how much of their table is still cached after.
# 2. A walk while rows arrive and leave: 100 new rows and 100 deletions a second, while a walker reads
#    every page. Counted against the rows that were there for the whole walk: each should arrive once.
#
# Needs pgbench, and CREATE EXTENSION rights for pg_prewarm and pg_buffercache. About 4 minutes.
# Changes the events table (section 2): run offset-vs-keyset.sql again to start clean.
set -euo pipefail
DB=${1:?usage: $0 <database>}
export PGOPTIONS='-c client_min_messages=warning'
P="psql -X -q -At -v ON_ERROR_STOP=1 -d $DB"
T=$(mktemp -d); trap 'rm -rf "$T"; $P -c "SELECT pg_cancel_backend(pid) FROM pg_stat_activity WHERE application_name = '"'"'walker'"'"'" >/dev/null 2>&1 || true' EXIT

# A walker: every page of 1,000, in order, until one comes back short; again and again until cancelled.
# With a table name as $2 it also records the id of every row it receives.
walker() {
  local strategy=$1 seen=${2:-}
  local keep=""; [ -n "$seen" ] && keep="INSERT INTO $seen SELECT unnest(ids);"
  local loop="LOOP"; [ -n "$seen" ] && loop="FOR once IN 1..1 LOOP"
  PGAPPNAME=walker $P <<SQL
DO \$\$
DECLARE n int; done bigint; c timestamptz; i bigint; ids bigint[]; q text; bytes bigint;
BEGIN
  $loop
    done := 0; c := NULL;
    LOOP
      IF '$strategy' = 'offset' THEN
        q := format('SELECT * FROM events ORDER BY created_at DESC, id DESC LIMIT 1000 OFFSET %s', done);
      ELSIF c IS NULL THEN
        q := 'SELECT * FROM events ORDER BY created_at DESC, id DESC LIMIT 1000';
      ELSE
        q := format('SELECT * FROM events WHERE (created_at, id) < (%L, %s) ORDER BY created_at DESC, id DESC LIMIT 1000', c, i);
      END IF;
      EXECUTE format('SELECT count(*), array_agg(id), (array_agg(created_at ORDER BY created_at, id))[1],
                             (array_agg(id ORDER BY created_at, id))[1], sum(length(p::text)) FROM (%s) p', q)
         INTO n, ids, c, i, bytes;
      $keep
      EXIT WHEN n < 1000;
      done := done + n;
      PERFORM pg_sleep(0.005);
    END LOOP;
  END LOOP;
END \$\$;
SQL
}

echo "== 1. Other requests beside a machine reading every page"
$P -c "CREATE EXTENSION IF NOT EXISTS pg_prewarm; CREATE EXTENSION IF NOT EXISTS pg_buffercache;"
$P <<'SQL'
DROP TABLE IF EXISTS neighbour;
CREATE TABLE neighbour AS
SELECT g AS id, repeat(md5(g::text), 6) AS payload
  FROM generate_series(1, (SELECT setting::bigint * 8192 / 2 / 300 FROM pg_settings WHERE name = 'shared_buffers')) g;
ALTER TABLE neighbour ADD PRIMARY KEY (id);
VACUUM ANALYZE neighbour;
SQL
N=$($P -c "SELECT count(*) FROM neighbour")
PAGES=$($P -c "SELECT (pg_relation_size('neighbour') + pg_relation_size('neighbour_pkey')) / 8192")
printf '\\set id random(1, %s)\nSELECT * FROM neighbour WHERE id = :id;\n' "$N" > "$T/lookup.sql"
cached() {
  $P -c "SELECT count(*) FROM pg_buffercache b JOIN pg_class c ON b.relfilenode = pg_relation_filenode(c.oid)
          AND b.reldatabase = (SELECT oid FROM pg_database WHERE datname = current_database())
          WHERE c.relname IN ('neighbour', 'neighbour_pkey')"
}
printf '%-22s %10s %10s %22s\n' "other requests" "tps" "latency" "their pages cached"
for cond in alone offset keyset; do
  $P -c "SELECT pg_prewarm('neighbour'), pg_prewarm('neighbour_pkey')" >/dev/null
  before=$(cached)
  # the walker is cancelled when the lookups are done: that error is expected, and not shown
  if [ "$cond" != alone ]; then walker "$cond" 2>/dev/null & sleep 2; fi
  out=$(pgbench -n -M prepared -c 4 -j 4 -T 30 -f "$T/lookup.sql" "$DB" 2>/dev/null)
  after=$(cached)
  if [ "$cond" != alone ]; then
    $P -c "SELECT pg_cancel_backend(pid) FROM pg_stat_activity WHERE application_name = 'walker'" >/dev/null
    wait || true
  fi
  label=$cond; [ "$cond" != alone ] && label="beside $cond walker"
  printf '%-22s %10s %10s %22s\n' "$label" "$(sed -n 's/^tps = \([0-9]*\).*/\1/p' <<<"$out")" \
         "$(sed -n 's/^latency average = \(.*\)/\1/p' <<<"$out")" "$before -> $after of $PAGES"
done
$P -c "DROP TABLE neighbour"

echo
echo "== 2. Every page while rows arrive and leave (100 new, 100 deleted a second)"
cat > "$T/insert.sql" <<'SQL'
INSERT INTO events (created_at, account_id, kind, payload)
SELECT created_at, account_id, kind, payload FROM events ORDER BY created_at DESC, id DESC LIMIT 1;
SQL
cat > "$T/delete.sql" <<'SQL'
DELETE FROM events WHERE ctid = (SELECT ctid FROM events TABLESAMPLE SYSTEM (0.1) LIMIT 1);
SQL
printf '%-10s %12s %12s %12s %12s\n' "strategy" "changes" "received" "duplicated" "missed"
for s in offset keyset; do
  $P -c "DROP TABLE IF EXISTS before, seen; CREATE TABLE before AS SELECT id FROM events; CREATE TABLE seen (id bigint)"
  pgbench -n -c 2 -j 2 -R 200 -T 3600 -f "$T/insert.sql@1" -f "$T/delete.sql@1" "$DB" >/dev/null 2>&1 &
  writer=$!
  sleep 1
  walker "$s" seen
  kill $writer; wait $writer 2>/dev/null || true
  $P -F ' ' <<'SQL' | while read -r ch rec dup mis; do printf '%-10s %12s %12s %12s %12s\n' "$s" "$ch" "$rec" "$dup" "$mis"; done
CREATE TEMP TABLE after AS SELECT id FROM events;
SELECT (SELECT count(*) FROM after a WHERE NOT EXISTS (SELECT 1 FROM before b WHERE b.id = a.id))
     + (SELECT count(*) FROM before b WHERE NOT EXISTS (SELECT 1 FROM after a WHERE a.id = b.id)),
       (SELECT count(*) FROM seen),
       (SELECT count(*) - count(DISTINCT id) FROM seen),
       (SELECT count(*) FROM before b WHERE EXISTS (SELECT 1 FROM after a WHERE a.id = b.id)
                                        AND NOT EXISTS (SELECT 1 FROM seen s WHERE s.id = b.id));
SQL
done
$P -c "DROP TABLE before, seen"
