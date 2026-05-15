# Billing module

The Billing subfolder is the execution engine of Subscription Billing. It
turns contract subscription lines into sales invoices, purchase invoices,
sales credit memos, and purchase credit memos. Everything upstream
(subscriptions, contracts, subscription lines) defines *what* should be
billed; this module decides *when* and *how* it becomes a real document.

## Core tables

**BillingLine (8061)** is the central transaction record. Each row links a
subscription line to an in-progress document. The `Partner` enum
(Customer/Vendor) drives conditional `TableRelation` throughout the table
-- partner no., contract no., contract line no., and document no./type all
resolve to different tables based on this enum. Key fields:

- `Billing from` / `Billing to` -- the period this line covers
- `Document Type` / `Document No.` / `Document Line No.` -- the generated
  sales/purchase document, populated only after "Create Documents"
- `Update Required` -- set to true by subscription line changes after the
  billing proposal was created; blocks document creation until the
  proposal is refreshed
- `Correction Document Type` / `Correction Document No.` -- populated on
  credit memo billing lines, pointing back to the original posted invoice
- `Billing Template Code` -- links back to the template that generated
  this line (empty when created from a contract card)
- `Rebilling` -- flags lines created from usage data rebilling scenarios

Deletion is constrained: only the last billing line for a given
subscription line can be deleted (sorted by `Billing to` descending), and
lines already linked to a document cannot be deleted at all. On delete,
the subscription line's `Next Billing Date` is reset.

**BillingLineArchive (8064)** is a near-identical copy of BillingLine,
created when a billing document is posted. The `Document No.` field points
to the *posted* document (Sales Invoice Header, Sales Cr.Memo Header,
etc.) rather than the unposted one. This table is the source of truth for
billing corrections -- credit memos are built by reading archive records
for the original invoice.

**BillingTemplate (8060)** is the automation configuration record. Each
template defines:

- `Partner` -- Customer or Vendor (vendor templates cannot be automated)
- `Billing Date Formula` / `Billing to Date Formula` -- date formulas
  applied to WorkDate (or Today for background jobs) to derive billing
  parameters
- `Filter` -- a Blob storing a RecordRef view filter against
  Customer/Vendor Subscription Contract, with default filter fields for
  Billing Rhythm, Assigned User, Contract Type, and Salesperson/Purchaser
- `Group by` -- how to group the proposal view (None, Contract, Contract
  Partner)
- `Customer Document per` -- how customer billing lines are grouped into
  documents (per Contract, per Sell-to Customer, per Bill-to Customer)
- `Automation` -- None or "Create Billing Proposal and Documents"
- `Minutes between runs` / `Batch Recurrent Job Id` -- Job Queue
  scheduling fields

**ContractBillingErrLog (8022)** captures errors during automated billing.
Each record stores the billing template code, error text, and contract
context (subscription, contract no., contract type, assigned user,
salesperson). Linked to billing lines via `Billing Error Log Entry No.`.

## How billing works

The workflow has three phases:

### 1. Create billing proposal

`BillingProposal.CreateBillingProposal()` iterates contracts matching the
template's filter and partner type. For each contract, it finds
subscription lines where `Next Billing Date <= BillingDate`. Lines are
skipped when:

- The subscription line has ended (`Next Billing Date > End Date`)
- A billing line with a document already exists for that subscription line
- For usage-based lines, no unbilled usage data exists
- An unposted credit memo exists for the subscription line (the user is
  warned; in automated mode, an error log entry is created)

For each qualifying subscription line, the codeunit calculates the billing
period using the line's `Billing Rhythm` and `Next Billing Date`, creates
a BillingLine record, computes amounts via `UnitPriceAndCostForPeriod`,
then advances `Next Billing Date` on the subscription line. If the billing
period hasn't reached the Billing to Date yet, the process recurses to
create additional billing lines for subsequent periods.

Each subscription line can appear in a billing proposal only once per
period -- the existence check on BillingLine prevents duplicate billing.

### 2. Create documents

`CreateBillingDocuments` (codeunit 8060) runs against the billing lines.
It first validates: only one partner type at a time, no "Update Required"
lines, consistency checks (all billing lines for a subscription line must
be included -- no gaps). It then creates temporary billing lines that
consolidate multiple period lines per subscription line into a single
document line.

Document grouping depends on the template configuration:

- **Per contract** -- one document per contract, document type (invoice
  vs. credit memo) determined by the net amount sign across the contract
- **Per customer/vendor** -- one document per partner, with description
  lines separating each contract's lines within the document
- Currency code also forces new documents (different currencies cannot mix)

The sign logic is notable: positive amounts produce invoices, negative
amounts produce credit memos. Discount lines invert this logic (negative
discount = invoice, positive discount = credit memo).

Sales header creation transfers fields from the contract record (bill-to,
ship-to, currency, dimensions) and sets `Recurring Billing = true`. This
flag triggers the `DocumentChangeManagement` codeunit's protection --
most header and line fields become read-only after creation.

Invoice line descriptions are configured through `Subscription Contract
Setup` fields (`Contract Invoice Description`, `Contract Invoice Add. Line
1` through `5`), supporting text types like Service Object description,
Subscription Line description, billing period, serial number, customer
reference, and primary attribute.

At least one "Additional Line" must be configured in Setup for the billing
period; otherwise the description text for the invoice line will be empty.

### 3. Post

If `PostDocuments` is true (set from the request page or automated
billing), the created sales documents are posted immediately. For a
single document, `Sales-Post` runs directly. For multiple documents,
`Sales Batch Post Mgt.` is used with error message handling. Purchase
document posting is not automated from this module.

On posting, `SalesDocuments` and `PurchaseDocuments` codeunits subscribe
to `OnBeforeDeleteAfterPosting` events to move billing lines to
BillingLineArchive with the posted document number, then delete the
original billing lines. They also copy contract reference fields
(Contract No., Contract Line No.) onto the posted document lines via
`OnAfterInitFromSalesLine` / `OnAfterInitFromPurchLine` events.

## Billing correction

`BillingCorrection` (codeunit 8061) handles credit memos. It subscribes
to `Copy Document Mgt.` events (`OnAfterInsertToSalesLine`,
`OnAfterInsertToPurchLine`) that fire when a credit memo is created from
a posted invoice using "Create Corrective Credit Memo".

The correction process:

1. Finds the BillingLineArchive for the original invoice line
2. Checks that no newer invoices exist for the subscription line (credit
   memos must be chronological -- most recent invoice first)
3. Checks that no other unposted document exists for the same contract
   line
4. Creates a new BillingLine with negated amount, referencing the original
   invoice as the correction document
5. Resets the subscription line's `Next Billing Date` to the start of the
   credited period

Copying a recurring billing document for any purpose other than creating
a credit memo from a posted invoice raises an error.

## Automation

The `AutoContractBilling` codeunit (8014) is a Job Queue entry handler. It
receives the BillingTemplate record ID from the Job Queue Entry, calls
`BillingTemplate.BillContractsAutomatically()`, which:

1. Calculates billing dates using `Today()` (not WorkDate)
2. Creates the billing proposal
3. Creates documents (with the customer grouping from the template)

The `SubBillingBackgroundJobs` codeunit manages the Job Queue lifecycle:
creating, updating, or removing entries as the template's `Automation` and
`Minutes between runs` fields change.

Vendor contract invoicing is NOT automated -- `BillingTemplate.Partner`
validation enforces `TestField(Automation, None)` when Partner is Vendor.

Errors during automated billing are caught and written to
`ContractBillingErrLog` rather than raising user-facing errors. This
includes credit memo conflicts, consistency errors, and unit of measure
mismatches.

## Document change management

`DocumentChangeManagement` (codeunit 8074) is a SingleInstance codeunit
that subscribes to `OnBeforeValidateEvent` on dozens of fields across
Sales Header, Sales Line, Purchase Header, and Purchase Line. When the
document has `Recurring Billing = true`, it blocks changes to customer/
vendor identity, addresses, currency, posting groups, dimensions,
quantities, prices, and discount fields. The intent is that contract
billing documents are fully controlled by the contract data -- manual
edits to the generated documents would create inconsistencies.

The codeunit exposes `SetSkipContractSalesHeaderModifyCheck` and
`SetSkipContractPurchaseHeaderModifyCheck` for internal callers that need
to modify these protected fields programmatically (e.g., during document
creation itself or when creating credit memos via Copy Document).

## Table extensions on posted documents

The module adds `Subscription Contract No.` and `Subscription Contract
Line No.` fields to four posted document line tables
(SalesInvoiceLine, SalesCrMemoLine, PurchInvLine, PurchCrMemoLine) and
header tables (SalesInvoiceHeader, SalesCrMemoHeader, PurchInvHeader,
PurchCrMemoHdr). The header extensions add the `Recurring Billing`
boolean. These fields establish traceability from posted documents back to
contracts.

The `UserSetup` table extension adds an `Auto Contract Billing Allowed`
field that gates who can configure automated billing templates and
clear/delete billing proposals when automation templates exist.

## Page structure

The **RecurringBilling** page (8067) is the central hub. It is a Worksheet
page backed by a temporary BillingLine table, displayed as a collapsible
tree (grouped by contract or partner). The workflow is:

1. Select a Billing Template (sets partner filter, date formulas, grouping)
2. Set Billing Date and optional Billing to Date
3. Run "Create Billing Proposal" -- populates billing lines
4. Review and optionally adjust (Change Billing To Date, Delete lines)
5. Run "Create Documents" -- generates sales/purchase documents
6. Optionally navigate to the created documents and post

Other pages provide list/subpage views of billing lines
(BillingLines, BillingLinesList) and archived billing lines
(ArchivedBillingLines, ArchivedBillingLinesList), the billing template
list (BillingTemplates), error log (ContractBillingErrLog), and document
creation request pages (CreateCustomerBillingDocs, CreateVendorBillingDocs,
CreateBillingDocument).
