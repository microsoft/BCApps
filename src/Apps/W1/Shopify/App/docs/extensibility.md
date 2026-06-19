# Extensibility

The Shopify Connector exposes two categories of extension points: **integration events** (subscribe to react to or modify behavior) and **interfaces** (implement to provide entirely new strategies). The Shop table's enum fields select which interface implementation is active -- extending the connector often means adding a new enum value with a corresponding interface implementation.

## Overview

The extension model follows a consistent pattern across all domains. Configuration enums on the Shop table (like `"Customer Mapping Type"`, `"Stock Calculation"`, `"Status for Created Products"`) each map to an interface. The enum's implementation attribute links each value to a codeunit that implements the interface. At runtime, the connector reads the enum from the Shop record and dispatches through the interface.

To add a new strategy, you extend the enum (adding a new value), create a codeunit implementing the interface, and link them via the `Implementation` attribute on the enum extension. No modification to existing code is needed.

Integration events provide finer-grained hooks for modifying data in flight. Most follow the `OnBefore`/`OnAfter` pattern, where `OnBefore` events include a `var Handled: Boolean` parameter that lets you suppress default behavior entirely.

Note: the `CommunicationEvents` codeunit's events are marked `InternalEvent` (not `IntegrationEvent`), meaning they are only subscribable from within the app itself. They exist for test isolation, not for extension.

## Customize order creation

The order processing flow in `ShpfyProcessOrder.Codeunit.al` and `ShpfyOrderMapping.Codeunit.al` fires events at every major step.

**Sales header creation** -- `OnBeforeCreateSalesHeader` gives you the Shopify Order Header and lets you set `IsHandled` to completely replace header creation logic. `OnAfterCreateSalesHeader` fires after the header is inserted and validated, giving you the Sales Header to modify.

**Sales line creation** -- `OnBeforeCreateSalesLine` and `OnAfterCreateSalesLine` in `ShpfyProcessOrder.Codeunit.al` let you intercept line creation. This is where you would add custom line types, modify quantities, or insert additional lines.

**Customer mapping override** -- `OnBeforeMapCustomer` on `ShpfyOrderEvents.Codeunit.al` fires before the customer mapping strategy runs. Set `Handled := true` and populate `"Sell-to Customer No."` on the Order Header to bypass the standard mapping entirely. `OnAfterMapCustomer` lets you adjust the result.

**Shipment/payment method mapping** -- `OnBeforeMapShipmentMethod`, `OnBeforeMapShipmentAgent`, and `OnBeforeMapPaymentMethod` each allow you to override the standard mapping with `Handled := true`. The corresponding `OnAfter` events let you adjust the mapped values.

**Post-processing** -- `OnAfterProcessSalesDocument` fires after the complete sales document is created and optionally released, giving you both the Sales Header and the Shopify Order Header.

## Customize product mapping

Product events live in `ShpfyProductEvents.Codeunit.al` and cover both import and export directions.

**Item creation from Shopify** -- `OnAfterCreateItem` fires after a new BC Item is created from an imported Shopify product/variant. You receive the Shop, Product, Variant, and the new Item record. Use this to set additional fields (dimensions, posting groups, etc.) that the template does not cover. `OnAfterCreateItemVariant` is the equivalent for variant-to-item-variant creation.

**Template selection** -- `OnAfterFindItemTemplate` lets you override which BC Item Template is used for a specific Shopify product. This is how you implement per-product-type or per-vendor template selection.

**Product body HTML** -- `OnBeforeCreateProductBodyHtml` (with `IsHandled`) and `OnAfterCreateProductBodyHtml` let you customize the HTML description sent to Shopify during export. The `IsHandled` pattern lets you replace the standard extended-text + marketing-text + attributes assembly entirely.

**Tags** -- `OnAfterGetCommaSeparatedTags` on the Product Events codeunit lets you modify the tag string before it is sent to Shopify.

**Price calculation** -- Events in `ShpfyProductPriceCalc.Codeunit.al` let you override how prices and compare-at prices are calculated during export.

**Product status on creation** -- The `"Status for Created Products"` enum uses the `ICreateProductStatusValue` interface. Built-in values are Active and Draft. Extend the enum and implement the interface to add new initial statuses.

**Action for removed products** -- The `"Action for Removed Products"` enum uses `IRemoveProductAction`. Extend to control what happens to the Shopify product when the linked BC item is blocked or the product is deleted locally.

## Customize customer and company mapping

**Customer mapping strategies** -- The `"Customer Mapping Type"` enum dispatches through `ICustomerMapping`. Built-in implementations:

- `ShpfyCustByEmailPhone.Codeunit.al` -- matches by email, then phone
- `ShpfyCustByBillto.Codeunit.al` -- matches by bill-to address
- `ShpfyCustByDefaultCust.Codeunit.al` -- always returns the Shop's default customer

To add a new mapping strategy, extend the `"Shpfy Customer Mapping"` enum and implement `ICustomerMapping` with its two `DoMapping` overloads.

**Company mapping strategies** -- The `"Company Mapping Type"` enum dispatches through `ICompanyMapping`. Built-in implementations match by email/phone, by tax ID, or by default company.

**Customer name formatting** -- The `"Name Source"` and `"Name 2 Source"` enums use `ICustomerName` to control how the BC customer name is derived from Shopify data (CompanyName, FirstAndLastName, LastAndFirstName, None).

**County resolution** -- The `"County Source"` enum uses `ICounty` to control whether the county field comes from the province code or name. `ICountyFromJson` handles the JSON-to-county mapping direction.

**Customer events** -- `ShpfyCustomerEvents.Codeunit.al` provides `OnBeforeCreateCustomer`, `OnAfterCreateCustomer`, `OnBeforeUpdateCustomer`, and `OnAfterUpdateCustomer` events for intercepting customer sync in both directions.

## Customize stock calculation

Stock calculation is driven by two interfaces:

**`IStockAvailable`** -- A simple boolean check: can this type of item have stock? The `"Inventory Management"` enum on Shop Location uses this. Implementations include `ShpfyCanHaveStock.Codeunit.al` (returns true) and `ShpfyCanNotHaveStock.Codeunit.al` (returns false).

**`IStockCalculation`** (aka `"Shpfy Stock Calculation"`) -- Computes the actual stock quantity for an Item. The Shop Location's `"Stock Calculation"` enum selects the implementation. Built-in options:

- `ShpfyBalanceToday.Codeunit.al` -- projected available balance
- `ShpfyFreeInventory.Codeunit.al` -- inventory minus reserved
- `ShpfyDisabledValue.Codeunit.al` -- always returns 0

To add a new calculation, extend the `"Shpfy Stock Calculation"` enum and implement the `"Shpfy Stock Calculation"` interface. Your `GetStock()` receives an Item record (already filtered to the relevant location) and returns a decimal.

**`IExtendedStockCalculation`** -- An extended version of the stock calculation interface that receives additional context. If your implementation also implements this interface, the connector will call it instead.

**Inventory events** -- `ShpfyInventoryEvents.Codeunit.al` provides events for intercepting the stock sync flow.

## Customize return and refund processing

The `"Return and Refund Process"` enum dispatches through `IReturnRefundProcess`. The interface has three methods:

- `IsImportNeededFor()` -- should the connector import data for this source document type?
- `CanCreateSalesDocumentFor()` -- can a BC document be created from this source?
- `CreateSalesDocument()` -- create the BC Sales Credit Memo or Return Order

The `IDocumentSource` interface controls which Shopify document (return or refund) provides the line items. The `IExtendedDocumentSource` interface extends this with additional context.

**Refund processing events** -- `ShpfyRefundProcessEvents.Codeunit.al` provides events around credit memo creation for customizing the generated document.

## Customize metafields

Metafields are extensible through two interfaces:

**`IMetafieldType`** -- Validates and provides examples for metafield value types. There are 25+ built-in implementations covering boolean, date, dimension, money, URL, references, etc. To support a new Shopify metafield type, extend the `"Shpfy Metafield Type"` enum and implement this interface.

**`IMetafieldOwnerType`** -- Maps owner types to table IDs and resolves shop codes. Built-in owners are Product, ProductVariant, Customer, and Company. This rarely needs extension since Shopify's owner types are fixed.

## Bulk operations

The `IBulkOperation` interface supports async bulk mutations. Implementations provide the GraphQL mutation template, the JSONL input, and revert logic for failed operations. Built-in implementations handle bulk price updates (`ShpfyBulkUpdateProductPrice.Codeunit.al`) and bulk image updates (`ShpfyBulkUpdateProductImage.Codeunit.al`).

To add a new bulk operation, extend the `"Shpfy Bulk Operation Type"` enum and implement `IBulkOperation`. Your implementation must handle the revert case because bulk operations are async -- the connector cannot roll back within the same transaction.
