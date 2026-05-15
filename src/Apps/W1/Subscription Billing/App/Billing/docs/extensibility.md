# Extensibility

The Billing module exposes integration events across its codeunits for
customization. This document groups them by what you're trying to achieve.

## Customizing billing proposal creation

**Codeunit: `BillingProposal.Codeunit.al` (8062) -- 12 events**

### Controlling which subscription lines enter the proposal

`OnBeforeProcessContractSubscriptionLines` fires after the subscription
line record is filtered by contract and next billing date but before the
loop begins. Subscribe to add extra filters or modify the billing date
parameters for a specific contract.

`OnCheckSkipSubscriptionLineOnElse` fires when a subscription line doesn't
match any of the built-in skip conditions (ended, existing document,
usage-based). Subscribe to implement custom skip logic -- for example,
skipping lines that have a specific custom field value. Set
`SkipSubscriptionLine := true` to exclude the line.

### Modifying billing lines before they're saved

`OnBeforeInsertBillingLineUpdateBillingLine` fires after the billing line
fields are populated from the subscription line and amounts are calculated,
but before `Insert`. This is the best place to set custom fields on the
billing line or adjust amounts.

`OnAfterUpdateBillingLineFromSubscriptionLine` fires after standard
subscription line fields are copied to the billing line but before amount
calculation. Subscribe to override field mappings or add custom field
transfers.

### Controlling amount calculation

`OnBeforeCalculateBillingLineUnitAmountsAndServiceAmount` fires before
the standard amount calculation. Set `IsHandled := true` to completely
replace the built-in price/cost calculation -- useful if you have custom
pricing logic.

### Controlling the billing period end date

`OnAfterCalculateNextBillingToDateForSubscriptionLine` fires after the
next billing-to date is calculated. Modify `NextBillingToDate` to change
the billing period end -- for example, to align with fiscal periods
instead of calendar months.

### Modifying the billing template filter

`OnCreateBillingProposalBeforeApplyFilterToContract` fires before the
template's filter is applied to the contract table. You can modify
`FilterText` to add or override filter criteria programmatically, or
adjust the billing dates.

### Overriding proposal creation from a contract card

`OnBeforeCreateBillingProposalFromContract` fires when billing is
initiated from a contract card rather than the Recurring Billing page.
Set `IsHandled := true` to replace the standard Create Billing Document
dialog with custom logic.

## Customizing document creation

**Codeunit: `CreateBillingDocuments.Codeunit.al` (8060) -- 27 events**

This codeunit has the most events because document creation involves many
steps. The most useful ones are grouped by purpose.

### Controlling the overall process

`OnBeforeCreateBillingDocuments` fires at the very start, before
validation. Subscribe to modify the billing line filters or perform
pre-processing.

`OnBeforeProcessBillingLines` fires after validation passes, with all
process parameters available as var parameters: `DocumentDate`,
`PostingDate`, `CustomerRecBillingGrouping`,
`VendorRecBillingGrouping`, `PostDocuments`. This is the best place to
override document creation settings programmatically.

`OnAfterProcessBillingLines` fires after all documents are created.
Subscribe for post-processing, notifications, or logging.

### Customizing document headers

`OnAfterCreateSalesHeaderFromContract` fires after a sales header is
created from a customer contract (per-contract grouping). The
`SalesHeader` is a var parameter -- modify it to set custom header
fields before lines are inserted.

`OnAfterCreateSalesHeaderForCustomerNo` fires after a sales header is
created for a customer (per-customer grouping).

### Customizing document lines

`OnBeforeInsertSalesLineFromContractLine` fires after the sales line is
fully populated (item, quantity, price, dimensions, description) but
before `Insert`. This is the primary hook for modifying invoice line
content -- adding custom fields, changing descriptions, or adjusting
amounts.

`OnBeforeInsertPurchaseLineFromContractLine` is the equivalent for
purchase lines.

`OnAfterInsertSalesLineFromBillingLine` and
`OnAfterInsertPurchaseLineFromBillingLine` fire after the line is
inserted and billing line references are updated. Subscribe for
post-insert processing like creating related records.

### Customizing invoice text

`OnGetAdditionalLineTextElseCase` fires when the configured
`ContractInvoiceTextType` doesn't match any built-in option. Subscribe to
implement custom invoice text types beyond the standard set (Service
Object, Service Commitment, Customer Reference, Serial No., Billing
Period, Primary Attribute).

`OnAfterGetAdditionalLineText` fires after the description text is
determined for any text type. Modify `DescriptionText` to append,
prepend, or replace the standard text.

### Customizing contract description lines

`OnBeforeInsertContractDescriptionSalesLines` fires before the contract
header description lines are inserted on collective invoices. Set
`IsHandled := true` to completely replace the standard description block.

`OnAfterInsertContractDescriptionSalesLines` fires after the description
lines are inserted. Subscribe to add extra descriptive lines.

`OnBeforeInsertAddressInfoForCollectiveInvoice` and
`OnAfterInsertAddressInfoForCollectiveInvoice` control the address
information block inserted in collective invoices for each contract.

### Controlling document grouping

`OnAfterIsNewSalesHeaderNeeded` fires during per-customer document
creation to determine if a new sales header should be created.
Modify `CreateNewSalesHeader` to force or prevent header breaks beyond
the standard logic (partner no. + detail overview + currency code).

`OnAfterIsNewHeaderNeededPerContract` is the equivalent for per-contract
document creation.

### Controlling temporary billing line consolidation

`OnBeforeInsertTempBillingLine` fires before the first temporary billing
line for a subscription line is inserted. Modify the temp line to set
custom fields.

`OnCreateTempBillingLinesBeforeSaveTempBillingLine` fires each time a
billing line is accumulated into the temp line (after amounts are summed).
Modify the temp line for custom consolidation logic.

### Controlling sort order before document creation

`OnCreateSalesDocumentsPerContractBeforeTempBillingLineFindSet`,
`OnCreateSalesDocumentsPerCustomerBeforeTempBillingLineFindSet`,
`OnCreatePurchaseDocumentsPerContractBeforeTempBillingLineFindSet`, and
`OnCreatePurchaseDocumentsPerVendorBeforeTempBillingLineFindSet` all fire
after the temp billing lines are keyed but before iteration. Modify the
temp line filters or sort order to control document creation sequence.

## Customizing sales document handling

**Codeunit: `SalesDocuments.Codeunit.al` (8063) -- 15 events**

Most events in this codeunit relate to subscription creation from sales
orders rather than billing. The billing-relevant ones are:

### Controlling billing line archival

`OnAfterInsertBillingLineArchiveOnMoveBillingLineToBillingLineArchive`
fires after each billing line is copied to the archive during posting.
Subscribe to set custom fields on the archive record.

`OnBeforeMoveBillingLineToBillingLineArchiveForPostingPreview` fires
during posting preview. Set `IsHandled := true` to skip archival in
preview mode if your custom logic doesn't support it.

### Controlling subscription item invoicing behavior

`OnCheckResetValueForSubscriptionItems` fires when determining whether a
sales line's amounts should be zeroed during posting (because it's a
subscription item). Set `IsHandled := true` and control
`ResetValueForSubscriptionItems` to change which lines get this treatment.

`OnBeforeClearQtyToInvoiceOnForSubscriptionItem` fires before Qty. to
Invoice is cleared on subscription items. Set `IsHandled := true` to
allow invoicing of subscription items through standard sales flow.

`OnAfterSalesLineShouldSkipInvoicing` fires after the standard check for
whether a sales line should skip invoicing. Modify `Result` to override
the decision.

### Controlling subscription creation from sales

`OnBeforeCreateSubscriptionHeaderFromSalesLine` fires before a
Subscription Header is created from a shipped sales line. Set
`IsHandled := true` to suppress automatic subscription creation or
replace it with custom logic.

`OnCreateSubscriptionHeaderFromSalesLineBeforeInsertSubscriptionHeader`
and the `AfterInsert` variant let you modify the subscription header
before/after it's saved.

`OnCreateSubscriptionHeaderFromSalesLineBeforeInsertSubscriptionLine`
and the `AfterInsert` variant let you modify subscription lines
before/after they're created from sales subscription lines.

## Customizing purchase document handling

**Codeunit: `PurchaseDocuments.Codeunit.al` (8066) -- 1 event**

`OnAfterInsertBillingLineArchiveOnMoveBillingLineToBillingLineArchive`
fires after each billing line is archived during purchase document
posting. This mirrors the sales equivalent and is useful for the same
custom field transfer scenarios.

## Customizing billing corrections

**Codeunit: `BillingCorrection.Codeunit.al` (8061) -- 3 events**

`OnBeforeCreateBillingLineFromBillingLineArchiveAfterInsertToSalesLine`
fires before the correction logic begins for a sales credit memo line.
Set `IsHandled := true` to bypass the standard correction process
entirely -- useful if you need custom credit memo handling for specific
contract types.

`OnAfterCreateBillingLineFromBillingLineArchive` fires after the
correction billing line is created from the archive. The `RRef`
(RecordRef) parameter gives you access to the target credit memo line.
Subscribe to create additional records or modify the correction line.

`OnBeforeUpdateNextBillingDateInCreateBillingLineFromBillingLineArchive`
fires before the subscription line's Next Billing Date is reset. Modify
the subscription line record to override the date calculation -- for
example, to preserve the current Next Billing Date in rebilling
scenarios.

## Customizing document change protection

**Codeunit: `DocumentChangeManagement.Codeunit.al` (8074) -- 1 event**

`OnBeforePreventChangeOnDocumentHeaderOrLine` fires before any field
change is blocked on a recurring billing document. Set
`IsHandled := true` to allow the change through. This is the primary
escape hatch for extensions that need to modify billing document fields
that are normally locked -- for example, adding a custom field to the
sales header that should be editable even on contract invoices.

## Recurring Billing page

**Page: `RecurringBilling.Page.al` (8067) -- 1 event**

`OnAfterApplyBillingTemplateFilter` fires after the billing template's
settings are applied to the page filters. Subscribe to add extra page
filters based on custom template fields or user context.
