# Logs

API call logging, raw JSON capture, and skipped record tracking. These three facilities serve different diagnostic purposes and are used pervasively by other modules.

## How it works

`ShpfyLogEntry.Table.al` stores one row per API call with the request/response bodies in BLOB fields, plus metadata like URL, HTTP method, status code, retry count, query cost, and the Shopify request ID. The request and response are also previewed in 50-character text fields for quick scanning without loading the BLOBs. `ShpfyLogEntries.Codeunit.al` provides escalation support -- for 500-status entries less than 14 days old, it can generate a downloadable escalation report containing the request ID, timestamp, store URL, API version, and full request/response payloads.

`ShpfyDataCapture.Table.al` stores raw JSON snapshots linked to any record via `Linked To Table` (table ID) and `Linked To Id` (SystemId). It uses hash-based deduplication: the `Add` procedure calculates a hash of the incoming JSON and skips the insert if the last capture for that record has the same hash. This prevents storage bloat when repeated syncs return identical data. Both tables participate in the BC retention policy framework through `ShpfyLogEntriesDelete.Codeunit.al`.

`ShpfySkippedRecord.Codeunit.al` logs records that could not be imported during sync, with the Shopify ID, BC record ID, and a human-readable reason. It sends a one-time notification per sync session (guarded by a `NotificationSent` boolean) so the user is alerted without being spammed. Skipped record logging respects the shop's `Logging Mode` -- when disabled, nothing is written.

## Things to know

- Data captures are keyed by entry number but indexed on `(Linked To Table, Linked To Id)` -- always filter by those fields, not by entry number, when looking up captures for a specific record.
- Log entries and data captures are cleaned up through BC's standard retention policy mechanism, not custom cleanup jobs.
- The skipped record table resolves its `Table Name` and `Description` dynamically from the `Record ID` field using `AllObjWithCaption` and `RecRef`, with a special case for `Shpfy Catalog` where it uses the catalog's `Name` field instead of the PK filter.
- The escalation report feature extracts the store domain from the log entry's URL to find the matching enabled shop, which means it will fail if the shop has been disabled since the error occurred.
