# orders-api

Serves order records to the rest of the estate. `GET /orders/{id}` is the endpoint
everything else depends on.

This folder is the **local working copy** the presenter has open on stage. It is
deliberately the *only* repository on the machine: the services that call this API
live in the GitHub organization and in the Context Graph, not here. That is the
premise of the talk — a repository shows you what an endpoint *calls*, never who
*calls it*, so a pipeline that only reads this repo cannot fail on a break it
causes somewhere else.

```bash
npm start                                  # node 18+, zero dependencies
curl http://localhost:3000/orders/ord_9f21

npm test                                   # the gate that checks this service against itself
./ci/blast-radius-check.sh                 # the gate that checks everyone else against it
```

## Two gates, two questions

| | Asks | Can answer from this repo? |
|---|---|---|
| [`npm test`](test/order-serializer.test.js) | is `orders-api` still correct against its own spec? | yes |
| [`ci/blast-radius-check.sh`](ci/blast-radius-check.sh) | is anyone *else* still correct against `orders-api`? | **no** — it needs the Postman CLI and the Context Graph |

Both run in [the same workflow](.github/workflows/blast-radius.yml). The second one
is policy we wrote — roughly a hundred and fifty lines of shell — on top of
`postman context-graph ask`. Postman does not ship a blast-radius gate; it ships the
command and the exit-code contract that let you build one.

The field under discussion is `legacy_customer_ref` in
[src/serializers/order.js](src/serializers/order.js). Inside this repo it is written
once and never read again, and [the test suite](test/order-serializer.test.js)
deliberately does not assert it — because nobody writes a test for a field their own
service never reads.
