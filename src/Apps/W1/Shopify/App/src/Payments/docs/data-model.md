# Payments data model

## Tables

### Shpfy Payment Transaction (30124)

Individual payment transaction records within payouts.

**File:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Payments\Tables\ShpfyPaymentTransaction.Table.al`

**Key fields:**
- Id (PK)
- Type (Enum: Shpfy Payment Trans. Type)
- Test (Boolean)
- Payout Id
- Currency (Code 10)
- Amount, Fee, Net Amount (Decimal)
- Source Id, Source Type (Enum)
- Source Order Transaction Id
- Source Order Id
- Processed At (DateTime)
- Shop Code

**Calculated fields:**
- Invoice No. (from Sales Invoice Header via Source Order Id)

**Keys:**
- PK: Id
- Idx1: Payout Id
- Idx2: Shop Code

### Shpfy Payout (30125)

Payout records from Shopify Payments.

**File:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Payments\Tables\ShpfyPayout.Table.al`

**Key fields:**
- Id (PK)
- Status (Enum: Scheduled, In Transit, Paid, Failed, Canceled)
- Date
- Currency (Code 10)
- Amount (total payout amount)
- Adjustments Fee Amount, Adjustments Gross Amount
- Charges Fee Amount, Charges Gross Amount
- Refunds Fee Amount, Refunds Gross Amount
- Reserved Funds Fee Amount, Reserved Funds Gross Amount
- Retried Payouts Fee Amount, Retried Payouts Gross Amount
- External Trace Id

**Keys:**
- PK: Id
- Key1: Date

### Shpfy Dispute (30155)

Payment dispute records.

**File:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Payments\Tables\ShpfyDispute.Table.al`

**Access:** Internal

**Key fields:**
- Id (PK)
- Source Order Id (TableRelation: Shpfy Order Header)
- Type (Enum: Inquiry, Chargeback)
- Currency (Code 10)
- Amount
- Reason (Enum: Shpfy Dispute Reason)
- Network Reason Code
- Status (Enum: Shpfy Dispute Status)
- Evidence Due By (DateTime)
- Evidence Sent On (DateTime)
- Finalized On (DateTime)

### Shpfy Payment Terms (30158)

Payment terms from Shopify for B2B orders.

**File:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Payments\Tables\ShpfyPaymentTerms.Table.al`

**Access:** Internal

**Key fields:**
- Shop Code (PK)
- Id (PK)
- Name (not editable)
- Due In Days (not editable)
- Description (not editable)
- Type (Code 20, not editable)
- Is Primary (Boolean, validated)
- Payment Terms Code (TableRelation: Payment Terms)

**Validation:**
- Only one payment term can be marked as primary

## Relationships

```
Shpfy Payment Transaction
├── Shpfy Payout (via Payout Id)
├── Shpfy Shop (via Shop Code)
├── Shpfy Order Transaction (via Source Order Transaction Id)
├── Shpfy Order Header (via Source Order Id)
└── Sales Invoice Header (via Source Order Id, FlowField)

Shpfy Payout
└── Shpfy Payment Transaction (1:many via Payout Id)

Shpfy Dispute
└── Shpfy Order Header (via Source Order Id)

Shpfy Payment Terms
├── Shpfy Shop (via Shop Code)
└── Payment Terms (via Payment Terms Code)
```

## Enums

### Shpfy Payment Trans. Type (30127)

**File:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Payments\Enums\ShpfyPaymentTransType.Enum.al`

Primary values:
- Charge
- Refund
- Adjustment

Deprecated (kept for legacy support):
- Dispute, Reserve, Credit, Debit, Payout, Payout Failure, Payout Cancellation, Payment Refund

Extended values (100+ total):
- Shop Cash Credit, Anomaly Debit, Application Fee Refund, Balance Transfer Inbound, Billing Debit
- Channel Credit/Debit variations, Chargeback Fee/Hold variations
- Shipping Label adjustments, Tax Adjustment variations, Transfer variations
- VAT Refund Credit, Advance Funding, and many others

### Shpfy Payout Status (30128)

**File:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Payments\Enums\ShpfyPayoutStatus.Enum.al`

Values:
- Unknown (blank)
- Scheduled
- In Transit
- Paid
- Failed
- Canceled

### Shpfy Dispute Type (30155)

**File:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Payments\Enums\ShpfyDisputeType.Enum.al`

Values:
- Unknown (blank)
- Inquiry
- Chargeback

### Shpfy Dispute Reason

**File:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Payments\Enums\ShpfyDisputeReason.Enum.al`

Enumeration of dispute reason codes.

### Shpfy Dispute Status

**File:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Payments\Enums\ShpfyDisputeStatus.Enum.al`

Enumeration of dispute status values.

### Shpfy Payment Trans. Source (30XXX)

**File:** `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Payments\Enums\ShpfyPaymentTransSource.Enum.al`

Enumeration indicating the source entity type for a payment transaction.
