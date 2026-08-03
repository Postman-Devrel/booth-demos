# Agent-Ready Docs — Grade Your API Documentation

> Booth demo — target length **10 minutes**. This README is the single source of truth.
> Read it top to bottom before your first attendee; everything you need to run the demo
> without improvising is here.

---

## 1. Product summary

**Product:** Fern

**Use case:** Show that docs built for humans are half-invisible to agents, grade any docs
site live with a one-file audit script, and prove the difference by letting Claude Code
query a Fern-generated MCP server instead of crawling HTML.

**The story (the narrative arc):**

> Your API docs have a second reader now, and it is not a person. Most teams have
> noticed — thirteen of the fifteen most popular API docs on the internet now ship an
> `llms.txt`. But that is the easy half. Almost nobody serves clean markdown, publishes a
> discoverable spec, or exposes an MCP server, because those things require a real source
> of truth rather than a file you can hand-write once. So the median docs site scores a
> **C**: modern on the surface, still un-queryable underneath. Fern generates all four
> layers from the same spec that generates your SDKs, which is why a Fern site scores an A
> without anyone on that team having tried to.

**CTA:**
- Grade your own docs — `./scripts/agent-audit.sh yourdomain.com`
- Fern — <https://buildwithfern.com>
- Grab the demo — `git clone https://github.com/Postman-Devrel/booth-demos.git`

**Total time: ~10 minutes.** Acts 1–4 are the **core (~7 min)** and stand alone — at a
booth you will get interrupted. Acts 5–6 are the extension for a captive attendee.

---

## 2. Pre-requisites

| Requirement | How to get it |
|---|---|
| macOS or Linux with `bash`, `curl`, `awk` | Pre-installed. The audit script targets bash 3.2, so stock macOS is fine. |
| Claude Code | <https://code.claude.com/docs> — needed for Act 4 only |
| Node.js 18+ | <https://nodejs.org> — only for the offline MCP fallback |
| `jq` *(optional)* | `brew install jq` — makes Act 5's `api-catalog` output readable |
| Network *(optional)* | Every act has an offline path. See §5. |

No API keys. No accounts. No cloud state. Nothing to clean up remotely.

---

## 3. Setup

```bash
cd demos/agent-ready-docs
./scripts/setup.sh
```

`setup.sh` will:

1. Verify `curl`, `awk`, `sed`, `claude`, and (optionally) `node` and `jq`.
2. **Detect online vs offline and print the mode in a banner** — the demo branches here.
3. Record or refresh `fixtures/` if the baseline is missing or more than a day old.
4. Warn if your terminal is under 84 columns (the scorecard is a fixed 76).
5. **Dry-run Act 2** — confirms the anchor site still scores an A.
6. **Dry-run Act 4 headlessly** — asks the real question against the real MCP server and
   checks the answer contains `300`. You find out about a broken act at setup, not on stage.
7. Print the exact command you will type in Act 4.
8. Open the presentation.

### Authentication

None. The audit script is unauthenticated `curl` against public endpoints. Claude Code
uses whatever login you already have.

### Pre-demo checklist

- [ ] `setup.sh` banner said **ONLINE** (or you have rehearsed the OFFLINE wording)
- [ ] Terminal is **84+ columns** and the font is readable from 6 feet (`Cmd+=`)
- [ ] Act 2 dry run scored an **A**
- [ ] Act 4 dry run said **PASSED**
- [ ] You know the peer median to quote — `setup.sh` prints it (currently **C, 55**)
- [ ] Presentation open on the booth monitor, slide 1
- [ ] Second browser tab ready on <https://elevenlabs.io/docs/eleven-agents/guides/burst-pricing>
- [ ] **You will ask consent before typing an attendee's domain in Act 3**

---

## 4. Talk track and click track

Six acts, ~10 minutes. Talk track is **verbatim** (blockquotes) — read it if you need to.
Click track is interleaved at the exact point each action happens. **Never skip the
payoff** — if a step produces an artifact, show the artifact.

---

### Act 1: The second reader (1.5 min)

**Show:** presentation, slide 1.

> "Quick question before I show you anything. When you write API docs — who are you
> writing them for?"

*(let them answer — it is almost always "developers")*

> "Right. That was true until about a year ago. Let me show you the other reader."

**Do:** in the terminal, run one command:

```bash
curl -sI https://elevenlabs.io/docs/api-reference/text-to-speech/convert | grep -i content-length
```

**Show (payoff):** `content-length: 1388460`

> "One page. One API reference page — text-to-speech convert. One-point-four megabytes of
> HTML. Claude's context window is two hundred thousand tokens. That page is roughly four
> hundred thousand. So a single page of your documentation does not fit in the context
> window — and an agent has to read it before it can write a single line against your API."

**Do:** advance to slide 2 (The Problem).

> "Nav, CSS, a React bundle, analytics — all of it billed to the context window before the
> agent reaches the endpoint description. The human web actively fights machines."

---

### Act 2: The scorecard (2 min)

> "So I wrote a script that measures this. Ten curl requests, no account, no crawl. It
> checks four things: can an agent discover your pages, can it read one without parsing a
> JavaScript app, can it find your spec, and can it just ask you a question. Four layers.
> Let's point it at a site that did all four."

**Do:**

```bash
./scripts/agent-audit.sh https://elevenlabs.io/docs
```

**Show (payoff):** the scorecard builds line by line and lands on **A, 90/100**.

> "ElevenLabs. Ninety out of a hundred. And notice the one it fails — their OpenAPI spec is
> behind auth, so it loses ten points. I left that in on purpose. A scorecard that gives a
> Fern customer a perfect score is a scorecard nobody believes."

**Do:** point at the payload block at the bottom of the card.

> "And here is the part that changed how I think about documentation. Same page. One-point-four
> megabytes of HTML. The markdown version of that exact page: nineteen thousand six hundred
> bytes. Ninety-eight point six percent smaller."

**Show (payoff):** prove it live — this is the moment people reach for their phones.

```bash
curl -s https://elevenlabs.io/docs/api-reference/text-to-speech/convert.md | wc -c
```

> "Dot-M-D on the end of the URL. That is the entire trick. Same content, same page,
> one-seventieth the size. And before anyone asks — no, gzip does not save you. Compression
> helps the wire. The model reads it decompressed."

---

### Act 3: Now yours (1.5 min)

> **Ask first, every time:** "Do you have public API docs? Want me to run this on them?"

If they hesitate, **do not push**. Offer instead: *"Want me to run it on a competitor?"* or
just move to Act 4.

**Do:** type their domain live. Talk while it runs — do not watch the screen.

```bash
./scripts/agent-audit.sh docs.theircompany.com
```

**Show (payoff):** the grade lands, and immediately point one line below it.

> "Now — before that number lands wrong. Look at the line under the grade. That is the
> median across fifteen of the most popular API docs on the internet — Stripe, GitHub,
> Twilio, Cloudflare, OpenAI. The median is a **C**. Your docs are excellent. They are
> excellent *for humans*. There is a second audience now and almost nobody has finished
> building for it."

**Do:** point at the `llms.txt` row, then at the MCP row.

> "Here is the interesting pattern. Thirteen of those fifteen sites have an llms-dot-txt —
> that part everybody did, because you can hand-write it in an afternoon. Three of fifteen
> have an MCP server. Two of fifteen have a discoverable spec. That is the split: the easy
> half got done everywhere, and the half that needs a real source of truth got done almost
> nowhere."

**Show:** the **TOP 3 WINS** footer.

> "So the card doesn't end with a list of failures. It ends with the three highest-value
> things you could ship, in order."

**If they score an A** *(it happens — Notion scores 100, Anthropic 90)*:

> "You're in the top few percent — you clearly already believe this. So the better question
> is the one the scorecard can't see: is your SDK generated from that same spec, or is
> somebody maintaining it by hand alongside it?"

---

### Act 4: The consequence (2.5 min)

> "Byte counts are an argument. Here's the proof. One line."

**Do:** type it visibly.

```bash
claude mcp add --transport http -s project elevenlabs-docs https://elevenlabs.io/docs/_mcp/server
```

> "Dash-S project — that writes a dot-M-C-P-dot-json right here in this folder, not into my
> global config. I can delete it after. And that server is not something the ElevenLabs team
> built. Fern generates and hosts one for every docs site."

**Show (payoff):** `cat .mcp.json` — four lines.

**Do:** launch isolated.

```bash
claude --strict-mcp-config --mcp-config .mcp.json \
       --allowedTools "mcp__elevenlabs-docs__searchDocs"
```

> "Strict config — only that one server loads, so you're seeing exactly what I just added
> and nothing else."

**Do:** paste the question (also printed by `setup.sh`).

```
Using the elevenlabs-docs MCP server: if my ElevenLabs workspace has a subscription
concurrency limit of 200 calls and I turn on burst pricing, what is my maximum number
of concurrent calls, what rate are the burst calls charged at, and what is the hard cap
for non-enterprise customers? Cite the documentation URL you used.
```

> "This is a trap question. Burst pricing gives you three times your limit — so three times
> two hundred is six hundred. That's the answer a model guesses. The real answer is in the
> docs."

**Show (payoff):** the `searchDocs` call fires, then the answer.

**Ground truth** — verify against this without leaving the terminal:

| | |
|---|---|
| Maximum concurrent calls | **300**, not 600 — non-enterprise burst is capped |
| Burst call rate | **2×** the standard rate |
| Hard cap | **300** for non-enterprise |
| Source | <https://elevenlabs.io/docs/eleven-agents/guides/burst-pricing> |

> "Three hundred. Not six hundred — because there's a cap the model could only know by
> reading the page. With the source URL."

**Do:** open the cited page in the second browser tab, side by side.

> "Correct. And notice what did *not* happen. No crawler. No scraping job. No vector
> database I have to keep in sync. No RAG pipeline. The docs answered the question. That is
> the difference between docs an agent *can* read and docs an agent can *query*."

---

### Act 5: The source (1.5 min) — *extension*

> "So where does all of that come from? It's one file."

**Do:**

```bash
curl -s https://docs.cohere.com/.well-known/api-catalog | jq .
```

*(Cohere, not ElevenLabs — ElevenLabs' catalog is empty, which is exactly why they scored 90.)*

**Show (payoff):** the RFC 9727 linkset pointing at `openapi/cohere-api.yaml`.

> "That's a standard — RFC nine-seven-two-seven. An agent asks 'where is your API contract'
> and gets a machine-readable answer instead of a search box."

**Show:** `assets/one-spec.md` full-screen, or slide 3.

**Show (payoff — the real artifact):** open <https://github.com/elevenlabs/elevenlabs-js>
and point at the badge: **🌿 SDK generated by Fern**.

> "Real SDK. On npm, version two-point-six-oh. A million downloads a week. Generated from
> the same spec as the docs, the llms-dot-txt and the MCP server — so none of them can drift,
> because there's only one source."

---

### Act 6: The close (45 sec)

**Show:** slide 5.

> "One sentence to take away: developer-friendly and agent-friendly are the same problem
> now. Everything you'd do to stop a human getting lost in your docs is the same work that
> stops an agent guessing."

**Do:** hand them the script.

```bash
git clone https://github.com/Postman-Devrel/booth-demos
cd booth-demos/demos/agent-ready-docs
./scripts/agent-audit.sh yourdomain.com
```

> "That's one bash file, no dependencies, and it only checks open standards — llms-dot-txt,
> OpenAPI, RFC nine-seven-two-seven, MCP. Nothing Fern-specific. Take it, run it on your
> docs on the plane home, and run it on your closest competitor. If you want the green
> column instead of the red one, that's buildwithfern.com."

---

## 5. Tear down / reset

```bash
./scripts/teardown.sh
```

Removes `./.mcp.json` (the project-scoped server you added on stage), removes any dry-run
configs, and **verifies your global MCP config is still clean**. Fixtures are deliberately
kept — they take a minute to rebuild and they are what makes the demo survive dead wifi.

**Full reset between demo days:**

```bash
./scripts/teardown.sh && ./scripts/refresh-fixtures.sh && ./scripts/setup.sh
```

There is no cloud state. Nothing to delete in a dashboard.

### Running offline

Run `./scripts/refresh-fixtures.sh` on hotel wifi each morning. Then:

| Act | Offline behavior |
|---|---|
| 1 | Uses the cached byte count. Say "recorded this morning." |
| 2 | `--offline` replays a real recorded audit. Banner turns amber, rows get a `⟲`. |
| 3 | An attendee's arbitrary domain **cannot** be faked. Say so, then replay a cached peer site. |
| 4 | `claude mcp add -s project <name> -- node scripts/offline-docs-mcp.js` — a **real** MCP handshake and a real `searchDocs` call against the cached corpus. |
| 5 | Entirely local files. No change. |

**The banner never lies.** `● LIVE` means live; `◈ CACHED` means cached. A booth demo
caught faking data is unrecoverable — say "this is a snapshot" out loud and lose nothing.

---

## 6. Troubleshooting

| Issue | Fix |
|---|---|
| Scorecard box art wraps | Terminal under 84 columns. `Cmd+-` to shrink the font. |
| Anchor site no longer scores an A | Switch `FERN_SITE` in `demo.conf` to `https://docs.cohere.com` (scores 100). |
| Attendee's site scores an F | Check the `base:` line first — their docs may live at `/docs`. Re-run with the full path. Recovering gracefully looks better than being right. |
| `SITE BLOCKS AUTOMATED REQUESTS` | Their WAF blocked us. Pivot: *"that's itself a finding — agents get blocked the same way."* |
| Grade shows `?` | The site returns 200 for every path, so presence can't be distinguished from absence. Say that; do not read it as a failing grade. |
| Act 4 returns 600 instead of 300 | The model guessed instead of reading. Say so — it's the point of the trap — then open the docs page. |
| Act 4 shows a wall of unrelated MCP servers | You dropped `--strict-mcp-config`. It is not optional. |
| `claude mcp add` polluted the global config | You omitted `-s project`. Fix: `claude mcp remove elevenlabs-docs`. |
| Audit hangs | Every request has a hard timeout; the whole audit is capped by `BUDGET` in `demo.conf`. `Ctrl-C` is always safe. |
| Wifi died mid-demo | `./scripts/agent-audit.sh <site> --offline`. Announce it. |

---

## 7. Additional resources

| Resource | Link |
|---|---|
| Fern | <https://buildwithfern.com> |
| A real Fern portal | <https://elevenlabs.io/docs> |
| Fern-generated SDK (TypeScript) | <https://github.com/elevenlabs/elevenlabs-js> |
| The Act 4 source page | <https://elevenlabs.io/docs/eleven-agents/guides/burst-pricing> |
| RFC 9727 — API catalog | <https://www.rfc-editor.org/rfc/rfc9727.html> |
| llms.txt proposal | <https://llmstxt.org> |
| Model Context Protocol | <https://modelcontextprotocol.io> |

---

## Customizing this demo

Everything lives in **`demo.conf`**. Retargeting to a specific customer means editing four values:

| Knob | What it does |
|---|---|
| `FERN_SITE` | The all-green anchor audited in Act 2 |
| `AUDIT_PAGE` | The page used for the byte diff — **pin it** so the number is identical every run |
| `MCP_NAME` / `MCP_URL` | The docs MCP server connected in Act 4 |
| `DEMO_QUESTION` / `DEMO_EXPECT` | The Act 4 question and the string `setup.sh` checks for |

`fixtures/baseline-sites.txt` controls which sites the peer median is computed from — edit
it and re-run `./scripts/refresh-fixtures.sh`.

### How the score works

| Layer | Check | Points |
|---|---|---:|
| Discovery | `robots.txt` · `sitemap.xml` · `llms.txt` | 10 · 15 · 15 |
| Content | `<page>.md` · `Accept: text/markdown` | 25 · 5 |
| Contract | OpenAPI **or** a populated `.well-known/api-catalog` | 10 |
| Interface | docs MCP server | 20 |

**A** 85+ · **B** 70–84 · **C** 50–69 · **D** 25–49 · **F** <25

`llms-full.txt` and `api-catalog` show as unscored bonus rows. `llms-full.txt` is *not*
scored on purpose: Cohere serves a 662-byte stub there and ElevenLabs serves a byte-identical
copy of `llms.txt`, so scoring it would fail a Fern site for no analytical gain.

Byte counts are exact. Token counts are a chars-per-token estimate (±15%) and are always
prefixed with `~` — if someone challenges them, agree and point at the byte count.
