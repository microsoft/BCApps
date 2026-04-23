# Bulk Operations

Tests for Shopify's bulk mutation API -- the asynchronous batch processing path used for large-scale product operations. This module is separate from Products because bulk operations have their own lifecycle (staged upload, mutation submission, polling, result processing, revert) that is independent of the per-product sync logic.

## How it works

The bulk operations system works in stages: upload a JSONL file to a staged URL, submit a bulk mutation referencing that upload, then poll for completion and process results. ShpfyBulkOperationsTest covers this entire lifecycle. It tests sending a bulk mutation (which creates a "Shpfy Bulk Operation" record), sending a second after the first completes, blocking a second while the first is still running, and handling upload failures silently. The HTTP handler dispatches on a `GraphQLResponses` queue that tracks expected request types (StagedUpload, BulkMutation, CurrentOperation).

The revert tests are particularly interesting. When a bulk operation completes, the system downloads a JSONL result file to identify which individual operations succeeded. `TestBulkOperationRevertFailed` creates 4 variants with original prices, submits a bulk price update, and simulates a partial failure -- only variants 1 and 4 appear in the success result (loaded from `BulkOperationResult.txt` with ID substitution). Variants 2 and 3, which are missing from the result, get their prices reverted to the values stored in the `RequestData` JsonArray on the bulk operation record. `TestBulkOperationRevertAll` tests the failure path where the entire operation fails and all variants are reverted.

ShpfyMockBulkProductCreate implements the `Shpfy IBulk Operation` interface for testing. It provides a productCreate mutation template with placeholder substitution for title, productType, and vendor. Its `RevertFailedRequests` and `RevertAllRequests` methods are no-ops since product creation does not need revert logic.

ShpfyBulkOperationType.EnumExt extends the production `Shpfy Bulk Operation Type` enum with an `AddProduct` test value (ID 139614) that wires to the mock implementation. ShpfyBulkOpSubscriber handles the `OnInvalidUser` event to bypass user validation during tests.

## Things to know

- The enum extension approach for injecting test bulk operation types is the same pattern used elsewhere in the connector for interface-based extensibility -- the test app adds its own enum value that maps to a mock implementation of the `Shpfy IBulk Operation` interface.
- Revert logic relies on the `RequestData` JsonArray stored on the bulk operation record, which contains the original field values (price, compareAtPrice, unitCost) for each variant. If a variant ID is not found in the Shopify result file, its values are restored from this array.
- The HTTP handler distinguishes three URL patterns: POST to the staged upload URL (UploadUrlLbl), GET for the bulk operation result file (BulkOperationUrl), and POST to the Shopify GraphQL endpoint. This three-way routing in a single handler is unique to this test area.
- `BulkOperationRunning` is a module-level boolean that controls whether the CurrentOperation response returns "RUNNING" or "COMPLETED" -- the test for blocked concurrent operations sets this to true before the second send attempt.
- ShpfyBulkOpSubscriber uses `SingleInstance = true` and `EventSubscriberInstance = Manual` but is not explicitly bound in the test codeunit -- it likely gets auto-bound because the test app's event subscribers for `OnInvalidUser` need to fire during bulk operation sends.
- The `BulkMessageHandler` confirms the user-facing message text that appears when a bulk operation is submitted, ensuring UX consistency.
