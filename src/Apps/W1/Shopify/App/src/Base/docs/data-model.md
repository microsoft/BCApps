# Base data model

## Tables

### Shpfy Shop (30102)
Central configuration table for Shopify shop connection.

**Location:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Base\Tables\ShpfyShop.Table.al`

**Key fields (first 300 lines shown):**

**Connection:**
- `Code` (Code[20]) -- Primary key, shop identifier
- `Shopify URL` (Text[250]) -- Admin URL (e.g., https://mystore.myshopify.com/admin)
- `Enabled` (Boolean) -- Shop enabled for sync
- `Shop Id` (Integer) -- Calculated from Shopify URL hash

**Logging:**
- `Logging Mode` (Enum Shpfy Logging Mode) -- Disabled, Error Only, Verbose

**Product sync:**
- `Sync Item` (Option) -- " ", "To Shopify", "From Shopify"
- `Sync Item Images` (Option) -- " ", "To Shopify", "From Shopify"
- `Sync Item Extended Text` (Boolean) -- Include extended text in product body
- `Sync Item Attributes` (Boolean) -- Include item attributes in product body
- `Sync Item Marketing Text` (Boolean) -- Include marketing text
- `Can Update Shopify Products` (Boolean) -- Allow BC to update existing Shopify products
- `SKU Mapping` (Enum Shpfy SKU Mapping) -- How SKU maps to BC
- `UoM as Variant` (Boolean) -- Represent units of measure as variants
- `Status for Created Products` (Enum Shpfy Cr Prod Status Value) -- Active or Draft
- `Action for Removed Products` (Enum Shpfy Remove Product Action) -- Status change when removed

**Item creation:**
- `Auto Create Unknown Items` (Boolean) -- Create BC items from Shopify products
- `Item Templ. Code` (Code[20]) -- Template for new items
- `Shopify Can Update Items` (Boolean) -- Allow Shopify to update BC items

**Customer sync:**
- `Customer Import From Shopify` (Enum Shpfy Customer Import Range) -- AllCustomers, WithOrderImport, None
- `Auto Create Unknown Customers` (Boolean) -- Create BC customers from Shopify
- `Customer Templ. Code` (Code[20]) -- Template for new customers
- `Shopify Can Update Customer` (Boolean) -- Allow Shopify to update BC customers
- `Can Update Shopify Customer` (Boolean) -- Allow BC to update Shopify customers
- `Customer Mapping Type` (Enum Shpfy Customer Mapping) -- By Email/Phone, By Bill-to, DefaultCustomer
- `Default Customer No.` (Code[20]) -- Default customer for all orders
- `Name Source`, `Name 2 Source`, `Contact Source` (Enum Shpfy Name Source) -- Name derivation
- `County Source` (Enum Shpfy County Source) -- Code or Name

**Pricing:**
- `Customer Price Group` (Code[10]) -- For price calculation
- `Customer Discount Group` (Code[20]) -- For discount calculation

**GL accounts:**
- `Shipping Charges Account` (Code[20]) -- G/L account for shipping
- (Additional accounts for tips, sold gift cards, etc.)

**Language and currency:**
- `Language Code` (Code[10]) -- Default language for sync
- (Currency settings in other fields)

**Additional configuration fields:**
- Order processing settings
- Inventory sync settings
- Tax and VAT settings
- B2B company settings
- Webhook settings
- Initial import settings

**Methods:**
- `SetLastSyncTime(SyncType, DateTime)` -- Updates Shpfy Synchronization Info
- `CalcShopId()` -- Calculates Shop Id from URL hash

**Relationships:**
- 1:N with all Shopify entity tables (Product, Customer, Order, etc.)
- 1:N with Shpfy Synchronization Info
- 1:N with Shpfy Initial Import Line

**Indexes:**
- PK: Code (clustered)

### Shpfy Synchronization Info (30103)
Tracks last synchronization timestamp for each sync type.

**Location:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Base\Tables\ShpfySynchronizationInfo.Table.al`

**Key fields:**
- `Shop Code` (Code[20]) -- Part of PK
- `Synchronization Type` (Enum Shpfy Synchronization Type) -- Part of PK
- `Last Sync Time` (DateTime) -- Last successful sync timestamp

**Synchronization Types (from enum):**
- Products
- Customers
- Companies
- Orders
- Inventory
- Images
- Payments
- Payouts
- (Additional types for webhooks, bulk operations, etc.)

**Usage:** Used to perform incremental syncs (only sync records updated since Last Sync Time).

**Indexes:**
- PK: Shop Code, Synchronization Type (clustered)

### Shpfy Tag (30104)
Stores tags for multiple entity types.

**Location:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Base\Tables\ShpfyTag.Table.al`

**Key fields:**
- `Parent Table No.` (Integer) -- Table ID (e.g., Database::"Shpfy Product")
- `Parent Id` (BigInteger) -- Record ID in parent table
- `Tag` (Text[255]) -- Tag value

**Constraint:** Maximum 250 tags per parent record (enforced in OnInsert trigger).

**Methods:**
- `GetCommaSeparatedTags(ParentId)` -- Returns "tag1,tag2,tag3"
- `UpdateTags(ParentTableNo, ParentId, CommaSeparatedTags)` -- Replaces all tags for record

**Usage:** Used by Shpfy Product, Shpfy Customer, Shpfy Order to store Shopify tags.

**Indexes:**
- PK: Parent Id, Tag (clustered)

### Shpfy Initial Import Line (30137)
Tracks initial import jobs for guided setup.

**Location:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Base\Tables\ShpfyInitialImportLine.Table.al`

**Key fields:**
- `Name` (Code[20]) -- Import step name (e.g., "Products", "Customers"), primary key
- `Dependency Filter` (Text[250]) -- Steps that must complete first
- `Session ID` (Integer) -- Session running the job
- `Job Status` (Option) -- " ", Success, "In Process", Error
- `Job Queue Entry ID` (Guid) -- Link to Job Queue Entry
- `Job Queue Entry Status` (Option) -- Mirrors job queue status
- `Shop Code` (Code[20]) -- Shop being imported
- `Page ID` (Integer) -- Page to open after completion
- `Demo Import` (Boolean) -- Demo data import flag

**Flow:**
1. Initial import creates lines for each sync type (Products, Customers, etc.)
2. Dependency Filter ensures correct order (e.g., Customers before Orders)
3. Job Queue Entry created for each line
4. Job Status updated as import progresses

**Indexes:**
- Key1: Name (clustered)

### Shpfy Cue (30138)
Activity cue counts for role center.

**Fields:**
- Counts of orders, products, customers by status
- Used in Shpfy Activities page for drill-down

## Enums

### Shpfy Synchronization Type (30100)
Identifies sync operation type for Shpfy Synchronization Info.

**Values:**
- Products
- Customers
- Companies
- Orders
- Inventory
- Images
- Payments
- Payouts
- Webhooks
- BulkOperations
- (Additional types)

### Shpfy Logging Mode (30101)
Controls logging verbosity.

**Values:**
- `Disabled` (0) -- No logging
- `Error Only` (1) -- Log errors only
- `Verbose` (2) -- Log all requests/responses

**Used by:** Shpfy Communication Mgt. to determine what to log in Shpfy Log Entry table.

### Shpfy Mapping Direction (30102)
Direction of mapping operation.

**Values:**
- `ShopifyToBC` (0) -- Import: Map Shopify record to BC record
- `BCToShopify` (1) -- Export: Map BC record to Shopify record

**Used by:** Product Mapping, Customer Mapping, Company Mapping to determine search direction.

### Shpfy Import Action (30103)
Action to take when importing record.

**Values:**
- `Create` -- Create new BC record
- `Update` -- Update existing BC record
- `Skip` -- Skip record

## Relationships

```
Shpfy Shop (1) ----< (N) Shpfy Synchronization Info
       |
       +----< (N) Shpfy Initial Import Line
       |
       +----< (N) Shpfy Product
       |
       +----< (N) Shpfy Customer
       |
       +----< (N) Shpfy Company
       |
       +----< (N) Shpfy Order
       |
       +----< (N) ... (all entity tables)

Shpfy Tag -- generic, linked via Parent Table No. + Parent Id
  (Used by Shpfy Product, Shpfy Customer, Shpfy Order)
```

## Key indexes

**Shpfy Shop:**
- PK: Code (clustered)

**Shpfy Synchronization Info:**
- PK: Shop Code, Synchronization Type (clustered)

**Shpfy Tag:**
- PK: Parent Id, Tag (clustered)

**Shpfy Initial Import Line:**
- Key1: Name (clustered)
