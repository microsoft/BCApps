# Processing

Processing is the core orchestration layer of the E-Document framework. It owns both
the outbound export pipeline (turning BC documents into electronic documents) and the
inbound import pipeline (turning received files into BC purchase documents or journal
lines). Every e-document flows through this folder at some point in its lifecycle.

## How it works

**Export** is driven by `EDocExport.Codeunit.al`. When a sales or purchase document
is posted, `EDocumentSubscribers.Codeunit.al` hooks the posting events and calls
`EDocExport.CreateEDocument`. The export codeunit resolves the Document Sending
Profile, discovers which E-Document Services apply via the workflow, maps fields using
`E-Doc. Mapping` records, and calls the format interface (`"E-Document"` interface) to
produce the output blob. Batch mode is supported -- the service can opt into
`"Use Batch Processing"` to defer the format call until multiple documents are
collected.

**Import** has two codepaths. V1 (`EDocImport.Codeunit.al`) calls `GetBasicInfo` and
`GetCompleteInfo` directly on the format interface, then creates a purchase document or
journal line in one shot. V2 (`ImportEDocumentProcess.Codeunit.al` in the Import/
subfolder) is a four-stage state machine -- Structure, Read, Prepare, Finish -- where
each stage is backed by a separate interface from the Interfaces/ subfolder. V2
introduces draft tables (`E-Document Purchase Header` / `E-Document Purchase Line`)
as an intermediate staging area that users can review and correct before the final BC
document is created. The `EDocImport` codeunit acts as the entry point for both paths
and delegates to `ImportEDocumentProcess` for V2.

The Interfaces/ subfolder defines the contract layer: 18 interfaces covering every
pluggable step of the import pipeline (structuring, reading, vendor/item resolution,
PO matching, draft finalization) plus export eligibility and AI system integration.

## Things to know

- V1 vs V2 is determined per service via `GetImportProcessVersion()`. V1 only uses
  the "Finish draft" step, which internally calls the old `V1_ProcessEDocument` path.
  V2 uses all four steps and the draft tables.

- `EDocumentSubscribers.Codeunit.al` subscribes to posting events for Sales, Purchase,
  Service, Finance Charge Memos, Reminders, and Transfer Shipments. It also hooks
  `OnBeforeOnDelete` on Purchase Header to undo the draft when a linked purchase
  document is deleted.

- Every processing step follows the commit-run-log pattern: `Commit()` first, then
  `Codeunit.Run()` inside a TryFunction boundary so errors are captured rather than
  propagated. Errors are logged via `EDocumentErrorHelper` and the service status is
  updated accordingly.

- `EDocRecordLink.Table.al` provides SystemId-based links between draft records and
  their corresponding BC records. These links are ephemeral -- they exist only while
  the draft is active and are cleaned up when the draft is finalized or reverted.

- The AI/ subfolder contains `EDocAIToolProcessor.Codeunit.al` and buffer tables for
  AI-assisted matching (historical line matching, GL account suggestion). These are
  invoked during the Prepare draft step when Copilot capabilities are enabled.

- `EDocAttachmentProcessor.Codeunit.al` extracts PDF attachments from structured
  documents (typically PEPPOL XML with embedded base64 PDFs) and stores them as
  Document Attachments. Attachments are moved from the E-Document to the final
  purchase document during the Finish draft step.

- Export uses `IExportEligibilityEvaluator` to let services decide per-document
  whether export should happen, beyond just document type support.
