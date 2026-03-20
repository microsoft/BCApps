# Subscription Billing

Subscription Billing enables selling and managing recurring subscriptions in Business Central. It decouples the physical service being delivered (a Subscription) from the billing agreement (a Contract), allowing flexible combinations of subscription-based, usage-based, and hybrid pricing models. The app integrates deeply with BC sales documents, posting, and G/L, acting as a parallel invoicing engine that creates and posts standard BC invoices/credit memos from contract billing lines.

## Quick reference

- **ID range**: 8000-8113
- **Dependencies**: Power BI Report embeddings for Dynamics 365 Business Central

## How it works

The core abstraction separates three concepts that are often conflated. A **Subscription** (table `Subscription Header`, internally still called "Service Object") represents the physical thing being delivered -- a software license, a maintenance agreement, a piece of equipment. A **Subscription Line** (table `Subscription Line`, internally "Service Commitment") represents a single billing rule attached to that subscription -- its price, billing rhythm, term dates, and contract assignment. A **Contract** (either `Customer Subscription Contract` or `Vendor Subscription Contract`) is the billing vehicle that groups subscription lines for invoicing. One subscription can have lines billed through different contracts, and one contract can contain lines from many subscriptions.

The setup hierarchy flows from templates down to actual billing. A **Subscription Package Line Template** defines billing defaults (invoicing method, calculation base, billing period, usage-based pricing). A **Subscription Package** groups multiple package lines. Packages are assigned to Items, and when an item is sold via a sales document, **Sales Subscription Lines** are auto-created from the item's packages. When the sales order is posted, these become actual Subscription Lines on a Subscription, linked to contracts.

The **Partner enum** (`Service Partner`: Customer or Vendor) is the fundamental branching mechanism. Throughout the app, tables use conditional `TableRelation` based on Partner to point billing lines, contract lines, and usage data at either customer or vendor records. This is not inheritance -- it is conditional logic applied consistently across every table that touches both sides.

Billing follows a pipeline: contract lines feed a **Billing Proposal** (codeunit `Billing Proposal`) which creates `Billing Line` records based on "Next Billing Date". These billing lines are then turned into actual sales/purchase invoices by `Create Billing Documents`. The process can run manually, semi-automatically via billing templates, or fully automated through `Auto Contract Billing` using job queue entries. The `Billing Template` controls grouping (per contract, per customer/vendor), date formulas, and automation level.

**Deferrals** are optional per contract type and per subscription line template. When enabled, posting a contract invoice credits a deferral account instead of revenue. A monthly report (`Contract Deferrals Release`) then releases the deferred amounts to the actual revenue/cost accounts based on a "Post Until Date". **Usage-based billing** is an alternative model where metered consumption data flows in from external suppliers through a multi-stage pipeline (Supplier -> Import -> Generic Import -> Usage Data Billing) and feeds into the normal billing proposal. **Price updates** use template-driven methods (percentage of calculation base, percentage of price, or recent item prices) through a `Contract Price Update` interface, and create **Planned Subscription Lines** when changes cannot take effect immediately. **Contract renewals** generate sales quotes from expiring contract lines, and posting those quotes extends the subscription terms.

## Structure

- Base/ -- Setup tables (`Subscription Contract Setup`, `Subscription Contract Type`), enums (`Service Partner`, `Contract Line Type`), utility codeunits
- Service Objects/ -- `Subscription Header` table, item integration, attribute factboxes
- Service Commitments/ -- `Subscription Line`, `Subscription Package`, `Subscription Package Line`, `Sub. Package Line Template`, archives
- Sales Service Commitments/ -- `Sales Subscription Line` table, posting integration with sales documents, sales report extensions
- Customer Contracts/ -- `Customer Subscription Contract`, `Cust. Sub. Contract Line`, extend-contract workflows, dimension management
- Vendor Contracts/ -- `Vendor Subscription Contract`, `Vend. Sub. Contract Line`
- Billing/ -- `Billing Line`, `Billing Template`, `Billing Proposal` codeunit, `Create Billing Documents`, `Auto Contract Billing`, correction logic
- Deferrals/ -- `Cust. Sub. Contract Deferral`, `Vend. Sub. Contract Deferral`, release report, analysis reports
- Contract Price Update/ -- `Price Update Template`, `Sub. Contr. Price Update Line`, `Contract Price Update` interface, three method implementations
- Contract Renewal/ -- `Sub. Contract Renewal Line`, `Planned Subscription Line`, renewal codeunits, sales quote generation
- Usage Based Billing/ -- `Usage Data Supplier`, `Usage Data Import`, `Usage Data Billing`, generic connector processing, `Usage Data Processing` interface
- Import/ -- Creating subscriptions and contract lines from imported/unassigned subscription lines
- ContractAnalysis/ -- `Sub. Contr. Analysis Entry` for reporting
- Overdue Service Commitments/ -- Query and page for overdue subscription lines
- APIs/ -- API pages for external integration
- Power BI/ -- Embedded Power BI reports

## Documentation

- [docs/data-model.md](docs/data-model.md) -- How tables relate across subscriptions, contracts, and billing
- [docs/business-logic.md](docs/business-logic.md) -- Key processes: billing, price updates, renewals, usage data
- [docs/extensibility.md](docs/extensibility.md) -- 320 integration events organized by customization goal
- [docs/patterns.md](docs/patterns.md) -- Partner-polymorphism, conditional FKs, template hierarchy

## Things to know

- The code still uses "Service Object" and "Service Commitment" in many table and codeunit names, while the official Microsoft docs now use "Subscription" and "Subscription Line". The field captions have been updated but the object names lag behind (e.g., `LookupPageId = "Service Objects"` on `Subscription Header`).
- The `Service Partner` enum (Customer/Vendor) drives conditional `TableRelation` throughout -- `Billing Line`, `Usage Data Billing`, contract line references, and price update lines all switch their foreign keys based on this enum rather than using separate tables.
- A Subscription is decoupled from contracts -- one Subscription can have lines billed through multiple contracts, and a single contract can aggregate lines from many different Subscriptions.
- Subscription items auto-show as "Invoiced on Shipment" even though no sales invoice exists at ship time -- invoicing happens later through the contract billing pipeline, not through the sales document.
- Usage-based billing requires contract invoicing (`Invoicing via` = Contract) and cannot have discounts. It flows through a multi-stage pipeline: Supplier -> Import -> Blob -> Generic Import -> Usage Data Billing -> Billing Line.
- Vendor contract invoicing is NOT automated -- the `Billing Template.Automation` field enforces `Partner = Customer`, so only customer contracts support job-queue-driven billing.
- When a price update cannot take effect immediately (because the update date is after the next billing date, or an unposted document exists), the system creates a `Planned Subscription Line` that stores the future values and activates when the current period ends.
- Deferrals are controlled at three levels: the `Subscription Contract Type` sets the default, the `Sub. Package Line Template` can override it, and the `Create Contract Deferrals` enum (`No`, `Contract-dependent`) determines the final behavior per subscription line.
- The `Billing Template` controls automation level: `None` is manual, `Create Billing Proposal and Documents` is fully automated via job queue. There is no "partial" automation -- it is all or nothing per template.
- Harmonized billing aligns all subscription lines on a customer contract to a common billing date. It is enabled per `Subscription Contract Type` and only applies to customer contracts.
- Contract lines use a "Closed" boolean flag for soft-deletion. Closed lines appear on a separate "Closed Lines" FastTab rather than being deleted, preserving the audit trail and preventing re-billing.
- The `Billing Line."Update Required"` flag detects stale proposals -- when contract data changes after billing lines were created, this flag forces regeneration before documents can be created.
