# Workflow

Workflow orchestration for outbound E-Documents -- wires the E-Document lifecycle into BC's general-purpose Workflow engine. This module defines the events, responses, and templates that allow configurable processing chains instead of hardcoded send logic. The boundary is clear: this module handles *when* and *in what order* things happen; the actual export/send logic lives in the Processing and Integration modules.

## How it works

E-Documents use Document Sending Profile to select a Workflow Code, which defines the processing chain. When a document is posted, `EDocumentCreatedFlow` runs as a Job Queue Entry, firing the `EDOCCREATEDEVENT` workflow event. The workflow engine then walks the step chain, executing responses in order.

`EDocumentWorkFlowSetup` registers four events (`EDocCreated`, `EDocStatusChanged`, `EDocImported`, `EDocExported`) and five responses (`Send`, `Export`, `Import`, `EmailEDoc`, `EmailPDFAndEDoc`) into the BC workflow library via event subscribers. It also installs two built-in templates: "Send to one service" (EDOCTOS) and "Send to multiple services" (EDOCTOM). The multi-service template chains two Send responses off the same entry point event, each targeting a different service.

`EDocumentWorkFlowProcessing` is the response executor. When the workflow engine dispatches a response, the `ExecuteEdocWorkflowResponses` subscriber routes to the appropriate method: `SendEDocument`, `ExportEDocument`, or `SendEDocFromEmail`. Each method resolves the E-Document Service from the `Workflow Step Argument` (extended with an `"E-Document Service"` field via table extension) and delegates to the export/integration layer. After execution, `HandleNextEvent` fires `EDocStatusChanged` to advance the workflow to the next step, enabling multi-step chains like Export -> Send -> Email.

For async services, after a send returns `IsAsync = true`, a background job is scheduled to poll `GetResponse` until the service confirms delivery.

## Things to know

- The `Workflow Step Argument` table extension (field `"E-Document Service"`) is the critical link between a workflow response step and the E-Document Service it targets. Each response step in the chain can target a different service.
- `ValidateFlowStep` ensures the workflow step instance matches the E-Document's stored `"Workflow Code"` -- this prevents cross-workflow execution when multiple workflows are enabled.
- The `DoSend` path has an optimization: if the document was already exported (status = `Exported` from a prior Export step), it skips re-export and goes straight to the integration send.
- Batch processing has three modes: `Recurrent` (exits immediately, a separate scheduled job handles it), `Threshold` (waits until N documents of the same type accumulate), and custom (raises `OnBatchSendWithCustomBatchMode` for extensions).
- Email responses (`SendEDocFromEmail`) look up the previous Send or Export response in the workflow to find which service produced the document -- they don't require their own service argument.
- The `EDocWorkflowStepArgumentArch` table extension mirrors the argument field to the archive table, preserving which service was used after workflow archival.

See the [app-level CLAUDE.md](../../docs/CLAUDE.md) for broader architecture context.
