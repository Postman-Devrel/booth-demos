const ORDERS_API = process.env.ORDERS_API_URL ?? 'https://orders.internal.example.com';

// Call site the Context Graph reads out of GitHub: this is what creates the
// `calls` edge from invoice-service to GET /orders/{id} on orders-api.
export async function getOrder(orderId) {
  const res = await fetch(`${ORDERS_API}/orders/${orderId}`, {
    headers: { accept: 'application/json' },
  });
  if (!res.ok) throw new Error(`orders-api returned ${res.status}`);
  return res.json();
}
