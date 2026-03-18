# Clearance model

Framework support for tax authority clearance workflows used in countries like Spain, Italy, and India. When a government tax authority "clears" an invoice, it returns a QR code or unique identifier that must be stored on the posted document and printed on invoices.

## What this folder does (and does not do)

This folder handles the result of clearance -- storing and displaying QR codes on posted documents. The clearance workflow itself (submitting to the tax authority, polling for approval, handling rejections) is service-specific and implemented by country localization apps. E-Document Core provides the hooks; localizations provide the integration.

## QR code storage

`EDocumentQRCodeManagement.Codeunit.al` handles QR code generation and storage. `EDocQRBuffer.Table.al` is a temporary buffer used during QR code processing.

The QR code is stored as a base64-encoded image in blob fields added by table extensions to four posted document tables:

- Posted Sales Invoice (`PostedSalesInvoicewithQR.TableExt.al`)
- Posted Sales Credit Memo (`PostedSalesCrdMemoWithQR.TableExt.al`)
- Posted Service Invoice (`PostedServiceInvoiceWithQR.TableExt.al`)
- Posted Service Credit Memo (`PostedServiceCrMemoWithQR.TableExt.al`)

## Display

Matching page extensions add QR code display to each posted document page. Report extensions (`PostedSalesInvoiceWithQR.ReportExt.al`, etc.) embed the QR code in printed and PDF invoice output. Two viewer pages (`EDocumentQRViewer.Page.al` and `EDocumentQRCodeViewer.Page.al`) provide standalone QR code display.

The table extensions in `src/Extensions/` for QR code fields on posted documents are the other half of this story -- they add the storage fields that this folder's codeunits populate.
