# Make MCPs Your Documentation Best Friend

> [Short talk](../../../templates/formats/short-talk.md) — target length **25 minutes + Q&A**.
> Conference breakout, meetup main slot, or webinar. This README is the single source of
> truth. Read it top to bottom before you present; everything you need is here.

This is a **cold open, a deck, and one long live demo**. You open in the browser, not on a
slide: a perfectly good API portal, then the same portal with JavaScript off — which is what
an agent gets. That is the whole talk in ninety seconds. Then ten slides build the argument,
and slide 10 drops you into the pipeline that fixes it: **one OpenAPI spec, managed in
Postman, deployed by Fern, producing the human site, per-page Markdown, `llms.txt`, and an
MCP server** — which you then connect to a live Claude Code session and query on stage.

The payoff question is chosen so it cannot be guessed: **"if I PATCH an appointment to change
its `reason`, what happens to its slot?"** The answer is a real footgun in this API — a plain
update emits `appointment.cancelled`, and downstream `appointment-slots-service` reopens the
slot. The MCP server finds it in one call, with a citation.

---

## 1. Product summary

**Product:** Fern — one OpenAPI spec becomes the human docs site, per-page Markdown, an
`llms.txt` index, and an MCP server, generated together. The spec itself is authored and
managed in **Postman**.

**Use case:** Show that a docs site can be excellent for people and useless to agents at the
same time, then walk the full pipeline that serves both readers from a single source.

**The story (the narrative arc):**

> Documentation used to have one reader: a developer with your docs open in another tab. Now
> it has two, and the second one has to discover, authenticate, parse, and recover from errors
> on its own. Here is a portal built for the first reader — and here is the same portal with
> JavaScript off, which is what the second one receives. Nobody did anything wrong; the second
> reader did not exist when it was built. The fix is not to write four artifacts by hand, it
> is to generate them: the spec lives in Postman, Fern builds from it, and out comes the human
> site, the Markdown, the index, *and* an MCP server. Then you connect that MCP server to a
> real agent session and ask it a question no one could guess the answer to — and it answers,
> with a citation, in one call.

**CTA:**
- The docs site — <https://myhealthcare.docs.buildwithfern.com>
- The MCP server — `https://myhealthcare.docs.buildwithfern.com/_mcp/server`
- Fern — <https://buildwithfern.com>
- Postman Discord — <https://discord.gg/postman>

**Total time: ~23 minutes**, leaving 2+ for Q&A in a 25-minute slot. Act 0 is the cold open
(~2.5 min), Acts 1–6 are the deck (~8.5 min), Act 7 is the demo (~10 min), Act 8 closes
(~2 min).

---

## 2. Pre-requisites

| Requirement | How to get it |
|---|---|
| **Chrome** (or your usual presenting browser) | Everything except the JS-off tab runs here. |
| **Safari**, with JavaScript disabled | The Act 0 payoff. Safari → Settings → Advanced → *Show features for web developers*, then Develop → **Disable JavaScript**. Set it once; it persists. |
| **Postman desktop app** | Act 7b. Signed in, with the healthcare-org OpenAPI spec open. |
| **Claude Code CLI** | Acts 7e–7f. `claude --version` should work. |
| `python3` (3.8+) | Pre-installed on macOS. Serves the portal and builds the spec bundle. |
| PyYAML | `python3 -m pip install pyyaml`. `setup.sh` installs it if missing. |
| A terminal with a **large font** | Act 7e runs the CLI on stage. Bump to ~18pt. |
| The Claude-design deck | <https://claude.ai/design/p/34e5524b-4e2d-436a-97bc-9a59609fb288?file=MCP+Docs+Best+Friend.dc.html&via=share> — `setup.sh` opens it. Requires you to be signed in to claude.ai. |
| Network | Required for Acts 7a–7f and the deck. Act 0 and Acts 1–6 run offline (use the local deck fallback — see Troubleshooting). |
| **Nothing else** | The `healthcare-org` services do **not** need to be running. The portal's "Try it" panel is fully mocked and sends no requests. |

---

## 3. Setup

```bash
cd content/short-talks/mcp-docs-best-friend
./scripts/setup.sh
```

`setup.sh` will:

1. Rebuild the portal's spec bundle from `openapi/*.yaml` into `site/assets/spec-bundle.js`.
2. **Assert the portal's anti-agent properties** — no `llms.txt`, no `openapi.yaml`, no
   `openapi.json`, no `sitemap.xml`, and an empty root div in `index.html`. These *are* the
   demo, so setup fails loudly if a well-meaning edit ever adds one.
3. Serve the portal at <http://localhost:4173> (override with `PORT=4180 ./scripts/setup.sh`).
4. Check every live surface: `myhealthcare.dev`, the Fern docs site, its `llms.txt`, and the
   MCP server (a real JSON-RPC `initialize` handshake, not just a ping).
5. Create the empty **`/tmp/myhealthcare`** working folder for Act 7e.
6. Open, in order: the **Claude-design deck**, the portal in Chrome, the portal **in Safari**
   (your JS-off tab), and the **Postman desktop app**.

Set `SKIP_OPEN=1` to run all the checks without opening anything.

### Authentication

None on stage. The portal's "Try it" panel never sends a request, `myhealthcare.dev` is
public, the Fern site is public, and its MCP server is unauthenticated. There is no key to
rotate and nothing to leak. You do need to be signed in to **claude.ai** (deck) and the
**Postman desktop app** (Act 7b) — do both before you walk on.

### Pre-demo checklist

Tabs and windows, left to right, in the order you will use them:

- [ ] **Chrome tab 1** — <http://localhost:4173>, scrolled to **API reference** *(Act 0a)*
- [ ] **Safari** — <http://localhost:4173>, **JavaScript disabled**, showing "JavaScript is
      required" *(Act 0b)*. Verify this before you start; a Safari update can reset it.
- [ ] **Chrome tab 2** — the **deck**, fullscreen, slide 1 *(Acts 1–6, 8)*
- [ ] **Chrome tab 3** — <https://myhealthcare.dev/> *(Act 7a)*
- [ ] **Postman desktop** — healthcare-org spec open on the **appointments** definition *(7b)*
- [ ] **Chrome tab 4** — [generators.yml#L18](https://github.com/avdev4j/myhealthcare-fern-doc/blob/main/fern/apis/healthcare-org/generators.yml#L18) *(Act 7c)*
- [ ] **Chrome tab 5** — <https://myhealthcare.docs.buildwithfern.com> *(Act 7d)*
- [ ] **Terminal**, large font, in `/tmp/myhealthcare`, **empty Claude Code context** *(7e–7f)*
- [ ] You have run the Act 7f prompts once already today, so nothing is cold on stage
- [ ] You know the four numbers cold: **1,402 bytes · 404 · 900 KB → 9 KB · 24 endpoints**
- [ ] Browser zoom set so text reads from 6 feet (`Cmd+=` / `Cmd+-`)

That is eight surfaces. Rehearse the switching order once — it is the only fragile part of
this talk.

---

## 4. Talk track and click track

Nine acts, ~23 minutes. Deck slides in order: **(1)** title · **(2)** speaker · **(3)** two
readers · **(4)** what docs are for · **(5)** the agent-facing surface · **(6)** how MCP works
· **(7)** why it matters · **(8)** curating by hand · **(9)** one spec to rule them all ·
**(10)** LIVE demo · **(11)** Discord · **(12)** thank you.

Talk track is **verbatim** (blockquotes) — read it if you need to.

---

### Act 0: The cold open (2.5 min) — no slides

Start in the browser. No title slide, no introduction. Just the portal.

#### 0a — "Is this good documentation?" (1 min)

**Show:** Chrome tab 1 — <http://localhost:4173>. Scroll the overview, open **API reference**,
expand **`POST /api/appointments/`**, click **Try it out** → **Execute**, land the 201.

> "Before I introduce myself, I want your opinion on something. This is the developer portal
> for a hospital platform — appointments, slots, prescriptions. Search, a sidebar, every
> endpoint with its parameters and schemas, worked examples, a try-it panel that returns a
> real 201."

**Do:** stop scrolling. Ask, and *wait for hands*.

> "Show of hands — is this good API documentation?"

**Show (payoff):** most hands go up.

> "Good. I agree with you. Genuinely — this is a nice docs site. Nothing here is broken, and
> nobody who built it did anything wrong."

#### 0b — The same page, for the other reader (1.5 min)

**Do:** switch to **Safari** — same URL, JavaScript disabled.

**Show (payoff):** the entire page is a single grey box: **"JavaScript is required."**

Say nothing for three seconds. Let them read it.

> "Same URL. Same server. Same second of the same day. The only difference is that this
> browser does not run JavaScript — and that is what an agent gets when it fetches your docs."

**Do:** switch to the terminal, one command, large font:

```bash
curl -s http://localhost:4173/ | wc -c
```

**Show (payoff):** `1402`.

> "Fourteen hundred bytes. That's the whole document. Everything you just watched me scroll
> through is built by JavaScript after the page loads — it exists in my browser and nowhere
> else. So: you were right, and I was right. It is a good docs site, and it is unusable by
> half its readers. **That is what we are going to talk about tonight.**"

**Do:** switch to the deck, fullscreen, slide 1.

> **Why this works:** the audience commits publicly to "yes, good docs" before you show the
> counter-evidence. Do not skip the show of hands — without it, this is just a demo. With it,
> they are invested in the answer.

---

### Act 1: Who I am (45 sec) — slides 1–2

**Show:** slide 1 — "Make MCPs Your Documentation Best Friend."

**Do:** advance to slide 2.

> "I'm Anthony, Senior Developer Advocate at Postman. Sixteen years as a Java and JavaScript
> developer before this, and a core member of the JHipster project — so I have written my
> share of documentation nobody could use. That's the perspective I'm bringing."

---

### Act 2: Two readers (2 min) — slide 3

**Do:** advance to slide 3 — BEFORE / NOW.

> "Let me put a name on what you just saw. Before, your docs had exactly one reader: a human,
> skimming headings, hunting for the one paragraph they needed. The integration got written by
> that person. That was the whole model, and every docs tool we have was built for it."

**Show (payoff):** point at the NOW column.

> "Now there are two readers. A human still skims. But an agent has to do four things on its
> own — discover what exists, authenticate, parse the response, and recover when a call fails.
> Nobody is there to squint at the page for it."

> "And here is the part I want you to take home: that portal is not badly built. It is
> *correctly* built, for the reader who existed when it was built. Dual readership is a new
> requirement, not a bug someone introduced. Which means the fix isn't 'try harder' — it's
> structural."

---

### Act 3: What documentation has to do (1.5 min) — slide 4

**Do:** advance to slide 4.

> "So what does documentation actually have to deliver? Three things. What the API *does* —
> endpoints and behaviour. What it *needs* — parameters, schemas, auth. And what it *shows* —
> worked examples and what happens when the call fails."

**Show (payoff):** the takeaway line.

> "Documentation is the interface between your API and whoever has to use it correctly. Not a
> description of your API for its own sake. And notice: nothing in those three bullets says
> 'human'. An agent needs all three too. It just cannot get them the same way."

---

### Act 4: The agent-facing surface, and MCP (3 min) — slides 5–7

**Do:** advance to slide 5.

> "So what do we build for that second reader? Three things. `llms.txt` — a plain-text index
> at the root of the site, so the agent knows what exists before it starts guessing URLs.
> Per-page Markdown — the same content as the HTML page with the navigation and the JS chrome
> stripped out, so it is cheap to parse. And an MCP server — a tool the agent calls directly
> instead of scraping and re-parsing pages itself."

**Show (payoff):** the takeaway.

> "Three formats, one purpose: give the agent a shortcut past the parts of the page it cannot
> use."

**Do:** advance to slide 6.

> "Quick primer on that third one, because MCP gets talked about a lot and explained rarely.
> Four pieces. The **host** is the app the human is in — Claude, an IDE, a custom agent. The
> **client** lives inside the host and manages exactly one connection to one server. The
> **server** is a program that exposes tools — for docs, that's something like `searchDocs`.
> And the **transport** carries JSON-RPC messages between them, usually over HTTP. That's it.
> It's a protocol for exposing tools, not a product."

**Do:** advance to slide 7.

> "Why this is good news specifically for documentation. First, your docs become *queryable*
> instead of scraped — the agent calls a tool instead of parsing raw HTML. Second, answers
> stay grounded: the response is scoped to what your docs actually say, not to what the model
> half-remembers about an API with a similar name. Third — and this is the one that matters at
> scale — it's one door, not one scraper per integration."

**Show (payoff):** the takeaway.

> "Which raises the obvious question. How do you keep all of that up to date? The docs, the
> `llms.txt`, the Markdown, *and* the MCP server."

---

### Act 5: Curating by hand (1.5 min) — slide 8

**Do:** advance to slide 8.

> "Imagine doing it by hand. You add a field to an endpoint. Step one, update the OpenAPI spec
> — the source everyone is supposed to trust. Step two, rewrite the affected doc pages and
> hope you didn't miss one. Step three, update `llms.txt` and the Markdown — if they exist,
> and if anyone still remembers those are separate files. Step four, patch the MCP server,
> re-implementing whatever changed, in a different repo, on a different sprint."

**Show (payoff):** the takeaway.

> "Four surfaces, four owners, four chances to forget. I'll say the quiet part: anything
> maintained by hand drifts. Not might — does. Usually within a quarter. And the drift is
> invisible, because nothing fails. The docs just quietly stop being true."

---

### Act 6: One spec to rule them all (1.5 min) — slide 9

**Do:** advance to slide 9.

> "So don't maintain them. Generate them. One OpenAPI spec plus your guides — the examples,
> the parameter definitions, the auth story — feeds all four outputs at once. The human docs
> site, same as always but always in sync. Per-page Markdown for every page. The `llms.txt`
> index. And the MCP server, which is the piece that lets an agent actually *use* the other
> three."

**Show (payoff):** the takeaway.

> "Nothing is copied by hand. Everything is built together, so it cannot drift. That's the
> claim. Now let me show you the whole thing running, end to end — one spec, four outputs, and
> an agent on the other end of it."

---

### Act 7: The pipeline, live (10 min) — slide 10

**Do:** advance to slide 10 — the LIVE / Demo slide. Leave it up whenever you are between
windows; it is your backdrop for the whole act.

> "Everything from here is live. Follow the spec — it's the only thing that moves."

#### 7a — The app we are documenting (1 min)

**Show:** Chrome tab 3 — <https://myhealthcare.dev/>.

> "This is MyHealthcare — the platform behind that portal. Fourteen business domains, a
> hundred and one services. Today we only care about three of them: appointments, appointment
> slots, and prescriptions. Twenty-four endpoints between them."

> "I'm showing you the running product first for one reason: the documentation problem is
> never abstract. There is a real service here, it has real behaviour, and some of that
> behaviour is genuinely surprising. Hold that thought — we come back to it at the end."

#### 7b — Where the spec lives: Postman (1.5 min)

**Do:** switch to the **Postman desktop app**, healthcare-org, the appointments definition.

**Do:** scroll the spec. Land on **`PATCH /api/appointments/{record_id}`** and show the
description — the `⚠️` note about `appointment.cancelled`.

> "Step one of the pipeline: the spec. It lives in Postman, and this is where it is actually
> worked on — I edit it here, I test the endpoints against it here, and my team reviews it
> here. This is not a build artifact somebody generates and forgets. It's the source."

> "And look at what's in it. This is the PATCH endpoint, and the description carries a warning
> — a plain update publishes `appointment.cancelled`. That is written down. Remember it."

**Do:** point at the collection/definition split if your workspace has both.

> "The important property is that there is exactly one of these. Not one per output. One."

#### 7c — Where the spec gets consumed: Fern (1.5 min)

**Do:** switch to Chrome tab 4 —
[fern/apis/healthcare-org/generators.yml#L18](https://github.com/avdev4j/myhealthcare-fern-doc/blob/main/fern/apis/healthcare-org/generators.yml#L18)

**Show (payoff):** the highlighted line is a `repo:` pointing at the appointments service, with
`path: openapi.yaml` under it — one entry per service, each with a `namespace`.

> "Step two. This is the entire Fern configuration for the API. Eighteen lines in, that's the
> spec you just watched me edit — referenced by repo and path, not copied. Three services,
> three entries, one namespace each."

**Do:** scroll up two lines to the comment block above `api:`.

> "The comment there is a real war story, and it's worth thirty seconds. Without those
> namespaces, Fern merges the specs on raw path keys — and every service exposes `/health` and
> `/ready`, so they collapse into one copy and the rest get dropped. Silently. `fern check`
> stays green, the build succeeds, and you ship twenty pages instead of twenty-four. That's
> the drift problem again, one layer down: nothing failed, it was just quietly wrong."

> "So: one spec file, managed in Postman, referenced here, deployed by Fern. Let's see what
> comes out."

#### 7d — Four outputs from one spec (2 min)

**Do:** switch to Chrome tab 5 — <https://myhealthcare.docs.buildwithfern.com>.

**Do:** browse it like a human for twenty seconds — Welcome, Business domains, then into
**API Reference → Appointments Service → Update an appointment**.

> "**Output one: the human site.** And it's deliberately unremarkable — it's a docs site, it's
> nice, you can read it. Nothing has been taken away from the reader we already had. That's
> the bar, and it's met."

**Do:** in the address bar, add **`.md`** to the current URL and hit enter:
<https://myhealthcare.docs.buildwithfern.com/api-reference/healthcare-org/appointments-service/appointments/update.md>

**Show (payoff):** the same page as clean Markdown — and the ⚠️ block from Postman is right
there in plain text, four lines from the top.

> "**Output two: Markdown.** Add dot-M-D to any URL on this site. Same page, no chrome. The
> HTML version is nine hundred kilobytes. This is nine. A hundred times smaller — and every
> fact survived, including that warning I showed you in Postman. Same sentence, different
> surface, zero copies."

**Do:** open <https://myhealthcare.docs.buildwithfern.com/llms.txt>.

**Show (payoff):** instructions for agents at the top, then all 24 endpoints with descriptions
and `.md` links, then the raw OpenAPI links at the bottom.

> "**Output three: `llms.txt`.** Every endpoint across all three services, named, described,
> linked. Six kilobytes for the entire API surface. The agent stops guessing URLs and reads
> the index — same as you would. And notice the top of the file: it *tells* the agent about
> the dot-M-D trick and about the MCP server. The docs document how to read the docs."

**Do:** scroll to the bottom, point at the OpenAPI JSON/YAML links.

> "And the spec itself is published, at a URL, which is exactly what the first portal 404'd
> on."

**Do:** scroll back to the MCP line at the top and select the `_mcp/server` URL.

> "**Output four**, and the one this talk is named after: an MCP server. Same content, same
> build, no extra repo. Let's plug it in."

#### 7e — Connect it to a real agent (1 min)

**Do:** switch to the terminal. Large font. Show it is an empty folder:

```bash
cd /tmp/myhealthcare && ls -la
```

> "Clean machine, empty folder, nothing installed. This is the position anyone integrating
> your API is in on day one."

**Do:**

```bash
claude mcp add --transport http myhealthcare-docs https://myhealthcare.docs.buildwithfern.com/_mcp/server
```

**Do:** start a session and confirm the server is live:

```bash
claude
```

then, in the session:

```
/mcp
```

**Show (payoff):** `myhealthcare-docs` listed as **connected**, exposing one tool —
`searchDocs`.

> "One command. One tool: `searchDocs`. No SDK, no scraping, no API key. The docs are now
> something this agent can *ask*, not something it has to download and re-read."

#### 7f — Ask it two questions (2.5 min)

**The first prompt** — discovery. Paste verbatim:

```
Using the myhealthcare-docs MCP server, what endpoints does the appointments
service expose, and what does each one do?
```

**Show (payoff):** one `searchDocs` call. It comes back with the endpoints, each with its
method, path, behaviour, the events it publishes, and a footnote link to the exact doc page.

> "One tool call. Note two things. It knows the *events* each endpoint publishes — that's not
> in an OpenAPI path definition, that's in the description I wrote in Postman, and it survived
> all the way through. And every claim has a footnote pointing at the page it came from. It is
> not remembering my API. It is reading it."

**The second prompt** — the payoff. It uses `PATCH /api/appointments/{record_id}` from the
list the agent just produced. Paste verbatim:

```
I want to change only the `reason` field on an existing appointment using that
PATCH endpoint. What side effects does that have on the appointment slot?
```

**Show (payoff):** one more `searchDocs` call, and the answer is the footgun — a plain PATCH
publishes `appointment.cancelled`, so `appointment-slots-service` reopens the slot even though
the appointment is still active. Cited to `.../appointments/update`.

Read the ⚠️ line off the screen, out loud.

> "There it is. I asked to change a text field. The answer is: your slot gets given away."

> "That is a genuine footgun in this API. No model guesses that — it is not conventional, it
> is not inferable from the path, it is a wiring decision somebody made once. It was in the
> spec in Postman, it went into the Markdown, it went into `llms.txt`, and the MCP server
> surfaced it in one call with a link to prove it."

> "Now go back thirteen minutes. Same question, same content, against the first portal: the
> agent gets fourteen hundred bytes and a 404, and answers 'nothing happens to the slot' —
> confidently, reasonably, and wrong. Not a crash. A wrong answer that looks right. That's the
> failure mode, and it is the expensive one."

> **Fast version (running long?):** cut 7a to one sentence, and drop the second prompt in 7f.
> Doing 7d and the first prompt still lands the argument. Do **not** cut 7c — the "one spec,
> referenced not copied" beat is the actual thesis.

---

### Act 8: The close (2 min) — slides 11–12

**Do:** advance to slide 11 — Discord.

> "Before I let you go — the Postman Community on Discord. Scan that. Come ask questions, show
> us what you're building, tell me if you try this on your own docs and it goes badly. I'd
> genuinely like to know."

**Do:** advance to slide 12.

> "So: your docs have two readers now. You do not have to choose between them, and you should
> not maintain four artifacts by hand to serve them both. Write the spec, keep it somewhere
> real, and let the human site, the Markdown, the index, and the MCP server come out of it
> together — because that's the only version that can't drift."

> "Everything you saw is public: the docs site, the Fern repo, and the MCP server URL. Slides
> and links are on the event page. Questions?"

**Do:** leave slide 12 up for Q&A.

#### The two questions you will get

**"Isn't `llms.txt` enough? Why do I need MCP too?"**

> "`llms.txt` is a map. MCP is a librarian. With `llms.txt` the agent still fetches pages,
> pulls them into context, and re-reads them every session — you saw nine kilobytes for one
> endpoint, and there are twenty-four. With MCP it asks a question and gets the relevant
> passage back, cited. Both, ideally: the index is what makes the MCP server's answers
> findable in the first place."

**"What stops the MCP server from hallucinating?"**

> "Nothing stops the *model* from hallucinating — but that answer had footnotes, and you can
> click them. The MCP server only returns passages from pages that exist on that site, and
> those pages were generated from the spec. It can be wrong the way a search engine can be
> wrong — it can miss something. It can't invent an endpoint I never wrote."

---

## 5. Tear down / reset

```bash
./scripts/teardown.sh
```

| State the demo creates | What teardown does |
|---|---|
| A `python3 -m http.server` in front of `site/` | **Stops it** (by pid, then by port, so a hand-started one is caught too) |
| `.demo-state` (the server pid) | Removed |
| `/tmp/mcp-docs-portal.log` | Removed |
| `/tmp/myhealthcare/` (Act 7e working folder) | Removed |
| The `myhealthcare-docs` MCP registration | **Removed** (`claude mcp remove`), so Act 7e is a real first-time connect next run |
| `site/assets/spec-bundle.js` | **Kept** — setup rebuilds it every run. `--purge` deletes it. |

Nothing else exists to clean up: **no API calls are ever made** (the portal's "Try it" panel
is mocked), no credentials, no cloud resources, and nothing on the Fern or Postman side is
touched.

**Between runs:** `./scripts/teardown.sh && ./scripts/setup.sh`. Three things you must do by
hand:

1. **Clear your Claude Code session** — a warm context already knows the Act 7f answer.
2. **Re-check Safari's Disable JavaScript** — it survives restarts but not every update.
3. **Reset the deck** to slide 1 and collapse any endpoints you expanded in the portal.

---

## 6. Troubleshooting

| Issue | Fix |
|---|---|
| **Safari renders the portal normally** | Disable JavaScript came back on. Develop → Disable JavaScript. If the Develop menu is gone: Settings → Advanced → *Show features for web developers*. Fallback: run the Act 0b `curl` first and say "fourteen hundred bytes is the whole page" — it lands almost as well. |
| **No hands go up in Act 0a** | Someone in the room already knows where this is going. Roll with it: *"some of you have seen this coming — good, then you already know what I'm about to show you."* Then do 0b anyway; the visual still works. |
| **The deck won't load from claude.ai** | You're signed out, or offline. Fall back to the local copy: `presentation/index.html` — same 12 slides, opens with no network. Arrow keys / space to advance, `f` for fullscreen, `Home` for slide 1. |
| **Postman desktop opens on the wrong workspace** | Set it before you walk on; there is no fast recovery on stage. If it happens, skip to 7c and say "the spec lives in Postman, here's where Fern picks it up" — the pipeline still reads. |
| Port 4173 is already in use | `./scripts/teardown.sh` frees it, or `PORT=4180 ./scripts/setup.sh` — then use that URL in Act 0 **and in Safari**. |
| `setup.sh` fails on the spec bundle | It needs PyYAML: `python3 -m pip install pyyaml`. If pip is blocked, the checked-in `spec-bundle.js` still works — the build only matters if you edited `openapi/`. |
| Portal shows "Loading the API portal…" forever in Chrome | `spec-bundle.js` failed to load. Hard-refresh (`Cmd+Shift+R`); if it persists, re-run `./scripts/build-spec-bundle.py`. |
| **`claude mcp add` says the server already exists** | You didn't tear down. `claude mcp remove myhealthcare-docs`, then re-add. Do this *before* the audience is watching. |
| **`/mcp` shows the server as failed** | Check the URL has no trailing slash and `--transport http` is present. Verify by hand: `curl -s -X POST https://myhealthcare.docs.buildwithfern.com/_mcp/server -H 'Content-Type: application/json' -H 'Accept: application/json, text/event-stream' -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"x","version":"1"}}}'` — you should get a `fern-docs-mcp-server` result. `setup.sh` runs exactly this check for you. |
| **`searchDocs` is slow on stage** | Normal range is 7–15 seconds; a cold first call can take 40+. This is why the checklist says run the prompts once before you present. While it spins, narrate: *"it's searching the docs, not the model's memory — that's the delay you're watching."* |
| **The agent answers 7f from prior knowledge, without calling the tool** | Context is warm, or it recognised the platform. Say so out loud and re-ask with *"use the myhealthcare-docs MCP server and cite your sources"*. Clean context next time. |
| **The 7f answer misses the footgun** | Re-ask more narrowly: *"check the update endpoint page specifically — what events does PATCH publish?"* That is itself a fair demo: the index and the citations are what let you verify and correct it. |
| No network at all | Run Act 0 and Acts 1–6 from the local deck, then say the numbers: **1,402-byte shell; 900 KB of HTML becomes 9 KB of Markdown, ~100× smaller; `llms.txt` lists all 24 endpoints; the MCP server answers in one call.** Slides 9 and 10 carry the argument. |
| The Fern site's page layout changed | It's a live site. The `.md` trick, `llms.txt`, and `/_mcp/server` are stable; if a specific page moved, re-derive the URL from `llms.txt` on the spot — an accidental demo of `llms.txt` doing its job. |

---

## 7. Additional resources

| Resource | Link |
|---|---|
| The deck (Claude design) | <https://claude.ai/design/p/34e5524b-4e2d-436a-97bc-9a59609fb288?file=MCP+Docs+Best+Friend.dc.html&via=share> |
| The deck (offline fallback) | `presentation/index.html` |
| The "before" portal (this repo) | `site/` — served at <http://localhost:4173> |
| The app being documented (Act 7a) | <https://myhealthcare.dev/> |
| The Fern config repo (Act 7c) | <https://github.com/avdev4j/myhealthcare-fern-doc> |
| The exact line to open (Act 7c) | [generators.yml#L18](https://github.com/avdev4j/myhealthcare-fern-doc/blob/main/fern/apis/healthcare-org/generators.yml#L18) |
| The docs site, built by Fern (Act 7d) | <https://myhealthcare.docs.buildwithfern.com> |
| Its `llms.txt` index | <https://myhealthcare.docs.buildwithfern.com/llms.txt> |
| The Act 7d Markdown page | <https://myhealthcare.docs.buildwithfern.com/api-reference/healthcare-org/appointments-service/appointments/update.md> |
| Its published OpenAPI | <https://myhealthcare.docs.buildwithfern.com/openapi.yaml> |
| Its MCP server (Acts 7e–7f) | `https://myhealthcare.docs.buildwithfern.com/_mcp/server` |
| Source specs, copied into this demo | `openapi/*.openapi.yaml` |
| Upstream services | <https://github.com/healthcare-org-app> |
| Model Context Protocol | <https://modelcontextprotocol.io> |
| Fern | <https://buildwithfern.com> |
| Postman Discord (slide 11) | <https://discord.gg/postman> |
| Companion demo — the full Fern product pitch | `../../lightning-talks/fern` |

---

## 8. How the "before" portal is built

Worth knowing, because an attendee will ask whether you rigged it.

`site/` is a hand-built single-page app: `index.html` is a 1,402-byte shell containing an empty
`<div id="root">` and a `<noscript>` block, and `assets/portal.js` constructs the entire portal
— overview, platform notes, every operation, every schema — at runtime from the three OpenAPI
files. It renders **27** operations against Fern's **24**: the specs declare three `PUT`
aliases that Fern collapses into their `PATCH` twin and the portal does not. Say "twenty-four
endpoints" on stage — that is the number in `llms.txt`, and the three aliases are not a real
difference in coverage.

The look is the API-explorer convention everyone recognises (method pills, collapsible
operation rows, parameter tables, a try-it panel), rebranded blue and carrying no third-party
name or code.

Every property that makes it hostile to agents is a real property, and each one is common in
the wild:

| Property | How it's done | Why it's realistic |
|---|---|---|
| Content is invisible in the source | Client-rendered into an empty div | Every SPA docs portal behaves this way |
| No `llms.txt` | The file does not exist | It did not exist as a convention when most portals were built |
| No per-page Markdown | There are no per-page URLs at all — routing is `#`-fragments | Hash routing was standard for years |
| No fetchable spec | `scripts/build-spec-bundle.py` compiles `openapi/*.yaml` to base64 inside `assets/spec-bundle.js`; nothing is served as `.yaml` or `.json` | Bundlers inline data by default; publishing the raw spec is an extra, deliberate step |
| No MCP server | There isn't one | Same as almost every portal today |
| `robots.txt` disallows everything | `site/robots.txt` | Plenty of vendors block AI crawlers on purpose |

`setup.sh` asserts the first four every run, so the demo cannot quietly rot. The "Try it" panel
synthesises responses from the specs' own examples and never opens a socket — which is why
this demo needs nothing running and leaves nothing behind.

The `<noscript>` block is the one concession to stagecraft, and it is an honest one: without
it, Safari shows a blank white page, which reads as "the demo broke" rather than "the content
is not there." The message it displays — *"JavaScript is required"* — is what a real portal in
this position would say.
