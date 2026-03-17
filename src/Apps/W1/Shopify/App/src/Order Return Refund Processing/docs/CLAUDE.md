# Order Return Refund Processing

The processing engine that converts Shopify refunds into BC sales credit memos. This area owns the strategy pattern and the actual credit memo creation logic, while the data models for returns and refunds live in their own sibling folders.

## How it works

The `Shpfy ReturnRefund ProcessType` enum implements `Shpfy IReturnRefund Process` with three strategies: blank (default, does nothing), "Import Only" (imports Shopify data but creates no BC documents), and "Auto Create Credit Memo" (the main workhorse in `ShpfyRetRefProcCrMemo.Codeunit.al`). The credit memo strategy validates prerequisites -- the parent order must already be processed in BC, and the refund must not already have a document link -- before delegating to `ShpfyCreateSalesDocRefund.Codeunit.al`.

`ShpfyCreateSalesDocRefund` builds the credit memo in several phases: create the header (copying addresses and customer data from the original order header), create item lines from refund lines (respecting restock type), fall back to return lines if no refund lines exist, add refund shipping lines, and finally balance the total with a remaining-amount line posted to the Shop's "Refund Account". The restock type on each line determines how it is handled -- `Return` and `Legacy Restock` create item-type lines, `No Restock` uses the "Refund Acc. non-restock Items" G/L account, and `Cancel` uses the "Refund Account" G/L account.

## Things to know

- The `Shpfy IDocument Source` interface exists solely for error reporting back to the source record. `ShpfyIDocSourceRefund.Codeunit.al` writes error details (including call stack via `Shpfy Extended IDocument Source`) to the Refund Header's blob fields.
- Refund processing runs inside `if CreateSalesDocRefund.Run()` with a `Commit()` before and after, isolating failures so one bad refund doesn't roll back others.
- The credit memo is automatically released via `ReleaseSalesDocument.Run` after creation -- it arrives in BC ready for posting.
- Currency handling branches on `Processed Currency Handling` (Shop Currency vs Presentment Currency) throughout line creation, which means unit prices come from different refund line fields depending on the shop setting.
- Table extensions on `Sales Cr.Memo Header`, `Sales Cr.Memo Line`, `Return Receipt Header`, and `Return Receipt Line` add Shopify tracking fields to posted BC documents.
