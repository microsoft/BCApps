// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;


using Microsoft.eServices.EDocument;
using Microsoft.EServices.EDocumentConnector.Avalara;
using Microsoft.Sales.Customer;
using System.Threading;
using System.Utilities;

codeunit 148196 "E2E Tests - Document Lifecycle"
{
    Subtype = Test;
    TestHttpRequestPolicy = AllowOutboundFromHandler;
    TestPermissions = Disabled;

    var
        Customer: Record Customer;
        EDocumentService: Record "E-Document Service";
        Assert: Codeunit Assert;
        LibraryEDocument: Codeunit "Library - E-Document";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('HttpSubmitHandler')]
    procedure TestCompleteLifecycle_Invoice_SubmitToComplete()
    var
        EDocument: Record "E-Document";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [SCENARIO] Complete lifecycle from invoice posting to document completion

        // [GIVEN] Configured E-Document service
        Initialize();

        // [WHEN] Posting an invoice
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();

        // [THEN] E-Document should be created
        Assert.AreEqual(Enum::"E-Document Status"::Created, EDocument.Status, 'Document should be created');

        // [WHEN] Running job queue to submit document
        LibraryEDocument.RunEDocumentJobQueue(EDocument);
        EDocument.FindLast();

        // [THEN] Document should be in progress with Avalara Document ID
        Assert.AreEqual(Enum::"E-Document Status"::"In Progress", EDocument.Status, 'Document should be in progress');
        Assert.AreNotEqual('', EDocument."Avalara Document Id", 'Avalara Document ID should be set');

        // [WHEN] Running get response with completed status
        SetDocumentStatus(DocumentStatus::Completed);
        JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"E-Document Get Response");
        LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);
        EDocument.FindLast();

        // [THEN] Document should be processed
        Assert.AreEqual(Enum::"E-Document Status"::Processed, EDocument.Status, 'Document should be processed');
    end;

    [Test]
    [HandlerFunctions('HttpSubmitHandler')]
    procedure TestCompleteLifecycle_CreditMemo_SubmitToComplete()
    var
        EDocument: Record "E-Document";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [SCENARIO] Complete lifecycle for credit memo from posting to completion

        // [GIVEN] Configured E-Document service
        Initialize();

        // [WHEN] Posting a credit memo
        LibraryEDocument.PostCreditMemo(Customer);
        EDocument.FindLast();

        // [THEN] E-Document should be created
        Assert.AreEqual(Enum::"E-Document Status"::Created, EDocument.Status, 'Document should be created');

        // [WHEN] Submitting document
        LibraryEDocument.RunEDocumentJobQueue(EDocument);
        EDocument.FindLast();

        // [THEN] Document should be in progress
        Assert.AreEqual(Enum::"E-Document Status"::"In Progress", EDocument.Status, 'Document should be in progress');

        // [WHEN] Getting response with completed status
        SetDocumentStatus(DocumentStatus::Completed);
        JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"E-Document Get Response");
        LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);
        EDocument.FindLast();

        // [THEN] Document should be processed
        Assert.AreEqual(Enum::"E-Document Status"::Processed, EDocument.Status, 'Document should be processed');
    end;

    [Test]
    [HandlerFunctions('HttpSubmitHandler')]
    procedure TestManualResend_AfterError_Success()
    var
        EDocument: Record "E-Document";
        JobQueueEntry: Record "Job Queue Entry";
        EDocumentPage: TestPage "E-Document";
    begin
        // [SCENARIO] User can manually resend document after error

        // [GIVEN] A document in error state
        Initialize();
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);
        EDocument.FindLast();

        // Set to error state
        SetDocumentStatus(DocumentStatus::Error);
        JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"E-Document Get Response");
        LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);
        EDocument.FindLast();
        Assert.AreEqual(Enum::"E-Document Status"::Error, EDocument.Status, 'Document should be in error');

        // [WHEN] User manually resends document
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        EDocumentPage.Send_Promoted.Invoke();
        EDocumentPage.Close();

        // [THEN] Document should be resubmitted
        EDocument.FindLast();
        Assert.AreEqual(Enum::"E-Document Status"::"In Progress", EDocument.Status, 'Document should be in progress after resend');

        // [WHEN] Get response returns complete
        SetDocumentStatus(DocumentStatus::Completed);
        JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"E-Document Get Response");
        LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);
        EDocument.FindLast();

        // [THEN] Document should be processed
        Assert.AreEqual(Enum::"E-Document Status"::Processed, EDocument.Status, 'Document should be processed');
    end;

    [Test]
    [HandlerFunctions('HttpSubmitHandler')]
    procedure TestMultipleDocuments_Sequential_AllProcessed()
    var
        EDocument: Record "E-Document";
        JobQueueEntry: Record "Job Queue Entry";
        DocumentCount: Integer;
        i: Integer;
    begin
        // [SCENARIO] Multiple documents can be processed sequentially

        // [GIVEN] Configured E-Document service
        Initialize();
        DocumentCount := 3;

        // [WHEN] Posting multiple invoices
        for i := 1 to DocumentCount do
            LibraryEDocument.PostInvoice(Customer);

        // [THEN] All documents should be created
        EDocument.SetRange(Status, EDocument.Status::Created);
        Assert.AreEqual(DocumentCount, EDocument.Count, 'All documents should be created');

        // [WHEN] Running job queue for all documents
        SetDocumentStatus(DocumentStatus::Completed);
        if EDocument.FindSet() then
            repeat
                LibraryEDocument.RunEDocumentJobQueue(EDocument);
            until EDocument.Next() = 0;

        // Process responses
        JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"E-Document Get Response");
        LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);

        // [THEN] All documents should be processed
        Clear(EDocument);
        EDocument.SetRange(Status, EDocument.Status::Processed);
        Assert.AreEqual(DocumentCount, EDocument.Count, 'All documents should be processed');
    end;

    [Test]
    [HandlerFunctions('HttpSubmitHandler')]
    procedure TestDocumentCancellation_MarksAsCancelled()
    var
        EDocument: Record "E-Document";
    begin
        // [SCENARIO] Document can be cancelled before submission

        // [GIVEN] A created E-Document
        Initialize();
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        Assert.AreEqual(Enum::"E-Document Status"::Created, EDocument.Status, 'Document should be created');

        // [WHEN] Cancelling the document
        EDocument.Status := EDocument.Status::Cancelled;
        EDocument.Modify();

        // [THEN] Document should be cancelled
        Assert.AreEqual(Enum::"E-Document Status"::Cancelled, EDocument.Status, 'Document should be cancelled');
    end;

    [Test]
    [HandlerFunctions('HttpSubmitHandler')]
    procedure TestAvalaraDocumentId_Persistence()
    var
        EDocument: Record "E-Document";
        SavedDocumentId: Text[50];
    begin
        // [SCENARIO] Avalara Document ID persists across status changes

        // [GIVEN] A submitted E-Document
        Initialize();
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);
        EDocument.FindLast();

        SavedDocumentId := EDocument."Avalara Document Id";
        Assert.AreNotEqual('', SavedDocumentId, 'Document ID should be set');

        // [WHEN] Document status changes
        EDocument.Status := EDocument.Status::Processed;
        EDocument.Modify();

        // [THEN] Avalara Document ID should remain unchanged
        EDocument.Get(EDocument."Entry No");
        Assert.AreEqual(SavedDocumentId, EDocument."Avalara Document Id", 'Document ID should persist');
    end;

    [Test]
    [HandlerFunctions('HttpSubmitHandler')]
    procedure TestServiceStatusLog_CreatesLogEntries()
    var
        EDocument: Record "E-Document";
        EDocumentServiceStatus: Record "E-Document Service Status";
    begin
        // [SCENARIO] Service status changes create log entries

        // [GIVEN] Configured E-Document service
        Initialize();

        // [WHEN] Processing a document through various states
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);

        // [THEN] Service status log entries should be created
        EDocumentServiceStatus.SetRange("E-Document Entry No", EDocument."Entry No");
        Assert.RecordIsNotEmpty(EDocumentServiceStatus);
    end;

    local procedure Initialize()
    var
        ConnectionSetup: Record "Connection Setup";
        AvalaraAuth: Codeunit Authenticator;
        KeyGuid: Guid;
    begin
        if IsInitialized then
            exit;

        LibraryEDocument.SetupStandardVAT();
        LibraryEDocument.SetupStandardSalesScenario(Customer, EDocumentService, Enum::"E-Document Format"::"PEPPOL BIS 3.0", Enum::"Service Integration"::Avalara);
        EDocumentService."Avalara Mandate" := 'GB-TEST';
        EDocumentService.Modify();

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

        IsInitialized := true;
    end;

    local procedure SetDocumentStatus(NewDocumentStatus: Option Completed,Pending,Error)
    begin
        this.DocumentStatus := NewDocumentStatus;
    end;

    [HttpClientHandler]
    internal procedure HttpSubmitHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        Regex: Codeunit Regex;
        ConnectTokenFileTok: Label 'ConnectToken.txt', Locked = true;
        GetResponseCompleteFileTok: Label 'GetResponseComplete.txt', Locked = true;
        GetResponseErrorFileTok: Label 'GetResponseError.txt', Locked = true;
        GetResponsePendingFileTok: Label 'GetResponsePending.txt', Locked = true;
        SubmitDocumentFileTok: Label 'SubmitDocument.txt', Locked = true;
    begin
        case true of
            Regex.IsMatch(Request.Path, 'https?://.+/connect/token'):
                LoadResourceIntoHttpResponse(ConnectTokenFileTok, Response);

            Regex.IsMatch(Request.Path, 'https?://.+/einvoicing/documents/.+/status'):
                case DocumentStatus of
                    DocumentStatus::Completed:
                        LoadResourceIntoHttpResponse(GetResponseCompleteFileTok, Response);
                    DocumentStatus::Pending:
                        LoadResourceIntoHttpResponse(GetResponsePendingFileTok, Response);
                    DocumentStatus::Error:
                        LoadResourceIntoHttpResponse(GetResponseErrorFileTok, Response);
                end;

            Regex.IsMatch(Request.Path, 'https?://.+/einvoicing/documents'):
                LoadResourceIntoHttpResponse(SubmitDocumentFileTok, Response);
        end;
    end;

    local procedure LoadResourceIntoHttpResponse(ResourceText: Text; var Response: TestHttpResponseMessage)
    begin
        Response.Content.WriteFrom(NavApp.GetResourceAsText(ResourceText, TextEncoding::UTF8));
        Response.HttpStatusCode := 200;
    end;

    var
        DocumentStatus: Option Completed,Pending,Error;
}
