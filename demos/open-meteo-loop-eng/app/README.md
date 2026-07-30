# open-meteo-loop-eng (demo project)

The runnable project for the **Meteo API Loop Engineering** booth demo — a
loop-engineering example where an AI coding agent verifies its own Open-Meteo
API client against a human-authored Postman oracle and fixes itself until the
oracle passes.

This folder is what you open in Claude Code during the demo. It is kept lean —
everything the demo needs is right here.

## Run it

```bash
npm install    # no runtime deps; wires up 'npm start'
npm start      # runs the client and prints its output
```

## How the demo is driven

The booth runbook is the single source of truth — see the demo README one level
up (`../README.md`). In short:

1. `../scripts/setup.sh` provisions the Postman oracle and prints the loop
   prompt with the collection/environment UIDs filled in.
2. In Claude Code (opened here), paste that loop prompt. The agent writes the
   client, verifies via `@agent-oracle-check`, and loops until the oracle passes.
3. `../scripts/teardown.sh` removes the Postman workspace and resets the client.

See [`AGENTS.md`](AGENTS.md) for the rules the agent must follow (most importantly:
never read the oracle).

## Learn more

- Postman MCP Server: <https://learning.postman.com/docs/reference/postman-api/postman-mcp-server/overview>
- Loop engineering (Addy Osmani): <https://addyosmani.com/blog/loop-engineering/>

## Requirements

- [Node.js](https://nodejs.org/) 18+ (uses built-in `fetch`)
- A free [Postman account](https://identity.getpostman.com/signup) and a
  [Postman API key](https://learning.postman.com/docs/developer/postman-api/authentication/)
- [Claude Code](https://code.claude.com/docs) (or another MCP-compatible agent)
