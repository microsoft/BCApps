# Extensibility

The app publishes 320 integration events across 62 files. Rather than listing every event, this document groups them by what you would want to customize. The most event-dense objects are `Customer Subscription Contract` (50 events), `Subscription Header` (43 events), `Create Billing Documents` (27 events), `Vendor Subscription Contract` (20 events), `Sales Documents` (15 events), and `Billing Proposal` (12 events).

## Customizing billing document creation

`CreateBillingDocuments.Codeunit.al` (27 events) is the most extensible codeunit. Key hook points:

- **Before/after the entire process**: `OnBeforeCreateBillingDocuments`, `OnAfterProcessBillingLines` -- intercept or modify the billing line set before documents are generated
- **Document header creation**: `OnCreateSalesDocumentsPerContractBeforeTempBillingLineFindSet`, `OnCreateSalesDocumentsPerCustomerBeforeTempBillingLineFindSet`, and equivalent purchase events -- filter or reorder billing lines before they become document lines
- **Line insertion**: events around `InsertSalesLineFromTempBillingLine` and `InsertPurchaseLineFromTempBillingLine` -- modify amounts, descriptions, or dimensions on the created document lines
- **Grouping decisions**: events on `IsNewSalesHeaderNeeded` / `IsNewPurchaseHeaderNeeded` -- override when a new document header is created vs. appending to an existing one
- **Post-creation**: events after document creation completes, useful for logging, notifications, or chaining to other processes

## Customizing billing proposals

`BillingProposal.Codeunit.al` (12 events) exposes hooks at key decision points:

- **Before processing contract subscription lines**: `OnBeforeProcessContractSubscriptionLines` -- add extra filters or skip specific subscription lines
- **After processing**: `OnAfterProcessContractSubscriptionLines` -- post-process created billing lines
- **Skip logic**: `OnCheckSkipSubscriptionLineOnElse` -- custom logic for whether to skip a subscription line during proposal creation
- **Line calculation**: `OnBeforeInsertBillingLineUpdateBillingLine` -- modify billing line amounts or periods before insertion
- **Billing-to date changes**: events around `OnCreateBillingProposalBeforeApplyFilterToContract` -- adjust filtering before contracts are enumerated

## Customizing sales document handling

`SalesDocuments.Codeunit.al` (15 events) hooks into sales posting to control subscription creation:

- **Subscription creation from posted sales**: events around when subscriptions and subscription lines are created from posted sales lines
- **Delete handling**: events when sales invoices/credit memos linked to billing lines are deleted
- **Contract renewal integration**: events for the renewal-specific posting flow

`SalesSubscriptionLineMgmt.Codeunit.al` (8 events) controls how sales subscription lines are generated:

- `OnBeforeAddSalesServiceCommitmentsForSalesLine` -- prevent or modify auto-creation of subscription lines on sales lines
- Events around package selection and insertion -- customize which packages are applied to which sales lines

## Customizing subscription header behavior

`SubscriptionHeader.Table.al` (43 events) publishes events on virtually every field validation and key operations:

- **Customer changes**: `OnValidateEndUserCustomerNoAfterInit`, `OnValidateBillToCustomerNoOnAfterConfirmed` -- customize behavior when End-User or Bill-to customer changes
- **Address synchronization**: events around copying address fields from customer records
- **Subscription line recalculation**: events triggered when header changes cascade to subscription lines (e.g., customer change, currency change)
- **Insert/modify/delete lifecycle**: standard lifecycle events for custom validation or side effects

## Customizing subscription line behavior

`SubscriptionLine.Table.al` (11 events) covers pricing and contract assignment:

- **Price calculation**: events around `CalculatePrice` and `CalculateServiceAmount` -- override pricing logic
- **Contract assignment**: events when subscription lines are linked to or unlinked from contracts
- **Date calculations**: events around billing date, term date, and cancellation date computation

## Customizing customer contracts

`CustomerSubscriptionContract.Table.al` (50 events) is the most event-dense table, covering:

- **Customer field changes**: Sell-to and Bill-to customer validation chains with events at each step
- **Address field synchronization**: events for copying and updating address fields from customer records
- **Dimension management**: events around dimension creation and defaulting
- **Contract lifecycle**: events on insert, modify, delete, and status changes
- **Contact integration**: events around updating sell-to and bill-to contact references

`CustSubContractLine.Table.al` (6 events) covers contract line operations including subscription line connection/disconnection.

## Customizing vendor contracts

`VendorSubscriptionContract.Table.al` (20 events) follows the same pattern as customer contracts but with vendor-specific fields:

- **Vendor field changes**: Buy-from and Pay-to vendor validation events
- **Address synchronization**: events for vendor address fields
- **Lifecycle events**: insert, modify, delete

## Customizing price updates

The `Contract Price Update` interface (`ContractPriceUpdate.Interface.al`) is the primary extensibility point for custom pricing methods. Implement the four interface methods (`SetPriceUpdateParameters`, `ApplyFilterOnServiceCommitments`, `CreatePriceUpdateProposal`, `CalculateNewPrice`) and add a new value to the `Price Update Method` enum.

Each of the three built-in implementations publishes one event: `OnAfterFilterSubscriptionLineOnAfterGetAndApplyFiltersOnSubscriptionLine` in `PriceUpdateManagement.Codeunit.al` for post-filter customization.

## Customizing usage-based billing

The `Usage Data Processing` interface (`UsageDataProcessing.Interface.al`) allows custom connector implementations. Implement the five interface methods (`ImportUsageData`, `ProcessUsageData`, `TestUsageDataImport`, `FindAndProcessUsageDataImport`, `SetUsageDataImportError`) and add a new value to the `Usage Data Supplier Type` enum.

`CreateUsageDataBilling.Codeunit.al` (3 events) and `ProcessUsageDataBilling.Codeunit.al` (8 events) provide hooks into the billing creation and post-processing stages. `UsageDataImport.Table.al` (3 events) and `UsageDataBilling.Table.al` (3 events) cover data-level customization.

## Customizing contract renewals

`CreateSubContractRenewal.Codeunit.al` (12 events) is heavily extensible:

- **Validation**: `OnAfterCheckSubContractRenewalLine`, `OnAfterRunCheck` -- add custom validation rules
- **Sales quote creation**: events around sales header and line creation from renewal lines
- **Batch processing**: events for batch renewal operations

`PostSubContractRenewal.Codeunit.al` (5 events) covers the posting side -- events around planned subscription line creation and term extension.

## Customizing deferrals

`CustomerDeferralsMngmt.Codeunit.al` (3 events) and `VendorDeferralsMngmt.Codeunit.al` (1 event) hook into the deferral creation during invoice posting. `ContractDeferralsRelease.Report.al` (2 events) allows customization of the monthly release process.

## Customizing imports

The import codeunits (`CreateSubscriptionHeader`, `CreateSubscriptionLine`, `CreateCustSubContract`, `CreateSubContractLine`) each publish 3-4 events around their creation and validation logic, allowing customization of the bulk import workflow.

## Customizing UI and reports

Several pages publish events for adding custom actions or modifying behavior:

- `CustomerContract.Page.al` (3 events), `ExtendContract.Page.al` (3 events) -- customer contract page customization
- `ContractRenewalSelection.Page.al` (4 events) -- renewal selection customization
- `RecurringBilling.Page.al` (1 event) -- billing page customization
- Sales report extensions (2 events each) -- customize subscription data on sales order confirmations and quotes
