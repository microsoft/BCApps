// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Pagero;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.eServices.EDocument.Service;
using Microsoft.EServices.EDocumentConnector;
using Microsoft.Finance.Currency;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Security.Authentication;
using System.Threading;

/// <summary>
/// Integration tests for the Pagero E-Document Connector. The tests cover the outbound document
/// lifecycle (send, get response with Processing/Error/Processed filepart transitions, restart after
/// a sending error, cancellation, and approval/rejection through application responses), the inbound
/// document flow (receive document list, download target document and create a purchase invoice)
/// and the connection setup card.
/// </summary>
codeunit 148192 "Integration Tests"
{
    TestHttpRequestPolicy = AllowOutboundFromHandler;
    Subtype = Test;
    TestType = IntegrationTest;
    Permissions = tabledata "E-Doc. Ext. Connection Setup" = rimd,
                    tabledata "E-Document" = r;

    #region Outbound tests

    [Test]
    [HandlerFunctions('HTTPSubmitHandler')]
    internal procedure SubmitDocument()
    var
        EDocument: Record "E-Document";
        EDocumentPage: TestPage "E-Document";
        EDocLogList: List of [Enum "E-Document Service Status"];
    begin
        // [SCENARIO] Document is submitted to Pagero and the filepart is processed on the first get response.
        // Pending response -> Sent
        Initialize();

        // [GIVEN] Team member
        LibraryPermission.SetTeamMember();

        // [WHEN] Posting invoice and EDocument is created
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);

        // [WHEN] EDocument is fetched after running Pagero SubmitDocument
        EDocument.FindLast();

        // [THEN] File Id has been correctly set on E-Document, parsed from Integration response.
        Assert.AreEqual(MockFileId(), EDocument."File Id", 'Pagero integration failed to set File Id on E-Document');
        Assert.AreEqual(Enum::"E-Document Status"::"In Progress", EDocument.Status, 'E-Document should be set to in progress');

        // [THEN] Open E-Document page
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        Assert.AreEqual(Format(EDocument.Direction::Outgoing), EDocumentPage.Direction.Value(), IncorrectValueErr);
        Assert.AreEqual(EDocument."Document No.", EDocumentPage."Document No.".Value(), IncorrectValueErr);

        // [THEN] E-Document Service Status has "Pending Response"
        VerifyOutboundFactboxValuesForSingleService(EDocument, Enum::"E-Document Service Status"::"Pending Response", 2);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        // [THEN] E-Document Errors and Warnings has correct status
        Assert.AreEqual('', EDocumentPage.ErrorMessagesPart."Message Type".Value(), IncorrectValueErr);
        Assert.AreEqual('', EDocumentPage.ErrorMessagesPart.Description.Value(), IncorrectValueErr);
        EDocumentPage.Close();

        // [WHEN] Executing Get Response succesfully
        RunGetResponseJob();

        // [WHEN] EDocument is fetched after running Pagero GetResponse
        EDocument.FindLast();

        // [THEN] E-Document is considered processed
        Assert.AreEqual(Enum::"E-Document Status"::Processed, EDocument.Status, 'E-Document should be set to processed');
        Assert.AreEqual(MockDocumentId(), EDocument."Document Id", 'Pagero integration failed to set Document Id on E-Document');

        // [THEN] Open E-Document page
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        Assert.AreEqual(Format(EDocument.Direction::Outgoing), EDocumentPage.Direction.Value(), IncorrectValueErr);
        Assert.AreEqual(EDocument."Document No.", EDocumentPage."Document No.".Value(), IncorrectValueErr);

        // [THEN] E-Document Service Status has Sent
        VerifyOutboundFactboxValuesForSingleService(EDocument, Enum::"E-Document Service Status"::Sent, 3);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Sent");
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        // [THEN] E-Document Errors and Warnings has correct status
        Assert.AreEqual('', EDocumentPage.ErrorMessagesPart."Message Type".Value(), IncorrectValueErr);
        Assert.AreEqual('', EDocumentPage.ErrorMessagesPart.Description.Value(), IncorrectValueErr);
        EDocumentPage.Close();
    end;

    [Test]
    [HandlerFunctions('HTTPSubmitHandler')]
    internal procedure SubmitDocumentPendingSent()
    var
        EDocument: Record "E-Document";
        EDocLogList: List of [Enum "E-Document Service Status"];
    begin
        // [SCENARIO] The filepart is still being processed by Pagero on the first get response, and processed on the second.
        // Pending response -> Pending response -> Sent
        Initialize();

        // [GIVEN] Team member posts an invoice that is submitted to Pagero
        LibraryPermission.SetTeamMember();
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);
        EDocument.FindLast();

        // [THEN] E-Document is pending response as Pagero is async
        Assert.AreEqual(Enum::"E-Document Status"::"In Progress", EDocument.Status, 'E-Document should be set to in progress');
        VerifyOutboundFactboxValuesForSingleService(EDocument, Enum::"E-Document Service Status"::"Pending Response", 2);

        // [WHEN] Pagero reports that the filepart is still being processed
        SetFilepartStatus(FilepartStatus::Processing);
        RunGetResponseJob();
        EDocument.FindLast();

        // [THEN] E-Document is still pending response and the filepart id is stored
        Assert.AreEqual(Enum::"E-Document Status"::"In Progress", EDocument.Status, 'E-Document should still be in progress');
        Assert.AreEqual(MockFilepartId(), EDocument."Filepart Id", 'Pagero integration failed to set Filepart Id on E-Document');
        VerifyOutboundFactboxValuesForSingleService(EDocument, Enum::"E-Document Service Status"::"Pending Response", 3);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        // [WHEN] Pagero has processed the filepart
        SetFilepartStatus(FilepartStatus::Processed);
        RunGetResponseJob();
        EDocument.FindLast();

        // [THEN] E-Document is considered processed
        Assert.AreEqual(Enum::"E-Document Status"::Processed, EDocument.Status, 'E-Document should be set to processed');
        Assert.AreEqual(MockDocumentId(), EDocument."Document Id", 'Pagero integration failed to set Document Id on E-Document');
        VerifyOutboundFactboxValuesForSingleService(EDocument, Enum::"E-Document Service Status"::Sent, 4);
    end;

    [Test]
    [HandlerFunctions('ServiceDownHandler')]
    internal procedure SubmitDocumentPageroServiceDown()
    var
        EDocument: Record "E-Document";
        EDocumentPage: TestPage "E-Document";
        EDocLogList: List of [Enum "E-Document Service Status"];
    begin
        // [SCENARIO] Pagero returns an internal server error when the document is submitted.
        Initialize();

        // [GIVEN] Team member posts an invoice
        LibraryPermission.SetTeamMember();
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);
        EDocument.FindLast();

        // [THEN] E-Document is in error state and no file id was assigned
        Assert.AreEqual(Enum::"E-Document Status"::Error, EDocument.Status, 'E-Document should be set to error state when service is down.');
        Assert.AreEqual('', EDocument."File Id", 'File Id on E-Document should not be set.');

        // [THEN] E-Document page shows the error
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        Assert.AreEqual(Format(EDocument.Status::Error), EDocumentPage."Electronic Document Status".Value(), IncorrectValueErr);
        Assert.AreEqual(Format(EDocument.Direction::Outgoing), EDocumentPage.Direction.Value(), IncorrectValueErr);

        // [THEN] E-Document Service Status has correct error status
        VerifyOutboundFactboxValuesForSingleService(EDocument, Enum::"E-Document Service Status"::"Sending Error", 2);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Sending Error");
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        // [THEN] E-Document Errors and Warnings contains the response code returned by Pagero
        EDocumentPage.ErrorMessagesPart.First();
        Assert.AreEqual('Error', EDocumentPage.ErrorMessagesPart."Message Type".Value(), IncorrectValueErr);
        Assert.IsTrue(
            EDocumentPage.ErrorMessagesPart.Description.Value().Contains('500'),
            'The error message should contain the http status code returned by Pagero.');
        EDocumentPage.Close();
    end;

    [Test]
    [HandlerFunctions('HTTPSubmitHandler,EDocServicesPageHandler')]
    internal procedure SubmitDocumentErrorRestart()
    var
        EDocument: Record "E-Document";
        EDocumentPage: TestPage "E-Document";
        EDocLogList: List of [Enum "E-Document Service Status"];
    begin
        // [SCENARIO] Pagero reports an error on the filepart, and the user restarts the document from the E-Document page.
        // Pending response -> Sending error -> Pending response -> Sent
        Initialize();

        // [GIVEN] Team member posts an invoice that is submitted to Pagero
        LibraryPermission.SetTeamMember();
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);

        // [WHEN] Pagero reports an error for the filepart
        SetFilepartStatus(FilepartStatus::Error);
        RunGetResponseJob();
        EDocument.FindLast();

        // [THEN] E-Document is in error state and the filepart id from the response is stored
        Assert.AreEqual(Enum::"E-Document Status"::Error, EDocument.Status, 'E-Document should be set to error');
        Assert.AreEqual(MockFilepartId(), EDocument."Filepart Id", 'Pagero integration failed to set Filepart Id on E-Document');
        VerifyOutboundFactboxValuesForSingleService(EDocument, Enum::"E-Document Service Status"::"Sending Error", 3);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Sending Error");
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        // [THEN] The error description returned by Pagero is shown to the user
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        EDocumentPage.ErrorMessagesPart.First();
        Assert.AreEqual('Error', EDocumentPage.ErrorMessagesPart."Message Type".Value(), IncorrectValueErr);
        EDocumentPage.Close();

        // [WHEN] User sends the document again, which restarts the filepart in Pagero
        SetFilepartStatus(FilepartStatus::Processed);
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        EDocumentPage.Send_Promoted.Invoke();
        // Service is selected by EDocServicesPageHandler
        EDocumentPage.Close();
        EDocument.FindLast();

        // [THEN] E-Document is pending response again
        Assert.AreEqual(Enum::"E-Document Status"::"In Progress", EDocument.Status, 'E-Document should be set to in progress');
        VerifyOutboundFactboxValuesForSingleService(EDocument, Enum::"E-Document Service Status"::"Pending Response", 4);

        // [WHEN] Pagero has processed the restarted filepart
        RunGetResponseJob();
        EDocument.FindLast();

        // [THEN] E-Document is considered processed
        Assert.AreEqual(Enum::"E-Document Status"::Processed, EDocument.Status, 'E-Document should be set to processed');
        VerifyOutboundFactboxValuesForSingleService(EDocument, Enum::"E-Document Service Status"::Sent, 5);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Sending Error");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        EDocLogList.Add(Enum::"E-Document Service Status"::Sent);
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);
    end;

    [Test]
    [HandlerFunctions('HTTPSubmitHandler,EDocServicesPageHandler')]
    internal procedure GetApprovalDocumentAccepted()
    var
        EDocument: Record "E-Document";
        EDocumentPage: TestPage "E-Document";
    begin
        // [SCENARIO] The receiver accepted the sent document, so Pagero returns an application response with 'RecipientAccept'.
        Initialize();
        SendDocumentAndGetResponse(EDocument);

        // [GIVEN] Pagero has a received application response accepting the document
        SetApplicationResponseSubType(RecipientAcceptTok);

        // [WHEN] User invokes Get Approval on the E-Document page
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        EDocumentPage.GetApproval.Invoke();
        // Service is selected by EDocServicesPageHandler
        EDocumentPage.Close();

        // [THEN] E-Document Service Status is Approved
        VerifyServiceStatus(EDocument, Enum::"E-Document Service Status"::Approved);
    end;

    [Test]
    [HandlerFunctions('HTTPSubmitHandler,EDocServicesPageHandler')]
    internal procedure GetApprovalDocumentRejected()
    var
        EDocument: Record "E-Document";
        EDocumentPage: TestPage "E-Document";
    begin
        // [SCENARIO] The receiver rejected the sent document, so Pagero returns an application response with 'RecipientReject'.
        Initialize();
        SendDocumentAndGetResponse(EDocument);

        // [GIVEN] Pagero has a received application response rejecting the document
        SetApplicationResponseSubType(RecipientRejectTok);

        // [WHEN] User invokes Get Approval on the E-Document page
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        EDocumentPage.GetApproval.Invoke();
        // Service is selected by EDocServicesPageHandler
        EDocumentPage.Close();

        // [THEN] E-Document Service Status is Rejected
        VerifyServiceStatus(EDocument, Enum::"E-Document Service Status"::Rejected);
    end;

    [Test]
    [HandlerFunctions('HTTPSubmitHandler,EDocServicesPageHandler')]
    internal procedure GetApprovalNotAllowedBeforeDocumentIsSent()
    var
        EDocument: Record "E-Document";
        EDocumentPage: TestPage "E-Document";
    begin
        // [SCENARIO] Approval can only be requested when the document has been sent.
        Initialize();

        // [GIVEN] A document that is pending response
        LibraryPermission.SetTeamMember();
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);
        EDocument.FindLast();
        VerifyServiceStatus(EDocument, Enum::"E-Document Service Status"::"Pending Response");

        // [WHEN] User invokes Get Approval on the E-Document page
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        EDocumentPage.GetApproval.Invoke();
        // Service is selected by EDocServicesPageHandler
        EDocumentPage.Close();

        // [THEN] A warning is shown to the user
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        EDocumentPage.ErrorMessagesPart.First();
        Assert.AreEqual('Warning', EDocumentPage.ErrorMessagesPart."Message Type".Value(), IncorrectValueErr);
        EDocumentPage.Close();

        // [THEN] The status is unchanged
        VerifyServiceStatus(EDocument, Enum::"E-Document Service Status"::"Pending Response");
    end;

    [Test]
    [HandlerFunctions('HTTPSubmitHandler,EDocServicesPageHandler')]
    internal procedure CancelDocumentAfterSendingError()
    var
        EDocument: Record "E-Document";
        EDocumentPage: TestPage "E-Document";
    begin
        // [SCENARIO] A document in sending error can be canceled in Pagero.
        Initialize();

        // [GIVEN] A document that failed with a sending error
        LibraryPermission.SetTeamMember();
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);
        SetFilepartStatus(FilepartStatus::Error);
        RunGetResponseJob();
        EDocument.FindLast();
        VerifyServiceStatus(EDocument, Enum::"E-Document Service Status"::"Sending Error");

        // [WHEN] User invokes Cancel on the E-Document page
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        EDocumentPage.Cancel.Invoke();
        // Service is selected by EDocServicesPageHandler
        EDocumentPage.Close();

        // [THEN] E-Document Service Status is Canceled
        VerifyServiceStatus(EDocument, Enum::"E-Document Service Status"::Canceled);
    end;

    [Test]
    [HandlerFunctions('HTTPSubmitHandler,EDocServicesPageHandler')]
    internal procedure CancelNotAllowedWhilePendingResponse()
    var
        EDocument: Record "E-Document";
        EDocumentPage: TestPage "E-Document";
    begin
        // [SCENARIO] Cancellation is only allowed from 'Sending Error' or 'Cancel Error'.
        Initialize();

        // [GIVEN] A document that is pending response
        LibraryPermission.SetTeamMember();
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);
        EDocument.FindLast();
        VerifyServiceStatus(EDocument, Enum::"E-Document Service Status"::"Pending Response");

        // [WHEN] User invokes Cancel on the E-Document page
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        EDocumentPage.Cancel.Invoke();
        // Service is selected by EDocServicesPageHandler
        EDocumentPage.Close();

        // [THEN] A warning is shown to the user
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        EDocumentPage.ErrorMessagesPart.First();
        Assert.AreEqual('Warning', EDocumentPage.ErrorMessagesPart."Message Type".Value(), IncorrectValueErr);
        EDocumentPage.Close();

        // [THEN] The status is unchanged
        VerifyServiceStatus(EDocument, Enum::"E-Document Service Status"::"Pending Response");
    end;

    #endregion

    #region Inbound tests

    [Test]
    [HandlerFunctions('HTTPSubmitHandler')]
    internal procedure ReceiveDocumentCreatesPurchaseInvoice()
    var
        Currency: Record Currency;
        EDocument: Record "E-Document";
        PurchaseHeader: Record "Purchase Header";
        EDocServicePage: TestPage "E-Document Service";
        PreviousWorkDate: Date;
    begin
        // [SCENARIO] The import job downloads the documents that Pagero received on behalf of the company
        // and creates a purchase invoice for the sending vendor.
        Initialize();

        // [GIVEN] Work date and exchange rate matching the received document
        PreviousWorkDate := WorkDate();
        WorkDate(DMY2Date(8, 4, 2024));
        if not Currency.Get(MockCurrencyCode()) then begin
            Currency.Init();
            Currency.Validate(Code, MockCurrencyCode());
            Currency.Insert(true);
        end;
        LibraryERM.CreateExchangeRate(MockCurrencyCode(), WorkDate(), 1, 1);
        EnsureCountryISOCode();

        // [GIVEN] Service is configured to look up items by item reference
        EDocServicePage.OpenView();
        EDocServicePage.GoToRecord(EDocumentService);
        EDocServicePage."Resolve Unit Of Measure".SetValue(false);
        EDocServicePage."Lookup Item Reference".SetValue(true);
        EDocServicePage."Lookup Item GTIN".SetValue(false);
        EDocServicePage."Lookup Account Mapping".SetValue(false);
        EDocServicePage."Validate Line Discount".SetValue(false);
        EDocServicePage.Close();

        // [WHEN] The recurrent import job runs
        if EDocument.FindLast() then
            EDocument.SetFilter("Entry No", '>%1', EDocument."Entry No");
        LibraryEDocument.RunImportJob();

        // [THEN] An incoming E-Document with a purchase invoice for the vendor is created
#pragma warning disable AA0210
        EDocument.SetRange("Document Type", EDocument."Document Type"::"Purchase Invoice");
        EDocument.SetRange("Bill-to/Pay-to No.", Vendor."No.");
#pragma warning restore AA0210
        EDocument.FindLast();

        Assert.AreEqual(Format(EDocument.Direction::Incoming), Format(EDocument.Direction), IncorrectValueErr);
        PurchaseHeader.Get(EDocument."Document Record ID");
        Assert.AreEqual(Vendor."No.", PurchaseHeader."Buy-from Vendor No.", 'Wrong Vendor');

        // [THEN] The identifiers returned by Pagero are persisted on the E-Document
        Assert.AreEqual(MockReceivedDocumentId(), EDocument."Document Id", 'Pagero integration failed to set Document Id on the received E-Document');
        Assert.AreEqual(MockReceivedFileId(), EDocument."File Id", 'Pagero integration failed to set File Id on the received E-Document');

        WorkDate(PreviousWorkDate);
    end;

    #endregion

    #region Setup tests

    [Test]
    [HandlerFunctions('ConfirmQst')]
    procedure ResetSetupRecord()
    var
        EDocExtConnectionSetup: Record "E-Doc. Ext. Connection Setup";
        PageroAuth: Codeunit "Pagero Auth.";
        EDOCExt: TestPage "EDoc Ext Connection Setup Card";
        ValueBefore: Text;
    begin
        PageroAuth.InitConnectionSetup();
        EDocExtConnectionSetup.Get();
        ValueBefore := EDocExtConnectionSetup."Authentication URL";

        // Mimic wrong url
        EDocExtConnectionSetup."Authentication URL" := 'Random URL';
        EDocExtConnectionSetup.Modify();

        EDOCExt.OpenView();
        EDOCExt.ResetSetup.Invoke();

        EDocExtConnectionSetup.Get();
        Assert.AreEqual(ValueBefore, EDocExtConnectionSetup."Authentication URL", 'Reset Setup did not restore the Authentication URL');
    end;

    #endregion

    #region Handlers

    [ConfirmHandler]
    procedure ConfirmQst(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true; // Automatically confirm all questions in tests
    end;

    [ModalPageHandler]
    internal procedure EDocServicesPageHandler(var EDocServicesPage: TestPage "E-Document Services")
    begin
        EDocServicesPage.Filter.SetFilter(Code, EDocumentService.Code);
        EDocServicesPage.OK().Invoke();
    end;

    [HttpClientHandler]
    internal procedure HTTPSubmitHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Response.HttpStatusCode := 200;
        case true of
            Request.Path = FileApiUrlTok:
                RespondWithResource(Response, FilesResourceTok);
            Request.Path = FileApiUrlTok + '/' + MockFileId() + '/fileparts':
                RespondWithFileparts(Response);
            Request.Path = FilepartsApiUrlTok + '/' + MockFilepartId() + '/action':
                Response.Content.WriteFrom(EmptyJsonTok);
            Request.Path = DocumentApiUrlTok + '/fetch':
                Response.Content.WriteFrom(EmptyJsonTok);
            Request.Path.EndsWith(TargetDocumentPathTok):
                RespondWithResource(Response, TargetDocumentResourceTok);
            Request.Path = DocumentApiUrlTok:
                RespondWithDocuments(Request, Response);
            else
                Response.HttpStatusCode := 500;
        end;
    end;

    [HttpClientHandler]
    internal procedure ServiceDownHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Response.HttpStatusCode := 500;
        Response.Content.WriteFrom(EmptyJsonTok);
    end;

    local procedure RespondWithFileparts(var Response: TestHttpResponseMessage)
    begin
        case FilepartStatus of
            FilepartStatus::Processing:
                RespondWithResource(Response, FilepartsProcessingResourceTok);
            FilepartStatus::Error:
                RespondWithResource(Response, FilepartsErrorResourceTok);
            else
                RespondWithResource(Response, FilepartsResourceTok);
        end;
    end;

    local procedure RespondWithDocuments(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage)
    var
        QueryParameters: Dictionary of [Text, Text];
        ResponseJson: Text;
    begin
        QueryParameters := Request.QueryParameters;
        case true of
            QueryParameters.ContainsKey(FileIdParameterTok):
                RespondWithResource(Response, DocumentsResourceTok);
            QueryParameters.ContainsKey(ReferenceDocumentParameterTok):
                begin
                    // The identifier on the application response has to match the document approval was requested for.
                    ResponseJson := NavApp.GetResourceAsText(ApplicationResponseResourceTok, TextEncoding::UTF8);
                    ResponseJson := ResponseJson.Replace(DocumentNoPlaceholderTok, QueryParameters.Get(ReferenceDocumentParameterTok));
                    ResponseJson := ResponseJson.Replace(SubTypePlaceholderTok, ApplicationResponseSubType);
                    Response.Content.WriteFrom(ResponseJson);
                end;
            else
                RespondWithResource(Response, DocumentsReceivedResourceTok);
        end;
    end;

    local procedure RespondWithResource(var Response: TestHttpResponseMessage; ResourceName: Text)
    begin
        Response.Content.WriteFrom(NavApp.GetResourceAsText(ResourceName, TextEncoding::UTF8));
    end;

    #endregion

    #region Helpers

    local procedure SendDocumentAndGetResponse(var EDocument: Record "E-Document")
    begin
        LibraryPermission.SetTeamMember();
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);

        RunGetResponseJob();
        EDocument.FindLast();

        Assert.AreEqual(Enum::"E-Document Status"::Processed, EDocument.Status, 'E-Document should be set to processed');
        VerifyServiceStatus(EDocument, Enum::"E-Document Service Status"::Sent);
    end;

    local procedure RunGetResponseJob()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"E-Document Get Response");
        LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);
    end;

    local procedure VerifyServiceStatus(EDocument: Record "E-Document"; Status: Enum "E-Document Service Status")
    var
        EDocumentServiceStatus: Record "E-Document Service Status";
    begin
        EDocumentServiceStatus.Get(EDocument."Entry No", EDocumentService.Code);
        Assert.AreEqual(Format(Status), Format(EDocumentServiceStatus.Status), 'Wrong E-Document Service Status');
    end;

    local procedure VerifyOutboundFactboxValuesForSingleService(EDocument: Record "E-Document"; Status: Enum "E-Document Service Status"; Logs: Integer);
    var
        EDocumentServiceStatus: Record "E-Document Service Status";
        Factbox: TestPage "Outbound E-Doc. Factbox";
    begin
        EDocumentServiceStatus.SetRange("E-Document Entry No", EDocument."Entry No");
        EDocumentServiceStatus.FindSet();
        // This function is for single service, so we expect only one record
        Assert.RecordCount(EDocumentServiceStatus, 1);

        Factbox.OpenView();
        Factbox.GoToRecord(EDocumentServiceStatus);

        Assert.AreEqual(EDocumentService.Code, Factbox."E-Document Service".Value(), IncorrectValueErr);
        Assert.AreEqual(Format(Status), Factbox.SingleStatus.Value(), IncorrectValueErr);
        Assert.AreEqual(Format(Logs), Factbox.Log.Value(), IncorrectValueErr);
    end;

    local procedure SetFilepartStatus(NewFilepartStatus: Option Processed,Processing,Error)
    begin
        FilepartStatus := NewFilepartStatus;
    end;

    local procedure SetApplicationResponseSubType(NewApplicationResponseSubType: Text)
    begin
        ApplicationResponseSubType := NewApplicationResponseSubType;
    end;

    local procedure EnsureCountryISOCode()
    var
        CountryRegion: Record "Country/Region";
    begin
        if CountryRegion.Get(Vendor."Country/Region Code") then
            if CountryRegion."ISO Code" = '' then begin
                CountryRegion."ISO Code" := 'GB';
                CountryRegion."ISO Numeric Code" := '826';
                CountryRegion.Modify();
            end;
    end;

    local procedure Initialize()
    var
        ConnectionSetup: Record "E-Doc. Ext. Connection Setup";
        CompanyInformation: Record "Company Information";
        OAuth2Setup: Record "OAuth 2.0 Setup";
        PageroAuth: Codeunit "Pagero Auth.";
        KeyGuid: Guid;
    begin
        LibraryPermission.SetOutsideO365Scope();
        // Restore the work date in case a previous test failed before restoring it
        if OriginalWorkDate = 0D then
            OriginalWorkDate := WorkDate()
        else
            WorkDate(OriginalWorkDate);

        SetFilepartStatus(FilepartStatus::Processed);
        SetApplicationResponseSubType(RecipientAcceptTok);

        // Clean up token between runs
        if ConnectionSetup.Get() then
            ConnectionSetup.DeleteAll();
        PageroAuth.InitConnectionSetup();
        ConnectionSetup.Get();
        ConnectionSetup."Send Mode" := "E-Doc. Ext. Send Mode"::Test;
        ConnectionSetup."Company Id" := Format(CreateGuid());
        ConnectionSetup.Modify();

        if not OAuth2Setup.Get('EDocPagero') then begin
            OAuth2Setup.Init();
            OAuth2Setup.Code := 'EDocPagero';
            OAuth2Setup."Client Id" := KeyGuid;
            OAuth2Setup."Client Secret" := KeyGuid;
            OAuth2Setup."Access Token" := KeyGuid;
            OAuth2Setup.Insert(true);
        end;

        OAuth2Setup."Access Token Due DateTime" := CurrentDateTime() + 600 * 1000;
        OAuth2Setup.Modify();

        // Detect rollback from a previous failed test and force re-initialization
        if IsInitialized then
            if not Customer.Get(Customer."No.") then
                IsInitialized := false;

        if IsInitialized then
            exit;

        LibraryEDocument.SetupStandardVAT();
        LibraryEDocument.SetupStandardSalesScenario(Customer, EDocumentService, Enum::"E-Document Format"::"PEPPOL BIS 3.0", Enum::"Service Integration"::Pagero);

        LibraryEDocument.SetupStandardPurchaseScenario(Vendor, EDocumentService, Enum::"E-Document Format"::"PEPPOL BIS 3.0", Enum::"Service Integration"::Pagero);
        EDocumentService.Validate("Auto Import", true);
        EDocumentService."Import Minutes between runs" := 10;
        EDocumentService."Import Start Time" := Time();
        EDocumentService.Modify();

        Vendor."VAT Registration No." := 'GB777777771';
        Vendor."Receive E-Document To" := Enum::"E-Document Type"::"Purchase Invoice";
        Vendor.Modify();

        CompanyInformation.Get();
        CompanyInformation."VAT Registration No." := 'GB777777771';
        if CompanyInformation.Name = '' then
            CompanyInformation.Name := 'Test Company';
        CompanyInformation.Modify();

        IsInitialized := true;
    end;

    local procedure MockFileId(): Text
    begin
        exit('1234567890');
    end;

    local procedure MockFilepartId(): Text
    begin
        exit('5555555555');
    end;

    local procedure MockDocumentId(): Text
    begin
        exit('01f00578-8650-17dc-8631-390b96a662c9');
    end;

    local procedure MockReceivedDocumentId(): Text
    begin
        exit('2c1a2b30-0f4d-4b0e-91a1-8f37b53de0aa');
    end;

    local procedure MockReceivedFileId(): Text
    begin
        exit('9876543210');
    end;

    local procedure MockCurrencyCode(): Code[10]
    begin
        exit('XYZ');
    end;

    #endregion

    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        EDocumentService: Record "E-Document Service";
        Assert: Codeunit Assert;
        LibraryEDocument: Codeunit "Library - E-Document";
        LibraryERM: Codeunit "Library - ERM";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryPermission: Codeunit "Library - Lower Permissions";
        IsInitialized: Boolean;
        OriginalWorkDate: Date;
        FilepartStatus: Option Processed,Processing,Error;
        ApplicationResponseSubType: Text;
        IncorrectValueErr: Label 'Wrong value';
        RecipientAcceptTok: Label 'RecipientAccept', Locked = true;
        RecipientRejectTok: Label 'RecipientReject', Locked = true;
        FileApiUrlTok: Label 'https://api.pageroonline.com/file/v1/files', Locked = true;
        FilepartsApiUrlTok: Label 'https://api.pageroonline.com/file/v1/fileparts', Locked = true;
        DocumentApiUrlTok: Label 'https://api.pageroonline.com/document/v1/documents', Locked = true;
        TargetDocumentPathTok: Label '/targetdocument', Locked = true;
        FileIdParameterTok: Label 'fileId', Locked = true;
        ReferenceDocumentParameterTok: Label 'referenceDocumentIdentifier', Locked = true;
        FilesResourceTok: Label 'files200.json', Locked = true;
        FilepartsResourceTok: Label 'fileparts200.json', Locked = true;
        FilepartsProcessingResourceTok: Label 'filepartsprocessing.json', Locked = true;
        FilepartsErrorResourceTok: Label 'filepartserror.json', Locked = true;
        DocumentsResourceTok: Label 'documents200.json', Locked = true;
        DocumentsReceivedResourceTok: Label 'documentsreceived200.json', Locked = true;
        ApplicationResponseResourceTok: Label 'applicationresponse200.json', Locked = true;
        TargetDocumentResourceTok: Label 'targetdocument.xml', Locked = true;
        DocumentNoPlaceholderTok: Label '{{DOCUMENTNO}}', Locked = true;
        SubTypePlaceholderTok: Label '{{SUBTYPE}}', Locked = true;
        EmptyJsonTok: Label '{}', Locked = true;
}
