# Logs

HTTP request/response logging, raw data capture for audit, and skipped record tracking.

`Shpfy Log Entry` (`ShpfyLogEntry.Table.al`) records every Shopify API call. Request and response bodies are stored as BLOBs (with 50-char preview fields for list display). Key diagnostic fields: `Status Code`, `Has Error`, `Retry Count`, `Query Cost` (the GraphQL cost returned by Shopify), `Shpfy Request Id` (Shopify's correlation ID for support escalation), URL, and HTTP method. The `ShpfyLogEntries.Codeunit.al` provides download helpers for request/response JSON and an escalation report generator that bundles all details into a text file for Shopify support -- gated behind a connection test and limited to status-500 entries within the last 14 days.

`Shpfy Data Capture` (`ShpfyDataCapture.Table.al`) stores raw JSON payloads linked to specific records via `Linked To Table` (table number) and `Linked To Id` (SystemId). It uses a hash-based dedup -- new captures are skipped if the hash matches the previous entry for the same record. This is used throughout the connector (transactions, payouts, payment transactions) to preserve the original Shopify JSON for audit purposes. Records clean up via cascade delete when the parent is deleted.

`Shpfy Skipped Record` (`ShpfySkippedRecord.Table.al`) tracks records that were intentionally skipped during sync, with a `Skipped Reason` and a link back to the source `Record ID`. The `ShpfySkippedRecord.Codeunit.al` sends a one-time notification in the UI when records are skipped and respects the shop's `Logging Mode` setting (skips are not logged when logging is disabled). Both log entries and skipped records support age-based deletion and integrate with BC's retention policy framework via `ShpfyLogEntriesDelete.Codeunit.al`.
