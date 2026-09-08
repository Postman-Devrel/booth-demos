# Make MCPs Your Documentation Best Friend

> [Short talk](../../../templates/formats/short-talk.md) — target length **25 minutes,
> Q&A included**. Conference breakout, meetup main slot, or webinar. This README is the single
> source of truth. Read it top to bottom before you present; everything you need is here.
>
> **There is a 10-minute booth cut of this same talk** — same cold open, same demo, and **no
> slides at all**. It is [section 9](#9-the-10-minute-booth-cut), not a separate folder.

This is a **cold open, a deck, and one long live build**. You open in the browser, not on a
slide: a perfectly good API portal, then the same portal with JavaScript off — which is what
an agent gets. That is the whole talk in ninety seconds. Then the deck builds the argument,
and hands you a terminal holding **one OpenAPI file in an otherwise empty folder**. Three commands later that file has become a human docs site, per-page Markdown, an
`llms.txt` index, and an MCP server — which you connect to a live Claude Code session and
query on stage.

The payoff question is chosen so it cannot be guessed: **"if I PATCH an appointment to change
its `reason`, what happens to its slot?"** The answer is a real footgun in this API — a plain
update emits `appointment.cancelled`, and downstream `appointment-slots-service` reopens the
slot. You plant that warning in the spec in Act 7a and get it back out of the MCP server, with
a citation, in Act 7f. **That round trip is the talk.** If you cut anything, do not cut either
end of it.

---

## 1. Product summary

**Product:** Fern — one OpenAPI spec becomes the human docs site, per-page Markdown, an
`llms.txt` index, and an MCP server, generated together by one command.

**Use case:** Show that a docs site can be excellent for people and useless to agents at the
same time, then build the pipeline that serves both readers from a single source, live.

**The story (the narrative arc):**

> Documentation used to have one reader: a developer with your docs open in another tab. Now
> it has two, and the second one has to discover, authenticate, parse, and recover from errors
> on its own. Here is a portal built for the first reader — and here is the same portal with
> JavaScript off, which is what the second one receives. Nobody did anything wrong; the second
> reader did not exist when it was built. The fix is not to write four artifacts by hand, it
> is to generate them. So here is one OpenAPI file in an empty folder, and three commands —
> and out comes the human site, the Markdown, the index, *and* an MCP server. Then you connect
> that MCP server to a real agent session and ask it a question no one could guess the answer
> to — and it answers, with a citation, in one call.

**CTA:**
- Fern — <https://buildwithfern.com>
- Try it on your own spec — `npm i -g fern-api && fern init --openapi ./your-spec.yaml`
- Postman Discord — <https://discord.gg/postman>

**Total time: ~20.5 minutes of content**, which leaves ~4.5 minutes of Q&A **inside** a
25-minute slot. Act 0 is the cold open (~2.5 min), Acts 1–6 are the deck (~8.5 min), Act 7 is
the live build (~7.5 min), Act 8 closes (~2 min).

> Those 4.5 minutes are Q&A, **not** slack. If the search index is cold you spend the
> questions recovering — see [section 3](#the-one-thing-that-decides-whether-this-lands).

---

## 2. Pre-requisites

| Requirement | How to get it |
|---|---|
| **Chrome** (or your usual presenting browser) | Everything except the JS-off tab runs here. |
| **Safari**, with JavaScript disabled | The Act 0b payoff. Safari → Settings → Advanced → *Show features for web developers*, then Develop → **Disable JavaScript**. Set it once; it persists, but not across every update. |
| **Node.js 18+ and npm** | The Fern CLI runs on it. |
| **Fern CLI** | `npm install -g fern-api`. Verify with `fern --version`. |
| **A Fern account, logged in** | `fern login` → **Continue with Postman**. Do this *before* you present — an unauthenticated `fern generate` opens a browser mid-demo. `setup.sh` fails if `~/.fern/token` is missing. |
| **Claude Code CLI** | Act 7f. `claude --version` should work. |
| `python3` (3.8+) | Pre-installed on macOS. Serves the portal and builds the spec bundle. |
| PyYAML | `python3 -m pip install pyyaml`. `setup.sh` installs it if missing. |
| A terminal with a **large font** | Act 7 *is* the terminal. Bump to ~18pt. |
| The Claude-design deck — **the deck of record, 7 slides** | <https://claude.ai/design/p/34e5524b-4e2d-436a-97bc-9a59609fb288?file=MCP+Docs+Best+Friend.dc.html&via=share> — `setup.sh` opens it. Requires you to be signed in to claude.ai. |
| Network | Required for Acts 7d–7f and the deck. Act 0, Acts 1–6 and Acts 7a–7c run offline. |
| **A rehearsal run, same day** | Not optional. See [the one thing that decides whether this lands](#the-one-thing-that-decides-whether-this-lands). |
| **No GitHub, no `git`** | Deliberate. `fern init`, `fern check` and `fern generate --docs` need no repository — `setup.sh` proves it every run by scaffolding in a folder that is not one. |
| **Nothing else** | The `healthcare-org` services do **not** need to be running. The portal's "Try it" panel is fully mocked and sends no requests. |

### Configuration

| Variable | Default | What it is |
|---|---|---|
| `PORT` | `4173` | Where the "before" portal is served for Act 0. |
| `FERN_ORG` | `postman-devrel` | The **organization** — the DevRel team's shared Fern tenant. Goes in `fern.config.json`. Permanent. You do not invent it and you do not delete it. |
| `FERN_HANDLE` | `booth-demo` | The **subdomain** — `<handle>.docs.buildwithfern.com`, the site this demo publishes *inside* that org. Goes in `docs.yml`. Globally unique across all Fern customers. |
| `WORKDIR` | `/tmp/appointments-docs` | Where Acts 7a–7e run. Holds the spec, then the `fern/` project. |
| `AGENTDIR` | `/tmp/appointments-agent` | Where Act 7f runs. **Must be empty** — it is what stops the agent reading the spec instead of calling the MCP server. |

> ### The organization is not the subdomain
>
> This is the one thing to internalise, because getting it wrong cost a demo already.
>
> The **organization** is the account-level tenant you belong to. One organization publishes
> many sites. `postman-devrel` already publishes `myhealthcare.docs.buildwithfern.com` — the
> names do not match, and they were never meant to.
>
> Passing a name you made up to `fern init --organization` **does not fail**. Fern provisions
> that organization for you on the first publish. So the mistake is invisible until someone
> tries to tidy up.
>
> **Never delete a Fern organization.** Deleting one leaves your account belonging to none,
> and every subsequent publish dies with a 500 `Failed to resolve organization` that gives you
> no hint where to look. There is nothing up there to reset — the org is permanent, the demo
> site lives inside it, and **republishing over the same subdomain is the reset.** Note that
> deleting the org does *not* take the published site down, which makes it even more
> confusing.
>
> `setup.sh` verifies the organization resolves before you walk on.

> ### `myhealthcare` is production. Do not publish to it.
>
> `myhealthcare.docs.buildwithfern.com` is the **real MyHealthcare documentation** — a live,
> three-service site that other content links to, and this talk's warm fallback. It happens to
> live in the same organization as this demo, which is exactly what makes it easy to clobber:
> `fern generate --docs` publishes wherever `docs.yml` points, with no confirmation beyond a
> generic production warning.
>
> Publishing this one-service demo to that subdomain would **replace the real documentation
> with ten appointment endpoints.** `setup.sh` hard-fails if `FERN_HANDLE=myhealthcare`, but
> the check only covers that exact string — read your `docs.yml` before every
> `fern generate`.
>
> The demo site is `booth-demo`, a throwaway name inside the same org. Publish there as often
> as you like.
>
> The one place this README points at `myhealthcare` is the Act 7f fallback, and that use is
> **strictly read-only**: `claude mcp add` against its MCP server, plus `curl` on its
> `llms.txt`. Neither writes anything. Never point `docs.yml` at it.

---

## 3. Setup

```bash
cd content/short-talks/mcp-docs-best-friend
./scripts/setup.sh
```

`setup.sh` has two jobs, and they pull in opposite directions: the cold open needs the portal
to **exist**, and the build needs the pipeline to **not exist yet**. It will:

1. Check the tooling — `python3`, `node`, `npm`, `fern`, `claude` — and that **Fern is logged
   in** and the **organization resolves**. Both are hard failures.
2. Assert the payoff warning is still in `openapi/appointments.openapi.yaml`. Without it the
   demo runs fine and proves nothing.
3. Rebuild the portal's spec bundle from `openapi/*.yaml` into `site/assets/spec-bundle.js`.
4. **Assert the portal's anti-agent properties** — no `llms.txt`, no `openapi.yaml`, no
   `openapi.json`, no `sitemap.xml`, and an empty root div in `index.html`. These *are* the
   demo, so setup fails loudly if a well-meaning edit ever adds one.
5. Serve the portal at <http://localhost:4173> and print the exact byte count for Act 0b.
6. Create `$WORKDIR` holding **exactly one file**, `appointments.yaml` — no `fern/`, no
   `.git`.
7. Create `$AGENTDIR` and assert it is **empty**.
8. **Run the Act 7b–7c sequence in a throwaway folder** — `fern init`, then the trimmed
   `generators.yml`, then `fern check` — so a CLI upgrade or a spec edit cannot break Act 7
   silently. It also proves the demo needs no git: the throwaway folder is not a repository.
9. Report whether the docs subdomain's search index is **WARM or COLD**, and check the warm
   fallback site.
10. Check no MCP registration for this URL is already visible from `$AGENTDIR` — **by URL, not
    by name**.
11. Open the deck, the portal in Chrome *(Act 0a)*, and the portal **in Safari** *(Act 0b)*.
    **Nothing else** — the docs site does not exist until Act 7d publishes it, so a tab for it
    now shows the room a 404.
12. Print the whole paste-ready act sequence and the Act 7f prompt verbatim, so you never have
    to come back to this README on stage.

Set `SKIP_OPEN=1` to run all the checks without opening anything.

### The one thing that decides whether this lands

**Fern builds the search index after the first publish, and it takes minutes.** Measured
2026-09-07: `searchDocs` was still unavailable when `fern generate --docs` had just finished,
and started answering normally about **five minutes later**. A warm site answers in 5–15 s.

A 25-minute slot has ~4.5 minutes of Q&A and no other slack, so a cold index means spending
the questions on recovery.

**So the site must already exist before you present:**

```bash
./scripts/setup.sh      # read the WARM/COLD verdict
# ... if COLD: run the whole demo once, alone, then:
./scripts/teardown.sh
./scripts/setup.sh      # this should now say WARM
```

On stage `fern generate --docs` then republishes to a subdomain that already has an index,
which is both faster and much safer. If the index is cold anyway, fall back to
`myhealthcare.docs.buildwithfern.com` — same spec, same warning, permanently warm, and
**read-only**.

### Authentication

None on stage beyond Fern. The portal's "Try it" panel never sends a request, the published
site is public, and its MCP server is unauthenticated. There is no key to rotate and nothing
to leak. You do need to be signed in to **claude.ai** (the deck) and **logged into the Fern
CLI** — do both before you walk on.

### Pre-demo checklist

Windows, left to right, in the order you will use them:

- [ ] **Chrome tab 1** — <http://localhost:4173>, scrolled to **API reference** *(Act 0a)*
- [ ] **Safari** — <http://localhost:4173>, **JavaScript disabled**, showing "JavaScript is
      required" *(Act 0b)*. Verify this before you start; a Safari update can reset it.
- [ ] **Chrome tab 2** — the **deck**, fullscreen, slide 1 *(Acts 1–6, 8)*
- [ ] **Terminal**, ~18pt, `cwd` = `/tmp/appointments-docs`, `ls` shows **one file** *(Act 7)*
- [ ] **Claude Code context CLEAN** — a warm session answers Act 7f without calling the tool,
      which destroys the payoff
- [ ] You will `cd /tmp/appointments-agent` before Act 7f. The agent must **not** see the spec
- [ ] `setup.sh` said **WARM**
- [ ] You know the numbers: **1,402 bytes · 404 · 780 KB → 9 KB (~90×) · 10 operations**
- [ ] The bridge sentence is ready: *the portal shows three services, tonight we publish one*
- [ ] Browser zoom set so text reads from 6 feet (`Cmd+=` / `Cmd+-`)

Four surfaces, not ten. Rehearse the switch from Safari to the deck, and the switch from the
deck to the terminal — those are the only fragile transitions.

---

## 4. Talk track and click track

Nine acts, ~20.5 minutes. The beats in order: title · speaker · two readers · what docs are
for · the agent-facing surface · how MCP works · why it matters · curating by hand · one spec
to rule them all · LIVE demo · Discord · thank you.

> ### The slide numbers below are stale — the content is not
>
> The **deck of record is the Claude design deck**, and it is now **7 slides** (the argument
> sits on slides 3–7). The offline fallback, `presentation/index.html`, is still the older
> **12-slide** cut, and the `— slides N` labels on the act headings below still refer to that
> 12-slide numbering.
>
> **The acts, their order, and every word of the talk track are unaffected.** Only the mapping
> from act to slide number is. Open the Claude deck once, re-map the labels, and re-cut the
> fallback — until then, present from the Claude deck and treat the numbers below as "the next
> slide".

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
> claim, and claims are boring — so let's just do it. One file, three commands, and at the end
> an agent is going to tell me something about this API that it has no way of knowing."

---

### Act 7: Build it, live (7.5 min) — slide 10

**Do:** advance to slide 10 — the LIVE / Demo slide. Leave it up whenever you are between
windows; it is your backdrop for the whole act.

> "Everything from here is live. Three steps, and none of them is 'write documentation'."

#### 7a — What we start with (1 min)

**Do:** switch to the terminal. Large font, already in `/tmp/appointments-docs`.

```bash
ls
```

**Show (payoff):** one file — `appointments.yaml`.

> "This is everything I have. One OpenAPI file describing the appointments service — ten
> endpoints. No docs folder, no site, no config, no MCP server, not even a git repo. That's
> the starting position. And it's one of the three services you saw in that portal — we're
> going to fix one of them tonight, properly."

**Do:** show the warning in the spec. **This is the plant for the payoff — do not skip it.**

```bash
grep -n -A4 'a plain update emits' appointments.yaml
```

**Show (payoff):** the ⚠️ block — a plain update emits `appointment.cancelled`, so
`appointment-slots-service` reopens the slot.

> "One thing in this file to remember. Somebody wired the generic 'record updated' event to
> the topic named `appointment.cancelled`. So a plain `PATCH` — changing a text field —
> publishes 'cancelled', and downstream, the slots service gives the slot away. The
> appointment is still active. That is genuine, it is written down right here, and it is the
> kind of thing no model can guess. Remember it — we're going to ask an agent about it in
> about five minutes."

#### 7b — Scaffold (1 min)

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
> different talk — I'm dropping it in a second so we stay on docs."

> **Do NOT run `fern check` here.** `fern init` scaffolds a TypeScript SDK generator, and the
> SDK validator throws five errors on this spec's request examples: the schemas are open
> (`additionalProperties`, because the service stores a free-form JSONB `data` document), so
> the example keys are not declared members. Docs do not care. `fern check` does. Act 7c
> removes that generator and *then* checks green — check here and you show the room red text
> for no reason. `setup.sh` runs this whole sequence as a preflight, so you will know before
> you walk on if it ever changes.

#### 7c — Two small YAML files (1 min)

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

#### 7d — Publish (1 min 15)

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

> "And there's no magic in the folder either. It's three small text files next to a spec.
> Commit them, run this same command from a GitHub Action, and a push to your spec republishes
> your docs. I'm not doing that here because it isn't the interesting part — the interesting
> part is what just came out."

**Show (payoff):** `Published docs to https://booth-demo.docs.buildwithfern.com`.

> *(If you did a rehearsal run and someone noticed the subdomain already existed:)* "Yes —
> this republishes over the site I built this morning. Same command, and it's the same command
> CI would run."

#### 7e — The four outputs (1 min 30)

**Do:** open the printed URL. Browse it like a human for fifteen seconds, then go to
**API Reference → Appointments → Update an appointment**.

> "**Output one: the human site.** Deliberately unremarkable — it's a docs site, it's nice,
> you can read it. Nothing was taken away from the reader we already had. That's the bar, and
> it's met."

**Do:** add **`.md`** to the current URL and hit enter.

**Show (payoff):** the same page as clean Markdown — and the ⚠️ block from Act 7a is right
there in plain text.

> "**Output two: Markdown.** Append dot-M-D to any URL on this site. Same page, no chrome. The
> HTML version of this page is seven hundred and eighty kilobytes. This is nine. Nearly ninety
> times smaller — and look: my warning survived. Same sentence I showed you in the spec,
> different surface, zero copies."

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

#### 7f — Connect it to an agent and ask (2 min 45)

**Change folders first.** This is not housekeeping — see
[the two things that break Act 7f](#the-two-things-that-break-act-7f). If the agent can see
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

> **The prompt names no server on purpose.** This one server ends up registered under at least
> three different names depending on which command you used:
>
> | Name | Where it comes from |
> |---|---|
> | `appointments-docs` | the command in this README and in `setup.sh` |
> | `booth-demo-docs-buildwithfern-com` | the snippet in the docs site's own UI |
> | `fern_mcp_booth-demo-docs-buildwithfern-com` | the `usage.claudeCode` field of `/_mcp/server` |
>
> Name it in the prompt and you get the agent opening with *"no server named
> appointments-docs is connected"* — which is what happened on 2026-09-08. Whichever name you
> register, this prompt works. Pick the site's snippet if you like: *"the docs even tell me the
> command"* is a fair beat.

**Claude Code will ask permission** to run `mcp__<server>__searchDocs` the first time. Approve
it. Do not pre-allowlist it — the prompt is worth having on screen:

> "It's asking me before it calls the tool. That's the protocol working: this is a tool call
> going out to my docs site, not the model rummaging in its memory."

**This takes about thirty seconds**, not the ~13 s of the search itself — the model reads the
results and writes the answer too. Measured end to end on 2026-09-07: **33 s**. That is a long
silence, so have something to say. Narrate while it runs:

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
> sentence in the YAML file you saw five minutes ago, it went into the site, into the Markdown,
> into `llms.txt`, and the MCP server just handed it back to me with a link. Nobody copied it.
> Nobody could forget to update it. That's the difference between generating four artifacts and
> maintaining them."

> "Now go back eighteen minutes. Same question, against the first portal: the agent gets
> fourteen hundred bytes and a 404, and answers 'nothing happens to the slot' — confidently,
> reasonably, and wrong. Not a crash. A wrong answer that looks right. That's the failure mode,
> and it is the expensive one."

> **Running long?** Cut the human browsing at the top of 7e — go straight to the endpoint page
> — and reduce the `llms.txt` beat to one sentence. Never cut the plant in 7a or the prompt in
> 7f; they are the two ends of the same thread and one without the other proves nothing.

---

### Act 8: The close (2 min) — slides 11–12

**Do:** advance to slide 11 — Discord.

> "Before I let you go — the Postman Community on Discord. Scan that. Come ask questions, show
> us what you're building, tell me if you try this on your own docs and it goes badly. I'd
> genuinely like to know."

**Do:** advance to slide 12.

> "So: your docs have two readers now. You do not have to choose between them, and you should
> not maintain four artifacts by hand to serve them both. Keep one spec somewhere real, and let
> the human site, the Markdown, the index, and the MCP server come out of it together — because
> that's the only version that can't drift."

> "Two commands to try it on your own spec, they're on the slide. Everything you saw is public.
> Questions?"

**Do:** leave slide 12 up for Q&A. **This is where the remaining ~4.5 minutes of the slot go.**

#### The questions you will get

**"Isn't `llms.txt` enough? Why do I need MCP too?"**

> "`llms.txt` is a map. MCP is a librarian. With `llms.txt` the agent still fetches pages,
> pulls them into context, and re-reads them every session. With MCP it asks a question and
> gets the relevant passage back, cited. Both, ideally: the index is what makes the MCP
> server's answers findable in the first place."

**"What stops the MCP server from hallucinating?"**

> "Nothing stops the *model* from hallucinating — but that answer had footnotes, and you can
> click them. The MCP server only returns passages from pages that exist on that site, and
> those pages were generated from the spec. It can be wrong the way a search engine can be
> wrong — it can miss something. It can't invent an endpoint I never wrote."

**"How does this fit into CI? You published from your laptop."**

> "Deliberately, because it's a twenty-five minute talk. Those three files next to the spec are
> the whole definition — commit them and run the same `fern generate --docs` from a GitHub
> Action with a `FERN_TOKEN` secret, and a push to the spec republishes everything. Nothing
> about what you just saw changes; only who runs the command."

**"Where should the spec actually live?"**

> "Wherever your team already works on it, as long as there is exactly one of it. Mine lives in
> a Postman workspace — that's where it gets edited, tested against the running service, and
> reviewed. Fern references it by repo and path rather than copying it, so 'where it lives' and
> 'what builds the docs' stay separate decisions."

**"Does it work with a private repo / private docs?"**

> "Fern supports authenticated docs sites, and the MCP server sits behind the same auth. That's
> a configuration question, not a different architecture."

**"How is this different from just publishing my OpenAPI file?"**

> "Publishing the spec gives an agent the contract. It doesn't give it your guides, your
> examples, your auth story, or a way to search any of it. Notice the answer you just saw came
> out of a *prose description*, not a path definition. That's the part a raw spec URL doesn't
> deliver."

**"Did you rig the spec?"**

> Show them. `openapi/appointments.openapi.yaml` is checked into this repo, the warning is in
> `info.description` *and* on the `patch` operation, and `setup.sh` asserts it is still there
> on every run.

---

## 5. The two things that break Act 7f

Both were hit on real runs. Neither is obvious, and one of them fails by *looking* like it
worked.

### 1. The agent must run in an empty folder

`$WORKDIR` contains `appointments.yaml`. Claude Code reads the files in its working directory,
so when the MCP server is slow or not yet indexed it takes the cheaper route. Observed live on
2026-09-07:

> *"The docs site isn't indexed yet, but the local OpenAPI spec has the answer. Let me read the
> relevant sections."*

It then produced the **correct answer from the wrong source** — which is the worst outcome
available, because it looks like the demo worked. The claim being demonstrated is that the fact
travelled spec → site → MCP; an agent opening the file next to it demonstrates none of that.

The escape hatch is the bug, not the index. `$AGENTDIR` holds nothing, so a slow or cold index
makes the agent wait, retry, or admit it cannot answer — all of which are honest and
recoverable in front of a room. `setup.sh` creates it and asserts it is empty.

### 2. MCP registrations are directory-scoped, and inherited

`claude mcp add` defaults to `--scope local`, which keys the registration to the directory it
was run in and stores it in `~/.claude.json` — **not** inside the folder. So:

- `teardown.sh` must unregister **before** deleting the folders. Reverse that order and the
  entry is orphaned, `setup.sh` recreates the path, the stale entry returns with it, and Act 7f
  opens with `claude mcp add` erroring on a duplicate name in front of the audience.
- Local scope is **inherited by subdirectories**. A registration made in `/private/tmp` is
  visible from every `/tmp/*` folder, `$AGENTDIR` included, so it silently makes "a genuine
  first-time connect" false forever. Found exactly that on 2026-09-08.

Both scripts therefore search `$AGENTDIR`, `$WORKDIR` and `/private/tmp`, and **match on the
MCP URL** so they catch the registration whatever name it was given.

---

## 6. Tear down / reset

```bash
./scripts/teardown.sh
```

| State the demo creates | What teardown does |
|---|---|
| The docs MCP registration | **Removed** (`claude mcp remove`), by URL, from `$AGENTDIR`, `$WORKDIR` and `/private/tmp` — **before** the folders go, see section 5 |
| `$WORKDIR` with `fern/`, `generators.yml`, `docs.yml` | **Removed** (setup recreates it with just the spec) |
| `$AGENTDIR` | **Removed** (setup recreates it empty) |
| A `python3 -m http.server` in front of `site/` | **Stopped** (by pid, then by port, so a hand-started one is caught too) |
| `.demo-state` (the server pid) and `/tmp/mcp-docs-portal.log` | Removed |
| `site/assets/spec-bundle.js` | **Kept** — setup rebuilds it every run. `--purge` deletes it. |
| **The published Fern site** | **Left alone, on purpose** — see below |
| GitHub, repos, commits, CI | None exist. The demo never touches git. |
| API calls, data, credentials | None exist. The spec is a document; the service is never called. The portal's "Try it" panel is mocked. |

**Why the site is not unpublished.** The published subdomain is what keeps the search index
warm, and Act 7f depends on it. Unpublishing between runs would hand every run the slow,
unreliable first-publish path. Republishing over a warm subdomain is what makes this talk safe
to give twice in a day. Teardown reports whether the site is still up and warns you if it is
not.

**Never delete the Fern organization to reset.** It is `postman-devrel`, it is shared with the
rest of DevRel, it also publishes the fallback site, and deleting it is exactly the thing that
broke this demo once.

**Between runs:** `./scripts/teardown.sh && ./scripts/setup.sh`. Three things you must do by
hand:

1. **Clear your Claude Code session** — a warm context already knows the Act 7f answer.
2. **Re-check Safari's Disable JavaScript** — it survives restarts but not every update.
3. **Reset the deck** to slide 1 and collapse any endpoints you expanded in the portal.

---

## 7. Troubleshooting

| Issue | Fix |
|---|---|
| **Safari renders the portal normally** | Disable JavaScript came back on. Develop → Disable JavaScript. If the Develop menu is gone: Settings → Advanced → *Show features for web developers*. Fallback: run the Act 0b `curl` first and say "fourteen hundred bytes is the whole page" — it lands almost as well. |
| **No hands go up in Act 0a** | Someone already knows where this is going. Roll with it: *"some of you have seen this coming — good, then you already know what I'm about to show you."* Then do 0b anyway; the visual still works. |
| **The deck won't load from claude.ai** | You're signed out, or offline. Fall back to `presentation/index.html` — arrows/space to advance, `f` fullscreen, `Home` for slide 1. Note it is the older 12-slide cut: same content and order, different slide count, so you will advance more often than the act headings suggest. |
| Port 4173 is already in use | `./scripts/teardown.sh` frees it, or `PORT=4180 ./scripts/setup.sh` — then use that URL in Act 0 **and in Safari**. |
| `setup.sh` fails on the spec bundle | It needs PyYAML: `python3 -m pip install pyyaml`. If pip is blocked, the checked-in `spec-bundle.js` still works — the build only matters if you edited `openapi/`. |
| Portal shows "Loading the API portal…" forever | `spec-bundle.js` failed to load. Hard-refresh (`Cmd+Shift+R`); if it persists, re-run `./scripts/build-spec-bundle.py`. |
| **`fern check` shows 5 errors about `starts_at` / `reason` / `duration_minutes`** | Expected if you ran it before Act 7c. They are `[sdk]` errors from the TypeScript generator `fern init` scaffolds — this spec's schemas are open (`additionalProperties`) so its request examples fail the SDK validator. Docs are unaffected. Do Act 7c's trim and check again; it passes. Recover on stage with: *"that's the SDK generator complaining — we're not generating SDKs today, watch."* |
| **`fern generate --docs` opens a browser** | You are not logged in. `Ctrl+C`, `fern login`, retry. `setup.sh` fails on this exact condition — it should never surprise you on stage. |
| **Publish fails: *"A valid API configuration was not found at fern/apis/..."*** | `docs.yml` has an `api-name:` line. Delete it. This project is single-API. |
| **Publish fails with `Failed to resolve organization` (HTTP 500)** | Your account belongs to no organization the CLI can resolve. Set `"organization": "postman-devrel"` in `fern.config.json` — leave `docs.yml`'s subdomain alone, they are independent. Diagnose with `fern org get`: *"No org-level CLI config set for X"* means X resolves and you are fine; **403** means no access. `setup.sh` runs this check for you. |
| **`fern org get` returns 403 for every name you try** | You are not a member of any organization — this is what deleting one does. Nothing in the CLI can recreate it; open <https://dashboard.buildwithfern.com> to see what the account has. Fall back to the `myhealthcare` site for Act 7f. |
| **You are tempted to delete the org to "start clean"** | Don't. See section 2. Republishing over the same subdomain is the reset. |
| **`fern init` says the project already exists** | You did not tear down, or you ran it twice. `./scripts/teardown.sh && ./scripts/setup.sh`. Never re-run `fern init` in a folder that has a `fern/` — it re-scaffolds and adds a second, imaginary API. |
| **The subdomain is taken** | Fern subdomains are globally unique across all customers. Pick another: `FERN_HANDLE=<something>-demo ./scripts/setup.sh`. |
| **`searchDocs` hangs or returns nothing in 7f** | The index is cold. Point at the warm site instead: `claude mcp add --transport http appointments-docs https://myhealthcare.docs.buildwithfern.com/_mcp/server`. Say what you are doing — same spec, same answer. Then do a rehearsal run before the next slot. |
| **The agent says *"the local OpenAPI spec has the answer, let me read that"*** | You are in `$WORKDIR`, not `$AGENTDIR`. Quit, `cd /tmp/appointments-agent`, re-add the server and re-ask. This is the failure that *looks* like success — call it out rather than letting it slide. See section 5. |
| **The agent answers 7f from memory, without calling the tool** | Warm context, or it recognised the platform. Say so out loud and re-ask with *"use the connected docs MCP server only, and cite the page"*. Clear the session next run. |
| **The 7f answer misses the footgun** | Re-ask narrowly: *"check the update endpoint page specifically — what events does PATCH publish?"* That is itself a fair demo: the citations are what let you verify and correct it. |
| **The agent says *"no server named appointments-docs is connected"*** | You registered it under a different name — the site's snippet gives `booth-demo-docs-buildwithfern-com`. Harmless: the Act 7f prompt names no server. If you are reading an older prompt, drop the name from it. |
| **`claude mcp add` says the server already exists** | You did not tear down, or it is registered in a *parent* directory. See section 5. `./scripts/teardown.sh` searches by URL across `$AGENTDIR`, `$WORKDIR` and `/private/tmp`. |
| **`/mcp` shows the server as failed** | Check the URL has no trailing slash and `--transport http` is present. Verify by hand: `curl -s https://booth-demo.docs.buildwithfern.com/_mcp/server` should return a `fern-docs-mcp-server` descriptor. |
| **The page URLs do not match what you expected** | This build is single-API, so pages sit at `/api-reference/appointments/update`. The `myhealthcare` fallback is multi-API and puts the same page at `/api-reference/healthcare-org/appointments-service/appointments/update`. Both are correct; the layout decides the path. Take URLs from `llms.txt` rather than typing them — and doing that on stage is an accidental demo of `llms.txt` doing its job. |
| No network at all | Act 0, Acts 1–6 and Acts 7a–7c still run — you can genuinely scaffold and `fern check` offline. For the rest, walk slide 9 and say the numbers: **1,402-byte shell; 780 KB of HTML becomes 9 KB of Markdown, ~90× smaller; `llms.txt` indexes every page; the MCP server answers in one call.** Do not fake a terminal. |

---

## 8. Additional resources

| Resource | Link |
|---|---|
| The deck (Claude design) | <https://claude.ai/design/p/34e5524b-4e2d-436a-97bc-9a59609fb288?file=MCP+Docs+Best+Friend.dc.html&via=share> |
| The deck (offline fallback, **12 slides — out of sync with the 7-slide deck of record**) | `presentation/index.html` — arrows/space, `f` fullscreen, `Home` for slide 1 |
| The "before" portal (this repo) | `site/` — served at <http://localhost:4173> |
| The spec the demo publishes | `openapi/appointments.openapi.yaml` (10 operations) |
| The other two specs, portal-only | `openapi/appointment-slots.openapi.yaml`, `openapi/prescriptions.openapi.yaml` |
| The Fern organization (permanent, shared) | `postman-devrel` · <https://dashboard.buildwithfern.com> |
| The site the demo publishes | <https://booth-demo.docs.buildwithfern.com> (`$FERN_HANDLE`) |
| Its MCP server | `https://booth-demo.docs.buildwithfern.com/_mcp/server` |
| **The payoff page** (single-API paths) | `https://booth-demo.docs.buildwithfern.com/api-reference/appointments/update` · append `.md` |
| Its `llms.txt` | `https://booth-demo.docs.buildwithfern.com/llms.txt` |
| The warm fallback site (**production — read-only**) | <https://myhealthcare.docs.buildwithfern.com> · [its `llms.txt`](https://myhealthcare.docs.buildwithfern.com/llms.txt) |
| The fallback's payoff page, as Markdown | <https://myhealthcare.docs.buildwithfern.com/api-reference/healthcare-org/appointments-service/appointments/update.md> |
| The app being documented | <https://myhealthcare.dev/> |
| The upstream service | <https://github.com/healthcare-org-app/healthcare-appointments> |
| A multi-API Fern config, for the namespace story | <https://github.com/avdev4j/myhealthcare-fern-doc> |
| Fern docs — AI features | <https://buildwithfern.com/learn/docs/ai-features/api-catalog> |
| Model Context Protocol | <https://modelcontextprotocol.io> |
| Fern | <https://buildwithfern.com> |
| Postman Discord (slide 11) | <https://discord.gg/postman> |
| Companion content — the full Fern product pitch | [`../../lightning-talks/fern`](../../lightning-talks/fern/) |

---

## 9. The 10-minute booth cut

Same folder, same scripts, same demo, same cold open. **The only thing that changes is that
there are no slides** — everything the deck would have said, you say out loud over whatever is
already on screen.

| | 25-minute slot | 10-minute booth cut |
|---|---|---|
| Act 0 — cold open | 2.5 min | **2.5 min — kept, and now it is the only visual** |
| Acts 1–6 — the argument | 8.5 min, on the deck | **1 min, spoken. No slides.** |
| Act 7 — the live build | 7.5 min | **6 min** (drop the browsing at the top of 7e, one sentence on `llms.txt`) |
| Act 8 — the close | 2 min, on the deck | **30 sec, spoken** |
| Q&A | ~4.5 min, inside the slot | rolling, at the booth |

### The argument, spoken (Act 1, ~1 min)

Three sentences. Say them over the Safari tab still showing "JavaScript is required" — the
thing on screen *is* the visual aid, which is why this works without a deck.

> "Your docs have two readers now. A human still skims, but an agent has to discover what
> exists, authenticate, parse the response, and recover when a call fails — on its own, with
> nobody there to squint at the page for it."

> "What that second reader needs is three things you almost certainly don't have: an
> `llms.txt` index at the root of your site, per-page Markdown so the content is cheap to
> parse, and an MCP server it can call instead of scraping you."

> "And nobody has time to write those by hand, or to keep four artifacts true at once. So
> we're not going to — watch."

Then straight into Act 7 in the terminal. That last line is the handoff; there is no slide to
click, so the transition is a sentence.

### The close, spoken (Act 3, ~30 sec)

> "One spec, four outputs, built together — which is the only version that can't drift. Two
> commands to try it on your own spec: `npm i -g fern-api`, then `fern init --openapi`. And
> the Postman Discord is the place to tell me if it goes badly on your docs."

Then talk to whoever stayed. At a booth that conversation is the point, not the applause.

### Setup for the booth cut

Run the same script — it opens the portal in Chrome and Safari, which Act 0 needs:

```bash
./scripts/setup.sh
```

It also opens the deck. **Close that tab**, or use `SKIP_OPEN=1` and open the two portal tabs
yourself. Everything else — the build folders, the WARM/COLD verdict, the preflight — matters
exactly as much here as it does in the 25-minute slot.

### Why no slides is the better booth format

A deck at a booth costs you the fullscreen fumble, a slide-advance rhythm nobody in a walking
crowd is following, and a screen that is not the terminal. Dropping it means someone joining
halfway through has missed **a sentence, not a section** — and the two things that actually
carry the talk, the Safari tab and the live build, are both already on screen.

**What is not negotiable at any length:** the warning gets planted in the spec before the build
(7a), and it comes back out of the MCP server with a citation (7f). Everything else is
staging.

---

## 10. Deliberately not in this talk

Tempting to add back, and each one costs more than it returns.

| Not here | Why |
|---|---|
| **The Postman desktop act** — the spec being authored and tested in the app | It only showed *where the spec lives*, and Act 7b makes that point structurally: Fern references the spec where it is, rather than copying it. Adds a whole application to the window-switching order. Keep the workspace open for Q&A and answer *"where should the spec live?"* out loud instead. |
| **Three services, the multi-API layout, and the `/health` namespace-collision war story** | Requires `fern/apis/<name>/generators.yml` and an `api-name` in `docs.yml` — the opposite of what `fern init --openapi` scaffolds, and the opposite of what this build shows. Excellent content; it is a different talk. The portal still shows all three, which is what the Act 7a bridge sentence is for. |
| **Git and GitHub entirely** — an empty repo, a first push, a GitHub Action | Fern needs no repository to publish, so carrying one buys an act, an account to be logged into, a prerequisite to reset between runs, and a `git push` that can fail on stage. All to gesture at CI, which one sentence in 7d and one Q&A answer do just as well. `setup.sh` proves the point every run by scaffolding in a folder that is not a repo. |
| **A second, discovery-first prompt in 7f** | Two `searchDocs` calls is two cold-start risks. One prompt that needs both discovery *and* the footgun does the same work in half the silence. |
| **Walking an already-published docs site instead of building one** | It was the original shape of this talk. Building is faster, it makes the "referenced, not copied" property visible rather than asserted, and it removes the question of whether anything was prepared earlier. |

---

## 11. How the "before" portal is built

Worth knowing, because an attendee will ask whether you rigged it.

`site/` is a hand-built single-page app: `index.html` is a 1,402-byte shell containing an empty
`<div id="root">` and a `<noscript>` block, and `assets/portal.js` constructs the entire portal
— overview, platform notes, every operation, every schema — at runtime from the three OpenAPI
files. It renders **27** operations, where a Fern build of the same three specs produces **24**:
the specs declare three `PUT` aliases that Fern collapses into their `PATCH` twin and the portal
does not. This talk publishes only the appointments service — **10 operations** — so the number
to say on stage is ten.

The look is the API-explorer convention everyone recognises (method pills, collapsible operation
rows, parameter tables, a try-it panel), rebranded blue and carrying no third-party name or
code.

Every property that makes it hostile to agents is a real property, and each one is common in the
wild:

| Property | How it's done | Why it's realistic |
|---|---|---|
| Content is invisible in the source | Client-rendered into an empty div | Every SPA docs portal behaves this way |
| No `llms.txt` | The file does not exist | It did not exist as a convention when most portals were built |
| No per-page Markdown | There are no per-page URLs at all — routing is `#`-fragments | Hash routing was standard for years |
| No fetchable spec | `scripts/build-spec-bundle.py` compiles `openapi/*.yaml` to base64 inside `assets/spec-bundle.js`; nothing is served as `.yaml` or `.json` | Bundlers inline data by default; publishing the raw spec is an extra, deliberate step |
| No MCP server | There isn't one | Same as almost every portal today |
| `robots.txt` disallows everything | `site/robots.txt` | Plenty of vendors block AI crawlers on purpose |

`setup.sh` asserts the first four every run, so the demo cannot quietly rot. The "Try it" panel
synthesises responses from the specs' own examples and never opens a socket — which is why the
cold open needs nothing running and leaves nothing behind.

The `<noscript>` block is the one concession to stagecraft, and it is an honest one: without it,
Safari shows a blank white page, which reads as "the demo broke" rather than "the content is not
there." The message it displays — *"JavaScript is required"* — is what a real portal in this
position would say.
