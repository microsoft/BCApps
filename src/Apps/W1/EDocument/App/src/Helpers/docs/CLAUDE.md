# Helpers

Utility codeunits for connector and localization developers. These are the recommended public API for common operations that third-party apps need when building E-Document integrations.

## How it works

Five codeunits provide distinct utility surfaces:

`E-Document Error Helper` (codeunit 6115) wraps BC's Error Message framework with E-Document context. Every method takes an E-Document record to set the error context, then delegates to `Error Message` table operations. This ensures errors are associated with the right E-Document and show up in the E-Document's error list. Key methods: `LogSimpleErrorMessage`, `LogErrorMessage` (with related record and field), `LogWarningMessage`, `HasErrors`, `ClearErrorMessages`, and count methods.

`E-Document Helper` (codeunit 6148) is the general-purpose utility. `IsElectronicDocument` checks whether a source document's sending profile enables the E-Document pipeline. `GetEDocumentBlob` retrieves the imported document blob from logs. `AllowEDocumentCoreHttpCalls` enables HttpClient permissions for the E-Document Core extension. `GetServicesInWorkflow` returns the E-Document services used in a specific workflow.

`E-Document Import Helper` (codeunit 6109) provides resolution logic for inbound documents: `ResolveUnitOfMeasureFromDataImport` (tries Code, then International Standard Code, then Description), `FindItemReferenceByItemReference` (lookup by item reference), and vendor resolution utilities. These are the building blocks that format implementations call during import parsing.

`E-Document Log Helper` (codeunit 6131) is a thin public facade over the internal `E-Document Log` codeunit. It exposes `InsertIntegrationLog` and `InsertLog` for connector developers who need to log additional HTTP calls or status changes from their integration code.

`EDocument Json Helper` (codeunit 6121, Internal access) parses the specific JSON structure returned by AI document intelligence services -- extracting header fields and line arrays from the `outputs.1.result` path. This is not a general-purpose JSON utility.

## Things to know

- Error Helper and Import Helper have Public access -- they are the intended API for connector developers. The Json Helper is Internal and specific to the ADI integration path.
- `LogSimpleErrorMessage` is the most common error logging method. It takes just an E-Document and a message string, without needing a related record or field number.
- Import Helper's UOM resolution has a three-step fallback: exact Code match, International Standard Code match, Description match. This handles the variety of UOM representations in PEPPOL documents.
- `AllowEDocumentCoreHttpCalls` directly manipulates `NAV App Setting` records using the hardcoded E-Document Core extension ID. This is an admin-level operation.
- Log Helper exists because the main `E-Document Log` codeunit has Internal access. Third-party apps cannot call it directly, so the helper provides the subset of logging operations that connector developers need.
