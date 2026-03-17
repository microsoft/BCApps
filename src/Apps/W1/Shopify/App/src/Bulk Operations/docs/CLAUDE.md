# Bulk operations

Async bulk mutation support for large-scale updates to Shopify (product prices, images). Shopify processes these asynchronously and notifies BC via webhook when complete.

## How it works

The flow starts in `ShpfyBulkOperationMgt.Codeunit.al`. Before sending a new mutation, it checks whether a Created or Running bulk operation already exists for the same shop and type; if so, it polls Shopify for an updated status and only proceeds if the previous operation has finished. The mutation data is uploaded as a JSONL file via a staged upload URL (created through `stagedUploadsCreate`), then the bulk mutation is submitted referencing that uploaded file. The `ShpfyBulkOperation.Table.al` record tracks the operation's lifecycle with status, error code, result URL, and partial data URL.

When Shopify finishes, a `BULK_OPERATIONS_FINISH` webhook arrives and `ShpfyBulkOperationMgt.ProcessBulkOperationNotification` fetches the final status and result URL. The `OnModify` trigger on the bulk operation table drives the revert logic: on completion it calls `IBulkOperation.RevertFailedRequests` (which downloads the JSONL result, identifies successful variant IDs, and reverts local changes for any variant not in the success list), and on cancel/failure it calls `RevertAllRequests`. The `Processed` flag prevents the revert logic from firing more than once.

## Things to know

- The `IBulkOperation` interface has six methods: `GetGraphQL`, `GetInput`, `GetName`, `GetType`, `RevertFailedRequests`, and `RevertAllRequests`. Implementations like `ShpfyBulkUpdateProductPrice` provide the mutation template and know how to parse the JSONL result to determine which items succeeded.
- The threshold for switching from individual API calls to bulk operations is 100 items, returned by `GetBulkOperationThreshold`.
- Request data (the list of items being updated) is stored as a JSON array in a BLOB field on the bulk operation record, so the revert logic can restore original values for failed items.
- Enabling bulk operations requires a valid BC licensed user because it registers a webhook subscription that runs as that user. The `OnInvalidUser` event allows test code to bypass this check.
- Only one bulk operation per shop per type (mutation/query) can be active at a time -- the codeunit enforces this before submission.
