# Business logic

## Overview

Order handling follows a three-stage pipeline: retrieval into a staging table, detailed import into order header/line records, and processing into BC sales documents. Each stage is separated by a commit boundary and can be retried independently.

## Order retrieval and staging

`ShpfyOrdersAPI.GetOrdersToImport` queries Shopify's GraphQL API using paginated cursor-based queries. On the first sync (no last-sync timestamp), it uses `GetOpenOrdersToImport` which filters to non-closed orders; on subsequent syncs it uses `GetOrdersToImport` which fetches everything modified since the last sync time. The response is parsed by `ExtractShopifyOrdersToImport`, which writes one row per order into `Shpfy Orders to Import`. Each row records whether the order is `New` or an `Update` to an existing header, and closed orders that have never been imported are excluded. The staging table also captures custom attributes, tags, risk assessments, and purchasing entity type (Customer vs Company for B2B).

## Detailed order import

`ShpfyImportOrder.ImportOrderAndCreateOrUpdate` does the heavy lifting. It ensures an `Shpfy Order Header` record exists, retrieves the full order JSON via a separate GraphQL query (`GetOrderHeader`), and populates header fields from three JSON regions -- `displayAddress` for sell-to, `shippingAddress` for ship-to, and `billingAddress` for bill-to. Currency codes are translated from ISO codes to BC currency codes via `TranslateCurrencyCode`, which clears the code if it matches the LCY code.

Order lines are retrieved separately through `GetOrderLines` / `GetNextOrderLines` (paginated), parsed into temporary records, then inserted or updated. Each line captures both shop and presentment prices (`Unit Price` vs `Presentment Unit Price`, `Discount Amount` vs `Presentment Discount Amount`). Discount allocations are summed across all allocation entries on each line via `GetTotalLineDiscountAmount`. After line insertion, the codeunit computes `Line Items Redundancy Code` -- a hash of all sorted line IDs -- which is stored on the header for later conflict detection.

Related records are created in `SetAndCreateRelatedRecords`: tax lines, shipping charges, transactions, fulfillment orders, returns, and refunds are all imported. The codeunit then calls `ConsiderRefundsInQuantityAndAmounts` to subtract refund quantities and amounts directly from header totals and line quantities, and deletes any lines reduced to zero.

If the order was already processed and the import detects a change -- different redundancy hash, increased item quantity, or changed shipping charges -- it sets `Has Order State Error = true` with a descriptive conflict message. This prevents the stale BC sales document from silently diverging from the Shopify order.

## Customer and item mapping

`ShpfyOrderMapping.DoMapping` orchestrates header and line mapping. For non-B2B orders, `MapHeaderFields` resolves sell-to and bill-to customers via `Shpfy Customer Mapping`, falling back to the shop's default customer when no match is found. For B2B orders, `MapB2BHeaderFields` uses `Shpfy Company Mapping` and can resolve sell-to/bill-to from `Shpfy Company Location` records when a `Company Location Id` is present on the order.

Shipping method, shipping agent, and payment method are resolved from their own mapping tables. Payment method mapping in particular looks at successful order transactions and only assigns a code when all transactions share a single payment method -- mixed-payment orders get no code so the user can decide.

Line mapping in `MapVariant` resolves each order line's `Shopify Variant Id` to a BC `Item No.`, `Variant Code`, and `Unit of Measure Code`. It first checks whether the variant already has a linked `Item SystemId`; if not, it triggers a product import for that product to create the mapping on the fly. The `UoM Option Id` on the variant determines which option slot provides the unit-of-measure code.

## Sales document creation

`ShpfyProcessOrder` converts a fully-mapped order into a BC Sales Order or Sales Invoice. The choice is configuration-driven: fulfilled orders become invoices when the shop's `Create Invoices From Orders` flag is set. The codeunit creates the header with all three address blocks copied from the order, validates the currency based on `Currency Handling` (shop currency or presentment currency), and sets document date, external document number (from `PO Number`), and payment/shipping terms.

Lines are created with explicit unit price and line discount amount from the Shopify order, bypassing BC's normal price calculation. Tip lines post to the shop's "Tip Account" G/L account; gift card lines post to "Sold Gift Card Account". Shipping charges become G/L account lines (or item charge lines when the shipment method mapping specifies a charge type). After all lines, a cash rounding line is added if the order has a `Payment Rounding Amount`.

Global discounts -- the portion of the order discount not already allocated to individual lines or shipping -- are applied as an invoice discount via `SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt`.

After successful creation, the order header is marked `Processed = true` and the `Processed Currency Handling` field snapshots which currency mode was used. If `Auto Release Sales Orders` is enabled, the sales document is released immediately. If the order is fully paid and fully fulfilled, and `Archive Processed Orders` is on, the import codeunit closes the order in Shopify via a `CloseOrder` GraphQL mutation.

## Error handling

Processing wraps each order in `ProcessOrder.Run` (a TryFunction-style pattern via `Codeunit.Run`). On failure, the partially created sales document is deleted via `CleanUpLastCreatedDocument`, the error text is stored in `Error Message` with a timestamp prefix, and `Sales Order No.` / `Sales Invoice No.` are cleared. The outer loop in `ShpfyProcessOrders` commits after each order so failures are isolated.
