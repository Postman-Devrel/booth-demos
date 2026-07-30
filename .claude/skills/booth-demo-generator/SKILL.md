---
name: booth-demo-generator
description: Generate a new booth demo from product front matter — creates a standard demo folder under demos/ with a presenter-ready README (product summary, prerequisites, setup, act-by-act talk/click track, teardown, troubleshooting), executable setup.sh/teardown.sh scripts, and a self-contained 5-slide HTML presentation. Use when the user wants to scaffold, create, or build a new conference/booth demo for a Postman product.
---

# Booth Demo Generator

Use this skill to create a new booth demo from product-specific front matter.

## Goal

Create a new demo folder under `demos/` that:
- uses a standard structure every time,
- accepts unique values from front matter,
- keeps setup and teardown logic isolated per demo,
- produces a repeatable README, talk track, click track, and presentation scaffold.

## Required inputs

Ask the user for the following values unless they are already provided:

```yaml
product:        # the product being demoed
name:           # human-readable demo title
use_case:       # one-sentence description of the problem being solved
primary_api:    # the API endpoint(s) or repo used in the demo
key_messages:   # bullet list of things the attendee should walk away knowing
cta:            # call-to-action links or install commands
demo_length:    # target duration (default: 10m)
presentation_title:  # title for the slide deck
brand_style:    # design-sync or manual
```

## Required output structure

Create a new folder at `demos/<demo-slug>/` with:

```
demos/<demo-slug>/
  frontmatter.yaml
  README.md
  presentation/
  scripts/
    setup.sh
    teardown.sh
```

No per-demo `.claude/skills/` directories. Setup and teardown are shell scripts only so they work without Claude Code and run instantly at a booth.

## README sections

Every generated `README.md` must include these sections, in this order. The README is the **single source of truth** a presenter reads at the booth — it must contain everything they need to run the demo without improvising.

### 1. Product summary
Product name, use case, story (the one-paragraph narrative arc of the demo), and CTA from frontmatter.

### 2. Pre-requisites
A table with two columns: **Requirement** and **How to get it**. Include version minimums, install links, account setup steps, and any workspace or environment prep that must happen before demo day.

### 3. Setup
Point to `./scripts/setup.sh` and list exactly what it checks and prepares. Include an authentication section if the product requires API keys or OAuth. End with a **pre-demo checklist** — a markdown checkbox list of everything the presenter should verify before the first attendee walks up.

### 4. Talk track and click track (combined, act by act)
Structure the demo as a sequence of **acts**, each with a timing estimate. For every act, include:

- **Act title and duration** — e.g., "Act 2: Generate the Spec (2 min)"
- **Talk track** — the exact words the presenter says, written as blockquotes (`>`). Not bullet points, not summaries — the actual sentences. A presenter should be able to read these verbatim if needed.
- **Click track** — interleaved with the talk track at the point where each action happens:
  - **Show:** what to display on screen (browser tab, terminal, editor pane)
  - **Do:** the exact action — the literal command to type, the button to click, the URL to open. For Claude Code demos, include the full prompt to paste.
  - **Show (payoff):** after every major action, switch to the destination system (IDE, Postman app, browser, dashboard — wherever the result landed) and show the audience the real artifact that was created. The audience must see proof that the action produced a real result, not just terminal output. Never skip the payoff — if a step creates something, show it where it lives.

The number of acts should fit the `demo_length`. A 10-minute demo typically has 5–7 acts including the opening problem statement and the closing CTA.

### 5. Tear down / reset
Point to `./scripts/teardown.sh` and describe what it cleans up. If there are manual cleanup steps (e.g., deleting cloud resources), list them explicitly. Include a "full reset between demo days" section showing the teardown-then-setup sequence.

### 6. Troubleshooting
A table of common issues and fixes — things that can go wrong at a booth (auth expired, network slow, service restarting). Two columns: **Issue** and **Fix**.

### 7. Additional resources
A table of links to docs, repos, learning paths, and related modules. Two columns: **Resource** and **Link**.

## Script requirements

### setup.sh
- Must be executable (`chmod +x`)
- Validate that required tools are installed (exit with a clear error if not)
- Prepare any local assets or state needed for the demo
- Open the presentation in a browser as the last step so the presenter is ready
- Print clear status messages for each step

### teardown.sh
- Must be executable (`chmod +x`)
- Remove generated artifacts and temporary state
- Restore the demo to a clean state for the next run
- Print clear status messages for each step

## Presentation

Generate a self-contained `presentation/index.html` — a single HTML file with inline CSS and JS, no external dependencies beyond Google Fonts.

### Brand style

Before generating the presentation, run `/design-sync` from the Claude Code CLI to pull the team brand style. Apply the returned design tokens (colors, fonts, gradients) to the presentation. If `/design-sync` is unavailable or the user specifies `brand_style: manual`, ask the user for primary color, accent color, and font family.

### Required slide structure (5 slides)

1. **Title slide** — product logos/icons, `presentation_title` from frontmatter, one-sentence subtitle derived from `use_case`
2. **The Problem** — why this matters to the audience. Use the `key_messages` to frame the pain points as a card grid (3–6 cards with icon, title, and one-line description)
3. **The Journey** — the demo flow as a numbered step sequence (3–5 steps with arrows between them), derived from the acts in the talk track
4. **Live Demo** — the key prompts or actions the presenter will type during the demo, shown as styled code/prompt blocks. This slide is the visual backdrop while the presenter works in the terminal
5. **CTA slide** — install command or primary action in a styled code block, supported tool/platform badges, and the CTA link from frontmatter

### Technical requirements

- **No auto-advance** — slides only change on user input
- **Keyboard navigation** — ArrowRight/Space = next, ArrowLeft = prev
- **Click navigation** — left half of screen = prev, right half = next
- **Navigation dots** at bottom center, slide counter at bottom right
- **Full-viewport** — each slide fills 100vw x 100vh, no scrolling
- **Slide transitions** — fade + horizontal translate, ~0.5s duration
- **Dark background** by default — booth presentations need high contrast
- **Responsive text** — readable from 6 feet away on a booth monitor

## Rules

- NEVER invent a fake demo or fake product data.
- Ask follow-up questions when required inputs are unclear (e.g., which API to use for a backend).
- Setup and teardown must be automated as much as possible via shell scripts.
- Slides must not auto-advance.
- `setup.sh` must open the presentation in a browser so the presenter is ready.
