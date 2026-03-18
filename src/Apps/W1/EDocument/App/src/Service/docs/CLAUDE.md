# Service

Service registration and configuration for E-Document outbound/inbound flows. Defines connection settings, supported document types, batch processing modes, import scheduling, and file format mappings. This is where you configure which documents get sent where, how batching works, and how incoming documents are processed.

## Quick reference

- **Parent:** [`src/`](../../CLAUDE.md)
- **Files:** 8 .al files + Participant/ subdirectory (3 files)
- **Key objects:** E-Document Service (table + page), E-Doc. Service Supported Type, Service Status
- **Entry points:** `E-Document Services` page (6102), `E-Document Service` card (6133)

## How it works

An E-Document Service record defines connection parameters for a specific integration endpoint. It stores the service code, document format (PEPPOL, Data Exchange, etc.), integration type (enum pointing to sender/receiver interfaces), and processing flags for both outbound and inbound flows.

For outbound, the service specifies whether to use batch processing (threshold or recurrent scheduling), PDF embedding, and export eligibility rules. When batch processing is enabled via "Use Batch Processing", the system schedules background jobs based on either a document count threshold or a time-based recurrence pattern.

For inbound, the service configures auto-import scheduling (via "Auto Import", start time, and interval), automatic processing triggers, and a 13-step import parameter set (validate receiving company, resolve UOM, lookup item references, verify totals, create journal lines, etc.). Import Process enum selects between V1.0 (legacy) and V2.0 (draft-based) workflows.

The E-Doc. Service Supported Type junction table maps service codes to document types (Sales Invoice, Credit Memo, etc.), filtering which posted documents trigger export via this service. Service Status records track per-service, per-document processing state independently—one E-Document can have multiple statuses if sent through multiple services simultaneously.

Service Participant sub-entities store GLN/VAT identifiers for trading partners, enabling lookup during document reception.

## Key files

- **EDocumentService.Table.al** -- Service configuration table with 60+ fields spanning export/import/batch/journal settings
- **EdocumentService.Page.al** -- Card page with conditional group visibility (import parameters vs. V2.0 draft settings)
- **EDocServiceSupportedType.Table.al** -- Junction table linking service codes to supported E-Document Types
- **EDocumentServiceStatus.Table.al** -- Composite status tracking per service per document (1:N relationship)
- **EDocumentServices.Page.al** -- List page with "New Service" action and filter by integration type
- **EDocumentServiceStatus.Page.al** -- Status list with drill-down to logs and integration logs
- **Participant/** -- GLN/VAT participant registry for matching incoming documents to vendors

## Things to know

- **Service Integration V2 replaces legacy enum** -- Field 27 uses new "Service Integration" enum with IConsentManager privacy consent; field 4 obsoleted in v26.0.
- **Batch Recurrent Job Id + Import Recurrent Job Id** -- GUIDs linking to scheduled job queue entries; cleaned up OnDelete via EDocBackgroundJobs.RemoveJob().
- **GetDefaultImportParameters() returns step/status pair** -- V1.0 returns "Finish draft" step with CreateDocumentV1Behavior flag; V2.0 returns "Desired Status" = Unprocessed unless auto-processing enabled.
- **OnDelete cascade prevents orphaned workflows** -- Checks if service is used in active workflow via IsServiceUsedInActiveWorkflow() before allowing deletion.
- **GetDefaultFileExtension() defaults to '.xml'** -- Extensible via OnAfterGetDefaultFileExtension event for custom formats.
- **Verify Purch. Total Amounts (field 60)** -- V2.0-only setting controlling whether posted purchase draft validates document totals.
- **Processing Customizations enum** -- Allows service-level customization of import behavior (enum injected into import parameters).
- **Service Status is lightweight composite** -- Only 4 fields: Entry No, Service Code, Status enum, Import Processing Status. Logs/IntegrationLogs counted on demand.
- **Participant subentity stores GLN-to-vendor mappings** -- Used during inbound document reception to resolve "To:" participant to vendor record.
