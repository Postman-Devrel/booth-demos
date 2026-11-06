> OLD MATERIAL, not up to date with the new demo ("From Click to Terminal", throwaway transport-service repo). It is the healthcare gate demo, kept verbatim for a future talk on the quality gate. The sentence "it is required on appointments-service" below is FALSE: the gate is not a required check on `main` of healthcare-appointments (the branch is not protected). Also stale: slide numbers, the 28-minute timings, and the `setup.sh`/`teardown.sh` behaviour described here (the scripts now create a throwaway transport repo).

# Gate talk material (moved from the old README and frontmatter)

## Product summary and story (gate version)

- **Product:** the [Postman Claude Code plugin](https://www.postman.com/liftoff/modules/claude-code-plugin/), backed by the same Postman skills and the [Postman CLI](https://www.postman.com/product/postman-cli/) underneath, with the [API Context Graph](https://www.postman.com/context-graph/) as the source of "who consumes this API".
- **Use case:** a platform team (here, the fictional `healthcare-org-app`) turns Postman building blocks into an **API quality gate** that every service calls from its own CI, and the developer's own coding agent fixes its API changes against that gate. **The gate is the healthcare org's own use case, built with Postman. It is not a Postman product.** The talk is about the building blocks: committed Postman skills, the CLI, the Context Graph, and the plugin that carries them to an agent.
- **Audience:** developers building or supervising coding agents, platform and API-governance teams, and anyone who has wondered what a Postman plugin gives an agent that the app's UI does not.

**The thesis, in one line:**

> **A coding agent doesn't need Postman's UI. It needs a command per step, committed skills that tell it which one to run, and a gate it can't edit, and Postman gives you the first two.** The rules of the loop live in files (the gate plugin's `gate-loop` skill, a short `CLAUDE.md`), not in a prompt.

**The story (the narrative arc):**

> Open on the pyramid of agentic API engineering: the API engineering chain, then what an agent needs from a tool to work that chain (a command per step, readable output, no human in the loop), then the Postman CLI and MCP, then the Postman plugin. Those are slides 1 to 11. Then the demo runs on one **real repo**, `healthcare-org-app/healthcare-patients` (`patients-service`, Python/Flask, port 8100), which already has everything in files: the contract, a v3 collection with assertions, the skills `postman init` wrote, a short `CLAUDE.md` that points to the gate loop, and the platform team's quality gate in CI. There is no coding agent in the repo: the coder is your own Claude Code session (Postman plugin + the platform team's gate plugin). You rename one field "for readability" and open a PR. Nothing local looks wrong, and the gate fails it: rating D, contract tests and impact blocking. Then you ask your own session to run the gate loop: the read-only `gate-verdict` agent reads the verdict and writes a fixes brief, your session applies it, and it iterates (3 rounds at most). Two honest endings: the gate passes, or the loop stops with NEEDS_DECISION and a draft PR (a human decides). You do not merge. You open the gate's repo and show that each step is one Postman CLI command, then the Context Graph in the Postman app, which is how the gate knows who the rename breaks.

> **The quality delta.** The gate's comment now opens with the change of the gate score against the base branch ("API quality is lowered by 36 % from main"), then the change risk. The score is the rating score ("NN/100"), all steps included, impact and skills-check too. This answers the question "what is the evidence that it improves quality by x %?": per PR, the gate says how much quality moves against `main`; aggregated over PRs, it becomes org-level evidence. See the format in act 5a.

> **What this demo is not:** a Postman feature tour, and not "Postman ships a quality gate". The gate is one team's use case, assembled from the CLI, skills and Context Graph. The point is how little glue it took, and that the agent can't cheat on it.

## Presenter prerequisites specific to the gate

| **Postman CLI logged in** | `postman login` before you present, on a team whose Context Graph has `healthcare-org-app` ingested. The local gate run in the gate loop needs it (`setup.sh` only WARNs if `postman whoami` fails). |
| **The org-level `POSTMAN_API_KEY` secret** | Already set at the `healthcare-org-app` organization level and used by the gate's workflow in CI. Nothing to set per session. A repo-level secret with the same name would shadow it, see [section 6](#6-troubleshooting). |
| **The gate plugin installed at user level** (gate 0.6.3 or later) | `claude plugin marketplace add healthcare-org-app/healthcare-api-quality-gate` then `claude plugin install healthcare-api-quality-gate@healthcare-api-quality-gate`. Check with `claude plugin list`. **Why user level:** a built-in Claude Code security hook deletes `.claude/settings.json` in a clone it considers untrusted (it writes `.claude/.settings-security-marker`), so the repo-level plugin enablement doesn't apply. |
| **The old `postman-agent-quality-gate` plugin (0.4.0) disabled** | `claude plugin disable postman-agent-quality-gate@postman-agent-quality-gate` (or uninstall it). While it is enabled it loads a duplicate `gate-loop` and `gate-verdict`. `setup.sh` WARNs if it is still enabled. |
| **The Postman plugin** | `postman@claude-plugins-official`, the plugin the talk is about. Your session uses it for the Postman work (the `postman:api-engineer` skill). |
| **The Postman app, logged in** | Same team as the CLI. Used for act 6, the Context Graph UI. |
| **The deck** | A local file, `presentation/index.html`, built from the Claude Design deck "From Click to Terminal". No sign-in needed. |

> **The gate is not the thing you installed.** Nothing to install for the gate itself: it runs in the repo's CI (reusable workflow `gate.yml@v1`) and locally through `npx github:healthcare-org-app/healthcare-api-quality-gate#v1 run`, which needs Node 22.

> **Presenter note from the CI rehearsals** (2026-10-29, gate 0.6.0 and 0.6.1: same results; gate 0.6.2 and 0.6.3, released the same day, changed the comment's format. 0.6.3 was verified in CI on `healthcare-patients` PR #8, a variant where only `impact` fails: lowered by 21 %; the demo's own failing round was not re-run with 0.6.3, its numbers below are what 0.6.3 computes from the rehearsal's step scores).
> Write a PR body when you open the PR (act 4b): the loop reads the title and body as the intent to preserve, and `gh pr create --fill` gives an empty body. Use `gh pr create --title … --body …`.

> **Git hygiene in the clone.** The security hook leaves a deleted `.claude/settings.json` in the working tree. **Never `git add -A`** in the clone (it would commit that deletion): `git add openapi.yaml` only.

## Act 4 (gate version): the workspace in files, then a harmless-looking change

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

## Acts 5 and 6 (gate version): the gate, the gate loop, the gate repo, the Context Graph

### Act 5: Demo, part 2 — the gate, then the gate loop (~7 min)

#### 5a. The gate result (~2 min)

- **Show:** the PR in the browser, then the **Actions** run for it. The gate's sticky comment appears, titled "API quality gate" (marker `<!-- healthcare-api-quality-gate -->`). It takes a couple of minutes: while it runs, say what it is.

> "This check isn't mine, and it isn't the agent's. It's the platform team's quality gate. Every service that adopts it calls it from its own CI, patients and appointments today. Every step is a Postman CLI command."

- **Timing:** the first comment lands about 83 seconds after the push (CI rehearsals of 2026-10-29, gate 0.6.0 and 0.6.1, `healthcare-org-app/healthcare-patients` PRs #4 and #5, closed and not merged).
- **Say what the comment says.** The comment opens with its title, then **the quality change against `main` as the first bold line**, then the change risk, then the rating line. The failing round was rehearsed in CI with gate 0.6.0 and 0.6.1 (PRs #4 and #5); gate 0.6.3 shows it as follows. These are the numbers 0.6.3 computes from the rehearsal's step scores (base 94, head 60), not a 0.6.3 CI run. The verified 0.6.3 example is `healthcare-patients` PR #8 (run 40952454418, attempt 2), a variant where the collection was updated too (contract-tests 10/10), so only `impact` fails: `⬇️ API quality is lowered by 21 % from main`, `Rating C (74/100)`.

  ```
  ❌ API quality gate: FAILED
  ⬇️ API quality is lowered by 36 % from main
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

  The blockers are visible under the table. **"What to fix (N)" is collapsed: click it open on stage.** Fail steps come first, warn steps are marked non-blocking. For `impact`, it lists the real breaking changes (for instance "Keep 'mrn' in GET /api/patients/{patient_id} response 200 (add the new name next to it)") and then `Affected consumers (32): a, b, c, +29 more`. Below it, "Accepted exceptions (1, human decisions)" and "Reproduce locally". The footer gives versions, spec, collection, baseline and score weights, and the API quality index (contract-lint, contract-tests, coverage, ai-readiness only; here 91 → 71) with the base score (94, reconstructed from main's steps, impact counted 100, skills-check from this run). The 32 comes from the Context Graph, through `postman context-graph`. Read the real comment on the day; the numbers can move.

  The commit in the rating line is the commit you pushed (the PR head SHA).

- **Baseline.** `main`'s own gate run had been skipped, so there was no artifact to compare with: the gate re-ran the steps on `main` and says so (footer: baseline).
- **The quality change vs `main`.** The first bold line of the comment is the answer to "how much did quality move?". The first line compares the **gate score** (the rating score, all steps including `impact` and `skills-check`) with `main`'s; the API quality index (91 → 71 in round 1) is in the footer, not in the first line. Round 1, the rename: 94 on `main` (reconstructed from main's steps, impact counted 100), 60 on the PR, −34 pts, **lowered by 36 %** (computed by 0.6.3 from the rehearsal's step scores, not a 0.6.3 CI run). After the loop (round 2): 94 vs 94, **unchanged**. The passing comment was verified in CI in the 0.6.2 format (`healthcare-patients` PR #6, run 40943655307); the numbers are the same in 0.6.3 (index and score both unchanged), not a 0.6.3 run. Its first lines:

  ```
  ✅ API quality gate: PASSED
  🟰 API quality is unchanged from main
  Change risk: 🟢 no breaking change · 32 known consumers
  ```

  The numbers can move from run to run: read the real comment on the day.

> "Rating D, failed, two blockers. The contract tests: the collection still expects `mrn`, and the mock generated from my new contract doesn't send it. And the impact step: thirty-two consumers of this service, from the Context Graph. And look at the first line of the comment: 'API quality is lowered by 36 % from main'. That's the answer to 'does this improve quality?', per PR. Over many PRs, it's your evidence."

#### 5b. The gate loop (~5 min)

> "I could read that report and fix it myself. Instead I hand it to my own Claude Code. It has the Postman plugin, and the platform team's gate plugin. The rules of the loop are in files, not in my prompt."

- **Do:** switch to terminal tab 2, your own `claude` session opened in the clone. Type:
  ```
  The quality gate failed on demo/live-rename-mrn. Run the gate loop until the gate passes. Don't merge.
  ```
- **Show (narrate while it works):** the `gate-loop` skill (gate plugin 0.6.3) does this:
  1. It takes the **PR title and body as the intent to preserve**, and never reverts the change.
  2. **`gate-verdict`** (the only other agent, read-only) finds the CI run for that exact commit SHA, waits for it, reads the report, and returns a verdict plus a **numbered fixes brief**.
  3. Your session applies the brief. For a rename it **keeps the old field, marked `deprecated`, and adds the new one next to it**, in the contract, the code, the tests and the collection. Postman work goes through `postman:api-engineer`: the session loaded it before fixing (contract, `app/routes.py`, tests, 8 collection requests), which is the talk's thesis in action. `gate-verdict` downloads the CI report into `<repo root>/gate-results/ci-<run id>/` and reads it with the Read tool, one simple command at a time: no permission prompt.
  4. It pushes to the **same branch**, new SHA, new verdict. **At most 3 rounds**, then a final report.

> "It never edits the gate, it doesn't merge, and it never sees the Postman key CI uses. The rules are in the plugin and in a short `CLAUDE.md`, and the gate runs outside the agent."

**Two honest endings, both fine on stage:**

- **Green (a compatible rename).** The PR comment has been **updated in place**, not duplicated: `✅ … PASSED`, and it now reads **`✅ API quality gate: PASSED`**, **`🟰 API quality is unchanged from main`**, **`Change risk: 🟢 no breaking change · 32 known consumers`**, then **Rating A (94/100)** · required: B or better, no blocker · 1 accepted lint exception. The impact step says "Additive contract change; 32 known consumers of patients-service" (verified in CI on `healthcare-patients` PR #6 in the 0.6.2 format; same numbers in 0.6.3). The loop numbers below (2 rounds, about 3.5 minutes) come from the 0.6.0/0.6.1 rehearsals. In the rehearsal: **2 rounds out of 3**, about **3.5 minutes** of loop once running, one sticky comment updated in place. The session kept `mrn` with `deprecated: true` and added `medical_record_number` next to it in `openapi.yaml`, `app/routes.py` (both keys returned), `tests/` (a new test) and the collection (assertions + examples); no revert, nothing forbidden touched. Read the new rating out loud.

> **The delta, as a talking point:** the rename lowered the gate score by 36 % from main (94 → 60, computed by 0.6.3 from the rehearsal); the compatible fix brings it back to unchanged (94 vs 94) and removes the breaking change. That is the per-PR "quality moved by x %" evidence.

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

- **Show:** stay on slide 12 (or go back to it).

## Acts 7 and 8 (gate version): what it costs, objections

### Act 7: What you just saw, and what it costs (~2 min)

> "What you saw: I made a change that looked fine, and a gate the agent can't edit stopped it. My own Claude Code read the verdict through a read-only reviewer and fixed the change in the same PR, without breaking a consumer, or stopped and asked a human to decide. What it costs: the skills are files you keep current with `postman skills`, the gate is code the platform team owns, and the impact step is only as good as your Context Graph: it knows which services declare you as a dependency, not which field they read."

- **Show:** stay on slide 12; the loop is the demo you just ran.

### Act 8: Objections (~2–3 min)

> "Three questions, every time. Does this block my merge? The gate returns FAILED. Whether FAILED actually blocks is a branch-protection setting: it's required on appointments-service, and not yet on `main` of patients. Can the agent cheat? It can't edit the gate: the rules are in the gate plugin and `CLAUDE.md`, and the gate runs in CI, with a secret the agent never sees. And can the Context Graph tell me which *field* a consumer reads? No, the graph answers at the endpoint level, not the field level. That's why the gate's brief says 'keep the old name, add the new one next to it', and why you don't treat 'no consumer found' as 'safe'."

- **Show:** slide 12 as the backdrop if the room wants to talk.

## Troubleshooting rows specific to the gate demo

| Issue | Fix |
|---|---|
| `setup.sh` fails: leftover open PR or `demo/live-*` branch | A previous rehearsal didn't run teardown. Run `./scripts/teardown.sh`, or close the PR and delete the branch by hand. |
| `setup.sh` fails: `main` has no `mrn` in the Patient schema | A rehearsal's rename reached `main`. Revert it on `main` by hand before presenting. |
| `setup.sh` warns: Postman CLI not logged in | `postman login` (a team whose Context Graph has `healthcare-org-app`). The local gate run in the loop needs it; the CI gate doesn't use your login. |
| The gate comment never appears | Check the **Actions** run of the PR: the workflow `quality-gate` calls the reusable `gate.yml@v1`. It only runs when something it judges changed, and a PR from a fork gets no secrets. Push the branch to the repo itself. |
| `impact` says no consumer found in CI (it found 32 in the rehearsal) | The org-level `POSTMAN_API_KEY` is on a team without the Context Graph for the org, or a **repo-level** `POSTMAN_API_KEY` is shadowing the org one (`gh secret list --repo healthcare-org-app/healthcare-patients`). Delete the repo-level secret, or say what the comment says and move on. |
| `contract-lint` or `impact` shows `not_available` or `degraded` | The CI step couldn't log in to Postman. A degraded step is a gap, never a pass: say so. Same fix as the row above. |
| The loop doesn't know what to preserve | The PR was opened with `gh pr create --fill` (empty body). Open it with a title and a body (act 4b). |
| Claude Code doesn't know `gate-loop` | The gate plugin isn't installed at user level (the repo-level enablement is deleted by the security hook). Run the two install commands of section 2, restart `claude` in `/tmp/healthcare-patients`. |
| Two `gate-loop` / `gate-verdict` show up | The old `postman-agent-quality-gate` (0.4.0) is still enabled. `claude plugin disable postman-agent-quality-gate@postman-agent-quality-gate`. |
| `.claude/settings.json` is deleted in the clone, `.claude/.settings-security-marker` appears | Expected: the security hook. Don't `git add -A`, add `openapi.yaml` only. |
| The loop ends with NEEDS_DECISION and a draft PR | A designed ending, not a failure. Read the comment and the options out loud. `teardown.sh` closes the draft like any other demo PR. |
| The loop stops after 3 rounds with the gate still red | Read the final report out loud: that's the designed stop. Look at the PR comment and the last brief, and say what the agent couldn't do (for instance, a lint finding that needs a human exception: the agent must not add it). |
| The first line says "lowered" but the per-step vs main column is all 🟰 | Expected: `impact` (the change risk) is in the gate score, not in the per-step column. The breaking change is what lowers the score. |
| The comment doesn't open with "API quality is … from main", or the first line says "unchanged" while `impact` fails and the rating is C or D | Gate older than 0.6.3 (0.6.2 compared the API quality index, which leaves out `impact`; older than 0.6.0: no quality delta at all). Check that tag `v1` points to 0.6.3 and re-run the workflow. Otherwise say it's a feature of the latest release and read what the comment says. |
| The agent merged or pushed to `main` | It shouldn't: the gate loop and `CLAUDE.md` forbid it. If it did, revert on `main` by hand before the next session; `teardown.sh` never touches `main`. |

## Old frontmatter, verbatim (use_case, primary_api, key_messages, notes)

```yaml
use_case: >
  A platform team (the fictional healthcare-org-app) builds an API quality gate
  with Postman building blocks, the CLI, committed skills and the Context
  Graph, and every service calls it from its own CI. The demo runs on one real
  service repo, healthcare-org-app/healthcare-patients (patients-service,
  Python/Flask): a hand-made "readability" rename of `mrn` tanks the rating
  (contract tests and impact fail), then the developer's own Claude Code
  session (Postman plugin + the platform team's gate plugin) runs the gate
  loop (verdict, fixes brief, push) until the gate passes or stops with
  NEEDS_DECISION. There is no coding agent in the repo: the only second agent
  is the read-only gate-verdict reviewer.
  The gate is the healthcare org's use case built with Postman, not a Postman
  product.
primary_api:
  - "The Postman Claude Code plugin and `postman init`: the two paths a Postman skill takes to reach an agent"
  - "Postman CLI, one command per gate step: postman skills status, postman spec lint, postman collection run --use-mock, postman spec ai-readiness, postman context-graph ask"
  - "The committed contract and v3 collection: openapi.yaml and postman/collections/Patients API/ of healthcare-org-app/healthcare-patients (patients-service, port 8100)"
  - "The platform team's gate: healthcare-org-app/healthcare-api-quality-gate (tag v1; 0.6.0 adds the loop and the quality delta vs main, 0.6.2 makes the PR comment readable: quality change first, change risk, collapsed fix list; 0.6.3: the first line compares the gate score, impact included, with main's), its reusable workflow gate.yml, and its Claude Code plugin healthcare-api-quality-gate (skill gate-loop, agent gate-verdict)"
  - "API Context Graph: https://www.postman.com/context-graph/"
  - "Postman CLI: https://www.postman.com/product/postman-cli/"
key_messages:
  - A coding agent doesn't need Postman's UI. It needs a command per step of the API engineering chain, and the Postman CLI is that.
  - An agent's Postman know-how lives in committed skills, not in a chat. The plugin puts them in a developer's own Claude Code; `postman init` commits the same skills into the repo.
  - A change that looks harmless locally can still fail a quality gate. Here a rename in the response contract fails contract tests, because the collection is the consumers' side of the contract.
  - The gate loop closes the circle without a human relaying the report. The developer's own session reads the verdict through a read-only reviewer, applies the fixes brief (keep the old field deprecated, add the new one next to it), pushes to the same branch, and stops after 3 rounds, on PASSED, or on NEEDS_DECISION (draft PR with the options: a human decides).
  - The rules live in files, not in the prompt (the platform team's gate plugin, a short CLAUDE.md). The agent can't edit the gate, and the gate runs in CI with a secret the agent never sees.
  - Per PR, the gate says how much API quality moves against main. Rehearsed in CI on 2026-10-29 (gates 0.6.0 and 0.6.1, same results). Gate 0.6.3 opens the comment with the change of the gate score (the rating score, all steps incl. impact) against main's: for the rename, 94 -> 60 (-34 pts, -36 %), "API quality is lowered by 36 % from main", computed by 0.6.3 from the rehearsal's step scores, not a 0.6.3 CI run; the compatible fix brings it back (94 vs 94, "API quality is unchanged from main", same numbers as the 0.6.2 passing comment verified in CI). Verified in CI with 0.6.3 on healthcare-patients PR #8 (only impact fails, lowered by 21 %, rating C 74/100). Aggregated over PRs, that is org-level evidence that it improves quality.
  - The quality gate is a use case a platform team built with Postman, in a small repo. It is not something Postman ships.
  - The Context Graph is how the gate knows who a break hits (32 consumers of patients-service, the gate's count), at the endpoint level, not the field level.
notes: >
  THE DECK OF RECORD IS NOW `presentation/index.html`, built from the Claude
  Design deck "From Click to Terminal" (`presentation_url`, kept as the
  source). 13 slides, in the Postman dark look of the agentic-sdlc deck. The
  live demo starts at slide 12 ("Now, Postman in the CI"); slide 13 is
  "Try it". If the
  Claude Design deck changes, re-export it into `presentation/index.html`
  rather than editing the two by hand.

  THE QUALITY GATE IS NOT A POSTMAN PRODUCT. It is a use case the (fictional)
  healthcare org's platform team built with Postman: the CLI, committed skills
  and the Context Graph. Say so on stage and don't present it as something
  Postman ships.

  THE DEMO RUNS ON A REAL REPO, NOT PART OF THIS MONOREPO:
  healthcare-org-app/healthcare-patients (patients-service). It is equipped
  with the gate (healthcare-org-app/healthcare-api-quality-gate, tag v1)
  through the caller workflow `.github/workflows/quality-gate.yml` and
  `quality-gate.yml`. The gate's CI step uses the ORG-level `POSTMAN_API_KEY`
  secret; a repo-level secret with the same name would shadow it.

  NO CODING AGENT ANYMORE. The coder is the presenter's own Claude Code
  session (Postman plugin + the platform team's gate plugin
  `healthcare-api-quality-gate`). The only second agent is `gate-verdict`
  (read-only reviewer). The repo no longer has a coder sub-agent definition
  (PR chore/drop-coder-agent); its CLAUDE.md is short and points to
  `healthcare-api-quality-gate:gate-loop`.

  THE GATE LOOP (gate 0.6.0, PR feat/0.6.0-loop-and-baseline): takes the PR
  title/body as the intent to preserve; never reverts the change; for a rename
  keeps the old field `deprecated` and adds the new one next to it (contract,
  code, tests, collection); uses postman:api-engineer for Postman work; stops
  after 3 rounds or PASSED, or with NEEDS_DECISION (PR converted to draft and
  one comment with the options, e.g. keep the old field deprecated or version
  the API). Never merges. Two honest endings on stage: green, or
  NEEDS_DECISION ("that's where a human decides").

  QUALITY DELTA VS MAIN (the answer to "evidence that it improves quality by
  x %"). Since gate 0.6.3 (released 2026-10-29, tag v1 moved) the PR comment
  opens with its title, then the gate score change against the base branch (the
  rating score, all steps incl. impact and skills-check; base score always
  reconstructed from main's steps, impact counted 100) as the
  first bold line, then the change risk, then the rating line. Round 1 was
  rehearsed in CI with gates 0.6.0 and 0.6.1 (healthcare-patients PRs #4 and
  #5, closed, not merged; same results); the 0.6.3 numbers for it (base 94, head 60) are
  what 0.6.3 computes from the rehearsal's step scores, not re-run in CI
  (verified 0.6.3 example: healthcare-patients PR #8, run 40952454418, attempt
  2, only impact fails: lowered by 21 %, Rating C 74/100): `API quality gate: FAILED` / `API
  quality is lowered by 36 % from main` / `Change risk: breaking change for 32
  consumers` / `Rating D (60/100) · required: B or better, no blocker · 1
  accepted lint exception`. Steps (Score, vs main): skills-check pass 100;
  contract-lint pass 100 (0); contract-tests fail 30 (-70), 3/10; coverage pass
  100 (0); ai-readiness warn 70 (0); impact fail 0 ("the change breaks 32 known
  consumers"). Blockers: contract-tests and impact. "What to fix (N)" is
  collapsed: click it open on stage. Baseline: main's own gate run had been
  skipped, so the steps were re-run on main. After the loop (round 2), verified
  in CI with 0.6.2 (healthcare-patients PR #6, run 40943655307): `API quality
  gate: PASSED` / `API quality is unchanged from main` / `Change risk: no
  breaking change · 32 known consumers` / `Rating A (94/100)` (0.6.2 format; same numbers in 0.6.3); impact "Additive
  contract change; 32 known consumers of patients-service". The rename lowered
  the gate score by 36 % (94 -> 60); the compatible fix brings it back (unchanged) and
  removes the breaking change. The API quality index (contract-lint,
  contract-tests, coverage, ai-readiness; 91 -> 71 in round 1) is in the footer,
  with the base score. The commit in the rating line is the commit pushed. First comment about 83 s
  after the push (0.6.0/0.6.1 rehearsals).

  THE LOOP, REHEARSED IN CI ON 2026-10-29 (gates 0.6.0 and 0.6.1, same results): 2 rounds
  out of 3, ending PASSED, about 3.5 min of wall time once running, one sticky comment
  updated in place. The session kept `mrn` with `deprecated: true` and added
  `medical_record_number` next to it in openapi.yaml, app/routes.py (both keys
  returned), tests/ (a new test) and the collection (assertions + examples);
  no revert, nothing forbidden touched. The session loaded postman:api-engineer
  before fixing (contract, app/routes.py, tests, 8 collection requests).

  REHEARSAL NOTES. Write a PR body (`gh pr create --title ... --body ...`): `--fill` gives an empty body
  and the loop reads title + body as the intent. gate-verdict reads the CI report
  from <repo root>/gate-results/ci-<run id>/ with no permission prompt (gate 0.6.2 and later).

  PRESENTER PREREQUISITES. (1) Install the gate plugin at USER level:
  `claude plugin marketplace add healthcare-org-app/healthcare-api-quality-gate`
  then `claude plugin install healthcare-api-quality-gate@healthcare-api-quality-gate`.
  A built-in Claude Code security hook deletes `.claude/settings.json` in a
  clone it considers untrusted (it writes `.claude/.settings-security-marker`),
  so the repo-level plugin enablement does not apply. (2) Disable or uninstall
  the old `postman-agent-quality-gate` plugin (0.4.0): it loads a duplicate
  gate-loop / gate-verdict. (3) Clone to /tmp/healthcare-patients (not a name
  with "demo": the reviewer once guessed the repo from the folder name).
  (4) Never `git add -A` in the clone (it would commit the settings.json
  deletion): `git add openapi.yaml` only.

  THE REPO IS NOT LINKED TO A POSTMAN CLOUD WORKSPACE YET
  (`workspace.id: ''` in `.postman/resources.yaml`). Act 4 shows the local,
  git-native workspace, and says so. Linking a cloud workspace is a follow-up.

  THE DEMO PR IS NEVER MERGED. The branch is `demo/live-rename-mrn`. The
  gate-loop fix keeps `mrn` (deprecated) and adds
  `medical_record_number` next to it (contract, `app/`, pytest tests,
  collection; rehearsed in CI on 2026-10-29, gates 0.6.0 and 0.6.1: PASSED in 2 rounds),
  or stops with NEEDS_DECISION and a draft PR. `teardown.sh`
  closes the PR (draft or not) and deletes the branch; if a rehearsal reached `main`, `setup.sh`
  refuses to run.

  BLOCKING IS A BRANCH-PROTECTION SETTING, NOT A GATE FEATURE. The gate
  returns FAILED; whether that blocks a merge depends on the repo requiring
  the "gate / quality-gate" check. It is required on appointments-service,
  not yet on patients' `main`. Say so when asked.

  THE CONTEXT GRAPH IS ENDPOINT-LEVEL, NOT FIELD-LEVEL. 32 consumers of
  patients-service per the gate (including ehr, immunizations, lab-results,
  lab-orders, referrals, appointments); the graph can't say which field each one
  reads. That is why the gate's brief says "keep the old name, add the new
  one next to it". It is also team-gated: whichever team's key backs
  POSTMAN_API_KEY decides which graph answers.

  THE 10-MINUTE BOOTH CUT (`content/lightning-talks/from-click-to-terminal/`)
  WAS WRITTEN FOR THE PREVIOUS DEMO (bare spec, then a CI agent that only
  comments) and wraps this folder's scripts. Re-check it against this
  README before using it on the floor.

  SAME PRODUCT AS open-meteo-loop-eng, DIFFERENT SIGNAL AND DIFFERENT SCOPE.
  That talk is the CLI as a test oracle for one API. This one is the CLI and
  committed skills as an agent's toolbox, with a gate around the agent. If a
  booth crowd has seen both, lead with that distinction.
```
