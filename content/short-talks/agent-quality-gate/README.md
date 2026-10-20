# Let the Gate Decide

> [Short talk](../../../templates/formats/short-talk.md) — target length **27 minutes (Q&A
> included)**. This README is the single source of truth. Read it top to bottom before you
> present; everything you need to run the demo without improvising is here.

> **This folder carries the slides, the talk track, and setup/teardown only — not the demo.**
> The live demo runs inside a separate product repo,
> [Postman-Devrel/agent-quality-gate](https://github.com/Postman-Devrel/agent-quality-gate)
> (branch `main`), the same way [`postman-in-the-terminal`](../postman-in-the-terminal/)
> points at its own external demo repo. See [section 2](#2-pre-requisites) for what has to
> exist there before you can rehearse this.

---

## 1. Product summary

- **Product:** the [Postman CLI](https://www.postman.com/product/postman-cli/), as the engine
  behind a quality gate for API changes, plus the [API Context
  Graph](https://www.postman.com/context-graph/) as the one step that asks who depends on the
  API.
- **Use case:** a code-quality tool like Sonar analyzes code. Nothing in that stack looks at
  the API **contract**, or at **who depends on it**. A coding agent can rename a response
  field, update its own unit tests to match, keep the build green, and still break every
  consumer. This talk shows the gap, then shows the fix live: a naive coding agent "cleans
  up" an endpoint exactly the way a product owner might plausibly ask for, a five-step
  deterministic gate catches it in CI, a second, read-only agent reads the verdict and briefs
  the first one, and the same agent fixes it and pushes again until the gate is green.
- **Audience:** developers and platform/API engineers who supervise coding agents, and anyone
  who has watched a build stay green while an API broke anyway.

**The thesis, in one line:**

> **A green build proves nothing about the contract or its consumers — an independent,
> deterministic gate, driven entirely by the Postman CLI, is what actually stops a breaking
> change, and it closes the loop between two agents without a human relaying the verdict.**

**The story (the narrative arc):**

> Open on the failure everyone recognizes from code review, not API review: a change that
> passes every check a build system runs, and still breaks a consumer, because nothing in
> that build looked at the contract or asked who depends on it. Name the structural reason —
> a code-quality tool analyzes code, not a contract's compatibility with its previous version,
> and not who calls it. Then name the fix: a quality gate built for coding agents, five
> deterministic steps, every one of them a single Postman CLI command, run in CI where the
> agent that wrote the change cannot see it, skip it, or edit it. Show the repo and a clean
> baseline run first — rating A, nothing broken, so the audience has a "before." Then hand a
> **naive** coding agent a plausible, reasonable-sounding request — rename a field, make
> another one required — and watch it do exactly that, tests green, build green. The gate
> disagrees: two hard blockers, a score that would not have been enough to stop it on its own.
> A second, read-only agent reads that verdict off the exact CI run for that commit and writes
> a prioritized brief. The same coding agent applies it, pushes again, and the gate goes
> green. Close on what this costs to keep running, and the limits the talk does not hide:
> one step is `not_available` today, one step uses an LLM and can occasionally miss, and the
> gate never merges anything — CI does.

> **What this demo is not:** a Sonar replacement, a merge-blocking CI gate that stops you
> from going around it (it reports a verdict; a human or a branch-protection rule still has to
> act on it), or a demo of agents that cannot be wrong on the first try — the whole point is
> that a plausible, reasonable change is exactly what breaks a consumer, invisibly, every
> time.

**Call to action (for attendees):**

- Postman CLI: <https://www.postman.com/product/postman-cli/>
- API Context Graph: <https://www.postman.com/context-graph/>
- Clone the product repo and run the gate yourself: `git clone
  https://github.com/Postman-Devrel/agent-quality-gate.git && ./gate/run-all.sh`
- This talk's slides and setup tooling: `git clone
  https://github.com/Postman-Devrel/booth-demos.git` → `cd
  booth-demos/content/short-talks/agent-quality-gate`

**Network reality:** acts 1–3 are slides only, no network needed. From act 4 onward you need:
a live Postman CLI login, push access to the product repo, and GitHub Actions runners that
actually start (see [section 6](#6-troubleshooting) if a run stays `queued`). There is no
offline fallback for acts 4–7 in this version of the talk — if the venue network is in doubt,
rehearse the "what to cut" order in [section 4](#what-to-cut-when-you-are-over) in advance.

---

## 2. Pre-requisites

| Requirement | How to get it |
|---|---|
| **The product repo's demo material exists** | This talk is written from `BRIEF.md`'s design (Option A: a demo-only `api-coder-naive` agent, see the brief's section 3). As of this writing that material has not been verified to exist inside `Postman-Devrel/agent-quality-gate` itself — confirm `.claude/agents/api-coder-naive.md` is committed there (or wherever the brief's demo-material deliverable landed) before you rely on this README's click track. If it is missing, you are presenting ahead of the build, not behind it. |
| **`gh`, authenticated, with push access** | `gh auth status`; you need push access to `Postman-Devrel/agent-quality-gate` to push the demo branch live. |
| **Postman CLI 1.73.0 or newer, logged in** | `postman login --with-api-key "$POSTMAN_API_KEY"`. The key must belong to the Postman team whose Context Graph has `appointments-service` ingested (the Postman DevRel team's already does) — without it, the `impact` gate step is `not_available`, not just quieter. |
| **A new Claude Code session, opened after any change to `.claude/agents/`** | Agents in `.claude/agents/` load at session start only. If you edited or added an agent definition and reused an old session, it will not see it — open a fresh one before you go live. |
| **Java 21+, Node, `jq`** | The product repo builds with the Maven wrapper (`./mvnw`), so no separate Maven install is required. Optionally Python 3 with PyYAML — the contract diff step uses it, with a weaker fallback when it is missing. |
| **GitHub Actions runners that actually start** | Confirm a run does not sit `queued` for minutes before you go live — a `$0` Actions budget on the org or account has silently blocked runs before. |
| **The product repo's `POSTMAN_API_KEY` secret** | Already set on the repo as a GitHub Actions secret (per the brief); you do not set this, you only rely on it. Never print it or write it to a file. |

### Postman-specific setup

Log in to the Postman CLI **before** you present, not during act 4 — `postman login
--with-api-key "$POSTMAN_API_KEY"` once, locally, well ahead of time, so nothing stalls on an
auth prompt on stage.

---

## 3. Setup

```bash
cd content/short-talks/agent-quality-gate
./scripts/setup.sh
```

`setup.sh` will:

1. Check `git`, `gh`, `postman`, `claude`, and Java are installed, and that `gh` is
   authenticated.
2. Fail loudly, with the exact command to fix it, if the Postman CLI is not logged in.
3. Check for a leftover demo branch or an open demo PR on the product repo from a previous
   rehearsal, and refuse to continue until `./scripts/teardown.sh` has cleaned it up.
4. Make (or refresh) a fresh clone of `Postman-Devrel/agent-quality-gate` at a scratch
   directory, so nothing is typed by hand at run time.
5. Open the product repo and this talk's deck.

### Authentication

`gh auth status` is what lets `setup.sh` clone the product repo and lets you `git push` and
open the live Actions run on stage — nothing further to log into for that part. The Postman
CLI is separate: `postman login --with-api-key "$POSTMAN_API_KEY"` once, before you present,
using a key whose team has `appointments-service` in its Context Graph.

### Pre-flight checklist

- [ ] `./scripts/setup.sh` finished with no `[FAIL]` lines
- [ ] Logged into the Postman CLI (`postman login`) before presenting, with the right team's key
- [ ] `gh auth status` is green, with push access to `Postman-Devrel/agent-quality-gate`
- [ ] A **new** Claude Code session opened in the product repo clone (so `.claude/agents/` is loaded)
- [ ] `./gate/run-all.sh` run once on `main` in that clone — confirms the baseline is rating **A**
- [ ] No open PR, no leftover `demo/live-*` branch on the product repo
- [ ] GitHub Actions runners are not stuck `queued`
- [ ] Deck open, fullscreen, on slide 1
- [ ] A terminal tab in the product repo clone, large font (`Cmd+=`)
- [ ] A browser tab on the product repo's **Actions** page, ready to switch to

---

## 4. Talk track and click track

Ten acts, ~28 minutes including Q&A. Talk track is **verbatim** (blockquotes) — read it if
the room goes cold. Click track is interleaved at the exact point each action happens.

**The live demo starts at act 4** — that is the handoff point from slides to a real terminal
and a real GitHub Actions run. It stays live through act 7; there is no going back to slides
in between.

| Act | Purpose | Budget |
|---|---|---|
| 1 | **Cold open** — the build stayed green and the consumer still broke | 2 min |
| 2 | **Why it happens** — a code-quality tool never reads the contract or asks who depends on it | 2 min |
| 3 | **The idea** — five deterministic Postman CLI steps, run where the agent can't touch them | 2 min |
| 4 | **Demo, part 1** — tour the repo, run the baseline gate (**live demo starts here**) | 3 min |
| 5 | **Demo, part 2** — a naive coding agent "cleans up" the API | 5 min |
| 6 | **Demo, part 3** — the gate fails it, a read-only agent briefs the coder | 5 min |
| 7 | **Demo, part 4** — the fix round, the gate goes green | 4 min |
| 8 | **What it costs** — the limits this talk does not hide | 2 min |
| 9 | **Objections** — the two questions you know you'll be asked | 2 min |
| 10 | **Close + CTA** | 1 min |

### Act 1: Cold open (~2 min)

> "Say a coding agent renames a field in an API response. It updates its own unit tests to
> match, so the build stays green. It adds a request field and marks it required, which also
> seems harmless — the build is still green. Nothing local tells it, or you, that a consumer
> just broke. That's not a hypothetical. It's what a perfectly normal, perfectly plausible
> 'clean up this endpoint' request does, every time, unless something else is watching the
> contract."

- **Show:** title slide, then the slide stating the failure as a picture — a green checkmark
  next to a broken consumer icon.

### Act 2: Why it happens (~2 min)

> "This isn't a bug in the agent. A code-quality tool like Sonar analyzes code — style, dead
> branches, complexity. It was never built to ask whether this version of the contract is
> still compatible with the last one, or who out there is calling it. That gap is structural,
> not a tooling oversight somebody forgot to patch."

- **Show:** the slide naming the gap — "Sonar and friends check code. Nothing checks the
  contract, or who depends on it."

### Act 3: The idea (~2 min)

> "Here's what closes that gap: a quality gate, built for coding agents, that sits in CI, not
> on the agent's own machine. Five steps, each one a single Postman CLI command: a skills
> check, a contract lint, the committed Postman tests replayed against a mock generated from
> the *new* contract, an AI-readiness score, and an impact check against the Context Graph —
> who actually depends on this API. Every step is deterministic except one, and that one is
> flagged honestly. The gate produces a score, a letter rating, and hard blockers that
> override the score. And because it runs in CI, the agent that wrote the change cannot skip
> it, edit it in its favor, or see the secret it authenticates with."

- **Show:** the five-step diagram slide (skills, lint, tests, ai-readiness, impact →
  score/rating/blockers), then the architecture slide: contract → code + Postman objects →
  gate in CI → score + blockers.

### Act 4: Demo, part 1 — tour the repo, baseline gate (~3 min) — live demo starts here

> "This is the real repo. `contract/openapi.yaml` is the source of truth — everything else
> derives from it. The Postman collection, with its assertions, and a local mock both live
> right here, versioned next to the code, and they're kept in sync with a real Postman
> workspace. `gate/` is the five steps; `quality-gate.yml` is the weights and the rating
> scale. Let's run it once, clean, so you have a 'before.'"

- **Show:** switch to the terminal tab in the product repo clone. `git switch main`.
- **Show:** the repo tree — `contract/`, `src/`, `postman/`, `gate/`, `.github/workflows/`,
  `.claude/agents/`. Open `contract/openapi.yaml`, point at the operations and the
  `Appointment` envelope (`id`, `status`, `created_at`, `updated_at`). Open the Postman
  collection folder and one request with its `pm.test` script.
- **Do:**
  ```bash
  ./mvnw spring-boot:run   # or ./scripts/check-api.sh if the repo ships one
  ```
  then, in another pane:
  ```bash
  curl localhost:8080/health
  curl localhost:8080/api/appointments
  ```
- **Show (payoff):** point at the `X-Request-Id` response header — the contract declares it,
  the response has it.
- **Do:**
  ```bash
  ./gate/run-all.sh
  ```
- **Show (payoff):** the baseline report — expected **rating A**, `skills-check` shown in
  grey (`not_available`, excluded from the score, never counted as a pass), `ai-readiness`
  warn-only. *(The brief's own baseline run reports ~93/100 on `main`; treat that number as
  the design target, not as something this talk has personally rehearsed yet — say "about 93"
  unless you've just watched your own run say it.)*

### Act 5: Demo, part 2 — a naive coding agent "cleans up" the API (~5 min)

> "Now the part that makes the point. I'm not going to ask the careful agent that already
> knows not to do this. I'm going to ask a naive one — same tools, same order of work, but
> without the rule that says 'never rename or remove something a consumer uses.' That's not a
> strawman. That's what a coding agent looks like before anyone teaches it about consumers at
> all. And the request I'm giving it is exactly the kind a product owner emails you."

- **Show:** switch to the Claude Code session open in the product repo clone.
- **Do** — launch the demo-only agent with the brief's exact part-3 request:
  ```
  Launch api-coder-naive on this: Clean up the list endpoint: rename `count` to `total`
  in the response, and make `patient_id` required when booking an appointment.
  ```
- **Show (payoff):** narrate the coder working in order — contract, then Java code, then its
  own unit tests, then the Postman collection, a local gate run, then `git push` to a branch
  named `demo/live-<slug>` (never `main`). Point out the moment it reports the local gate
  passed, or doesn't — either is fine, the CI gate is the one that counts.

> "Notice what it did *not* do: it didn't ask who else calls this. It updated its own tests to
> match its own change, which is exactly how a build stays green while an API breaks."

### Act 6: Demo, part 3 — the gate fails it, a read-only agent briefs the coder (~5 min)

> "That push just triggered CI. No pull request needed — five gate jobs are running in
> parallel right now."

- **Show:** switch to the browser tab, the **Actions** run that started on the push.
- **Do**, back in the Claude Code session:
  ```
  Launch gate-reviewer on branch demo/live-<slug>, commit <SHA>. Wait for the GitHub
  Actions run on that exact commit, read the gate report, and give me a prioritized
  fixes brief.
  ```
- **Show (payoff):** the reviewer confirms the run matches that exact SHA, downloads the
  `gate-report` artifact, and returns a structured verdict. *(Per the brief's own scenario
  file for this exact change: expected **rating C, around 70/100**, gate **FAILED**, with
  **two hard blockers** — the committed Postman collection still expects `count` in the list
  response, and the contract diff reports both the removed/renamed `count` property and the
  newly required `patient_id`, against the known consumer `patients-service`. `contract-lint`
  is expected to **pass** — lint checks the shape of a contract, not its compatibility with
  the last version, and that gap is exactly what steps 3 and 5 exist to cover. Say that out
  loud; it is the teaching point of this act, not a bug in the gate.)*
- **Show:** the PR/report's "What to fix (for the coding agent)" section, or the reviewer's
  own brief — same information, written for a human and for an agent.

> "The score alone — a C — would not have stopped this on its own. The two hard blockers are
> what actually fail the gate, whatever the average says."

### Act 7: Demo, part 4 — the fix round, the gate goes green (~4 min)

> "Now the brief goes back to the same agent that wrote the problem. Not a human relaying it
> — the brief, directly."

- **Do**, in the Claude Code session (same `api-coder-naive`, via its agent id):
  ```
  Send gate-reviewer's brief to api-coder-naive: keep `count` next to the new `total`
  field instead of removing it, and keep `patient_id` optional. Apply the fixes,
  re-run the gate locally, commit, and push to the same branch.
  ```
- **Show (payoff):** the coder narrates what changed, per finding — `count` restored
  alongside `total`, `patient_id` back out of `required`. Switch to the browser: the new
  Actions run on the same branch, same PR comment updated in place (not a second comment).
- **Show (payoff):** the updated report. Expected: rating back to **A or B**, no blockers.

> "Same two agents, same gate, and the only thing that changed between a failing run and a
> passing one is the brief one agent wrote and the other one acted on. No human copied
> anything between them."

### Act 8: What it costs (~2 min)

> "What you just watched has real limits, and I'd rather say them than have you find them.
> The skills-check step is `not_available` today — a real Postman CLI bug, not a design
> choice — and it's shown in grey, excluded from the score, never counted as a pass; that's
> the honest behavior for a step that can't run, not a silent green. The impact step is the
> one fuzzy part: the breaking-or-not verdict itself is a deterministic diff of the contract,
> but figuring out *who* depends on it comes from a Context Graph query that returns free
> text, retried up to three times — it can still miss a consumer. And the gate never merges
> anything. It reports. A human, or a branch-protection rule, still has to act on the
> verdict."

- **Show:** the slide listing the three limits, plain text, no apology framing.

### Act 9: Objections (~2 min)

> "Two questions, every time. First: doesn't a contract-lint pass mean the change was fine?
> No — lint checks the *shape* of a contract against governance rules, not its compatibility
> with the version before it. That's exactly why this gate has five steps and not one.
> Second: can this stop the merge? Not by itself — it's a CI check with a verdict; whether
> that verdict blocks a merge is a branch-protection setting on your repo, not something the
> gate enforces on its own."

- **Show:** objections slide, if the deck carries one.

### Act 10: Close + CTA (~1 min)

> "A green build only tells you the code you wrote agrees with the tests you also wrote. It
> was never going to catch a broken contract or a consumer it doesn't know about. The gate
> that does — five deterministic Postman CLI steps, independent of the agent, honest about
> what it can't do yet — is what let one agent catch another agent's plausible mistake, and
> brief it back without anyone standing in the middle."

- **Show:** CTA slide.
- CTA, read it out:
  - Postman CLI: <https://www.postman.com/product/postman-cli/>
  - API Context Graph: <https://www.postman.com/context-graph/>
  - Clone the product repo and run the gate yourself: `git clone
    https://github.com/Postman-Devrel/agent-quality-gate.git && ./gate/run-all.sh`

### What to cut when you are over

Cut act 9, then act 8, then compress act 2. If you are badly over, cut act 4's full repo tour
down to the contract file and the baseline score alone — the four live acts (5–7, and the
back half of 4) are the reason people came; shorten the setup around them, never the payoff.
**Never cut** the cold open (act 1) or act 6's payoff — reading the two hard blockers out
loud, and saying plainly that lint passed anyway, is where this talk lands.

---

## 5. Tear down / reset

```bash
./scripts/teardown.sh
```

Removes the demo branch (`demo/live-*`) locally and on the product repo's GitHub remote,
closes the demo PR if one was opened, and returns the local clone to `main`. Safe to run when
setup never ran.

**It deliberately leaves standing:** the product repo's `main` branch, its Actions secrets,
and the Postman workspace / Context Graph connection — shared infrastructure this talk
doesn't own.

**It cannot clean up:** anything pushed to a branch *other* than the `demo/live-*` pattern, or
a manually renamed branch. Check `git branch -r` on the product repo clone by hand if a
rehearsal used a non-standard name.

### Full reset between sessions

```bash
./scripts/teardown.sh && ./scripts/setup.sh
```

---

## 6. Troubleshooting

| Issue | Fix |
|---|---|
| `skills-check` always shows `not_available` | That's the current, known behavior, not a misconfiguration — Postman CLI 1.73.0/1.75.0 answer `foreign` once `postman/skills` holds a `.py` file. Say so on stage: grey, excluded from the score, never a silent pass. Do not re-enable the workaround in git history; it was reverted on purpose. |
| `impact` shows 0 consumers, or a different consumer than expected | The step's Context Graph call is the one fuzzy, LLM-backed part. It retries empty answers up to 3 times but can still miss. Re-run the step; the structural "is this breaking" verdict itself is deterministic and does not change between re-runs. |
| `impact` is `not_available` entirely | The Postman CLI login in use is not on the team whose Context Graph has `appointments-service` ingested. Re-`postman login --with-api-key` with the right key. |
| A GitHub Actions run stays `queued` for minutes | Check the org/account Actions budget — a `$0` Actions budget has silently blocked all runs before. Fix the budget, don't wait it out on stage; narrate while a previously finished run sits open in a backup tab. |
| A push triggers two runs, one shows `cancelled` | Expected — a push to a branch with an open PR triggers both a `push` and a `pull_request` run; the concurrency group cancels the older one. That's not a failure, say so if anyone asks. |
| A live collection run fails oddly between takes | The collection's tests assume the seeded appointment exists fresh. Restart the API between local runs of the live check. |
| `gate/run-all.sh` ever points at a real server instead of a mock | Never run the committed collection against `https://myhealthcare.dev` — the spec lists it first, but the committed collection and the gate both pin to `http://localhost:8080` / a generated mock. If you ever regenerate a collection from the spec by hand, set `baseUrl` to localhost before running it. |
| The reviewer agent can't find a matching run | It must match the exact commit SHA that was pushed, not just "the latest run on this branch." If you pushed again between launching the coder and launching the reviewer, re-read the SHA the coder reported. |
| Nothing in `.claude/agents/` shows up | Agents load at session start only. If you added or edited an agent file and kept using an old Claude Code session, open a new one. |
| You're tempted to merge, delete, or force-push on `main` to "clean up" mid-demo | Don't. The demo only ever touches a `demo/live-<slug>` branch; `./scripts/teardown.sh` is the cleanup path. |

---

## 7. Additional resources

| Resource | Link |
|---|---|
| **The product repo** | <https://github.com/Postman-Devrel/agent-quality-gate> — clone it, break it, watch the gate |
| Its five gate steps | `gate/` in the product repo |
| Its gate config (weights, rating scale, blockers) | `quality-gate.yml` in the product repo |
| Its two (plus one demo-only) agents | `.claude/agents/api-coder`, `.claude/agents/gate-reviewer`, and the demo-only `api-coder-naive` |
| Postman CLI | <https://www.postman.com/product/postman-cli/> |
| Postman CLI command reference | <https://learning.postman.com/docs/postman-cli/postman-cli-options> |
| Postman CLI installation | <https://learning.postman.com/docs/postman-cli/postman-cli-installation/> |
| API Context Graph | <https://www.postman.com/context-graph/> |
| Same repo pattern, a different product story | [../postman-in-the-terminal/](../postman-in-the-terminal/) — also points at an external demo repo instead of bundling product code |
