# Order handling

This folder owns the full lifecycle of a Shopify order inside BC -- from API fetch through to a posted Sales Order or Sales Invoice.

## Import flow

Orders arrive in two stages. `ShpfyOrdersAPI` (codeunit 30165) runs a GraphQL cursor-paginated query against the Shopify Orders API and writes lightweight rows into `Shpfy Orders to Import`. On first sync (no previous sync time) it fetches only open orders; subsequent syncs fetch by `updatedAt`. `ShpfyImportOrder` (codeunit 30161) then retrieves the full order JSON per order, populates `Shpfy Order Header` and `Shpfy Order Line`, and pulls in related records -- fulfillment orders, shipping charges, transactions, returns, and refunds -- all inside `SetAndCreateRelatedRecords`. Refund lines are subtracted from order line quantities and header amounts in `ConsiderRefundsInQuantityAndAmounts` so the order reflects the net position.

## Dual currency model

Every monetary field on the header and lines exists in two flavours: shop currency (e.g. `"Total Amount"`, `"Unit Price"`) and presentment currency (e.g. `"Presentment Total Amount"`, `"Presentment Unit Price"`). The shop's `"Currency Handling"` setting -- either `Shop Currency` or `Presentment Currency` -- selects which set flows into the BC Sales Document. This choice is recorded on the order header as `"Processed Currency Handling"` at processing time so credit memos created later use the same currency the order was processed in.

## Mapping chain

`ShpfyOrderMapping` (codeunit 30163) resolves everything the Sales Header needs before document creation. The chain is:

- **Customer / Company** -- B2C orders use `ShpfyCustomerMapping`, B2B orders use `ShpfyCompanyMapping`. Falls back to `"Default Customer No."` / `"Default Company No."` on the shop. B2B orders with a company location try to resolve sell-to and bill-to from the location record first.
- **Shipment method** -- looked up via `Shpfy Shipment Method Mapping` keyed on (Shop Code, shipping charge title).
- **Shipping agent** -- same mapping table, separate fields for agent code and service code.
- **Payment method** -- resolved from `Shpfy Order Transaction` records; only set when all successful sale/capture/authorization transactions agree on a single payment method.

## Tax area priority

`ShpfyOrderMgt.FindTaxArea` implements a configurable address priority (`"Tax Area Priority"` on the shop) to decide which address (ship-to, sell-to, bill-to) determines the tax area code. Six permutations are supported. Presence is determined by whether the city field is non-empty.

## Processing -- Sales Order vs Sales Invoice

`ShpfyProcessOrder` (codeunit 30166) decides the document type: if the order's fulfillment status is `Fulfilled` and the shop has `"Create Invoices From Orders"` enabled, it creates a Sales Invoice; otherwise a Sales Order. Line creation handles tips (G/L Account from `"Tip Account"`), gift cards (`"Sold Gift Card Account"`), and regular items. Shipping charges create additional lines -- either from the shop's `"Shipping Charges Account"` or from the shipment method mapping's custom type/no. if configured (which can be G/L Account, Item, or Item Charge). After lines, a global discount residual (order discount minus sum of line discounts) is applied as an invoice discount. The document is optionally auto-released via `"Auto Release Sales Orders"`.

## The "Processed" flag

`OrderHeader.Processed` is set to `true` after successful document creation. It is also set if a Shopify Invoice already existed at import time. The `IsProcessed()` function is broader -- it also checks the `Shpfy Doc. Link To Doc.` table for any linked BC document, so even if someone clears the Processed flag, the link table still prevents reprocessing. When re-importing a processed order, the system detects conflicts (changed line items, quantities, or shipping amounts) and sets `"Has Order State Error"` to flag the order for manual review.

## Archive / close

If `"Archive Processed Orders"` is enabled, the import step calls `CheckToCloseOrder`. An order is closed in Shopify when it is fulfilled, fully paid, and has no outstanding sales line quantities (for orders) or simply has a Sales Invoice No. and is fulfilled (for invoices).
