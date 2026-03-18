# Workflow

Workflow integration that drives the outbound e-document processing pipeline. E-document sending is not a direct API call -- it flows through BC's workflow engine using "when event, then response" rules.

## Architecture

`EDocumentWorkFlowSetup.Codeunit.al` installs workflow templates on module setup and subscribes to the events that trigger e-document processing. The key templates are "Send to one service" and "Send to multiple services" -- these define the standard outbound paths.

`EDocumentWorkFlowProcessing.Codeunit.al` orchestrates the actual workflow execution. When a workflow fires, this codeunit coordinates the export-then-send sequence through the service interface.

`EDocumentCreatedFlow.Codeunit.al` handles the initial "E-Document Created" event that kicks off the pipeline.

## Clearance model support

For countries using tax authority clearance (Spain, Italy, India), workflows support multi-step chains: export to clearance service, wait for "Cleared" status, export to delivery service, send. This is configured by chaining workflow steps rather than requiring custom code.

## How workflows get selected

Document Sending Profiles on customer records determine which workflow fires for a given document. When a user posts a sales invoice, the customer's sending profile routes it to the correct e-document workflow. The `Sending/` subfolder in `src/Extensions/` handles this integration point.

## Extension points

`EDocWorkflowStepArgument.TableExt.al` and `EDocWorkflowResponseOptions.PageExt.al` extend BC's standard workflow step arguments to carry e-document-specific parameters (service selection, format options). The archived version (`EDocWorkflowStepArgumentArch.TableExt.al`) preserves these parameters for completed workflows.
