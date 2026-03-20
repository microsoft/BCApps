# Deferrals

Revenue/cost recognition module for subscription contract billing. When
enabled, posted contract invoice amounts go to balance sheet accrual
accounts instead of income/expense. A separate release process moves
amounts to income/expense accounts monthly.

## How it works

When a contract invoice is posted and deferrals are enabled, the posting
codeunits (`CustomerDeferralsMngmt.Codeunit.al`,
`VendorDeferralsMngmt.Codeunit.al`) intercept the posting pipeline via
event subscribers:

1. **Account redirection**: `OnPrepareLineOnBeforeSetAccount` swaps the
   sales/purchase account from `"Cust. Sub. Contract Account"` to
   `"Cust. Sub. Contr. Def Account"` (or the vendor equivalents) in General
   Posting Setup. This sends the posting to the balance sheet deferral
   account instead of the income/expense account.

2. **Deferral record creation**: `InsertContractDeferrals` creates one
   `"Cust. Sub. Contract Deferral"` (table 8066) or
   `"Vend. Sub. Contract Deferral"` (table 8072) record per month in the
   billing period. The billing period comes from `"Recurring Billing from"`
   / `"Recurring Billing to"` on the document line.

3. **Period splitting methodology**: The billing period amount is divided
   among calendar months. Partial months (first and last) are
   day-proportioned using a daily rate = total amount / total days. Full
   months in between get an equal share of the remaining amount. The last
   period absorbs rounding differences. Each deferral record stores the
   `"Number of Days"` and `Amount` for its month.

4. **Release**: `ContractDeferralsRelease.Report.al` (Report 8051) posts
   G/L entries that move amounts from the deferral account to the
   income/expense account. It takes a "Post Until Date" parameter and
   releases all unreleased deferrals with posting dates up to that date.
   Each release creates two G/L entries per deferral: debit the
   income/expense account, credit the deferral account (or vice versa for
   vendor). The report can be scheduled via job queue.

## Credit memo handling

When a credit memo is posted against an invoice that has deferrals:

- The original invoice's deferral records are located by document no. and
  contract line
- Mirror deferral records are created with negated amounts
- Any unreleased invoice deferrals are force-released at the credit memo's
  posting date
- The credit memo deferrals are then also released immediately
- If the invoice was already fully released, only the credit memo deferrals
  are created and released

This ensures the net effect is zero once both the invoice and credit memo
deferrals are released.

## Configuration

**Opt-in per contract type**: The `"Create Contract Deferrals"` enum
(`CreateContractDeferrals.Enum.al`) has three values:

- `Contract-dependent` -- inherits the setting from the contract type
- `Yes` -- always create deferrals
- `No` -- never create deferrals

The `CreateContractDeferrals()` function on Sales Line / Purchase Line
evaluates this hierarchy.

**G/L accounts** in General Posting Setup:

- `"Cust. Sub. Contract Account"` / `"Vend. Sub. Contract Account"` --
  income/expense accounts (where amounts end up after release)
- `"Cust. Sub. Contr. Def Account"` / `"Vend. Sub. Contr. Def. Account"` --
  balance sheet deferral/accrual accounts (where amounts park during
  deferral)

**Source Code Setup**: `"Sub. Contr. Deferrals Release"` identifies
deferral release G/L entries.

**Journal template/batch**: When `"Journal Templ. Name Mandatory"` is
enabled in General Ledger Setup, the Subscription Contract Setup must
specify `"Def. Rel. Jnl. Template Name"` and `"Def. Rel. Jnl. Batch Name"`.

## Things to know

- Deferrals are optional and controlled at the contract type level. The
  three-value enum allows both global defaults and per-line overrides.
- Line discounts are tracked separately in `"Discount Amount"` on the
  deferral record. Whether discount amounts are posted to a separate
  line discount account depends on Sales/Purchase Setup
  `"Discount Posting"` configuration.
- `"Deferral Base Amount"` is the total amount being deferred (net of VAT
  if prices include VAT). It does not include the discount amount.
- `"Release Posting Date"` is the date the release G/L entry was posted,
  which can differ from `"Posting Date"` (the deferral period date). This
  separation enables posting releases for past periods on a current date.
- `"Document Posting Date"` is the original invoice/credit memo posting
  date. `"Posting Date"` is the first day of the deferral period month.
- The `Released` boolean controls whether a deferral has been posted to
  G/L. The release report filters on `Released = false`.
- Each release G/L entry carries the `"Subscription Contract No."` for
  reporting and traceability.
- Dimensions from the original document line are preserved on deferral
  records and passed through to G/L entries via `"Dimension Set ID"`.
- The Navigate page integration (`OnAfterNavigateFindRecords` /
  `OnBeforeShowRecords`) allows finding deferral records from the standard
  document navigation.
- Deferral preview codeunits (`DeferralPostPreviewBinding`,
  `DeferralPostPreviewHandler`, `DeferralPostPreviewSubscr`) support the
  standard posting preview framework, so users can preview deferral
  entries before posting.

## Extension points

- `OnBeforeInsertCustomerContractDeferral` -- modify deferral records
  before insert (e.g., adjust amounts, add custom fields)
- `OnBeforeInsertVendorContractDeferral` -- same for vendor deferrals
- `OnBeforeReleaseCustomerContractDeferral` -- skip or customize release
  per deferral record
- `OnBeforeReleaseVendorContractDeferral` -- same for vendor
- `OnAfterInitFromSalesLine` / `OnAfterInitFromPurchaseLine` -- extend
  deferral initialization from document lines
