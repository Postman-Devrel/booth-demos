# The Check Your CI Is Missing — the Postman CLI as a Blast-Radius Gate

> [Lightning talk](../../../templates/formats/lightning-talk.md) — target length **10 minutes**. Delivered at booths, meetups, and lightning tracks. This README is the single source of truth. Read it top to bottom before your first attendee; everything you need to run the demo without improvising is here.

---

## 1. Product summary

- **Product:** [Postman CLI](https://www.postman.com/product/postman-cli/), with the [API Context Graph](https://www.postman.com/context-graph/) behind it
- **Use case:** Show that a pipeline can only fail on what it can see, and that the Postman CLI is what lets it see past the repository — one binary that runs a blast-radius check in CI, in your terminal, and in your coding agent's shell.
- **Audience:** Developers and platform engineers who own an API other teams consume, and who run tests in CI.

**The chain, in one line:**

> **the agent orchestrates and corrects · the Postman CLI is the connector · the Context Graph is the awareness that does not fit in a repo**

**The story (the narrative arc):**

> You own `orders-api`. You have removed `legacy_customer_ref` from the `GET /orders/{id}` response — deprecated three years ago, written once by the serializer, never read anywhere in this repository. `npm test` is green, and it is *honestly* green: nobody writes a test for a field their own service never reads. Your coding agent, asked from inside the repo, tells you it is safe to merge. Everything you own agrees with you, and every one of them is answering the same narrow question: *is `orders-api` still correct against itself?* **Nobody is checking whether anyone else is still correct against you** — and you cannot check it from in here, because your consumers are not on this laptop. What you can do is run one command. `postman context-graph ask`, through the **Postman CLI**: the same binary, the same exit-code contract, wherever you run it. Which means the check has a *time*, not a place — and the cheapest time is before the push. So you tell the agent to run it first. It comes back **exit 1**: three services call that endpoint, two of them read that field, three different teams own them. The agent asks the graph for the detail, puts the field back on a dated sunset, writes `IMPACT.md` naming every consumer with the graph's evidence, and re-runs until the check is green — all before a commit exists. The same command is the second job in the pipeline, so if the agent had skipped it, the merge would have been blocked anyway. The payoff is a change that got corrected at the cheapest possible moment, by an agent that could finally see who it was about to hurt.

> **Offline and network reality:** Act 1 is fully local. Act 3 needs the network and a Context Graph-enabled team. `setup.sh` runs the real gate ahead of time and caches the graph's answer to `.demo-state/ask.txt`, and the gate takes `BLAST_RADIUS_ANSWER_FILE` so a dead venue network degrades Act 3 to a cached answer rather than killing it. See [section 6](#6-troubleshooting).

**Call to action (for attendees):**

- `npm install -g postman-cli@latest`, then `postman context-graph ask "what depends on <your-api>?" --wait`
- Postman CLI: <https://www.postman.com/product/postman-cli/>
- API Context Graph: <https://www.postman.com/context-graph/>
- The launch post, with the benchmark: <https://blog.postman.com/introducing-the-context-graph-api-one-map-of-your-api-ecosystem/>
- Grab the demo, gate included: `git clone https://github.com/Postman-Devrel/booth-demos.git` → `cd booth-demos/content/lightning-talks/postman-cli-blast-radius-gate`

> ⚠️ **Say this out loud in Act 2: the gate is ours, not a Postman feature.** `postman context-graph ask` is a Postman command. [`app/ci/blast-radius-check.sh`](app/ci/blast-radius-check.sh) is about a hundred and fifty lines of shell that this repo wrote on top of it. Never let an attendee leave thinking Postman ships a blast-radius gate — they will go looking for it and not find it. The honest framing is stronger anyway: *the CLI gives you the answer and an exit code; what blocks a merge is your policy, and it is small.*

---

## 2. Pre-requisites

| Requirement | How to get it |
|---|---|
| **Postman CLI with `context-graph`** | `npm install -g postman-cli@latest`. Known-good: **1.62.0**. Older builds (1.43.0, for one) have no `context-graph` command *and still exit 0* when you call it — `setup.sh` and the gate both probe the root help rather than trusting an exit code. Verify: `postman --help \| grep context-graph`. |
| **A signed-in Postman account** | `postman login`. Your credentials decide **which team's graph** you are querying. In CI it is `POSTMAN_API_KEY`. |
| **Context Graph enabled for that team** | **Not a free-tier feature, and not provisionable in the hallway.** Start at <https://www.postman.com/context-graph/>. Without it the gate exits 2 and you present Act 3 from the cached answer, saying so. |
| **The demo estate, seeded and ingested** | One-time, **at least a day before you present** — the graph refreshes nightly. Full procedure: [estate/README.md](estate/README.md). Summary: `ESTATE_ORG=<your-demo-org> ./estate/seed-estate.sh`, then connect that GitHub org and a Postman workspace holding [app/openapi.yaml](app/openapi.yaml) as Context Graph sources. |
| **Node.js 18+** | <https://nodejs.org/>. The provider repo has zero dependencies; the tests are `node --test`. Verify: `node --version`. |
| **Claude Code** | <https://code.claude.com/docs>. Both prompts are written for it, and Act 3 needs it to be able to run shell commands. Verify: `claude --version`. |
| **git** | The gate diffs the published contract with it. Without a work tree the gate skips and there is no demo. |
| **python3** | Used to read the prose answer out of the CLI's JSON envelope. Without it the gate prints raw JSON — survivable, ugly on a booth monitor. |
| **`gh` (optional)** | Only for `seed-estate.sh`. <https://cli.github.com/> |

> **The honest constraint, up front.** Everything else in this repo runs from a cold laptop in ten minutes. This one does not: the Context Graph is team-gated and ingests on a nightly cycle. Treat the estate as standing infrastructure you set up once and reuse at every booth, not as session setup. `teardown.sh` deliberately leaves it alone.

---

## 3. Setup

```bash
./scripts/setup.sh              # rehearses the real gate against the live graph
./scripts/setup.sh --skip-ask   # rehearsal from the cached answer, no live call
```

Setup does not just validate — it **puts the machine into the starting state and proves it**, by running the same gate the demo runs:

1. **The deck** exists and is a complete HTML file.
2. **Tooling**: `node`, `claude`, `postman`, `git`, and `python3` (warn only).
3. **The `context-graph` capability** — greps the CLI's root help. Fails with the upgrade command if absent.
4. **The gate** exists and is executable at `app/ci/blast-radius-check.sh`.
5. **Removes any stale `app/IMPACT.md`** — the agent writes it live.
6. **Restores `app/` from git, then applies the breaking change** from `scripts/breaking-change/` (the field removed from the serializer *and* the spec, version bumped). Fails if the field is still in the spec afterwards.
7. **Guards Act 1's premise** — warns on any outbound `fetch(` under `app/`, the signature of a consumer having leaked into the provider repo.
8. **Runs `npm test` and requires it to be GREEN.** A red suite means the change broke `orders-api` against its own spec, which is a different talk — setup fails loudly.
9. **Runs the gate for real**, absorbing the 20–40s the graph takes to reason, saving the answer to `.demo-state/ask.txt` and the full output to `.demo-state/gate-red.txt`. **It requires exit 1.** Exit 0 means the demo has no red to go green from, and setup tells you the three likely causes.
10. **Checks what the graph actually named today** — `[found]` / `[MISSING]` per expected consumer, plus whether the answer carries the parsable `SERVICES:` line the gate branches on.
11. **Writes `.demo-state/prompts.txt`** — both prompts, paste-ready.
12. **Opens the presentation.**

### The gate's exit codes

The gate borrows the CLI's own contract, and that is the point of Act 2:

| Exit | Meaning |
|---|---|
| **0** | No fields removed from the contract, **or** every consumer the graph named is acknowledged in `IMPACT.md` |
| **1** | **BLOCKED** — a field was removed and consumers of it are not acknowledged |
| **2** | **INDETERMINATE** — the graph could not be reached, or its answer could not be parsed. `BLAST_RADIUS_ON_ERROR=pass` fails open; the default fails closed |

Environment switches worth knowing on stage: `BLAST_RADIUS_ANSWER_FILE=<path>` reads a cached answer instead of calling the CLI (**the offline switch — a real pipeline never sets it**), and `BLAST_RADIUS_SAVE_ANSWER=<path>` writes the answer out, which is how setup builds that cache.

### Authentication

`postman login`. That is the only credential, and your account decides which team's graph answers — if you have several, log in as the one whose graph has the seeded estate. In the pipeline it is `POSTMAN_API_KEY` as a secret; see [app/.github/workflows/blast-radius.yml](app/.github/workflows/blast-radius.yml), which fails open when the secret is absent so a fork's PR is not blocked on something it cannot check.

### Pre-demo checklist

- [ ] `./scripts/setup.sh` finished with no `[FAIL]` lines, and reported **the gate is RED (exit 1)**
- [ ] You have **read `.demo-state/ask.txt`** and know what the graph said *today*
- [ ] No `[MISSING]` service in setup's check (if there is one, drop it from the story and adjust the numbers you say)
- [ ] Terminal in `./app` with `claude` running — **not** in the content folder (see the warning below)
- [ ] `git diff app/` ready in a pane — that is the change under review
- [ ] A second terminal pane in `./app` — **not** for you to run the check (the agent does that), only for the fallbacks in section 6
- [ ] `.demo-state/prompts.txt` open in a pane you can copy from
- [ ] No `app/IMPACT.md` yet — the agent writes it live
- [ ] Editor and terminal font readable from 6 feet (`Cmd+=`)
- [ ] Presentation open, fullscreen, on slide 1

---

## 4. Talk track and click track

Four acts, 10 minutes. Talk track is **verbatim** (blockquotes) — read it if the room goes cold. Click track is interleaved at the exact point each action happens. The live demo starts on **slide 4**.

> ⚠️ **Stay in `./app` for the whole demo.** The consumer repos are checked into `estate/repos/` so they can be seeded, and if you run the agent from the content folder it can grep them — Act 1's wrong answer becomes a right answer and the talk has no point. The agent's working directory is `./app` and nothing else.

> ⚠️ **One mechanism, one actor.** The pipeline and the agent are **not two stories** — they are the same command at two different times, and the whole talk turns on that. You never run the check yourself: the agent runs it, in Act 3, once. The pipeline appears twice, for fifteen seconds each time: as the reason the check exists (Act 2) and as the backstop (Act 4). If you find yourself demoing CI *and* the agent, you have split the talk in half and the audience is now holding two ideas.

### Act 1: The hook — everything I own says yes (2 min)

> "Who here has merged something that passed every check you had, and still broke somebody two teams away? Right. Let me show you why your pipeline let you."

- **Show:** the editor on `app/src/serializers/order.js`, and `git diff app/` in a terminal pane.
- **Do:** walk the diff — the field is gone from the serializer and from `openapi.yaml`.

> "This is `orders-api`. I own it. I have just removed `legacy_customer_ref` — added three years ago when we migrated customer IDs off the old CRM, kept for consumers who had not moved yet, marked deprecated in the spec, written once right here and never read again anywhere in this repository. Dead weight. And here is my pipeline's opinion."

- **Do:** run the suite:
  ```bash
  npm test
  ```
- **Show (payoff):** **3 passing.** Green.

> "Green. And it is *honestly* green — look at what the tests assert. They assert the fields this service promises in its own spec. Nobody writes a test for a field their own service never reads, so there is nothing here to go red. My tests point inward. Let me ask the agent too."

- **Do:** paste the **Act 1 prompt** from `.demo-state/prompts.txt`:
  ```
  I removed the deprecated legacy_customer_ref field from the GET /orders/{id}
  response, in the serializer and in the spec. The test suite passes.
  Answer from this repository only: do not call any external tool, CLI, or network.
  Is this safe to merge? Give me a one-line verdict.
  ```
- **Show (payoff):** the agent greps, finds no readers, and says **safe to merge**. Leave it on screen.

> "So: tests green, spec updated, agent agrees. Everything I own says yes — and every one of them is answering the same narrow question. *Is `orders-api` still correct against itself?* Nobody here is asking whether anyone **else** is still correct against me. And I cannot ask it from in here: my consumers are in other repos, owned by other teams, deployed somewhere else. A pipeline can only fail on what it can see."

- **Show:** advance the deck to **slide 2** (A Pipeline Can Only Fail on What It Sees).

### Act 2: The one idea — it is a command, so run it early (1.5 min)

> "So there is a check missing, and I know exactly what it has to ask: who depends on what I just removed? The interesting part is not that Postman can answer that. It is *where* I get to ask."

- **Show:** open [app/ci/blast-radius-check.sh](app/ci/blast-radius-check.sh) and scroll it once, fast. **Do not run it.**

> "This is the check. It diffs the contract I publish, and for anything I removed it asks my team's API Context Graph who was reading it — through the Postman CLI. And to be completely straight with you: Postman does not ship a blast-radius gate. This file is mine, about a hundred and fifty lines of shell. The CLI hands me an answer and a pipeline-aware exit code — zero pass, one blocked, two *I could not prove it was safe* — and what blocks a merge is my policy. That is all a gate is."

- **Show:** open [app/.github/workflows/blast-radius.yml](app/.github/workflows/blast-radius.yml) for about fifteen seconds.

> "Yes, it is a CI job. Two jobs, two questions: am I still correct against myself, and is anyone else still correct against me. But here is the thing I actually want you to take away —"

- **Show:** advance the deck to **slide 3** (Agent → Postman CLI → Context Graph). Point at the three roles as you say them.

> "— it is *one command*. Not an SDK I bind, not an MCP server I stand up, not test infrastructure I maintain. One binary with one exit-code contract, which means this check does not have a *place*. It has a **time**. The pipeline is not a different environment, it is just a later and more expensive moment — after the push, after the review, in front of my team. My terminal is earlier. And my agent's shell is earlier still, before a commit even exists."

> "Three pieces, and I want to be precise about who does what. The **Context Graph** holds the awareness that does not fit in a repo — Postman workspaces, GitHub, New Relic, resolved into one graph, refreshed nightly, every edge carrying its evidence: commit SHA, source, last observed. The **Postman CLI** is the connector — the one binary that makes that answer available anywhere I can run a command. And the **agent** orchestrates and corrects. So let's run it at the earliest possible moment."

### Act 3: The demo — the agent runs it before the push (5 min)

**One actor, one prompt, one continuous run.** You do not touch the check.

- **Show:** the Claude Code pane in `./app` — the "safe to merge" verdict from Act 1 is still above it.
- **Do:** paste the **Act 3 prompt** from `.demo-state/prompts.txt`:
  ```
  Before you push this, run the check we have for exactly this situation:

    ./ci/blast-radius-check.sh

  It uses the Postman CLI to ask our API Context Graph who depends on this API,
  because that is not answerable from inside this repository. It is also the second
  job in our pipeline, so whatever it says now is what CI will say later.

  If it blocks, use the same tool to get the detail you need:

    postman context-graph ask "<your question>" --wait --interval 5

  Then fix the change so the check goes green, and tell me what you did:
    - keep the intent — this field is deprecated and should eventually go away
    - do not break the consumers the graph named
    - write IMPACT.md containing the verdict, every service in the blast radius of
      the ENDPOINT with its owning team, which of those read the FIELD specifically,
      the graph's evidence for each, and a migration path with a sunset date
    - re-run ./ci/blast-radius-check.sh and show me the exit code

  Cite the graph as your source. Do not guess anything it did not tell you.
  ```

**Beat 1 — the check comes back red (1.5 min, including the wait)**

- **Show:** the agent runs the script. It prints the removed field, then the CLI line — `postman context-graph ask ... --wait`.

> "Twenty to forty seconds, and I want to be honest about why: this is not a lookup. The graph is reasoning over the estate. While it works — this is the thing I could not do by hand in a sprint. To answer it myself I would grep every repository in the org, guess which HTTP clients are ours, then go and find out who owns each hit."

- **Show (payoff):** the answer, then the verdict: **`[BLOCKED] ... Merge blocked. Exit 1.`** Read out what it actually returned — the named services, the owning teams, the evidence.

> "Exit one. Three services call this endpoint. Two of them read this specific field — and those are not the same number, which is the distinction I could not make ninety seconds ago. One keys the billing entity off it. One is a nightly job that runs at two in the morning, which is when I would have found out."

> ⚠️ **Say what it said today, not what this README says.** The graph is live and its prose varies. `setup.sh` already grepped this morning's answer and printed `[found]` / `[MISSING]`. Never promise a service the graph did not name.

**Beat 2 — the agent corrects it (2 min)**

- **Show:** the agent reaching for the same CLI command for detail, then editing the serializer and the spec.

> "Watch what the agent is actually doing. Nobody told it the answer — it ran the same command my pipeline runs, and it is now the only participant in this story that can see both sides: my code, and who consumes it. Notice also what it did *not* have to do. It did not read four hundred repositories. It asked one question, got three service names back, and now it knows exactly which corners of the estate matter. That is where the savings come from — the graph does not make the model smarter, it makes the search space smaller."

- **Show:** the agent's final check run — **exit 0**.

**Beat 3 — the payoff (1.5 min)**

- **Do:** switch to the editor. **End here, not on the terminal.**
- **Show (payoff):** two files, in this order:
  1. `git diff app/` — the field is **back**, now with a dated sunset rather than deleted. The intent was kept; the break was not shipped.
  2. **`app/IMPACT.md`** — the verdict, every service in the endpoint's blast radius with its owning team, which of them read the field, the graph's evidence, and the migration path.

> "So the change got corrected before a commit existed. Not after the review, not after the incident. The field still goes away — on a date, with the two teams that read it told first."

- **Say, one sentence, then move on:** "The check has a second way to go green, by the way — if I genuinely want to ship the removal, a complete `IMPACT.md` naming every consumer unblocks it. Shipping a known break should be a decision, not an accident."

### Act 4: The close — and the backstop (1.5 min)

- **Show:** flip back to [app/.github/workflows/blast-radius.yml](app/.github/workflows/blast-radius.yml) for about ten seconds.

> "One last thing, and it is the reason this is a CI job and not just a nice habit. If my agent had skipped that step — or if I had, on a Friday — this is the job that would have blocked the merge instead. Same command, same exit code, later and more expensive. CI is the backstop. It is not where you want to *learn* this."

- **Show:** advance the deck to **slide 5** (One Binary, Three Places).

> "So: your pipeline already blocks the merge when you break yourself. This is what it takes to block it when you are about to break someone else — one CLI, one command, one exit code, and about a hundred lines of your own policy on top. And because it is one command, you get to choose when: agent, terminal, pipeline. Earliest wins."

> "Postman's own benchmark puts the model side of it at twenty-nine percent fewer prompt tokens and seventeen percent fewer tool calls per run when a model works with the graph instead of from code alone, and across four hundred and sixty-eight repositories they measured up to seventy-four percent fewer tokens and seventy-two percent lower cost. Those are Postman's published numbers, not something I measured up here."

> "Install the CLI, point `context-graph ask` at your own API, and find out who you were about to break."

- **Do:** leave slide 5 up, with the install command and the links on screen.

> **Number discipline.** Lead with **−29% prompt tokens / −17% tool calls per run** (the product page's typical figures) and use **up to −74% / −52% / −72% cost, accuracy gains on 18 of 21 prompt-model pairs** (the launch post: 468 repositories, three frontier models, eight cross-service questions) as the ceiling, always with the words "up to". Nothing in this demo measures anything. Never round up, and never let either figure sound like it came off this laptop.

### What to cut when you are over

In this order: the workflow file in Act 2 (keep the sentence "it is also a CI job", drop the file); then Act 4's backstop beat (say the sentence, do not flip to the file); then Beat 1's narration down to one sentence while the ask runs. **Never cut** the `IMPACT.md` payoff, the "Postman does not ship a blast-radius gate" sentence, or the close.

### What survives a dead network

| Act | Offline? |
|---|---|
| 1 — the diff, `npm test`, the agent's repo-only verdict | **Yes.** Fully local. |
| 2 — the check, the workflow, the deck | **Yes.** Reading files, running nothing. |
| 3 — the agent's check run | **No.** The last block of `.demo-state/prompts.txt` is the prompt variant that points the check at the cached answer (`BLAST_RADIUS_ANSWER_FILE=../.demo-state/ask.txt`). Identical output and exit code, one extra line saying it is cached. **Say that line out loud** — do not narrate a live call that did not happen. |
| 3 — the agent correcting it, `IMPACT.md`, the green re-run | **Yes**, once the check is reading the cache. All local edits. |
| 4 — the backstop and the close | **Yes.** Deck and one file. |

---

## 5. Tear down / reset

```bash
./scripts/teardown.sh
```

`app/` is always dirty after a session — setup applies the breaking change and the agent rewrites it on stage — so teardown restores `app/` from git, removes `app/IMPACT.md` and `app/node_modules`, lists any untracked file the agent created for you to review, and deletes `.demo-state/` (cached answer, gate log, test output, prompts). Safe to run when setup never ran.

**It deliberately leaves two things standing**, because they are shared infrastructure and rebuilding them costs a nightly refresh:

- the seeded GitHub estate and its Context Graph connection — see [estate/README.md](estate/README.md);
- your `postman login` session.

Full reset between sessions:

```bash
./scripts/teardown.sh && ./scripts/setup.sh
```

> **Note on `git checkout -- app`:** both scripts restore `app/` from the **index**, so in a fresh clone that is the committed state. If you are editing this demo and have staged changes under `app/`, that is what they will restore to.

Manual steps, only if you are retiring the demo for good: delete the four seeded repositories from your demo org, and remove the GitHub org and Postman workspace as Context Graph sources.

---

## 6. Troubleshooting

| Issue | Fix |
|---|---|
| Setup fails: no `context-graph` command | `npm install -g postman-cli@latest` (known-good 1.62.0), then re-run setup. Do not try `postman context-graph` on the old CLI — it prints "Invalid command" and exits **0**, which is why setup and the gate grep the help text instead. |
| Setup reports **the gate PASSED** | The demo has no red to go green from. Three causes, in order: the breaking change did not apply (check `git diff app/openapi.yaml`); the graph found no consumers (estate not ingested — [estate/README.md](estate/README.md)); a stale `app/IMPACT.md` is acknowledging them (`rm app/IMPACT.md`). |
| The gate exits **2** | The CLI could not answer. Auth first: `postman login`. Then access: Context Graph must be enabled for that team. Then the estate: it must have been ingested. On stage, fall back to `BLAST_RADIUS_ANSWER_FILE=../.demo-state/ask.txt` and say the answer is cached. |
| Setup warns: **no `SERVICES:` line** | The graph answered in prose without the machine-readable tail the gate branches on, so the gate will exit 2 instead of 1. Read `.demo-state/ask.txt` and narrate Act 3 from it; the gate will honestly refuse to guess which words were service names. |
| The ask times out | Its exit 4 surfaces as gate exit 2. The ask is still running server-side: `postman context-graph status <askId>`. On stage, use the cached answer and keep the pace — never wait in silence. |
| `npm test` goes red in setup | The change broke `orders-api` against its own spec, which is a different talk. `git checkout -- app` and re-run setup; if it persists, the breaking-change template has drifted from `app/`. |
| The Act 1 agent finds the consumers anyway | You are in the wrong working directory. Quit the agent, `cd app`, restart it. From the content folder it can grep `estate/repos/`. |
| The agent will not run the gate or the CLI | Run them yourself in the second pane and paste the output into the chat. The story is unaffected — you are the orchestrator for that beat instead. |
| The agent "fixes" it by deleting the test or the gate | Say so out loud, it is a real failure mode and the room will respect it. Re-prompt: the field must come back on a sunset timeline and the gate must not be modified. |
| `app/IMPACT.md` exists before you start | `./scripts/setup.sh` removes it. If you skipped setup: `rm app/IMPACT.md`. |
| `app/` is in a strange state mid-demo | `./scripts/setup.sh` is idempotent — it restores `app/` and re-applies the breaking change. Roughly 40s if the graph answers. |
| The deck does not open | Open `presentation/index.html` by hand. It is self-contained; only the fonts need the network. |

---

## 7. Additional resources

| Resource | Link |
|---|---|
| Postman CLI | <https://www.postman.com/product/postman-cli/> |
| Postman CLI command reference | <https://learning.postman.com/docs/postman-cli/postman-cli-options> |
| Postman CLI installation | <https://learning.postman.com/docs/postman-cli/postman-cli-installation/> |
| API Context Graph | <https://www.postman.com/context-graph/> |
| Launch post — "Introducing the Context Graph API: One Map of Your API Ecosystem" | <https://blog.postman.com/introducing-the-context-graph-api-one-map-of-your-api-ecosystem/> |
| The gate — our policy, on top of the CLI | [app/ci/blast-radius-check.sh](app/ci/blast-radius-check.sh) |
| The pipeline job | [app/.github/workflows/blast-radius.yml](app/.github/workflows/blast-radius.yml) |
| The demo estate and how to seed it | [estate/README.md](estate/README.md) |
| Same product, different signal — the CLI as a test oracle | [../open-meteo-loop-eng/](../open-meteo-loop-eng/) |
