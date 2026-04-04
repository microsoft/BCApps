# Customer contracts

Customer contracts are the sell-side contract entity in Subscription Billing.
Each contract groups subscription lines that share billing terms for a single
customer.

## Core tables

**CustomerSubscriptionContract (8052)** is the header. It stores sell-to and
bill-to customer addresses, ship-to address, payment terms, currency, salesperson,
and dimensions. It follows the standard BC sell-to / bill-to pattern where
changing the bill-to customer cascades payment, currency, and dimension defaults.
The table publishes roughly 50 IntegrationEvents -- by far the largest
extensibility surface in the app. See `extensibility.md` for a grouped
breakdown.

**CustSubContractLine (8062)** links to exactly one Subscription Line (via
`Subscription Line Entry No.`). Key behaviors:

- Lines are **soft-deleted** using the `Closed` flag, not physically removed.
  Deletion is blocked when unreleased contract deferrals exist
  (`ErrorIfUnreleasedCustSubContractDeferralExists`).
- The FlowField `Planned Sub. Line exists` checks for pending renewal or
  price-update entries in `Planned Subscription Line`.
- `CreateServiceObjectWithServiceCommitment()` auto-creates a Subscription
  Header + Subscription Line when a user enters an Item or G/L Account on
  a manual contract line.
- Merging contract lines consolidates quantities into a new Subscription
  Header, closes the old lines, and re-assigns the new Subscription Line.
  Merge requires matching dimensions, Next Billing Date, and Customer Reference.

## Contract types and harmonized billing

The `Contract Type` field references `Subscription Contract Type`, which
controls two defaults: whether contract deferrals are created, and whether
harmonized billing is enabled. When harmonized billing is on, the contract
maintains `Billing Base Date` and `Default Billing Rhythm` so all lines
align to the same billing cycle (`RecalculateHarmonizedBillingFieldsBasedOnNextBillingDate`).

## Extending contracts

`ExtendSubContractMgt` (codeunit 8075) handles adding new subscription lines
to existing contracts via the **Extend Contract** page. The flow: select
an item, pick subscription packages, set provision start date, then
`ExtendContract()` creates a Subscription Header from the item and assigns
its Subscription Lines to the chosen customer and/or vendor contract.

## Dimension management

`CustSubContrDimMgt` (codeunit 8054) auto-creates a dimension value for the
contract number when `Aut. Insert C. Contr. DimValue` is set in
Subscription Contract Setup. Dimension changes on the contract header
cascade to all contract lines after user confirmation.

## Gotchas

- Deletion of a contract line is blocked if a billing proposal line exists
  for it -- delete the billing proposal first.
- Usage-based billing lines cannot be deleted if `Usage Data Billing`
  records reference the contract line.
- Manual contract lines (Item or G/L Account typed directly) require that
  default billing periods are configured in Subscription Contract Setup.
- Currency changes on the contract header force recalculation of all
  linked Subscription Line amounts via exchange rate selection.
