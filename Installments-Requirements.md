# W1 Installments - Requirements Specification

## Document status

This document captures the supplied proposal for a global Business Central (W1)
Installments feature. It is a proposed requirements baseline, not an approved
implementation design.

Requirements, recommendations, optional extensions, and later delivery slices
are distinguished below. References to existing Business Central behavior and
other ERP products come from the supplied specification and have not been
independently verified here. Source titles are retained where supplied; source
URLs were not provided.

Sections 15 and 16 add implementation planning and repository-verified findings.
Section 16 distinguishes observed behavior from proposed implementation contracts
and decisions that still require approval.

## Executive recommendation

An **installment** is a scheduled portion of one posted receivable or payable,
represented by its own customer or vendor ledger entry with an independently
calculated due date, remaining amount, payment-discount conditions, application
state, and collection or payment status.

Post one ledger entry per installment, linked by an Installment Plan ID and the
original document number. Do not retain one ledger entry with an embedded
schedule. Separate entries preserve compatibility with aging, reminders, payment
suggestions, payment application, cash-flow forecasting, currencies, and existing
entry-based integrations.

Installments determine settlement timing. They do not create multiple commercial
invoices or change revenue, expense, or tax recognition.

The supplied roadmap context describes invoice and payment schedules per
customer or document, with potential use in Projects and Service Management.

## 1. Payment Terms setup

Extend Payment Terms with subordinate **Installment Lines**.

### 1.1. Installment line fields

| Field | Requirement |
| --- | --- |
| Sequence | Unique within the payment term; controls calculation and display order. |
| Calculation type | Percentage, Fixed Amount, or Remaining Amount. Fixed Amount is proposed for a later delivery slice. |
| Payment percentage | Decimal percentage of the document amount. |
| Fixed amount | Optional; supports deposits or fixed first installments. |
| Due date calculation | Existing BC DateFormula, calculated from the terms or baseline date. |
| Due-date adjustment | None, next working day, previous working day, or nearest working day; advanced calendar support is proposed for later delivery. |
| Payment discount date calculation | Independent per installment. |
| Payment discount percentage | Independent per installment. |
| Description | Printable text, such as "Installment 2 of 3". |
| Payment method | Optional override per installment. |
| Bank account / direct-debit mandate | Optional future extension. |
| Grace period | Optional override for collection and reminders. |

### 1.2. Setup validation

- Percentages must total exactly 100%, subject to a defined BC rounding tolerance.
- Allow only one Remaining Amount line. It should preferably be the last line.
- Define deterministic calculation ordering when fixed amounts and percentages
  are combined.
- Reject negative percentages and negative amounts.
- Normally reject an installment with a zero amount.
- Require a due-date calculation on every line.
- A discount date should not normally be later than the installment due date.
- Resulting dates should be nondecreasing unless an explicit override is allowed.
- Setup changes must not alter already posted documents.
- A single 100% line must remain valid for backward compatibility.

**Recommendation:** Prefer Remaining Amount as the final line so that it absorbs
rounding differences after earlier allocations.

**Decision required:** Define percentage-validation precision separately from
currency amount-rounding precision, and specify how validation changes when a
Remaining Amount or Fixed Amount line is present.

## 2. Date calculation

### 2.1. Baseline date

Retain **Document Date** as the default baseline, consistent with the existing
payment-term behavior described in the supplied specification.

The extensibility model should also support:

- Posting Date.
- Shipment or Receipt Date.
- Tax point or tax document date where localization requires it.
- An explicit Terms Date copied to the document.

### 2.2. Date patterns

The target design must accommodate:

- Relative formulas such as `30D`, `60D`, and `90D`.
- End of month plus a specified number of days.
- A specific day of the month.
- Cutoff-day logic.
- A fixed date.
- Payment calendars and nonpayment days.
- Next or previous working-day adjustment.

**V1 recommendation:** Use standard BC DateFormula calculations. Provide an
extensible calculation interface so day-of-month, cutoff, and payment-calendar
strategies can be added without changing stored installment records.

## 3. Document experience

### 3.1. Target document coverage

Installment terms should be usable on:

- Sales quotes and orders.
- Sales invoices and sales credit memos.
- Purchase orders, invoices, and credit memos.
- Service documents.
- Project invoices.
- Subscription Billing invoices that result in normal posted sales invoices.
- General journals used to post customer or vendor invoices.

Payment Terms must default from the customer or vendor and remain overridable
on the document under the same rules as existing Payment Terms.

Document coverage is phased according to the delivery slices in section 11.

### 3.2. Installment Schedule preview

Add an **Installment Schedule** action or FactBox showing:

| Preview field | Content |
| --- | --- |
| Sequence | Installment calculation and display order. |
| Due date | Calculated installment due date. |
| Percentage | Allocated percentage, where applicable. |
| Amount excluding tax | Installment allocation excluding tax. |
| Tax amount | Tax allocation, if allocated. |
| Amount including tax | Total installment amount. |
| Discount date | Installment-specific discount date. |
| Discount amount | Installment-specific payment discount. |
| Currency | Document currency. |
| Rounding adjustment | Adjustment applied to reconcile the schedule total. |

The preview must update when any of the following changes:

- Document date.
- Currency.
- Prices or discounts.
- VAT or tax.
- Invoice discount.
- Payment terms.
- Amounts.

The schedule is part of the invoice payment conditions, not a separate invoicing
process.

## 4. Posting model

### 4.1. Posted records

Posting an invoice must create:

- One posted invoice header and normal G/L, VAT, and detailed posting entries.
- One customer or vendor ledger entry per installment.
- A shared Installment Plan ID.
- Installment No. and No. of Installments.
- The original total amount and original document identifier.
- An independent due date, discount date, discount percentage, and remaining
  amount for each installment.

### 4.2. Rounding example

For a DKK 10,000 invoice split into three equal installments:

| Installment | Due date relative to baseline | Amount |
| --- | --- | --- |
| 1 of 3 | 30 days | DKK 3,333.33 |
| 2 of 3 | 60 days | DKK 3,333.33 |
| 3 of 3 | 90 days | DKK 3,333.34 |
| **Total** | | **DKK 10,000.00** |

The last line receives the rounding remainder.

### 4.3. Compatibility goals

Separate ledger entries must preserve correct behavior for:

- Customer and vendor aging by installment due date.
- Reminders and finance charge memos per overdue installment.
- Suggest Vendor Payments.
- Cash Receipt Journal and Payment Journal.
- Payment Reconciliation Journal.
- Payment discounts and partial application.
- Currency revaluation.
- Cash-flow forecasts.
- External reporting over ledger entries.
- Standard document navigation.

A single entry with a secondary schedule is not the recommended model because
processes reading Due Date and Remaining Amount would require pervasive changes.
Existing entry-based processes still require review for installment correctness.

### 4.4. G/L and tax consequences

- Post revenue or expense once for the complete invoice.
- Post VAT or sales tax once according to existing invoice-posting rules.
- Customer or vendor control-account amounts may be split, but must reconcile
  exactly to the total invoice control amount.
- Keep dimensions identical across installment receivable or payable entries,
  unless a localization explicitly requires different behavior.
- Do not create separate posted invoice documents unless the scenario is
  periodic billing rather than installments.

## 5. Payment application

### 5.1. Required behavior

- A payment can close one installment.
- A payment can span multiple installments.
- Apply to Oldest applies first by due date, then installment sequence.
- A user can manually apply a payment to a later installment.
- An overpayment leaves the remainder unapplied or applies to the next
  installment according to existing rules.
- Evaluate payment tolerance per installment entry.
- Calculate realized currency gains or losses for each applied installment.
- Unapplication must preserve installment identity.
- Bank reconciliation must show the installment number and original invoice
  number.
- External Document No. must remain usable for matching every installment.

### 5.2. Payment discounts

**Recommendation:** Calculate and grant payment discounts per installment, not
over the complete original invoice.

For an installment of DKK 3,333.33 with a 2% discount, an eligible on-time payment
should close that installment with a DKK 66.67 discount even if later
installments remain open.

The supplied specification notes that existing BC normally calculates discounts
only when the document is fully applied. Define and verify compatibility when
each installment becomes its own entry.

**M2 decision approved:** Discount eligibility for partial payments within an
installment follows existing BC rules. Do not introduce a configurable or
proportional partial-payment discount policy.

## 6. Corrections, credit memos, and reversals

### 6.1. Unpaid invoice

For an invoice with no applications:

- Cancel or correct all installment ledger entries as one logical invoice.
- Create the correcting credit memo with matching installment allocation, or
  close the original entries and post the corrected invoice with a newly
  calculated schedule.
- Maintain document navigation between every installment entry and both posted
  documents.

**Decision required:** Select the correction approach and define when each
alternative is permitted.

### 6.2. Partly paid invoice

For an invoice with one or more paid installments:

- Block standard automatic cancellation if existing BC rules would block
  cancellation of a paid invoice.
- Allow allocation of a corrective credit memo proportionally across remaining
  installments, to earliest open installments, to latest open installments, or
  manually to selected installments.
- Never reopen settled amounts without an explicit unapply operation.

### 6.3. Purchase credit memos

Apply equivalent rules to payables, including payment suggestions and vendor
payments that have already been exported.

Define existing credit-memo payment-discount behavior at installment-entry level,
including reduction of the invoice payment discount when a credit memo is
applied.

## 7. Collections, reminders, and payments

### 7.1. Receivables

Reminders and finance charge memos must operate per overdue installment:

- Treat an invoice as partially overdue when at least one installment is overdue.
- Include only overdue installment amounts.
- Evaluate reminder level per installment entry.
- Group installments under the original invoice on printed reminders.
- Do not accelerate future installments merely because an earlier installment
  is overdue. Acceleration is a possible later feature, not baseline behavior.

Post-invoice collections plans and debt rescheduling are separate from
contractual installment terms established before posting.

### 7.2. Payables

Suggest Vendor Payments must:

- Suggest only installments due within the specified horizon.
- Respect payment discounts per installment.
- Respect vendor priority, available amount, payment method, and bank account.
- Allow consolidation of multiple installments into one bank payment.
- Retain remittance details for underlying invoice and installment numbers.

## 8. Reporting, output, and APIs

| Area | Requirement |
| --- | --- |
| Sales invoice | Print the payment schedule. |
| Purchase invoice archive / external document | Retain the schedule. |
| Customer statement | Group installment entries under the invoice. |
| Vendor remittance advice | Show the invoice and installment identifier. |
| Aged Accounts Receivable / Payable | Age each installment by its own due date. |
| Trial balance and control accounts | Preserve existing totals. |
| Cash Flow Forecast | Forecast each installment separately. |
| Standard APIs | Expose the schedule and posted installment identifiers. |
| Analysis mode and Power BI | Expose plan ID, installment number, original document number, due date, and status. |

Schedule printing must be configurable. Support a summarized payment-terms
description as well as a detailed breakdown of amounts and due dates.

## 9. Localization and migration

Design and implement the global solution in `src\Layers\W1\BaseApp`, using the
Italian localization as a historical implementation reference, not as a runtime
dependency or the target data model.

The Italian implementation provides reference behavior for:

- One Payment Terms record with multiple Payment Terms Lines.
- Payment percentage.
- Due-date formula.
- Discount-date formula.
- Discount percentage.
- Customer and vendor symmetry.

Repository inspection confirms that the IT posting implementation already splits
customer and vendor ledger entries, assigns installment-specific dates, calculates
payment discounts, and places rounding remainders on the final entry. It is an
end-to-end legacy implementation, not merely a setup facade.

The W1 design must strengthen global extensibility, fixed and balance line
types, ledger and application behavior, printed schedules, API exposure,
rounding, credit memos, and reminders.

The eventual solution must support Italy through the W1 contract and appropriate
local extension points. Provide a data-upgrade path from Italian Payment Terms
Lines. Migration behavior for existing setup and posted data requires detailed
design; do not regenerate historical ledger entries.

During development, preserve legacy IT behavior and prevent the legacy and global
posting paths from splitting the same invoice twice. IT migration and activation
are separate from the first W1 implementation milestone.

## 10. ERP precedents and source notes

These are research notes supplied with the proposal, not independently verified
product guarantees.

### 10.1. Business Central Italy and base application

The Italian localization provides the closest BC precedent through multiple
Payment Terms Lines and split customer/vendor posting. The supplied research
states that base BC explicitly does not support partial-payment terms.

Reuse setup vocabulary, date formulas, payment percentages, and customer/vendor
symmetry, while validating the complete W1 AR/AP lifecycle.

### 10.2. Oracle Fusion Cloud Financials

The supplied research describes:

- One payment-term line per installment.
- Percentage or fixed-amount allocation.
- Independent due and discount amounts.
- Up to three discounts per line.
- Fixed dates, relative days, calendars, and day-of-month/cutoff logic.
- Automatic recalculation when invoice payment terms change.
- An option to allow discounts on partial payments.

**Design lesson:** Make the installment a first-class term line and keep
date-calculation strategies extensible. Multiple discount tiers are a precedent,
not a committed V1 requirement.

Source titles supplied: *Payment Terms* and *Guidelines for Defining Payment
Terms*.

### 10.3. Odoo

The supplied research describes:

- Ordered payment-term rules.
- Percentage-based rules.
- A balance-based final rule to avoid rounding discrepancies.
- Multiple calculated due dates.
- Customer invoices and vendor bills.
- Optional printing of installment dates.
- Explicit separation of installments from down payments and multi-invoice
  billing.

**Design lesson:** Keep setup and preview simple, and prefer a final balance
line.

Source title supplied: *Payment terms and installment plans*.

### 10.4. SAP

The supplied research distinguishes:

- Standard AR/AP payment terms controlling installment payments and cash
  discounts.
- Collections-created plans over existing debt, including creation, simulation,
  changes, deactivation, original-item association, and interest calculation.

**Design lesson:** Keep contractual installments and post-delinquency payment
plans separate, even if they later share calculation infrastructure.

Source titles supplied: *Terms of Payment* and *Installment Plans*.

### 10.5. Business Central application reference

Source title supplied: *Apply Entries - Accounts Receivable*, referenced for
partial payments and payment-discount behavior.

## 11. Proposed delivery slices

Slices are implementation increments, not independent declarations of release
readiness. The minimum credible V1 in section 13 spans multiple slices.

### Slice 1: Setup and sales posting

- Installment lines on Payment Terms.
- Percentage plus Remaining Amount allocation.
- DateFormula per line.
- Schedule preview on sales invoices.
- Multiple Customer Ledger Entries at posting.
- Rounding and currency handling.
- Printed installment schedule.
- Basic API exposure.

### Slice 2: Complete receivables

- Sales credit memos and corrections.
- Payment discounts per installment.
- Payment application and unapplication.
- Statements.
- Reminders and finance charges.
- Payment reconciliation.
- Cash Flow Forecast.
- Aging reports.

### Slice 3: Payables

- Purchase documents.
- Vendor Ledger Entries.
- Suggest Vendor Payments.
- Payment exports and remittance advice.
- Purchase corrective documents.

### Slice 4: Advanced terms

- Fixed amounts.
- Day-of-month and cutoff calculations.
- Working-day calendars.
- Document-specific schedule editing.
- Approval for overrides.
- Customer/site/document precedence.
- Subscription Billing, Service, and Project integration.

### Slice 5: Renegotiated plans

- Create an installment plan over existing open entries.
- Interest and fees.
- Approval workflow.
- Broken-plan status.
- Collections and promise-to-pay integration.

## 12. Essential acceptance-test matrix

Automate the following scenarios as their corresponding capabilities are
delivered.

| ID | Scenario | Expected outcome |
| --- | --- | --- |
| AT-01 | Split an invoice 30/30/40%. | Allocations follow the percentages and reconcile exactly using currency rounding. |
| AT-02 | Create three equal installments. | The final installment receives the rounding remainder; the total equals the invoice. |
| AT-03 | Pay a foreign-currency invoice at different exchange rates. | Each installment application records correct realized currency gains or losses. |
| AT-04 | Post prices including VAT and an invoice discount. | The schedule reconciles to the final invoice total without duplicating tax or recognition. |
| AT-05 | Fully pay one installment within its discount period. | That installment closes with its eligible discount while later installments remain open. |
| AT-06 | Partially pay one installment. | Only the applied amount is settled; the entry retains its identity and correct remaining amount. |
| AT-07 | Apply one payment to two installments. | Both applications and remaining amounts are correct. |
| AT-08 | Apply to Oldest across two invoices and six installments. | Allocation follows due date, then installment sequence. |
| AT-09 | Apply a credit memo before any payment. | The selected credit-allocation behavior preserves invoice and installment reconciliation. |
| AT-10 | Apply a credit memo after one installment is paid. | Allocation follows the selected policy without reopening settled amounts. |
| AT-11 | Unapply and reapply a payment. | Installment identity is preserved and balances and application effects remain correct. |
| AT-12 | Create a reminder when only installment 1 is overdue. | Only overdue amounts are included; future installments are not accelerated. |
| AT-13 | Suggest vendor payments when installments 1 and 2 are due but 3 is not. | Only eligible installments are suggested within the selected horizon. |
| AT-14 | Calculate a due date on a nonworking day. | The configured working-day adjustment is applied when calendar support is delivered. |
| AT-15 | Change payment terms before posting. | The preview and posted schedule reflect the recalculated terms. |
| AT-16 | Change Payment Terms setup after posting. | Posted installment entries and their schedule remain unchanged. |
| AT-17 | Cancel or correct an unpaid installment invoice. | All installment entries are handled as one logical invoice with traceable correcting documents. |
| AT-18 | Automatically cancel an invoice with a settled installment. | Cancellation is blocked where existing BC paid-invoice cancellation rules require it. |
| AT-19 | Apply payment tolerance and discount tolerance. | Tolerances are evaluated correctly at installment-entry level. |
| AT-20 | Upgrade Italian Payment Terms Lines. | Setup migrates according to the approved mapping without changing existing posted obligations. |

## 13. Minimum credible V1 and release boundary

The smallest credible V1 includes:

- Payment-term lines.
- Percentage plus balance allocation.
- Independent due dates and payment discounts.
- Schedule preview.
- Separate ledger entries.
- Correct rounding and currency handling.
- Printed schedules.
- Payment application.
- Credit memo handling.
- Reminders.
- Payment suggestions.

A schedule-only implementation is insufficient if actual receivables and
payables processes cannot consistently recognize and settle its installments.

Advanced dates and calendars, fixed amounts, document-specific overrides, and
renegotiated collections plans are later increments as outlined above.

## 14. Decisions to resolve before implementation

The supplied proposal leaves the following choices open:

- Exact V1 document coverage and release scope across the proposed slices.
- Percentage-validation tolerance and mixed allocation rules.
- Whether Remaining Amount must be the final line.
- Conditions permitting zero installments, discount dates after due dates, or
  nonmonotonic due dates.
- Terms-date selection and the scope of date-strategy extensibility in V1.
- Action versus FactBox presentation for the schedule preview.
- Partial-payment discount eligibility within an installment.
- Unpaid-invoice correction strategy and default credit-memo allocation policy.
- Detailed Italian localization migration rules.

Resolve these choices without weakening the core invariant: **one commercial and
tax invoice, with independently managed ledger obligations for its installments**.

## 15. First implementation milestone: W1 sales vertical slice

### 15.1. Objective and release status

Deliver a W1-owned path from payment-term setup through sales invoice schedule
preview to posted installment customer ledger entries.

This is an **internal, opt-in implementation milestone**, not the complete V1
defined in section 13. It establishes the shared calculation and posting contract
before broad document coverage or IT migration.

Success means a supported sales invoice produces one posted invoice, the normal
commercial and tax postings, and N correctly linked receivable entries whose
amounts and dates match the schedule.

### 15.2. Proposed milestone boundary

The following are proposed implementation defaults, subject to design sign-off.
They narrow the broader requirements for this milestone only.

| Area | Included in M1 | Deferred or guarded in M1 |
| --- | --- | --- |
| Sales source | Standalone Sales Invoice, posted in full. | Orders, partial invoicing, combined shipments, and alternate producers. |
| Allocation | Percentage lines and one final Remaining Amount line. A complete percentage-only allocation is also supported. | Fixed amounts and manually edited schedules. |
| Dates | Document Date baseline; standard DateFormula per line. | Alternate baselines, calendars, cutoff rules, and working-day adjustment. |
| Currency | LCY and one document currency; reconcile document-currency and LCY totals independently. | Additional reporting currency until its posting allocation is implemented and verified. |
| Discounts | Per-line discount dates and percentages, posted discount eligibility amounts. | New partial-payment discount policies and multiple discount tiers. |
| Tax and invoice discounts | Existing VAT calculation, prices including VAT, and invoice discounts. | Tax regimes or discount/tax combinations not yet covered by the posting contract. |
| Customer entries | One entry per nonzero installment with shared plan identity. | Vendor installment posting. |
| User experience | Editable terms setup, read-only draft and posted schedule, plan-aware posted invoice totals and entry navigation. | FactBox, schedule overrides, new schedule APIs, and printed schedule layouts. |
| Lifecycle | Basic manual receipt application smoke coverage and truthful invoice status. | Full application-policy changes, reminders, reconciliation, and collections output. |
| Corrections | Explicit rejection of unsupported plan-aware automatic corrections and cancellation. | Implementing installment credit allocation and full correction flows. |
| Italy | Reference scenarios and preservation of legacy behavior during propagation. | Activation of global plans in IT, migration, and replacement of legacy posting. |

Printed schedules and new public schedule APIs remain part of Slice 1, but follow
this first vertical milestone. Existing invoice API balances/status must remain
truthful; that compatibility work is not deferred with new API exposure.
No production rollout is permitted until the broader release gates, including
correction and settlement behavior, are met.

Unsupported combinations must fail before posting writes begin, with a specific
localized error identifying the limitation. Never silently collapse an
installment invoice into one ledger entry or ignore selected installment terms.
Ordinary documents without global installment plans must remain unaffected.

### 15.3. Verified W1 integration points

Paths below are relative to `src\Layers\W1\BaseApp`.

| Existing object | Observed responsibility | Planned change |
| --- | --- | --- |
| `Foundation\PaymentTerms\PaymentTerms.Table.al` | Single due-date formula and discount conditions. | Add access to subordinate installment rules; preserve the no-lines path. |
| `Foundation\PaymentTerms\PaymentTerms.Page.al` | Payment Terms setup UI. | Add Installment Lines action and clear indication that terms use a schedule. |
| `Sales\Document\SalesHeader.Table.al` | Validates payment terms and derives header due date and discounts. | Create or replace document rule snapshots, support schedule calculation, and distinguish summary fields from installment conditions. |
| `Sales\Posting\SalesPostInvoice.Codeunit.al`, `PostLedgerEntry` | Builds the customer journal line using final invoice totals and calls `RunWithCheck`. | Supply an explicitly scoped installment posting context based on authoritative final totals. |
| `Finance\GeneralLedger\Posting\GenJnlPostLine.Codeunit.al`, `PostCust` | Creates the customer entry, detailed buffers, application effects, and posting links. | Create installment entries within the existing posting transaction without repeating complete invoice posting. |
| `Sales\Posting\SalesPost.Codeunit.al`, `UpdateSalesHeader` | Finds one entry and assigns `Cust. Ledger Entry No.` on the posted invoice. | Preserve a deterministic legacy entry link and associate the invoice with its complete plan. |
| `Sales\History\SalesInvoiceHeader.Table.al` | `Closed` and `Remaining Amount` FlowFields use the single entry link; `GetRemainingAmount` returns the first matching entry. | Introduce plan-aware aggregate access and update milestone consumers explicitly. |
| `Sales\History\CorrectPostedSalesInvoice.Codeunit.al` | Reads the linked entry and invoice remaining amount. | Guard unsupported installment correction paths before they can use single-entry assumptions. |

Do not treat existing posting events as proof that split posting is safe.
Preserve their signatures and document which events continue to be document-level
and which execute per ledger entry.

### 15.4. Architecture and ownership

Keep setup, validation, and calculation in a focused W1 Installments area under
`Foundation\PaymentTerms`. Integrate document-specific behavior in Sales and
accounting behavior in the existing posting pipeline.

Use ordinary typed AL records, enums, and codeunits. The calculator must not
depend on IT objects, pages, or posting codeunits.

Suggested responsibilities, with final object names and IDs assigned during
implementation:

| Component | Responsibility |
| --- | --- |
| Payment Term Installment table | Ordered reusable payment-term rules. |
| Installment Plan table | Document-owned snapshot identity, lifecycle, baseline, currency, and source/posted document links. |
| Installment Plan Line table | Snapshotted rules and, after posting, immutable original allocations and ledger-entry links. |
| Allocation Type enum | Percentage and Remaining Amount for M1; leave a clean path for later Fixed Amount support. |
| Installment calculation codeunit | Validate and calculate schedules into temporary plan-line records without database writes. |
| Sales installment management codeunit | Copy rules to documents, obtain existing sales totals, coordinate preview and posting context. |
| Setup and schedule pages | Edit reusable rules; display calculated or posted schedules read-only. |

Use the plan-line record temporarily for calculation rather than adding a second
nearly identical calculation-buffer table.

Do not introduce a generic workflow engine or a pluggable strategy framework
before there is a concrete second implementation. Provide focused extension
events where an identified localization needs them.

### 15.5. Data contract and identity

**Payment-term rule**

- Key: Payment Terms Code and Line No.
- Fields: allocation type, payment percentage, due-date formula, discount-date
  formula, discount percentage, and description.
- Setup lines can be incomplete while being edited; selecting them for a document
  or posting requires a valid complete set.
- Payment Terms without lines follow existing W1 behavior, with no synthetic
  persistent plan.

**Plan header**

- Company-scoped Plan ID of type Guid, independent of document numbering.
- State: Draft or Posted.
- Typed source-document identification, including SystemId and document number.
- Baseline date, currency code, and snapshotted payment-terms identity.
- Posted invoice identity and original invoice total in document currency and LCY.
- A Draft plan belongs to one source invoice. A Posted plan belongs to one posted
  invoice. Reusing the plan ID while making that transition is intentional.
- Copying an invoice creates a new plan ID; it must not share mutable lines with
  the source or reuse a posted plan ID.

**Plan line**

- Key: Plan ID and Line No.; expose a consecutive Installment No. for users.
- Store rule snapshots independently of reusable Payment Terms setup.
- Calculate draft dates and monetary amounts into temporary records on demand.
- Persist final due date, discount date/percentage, original discount eligibility,
  allocation amount, LCY allocation, rounding adjustment, and customer ledger
  Entry No. when posting succeeds.
- Do not maintain a second mutable remaining balance or payment status on the
  plan line. Read those from the linked ledger entry.
- Posted original allocations and conditions are immutable; setup edits,
  application, and unapplication must not rewrite them.

**Existing records**

- Add a Plan ID link to Sales Header and Sales Invoice Header.
- Add Plan ID, Installment No., and No. of Installments to customer ledger entries.
- Retain the original posted invoice number, external document number, bill-to
  customer, currency, and relevant dimensions on each entry.
- Index plan-based entry lookup. Allocate object and field IDs only after checking
  W1 and dependent-country objects for conflicts.
- Preserve `Cust. Ledger Entry No.` as a legacy navigation link to a documented,
  deterministic member of the plan. It is not the whole-invoice balance source.

### 15.6. Document lifecycle and setup snapshots

1. Selecting installment Payment Terms copies a validated rule set into a new
   Draft plan. Handle an unsaved Sales Header through its normal insertion flow;
   do not leave orphan plans if document creation is abandoned.
2. Revalidating the same code during date updates must not silently reload changed
   reusable setup. Distinguish recalculating the existing snapshot from explicitly
   replacing it.
3. Changing terms explicitly replaces the draft snapshot. Switching to ordinary
   terms removes the draft plan and restores standard header behavior.
4. Changing document date recalculates dates; changing prices, quantity, VAT,
   currency, or invoice discount recalculates allocations using current totals.
5. Opening the Schedule action always calculates from current document totals.
   The initial action-based UI avoids maintaining a live persisted amount cache.
6. Posting recalculates using final posting totals, validates again, and uses that
   result rather than trusting a previously viewed preview.
7. Successful posting changes the plan to Posted, links every posted installment,
   and retains the schedule after the source invoice is deleted.
8. Deleting an unposted invoice deletes only its Draft plan. Copying, renaming,
   reopening, and changing bill-to customer must preserve or explicitly replace
   the snapshot according to existing document rules.

For installment documents, show header Due Date as the first scheduled due date,
clearly labeled as a summary in the affected UI. Prevent header discount fields
from overriding line conditions. Do not feed this summary back into installment
calculation. Final treatment of VAT Base Discount % must be resolved before
enabling combinations affected by line-specific discounts.

### 15.7. Calculation contract

Inputs are a rule snapshot, Document Date, currency rounding precision, LCY
rounding precision, authoritative document/LCY totals, and the discount bases
provided by existing BC posting rules.

Calculation must be deterministic and side-effect free:

1. Validate allocation types, percentage bounds, complete allocation, and formulas.
2. For percentage-only schedules, require a total of 100 at the supported
   percentage-field precision; do not use currency tolerance to excuse a
   percentage-total error.
3. If present, require exactly one Remaining Amount line in the final position.
   Its preceding percentages must leave a positive remainder.
4. Calculate percentage allocations from the original total, not from a shrinking
   balance. Allocate the final monetary residual to the last installment, including
   for a percentage-only schedule.
5. Allocate LCY from the authoritative posted LCY total with an independent final
   remainder. Do not independently convert each rounded document-currency line
   and accept a changed control-account total.
6. Calculate dates from the same Document Date. Require due-date formulas,
   nondecreasing due dates, and nonzero installment amounts after rounding.
7. Calculate each discount using existing eligible-base, tax, and rounding rules,
   with the installment's discount percentage/date. A single invoice-wide
   discount must not be copied in full to every entry.
8. Return specific validation errors, including the offending installment line.

The preview displays positive invoice amounts; posting applies the existing
customer-journal sign convention exactly once. Reject unsupported zero or
net-negative installment invoices without changing ordinary invoice behavior.

Do not introduce separate tax recognition per installment. Amount-excluding-tax
and tax allocations are informational and must reconcile to existing invoice
totals if displayed; they do not drive additional VAT posting.

### 15.8. Posting integration sequence

1. Complete support and rule checks before posting-number updates or other posting
   writes. Validate amount-dependent allocations against available totals early
   and revalidate against final totals before splitting the receivable.
2. Recalculate against final `TotalSalesLine` and `TotalSalesLineLCY` amounts in
   the invoice-posting pipeline. Include invoice rounding in the final obligation.
3. Pass the schedule explicitly to the customer-posting invocation. Do not rely on
   SingleInstance state or a context that can leak into the next journal line.
   Clear or scope any instance context on success and failure.
4. Check duplicate invoice and external-document restrictions once for the
   logical invoice, not once for each installment inserted during the same post.
5. Within `PostCust`, initialize fresh customer and detailed-entry buffers for
   each installment. Allocate unique entry numbers through the existing posting
   mechanism and maintain transaction/register consistency.
6. Allocate every affected monetary buffer field, not just Amount: LCY, sales,
   profit, invoice discount, source-currency amounts, payment-discount eligibility,
   and other required accounting amounts. Distinguish additive allocations from
   recalculated eligibility/tolerance fields; see section 16.3.
7. Reuse normal detailed customer posting and receivables control-account posting.
   The sum of installment control amounts must equal the unsplit invoice.
8. Keep revenue, VAT, inventory, and document-level deferral work outside the
   installment loop. Never loop the entire Sales-Post or `RunWithCheck` pipeline
   for the complete invoice once per installment.
9. Record customer-entry links in the posted schedule and set posted invoice plan
   identity within the same transaction.
10. Preserve posting preview, suppress-commit behavior, and error rollback.
    Introduce no new `COMMIT`. Failure on a later installment must not leave a
    posted invoice, partial plan, or partial financial entries.

For M1, explicitly guard on-invoice balancing payments, prepayments, application
to existing entries during invoice posting, and unsupported journal producers.
Normal later manual receipt posting remains available for targeted application
verification. These guards are limitations of the milestone, not global product
requirements.

### 15.9. Posted invoice totals, navigation, and safety

This is part of M1 correctness, not a reporting enhancement to postpone.

- Provide plan-aware accessors for total remaining amount and closed status.
  Aggregate linked ledger entries by Plan ID, never by document number alone.
- For ordinary invoices, retain the current behavior.
- Update the posted invoice card/list surfaces included in the milestone to use
  plan-aware values and drill down to all installments.
- Opening a posted schedule reads immutable original allocations and current
  ledger balances, even after Payment Terms setup has changed or been deleted.
- A paid first installment must not make the entire invoice appear closed.
- A later installment must not disappear because an existing caller uses
  `FindFirst`, `FindLast`, or the single linked entry.
- Inventory all consumers of the single-entry fields, including FlowField filters,
  APIs, reports, correction, and payment actions. Classify them as adapted in M1,
  explicitly blocked in M1, or a production-release blocker.
- Do not claim that adding accessors fixes existing `Closed` or `Remaining Amount`
  FlowFields. Their direct consumers and filters require an explicit compatibility
  design before M1 posted card/list and API integration; avoid broad
  historical-data changes merely to make M1 work.
- Guard automatic correction/cancellation and other identified unsafe actions for
  global installment invoices until plan-aware implementations exist.

### 15.10. Italy reference and country propagation

Reference these IT objects without importing them into the W1 dependency graph:

- `Local\Foundation\PaymentTerms\PaymentLines.Table.al`: reusable terms and
  document/journal payment-line representation.
- `Foundation\PaymentTerms\PaymentTerms.Table.al`: line totals and local setup
  behavior.
- `Finance\GeneralLedger\Posting\GenJnlPostLine.Codeunit.al`: customer/vendor
  loops, final-line residuals, discounts, and occurrence-based identity.

Extract reference scenarios for 30/60/90 dates, percentages, discount conditions,
document-currency/LCY residuals, and multiple entries per invoice. Compare intended
outcomes, not table layouts or local object identifiers.

After W1 changes, run `Invoke-Miapp` and resolve country variants deliberately.
In IT, route an invoice to either legacy installment posting or the new global
path, never both. For M1, keep global-plan activation blocked in IT until the
combined posting path is safely reconciled; ordinary legacy IT terms continue
using their existing behavior.

Other countries with installment-related behavior require the same conflict
review. Successfully merging files does not establish semantic compatibility.

### 15.11. Dependency-ordered implementation work packages

These are suggested reviewable changes, not a request to create branches or PRs.

| Package | Depends on | Work | Completion evidence |
| --- | --- | --- | --- |
| M1-01: Contracts and compatibility inventory | None | Confirm scope, inspect all split monetary fields and single-entry consumers, map IT reference cases, define unsupported-path guards. | Evidence-backed field-allocation map, consumer classification, and explicit decision gates; required approvals precede the dependent implementation. |
| M1-02: Setup and calculation | M1-01 | Add term rules, validation, pure calculator, setup action, permissions, and translations/localizable text following repository conventions. | Focused calculation cases cover allocation, dates, rounding, invalid setup, and legacy no-lines behavior. |
| M1-03: Draft document schedule | M1-02 | Add plan snapshots, lifecycle handling, read-only Schedule action, existing-totals integration, and header summary behavior. | Preview is accurate after edits; setup changes do not silently replace snapshots; copy/delete creates no shared or orphan plan. |
| M1-04: Customer posting | M1-03 | Integrate final schedule, split customer/detailed entries, allocate buffer fields, persist posted links, and preserve transaction semantics. | Posted amounts reconcile to an equivalent ordinary invoice; preview and failed-post checks leave no persistent accounting changes. |
| M1-05: Posted experience and guards | M1-04 | Add plan-aware balances/navigation and filters, existing API status refresh, correction/edit/application guards, and manual application smoke coverage. | Paying any installment leaves truthful invoice totals/status in UI and existing APIs; unsafe entry points reject the operation before writes. |
| M1-06: Integration and milestone sign-off | M1-05 | Propagate with Miapp, reconcile country variants, preserve IT legacy execution, and complete targeted regression review. | M1 acceptance matrix passes in the designated validation environment; remaining release blockers are recorded. |

M1-01 investigation is documented in section 16. Its proposed contracts and
guards are a design baseline, not evidence that AL implementation or runtime
validation has been completed.

Propagate shared-file changes as each package lands; do not defer all country
conflict discovery to the final package.

### 15.12. Focused M1 acceptance matrix

Use existing AL test libraries. Place calculator/setup and posting tests under
`src\Layers\W1\Tests\ERM`; extend application tests under
`src\Layers\W1\Tests\ERM-Application` only for behavior introduced by this
milestone. IT reference cases belong in the appropriate country test scope.

| ID | Scenario | Required assertion |
| --- | --- | --- |
| M1-AT-01 | Ordinary invoice with terms containing no installment lines. | Existing dates, discounts, single-entry posting, and navigation remain unchanged. |
| M1-AT-02 | 30/30/40 allocation and percentage-plus-remainder allocation. | Exact totals, correct order, and deterministic final remainder. |
| M1-AT-03 | Three equal installments on DKK 10,000. | DKK 3,333.33 / 3,333.33 / 3,333.34. |
| M1-AT-04 | Currency precisions including whole units and three decimals. | Use configured precisions; never assume two decimal places. |
| M1-AT-05 | Foreign-currency posting with an LCY rounding difference. | Both currencies reconcile independently to authoritative posting totals. |
| M1-AT-06 | Invalid percentages, misplaced/multiple balance lines, missing formula, zero rounded amount, or descending dates. | Specific validation error; posting creates no financial records. |
| M1-AT-07 | Change date, currency, quantities, prices, VAT, or invoice discount. | A freshly calculated preview matches the final posted schedule. |
| M1-AT-08 | Edit reusable terms after a draft snapshot; explicitly reload terms; edit terms after posting. | Draft remains stable until explicit replacement; posted schedule is immutable. |
| M1-AT-09 | Copy/delete draft invoice or change selected terms. | Correct plan ownership and cleanup; no sharing of mutable snapshots. |
| M1-AT-10 | Post a supported VAT invoice with invoice discount. | One posted invoice; unchanged commercial/tax totals; installment receivables sum to the control amount. |
| M1-AT-11 | Configure different payment discounts by installment. | Dates and original discount eligibility follow each line and the existing eligible-base rules. |
| M1-AT-12 | Inspect metadata and detailed entries. | Unique entry numbers; correct plan/sequence links, customer, dimensions, currency, and external document number. |
| M1-AT-13 | Posting preview and injected failure on a later installment. | No persistent partial posted plan or accounting entries; a retry creates only one complete result. |
| M1-AT-14 | Fully settle the first installment; partially settle another. | Ledger balances and aggregate invoice remaining amount/closed status are correct. |
| M1-AT-15 | Open the posted schedule after setup changes. | Original allocations remain visible; current balances come from ledger entries. |
| M1-AT-16 | Attempt unsupported producer, correction, cancellation, or posting combination. | Explicit rejection before writes; ordinary noninstallment documents are unaffected. |
| M1-AT-17 | Post an ordinary invoice after an installment post or failed attempt. | No leaked schedule context or accidental splitting. |
| M1-AT-18 | Propagate shared posting changes into IT. | Legacy reference cases still work; global-plan activation cannot invoke a second split. |
| M1-AT-19 | Settle a non-anchor installment; then settle the legacy-anchor installment while another remains open. | Existing API remaining amount/status refresh after either entry changes; the invoice does not become Paid prematurely. |
| M1-AT-20 | Filter posted invoices through Open/Paid views after partial settlement. | Both ordinary and installment invoices appear under the correct filter, not merely with correct displayed text. |
| M1-AT-21 | Exercise implicit Apply to Oldest, document-number application, and legacy due-date editing. | Unsupported operations fail at shared business boundaries; selected-entry manual application still works and does not overwrite the header summary. |
| M1-AT-22 | Use per-installment discount rates, tolerance caps, negative profit, and a rounded zero-LCY/nonzero-document amount. | Preserve independent statistical totals; discount/tolerance follows the stated per-entry rules without division by zero or invoice-total duplication. |

Manual application checks in M1 are safety coverage, not a claim that the full
application, currency revaluation, discount-tax, and unapplication matrix in
section 12 is complete.

### 15.13. Blocking decisions and exit criteria

Before M1-04 starts, approve:

- The final object/field allocation and plan-to-document lifecycle.
- The field-by-field posting allocation map and handling of LCY residuals.
- Header due-date summary semantics and interaction with VAT Base Discount %.
- Supported discount/tax combinations and exact pre-posting guards.
- The legacy entry-link convention and plan-aware consumer strategy.
- Feature activation and IT conflict-resolution approach.

M1 is complete when:

- The W1 vertical path works without any IT runtime dependency.
- Supported preview and posting produce the same schedule.
- Every installment has a traceable customer ledger entry and correct detailed
  accounting; document/LCY and control-account totals reconcile.
- Posted balances and navigation do not present one installment as the invoice.
- Unsupported lifecycle actions are blocked clearly, not silently approximated.
- No-lines W1 behavior and legacy IT behavior are preserved.
- Targeted acceptance checks have passed in the designated validation environment
  and Miapp propagation has been reviewed.

Production activation additionally requires the deferred Slice 1 output/API work
and the broader V1 settlement, correction, collection, and payables requirements.
M1 completion alone must not enable the feature for unrestricted production use.

## 16. Step 1 results: posting contract and compatibility inventory

**Status:** Source investigation complete. No AL objects or posting behavior have
been changed. The recommendations below make the next setup/calculator work
concrete while identifying decisions that must be resolved before posting or
posted-document integration.

**Scope of evidence:** Current W1 BaseApp sources, the directly relevant APIV1
and APIV2 invoice endpoints, and selected IT historical behavior. This is not a
claim that every extension, report layout, localization, or external integration
has been certified for installments.

### 16.1. Source evidence

Paths are relative to the repository root. Line numbers identify the inspected
source and may shift during implementation.

| ID | Source | Evidence |
| --- | --- | --- |
| S01 | `src\Layers\W1\BaseApp\Sales\Posting\SalesPost.Codeunit.al:523-531` | Reverses normal invoice totals before calling invoice posting. |
| S02 | `src\Layers\W1\BaseApp\Sales\Posting\SalesPostInvoice.Codeunit.al:604-667` | Constructs the customer journal line, copies document/payment/application fields, and assigns final amount fields. |
| S03 | `src\Layers\W1\BaseApp\Finance\GeneralLedger\Posting\GenJnlPostLine.Codeunit.al:1310-1428` | W1 creates one customer entry, initial detailed buffer, discount/tolerance state, application effects, and control-account postings. |
| S04 | `src\Layers\W1\BaseApp\Sales\Receivables\CustLedgerEntry.Table.al:1442-1505` | Copies journal metadata and sales/profit/invoice-discount statistics; transfers calculated CV-buffer values back to the customer entry. |
| S05 | `src\Layers\W1\BaseApp\Finance\ReceivablesPayables\DetailedCVLedgEntryBuffer.Table.al:495-585,608-624` | Initializes detailed amounts and initial due date; derives remaining/original amounts when inserting the initial buffer entry. |
| S06 | `src\Layers\W1\BaseApp\Finance\GeneralLedger\Posting\GenJnlPostLine.Codeunit.al:2712-2775,7392-7402` | Calculates discount eligibility and tolerance; VAT-exclusive discount fallback queries journal-wide VAT totals. |
| S07 | `src\Layers\W1\BaseApp\Finance\GeneralLedger\Posting\GenJnlPostLine.Codeunit.al:4255-4326,7789-7808,8026-8124` | Posts detailed customer buffers and creates receivables G/L amounts, including source/additional-currency handling. |
| S08 | `src\Layers\W1\BaseApp\Sales\Posting\SalesPost.Codeunit.al:6158-6210` | Links the posted invoice to the last matching customer entry through a single Entry No. |
| S09 | `src\Layers\W1\BaseApp\Sales\History\SalesInvoiceHeader.Table.al:1088-1118,1158-1164,1669-1682` | Closed, Remaining Amount, and Reversed use one linked entry; `GetRemainingAmount` returns the first matching entry. |
| S10 | `src\Layers\W1\BaseApp\Sales\History\PostedSalesInvoices.Page.al:92-96,233-236,742-751`; `src\Layers\W1\BaseApp\Sales\History\PostedSalesInvoice.Page.al:294-300` | Invoice list/card display entry-based status; Open/Paid list views filter the existing Closed FlowField. |
| S11 | `src\Layers\W1\BaseApp\Sales\History\CorrectPostedSalesInvoice.Codeunit.al:266-277,376-390,553-566` | Applied-entry navigation and paid-invoice correction checks depend on single-entry state. |
| S12 | `src\Layers\W1\BaseApp\Sales\Posting\SalesPostInvoice.Codeunit.al:673-769` | Immediate balancing payment calculates discount effects using one found entry and applies by document number. |
| S13 | `src\Layers\W1\BaseApp\Finance\GeneralLedger\Posting\GenJnlPostLine.Codeunit.al:3854-3895,4144-4203` | Explicit Applies-to Doc. No. selects one open entry; Applies-to ID builds a set; Apply to Oldest can trigger without explicit application fields. |
| S14 | `src\Layers\W1\BaseApp\Integration\Entity\SalesInvoiceAggregator.Codeunit.al:584-635`; `src\Apps\W1\APIV2\app\src\pages\APIV2SalesInvoices.Page.al:803-815,1148-1149`; `src\Apps\W1\APIV1\app\src\pages\APIV1SalesInvoices.Page.al:627-638,1076` | API status/update lookup uses the linked entry; API remaining amount calls the header helper; corrective actions read legacy fields. |
| S15 | `src\Layers\W1\BaseApp\Sales\History\SalesInvHeaderEdit.Codeunit.al:19-69,88-93`; `src\Layers\W1\BaseApp\Sales\Receivables\CustEntryEdit.Codeunit.al:34-65,103-129` | Header edits update one linked entry; entry edits can copy that entry's due date and other fields back to the invoice header. |
| S16 | `src\Layers\W1\BaseApp\Sales\History\SalesInvoicesDueNextWeek.Page.al:29-72,94-98`; `src\Layers\W1\BaseApp\Sales\History\StandardSalesInvoice.Report.al:1187-1195` | Dashboard filters header due date/Closed and drills to one entry; standard invoice output derives paid/partly-paid text from the remaining-amount helper. |
| S17 | `src\Layers\W1\BaseApp\Bank\Setup\PaymentServiceSetup.Table.al:395-412`; `src\Layers\W1\BaseApp\Finance\GeneralLedger\Journal\PostLateGenJournalLines.Codeunit.al:25-44` | Payment-service eligibility and specialized late posting use legacy invoice balances. |
| S18 | `src\Layers\W1\BaseApp\CashFlow\Worksheet\SuggestWorksheetLines.Report.al:79-95,877-906,1738-1750` | Posted receivables use entry-level dates/balances; the sales-order prepayment helper separately reads invoice-header balances. |
| S19 | `src\Layers\W1\BaseApp\Sales\Reports\AgedAccountsReceivable.Report.al:240-259,497-518`; `src\Layers\W1\BaseApp\Sales\Reminder\ReminderMake.Codeunit.al:521-529`; `src\Layers\W1\BaseApp\Sales\Reminder\Automation\Actions\SendReminders\SendReminderEventHandler.Codeunit.al:230-247` | Core aging/reminder selection is entry-based, but automated invoice attachments also depend on header Closed status. |
| S20 | `src\Layers\W1\BaseApp\Bank\DirectDebit\CreateDirectDebitCollection.Report.al:29-58`; `src\Layers\W1\BaseApp\Bank\Reconciliation\MatchBankPayments.Codeunit.al:1845-1877` | Direct debit selects invoice entries by due date; bank matching also traverses entries sharing document identifiers. |
| S21 | `src\Layers\IT\BaseApp\Finance\GeneralLedger\Posting\GenJnlPostLine.Codeunit.al:1556-1698,1755-1874,8429-8470` | Legacy customer/vendor split loops, independent residuals, discounts, occurrence identity, and journal-line payment lookup. |
| S22 | `src\Layers\IT\BaseApp\Local\Foundation\PaymentTerms\PaymentLines.Table.al:12-16,136-154,199-219,243-350` | One legacy table represents terms and document/journal lines; sales date calculation includes deferring/fixed due dates. |
| S23 | `src\Layers\IT\BaseApp\Sales\History\SalesInvoiceHeader.Table.al:1089-1105,1785-1804`; `src\Layers\IT\BaseApp\Sales\Receivables\CustLedgerEntry.Table.al:1088-1094,1206-1226` | IT aggregates the remaining-amount helper but retains the legacy header FlowFields; occurrence fields/keys participate in identity. |
| S24 | `src\Layers\W1\BaseApp\Sales\Posting\SalesPost.Codeunit.al:745-810` | Header checks precede posting-number updates and a possible commit; final invoice discounts and posted headers are processed later. |
| S25 | `src\Layers\W1\BaseApp\Finance\GeneralLedger\Journal\GenJournalLine.Table.al:7310-7335,7382-7401`; `src\Layers\W1\BaseApp\Finance\VAT\Setup\VATPostingSetup.Table.al:56-120` | Copies VAT base discount and automatic-application settings; VAT setup has distinct unrealized-tax and payment-discount-adjustment behavior. |

### 16.2. Observed posting trace

The relevant invoice path is:

1. Sales-Post checks the document, updates posting numbers, calculates invoice
   discounts, and inserts posted headers. Some source-header changes can be
   committed before final financial posting (S24).
2. Sales lines produce the commercial, VAT, inventory, and related posting work.
   Normal invoice totals are reversed before `PostInvoice` (S01).
3. `Sales Post Invoice.PostLedgerEntry` constructs one customer journal line from
   final totals and invokes `Gen. Jnl.-Post Line.RunWithCheck` once (S02).
4. `PostCust` initializes the customer entry and initial detailed buffer,
   calculates discount/tolerance conditions, checks document duplication,
   performs application, inserts the customer entry, and posts detailed/control
   entries (S03, S05-S07).
5. Sales-Post assigns the posted invoice's single customer-entry link (S08).

**Recommended insertion boundary:** Prepare the final schedule at step 3 and
perform the customer-obligation split inside step 4. Do not repeat line posting,
VAT posting, or the complete journal-line pipeline.

**Sign contract:** Take the sign from the final customer journal line. Its amount
is assigned as minus the posting totals, but those totals have already been
reversed for a normal invoice. Do not infer a negative receivable simply from the
assignment in `SalesPostInvoice` or negate a positive preview a second time.

**Atomicity contract:** No new commits. Keep financial entries, the posted
schedule, and its ledger links in one posting transaction. A failure must leave
no partial posted result. This does not promise rollback of posting-number or
source-header changes that standard Sales-Post has already committed.

### 16.3. Field-by-field allocation contract

The following is the proposed W1 contract, not a transcription of IT code.

For each additive monetary total `T`, calculate earlier allocations at the
appropriate precision and set the final allocation to
`T - sum(previous allocations)`. Allocate each independent total separately.
Do not derive all LCY/statistical amounts by converting rounded installment
amounts.

| Source / destination | Treatment per installment | Reconciliation / reason |
| --- | --- | --- |
| Journal `Amount` -> detailed/CV amount | Allocate the final signed invoice obligation using document currency precision. | Sum equals original journal Amount. |
| Journal `Amount (LCY)` -> detailed/CV LCY amount | Independently allocate the authoritative LCY total. | Sum equals original journal LCY amount, including exchange/rounding effects. |
| Journal `Source Currency Amount` | Allocate consistently with the customer obligation; preserve source currency code. | Sum equals the original source-currency amount; never repeat the full amount. |
| Journal `Sales/Purch. (LCY)` -> customer `Sales (LCY)` | Allocate the final net sales statistical total independently using LCY precision. | Customer-entry sales statistics must not multiply by installment count. |
| Journal `Profit (LCY)` -> customer `Profit (LCY)` | Independently allocate signed profit, including zero/negative profit. | Sum equals invoice profit; this is not a nonnegative installment validation target. |
| Journal `Inv. Discount (LCY)` -> customer statistic | Independently allocate the existing invoice-discount total. | Discount is already included in invoice totals; do not subtract it again. |
| Detailed buffer `Additional-Currency Amount` | Initialize with the installment document-currency amount as the existing initial-entry copy routine does. | This field also feeds source-currency/control posting even when no Additional Reporting Currency is configured (S05, S07). It must not be left at the full invoice amount or indiscriminately zeroed. |
| CV Original Amount / Original Amt. (LCY) | Derive through insertion of the installment initial detailed entry. | Do not independently write conflicting original balances. |
| CV Remaining Amount / Remaining Amt. (LCY) / Amount to Apply | Derive from the installment detailed buffer; no invoice-posting application in M1. | Initially equal the installment obligation; subsequent settlement remains ledger-owned. |
| Debit/credit amounts and Open/Positive flags | Use existing posting derivation from each signed entry. | Do not percentage-split flags or duplicate invoice-level debit/credit totals. |
| Due Date and detailed `Initial Entry Due Date` | Set both from the same installment calculation. | Aging/reminder logic must not inherit the header summary date for every entry. |
| Pmt. Discount Date / Payment Discount % | Set from the installment rule in the per-entry working context. | Never use the header's single discount condition as authority for the plan. |
| CV Original / Remaining Pmt. Disc. Possible | Calculate per installment from its eligible base, percentage, date/grace rules, and rounding. | Sum can intentionally differ from a legacy single-rate invoice discount; do not force a residual to an unrelated invoice-wide discount amount. |
| Journal `Orig. Pmt. Disc. Possible` and `(LCY)` | Treat as document-posting inputs distinct from the calculated CV eligibility fields; define their per-entry projection and any document summary explicitly. | S02 populates these from sales totals, whereas S06 calculates CV eligibility from other fields. They cannot simply be assumed to override `CalcPmtDiscPossible`. Discount-summary integration remains a pre-posting design gate. |
| Max. Payment Tolerance | Recalculate with installment Amount and Amount (LCY), respecting the customer block setting. | Use the standard cap per entry; the sum of capped tolerances need not equal the unsplit invoice tolerance. Do not copy one invoice-sized tolerance to every entry. This is the proposed M1 policy. |
| Pmt. Disc. Tolerance Date | Calculate from the installment discount date and existing grace-period setup. | It is date logic, not an allocated amount. |
| Original / Adjusted Currency Factor | Copy the existing posting factor to each entry. | Do not split factors; LCY originals still come from the authoritative allocated total. |
| VAT/base amounts and payment-discount VAT adjustments | Do not create additional invoice tax from the split. Initial detailed VAT adjustment amounts remain zero for the supported M1 path. | Unexpected nonzero adjustment buffers or unsupported tax settings require rejection, not repeated document-wide VAT amounts. |
| Additional Reporting Currency accounting amounts | Not supported in the initial M1 contract; guard global-plan posting when configured. | Supporting document-currency/LCY does not certify third-currency allocation. This is distinct from the initial buffer field above. |

Sources: S02, S04-S07. The zero-LCY/nonzero-document-currency edge case must retain
existing posting semantics and be covered explicitly; do not divide by zero or
invent discount eligibility where the standard routine skips calculation.

**Copied identity and metadata:** Bill-to customer, sell-to customer, document
type/number, external document number, posting/document dates, dimension set,
posting groups, source/reason codes, salesperson, payment method/reference, and
other unchanged journal metadata retain their existing copy rules (S04, S25).
Plan ID, installment sequence/count, and exact ledger-entry links are additional
identity, not replacements for standard fields.

**Entry numbers and buffers:** Use the existing entry-number/sequence machinery,
not `invoice entry number + sequence`. Reset per-entry temporary buffers and
apply plan metadata deliberately across `TransferFields` boundaries. Preserve
the shared invoice transaction/register relationship without assuming ledger
entry numbers are contiguous.

**Event contract:** Document-level checks and completion hooks remain once per
invoice/customer posting invocation. Entry initialization, insertion, and detailed
posting hooks execute for each actual entry. Keep existing event signatures;
publish only additional focused context where required. Do not implement the
global engine as a replacement subscriber that bypasses the normal pipeline.

### 16.4. Consumer-impact classification

Classification:

- **Adapt M1:** Required for the milestone to present correct data or perform its
  supported operations.
- **Guard M1:** Reject the unsupported operation through the shared business-logic
  boundary, not just by hiding a page action.
- **Release gate:** Inspected entry-based behavior or broader integration still
  requires certification before production activation; no compatibility claim
  follows merely from the new entries existing.

| Consumer | Observed assumption / behavior | Classification and contract |
| --- | --- | --- |
| Posted invoice single-entry link | Sales-Post currently chooses the last matching entry (S08). | **Adapt M1:** Preserve a deterministic final-installment legacy link for global plans, selected by plan sequence rather than a document-number-only search. No link change for ordinary invoices. |
| Header `GetRemainingAmount` | Returns the first matching customer entry (S09). | **Adapt M1:** Sum entries linked by Plan ID for global invoices, retaining the existing ordinary-invoice path. Also fixes callers such as standard invoice paid-text and API remaining amount. |
| Header Closed / Remaining Amount FlowFields | Read only the single linked entry (S09). | **Adapt M1:** Decide aggregate fields/query and filter strategy before posted UI work. A procedural helper does not change FlowField filters. |
| Header Reversed | Looks up the single linked entry (S09). | **Guard M1 / release gate:** Block unsupported reversal of plan entries until whole-invoice reversal/status semantics are implemented. |
| Posted invoice card and list | Display legacy values; Open/Paid list views filter Closed (S10). | **Adapt M1:** Correct both displayed values and saved/built-in filter behavior. Updating text controls alone is insufficient. |
| Correct/Cancel/Create Corrective Credit Memo and notifications | Paid test and applied-entry navigation read one entry (S11). | **Guard M1:** Cover all shared correction entry points and API callers before any credit document or cancellation tracking is written. |
| On-invoice balancing payment | Uses one entry's remaining discount and applies by invoice number (S12). | **Guard M1:** Reject a global-plan invoice with balancing-account/immediate-payment posting. |
| Explicit application by invoice number | `PrepareTempCustLedgEntry` uses `FindFirst` (S13). | **Guard M1:** Do not advertise this as whole-plan application. Reject ambiguous document-number application to a multi-entry global plan until the behavior is designed. |
| Manual Apply Entries using Applies-to ID | Builds a selected set of ledger entries (S13). | **Adapt M1:** Keep supported manual entry selection; verify settling/partly settling selected installments and truthful aggregate status. |
| Customer Apply to Oldest during invoice posting | Can activate even with blank Applies-to Doc. No./ID (S13, S25). | **Guard M1:** Reject global invoice posting for this application method in M1, rather than silently consuming earlier customer credits. |
| Apply to Oldest during later payments | Selects entries using a due-date key, but has no explicit new installment-sequence contract (S13). | **Release gate:** Verify equal-date ordering and multi-invoice cases before declaring the product requirement satisfied. |
| Existing invoice APIs and entity aggregate | Remaining helper and linked-entry status/update mapping (S14). | **Adapt M1:** Resolve updates from any plan entry to the owning invoice and recalculate whole-plan status. Reuse shared correction guards. No new schedule API schema is required for this fix. |
| Posted invoice edit and customer-entry edit | Header updates one entry; editing any entry can overwrite header summary fields (S15). | **Guard/adapt M1:** Reject unsupported installment term/date edits; prevent a later installment from overwriting the invoice summary. Do not block application-owned Amount to Apply/Applies-to ID updates. |
| Due-next-week dashboard | Uses header due date and Closed filter and drills to one entry (S16). | **Release gate:** Requires installment-aware due-horizon selection/drilldown, not just an aggregate invoice balance. Remains outside the certified internal M1 UI. |
| Standard invoice output | Uses remaining helper to print paid/partly-paid status (S16). | **Adapt M1** via the helper; **release gate** for schedule output, header discount/due labels, payment-service links, and other report layouts. |
| Payment-service changes | Eligibility reads legacy header fields (S17). | **Guard M1:** Reject unsupported service configuration/payment initiation for global plans; do not issue payment links based on one installment. |
| Specialized late journal posting | Reads legacy remaining amount and applies by document number (S17). | **Guard M1:** Reject global-plan targets until plan-aware late posting is designed. |
| Posted-receivable cash-flow forecast | Reads customer entry due date, remaining LCY, and discount state (S18). | **Release gate:** Good entry-based fit; verify totals, dates, and duplicate-document-number handling. Do not confuse it with the separately guarded order-prepayment helper. |
| Aging and core reminder selection | Operates on entry due dates and remaining amounts (S19). | **Release gate:** Verify buckets, fees/levels, grouping, and output. This is not a reason to block ordinary entry-based reads. |
| Automated reminder attachments | Uses invoice header Closed before attaching the invoice (S19). | **Release gate:** Must use whole-plan closure; entry-based reminder selection alone does not fix this integration. |
| Direct debit and bank reconciliation | Entry-based candidate selection plus document-number matching/grouping paths (S20). | **Release gate:** Verify mandate/date eligibility, consolidation, ambiguous matches, and installment remittance identifiers before enablement. |

The dashboard/report release gates are acceptable only while M1 is isolated as
an internal feature. An unrestricted company-level production switch cannot
treat these paths as silently supported.

### 16.5. IT historical reference scenarios

The following are source-derived scenarios to reproduce as reference fixtures,
not claims that new W1 runtime tests have already passed.

| Reference | Observed IT behavior | W1 lesson / disposition |
| --- | --- | --- |
| IT-R01: Percentage allocation | Splits customer and vendor amounts by line percentage (S21). | Reproduce 30/30/40 totals; implement the rule contract in W1-owned types. |
| IT-R02: Independent residuals | Final entry receives separate remaining document, LCY, sales, and profit amounts (S21). | Preserve independent residual handling. Also cover invoice-discount/source fields explicitly rather than assuming the IT loop is a complete new-field allocation specification. |
| IT-R03: Dates | Copies DateFormula rules and calculates due/discount dates from Document Date (S22). | Reproduce 30/60/90 and discount dates with the W1 calculator. |
| IT-R04: Advanced local dates | Supports customer deferring dates and fixed payment days, with month-length adjustment and date clamping (S22). | IT already has richer date behavior than the original research summary suggested. Capture it for future Italy support; do not silently replace it with plain W1 DateFormula during migration. |
| IT-R05: Per-line discounts | Uses line Discount % and line dates with split entry amounts; contains VAT-exclusive calculation paths (S21). | Use it as behavioral reference, not a copy/paste calculator. Preserve W1 grace/date eligibility and resolve VAT-base allocation explicitly. |
| IT-R06: Installment identity | Stores Document Occurrence and application occurrence references; corresponding keys support lookup (S21, S23). | New W1 Plan ID plus sequence must coexist with these local references until a deliberate migration contract exists. |
| IT-R07: Document snapshots/journal handoff | Payment Lines contains setup plus document/journal rows; posting selects rows by journal batch/template/line (S21-S22). | Retain the concept of document-owned rules and scoped posting handoff without adopting the overloaded legacy table/key. |
| IT-R08: Posted balance | IT `GetRemainingAmount` sums matching entries, while the inspected header FlowFields still use one link (S23). | Reuse the aggregation lesson, not every legacy assumption. W1 should group by explicit plan identity rather than rely solely on document/date filters. |

For M1, comparison fixtures cover customer behavior; vendor parity is recorded
as reference for the later payables slice. Migration of local fixed/deferring
dates, occurrence references, and posted history remains separate work.

### 16.6. Recommended M1 supported path and guards

This is the recommended engineering baseline from the investigation; it is not
a statement that the broader product requirements have been removed or approved.

**Supported path**

- Opt-in W1 standalone sales invoice, posted in full with a positive net
  receivable, ordinary realized VAT/no VAT, and ordinary invoice discounts.
- Percentage and final-balance allocation, Document Date formulas, document
  currency plus LCY, and read-only schedule preview.
- Gross-amount installment payment-discount eligibility using existing posting
  date/grace logic; no tax-base change caused by those discounts.
- Customer Application Method Manual; no application or balancing payment during
  invoice posting.
- Later manual receipts targeting selected ledger entries through Applies-to ID.
- Existing invoice API balances/status adapted without exposing a new schedule
  API, and internal posted invoice surfaces that show correct plan totals.

**Guard matrix**

| Guard | Reject / constrain | Required enforcement |
| --- | --- | --- |
| G01: Producer | Orders/partial invoicing, purchases, services, project/subscription producers, customer invoice journals, and other not-yet-supported producers using global installment terms. | Shared support validation plus producer checks. A recognized installment term must not fall through to ordinary single-entry posting. Document type Invoice alone is not proof of supported provenance. |
| G02: Invoice shape | Zero/negative net obligation, fixed allocation rules, invalid rules/dates, or zero document-currency installments after rounding. | Calculator and early sales validation; repeat final-total validation before financial posting. Negative profit or zero rounded LCY alone is not a negative/zero invoice. |
| G03: Prepayment/balancing | Existing prepayment deductions, prepayment invoice paths, or Bal. Account No. populated. | Early document check before prepayment-line creation and posting-number updates; retain lower-level defensive checks. |
| G04: Initial application | Applies-to Doc. No./ID, or customer Application Method Apply to Oldest. | Early document/customer check; do not silently change the customer's application setting. |
| G05: Tax/discount | VAT Base Discount % nonzero, Pmt. Disc. Excl. VAT enabled, relevant VAT setup Adjust for Payment Discount enabled, unrealized VAT, or nonstandard tax calculation not covered by the M1 contract. | Validate actual document/setup combinations and give a specific unsupported-combination error. Do not disable tax behavior or coerce discounts to zero. |
| G06: Third currency | Additional Reporting Currency configured. | Shared support check; do not confuse this with the initial detailed buffer's Additional-Currency Amount field. |
| G07: Corrections/reversal | Automatic cancel/correct, corrective credit creation/allocation, unsupported credit application, or reversal targeting global plan entries. | Common business-logic entry points, including notifications and API actions, before writes. Do not rely solely on page visibility. |
| G08: Ambiguous settlement | Later application by invoice number alone for a multi-entry global plan; unsupported automated settlement/payment services/late journal flow. | Resolve the target plan and reject ambiguity; preserve manual selected-entry application. |
| G09: Posted schedule edits | Changing installment dates/discount terms through legacy invoice/entry edit paths. | Reject actual unsupported condition changes, not all calls to Cust. Entry-Edit. Prevent accidental header-summary overwrite during ordinary application edits. |
| G10: Country execution | New global-plan activation in IT before the legacy/global posting path is reconciled. | Explicit activation/support boundary; Miapp must preserve legacy IT behavior, not wrap one split loop inside another. |

Guards validate proposed operations, not just feature-flag state. Ordinary
documents and historical entries without a global Plan ID keep their existing
behavior. Avoid adding unrelated blanket restrictions to customers or companies.

### 16.7. Decisions, readiness, and next work

| ID | Decision / recommendation | Gate |
| --- | --- | --- |
| D01 | W1 owns the new contract; IT is reference-only, with no historical reposting. | Agreed direction from this design discussion. |
| D02 | Adopt the conservative supported path and G01-G10 guards above for internal M1. | Proposed; confirm before implementing posting guards. |
| D03 | Calculator uses configured amount precisions, exact percentage-field precision for 100%, independent residuals, and immutable rule snapshots. | Recommended basis for M1-02; no IT schema dependency. |
| D04 | Per-entry discounts must use a supported eligible base and preserve W1 date/grace behavior; define the journal Orig. Pmt. Disc. Possible pair and header discount-summary contract. | Resolve before M1-04. Restrict tax/discount combinations until supported. |
| D05 | Legacy invoice Entry No. points to the final installment; Plan ID is authoritative for grouping and aggregate access. | Proposed; confirm before M1-04/M1-05. |
| D06 | Use an additive invoice-group entry key on customer and detailed customer entries. Ordinary entries group by their own number; global installments group by the final plan-sequence entry. Reuse existing Closed/Remaining Amount FlowFields with that key and backfill historical metadata during upgrade. | User approved for M1-05. Existing field identities and saved filters remain intact; financial amounts are not migrated. |
| D07 | Allocate globally safe object/field IDs and define draft-to-posted plan ownership, copy/delete, and producer handoff. | Detailed schema work before M1-02/M1-03 objects are finalized. |
| D08 | Existing API status updates from every plan entry are M1 compatibility work; new schedule endpoints remain deferred. | Required adjustment to the original milestone interpretation. |

**Next implementation package at Step 1 completion:** M1-02, setup and pure calculation, using the
allocation rules and focused edge cases above. Do not start split posting until
the discount-input contract, supported guards, field allocation, and identity
decisions have been settled.

Steps 2-5 have since been implemented. Current integration readiness and the
remaining environment-acceptance gates are recorded in section 21.

**Step 1 deliverables:** Posting trace and monetary allocation map, classified
consumer-impact inventory, IT reference fixtures, proposed supported-path/guard
matrix, and explicit decision gates. No build, test execution, migration, or
feature activation is part of this source-analysis step.

## 17. Step 2 implementation: setup and pure calculation

**Source implementation:** Added M1-02 setup and calculation objects. Document
integration, persistent plan ownership, posting, and feature activation remain
outside this step. The setup page explicitly states that its rules do not yet
affect document posting.

| Object | ID | Responsibility |
| --- | --- | --- |
| Payment Term Installment table | 8840 | Reusable ordered rules, allocation type, percentage, date formulas, discount conditions, and description. |
| Installment Allocation Type enum | 8840 | Percentage and final Remaining Amount. |
| Payment Term Installments page | 8840 | Edit rules for one payment term and explicitly validate the complete rule set. |
| Installment Plan Line table | 8841 | Shared snapshot/result shape; used only temporarily in this step. Persistent ownership and links follow in M1-03/M1-04. |
| Installment Calculation codeunit | 8840 | Copy reusable rules into a temporary snapshot, validate rules, and calculate from explicit inputs. |
| ERM Installment Calculation test codeunit | 134491 | Focused setup/snapshot and calculator cases. |

Object IDs and Payment Terms field 9 were checked against the repository sources
before adding them. This is a repository collision check, not an external ID
reservation.

### 17.1. Implemented behavior

- Payment Terms exposes a Has Installments indicator and Installment Lines
  action. Its existing date/discount fields and posting behavior are unchanged.
- Rules can be incomplete during editing. Explicit validation and snapshot
  creation require complete percentages or a correctly placed final balance.
  Percentages use five-decimal precision, not currency rounding tolerance.
- `CopyPaymentTerms` reads the selected setup, validates it, and replaces only a
  temporary snapshot. Ordinary terms return false with no synthetic lines.
- `Calculate` reads only a temporary snapshot and explicit inputs: document date,
  posting date, document/LCY totals and precisions, and payment-discount grace
  period. It does not reread setup or use Work Date.
- Each currency has independent rounding and final-line residuals. Nonpositive
  document-currency installments are rejected; a zero LCY allocation is allowed.
- Due dates must be nondecreasing and not precede the document date. Nonzero
  discounts require a formula and a date between document date and due date.
- Discount amounts implement the proposed M1 gross-base policy, including
  posting-date/grace eligibility and the standard zero-LCY exclusion. This does
  not enable unsupported VAT/discount combinations in posting.
- Calculation stages all results before replacing the temporary snapshot, so a
  later invalid line does not leave partially calculated line values.
- Setup permissions follow existing Payment Terms permissions. Deleting a
  persistent payment term removes its reusable rules, not copied snapshots.

### 17.2. Validation status

Focused AL cases cover original-total allocation, independent residuals, whole-
unit/three-decimal precision, final balance, due/discount dates, grace expiry,
zero LCY, malformed rules, failed-calculation isolation, temporary-only operation,
ordinary terms, snapshot independence, deletion, and rename ownership.

The user confirmed that the Step 2 changes compile in W1 and IT. Runtime
execution of codeunit 134491 has not been confirmed. Source review and country
propagation do not replace runtime validation. M1-02 is not a claim that the full
M1 acceptance matrix has passed.

Shared changes were propagated with `Invoke-Miapp`. Country merge resolutions
retain the existing Italian Calculation action/payment-line cleanup, Spanish
installment cleanup/events, and North American SAT field alongside the new W1
setup. No local or global posting loop was changed.

Staged source whitespace/conflict checks passed. `Invoke-MiSnapApp` validated all
43 changed source files and reported no missing country propagation paths.

## 18. Step 3 implementation: draft snapshots and schedule preview

**Source implementation:** Added M1-03 document-owned draft snapshots for
standalone sales invoices. Split posting remains outside this step. An invoice
with a global draft plan is explicitly blocked from posting until M1-04, rather
than silently creating a single receivable.

| Object | ID | Responsibility |
| --- | --- | --- |
| Installment Plan table | 8842 | Plan identity, draft status, typed source identity, and document context. |
| Installment Plan Status enum | 8841 | Draft lifecycle; Posted is reserved for the subsequent posting implementation. |
| Sales Installment Mgt. codeunit | 8841 | Snapshot ownership, invoice lifecycle, header guards, current-total preview, and temporary posting guard. |
| Sales Installment Schedule page | 8841 | Read-only temporary schedule calculated from current invoice totals. |
| ERM Installment Draft test codeunit | 134492 | Focused draft lifecycle, copying, preview, and guard cases. |

Sales Header field 8840 links the invoice to its plan. Object and field IDs were
checked against repository sources, not externally reserved.

### 18.1. Implemented behavior

- Selecting global installment terms snapshots validated rules into a plan owned
  by the invoice SystemId and typed RecordId. Unsaved and temporary headers do not
  create persistent plans; insertion binds a non-temporary header to its
  assigned SystemId.
- Stored lines contain rules only. Calculated dates, amounts, discount amounts,
  and rounding residuals remain temporary and are rebuilt when preview opens.
- Revalidating document dates retains the snapshot, even after reusable setup
  changes. Changing payment terms replaces the owned draft; ordinary terms
  remove it and resume native W1/local payment-term behavior.
- Copy Document clones the source rule snapshot into an independently owned
  plan. Copying over a draft removes the target's previous plan. Deletion removes
  only the matching owned draft, including when table triggers are disabled.
- Invoice due date is a read-only first-installment summary. Header payment
  discount percentage, date, and VAT-base discount cannot override the plan.
- Preview uses the standard Sales Statistics totals path, including current VAT,
  invoice discounts, document currency factor, and temporary invoice rounding.
  Document and LCY totals are allocated independently by the pure calculator.
  Automatic invoice-discount calculation can update normal invoice data; opening
  preview does not explicitly commit or cache calculated plan values.
- Preview rejects payment-discount plans when General Ledger Setup enables
  Pmt. Disc. Excl. VAT or Adjust for Payment Disc.; these combinations are not yet
  implemented by the proposed gross-base discount policy.
- Ordinary documents without a global plan retain native behavior. Adding
  reusable rules does not implicitly activate an existing ordinary invoice on
  document-date revalidation. Italian legacy payment terms continue through the
  existing local path unless a standalone invoice explicitly selects global
  installment rules. No Italian or W1 posting loop has been replaced.

### 18.2. Validation status

Codeunit 134492 contains 13 focused source cases covering snapshot ownership,
setup independence, replacement/removal, ordinary-document preservation, bill-to
changes, actual Copy Document, insertion/deletion without table triggers,
current-total preview, and header/posting guards.

The user confirmed Step 3 AL compilation. Runtime execution of codeunits 134491
and 134492 has not been confirmed and remains pending in the designated user
environment.

Shared changes were propagated with `Invoke-Miapp`. Manual resolutions preserve
the Italian legacy controls/events, Spanish mandatory fields and installment
cleanup, North American statistics/SAT controls, and Russian permissions. Italy
does not expose the W1 header discount controls on its invoice page; no W1
discount properties were applied to unrelated local controls.

Changed-source conflict-marker, namespace-import, and staged whitespace checks
passed. `Invoke-MiSnapApp -Files <explicit staged source paths>` validated all 92
changed AL source files across Steps 2 and 3 and reported no missing country
propagation paths. These are source checks, not AL compilation or runtime test
results.

## 19. Step 4 implementation: split customer posting

**Source implementation:** M1-04 replaces the temporary posting block with
split receivables for supported, fully invoiced standalone W1 sales invoices.
The user confirmed compilation completed. Runtime validation remains pending.
Posted-page navigation and invoice-wide aggregate/API behavior remain M1-05.

### 19.1. Posting integration and accounting

- New codeunit 8842 **Installment Posting** validates the supported producer,
  calculates from the final customer journal totals, verifies each native ledger
  result, persists the final schedule, and selects the legacy posted-header
  customer-entry anchor.
- Gen. Journal Line fields 8840 **Installment Plan ID** and 8841 **Sales Invoice
  Source SystemId** provide an explicit, invocation-local handoff. Posting checks
  the saved source, owned Draft plan, and posted invoice's native Draft Invoice
  SystemId. There is no global/SingleInstance posting context.
- The customer entry pipeline is extracted into `PostCustEntry` and invoked once
  per installment. The whole sales invoice and its revenue, VAT, inventory, and
  document posting pipeline are not repeated. Ordinary customer journals still
  execute the native per-entry path once.
- Each installment receives its own journal amounts, due date, and discount
  conditions before native initialization, detailed-entry creation, discount and
  tolerance calculations, and entry-insertion events. Numbering remains native;
  no anchor-plus-sequence entry-number arithmetic is used. Invoice duplicate
  number checks run on the first installment only.
- Document amount, LCY amount, source-currency amount, Sales (LCY), Profit (LCY),
  and Invoice Discount (LCY) are allocated independently. Each column's last line
  absorbs its own residual, including negative profit. Currency factors,
  dimensions, posting groups, and nonallocated journal context remain unchanged.
- The header journal's Orig. Pmt. Disc. Possible pair stays zero: the header has
  zero payment discount, and VAT discount adjustments are unsupported. Native
  per-entry gross-amount discount calculation uses the installment percentage,
  date/grace period, and nonzero-LCY eligibility. It does not consume an
  invoice-wide projection of that pair.
- Each linked customer entry and its single Initial Entry detailed record must
  match the calculated amounts, dates, discount, sequence, and auxiliary values.
  Final stored totals are reconciled against all six authoritative journal
  columns before the plan becomes Posted.

### 19.2. Posted ownership and transaction behavior

Sales Invoice Header field 8840 links the posted invoice to its plan. Customer
Ledger Entry fields 8840-8842 store Plan ID, installment sequence, and count.
Each stored plan line contains its exact customer-entry link and final amounts.
The existing posted-header Cust. Ledger Entry No. points to the **final plan
sequence**, selected using that stored link rather than the largest entry number.

The original source SystemId and typed RecordId remain immutable provenance.
New plan fields explicitly identify the posted invoice by number and SystemId,
with posting date and original document/LCY totals. This refines the earlier
proposal to replace the source identity: draft provenance and posted ownership
are recorded separately. Native source-header finalization/deletion preserves
the Posted plan. Copying a posted invoice clones its stored rules into a new
owned Draft plan, without copying posted amounts or ledger links. Posted plan
modification, deletion, and renaming, and changes,
inserts, or moves of its lines, are rejected even with table triggers disabled.

No production COMMIT is added. Splitting, ledger insertion, schedule materialization,
and completion participate in the native posting transaction and preview /
suppress-commit handling. Existing native posting-number commits are not changed
or represented as rollback of every possible source-document update.

### 19.3. Guarded scope and localization

- Global terms cannot silently produce a single receivable through general
  journals, purchase documents, service documents, orders, or credit memos.
  Existing ordinary standalone invoices do not automatically acquire a schedule
  when reusable rules are added; their explicit native invoice handoff retains
  the original single-entry behavior.
- Application during invoice posting, invoice-time automatic oldest-entry application,
  payment-method balancing/direct debit, prepayments, corrections, shipment /
  return-receipt invoices, projects, subscription billing, partial invoicing,
  sales-tax/reverse-charge/unrealized-VAT paths, additional reporting currency,
  and VAT payment-discount adjustments are rejected for global plans.
- Subscription Billing subscribes to the producer guard and rejects recurring
  and automatic contract-billing sources without a Base App dependency on the
  subscription extension.
- Applying a posted installment invoice by document number is rejected,
  including when the customer is on the journal's balancing side. Explicit
  Applies-to ID selection remains the supported manual application path.
  Automatic correction/cancellation and reversal are blocked; correction is
  also checked before native cost unapplication.
- Shared changes are propagated to country copies while retaining local posting
  behavior. Belgium's system-created discount shortcut and Spain's local
  discount calculation remain unchanged for ordinary posting; global entries
  use the W1 per-entry discount contract. Spain requires Full Amount discount
  policy; APAC withholding-tax documents are excluded.
- Italy retains its original legacy installment loop unchanged. An early
  application-level subscriber and defensive customer-posting check explicitly
  reject **global** plans in Italy until legacy reconciliation is implemented.
  Global and legacy loops are never nested.

### 19.4. Validation status

New test codeunit 134493 **ERM Installment Posting** contains focused source
cases for LCY/FCY posting, independent residuals and negative profit, installment
discounts, zero-LCY discount exclusion, rollback after the second installment,
native posting preview, ordinary follow-up isolation after setup changes,
unsupported journal use, ambiguous document-number application, explicit
single-installment payment, posted schedule immutability, and copying posted
rules into an independently owned draft.

These are W1 posting cases. Italy's deliberate global-posting rejection is not
a supported success scenario for the end-to-end W1 posting cases. Localized
runtime coverage and the broader M1-06 integration matrix remain outstanding.
The existing draft test now verifies rejection of invoice-time application
instead of the removed temporary posting block.

Source checks across 164 changed AL files found no conflict markers, duplicate
namespace imports, duplicate installment field IDs, new delimiter imbalances,
or unused extracted posting locals. Existing French conditional-compilation
branches account for the raw parenthesis-count difference from zero and are
unchanged from the baseline. The staged whitespace check passed.

Country propagation has been applied and conflicts reconciled. The explicit
staged-path `Invoke-MiSnapApp -Files $layerPaths` check passed for 163 layer AL
files with `SUCCESS: No missing files`.

The user confirmed Step 4 compilation completed. No compilation or publishing
was performed by the assistant, and runtime test results have not been reported.
Compilation, source checks, and propagation validation are not evidence of
runtime accounting correctness.

## 20. Step 5 implementation: posted experience and guards

### 20.1. Aggregate and upgrade contract

The user approved the shared invoice-group key and historical metadata backfill.
Customer and Detailed Customer Ledger Entry field 8843 **Invoice Entry No.**
provides a persisted grouping identity, not a balance cache. Ordinary customer
entries identify themselves; all entries in a global plan identify its exact
final-sequence customer entry. No contiguous-entry-number assumption is made.

The existing posted-invoice **Closed** and **Remaining Amount** FlowFields keep
their field IDs and query this group. Existing Open/Paid views, saved filters,
reports, and ordinary single-entry behavior therefore use the same fields.
The global `GetRemainingAmount` path uses that aggregate; the ordinary path,
including Italy's existing helper behavior, remains unchanged.

New upgrade codeunit 8844 **Installment Ledger Upgrade** uses a registered
per-company upgrade tag. It populates detailed grouping metadata before customer
grouping metadata so customer-entry notifications read initialized balances,
then regroups existing Posted plans through their verified invoice ownership.
The backfill is idempotent and changes no financial amounts, original entry
links, dates, currency factors, or application records.

**Deployment requirement:** compiling or schema synchronization alone is not
sufficient. Run the Base App data upgrade before validating historical invoice
balances and filters. The metadata backfill can touch large customer/detailed
ledgers; upgrade duration and locking must be assessed in the M1-06 environment.

### 20.2. Posted navigation and API refresh

New page 8842 **Posted Installment Schedule**, opened from posted invoice card
and list actions, displays the stored immutable allocation and discount rules
alongside current linked-entry remaining amounts in document currency and LCY.
Its invoice filter cannot be removed by ordinary user filters. Each line opens
its exact customer ledger entry.

New codeunit 8843 **Sales Installment History** owns grouping, navigation, and
posted safety checks. Posting finalizes grouping inside the existing transaction.
Every later detailed entry inherits its parent's group, including applications
and exchange adjustments; individual ledger balances remain native.

The existing Sales Invoice Aggregator resolves updates from any global plan
entry to the posted invoice, rather than only reacting to the legacy anchor.
The native draft-derived API identity is preserved. Closure is based on all open
entries in the invoice group, so settling the anchor alone cannot mark it Paid.
No new API schedule schema is introduced.

### 20.3. Guarded operations and verification scope

- Shared table and edit-codeunit boundaries reject changes to posted installment
  identity, due/discount dates, and unsupported payment conditions.
- Ordinary entry edits used for manual application remain supported and do not
  copy an installment's date or payment information back to the invoice summary.
  Harmless posted-header edits do not rewrite the final installment from header
  summary values.
- Implicit application without an explicit selected-entry Applies-to ID rejects
  global-plan candidates. Manual selection remains supported.
- Payment-service eligibility excludes global plans; configuration and actual
  payment reporting/provider invocation reject them through shared boundaries.
  Posting also requires an empty Payment Service Set ID.
- Specialized late journal posting rejects a global invoice before changing the
  journal. Existing correction/reversal guards remain in force.

Focused source cases extend **ERM Installment Posting** for aggregate balances,
existing Closed filters, non-anchor API refresh, partial payments, read-only
posted schedules, immutable original rules, safe/unsafe edits, implicit oldest
application, payment services, late journals, and repeatable metadata backfill.
Ordinary-invoice isolation also verifies grouping and historical backfill.

The posting test codeunit now contains 20 source cases, including eight added
for this step. They have not been executed.

### 20.4. Source review and country propagation

Bounded Miapp propagation completed. Thirty-five merge hunks in 25 country
files were reconciled without replacing localized fields, keys, or actions.
Italy retains its native legacy remaining-amount helper and the existing guard
against unreconciled global posting. North America's native statistics actions
and Italy's detailed-ledger keys remain intact.

Source checks across 198 staged AL paths found no conflict markers, duplicate
imports, duplicate table field IDs, duplicate key names, or new delimiter
imbalance. The French posting codeunit retains its unchanged conditional-
compilation parenthesis difference already documented in Step 4. Group fields,
FlowField expressions, schedule actions, and upgrade-tag registration were
checked in the affected country copies. New object IDs are unique in source.
`git diff --cached --check` passed.

`Invoke-MiSnapApp -Files $paths`, using the explicit 198 staged layer AL paths,
passed: **SUCCESS: No missing files**. This verifies propagation coverage, not
AL compilation or accounting behavior.
The user confirmed Step 5 compilation completed on 2026-11-16. Country scope
and runtime test results were not specified. Data-upgrade execution, runtime
test execution, and upgrade performance validation remain pending with the user.

## 21. Step 6: integration review and acceptance readiness

**Status:** Source integration review and focused hardening complete. The user
reported M1 verification in progress on 2026-11-16; compilation, upgrade, and
runtime results have not yet been recorded. M1 acceptance and sign-off remain
pending designated-environment evidence.

### 21.1. Integration findings and hardening

Reviewed native W1 customer posting, discount and tolerance calculation,
snapshot lifecycle, invoice grouping/backfill, correction entry points, and
Italy's preserved legacy split. No change to financial allocation, schema,
object IDs, supported scope, or feature activation was required.

Two native corrective-copy routes did not pass through the existing
`OnBeforeCreateCorrectiveSalesCrMemo` guard:

- `CreateCreditMemoCopyDocument` can proceed directly to document copying.
- The notification action `CreateCorrectiveCreditMemo` calls
  `CreateCopyDocument` directly, including for partially settled invoices.

Added an early `OnBeforeCreateCreditMemoCopyDocument` subscriber and a shared
`OnBeforeSalesHeaderInsert` subscriber in `Installment Posting`. Both reuse the
existing explicit unsupported-correction error. The first rejects the copy
request before native checks/notifications; the second protects document
creation, including the notification route, before inserting a new sales header.
Ordinary invoices with no global Plan ID retain native behavior.

Focused source coverage was strengthened in `ERM Installment Posting`:

- New corrective-copy/notification rejection test, including a partial payment.
- New tolerance test with 10/20/remainder allocation: at 2% with a 0.50 cap,
  installment tolerances are 0.25/0.50/0.50, not three invoice-sized amounts.
  It also checks per-entry grace dates and the customer tolerance block.
- The injected-failure case now retries the same persisted invoice and checks
  that exactly one complete posted result exists.
- The VAT/invoice-discount case now compares a fresh preview to posted amounts,
  LCY amounts, dates, and discount eligibility. It uses nonzero dimensions and
  an external document number; shared verification checks those fields,
  customer, currency, document number, and plan ownership on every receivable.

### 21.2. M1 acceptance coverage map

Source suites: **C** = 134491 `ERM Installment Calculation` (18 tests),
**D** = 134492 `ERM Installment Draft` (13 tests), and
**P** = 134493 `ERM Installment Posting` (22 tests).
Total: **53 test methods; runtime results not yet recorded**. Every row below
still requires runtime evidence; test presence and source review are not acceptance results.
The additional checks column identifies coverage beyond the named source cases.

| Acceptance ID | Source evidence | Additional designated-environment checks |
| --- | --- | --- |
| M1-AT-01 | C `OrdinaryTermsProduceNoSyntheticPlan`; P `OrdinaryInvoiceRemainsSingleWhenReusableRulesAreAdded`. | Ordinary invoice dates, discounts, and native navigation baseline. |
| M1-AT-02 | C `PercentagesUseOriginalTotalsAndDocumentDate`, `RemainingAmountReceivesUnallocatedPercentage`. | Run C. |
| M1-AT-03 | C `FinalLineReceivesIndependentCurrencyResiduals`. | Run C. |
| M1-AT-04 | C `UsesWholeUnitAndThreeDecimalPrecisions`. | Run C; verify configured currencies in the UI. |
| M1-AT-05 | P `ForeignCurrencyPostingKeepsIndependentLCYResidualAndCurrencyFactors`. | Trace customer/control-account totals in both currencies. |
| M1-AT-06 | C invalid percentage, remainder, date, precision, and rounded-amount cases. | Attempt invalid-rule posting and confirm no financial records persist. |
| M1-AT-07 | D `PreviewUsesCurrentVATAndInvoiceDiscountTotalsWithoutCaching`; P `PostingSplitsOnlyReceivablesAndPreservesDiscountedInvoiceTotals` now compares preview/posting line by line. | Complete the document-date, currency, quantity, price, VAT, and discount change matrix. |
| M1-AT-08 | D `DateRevalidationDoesNotReloadChangedSetup`, `ChangingTermsReplacesOnlyTheOwnedPlan`; P posted immutability and posted schedule tests. | Verify explicit terms replacement and posted history through the UI. |
| M1-AT-09 | D copy, deletion, unsaved-header, customer-change, and terms-change cases. | Exercise document actions with real user permissions. |
| M1-AT-10 | P `PostingSplitsOnlyReceivablesAndPreservesDiscountedInvoiceTotals`. | Inspect the posted invoice, VAT, revenue, and control-account reconciliation. |
| M1-AT-11 | C `DiscountsUseEachLineAndPostingDateGracePeriod`; P shared posted-schedule assertions. | Native settlement/discount behavior for the supported gross-base policy. |
| M1-AT-12 | P shared posted-schedule assertions, now with nonzero dimension/external-reference fixture. | Ledger and detailed-entry inspection/navigation. |
| M1-AT-13 | P failure/rollback/retry and posting-preview cases. | Run P and inspect the persisted retry result. |
| M1-AT-14 | P selected-entry payment and aggregate invoice balance cases. | Manual application pages: full first installment and partial later installment. |
| M1-AT-15 | P `PostedScheduleShowsOriginalRulesAndCurrentEntryBalances`. | Schedule action and exact entry drilldown after setup/payment changes. |
| M1-AT-16 | P journal rejection and new `CorrectiveCopyAndNotificationRejectInstallmentInvoices`; reviewed posting guards. | Full unsupported producer, correction, cancellation, reversal, and payment-combination matrix, plus ordinary controls. |
| M1-AT-17 | P `OrdinaryInvoiceRemainsSingleWhenReusableRulesAreAdded` reuses posting after a successful installment invoice. | Ordinary posting immediately after a failed installment attempt. |
| M1-AT-18 | IT native legacy loop and early global-plan rejection reviewed; prior shared propagation recorded in sections 19-20. | Run legacy IT reference cases and confirm no double split. No IT runtime result is recorded. |
| M1-AT-19 | P `InvoiceBalancesFiltersAndAPIStatusFollowEveryInstallment`. | Verify actual API responses after non-anchor, anchor, and final settlement. |
| M1-AT-20 | P aggregate balance assertions exercise native Closed filters; ordinary follow-up checks its open filter. | Actual Open/Paid views, including a fully settled ordinary invoice. |
| M1-AT-21 | P implicit-oldest, document-number, selected-entry payment, and posted-entry/header-edit cases. | Exercise native application/edit pages and verify header summary stability. |
| M1-AT-22 | P new tolerance case, auxiliary negative-profit/residual case, zero-LCY calculation case, and posted discount assertions. | Native zero-LCY posting and supported discount/tolerance settlement edge cases. |

This map does not certify the broader V1 application, unapplication, revaluation,
discount-tax, correction, collection, or output/API scope.

### 21.3. Source verification and propagation

Only the W1 `InstallmentPosting.Codeunit.al` and its W1 posting test codeunit
changed in Step 6, alongside this document. The shared posting helper has no
country override; no existing native/country file needed a new merge.
The new event parameter names/types match the W1, APAC, and ES publishers.

Explicit changed-file validation passed:

```powershell
Import-Module .\build\scripts\Miapp\MicroSnapApp.psm1 -Force
$paths = @(git diff --name-only | Where-Object { $_ -like '*.al' })
Invoke-MiSnapApp -Files $paths
```

Result: **SUCCESS: No missing files** for both changed AL paths.
Comment/string-aware delimiter checks, duplicate import/method checks, and
conflict-marker checks passed for those files. `git diff --check` passed.
These are source/propagation checks, not AL compilation or runtime execution.

### 21.4. Outstanding environment gates

The user must complete and record the following before M1 sign-off:

1. Compile the Step 6 changes in the relevant W1/country projects.
2. Execute the Base Application data upgrade in the validation environment.
   Verify the per-company installment invoice-group upgrade tag, historical
   ordinary/installment balances and filters, and metadata-only changes.
   Record upgrade duration/locking on representative ledger volumes.
3. Execute all three test codeunits above and record results for all 53 tests.
   The existing backfill test exercises helper idempotency; it does not prove
   deployment-time execution or tag handling.
4. Complete the additional acceptance checks in section 21.2, including native
   UI/API flows, ordinary W1 controls, and legacy IT reference cases.

No build, publish, data upgrade, or container-backed test was run by the
assistant. No commit was created. Step 6 environment acceptance remains open;
the milestone is not signed off and unrestricted production activation remains
outside M1.

## 22. M2 implementation plan: complete receivables business logic

### 22.1. Objective, scope, and dependency on M1

**Revised direction confirmed by the user:** Prioritize the broader receivables
Slice 2 business logic. Move printed invoices and layouts to the end of
development, rather than making them the next milestone.

Complete installment settlement, corrections, collections, reconciliation,
aging, and cash-flow behavior on top of the existing W1 posting model. Reuse
native ledger/application accounting; do not introduce another calculator or
financial source of truth. This supersedes the earlier output/API-only M2 plan.

M1 verification continues independently. M2 planning and contract investigation
can proceed now; M2 acceptance requires an accepted M1 baseline and resolution
of any M1 defects affecting receivables correctness. Neither milestone by itself
authorizes unrestricted production activation.

| Included | Explicitly excluded |
| --- | --- |
| Per-installment application/unapplication, discounts, tolerances, and currency effects. | New payment services, payment initiation, and unrelated application-policy changes. |
| Sales credit memos, correction/cancellation, and their allocation and navigation rules. | Payables, additional invoice producers, renegotiation, and advanced terms. |
| Statements, overdue-only reminders/finance charges, and payment reconciliation business logic. | Printed invoice schedules, report presentation/layouts, PDF/email delivery work, and custom-layout adaptation until the final delivery phase. |
| Per-installment aging and Cash Flow Forecast calculations and source data. | Recalculation from current Payment Terms or manual rewriting of posted obligations. |
| Existing invoice aggregate status/API compatibility, country regression, and guard review. | New schedule API implementation as an M2 prerequisite, API writes, and IT migration/global activation. |

New read-only schedule API work follows the business logic; its contract remains
to be finalized separately. Printed invoice schedules and all layout/presentation
work are the final development phase. Statement grouping, reminder selection,
aging buckets, and forecast calculations belong in M2 even when their visual
presentation is deferred.

Remove an M1 unsupported-path guard only for a specifically implemented and
verified replacement path. Other guards remain in force. Legacy IT invoices
must not acquire synthetic global schedules or be routed through global posting.

### 22.2. Source anchors and design constraints

Business-logic contracts to freeze before their dependent implementation:

- Apply to exact linked entries; preserve plan/line identities, immutable posted
  dates/amounts, and invoice-wide aggregate status through settlement/unapply.
- Define partial-payment discount eligibility, tolerances, credit-memo discount
  reduction, and supported VAT/discount combinations using native accounting.
- Select the unpaid-invoice correction approach and the permitted allocation
  policies for partly paid invoices from section 6. These are open decisions,
  not approval to implement every alternative. Do not reopen settled amounts
  without explicit unapplication.
- Define deterministic matching for multi-entry invoice numbers and external
  references. Ambiguous reconciliation must not silently choose an installment.
- Evaluate overdue amounts, reminder levels, aging, and forecasts per entry's
  own due date and balance; do not accelerate future installments.
- Inventory single-entry assumptions and shared entry points before lifting
  guards. Ordinary invoices and existing invoice API identity/status remain
  compatible; country changes preserve local behavior.

The following previously inspected output/API anchors are retained for the
deferred delivery work, not as prerequisites for starting M2 business logic:

| Source | Planning consequence |
| --- | --- |
| W1 `Sales\History\StandardSalesInvoice.Report.al`, report 1306. | Already exposes header due date/payment terms, aggregate remaining-amount text, payment reporting arguments, and six rendering layouts. Add schedule output once per invoice, not once per commercial line. |
| Report 1306 rendering section. | Current W1 layouts are RDLC plus standard Word, Blue Word, themable Word, VAT-specification Word, and default-email Word. Dataset changes alone do not update these layouts. |
| FR, ES, NA, and NO report 1306 overrides. | Shared report changes need Miapp propagation and preservation of local output behavior; layout propagation must also be inventoried. |
| W1 `Sales\History\PostedInstallmentSchedule.Page.al`; `SalesInstallmentHistory.Codeunit.al`. | Reuse posted ownership/link validation and the existing distinction between original schedule values and live customer-entry balances. Do not make a UI page the output/API service. |
| `Installment Plan` and `Installment Plan Line`. | Original allocation/date/discount values are persisted already. Use the line SystemId as the proposed stable API row identity, not a fresh request-time GUID or ledger entry arithmetic. |
| `Integration\Entity\SalesInvoiceAggregator.Codeunit.al`, `GetSalesInvoiceHeaderId`. | Public invoice ID can be Draft Invoice SystemId, falling back to posted SystemId. It is not always the posted header SystemId or the plan source ID. |
| `src\Apps\W1\APIV2\app\src\pages\APIV2SalesInvoices.Page.al`. | The standard API is aggregate-backed and not extensible. An additive child navigation would require a deliberate change in the API app, with API contract/version review. |
| `APIV2SalesInvoiceLines.Page.al`; `APIV2PDFDocument.Page.al`. | Existing API pages demonstrate temporary read models and parent-linked resources. PDF retrieval delegates to native PDF Document Management; trace its report/layout selection before promising output coverage. |
| `src\Apps\W1\APIV2\test\src\APIV2SalesInvoicesE2E.Codeunit.al`. | Extend existing invoice E2E conventions for API identity, requests, permissions, and delivery regression coverage. |

Base App remains the owner of installment business/read logic. The API app can
consume that logic; Base App must not depend on the API app.

### 22.3. Deferred output and API contracts

These preserve the earlier delivery requirements. They are recommended defaults
to finalize in the later delivery contract review, not M2 business-logic
prerequisites or additional approved product decisions. API work follows the
business logic; printed invoices and layouts remain the final phase.

**Invoice output**

- Support Detailed and Summary modes. Recommend Detailed by default for global
  installment invoices, with an explicit summary alternative. Freeze setting
  ownership, unattended defaults, and any request-page override in that review.
  Ordinary invoices retain their native presentation.
- Detailed output shows installment number/count, original due date, original
  document-currency amount, and applicable discount percentage/date/eligibility.
  Show currency unambiguously and respect its amount precision.
- Summary text must truthfully describe the posted schedule. Do not substitute
  a reusable Payment Terms description that can change after posting.
- Read original amounts and dates from the posted snapshot. Reprints after
  setup edits, settlement, or exchange-rate adjustment must not rewrite those
  original obligations.
- If live paid/remaining information is displayed, label it separately and use
  aggregate invoice balances. Do not present the first installment's due date
  as the due date for the entire outstanding invoice, or header discount zero
  as a claim that no installment has a discount.
- Do not multiply revenue, VAT, totals, document copies, or payment instructions.
  Preserve native print counters and delivery behavior; schedule reads must not
  modify plans or financial records.
- Target all six W1 report 1306 layouts. Freeze expected email-body versus
  attachment presentation and country coverage before implementation. Custom
  layouts and other report IDs are not automatically upgraded or certified;
  document their required adaptation and make supported output choices clear.

**Read-only API**

- Recommend an additive child collection beneath the existing sales invoice
  resource, provisionally `salesInvoices({invoiceId})/installments`. Final entity
  names, version placement, navigation, and direct-root access need API review.
- Return only posted global schedules belonging to the authorized company and
  parent invoice. A valid ordinary or draft invoice has no posted installment
  rows; invalid/inaccessible parents follow normal API error behavior.
- Proposed fields: stable line ID, public sales-invoice ID, plan ID, installment
  number/count, due date, currency, original amount/LCY amount, remaining
  amount/LCY amount, open flag, original discount terms/eligibility, and a stable
  customer-ledger-entry identifier. Final public names/types belong to the later
  API contract review.
- Obtain current balances/open state from each exact linked customer entry.
  Remaining LCY may change through native exchange adjustments; do not treat it
  as a recalculated original amount or infer cash paid by simple subtraction.
- Support normal parent scoping, ordering by sequence, pagination, and explicitly
  agreed filters/expansion. Do not assume calculated page variables provide
  server-side filtering or that temporary rows preserve API filters automatically.
- Reject create/update/delete operations; do not expose posting, correction,
  rescheduling, or payment actions on this resource.
- Do not add a persistent balance cache. Choose the simplest read model that
  satisfies identity, filtering, permissions, and paging requirements.
- Verify ETag/conditional-read behavior when linked ledger balances change.
  Immutable plan timestamps are not financial last-change timestamps; do not
  promise delta/change-tracking semantics without a correct supporting contract.
- Missing/mismatched posted ownership or ledger links are explicit errors, not
  empty/zero-valued synthetic schedules. Apply native permissions and company
  isolation without granting broad new financial-table access.

### 22.4. Implementation packages and deliverables

| Package | Prerequisites | Work and deliverable | Completion evidence |
| --- | --- | --- | --- |
| M2-01: Receivables contracts and consumer inventory | Revised M2 scope; M1 results tracked. | Trace settlement/unapply, discount/tax, credit/correction, collections, reconciliation, aging, and forecast paths. Classify single-entry assumptions and guards. Record policy decisions, supported combinations, and focused accounting fixtures. | Reviewed behavior/guard map; unresolved policy choices block only their dependent implementation. No report/layout inventory required to start. |
| M2-02: Application, unapplication, and discounts | Relevant M2-01 settlement decisions. | Preserve explicit-entry and multi-installment settlement, deterministic oldest-first behavior, partial/overpayments, discounts/tolerances, realized currency effects, and unapply/reapply identity. Keep aggregate invoice status correct. Reuse native posting and shared ownership validation. | Focused accounting cases reconcile detailed/customer/control entries; supported discount/tax combinations and remaining guards are explicit. |
| M2-03: Sales credits, corrections, and cancellation | M2-02 and M2-01 correction/allocation decisions. | Implement the selected unpaid and partly paid correction paths, credit allocation and discount effects, complete document navigation, and transactional rollback. Replace only covered correction guards at shared business entry points. | Unpaid/partly paid/full-settlement scenarios follow the selected policy without reopening settled amounts or duplicating revenue/VAT. |
| M2-04: Collections and payment reconciliation | M2-02 and relevant M2-01 matching/collection decisions. | Make statements logically group the invoice, reminders/finance charges select only eligible overdue installments, and reconciliation identify exact entries or reject ambiguity. Keep printed presentation deferred. | Due/future mixtures, reminder levels, partial settlement, multi-installment receipts, duplicate references, and ordinary controls behave correctly. |
| M2-05: Aging and Cash Flow Forecast | M2-02 and M2-01 calculation contracts. | Audit/adapt entry selection, bucket calculations, forecast dates/amounts, and settled/credited balances. Reuse native entry-based behavior where already correct; do not redesign layouts. | Per-installment due dates and remaining balances reconcile to invoice and customer totals across as-of dates and currencies. |
| M2-06: Integration, country, and regression review | M2-03, M2-04, and M2-05. | Review cross-feature interactions, existing invoice API identity/status, permissions, propagation, ordinary invoices, and legacy IT isolation. Inventory remaining guards and deferred delivery/release gates. | Focused regression/accounting evidence, country propagation review, and realistic-volume checks; no new financial cache or schedule store. |
| M2-07: Designated-environment acceptance and sign-off | M2-06 and accepted M1 baseline. | Run the business-logic acceptance matrix below and capture supported policies, accounting results, country scope, and remaining limitations. | M2 business logic accepted; deferred API/output work and production-release gates remain explicit. |

M2-03, M2-04, and M2-05 can proceed independently after their prerequisites;
integration covers their combined behavior. The user performs compilation,
publishing, and container-backed runtime validation.

After business-logic acceptance, deliver the read-only schedule API under its
reviewed contract. Finish development with the invoice datasets, all six
certified W1 report 1306 layouts, country adaptations, summary/detail settings,
and print/preview/PDF/email/API-PDF delivery acceptance. Reuse validated posted
reads and native public invoice identity; do not add another schedule store.

### 22.5. Focused M2 acceptance matrix

| ID | Scenario | Required assertion |
| --- | --- | --- |
| M2-AT-01 | Partial, full, later-installment, and multi-installment receipt application. | Only selected/eligible entries close; remaining balances and aggregate invoice status are correct, including when the anchor settles first. |
| M2-AT-02 | Oldest-first application and overpayment. | Due-date/sequence ordering is deterministic; excess follows native unapplied/next-entry rules without ambiguous invoice-number selection. |
| M2-AT-03 | Eligible/late discounts, partial payments, and payment tolerance. | Per-entry amounts follow the approved policy and native supported discount/tax accounting; later installments do not lose eligibility incorrectly. |
| M2-AT-04 | Unapply and reapply after partial/full settlement. | Plan, line, and ledger identities persist; balances, discounts, tolerances, and currency effects reverse/repost correctly. |
| M2-AT-05 | FCY settlement/revaluation and whole-unit/three-decimal precision. | Native realized/unrealized effects and rounding reconcile; original posted document/LCY allocations remain immutable. |
| M2-AT-06 | Correct/cancel an unpaid multi-entry invoice. | Selected whole-invoice correction policy covers every installment, preserves navigation, and posts revenue/VAT only as required by the correction. |
| M2-AT-07 | Credit a partly paid invoice or attempt automatic cancellation. | Approved allocation affects only permitted amounts; native paid-invoice restrictions remain; settled amounts are not reopened without unapply. |
| M2-AT-08 | Credit application and its unapplication with payment discounts. | Credit allocation and discount reductions reconcile; reversal restores the correct balances and eligibility. |
| M2-AT-09 | Failure during multi-entry correction/application. | Transaction rolls back without partial correction, orphaned ownership, or inconsistent aggregate status. |
| M2-AT-10 | Statements and reminders/finance charges with due and future installments. | Logical invoice grouping is correct; only eligible overdue balances are collected and reminder levels remain entry-specific. |
| M2-AT-11 | Payment reconciliation with shared invoice/external references. | Exact entries can be identified; ambiguous matches require explicit resolution, not silent selection or duplicated application. |
| M2-AT-12 | Aging across due-date boundaries and as-of dates. | Each installment contributes its appropriate remaining amount to its own bucket; totals reconcile, including subsequent applications/credits. |
| M2-AT-13 | Cash Flow Forecast before/after partial payments and credits. | Dates and outstanding amounts reflect individual installments without duplicate invoice totals or forecasting settled obligations. |
| M2-AT-14 | Existing invoice API after anchor/non-anchor settlement, correction, and unapply. | Public invoice identity remains stable; current totals/status reflect the whole invoice, with native corrected-document behavior. |
| M2-AT-15 | Ordinary invoices, legacy IT, permissions, and unsupported paths. | Native behavior and authorization remain; guards are lifted only for verified paths; no IT global activation or second split. |
| M2-AT-16 | Combined lifecycle and representative volume. | M1 invariants, customer/detailed/control balances, ownership, country behavior, and acceptable execution/query behavior are preserved. |

Use focused existing Base App accounting/integration test libraries. Presentation
and rendered-layout acceptance belong to the final delivery phase, not this
business-logic matrix. Deferred API acceptance must still cover stable identity,
parent/company scoping, live balances, queries/paging, denied writes, broken
ownership, and conditional reads before that resource is delivered.

### 22.6. Exit criteria and first executable step

M2 is complete only when the approved receivables policies are implemented,
the business-logic acceptance cases pass, country propagation is reviewed, and
the M1 prerequisite is accepted. Printed schedules, layouts, and the new schedule
API are deferred delivery requirements, not removed requirements or evidence of
full product readiness. Record exact validation commands, results, country scope,
remaining guards, and release limitations during implementation.

This revision changes the plan only; it does not implement or validate M2 logic.

**First executable step: M2-01.** Inventory the application/unapplication and
discount paths first, map existing guards and single-entry assumptions, and
present the settlement/correction policy decisions before dependent code changes.

### 22.7. M2-01 initial source inventory

The following records the baseline at the initial investigation, not runtime
certification. Paths in the table are relative to `src\Layers\W1\BaseApp` unless
explicitly prefixed with `Tests`. Section 22.10 supersedes the blanket later
receipt rejection described here; other guard dispositions remain in force.

| Area and source | Verified current behavior | M2 disposition |
| --- | --- | --- |
| `Sales\Posting\InstallmentPosting.Codeunit.al:33-95`, `CheckSalesPosting`. | Invoice creation requires Manual customer application, no initial application/balancing payment, no additional reporting currency, and the supported realized gross-discount VAT setup. | Keep these producer/tax boundaries in the first settlement increment. Later receipt application is a separate contract from application during invoice posting. |
| `Sales\Posting\InstallmentPosting.Codeunit.al:109-130`, `CheckJournalLine`. | A customer-side Applies-to Doc. No. matching a global installment entry raises an explicit error. | Retain document-number ambiguity protection; do not replace it with a first-match lookup. |
| `Finance\GeneralLedger\Posting\GenJnlPostLine.Codeunit.al:3880-4009`, `ApplyCustLedgEntry`. | Native posting processes the selected temporary entries individually through `PostApply`, updates each original entry, and posts native discount/currency effects. | Reuse this pipeline for selected-entry and multi-installment settlement; no parallel installment application engine. |
| `Finance\GeneralLedger\Posting\GenJnlPostLine.Codeunit.al:4154-4274`, `PrepareTempCustLedgEntry`. | Document-number application uses `FindFirst`; Applies-to ID builds an entry set. Oldest-first uses the customer/applies-to/open/sign/due-date key, which has no explicit installment-sequence field. | Verify explicit-entry selection independently. Before enabling automatic application, specify equal-date and mixed-invoice ordering and preserve native sign/currency handling. |
| `Sales\History\SalesInstallmentHistory.Codeunit.al:214-222`, `CheckAutomaticApplication`. | A candidate with a global plan is rejected when both application identifiers are blank, including later Apply to Oldest receipts. | This guard is an actual M2 enablement gap, not evidence that native oldest-first behavior is certified. Replace only after its ordering contract is implemented. |
| `Finance\ReceivablesPayables\PaymentToleranceManagement.Codeunit.al:2117-2155`, `CheckCalcPmtDisc`; `Finance\GeneralLedger\Posting\GenJnlPostLine.Codeunit.al:2847-2913`, `CalcPmtDisc`. | Native eligibility compares the payment/application amount with the selected entry's remaining liability less its available discount. It does not require the other installment entries to close. | Recommend native discount eligibility per installment, not a new proportional discount for every partial receipt. Approval remains required under section 5.2. |
| `Finance\GeneralLedger\Posting\GenJnlPostLine.Codeunit.al:2947-2979`, `CalcPmtDiscIfAdjVAT`. | Discount adjustment factors use the individual old entry's original LCY amount, while VAT selection is by transaction number. | Keep VAT-adjusting discount combinations guarded pending a dedicated invoice-tax allocation design; removing the setup guard alone is unsafe. |
| `Sales\Receivables\CustEntryApplyPostedEntries.Codeunit.al:357-453`, `PostUnApplyCustomerCommit`; `Finance\GeneralLedger\Posting\GenJnlPostLine.Codeunit.al:6164-6330`, `UnapplyCustLedgEntry`. | Unapplication selects detailed records by application/transaction and customer, reverses application effects, and supports suppressing the commit. It is not necessarily restricted to one installment when one application covers several entries. | Preserve native application-transaction scope; verify multi-installment unapply/reapply, balances, discounts, currency effects, and unchanged original schedule. Do not equate application unapply with the separately guarded document reversal. |
| `Sales\History\SalesInstallmentHistory.Codeunit.al:118-179`, detailed grouping and condition checks; `Integration\Entity\SalesInvoiceAggregator.Codeunit.al:615-645`, `SetStatusOptionFromCustLedgerEntry`. | Later invoice detailed entries inherit invoice grouping; posted payment conditions are protected; API status resolves plan entries to the owning posted invoice. | Reuse these invariants and verify reopening/status after unapply, including non-anchor updates. Do not rewrite posted plan lines during settlement. |
| `Sales\Posting\InstallmentPosting.Codeunit.al:469-509`, correction/reversal subscribers; `Sales\History\CorrectPostedSalesInvoice.Codeunit.al:209-278,553-566`. | Shared guards block correction creation, cancellation, and ledger reversal. Native corrective-copy and applied-entry navigation still use the legacy invoice link in places; the paid test uses the aggregate remaining amount. | Do not remove all correction subscribers together. Implement the selected whole-invoice allocation/navigation contract before opening each entry point. |
| `Sales\Reminder\ReminderMake.Codeunit.al:344-421`, candidate selection; `Sales\FinanceCharge\FinChrgMemoMake.Codeunit.al:190-258`, `MakeLines`/`MakeLines2`. | Selection and charges operate on customer entries and their dates. Reminder settings can also include not-yet-due entries for information. | Verify overdue collection amounts and entry-specific levels without accelerating future installments. Distinguish informational lines from amounts actually demanded or charged; layout changes stay deferred. |
| `Bank\Reconciliation\MatchBankPayments.Codeunit.al:1150-1194,1845-1878`. | Matching candidates retain individual ledger entries; closing-document lookup also searches shared document/type/date references. | Trace the complete matching/application path before enablement. Shared invoice numbers alone are not unique installment identifiers. |
| `Sales\Customer\StandardStatement.Report.al:435-492`; `Sales\Reports\AgedAccountsReceivable.Report.al:438-521`. | Statement amounts use entry-specific as-of date filters; aging rebuilds remaining amounts from detailed entries and buckets by each entry's due date when requested. | Preserve native as-of accounting; verify invoice grouping and no duplicated totals rather than replacing these entry-based calculations. Visual grouping/layouts remain deferred. |
| `CashFlow\Worksheet\SuggestWorksheetLines.Report.al:871-916`, `InsertCFLineForCustLedgerEntry`. | Forecast source amounts, due/discount dates, and tolerances come from each entry, but source/document numbers are shared and optional customer cash-flow terms can override dates. | Verify worksheet insertion/aggregation and configured forecast-date semantics before claiming per-installment forecast compatibility. |

Existing M1 focused source coverage is in
`src\Layers\W1\Tests\ERM\ERMInstallmentPosting.Codeunit.al`:
`ManualPaymentUsingAppliesToIDClosesOnlyTheSelectedInstallment`,
`InvoiceBalancesFiltersAndAPIStatusFollowEveryInstallment`, and
the original `ImplicitOldestApplicationRejectsInstallments` (replaced by the
M2-02 receipt/guard cases below). These M1 cases do not establish
multi-entry unapplication, actual discount realization/reversal, or automatic
oldest-first success. `LibraryERMInstallments.Codeunit.al:118-147` currently
provides a one-entry LCY payment helper; extend only as required by the focused
settlement cases, not into a separate test posting engine.

### 22.8. Proposed first business-logic increment and decision gates

**First increment:** M2-02 selected-entry settlement, actual per-installment
discount realization, and native application/unapplication lifecycle. Cover
one receipt spanning selected installments, a partial receipt followed by
eligible final settlement, and unapply/reapply of the affected application.
Assert original plan/ledger identities and dates, exact entry balances,
invoice-wide status, and native detailed/G/L accounting. Change production
logic only where the verified contract requires it.

Do not enable initial invoice application, implicit oldest-first application,
document-number-only settlement, corrective posting, VAT-adjusting discounts,
or additional reporting currency as a side effect of this increment.

| Decision | Contract / approval status | Dependent work |
| --- | --- | --- |
| M2-D01: Partial-payment discounts | **User approved: native.** Follow existing BC eligibility per installment. A partial receipt does not earn a new proportional discount; eligible settlement of that installment can realize its remaining native discount independently of other installments. No new discount-mode setting. | First increment discount contract. |
| M2-D02: Unpaid correction model | **User approved on 2026-11-17.** Use one native corrective credit, explicitly allocated/applied across all original installment entries; a replacement invoice owns a new independent schedule. Do not create a second installment calculator or mirror-credit schedule. | M2-03 posting, cancellation, and navigation work. |
| M2-D03: Partly paid corrective-credit allocation | **User approved on 2026-11-17.** Start with explicit manual allocation to selected open installments, preserving paid amounts and native automatic-cancellation restrictions. Add automatic earliest/latest/proportional policies only by a separate agreed requirement. | M2-03 credit allocation and user interaction. |
| M2-D04: Payment reconciliation matching | **User approved on 2026-11-17.** Require manual entry selection while an invoice has multiple open installments, including uniquely sized installments and exact full-invoice receipts. Preserve native matching for the last open installment and ordinary invoices. | M2-04 automatic matching guard and exact-entry settlement cases. |
| M2-D05: Cash Flow Forecast date overrides | **User approved on 2026-11-17.** Preserve native behavior: use installment dates by default; when Consider CF Payment Terms is explicitly enabled, retain the customer's separate forecast terms calculated from the original invoice date. Forecast options must not rewrite posted installment obligations. | M2-05 forecast-date and immutable-ledger cases. |

M2-D01, M2-D02, M2-D03, M2-D04, and M2-D05 are approved. Further automatic matching
policies and collection/forecast details remain package-specific contract gates;
approval of these policies is not full M2 sign-off.

### 22.9. First settlement increment: source cases and validation status

The existing native application engine is retained. Two focused cases were added
to `src\Layers\W1\Tests\ERM\ERMInstallmentPosting.Codeunit.al`:

- `PartialPaymentDiscountSettlementAndUnapplyPreserveSchedule`: an initial
  partial receipt earns no proportional discount; an eligible final receipt
  realizes the installment's discount while later installments remain open.
  Unapplying that final application restores the discount and remaining balance,
  preserves the earlier receipt, and reverses the discount expense.
- `MultiInstallmentReceiptUnapplyAndReapplyPreservesSchedule`: one receipt closes
  all three explicitly selected installments; native transaction unapplication
  reopens the original entries; the same receipt is reapplied to those entries.
  Invoice-wide balance/closure and original plan links, sequence, and due dates
  are checked.

Fixtures use a test-owned customer posting group with discount accounts and
block payment tolerance so the assertions isolate discounts/application rather
than depend on ambient tolerance setup. Payment-journal creation is shared with
the existing selected-entry payment test; native posted-entry services handle
unapplication and reapplication.

The user confirmed runtime validation of this settlement increment on
2026-11-17. Exact commands, environment/version, and country coverage were not
supplied. Compilation, publishing, and container-backed execution remain with
the user. No production guards had been removed at that checkpoint; this confirmation does not
certify the full M2-02 currency/tolerance matrix, automatic oldest-first behavior,
or M2 correction policies. Printed invoices, layouts, and new API delivery
remain deferred.

### 22.10. M2-02: oldest-first receipts and settlement edge cases

**Implementation status:** Compiled, published, and runtime-validated on the
local `Navision_master` development server on 2026-11-17. All 71 installment
tests passed, including the expanded M2-02 cases and earlier settlement cases.
This is local W1-source validation, not certification of every country or the
broader M2 acceptance matrix.

**Receipt boundary and ordering**

- `Sales Installment History.CheckAutomaticApplication` now permits implicit
  application only for negative customer Payment journal lines without a new
  installment posting context. Native customer Application Method and Allow
  Application checks still decide whether automatic application runs.
- Native candidate selection, currency compatibility, positive/negative-entry
  handling, discount calculation, and financial posting are retained. The change
  does not implement another application engine.
- For an implicit receipt whose eligible temporary candidates include global
  installments, order by due date, then the stable Invoice Entry No. group,
  then installment sequence; the primary entry number remains the final key
  tiebreaker. Thus invoice groups deterministically resolve equal dates across
  invoices, and sequence resolves equal dates within a plan. Different due dates
  always take priority over grouping or sequence.
- Explicit Applies-to ID selection and ordinary-only candidate sets keep native
  ordering. A global automatic candidate must have its existing invoice-group
  metadata; a missing group raises a field error rather than silently guessing.
- The new customer-ledger ordering key has `MaintainSQLIndex = false` and is
  selected on the temporary candidate table only. It adds no persistent SQL
  index, balance cache, new financial fields, or data-backfill requirement.
- Invoice-time automatic application, document-number-only global application,
  implicit non-payment application, correction/reversal, payment-service/late
  posting, additional reporting currency, and unsupported VAT/discount paths
  remain guarded. The existing M1 invoice-group upgrade requirement is unchanged.

**Focused source coverage**

All cases are in
`src\Layers\W1\Tests\ERM\ERMInstallmentPosting.Codeunit.al`, using the native
posting/application services and the existing installment libraries.

| Case | Contract exercised |
| --- | --- |
| `OldestReceiptUsesInstallmentSequenceAndMixedInvoiceDueDates` | Equal-date installment sequence; an intervening ordinary invoice is paid before a later-due installment. |
| `OldestReceiptLeavesExcessUnappliedAfterAllInstallmentsClose` | One receipt closes the complete invoice and retains excess cash as an unapplied native payment balance. |
| `OldestReceiptDoesNotGrantExpiredInstallmentDiscount` | A late receipt cannot realize an expired discount or prematurely close the installment. |
| `ForeignCurrencyOldestReceiptGainCanBeUnappliedAndReapplied` | A 41.67 realized gain reconciles at entry/G/L level, reverses on unapply, and reposts on reapply of the same receipt. |
| `ForeignCurrencyOldestReceiptLossCanBeUnappliedAndReapplied` | A rounded 20.83 realized loss follows the same lifecycle; original document/LCY allocations and schedule/ledger identities remain unchanged. |
| `InstallmentUnderpaymentWithinToleranceClosesOnlySelectedEntry` | Native accepted tolerance closes the selected installment without closing later installments. |
| `CustomerToleranceBlockPreservesInstallmentUnderpayment` | A customer block prevents tolerance from absorbing the shortfall. |
| `InstallmentUnderpaymentAboveToleranceRemainsOutstanding` | A shortfall beyond the entry cap and native rounding allowance remains outstanding. |
| `OldestCustomerCannotApplyDuringInstallmentInvoicePosting` | The initial invoice-posting application-method guard remains enforced before financial writes. |
| `ImplicitNonPaymentApplicationStillRejectsInstallments` | The former blanket receipt-rejection case now checks the remaining unsupported non-payment boundary. |

Receipt fixtures now explicitly validate posting date and document currency.
Explicit-entry receipts invoke native tolerance management, matching the native
journal application flow; no accepted-tolerance amounts are fabricated by tests.
Tolerance fixtures isolate percentage/cap/warning/posting setup and customer
blocking. Foreign-currency cases retain a fixed adjustment rate while changing
the payment exchange rate, separating realized settlement effects from an
independently configured revaluation scenario.

**Propagation and evidence**

- `Invoke-Miapp -SkipSync -SkipFileStatus -NoMergeTool -FileNameFilter '(^|[\\/])CustLedgerEntry\.Table\.al$'`
  stopped at an APAC merge conflict because interactive resolution was
  unavailable. It left no unresolved tracked files. The identical four-line key
  was applied manually to all nine existing country copies, preserving local
  keys and behavior.
- `git diff --check`: passed.
- Ordering-key consistency check: passed for all ten shared/country table copies,
  including `MaintainSQLIndex = false`.
- `Invoke-MiSnapApp -Files $files`, where `$files` contains all changed layer AL
  paths from `git diff HEAD --name-only`: passed, `SUCCESS: No missing files`
  (12 layer paths, including all ten customer-ledger table copies).
- Compilation and publishing: after explicit user authorization, the assistant
  compiled and published Base Application and Tests-ERM 30.0.0.0 to
  `Navision_master`, tenant `default`, using normal schema synchronization.
  Base Application compiled with zero errors and the same 337 compiler warnings
  as the earlier build (normalized diagnostics unchanged); Tests-ERM compiled
  with zero errors and zero warnings.
- Runtime: the initial local run exposed 15 failures. After the corrections
  below, all 71 installment tests passed with no failures or skipped tests.
  The native local server was used directly, not a BC container.

**Runtime corrections and final evidence (2026-11-17)**

- The sales-header modify guard now validates an already-replaced owned draft
  or explicit payment-term removal instead of assuming the previous draft
  still exists. Immediate replacement retains the unique Source SystemId
  invariant; posted-plan and replacement-ownership guards remain enforced.
- Temporary-only calculation/posting guard helpers now take their record by
  reference, so a by-value temporary copy cannot hide a persistent caller.
- Discount fixtures explicitly permit invoice discounting; the bill-to change
  fixture explicitly accepts native confirmation. Journal guard fixtures now
  supply valid posting data and commit the baseline that must survive the
  expected rollback.
- Discount, tolerance, and realized-FX detail assertions now inspect the native
  application transaction, including receipt-side entries. Exact expected
  amounts, selected-installment balances, G/L reconciliation, and
  unapply/reapply assertions are retained.

| Codeunit | Passed | Failed | Skipped |
| --- | ---: | ---: | ---: |
| 134491 ERM Installment Calculation | 19 | 0 | 0 |
| 134492 ERM Installment Draft | 13 | 0 | 0 |
| 134493 ERM Installment Posting | 38 | 0 | 0 |
| 134494 ERM Installments UI | 1 | 0 | 0 |
| Total | 71 | 0 | 0 |

Executed test command (`$tool` is
`C:\Depot\master\Run\ALDevEnv\bin\altool.exe`; `$root` is the session artifact
directory, containing the four-codeunit test-group JSON):

```powershell
& $tool runtests --testgroups (Join-Path $root 'erm-installments-testgroups.json') `
    --project 'C:\depot\master\app\BCApps\src\Layers\W1\Tests\ERM' `
    --server 'http://localhost' --serverinstance Navision_master --port 7049 `
    --environmenttype OnPrem --authentication Windows --tenant default
```

Result: passed, exit code 0; structured results and call stacks are retained in
`erm-installments-tests-fixed.log` in the session artifacts.
The configured CodeCop, AppSourceCop, PerTenantExtensionCop, and UICop analyzers
also passed with `src\rulesets\base.ruleset.json`: zero errors, 11,746 warnings
project-wide, and no diagnostics in the three changed production codeunits.
`Invoke-MiSnapApp -Files $files` passed for the six corrected AL paths; these
new W1 objects have no country copies. `git diff --check` passed.

This package does not start M2-03 corrective posting or resolve M2-D02/M2-D03.
Printed invoice schedules, layouts, and new API delivery remain deferred.

### 22.11. M2-03: credits and corrections

**Status (2026-11-17):** Implemented, locally compiled, published, and
runtime-validated under the user-approved M2-D02/M2-D03 policies. All 80
installment tests passed on the native `Navision_master` development server.
This section supersedes the earlier correction rejection boundary; it is not
full M2 sign-off. The user confirmed the preceding shared-library move and
71-test baseline.

**Accounting and application contract**

- An unpaid installment invoice can use native cancellation, correction, or
  corrective copying. One native credit is applied to the exact original
  installment entries; no mirrored credit schedule is created. The adapter
  validates posted-plan ownership, ledger links, original amounts, currency,
  dates, sequence, and invoice totals before automatic application.
- A replacement invoice owns an independent draft copied from the original
  frozen rules, not subsequently changed reusable payment terms. Posting creates
  independent receivables; the original posted snapshot remains unchanged.
- Partial document-linked credits require explicit Applies-to ID selection.
  Corrective copies of partly paid invoices do not automatically select an
  entry. Manual allocation uses the native application/unapplication engine;
  previously paid amounts are preserved. Credits do not introduce a new cash
  discount policy. Automatic cancellation/correction retains the native
  fully-or-partly-paid restriction.
- Full document-linked credits retain the header's original invoice link for
  native cancellation tracking, but their posting journal applies through a
  unique ID across all owned installments. Automatic correction suppresses both
  the outer pre-post commit and the posting codeunit's commits, including
  date-ordered number series, so posting and cancellation tracking share a
  transaction.
- The correction notification's applied-entry action shows the union of native
  applications across the invoice group. Ordinary per-entry navigation remains
  unchanged. W1 changes are propagated to APAC, ES, and RU where applicable.
- Ledger reversal, unsupported invoice producers, and document-number-only
  payment ambiguity remain guarded. Ordinary sales credit memos can retain
  installment payment-term codes without acquiring a plan; the journal guard
  verifies native posted-credit/draft provenance rather than enabling generic
  credit journals. Italy retains its global-feature rejection.

**Source coverage and validation**

Codeunit 134496 `ERM Installment Correction` adds nine cases: unpaid cancellation
and single revenue/VAT reversal; independent replacement schedule; selected
partial credit/unapply preserving earlier payment and discount terms; native
paid-invoice rejection; explicit selection for partial unpaid credits;
mid-application rollback; cancellation-tracking failure with date-ordered number
series; non-anchor applied-payment navigation; and generic credit-journal
rejection. The former corrective-copy rejection case in codeunit 134493 now
checks successful posting of one credit across all original installments.
The complete installment suite now contains 80 tests; all passed in the final
runtime run below.

Local validation used `C:\Depot\master\Run\ALDevEnv\bin\alc.exe`
(30.0.46.29347), the session-private `erm-symbols` package cache, and each
project's existing assembly probing paths with nonexistent directories excluded:

```powershell
& $compiler "/project:$project" "/out:$output" `
    "/packagecachepath:$root\erm-symbols" `
    "/assemblyprobingpaths:$($paths -join ',')" /maxdegreeofparallelism:4
```

Result: Base Application passed with zero errors and 337 existing warnings;
Tests-ERM passed with zero errors and zero warnings. New packages use the
`m2-03-` prefix in session artifacts; the compiled Base package was copied only
to the private symbol cache for ERM compilation.

The same Base command with
`"/analyzer:$($analyzers -join ',')"` and
`/ruleset:C:\depot\master\app\BCApps\src\rulesets\base.ruleset.json`
passed for the configured CodeCop, AppSourceCop, PerTenantExtensionCop, and
UICop DLLs. All 11,746 warning signatures match `base-fix-analyzers.log` after
normalizing diagnostic line/column positions: zero added or removed warnings.
Evidence is retained in `m2-03-base-compile.log`,
`m2-03-base-analyzers.log`, and `m2-03-erm-compile.log`.

**Runtime validation and correction (2026-11-17)**

At the user's request, the compiled Base Application and Tests-ERM packages
were published to the existing native development server using normal
`Synchronize`. No container, ForceSync, or manual application uninstall was used.
The initial run passed 79 tests and failed the replacement-invoice case:
customer validation attempted to calculate changed reusable rules before the
posted invoice's frozen rules were transferred.

The copy adapter now establishes and saves an independently owned draft from
the original frozen plan before native customer/payment-term validation.
Subsequent field transfer replaces that draft through the existing ownership
mechanism, retaining the unique Source SystemId invariant. The original
regression case remains unchanged: reusable terms have a descending due-date
sequence, while correction must still use the valid original snapshot.
No date validation was weakened.

The corrected Base package compiled with the four configured analyzers:
zero errors and the same 11,746 normalized warning signatures as the baseline.
Evidence is in `m2-03-base-runtime-fix-compile.log`; the corrected package was
republished successfully, recorded in `m2-03-base-runtime-fix-publish.log`.
The original successful publications are recorded in
`m2-03-base-publish.log` and `m2-03-erm-publish.log`.

Publish command (`$tool` is
`C:\Depot\master\Run\ALDevEnv\bin\altool.exe`; `$package` and `$project`
select the compiled Base or ERM package and its corresponding project):

```powershell
& $tool publishapp $package --project $project `
    --server http://localhost --serverinstance Navision_master --port 7049 `
    --environmenttype OnPrem --authentication Windows --tenant default `
    --schemaupdatemode Synchronize
```

Final executed test command (`$root` is the session artifact directory; the
test-group JSON includes all five codeunits below):

```powershell
& $tool runtests --testgroups "$root\erm-installments-m2-03-testgroups.json" `
    --project 'C:\depot\master\app\BCApps\src\Layers\W1\Tests\ERM' `
    --server http://localhost --serverinstance Navision_master --port 7049 `
    --environmenttype OnPrem --authentication Windows --tenant default
```

Result: passed, exit code 0. Structured results and individual case evidence
are retained in `erm-installments-m2-03-tests-fixed.log`; the initial failure
and call stack remain in `erm-installments-m2-03-tests.log`.

| Codeunit | Passed | Failed | Skipped |
| --- | ---: | ---: | ---: |
| 134491 ERM Installment Calculation | 19 | 0 | 0 |
| 134492 ERM Installment Draft | 13 | 0 | 0 |
| 134493 ERM Installment Posting | 38 | 0 | 0 |
| 134494 ERM Installments UI | 1 | 0 | 0 |
| 134496 ERM Installment Correction | 9 | 0 | 0 |
| Total | 80 | 0 | 0 |

Country propagation validation passed for all 12 changed AL paths. Compiler-
generated layout edits were removed; layout development remains deferred.
This validates the local W1 installment suite, not FCY correction, every country
runtime, or the full broader M2 matrix. Printed invoices, layouts, and new API
delivery remain deferred.

### 22.12. M2-04: collections and payment reconciliation

**Status (2026-11-17):** Source implemented and locally compiled. At this
package's validation gate the user authorized **compilation only**. M2-04 has
not been published or runtime-tested; the accepted server baseline remains
the 80-test M2-03 result above.

**Approved matching boundary and implementation**

M2-D04 requires explicit manual customer-entry selection whenever the original
invoice still has more than one open installment. A different residual amount
does not identify the user's intended obligation, and a receipt equal to the
full invoice does not bypass this first-increment boundary.

`Sales Installment History` subscribes to
`Applied Payment Entry.OnApplyFromBankStmtMatchingBufOnBeforeInsert`.
Both native single-candidate and one-to-many automatic applications use this
shared point. A customer candidate belonging to a plan with multiple open
entries raises an explicit invoice/statement-line error directing the user to
manual selection. Matching is stopped rather than silently accepting the first
due entry, assigning confidence to an ambiguous choice, or redirecting the
receipt to a lower-ranked candidate. The native matching transaction rolls
back; the user must select the exact entries before retrying. This is a batch
error, not an automatically skipped line.

Native manual application creates exact `Applies-to Entry No.` selections and
does not use this automatic-application event. The existing reconciliation
posting code applies those entries through Applies-to ID and the native customer
application engine. The last open installment and ordinary invoices retain
native matching; vendor, employee, and bank-ledger candidates are unchanged.
No new matching engine, allocation policy, or financial cache is introduced.

**Native collection paths retained**

- `Standard Statement` already reads each original detailed/customer entry,
  retaining the shared invoice document number, separate due dates, and
  entry-specific as-of remaining balances. Logical invoice grouping must sum
  those obligations, not repeat the header total per row. No dataset or layout
  change is needed for this boundary.
- `Reminder-Make` selects open entries by their own due dates and reminder
  history. Native not-yet-due lines remain informational when requested; they
  are not accelerated obligations or new reminder levels.
- `FinChrgMemo-Make` and `Finance Charge Memo Line` calculate eligibility and
  interest from each selected entry. Existing finance-charge methods, grace
  periods, fees, and issuing policies are retained rather than replaced.
  The new focused fixture uses Open Entries and Balance Due interest to isolate
  overdue, paid, and future-installment behavior.

**Focused source cases**

New codeunit 134497 `ERM Installment Collections` contains nine cases:

| Case | Assertions to validate at runtime |
| --- | --- |
| `OverdueReminderCollectsOnlyTheRemainingDueInstallment` | A 10 receipt leaves 31.67 collectible on the first installment; the future 41.67/41.66 obligations are not demanded. |
| `InformationalFutureLinesDoNotAdvanceInstallmentReminderLevels` | Future lines are Not Due with no interest/reminder count; issuing advances only the due entry. Later suggestions produce entry-specific levels and exclude a settled installment. |
| `FinanceChargesUseOnlyOverdueRemainingBalances` | At 12% Balance Due, interest is 3.80 on 31.67; after settlement only the newly overdue 41.67 entry incurs 5.00. Future entries are not charged. |
| `StatementPreservesLogicalInvoiceTotalsAndSeparateDueBalances` | Native in-memory statement data contains three obligations for the same invoice, original total 125, remaining total 115, and overdue balance 31.67 without repeated header amounts. |
| `AutomaticReconciliationRequiresSelectionForSharedInvoiceReferences` | Equal-installment, unique-residual, and exact-full-invoice receipt amounts all require selection while multiple installments remain open; no application or partial line update survives rejection. |
| `DuplicateExternalReferencesCannotChooseAnInstallment` | A reference shared by two invoices cannot silently select an invoice/installment. |
| `ManualReconciliationPostsOnlySelectedInstallments` | One 83.34 receipt settles the two selected entries; a prior 10 receipt against the third remains intact, leaving 31.66 invoice-wide. |
| `LastOpenInstallmentRetainsNativeAutomaticMatching` | Native matching identifies and settles the remaining exact entry once the other installments are closed. |
| `OrdinaryInvoiceRetainsNativeAutomaticReconciliation` | A non-installment invoice keeps one native automatic application and closes normally. |

These are compiled source cases, **not passing runtime evidence**. The complete
installment suite now has 89 tests. The session artifact
`erm-installments-m2-04-testgroups.json` selects all six installment codeunits
for a future authorized run.

**Compilation evidence and remaining gates**

Local compilation used `C:\Depot\master\Run\ALDevEnv\bin\alc.exe`
(30.0.46.29347), each project's existing valid assembly probing directories,
and the private `erm-symbols` package cache:

```powershell
& $compiler "/project:$project" "/out:$output" `
    "/packagecachepath:$root\erm-symbols" `
    "/assemblyprobingpaths:$($paths -join ',')" /maxdegreeofparallelism:4
```

Base Application also used the configured CodeCop, AppSourceCop,
PerTenantExtensionCop, and UICop DLLs through
`"/analyzer:$($analyzers -join ',')"` and
`/ruleset:C:\depot\master\app\BCApps\src\rulesets\base.ruleset.json`.
Result: passed, zero errors; all 11,746 normalized warning signatures match the
baseline, with no added or removed warnings. Tests-ERM passed with zero errors
and zero warnings. Logs are `m2-04-base-compile.log` and
`m2-04-erm-compile.log`; compiled packages use the `m2-04-` prefix in session
artifacts and were not deployed.

Runtime acceptance must execute these cases and the existing installment
regressions before this package is accepted. FCY reconciliation, additional
finance-charge methods/fees, country runtime behavior, realistic-volume checks,
and broader M2 integration remain unverified gates, not implied compatibility.
Existing unsupported-producer, correction/reversal, and IT activation boundaries
remain in force. Printed invoices, layouts, and new API delivery remain deferred.

### 22.13. M2-05: aging and Cash Flow Forecast

**Status (2026-11-17):** Native calculation paths reviewed; eleven focused source
cases added and affected projects locally compiled. The user authorized
**compilation only** for this package. No M2-05 packages were published, no
runtime cases were executed, and the server remains at the accepted M2-03
baseline. M2-04 runtime acceptance is also still pending.

**Calculation contract and implementation boundary**

No production adapter is required for the reviewed paths. The current
`EXR Aged Accounts Rec Excel` report (4402) reads exact customer ledger entries,
sets both Posting Date and Date Filter through its cutoff, calculates remaining
document/LCY balances, and keys its temporary buffer by Entry No. It deliberately
does not filter by today's Open state, so an installment settled after the
cutoff can still appear in historical aging. `EXR Aging Report Buffer` (4401)
uses each entry's selected aging date and the native period boundaries. Tests
exercise this current data engine rather than the obsolete report 120, and
export only in-memory XML: no workbook rendering or layout edits are included.

`Suggest Worksheet Lines` (840) selects open, nonzero customer entries and
copies each entry's remaining LCY, due date, discount dates, and discount amount.
Each temporary worksheet insertion receives a separate line number even when
Source No. and Document No. are shared. Its grouping option affects order lines,
not receivable installments. Native worksheet registration copies each line's
date and amount into a separate forecast entry; it does not need another invoice
total or an installment financial cache.

M2-D05 preserves explicitly enabled native customer cash-flow terms, including
their original-document-date basis. Without that option, the native forecast
uses the original installment due dates. Native Consider Discount and Overdue
CF Dates to Work Date options also remain forecast projections, not changes to
posted ledger dates or immutable original plan amounts. Changing an exchange
rate alone must not replace the ledger's remaining LCY balance with a fresh
conversion; native revaluation remains the separate accounting operation.

**Focused source cases**

| Location/case | Assertions to validate at runtime |
| --- | --- |
| 134498 `ForecastAndRegistrationRetainSeparateInstallmentObligations` | Both grouping settings retain three 30/60/90-day receivable lines totaling 125; native registration retains three dates and the same forecast total. |
| 134498 `ForecastExcludesSettledAndReducesPartlyPaidInstallments` | Closing the anchor and paying 10 against the third leaves two forecast obligations totaling 73.33; full settlement removes all forecast lines for the invoice. |
| 134498 `ForecastReflectsSelectedCreditWithoutMirroringCreditSchedule` | An explicit 20 credit to installment two and a prior 10 receipt on installment three leave 95 at the original installment dates; the fully applied credit is not forecast again. |
| 134498 `ForeignCurrencyForecastUsesRemainingLedgerLCYNotCurrentExchangeRate` | Partial/full FCY receipts reduce the correct entries. A later exchange-rate record without revaluation does not change the remaining ledger LCY used by the forecast. |
| 134498 `ForecastDiscountsFollowIndividualDatesAndAmounts` | Eligible first/second discounts use their own dates and amounts, producing expected receipts of 123.75; the undiscounted third installment keeps its due date. |
| 134498 `ForecastPreservesExplicitCustomerPaymentTermOverride` | Customer forecast terms are ignored when disabled, may project all three receipts onto document date +45D when enabled, and revert to installment dates when disabled again without changing ledger due dates or the 125 total. |
| 134498 `OverdueForecastDateOptionDoesNotRewriteInstallmentDueDates` | Only the overdue forecast line moves to Work Date when requested; future lines and the original overdue ledger due date remain unchanged. |
| 139555 `InstallmentAgingRetainsSeparateEntriesAcrossBucketBoundaries` | Exact Entry No. identities, original/remaining amounts, due/reporting dates, and native aging periods remain distinct across the +90/+91-day boundary. |
| 139555 `InstallmentAgingReconstructsBalancesBeforeLaterPaymentAndCredit` | After a receipt dated +45D and selected credit dated +75D, historical cutoffs reconstruct 125, 115, and 95 rather than using today's remaining balances. |
| 139555 `InstallmentAgingIncludesEntriesClosedAfterTheCutoff` | A fully settled invoice still contributes all entries at the earlier cutoff; anchor settlement removes only the anchor from later aging, and final settlement removes all obligations. |
| 139555 `ForeignCurrencyInstallmentAgingReconcilesOriginalAndRemainingLCY` | Original per-entry document/LCY allocations stay immutable; as-of FCY and LCY balances reconcile to the exact entries and customer at both cutoffs. |

Shared fixtures remain in codeunit 134495 `Library - ERM Installments`.
New helpers post the known 125 invoice with optional installment discounts,
resolve exact entries through the posted plan, and apply a native selected
corrective credit. A date-aware payment overload uses the target entry's currency;
existing three-argument callers continue to use Work Date.

The M2-04 statement case was also corrected to select native XML DataItem/Column
nodes. `Library - Report Dataset.SetRange` requires the older embedded preview
schema and cannot filter `Report.SaveAs` XML loaded without that schema.
The aging cases likewise use native XML selection and invariant value parsing.
This is a test-fixture correction, not a statement or layout behavior change.

**Actual compilation evidence**

Compiler: `C:\Depot\master\Run\ALDevEnv\bin\alc.exe`
(30.0.46.29347). All outputs and dependency symbol updates were confined to the
session artifact directory/private `erm-symbols` cache. Application Test Library
and ERM used their existing valid assembly probing paths and configured
analysis-disabled settings:

```powershell
& $compiler "/project:$project" "/out:$output" `
    "/packagecachepath:$root\erm-symbols" `
    "/assemblyprobingpaths:$($paths -join ',')" /maxdegreeofparallelism:4
```

The missing Excel Reports dependency and its tests used:

```powershell
& $compiler "/project:$project" "/out:$output" `
    "/packagecachepath:$root\erm-symbols" /maxdegreeofparallelism:4
```

| Project | Result | Session log |
| --- | --- | --- |
| Application Test Library | Passed; zero errors; six existing obsolescence warnings, normalized signatures identical to the earlier library baseline. | `m2-05-library-compile.log` |
| Dynamics BC Excel Reports (unchanged source dependency) | Passed; zero errors/warnings. | `m2-05-excel-app-compile.log` |
| Tests-ERM | Passed; zero errors/warnings. | `m2-05-erm-compile.log` |
| Dynamics BC Excel Reports Tests | Passed; zero errors/warnings. | `m2-05-excel-tests-compile.log` |

There are now **100 installment-focused source cases**: 96 across the seven ERM
codeunits and four added to aging codeunit 139555. Prepared session selections
are `erm-installments-m2-05-testgroups.json` and
`excel-installments-m2-05-testgroups.json`. The latter runs all 18 cases in the
existing aging codeunit, including 14 pre-existing non-installment regressions;
the combined selections therefore contain 114 tests, not 100.

**Remaining acceptance gates**

Compilation is not runtime acceptance. A future authorized validation must
deploy compatible shared-library/ERM/Excel Reports packages and the pending
M2-04 Base change before executing the full selections. No new object ownership
move, uninstall, schema force synchronization, or environment repair is part of
this package.

Historical FCY revaluation/realized gain-loss combinations, three-decimal and
whole-unit aging/forecast matrices, discount/tolerance option combinations,
additional aging modes and consumers, country runtime behavior, permissions,
and realistic-volume behavior remain broader validation gates. M2-06 integration
review and the existing unsupported-path/IT boundaries remain in force. Printed
invoices, layouts, and new schedule API delivery remain deferred.
