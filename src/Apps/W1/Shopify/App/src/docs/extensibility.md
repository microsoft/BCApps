# Extensibility

The Shopify Connector exposes integration events, extensible enums with interface implementations, and subscribable internal events. The primary extension surface is through events in `Shpfy Order Events` (30162), `Shpfy Product Events`, `Shpfy Inventory Events`, and the various mapping interfaces.

## Customize product mapping and pricing

To control how BC items map to Shopify products, subscribe to the product export events. The product export raises events before and after creating or updating each product, giving you access to both the BC Item and the Shopify product data. For custom pricing logic, you can subscribe to the price calculation events or -- for B2B -- configure catalog-level `Customer Price Group` and `Customer Discount Group` overrides on individual `Shpfy Catalog` records.

For SKU mapping, the `SKU Mapping` enum on the Shop is extensible. Built-in options include Item No., Variant Code, Item No. + Variant Code, and Barcode. You can add custom SKU strategies by extending the enum and implementing the mapping.

## Customize order creation

Order processing in `Shpfy Process Order` fires a rich set of events at every stage.

- **OnBeforeCreateSalesHeader / OnAfterCreateSalesHeader** -- Control document type (order vs. invoice), set custom fields, change the customer. The `IsHandled` pattern on `OnBeforeCreateSalesHeader` lets you completely take over header creation.
- **OnBeforeCreateItemSalesLine / OnAfterCreateItemSalesLine** -- Modify line quantities, change the item, add dimensions, set location codes. Again, `IsHandled` on the Before event lets you replace the standard logic.
- **OnBeforeCreateShippingCostSalesLine / OnAfterCreateShippingCostSalesLine** -- Customize how shipping charges become sales lines.
- **OnBeforeProcessSalesDocument / OnAfterProcessSalesDocument** -- Wrap the entire processing with pre/post logic.

A common extension pattern is setting dimensions on sales documents based on Shopify channel or order attributes. Subscribe to `OnAfterCreateSalesHeader`, read the order attributes from `Shpfy Order Attribute`, and set dimension values on the sales header.

## Customize customer matching

The `Customer Mapping Type` enum on the Shop table is extensible. To add a custom strategy:

1. Extend the `Shpfy Customer Mapping` enum with your new option.
2. Implement the `Shpfy ICustomer Mapping` interface on a codeunit.
3. Your `DoMapping` procedure receives the Shopify customer ID, a JSON object with address info, the shop code, template code, and an AllowCreate flag.

For example, to match customers by a custom field, extend the enum and write a codeunit that queries BC customers by that field using the data from the JSON parameter.

The `OnBeforeMapCustomer` / `OnAfterMapCustomer` events on `Shpfy Order Events` provide an alternative: you can subscribe and set the `Sell-to Customer No.` directly on the order header before or after standard mapping runs. The `Handled` parameter on `OnBeforeMapCustomer` lets you skip standard mapping entirely.

## Customize stock calculation

The `Stock Calculation` enum on `Shpfy Shop Location` is extensible. To add a custom stock method:

1. Extend the `Shpfy Stock Calculation` enum.
2. Implement the `Shpfy Stock Calculation` interface (`GetStock` procedure that receives a filtered Item record and returns a decimal).
3. Optionally implement `Shpfy IStock Available` to control whether the item is considered "in stock" at all.

Additionally, `Shpfy Inventory Events` provides events for further adjustment after the stock calculation runs, useful for applying safety stock or custom availability rules.

## Customize refund and return processing

The `Shpfy ReturnRefund ProcessType` enum is extensible. To add a custom processing strategy:

1. Extend the enum.
2. Implement the `Shpfy IReturnRefund Process` interface.
3. Your implementation controls three things: whether import is needed for a given source document type, whether a sales document can be created, and the actual document creation logic.

The `IDocumentSource` and `IExtendedDocumentSource` interfaces provide further control over which source documents are used for credit memo creation.

## Customize B2B company matching

The `Company Mapping Type` enum on the Shop is extensible, following the same pattern as customer mapping. Implement `Shpfy ICompany Mapping` with a `DoMapping` procedure that receives the Shopify company ID, shop code, template code, and AllowCreate flag.

The `OnBeforeMapCompany` / `OnAfterMapCompany` events on `Shpfy Order Events` let you override company mapping for orders without implementing a full strategy.

Tax registration ID mapping for B2B companies is handled by the `Shpfy Comp. Tax Id Mapping` interface, which is also extensible via its enum.

## Add custom GraphQL queries

To add a new GraphQL query to the connector (typically in a fork or contribution):

1. Create a new codeunit implementing `Shpfy IGraphQL`.
2. `GetGraphQL()` returns the query string with `{{placeholders}}` for dynamic values.
3. `GetExpectedCost()` returns the estimated query cost for rate limiting. This must be accurate -- underestimating causes throttling, overestimating causes unnecessary waits.
4. Add a new value to the `Shpfy GraphQL Type` enum pointing to your codeunit.
5. Call it through `CommunicationMgt.ExecuteGraphQL(GraphQLType)`.

## Common extension examples

**Show Shopify fields on sales documents** -- Use page extensions on Sales Order / Sales Invoice to show `Shpfy Order Id` and `Shpfy Order No.` fields that are added to the Sales Header table extension. Subscribe to `OnAfterCreateSalesHeader` to populate custom fields.

**Custom pricing based on Shopify data** -- Subscribe to the product export price calculation events. You can read the Shopify product/variant data (including metafields and tags) and adjust the price before it is sent to Shopify.

**Channel-based customer mapping** -- Subscribe to `OnBeforeMapCustomer`, read the `Channel Name` or `App Name` from the order header, and assign a different customer based on the sales channel (e.g. POS vs. online store vs. wholesale).

**Order-level dimensions from Shopify attributes** -- Subscribe to `OnAfterCreateSalesHeader`, iterate `Shpfy Order Attribute` records for the order, and use `DimensionManagement` to set dimensions on the sales header based on attribute values.

**Custom stock calculation with safety stock** -- Extend the `Shpfy Stock Calculation` enum, implement the interface to subtract a safety stock quantity from the standard calculation, and configure the new method on the relevant shop locations.
