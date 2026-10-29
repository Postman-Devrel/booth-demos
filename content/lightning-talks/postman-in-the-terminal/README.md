# Postman in the terminal (booth cut)

> [Lightning talk](../../../templates/formats/lightning-talk.md) — target length **10 minutes**. Delivered at booths and meetup lightning tracks. This is the slimmed-down cut of [content/short-talks/postman-in-the-terminal/](../../short-talks/postman-in-the-terminal/), which is the canonical folder: full product summary, prerequisites, troubleshooting, and the un-cut talk track all live there. This README only lists what's different in the 10-minute version and the commands typed on stage.

**The claim:** a change that looks harmless locally fails a quality gate, and your own Claude Code session fixes it through that gate without you typing a Postman command. **The quality gate is not a Postman product.** It is a use case the (fictional) healthcare org's platform team built with Postman: the CLI, committed skills and the Context Graph. Say so on stage.

---

## The deck

Same deck as the short talk (`presentation/index.html` in the short talk folder, built from the Claude Design deck "From Click to Terminal", see `frontmatter.yaml`). The full deck is 18 slides; this booth cut uses **6**: 1, 2, 14, 15, 17, 18. Slides 3 to 13 and 16 are cut: nobody at a booth waits through the pyramid layer by layer. `setup.sh` opens the deck.

## Act plan (4 acts, ~10 min)

| Act | Purpose | Slide(s) | Budget |
|---|---|---|---|
| 1 | **Hook** — an agent renames a field and breaks 32 services it has never heard of | 1, 2 | 1:00 |
| 2 | **The setup** — where an agent's Postman skills come from, and what "working" will look like | 14, 15 | 1:00 |
| 3 | **The demo** — rename by hand, PR, the gate fails, your own session runs the gate loop | — (live terminal and browser) | 6:30 |
| 4 | **The close** — one sentence of meaning, then the CTA | 17, 18 | 1:00 |

Total ≈ 9:30, leaving 30 s of slack for the loop. These are estimates: validate in rehearsal, and time the gate loop in particular (see act 3c).

### Act 1: Hook (~1:00)

> "Ask a coding agent to rename a field in an API. It will do it, cleanly, in thirty seconds. The code compiles, the tests it wrote pass. And it has just broken thirty-two other services it has never heard of. Nothing it can see tells it so."

- **Show:** slide 1 — *From Click to Terminal* (0:15).
- **Show:** slide 2 — *The pyramid of agentic API engineering* (0:45). Say it once: an agent needs a command per step, and skills that say which one.

### Act 2: The setup (~1:00)

> "The answer isn't a smarter agent, it's a better toolbox. Every step is one Postman CLI command, and the skills that say which command, and when, are files. The Postman plugin puts them in your own Claude Code; `postman init` commits them into a repo. Now a real repo, and a real gate."

- **Show:** slide 14 — *`postman init`* (0:30).
- **Show:** slide 15 — *Live demo* (0:30). Name the setup in two sentences and move on:

> "This is `patients-service`, a repo of a made-up healthcare org. Its platform team built a quality gate with Postman, and every service calls it from CI. The gate is their use case, not a Postman product. There is no coding agent in this repo: the coder is my own Claude Code."

What "working" looks like: the gate goes red on my change, and my session turns it green, or stops and tells me why. I never merge.

### Act 3: The demo (~6:30)

Exactly the short talk's acts 4b and 5, run with the same scripts. **Cut from the short talk:** the workspace tour (4a), the gate repo tour (6a) and the Context Graph UI (6b). For the full talk track, click track, prerequisites and troubleshooting, see **[the short talk's README](../../short-talks/postman-in-the-terminal/README.md#4-talk-track-and-click-track)**.

#### 3a. The change, by hand (~1:15)

> "I'm the developer having a tidy-up afternoon. `mrn` is cryptic, `medical_record_number` reads better. I rename it in the responses, and leave the request bodies alone."

- **Do:** terminal tab 1, in `/tmp/healthcare-patients`:

  ```bash
  git checkout -b demo/live-rename-mrn
  # in openapi.yaml, rename mrn -> medical_record_number on the response side only:
  #   the Patient schema (required, the property, its example, the description)
  #   and the mrn: keys in the response examples of PatientPage, PatientSearchResult, PatientSummary
  #   leave PatientCreateRequest and PatientUpdateRequest alone
  git add openapi.yaml
  git commit -m "Rename mrn to medical_record_number in patient responses"
  git push -u origin demo/live-rename-mrn
  gh pr create --fill
  ```

  **Never `git add -A`** in the clone: a Claude Code security hook deletes `.claude/settings.json` there, and `-A` would commit the deletion.

> "A readability clean-up. Nothing local looks wrong. Open the PR."

#### 3b. The gate fails it (~1:15)

- **Show:** the PR in the browser. The gate's sticky comment, "API quality gate", lands about 80 s after the push (CI rehearsal of 2026-10-29). Talk through the wait with the line below, then read the real comment.

> "This check isn't mine and it isn't the agent's. It's the platform team's gate, and every step is a Postman CLI command."

- **Say what the comment says.** The rehearsal read **rating D (60/100), FAILED (the bar is B), two blockers**: `contract-tests` (3/10 assertions pass, the collection still expects `mrn`) and `impact` (gate 0.6.3 words it "the change breaks 32 known consumers"; the rehearsal ran 0.5.0; the count comes from the Context Graph). Read the real comment on the day, the numbers can move. The comment opens with the gate score change against main (gate 0.6.3): read it; don't quote the short talk's format examples as results.

> "Rating D, two blockers. The collection is the consumers' side of the contract, and the impact step says thirty-two services consume this one. I could fix that myself. Instead I hand it to my own Claude Code."

#### 3c. The gate loop (~4:00)

- **Do:** terminal tab 2, your own `claude` session in the clone (Postman plugin and the platform team's gate plugin), type:

  ```
  The quality gate failed on demo/live-rename-mrn. Run the gate loop until the gate passes. Don't merge.
  ```

- **Show (narrate while it works):** the `gate-loop` skill takes the PR title as the intent to preserve and never reverts it; the read-only `gate-verdict` reviewer finds the CI run for the exact commit, reads the verdict and writes a numbered fixes brief; your session applies it (keep `mrn` marked `deprecated`, add `medical_record_number` next to it, in the contract, code, tests and collection), pushes to the same branch, repeats. At most 3 rounds.

> "It never edits the gate, it doesn't merge, and it never sees the key CI uses. The rules live in files, not in my prompt."

- **Timing.** One CI round is about 80 s plus the agent's work, so the loop may not be done at 4:00. Don't wait in silence and don't cut the payoff: rehearse it and time it. If it is still working when the act ends, say so, read where the session is (the latest verdict and the PR comment), and carry on to the close. Never fake a result.
- **Two honest endings, both fine on stage:**
  - **Green:** the PR comment is updated in place to PASSED. "Same PR, same comment, green. The old field is still there, deprecated, so no consumer breaks. I asked for an outcome and I didn't type a Postman command."
  - **NEEDS_DECISION:** the PR is converted to draft with one comment listing the options (keep the old field deprecated, or version the API). "It stopped and told me why. That's where a human decides."
- **Do not merge**, in either case.

### Act 4: The close (~1:00)

> "A command per step, skills in files, a gate the agent can't edit. Install the plugin and your own agent gets the skills; run `postman init` and any agent in your repo does. The gate you saw is one team's use case, built from these blocks. Yours will look different."

- **Show:** slide 17 — *What to take away* (0:40).
- **Show:** slide 18 — *Try it* (0:20), the CTA:
  - `npx @postman/postman-plugin`, then ask your own agent to work an API change
  - Postman CLI: <https://www.postman.com/product/postman-cli/>
  - API Context Graph: <https://www.postman.com/context-graph/>
  - The demo repos: [healthcare-patients](https://github.com/healthcare-org-app/healthcare-patients) and [healthcare-api-quality-gate](https://github.com/healthcare-org-app/healthcare-api-quality-gate)
  - Grab the full 28-minute version: `git clone https://github.com/Postman-Devrel/booth-demos.git` → `cd booth-demos/content/short-talks/postman-in-the-terminal`

### What to cut when you are over

Act 2 first (fold it into the hook, one sentence, skip slide 14). Then the narration in 3b while the gate runs. Never cut the gate comment (3b), the loop's ending (3c) or the CTA.

If someone asks "does this block my merge?": the gate returns FAILED, and blocking is a branch-protection setting (required on appointments-service, not yet on patients' `main`). If they ask which field a consumer reads: the Context Graph answers at the endpoint level, not the field level, which is why the brief says "keep the old name, add the new one next to it". Answer one-to-one after the run.

---

## Mapping: short-talk act → this cut

| Short-talk act | In the 10-minute cut |
|---|---|
| 1. Cold open | **kept** — act 1 (slides 1, 2), the opening line only |
| 2. Why it happens | **cut** — folded into the act 1 line |
| 3. The idea | **kept, compressed** — act 2 (slide 14, one sentence) |
| 4. Demo, part 1 | **kept, 4b only** — act 3a. The workspace tour (4a) is cut |
| 5. Demo, part 2 | **kept** — act 3b (gate comment) and 3c (gate loop) |
| 6. Demo, part 3 | **cut** — no gate repo tour, no Context Graph UI |
| 7. What you just saw, and what it costs | **cut** — answer one-to-one if asked |
| 8. Objections | **cut** — answer one-to-one if asked |
| 9. Close + CTA | **kept** — act 4 (slides 17, 18), condensed |

---

## Offline

None of the demo survives offline: it needs GitHub Actions and the Postman cloud (lint governance, the Context Graph). Only acts 1, 2 and 4 (the slides) work without the network.

## Setup / teardown

```bash
./scripts/setup.sh      # wraps the short talk's setup.sh
# ... deliver it ...
./scripts/teardown.sh   # wraps the short talk's teardown.sh
```

Both scripts exec the short talk's own `scripts/setup.sh` / `scripts/teardown.sh`, which check the tooling and the gate plugin, refuse to run on a leftover `demo/live-*` PR or branch, clone `healthcare-org-app/healthcare-patients` to `/tmp/healthcare-patients`, and open the deck and the repos. Teardown closes the demo PR (draft or not), deletes the branch and removes the clone. See the [short talk's README](../../short-talks/postman-in-the-terminal/README.md) for the pre-demo checklist and troubleshooting. Prerequisites that bite at a booth: `postman login` done, `gh auth status` with push access to the patients repo, the gate plugin `healthcare-api-quality-gate` installed at **user level**, and the old `postman-agent-quality-gate` plugin disabled. There is nothing booth-specific to set up beyond that.
