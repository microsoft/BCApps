# Invoicing

Exports posted BC sales invoices to Shopify as draft orders, completes them, creates fulfillments, and tracks the resulting Shopify order.

## Quick reference

- **Entry point(s)**: `Codeunits/ShpfyPostedInvoiceExport.Codeunit.al`
- **Key patterns**: Draft order create-then-complete flow, validation with skipped record logging

## Structure

- Codeunits (4): PostedInvoiceExport (main orchestrator), DraftOrdersAPI, FulfillmentAPI, UpdateSalesInvoice
- Tables (1): InvoiceHeader (minimal -- just stores Shopify Order Id)
- Page Extensions (1): SalesInvoiceUpdate
- Reports (1): SyncInvoicesToShpfy

## Key concepts

- The export flow: validate exportability, map invoice data to temp order header/lines, create Shopify draft order, complete it, create fulfillments, then store the Shopify order ID on the BC invoice
- Validation checks: customer must exist as Shopify customer/company, payment terms must exist in Shopify, customer must not be the default/template customer, lines must have valid quantities (positive integers) and non-empty No.
- Failed exports set the Shopify Order Id to -1; non-exportable invoices get -2; successful exports store the real Shopify order ID
- Tax lines are aggregated by VAT calculation type and percentage, then sent as order-level tax lines on the draft order
- A document link is automatically created after successful export to connect the BC invoice to the Shopify order
