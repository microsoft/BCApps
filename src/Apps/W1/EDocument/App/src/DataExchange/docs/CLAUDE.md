# DataExchange

Bridge between the E-Document framework and BC's standard Data Exchange
Framework. This is the alternative to the direct PEPPOL BIS 3.0 format --
it uses configurable Data Exchange Definitions for both export and import.

## E-Doc. Service Data Exch. Def.

Configuration table keyed by (E-Document Format Code, Document Type). Each
row maps to an import and/or export Data Exchange Definition code. This
lets a single service handle multiple document types, each with its own
data exchange definition.

## E-Doc. Data Exchange Impl.

Codeunit 6152 implements the `E-Document` interface using the Data Exchange
framework:

- **Export** -- looks up the export data exchange definition, creates a
  `Data Exch.` record with the source document lines as table filters,
  runs `ExportFromDataExch`, and captures the resulting blob.

- **Import** -- runs each configured import data exchange definition
  against the inbound XML to find the best match (highest intermediate
  record count). Then processes the intermediate data into temporary
  Purchase Header/Line records. Header fields are extracted using XPath
  from the data exchange line definitions.

Batch processing is not supported through this implementation.

## PEPPOL pre-mapping codeunits

The `PEPPOL Data Exchange Definition/` subfolder contains codeunits that
run as the `Data Handling Codeunit` in PEPPOL data exchange definitions:

- `E-Doc. DED PEPPOL Pre-Mapping` -- the main pre-mapping codeunit for
  purchase headers. Validates currency, resolves buy-from/pay-to vendors
  (by GLN, VAT reg no, bank account, phone, name+address), sets document
  type, finds invoices to apply credit memos to, and resolves G/L accounts
  for lines.

- `PreMapSalesInvLine`, `PreMapSalesCrMemoLine`, `PreMapServiceInvLine`,
  `PreMapServiceCrMemoLine` -- line-level pre-mapping for export.

- `E-Doc. DED PEPPOL Subscribers` -- event subscribers that wire up the
  pre-mapping codeunits.

## When this is used

This path is active when a service's Document Format points to a format
that uses the `E-Doc. Data Exchange Impl.` codeunit. It was the original
V1 import mechanism before the direct PEPPOL parser. The V1 import
process (`Import Process` = Version 1.0) still uses this path.
