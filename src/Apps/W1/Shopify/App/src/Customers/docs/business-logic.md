# Customers business logic

## Synchronization flows

### Import from Shopify (Shpfy Sync Customers, Shpfy Customer Import)

**Location:**
- `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Customers\Codeunits\ShpfySyncCustomers.Codeunit.al`
- `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Customers\Codeunits\ShpfyCustomerImport.Codeunit.al`

**Trigger:** Shop."Customer Import From Shopify" = AllCustomers or WithOrderImport

**Flow:**
1. Shpfy Sync Customers.Run(Shop) calls ImportCustomersFromShopify(CreateCustomers)
   - CreateCustomers = true if "Customer Import From Shopify" = AllCustomers
   - CreateCustomers = false if "Customer Import From Shopify" = WithOrderImport
2. Retrieve customer IDs via Shpfy Customer API.RetrieveShopifyCustomerIds() (returns Dictionary of [BigInteger, DateTime])
3. For each customer ID:
   - If customer exists locally and Updated At > Customer."Updated At" and Customer."Last Updated by BC", mark for import
   - If customer doesn't exist and CreateCustomers = true, mark for import
   - If customer doesn't exist and CreateCustomers = false, skip (only import when referenced by order)
4. For each marked customer:
   - Shpfy Customer Import.Run() retrieves full customer data via CustomerApi.RetrieveShopifyCustomer()
   - Retrieve addresses via CustomerApi (stored in Shpfy Customer Address)
   - Attempt mapping via Shpfy Customer Mapping.FindMapping()
   - If mapping found and Shop."Shopify Can Update Customer", call Shpfy Update Customer
   - If no mapping and Shop."Auto Create Unknown Customers", call Shpfy Create Customer
5. Update Shop."Last Sync Time" (Shpfy Synchronization Info, type = Customers)

### Export to Shopify (Shpfy Sync Customers, Shpfy Customer Export)

**Location:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Customers\Codeunits\ShpfyCustomerExport.Codeunit.al`

**Trigger:** Shop."Can Update Shopify Customer" = true

**Flow:**
1. Shpfy Sync Customers calls SyncCustomersToShopify()
2. Shpfy Customer Export.Run(Customer) processes BC customers
3. For each customer, if mapped to Shopify customer:
   - Update Shopify customer data via Shpfy Customer API
   - Update addresses
   - Set Last Updated by BC timestamp

**Manual export:** Report "Shpfy Add Customer to Shopify" creates new Shopify customers.

## Mapping strategies

### By Email/Phone (Shpfy Cust. By Email/Phone)

**Location:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Customers\Codeunits\ShpfyCustByEmailPhone.Codeunit.al`

**Shopify to BC:**
1. If Shpfy Customer.Email is not empty:
   - Search BC Customer where "E-Mail" matches (case-insensitive)
   - If found, map to that customer
2. If not found and Phone No. is not empty:
   - Create phone filter (handles various formats)
   - Search BC Customer where "Phone No." matches
   - If found, map to that customer
3. If not found and AllowCreate = true, create new BC customer from template

**BC to Shopify:**
1. Search Shpfy Customer where "Customer SystemId" = BC Customer.SystemId
2. If not found, search Shopify by email via CustomerApi.FindIdByEmail()
3. If not found, search Shopify by phone via CustomerApi.FindIdByPhone()
4. If found, map; if not found and CreateCustomersInShopify = true, create new Shopify customer

### By Bill-to Info (Shpfy Cust. By Bill-to)

**Location:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Customers\Codeunits\ShpfyCustByBillto.Codeunit.al`

**Shopify to BC:**
1. Get default address (Shpfy Customer Address where Default = true)
2. Match BC Customer by bill-to address fields:
   - Name, Address, City, Post Code, County, Country/Region Code
   - Uses fuzzy matching on name and address
3. If found, map to that customer
4. Falls back to email/phone matching if address match fails

### Default Customer (Shpfy Cust. By Default Cust.)

**Location:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Customers\Codeunits\ShpfyCustByDefaultCust.Codeunit.al`

**Always returns Shop."Default Customer No."** -- all Shopify customers map to same BC customer.

**Use case:** For shops that don't need individual customer tracking in BC.

## Customer creation (from Shopify)

### Shpfy Create Customer (30122)

**Location:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Customers\Codeunits\ShpfyCreateCustomer.Codeunit.al`

**Flow:**
1. Read Shpfy Customer and default Shpfy Customer Address
2. Create BC Customer from template (Shop."Customer Templ. Code")
3. Derive name fields using Name Source rules:
   - Name: Apply Shop."Name Source" to First Name, Last Name, Company
   - Name 2: Apply Shop."Name 2 Source"
   - Contact: Apply Shop."Contact Source"
4. Set contact fields:
   - "E-Mail" from Email
   - "Phone No." from Phone No.
5. Set address from default Shpfy Customer Address:
   - Address, Address 2, City, Post Code
   - Country/Region Code
   - County via county resolution (see below)
6. Set tax fields from Shpfy Tax Area lookup:
   - Tax Area Code, Tax Liable (if Tax By = Tax)
   - VAT Bus. Posting Group (if Tax By = VAT)
7. Set Currency Code from ISO Currency Code
8. Set Shpfy Customer."Customer SystemId" = new customer.SystemId

## County resolution

### County interfaces and implementations

**Interface:** Shpfy ICounty (maps province to BC county)

**Implementations:**
- **Shpfy County Code (30124)** -- Uses Province Code directly as County
- **Shpfy County Name (30125)** -- Uses Province Name directly as County

**Interface:** Shpfy ICounty From Json (parses county from JSON address)

**Implementations:**
- **Shpfy County From Json Code (30126)** -- Extracts province_code from JSON
- **Shpfy County From Json Name (30127)** -- Extracts province from JSON

**Selection:** Shop."County Source" enum selects implementation.

### Tax area lookup

After resolving county, lookup Shpfy Tax Area:

```al
TaxArea.Get(CountryRegionCode, County);
Customer."Tax Area Code" := TaxArea."Tax Area Code";
Customer."Tax Liable" := TaxArea."Tax Liable";
Customer."VAT Bus. Posting Group" := TaxArea."VAT Bus. Posting Group";
```

**Setup:** Shpfy Tax Areas page (30109) allows manual mapping of country/county to tax configuration.

## Name derivation

### Name Source enum logic

Implemented via Shpfy ICustomer Name interface.

**Implementations:**
- **Shpfy Name is Empty (30130)** -- Returns empty string
- **Shpfy Name is First Last Name (30131)** -- Returns "First Last"
- **Shpfy Name is Last First Name (30132)** -- Returns "Last, First"
- **Shpfy Name is Company Name (30133)** -- Returns Company field

**Application:**
- Shop."Name Source" → Customer.Name
- Shop."Name 2 Source" → Customer."Name 2"
- Shop."Contact Source" → Customer.Contact

**Example:**
If Name Source = CompanyName, Name 2 Source = FirstAndLastName:
- Customer.Name = "Acme Corp"
- Customer."Name 2" = "John Smith"

## Address synchronization

**Multiple addresses:** All addresses imported to Shpfy Customer Address table.

**Default address:** Address where Default = true used to populate BC Customer address fields.

**Updates:** If Shopify customer updated, BC customer address updated if "Shopify Can Update Customer" = true.

## Events for extensibility

### Shpfy Customer Events (30121)

**Published events:**
- OnBeforeFindMapping, OnAfterFindMapping -- override or supplement mapping logic
- OnBeforeCreateCustomer, OnAfterCreateCustomer -- customize customer creation
- OnBeforeUpdateCustomer, OnAfterUpdateCustomer -- customize customer updates

## Key configuration (Shpfy Shop fields)

**Customer import:**
- `Customer Import From Shopify` -- AllCustomers, WithOrderImport, None
- `Auto Create Unknown Customers` -- Create BC customers from Shopify
- `Customer Templ. Code` -- Template for new customers
- `Shopify Can Update Customer` -- Allow Shopify to update BC customers

**Customer export:**
- `Can Update Shopify Customer` -- Allow BC to update Shopify customers

**Mapping:**
- `Customer Mapping Type` -- By EMail/Phone, By Bill-to Info, DefaultCustomer
- `Default Customer No.` -- Used when mapping type = DefaultCustomer

**Name and address:**
- `Name Source`, `Name 2 Source`, `Contact Source` -- Name derivation rules
- `County Source` -- Code, Name, JsonCode, JsonName

## Country and province sync

### Shpfy Sync Countries (30128)

**Purpose:** Downloads country and province data from Shopify to populate tax area mapping.

**Report:** "Shpfy Sync Countries" (30111)

**Flow:**
1. Retrieve countries via GraphQL (countries query)
2. For each country, retrieve provinces
3. Can be used to pre-populate Shpfy Tax Area with all countries/provinces
4. User then manually maps to BC Tax Area Code or VAT Bus. Posting Group
