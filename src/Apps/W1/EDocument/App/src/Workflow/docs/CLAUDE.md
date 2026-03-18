# Workflow

Integration with BC's Workflow engine for multi-step e-document processing. This is how outbound e-documents get exported, sent, and emailed in configurable sequences -- workflow is not optional for outbound e-documents.

## How it works

`EDocumentWorkflowSetup` (codeunit 6139, Public access) defines the event and response codes that plug into BC's Workflow framework. Events include `EDOCCREATEDEVENT` (document created), `EDOCRECEIVED` (document imported), `EDOCSENT` (status changed), and `Event-EDOC-EXPORTED`. Responses include export, send, send-by-email, and get-response actions. The codeunit also provides two built-in workflow templates: single-service (export + send) and multi-service (export to multiple services in sequence).

`EDocumentWorkFlowProcessing` (codeunit 6135) is the execution engine. When a workflow response fires, this codeunit handles the actual work: `SendEDoc` runs the export-then-send pipeline, `SendEDocFromEmail` generates the document and emails it (with PDF, e-document XML, or both as attachments), and `GetEDocResponse` checks async send status. Each response step reads its configuration from `Workflow Step Argument`, which is extended with an `E-Document Service` field (Code[20]) that specifies which service to use for that step.

`EDocumentCreatedFlow` (codeunit 6143) is a Job Queue handler. When an E-Document is created, a job queue entry fires this codeunit, which tells the Workflow Management to handle the `EDOCCREATEDEVENT`. This decouples document creation from workflow execution.

## Things to know

- The Document Sending Profile must reference an enabled Workflow with `Electronic Document = Extended E-Document Service Flow`. Without this, outbound e-documents will not be processed.
- Each workflow step can target a different E-Document Service via the `Workflow Step Argument` extension. This enables multi-service scenarios like "export to PEPPOL, send to Pagero, then email a copy."
- `IsServiceUsedInActiveWorkflow` iterates all enabled workflows to check if a service is referenced in any step argument. This is used to prevent deletion of in-use services.
- Workflow templates are inserted with `Template = true` so users can create workflows from them but cannot modify the templates directly.
- The `EDocWorkflowStepArgumentArch.TableExt.al` extends the archived step argument too, so completed workflow instances retain their E-Document Service reference for historical tracking.
- Email sending determines the report usage, customer number, and document type by switching on `EDocument."Document Type"` -- the large case statement in `SendEDocFromEmail` covers all supported outbound document types.
