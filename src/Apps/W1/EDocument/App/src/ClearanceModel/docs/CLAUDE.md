# ClearanceModel

The ClearanceModel folder implements real-time tax authority clearance validation through QR code generation and display. It extends posted sales and service documents with QR code fields, provides viewer UI, and manages QR code image conversion.

## Quick reference

- **Files:** 16 AL files (1 codeunit, 1 table, 2 pages, 12 extensions)
- **ID range:** 6197 (management), 6196 (buffer table), 6198-6199 (pages)
- **Dependencies:** System.IO (Base64 Convert), System.Text, System.Utilities
- **Extension pattern:** Table/Page/Report extensions for 4 document types

## How it works

Jurisdictions like Saudi Arabia ZATCA and Italy FatturaPA require tax authority clearance before invoices are legally valid. The clearance response includes a QR code containing validation data (clearance ID, timestamp, hash). This folder extends Posted Sales Invoice, Posted Sales Cr.Memo, Posted Service Invoice, and Posted Service Cr.Memo with a "QR Code Base64" blob field that stores the Base64-encoded PNG image.

The **EDocument QR Code Management** codeunit provides three core operations: initialize and display QR viewer from source document, export QR code to file, and convert Base64 string to image for UI display. A temporary buffer table (EDocQRBuffer) intermediates between source documents and the viewer page.

Extensions are organized in triplets (TableExt, PageExt, ReportExt) for each document type, adding the QR field, viewer action, and QR code placeholder in report layouts.

## Structure

- `EDocumentQRCodeManagement.Codeunit.al` -- Core QR operations (view, export, convert)
- `EDocQRBuffer.Table.al` -- Temporary buffer with Document Type + No + QR blob
- `EDocumentQRViewer.Page.al` -- Simple viewer showing QR image + metadata
- `EDocumentQRCodeViewer.Page.al` -- Enhanced viewer with export action
- `PostedSalesInvoicewithQR.TableExt.al` -- Adds "QR Code Base64" blob field
- `PostedSalesInvoicewithQR.PageExt.al` -- Adds "View QR Code" action
- `PostedSalesInvoiceWithQR.ReportExt.al` -- Adds QR placeholder in layout
- (Repeat for Sales Cr.Memo, Service Invoice, Service Cr.Memo)

## Documentation

- [Business logic](business-logic.md) -- QR generation workflow, viewer initialization, image conversion
- [Data model](data-model.md) -- QR Buffer schema, extension field structure

## Things to know

- **Base64 storage:** QR codes are stored as Base64-encoded PNG images in blob fields, not as binary. This simplifies API integration (clearance services return Base64).
- **Temporary buffer pattern:** EDocQRBuffer is always temporary; it acts as a data transfer object between source document and viewer page. No persistent storage beyond source document blob fields.
- **Document type detection:** InitializeAndRunQRCodeViewer uses RecordRef.Number to switch on source table, ensuring type-safe casting to specific document records.
- **CalcFields requirement:** QR Code Base64 is a blob field, requiring CalcFields before checking HasValue or CreateInStream.
- **No QR code message:** If CalcFields returns no value, displays user-friendly message "No QR code available for {DocumentType} {No}" instead of error.
- **Image conversion for UI:** The viewer page cannot display Base64 text directly; SetQRCodeImageFromBase64 converts to binary stream and imports into Media field for rendering.
- **Export workflow:** ExportQRCodeToFile converts Base64 → binary TempBlob → file download dialog with filename format "{DocumentType}_{No}_QRCode.png".
- **Extension point for localization:** Partners can extend the management codeunit to add custom QR formats (e.g., EAN-128, Data Matrix) or embed additional metadata.
- **Report integration:** Report extensions add an Image control placeholder; at runtime, the QR code is injected into the placeholder before PDF generation.
- **Clearance timestamp:** E-Document."Clearance Date" field (in Document folder) tracks when authority cleared the document; QR code typically includes this timestamp as encoded data.
- **Security consideration:** QR codes contain document hash and clearance ID, enabling offline validation by scanning the code and checking against authority's public API.
