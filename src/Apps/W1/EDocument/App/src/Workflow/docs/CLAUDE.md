# Workflow

Integration with BC's Workflow engine to orchestrate E-Document export, send, and email actions. This module registers events, responses, and templates in the EDOC workflow category and handles the runtime execution of workflow steps.

## How it works

`EDocumentWorkFlowSetup.Codeunit.al` registers four events (Created, Status Changed, Imported, Exported) and five responses (Send, Import, Export, Email E-Document, Email PDF+E-Document) into the Workflow library via event subscribers. It also installs two workflow templates: single-service (EDOCTOS) and multi-service (EDOCTOM). The multi-service template chains response steps so that Service A's status change triggers Service B's send.

`EDocumentWorkFlowProcessing.Codeunit.al` is the runtime engine. When a response step executes, it resolves the E-Document from the RecordRef (which can be either an E-Document or E-Document Service Status record), validates the workflow step instance matches the document's workflow code, retrieves the service from the step argument, and dispatches to `DoSend` or `DoBatchSend`. After each send completes, `HandleNextEvent` fires the Status Changed event to advance to the next workflow step.

`EDocWorkflowStepArgument.TableExt.al` extends the standard Workflow Step Argument with an `E-Document Service` field, which is how each workflow response step knows which service to use. `EDocumentCreatedFlow.Codeunit.al` is a Job Queue handler that fires the EDocCreated event for a specific E-Document.

## Things to know

- Each workflow step argument must have a non-empty `E-Document Service` -- if it is blank, the step logs an error and exits without sending.
- `ValidateFlowStep` checks that the step's workflow code matches the E-Document's `Workflow Code`. A mismatch raises an error, which matters when multiple workflows are active simultaneously.
- The first workflow step that runs on an E-Document sets its `Workflow Step Instance ID`. Subsequent steps for the same document must match this ID or they are silently skipped.
- Batch send with Threshold mode accumulates documents in "Pending Batch" status until the count reaches `Batch Threshold`, then exports and sends them all at once. Recurrent mode defers to the background job.
- Deleting a service that is used in any enabled workflow is blocked by `IsServiceUsedInActiveWorkflow`, which scans all active workflow step arguments.
- Email responses do not require an E-Document Service in the step argument -- they use the document's sending profile directly.
