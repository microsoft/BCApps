# Manufacturing Domain Knowledge

## Production BOMs and Routings

- **Production BOMs** (T99000771) define the component list for a manufactured item. BOMs can be multi-level (components that are themselves manufactured).
- **BOM Versions** allow maintaining multiple active BOMs for different date ranges or production quantities.
- **Routings** (T99000763) define the sequence of operations, each linked to a **Work Center** (T99000754) or **Machine Center** (T99000758).
- **Routing Links** connect BOM components to specific routing operations — this controls when components are consumed (flushing).
- **Scrap %** on BOM lines and routing operations increases required quantities to account for expected waste.

## Production Order Lifecycle

- **Simulated**: For planning and cost estimation — no inventory impact.
- **Firm Planned**: Committed to production, creates demand for components and capacity, but not yet released to shop floor.
- **Released**: Active on the shop floor — consumption and output can be posted.
- **Finished**: All output posted, costs finalized. Finishing triggers remaining cost adjustments.
- **Status change** from Released to Finished posts any remaining expected consumption/output as actual entries.

## Consumption and Output

- **Consumption Journals** (T83) record material usage against production order components.
- **Output Journals** (T83) record finished goods produced and operation time against routing operations.
- **Flushing Methods**: Manual (explicit journal posting), Forward (auto-consume at release), Backward (auto-consume at output), Pick + Forward, Pick + Backward.
- **Expected Cost** entries are created when the production order is released; actual cost entries replace them during consumption/output posting.

## Subcontracting

- **Subcontracting** routes operations to a **Work Center** linked to a vendor.
- Releasing a production order with subcontracted operations creates a **Subcontracting Worksheet** entry.
- The worksheet generates **Purchase Orders** for the subcontracted work — the vendor receives components (if send-ahead) and returns finished goods.

## Assembly Orders vs Production Orders

- **Assembly Orders** (T900/T901) are simpler — they combine components into a parent item without routings or work centers.
- Assembly supports **Assemble-to-Stock** (build to inventory) and **Assemble-to-Order** (build per sales order).
- Assembly does not support multi-level BOMs, operation sequences, or capacity planning.
- Use assembly for simple kitting; use production for complex manufacturing with operations.

## MRP/MPS Planning

- **Planning Worksheets** (T246) calculate material and capacity requirements based on demand (sales orders, forecasts, reorder points).
- **MPS** (Master Production Schedule) plans finished goods; **MRP** (Material Requirements Planning) plans components.
- **Reorder Policies**: Fixed Reorder Qty., Maximum Qty., Order (lot-for-lot), Lot-for-Lot.
- **Dampener** settings prevent trivial replanning (dampener period and dampener quantity).
- **Action Messages**: New, Change Qty., Reschedule, Cancel — these recommend supply adjustments.

## Common Issues

- BOM circular references (item A requires item B which requires item A) causing infinite loops in planning
- Cost roll-up inaccuracies when subcomponent costs change but the parent standard cost is not recalculated
- Planning calculation performance on large datasets with deep BOM structures
- Flushing method timing issues — backward flushing at output can consume components that were not yet available
- Subcontracting purchase order quantity mismatches when production order quantity changes after the PO was created
