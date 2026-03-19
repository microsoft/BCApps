# ClearanceModel

Support for tax authority clearance jurisdictions where invoices must be
pre-approved by a government authority before being sent to the buyer.
The authority returns a QR code (or similar stamp) that must appear on
the printed invoice.

## What it does

After a cleared e-document is processed, the integration connector stores
a Base64-encoded QR code image on the posted document. This folder
provides the infrastructure to store, display, and print that QR code.

## Extended BC objects

Table extensions add `QR Code Image` (MediaSet) and `QR Code Base64`
(Blob) fields to four posted document tables:

- Sales Invoice Header
- Sales Cr.Memo Header
- Service Invoice Header
- Service Cr.Memo Header

Page extensions on the corresponding posted document pages add a
"View QR Code" action (visible only when a QR image exists). This opens
the `E-Document QR Viewer` page.

Report extensions on the standard printed invoice/credit memo reports
(Standard Sales - Invoice, Standard Sales - Credit Memo, and their
service equivalents) add the QR Code Image column so it renders on the
printed document. Each report extension includes a Word layout template
with QR code placement.

## QR code management

The `EDocument QR Code Management` codeunit handles viewing and exporting:

- `InitializeAndRunQRCodeViewer` -- reads the Base64 blob from the
  posted document, copies it to a temporary `EDoc QR Buffer`, and opens
  the viewer page.
- `ExportQRCodeToFile` -- decodes the Base64 content to a PNG file and
  triggers a download.
- `SetQRCodeImageFromBase64` -- converts Base64 to a MediaSet image for
  display in report layouts.

## When this is used

The clearance model applies in countries that require government
pre-approval of invoices (e.g. Italy SDI, Spain SII, India e-Way Bill,
Mexico CFDI). The integration connector for those countries is
responsible for submitting the document, receiving the QR code back, and
storing it on the posted document using the fields defined here.
