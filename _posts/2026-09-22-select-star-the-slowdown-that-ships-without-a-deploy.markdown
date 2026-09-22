---
layout: post
title: "SELECT *: the slowdown that ships without a deploy"
date: 2026-09-22 10:00:00 +0200
description: The same query went from 10 ms to 123 ms and nobody deployed anything. SELECT * depends on columns that do not exist yet, so no test can catch it when the code is written. A reproducible PostgreSQL experiment.
img: select-star-slowdown-without-deploy.webp
tags: [PostgreSQL, SQL, Performance, Explainer]
---

A query took 10 milliseconds. Months later the same query takes 123. Nobody changed it, nobody deployed the service that runs it, and every test still passes.

<div class="post-verdict">
<p class="post-verdict-label">In short</p>
<p><strong>The cost of <code>SELECT *</code> depends on columns that do not exist yet, so no test, review or benchmark can catch it when the code is written.</strong> A later migration that adds one wide column makes every <code>SELECT *</code> on that table slower, without any change to the query.</p>
<ul class="post-facts">
<li><b>12&times;</b> slower, same query</li>
<li><b>0</b> lines of query code changed</li>
<li><code>EXPLAIN</code>: <b>no visible change</b></li>
</ul>
</div>

## What SELECT * actually promises

`SELECT *` does not mean "the columns I need". It means "every column this table has **at the moment the query runs**", including the ones nobody has added yet.

That is the whole problem in one sentence. On the day it ships, `SELECT *` and a list of the needed columns can cost exactly the same. The difference arrives later, with someone else's migration.

## The experiment

A table of API calls: 30 days, one row every 6 seconds, 432,000 rows, eight narrow columns. A screen shows one consumer's calls for the last 30 days, about 10,800 rows:

```sql
SELECT * FROM api_log
 WHERE consumer_id = 'consumer-3' AND created_at >= now() - interval '30 days'
 ORDER BY created_at DESC;
```

Months later, a new feature needs the request and response of every call, and a migration adds them:

```sql
ALTER TABLE api_log ADD COLUMN details jsonb;   -- about 2 kB per row
```

The query above is not touched. Then the same two queries run again, the `SELECT *` and one listing the six columns the screen shows, with every row sent to the client:

<div class="compare">
<div class="compare-card bad">
<h4>SELECT *</h4>
<div class="compare-times"><span class="from">10.5 ms</span><span class="arrow">&rarr;</span><span class="to">123 ms</span></div>
<p class="compare-note">About <b>12&times; slower</b>. It now reads, decodes and sends 10,800 JSON documents the screen never shows.</p>
</div>
<div class="compare-card good">
<h4>The 6 needed columns</h4>
<div class="compare-times"><span class="from">11.7 ms</span><span class="arrow">&rarr;</span><span class="to">12.9 ms</span></div>
<p class="compare-note"><b>Unchanged.</b> It does not notice the new column at all.</p>
</div>
</div>

<div class="post-chart">
<p class="post-chart-title">Median time, before and after the migration</p>
<div class="post-chart-legend"><span><i style="background:#a9b3c1"></i>before</span><span><i style="background:#263959"></i>after</span></div>
<svg viewBox="0 0 640 214" role="img" aria-label="Median time before and after the migration, in milliseconds"><line x1="190.0" x2="190.0" y1="6" y2="198" stroke="#e6e8eb" stroke-width="1"/><text x="190.0" y="211" text-anchor="middle" font-size="11" fill="#6c7a89">0 ms</text><line x1="263.1" x2="263.1" y1="6" y2="198" stroke="#e6e8eb" stroke-width="1"/><text x="263.1" y="211" text-anchor="middle" font-size="11" fill="#6c7a89">25 ms</text><line x1="336.2" x2="336.2" y1="6" y2="198" stroke="#e6e8eb" stroke-width="1"/><text x="336.2" y="211" text-anchor="middle" font-size="11" fill="#6c7a89">50 ms</text><line x1="409.2" x2="409.2" y1="6" y2="198" stroke="#e6e8eb" stroke-width="1"/><text x="409.2" y="211" text-anchor="middle" font-size="11" fill="#6c7a89">75 ms</text><line x1="482.3" x2="482.3" y1="6" y2="198" stroke="#e6e8eb" stroke-width="1"/><text x="482.3" y="211" text-anchor="middle" font-size="11" fill="#6c7a89">100 ms</text><line x1="555.4" x2="555.4" y1="6" y2="198" stroke="#e6e8eb" stroke-width="1"/><text x="555.4" y="211" text-anchor="middle" font-size="11" fill="#6c7a89">125 ms</text><text x="0" y="28.0" font-size="13" font-weight="700" fill="#263959">SELECT &#42;</text><text x="0" y="43.0" font-size="11.5" fill="#6c7a89">sent to the client</text><rect x="190" y="10" width="30.7" height="18" rx="2" fill="#a9b3c1"><title>SELECT * before: 10.5 ms</title></rect><text x="226.7" y="23" font-size="12" fill="#263959">10.5 ms</text><rect x="190" y="32" width="359.5" height="18" rx="2" fill="#263959"><title>SELECT * after: 123.0 ms</title></rect><text x="555.5" y="45" font-size="12" font-weight="700" fill="#263959">123 ms</text><text x="0" y="90.0" font-size="13" font-weight="700" fill="#263959">the 6 needed columns</text><text x="0" y="105.0" font-size="11.5" fill="#6c7a89">sent to the client</text><rect x="190" y="72" width="34.2" height="18" rx="2" fill="#a9b3c1"><title>the 6 needed columns before: 11.7 ms</title></rect><text x="230.2" y="85" font-size="12" fill="#263959">11.7 ms</text><rect x="190" y="94" width="37.7" height="18" rx="2" fill="#263959"><title>the 6 needed columns after: 12.9 ms</title></rect><text x="233.7" y="107" font-size="12" font-weight="700" fill="#263959">12.9 ms</text><text x="0" y="152.0" font-size="13" font-weight="700" fill="#263959">EXPLAIN ANALYZE</text><text x="0" y="167.0" font-size="11.5" fill="#6c7a89">of the same SELECT &#42;</text><rect x="190" y="134" width="22.8" height="18" rx="2" fill="#a9b3c1"><title>EXPLAIN ANALYZE before: 7.8 ms</title></rect><text x="218.8" y="147" font-size="12" fill="#263959">7.8 ms</text><rect x="190" y="156" width="27.5" height="18" rx="2" fill="#263959"><title>EXPLAIN ANALYZE after: 9.4 ms</title></rect><text x="223.5" y="169" font-size="12" font-weight="700" fill="#263959">9.4 ms</text></svg>
</div>

Before the migration the two queries cost the same, so nothing warned anyone. The table meanwhile grew from 52 MB to 1.2 GB. Over a real network, sending 21 MB instead of 1 MB per request widens the gap further.

## Why EXPLAIN ANALYZE did not see it

Anyone investigating a slow query reaches for `EXPLAIN ANALYZE`. Here it reported 7-10 ms before the migration and 8-10 ms after. **The slowdown was invisible to it.** Same plan, a few more pages, a couple of milliseconds (one run of each):

<div class="compare">
<div class="compare-card">
<h4>Before the migration</h4>
<pre><code>Sort
  -> Bitmap Heap Scan on api_log
       -> Bitmap Index Scan on
          api_log_consumer_created
Buffers: shared hit=6699
Execution Time: 7.8 ms</code></pre>
</div>
<div class="compare-card">
<h4>After the migration</h4>
<pre><code>Sort
  -> Bitmap Heap Scan on api_log
       -> Bitmap Index Scan on
          api_log_consumer_created
Buffers: shared hit=7504
Execution Time: 10.2 ms</code></pre>
</div>
</div>

PostgreSQL stores large values like these 2 kB documents outside the row, in a separate TOAST table: here 1.1 GB of the 1.2 GB. The row itself only holds a pointer. `EXPLAIN ANALYZE` runs the query but throws the rows away without sending them, so it never follows those pointers. The expensive part only happens when rows are actually delivered.

PostgreSQL 17 added `EXPLAIN (ANALYZE, SERIALIZE)` to close exactly this gap: it fetches and encodes the values as if sending them. On older versions, trust the timings seen by clients, or `pg_stat_statements`, whose execution time includes sending the rows. For the query above it recorded 111 ms while `EXPLAIN ANALYZE` said 19 ms.

## You may not write SELECT *, your ORM might

Most code does not contain the literal `SELECT *`. The ORM writes the column list, from the entity mapping. That limits the damage, but not the pattern: when the new column is mapped into the entity for the new feature, every existing query that loads that entity starts carrying it too. A deploy happened, but of a different feature, and the slow query's code did not change.

## The second cost: no index-only scans

There is a quieter cost even before any migration. When every column the query needs is inside an index, PostgreSQL can answer from the index alone and never read the table (an Index Only Scan). `SELECT *` rules that out, because no index contains every column. For hot queries that is often the difference between a few pages and a few thousand.

## What to do

- **List the columns in hot paths.** `SELECT *` is fine for ad-hoc queries and tiny lookup tables, not for queries that run on every request.
- **Use projections in the ORM** for list screens and APIs: a DTO or record with the fields the screen shows, not the full entity.
- **Review migrations that add wide columns** by asking one question: who selects this table, and how?
- **Keep large payloads in their own table**, one-to-one with the main row, fetched only when someone asks for them.
- **Watch mean execution time over time** in `pg_stat_statements`, per query. A query that got slower without a deploy is exactly what it shows and `EXPLAIN` hides.

No technology fixes bad design, it only mitigates it. `SELECT *` is a small design decision whose cost arrives later, on someone else's schedule.

## Try it yourself

The whole experiment is one SQL file: [select-star-delayed-cost.sql](/assets/sql/select-star-delayed-cost.sql). It creates its own table (about 1 GB at the end) and prints the timings before and after the migration, plus both `EXPLAIN` outputs. On PostgreSQL 17 or later it also runs the `SERIALIZE` variant.

```bash
curl -O https://constantine2nd.github.io/assets/sql/select-star-delayed-cost.sql
createdb select_star_demo
psql -X -d select_star_demo -f select-star-delayed-cost.sql
dropdb select_star_demo
```

`createdb` makes a throwaway database, `psql -X` runs the script there without your personal `~/.psqlrc` settings, and `dropdb` removes everything again. Add `-h <host> -U <user>` to each command if your PostgreSQL is not local, for example in Docker.

<details class="post-details">
<summary>Measurement details</summary>
<div markdown="1">

| | |
|---|---|
| Machine | Laptop, Intel Core i7-11390H (4 cores / 8 threads), 16 GB RAM, NVMe SSD, Linux |
| PostgreSQL | 14, default settings (`shared_buffers` 128 MB), local Unix-socket connection |
| Timings | Medians of 15 runs (the script run 3 times, 5 runs per query), measured by psql `\timing`, rows sent to psql and discarded |
| Rows returned | 10,800 per query |
| Table size | 52 MB before, 1.2 GB after (1.1 GB of it stored out of line) |
| `EXPLAIN ANALYZE` | Execution time 7.1-10.2 ms before, 8.4-10.2 ms after (one run per script run) |
| `pg_stat_statements` | Separate run after the migration: 111 ms mean for the `SELECT *`, while `EXPLAIN ANALYZE` reported 19 ms |

</div>
</details>
