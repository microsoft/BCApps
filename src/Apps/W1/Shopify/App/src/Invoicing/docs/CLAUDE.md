# Invoicing

Exports posted BC sales invoices to Shopify as orders, enabling B2B buyers to see invoices in their Shopify portal.

## How it works

`ShpfyPostedInvoiceExport.Codeunit.al` is the main entry point (runs on `Sales Invoice Header`). It first validates the invoice is exportable -- the bill-to customer must exist as a Shopify company or customer, the payment terms must be mapped in Shopify, the customer cannot be the default customer or a customer template target, lines must have valid positive integer quantities, and every typed line must have a `No.` value. Any validation failure logs a skipped record and stamps the invoice with `Shpfy Order Id = -2`.

For valid invoices, the codeunit maps the header and lines into temporary `Shpfy Order Header` and `Shpfy Order Line` records, then uses `ShpfyDraftOrdersAPI.Codeunit.al` to create a Shopify draft order via raw GraphQL mutation construction (not parameterized templates). The draft order is immediately completed to convert it into a real order. After completion, fulfillment orders are fetched and immediately fulfilled (since the invoice represents already-shipped goods), a `ShpfyInvoiceHeader` tracking record is created, and a document link is added to `Shpfy Doc. Link To Doc.` for traceability. If draft order creation fails, the invoice gets `Shpfy Order Id = -1`.

## Things to know

- Tax lines are aggregated by VAT calculation type and percentage, then added as separate line items on the draft order (with `taxExempt: true` on the order itself) -- Shopify does not natively support BC's tax structure, so taxes are represented as custom line items.
- The draft order includes `paymentTerms` only when the invoice has a remaining amount (is unpaid). Payment terms resolution falls back to the primary Shopify payment term if no exact code match exists.
- Invoice quantities must be positive whole numbers -- Shopify does not support fractional or negative quantities, so such lines cause the entire invoice to be skipped.
- The `ShpfyInvoiceHeader` table is minimal (just a Shopify Order Id) and exists solely to track which orders were created by invoice export rather than normal order import.
- Sales invoice comments are exported as the draft order's `note` field.
