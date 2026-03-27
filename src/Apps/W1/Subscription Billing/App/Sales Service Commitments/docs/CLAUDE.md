# Sales Service Commitments

This module bridges the standard BC sales process and the Subscription Billing
engine. When a user sells an item that carries subscription packages, this
module auto-generates Sales Subscription Lines on the sales document, carries
them through archiving and document-copy workflows, and ultimately hands them
off to the subscription/contract system at shipment time.

## Core objects

**`SalesSubscriptionLine.Table.al`** (table 8068) stores subscription lines
attached to a sales document line. Each record captures billing terms
(Initial Term, Extension Term, Notice Period, Billing Base Period, Billing
Rhythm), pricing details (Calculation Base Type/Amount/%, Price, Discount),
and a Partner enum indicating whether the line bills a customer or a vendor.
The table prevents edits while the parent sales order is released. It also
holds `Subscription Header No.` and `Subscription Line Entry No.` fields
that get populated after shipment, linking back to the created subscription.

**`SalesSubscriptionLineMgmt.Codeunit.al`** (codeunit 8069) orchestrates the
full lifecycle. It is `SingleInstance` so a `SalesLineRestoreInProgress`
flag can suppress auto-creation during archive-restore. The codeunit
subscribes to events on Sales Line insert, Sales-Quote to Order,
Blanket Sales Order to Order, Copy Document, Explode BOM, Archive
Management, Sales-Post, and Undo Sales Shipment Line.

**`SalesSubLineArchive.Table.al`** (table 8069) mirrors the
SalesSubscriptionLine structure with added `Version No.` and
`Doc. No. Occurrence` fields for archive versioning.

**`SalesServiceCommitmentBuff.Table.al`** (table 8020) is a temporary buffer
used exclusively by `CalcVATAmountLines` in SalesSubscriptionLine to
aggregate subscription amounts by billing rhythm and VAT setup for report
totals.

## How subscription lines are created

When an item with Subscription Option set to "Service Commitment Item" or
"Sales with Service Commitment" is entered on a sales line,
`AddSalesServiceCommitmentsForSalesLine` fires via `SalesLineOnAfterInsertEvent`.
It queries `Item Subscription Package` records filtered by the item and the
header's Customer Price Group, selecting packages marked `Standard = true`.
For each matching package, it walks the package's `Subscription Package Line`
records and inserts a `Sales Subscription Line` per package line.

After standard packages are applied, `AddAdditionalSalesServiceCommitmentsForSalesLine`
runs. This opens the "Assign Service Commitments" dialog showing non-standard
(optional) packages. The dialog only appears if optional packages exist and
`GuiAllowed()` returns true. Contract renewal lines block this dialog
entirely and raise an error if attempted.

The item number written to each Sales Subscription Line depends on the item's
Subscription Option. For "Service Commitment Item", the package line's
Invoicing Item No. is used if present, otherwise the item itself. For
"Sales with Service Commitment" invoiced via Contract, the package line must
have an Invoicing Item No.

## Calculation base types

The Calculation Base Type on each subscription line controls how Price is
derived:

- **Item Price** -- uses the item's list price (via `UpdateUnitPrice`) for
  customer lines, or `CalculateUnitCost` for vendor lines.
- **Document Price** -- uses `Unit Price` from the sales line (customer) or
  `Unit Cost` (vendor). Price tracks the document.
- **Document Price And Discount** -- same as Document Price but also copies
  `Line Discount %` from the sales line into the subscription line's
  Discount %. This is the only mode where sales line discounts flow through.

A notification warns when the user changes a sales line discount and
the subscription line uses a Calculation Base Type other than
"Document Price And Discount", since the discount will not propagate.

## Subscription line recalculation

Changes to Quantity, Unit Price, Unit Cost, Line Discount %, or
Line Discount Amount on the sales line trigger
`UpdateSalesServiceCommitmentCalculationBaseAmount`. This recalculates
every attached Sales Subscription Line by calling
`CalculateCalculationBaseAmount`, keeping subscription pricing in sync
with the document.

## Document lifecycle events

**Quote to Order / Blanket Order to Order** -- subscription lines transfer
via `TransferServiceCommitments`, which copies each line to the new document
type while re-validating `Calculation Base Amount`.

**Copy Document** -- if `RecalculateLines` is true, subscription lines are
regenerated from item packages. Otherwise they are transferred field-by-field
from the source document. Copy from archive works the same way.

**Archive** -- `StoreSalesServiceCommitmentLines` copies every subscription
line to `Sales Sub. Line Archive` on each archive action.
`RestoreSalesServiceCommitment` reverses this, and the `SingleInstance`
flag `SalesLineRestoreInProgress` prevents the insert-event from re-adding
packages during restore.

**Post (Sales-Post)** -- the `OnBeforeSalesLineDeleteAll` subscriber deletes
subscription lines from the sales document after posting, since at that point
the subscription has been created.

**Undo Shipment** -- `RemoveQuantityInvoicedForServiceCommitmentItems` zeros
out `Quantity Invoiced` and `Qty. Invoiced (Base)` on the shipment line for
service commitment items, because the original "invoiced" status was synthetic
(these items do not go through a real sales invoice).

## Table extensions on standard sales objects

`SalesHeader.TableExt.al` adds `Recurring Billing` (marks documents created
by the billing engine), `Sub. Contract Detail Overview` (controls whether
billing details print), and `Auto Contract Billing`. It also exposes
`HasOnlyContractRenewalLines` for checking whether a document contains
nothing but renewal lines.

`SalesLine.TableExt.al` adds `Recurring Billing from/to` date fields,
a `Subscription Lines` FlowField counting attached Sales Subscription Lines,
a `Subscription Option` FlowField from the Item table, a `Discount` boolean,
and `Exclude from Doc. Total`. It prevents manual selection of the
"Service Object" type, enforces that Invoice Discount is not allowed on
service commitment items, and blocks deferral codes when contract deferrals
are active on the billing line.

`SalesLineArchive.TableExt.al` adds the same `Subscription Lines` FlowField
and `Exclude from Doc. Total` to archived lines, and cleans up archived
subscription lines on delete.

`SalesShipmentLine.TableExt.al` adds a TableRelation override so the "No."
field resolves to `Subscription Header` when Type is "Service Object".

The Purchase Header and Purchase Line extensions in this folder add the
vendor-side `Recurring Billing` flag and billing date fields used by
vendor contract billing.

## Enum extension

`SubBillingSalesLineType.EnumExt.al` adds value 8000 "Service Object"
(captioned "Subscription") to the Sales Line Type enum, enabling sales lines
that reference a Subscription Header rather than an item or G/L account.

## Report extensions

`ContractStandardSalesQuote.ReportExt.al` and
`ContractSalesOrderConf.ReportExt.al` extend the standard quote and order
confirmation reports. They inject per-line subscription detail
(ServiceCommitmentForLine dataitem) and a grouped summary by billing rhythm
(ServiceCommitmentsGroupPerPeriod). Service commitment items are excluded
from document totals via `ExcludeItemFromTotals`. Both provide RDLC and Word
layouts under the `Layouts/` subfolder.

`ContractBlanketSalesOrder.ReportExt.al` extends the blanket order report,
excluding service commitment items from totals but not adding the per-line
detail.

## Page extensions and pages

The subform page extensions for Sales Quote, Sales Order, Blanket Sales
Order, and their archive counterparts all add a `Subscription Lines` column
after Line Amount, plus actions to view and add subscription lines.
The quote and order subforms also show Customer and Vendor Contract No.
fields derived from contract renewal subscription lines.

`SalesServiceCommitments.Page.al` (page 8082) is the detail editor for
subscription lines on a single sales line. `SalesServiceCommitmentsList.Page.al`
(page 8015) is a read-only global list page. `SalesServCommArchiveList.Page.al`
(page 8083) shows archived subscription lines.

`SalesLineFactBox.PageExt.al` adds the `Subscription Lines` count to the
Sales Line FactBox.

## Integration events

The codeunit publishes eight integration events for extensibility:

- `OnBeforeAddSalesServiceCommitmentsForSalesLine` -- suppress or replace auto-creation
- `OnBeforeCreateSalesSubscriptionLineFromSubscriptionPackageLine` -- intercept individual line creation
- `OnAfterCreateSalesSubscriptionLineFromSubscriptionPackageLine` -- post-process created lines
- `OnCreateSalesServCommLineFromServCommPackageLineOnAfterInsertSalesSubscriptionLineFromSubscriptionPackageLine` -- runs after insert, before field population
- `OnBeforeModifySalesSubscriptionLineFromSubscriptionPackageLine` -- modify line before final write
- `OnAddAdditionalSalesSubscriptionLinesForSalesLineAfterApplyFilters` -- adjust package filters for optional packages
- `OnBeforeGetItemNoForSalesServiceCommitment` -- override item number resolution
- `OnAfterShowAssignServiceCommitmentsDetermined` -- control whether the optional-package dialog shows

The SalesSubscriptionLine table publishes additional events around
calculation base amount computation and VAT line creation.
