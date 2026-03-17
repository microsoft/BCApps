# Order handling

This module is the core order processing engine. It imports Shopify orders into BC, maps them to customers and items, and creates sales documents. Every order passes through a three-stage pipeline -- import, mapping, processing -- before it becomes a BC sales order or invoice.

## How it works

`ShpfyImportOrder` retrieves order JSON via GraphQL, populates `ShpfyOrderHeader` and `ShpfyOrderLine` records, pulls in related data (shipping charges, transactions, fulfillments, returns, refunds), then considers refunds against line quantities and checks whether the order should auto-close. The `ShpfyOrdersToImport` table acts as the inbound queue -- webhooks, manual sync, and job queues all feed into it.

`ShpfyOrderMapping.DoMapping` resolves Shopify data to BC master data: customer (or company for B2B), shipment method, shipping agent, and payment method. For lines, it maps Shopify variants to BC items, falling back to a product import if the variant is unknown. B2B orders take a separate path through `MapB2BHeaderFields` that resolves company locations to sell-to/bill-to customer numbers.

`ShpfyProcessOrder` creates the actual BC sales document. If the order is already fulfilled and the shop has "Create Invoices From Orders" enabled, it creates a Sales Invoice; otherwise a Sales Order. It copies the triple address set (sell-to, ship-to, bill-to), applies currency handling, adds item lines, shipping charge lines, and global discount balancing via `SalesCalcDiscountByType`. It optionally auto-releases.

## Things to know

- Every monetary field exists in two flavors: shop currency (`Unit Price`, `Total Amount`) and presentment currency (`Presentment Unit Price`, `Presentment Total Amount`). The shop's "Currency Handling" setting controls which set flows into BC sales lines.
- Conflict detection fires when a processed order is re-imported and the line items hash (`Line Items Redundancy Code`), current subtotal quantity, or shipping charges amount differs from what was originally processed. Conflicting orders get `Has Order State Error` set to true.
- Refund quantities are subtracted from order line quantities during import in `ConsiderRefundsInQuantityAndAmounts`. Lines that net to zero quantity are deleted. This means the order header amounts reflect the post-refund state.
- The order header carries three complete address blocks (sell-to, ship-to, bill-to), each parsed from different JSON paths: `displayAddress`, `shippingAddress`, `billingAddress`.
- B2B orders populate `Company Id`, `Company Location Id`, `PO Number`, `Payment Terms Type/Name`, and `Due Date` from the `purchasingEntity` JSON node. The PO Number flows to `External Document No.` on the sales header.
- Auto-close sends a GraphQL `orderClose` mutation when the order is fulfilled, fully paid, and has no outstanding sales order quantities. The shop must have "Archive Processed Orders" enabled.
- Tips and gift cards are not mapped to items -- they route to G/L accounts configured on the shop (`Tip Account`, `Sold Gift Card Account`).
