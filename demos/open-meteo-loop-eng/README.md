# Meteo API Loop Engineering — Postman as the Oracle

> Booth demo — target length **10 minutes**. This README is the single source of truth. Read it top to bottom before your first attendee; everything you need to run the demo without improvising is here.

---

## 1. Product summary

- **Product:** Postman MCP Server (Postman as the oracle for an AI coding loop)
- **Use case:** Show how an AI coding agent stops guessing and fixes its own mistakes by looping against a real API, with a human-authored Postman test as the pass/fail oracle.

**The story (the narrative arc):**

> You ask an AI agent to write a small JavaScript client for a free public weather API. Its first draft returns `200 OK` and a full array of numbers — it looks completely correct, and `npm start` runs fine. But it's quietly wrong: the task never said which unit, and the API defaults to Celsius. Instead of you re-prompting the model, you wire in an **oracle** — a Postman Collection with a test script *you* authored, run through the Postman MCP Server — that requires Fahrenheit. The agent's first attempt fails that one assertion, and because a tool-restricted verifier subagent can't read the test, the agent has to *discover* the fix from the failure message and loop until it passes. The payoff: `npm start` prints Fahrenheit temperatures, and the fix came from the API itself, not from you.

> **Self-contained:** the full demo project is bundled in this folder under [`./app`](./app) — setup does **not** clone anything at demo time. This folder is the single source of truth for the demo; everything it needs lives here.

**Call to action (for attendees):**

- Grab the demo: `git clone https://github.com/Postman-Devrel/booth-demos.git` → `cd booth-demos/demos/open-meteo-loop-eng`
- Postman MCP Server docs: <https://learning.postman.com/docs/reference/postman-api/postman-mcp-server/overview>
- Loop engineering, explained: <https://addyosmani.com/blog/loop-engineering/>

---

## 2. Pre-requisites

| Requirement | How to get it |
|---|---|
| **Node.js 18+** | Install from <https://nodejs.org/>. The client uses the built-in `fetch`, so no runtime packages are needed. Verify: `node --version` → `v18.0.0` or later. |
| **git** | Pre-installed on macOS/Linux. Used to clone and reset the demo repo. |
| **Claude Code** | Install from <https://code.claude.com/docs>. Any MCP-compatible agent works, but the `oracle-check` subagent and the optional `/goal` variant are written for Claude Code. Verify: `claude --version`. |
| **Free Postman account** | Sign up at <https://identity.getpostman.com/signup>. The oracle lives in your Postman workspace. |
| **Postman API key** | Generate at <https://learning.postman.com/docs/developer/postman-api/authentication/>. The MCP server uses it to create and run collections on your behalf. Export before the demo: `export POSTMAN_API_KEY=PMAK-your-key-here`. |
| **Network to `api.open-meteo.com`** | The loop runs against the live Open-Meteo API (no key). Confirm the booth Wi-Fi can reach it. |
| **Postman MCP Server** | No manual install — the bundled project (`./app`) ships a project-level `.mcp.json` that runs `@postman/postman-mcp-server --full` via `npx`. Claude Code loads it automatically when you open `claude` in `./app`; approve it when prompted. |

---

## 3. Setup

Run the setup script from this demo folder:

```bash
./scripts/setup.sh
```

It checks and prepares (all against the bundled `./app` project — nothing is cloned):

1. **Bundled project present** at `./app` (fails clearly if the folder is missing).
2. **Node.js 18+** is installed (fails clearly if older — the built-in `fetch` requires 18).
3. **Claude Code** is on the PATH.
4. **`POSTMAN_API_KEY` is set** (fails clearly if missing — the MCP server can't create or run collections without it).
5. **Resets `app/src/weather-client.js`** to its "looks correct" Celsius starting state via `git checkout` (the file is tracked by this booth-demos repo). This is essential, or the loop has nothing to fix.
6. **Runs `npm install`** in `./app` (no runtime deps; just wires up `npm start`).
7. **Creates `app/.env`** from the example so `.mcp.json` can read `${POSTMAN_API_KEY}` (no secret is committed).
8. **Provisions the Postman oracle** (via `scripts/postman-setup.mjs`, using the Postman API): finds or creates the **open-meteo-loop-eng** workspace, builds the **Hourly forecast** collection whose request URL is `{{forecast_url}}` with your test attached, and creates the **open-meteo-loop-eng** environment. It writes the IDs to `app/oracle.ids.json` (the loop prompt reads them from there, so you never paste IDs by hand) and **prints the workspace URL, `collectionUid`, `environmentUid`, and a ready-to-paste loop prompt**. Idempotent — re-run any time; it refreshes the collection in place.

   > **Finding the workspace:** on a **team** Postman account, the API creates it with **Personal** visibility, so it will **not** appear in the shared team workspace list — open it via the **workspace URL** setup prints (`https://go.postman.co/workspace/<id>`), or find it under the **Personal** section of the app sidebar. (See troubleshooting if you'd rather make it team-visible.)
9. **Sanity-runs the starting client** (`npm start`) so you can see it returns a Celsius array before the demo.
10. **Opens the presentation** in your browser as the last step.

> **Why the script, not an agent?** The oracle is pure setup — it never touches client code. Provisioning it in `setup.sh` means the booth environment is fully ready before the first attendee, and the *only* agent in the live demo is `oracle-check`, the tool-restricted verifier that drives the loop. That keeps the spotlight on the one thing that matters: the agent looping until the oracle passes.

### Authentication

This demo needs a **Postman API key** so both the setup script and the MCP server can create and run collections. 

- **Recommended for a booth:** export it once before running setup and before opening Claude Code — `export POSTMAN_API_KEY=PMAK-...`. `scripts/postman-setup.mjs` reads it directly, and `app/.mcp.json` reads `${POSTMAN_API_KEY}`, so nothing secret is committed.
- The Open-Meteo API itself needs **no** key or auth.

### Pre-demo checklist

- [ ] `./scripts/setup.sh` finished with no `[FAIL]` lines
- [ ] **Oracle provisioned** — you copied the `collectionUid`, `environmentUid`, and the ready-to-paste loop prompt that setup printed
- [ ] `POSTMAN_API_KEY` is exported in the terminal you'll use for Claude Code
- [ ] Terminal open in `./app` with `claude` running
- [ ] Postman MCP Server approved when Claude Code prompted (ask Claude to "list my Postman workspaces" — it should call `getWorkspaces`)
- [ ] `npm start` printed a **Celsius** array (~24 for Paris), NOT Fahrenheit — proof the loop hasn't run yet
- [ ] `app/src/weather-client.js` open in the editor so the audience can watch it change
- [ ] Postman app/web open on the **open-meteo-loop-eng** workspace for the payoff moment (open it via the **workspace URL** setup printed — it's a Personal-visibility workspace, not in the team list)
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

- **Show:** advance the deck to slide 3 (The Journey): Generate → Run against the real API → Verify with Postman → fix and loop.
- **Do:** (optional, for a curious crowd) show the oracle exists but *don't* read its contents on the main session — point to `postman/hourly-forecast.test.js` in the file tree and say "this is mine, the agent never sees it."

### Act 3: Meet the oracle — already live in Postman (1.5 min)

> "Here's the oracle I wrote. It's a Postman Collection with a test script, and it lives in my Postman workspace right now — I set it up before we started. It requires the temperatures to come back in Fahrenheit. The agent will never see this test; it only gets to know whether it passed or failed. That's the contract."

- **Show (payoff):** switch to the **Postman app/web** (open the workspace via the URL setup printed — have this tab ready before the demo), and show the **Hourly forecast** collection with the test script attached and the **open-meteo-loop-eng** environment holding `forecast_url`. This is the real artifact — Postman is the source of truth, and it's ready before the demo even starts.
- **Do:** have the `collectionUid` and `environmentUid` from the setup output ready (setup printed them and a ready-to-paste loop prompt). Emphasize to the audience: "I authored this test; the agent cannot read it."

### Act 4: Run the loop — the agent fixes itself (3.5 min)

> "Now the loop. I tell the agent to write the client and check its work — but the only way it's allowed to check is by delegating to a verifier subagent that *cannot read my test*. No peeking at Postman directly, no reading the test file. It writes, it checks, and if the oracle fails, it fixes itself from the failure message alone."

- **Show:** the Claude Code terminal in `./app`.
- **Do:** paste this prompt as-is — no hand-editing, no IDs to swap in. It reads the UIDs from `oracle.ids.json` itself (setup wrote them there). This is the exact prompt setup also prints:
  ```text
  Build getParisHourlyTemps() in src/weather-client.js: fetch the hourly
  temperature forecast for Paris (lat 48.85, lon 2.35) from
  https://api.open-meteo.com/v1/forecast and return the array of temperatures.

  Rules:
  - The collectionUid and environmentUid are in ./oracle.ids.json — read them from
    that file and pass them to @agent-oracle-check.
  - The ONLY way you may check your work is by delegating to @agent-oracle-check.
    Do NOT call any Postman tool yourself and do NOT read postman/ or the test.
    You do not know what the oracle checks beyond its failure messages.
  - Loop, up to 3 attempts: (1) write the whole client; (2) call @agent-oracle-check
    with the exact URL your client fetches plus the collectionUid and environmentUid
    from oracle.ids.json; (3) if it reports failures, use the messages to fix the
    client, then go to step 1.
  - Stop when oracle-check reports zero failed assertions.
  ```
- **Show (payoff, attempt 1 fails):** point at the agent's output where `oracle-check` reports **two assertions pass, Fahrenheit fails** — `expected temperature_2m in "°F" but got "°C" — the request is missing a unit parameter`. Emphasize: the agent wrote the *right field* on the first try; it's failing only on the Fahrenheit requirement it never knew about.
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

> "That's loop engineering. You own the oracle, the agent owns the fix, and Postman is the pass/fail signal in between — exposed to the agent through the Postman MCP Server."

> "And you don't have to drive it by hand. What we just did manually is exactly what Claude Code's `/goal` automates: you give it the same verifiable condition, and it keeps looping — writing, checking with the oracle, fixing — until the oracle passes, then stops. Same loop, hands-free."

- **Do (optional, hands-free variant):** instead of driving the loop yourself, wrap it in `/goal`. Same as the manual prompt, it reads the UIDs from `oracle.ids.json` — nothing to swap in:
  ```text
  /goal getParisHourlyTemps in src/weather-client.js is correct: verifying its URL
  with @agent-oracle-check (using the collectionUid and environmentUid from
  ./oracle.ids.json) reports zero failed assertions. Do not read postman/ or the test.
  ```
  > Note: for a live booth, prefer the manual loop (Act 4) — it's watchable and you control the pacing. Use `/goal` to show the productized, unattended version, or for headless runs (`claude -p "/goal ..."`).

- **Show:** advance the deck to slide 5 (CTA).
- **Do:** point to the clone command and the docs link on screen.

---

## 5. Tear down / reset

Run the teardown script from this demo folder:

```bash
./scripts/teardown.sh
```

It cleans up:

- **Resets `app/src/weather-client.js`** back to the Celsius "looks correct" starting state (`git checkout`), so the loop has something to fix next time.
- **Removes the Postman cloud oracle** (via `scripts/postman-teardown.mjs`, using the Postman API): deletes the **Hourly forecast** collection and the **open-meteo-loop-eng** environment, and deletes the **open-meteo-loop-eng** workspace **only if setup created it** (recorded in `oracle.ids.json` — a pre-existing workspace of the same name is left untouched).
- **Removes `app/oracle.ids.json`** so the next setup provisions a fresh oracle.
- **Removes `app/.env`** (regenerated from `.env.example` on next setup).

No manual Postman cleanup is needed — teardown removes the cloud artifacts for you. (If `POSTMAN_API_KEY` isn't set when you run teardown, cloud cleanup is skipped with a warning; re-run teardown with the key exported.)

**Full reset between demo days:**

```bash
./scripts/teardown.sh   # reset client, delete the Postman oracle + workspace, clear local state
./scripts/setup.sh      # verify tools, re-provision the oracle, sanity-run npm start, open the deck
```

---

## 6. Troubleshooting

| Issue | Fix |
|---|---|
| `POSTMAN_API_KEY is not set` on setup | `export POSTMAN_API_KEY=PMAK-...` in the same terminal, then re-run `./scripts/setup.sh`. Get a key at <https://learning.postman.com/docs/developer/postman-api/authentication/>. |
| Claude Code doesn't see Postman tools | Confirm `.mcp.json` loaded and you approved the server. Test with "list my Postman workspaces" — it should call `getWorkspaces`. Restart `claude` in `./app` if needed. |
| `setup.sh` fails provisioning the oracle | Usually a bad/expired API key or no network. Re-export `POSTMAN_API_KEY`; confirm you can reach `api.getpostman.com`. Then re-run `./scripts/setup.sh` (it's idempotent). |
| Workspace isn't in my Postman workspace list | Expected on a **team** account: the API creates it with **Personal** visibility, so it's not in the shared team list. Open it via the **workspace URL** setup printed, or the **Personal** section of the sidebar. To make it appear team-wide instead, change `type: "personal"` to `type: "team"` in `scripts/postman-setup.mjs` (note: that exposes it to your whole team) and re-run setup. |
| The agent "passes" on the very first attempt | It read the test. Re-emphasize the rule in the prompt: do NOT read `postman/`, do NOT call Postman tools directly — only delegate to `@agent-oracle-check`. Re-run `./scripts/teardown.sh` then `setup.sh` to reset the client. |
| `runCollection` returns 404 | Wrong ID *form*. `runCollection` needs the collection **uid** (`<owner>-<uuid>`), and the environment **uid** for `environmentId`. Re-copy the exact IDs `setup.sh` printed (also saved in `app/oracle.ids.json`). |
| Loop passes but I edited the test and nothing changed | Editing `postman/hourly-forecast.test.js` does NOT update Postman. Re-run `./scripts/setup.sh` — it refreshes the collection in place (same IDs) with the new test. |
| `npm start` errors / hangs | Booth network can't reach `api.open-meteo.com`. Check Wi-Fi; the API needs no key but does need connectivity. |
| Node error about `fetch` undefined | Node is older than 18. Install Node 18+ (`node --version`). |
| Fahrenheit array looks like Celsius (~24) | The loop didn't actually add `&temperature_unit=fahrenheit`. Re-run the loop prompt; confirm the agent edited the URL in `src/weather-client.js`. |

---

## 7. Additional resources

| Resource | Link |
|---|---|
| This demo (booth-demos repo) | <https://github.com/Postman-Devrel/booth-demos/tree/main/demos/open-meteo-loop-eng> |
| Postman MCP Server — overview | <https://learning.postman.com/docs/reference/postman-api/postman-mcp-server/overview> |
| Postman MCP Server — local setup | <https://learning.postman.com/docs/reference/postman-api/postman-mcp-server/postman-mcp-local-server> |
| Postman API key — authentication | <https://learning.postman.com/docs/developer/postman-api/authentication/> |
| Open-Meteo API docs | <https://open-meteo.com/en/docs> |
| Loop engineering (Addy Osmani) | <https://addyosmani.com/blog/loop-engineering/> |
| Claude Code docs | <https://code.claude.com/docs> |
| Claude Code `/goal` (unattended loop) | <https://code.claude.com/docs/en/goal> |
