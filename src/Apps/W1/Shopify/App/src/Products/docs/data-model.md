# Products data model

## Tables

### Shpfy Product (30127)
Stores Shopify product master data.

**Location:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Products\Tables\ShpfyProduct.Table.al`

**Key fields:**
- `Id` (BigInteger) -- Shopify product ID, primary key
- `Title` (Text[100]) -- Product title
- `Description` (Text[250]) -- Plain text description
- `Description as HTML` (Blob) -- HTML body stored as blob
- `Product Type` (Text[50]) -- Product categorization
- `Vendor` (Text[100]) -- Vendor/manufacturer
- `Status` (Enum Shpfy Product Status) -- Active, Archived, Draft
- `Has Variants` (Boolean) -- True if product has multiple variants
- `Shop Code` (Code[20]) -- Link to Shpfy Shop
- `Item SystemId` (Guid) -- Link to BC Item
- `Image Id` (BigInteger) -- Default product image
- `Created At`, `Updated At` (DateTime) -- Shopify timestamps
- `Last Updated by BC` (DateTime) -- BC modification timestamp
- `Image Hash`, `Tags Hash`, `Description Html Hash` (Integer) -- Change tracking hashes
- `Has Error` (Boolean), `Error Message` (Text[2048]) -- Item creation error tracking

**Methods:**
- `GetCommaSeparatedTags()` -- Returns tags as comma-separated string
- `GetDescriptionHtml()` -- Reads HTML description from blob
- `SetDescriptionHtml(Text)` -- Writes HTML description and updates hash
- `UpdateTags(Text)` -- Updates tags via Shpfy Tag table

**Relationships:**
- 1:N with Shpfy Variant (via Product Id)
- N:1 with Item (via Item SystemId)
- N:1 with Shpfy Shop

### Shpfy Variant (30129)
Stores Shopify product variant data (one or more per product).

**Location:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Products\Tables\ShpfyVariant.Table.al`

**Key fields:**
- `Id` (BigInteger) -- Shopify variant ID, primary key
- `Product Id` (BigInteger) -- Parent product
- `SKU` (Text[50]) -- Stock keeping unit
- `Barcode` (Text[50]) -- Barcode
- `Price` (Decimal) -- Selling price
- `Compare at Price` (Decimal) -- Original/compare-at price
- `Unit Cost` (Decimal) -- Cost
- `Title` (Text[100]) -- Variant title (e.g., "Small / Red")
- `Display Name` (Text[250]) -- Full display name
- `Option 1/2/3 Name/Value` (Text[50]) -- Up to 3 variant options (e.g., Size=Small, Color=Red)
- `Weight` (Decimal) -- Product weight
- `Taxable` (Boolean) -- Subject to tax
- `Shop Code` (Code[20])
- `Item SystemId` (Guid) -- Link to BC Item
- `Item Variant SystemId` (Guid) -- Link to BC Item Variant
- `Mapped By Item` (Boolean) -- True if variant maps to item (not item variant)
- `UoM Option Id` (Integer) -- Which option represents unit of measure
- `Image Id` (BigInteger) -- Variant-specific image
- `Image Hash` (Integer) -- Image change tracking
- `Created At`, `Updated At` (DateTime)
- `Last Updated by BC` (DateTime)

**Calculated fields:**
- `Item No.` (Code[20]) -- FlowField from Item
- `Variant Code` (Code[10]) -- FlowField from Item Variant

**Relationships:**
- N:1 with Shpfy Product (via Product Id)
- N:1 with Item (via Item SystemId)
- N:1 with Item Variant (via Item Variant SystemId)
- 1:N with Shpfy Inventory Item (via Variant Id)

### Shpfy Inventory Item (30126)
Inventory metadata for variants (internal access only).

**Location:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Products\Tables\ShpfyInventoryItem.Table.al`

**Key fields:**
- `Id` (BigInteger) -- Inventory item ID
- `Variant Id` (BigInteger) -- Parent variant
- `Tracked` (Boolean) -- Inventory tracking enabled
- `Requires Shipping` (Boolean)
- `Country/Region of Origin` (Text[50])
- `Unit Cost` (Decimal)

### Shpfy Sales Channel (30125)
Product publication channels.

**Key fields:**
- `Id` (BigInteger) -- Channel ID
- `Name` (Text[100]) -- Channel name (e.g., "Online Store")
- `Shop Code` (Code[20])

### Shpfy Product Collection (30128)
Product collections for grouping.

**Key fields:**
- `Id` (BigInteger) -- Collection ID
- `Handle` (Text[255]) -- URL handle
- `Title` (Text[255]) -- Collection title
- `Shop Code` (Code[20])

## Enums

### Shpfy Product Status (30130)
**Location:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Products\Enums\ShpfyProductStatus.Enum.al`

- `Active` (0) -- Published and visible
- `Archived` (1) -- Archived, not visible
- `Draft` (2) -- Unpublished draft

### Shpfy SKU Mapping (30132)
Defines how variant SKU maps to BC.

**Location:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Products\Enums\ShpfySKUMapping.Enum.al`

- `" "` (0) -- No mapping
- `Item No.` (1) -- SKU = Item."No."
- `Variant Code` (2) -- SKU = Item Variant.Code
- `Item No. + Variant Code` (3) -- SKU = concatenation
- `Vendor Item No.` (4) -- SKU = Item Vendor."Vendor Item No."
- `Bar Code` (5) -- SKU = Item."Bar Code" or Item Reference

### Shpfy Variant Create Strategy (30165)
Strategy for creating variants via GraphQL.

**Location:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Products\Enums\ShpfyVariantCreateStrategy.Enum.al`

- `DEFAULT` (0)
- `REMOVE_STANDALONE_VARIANT` (1) -- Removes default variant when adding new ones

### Shpfy Remove Product Action (30131)
Action when product removed from BC.

- Values: Status To Draft, Status To Archived, Do Nothing (via interface implementations)

### Shpfy Incl In Product Sync (30166)
Controls item inclusion in product sync.

- All Items
- By Item Category Code
- By Product Collection Mapping

## Relationships

```
Shpfy Shop (1) ----< (N) Shpfy Product
                         |
                         +----< (N) Shpfy Variant ----< (N) Shpfy Inventory Item
                                      |
                                      |
Item (1) ----< (N) Shpfy Variant
       |
       +----< (N) Item Variant (1) ----< (N) Shpfy Variant

Shpfy Product (N) ----< (N) Shpfy Tag (by Parent Id, Parent Table No.)
Shpfy Product (N) ----< (N) Shpfy Metafield
Shpfy Variant (N) ----< (N) Shpfy Metafield
```

## Key indexes

**Shpfy Product:**
- PK: Id (clustered)
- Key2: Shop Code, Item SystemId

**Shpfy Variant:**
- PK: Id (clustered)
