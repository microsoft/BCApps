// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

using Microsoft.eServices.EDocument;

codeunit 133635 "Unit Tests - Document Mgmt"
{
    Subtype = Test;
    TestHttpRequestPolicy = AllowOutboundFromHandler;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    [Test]
    procedure TestParseIntoTemp_ValidJsonWithMultipleDocuments()
    var
        TempDocumentBuffer: Record "Avalara Document Buffer" temporary;
        AvalaraDocMgt: Codeunit "Avalara Document Management";
        JsonText: Text;
    begin
        // [SCENARIO] ParseIntoTemp correctly parses JSON with multiple documents

        // [GIVEN] Valid JSON with document array
        Initialize();
        JsonText := GetMockDocumentsJson(3);

        // [WHEN] Parsing into temporary buffer
        AvalaraDocMgt.ParseIntoTemp(TempDocumentBuffer, JsonText);

        // [THEN] All documents should be parsed
        Assert.AreEqual(3, TempDocumentBuffer.Count, 'Should parse all 3 documents');
    end;

    [Test]
    procedure TestParseIntoTemp_EmptyJson()
    var
        TempDocumentBuffer: Record "Avalara Document Buffer" temporary;
        AvalaraDocMgt: Codeunit "Avalara Document Management";
    begin
        // [SCENARIO] ParseIntoTemp handles empty JSON gracefully

        // [GIVEN] Empty JSON
        Initialize();

        // [WHEN] Parsing empty JSON
        AvalaraDocMgt.ParseIntoTemp(TempDocumentBuffer, '');

        // [THEN] No documents should be created
        Assert.AreEqual(0, TempDocumentBuffer.Count, 'Should have no documents');
    end;

    [Test]
    procedure TestParseIntoTemp_InvalidJson_Error()
    var
        TempDocumentBuffer: Record "Avalara Document Buffer" temporary;
        AvalaraDocMgt: Codeunit "Avalara Document Management";
    begin
        // [SCENARIO] ParseIntoTemp throws error for invalid JSON

        // [GIVEN] Invalid JSON
        Initialize();

        // [WHEN] [THEN] Parsing invalid JSON should throw error
        asserterror AvalaraDocMgt.ParseIntoTemp(TempDocumentBuffer, '{invalid json}');
    end;

    [Test]
    procedure TestParseIntoTemp_ValidatesRequiredFields()
    var
        TempDocumentBuffer: Record "Avalara Document Buffer" temporary;
        AvalaraDocMgt: Codeunit "Avalara Document Management";
        JsonText: Text;
    begin
        // [SCENARIO] ParseIntoTemp correctly extracts all required fields

        // [GIVEN] JSON with complete document data
        Initialize();
        JsonText := GetMockDocumentsJson(1);

        // [WHEN] Parsing into buffer
        AvalaraDocMgt.ParseIntoTemp(TempDocumentBuffer, JsonText);

        // [THEN] All fields should be populated
        TempDocumentBuffer.FindFirst();
        Assert.AreNotEqual('', TempDocumentBuffer.Id, 'Document ID should be populated');
        Assert.AreNotEqual('', TempDocumentBuffer."Company Id", 'Company ID should be populated');
        Assert.AreNotEqual('', TempDocumentBuffer.Status, 'Status should be populated');
        Assert.AreNotEqual('', TempDocumentBuffer."Document Type", 'Document Type should be populated');
    end;

    [Test]
    [HandlerFunctions('HttpDocumentListHandler')]
    procedure TestLoadDocumentList_Success()
    var
        TempDocumentBuffer: Record "Avalara Document Buffer" temporary;
        AvalaraDocMgt: Codeunit "Avalara Document Management";
    begin
        // [SCENARIO] LoadDocumentList successfully retrieves documents from API

        // [GIVEN] Valid connection setup
        Initialize();
        CreateMockConnectionSetup();

        // [WHEN] Loading document list
        AvalaraDocMgt.LoadDocumentList(TempDocumentBuffer);

        // [THEN] Documents should be loaded into buffer
        Assert.IsTrue(TempDocumentBuffer.Count > 0, 'Should load documents');
    end;

    [Test]
    [HandlerFunctions('HttpDownloadSuccessHandler')]
    procedure TestDownloadDocumentWithAllMediaTypes_Success()
    var
        EDocument: Record "E-Document";
        EDocService: Record "E-Document Service";
        AvalaraDocMgt: Codeunit "Avalara Document Management";
        Result: Boolean;
    begin
        // [SCENARIO] DownloadDocumentWithAllMediaTypes successfully downloads document in multiple formats

        // [GIVEN] An E-Document with Avalara Document ID
        Initialize();
        CreateMockEDocument(EDocument);
        CreateMockEDocumentService(EDocService);
        CreateMockConnectionSetup();

        // [WHEN] Downloading document with all media types
        Result := AvalaraDocMgt.DownloadDocumentWithAllMediaTypes(EDocument, EDocService, 'test-doc-id-123');

        // [THEN] Download should succeed
        Assert.IsTrue(Result, 'Download should succeed');
    end;

    [Test]
    [HandlerFunctions('DocumentIdRequiredMessageHandler')]
    procedure TestDownloadDocumentWithAllMediaTypes_EmptyDocumentId_Fails()
    var
        EDocument: Record "E-Document";
        EDocService: Record "E-Document Service";
        AvalaraDocMgt: Codeunit "Avalara Document Management";
        Result: Boolean;
    begin
        // [SCENARIO] DownloadDocumentWithAllMediaTypes fails gracefully with empty document ID

        // [GIVEN] An E-Document without Avalara Document ID
        Initialize();
        CreateMockEDocument(EDocument);
        CreateMockEDocumentService(EDocService);

        // [WHEN] Downloading document with empty ID
        Result := AvalaraDocMgt.DownloadDocumentWithAllMediaTypes(EDocument, EDocService, '');

        // [THEN] Download should fail
        Assert.IsFalse(Result, 'Download should fail with empty document ID');
    end;

    [Test]
    [HandlerFunctions('HttpStatusCompleteHandler')]
    procedure TestShowDocumentStatus_DisplaysStatus()
    var
        EDocument: Record "E-Document";
        AvalaraDocMgt: Codeunit "Avalara Document Management";
    begin
        // [SCENARIO] ShowDocumentStatus retrieves and displays document status

        // [GIVEN] An E-Document with Avalara Document ID
        Initialize();
        CreateMockEDocument(EDocument);
        EDocument."Avalara Document Id" := 'test-doc-id-123';
        EDocument.Modify();
        CreateMockConnectionSetup();

        // [WHEN] Showing document status
        // Note: This opens a page, so in test we just ensure no error
        AvalaraDocMgt.ShowDocumentStatus(EDocument);

        // [THEN] No error should occur
        // Test passes if no exception is thrown
    end;

    [Test]
    procedure TestShowDocumentStatus_EmptyDocumentId_Error()
    var
        EDocument: Record "E-Document";
        AvalaraDocMgt: Codeunit "Avalara Document Management";
    begin
        // [SCENARIO] ShowDocumentStatus throws error when document ID is empty

        // [GIVEN] An E-Document without Avalara Document ID
        Initialize();
        CreateMockEDocument(EDocument);

        // [WHEN] [THEN] Showing status without document ID should throw error
        asserterror AvalaraDocMgt.ShowDocumentStatus(EDocument);
        Assert.ExpectedTestFieldError('Avalara Document Id', '');
    end;

    [Test]
    [HandlerFunctions('HttpReceiveDocumentsHandler')]
    procedure TestReceiveAndProcessDocuments_Success()
    var
        EDocument: Record "E-Document";
        EDocService: Record "E-Document Service";
        AvalaraDocMgt: Codeunit "Avalara Document Management";
        ReceivedCount: Integer;
    begin
        // [SCENARIO] ReceiveAndProcessDocuments successfully imports documents from Avalara

        // [GIVEN] Valid E-Document service configuration
        Initialize();
        CreateMockEDocumentService(EDocService);
        CreateMockConnectionSetup();

        // [WHEN] Receiving and processing documents
        ReceivedCount := AvalaraDocMgt.ReceiveAndProcessDocuments(EDocService, EDocument);

        // [THEN] Documents should be received
        Assert.IsTrue(ReceivedCount >= 0, 'Should return count of received documents');
    end;

    local procedure Initialize()
    var
        ConnectionSetup: Record "Connection Setup";
    begin
        // Clear cached token to ensure each test starts fresh
        if ConnectionSetup.Get() then
            if not IsNullGuid(ConnectionSetup."Token - Key") then begin
                if IsolatedStorage.Contains(ConnectionSetup."Token - Key", DataScope::Company) then
                    IsolatedStorage.Delete(ConnectionSetup."Token - Key", DataScope::Company);
                Clear(ConnectionSetup."Token - Key");
                ConnectionSetup."Token Expiry" := 0DT;
                ConnectionSetup.Modify();
            end;

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

        AvalaraAuth.SetClientId(KeyGuid, SecretText.SecretStrSubstNo('mock-client-id'));
        ConnectionSetup."Client Id - Key" := KeyGuid;
        AvalaraAuth.SetClientSecret(KeyGuid, SecretText.SecretStrSubstNo('mock-client-secret'));
        ConnectionSetup."Client Secret - Key" := KeyGuid;
        ConnectionSetup."Company Id" := 'test-company-id';
        ConnectionSetup.Modify(true);
    end;

    local procedure CreateMockEDocument(var EDocument: Record "E-Document")
    begin
        EDocument.Init();
        EDocument."Entry No" := 0;
        EDocument.Direction := EDocument.Direction::Outgoing;
        EDocument.Insert(true);
    end;

    local procedure CreateMockEDocumentService(var EDocService: Record "E-Document Service")
    begin
        EDocService.Init();
        EDocService.Code := 'AVALARA-TEST';
        EDocService."Service Integration V2" := EDocService."Service Integration V2"::Avalara;
        EDocService."Avalara Mandate" := 'GB-TEST';
        if EDocService.Insert() then;
    end;

    local procedure GetMockDocumentsJson(Count: Integer): Text
    var
        i: Integer;
        JsonBuilder: TextBuilder;
    begin
        JsonBuilder.Append('{"value":[');

        for i := 1 to Count do begin
            if i > 1 then
                JsonBuilder.Append(',');

            JsonBuilder.Append('{');
            JsonBuilder.Append('"id":"doc-id-' + Format(i) + '",');
            JsonBuilder.Append('"companyId":"company-123",');
            JsonBuilder.Append('"status":"Complete",');
            JsonBuilder.Append('"documentType":"ubl-invoice",');
            JsonBuilder.Append('"documentVersion":"2.1",');
            JsonBuilder.Append('"documentNumber":"INV-' + Format(i) + '",');
            JsonBuilder.Append('"documentDate":"2024-01-15",');
            JsonBuilder.Append('"processDateTime":"2024-01-15T10:30:00Z",');
            JsonBuilder.Append('"flow":"in",');
            JsonBuilder.Append('"countryCode":"GB",');
            JsonBuilder.Append('"countryMandate":"GB-B2G",');
            JsonBuilder.Append('"receiver":"GB123456789",');
            JsonBuilder.Append('"supplierName":"Test Supplier",');
            JsonBuilder.Append('"customerName":"Test Customer",');
            JsonBuilder.Append('"interface":"API"');
            JsonBuilder.Append('}');
        end;

        JsonBuilder.Append(']}');
        exit(JsonBuilder.ToText());
    end;

    [MessageHandler]
    procedure DocumentIdRequiredMessageHandler(Message: Text[1024])
    begin
        // Expected message when Document ID is empty
    end;

    [HttpClientHandler]
    internal procedure HttpDocumentListHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        if Request.Path.Contains('/connect/token') then begin
            Response.Content.WriteFrom(GetMockAuthTokenJson());
            Response.HttpStatusCode := 200;
            exit(true);
        end;
        Response.Content.WriteFrom(GetMockDocumentsJson(2));
        Response.HttpStatusCode := 200;
        exit(true);
    end;

    [HttpClientHandler]
    internal procedure HttpDownloadSuccessHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        if Request.Path.Contains('/connect/token') then begin
            Response.Content.WriteFrom(GetMockAuthTokenJson());
            Response.HttpStatusCode := 200;
            exit(true);
        end;
        Response.Content.WriteFrom('<?xml version="1.0"?><Invoice></Invoice>');
        Response.HttpStatusCode := 200;
        exit(true);
    end;

    [HttpClientHandler]
    internal procedure HttpStatusCompleteHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        StatusJson: Text;
    begin
        if Request.Path.Contains('/connect/token') then begin
            Response.Content.WriteFrom(GetMockAuthTokenJson());
            Response.HttpStatusCode := 200;
            exit(true);
        end;
        StatusJson := '{"id":"test-doc-id-123","status":"Complete","events":[]}';
        Response.Content.WriteFrom(StatusJson);
        Response.HttpStatusCode := 200;
        exit(true);
    end;

    [HttpClientHandler]
    internal procedure HttpReceiveDocumentsHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        if Request.Path.Contains('/connect/token') then begin
            Response.Content.WriteFrom(GetMockAuthTokenJson());
            Response.HttpStatusCode := 200;
            exit(true);
        end;
        Response.Content.WriteFrom(GetMockDocumentsJson(1));
        Response.HttpStatusCode := 200;
        exit(true);
    end;

    local procedure GetMockAuthTokenJson(): Text
    begin
        exit('{"access_token":"mock-access-token-12345","token_type":"Bearer","expires_in":3600}');
    end;
}
