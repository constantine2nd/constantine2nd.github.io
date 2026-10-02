---
layout: post
title: "OFFSET or keyset? It depends who is reading"
date: 2026-09-30 10:00:00 +0200
description: Every pagination debate ends with "use keyset". Measured on PostgreSQL, the answer depends on who reads the pages. For a person clicking through the first ten, OFFSET costs the same and keyset's extra work never pays off. For a machine reading every page, OFFSET grows with the square of the table, evicts other requests' data and repeats rows.
img: offset-or-keyset.webp
tags: [PostgreSQL, SQL, Performance, Explainer]
---

Every discussion of pagination seems to end the same way: `LIMIT ... OFFSET` is slow, use keyset pagination. Measured, the honest answer is less tidy. **It depends on who is reading the pages.** A person paging through a screen and a machine reading all of them are asking two different questions, and the two strategies answer them very differently.

<div class="post-verdict">
<p class="post-verdict-label">In short</p>
<p><strong>For a person clicking through the first pages of a screen, OFFSET and keyset cost the same, and keyset's extra design work does not pay for itself. For a machine reading every page, an export, a sync or another service, OFFSET's cost grows with the square of the table, it pushes other requests' data out of the cache, and it repeats rows when the data changes underneath it.</strong></p>
<ul class="post-facts">
<li>pages 1 to 11: <b>4-10 vs 4-5</b> buffers</li>
<li>every page of 1M rows: <b>56 s vs 2.5 s</b></li>
<li>other requests' data kept in cache: <b>85% vs 100%</b></li>
<li>rows an export repeated: <b>6,609 vs 0</b></li>
</ul>
</div>

## Two ways to ask for the same page

A table of events, newest first, twenty to a page. Here is page 51, asked both ways:

<div class="compare">
<div class="compare-card bad">
<h3>LIMIT / OFFSET</h3>
<pre><code>SELECT * FROM events
ORDER BY created_at DESC,
         id DESC
LIMIT 20 OFFSET 1000;</code></pre>
<p class="compare-note">Counts past the first 1,000 rows, then returns the next 20. Needs nothing but the page number.</p>
</div>
<div class="compare-card good">
<h3>Keyset</h3>
<pre><code>SELECT * FROM events
WHERE (created_at, id) &lt;
      ('2026-09-03 21:22:30+02',
       999001)
ORDER BY created_at DESC,
         id DESC
LIMIT 20;</code></pre>
<p class="compare-note">Starts right after the last row the client showed, which it has to remember: here row 1,000.</p>
</div>
</div>

Both return the same twenty rows, and both use the same index on `(created_at DESC, id DESC)`. The difference is how they find where the page starts. OFFSET walks the index from the top and throws away every row it counts past. Keyset asks the index to start at the remembered row.

The test table has 1,000,000 events, four to a second, so `created_at` alone has ties and `id` is there to break them. Details are at the end.

## A person, page by page

Most people who open a list look at the first page, some at the second, few past the tenth. Here is what pages 1 to 11 cost:

{% include offset-keyset/person-charts.html %}

On the first eleven pages OFFSET touched 4 to 10 buffers (8 kB pages of table or index) and took 0.03 to 0.06 ms. Keyset touched 4 or 5 and took 0.03 ms. The gap is a few hundredths of a millisecond per page, far below anything a person, or the network between them and the database, would notice.

They part further in. OFFSET reads every row it skips, so its cost grows with the page number: 0.15 ms on page 51, 1.2 ms on page 501, 12.8 ms and 3,512 buffers on page 5,001. The very last page, 999,980 rows in, took 187 ms and touched 35,084 buffers, more than twice the whole of `shared_buffers`, to return 20 rows. Keyset stayed at 4 or 5 buffers and a few hundredths of a millisecond at every depth. But nobody clicks "next" five thousand times.

{% include offset-keyset/person-table.html %}

### What keyset asks for in return

The speed is only one side. Keyset pagination costs design work that OFFSET does not:

- **A unique tiebreaker.** `created_at` alone has four rows a second here. Page on it alone and a page boundary that falls inside a second repeats or loses rows. The cursor has to include something unique, here `id`.
- **An index per sort order.** A screen that sorts by date, by amount and by customer needs three indexes, each ending in the tiebreaker, and three kinds of cursor.
- **No jumping.** "Go to page 37" has no keyset equivalent. There is next and previous, from where you are.
- **State in the client.** The cursor travels with every request and has to be kept, encoded and validated.
- **Sharp edges.** A nullable sort column silently drops the rows where it is NULL, and mixing ascending and descending columns rules out the simple row comparison.

OFFSET has none of these: any sort the user picks, any page number, no state. For a person who stays in the first pages, keyset buys almost nothing and costs all of the above.

### When the data moves

One more difference shows up even at page 2. Load page 1, then let a new event arrive, or let one the reader already saw be deleted, and load page 2:

{% include offset-keyset/moved-small.html %}

OFFSET counts rows. One more row in front of the window pushes everything down by one, one fewer pulls it up by one. For a person that is an annoyance: a card shown twice in a feed, or one they never see. It rarely gets reported.

## A machine, every page

Now the other reader. An export, a nightly sync, another service copying the data, a batch job: they read every page, in order, usually in bigger pages, here 1,000 rows. The question stops being "what does page 51 cost" and becomes "what does the whole walk cost".

{% include offset-keyset/machine-sizes.html %}

On 100,000 rows the difference is still small: OFFSET reads every page in 0.6 s, keyset in 0.2 s. On a million rows OFFSET takes 56 s and reads 501 million rows to deliver 1 million; keyset takes 2.5 s and reads each row once. OFFSET's last page alone touched 35,084 buffers. Keyset's last page touched 39, the same as its first:

{% include offset-keyset/machine-pages.html %}

Page *k* with OFFSET reads the *k - 1* pages before it again. Over the whole walk that adds up to about half the table times the number of pages, so ten times the rows means about a hundred times the work. Keyset reads each row once.

The usual advice for making OFFSET cheaper is the *deferred join*: skip over the index alone, then fetch only the page's rows by key. It helps, 25 s instead of 56 on the full table, with a third of the buffers. It does not change the shape: it still reads 502 million index entries, because skipping still means counting. It also depends on the plan. On 100,000 rows the planner joined back with a hash join over the whole table, and the walk took twice as long as plain OFFSET. On the first pages a person sees, it touches about twenty times the buffers plain OFFSET does.

{% include offset-keyset/machine-table.html %}

## Other requests notice

A walk like this does not run alone. While it reads, the same database answers ordinary requests, and they all share one cache, PostgreSQL's `shared_buffers`. To see whether they notice, a stream of primary-key lookups ran against a table of their own, loaded into the cache first and small enough to stay there: alone, beside a machine walking `events` with OFFSET, and beside one using keyset. Who held the cache was sampled once a second while each round ran.

{% include offset-keyset/neighbours.html %}

Beside the OFFSET walker, the lookups' table held 82 to 85% of its pages while both ran, and at the worst second 75%. Beside the keyset walker it held all of them. Second by second, it looks like a tug of war: the walker pushes their pages out, the lookups pull them back, and it settles at the share the walker leaves them:

{% include offset-keyset/neighbours-seconds.html %}

Both walkers read the whole table, so why only OFFSET? Not because its pages get hotter: under either walker alone, the walked table's pages sat at an average usage count of about 0.5 to 0.7. It is the misses. OFFSET re-reads the table from the top for every page, and the table is twice the size of the cache, so almost every read needs a new buffer: PostgreSQL allocated 115,887 buffers a second for the OFFSET walker, against 13,579 for keyset. Each allocation moves the cache's clock sweep, and the sweep lowers the usage count of every buffer it passes, the lookups' included. Eight and a half times the sweep is eight and a half times the pressure on everyone else's pages. PostgreSQL protects its cache from large sequential scans by giving them a small ring of 256 kB to cycle through ([buffer manager README](https://github.com/postgres/postgres/blob/REL_14_STABLE/src/backend/storage/buffer/README)); a walk through an index gets no such protection.

What the lookups *felt* was smaller, and it would be wrong to overstate it. Their p95 latency went from 0.043 ms alone to 0.061 ms beside the OFFSET walker and 0.052 ms beside the keyset walker, and their throughput dropped by 23% and 15%. Part of that is the walker competing for CPU, which keyset pays too. The evicted pages came back from the operating system's own cache: this laptop has 15 GB of memory and the whole database fits in it. On a server whose data does not fit in memory, or whose storage is a network disk, those pages would come from storage instead. That case was not measured here.

## When the data moves during an export

The row repeated on page 2 is an annoyance for a person. For a machine it is a wrong result. The same walk ran again while rows kept arriving and leaving, 200 changes a second, and every row it received was counted against the rows that existed for the whole walk:

{% include offset-keyset/moved-walk.html %}

OFFSET repeated 6,609 rows (median of three walks) and missed 9 of the roughly 993,000 that were there throughout. The deferred join repeated 3,644 and missed 3. Keyset repeated none and missed none, in every walk.

Almost every row that arrived at the top during the walk became a duplicate further down, because it pushed every later page back by one. Deleting a row the walker had already passed pulls the window the other way and makes it skip one, so the two partly cancel: that is why misses are rare here and duplicates are not. The slow walk also makes it worse: OFFSET's walks took 70 to 87 seconds and saw about 7,000 new rows, keyset's took 13 seconds and saw about 1,000. An export that must contain every row exactly once cannot use OFFSET while the table is being written to.

## So which one?

Side by side, the case for each, whoever is reading:

{% include offset-keyset/pros-cons.html %}

Which of those lines matter depends on the reader:

<div class="post-table" tabindex="0" role="region" aria-label="Which pagination to pick, by who reads the pages">
<table>
<thead><tr><th class="wrap" scope="col">Who reads the pages</th><th class="wrap" scope="col">What matters</th><th class="wrap" scope="col">Pick</th></tr></thead>
<tbody>
<tr><th class="wrap" scope="row">A person, a screen with page numbers and a choice of sort</th><td class="wrap">Jumping to a page, any sort order, simple code</td><td class="wrap"><b>OFFSET</b>, with a cap on how deep it goes</td></tr>
<tr><th class="wrap" scope="row">A person, an endless feed or "load more"</th><td class="wrap">No repeats while new items arrive</td><td class="wrap"><b>Keyset</b>, it fits the interaction anyway</td></tr>
<tr><th class="wrap" scope="row">A machine: an export, a sync, an API other services walk</th><td class="wrap">Every row exactly once, cost that does not grow with depth, leaving the cache to others</td><td class="wrap"><b>Keyset</b></td></tr>
<tr><th class="wrap" scope="row">An admin grid over a small table</th><td class="wrap">Nothing, really</td><td class="wrap"><b>OFFSET</b></td></tr>
</tbody>
</table>
</div>

The two also combine well: page numbers for the first pages a person will actually visit, and a cap beyond them ("refine your search"), with keyset behind any endpoint a machine is going to walk.

## Your framework already chose

Most code does not write either query by hand. In Spring Data, a repository method that takes a `Pageable` and returns a `Page` generates OFFSET, plus a `count(*)` over the whole result for the page total. Returning a `Slice` drops the count, not the OFFSET. Keyset is there too, since Spring Data 3.1: `ScrollPosition.keyset()` and a `Window` result. Which one an endpoint uses is worth deciding on purpose, by asking who will call it.

No technology fixes bad design, it only mitigates it. Neither pagination is the good one. They answer different questions, and the design decision is knowing which question your reader is asking.

## Try it yourself

Two scripts reproduce every number above. The first needs only psql; it builds the table (about 300 MB), measures one page at every depth, shows the data moving under page 2, and walks every page three ways on 100,000, 300,000 and 1,000,000 rows. It takes about five minutes on this laptop, most of it OFFSET.

```bash
curl -O https://constantine2nd.github.io/assets/sql/offset-vs-keyset.sql
curl -O https://constantine2nd.github.io/assets/sql/offset-vs-keyset-concurrent.sh
createdb pagination_demo
psql -X -d pagination_demo -f offset-vs-keyset.sql
bash offset-vs-keyset-concurrent.sh pagination_demo
dropdb pagination_demo
```

The second needs `pgbench` and runs the two experiments that need two sessions at once: other requests beside a walker, and a walk while rows change. It creates the `pg_prewarm` and `pg_buffercache` extensions to load and count the cache. `psql -X` skips your personal `~/.psqlrc`; add `-h <host> -U <user>` if your PostgreSQL is not local.

{% include offset-keyset/details.html %}

<p class="post-correction"><b>Corrected on 2 October 2026.</b> The first version said the lookups' table kept 56% of its pages beside the OFFSET walker. That was counted just after the lookups stopped, with the walker still running, when nothing pulls their pages back and the walker clears them fast. Sampled once a second while both ran, the share is 82 to 85%. The direction and the conclusion are unchanged; the size was overstated. The section above is re-measured, with the cache sampled during every round, and now explains why it happens.</p>
