const ORDERS_API = process.env.ORDERS_API_URL ?? 'https://orders.internal.example.com';

// Calls the same endpoint, but projects only the fields the mobile screen shows.
// This consumer is in the blast radius of the ENDPOINT and not of the FIELD —
// the distinction the graph lets the agent make.
export async function orderScreen(orderId) {
  const res = await fetch(`${ORDERS_API}/orders/${orderId}`);
  const { id, status, currency, total_cents } = await res.json();
  return { id, status, currency, total_cents };
}
