# Customers

Customer sync is bidirectional -- import from Shopify, export from BC -- controlled by `Shpfy Shop` fields `Customer Import From Shopify` and `Can Update Shopify Customer`. `ShpfySyncCustomers.Codeunit.al` orchestrates both directions in a single run, using `Updated At` / `Last Updated by BC` timestamps to skip unchanged records.

## Mapping strategies

The `Shpfy ICustomer Mapping` interface (`ShpfyICustomerMapping.Interface.al`) dispatches via the `Shpfy Customer Mapping` enum on the Shop card. Three implementations exist:

- **By Email/Phone** (`ShpfyCustByEmailPhone.Codeunit.al`) -- imports the Shopify customer if not already local, then resolves by `Customer SystemId`. Falls back to creating a BC customer via `Shpfy Create Customer` when `AllowCreate` is true.
- **By Bill-to** (`ShpfyCustByBillto.Codeunit.al`) -- matches on address fields (Address, Zip, City, Country) plus the computed Name/Name2 using the shop's name source settings. The most complex strategy because it iterates all addresses for a Shopify customer and tries both name and address equality.
- **Default Customer** (`ShpfyCustByDefaultCust.Codeunit.al`) -- always returns `Shop."Default Customer No."`. No matching logic at all.

A subtlety in `ShpfyCustomerMapping.Codeunit.al`: when both Name and Name2 from the order are empty, the mapping silently overrides to `By EMail/Phone` regardless of the shop setting. This prevents the Bill-to strategy from failing on anonymous checkouts.

## SystemId-based linking

`Shpfy Customer` links to BC via `Customer SystemId` (a Guid), not `Customer No.`. The `Customer No.` field is a FlowField calculated from the SystemId. `FindMapping` in `ShpfyCustomerMapping.Codeunit.al` validates the link on every call -- if `GetBySystemId` fails (customer deleted), it clears the Guid and re-runs discovery. The BCToShopify direction also queries the Shopify API by email/phone as a fallback.

## Customer name parsing

`Shpfy ICustomer Name` interface with four implementations controlled by the `Shpfy Name Source` enum: `CompanyName`, `FirstAndLastName`, `LastAndFirstName`, and `None` (empty). The Shop card exposes three independent name-source fields -- `Name Source`, `Name 2 Source`, `Contact Source` -- each choosing an implementation independently. On export, `SpiltNameIntoFirstAndLastName` in `ShpfyCustomerExport.Codeunit.al` reverses the process, splitting a BC name string back into Shopify first/last name fields.

## County mapping

Two parallel interfaces: `Shpfy ICounty` resolves county from a `Shpfy Customer Address` or `Shpfy Company Location` record, while `Shpfy ICounty From Json` resolves from raw JSON during import. The `Shpfy County Source` enum implements both, with `Code` and `Name` variants. County resolution depends on the `Shpfy Tax Area` table for province code/name lookups.

## Address negative ID allocation

`ShpfyCustomerAddress.Table.al` uses negative IDs for BC-created addresses (OnInsert assigns `Min(-1, lowest existing Id - 1)`). This reserves the positive ID space for Shopify-assigned identifiers, so locally created addresses never collide with real Shopify addresses.

## Customer templates

`Shpfy Customer Template` (keyed by Shop Code + Country/Region Code) lets you assign different `Customer Templ. Code` and `Default Customer No.` per country. `ShpfyCreateCustomer.Codeunit.al` looks up the template by the address's country code, falling back to the shop-level `Customer Templ. Code` if no country-specific override exists. Templates that don't exist yet are auto-inserted as blank rows for later configuration.
