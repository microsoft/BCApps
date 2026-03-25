# Inventory Domain Knowledge

## Item Types and Costing Methods

- **Item Types**: Inventory (tracked in stock), Non-Inventory (expensed on purchase), Service (no physical tracking).
- **Costing Methods** determine how item cost is calculated:
  - **FIFO**: First in, first out — oldest cost applied first
  - **LIFO**: Last in, first out — newest cost applied first
  - **Average**: Weighted average cost recalculated on each inbound entry
  - **Standard**: Fixed cost from Item Card; variances posted to variance accounts
  - **Specific**: Cost tracked per serial/lot number — requires item tracking
- The **Unit Cost** on the Item Card may differ from actual ledger costs depending on the costing method and whether cost adjustment has run.

## Item Tracking

- **Serial Numbers**, **Lot Numbers**, and **Package Numbers** are enforced via **Item Tracking Codes** (T6502).
- Tracking codes define rules: SN/Lot required on inbound, outbound, or both. **SN Warehouse Tracking** vs **SN Specific Tracking** control granularity.
- **Item Tracking Lines** (T337/T336) link to document lines and reservation entries.
- Tracking must balance — the total tracked quantity must equal the document line quantity before posting.
- **Undoing** posted receipts/shipments with item tracking requires reversing specific tracking entries, which is error-prone.

## Reservations

- **Reservations** (T337) link specific supply to specific demand — e.g., a purchase order line reserved for a sales order line.
- **Auto-Reserve** can be configured per item to automatically link supply when demand is created.
- Reservation binding: **Order-to-Order** locks a 1:1 relationship; loose reservations allow flexible fulfillment.
- Reservations interact with **Item Availability** calculations — reserved quantities reduce available inventory for other demands.
- **Conflicts** arise when a reservation references supply that gets deleted, reduced, or rescheduled.

## Cost Adjustment

- **Adjust Cost - Item Entries** batch job (Report 795) reconciles expected costs with actual costs.
- It processes **Value Entries** (T5802) and creates adjustment entries to correct costs for: purchase invoice variances, revaluation, rounding, and output cost differences.
- **Performance** is a major concern for large datasets — the batch job can take hours if item ledger entries and value entries tables are large.
- **Post Inventory Cost to G/L** (Report 1002) creates G/L entries from value entries that haven't been posted to G/L yet.
- **Automatic Cost Posting** setting controls whether value entries post to G/L immediately or require the batch job.

## Transfer Orders

- **Transfer Orders** (T5740/T5741) move inventory between **Locations**.
- Posting creates **Transfer Shipment** and **Transfer Receipt** documents.
- **In-Transit** location tracks goods during transfer — the item is in neither source nor destination until receipt is posted.
- **Direct Transfer** skips the in-transit step for same-warehouse or logical transfers.

## Item Availability

- Availability is calculated as: **Inventory + Planned Receipts - Planned Shipments - Reserved Qty.**
- **Available to Promise** (ATP) and **Capable to Promise** (CTP) provide delivery date calculations considering supply chain lead times.
- **Stockkeeping Units** (T5700) allow location-specific and variant-specific inventory parameters (reorder point, reorder quantity, lead time).

## Common Issues

- Cost adjustment batch job performance degradation on databases with millions of value entries
- Item tracking conflicts when posting partial shipments — tracked quantity must match line quantity
- Reservation vs. availability mismatches when auto-reserve creates conflicting links
- Transfer order posting errors when in-transit location dimensions differ from source/destination
- Average cost calculation anomalies when backdating inbound entries before existing outbound entries
