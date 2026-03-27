# E-Document Connector - Avalara

Connects Business Central's E-Document framework to Avalara's e-invoicing API for cross-border compliance. Implements the E-Document Core interfaces to send and receive electronic invoices in UBL format through Avalara's platform. Handles OAuth authentication, company and mandate selection, and automatic format mapping based on document type.

## Quick reference

- **ID range**: 6370-6380
- **Dependencies**: E-Document Core

## How it works

The connector implements three E-Document Core interfaces: IDocumentSender (sends documents to Avalara), IDocumentReceiver (polls for incoming documents), and IDocumentResponseHandler (processes API responses). Authentication uses OAuth 2.0 client credentials flow with tokens cached for their lifetime minus a 60-second buffer.

Send flow starts by fetching the mandate for the destination country/customer from Avalara, then builds metadata JSON and POSTs a multipart request (metadata + UBL payload) to `/einvoicing/documents`. The response contains an Avalara Document Id stored in integration fields. Credit memos use `ubl-creditnote` format; all other documents use `ubl-invoice`.

Receive flow calls GET `/einvoicing/documents` filtered by the selected Avalara company, then recursively follows `@nextLink` pagination until all documents are retrieved. Each document's metadata and payload are downloaded separately and converted into E-Document records.

Setup is intentionally simple: one ConnectionSetup record per environment stores OAuth credentials via IsolatedStorage indirection (actual secrets never touch normal tables). Mandates and companies are temporary tables fetched fresh from the API on every lookup -- no local caching, which keeps the data model minimal but requires stable API connectivity.

## Structure

- `src/` -- Codeunits for send/receive logic, connection setup page, and API client
- `Permissions/` -- Permission sets for connector setup and use

## Documentation

- [docs/data-model.md](docs/data-model.md) -- How the data fits together
- [docs/business-logic.md](docs/business-logic.md) -- Processing flows and gotchas
- [docs/extensibility.md](docs/extensibility.md) -- Extension points and how to customize
- [docs/patterns.md](docs/patterns.md) -- Recurring code patterns (and legacy ones to avoid)

## Things to know

- Mandates and companies are fetched from Avalara on every lookup -- no local persistence. If the API is slow or down, lookups fail.
- Token refresh uses a 60-second buffer: if the token expires in less than 60 seconds, it's considered expired and refreshed proactively.
- The connector stores OAuth secrets in IsolatedStorage via helper codeunits, never directly in ConnectionSetup fields. This prevents secrets from appearing in logs or exports.
- Document format selection is hardcoded: credit memos → `ubl-creditnote`, everything else → `ubl-invoice`. No extensibility point for custom formats.
- Send errors are surfaced via IDocumentResponseHandler -- Avalara's API returns structured error JSON that gets logged to E-Document error fields.
- Receive polling fetches all documents for the selected company, filtered by date range. No incremental sync -- each poll starts from scratch within the date window.
- Pagination uses `@nextLink` from Avalara's JSON response. The connector recursively follows links until `@nextLink` is missing.
- The ConnectionSetup is a singleton enforced by code -- only one Avalara connection allowed per environment.
- Multipart send request combines metadata (JSON) and payload (UBL XML) in a single POST. Metadata contains mandate, company, document type, and workflow code.
- Avalara Document Id is stored in E-Document integration fields after send, used for status tracking and correlation with received documents.
