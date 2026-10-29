# Context Graph

A 10-minute booth demo. One claim: **you cannot grep what was never in the checkout**, and a Context Graph query is how a model gets at the rest. You put eight real questions on screen, let the audience pick one, and show all three models answering it with and without the graph, using the numbers from the benchmark.

Everything below is written the way I'd walk a colleague through it, because that's the audience: engineers who already use coding agents and have felt the "it only knows the repos in front of it" problem.

> **Deck note.** The lightning-talk format says five slides. This one has seven, because we added "Where the Context Graph earns its place" and the `api-discovery` skill slide ahead of the CTA. It's deliberate. If you ever need to cut back to five, drop slide 3 (the overview table; slide 4 shows the same numbers one question at a time) and slide 6 (the skill).

---

## 1. Product summary

**What it is.** The Postman Context Graph is a graph of your software estate: APIs, endpoints, services, external systems, schemas, telemetry. It's built from your connected data and refreshed nightly. You ask it a natural-language question and get graph rows back, plus a prose answer if you want one. In Claude Code you reach it through the Postman plugin's `submitContextGraphAsk` and `getContextGraphAsk` tools.

**Why it matters.** An agent searching a checkout is a very good librarian walking the shelves. It's fast, but it can only find books that are on the shelves. The graph is the library catalog. It points at books in other branches, at things with no shelf at all (an external system called at runtime), and at chapters buried inside a book with an unrelated title.

**The number to remember.** Ask "which services expose HTTP endpoints?" against the benchmark estate:

| | Services |
|---|---|
| Found by searching the checkout | 129 |
| Returned by the graph | 498 |

Of the 498: 129 are in the checkout, 221 are repos elsewhere in the estate, 140 have no standalone repo, and 8 are components inside repos the agent had already searched. That's 369 services no amount of better searching would find.

**The result to remember.** Same three models, same questions, same code, same pinned commit. The only variable is whether the model starts with one graph query. Accuracy went up in **18 of 21** prompt-model pairs. Opus ran 27% cheaper, Astra 20% cheaper.

**The honest version.** It helps when the answer is a *relationship* between things (runtime calls, callers, upstream dependencies). If the answer is already written in a file, the model is often better off just reading the file. Three of the 21 pairs got worse and the deck shows them in red. Don't hide that. It's the most credible thing on the slide.

**Look and feel.** The deck follows the Postman Deck Template (dark theme): Inter titles with orange accent words, orange mono kickers, hairline rows, dark cards with coloured top bars, the Postman mark top right and the rainbow strip along the bottom. The title and closing slides use a CSS version of the template's arc glow, not the original artwork. If you need the exact template artwork, rebuild those two slides in Google Slides from the "Cover" layouts.

Source for every number: `ai-harness/docs/context_graph_api_benchmarking_report.md` (the "benchmark report" below).

---

## 2. Pre-requisites

- **A browser.** The deck is one self-contained HTML file. Only the fonts come from Google, and they degrade to system fonts offline.
- That's it for the main demo. It runs entirely from preloaded results: no network, no login, nothing created in Postman.
- **Optional, only for the bonus live ask in act 3:** Claude Code with the Postman plugin (`claude plugin install github:Postman-Devrel/postman-claude-code-plugin`), signed in to the team that owns the benchmark estate, with Context Graph enabled.

> **Why the demo is preloaded and not live.** The ask tools take no workspace or team parameter. The team is whichever account the plugin is signed in as, and nothing in the tool call tells you which. When I built this, I ran the harness queries through the plugin as signed in on this machine and got a completely different estate back: ~790 services (sentry, snuba, airflow and so on) and **none** of the benchmark estate. Asked who calls the platform's HTTP API, the graph said, politely, that it couldn't find a match. So: results come from the saved benchmark run, and the plugin is the "now go try it on yours" step. If you do the bonus live ask, make sure you're on the right team first (quick tell: the callers query should name an MCP server and a Terraform provider).

---

## 3. Setup

```bash
./scripts/setup.sh
```

What it does, in order:

1. Checks `presentation/index.html` exists (fails if not).
2. Checks the preloaded results in `fixtures/` are there (warns if not; the deck has the numbers baked in either way).
3. Notes whether Claude Code and the Postman plugin are installed. Warns, never fails: you only need them for the bonus ask.
4. Opens the deck.

### Pre-demo checklist

- [ ] Deck full-screen on the booth monitor, slide 1
- [ ] Browser zoom at 100% so slide 4 fits. Click a question once to test, then reload.
- [ ] Keyboard within reach: **1 to 8** picks a question on slide 4, **left/right arrows** move between slides
- [ ] (Optional) Claude Code open with the plugin, signed in to the right team

### How the deck works

| # | Slide | What's on it |
|---|---|---|
| 1 | Context Graph | Title |
| 2 | Which services expose HTTP endpoints? | 129 vs 498 bar, the A/B/C/D breakdown, the 6,712-node composition |
| 3 | Same models. One graph query. | 18/21, -27%, -20%, and accuracy for every question x model, alone then with graph |
| 4 | Ask the graph | The 8 questions. Pick one: the scenario behind it, the graph query, then Opus / Sonnet / Astra with and without the graph (correct found, accuracy, cost per run, tool calls) |
| 5 | Where the Context Graph earns its place | The benchmark's summary and the one rule to leave with |
| 6 | The `api-discovery` skill | How the Postman plugin picks a source by the question (Orbit, search Postman, or the Context Graph), plus a Claude Code transcript of the `postman:api-discovery` skill being invoked and calling `submitContextGraphAsk` then `getContextGraphAsk`, and the "then verify" caveats |
| 7 | Ask your own estate | Install command |

On slide 4, nothing is selected when you arrive. That's on purpose: it's a list the audience reads, and you go where they point. Selecting **6 (API callers)** also draws the graph the query returned: the platform's HTTP API at the centre, the services the graph linked to it around the edge.

### The eight questions

These are the benchmark prompts exactly as the models received them. Each also has its own graph query (shown on the slide, verbatim from `ai-harness/src/evals/model-benchmark.ts`). Don't reword them: rewording changes what the graph returns. The telemetry query returned 11 rows until it was rewritten as a relationship question, and then it returned 200+.

1. What are the runtime dependencies between services?
2. List each service and the logs, metrics, and traces it produces.
3. Which services do we actually deploy, and how is each one deployed?
4. Which services serve HTTP endpoints, and what paths does each one serve?
5. Which services consume from a message bus, and which topics do they read?
6. Which services call the platform's HTTP API?
7. Which services declare a machine-readable data or API contract, and what does each contract describe?
8. What does each service depend on at run time?

Every question on the slide also carries the scenario paragraph from the benchmark report ("Let's say you are responding to an incident…"), so the audience knows why anyone would ask it.

---

## 4. Talk track and click track

Total: **10:00**. Hook 1:30, Setup 1:00, Demo 5:00, Close 2:30.

### Act 1: Hook (1:30)

#### Talk track

> "Quick question. Your agent has your services checked out. You ask it 'which services expose HTTP endpoints?' and it goes off and greps, and it's good at it. It comes back with a confident list. How many services did it miss?
>
> Here's a real answer from a real estate. The estate: 468 repos declared, and the agent can see 129 of them. Ask the Context Graph the same question and you get 498. That's not the agent searching badly. Those 369 other services aren't on the disk. You cannot grep what was never in the checkout."

#### Click track

- **Show:** slide 1 for one beat, then slide 2.
- **Show (payoff):** the two bars on slide 2, 129 against 498, and the line "369 services the agent could never grep."
- **Do:** point at the chips along the bottom (6,712 nodes, 4,828 endpoints, 1,424 APIs and services, 309 external systems). That's what the catalog is made of.

### Act 2: Setup (1:00)

#### Talk track

> "So the question I actually care about is: does that catalog make a model *better*, or does it just make the answer longer? We tested it. Three frontier models, Opus, Sonnet and GPT-6 Astra. Eight questions an engineer really asks before changing something. Each one asked twice: model alone, and model plus one graph query. Same tools, same code at the same commit. The baseline isn't even told the graph exists.
>
> And it's graded against an answer key built with grep from the code, never from the graph. Grading the graph against its own output would be marking its own homework."

#### Click track

- **Show:** slide 3.
- **Do:** trace one row with your finger, then land on the strip at the top: 18 of 21, minus 27%, minus 20%.
- **Show (payoff):** the red cells. Say it out loud before anyone else spots them: "three of those went the wrong way, and I'll show you which and why."

### Act 3: The demo (5:00)

You're not driving this. The audience is.

#### Talk track

> "Here are the eight questions. Pick one."

Then take whichever they pick. If nobody does, run these three in order (about 1:45 each):

**Question 4: HTTP endpoints. The one from the hook.**

> "This is the endpoint question again. Read the scenario: you're about to require auth on every endpoint, and if you miss one it stays open while everyone believes the rollout is done. Sonnet alone found 7 of the real services. With the graph, 27. Opus went from 37 dollars a run to 10, with half the tool calls, because it stops walking every shelf. And look at Astra: red. It was already finding more than 90% on its own, and the graph pulled its attention toward services that don't serve endpoints. If the answer's in a file, read the file."

- **Do:** press **4**.
- **Show (payoff):** the cost line for Opus ($37 → $10) and the note: 48 services with no repo in the checkout, 47 straight from the graph query.

**Question 6: API callers. The graph.**

> "This is the one that scares me on a release: I'm changing the platform API, who calls it? That's the graph the query returned: the platform's HTTP API in the middle, twelve services around it. An MCP server, a Terraform provider, a crossplane provider, an Ansible collection, `irm-tooling`. None of that is text you can grep for, because these are relationships. Opus found 12 of the 13 real callers with the graph and 9 without, and returned 30 services instead of 54. It wasn't just finding more. It was guessing less."

- **Do:** press **6**.
- **Show (payoff):** the graph under the model cards. Pick two names the crowd will recognise.
- **If asked about the extra three:** the graph returned 12 documents. Nine of them are in the answer key of 13 real callers. `act-kit`, `amixr-api-go-client` and `developer-advocacy` aren't. The "12 of 13" is how many of the *real* callers Opus named in its final answer. Different things, both true.

**Question 5: Message-bus consumers. The honest one.**

> "And here's where it doesn't help. Which services consume from a message bus? Opus gets a bit better, Sonnet's flat, Astra gets worse. The reason is the index: it has links from services to 13 messaging systems, but no topic nodes and no subscribe or publish edges. It can tell you a service talks to Kafka. It can't tell you it *consumes* from it, and that's exactly the question."

- **Do:** press **5**.
- **Show (payoff):** Astra's accuracy in red, 0.719 → 0.576.

#### Optional: one live ask (only if the plugin is on the right team and you have a spare 2 to 7 minutes)

- **Do:** in Claude Code, paste: `Use submitContextGraphAsk with includeAnswer=true for exactly this query, then poll getContextGraphAsk until it completes: "Which services call the platform's HTTP API, and what are their upstream and downstream dependencies?"`
- Asks took roughly 40 seconds to 7 minutes in the benchmark. Fire it at the start of act 3 and come back to it, or skip it. It's the most droppable beat. Don't present a live count as a benchmark number: the graph refreshes nightly and the plugin uses a different client than the harness did.

### Act 4: Close (2:30)

#### Talk track

> "So where does it earn its place? When the answer is a relationship, not text in a file. Runtime calls, callers, services with no repo in your checkout. If the answer's already written in a repository, just read the files. If it lives between repositories, services and systems, that's where the graph pays for itself. And for two of the three models it made these questions cheaper, too.
>
> A better model is a faster, more experienced librarian. It still can't find a book that isn't on the shelf. The graph is the catalog. Install the plugin and ask it about your own estate. One caveat for free: it refreshes nightly, so it's as fresh as your last ingest, not your last commit."

#### Click track

- **Show:** slide 5.
- **Show (payoff):** the two boxes at the bottom: "Answer already written in a repository? Simply read the files." / "Answer lives between repositories, services and systems? That is where the Context Graph earns its place."
- **Show:** slide 6, the `api-discovery` skill.

  > "And here's how you'd actually use it. The Postman plugin ships an `api-discovery` skill, and it picks the source by the question. Looking for a public provider's endpoints: Orbit. Looking for a specific collection, spec or mock: it searches Postman. Asking who consumes this endpoint, who owns it, what a change will hit: that's the Context Graph. Watch the right-hand side: I ask a plain question in Claude Code, the `postman:api-discovery` skill fires, and it calls the plugin's `submitContextGraphAsk` tool and then polls `getContextGraphAsk` until the answer is ready. It connects Postman definitions, repository call sites and runtime telemetry, beyond the checkout.
  >
  > Two honesty points straight from the skill. Coverage depends on what's connected and ingested, so verify anything consequential against source or telemetry. And the team comes from your API key, not your repo's workspace binding. If you're pointed at the wrong organization, changing the binding won't fix it."

- **Show (payoff):** the highlighted "Context Graph" row and the Claude Code transcript: the question, the `Skill(postman:api-discovery)` call, then the two MCP tool calls. The transcript shows the calls the plugin makes, not live output, so don't present it as a captured run.
- **Show:** slide 7, the install command. Let people photograph it.

### What to cut when you're over

The optional live ask first. Then question 5 in act 3. Then slide 6 (the skill; fold one sentence of it into the install slide) and slide 3 (the overview table duplicates slide 4). Never cut the 129-versus-498 bars, a question that shows the graph (6), or the "earns its place" slide.

---

## 5. Tear down / reset

```bash
./scripts/teardown.sh
```

There's nothing to undo. The demo writes no files and creates no workspaces, collections, mocks or monitors, and `teardown.sh` just says so. Reload the deck to clear the slide 4 selection.

---

## 6. Troubleshooting

| Symptom | Likely cause | What to do |
|---|---|---|
| Slide 4 shows nothing on the right | Nothing selected yet | Click a question or press 1 to 8. That's the intended starting state. |
| Number keys don't work | Not on slide 4, or focus is in another window | Click the browser window, go to slide 4. |
| Slide 4 is cut off | Browser zoom above 100%, or a short window | Reset zoom (Cmd+0) and go full-screen. |
| Deck fonts look off | Google Fonts blocked | Cosmetic. They fall back to system fonts. |
| The optional live ask says nothing matches, or returns sentry/snuba/airflow | Plugin signed in to a different team | Sign in to the right team, or skip the live ask. This is what I hit while building the demo. |
| Live ask errors that Context Graph isn't enabled | Team doesn't have the feature | Skip the live ask. The demo doesn't need it. |
| Live ask 429s | Quota or burst limit | Wait. Each ask counts against the team's quota, so don't retry in a loop. |
| Booth wifi is down | Doesn't matter | The demo is fully offline. |

### Things I'd want you to know before someone asks

- **"Is that one run?"** No. "The latest benchmark run" in ai-harness is a composite: the report is built from 13 runs between 2026-09-18 and 2026-09-19, each the latest 3-epoch run for its case and model. The newest single run is `2026-09-19T01-47-03-061Z__model-benchmark` (the event-consumers re-run).
- **"Did you re-run the queries for this demo?"** No. Every number is the benchmark's, parsed straight out of the report's scorecard blocks into `fixtures/benchmark.json`, nothing recomputed. The three graph document counts and the twelve caller names come from saved harness cells.
- **"498 or 456?"** The report's diagram says 498 services; its HTTP-endpoints prose says the graph returned 456 results. The deck uses 498, the number in the diagram and the 129/221/140/8 breakdown. Don't defend it as a precise count of the estate's services: an ai-harness commit (`9f49449`) found roughly 22% of the off-checkout names belonged to another corpus (Sentry). The slide has a footnote saying so, which is why the deck shows the count and not the list (`fixtures/http-endpoints.json` keeps the count only).
- **"Why do three cells go red?"** Astra on HTTP endpoints (already high alone), and Sonnet and Astra on message-bus consumers (the index has no topic or subscribe/publish edges). Also: cost went *up* for Sonnet on several questions. The headline cost wins are Opus and Astra.
- **"Does the live path match the benchmark?"** Not exactly. The harness calls the REST endpoint (`POST /context-graph/asks`); the plugin goes through MCP tools. Same graph, different client, so don't promise identical rows.
- **"What counts as 'correct'?"** An answer key built by grep from the checked-out code at a pinned commit. Never from the graph. Plus a check that every cited file path exists, plus an anonymised LLM judge from a different model family with the lowest weight.

---

## 7. Additional resources

- **Benchmark report:** `ai-harness/docs/context_graph_api_benchmarking_report.md`
- **Runs behind the report** (all under `ai-harness/runs/`, each `<id>__model-benchmark`): `2026-09-18T17-12-26-989Z` (Opus baseline and graph arm, original prompts), `2026-09-18T18-15-10-593Z` (Sonnet baseline), `2026-09-18T18-29-15-512Z` (Astra), `2026-09-18T20-37-07-040Z` (Sonnet graph arm), `2026-09-18T23-36-07-677Z`, `23-42-41-945Z`, `23-47-42-024Z` (upstream dependencies), `2026-09-19T00-47-55-004Z`, `00-54-11-288Z`, `00-59-38-699Z` (telemetry re-run), `2026-09-19T01-32-50-520Z`, `01-40-42-801Z`, `01-47-03-061Z` (event-consumers re-run)
- **Where the graph queries live:** `ai-harness/README.md` and `ai-harness/src/evals/model-benchmark.ts`
- **Preloaded data in `fixtures/`:**
  - `benchmark.json`: the report's scorecards for all 8 questions x 3 models, plus each question's scenario text, graph query and one-line takeaway. Slides 3 and 4 are built from this.
  - `api-callers.json`: run `2026-09-18T17-12-26-989Z`, Opus 4.7 + graph, epoch 0, 12 documents. The caller graph on slide 4.
  - `http-endpoints.json`: same run, epoch 2, 498 documents
  - `upstream-dependencies.json`: run `2026-09-18T23-36-07-677Z`, epoch 0, 193 documents
- **Answer keys** (grep-derived, never from the graph): the callers, graph and upstream key files in `ai-harness/src/evals/`
- **The skill on slide 6:** `postmanlabs/postman-plugin`, `skills/api-discovery/SKILL.md` (step 4 is the Context Graph part). Plugin tools: `submitContextGraphAsk` and `getContextGraphAsk`.
- **Install the plugin:** `claude plugin install github:Postman-Devrel/postman-claude-code-plugin`
