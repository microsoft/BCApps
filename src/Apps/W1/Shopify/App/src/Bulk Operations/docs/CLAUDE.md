# Bulk Operations

Async bulk mutation support for Shopify API operations that exceed practical single-request limits. Used for price updates and image updates, with webhook-based status polling and automatic rollback on failure.

## How it works

The `Shpfy IBulk Operation` interface defines what each bulk operation provides: the GraphQL mutation template, the JSONL input data, and rollback logic for failed or canceled operations. Two implementations exist: `ShpfyBulkUpdateProductPrice` and `ShpfyBulkUpdateProductImage`.

`ShpfyBulkOperationMgt` (30270) orchestrates the lifecycle. It checks for already-running operations (only one per type per shop), submits the JSONL payload via `ShpfyBulkOperationAPI`, creates a tracking record in `Shpfy Bulk Operation` (30148), and enables a webhook for completion notifications. When Shopify notifies BC (via the bulk operation webhook), `ProcessBulkOperationNotification` updates the status. The `OnModify` trigger on the table automatically calls `RevertFailedRequests` or `RevertAllRequests` depending on the final status.

The threshold for switching from individual mutations to bulk operations is 100 items (`GetBulkOperationThreshold()`).

## Things to know

- Only one bulk operation per type (mutation/query) per shop can run at a time. `SendBulkMutation` checks for active operations and updates their status before submitting a new one.
- The `Request Data` BLOB on the bulk operation record stores the original request as a JsonArray, enabling the `RevertAllRequests` implementation to undo changes if the operation fails or is canceled.
- Enabling bulk operations requires a valid BC licensed user (checked via `WebhookManagement.IsValidNotificationRunAsUser`) because the webhook callback runs under that user's context.
- The `Processed` flag prevents reprocessing: once the `OnModify` trigger has handled the completion/failure rollback, it sets `Processed = true` and subsequent modifications are no-ops.
- Bulk operations were made mandatory for 100+ price updates starting in 2025 Wave 1. The connector falls back to individual mutations only when the item count is below the threshold.
