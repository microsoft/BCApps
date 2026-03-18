# Document

The E-Document table (6121) is the central transactional entity in the E-Document framework. Every inbound or outbound electronic document -- invoice, credit memo, order, reminder -- gets exactly one record here. It is the unit of work that the rest of the framework (export, integration, import processing) operates on.

## How it works

An E-Document is created with a Direction (Incoming or Outgoing) and a Document Type from the `E-Document Type` enum, which covers sales, purchase, service, finance charge, and reminder document types. For outgoing documents, `Document Record ID` is a `RecordId` pointing back to the source BC document (e.g., a posted sales invoice). For incoming documents, the link is built in the other direction -- once import processing creates a purchase invoice, the `Document Record ID` is set to point at it.

The status model has two independent dimensions. The top-level `E-Document Status` enum has three values: "In Progress", "Processed", and "Error". This status is not stored directly -- it is calculated from the per-service status. The `E-Document Service Status` enum has roughly 20 values (Created, Exported, Sent, Pending Response, Approved, Imported, etc.) and each value implements the `IEDocumentStatus` interface. When the framework needs to compute the overall E-Document status, it calls `GetEDocumentStatus()` on the current service status value. For example, `EDocErrorStatus` returns `Error`, `EDocProcessedStatus` returns `Processed`, and `EDocInProgressStatus` returns `In Progress`. This means new service status values automatically map to the correct overall status just by choosing the right interface implementation in the enum declaration.

For incoming V2 documents, a third status dimension exists: `Import Processing Status` on the `E-Document Service Status` table, which tracks the progress of structured import processing independently from the service-level status.

## Things to know

- `Document Record ID` is a `RecordId` field that bidirectionally links the E-Document to its source or target BC document. When it changes, the `OnValidate` trigger moves document attachments to the new record.
- Two data storage pointers exist: `Unstructured Data Entry No.` (for raw content like PDF) and `Structured Data Entry No.` (for parsed content like XML). Both point to `E-Doc. Data Storage` records.
- `Workflow Step Instance ID` and `Job Queue Entry ID` enable async processing. Workflows fire on status changes, and background jobs handle polling for responses.
- Status implementations drive the overall status -- adding a new `E-Document Service Status` value only requires choosing the right `IEDocumentStatus` implementation (one of the three existing codeunits) in the enum declaration.
- The `E-Document Type` enum also implements `IEDocumentFinishDraft`, which controls how import processing finalizes a draft document. For example, "Purchase Invoice" maps to `"E-Doc. Create Purchase Invoice"`.
- Deletion is guarded: processed documents and documents linked to BC records cannot be deleted. Non-duplicate documents require user confirmation.
- The notification subsystem (`EDocumentNotification.Table.al`, `EDocumentNotification.Codeunit.al`) stores per-user, per-document messages for surfacing import errors or processing results in the UI.
