# From Click to Terminal: API Engineering in the Age of Agents

> The 10-minute booth cut of this talk lives in [content/lightning-talks/postman-in-the-terminal/](../../lightning-talks/postman-in-the-terminal/). It was written for an older demo and is being redone: check it against this README before you use it on the floor.

> [Short talk](../../../templates/formats/short-talk.md) — target length **25 minutes (Q&A included)**. Delivered at meetups and conference breakouts. This README is the single source of truth. Read it top to bottom before your first attendee; everything you need to run the demo without improvising is here.
>
> The previous version of this talk demoed a healthcare quality gate. That material is not lost: it is in [gate-talk-material.md](gate-talk-material.md), out of date with this demo, for a future talk.

---

## 1. Product summary

- **Product:** the [Postman Claude Code plugin](https://www.postman.com/liftoff/modules/claude-code-plugin/), backed by the same Postman skills and the [Postman CLI](https://www.postman.com/product/postman-cli/) underneath. `postman init` is the other way in: it commits the same skills into a repo.
- **Use case:** a developer has the OpenAPI spec of a new service, `transport-service` (`GET` and `POST /api/rides`, `GET /api/rides/{ride_id}`, `GET /health`), and asks a coding agent to run the API engineering chain from the terminal: `postman init`, generate the collection, add tests, generate a mock and run the tests against it, generate a GitHub workflow with the `ci-integration` skill, push, open a PR, watch the CI. Local, git-native workspace: nothing goes to the Postman cloud.
- **Audience:** developers building or supervising coding agents, platform and API-governance teams, and anyone who has wondered what a Postman plugin gives an agent that the app's UI does not.

**The thesis, in one line:**

> **A coding agent doesn't need Postman's UI. It needs a command per step, and skills committed in files that tell it which command to run.** The skills reach the agent through the plugin, or through `postman init`.

**The story (the narrative arc):**

> Open on the clicks: every step of setting up Postman for a new service is a click the agent can't take. The agent has files and a terminal; it needs a command per step, readable output, no human in the loop. The Postman CLI is that, and the skills that say which command to run are files: the plugin puts them in your own Claude Code, `postman init` commits them in the repo. Then the live demo: a spec, and the agent does the chain, in a throwaway repo, until the CI is green on a PR. You show that generating isn't testing (the generated collection has no assertion), and that nothing leaves the machine except a git push. Then what it costs. Then one slide, no live: a closed PR of another repo where a platform team's quality gate commented. **That gate is the use case of a platform team, built with Postman. It is not a Postman product**, and it will be the subject of another talk.

> **What this demo is not:** a Postman feature tour, a cloud workspace demo, or "Postman ships a quality gate".

> **Network reality:** the live demo needs the network (GitHub for the repo, the push, the PR and the CI run). The local steps work on files and were not tested offline. There is no offline fallback for the CI part. See [section 6](#6-troubleshooting).

**Call to action (for attendees):**

- `npx @postman/postman-plugin`, then ask your own agent to work an API change
- Postman CLI: <https://www.postman.com/product/postman-cli/>
- Claude Code Plugin module on Liftoff: <https://www.postman.com/liftoff/modules/claude-code-plugin/>
- Join the Postman community on Discord: <https://postman-community.com/kmg>
- The demo template: <https://github.com/healthcare-org-app/healthcare-transport-template>
- Advanced use, a gate on a PR (no live): <https://github.com/healthcare-org-app/healthcare-appointments/pull/9>
- This talk's slides and setup tooling: `git clone https://github.com/Postman-Devrel/booth-demos.git` → `cd booth-demos/content/short-talks/postman-in-the-terminal`

> **Open question: the install path.** The CTA says `npx @postman/postman-plugin` (also on slides 10 and 15). The canonical path (that, or `claude plugin install …`) is not decided: align it with the plugin team before the next delivery.

---

## 2. Pre-requisites

| Requirement | How to get it |
|---|---|
| **Claude Code, the Postman CLI, `git`, `gh`** | `setup.sh` checks them. The rehearsal used Postman CLI 1.85.0 (the CLI said 1.86.0 was available) and the plugin `postman` 2.0.1. |
| **`gh` authenticated, with the right scopes** | `gh auth status`. You need to create a repo in the `healthcare-org-app` organization, push to it and open a PR. `teardown.sh` deletes the repo, which needs the `delete_repo` scope on your token. In the rehearsal the push of a workflow file worked with the usual token, no `workflow` scope needed. |
| **The Postman plugin** | `postman@claude-plugins-official`, the plugin the talk is about. Your session uses it for the Postman work (`postman:api-engineer`, `postman:ci-integration`). |
| **The template repo** | `healthcare-org-app/healthcare-transport-template`, marked as a template, with the spec only. Check it exists before presenting. |
| **A Postman login** | **Not needed by the CI workflow** (it ran green with an empty `HOME`, no secret). Whether the local steps (`init`, `generate`, `mock`, `run`) work logged out was **not tested**: `postman login` before you present, as a precaution. |
| **The deck** | A local file, `presentation/index.html`, 15 slides, no sign-in. Fonts come from Google Fonts: without network it falls back to system fonts. |
| **A backup tab** | A browser tab on the rehearsal PR <https://github.com/healthcare-org-app/healthcare-transport-rehearsal-1/pull/1> (run green in 19 s), in case the live CI is slow. Check it still exists: it is meant to be deleted. |
| **A tab on PR #9** | <https://github.com/healthcare-org-app/healthcare-appointments/pull/9>, for questions after slide 14. |

> **Git hygiene.** The created repo has its own history, unrelated to a local clone of the template: always work in the clone `setup.sh` makes **of the created repo**. Never push a clone of the template into it.

---

## 3. Setup

```bash
./scripts/setup.sh
```

What it does (`./scripts/setup.sh --dry-run` shows it without creating anything):

1. Checks the prerequisites (deck, git, gh and its login, claude, the Postman CLI and its version, the Postman plugin). No Postman login or API key is needed.
2. Creates a public repo `healthcare-org-app/healthcare-transport-<date>-<time>` from the template `healthcare-org-app/healthcare-transport-template`.
3. Clones that repo (not the template) into `/tmp/healthcare-transport-<date>-<time>`, and writes the repo name and path to `/tmp/.postman-terminal-demo.state`. It refuses to run if that file already exists.
4. Creates the branch `demo/spec-to-pipeline` in the clone.
5. Opens the deck and prints the checklist and the demo prompts.

It never merges anything.

### Pre-demo checklist

- [ ] `./scripts/setup.sh` finished with no `[FAIL]` lines; note the clone path and the repo name it printed
- [ ] Deck open, fullscreen, on slide 1
- [ ] Terminal 1 in the clone, large font (`Cmd+=`), running `claude` with the Postman plugin loaded
- [ ] `ls -A` in the clone shows only the spec (and `.git`): no `.postman/`, no `postman/`, no `.opencode/`. They appear at `init`.
- [ ] Browser tabs: the created repo (empty of PRs), the rehearsal PR #1, PR #9 of healthcare-appointments
- [ ] `postman --version` is 1.85.0 or later; ignore the "new version" notice
- [ ] Optional dry run the day before, then `./scripts/teardown.sh`

---

## 4. Talk track and click track

Seven acts, 25 minutes (Q&A included). Talk track is **verbatim** (blockquotes), read it if the room goes cold. Click track is interleaved at the exact point each action happens.

The deck is `presentation/index.html`, 15 slides. **The live demo starts at slide 12, "From a spec to a green PR"**: that is the handoff point, the moment you leave the deck for a real terminal and a browser. You come back to slide 13 when the PR is green.

| Act | Purpose | Slide(s) | Budget |
|---|---|---|---|
| 1 | **Cold open** — the clicks an agent can't take | 01 Title, 02 Pyramid, 03 API engineering chain | 2 min |
| 2 | **Why it happens** — what an agent needs from a tool | 04 What an agent needs | 2 min |
| 3 | **The idea** — a command per step, skills in committed files, two ways in | 05 to 11 | 3 min (about 25 s per slide, walk fast) |
| 4 | **Live demo** — spec to green PR | 12 From a spec to a green PR | 11 min |
| 5 | **What it costs** | 13 What it costs | 2 min |
| 6 | **Advanced use** — a platform team's gate, on a PR, no live | 14 Advanced use | 2 min |
| 7 | **Q&A + CTA** | 15 Try it | 3 min |

Total: 25 minutes. The sum of the original plan (2 + 3 + 3 + 12 + 2 + 2 + 3) is 27: this table takes 1 minute from act 2 and 1 from the demo to fit the slot. The demo time itself is a **guess**: the rehearsal played the commands one by one and did not time an agent working from a prompt.

### Act 1: Cold open (~2 min)

> "Think about the last time you set Postman up for a new service. You open the app. You import the spec. You click to generate a collection. You click to add tests. You click to create a mock. You click to wire it into your CI. Every one of those is a click. An agent can't take a click. An agent has files and a terminal."

- **Show:** slide 01 (title), slide 02 (the pyramid of agentic API engineering: the whole talk is walking up it), slide 03 (the API engineering chain: contract, collection and tests, mock, CI, workspace, docs).

### Act 2: Why it happens (~2 min)

> "This isn't a model problem. What an agent needs from a tool is simple: it runs with nobody at the keyboard, it returns JSON and exit codes, it loads only what the task needs, it gives facts, and it runs the same way locally and in CI. A click in a UI fails every one of those."

- **Show:** slide 04 (what an agent needs from a tool).

### Act 3: The idea (~3 min)

> "So the answer isn't a smarter agent, it's a better toolbox. Every step of that chain is one Postman CLI command. The skills that say which command, and when, are files, committed in the repo. There are two ways in. The Postman plugin puts them in your own Claude Code. `postman init` commits the same skills into a repo, so any agent that works there gets them, an unattended one in CI included. Let me show you."

- **Show:** slides 05 to 07 (the CLI: every step has a command, one command read by a human or an agent), then slides 08 to 11 (the plugin: what the CLI alone doesn't give, the architecture, how an agent picks a skill). Walk them, don't read them.
- **Show:** advance to slide 12. This is the handoff.

### Act 4: Live demo, from a spec to a green PR (~11 min)

> **The prompts below are drafts.** The rehearsal ran the commands one by one, not through prompts. Say them in your own words, one step at a time, and read what the agent runs: nothing here was rehearsed as a prompt. Rehearsal timings are in brackets and can move.

#### 4a. The spec (~1 min)

> "This is a throwaway repo, created from a template a minute ago. Four endpoints for a new service, a ride transport service: list and create rides, get one, and a health check. All I have is the spec."

- **Do:** in the clone, `ls -A`, then show `openapi.yaml` (`GET` and `POST /api/rides`, `GET /api/rides/{ride_id}`, `GET /health`).

#### 4b. `postman init` (~1 min)

- **Do:** ask your session: `Set this repo up for Postman. Local only, no cloud.` The command that worked is `postman init --json -y` [7.8 s].
- **Show:** `ls -A` again: `.postman/resources.yaml` (the spec is linked; `workspace.id` is empty), `postman/` with 16 skills, `AGENTS.md`, and `.opencode/`.

> "Two things. `workspace.id` is empty: this is the local, git-native workspace, nothing in the cloud. And those 16 skills in `postman/skills/` are the agent's know-how, committed. Any agent that opens this repo gets them. Yes, there's an `.opencode/` folder too: `init` sets that up as well."

> **Trap, `--no-cloud`.** The `bootstrap` skill cites `postman init --json --no-cloud`. CLI 1.85.0 refuses that option. If the agent tries it, the CLI says so; it recovers with `postman init --json -y`. Don't hide it: it is a real finding (to report to the plugin team), and the skill's own rule is "Never invent a subcommand or a flag. Run -h first and believe it."

#### 4c. The collection, then the tests (~3 min)

- **Do:** ask: `Generate the Postman collection from the spec.` The command: `postman spec generate collection ./openapi.yaml -n "Transport API"` [4.3 s]: 4 requests with examples, v3 YAML files under `postman/collections/`.
- **Show:** open one request file. Point out there is **no assertion**.

> "Generating a collection is not testing. This one has four requests and zero assertions: it can only fail if the server is down."

- **Do:** ask: `Add tests to every request.` The agent edits each request (rehearsal: `postman collection request update … --scripts 'test:…'`, four times): 4 `pm.test` in all.

> **A good moment, not a script.** In the rehearsal an assertion on the list used `rides` while the spec says `items`, and the run caught it. If it happens on stage, say so: that is why the tests are run against something, and why you generate the mock next. Don't plan on it.

> **Trap.** `.postman/resources.yaml` does **not** register the collection after `spec generate collection` (no `collections` binding). Don't claim it does.

#### 4d. The mock, and the tests against it (~2 min)

- **Do:** ask: `Generate a mock from the spec and run the tests against it.` Commands: `postman mock generate ./openapi.yaml -n "Transport mock" --port 4500` [4.1 s], which writes a static mock to `postman/mocks/transport-mock/`, then `postman collection run "postman/collections/Transport API" --use-mock '{{baseUrl}} mock:./postman/mocks/transport-mock'` [5 s].
- **Show:** the run's output: **4 requests, 4 assertions, 0 failures** in the rehearsal.

> "The mock comes from the contract, so the tests run against what the spec says, with no service running. Four requests, four assertions."

#### 4e. The CI workflow, the push, the PR (~2 min)

- **Do:** ask: `Add a GitHub workflow that runs these checks on every PR, with the ci-integration skill.` The skill writes `.github/workflows/api-checks.yml`. In the rehearsal it has four steps: a contract lint with `--issueType=syntax`, a collection lint, the collection run against the mock, and AI readiness (75/100, threshold 70). **No secret is configured or used.**
- **Show:** the workflow file, briefly: say what each step is, and what it isn't (see act 5).
- **Do:** ask: `Commit, push the branch and open a PR.` Make sure the PR has a title and a body (`gh pr create --title … --body …`). In the created repo, the push goes to the demo branch of `setup.sh`.

> **Traps in the workflow.** `postman spec lint` without a login fails ("Governance linting requires you to be logged in"): that is why the contract lint uses `--issueType=syntax`. The `junit` reporter is refused for v3 collections (only `cli` is supported): there must be no `-r junit` in the workflow. If the agent writes either, the CI fails, and that is your honest red run.

#### 4f. The CI run (~1 min of talk, the run itself is short)

- **Show:** the PR, then the **Actions** run, "API checks". In the rehearsal: **green, 19 s in all**, observed after a 45 s wait (CLI install 6 s, contract lint 1 s, collection lint 1 s, run against the mock 2 s, AI readiness 1 s).

> "Green, in under half a minute, and it needed no secret. Spec to PR, and everything is a file in git."

- **If the run is slow or red:** switch to the backup tab (the rehearsal PR #1, green) and say so. A red run caused by one of the traps above is a fine story: the CI caught it. **A red CI was not rehearsed.**
- **Do not merge.**

### Act 5: What it costs (~2 min)

> "What did this cost? Three things. First, the skills are files: they age like code, and they can disagree with the CLI. You saw it: the bootstrap skill cites an option, `--no-cloud`, that CLI 1.85.0 refuses. Second, look at what the `ci-integration` skill wrote, and what it didn't. It lints the contract for syntax, lints the collection, runs the tests against the mock, and scores AI readiness. It doesn't do governance lint, which needs a login. It doesn't give you a junit report on a v3 collection. It doesn't push to a cloud workspace. And it tests the mock, not your running service. Third, secrets. This workflow needed none. The day you add governance lint or a workspace push, the key goes in your CI secrets, and the agent never sees it."

- **Show:** slide 13.

### Act 6: Advanced use (~2 min)

> "One more thing, no live. Once the checks live in files and in CI, a platform team can build on the same blocks. This is a real PR of another repo, `healthcare-appointments`, closed, never merged. A quality gate commented on it."

- **Show:** slide 14, then, if you have time, the tab on PR #9. Read the four lines **as they are**:

  ```
  ❌ API quality gate: FAILED
  API quality is lowered by 38 % from main
  Change risk: breaking change for 1 consumer
  Rating D (55/100) · required: B or better, no blocker
  ```

  (Lines of the gate v0.6.3 comment. Read the real PR on the day: the numbers are the ones of that PR.)

> "I want to be clear about what this is. **The gate is a use case a platform team built with Postman: the CLI, committed skills, the Context Graph. It is not a Postman product.** It's the subject of another talk."

> **If asked "does it block the merge?"** The gate is **not** a required check on `main` of `healthcare-appointments`: the branch is not protected. Blocking is a branch-protection setting, not a gate feature.

### Act 7: Q&A + CTA (~3 min)

> "A command per step, skills in files. Install the plugin and your own agent gets them; run `postman init` and any agent in your repo does. Questions?"

- **Show:** slide 15 (Try it). CTA, read it out:
  - `npx @postman/postman-plugin`, then ask your own agent to work an API change
  - Postman CLI: <https://www.postman.com/product/postman-cli/>
  - Claude Code Plugin module on Liftoff: <https://www.postman.com/liftoff/modules/claude-code-plugin/>
  - Join the Postman community on Discord: <https://postman-community.com/kmg>
  - The demo template: <https://github.com/healthcare-org-app/healthcare-transport-template>

### What to cut when you are over

Cut act 6 first (keep one sentence: "a platform team can build a gate on this, another talk"), then compress act 5 to its first point, then compress act 3 (slides 05 to 11 in 15 seconds each, stop on 12). In act 4, skip 4a and show the spec in a glance, and run 4d as a single prompt with 4c. **Never cut** the cold open (act 1), the tests step (4c: the collection has no assertion) or the green PR (4f): that's where the demo lands.

---

## 5. Tear down / reset

```bash
./scripts/teardown.sh
```

`./scripts/teardown.sh --dry-run` shows what it would do. It closes the open PR, deletes the throwaway repo only after you type its full name (your token needs the `delete_repo` scope), then deletes the clone in `/tmp` and the state file. It refuses any repo whose name does not start with `healthcare-transport-`.

**It deliberately leaves standing:** the template repo, and PR #9 of `healthcare-appointments`.

**It does not clean up** the rehearsal repo `healthcare-transport-rehearsal-1` (created by hand, to be deleted with `gh repo delete`; it needs the `delete_repo` scope) Don't delete it before the talk if you use it as the backup tab.

Full reset between sessions:

```bash
./scripts/teardown.sh && ./scripts/setup.sh
```

---

## 6. Troubleshooting

| Issue | Fix |
|---|---|
| `postman init --json --no-cloud` fails | The `bootstrap` skill cites that option; CLI 1.85.0 refuses it. Use `postman init --json -y`. Say so on stage (act 4b). |
| `.opencode/` shows up in `ls -A` after `init` | Expected: `postman init` creates `.opencode/` (with `opencode.json`, `package.json`, `node_modules`) next to `AGENTS.md`, `postman/skills/` and `.postman/resources.yaml`. |
| The generated collection has no tests | Expected: `postman spec generate collection` writes 4 requests and **no assertion**. The tests are the agent's work (act 4c). |
| A test fails against the mock on a property name (for example `rides` instead of `items`) | The assertion doesn't match the spec. Fix the assertion, not the mock: the mock is generated from the spec. In the rehearsal that is exactly what the run caught. |
| `.postman/resources.yaml` doesn't list the collection after `spec generate collection` | Expected (no `collections` binding). Don't present the file as an index of the collections. |
| `postman spec lint` fails: "Governance linting requires you to be logged in" | Use `--issueType=syntax` in CI, where there is no login. |
| `-r junit` is refused on `postman collection run` | Collections v3 only support the `cli` reporter. Remove the reporter from the workflow. |
| The CI run needs a secret and fails without it | The rehearsed workflow needs none. If the agent added a step that logs in (governance lint, workspace push), remove that step; it is out of this demo. |
| The push of the workflow file is refused | Rehearsal: it passed with the usual token. If it doesn't, check `gh auth status` and add the `workflow` scope. |
| Pushing the clone of the template fails or shows unrelated history | A repo created from a template has its own history. Work in the clone of the **created** repo, never push a local clone of the template into it. |
| The "new version available (1.86.0)" notice | Cosmetic: the rehearsal ran on 1.85.0. |
| `setup.sh` or `teardown.sh` behaves differently from section 3 and 5 | Those sections describe the intended behaviour; the scripts are written separately. Trust the script's output and tell whoever maintains the README. |
| The CI run is slow or red on stage | Switch to the backup tab (rehearsal PR #1) and say so, or keep a red run as the story (act 4f). |
| `teardown.sh` can't delete the repo | The token lacks the `delete_repo` scope: `gh auth refresh -h github.com -s delete_repo`, then `gh repo delete healthcare-org-app/<repo>` by hand. |
| Venue Wi-Fi is down | There is no offline fallback for the CI part. Stay on the slides, show the local steps in the terminal if you have a pre-made clone (not tested offline), and use the rehearsal PR from a cached tab. |

---

## 7. Additional resources

| Resource | Link |
|---|---|
| **The template** (transport-service, spec only) | <https://github.com/healthcare-org-app/healthcare-transport-template> |
| The rehearsal PR (CI green in 19 s, not merged) | <https://github.com/healthcare-org-app/healthcare-transport-rehearsal-1/pull/1> |
| **Advanced use** (a platform team's quality gate on a PR, closed, not merged) | <https://github.com/healthcare-org-app/healthcare-appointments/pull/9> |
| The gate's material for a future talk, out of date with this demo | [gate-talk-material.md](gate-talk-material.md) |
| Postman Claude Code Plugin module (Liftoff) | <https://www.postman.com/liftoff/modules/claude-code-plugin/> |
| The Postman plugin | <https://github.com/postmanlabs/postman-plugin> |
| Postman CLI | <https://www.postman.com/product/postman-cli/> |
| Postman CLI command reference | <https://learning.postman.com/docs/postman-cli/postman-cli-options> |
| Postman CLI installation | <https://learning.postman.com/docs/postman-cli/postman-cli-installation/> |
| The 10-minute booth cut of this talk (to re-check against this README) | [../../lightning-talks/postman-in-the-terminal/](../../lightning-talks/postman-in-the-terminal/) |
| Same product, different signal, the CLI as a test oracle | [../../lightning-talks/open-meteo-loop-eng/](../../lightning-talks/open-meteo-loop-eng/) |
