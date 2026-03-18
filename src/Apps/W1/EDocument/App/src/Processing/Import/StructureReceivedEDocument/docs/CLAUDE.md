# Structure received E-Document

Implementations of `IStructureReceivedEDocument` and `IStructuredFormatReader` that convert unstructured or structured blobs into draft table data. This is where format-specific parsing lives -- PEPPOL XML, ADI JSON, and MLLM output.

## How it works

The V2 pipeline's first step calls `IStructureReceivedEDocument.StructureReceivedEDocument` to convert raw data into structured data. For PDF/image inputs, this means calling an external service (Azure Document Intelligence or MLLM) and returning the result as an `IStructuredDataType`. For already-structured formats like XML, it returns the input unchanged.

The PEPPOL handler (`EDocumentPEPPOLHandler`) implements `IStructuredFormatReader` -- it reads UBL Invoice XML into `E-Document Purchase Header` and `E-Document Purchase Line` records. It parses xpath-based fields (supplier party, monetary totals, invoice lines) and returns `"Purchase Document"` as the process draft enum, routing to the standard purchase draft preparation.

## Things to know

- `EDocumentPEPPOLHandler` only supports Invoice documents. Credit notes throw an error. This is a deliberate limitation -- credit note support would require a separate document type flow.

- The PEPPOL reader sets currency by comparing against `General Ledger Setup."LCY Code"`. If the document currency matches LCY, it stores blank (BC convention for local currency). This applies to both header and line-level currency codes.

- ADI and MLLM structuring implementations are not in this directory -- they live in `Processing/AI/`. The `Structure Received E-Doc.` enum routes to them. This directory only contains the PEPPOL reader and supporting code.

- The "Already Structured" implementation (for XML/JSON inputs) simply copies the unstructured data entry number to the structured data entry number -- no conversion needed, but the step still fires to set up the correct `Read into Draft Impl.` value.

- PEPPOL parsing uses XML namespace prefixes (`cac:`, `cbc:`, `inv:`) that match the UBL 2.1 schema. If a vendor sends non-standard namespace prefixes, the parsing will fail silently (XPath returns no matches) and fields will be blank.
