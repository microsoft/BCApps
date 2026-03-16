# Order return refund processing

Processing logic for creating BC sales documents from Shopify returns and refunds. This module sits between the data-import modules (Order Returns, Order Refunds) and the BC sales document layer. It decides whether and how to create credit memos or return orders based on the shop's configured processing type.

## How it works

The `Shpfy IReturnRefund Process` interface (`ShpfyIReturnRefundProcess.Interface.al`) defines three methods: `IsImportNeededFor`, `CanCreateSalesDocumentFor`, and `CreateSalesDocument`. The `Shpfy ReturnRefund ProcessType` enum (30139) selects the implementation: blank (default, no processing), `Import Only` (`ShpfyRetRefProcImportOnly.Codeunit.al`, imports data but creates no documents), or `Auto Create Credit Memo` (`ShpfyRetRefProcCrMemo.Codeunit.al`, creates credit memos automatically).

The credit memo flow in `ShpfyRetRefProcCrMemo` validates prerequisites -- the refund must not already be processed (checked via `DocLinkToDoc`), and the parent order must already be processed in BC. It then delegates to `ShpfyCreateSalesDocRefund.Codeunit.al`, which builds a full Sales Header and Sales Lines from the refund data. Sales lines are created from refund lines, with special handling for different restock types: `Return` and `Legacy Restock` create item lines, `No Restock` creates a G/L account line using the shop's `Refund Acc. non-restock Items`, `Cancel` creates a G/L account line using `Refund Account`, and gift card refunds use the `Sold Gift Card Account`. After all lines, a balancing line ensures the credit memo total matches Shopify's refund amount exactly, and a rounding line handles cash rounding from transactions.

The module also extends `Sales Credit Memo`, `Sales Cr.Memo Header/Line`, and `Return Receipt Header/Line` with Shopify fields via table and page extensions.

## Things to know

- The `CanCreateSalesDocumentFor` method populates an `ErrorInfo` record with structured error details rather than throwing -- callers check the result and log errors via the `IDocumentSource` interface.
- If refund lines have `Can Create Credit Memo = false`, the entire credit memo creation is skipped silently.
- When a refund has no refund lines but does have a `Return Id`, the system falls back to creating sales lines from return lines instead.
- Currency handling respects the order's `Processed Currency Handling` setting -- either shop currency or presentment currency amounts are used on the sales lines.
- The credit memo is automatically released after creation via `ReleaseSalesDocument.Run`.
- Refund shipping lines create separate G/L account lines using the shop's `Shipping Charges Account`.
- The `OnBeforeCreateSalesHeader` and `OnAfterCreateItemSalesLine` events in `ShpfyRefundProcessEvents.Codeunit.al` allow partners to customize the document creation.
