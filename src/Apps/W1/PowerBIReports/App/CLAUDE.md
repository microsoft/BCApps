# Power BI Report embeddings for Dynamics 365 Business Central

Provides the BC-side connector for Microsoft's Power BI apps -- out-of-the-box embedded reports covering Finance, Sales, Purchasing, Inventory, Manufacturing, and Projects. This AL app is one half of a two-part system: it exposes BC data via API pages/queries and hosts Power BI reports inline via embedded pages. The other half is a Power BI template app (installed separately from Marketplace) containing the semantic model and report definitions.

## Quick reference

- **ID range**: 36950--37049, 37055--37119
- **Namespace**: `Microsoft.Finance.PowerBIReports`, `Microsoft.Sales.PowerBIReports`, etc. (per domain)
- **Dependencies**: None (uses base application tables directly)

## How it works

The app is organized into 7 domain modules (Core, Finance, Sales, Purchasing, Inventory, Manufacturing, Projects) that all follow the same structure. Each module has an `APIs/` folder with Query and Page objects that expose BC data as OData endpoints, and an `Embedded/` folder with pages that host Power BI reports via the `PowerBIManagement` control add-in.

Data flows in a loop: BC exposes data through API queries/pages -> Power BI pulls data via its Business Central connector -> Power BI builds semantic models and reports -> those reports are embedded back inside BC via iframe. The API queries denormalize BC's normalized data into wide tables optimized for Power BI's columnar model. For example, the `PowerBI Dimension Sets` query pivots up to 8 dimension entries per set into a single flat row.

The app ships a setup table (`PowerBI Reports Setup`) that stores calendar configuration (fiscal year start, first day of week, UTC offset), date ranges for filtering, and per-domain report ID GUIDs. An assisted setup wizard guides users through initial configuration and maps embed pages to Power BI workspace/report pairs. Each domain also adds its own fields to the setup table via table extensions.

Date filtering is a key design concern -- Power BI's data volumes must be controlled. Each domain has a "filter helper" codeunit that generates date filter expressions, applied in the Query's `OnBeforeOpen` trigger. This ensures consistent date range filtering before data reaches Power BI.

## Structure

- `Core/` -- Setup tables, initialization codeunits, dimension caching job, permission sets, 14 role center extensions, and shared API endpoints (dimensions, customers, vendors, items, etc.)
- `Finance/` -- GL-specific APIs (account categories, budgets, income statement, balance sheet), 16 embedded report pages, account category mapping table
- `Sales/` -- Sales order/invoice/customer analytics queries, 22 embedded report pages
- `Purchasing/` -- Purchase order/vendor analytics queries, 19 embedded report pages
- `Inventory/` -- Item ledger, stock level, valuation queries, 18 embedded report pages (split into Inventory/ and Inventory Valuation/ subfolders)
- `Manufacturing/` -- Production order, capacity, routing queries, 17 embedded report pages
- `Projects/` -- Job planning, resource utilization queries, 9 embedded report pages
- `_Obsolete/` -- Deprecated SubscriptionBilling and Sustainability reports (do not use as patterns for new code)

## Documentation

- [docs/data-model.md](docs/data-model.md) -- Setup table, dimension caching, account categories, domain extensions
- [docs/business-logic.md](docs/business-logic.md) -- Installation, dimension caching, embedded page pattern, date filtering

## Things to know

- **Two-part system** -- this AL app alone does nothing visible. Users must also install the Power BI template app from Marketplace and run the "Connect to Power BI" assisted setup to map reports.
- **Every domain follows the same pattern** -- APIs/ folder for data exposure, Embedded/ folder for report containers, a filter helper codeunit, and a table extension on `PowerBI Reports Setup`. Understanding one domain means understanding all of them.
- **Embedded pages are thin containers** -- they just host a Power BI iframe via `PowerBIManagement` control add-in. The actual report logic, visuals, and measures live in the Power BI template app, not here.
- **Queries denormalize aggressively** -- API queries flatten BC's normalized data model (joins, left outer joins, calculated fields) into wide tables. This is intentional -- Power BI's columnar engine prefers wide denormalized tables over normalized joins.
- **Dimension set caching runs hourly** -- `UpdateDimSetEntries` codeunit flattens the M:M dimension set entries into an 8-column wide table (`PowerBI Flat Dim. Set Entry`). Uses `SystemModifiedAt` delta tracking to avoid full table scans.
- **Date filtering at query level** -- each domain's filter helper generates filter expressions applied in `OnBeforeOpen`. This prevents Power BI from pulling unbounded date ranges of transactional data.
- **Per-company setup** -- the Power BI template app must be installed per company. Multi-company environments need separate Power BI workspaces per company.
- **14 role centers extended** -- role center page extensions add Power BI embedded parts to Administrator, Finance Manager, Sales Manager, Purchasing Agent, Warehouse Manager, Production Planner, Project Manager, and more.
- **_Obsolete/ is not dead code** -- it contains deprecated objects with `ObsoleteState` attributes. They exist for backwards compatibility during upgrade and should not be used as patterns for new modules.
- **Account Category mapping (Finance only)** -- `FinanceInstallationHandler` populates 25 GL account hierarchy mappings (L1/L2/L3 Assets, Liabilities, etc.) on install, enabling chart-of-accounts rollup in Power BI.
