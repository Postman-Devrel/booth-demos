# Claude Code + Postman Booth Demo

A repeatable ~10 minute tradeshow booth demo showcasing the [Postman Plugin for Claude Code](https://github.com/Postman-Devrel/postman-claude-code-plugin). Uses the real [Postman Liftoff Content API](https://www.postman.com/liftoff/api/content) as demo content.

**The story:** Your APIs aren't ready for AI agents. The Postman Claude Code plugin takes you from bare endpoints to an AI- and production-ready API — spec generation, Postman sync, mock servers, security audit, and agent readiness scoring — all through natural language, using tools developers already love.

## Product summary

- **Product:** Postman Claude Code Plugin
- **Use case:** Help developers turn their APIs into AI- and production-ready services using natural language in Claude Code.
- **Duration:** 10m
- **CTA:** Claude Code Plugin install command and the [Building with AI learning path](https://www.postman.com/liftoff/learning-paths/building-with-ai/)

## Pre-requisites

| Requirement | How to get it |
|---|---|
| **Claude Code** v1.0.33+ | [claude.ai/code](https://claude.ai/code) |
| **Postman account** | [postman.com/signup](https://www.postman.com/signup) — free tier works |
| **Postman API Key** | [Settings > API Keys](https://go.postman.co/settings/me/api-keys) — generate a key named "Claude Code" |
| **Postman Claude Code Plugin** | `claude plugin install github:Postman-Devrel/postman-claude-code-plugin` |

### Postman workspace setup

Create a dedicated workspace for the demo so cleanup is easy:

1. Go to [postman.com](https://www.postman.com)
2. Create a new **Personal** workspace named "Liftoff Booth Demo"
3. Note the workspace ID from the URL (you'll select it during setup)

## Setup

Run the setup script before each demo session:

```bash
./scripts/setup.sh
```

The script checks:
- Claude Code CLI is installed
- Postman plugin is installed (installs if missing) and updated to the latest version
- `POSTMAN_API_KEY` is set
- `sample-api/` is clean (no leftover spec from a prior run)
- Presentation file is in place and opened in browser

### Authentication

**Option A: API Key (recommended for demos — no browser needed)**
```bash
export POSTMAN_API_KEY=PMAK-your-key-here
```
Add to `~/.zshrc` or `~/.bashrc` to persist across terminal sessions.

**Option B: OAuth (interactive)**
1. Run `/postman:setup` in Claude Code
2. A browser window opens for Postman sign-in
3. After auth, paste the callback URL back into Claude Code

### Pre-demo checklist

- [ ] Terminal open in this directory with Claude Code running
- [ ] Font size large enough for booth audience (Cmd+= to increase)
- [ ] Presentation open on booth monitor (`presentation/index.html`)
- [ ] Postman workspace is clean (no leftover collections from prior runs)
- [ ] No `openapi.yaml` in `sample-api/` (teardown removes it; the demo generates it live)

---

## Talk Track & Click Track

**Total time: ~10 minutes**

The demo story: "AI agents are the new consumers of your APIs. But most APIs aren't ready — no spec, no structured errors, no discoverability. The Postman Claude Code plugin makes your APIs AI- and production-ready, all through natural language in tools you already use."

---

### Act 1: The Problem (1 min)

#### Talk Track

> "AI agents are going to call your APIs. Not humans clicking buttons — autonomous agents that need to discover endpoints, understand schemas, handle errors, and recover from failures. The question is: are your APIs ready for that?"

> "Most aren't. And the first reason is simple — most APIs don't even have a spec. Without a spec, an AI agent can't discover what your API does. Let me show you how the Postman plugin for Claude Code fixes that."

> "Here's a real API — the Postman Liftoff Content API. It has two endpoints: one for learning paths, one for modules. No spec, no documentation. An AI agent would have no idea this API exists. Let's change that."

#### Click Track

**Show:** Open a browser tab to `https://www.postman.com/liftoff/api/content/learning-paths` so the audience can see the raw JSON response — real data, no spec wrapping it.

**Show:** Open a second tab to `https://www.postman.com/liftoff/api/content/modules` — same thing, raw JSON, no documentation.

**Show:** Switch to the terminal with Claude Code running in this directory. The audience should see the empty `sample-api/` folder — no spec exists yet.

---

### Act 2: Generate the Spec (2 min)

#### Talk Track

> "Step one toward AI readiness: your API needs a spec. Writing one by hand takes half a day. Let's do it in 30 seconds."

_(wait for Claude to finish generating)_

> "Claude called the live endpoints, analyzed the response shapes, and produced a complete OpenAPI spec — endpoints, schemas, real examples from the actual API. That's the foundation every AI agent needs to discover and understand your API."

#### Click Track

**Show:** The Claude Code terminal, focused so the audience can read the prompt and watch Claude work.

**Do:** Type this prompt into Claude Code:

```
I have an API with two endpoints:
- https://www.postman.com/liftoff/api/content/learning-paths
- https://www.postman.com/liftoff/api/content/modules
Call both endpoints, examine the responses, and generate an OpenAPI 3.0 spec. Save it to sample-api/openapi.yaml
```

**Show:** After Claude finishes, open `sample-api/openapi.yaml` in the editor so the audience can see the generated spec — schemas, examples, metadata all derived from the live API.

---

### Act 3: Sync to Postman (1.5 min)

#### Talk Track

> "A spec on disk is good. A spec in Postman is better — now your whole team can test, document, and monitor it. And AI agents can discover it through the Postman API Network."

_(wait for sync to complete)_

> "One command. Collection created, environment configured, base URL set. The API is now discoverable."

> "I can search across all my Postman workspaces using plain English — and so can AI agents using the Postman MCP Server."

#### Click Track

**Do:** Type this prompt into Claude Code:

```
Sync my sample-api/openapi.yaml spec with Postman. Create a collection and environment for it.
```

Wait for the async sync to complete (~15-30 seconds). Claude will poll and confirm.

**Do:** Type this follow-up:

```
Search for the Liftoff Content API in my workspace. What endpoints does it have?
```

**Show:** Point out the endpoint list Claude returns — the audience should see the same endpoints from the browser tabs now organized in a Postman collection.

**Show (payoff):** Switch to the Postman app and open the "Liftoff Booth Demo" workspace. Show the newly created collection with the two endpoints, the environment with the base URL, and the imported schema. The audience sees the real artifact — it's not just terminal output, it lives in Postman.

---

### Act 4: Mock Server (2 min)

#### Talk Track

> "AI agents need reliable, predictable responses to test against. A mock server gives them that — and your frontend team gets to build in parallel."

_(wait for mock creation)_

> "Claude generated realistic example responses from the schema and created a live mock server. AI agents and developers both get a stable URL with predictable responses."

#### Click Track

**Do:** Type this prompt into Claude Code:

```
Create a mock server for the Liftoff Content API collection. Generate example responses for all endpoints.
```

**Show:** Point out the mock server URL that Claude returns in its response.

**Do:** Type this follow-up to prove it works:

```
Show me a curl command to test the mock server's GET /learning-paths endpoint
```

**Show:** Run the curl command Claude provides (or let Claude run it) — the audience sees a real HTTP response from the mock server.

**Show (payoff):** Switch to the Postman app. Open the mock server tab in the collection — show the mock URL, the configured example responses, and the server status. The audience sees the mock server is a real, running Postman resource, not just a terminal response.

---

### Act 5: Security Audit (1.5 min)

#### Talk Track

> "AI agents will probe your API in ways humans never would. Security matters even more when the consumer isn't a person making judgment calls — it's an autonomous agent following instructions. And if you want your API production-ready, security can't be an afterthought."

_(wait for audit to complete)_

> "OWASP Top 10 scanning — authentication, rate limiting, input validation, error handling, sensitive data exposure. Each finding gets a severity score and concrete remediation. Claude can apply the fixes directly to the spec."

#### Click Track

**Do:** Type this prompt into Claude Code:

```
Run a security audit on my Liftoff Content API
```

**Show:** Point out the findings list as Claude outputs it — highlight the severity scores and the specific remediation steps. If time allows, ask Claude to fix one of the findings live.

---

### Act 6: AI Agent Readiness — The Punchline (2 min)

#### Talk Track

> "Now for the big question — the one this whole demo has been building toward. Is this API actually ready for AI agents?"

_(wait for the readiness report)_

> "This runs 48 checks across 8 pillars — discoverability, authentication complexity, error handling, pagination, idempotency, and more. It scores your API and tells you exactly what to fix."

> "When we started 8 minutes ago, this API had no spec, no collection, no mock, no security review. Now we have a scored AI readiness report with a prioritized fix list. That's the journey from 'my API exists' to 'my API is AI- and production-ready.'"

#### Click Track

**Do:** Type this prompt into Claude Code:

```
Is my Liftoff Content API ready for AI agents?
```

**Show:** Walk the audience through the readiness report as it appears — point out the overall score, the 8 pillar breakdown, and the prioritized fix list. Highlight any pillar that scored low and the specific recommendation to improve it.

---

### Act 7: The Close (30 sec)

#### Talk Track

> "AI agents are coming for your APIs. The question isn't if, it's when. The Postman plugin for Claude Code gets you ready — from zero spec to AI-ready, all through natural language."

> "And this isn't just Claude Code. Postman provides plugins and skills for Cursor, Amazon Kiro, and Antigravity too — the same capabilities, in whatever tool you already use."

> "Open source. Free. One command."

> "Want to try it yourself? Walk through the Building with AI learning path on Postman Liftoff — it takes you through everything you just saw, step by step."

#### Click Track

**Show:** The presentation slide with the install command (slide 5 — navigate to it manually).

**Show:** Point to the CTA URL on the slide or have it ready in a browser tab:

`https://www.postman.com/liftoff/learning-paths/building-with-ai/`

---

## Tear Down / Reset

Run the teardown script after each demo:

```bash
./scripts/teardown.sh
```

The script:
- Deletes all generated files in `sample-api/` (including the spec)
- Reminds you to clean up Postman artifacts (collections, mocks, environments)
- Prints quick-cleanup commands you can run in Claude Code

### Full reset between demo days

```bash
./scripts/teardown.sh
./scripts/setup.sh
```

## Troubleshooting

| Issue | Fix |
|---|---|
| Plugin not loading | `claude plugin list` to verify. Reinstall with `claude plugin install github:Postman-Devrel/postman-claude-code-plugin` |
| Auth expired | Re-run `/postman:setup` or refresh your API key |
| Sync takes too long | The `generateCollection` call is async. Wait 15-30s. If stuck, try again. |
| Mock server errors | Check that the collection has example responses. Re-run the mock command. |
| "MCP server restarting" | Normal after OAuth. Wait 5 seconds and retry. |

## Additional Resources

| Resource | Link |
|---|---|
| **Building with AI** learning path (CTA) | https://www.postman.com/liftoff/learning-paths/building-with-ai/ |
| Postman Claude Code Plugin repo | https://github.com/Postman-Devrel/postman-claude-code-plugin |
| Postman Liftoff platform | https://www.postman.com/liftoff |
| Postman MCP Server docs | https://learning.postman.com/docs/ai/model-context-protocol/ |
| Claude Code Plugin module (Liftoff) | https://www.postman.com/liftoff/modules/claude-code-plugin |
| Postman MCP module (Liftoff) | https://www.postman.com/liftoff/modules/postman-mcp |
| Agent Mode Basics module (Liftoff) | https://www.postman.com/liftoff/modules/agent-mode-basics |
