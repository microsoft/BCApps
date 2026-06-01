# Extensibility

## IReturnRefund Process interface

The `Shpfy ReturnRefund ProcessType` enum is `Extensible = true`. To add a custom refund processing strategy, add a new enum value with an implementation of `Shpfy IReturnRefund Process`. The three procedures you must implement are:

- `IsImportNeededFor(SourceDocumentType)` -- return true if your strategy requires returns/refunds to be imported from Shopify during order sync. If false, the refund and return API calls are skipped entirely during import.
- `CanCreateSalesDocumentFor(SourceDocumentType, SourceDocumentId, ErrorInfo)` -- validate preconditions. Return true to allow creation. On failure, populate the `ErrorInfo` record with an error message; set `Verbosity` to `Error` for hard failures or `Warning` for soft skips.
- `CreateSalesDocument(SourceDocumentType, SourceDocumentId)` -- build and return the Sales Header for the credit memo / return order.

## IDocument Source interface

The `Shpfy Source Document Type` enum is also `Extensible = true` and implements `Shpfy IDocument Source`. The interface has a single method, `SetErrorInfo`, which writes error information back to the source document record. The extended interface `Shpfy Extended IDocument Source` adds `SetErrorCallStack` for detailed diagnostics. When your `IReturnRefund Process` implementation calls `CreateSalesDocument`, errors are routed to the appropriate source document through this interface.

## Events in ShpfyRefundProcessEvents

Events are published by `ShpfyRefundProcessEvents` (codeunit 30247).

- `OnBeforeCreateSalesHeader` / `OnAfterCreateSalesHeader` -- wrap credit memo header creation from a refund. The Before event supports the Handled pattern to replace the built-in header creation entirely.
- `OnBeforeCreateItemSalesLine` / `OnAfterCreateItemSalesLine` -- wrap each refund line's conversion to a sales line. Handled pattern supported on Before.
- `OnBeforeCreateItemSalesLineFromReturnLine` / `OnAfterCreateItemSalesLineFromReturnLine` -- same pattern but for return lines (used when the refund has a linked return and no refund lines).
- `OnAfterProcessSalesDocument` -- fires after the credit memo is created and released.
- `OnBeforeCreateSalesLinesFromRemainingAmount` -- fires before the auto-balance line is created. Set `SkipBalancing = true` to suppress the balance line entirely, useful if your custom logic already ensures the document total matches the refund amount.
