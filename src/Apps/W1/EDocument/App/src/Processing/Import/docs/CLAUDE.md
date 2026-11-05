# Import pipeline

The V2 import pipeline converts a received blob (XML, JSON, PDF) into a reviewable Business Central draft and then into the target BC document. It is no longer purchase-invoice-only: built-in process draft implementations now create purchase invoices, purchase credit memos, and inbound sales orders. The pipeline is orchestrated by `ImportEDocumentProcess.Codeunit.al`, which dispatches each stage through enum-backed interfaces so formats and providers can be swapped without changing the orchestrator.

*Updated: 2026-07-29 -- Import V2 now routes to purchase invoice, purchase credit memo, or sales order drafts, and format selection is enum-driven.*

## How it works

An incoming E-Document enters the pipeline at status `Unprocessed` with a raw blob in `E-Doc. Data Storage`. Each step advances the status by one notch:

- **Structure received data** converts unstructured data into a structured blob and moves to `Readable`. XML and JSON use `Already Structured`. PDF now prefers `MLLM`, which calls Azure OpenAI with the prompt in `App/.resources/Prompts/EDocMLLMExtraction-SystemPrompt.md` and falls back to ADI if the model returns empty or invalid JSON. ADI remains available and falls back to `Blank Draft` when it cannot produce structured data.

- **Read into draft** parses the structured blob into staging tables and moves to `Ready for draft`. PEPPOL reads invoices, credit notes, orders, and order responses. `Data Exchange Purchase` lets configured Data Exchange definitions feed the V2 purchase staging tables. External apps can add more readers, such as XRechnung and OIOUBL, by extending the read-into-draft enum.

- **Prepare draft** resolves BC entities and moves to `Draft ready`. Purchase drafts resolve vendor, purchase order, UOM, item or account, VAT product posting group, historical values, GL account suggestions, and deferrals. Sales drafts resolve customer, UOM, and sales line item references.

- **Finish draft** creates or links the BC document and moves to `Processed`. Purchase invoice, purchase credit memo, and sales order finalizers all write `E-Doc. Record Link` entries or `E-Document Link` values for traceability and attachment movement.

Each step is undoable. Undoing Finish Draft delegates to the current `E-Document Type` implementation and clears `Document Record ID`. Purchase and sales helper code moves attachments back and clears the `E-Document Link`; it does not delete the created BC document. Undoing Prepare Draft clears header mappings, bill-to/pay-to fields, and `Document Type`. Undoing Structure clears the structured data pointer. The user can fix data at any stage and re-run forward from there.

V1 services are still supported: when `GetImportProcessVersion()` returns `Version 1.0`, the pipeline collapses to the legacy import code path and only the Finish Draft step is meaningful. New services initialize with `Import Process = Version 2.0`, and for V2 services the service card exposes `Read into Draft Impl.` as the user-facing draft format fallback for already-structured documents.

*Updated: 2026-07-29 -- Added MLLM, Data Exchange bridge, sales order, credit memo, and V2 default behavior.*

## Things to know

- The pipeline status is an ordered enum (`Unprocessed` = 0 through `Processed` = 4). `StatusStepIndex()` maps each status to a numeric index used for comparison and navigation -- this is how `GetNextStep()` and `GetPreviousStep()` work.

- The `E-Doc. Import Parameters` table is temporary and controls pipeline execution: which step to run, whether to target a step or desired status, processing customizations, V1 compatibility flags, and `Existing Doc. RecordId` for linking to an existing document instead of creating one.

- Interface dispatch is layered: `IEDocFileFormat` determines the preferred `IStructureReceivedEDocument`, which returns an `IStructuredDataType` that can override the `IStructuredFormatReader`, which returns the `IProcessStructuredData` enum. If no reader is set by the document or structuring step, the service-level `Read into Draft Impl.` field is used.

- The `E-Doc. Process Draft` enum now separates `Purchase Invoice`, `Purchase Credit Memo`, and `Sales Order`. The old `Purchase Document` value is pending obsolete for v29 and should not be described as the current route.

- The `E-Doc. Proc. Customizations` enum is a multi-interface enum. It now bundles purchase providers, purchase invoice creation, purchase credit memo creation, customer resolution, sales line resolution, and sales order creation. Extensions add one enum value to swap a coherent set of providers.

- AI-assisted purchase line matching runs during Prepare Draft: historical matching first, then GL account matching for remaining unresolved lines, then deferral matching. The old Purchase Order Matching Copilot is obsolete; PO matching itself remains a manual and rules-based purchase draft feature.

- Purchase draft dates are deliberately carried forward. `Document Date` and `Due Date` from the staging header are copied to the E-Document during Prepare Draft, then validated onto the purchase document during Finish Draft. If purchase setup requests it, posting date defaults from the draft document date.

- VAT handling is split between Prepare and Finish. Prepare resolves `[BC] VAT Prod. Posting Group` from extracted VAT rates when purchase setup enables it, computes whether a VAT amount difference is allowed, and logs why it was or was not applied. Finish distributes the allowed difference across purchase lines.

- Errors raised while finalizing fields are wrapped with validation context by `E-Doc. Import Error Context`, so a failed additional field or purchase field validation points to the field being applied instead of surfacing only the lower-level error.

- Reader failures, including JSON parsing failures from ADI or MLLM structured data, are run through `E-Doc. Import.RunConfiguredImportStep()`. That wrapper logs the error on the E-Document instead of letting malformed structured data break the session.

- Purchase invoice pages outside this folder now show an inbound PDF preview factbox when `E-Document Helper.GetInboundPdfPreviewEntryNo()` can find a PDF source linked to the E-Document. The purchase draft line subform also has a hidden `Name` column that users can personalize in; it displays the matched item, account, or other entity name rather than the extracted invoice description.

- The history system is populated by event subscribers on `Purch.-Post`: `OnAfterPurchInvLineInsert` and `OnAfterPostPurchaseDoc` create entries in `E-Doc. Purchase Line History` and `E-Doc. Vendor Assign. History`, completing the learning loop.

- See `../docs/CLAUDE.md` for the parent Processing module context. The interface contracts live in `src/Processing/Interfaces/`, with import-specific implementations under this folder.

*Updated: 2026-07-29 -- Added current enum values, setup fallback, VAT/date behavior, and obsolete Copilot note.*
