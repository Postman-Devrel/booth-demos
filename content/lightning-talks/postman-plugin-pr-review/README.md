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

> Say the thesis once, early, then make it concrete with the one line Postman's own CLI uses to describe it: "the Claude Code plugin delivers the same skills separately" (from `postman skills --help`). Then show both halves live. First, your own Claude Code session, with the plugin installed, gets one plain-English instruction: remove a field from a real API contract, commit it, push it, open a pull request. You give that instruction and then you stop typing. While your agent reads the repo's skills, checks the Context Graph, and works through the change, you talk through the second half on slides: the same contract, the same skills, but committed into the repo itself and handed to a different agent, one nobody is sitting in front of. The pull request lands, a GitHub Action fires, and from that moment nobody prompts anything. The CI agent reads the diff, decides on its own whether it's risky, and if it is, reaches for `postman context-graph ask` on its own initiative. While it thinks (a handful of seconds to a few minutes, Context Graph results vary), you switch to the Postman app and show the Context Graph UI for real. Then you read its verdict off the PR.

> **What this demo is not:** a Context Graph feature demo, and not a merge-blocking CI gate either. The CI agent reports; it doesn't block anything. The point is narrower: the same committed skills can reach an agent two different ways, and both times the agent decides for itself what to do with them.

> **Network reality:** everything from step 2 onward needs the network, a real GitHub repo, a real Claude Code session, a real Actions run, a real Context Graph call. There is no offline fallback in this version of the demo; see [section 6](#6-troubleshooting) for what to do if the venue Wi-Fi is the problem, not the demo.

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
| **Claude Code, with the Postman plugin installed** | `claude plugin list` should list `postman` as enabled. Install or update it with `npx @postman/postman-plugin`. This is what gives your own agent the Postman skills in step 3, no chat history required. |
| **The Postman CLI, installed and logged in locally** | `postman whoami`. In rehearsal, the plugin-backed agent called the Postman CLI directly (`context-graph ask`, `spec lint`, `mock generate`, `collection run`), it doesn't just read the plugin's own files. If the CLI isn't on your path or isn't logged in, the agent will stop to ask about it mid-demo. |
| **The demo repo's own secrets, already set** | `POSTMAN_API_KEY` and `ANTHROPIC_API_KEY` as GitHub Actions secrets on the demo repo, `setup.sh` checks both exist (not their values) and fails loudly if either is missing. One-time; not something you redo per session. |
| **A Postman account, for narrating the Context Graph UI** | Logged into the Postman **app** (not the CLI) as a member of the team whose Context Graph has the estate ingested. Your own personal Postman account's Context Graph may well have none of this ingested, see the callout in step 3 for what to say if that happens. |

---

## 3. Setup

```bash
./scripts/setup.sh
```

1. **The deck** exists and is a complete HTML file.
2. **Tooling**: `git`, `gh`, and that `gh` is authenticated.
3. **Claude Code and the Postman plugin**: `claude --version` runs, and `claude plugin list` shows `postman` as enabled.
4. **The Postman CLI**: `postman whoami` succeeds, confirming you're logged in locally.
5. **No leftover PR** from a previous rehearsal on the demo repo, fails if teardown didn't run last time.
6. **Both Actions secrets exist** on the demo repo (`POSTMAN_API_KEY`, `ANTHROPIC_API_KEY`), fails with the exact `gh secret set` command if either is missing.
7. **A fresh clone** of the demo repo at `/tmp/postman-plugin-pr-review-demo`, replacing whatever was there.
8. **`main` still has `blood_type`**: sanity check that a previous rehearsal's change didn't reach `main` without a teardown.
9. **Opens the presentation and the demo repo's GitHub page** in the browser.

### Authentication

`gh auth status` is what lets `setup.sh` clone the repo and check its secrets, and what lets you run `gh pr create` live if you fall back to the manual commands in step 3. `claude plugin list` and `postman whoami` confirm your own agent is ready to go: neither logs anything in for you, they only report whether you already are.

### Pre-demo checklist

- [ ] `./scripts/setup.sh` finished with no `[FAIL]` lines
- [ ] Deck open, fullscreen, on slide 1
- [ ] `github.com/Postman-Devrel/postman-plugin-pr-review-demo` open in a browser tab
- [ ] A Postman workspace with this team's Context Graph open in **another** tab, don't switch to it until step 4
- [ ] Terminal in `/tmp/postman-plugin-pr-review-demo`, large font (`Cmd+=`), with Claude Code already set to accept edits or bypass permission prompts so you aren't approving every tool call live
- [ ] No open PR yet on the demo repo

---

## 4. Talk track and click track

Five steps, 10 minutes. Talk track is **verbatim** (blockquotes), read it if the room goes cold. Click track is interleaved at the exact point each action happens. The live part starts at **step 2**, steps 3 onward run in a real terminal and a real browser tab, not the deck.

> ⚠️ **Step 3 is you prompting your own agent, out loud, on purpose.** That's the first half of the point: a developer asking their own Claude Code, with the Postman plugin, to make a change. **The "nobody prompts anything" guarantee starts once the PR from step 3 is open**, say that explicitly right before you switch to the CI tab: "from here, nobody tells it what to do next."

### Step 1: the concept, on slides (~2 min)

> "An agent's Postman skills don't live in a chat history. They live in files, and those files can reach an agent two ways. Install the Postman plugin in Claude Code, and your own agent gets them. Run `postman init` in a repo, and the same skills get committed there, so an agent running in CI, with nobody watching, gets them too. Watch both halves."

- **Show:** slides 2 to 4 (capabilities, build and test, the two paths skills take) walked through, not typed live.
- **Show:** advance to slide 5 ("A script can run the CLI. It can't judge the diff.") as the bridge into the live part.

### Step 2: the real repo (~1 min)

> "`patients-service` is a real API, in a real GitHub repo. It already has `AGENTS.md` at its root, the Postman skills `postman init` committed under `postman/skills/`, and an agent prompt that reasons through a change instead of listing commands."

- **Show:** switch to the browser tab on `github.com/Postman-Devrel/postman-plugin-pr-review-demo`. Point out [`openapi.yaml`](openapi.yaml), `AGENTS.md`, the `postman/skills/` directory, and [`agents/api-change-reviewer.md`](agents/api-change-reviewer.md), "read this file, it never names a single Postman command, it points at the skills instead. Not a script, five judgment calls."

### Step 3: ask your own agent to make the change (~2 to 3 min, mostly in the background)

> "I'm going to ask my own Claude Code, with the Postman plugin, to do this: remove `blood_type` from the patient contract, commit it, push it, open the pull request. I'll give it that instruction once, then I'm not touching the keyboard again until there's a PR to look at."

- **Do**, in `/tmp/postman-plugin-pr-review-demo`, in a Claude Code session:
  > "Remove the `blood_type` field from the Patient schema in openapi.yaml, commit it on a new branch called remove-blood-type, push it and open a pull request."

> ⚠️ **This step ran 5 to 12 minutes end to end in rehearsal**, most of it the agent reading skills, checking the Context Graph, and reasoning, not something worth watching in silence. Give the prompt, then move straight to narrating step 1's second half on slides (the `postman init` path, the same skills reaching the CI agent) while it works in the background pane. Check back on it once you've made that point.

> ⚠️ **If the Context Graph comes back with nothing for this service, that's expected, not a bug.** Rehearsal confirmed it: under a personal Postman account, `context-graph ask` returns no data for this service at all, while the demo repo's own CI key (on a team with the estate ingested) sees dozens of callers. If your agent flags the check as inconclusive instead of claiming the change is safe, that's the honest behavior to point at, read it out loud.

> ⚠️ **If the agent is still going after a few minutes, or starts asking you more than one or two questions, switch to the manual commands instead of waiting it out:**
  ```bash
  git checkout -b remove-blood-type
  # remove the blood_type property from the Patient schema in openapi.yaml
  git add openapi.yaml
  git commit -m "Remove blood_type from the patient contract"
  git push -u origin remove-blood-type
  gh pr create --fill
  ```

### Step 4: the CI agent takes over (~2 min)

- **Show:** switch to the PR in the browser, or the **Actions** tab.

> "The PR is open. From this exact moment, nobody prompts anything. The PR opening is the trigger. Watch."

- **Show (payoff):** the checks run, then a comment lands on the PR from the CI agent, it read the diff, judged the change, and if it decided the change was risky, it called `postman context-graph ask` itself and reported what came back: real service names, and whatever it could or couldn't confirm about ownership.

> "Same skills, same CLI underneath, but this time committed into the repo for an agent I'm not sitting in front of."

### Step 5: while it thinks, show the graph for real (~1 to 2 min)

The Context Graph call inside that CI job can take anywhere from a few seconds to a few minutes, dead air if you just wait on it.

- **Show:** switch to the Postman app, the Context Graph UI, for this team's estate.

> "This is what the CI agent is looking at right now. It's not a lookup table, it's reasoning over real service-to-service calls. That's what's happening behind that spinner."

- **Show:** back to the PR, read the agent's comment out loud, verbatim. **Say what it actually says today**, not a number this README knows, it's live.

> ⚠️ **Field-level questions are out of scope, and that's honest, not a limitation to apologize for.** The graph knows who calls this endpoint. It doesn't know which JSON field in the response they read. If asked "can it tell me who reads *this specific field*," the honest answer is: not yet, and here's what it told you instead, which is still more than you had before opening the PR.

> "One pull request, two agents, and I know exactly who to go talk to before I ship this, reported by an agent I never prompted."

- **Show:** advance the deck to the CTA slide.

### What to cut when you are over

If you're short on time: cut step 1 down to the thesis line and slide 5, and let the manual fallback in step 3 fire immediately instead of waiting on the plugin. **Never cut** reading the CI agent's comment out loud, that's the payoff landing.

---

## 5. Tear down / reset

```bash
./scripts/teardown.sh
```

Closes the PR opened on stage, deletes its branch on the demo repo, and removes the local clone at `/tmp/postman-plugin-pr-review-demo`. Safe to run when setup never ran.

**It deliberately leaves standing:** the demo repo's `main` branch and its Actions secrets, your local Claude Code and Postman CLI installs, and the Postman team's Context Graph connection to the estate, shared infrastructure this session doesn't own.

Full reset between sessions:

```bash
./scripts/teardown.sh && ./scripts/setup.sh
```

---

## 6. Troubleshooting

| Issue | Fix |
|---|---|
| `setup.sh` fails: the Postman plugin isn't installed or isn't loaded | `claude plugin list` won't show `postman` as enabled. Run `npx @postman/postman-plugin`, then restart Claude Code before going on stage. |
| `setup.sh` fails: `postman whoami` fails | Run `postman login` locally first. The plugin-backed agent in step 3 calls the Postman CLI directly, so it needs a real session, not just the plugin installed. |
| The local agent in step 3 asks too many questions, or is taking too long | Don't wait it out mid-demo. Switch to the manual commands printed in step 3 and open the PR yourself, the rest of the click track doesn't care which way the PR got opened. |
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
| **The live demo repo** | <https://github.com/Postman-Devrel/postman-plugin-pr-review-demo>, clone it, break it, watch both agents |
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
