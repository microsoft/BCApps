# Companies data model

## Tables

### Shpfy Company (30150)
Stores Shopify B2B company master data.

**Location:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Companies\Tables\ShpfyCompany.Table.al`

**Key fields:**
- `Id` (BigInteger) -- Shopify company ID, primary key
- `Name` (Text[500]) -- Company name
- `Note` (Blob) -- Company notes
- `Created At`, `Updated At` (DateTime) -- Shopify timestamps
- `Last Updated by BC` (DateTime) -- BC modification timestamp
- `Customer SystemId` (Guid) -- Link to BC Customer (company level)
- `Shop Id` (Integer) -- Link to shop
- `Shop Code` (Code[20]) -- Shop code
- `Main Contact Customer Id` (BigInteger) -- Link to Shpfy Customer (main contact)
- `Main Contact Id` (BigInteger) -- Shopify contact ID
- `Location Id` (BigInteger) -- Default location ID
- `External Id` (Text[500]) -- External system ID

**Calculated fields:**
- `Customer No.` (Code[20]) -- FlowField from Customer

**Methods:**
- `GetNote()` -- Reads note from blob
- `SetNote(Text)` -- Writes note to blob

**Relationships:**
- N:1 with Customer (via Customer SystemId)
- 1:N with Shpfy Company Location (via Company SystemId)
- N:1 with Shpfy Customer (main contact, via Main Contact Customer Id)

**OnDelete trigger:** Deletes associated Shpfy Company Location records.

**Indexes:**
- PK: Id (clustered)
- Idx1: Customer SystemId
- Idx2: Shop Id

### Shpfy Company Location (30151)
Stores company locations (ship-to addresses).

**Location:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Companies\Tables\ShpfyCompanyLocation.Table.al`

**Key fields:**
- `Id` (BigInteger) -- Location ID, primary key
- `Company SystemId` (Guid) -- Parent company
- `Name` (Text[100]) -- Location name (editable = false)
- `Recipient` (Text[100]) -- Company/Attention recipient
- `Address` (Text[100]) -- Address line 1
- `Address 2` (Text[100]) -- Address line 2
- `Zip` (Code[20]) -- Postal code
- `City` (Text[50]) -- City
- `Province Code` (Code[10]) -- Province/state code
- `Province Name` (Text[50]) -- Province/state name
- `Country/Region Code` (Code[2]) -- 2-letter country code
- `Phone No.` (Text[30]) -- Phone number
- `Tax Registration Id` (Text[150]) -- Tax registration ID
- `Default` (Boolean) -- Default location for company
- `Shpfy Payment Terms Id` (BigInteger) -- Shopify payment terms
- `Sell-to Customer No.` (Code[20]) -- BC customer for sell-to
- `Bill-to Customer No.` (Code[20]) -- BC customer for bill-to
- `Customer Id` (Guid) -- Associated customer system ID

**Calculated fields:**
- `Company Name` (Text[500]) -- FlowField from Shpfy Company.Name
- `Shpfy Payment Term` (Text[150]) -- FlowField from Shpfy Payment Terms

**Validation:**
- Bill-to Customer No. requires Sell-to Customer No.

**Indexes:**
- PK: Id (clustered)
- Idx1: Company SystemId

## Enums

### Shpfy Company Mapping (30151)
Defines how Shopify companies map to BC customers (extensible, implements ICompany Mapping interface).

**Location:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Companies\Enums\ShpfyCompanyMapping.Enum.al`

- `By Email/Phone` (0) -- Match by main contact email/phone
  - Implementation: Shpfy Comp. By Email/Phone (30158)
- `DefaultCompany` (2) -- Always use default company
  - Implementation: Shpfy Comp. By Default Comp. (30160)
- `By Tax Id` (3) -- Match by tax registration ID
  - Implementation: Shpfy Comp. By Tax Id (30159)

### Shpfy Company Import Range (30152)
Controls which companies are imported.

- `AllCompanies` -- Import all companies from Shopify
- `WithOrderImport` -- Import only companies associated with orders
- `None` -- No company import

### Shpfy Comp Tax Id Mapping (30153)
How to map Shopify Tax Registration Id to BC (extensible, implements Shpfy Tax Registration Id Mapping interface).

**Location:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Companies\Enums\ShpfyCompTaxIdMapping.Enum.al`

- `Tax Registration No.` (0) -- Use BC Customer."Tax Registration No." field
  - Implementation: Shpfy Tax Registration No. (30161)
- `VAT Registration No.` (1) -- Use BC Customer."VAT Registration No." field
  - Implementation: Shpfy VAT Registration No. (30162)

### Shpfy Default Cont Permission (30154)
Default contact permissions for company locations.

- `None` -- No permissions
- `Ordering_only` -- Can place orders only
- `Full` -- Full permissions

## Relationships

```
Shpfy Shop (1) ----< (N) Shpfy Company
                         |
                         +----< (N) Shpfy Company Location
                         |
                         +--- (N:1) Shpfy Customer (main contact)

Customer (1) ----< (N) Shpfy Company
         |
         +----< (N) Shpfy Company Location (via Sell-to/Bill-to Customer No.)

Shpfy Payment Terms (1) ----< (N) Shpfy Company Location
```

## Key indexes

**Shpfy Company:**
- PK: Id (clustered)
- Idx1: Customer SystemId (for reverse lookup from BC)
- Idx2: Shop Id (for shop-scoped queries)

**Shpfy Company Location:**
- PK: Id (clustered)
- Idx1: Company SystemId (find locations for company)
