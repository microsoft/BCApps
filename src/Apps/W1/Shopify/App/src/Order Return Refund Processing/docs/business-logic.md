# Order Return Refund Processing business logic

Details the strategy pattern for processing returns and refunds.

## Interface design

### IReturnRefund Process interface

File: `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Order Return Refund Processing\Interfaces\ShpfyIReturnRefundProcess.Interface.al`

Three required procedures:

1. **IsImportNeededFor**(SourceDocumentType): Returns true if returns or refunds should be imported from Shopify
   - Return false to skip API calls entirely
   - Reduces API usage if returns/refunds not needed

2. **CanCreateSalesDocumentFor**(SourceDocumentType, SourceDocumentId, ErrorInfo): Returns true if source document can be converted to BC sales document
   - Validates preconditions (e.g., order is processed, refund not already processed)
   - Populates ErrorInfo with detailed message if cannot create
   - Used before attempting creation to avoid errors

3. **CreateSalesDocument**(SourceDocumentType, SourceDocumentId): Creates and returns BC Sales Header
   - Main entry point for document creation
   - Commits transaction after success/failure
   - Returns empty Sales Header if creation failed

## Strategy implementations

### Auto Create Credit Memo (30243)

File: `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Order Return Refund Processing\Codeunits\ShpfyRetRefProcCrMemo.Codeunit.al`

**IsImportNeededFor**: Returns true (always import returns and refunds)

**CanCreateSalesDocumentFor** (lines 17-61):

Validation checks for refunds:
1. Refund must exist
2. Refund must not be already processed (check flowfield `Is Processed`)
3. Order must exist for the refund
4. Order must be processed in BC (has Sales Order No. or Sales Invoice No.)

Returns ErrorInfo with:
- **ErrorType**: Client
- **DetailedMessage**: Specific reason (e.g., "You must process Shopify order #1001 first")
- **Message**: Composite message for display
- **RecordId**, **SystemId**, **TableId**: For linking to source record
- **Verbosity**: Error (block creation) or Warning (already processed)

**CreateSalesDocument** (lines 63-97):

Steps:
1. Check `CanCreateSalesDocumentFor`; exit if ErrorInfo.Verbosity = Error
2. Check if any refund lines have `Can Create Credit Memo` = false; exit if so
3. Instantiate `Shpfy Create Sales Doc. Refund` codeunit
4. Set source = refund ID, target document type = Credit Memo
5. Commit to save state
6. Run codeunit; if succeeds:
   - Get created Sales Header
   - Clear error on refund header
7. If fails:
   - Store error text and call stack on refund header via IDocument Source interface
8. Commit again

### Import Only (30245)

File: `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Order Return Refund Processing\Codeunits\ShpfyRetRefProcImportOnly.Codeunit.al`

**IsImportNeededFor**: Returns true (import but don't process)

**CanCreateSalesDocumentFor**: Returns false (never create documents)

**CreateSalesDocument**: Returns empty Sales Header (no-op)

Use case: Import return/refund data for reporting, analytics, or manual credit memo creation.

### Default strategy (30244)

Placeholder for future custom logic. Currently inherits behavior from base interface.

## Document source interfaces

### IDocument Source interface

Provides error tracking for source documents (returns or refunds):

- **SetErrorInfo**(SourceDocumentId, ErrorText): Stores error message on source record
- Implemented by `Shpfy IDocSource Default` and `Shpfy IDocSource Refund`

### Extended IDocument Source interface

Extends IDocument Source with:

- **SetErrorCallStack**(SourceDocumentId, CallStack): Stores full call stack for debugging

Implemented by `Shpfy IDocSource Refund`.

### IDocSource Refund implementation (30247)

Uses enum `Shpfy Source Document Type` to resolve to Refund Header table:

**SetErrorInfo**:
1. Get refund header by ID
2. Set `Has Processing Error` = true
3. Write error text to blob field `Last Error Description`
4. Modify record

**SetErrorCallStack**:
1. Get refund header by ID
2. Write call stack to blob field `Last Error Call Stack`
3. Modify record

## Credit memo creation flow

Codeunit: `Shpfy Create Sales Doc. Refund` (30248)

Referenced in `ShpfyRetRefProcCrMemo.Codeunit.al` lines 85-96.

Entry point: `SetSource(RefundId)`, `SetTargetDocumentType(CreditMemo)`, then `Run()`

Process (inferred from usage):
1. Load Shpfy Refund Header by ID
2. Load Shpfy Order Header for original order
3. Get original BC sales document (order or invoice)
4. Create Sales Header with Document Type = Credit Memo
5. Copy customer, addresses, currency from original document
6. For each Shpfy Refund Line:
   - Create Sales Line with negative quantity
   - Match to original order line via `Order Line Id`
   - Set item, variant, UOM, price
   - Apply refund amount and tax adjustments
7. Handle refund shipping lines (if shipping cost refunded)
8. Apply rounding adjustments
9. Trigger events for customization
10. Store link in `Shpfy Doc. Link To Doc.` table
11. Mark refund as processed (via flowfield calculation)

## Processing trigger

Entry point: `Shpfy Process Orders` codeunit (30167), procedure `ProcessShopifyRefunds` (line 96)

File: `C:\repos\NAV\App\BCApps\src\Apps\W1\Shopify\App\src\Order handling\Codeunits\ShpfyProcessOrders.Codeunit.al`

Logic:
1. Check shop setting `Return and Refund Process`
2. If set to "Auto Create Credit Memo":
   - Get IReturnRefundProcess implementation from enum
   - Filter Shpfy Refund Header for `Is Processed` = false
   - Loop through each refund
   - Call `IReturnRefundProcess.CreateSalesDocument(Refund, RefundId)`
   - Commit after each refund

Note: This runs after processing orders, so refunds are created for already-processed orders.

## Refund line eligibility

Field `Can Create Credit Memo` on Shpfy Refund Line determines if line can be included in auto-created credit memo.

Set to false when:
- Refund line has no corresponding order line (e.g., shipping refund without order line)
- Refund line references a line that was not in the original BC sales document
- Refund line has zero quantity

Logic in `ShpfyImportOrder.Codeunit.al` function `ConsiderRefundsInQuantityAndAmounts` (line 195):
- If refund lines exist with `Can Create Credit Memo` = false and order is processed, set order state error

## Error handling

All error handling uses ErrorInfo record:

**ErrorInfo fields populated**:
- **ErrorType**: Client (user-fixable) or Internal (system error)
- **Message**: User-facing message
- **DetailedMessage**: Technical details
- **RecordId**, **SystemId**, **TableId**: Link to source record
- **Verbosity**: Error, Warning, or Informational
- **Collectible**: Can be added to error list

**Error storage**:
- Refund Header: `Has Processing Error` (Boolean), `Last Error Description` (Blob), `Last Error Call Stack` (Blob)
- Return Header: Similar fields

**Error display**:
- Page extensions show error fields
- Users can view error details and call stack for troubleshooting
- Can retry processing after fixing issue (e.g., processing parent order first)

## Integration events

Codeunit `Shpfy Refund Process Events` (30249) provides extension points for customization.

Expected events (not detailed in read files):
- OnBeforeCreateCreditMemo
- OnAfterCreateCreditMemo
- OnBeforeValidateRefundLine
- OnAfterValidateRefundLine
