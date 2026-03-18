# ClearanceModel

QR code generation and display for posted documents that have been cleared by a tax authority (e.g., Saudi Arabia ZATCA). This module adds QR code blob fields to posted documents and surfaces them on pages and printed reports. It is country-specific infrastructure that is a silent no-op when no QR data is populated.

## How it works

Four table extensions (`PostedSalesInvoicewithQR.TableExt.al` and siblings) add `QR Code Image` (MediaSet) and `QR Code Base64` (Blob) fields to Sales Invoice Header, Sales Cr.Memo Header, Service Invoice Header, and Service Cr.Memo Header. Corresponding report extensions add the QR Code Image column to the standard printed document reports (Word layout), and page extensions add a QR viewer action to the posted document pages.

`EDocumentQRCodeManagement.Codeunit.al` is the core logic. `InitializeAndRunQRCodeViewer` reads the Base64-encoded QR data from the posted document, copies it to a temporary `EDoc QR Buffer` record, and opens the viewer page. `SetQRCodeImageFromBase64` decodes the Base64 string into a PNG binary and imports it into the MediaSet field for display. `ExportQRCodeToFile` lets users download the QR code as a PNG file.

`EDocQRBuffer.Table.al` is a temporary-only table used as a display container for the QR viewer page. It holds the document type, document number, Base64 blob, and decoded QR image.

## Things to know

- The QR code data itself is written to the posted document by country-specific clearance connectors (e.g., ZATCA). This module only reads and displays it -- it does not generate the QR content.
- If `QR Code Base64` has no value, the viewer shows a message and exits. There is no error -- this is the expected path for countries that do not use clearance.
- The four table/report/page extension triplets are structurally identical across Sales Invoice, Sales Credit Memo, Service Invoice, and Service Credit Memo.
- The report extensions provide Word layout files (`.docx`) stored in `.resources/Template/` that include the QR code image placeholder.
- Base64 decoding uses the standard `Base64 Convert` codeunit. The decoded binary is imported as a `MediaSet` for rendering in the AL client.
- The `EDoc QR Buffer` table is `TableType = Temporary` by declaration, so it never persists data to the database.
