# Extensibility

E-Document Core provides 25+ interfaces organized around developer customization goals. Rather than exposing low-level hooks, the system defines high-level contracts (format a document, send to a service, extract data) that implementations fulfill. This interface-driven architecture allows partners to add new services and formats without modifying core code.

## Add a new file format

**Goal:** Export sales documents or parse inbound documents in a custom XML/JSON/EDI format.

**Interfaces:**

- **IEDocFileFormat** -- Generates outbound format from Business Central document references
- **IStructureReceivedEDocument** -- Parses inbound blob into structured intermediate format
- **IStructuredFormatReader** -- Extracts fields from structured format using path expressions (ADI)

**Example: Custom XML invoice format**

```al
codeunit 50100 "My XML Format" implements IEDocFileFormat, IStructureReceivedEDocument
{
    procedure CreateDocument(var EDocument: Record "E-Document"; var SourceDocumentHeader: RecordRef; var SourceDocumentLines: RecordRef; var TempBlob: Codeunit "Temp Blob")
    begin
        // Read fields from SourceDocumentHeader (Sales Invoice Header)
        // Generate XML using XmlDocument APIs
        // Write to TempBlob
    end;

    procedure StructureDocument(var EDocument: Record "E-Document"; var TempBlob: Codeunit "Temp Blob"): Boolean
    begin
        // Parse XML from TempBlob
        // Populate E-Document fields (Document Date, Amount, Vendor No.)
        // Return true if successful
    end;
}
```

Register format enum value and subscribe to format selection events to wire up the interface.

## Add a new e-invoice service

**Goal:** Send documents to a government portal, clearance service, or private network.

**Interfaces:**

- **IDocumentSender** -- Sends formatted document to service endpoint
- **IDocumentReceiver** -- Polls service for inbound documents
- **IDocumentResponseHandler** -- Parses service responses and updates status
- **IConsentManager** -- Handles OAuth/consent flows for authenticated services

**Example: REST API sender**

```al
codeunit 50110 "My Service Sender" implements IDocumentSender
{
    procedure Send(var EDocument: Record "E-Document"; var TempBlob: Codeunit "Temp Blob"; var IsAsync: Boolean; var HttpRequest: HttpRequestMessage; var HttpResponse: HttpResponseMessage): Boolean
    var
        Client: HttpClient;
        Content: HttpContent;
    begin
        // Read formatted document from TempBlob
        // Build HTTP POST request with service auth headers
        // Send via Client.Post()
        // Check HttpResponse.IsSuccessStatusCode()
        IsAsync := false; // Synchronous response
        exit(HttpResponse.IsSuccessStatusCode());
    end;

    procedure SendBatch(var EDocuments: Record "E-Document"; var TempBlob: Codeunit "Temp Blob"; var IsAsync: Boolean; var HttpRequest: HttpRequestMessage; var HttpResponse: HttpResponseMessage): Boolean
    begin
        // Optional: implement batch send for multiple documents
        exit(false); // Not supported
    end;
}
```

Implement **IDocumentReceiver** to poll for inbound documents:

```al
codeunit 50111 "My Service Receiver" implements IDocumentReceiver
{
    procedure ReceiveDocuments(var TempBlob: Codeunit "Temp Blob"; var HttpRequest: HttpRequestMessage; var HttpResponse: HttpResponseMessage)
    begin
        // Poll service API for new documents
        // Download each document blob
        // Create E-Document records with Direction::Inbound
        // Write blob to TempBlob for structure step
    end;

    procedure DownloadDocument(var EDocument: Record "E-Document"; var TempBlob: Codeunit "Temp Blob"; var HttpRequest: HttpRequestMessage; var HttpResponse: HttpResponseMessage)
    begin
        // Download specific document by service tracking ID
    end;
}
```

## Customize data resolution

**Goal:** Control how inbound data maps to Business Central master data (vendors, items, UOMs).

**Interfaces:**

- **IVendorProvider** -- Resolves external vendor IDs to Vendor No.
- **IItemProvider** -- Resolves external item codes to Item No.
- **IUnitOfMeasureProvider** -- Resolves external UOM codes to Unit of Measure Code
- **IPurchaseLineProvider** -- Provides purchase line creation logic
- **IPurchaseOrderProvider** -- Provides purchase header creation logic

**Example: Custom vendor resolution**

```al
codeunit 50120 "My Vendor Resolver" implements IVendorProvider
{
    procedure GetVendor(VendorId: Text; var Vendor: Record Vendor): Boolean
    begin
        // VendorId might be tax ID, GLN, or custom identifier
        // Search Vendor table by custom field
        // Populate Vendor record reference
        // Return true if found
        if Vendor.Get(FindVendorByTaxId(VendorId)) then
            exit(true);
        exit(false);
    end;
}
```

Subscribe to `OnBeforeResolveVendor` event to inject custom resolution logic before default provider runs.

## Add AI-powered matching

**Goal:** Use Copilot to suggest purchase order matches or extract unstructured data.

**Interfaces:**

- **IEDocAISystem** -- Defines AI system contract (AOAI, Azure AI, custom LLM)
- **AOAI Function interface** -- Implements function calling pattern for structured outputs

**Example: AOAI Function for line matching**

```al
codeunit 50130 "My Match Function" implements "AOAI Function"
{
    procedure GetPrompt(): JsonObject
    begin
        // Define system prompt and function tools
        // Return JSON with "messages" array and "tools" array
    end;

    procedure Execute(Arguments: JsonObject): Variant
    var
        ImportedLine: Record "E-Doc. Imported Line";
        Matches: List of [Text];
    begin
        // Arguments contains AI-extracted parameters
        // Call GetCandidatePOLines with filters
        // Return match suggestions as JSON array
        exit(BuildMatchSuggestions(Matches));
    end;

    procedure GetName(): Text
    begin
        exit('match_purchase_line');
    end;
}
```

Register function via `AOAI Function` enum extension. The system calls `GetPrompt()` to build the AI request, sends to AOAI, parses function calls from response, and invokes `Execute()` with arguments.

## Customize document lifecycle

**Goal:** Add validation logic, enrich data, or trigger external workflows during export/import.

**Interfaces:**

- **IProcessStructuredData** -- Processes data after structure step, before read step
- **IEDocumentFinishDraft** -- Customizes purchase draft creation during finish step
- **IExportEligibilityEvaluator** -- Determines if document qualifies for export

**Example: Custom export eligibility**

```al
codeunit 50140 "My Export Validator" implements IExportEligibilityEvaluator
{
    procedure IsEligible(SourceDocumentHeader: RecordRef): Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // Check custom business rules
        // e.g., only export if customer is in EU
        SourceDocumentHeader.SetTable(SalesInvoiceHeader);
        exit(IsEUCustomer(SalesInvoiceHeader."Sell-to Customer No."));
    end;
}
```

Subscribe to export eligibility event:

```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"E-Doc. Export", OnBeforeCheckExportEligibility, '', false, false)]
local procedure OnBeforeCheckExportEligibility(var SourceDocumentHeader: RecordRef; var IsEligible: Boolean; var Handled: Boolean)
begin
    if not MyExportValidator.IsEligible(SourceDocumentHeader) then begin
        IsEligible := false;
        Handled := true;
    end;
end;
```

## Customize status behavior

**Goal:** Add custom status states or transitions beyond the built-in states (In Progress, Sent, Error, Processed).

**Interface:**

- **IEDocumentStatus** -- Implements state pattern for status calculation and display

**Example: Custom clearance status**

```al
codeunit 50150 "My Status Handler" implements IEDocumentStatus
{
    procedure GetStatus(EDocument: Record "E-Document"): Enum "E-Document Status"
    begin
        // Calculate custom status from Service Status records
        // e.g., if any clearance status is Failed, return Error
        exit(CalculateCustomStatus(EDocument));
    end;

    procedure CanTransitionTo(FromStatus: Enum "E-Document Status"; ToStatus: Enum "E-Document Status"): Boolean
    begin
        // Define allowed transitions
        // e.g., can't go from Error directly to Sent without re-processing
        exit(IsValidTransition(FromStatus, ToStatus));
    end;
}
```

## Add custom actions

**Goal:** Provide UI actions for service-specific operations (cancel, retrieve updated status, download receipt).

**Interfaces:**

- **IDocumentAction** -- Defines generic document action
- **ISentDocumentActions** -- Provides actions for sent documents

**Example: Cancel sent document**

```al
codeunit 50160 "My Cancel Action" implements ISentDocumentActions
{
    procedure GetActionCaption(): Text
    begin
        exit('Cancel Invoice');
    end;

    procedure InvokeAction(var EDocument: Record "E-Document"; var HttpRequest: HttpRequestMessage; var HttpResponse: HttpResponseMessage): Boolean
    begin
        // Call service API to cancel document
        // Update Service Status to Cancelled
        exit(HttpResponse.IsSuccessStatusCode());
    end;
}
```

Register action enum value and bind to service configuration.

## Events

Key events for cross-cutting customization:

**Export flow:**

```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"E-Doc. Export", OnBeforeEDocumentCheck, '', false, false)]
local procedure OnBeforeEDocumentCheck(var SourceDocumentHeader: RecordRef; var IsHandled: Boolean)
begin
    // Add pre-export validation
end;

[EventSubscriber(ObjectType::Codeunit, Codeunit::"E-Doc. Export", OnAfterCreatePEPPOLXMLDocument, '', false, false)]
local procedure OnAfterCreatePEPPOLXMLDocument(var EDocument: Record "E-Document"; var TempBlob: Codeunit "Temp Blob")
begin
    // Modify PEPPOL XML after generation
end;
```

**Import flow:**

```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"E-Doc. Import", OnADIProcessingCompleted, '', false, false)]
local procedure OnADIProcessingCompleted(var EDocument: Record "E-Document"; var ImportedLines: Record "E-Doc. Imported Line")
begin
    // Post-process extracted data
end;

[EventSubscriber(ObjectType::Codeunit, Codeunit::"Prepare Purchase E-Doc. Draft", OnBeforeCreatePurchaseHeader, '', false, false)]
local procedure OnBeforeCreatePurchaseHeader(var EDocument: Record "E-Document"; var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
begin
    // Customize purchase header before insert
end;
```

**Order matching:**

```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"E-Doc. Line Matching", OnAfterMatchLine, '', false, false)]
local procedure OnAfterMatchLine(var ImportedLine: Record "E-Doc. Imported Line"; var OrderMatch: Record "E-Doc. Order Match")
begin
    // Log custom match analytics
end;
```

These events fire at strategic points in the processing pipeline, allowing customization without replacing entire codeunits.
