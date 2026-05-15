# Base

Foundation layer for the entire Subscription Billing app. Provides global
configuration, shared utility codeunits, and base-app extensions that wire
subscription billing into standard Business Central.

## How it works

`SubscriptionContractSetup` (table 8051) is the single-row configuration
record. It stores number series for customer/vendor contracts and
subscriptions, default billing periods and rhythms, invoice text layout
rules, and deferral journal settings. `SubBillingInstallation` seeds the
record on install and on company initialization; `UpgradeSubscriptionBilling`
handles schema migrations across versions.

The `ServicePartner` enum (Customer | Vendor) is the fundamental
discriminator used across the entire app -- contract tables, subscription
lines, billing logic, and import codeunits all branch on this value.

Utility codeunits provide shared logic consumed throughout:

- `DateFormulaManagement` -- validates date formulas are non-negative and
  non-empty, checks integer ratios between billing base period and rhythm
- `SubContractsItemManagement` -- enforces item subscription option rules
  on sales/purchase lines, prevents billing items and subscription items
  from being used outside their intended document types, calculates unit
  prices via the pricing interface
- `SubContractsGeneralMgt` -- partner-aware navigation (opens the right
  contract card or partner card based on ServicePartner)
- `DimensionMgt`, `ContactManagement`, `CustomerManagement`,
  `VendorManagement` -- thin wrappers for partner-specific lookups

Table extensions on `GLEntry`, `GenJournalLine`, `SourceCodeSetup`, and
`GeneralPostingSetup` add fields needed for contract deferral posting.
Page extensions on role center pages (Business Manager, Order Processor,
etc.) surface subscription billing activity cues.

`FieldTranslation` (table 8000) stores per-language overrides for any
text field on any table, keyed by table ID + field number + language code
+ source record SystemId. Used for multi-language contract descriptions.

## Things to know

- Changing "Default Period Calculation" on setup prompts to bulk-update
  ALL existing Subscription Package Lines, Sales Subscription Lines, and
  Subscription Lines via `ModifyAll`. This is a database-wide change.
- "Default Billing Base Period" and "Default Billing Rhythm" must both be
  set for manual contract line creation to work. Clearing either shows a
  warning and blocks manual line creation.
- `SubContractsItemManagement` is a `SingleInstance` codeunit. The
  `AllowInsertOfInvoicingItem` flag persists for the session -- callers
  must reset it after use to avoid leaking state.
- The `ContractLineType` enum is transitioning: the old "Service
  Commitment" value is obsolete (CLEAN26/29), replaced by Item and
  G/L Account values.
