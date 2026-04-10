# Logs

Captures API call logs, raw data snapshots, and skipped record notifications across the Shopify Connector. This module provides the diagnostic infrastructure that all other modules rely on for troubleshooting.

## How it works

The `Shpfy Log Entry` table records each API call with URL, HTTP method, status code, retry count, and GraphQL query cost. Request and response payloads are stored as BLOBs, with the first 50 characters duplicated into `Request Preview` and `Response Preview` fields for grid display without loading the full blob. Logging is controlled per shop via the `Logging Mode` setting (Disabled, All, or Errors only).

The `Shpfy Data Capture` table provides a separate mechanism for storing raw JSON snapshots of imported Shopify entities. It is keyed by source table and record SystemId, uses content hashing to avoid storing duplicates, and is used throughout the connector (orders, fulfillments, transactions, refunds, etc.) to preserve the original Shopify payload for debugging.

The `Shpfy Skipped Record` table and its codeunit handle records that could not be processed during sync. When a record is skipped, the reason is logged and a notification is sent to the user. The `ShpfyLogEntries` codeunit adds escalation support -- for HTTP 500 errors within 14 days, it can generate a downloadable escalation report containing the request ID, timestamp, store URL, API version, and full request/response data.

## Things to know

- Log entries can be bulk-deleted by age using `DeleteEntries`. Data captures are cleaned up automatically when their parent records are deleted.
- The `Shpfy Request Id` field stores Shopify's request correlation ID, which is needed when escalating server-side errors to Shopify support.
- Skipped records are only logged when the shop's logging mode is not Disabled.
- The `Shpfy Data Capture` table uses a hash-based dedup -- if the JSON payload hash matches the last capture for that record, no new entry is created.
- Escalation reports are only available for 500-status entries less than 14 days old, and require a successful connection test before download.
