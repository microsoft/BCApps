# Helpers

Utility codeunits used across the E-Document app for error handling, logging convenience, import data resolution, and JSON parsing. These are shared building blocks, not standalone features.

## How it works

`EDocumentHelper.Codeunit.al` provides general-purpose utilities: checking if a record is an electronic document (via Document Sending Profile), retrieving an E-Document's service from workflow step arguments, enabling HttpClient permissions for the app, and opening the correct draft page based on the import process version (V1 vs V2).

`EDocumentErrorHelper.Codeunit.al` wraps BC's Error Message table with E-Document context. All methods call `ErrorMessage.SetContext(EDocument)` so errors are scoped to the specific document. It also logs every error to Feature Telemetry with the document's string representation and the error callstack.

`EDocumentImportHelper.Codeunit.al` is the most complex helper. It contains the vendor resolution chain: find by No., then by GLN, then by VAT Registration No., then by service participant, then by phone number, then by name+address (fuzzy matching with 95% nearness threshold). For line items, the resolution chain is: Item Reference (vendor-specific) then GTIN then G/L Account (via Text-to-Account Mapping then Purchases & Payables defaults). It also handles UoM resolution, line discount validation, invoice discount application, and total verification.

`EDocumentLogHelper.Codeunit.al` is a thin public facade over the internal `E-Document Log` codeunit, exposing `InsertLog` and `InsertIntegrationLog` for use by connector extensions.

`EDocumentJsonHelper.Codeunit.al` parses structured JSON responses (from Azure Document Intelligence), extracting header fields and line arrays from a specific `outputs/1/result` structure with typed accessors for text, date, number, and currency values.

## Things to know

- The vendor resolution in Import Helper uses fuzzy string matching (`RecordMatchMgt.CalculateStringNearness`) with a 95% threshold and normalizing factor of 100 -- near-misses in vendor name or address will not match.
- `FindVendorByBankAccount` prefers non-blocked vendors, falling back to payment-blocked, then all-blocked, rather than just returning the first match.
- `FindGLAccountForLine` tries Text-to-Account Mapping with the vendor number first, then without it, then falls back to Purchases & Payables Setup default accounts. Multiple mapping matches log an error rather than picking one.
- Error Helper's `LogSimpleErrorMessage` does not require a related record or field number -- use it for free-form error text.
- JSON Helper's structure (`outputs/1/result/fields` and `outputs/1/result/items`) is specific to Azure Document Intelligence CAPI responses. It uses TryFunction wrappers to silently handle null JSON values.
- Import Helper validates self-billing vendors: if a vendor has `Self-Billing Agreement = true`, incoming e-documents are blocked with an error.
