# Format: Bootcamp

| | |
|---|---|
| **Slug** | `bootcamp` |
| **Folder** | `content/bootcamps/<slug>/` |
| **Length** | No fixed clock — 50 minutes to multiple days, set by the topic and the room. State the real number in `frontmatter.yaml`. |
| **Typical slot** | Workshop track, customer enablement, university session, internal training |
| **Q&A** | Continuous. There is no Q&A block because the whole thing is Q&A. |

## When to pick this

The room leaves able to *do* the thing, not just describe it. If nobody is typing, this is
a [standard talk](standard-talk.md) with extra slides.

## Structure: modules, not acts

A bootcamp is a sequence of modules. Every module is the same shape:

| Phase | Purpose | Budget |
|---|---|---|
| **Teach** | The concept and the demo of it, presenter-driven | 10–15 min |
| **Do** | The room builds it themselves from `exercises/NN-*/` | 15–25 min |
| **Checkpoint** | One command that prints pass or fail, so nobody silently falls behind | 5 min |

Size the bootcamp by counting modules, not minutes: a 60-minute session is two modules,
a half day is four to five, a full day is eight with a real break between each pair.

## Deck

Modular — one short deck per module, or one deck with clear module dividers. Slides are
signposts here, not the content. The exercise files are the content.

## Required files

```
content/bootcamps/<slug>/
  frontmatter.yaml
  README.md                  # facilitator guide: module-by-module teach notes and timings
  handout.md                 # attendee-facing: what they type, in order, with no talk track
  presentation/index.html
  modules/
    01-<name>.md             # teach notes + the exact demo the facilitator runs
    02-<name>.md
  exercises/
    01-<name>/
      README.md              # the task, the constraints, and the checkpoint command
      <starter files>
  solutions/
    01-<name>/               # mirrors exercises/ 1:1, complete and verified
  scripts/
    setup.sh                 # provisions the facilitator AND prints the attendee setup command
    teardown.sh
    checkpoint.sh            # ./scripts/checkpoint.sh 01 -> pass/fail for module 01
```

`solutions/` must mirror `exercises/` exactly, one directory per exercise, and must pass
its own checkpoint. `teardown.sh` resets the exercise directories to their starter state.

## Pacing rules

- **Never more than 20 minutes without hands-on.** This is the rule the format exists for.
- Every exercise ends in a runnable verification the attendee can trigger themselves. Not
  "you should see" — a command that exits 0.
- Attendee setup must be one command and must be sendable the day before. Assume a quarter
  of the room did not run it, and make module 01 survivable anyway.
- Publish a per-module time budget in the README and check the clock at every checkpoint —
  a bootcamp that overruns cuts the last module, which is always the best one.
- Solutions are handed out at each checkpoint, not at the end. Someone who is stuck at
  module 02 should not be stuck for the rest of the day.

## What to cut when you are over

Whole modules from the end, announced up front ("we will get through three of the four").
Never cut the Do phase to preserve the Teach phase — that inverts the point of the format.
