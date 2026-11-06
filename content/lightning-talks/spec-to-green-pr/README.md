# From spec to green PR in 10 minutes

> [Lightning talk](../../../templates/formats/lightning-talk.md) — target length **~10 minutes**. Booth demo or meetup opener, in front of one person or a small group. No Q&A inside the slot: questions happen after, one to one.
>
> This is the booth cut of the short talk [From Click to Terminal: API Engineering in the Age of Agents](../../short-talks/from-click-to-terminal/README.md). It keeps **only the live part**. For what is common (product, thesis, prerequisites in full, the long troubleshooting table, resources) the short talk's README is the reference: this one repeats only what you need in front of you at the booth.

---

## 1. Product summary

- **Product:** the [Postman Claude Code plugin](https://www.postman.com/liftoff/modules/claude-code-plugin/) and the [Postman CLI](https://www.postman.com/product/postman-cli/) underneath.
- **Use case:** the OpenAPI spec of a new service, `transport-service` (`GET` and `POST /api/rides`, `GET /api/rides/{ride_id}`, `GET /health`), in a throwaway repo. A coding agent does the chain from the terminal: `postman init`, collection, tests, mock and run, GitHub workflow, push, PR, CI. Local, git-native workspace: nothing goes to the Postman cloud.
- **One payoff:** a PR with a green "API checks" run. Everything that got it there is a file in git.

**The claim, in one line:**

> **An agent doesn't need Postman's UI. It needs one command per step.** The CLI is that.

**What this demo is not:** a feature tour, a cloud-workspace demo, or "Postman ships a quality gate". If someone asks about the gate on PR #9 of `healthcare-appointments`: it is a platform team's use case built with Postman, not a Postman product, and the subject of another talk. Give the link, don't demo it.

**What is cut from the short talk:** the idea slides (pyramid, what an agent needs, CLI and plugin architecture), the "advanced use" PR #9 live, "what it costs" as its own act (one sentence at the close), and the long Q&A.

**Network:** the live demo needs the network (GitHub for the repo, the push, the PR, the CI run). The local steps work on files and were not tested offline. There is no offline fallback for the CI part: see [Troubleshooting](#6-troubleshooting).

---

## 2. Pre-requisites

Same as the [short talk](../../short-talks/from-click-to-terminal/README.md#2-pre-requisites): Claude Code with the `postman@claude-plugins-official` plugin, the Postman CLI (1.85.0 in the rehearsal, 1.86.0 was announced), `git`, and `gh` authenticated with access to the `healthcare-org-app` organization (create repo, push, PR; `delete_repo` for teardown). The template repo `healthcare-org-app/healthcare-transport-template` must exist.

Booth additions:

| Requirement | Why |
|---|---|
| **`postman login` done beforehand** | Precaution only. The CI workflow needs no login (green with an empty `HOME`), but the local steps were **not tested logged out**. |
| **Laptop on power, a large terminal font** | Passers-by read the screen from 2 metres. |
| **Four browser tabs** (see the checklist) | The created repo, the backup PR, this deck, PR #9 for questions. |

---

## 3. Setup

```bash
./scripts/setup.sh          # --dry-run shows it without creating anything
```

`scripts/setup.sh` only `exec`s the short talk's script. It checks the prerequisites, creates a **throwaway public repo** `healthcare-org-app/healthcare-transport-<date>-<time>` from the template, clones **that repo** (not the template) into `/tmp/healthcare-transport-<date>-<time>`, creates the branch `demo/spec-to-pipeline`, writes `/tmp/.postman-terminal-demo.state`, and prints the checklist and the demo prompts. It never pushes and never opens a PR. It refuses to run if the state file exists (run teardown first).

It opens this cut's deck, `presentation/index.html` (5 slides, `F` for fullscreen, `N` for notes). The QR codes on slide 5 load from `assets/`: check them once.

### What is prepared before the visitor arrives, and what is live

| Before (zero typing at the booth) | Live (the visitor sees it) |
|---|---|
| `./scripts/setup.sh`: repo, clone, branch | `ls -A` and the spec |
| `claude` started in the clone, plugin loaded, large font | `postman init` |
| Postman CLI present, `postman login` done | collection, **tests**, mock, run |
| The tabs open (see checklist) | workflow, push, PR |
| Deck on slide 1 | the CI run, then the PR |

The point of preparing only the repo: the visitor must see the chain start from a bare spec. Nothing in the chain is pre-run. The only thing that runs in the background is the CI, after the push: talk over it.

**Time reality.** The rehearsal numbers are: init 7.8 s, collection 4.3 s, mock 4.1 s, run 5 s, CI run 19 s (green, observed after a 45 s wait). That is about 21 s of CLI commands plus the CI run. **It excludes the agent's own time** (reading, editing, writing the workflow, committing), which was **not measured**. So the 6 minutes below are a budget to hold yourself to, not a duration anyone has timed. Do the full run once before the first session and write your own number here: `____`.

### Pre-demo checklist

- [ ] `./scripts/setup.sh` ended with no `[FAIL]`; note the clone path and the repo name
- [ ] This folder's deck open on slide 1, fullscreen; the short talk's deck tab closed
- [ ] Terminal in the clone, `claude` running, plugin loaded, large font (`Cmd+=`)
- [ ] `ls -A` in the clone shows only the spec (and `.git`). `.postman/`, `postman/`, `AGENTS.md` and `.opencode/` appear at `init`.
- [ ] Tab 1: the created repo (no PR yet). Tab 2: **backup**, the rehearsal PR <https://github.com/healthcare-org-app/healthcare-transport-rehearsal-1/pull/1> (run green in 19 s). **Check that it still loads: that repo was created by hand for the rehearsal and is meant to be deleted** (see [Tear down](#5-tear-down--reset)). Tab 3: PR #9 of `healthcare-appointments`, only for questions.
- [ ] `postman --version` is 1.85.0 or later; ignore the "new version" notice

---

## 4. Talk track and click track

Four acts, ~10 minutes. The talk track is verbatim (blockquotes); the click track is interleaved at the point each action happens. The deck has 5 slides: Title, The friction, The chain, Live demo, Try it. **There is no "advanced use" slide:** the format has one payoff and no branching, and PR #9 is a different story (a platform team's gate), so it is only a link on slide 5.

| Act | Purpose | Slide(s) | Budget |
|---|---|---|---|
| 1 | **Hook**: the clicks an agent can't take | 01, 02 | 1.5 min |
| 2 | **Setup**: one command per step, what "working" looks like | 03 | 1 min |
| 3 | **Live demo**: spec to green PR | 04, then terminal and browser | 6 min |
| 4 | **Close**: one sentence of meaning, then the CTA | 05 | 1.5 min |

### Act 1: Hook (~1.5 min)

> "Think about the last time you set Postman up for a new service. You open the app. You import the spec. You click to generate a collection, click to add tests, click to create a mock, click to wire it into your CI. Every one of those is a click, and an agent can't take a click. An agent has files and a terminal."

- **Show:** slide 01, then slide 02 (every step was a click; the agent can't click, it needs a command to run in a terminal).

### Act 2: The setup (~1 min)

> "So give each step a command. Postman's CLI has one for every link of that chain, and the skills that say which command to run are files in the repo. In the next six minutes I start from a spec of a new service, and I ask an agent to take it to a green pull request. What I want you to watch is step three: a collection generated from a spec has no assertion in it. The tests are real work."

- **Show:** slide 03 (the chain: one command per step; the collection has no assertion, step 3 is the agent's work).
- **Show:** advance to slide 04 (Demo: spec, Postman plugin, GitHub CI), then leave the deck for the terminal.

### Act 3: Live demo (~6 min)

> **The prompts below are drafts.** The rehearsal ran the commands one by one in a Claude session, not from prompts, and **not with an agent working alone**: the journal does not measure the agent's variability or the total time. Say each prompt in your own words, one step at a time, and read what the agent runs. Bracketed times are the CLI's own, from the rehearsal.

#### 3a. The spec (~30 s)

> "A throwaway repo, created from a template a minute ago. All I have is the spec of a ride transport service: list and create rides, get one, a health check."

- **Do:** in the clone, `ls -A`, then show `openapi.yaml`.

#### 3b. `postman init` (~45 s)

- **Do:** `Set this repo up for Postman. Local only, no cloud.`
- **Command that works:** `postman init --json -y` [7.8 s].
- **Show:** `ls -A`: `.postman/resources.yaml` (`workspace.id` is empty), `postman/` with 16 skills, `AGENTS.md`, `.opencode/`.

> "`workspace.id` is empty: local, nothing in the cloud. Those skills in `postman/skills/` are the agent's know-how, committed. Anyone's agent that opens this repo gets them."

> **Trap, `--no-cloud`.** The `bootstrap` skill cites `postman init --json --no-cloud`; CLI 1.85.0 refuses it. If the agent tries it, it recovers with `postman init --json -y`. Say it out loud: it is a real finding, and the skill's own rule is to run `-h` first.
> **Trap, `.opencode/`.** `init` creates it (`opencode.json`, `package.json`, `node_modules`). It will be in `ls -A`. Expected.

#### 3c. The collection, then the tests (~1 min 45 s)

- **Do:** `Generate the Postman collection from the spec.` Command: `postman spec generate collection ./openapi.yaml -n "Transport API"` [4.3 s]: 4 requests with examples, v3 YAML.
- **Show:** open one request file. **There is no assertion.**

> "Generating a collection is not testing. Four requests, zero assertions: this can only fail if the server is down."

- **Do:** `Add tests to every request.` In the rehearsal: `postman collection request update … --scripts 'test:…'`, four times, 4 `pm.test` in all.

> **Good moment, not a script.** In the rehearsal an assertion on the list used `rides` while the spec says `items`; the run caught it. If it happens, say so. Don't plan on it.
> **Trap.** `.postman/resources.yaml` does **not** register the collection after `spec generate collection`. Don't claim it does.

#### 3d. The mock, and the tests against it (~1 min 15 s)

- **Do:** `Generate a mock from the spec and run the tests against it.` Commands: `postman mock generate ./openapi.yaml -n "Transport mock" --port 4500` [4.1 s], then `postman collection run "postman/collections/Transport API" --use-mock '{{baseUrl}} mock:./postman/mocks/transport-mock'` [5 s].
- **Show:** the run output: **4 requests, 4 assertions, 0 failures** in the rehearsal.

> **If you are behind:** merge 3c's test step and 3d into a single prompt (`Add tests to every request, generate a mock from the spec and run the tests against it`). **That merged prompt was never run.**

#### 3e. Workflow, push, PR (~1 min 30 s)

- **Do:** `Add a GitHub workflow that runs the checks on every PR, including the AI readiness score. It must work with no Postman login and no secret.` It writes `.github/workflows/api-checks.yml`. **No secret.**
- **Show:** the file, ten seconds: say what each step is.
- **Do:** `Commit, push the branch and open a PR.` Make sure the PR has a title and a body. The push goes to `demo/spec-to-pipeline` of the **created** repo.

> **Traps in the workflow.** `postman spec lint` without a login fails ("Governance linting requires you to be logged in"): hence `--issueType=syntax`. The `junit` reporter is refused for v3 collections (only `cli`): no `-r junit`. If the agent writes either, the CI is red, and that is an honest story (a red run was not rehearsed).

#### 3f. The CI run (~15 s of your time; the run is short)

- **Show:** the PR in the browser, then the **Actions** run "API checks". Rehearsal: **green, 19 s in all**, observed after a 45 s wait.
- Talk over the wait with act 4's first sentence; do not stare at the spinner.
- **If it is slow or red at the 8-minute mark:** switch to the backup tab (the rehearsal PR, green in 19 s) and **say it is the rehearsal's**. **Do not merge.**

### Act 4: Close (~1.5 min)

> "That's the whole chain, spec to green PR, and every step is a file in git. Nothing went to the cloud except a git push. One thing to be honest about: the skills are files, so they age like code, and they can disagree with the CLI: you saw `--no-cloud`. And this workflow tests the mock, not your running service. The agent didn't need a UI. It needed one command per step."

- **Show:** the PR, with its green check (end on the thing that got created, not on the terminal), then slide 05 (Try it) for the CTA:
  - `npx @postman/postman-plugin`, then ask your own agent to work an API change
  - Postman Liftoff (QR) and the Postman Discord (QR)
  - Going further, a platform team's gate on a PR (not a Postman product): <https://github.com/healthcare-org-app/healthcare-appointments/pull/9>

> **If asked "does the gate block the merge?"** It is not a required check on `main` of `healthcare-appointments` (the branch is not protected). Blocking is a branch-protection setting, not a gate feature.

### What to cut when you are over

1. Act 2: fold it into the hook (one sentence: "one command per step, watch step 3").
2. 3a: show the spec at a glance. 3b: skip the `ls -A` commentary.
3. Merge the test and mock prompts (never run: see 3d).
4. At the 8-minute mark with no green run, go to the backup tab.

**Never cut:** the missing assertion (3c) and the green PR (3f). The close shrinks to the CTA.

---

## 5. Tear down / reset

```bash
./scripts/teardown.sh        # --dry-run shows what it would do
```

It `exec`s the short talk's script: it closes the open PR, deletes the throwaway repo **only after you type its full name** (your token needs the `delete_repo` scope), then deletes the clone in `/tmp` and the state file. It refuses any repo whose name does not start with `healthcare-transport-`. It leaves standing the template and PR #9 of `healthcare-appointments`.

**It does not clean up the rehearsal repo** `healthcare-transport-rehearsal-1` (created by hand, to be deleted with `gh repo delete`): keep it until your last session if it is your backup tab.

Between two visitors: `./scripts/teardown.sh && ./scripts/setup.sh`. How long that takes was not timed: run it ahead of the next visitor, not in front of them.

---

## 6. Troubleshooting

The full table is in the [short talk's README](../../short-talks/from-click-to-terminal/README.md#6-troubleshooting). The ones you will hit at the booth:

| Issue | Fix |
|---|---|
| `postman init --json --no-cloud` fails | CLI 1.85.0 refuses it. Use `postman init --json -y`. |
| `.opencode/` appears after `init` | Expected: `init` creates it. |
| The generated collection has no tests | Expected. The tests are the agent's work (3c). |
| A test fails against the mock on a property (`rides` vs `items`) | Fix the assertion, not the mock: the mock comes from the spec. |
| `postman spec lint` fails: "Governance linting requires you to be logged in" | `--issueType=syntax` in CI. |
| `-r junit` refused | v3 collections only support `cli`. Remove the reporter. |
| The workflow wants a secret | The rehearsed one needs none. Remove any step that logs in (governance lint, workspace push). |
| Push or PR looks like unrelated history | Work in the clone of the **created** repo, never push a clone of the template. |
| The CI run is slow or red | Backup tab: the rehearsal PR, green in 19 s (say it is the rehearsal's). A red run caused by a known trap is a fair story. |
| The backup tab is a 404 | The rehearsal repo was deleted. Tell the visitor, show the Actions run of your own PR, or replay a run the day before. |
| Venue Wi-Fi is down | No offline fallback for the CI part. Stay on the slides; show the local steps if you have a pre-made clone (not tested offline). |

---

## 7. Additional resources

| Resource | Link |
|---|---|
| The short talk this is cut from | [../../short-talks/from-click-to-terminal/](../../short-talks/from-click-to-terminal/README.md) |
| **The template** (transport-service, spec only) | <https://github.com/healthcare-org-app/healthcare-transport-template> |
| The rehearsal PR (CI green in 19 s, not merged; **to verify, this repo is meant to be deleted**) | <https://github.com/healthcare-org-app/healthcare-transport-rehearsal-1/pull/1> |
| Going further: a platform team's quality gate on a PR (closed, not merged, not a Postman product) | <https://github.com/healthcare-org-app/healthcare-appointments/pull/9> |
| Postman Liftoff | <https://www.postman.com/liftoff/> |
| The Postman plugin | <https://github.com/postmanlabs/postman-plugin> |
| Postman CLI | <https://www.postman.com/product/postman-cli/> |
| Postman CLI command reference | <https://learning.postman.com/docs/postman-cli/postman-cli-options> |
| Join the Postman community on Discord | <https://postman-community.com/kmg> |
| Same product, different signal: the CLI as a test oracle | [../open-meteo-loop-eng/](../open-meteo-loop-eng/) |
