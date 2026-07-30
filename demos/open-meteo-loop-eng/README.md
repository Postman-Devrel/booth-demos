# Meteo API Loop Engineering — Postman as the Oracle

> Booth demo — target length **10 minutes**. This README is the single source of truth. Read it top to bottom before your first attendee; everything you need to run the demo without improvising is here.

---

## 1. Product summary

- **Product:** Postman CLI (Postman as the oracle for an AI coding loop)
- **Use case:** Show how an AI coding agent stops guessing and fixes its own mistakes by looping against a real API, with a human-authored Postman collection as the pass/fail oracle.

**The story (the narrative arc):**

> You ask an AI agent to write a small JavaScript client for a free public weather API. Its first draft returns `200 OK` and a full array of numbers — it looks completely correct, and `npm start` runs fine. But it's quietly wrong: the task never said which unit, and the API defaults to Celsius. Instead of you re-prompting the model, you wire in an **oracle** — a Postman Collection *you* authored, sitting right in the repo, run by the **Postman CLI** — that requires Fahrenheit. The agent's first attempt fails that one assertion, and because it verifies only through a subagent (and is told never to read the collection), it has to *discover* the fix from the failure message and loop until it passes. The payoff: `npm start` prints Fahrenheit temperatures, and the fix came from the API itself, not from you.

> **Self-contained & zero-auth:** the full demo project is bundled in this folder under [`./app`](./app) — setup clones nothing and needs **no Postman account, API key, or cloud workspace**. The oracle is a local collection; the Postman CLI runs it offline against the live Open-Meteo API. This folder is the single source of truth.

**Call to action (for attendees):**

- Grab the demo: `git clone https://github.com/Postman-Devrel/booth-demos.git` → `cd booth-demos/demos/open-meteo-loop-eng`
- Postman CLI docs: <https://learning.postman.com/docs/postman-cli/postman-cli-overview/>
- Loop engineering, explained: <https://addyosmani.com/blog/loop-engineering/>

---

## 2. Pre-requisites

| Requirement | How to get it |
|---|---|
| **Node.js 18+** | Install from <https://nodejs.org/>. The client uses the built-in `fetch`, so no runtime packages are needed. Verify: `node --version` → `v18.0.0` or later. |
| **git** | Pre-installed on macOS/Linux. Used to clone the booth-demos repo and to reset the client between runs. |
| **Claude Code** | Install from <https://code.claude.com/docs>. The `oracle-check` subagent and the optional `/goal` variant are written for Claude Code. Verify: `claude --version`. |
| **Postman CLI** | Runs the local oracle collection — **no Postman account or API key needed**. Install: `curl -o- "https://dl-cli.pstmn.io/install/unix.sh" \| sh` (docs: <https://learning.postman.com/docs/postman-cli/postman-cli-installation/>). Verify: `postman --version`. |
| **Network to `api.open-meteo.com`** | The oracle runs the collection against the live Open-Meteo API (no key). Confirm the booth Wi-Fi can reach it. |

> **No cloud, no auth.** There is deliberately no Postman account, API key, MCP server, or workspace here — the oracle is a JSON collection in the repo (`app/postman/hourly-forecast.postman_collection.json`) and the Postman CLI runs it locally. Nothing is created in or sent to the Postman cloud.

---

## 3. Setup

Run the setup script from this demo folder:

```bash
./scripts/setup.sh
```

It checks and prepares (all against the bundled `./app` project — nothing is cloned, nothing touches the cloud):

1. **Bundled project present** at `./app` (fails clearly if the folder is missing).
2. **Node.js 18+** is installed (fails clearly if older — the built-in `fetch` requires 18).
3. **Claude Code** is on the PATH.
4. **Postman CLI** is installed (fails with the install command if missing).
5. **Oracle collection present** at `app/postman/hourly-forecast.postman_collection.json`.
6. **Resets `app/src/weather-client.js`** to its "looks correct" Celsius starting state by copying the pristine template `scripts/starting-client.js` (git-independent, so it's reliable no matter the repo state). This is essential, or the loop has nothing to fix.
7. **Runs `npm install`** in `./app` (no runtime deps; just wires up `npm start`).
8. **Sanity-runs the starting client** (`npm start`) so you can see it returns a Celsius array before the demo.
9. **Sanity-runs the oracle** against the Celsius URL — it must report the **Fahrenheit assertion failing** (that failing assertion is what drives the loop). If it *passes* on Celsius, something's wrong with the collection.
10. **Prints the ready-to-paste loop prompt** — fully static now (no IDs to swap in), so you can copy it straight into Claude Code.
11. **Opens the presentation** in your browser as the last step.

> **Why a local collection + CLI, not the cloud?** The oracle never touches client code — it's just a contract. Keeping it as a JSON collection in the repo, run by the Postman CLI, means the booth environment is ready instantly with **no account, key, workspace, or teardown of cloud resources**. The only agent in the live demo is `oracle-check`, the verifier that runs the CLI and reports pass/fail.

### Authentication

**None.** The Postman CLI runs a *local* collection file, which needs no login (per Postman's docs, "any local operations work without a login requirement"). The Open-Meteo API needs no key either. There is nothing to export or sign into.

### Pre-demo checklist

- [ ] `./scripts/setup.sh` finished with no `[FAIL]` lines
- [ ] Oracle sanity check reported a **Celsius failure** (the Fahrenheit assertion) — the loop has a fix to find
- [ ] You copied the **ready-to-paste loop prompt** setup printed (it's static — no IDs to edit)
- [ ] Terminal open in `./app` with `claude` running
- [ ] `npm start` printed a **Celsius** array (~24 for Paris), NOT Fahrenheit — proof the loop hasn't run yet
- [ ] `app/src/weather-client.js` open in the editor so the audience can watch it change
- [ ] A terminal pane visible for the `oracle-check` (Postman CLI) output — that's the red→green payoff
- [ ] Editor/terminal font large enough to read from 6 feet away (`Cmd+=`)
- [ ] Presentation open on the booth monitor (slide 1)

---

## 4. Talk track and click track

Five acts, ~10 minutes. Talk track is **verbatim** (blockquotes) — read it if you need to. Click track is interleaved at the exact point each action happens. **Never skip the payoff** — after each major step, show the real artifact where it lives (the file, the Postman app, the terminal array).

### Act 1: The problem — "looks correct" isn't "correct" (2 min)

> "Everyone's using AI agents to write code now. Here's the uncomfortable part: generated code that returns two-hundred OK and a full array of numbers can still be quietly wrong. Let me show you. I asked an agent to write a client for a free weather API — get the hourly forecast for Paris. Watch."

- **Show:** terminal in `./app`, and `app/src/weather-client.js` open in the editor.
- **Do:** run the starting client:
  ```bash
  npm start
  ```
- **Show (payoff):** the terminal prints a real array — `temperatures: [ 23.4, 22.9, ... ] count: 168`.

> "It runs. Two-hundred OK, a hundred and sixty-eight real numbers. If I were reviewing this on a Friday afternoon, I'd approve it. But the task never said which *unit*, and this API defaults to Celsius. What if the contract actually needed Fahrenheit? The code looks right — nothing here tells me it's wrong. Re-prompting the model won't reliably catch this. So let's not prompt. Let's *loop*."

- **Show:** advance the deck to slide 2 (The Problem).

### Act 2: The idea — Postman as the oracle (1.5 min)

> "Loop engineering means: instead of prompting turn by turn, you design a loop where the agent checks its own work against a real signal and fixes itself. The signal is an *oracle* — a test that decides pass or fail. Here, the oracle is a Postman Collection with a test script that *I* wrote, and it requires Fahrenheit. The agent doesn't know that. It can't read my test. It can only see whether it passed or failed. That's what makes the discovery real instead of a rubber stamp."

> "And that's the real lesson: a loop only works when *done* is something you can verify — a clear, binary check. Give the agent that and it converges; leave it vague and it just drifts. The oracle is how we make 'correct' verifiable."

- **Show:** advance the deck to slide 3 (The Journey): Generate → Run against the real API → Verify with the Postman CLI → fix and loop.
- **Do:** (optional, for a curious crowd) point to `postman/hourly-forecast.postman_collection.json` in the file tree — "this collection is mine, the oracle; the agent is told never to open it."

### Act 3: Meet the oracle — a Postman collection in the repo (1.5 min)

> "Here's the oracle I wrote. It's a Postman Collection — it lives right in the repo, and I run it with the Postman CLI. No account, no cloud, nothing to log into. It requires the temperatures to come back in Fahrenheit. The agent will never read this collection; it only gets to know whether it passed or failed. That's the contract."

- **Show (payoff):** in a terminal, run the oracle once against the *current* (Celsius) client URL so the audience sees the contract fail:
  ```bash
  postman collection run postman/hourly-forecast.postman_collection.json \
    --env-var "forecast_url=https://api.open-meteo.com/v1/forecast?latitude=48.85&longitude=2.35&hourly=temperature_2m"
  ```
- **Show:** point at the CLI output — `assertions 3 | failed 1`, and the failure detail: **`expected temperature_2m in "°F" but got "°C"`**. This is the real artifact: a live Postman run, red on the requirement the task never mentioned. (Optional: you can drag this collection into the Postman app to view it — but the CLI is all the demo needs.)
- **Say:** "I authored this; the agent can't read it. All it will get is that failure message."

### Act 4: Run the loop — the agent fixes itself (3.5 min)

> "Now the loop. I tell the agent to write the client and check its work — but the only way it's allowed to check is by delegating to a verifier subagent, and it's told never to open the collection. No running the CLI itself, no reading the oracle. It writes, it checks, and if the oracle fails, it fixes itself from the failure message alone."

- **Show:** the Claude Code terminal in `./app`.
- **Do:** paste this prompt as-is — no hand-editing, no IDs to swap in (the CLI targets the local collection directly). This is the exact prompt setup also prints:
  ```text
  Build getParisHourlyTemps() in src/weather-client.js: fetch the hourly
  temperature forecast for Paris (lat 48.85, lon 2.35) from
  https://api.open-meteo.com/v1/forecast and return the array of temperatures.

  Rules:
  - The ONLY way you may check your work is by delegating to @agent-oracle-check,
    passing the exact URL your client fetches.
  - Do NOT run the Postman CLI yourself and do NOT open postman/ (that collection is
    the oracle). Learn what to fix only from oracle-check's failure messages.
  - Loop, up to 3 attempts: (1) write the whole client; (2) call @agent-oracle-check
    with your URL; (3) if it reports failures, fix from the messages, then go to step 1.
  - Stop when oracle-check reports zero failed assertions.
  ```
- **Show (payoff, attempt 1 fails):** point at the agent's output where `oracle-check` reports **two assertions pass, Fahrenheit fails** — `expected temperature_2m in "°F" but got "°C" — the request is missing a unit parameter` (straight from the Postman CLI run). Emphasize: the agent wrote the *right field* on the first try; it's failing only on the Fahrenheit requirement it never knew about.
- **Show (payoff, the fix):** switch to `src/weather-client.js` in the editor and show the agent has edited the URL to add `&temperature_unit=fahrenheit`. It learned that from the failure message, not from reading the test.
- **Show (payoff, attempt 2 passes):** point at `oracle-check` reporting **zero failed assertions**. The loop stops.

> "There it is. The agent's first attempt looked perfect and still failed the contract. It read the failure, added the unit parameter, and passed — without me re-prompting and without ever seeing my test. The API told it what was wrong, through a Postman assertion."

### Act 5: Prove it and the CTA (1.5 min)

- **Show:** the terminal.
- **Do:** run the client again:
  ```bash
  npm start
  ```
- **Show (payoff):** `temperatures: [ 75.4, 73.9, 73.3, ... ] count: 168`. Say: "Those are Fahrenheit — Paris in Celsius would read about twenty-four, not seventy-five. Real proof."

> "That's loop engineering. You own the oracle, the agent owns the fix, and Postman is the pass/fail signal in between — a collection in the repo, run by the Postman CLI."

> "And you don't have to drive it by hand. What we just did manually is exactly what Claude Code's `/goal` automates: you give it the same verifiable condition, and it keeps looping — writing, checking with the oracle, fixing — until the oracle passes, then stops. Same loop, hands-free."

- **Do (optional, hands-free variant):** instead of driving the loop yourself, wrap it in `/goal`. Nothing to swap in. The `or stop after 5 turns` clause is the budget guard (see note):
  ```text
  /goal getParisHourlyTemps in src/weather-client.js is correct: verifying its URL
  with @agent-oracle-check reports zero failed assertions, or stop after 5 turns.
  Do not run the Postman CLI yourself and do not open postman/.
  ```
  > **Budget / tokenmaxxing:** `/goal` has **no** token/cost cap — but you can bound it with a **turn limit inside the condition** (`… or stop after N turns`, as above). This is the `/goal` equivalent of the manual loop's 3-attempt cap. Check spend anytime by running `/goal` with no args (it shows turn count + tokens); abort with `/goal clear`. Heads-up: if the **turn cap** is what trips, `/goal` reports the goal met and clears even if the oracle isn't passing yet — so glance at the last `oracle-check` result, don't just trust "goal met."

  > Note: for a live booth, prefer the manual loop (Act 4) — it's watchable and you control the pacing. Use `/goal` to show the productized, unattended version, or for headless runs (`claude -p "/goal ..."`).

- **Show:** advance the deck to slide 5 (CTA).
- **Do:** point to the clone command and the docs link on screen.

---

## 5. Tear down / reset

Run the teardown script from this demo folder:

```bash
./scripts/teardown.sh
```

Teardown is trivial because **nothing runs in the cloud** — the oracle is a local collection. It only:

- **Resets `app/src/weather-client.js`** back to the Celsius "looks correct" starting state by copying the pristine template `scripts/starting-client.js` (git-independent), so the loop has something to fix next time.

No API keys, no workspace, no cloud artifacts to delete. The oracle collection stays in the repo (it's the versioned source of truth).

**Full reset between demo days:**

```bash
./scripts/teardown.sh   # reset the client to Celsius
./scripts/setup.sh      # verify tools, sanity-run client + oracle, open the deck
```

---

## 6. Troubleshooting

| Issue | Fix |
|---|---|
| `Postman CLI not found` on setup | Install it (no account needed): `curl -o- "https://dl-cli.pstmn.io/install/unix.sh" \| sh`, or `npm install -g postman-cli`. Then re-run `./scripts/setup.sh`. Verify with `postman --version`. |
| CLI prints "publishing run details to Postman cloud…" or a version-update hint | Harmless. A local collection run reports nothing to the cloud regardless; that line and the update notice are just noise. `oracle-check` ignores them. |
| Oracle *passes* on the Celsius URL during setup | The Fahrenheit assertion isn't firing — check `app/postman/hourly-forecast.postman_collection.json` still contains the "Temperatures are reported in Fahrenheit" test. Without a failing assertion the loop has nothing to do. |
| The agent "passes" on the very first attempt | It read the collection. Re-emphasize the rule: do NOT open `postman/`, do NOT run the Postman CLI directly — only delegate to `@agent-oracle-check`. Re-run `./scripts/teardown.sh` then `setup.sh` to reset the client. |
| `/goal` runs too long / burns tokens | `/goal` has no token cap. Bound it with a turn limit in the condition (`… or stop after N turns`). Run `/goal` (no args) to see turn count + spend; `/goal clear` aborts immediately. If the turn cap trips, it reports "goal met" even if the oracle didn't pass — check the last `oracle-check` result. |
| `oracle-check` reports a network/connection error | The collection runs against live Open-Meteo. Confirm the booth Wi-Fi can reach `api.open-meteo.com`. |
| `npm start` errors / hangs | Same network cause — can't reach `api.open-meteo.com`. Check Wi-Fi; the API needs no key but does need connectivity. |
| Node error about `fetch` undefined | Node is older than 18. Install Node 18+ (`node --version`). |
| Fahrenheit array looks like Celsius (~24) | The loop didn't actually add `&temperature_unit=fahrenheit`. Re-run the loop prompt; confirm the agent edited the URL in `src/weather-client.js`. |

---

## 7. Additional resources

| Resource | Link |
|---|---|
| This demo (booth-demos repo) | <https://github.com/Postman-Devrel/booth-demos/tree/main/demos/open-meteo-loop-eng> |
| Postman CLI — overview | <https://learning.postman.com/docs/postman-cli/postman-cli-overview/> |
| Postman CLI — install | <https://learning.postman.com/docs/postman-cli/postman-cli-installation/> |
| Postman CLI — running collections | <https://learning.postman.com/docs/postman-cli/postman-cli-collections/> |
| Open-Meteo API docs | <https://open-meteo.com/en/docs> |
| Loop engineering (Addy Osmani) | <https://addyosmani.com/blog/loop-engineering/> |
| Claude Code docs | <https://code.claude.com/docs> |
| Claude Code `/goal` (unattended loop) | <https://code.claude.com/docs/en/goal> |
