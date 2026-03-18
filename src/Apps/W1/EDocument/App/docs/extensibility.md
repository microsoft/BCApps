# Extensibility

This document is organized by developer intent. Each section describes a specific customization scenario, the interfaces involved, and what the framework expects from your implementation. Read [business-logic.md](business-logic.md) first for the processing flow context.

## How to implement a document format

Implement the `E-Document` interface (in `Document/Interfaces/EDocument.Interface.al`) and register it on the `E-Document Format` enum.

The format interface handles both export (BC document to XML/JSON) and import (XML/JSON to BC document). It has five methods:

```al
interface "E-Document"
{
    procedure Check(var SourceDocumentHeader: RecordRef; EDocumentService: Record "E-Document Service";
        EDocumentProcessingPhase: Enum "E-Document Processing Phase")
    procedure Create(EDocumentService: Record "E-Document Service"; var EDocument: Record "E-Document";
        var SourceDocumentHeader: RecordRef; var SourceDocumentLines: RecordRef; var TempBlob: Codeunit "Temp Blob")
    procedure CreateBatch(EDocumentService: Record "E-Document Service"; var EDocuments: Record "E-Document";
        var SourceDocumentHeaders: RecordRef; var SourceDocumentsLines: RecordRef; var TempBlob: Codeunit "Temp Blob")
    procedure GetBasicInfoFromReceivedDocument(var EDocument: Record "E-Document"; var TempBlob: Codeunit "Temp Blob")
    procedure GetCompleteInfoFromReceivedDocument(var EDocument: Record "E-Document";
        var CreatedDocumentHeader: RecordRef; var CreatedDocumentLines: RecordRef; var TempBlob: Codeunit "Temp Blob")
}
```

**What to know**:

- `Check` is called at release/post time, before the document is posted. Validate that all required data is present and throw an error if not. The `EDocumentProcessingPhase` tells you whether this is a release check or a post check.
- `Create` receives mapped RecordRefs (after `E-Doc. Mapping` transformations). Write the exported document into `TempBlob`. The E-Document record is writeable -- you can update fields like `Receiving Company VAT Reg. No.` here.
- `CreateBatch` is only called when batch processing is enabled. The `EDocuments` record set contains multiple E-Documents. Write a single combined blob.
- `GetBasicInfoFromReceivedDocument` is the V1 import entry point. Populate basic E-Document fields (vendor, amounts, dates) from the blob. This is called first for every received document.
- `GetCompleteInfoFromReceivedDocument` is the V1 import method that creates the actual BC purchase document. The `CreatedDocumentHeader` and `CreatedDocumentLines` RecordRefs should be populated with the newly created records.

For V2 import, these last two methods are still called for backward compatibility but the real work happens through the V2 interfaces described below.

## How to build a service connector

A service connector handles the network communication -- sending documents to and receiving documents from an external API. Implement one or more of these interfaces and register them on the `Service Integration` enum (in `Integration/ServiceIntegration.Enum.al`).

### Sending: `IDocumentSender`

In `Integration/Interfaces/IDocumentSender.Interface.al`:

```al
interface IDocumentSender
{
    procedure Send(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service";
        SendContext: Codeunit SendContext);
}
```

The `SendContext` gives you:

- `SendContext.GetTempBlob()` -- the exported document blob.
- `SendContext.Http().GetHttpRequestMessage()` / `GetHttpResponseMessage()` -- HTTP objects that will be automatically logged if populated.
- `SendContext.Status().SetStatus(...)` -- override the resulting service status (defaults to "Sent").

The framework determines sync vs async based on whether your implementation also implements `IDocumentResponseHandler`. If it does, the status will be set to "Pending Response" after a successful send.

### Async response: `IDocumentResponseHandler`

In `Integration/Interfaces/IDocumentResponseHandler.Interface.al`:

```al
interface IDocumentResponseHandler
{
    procedure GetResponse(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service";
        SendContext: Codeunit SendContext): Boolean;
}
```

Return `true` when the service confirms the document was received/processed. Return `false` to keep polling. If you log an error via `EDocumentErrorHelper`, the status transitions to "Sending Error" and polling stops.

### Receiving: `IDocumentReceiver`

In `Integration/Interfaces/IDocumentReceiver.Interface.al`:

```al
interface IDocumentReceiver
{
    procedure ReceiveDocuments(var EDocumentService: Record "E-Document Service";
        DocumentsMetadata: Codeunit "Temp Blob List"; ReceiveContext: Codeunit ReceiveContext)
    procedure DownloadDocument(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service";
        DocumentMetadata: Codeunit "Temp Blob"; ReceiveContext: Codeunit ReceiveContext)
}
```

`ReceiveDocuments` queries the API for available documents and adds one `Temp Blob` per document to the `DocumentsMetadata` list. Each blob typically contains the document ID or metadata needed by `DownloadDocument`. The count of blobs determines how many E-Documents will be created.

`DownloadDocument` is called once per document. Fetch the actual content and write it to `ReceiveContext.GetTempBlob()`. You can also update `EDocument` fields (like `Incoming E-Document No.`).

### Marking fetched: `IReceivedDocumentMarker`

In `Integration/Interfaces/IReceivedDocumentMarker.Interface.al`. Optional. If your connector implements this, the framework calls it after successfully downloading a document, so you can mark it as fetched on the external API to prevent re-downloading.

### Privacy consent: `IConsentManager`

In `Integration/Interfaces/IConsentManager.Interface.al`. Optional. If your connector implements this, the framework calls `ObtainPrivacyConsent()` when a user selects your integration on a service. Return `false` to block activation.

## How to add custom actions

Actions are post-send operations like approval checks and cancellation requests.

### `ISentDocumentActions`

In `Integration/Interfaces/ISentDocumentActions.Interface.al`:

```al
interface ISentDocumentActions
{
    procedure GetApprovalStatus(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service";
        ActionContext: Codeunit ActionContext): Boolean;
    procedure GetCancellationStatus(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service";
        ActionContext: Codeunit ActionContext): Boolean;
}
```

These are pre-built action types. The framework provides `SentDocumentApproval` and `SentDocumentCancellation` codeunits that call your implementation and update the status accordingly (Approved, Rejected, Canceled, or error).

### `IDocumentAction`

In `Integration/Interfaces/IDocumentAction.Interface.al`:

```al
interface IDocumentAction
{
    procedure InvokeAction(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service";
        ActionContext: Codeunit ActionContext): Boolean
}
```

This is the generic action interface. Return `true` to update the E-Document service status to whatever `ActionContext.Status().SetStatus(...)` was set to. Return `false` to leave the status unchanged.

`ActionContext` provides the same `Http()` and `Status()` accessors as `SendContext`.

## How to customize import processing

The V2 import pipeline has four steps, each driven by a separate interface. To customize a step, implement the relevant interface and register it on the corresponding enum.

### Step 1 -- Structure received data: `IStructureReceivedEDocument`

In `Processing/Interfaces/IStructureReceivedEDocument.Interface.al`:

```al
interface IStructureReceivedEDocument
{
    procedure StructureReceivedEDocument(EDocumentDataStorage: Record "E-Doc. Data Storage"): Interface IStructuredDataType
}
```

Takes raw blob data (e.g., a PDF) and returns a structured representation. The returned `IStructuredDataType` declares its file format and preferred `Read into Draft` implementation. Register on the `Structure Received E-Doc.` enum.

The built-in "Already Structured" value skips this step (reuses the unstructured blob as-is). This is the path for documents received as XML/JSON.

### Step 2 -- Read into draft: `IStructuredFormatReader`

In `Processing/Interfaces/IStructuredFormatReader.Interface.al`. Takes structured content and populates the `E-Document Purchase Header` and `E-Document Purchase Line` draft tables. Returns an `E-Doc. Process Draft` enum value that determines which `IProcessStructuredData` implementation runs next. Register on the `E-Doc. Read into Draft` enum.

### Step 3 -- Prepare draft: `IProcessStructuredData`

In `Processing/Interfaces/IProcessStructuredData.Interface.al`:

```al
interface IProcessStructuredData
{
    procedure PrepareDraft(EDocument: Record "E-Document"; EDocImportParameters: Record "E-Doc. Import Parameters"): Enum "E-Document Type";
    procedure GetVendor(EDocument: Record "E-Document"; Customizations: Enum "E-Doc. Proc. Customizations"): Record Vendor;
    procedure OpenDraftPage(var EDocument: Record "E-Document");
    procedure CleanUpDraft(EDocument: Record "E-Document");
}
```

`PrepareDraft` resolves BC entities (vendor, items, GL accounts) and returns the document type. `GetVendor` is called separately to populate the E-Document's vendor fields. `OpenDraftPage` opens the UI for manual review. `CleanUpDraft` is called when the E-Document is deleted.

### Step 4 -- Finish draft: `IEDocumentFinishDraft`

In `Processing/Interfaces/IEDocumentFinishDraft.Interface.al`:

```al
interface IEDocumentFinishDraft
{
    procedure ApplyDraftToBC(EDocument: Record "E-Document"; EDocImportParameters: Record "E-Doc. Import Parameters"): RecordId;
    procedure RevertDraftActions(EDocument: Record "E-Document");
}
```

`ApplyDraftToBC` creates the actual BC document (purchase invoice, journal line, etc.) and returns its `RecordId`. `RevertDraftActions` undoes this -- typically deleting the created document. This interface is registered on the `E-Document Type` enum, meaning different document types can have different finish behaviors.

### `IPrepareDraft`

In `Processing/Interfaces/IPrepareDraft.Interface.al`:

```al
interface IPrepareDraft
{
    procedure PrepareDraft(EDocument: Record "E-Document"; EDocImportParameters: Record "E-Doc. Import Parameters"): Enum "E-Document Type";
}
```

A simpler alternative to `IProcessStructuredData` when you only need to customize the draft preparation logic without vendor resolution or UI.

## How to customize export eligibility

### `IExportEligibilityEvaluator`

In `Processing/Interfaces/IExportEligibilityEvaluator.Interface.al`:

```al
interface IExportEligibilityEvaluator
{
    procedure ShouldExport(EDocumentService: Record "E-Document Service";
        SourceDocumentHeader: RecordRef; DocumentType: Enum "E-Document Type"): Boolean;
}
```

Register on the `Export Eligibility Evaluator` enum (set on the E-Document Service). Called after the document type support check passes. The default implementation (`DefaultExportEligibility`) always returns `true`. Override this to add custom conditions -- for example, only export invoices above a threshold amount, or only for specific customer groups.

## Key integration events

These are the most useful events for extending behavior without implementing a full interface:

**Export path** (in `EDocExport.Codeunit.al`):

- `OnBeforeEDocumentCheck` -- Skip or override the pre-post validation. Has `IsHandled` pattern.
- `OnAfterEDocumentCheck` -- Run additional validations after the standard check.
- `OnBeforeCreateEDocument` -- Modify the E-Document record before it's inserted.
- `OnAfterCreateEDocument` -- React to E-Document creation (e.g., add custom logging).

**Import path** (in `ImportEDocumentProcess.Codeunit.al`):

- `OnADIProcessingCompleted` -- Fired after Azure Document Intelligence structures a PDF.
- `OnFoundVendorNo` -- Fired when vendor resolution succeeds during Prepare Draft.

**Service status** (in `EDocumentProcessing.Codeunit.al`):

- `OnAfterModifyServiceStatus` -- React to any service status change.

**Log export** (in `EDocumentLog.Table.al`):

- `OnBeforeExportDataStorage` -- Customize the filename when a user exports log data.

**Service configuration** (in `EDocumentService.Table.al`):

- `OnAfterGetDefaultFileExtension` -- Override the default `.xml` file extension for a service.
