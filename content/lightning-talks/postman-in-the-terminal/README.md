# Postman in the terminal (booth cut)

> [Lightning talk](../../../templates/formats/lightning-talk.md) — target length **10 minutes**. Delivered at booths and meetup lightning tracks. This is the slimmed-down cut of [content/short-talks/postman-in-the-terminal/](../../short-talks/postman-in-the-terminal/), which is the canonical folder: full product summary, prerequisites, troubleshooting, and the un-cut talk track all live there. This README only lists what's different in the 10-minute version and the commands typed on stage.

---

## The deck

Same deck as the short talk, one deck of record in Claude Design — `presentation_title: From Click to Terminal`, see `frontmatter.yaml`. This cut uses only the slides marked `booth` in the deck's outline. Every slide below is `[slide ?]` because that outline wasn't available when this README was written — re-map against the real deck before presenting; never invent a slide title in the meantime.

## Act plan (4 acts, ~10 min)

| Act | Purpose | Slide(s) | Budget |
|---|---|---|---|
| 1 | **Hook** — the agent that only knows what you just told it | `[slide ?]` | 1–2 min |
| 2 | **The setup** — committed Postman skills, two paths, one sentence each | `[slide ?]` | 1 min |
| 3 | **The demo** — the real repo, the PR, the CI agent, the Context Graph, the verdict | `[slide ?]` (**live demo starts here**) | 5–6 min |
| 4 | **The close** — one sentence, then the CTA | `[slide ?]` | 1 min |

### Act 1: Hook (~1–2 min)

> "Say you ask your coding agent to check whether an API change is safe. It only knows what you just told it, right now. Hand the same question to a CI job, where nobody's even there to ask, and it has nothing at all."

- **Show:** `[slide ?]` (title), `[slide ?]` (the chat-window problem).

### Act 2: The setup (~1 min)

> "The fix: commit what the agent needs to know, as Postman skills. They reach an agent two ways — the Postman Claude Code plugin puts them in your own agent, `postman init` commits the same skills into a repo so a CI agent, with nobody prompting it, gets them too. What's next is the second path, live."

- **Show:** `[slide ?]` (the two paths, one diagram), walked through, not typed live.

### Act 3: The demo (~5–6 min)

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

### Act 4: The close (~1 min)

> "An agent's Postman skills live in files, not in a chat history. Install the plugin, and your own agent gets them. Run `postman init`, and the agent nobody is prompting gets them too."

- **Show:** `[slide ?]` (CTA):
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
| 1. Cold open | **kept** — this cut's act 1 |
| 2. Why it happens | **spoken** — one line, folded into act 2 |
| 3. The idea | **spoken** — one line, folded into act 2 |
| 4. Demo, part 1 | **kept** — this cut's act 3, commands only |
| 5. Demo, part 2 | **kept** — this cut's act 3, full payoff kept |
| 6. What it costs | **cut** — answer one-to-one if asked |
| 7. Objections | **cut** — answer one-to-one if asked |
| 8. Close + CTA | **kept** — this cut's act 4, condensed |

---

## Setup / teardown

```bash
./scripts/setup.sh      # wraps the short talk's setup.sh
# ... deliver it ...
./scripts/teardown.sh   # wraps the short talk's teardown.sh
```

Both scripts exec the short talk's own `scripts/setup.sh` / `scripts/teardown.sh` — see [content/short-talks/postman-in-the-terminal/README.md](../../short-talks/postman-in-the-terminal/README.md) for what they check, the pre-demo checklist, and troubleshooting. There is nothing booth-specific to set up beyond what that script already does.
