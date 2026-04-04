# Service Commitments

Defines subscription lines and the template hierarchy that creates them.
A subscription line is the billing agreement attached to a subscription
header -- it carries price, rhythm, terms, and contract assignment.

## How it works

The template hierarchy flows top-down:

1. **SubPackageLineTemplate** (table 8054) -- master formula defining
   invoicing method, calculation base type/percent, billing base period,
   discount flag, and usage-based billing settings.
2. **SubscriptionPackage** (table 8055) -- a named group of package
   lines. Linked to a Customer Price Group. Can be copied with
   `CopyServiceCommitmentPackage`.
3. **SubscriptionPackageLine** (table 8056) -- one line per package,
   referencing a template. Adds partner (Customer/Vendor), billing
   rhythm, initial term, subsequent term, notice period, invoicing item,
   and period calculation. Validates ratio between billing base period
   and billing rhythm (must be an integer multiple).
4. **ItemSubscriptionPackage** (table 8058) -- many-to-many link between
   items and packages. The `Standard` flag determines which packages are
   automatically applied when a subscription's Source No. is set.
5. **ItemTemplSubPackage** (table 8005) -- same link but for item
   templates, so new items inherit packages from their template.

When a subscription header validates its Source No., standard packages
expand into `SubscriptionLine` records (table 8059). Each subscription
line stores the full billing agreement: start/end dates, next billing
date, calculation base amount and percent, price, discount, billing base
period, billing rhythm, initial term, subsequent term, notice period,
currency, dimensions, and contract assignment.

`SubscriptionLineArchive` (table 8073) preserves historical pricing.
Archival happens on subscription quantity/serial changes and price
updates, via `CopyFromServiceCommitment`. This gives period-accurate
records after pricing changes.

Key pricing fields on a subscription line: `Calculation Base Amount` x
`Calculation Base %` = `Price`. Then `Discount %` / `Discount Amount`
reduce Price to `Amount`. All values exist in both document currency and
LCY.

## Things to know

- The `Partner` field on package lines and subscription lines determines
  whether the line flows to a customer contract or vendor contract. The
  `CalculationBaseType` "Document Price And Discount" is not allowed for
  vendors -- the validation silently downgrades to "Document Price" with
  a notification.
- Billing Base Period and Billing Rhythm must have an integer ratio (e.g.
  12M base with 1M rhythm = 12 billing cycles). Non-integer ratios error.
- The `Discount` boolean marks a line as a recurring discount. Discount
  lines require Invoicing via Contract and a Subscription Item as the
  invoicing item. They cannot combine with usage-based billing.
- `PlannedSubscriptionLine` (in the Contract Renewal subfolder, not here)
  stores future-dated copies of subscription lines for pending changes.
- Subscription lines are not directly editable once linked to a contract
  -- modifications go through the contract line or price update workflow.
