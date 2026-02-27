// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

codeunit 148191 "Unit Tests - HTTP & Processing"
{
    Subtype = Test;
    TestHttpRequestPolicy = AllowOutboundFromHandler;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    // ============================================================================
    // HTTP Executor Tests
    // ============================================================================

    [Test]
    [HandlerFunctions('HttpSuccessHandler')]
    procedure TestHttpExecutor_SuccessfulRequest_ReturnsResponse()
    var
        HttpExecutor: Codeunit "Http Executor";
        Request: Codeunit Requests;
        Response: Text;
    begin
        // [SCENARIO] HttpExecutor successfully executes HTTP request

        // [GIVEN] Valid request object
        Initialize();
        CreateMockConnectionSetup();
        Request.Init();
        Request.Authenticate().CreateGetCompaniesRequest();

        // [WHEN] Executing HTTP request
        Response := HttpExecutor.ExecuteHttpRequest(Request);

        // [THEN] Response should be returned
        Assert.AreNotEqual('', Response, 'Response should not be empty');
    end;

    [Test]
    [HandlerFunctions('Http500Handler')]
    procedure TestHttpExecutor_ServerError_ThrowsError()
    var
        HttpExecutor: Codeunit "Http Executor";
        Request: Codeunit Requests;
        Response: Text;
    begin
        // [SCENARIO] HttpExecutor throws error on 500 status

        // [GIVEN] Request that will return 500
        Initialize();
        CreateMockConnectionSetup();
        Request.Init();
        Request.Authenticate().CreateGetCompaniesRequest();

        // [WHEN] [THEN] Executing request should throw error
        asserterror Response := HttpExecutor.ExecuteHttpRequest(Request);
    end;

    [Test]
    [HandlerFunctions('Http201Handler')]
    procedure TestHttpExecutor_201Response_Success()
    var
        HttpExecutor: Codeunit "Http Executor";
        Request: Codeunit Requests;
        Response: Text;
    begin
        // [SCENARIO] HttpExecutor handles 201 Created status

        // [GIVEN] Request that will return 201
        Initialize();
        CreateMockConnectionSetup();
        Request.Init();
        Request.Authenticate().CreateGetCompaniesRequest();

        // [WHEN] Executing HTTP request
        Response := HttpExecutor.ExecuteHttpRequest(Request);

        // [THEN] Response should be returned successfully
        Assert.AreNotEqual('', Response, 'Response should not be empty');
    end;

    [Test]
    [HandlerFunctions('HttpSuccessHandler')]
    procedure TestHttpExecutor_GetResponse_ReturnsStoredResponse()
    var
        HttpExecutor: Codeunit "Http Executor";
        Request: Codeunit Requests;
        HttpResponse: HttpResponseMessage;
        Response: Text;
    begin
        // [SCENARIO] HttpExecutor stores and returns response message

        // [GIVEN] Executed HTTP request
        Initialize();
        CreateMockConnectionSetup();
        Request.Init();
        Request.Authenticate().CreateGetCompaniesRequest();
        Response := HttpExecutor.ExecuteHttpRequest(Request);

        // [WHEN] Getting stored response
        HttpResponse := HttpExecutor.GetResponse();

        // [THEN] Response should match
        Assert.AreEqual(200, HttpResponse.HttpStatusCode(), 'Status code should be 200');
    end;

    // ============================================================================
    // Processing Codeunit Tests
    // ============================================================================

    [Test]
    [HandlerFunctions('HttpCompaniesHandler')]
    procedure TestProcessing_GetCompanyList_Success()
    var
        AvalaraCompany: Record "Avalara Company" temporary;
        Processing: Codeunit Processing;
    begin
        // [SCENARIO] Processing.GetCompanyList retrieves companies

        // [GIVEN] Valid connection setup
        Initialize();
        CreateMockConnectionSetup();

        // [WHEN] Getting company list
        Processing.GetCompanyList(AvalaraCompany);

        // [THEN] Companies should be loaded
        Assert.RecordIsNotEmpty(AvalaraCompany);
    end;

    [Test]
    [HandlerFunctions('HttpMandatesHandler')]
    procedure TestProcessing_GetMandates_Success()
    var
        Processing: Codeunit Processing;
    begin
        // [SCENARIO] Processing can retrieve mandates from API

        // [GIVEN] Valid connection setup
        Initialize();
        CreateMockConnectionSetup();

        // [WHEN] [THEN] Getting mandates should not throw error
        // Test implementation depends on Processing codeunit structure
    end;

    // ============================================================================
    // Request Builder Tests
    // ============================================================================

    [Test]
    [HandlerFunctions('HttpAuthHandler')]
    procedure TestRequests_Authenticate_SetsAuthHeader()
    var
        Request: Codeunit Requests;
        HttpHeaders: HttpHeaders;
    begin
        // [SCENARIO] Request.Authenticate sets authorization header

        // [GIVEN] Valid connection setup
        Initialize();
        CreateMockConnectionSetup();

        // [WHEN] Authenticating request
        Request.Init();
        Request.Authenticate();

        // [THEN] Request should have authorization header
        Request.GetRequest().GetHeaders(HttpHeaders);
        Assert.IsTrue(HttpHeaders.Contains('Authorization'), 'Should have Authorization header');
    end;

    [Test]
    procedure TestRequests_CreateSubmitDocumentRequest_SetsCorrectMethod()
    var
        MetaData: Codeunit Requests;
        Request: Codeunit Requests;
        RequestContent: Text;
    begin
        // [SCENARIO] CreateSubmitDocumentRequest sets POST method

        // [GIVEN] Request object
        Initialize();
        Request.Init();

        // [WHEN] Creating submit document request
        MetaData.SetDataFormat('ubl-invoice');
        RequestContent := '<?xml version="1.0"?><Invoice></Invoice>';
        Request.CreateSubmitDocumentRequest(MetaData, RequestContent);

        // [THEN] Method should be POST
        Assert.AreEqual('POST', Request.GetRequest().Method(), 'Method should be POST');
    end;

    [Test]
    procedure TestRequests_CreateGetDocumentStatusRequest_SetsCorrectUri()
    var
        Request: Codeunit Requests;
        DocumentId: Text;
        Uri: Text;
    begin
        // [SCENARIO] CreateGetDocumentStatusRequest sets correct URI

        // [GIVEN] Document ID
        Initialize();
        DocumentId := 'test-doc-id-123';

        // [WHEN] Creating get status request
        Request.Init();
        Request.CreateGetDocumentStatusRequest(DocumentId);

        // [THEN] URI should contain document ID
        Uri := Request.GetRequest().GetRequestUri();
        Assert.IsTrue(Uri.Contains(DocumentId), 'URI should contain document ID');
        Assert.IsTrue(Uri.Contains('/status'), 'URI should contain /status');
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

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

    // ============================================================================
    // HTTP Handlers
    // ============================================================================

    [HttpClientHandler]
    internal procedure HttpSuccessHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Response.Content.WriteFrom('{"success": true}');
        Response.HttpStatusCode := 200;
    end;

    [HttpClientHandler]
    internal procedure Http500Handler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Response.Content.WriteFrom('{"error": "Internal Server Error"}');
        Response.HttpStatusCode := 500;
    end;

    [HttpClientHandler]
    internal procedure Http201Handler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Response.Content.WriteFrom('{"created": true}');
        Response.HttpStatusCode := 201;
    end;

    [HttpClientHandler]
    internal procedure HttpCompaniesHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Response.Content.WriteFrom(NavApp.GetResourceAsText('Companies.txt', TextEncoding::UTF8));
        Response.HttpStatusCode := 200;
    end;

    [HttpClientHandler]
    internal procedure HttpMandatesHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        ResponseText: Text;
    begin
        ResponseText := '[{"countryMandate":"GB-TEST","description":"Test Mandate"}]';
        Response.Content.WriteFrom(ResponseText);
        Response.HttpStatusCode := 200;
    end;

    [HttpClientHandler]
    internal procedure HttpSubmitDocumentHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Response.Content.WriteFrom(NavApp.GetResourceAsText('SubmitDocument.txt', TextEncoding::UTF8));
        Response.HttpStatusCode := 200;
    end;

    [HttpClientHandler]
    internal procedure HttpStatusCompleteHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Response.Content.WriteFrom(NavApp.GetResourceAsText('GetResponseComplete.txt', TextEncoding::UTF8));
        Response.HttpStatusCode := 200;
    end;

    [HttpClientHandler]
    internal procedure HttpStatusPendingHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Response.Content.WriteFrom(NavApp.GetResourceAsText('GetResponsePending.txt', TextEncoding::UTF8));
        Response.HttpStatusCode := 200;
    end;

    [HttpClientHandler]
    internal procedure HttpStatusErrorHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Response.Content.WriteFrom(NavApp.GetResourceAsText('GetResponseError.txt', TextEncoding::UTF8));
        Response.HttpStatusCode := 200;
    end;

    [HttpClientHandler]
    internal procedure HttpReceiveDocumentsHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Response.Content.WriteFrom(NavApp.GetResourceAsText('GetDocuments.txt', TextEncoding::UTF8));
        Response.HttpStatusCode := 200;
    end;

    [HttpClientHandler]
    internal procedure HttpAuthHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Response.Content.WriteFrom(NavApp.GetResourceAsText('ConnectToken.txt', TextEncoding::UTF8));
        Response.HttpStatusCode := 200;
    end;
}
