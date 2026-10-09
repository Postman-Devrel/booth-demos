# Postman in the terminal (booth cut)

> [Lightning talk](../../../templates/formats/lightning-talk.md) — target length **10 minutes**. Delivered at booths and meetup lightning tracks. This is the slimmed-down cut of [content/short-talks/postman-in-the-terminal/](../../short-talks/postman-in-the-terminal/), which is the canonical folder: full product summary, prerequisites, troubleshooting, and the un-cut talk track all live there. This README only lists what's different in the 10-minute version and the commands typed on stage.

---

## The deck

Same deck as the short talk, one deck of record in Claude Design — `presentation_title: From Click to Terminal`, see `frontmatter.yaml`. The full deck is 18 slides (for the 25-minute cut); this booth cut uses only 8 of them. Confirmed 2026-10-09 — titles for the 10 cut slides (3, 4, 6, 7, 9, 10, 11, 12, 14, 16) have not been shared and are not guessed here.

## Act plan (4 acts, ~10 min)

| Act | Purpose | Slide(s) | Budget |
|---|---|---|---|
| 1 | **Hook** — title, then the pyramid that frames the whole talk | 1, 2 | 0:50 |
| 2 | **The setup** — each layer of the pyramid: the tool, the CLI, the plugin | 5, 8, 13 | 3:00 |
| 3 | **The demo** — the real repo, the PR, the CI agent, the Context Graph, the verdict | 15 (**live demo starts here**) + ~5 min live | ~5:15 |
| 4 | **The close** — the pyramid again, then the CTA | 17, 18 | 1:05 |

Total ≈ 10:10. These are the presenter's own timings, faster than the per-slide pace of the 25-minute cut — validate in rehearsal.

### Act 1: Hook (~0:50)

> "Say you ask your coding agent to check whether an API change is safe. It only knows what you just told it, right now. Hand the same question to a CI job, where nobody's even there to ask, and it has nothing at all."

- **Show:** slide 1 — *From Click to Terminal* (0:20).
- **Show:** slide 2 — *The pyramid of agentic API engineering* (0:30), the shape the rest of the talk follows: what the agent needs, layer by layer.

### Act 2: The setup (~3:00)

> "The fix: commit what the agent needs to know, as Postman skills. They reach an agent two ways — the Postman Claude Code plugin puts them in your own agent, `postman init` commits the same skills into a repo so a CI agent, with nobody prompting it, gets them too. What's next is the second path, live."

- **Show:** slide 5 — *What an agent needs from a tool* (1:00), the base of the pyramid.
- **Show:** slide 8 — *One command, two readers* (1:00), the CLI layer.
- **Show:** slide 13 — *Postman plugin: how the agent picks the right skill* (1:00), the plugin layer.

> ⚠️ The talk track above paraphrases the thesis already in this folder's `frontmatter.yaml`; it is not verbatim deck copy — the deck's own per-slide key message wasn't shared when this README was written. Check it against the actual slides in rehearsal.

### Act 3: The demo (~5:15)

- **Show:** slide 15 — *Live demo* (0:15), the bridge into the live part.

Exactly the short talk's acts 4 and 5, run with the same scripts. For the full talk track, click track, prerequisites, and troubleshooting, see **[the short talk's README](../../short-talks/postman-in-the-terminal/README.md#4-talk-track-and-click-track)**. Only the commands typed on stage are copied here:

```bash
# in /tmp/postman-plugin-pr-review-demo
git checkout -b remove-blood-type
# remove the blood_type property from the Patient schema in openapi.yaml
git add openapi.yaml
git commit -m "Remove blood_type from the patient contract"
git push -u origin remove-blood-type
gh pr create --fill
```

Then: watch the PR, switch to the Postman app's Context Graph UI while the CI agent thinks, switch back and read its comment out loud.

### Act 4: The close (~1:05)

> "An agent's Postman skills live in files, not in a chat history. Install the plugin, and your own agent gets them. Run `postman init`, and the agent nobody is prompting gets them too."

- **Show:** slide 17 — *What to take away* (0:45), the pyramid one more time.
- **Show:** slide 18 — *Try it* (0:20), the CTA:
  - `npx @postman/postman-plugin`, then ask your own agent to review your next API change
  - Postman CLI: <https://www.postman.com/product/postman-cli/>
  - API Context Graph: <https://www.postman.com/context-graph/>
  - Grab the full 25-minute version: `git clone https://github.com/Postman-Devrel/booth-demos.git` → `cd booth-demos/content/short-talks/postman-in-the-terminal`

### What to cut when you are over

Act 2 first (fold it into the hook, one sentence). Never cut the payoff in act 3 (reading the CI agent's comment) or the CTA.

---

## Mapping: short-talk act → this cut

| Short-talk act | In the 10-minute cut |
|---|---|
| 1. Cold open | **kept** — this cut's act 1 (slides 1, 2) |
| 2. Why it happens | **kept, compressed to one slide** — folded into act 2 (slide 5) |
| 3. The idea | **kept, compressed to two slides** — folded into act 2 (slides 8, 13) |
| 4. Demo, part 1 | **kept** — this cut's act 3, commands only |
| 5. Demo, part 2 | **kept** — this cut's act 3, full payoff kept |
| 6. What it costs | **cut** — answer one-to-one if asked |
| 7. Objections | **cut** — answer one-to-one if asked |
| 8. Close + CTA | **kept** — this cut's act 4 (slides 17, 18), condensed |

---

## Setup / teardown

```bash
./scripts/setup.sh      # wraps the short talk's setup.sh
# ... deliver it ...
./scripts/teardown.sh   # wraps the short talk's teardown.sh
```

Both scripts exec the short talk's own `scripts/setup.sh` / `scripts/teardown.sh` — see [content/short-talks/postman-in-the-terminal/README.md](../../short-talks/postman-in-the-terminal/README.md) for what they check, the pre-demo checklist, and troubleshooting. There is nothing booth-specific to set up beyond what that script already does.
