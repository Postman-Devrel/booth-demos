# Postman in the terminal

> The 10-minute booth cut of this same demo lives in [content/lightning-talks/postman-in-the-terminal/](../../lightning-talks/postman-in-the-terminal/) — read that README instead if you're on the floor, not in a slot.

> [Short talk](../../../templates/formats/short-talk.md) — target length **28 minutes (Q&A included)**. Delivered at meetups and conference breakouts. This README is the single source of truth. Read it top to bottom before your first attendee; everything you need to run the demo without improvising is here.

---

## 1. Product summary

- **Product:** the [Postman Claude Code plugin](https://www.postman.com/liftoff/modules/claude-code-plugin/), backed by the same Postman skills and the [Postman CLI](https://www.postman.com/product/postman-cli/) underneath, with the [API Context Graph](https://www.postman.com/context-graph/) as the flagship example of what those skills let an agent reach for
- **Use case:** show where an agent's Postman know-how actually comes from. It isn't something you told it once in a chat. It's committed Postman skills, and they reach an agent two ways: the plugin installs them straight into a developer's own Claude Code, and `postman init` commits the same skills into a repository, so an agent running unattended in CI gets them too.
- **Audience:** developers building or supervising coding agents, and anyone who's wondered what a Postman plugin actually gives an agent that the app's UI does not.

**The thesis, in one line:**

> **An agent's Postman skills live in files, not in a chat history, and the same files reach a developer's own agent through the plugin and a CI agent through `postman init`.**

**The story (the narrative arc):**

> Open on the failure: an agent that only knows what you just told it, and a second agent — a CI job — that you can't tell anything at all. Name the structural reason (a chat history isn't committed anywhere a second agent can find it), then name the fix: committed Postman skills, reaching an agent two ways. The **slides** carry both paths conceptually first: the plugin installs committed Postman skills straight into a developer's own Claude Code, and `postman init` commits the same skills into a repo, where they reach a different agent, one nobody is prompting. Then both paths get shown live, in order. First the plugin path: a bare `openapi.yaml`, nothing else, handed to a local Claude Code session, and one plain-English instruction — build a workspace, a collection, and a mock — that the plugin turns into a live chain of Postman skills, no commands named. Then the `postman init` path: you clone a **real repository** backing `patients-service`, remove a real field from its contract, and open a real pull request. From there nobody prompts anything: a GitHub Action fires, the CI agent reads the diff, decides on its own that the change is risky, and reaches for `postman context-graph ask` on its own initiative. While it thinks (a handful of seconds to a few minutes, Context Graph results vary), you switch to the Postman app and show the Context Graph UI for real. Then you read its verdict off the PR, and close on what it costs to keep this working and the two questions you know you'll be asked.

> **What this demo is not:** a Context Graph feature demo, and not a merge-blocking CI gate either. The CI agent reports; it doesn't block anything. The point is narrower: committed Postman skills, not a chat history, are what let this agent reason on its own.

> **Network reality:** everything from act 4 onward needs the network. Act 4 makes real Postman API calls (a real workspace, collection, and mock); act 5 onward adds a real GitHub repo, a real Actions run, a real Context Graph call. There is no offline fallback in this version of the demo; see [section 6](#6-troubleshooting) for what to do if the venue Wi-Fi is the problem, not the demo.

**Call to action (for attendees):**

- `npx @postman/postman-plugin`, then ask your own agent to review your next API change
- Postman CLI: <https://www.postman.com/product/postman-cli/>
- API Context Graph: <https://www.postman.com/context-graph/>
- Claude Code Plugin module on Liftoff: <https://www.postman.com/liftoff/modules/claude-code-plugin/>
- Join the Postman community on Discord: <https://postman-community.com/kmg>
- The live demo repo: <https://github.com/Postman-Devrel/postman-plugin-pr-review-demo>
- This talk's slides and setup tooling: `git clone https://github.com/Postman-Devrel/booth-demos.git` → `cd booth-demos/content/short-talks/postman-in-the-terminal`

---

## 2. Pre-requisites

| Requirement | How to get it |
|---|---|
| **Claude Code and the Postman CLI, installed and logged in locally** | `command -v claude`, `command -v postman`, and `postman login` done **before** you present, see [section 6](#6-troubleshooting) if the plugin prompts for auth mid-demo. This is for act 4 only: the plugin creates a real workspace, collection, and mock on your own Postman account. |
| **`git` and `gh`, authenticated** | `gh auth status`. You need push access to [Postman-Devrel/postman-plugin-pr-review-demo](https://github.com/Postman-Devrel/postman-plugin-pr-review-demo) to open the PR live, presenting under your own fork or a different demo repo means updating `DEMO_REPO` at the top of `scripts/setup.sh` and `scripts/teardown.sh`. |
| **The demo repo's own secrets, already set** | `POSTMAN_API_KEY` and `ANTHROPIC_API_KEY` as GitHub Actions secrets on the demo repo, `setup.sh` checks both exist (not their values) and fails loudly if either is missing. One-time; not something you redo per session. |
| **A Postman account, for act 6 too** | Logged into the Postman **app** (not just the CLI) as a member of the team whose Context Graph has the estate ingested. This is for narrating the UI while the CI agent runs; the CI agent's own job logs into the CLI with the repo's secret, it doesn't need your laptop. |
| **A claude.ai account, signed in, for the deck** | The deck of record is a Claude Design project, not a local file. Sign in before you present; see [section 6](#6-troubleshooting) if it won't open. |

> **From act 5 onward, no local Postman CLI, no local Claude Code.** Act 4 is the exception, it runs the plugin on your own laptop on purpose. From the moment you open the PR, the CI agent runs both, inside the demo repo's own CI. Your laptop only needs to get a branch pushed and a PR opened.

---

## 3. Setup

```bash
./scripts/setup.sh
```

1. **Tooling**: `git`, `gh`, `claude`, `postman`, and that `gh` is authenticated.
2. **A fresh bare-spec folder** at `/tmp/postman-plugin-local-demo`, just `openapi.yaml` copied in, for act 4.
3. **No leftover PR** from a previous rehearsal on the demo repo, fails if teardown didn't run last time.
4. **Both Actions secrets exist** on the demo repo (`POSTMAN_API_KEY`, `ANTHROPIC_API_KEY`), fails with the exact `gh secret set` command if either is missing.
5. **A fresh clone** of the demo repo at `/tmp/postman-plugin-pr-review-demo`, replacing whatever was there.
6. **`main` still has `blood_type`**: sanity check that a previous rehearsal's change didn't reach `main` without a teardown.
7. **Opens the Claude Design deck and the demo repo's GitHub page** in the browser.

### Authentication

`gh auth status` is what lets `setup.sh` clone the demo repo and check its secrets, and what lets you run `gh pr create` live on stage, nothing to log into locally for that part. Act 4 is different: log into the Postman CLI (`postman login`) **before** you present, so `postman:bootstrap` doesn't stall on an auth flow mid-demo. Sign into claude.ai separately too, before you present, so the deck is ready.

### Pre-demo checklist

- [ ] `./scripts/setup.sh` finished with no `[FAIL]` lines
- [ ] Logged into the Postman CLI (`postman login`) before presenting
- [ ] Signed into claude.ai, deck open, fullscreen, on slide 1
- [ ] `github.com/Postman-Devrel/postman-plugin-pr-review-demo` open in a browser tab
- [ ] A Postman workspace with this team's Context Graph open in **another** tab, don't switch to it until act 6
- [ ] A terminal tab in `/tmp/postman-plugin-local-demo` running `claude`, large font (`Cmd+=`) — act 4
- [ ] A second terminal tab in `/tmp/postman-plugin-pr-review-demo`, large font — act 5+
- [ ] No open PR yet on the demo repo

---

## 4. Talk track and click track

Nine acts, 28 minutes (Q&A included). Talk track is **verbatim** (blockquotes), read it if the room goes cold. Click track is interleaved at the exact point each action happens.

Slide numbers below are marked `[slide ?]` because this README was written before the deck's slide-by-slide outline was pasted in. Re-map them against the deck before you present — see the final report for the full list of placeholders; **do not invent slide titles**.

**The live demo starts at act 4, `[slide ?]`** — that's the handoff point, the moment you leave the deck for a real terminal. It stays live through act 6; there's no going back to slides in between.

| Act | Purpose | Slide(s) | Budget |
|---|---|---|---|
| 1 | **Cold open** — the agent that only knows what you just told it | `[slide ?]` | 2–3 min |
| 2 | **Why it happens** — a chat history isn't committed anywhere a second agent can find it | `[slide ?]` | 3 min |
| 3 | **The idea** — committed Postman skills, reaching an agent two ways | `[slide ?]`–`[slide ?]` | 2 min |
| 4 | **Demo, part 1** — the plugin, live, from a bare spec (**live demo starts here**) | `[slide ?]` | 3–4 min |
| 5 | **Demo, part 2** — the real repo, breaking the contract by hand | — (live terminal and browser, no slides) | 4–5 min |
| 6 | **Demo, part 3** — the CI agent takes over, the Context Graph, the verdict | — (live terminal and browser, no slides) | 5–6 min |
| 7 | **What it costs** — upkeep, and where this is gated | `[slide ?]` | 3 min |
| 8 | **Objections** — the two questions you know you'll be asked | `[slide ?]` | 2–3 min |
| 9 | **Close + CTA** | `[slide ?]` | 1–2 min |

### Act 1: Cold open (~2–3 min)

> "Say you ask your coding agent to check whether an API change is safe. It can reason about it — but only about what you've told it, right now, in this chat. Close the tab, and that's gone. Now hand the same question to a CI job, where there's nobody even there to ask. That agent doesn't start from zero. It starts from nothing."

- **Show:** `[slide ?]` (title), `[slide ?]` (the chat-window problem, stated as a picture: a conversation bubble that doesn't survive the tab closing).

### Act 2: Why it happens (~3 min)

> "This isn't a model problem, it's a storage problem. Teaching an agent in a conversation puts what it learned somewhere only that conversation can reach. The moment the agent asking the question is a CI job with no chat window at all, there's nothing to hand it — not a worse version of the knowledge, none of it."

- **Show:** `[slide ?]` (the two agents side by side: a developer's Claude Code with a chat history, and a CI job with none).

### Act 3: The idea (~2 min)

> "Here's the fix: stop teaching the agent in a conversation. Commit what it needs to know, as Postman skills, and those skills reach an agent two ways. Install the Postman Claude Code plugin, and your own agent gets them. Run `postman init` in a repo, and the same skills get committed there, so an agent running in CI, with nobody watching, gets them too. What's next shows both, live: the plugin first, then the same skills committed into a repo for an agent nobody's prompting."

- **Show:** `[slide ?]`–`[slide ?]` (capabilities, build and test, the two paths skills take) walked through, not typed live.
- **Show:** advance to `[slide ?]` ("A script can run the CLI. It can't judge the diff.") as the bridge into the live part.

### Act 4: Demo, part 1 — the plugin, live, from a bare spec (~3–4 min)

> "Before any of that touches a real repo, here's the plugin by itself. This folder has exactly one file, `openapi.yaml`, nothing else — no workspace, no collection, no mock. I'm not going to run a single Postman command. I'm going to ask for the outcome and watch the plugin decide the commands."

- **Show:** switch to the terminal tab in `/tmp/postman-plugin-local-demo`, `claude` already running, `ls` to show the one file.
- **Do**, inside that Claude Code session:
  ```
  From openapi.yaml, create a Postman workspace, a collection, and a mock.
  ```
- **Show (payoff):** narrate each skill as it fires, don't read the file names off this README, read what's actually on screen. The chain is typically `postman:api-engineer` routing the request, `postman:bootstrap` creating or linking the workspace, a collection generated from the spec, then `postman:api-mocking` standing the mock up.

> "One instruction, three Postman skills chained on their own, and I never typed a single `postman` command. That's the plugin, straight in my own terminal, on my own account. Now watch where the exact same skills go when there's nobody sitting here at all."

### Act 5: Demo, part 2 — the real repo, breaking it (~4–5 min)

> "`patients-service` is a real API, in a real GitHub repo. It already has `AGENTS.md` at its root, the Postman skills `postman init` committed under `postman/skills/`, and an agent prompt that reasons through a change instead of listing commands."

- **Show:** switch to the browser tab on `github.com/Postman-Devrel/postman-plugin-pr-review-demo`. Point out [`openapi.yaml`](openapi.yaml), `AGENTS.md`, the `postman/skills/` directory, and [`agents/api-change-reviewer.md`](agents/api-change-reviewer.md), "read this file, it never names a single Postman command, it points at the skills instead. Not a script, five judgment calls."

> "I'm about to remove `blood_type` from the patient contract. Clinical data, plausibly read by another system, never read by this service itself, so my own tests here stay green either way. That's the honest trap: locally, nothing looks wrong."

- **Do**, in `/tmp/postman-plugin-pr-review-demo`:
  ```bash
  git checkout -b remove-blood-type
  # remove the blood_type property from the Patient schema in openapi.yaml
  git add openapi.yaml
  git commit -m "Remove blood_type from the patient contract"
  git push -u origin remove-blood-type
  gh pr create --fill
  ```

> "And that's it. I'm not opening Postman, I'm not asking an agent anything. I just opened a pull request."

### Act 6: Demo, part 3 — the CI agent takes over (~5–6 min)

- **Show:** switch to the PR in the browser, or the **Actions** tab.

> "The PR is open. From this exact moment, nobody prompts anything. The PR opening is the trigger. Watch."

- **Show (payoff):** the checks run, then a comment lands on the PR from the CI agent, it read the diff, judged the change, and if it decided the change was risky, it called `postman context-graph ask` itself and reported what came back: real service names, and whatever it could or couldn't confirm about ownership.

> "The same skills the plugin would hand to my own agent, committed into the repo instead, for an agent I'm not sitting in front of."

The Context Graph call inside that CI job can take anywhere from a few seconds to a few minutes, dead air if you just wait on it.

- **Show:** switch to the Postman app, the Context Graph UI, for this team's estate.

> "This is what the CI agent is looking at right now. It's not a lookup table, it's reasoning over real service-to-service calls. That's what's happening behind that spinner."

- **Show:** back to the PR, read the agent's comment out loud, verbatim. **Say what it actually says today**, not a number this README knows, it's live.

> ⚠️ **Field-level questions are out of scope, and that's honest, not a limitation to apologize for.** The graph knows who calls this endpoint. It doesn't know which JSON field in the response they read. If asked "can it tell me who reads *this specific field*," the honest answer is: not yet, and here's what it told you instead, which is still more than you had before opening the PR.

> "One pull request, two agents, and I know exactly who to go talk to before I ship this, reported by an agent I never prompted."

### Act 7: What it costs (~3 min)

> "What you just watched cost nothing extra to run on this PR — the CI agent reports, it never blocks a merge, and this talk is honest about that limit. What it costs is upkeep: these skills are the same files the Postman CLI ships, so when they change, you update one place, not every agent's memory separately. And the Context Graph answer you saw is only as good as the team's graph. It's gated per Postman team, not a free-tier feature, and it only knows what's been ingested."

- **Show:** `[slide ?]` (the one set of skill files, two delivery paths, diagram).

### Act 8: Objections (~2–3 min)

> "Two questions, every time. First: does this block my merge? No. The CI agent reports; it never blocks anything, on purpose — the judgment call still belongs to a person. Second: can it tell me which *field* broke, not just which service calls the endpoint? Also no, today. The graph answers at the endpoint level. A stronger agent run reads the caller's source to close that gap partway; a weaker run just reports the fan-in and asks a human to confirm. Both are honest answers, and both are more than you had before you opened the PR."

- **Show:** `[slide ?]` (the objections slide, if the deck carries one).

### Act 9: Close + CTA (~1–2 min)

> "An agent's Postman skills live in files, not in a chat history. Install the plugin, and your own agent gets them. Run `postman init`, and the agent nobody is prompting gets them too."

- **Show:** `[slide ?]` (CTA).
- CTA, read it out:
  - `npx @postman/postman-plugin`, then ask your own agent to review your next API change
  - Postman CLI: <https://www.postman.com/product/postman-cli/>
  - API Context Graph: <https://www.postman.com/context-graph/>
  - Claude Code Plugin module on Liftoff: <https://www.postman.com/liftoff/modules/claude-code-plugin/>
  - Join the Postman community on Discord: <https://postman-community.com/kmg>

### What to cut when you are over

Cut act 7 first, then act 8, then compress act 2. If you're still over, cut act 4 (the local plugin demo) entirely and jump from the slides straight to act 5 — say so on stage, the plugin path is the same skills, just not typed live this session. **Never cut** the cold open (act 1) or act 6's payoff — reading the CI agent's comment out loud, that's where the demo lands.

---

## 5. Tear down / reset

```bash
./scripts/teardown.sh
```

Closes the PR opened on stage, deletes its branch on the demo repo, and removes both local folders: `/tmp/postman-plugin-local-demo` (act 4) and `/tmp/postman-plugin-pr-review-demo` (act 5+). Safe to run when setup never ran.

**It deliberately leaves standing:** the demo repo's `main` branch and its Actions secrets, and the Postman team's Context Graph connection to the estate, shared infrastructure this session doesn't own.

**It cannot clean up:** the workspace, collection, and mock act 4 created live on your own Postman account. `teardown.sh` has no way to identify them after the fact — delete them by hand in the Postman app before the next rehearsal, or they pile up.

Full reset between sessions:

```bash
./scripts/teardown.sh && ./scripts/setup.sh
```

---

## 6. Troubleshooting

| Issue | Fix |
|---|---|
| Act 4 stalls on a Postman login prompt | You weren't logged into the Postman CLI before presenting. Run `postman login` now, or narrate the delay — never skip it to save time, that defeats the point of showing a real workspace get created. |
| Act 4: the plugin doesn't create a workspace, or picks the wrong one | Check which Postman account/team `postman login` is authenticated against; it's whatever account is logged in locally, not the demo repo's `POSTMAN_API_KEY`. Re-run `postman login` against the right account before presenting. |
| `setup.sh` fails: leftover open PR | A previous session's `teardown.sh` didn't run. Run it now, or close the PR by hand on `github.com/Postman-Devrel/postman-plugin-pr-review-demo/pulls`. |
| `setup.sh` fails: a secret is missing | Run the `gh secret set` command it prints. This is a one-time, per-repo setup, it shouldn't recur once both secrets exist. |
| `setup.sh` fails: `main` is already missing `blood_type` | A previous rehearsal's change reached `main` without a teardown. Open the file on `main` and put `blood_type` back by hand before presenting. |
| The Action job fails on `postman login` | Almost always a PR opened from a fork, GitHub does not pass secrets to fork PRs. Push the branch to the repo itself, not a fork, and open the PR from there. |
| The Action job fails on `claude -p` with an auth error | `ANTHROPIC_API_KEY` is missing or wrong on the demo repo. Re-issue it: `gh secret set ANTHROPIC_API_KEY --repo Postman-Devrel/postman-plugin-pr-review-demo`. |
| The PR comment says the graph doesn't know this API, or never mentions the graph at all | The `POSTMAN_API_KEY` behind the demo repo's secret isn't on a team with the estate ingested, re-issue the secret from an account that is. Separately: the agent only calls the graph if it judges the change risky; if it didn't ask, that's a real finding to narrate, not a bug. |
| No comment shows up on the PR at all | Check the **Actions** tab for the run's logs, the job may still be running, or it failed outright; the logs say which. A run that reports success but shows no commands and no comment is itself a known failure mode of an earlier cut of the workflow's logging, not expected behavior today. |
| The deck does not open | Sign in to claude.ai — the deck lives in Claude Design, there's no offline deck for this talk and no HTML fallback to open instead. |

---

## 7. Additional resources

| Resource | Link |
|---|---|
| **The live demo repo** | <https://github.com/Postman-Devrel/postman-plugin-pr-review-demo>, clone it, break it, watch the agent |
| Its committed skills, written by `postman init` | [`postman/skills/`](https://github.com/Postman-Devrel/postman-plugin-pr-review-demo/tree/main/postman/skills) and [`AGENTS.md`](https://github.com/Postman-Devrel/postman-plugin-pr-review-demo/blob/main/AGENTS.md) |
| Its CI agent's instructions | [`agents/api-change-reviewer.md`](https://github.com/Postman-Devrel/postman-plugin-pr-review-demo/blob/main/agents/api-change-reviewer.md) |
| Its trigger | [`.github/workflows/api-change-review.yml`](https://github.com/Postman-Devrel/postman-plugin-pr-review-demo/blob/main/.github/workflows/api-change-review.yml) |
| Postman Claude Code Plugin module (Liftoff) | <https://www.postman.com/liftoff/modules/claude-code-plugin/> |
| Postman CLI | <https://www.postman.com/product/postman-cli/> |
| Postman CLI command reference | <https://learning.postman.com/docs/postman-cli/postman-cli-options> |
| Postman CLI installation | <https://learning.postman.com/docs/postman-cli/postman-cli-installation/> |
| API Context Graph | <https://www.postman.com/context-graph/> |
| The contract shown on the slides | [openapi.yaml](openapi.yaml), same content as the demo repo's |
| The 10-minute booth cut of this talk | [../../lightning-talks/postman-in-the-terminal/](../../lightning-talks/postman-in-the-terminal/) |
| Same product, different signal, the CLI as a test oracle | [../../lightning-talks/open-meteo-loop-eng/](../../lightning-talks/open-meteo-loop-eng/) |
