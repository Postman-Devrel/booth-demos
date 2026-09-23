# orders-api

Serves order records to the rest of the estate. `GET /orders/{id}` is the endpoint
everything else depends on.

This folder is the **local working copy** the presenter has open on stage. It is
deliberately the *only* repository on the machine: the services that call this API
live in the GitHub organization and in the Context Graph, not here. That is the
whole point of the talk — a repository shows an agent what an endpoint *calls*,
never who *calls it*.

```bash
npm start                                  # node 18+, zero dependencies
curl http://localhost:3000/orders/ord_9f21
```

The field under discussion is `legacy_customer_ref` in
[src/serializers/order.js](src/serializers/order.js). Inside this repo it is
written once and never read again.
