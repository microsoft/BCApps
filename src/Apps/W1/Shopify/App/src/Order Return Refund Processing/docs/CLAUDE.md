# Order Return Refund Processing

This folder orchestrates the creation of BC credit memos from Shopify refunds. It uses an interface-based strategy pattern to support different processing modes.

## Processing modes

The `Shpfy ReturnRefund ProcessType` enum (extensible) maps to implementations of `Shpfy IReturnRefund Process`:

- **Default (blank)** -- `ShpfyRetRefProcDefault`. Does nothing: `IsImportNeededFor` returns false, no documents are created. Returns and refunds are not imported at all.
- **Import Only** -- `ShpfyRetRefProcImportOnly`. Imports returns and refunds (`IsImportNeededFor` returns true) but never creates sales documents.
- **Auto Create Credit Memo** -- `ShpfyRetRefProcCrMemo`. Imports returns/refunds and auto-creates credit memos from refunds.

The mode is set on the Shop record as `"Return and Refund Process"`. The interface is consumed in two places: during order import (to decide whether to fetch returns/refunds) and during order processing (to create credit memos).

## The IReturnRefundProcess interface

Three methods:

- `IsImportNeededFor(SourceDocumentType)` -- controls whether returns or refunds are fetched during order import.
- `CanCreateSalesDocumentFor(SourceDocumentType, SourceDocumentId, ErrorInfo)` -- validates preconditions: the refund must not already be processed, the parent order must exist and be processed. Returns detailed error info on failure.
- `CreateSalesDocument(SourceDocumentType, SourceDocumentId)` -- creates the sales document.

## Credit memo auto-creation

`ShpfyRetRefProcCrMemo.CreateSalesDocument` is the entry point. It:

1. Validates via `CanCreateSalesDocumentFor` -- checks the refund is not already linked to a BC document, the order exists and is processed.
2. Skips if any refund line has `"Can Create Credit Memo" = false` (these were already absorbed into the order).
3. Delegates to `ShpfyCreateSalesDocRefund` (codeunit 30246), which runs inside `codeunit.Run()` for error isolation.

`ShpfyCreateSalesDocRefund.CreateSalesDocument` does the actual work:

1. Creates a Sales Credit Memo header copying addresses, customer, currency, and tax area from the original order. Uses `"Processed Currency Handling"` from the order to pick the right currency -- important because the order may have been processed with a different currency setting than the shop currently has.
2. Creates lines from refund lines, handling each restock type differently:
   - **Return / Legacy Restock** -- creates Item lines with the refunded item, variant, UoM, and location (from the refund's resolved location or the shop's default return location based on `"Return Location Priority"`).
   - **No Restock** -- creates G/L Account lines using `"Refund Acc. non-restock Items"`.
   - **Cancel** -- creates G/L Account lines using `"Refund Account"`.
3. If no refund lines exist but a return ID is present, falls back to creating lines from return lines instead.
4. Creates lines for refund shipping amounts.
5. Adds a balancing "remaining amount" line to ensure the credit memo total matches the refund's total refunded amount exactly (accounts for rounding, tax differences, etc.).
6. Auto-releases the credit memo.

## Error handling

Errors during credit memo creation are captured and stored on the refund header as blob fields (`"Last Error Description"`, `"Last Error Call Stack"`). The `Shpfy IDocument Source` / `Shpfy Extended IDocument Source` interfaces provide the `SetErrorInfo` / `SetErrorCallStack` callbacks used by the processing code to persist error details. The `"Has Processing Error"` flag on the refund header enables filtering for failed refunds.

## Key files

- `ShpfyRetRefProcCrMemo.Codeunit.al` -- the "Auto Create Credit Memo" strategy implementation.
- `ShpfyCreateSalesDocRefund.Codeunit.al` -- the actual credit memo creation logic.
- `ShpfyRetRefProcDefault.Codeunit.al` / `ShpfyRetRefProcImportOnly.Codeunit.al` -- the no-op and import-only strategies.
- `ShpfyIReturnRefundProcess.Interface.al` -- the strategy interface.
- `ShpfyRefundProcessEvents.Codeunit.al` -- event publishers for extensibility (OnBefore/AfterCreateSalesHeader, OnBefore/AfterCreateItemSalesLine, etc.).
