# AGENTS.md

Context for AI agents working in this project during the booth demo.

## What this is

A hands-on **loop-engineering** demo. You will be asked to write a small
JavaScript client for the free [Open-Meteo](https://open-meteo.com/en/docs)
weather API, and to verify your work by looping against an **oracle** — a
human-authored Postman Collection whose test decides pass/fail. The oracle lives
in this repo (`postman/hourly-forecast.postman_collection.yaml`) and is run by the
Postman CLI; no Postman account, key, or cloud is involved.

The point of the demo is that you *discover* what "correct" means by running,
not by being told. So the rules below are not optional.

## Rules for the loop

- **The only way you may check your work is by delegating to `@agent-oracle-check`.**
  It runs the oracle (the Postman CLI against the local collection) and reports
  which assertions passed or failed.
- **Do NOT read the oracle.** Do not open `postman/` — especially the collection
  file, which contains the assertions. Do not run the Postman CLI yourself. If you
  read the assertions, you defeat the entire exercise; you must learn what to fix
  from `oracle-check`'s failure messages alone.
- **You do not know the full contract up front.** A first attempt can return
  `200 OK` and a full array of numbers and still fail an assertion. Read the
  failure message, fix the client, and re-verify.
- **Loop with a budget** (typically up to 3 attempts): write the whole client →
  call `@agent-oracle-check` with the exact URL your client fetches → if it reports
  failures, fix from the messages and repeat → stop when zero assertions fail.

## Layout

| Path | Purpose |
|------|---------|
| `src/weather-client.js` | The client you edit. Ships in a "looks correct" state that runs fine but does not yet satisfy the oracle. |
| `src/run.js` | CLI runner. `npm start` runs the client and prints its output. |
| `postman/hourly-forecast.postman_collection.yaml` | The oracle (a Postman Collection with the test embedded). **Off-limits — do not read.** |
| `.claude/agents/oracle-check.md` | The verifier subagent. It runs the Postman CLI against the collection and reports only assertion results. |

## Conventions

- Node 18+ only (built-in `fetch`); no runtime dependencies, no build step.
- ESM (`import`/`export`), no TypeScript, minimal comments.
- The oracle is run locally with the Postman CLI — no secrets, no API key.
