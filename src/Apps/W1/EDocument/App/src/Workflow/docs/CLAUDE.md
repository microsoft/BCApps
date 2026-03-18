# Workflow

Workflow integration for E-Document lifecycle automation. Registers workflow events (Created, Status Changed, Exported, Imported), response actions (Send, Export, Email), and provides templates for single-service and multi-service routing. Workflow arguments bind service codes to response steps, enabling orchestrated export → send → email chains.

## Quick reference

- **Parent:** [`src/`](../../CLAUDE.md)
- **Files:** 6 .al files
- **Key objects:** E-Document WorkFlow Processing (codeunit 6135), E-Document Workflow Setup (codeunit 6139)
- **Entry points:** Workflow event handlers (subscribers), template installation

## How it works

E-Document workflow integration extends Business Central's workflow engine with 4 custom events (E-Document Created, Service Status Changed, Exported, Imported) and 5 response actions (Send, Export, Email E-Doc, Email PDF+E-Doc, Import). When a sales document is posted and creates an E-Document, the system raises the "E-Document Created" event, triggering any enabled workflows listening on that event.

Each workflow response step stores a Workflow Step Argument record with an "E-Document Service" field (injected via table extension). This field binds the response to a specific service—when "Send E-Document" executes, it reads the argument to know which service to use for transmission.

The framework supports two routing patterns: single-service (template EDOCTOS) routes documents to one integration endpoint, while multi-service (template EDOCTOM) chains multiple Send responses sequentially, enabling scenarios like "send to government clearance, then email to customer, then archive to SharePoint."

Status transitions trigger subsequent workflow steps. After export completes, the system raises "E-Document Exported" event with the E-Document as variant; after send completes, it raises "E-Document Service Status Changed" with the Service Status record as variant. Workflows can chain responses: Created → Export → Status Changed → Send → Status Changed → Email.

Workflow Step Instance ID tracking prevents duplicate execution—EDocument."Workflow Step Instance ID" stores the active instance GUID, and ValidateFlowStep() verifies each response invocation matches the expected instance before executing.

## Key files

- **EDocumentWorkFlowProcessing.Codeunit.al** -- Core execution engine: SendEDocument(), ExportEDocument(), SendEDocFromEmail(), HandleNextEvent()
- **EDocumentWorkFlowSetup.Codeunit.al** -- Event/response registration, template installation, workflow library integration
- **EDocumentCreatedFlow.Codeunit.al** -- Subscriber raising "E-Document Created" event after document insert
- **EDocWorkflowResponseOptions.PageExt.al** -- Extends Workflow Response Options page to show E-Document Service lookup
- **EDocWorkflowStepArgument.TableExt.al** -- Adds "E-Document Service" field to Workflow Step Argument
- **EDocWorkflowStepArgumentArch.TableExt.al** -- Adds same field to archived workflow arguments

## Things to know

- **Workflow Step Instance ID prevents re-execution** -- ValidateFlowStep() checks EDocument."Workflow Step Instance ID" matches current instance; if mismatch, silently exits (step already executed by another workflow)
- **HandleNextEvent() commits before firing** -- Explicitly calls Commit() before WorkflowManagement.HandleEventOnKnownWorkflowInstance() to persist status changes before next step
- **GetEDocumentServiceFromPreviousSendOrExportResponse() enables chaining** -- Walks workflow instance tree backward to find previous Send/Export response, extracts service code from argument (used for Email responses that inherit service)
- **Batch send integrates with workflow** -- DoBatchSend() calls HandleNextEvent() with filter set on all batched documents, triggering next workflow step for entire batch simultaneously
- **Email responses require Document Sending Profile** -- SendEDocFromEmail() reconstructs Document Sending Profile from E-Document, sets E-Mail attachment type (E-Document only or PDF+E-Document), calls ProcessEDocumentAsEmail()
- **Template installation via OnInsertWorkflowTemplates subscriber** -- InsertSendToSingleServiceTemplate() and InsertSendToMultiServiceTemplate() create default workflow skeletons on setup
- **Workflow argument validation logs errors** -- If "E-Document Service" blank in argument, logs error via EDocErrorHelper.LogErrorMessage() and returns false from ValidateFlowStep()
- **DoesFlowHasEDocService() checks if workflow references services** -- Iterates all response steps, collects service codes into filter, enables service deletion validation
- **OnAfterGetDescription subscriber formats response labels** -- Injects service name into Workflow Response description: "Send E-Document using service: %1"

## Integration points

- **Event subscribers:**
  - `OnAddWorkflowEventsToLibrary` -- Registers 4 E-Document events with Workflow Event Handling
  - `OnAddWorkflowResponsesToLibrary` -- Registers 5 E-Document responses with Workflow Response Handling
  - `OnAfterGetDescription` -- Formats response descriptions with service code
  - `OnAddWorkflowResponsePredecessorsToLibrary` -- Defines allowed event→response pairs
  - `OnExecuteWorkflowResponse` -- Routes execution to SendEDocument/ExportEDocument/SendEDocFromEmail
  - `OnInsertWorkflowTemplates` -- Installs default templates
  - `OnAddWorkflowCategoriesToLibrary` -- Adds "EDOC" category

- **Extensibility events:**
  - `OnBatchSendWithCustomBatchMode(EDocument, Service, IsHandled)` -- Allows external code to implement custom batch modes beyond Threshold/Recurrent
  - `OnBeforeOpenServiceIntegrationSetupPage(Service, IsRun)` -- Allows external setup page invocation (called from Service page action)

## Error handling

- **WrongWorkflowStepInstanceFoundErr** -- Raised if WorkflowStepInstance."Workflow Code" ≠ EDocument."Workflow Code"; prevents cross-workflow contamination
- **NotSupportedBatchModeErr** -- Raised if Batch Mode enum not Threshold/Recurrent and OnBatchSendWithCustomBatchMode not handled
- **CannotSendEDocWithoutTypeErr** -- Raised if E-Document.Type = None when attempting email send (cannot determine Report Selection Usage)
- **CannotFindEDocErr** -- Raised if posted document header (Sales Invoice, Service Cr. Memo, etc.) not found by Document Record ID
- **NotSupportedEDocTypeErr** -- Raised if attempting email send for unsupported document type (not in Sales Invoice/Cr. Memo/Service Invoice/etc. set)

## Performance notes

- **ValidateFlowStep() short-circuits on instance mismatch** -- Returns false immediately if Workflow Step Instance ID doesn't match, avoiding database reads
- **HandleNextEvent() uses HasFilter() check** -- Verifies E-Document record filtered before executing workflow to prevent accidental mass execution
- **GetEDocumentServiceFromPreviousSendOrExportResponse() walks instance tree** -- O(N) in workflow step count; cached by WorkflowManagement.FindResponse() helper
- **Batch send commits once for all documents** -- HandleNextEvent() called with multi-record filter, fires workflow event for batch simultaneously rather than looping
