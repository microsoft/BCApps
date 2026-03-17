# Bulk operations

Orchestrates asynchronous bulk jobs via the Shopify Bulk Operations API, used for high-volume mutations like product image and price updates that exceed single-request thresholds.

## Quick reference

- **Entry point(s)**: `Codeunits/ShpfyBulkOperationMgt.Codeunit.al`, `Codeunits/ShpfyBulkOperationAPI.Codeunit.al`
- **Key patterns**: Interface-based operation types, webhook-driven status updates, JSONL input format

## Structure

- Codeunits (4): BulkOperationMgt (orchestration), BulkOperationAPI (Shopify API calls), BulkUpdateProductImage, BulkUpdateProductPrice
- Tables (1): BulkOperation
- Enums (2): BulkOperationStatus, BulkOperationType
- Interfaces (1): IBulkOperation
- Pages (1): BulkOperations

## Key concepts

- `SendBulkMutation` checks for an existing running/created operation of the same type before submitting a new one; if one is found, it updates its status first and only proceeds if it is no longer active
- The `IBulk Operation` interface requires implementations to provide: `GetGraphQL` (the mutation), `GetInput` (JSONL data), `GetName`, `GetType` (mutation or query), `RevertFailedRequests`, and `RevertAllRequests`
- Built-in implementations: `BulkUpdateProductImage` and `BulkUpdateProductPrice`
- Bulk operations require SaaS environment and a valid BC licensed user; they are tied to the webhook system -- enabling bulk operations also registers a `BULK_OPERATIONS_FINISH` webhook
- The threshold for switching from individual API calls to bulk operations is 100 items (`GetBulkOperationThreshold`)
- Status updates come asynchronously via webhook notifications processed by `ProcessBulkOperationNotification`, which updates status, error code, completion time, and result URLs
