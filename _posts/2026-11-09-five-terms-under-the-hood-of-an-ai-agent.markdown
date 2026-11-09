---
layout: post
title: "Five terms under the hood of an AI agent"
date: 2026-11-09 10:00:00 +0100
description: AGENTS.md, agent skills, MCP, A2A and subagents. What each one is, the problem it solves, and how the five fit together, with a diagram for each. Notes on an IBM Technology video.
img: five-terms-ai-agent.webp
tags: [AI, Agents, MCP, Explainer]
---

A coding agent can plan a task, write the code, run the tests and open the pull request with very little help. The model alone does none of that. A model is a conversation partner. What turns it into an agent is a handful of pieces around it, and five of them have names worth knowing.

These are my notes on [*5 AI Agent Terms You Need to Know*](https://www.youtube.com/watch?v=k5jYwyhDMxA) by IBM Technology (11 minutes), with a diagram for each term and a few things I would add.

<div class="post-verdict">
<p class="post-verdict-label">In short</p>
<p><strong>Two terms shape what the agent knows, two let it reach outside itself, and one handles work too big for a single context.</strong> All five are, in the end, about the same scarce thing: what goes into the model's context window, and when.</p>
<ul class="post-facts">
<li><b>AGENTS.md</b> how this project works</li>
<li><b>Skills</b> how to do a kind of task</li>
<li><b>MCP</b> agent &rarr; tools and data</li>
<li><b>A2A</b> agent &rarr; agent</li>
<li><b>Subagents</b> work that does not fit</li>
</ul>
</div>

<div class="post-chart">
<p class="post-chart-title">The five pieces around the model</p>
<p class="post-chart-sub">Inside the box: what the agent knows. Arrows: how it reaches outside.</p>
<svg viewBox="0 0 640 322" role="img" aria-label="Diagram of an agent. In the centre is the model, wrapped in an instruction layer that holds 1, AGENTS.md, read every session, and 2, skills, read when needed. To the right, arrow 3, MCP, connects the agent to tools and data such as Notion, Stripe and a database. To the left, arrow 4, A2A, connects it to other agents such as a finance agent and a legal agent. Below, arrows 5 connect it to three subagents, each with its own context.">
<defs><marker id="ah1" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="#263959"/></marker></defs>
<rect x="180" y="16" width="280" height="214" rx="10" fill="#f4f5f7" stroke="#263959" stroke-width="1.5"/>
<text x="196" y="38" font-size="11" font-weight="700" letter-spacing="1" fill="#5a6776">THE AGENT</text>
<rect x="196" y="50" width="248" height="166" rx="8" fill="#fff" stroke="#a9b3c1" stroke-dasharray="4 3"/>
<text x="320" y="68" text-anchor="middle" font-size="11" fill="#5a6776">instruction layer</text>
<rect x="206" y="78" width="114" height="38" rx="4" fill="#eef1f6" stroke="#263959"/>
<circle cx="221" cy="97" r="9" fill="#263959"/><text x="221" y="101" text-anchor="middle" font-size="11" font-weight="700" fill="#fff">1</text>
<text x="235" y="94" font-size="13" font-weight="700" fill="#263959">AGENTS.md</text>
<text x="235" y="109" font-size="10.5" fill="#5a6776">every session</text>
<rect x="326" y="78" width="108" height="38" rx="4" fill="#eef1f6" stroke="#263959"/>
<circle cx="341" cy="97" r="9" fill="#263959"/><text x="341" y="101" text-anchor="middle" font-size="11" font-weight="700" fill="#fff">2</text>
<text x="355" y="94" font-size="13" font-weight="700" fill="#263959">Skills</text>
<text x="355" y="109" font-size="10.5" fill="#5a6776">when needed</text>
<rect x="257" y="134" width="126" height="48" rx="24" fill="#263959"/>
<text x="320" y="163" text-anchor="middle" font-size="13" font-weight="700" fill="#fff">Model (LLM)</text>
<text x="320" y="203" text-anchor="middle" font-size="11" fill="#5a6776">generates text, reasons</text>
<rect x="530" y="40" width="104" height="160" rx="8" fill="#fff" stroke="#a9b3c1"/>
<text x="582" y="60" text-anchor="middle" font-size="10.5" font-weight="700" letter-spacing="1" fill="#5a6776">TOOLS &amp; DATA</text>
<rect x="540" y="72" width="84" height="28" rx="4" fill="#f4f5f7"/><text x="582" y="91" text-anchor="middle" font-size="12" fill="#263959">Notion</text>
<rect x="540" y="108" width="84" height="28" rx="4" fill="#f4f5f7"/><text x="582" y="127" text-anchor="middle" font-size="12" fill="#263959">Stripe</text>
<rect x="540" y="144" width="84" height="28" rx="4" fill="#f4f5f7"/><text x="582" y="163" text-anchor="middle" font-size="12" fill="#263959">Database</text>
<line x1="462" y1="128" x2="527" y2="128" stroke="#263959" stroke-width="1.5" marker-start="url(#ah1)" marker-end="url(#ah1)"/>
<circle cx="476" cy="110" r="9" fill="#263959"/><text x="476" y="114" text-anchor="middle" font-size="11" font-weight="700" fill="#fff">3</text>
<text x="490" y="115" font-size="13" font-weight="700" fill="#263959">MCP</text>
<rect x="6" y="72" width="104" height="112" rx="8" fill="#fff" stroke="#a9b3c1"/>
<text x="58" y="92" text-anchor="middle" font-size="10.5" font-weight="700" letter-spacing="1" fill="#5a6776">OTHER AGENTS</text>
<rect x="16" y="104" width="84" height="28" rx="4" fill="#f4f5f7"/><text x="58" y="123" text-anchor="middle" font-size="12" fill="#263959">Finance</text>
<rect x="16" y="140" width="84" height="28" rx="4" fill="#f4f5f7"/><text x="58" y="159" text-anchor="middle" font-size="12" fill="#263959">Legal</text>
<line x1="113" y1="128" x2="178" y2="128" stroke="#263959" stroke-width="1.5" marker-start="url(#ah1)" marker-end="url(#ah1)"/>
<circle cx="127" cy="110" r="9" fill="#263959"/><text x="127" y="114" text-anchor="middle" font-size="11" font-weight="700" fill="#fff">4</text>
<text x="141" y="115" font-size="13" font-weight="700" fill="#263959">A2A</text>
<line x1="245" y1="232" x2="245" y2="268" stroke="#263959" stroke-width="1.5" marker-start="url(#ah1)" marker-end="url(#ah1)"/>
<line x1="320" y1="232" x2="320" y2="268" stroke="#263959" stroke-width="1.5" marker-start="url(#ah1)" marker-end="url(#ah1)"/>
<line x1="395" y1="232" x2="395" y2="268" stroke="#263959" stroke-width="1.5" marker-start="url(#ah1)" marker-end="url(#ah1)"/>
<rect x="212" y="270" width="66" height="40" rx="6" fill="#fff" stroke="#7d8aa0"/><text x="245" y="295" text-anchor="middle" font-size="11.5" fill="#263959">subagent</text>
<rect x="287" y="270" width="66" height="40" rx="6" fill="#fff" stroke="#7d8aa0"/><text x="320" y="295" text-anchor="middle" font-size="11.5" fill="#263959">subagent</text>
<rect x="362" y="270" width="66" height="40" rx="6" fill="#fff" stroke="#7d8aa0"/><text x="395" y="295" text-anchor="middle" font-size="11.5" fill="#263959">subagent</text>
<circle cx="452" cy="285" r="9" fill="#263959"/><text x="452" y="289" text-anchor="middle" font-size="11" font-weight="700" fill="#fff">5</text>
<text x="466" y="290" font-size="13" font-weight="700" fill="#263959">Subagents</text>
<text x="466" y="305" font-size="10.5" fill="#5a6776">each with its own context</text>
</svg>
</div>

## 1. AGENTS.md: a README written for the agent

`AGENTS.md` is a plain Markdown file at the root of a project. Whenever the agent starts work there, it reads the file first. It holds what a new colleague would need on day one: the setup commands, how to run the tests, the code style, how a pull request title should look.

The agent acts on it when it is relevant. If the file says *run `pnpm test` before committing*, the agent runs `pnpm test` before it commits.

Files can be nested. A monorepo can have one at the root and one per subproject, and the one closest to the code being changed wins where they disagree:

```text
repo/
├── AGENTS.md          pnpm test before commit
└── packages/
    ├── web/
    │   └── AGENTS.md  Next.js lint rules
    └── api/
        └── AGENTS.md  go test   ← wins here
```

`AGENTS.md` came from OpenAI and is now stewarded by the Agentic AI Foundation (AAIF) under the Linux Foundation. Some agents read a file of their own name for the same job: Claude Code reads `CLAUDE.md`. Different name, same idea.

## 2. Agent skills: knowledge loaded only when it is needed

`AGENTS.md` is read every time. That is right for how *this project* works, and wrong for knowledge the agent needs only sometimes, such as how to build a PowerPoint deck. Loading that into every session would fill the context window with instructions the task at hand never uses.

An agent skill is a folder. Inside it is a `SKILL.md` file and whatever scripts or resources the task needs. The top of `SKILL.md` carries a name and a description that says, in effect, *use me when the user wants X*:

```markdown
---
name: pptx
description: Create and edit PowerPoint decks. Use when the user asks for slides or a .pptx file.
---
# Building a deck
1. Start from template.pptx in this folder ...
```

The agent sees only the descriptions up front. When a request matches one, it pulls in the rest of the skill. When nothing matches, the skill sits out of the way. The video says it takes no context at all; strictly, the one-line description does, which is the price of the agent knowing the skill exists.

<div class="post-chart">
<p class="post-chart-title">What the context window holds before the task starts</p>
<p class="post-chart-sub">Three skills installed. Sizes illustrative.</p>
<div class="post-chart-legend"><span><i style="background:#263959"></i>AGENTS.md</span><span><i style="background:#7d8aa0"></i>skill descriptions</span><span><i style="background:#a9b3c1"></i>full skill</span><span><i style="background:#fff;border:1px solid #a9b3c1"></i>room for the task</span></div>
<svg viewBox="0 0 640 150" role="img" aria-label="Three bars showing the context window. If all three skills are loaded up front, AGENTS.md and the PowerPoint, PDF and spreadsheet skills take more than half of the window. With skills, only AGENTS.md and three short descriptions are loaded, leaving almost the whole window for the task. When a PowerPoint request arrives, the PowerPoint skill alone is added.">
<text x="0" y="24" font-size="13" font-weight="700" fill="#263959">Everything up front</text>
<text x="0" y="39" font-size="11.5" fill="#5a6776">all skills, every session</text>
<rect x="170" y="12" width="40" height="30" fill="#263959"/>
<rect x="211" y="12" width="100" height="30" fill="#a9b3c1"/><text x="261" y="32" text-anchor="middle" font-size="11" fill="#1a2b45">PowerPoint</text>
<rect x="312" y="12" width="80" height="30" fill="#a9b3c1"/><text x="352" y="32" text-anchor="middle" font-size="11" fill="#1a2b45">PDF</text>
<rect x="393" y="12" width="90" height="30" fill="#a9b3c1"/><text x="438" y="32" text-anchor="middle" font-size="11" fill="#1a2b45">Spreadsheet</text>
<rect x="484" y="12.5" width="151" height="29" fill="#fff" stroke="#a9b3c1"/>
<text x="0" y="74" font-size="13" font-weight="700" fill="#263959">Skills, idle</text>
<text x="0" y="89" font-size="11.5" fill="#5a6776">descriptions only</text>
<rect x="170" y="62" width="40" height="30" fill="#263959"/>
<rect x="211" y="62" width="18" height="30" fill="#7d8aa0"/>
<rect x="230" y="62.5" width="405" height="29" fill="#fff" stroke="#a9b3c1"/><text x="432" y="82" text-anchor="middle" font-size="11" fill="#5a6776">room for the task</text>
<text x="0" y="124" font-size="13" font-weight="700" fill="#263959">Skills, "make slides"</text>
<text x="0" y="139" font-size="11.5" fill="#5a6776">one skill pulled in</text>
<rect x="170" y="112" width="40" height="30" fill="#263959"/>
<rect x="211" y="112" width="18" height="30" fill="#7d8aa0"/>
<rect x="230" y="112" width="100" height="30" fill="#a9b3c1"/><text x="280" y="132" text-anchor="middle" font-size="11" fill="#1a2b45">PowerPoint</text>
<rect x="331" y="112.5" width="304" height="29" fill="#fff" stroke="#a9b3c1"/><text x="483" y="132" text-anchor="middle" font-size="11" fill="#5a6776">room for the task</text>
</svg>
</div>

Anthropic introduced skills for Claude and published the format as an open standard, and several agent platforms now read it. In short: `AGENTS.md` tells the agent how *this project* works; a skill tells it how to do *a kind of task*, in any project.

## 3. MCP: one plug for every tool

Now the agent knows what to do. Doing it means reaching outside: APIs, databases, developer tools, SaaS products. Each has its own interface, so without a standard every agent needs a custom connector for every tool it touches.

The **Model Context Protocol** is an open protocol for connecting AI applications to tools, data and workflows. A tool is wrapped once in an **MCP server**, which handles that tool's own API. Any agent that speaks MCP can then use it. When the agent needs a page from Notion, it speaks MCP to the Notion server, and the server talks to Notion.

<div class="post-chart">
<p class="post-chart-title">Connectors needed for 3 agents and 4 tools</p>
<svg viewBox="0 0 640 240" role="img" aria-label="Left: without a standard, three agents each connect directly to four tools, twelve custom connectors. Right: with MCP, each agent speaks MCP once and each tool is wrapped once in an MCP server, seven integrations in total.">
<text x="16" y="18" font-size="11" font-weight="700" letter-spacing="1" fill="#5a6776">WITHOUT A STANDARD</text>
<g stroke="#c0461a" stroke-width="1.2" opacity="0.6">
<line x1="106" y1="64" x2="210" y2="50"/><line x1="106" y1="64" x2="210" y2="96"/><line x1="106" y1="64" x2="210" y2="142"/><line x1="106" y1="64" x2="210" y2="188"/>
<line x1="106" y1="119" x2="210" y2="50"/><line x1="106" y1="119" x2="210" y2="96"/><line x1="106" y1="119" x2="210" y2="142"/><line x1="106" y1="119" x2="210" y2="188"/>
<line x1="106" y1="174" x2="210" y2="50"/><line x1="106" y1="174" x2="210" y2="96"/><line x1="106" y1="174" x2="210" y2="142"/><line x1="106" y1="174" x2="210" y2="188"/>
</g>
<g font-size="12" fill="#263959" text-anchor="middle">
<rect x="16" y="50" width="90" height="28" rx="4" fill="#f4f5f7" stroke="#a9b3c1"/><text x="61" y="69">Coding agent</text>
<rect x="16" y="105" width="90" height="28" rx="4" fill="#f4f5f7" stroke="#a9b3c1"/><text x="61" y="124">Chat app</text>
<rect x="16" y="160" width="90" height="28" rx="4" fill="#f4f5f7" stroke="#a9b3c1"/><text x="61" y="179">Your agent</text>
<rect x="210" y="36" width="90" height="28" rx="4" fill="#fff" stroke="#a9b3c1"/><text x="255" y="55">Notion</text>
<rect x="210" y="82" width="90" height="28" rx="4" fill="#fff" stroke="#a9b3c1"/><text x="255" y="101">Stripe</text>
<rect x="210" y="128" width="90" height="28" rx="4" fill="#fff" stroke="#a9b3c1"/><text x="255" y="147">GitHub</text>
<rect x="210" y="174" width="90" height="28" rx="4" fill="#fff" stroke="#a9b3c1"/><text x="255" y="193">Database</text>
</g>
<text x="158" y="230" text-anchor="middle" font-size="13" font-weight="700" fill="#c0461a">3 &times; 4 = 12 connectors</text>
<line x1="322" y1="10" x2="322" y2="236" stroke="#e6e8eb"/>
<text x="340" y="18" font-size="11" font-weight="700" letter-spacing="1" fill="#5a6776">WITH MCP</text>
<g stroke="#2e7d4f" stroke-width="1.5">
<line x1="430" y1="64" x2="470" y2="64"/><line x1="430" y1="119" x2="470" y2="119"/><line x1="430" y1="174" x2="470" y2="174"/>
<line x1="496" y1="50" x2="530" y2="50"/><line x1="496" y1="96" x2="530" y2="96"/><line x1="496" y1="142" x2="530" y2="142"/><line x1="496" y1="188" x2="530" y2="188"/>
</g>
<rect x="470" y="36" width="26" height="166" rx="4" fill="#263959"/>
<text x="483" y="119" text-anchor="middle" font-size="12" font-weight="700" fill="#fff" transform="rotate(-90 483 119)" dy="4">MCP</text>
<g font-size="12" fill="#263959" text-anchor="middle">
<rect x="340" y="50" width="90" height="28" rx="4" fill="#f4f5f7" stroke="#a9b3c1"/><text x="385" y="69">Coding agent</text>
<rect x="340" y="105" width="90" height="28" rx="4" fill="#f4f5f7" stroke="#a9b3c1"/><text x="385" y="124">Chat app</text>
<rect x="340" y="160" width="90" height="28" rx="4" fill="#f4f5f7" stroke="#a9b3c1"/><text x="385" y="179">Your agent</text>
</g>
<g font-size="12" fill="#263959">
<rect x="530" y="36" width="104" height="28" rx="4" fill="#fff" stroke="#a9b3c1"/><rect x="530" y="36" width="7" height="28" fill="#263959"/><text x="545" y="55">Notion</text>
<rect x="530" y="82" width="104" height="28" rx="4" fill="#fff" stroke="#a9b3c1"/><rect x="530" y="82" width="7" height="28" fill="#263959"/><text x="545" y="101">Stripe</text>
<rect x="530" y="128" width="104" height="28" rx="4" fill="#fff" stroke="#a9b3c1"/><rect x="530" y="128" width="7" height="28" fill="#263959"/><text x="545" y="147">GitHub</text>
<rect x="530" y="174" width="104" height="28" rx="4" fill="#fff" stroke="#a9b3c1"/><rect x="530" y="174" width="7" height="28" fill="#263959"/><text x="545" y="193">Database</text>
</g>
<text x="487" y="230" text-anchor="middle" font-size="13" font-weight="700" fill="#2e7d4f">3 + 4 = 7, each written once</text>
</svg>
<p class="post-chart-sub">Dark edge on a tool: its MCP server.</p>
</div>

MCP started at Anthropic and is now governed by the same AAIF at the Linux Foundation, with broad industry support.

## 4. A2A: agents talking to agents

MCP covers an agent talking to tools and data. **Agent2Agent (A2A)** is the open protocol for an agent talking to another agent.

The video's example: a procurement agent negotiates vendor contracts, a finance agent approves spend. Once procurement has a contract, it has to hand it to finance. Without a shared protocol, the two need a custom integration, or they do not coordinate well.

With A2A, every agent publishes an **agent card**: a short description of what it does and how to reach it. Another agent reads the card and knows whether, and how, to delegate. A trimmed one:

```json
{
  "name": "Finance agent",
  "description": "Approves spend against the department budget.",
  "url": "https://finance.example.com/a2a",
  "skills": [
    { "id": "approve-spend", "name": "Approve spend",
      "description": "Approve or reject a contract or purchase." }
  ]
}
```

<div class="post-chart">
<p class="post-chart-title">Procurement hands a contract to finance</p>
<svg viewBox="0 0 640 218" role="img" aria-label="Sequence between a procurement agent and a finance agent. 1: procurement fetches the finance agent's card. 2: finance returns the card, approves spend. 3: procurement sends a task, approve this contract. 4: finance returns the result, approved.">
<defs><marker id="ah2" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" fill="#263959"/></marker></defs>
<rect x="60" y="8" width="170" height="34" rx="6" fill="#263959"/><text x="145" y="30" text-anchor="middle" font-size="13" font-weight="700" fill="#fff">Procurement agent</text>
<rect x="410" y="8" width="170" height="34" rx="6" fill="#263959"/><text x="495" y="30" text-anchor="middle" font-size="13" font-weight="700" fill="#fff">Finance agent</text>
<line x1="145" y1="42" x2="145" y2="210" stroke="#a9b3c1" stroke-dasharray="4 3"/>
<line x1="495" y1="42" x2="495" y2="210" stroke="#a9b3c1" stroke-dasharray="4 3"/>
<g font-size="12" fill="#263959" text-anchor="middle">
<line x1="147" y1="76" x2="491" y2="76" stroke="#263959" stroke-width="1.5" marker-end="url(#ah2)"/><text x="320" y="68">1 &#183; fetch the agent card</text>
<line x1="493" y1="116" x2="149" y2="116" stroke="#263959" stroke-width="1.5" stroke-dasharray="5 3" marker-end="url(#ah2)"/><text x="320" y="108">2 &#183; card: "approves spend"</text>
<line x1="147" y1="156" x2="491" y2="156" stroke="#263959" stroke-width="1.5" marker-end="url(#ah2)"/><text x="320" y="148">3 &#183; task: approve this contract</text>
<line x1="493" y1="196" x2="149" y2="196" stroke="#2e7d4f" stroke-width="1.5" stroke-dasharray="5 3" marker-end="url(#ah2)"/><text x="320" y="188" fill="#2e7d4f" font-weight="700">4 &#183; result: approved</text>
</g>
</svg>
</div>

A2A comes from Google and is also an open standard under the Linux Foundation. MCP is how an agent reaches tools and data; A2A is how it reaches other agents.

## 5. Subagents: when one context is not enough

Sometimes one agent is not enough. The task can be too big for one context window: reviewing a codebase of thousands of files by loading every file would fill it on its own. Or the work is embarrassingly parallel: twenty independent checks on twenty functions, done one at a time when they could all run at once.

A **subagent** is a child agent the main agent spawns for one piece of work. It starts with a fresh context, does the job, and returns only the result. *Read these 500 files and give me a summary*: the 500 files fill the child's context, and the parent receives a few paragraphs.

<div class="post-chart">
<p class="post-chart-title">The parent stays clean, the children do the reading</p>
<div class="post-chart-legend"><span><i style="background:#263959"></i>context used</span><span><i style="background:#2e7d4f"></i>returned summaries</span></div>
<svg viewBox="0 0 640 220" role="img" aria-label="A main agent sends four subagents a task each: read files 1 to 500, 501 to 1000, 1001 to 1500, and so on. Each subagent's context is almost full of files. Each returns a short summary, so the main agent's context stays mostly empty.">
<defs><marker id="ah3" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" fill="#7d8aa0"/></marker></defs>
<rect x="10" y="70" width="190" height="80" rx="8" fill="#f4f5f7" stroke="#263959" stroke-width="1.5"/>
<text x="24" y="93" font-size="13" font-weight="700" fill="#263959">Main agent</text>
<rect x="24" y="106" width="162" height="16" rx="2" fill="#fff" stroke="#a9b3c1"/>
<rect x="24" y="106" width="40" height="16" fill="#263959"/><rect x="64" y="106" width="20" height="16" fill="#2e7d4f"/>
<text x="24" y="140" font-size="11" fill="#5a6776">context mostly free</text>
<g stroke="#7d8aa0" stroke-width="1.3" fill="none">
<path d="M200 104 C 260 104, 270 34, 336 34" marker-end="url(#ah3)"/>
<path d="M200 108 C 260 108, 270 84, 336 84" marker-end="url(#ah3)"/>
<path d="M200 112 C 260 112, 270 134, 336 134" marker-end="url(#ah3)"/>
<path d="M200 116 C 260 116, 270 184, 336 184" marker-end="url(#ah3)"/>
</g>
<text x="268" y="62" text-anchor="middle" font-size="11" fill="#5a6776">tasks out,</text>
<text x="268" y="168" text-anchor="middle" font-size="11" fill="#2e7d4f">summaries back</text>
<g font-size="12" fill="#263959">
<rect x="340" y="14" width="290" height="40" rx="6" fill="#fff" stroke="#7d8aa0"/><text x="352" y="38">files 1&#8211;500</text><rect x="470" y="26" width="148" height="16" fill="#263959"/>
<rect x="340" y="64" width="290" height="40" rx="6" fill="#fff" stroke="#7d8aa0"/><text x="352" y="88">files 501&#8211;1000</text><rect x="470" y="76" width="140" height="16" fill="#263959"/><rect x="610" y="76" width="8" height="16" fill="#fff" stroke="#a9b3c1"/>
<rect x="340" y="114" width="290" height="40" rx="6" fill="#fff" stroke="#7d8aa0"/><text x="352" y="138">files 1001&#8211;1500</text><rect x="470" y="126" width="144" height="16" fill="#263959"/>
<rect x="340" y="164" width="290" height="40" rx="6" fill="#fff" stroke="#7d8aa0"/><text x="352" y="188">&#8230; up to 20 in parallel</text><rect x="470" y="176" width="136" height="16" fill="#263959"/>
</g>
</svg>
</div>

Subagents differ from the other four in one way: there is no standard document behind them. It is a pattern, but it looks almost the same everywhere. The parent spawns one or more children, each child gets its own context, does what it was told and returns a result, and the parent carries on with its own context intact.

## The five together

<div class="post-table" role="region" aria-label="The five terms compared" tabindex="0">
<table>
<thead><tr><th scope="col">Term</th><th scope="col">Answers</th><th scope="col">Enters the context</th><th scope="col">Standard</th></tr></thead>
<tbody>
<tr><th scope="row"><b>AGENTS.md</b></th><td class="wrap">How does this project work?</td><td class="wrap">every session</td><td class="wrap">open spec, AAIF</td></tr>
<tr><th scope="row"><b>Agent skills</b></th><td class="wrap">How do I do this kind of task?</td><td class="wrap">description always, the rest on a match</td><td class="wrap">open spec</td></tr>
<tr><th scope="row"><b>MCP</b></th><td class="wrap">How do I reach this tool or data?</td><td class="wrap">tool list, then each result</td><td class="wrap">open protocol, AAIF</td></tr>
<tr><th scope="row"><b>A2A</b></th><td class="wrap">Who can I hand this work to?</td><td class="wrap">the card, then the result</td><td class="wrap">open protocol, Linux Foundation</td></tr>
<tr><th scope="row"><b>Subagents</b></th><td class="wrap">What if the work does not fit?</td><td class="wrap">only the child's summary</td><td class="wrap">a pattern, no spec</td></tr>
</tbody>
</table>
</div>

Read the middle column top to bottom and the five turn out to be one idea: the context window is the scarce resource, and each term is a rule for what is allowed into it, and when.

## What I would add: four of the five are things the agent obeys

`AGENTS.md` and `SKILL.md` are instructions in plain text, followed by a program that can run commands. An MCP server is a dependency that holds your credentials. An agent card is a stranger describing itself. None of that is a reason to avoid them, but it is a reason to treat them like code: review them, pin their versions, and give each the narrowest access it needs. And keep a record of what the agent actually did, not only what it was told to do. No technology fixes bad design, it only mitigates it, and an agent is a very fast way to carry out a design, good or bad.
