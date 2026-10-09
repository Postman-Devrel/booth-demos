# Postman plugin: an agent reviews your API change

> [Lightning talk](../../../templates/formats/lightning-talk.md) — target length **10 minutes**. Delivered at booths, meetups, and lightning tracks. This README is the single source of truth. Read it top to bottom before your first attendee; everything you need to run the demo without improvising is here.

---

## 1. Product summary

- **Product:** the [Postman Claude Code plugin](https://www.postman.com/liftoff/modules/claude-code-plugin/), backed by the same Postman skills and the [Postman CLI](https://www.postman.com/product/postman-cli/) underneath, with the [API Context Graph](https://www.postman.com/context-graph/) as the flagship example of what those skills let an agent reach for
- **Use case:** show where an agent's Postman know-how actually comes from. It isn't something you told it once in a chat. It's committed Postman skills, and they reach an agent two ways: the plugin installs them straight into a developer's own Claude Code, and `postman init` commits the same skills into a repository, so an agent running unattended in CI gets them too.
- **Audience:** developers building or supervising coding agents, and anyone who's wondered what a Postman plugin actually gives an agent that the app's UI does not.

**The thesis, in one line:**

> **An agent's Postman skills live in files, not in a chat history, and the same files reach a developer's own agent through the plugin and a CI agent through `postman init`.**

**The story (the narrative arc):**

> Say the thesis once, early, then make it concrete with the one line Postman's own CLI uses to describe it: "the Claude Code plugin delivers the same skills separately" (from `postman skills --help`). The **slides** carry both paths conceptually: the plugin installs committed Postman skills straight into a developer's own Claude Code, and `postman init` commits the same skills into a repo, where they reach a different agent, one nobody is prompting. That's illustrated, not typed live; the live part is what comes next. You clone a **real repository** backing `patients-service`, remove a real field from its contract, and open a real pull request. From there nobody prompts anything: a GitHub Action fires, the CI agent reads the diff, decides on its own that the change is risky, and reaches for `postman context-graph ask` on its own initiative. While it thinks (a handful of seconds to a few minutes, Context Graph results vary), you switch to the Postman app and show the Context Graph UI for real. Then you read its verdict off the PR.

> **What this demo is not:** a Context Graph feature demo, and not a merge-blocking CI gate either. The CI agent reports; it doesn't block anything. The point is narrower: committed Postman skills, not a chat history, are what let this agent reason on its own.

> **Network reality:** everything from step 2 onward needs the network, a real GitHub repo, a real Actions run, a real Context Graph call. There is no offline fallback in this version of the demo; see [section 6](#6-troubleshooting) for what to do if the venue Wi-Fi is the problem, not the demo.

**Call to action (for attendees):**

- `npx @postman/postman-plugin`, then ask your own agent to review your next API change
- Postman CLI: <https://www.postman.com/product/postman-cli/>
- API Context Graph: <https://www.postman.com/context-graph/>
- Claude Code Plugin module on Liftoff: <https://www.postman.com/liftoff/modules/claude-code-plugin/>
- Join the Postman community on Discord: <https://postman-community.com/kmg>
- The live demo repo: <https://github.com/Postman-Devrel/postman-plugin-pr-review-demo>
- This talk's slides and setup tooling: `git clone https://github.com/Postman-Devrel/booth-demos.git` → `cd booth-demos/content/lightning-talks/postman-plugin-pr-review`

---

## 2. Pre-requisites

| Requirement | How to get it |
|---|---|
| **`git` and `gh`, authenticated** | `gh auth status`. You need push access to [Postman-Devrel/postman-plugin-pr-review-demo](https://github.com/Postman-Devrel/postman-plugin-pr-review-demo) to open the PR live, presenting under your own fork or a different demo repo means updating `DEMO_REPO` at the top of `scripts/setup.sh` and `scripts/teardown.sh`. |
| **The demo repo's own secrets, already set** | `POSTMAN_API_KEY` and `ANTHROPIC_API_KEY` as GitHub Actions secrets on the demo repo, `setup.sh` checks both exist (not their values) and fails loudly if either is missing. One-time; not something you redo per session. |
| **A Postman account, for step 5 only** | Logged into the Postman **app** (not the CLI) as a member of the team whose Context Graph has the estate ingested. This is just for narrating the UI while the CI agent runs, no `postman login` needed on your laptop, the CI agent's own job logs in with the repo's secret. |

> **No local Postman CLI, no local Claude Code.** Neither runs on your laptop in this version of the demo, the CI agent runs both, inside the demo repo's own CI. Your laptop only needs to get a branch pushed and a PR opened.

---

## 3. Setup

```bash
./scripts/setup.sh
```

1. **The deck** exists and is a complete HTML file.
2. **Tooling**: `git`, `gh`, and that `gh` is authenticated.
3. **No leftover PR** from a previous rehearsal on the demo repo, fails if teardown didn't run last time.
4. **Both Actions secrets exist** on the demo repo (`POSTMAN_API_KEY`, `ANTHROPIC_API_KEY`), fails with the exact `gh secret set` command if either is missing.
5. **A fresh clone** of the demo repo at `/tmp/postman-plugin-pr-review-demo`, replacing whatever was there.
6. **`main` still has `blood_type`**: sanity check that a previous rehearsal's change didn't reach `main` without a teardown.
7. **Opens the presentation and the demo repo's GitHub page** in the browser.

### Authentication

Nothing to log into locally. `gh auth status` is the only thing this script checks, it's what lets `setup.sh` clone the repo and check its secrets, and what lets you run `gh pr create` live on stage.

### Pre-demo checklist

- [ ] `./scripts/setup.sh` finished with no `[FAIL]` lines
- [ ] Deck open, fullscreen, on slide 1
- [ ] `github.com/Postman-Devrel/postman-plugin-pr-review-demo` open in a browser tab
- [ ] A Postman workspace with this team's Context Graph open in **another** tab, don't switch to it until step 5
- [ ] Terminal in `/tmp/postman-plugin-pr-review-demo`, large font (`Cmd+=`)
- [ ] No open PR yet on the demo repo

---

## 4. Talk track and click track

Five steps, 10 minutes. Talk track is **verbatim** (blockquotes), read it if the room goes cold. Click track is interleaved at the exact point each action happens. The live part starts at **step 2**, steps 3 onward run in a real terminal and a real browser tab, not the deck.

> ⚠️ **Nobody prompts anything from step 3 onward.** That's the whole point of this cut of the talk, say it once, explicitly, right before you push: "I'm not going to tell it what to do next." Then don't narrate the CI job like you're driving it. You aren't.

### Step 1: the concept, on slides (~2 min)

> "An agent's Postman skills don't live in a chat history. They live in files, and those files can reach an agent two ways. Install the Postman plugin in Claude Code, and your own agent gets them. Run `postman init` in a repo, and the same skills get committed there, so an agent running in CI, with nobody watching, gets them too. What's next shows the second one, live, end to end."

- **Show:** slides 2 to 4 (capabilities, build and test, the two paths skills take) walked through, not typed live.
- **Show:** advance to slide 5 ("A script can run the CLI. It can't judge the diff.") as the bridge into the live part.

### Step 2: the real repo (~1 min)

> "`patients-service` is a real API, in a real GitHub repo. It already has `AGENTS.md` at its root, the Postman skills `postman init` committed under `postman/skills/`, and an agent prompt that reasons through a change instead of listing commands."

- **Show:** switch to the browser tab on `github.com/Postman-Devrel/postman-plugin-pr-review-demo`. Point out [`openapi.yaml`](openapi.yaml), `AGENTS.md`, the `postman/skills/` directory, and [`agents/api-change-reviewer.md`](agents/api-change-reviewer.md), "read this file, it never names a single Postman command, it points at the skills instead. Not a script, five judgment calls."

### Step 3: break it, for real (~2 min)

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

### Step 4: the CI agent takes over (~2 min)

- **Show:** switch to the PR in the browser, or the **Actions** tab.

> "The PR is open. From this exact moment, nobody prompts anything. The PR opening is the trigger. Watch."

- **Show (payoff):** the checks run, then a comment lands on the PR from the CI agent, it read the diff, judged the change, and if it decided the change was risky, it called `postman context-graph ask` itself and reported what came back: real service names, and whatever it could or couldn't confirm about ownership.

> "The same skills the plugin would hand to my own agent, committed into the repo instead, for an agent I'm not sitting in front of."

### Step 5: while it thinks, show the graph for real (~1 to 2 min)

The Context Graph call inside that CI job can take anywhere from a few seconds to a few minutes, dead air if you just wait on it.

- **Show:** switch to the Postman app, the Context Graph UI, for this team's estate.

> "This is what the CI agent is looking at right now. It's not a lookup table, it's reasoning over real service-to-service calls. That's what's happening behind that spinner."

- **Show:** back to the PR, read the agent's comment out loud, verbatim. **Say what it actually says today**, not a number this README knows, it's live.

> ⚠️ **Field-level questions are out of scope, and that's honest, not a limitation to apologize for.** The graph knows who calls this endpoint. It doesn't know which JSON field in the response they read. If asked "can it tell me who reads *this specific field*," the honest answer is: not yet, and here's what it told you instead, which is still more than you had before opening the PR.

> "One pull request, two agents, and I know exactly who to go talk to before I ship this, reported by an agent I never prompted."

- **Show:** advance the deck to the CTA slide.

### What to cut when you are over

If you're short on time: cut step 1 down to the thesis line and slide 5, and spend the saved time letting step 4's job actually finish live rather than narrating over it. **Never cut** reading the CI agent's comment out loud, that's the payoff landing.

---

## 5. Tear down / reset

```bash
./scripts/teardown.sh
```

Closes the PR opened on stage, deletes its branch on the demo repo, and removes the local clone at `/tmp/postman-plugin-pr-review-demo`. Safe to run when setup never ran.

**It deliberately leaves standing:** the demo repo's `main` branch and its Actions secrets, and the Postman team's Context Graph connection to the estate, shared infrastructure this session doesn't own.

Full reset between sessions:

```bash
./scripts/teardown.sh && ./scripts/setup.sh
```

---

## 6. Troubleshooting

| Issue | Fix |
|---|---|
| `setup.sh` fails: leftover open PR | A previous session's `teardown.sh` didn't run. Run it now, or close the PR by hand on `github.com/Postman-Devrel/postman-plugin-pr-review-demo/pulls`. |
| `setup.sh` fails: a secret is missing | Run the `gh secret set` command it prints. This is a one-time, per-repo setup, it shouldn't recur once both secrets exist. |
| `setup.sh` fails: `main` is already missing `blood_type` | A previous rehearsal's change reached `main` without a teardown. Open the file on `main` and put `blood_type` back by hand before presenting. |
| The Action job fails on `postman login` | Almost always a PR opened from a fork, GitHub does not pass secrets to fork PRs. Push the branch to the repo itself, not a fork, and open the PR from there. |
| The Action job fails on `claude -p` with an auth error | `ANTHROPIC_API_KEY` is missing or wrong on the demo repo. Re-issue it: `gh secret set ANTHROPIC_API_KEY --repo Postman-Devrel/postman-plugin-pr-review-demo`. |
| The PR comment says the graph doesn't know this API, or never mentions the graph at all | The `POSTMAN_API_KEY` behind the demo repo's secret isn't on a team with the estate ingested, re-issue the secret from an account that is. Separately: the agent only calls the graph if it judges the change risky; if it didn't ask, that's a real finding to narrate, not a bug. |
| No comment shows up on the PR at all | Check the **Actions** tab for the run's logs, the job may still be running, or it failed outright; the logs say which. A run that reports success but shows no commands and no comment is itself a known failure mode of an earlier cut of the workflow's logging, not expected behavior today. |
| The deck does not open | Open `presentation/index.html` by hand. It is self-contained; only the fonts need the network. |

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
| Same product, different signal, the CLI as a test oracle | [../open-meteo-loop-eng/](../open-meteo-loop-eng/) |
