# Processing

The Processing module orchestrates what happens to E-Documents between creation and delivery on the outbound side and between receipt and BC document creation on the general inbound side. It owns the export pipeline, event subscribers that hook into BC posting and release, background job scheduling, order matching for purchase documents, outbound response messages, and AI-assisted draft line matching. The detailed import pipeline lives in `Import/` and has its own docs.

## How it works

*Updated: 2026-07-29 -- added purchase order export, message responses, and current AI matching boundaries.*

**Outbound flow.** `EDocumentSubscribers` listens to posted sales, service, finance charge, reminder, warehouse completion, and transfer shipment events. It also listens to purchase order release. When the relevant customer, vendor, or location resolves to a Document Sending Profile with `"Extended E-Document Service Flow"`, the subscriber calls `EDocExport.CreateEDocument()`. This creates or reuses an E-Document record, evaluates export eligibility per service via `IExportEligibilityEvaluator`, runs field mapping, invokes the format interface's `Create()` method through `EDocumentCreate.Codeunit.al` to produce a TempBlob, and logs the result. Finally, `EDocumentBackgroundJobs.StartEDocumentCreatedFlow()` enqueues a job that triggers the workflow -- which in turn decides whether to send, email, or route for approval.

**PEPPOL EDI flow.** Purchase orders now enter the same outbound pipeline when a purchase order is released. `EDocExport` understands `"Purchase Order"` as an E-Document type and reads live `Purchase Line` records for export. The core `"PEPPOL BIS 3.0"` format value still dispatches through `EDoc PEPPOL BIS 3.0`, but the PEPPOL XML builders it calls live in the standalone PEPPOL app. For inbound sales orders and order responses, Processing only owns the parent dispatch and message storage; the sales draft details live under `Import/`.

**Batch processing.** When a service has `"Use Batch Processing"` enabled, individual documents are not exported immediately. Instead they get status `Created` and wait. If the batch mode is `Recurrent`, a scheduled job (`"E-Doc. Recurrent Batch Send"`) collects all pending-batch documents grouped by document type, exports them as a batch, and sends them together.

**Order matching.** For incoming purchase orders, `EDocLineMatching.Codeunit.al` matches imported e-document lines to existing purchase order lines. Automatic matching filters on UOM, unit cost, and discount, then uses `CalculateStringNearness()` above 80% for description matching, plus Item Reference and Text-to-Account Mapping lookups. The old matching-page Copilot action is now hidden and obsolete; AI-assisted matching has moved to import draft processing through `EDocAIToolProcessor.Codeunit.al` and the tool codeunits in `AI/Tools/`.

**Message responses.** `E-Document Message` records store message payloads related to an existing E-Document, such as PEPPOL Order Responses. `EDocumentSubscribers.OnAfterReleaseSalesDoc()` creates an Accepted response for an inbound sales order when the document format reports a response message type. `EDocumentProcessing.SendOrderRejection()` builds the same kind of message with a Rejected response. Both paths use `IEDocResponseProvider` to ask the format which message applies, then `IEDocMessageBuilder` to build and persist the payload.

**AI tools.** `EDocAIToolProcessor.Codeunit.al` is a generic Copilot orchestrator that registers the E-Document Matching Assistance capability in SaaS, configures Azure OpenAI with the latest GPT-4.1 chat deployment, registers AI tools as function calls, and processes responses. The `Tools/` subfolder provides implementations for historical matching, G/L account matching, deferral matching, and similar-description lookups. Historical matching now tries direct history before asking the model.

## Things to know

*Updated: 2026-07-29 -- refreshed gotchas for PEPPOL EDI, error handling, attachments, and obsolete Copilot matching.*

- Export eligibility is pluggable: the `"Export Eligibility Evaluator"` enum on the service record controls which `IExportEligibilityEvaluator` runs. The default implementation allows all documents. Extend the enum to filter by document attributes, customer, vendor, or any other criteria.

- `EDocumentCreate.Codeunit.al` is a thin runner that delegates to the format interface's `Create()` or `CreateBatch()`. It exists solely to be wrapped in `Codeunit.Run()` for error isolation.

- `EDocumentSubscribers` subscribes to release events (`OnBeforeReleaseSalesDoc`, `OnBeforeReleasePurchaseDoc`, etc.) and posting-check events to run `CheckEDocument()` before the document is committed. Purchase order release also creates or re-exports an outbound E-Document when the profile is electronic.

- Manual creation from a posted document validates the resolved Document Sending Profile before export and errors if the source record cannot be mapped to an E-Document type. That avoids silently doing nothing when setup is missing or the record type is unsupported.

- Error messages are part of the document lifecycle. Processing actions clear existing errors before retrying, import step failures log the wrapped error text and mark the service status as `"Imported Document Processing Error"`, and E-Document cleanup clears linked Error Message records along with logs, service statuses, attachments, imported lines, messages, and draft data.

- Order matching only applies to incoming purchase orders (`"Document Type" = "Purchase Order"`, `Direction = Incoming`, `Status = "Order Linked"`). The matching page lets users match manually or run automatic matching. Accepted matches persist to the `"E-Doc. Order Match"` table and update `"Qty. to Invoice"` on purchase lines.

- The legacy Copilot PO matching code remains behind `#if not CLEAN29` as obsolete and hidden UI. Do not build new flows on it. New AI matching work should use `EDocAIToolProcessor` and import draft tools instead.

- `EDocumentBackgroundJobs` manages three job types: the one-shot "created flow" trigger, the recurring 5-minute `GetResponse` poller, and the recurrent batch send/import jobs with configurable frequency.

- Document attachments saved against an E-Document are marked with `"E-Document Attachment"` and `"E-Document Entry No."`. This lets the attachment factbox recover the E-Document context, supports Digital Voucher attachment scenarios, and lets cleanup remove only attachments that belong to that E-Document.

- `E-Document Message` is not a BC source document. It is a child payload for lifecycle messages such as an outgoing PEPPOL Order Response, with its XML stored in `E-Doc. Data Storage` and surfaced by the messages factbox.

- Do not confuse `EDocImport.Codeunit.al` in this folder with the full import pipeline -- it is the entry point that delegates to `Processing/Import/` for V2 import processing. New services default to the V2 import architecture; see the Import docs for stage-by-stage inbound behavior.
