# Customers -- implementation details

## Import flow (Shopify to BC)

The import flow is orchestrated by `ShpfySyncCustomers` (codeunit 30123), triggered by running it against a `Shpfy Shop` record.

1. **Retrieve IDs** -- `ShpfyCustomerAPI.RetrieveShopifyCustomerIds` fetches all customer IDs modified since the last sync via paginated GraphQL queries (`GetCustomerIds` / `GetNextCustomerIds`). Returns a `Dictionary of [BigInteger, DateTime]`.

2. **Filter changed records** -- only customers whose Shopify `updatedAt` is newer than both the local `Updated At` and `Last Updated by BC` timestamps are queued for import.

3. **Per-customer import** -- `ShpfyCustomerImport` runs for each queued customer:
   - Calls `CustomerAPI.RetrieveShopifyCustomer` to fetch full customer data (via `GetCustomer` GraphQL)
   - `UpdateShopifyCustomerFields` parses the JSON response and updates the local `Shpfy Customer` and `Shpfy Customer Address` records, including tags and metafields
   - Attempts to find a BC mapping via `ShpfyCustomerMapping.FindMapping`
   - If mapped and `Shopify Can Update Customer` is enabled, runs `ShpfyUpdateCustomer`
   - If unmapped and `Auto Create Unknown Customers` is enabled, runs `ShpfyCreateCustomer`

4. **Customer creation** -- `ShpfyCreateCustomer` (codeunit 30110):
   - Resolves a customer template via `FindCustomerTemplate` (checks `Shpfy Customer Template` table by shop + country code, falls back to the shop default)
   - Creates a BC Customer record using `CustomerTemplMgt.CreateCustomerFromTemplate`
   - Fills fields using `ShpfyUpdateCustomer.FillInCustomerFields`
   - Links the Shopify customer to BC via `Customer SystemId`

5. **Customer update** -- `ShpfyUpdateCustomer` (codeunit 30124):
   - Finds the default address for the Shopify customer
   - Calls `FillInCustomerFields` to map Shopify fields to BC Customer fields
   - Triggers `CustCont-Update` for contact synchronization

## Export flow (BC to Shopify)

The export flow is triggered by `ShpfySyncCustomers` when `Can Update Shopify Customer` is enabled on the shop.

1. `ShpfyCustomerExport` iterates all BC Customer records
2. For each customer, calls `CustomerMapping.FindMapping` (BCToShopify direction):
   - First checks if a `Shpfy Customer` record exists with the same `Customer SystemId` and `Shop Id`
   - Falls back to `CustomerAPI.FindIdByEmail` then `FindIdByPhone`
3. **Create** -- if no mapping exists and create is enabled:
   - Requires non-empty email (skips with log otherwise)
   - `FillInShopifyCustomerData` maps BC fields to Shopify customer/address records
   - `CustomerAPI.CreateCustomer` sends a `customerCreate` GraphQL mutation
4. **Update** -- if mapped and `Can Update Shopify Customer` is enabled:
   - `FillInShopifyCustomerData` recalculates fields
   - `CustomerAPI.UpdateCustomer` sends a `customerUpdate` GraphQL mutation (only sends changed fields)
   - Syncs metafields if `Customer Metafields To Shopify` is enabled

## Address mapping

Shopify addresses map to `Shpfy Customer Address` records (table 30106). Key fields:

| Shopify field | BC field |
|---------------|----------|
| `address1`, `address2` | `Address 1`, `Address 2` |
| `city` | `City` |
| `zip` | `Zip` |
| `countryCodeV2` | `Country/Region Code` (ISO 2-letter) |
| `provinceCode` | `Province Code` |
| `province` | `Province Name` |
| `phone` | `Phone` (sanitized to digits + `/ + . ( )`) |

During import, all addresses from Shopify are stored. Addresses not present in the latest Shopify response are deleted. The `defaultAddress` is flagged with `Default = true`.

During export, the country code is resolved from BC's `Country/Region` table via ISO Code. Province/county mapping uses the `Shpfy Tax Area` table (see below).

## Interface-driven mapping strategies

### Customer mapping (`ICustomerMapping`)

The `Shpfy Customer Mapping` enum (30106) is extensible and implements `ICustomerMapping`:

- **By Email/Phone** (`ShpfyCustByEmailPhone`) -- matches BC customers by email filter (`@` prefix for case-insensitive) or phone number filter (digits with wildcard pattern)
- **By Bill-to Info** (`ShpfyCustByBillto`) -- matches using bill-to address fields from order data
- **Default Customer** (`ShpfyCustByDefaultCust`) -- always returns the configured default customer from the `Shpfy Customer Template`

The `ShpfyCustomerMapping` codeunit (30118) orchestrates mapping in both directions:

- **ShopifyToBC** -- checks `Customer SystemId` first, then delegates to `DoFindMapping` which tries email then phone
- **BCToShopify** -- checks local records by `Customer SystemId` + `Shop Id`, then queries Shopify API by email/phone

### Name source (`ICustomerName`)

The `Shpfy Name Source` enum (30108) controls how the BC `Name`, `Name 2`, and `Contact` fields are populated:

- **CompanyName** -- returns the `CompanyName` from the address
- **FirstAndLastName** -- returns `"FirstName LastName"`
- **LastAndFirstName** -- returns `"LastName FirstName"`
- **None** -- returns empty string

The shop configures three separate name sources: `Name Source`, `Name 2 Source`, and `Contact Source`. During import (`FillInCustomerFields`), each is applied via the interface. If `Name` ends up empty, it falls back to `Contact`.

During export (`SpiltNameIntoFirstAndLastName`), the reverse operation splits a single name into first/last based on `Name Source` / `Name 2 Source` / `Contact Source` settings.

## County/region handling

### Import (Shopify to BC) -- `ICounty` interface

The `Shpfy County Source` enum (30104) controls how `Province Code` / `Province Name` from Shopify maps to BC's `County` field:

- **Code** (`ShpfyCountyCode`) -- uses `Province Code` (e.g., "CA", "NY")
- **Name** (`ShpfyCountyName`) -- uses `Province Name` (e.g., "California", "New York")

Both implementations handle both `Shpfy Customer Address` and `Shpfy Company Location` records.

### Import from JSON -- `ICountyFromJson` interface

The same enum also implements `ICountyFromJson` for parsing county data directly from JSON address objects:

- **Code** (`ShpfyCountyFromJsonCode`) -- reads `provinceCode` from JSON
- **Name** (`ShpfyCountyFromJsonName`) -- reads `province` from JSON

### Export (BC to Shopify)

During export, the `Shpfy Tax Area` table is used to resolve BC's `County` field to Shopify's `Province Code` and `Province Name`:

- When `County Source = Code`: filters `Tax Area` by `Country/Region Code` + `County Code`
- When `County Source = Name`: filters by `Country/Region Code` + `County` (with wildcard fallback)

If the county code exceeds the maximum field length, an error is raised with details.

## Tax area resolution

The `Shpfy Tax Area` table (30109) maps country/region + county combinations to BC tax settings. Primary key: `Country/Region Code` + `County`.

Fields applied to BC customers during import/update:

- `Tax Area Code` -- set on the BC Customer's `Tax Area Code` field
- `Tax Liable` -- set on the BC Customer's `Tax Liable` field
- `VAT Bus. Posting Group` -- set on the BC Customer's `VAT Bus. Posting Group` field

Resolution happens in both `FillInCustomerFields` (import) and `CreateCustomerFromCompany` (company import) by looking up `TaxArea.Get(CountryRegionCode, ProvinceName)`.

## Tables

| Table | ID | Purpose |
|-------|-----|---------|
| `Shpfy Customer` | 30105 | Shopify customer record with link to BC Customer via `Customer SystemId` |
| `Shpfy Customer Address` | 30106 | Shopify customer addresses; one flagged as Default |
| `Shpfy Customer Template` | 30107 | Per-shop, per-country customer template configuration |
| `Shpfy Province` | 30108 | **Obsolete** (removed in 25.0) -- replaced by `Shpfy Tax Area` |
| `Shpfy Tax Area` | 30109 | Maps country + county to BC tax area, VAT posting group, tax liability |

## Events

`ShpfyCustomerEvents` (codeunit) publishes integration events for extensibility:

- `OnBeforeCreateCustomer` / `OnAfterCreateCustomer`
- `OnBeforeUpdateCustomer` / `OnAfterUpdateCustomer`
- `OnBeforeFindMapping` / `OnAfterFindMapping`
- `OnBeforeFindCustomerTemplate` / `OnAfterFindCustomerTemplate`
- `OnBeforeSendCreateShopifyCustomer` / `OnBeforeSendUpdateShopifyCustomer`
