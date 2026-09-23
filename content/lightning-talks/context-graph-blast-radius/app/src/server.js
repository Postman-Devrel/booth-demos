import { createServer } from 'node:http';
import { findOrder } from './orders-repository.js';
import { serializeOrder } from './serializers/order.js';

const PORT = process.env.PORT ?? 3000;

createServer((req, res) => {
  const match = /^\/orders\/([^/?]+)/.exec(req.url ?? '');
  if (!match) {
    res.writeHead(404, { 'content-type': 'application/json' });
    return res.end(JSON.stringify({ error: 'not_found' }));
  }

  const row = findOrder(match[1]);
  if (!row) {
    res.writeHead(404, { 'content-type': 'application/json' });
    return res.end(JSON.stringify({ error: 'order_not_found' }));
  }

  res.writeHead(200, { 'content-type': 'application/json' });
  res.end(JSON.stringify(serializeOrder(row), null, 2));
}).listen(PORT, () => {
  console.log(`orders-api listening on http://localhost:${PORT}`);
  console.log(`try: curl http://localhost:${PORT}/orders/ord_9f21`);
});
