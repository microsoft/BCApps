# Logs

Three logging mechanisms: `Shpfy Log Entry` for API request/response recording, `Shpfy Data Capture` for raw JSON snapshots linked to any entity, and `Shpfy Skipped Record` for records that couldn't be imported. These serve different diagnostic purposes and are referenced throughout the connector.

## How it works

`Shpfy Log Entry` stores individual API calls with request/response blobs, HTTP status codes, method, URL, retry count, query cost, and a Shopify request Id for correlation. `ShpfyLogEntries.Codeunit.al` adds escalation support -- entries with status code 500 that are less than 14 days old can generate a downloadable escalation report containing the request Id, timestamp, store URL, API version, and full request/response payloads for submission to Shopify support.

`Shpfy Data Capture` is a generic JSON snapshot store. Its `Add` method accepts a table number, a SystemId, and JSON data. It computes a hash via `Shpfy Hash` and skips writing if the latest capture for that record already has the same hash, avoiding duplicate snapshots. Nearly every import operation across the connector calls `DataCapture.Add` after writing a record.

`Shpfy Skipped Record` logs records that failed to import with a `Shopify Id`, the table/record that was being processed, and a `Skipped Reason`. The `ShowPage` method uses `Page Management` to navigate directly to the related record from the skipped records list.

## Things to know

- Data Capture links to entities via (Linked To Table, Linked To Id) where `Linked To Id` is the SystemId (Guid), not the primary key. This means if a record is deleted, its data captures become orphaned unless the parent table's OnDelete trigger cleans them up (most Shopify tables do this).
- The hash-based deduplication in `DataCapture.Add` means consecutive identical API responses for the same record produce only one capture entry, keeping storage manageable.
- Log entry deletion is age-based via `DeleteEntries(DaysOld)` on both `ShpfyLogEntry` and `ShpfySkippedRecord`, with a confirmation dialog.
- The escalation report feature in `ShpfyLogEntries.Codeunit.al` first tests the Shopify connection to verify it's a server-side issue, then warns the user to review data for sensitive information before downloading.
- Skipped records store a `Record ID` (RecordID type) that enables the `ShowPage` drill-down, but the description is computed from primary key filters on the referenced record, with special handling for `Shpfy Catalog` which uses the Name field instead.
