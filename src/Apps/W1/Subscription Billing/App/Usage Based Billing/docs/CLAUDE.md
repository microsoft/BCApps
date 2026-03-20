# Usage based billing

Sub-module for metered/consumption-based billing that extends the core
subscription billing model. Instead of fixed recurring amounts, charges are
based on actual usage data imported from external suppliers (cloud providers,
IoT platforms, etc.).

## Core concepts

**Usage Data Supplier** (`UsageDataSupplier.Table.al`) -- master record for
who provides usage data. Each supplier has a Type enum that drives which
`"Usage Data Processing"` interface implementation handles its import
pipeline. The built-in type is `Generic`, backed by Data Exchange
Definitions for CSV parsing.

**Usage Data Import** (`UsageDataImport.Table.al`) -- batch header for a
single import run. Tracks the current Processing Step and Processing Status,
with FlowFields counting dependent Blobs, Generic Import lines, Billing
records, and their respective error counts. The `ProcessUsageDataImport`
procedure is the central dispatcher: it routes each step to the correct
codeunit via `Codeunit.Run`.

**Three pricing models** (defined in `UsageBasedPricing.Enum.al`):

- **Usage Quantity** -- actual usage quantity x price. The subscription line
  quantity is updated to match total usage, and `GetSalesPriceForItem` looks
  up the customer-specific unit price. Cost is summed from the import data.
- **Fixed Quantity** -- subscription line quantity stays at its original
  value. Billing only occurs if usage data exists for the period. Price is
  calculated using the fixed quantity from the subscription line, not the
  imported quantity.
- **Unit Cost Surcharge** -- unit price = imported unit cost x
  (1 + surcharge %). The surcharge percentage lives on the subscription line
  (`"Pricing Unit Cost Surcharge %"`). Product name can optionally replace
  the subscription description on printed invoices (controlled by
  `"Invoice Desc. (Surcharge)"` in Subscription Contract Setup).

## How it works

1. Set up a Usage Data Supplier with a Data Exchange Definition
   (`GenericImportSettings.Table.al` links the two).
2. Upload a CSV/text file -- raw data stored in Usage Data Blob
   (`UsageDataBlob.Table.al`), hashed for deduplication.
3. **Create Imported Lines** -- `ProcessUsageDataImport` (CU 8027) delegates
   to the supplier's interface, which uses the Data Exchange Definition to
   parse blobs into `"Usage Data Generic Import"` rows via
   `GenericConnectorProcessing.Codeunit.al`.
4. **Process Imported Lines** -- validates each row: auto-creates Usage Data
   Customers and Subscriptions if configured, resolves the Subscription
   Header via Supplier References, checks subscription line validity.
5. **Create Usage Data Billing** -- `CreateUsageDataBilling.Codeunit.al`
   collects subscription lines for each service object and creates one
   `"Usage Data Billing"` record per subscription line per import line.
   Metadata records track rebilling state.
6. **Process Usage Data Billing** -- `ProcessUsageDataBilling.Codeunit.al`
   calculates customer prices per pricing model, updates subscription line
   quantities and prices, then the billing records are ready for contract
   invoicing.
7. **Create contract invoices** -- Usage Data Import collects affected
   contracts and opens the billing document creation pages. Posted invoices
   update Usage Data Billing with document references.

## Supplier-subscription linking

Supplier References (`UsageDataSupplierReference.Table.al`) map external IDs
to internal records. Three reference types exist: Customer, Subscription,
and Product. During import processing, these references are resolved to find
the correct subscription line. The `"Supplier Reference Entry No."` on
`"Subscription Line"` is the FK that connects external supplier data to
internal subscription lines.

Subscriptions can be connected in two ways
(`ConnectToSOMethod.Enum.al`):

- **Existing Service Commitments** -- reuses subscription lines already
  marked `"Usage Based Billing" = true`
- **New Service Commitments** -- closes existing subscription lines at a
  cutover date and creates new ones from subscription packages via
  `ExtendContract`

## Things to know

- Usage-based subscription lines REQUIRE contract invoicing, not direct
  sales invoicing. The billing integration uses the `"Recurring Billing"`
  flag on document headers.
- Usage-based lines cannot have discounts -- `"Discount %" = 100` zeroes
  out both price and amount in `CalculateUsageDataPrices`.
- The Processing Status enum (None/Ok/Error/Closed) and Processing Step
  enum (None/Create Imported Lines/Process Imported Lines/Create Usage Data
  Billing/Process Usage Data Billing) together track multi-stage progress.
  Errors at each stage are independently trackable.
- Rebilling is supported: if usage data overlaps a previously invoiced
  period, `UpdateRebilling` sets the Rebilling flag. On posting a credit
  memo, `CreateAdditionalUsageDataBilling` creates new unbilled records so
  the period can be re-invoiced.
- When a Sales/Purchase document is deleted, event subscribers in
  `UsageBasedContrSubscribers.Codeunit.al` clear the document references
  from Usage Data Billing (for invoices) or delete the billing records
  entirely (for credit memos).
- The `"Usage Data Processing"` interface (`UsageDataProcessing.Interface.al`)
  makes the import pipeline extensible. Custom connector types can implement
  the five interface methods to integrate with non-CSV sources.
