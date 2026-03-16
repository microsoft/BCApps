# Invoicing

Part of [Shopify Connector](../../CLAUDE.md).

Enables export of posted sales invoices from Business Central to Shopify as draft orders.

## AL objects

| Type | Name | Purpose |
|------|------|---------|
| Table | Shpfy Invoice Header (30161) | Tracks which Shopify orders were created from BC invoices |
| Codeunit | Shpfy Posted Invoice Export (30362) | Exports posted sales invoices to Shopify as draft orders |
| Codeunit | Shpfy Draft Orders API (30XXX) | GraphQL API calls for draft order creation and completion |
| Codeunit | Shpfy Fulfillment API (30XXX) | Creates fulfillments for invoice-originated orders |
| Codeunit | Shpfy Update Sales Invoice (30XXX) | Updates sales invoice headers with Shopify order info |
| Report | Shpfy Sync Invoices to Shpfy | Batch export of posted sales invoices to Shopify |
| PageExt | Shpfy Sales Invoice Update | Adds Shopify sync action to posted sales invoice |

## Key concepts

- Posted sales invoices can be exported to Shopify as completed draft orders
- Invoice export validates customer exists in Shopify (as company or customer)
- Payment terms on invoice must exist in Shopify for B2B scenarios
- Draft order is created first, then completed to generate a Shopify order
- Fulfillments are automatically created for the order after completion
- Shpfy Order Id on invoice tracks the created Shopify order
- Shpfy Order Id of -1 indicates export failure, -2 indicates not exportable
- Invoice lines map to draft order line items with quantities and prices
- Document links created to connect BC invoice with Shopify order
