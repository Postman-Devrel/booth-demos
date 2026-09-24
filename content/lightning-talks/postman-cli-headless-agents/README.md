# Postman Headless: The Agentic Era

> [Lightning talk](../../../templates/formats/lightning-talk.md) — target length **10 minutes**. Delivered at booths, meetups, and lightning tracks. This README is the single source of truth. Read it top to bottom before your first attendee; everything you need to run the demo without improvising is here.

---

## 1. Product summary

- **Product:** [Postman CLI](https://www.postman.com/product/postman-cli/), with the [API Context Graph](https://www.postman.com/context-graph/) as its flagship advanced case
- **Use case:** Show that the Postman CLI is not a niche CI trick — it is the interface Postman gives to agents, the same role the UI plays for humans. An agent builds and tests an API entirely headless, then reaches for the same binary to get awareness no UI could give it either — and it does not need a person to prompt it every time.
- **Audience:** Developers building or supervising coding agents, and anyone who's wondered why Postman needs a CLI when it already has an app.

**The thesis, in one line:**

> **The CLI is to agents what the UI is to humans. Headless is not a workaround — it's the natural interface for something that doesn't have eyes.**

**The story (the narrative arc):**

> Say the thesis once, early. The **slides** carry the everyday case conceptually: an agent validates an API contract, generates a collection and a mock from it, and runs the collection against the mock — no UI, no hand-written test code — then reaches for the same binary to ask the Context Graph who else depends on an endpoint before changing it. That's illustrated, not re-typed live; the live part is what comes next. You clone a **real repository** backing `patients-service`, remove a real field from its contract, and open a real pull request. From there nobody prompts anything: a GitHub Action fires, a **headless agent** reads the diff, decides on its own that the change is risky, and reaches for `postman context-graph ask` — the exact capability from the slides — on its own initiative. While it thinks (20–40s), you switch to the Postman app and show the Context Graph UI for real. Then you read its verdict off the PR. Same binary, same capability, but this time nobody typed the prompt.

> **What this demo is not:** a Context Graph feature demo, and not a merge-blocking CI gate either. The headless agent doesn't block anything — it reports. The point is narrower and stronger: the CLI is the one channel an agent actually has into Postman, whether a human drives it or not.

> **Network reality:** everything from step 2 onward needs the network — a real GitHub repo, a real Actions run, a real Context Graph call. There is no offline fallback in this version of the demo; see [section 6](#6-troubleshooting) for what to do if the venue Wi-Fi is the problem, not the demo.

**Call to action (for attendees):**

- `npm install -g postman-cli@latest`, then `postman spec lint <your-spec>`
- Postman CLI: <https://www.postman.com/product/postman-cli/>
- API Context Graph: <https://www.postman.com/context-graph/>
- The live demo repo: <https://github.com/avdev4j/postman-cli-headless-agents>
- This talk's slides and setup tooling: `git clone https://github.com/Postman-Devrel/booth-demos.git` → `cd booth-demos/content/lightning-talks/postman-cli-headless-agents`

---

## 2. Pre-requisites

| Requirement | How to get it |
|---|---|
| **`git` and `gh`, authenticated** | `gh auth status`. You need push access to [avdev4j/postman-cli-headless-agents](https://github.com/avdev4j/postman-cli-headless-agents) to open the PR live — presenting under your own fork or a different demo repo means updating `DEMO_REPO` at the top of `scripts/setup.sh` and `scripts/teardown.sh`. |
| **The demo repo's own secrets, already set** | `POSTMAN_API_KEY` and `ANTHROPIC_API_KEY` as GitHub Actions secrets on the demo repo — `setup.sh` checks both exist (not their values) and fails loudly if either is missing. One-time; not something you redo per session. |
| **A Postman account, for step 5 only** | Logged into the Postman **app** (not the CLI) as a member of the team whose Context Graph has the estate ingested. This is just for narrating the UI while the agent runs — no `postman login` needed on your laptop, the headless agent's own CI logs in with the repo's secret. |

> **No local Postman CLI, no local Claude Code.** Neither runs on your laptop in this version of the demo — the headless agent runs both, inside the demo repo's own CI. Your laptop only needs to get a branch pushed and a PR opened.

---

## 3. Setup

```bash
./scripts/setup.sh
```

1. **The deck** exists and is a complete HTML file.
2. **Tooling**: `git`, `gh`, and that `gh` is authenticated.
3. **No leftover PR** from a previous rehearsal on the demo repo — fails if teardown didn't run last time.
4. **Both Actions secrets exist** on the demo repo (`POSTMAN_API_KEY`, `ANTHROPIC_API_KEY`) — fails with the exact `gh secret set` command if either is missing.
5. **A fresh clone** of the demo repo at `/tmp/postman-cli-headless-agents-demo`, replacing whatever was there.
6. **`main` still has `blood_type`** — sanity check that a previous rehearsal's change didn't reach `main` without a teardown.
7. **Opens the presentation and the demo repo's GitHub page** in the browser.

### Authentication

Nothing to log into locally. `gh auth status` is the only thing this script checks — it's what lets `setup.sh` clone the repo and check its secrets, and what lets you run `gh pr create` live on stage.

### Pre-demo checklist

- [ ] `./scripts/setup.sh` finished with no `[FAIL]` lines
- [ ] Deck open, fullscreen, on slide 1
- [ ] `github.com/avdev4j/postman-cli-headless-agents` open in a browser tab
- [ ] A Postman workspace with this team's Context Graph open in **another** tab — don't switch to it until step 5
- [ ] Terminal in `/tmp/postman-cli-headless-agents-demo`, large font (`Cmd+=`)
- [ ] No open PR yet on the demo repo

---

## 4. Talk track and click track

Five steps, 10 minutes. Talk track is **verbatim** (blockquotes) — read it if the room goes cold. Click track is interleaved at the exact point each action happens. The live part starts at **step 2** — steps 3 onward run in a real browser tab and a real terminal, not the deck.

> ⚠️ **Nobody prompts anything from step 3 onward.** That's the whole point of this cut of the talk — say it once, explicitly, right before you push: "I'm not going to tell it what to do next." Then don't narrate the CI job like you're driving it. You aren't.

### Step 1: the concept, on slides (~3 min)

> "Postman has a CLI. It's not a smaller version of the app — it's the version built for something that doesn't have eyes. Here's what an agent does with it, on an everyday API: lints the contract, generates a collection and a mock from it, runs the collection against the mock. No UI, no hand-written test. And here's the same binary reaching further: before changing an endpoint, the agent asks the Context Graph who else depends on it — something no local file could tell it."

- **Show:** slides 2–4 (capabilities, Build & Test, Beyond One Repo) — walked through, not typed live. If asked "why not run it," the honest answer: "you're about to watch the same capability run with nobody driving it — that's the more interesting version."
- **Show:** advance to slide 6 ("A Script Can Run the CLI. It Can't Judge the Diff.") — this is what's about to happen, in the browser, for real.

### Step 2: the real repo (~1 min)

> "This isn't a slide anymore. `patients-service` is a real API, in a real GitHub repo, with a real collection and mock already checked in."

- **Show:** switch to the browser tab on `github.com/avdev4j/postman-cli-headless-agents`. Point out [`openapi.yaml`](openapi.yaml), the checked-in collection under `postman/collections/`, and [`agents/headless-pr-agent.md`](agents/headless-pr-agent.md) — "this file is what the agent reasons through. Not a script — read it, it's five judgment calls, not five commands."

### Step 3: break it, for real (~2 min)

> "I'm about to remove `blood_type` from the patient contract. Clinical data, plausibly read by another system, never read by this service itself — so my own tests here stay green either way. That's the honest trap: locally, nothing looks wrong."

- **Do**, in `/tmp/postman-cli-headless-agents-demo`:
  ```bash
  git checkout -b remove-blood-type
  # remove the blood_type property from the Patient schema in openapi.yaml
  git add openapi.yaml
  git commit -m "Remove blood_type from the patient contract"
  git push -u origin remove-blood-type
  gh pr create --fill
  ```

> "And that's it. I'm not opening Postman, I'm not asking an agent anything. I just opened a pull request."

### Step 4: the headless agent takes over (~2 min)

- **Show:** switch to the PR in the browser, or the **Actions** tab.

> "Nobody prompted this. The PR opening is the trigger. Watch."

- **Show (payoff):** the checks run, then a comment lands on the PR from the headless agent — it read the diff, judged the change, and if it decided the change was risky, it called `postman context-graph ask` itself and reported what came back: real service names, real owning teams, the evidence for each.

> "That comment is the whole thesis: the same CLI capability from the slides, invoked by the agent's own judgment, not mine."

### Step 5: while it thinks, show the graph for real (~2 min)

The Context Graph reasons for 20–40s inside that job — dead air if you just wait on it.

- **Show:** switch to the Postman app, the Context Graph UI, for this team's estate.

> "This is what the agent is looking at right now, from the CLI, headless. It's not a lookup table — it's reasoning over real service-to-service calls, real ownership. That's what took twenty to forty seconds just now."

- **Show:** back to the PR — read the agent's comment out loud, verbatim. **Say what it actually says today**, not a number this README knows — it's live.

> ⚠️ **Field-level questions are out of scope, and that's honest, not a limitation to apologize for.** The graph knows who calls this endpoint. It does not know which JSON field in the response they read. If asked "can it tell me who reads *this specific field*," the honest answer is: not yet — and here's what it told you instead, which is still more than you had before opening the PR.

> "One pull request, and I know exactly who to go talk to before I ship this — reported by an agent I never prompted."

- **Show:** advance the deck to slide 5 (CTA).

### What to cut when you are over

If you're short on time: cut step 1 down to the thesis line and slide 6, and spend the saved time letting step 4's job actually finish live rather than narrating over it. **Never cut** reading the agent's comment out loud — that's the payoff landing.

---

## 5. Tear down / reset

```bash
./scripts/teardown.sh
```

Closes the PR opened on stage, deletes its branch on the demo repo, and removes the local clone at `/tmp/postman-cli-headless-agents-demo`. Safe to run when setup never ran.

**It deliberately leaves standing:** the demo repo's `main` branch and its Actions secrets, and the Postman team's Context Graph connection to the estate — shared infrastructure this session doesn't own.

Full reset between sessions:

```bash
./scripts/teardown.sh && ./scripts/setup.sh
```

---

## 6. Troubleshooting

| Issue | Fix |
|---|---|
| `setup.sh` fails: leftover open PR | A previous session's `teardown.sh` didn't run. Run it now, or close the PR by hand on `github.com/avdev4j/postman-cli-headless-agents/pulls`. |
| `setup.sh` fails: a secret is missing | Run the `gh secret set` command it prints. This is a one-time, per-repo setup — it shouldn't recur once both secrets exist. |
| `setup.sh` fails: `main` is already missing `blood_type` | A previous rehearsal's change reached `main` without a teardown. Open the file on `main` and put `blood_type` back by hand before presenting. |
| The Action job fails on `postman login` | Almost always a PR opened from a fork — GitHub does not pass secrets to fork PRs. Push the branch to the repo itself, not a fork, and open the PR from there. |
| The Action job fails on `claude -p` with an auth error | `ANTHROPIC_API_KEY` is missing or wrong on the demo repo. Re-issue it: `gh secret set ANTHROPIC_API_KEY --repo avdev4j/postman-cli-headless-agents`. |
| The PR comment says the graph doesn't know this API, or never mentions the graph at all | The `POSTMAN_API_KEY` behind the demo repo's secret isn't on a team with the estate ingested — re-issue the secret from an account that is. Separately: the agent only calls the graph if it judges the change risky; if it didn't ask, that's a real finding to narrate, not a bug. |
| No comment shows up on the PR at all | Check the **Actions** tab for the run's logs — the job may still be running (give it the full 20–40s), or it failed outright; the logs say which. |
| The deck does not open | Open `presentation/index.html` by hand. It is self-contained; only the fonts need the network. |

---

## 7. Additional resources

| Resource | Link |
|---|---|
| **The live demo repo** | <https://github.com/avdev4j/postman-cli-headless-agents> — clone it, break it, watch the agent |
| Its headless agent's instructions | [`agents/headless-pr-agent.md`](https://github.com/avdev4j/postman-cli-headless-agents/blob/main/agents/headless-pr-agent.md) |
| Its trigger | [`.github/workflows/headless-agent.yml`](https://github.com/avdev4j/postman-cli-headless-agents/blob/main/.github/workflows/headless-agent.yml) |
| Postman CLI | <https://www.postman.com/product/postman-cli/> |
| Postman CLI command reference | <https://learning.postman.com/docs/postman-cli/postman-cli-options> |
| Postman CLI installation | <https://learning.postman.com/docs/postman-cli/postman-cli-installation/> |
| API Context Graph | <https://www.postman.com/context-graph/> |
| The contract shown on the slides | [openapi.yaml](openapi.yaml) — same content as the demo repo's |
| Same product, different signal — the CLI as a test oracle | [../open-meteo-loop-eng/](../open-meteo-loop-eng/) |
