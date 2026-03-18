# Extensions

Table and page extensions that stitch E-Document Core into the base BC application. Without these, no standard BC page would know about e-documents -- they create the "seams" that let users see, configure, and interact with e-document state from their normal workflows.

## How it works

The table extensions add fields to existing BC tables that E-Document Core needs. The most important is the `E-Document Link` Guid on Purchase Header (`EDocPurchaseHeader.TableExt.al`), which is how a BC purchase document links back to its source E-Document record. The Vendor table extension (`EDocumentVendor.TableExt.al`) adds `Receive E-Document To` -- a per-vendor preference controlling whether incoming e-documents create Purchase Orders or Purchase Invoices. The Purchase Line extension adds `Amount Incl. VAT To Inv.`, a computed field that prorates VAT by qty-to-invoice for order matching.

Page extensions surface e-document information on roughly 30 existing BC pages. Posted sales/purchase invoices and credit memos get E-Document factboxes. Sales, purchase, and service document pages gain e-document related fields. The `E-Document Activities` page (`EDocumentActivities.Page.al`) is a CardPart showing outgoing/incoming document counts by status (Processed, In Progress, Error) and is embedded into role centers via the `RoleCenter/` subdirectory.

The `Sending/` subdirectory extends Document Sending Profile to add e-document workflow selection -- this is the user-facing configuration that connects "post and send" to the E-Document pipeline.

## Things to know

- `E-Document Link` on Purchase Header is a Guid, not an integer FK. It matches `E-Document.SystemId`, not `Entry No`. The `IsLinkedToEDoc` helper checks both non-null and not-equal-to-excluded.
- The `Receive E-Document To` enum on Vendor defaults to Purchase Order. This drives whether inbound e-documents create POs (for three-way matching) or go straight to Purchase Invoice.
- `EDocPurchPayablesSetup.TableExt.al` adds `E-Document Matching Difference %` -- a tolerance threshold for automatic line matching during import.
- Document Attachment gets `E-Document Attachment` boolean and `E-Document Entry No.` FK, letting attachments be linked back to their originating e-document.
- Location gets `Transfer Doc. Sending Profile` for transfer shipment e-document support.
- The `.al.orig` files (e.g., `EDocPostedSalesInv.PageExt.al.orig`) are merge artifacts and should be ignored.
