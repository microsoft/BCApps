# Extensions

This area hooks E-Document Core into standard Business Central documents. It extends posted and unposted sales, purchase, service, finance charge, and reminder pages with E-Document actions, extends key tables with E-Document fields, and subscribes to posting events so E-Documents are created automatically when documents are posted.

## How it works

The central piece is `EDocumentSubscribers.Codeunit.al` (codeunit 6103), which subscribes to BC posting events across all supported document types. The pattern for outgoing documents is: subscribe to `OnAfterPost*` events (e.g. `OnAfterPostSalesDoc`, `OnAfterPostServiceDoc`, `OnAfterIssueReminder`) and call `CreateEDocumentFromPostedDocument`. The subscriber first checks whether the customer has a Document Sending Profile with Electronic Document set to "Extended E-Document Service Flow" -- if not, no E-Document is created. For purchase documents, the pattern is different: `OnAfterPostPurchaseDoc` calls `PointEDocumentToPostedDocument`, which re-links an existing incoming E-Document from the Purchase Header to the posted purchase invoice/credit memo.

Before posting, separate `OnBefore*` subscribers run `RunEDocumentCheck` on release and post events to validate that required E-Document fields are present. This means validation failures surface before the document is committed, not after.

Page extensions follow a repeating pattern -- see `EDocPostedSalesInv.PageExt.al` as representative. Each posted document page gets an "E-Document" action group with Open (enabled when E-Document exists for the record) and Create (enabled when it does not). The `OnAfterGetRecord` trigger checks `EDocument.SetRange("Document Record ID", Rec.RecordId())` to set visibility. Purchase pages like `EDocPurchaseOrder.PageExt.al` also surface inbound E-Document factboxes and order matching actions.

Role center page extensions (`RoleCenter/` subfolder) embed the `E-Document Activities` page part, which shows cue tiles for outgoing/incoming documents split by status (Processed, In Progress, Error) plus counts for linked purchase orders and waiting purchase E-Invoices.

## Things to know

- The subscriber codeunit lives outside this folder, in `Processing/EDocumentSubscribers.Codeunit.al`, but its logic is tightly coupled to the extensions here
- Outgoing E-Documents are only created when the Document Sending Profile has `"Electronic Document" = "Extended E-Document Service Flow"` -- the `EDocSendProfileElecDoc.EnumExt.al` adds this value to the standard BC enum
- The `E-Document Link` field on Purchase Header (`EDocPurchaseHeader.TableExt.al`) is a Guid matching `E-Document.SystemId`, not a record reference -- it links a purchase document to the incoming E-Document that spawned it
- `Receive E-Document To` on Vendor/Vendor Template (`EDocumentVendor.TableExt.al`) controls whether incoming docs become Purchase Orders or Purchase Invoices -- defaults to Purchase Order, only those two values are allowed
- Sending extensions in the `Sending/` subfolder add "E-Document" and "PDF & E-Document" email attachment types, and wire up the Electronic Service Flow (workflow code) on Document Sending Profile
- The `E-Doc. Attachment` table extension tags Document Attachment records with an E-Document Entry No., enabling attachment movement when `Document Record ID` changes (e.g. when a draft purchase becomes a posted invoice)
- Deleting a Purchase Header linked to an E-Document triggers a confirmation dialog and resets the E-Document back to "Draft Ready" status via `E-Doc. Import`
