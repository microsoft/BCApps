# Business logic

The Processing engine implements the core outbound export and inbound import workflows described in the app-level business logic documentation. This document covers engine-specific orchestration details.

## Export orchestration

EDocExport.CreateEDocument is the main entry point. It validates the Document Sending Profile, retrieves services from the workflow, creates the E-Document record, and creates E-Document Service Status records with "Created" status for each supporting service. For services without "Use Batch Processing" enabled, it immediately calls ExportEDocument.

ExportEDocument performs these steps:

1. **Validation** -- Calls IExportEligibilityEvaluator interfaces to check business rules (customer has tax ID, document type supported, no blocking errors).
2. **Format** -- Instantiates IEDocFileFormat from service configuration, calls CreateDocument with source document RecordRef, receives TempBlob with formatted content.
3. **Send** -- Instantiates IDocumentSender from service configuration, calls Send with TempBlob and HTTP client, receives success/failure status.
4. **Status update** -- On success, updates Service Status to "Sent". On failure, updates to "Error" and creates log entries. Updates overall E-Document status from aggregate Service Status.

For batch services, EDocumentBackgroundJobs.ProcessService queries all Service Status records with "Created" status for that service and processes them sequentially, respecting service-level rate limits.

## Import orchestration

EDocImport.ProcessIncomingEDocument drives the state machine. It accepts an E-Document and EDocImportParameters specifying either a single step to run or a desired final status. The codeunit calculates the path from current status to target status, executes each step via ImportEDocumentProcess, and stops at the first error.

ImportEDocumentProcess.OnRun executes a single step:

1. **Structure** -- Calls IStructureReceivedEDocument.StructureReceivedEDocument with unstructured blob, receives IStructuredDataType with parsed content. Sets "Structure Done" flag.
2. **Read** -- Determines read implementation (MLLM or ADI) from service configuration. Calls IEDocAISystem or IStructuredFormatReader to extract header/line data. Populates E-Document Purchase Header and Purchase Line temporary tables. Sets "Read Done" flag.
3. **Prepare** -- Calls PreparePurchaseEDocDraft to resolve vendor, items, UOMs via provider interfaces. Optionally runs Copilot matching to suggest purchase order line matches. Sets "Prepare Done" flag.
4. **Finish** -- Calls EDocumentCreate to transform temporary purchase records into real Purchase Header and Purchase Line records. Calls IEDocumentFinishDraft interfaces for customization. Sets "Finish Done" flag and overall status to "Processed".

Each step logs activity to E-Document Log and E-Document Integration Log tables. Errors during any step halt processing and set status to "Error" with detailed log entries.

## Undo mechanism

Undo operations reset completion flags and delete dependent data:

- **Undo Structure** -- Clears Structure Done, Read Done, Prepare Done, Finish Done. Deletes structured data blob, imported lines, matches, and final purchase drafts.
- **Undo Read** -- Clears Read Done, Prepare Done, Finish Done. Deletes imported lines, matches, and final purchase drafts. Preserves structured data.
- **Undo Prepare** -- Clears Prepare Done, Finish Done. Deletes matches and final purchase drafts. Preserves structured data and imported lines.
- **Undo Finish** -- Clears Finish Done. Deletes final purchase drafts. Preserves all intermediate data.

This allows users to correct extraction errors (re-run Read with different AI settings), re-match with updated parameters (re-run Prepare with different order filters), or regenerate drafts (re-run Finish with field mapping changes).

## Automatic processing

Services with "E-Doc. Automatic Processing" configured can run inbound processing automatically when documents arrive. The setting specifies which step to reach automatically:

- **Structure only** -- Stop after structuring, require manual Read/Prepare/Finish.
- **Read only** -- Stop after extraction, require manual Prepare/Finish for review.
- **Prepare only** -- Stop after matching, require manual Finish to create drafts.
- **Full automatic** -- Complete all steps, create purchase drafts without user interaction.

EDocImport.ReceiveAndProcessAutomatically polls for new documents via IDocumentReceiver, then processes each according to service automatic processing settings.

## Attachment processing

EDocAttachmentProcessor handles file attachments for both outbound and inbound documents. On export, it can attach the formatted e-invoice file to the source sales document as a Document Attachment record. On import, it attaches the original unstructured blob (PDF, email attachment) to the E-Document record for reference.

Attachments are linked via Record Link records, enabling the standard Document Attachment factbox to show e-document files alongside user-uploaded attachments.

## Email integration

EDocumentEmailing provides email-based document exchange. On export, it can send formatted e-invoices as email attachments using SMTP configuration. On import, it can poll IMAP/POP3 mailboxes for incoming e-invoice emails and extract attachments for processing.

Email-based import requires mailbox configuration on the E-Document Service record, specifying connection settings, folder paths, and file extension filters.
