# Bulk operations

Part of [Shopify Connector](../../CLAUDE.md).

Manages Shopify bulk operations for large-scale data updates like product prices and images using GraphQL mutations.

## AL objects

| Type | Name | Purpose |
|------|------|---------|
| Table | Shpfy Bulk Operation (30148) | Tracks bulk operation status and stores request/response data |
| Interface | Shpfy IBulk Operation | Defines contract for bulk operation implementations |
| Codeunit | Shpfy Bulk Operation Mgt. (30270) | Manages bulk operation lifecycle and webhook processing |
| Codeunit | Shpfy Bulk Operation API (30XXX) | GraphQL API calls for bulk operations |
| Codeunit | Shpfy Bulk Update Product Price (30XXX) | Implementation for product price bulk updates |
| Codeunit | Shpfy Bulk Update Product Image (30XXX) | Implementation for product image bulk updates |
| Page | Shpfy Bulk Operations | List view of bulk operations with status |
| Enum | Shpfy Bulk Operation Type (30XXX) | Product Price Update, Product Image Update, etc. |
| Enum | Shpfy Bulk Operation Status (30XXX) | Created, Running, Completed, Failed, Canceled |

## Key concepts

- Bulk operations use Shopify's asynchronous bulk mutation API for large datasets
- Each bulk operation type implements the IBulk Operation interface
- Interface methods: GetGraphQL, GetInput, GetName, GetType, RevertFailedRequests, RevertAllRequests
- Webhook notifications inform BC when bulk operation status changes
- Request Data stored as JSON array for rollback if operation fails
- Only one active bulk operation (Created or Running status) allowed per type per shop
- Processed flag prevents duplicate processing of status changes
- URL and Partial Data URL fields provide access to operation results
- OnModify trigger automatically reverts changes based on operation status
