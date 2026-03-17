# Customers

The Customers module synchronizes Shopify customers with BC Customer records. It uses a pluggable interface architecture for both mapping strategies and name formatting, so the same sync engine adapts to different business rules without code changes.

## How it works

`ShpfySyncCustomers` orchestrates the bidirectional sync. On import, it retrieves Shopify customer IDs and their `Updated At` timestamps, compares them against local records, and queues only changed customers into a temp table. For each queued customer, `ShpfyCustomerImport` fetches full details from Shopify, then `ShpfyCustomerMapping.FindMapping` tries to link the Shopify customer to a BC Customer. The mapping first checks the stored `Customer SystemId`; if that is empty or stale, it delegates to `DoFindMapping`, which searches BC customers by email (case-insensitive) and then by phone number (using a digit-only wildcard filter built by `CreatePhoneFilter`). If no match is found and `Auto Create Unknown Items` is enabled, `ShpfyCreateCustomer` creates a new BC Customer using a template selected from `Shpfy Customer Template` based on the customer's country code.

On export, `ShpfyCustomerExport` iterates BC Customers, finds or creates their Shopify counterpart through the same mapping codeunit (but in the BCToShopify direction), and pushes updates to the API.

The mapping strategy is controlled by the shop's `Customer Mapping Type` enum, which selects one of three `ICustomerMapping` implementations: `ByEmailPhone` (match on email, then phone), `ByBillto` (match on bill-to address fields), or `ByDefaultCust` (always return the shop's default customer). The enum is extensible, so partners can add custom strategies.

Customer name formatting is handled separately via the `ICustomerName` interface, with four implementations: FirstLastName, LastFirstName, CompanyName, and Empty. The `ICounty` and `ICountyFromJson` interfaces resolve Shopify province codes/names to BC county values, bridging the address model differences.

## Things to know

- Customers link to BC via `Customer SystemId`, not `Customer No.`. The `Customer No.` field is a FlowField. This survives customer renumbering.
- The `Shpfy Customer Template` table (keyed by Shop Code + Country/Region Code) selects which BC Customer Template and Default Customer No. to use when auto-creating customers. Country-specific rules are the norm for international shops.
- The `Shop Id` field on `Shpfy Customer` is an integer identifying the Shopify shop, used as a filter key for BCToShopify mapping lookups. This is separate from `Shop Code`.
- `Shpfy Customer Address` uses a negative auto-incrementing ID pattern for new records: the `OnInsert` trigger picks `Min(-1, smallest existing Id - 1)`. This avoids collisions with positive IDs coming from Shopify.
- The `State` enum on `Shpfy Customer` tracks the Shopify customer account lifecycle (Disabled, Invited, Enabled, Declined). This is informational -- it does not gate sync behavior.
- Cascade deletes on `Shpfy Customer` remove all related addresses, tags, and metafields.
- The sync respects paired boolean flags on the Shop record: `Customer Import From Shopify` controls direction, `Shopify Can Update Customer` and `Can Update Shopify Customer` control write permissions in each direction.
