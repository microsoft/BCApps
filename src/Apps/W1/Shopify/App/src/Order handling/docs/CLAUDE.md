# Order handling module

Imports Shopify orders into Business Central as staging records, maps customers/items/shipping, and creates BC Sales Orders or Sales Invoices.

## Quick reference

- Orders flow through three stages: fetch to-import list, import full details, process into BC documents
- Entry point for fetching: `Shpfy Orders API` (codeunit 30165) populates `Shpfy Orders to Import`
- Entry point for importing: `Shpfy Import Order` (codeunit 30161) creates `Shpfy Order Header` and lines
- Entry point for processing: `Shpfy Process Order` (codeunit 30166) creates BC `Sales Header` and `Sales Line`
- Fulfilled orders create Sales Invoices; unfulfilled orders create Sales Orders

## Structure

```
Order handling/
  Codeunits/
    ShpfyOrdersAPI           -- Fetches order list from Shopify GraphQL API
    ShpfyImportOrder         -- Imports a single order's full details
    ShpfyProcessOrder        -- Creates BC Sales Order/Invoice from staging data
    ShpfyProcessOrders       -- Batch processor for unprocessed orders
    ShpfyOrderMapping        -- Maps customers, items, shipping, payment methods
    ShpfyOrderMgt            -- Tax area lookup, Shopify order navigation
    ShpfyOrderEvents         -- Integration events for extensibility
    ShpfyOrders              -- Helper codeunit
    ShpfyCopySalesDocument   -- Handles document copying scenarios
    ShpfySuppressAsmWarning  -- Suppresses assembly warnings during line creation
  Tables/
    ShpfyOrderHeader         -- Shopify order staging header (ID 30118)
    ShpfyOrderLine           -- Shopify order line (ID 30119)
    ShpfyOrderTaxLine        -- Tax lines per order/line (ID 30122)
    ShpfyOrdersToImport      -- Lightweight order queue (ID 30121)
    ShpfyOrderAttribute      -- Key-value order attributes
    ShpfyOrderLineAttribute  -- Key-value line attributes
    ShpfyOrderDiscAppl       -- Discount applications
    ShpfyOrderPaymentGateway -- Payment gateway info
  Enums/
    ShpfyFinancialStatus     -- Pending, Authorized, Partially Paid, Paid, etc.
    ShpfyCancelReason         -- Customer, Fraud, Inventory, Other, Staff, Declined
    ShpfyCurrencyHandling     -- Shop Currency, Presentment Currency
    ShpfyShipmentStatus, ShpfyAllocationMethod, ShpfyProcessingMethod,
    ShpfyTargetSelection, ShpfyTargetType, ShpfyValueType,
    ShpfyOrderPurchasingEntity, ShpfyTrackingCompanies
  Pages/
    ShpfyOrder, ShpfyOrders, ShpfyOrderSubform, ShpfyOrdersToImport,
    ShpfyOrderAttributes, ShpfyOrderLinesAttributes,
    ShpfyOrderTaxLines, ShpfyOrderTotalsFactBox, ShpfyCancelOrder
```

## Documentation

- [implementation.md](implementation.md) -- Import pipeline, data model, processing flow, and extensibility

## Key concepts

- **Three-stage pipeline**: fetch IDs -> import details -> process to BC documents
- **Staging model**: Shopify data is stored in dedicated tables before BC document creation
- **Customer mapping**: Resolves Shopify customers/companies to BC Customer No. with auto-creation support
- **Currency handling**: Configurable to use either shop currency or presentment (customer-facing) currency
- **B2B support**: Company orders map via `Shpfy Company` rather than individual customer
