# Extensions

Integration surface between E-Document Core and the BC base app. This is the largest subfolder (~40 files) because every BC document page that participates in e-document exchange needs a page extension to wire up actions and status indicators.

## Table extensions

The critical one is `EDocPurchaseHeader.TableExt.al`, which adds two fields to Purchase Header. "E-Document Link" is a bidirectional Guid that joins a Purchase Header record to its originating E-Document record -- the framework uses this to navigate between the two without a rigid foreign key. "Amount Incl. VAT To Inv." supports partial invoicing during the import flow. `EDocPurchaseLine.TableExt.al` adds a matching amount field at the line level.

`EDocumentVendor.TableExt.al` adds "Receive E-Document To" (an enum controlling whether incoming e-documents create purchase orders or purchase invoices) and "E-Document Default Line Type". These fields drive routing decisions in the import pipeline. `EDocPurchPayablesSetup.TableExt.al` adds org-wide defaults for the same settings.

The posted document table extensions (`PostedSalesInvoicewithQR`, `PostedSalesCrdMemoWithQR`, etc.) add QR code blob fields to support the clearance model -- see `src/ClearanceModel/` for the full story.

## Page extensions

Most follow one of two patterns:

- Outbound document pages (Sales Invoice, Service Order, etc.) get a "Send E-Document" action
- Posted document pages get an e-document status factbox and navigation to the E-Document card

## Subfolders

`Sending/` handles Document Sending Profile integration. `EDocSendingProfile.Codeunit.al` hooks into BC's sending profile framework so that selecting an e-document profile on a customer triggers the e-document workflow instead of the standard email/print path.

`RoleCenter/` provides cue tiles and the E-Document Activities page for role center integration, giving users at-a-glance counts of pending, failed, and processed e-documents.
