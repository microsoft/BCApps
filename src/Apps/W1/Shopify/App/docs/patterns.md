# Patterns

## GraphQL encapsulation via IGraphQL

**Problem**: The connector needs 143+ distinct GraphQL queries, each with different structure, parameters, and cost budgets. Hardcoding query strings throughout the codebase would be unmaintainable and impossible to extend.

**Solution**: Each GraphQL query is a separate codeunit implementing the `Shpfy IGraphQL` interface (two methods: `GetGraphQL()` returns the query template, `GetExpectedCost()` returns the Shopify API cost budget). The `ShpfyGraphQLType` enum (30111) maps symbolic names to implementations. The dispatcher in `ShpfyGraphQLQueries.Codeunit.al` resolves the enum to an interface, calls it, then replaces `{{param}}` placeholders with values from a `Dictionary of [Text, Text]`.

**Example**: `ShpfyGQLOrderHeader.Codeunit.al` returns a GraphQL query template for fetching order headers. The caller passes `{ "OrderId": "gid://shopify/Order/12345" }` as parameters. The dispatcher substitutes `{{OrderId}}` in the query text before sending it to the API.

**Gotcha**: The dispatcher fires events at every stage (before interface resolution, before/after query retrieval, before/after parameter replacement). If you subscribe to `OnBeforeSetInterfaceCodeunit` and set `IsHandled := true` but provide a `nil` interface, you'll get a runtime error -- the dispatcher does not null-check the interface after the event.

## Enum-implements-interface strategy selection

**Problem**: Many behaviors need to be user-configurable from a dropdown: customer mapping strategy, stock calculation method, product status rules, return/refund processing, county formatting, customer name formatting, etc.

**Solution**: The enum definition includes `implements` clauses that bind each value to a codeunit. The Shop table stores the enum value. Business logic resolves the enum to its interface and calls the method. No factory codeunit, no case statement -- AL's enum-to-interface dispatch handles it.

**Example**: The `Shpfy Customer Mapping` enum has values like `"By EMail/Phone"` (implemented by `ShpfyCustByEmailPhone`), `"By Bill-to Info"` (implemented by `ShpfyCustByBillto`). In `ShpfyCustomerMapping.Codeunit.al`, the code does `IMapping := LocalShop."Customer Mapping Type"` and then `IMapping.DoMapping(...)`. Adding a new strategy means adding an enum extension value with an `Implementation` attribute -- no changes to the mapper.

**Gotcha**: The mapper has a hardcoded fallback: if both `Name` and `Name2` are empty, it ignores the Shop setting and uses `"By EMail/Phone"` directly. This overrides any custom implementation. If your mapping strategy does not depend on name fields, empty-name orders will still bypass it.

## Hash-based change detection

**Problem**: Syncing every product on every run wastes API calls. The connector needs to detect which products actually changed.

**Solution**: Integer hash fields stored on the entity record (`Image Hash`, `Tags Hash`, `Description Html Hash` on `Shpfy Product`). Before export, the connector computes the current hash and compares it to the stored value. If they match, the product is skipped.

**Example**: In `ShpfyProductExport.Codeunit.al`, `FillInProductFields` sets `ShopifyProduct."Tags Hash" := ShopifyProduct.CalcTagsHash()`. The `CalcTagsHash` method (on the Product table) hashes the concatenated tag values via the `ShpfyHash` codeunit. The same pattern is used for `Description Html Hash` and `Image Hash`.

**Gotcha**: These are non-cryptographic integer hashes. Collisions are theoretically possible. More importantly, the hash only detects changes in the specific fields it covers. If you modify a product field that is not covered by any hash (like Vendor or Product Type), the change detection will not catch it, and the product will not be re-exported unless some hashed field also changes.

## SystemId linking instead of No./Code

**Problem**: BC records can be renumbered (Item No. changed). If the connector stored Item No. as the link, renumbering would break the mapping.

**Solution**: All links from Shopify records to BC records use `SystemId` (Guid) fields. The `Item SystemId` on `Shpfy Product` and `Shpfy Variant` tables links to `Item.SystemId`. The `Customer SystemId` on `Shpfy Customer` links to `Customer.SystemId`. FlowFields like `Shpfy Product."Item No."` resolve through SystemId for display purposes.

**Example**: In `ShpfyProduct.Table.al`, field 101 `"Item SystemId"` is a Guid. Field 103 `"Item No."` is a FlowField: `CalcFormula = lookup(Item."No." where(SystemId = field("Item SystemId")))`.

**Gotcha**: The `FindMapping` method in `ShpfyCustomerMapping.Codeunit.al` checks if the BC record still exists by calling `Customer.GetBySystemId`. If the customer was deleted, it clears the SystemId and attempts to re-map. But if `GetBySystemId` fails for other reasons (permissions, filters), the link is silently cleared.

## Temp table batching

**Problem**: Processing records one-at-a-time from the API is fragile. Network errors mid-batch leave partial state. The connector needs to separate "retrieve data" from "write to database."

**Solution**: Import flows retrieve all data into temporary records first, then iterate the temp records to insert/update permanent records. This gives a commit boundary between retrieval and persistence.

**Example**: In `ShpfySyncProducts.Codeunit.al`, the import flow retrieves all product IDs into a `ProductIds: Dictionary of [BigInteger, DateTime]`, filters against local timestamps, builds a `TempProduct` temp table of products that need updating, then loops over `TempProduct` to run `ProductImport` for each. Each product import runs in its own `Commit()` scope, so one failure does not roll back previous successes.

**Gotcha**: The `Commit()` call before each `ProductImport.Run()` means that if the import fails, the product record may be in a half-updated state (header committed, lines not yet processed). The error is captured via `GetLastErrorText` but the partial state remains.

## Data capture for debugging

**Problem**: When an order import fails or produces unexpected results, you need to see the raw Shopify data that caused it.

**Solution**: The `Shpfy Data Capture` table (30114) stores raw JSON in a Blob field, linked to any record via `Linked To Table` (integer table ID) and `Linked To Id` (Guid). The `Add` method accepts a table ID, SystemId, and JSON text.

**Example**: In `ShpfyImportOrder.Codeunit.al`, after inserting each order line, the code calls `DataCapture.Add(Database::"Shpfy Order Line", OrderLine.SystemId, Format(JOrderLine))`. This stores the raw JSON for every order line, making it possible to compare what Shopify sent against what ended up in the BC tables.

**Gotcha**: Data capture stores the JSON at the time of import. If the Shopify order changes later and is re-imported, the captured data is for the latest import, not the original. There is no history -- each re-import overwrites.

## Skipped record logging

**Problem**: Users see "my product didn't sync" and file bugs. The connector needs to explain why it deliberately skipped a record.

**Solution**: The `ShpfySkippedRecord.Codeunit.al` codeunit provides `LogSkippedRecord` methods that create entries in `Shpfy Skipped Record` (30159) with the Shopify ID, BC record ID, description, and skip reason.

**Example**: In `ShpfyProductExport.Codeunit.al`, when a variant is blocked: `SkippedRecord.LogSkippedRecord(ItemVariant.RecordId, ItemVariantIsBlockedLbl, Shop)`. The user can open the Skipped Records page to see "Item variant is blocked or sales blocked."

**Gotcha**: Skipped records accumulate over time. The table has no built-in cleanup. On high-volume shops with many blocked variants, this table can grow large.

## Negative IDs for BC-created records

**Problem**: When the connector creates customer addresses in BC and exports them to Shopify, it needs to assign IDs to the address records before Shopify responds with real IDs. But Shopify IDs are positive BigIntegers.

**Solution**: BC-created addresses use negative IDs. This guarantees no collision with Shopify-assigned positive IDs. When Shopify responds with the real ID, the record can be updated.

**Example**: `Shpfy Customer Address` records created during customer export get negative `Id` values. The sign convention makes it trivial to filter for BC-created vs. Shopify-created addresses.

## Cursor-based pagination

**Problem**: Shopify's GraphQL API uses cursor-based pagination (not offset-based). Each page returns an `endCursor` that must be passed to the next request.

**Solution**: Query types come in pairs: `GetCustomerIds` / `GetNextCustomerIds`, `GetProductIds` / `GetNextProductIds`, etc. The "Next" variant includes a `{{After}}` parameter for the cursor. The calling code loops: call the first query, extract the cursor from the response, call the "Next" query with the cursor, repeat until `hasNextPage` is false.

**Example**: The `ShpfyGraphQLType` enum shows 65+ "Next*" entries paired with their initial counterparts. The `ShpfyProductAPI` and other API codeunits implement the pagination loop.

## Conflict detection via redundancy codes

**Problem**: An order can be modified in Shopify after it has already been processed into a BC Sales Order. The connector needs to detect this without re-downloading and comparing every field.

**Solution**: The `Line Items Redundancy Code` on the order header is an integer hash of pipe-separated line IDs. On re-import, the connector computes the hash from the new line data and compares it to the stored value. It also compares total quantity and shipping charges amount.

**Example**: In `ShpfyImportOrder.Codeunit.al`, `IsImportedOrderConflictingExistingOrder` checks `OrderHeader."Current Total Items Quantity"` against the JSON value, computes the line ID hash, and compares shipping charges. Any mismatch sets `Has Order State Error := true`.

**Gotcha**: This only detects structural changes (lines added/removed, quantities changed, shipping changed). It does not detect changes to individual line prices, addresses, or metadata. Those changes silently update the Shopify record without flagging a conflict.

## Legacy patterns to avoid

### Config template tables (removed v25)

The Shop table had `Item Template Code` (field 11) and `Customer Template Code` (field 24) of type `Code[10]` referencing `Config. Template Header`. These were replaced by `Item Templ. Code` (field 63) and `Customer Templ. Code` (field 62) referencing BC's native `Item Templ.` and `Customer Templ.` tables. The old fields are `ObsoleteState = Removed` with `ObsoleteTag = '25.0'` and guarded by `#if not CLEANSCHEMA25`. Do not reference the old template fields.

### Export Customer To Shopify boolean (removed v27)

Field 29 (`Export Customer To Shopify`) was a boolean that triggered automatic customer export during sync. It was removed in v27 (`ObsoleteTag = '27.0'`) and replaced by a manual "Add to Shopify" action on the Shopify Customers page. The field definition is guarded by `#if not CLEANSCHEMA27`.

### Log Enabled boolean (removed v26)

Field 5 (`Log Enabled`) was a simple on/off toggle for logging. It was replaced by the `Logging Mode` enum (field number not adjacent) which supports finer-grained options. The old field is `ObsoleteState = Removed` with `ObsoleteTag = '26.0'` and guarded by `#if not CLEANSCHEMA26`.

### Owner Resource text field on metafields (removed v28)

The `Shpfy Metafield` table had an `Owner Resource` text field (field 3) that stored the owner type as a string. This was replaced by the `Owner Type` enum with `IMetafieldOwnerType` interface dispatch. Similarly, the `Value Type` enum field (field 6) was replaced by the `Type` field. Both old fields are `ObsoleteTag = '28.0'`.

### Tax Code on variant (deprecated v28)

The `Tax Code` field (field 13) on `Shpfy Variant` was deprecated because Shopify API 2025-10 removed `taxCode` from the `ProductVariant` type. The field is `ObsoleteState = Pending` in v28 and will be removed in v31.
