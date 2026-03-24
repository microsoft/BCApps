# Invoicing

Exports posted BC sales invoices to Shopify as completed orders. This is a one-directional push -- BC invoices become Shopify draft orders that are immediately completed and fulfilled.

## How it works

`ShpfyPostedInvoiceExport` drives the flow. It first validates the invoice is exportable: the bill-to customer must exist as a Shopify customer or company, payment terms must be mapped, the customer cannot be the default template customer, and lines must have valid quantities (positive integers) and non-empty item numbers. The invoice data is mapped to temporary `Shpfy Order Header` and `Shpfy Order Line` records, then passed to `ShpfyDraftOrdersAPI.CreateDraftOrder`, which builds and sends a `draftOrderCreate` GraphQL mutation.

The draft order includes line items (with prices, weights, and descriptions), shipping and billing addresses, invoice discount as an applied discount, tax lines aggregated by VAT calculation type, and optional payment terms (NET or FIXED). Once created, the draft is immediately completed via `draftOrderComplete`, which converts it to a real Shopify order. Fulfillment orders for the new order are then auto-fulfilled via `ShpfyFulfillmentAPI`, marking everything as shipped.

The `Shpfy Order Id` on the posted Sales Invoice Header tracks the result: a positive value means success, -1 means the Shopify call failed, and -2 means the invoice was not exportable. A `Shpfy Invoice Header` record and a document link are created on success.

## Things to know

- Draft orders are created with `taxExempt: true` and tax amounts are added as separate line items, because Shopify cannot replicate BC's exact tax calculations.
- Payment terms on the draft order use Shopify's `PaymentTermsTemplate` IDs from the Payment Terms mapping. If the invoice's payment terms code is not mapped, the primary (fallback) term is used.
- Invoices with non-integer or negative quantities are rejected during validation.
- The invoice's remaining amount determines whether the Shopify order is marked as unpaid (which triggers payment terms) or paid.
- Sales comment lines from the posted invoice are concatenated and sent as the draft order's note.
- Currency codes are resolved to ISO codes via the BC Currency table.
