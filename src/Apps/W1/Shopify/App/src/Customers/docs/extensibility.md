# Customers extensibility

Events are defined in `ShpfyCustomerEvents` (codeunit 30115). The four
interfaces handle mapping strategy, name formatting, and county resolution.

## Customizing customer creation

- `OnBeforeCreateCustomer` -- set Handled to replace the entire customer
  creation flow. Receives Shop, Customer Address, and the Customer record to
  populate.
- `OnAfterCreateCustomer` -- post-creation hook for setting custom fields,
  dimensions, or triggering downstream processes.
- `OnBeforeFindCustomerTemplate` / `OnAfterFindCustomerTemplate` -- override
  which Customer Template is selected for a given country code. OnBefore can
  set Handled to bypass the default template lookup.

*Updated: 2026-07-29 -- creation hooks may receive a fallback address when no
default Shopify address exists*

When customer creation is triggered by order-time by-email/phone mapping, the
Customer Address passed into these hooks is the Shopify default address when
available, otherwise the first address for that Shopify customer. Extensions
that require the Shopify default address should check the address `Default`
flag themselves.

## Customizing customer mapping

- `OnBeforeFindMapping` -- fires before the default email/phone matching in
  `ShpfyCustomerMapping.FindMapping`. Set Handled and populate the Customer
  record to completely bypass built-in logic. Works for both ShopifyToBC and
  BCToShopify directions (check the Direction parameter).
- `OnAfterFindMapping` -- fires after a successful match, allowing you to
  adjust the mapping or update related records.

## Customizing customer updates

- `OnBeforeUpdateCustomer` / `OnAfterUpdateCustomer` -- fire around the
  Shopify-to-BC customer update flow. OnBefore can set Handled.
- `OnBeforeSendCreateShopifyCustomer` / `OnBeforeSendUpdateShopifyCustomer` --
  last chance to modify the Shopify Customer and Address records before they
  are serialized and sent to the API.

## Interfaces

**ICustomerMapping** -- the strategy interface for order-time customer
resolution. Three built-in implementations selected via the extensible
`Shpfy Customer Mapping` enum:

- `ShpfyCustByEmailPhone` -- matches on email then phone
- `ShpfyCustByBillto` -- matches on bill-to name and address fields
- `ShpfyCustByDefaultCust` -- always returns the Shop's default customer

To add a custom strategy, extend the enum with a new value and implement
`ICustomerMapping`. The `DoMapping` procedure receives a JSON object with
Name, Name2, Address, PostCode, City, County, CountryCode fields.

**ICustomerName** -- controls how the BC Customer Name field is composed
from Shopify first/last/company name. Implementations:
`ShpfyNameisFirstLastName`, `ShpfyNameisLastFirstName`,
`ShpfyNameisCompanyName`, `ShpfyNameisEmpty`. Selected via the "Name Source"
enum on the Shop.

**ICounty** -- converts a stored Shopify address record's province data to a
BC County string. Two implementations: `ShpfyCountyCode` (province code) and
`ShpfyCountyName` (province name). Selected via the "County Source" enum.

Customer and company export now filter `Shpfy Tax Area` with Shopify's ISO
country code before applying the county source. Custom tax-area records used by
export should therefore be keyed by ISO code.

*Updated: 2026-07-29 -- tax-area filtering during export uses ISO country
codes*

**ICountyFromJson** -- same as ICounty but operates on a raw JSON address
object during API response parsing. Implementations:
`ShpfyCountyFromJsonCode` and `ShpfyCountyFromJsonName`.
