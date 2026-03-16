# Transactions data model

## Tables

### Shpfy Order Transaction (30133)

Stores transaction details from Shopify orders.

**File:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Transactions\Tables\ShpfyOrderTransaction.Table.al`

**Key fields:**
- Shopify Transaction Id (PK)
- Shopify Order Id
- Type (Enum: Authorization, Capture, Sale, Void, Refund)
- Status (Enum: Pending, Failure, Success, Error, Awaiting Response, Unknown)
- Gateway (Text 30)
- Credit Card Company (Text 50)
- Amount, Currency
- Presentment Amount, Presentment Currency
- Gift Card Id
- Parent Id (self-reference for transaction hierarchy)
- Refund Id
- Created At
- Manual Payment Gateway (Boolean)
- Shop (Code 20)

**Calculated fields:**
- Sales Document No. (from Sales Header)
- Posted Invoice No. (from Sales Invoice Header)
- Payment Method (from Shpfy Payment Method Mapping)
- Used (Boolean, exists in Cust. Ledger Entry)

**Internal fields (Access = Internal):**
- Credit Card Bin, Credit Card Number
- AVS Result Code, CVV Result Code

**Keys:**
- PK: Shopify Transaction Id
- Idx001: Gift Card Id (SumIndex on Amount)
- Idx002: Created At
- Idx003: Type
- Key5: Shopify Order Id, Status

### Shpfy Payment Method Mapping (30134)

Maps Shopify payment gateways to Business Central payment methods.

**File:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Transactions\Tables\ShpfyPaymentMethodMapping.Table.al`

**Access:** Internal

**Key fields:**
- Shop Code (PK)
- Gateway (PK, TableRelation: Shpfy Transaction Gateway)
- Credit Card Company (PK, TableRelation: Shpfy Credit Card Company)
- Payment Method Code (TableRelation: Payment Method)
- Manual Payment Gateway (Boolean, not editable)

### Shpfy Suggest Payment (30154)

Temporary table for suggesting payment journal entries.

**File:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Transactions\Tables\ShpfySuggestPayment.Table.al`

**Access:** Internal
**TableType:** Temporary

**Key fields:**
- Entry No. (PK)
- Shop Code
- Shpfy Transaction Id
- Customer Ledger Entry No.
- Customer No.
- Invoice No., Credit Memo No.
- Amount, Currency Code
- Gateway
- Shpfy Order Id, Shpfy Gift Card Id
- Payment Method Code

**Calculated fields:**
- Shpfy Order No. (from Shpfy Order Header)

### Shpfy Credit Card Company (30132)

Lookup table of credit card companies.

**File:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Transactions\Tables\ShpfyCreditCardCompany.Table.al`

**Access:** Internal

**Key fields:**
- Name (PK, Text 50)

### Shpfy Transaction Gateway (30135)

Lookup table of transaction gateways.

**File:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Transactions\Tables\ShpfyTransactionGateway.Table.al`

**Access:** Internal

**Key fields:**
- Name (PK, Text 30)

## Relationships

```
Shpfy Order Transaction
├── Shpfy Order Header (via Shopify Order Id)
├── Sales Header (via Shopify Order Id)
├── Sales Invoice Header (via Shopify Order Id)
├── Shpfy Order Transaction (self-reference via Parent Id)
├── Cust. Ledger Entry (via Shopify Transaction Id)
└── Shpfy Payment Method Mapping (via Shop, Gateway, Credit Card Company)
    ├── Payment Method
    ├── Shpfy Transaction Gateway (via Gateway)
    └── Shpfy Credit Card Company (via Credit Card Company)

Shpfy Suggest Payment
├── Shpfy Shop (via Shop Code)
├── Shpfy Order Transaction (via Shpfy Transaction Id)
├── Cust. Ledger Entry (via Customer Ledger Entry No.)
├── Customer (via Customer No.)
├── Sales Invoice Header (via Invoice No.)
├── Sales Cr.Memo Header (via Credit Memo No.)
└── Currency (via Currency Code)
```

## Enums

### Shpfy Transaction Type (30134)

**File:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Transactions\Enums\ShpfyTransactionType.Enum.al`

Values:
- (blank)
- Authorization
- Capture
- Sale
- Void
- Refund

### Shpfy Transaction Status (30133)

**File:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Transactions\Enums\ShpfyTransactionStatus.Enum.al`

Values:
- (blank)
- Pending
- Failure
- Success
- Error
- Awaiting Response
- Unknown
