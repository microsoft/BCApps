# Workflow

Integration with BC's standard Workflow engine to orchestrate multi-step
e-document processing (export, send, email) through configurable flows.

## How it connects

The Document Sending Profile's `Electronic Document` field can be set to
`"Extended E-Document Service Flow"`, which activates workflow-driven
processing instead of direct single-service send. The sending profile's
`Electronic Service Flow` field then references a specific Workflow record
in the EDOC category.

When a document is posted and triggers e-document creation, the
`E-Document Created Flow` codeunit fires the `EDocCreated` workflow event
via a job queue entry. The workflow engine then executes the configured
response steps.

## Events and responses

Four workflow events are registered:

- E-Document Created, E-Document Service Status Changed, E-Document
  Imported, E-Document Exported

Five workflow responses:

- Send E-Document (export + send to a service)
- Export E-Document (export only, no send)
- Import E-Document
- Email E-Document, Email PDF & E-Document

Each response step's `Workflow Step Argument` carries an `E-Document
Service` code (added via table extension) that identifies which service
to use for that step. This enables multi-service flows where step 1
exports to service A, and step 2 sends to service B.

## Workflow step instance linking

When a workflow starts processing an e-document, the E-Document record's
`Workflow Step Instance ID` is set to the current instance ID. Subsequent
steps use `HandleNextEvent` to advance the workflow on the same instance.
The `ValidateFlowStep` procedure ensures the step's workflow code matches
the e-document's `Workflow Code` to prevent cross-workflow interference.

## Templates

Two built-in workflow templates are seeded on install:

- EDOCTOS -- send to a single service (one event + one response)
- EDOCTOM -- send to multiple services (one event + chained responses)

## Batch send through workflow

When a service has batch processing enabled, the workflow send response
routes through `DoBatchSend` which accumulates e-documents in
"Pending Batch" status until the threshold or recurrent schedule triggers
the actual batch export and send.
