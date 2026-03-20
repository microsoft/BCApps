# Contract price update

Contract price updates let you adjust subscription prices in bulk using
configurable templates. The system supports both customer and vendor
subscription lines.

## Templates and methods

**PriceUpdateTemplate (8003)** stores the configuration: which partner
(customer or vendor), filter criteria for contracts/subscriptions/lines,
the update method, percentage value, effective date formula, and price
binding period. Filters are stored as BLOBs containing serialized
RecordRef views, editable through a FilterPageBuilder UI.

Three price update methods implement the `ContractPriceUpdate` interface
(`ContractPriceUpdate.Interface.al`):

- **CalculationBaseByPerc** -- increases the Calculation Base Amount by the
  template percentage, then recalculates Price from the new base. The
  percentage cannot be negative.
- **PriceByPercent** -- increases the Price directly by the template
  percentage, leaving Calculation Base unchanged.
- **RecentItemPrice** -- fetches the current item sales price (customer) or
  unit cost (vendor) and uses that as the new Calculation Base. The
  `Update Value %` must be zero since the price comes from item pricing,
  not a percentage.

## Proposal workflow

The process follows four steps:

1. **Select template** on the Contract Price Update page
2. **Create proposal** -- `PriceUpdateManagement.CreatePriceUpdateProposal`
   applies default filters (excludes usage-based, closed, and already-planned
   lines; respects `Next Price Update` date and `Exclude from Price Update`
   flag), then runs the template's interface to generate
   `SubContrPriceUpdateLine` records
3. **Review** -- the proposal page shows old vs new pricing, grouped by
   contract or contract partner. Lines where the new price would be zero or
   negative are skipped with a notification.
4. **Perform update** -- `PriceUpdateManagement.PerformPriceUpdate` runs
   `ProcessPriceUpdate` (codeunit 8013) per line, wrapped in
   `Codeunit.Run` for error isolation

## Immediate vs deferred updates

`ProcessPriceUpdate` checks whether the update can take effect immediately.
If any of these conditions are true, it creates a **Planned Subscription
Line** instead of updating the Subscription Line directly:

- The `Perform Update On` date is after the line's `Next Billing Date`
- An unposted sales/purchase document exists for the line
- The `Next Price Update` date has not yet been reached by `Next Billing Date`

Planned Subscription Lines activate automatically when the current billing
period is fully invoiced (triggered by `PostSubContractRenewal` subscribers
on sales/purchase posting events).

## Price binding period

The template's `Price Binding Period` date formula sets the `Next Price
Update` date on the Subscription Line after the update executes. This
prevents another price update from affecting the line before that date.

## Credit memo handling

When a credit memo is posted for a previously invoiced billing period,
`PostSubContractRenewal.ProcessPlannedServCommsForPostedSalesCreditMemo`
restores the Subscription Line to its archived state and re-creates a
Planned Subscription Line so the price update can re-activate later.
