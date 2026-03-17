# Order return refund processing -- architecture

## Interface-driven workflow

The module uses two separate interface hierarchies that work together:

### `IReturnRefund Process` interface

Defined in `Interfaces/ShpfyIReturnRefundProcess.Interface.al`. Three methods:

- `IsImportNeededFor(SourceDocumentType)` -- determines whether refund/return data should be imported from Shopify
- `CanCreateSalesDocumentFor(SourceDocumentType, SourceDocumentId, ErrorInfo)` -- validates whether a sales document can be created; returns detailed error information on failure
- `CreateSalesDocument(SourceDocumentType, SourceDocumentId)` -- creates and returns a `Sales Header` record

### `IDocument Source` interface

Defined in `Interfaces/ShpfyIDocumentSource.Interface.al`. One method:

- `SetErrorInfo(SourceDocumentId, ErrorDescription)` -- writes processing errors back to the source document

### `Extended IDocument Source` interface

Defined in `Interfaces/ShpfyExtendedIDocumentSource.Interface.al`. Extends `IDocument Source` with:

- `SetErrorCallStack(SourceDocumentId, ErrorCallStack)` -- writes the error call stack for debugging

## Strategy pattern for refund scenarios

The `Shpfy ReturnRefund ProcessType` enum (30139) implements `IReturnRefund Process` and is extensible. Three built-in strategies:

### Default (blank value)

Implemented by `ShpfyRetRefProcDefault` (codeunit 30244).

- `IsImportNeededFor` returns `false`
- `CanCreateSalesDocumentFor` returns `false`
- `CreateSalesDocument` returns an empty `Sales Header`

This is the no-op strategy -- refund data is neither imported nor processed.

### Import only

Implemented by `ShpfyRetRefProcImportOnly` (codeunit 30245).

- `IsImportNeededFor` returns `true`
- `CanCreateSalesDocumentFor` returns `false`
- `CreateSalesDocument` returns an empty `Sales Header`

Refund data is imported from Shopify and stored locally, but no sales documents are created. Useful for manual review workflows.

### Auto create credit memo

Implemented by `ShpfyRetRefProcCrMemo` (codeunit 30243).

- `IsImportNeededFor` returns `true`
- `CanCreateSalesDocumentFor` validates:
  - The source document type is Refund
  - The refund header exists and is not already processed
  - The parent Shopify order exists and is already processed in BC
  - Returns detailed `ErrorInfo` with appropriate verbosity (Warning for already-processed, Error for missing order or unprocessed order)
- `CreateSalesDocument`:
  - Resolves the `IDocumentSource` from the `SourceDocumentType` enum for error reporting
  - Checks `CanCreateSalesDocumentFor` -- on error, writes error info to the refund header and exits
  - Verifies no refund lines have `Can Create Credit Memo = false`
  - Delegates to `ShpfyCreateSalesDocRefund` (codeunit 30246) for actual document creation
  - On success, clears the error on the refund header
  - On failure, writes error text (and call stack if `ExtendedIDocumentSource` is supported) to the refund header

## Enum-based document source selection

The `Shpfy Source Document Type` enum (30142) implements `IDocument Source` and is extensible. Values:

- **Blank** / **Order** / **Return** -- use `ShpfyIDocSourceDefault` (codeunit 30248), which is a no-op for error handling
- **Refund** -- uses `ShpfyIDocSourceRefund` (codeunit 30249), which writes errors to `Shpfy Refund Header` via `SetLastErrorDescription` and `SetLastErrorCallStack`

`ShpfyIDocSourceRefund` also implements `Shpfy Extended IDocument Source`, enabling call stack capture.

## Sales document creation (`ShpfyCreateSalesDocRefund`)

Codeunit 30246 handles the full credit memo creation process.

### Sales header creation (`DoCreateSalesHeader`)

1. Checks if a `Shpfy Doc. Link To Doc.` record already exists for this refund (prevents duplicates)
2. Retrieves the parent `Shpfy Order Header`
3. Fires `OnBeforeCreateSalesHeader` event (allows full override via `Handled` parameter)
4. Creates a `Sales Header` with `Document Type = Credit Memo`
5. Copies all customer/address fields from the order header:
   - Sell-to customer details (name, address, phone, email, contact)
   - Bill-to customer details
   - Ship-to details
6. Applies currency based on `Processed Currency Handling` (Shop Currency or Presentment Currency)
7. Sets document date from refund `Created At`
8. Resolves tax area from the order
9. Maps payment method from refund transactions
10. Creates `Shpfy Doc. Link To Doc.` record linking the refund to the BC document
11. Fires `OnAfterCreateSalesHeader` event

### Sales line creation

Lines are created from multiple sources in order:

**1. Refund lines** (`CreateSalesLinesFromRefundLines`):

Handles four restock types:

- **Legacy Restock / Return / No Restock**:
  - Gift cards -- posted to the `Sold Gift Card Account` G/L account; adjusts gift card known amounts
  - No Restock items -- posted to `Refund Acc. non-restock Items` G/L account
  - Regular items -- creates Item-type sales lines with item no., variant, unit of measure, and location
  - Location resolved via `Shpfy Shop Location` mapping; falls back to shop's `Return Location` based on `Return Location Priority`
  - Unit price and discount from refund line amounts (shop or presentment currency)

- **Cancel** -- posts to the `Refund Account` G/L account with the subtotal amount

**2. Return lines** (fallback when no refund lines exist):

If `RefundHeader."Return Id"` is set but no refund lines exist, creates item sales lines from `Shpfy Return Line` records instead, using `Discounted Total Amount / Quantity` for unit price.

**3. Shipping refund lines** (`CreateSalesLinesFromRefundShippingLines`):

Posts shipping refunds to the `Shipping Charges Account` G/L account, handling VAT-inclusive pricing.

**4. Rounding lines** (`CreateRoundingLine`):

If the order has a refund rounding amount, creates a line on the `Cash Roundings Account` using the rounding amount from successful refund transactions.

**5. Remaining amount balancing** (`CreateSalesLinesFromRemainingAmount`):

Compares the sales document's `Amount Including VAT` to the refund's `Total Refunded Amount`. If they differ, creates a balancing line on the `Refund Account` to ensure the credit memo total matches the Shopify refund total. This accounts for rounding differences and tax calculation variances.

The `OnBeforeCreateSalesLinesFromRemainingAmount` event allows skipping this auto-balancing.

### Post-creation

After all lines are created, the sales document is released via `ReleaseSalesDocument.Run`, and `OnAfterProcessSalesDocument` is fired.

## Page extensions

Three page extensions add Shopify visibility to standard BC pages:

| Page extension | Extends | Adds |
|----------------|---------|------|
| `ShpfyPostedSalesCrMemos` (30126) | Posted Sales Credit Memos | "From Shopify" view (filters `Shpfy Refund Id <> 0`) |
| `ShpfySalesCreditMemo` (30122) | Sales Credit Memo | `Shpfy Order No.` field with drill-down to Shopify order |
| `ShpfySalesCreditMemos` (30121) | Sales Credit Memos | `Shpfy Order No.` field + "From Shopify" view |

## Table extensions

Four table extensions add Shopify tracking fields to standard BC tables:

| Table extension | Extends | Fields added |
|-----------------|---------|--------------|
| `ShpfyReturnReceiptHeader` (30110) | Return Receipt Header | `Shpfy Refund Id` |
| `ShpfyReturnReceiptLine` (30111) | Return Receipt Line | `Shpfy Refund Id`, `Shpfy Refund Line Id` |
| `ShpfySalesCrMemoHeader` (30108) | Sales Cr.Memo Header | `Shpfy Refund Id` |
| `ShpfySalesCrMemoLine` (30109) | Sales Cr.Memo Line | `Shpfy Refund Id`, `Shpfy Refund Line Id` |

All `Shpfy Refund Id` fields have a table relation to `Shpfy Refund Header."Refund Id"`.

## Integration events (`ShpfyRefundProcessEvents`)

| Event | Purpose |
|-------|---------|
| `OnBeforeCreateSalesHeader` | Override or customize sales header creation (supports `Handled` flag) |
| `OnAfterCreateSalesHeader` | Post-processing after header creation |
| `OnBeforeCreateItemSalesLine` | Override item line creation from refund lines (supports `Handled` flag) |
| `OnAfterCreateItemSalesLine` | Post-processing after item line from refund line |
| `OnBeforeCreateItemSalesLineFromReturnLine` | Override item line creation from return lines (supports `Handled` flag) |
| `OnAfterCreateItemSalesLineFromReturnLine` | Post-processing after item line from return line |
| `OnAfterProcessSalesDocument` | Post-processing after the full document is created and released |
| `OnBeforeCreateSalesLinesFromRemainingAmount` | Skip auto-balancing via `SkipBalancing` parameter |
