# Document

The central entity layer of E-Document Core. The `E-Document` table (6121) is the master record that tracks every electronic document -- inbound or outbound -- through its full lifecycle. Everything else in the module ultimately points back to an entry in this table.

## How it works

An E-Document is created either by posting a BC sales/service document (outbound) or by receiving a file from an external service (inbound). The `Direction` enum (`EDocumentDirection.Enum.al`) distinguishes the two flows. For outbound documents, `Document Record ID` links back to the originating BC record (posted invoice, credit memo, etc.). For inbound documents, the record starts with Direction = Incoming and no linked document -- it acquires a `Document Record ID` only after the import pipeline successfully creates a purchase document or journal line.

Content is stored externally via two Data Storage pointers: `Unstructured Data Entry No.` holds the raw file (PDF, image), while `Structured Data Entry No.` holds the machine-readable representation (XML, JSON). Both reference `E-Doc. Data Storage` records. This split is fundamental -- a single e-document can have both a human-readable PDF and a PEPPOL XML simultaneously.

The `E-Document Type` enum (`EDocumentType.Enum.al`) covers the full range of BC document types from Sales Quote through Transfer Shipment. It implements `IEDocumentFinishDraft` -- the Purchase Invoice value carries a concrete implementation (`E-Doc. Create Purchase Invoice`) while all others fall back to a default no-op. The `E-Document Format` enum is extensible and implements the `E-Document` interface, which is the contract for creating/parsing documents in a specific wire format (PEPPOL BIS 3.0, Data Exchange, or custom).

## Things to know

- The table has three separate status tracking systems: `Status` (document-level, from the `E-Document Status` enum), the per-service status in `E-Document Service Status` table, and the newer `Import Processing Status` flow field. They serve different purposes but interact -- document-level status is derived pessimistically from service statuses.

- Duplicate detection uses Key3: `Incoming E-Document No.` + `Bill-to/Pay-to No.` + `Document Date`. The `IsDuplicate` procedure checks this composite. Deleting a non-duplicate requires user confirmation (or errors entirely if `GuiAllowed()` is false).

- You cannot delete a Processed e-document, and you cannot delete one that is linked to a BC document (`Document Record ID.TableNo <> 0`). The `CleanupDocument` procedure handles cascading deletes of logs, service statuses, attachments, mapping logs, and imported lines.

- `EDocumentsSetup.Table.al` is obsolete (tagged for removal in 28.0). It was a feature-flag table for the "new e-document experience" that is now the default for most country codes.

- The `E-Document Processing Phase` enum (Create, Release, Prepayment, Post, Map) controls when validation runs during document lifecycle -- the format interface's `Check` procedure receives this phase so it can apply context-appropriate validation.

- `Source Type` (Customer, Vendor, Location, Company) identifies the trading partner type, distinct from `Document Type` which identifies the BC document kind.
