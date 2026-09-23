# The demo estate

The Context Graph does not read a local folder. It ingests **Postman workspaces**,
**GitHub** repositories, and **New Relic** telemetry, resolves entities across them,
and refreshes nightly. So for the demo to be real rather than narrated, a small API
estate has to exist somewhere the graph can see it.

This folder is that estate, plus the script that publishes it. **It is one-time
setup, not per-session work.** `scripts/setup.sh` never touches it.

## What the estate says

| Repo | Role in the story | Calls `GET /orders/{id}` | Reads `legacy_customer_ref` | Owner |
|---|---|---|---|---|
| `orders-api` (from [../app](../app)) | the provider — the only repo on stage | — (exposes it) | writes it, never reads it | `@platform-orders` |
| `invoice-service` | keys the billing entity off the old CRM ref | yes | **yes** | `@finance-systems` |
| `crm-sync-job` | nightly mirror into the legacy CRM | yes | **yes** | `@growth-crm` |
| `mobile-bff` | projects four fields onto a mobile screen | yes | no | `@apps-mobile` |

That last row is the one that makes the demo worth watching: three services are in
the blast radius of the **endpoint**, two are in the blast radius of the **field**.
An agent with only the provider repo cannot tell you either number.

`CODEOWNERS` in each repo is what gives the graph its `owned_by` edges, so the
answer comes back with teams attached and not just service names.

## Publishing it

```bash
ESTATE_ORG=<your-demo-org> ./estate/seed-estate.sh --dry-run   # prints, creates nothing
ESTATE_ORG=<your-demo-org> ./estate/seed-estate.sh             # asks for confirmation
```

Use a **dedicated org or your own account**. The service names are deliberately
plain because they appear on stage — do not seed them into an org that already has
a real `orders-api`.

## The two steps that are not scriptable

1. **Connect the sources** on the Postman side: ingest the GitHub org, and ingest
   the Postman workspace holding the Orders API spec (import [../app/openapi.yaml](../app/openapi.yaml)).
   Context Graph must be **enabled for your team** — it is not a free-tier feature.
2. **Wait for the nightly refresh.** Pushing repos does not populate the graph
   within the hour. Seed at least a day before you present.

New Relic is the third source the graph can ingest. The demo does not need it:
GitHub call sites plus the Postman spec are enough for `exposes`, `calls`, and
`owned_by`. If your team *does* have New Relic wired up, the graph's answer will
also carry runtime evidence, which is strictly better on stage — say so if it does.

## Verifying before you present

```bash
./scripts/setup.sh
```

Setup runs the real ask and caches the answer. If the graph cannot answer about
`orders-api`, setup says so loudly and tells you which act degrades — read
[../README.md](../README.md) section 6.
