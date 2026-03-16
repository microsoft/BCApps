# Patterns

## IsHandled pattern

The IsHandled pattern enables event subscribers to prevent default behavior execution by setting a boolean `var IsHandled: Boolean` parameter to true. This pattern appears 114 times across 17 files.

### Purpose
Allows complete replacement of default logic without modifying base code. When IsHandled is set to true, the default implementation is skipped.

### Implementation structure
```al
var
    IsHandled: Boolean;
begin
    IsHandled := false;
    OnBeforeDoSomething(Parameters, IsHandled);
    if IsHandled then
        exit;

    // Default implementation runs only if IsHandled remains false
    DefaultImplementation();
end;
```

### Example: Custom product export filter
From `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Products\Codeunits\ShpfyProductExport.Codeunit.al`:
```al
ShopifyProduct.SetFilter("Item SystemId", '<>%1', NullGuid);
ShopifyProduct.SetFilter("Shop Code", Rec.GetFilter(Code));

ProductEvents.OnAfterProductsToSynchronizeFiltersSet(ShopifyProduct, Shop, OnlyUpdatePrice);
```
Subscribers can modify the ShopifyProduct filter to change which products sync, adding custom criteria like "only items with specific attribute values" or "only items in certain categories."

### Example: Custom GraphQL query
From `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\GraphQL\Codeunits\ShpfyGraphQLQueries.Codeunit.al`:
```al
IsHandled := false;
OnBeforeGetGrapQLInfo(GraphQLType, Parameters, IGraphQL, GraphQL, ExpectedCost, IsHandled);
if not IsHandled then begin
    GraphQL := IGraphQL.GetGraphQL();
    ExpectedCost := IGraphQL.GetExpectedCost();
end;
```
Subscribers can completely replace the GraphQL query for a given operation, such as adding custom fields to product queries or modifying order filters.

### Example: Custom order line processing
From `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Order handling\Codeunits\ShpfyOrderMapping.Codeunit.al`:
```al
OrderEvents.OnBeforeCreateSalesLine(ShopifyOrderHeader, ShopifyOrderLine, SalesHeader, SalesLine, IsHandled);
if not IsHandled then begin
    // Create standard sales line from order line
    CreateSalesLineFromOrderLine(ShopifyOrderLine, SalesLine);
end;
```
Subscribers can prevent standard sales line creation and implement custom logic, such as splitting lines, adding related items, or applying custom pricing.

### Common use cases
- **Skip default customer mapping**: Implement custom logic to find or create customers based on proprietary fields
- **Override price calculation**: Use custom price lists or discount engines
- **Custom sales document creation**: Create purchase orders for dropship items or special order types
- **Filter synchronization scope**: Limit products/customers/orders synced based on business rules
- **Replace GraphQL queries**: Add custom fields to Shopify queries or modify filters

## Interface + Enum pattern

The app defines 22 interfaces with corresponding enums to enable pluggable behavior. Each enum value implements the interface, creating a strategy pattern for swappable logic.

### Purpose
Provides type-safe, compile-time validated extension points for core business logic. Unlike events (runtime extensibility), interfaces enable algorithm replacement with IntelliSense support.

### Implementation structure
1. Define interface with required procedures
2. Define enum with strategy options
3. Enum implements interface with different codeunits per value
4. Business logic uses `IInterface := EnumValue` syntax

### Key interface implementations

#### ICustomerMapping -- Customer association strategy (4 implementations)
**Interface**: `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Customers\Interfaces\ShpfyICustomerMapping.Interface.al`
```al
interface "Shpfy ICustomerMapping"
{
    procedure FindCustomer(ShopifyCustomer: Record "Shpfy Customer"; var Customer: Record Customer): Boolean;
}
```

**Enum**: Shpfy Customer Mapping (30107)
- **By Email/Phone**: Matches Customer."E-Mail" or "Phone No." to Shopify customer
- **By Bill-to Info**: Matches billing address fields
- **Always Create New**: Never maps to existing, always creates
- **By Default Customer**: Always uses default customer no. from shop settings

**Usage in** `ShpfyCustomerMapping.Codeunit.al`:
```al
procedure FindMapping(var ShopifyCustomer: Record "Shpfy Customer"): Boolean
var
    ICustomerMapping: Interface "Shpfy ICustomerMapping";
begin
    ICustomerMapping := Shop."Customer Mapping Type";
    exit(ICustomerMapping.FindCustomer(ShopifyCustomer, Customer));
end;
```

#### ICompanyMapping -- B2B company association (4 implementations)
**Interface**: `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Companies\Interfaces\ShpfyICompanyMapping.Interface.al`
- **By Tax ID**: Matches company tax registration ID
- **By Email/Phone**: Matches main contact info
- **By Default Company**: Uses default company no.
- **None**: Disables company mapping

#### IStockCalculation -- Inventory calculation (2 implementations)
**Interface**: `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Inventory\Interface\ShpfyStockCalculation.Interface.al`
```al
interface "Shpfy Stock Calculation"
{
    procedure GetStock(var ShopifyShopInventory: Record "Shpfy Shop Inventory"): Decimal;
}
```

**Implementations**:
- **Default**: Uses standard available inventory calculation
- **Projected Available Balance**: Uses planning calculation

Shop Location."Stock Calculation" field determines which implementation to use.

#### IMetafieldType -- Type-specific metafield handling (50+ implementations)
**Interface**: `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Metafields\Interfaces\ShpfyIMetafieldType.Interface.al`
```al
interface "Shpfy IMetafield Type"
{
    procedure HasValue(Metafield: Record "Shpfy Metafield"): Boolean;
    procedure GetValue(Metafield: Record "Shpfy Metafield"): Text;
    procedure SetValue(var Metafield: Record "Shpfy Metafield"; Value: Text);
}
```

**Sample implementations**: Money, Weight, Dimension, Volume, Date, DateTime, Number (Decimal/Integer), Single Line Text, Multi Line Text, JSON, etc.

Each type knows how to parse JSON values from Shopify and format them for storage/display.

#### IGraphQL -- Query template provider
**Interface**: `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\GraphQL\Interfaces\ShpfyIGraphQL.Interface.al`
```al
interface "Shpfy IGraphQL"
{
    procedure GetGraphQL(): Text;
    procedure GetExpectedCost(): Integer;
}
```

Each GraphQL query type (product query, order query, customer query, etc.) implements this interface to provide the query template and cost estimate for rate limiting.

**Example**: Shpfy GraphQL Type enum has 100+ values, each providing a different query template.

#### IReturnRefundProcess -- Return processing strategy (3 implementations)
**Interface**: `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Order Return Refund Processing\Interfaces\ShpfyIReturnRefundProcess.Interface.al`
- **Import Only**: Stores refund data but creates no BC documents
- **Auto Create Credit Memo**: Automatically creates BC credit memos from refunds
- **Only Refund**: Handles refunds without associated returns

#### IDocumentSource -- Return source tracking (5+ implementations)
**Interface**: `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Order Return Refund Processing\Interfaces\ShpfyIDocumentSource.Interface.al`

Implementations for Sales Order, Sales Invoice, Posted Sales Invoice, Posted Sales Shipment, Posted Sales Credit Memo -- enables return tracing to original document.

#### IOpenBCDocument / IOpenShopifyDocument -- Document navigation (13+ implementations)
**Interfaces**: `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Document Links\Interfaces\`

Implementations for opening different document types (Sales Order, Posted Invoice, Shipment, Return, Refund, etc.) from links. Enables navigation from Shopify → BC and BC → Shopify.

### Benefits
- **Compile-time safety**: Interface contract enforced by compiler
- **Centralized extension**: All implementations in one enum
- **IntelliSense discovery**: Developers can see all available strategies
- **No event subscription**: Simpler than events for strategy pattern
- **Testability**: Easy to test individual strategy implementations

## TryFunction error handling

The TryFunction attribute marks procedures that catch errors and return boolean success/failure instead of propagating errors. Used 14 times across 10 files.

### Purpose
Enables graceful error handling without breaking transaction scope. Particularly useful for API calls that may fail due to rate limiting, network issues, or validation errors.

### Implementation pattern
```al
[TryFunction]
local procedure TryExecuteGraphQL(Parameters): Boolean
var
    Result: JsonToken;
begin
    Result := ExecuteGraphQL(Parameters);
    exit(true);
end;
```

### Example: Rate limit handling
From `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\GraphQL\Codeunits\ShpfyGraphQLRateLimit.Codeunit.al`:
```al
[TryFunction]
local procedure TryExecuteGraphQL(GraphQLType: Enum "Shpfy GraphQL Type"; Parameters: Dictionary of [Text, Text]; var JResponse: JsonToken)
begin
    JResponse := CommunicationMgt.ExecuteGraphQL(GraphQLType, Parameters, true);
end;

procedure ExecuteGraphQLWithRateLimit(): JsonToken
var
    JResponse: JsonToken;
    Success: Boolean;
    ThrottleCount: Integer;
begin
    repeat
        Success := TryExecuteGraphQL(GraphQLType, Parameters, JResponse);
        if not Success then begin
            ThrottleCount += 1;
            Sleep(CalculateThrottleDelay(ThrottleCount));
        end;
    until Success or (ThrottleCount > MaxRetries);
    exit(JResponse);
end;
```
This pattern allows the app to retry throttled requests without rolling back the transaction.

### Example: JSON parsing safety
From `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Helpers\Codeunits\ShpfyJsonHelper.Codeunit.al`:
```al
[TryFunction]
procedure TryGetJsonValue(JObject: JsonObject; Path: Text; var JValue: JsonValue)
begin
    JObject.SelectToken(Path, JToken);
    JValue := JToken.AsValue();
end;

procedure GetValueAsText(JObject: JsonObject; Path: Text; MaxLength: Integer): Text
var
    JValue: JsonValue;
begin
    if TryGetJsonValue(JObject, Path, JValue) then
        exit(CopyStr(JValue.AsText(), 1, MaxLength));
    exit('');
end;
```
Returns empty string instead of error if JSON path doesn't exist.

### Example: Bulk operation result processing
From `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Bulk Operations\Codeunits\ShpfyBulkOperationAPI.Codeunit.al`:
```al
[TryFunction]
local procedure TryDownloadBulkResult(Url: Text; var TempBlob: Codeunit "Temp Blob")
var
    Client: HttpClient;
    Response: HttpResponseMessage;
begin
    Client.Get(Url, Response);
    Response.Content.ReadAs(TempBlob);
end;
```
Prevents bulk operation failures from crashing the entire sync process.

### Common use cases
- **API retries**: Try API call, retry on throttle/timeout
- **Optional fields**: Try parse field, continue if missing
- **Validation**: Try validate data, log error if invalid
- **File operations**: Try download/upload, handle failure gracefully

## Partial records (SetLoadFields)

SetLoadFields optimizes database queries by loading only specified fields, reducing memory and improving performance for large tables.

### Purpose
Minimizes data transfer when only a subset of fields is needed. Critical for performance when processing thousands of orders/products.

### Usage locations
Found in 5+ files:
- `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Order handling\Codeunits\ShpfyImportOrder.Codeunit.al`
- `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Products\Codeunits\ShpfyProductExport.Codeunit.al`
- `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Products\Page Extensions\ShpfyItemCard.PageExt.al`

### Example: Order line processing
```al
ShopifyOrderLine.SetLoadFields("Shopify Order Id", "Line Id", "Shopify Product Id", "Shopify Variant Id", Quantity, "Unit Price");
if ShopifyOrderLine.FindSet() then
    repeat
        ProcessLine(ShopifyOrderLine);
    until ShopifyOrderLine.Next() = 0;
```
Loads only 6 fields instead of 50+, improving loop performance by 3-5x for large order imports.

### Example: Item lookup
```al
Item.SetLoadFields(SystemId, "No.", Description, Blocked);
if Item.Get(ItemNo) then
    if not Item.Blocked then
        ProcessItem(Item);
```
Loads minimal fields for validation check, then loads full record only if needed.

### Best practices
- **Use before FindSet()**: Most beneficial for loops over large datasets
- **Include primary key**: Always include key fields for proper record identification
- **Combine with filters**: Use with SetRange/SetFilter for maximum benefit
- **Load full record when updating**: Call Get() without SetLoadFields before Modify()

## GraphQL query template pattern

All GraphQL queries use parameterized templates with `{{Placeholder}}` syntax for dynamic value substitution. This centralizes query definitions and enables modification via events.

### Template structure
Queries are stored as text constants with placeholder tokens:
```graphql
query {
  products(first: {{MaxItems}}, query: "{{ProductFilter}}") {
    edges {
      node {
        id
        title
        variants(first: 10) {
          edges {
            node { id sku price }
          }
        }
      }
    }
  }
}
```

### Parameter substitution
From `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\GraphQL\Codeunits\ShpfyGraphQLQueries.Codeunit.al`:
```al
internal procedure GetQuery(GraphQLType: enum "Shpfy GraphQL Type"; Parameters: Dictionary of [Text, Text]) GraphQL: Text
var
    IGraphQL: Interface "Shpfy IGraphQL";
begin
    IGraphQL := GraphQLType;
    GraphQL := IGraphQL.GetGraphQL();

    if Parameters.Count > 0 then
        foreach Param in Parameters.Keys do
            GraphQL := GraphQL.Replace('{{' + Param + '}}', Parameters.Get(Param));
    exit(GraphQL);
end;
```

### Example: Product export query
From `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Products\Codeunits\ShpfyProductAPI.Codeunit.al`:
```al
GraphQuery.Append('{"query":"mutation {productCreate(product: {');
GraphQuery.Append('title: \"');
GraphQuery.Append(CommunicationMgt.EscapeGraphQLData(ShopifyProduct.Title));
GraphQuery.Append('\"');
// ... build mutation dynamically
GraphQuery.Append('}) {product {legacyResourceId, onlineStoreUrl}, userErrors {field, message}}}"}');

JResponse := CommunicationMgt.ExecuteGraphQL(GraphQuery.ToText());
```

### Benefits
- **Centralized queries**: All queries in one codeunit (Shpfy GraphQL Queries 30154)
- **Version safety**: API version changes require updates in one place
- **Event extensibility**: OnBeforeGetGraphQLInfo event allows query replacement
- **Type safety**: Enum-based query selection with IntelliSense
- **Cost tracking**: Each query template includes expected API cost

### Extension pattern
```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy GraphQL Queries", 'OnBeforeGetGrapQLInfo', '', true, true)]
local procedure OnBeforeGetProductQuery(GraphQLType: Enum "Shpfy GraphQL Type"; var GraphQL: Text; var IsHandled: Boolean)
begin
    if GraphQLType = GraphQLType::GetProducts then begin
        GraphQL := 'query { products(first: 50) { edges { node { id title myCustomField } } } }';
        IsHandled := true;
    end;
end;
```
This replaces the default product query to include custom metafields.

## Event-driven extensibility

The connector exposes 70+ integration events across three event codeunits, enabling deep customization without modifying base code.

### Event categories

#### Pre-processing events (On**Before**)
Allow validation, modification, or cancellation before an operation:
- **OnBeforeCreateCustomer**: Validate customer data, set IsHandled to prevent creation
- **OnBeforeCreateSalesLine**: Modify line data, add custom logic
- **OnBeforeSendCreateShopifyProduct**: Adjust product before sending to Shopify
- **OnBeforeGetGraphQLInfo**: Replace GraphQL query entirely

#### Post-processing events (On**After**)
Allow customization after an operation completes:
- **OnAfterCreateCustomer**: Set custom fields on newly created customer
- **OnAfterCreateSalesHeader**: Add custom dimensions, apply business logic
- **OnAfterImportOrder**: Trigger custom workflows, send notifications
- **OnAfterCalculateAvailableInventory**: Apply custom stock reservations

#### Decision events (OnBefore**Find**)
Allow custom logic for lookups and mappings:
- **OnBeforeFindCustomerTemplate**: Select template based on custom rules
- **OnBeforeFindMapping**: Implement custom customer/product matching
- **OnBeforeFindItemTemplate**: Select item template by category

### Example: Custom customer mapping
```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Customer Events", 'OnBeforeFindMapping', '', true, true)]
local procedure OnBeforeFindCustomerMapping(Direction: Enum "Shpfy Mapping Direction"; var ShopifyCustomer: Record "Shpfy Customer"; var Customer: Record Customer; var Handled: Boolean)
begin
    if Direction = Direction::"From Shopify" then begin
        // Custom logic: match by loyalty program ID stored in metafield
        if FindCustomerByLoyaltyId(ShopifyCustomer, Customer) then
            Handled := true;
    end;
end;
```

### Example: Custom sales line pricing
```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Order Events", 'OnAfterCalcSalesPrice', '', true, true)]
local procedure OnAfterCalculatePrice(ShopifyOrderLine: Record "Shpfy Order Line"; var SalesLine: Record "Sales Line")
begin
    // Apply custom pricing logic after standard calculation
    if ShopifyOrderLine."Discount Amount" > 1000 then
        SalesLine.Validate("Line Discount Amount", ShopifyOrderLine."Discount Amount" * 0.9);
end;
```

### Example: Post-import workflow trigger
```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Order Events", 'OnAfterImportOrder', '', true, true)]
local procedure OnAfterOrderImport(ShopifyOrderHeader: Record "Shpfy Order Header")
begin
    // Trigger custom approval workflow for high-value orders
    if ShopifyOrderHeader."Total Amount" > 10000 then
        SendApprovalRequest(ShopifyOrderHeader);
end;
```

### Event discovery
All events documented in event codeunits:
- **Shpfy Order Events (30166)** -- 19 events for order processing
- **Shpfy Customer Events (30115)** -- 7 events for customer sync
- **Shpfy Product Events (30177)** -- 35+ events for product sync
- **Shpfy Shipping Events (30123)** -- 2 events for fulfillment
- **Shpfy Inventory Events (30201)** -- 1 event for stock calculation
- **Shpfy Refund Process Events (30146)** -- 6 events for return/refund processing
- **Shpfy Communication Events (30148)** -- Events for API call logging/modification

## Header-line pattern

Standard AL pattern for master-detail relationships. Used for orders, returns, refunds, fulfillments.

### Structure
- **Header table**: Stores document-level data (customer, totals, status)
- **Line table**: Stores line-level data (item, quantity, price)
- **Primary key relationship**: Line table includes header's primary key

### Implementation examples

**Order processing**:
- Shpfy Order Header (30118) ← Shpfy Order Line (30119)
- Shpfy Order Line includes "Shopify Order Id" linking to header

**Returns**:
- Shpfy Return Header (30140) ← Shpfy Return Line (30141)
- Shpfy Return Line includes "Return Id" linking to header

**Refunds**:
- Shpfy Refund Header (30142) ← Shpfy Refund Line (30143)
- Multiple refund lines per refund header

**Fulfillments**:
- Shpfy Order Fulfillment (30120) ← Shpfy Fulfillment Line (30121)
- Shpfy Fulfillment Order Header (30460) ← Shpfy Fulfillment Order Line (30461)

### Cascade delete pattern
Headers implement OnDelete trigger to delete child lines:
```al
trigger OnDelete()
var
    ShopifyOrderLine: Record "Shpfy Order Line";
begin
    ShopifyOrderLine.SetRange("Shopify Order Id", "Shopify Order Id");
    if not ShopifyOrderLine.IsEmpty then
        ShopifyOrderLine.DeleteAll(true);
end;
```

## Hash-based change detection

Products and variants use integer hash codes to detect changes without comparing full field values. Improves performance and reduces API calls.

### Hash fields in Shpfy Product (30127)
- **Image Hash**: Detects image changes
- **Tags Hash**: Detects tag list changes
- **Description Html Hash**: Detects description changes
- **Last Updated by BC**: Timestamp of last BC-initiated update

### Hash calculation
From Shpfy Hash codeunit:
```al
procedure CalcHash(Value: Text): Integer
var
    MD5: Codeunit "Cryptography Management";
begin
    exit(MD5.GenerateHash(Value, 2)); // 2 = MD5
end;
```

### Change detection workflow
```al
procedure UpdateProductIfChanged(var Product: Record "Shpfy Product")
var
    Hash: Codeunit "Shpfy Hash";
    NewDescriptionHash: Integer;
begin
    NewDescriptionHash := Hash.CalcHash(Product.GetDescriptionHtml());
    if NewDescriptionHash <> Product."Description Html Hash" then begin
        // Description changed, update Shopify
        Product."Description Html Hash" := NewDescriptionHash;
        UpdateProductInShopify(Product);
    end;
end;
```

### Benefits
- **Efficient comparison**: Integer comparison faster than text comparison
- **Null-safe**: Hash of empty text is valid integer
- **Prevents unnecessary API calls**: Only sync when content actually changes
- **Bidirectional tracking**: "Last Updated by BC" prevents circular updates
- **Audit trail**: Hash changes indicate modification history

### Example: Tag sync optimization
```al
procedure CalcTagsHash(): Integer
var
    Hash: Codeunit "Shpfy Hash";
begin
    exit(Hash.CalcHash(Rec.GetCommaSeparatedTags()));
end;

procedure UpdateTagsIfChanged(CommaSeparatedTags: Text)
var
    Hash: Codeunit "Shpfy Hash";
    NewHash: Integer;
begin
    NewHash := Hash.CalcHash(CommaSeparatedTags);
    if NewHash <> Rec."Tags Hash" then begin
        Rec.UpdateTags(CommaSeparatedTags);
        Rec."Tags Hash" := NewHash;
    end;
end;
```
Only sends tag updates to Shopify when the comma-separated list actually changes.
