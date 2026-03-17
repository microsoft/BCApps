# Logs

Provides activity logging infrastructure for the Shopify Connector, including API request/response logging, skipped record tracking, and escalation report generation for Shopify support.

## Quick reference

- **Entry point(s)**: `Codeunits/ShpfyLogEntries.Codeunit.al`, `Codeunits/ShpfySkippedRecord.Codeunit.al`
- **Key patterns**: Blob-based request/response storage, notification-based UI for skipped records

## Structure

- Codeunits (3): LogEntries (viewing, deleting, escalation), LogEntriesDelete, SkippedRecord
- Tables (3): LogEntry, DataCapture, SkippedRecord
- Pages (4): DataCaptureList, LogEntries, LogEntryCard, SkippedRecords

## Key concepts

- `LogEntry` stores each Shopify API call with request/response as BLOBs, status code, URL, method, Shopify request ID, query cost, and retry count
- `DataCapture` stores raw JSON snapshots of imported Shopify entities (linked by table ID and record SystemId), used for debugging throughout the connector
- `SkippedRecord` logs records that were skipped during sync with a reason; a notification is shown to the user with a link to view all skipped records (sent once per sync session)
- Skipped record logging respects the shop's `Logging Mode` setting -- disabled logging suppresses skipped record creation
- Log entries with status code 500 that are within 14 days can generate an escalation report (text file) containing request ID, timestamp, store URL, API version, and the request/response data for Shopify support
