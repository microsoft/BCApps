# Extensibility

## Building a new e-document connector

The most common extension scenario is adding support for a new country's e-invoicing standard. This requires two things: a format implementation and an integration implementation.

**Format implementation**: Create an enum extension for `E-Document Format` (in `EDocumentFormat.Enum.al`) and implement the `E-Document` interface (in `src/Document/Interfaces/EDocument.Interface.al`). Your implementation needs five methods: `Check` (validate before posting), `Create` (produce the outbound blob), `CreateBatch` (produce a batch blob), `GetBasicInfoFromReceivedDocument` (extract header info from an inbound blob), and `GetCompleteInfoFromReceivedDocument` (fully populate a purchase document from an inbound blob). The last two are V1-era methods -- for V2 import, you implement the reader interfaces instead, but the format interface is still required for the enum registration.

**Integration implementation**: Create an enum extension for `Service Integration V2` (in `ServiceIntegration.Enum.al`) and implement the relevant interfaces from `src/Integration/Interfaces/`. At minimum you need `IDocumentSender` for outbound. For inbound, implement `IDocumentReceiver` (list available documents and download them) plus `IReceivedDocumentMarker` (acknowledge receipt). For async sending, add `IDocumentResponseHandler`. For approval/cancellation workflows, add `ISentDocumentActions`. For custom actions, implement `IDocumentAction`.

The context objects (`SendContext`, `ReceiveContext`, `ActionContext`) are your API surface during transmission. They provide access to the document blob, HTTP message state (for automatic communication logging), and status control. If you populate `SendContext.Http().GetHttpRequestMessage()` and the response message, the framework automatically logs the HTTP exchange to `E-Document Integration Log`.

## Customizing the V2 import pipeline

Each stage of the import pipeline is independently extensible via interfaces in `src/Processing/Interfaces/`.

### How do I support a new input format (e.g., custom JSON)?

Extend the `Structure Received E-Doc.` enum and implement `IStructureReceivedEDocument`. Your implementation receives the raw `E-Doc. Data Storage` record and returns an `IStructuredDataType` that wraps the converted content. If the input is already structured (e.g., native XML), return it as-is with `Structure Received E-Doc.::Already Structured`.

Also extend the `E-Doc. Read into Draft` enum and implement `IStructuredFormatReader`. The `ReadIntoDraft` method receives the structured blob and populates `E-Document Purchase Header` and `E-Document Purchase Line` records. Return the `E-Doc. Process Draft` enum value that tells the framework which `IProcessStructuredData` implementation should handle stage 3.

### How do I customize vendor/item resolution?

Implement the provider interfaces: `IVendorProvider`, `IItemProvider`, `IUnitOfMeasureProvider`, `IPurchaseLineAccountProvider`, or `IPurchaseOrderProvider`. These are called during the "Prepare draft" stage via `EDocProviders.Codeunit.al`. The default implementation uses historical matching tables (`EDocPurchaseLineHistory`, `EDocVendorAssignHistory`) and BC's standard cross-reference lookups. Your implementation can add custom lookup logic -- for example, matching items by GTIN, vendor-specific product codes, or external catalog references.

### How do I control what BC document gets created?

Implement `IEDocumentFinishDraft` by extending the `E-Document Type` enum. The default implementations create Purchase Invoices (`EDocCreatePurchaseInvoice.Codeunit.al`) or update Purchase Orders, but you can implement your own to create journal lines, purchase credit memos, or any other document type. The `RevertDraftActions` method must undo whatever `ApplyDraftToBC` did.

### How do I add custom fields to import lines?

Use the EAV tables `E-Document Line - Field` (6110) and `E-Doc. Purchase Line Field Setup` (6109/6111). Register your custom fields in the setup table, then populate values in the line field table during the "Read into draft" stage. The UI pages (`EDocLineAdditionalFields`, `EDocFieldValueEdit`) automatically render configured fields.

## Integration events by intent

### Customizing outbound document creation

- `OnBeforeEDocumentCheck` / `OnAfterEDocumentCheck` in `EDocExport.Codeunit.al` -- Intercept or extend pre-posting validation. Use `IsHandled` to skip the standard check entirely.
- `OnAfterCreateEDocument` in `EDocExport.Codeunit.al` -- Modify the E-Document record or its blob after format creation but before sending.
- `OnAfterGetTypeFromSourceDocument` in `EDocExport.Codeunit.al` -- Override how the source BC document type maps to `E-Document Type`.

### Customizing send behavior

- `OnBeforeSendDocument` / `OnAfterSendDocument` in `EDocIntegrationManagement.Codeunit.al` -- Pre/post hooks around the integration Send call.
- `OnGetBatch` in `EDocIntegrationManagement.Codeunit.al` -- Customize batch assembly before sending.
- `OnBatchSendWithCustomBatchMode` in `EDocumentWorkFlowProcessing.Codeunit.al` -- Implement custom batch triggering logic.

### Customizing inbound processing

- `OnAfterProcessIncomingEDocument` in `EDocImport.Codeunit.al` -- Hook after V1 import completes.
- `OnBeforePrepareReceivedDoc` / `OnBeforeCreateDocument` in `EDocImport.Codeunit.al` -- Modify draft data or override document creation in V1.
- `OnFoundVendorNo` in `ImportEDocumentProcess.Codeunit.al` -- React when vendor resolution succeeds during V2 prepare stage.
- `OnADIProcessingCompleted` in `ImportEDocumentProcess.Codeunit.al` -- Hook after Azure Document Intelligence processing for custom post-processing.
- Events on `EDocumentCreatePurchDoc.Codeunit.al` -- Fine-grained control over purchase header/line creation during V1 import.

### Customizing PEPPOL processing

- `OnBeforeInsertEDocPEPPOLBIS30` / `OnAfterInsertEDocPEPPOLBIS30` in `EDocPEPPOLBIS30.Codeunit.al` -- Customize PEPPOL XML generation.
- `OnBeforeProcessImportedPEPPOLDocument` / `OnAfterProcessImportedPEPPOLDocument` in `EDocImportPEPPOLBIS30.Codeunit.al` -- Customize PEPPOL import parsing.
- `OnBeforePEPPOLPreMapDocument` in `EDocDEDPEPPOLPreMapping.Codeunit.al` -- Override Data Exchange Definition pre-mapping.

### Reacting to status changes

- `OnAfterModifyEDocumentStatus` in `EDocumentProcessing.Codeunit.al` -- Fires when the document-level status changes.
- `OnAfterModifyServiceStatus` in `EDocumentProcessing.Codeunit.al` -- Fires when a service-level status changes.
- `EDocumentStatusChanged` / `EDocumentServiceStatusChanged` in `EDocumentBusinessEvents.Codeunit.al` -- External business events for Power Automate / Logic Apps integration.

### Extending the service configuration

- `OnAfterInsertEDocService` in `EDocumentService.Table.al` -- React to new service creation.
- `OnBeforeOpenServiceIntegrationSetupPage` in `EDocumentService.Page.al` -- Open a custom setup page for your integration.

## Consent management

When a user configures a new service integration, the framework calls `IConsentManager.ObtainPrivacyConsent` (via the `Consent Manager Default Impl.` codeunit) before enabling the integration. Implement this interface if your connector needs custom privacy consent flows beyond the default dialog.

## API endpoints

The `src/Processing/API/Endpoints/` directory contains API pages for external integrations. The external business events (`EDocumentStatusChanged`, `EDocumentServiceStatusChanged`) allow Power Automate flows to react to e-document lifecycle changes without polling.
