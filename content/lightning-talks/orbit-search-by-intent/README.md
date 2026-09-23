# The API You Can't Name — Searching by Intent Instead

> [Lightning talk](../../../templates/formats/lightning-talk.md) — target length **10 minutes**.
> This README is the single source of truth. Read it top to bottom before you present;
> everything you need to deliver without improvising is here.

One engineer needed three capabilities — check a calendar, write an event, send a confirmation —
and could not name the API that provided them. This talk shows what they did instead: describe the
task, get back callable endpoints with a fit evaluation, and get a task brief that named three bugs
before a line of client code was written. It is a story about how API discovery changed, not a
product tour.

> **The numbers are measured, not written.** `setup.sh` re-measures most of the Act 4 scoreboard on
> the day you present — real Orbit calls, real documentation pages, real byte and character counts,
> and the gotcha grep — and writes `.demo-state/scoreboard.txt`. **Say the numbers in that file, not
> the ones in this README.** The figures quoted below are from a run on **2026-09-01** so you know
> the shape to expect.
>
> **Two exceptions: tokens and cost.** Those were measured once, on **2026-09-01**, and are held as
> fixed constants in `setup.sh` and on slide 4 — see [§3b](#3b-refreshing-the-fixed-token-and-cost-figures).
> The scoreboard prints them in a block labelled `FIXED`, separate from what it measured today, so
> you always know which is which. Everything in the `MEASURED TODAY` block is computed on the spot.
>
> **There is no speed comparison anywhere in this talk, on purpose.** Two Orbit calls that return an
> evaluated, gotcha-annotated brief and four raw HTML downloads are not the same operation — timing
> one against the other compares nothing. If someone asks, say exactly that.

---

## 1. Product summary

- **Product:** Orbit by Postman, via the [Orbit MCP server](https://www.buildwithorbit.ai/welcome)
- **Use case:** Find and integrate a public API when you know the capability you need but not the vendor's name.
- **Format:** lightning-talk (10m) — see [templates/formats/lightning-talk.md](../../../templates/formats/lightning-talk.md)
- **Audience:** Developers and AI engineers who have read API docs and shipped an integration. No prior Orbit or MCP knowledge assumed.

**The story (the narrative arc):**

> A team is building a healthcare app. Booking works: a patient picks a slot, the service publishes
> an `appointment.booked` event. But the clinician's real calendar never learns about it, and the
> patient never hears from anyone again. So the feature is clear — check the calendar before you
> confirm, write the event, email the patient. Three capabilities, and no idea whose API provides
> them. That used to mean a brute-force loop: guess a product name, open its docs, map your
> capabilities onto its endpoints, work out the auth model, and discover on candidate four that it
> can't do one of the three. Instead they described the task in one sentence, got back evaluated
> endpoints with a "not supported" line that eliminated candidates on sight, and got a brief with
> the request bodies, the execution order, and the three things that would have broken in
> production — epoch seconds, a nullable field that means `true`, and an idempotency header. Then
> you show the scoreboard: the documentation path pulls roughly ten times the tokens into context
> and still doesn't contain any of those three.

**CTA:**

- One command — `claude mcp add --transport http orbit https://mcp.buildwithorbit.ai/mcp`
- Orbit docs — <https://www.buildwithorbit.ai/welcome>
- The full story — <https://blog.postman.com/how-ai-agents-discover-and-integrate-public-apis/>

**Total time: ~10 minutes.** Acts 1, 2 and 4 are deck-only and run **fully offline**. **Act 3 is
the live demo and needs the network** — but `setup.sh` caches a real search response and task brief
in `.demo-state/`, so if the network or Orbit fails on stage you read Act 3 from the cache and the
talk still lands. There is no Q&A inside the slot; questions happen after, one to one.

---

## 2. Pre-requisites

| Requirement | How to get it |
|---|---|
| A modern browser (Chrome, Safari, Firefox) | Pre-installed. The fallback deck is a single self-contained HTML file; the Claude Design deck, if configured, needs a login. |
| `curl` | Pre-installed on macOS; `apt install curl` on Linux. Used by `setup.sh` to measure both paths. |
| `python3` (3.8+) | Pre-installed on macOS; <https://www.python.org/downloads/>. Computes the scoreboard. |
| Claude Code | <https://code.claude.com/docs> — Act 3 is driven from a Claude Code session. |
| Network, for Act 3 and for setup | `api.buildwithorbit.ai`, `mcp.buildwithorbit.ai`, `developer.nylas.com`. Acts 1, 2, 4 need nothing. |
| An API key — Orbit's, Anthropic's, anyone's | **None needed, anywhere.** Orbit's `search` and `integrate` endpoints are public and unauthenticated — worth saying out loud in Act 2. The scoreboard no longer counts tokens at run time, so it needs no `ANTHROPIC_API_KEY` either. |

### Workspace prep before the day

Run `./scripts/setup.sh`, then **launch `claude` in this folder once and approve the `.mcp.json`
prompt**. That approval is a one-time interactive step and it cannot be scripted — doing it on
stage costs you thirty seconds and your composure.

---

## 3. Setup

```bash
cd content/lightning-talks/orbit-search-by-intent
./scripts/setup.sh
```

`setup.sh` will:

1. Resolve the deck source — Claude Design if `presentation/deck-url.txt` holds a URL, otherwise the local HTML — and confirm the `presentation/index.html` fallback is a complete, self-contained HTML file either way.
2. Validate `curl`, `python3`, and Claude Code, failing with the command that fixes each.
3. Write a **project-scoped** `.mcp.json` registering the Orbit MCP server for this folder only — it does not touch your global Claude config. `teardown.sh` removes it.
4. Run the **real** Orbit `search` call and cache the response to `.demo-state/search.json`.
5. Run the **real** Orbit `integrate` call — building the request from the endpoint IDs the search just returned, never from hardcoded IDs — and cache the brief to `.demo-state/integrate.json`.
6. Write **readable copies** of both — indented JSON, plus `.txt` renders you can read cold. See [§3c](#3c-the-cached-artifacts-and-which-copy-to-read).
7. Fetch the four documentation pages an agent would otherwise read, into `.demo-state/docs/`.
8. Write `.demo-state/scoreboard.txt` — a `MEASURED TODAY` block computed from those fetches, and a `FIXED` block holding the one-off token and cost figures. No token counting happens at run time.
9. Print **the full Orbit prompt sheet** — all five prompts in running order, plus the no-Claude-Code
   `curl` backup. See [§3a](#3a-the-prompt-sheet).
10. Open the deck — the Claude Design one if configured, otherwise the local HTML fallback.

Steps 4–8 **warn rather than fail** on a network problem, and name which act is affected. If the
Orbit calls fail but a previous run cached results, setup says so and Act 3 falls back to the cache.

### Authentication

**None for Orbit.** Both endpoints are public. The MCP server's own tool description says
"No authentication required" — Act 2 uses that fact.

**And none for the scoreboard.** It used to take an optional `ANTHROPIC_API_KEY` to count tokens
exactly. It no longer counts tokens at all — they are fixed figures now — so `setup.sh` needs no
credential of any kind.

### Where the deck comes from

The deck has **two sources, in priority order**, and `setup.sh` picks between them:

| Priority | Source | When it is used |
|---|---|---|
| 1 | **Claude Design** — the team design system lives there, so this is the deck of record | When `presentation/deck-url.txt` contains the deck's share URL. `setup.sh` opens it *and* the HTML fallback behind it. |
| 2 | `presentation/index.html` — self-contained, committed, offline | Always available. Used automatically when no Claude Design URL is configured, and it is the answer to "the venue wifi died" or "I can't log in to Claude Design." |

The point of keeping both: **there is always a deck.** Claude Design gives the talk the team's design
system instead of a one-off theme, but it needs a login and a network, and neither is guaranteed at a
booth. The HTML deck is the guarantee.

To make Claude Design the deck of record, put its share URL on one line in
`presentation/deck-url.txt` (lines starting with `#` are ignored) and re-run `setup.sh`. That file is
committed, so the whole team presents from the same deck.

> **Current state:** no `deck-url.txt` yet — this talk presents from the HTML deck. Pushing the deck
> into Claude Design needs a one-time `/design-login` run from a **standalone terminal** (the VSCode
> extension can't do the interactive authorization), after which the deck can be built against the
> existing design-system project rather than a new one.

### Pre-flight checklist

- [ ] Deck open, **fullscreen**, on slide 1 of 5 — and if it's the Claude Design deck, the HTML
      fallback open in a second tab
- [ ] Terminal open in this folder, font bumped for the room (`Cmd+=`)
- [ ] `claude` launched here **once** and the `.mcp.json` approval prompt accepted
- [ ] `/mcp` in Claude Code lists **orbit** with two tools: `search` and `integrate`
- [ ] You have read `.demo-state/scoreboard.txt` and know **today's** numbers
- [ ] You can say the three gotchas cold: **epoch seconds**, **nullable `busy`**, **`Idempotency-Key`**
- [ ] Browser zoom set so the deck reads from 6 feet
- [ ] Claude Code session cleared (`/clear`) so the search runs fresh

---

## 3a. The prompt sheet

`setup.sh` prints every prompt this talk uses, in running order, right before the pre-flight
checklist. **Read them off that output, not off this README** — the terminal is already in front of
you and the copy there is the one that stays in sync with the script.

| # | When | Required? |
|---|---|---|
| 1 | Act 3 beat 1 — the product problem in a colleague's words | **Yes** |
| 2 | Act 3 beat 2 — the brief, agent carries the IDs | **Yes** |
| 3 | The contrast shot — the deliberately-bad query, to show mechanism-vs-feature | Optional, ~30s, skip if behind |
| 4 | The offline fallback — walk the cached `search.json` / `integrate.json` | Only if the network or Orbit dies |
| 5 | The CTA prompt from slide 5 — say it, don't run it | Spoken |

It also prints the raw `curl` equivalents of both Orbit calls, for the case where the MCP server
won't load at all. Both endpoints are public and unauthenticated, so that backup always works.

---

## 3b. Refreshing the fixed token and cost figures

Everything in the scoreboard is measured on the day **except two rows**: tokens into context, and
input cost. Those are constants, for a deliberate reason — recomputing them each launch needed
either an `ANTHROPIC_API_KEY` or a `chars / 3.5` estimate, and it produced a slightly different
number every run for an argument whose shape ("about ten times") never actually moved. A figure that
wobbles run to run is a figure you hesitate over on stage.

**Current values, measured 2026-09-01 by a `chars / 3.5` estimate at Opus 5 input pricing
($5.00 / 1M):**

| | Orbit | Read the docs |
|---|---|---|
| Tokens into context | 2,413 | 25,647 — **10.6×** |
| Input cost | $0.0121 | $0.1282 |

To refresh them, change **both places together or they will drift**:

1. `scripts/setup.sh` — the constants `FIXED_DATE`, `FIXED_METHOD`, `ORBIT_TOK`, `DOCS_TOK`,
   `ORBIT_COST`, `DOCS_COST`, in the scoreboard's Python block.
2. `presentation/index.html` — slide 4's table rows and the `Measured …` caption beneath it.

The `Text into context` character counts in the `MEASURED TODAY` block are what these were derived
from, so a run whose character counts have moved a long way from ~8.4k / ~90k is the signal to
re-measure.

---

## 3c. The cached artifacts, and which copy to read

Orbit returns both responses as a single line of JSON, and the task brief arrives as one long JSON
string with escaped `\n` — unreadable at a glance, which is a problem when it is your on-stage
fallback. So `setup.sh` writes **three copies of each response**, and which one you want depends on
what you are doing:

| File | Shape | Use it for |
|---|---|---|
| `.demo-state/search.txt`<br>`.demo-state/integrate.txt` | Plain text. One block per search result with its `evaluateGuide`; the brief with **real newlines**. | **Reading on stage.** This is the copy to open if you are walking the fallback yourself, or glancing at the brief while you talk. |
| `.demo-state/search.json`<br>`.demo-state/integrate.json` | The same JSON, indented two spaces. | Prompt 4's offline fallback, and anything that needs to be visibly *the API's response*. Claude Code reads these. |
| `.demo-state/raw/search.json`<br>`.demo-state/raw/integrate.json` | **Exactly** what came off the wire — one line, untouched. | Nothing on stage. This is what the scoreboard measures, and what you show if someone challenges the byte count. |

**Why the raw copy exists at all:** indenting adds a few thousand bytes of whitespace, and the
scoreboard's `Bytes retrieved` and `Text into context` rows are Orbit's side of the Act 4
comparison. Measuring the indented copy would inflate Orbit's own numbers with formatting — a
made-up figure in a talk whose whole premise is that the numbers are measured. So the scoreboard
always reads `raw/`, and if `raw/` is missing (a cache from before this existed) it falls back to
the indented copy **and prints a note saying the figures are overstated**.

The `.txt` renders are derived, never measured, and never quoted on the scoreboard.

---

## 4. Talk track and click track

**Total time: ~10 minutes.** Four acts. Talk track is **verbatim** — read it as-is if the room goes
cold. The deck's 5 slides, in order: **(1)** title · **(2)** the problem · **(3)** the shift ·
**(4)** live demo + scoreboard · **(5)** CTA.

---

### Act 1: The API you can't name (1.5 min) — slides 1–2

**Show:** slide 1 — "The API you can't name."

#### Talk track

> "I want to tell you about the hardest API I ever had to integrate. Not because it was badly
> designed — because I couldn't name it.
>
> My team builds a healthcare app. Booking already worked: a patient picks a slot, we write a row,
> we publish an `appointment.booked` event. And then nothing else happens. The clinician's real
> calendar never learns about the appointment, so a clinician who blocks time outside our app gets
> a patient booked over it. And the patient's only record of the visit is a page they already
> closed.
>
> So the feature was obvious. Check the clinician's calendar before we confirm the slot. Write the
> appointment to that calendar. Email the patient. Three capabilities — and no idea whose API
> provided them."

**Do:** advance to slide 2 — "I knew the feature. I didn't know the vendor."

**Show (payoff):** the five-step loop, with step 5 in orange.

> "Here's what that used to cost. Guess a product name. Open the docs site. Map my three
> capabilities onto their endpoints. Work out the auth model and the scoping rules. And then
> discover on candidate four that it does two of the three things and not the third.
>
> Look at where the failure is. It's at the bottom. Every candidate fails **after** you've already
> paid the full price of understanding it. That's the part I want to talk about — not the code. The
> code was one Kafka consumer and three HTTP calls. The expensive part was everything before it."

---

### Act 2: Describe the outcome, get the interfaces (1 min) — slide 3

**Do:** advance to slide 3 — "Describe the outcome. Get the interfaces."

#### Talk track

> "So I stopped guessing and inverted the search. Instead of starting with an API name, you start
> with the task.
>
> Two tools. `search` takes a sentence about what you need to do and gives you back **callable
> endpoints** — method, URL, and for each one an `evaluateGuide`: what it does, what it's good for,
> and what it does **not** support. `integrate` takes the task plus the endpoints you picked and
> gives you one **task brief**: fit, auth, base URL, the steps with every parameter, and the
> gotchas. No API key for either one."

**Show (payoff):** the pull-quote at the bottom of the slide.

> "But here's the part I actually want you to remember, because it's the interesting engineering.
>
> This MCP server does not just wrap the API. Read the `search` tool description and it tells the
> model: review `evaluateGuide` before you choose, then pass the chosen result's `id` and
> `resourceType` into `integrate`. The **chaining rule lives in the tool description**, not in my
> prompt. I never told the agent it was a two-step workflow. The server did.
>
> That's the difference between an MCP server that exposes endpoints and one that encodes how the
> API is meant to be used. The tools carry instructions, not just schemas."

---

### Act 3: The demo — one search, one brief (6 min) — slide 4

**Do:** advance to slide 4 and leave it up as the backdrop. Point at the left column.

> "Three things to watch for. One: what the agent does to my sentence. Two: the line that kills a
> candidate. Three: the part that saved me from production."

**Do:** switch to the terminal, in this folder, with `claude` running. Paste the beat-1 prompt
(also printed by `setup.sh`):

```text
The appointments service publishes appointment.booked but nothing reaches the
clinician's real calendar. Find me an API that can check whether a clinician is
free before we confirm a slot. Show me the evaluateGuide for each result.
```

**Show (payoff):** the agent calls `orbit - search`. Point at the query it actually sent.

> "First thing. Look at what it sent. I described a **product problem** — a service publishes an
> event and nothing reaches a calendar. It sent **calendar vocabulary**: free/busy time slots
> before booking a meeting. That translation is the thing that makes or breaks this. And it's the
> one lesson I'd tape to your monitor: **name the mechanism, not the feature.** 'Create a calendar
> event for a booked appointment' pulls back school calendar systems and integration platforms,
> because every product on earth has the nouns 'calendar' and 'appointment' in it. 'Find available
> free busy time slots before booking a meeting' returned the API I needed, three times over."

**Show (payoff):** the search results. Point at the top hits — on 2026-09-01 these were Nylas
free/busy, availability, and consecutive-availability endpoints, plus Google Calendar's `freeBusy`.

> "So that's the answer to 'what should I integrate with' — and I got it from one sentence, without
> opening a browser tab. Nylas was the name I'd been trying to remember."

**Do:** scroll to the `evaluateGuide` block on one of the results.

**Show (payoff):** the three-part guide, and specifically the last line.

> "Now the second thing. Every result comes with this. Summary, what to use it for — and then
> this line: **`Not supported: event creation, event details.`**
>
> That is the single highest-value line in the whole response. It just told me this endpoint answers
> 'is this clinician busy' and will never create the event. So I need a second endpoint, and I know
> that **now** — not from a 400 at four in the afternoon. 'What this endpoint won't do' is worth
> more than any amount of prose about what it will."

**Do:** paste the beat-2 prompt. Let the agent carry the IDs itself — **do not read IDs out or type
them.**

```text
Get the integration brief for the two best-fitting results. The task is: when a
patient books an appointment slot in a healthcare app, check the clinician's
calendar for conflicts before confirming.
```

> "And notice I didn't tell it to call `integrate`, and I didn't hand it any identifiers. It carried
> the `id` and the `resourceType` across on its own — because the tool description told it to. This
> is Act 2 happening in front of you."

**Show (payoff):** the returned `taskBrief`. Walk the headings in order — `FIT`, `AUTH`,
`BASE URL`, `STEPS`, `GOTCHAS`.

> "`FIT` first, and read it closely, because it does something I didn't expect. It says the two
> requests are **alternatives, not sequential steps** — pick one, don't call both. It looked for
> values passed between the calls, found none, and said so instead of inventing a chain. A brief
> that refuses to fabricate a dependency beats one that hands you plausible glue code — because
> plausible glue code is what I debug next week.
>
> `AUTH` and `BASE URL` are one line each, and both are things I'd otherwise have gone hunting for
> in a docs site. It even tells me honestly that the collection references a token variable and
> doesn't supply its value.
>
> `STEPS` is the bulk of it. Method, path, every parameter with where it goes and an example value,
> the JSON body shape, the success and error responses."

**Do:** scroll to `GOTCHAS`. Slow down — this is the payoff of the whole talk.

**Show (payoff):** the gotchas list.

> "And this is the third thing, and the reason I'm up here.
>
> **Use epoch seconds for the timestamps.** Nothing about a JSON booking payload suggests that, and
> ISO-8601 is the confident guess. That's a bug.
>
> **Fields can come back null** — including `busy`. Guess wrong on that one and you double-book a
> clinician.
>
> **Use an `Idempotency-Key` on the send call.** That header is the difference between a retry and
> a patient getting two confirmation emails.
>
> Three bugs. Every one of them is a thing I would have shipped and then heard about from a support
> ticket. They arrived before I opened an editor."

> **If the live call fails:** say "the catalog is live and it's having a moment" and read the same
> two artifacts from `.demo-state/search.json` and `.demo-state/integrate.json` — prompt 4 on the
> sheet hands them to Claude Code for you. If you would rather walk them yourself without an agent,
> open `.demo-state/search.txt` and `.demo-state/integrate.txt` instead: same content, plain text,
> the brief with real newlines ([§3c](#3c-the-cached-artifacts-and-which-copy-to-read)). Every beat
> above works from the cached files — the numbers and the gotchas are identical. Do not retry more
> than once on stage.

---

### Act 4: What that actually bought (1.5 min) — slide 4 (right), then 5

**Do:** switch back to slide 4 and point at the scoreboard on the right.

> "So let's be honest about what that bought, because I want to give you the real numbers and not a
> marketing slide. These were measured this morning, on this laptop."

**Show (payoff):** the table. Quote **today's** figures from `.demo-state/scoreboard.txt`. From the
2026-09-01 run:

| Same three capabilities | Orbit | Read the docs |
|---|---|---|
| Round trips | 2 calls | 4 pages, minimum |
| Bytes retrieved | 8,481 B | 1,232,233 B |
| Text into context | 8,447 chars | 89,765 chars |
| Tokens into context | ~2,413 | ~25,647 |
| Input cost, Claude Opus 5 at $5/1M | $0.0121 | $0.1282 |
| API limitations & gotchas — `epoch` / `start_time` / `Idempotency` | Stated up front in `GOTCHAS` | **0 hits in 1.23 MB** |

Measured but **deliberately not on the slide** (cut for legibility — keep it in your pocket, it is
one of the first questions you will get; see the note at the end of Act 4):

| | Orbit | Read the docs |
|---|---|---|
| Had to know the vendor first | No — that is the output | Assumed |

> "Two calls against four documentation pages. Eight and a half kilobytes against one and a quarter
> megabytes. Roughly two and a half thousand tokens into the context window against
> twenty-six thousand — ten times over. At Opus 5 input pricing that's a bit over a cent against
> about thirteen cents."

**Do:** point at the bottom row — **API limitations & gotchas** — and slow down. This is the row
that carries Act 4.

> "And then the row at the bottom, which is the one I actually care about. I grepped all
> one-and-a-quarter megabytes for the three things that would have broken my integration.
> `start_time`: zero hits. `Idempotency`: zero hits. `epoch`: zero hits. None of them are in there.
>
> That API reference page is rendered by JavaScript, so most of those bytes aren't endpoint schema
> at all. You can pull the whole megabyte and still not have the contract.
>
> So it isn't really ten times the tokens for the same answer. It's ten times the tokens for a
> **worse** answer — one that doesn't tell you the formats, the nullable field, or the retry
> semantics. Orbit stated all three up front, in `GOTCHAS`, before I opened an editor."

> **Two things to have ready, off-slide.** Both were on earlier versions of this slide and were cut
> for legibility — they are still true and they are still the first two questions you will get:
>
> - **"Isn't scraping faster?"** Don't take the bait, and don't quote a stopwatch — this talk
>   deliberately has no speed row. Two calls that return an evaluated brief with the gotchas in it
>   and four raw HTML downloads are not the same operation, so timing them against each other
>   compares nothing. And the deeper reason: those are *Nylas* pages, and you only know it's Nylas
>   because the search told you. The discovery problem — the whole premise of this talk — was
>   solved for free first.
> - **"What didn't you measure?"** An agent reading ~26k tokens and going back for more. There is no
>   number for that in the scoreboard. Don't invent one; say the download is the docs' best case.
>
> `.demo-state/scoreboard.txt` prints both of these under "THE HONEST CAVEATS" every time setup
> runs, so they are in front of you at the podium.

> "The author of the writeup this talk comes from puts the end-to-end saving at a week of provider
> comparison becoming an afternoon of writing a consumer. That's their reported experience, not
> something I measured — so take it as a story, not a benchmark. The ten-times token number and the
> three gotchas are the measured part."

**Do:** advance to slide 5 — the CTA.

> "One command, and this is on your machine."

**Show (payoff):** the `claude mcp add` line and the prompt template.

> "Then take a feature you've been putting off because you don't know what to integrate with, and
> describe it in one sentence. That's the whole prompt, it's on the slide.
>
> Two habits and I'll stop. Read `evaluateGuide` before you open a docs site — the 'not supported'
> line will eliminate half your candidates in a paragraph. And read `GOTCHAS` before you write the
> client, because that's where your production bugs are sitting, already written down.
>
> Try it, and then find me and tell me whether the brief caught something you'd have shipped. I'd
> genuinely like to know if my three were typical."

---

## 5. Tear down / reset

```bash
./scripts/teardown.sh
```

The script:

| Left behind | What teardown does |
|---|---|
| `.mcp.json` registering the Orbit MCP server for this folder | **Removed** — the server is no longer registered here |
| A global/user-scope `orbit` registration, if someone ran `claude mcp add` | **Warns only** — that's the presenter's own config. It prints `claude mcp remove orbit` and leaves the decision to you. |
| `.demo-state/docs/` — ~1.2 MB of downloaded documentation | **Removed** |
| `.demo-state/search.json`, `integrate.json`, their `.txt` renders, `raw/`, `scoreboard.txt` | **Kept** by default — this is Act 3's offline fallback |
| A running process, a cloud resource, an API key | **None exist.** Orbit needs no credential and this demo starts no servers, so there is nothing to stop or revoke. |
| An edited repo file | **None.** Act 3 happens entirely inside a Claude Code conversation. |

**Between attendees:** `./scripts/teardown.sh`, reset the deck to slide 1, and `/clear` the Claude
Code session so the search runs fresh rather than replaying from context.

### Full reset between sessions

```bash
./scripts/teardown.sh --purge   # also deletes the cached search, brief, and scoreboard
./scripts/setup.sh              # re-measures everything from scratch
```

Run the full reset **at the start of each demo day**, not the end — the scoreboard should be
measured on the day you say the numbers.

---

## 6. Troubleshooting

| Issue | Fix |
|---|---|
| `search` returns different endpoints than this README describes | Expected. The Orbit catalog is live. Present whatever came back — the three beats (translation, `evaluateGuide`, `GOTCHAS`) hold for any result. Never read a hardcoded endpoint ID. |
| `integrate` returns a 500 | Known and intermittent — one run in three failed on 2026-08-31; both runs on 2026-09-01 succeeded. Retry **once**. If it fails again, read the brief from `.demo-state/integrate.json` and move on. |
| `search` returns `total: 0` | Your query was over-specified. Shorten it toward the mechanism: "Find available free busy time slots before booking a meeting". Long, jargon-stacked queries return nothing. |
| Results come back from unrelated domains (school calendars, CRMs) | Your query was too generic. That is the Act 3 lesson — say it out loud and re-run with mechanism words. It reads as intentional. |
| No network at the venue | Acts 1, 2 and 4 are deck-only and unaffected. Read Act 3 from `.demo-state/search.json` and `integrate.json`, or their `.txt` renders if you are reading aloud yourself. Say plainly that you are reading a captured run. |
| Claude Code doesn't see the `orbit` tools | You are in the wrong folder, or the `.mcp.json` approval was never accepted. `cd` here, run `claude`, approve the prompt, then `/mcp` to confirm `search` and `integrate` are listed. |
| `/mcp` shows orbit but calls fail | The transport is HTTP, so it needs egress to `mcp.buildwithorbit.ai`. On a locked-down conference network, fall back to `.demo-state/`. |
| `setup.sh` says a docs page returned only a few hundred bytes | Nylas moved or blocked the page. The scoreboard drops it and reports the smaller page count — which makes the comparison *more* conservative, so just say the number the scoreboard prints. |
| Someone challenges the token or cost numbers | Say plainly that those two rows were measured **once, on 2026-09-01**, by a `chars / 3.5` estimate — the scoreboard prints exactly that under `FIXED`. They are the only figures not measured today. Offer to show the file. Never defend a number you can't point at. |
| Someone challenges the bytes, the character counts, or the 0-hits grep | Those *were* measured today, from the raw inputs still sitting in `.demo-state/`. Show them — and note the Orbit rows are measured from `.demo-state/raw/`, the untouched wire responses, not the indented copies you read from ([§3c](#3c-the-cached-artifacts-and-which-copy-to-read)). |
| The task brief is one unreadable line of escaped `\n` | You are looking at `.demo-state/raw/integrate.json`. Open `.demo-state/integrate.txt` instead. |
| Someone asks "but which one is faster?" | There is no speed number in this talk, by design — say so. Two evaluated API calls and four raw HTML downloads are different operations, so timing them against each other compares nothing. Move the question back to what the megabyte does *not* contain. |
| Someone says "so it's just cheaper?" | No, and don't claim it. The dollar delta is about eleven cents. The point is the three gotchas that appear in `GOTCHAS` and in none of the 1.23 MB. |
| Text too small from the floor | `Cmd+=` / `Cmd+-` in the browser; `Cmd+=` in the terminal. |
| Arrow keys don't move the deck | Click once on the slide to give the page focus. ArrowRight/Space = next, ArrowLeft = prev; the right half of the screen also advances. |

---

## 7. Additional resources

| Resource | Link |
|---|---|
| Orbit — docs and welcome | <https://www.buildwithorbit.ai/welcome> |
| Orbit usage guide | <https://www.buildwithorbit.ai/docs/get-started/usage-guide> |
| Orbit `search` endpoint reference | <https://www.buildwithorbit.ai/api-reference/search-public-endpoints> |
| Orbit `integrate` endpoint reference | <https://www.buildwithorbit.ai/api-reference/integrate-public-endpoints> |
| Orbit OpenAPI specification | <https://www.buildwithorbit.ai/openapi.json> |
| Orbit MCP server endpoint | `https://mcp.buildwithorbit.ai/mcp` |
| Launch post — Introducing Orbit | <https://blog.postman.com/introducing-orbit-turn-any-task-into-the-right-api-calls/> |
| **The article this talk is built from** | <https://blog.postman.com/how-ai-agents-discover-and-integrate-public-apis/> |
| Nylas v3 collection on the Postman API Network | <https://www.postman.com/trynylas/nylas-api/collection/fn1ujmb/v3-nylas-email-and-calendar-apis> |
| Nylas developer docs (the Act 4 "before" baseline) | <https://developer.nylas.com/docs/v3/getting-started/> |
| Claude Opus 5 pricing (Act 4 cost row) | <https://platform.claude.com/docs/en/pricing> |
