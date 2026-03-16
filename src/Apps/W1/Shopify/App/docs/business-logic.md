# Business logic

## Product synchronization

Product sync is bidirectional, controlled by the Shop's `Sync Item` setting.

**Import (From Shopify)**: `ShpfySyncProducts.ImportProductsFromShopify` calls `ProductApi.RetrieveShopifyProductIds` to get all product IDs with their `UpdatedAt` timestamps. It then filters: if a product already exists locally and both `Product."Updated At"` and `Product."Last Updated by BC"` are newer than Shopify's timestamp, the product is skipped. This is the first-pass optimization -- no API call is made for unchanged products.

For each product that passes the filter, `ShpfyProductImport.SetProduct` calls `ProductApi.RetrieveShopifyProduct` (a GraphQL query) to fetch full product data, then `VariantApi.RetrieveShopifyProductVariantIds` and `VariantApi.RetrieveShopifyVariant` for each variant. The import creates or updates local `Shpfy Product` and `Shpfy Variant` records.

Then `ShpfyProductImport.OnRun` iterates variants and calls `ProductMapping.FindMapping` to link each variant to a BC Item + Item Variant. The mapping strategy depends on the Shop's `SKU Mapping` setting -- it can match by Item No., Vendor Item No., Barcode, or a compound SKU with a configurable separator. If no mapping is found and `Auto Create Unknown Items` is enabled, `ShpfyCreateItem` runs (with a `Commit()` before each attempt for isolation). Failures are captured as product errors rather than thrown.

**Export (To Shopify)**: `ShpfyProductExport.OnRun` iterates all `Shpfy Product` records that have a non-empty `Item SystemId` (meaning they are mapped to a BC item). For each product, it calls `UpdateProductData`, which recalculates prices via `ProductPriceCalc`, rebuilds the HTML body from extended text + marketing text + attributes, updates variants, and pushes changes via `ProductApi` / `VariantApi` GraphQL mutations.

For price-only sync, the export uses bulk operations. It accumulates JSONL input and, if the count exceeds 100 items, calls `BulkOperationMgt.SendBulkMutation`. If the bulk operation fails (e.g., another is already running), it falls back to individual `VariantAPI.UpdateProductPrice` calls per variant.

**Image sync** runs separately via `ShpfySyncProductImage` and `ShpfyProductImageExport`/`ShpfyVariantImageExport`. Image changes are detected by comparing the `Image Hash` on the product/variant. Bulk image updates use `ShpfyBulkUpdateProductImage`.

**UoM as Variant**: When `UoM as Variant` is enabled on the Shop, the connector treats BC Units of Measure as Shopify variant options. The `UoM Option Id` on the variant tracks which option slot (1, 2, or 3) holds the UoM value. During order mapping, the UoM option value becomes the `Unit of Measure Code` on the order line.

## Order import and processing

Order import is a multi-step pipeline.

**Step 1 -- Retrieval**: `ShpfyOrders.OnRun` queries Shopify for order IDs updated since the last sync time. For each order, it inserts a row into `Shpfy Orders to Import`. Webhooks (`Order Created Webhooks`) can also populate this staging table in near-real-time.

**Step 2 -- Import**: `ShpfyImportOrder.ImportOrderAndCreateOrUpdate` is the main import procedure. It calls GraphQL to get the full order JSON (header, addresses, B2B purchasing entity, payment terms). Then it retrieves order lines in paginated batches via `GetOrderLines` / `GetNextOrderLines`. It writes the data into `Shpfy Order Header` and `Shpfy Order Line` records.

During import, it also fetches: fulfillment orders (for location/delivery method), shipping charges, transactions, returns (if configured), refunds (if configured), and risk assessments. The `DataCapture.Add()` call stores the raw JSON for each header and line as an audit trail.

If the order was already processed in BC and the re-import detects changes (different line IDs via `LineItemsRedundancyCode`, different quantities, or different shipping amounts), the order is flagged as conflicting (`Has Order State Error = true`) rather than silently overwriting. This is critical -- the connector refuses to modify already-processed orders automatically.

After import, `ConsiderRefundsInQuantityAndAmounts` subtracts refunded quantities and amounts from order lines. Then `DeleteZeroQuantityLines` removes fully-refunded lines. If the order is fully fulfilled and paid, `CheckToCloseOrder` / `CloseOrder` closes it in Shopify.

**Step 3 -- Mapping**: `ShpfyOrderMapping.DoMapping` resolves Shopify entities to BC entities. For B2C orders, it uses `CustomerMapping.DoMapping` with the configured strategy (ByEmail/Phone, ByBillto, ByDefault). For B2B orders, it uses `CompanyMapping.DoMapping`. The CustomerTemplate table provides per-country overrides.

For order lines, `MapVariant` looks up the Shopify Variant, resolves the `Item SystemId` to a BC Item No., the `Item Variant SystemId` to a Variant Code, and extracts the UoM from the variant option. If the variant is unmapped, it triggers `ProductImport` on the spot to try to create the mapping.

Payment method mapping uses `MapPaymentMethodCode`, which looks at successful Sale/Capture/Authorization transactions and resolves via `PaymentMethodMapping` (gateway + card brand to BC method). If multiple distinct payment methods are found, it leaves the field blank for manual resolution.

**Step 4 -- Processing**: `ShpfyProcessOrders.ProcessShopifyOrder` runs `ShpfyProcessOrder.OnRun` within a TryFunction pattern. `ProcessOrder` calls `DoMapping` one more time, then `CreateHeaderFromShopifyOrder` creates a BC Sales Header (Sales Order or Sales Invoice, depending on fulfillment status and the `Create Invoices From Orders` setting). It populates all three address blocks, sets currency based on `Currency Handling`, assigns tax area, payment method, shipping method, and salesperson.

`CreateLinesFromShopifyOrder` creates Sales Lines. Tips map to the `Tip Account` G/L account, gift cards to `Sold Gift Card Account`, and regular items to type Item with location derived from `ShpfyShopLocation`. Shipping charges become G/L Account lines (or Item Charge lines if configured in `ShipmentMethodMapping`). Cash rounding adjustments get their own line from `Cash Roundings Account`.

The `DocLinkToDoc` record is always created to link the Shopify order to the BC document. If `Order Attributes To Shopify` is enabled, the BC document number is written back to Shopify as a custom order attribute.

On failure, `ProcessOrders` catches the error, stores it on the order header, and calls `CleanUpLastCreatedDocument()` to delete the partially-created Sales document. The `Commit()` between each order ensures isolation.

## Customer and company sync

**Customer mapping** uses strategy interfaces. The `Shpfy Customer Mapping` enum maps to implementations: `ByEMail/Phone` (`ShpfyCustByEmailPhone`), `ByBilltoInfo` (`ShpfyCustByBillto`), and `ByDefaultCustomer` (`ShpfyCustByDefaultCust`). The mapping codeunit `ShpfyCustomerMapping.DoMapping` checks if the order has name info -- if both Name and Name2 are empty, it falls back to ByEmail/Phone regardless of the configured strategy.

The `DoFindMapping` method in `ShpfyCustomerMapping` does bidirectional lookup: Shopify-to-BC searches BC Customers by email filter (`'@' + email`) then phone filter (digits-only with wildcards), while BC-to-Shopify searches the Shopify Customer table by `Customer SystemId`, then calls the Shopify API to find by email/phone.

**Customer import** can be set to `None`, `WithOrderImport`, or `AllCustomers` via the `Customer Import From Shopify` enum. With `None`, the default customer is used. With `WithOrderImport`, customers are imported on-demand during order processing. With `AllCustomers`, a full sync pulls all customer IDs.

**Company mapping (B2B)** follows the same pattern with the `Shpfy Company Mapping` enum: `ByTaxId`, `ByEmailPhone`, `ByDefaultCompany`. The B2B order path in `OrderMapping.MapB2BHeaderFields` tries to resolve from the company location first (which can have its own Sell-to/Bill-to customer overrides), then from the company level, then from the default.

**Name formatting** uses the `Shpfy ICustomer Name` interface, with implementations for CompanyName, FirstAndLastName, LastAndFirstName, and None. The Shop configures which source to use for Name, Name2, and Contact. County resolution similarly uses `Shpfy ICounty From Json` with Code and Name implementations.

## Inventory sync

Inventory sync is one-way: BC to Shopify. `ShpfySyncInventory.OnRun` iterates shop locations that have a non-Disabled `Stock Calculation` setting. For each location, `InventoryApi.ImportStock` reads the current Shopify inventory levels, then `InventoryApi.ExportStock` pushes BC-calculated stock.

Stock calculation uses the `Shpfy IStock Available` interface. Implementations include `ShpfyCanHaveStock` and `ShpfyCanNotHaveStock` (for the basic toggle), and `ShpfyFreeInventory`, `ShpfyBalanceToday`, etc. for actual calculations. The `Shpfy Stock Calculation` enum on the Shop Location determines which implementation runs. There is also an `Extended Stock Calculation` interface for custom calculations.

## Returns and refunds

Returns and refunds are import-only from Shopify. During order import, `ShpfyImportOrder.SetAndCreateRelatedRecords` conditionally fetches returns via `ReturnsAPI.GetReturns` and refunds via `RefundsAPI.GetRefunds`, controlled by the `IReturnRefund Process` interface's `IsImportNeededFor` method.

The `Return and Refund Process` enum has two values: `Import Only` and `Auto Create Credit Memo`. With `Import Only`, the data is stored but no BC documents are created. With `Auto Create Credit Memo`, `ProcessOrders.ProcessShopifyRefunds` iterates unprocessed refund headers and calls `IReturnRefundProcess.CreateSalesDocument` to generate Sales Credit Memos.

The `Return Location Priority` enum controls where returned items go: the shop's default return location, the fulfillment location, or the order's original location.

## Extension points

The connector exposes events throughout its processing chain. The main event codeunits are:

- `ShpfyOrderEvents` -- Before/After CreateSalesHeader, CreateItemSalesLine, CreateShippingCostSalesLine, ProcessSalesDocument, MapCustomer, MapCompany, MapShipmentMethod, MapPaymentMethod, and enum conversion hooks
- `ShpfyProductEvents` -- Before/After FindProductMapping, CreateProductBodyHtml, GetCommaSeparatedTags, ProductsToSynchronizeFiltersSet
- `ShpfyCustomerEvents` -- Before/After FindMapping (both directions)
- `ShpfyCommunicationEvents` -- OnClientSend, OnClientPost, OnClientGet, OnGetContent, OnGetAccessToken (used extensively by the test app to mock API responses)
- `ShpfyInventoryEvents` -- for stock calculation customization

If you want to customize how orders are created, subscribe to `OnBeforeCreateSalesHeader` and set `IsHandled = true`. If you want to change product mapping, subscribe to `OnBeforeFindProductMapping`. If you want to add custom stock calculation logic, implement `Shpfy Stock Calculation` or `Shpfy Extended Stock Calculation` interface.
