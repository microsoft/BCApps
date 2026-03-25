# Business Central Functional Domain Knowledge

Use this reference to understand the business processes, module relationships, and common issue patterns in Microsoft Dynamics 365 Business Central. This knowledge is essential for accurate triage — understanding what a user is actually trying to do, which modules are involved, and what the downstream impacts are.

## Core Business Processes

### Procure-to-Pay (Purchasing)
The full cycle: **Requisition -> Purchase Quote -> Purchase Order -> Warehouse Receipt -> Purchase Invoice -> Payment -> Vendor Ledger Entry -> G/L Entry**.

Key concepts:
- **Purchase documents** progress through a status lifecycle: Open -> Released -> Pending Prepayment -> Pending Approval
- **Receiving** and **invoicing** can be split (receive goods now, invoice later)
- **Prepayments** require invoicing a percentage before shipment
- **Purchase prices / discounts** are managed via price lists (modern) or the legacy price/discount tables
- **Item charges** distribute landed costs (freight, insurance) across received items
- **Partial posting** allows receiving/invoicing a subset of lines
- **Over-receipt** tolerance lets warehouses accept more than ordered within configured limits
- Common issues: posting errors on partially received orders, prepayment rounding, price calculation mismatches, document dimension conflicts

### Order-to-Cash (Sales)
The full cycle: **Sales Quote -> Sales Order -> Warehouse Shipment -> Sales Invoice -> Payment -> Customer Ledger Entry -> G/L Entry**.

Key concepts:
- **Combine shipments** merges multiple shipments into one invoice
- **Blanket orders** are framework agreements with scheduled deliveries
- **Drop shipments** and **special orders** link sales directly to purchase orders
- **Sales prices / discounts** use the same price list infrastructure as purchasing
- **Assemble-to-order** triggers assembly when a sales line is for a BOM item
- **Credit memos** reverse invoices; **return orders** handle physical returns
- Common issues: shipment/invoice mismatch, incorrect discount calculation, dimension inheritance from customer/item to document lines

### Financial Management
- **Chart of Accounts** defines the G/L structure; accounts have categories and subcategories for financial reporting
- **General Journals** are the freeform posting mechanism (payment journals, cash receipt journals are specialized)
- **Recurring Journals** automate periodic entries (allocations, accruals)
- **Applying entries** links payments to invoices (or credits to debits). This is a critical concept — application affects remaining amounts, discount eligibility, and exchange rate adjustments
- **Bank Reconciliation** matches bank statement lines to bank account ledger entries
- **Intercompany** transactions post mirror documents in partner companies
- **Consolidation** combines financial data from multiple companies
- **Deferrals** spread revenue/cost recognition over multiple periods using deferral templates
- **VAT** can be calculated as percentage, reverse charge, or full VAT; VAT entries link to G/L entries
- Common issues: rounding differences in multi-currency scenarios, applying entries across fiscal years, VAT calculation in prepayment chains, bank reconciliation matching failures

### Inventory & Warehouse
- **Item types**: Inventory (physical), Non-Inventory (expensed), Service
- **Item Tracking** uses serial numbers, lot numbers, and package numbers; tracking is enforced via Item Tracking Codes
- **Reservations** link supply to demand (e.g., reserve purchase receipt for a sales order)
- **Costing methods**: FIFO, LIFO, Average, Standard, Specific — the **Adjust Cost - Item Entries** batch job reconciles expected vs. actual costs
- **Warehouse Management** has basic (inventory picks/put-aways) and advanced (directed put-away/pick with bins, zones, and warehouse classes) modes
- **Transfer Orders** move inventory between locations
- **Item Availability** checks consider inventory, planned receipts, planned shipments, and reservations
- Common issues: cost adjustment performance on large datasets, item tracking conflicts during posting, warehouse bin capacity, reservation vs. availability mismatches

### Manufacturing & Assembly
- **Production BOMs** define component lists; **Routing** defines operation sequences with work/machine centers
- **Production Orders** go through: Simulated -> Firm Planned -> Released -> Finished
- **Consumption** and **Output** journals record material usage and finished goods
- **Subcontracting** routes operations to vendor work centers, creating purchase orders
- **Assembly Orders** are simpler than production — they assemble components into a parent item without routings
- **Planning Worksheets** calculate material requirements (MRP/MPS) based on demand forecasts, sales orders, and reorder policies
- Common issues: BOM circular references, cost roll-up inaccuracies, planning calculation performance, flushing method timing

### Service Management
- **Service Items** track customer equipment with contracts and warranty
- **Service Orders** schedule and dispatch technicians; they have allocation entries for resource planning
- **Service Contracts** generate periodic invoices and track entitlements
- Common issues: contract renewal pricing, service order status transitions, resource allocation conflicts

### CRM
- **Contacts** (persons and companies) link to Customers/Vendors via Business Relations
- **Opportunities** track sales pipeline with stages and estimated close dates
- **Campaigns** and **Segments** manage marketing activities
- **Interactions** log communication history (emails, calls, meetings)

### Project Management (Jobs)
- **Jobs** have a task hierarchy with planning lines that define budget and billable work
- **Job Journals** post usage (resources, items, G/L) against tasks
- **Job WIP** (Work in Progress) methods recognize revenue for long-running projects
- Common issues: WIP calculation method changes mid-project, job planning line vs. job journal line discrepancies

## Cross-Cutting Concepts

### Dimensions
Dimensions are analytical tags attached to every transaction. They flow through the entire posting pipeline:
- **Default Dimensions** are set on master data (customer, vendor, item, G/L account) with rules: Code Mandatory, Same Code, No Code, or blank
- **Dimension Combinations** block or limit which dimension values can be used together
- During posting, dimensions from header, lines, and master data are merged. Conflicts produce **Dimension Set Entries** errors — one of the most common user complaints
- Dimensions affect **analysis views**, **account schedules/financial reports**, and **consolidation**
- Any change to dimension logic has wide blast radius across all document types

### Posting Pipeline
When a document is posted, BC executes a complex sequence:
1. Validate header and lines (checks dimensions, amounts, quantities, number series)
2. Create posted document (e.g., Posted Sales Invoice)
3. Create ledger entries (Customer/Vendor/Item/G/L/VAT/etc.)
4. Update document status and related records
5. Trigger integration events for extensions

Key tables: Gen. Journal Line (T81), G/L Entry (T17), Cust. Ledger Entry (T21), Vendor Ledger Entry (T25), Item Ledger Entry (T32), Value Entry (T5802), VAT Entry (T254)

Changes to posting codeunits (80/81/90/91 series) are always high-risk.

### Number Series
Every document type uses number series for auto-numbering. Number series can have:
- **Lines** with date ranges for fiscal-year-specific numbering
- **Relationships** linking related series (e.g., posted invoice numbers derived from order numbers)
- **Manual numbering** overrides for special cases

### Approval Workflows
BC has built-in approval workflows for purchases, sales, payments, and journal batches. These use:
- **Approval Templates** defining who approves and amount limits
- **Workflow** engine with conditions, responses, and event/response combinations
- Status changes (Open -> Pending Approval -> Released) gate posting

### Reporting & Analytics
- **Account Schedules / Financial Reports** are configurable financial statements
- **Analysis Views** aggregate dimension-tagged entries for multidimensional analysis
- **Power BI** embedded reports use BC APIs for real-time data
- **Excel Reports** use AL report datasets exported to Excel layouts

### Integration Points
- **APIs** (v2.0) expose entities as REST endpoints; custom API pages extend this
- **Dataverse** integration syncs data bidirectionally with Dynamics 365 CE
- **E-Documents** handle structured electronic invoicing (PEPPOL, local formats)
- **Job Queue** runs background tasks on schedule; failures are a common support topic

## Common Issue Patterns and What They Really Mean

| User says | They likely mean | Affected area |
|-----------|-----------------|---------------|
| "posting error" | Dimension conflict, number series gap, or validation failure | Posting pipeline, dimensions |
| "wrong amount" | Rounding, currency exchange, discount calculation, or cost adjustment | Finance, costing, pricing |
| "can't apply" | Entry application conflict, closed entry, or different currencies | Customer/vendor ledger entries |
| "slow performance" | FlowField recalculation, large ledger table scans, or cost adjustment batch | Performance, indexing |
| "missing field on page" | Page extension needed, or field exists but not visible in personalization | UI, page design |
| "approval stuck" | Workflow misconfiguration, missing approver, or status transition issue | Approval workflows |
| "dimensions error" | Default dimension conflict between master data sources during posting | Dimensions, posting |
| "item tracking" | Serial/lot number enforcement, tracking mismatch, or undoing tracked entries | Item tracking, warehouse |
| "reservation problem" | Supply/demand mismatch, firm planned vs. actual, or auto-reserve conflicts | Planning, availability |
| "number series" | Gaps, exhausted series, date range issues, or missing relationships | Number series config |
| "integration fails" | API field mapping, Dataverse sync conflict, or job queue error | Integration, APIs |

## Module Dependency Map

Understanding which modules affect each other is critical for risk assessment:

```
Finance (G/L, Dimensions, VAT)
  |-- Purchasing -> Inventory -> Costing
  |-- Sales -> Inventory -> Costing
  |-- Bank & Cash Management
  |-- Fixed Assets
  |-- Intercompany
  |
Inventory
  |-- Warehouse Management (basic or advanced)
  |-- Item Tracking (serial/lot/package)
  |-- Manufacturing -> Production BOMs, Routings
  |-- Assembly -> Assembly BOMs
  |-- Planning (MRP/MPS)
  |
CRM -> Sales (Contacts -> Customers)
Service Management -> Inventory, Finance
Jobs/Projects -> Resources, Items, Finance
```

A change in Finance/Posting affects nearly everything. A change in Warehouse affects Inventory, Sales, and Purchasing. A change in CRM only affects Sales and Contacts.
