# Order return refund processing

Interface-driven processing of Shopify returns and refunds, with a strategy pattern that controls whether refund data is imported only, automatically converted to credit memos, or ignored entirely.

## Quick reference

| Task | Entry point |
|------|-------------|
| Process a refund | `Shpfy ReturnRefund ProcessType` enum -- selects strategy via `IReturnRefund Process` |
| Create credit memo from refund | `ShpfyRetRefProcCrMemo` (codeunit 30243) |
| Build sales document | `ShpfyCreateSalesDocRefund` (codeunit 30246) |
| Error handling for refund source | `ShpfyIDocSourceRefund` (codeunit 30249) |

## Structure

- `Codeunits/` -- process strategy implementations, sales document creation, document source error handlers, refund process events
- `Enums/` -- `ReturnRefundProcessType` (strategy selector), `SourceDocumentType` (document source selector)
- `Interfaces/` -- `IReturnRefundProcess`, `IDocumentSource`, `ExtendedIDocumentSource`
- `Page Extensions/` -- Shopify fields on Sales Credit Memo, Sales Credit Memos list, Posted Sales Credit Memos
- `Table Extensions/` -- Shopify refund ID on Return Receipt Header/Line, Sales Cr.Memo Header/Line

## Documentation

- [docs/architecture.md](docs/architecture.md) -- interface-driven workflow, strategy pattern, page extensions, enum-based process selection

## Key concepts

- **Strategy pattern** -- the `Shpfy ReturnRefund ProcessType` enum selects the processing behavior: no-op (default), import only, or auto-create credit memo
- **Dual interface design** -- `IReturnRefundProcess` handles the processing workflow; `IDocumentSource` (and `ExtendedIDocumentSource`) handles error reporting back to the source document
- **Credit memo creation** -- builds a full Sales Credit Memo from Shopify refund data, including item lines, shipping refunds, gift card adjustments, cash rounding, and remaining amount balancing
- **Extensibility** -- both enums are extensible; `ShpfyRefundProcessEvents` publishes integration events for customizing sales header/line creation
