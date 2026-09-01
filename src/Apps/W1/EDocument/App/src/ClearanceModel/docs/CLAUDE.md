# Clearance model

QR code storage and display for tax authority clearance scenarios. In countries with clearance models (e.g., Spain, India, Saudi Arabia), invoices must be submitted to a tax authority that stamps them with a QR code or similar token. This module provides the infrastructure to store those QR codes on posted documents and display them to users. It does not perform the clearance itself -- that is handled by country-specific connectors that write QR data back to these fields.

## How it works

The module adds two fields to each of four posted document tables (Sales Invoice Header, Sales Cr.Memo Header, Service Invoice Header, Service Cr.Memo Header) via table extensions: `"QR Code Image"` (MediaSet for display) and `"QR Code Base64"` (Blob for raw data). Matching page extensions add a "View QR Code" action to each posted document page, and report extensions include the QR image in printed documents.

`EDocumentQRCodeManagement` is the central codeunit. `InitializeAndRunQRCodeViewer` takes a RecordRef, extracts the QR Code Base64 from the appropriate table, copies it to a temporary `EDocQRBuffer` record, and opens the `E-Document QR Viewer` page as modal. The buffer table exists because the viewer needs a temporary, table-agnostic record to display. `ExportQRCodeToFile` decodes the base64 to a PNG and triggers a file download. `SetQRCodeImageFromBase64` converts the stored base64 into a MediaSet for inline display on document pages.

## Things to know

- The QR data is stored as base64 text in a Blob field, not as a MediaSet directly. `SetQRCodeImageFromBase64` must be called to populate the MediaSet field for inline rendering. This two-field approach allows both raw export and rendered display.
- The module is purely passive storage -- connectors write the QR data after clearance, and this module reads it. There are no events or triggers that fire during the clearance process.
- All four document types (Sales Invoice, Sales Credit Memo, Service Invoice, Service Credit Memo) follow an identical pattern -- the table/page/report extensions are near-copies of each other.
- The `EDocQRBuffer` table is declared as `TableType = Temporary` and `Access = Internal` -- it never persists data. It exists solely as a transport between the management codeunit and the viewer page.
- If no QR data exists for a document, the viewer shows a user-friendly message ("No QR Base64 content available for...") and exits without opening the page.

See the [app-level CLAUDE.md](../../docs/CLAUDE.md) for broader architecture context.
