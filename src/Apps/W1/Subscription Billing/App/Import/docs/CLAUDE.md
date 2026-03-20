# Import

Bulk creation of subscriptions, subscription lines, contract lines, and
customer contracts from staging tables. Despite the name, this is not a
data import framework -- it is a processing pipeline that converts
imported staging records into live subscription billing entities.

## How it works

Three staging tables hold data to be processed:

- **ImportedSubscriptionHeader** (table 8008) -- one row per subscription
  to create. Requires item number, quantity, and optionally customer,
  serial number, and provision dates.
- **ImportedSubscriptionLine** (table 8009) -- one row per subscription
  line. Carries the full billing agreement: partner, package code,
  template, start/end dates, pricing fields, billing rhythm, and the
  target contract number.
- **ImportedCustSubContract** (table 8010) -- one row per customer
  contract to create. Carries sell-to/bill-to customer, currency,
  contract type, dimensions, and payment terms.

Three reports drive the processing in sequence:

1. **Create Service Objects** (report 8001) runs `CreateSubscriptionHeader`
   for each unprocessed imported subscription header. Validates the item
   has a subscription option, quantity is positive, and the number series
   allows manual numbers if a specific number is provided.
2. **Create Customer Contracts** (report 8003) runs `CreateCustSubContract`
   for each unprocessed imported contract. Validates customer exists and
   number series is configured.
3. **Cr. Serv. Comm. And Contr. L.** (report 8002) processes imported
   subscription lines in two steps per record: first runs
   `CreateSubscriptionLine` to create the subscription line on the
   subscription header, then runs `CreateSubContractLine` to assign it
   to a customer or vendor contract line. If the subscription line
   creation fails, the contract line step is skipped.

Each report uses `Codeunit.Run` with error trapping -- failures are
recorded in the staging record's `Error Text` field and processing
continues. Every record is committed individually so partial runs retain
their progress.

## Things to know

- The reports must run in the correct order: subscriptions first, then
  contracts, then subscription lines + contract lines. The third report
  requires both the subscription and contract to exist.
- Lines with `Invoicing via` = Sales automatically mark the contract line
  as created (they do not need a contract assignment).
- Comment lines (`IsContractCommentLine`) skip subscription line creation
  and create only a contract line with a description.
- `CreateSubContractLine` validates that the contract's customer matches
  the subscription's End-User Customer and that currency codes align.
  Mismatches error.
- All four codeunits publish integration events for extensibility
  (OnAfterInsert, OnAfterModify, OnAfterTest patterns).
