-- OFFSET or keyset? It depends on who is reading.
-- https://constantine2nd.github.io/offset-or-keyset-it-depends-who-is-reading/
--
-- One page at a time, the way a person pages through a screen, and every page in order, the way an
-- export or another service does. Needs PostgreSQL 12+. Builds its own table of 1,000,000 rows
-- (about 300 MB) and takes about 5 minutes, most of it OFFSET reading every page.
--
--   curl -O https://constantine2nd.github.io/assets/sql/offset-vs-keyset.sql
--   createdb pagination_demo
--   psql -X -d pagination_demo -f offset-vs-keyset.sql
--   dropdb pagination_demo
--
-- Buffers and rows read are the numbers to compare: they do not depend on the machine. Times do, and
-- are medians of 5 runs after one that is not counted.

\set ON_ERROR_STOP on
\set QUIET on
\pset pager off
\pset footer off
SET client_min_messages = warning;

\echo '== 1. A table of events: 1,000,000 rows, four to a second, so the sort column has ties'
DROP TABLE IF EXISTS events, events_100k, events_300k;
CREATE TABLE events (
  id         bigserial   PRIMARY KEY,
  created_at timestamptz NOT NULL,
  account_id int         NOT NULL,
  kind       text        NOT NULL,
  payload    text        NOT NULL
);
INSERT INTO events (created_at, account_id, kind, payload)
SELECT timestamptz '2026-09-01' + (g / 4) * interval '1 second', g % 5000,
       (ARRAY['created', 'paid', 'shipped', 'cancelled'])[1 + g % 4], repeat(md5(g::text), 6)
  FROM generate_series(1, 1000000) g;
-- the index both need: newest first, ties broken by id
CREATE INDEX events_created ON events (created_at DESC, id DESC);
VACUUM ANALYZE events;
SELECT pg_size_pretty(pg_table_size('events')) AS "table", pg_size_pretty(pg_indexes_size('events')) AS indexes,
       current_setting('shared_buffers') AS shared_buffers;

-- What one query costs: median time of 5 runs, buffers touched, rows its scans read (skipped ones too).
CREATE FUNCTION pg_temp.cost(q text, OUT ms numeric, OUT buffers bigint, OUT rows_read bigint)
LANGUAGE plpgsql AS $$
DECLARE plan jsonb; t numeric[] := '{}';
BEGIN
  EXECUTE 'EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) ' || q INTO plan;          -- not counted
  FOR i IN 1..5 LOOP
    EXECUTE 'EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) ' || q INTO plan;
    t := t || (plan -> 0 ->> 'Execution Time')::numeric;
  END LOOP;
  ms := round((SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY x) FROM unnest(t) x)::numeric, 3);
  buffers := (plan -> 0 -> 'Plan' ->> 'Shared Hit Blocks')::bigint + (plan -> 0 -> 'Plan' ->> 'Shared Read Blocks')::bigint;
  rows_read := (SELECT sum((n ->> 'Actual Rows')::bigint * (n ->> 'Actual Loops')::bigint)
                  FROM jsonb_path_query(plan, 'strict $.** ? (@."Node Type" like_regex "Scan" && @."Node Type" != "Bitmap Index Scan")') n);
END $$;

-- The three ways to ask for the page that starts after `depth` rows. Keyset needs the last row of the
-- page before; here it is looked up, the way a client would have kept it.
CREATE FUNCTION pg_temp.page(strategy text, depth bigint, size int, tbl text DEFAULT 'events') RETURNS text
LANGUAGE plpgsql AS $$
DECLARE c timestamptz; i bigint;
BEGIN
  IF strategy = 'offset' THEN
    RETURN format('SELECT * FROM %I ORDER BY created_at DESC, id DESC LIMIT %s OFFSET %s', tbl, size, depth);
  ELSIF strategy = 'deferred' THEN
    RETURN format('SELECT t.* FROM %I t JOIN (SELECT created_at, id FROM %I ORDER BY created_at DESC, id DESC '
                  'LIMIT %s OFFSET %s) s ON t.id = s.id ORDER BY t.created_at DESC, t.id DESC', tbl, tbl, size, depth);
  ELSIF depth = 0 THEN
    RETURN format('SELECT * FROM %I ORDER BY created_at DESC, id DESC LIMIT %s', tbl, size);
  END IF;
  EXECUTE format('SELECT created_at, id FROM %I ORDER BY created_at DESC, id DESC OFFSET %s LIMIT 1', tbl, depth - 1)
     INTO c, i;
  RETURN format('SELECT * FROM %I WHERE (created_at, id) < (%L, %s) ORDER BY created_at DESC, id DESC LIMIT %s',
                tbl, c, i, size);
END $$;

\echo
\echo '== 2. A person: one page of 20, at increasing depth. Pages 1 to 11 first, then deep.'
SELECT d AS depth, d / 20 + 1 AS page,
       o.ms AS offset_ms, o.rows_read AS offset_rows_read, o.buffers AS offset_buffers,
       k.ms AS keyset_ms, k.rows_read AS keyset_rows_read, k.buffers AS keyset_buffers,
       j.ms AS deferred_ms, j.buffers AS deferred_buffers
  FROM unnest(ARRAY[0, 20, 40, 60, 80, 100, 120, 140, 160, 180, 200, 1000, 10000, 100000, 500000, 999980]) d,
       pg_temp.cost(pg_temp.page('offset', d, 20)) o,
       pg_temp.cost(pg_temp.page('keyset', d, 20)) k,
       pg_temp.cost(pg_temp.page('deferred', d, 20)) j;

\echo
\echo '== 3. The data moves between page 1 and page 2 (on a copy of the newest 1,000 rows)'
CREATE TEMP TABLE recent AS SELECT * FROM events ORDER BY created_at DESC, id DESC LIMIT 1000;
ALTER TABLE recent ADD PRIMARY KEY (id);
CREATE TEMP TABLE page1 AS SELECT id FROM recent ORDER BY created_at DESC, id DESC LIMIT 20;
-- a new event arrives at the top: a copy of the newest, with a new id
INSERT INTO recent (id, created_at, account_id, kind, payload)
SELECT 2000000, created_at, account_id, kind, payload FROM recent ORDER BY created_at DESC, id DESC LIMIT 1;
SELECT 'a row arrived' AS "between page 1 and 2",
       (SELECT count(*) FROM (SELECT id FROM recent ORDER BY created_at DESC, id DESC LIMIT 20 OFFSET 20) p
         WHERE id IN (SELECT id FROM page1)) AS "OFFSET page 2 repeats",
       (SELECT count(*) FROM (SELECT id FROM recent r WHERE (created_at, id) <
               (SELECT created_at, id FROM recent WHERE id = (SELECT min(id) FROM page1 WHERE id < 2000000))
         ORDER BY created_at DESC, id DESC LIMIT 20) p WHERE id IN (SELECT id FROM page1)) AS "keyset page 2 repeats";
-- start over, and this time a row the reader already saw is deleted
DELETE FROM recent WHERE id = 2000000;
CREATE TEMP TABLE due AS SELECT id FROM recent ORDER BY created_at DESC, id DESC LIMIT 20 OFFSET 20;
DELETE FROM recent WHERE id = (SELECT max(id) FROM page1);
SELECT 'a row was deleted' AS "between page 1 and 2",
       (SELECT count(*) FROM due WHERE id NOT IN
         (SELECT id FROM recent ORDER BY created_at DESC, id DESC LIMIT 20 OFFSET 20)) AS "OFFSET page 2 never shows",
       (SELECT count(*) FROM due WHERE id NOT IN
         (SELECT id FROM recent WHERE (created_at, id) < (SELECT created_at, id FROM recent WHERE id = (SELECT min(id) FROM page1))
           ORDER BY created_at DESC, id DESC LIMIT 20)) AS "keyset page 2 never shows";

\echo
\echo '== 4. A machine: every page of 1,000, in order, on 100,000, 300,000 and 1,000,000 rows'
\echo '   (OFFSET and the deferred join on the full table take several minutes each)'
CREATE TABLE events_100k AS SELECT * FROM events WHERE id <= 100000;
ALTER TABLE events_100k ADD PRIMARY KEY (id);
CREATE INDEX ON events_100k (created_at DESC, id DESC);
CREATE TABLE events_300k AS SELECT * FROM events WHERE id <= 300000;
ALTER TABLE events_300k ADD PRIMARY KEY (id);
CREATE INDEX ON events_300k (created_at DESC, id DESC);
VACUUM ANALYZE events_100k, events_300k;

-- Every page, the way a client asks for them: until one comes back short. Buffers and rows read from
-- EXPLAIN of each page; time from running each page for real (every column turned into text).
CREATE FUNCTION pg_temp.walk(strategy text, tbl text, size int,
                             OUT pages int, OUT seconds numeric, OUT rows_read bigint, OUT buffers bigint,
                             OUT first_page_buffers bigint, OUT last_page_buffers bigint)
LANGUAGE plpgsql AS $$
DECLARE n int; done bigint := 0; c timestamptz; i bigint; q text; plan jsonb; b bigint; t0 timestamptz;
        e numeric := 0;
BEGIN
  pages := 0; rows_read := 0; buffers := 0;
  LOOP
    IF strategy = 'keyset' AND done > 0 THEN
      q := format('SELECT * FROM %I WHERE (created_at, id) < (%L, %s) ORDER BY created_at DESC, id DESC LIMIT %s',
                  tbl, c, i, size);
    ELSE
      q := pg_temp.page(CASE WHEN strategy = 'keyset' THEN 'offset' ELSE strategy END, done, size, tbl);
    END IF;
    t0 := clock_timestamp();
    EXECUTE format('SELECT count(*), sum(length(p::text)) FROM (%s) p', q) INTO n;
    e := e + extract(epoch FROM clock_timestamp() - t0);
    EXECUTE 'EXPLAIN (ANALYZE, BUFFERS, TIMING OFF, FORMAT JSON) ' || q INTO plan;
    b := (plan -> 0 -> 'Plan' ->> 'Shared Hit Blocks')::bigint + (plan -> 0 -> 'Plan' ->> 'Shared Read Blocks')::bigint;
    buffers := buffers + b;
    rows_read := rows_read + (SELECT sum((x ->> 'Actual Rows')::bigint * (x ->> 'Actual Loops')::bigint)
                                FROM jsonb_path_query(plan, 'strict $.** ? (@."Node Type" like_regex "Scan" && @."Node Type" != "Bitmap Index Scan")') x);
    IF pages = 0 THEN first_page_buffers := b; END IF;
    IF n > 0 THEN pages := pages + 1; last_page_buffers := b; END IF;
    EXIT WHEN n < size;
    done := done + n;
    EXECUTE format('SELECT created_at, id FROM (%s) p ORDER BY created_at, id LIMIT 1', q) INTO c, i;
  END LOOP;
  seconds := round(e, 2);
END $$;

SELECT t AS "table", s AS strategy, w.pages, w.seconds, w.rows_read, w.buffers,
       w.first_page_buffers AS "page 1", w.last_page_buffers AS "last page"
  FROM unnest(ARRAY['events_100k', 'events_300k', 'events']) WITH ORDINALITY u(t, tn),
       unnest(ARRAY['offset', 'keyset', 'deferred']) WITH ORDINALITY v(s, sn),
       pg_temp.walk(s, t, 1000) w
 ORDER BY tn, sn;

\echo
\echo 'Done. Other requests beside a walker, and a walk while rows change, need two sessions at once:'
\echo 'see offset-vs-keyset-concurrent.sh next to this file.'
DROP TABLE events_100k, events_300k;
