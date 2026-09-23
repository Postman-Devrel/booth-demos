# The Blast Radius You Can't Grep — Postman CLI and the API Context Graph

> [Lightning talk](../../../templates/formats/lightning-talk.md) — target length **10 minutes**. Delivered at booths, meetups, and lightning tracks. This README is the single source of truth. Read it top to bottom before your first attendee; everything you need to run the demo without improvising is here.

---

## 1. Product summary

- **Product:** Postman CLI + the [API Context Graph](https://www.postman.com/context-graph/)
- **Use case:** Show why a coding agent confidently green-lights a breaking API change, and how one Postman CLI command turns *"nothing in this repo reads it, safe to ship"* into a named blast radius with owning teams and evidence.
- **Audience:** Developers and platform engineers who let coding agents touch shared APIs, and who have shipped a change that passed every local test and still broke someone downstream.

**The story (the narrative arc):**

> You own `orders-api`. There is a field in the `GET /orders/{id}` response — `legacy_customer_ref` — that is written once by the serializer and never read again anywhere in the repository. It is marked deprecated in the spec. It has been dead weight for three years. You ask your coding agent who breaks if you remove it, and, restricted to this repository, it greps, finds no readers, and tells you it is safe to ship. **It is right about the search space it had and wrong about production.** Then you give it one more thing: the Postman CLI, pointed at your team's **API Context Graph** — one map of the estate, built from your Postman workspaces, your GitHub org, and your New Relic telemetry, refreshed nightly, with the evidence for every edge. You ask the *same* question. Three services call that endpoint. Two of them read that specific field — one keys the billing entity off it, one is a nightly CRM mirror that runs at 02:00 UTC. Three different teams own them. The agent writes `app/IMPACT.md`: do not ship yet, here is who to talk to, here is the migration path. The payoff is the change it told you **not** to ship.

> **Offline and network reality:** Act 1 is fully local. Act 3 needs the network and a Context Graph-enabled team. `setup.sh` runs the real ask ahead of time and caches the answer to `.demo-state/ask.txt`, so a dead venue network degrades Act 3 to "here is the answer the graph gave me this morning" rather than killing it. See [section 6](#6-troubleshooting).

**Call to action (for attendees):**

- `npm install -g postman-cli@latest`, then `postman context-graph ask "what depends on <your-api>?" --wait`
- API Context Graph: <https://www.postman.com/context-graph/>
- Postman CLI: <https://www.postman.com/product/postman-cli/>
- The launch post, with the benchmark: <https://blog.postman.com/introducing-the-context-graph-api-one-map-of-your-api-ecosystem/>
- Grab the demo: `git clone https://github.com/Postman-Devrel/booth-demos.git` → `cd booth-demos/content/lightning-talks/context-graph-blast-radius`

---

## 2. Pre-requisites

| Requirement | How to get it |
|---|---|
| **Postman CLI with `context-graph`** | `npm install -g postman-cli@latest`. Known-good: **1.62.0**. Older builds (1.43.0, for one) have no `context-graph` command *and still exit 0* when you call it — `setup.sh` probes the root help rather than trusting an exit code. Verify: `postman --help \| grep context-graph`. |
| **A signed-in Postman account** | `postman login`. Your credentials decide **which team's graph** you are querying. |
| **Context Graph enabled for that team** | **This is not a free-tier feature and it cannot be provisioned in the hallway.** Start at <https://www.postman.com/context-graph/>. Without it, Act 3 runs from the cached answer and you must say so on stage. |
| **The demo estate, seeded and ingested** | One-time, **at least a day before you present** — the graph refreshes nightly. Full procedure: [estate/README.md](estate/README.md). Summary: `ESTATE_ORG=<your-demo-org> ./estate/seed-estate.sh`, then connect that GitHub org and a Postman workspace holding [app/openapi.yaml](app/openapi.yaml) as Context Graph sources. |
| **Node.js 18+** | <https://nodejs.org/>. The provider repo uses built-in `fetch` and has zero dependencies. Verify: `node --version`. |
| **Claude Code** | <https://code.claude.com/docs>. Both prompts are written for it. Verify: `claude --version`. |
| **git** | Pre-installed on macOS/Linux. `teardown.sh` uses it to restore `app/` if the agent edited code. |
| **`gh` (optional)** | Only for the optional confirmation beat in Act 3 and for `seed-estate.sh`. <https://cli.github.com/> |
| **Network to the Postman API** | Act 3's live ask needs it. Act 1 does not. |

> **The honest constraint, up front.** Everything else in this repo runs from a cold laptop in ten minutes. This one does not: the Context Graph is team-gated and ingests on a nightly cycle. Treat the estate as standing infrastructure you set up once and reuse at every booth, not as session setup. [estate/README.md](estate/README.md) is where that lives, and `teardown.sh` deliberately leaves it alone.

---

## 3. Setup

Run the setup script from this demo folder:

```bash
./scripts/setup.sh              # probes the graph for real and caches the answer
./scripts/setup.sh --skip-ask   # rehearsal mode: reuse the cached answer, no live call
```

It checks and prepares:

1. **The deck** exists at `presentation/index.html` and is a complete HTML file.
2. **Tooling**: `node`, `claude`, `postman` are on the PATH, and prints the CLI version.
3. **The `context-graph` capability** — greps the CLI's root help for the command. Fails with the upgrade command if it is absent, because Act 3 cannot be improvised without it.
4. **Removes any stale `app/IMPACT.md`** from a previous run. The payoff has to appear live.
5. **Verifies the provider repo is intact** — `legacy_customer_ref` is still in the serializer. Fails with `git checkout -- app/` if not.
6. **Guards Act 1's premise** — the provider calls nothing, so setup warns if any outbound `fetch(` appears under `app/`. That is the signature of a consumer having leaked into the provider repo, which would make the Act 1 agent answer *correctly* and cost you the whole talk.
7. **Runs the real ask** (`postman context-graph ask "..." --wait --interval 5 --timeout 180 --json`), absorbing the 20–40s the graph takes to reason, and caches the raw response to `.demo-state/raw/ask.json`.
8. **Writes `.demo-state/ask.txt`** — the prose answer, extracted from the JSON envelope, ready to read on stage.
9. **Greps that answer for the three expected consumers** and prints `[found]` / `[MISSING]` for each. Anything `[MISSING]` must be dropped from your talk track — do not promise it.
10. **Writes `.demo-state/prompts.txt`** — both prompts, paste-ready. Nothing else is typed on stage.
11. **Opens the presentation** as the last step.

Exit codes from the ask are interpreted for you: **1** usually means not signed in or the graph is not enabled for your team, **2** means the ask reached a failed state, **4** means it timed out but is still running server-side (resume with `postman context-graph status <askId>`). In every non-zero case setup **warns rather than fails** and falls back to the previous cache, then tells you which act degrades.

### Authentication

`postman login`. That is the only credential. Your account determines which team's Context Graph answers, so if you have several, log in as the one whose graph has the seeded estate. No API key is needed interactively, though `--api-key` / `POSTMAN_API_KEY` works if you prefer it in CI.

### Pre-demo checklist

- [ ] `./scripts/setup.sh` finished with no `[FAIL]` lines
- [ ] You have **read `.demo-state/ask.txt`** and know what the graph said *today* — the wording changes between runs
- [ ] No `[MISSING]` service in setup's grep check (if there is one, drop it from the story)
- [ ] Terminal open in `./app` with `claude` running — **not** in the content folder (see the warning in Act 1)
- [ ] `app/src/serializers/order.js` open in the editor, `legacy_customer_ref` visible
- [ ] `.demo-state/prompts.txt` open in a pane you can copy from
- [ ] No `app/IMPACT.md` yet — it is the payoff and must appear live
- [ ] A second terminal pane free for the `postman context-graph ask` run
- [ ] Editor and terminal font readable from 6 feet (`Cmd+=`)
- [ ] Presentation open, fullscreen, on slide 1

---

## 4. Talk track and click track

Four acts, 10 minutes. Talk track is **verbatim** (blockquotes) — read it if the room goes cold. Click track is interleaved at the exact point each action happens. The live demo starts on **slide 4**.

> ⚠️ **Stay in `./app` for the whole demo.** The consumer repos are checked into `estate/repos/` so they can be seeded, and if you run the agent from the content folder it can grep them — Act 1's wrong answer becomes a right answer and the talk has no point. The agent's working directory is `./app` and nothing else.

### Act 1: The hook — the confident wrong answer (2 min)

> "Show of hands, figuratively: who has shipped a change that passed every test you had and still broke somebody two teams away? Right. Let me show you why your coding agent is about to do that for you, faster."

- **Show:** the editor on `app/src/serializers/order.js`, and a terminal in `./app` with `claude` running.
- **Do:** point at the field in the serializer.

> "This is `orders-api`. I own it. And this is `legacy_customer_ref` — added three years ago when we migrated customer IDs off the old CRM, kept for consumers that had not moved yet. It is written right here and never read again anywhere in this repository. It is marked deprecated in the spec. It is dead weight, and I would quite like to delete it."

- **Do:** paste the **Act 1 prompt** from `.demo-state/prompts.txt`:
  ```
  I want to remove the legacy_customer_ref field from the GET /orders/{id} response.
  Answer from this repository only: do not call any external tool, CLI, or network.
  Who breaks if I remove it? Give me a one-line verdict: safe or not safe to ship.
  ```
- **Show (payoff):** the agent greps, finds the single write and no reads, and returns its verdict — **safe to ship**. Leave it on screen.

> "And it is *right*. Given what it could see, that is the correct answer. It read every file it had. The problem is that a repository tells you what an endpoint *calls*. It never tells you who *calls it*. My consumers are in other repos, owned by other teams, deployed somewhere else entirely — and none of that is on this laptop. The agent didn't lack reasoning. It lacked the map."

- **Show:** advance the deck to **slide 2** (The Repo Is the Horizon).

### Act 2: The setup — one map of the estate (1.5 min)

> "So let's give it the map. The API Context Graph is one continuously updated graph of your API estate. It ingests three things you already have: your Postman workspaces — specs, collections; your GitHub org — the specs again, plus the actual call sites in source code; and your New Relic telemetry — what is really deployed and really calling what. It resolves all of that into one entity per service and refreshes nightly."

- **Show:** advance the deck to **slide 3** (One Map of the Estate).

> "The edges are typed — `exposes`, `calls`, `depends_on`, `backed_by`, `owned_by`, `monitored_by` — and this is the part I care about: every single edge carries its evidence. The commit SHA it came from, the source it came from, when it was last observed. So the answer is not an LLM's impression of my architecture. It is a claim with a receipt attached."

> "And the way I get at it is not an SDK and not an MCP server I have to stand up. It is one command in the Postman CLI. Watch."

### Act 3: The demo — the same question, with the estate in view (5.5 min)

**Beat 1 — ask the graph yourself (1.5 min, including the wait)**

- **Show:** the second terminal pane.
- **Do:** run the ask (the exact question `setup.sh` used is at the bottom of `.demo-state/prompts.txt`):
  ```bash
  postman context-graph ask "Which services call the GET /orders/{id} endpoint on orders-api, which teams own those services, and what evidence supports each dependency?" --wait --interval 5
  ```

> "This takes twenty to forty seconds, and I want to be honest about why: it is not a lookup. The graph is reasoning over the estate to answer that question. So while it works — this is the thing I could not do by hand in a sprint, let alone in thirty seconds. To answer this myself I would grep every repository in the org, guess which HTTP clients are ours, and then go and find out who owns each result."

- **Show (payoff):** the answer. Read out what it actually returned — **the named services, the owning teams, and the evidence**. Compare it against `.demo-state/ask.txt` if the live call is slower than you like.

> ⚠️ **Say what it said today, not what this README says.** The graph is live and its prose varies between runs. `setup.sh` already grepped this morning's answer for the three expected consumers and printed `[found]` / `[MISSING]`. Never promise a service the graph did not name.

**Beat 2 — hand it to the agent (2.5 min)**

- **Show:** back to the Claude Code pane in `./app` — the "safe to ship" verdict is still above it.
- **Do:** paste the **Act 3 prompt** from `.demo-state/prompts.txt`:
  ```
  Same question: who breaks if I remove legacy_customer_ref from GET /orders/{id}?
  This time you may use the Postman CLI to query our API Context Graph, which maps
  every service, endpoint, deployment and owning team across the estate:

    postman context-graph ask "<your question>" --wait --interval 5

  Then write app/IMPACT.md containing:
    - the verdict (ship / do not ship yet)
    - every service in the blast radius of the ENDPOINT, with its owning team
    - which of those are in the blast radius of the FIELD specifically
    - the evidence the graph gave you for each one
    - a recommended migration path
  Cite the graph as your source. Do not guess anything it did not tell you.
  ```
- **Show:** the agent runs the CLI itself, gets the estate back, and starts writing.

> "Notice what just happened to the agent's job. It did not read four hundred repositories. It asked one question, got three service names back, and now it knows exactly which corners of the estate matter. That is where the savings come from — the graph does not make the model smarter, it makes the search space smaller."

**Beat 3 — the payoff (1.5 min)**

- **Show (payoff):** open **`app/IMPACT.md`** in the editor. This is the artifact. Read the verdict line out loud.
- **Do:** walk three lines of it with your finger:
  1. the services in the **endpoint's** blast radius, with owning teams;
  2. which of them are in the **field's** blast radius — the narrower, more useful number;
  3. the **evidence** line for one of them.

> "Three services call the endpoint. Two of them read this specific field — and those are not the same number, which is exactly the distinction I could not make an hour ago. One of them keys the billing entity off it. One is a nightly job that runs at two in the morning, which is when I would have found out. And it tells me which three teams to talk to before I touch anything."

> "The agent's recommendation is: do not ship this yet. That is the best possible outcome of an agent run on a shared API — the change it tells you *not* to make."

- **Optional, droppable beat (needs `gh` and network):** confirm the graph's claim against GitHub with
  ```bash
  gh search code legacy_customer_ref --owner <your-demo-org>
  ```
  and show that the hits are exactly the services the graph named. Cut this first if you are over.

### Act 4: The close (1 min)

- **Show:** advance the deck to **slide 5** (Give Your Agent the Map).

> "Same model. Same prompt. Same repository. The only thing that changed was what it could see. Postman's own benchmark puts it at twenty-nine percent fewer prompt tokens and seventeen percent fewer tool calls per run when a model works with the graph instead of from code alone — and across four hundred and sixty-eight repositories they measured up to seventy-four percent fewer tokens and seventy-two percent lower cost. Those are Postman's published numbers, not something I measured up here."

> "One command. `postman context-graph ask`, the question you actually have, `--wait`. Point it at your own API and find out who you were about to break."

- **Do:** leave slide 5 up, with the command and the links on screen.

> **Number discipline.** Lead with **−29% prompt tokens / −17% tool calls per run** (the product page's typical figures) and use **up to −74% / −52% / −72% cost, accuracy gains on 18 of 21 prompt-model pairs** (the launch post, 468 repositories, three frontier models, eight cross-service questions) as the ceiling, always with the words "up to". Nothing in this demo measures anything. Never round up, and never let either figure sound like it came off this laptop.

### What to cut when you are over

In this order: the optional `gh` confirmation beat; then the architecture detail in Act 2 (keep the three sources and the evidence, drop the edge-type list); then Beat 1's narration down to a single sentence while the ask runs. **Never cut** the `IMPACT.md` payoff or the close.

### What survives a dead network

| Act | Offline? |
|---|---|
| 1 — the confident wrong answer | **Yes.** Fully local: the repo, the agent, the grep. |
| 2 — the setup | **Yes.** Deck only. |
| 3 — the live ask | **No.** Degrades to `.demo-state/ask.txt` — the answer `setup.sh` captured earlier. Say out loud that it is cached; do not narrate a live call that did not happen. |
| 3 — the agent writing `IMPACT.md` | **Partly.** Without the network the agent cannot run the CLI. Paste the contents of `.demo-state/ask.txt` into the prompt as the graph's answer and let it write `IMPACT.md` from that. |
| 4 — the close | **Yes.** Deck only. |

---

## 5. Tear down / reset

```bash
./scripts/teardown.sh
```

It removes `app/IMPACT.md`, restores `app/` with git if the agent edited any code, deletes `app/node_modules`, and removes `.demo-state/` (the cached graph answer and the prompts). It is safe to run when setup never ran.

**It deliberately leaves two things standing**, because they are shared infrastructure and rebuilding them costs a nightly refresh:

- the seeded GitHub estate and its Context Graph connection — see [estate/README.md](estate/README.md);
- your `postman login` session.

Full reset between sessions:

```bash
./scripts/teardown.sh && ./scripts/setup.sh
```

Manual steps, only if you are retiring the demo for good: delete the four seeded repositories from your demo org, and remove the GitHub org and Postman workspace as Context Graph sources.

---

## 6. Troubleshooting

| Issue | Fix |
|---|---|
| `setup.sh` fails: no `context-graph` command | `npm install -g postman-cli@latest` (known-good 1.62.0), then re-run setup. Do not try `postman context-graph` on the old CLI — it prints "Invalid command" and exits **0**, which is why setup greps the help text instead. |
| The ask exits **1** | Almost always auth: `postman login`. If you are logged in, the graph is probably not enabled for that team — check with the account that owns the seeded estate. |
| "Context Graph not enabled for your team" | It is not a free-tier feature and you cannot fix it on stage. Present Act 3 from `.demo-state/ask.txt` and say the answer was captured earlier. |
| The ask exits **4** (timeout) | It is still running server-side: `postman context-graph status <askId>`. Or just use the cached `.demo-state/ask.txt` and move on — do not make the room watch a spinner. |
| The graph answers, but names no consumers | The estate was never ingested, or was seeded today and has not refreshed. See [estate/README.md](estate/README.md). Nothing on stage fixes this; run the talk from a previous cache. |
| Setup printed `[MISSING] <service>` | Drop that service from your talk track and adjust the numbers you say. Say three-minus-one, not what this README says. |
| The Act 1 agent finds the consumers anyway | You are in the wrong working directory. Quit the agent, `cd app`, restart it. It can grep `estate/repos/` from the content folder. |
| The agent refuses to run the CLI in Act 3 | Run the ask yourself in the second pane, then paste its output into the chat as the graph's answer. The story is unaffected. |
| The live ask is taking too long on stage | Switch to the pane with `.demo-state/ask.txt`, say "here is the same answer from this morning", and keep the pace. Never wait in silence. |
| `app/IMPACT.md` already exists at the start | `./scripts/setup.sh` removes it. If you skipped setup: `rm app/IMPACT.md`. |
| The agent edited the serializer | Fine, nothing shipped — `teardown.sh` restores `app/` from git. |
| The deck does not open | Open `presentation/index.html` by hand. It is self-contained; only the fonts need the network. |

---

## 7. Additional resources

| Resource | Link |
|---|---|
| API Context Graph | <https://www.postman.com/context-graph/> |
| Postman CLI | <https://www.postman.com/product/postman-cli/> |
| Postman CLI command reference | <https://learning.postman.com/docs/postman-cli/postman-cli-options> |
| Postman CLI installation | <https://learning.postman.com/docs/postman-cli/postman-cli-installation/> |
| Launch post — "Introducing the Context Graph API: One Map of Your API Ecosystem" | <https://blog.postman.com/introducing-the-context-graph-api-one-map-of-your-api-ecosystem/> |
| The demo estate and how to seed it | [estate/README.md](estate/README.md) |
| Same product, different claim — the CLI as a test oracle | [../open-meteo-loop-eng/](../open-meteo-loop-eng/) |
