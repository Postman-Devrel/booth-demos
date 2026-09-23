// Shapes an order row into the public GET /orders/{id} response body.
//
// Nothing else in THIS repository reads `legacy_customer_ref`. It is written
// here and never referenced again — which is exactly why it looks safe to drop.
export function serializeOrder(row) {
  return {
    id: row.id,
    status: row.status,
    currency: row.currency,
    total_cents: row.total_cents,
    customer_id: row.customer_id,
    // Added in v1.2 when customer IDs were migrated off the old CRM.
    // Kept for consumers that had not migrated yet. That was three years ago.
    legacy_customer_ref: row.legacy_customer_ref,
    created_at: row.created_at,
  };
}
