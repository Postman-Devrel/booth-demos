# Fern Overview — One Spec, Your Entire Developer Experience

A product-agnostic, 10-minute Fern overview. No live coding, no API keys, no network
dependency beyond two browser tabs. This is the deck you give at a booth, a meetup,
or the top of a customer call before you demo anything.

Adapted from the 2026-06-04 *Postman & Fern: Use Cases that Shine* tech talk, with the
co-marketing and commercial slides removed so it stands alone as a Fern product overview.

---

## 1. Product summary

**Product:** Fern

**Use case:** Give any audience a tour of Fern — why agents changed who reads your API,
and how one OpenAPI spec plus your MDX guides becomes SDKs, a branded developer portal,
and agent-ready infrastructure that never drifts.

**Story (the arc):** APIs used to be read by developers. Now they are read by agents,
and agents fail on the two things almost every API gets wrong — docs a machine cannot
parse, and SDKs that drift from the spec. Fern collapses both into one pipeline: you
maintain a spec and your guides, and Fern generates the SDKs, the portal, and the
agent surface (`llms.txt`, per-page `.md`, a hosted MCP server) on every build. Then
you point at ElevenLabs, running 1M SDK downloads a week on exactly that pipeline, and
close on buy-vs-build.

**CTA:**
- See it live — <https://buildwithfern.com>
- A real Fern portal in production — <https://elevenlabs.io/docs>

---

## 2. Pre-requisites

| Requirement | How to get it |
| --- | --- |
| A modern browser | Chrome, Safari, Arc, or Firefox. Any version from the last two years. |
| `bash` | Preinstalled on macOS and Linux. On Windows use WSL or Git Bash. |
| A second browser tab on <https://elevenlabs.io/docs> | Open it before you start. Used as the live proof point in Act 5. |
| Presenter display set to mirror | Booth monitors are usually mirrored — check before the first attendee. The deck is full-viewport with no speaker notes pane. |
| *(Optional)* Offline copy of the ElevenLabs docs page | If booth wifi is unreliable, screenshot `elevenlabs.io/docs` and `elevenlabs.io/docs/llms.txt` in advance. See Troubleshooting. |

No accounts, no API keys, no CLI installs. That is deliberate — this demo must survive a
dead network.

---

## 3. Setup

```bash
cd demos/fern-overview
./scripts/setup.sh
```

`setup.sh` does exactly four things:

1. Verifies `presentation/index.html` exists and is non-empty.
2. Checks that the machine has a usable browser opener (`open` on macOS, `xdg-open` on Linux).
3. Optionally probes `https://elevenlabs.io/docs` and warns you — without failing — if the
   network is down, so you know to fall back to screenshots before you are on stage.
4. Opens the presentation full-screen in your default browser.

### Authentication

None. Nothing in this demo authenticates against anything.

### Pre-demo checklist

- [ ] `./scripts/setup.sh` ran clean and the deck opened on slide 1 of 10.
- [ ] Browser is in full-screen / presentation mode (`Cmd+Ctrl+F` on macOS Chrome).
- [ ] Arrow keys advance slides — press right once, then left once, and confirm.
- [ ] A second tab is open on <https://elevenlabs.io/docs> and already scrolled to an API reference page.
- [ ] A third tab is open on that same page with `.md` appended — you will show the contrast in Act 5.
- [ ] Display is mirrored, brightness up, notifications silenced.
- [ ] You can say the numbers on slide 2 out loud without reading them: **74%**, **2,650**, **33% by 2028, up from 1%**.

---

## 4. Talk track and click track

Ten slides, ~10 minutes. Arrow-right advances; nothing auto-advances. The talk track
below is written to be read verbatim if you need it.

### Act 1: The hook (0:45) — slide 1

**Show:** Slide 1, the title slide.

> "Everything I'm going to show you comes down to one sentence: you maintain one spec, and
> Fern generates the rest of your developer experience. SDKs, your docs site, and — this is
> the part that's new — the version of your docs that machines read. Ten minutes."

**Do:** Do not advance yet. Let the title sit for a beat.

---

### Act 2: The shift (1:30) — slide 2

**Do:** Arrow right.

**Show:** Slide 2 — the two stats and the before/after panels.

> "Seventy-four percent of organizations are already API-first, averaging about 2,650 APIs
> per app. That part isn't new. What's new is the right-hand number: Gartner says a third of
> enterprise software will have agentic AI in it by 2028. In 2024 that was one percent."

**Do:** Point at the **Before** panel, then the **Now** panel.

> "Before, a human read your docs, wrote the integration, and debugged the response by eye.
> Now something has to discover the endpoint, authenticate, build the request, parse the
> response, and recover from its own errors — with no human in the loop. Your API has a
> second audience, and almost nobody has shipped for it."

---

### Act 3: How agents actually call you (1:00) — slide 3

**Do:** Arrow right.

**Show:** Slide 3 — the four patterns.

> "There are four ways this happens in practice. Direct REST calls built from your docs.
> Function calling, where the model picks a tool definition. MCP, which is a standard
> discovery layer. And generated CLIs, where every endpoint becomes something an agent can
> run in a shell."

**Do:** Sweep a hand across all four cards.

> "The important thing isn't the four patterns. It's that all four read from the same two
> artifacts — your documentation and your spec. If either one is unreliable, all four break
> in the same way."

---

### Act 4: The gap (1:15) — slide 4

**Do:** Arrow right.

**Show:** Slide 4 — Discovery and Reliability.

> "So what breaks? Two things, and neither is exotic. First, discovery: your docs aren't
> built for machines. Nav menus, JavaScript, CSS — an agent burns its token budget before it
> ever reaches an endpoint description. And there's no standard answer to 'what APIs exist
> here and what do they do.'"

> "Second, reliability: hand-written SDKs drift from the spec. Different error handling in
> every language, breaking changes an agent can't recover from. Bad docs in, wrong code out —
> and the agent fails silently, which is worse than failing loudly."

---

### Act 5: Enter Fern + the live proof (2:30) — slides 5, 6, 7

**Do:** Arrow right to slide 5.

**Show:** Slide 5 — the pipeline: source of truth → Output A, Output B.

> "Here's the whole product on one slide. On the left, what you maintain: your OpenAPI spec
> and your MDX guides. On the right, two outputs. Output A is idiomatic, type-safe SDKs —
> auth, retries, and pagination already in them. Output B is a full developer portal — not
> just an API reference, the whole site, on your domain, in your design system."

**Do:** Arrow right to slide 6.

**Show:** Slide 6 — the ten-tile portal grid.

> "This is what's actually in the portal. Guides, reference, an interactive playground,
> search and AI chat, changelogs and versioning, auth for private and partner docs,
> analytics. And the two green tiles — those are the agent tiles, and they're the ones I
> want to spend real time on."

**Do:** Arrow right to slide 7.

**Show:** Slide 7 — llms.txt, llms-full.txt, `<any-page>.md`.

> "Three surfaces, all generated. `llms.txt` is a markdown index of every page — one fetch
> tells an agent what exists. `llms-full.txt` embeds the content, so an agent parses the
> whole portal without crawling it. And any page in your docs, with `.md` on the end, gives
> you the same page with the chrome stripped out."

**Do:** **Payoff — switch to the browser.** Go to the `elevenlabs.io/docs` tab. Then switch
to the tab with the same URL plus `.md`.

> "This is a real Fern site, live right now. Same page. Left, that's a megabyte-plus of HTML
> that will not fit in a context window. Right, that's the same content as markdown. Nobody
> at ElevenLabs hand-wrote that second one — it's generated on every docs build, which is why
> it can't go stale."

**Do:** Switch back to the deck.

---

### Act 6: SDKs as agent infrastructure (1:15) — slide 8

**Do:** Arrow right.

**Show:** Slide 8 — the two columns.

> "The other half is the SDKs, and I'd frame those as agent infrastructure rather than a
> developer convenience. Agents need deterministic interfaces, predictable response shapes,
> and parity — a Python agent and a TypeScript agent should behave identically."

> "The line that matters is the last one on the left: auth, retries, and pagination should be
> handled by the SDK, not improvised by the model in a prompt. On the right, that's what Fern
> generates — with your custom business logic layered alongside the generated code, not
> forked from it. Spec change becomes a PR becomes a published release, automatically."

---

### Act 7: Proof in production (1:30) — slide 9

**Do:** Arrow right.

**Show:** Slide 9 — ElevenLabs.

> "That's the pitch. Here's it running at scale. ElevenLabs: a million SDK downloads a week,
> a million and a half docs users a month. Their SDKs needed thousands of changes a week to
> keep up with new endpoints — that's not a problem you solve by hiring."

**Do:** Point at the middle card.

> "The part that surprises people is this one: their DX team works in the CLI and GitHub,
> their Support team works in a browser editor, and it's the same git-backed repo. Two very
> different workflows, no fork."

**Do:** Point at the quote.

> "And this is from their DX lead, who used to work at Stripe: 'I know how much effort goes
> into it. It's one of those things that I'm very happy to buy, not build.'"

---

### Act 8: Close (1:15) — slide 10

**Do:** Arrow right.

**Show:** Slide 10 — three takeaways and the URL.

> "Three things to leave with. One: agents are now the fastest-growing consumer of your API,
> and they need machine-readable docs and type-safe SDKs to work at all. Two: one spec gets
> you all of it — SDKs, the portal, `llms.txt`, per-page markdown, an MCP server — from a
> single source of truth. Three: the honest gating question is whether getting your own
> generator to parity costs less than buying this. For the teams that have actually run that
> number, it doesn't."

**Do:** Leave slide 10 up. It has the URL on it.

> "buildwithfern.com. And if you want to see a production Fern portal before you talk to
> anyone — elevenlabs.io/docs. Try the `.md` trick on any page while you're there."

---

## 5. Tear down / reset

```bash
./scripts/teardown.sh
```

`teardown.sh` removes the `.demo-state` marker written by setup so the next run starts
clean. There is no cloud state, no generated artifact, and no account to clean up —
this demo is intentionally stateless.

**Manual steps:** close the extra browser tabs (`elevenlabs.io/docs` and the `.md` one) so
the next presenter opens them fresh.

**Full reset between demo days:**

```bash
./scripts/teardown.sh && ./scripts/setup.sh
```

---

## 6. Troubleshooting

| Issue | Fix |
| --- | --- |
| Booth wifi is dead and the Act 5 payoff needs a live page | Skip the browser switch entirely. The slides carry the point on their own — say "append `.md` to any page on a Fern site" and move on. Better: screenshot both pages the night before and keep them in a folder on the desktop. |
| Slides don't advance with arrow keys | Click once anywhere on the slide to give the page focus, then try again. Clicking the right half of the screen also advances. |
| Deck opens but looks cramped or text is clipped | Put the browser in full-screen (`Cmd+Ctrl+F` on macOS Chrome). The layout is sized for a 16:9 viewport; a windowed browser with bookmarks and tabs showing loses vertical space. |
| `setup.sh` says it can't find a browser opener | Open `presentation/index.html` by double-clicking it in Finder / your file manager. The script's only job at that point is already done. |
| Someone asks about pricing or contract sizes | Not in this deck on purpose — it's a product overview. Take the question offline and hand them to the right person. |
| Someone asks "how is this different from Postman?" | Postman is where you design and test APIs internally. Fern is the branded portal and SDKs your *customers* use to integrate. Design and test in Postman, publish through Fern. |
| Someone asks which languages | Point at the chips on slide 5: Python, TypeScript, Java, Go, C#, Ruby, PHP, Rust. Don't quote a count — the list is what matters. |

---

## 7. Additional resources

| Resource | Link |
| --- | --- |
| Fern | <https://buildwithfern.com> |
| Fern documentation | <https://buildwithfern.com/learn> |
| ElevenLabs docs (a production Fern portal) | <https://elevenlabs.io/docs> |
| The same page, as markdown | <https://elevenlabs.io/docs/llms.txt> |
| llms.txt specification | <https://llmstxt.org> |
| Model Context Protocol | <https://modelcontextprotocol.io> |
| Postman State of the API Report | <https://www.postman.com/state-of-api/> |
| Related demo — grade any docs site for agent-readiness | [`../agent-ready-docs`](../agent-ready-docs) |
| Source deck this was adapted from | `Postman & Fern: Use Cases that Shine`, 2026-06-04 |
