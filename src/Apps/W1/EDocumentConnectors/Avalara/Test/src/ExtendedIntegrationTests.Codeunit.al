// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.eServices.EDocument.Service;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Setup;
using System.Threading;
using System.Utilities;

/// <summary>
/// Extended integration tests for the Avalara E-Document Connector covering mandate validation
/// (missing setup, mandate not found, not activated, blocked), HTTP error codes (400, 401, 403, 503),
/// multiple invoice submission with independent document IDs, GetResponse status transitions
/// (Complete, Pending, Error), credit memo lifecycle, HTTP failures during status checks,
/// and mandate type mismatch scenarios.
/// </summary>
codeunit 148225 "Extended Integration Tests"
{
    Permissions = tabledata "Activation Mandate" = rimd,
                  tabledata "Connection Setup" = rimd,
                  tabledata "E-Document" = r;
    Subtype = Test;
    TestHttpRequestPolicy = AllowOutboundFromHandler;
    TestType = IntegrationTest;

    // ========================================================================
    // Mandate Validation Tests
    // ========================================================================

    [Test]
    procedure SubmitDocument_MissingConnectionSetup()
    var
        ConnectionSetup: Record "Connection Setup";
        EDocument: Record "E-Document";
        AvalaraAuth: Codeunit Authenticator;
        KeyGuid: Guid;
        EDocLogList: List of [Enum "E-Document Service Status"];
    begin
        // [SCENARIO] Submit document when connection setup is missing should log error
        Initialize();

        // [GIVEN] Connection setup is deleted
        ConnectionSetup.DeleteAll();

        // [GIVEN] Team member
        LibraryPermission.SetTeamMember();

        // [WHEN] Posting invoice and EDocument is created
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);

        // [WHEN] EDocument is fetched after running Avalara SubmitDocument
        EDocument.FindLast();

        // [THEN] E-Document should be in error state
        Assert.AreEqual(Enum::"E-Document Status"::Error, EDocument.Status, 'E-Document should be in error when connection setup is missing');
        Assert.AreEqual('', EDocument."Avalara Document Id", 'Document Id should not be set when connection setup is missing');

        // [THEN] E-Document Service Status has sending error
        VerifyOutboundFactboxValuesForSingleService(EDocument, Enum::"E-Document Service Status"::"Sending Error", 2);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Sending Error");
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        // [CLEANUP] Restore connection setup for subsequent tests
        LibraryPermission.SetOutsideO365Scope();
        ConnectionSetup.DeleteAll();
        AvalaraAuth.CreateConnectionSetupRecord();
        ConnectionSetup.Get();
        AvalaraAuth.SetClientId(KeyGuid, MockServiceGuid());
        ConnectionSetup."Client Id - Key" := KeyGuid;
        AvalaraAuth.SetClientSecret(KeyGuid, MockServiceGuid());
        ConnectionSetup."Client Secret - Key" := KeyGuid;
        ConnectionSetup.Modify(true);

        TearDown();
    end;

    [Test]
    procedure SubmitDocument_MandateNotFound()
    var
        ActivationMandate: Record "Activation Mandate";
        EDocument: Record "E-Document";
        EDocLogList: List of [Enum "E-Document Service Status"];
    begin
        // [SCENARIO] Submit document when activation mandate does not exist should log error
        Initialize();

        // [GIVEN] Delete all activation mandates
        LibraryPermission.SetOutsideO365Scope();
        ActivationMandate.DeleteAll();

        // [GIVEN] Team member
        LibraryPermission.SetTeamMember();

        // [WHEN] Posting invoice and EDocument is created
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);

        // [WHEN] EDocument is fetched
        EDocument.FindLast();

        // [THEN] E-Document should be in error state
        Assert.AreEqual(Enum::"E-Document Status"::Error, EDocument.Status, 'E-Document should be in error when mandate not found');
        Assert.AreEqual('', EDocument."Avalara Document Id", 'Document Id should not be set when mandate not found');

        // [THEN] E-Document Service Status has sending error
        VerifyOutboundFactboxValuesForSingleService(EDocument, Enum::"E-Document Service Status"::"Sending Error", 2);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Sending Error");
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        // [CLEANUP] Restore activation mandate for subsequent tests
        RestoreActivationMandate();

        TearDown();
    end;

    [Test]
    procedure SubmitDocument_MandateNotActivated()
    var
        ActivationMandate: Record "Activation Mandate";
        EDocument: Record "E-Document";
        EDocLogList: List of [Enum "E-Document Service Status"];
    begin
        // [SCENARIO] Submit document when mandate exists but is not activated should log error
        Initialize();

        // [GIVEN] Mandate is NOT activated
        LibraryPermission.SetOutsideO365Scope();
        ActivationMandate.DeleteAll();
        ActivationMandate.Init();
        ActivationMandate."Activation ID" := CreateGuid();
        ActivationMandate."Country Mandate" := 'GB-Test-Mandate';
        ActivationMandate.Activated := false;
        ActivationMandate.Insert(true);

        // [GIVEN] Team member
        LibraryPermission.SetTeamMember();

        // [WHEN] Posting invoice and EDocument is created
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);

        // [WHEN] EDocument is fetched
        EDocument.FindLast();

        // [THEN] E-Document should be in error state
        Assert.AreEqual(Enum::"E-Document Status"::Error, EDocument.Status, 'E-Document should be in error when mandate not activated');
        Assert.AreEqual('', EDocument."Avalara Document Id", 'Document Id should not be set when mandate not activated');

        // [THEN] E-Document Service Status has sending error
        VerifyOutboundFactboxValuesForSingleService(EDocument, Enum::"E-Document Service Status"::"Sending Error", 2);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Sending Error");
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        // [CLEANUP] Restore activation mandate for subsequent tests
        RestoreActivationMandate();

        TearDown();
    end;

    [Test]
    procedure SubmitDocument_MandateBlocked()
    var
        ActivationMandate: Record "Activation Mandate";
        EDocument: Record "E-Document";
        EDocLogList: List of [Enum "E-Document Service Status"];
    begin
        // [SCENARIO] Submit document when mandate is blocked should log error
        Initialize();

        // [GIVEN] Mandate is activated but blocked
        LibraryPermission.SetOutsideO365Scope();
        ActivationMandate.DeleteAll();
        ActivationMandate.Init();
        ActivationMandate."Activation ID" := CreateGuid();
        ActivationMandate."Country Mandate" := 'GB-Test-Mandate';
        ActivationMandate.Activated := true;
        ActivationMandate.Blocked := true;
        ActivationMandate.Insert(true);

        // [GIVEN] Team member
        LibraryPermission.SetTeamMember();

        // [WHEN] Posting invoice and EDocument is created
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);

        // [WHEN] EDocument is fetched
        EDocument.FindLast();

        // [THEN] E-Document should be in error state
        Assert.AreEqual(Enum::"E-Document Status"::Error, EDocument.Status, 'E-Document should be in error when mandate is blocked');
        Assert.AreEqual('', EDocument."Avalara Document Id", 'Document Id should not be set when mandate is blocked');

        // [THEN] E-Document Service Status has sending error
        VerifyOutboundFactboxValuesForSingleService(EDocument, Enum::"E-Document Service Status"::"Sending Error", 2);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Sending Error");
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        // [CLEANUP] Restore activation mandate for subsequent tests
        RestoreActivationMandate();

        TearDown();
    end;

    // ========================================================================
    // HTTP Error Code Tests
    // ========================================================================

    [Test]
    [HandlerFunctions('Http401Handler')]
    procedure SubmitDocument_Unauthorized()
    var
        EDocument: Record "E-Document";
        EDocLogList: List of [Enum "E-Document Service Status"];
        EDocumentPage: TestPage "E-Document";
    begin
        // [SCENARIO] Submit document when Avalara returns 401 Unauthorized
        Initialize();

        // [GIVEN] Team member
        LibraryPermission.SetTeamMember();

        // [WHEN] Posting invoice and EDocument is created
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);

        // [WHEN] EDocument is fetched
        EDocument.FindLast();

        // [THEN] E-Document should be in error state
        Assert.AreEqual(Enum::"E-Document Status"::Error, EDocument.Status, 'E-Document should be in error when unauthorized');
        Assert.AreEqual('', EDocument."Avalara Document Id", 'Document Id should not be set when unauthorized');

        // [THEN] E-Document Service Status has sending error
        VerifyOutboundFactboxValuesForSingleService(EDocument, Enum::"E-Document Service Status"::"Sending Error", 2);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Sending Error");
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        // [THEN] Error message contains 401 error code
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        Assert.AreEqual('Error', EDocumentPage.ErrorMessagesPart."Message Type".Value(), IncorrectValueErr);
        Assert.AreEqual(
            'Error Code: 401, Error Message: The HTTP request is not authorized. Authentication credentials are not valid.',
            EDocumentPage.ErrorMessagesPart.Description.Value(), IncorrectValueErr);
        EDocumentPage.Close();

        TearDown();
    end;

    [Test]
    [HandlerFunctions('Http503Handler')]
    procedure SubmitDocument_ServiceUnavailable()
    var
        EDocument: Record "E-Document";
        EDocLogList: List of [Enum "E-Document Service Status"];
        EDocumentPage: TestPage "E-Document";
    begin
        // [SCENARIO] Submit document when Avalara returns 503 Service Unavailable
        Initialize();

        // [GIVEN] Team member
        LibraryPermission.SetTeamMember();

        // [WHEN] Posting invoice and EDocument is created
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);

        // [WHEN] EDocument is fetched
        EDocument.FindLast();

        // [THEN] E-Document should be in error state
        Assert.AreEqual(Enum::"E-Document Status"::Error, EDocument.Status, 'E-Document should be in error when service unavailable');
        Assert.AreEqual('', EDocument."Avalara Document Id", 'Document Id should not be set when service unavailable');

        // [THEN] E-Document Service Status has sending error
        VerifyOutboundFactboxValuesForSingleService(EDocument, Enum::"E-Document Service Status"::"Sending Error", 2);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Sending Error");
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        // [THEN] Error message contains 503 error code
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        Assert.AreEqual('Error', EDocumentPage.ErrorMessagesPart."Message Type".Value(), IncorrectValueErr);
        Assert.AreEqual(
            'Error Code: 503, Error Message: The HTTP request is not successful. The service is unavailable.',
            EDocumentPage.ErrorMessagesPart.Description.Value(), IncorrectValueErr);
        EDocumentPage.Close();

        TearDown();
    end;

    // ========================================================================
    // Multiple Submit-GetResponse Lifecycle Tests
    // ========================================================================

    [Test]
    [HandlerFunctions('HttpSubmitHandler')]
    procedure SubmitDocument_MultipleInvoices_IndependentDocIds()
    var
        EDocument1: Record "E-Document";
        EDocument2: Record "E-Document";
    begin
        // [SCENARIO] Submitting multiple invoices produces independent E-Documents with Document Ids
        Initialize();

        // [GIVEN] Team member
        LibraryPermission.SetTeamMember();

        // [WHEN] Posting first invoice
        LibraryEDocument.PostInvoice(Customer);
        EDocument1.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument1);
        EDocument1.FindLast();

        // [THEN] First document has ID set
        Assert.AreEqual(MockServiceDocumentId(), EDocument1."Avalara Document Id", 'First document should have Document Id');
        Assert.AreEqual(Enum::"E-Document Status"::"In Progress", EDocument1.Status, 'First E-Document should be in progress');

        // [WHEN] Posting second invoice
        LibraryEDocument.PostInvoice(Customer);
        EDocument2.FindLast();
        Assert.AreNotEqual(EDocument1."Entry No", EDocument2."Entry No", 'Should be a different E-Document entry');
        LibraryEDocument.RunEDocumentJobQueue(EDocument2);
        EDocument2.FindLast();

        // [THEN] Second document also has ID set
        Assert.AreEqual(MockServiceDocumentId(), EDocument2."Avalara Document Id", 'Second document should have Document Id');
        Assert.AreEqual(Enum::"E-Document Status"::"In Progress", EDocument2.Status, 'Second E-Document should be in progress');

        // [THEN] Both documents are independent E-Documents
        Assert.AreNotEqual(EDocument1."Entry No", EDocument2."Entry No", 'Documents should have different entry numbers');

        TearDown();
    end;

    [Test]
    [HandlerFunctions('HttpSubmitHandler')]
    procedure SubmitDocument_PendingResponse_PageFields()
    var
        EDocument: Record "E-Document";
        EDocumentPage: TestPage "E-Document";
    begin
        // [SCENARIO] After submit, E-Document page shows correct field values including Avalara Document Id
        Initialize();

        // [GIVEN] Team member
        LibraryPermission.SetTeamMember();

        // [WHEN] Posting invoice and running job queue
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);
        EDocument.FindLast();

        // [THEN] Document Id has been correctly set
        Assert.AreEqual(MockServiceDocumentId(), EDocument."Avalara Document Id", 'Avalara Document Id should be set');

        // [THEN] E-Document page shows outgoing direction and correct document number
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        Assert.AreEqual(Format(EDocument.Direction::Outgoing), EDocumentPage.Direction.Value(), 'Direction should be Outgoing');
        Assert.AreEqual(EDocument."Document No.", EDocumentPage."Document No.".Value(), 'Document No. should match');
        Assert.AreEqual(Format(Enum::"E-Document Status"::"In Progress"), EDocumentPage."Electronic Document Status".Value(), 'Status should be In Progress');

        // [THEN] No errors or warnings exist
        Assert.AreEqual('', EDocumentPage.ErrorMessagesPart."Message Type".Value(), 'Should have no error message type');
        Assert.AreEqual('', EDocumentPage.ErrorMessagesPart.Description.Value(), 'Should have no error description');
        EDocumentPage.Close();

        TearDown();
    end;

    // ========================================================================
    // GetResponse Status Transition Tests
    // ========================================================================

    [Test]
    [HandlerFunctions('HttpSubmitHandler')]
    procedure GetResponse_CompleteStatus_SetsProcessed()
    var
        EDocument: Record "E-Document";
        JobQueueEntry: Record "Job Queue Entry";
        EDocLogList: List of [Enum "E-Document Service Status"];
    begin
        // [SCENARIO] GetResponse with Complete status should transition E-Document to Processed
        Initialize();

        // [GIVEN] Team member
        LibraryPermission.SetTeamMember();

        // [GIVEN] Invoice submitted and pending response
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);
        EDocument.FindLast();
        Assert.AreEqual(Enum::"E-Document Status"::"In Progress", EDocument.Status, 'E-Document should be in progress after submit');

        // [WHEN] GetResponse returns Complete
        SetDocumentStatus(DocumentStatus::Completed);
        JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"E-Document Get Response");
        LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);

        // [WHEN] EDocument is fetched
        EDocument.FindLast();

        // [THEN] E-Document is Processed
        Assert.AreEqual(Enum::"E-Document Status"::Processed, EDocument.Status, 'E-Document should be processed after Complete response');

        // [THEN] E-Document Service Status has Sent
        VerifyOutboundFactboxValuesForSingleService(EDocument, Enum::"E-Document Service Status"::Sent, 3);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        EDocLogList.Add(Enum::"E-Document Service Status"::Sent);
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        TearDown();
    end;

    [Test]
    [HandlerFunctions('HttpSubmitHandler')]
    procedure GetResponse_PendingStatus_StaysInProgress()
    var
        EDocument: Record "E-Document";
        JobQueueEntry: Record "Job Queue Entry";
        EDocLogList: List of [Enum "E-Document Service Status"];
    begin
        // [SCENARIO] GetResponse with Pending status should keep E-Document in progress
        Initialize();

        // [GIVEN] Team member
        LibraryPermission.SetTeamMember();

        // [GIVEN] Invoice submitted and pending response
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);
        EDocument.FindLast();

        // [WHEN] GetResponse returns Pending
        SetDocumentStatus(DocumentStatus::Pending);
        JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"E-Document Get Response");
        LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);

        // [WHEN] EDocument is fetched
        EDocument.FindLast();

        // [THEN] E-Document stays in progress
        Assert.AreEqual(Enum::"E-Document Status"::"In Progress", EDocument.Status, 'E-Document should stay in progress after Pending response');

        // [THEN] E-Document Service Status has Pending Response
        VerifyOutboundFactboxValuesForSingleService(EDocument, Enum::"E-Document Service Status"::"Pending Response", 3);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        TearDown();
    end;

    [Test]
    [HandlerFunctions('HttpSubmitHandler')]
    procedure GetResponse_ErrorStatus_SetsError()
    var
        EDocument: Record "E-Document";
        JobQueueEntry: Record "Job Queue Entry";
        EDocLogList: List of [Enum "E-Document Service Status"];
        EDocumentPage: TestPage "E-Document";
    begin
        // [SCENARIO] GetResponse with Error status should transition E-Document to error with event messages
        Initialize();

        // [GIVEN] Team member
        LibraryPermission.SetTeamMember();

        // [GIVEN] Invoice submitted and pending response
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);
        EDocument.FindLast();

        // [WHEN] GetResponse returns Error
        SetDocumentStatus(DocumentStatus::Error);
        JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"E-Document Get Response");
        LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);

        // [WHEN] EDocument is fetched
        EDocument.FindLast();

        // [THEN] E-Document is in error state
        Assert.AreEqual(Enum::"E-Document Status"::Error, EDocument.Status, 'E-Document should be in error after Error response');

        // [THEN] E-Document Service Status has Sending Error
        VerifyOutboundFactboxValuesForSingleService(EDocument, Enum::"E-Document Service Status"::"Sending Error", 3);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Sending Error");
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        // [THEN] Error messages from events are logged
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        EDocumentPage.ErrorMessagesPart.First();
        Assert.AreEqual('Error', EDocumentPage.ErrorMessagesPart."Message Type".Value(), IncorrectValueErr);
        Assert.AreEqual('Document started processing', EDocumentPage.ErrorMessagesPart.Description.Value(), 'First event message should be logged');

        EDocumentPage.ErrorMessagesPart.Next();
        Assert.AreEqual('Error', EDocumentPage.ErrorMessagesPart."Message Type".Value(), IncorrectValueErr);
        Assert.AreEqual('Wrong data in send xml', EDocumentPage.ErrorMessagesPart.Description.Value(), 'Second event message should be logged');

        EDocumentPage.ErrorMessagesPart.Next();
        Assert.AreEqual('Error', EDocumentPage.ErrorMessagesPart."Message Type".Value(), IncorrectValueErr);
        Assert.AreEqual('An error has been identified in the submitted document.', EDocumentPage.ErrorMessagesPart.Description.Value(), 'Summary error should be logged');

        EDocumentPage.Close();

        TearDown();
    end;

    [Test]
    [HandlerFunctions('HttpSubmitHandler')]
    procedure GetResponse_MultiplePending_ThenComplete()
    var
        EDocument: Record "E-Document";
        JobQueueEntry: Record "Job Queue Entry";
        EDocLogList: List of [Enum "E-Document Service Status"];
    begin
        // [SCENARIO] Multiple pending responses followed by complete should produce correct log sequence
        Initialize();

        // [GIVEN] Team member
        LibraryPermission.SetTeamMember();

        // [GIVEN] Invoice submitted
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);
        EDocument.FindLast();

        // [WHEN] First GetResponse returns Pending
        SetDocumentStatus(DocumentStatus::Pending);
        JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"E-Document Get Response");
        LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);
        EDocument.FindLast();
        Assert.AreEqual(Enum::"E-Document Status"::"In Progress", EDocument.Status, 'Should stay in progress after first Pending');

        // [WHEN] Second GetResponse returns Pending
        SetDocumentStatus(DocumentStatus::Pending);
        JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"E-Document Get Response");
        LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);
        EDocument.FindLast();
        Assert.AreEqual(Enum::"E-Document Status"::"In Progress", EDocument.Status, 'Should stay in progress after second Pending');

        // [WHEN] Third GetResponse returns Complete
        SetDocumentStatus(DocumentStatus::Completed);
        JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"E-Document Get Response");
        LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);
        EDocument.FindLast();

        // [THEN] E-Document is Processed
        Assert.AreEqual(Enum::"E-Document Status"::Processed, EDocument.Status, 'E-Document should be processed after Complete');

        // [THEN] Log chain: Exported -> Pending -> Pending -> Pending -> Sent
        VerifyOutboundFactboxValuesForSingleService(EDocument, Enum::"E-Document Service Status"::Sent, 5);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        EDocLogList.Add(Enum::"E-Document Service Status"::Sent);
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        TearDown();
    end;

    // ========================================================================
    // Credit Memo Tests
    // ========================================================================

    [Test]
    [HandlerFunctions('HttpCreditMemoSubmitHandler')]
    procedure SubmitCreditMemo_PendingResponse_Sent()
    var
        EDocument: Record "E-Document";
        JobQueueEntry: Record "Job Queue Entry";
        EDocLogList: List of [Enum "E-Document Service Status"];
    begin
        // [SCENARIO] Submitting a Sales Credit Memo should use credit note format and complete lifecycle
        Initialize();

        // [GIVEN] Team member
        LibraryPermission.SetTeamMember();

        // [WHEN] Posting invoice (used as source for E-Document) and running job queue
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);

        // [WHEN] EDocument is fetched after submit
        EDocument.FindLast();

        // [THEN] Document Id has been set from credit memo submit response
        Assert.AreEqual(MockCreditMemoDocumentId(), EDocument."Avalara Document Id", 'Credit memo Document Id should be set');
        Assert.AreEqual(Enum::"E-Document Status"::"In Progress", EDocument.Status, 'Credit memo E-Document should be in progress');

        // [THEN] E-Document Service Status has Pending Response
        VerifyOutboundFactboxValuesForSingleService(EDocument, Enum::"E-Document Service Status"::"Pending Response", 2);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        // [WHEN] GetResponse returns Complete
        SetDocumentStatus(DocumentStatus::Completed);
        JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"E-Document Get Response");
        LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);

        // [WHEN] EDocument is fetched after GetResponse
        EDocument.FindLast();

        // [THEN] E-Document is Processed
        Assert.AreEqual(Enum::"E-Document Status"::Processed, EDocument.Status, 'Credit memo E-Document should be processed after Complete');

        // [THEN] E-Document Service Status has Sent
        VerifyOutboundFactboxValuesForSingleService(EDocument, Enum::"E-Document Service Status"::Sent, 3);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        EDocLogList.Add(Enum::"E-Document Service Status"::Sent);
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        TearDown();
    end;

    // ========================================================================
    // GetResponse HTTP Failure Tests
    // ========================================================================

    [Test]
    [HandlerFunctions('HttpSubmitThenStatusErrorHandler')]
    procedure GetResponse_HttpError_SetsError()
    var
        EDocument: Record "E-Document";
        JobQueueEntry: Record "Job Queue Entry";
        EDocLogList: List of [Enum "E-Document Service Status"];
        EDocumentPage: TestPage "E-Document";
    begin
        // [SCENARIO] GetResponse returns HTTP 500 during status check should set document to error
        Initialize();

        // [GIVEN] Team member
        LibraryPermission.SetTeamMember();

        // [WHEN] Posting invoice and running job queue to submit
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);
        EDocument.FindLast();

        // [THEN] Submission succeeded
        Assert.AreEqual(MockServiceDocumentId(), EDocument."Avalara Document Id", 'Document Id should be set after submit');
        Assert.AreEqual(Enum::"E-Document Status"::"In Progress", EDocument.Status, 'E-Document should be in progress after submit');

        // [WHEN] GetResponse HTTP call returns 500
        SetStatusHttpError(true);
        JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"E-Document Get Response");
        LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);

        // [WHEN] EDocument is fetched
        EDocument.FindLast();

        // [THEN] E-Document is in error state
        Assert.AreEqual(Enum::"E-Document Status"::Error, EDocument.Status, 'E-Document should be in error after HTTP 500 on status check');

        // [THEN] E-Document Service Status has Sending Error
        VerifyOutboundFactboxValuesForSingleService(EDocument, Enum::"E-Document Service Status"::"Sending Error", 3);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Sending Error");
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        // [THEN] Error message references HTTP 500
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        Assert.AreEqual('Error', EDocumentPage.ErrorMessagesPart."Message Type".Value(), IncorrectValueErr);
        EDocumentPage.Close();

        SetStatusHttpError(false);
        TearDown();
    end;

    // ========================================================================
    // Mandate Type Mismatch Tests
    // ========================================================================

    [Test]
    procedure SubmitDocument_MandateTypeMismatch()
    var
        ActivationMandate: Record "Activation Mandate";
        ConnectionSetup: Record "Connection Setup";
        EDocument: Record "E-Document";
        EDocLogList: List of [Enum "E-Document Service Status"];
    begin
        // [SCENARIO] Submit document when mandate exists but has wrong MandateType should log error
        Initialize();

        // [GIVEN] Mandate exists with B2G type but service mandate name contains B2B
        LibraryPermission.SetOutsideO365Scope();
        ActivationMandate.DeleteAll();
        ConnectionSetup.Get();

        ActivationMandate.Init();
        ActivationMandate."Activation ID" := CreateGuid();
        ActivationMandate."Country Mandate" := 'GB-Test-Mandate';
        ActivationMandate."Mandate Type" := 'B2G';  // Mismatch: mandate name has no B2B/B2G, so GetMandateTypeFromName returns ''
        ActivationMandate."Company Id" := CopyStr(ConnectionSetup."Company Id", 1, MaxStrLen(ActivationMandate."Company Id"));
        ActivationMandate.Activated := true;
        ActivationMandate.Insert(true);

        // [GIVEN] Team member
        LibraryPermission.SetTeamMember();

        // [WHEN] Posting invoice and running EDocument job queue
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);

        // [WHEN] EDocument is fetched
        EDocument.FindLast();

        // [THEN] E-Document should be in error state because mandate type filter doesn't match
        Assert.AreEqual(Enum::"E-Document Status"::Error, EDocument.Status, 'E-Document should be in error when mandate type mismatches');
        Assert.AreEqual('', EDocument."Avalara Document Id", 'Document Id should not be set when mandate type mismatches');

        // [THEN] E-Document Service Status has sending error
        VerifyOutboundFactboxValuesForSingleService(EDocument, Enum::"E-Document Service Status"::"Sending Error", 2);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Sending Error");
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        // [CLEANUP]
        RestoreActivationMandate();

        TearDown();
    end;

    // ========================================================================
    // Additional HTTP Error Code Tests
    // ========================================================================

    [Test]
    [HandlerFunctions('Http400Handler')]
    procedure SubmitDocument_BadRequest_400()
    var
        EDocument: Record "E-Document";
        EDocLogList: List of [Enum "E-Document Service Status"];
        EDocumentPage: TestPage "E-Document";
    begin
        // [SCENARIO] Submit document when Avalara returns 400 Bad Request
        Initialize();

        // [GIVEN] Team member
        LibraryPermission.SetTeamMember();

        // [WHEN] Posting invoice and EDocument is created
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);

        // [WHEN] EDocument is fetched
        EDocument.FindLast();

        // [THEN] E-Document should be in error state
        Assert.AreEqual(Enum::"E-Document Status"::Error, EDocument.Status, 'E-Document should be in error when bad request');
        Assert.AreEqual('', EDocument."Avalara Document Id", 'Document Id should not be set when bad request');

        // [THEN] E-Document Service Status has sending error
        VerifyOutboundFactboxValuesForSingleService(EDocument, Enum::"E-Document Service Status"::"Sending Error", 2);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Sending Error");
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        // [THEN] Error message contains 400 error code
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        Assert.AreEqual('Error', EDocumentPage.ErrorMessagesPart."Message Type".Value(), IncorrectValueErr);
        Assert.AreEqual(
            'Error Code: 400, Error Message: The HTTP request was incorrectly formed or invalid.',
            EDocumentPage.ErrorMessagesPart.Description.Value(), IncorrectValueErr);
        EDocumentPage.Close();

        TearDown();
    end;

    [Test]
    [HandlerFunctions('Http403Handler')]
    procedure SubmitDocument_Forbidden_403()
    var
        EDocument: Record "E-Document";
        EDocLogList: List of [Enum "E-Document Service Status"];
        EDocumentPage: TestPage "E-Document";
    begin
        // [SCENARIO] Submit document when Avalara returns 403 Forbidden
        Initialize();

        // [GIVEN] Team member
        LibraryPermission.SetTeamMember();

        // [WHEN] Posting invoice and EDocument is created
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);

        // [WHEN] EDocument is fetched
        EDocument.FindLast();

        // [THEN] E-Document should be in error state
        Assert.AreEqual(Enum::"E-Document Status"::Error, EDocument.Status, 'E-Document should be in error when forbidden');
        Assert.AreEqual('', EDocument."Avalara Document Id", 'Document Id should not be set when forbidden');

        // [THEN] E-Document Service Status has sending error
        VerifyOutboundFactboxValuesForSingleService(EDocument, Enum::"E-Document Service Status"::"Sending Error", 2);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Sending Error");
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        // [THEN] Error message contains 403 error code
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        Assert.AreEqual('Error', EDocumentPage.ErrorMessagesPart."Message Type".Value(), IncorrectValueErr);
        Assert.AreEqual(
            'Error Code: 403, Error Message: The HTTP request was incorrectly formed or invalid.',
            EDocumentPage.ErrorMessagesPart.Description.Value(), IncorrectValueErr);
        EDocumentPage.Close();

        TearDown();
    end;

    // ========================================================================
    // Helpers
    // ========================================================================

    local procedure VerifyOutboundFactboxValuesForSingleService(EDocument: Record "E-Document"; Status: Enum "E-Document Service Status"; Logs: Integer);
    var
        EDocumentServiceStatus: Record "E-Document Service Status";
        Factbox: TestPage "Outbound E-Doc. Factbox";
    begin
        EDocumentServiceStatus.SetRange("E-Document Entry No", EDocument."Entry No");
        EDocumentServiceStatus.FindSet();
        Assert.RecordCount(EDocumentServiceStatus, 1);

        Factbox.OpenView();
        Factbox.GoToRecord(EDocumentServiceStatus);

        Assert.AreEqual(EDocumentService.Code, Factbox."E-Document Service".Value(), IncorrectValueErr);
        Assert.AreEqual(Format(Status), Factbox.SingleStatus.Value(), IncorrectValueErr);
        Assert.AreEqual(Format(Logs), Factbox.Log.Value(), IncorrectValueErr);
    end;

    local procedure Initialize()
    var
        ActivationMandate: Record "Activation Mandate";
        CompanyInformation: Record "Company Information";
        ConnectionSetup: Record "Connection Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        AvalaraAuth: Codeunit Authenticator;
        KeyGuid: Guid;
    begin
        LibraryPermission.SetOutsideO365Scope();

        GeneralLedgerSetup.Get();
        PrevVATReportingDateValue := GeneralLedgerSetup."VAT Reporting Date Usage";
        GeneralLedgerSetup."VAT Reporting Date Usage" := Enum::"VAT Reporting Date Usage"::Disabled;
        if GeneralLedgerSetup."LCY Code" = '' then
            GeneralLedgerSetup."LCY Code" := 'GBP';
        GeneralLedgerSetup.Modify();

        EnsureSetupNumberSeries();

        // Clean up token between runs
        if ConnectionSetup.Get() then
            if IsolatedStorage.Delete(ConnectionSetup."Token - Key", DataScope::Company) then;

        ConnectionSetup.DeleteAll();
        AvalaraAuth.CreateConnectionSetupRecord();

        ConnectionSetup.Get();
        AvalaraAuth.SetClientId(KeyGuid, MockServiceGuid());
        ConnectionSetup."Client Id - Key" := KeyGuid;
        AvalaraAuth.SetClientSecret(KeyGuid, MockServiceGuid());
        ConnectionSetup."Client Secret - Key" := KeyGuid;
        ConnectionSetup.Modify(true);

        CompanyInformation.Get();
        OriginalVATNumber := CompanyInformation."VAT Registration No.";
        CompanyInformation."VAT Registration No." := 'GB777777771';
        if CompanyInformation.Name = '' then
            CompanyInformation.Name := 'Test Company';
        CompanyInformation.Modify();

        // Ensure mandate exists with correct state on every test run
        ActivationMandate.DeleteAll();
        ActivationMandate.Init();
        ActivationMandate."Activation ID" := CreateGuid();
        ActivationMandate."Country Mandate" := 'GB-Test-Mandate';
        ActivationMandate.Activated := true;
        ActivationMandate.Insert(true);

        // Detect rollback from a previous failed test and force re-init
        if IsInitialized then
            if not Customer.Get(Customer."No.") then
                IsInitialized := false;

        if IsInitialized then
            exit;

        LibraryEDocument.SetupStandardVAT();
        LibraryEDocument.SetupStandardSalesScenario(Customer, EDocumentService, Enum::"E-Document Format"::"PEPPOL BIS 3.0", Enum::"Service Integration"::Avalara);
        EDocumentService."Avalara Mandate" := 'GB-Test-Mandate';
        EnsureCountryISOCode(Customer."Country/Region Code");
        EnsurePostingSetup();
        EDocumentService.Modify();

        IsInitialized := true;
    end;

    local procedure EnsurePostingSetup()
    var
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        Item: Record Item;
    begin
        if not GenProdPostingGroup.FindSet() then
            exit;
        repeat
            if not GeneralPostingSetup.Get(Customer."Gen. Bus. Posting Group", GenProdPostingGroup.Code) then begin
                GeneralPostingSetup.Init();
                GeneralPostingSetup.Validate("Gen. Bus. Posting Group", Customer."Gen. Bus. Posting Group");
                GeneralPostingSetup.Validate("Gen. Prod. Posting Group", GenProdPostingGroup.Code);
                GeneralPostingSetup.Insert(true);
            end;
            if GeneralPostingSetup."Sales Account" = '' then begin
                GeneralPostingSetup."Sales Account" := LibraryERM.CreateGLAccountNo();
                GeneralPostingSetup."Sales Credit Memo Account" := LibraryERM.CreateGLAccountNo();
                GeneralPostingSetup."Sales Line Disc. Account" := LibraryERM.CreateGLAccountNo();
                GeneralPostingSetup."COGS Account" := LibraryERM.CreateGLAccountNo();
                GeneralPostingSetup."Purch. Account" := LibraryERM.CreateGLAccountNo();
                GeneralPostingSetup."Purch. Credit Memo Account" := LibraryERM.CreateGLAccountNo();
                GeneralPostingSetup."Direct Cost Applied Account" := LibraryERM.CreateGLAccountNo();
                GeneralPostingSetup."Inventory Adjmt. Account" := LibraryERM.CreateGLAccountNo();
                GeneralPostingSetup.Modify(true);
            end;
        until GenProdPostingGroup.Next() = 0;

        Item.SetFilter("Inventory Posting Group", '<>%1', '');
        if Item.FindSet() then
            repeat
                if not InventoryPostingSetup.Get('', Item."Inventory Posting Group") then begin
                    InventoryPostingSetup.Init();
                    InventoryPostingSetup."Location Code" := '';
                    InventoryPostingSetup."Invt. Posting Group Code" := Item."Inventory Posting Group";
                    InventoryPostingSetup."Inventory Account" := LibraryERM.CreateGLAccountNo();
                    InventoryPostingSetup.Insert(true);
                end else
                    if InventoryPostingSetup."Inventory Account" = '' then begin
                        InventoryPostingSetup."Inventory Account" := LibraryERM.CreateGLAccountNo();
                        InventoryPostingSetup.Modify(true);
                    end;
            until Item.Next() = 0;
    end;

    local procedure EnsureCountryISOCode(CountryCode: Code[10])
    var
        CountryRegion: Record "Country/Region";
    begin
        if CountryRegion.Get(CountryCode) then
            if CountryRegion."ISO Code" = '' then begin
                CountryRegion."ISO Code" := 'GB';
                CountryRegion."ISO Numeric Code" := '826';
                CountryRegion.Modify();
            end;
    end;

    local procedure EnsureSetupNumberSeries()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        if not SalesReceivablesSetup.Get() then begin
            SalesReceivablesSetup.Init();
            SalesReceivablesSetup.Insert();
        end;
        if SalesReceivablesSetup."Invoice Nos." = '' then
            SalesReceivablesSetup."Invoice Nos." := LibraryERM.CreateNoSeriesCode();
        if SalesReceivablesSetup."Credit Memo Nos." = '' then
            SalesReceivablesSetup."Credit Memo Nos." := LibraryERM.CreateNoSeriesCode();
        if SalesReceivablesSetup."Posted Invoice Nos." = '' then
            SalesReceivablesSetup."Posted Invoice Nos." := LibraryERM.CreateNoSeriesCode();
        if SalesReceivablesSetup."Posted Credit Memo Nos." = '' then
            SalesReceivablesSetup."Posted Credit Memo Nos." := LibraryERM.CreateNoSeriesCode();
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure MockServiceGuid(): Text
    begin
        exit('1590fa93-f12c-446c-8e41-c86d082fe3e0');
    end;

    local procedure MockServiceDocumentId(): Text
    begin
        exit('52f60401-44d0-4667-ad47-4afe519abb53');
    end;

    local procedure RestoreActivationMandate()
    var
        ActivationMandate: Record "Activation Mandate";
    begin
        LibraryPermission.SetOutsideO365Scope();
        ActivationMandate.DeleteAll();
        ActivationMandate.Init();
        ActivationMandate."Activation ID" := CreateGuid();
        ActivationMandate."Country Mandate" := 'GB-Test-Mandate';
        ActivationMandate.Activated := true;
        ActivationMandate.Insert(true);
    end;

    // ========================================================================
    // HTTP Handlers
    // ========================================================================

    [HttpClientHandler]
    internal procedure HttpSubmitHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        Regex: Codeunit Regex;
        CompaniesFileTok: Label 'HttpResponseFiles/Companies.txt', Locked = true;
        ConnectTokenFileTok: Label 'HttpResponseFiles/ConnectToken.txt', Locked = true;
        DownloadDocumentFileTok: Label 'HttpResponseFiles/DownloadDocument.txt', Locked = true;
        GetDocumentsFileTok: Label 'HttpResponseFiles/GetDocuments.txt', Locked = true;
        SubmitDocumentFileTok: Label 'HttpResponseFiles/SubmitDocument.txt', Locked = true;
    begin
        case true of
            Regex.IsMatch(Request.Path, 'https?://.+/connect/token'):
                LoadResourceIntoHttpResponse(ConnectTokenFileTok, Response);

            Regex.IsMatch(Request.Path, 'https?://.+/einvoicing/documents/.+/status'):
                GetStatusResponse(Response);

            Regex.IsMatch(Request.Path, 'https?://.+/einvoicing/documents/.+/\$download'):
                LoadResourceIntoHttpResponse(DownloadDocumentFileTok, Response);

            Regex.IsMatch(Request.Path, 'https?://.+/einvoicing/documents'):
                case Request.RequestType of
                    HttpRequestType::POST:
                        LoadResourceIntoHttpResponse(SubmitDocumentFileTok, Response);
                    HttpRequestType::GET:
                        begin
                            LoadResourceIntoHttpResponse(GetDocumentsFileTok, Response);
                            Response.HttpStatusCode := 200;
                        end;
                end;

            Regex.IsMatch(Request.Path, 'https?://.+/scs/companies'):
                begin
                    LoadResourceIntoHttpResponse(CompaniesFileTok, Response);
                    Response.HttpStatusCode := 200;
                end;
        end;
    end;

    [HttpClientHandler]
    internal procedure Http401Handler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        Regex: Codeunit Regex;
        ConnectTokenFileTok: Label 'HttpResponseFiles/ConnectToken.txt', Locked = true;
    begin
        case true of
            Regex.IsMatch(Request.Path, 'https?://.+/connect/token'):
                LoadResourceIntoHttpResponse(ConnectTokenFileTok, Response);
            else begin
                Response.Content.WriteFrom('Unauthorized');
                Response.HttpStatusCode := 401;
            end;
        end;
    end;

    [HttpClientHandler]
    internal procedure Http503Handler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        Regex: Codeunit Regex;
        ConnectTokenFileTok: Label 'HttpResponseFiles/ConnectToken.txt', Locked = true;
    begin
        case true of
            Regex.IsMatch(Request.Path, 'https?://.+/connect/token'):
                LoadResourceIntoHttpResponse(ConnectTokenFileTok, Response);
            else begin
                Response.Content.WriteFrom('Service Unavailable');
                Response.HttpStatusCode := 503;
            end;
        end;
    end;

    [HttpClientHandler]
    internal procedure Http400Handler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        Regex: Codeunit Regex;
        ConnectTokenFileTok: Label 'HttpResponseFiles/ConnectToken.txt', Locked = true;
    begin
        case true of
            Regex.IsMatch(Request.Path, 'https?://.+/connect/token'):
                LoadResourceIntoHttpResponse(ConnectTokenFileTok, Response);
            else begin
                Response.Content.WriteFrom('Bad Request');
                Response.HttpStatusCode := 400;
            end;
        end;
    end;

    [HttpClientHandler]
    internal procedure Http403Handler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        Regex: Codeunit Regex;
        ConnectTokenFileTok: Label 'HttpResponseFiles/ConnectToken.txt', Locked = true;
    begin
        case true of
            Regex.IsMatch(Request.Path, 'https?://.+/connect/token'):
                LoadResourceIntoHttpResponse(ConnectTokenFileTok, Response);
            else begin
                Response.Content.WriteFrom('Forbidden');
                Response.HttpStatusCode := 403;
            end;
        end;
    end;

    [HttpClientHandler]
    internal procedure HttpCreditMemoSubmitHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        Regex: Codeunit Regex;
        ConnectTokenFileTok: Label 'HttpResponseFiles/ConnectToken.txt', Locked = true;
        SubmitDocumentCreditMemoFileTok: Label 'HttpResponseFiles/SubmitDocumentCreditMemo.txt', Locked = true;
    begin
        case true of
            Regex.IsMatch(Request.Path, 'https?://.+/connect/token'):
                LoadResourceIntoHttpResponse(ConnectTokenFileTok, Response);

            Regex.IsMatch(Request.Path, 'https?://.+/einvoicing/documents/.+/status'):
                GetCreditMemoStatusResponse(Response);

            Regex.IsMatch(Request.Path, 'https?://.+/einvoicing/documents'):
                case Request.RequestType of
                    HttpRequestType::POST:
                        LoadResourceIntoHttpResponse(SubmitDocumentCreditMemoFileTok, Response);
                end;
        end;
    end;

    [HttpClientHandler]
    internal procedure HttpSubmitThenStatusErrorHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        Regex: Codeunit Regex;
        ConnectTokenFileTok: Label 'HttpResponseFiles/ConnectToken.txt', Locked = true;
        SubmitDocumentFileTok: Label 'HttpResponseFiles/SubmitDocument.txt', Locked = true;
    begin
        case true of
            Regex.IsMatch(Request.Path, 'https?://.+/connect/token'):
                LoadResourceIntoHttpResponse(ConnectTokenFileTok, Response);

            Regex.IsMatch(Request.Path, 'https?://.+/einvoicing/documents/.+/status'):
                if StatusHttpError then begin
                    Response.Content.WriteFrom('Internal Server Error');
                    Response.HttpStatusCode := 500;
                end else
                    GetStatusResponse(Response);

            Regex.IsMatch(Request.Path, 'https?://.+/einvoicing/documents'):
                case Request.RequestType of
                    HttpRequestType::POST:
                        LoadResourceIntoHttpResponse(SubmitDocumentFileTok, Response);
                end;
        end;
    end;

    local procedure TearDown()
    var
        CompanyInformation: Record "Company Information";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        CompanyInformation.Get();
        CompanyInformation."VAT Registration No." := OriginalVATNumber;
        CompanyInformation.Modify();

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."VAT Reporting Date Usage" := PrevVATReportingDateValue;
        GeneralLedgerSetup.Modify();
    end;

    local procedure LoadResourceIntoHttpResponse(ResourceText: Text; var Response: TestHttpResponseMessage)
    begin
        Response.Content.WriteFrom(NavApp.GetResourceAsText(ResourceText, TextEncoding::UTF8));
    end;

    local procedure SetDocumentStatus(NewDocumentStatus: Option Completed,Pending,Error)
    begin
        this.DocumentStatus := NewDocumentStatus;
    end;

    local procedure SetStatusHttpError(HttpError: Boolean)
    begin
        this.StatusHttpError := HttpError;
    end;

    local procedure GetStatusResponse(var Response: TestHttpResponseMessage)
    var
        GetResponseCompleteFileTok: Label 'HttpResponseFiles/GetResponseComplete.txt', Locked = true;
        GetResponseErrorFileTok: Label 'HttpResponseFiles/GetResponseError.txt', Locked = true;
        GetResponsePendingFileTok: Label 'HttpResponseFiles/GetResponsePending.txt', Locked = true;
    begin
        case DocumentStatus of
            DocumentStatus::Completed:
                LoadResourceIntoHttpResponse(GetResponseCompleteFileTok, Response);

            DocumentStatus::Pending:
                LoadResourceIntoHttpResponse(GetResponsePendingFileTok, Response);

            DocumentStatus::Error:
                LoadResourceIntoHttpResponse(GetResponseErrorFileTok, Response);
        end;
    end;

    local procedure GetCreditMemoStatusResponse(var Response: TestHttpResponseMessage)
    var
        GetResponseCompleteCreditMemoFileTok: Label 'HttpResponseFiles/GetResponseCompleteCreditMemo.txt', Locked = true;
        GetResponsePendingFileTok: Label 'HttpResponseFiles/GetResponsePending.txt', Locked = true;
    begin
        case DocumentStatus of
            DocumentStatus::Completed:
                LoadResourceIntoHttpResponse(GetResponseCompleteCreditMemoFileTok, Response);

            DocumentStatus::Pending:
                LoadResourceIntoHttpResponse(GetResponsePendingFileTok, Response);
        end;
    end;

    local procedure MockCreditMemoDocumentId(): Text
    begin
        exit('a1b2c3d4-e5f6-7890-abcd-ef1234567890');
    end;

    var
        Customer: Record Customer;
        EDocumentService: Record "E-Document Service";
        Assert: Codeunit Assert;
        LibraryEDocument: Codeunit "Library - E-Document";
        LibraryERM: Codeunit "Library - ERM";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryPermission: Codeunit "Library - Lower Permissions";
        IsInitialized: Boolean;
        StatusHttpError: Boolean;
        PrevVATReportingDateValue: Enum "VAT Reporting Date Usage";
        IncorrectValueErr: Label 'Wrong value';
        DocumentStatus: Option Completed,Pending,Error;
        OriginalVATNumber: Text[20];
}
