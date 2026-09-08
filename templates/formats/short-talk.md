# Format: Short Talk

| | |
|---|---|
| **Slug** | `short-talk` |
| **Folder** | `content/short-talks/<slug>/` |
| **Length** | 25–30 minutes — *a handball half* |
| **Typical slot** | Conference breakout, meetup main slot, webinar, internal brown bag |
| **Q&A** | 3–5 minutes, usually after the slot rather than inside it. Budget acts to 25 min if the slot is 30. |

## When to pick this

There is an argument to make, not just a thing to show. You have room for a
*before* and an *after*, or for two or three ideas that build on each other, and the
audience is seated and staying.

## Act plan (6–8 acts)

| Act | Purpose | Budget |
|---|---|---|
| 1 | **Cold open** — the failure the audience recognises, stated as a story not a bullet | 2–3 min |
| 2 | **Why it happens** — the structural reason. Blame the situation, never the audience | 3 min |
| 3 | **The idea** — name the thing you are proposing, in one sentence they could repeat | 2 min |
| 4 | **Demo, part 1** — the *before*, or the first of the ideas | 4–5 min |
| 5 | **Demo, part 2** — the *after*, or the second idea building on the first | 5–6 min |
| 6 | **What it costs** — how this is built and maintained once the applause stops | 3 min |
| 7 | **Objections** — the two questions you know you will be asked, answered pre-emptively | 2–3 min |
| 8 | **Close + CTA** | 1–2 min |

Acts 4 and 5 are the reason people came. If the deck is running long, the deck loses,
not the demo.

## Deck

10–14 slides. Beyond the lightning five, you have room for:

- a slide per key message rather than one crowded card grid,
- a "before/after" comparison slide the demo pays off,
- an architecture or flow diagram,
- an objections slide.

Mark in the README which slide the live demo starts on, so the presenter knows the
handoff point.

## Required files

```
content/short-talks/<slug>/
  frontmatter.yaml
  README.md
  presentation/index.html
  scripts/setup.sh
  scripts/teardown.sh
  <supporting assets>/     # optional: sample app, specs, fixtures, a local site
```

Supporting assets are welcome; exercises and modules are not — the audience is watching,
not typing.

## Pacing rules

- The audience will sit through explanation *if* it has already seen the failure. Cold open first, always.
- No act longer than 6 minutes without something changing on screen.
- State offline behaviour per act in the README. A 30-minute slot on conference wifi will find your weakest dependency.
- Rehearse the transition into the live demo — it is where short talks die.

## What to cut when you are over

Act 6, then Act 7, then compress Act 2. Never cut the cold open or the second half of
the demo.
