# Bulk operations

Provides an async GraphQL bulk mutation framework for high-volume updates to Shopify. Instead of sending hundreds of individual API calls, this module uploads a JSONL file and submits a single `bulkOperationRunMutation` to process it server-side.

## How it works

The flow is: build JSONL input, upload it to a staged URL, submit the bulk mutation referencing that URL, then wait for a webhook callback. `ShpfyBulkOperationMgt.SendBulkMutation` orchestrates this -- it checks that no bulk operation of the same type is already running, calls `ShpfyBulkOperationAPI.CreateBulkOperationMutation` (which creates the upload URL, POSTs the JSONL as multipart/form-data, then sends the GraphQL mutation), and records the operation in the `Shpfy Bulk Operation` table. When Shopify completes the operation, it fires a webhook that calls `ProcessBulkOperationNotification`, which fetches the final status, result URL, and any error codes.

Each concrete operation implements the `Shpfy IBulk Operation` interface, which provides the GraphQL mutation template, JSONL input template, and revert logic. The `OnModify` trigger on the `Shpfy Bulk Operation` table automatically calls `RevertFailedRequests` on completion or `RevertAllRequests` on cancellation/failure -- this restores local records that were optimistically updated before the bulk call and, for price updates, logs skipped records for the variants Shopify did not confirm.

Two implementations exist today: `ShpfyBulkUpdateProductImage` (updates product media) and `ShpfyBulkUpdateProductPrice` (updates variant prices and costs). Price sync switches to bulk only when there are at least 100 changed variant price requests, not merely 100 variants considered during the sync.

*Updated: 2026-07-29 -- price bulk threshold, diagnostics, and revert behavior
updated*

## Things to know

- Only one bulk operation per type (mutation/query) can run at a time per shop. The module polls the current operation status before starting a new one.
- Enabling bulk operations requires a BC-licensed user and registers a webhook subscription on the shop.
- The `Shpfy Bulk Operation` table stores request data as a JSONL blob so revert logic can compare against Shopify's JSONL result to identify which items succeeded vs. failed.
- When the shop logging mode is `All`, the exact JSONL sent to Shopify is also stored on the bulk operation and can be downloaded from the Shopify Bulk Operations page.
- `RevertFailedRequests` for price updates parses the JSONL result line by line, collects successful variant IDs, logs skipped records with Shopify error text when available, and reverts only the records that were not in the success list.
- Revert logic tolerates older request data that does not contain `unitCost`; it restores unit cost only when that key is present.
- Price update JSONL sends `compareAtPrice` only when it changed. If the new compare-at price is not greater than the price, it sends `null` instead of `"0"` so Shopify clears the value rather than storing a zero compare-at price.
- Adding a new bulk operation type means implementing `Shpfy IBulk Operation` and adding an enum value to `Shpfy Bulk Operation Type`.
