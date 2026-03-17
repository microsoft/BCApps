# Bulk operations

Async bulk mutation pattern via Shopify's `bulkOperationRunMutation` API, used when updates exceed a threshold (100 items per `GetBulkOperationThreshold`).

The `Shpfy IBulk Operation` interface (`ShpfyIBulkOperation.Interface.al`) defines the contract: `GetGraphQL` (the mutation template), `GetInput` (the JSONL line template with placeholders), `GetName`, `GetType` (mutation or query), `RevertFailedRequests`, and `RevertAllRequests`. The `Shpfy Bulk Operation Type` enum implements this interface with two values -- `UpdateProductImage` and `UpdateProductPrice`. The enum is `Extensible = true`.

The flow in `ShpfyBulkOperationMgt.Codeunit.al`: first check no other bulk operation is already running for this shop+type (if one exists, poll its status). Then upload the JSONL payload via a staged upload (create URL, multipart POST), submit the bulk mutation referencing the uploaded file, and create a `Shpfy Bulk Operation` record with status Created. The request data (a JSON array of the original values) is stored as a BLOB on the record so failures can be reverted.

Completion is webhook-driven. `ProcessBulkOperationNotification` receives the webhook, queries the final status/URL via `GetBulkOperation` GraphQL, and updates the record. The `OnModify` trigger on `Shpfy Bulk Operation` table dispatches to the interface: on Completed, it calls `RevertFailedRequests` (parse the JSONL result, find which variants succeeded, revert the rest); on Canceled/Failed, it calls `RevertAllRequests` (revert everything to the pre-sync values). The `Processed` flag prevents double-processing.

For price updates (`ShpfyBulkUpdateProductPrice.Codeunit.al`), revert means restoring the variant's Price, Compare at Price, Updated At, and Unit Cost from the stored request data. For image updates (`ShpfyBulkUpdateProductImage.Codeunit.al`), only `RevertAllRequests` is implemented (restores the image hash); `RevertFailedRequests` is a no-op since partial image failures are acceptable.

Enabling bulk operations requires a licensed BC user (validated via `WebhookManagement.IsValidNotificationRunAsUser`) because it registers a webhook subscription.
