# Warehouse Domain Knowledge

## Basic vs Advanced Warehouse Management

- **Basic warehouse**: Uses Inventory Picks, Inventory Put-aways, and Inventory Movements. No bin-level tracking or warehouse documents.
- **Advanced warehouse** (Directed Put-away and Pick): Full bin management with zones, bin types, warehouse classes, and dedicated warehouse documents.
- The warehouse complexity level is configured per **Location** — different locations can use different levels.
- The **Location Card** settings (Require Receive, Require Shipment, Require Pick, Require Put-away, Directed Put-away and Pick) determine which warehouse features are active.

## Directed Put-Away and Pick

- **Bins** (T7354) are the smallest storage units, organized into **Zones** (T7300) with **Bin Types** (T7303).
- **Warehouse Classes** restrict which items can be stored in which bins (e.g., refrigerated, hazardous).
- **Put-Away Templates** define the logic for suggesting bins during put-away (by zone, bin type, fixed bin, floating bin).
- **Bin Content** (T7302) tracks what items are in each bin and supports fixed vs. floating assignment.
- **ADCS** (Automated Data Capture System) supports barcode scanning for warehouse operations.

## Warehouse Documents

- **Warehouse Receipt** (T7316/T7317) — receives goods from purchase orders, transfer orders, or production output.
- **Warehouse Shipment** (T7320/T7321) — ships goods for sales orders, transfer orders, or service orders.
- **Warehouse Pick** (T7342/T7344) — instructs warehouse workers which bins to pick from for a shipment.
- **Warehouse Put-Away** (T7340/T7341) — instructs workers where to store received goods.
- **Warehouse Movement** — relocates items between bins without document linkage.
- **Internal Pick / Internal Put-Away** — warehouse-initiated movements not tied to source documents.

## Integration with Source Documents

- Sales/purchase/transfer documents create **Warehouse Requests** that appear in the warehouse receipt or shipment list.
- Posting a warehouse receipt creates **Posted Whse. Receipt** and updates the source document's **Qty. Received** (for purchases).
- Posting a warehouse shipment updates the source document's **Qty. Shipped** (for sales).
- **Breakbulk** splits units of measure during pick (e.g., pick individual items from a case).

## Common Issues

- Bin capacity exceeded errors when put-away template suggests a bin that is already full
- Pick errors when reserved items are in bins that are not in the pick zone
- Partial warehouse receipt/shipment posting conflicts with source document quantities
- Warehouse class mismatch preventing items from being placed in suggested bins
- Performance issues with large bin content tables when calculating available quantity per bin
- Directed put-away and pick zone/bin configuration errors causing items to be placed in wrong areas
