# Invoicing

Exports posted BC sales invoices to Shopify as orders. The flow creates a Shopify draft order, completes it, immediately marks it as fulfilled, and links it back to the BC invoice. Invoices are treated as tax-exempt in Shopify to prevent tax recalculation.

## How it works

`ShpfyPostedInvoiceExport` (30362) drives the export. It validates the invoice is exportable (customer exists in Shopify, payment terms exist, customer is not the default template customer, lines have valid quantities), then maps the invoice header and lines into temporary `Shpfy Order Header` and `Shpfy Order Line` records. The `ShpfyDraftOrdersAPI` creates and completes the draft order, `ShpfyFulfillmentAPI` immediately creates fulfillments for all fulfillment order IDs, and a `Shpfy Invoice Header` record is created to track the Shopify order ID. The BC invoice gets the Shopify Order Id and Order No. written back.

The `Shpfy Sync Invoices to Shopify` report (30110) orchestrates the batch export, iterating over posted invoices that lack a Shopify Order Id.

## Things to know

- Sentinel values on `Shpfy Order Id` field of the Sales Invoice Header: -2 means the invoice was not exportable (failed validation), -1 means the Shopify API call failed. Both prevent re-processing on subsequent sync runs.
- Invoices are immediately fulfilled after creation in Shopify -- the flow creates fulfillment orders and marks them complete in the same operation, so the Shopify order shows as delivered.
- The export skips invoices where the Bill-to Customer No. matches the shop's `Default Customer No.` or any customer template's default customer, preventing circular sync scenarios.
- Line quantities must be positive whole numbers (Shopify doesn't support fractional quantities), and every non-blank line must have a `No.` value. Invalid lines cause the entire invoice to be skipped.
- A document link is created between the Shopify order and the BC posted invoice, enabling bidirectional navigation through the Document Links framework.
