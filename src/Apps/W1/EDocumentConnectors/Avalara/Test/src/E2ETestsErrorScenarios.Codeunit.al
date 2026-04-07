// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.NoSeries;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Setup;

codeunit 133625 "E2E Tests - Error Scenarios"
{
    EventSubscriberInstance = Manual;
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
    [HandlerFunctions('HttpNotFoundHandler')]
    procedure TestDownloadDocument_NotFound_LogsError()
    var
        EDocument: Record "E-Document";
        AvalaraDocMgt: Codeunit "Avalara Document Management";
    begin
        // [SCENARIO] Document not found (404) is handled appropriately

        // [GIVEN] An E-Document with non-existent Avalara Document ID
        Initialize();
        CreateMockEDocument(EDocument);
        CreateMockConnectionSetup();

        // [WHEN] Attempting to download non-existent document
        asserterror AvalaraDocMgt.DownloadDocumentWithAllMediaTypes(EDocument, EDocumentService, 'non-existent-id');

        // [THEN] Should fail with appropriate error
        Assert.ExpectedError('404');
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

    local procedure Initialize()
    var
        CompanyInformation: Record "Company Information";
        ConnectionSetup: Record "Connection Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
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

        CompanyInformation.Get();
        if CompanyInformation.Name = '' then begin
            CompanyInformation.Name := 'Test Company';
            CompanyInformation.Modify();
        end;

        // Ensure LCY Code is set
        GeneralLedgerSetup.Get();
        if GeneralLedgerSetup."LCY Code" = '' then begin
            GeneralLedgerSetup."LCY Code" := 'GBP';
            GeneralLedgerSetup.Modify();
        end;

        // Disable VAT Reporting Date to avoid VAT Period requirement
        if GeneralLedgerSetup."VAT Reporting Date Usage" <> Enum::"VAT Reporting Date Usage"::Disabled then begin
            GeneralLedgerSetup."VAT Reporting Date Usage" := Enum::"VAT Reporting Date Usage"::Disabled;
            GeneralLedgerSetup.Modify();
        end;

        // Ensure Sales & Receivables Setup has Invoice Nos.
        EnsureSalesSetup();

        // Verify Customer still exists (may have been rolled back between tests)
        if IsInitialized then
            if not Customer.Get(Customer."No.") then
                IsInitialized := false;

        if IsInitialized then
            exit;

        BindSubscription(this);
        EnsureVATBusinessPostingGroup();
        LibraryEDocument.SetupStandardVAT();
        LibraryEDocument.SetupStandardSalesScenario(Customer, EDocumentService, Enum::"E-Document Format"::"PEPPOL BIS 3.0", Enum::"Service Integration"::Avalara);
        EDocumentService."Avalara Mandate" := 'GB-TEST';
        EDocumentService.Modify();

        CreateMockConnectionSetup();
        CreateActivationMandate();

        IsInitialized := true;
    end;

    local procedure CreateActivationMandate()
    var
        ActivationMandate: Record "Activation Mandate";
    begin
        ActivationMandate.Init();
        ActivationMandate."Activation ID" := CreateGuid();
        ActivationMandate."Country Mandate" := 'GB-TEST';
        ActivationMandate."Country Code" := 'GB';
        ActivationMandate."Mandate Type" := '';
        ActivationMandate."Company Id" := 'test-company-id';
        ActivationMandate.Activated := true;
        ActivationMandate.Blocked := false;
        if not ActivationMandate.Insert() then
            ActivationMandate.Modify();
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
        EDocument.Insert(true);
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

    [HttpClientHandler]
    internal procedure HttpNetworkErrorHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        if Request.Path.Contains('/connect/token') then begin
            Response.Content.WriteFrom(GetMockAuthTokenJson());
            Response.HttpStatusCode := 200;
            exit(true);
        end;
        // Simulate network error by not setting response properly
        exit(false);
    end;

    [HttpClientHandler]
    internal procedure HttpTimeoutHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        if Request.Path.Contains('/connect/token') then begin
            Response.Content.WriteFrom(GetMockAuthTokenJson());
            Response.HttpStatusCode := 200;
            exit(true);
        end;
        Response.HttpStatusCode := 408; // Request Timeout
        Response.Content.WriteFrom('{"error":"Request timeout"}');
        exit(true);
    end;

    [HttpClientHandler]
    internal procedure HttpValidationErrorHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        if Request.Path.Contains('/connect/token') then begin
            Response.Content.WriteFrom(GetMockAuthTokenJson());
            Response.HttpStatusCode := 200;
            exit(true);
        end;
        Response.HttpStatusCode := 400;
        Response.Content.WriteFrom('{"error":"validation_failed","details":["Invalid VAT number","Missing required field: Customer Name"]}');
        exit(true);
    end;

    [HttpClientHandler]
    internal procedure HttpUnauthorizedHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        if Request.Path.Contains('/connect/token') then begin
            Response.Content.WriteFrom(GetMockAuthTokenJson());
            Response.HttpStatusCode := 200;
            exit(true);
        end;
        Response.HttpStatusCode := 401;
        Response.Content.WriteFrom('{"error":"unauthorized","error_description":"Invalid credentials"}');
        exit(true);
    end;

    [HttpClientHandler]
    internal procedure HttpRateLimitHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        if Request.Path.Contains('/connect/token') then begin
            Response.Content.WriteFrom(GetMockAuthTokenJson());
            Response.HttpStatusCode := 200;
            exit(true);
        end;
        Response.HttpStatusCode := 429;
        Response.Content.WriteFrom('{"error":"rate_limit_exceeded","retry_after":60}');
        exit(true);
    end;

    [HttpClientHandler]
    internal procedure HttpMalformedJsonHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Response.HttpStatusCode := 200;
        Response.Content.WriteFrom('{this is not valid json]');
        exit(true);
    end;

    [HttpClientHandler]
    internal procedure HttpEmptyResponseHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Response.HttpStatusCode := 200;
        Response.Content.WriteFrom('');
        exit(true);
    end;

    [HttpClientHandler]
    internal procedure HttpNotFoundHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        if Request.Path.Contains('/connect/token') then begin
            Response.Content.WriteFrom(GetMockAuthTokenJson());
            Response.HttpStatusCode := 200;
            exit(true);
        end;
        Response.HttpStatusCode := 404;
        Response.Content.WriteFrom('{"error":"not_found","message":"Document not found"}');
        exit(true);
    end;

    [HttpClientHandler]
    internal procedure HttpInvalidMandateHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        if Request.Path.Contains('/connect/token') then begin
            Response.Content.WriteFrom(GetMockAuthTokenJson());
            Response.HttpStatusCode := 200;
            exit(true);
        end;
        Response.HttpStatusCode := 400;
        Response.Content.WriteFrom('{"error":"invalid_mandate","message":"Mandate INVALID-MANDATE not found"}');
        exit(true);
    end;

    [HttpClientHandler]
    internal procedure HttpServerErrorRecoveryHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        if Request.Path.Contains('/connect/token') then begin
            Response.Content.WriteFrom(GetMockAuthTokenJson());
            Response.HttpStatusCode := 200;
            exit(true);
        end;
        // First call returns 500, subsequent calls would return success
        // This simulates temporary server issues
        Response.HttpStatusCode := 500;
        Response.Content.WriteFrom('{"error":"internal_server_error"}');
        exit(true);
    end;

    [HttpClientHandler]
    internal procedure HttpSubmitHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        ConnectTokenFileTok: Label 'ConnectToken.txt', Locked = true;
        SubmitDocumentFileTok: Label 'SubmitDocument.txt', Locked = true;
    begin
        if Request.Path.Contains('/connect/token') then begin
            LoadResourceIntoHttpResponse(ConnectTokenFileTok, Response);
            Response.HttpStatusCode := 200;
        end else
            if Request.Path.Contains('/einvoicing/documents') then begin
                LoadResourceIntoHttpResponse(SubmitDocumentFileTok, Response);
                Response.HttpStatusCode := 200;
            end;
        exit(true);
    end;

    local procedure LoadResourceIntoHttpResponse(ResourceText: Text; var Response: TestHttpResponseMessage)
    begin
        Response.Content.WriteFrom(NavApp.GetResourceAsText(ResourceText, TextEncoding::UTF8));
        Response.HttpStatusCode := 200;
    end;

    local procedure EnsureSalesSetup()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        if not SalesSetup.Get() then
            SalesSetup.Insert(true);
        if SalesSetup."Invoice Nos." = '' then begin
            SalesSetup."Invoice Nos." := CreateTestNoSeries('SINV', 'SI00001', 'SI99999');
            SalesSetup.Modify(true);
        end;
        if SalesSetup."Posted Invoice Nos." = '' then begin
            SalesSetup."Posted Invoice Nos." := CreateTestNoSeries('PSINV', 'PSI0001', 'PSI9999');
            SalesSetup.Modify(true);
        end;
    end;

    local procedure CreateTestNoSeries(SeriesCode: Code[20]; StartNo: Code[20]; EndNo: Code[20]): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        if NoSeries.Get(SeriesCode) then
            exit(SeriesCode);

        NoSeries.Init();
        NoSeries.Code := SeriesCode;
        NoSeries.Description := SeriesCode;
        NoSeries."Default Nos." := true;
        NoSeries."Manual Nos." := true;
        NoSeries.Insert();

        NoSeriesLine.Init();
        NoSeriesLine."Series Code" := SeriesCode;
        NoSeriesLine."Line No." := 10000;
        NoSeriesLine."Starting No." := StartNo;
        NoSeriesLine."Ending No." := EndNo;
        NoSeriesLine."Increment-by No." := 1;
        NoSeriesLine.Insert();

        exit(SeriesCode);
    end;

    local procedure EnsureVATBusinessPostingGroup()
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        if not VATBusinessPostingGroup.IsEmpty() then
            exit;

        VATBusinessPostingGroup.Init();
        VATBusinessPostingGroup.Code := 'DOMESTIC';
        VATBusinessPostingGroup.Description := 'Domestic';
        VATBusinessPostingGroup.Insert(false);

        if VATProductPostingGroup.IsEmpty() then begin
            VATProductPostingGroup.Init();
            VATProductPostingGroup.Code := 'STANDARD';
            VATProductPostingGroup.Description := 'Standard';
            VATProductPostingGroup.Insert(false);
        end else
            VATProductPostingGroup.FindFirst();

        if not VATPostingSetup.Get('DOMESTIC', VATProductPostingGroup.Code) then begin
            VATPostingSetup.Init();
            VATPostingSetup."VAT Bus. Posting Group" := 'DOMESTIC';
            VATPostingSetup."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
            VATPostingSetup."VAT %" := 0;
            VATPostingSetup.Insert(false);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::Customer, OnBeforeInsertEvent, '', false, false)]
    local procedure OnBeforeCustomerInsert(var Rec: Record Customer; RunTrigger: Boolean)
    var
        VATBusPostingGroup: Record "VAT Business Posting Group";
    begin
        if Rec."VAT Bus. Posting Group" <> '' then
            if not VATBusPostingGroup.Get(Rec."VAT Bus. Posting Group") then begin
                VATBusPostingGroup.Init();
                VATBusPostingGroup.Code := Rec."VAT Bus. Posting Group";
                VATBusPostingGroup.Description := Rec."VAT Bus. Posting Group";
                VATBusPostingGroup.Insert(false);
            end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Country/Region", OnBeforeInsertEvent, '', false, false)]
    local procedure OnBeforeCountryRegionInsert(var Rec: Record "Country/Region"; RunTrigger: Boolean)
    begin
        if Rec."ISO Code" = '' then
            Rec."ISO Code" := CopyStr(Rec.Code, 1, 2);
        if Rec."ISO Numeric Code" = '' then
            Rec."ISO Numeric Code" := '000';
    end;

    local procedure GetMockAuthTokenJson(): Text
    begin
        exit('{"access_token":"mock-access-token-12345","token_type":"Bearer","expires_in":3600}');
    end;

}
