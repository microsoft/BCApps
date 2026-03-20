# Vendor contracts

Vendor contracts mirror customer contracts but for the incoming (cost) side of
subscription billing. They track what you owe vendors for subscriptions you
resell to customers.

## Core tables

**VendorSubscriptionContract (8063)** is the header. It follows the standard
BC buy-from / pay-to vendor pattern: setting the buy-from vendor cascades
contact, address, and payment defaults. Changing pay-to triggers currency,
payment terms, payment method, and dimension recalculation. The table
publishes about 20 IntegrationEvents covering vendor validation, address
copy, contact resolution, dimensions, and initialization.

**VendSubContractLine (8065)** is structurally identical to its customer
counterpart. Each line links to one Subscription Line via
`Subscription Line Entry No.` and uses the same `Closed` flag for
soft-delete. It also has the `Planned Sub. Line exists` FlowField.
Like customer lines, `CreateServiceObjectWithServiceCommitment()` supports
manual line entry. Deletion is blocked by unreleased vendor contract
deferrals and linked usage data billing records.

## Key differences from customer contracts

- **No harmonized billing.** The contract type does not control billing
  date alignment -- there are no `Billing Base Date` or
  `Default Billing Rhythm` fields.
- **No renewal support.** Contract renewal (sales quotes, planned
  subscription lines from renewal) is a customer-side concept. Vendor
  lines can be *included* in a renewal as linked lines via
  `FilterServCommVendFromServCommCust` in `SubContractRenewalMgt`, but
  the vendor contract itself has no renewal workflow.
- **No customer price group.** The customer contract has a
  `Customer Price Group` field that feeds pricing; the vendor contract
  has no equivalent.
- **Simpler line merge.** Vendor contract line merging skips the Customer
  Reference and Serial No. checks that the customer side enforces.

## Contract type and deferrals

The `Contract Type` field links to `Subscription Contract Type` and
controls the `Create Contract Deferrals` default. The obsolete
`Without Contract Deferrals` field is being replaced by the inverted
`Create Contract Deferrals` boolean (pending removal in v30).

## Currency handling

Currency changes on the vendor contract header prompt exchange rate
selection and recalculate all linked Subscription Line amounts via
`UpdateAndRecalculateServiceCommitmentCurrencyData`. When currency is
cleared, `ResetVendorServiceCommitmentCurrencyFromLCY` reverts lines to
LCY values.

## Dimension cascading

Dimension changes on the header propagate to all Subscription Lines
assigned to the contract after user confirmation. The dimension update
also flows to unreleased vendor contract deferrals via
`UpdateDimensionsInDeferrals`.

## Gotchas

- When assigning Subscription Lines to a vendor contract with a different
  currency, the system forces exchange rate selection and recalculates
  prices -- this is a one-way conversion.
- Vendor contract lines have no `OnAfterInitFromSubscriptionLine` event
  (unlike customer lines), so customizing line initialization requires
  subscribing elsewhere.
- Deleting a vendor contract cascades deletion to all its lines
  (with trigger), which in turn disconnects or deletes the underlying
  Subscription Lines.
