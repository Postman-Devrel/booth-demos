# Make MCPs Your Documentation Best Friend — Live Build

> [Lightning talk](../../../templates/formats/lightning-talk.md) — target length **10 minutes**,
> no Q&A inside the slot. Booth demo or meetup opener. This README is the single source of
> truth. Read it top to bottom before you present; everything you need is here.

This is the **tools-in-action** cut of [the 25-minute short talk](../../short-talks/mcp-docs-best-friend/).
Same thesis, opposite ratio. The short talk *walks* a pipeline that was already published and
spends its time on the argument. This one *builds* the pipeline from nothing and spends its
time on the terminal.

Three slides set up the problem in ninety seconds. Then: a folder holding one OpenAPI file, and
three steps — `fern init`, two small YAML files, `fern generate --docs`. Out comes a published
docs site, per-page Markdown, an `llms.txt` index, and an MCP server. You connect that MCP
server to a local Claude Code session and ask it one question.

No GitHub, no repository, no CI. Fern needs none of it to publish, so the demo does not carry
it — one fewer account to be logged into and one fewer thing to fail on stage.

The payoff question is chosen so it cannot be guessed: **"I want to change only the `reason`
field on an appointment — does that affect the slot?"** The answer is a real footgun in this
API: a plain `PATCH` emits `appointment.cancelled`, and `appointment-slots-service` reopens the
slot even though the appointment is still active. That warning is in `appointments.openapi.yaml`
on disk. You show it in Act 2. Eight minutes later the MCP server hands it back to you, cited.
Nothing in between copied it by hand — that round trip *is* the demo.

---

## 1. Product summary

**Product:** Fern — one OpenAPI spec becomes the human docs site, per-page Markdown, an
`llms.txt` index, and an MCP server, all generated together by one command.

**Use case:** Prove at a booth, from zero, that the agent-facing docs surface is something you
*generate* in ten minutes rather than something you hand-write and maintain in four places.

**The story (the narrative arc):**

> Your documentation used to have one reader: a developer with your docs in another tab. Now it
> has two, and the second one has to discover, authenticate, parse, and recover from errors on
> its own. Serving it means three more artifacts — an index, clean Markdown, a queryable
> server — and nobody has time to write those by hand, let alone keep them true. So don't.
> Here is one OpenAPI file in an otherwise empty folder. Three steps later there is a published
> site and all three agent-facing surfaces. Then I connect that MCP server to an agent and ask
> it something no model can guess — and the answer comes back out of the same sentence I showed
> you in the spec, with a link to prove it.

**One payoff:** the cited MCP answer. Everything else is scaffolding for that moment.

**CTA:**
- Fern — <https://buildwithfern.com>
- Do it to your own spec — `npm i -g fern-api && fern login && fern init --openapi ./your-spec.yaml`
- Postman Discord — <https://discord.gg/postman>
- The 25-minute version — [`../../short-talks/mcp-docs-best-friend`](../../short-talks/mcp-docs-best-friend/)

**Total time: ~10 minutes.** Act 1 hook (1.5 min), Act 2 setup (1.5 min), Act 3 demo (6 min),
Act 4 close (1 min).

---

## 2. Pre-requisites

| Requirement | How to get it |
|---|---|
| **Node.js 18+ and npm** | The Fern CLI runs on it. |
| **Fern CLI** | `npm install -g fern-api`. Verify with `fern --version`. |
| **A Fern account, logged in** | `fern login` → **Continue with Postman**. Do this *before* the booth — an unauthenticated `fern generate` opens a browser mid-demo. `setup.sh` fails if `~/.fern/token` is missing. |
| **Claude Code CLI** | Act 3e. `claude --version` should work. |
| **A terminal with a large font** | The demo *is* the terminal. Bump to ~18pt. |
| **Network** | Required for Acts 3c–3e. Acts 1–2 and 3a–3b work offline. |
| **A rehearsal run, same day** | Not optional. See [the two things that break Act 3e](#the-two-things-that-break-act-3e) below. |
| **No GitHub, no `git`** | Deliberate. `fern init`, `fern check` and `fern generate --docs` need no repository — `setup.sh` proves this on every run by doing the scaffold in a folder that is not one. |

### Configuration

| Variable | Default | What it is |
|---|---|---|
| `FERN_ORG` | `postman-devrel` | The **organization** — the DevRel team's shared Fern tenant. Goes in `fern.config.json`. Permanent. You do not invent it and you do not delete it. |
| `FERN_HANDLE` | `booth-demo` | The **subdomain** — `<handle>.docs.buildwithfern.com`, the site this demo publishes *inside* that org. Goes in `docs.yml`. Globally unique across all Fern customers. |
| `WORKDIR` | `/tmp/appointments-docs` | Where Acts 3a–3c run. Holds the spec, then the `fern/` project. |
| `AGENTDIR` | `/tmp/appointments-agent` | Where Act 3e runs. **Must be empty** — it is what stops the agent reading the spec instead of calling the MCP server. |

> ### The organization is not the subdomain
>
> This is the one thing to internalise, because getting it wrong cost a demo already.
>
> The **organization** is the account-level tenant you belong to. One organization publishes
> many sites. `postman-devrel` already publishes `myhealthcare.docs.buildwithfern.com` — the
> names do not match, and they were never meant to.
>
> Passing a name you made up to `fern init --organization` **does not fail**. Fern
> provisions that organization for you on the first publish. So the mistake is invisible
> until someone tries to tidy up.
>
> **Never delete a Fern organization.** Deleting one leaves your account belonging to none,
> and every subsequent publish dies with a 500 `Failed to resolve organization` that gives
> you no hint where to look. There is nothing up there to reset — the org is permanent, the
> demo site lives inside it, and **republishing over the same subdomain is the reset.**
>
> `setup.sh` now verifies the organization resolves before you walk on.

> ### `myhealthcare` is production. Do not publish to it.
>
> `myhealthcare.docs.buildwithfern.com` is the **real MyHealthcare documentation** — a live,
> three-service site that the short talk presents and that other content links to. It happens
> to live in the same organization as this demo, which is exactly what makes it easy to
> clobber: `fern generate --docs` publishes wherever `docs.yml` points, with no confirmation
> beyond a generic production warning.
>
> Publishing this one-service demo to that subdomain would **replace the real documentation
> with nine appointment endpoints.** `setup.sh` hard-fails if `FERN_HANDLE=myhealthcare`, but
> the check only covers that exact string — read your `docs.yml` before every `fern generate`.
>
> The demo site is `booth-demo`, a throwaway name inside the same org. Publish there as often
> as you like.
>
> The one place this README does point at `myhealthcare` is the Act 3e fallback, and that use
> is **strictly read-only**: `claude mcp add` against its MCP server, plus `curl` on its
> `llms.txt`. Neither writes anything. Never point `docs.yml` at it.

---

## 3. Setup

```bash
cd content/lightning-talks/mcp-docs-live-build
./scripts/setup.sh
```

`setup.sh` builds none of the demo — that is the point. It guarantees the starting
conditions and then gets out of the way:

1. Checks `node`, `npm`, `fern`, `claude`, that the Fern CLI is **logged in**, and that
   `$FERN_ORG` **actually resolves for your account** — the check that turns a mid-demo 500
   into a line of setup output.
2. Asserts the payoff warning is still in `openapi/appointments.openapi.yaml`. If someone ever
   tidies that description away, the demo still runs and quietly stops proving anything — and
   the Act 2 `grep` prints nothing.
3. Creates `$WORKDIR` containing **exactly one file**, `appointments.yaml`. No `fern/`, no
   `.git`, nothing else, so "empty folder, one file" is literally true.
4. Creates `$AGENTDIR` and asserts it is **empty**. Act 3e runs there, so the agent has no
   local spec to read and the MCP server is the only possible source of the answer.
5. Runs the whole Act 3a–3b sequence as a **preflight** in a throwaway folder — `fern init`,
   the `generators.yml` trim, `fern check` — and fails loudly if it no longer passes. That
   throwaway folder is not a git repo, which is the standing proof that this demo needs none.
6. Prints **WARM** or **COLD** for your docs subdomain. Read this line. It is the only part of
   the output that changes what you do.
7. Opens **the deck, and nothing else.** The docs site does not exist until Act 3c publishes
   it, and buildwithfern.com is a slide rather than a demo surface — extra tabs are how you
   lose the one you need.
8. Prints every command and the payoff prompt, paste-ready, act by act. You should not need
   this README on stage.

`SKIP_OPEN=1 ./scripts/setup.sh` runs the checks without opening anything.

### The two things that break Act 3e

Both were hit on the first live run, 2026-09-07. They are independent and each needs its own
fix.

#### 1. The search index takes minutes to build after a first publish

Not seconds. Measured: `searchDocs` was still unavailable the moment `fern generate --docs`
finished, and answering normally about **five minutes** later (in 13 s). A ten-minute demo
does not have five minutes of slack, so the site has to already exist before you present.

#### 2. The agent will read the spec off your disk instead of calling the MCP server

This is the nastier one, because it *looks like success*. Run `claude` in `$WORKDIR` — the
folder holding `appointments.yaml` — ask the payoff question, and when the MCP server is slow
you get:

> *"The docs site isn't indexed yet, but the local OpenAPI spec has the answer. Let me read
> the relevant sections."*

It then gives the **correct answer from the wrong source**. Nothing about the pipeline was
demonstrated: the fact never travelled spec → site → MCP, the agent just opened the file
sitting next to it.

**The fix is an empty folder.** Act 3e runs in `$AGENTDIR` (`/tmp/appointments-agent`), which
`setup.sh` creates and asserts is empty. With nothing to read, a slow index makes the agent
wait, retry, or say it cannot answer — all honest, all recoverable in front of a booth. Keep
both fixes: the empty folder removes the escape hatch, the warm index removes the reason to
look for one.

The fix is a rehearsal run, and it takes five minutes:

```bash
./scripts/setup.sh     # says COLD
# ... run the whole demo once, alone ...
./scripts/teardown.sh
./scripts/setup.sh     # must now say WARM
```

Teardown deliberately **does not unpublish the site**. On stage, `fern generate --docs`
republishes over a subdomain that already has an index — the audience sees a genuine publish,
and `searchDocs` comes back in **5–6 seconds** (measured on the published booth site,
2026-09-07; budget 15 to be safe). Every command you run is real; only the index is
pre-warmed, and Act 3c says "republish" if anyone asks.

### Verified stage numbers

Measured **2026-09-08** against the live `booth-demo` site, end to end through a real Claude
Code session in the empty `$AGENTDIR` — not predicted. Quote them; do not round them up.

| Claim | Measured |
|---|---|
| The payoff page as HTML | 795,181 bytes (~777 KB) |
| The same page as Markdown (`.md`) | 9,165 bytes (~9 KB) — **~87× smaller** |
| The ⚠️ warning in that Markdown | Line 19, verbatim from the spec |
| `llms.txt` | 11 entries — 9 endpoint pages plus the OpenAPI JSON/YAML links |
| Warm `searchDocs` call, on its own | 5–15 s |
| **Act 3e end to end**, prompt to finished answer | **33 s** — plan narration for it |
| Index build after a *first* publish | Unavailable immediately; answering ~5 min later |
| The payoff answer | Names `PATCH /api/appointments/{record_id}` and the shallow merge, states the slot is reopened, cites `.../api-reference/appointments/update` |

Two behaviours worth knowing because they are not in the numbers:

- **The first `searchDocs` call needs your approval.** Claude Code prompts for
  `mcp__<whatever-you-named-it>__searchDocs`. Approve it live rather than pre-allowlisting — the
  prompt is visible evidence that a tool call is leaving the machine.
- **In an empty folder, a blocked or cold tool makes the agent refuse rather than guess.**
  Tested with the tool denied: *"Since you scoped me to only that server, I have no other
  source to answer from, and I won't guess at the endpoint or its slot behavior."* That is
  the honest failure, and it is only available because `$AGENTDIR` is empty.

---

## 4. Talk track and click track

Four acts, ~10 minutes. Deck slides in order: **(1)** title · **(2)** two readers ·
**(3)** the agent-facing surface · **(4)** one spec to rule them all · **(5)** LIVE ·
**(6)** CTA.

Talk track is **verbatim** (blockquotes) — read it if you need to.

Booth reality: people arrive mid-run. Act 3 is written so each sub-beat re-states what is
happening, and Act 1 is short enough to simply repeat for a new group.

---

### Act 1: The hook (1.5 min) — slides 1–3

**Show:** slide 1.

> "Ten minutes, one file, three commands. At the end of it an AI agent is going to answer a
> question about this API that it has no way of knowing — and show me where it read it."

**Do:** advance to slide 2 — BEFORE / NOW.

> "Here is why that matters. Your documentation used to have exactly one reader: a human,
> skimming headings, hunting for the one paragraph they needed. Every docs tool we have was
> built for that reader."

**Show (payoff):** point at the NOW column.

> "Now there are two. A human still skims. But an agent has to do four things on its own —
> discover what exists, authenticate, parse the response, and recover when a call fails.
> Nobody is there to squint at the page for it. And the thing I want you to take home is that
> your portal is not badly built. It is *correctly* built, for the reader who existed when it
> was built. Dual readership is a new requirement, not a bug someone introduced."

**Do:** advance to slide 3 — the agent-facing surface.

> "So what do you owe that second reader? Three things. An `llms.txt` — a plain-text index at
> the root of your site, so the agent knows what exists instead of guessing URLs. Per-page
> Markdown — the same content with the navigation and the JavaScript chrome stripped out, so
> it is cheap to parse. And an MCP server — a tool the agent *calls*, instead of scraping and
> re-parsing your pages itself."

**Show (payoff):** the takeaway line.

> "Three more artifacts. Nobody in this room has time to write those by hand, and nobody has
> time to keep four things true at once. So we are not going to."

---

### Act 2: What we start with (1.5 min) — slide 4, then the terminal

**Do:** advance to slide 4 — one spec to rule them all.

> "One spec, four outputs, built together. Not copied — built. That's the claim, and claims
> are boring, so let's just do it."

**Do:** switch to the terminal. Large font.

```bash
ls
```

**Show (payoff):** one file — `appointments.yaml`.

> "This is everything I have. One OpenAPI file describing our appointments service — ten
> endpoints. No docs folder, no site, no config, no MCP server, not even a git repo. That's
> the starting position."

**Do:** show the warning in the spec. This is the plant for the payoff — do not skip it.

```bash
grep -n -A4 'a plain update emits' appointments.yaml
```

**Show (payoff):** the ⚠️ block: a plain update emits `appointment.cancelled`, so
`appointment-slots-service` reopens the slot.

> "One thing in this file to remember. Somebody wired the generic 'record updated' event to
> the topic named `appointment.cancelled`. So a plain `PATCH` — changing a text field —
> publishes 'cancelled', and downstream, the slots service gives the slot away. The
> appointment is still active. That is genuine, it is written down right here, and it is the
> kind of thing no model can guess. Remember it — we're going to ask an agent about it in
> seven minutes."

**Do:** advance to slide 5 — LIVE. Leave it up as your backdrop between windows.

---

### Act 3: Build it (6 min) — slide 5

> "Everything from here is live. Three steps."

#### 3a — Scaffold (1 min)

```bash
fern init --openapi ./appointments.yaml --organization postman-devrel
ls fern
cat fern/generators.yml
```

**Show (payoff):** two files — `fern.config.json` and `generators.yml`. No `apis/` folder. And
in `generators.yml`, `- openapi: ../appointments.yaml`.

> "Step one. Fern scaffolded two files. And look at the important line: it points back at
> `../appointments.yaml` — one level up, where I left it. It *references* my spec where it
> lives; it did not copy it into a folder. That's the property the whole thing rests on. There
> is one spec, and editing it is how everything downstream changes."

**Do:** point at the `groups:` block below it — the TypeScript SDK generator `fern init` also
scaffolded.

> "It also wired up an SDK generator, because the same spec generates SDKs too. That's a
> different demo — I'm dropping it in a second so we stay on docs."

> **Do NOT run `fern check` here.** `fern init` scaffolds a TypeScript SDK generator, and the
> SDK validator throws five errors on this spec's request examples: the schemas are open
> (`additionalProperties`, because the service stores a free-form JSONB `data` document), so
> the example keys are not declared members. Docs do not care. `fern check` does. Act 3b
> removes that generator and *then* checks green — check here and you show the room red text
> for no reason. `setup.sh` runs this whole sequence as a preflight, so you will know before
> you walk on if it ever changes.

#### 3b — Two small YAML files (1 min)

**Do:** paste the whole block from the `setup.sh` output — one paste, two files.

```bash
cat > fern/generators.yml <<'YAML'
api:
  specs:
    - openapi: ../appointments.yaml
YAML

cat > fern/docs.yml <<'YAML'
instances:
  - url: booth-demo.docs.buildwithfern.com
title: Appointments Service | Documentation
navigation:
  - api: API Reference
YAML

fern check
```

**Show (payoff):** `All checks passed` — or `Found 0 errors and N warnings`, which is also a
pass. Zero *errors* is the bar; warnings are Fern being chatty.

> "Step two, and it's not really a command — it's two small YAML files. The first one is
> `generators.yml` trimmed down to just 'here is my spec', because we're only doing docs
> today. The second is the docs config: a subdomain, a title, and one navigation entry.
> `- api: API Reference` with nothing after it, because this project has one API and Fern
> resolves it from the file above. Five lines. That is the entire definition of a
> documentation site."

> **Trap, if someone asks:** adding `api-name:` here is the single most common failure. It
> belongs to multi-API projects, where it names a folder under `fern/apis/`. In a single-API
> project it makes the publish fail looking for a folder that never existed.

#### 3c — Publish (1 min 15)

```bash
fern generate --docs
```

Answer **Yes** to the production warning.

> "Step three. This is building the site, the Markdown for every page, the `llms.txt` index,
> and an MCP server — one pass, one command, no extra configuration and no second repo."

**While it runs** — you have about a minute, so use it:

> "Worth saying what is *not* happening here. I am not writing documentation. I am not
> maintaining an index. I am not implementing a server. Those four outputs are all downstream
> of the one file you saw, which means the interesting question stops being 'are the docs up
> to date' and becomes 'is the spec right' — and that's a question your team can actually
> answer."

> "And there's no magic in the folder either. It's three small text files next to a spec. Commit
> them, run this same command from a GitHub Action, and a push to your spec republishes your
> docs. I'm not doing that here because it isn't the interesting part — the interesting part is
> what just came out."

**Show (payoff):** `Published docs to https://booth-demo.docs.buildwithfern.com`.

> *(If you did a rehearsal run and someone noticed the subdomain already existed:)* "Yes —
> this republishes over the site I built this morning. Same command, and it's the same
> command CI would run."

#### 3d — The four outputs (1 min 30)

**Do:** open the printed URL. Browse it like a human for fifteen seconds, then go to
**API Reference → Appointments → Update an appointment**.

> "**Output one: the human site.** Deliberately unremarkable — it's a docs site, it's nice,
> you can read it. Nothing was taken away from the reader we already had. That's the bar,
> and it's met."

**Do:** add **`.md`** to the current URL and hit enter.

**Show (payoff):** the same page as clean Markdown — and the ⚠️ block from Act 2 is right
there in plain text.

> "**Output two: Markdown.** Append dot-M-D to any URL on this site. Same page, no chrome.
> The HTML version of this page is seven hundred and eighty kilobytes. This is nine. Nearly
> ninety times smaller — and look: my warning survived. Same sentence I showed you in the
> spec, different surface, zero copies."

**Do:** open `/llms.txt`.

**Show (payoff):** the *Instructions for AI Agents* header, then every page and endpoint
listed with a description and a `.md` link.

> "**Output three: `llms.txt`.** Every page, named, described, linked, in a few kilobytes. The
> agent reads the index instead of guessing URLs — same as you would. And read the top of the
> file: it *tells* the agent about the dot-M-D trick, and it gives it the MCP server URL. The
> docs document how to read the docs."

**Do:** select the `_mcp/server` URL on that line.

> "**Output four**, and the one this talk is named after: an MCP server. Same build, same
> command, no extra repo. Let's plug it in."

#### 3e — Connect it to an agent and ask (2 min 15)

**Change folders first.** This is not housekeeping — see
[the two things that break Act 3e](#the-two-things-that-break-act-3e). If the agent can see
`appointments.yaml`, it reads `appointments.yaml`.

```bash
cd /tmp/appointments-agent
ls -la
```

**Show (payoff):** the folder is empty.

> "New folder, and it's empty — no spec, no SDK, nothing installed. This is the position
> anyone integrating your API is in on day one. Whatever this agent tells me next, it can only
> have got from your published docs."

```bash
claude mcp add --transport http appointments-docs https://booth-demo.docs.buildwithfern.com/_mcp/server
claude
```

then, in the session:

```
/mcp
```

**Show (payoff):** one server **connected**, one tool: `searchDocs`. The name is whatever you
passed — nothing downstream cares.

> "One command, no SDK, no API key, no scraping. The docs are now something this agent can
> *ask*."

**The prompt.** Paste verbatim:

```
Using the connected docs MCP server — the only MCP server in this folder —
and nothing else: I want to change only the `reason` field on an existing
appointment. Which endpoint do I call, and does that have any side effect
on the appointment's slot? Cite the page you got it from.
```

> **The prompt names no server on purpose.** This one server ends up registered under at
> least three different names depending on which command you used:
>
> | Name | Where it comes from |
> |---|---|
> | `appointments-docs` | the command in this README and in `setup.sh` |
> | `booth-demo-docs-buildwithfern-com` | the snippet in the docs site's own UI |
> | `fern_mcp_booth-demo-docs-buildwithfern-com` | the `usage.claudeCode` field of `/_mcp/server` |
>
> Name it in the prompt and you get the agent opening with *"no server named
> appointments-docs is connected"* — which is what happened on 2026-09-08. Whichever name
> you register, this prompt works. Pick the site's snippet if you like: *"the docs even tell
> me the command"* is a fair beat.

**Claude Code will ask permission** to run `mcp__<server>__searchDocs` the first time.
Approve it. Do not pre-allowlist it — the prompt is worth having on screen:

> "It's asking me before it calls the tool. That's the protocol working: this is a tool call
> going out to my docs site, not the model rummaging in its memory."

**This takes about thirty seconds**, not the ~13 s of the search itself — the model reads the
results and writes the answer too. Measured end to end on 2026-09-07: **33 s**. That is a long
silence at a booth, so have something to say. Narrate while it runs:

> "While that goes: notice what it does *not* have. No SDK, no API key, no copy of the spec —
> this folder is empty. It has one tool and a URL."

**Show (payoff):** one or two `searchDocs` calls. It names `PATCH /api/appointments/{record_id}`,
notes the shallow merge, then warns that the update publishes `appointment.cancelled` so
`appointment-slots-service` reopens the slot while the appointment is still active — cited to
the *Update an appointment* page.

Read the warning off the screen, out loud. Then stop talking for two seconds.

> "I asked to change a text field. The answer is: your slot gets given away."

> "Nothing about that is guessable. It's not conventional, it's not inferable from the path —
> it's a wiring decision somebody made once and wrote down. And follow where it went: it was a
> sentence in the YAML file you saw at the start, it went into the site, into the Markdown,
> into `llms.txt`, and the MCP server just handed it back to me with a link. Nobody copied it.
> Nobody could forget to update it. That's the difference between generating four artifacts
> and maintaining them."

> **Running long?** Cut 3d's `llms.txt` beat to one sentence and skip the human browsing at the
> top of 3d — go straight to the endpoint page. Never cut the plant in Act 2 or the prompt in
> 3e; they are the two ends of the same thread and one without the other proves nothing.

---

### Act 4: The close (1 min) — slide 6

**Do:** advance to slide 6.

> "So: your docs have two readers now. You don't have to choose between them, and you
> definitely shouldn't hand-maintain four artifacts to serve them both. Keep one spec
> somewhere real, and let the site, the Markdown, the index, and the MCP server come out of it
> together — because that's the only version that can't drift."

> "Two commands to try it on your own spec — they're on the slide. And if it goes badly, come
> tell me on the Postman Discord. I'd genuinely like to know."

**Do:** leave slide 6 up. At a booth, this is also your invitation to talk to whoever stayed.

#### The questions you will get

**"Isn't `llms.txt` enough? Why do I need MCP too?"**

> "`llms.txt` is a map. MCP is a librarian. With just the index, the agent still fetches whole
> pages and pulls them into context every session. With MCP it asks a question and gets the
> relevant passage back, cited. You want both — the index is what makes the server's answers
> findable in the first place."

**"What stops it hallucinating?"**

> "Nothing stops the *model* hallucinating — but that answer had a footnote, and you can click
> it. The server only returns passages from pages that exist on that site, and those pages were
> generated from the spec. It can be wrong the way a search engine can be wrong: it can miss
> something. It can't invent an endpoint I never wrote."

**"How does this fit into CI? You published from your laptop."**

> "Deliberately, because it's ten minutes. Those three files next to the spec are the whole
> definition — commit them and run the same `fern generate --docs` from a GitHub Action with a
> `FERN_TOKEN` secret, and a push to the spec republishes everything. Nothing about what you
> just saw changes; only who runs the command."

**"Does it work with a private repo / private docs?"**

> "Fern supports authenticated docs sites, and the MCP server sits behind the same auth. That's
> a configuration question, not a different architecture — and it's the right conversation to
> have at the booth rather than from the stage."

**"How is this different from just publishing my OpenAPI file?"**

> "Publishing the spec gives an agent the contract. It doesn't give it your guides, your
> examples, your auth story, or a way to search any of it. Notice the answer you just saw came
> out of a *prose description*, not a path definition. That's the part a raw spec URL doesn't
> deliver."

---

## 5. Tear down / reset

```bash
./scripts/teardown.sh
```

| State the demo creates | What teardown does |
|---|---|
| `$WORKDIR` with `fern/`, `generators.yml` and `docs.yml` | **Removed** (setup recreates it with just the spec) |
| `$AGENTDIR` | **Removed** (setup recreates it empty) |
| The `appointments-docs` MCP registration | **Removed** (`claude mcp remove`), so Act 3e is a real first-time connect. Registrations are `--scope local`, keyed to the directory, so teardown unregisters *before* deleting the folders — reverse that order and the entry is orphaned and comes back on the next setup. |
| The published Fern site | **Left alone, on purpose** — see below |
| GitHub, repos, commits, CI | None exist. The demo never touches git. |
| API calls, data, credentials | None exist. The spec is a document; the service is never called. |

**Why the site is not unpublished.** The published subdomain is what keeps the search index
warm, and Act 3e depends on that. Unpublishing between runs would hand every run the slow,
unreliable first-publish path. Republishing over a warm subdomain is what makes this demo safe
to give twice in an hour. Teardown reports whether the site is still up and warns you if it
is not.

**Between runs:** `./scripts/teardown.sh && ./scripts/setup.sh`. Two things you must do by
hand: **clear your Claude Code session** (a warm context answers Act 3e without calling the
tool), and **reset the deck to slide 1**.

---

## 6. Troubleshooting

| Issue | Fix |
|---|---|
| **`searchDocs` hangs or returns nothing in 3e** | The index is cold. Point at the warm site instead: `claude mcp add --transport http appointments-docs https://myhealthcare.docs.buildwithfern.com/_mcp/server`. Say what you are doing — same spec, same answer. Then do a rehearsal run before the next slot. |
| **The page URLs do not match what you expected** | This build is single-API, so pages sit at `/api-reference/appointments/update`. The short talk's site is multi-API and puts the same page at `/api-reference/healthcare-org/appointments-service/appointments/update`. Both are correct; the layout decides the path. Take URLs from `llms.txt` rather than typing them — and if you do that on stage, it is an accidental demo of `llms.txt` doing its job. |
| **The agent says *"the local OpenAPI spec has the answer, let me read that"*** | You are in `$WORKDIR`, not `$AGENTDIR`. It can see `appointments.yaml`. Quit, `cd /tmp/appointments-agent`, re-add the server and re-ask. This is the failure that *looks* like success — the answer is right and proves nothing — so call it out rather than letting it slide. |
| **The agent answers 3e from memory, without calling the tool** | Warm context, or it recognised the platform. Say so out loud and re-ask with *"use the connected docs MCP server only, and cite the page"*. Clear the session next run. |
| **The 3e answer misses the footgun** | Re-ask narrowly: *"check the update endpoint page specifically — what events does PATCH publish?"* That is itself a fair demo: the citations are what let you verify and correct it. |
| **`fern check` shows 5 errors about `starts_at` / `reason` / `duration_minutes`** | Expected if you ran it before Act 3b. They are `[sdk]` errors from the TypeScript generator `fern init` scaffolds — this spec's schemas are open (`additionalProperties`) so its request examples fail the SDK validator. Docs are unaffected. Do Act 3b's `generators.yml` trim and check again; it passes. Recover on stage with: *"that's the SDK generator complaining — we're not generating SDKs today, watch."* |
| **`fern generate --docs` opens a browser** | You are not logged in. `Ctrl+C`, `fern login`, retry. `setup.sh` fails on this exact condition — it should never surprise you on stage. |
| **Publish fails: *"A valid API configuration was not found at fern/apis/..."*** | `docs.yml` has an `api-name:` line. Delete it. This project is single-API. |
| **Publish fails with `Failed to resolve organization` (HTTP 500)** | Your account belongs to no organization the CLI can resolve. Set `"organization": "postman-devrel"` in `fern.config.json` — leave `docs.yml`'s subdomain alone, they are independent. Diagnose it directly with `fern org get`: *"No org-level CLI config set for X"* means X resolves and you are fine; **403** means you have no access to X. `setup.sh` runs this check for you now. |
| **`fern org get` returns 403 for every name you try** | You are not a member of any organization — this is what deleting one does. Nothing in the CLI can recreate it; open <https://dashboard.buildwithfern.com> to see what the account actually has, and if it has none, that is a conversation with Fern rather than something to fix on stage. Fall back to the short talk's site for Act 3e. |
| **You are tempted to delete the org to "start clean"** | Don't. It is `postman-devrel`, it is shared with the rest of DevRel, it also publishes the short talk's site, and deleting it is exactly the thing that broke this demo once. Republishing over the same subdomain is the reset. |
| **`fern init` says the project already exists** | You did not tear down, or you ran it twice. `./scripts/teardown.sh && ./scripts/setup.sh`. Never re-run `fern init` in a folder that has a `fern/` — it re-scaffolds and adds a second, imaginary API you then have to hunt down. |
| **The agent says *"no server named appointments-docs is connected"*** | You registered it under a different name — the site's snippet gives `booth-demo-docs-buildwithfern-com`. Harmless: the Act 3e prompt names no server. If you are reading an older prompt, drop the name from it. |
| **`claude mcp add` says the server already exists** | You did not tear down, or the server is registered in a *parent* directory. `--scope local` is inherited, so a registration made in `/private/tmp` shows up in every `/tmp/*` folder and makes "first-time connect" false. `./scripts/teardown.sh` searches by URL across `$AGENTDIR`, `$WORKDIR` and `/private/tmp` and removes whatever name it finds. |
| **`/mcp` shows the server as failed** | Check the URL has no trailing slash and `--transport http` is present. Verify by hand: `curl -s https://booth-demo.docs.buildwithfern.com/_mcp/server` should return a `fern-docs-mcp-server` descriptor. |
| **The subdomain is taken** | Fern subdomains are globally unique across all customers. Pick another: `FERN_HANDLE=<something>-booth ./scripts/setup.sh`. |
| **No network** | Acts 1–2 and 3a–3b still run — you can genuinely scaffold and `fern check` offline. For the rest, walk slide 4 and say the shape: four outputs, one command, and the answer you would have got. Do not fake a terminal. |
| **Someone asks whether you rigged the spec** | Show them. `openapi/appointments.openapi.yaml` is checked into this repo, the warning is in `info.description` *and* on the `patch` operation, and it is the same file the [short talk](../../short-talks/mcp-docs-best-friend/) publishes. `setup.sh` asserts it is still there on every run. |

---

## 7. Additional resources

| Resource | Link |
|---|---|
| The deck | `presentation/index.html` — arrows/space/click, `f` fullscreen, `Home` for slide 1 |
| The spec the demo publishes | `openapi/appointments.openapi.yaml` (10 operations, copied from the short talk) |
| The Fern organization (permanent, shared) | `postman-devrel` · <https://dashboard.buildwithfern.com> |
| The site this demo publishes | <https://booth-demo.docs.buildwithfern.com> (`$FERN_HANDLE`) |
| Its MCP server | `https://booth-demo.docs.buildwithfern.com/_mcp/server` |
| **The payoff page** (Act 3d, single-API paths) | `https://booth-demo.docs.buildwithfern.com/api-reference/appointments/update` · append `.md` for the Markdown |
| Its `llms.txt` | `https://booth-demo.docs.buildwithfern.com/llms.txt` |
| The warm fallback site (**production — read-only**) | <https://myhealthcare.docs.buildwithfern.com> · [its `llms.txt`](https://myhealthcare.docs.buildwithfern.com/llms.txt) |
| The fallback's payoff page, as Markdown | <https://myhealthcare.docs.buildwithfern.com/api-reference/healthcare-org/appointments-service/appointments/update.md> |
| The upstream service | <https://github.com/healthcare-org-app/healthcare-appointments> |
| The app being documented | <https://myhealthcare.dev/> |
| **The 25-minute version of this talk** | [`../../short-talks/mcp-docs-best-friend`](../../short-talks/mcp-docs-best-friend/) |
| The Fern product pitch (slides only, 10 min) | [`../fern`](../fern/) |
| Fern docs — AI features | <https://buildwithfern.com/learn/docs/ai-features/api-catalog> |
| Model Context Protocol | <https://modelcontextprotocol.io> |
| Fern | <https://buildwithfern.com> |
| Postman Discord | <https://discord.gg/postman> |

---

## 8. What this cut dropped, and why

Worth knowing, because you may be asked to give the long version — and because these are
tempting to add back at the wrong moment.

| Dropped | Why it does not fit ten minutes |
|---|---|
| The cold open: a hand-built "before" portal, Safari with JavaScript disabled, `curl \| wc -c` → 1,402 bytes | The strongest ninety seconds in the short talk, and it needs a second browser configured by hand, a local server, and a show of hands. Booth traffic does not do show of hands. |
| The Postman act — the spec being authored and tested in the desktop app | Adds a whole application to the window-switching order to make a point Act 3a already makes structurally: the spec is referenced where it lives, not copied. |
| Three services, the multi-API layout, and the `/health` namespace-collision war story | Requires `fern/apis/<name>/generators.yml` and an `api-name` in `docs.yml` — the opposite of what `fern init --openapi` scaffolds. Excellent content, wrong format. |
| **Git and GitHub entirely** — the empty repo, the first push, the GitHub Action | Fern needs no repository to publish, so carrying one bought an act, an account to be logged into, a prerequisite to reset between runs, and a `git push` that can fail on stage. All of it to gesture at CI, which a single sentence in Act 3c does just as well. |
| The second prompt (discovery, before the payoff) | Two `searchDocs` calls is two cold-start risks. One prompt that needs both discovery *and* the footgun does the same work. |
| Slide 8 — curating four artifacts by hand, the drift argument | Cut for time; the presenter kept three of the twelve slides. Its idea survives as one line in Act 1: nobody has time to keep four things true at once. |

What is **not** negotiable, in either format: the warning gets planted in the spec before the
build, and it comes back out of the MCP server with a citation. Everything else is staging.
