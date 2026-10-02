#!/usr/bin/env python3
"""The OFFSET vs keyset post's charts and cards, from the measurements - no number typed by hand.

    python3 _tools/offset_keyset_render.py

Reads _data/offset_keyset.json (written by pglab's measurement run) and writes the fragments the post
includes, into _includes/offset-keyset/. Run it again after new measurements; the post does not change.
Jekyll does not publish folders starting with an underscore, so this stays out of the site.
"""
import json
import math
import os
import statistics

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
DATA = json.load(open(os.path.join(ROOT, "_data", "offset_keyset.json")))
OUT = os.path.join(ROOT, "_includes", "offset-keyset")

NAVY, GREY, RED, INK2, RULE = "#263959", "#7d8aa0", "#c0461a", "#5a6776", "#e6e8eb"
GREEN = "#2e7d4f"
COLOR = {"offset": RED, "keyset": NAVY, "deferred": GREY, "alone": GREEN}
NAME = {"offset": "LIMIT / OFFSET", "keyset": "keyset", "deferred": "deferred join", "alone": "nothing else running"}
SHORT = {"offset": "OFFSET", "keyset": "keyset", "deferred": "deferred", "alone": "alone"}
# text in the series' colour must itself meet 4.5:1 on white: the grey line colour does not, so its label is darker
LABEL = {"offset": RED, "keyset": NAVY, "deferred": INK2, "alone": GREEN}


def num(v, digits=0):
    return f"{v:,.{digits}f}"


def ms(v):
    if v >= 1000:
        return f"{v / 1000:,.1f} s"
    if v >= 10:
        return f"{v:,.0f} ms"
    if v >= 1:
        return f"{v:,.1f} ms"
    return f"{v:,.2f} ms"


def esc(s):
    return str(s).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace('"', "&quot;")


def legend(keys):
    return ('<div class="post-chart-legend">' + "".join(
        f'<span><i style="background:{COLOR[k]}"></i>{NAME[k]}</span>' for k in keys) + "</div>")


def write(name, html):
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, name), "w") as f:
        f.write(html.strip() + "\n")


# ---------------------------------------------------------------- charts

def line_chart(series, title, sub, xlabels, aria, log_y=False, unit="", height=230, keys=None):
    """series: {strategy: [y per x]}. x is categorical, evenly spaced (depths are not evenly spread)."""
    W, H, L, R, T, B = 640, height, 64, 74, 12, 34
    ys = [v for vs in series.values() for v in vs if v is not None]
    if log_y:
        lo, hi = max(min(ys), 1e-3), max(ys)
        lo, hi = 10 ** math.floor(math.log10(lo)), 10 ** math.ceil(math.log10(hi))
    elif unit == "%":
        ticks_lin = [0, 25, 50, 75, 100]               # a share: the axis is the whole of it, no more
        lo, hi = 0, 100
    else:
        ticks_lin = nice_ticks(max(ys))
        lo, hi = 0, ticks_lin[-1]
    y = (lambda v: T + (H - T - B) * (1 - (math.log10(v) - math.log10(lo)) / (math.log10(hi) - math.log10(lo)))) \
        if log_y else (lambda v: T + (H - T - B) * (1 - (v - lo) / (hi - lo)))
    x = lambda i: L + i * (W - L - R) / max(1, len(xlabels) - 1)
    g = []
    ticks = [10 ** e for e in range(round(math.log10(lo)), round(math.log10(hi)) + 1)] if log_y else ticks_lin
    for t in ticks:
        g.append(f'<line x1="{L}" x2="{W - R}" y1="{y(t):.1f}" y2="{y(t):.1f}" stroke="{RULE}"/>'
                 f'<text x="{L - 8}" y="{y(t) + 4:.1f}" text-anchor="end" font-size="11" fill="{INK2}">'
                 f'{short(t)}{unit}</text>')
    for i, lab in enumerate(xlabels):
        if lab is not None:
            g.append(f'<text x="{x(i):.1f}" y="{H - 12}" text-anchor="middle" font-size="11" fill="{INK2}">{lab}</text>')
    ends = []
    for k, vs in series.items():
        pts = [(x(i), y(max(v, lo) if log_y else v)) for i, v in enumerate(vs) if v is not None]
        g.append(f'<polyline points="{" ".join(f"{a:.1f},{b:.1f}" for a, b in pts)}" fill="none" '
                 f'stroke="{COLOR[k]}" stroke-width="2.2"/>')
        if len(pts) <= 20:
            g += [f'<circle cx="{a:.1f}" cy="{b:.1f}" r="3.2" fill="{COLOR[k]}"/>' for a, b in pts]
        ends.append([pts[-1][1], k])
    # the series' names at the ends of their lines, nudged apart where they would overlap
    ends.sort()
    for i in range(1, len(ends)):
        ends[i][0] = max(ends[i][0], ends[i - 1][0] + 13)
    for yv, k in ends:
        g.append(f'<text x="{W - R + 6}" y="{yv + 4:.1f}" font-size="11" font-weight="700" fill="{LABEL[k]}">{SHORT[k]}</text>')
    return (f'<div class="post-chart">\n<p class="post-chart-title">{title}</p>\n'
            + (f'<p class="post-chart-sub">{sub}</p>\n' if sub else "")
            + legend(keys or list(series)) + "\n"
            + f'<svg viewBox="0 0 {W} {H}" role="img" aria-label="{esc(aria)}">{"".join(g)}</svg>\n</div>')


def nice_ticks(top, n=4):
    """Round steps (1, 2, 2.5 or 5 times a power of ten) up to at least `top`."""
    raw = top / n
    mag = 10 ** math.floor(math.log10(raw))
    # no 2.5 when it would make fractions of a count
    step = next(m * mag for m in (1, 2, 2.5, 5, 10) if m * mag >= raw and (top < 1 or m * mag == int(m * mag)))
    return [step * i for i in range(math.ceil(top / step) + 1)]


def short(v):
    if v >= 1e6:
        return f"{v / 1e6:g}M"
    if v >= 1e3:
        return f"{v / 1e3:g}k"
    if v >= 1:
        return f"{v:g}"
    return f"{v:g}"


def bar_chart(groups, title, sub, aria, fmt, keys):
    """groups: [(label, sublabel, {strategy: value})]. Horizontal bars, the SELECT * post's shape."""
    W, L, R, BH, GAP = 640, 150, 130, 16, 4
    top = max(v for _, _, vals in groups for v in vals.values())
    scale = (W - L - R) / top
    g, yy = [], 8
    for label, sublabel, vals in groups:
        g.append(f'<text x="0" y="{yy + 16}" font-size="13" font-weight="700" fill="{NAVY}">{esc(label)}</text>'
                 f'<text x="0" y="{yy + 31}" font-size="11.5" fill="{INK2}">{esc(sublabel)}</text>')
        for k in keys:
            v = vals[k]
            w = max(1.5, v * scale)
            g.append(f'<rect x="{L}" y="{yy}" width="{w:.1f}" height="{BH}" rx="2" fill="{COLOR[k]}">'
                     f'<title>{NAME[k]}: {fmt(v)}</title></rect>'
                     f'<text x="{L + w + 6:.1f}" y="{yy + 12}" font-size="12" fill="{NAVY}">{fmt(v)} '
                     f'<tspan fill="{LABEL[k]}" font-weight="700">{SHORT[k]}</tspan></text>')
            yy += BH + GAP
        yy += 14
    return (f'<div class="post-chart">\n<p class="post-chart-title">{title}</p>\n'
            + (f'<p class="post-chart-sub">{sub}</p>\n' if sub else "") + legend(keys) + "\n"
            + f'<svg viewBox="0 0 {W} {yy}" role="img" aria-label="{esc(aria)}">{"".join(g)}</svg>\n</div>')


# ---------------------------------------------------------------- the fragments

def person():
    s = DATA["sweep"]
    ds = s["depths"]
    near = [d for d in ds if d["depth"] <= 200]
    deep = [d for d in ds if d["depth"] == 0 or d["depth"] >= 1000]
    out = [line_chart(
        {k: [d[k]["buffers"] for d in near] for k in ("offset", "keyset")},
        "Pages 1 to 11: buffers each page touched",
        f"One page of {s['page_size']}, the way a person clicks through a screen. A buffer is one 8 kB page, here "
        f"already in memory: ten of them take a few hundredths of a millisecond.",
        [str(d["depth"] // s["page_size"] + 1) for d in near],
        "Buffers per page for pages 1 to 11. OFFSET: " + ", ".join(str(d["offset"]["buffers"]) for d in near)
        + ". Keyset: " + ", ".join(str(d["keyset"]["buffers"]) for d in near) + ".",
        keys=["offset", "keyset"])]
    out.append(line_chart(
        {k: [d[k]["ms"] for d in deep] for k in ("offset", "deferred", "keyset")},
        "Deeper in: time to fetch one page",
        "Median of 3 runs of 5. Logarithmic scale: each line up is ten times slower.",
        ["page 1"] + [f"{short(d['depth'])} in" for d in deep[1:-1]] + ["last page"],
        "Time for one page at increasing depth. " + "; ".join(
            f"{NAME[k]}: " + ", ".join(ms(d[k]["ms"]) for d in deep) for k in ("offset", "deferred", "keyset")),
        log_y=True, unit=" ms", keys=["offset", "deferred", "keyset"]))
    write("person-charts.html", "\n".join(out))

    cells = lambda d, k: (f'<td class="num first">{ms(d[k]["ms"])}</td><td class="num">{num(d[k]["scanned"])}</td>'
                          f'<td class="num">{num(d[k]["buffers"])}</td>')
    rows = "".join(
        f'<tr><th class="num" scope="row">{num(d["depth"] // s["page_size"] + 1)}</th><td class="num">{num(d["depth"])}</td>'
        + cells(d, "offset") + cells(d, "keyset") + "</tr>"
        for d in ds if d["depth"] in (0, 200, 1000, 10000, 100000, 500000, 999980))
    sub = '<th class="num first" scope="col">time</th><th class="num" scope="col">rows read</th><th class="num" scope="col">buffers</th>'
    write("person-table.html", f"""<div class="post-table" tabindex="0" role="region" aria-label="One page of 20 at increasing depth: time, rows read and buffers for OFFSET and keyset">
<table>
<thead>
<tr><th class="num" rowspan="2" scope="col">Page</th><th class="num" rowspan="2" scope="col">Rows skipped</th><th class="group bad" colspan="3" scope="colgroup">LIMIT / OFFSET</th><th class="group good" colspan="3" scope="colgroup">Keyset</th></tr>
<tr>{sub}{sub}</tr>
</thead>
<tbody>{rows}</tbody>
</table>
</div>""")


def moved_small():
    s = DATA["shift"]
    ins, dele = s["insert"], s["delete"]
    write("moved-small.html", f"""<div class="compare">
<div class="compare-card bad">
<h3>LIMIT / OFFSET</h3>
<p class="compare-note">A row arrives: page 2 opens with <b>{len(ins['offset_repeated'])} row the reader already saw</b>.<br>
A row they saw is deleted: <b>{len(dele['offset_skipped'])} row is never shown</b>.</p>
</div>
<div class="compare-card good">
<h3>Keyset</h3>
<p class="compare-note">Repeated <b>{len(ins['keyset_repeated'])}</b>, skipped <b>{len(dele['keyset_skipped'])}</b>. Page 2 is
"after the last row you saw", and that row has not moved.</p>
</div>
</div>""")


def walks():
    ws = DATA["walks"]
    by = {(w["table"], w["strategy"]): w for w in ws}
    sizes = [("events_100k", "100,000 rows"), ("events_300k", "300,000 rows"), ("events", "1,000,000 rows")]
    groups = [(lab, f"{by[(t, 'offset')]['pages']:,} pages of 1,000",
               {k: by[(t, k)]["ms"] / 1000 for k in ("offset", "deferred", "keyset")}) for t, lab in sizes]
    write("machine-sizes.html", bar_chart(
        groups, "Reading every page: time against the size of the table",
        "Pages of 1,000, in order, server-side. Median of 3 walks.",
        "Time to read every page. " + "; ".join(
            f"{lab}: " + ", ".join(f"{NAME[k]} {v:,.1f} s" for k, v in vals.items()) for lab, _, vals in groups),
        lambda v: f"{v:,.1f} s", ["offset", "deferred", "keyset"]))

    big = {k: by[("events", k)] for k in ("offset", "deferred", "keyset")}
    pages = big["keyset"]["pages"]                       # the requests after it came back empty
    n = pages + 1
    step = max(1, pages // 100)
    idx = sorted(set(range(0, pages, step)) | {pages - 1})
    write("machine-pages.html", line_chart(
        {k: [big[k]["per_page"][i]["buffers"] if i < len(big[k]["per_page"]) else None for i in idx]
         for k in ("offset", "deferred", "keyset")},
        "Every page of 1,000,000 rows: buffers each page touched, in order",
        "Page 1 on the left, page 1,000 on the right.",
        [f"{i + 1:,}" if (j % 25 == 0 and i + 1 < pages - step) else None for j, i in enumerate(idx)][:-1]
        + [f"{pages:,}"],
        f"Buffers per page across a walk of 1,000,000 rows. OFFSET grows from "
        f"{big['offset']['per_page'][0]['buffers']} to {big['offset']['per_page'][n - 2]['buffers']:,}; keyset stays at "
        f"{big['keyset']['per_page'][0]['buffers']} to {big['keyset']['per_page'][n - 2]['buffers']}.",
        keys=["offset", "deferred", "keyset"]))

    # the deferred join reads as many rows as OFFSET (the text says so): its column would repeat OFFSET's
    cells = lambda t, k: (f'<td class="num first">{by[(t, k)]["ms"] / 1000:,.1f} s</td>'
                          + ("" if k == "deferred" else f'<td class="num">{num(by[(t, k)]["rows_read"])}</td>')
                          + f'<td class="num">{num(by[(t, k)]["buffers"])}</td>')
    brief = {"events_100k": "100k rows", "events_300k": "300k rows", "events": "1M rows"}
    rows = "".join(f'<tr><th scope="row">{brief[t]}</th>' + "".join(cells(t, k) for k in ("offset", "deferred", "keyset")) + "</tr>"
                   for t, lab in sizes)
    sub = '<th class="num first" scope="col">time</th><th class="num" scope="col">rows read</th><th class="num" scope="col">buffers</th>'
    write("machine-table.html", f"""<div class="post-table" tabindex="0" role="region" aria-label="Reading every page: time, rows read and buffers by table size and strategy">
<table>
<thead>
<tr><th rowspan="2" scope="col">Every page of</th><th class="group bad" colspan="3" scope="colgroup">LIMIT / OFFSET</th><th class="group" colspan="2" scope="colgroup">Deferred join</th><th class="group good" colspan="3" scope="colgroup">Keyset</th></tr>
<tr>{sub}<th class="num first" scope="col">time</th><th class="num" scope="col">buffers</th>{sub}</tr>
</thead>
<tbody>{rows}</tbody>
</table>
</div>""")


def neighbours():
    nb = DATA["neighbours"]
    P = nb["neighbour_pages"]
    of = lambda c: [x for x in nb["runs"] if x["condition"] == c]
    med = lambda c, k: statistics.median(x[k] for x in of(c) if x[k] is not None)
    # the buffer count includes the table's free-space and visibility maps, so it can edge past its page count
    share = lambda v: min(1.0, v / P)
    held = lambda c: [share(x["held"]["median"]) for x in of(c)]
    low = lambda c: share(min(x["held"]["min"] for x in of(c)))
    groups = [("alone", "nothing else running"), ("offset", "beside an OFFSET walker"), ("keyset", "beside a keyset walker")]
    cards = []
    for c, lab in groups:
        cls = "bad" if c == "offset" else "good" if c == "keyset" else ""
        hs = held(c)
        span = f"{min(hs):.0%}" if f"{min(hs):.0%}" == f"{max(hs):.0%}" else f"{min(hs):.0%}–{max(hs):.0%}"
        cards.append(f"""<div class="compare-card {cls}">
<h3>{esc(lab)}</h3>
<div class="compare-times"><span class="to">{statistics.median(hs):.0%}</span></div>
<p class="compare-note">of their table held in <code>shared_buffers</code> while it ran ({span} over {len(hs)} rounds,
the lowest second {low(c):.0%}). p95 {med(c, 'p95')} ms, {num(med(c, 'tps'))} lookups a second.</p>
</div>""")
    write("neighbours.html", '<div class="compare compare-3">' + "\n".join(cards) + "</div>")

    first = {c: next(x for x in of(c) if x["held_per_second"]) for c, _ in groups}
    n = min(len(first[c]["held_per_second"]) for c in first)
    write("neighbours-seconds.html", line_chart(
        {c: [share(v) * 100 for v in first[c]["held_per_second"][:n]] for c, _ in groups},
        "Their table's share of shared_buffers, once a second",
        "First round of each, 30 s. Beside keyset, the dip in the first two seconds is the walker's head start, "
        "before the lookups begin: nothing was using their pages yet, and they came straight back.",
        [f"{i} s" if i % 5 == 0 else None for i in range(n)],
        "Their table's share of shared_buffers over 30 seconds. Alone: 100% throughout. Beside an OFFSET walker: "
        f"falls from 100% to about {statistics.median(first['offset']['held_per_second'][10:]) / P:.0%} within ten "
        "seconds and stays there. Beside a keyset walker: a dip in the first two seconds, then 100% throughout.",
        unit="%", keys=["alone", "offset", "keyset"]))


def moved_walk():
    mv = DATA["moving"]
    med = lambda s, k: statistics.median(x[k] for x in mv if x["strategy"] == s)
    cards = []
    for s in ("offset", "deferred", "keyset"):
        cls = "good" if s == "keyset" else "bad"
        changes = med(s, "inserted") + med(s, "deleted")
        cards.append(f"""<div class="compare-card {cls}">
<h3>{NAME[s]}</h3>
<div class="compare-times"><span class="to">{num(med(s, 'duplicated'))}</span><span class="from">duplicated</span></div>
<div class="compare-times"><span class="to">{num(med(s, 'missed'))}</span><span class="from">missed</span></div>
<p class="compare-note">of {num(med(s, 'stable'))} rows that were there throughout, with {num(changes)} rows
inserted or deleted during the walk (medians of {sum(1 for x in mv if x['strategy'] == s)}).</p>
</div>""")
    write("moved-walk.html", '<div class="compare compare-3">' + "\n".join(cards) + "</div>")


def pros_cons():
    pc = DATA["pros_cons"]
    card = lambda k, title: (f'<div class="compare-card"><h3>{title}</h3>'
                             + '<p class="compare-note"><b>For</b></p><ul class="compare-list">'
                             + "".join(f"<li>{esc(x)}</li>" for x in pc[k]["for"])
                             + '</ul><p class="compare-note"><b>Against</b></p><ul class="compare-list">'
                             + "".join(f"<li>{esc(x)}</li>" for x in pc[k]["against"]) + "</ul></div>")
    write("pros-cons.html", '<div class="compare">' + card("offset", "LIMIT / OFFSET") + card("keyset", "Keyset") + "</div>")


def details():
    m = DATA["machine"]
    s = DATA["sweep"]
    nb = DATA["neighbours"]
    write("details.html", f"""<details class="post-details">
<summary>Measurement details</summary>
<div markdown="1">

| | |
|---|---|
| Machine | Laptop, {esc(m['cpu'])} ({m['threads']} threads), {m['ram_gb']} GB RAM, NVMe SSD, Linux; CPU governor `{m['governor']}` |
| PostgreSQL | {esc(m['postgres'].split()[0])}, default settings (`shared_buffers` {m['shared_buffers']}), local Unix-socket connection |
| Table | 1,000,000 rows, {m['table_size']} plus {m['index_size']} of indexes; `created_at` has four rows a second, so ties are real |
| One page | Page of {s['page_size']}; `EXPLAIN (ANALYZE, BUFFERS)`, median of 5 runs after one not counted, three such runs; rows read is every row the plan's scans produced, skipped ones included |
| Every page | Pages of 1,000, in order, until one comes back short, in a PL/pgSQL loop (server-side: no network); time from running each page with every column turned into text, median of 3 walks; buffers and rows read from `EXPLAIN` of each page |
| Other requests | Primary-key lookups, 4 clients, {nb['seconds']} s, on a {num(nb['neighbour_pages'])}-page table loaded into `shared_buffers` first; `pg_buffercache` sampled once a second during each round; medians of {len(nb['runs']) // 3} rounds, interleaved; measured {nb['measured']} |
| Moving data | pgbench writer, 200 changes a second (half new rows at the top, half random deletes), 5 ms pause between pages |
| Measured | {DATA['started'][:10]}; the two scripts above reproduce every number |

</div>
</details>""")


def cover():
    """The cover, in the house style of the other posts: a psql window and a banner. Numbers from the data."""
    from PIL import Image, ImageDraw, ImageFont
    fonts = "/usr/share/fonts/truetype/noto/"
    reg = lambda n: ImageFont.truetype(fonts + "NotoSansMono-Regular.ttf", n)
    bold = lambda n: ImageFont.truetype(fonts + "NotoSansMono-Bold.ttf", n)
    by = {(w["table"], w["strategy"]): w for w in DATA["walks"]}
    page5 = next(d for d in DATA["sweep"]["depths"] if d["depth"] == 80)
    off, key = by[("events", "offset")]["ms"] / 1000, by[("events", "keyset")]["ms"] / 1000

    im = Image.new("RGB", (1920, 1080), "#1e1f24")
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((160, 100, 1760, 830), 28, fill="#262a35", outline="#353b4a", width=2)
    d.rounded_rectangle((160, 100, 1760, 180), 28, fill="#2d3240")
    d.rectangle((160, 150, 1760, 180), fill="#2d3240")
    for x, c in ((218, "#ff5f57"), (262, "#febc2e"), (306, "#28c840")):
        d.ellipse((x - 15, 126, x + 15, 156), fill=c)
    d.text((360, 118), "psql  -  events", font=bold(42), fill="#d6dae3")

    BLUE, WHITE, GREY, GREEN, RED = "#7aa2f7", "#e6e8ee", "#6b7384", "#6fd17a", "#f07860"
    def line(x, y, parts, size=44):
        for text, color in parts:
            d.text((x, y), text, font=reg(size), fill=color)
            x += d.textlength(text, font=reg(size))
    line(230, 222, [("-- a person, page 5", GREY)])
    line(230, 282, [("OFFSET  ", BLUE), (f"{page5['offset']['ms']:.2f} ms   ", GREEN),
                    ("keyset  ", BLUE), (f"{page5['keyset']['ms']:.2f} ms", GREEN)])
    line(230, 342, [("-- the same, near enough", GREY)])
    d.rectangle((162, 420, 1758, 510), fill="#3a2f1f")
    line(230, 440, [("-- a machine, every page of 1,000,000 rows", "#e5c07b")])
    line(230, 552, [("OFFSET  ", BLUE), (f"{off:.0f} s", RED)])
    line(230, 622, [("keyset  ", BLUE), (f"{key:.1f} s", GREEN)])
    line(230, 712, [(f"-- {off / key:.0f}x, and other requests lose their cache", GREY)])

    d.rounded_rectangle((260, 890, 1660, 1000), 22, fill="#3d1f1f", outline="#8a3a3a", width=2)
    msg = "OFFSET or keyset  -  depends who reads"
    w = d.textlength(msg, font=bold(56))
    d.text(((1920 - w) / 2, 908), msg, font=bold(56), fill="#fbd5cc")
    im.save(os.path.join(ROOT, "assets", "img", "offset-or-keyset.webp"), quality=90)
    im.save(os.path.join(ROOT, "_tools", "offset-or-keyset-linkedin.png"))


if __name__ == "__main__":
    person()
    moved_small()
    walks()
    neighbours()
    moved_walk()
    pros_cons()
    details()
    cover()
    print("wrote", ", ".join(sorted(os.listdir(OUT))))
