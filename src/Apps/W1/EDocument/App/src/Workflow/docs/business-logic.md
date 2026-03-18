# Workflow — Business Logic

Workflow integration automates E-Document routing through event-driven response chains. This document describes workflow lifecycle, response execution, batch processing, and multi-service routing patterns.

## Core workflows

### Workflow template installation

1. **OnInsertWorkflowTemplates subscriber fires** -- Triggered when admin opens Workflow Templates page or runs "Insert Workflow Templates" action
2. **InsertSendToSingleServiceTemplate()** -- Creates "EDOCTOS" template with entry point "E-Document Created" → response "Send E-Document using service: %1"
3. **InsertSendToMultiServiceTemplate()** -- Creates "EDOCTOM" template with entry point + two chained "Send E-Document" responses (service A → service B)
4. **Template marked as Template = true** -- Prevents direct execution; admin must create workflow from template, configure service arguments
5. **Admin creates workflow from template** -- Workflow Setup page duplicates template, admin assigns E-Document Service codes to each response argument

### Single-service workflow execution

1. **E-Document created** -- Document posting inserts E-Document record, EDocumentCreatedFlow.OnAfterInsertEvent() raises "EDOCCREATEDEVENT"
2. **Workflow triggered** -- WorkflowManagement.HandleEvent() finds enabled workflows listening on "EDOCCREATEDEVENT", evaluates conditions (document type, sending profile, etc.)
3. **Response step executed** -- OnExecuteWorkflowResponse subscriber calls SendEDocument(RecordRef, WorkflowStepInstance)
4. **ValidateFlowStep()** -- Verifies WorkflowStepInstance."Workflow Code" matches EDocument."Workflow Code", stores WorkflowStepInstance.ID in EDocument."Workflow Step Instance ID"
5. **Service extraction** -- WorkflowStepArgument.Get(WorkflowStepInstance.Argument), reads "E-Document Service" field
6. **Export + send** -- DoSend() calls EDocExport.ExportEDocument() → EDocIntMgt.Send() → updates Service Status → commits
7. **Next event** -- HandleNextEvent() calls WorkflowManagement.HandleEventOnKnownWorkflowInstance(EventEDocStatusChanged(), ServiceStatus, InstanceID)
8. **Workflow complete** -- If no response listens on "E-Document Service Status Changed", workflow ends; else continues to next step (e.g., email)

### Multi-service workflow chaining

1. **Entry point triggers first service** -- Same as single-service: Created event → Send response → Status Changed event
2. **Second response step** -- Status Changed event has condition "Service Code = SERVICE_A", triggers second "Send E-Document" response with argument "E-Document Service = SERVICE_B"
3. **ValidateFlowStep() checks instance ID** -- If EDocument."Workflow Step Instance ID" already set to previous step's ID, compares to current instance; if mismatch, exits (prevents double execution)
4. **Instance ID updated** -- If match, ValidateFlowStep() overwrites EDocument."Workflow Step Instance ID" with new instance ID, allows execution
5. **Service B export + send** -- Same DoSend() flow, creates second E-Document Service Status record for SERVICE_B
6. **HandleNextEvent() fires Status Changed again** -- Now with SERVICE_B status, triggers any responses listening on "Service Code = SERVICE_B"
7. **Chain continues** -- Workflow can have N services in sequence; each Status Changed event triggers next step

### Batch processing workflow integration

1. **Threshold batch accumulation** -- Documents set to "Pending Batch" status, no workflow event fired yet
2. **Threshold met** -- When count >= Batch Threshold, DoBatchSend() exports all documents in batch, updates statuses to "Exported"
3. **Batch event firing** -- HandleNextEvent(EDocument filter with all batch entries, EDocumentService) calls WorkflowManagement.HandleEventOnKnownWorkflowInstance() for each document
4. **Send batch** -- EDocIntMgt.SendBatch() transmits single payload with all documents, updates all statuses to "Sent" simultaneously
5. **Next workflow steps** -- Each document's Status Changed event evaluated independently (some may chain to email, others may stop)

### Email response execution

1. **Email response triggered** -- Status Changed event triggers "Email E-Document to Customer" or "Email PDF and E-Document" response
2. **GetEDocumentServiceFromPreviousSendOrExportResponse()** -- Walks workflow instance tree backward, finds previous Send/Export response, extracts service code (email inherits service from previous step)
3. **Reconstruct sending profile** -- DocumentSendingProfile.Get(EDocument."Document Sending Profile"), overwrite E-Mail = "Yes (Use Default Settings)", E-Mail Attachment = E-Document or PDF+E-Document
4. **Resolve document header** -- Case on EDocument."Document Type", Get(EDocument."Document Record ID") to retrieve Sales Invoice Header, Service Cr. Memo Header, etc.
5. **Determine report usage** -- Map document type to Report Selection Usage (S.Invoice, S.Cr.Memo, SM.Invoice, etc.)
6. **Email transmission** -- EDocumentProcessing.ProcessEDocumentAsEmail(profile, usage, variant, docNo, docTypeText, customerNo, false) generates email with attachments

### Workflow argument validation

1. **ValidateFlowStep() called first** -- Before any response execution (SendEDocument, ExportEDocument, SendEDocFromEmail)
2. **Workflow code check** -- Error if WorkflowStepInstance."Workflow Code" ≠ EDocument."Workflow Code" (prevents cross-workflow execution)
3. **Instance ID initialization** -- If EDocument."Workflow Step Instance ID" is null GUID, store WorkflowStepInstance.ID
4. **Instance ID match** -- If non-null, compare to WorkflowStepInstance.ID; if mismatch, return false (step already executed by another workflow)
5. **Argument validation** -- If ValidateArgument = true, WorkflowStepArgument.Get(WorkflowStepInstance.Argument), check "E-Document Service" not blank
6. **Error logging** -- If service blank, EDocErrorHelper.LogErrorMessage(EDocument, WorkflowStepArgument, FieldNo("E-Document Service"), 'E-Document Service must be specified'), return false

## Key procedures

### E-Document Workflow Processing

- **SendEDocument(RecordRef, WorkflowStepInstance)** -- Entry point for "Send E-Document using service" response; validates flow, extracts service, calls SendEDocument(EDocument, Service)
- **SendEDocument(EDocument, Service)** -- Checks IsEdocServiceUsingBatch(), routes to DoBatchSend() or DoSend(), logs telemetry, calls FeatureTelemetry.LogUsage()
- **DoSend(EDocument, Service)** -- Single-document send: ExportEDocument() → Send() → commit → HandleNextEvent() → schedule async response job
- **DoBatchSend(EDocument filter, Service)** -- Batch send: accumulate until threshold/recurrence, ExportEDocumentBatch() → SendBatch() → HandleNextEvent(filter)
- **ExportEDocument(RecordRef, WorkflowStepInstance)** -- Response action for "Export E-Document"; calls EDocExport.ExportEDocument(), raises "E-Document Exported" event
- **SendEDocFromEmail(RecordRef, WorkflowStepInstance, AttachmentType)** -- Email response; validates flow (no argument check), reconstructs sending profile, calls ProcessEDocumentAsEmail()
- **HandleNextEvent(EDocument filter, Service)** -- Commits, then fires EventEDocStatusChanged() for each document in filter via WorkflowManagement.HandleEventOnKnownWorkflowInstance()
- **GetEDocumentServiceFromPreviousSendOrExportResponse(instance, out service)** -- Walks workflow instance tree backward using WorkflowManagement.FindResponse(), returns service from previous Send/Export step
- **GetEDocumentFromRecordRef(RecordRef, out EDocument)** -- Converts RecordRef variant (E-Document or E-Document Service Status) to E-Document record
- **IsServiceUsedInActiveWorkflow(Service)** -- Iterates enabled workflows + steps + arguments, checks if any argument references service code (blocks service deletion)
- **GetServicesFromEntryPointResponseInWorkflow(Workflow, out Service)** -- Returns filter of all service codes referenced in entry point responses (validation helper)
- **DoesFlowHasEDocService(out Services, WorkflowCode)** -- Checks if workflow contains any E-Document service references (returns true if filter non-empty)

### E-Document Workflow Setup

- **EDocCreated() / EventEDocStatusChanged() / EventEDocExported() / EventEDocImported()** -- Return event code constants ('EDOCCREATEDEVENT', 'EDOCSENT', etc.)
- **EDocSendEDocResponseCode() / ResponseEDocExport() / ResponseSendEDocByEmail() / ResponseSendEDocAndPDFByEmail()** -- Return response code constants
- **InsertSendToSingleServiceTemplate()** -- Creates EDOCTOS workflow template: Created event → Send response
- **InsertSendToMultiServiceTemplate()** -- Creates EDOCTOM workflow template: Created event → Send response A → Send response B (chained)

## Integration patterns

### Custom batch mode extension

```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"E-Document WorkFlow Processing", OnBatchSendWithCustomBatchMode, '', false, false)]
local procedure HandleCustomBatchMode(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; var IsHandled: Boolean)
begin
    if EDocumentService."Batch Mode" = MyCustomBatchMode then begin
        // Implement custom batching logic
        // Export + send batch
        // Update statuses
        IsHandled := true;
    end;
end;
```

### Service-specific workflow routing

Use workflow response conditions to route by service:
1. Create workflow with entry point "E-Document Created"
2. Add condition: "E-Document Service Status.E-Document Service Code = 'PEPPOL'"
3. Add response: "Send E-Document using service: PEPPOL"
4. Add second branch with condition: "E-Document Service Status.E-Document Service Code = 'ARCHIVE'"
5. Add response: "Send E-Document using service: ARCHIVE"
6. Both services execute in parallel (separate workflow instances)

### Email after send pattern

1. Entry point: "E-Document Created" → Response: "Send E-Document using service: PEPPOL"
2. Add event: "E-Document Service Status Changed" with condition "Status = Sent"
3. Add response: "Email E-Document to Customer" (inherits service from previous step)
4. Workflow executes: Create → Send → Status Changed → Email

## Error handling

- **WrongWorkflowStepInstanceFoundErr** -- Workflow code mismatch; indicates workflow response conditions overlapping (multiple workflows executing simultaneously)
- **Service code blank in argument** -- Logged as error message, ValidateFlowStep() returns false, response skipped (workflow continues to next step)
- **NotSupportedBatchModeErr** -- Custom batch mode not handled via OnBatchSendWithCustomBatchMode; indicates missing extension implementation
- **CannotSendEDocWithoutTypeErr** -- E-Document Type = None; cannot determine Report Selection Usage for email (document type not set during import?)
- **CannotFindEDocErr** -- Document Record ID invalid; posted document header deleted? (shouldn't happen, E-Document should block header deletion)
- **NotSupportedEDocTypeErr** -- Email response doesn't support this document type (only Sales/Service Invoice/Cr. Memo, Issued Reminder/Fin. Charge, Sales/Transfer Shipment supported)

## Performance notes

- **ValidateFlowStep() short-circuits on instance mismatch** -- Avoids expensive service code validation if workflow instance already executed
- **HandleNextEvent() commits before firing** -- Ensures status changes persisted before triggering dependent workflows (prevents rollback on workflow error)
- **Batch send fires single event per document** -- HandleNextEvent(filter) loops documents, but each HandleEventOnKnownWorkflowInstance() call independent (no transaction spanning multiple documents)
- **GetEDocumentServiceFromPreviousSendOrExportResponse() caches instance tree** -- WorkflowManagement.FindResponse() uses recursive CTE-style lookup, but step count typically small (< 10 steps per workflow)
