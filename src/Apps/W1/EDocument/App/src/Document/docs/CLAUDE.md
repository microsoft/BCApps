# Document

The Document folder contains the E-Document aggregate root and its supporting types. It defines the central E-Document table, enums for document classification, and the main document card UI. This is the core entity around which all e-document processing revolves.

## Quick reference

- **Files:** 9 AL files (1 table, 1 page, 7 enums)
- **ID range:** 6121 (table/page), 6100-6106 (enums)
- **Dependencies:** None (foundation layer)
- **Extension model:** SystemId-based linking, calculated status from Service Status

## How it works

The E-Document table is an aggregate root that stores header-level information extracted from both outbound (sales, service) and inbound (purchase) documents. It does not store line details directly; those are in related tables (E-Doc. Imported Line for inbound, original source tables for outbound). The record links to source documents via RecordId and stores participant information (Bill-to/Pay-to) as snapshots at creation time.

Status is calculated from E-Document Service Status records in a 1:N relationship (one E-Document can have multiple Service Status records if processed through multiple services). The header Status field uses IEDocumentStatus interface implementations to determine overall state. Document classification uses seven enums (Type, Direction, Format, SourceType, ProcessingPhase, Status, ServiceStatus) to track processing state.

The E-Document card page provides drill-down navigation to source documents, service status details, logs, and imported line matching. It displays different FactBoxes and actions based on document direction (Outgoing vs Incoming).

## Structure

- `EDocument.Table.al` -- Aggregate root with 41 fields including clearance model fields
- `EDocument.Page.al` -- Document card with conditional UI based on direction
- `EDocuments.Page.al` -- List page with filters and bulk actions
- `EDocumentsSetup.Table.al` -- Global configuration
- `EDocumentType.Enum.al` -- Sales Invoice, Purchase Invoice, etc. (12 values)
- `EDocumentDirection.Enum.al` -- Incoming vs Outgoing
- `EDocumentFormat.Enum.al` -- PEPPOL BIS 3.0, etc. (extensible)
- `EDocumentSourceType.Enum.al` -- Manual, Automatic, OCR
- `EDocumentProcessingPhase.Enum.al` -- Create, Export, Send, Receive

## Documentation

- [Business logic](business-logic.md) -- Lifecycle, status calculation, cleanup cascades
- [Data model](data-model.md) -- Field descriptions, relationships, key indexes

## Things to know

- **Aggregate root pattern:** E-Document is the transaction boundary. All related data (Service Status, Logs, Attachments) is accessed through the E-Document record and deleted when it's deleted.
- **Calculated status:** E-Document.Status is not stored; it's computed from all related E-Document Service Status records via IEDocumentStatus interface implementations.
- **SystemId linking:** Uses Rec."Document Record ID" (RecordId type) to link to source documents, enabling cross-table references without surrogate keys.
- **Snapshot participant data:** Bill-to/Pay-to Name is copied from Customer/Vendor at creation time and stored on E-Document, preserving history even if master data changes.
- **Immutable records:** Once created, E-Documents should not be modified (only status transitions via Service Status records). This ensures audit trail integrity.
- **Deletion restrictions:** Cannot delete if Status = Processed or if Document Record ID is populated (linked to posted document). Only duplicate or orphaned records can be deleted.
- **Duplicate detection:** IsDuplicate checks for existing records with same Incoming E-Document No. + Bill-to/Pay-to No. + Document Date, preventing re-import of same invoice.
- **Clearance model fields:** Fields 60-61 support real-time tax clearance validation (Clearance Date, Last Clearance Request Time) for jurisdictions requiring authority approval.
- **Service field:** Stores the primary E-Document Service Code used to process the document; separate from Service Status records which track per-service results.
- **Import processing status:** FlowField calculated from E-Document Service Status table, showing progress through 4-step import state machine (Structure → Read → Prepare → Finish).
- **RecordRef isolation:** The table uses RecordRef for dynamic field access in mapping and transformation logic, avoiding compile-time dependencies.
