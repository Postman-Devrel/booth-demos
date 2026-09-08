# Format: Lightning Talk

| | |
|---|---|
| **Slug** | `lightning-talk` |
| **Folder** | `content/lightning-talks/<slug>/` |
| **Length** | ~10 minutes — *an NBA quarter* |
| **Typical slot** | Booth demo, lightning track, meetup opener, sales-floor walkthrough |
| **Q&A** | None inside the slot. Questions happen after, one-to-one. |

## When to pick this

One idea, one payoff, no branching. You are proving a single claim to someone who may
walk away mid-sentence. If the content has a "and then the other thing" in it, it is a
[short talk](short-talk.md), not a lightning talk.

## Act plan (3–4 acts)

| Act | Purpose | Budget |
|---|---|---|
| 1 | **Hook** — the failure or friction the audience already recognises | 1–2 min |
| 2 | **The setup** — name what you are about to do and what "working" will look like | 1 min |
| 3 | **The demo** — one continuous run to one visible artifact | 5–6 min |
| 4 | **The close** — one sentence of meaning, then the CTA | 1 min |

Every act carries both a **talk track** (verbatim blockquotes) and a **click track**
(`Show:` / `Do:` / `Show (payoff):`).

## Deck

5 slides: Title → The Problem → The Journey → Live Demo → CTA.

## Required files

```
content/lightning-talks/<slug>/
  frontmatter.yaml
  README.md
  presentation/index.html
  scripts/setup.sh
  scripts/teardown.sh
```

No exercises, no modules, no lab. If you are tempted to add them, you have the wrong format.

## Pacing rules

- One payoff. Not two. The audience remembers the artifact, not the argument.
- Setup must be zero-typing at run time — `setup.sh` leaves the screen ready to demo.
- Assume the network is hostile. State in the README which acts survive offline.
- Never end on a terminal. End on the thing that got created, where it lives.

## What to cut when you are over

Act 2 first (fold the setup into the hook), then the architecture explanation inside Act 3.
Never cut the payoff or the CTA.
