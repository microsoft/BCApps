# Clearance model

QR code display support for government clearance e-invoicing jurisdictions (Spain, India, Mexico, Italy). In a clearance model, the government must approve an invoice before it is legally valid, and the QR code is the proof of that approval.

## How it works

Table extensions add `QR Code Image` (MediaSet) and `QR Code Base64` (Blob) fields to four posted document tables: Sales Invoice Header, Sales Cr.Memo Header, Service Invoice Header, and Service Cr.Memo Header. Country-specific connector apps populate these fields after receiving clearance approval from the government API -- this module only handles the display side.

The `EDocumentQRCodeManagement` codeunit (6197) provides the viewer: `InitializeAndRunQRCodeViewer` takes a RecordRef for any of the four supported tables, reads the Base64 blob, copies it into a temporary `EDoc QR Buffer` record, and opens the QR viewer page. It also has `ExportQRCodeToFile` to decode the Base64 and save a PNG, and `SetQRCodeImageFromBase64` to convert the Base64 blob into a MediaSet for inline display on reports.

Page extensions add a "View QR Code" action to the four posted document pages. Report extensions add the QR code image to the standard invoice/credit memo report layouts.

## Things to know

- `EDoc QR Buffer` (table 6166) is `TableType = Temporary` -- it never persists to the database. It exists only to pass QR data to the viewer page.
- The QR code content is stored as Base64 text in a Blob field, not as a direct image. The codeunit decodes it to PNG on demand for export or MediaSet conversion.
- This module does not generate QR codes or interact with government APIs. That responsibility belongs to country-specific connector apps. The clearance model module only provides storage fields and UI for displaying the result.
- Four table extensions, four page extensions, and four report extensions follow the same pattern for Sales Invoice, Sales Credit Memo, Service Invoice, and Service Credit Memo. Transfer documents and purchase documents are not covered.
- The `EDocumentQRViewer.Page.al` and `EDocumentQRCodeViewer.Page.al` are two separate pages -- one shows the QR as an image, the other provides export functionality.
