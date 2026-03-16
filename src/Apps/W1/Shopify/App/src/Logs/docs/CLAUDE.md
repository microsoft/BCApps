# Logs

API logging, diagnostics, and data capture for the Shopify Connector. This module provides three storage mechanisms for troubleshooting sync issues: structured API log entries, raw JSON data captures, and skipped record tracking. It is a shared infrastructure module used by all other Shopify modules.

## How it works

`Shpfy Log Entry` (table 30115) records every HTTP request to the Shopify API. Each entry stores the URL, method, status code, status description, request and response bodies as blobs, and a `Has Error` flag. The `Request Preview` and `Response Preview` fields hold the first 50 characters of each blob for quick scanning without loading the full payload. A `Query Cost` field tracks the GraphQL query cost for monitoring API quota consumption, and `Retry Count` records how many retries were needed. The `Shpfy Request Id` field stores Shopify's request ID for cross-referencing with Shopify's own logs. `ShpfyLogEntries.Codeunit.al` manages creation of log entries, and `ShpfyLogEntriesDelete.Codeunit.al` handles cleanup.

`Shpfy Data Capture` (table 30114) stores raw JSON snapshots linked to specific records in other tables via (`Linked To Table`, `Linked To Id`). The `Add` method computes a hash of the incoming data and skips storage if the hash matches the last capture for that record -- this deduplication prevents storing identical snapshots on repeated syncs without changes. The hash is stored in `Hash No.` for comparison.

`Shpfy Skipped Record` (table 30159) logs records that were intentionally skipped during import or export, with a `Skipped Reason` explanation, the source `Record ID`, and a `Shopify Id`. It provides a `ShowPage` method that navigates to the related BC record via `PageManagement`, and a `DeleteEntries` method for age-based cleanup.

## Things to know

- Log entry request/response bodies are blob fields read via `TypeHelper.ReadAsTextWithSeparator` -- they can be arbitrarily large.
- The `SetRequest` / `SetResponse` methods automatically populate the 50-character preview fields, so the list page can show a snippet without CalcFields.
- Data capture hash dedup means that if the same JSON is returned on consecutive syncs, only one copy is stored -- this significantly reduces database growth.
- Data captures are cleaned up by the owning table's `OnDelete` trigger (e.g., deleting an order transaction deletes its captures).
- Skipped records resolve their `Table Name` and `Description` dynamically from `AllObjWithCaption` and `RecordRef` -- special handling exists for `Shpfy Catalog` to show the catalog name instead of a key filter.
- The `ShpfySkippedRecord.Codeunit.al` provides helper methods for logging skipped records from various modules, accepting different parameter combinations (record ID, Shopify ID, or both).
