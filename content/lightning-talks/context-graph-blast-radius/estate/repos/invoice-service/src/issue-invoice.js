import { getOrder } from './orders-client.js';

// The legal entity that issues the invoice is still keyed off the OLD CRM
// reference. Nothing in orders-api knows this. Removing the field takes this
// branch straight to `undefined` and issues the invoice against no entity.
export async function issueInvoice(orderId) {
  const order = await getOrder(orderId);

  const billingEntity = lookupEntityByCrmRef(order.legacy_customer_ref);
  if (!billingEntity) {
    throw new Error(`no billing entity for CRM ref ${order.legacy_customer_ref}`);
  }

  return {
    order_id: order.id,
    amount_cents: order.total_cents,
    currency: order.currency,
    entity: billingEntity,
  };
}

function lookupEntityByCrmRef(crmRef) {
  return crmRef?.startsWith('CRM-') ? { id: crmRef, region: 'EU' } : null;
}
