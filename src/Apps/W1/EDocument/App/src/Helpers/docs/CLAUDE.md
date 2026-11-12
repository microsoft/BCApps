# Helpers

Utility codeunits used across the E-Document framework. These are not standalone features -- they provide shared services (error handling, import resolution, logging, JSON parsing) that other modules depend on. The boundary is that helpers never initiate processing; they are called by the Processing, Format, and Integration layers.

## How it works

*Updated: 2026-07-29 -- Added persisted error throwing, PDF preview lookup, customer matching, import telemetry, and safer ADI JSON handling.*

**`EDocumentErrorHelper`** implements the collecting-parameter pattern for errors. Instead of throwing on first failure, callers use `LogSimpleErrorMessage` or `LogErrorMessage` to accumulate errors against an E-Document's context. The errors are stored in BC's `"Error Message"` table, scoped by the E-Document's `RecordId`. After processing completes, the framework checks `HasErrors` or calls `ThrowIfHasErrors` to decide whether to proceed or surface the collected errors. `ThrowIfHasErrors` copies the persisted messages to a temporary record, commits them, and throws the collected error so the messages survive the failure. All errors are also forwarded to Feature Telemetry for monitoring.

**`EDocumentImportHelper`** handles the resolution of incoming document data to BC master data. Its main responsibilities are: resolving units of measure (by code, then by International Standard Code, then by description), finding items (by Item Reference, GTIN, vendor item number, or item description), finding vendors (by number, GLN, VAT registration number, service participant, bank account, or name+address), and fuzzy-matching customers by name+address. Each resolution method follows a cascade pattern -- try the most specific match first, fall back to less specific. Vendor matching also records session telemetry for the match method and for name-only candidates whose address did not match. Errors are logged (not thrown) when no match is found.

**`EDocumentHelper`** provides document-level utilities: checking if a RecordRef is an E-Document (`IsElectronicDocument`), retrieving the E-Document Service for a document (checking both live and archived workflow step instances), getting the E-Document blob from logs, finding an inbound PDF preview data-storage entry, and enabling HTTP client requests for the core extension. For outbound documents, service resolution walks the workflow step instance chain; for inbound, it uses the service status table. PDF preview lookup first follows an `E-Document Link` SystemId for open purchase documents, then falls back to the source document RecordId for posted documents, and only returns entries whose unstructured data is actually PDF.

**`EDocumentLogHelper`** is a thin public facade over the internal `"E-Document Log"` codeunit, exposing `InsertLog` and `InsertIntegrationLog` for connector implementations that need to record HTTP request/response pairs or status transitions.

**`EDocumentJsonHelper`** is internal, used for Azure Document Intelligence integration. It parses a specific JSON structure (`outputs.1.result.fields`/`items`) and extracts typed values (text, date, number, currency) into AL variables. Missing `outputs`, `1`, `result`, or `fields` properties now log warning telemetry and return an empty object instead of causing an untrappable JSON error.

## Things to know

*Updated: 2026-07-29 -- Added gotchas for collected-error throwing and inbound PDF preview lookup.*

- `LogSimpleErrorMessage` vs `LogErrorMessage`: the simple version only takes a message string. The full version also takes a related record and field number, which enables drill-down navigation from the error message to the source record.
- Use `ThrowIfHasErrors` when the caller needs to stop after collecting multiple errors but still keep those messages available to the user after the transaction fails.
- `GetInboundPdfPreviewEntryNo` returns 0 for non-PDF unstructured data, missing links, or documents without an E-Document source. Callers must treat 0 as "no preview" rather than as an error.
- The error helper's `ClearErrorMessages` is called before re-processing to avoid stacking duplicate errors from retry attempts.
- `EDocumentImportHelper` UOM resolution tries three paths: exact Code match, International Standard Code match, then Description match. If all fail, the error is logged but import continues -- the line will just have no UOM set.
- `EDocumentHelper.AllowEDocumentCoreHttpCalls` directly manipulates the `"NAV App Setting"` table using the E-Document Core extension's hardcoded app ID (`e1d97edc-c239-46b4-8d84-6368bdf67c8b`).
- `EDocumentJsonHelper` is tightly coupled to Azure Document Intelligence's output schema -- it is not a general-purpose JSON utility.

See the [app-level CLAUDE.md](../../docs/CLAUDE.md) for broader architecture context.
