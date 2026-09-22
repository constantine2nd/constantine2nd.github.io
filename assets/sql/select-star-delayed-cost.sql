-- SELECT *: the slowdown that ships without a deploy
-- https://constantine2nd.github.io/select-star-the-slowdown-that-ships-without-a-deploy/
--
-- The same query, run before and after a later migration adds one JSON column.
-- Needs PostgreSQL 13+ (gen_random_uuid). Uses its own table, about 1 GB at the end.
--
--   curl -O https://constantine2nd.github.io/assets/sql/select-star-delayed-cost.sql
--   createdb select_star_demo
--   psql -X -d select_star_demo -f select-star-delayed-cost.sql
--   dropdb select_star_demo
--
-- Each query runs 5 times with its rows discarded (\o /dev/null) but still sent to psql,
-- so "Time:" is what a client waits for. Read the lower, steadier values.

\set ON_ERROR_STOP on
\set QUIET on
\pset pager off
SET client_min_messages = warning;

\echo '== 1. A table of API calls: 30 days, one row every 6 seconds (432,000 rows)'
DROP TABLE IF EXISTS api_log;
CREATE TABLE api_log (
  id             bigserial PRIMARY KEY,
  created_at     timestamptz NOT NULL,
  consumer_id    text        NOT NULL,
  verb           text        NOT NULL,
  url            text        NOT NULL,
  http_code      int         NOT NULL,
  duration_ms    int         NOT NULL,
  correlation_id uuid        NOT NULL
);
INSERT INTO api_log (created_at, consumer_id, verb, url, http_code, duration_ms, correlation_id)
SELECT now() - g * interval '6 seconds',
       'consumer-' || (g % 40),
       (ARRAY['GET', 'GET', 'GET', 'POST', 'PUT'])[1 + g % 5],
       '/api/v1/accounts/' || (g % 5000) || '/transactions',
       (ARRAY[200, 200, 200, 200, 201, 400, 404, 500])[1 + g % 8],
       5 + (g::bigint * 7919) % 300,
       gen_random_uuid()
  FROM generate_series(1, 432000) g;
CREATE INDEX api_log_consumer_created ON api_log (consumer_id, created_at);
VACUUM ANALYZE api_log;
SELECT pg_size_pretty(pg_table_size('api_log')) AS table_size, count(*) AS rows FROM api_log;

\echo '== 2. Before: one consumer, last 30 days (about 10,800 rows)'
\timing on
\echo '-- SELECT *'
\o /dev/null
SELECT * FROM api_log WHERE consumer_id = 'consumer-3' AND created_at >= now() - interval '30 days' ORDER BY created_at DESC;
SELECT * FROM api_log WHERE consumer_id = 'consumer-3' AND created_at >= now() - interval '30 days' ORDER BY created_at DESC;
SELECT * FROM api_log WHERE consumer_id = 'consumer-3' AND created_at >= now() - interval '30 days' ORDER BY created_at DESC;
SELECT * FROM api_log WHERE consumer_id = 'consumer-3' AND created_at >= now() - interval '30 days' ORDER BY created_at DESC;
SELECT * FROM api_log WHERE consumer_id = 'consumer-3' AND created_at >= now() - interval '30 days' ORDER BY created_at DESC;
\o
\echo '-- the columns the screen needs'
\o /dev/null
SELECT id, created_at, verb, url, http_code, duration_ms FROM api_log WHERE consumer_id = 'consumer-3' AND created_at >= now() - interval '30 days' ORDER BY created_at DESC;
SELECT id, created_at, verb, url, http_code, duration_ms FROM api_log WHERE consumer_id = 'consumer-3' AND created_at >= now() - interval '30 days' ORDER BY created_at DESC;
SELECT id, created_at, verb, url, http_code, duration_ms FROM api_log WHERE consumer_id = 'consumer-3' AND created_at >= now() - interval '30 days' ORDER BY created_at DESC;
SELECT id, created_at, verb, url, http_code, duration_ms FROM api_log WHERE consumer_id = 'consumer-3' AND created_at >= now() - interval '30 days' ORDER BY created_at DESC;
SELECT id, created_at, verb, url, http_code, duration_ms FROM api_log WHERE consumer_id = 'consumer-3' AND created_at >= now() - interval '30 days' ORDER BY created_at DESC;
\o
\timing off
\echo '-- EXPLAIN ANALYZE of SELECT * (server side only)'
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, SUMMARY ON)
SELECT * FROM api_log WHERE consumer_id = 'consumer-3' AND created_at >= now() - interval '30 days' ORDER BY created_at DESC;

\echo '== 3. Months later a migration adds a JSON column (~2 kB per row). No query changes.'
ALTER TABLE api_log ADD COLUMN details jsonb;
UPDATE api_log SET details = jsonb_build_object(
  'request',  jsonb_build_object('headers', jsonb_build_object('accept', 'application/json'),
                                 'body', (SELECT string_agg(md5(api_log.id::text || g), '') FROM generate_series(1, 60) g)),
  'response', jsonb_build_object('status', http_code));
VACUUM FULL api_log;   -- a clean table, as if the rows had been written with the column
ANALYZE api_log;
SELECT pg_size_pretty(pg_table_size('api_log')) AS table_size,
       pg_size_pretty(pg_relation_size((SELECT reltoastrelid FROM pg_class WHERE relname = 'api_log'))) AS stored_out_of_line
  FROM api_log LIMIT 1;

\echo '== 4. After: exactly the same two queries'
\timing on
\echo '-- SELECT *'
\o /dev/null
SELECT * FROM api_log WHERE consumer_id = 'consumer-3' AND created_at >= now() - interval '30 days' ORDER BY created_at DESC;
SELECT * FROM api_log WHERE consumer_id = 'consumer-3' AND created_at >= now() - interval '30 days' ORDER BY created_at DESC;
SELECT * FROM api_log WHERE consumer_id = 'consumer-3' AND created_at >= now() - interval '30 days' ORDER BY created_at DESC;
SELECT * FROM api_log WHERE consumer_id = 'consumer-3' AND created_at >= now() - interval '30 days' ORDER BY created_at DESC;
SELECT * FROM api_log WHERE consumer_id = 'consumer-3' AND created_at >= now() - interval '30 days' ORDER BY created_at DESC;
\o
\echo '-- the columns the screen needs'
\o /dev/null
SELECT id, created_at, verb, url, http_code, duration_ms FROM api_log WHERE consumer_id = 'consumer-3' AND created_at >= now() - interval '30 days' ORDER BY created_at DESC;
SELECT id, created_at, verb, url, http_code, duration_ms FROM api_log WHERE consumer_id = 'consumer-3' AND created_at >= now() - interval '30 days' ORDER BY created_at DESC;
SELECT id, created_at, verb, url, http_code, duration_ms FROM api_log WHERE consumer_id = 'consumer-3' AND created_at >= now() - interval '30 days' ORDER BY created_at DESC;
SELECT id, created_at, verb, url, http_code, duration_ms FROM api_log WHERE consumer_id = 'consumer-3' AND created_at >= now() - interval '30 days' ORDER BY created_at DESC;
SELECT id, created_at, verb, url, http_code, duration_ms FROM api_log WHERE consumer_id = 'consumer-3' AND created_at >= now() - interval '30 days' ORDER BY created_at DESC;
\o
\timing off
\echo '-- EXPLAIN ANALYZE of the same SELECT *: barely changed, it never fetches the out-of-line JSON'
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, SUMMARY ON)
SELECT * FROM api_log WHERE consumer_id = 'consumer-3' AND created_at >= now() - interval '30 days' ORDER BY created_at DESC;

SELECT current_setting('server_version_num')::int >= 170000 AS pg17 \gset
\if :pg17
\echo '-- PostgreSQL 17+: SERIALIZE makes EXPLAIN fetch and encode the values, and the cost appears'
EXPLAIN (ANALYZE, BUFFERS, SERIALIZE, COSTS OFF, SUMMARY ON)
SELECT * FROM api_log WHERE consumer_id = 'consumer-3' AND created_at >= now() - interval '30 days' ORDER BY created_at DESC;
\endif

\echo '== Done. Clean up with: DROP TABLE api_log;  (or dropdb select_star_demo)'
