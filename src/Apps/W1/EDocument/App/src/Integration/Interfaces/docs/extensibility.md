# Extending the E-Document integration layer

## How do I send documents to my service?

Extend the `Service Integration` enum with your connector's value and implement `IDocumentSender`. The framework passes you a `SendContext` containing the exported document blob and HTTP state objects.

```al
enumextension 50100 "My Connector" extends "Service Integration"
{
    value(50100; "My Connector")
    {
        Implementation =
            IDocumentSender = "My Connector Impl.",
            IDocumentReceiver = "My Connector Impl.",
            IConsentManager = "My Connector Impl.";
    }
}

codeunit 50100 "My Connector Impl."
    implements IDocumentSender, IDocumentReceiver, IConsentManager
{
    procedure Send(var EDocument: Record "E-Document";
                   var EDocumentService: Record "E-Document Service";
                   SendContext: Codeunit SendContext)
    var
        TempBlob: Codeunit "Temp Blob";
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Client: HttpClient;
    begin
        TempBlob := SendContext.GetTempBlob();
        Request := SendContext.Http().GetHttpRequestMessage();
        // Build your request from TempBlob, send via Client
        Client.Send(Request, Response);
        SendContext.Http().SetHttpResponseMessage(Response);
    end;
}
```

Key points:

- The document blob in `SendContext` is the formatted output (PEPPOL XML, etc.) already produced by the format layer.
- You must populate the HTTP request/response on the context -- the framework auto-logs them to integration logs.
- Set `SendContext.Status().SetStatus(...)` if you want a non-default service status (default is Sent).

## How do I support async sending?

Also implement `IDocumentResponseHandler` on the same codeunit. The framework detects this via `is` check and automatically:

1. Sets the service status to "Pending Response" after send.
2. Schedules a background job that polls `GetResponse`.

```al
codeunit 50100 "My Connector Impl."
    implements IDocumentSender, IDocumentResponseHandler
{
    procedure GetResponse(var EDocument: Record "E-Document";
                          var EDocumentService: Record "E-Document Service";
                          SendContext: Codeunit SendContext): Boolean
    begin
        // Poll your API. Return true when the service confirms receipt.
        // Return false to stay in "Pending Response" and retry later.
    end;
}
```

## How do I receive documents?

Implement `IDocumentReceiver`. The framework calls your connector in two phases:

1. `ReceiveDocuments` -- return a list of document metadata (one `Temp Blob` per document).
2. `DownloadDocument` -- called once per document to fetch the actual content.

```al
procedure ReceiveDocuments(var EDocumentService: Record "E-Document Service";
                           DocumentsMetadata: Codeunit "Temp Blob List";
                           ReceiveContext: Codeunit ReceiveContext)
begin
    // Call your API to list available documents.
    // Add one Temp Blob per document to DocumentsMetadata.
end;

procedure DownloadDocument(var EDocument: Record "E-Document";
                           var EDocumentService: Record "E-Document Service";
                           DocumentMetadata: Codeunit "Temp Blob";
                           ReceiveContext: Codeunit ReceiveContext)
begin
    // Read the metadata blob to get a document ID.
    // Download the document and write it into ReceiveContext.GetTempBlob().
end;
```

## How do I acknowledge that a document was fetched?

Also implement `IReceivedDocumentMarker` on your `IDocumentReceiver` codeunit. The framework calls `MarkFetched` after each successful download. If this call fails, the E-Document is not created -- ensuring you never silently lose documents by acknowledging receipt without storing them.

## How do I handle approval and cancellation?

Implement `ISentDocumentActions` on the same codeunit that implements `IDocumentSender`. The framework casts your sender to `ISentDocumentActions` at runtime. Return `true` from `GetApprovalStatus` or `GetCancellationStatus` to update the E-Document's status; return `false` if the external state has not changed.

## How do I add custom actions?

Extend the `Integration Action Type` enum with a new value and implement `IDocumentAction`:

```al
enumextension 50101 "My Custom Action" extends "Integration Action Type"
{
    value(50100; "My Custom Action")
    {
        Implementation = IDocumentAction = "My Custom Action Impl.";
    }
}
```

Then call `EDocIntegrationManagement.InvokeAction(EDocument, EDocService, Enum::"Integration Action Type"::"My Custom Action", ActionContext)` from your page action or processing code.
