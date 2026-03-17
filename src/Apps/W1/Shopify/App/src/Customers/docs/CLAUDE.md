# Customers

Bidirectional sync between Shopify customers and BC customers. The Shpfy Customer table (ID 30105) links to BC via a `Customer SystemId` Guid. Customer addresses live in a separate table keyed by a BigInteger `Id` that uses negative values (-1, -2, ...) for BC-created addresses not yet synced to Shopify, assigned in the `OnInsert` trigger of `ShpfyCustomerAddress.Table.al`.

## How it works

`ShpfySyncCustomers.Codeunit.al` orchestrates both directions. Import mode is controlled by the Shop's `Customer Import From Shopify` setting -- `AllCustomers` pulls everyone, `WithOrderImport` only refreshes already-known customers when the shop also has `Shopify Can Update Customer` enabled. In both cases the codeunit retrieves a `Dictionary of [BigInteger, DateTime]` of Shopify customer IDs, compares `Updated At` and `Last Updated by BC` timestamps to skip unchanged records, then feeds each changed customer into `ShpfyCustomerImport` inside a Commit/ClearLastError loop so one failure does not abort the batch.

For the BC-to-Shopify direction, `ShpfyCustomerExport.Codeunit.al` iterates BC customers, calls `ShpfyCustomerMapping` to find or create the Shopify counterpart, then pushes updates through `ShpfyCustomerAPI`. Creating a customer in Shopify requires a non-empty email -- records without one are logged as skipped. The export also syncs metafields if `Customer Metafields To Shopify` is enabled on the shop.

Mapping strategy is selected by the Shop's `Customer Mapping Type` enum, dispatched through the `Shpfy ICustomer Mapping` interface. If both Name fields are blank, `ShpfyCustomerMapping.DoMapping` forces the `By EMail/Phone` strategy regardless of the shop setting. The `ByEmailPhone` strategy in `ShpfyCustomerMapping.DoFindMapping` uses a case-insensitive email filter (`'@' + Email`) and a fuzzy phone filter -- `CreatePhoneFilter` strips all non-digits, trims leading zeros, then inserts `*` wildcards between every digit to match any formatting.

## Things to know

- Customer state in Shopify (Disabled, Invited, Enabled, Declined in `ShpfyCustomerState.Enum.al`) is unrelated to BC's Blocked field -- there is no automatic mapping between them.
- Name assembly for export is configurable per shop via `Name Source`, `Name 2 Source`, and `Contact Source` fields, each selecting a strategy like CompanyName, FirstAndLastName, or LastAndFirstName.
- Multi-email addresses in BC (semicolon or comma separated) are handled by export -- only the first email is sent to Shopify.
- `ShpfyCustomerEvents.Codeunit.al` publishes integration events at every stage: before/after find mapping, before/after create/update customer, and before/after find customer template. These are the primary extension points for partner customizations.
- County handling on export requires a matching `Shpfy Tax Area` row. If the shop's `County Source` is Code and the county string exceeds the field length, export raises a hard error rather than truncating silently.
- The `AddCustomerToShopify` report provides the manual "push" action that replaced the removed auto-export behavior.
