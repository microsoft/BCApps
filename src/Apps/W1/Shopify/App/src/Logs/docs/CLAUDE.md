# Logs

HTTP request/response logging, raw data capture for debugging, and skipped record tracking. Provides the audit trail for all Shopify API communication and records why specific items were skipped during sync.

## How it works

`Shpfy Log Entry` (30115) stores every HTTP request and response as BLOBs, along with URL, method, status code, retry count, query cost, and a Shopify request ID. Preview fields (first 50 characters of request/response) enable quick scanning without loading the full BLOBs. `ShpfyLogEntries` (30304) manages log creation and `ShpfyLogEntriesDelete` handles age-based cleanup.

`Shpfy Data Capture` (30114) is a general-purpose raw JSON storage table used throughout the connector. Every imported Shopify record (orders, fulfillments, transactions, etc.) has its raw JSON saved via `DataCapture.Add()`, keyed by (Linked To Table, Linked To Id). A hash-based deduplication check skips writes when the data hasn't changed.

`Shpfy Skipped Record` (30159) logs records that were skipped during sync with a reason. It stores the BC Record ID, table ID, Shopify ID, and a human-readable description. The `ShowPage` method opens the related BC record directly from the skipped records list.

## Things to know

- Log entries store full request/response content as BLOBs with UTF-8 encoding. The `Request Preview` and `Response Preview` fields (50 chars each) allow list page filtering without materializing the BLOBs.
- `Shpfy Data Capture` uses hash-based deduplication (`Hash.CalcHash()`) -- if the JSON for a record hasn't changed since the last capture, no new row is written. This keeps the table from growing unboundedly during repeated syncs.
- The `Query Cost` field on log entries tracks the actual GraphQL query cost returned by Shopify, useful for diagnosing rate-limiting issues.
- Skipped records auto-resolve the table caption and primary key description from the Record ID field, so the UI shows meaningful identifiers without additional lookups.
- Both log entries and skipped records support age-based deletion via `DeleteEntries(DaysOld)`, with a confirmation dialog to prevent accidental data loss.
