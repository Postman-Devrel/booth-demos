# open-meteo-loop-eng (demo project)

The runnable project for the **Meteo API Loop Engineering** booth demo — a
loop-engineering example where an AI coding agent verifies its own Open-Meteo
API client against a Postman oracle and fixes itself until the oracle passes.

The oracle is a Postman Collection stored right here in the repo
(`postman/hourly-forecast.postman_collection.json`) and is run by the **Postman
CLI** — no Postman account, API key, or cloud workspace involved. This folder is
what you open in Claude Code during the demo, and it's kept lean.

## Run it

```bash
npm install    # no runtime deps; wires up 'npm start'
npm start      # runs the client and prints its output
```

## How the demo is driven

The booth runbook is the single source of truth — see the demo README one level
up (`../README.md`). In short:

1. `../scripts/setup.sh` checks your tools (Node, Claude Code, the Postman CLI),
   resets the client, sanity-runs the oracle, and prints the ready-to-paste loop
   prompt (fully static — no IDs to swap in).
2. In Claude Code (opened here), paste that loop prompt. The agent writes the
   client, verifies via `@agent-oracle-check` (which runs the Postman CLI against
   the local collection), and loops until the oracle passes.
3. `../scripts/teardown.sh` resets the client for the next run. Nothing runs in the
   cloud, so there's nothing to clean up.

See [`AGENTS.md`](AGENTS.md) for the rules the agent must follow (most importantly:
never read the oracle).

## Learn more

- Postman CLI: <https://learning.postman.com/docs/postman-cli/postman-cli-overview/>
- Loop engineering (Addy Osmani): <https://addyosmani.com/blog/loop-engineering/>

## Requirements

- [Node.js](https://nodejs.org/) 18+ (uses built-in `fetch`)
- [Postman CLI](https://learning.postman.com/docs/postman-cli/postman-cli-installation/) — runs the local oracle collection (no account or key needed)
- [Claude Code](https://code.claude.com/docs)
