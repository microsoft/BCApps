# Extensibility

## Add a new document format

**What it enables:** Serialize BC documents into a different format (e.g., XRechnung, ZUGFeRD, OIOUBL) for outbound, and optionally parse that format for inbound.

**Interface:** `"E-Document"` (in `src/Document/Interfaces/EDocument.Interface.al`). This is the format interface, confusingly named the same as the table.

**How to wire it:** Extend the `E-Document Format` enum with a new value and implement the interface. The implementation handles both export (creating the blob from a BC document) and import (parsing the blob into BC fields).

```al
enumextension 50100 "My Format" extends "E-Document Format"
{
    value(50100; "My Custom Format")
    {
        Implementation = "E-Document" = "My Custom Format Impl.";
    }
}

codeunit 50100 "My Custom Format Impl." implements "E-Document"
{
    // Implement Create, CreateBatch, GetBasicInfo, GetBasicInfoFromReceivedDocument, etc.
}
```

The key methods to implement are `Create` (serialize a single document), `CreateBatch` (serialize multiple documents), and the import-side methods. The built-in PEPPOL implementation in `src/Format/EDocPEPPOLBIS30.Codeunit.al` is the reference implementation.

## Add a service connector

**What it enables:** Send e-documents to and receive them from an external service (Avalara, Pagero, a custom API, etc.).

**Interfaces:**

- `IDocumentSender` (required for outbound) -- sends a single or batch of documents. Gets a `SendContext` with the blob and HTTP state.
- `IDocumentReceiver` (required for inbound) -- polls for available documents and downloads them. Gets a `ReceiveContext`.
- `IDocumentResponseHandler` (optional) -- polls for async responses after send. Implement if your service doesn't return final status synchronously.
- `ISentDocumentActions` (optional) -- provides approval/cancellation workflows for sent documents.
- `IReceivedDocumentMarker` (optional) -- marks documents as processed on the external service after download.
- `IConsentManager` (optional) -- customizes the privacy consent flow when connecting to the service.

**How to wire it:** Extend the `Service Integration` enum (the V2 one, `ServiceIntegration.Enum.al`):

```al
enumextension 50100 "My Connector" extends "Service Integration"
{
    value(50100; "My API")
    {
        Implementation =
            IDocumentSender = "My API Sender",
            IDocumentReceiver = "My API Receiver",
            IDocumentResponseHandler = "My API Response Handler",
            ISentDocumentActions = "My API Actions",
            IReceivedDocumentMarker = "My API Marker";
    }
}
```

The send implementation receives a `SendContext` that carries the document blob, HTTP message state, and an action status object. Populate the HTTP request message on the context and the framework will automatically log the request/response to the integration log. See `src/Integration/Interfaces/IDocumentSender.Interface.al` for the documented contract with code examples.

## Customize import processing

**What it enables:** Override how incoming documents are resolved against BC master data (vendor matching, item matching, account assignment) or how the final BC document is created.

**Interfaces for the Prepare Draft stage:**

- `IProcessStructuredData` -- the top-level orchestrator for draft preparation. Calls the provider interfaces below. Extend the `E-Doc. Process Draft` enum.
- `IPrepareDraft` -- a simpler alternative if you only need to customize the preparation step.
- `IVendorProvider` -- resolve the incoming vendor identity to a BC Vendor record.
- `IItemProvider` -- resolve an incoming line to a BC Item.
- `IUnitOfMeasureProvider` -- resolve UOM codes.
- `IPurchaseLineProvider` -- customize how draft purchase lines are populated.
- `IPurchaseLineAccountProvider` -- assign G/L accounts to non-item lines.
- `IPurchaseOrderProvider` -- find the matching purchase order for PO-based imports.

**Interface for the Finish Draft stage:**

- `IEDocumentFinishDraft` -- creates the actual BC document from prepared draft data. Implement `ApplyDraftToBC` (returns the RecordId of the created document) and `RevertDraftActions` (reverses creation if the user undoes the step). Extend the `E-Doc. Create Purchase Invoice` enum.

```al
enumextension 50100 "My Draft Processor" extends "E-Doc. Process Draft"
{
    value(50100; "My Custom Processor")
    {
        Implementation = IProcessStructuredData = "My Draft Processor Impl.";
    }
}
```

The default implementation in `PreparePurchaseEDocDraft` (in `src/Processing/Import/PrepareDraft/`) delegates to provider interfaces via `EDocProviders` (in the same folder). If you only need to override one aspect (e.g., vendor matching), implement just that provider interface and register it.

## Add a structured format handler

**What it enables:** Support a new input format for incoming documents (e.g., a proprietary XML schema, a new PDF extraction service, or a custom JSON format).

**Interfaces:**

- `IStructureReceivedEDocument` -- converts unstructured data (PDF, image) into structured data (XML, JSON). Returns an `IStructuredDataType` that specifies the resulting format and content. Extend the `Structure Received E-Doc.` enum.
- `IStructuredFormatReader` -- reads structured data into the draft staging tables. Returns the `E-Doc. Process Draft` enum value that will handle Prepare Draft. Extend the `E-Doc. Read into Draft` enum.

```al
enumextension 50100 "My Structurer" extends "Structure Received E-Doc."
{
    value(50100; "My OCR Service")
    {
        Implementation = IStructureReceivedEDocument = "My OCR Structurer";
    }
}
```

The built-in structurers are in `src/Processing/Import/StructureReceivedEDocument/`: `EDocumentADIHandler` (Azure Document Intelligence), `EDocumentMLLMHandler` (multimodal LLM), and `EDocumentPEPPOLHandler` (passthrough for already-structured PEPPOL). The file format implementations in `src/Processing/Import/FileFormat/` (PDF, XML, JSON) determine the default structurer for each file type.

## Customize export eligibility

**What it enables:** Control which documents should be exported to a given service based on custom business rules (e.g., only export to a service if the customer is in a specific country).

**Interface:** `IExportEligibilityEvaluator` -- implement `ShouldExport` to return true/false based on the service, document header, and document type. Extend the `Export Eligibility Evaluator` enum.

```al
enumextension 50100 "My Eligibility" extends "Export Eligibility Evaluator"
{
    value(50100; "Country Filter")
    {
        Implementation = IExportEligibilityEvaluator = "My Country Filter Eval.";
    }
}
```

## Add custom actions

**What it enables:** Add custom operations that can be performed on sent documents beyond the built-in approval/cancellation.

**Interface:** `IDocumentAction` -- implement `InvokeAction` which receives an `ActionContext` and returns whether the action should update the E-Document status. Wire it through the `Integration Action Type` enum.

```al
enumextension 50100 "My Actions" extends "Integration Action Type"
{
    value(50100; "My Custom Action")
    {
        Implementation = IDocumentAction = "My Action Impl.";
    }
}
```

The action runner in `src/Integration/Actions/EDocumentActionRunner.Codeunit.al` orchestrates the execution and logging.

## Key integration events

The framework publishes integration events at critical processing points. These are useful when you need to hook into the flow without implementing a full interface.

**Export events** (in `EDocExport.Codeunit.al`):

- `OnBeforeCreateEDocument` / `OnAfterCreateEDocument` -- before and after e-document record creation during export
- `OnBeforeExportEdocument` / `OnAfterExportEdocument` -- before and after format serialization

**Import events** (in `EDocImport.Codeunit.al`):

- `OnBeforeCreatePurchaseDocumentFromEDocument` / `OnAfterCreatePurchaseDocumentFromEDocument` -- bracket BC document creation from import (V1)
- `OnBeforeProcessImportedDocument` / `OnAfterProcessImportedDocument` -- bracket the full import processing
- `OnBeforeInsertImportedEdocument` -- allows interception before the E-Document record is inserted during receive

**Send/receive events** (in `EDocIntegrationManagement.Codeunit.al`):

- `OnBeforeSendDocument` / `OnAfterSendDocument` -- bracket the IDocumentSender call
- `OnGetDocumentCountInBatch` -- allows overriding batch document count detection

**Status events** (in `EDocumentProcessing.Codeunit.al`):

- `OnAfterModifyServiceStatus` -- fired after any service status change. The business events codeunit (`EDocumentBusinessEvents`) subscribes to this to emit Power Automate external business events.

**Business events** (in `src/Processing/API/EDocumentBusinessEvents.Codeunit.al`):

- `EDocumentStatusChanged` -- external business event for Power Automate when document-level status changes
- `EDocumentServiceStatusChanged` -- external business event when per-service status changes
