# Order Return Refund Processing

Strategy framework that controls how Shopify returns and refunds become BC sales documents. Uses an enum-based interface pattern to select processing behavior (import only, auto-create credit memo) per shop configuration.

## How it works

The `Shpfy ReturnRefund ProcessType` enum (30139) implements `Shpfy IReturnRefund Process` with three strategies: blank (default/no-op), `Import Only` (imports data but creates no BC documents), and `Auto Create Credit Memo` (creates BC credit memos from refund data). The interface defines three methods: `IsImportNeededFor`, `CanCreateSalesDocumentFor`, and `CreateSalesDocument`.

The credit memo strategy in `ShpfyRetRefProcCrMemo` (30243) validates that the refund exists, is not already processed, and that the parent order has been processed. It then delegates to `ShpfyCreateSalesDocRefund` (30246), which builds a full Sales Credit Memo header (copying addresses from the order), creates lines from refund lines or return lines (falling back to return lines when refund lines are absent), adds shipping refund lines, and balances the total against the refund amount with a remaining-amount adjustment line. The document is auto-released after creation.

Error tracking uses the `Shpfy IDocument Source` and `Shpfy Extended IDocument Source` interfaces to write error descriptions and call stacks back to the refund header.

## Things to know

- The `CanCreateSalesDocumentFor` method checks three preconditions before creating a credit memo: the refund must not be already processed (checked via Doc Link To Doc existence), the parent order must exist, and the parent order must be processed. Violation produces structured `ErrorInfo` with record context.
- Refund lines with `Restock Type = Cancel` use the `Refund Account` G/L account instead of item lines; `No Restock` uses the `Refund Acc. non-restock Items` account. Only `Legacy Restock` and `Return` types create actual item-based credit memo lines.
- Currency handling branches on the order's `Processed Currency Handling` (Shop vs. Presentment), affecting which amount fields are used for unit prices and discount calculations on every credit memo line.
- The framework is extensible: both `Shpfy ReturnRefund ProcessType` and `Shpfy Source Document Type` enums are marked `Extensible = true`.
- Table extensions on Sales Cr.Memo Header/Line, Return Receipt Header/Line add `Shpfy Refund Id` and `Shpfy Refund Line Id` fields for traceability back to the Shopify refund.
