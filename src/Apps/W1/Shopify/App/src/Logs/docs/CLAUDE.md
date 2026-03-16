# Logs

Part of [Shopify Connector](../../CLAUDE.md).

Provides logging, data capture, and error tracking for Shopify integration operations.

## AL objects

| Type | Name | Purpose |
|------|------|---------|
| Table | Shpfy Log Entry (30115) | Stores HTTP request/response logs for API calls with status and error info |
| Table | Shpfy Data Capture (30114) | Stores JSON snapshots of imported records for troubleshooting |
| Table | Shpfy Skipped Record (30159) | Tracks records that failed to process with reason codes |
| Codeunit | Shpfy Log Entries (30XXX) | Manages log entry creation and retrieval |
| Codeunit | Shpfy Log Entries Delete (30XXX) | Batch deletion of old log entries |
| Codeunit | Shpfy Skipped Record (30XXX) | Logs skipped records with reasons |
| Page | Shpfy Log Entries | List view of API call logs |
| Page | Shpfy Log Entry Card | Detail view of individual log entry |
| Page | Shpfy Data Capture List | View captured JSON data |
| Page | Shpfy Skipped Records | List of skipped records with actions |

## Key concepts

- Log entries capture all GraphQL API requests and responses as BLOBs
- Request Preview and Response Preview fields show first 50 characters for quick scanning
- Data Capture stores JSON snapshots linked to specific table records via SystemId
- Hash No. in Data Capture prevents duplicate snapshots of unchanged data
- Skipped records track processing failures with table, record ID, and reason
- Retry Count and Query Cost fields help monitor API usage and performance
- Shpfy Request Id tracks Shopify's request identifier for support cases
- Data Capture automatically deleted when parent records are deleted
