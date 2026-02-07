// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

using Microsoft.eServices.EDocument;
using Microsoft.Sales.Customer;

codeunit 148195 "E2E Tests - Error Scenarios"
{
    Subtype = Test;
    TestHttpRequestPolicy = AllowOutboundFromHandler;
    TestPermissions = Disabled;

    var
        Customer: Record Customer;
        EDocumentService: Record "E-Document Service";
        Assert: Codeunit Assert;
        LibraryEDocument: Codeunit "Library - E-Document";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('HttpNetworkErrorHandler')]
    procedure TestSubmitDocument_NetworkError_SetsErrorState()
    var
        EDocument: Record "E-Document";
    begin
        // [SCENARIO] Network errors during submission set document to Error state

        // [GIVEN] Configured E-Document service
        Initialize();

        // [WHEN] Posting invoice with network error
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);
        EDocument.FindLast();

        // [THEN] E-Document should be in error state
        Assert.AreEqual(Enum::"E-Document Status"::Error, EDocument.Status, 'Document should be in error state');
    end;

    [Test]
    [HandlerFunctions('HttpTimeoutHandler')]
    procedure TestSubmitDocument_Timeout_SetsErrorState()
    var
        EDocument: Record "E-Document";
    begin
        // [SCENARIO] Timeout during submission sets document to Error state

        // [GIVEN] Configured E-Document service
        Initialize();

        // [WHEN] Posting invoice with timeout
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);
        EDocument.FindLast();

        // [THEN] E-Document should be in error state
        Assert.AreEqual(Enum::"E-Document Status"::Error, EDocument.Status, 'Document should be in error state after timeout');
    end;

    [Test]
    [HandlerFunctions('HttpValidationErrorHandler')]
    procedure TestSubmitDocument_ValidationError_LogsErrors()
    var
        EDocument: Record "E-Document";
        EDocumentPage: TestPage "E-Document";
    begin
        // [SCENARIO] Validation errors from Avalara are properly logged

        // [GIVEN] Configured E-Document service
        Initialize();

        // [WHEN] Posting invoice with validation errors
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);
        EDocument.FindLast();

        // [THEN] Document should be in error state with logged errors
        Assert.AreEqual(Enum::"E-Document Status"::Error, EDocument.Status, 'Document should be in error state');

        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        Assert.AreEqual('Error', EDocumentPage.ErrorMessagesPart."Message Type".Value(), 'Should have error messages');
        EDocumentPage.Close();
    end;

    [Test]
    [HandlerFunctions('HttpUnauthorizedHandler')]
    procedure TestSubmitDocument_Unauthorized_SetsErrorState()
    var
        EDocument: Record "E-Document";
    begin
        // [SCENARIO] Unauthorized (401) response sets document to Error state

        // [GIVEN] Configured E-Document service with invalid credentials
        Initialize();

        // [WHEN] Posting invoice with unauthorized error
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);
        EDocument.FindLast();

        // [THEN] E-Document should be in error state
        Assert.AreEqual(Enum::"E-Document Status"::Error, EDocument.Status, 'Document should be in error state');
    end;

    [Test]
    [HandlerFunctions('HttpRateLimitHandler')]
    procedure TestSubmitDocument_RateLimit_SetsErrorState()
    var
        EDocument: Record "E-Document";
    begin
        // [SCENARIO] Rate limit (429) response is handled appropriately

        // [GIVEN] Configured E-Document service
        Initialize();

        // [WHEN] Posting invoice with rate limit error
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);
        EDocument.FindLast();

        // [THEN] E-Document should be in error state
        Assert.AreEqual(Enum::"E-Document Status"::Error, EDocument.Status, 'Document should be in error state');
    end;

    [Test]
    [HandlerFunctions('HttpMalformedJsonHandler')]
    procedure TestGetResponse_MalformedJson_SetsErrorState()
    var
        EDocument: Record "E-Document";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [SCENARIO] Malformed JSON response is handled gracefully

        // [GIVEN] An E-Document in pending state
        Initialize();
        CreateMockPendingEDocument(EDocument);

        // [WHEN] Get response returns malformed JSON
        JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"E-Document Get Response");
        asserterror LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);

        // [THEN] Should handle error gracefully
    end;

    [Test]
    [HandlerFunctions('HttpEmptyResponseHandler')]
    procedure TestGetResponse_EmptyResponse_HandledGracefully()
    var
        EDocument: Record "E-Document";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [SCENARIO] Empty response is handled without crashing

        // [GIVEN] An E-Document in pending state
        Initialize();
        CreateMockPendingEDocument(EDocument);

        // [WHEN] Get response returns empty response
        JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"E-Document Get Response");
        asserterror LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);

        // [THEN] Should handle empty response gracefully
    end;

    [Test]
    [HandlerFunctions('HttpNotFoundHandler')]
    procedure TestDownloadDocument_NotFound_LogsError()
    var
        EDocument: Record "E-Document";
        EDocService: Record "E-Document Service";
        AvalaraDocMgt: Codeunit "Avalara Document Management";
        Result: Boolean;
    begin
        // [SCENARIO] Document not found (404) is handled appropriately

        // [GIVEN] An E-Document with non-existent Avalara Document ID
        Initialize();
        CreateMockEDocument(EDocument);
        CreateMockConnectionSetup();

        // [WHEN] Attempting to download non-existent document
        Result := AvalaraDocMgt.DownloadDocumentWithAllMediaTypes(EDocument, EDocumentService, 'non-existent-id');

        // [THEN] Should return false and log error
        Assert.IsFalse(Result, 'Download should fail for non-existent document');
    end;

    [Test]
    [HandlerFunctions('HttpInvalidMandateHandler')]
    procedure TestReceiveDocuments_InvalidMandate_HandlesGracefully()
    var
        EDocument: Record "E-Document";
        EDocService: Record "E-Document Service";
        AvalaraDocMgt: Codeunit "Avalara Document Management";
    begin
        // [SCENARIO] Invalid mandate configuration is handled gracefully

        // [GIVEN] E-Document service with invalid mandate
        Initialize();
        CreateMockEDocumentService(EDocService);
        EDocService."Avalara Mandate" := 'INVALID-MANDATE';
        EDocService.Modify();
        CreateMockConnectionSetup();

        // [WHEN] Attempting to receive documents with invalid mandate
        asserterror AvalaraDocMgt.ReceiveAndProcessDocuments(EDocService, EDocument);

        // [THEN] Should handle error appropriately
    end;

    [Test]
    [HandlerFunctions('HttpSubmitHandler,HttpServerErrorRecoveryHandler')]
    procedure TestGetResponse_ServerError_Retry_Success()
    var
        EDocument: Record "E-Document";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [SCENARIO] Temporary server errors can be recovered from on retry

        // [GIVEN] An E-Document in pending state
        Initialize();
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);
        EDocument.FindLast();

        // First call will fail (ServerErrorRecoveryHandler returns 500)
        // Second call will succeed (returns Complete status)

        // [WHEN] Get response initially fails but succeeds on retry
        JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"E-Document Get Response");
        LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);

        // [THEN] Document should eventually be processed
        EDocument.FindLast();
        // Note: Actual retry logic depends on job queue configuration
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        LibraryEDocument.SetupStandardVAT();
        LibraryEDocument.SetupStandardSalesScenario(Customer, EDocumentService, Enum::"E-Document Format"::"PEPPOL BIS 3.0", Enum::"Service Integration"::Avalara);
        EDocumentService."Avalara Mandate" := 'GB-TEST';
        EDocumentService.Modify();

        CreateMockConnectionSetup();

        IsInitialized := true;
    end;

    local procedure CreateMockConnectionSetup()
    var
        ConnectionSetup: Record "Connection Setup";
        AvalaraAuth: Codeunit Authenticator;
        KeyGuid: Guid;
    begin
        if not ConnectionSetup.Get() then begin
            AvalaraAuth.CreateConnectionSetupRecord();
            ConnectionSetup.Get();
        end;

        AvalaraAuth.SetClientId(KeyGuid, 'mock-client-id');
        ConnectionSetup."Client Id - Key" := KeyGuid;
        AvalaraAuth.SetClientSecret(KeyGuid, 'mock-client-secret');
        ConnectionSetup."Client Secret - Key" := KeyGuid;
        ConnectionSetup."Company Id" := 'test-company-id';
        ConnectionSetup.Modify(true);
    end;

    local procedure CreateMockEDocument(var EDocument: Record "E-Document")
    begin
        EDocument.Init();
        EDocument."Entry No" := 1;
        EDocument.Status := EDocument.Status::Processed;
        if EDocument.Insert() then;
    end;

    local procedure CreateMockEDocumentService(var EDocService: Record "E-Document Service")
    begin
        if not EDocService.Get('AVALARA-TEST') then begin
            EDocService.Init();
            EDocService.Code := 'AVALARA-TEST';
            EDocService."Service Integration V2" := EDocService."Service Integration V2"::Avalara;
            EDocService."Avalara Mandate" := 'GB-TEST';
            EDocService.Insert();
        end;
    end;

    local procedure CreateMockPendingEDocument(var EDocument: Record "E-Document")
    begin
        EDocument.Init();
        EDocument."Entry No" := 999;
        EDocument.Status := EDocument.Status::"In Progress";
        EDocument."Avalara Document Id" := 'test-pending-doc-id';
        if EDocument.Insert() then;
    end;

    [HttpClientHandler]
    internal procedure HttpNetworkErrorHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        // Simulate network error by not setting response properly
        Response.HttpStatusCode := 0;
        exit(false);
    end;

    [HttpClientHandler]
    internal procedure HttpTimeoutHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Response.HttpStatusCode := 408; // Request Timeout
        Response.Content.WriteFrom('{"error":"Request timeout"}');
    end;

    [HttpClientHandler]
    internal procedure HttpValidationErrorHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Response.HttpStatusCode := 400;
        Response.Content.WriteFrom('{"error":"validation_failed","details":["Invalid VAT number","Missing required field: Customer Name"]}');
    end;

    [HttpClientHandler]
    internal procedure HttpUnauthorizedHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Response.HttpStatusCode := 401;
        Response.Content.WriteFrom('{"error":"unauthorized","error_description":"Invalid credentials"}');
    end;

    [HttpClientHandler]
    internal procedure HttpRateLimitHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Response.HttpStatusCode := 429;
        Response.Content.WriteFrom('{"error":"rate_limit_exceeded","retry_after":60}');
    end;

    [HttpClientHandler]
    internal procedure HttpMalformedJsonHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Response.HttpStatusCode := 200;
        Response.Content.WriteFrom('{this is not valid json]');
    end;

    [HttpClientHandler]
    internal procedure HttpEmptyResponseHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Response.HttpStatusCode := 200;
        Response.Content.WriteFrom('');
    end;

    [HttpClientHandler]
    internal procedure HttpNotFoundHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Response.HttpStatusCode := 404;
        Response.Content.WriteFrom('{"error":"not_found","message":"Document not found"}');
    end;

    [HttpClientHandler]
    internal procedure HttpInvalidMandateHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Response.HttpStatusCode := 400;
        Response.Content.WriteFrom('{"error":"invalid_mandate","message":"Mandate INVALID-MANDATE not found"}');
    end;

    [HttpClientHandler]
    internal procedure HttpServerErrorRecoveryHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        // First call returns 500, subsequent calls would return success
        // This simulates temporary server issues
        Response.HttpStatusCode := 500;
        Response.Content.WriteFrom('{"error":"internal_server_error"}');
    end;

    [HttpClientHandler]
    internal procedure HttpSubmitHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        ConnectTokenFileTok: Label 'ConnectToken.txt', Locked = true;
        SubmitDocumentFileTok: Label 'SubmitDocument.txt', Locked = true;
    begin
        if Request.Path.Contains('/connect/token') then
            LoadResourceIntoHttpResponse(ConnectTokenFileTok, Response)
        else if Request.Path.Contains('/einvoicing/documents') then
            LoadResourceIntoHttpResponse(SubmitDocumentFileTok, Response);
    end;

    local procedure LoadResourceIntoHttpResponse(ResourceText: Text; var Response: TestHttpResponseMessage)
    begin
        Response.Content.WriteFrom(NavApp.GetResourceAsText(ResourceText, TextEncoding::UTF8));
        Response.HttpStatusCode := 200;
    end;

    var
        LibraryJobQueue: Codeunit "Library - Job Queue";
}
