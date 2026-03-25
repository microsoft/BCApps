# Sales Domain Knowledge

## Order-to-Cash Flow

- **Full flow**: Sales Quote -> Sales Order -> Warehouse Shipment -> Sales Invoice -> Payment -> Customer Ledger Entry -> G/L Entry
- **Status transitions**: Open -> Released -> Pending Prepayment -> Pending Approval. Only Released documents can be posted.
- **Posting options**: Ship only, Invoice only, or Ship and Invoice simultaneously.

## Combine Shipments and Blanket Orders

- **Combine Shipments** batch job merges multiple posted shipments into a single invoice per customer.
- **Blanket Orders** are framework agreements — sales orders are created from blanket order lines with **Qty. to Ship** controlling each release.
- **Drop Shipments** link a sales order directly to a purchase order — the item ships from vendor to customer without passing through inventory.
- **Special Orders** are similar but the item passes through your warehouse.

## Assemble-to-Order

- When a sales line references an item with an **Assembly BOM** and the **Assembly Policy** is "Assemble-to-Order", an assembly order is automatically created and linked.
- The assembly order consumes components and produces the parent item just-in-time for shipment.
- **ATO lines** are tightly coupled — changes to the sales line quantity or shipment date cascade to the assembly order.

## Credit Memos and Return Orders

- **Sales Credit Memos** reverse posted invoices — they can copy from posted invoice lines using **Copy Document**.
- **Sales Return Orders** handle physical returns with **Return Reason Codes** and optional warehouse receipt processing.
- **Exact Cost Reversing** links the credit/return to the original item ledger entry to reverse at the same cost.

## Key Tables

- **Sales Header** (T36) — document header with Sell-to/Bill-to customer, dates, currency, dimensions
- **Sales Line** (T37) — line details with item/resource/G-L, quantities, amounts, dimensions
- **Sales Shipment Header** (T110) / **Sales Shipment Line** (T111) — posted shipment records
- **Sales Invoice Header** (T112) / **Sales Invoice Line** (T113) — posted invoice records
- **Sales Cr.Memo Header** (T114) / **Sales Cr.Memo Line** (T115) — posted credit memos

## Pricing and Discounts

- **Price Lists** (T7000+) define prices per customer, customer group, campaign, or "all customers".
- **Line Discounts** and **Invoice Discounts** are separate mechanisms — line discounts are per-line, invoice discounts are calculated on the total amount.
- **Price Calculation** method (Lowest Price vs. Price Priority) determines which price list wins when multiple apply.

## Service and CRM Integration

- **Service Orders** follow a similar flow to sales but add service item tracking, fault/resolution codes, and technician dispatch.
- **Service Contracts** generate periodic invoices and are linked to service items for warranty and entitlement tracking.
- **CRM Contacts** link to customers via Business Relations — opportunity pipeline feeds into sales quotes and orders.

## Common Issues

- Shipment/invoice quantity mismatches when using Combine Shipments with partially shipped orders
- Discount calculation errors when both line discount and invoice discount apply simultaneously
- Dimension inheritance failures — dimensions from customer, item, and G/L account may conflict on sales lines
- Assemble-to-order synchronization issues when modifying sales line quantities after partial shipment
- Credit memo posting errors when the original invoice was applied to a payment
