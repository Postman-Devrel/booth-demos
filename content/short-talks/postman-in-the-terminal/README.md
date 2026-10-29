# Postman in the terminal

> The 10-minute booth cut of this talk lives in [content/lightning-talks/postman-in-the-terminal/](../../lightning-talks/postman-in-the-terminal/). It was written for the previous demo (bare spec, then a CI agent that comments), so check it against this README before you use it on the floor.

> [Short talk](../../../templates/formats/short-talk.md) — target length **28 minutes (Q&A included)**. Delivered at meetups and conference breakouts. This README is the single source of truth. Read it top to bottom before your first attendee; everything you need to run the demo without improvising is here.

---

## 1. Product summary

- **Product:** the [Postman Claude Code plugin](https://www.postman.com/liftoff/modules/claude-code-plugin/), backed by the same Postman skills and the [Postman CLI](https://www.postman.com/product/postman-cli/) underneath, with the [API Context Graph](https://www.postman.com/context-graph/) as the source of "who consumes this API".
- **Use case:** a platform team (here, the fictional `healthcare-org-app`) turns Postman building blocks into an **API quality gate** that every service calls from its own CI, and the developer's own coding agent fixes its API changes against that gate. **The gate is the healthcare org's own use case, built with Postman. It is not a Postman product.** The talk is about the building blocks: committed Postman skills, the CLI, the Context Graph, and the plugin that carries them to an agent.
- **Audience:** developers building or supervising coding agents, platform and API-governance teams, and anyone who has wondered what a Postman plugin gives an agent that the app's UI does not.

**The thesis, in one line:**

> **A coding agent doesn't need Postman's UI. It needs a command per step, committed skills that tell it which one to run, and a gate it can't edit, and Postman gives you the first two.** The rules of the loop live in files (the gate plugin's `gate-loop` skill, a short `CLAUDE.md`), not in a prompt.

**The story (the narrative arc):**

> Open on the pyramid of agentic API engineering: the API engineering chain, then what an agent needs from a tool to work that chain (a command per step, readable output, no human in the loop), then the Postman CLI and MCP, then the Postman plugin, then `postman init` committing the same skills into a repo. Those are slides 1 to 14. Then the demo runs on one **real repo**, `healthcare-org-app/healthcare-patients` (`patients-service`, Python/Flask, port 8100), which already has everything in files: the contract, a v3 collection with assertions, the skills `postman init` wrote, a short `CLAUDE.md` that points to the gate loop, and the platform team's quality gate in CI. There is no coding agent in the repo: the coder is your own Claude Code session (Postman plugin + the platform team's gate plugin). You rename one field "for readability" and open a PR. Nothing local looks wrong, and the gate fails it: rating D, contract tests and impact blocking. Then you ask your own session to run the gate loop: the read-only `gate-verdict` agent reads the verdict and writes a fixes brief, your session applies it, and it iterates (3 rounds at most). Two honest endings: the gate passes, or the loop stops with NEEDS_DECISION and a draft PR (a human decides). You do not merge. You open the gate's repo and show that each step is one Postman CLI command, then the Context Graph in the Postman app, which is how the gate knows who the rename breaks.

> **The quality delta.** The gate's comment now opens with the API quality change against the base branch ("API quality is lowered by 22 % from main"), then the change risk. This answers the question "what is the evidence that it improves quality by x %?": per PR, the gate says how much quality moves against `main`; aggregated over PRs, it becomes org-level evidence. See the format in act 5a.

> **What this demo is not:** a Postman feature tour, and not "Postman ships a quality gate". The gate is one team's use case, assembled from the CLI, skills and Context Graph. The point is how little glue it took, and that the agent can't cheat on it.

> **Network reality:** the whole live demo needs the network (GitHub Actions, the Postman cloud for lint governance and the Context Graph). There is no offline fallback. See [section 6](#6-troubleshooting).

**Call to action (for attendees):**

- `npx @postman/postman-plugin`, then ask your own agent to work an API change
- Postman CLI: <https://www.postman.com/product/postman-cli/>
- API Context Graph: <https://www.postman.com/context-graph/>
- Claude Code Plugin module on Liftoff: <https://www.postman.com/liftoff/modules/claude-code-plugin/>
- Join the Postman community on Discord: <https://postman-community.com/kmg>
- The two repos of the demo: <https://github.com/healthcare-org-app/healthcare-patients> (the service) and <https://github.com/healthcare-org-app/healthcare-api-quality-gate> (the platform team's gate)
- This talk's slides and setup tooling: `git clone https://github.com/Postman-Devrel/booth-demos.git` → `cd booth-demos/content/short-talks/postman-in-the-terminal`

---

## 2. Pre-requisites

| Requirement | How to get it |
|---|---|
| **Claude Code, the Postman CLI, `git`, `gh`, `python3`** | `setup.sh` checks all of them. `gh auth status` must pass: you need push access to [healthcare-org-app/healthcare-patients](https://github.com/healthcare-org-app/healthcare-patients) to push the branch and open the PR live. |
| **Postman CLI logged in** | `postman login` before you present, on a team whose Context Graph has `healthcare-org-app` ingested. The local gate run in the gate loop needs it (`setup.sh` only WARNs if `postman whoami` fails). |
| **The org-level `POSTMAN_API_KEY` secret** | Already set at the `healthcare-org-app` organization level and used by the gate's workflow in CI. Nothing to set per session. A repo-level secret with the same name would shadow it, see [section 6](#6-troubleshooting). |
| **The gate plugin installed at user level** (gate 0.6.2 or later) | `claude plugin marketplace add healthcare-org-app/healthcare-api-quality-gate` then `claude plugin install healthcare-api-quality-gate@healthcare-api-quality-gate`. Check with `claude plugin list`. **Why user level:** a built-in Claude Code security hook deletes `.claude/settings.json` in a clone it considers untrusted (it writes `.claude/.settings-security-marker`), so the repo-level plugin enablement doesn't apply. |
| **The old `postman-agent-quality-gate` plugin (0.4.0) disabled** | `claude plugin disable postman-agent-quality-gate@postman-agent-quality-gate` (or uninstall it). While it is enabled it loads a duplicate `gate-loop` and `gate-verdict`. `setup.sh` WARNs if it is still enabled. |
| **The Postman plugin** | `postman@claude-plugins-official`, the plugin the talk is about. Your session uses it for the Postman work (the `postman:api-engineer` skill). |
| **The Postman app, logged in** | Same team as the CLI. Used for act 6, the Context Graph UI. |
| **The deck** | A local file, `presentation/index.html`, built from the Claude Design deck "From Click to Terminal". No sign-in needed. |

> **The gate is not the thing you installed.** Nothing to install for the gate itself: it runs in the repo's CI (reusable workflow `gate.yml@v1`) and locally through `npx github:healthcare-org-app/healthcare-api-quality-gate#v1 run`, which needs Node 22.

> **Presenter note from the CI rehearsals** (2026-10-29, gate 0.6.0 and 0.6.1: same results; gate 0.6.2, released the same day, changed the comment's format and was verified in CI on the passing round only).
> Write a PR body when you open the PR (act 4b): the loop reads the title and body as the intent to preserve, and `gh pr create --fill` gives an empty body. Use `gh pr create --title … --body …`.

> **Git hygiene in the clone.** The security hook leaves a deleted `.claude/settings.json` in the working tree. **Never `git add -A`** in the clone (it would commit that deletion): `git add openapi.yaml` only.

---

## 3. Setup

```bash
./scripts/setup.sh
```

1. **The deck** exists at `presentation/index.html` and is a complete HTML file.
2. **Tooling**: `git`, `gh` (authenticated), `claude`, `postman`, `python3`. A `WARN` if `postman whoami` says you aren't logged in.
   **Plugins** (`claude plugin list`): `healthcare-api-quality-gate` must be enabled (`FAIL` with the install commands if not); `WARN` if the old `postman-agent-quality-gate` is still enabled.
3. **No leftover demo** on `healthcare-org-app/healthcare-patients`: refuses to continue if there is an open PR or a remote branch matching `demo/live-*`.
4. **A fresh clone** at `/tmp/healthcare-patients`, replacing whatever was there. The folder name matters: with `-demo` in it, the reviewer once guessed the repo from the folder name.
5. **`main` still has `mrn`** in the `Patient` schema of `openapi.yaml`: sanity check that a rehearsal didn't reach `main`.
6. **Opens** the deck, the patients repo and the gate repo.

It only reads GitHub and clones to `/tmp`. It never pushes and never opens a PR.

### Pre-demo checklist

- [ ] `./scripts/setup.sh` finished with no `[FAIL]` lines
- [ ] `postman login` done, same team in the Postman app
- [ ] Deck open, fullscreen, on slide 1
- [ ] `claude plugin list`: `healthcare-api-quality-gate` enabled, `postman-agent-quality-gate` (0.4.0) not
- [ ] Browser tabs: patients repo, gate repo (`healthcare-org-app/healthcare-api-quality-gate`), and the Postman app on the Context Graph for `patients-service` (**another** window, don't switch before act 6)
- [ ] Terminal tab 1 in `/tmp/healthcare-patients`, large font (`Cmd+=`): the manual change (act 4)
- [ ] Terminal tab 2 in `/tmp/healthcare-patients` running `claude`: your own session for the gate loop (act 5), with the Postman plugin and the gate plugin (`/plugin`)
- [ ] No open PR yet, no `demo/live-*` branch on the patients repo
- [ ] Optional dry run the day before on a throwaway branch, then `./scripts/teardown.sh`

---

## 4. Talk track and click track

Nine acts, 28 minutes (Q&A included). Talk track is **verbatim** (blockquotes), read it if the room goes cold. Click track is interleaved at the exact point each action happens.

The deck is `presentation/index.html`, 18 slides, from the Claude Design deck "From Click to Terminal". **The live demo starts at slide 15, "Live demo"**: that is the handoff point, the moment you leave the deck for a real terminal and a browser. You come back to slides 16 to 18 after act 6.

| Act | Purpose | Slide(s) | Budget |
|---|---|---|---|
| 1 | **Cold open** — the agent that knows the CLI but not your API's rules | 01 Title, 02 Pyramid, 03 API engineering chain | 2–3 min |
| 2 | **Why it happens** — what an agent sees, and what it needs from a tool | 04 What an agent sees, 05 What an agent needs | 3 min |
| 3 | **The idea** — a command per step, skills in files, two ways in | 06 Pyramid CLI, 07 Every step has a command, 08 One command, two readers, 09 CLI first, MCP otherwise, 10 Pyramid plugin, 11 What the CLI alone does not give, 12 Plugin architecture, 13 How the agent picks a skill, 14 `postman init` | 3 min (about 15 s per slide, walk fast) |
| 4 | **Demo, part 1** — the workspace in files, then the manual change that tanks the rating (**live demo starts at slide 15**) | 15 Live demo | 5 min |
| 5 | **Demo, part 2** — the gate result, then the gate loop fixes it | — (live terminal and browser) | 7 min |
| 6 | **Demo, part 3** — the gate's own repo, then the Context Graph | — (live terminal and browser) | 3 min |
| 7 | **What you just saw, and what it costs** — upkeep | 16 What you just saw | 2 min |
| 8 | **Objections** — the questions you know you'll be asked | 17 What to take away (backup: Q&A) | 2–3 min |
| 9 | **Close + CTA** | 18 Try it | 1–2 min |

Total: 28 minutes at the low end of each range, about 30 at the high end. The slot is 28 with Q&A, so plan on the low end. See [What to cut](#what-to-cut-when-you-are-over).

> **Reading the table.** Act 4 groups two things the user asked for in order: *present the workspace* (about 2 min) and *make the change by hand* (about 3 min). Act 5 is *show the gate result* (about 2 min) then *the gate loop* (about 5 min, mostly Claude Code working: narrate, don't wait in silence). Act 6 is the gate repo (about 2 min) then the Context Graph (about 1 min).

### Act 1: Cold open (~2–3 min)

> "Ask a coding agent to rename a field in an API. It will do it, cleanly, in thirty seconds. The code compiles, the tests it wrote pass. And it has just broken thirty-two other services it has never heard of. Nothing it can see tells it so."

- **Show:** slide 01 (title), slide 02 (the pyramid of agentic API engineering: the whole talk is walking up it), slide 03 (the API engineering chain: design, mock, test, document, monitor, discover).

### Act 2: Why it happens (~3 min)

> "This is not a model problem. An agent sees files and a terminal. The consumers of your API are not in the repo. And a click in a UI is a step it can't take. What it needs from a tool is a command per step, with output it can read, and no human in the loop."

- **Show:** slide 04 (what an agent sees), slide 05 (what an agent needs).

### Act 3: The idea (~3 min)

> "So the answer isn't a smarter agent, it's a better toolbox. Every step of that chain is one Postman CLI command. The skills that say which command, and when, are files, committed in the repo. The Postman plugin puts them in your own Claude Code; `postman init` commits the same skills into a repo, so any agent that works there gets them, an unattended one in CI included. Here's what that gives you in practice."

- **Show:** slides 06 to 09 (the CLI: every step has a command, one command read by a human or an agent, CLI first and MCP otherwise), then slides 10 to 13 (the plugin: what the CLI alone doesn't give, the architecture, how an agent picks a skill), then slide 14 (`postman init`). Walk them, don't read them.
- **Show:** advance to slide 15, **Live demo**. This is the handoff.

### Act 4: Demo, part 1 — the workspace in files, then a harmless-looking change (~5 min)

#### 4a. Present the workspace (~2 min)

> "This is `patients-service`, a real repo of a made-up healthcare org. A Python and Flask API on port 8100. Look at it as a Postman workspace, except everything is a file."

- **Do:** in terminal tab 1 (`/tmp/healthcare-patients`), `ls -A`, then open the files below in your editor or the GitHub tab. One sentence each:
  - `openapi.yaml`: the contract.
  - `postman/collections/Patients API/`: the v3 collection, one YAML file per request, with `pm.test` assertions.
  - `.postman/resources.yaml`: tells the Postman CLI where the spec and the collection are.
  - `postman/skills/` and `AGENTS.md`: written by `postman init`. The agent's Postman know-how, committed.
  - `CLAUDE.md`: short, and it points to `healthcare-api-quality-gate:gate-loop`. Say: "the rules come from the platform team's plugin, not from this repo."
  - `quality-gate.yml` and `.github/workflows/quality-gate.yml`: the gate's config and the caller of its reusable workflow.

> "There is no coding agent in this repo. The coder is my own Claude Code, with the Postman plugin and the platform team's gate plugin."

> "One honest note: this repo isn't linked to a Postman cloud workspace yet, `workspace.id` is empty in `.postman/resources.yaml`. So what you see is the local, git-native workspace. Linking a cloud workspace is a follow-up, and the gate doesn't need it."

#### 4b. Make a change by hand (~3 min)

> "Now I'm the developer having a tidy-up afternoon. `mrn` is cryptic. `medical_record_number` reads better. I'll rename it in the responses. Request bodies I leave alone, I'm being careful."

- **Do**, in `/tmp/healthcare-patients`:
  ```bash
  git checkout -b demo/live-rename-mrn
  ```
  Then in `openapi.yaml`, rename `mrn` to `medical_record_number` on the **response** side only:
  - the `Patient` schema: the `required` list, the property itself, its `example`, and the schema description that mentions `mrn`
  - the `mrn:` keys in the response examples of `PatientPage`, `PatientSearchResult` and `PatientSummary`

  Leave `PatientCreateRequest` and `PatientUpdateRequest` alone.
  ```bash
  git add openapi.yaml
  git commit -m "Rename mrn to medical_record_number in patient responses"
  git push -u origin demo/live-rename-mrn
  gh pr create --title "Rename mrn to medical_record_number in patient responses" --body "Consumers should get medical_record_number."
  ```

> **Write a PR body.** `gh pr create --fill` leaves the body empty, and the loop reads the PR title and body as the intent to preserve.

> "A readability clean-up. Nothing local looks wrong: my code still runs, I didn't touch a test. Open the PR."

### Act 5: Demo, part 2 — the gate, then the gate loop (~7 min)

#### 5a. The gate result (~2 min)

- **Show:** the PR in the browser, then the **Actions** run for it. The gate's sticky comment appears, titled "API quality gate" (marker `<!-- healthcare-api-quality-gate -->`). It takes a couple of minutes: while it runs, say what it is.

> "This check isn't mine, and it isn't the agent's. It's the platform team's quality gate. Every service that adopts it calls it from its own CI, patients and appointments today. Every step is a Postman CLI command."

- **Timing:** the first comment lands about 83 seconds after the push (CI rehearsals of 2026-10-29, gate 0.6.0 and 0.6.1, `healthcare-org-app/healthcare-patients` PRs #4 and #5, closed and not merged).
- **Say what the comment says.** The comment opens with its title, then **the quality change against `main` as the first bold line**, then the change risk, then the rating line. The failing round was rehearsed in CI with gate 0.6.0 and 0.6.1 (PRs #4 and #5); gate 0.6.2 shows it as follows (the wording is what the 0.6.2 code produces for those numbers; the failing round has not been re-run with 0.6.2):

  ```
  ❌ API quality gate: FAILED
  ⬇️ API quality is lowered by 22 % from main
  Change risk: 🔴 breaking change for 32 consumers
  Rating D (60/100) · required: B or better, no blocker · 1 accepted lint exception · commit <sha> · CI run
  ```

  FAILED (the bar is B), **two blockers**. The step table (Score, vs main, Summary; no Status, Weight or Command columns) read, in the rehearsal:

  | Step | Result |
  |---|---|
  | `skills-check` | pass, 100 |
  | `contract-lint` | pass, 100, 🟰 0 (one accepted exception) |
  | `contract-tests` | **fail, a blocker**: 30, ⬇️ −70, 3/10 assertions pass, the collection still expects `mrn` |
  | `coverage` | pass, 100, 🟰 0, 10/10 |
  | `ai-readiness` | warn, 70, 🟰 0 |
  | `impact` | **fail, 0, a blocker**: "the change breaks 32 known consumers" (the summary names three, then "+29 more") |

  The blockers are visible under the table. **"What to fix (N)" is collapsed: click it open on stage.** Fail steps come first, warn steps are marked non-blocking. For `impact`, it lists the real breaking changes (for instance "Keep 'mrn' in GET /api/patients/{patient_id} response 200 (add the new name next to it)") and then `Affected consumers (32): a, b, c, +29 more`. Below it, "Accepted exceptions (1, human decisions)" and "Reproduce locally". The footer gives versions, spec, collection, baseline and score weights. The 32 comes from the Context Graph, through `postman context-graph`. Read the real comment on the day; the numbers can move.

  On a `pull_request` run, the commit in the rating line is GitHub's PR merge commit, not the SHA you pushed: don't say it matches your push.

- **Baseline.** `main`'s own gate run had been skipped, so there was no artifact to compare with: the gate re-ran the steps on `main` and says so (footer: baseline).
- **The quality change vs `main`.** The first bold line of the comment is the answer to "how much did quality move?". Round 1, the rename: 91 on `main`, 71 on the PR, **lowered by 22 %**. After the loop (round 2): **unchanged** (91). The passing comment in 0.6.2 is verified in CI (`healthcare-patients` PR #6, run 40943655307); its first lines:

  ```
  ✅ API quality gate: PASSED
  🟰 API quality is unchanged from main
  Change risk: 🟢 no breaking change · 32 known consumers
  ```

  The numbers can move from run to run: read the real comment on the day.

> "Rating D, failed, two blockers. The contract tests: the collection still expects `mrn`, and the mock generated from my new contract doesn't send it. And the impact step: thirty-two consumers of this service, from the Context Graph. And look at the first line of the comment: 'API quality is lowered by 22 % from main'. That's the answer to 'does this improve quality?', per PR. Over many PRs, it's your evidence."

#### 5b. The gate loop (~5 min)

> "I could read that report and fix it myself. Instead I hand it to my own Claude Code. It has the Postman plugin, and the platform team's gate plugin. The rules of the loop are in files, not in my prompt."

- **Do:** switch to terminal tab 2, your own `claude` session opened in the clone. Type:
  ```
  The quality gate failed on demo/live-rename-mrn. Run the gate loop until the gate passes. Don't merge.
  ```
- **Show (narrate while it works):** the `gate-loop` skill (gate plugin 0.6.2) does this:
  1. It takes the **PR title and body as the intent to preserve**, and never reverts the change.
  2. **`gate-verdict`** (the only other agent, read-only) finds the CI run for that exact commit SHA, waits for it, reads the report, and returns a verdict plus a **numbered fixes brief**.
  3. Your session applies the brief. For a rename it **keeps the old field, marked `deprecated`, and adds the new one next to it**, in the contract, the code, the tests and the collection. Postman work goes through `postman:api-engineer`: the session loaded it before fixing (contract, `app/routes.py`, tests, 8 collection requests), which is the talk's thesis in action. `gate-verdict` downloads the CI report into `<repo root>/gate-results/ci-<run id>/` and reads it with the Read tool, one simple command at a time: no permission prompt.
  4. It pushes to the **same branch**, new SHA, new verdict. **At most 3 rounds**, then a final report.

> "It never edits the gate, it doesn't merge, and it never sees the Postman key CI uses. The rules are in the plugin and in a short `CLAUDE.md`, and the gate runs outside the agent."

**Two honest endings, both fine on stage:**

- **Green (a compatible rename).** The PR comment has been **updated in place**, not duplicated: `✅ … PASSED`, and it now reads **`✅ API quality gate: PASSED`**, **`🟰 API quality is unchanged from main`**, **`Change risk: 🟢 no breaking change · 32 known consumers`**, then **Rating A (94/100)** · required: B or better, no blocker · 1 accepted lint exception. The impact step says "Additive contract change; 32 known consumers of patients-service" (gate 0.6.2, verified in CI on `healthcare-patients` PR #6). The loop numbers below (2 rounds, about 3.5 minutes) come from the 0.6.0/0.6.1 rehearsals. In the rehearsal: **2 rounds out of 3**, about **3.5 minutes** of loop once running, one sticky comment updated in place. The session kept `mrn` with `deprecated: true` and added `medical_record_number` next to it in `openapi.yaml`, `app/routes.py` (both keys returned), `tests/` (a new test) and the collection (assertions + examples); no revert, nothing forbidden touched. Read the new rating out loud.

> **The delta, as a talking point:** the rename lowered API quality by 22 % from main; the compatible fix brings it back (unchanged) and removes the breaking change. That is the per-PR "quality moved by x %" evidence.

> "Same PR, same comment, green. The old field is still there, deprecated, so no consumer breaks. I asked for an outcome and I did not type a Postman command."

- **NEEDS_DECISION.** The agent can't keep the intent without a trade-off, so it stops: the PR is **converted to draft** and gets **one comment with the options** (for instance keep the old field deprecated, or version the API). The PR stays open.

> "It stopped, and it told me why. Two options: keep the old field deprecated, or version the API. That's not a call for an agent. That's where a human decides."

**Do not merge** in either case. The repo stays clean.

> **If the loop is slow:** the CI run and each round take minutes. While it waits, go to act 6 (the gate repo, the Context Graph), then come back to the PR. Say so on stage.

### Act 6: Demo, part 3 — the gate's repo, and the Context Graph (~3 min)

#### 6a. The gate repo (~2 min)

- **Show:** the browser tab on `github.com/healthcare-org-app/healthcare-api-quality-gate`.

> "This is what the platform team built. It isn't a Postman product, it's a use case, and it's small. Each service opts in with one workflow file and one config file."

  Point at, in this order:
  - **Steps, one Postman CLI command each:** `postman skills status` (skills), `postman spec lint` (contract), `postman collection run --use-mock` against a mock generated from the **new** contract (contract tests), coverage of operations by the collection, `postman spec ai-readiness`, and `postman context-graph ask` (impact).
  - **`quality-gate.yml` in the service repo:** weights, rating, `pass_rating: B`, and the **blockers** (`contract-lint: on_fail`, `contract-tests: on_fail`, `impact: on_breaking`). Accepted lint exceptions are **human decisions**, with a mandatory reason: agents never add them.
  - **The reusable workflow** `.github/workflows/gate.yml`, called from the service's own workflow as `gate.yml@v1`.
  - **The Claude Code plugin** (`plugin/`, `healthcare-api-quality-gate`): the `gate-loop` skill and the `gate-verdict` agent you just watched.

> "The agent can't edit any of that: the plugin's rules forbid it, and the gate runs in CI with a secret the agent never sees."

#### 6b. The Context Graph (~1 min)

- **Show:** switch to the Postman app, the Context Graph, `patients-service`.

> "And this is how the gate knows who the rename breaks. 32 services consume `patients-service`, the gate's count from the Context Graph: EHR, immunizations, lab results, lab orders, referrals, appointments, and the rest. That's a Postman Context Graph question, and it's one CLI command in the gate."

- **Show:** back to the deck, slide 16.

### Act 7: What you just saw, and what it costs (~2 min)

> "What you saw: I made a change that looked fine, and a gate the agent can't edit stopped it. My own Claude Code read the verdict through a read-only reviewer and fixed the change in the same PR, without breaking a consumer, or stopped and asked a human to decide. What it costs: the skills are files you keep current with `postman skills`, the gate is code the platform team owns, and the impact step is only as good as your Context Graph: it knows which services declare you as a dependency, not which field they read."

- **Show:** slide 16 (What you just saw).

### Act 8: Objections (~2–3 min)

> "Three questions, every time. Does this block my merge? The gate returns FAILED. Whether FAILED actually blocks is a branch-protection setting: it's required on appointments-service, and not yet on `main` of patients. Can the agent cheat? It can't edit the gate: the rules are in the gate plugin and `CLAUDE.md`, and the gate runs in CI, with a secret the agent never sees. And can the Context Graph tell me which *field* a consumer reads? No, the graph answers at the endpoint level, not the field level. That's why the gate's brief says 'keep the old name, add the new one next to it', and why you don't treat 'no consumer found' as 'safe'."

- **Show:** slide 17 (What to take away) as the backdrop, or stay on slide 16 if the room wants to talk.

### Act 9: Close + CTA (~1–2 min)

> "A command per step, skills in files, a gate the agent can't edit. Install the plugin and your own agent gets the skills; run `postman init` and any agent in your repo does. The gate you saw is one team's use case, built from these blocks. Yours will look different."

- **Show:** slide 18 (Try it).
- CTA, read it out:
  - `npx @postman/postman-plugin`, then ask your own agent to work an API change
  - Postman CLI: <https://www.postman.com/product/postman-cli/>
  - API Context Graph: <https://www.postman.com/context-graph/>
  - Claude Code Plugin module on Liftoff: <https://www.postman.com/liftoff/modules/claude-code-plugin/>
  - Join the Postman community on Discord: <https://postman-community.com/kmg>
  - The demo repos: [healthcare-patients](https://github.com/healthcare-org-app/healthcare-patients) and [healthcare-api-quality-gate](https://github.com/healthcare-org-app/healthcare-api-quality-gate)

### What to cut when you are over

Cut act 7 first, then act 8 down to one question (does this block my merge), then compress act 3 (slides 06 to 13 in 10 seconds each, stop on 14). In act 4, skip 4a's per-file tour and show only `openapi.yaml`, the collection, `CLAUDE.md` and `quality-gate.yml`. In act 6, skip the gate repo's workflow and plugin tour, keep the steps and the Context Graph. If you're still over, let the gate loop run while you do act 6, as above. **Never cut** the cold open (act 1), the PR gate comment (5a) or the PR going green (5b): that's where the demo lands.

---

## 5. Tear down / reset

```bash
./scripts/teardown.sh
```

Closes every open PR (drafts included, e.g. after a NEEDS_DECISION) from a `demo/live-*` branch on `healthcare-org-app/healthcare-patients` with a comment, deletes those branches on the remote, and removes `/tmp/healthcare-patients`. Safe to run when setup never ran. It never touches `main`.

**It deliberately leaves standing:** `main` of both repos, the org-level `POSTMAN_API_KEY` secret, the Postman team's Context Graph connection.

**It cannot clean up** anything else: for instance resources a rehearsal created on your own Postman account. Don't merge the demo PR: if you did, `main` is dirty and `setup.sh` will refuse to run until the rename is reverted by hand.

Full reset between sessions:

```bash
./scripts/teardown.sh && ./scripts/setup.sh
```

---

## 6. Troubleshooting

| Issue | Fix |
|---|---|
| `setup.sh` fails: leftover open PR or `demo/live-*` branch | A previous rehearsal didn't run teardown. Run `./scripts/teardown.sh`, or close the PR and delete the branch by hand. |
| `setup.sh` fails: `main` has no `mrn` in the Patient schema | A rehearsal's rename reached `main`. Revert it on `main` by hand before presenting. |
| `setup.sh` warns: Postman CLI not logged in | `postman login` (a team whose Context Graph has `healthcare-org-app`). The local gate run in the loop needs it; the CI gate doesn't use your login. |
| The gate comment never appears | Check the **Actions** run of the PR: the workflow `quality-gate` calls the reusable `gate.yml@v1`. It only runs when something it judges changed, and a PR from a fork gets no secrets. Push the branch to the repo itself. |
| `impact` says no consumer found in CI (it found 32 in the rehearsal) | The org-level `POSTMAN_API_KEY` is on a team without the Context Graph for the org, or a **repo-level** `POSTMAN_API_KEY` is shadowing the org one (`gh secret list --repo healthcare-org-app/healthcare-patients`). Delete the repo-level secret, or say what the comment says and move on. |
| `contract-lint` or `impact` shows `not_available` or `degraded` | The CI step couldn't log in to Postman. A degraded step is a gap, never a pass: say so. Same fix as the row above. |
| In an interactive session, Claude Code asks to approve a compound git command the session wrote itself (e.g. `cd … && git commit …`) | Approve it, or the session retries with `git -C <dir> …` on its own. |
| The loop doesn't know what to preserve | The PR was opened with `gh pr create --fill` (empty body). Open it with a title and a body (act 4b). |
| Claude Code doesn't know `gate-loop` | The gate plugin isn't installed at user level (the repo-level enablement is deleted by the security hook). Run the two install commands of section 2, restart `claude` in `/tmp/healthcare-patients`. |
| Two `gate-loop` / `gate-verdict` show up | The old `postman-agent-quality-gate` (0.4.0) is still enabled. `claude plugin disable postman-agent-quality-gate@postman-agent-quality-gate`. |
| `.claude/settings.json` is deleted in the clone, `.claude/.settings-security-marker` appears | Expected: the security hook. Don't `git add -A`, add `openapi.yaml` only. |
| The loop ends with NEEDS_DECISION and a draft PR | A designed ending, not a failure. Read the comment and the options out loud. `teardown.sh` closes the draft like any other demo PR. |
| The loop stops after 3 rounds with the gate still red | Read the final report out loud: that's the designed stop. Look at the PR comment and the last brief, and say what the agent couldn't do (for instance, a lint finding that needs a human exception: the agent must not add it). |
| The comment doesn't open with "API quality is … from main" | Gate older than 0.6.2 (older than 0.6.0: no quality delta at all). Check that tag `v1` points to 0.6.2 and re-run the workflow. Otherwise say it's a feature of the latest release and read what the comment says. |
| The agent merged or pushed to `main` | It shouldn't: the gate loop and `CLAUDE.md` forbid it. If it did, revert on `main` by hand before the next session; `teardown.sh` never touches `main`. |
| Venue Wi-Fi is down | There is no offline fallback. Stay on the slides, and show the files of act 4a and the gate repo from a cached browser tab. |

---

## 7. Additional resources

| Resource | Link |
|---|---|
| **The service repo** (patients-service, Python/Flask) | <https://github.com/healthcare-org-app/healthcare-patients> |
| Its contract and collection | [`openapi.yaml`](https://github.com/healthcare-org-app/healthcare-patients/blob/main/openapi.yaml), [`postman/collections/Patients API/`](https://github.com/healthcare-org-app/healthcare-patients/tree/main/postman/collections) |
| Its committed skills, written by `postman init` | [`postman/skills/`](https://github.com/healthcare-org-app/healthcare-patients/tree/main/postman/skills) and [`AGENTS.md`](https://github.com/healthcare-org-app/healthcare-patients/blob/main/AGENTS.md) |
| Its gate loop and rules | [`CLAUDE.md`](https://github.com/healthcare-org-app/healthcare-patients/blob/main/CLAUDE.md) (short, points to `healthcare-api-quality-gate:gate-loop`) |
| Its gate config and caller | [`quality-gate.yml`](https://github.com/healthcare-org-app/healthcare-patients/blob/main/quality-gate.yml), [`.github/workflows/quality-gate.yml`](https://github.com/healthcare-org-app/healthcare-patients/blob/main/.github/workflows/quality-gate.yml) |
| **The platform team's gate** (a use case, not a Postman product) | <https://github.com/healthcare-org-app/healthcare-api-quality-gate> (tag `v1`; 0.6.0 adds the loop and the quality delta vs main, 0.6.2 makes the PR comment readable: quality change first, change risk, collapsed fix list) |
| The gate's Claude Code plugin | [`plugin/`](https://github.com/healthcare-org-app/healthcare-api-quality-gate/tree/v1/plugin): skill `gate-loop`, agent `gate-verdict` |
| Postman Claude Code Plugin module (Liftoff) | <https://www.postman.com/liftoff/modules/claude-code-plugin/> |
| Postman CLI | <https://www.postman.com/product/postman-cli/> |
| Postman CLI command reference | <https://learning.postman.com/docs/postman-cli/postman-cli-options> |
| Postman CLI installation | <https://learning.postman.com/docs/postman-cli/postman-cli-installation/> |
| API Context Graph | <https://www.postman.com/context-graph/> |
| The 10-minute booth cut of this talk (to re-check against this README) | [../../lightning-talks/postman-in-the-terminal/](../../lightning-talks/postman-in-the-terminal/) |
| Same product, different signal, the CLI as a test oracle | [../../lightning-talks/open-meteo-loop-eng/](../../lightning-talks/open-meteo-loop-eng/) |
