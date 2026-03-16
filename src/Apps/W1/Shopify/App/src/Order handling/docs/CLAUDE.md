# Order handling

This module manages the full lifecycle of Shopify orders inside Business Central: retrieving orders from the Shopify GraphQL API, staging them for review, mapping them to BC customers and items, and converting them into Sales Orders or Sales Invoices. It also handles order cancellation, fulfillment tracking, refund adjustment, and conflict detection for already-processed orders.

## How it works

The flow has three distinct phases. First, `ShpfyOrdersAPI` retrieves lightweight order summaries into the `Shpfy Orders to Import` staging table via paginated GraphQL queries. This table carries enough data (financial status, fulfillment status, amounts, tags, risk level) for users to review and filter before committing to a full import. Second, `ShpfyImportOrder` performs the detailed import: it fetches the complete order JSON, populates `Shpfy Order Header` and `Shpfy Order Line` records, pulls in related data (tax lines, shipping charges, transactions, fulfillment orders, returns, refunds), and runs conflict detection against previously processed orders. Third, `ShpfyProcessOrder` takes a fully-imported order through mapping (customer resolution, item/variant resolution, shipping/payment method mapping) and creates a BC Sales Order or Sales Invoice depending on the fulfillment status and the shop's "Create Invoices From Orders" setting.

Each order is processed inside its own `Commit()` boundary in `ShpfyProcessOrders` so that a failure on one order does not roll back others. When `ProcessOrder.Run` fails, the codeunit captures the error in the header's `Has Error` / `Error Message` fields and cleans up any partially-created sales document via `CleanUpLastCreatedDocument`.

## Things to know

- Every monetary amount on the order header exists in two forms: shop currency (e.g. `Total Amount`, `VAT Amount`) and presentment currency (e.g. `Presentment Total Amount`, `Presentment VAT Amount`). Which set drives the sales document depends on the shop's `Currency Handling` setting -- either `Shop Currency` or `Presentment Currency`.
- The order header stores three complete denormalized addresses -- sell-to, bill-to, and ship-to -- each with first/last name, company, address lines, city, county, post code, and country code. These are populated from different JSON paths (`displayAddress`, `billingAddress`, `shippingAddress`).
- B2B orders are identified by `Company Id` / `Company Location Id` on the header (populated from `purchasingEntity.company` / `purchasingEntity.location` in the JSON). When `B2B = true`, the mapping path switches to `MapB2BHeaderFields` which resolves via `Shpfy Company Mapping` instead of `Shpfy Customer Mapping`.
- Conflict detection uses `Line Items Redundancy Code` -- a hash of all line IDs -- plus `Current Total Items Quantity` and shipping charges to detect whether a re-imported order has changed since it was last processed. Conflicts set `Has Order State Error = true` and leave the order in an error state that requires manual resolution.
- Refunds adjust order lines in place: `ConsiderRefundsInQuantityAndAmounts` subtracts refund line quantities and amounts directly from the order header and lines before processing, and lines reduced to zero quantity are deleted.
- The `ShpfyProcessOrder` codeunit decides between Sales Order and Sales Invoice based on fulfillment status: if `Fulfillment Status = Fulfilled` and `Create Invoices From Orders` is enabled on the shop, it creates an Invoice; otherwise it creates an Order.
