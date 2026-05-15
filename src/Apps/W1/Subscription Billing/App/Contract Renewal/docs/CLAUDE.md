# Contract renewal

Contract renewal extends customer subscription contracts by creating sales
quotes that, when shipped, extend or replace the subscription terms.

## Renewal workflow

1. **Select lines** -- `SubContractRenewalMgt.StartContractRenewalFromContract`
   opens a selection page filtered to renewable contract lines (must have a
   Subscription Line End Date, not be closed, and not have a pending Planned
   Subscription Line).
2. **Create renewal lines** -- `SelectContractRenewal` (report) calls
   `SubContractRenewalLine.InitFromServiceCommitment` for each selected
   line. The renewal line copies the Renewal Term from the Subscription
   Line and calculates `Agreed Sub. Line Start Date` as one day after the
   current end date.
3. **Generate sales quote** -- `CreateSubContractRenewal` (codeunit 8002)
   creates a Sales Quote header from the customer contract fields, then
   adds sales lines of type `Service Object` with pricing from the current
   Subscription Line. Each line gets a `SalesSubscriptionLine` marked
   with `Process::Contract Renewal`.
4. **Convert to order and ship** -- when the quote becomes an order and is
   shipped, `PostSubContractRenewal` (codeunit 8004) runs via the
   `OnBeforePostSalesLines` subscriber. It creates Planned Subscription
   Lines and, if pricing hasn't changed, immediately applies them to
   extend the Subscription Line End Date.

## Key tables

**SubContractRenewalLine (8001)** is the planning table. It links to a
Subscription Line and its contract, stores the `Renewal Term` and
`Agreed Sub. Line Start Date`, and carries FlowFields for current pricing.
Primary key is `Subscription Line Entry No.` -- one renewal line per
subscription line. The `Linked to Sub. Contract No.` field groups renewal
lines by the originating customer contract.

**PlannedSubscriptionLine (8002)** holds future subscription terms.
It mirrors the Subscription Line field structure plus `Type Of Update`
(Contract Renewal or Price Update), `Perform Update On`, and references
to the source Sales Order. `ProcessPlannedServiceCommitment` applies the
planned values to the real Subscription Line when conditions are met.

## When updates apply immediately vs are deferred

`CheckPerformServiceCommitmentUpdate` determines this. The Planned
Subscription Line is applied immediately when either:

- The Subscription Line's `Next Billing Date` has reached or passed its
  `Subscription Line End Date` (meaning the current term is fully invoiced)
- All pricing fields are identical (only the end date is changing)

Otherwise the planned line waits until the current billing period is
fully invoiced (triggered by posting events in
`SubContrRenewalSubcribers`).

## Batch processing

`BatchCreateContractRenewal` groups renewal lines by contract number and
creates one sales quote per contract. Errors on individual contracts are
captured and written to the `Error Message` field on the renewal line
rather than stopping the batch.

## Gotchas

- You cannot create a renewal if a sales quote or order already exists for
  that contract line (`ExistsInSalesOrderOrSalesQuote` check).
- Renewal is customer-side only. Vendor subscription lines can be included
  as linked lines (via `SetAddVendorServices`), but the renewal quote is
  always a sales document.
- Contract renewal lines are excluded from standard document copying
  (`ExcludeRenewalForSalesLine` subscriber) and from document totals.
- Quote-to-invoice conversion is blocked for contract renewal quotes --
  they must go through quote-to-order-to-ship.
- When a credit memo is posted against a previously invoiced period,
  the system restores the Subscription Line from its archive and
  re-creates a Planned Subscription Line.
