# Customers data model

## Tables

### Shpfy Customer (30105)
Stores Shopify customer master data.

**Location:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Customers\Tables\ShpfyCustomer.Table.al`

**Key fields:**
- `Id` (BigInteger) -- Shopify customer ID, primary key
- `First Name` (Text[100]) -- Customer first name
- `Last Name` (Text[100]) -- Customer last name
- `Email` (Text[100]) -- Email address
- `Phone No.` (Text[30]) -- Phone number
- `Accepts Marketing` (Boolean) -- Opted in to marketing
- `Accepts Marketing Update At` (DateTime) -- When marketing preference changed
- `ISO Currency Code` (Code[3]) -- Preferred currency
- `Tax Exempt` (Boolean) -- Exempt from tax
- `Verified Email` (Boolean) -- Email verified
- `State` (Enum Shpfy Customer State) -- Disabled, Invited, Enabled, Declined
- `Note` (Blob) -- Customer notes
- `Created At`, `Updated At` (DateTime) -- Shopify timestamps
- `Last Updated by BC` (DateTime) -- BC modification timestamp
- `Customer SystemId` (Guid) -- Link to BC Customer
- `Shop Id` (Integer) -- Link to shop

**Calculated fields:**
- `Customer No.` (Code[20]) -- FlowField from Customer

**Methods:**
- `GetCommaSeparatedTags()` -- Returns customer tags
- `GetNote()` -- Reads note from blob
- `SetNote(Text)` -- Writes note to blob
- `UpdateTags(Text)` -- Updates tags via Shpfy Tag table

**Relationships:**
- N:1 with Customer (via Customer SystemId)
- 1:N with Shpfy Customer Address (via Customer Id)
- 1:N with Shpfy Tag (via Parent Id)

**Indexes:**
- PK: Id (clustered)
- Idx1: Customer SystemId
- Idx2: Shop Id

### Shpfy Customer Address (30106)
Stores customer addresses.

**Location:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Customers\Tables\ShpfyCustomerAddress.Table.al`

**Key fields:**
- `Id` (BigInteger) -- Address ID, primary key
- `Customer Id` (BigInteger) -- Parent customer
- `Company` (Text[100]) -- Company name
- `First Name` (Text[50]) -- First name
- `Last Name` (Text[50]) -- Last name
- `Address 1` (Text[100]) -- Address line 1
- `Address 2` (Text[100]) -- Address line 2
- `Zip` (Code[20]) -- Postal code
- `City` (Text[50]) -- City
- `Country/Region Code` (Code[2]) -- 2-letter country code
- `Country/Region Name` (Text[50]) -- Country name
- `Province Code` (Code[10]) -- Province/state code
- `Province Name` (Text[50]) -- Province/state name
- `Phone` (Text[30]) -- Phone number
- `Default` (Boolean) -- Default address for customer
- `CustomerSystemId` (Guid) -- Link to BC Customer

**Calculated fields:**
- `Customer No.` (Code[20]) -- FlowField from Customer

**Trigger logic:**
- OnInsert: Auto-generates negative ID if Id = 0; ensures at least one default address per customer

**Indexes:**
- PK: Id (clustered)
- Key2: Customer Id, Default

### Shpfy Tax Area (30109)
Maps country/county to BC tax configuration.

**Location:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Customers\Tables\ShpfyTaxArea.Table.al`

**Key fields:**
- `Country/Region Code` (Code[20]) -- Country code, part of PK
- `County` (Text[50]) -- County/province name, part of PK
- `Tax Area Code` (Code[20]) -- BC Tax Area
- `Tax Liable` (Boolean) -- Tax liability flag
- `VAT Bus. Posting Group` (Code[20]) -- VAT business posting group
- `County Code` (Code[10]) -- County code for lookup

**Usage:** Looked up during customer/order import to set tax fields on BC customer or sales document.

**Indexes:**
- PK: Country/Region Code, County (clustered)
- Indx01: Country/Region Code, County Code

## Enums

### Shpfy Customer Mapping (30106)
Defines how Shopify customers map to BC customers (extensible, implements ICustomer Mapping interface).

**Location:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Customers\Enums\ShpfyCustomerMapping.Enum.al`

- `By EMail/Phone` (0) -- Match by email or phone, create if not found
  - Implementation: Shpfy Cust. By Email/Phone (30112)
- `By Bill-to Info` (1) -- Match by bill-to address info
  - Implementation: Shpfy Cust. By Bill-to (30113)
- `DefaultCustomer` (2) -- Always use Shop."Default Customer No."
  - Implementation: Shpfy Cust. By Default Cust. (30114)

### Shpfy Customer Import Range (30107)
Controls which customers are imported.

- `AllCustomers` -- Import all customers from Shopify
- `WithOrderImport` -- Import only customers associated with orders
- `None` -- No customer import

### Shpfy Customer State (30108)
Shopify customer account state.

- `Disabled` (0)
- `Invited` (1) -- Invited to create account
- `Enabled` (2) -- Active account
- `Declined` (3) -- Declined invitation

### Shpfy Name Source (30109)
How to derive BC customer name fields from Shopify data.

- `None` -- Leave empty
- `FirstAndLastName` -- "First Last"
- `LastAndFirstName` -- "Last, First"
- `CompanyName` -- Use company field

**Used for:**
- Shop."Name Source" -- Customer.Name
- Shop."Name 2 Source" -- Customer."Name 2"
- Shop."Contact Source" -- Customer.Contact

### Shpfy County Source (30110)
How to resolve county from Shopify address.

- `Code` -- Use Province Code
- `Name` -- Use Province Name
- `JsonCode` -- Parse from JSON
- `JsonName` -- Parse from JSON

### Shpfy Tax By (30111)
Tax calculation method.

- `Tax`
- `VAT`

### Shpfy Tax Type (30112)
Tax type (used in obsolete Shpfy Province table).

- `Normal`
- `Harmonized`

## Relationships

```
Shpfy Shop (1) ----< (N) Shpfy Customer
                         |
                         +----< (N) Shpfy Customer Address
                         |
                         +----< (N) Shpfy Tag (by Parent Id)

Customer (1) ----< (N) Shpfy Customer
         |
         +----< (N) Shpfy Customer Address

Shpfy Tax Area -- lookup table (no direct FK)
```

## Key indexes

**Shpfy Customer:**
- PK: Id (clustered)
- Idx1: Customer SystemId (for reverse lookup from BC)
- Idx2: Shop Id (for shop-scoped queries)

**Shpfy Customer Address:**
- PK: Id (clustered)
- Key2: Customer Id, Default (find default address)

**Shpfy Tax Area:**
- PK: Country/Region Code, County (clustered)
- Indx01: Country/Region Code, County Code (alternative lookup)
