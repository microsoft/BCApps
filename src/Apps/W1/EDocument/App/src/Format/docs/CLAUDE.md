# Format

Document format implementations that serialize BC records into e-document
XML (export) and parse inbound XML into temporary purchase records (import).

## PEPPOL BIS 3.0

The primary built-in format. `EDoc PEPPOL BIS 3.0` implements the
`E-Document` interface and handles:

- **Export** -- delegates to the existing PEPPOL XMLport codeunits
  (`Sales Invoice - PEPPOL BIS 3.0`, `Sales Cr.Memo - PEPPOL BIS 3.0`,
  etc.) plus dedicated codeunits for shipments, transfer shipments, and
  financial results (reminders/finance charge memos). Supports optional
  PDF embedding via `Embed PDF in export` on the service.

- **Import** -- `EDoc Import PEPPOL BIS 3.0` parses the XML into
  temporary Purchase Header/Line records. `ParseBasicInfo` extracts
  header-level fields (vendor, amounts, dates) for the E-Document record.
  `ParseCompleteInfo` creates the full line-level temporary records.
  Vendor resolution tries GLN, VAT reg no, service participant ID, then
  name+address fallback.

- **Validation** -- `E-Doc. PEPPOL Validation` validates Reminders and
  Finance Charge Memos for PEPPOL compliance (required fields, currency
  codes, country ISO codes). Sales/Service document validation delegates
  to the base app's `PEPPOL Validation` codeunit.

## E-Document Structured Format enum (obsolete)

`E-Document Structured Format` is an obsolete enum (pending removal in
v26) that was used to select how structured inbound documents are read.
It has been replaced by the `Read into Draft Impl.` field on the service.
Values were Azure Document Intelligence and PEPPOL BIS 3.0.

## Extensibility

The `E-Document Format` enum (defined elsewhere in the app) is extensible.
Partners add their own format values and implement the `E-Document`
interface. The format codeunit is resolved at runtime from the service's
`Document Format` field. An `OnAfterCreatePEPPOLXMLDocument` integration
event on the PEPPOL codeunit allows post-processing of the generated XML.

## Other export codeunits

- `E-Doc. Shipment Export To XML` -- generates Despatch Advice XML for
  sales shipments
- `E-Doc. Transfer Shpt. To XML` -- generates XML for transfer shipments
- `Fin. Results - PEPPOL BIS 3.0` (XMLport) -- exports reminders and
  finance charge memos
