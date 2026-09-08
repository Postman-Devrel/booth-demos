---
name: content-generator
description: Scaffold a new piece of DevRel content in this mono-repo — a lightning talk, short talk, standard talk, or bootcamp. Creates content/<format>/<slug>/ with frontmatter.yaml, a presenter-ready README (product summary, prerequisites, setup, act-by-act talk/click track, teardown, troubleshooting), executable setup.sh/teardown.sh, and a self-contained HTML deck sized to the format. Use when the user wants to scaffold, create, or build a new talk, booth demo, workshop, or bootcamp.
---

# Content Generator

Scaffold a new piece of content in this repo from front matter.

## Goal

Every piece of content — a 10-minute booth demo or a full-day bootcamp — uses the same
skeleton: front matter, a README that is the single source of truth, a self-contained deck,
and `setup.sh` / `teardown.sh` that make it repeatable. What changes between them is the
**format**, and the format decides the structure.

## Step 1 — establish the format

This is the first question and it is not optional. Ask the user which format the content is,
then read the matching definition file and follow it:

| Format | Length | Folder | Definition |
|---|---|---|---|
| `lightning-talk` | ~10 min — *an NBA quarter* | `content/lightning-talks/` | [templates/formats/lightning-talk.md](../../../templates/formats/lightning-talk.md) |
| `short-talk` | 25–30 min — *a handball half* | `content/short-talks/` | [templates/formats/short-talk.md](../../../templates/formats/short-talk.md) |
| `standard-talk` | 40–45 min — *a football half* | `content/standard-talks/` | [templates/formats/standard-talk.md](../../../templates/formats/standard-talk.md) |
| `bootcamp` | 50 min+, topic-dependent | `content/bootcamps/` | [templates/formats/bootcamp.md](../../../templates/formats/bootcamp.md) |

**Read the format definition file before generating anything.** It sets the act plan, the
act budgets, the deck size, the extra folders, and the pacing rules. This SKILL.md only
describes what every format shares.

If the user is unsure, ask what slot they were given. If they describe more content than the
slot holds, say so and recommend the next format up rather than compressing.

## Step 2 — collect front matter

Ask for anything not already supplied. The canonical field list with comments lives in
[templates/content/frontmatter.yaml](../../../templates/content/frontmatter.yaml) — copy it
and fill it in.

Required: `format`, `length`, `product`, `name`, `use_case`, `key_messages`, `cta`,
`presentation_title`.
Recommended: `owner`, `status`, `audience`, `venues`, `primary_api`, `brand_style`.

`length` is the *real* target, not the format's nominal range — a 27-minute slot is
`format: short-talk`, `length: 27m`.

## Step 3 — generate the folder

```
content/<format-folder>/<slug>/
  frontmatter.yaml
  README.md
  presentation/index.html
  scripts/setup.sh
  scripts/teardown.sh
  <plus whatever the format definition requires — bootcamps add modules/, exercises/,
   solutions/, handout.md, and scripts/checkpoint.sh>
```

Start from [templates/content/](../../../templates/content/) — `README.md`,
`frontmatter.yaml`, and the two scripts are skeletons with the contract written into their
comments.

No per-content `.claude/skills/` directories. Setup and teardown are shell scripts only, so
they work without Claude Code and run instantly in a hallway ten minutes before the slot.

After generating, run `./scripts/validate-content.sh` from the repo root and fix anything it
reports, then add the new row to the catalog table in the root `README.md`.

## README sections

Every `README.md` must include these sections, in this order. The README is the **single
source of truth** the presenter reads — it must contain everything they need to deliver
without improvising.

### 1. Product summary
Product, use case, format and length, audience, the one-paragraph story (the narrative arc),
and the CTA. State up front which parts stand alone offline and which need the network.

### 2. Pre-requisites
A table: **Requirement** | **How to get it**. Version minimums, install links, account setup,
and any workspace prep that must happen before the day. For bootcamps, split this into
*facilitator* and *attendee* prerequisites — the attendee list is the one you send out the
day before.

### 3. Setup
Point to `./scripts/setup.sh` and list exactly what it checks and prepares. Include an
authentication subsection if the product needs keys or OAuth. End with a **pre-flight
checklist** — markdown checkboxes covering everything that must be true before you start.

### 4. Talk track and click track (combined, act by act)
Structure the content as **acts** — or **modules**, for a bootcamp — following the act plan in
the format definition. For every act:

- **Act title and duration** — e.g. "Act 2: Generate the spec (2 min)"
- **Talk track** — the exact words the presenter says, as blockquotes (`>`). Not bullet
  points, not summaries — real sentences a presenter could read verbatim if the room goes
  cold.
- **Click track** — interleaved with the talk track at the point each action happens:
  - **Show:** what is on screen (browser tab, terminal, editor pane)
  - **Do:** the exact action — the literal command to type, the button to click, the URL to
    open. For agent demos, include the full prompt to paste.
  - **Show (payoff):** after every major action, switch to the destination system (IDE,
    Postman, browser, dashboard) and show the real artifact that was created. The audience
    must see proof the action produced a real result, not just terminal output. Never skip
    the payoff — if a step creates something, show it where it lives.

Act durations must sum to the format's content budget (which is *less* than the slot when the
format reserves Q&A). For 25 minutes and up, also name which acts are droppable and in what
order, so a presenter who has lost ten minutes can recover without improvising.

### 5. Tear down / reset
Point to `./scripts/teardown.sh` and describe what it cleans up. List manual steps explicitly
(deleting cloud resources, revoking keys). Include the teardown-then-setup sequence for a full
reset between sessions.

### 6. Troubleshooting
A table: **Issue** | **Fix**. Real failures — auth expired, network down, service restarting,
a port already bound. Each fix must be executable in under 30 seconds, on stage.

### 7. Additional resources
A table: **Resource** | **Link**.

## Script requirements

### setup.sh
- Executable (`chmod +x`)
- Validates every required tool, failing with the command that fixes it
- Prepares all local state so nothing is typed by hand at run time
- Idempotent — running it twice leaves the same ready state
- Warns (does not fail) on unreachable network dependencies, naming which acts they affect
- Opens the presentation as the last step
- Prints a clear status line per step (`[OK]` / `[WARN]` / `[FAIL]`)

### teardown.sh
- Executable (`chmod +x`)
- Stops anything setup started, removes generated artifacts, restores edited files
- Safe to run when setup never ran; never exits early on a missing artifact
- Prints a clear status line per step

### checkpoint.sh (bootcamps only)
- `./scripts/checkpoint.sh <module>` exits 0 when the attendee's work is correct
- The output tells them what is wrong, not just that something is

## Presentation

Generate a self-contained `presentation/index.html` — one file, inline CSS and JS, no external
dependencies beyond Google Fonts. It has to render on dead conference wifi.

### Brand style

Run `/design-sync` to pull the team brand style and apply the returned tokens. If it is
unavailable or the user specifies `brand_style: manual`, ask for primary colour, accent
colour, and font family.

### Slide count and structure

Set by the format definition. Every format starts from the same spine — **Title → The Problem
→ The Journey → Live Demo → CTA** — and the longer formats expand the middle:

- `lightning-talk` — exactly those 5.
- `short-talk` — 10–14: one slide per key message, a before/after comparison, an architecture
  or flow diagram, an objections slide.
- `standard-talk` — 16–20: the above plus section dividers between idea blocks and a backdrop
  slide per demo beat.
- `bootcamp` — modular: a short deck per module, or one deck with hard module dividers.

Note in the README which slide the live demo starts on.

### Technical requirements

- **No auto-advance** — slides change only on user input
- **Keyboard navigation** — ArrowRight/Space = next, ArrowLeft = prev
- **Click navigation** — left half of screen = prev, right half = next
- **Navigation dots** bottom centre, slide counter bottom right
- **Full-viewport** — each slide fills 100vw × 100vh, no scrolling
- **Slide transitions** — fade + horizontal translate, ~0.5s
- **Dark background** by default — high contrast for booths and bright rooms
- **Responsive text** — readable from 6 feet on a booth monitor

## Rules

- NEVER invent a fake demo, fake product data, or fake customer numbers.
- Establish the format before anything else, and follow its definition file.
- Ask follow-up questions when inputs are unclear (which API, which audience, which venue).
- Setup and teardown must be automated as much as possible via shell scripts.
- Slides must not auto-advance.
- `setup.sh` must open the presentation so the presenter is ready.
- If the same material already exists in another format, set `derived_from` in the front
  matter and reuse the assets rather than forking them.
