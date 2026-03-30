# Processing

The Processing module orchestrates what happens to E-Documents between creation and delivery (outbound) or between receipt and BC document creation (inbound). It owns the export pipeline, event subscribers that hook into BC posting, background job scheduling, order matching for purchase documents, and AI-assisted line matching via Copilot. The import pipeline lives in `Import/` and has its own docs.

## How it works

**Outbound flow.** `EDocumentSubscribers` listens to `OnAfterPostSalesDoc`, `OnAfterPostPurchaseDoc`, `OnAfterPostServiceDoc`, and similar events. When a document posts and its Document Sending Profile is set to `"Extended E-Document Service Flow"`, the subscriber calls `EDocExport.CreateEDocument()`. This creates an E-Document record, evaluates export eligibility per service via `IExportEligibilityEvaluator`, runs field mapping, invokes the format interface's `Create()` method (via `EDocumentCreate.Codeunit.al`) to produce a TempBlob, and logs the result. Finally, `EDocumentBackgroundJobs.StartEDocumentCreatedFlow()` enqueues a job that triggers the workflow -- which in turn decides whether to send, email, or route for approval.

**Batch processing.** When a service has `"Use Batch Processing"` enabled, individual documents are not exported immediately. Instead they get status `Created` and wait. If the batch mode is `Recurrent`, a scheduled job (`"E-Doc. Recurrent Batch Send"`) collects all pending-batch documents grouped by document type, exports them as a batch, and sends them together.

**Order matching.** For incoming purchase orders, `EDocLineMatching.Codeunit.al` matches imported e-document lines to existing purchase order lines. Automatic matching filters on UOM, unit cost, and discount, then uses `CalculateStringNearness()` above 80% for description matching, plus Item Reference and Text-to-Account Mapping lookups. The Copilot subfolder adds AI-assisted matching via Azure OpenAI when automatic matching leaves unmatched lines.

**AI tools.** `EDocAIToolProcessor.Codeunit.al` is a generic Copilot orchestrator that configures Azure OpenAI (GPT-4.1), registers AI tools as function calls, and processes responses. The `Tools/` subfolder provides implementations for historical matching, G/L account matching, deferral matching, and similar-description lookups.

## Things to know

- Export eligibility is pluggable: the `"Export Eligibility Evaluator"` enum on the service record controls which `IExportEligibilityEvaluator` runs. The default implementation allows all documents. Extend the enum to filter by document attributes, customer, or any other criteria.

- `EDocumentCreate.Codeunit.al` is a thin runner that delegates to the format interface's `Create()` or `CreateBatch()`. It exists solely to be wrapped in `Codeunit.Run()` for error isolation.

- `EDocumentSubscribers` also subscribes to release events (`OnBeforeReleaseSalesDoc`, etc.) and posting-check events to run `CheckEDocument()` before the document is committed, ensuring format-specific validation happens early.

- Order matching only applies to incoming purchase orders (`"Document Type" = "Purchase Order"`, `Direction = Incoming`, `Status = "Order Linked"`). The matching page lets users match manually, run automatic matching, or invoke Copilot. Accepted matches persist to the `"E-Doc. Order Match"` table and update `"Qty. to Invoice"` on purchase lines.

- The Copilot PO matching (`EDocPOCopilotMatching.Codeunit.al`) builds a user prompt from imported line and PO line descriptions, sends it to GPT-4.1 with function-calling tools, and grounds the result by verifying cost/quantity thresholds before surfacing proposals.

- `EDocumentBackgroundJobs` manages three job types: the one-shot "created flow" trigger, the recurring 5-minute `GetResponse` poller, and the recurrent batch send/import jobs with configurable frequency.

- Do not confuse `EDocImport.Codeunit.al` in this folder with the full import pipeline -- it is the entry point that delegates to `Processing/Import/` for V2 import processing. See the Import docs for that pipeline.
