# Format: Standard Talk

| | |
|---|---|
| **Slug** | `standard-talk` |
| **Folder** | `content/standard-talks/<slug>/` |
| **Length** | 40–45 minutes — *a football half* |
| **Typical slot** | Conference keynote-adjacent slot, deep-dive session, customer workshop opener |
| **Q&A** | 5 minutes, reserved **inside** the slot. Acts must sum to 35–40 min. |

## When to pick this

Three or more ideas that need each other, or one idea that only convinces after you have
shown it surviving production concerns. You have enough time that the audience will notice
if the middle sags — structure accordingly.

## Act plan (8–10 acts)

| Act | Purpose | Budget |
|---|---|---|
| 1 | **Cold open** — the failure, told as a specific incident | 3 min |
| 2 | **Why now** — what changed in the landscape that makes this urgent | 4 min |
| 3 | **Idea 1 + demo beat** | 6 min |
| 4 | **Idea 2 + demo beat** — builds on 1, does not restart | 6 min |
| 5 | **Idea 3 + demo beat** | 6 min |
| 6 | **Putting it together** — one live run through the whole pipeline | 6 min |
| 7 | **Production concerns** — cost, drift, failure modes, who owns it on Monday | 4 min |
| 8 | **Anti-patterns** — where this approach is the wrong choice | 3 min |
| 9 | **Close + CTA** | 2 min |
| 10 | **Q&A** *(reserved, not content)* | 5 min |

Act 8 is what separates a standard talk from a long product pitch. Keep it honest and
keep it in.

## Deck

16–20 slides. Add section-divider slides between the idea blocks — at this length the
audience needs to know where they are. Each demo beat gets a backdrop slide so the
presenter is never talking over a blank screen.

## Required files

```
content/standard-talks/<slug>/
  frontmatter.yaml
  README.md
  presentation/index.html
  scripts/setup.sh
  scripts/teardown.sh
  lab/                     # optional: a 5-min hands-on interlude the room can follow along with
    README.md              #   what the audience types, and the one command that proves it worked
  <supporting assets>/     # optional: sample app, specs, fixtures
```

A `lab/` is optional and is *not* a bootcamp exercise set — it is one short follow-along
the audience can do from their seat, with a single verification step. If it needs more
than five minutes or more than one checkpoint, the content wants to be a
[bootcamp](bootcamp.md).

## Pacing rules

- Three demo beats minimum. A 45-minute talk carried by slides is a webinar.
- Recap in one sentence at each act boundary — the room has drifted at least once.
- Budget acts to 40 minutes, not 45. Sessions start late.
- The README must say which acts can be dropped live and in what order, so the presenter
  can recover a lost ten minutes without improvising.

## What to cut when you are over

Act 8, then Act 2, then one of the three idea beats *whole* — never half of each. The
README should name which idea beat is the droppable one.
