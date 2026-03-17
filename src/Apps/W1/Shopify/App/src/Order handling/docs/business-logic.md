# Business logic

## Overview

Order processing follows a strict import-then-map-then-process pipeline. Each stage is a separate codeunit and can fail independently. Import retrieves raw Shopify data and stores it in Shopify-specific tables. Mapping resolves that data to BC master records (customers, items, shipment methods). Processing creates the actual BC sales documents. Errors at any stage are captured on the order header and do not block other orders from processing.

The pipeline is designed to be re-entrant. Re-importing an already-processed order triggers conflict detection rather than overwriting BC documents. Refunds are netted into order quantities at import time, so the mapping and processing stages always see post-refund figures.

## Import

The entry point is `ShpfyImportOrder`, which runs against an `ShpfyOrdersToImport` record. The core method `ImportOrderAndCreateOrUpdate` does the following:

1. Ensures an `ShpfyOrderHeader` record exists (inserts a skeleton if new).
2. Retrieves the order header JSON via `ExecuteGraphQL(GetOrderHeader)`. If B2B is enabled, the query also fetches `staffMember`.
3. Retrieves order lines with pagination via `GetOrderLines` / `GetNextOrderLines`.
4. If the order is already processed and has no prior state error, runs conflict detection before overwriting any fields.
5. Sets header values from JSON. New orders get the full treatment (`SetNewOrderHeaderValuesFromJson` -- addresses, customer, currency, B2B fields). Updates only refresh editable fields (statuses, amounts, dates).
6. Calls `SetAndCreateRelatedRecords` to pull in tax lines, custom attributes, tags, risks, fulfillment orders, shipping charges, transactions, returns, and refunds. Returns and refunds are only fetched if the shop's `Return and Refund Process` setting requires import.
7. Inserts order lines, computing the redundancy hash (a hash of sorted line IDs used for conflict detection later).
8. Runs `ConsiderRefundsInQuantityAndAmounts`, which subtracts refund line quantities and amounts from order lines and the header. Lines that reach zero quantity are deleted.
9. Checks whether the order should auto-close (fulfilled + fully paid + no outstanding quantities on BC sales order).
10. If a Shopify invoice already exists for the order, marks it as processed immediately.

Currency codes from Shopify (ISO format like "USD") are translated to BC currency codes via the Currency table's ISO Code field. If the translated code matches the company's LCY Code, it becomes blank (BC convention for local currency).

## Mapping

`ShpfyOrderMapping.DoMapping` is called both during import (on reimport) and as the first step of processing. It returns a boolean indicating whether all mappings succeeded.

For D2C orders, it tries the customer template for the ship-to country first, then falls back to the shop's default customer. `ShpfyCustomerMapping.DoMapping` handles the actual customer resolution, with an option to auto-create unknown customers. Sell-to and bill-to customer numbers are resolved separately using sell-to and bill-to address data.

For B2B orders, `MapB2BHeaderFields` uses `ShpfyCompanyMapping` and additionally tries to map sell-to/bill-to from the company location record. If the company location has distinct sell-to and bill-to customer numbers configured, they are used independently.

After customer mapping, the method maps shipping method (from shipping charge title to `ShpfyShipmentMethodMapping`), shipping agent (same mapping table), and payment method (from the highest-amount successful transaction's gateway). Payment method mapping skips assignment if multiple distinct payment methods are found.

Line mapping in `MapVariant` resolves each Shopify variant to a BC item and variant code. If the variant is not yet synced, it triggers a product import on the fly. The unit of measure is taken from the variant's UoM option or falls back to the item's sales unit of measure.

## Processing

`ShpfyProcessOrder` orchestrates document creation. It re-runs mapping (which is idempotent) and errors if mapping is incomplete.

The order-vs-invoice decision is simple: if fulfillment status is Fulfilled and the shop has "Create Invoices From Orders" enabled, create an invoice; otherwise create a sales order. `CreateHeaderFromShopifyOrder` builds the sales header with all three address blocks, validates currency based on the shop's currency handling setting, sets document date, external document no. (from PO Number), due date, tax area, shipment method, shipping agent, payment method, and payment terms.

`CreateLinesFromShopifyOrder` iterates order lines. Tips go to the Tip Account G/L, gift cards to Sold Gift Card Account, and everything else becomes an Item line. Location code is resolved from `ShpfyShopLocation` if the line has a Shopify location ID. The currency handling setting determines whether shop currency or presentment currency prices are used.

Shipping charges become separate sales lines after the item lines. Each `ShpfyOrderShippingCharges` record creates a line. If the shipment method mapping defines a specific shipping charges type (G/L Account, Item, or Charge (Item)), that is used; otherwise the shop's default Shipping Charges Account is used. Item charges get auto-assigned to the item lines.

After all lines, `ApplyGlobalDiscounts` computes the difference between the header discount amount and the sum of line-level and shipping-level discounts. Any remainder is applied as an invoice discount.

Cash rounding amounts (from Shopify's `totalCashRoundingAdjustment`) are added as a final G/L line against the Cash Roundings Account.

If the shop has "Auto Release Sales Orders" enabled, the document is released automatically at the end.

## Conflict detection

`IsImportedOrderConflictingExistingOrder` fires only for orders that are already processed and have no prior state error. It checks three conditions, any of which marks the order as conflicting:

1. The current subtotal line items quantity from Shopify is greater than what was stored (items were added).
2. The redundancy hash of line IDs differs (lines were added or removed).
3. The shipping charges amount differs.

Additionally, during refund consideration, if a processed order is cancelled but has no refund lines, or if refund lines exist that are not yet eligible for credit memo creation, the order is marked as conflicting.

A conflicting order gets `Has Order State Error` = true, `Has Error` = true, and a descriptive error message. This prevents the order from being processed again until the conflict is manually resolved.

## Error handling

Processing errors are caught by `ShpfyProcessOrders.ProcessShopifyOrder`, which wraps `ShpfyProcessOrder.Run()` in a conditional. On failure, the partially created sales document is cleaned up via `CleanUpLastCreatedDocument`, and the error message (prefixed with the current time) is stored on the order header. The order remains unprocessed so it can be retried.

Three error-related fields exist on the order header: `Has Error` (general errors during processing), `Error Message` (the text), and `Has Order State Error` (specifically for conflict detection). An order can have both a processing error and a state error simultaneously.
