const ORDERS_API = process.env.ORDERS_API_URL ?? 'https://orders.internal.example.com';

// Nightly. Runs at 02:00 UTC, which is why nobody notices it for a day.
export async function syncOrderToCrm(orderId) {
  const res = await fetch(`${ORDERS_API}/orders/${orderId}`);
  const order = await res.json();

  // The CRM record is addressed BY the legacy ref. There is no fallback path.
  return upsertCrmRecord(order.legacy_customer_ref, {
    amount_cents: order.total_cents,
    status: order.status,
  });
}

async function upsertCrmRecord(crmRef, payload) {
  if (!crmRef) throw new Error('cannot upsert a CRM record without a ref');
  return { crmRef, ...payload };
}
