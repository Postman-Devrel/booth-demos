// Stand-in for the real datastore. The demo never needs a database running.
const ROWS = new Map([
  ['ord_9f21', {
    id: 'ord_9f21',
    status: 'fulfilled',
    currency: 'EUR',
    total_cents: 12900,
    customer_id: 'cus_01HQ8M',
    legacy_customer_ref: 'CRM-448120',
    created_at: '2026-09-18T09:14:22Z',
  }],
]);

export function findOrder(id) {
  return ROWS.get(id) ?? null;
}
