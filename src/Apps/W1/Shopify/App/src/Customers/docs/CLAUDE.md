# Customers

Maps Shopify customers to Business Central customer records and handles bidirectional synchronization. This module owns the identity-resolution problem -- given a Shopify order, which BC customer should it land on? -- and keeps that boundary clean from the Orders module by exposing mapping through `ShpfyCustomerMapping.Codeunit.al`.

## How it works

When a Shopify customer needs to be resolved, `ShpfyCustomerMapping` dispatches to one of three strategies via the `ICustomerMapping` interface. The strategy is selected from `Shop."Customer Mapping Type"`, but if both Name and Name2 are blank in the incoming JSON, it falls back to `ByEMail/Phone` regardless of configuration. `ShpfyCustByEmailPhone` imports the customer from Shopify and creates a BC customer from the default address. `ShpfyCustByBillto` matches on the full bill-to address (address, zip, city, country) plus the computed name, iterating over all addresses for that Shopify customer. `ShpfyCustByDefaultCust` simply returns `Shop."Default Customer No."` -- no lookup at all.

Name computation is polymorphic too: `Shop."Name Source"`, `"Name 2 Source"`, and `"Contact Source"` each point to an `ICustomerName` implementation (CompanyName, FirstAndLastName, LastAndFirstName, or Empty). County resolution works the same way through `ICounty` and `ICountyFromJson` -- either the province code or the province name, controlled by `Shop."County Source"`.

Customer creation uses `ShpfyCreateCustomer`, which picks a `CustomerTemplate` by country code (the `ShpfyCustomerTemplate` table keyed on shop + country). If no country-specific template exists, it auto-creates an empty row and falls back to the shop-level default. Tax area mapping happens in `ShpfyUpdateCustomer.FillInCustomerFields` -- a `ShpfyTaxArea` record keyed on country + province name sets tax area code, tax liable, and VAT bus. posting group on the BC customer.

## Things to know

- Phone matching in `ShpfyCustomerMapping.CreatePhoneFilter` strips all non-digits, trims leading zeros, then inserts a wildcard `*` before every digit -- so `+1 (555) 012-3456` becomes `*5*5*5*0*1*2*3*4*5*6`. This is intentionally fuzzy to handle formatting differences.
- `ShpfyCustomerAddress.OnInsert` auto-assigns negative IDs (starting at -1, decrementing) for locally-created addresses that have not yet been synced to Shopify. The first address for a customer is automatically set as default.
- The old `ShpfyProvince` table (30108) is removed as of v25; it was replaced by `ShpfyTaxArea` which keys on country code + county name instead of Shopify province IDs.
- `ShpfySyncCountries` reads province data from an embedded YAML resource (`data/provinces.yml`) using `NavApp.GetResource`, not from the Shopify API. It populates `ShpfyTaxArea` rows during country sync.
- The `CustomerImportRange` enum controls when customers are pulled: `None` skips import entirely, `WithOrderImport` only imports customers encountered during order sync, and `AllCustomers` does a full pull via `RetrieveShopifyCustomerIds`.
- `ShpfyCustomerEvents` exposes integration events at every lifecycle point (before/after create, update, find mapping, find template). These are the primary extensibility mechanism for partner customizations.
- When exporting customers to Shopify, multi-value email fields (semicolon or comma separated) are split and only the first address is sent.
