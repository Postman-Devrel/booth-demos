# Astropods — Where Agents become Teammates

> [Lightning talk](../../../templates/formats/lightning-talk.md) — target length **10 minutes**. This README is the single source of truth.
> Read it top to bottom before you present; everything you need is here.

Everything for the Astropods talk in one place: the slides (a self-contained HTML deck in the Astropods theme), the demo repo, the content guide, two recorded walkthroughs, the blog, and the video series, all linked from one place. The live demo takes a first agent from `ast project create` to running locally, and optionally to a deployed blueprint. Anyone who wants more leaves with the resource list in section 7.

---

## 1. Product summary

- **Product:** Astropods — a platform for building, deploying, and managing AI agents, with infrastructure for models, knowledge, tools, messaging, and observability.
- **Use case:** Explain what Astropods is and show a first agent going from a local project to a running (and optionally deployed) teammate.
- **Format:** lightning-talk (10m) — see [templates/formats/lightning-talk.md](../../../templates/formats/lightning-talk.md)
- **Audience:** Developers and platform teams with an agent that works on a laptop and no clear path to production.

**The Astropods lifecycle (four stages):**

| Stage | What it is |
|---|---|
| **Project** | Local code plus `astropods.yml`, created and run with the `ast` CLI |
| **Blueprint** | A versioned, deployable snapshot of the project (private by default; `AGENT.md` becomes the Agent Card) |
| **Agent** | A running, hosted instance of a blueprint, optionally wired to Slack with `--adapter slack` |
| **Observability** | Usage, cost, traces, evals, and monitoring for the running agent |

**The story (the narrative arc):**

> An agent that works on your laptop is not a teammate yet. A teammate is deployed, reachable where your team already works, and accountable — you can see what it did and what it cost. Astropods is the layer that gets an agent from a project folder to that: one CLI to create and run it, a blueprint to version it, a hosted agent to run it, and traces to watch it.

**CTA:**

- Install the CLI: `curl -fsSL https://astropods.com/install | sh`
- Quickstart: https://docs.astropods.com/get-started
- Blog and video series: see section 7

**Total time: ~10 min.** Act 1, 2 and 4 are slides and work fully offline (the deck is a local file). Act 3 needs Docker; `--model gateway` and deploy need network and `ast login`. The two Loom recordings are the offline fallback for Act 3.

### The deck

`presentation/index.html` is a self-contained HTML slideshow in the Astropods theme: 21 slides, no Figma embed, no network needed. 19 are pages from the Astropods Deck Template (images in `presentation/assets/slides/`), and 2 are native HTML slides (11 and 19).

**Keys:** arrows, space or Enter to move, `F` fullscreen, `O` overview (jump to any slide), `Home` / `End`. Open a slide directly with `index.html#11`.

| # | Slide | Used in |
|---|---|---|
| 1 | Title: One platform to govern every agent | Act 1 |
| 2 | Agenda: Today's flight plan | Act 1 |
| 3 | The problem (section 01) | Act 1 |
| 4 | A flock of chaos | Act 1 |
| 5 | The path to AI-native | Act 1 |
| 6 | The platform (quote) | Act 2 |
| 7 | Anything you ship is a governed agent | Act 2 |
| 8 | 53,647 tasks handled by agents (example data) | Act 2, optional |
| 9 | See where agents add the most value (example data) | Act 2, optional |
| 10 | How it works: Create, Push, Deploy, Measure | Act 2, then hand off to the terminal |
| **11** | **Live demo** (native slide, the `ast` commands) | **Act 3: leave the deck here** |
| 12 | Set a rule once. Every agent follows it. | Act 4 |
| 13 | Run inside your boundaries | Act 4 |
| 14 | You do not need a fleet of agents to get value | Act 4 |
| 15 | Donut chart (template placeholder) | Skip |
| 16 | Quadrant chart (template placeholder) | Skip |
| 17 | Poll (template placeholder) | Skip |
| 18 | Let's keep in touch (template placeholder: `name@email.com`) | Skip, or edit |
| **19** | **Take it further** (native slide, clickable links) | **Act 4: end here** |
| 20 | The only platform your company needs (astropods.com, docs, support) | Optional |
| 21 | Thank you | Optional |

**Before you present:** slides 15-18 are unedited template placeholders. Press past them, or replace them (swap the PNG in `presentation/assets/slides/` and its `<section>` in `index.html`). Slides 8 and 9 show example workspace data, so say so on stage. The "Meet the crew" slide from the template was removed.

---

## 2. Pre-requisites

| Requirement | How to get it |
|---|---|
| Astropods CLI (`ast`) | `curl -fsSL https://astropods.com/install \| sh` (macOS/Linux), `irm https://astropods.com/install.ps1 \| iex` (Windows). [Install guide](https://docs.astropods.com/install-cli). Verify with `ast --version`. |
| Docker, running | Needed by `ast project start`. Docker Desktop or equivalent. |
| Astropods account | `ast login` opens the browser for one-time device authorization. Needed for `--model gateway` and for deploying. |
| Slack workspace (optional) | Only for the `--adapter slack` deploy. See the [blog](https://blog.postman.com/build-ai-agents-with-astropods/) for the Slack app setup (Socket Mode, Event Subscriptions, `chat:write`, `app_mentions:read`). |
| `curl`, a browser | Install check and the deck. |

### Astropods-specific setup

- The deck is a local file and needs no network. Open `presentation/index.html` in a browser (or serve it: `cd presentation && python3 -m http.server 8000`) and press `F` for fullscreen.
- Open both Loom recordings in tabs (section 7).
- Optional: clone the demo repo, https://github.com/Postman-Devrel/hello-world-agents, to show finished agents.

---

## 3. Setup

### Quick start

```bash
# One time, before the day
ast login                       # browser opens, approve once
ast upgrade                     # optional: keep the CLI current
# ...and make sure Docker Desktop is running

# From the repo root
cd content/lightning-talks/astropods
./scripts/setup.sh --start      # scaffold the agent, start it, open the deck

# On stage (Act 3)
cd workspace/hello-teammate
ast project logs                # follow the running agent (started by --start)
# or, if you ran setup.sh without --start:
ast project start               # streams logs; Ctrl+C stops it

# Afterwards
cd ../..                        # back to the content folder
./scripts/teardown.sh
```

Optional check that this folder still matches the repo pattern, from the repo root:
`./scripts/validate-content.sh astropods`

### Setup script

```bash
./scripts/setup.sh              # scaffold the agent
./scripts/setup.sh --start      # ...and start it in the background
```

`setup.sh` will:

1. Check the deck exists and is well-formed.
2. Check `ast` is installed (and print the install command if not).
3. Check Docker is running.
4. Check you are logged in (`ast whoami`) — warns, does not fail.
5. Scaffold the demo agent with `ast project create hello-teammate --model gateway --yes` into `./workspace/` (gitignored). Override with `AGENT_NAME=` and `AGENT_MODEL=` (`gateway`, `anthropic`, or `openai`).
6. With `--start`, run `ast project start --background`.
7. Check the docs and blog are reachable, then open the deck.

### Authentication

- **Gateway (default):** `ast login` — browser opens, approve once. No model-provider key needed.
- **Bring your own key:** run setup with `AGENT_MODEL=anthropic`, then `ast project configure --var ANTHROPIC_API_KEY=sk-...` inside the project.

### Pre-flight checklist

- [ ] Terminal open in `workspace/hello-teammate`, font size bumped for the room
- [ ] Deck open in the browser and fullscreened (press `O` to confirm every slide image loaded)
- [ ] `ast whoami` shows you logged in
- [ ] Docker running
- [ ] No leftover agent from a previous run (`ast agent list`)
- [ ] Both Loom recordings open in tabs as the offline fallback

---

## 4. Talk track & click track

**Total time: ~10 min**

### Act 1: Hook (1–2 min)

#### Talk track

> "How many of you have built an agent that works great on your laptop? Now, how many of those are running somewhere your team can actually use them? That gap is the whole problem. A demo is not a teammate. A teammate is deployed, it's where your team already works, and you can see what it did."

#### Click track

**Show:** Deck, slide 1 (title). The deck title is *Where Agents become Teammates*; the opening slide reads "One platform to govern every agent."

**Do:** Advance through slides 2-5 (agenda, the problem, a flock of chaos, the path to AI-native).

---

### Act 2: The setup (1 min)

#### Talk track

> "Astropods is the platform that closes that gap. Four stages. A project — your code and one config file. A blueprint — a versioned snapshot of that project. An agent — a running instance of the blueprint. And observability on top. I'm going to take you through the first two live, and show you the last two."

#### Click track

**Show:** Deck, slides 6-7 (the platform, a governed agent), then slide 10 "How it works" (Create → Push → Deploy → Measure, which are Project → Blueprint → Agent → Insights). Slides 8-9 are optional.

**Do:** Point at each stage as you name it. Advance to slide 11 "Live demo" (it lists the commands you are about to run), then switch to the terminal.

---

### Act 3: The demo (5–6 min)

#### Talk track

> "One command creates the project. The gateway option means I don't need a model key. Then I log in, and I start it. Docker brings up everything the agent needs, and the logs stream right here."

> "Notice what's in the folder: starter code, `astropods.yml`, and an AGENTS.md and CLAUDE.md so a coding agent can pick up from here."

> "If I'm happy with it, validating, pushing, and deploying the blueprint is three more commands. Add `--adapter slack` and the same agent shows up in Slack."

#### Click track

**Show:** Terminal in `workspace/`.

**Do:** (If you ran setup without `--start`, create the agent live:)

```bash
ast project create hello-teammate --model gateway --yes
cd hello-teammate
ls                               # starter code, astropods.yml, AGENTS.md, CLAUDE.md
ast login                        # skip if `ast whoami` already shows you
ast project start
```

**Show (payoff):** The agent running locally — logs streaming, the agent answering. Then the same project's `astropods.yml` in an editor.

**Do (optional deploy, if time and network allow):**

```bash
ast spec validate
ast blueprint push hello-teammate
ast blueprint deploy hello-teammate
ast agent list
# ast blueprint deploy hello-teammate --adapter slack
```

**Show (payoff):** The deployed agent in `ast agent list`, or the blueprint page on the Astropods platform. If the network is bad, switch to the **Building & Deploying your first Agent** Loom recording instead.

---

### Act 4: The close (1 min)

#### Talk track

> "That's the path: create, run, push, deploy, and watch. Everything I showed — the deck, the repo, the step-by-step recordings, the blog, and the Agents in Action series — is linked from one page. Everything is on this last slide. Go build your first teammate."

#### Click track

**Show:** Back in the deck at slide 12, then 13 and 14 (policies, deployment boundaries, "one agent with the right governance"). Jump to slide 19 "Take it further" (press `O` and pick it; every link is clickable).

**Do:** Leave slide 19 up. End on the links, not the terminal. Slide 20 (contact) and 21 (thank you) are optional.

---

## 5. Tear down / reset

```bash
./scripts/teardown.sh
```

The script:

- Runs `ast project stop` for the demo agent
- Deletes `./workspace/` and the `.demo-state` file

**Manual steps** — it never touches the platform. If you deployed:

```bash
ast agent list
ast agent delete --name hello-teammate
ast blueprint archive hello-teammate
```

### Full reset between sessions

```bash
./scripts/teardown.sh
./scripts/setup.sh
```

---

## 6. Troubleshooting

| Issue | Fix |
|---|---|
| `ast: command not found` after install | Open a new terminal, or `export PATH="$HOME/.ast/bin:$PATH"` |
| `ast project start` fails immediately | Docker isn't running. Start Docker Desktop and retry. |
| Browser doesn't open on `ast login` | Run `ast login` again and copy the printed device URL into a browser by hand. |
| Gateway model calls fail | `ast whoami` — if logged out, `ast login`. Or switch: `ast project configure --var ANTHROPIC_API_KEY=sk-...` with a project created using `--model anthropic`. |
| Project directory already exists | `./scripts/teardown.sh && ./scripts/setup.sh`, or `ast project create hello-teammate --force`. |
| Port or container conflict from an earlier run | `ast project stop` in the project, then `ast project start`. |
| A slide shows blank in the deck | Check `presentation/assets/slides/` is next to `index.html` (open the file from the repo, not a copy). |
| Venue wifi is down | Play the Loom recordings (section 7) for Act 3. Acts 1, 2 and 4 are slides. |
| CLI is out of date | `ast upgrade` |

---

## 7. Additional resources

| Resource | Link |
|---|---|
| Slides — Astropods deck (HTML) | `presentation/index.html` |
| Content + Demo Guide (Confluence) | https://postmanlabs.atlassian.net/wiki/x/WIHX8QE |
| Demo repo — hello-world-agents | https://github.com/Postman-Devrel/hello-world-agents/tree/main |
| Video — Astro Platform Overview Demo | https://www.loom.com/share/c0576e89c40546c3add20d6a71cbdaee |
| Video — Building & Deploying your first Agent, step by step | https://www.loom.com/share/fd1c313dce2c4dbe817c311a10dac42c |
| Blog — Build, Deploy & Monitor AI Agents with Astropods | https://blog.postman.com/build-ai-agents-with-astropods/ |
| Video series — Agents in Action (YouTube playlist) | https://www.youtube.com/watch?v=B3CWQ2Ar8go&list=PLM-7VG-sgbtAVbHcnUNX-aZLN5nez-_4X |
| Astropods docs | https://docs.astropods.com/welcome |
| Quickstart — your first agent | https://docs.astropods.com/get-started |
| Install the CLI | https://docs.astropods.com/install-cli |
| Pre-built `hello-astro` agent | https://github.com/astropods/agents |
| Claude Code plugin (migrate an existing agent) | `/plugin marketplace add astropods/agents` then `/plugin install astropods@astroai` |
