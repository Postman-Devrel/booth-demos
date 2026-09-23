import { test } from 'node:test';
import assert from 'node:assert/strict';
import { serializeOrder } from '../src/serializers/order.js';
import { findOrder } from '../src/orders-repository.js';

// These are the fields orders-api promises in its own spec. Note what is NOT
// asserted here: legacy_customer_ref. Nobody writes a test for a field their
// own service never reads — which is why this suite stays green through a
// change that breaks two other services.
const PROMISED = ['id', 'status', 'currency', 'total_cents', 'customer_id', 'created_at'];

test('serializes every promised field', () => {
  const body = serializeOrder(findOrder('ord_9f21'));
  for (const field of PROMISED) {
    assert.ok(field in body, `missing promised field: ${field}`);
  }
});

test('total_cents is an integer', () => {
  const body = serializeOrder(findOrder('ord_9f21'));
  assert.equal(Number.isInteger(body.total_cents), true);
});

test('status is one of the documented values', () => {
  const body = serializeOrder(findOrder('ord_9f21'));
  assert.ok(['pending', 'fulfilled', 'cancelled'].includes(body.status));
});
