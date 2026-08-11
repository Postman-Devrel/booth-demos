# Fern — Docs, SDKs, and a CLI for your API

> Booth demo — target length **10 minutes**. This README is the single source of truth.
> Read it top to bottom before your first attendee; everything you need to present the deck
> without improvising is here.

This is a **slide-forward** demo — a self-contained deck plus the talk track below. It's the
deck you give at a booth, a meetup, or the top of a customer call before you demo anything
hands-on. Several **optional** beats step off the deck into a live browser or terminal — each
one flagged inline in the talk track: the HTML-vs-markdown reveal (Act 3), a two-surface
**authoring deep-dive** on slide 6 (Fern Editor + a real repo edited by Claude Code), two
real Fern-generated SDKs (Act 4), and the live customers-page walk (Act 6). Every one is skippable — the
deck itself runs fully offline with no accounts or installs.

> **The deck is provided, not generated.** `presentation/index.html` is a pre-branded Fern
> deck used verbatim (**13 full-viewport slides**). It is a **vertical scroll deck** — you
> advance by **scrolling**, and press **`t`** to toggle light/dark. It does not use arrow-key
> or click slide navigation.

---

## 1. Product summary

**Product:** Fern

**Use case:** One API spec becomes a branded docs site, idiomatic SDKs in every language, and a CLI, all built for developers *and* agents.

**The story (the narrative arc):**

> APIs used to have one reader: a developer with your docs open in another tab. Now they have
> two — that developer, and the agent writing code beside them. Both fail on the same things:
> docs a machine can't parse, and SDKs that drift from the spec. Fern collapses the whole
> developer experience into one pipeline — you maintain a spec, and Fern generates the docs,
> the SDKs, and the CLI, and regenerates all of it on every change. Then you show the proof:
> Frame.io went from up to two weeks to under an hour to a first API call; Unleash's docs now
> answer nine in ten questions with no human; 8,000+ teams and a million SDK downloads a week
> run on exactly this. You close on buy-vs-build and enterprise migration.

**CTA:**
- See it live — <https://buildwithfern.com>
- Customer results — <https://buildwithfern.com/customers>
- Talk to the team — sales@buildwithfern.com

**Total time: ~12 minutes** for the deck (eight acts), or **~15** with the optional slide-6
authoring deep-dive. Acts 1–6 (the deck) are the core and stand alone; Acts 7–8 are the
close for a captive attendee. Several beats step off the deck and are all optional — drop any
of them if you're offline or short on time: the `.md` reveal (Act 3), two real SDK repos
(Act 4), the **live authoring deep-dive** (slide 6, needs `--authoring` + a Fern login), and
the customers-page walk (Act 6).

---

## 2. Pre-requisites

| Requirement | How to get it |
|---|---|
| A modern browser (Chrome, Safari, Firefox) | Pre-installed. The deck is a single HTML file. |
| The deck file | Ships with the demo at `presentation/index.html`. Nothing to download. |
| A booth monitor or laptop screen | Present in fullscreen; text is sized to read from ~6 feet. |
| Network *(optional)* | For the live web beats — the `.md` reveal (Act 3), the SDK repos (Act 4), the customers page (Act 6), and provisioning the authoring deep-dive. The deck itself runs fully offline. |
| **For the optional slide-6 authoring deep-dive only:** | |
| `git`, Node 18+, `npx`, and the Fern CLI | `npm i -g fern-api` (or `brew install fern-api/tap/fern`). `git`/`node`/`npx` are standard. |
| A Fern account + a project in the dashboard | Free at <https://buildwithfern.com>. Needed to log into the **Fern Editor** live — use your own project. |

---

## 3. Setup

```bash
cd demos/fern
./scripts/setup.sh
```

`setup.sh` will:

1. Confirm the deck exists at `presentation/index.html`.
2. Verify it is a complete, well-formed HTML file (guards against a truncated copy).
3. Confirm it is self-contained — no external assets, so it renders on dead wifi.
4. Open it in your default browser.

Then, before attendees arrive: **fullscreen the browser** (Cmd+Ctrl+F on macOS), **scroll to
the top**, and press **`t`** to set the theme to match the room.

### Optional: provision the slide-6 authoring deep-dive

```bash
./scripts/setup.sh --authoring
```

With `--authoring`, setup also (takes ~10s on good wifi, gitignored under `workspace/`):

1. Clones **fern-api/docs-starter** and **fern-api/sdk-starter** into `demos/fern/workspace/`.
2. Installs the official Fern agent skills (**fern-api/skills**, `npx skills add … --all`) into
   `workspace/docs-starter/.claude/skills/` — so Claude Code picks up the `fern-docs` skill there.
3. Runs `fern check` on the docs-starter so the live preview can't fail on stage.

Then, to rehearse Path B: `cd demos/fern/workspace/docs-starter && fern docs dev` (preview at
`localhost:3000`), and open `claude` in that folder.

### Authentication

The deck and the code path (Claude Code + starter repo) authenticate against nothing. The
**Fern Editor** in Path A needs you to be logged into **your own Fern project** in the
dashboard — that login is manual and cannot be scripted. Have the tab open before you start.

### Pre-demo checklist

- [ ] Deck open and in **fullscreen** on the booth monitor, scrolled to the top (slide 1)
- [ ] Theme (`t`) set to match booth lighting — dark for a dim hall, light for a bright one
- [ ] Browser zoom set so text is readable from 6 feet (`Cmd+=` / `Cmd+-`)
- [ ] Scrolling moves **one clean slide at a time** (test the trackpad/wheel)
- [ ] You know the **four proof stats** cold (Act 6): 99% · under an hour · 91.5% · 1M+/week
- [ ] For the Act 3 live reveal: a tab open to <https://elevenlabs.io/docs/api-reference/conversations/list>
      (and you know the `.md` trick + the numbers: **1.5 MB → 23 KB, ~60×**)
- [ ] For the Act 6 customers walk: a browser tab open to <https://buildwithfern.com/customers>
      and you can name one stat per value-add (SDKs: Auth0 7 langs / Docs: Deepgram 85% / Ask Fern: Solvimon 90%)

---

## 4. Talk track and click track

Eight acts, ~12 minutes (~15 with the optional slide-6 authoring deep-dive). Acts 1–7 map to
the deck's slides in order. Several optional beats step off the deck into a live browser or
terminal — the `.md` reveal (Act 3), the authoring deep-dive (slide 6), two real SDK repos
(Act 4), and the customers page (Act 6). Talk track is **verbatim** (blockquotes) — read it if
you need to. The click track is mostly **Do: scroll to the next slide** (plus `t` to toggle
theme), with every live beat called out explicitly.

The deck's 13 slides, in order: **(1)** title · **(2)** 8,000+ teams · **(3)** one source of
truth · **(4)** docs for developers + agents · **(5)** designed for the AI era · **(6)**
author in multiple ways · **(7)** SDKs by language experts · **(8)** just run `fern generate` ·
**(9)** a CLI for your API · **(10)** what teams ship · **(11)** enterprise-ready · **(12)**
migrate to the enterprise platform · **(13)** get in touch.

---

### Act 1: The two readers (45 sec) — slides 1–2

**Show:** slide 1 — "Upgrade your developer and agent experience."

> "APIs used to have one reader — a developer with your docs open in another tab. Now they
> have two: that developer, and the agent writing code right next to them. Fern is the
> developer experience layer built for both — docs, SDKs, and a CLI, from one spec."

**Do:** scroll to slide 2.

**Show (payoff):** "8,000+ teams build on Fern."

> "This isn't new or experimental. Eight thousand teams already build on Fern — from
> startups to public companies. Let me show you what they actually get."

---

### Act 2: One source of truth (1.5 min) — slide 3

**Do:** scroll to slide 3 — "Docs, SDKs, and CLI from one source of truth."

> "Here's the whole idea on one slide. You bring one spec — OpenAPI, GraphQL, AsyncAPI, or
> gRPC — and Fern produces three things from it: a documentation site, client libraries, and
> a command-line interface. One command, `fern generate`, and all three come out."

**Show (payoff):** point at the three outputs — Docs, SDKs, CLI.

> "The key word is *one*. There is a single source of truth. When your API changes, you change
> the spec, and every one of these regenerates together. Nothing is hand-maintained, so
> nothing can drift out of sync."

---

### Act 3: Docs for developers and agents (3 min) — slides 4–6

**Do:** scroll to slide 4 — "Documentation for developers and agents."

> "Start with the docs. Stunning by default, easy to update, designed to convert — and
> because your spec is the source of truth, a push regenerates the whole site. But look at the
> title: developers *and agents*. This is the part most docs tools miss."

**Do:** scroll to slide 5 — "Designed for the AI era."

> "Fern's docs are machine-readable by default — the same content served in a form an LLM can
> actually consume, and AI woven into how you write and maintain them. A human reads the
> page; an agent reads the markdown. Same source, both audiences. Let me show you exactly
> what I mean — on a real Fern site."

> This is a **live web** beat (needs network). If you're offline, skip it — the slide makes
> the point on its own, and you can say the two numbers from memory: **1.5 MB of HTML → 23 KB
> of markdown, about 60× smaller.**

**Show:** open a browser tab to a real Fern-powered docs page —
**<https://elevenlabs.io/docs/api-reference/conversations/list>**

> "This is ElevenLabs' API reference — built on Fern. This is the page a human sees:
> beautifully rendered, navigation, code samples, the works. It's also about a megabyte and a
> half of HTML — great for a person, far too heavy for an agent to read on every call."

**Do:** add **`.md`** to the end of the URL —
**<https://elevenlabs.io/docs/api-reference/conversations/list.md>**

**Show (payoff):** the exact same page returns as clean Markdown.

> "Same page. I just added dot-M-D to the URL. The agent gets the identical content as clean
> markdown — the endpoint, the parameters, the response schema — and nothing else. One and a
> half megabytes becomes twenty-three kilobytes. About sixty times smaller. Fern generates and
> serves both from your one spec — you don't do anything. A human reads the page; an agent
> reads the markdown."

**Do:** scroll to slide 6 — "Author in multiple ways."

> "And your team writes the way it already works — in Markdown, in a visual editor, in Git,
> whatever fits. The DX team and the docs team can live in the same repo without fighting
> over tooling."

---

#### Optional live deep-dive: two authoring surfaces, one repo (+3 min)

> **Optional and hands-on.** Run `./scripts/setup.sh --authoring` beforehand (clones Fern's
> docs-starter + sdk-starter and installs the official `fern-docs` agent skill into
> `workspace/docs-starter/`), and be **logged into your own Fern project** in the dashboard.
> Skip this entirely if you're offline or short on time — the slide makes the point alone.
> This is exactly how ElevenLabs runs it: **DX team in Git, support team in the Fern Editor,
> the same git-backed repo.** Show both doors.

**Path A — the Fern Editor, for someone who doesn't touch code.**

**Show:** your Fern project in the dashboard (<https://dashboard.buildwithfern.com>), and open
the **Fern Editor** on a page. *(Manual login — use your own project. Have this tab open before
you start.)*

> "This is the Fern Editor. A support engineer, a PM, a technical writer — someone who never
> opens a terminal — edits the docs visually, right here, and hits save. Under the hood that's
> a commit to the same repository the engineers use. No Git, no Markdown, no pull request."

**Path B — the repo and an agent, for the coder.**

**Show:** a terminal in `demos/fern/workspace/docs-starter` with the live preview already
running — `fern docs dev` at <http://localhost:3000> — beside a Claude Code session in the
same folder.

> "Same repo, different door. This is that project as actual files, and I've got Claude Code
> open in it. Fern ships an official agent skill — `fern-docs` — that's already installed here,
> so the agent knows how a Fern repo is laid out. I'll just describe the change."

**Do:** in Claude Code, type a plain-language edit, e.g.:

```
Update the welcome page: change the hero heading to "Build with the Plant Store API"
and add a short callout under it pointing developers to the Quickstart.
```

**Show (payoff):** the `fern docs dev` preview **hot-reloads** with the change.

> "Because the skill knows Fern's structure, it edited the right file the right way — and the
> live preview already updated. So that's the whole slide, made real: your API team in Git,
> your docs team in the Editor, and now an agent — all authoring the *same* source of truth."

> **Fast version (30 sec):** if you're tight on time, just show Path A — open the Fern Editor,
> make one visual edit, hit save. That alone lands "author in multiple ways."

---

### Act 4: SDKs designed by language experts (2 min) — slides 7–8

**Do:** scroll to slide 7 — "SDKs designed by language experts."

> "Now the SDKs — this is where teams feel it most. One spec, every language. And these
> aren't thin HTTP wrappers. Every generator carries the same ergonomics: a real type system,
> proper networking, reliability with retries and pagination, and auth handled for you. A
> developer — or an agent — gets the same experience whether they're in Python or Go."

**Show (payoff):** the Merge testimonial on this slide.

> "Gil Feig, the CTO of Merge, put it best: adding a feature used to mean implementing it
> seven times, once per language. Now they change the spec once and it ships in every SDK."

**Show (payoff — real SDKs, live):** *optional, needs network.* Open two production SDKs in
the browser — same generator, two companies, two languages:

- **<https://github.com/merge-api/merge-python-client>** — Merge's Python SDK
- **<https://github.com/square/square-nodejs-sdk>** — Square's TypeScript SDK

> "And I don't want this to be abstract, so — these are real. This is Merge's Python SDK, and
> this is Square's TypeScript SDK. Two different companies, two different languages."

**Do:** point at the green **🌿 Built with Fern** badge at the top of each README.

> "Same badge on both — 🌿 built with Fern. These aren't Fern's libraries; they're Square's and
> Merge's own production SDKs, the ones their customers `pip install` and `npm install` today —
> Square's is on npm at version forty-five, a hundred-plus stars. Both generated from a spec,
> not hand-written. The READMEs even say it: 'this library is generated programmatically.' One
> generator, and every one of these companies ships language-native code they never maintain by
> hand."

**Do:** scroll to slide 8 — "Just run `fern generate`."

> "And publishing is one command. `fern generate` builds and publishes the client libraries —
> tested by default — so your engineers focus on the API, not on maintaining seven client
> libraries by hand."

---

### Act 5: A CLI for your API (1 min) — slide 9

**Do:** scroll to slide 9 — "A CLI for your API."

> "The newest output, and the one people don't expect: a command-line interface. Fern
> generates a branded, idiomatic CLI from the same OpenAPI spec — every endpoint becomes a
> command. Built for agents and developers alike, because increasingly the thing driving your
> API from a terminal is an agent."

---

### Act 6: What teams ship — the proof, live (3 min) — slide 10

> "So does it actually pay off? This is the slide to slow down on."

**Do:** scroll to slide 10 — "What teams ship after moving to Fern."

**Show (payoff):** walk the three headline proof points.

> "Frame.io moved off Adobe's internal dev docs. Time to a first successful API call went from
> **one to fourteen days** down to **under an hour** — a ninety-nine percent reduction. That
> is the single most expensive number in developer experience, and they cut it to nothing."

> "Unleash left Docusaurus and Kapa. Their docs assistant, Ask Fern, now resolves **ninety-one
> and a half percent** of questions without a human — fifteen hundred support hours saved a
> year."

> "And at the top end: **a million-plus SDK downloads every week**, **one-and-a-half million**
> docs users a month, **seven thousand engineering hours** saved per year. This is
> production, at scale, today."

**Show (live customers page):** *optional, needs network — if offline, slide 10 alone carries
this.* Open a browser tab to **<https://buildwithfern.com/customers>**.

> "And these aren't three cherry-picked logos. Here's the receipts page — every logo on it
> runs on Fern in production, organized by the three things one spec gives you: SDKs, docs,
> and Ask Fern."

**Do:** scroll into the **SDKs** section — the roster of logos.

> "Start with SDKs. Look at this roster — Square, Auth0, ElevenLabs, Cohere, Webflow,
> LaunchDarkly, Merge, AssemblyAI, Pinecone. Auth0 generates **seven SDK languages from a
> single spec** and saves **seven thousand engineering hours a year** doing it. Cohere went
> from **one SDK to four**. Nobody on this page hand-writes client libraries anymore."

**Do:** click a language badge on one of them — e.g. Square's **TypeScript** badge → it opens
**<https://github.com/square/square-nodejs-sdk>**.

**Show (payoff — ties back to Act 4):** the real SDK repo on GitHub.

> "And these logos aren't just marketing — click the language badge and it drops you straight
> onto the actual SDK on GitHub. There's Square's TypeScript client — the one we looked at
> earlier — generated by Fern, badged, shipping on npm. Every logo on that page ships SDKs
> exactly like it."

**Do:** scroll on to the **Docs** and **Ask Fern** sections.

> "Same story for docs — Deepgram cut PR turnaround **eighty-five percent** and got **five
> times more contributors**. And Ask Fern, the agent layer, is the number that stops people:
> at Solvimon, **ninety percent of their docs traffic is now agents**, not humans. Ninety
> percent. Your biggest documentation audience may already be machines."

---

### Act 7: Enterprise-ready and migration (1 min) — slides 11–12

**Do:** scroll to slide 11 — "Enterprise-ready by default."

> "And it's enterprise-ready by default — SAML or OIDC, role-based access so customers see
> only what's relevant to them, the whole security story built in, not bolted on."

**Do:** scroll to slide 12 — "Migrate to the enterprise platform."

**Show (payoff):** the three migration cards on this slide — real names, grouped by what each
team left behind.

> "And look who's on here — grouped by what they migrated *off* of. **From ReadMe: Webflow** —
> they now run their docs *and* their SDKs with no dedicated engineering headcount. **From an
> internal homegrown system: NVIDIA** — they pulled dozens of separate GitHub repos into one
> docs site. **From Mintlify: ElevenLabs** — shipping first-class WebSocket SDKs right
> alongside REST, from one spec. And the 'also migrated' row underneath — **Deepgram, Deel,
> Merge, Square, Payabli, ShipBob.** Every kind of stack, and Fern's team does the heavy
> lifting on the migration, so you ship faster than you did before."

---

### Act 8: The close (45 sec) — slide 13

**Do:** scroll to the deck's final slide 13 — "Get in touch" — or leave the customers page up.

> "One sentence to take away: you maintain the spec, and Fern ships the entire developer
> experience — docs, SDKs, and a CLI, for developers and agents, regenerated on every change.
> That's buildwithfern.com, the receipts are on the customers page, and if you want to talk it
> through, it's sales at buildwithfern dot com — or just grab me right here."

---

## 5. Tear down / reset

```bash
./scripts/teardown.sh
```

The deck itself creates no files, no keys, and no cloud state. The optional slide-6 authoring
deep-dive *does* leave state, and `teardown.sh` cleans all of it:

| Left behind by the deep-dive | What teardown does |
|---|---|
| A running `fern docs dev` preview | **Stops the process** (no need to remember Ctrl-C) |
| Live edits Claude Code made to the docs-starter | **Resets** them (`git checkout` + cleans new pages under `fern/`) |
| Any edits to the sdk-starter | Reset the same way |
| Preview build caches (`.fern`, `.preview`) | Removed so the next run rebuilds clean |
| Cloned starter repos + installed `fern-docs` skill | **Kept** by default — re-cloning at a booth is slow |
| A Fern Editor (Path A) edit in your cloud project | **Manual** — teardown reminds you; a login can't be scripted |

**Between attendees:** `./scripts/teardown.sh`, then scroll the deck back to slide 1. The only
manual step is undoing any Fern Editor edit in your own project.

**Full reset between demo days:** `./scripts/teardown.sh --purge` also deletes `workspace/`
entirely; re-provision with `./scripts/setup.sh --authoring`.

If you only ran the deck (no `--authoring`), teardown is a no-op beyond confirming the deck is
intact — there is genuinely nothing else to clean up.

---

## 6. Troubleshooting

| Issue | Fix |
|---|---|
| Arrow keys / spacebar don't change slides | This is a **scroll deck** — use the trackpad or mouse wheel to move between slides. Only `t` (theme) is a key binding. |
| Scrolling jumps two slides at once | Momentum scrolling on a trackpad. Scroll in smaller flicks, or use `Page Down` / arrow-down for one step. |
| Text too small / too large from the floor | `Cmd+=` / `Cmd+-` to zoom the browser. |
| Theme is hard to read in the hall lighting | Press `t` to toggle light/dark — dark for a dim hall, light for a bright booth. |
| Slide art or fonts look wrong | Hard-refresh (`Cmd+Shift+R`). The deck is self-contained, so this is almost always a stale browser cache. |
| Deck won't open from `setup.sh` | Open `presentation/index.html` directly in a browser. If it's missing, restore it from git. |
| Presenting on a shared/roaming laptop | The deck needs no network and no install — copy the single `index.html` and open it anywhere. |
| Act 3 `.md` reveal won't load (no wifi) | Skip it — slide 5 makes the point on its own. Say the numbers from memory: 1.5 MB HTML → 23 KB markdown, ~60× smaller. |
| The `.md` page looks like raw text, not rendered | That's correct and it's the point — it's Markdown for a machine, not a styled page for a human. Say so out loud. |
| Act 6 customers page won't load (no wifi) | Skip it — the deck's slide 10 already carries the headline proof. The three value-add stats are in this README if you want to say them from memory. |
| Customers page layout changed | It's a live page and Fern updates it. The value-adds (SDKs / Docs / Ask Fern) are stable; if a specific stat has moved, fall back to the deck's slide 10 numbers. |
| Slide-6 deep-dive: `setup.sh --authoring` fails | It needs `git`, Node 18+, `npx`, `fern`, and network. Provision it the night before, not at the booth. |
| `fern docs dev` says port 3000 in use | Another preview is running. Kill it, or run `fern docs dev --port 3001` and open that. |
| Claude Code doesn't seem to use the `fern-docs` skill | Confirm you're in `workspace/docs-starter` (the skill installs there, not repo-wide). Re-run `./scripts/setup.sh --authoring` to reinstall. |
| Can't log into the Fern Editor | The Editor needs *your* Fern account/project — it can't be scripted. If login is flaky, fall back to Path B (the repo + Claude Code) alone, which needs no login. |
| Live edit left the docs-starter messy | `./scripts/teardown.sh` resets it (`git checkout`). `--purge` re-clones from scratch. |

---

## 7. Additional resources

| Resource | Link |
|---|---|
| Fern | <https://buildwithfern.com> |
| Customer results & case studies (Act 6) | <https://buildwithfern.com/customers> |
| Talk to the team | sales@buildwithfern.com |
| A real Fern docs portal in production | <https://elevenlabs.io/docs> |
| Merge's Python SDK (Act 4, Fern-generated) | <https://github.com/merge-api/merge-python-client> |
| Square's TypeScript SDK (Act 4, Fern-generated) | <https://github.com/square/square-nodejs-sdk> |
| The Act 3 live page (HTML) | <https://elevenlabs.io/docs/api-reference/conversations/list> |
| The same page as Markdown (`.md`) | <https://elevenlabs.io/docs/api-reference/conversations/list.md> |
| Fern docs starter (slide-6 Path B) | <https://github.com/fern-api/docs-starter> |
| Fern SDK starter | <https://github.com/fern-api/sdk-starter> |
| Fern agent skills (`fern-docs`) | <https://github.com/fern-api/skills> |
| Fern dashboard (Fern Editor, Path A) | <https://dashboard.buildwithfern.com> |
| Companion interactive demo (grade any docs site live) | `../agent-ready-docs` |
| Companion slide demo (product-agnostic overview) | `../fern-overview` |
