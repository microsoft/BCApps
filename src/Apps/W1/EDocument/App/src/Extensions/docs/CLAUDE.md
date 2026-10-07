# Extensions

Base app integration surface -- table extensions, page extensions, and enum extensions that embed E-Document capabilities into existing BC entities. This module contains little orchestration logic; it mainly adds fields, guards, actions, previews, and factboxes so that E-Documents are visible and actionable from the pages users already work in.

## How it works

*Updated: 2026-07-29 -- Refreshed purchase setup, preview, attachment, and page-action behavior.*

The module operates at three levels:

**Document Sending Profile integration** (`Sending/` subfolder): The `EDocSendProfileElecDoc` enum extension adds the `"Extended E-Document Service Flow"` option to the Electronic Document field. The `EDocumentSendingProfile` table extension adds `"Electronic Service Flow"` (a workflow code reference). The `EDocSendingProfAttType` enum extension adds `"E-Document"` and `"PDF & E-Document"` as email attachment types. Together, these connect BC's existing document sending infrastructure to the E-Document workflow engine.

**Purchase-side fields**: `EDocPurchaseHeader` adds `"E-Document Link"` (a Guid matching the E-Document's SystemId for linking incoming documents to purchase orders and invoices) and `"Amount Incl. VAT To Inv."` (a FlowField summing line amounts for partial invoicing). It also prevents deleting a purchase order that is linked to an active, non-canceled E-Document. `EDocPurchaseLine` adds matching `"Amount Incl. VAT To Inv."` with rounding logic and an `HasEDocMatch` helper for order matching. The `EDocPurchPayablesSetup` table extension adds matching tolerance, Copilot learning, default posting date behavior for purchase invoices created from e-documents, VAT difference handling, and VAT product posting group resolution.

**Sales-side fields**: `EDocSalesHeader` adds `"E-Document Link"` to Sales Header with a secondary key and the same `IsLinkedToEDoc` helper pattern used by Purchase Header. This supports incoming sales order draft processing that needs to link a BC sales document back to the E-Document SystemId.

**Vendor/Location/Attachment fields**: Vendor and Vendor Template get `"Receive E-Document To"` (controls whether incoming e-docs create Purchase Orders or Purchase Invoices, defaulting to Purchase Order). Location gets `"Transfer Doc. Sending Profile"` for transfer shipment routing. Document Attachment gets `"E-Document Attachment"` and `"E-Document Entry No."` to link attachments back to their source E-Document.

**Page extensions** add E-Document action groups (Open/Create), PDF preview factboxes, and document-source actions to posted sales invoices, credit memos, service documents, purchase documents, purchase invoice lists, and shipments. Role center extensions (`RoleCenter/` subfolder) add E-Document activities/cues to Accountant, Business Manager, Inventory Manager, and other standard role centers.

## Things to know

*Updated: 2026-07-29 -- Added factbox preview, attachment upload, and failure-message gotchas.*

- The `"E-Document Link"` Guid on Purchase Header is indexed (secondary key) for fast lookup during incoming document matching. It stores the E-Document's `SystemId`, not its `"Entry No"`. Sales Header now follows the same link pattern for incoming sales order processing.

- The `"Receive E-Document To"` field on Vendor only allows `"Purchase Order"` or `"Purchase Invoice"` -- it uses `ValuesAllowed` to restrict the enum. This determines the default document type created when an incoming e-document is received from that vendor.

- Purchase invoice pages and posted purchase invoice pages host the `Inbound E-Doc. Picture` part before the standard Incoming Document attachment factbox. The host page drives the preview by calling `GetInboundPdfPreviewEntryNo` with the current record id and, for open purchase invoices, the E-Document link Guid. The preview only appears when the linked unstructured data storage entry is a PDF.

- E-Document attachment uploads from the standard document attachment factbox rely on event subscribers, not custom upload UI. `OnAfterGetRecRefFail` resolves the E-Document from the factbox's `E-Document Entry No.` filter, and `OnBeforeInsertAttachment` stamps `E-Document Attachment` plus `E-Document Entry No.` before insert. This is why attachment behavior depends on the factbox filters being preserved.

- Page extensions follow a consistent pattern: an "E-Document" action group with "Open" (enabled when an E-Document exists for the record) and "Create" (enabled when none exists). Posted document Create actions now show an explicit failure message when `CreateEDocumentFromPostedDocumentPage` returns false, so page actions should not silently no-op.

- Purchase order page actions still expose manual line mapping when the linked E-Document service status is `Order Linked`. The Copilot prompt actions are hidden and obsolete in CLEAN29; AI-assisted matching moved to the purchase draft import experience.

- The purchase draft subform exposes a hidden, read-only `Name` column for personalization. It displays the matched item, G/L account, resource, fixed asset, allocation account, or item charge name via `GetMatchedEntityName`, not the extracted invoice description.

- The `"Electronic Service Flow"` on Document Sending Profile has a table relation filtered to `Category = 'EDOC'` and `Template = false`, ensuring only enabled E-Document workflows can be selected.

- `EDocOrderMapActivities` is a standalone page (not an extension) providing the order mapping activities cue for role centers.

See the [app-level CLAUDE.md](../../docs/CLAUDE.md) for broader architecture context.
