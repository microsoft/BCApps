# Extensibility

This document is organized by developer intent. Each section answers "I want to..." and points to the interfaces, enums, and events you need.

## Add a new document format

Extend the `E-Document Format` enum (enum 6101, `src/Document/EDocumentFormat.Enum.al`) and implement the `E-Document` interface (interface in `src/Document/Interfaces/EDocument.Interface.al`).

The interface requires these methods:

- `Check(SourceDocumentHeader, EDocumentService, EDocumentProcessingPhase)` -- validate the source document before export. Called at release and posting time.
- `Create(EDocumentService, EDocument, SourceDocumentHeader, SourceDocumentLines, TempBlob)` -- generate the e-document content (XML, JSON, etc.) from BC document fields into a TempBlob.
- `CreateBatch(EDocumentService, EDocument, SourceDocumentHeader, SourceDocumentLines, TempBlob)` -- same as Create but for batch mode where multiple documents are in the RecordRef.
- `GetBasicInfoFromReceivedDocument(EDocument, TempBlob)` -- (V1 import) extract basic header info (vendor, dates, amounts) from a received blob.
- `GetCompleteInfoFromReceivedDocument(EDocument, SourceDocumentHeader, SourceDocumentLines, TempBlob)` -- (V1 import) fully populate source document RecordRefs from the received blob.

See the existing README.md for a complete code example of extending this enum.

## Add a new service integration

Extend the `Service Integration` enum (enum 6151, `src/Integration/ServiceIntegration.Enum.al`). This enum implements three interfaces by default; you implement whichever your service needs.

**Required -- sending documents.** Implement `IDocumentSender` (`src/Integration/Interfaces/IDocumentSender.Interface.al`):

- `Send(EDocument, EDocumentService, SendContext)` -- send the exported blob to your service. Get the blob from `SendContext.GetTempBlob()`. Set up the HTTP request via `SendContext.Http().GetHttpRequestMessage()` and response via `SendContext.Http().GetHttpResponseMessage()` for automatic communication logging.

**Optional -- receiving documents.** Implement `IDocumentReceiver` (`src/Integration/Interfaces/IDocumentReceiver.Interface.al`):

- `ReceiveDocuments(EDocumentService, DocumentsMetadata, ReceiveContext)` -- fetch a list of available documents from the service. Add one TempBlob per document to the DocumentsMetadata list.
- `DownloadDocument(EDocument, EDocumentService, DocumentMetadata, ReceiveContext)` -- download the actual content for a single document. Store the content in `ReceiveContext.GetTempBlob()`.

If your service supports marking documents as fetched, also implement `IReceivedDocumentMarker`:

- `MarkFetched(EDocument, EDocumentService, DocumentBlob, ReceiveContext)` -- tell the service the document was successfully downloaded.

**Optional -- async response handling.** If `Send` is asynchronous (the service returns a tracking ID rather than immediate success), your codeunit should also implement `IDocumentResponseHandler`:

- `GetResponse(EDocument, EDocumentService, SendContext): Boolean` -- poll the service for the result. Return `true` when the response is final (status becomes Sent), `false` when still pending (status stays Pending Response). The framework detects async mode by checking `IDocumentSender is IDocumentResponseHandler`.

**Optional -- approval and cancellation.** Implement `ISentDocumentActions` (`src/Integration/Interfaces/ISentDocumentActions.Interface.al`):

- `GetApprovalStatus(EDocument, EDocumentService, ActionContext): Boolean` -- check if a sent document was approved.
- `GetCancellationStatus(EDocument, EDocumentService, ActionContext): Boolean` -- check if a sent document was canceled.

**Optional -- custom actions.** Implement `IDocumentAction` (`src/Integration/Interfaces/IDocumentAction.Interface.al`):

- `InvokeAction(EDocument, EDocumentService, ActionContext): Boolean` -- perform a custom action. Set the resulting status via `ActionContext.Status().SetStatus()`.

**Optional -- custom privacy consent.** Implement `IConsentManager` (`src/Integration/Interfaces/IConsentManager.Interface.al`):

- `ObtainPrivacyConsent(): Boolean` -- display a consent dialog when the service integration is first selected. The default implementation uses the BC Customer Consent management.

### Context objects

All V2 interfaces use context codeunits instead of raw parameters:

- `SendContext` (`src/Integration/Send/SendContext.Codeunit.al`): `GetTempBlob()` for document content, `Http()` for HTTP state, `Status()` for setting result status.
- `ReceiveContext` (`src/Integration/Receive/ReceiveContext.Codeunit.al`): `GetTempBlob()` / `SetTempBlob()` for content, `Http()` for HTTP state, `Status()` for status, `SetName()` / `SetFileFormat()` for metadata.
- `ActionContext` (`src/Integration/Actions/ActionContext.Codeunit.al`): `Http()` for HTTP state, `Status()` for setting result status.

The `Http()` codeunit gives you `GetHttpRequestMessage()` and `GetHttpResponseMessage()`. If you populate these, the framework automatically logs the request/response to `E-Document Integration Log`.

## Customize import processing

The V2 import pipeline has several plug points, all in `src/Processing/Interfaces/`.

**Structure unstructured data.** Extend the `Structure Received E-Doc.` enum and implement `IStructureReceivedEDocument`:

- `StructureReceivedEDocument(EDocumentDataStorage): Interface IStructuredDataType` -- convert a blob (PDF, image, etc.) into structured data. Return an `IStructuredDataType` with the content, file format, and preferred `Read into Draft` implementation.

**Read structured data into draft.** Extend the `E-Doc. Read into Draft` enum and implement `IStructuredFormatReader`:

- `ReadIntoDraft(EDocument, TempBlob): Enum "E-Doc. Process Draft"` -- parse structured data (XML, JSON) and populate draft tables (`E-Document Purchase Header`, `E-Document Purchase Line`). Return the `E-Doc. Process Draft` enum value that determines the processing implementation.
- `View(EDocument, TempBlob)` -- display a human-readable view of the structured data.

**Customize draft preparation (providers).** The `PreparePurchaseEDocDraft.Codeunit.al` orchestrates matching using provider interfaces. Override these by extending the `E-Doc. Proc. Customizations` enum:

- `IVendorProvider.GetVendor(EDocument): Record Vendor` -- resolve the vendor from e-document data.
- `IItemProvider.GetItem(EDocument, LineId, Vendor, UnitOfMeasure): Record Item` -- resolve the item for a line.
- `IUnitOfMeasureProvider.GetUnitOfMeasure(EDocument, LineId, ExternalUOM): Record "Unit of Measure"` -- resolve unit of measure.
- `IPurchaseOrderProvider.GetPurchaseOrder(EDocPurchaseHeader): Record "Purchase Header"` -- find a matching purchase order.
- `IPurchaseLineProvider` -- determine purchase line type and account for a line (replaces the obsolete `IPurchaseLineAccountProvider`).

**Customize draft finalization.** Extend the `E-Doc. Create Purchase Invoice` enum and implement `IEDocumentFinishDraft`:

- `ApplyDraftToBC(EDocument, EDocImportParameters): RecordId` -- create the real BC document from draft tables. Return the RecordId of the created document.
- `RevertDraftActions(EDocument)` -- undo the creation (delete the BC document).

## Control export eligibility

Extend the `Export Eligibility Evaluator` enum (enum in `src/Processing/ExportEligibilityEvaluator.Enum.al`) and implement `IExportEligibilityEvaluator`:

- `ShouldExport(EDocumentService, SourceDocumentHeader, DocumentType): Boolean` -- return false to prevent a document from being exported via this service. The default implementation always returns true.

This is useful for multi-service setups where different services handle different subsets of documents (e.g. by location or customer).

## Hook into processing via events

Key integration events in the codebase (all are `[IntegrationEvent]`):

**Export/creation events** (in `EDocExport.Codeunit.al`):

- `OnBeforeEDocumentCheck(RecRef, ProcessingPhase, IsHandled)` -- skip or customize validation
- `OnAfterEDocumentCheck(RecRef, ProcessingPhase)` -- post-validation hook
- `OnBeforeCreateEDocument(EDocument, SourceDocumentHeader)` -- modify E-Document before insert
- `OnAfterCreateEDocument(EDocument, SourceDocumentHeader)` -- react after E-Document creation

**Send events** (in `EDocIntegrationManagement.Codeunit.al`):

- `OnBeforeSendDocument(EDocument, EDocumentService, HttpRequest, HttpResponse)` -- inject headers, modify payload
- `OnAfterSendDocument(EDocument, EDocumentService, HttpRequest, HttpResponse)` -- post-send processing
- `OnBeforeIsEDocumentInStateToSend(EDocument, EDocumentService, IsInStateToSend, IsHandled)` -- override send eligibility

**Status events** (in `EDocumentProcessing.Codeunit.al`):

- `OnAfterModifyEDocumentStatus(EDocument, EDocumentServiceStatus)` -- react to document status changes
- `OnAfterModifyServiceStatus(EDocument, EDocumentService, EDocumentServiceStatus)` -- react to service status changes

## Business events (external API)

Two external business events are defined in `EDocumentBusinessEvents.Codeunit.al` (`src/Processing/API/`):

- `EDocumentStatusChanged` -- fires when the document-level status changes. Payload includes `EDocumentId`, `EDocumentStatus`, API URL, and web client URL.
- `EDocumentServiceStatusChanged` -- fires when a service-level status changes. Payload includes `EDocumentId`, `EDocumentServiceId`, `EDocumentServiceStatus`, API URL, and web client URL.

These enable external systems to subscribe to e-document lifecycle events via the BC business events webhook mechanism.

## API endpoints

The framework exposes several API pages in `src/Processing/API/Endpoints/`:

- `EDocumentsAPI.Page.al` -- CRUD for E-Document records
- `EDocumentServicesAPI.Page.al` -- read E-Document Service configuration
- `EDocumentServiceStatusAPI.Page.al` -- read service statuses
- `EDocFileContentAPI.Page.al` -- access document content blobs
- `NewEDocumentsAPI.Page.al` -- create new E-Documents via API
