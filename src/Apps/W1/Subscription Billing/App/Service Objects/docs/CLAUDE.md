# Service Objects

Defines the `SubscriptionHeader` (table 8057) -- the central record
representing a physical service or product being tracked under
subscription billing. Every subscription line, contract line, and billing
entry ultimately points back to a subscription header.

## How it works

A subscription header records what is being subscribed to: an item (or
G/L account), its quantity, serial number, version, key, and provision
dates. The `Type` + `Source No.` fields identify the source entity. When
`Source No.` is validated for an item, the subscription auto-creates
subscription lines from standard subscription packages assigned to that
item (via `InsertServiceCommitmentsFromStandardServCommPackages`).

The subscription uses a dual-customer model:

- **End-User Customer** -- who uses the service. Stored in
  `End-User Customer No.` with full address fields.
- **Bill-to Customer** -- who pays. Stored in `Bill-to Customer No.`
  with separate address fields.

When a customer record is changed, the subscription copies address fields
from the customer card and then calls `RecalculateServiceCommitments`,
which recalculates pricing on all linked subscription lines. This applies
to changes on both End-User and Bill-to Customer.

The Item table extension adds "Subscription Option"
(`ItemServiceCommitmentType` enum) with four values: No Subscription,
Sales with Subscription, Subscription Item, and Invoicing Item.
Subscription Items must be Non-Inventory type. The option controls which
document types the item can appear on and whether subscription packages
can be assigned.

Item attribute table extensions (`ItemAttributeValue`,
`ItemAttributeValueMapping`, `ItemAttributeValueSelection`) add a
`Primary` flag, surfaced through `ServObjectAttributeValues` and the
factbox page for per-subscription attribute tracking.

`UpdateSubLinesTermDates` is a job-queue codeunit that iterates all
subscriptions and recalculates term dates (`UpdateServicesDates`),
committing after each record to minimize lock contention.

## Things to know

- Changing `End-User Customer No.` or `Bill-to Customer No.` triggers
  `RecalculateServiceCommitments`, which recalculates prices for every
  linked subscription line. On subscriptions with many lines this is
  expensive. The subscription also checks whether lines are linked to
  contracts and warns if so.
- `Quantity` changes also trigger recalculation. Setting a serial number
  forces quantity to 1.
- `Type` and `Source No.` cannot be changed while subscription lines
  exist -- the subscription errors to prevent orphaned billing data.
- The old `Item No.` field (field 20) is obsolete; use `Source No.`
  (field 51) with the `Type` field instead.
- The table publishes 43+ integration events for extensibility.
  `HideValidationDialog` suppresses confirmation prompts during
  programmatic operations (import, posting).
