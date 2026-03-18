# Sample invoice

Demo/sample purchase invoice generation for testing and onboarding. Lets users and connector developers test the inbound e-document pipeline with realistic data without needing a real external vendor to send them an electronic invoice.

## How it works

`E-Doc Sample Purchase Invoice` (codeunit 6209) is the main builder. It uses a fluent pattern: call `AddInvoice` with a vendor number, external document number, and scenario description to set up a header, then call `AddLine` repeatedly to add line items. The codeunit populates temporary `E-Document Purchase Header` and `E-Document Purchase Line` records and can generate a sample PDF via the `E-Doc Sample Purchase Invoice` report. It resolves real data from the current company -- posting dates from the last G/L Entry, vendor details from the Vendor table, item details from the Item table.

`E-Doc Sample Purch.Inv. PDF` (codeunit 6208) is a facade for PDF generation from the temporary purchase header/line buffers. It takes header and line records, feeds them to the report, and returns a TempBlob containing the PDF.

The `E-Doc Sample Purch. Inv File` table (6120) stores generated sample files with their content (Blob), filename, scenario description, and vendor name. The `E-Doc Sample Purch. Inv. Files` page provides a list view.

Three `.docx` report layouts (`EDocSamplePurchInvoice.docx`, `EDocSamplePurchInvoice2.docx`, `EDocSamplePurchInvoice3.docx`) provide different visual styles for the sample invoices. The codeunit can optionally mix layouts across multiple invoices for variety.

## Things to know

- Sample invoices use real vendor and item data from the current company. If the company has no vendors or items, sample generation will fail.
- The `MixLayoutsForPDFGeneration` flag on the codeunit cycles through the three report layouts so a batch of sample invoices looks varied rather than identical.
- `GetSampleInvoicePostingDate` finds the last G/L Entry's posting date to ensure the sample invoice date falls within a valid posting period. It falls back to `WorkDate()` if no entries exist.
- The table uses `Access = Internal` -- sample invoice files are managed entirely through the codeunit API, not through direct table manipulation.
- The `Scenario` field (Text[2048]) provides a human-readable description of what each sample invoice demonstrates (e.g., "Invoice with multiple tax rates" or "Credit memo referencing existing invoice").
