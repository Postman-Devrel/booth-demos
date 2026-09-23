// Shapes an order row into the public GET /orders/{id} response body.
//
// Dropped legacy_customer_ref: deprecated three years ago, written here and
// never read anywhere in this repository. Removing dead weight from the payload.
export function serializeOrder(row) {
  return {
    id: row.id,
    status: row.status,
    currency: row.currency,
    total_cents: row.total_cents,
    customer_id: row.customer_id,
    created_at: row.created_at,
  };
}
