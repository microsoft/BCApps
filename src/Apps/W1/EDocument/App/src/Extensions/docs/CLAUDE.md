# Extensions

Base app integration surface -- table extensions, page extensions, and enum extensions that embed E-Document capabilities into existing BC entities. This module does not contain business logic; it adds fields, actions, and factboxes so that E-Documents are visible and actionable from the pages users already work in.

## How it works

The module operates at three levels:

**Document Sending Profile integration** (`Sending/` subfolder): The `EDocSendProfileElecDoc` enum extension adds the `"Extended E-Document Service Flow"` option to the Electronic Document field. The `EDocumentSendingProfile` table extension adds `"Electronic Service Flow"` (a workflow code reference). The `EDocSendingProfAttType` enum extension adds `"E-Document"` and `"PDF & E-Document"` as email attachment types. Together, these connect BC's existing document sending infrastructure to the E-Document workflow engine.

**Purchase-side fields**: `EDocPurchaseHeader` adds `"E-Document Link"` (a Guid matching the E-Document's SystemId for linking incoming documents to purchase orders) and `"Amount Incl. VAT To Inv."` (a FlowField summing line amounts for partial invoicing). `EDocPurchaseLine` adds matching `"Amount Incl. VAT To Inv."` with rounding logic and an `HasEDocMatch` helper for order matching. The `EDocPurchPayablesSetup` table extension adds `"E-Document Matching Difference"` (tolerance percentage) and a Copilot learning flag.

**Vendor/Location/Attachment fields**: Vendor and Vendor Template get `"Receive E-Document To"` (controls whether incoming e-docs create Purchase Orders or Purchase Invoices, defaulting to Purchase Order). Location gets `"Transfer Doc. Sending Profile"` for transfer shipment routing. Document Attachment gets `"E-Document Attachment"` and `"E-Document Entry No."` to link attachments back to their source E-Document.

**Page extensions** add E-Document action groups (Open/Create) and factboxes to posted sales invoices, credit memos, service documents, purchase documents, and shipments. Role center extensions (`RoleCenter/` subfolder) add E-Document activities/cues to Accountant, Business Manager, Inventory Manager, and other standard role centers.

## Things to know

- The `"E-Document Link"` Guid on Purchase Header is indexed (secondary key) for fast lookup during incoming document matching. It stores the E-Document's `SystemId`, not its `"Entry No"`.
- The `"Receive E-Document To"` field on Vendor only allows `"Purchase Order"` or `"Purchase Invoice"` -- it uses `ValuesAllowed` to restrict the enum. This determines the default document type created when an incoming e-document is received from that vendor.
- Page extensions follow a consistent pattern: an "E-Document" action group with "Open" (enabled when an E-Document exists for the record) and "Create" (enabled when none exists). The `EDocumentExists` boolean is computed on page load.
- The `"Electronic Service Flow"` on Document Sending Profile has a table relation filtered to `Category = 'EDOC'` and `Template = false`, ensuring only enabled E-Document workflows can be selected.
- `EDocOrderMapActivities` is a standalone page (not an extension) providing the order mapping activities cue for role centers.

See the [app-level CLAUDE.md](../../docs/CLAUDE.md) for broader architecture context.
