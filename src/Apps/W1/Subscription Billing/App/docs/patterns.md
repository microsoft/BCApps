# Patterns

## Partner-polymorphism via enum

The `Service Partner` enum (8053) has two values: `Customer` and `Vendor`. This single enum drives the entire app's dual-nature behavior. Rather than using inheritance or separate table hierarchies for customer vs. vendor operations, every shared table carries a Partner field and uses conditional `TableRelation` to point at the correct target.

For example, in `BillingLine.Table.al`:

```
field(10; "Partner No."; Code[20])
{
    TableRelation = if (Partner = const(Customer)) Customer else
    if (Partner = const(Vendor)) Vendor;
}
field(20; "Subscription Contract No."; Code[20])
{
    TableRelation = if (Partner = const(Customer)) "Customer Subscription Contract" else
    if (Partner = const(Vendor)) "Vendor Subscription Contract";
}
```

This pattern repeats in `Billing Line`, `Usage Data Billing`, `Sub. Contr. Price Update Line`, `Sub. Contract Renewal Line`, `Subscription Line`, and `Subscription Package Line`. The practical consequence is that all queries against these tables must always include a Partner filter -- without it, foreign key lookups become ambiguous.

The enum is explicitly `Extensible = false`, which means third-party extensions cannot add new partner types. The Customer/Vendor duality is baked into the architecture.

This pattern trades simplicity of schema (one table instead of two) for complexity of logic (every operation must branch on Partner). The billing codeunits (`CreateBillingDocuments`, `BillingProposal`) have explicit `case BillingLine.Partner of` blocks that duplicate logic for each partner type.

## Conditional foreign keys

A natural consequence of partner-polymorphism. The `Billing Line` table is the best example -- a single table serves both customer and vendor billing. Its `Document No.` field has a four-way conditional `TableRelation`:

```
TableRelation =
    if ("Document Type" = const(Invoice), Partner = const(Customer)) "Sales Header"
    else if ("Document Type" = const("Credit Memo"), Partner = const(Customer)) "Sales Header"
    else if ("Document Type" = const("Credit Memo"), Partner = const(Vendor)) "Purchase Header"
    else if ("Document Type" = const(Invoice), Partner = const(Vendor)) "Purchase Header";
```

This is a common BC pattern but used more extensively here than in most apps. The `Subscription Line` table also uses it for `Subscription Contract No.` and `Subscription Contract Line No.`, switching between customer and vendor contract tables.

## Template hierarchy

The configuration flows through four levels, each adding context and allowing overrides:

1. **Sub. Package Line Template** (8054) -- defines billing defaults: invoicing via (Sales/Contract), invoicing item, calculation base type and percentage, billing base period, discount flag, deferral settings, usage-based billing settings
2. **Subscription Package Line** (8056) -- references a template and adds Partner, billing rhythm, and can override any template field
3. **Sales Subscription Line** -- created from package lines when an item is sold, adds sales-specific context (customer pricing, quantities, line-specific overrides)
4. **Subscription Line** (8059) -- the final record, carries all accumulated values plus runtime state (next billing date, contract assignment, term dates)

The cascade works by copying fields down. `SubscriptionPackageLine.Template.OnValidate` copies all fields from the template. `SalesSubscriptionLineMgmt.InsertSalesServiceCommitmentFromServiceCommitmentPackage` copies fields from the package line. Each level can modify the copied values.

The key design decision: the subscription line is the source of truth, not the template. Once values cascade down, changes to the template do not propagate to existing subscription lines. This is intentional -- live billing data must be stable.

## Planned subscription lines

When a change to a subscription line cannot take effect immediately (because an unposted document exists, the change date is after the next billing date, or the next billing date is before the next price update), the system creates a `Planned Subscription Line` (8002) instead of modifying the current line.

`PlannedSubscriptionLine` has the same field structure as `Subscription Line` (created via `TransferFields`). It stores the future values along with a `Type Of Update` enum (`Price Update` or `Contract Renewal`) and a `Perform Update On` date.

The planned line activates when the current billing period completes. `ProcessPriceUpdate.Codeunit.al` checks three conditions in `ShouldPlannedServiceCommitmentBeCreated`:

- Is the "Perform Update On" date after the subscription line's next billing date?
- Does an unposted document exist for this subscription line?
- Is the next billing date before the next price update date?

If any are true, a planned line is created rather than direct modification. This prevents mid-period pricing changes that would create inconsistencies between billed and unbilled amounts.

The `Subscription Line` table has a `Planned Sub. Line exists` FlowField (CalcFormula exists check against `Planned Subscription Line`) that acts as a guard -- many operations check this flag and refuse to proceed if a planned line already exists.

## Soft-delete pattern

Contract lines (`Cust. Sub. Contract Line`, `Vend. Sub. Contract Line`) are never physically deleted during normal operation. Instead, they have a `Closed` boolean field. When a subscription line's billing is complete or the line is terminated, the contract line is marked as Closed.

Closed lines appear on a separate "Closed Lines" FastTab on the contract page (via `ClosedCustContLineSubp.Page.al`) and are filtered out of the active lines subpage. This preserves the complete billing history and prevents gaps in audit trails.

The `Cust. Sub. Contract Line` table's `CheckAndDisconnectContractLine` method handles the disconnection logic when line type or item changes, but the physical record persists.

## Dual-customer model

`Subscription Header` carries two customer references:

- **End-User Customer No.** (field 2) -- the customer who uses the service. Drives the subscription's address, ship-to code, and salesperson. Displayed as "Customer No." in the UI.
- **Bill-to Customer No.** (field 4) -- the customer who receives invoices. Copied from the End-User Customer's `Bill-to Customer No.` if one is set.

This mirrors BC's sales document pattern (Sell-to vs. Bill-to) but is independent of it. The contract also has its own Sell-to/Bill-to pair, creating a three-level customer chain: Subscription End-User -> Contract Sell-to -> Contract Bill-to. In practice, these are often the same customer, but the model supports scenarios where they differ.

When the End-User Customer changes, the system checks whether subscription lines are linked to contracts and forces confirmation. It also recalculates pricing since customer price groups may differ.

## Hash/update-required pattern

The `Billing Line` table has an `Update Required` boolean field. This flags billing lines that have become stale because the underlying contract or subscription data changed after the billing proposal was created.

When `CreateBillingProposal` runs, it first calls `DeleteUpdateRequiredBillingLines` to clear any flagged lines, then recreates them with current data. The `Update Required` flag prevents users from creating documents from stale billing lines -- the flag must be cleared (by regenerating the proposal) before `CreateBillingDocuments` will process them.

This pattern avoids the complexity of detecting what changed and patching billing lines. Instead, it invalidates and regenerates. The UI shows flagged lines prominently so users know to regenerate.

## Interface-based strategy pattern

Two interfaces enable pluggable algorithms:

**Contract Price Update** (`ContractPriceUpdate.Interface.al`) -- implemented by the `Price Update Method` enum (8003) with three implementations: `Calculation Base By Perc`, `Price By Percent`, and `Recent Item Price`. The enum uses AL's `implements` keyword to bind interface methods to specific codeunits. This is clean and follows BC's recommended pattern for extensible business logic.

**Usage Data Processing** (`UsageDataProcessing.Interface.al`) -- implemented by the `Usage Data Supplier Type` enum. Allows different supplier connectors to define how raw usage data is imported and processed. The `Generic` type provides a built-in implementation via `GenericConnectorProcessing.Codeunit.al`.

Both interfaces use the enum-implements pattern rather than subscriber-based extensibility. This means extending the set of implementations requires extending the enum (which is extensible, unlike `Service Partner`).

## Legacy terminology

Throughout the codebase, internal object names use the old terminology while captions and external-facing text use the new:

- Table name `Subscription Header`, old page name `"Service Objects"`, caption `'Subscription'`
- Table name `Subscription Line`, old page name `"Service Commitments List"`, caption `'Subscription Line'`
- Template table `Sub. Package Line Template`, old page name `"Service Commitment Templates"`
- Package table `Subscription Package`, old page name `"Service Commitment Packages"`

This split happened because table names in AL cannot change after publishing (they are the object identity), but captions and documentation can. Anyone searching the codebase should search for both naming conventions.

## Event parameter conventions

Most events pass the full record by reference (`var`), allowing subscribers to modify it. Some events also pass an `IsHandled` boolean that, when set to true, skips the publisher's default logic. This follows the standard BC event pattern but is used inconsistently -- some operations have comprehensive IsHandled support while others do not.

Several large tables (`Customer Subscription Contract`, `Subscription Header`) publish events on nearly every field validation, which is thorough but creates a large surface area. In contrast, some important operations (like billing line amount calculation) have fewer hook points.
