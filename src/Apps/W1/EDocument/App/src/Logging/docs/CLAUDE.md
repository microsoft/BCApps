# Logging

Three-tier logging design separating business events, technical details, and document content into independent tables with different lifecycles and retention policies.

## The three tiers

**E-Document Log** (`EDocumentLog.Table.al`, table 6105) tracks business-level state transitions. Every status change on an e-document creates a new log entry. The "Step Undone" flag marks entries that were rolled back -- the entry remains for audit but is excluded from status calculations. Each entry can link to an E-Doc. Data Storage record for the document content at that point in time.

**E-Document Integration Log** (`EDocumentIntegrationLog.Table.al`, table 6106) captures HTTP request/response pairs from service communication. Stores method, URL, status code, and request/response blobs. This is where you look when a service call fails -- the raw HTTP exchange is preserved here regardless of whether the business-level status was updated.

**E-Doc. Data Storage** (`EDocDataStorage.Table.al`, table 6107) holds the actual document content (XML, JSON, PDF) as blobs, decoupled from the log entries that reference them. The "File Format" enum determines which viewer renders the content. "Data Storage Size" is a cached field to avoid reading blobs just to show file sizes in lists.

## Design decisions

Not every log entry has associated blob content -- only export and import statuses store the document payload. The separation of data storage from logs means content can be purged independently of the audit trail.

`EDocumentLog.Codeunit.al` is the logging utility codeunit. All log writes go through here rather than direct table inserts, ensuring consistent log entry creation across the framework. When an e-document is deleted, `CleanupDocument` in the core handles orphaned data storage records.

Retention policies are configurable per log type through BC's standard retention policy framework, allowing organizations to keep integration logs shorter than document logs.
