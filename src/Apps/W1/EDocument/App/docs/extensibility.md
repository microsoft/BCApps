# Extensibility

This document is organized by developer intent -- what you want to customize, not which codeunit to look at. For the processing flows that call these extension points, see [business-logic.md](business-logic.md). For code examples of interface implementations, see [README.md](../README.md).

## Core pattern: enum extension binds interface implementation

All major extension points follow the same pattern. The framework defines an extensible enum that implements one or more interfaces. You extend the enum with a new value and bind it to your codeunit that implements the interface. At runtime, the framework reads the enum value from configuration and dispatches to your implementation.

Example: to add a custom document format, extend `enum 6101 "E-Document Format"` with a new value that implements the `"E-Document"` interface. Then set that format on the E-Document Service. No event subscriptions needed.

## Document format

**Goal**: Define how BC documents are serialized to/from electronic formats.

**Interface**: `"E-Document"` (in `Document/Interfaces/EDocument.Interface.al`)

**Methods**:

- `Check(SourceDocumentHeader, EDocumentService, EDocumentProcessingPhase)` -- validate on release/post
- `Create(EDocumentService, EDocument, SourceDocumentHeader, SourceDocumentLines, TempBlob)` -- serialize to blob
- `CreateBatch(EDocumentService, EDocuments, SourceDocumentHeaders, SourceDocumentsLines, TempBlob)` -- batch serialize
- `GetBasicInfoFromReceivedDocument(EDocument, TempBlob)` -- extract header info from received blob (V1.0 import)
- `GetCompleteInfoFromReceivedDocument(EDocument, CreatedDocumentHeader, CreatedDocumentLines, TempBlob)` -- parse into BC records (V1.0 import)

**Binding enum**: `"E-Document Format"` (`enum 6101`). Built-in values: `"Data Exchange"` and `"PEPPOL BIS 3.0"`. PEPPOL XML construction and validation primitives live in the standalone PEPPOL app that Core depends on; Core keeps the enum binding and adapter/reader logic.

*Updated: 2026-07-29 -- clarified the PEPPOL split between Core and the standalone PEPPOL app.*

**Where configured**: `"Document Format"` field on `"E-Document Service"` table.

## Service integration (send and receive)

**Goal**: Connect to an external service endpoint for sending and receiving electronic documents.

### Sending

**Interface**: `IDocumentSender` (in `Integration/Interfaces/IDocumentSender.Interface.al`)

```
procedure Send(var EDocument, var EDocumentService, SendContext)
```

The `SendContext` provides the exported blob via `GetTempBlob()`, HTTP request/response objects via `Http()`, and a status object via `Status()`. Set the status to control the resulting service status (default is `Sent`).

For **async sending**, your sender implementation must also implement `IDocumentResponseHandler`:

```
procedure GetResponse(var EDocument, var EDocumentService, SendContext): Boolean
```

Return `true` when the service confirms receipt (status becomes `Sent`), `false` to keep polling (status stays `Pending Response`). A runtime error or logged error message sets `Sending Error`.

### Receiving

**Interface**: `IDocumentReceiver` (in `Integration/Interfaces/IDocumentReceiver.Interface.al`)

Two methods:

- `ReceiveDocuments(EDocumentService, DocumentsMetadata, ReceiveContext)` -- query the service for available documents, add one TempBlob per document to the list
- `DownloadDocument(EDocument, EDocumentService, DocumentMetadata, ReceiveContext)` -- download a single document's content into `ReceiveContext.GetTempBlob()`

Optionally implement `IReceivedDocumentMarker` to mark documents as fetched on the service after download:

```
procedure MarkFetched(EDocument, EDocumentService, DocumentBlob, ReceiveContext)
```

### Consent

**Interface**: `IConsentManager` (in `Integration/Interfaces/IConsentManager.Interface.al`)

Invoked when a user selects a service integration for the first time. Return `true` to allow, `false` to block.

### Binding enum

`"Service Integration"` (`enum 6151`). Implements `IDocumentSender`, `IDocumentReceiver`, and `IConsentManager`. Built-in value: `"No Integration"`.

**Where configured**: `"Service Integration V2"` field on `"E-Document Service"` table.

## Actions on sent documents

**Goal**: Define custom actions that can be performed on E-Documents after sending (approval checks, cancellation, etc.).

**Interface**: `IDocumentAction` (in `Integration/Interfaces/IDocumentAction.Interface.al`)

```
procedure InvokeAction(var EDocument, var EDocumentService, ActionContext): Boolean
```

Return `true` to update the E-Document status to `ActionContext.Status().GetStatus()`, `false` to leave it unchanged.

**Binding enum**: `"Integration Action Type"` (`enum 6170`). Built-in: `"Sent Document Approval"` and `"Sent Document Cancellation"`.

For the two built-in actions, the framework also checks if the service integration implements `ISentDocumentActions`, which provides `GetApprovalStatus()` and `GetCancellationStatus()` methods.

## Import pipeline (V2.0)

### Structuring received documents

**Goal**: Convert a raw blob (e.g., PDF) into a structured, machine-readable format.

**Interface**: `IStructureReceivedEDocument` (in `Processing/Interfaces/IStructureReceivedEDocument.Interface.al`)

```
procedure StructureReceivedEDocument(EDocumentDataStorage): Interface IStructuredDataType
```

Returns an `IStructuredDataType` that wraps the structured content, its file format, and which `"E-Doc. Read into Draft"` implementation should read it. If it returns `Unspecified`, the pipeline falls back to the E-Document's value and then to the service's Draft Format field.

**Binding enum**: `"Structure Received E-Doc."` (`enum 6103`).

### Reading structured data into staging tables

**Goal**: Parse structured data (XML, JSON, ADI output) into the E-Document purchase or sales staging tables.

**Interface**: `IStructuredFormatReader` (in `Processing/Interfaces/IStructuredFormatReader.Interface.al`)

```
procedure ReadIntoDraft(EDocument, TempBlob): Enum "E-Doc. Process Draft"
procedure View(EDocument, TempBlob)
```

`ReadIntoDraft` populates the staging tables and returns the `"E-Doc. Process Draft"` enum value that determines which `IProcessStructuredData` runs next. Built-in readers include PEPPOL, ADI, MLLM, Blank Draft, and Data Exchange Purchase; dependent format apps can add readers such as OIOUBL or XRechnung by extending the enum.

**Binding enum**: `"E-Doc. Read into Draft"` (`enum 6109`).

The Data Exchange Purchase reader uses `E-Doc. Data Exchange Impl.` as a reusable XML-to-intermediate-data bridge and then maps the result into `E-Document Purchase Header` and `E-Document Purchase Line`. Those draft tables are exposed for dependent country apps to consume, while the bridge events below remain the safer customization points for adjusting mapped data. `E-Doc. Data Exchange Impl.` is no longer restricted with `Access = Internal`, but extensions should still prefer enum bindings and published events before depending on implementation details.

### Processing the draft

**Goal**: Resolve BC entities (vendors, items, accounts) from the parsed data and prepare for document creation.

**Interface**: `IProcessStructuredData` (in `Processing/Interfaces/IProcessStructuredData.Interface.al`)

```
procedure PrepareDraft(EDocument, EDocImportParameters): Enum "E-Document Type"
procedure GetVendor(EDocument, Customizations): Record Vendor
procedure OpenDraftPage(var EDocument)
procedure CleanUpDraft(EDocument)
```

`PrepareDraft` returns the resolved document type. `GetVendor` is called separately for purchase drafts to populate the E-Document's vendor fields. Sales implementations can extend the contract through `IProcessStructuredDataSales` to resolve customers. `CleanUpDraft` is called when an E-Document is deleted.

**Binding enum**: `"E-Doc. Process Draft"` (`enum 6107`).

### Finishing the draft (creating BC documents)

**Goal**: Create the actual BC purchase document from the staging tables.

**Interface**: `IEDocumentFinishDraft` (in `Processing/Interfaces/IEDocumentFinishDraft.Interface.al`)

```
procedure ApplyDraftToBC(EDocument, EDocImportParameters): RecordId
procedure RevertDraftActions(EDocument)
```

`ApplyDraftToBC` creates the BC document for the resolved E-Document Type and returns its RecordId. Current Core implementations handle Purchase Invoice, Purchase Credit Memo, and Sales Order. `RevertDraftActions` undoes the Core link and moves attachments back to the E-Document; it does not post or delete the user's business document for them.

**Binding enum**: `"E-Document Type"` (`enum 6121`). Each document type value implements this interface to handle its specific creation logic.

*Updated: 2026-07-29 -- added Draft Format fallback, Data Exchange Purchase, sales order import, and dependent format readers.*

## Provider interfaces

These interfaces allow customization of specific resolution steps during the "Prepare draft" stage. They are invoked by the `IProcessStructuredData` implementation.

- **IVendorProvider** -- resolve vendor from E-Document data
- **IItemProvider** -- resolve item from E-Document line, vendor, and unit of measure
- **IUnitOfMeasureProvider** -- resolve unit of measure from external code
- **IPurchaseLineProvider** -- determine purchase line type and account (replaces deprecated `IPurchaseLineAccountProvider`)
- **IPurchaseOrderProvider** -- match E-Document to an existing purchase order
- **ICustomerProvider** -- resolve a customer for inbound sales order drafts
- **ISalesLineProvider** -- resolve sales line type, number, item reference, dimensions, and unit of measure
- **IEDocumentCreateSalesOrder** -- customize how a staged inbound order becomes a BC Sales Order

## Export eligibility

**Goal**: Control which documents should be exported via a given service, beyond document type matching.

**Interface**: `IExportEligibilityEvaluator` (in `Processing/Interfaces/IExportEligibilityEvaluator.Interface.al`)

```
procedure ShouldExport(EDocumentService, SourceDocumentHeader, DocumentType): Boolean
```

**Binding enum**: `"Export Eligibility Evaluator"`. Configured on the service's `"Export Eligibility Evaluator"` field.

## Message formats (order responses and other lifecycle messages)

**Goal**: Provide your own message format (e.g. a CDAR/ApplicationResponse acknowledgement) that the framework emits as a lifecycle event on an E-Document, without creating an extra BC document.

**Interfaces**:

- `IEDocMessageBuilder` (in `Processing/Interfaces/IEDocMessageBuilder.Interface.al`) -- builds the message payload:

```
procedure BuildMessage(EDocument, ResponseType, var TempBlob)
```

- `IEDocResponseProvider` (in `Processing/Interfaces/IEDocResponseProvider.Interface.al`) -- lets a document format declare which message type (if any) to emit as a response:

```
procedure GetResponseMessageType(EDocument): Enum "E-Document Message Type"
```

**Binding enums**: `"E-Document Message Type"` (`enum 6436`) implements `IEDocMessageBuilder` -- each message type value dispatches to the codeunit that builds it. `"E-Document Format"` (`enum 6101`) implements `IEDocResponseProvider` -- the format selects the message type, or returns `Unknown` for none.

To ship a new message format, your app (depending only on E-Document Core):

1. Extend `"E-Document Message Type"` with a value bound to your `IEDocMessageBuilder` implementation.
2. Optionally extend `"E-Doc. Response Type"` (`enum 6427`) if your format has response semantics beyond Acknowledged/Accepted/Rejected.
3. Implement `IEDocResponseProvider` on your `"E-Document Format"` value, returning your message type for the documents that should get a response.
4. The framework builds the payload via your builder and persists it with `"E-Doc. Message Mgt.".CreateMessage()`, linked to the E-Document and visible in the message FactBox.

The built-in `"PEPPOL Order Response"` value follows the same pattern: it binds to `"E-Doc. PEPPOL Msg. Builder"` (Core-hosted), which delegates XML construction to the PEPPOL app's pure builder.

## AI tools

**Goal**: Register AI-powered processing capabilities (PDF classification, GL account matching, etc.).

**Interface**: `IEDocAISystem` (in `Processing/Interfaces/IEDocAISystem.Interface.al`)

```
procedure GetSystemPrompt(UserLanguage): SecretText
procedure GetTools(): List of [Interface "AOAI Function"]
procedure GetFeatureName(): Text
```

Implementations provide a system prompt, a list of AOAI Function tools, and a feature name for telemetry. The framework invokes these via the E-Document AI Processor during Copilot-assisted processing.

## Key integration events

Beyond interfaces, the framework publishes integration events for finer-grained customization. Major ones, organized by area:

**Export/create** (in `EDocExport.Codeunit.al`):

- `OnBeforeEDocumentCheck` / `OnAfterEDocumentCheck` -- override or extend document validation
- `OnBeforeCreateEDocument` / `OnAfterCreateEDocument` -- modify E-Document before/after creation

**Send** (in `EDocIntegrationManagement.Codeunit.al`):

- `OnBeforeSendDocument` / `OnAfterSendDocument` -- hook into send process
- `OnBeforeIsEDocumentInStateToSend` -- override send eligibility check

**Import pipeline** (in `ImportEDocumentProcess.Codeunit.al`):

- `OnADIProcessingCompleted` -- react to Azure Document Intelligence processing completion
- `OnFoundVendorNo` -- react to vendor resolution during draft preparation

**Data Exchange V2 bridge** (in `EDocDataExchPurchHandler.Codeunit.al`):

- `OnAfterBridgeToStagingTables` -- react after Data Exchange intermediate data has been mapped to the purchase staging header
- `OnAfterMapLineToStaging` -- react after each intermediate purchase line record becomes an E-Document Purchase Line

**Service configuration** (in `EDocumentService.Table.al`):

- `OnAfterGetDefaultFileExtension` -- override the default file extension for the service

**Subscribers** (in `EDocumentSubscribers.Codeunit.al`):

- Events on draft page field validations for reacting to user edits

**Attachments** (in `EDocAttachmentProcessor.Codeunit.al`):

- Document Attachment Management subscribers make E-Document act like an attachment-bearing source record, including filters by `"E-Document Entry No."`. This is the safe extension surface for flows that need to attach or move files around E-Documents, including Digital Voucher attachment flows.

**Import processing** (in `EDocImport.Codeunit.al`):

- `OnAfterProcessIncomingEDocument` -- react after the import pipeline completes or advances a step

*Updated: 2026-07-29 -- added Data Exchange bridge and attachment extension points.*

## Processing customizations

The `"E-Doc. Proc. Customizations"` enum on the service (field 61) provides a secondary customization axis. It is passed into purchase and sales draft processing, allowing different vendor, customer, line, unit of measure, purchase document creation, and sales order creation strategies per service.

*Updated: 2026-07-29 -- expanded processing customization coverage to sales order import.*
