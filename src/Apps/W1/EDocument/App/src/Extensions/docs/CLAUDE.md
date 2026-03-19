# Extensions

This folder extends standard BC base objects so they participate in the
E-Document framework. Nothing here owns core logic -- it adds fields,
actions, and cue tiles that surface e-document data on existing pages.

## What gets extended and why

The E-Document app cannot modify base tables directly, so table extensions
add the fields that link base records into the e-document lifecycle:

- **Purchase Header** -- `E-Document Link` (Guid) and `Amount Incl. VAT To Inv.`
  (FlowField). The link is a SystemId reference to the E-Document record
  that created this purchase document during import. It is **transient** --
  set during draft processing and cleared once the document is finalized.
  Do not confuse it with `Document Record ID` on the E-Document table,
  which is the permanent reverse pointer from the e-document to the posted
  document.

- **Purchase Line** -- `Amount Incl. VAT To Inv.` calculates the portion of
  the line amount corresponding to the qty-to-invoice. Also exposes
  `HasEDocMatch` to check whether the line has been matched to an
  e-document order line.

- **Vendor / Vendor Template** -- `Receive E-Document To` (enum limited to
  Purchase Order or Purchase Invoice). This controls whether incoming
  e-documents for this vendor create a purchase order or a purchase
  invoice. Defaults to Purchase Order.

- **Document Attachment** -- `E-Document Attachment` flag and
  `E-Document Entry No.` link. Attachments extracted from inbound
  e-documents (e.g. embedded PDFs in PEPPOL XML) are stored as standard
  Document Attachments with these fields set so the system knows they
  originated from an e-document.

- **Location** -- `Transfer Doc. Sending Profile` points to a Document
  Sending Profile, enabling transfer shipment documents to flow through
  the e-document pipeline per location.

- **Purchases & Payables Setup** -- `E-Document Matching Difference` (a
  tolerance percentage for order matching) and
  `E-Document Learn Copilot Matchings` (opt-in for Copilot-assisted
  line matching).

## Sending profile extensions

The `Sending/` subfolder extends the Document Sending Profile system:

- Enum extension adds `"Extended E-Document Service Flow"` to the
  Electronic Document options on the sending profile. This is what
  connects a sending profile to a BC Workflow that orchestrates
  multi-service e-document export and send.

- Enum extension adds `"E-Document"` and `"PDF & E-Document"` to the
  email attachment type options.

- Table extension on Document Sending Profile adds
  `"Electronic Service Flow"` (Code[20]), which references a Workflow
  record in the EDOC category. When the Electronic Document option is set
  to Extended E-Document Service Flow, this field must point to an enabled
  workflow.

- Page extensions on Select Sending Options and Document Sending Profile
  expose these new fields and control visibility based on the selected
  electronic document option.

## Page extensions on document pages

Page extensions add an **E-Document** action group to Sales, Purchase,
and Service document pages:

- On unposted purchase documents (Invoice, Credit Memo, Order), the
  actions include "Open E-Document Draft" and "View E-Document Source"
  (visible only when `E-Document Link` is populated), plus
  "Preview E-Document Mapping".

- On posted documents (Sales/Purchase/Service Invoices and Credit Memos,
  Sales Shipments, Transfer Shipments), the action is simply "Open" which
  navigates to the E-Document card via `Document Record ID`.

- On sales documents, the action is "Preview E-Document Mapping" which
  lets users see what field transformations would be applied before export.

## Role center extensions

The `RoleCenter/` subfolder embeds the `E-Document Activities` cue part
into several role centers (Accountant, Business Manager, AP Admin,
Inventory Manager, Ship/Receive/WMS). The activities part shows counts
of outgoing/incoming e-documents by status (Processed, In Progress,
Error) plus linked purchase orders and waiting purchase e-invoices.

A second activities page (`E-Doc. Order Map. Activities`) provides a
focused incoming-only view for the warehouse-oriented role centers.

## Gotchas

- `E-Document Link` on Purchase Header is a **Guid matching the
  E-Document SystemId**, not a Document Record ID. It is set during draft
  import and cleared when the document is finalized. Code that checks for
  linked e-documents should use `IsLinkedToEDoc()` which excludes the
  e-document being processed.

- The `Receive E-Document To` setting on Vendor controls document
  creation type at import time. Changing it after import has no effect
  on already-created documents.

- The sending profile extensions interact with the Workflow folder --
  the `Electronic Service Flow` field must reference a workflow in the
  EDOC category that is enabled.
