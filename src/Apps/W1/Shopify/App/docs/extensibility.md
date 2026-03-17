# Extensibility

The Shopify Connector offers two primary extension mechanisms: integration events (subscribe to inject behavior at specific points) and interface-based strategy selection (implement an interface, add an enum value, and the connector dispatches to your code). Most events are declared as `InternalEvent` or `IntegrationEvent` on dedicated event codeunits per domain.

## Customize product export

The product export pipeline in `ShpfyProductExport.Codeunit.al` fires events at several points:

- **Filter which products sync**: Subscribe to `OnAfterProductsToSynchronizeFiltersSet` on `ShpfyProductEvents.Codeunit.al` to add filters to the `Shpfy Product` record before the export loop starts. This is the right place to exclude certain products from sync.

- **Override product title**: `OnBeforSetProductTitle` (note the typo -- it is in the codebase) on `ShpfyProductEvents` fires before the title is assigned. Set `IsHandled` to true and modify `Title` to fully replace the title logic. `OnAfterSetProductTitle` fires after the default logic for post-processing.

- **Override product body HTML**: `OnBeforeCreateProductBodyHtml` on `ShpfyProductEvents` lets you replace the entire HTML generation (extended text + marketing text + attributes). `OnAfterCreateProductbodyHtml` lets you modify the result.

- **Modify product fields after population**: `OnAfterFillInShopifyProductFields` on `ShpfyProductEvents` fires after all standard fields are set, giving you a last chance to modify the temp `Shpfy Product` record before comparison and API call.

- **Modify variant fields**: `OnAfterCreateTempShopifyVariant` fires after variant data is populated from the BC Item.

- **Modify tags**: `OnAfterCreateTempShopifyProduct` passes the temp product, variant, and tag records, letting you add or remove tags before export.

### Control product status on creation

The `Status for Created Products` setting on the Shop selects an `ICreateProductStatusValue` implementation via the `Shpfy Cr. Prod. Status Value` enum. To add a custom status rule, add a new enum value with an `Implementation` attribute pointing to your codeunit that implements `ICreateProductStatusValue.GetStatus(Item): Enum "Shpfy Product Status"`.

### Control what happens to removed products

The `Action for Removed Products` setting uses the `IRemoveProductAction` interface. Add a new enum value to `Shpfy Remove Product Action` with your implementation of `IRemoveProductAction.RemoveProductAction(var Product)`.

## Customize order import and creation

Order events are centralized in `ShpfyOrderEvents.Codeunit.al`:

- **Override customer mapping on order**: `OnBeforeMapCustomer` with the `Handled` pattern. Set `Handled := true` and populate `Bill-to Customer No.`/`Sell-to Customer No.` directly on the `ShopifyOrderHeader` record to bypass the standard mapping logic entirely.

- **Post-process customer mapping**: `OnAfterMapCustomer` fires after the standard mapping completes, letting you adjust the result.

- **Override shipment method/agent/payment method mapping**: Each has a Before/After pair: `OnBeforeMapShipmentMethod`/`OnAfterMapShipmentMethod`, `OnBeforeMapShipmentAgent`/`OnAfterMapShipmentAgent`, `OnBeforeMapPaymentMethod`/`OnAfterMapPaymentMethod`. The Before events support the `Handled` pattern.

- **React to completed import**: `OnAfterImportShopifyOrderHeader` fires after the header is populated from JSON. `OnAfterCreateShopifyOrderAndLines` fires after both header and lines are fully imported and refund adjustments are applied. The `IsNew` boolean parameter distinguishes first import from re-import.

- **Adjust refund handling**: `OnAfterConsiderRefundsInQuantityAndAmounts` on `ShpfyOrderEvents` fires after each order line's quantity is adjusted for refunds, passing the order header, order line, and refund line records.

### Control return/refund processing

The `Return and Refund Process` setting on the Shop selects an `IReturnRefundProcess` implementation. The interface has three methods: `IsImportNeededFor`, `CanCreateSalesDocumentFor`, and `CreateSalesDocument`. To add a custom processing strategy, extend the `Shpfy ReturnRefund ProcessType` enum with your implementation.

The interface also uses two companion interfaces for document source resolution: `IDocumentSource` and `Shpfy Extended IDocumentSource`, found in `src/Order Return Refund Processing/Interfaces/`.

## Customize customer mapping

The `Customer Mapping Type` setting on the Shop selects an `ICustomerMapping` implementation. The built-in options are:

- **By EMail/Phone** (`ShpfyCustByEmailPhone.Codeunit.al`) -- searches by email, then by digits-only phone match
- **By Bill-to Info** (`ShpfyCustByBillto.Codeunit.al`) -- matches by bill-to address fields
- **Default Customer** (`ShpfyCustByDefaultCust.Codeunit.al`) -- always returns the shop's default customer

To add a custom mapping strategy, extend the `Shpfy Customer Mapping` enum with your codeunit implementing `ICustomerMapping.DoMapping`.

The related `ICustomerName` interface (selected by the Shop's `Name Source` enum) controls how the customer's display name is constructed from Shopify's first/last name and company fields. Implementations include `ShpfyNameisCompanyName`, `ShpfyNameisFirstLastName`, `ShpfyNameisLastFirstName`, and `ShpfyNameisEmpty`.

The `ICounty` and `ICountyFromJson` interfaces control how the county/province field is resolved from Shopify's address data (by code vs. by name, from JSON code vs. JSON name). The `County Source` shop setting selects the implementation.

Customer import/export events live in `ShpfyCustomerEvents.Codeunit.al`, with `OnBeforeFindMapping`/`OnAfterFindMapping` for intercepting the mapping process.

## Customize company mapping (B2B)

The `Company Mapping` setting on the Shop uses the `ICompanyMapping` and `IFindCompanyMapping` interfaces in `src/Companies/Interfaces/`. Built-in strategies include mapping by email/phone (`ShpfyCompByEmailPhone`), by tax ID (`ShpfyCompByTaxId`), and by default company (`ShpfyCompByDefaultComp`).

## Customize inventory calculation

The stock calculation interfaces form a hierarchy:

1. `Shpfy IStock Available` -- boolean guard: can this calculation type produce stock?
2. `Shpfy Stock Calculation` -- basic `GetStock(Item): Decimal`
3. `Shpfy Extended Stock Calculation` -- location-aware `GetStock(Item, ShopLocation): Decimal`

To add a custom stock calculation, extend the stock calculation enum with your codeunit implementing the appropriate interface level. If your calculation is location-dependent, implement `Shpfy Extended Stock Calculation`.

## Override GraphQL queries

The 143 GraphQL queries are dispatched through the `IGraphQL` interface on the `ShpfyGraphQLType` enum. The `ShpfyGraphQLQueries.Codeunit.al` dispatcher fires several events:

- `OnBeforeSetInterfaceCodeunit` -- replace which codeunit implements a given query type
- `OnBeforeGetGrapQLInfo` / `OnAfterGetGrapQLInfo` -- replace or modify the query text and expected cost
- `OnBeforeReplaceParameters` / `OnAfterReplaceParameters` -- modify parameter substitution

Since the enum is marked `Extensible = true`, you can also add entirely new GraphQL query types by adding enum values with your `IGraphQL` implementation.

## Document link dispatch

The `Shpfy Doc. Link To Doc.` table uses `IOpenShopifyDocument` and `IOpenBCDocument` interfaces for polymorphic document opening. When you add a new Shopify document type or BC document type enum value, provide implementations of these interfaces so the document link page can navigate to your documents.

## General patterns for extension

- **IsHandled pattern**: Most Before events pass a `var Handled: Boolean` parameter. Set it to `true` to skip the default logic. Do not set it to `true` unless you fully replace the behavior -- partial handling will leave the record in an inconsistent state.

- **Enum-implements-interface pattern**: Configuration enums on the Shop table have `implements` clauses. Extending the enum automatically makes your strategy available in the UI dropdown. The Shop table does not need modification.

- **InternalEvent vs IntegrationEvent**: Events marked `InternalEvent` are only subscribable from within the same app (the Shopify Connector itself and its test app via `internalsVisibleTo`). Events marked `IntegrationEvent` are subscribable from any extension app. Check the attribute before planning your extension.
