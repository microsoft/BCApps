// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.eServices.EDocument.Service;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Setup;
using System.Threading;
using System.Utilities;

/// <summary>
/// End-to-end tests for the Avalara E-Document Connector covering complete document lifecycles
/// including outbound invoice and credit memo flows (Submit → Pending → Complete), inbound document
/// receive and purchase invoice creation, error recovery with manual resend, service-down scenarios,
/// activation-then-submit workflows, connection setup company selection, send mode toggling,
/// blocked mandate recovery, HTTP status check failures, and message response header population.
/// </summary>
codeunit 133625 "End-to-End Tests"
{
    Permissions = tabledata "Activation Header" = rimd,
                  tabledata "Activation Mandate" = rimd,
                  tabledata "Connection Setup" = rimd,
                  tabledata "E-Document" = r;
    Subtype = Test;
    TestHttpRequestPolicy = AllowOutboundFromHandler;
    TestType = IntegrationTest;

    // ========================================================================
    // E2E: Full Outbound Invoice Lifecycle
    //   Post Invoice → Submit → Pending → Pending → Complete → Processed
    // ========================================================================

    [Test]
    [HandlerFunctions('HttpSubmitHandler')]
    procedure E2E_OutboundInvoice_FullLifecycle()
    var
        EDocument: Record "E-Document";
        JobQueueEntry: Record "Job Queue Entry";
        EDocLogList: List of [Enum "E-Document Service Status"];
        EDocumentPage: TestPage "E-Document";
    begin
        // [SCENARIO] Complete outbound invoice lifecycle: Post → Submit → Pending → Pending → Complete
        Initialize();

        // [GIVEN] Team member
        LibraryPermission.SetTeamMember();

        // [WHEN] Posting invoice and running EDocument job queue
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);
        EDocument.FindLast();

        // [THEN] Document submitted with Pending Response
        Assert.AreEqual(MockServiceDocumentId(), EDocument."Avalara Document Id", 'Document Id should be set after submit');
        Assert.AreEqual(Enum::"E-Document Status"::"In Progress", EDocument.Status, 'Status should be In Progress after submit');
        VerifyOutboundFactboxValuesForSingleService(EDocument, Enum::"E-Document Service Status"::"Pending Response", 2);

        // [WHEN] First GetResponse returns Pending
        SetDocumentStatus(DocumentStatus::Pending);
        JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"E-Document Get Response");
        LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);
        EDocument.FindLast();

        // [THEN] Still In Progress
        Assert.AreEqual(Enum::"E-Document Status"::"In Progress", EDocument.Status, 'Should remain In Progress after first Pending');

        // [WHEN] Second GetResponse returns Pending
        SetDocumentStatus(DocumentStatus::Pending);
        JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"E-Document Get Response");
        LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);
        EDocument.FindLast();

        // [THEN] Still In Progress
        Assert.AreEqual(Enum::"E-Document Status"::"In Progress", EDocument.Status, 'Should remain In Progress after second Pending');

        // [WHEN] Third GetResponse returns Complete
        SetDocumentStatus(DocumentStatus::Completed);
        JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"E-Document Get Response");
        LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);
        EDocument.FindLast();

        // [THEN] E-Document is Processed
        Assert.AreEqual(Enum::"E-Document Status"::Processed, EDocument.Status, 'E-Document should be Processed after Complete');

        // [THEN] Full log chain: Exported → Pending Response → Pending Response → Pending Response → Sent
        VerifyOutboundFactboxValuesForSingleService(EDocument, Enum::"E-Document Service Status"::Sent, 5);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        EDocLogList.Add(Enum::"E-Document Service Status"::Sent);
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        // [THEN] E-Document page shows correct values end-to-end
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        Assert.AreEqual(Format(Enum::"E-Document Status"::Processed), EDocumentPage."Electronic Document Status".Value(), 'Page status should show Processed');
        Assert.AreEqual(Format(EDocument.Direction::Outgoing), EDocumentPage.Direction.Value(), 'Direction should be Outgoing');
        Assert.AreEqual(EDocument."Document No.", EDocumentPage."Document No.".Value(), 'Document No. should match');
        Assert.AreEqual('', EDocumentPage.ErrorMessagesPart."Message Type".Value(), 'No errors should exist');
        Assert.AreEqual('', EDocumentPage.ErrorMessagesPart.Description.Value(), 'No error description should exist');
        EDocumentPage.Close();

        TearDown();
    end;

    // ========================================================================
    // E2E: Full Outbound Credit Memo Lifecycle
    //   Post Credit Memo → Submit → Pending → Complete → Processed
    // ========================================================================

    [Test]
    [HandlerFunctions('HttpCreditMemoSubmitHandler')]
    procedure E2E_OutboundCreditMemo_FullLifecycle()
    var
        EDocument: Record "E-Document";
        JobQueueEntry: Record "Job Queue Entry";
        EDocLogList: List of [Enum "E-Document Service Status"];
    begin
        // [SCENARIO] Complete outbound credit memo lifecycle: Post → Submit → Pending → Complete
        Initialize();

        // [GIVEN] Team member
        LibraryPermission.SetTeamMember();

        // [WHEN] Posting invoice (creates E-Document using credit memo handler) and running job queue
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);
        EDocument.FindLast();

        // [THEN] Credit memo Document Id is set
        Assert.AreEqual(MockCreditMemoDocumentId(), EDocument."Avalara Document Id", 'Credit memo Document Id should be set');
        Assert.AreEqual(Enum::"E-Document Status"::"In Progress", EDocument.Status, 'Status should be In Progress after submit');

        // [WHEN] GetResponse returns Complete
        SetCreditMemoDocumentStatus(CreditMemoDocumentStatus::Completed);
        JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"E-Document Get Response");
        LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);
        EDocument.FindLast();

        // [THEN] Credit memo is Processed
        Assert.AreEqual(Enum::"E-Document Status"::Processed, EDocument.Status, 'Credit memo should be Processed');

        // [THEN] Full log: Exported → Pending Response → Sent
        VerifyOutboundFactboxValuesForSingleService(EDocument, Enum::"E-Document Service Status"::Sent, 3);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        EDocLogList.Add(Enum::"E-Document Service Status"::Sent);
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        TearDown();
    end;

    // ========================================================================
    // E2E: Full Inbound Document Lifecycle
    //   Receive Documents → Download → Create Purchase Invoice
    // ========================================================================

    [Test]
    [HandlerFunctions('HttpSubmitHandler')]
    procedure E2E_InboundDocument_ReceiveAndCreatePurchaseInvoice()
    var
        Currency: Record Currency;
        EDocument: Record "E-Document";
        PurchaseHeader: Record "Purchase Header";
        EDocServicePage: TestPage "E-Document Service";
    begin
        // [SCENARIO] Complete inbound lifecycle: Receive → Download → Create Purchase Invoice
        Initialize();
        SetCompanyIdInConnectionSetup(MockCompanyId(), 'Mock Name');

        // [GIVEN] Currency and exchange rate for downloaded document
        WorkDate(DMY2Date(8, 4, 2024));
        if not Currency.Get('XYZ') then begin
            Currency.Init();
            Currency.Validate(Code, 'XYZ');
            Currency.Insert(true);
        end;
        LibraryERM.CreateExchangeRate('XYZ', WorkDate(), 1, 1);

        // [GIVEN] E-Document service configured for auto-import
        EDocServicePage.OpenView();
        EDocServicePage.GoToRecord(EDocumentService);
        EDocServicePage."Resolve Unit Of Measure".SetValue(false);
        EDocServicePage."Lookup Item Reference".SetValue(true);
        EDocServicePage."Lookup Item GTIN".SetValue(false);
        EDocServicePage."Lookup Account Mapping".SetValue(false);
        EDocServicePage."Validate Line Discount".SetValue(false);
        EDocServicePage.Close();

        // [WHEN] Import job runs
        if EDocument.FindLast() then
            EDocument.SetFilter("Entry No", '>%1', EDocument."Entry No");

        LibraryEDocument.RunImportJob();

        // [THEN] Purchase Invoice E-Document is created
#pragma warning disable AA0210
        EDocument.SetRange("Document Type", EDocument."Document Type"::"Purchase Invoice");
        EDocument.SetRange("Bill-to/Pay-to No.", Vendor."No.");
#pragma warning restore AA0210
        EDocument.FindLast();

        // [THEN] Purchase Header is created and linked
        PurchaseHeader.Get(EDocument."Document Record ID");
        Assert.AreEqual(Vendor."No.", PurchaseHeader."Buy-from Vendor No.", 'Vendor should match on created Purchase Invoice');

        // [THEN] E-Document direction is Incoming
        Assert.AreEqual(Enum::"E-Document Type"::"Purchase Invoice", EDocument."Document Type", 'Document Type should be Purchase Invoice');

        TearDown();
    end;

    // ========================================================================
    // E2E: Submit Error → Manual Resend → Complete
    //   Post → Submit → Pending → Error → Resend → Pending → Complete
    // ========================================================================

    [Test]
    [HandlerFunctions('EDocServicesPageHandler,HttpSubmitHandler')]
    procedure E2E_OutboundInvoice_Error_ManualResend_Complete()
    var
        EDocument: Record "E-Document";
        JobQueueEntry: Record "Job Queue Entry";
        EDocLogList: List of [Enum "E-Document Service Status"];
        EDocumentPage: TestPage "E-Document";
    begin
        // [SCENARIO] Submit → Pending → Error from Avalara → user resends → Pending → Complete
        Initialize();

        // [GIVEN] Team member
        LibraryPermission.SetTeamMember();

        // [WHEN] Posting invoice and running EDocument job queue
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);
        EDocument.FindLast();

        // [THEN] Submitted successfully
        Assert.AreEqual(MockServiceDocumentId(), EDocument."Avalara Document Id", 'Document Id should be set');
        Assert.AreEqual(Enum::"E-Document Status"::"In Progress", EDocument.Status, 'Should be In Progress');

        // [WHEN] GetResponse returns Error
        SetDocumentStatus(DocumentStatus::Error);
        JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"E-Document Get Response");
        LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);
        EDocument.FindLast();

        // [THEN] E-Document in error state
        Assert.AreEqual(Enum::"E-Document Status"::Error, EDocument.Status, 'Should be Error after Error response');

        // [THEN] Error messages are logged
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        EDocumentPage.ErrorMessagesPart.First();
        Assert.AreEqual('Error', EDocumentPage.ErrorMessagesPart."Message Type".Value(), 'Error type should be logged');
        EDocumentPage.Close();

        // [WHEN] User manually resends
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        EDocumentPage.Send_Promoted.Invoke();
        EDocumentPage.Close();

        EDocument.FindLast();

        // [THEN] E-Document is back to In Progress
        Assert.AreEqual(Enum::"E-Document Status"::"In Progress", EDocument.Status, 'Should be In Progress after resend');

        // [WHEN] GetResponse now returns Complete
        SetDocumentStatus(DocumentStatus::Completed);
        JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"E-Document Get Response");
        LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);
        EDocument.FindLast();

        // [THEN] E-Document is Processed
        Assert.AreEqual(Enum::"E-Document Status"::Processed, EDocument.Status, 'Should be Processed after successful resend');

        // [THEN] Full log chain
        VerifyOutboundFactboxValuesForSingleService(EDocument, Enum::"E-Document Service Status"::Sent, 5);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Sending Error");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        EDocLogList.Add(Enum::"E-Document Service Status"::Sent);
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        // [THEN] No errors remain on the page after successful delivery
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        Assert.AreEqual('', EDocumentPage.ErrorMessagesPart."Message Type".Value(), 'No errors should remain after successful resend');
        Assert.AreEqual('', EDocumentPage.ErrorMessagesPart.Description.Value(), 'No error description should remain');
        EDocumentPage.Close();

        TearDown();
    end;

    // ========================================================================
    // E2E: Multiple Sequential Documents Different Outcomes
    //   Doc1: Submit → Complete, Doc2: Submit → Error (independent lifecycle)
    // ========================================================================

    [Test]
    [HandlerFunctions('HttpSubmitHandler')]
    procedure E2E_MultipleDocuments_IndependentLifecycles()
    var
        EDocument1: Record "E-Document";
        EDocument2: Record "E-Document";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [SCENARIO] Two invoices submitted independently: first completes, second stays pending
        Initialize();

        // [GIVEN] Team member
        LibraryPermission.SetTeamMember();

        // [WHEN] Posting first invoice and submitting
        LibraryEDocument.PostInvoice(Customer);
        EDocument1.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument1);
        EDocument1.FindLast();

        // [THEN] First document is in progress
        Assert.AreEqual(Enum::"E-Document Status"::"In Progress", EDocument1.Status, 'First doc should be In Progress');
        Assert.AreEqual(MockServiceDocumentId(), EDocument1."Avalara Document Id", 'First doc should have Document Id');

        // [WHEN] First document completes
        SetDocumentStatus(DocumentStatus::Completed);
        JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"E-Document Get Response");
        LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);
        EDocument1.FindLast();

        // [THEN] First document processed
        Assert.AreEqual(Enum::"E-Document Status"::Processed, EDocument1.Status, 'First doc should be Processed');

        // [WHEN] Posting second invoice
        LibraryEDocument.PostInvoice(Customer);
        EDocument2.FindLast();
        Assert.AreNotEqual(EDocument1."Entry No", EDocument2."Entry No", 'Should be a different E-Document');
        LibraryEDocument.RunEDocumentJobQueue(EDocument2);
        EDocument2.FindLast();

        // [THEN] Second document is in progress independently
        Assert.AreEqual(Enum::"E-Document Status"::"In Progress", EDocument2.Status, 'Second doc should be In Progress');
        Assert.AreEqual(MockServiceDocumentId(), EDocument2."Avalara Document Id", 'Second doc should have Document Id');

        // [THEN] First document status unchanged (re-read by primary key, not FindLast)
        EDocument1.Get(EDocument1."Entry No");
        Assert.AreEqual(Enum::"E-Document Status"::Processed, EDocument1.Status, 'First doc should still be Processed');

        TearDown();
    end;

    // ========================================================================
    // E2E: Service Down During Submit → Recover and Resend
    // ========================================================================

    [Test]
    [HandlerFunctions('ServiceDownThenRecoverHandler')]
    procedure E2E_ServiceDown_ThenRecover()
    var
        EDocument: Record "E-Document";
        EDocLogList: List of [Enum "E-Document Service Status"];
        EDocumentPage: TestPage "E-Document";
    begin
        // [SCENARIO] Avalara service is down during submit → error logged → verify error page state
        Initialize();

        // [GIVEN] Team member with service returning 500
        LibraryPermission.SetTeamMember();
        SetSubmitHttpError(true);

        // [WHEN] Posting invoice and running EDocument job queue
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);
        EDocument.FindLast();

        // [THEN] E-Document in error state
        Assert.AreEqual(Enum::"E-Document Status"::Error, EDocument.Status, 'Should be Error when service is down');
        Assert.AreEqual('', EDocument."Avalara Document Id", 'Document Id should not be set when service is down');

        // [THEN] Error has correct log chain
        VerifyOutboundFactboxValuesForSingleService(EDocument, Enum::"E-Document Service Status"::"Sending Error", 2);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Sending Error");
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        // [THEN] Error message references HTTP 500
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        Assert.AreEqual('Error', EDocumentPage.ErrorMessagesPart."Message Type".Value(), 'Error type should be shown');
        EDocumentPage.Close();

        SetSubmitHttpError(false);
        TearDown();
    end;

    // ========================================================================
    // E2E: Activation Flow → Submit with Activated Mandate → Complete
    // ========================================================================

    [Test]
    [HandlerFunctions('HttpSubmitHandler')]
    procedure E2E_ActivationThenSubmit_Complete()
    var
        ActivationHeader: Record "Activation Header";
        ActivationMandate: Record "Activation Mandate";
        ConnectionSetup: Record "Connection Setup";
        EDocument: Record "E-Document";
        JobQueueEntry: Record "Job Queue Entry";
        ActivationCU: Codeunit Activation;
        ActivationJson: Text;
    begin
        // [SCENARIO] Full flow: Activation populates mandates → Submit document → Complete
        Initialize();

        // [GIVEN] Activation data is loaded from API JSON
        LibraryPermission.SetOutsideO365Scope();
        ActivationHeader.DeleteAll();
        ActivationMandate.DeleteAll();

        ConnectionSetup.Get();
        ConnectionSetup."Company Id" := 'e2e-test-comp';
        ConnectionSetup.Modify();

        ActivationJson := NavApp.GetResourceAsText('HttpResponseFiles/E2E_ActivationData.txt', TextEncoding::UTF8);

        ActivationCU.PopulateFromJson(ActivationJson);

        // [THEN] Mandate was created and activated
        ActivationMandate.SetRange("Country Mandate", 'GB-Test-Mandate');
        ActivationMandate.FindFirst();
        Assert.IsTrue(ActivationMandate.Activated, 'Mandate should be activated from activation flow');

        // [GIVEN] Team member
        LibraryPermission.SetTeamMember();

        // [WHEN] Posting invoice and running EDocument job queue
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);
        EDocument.FindLast();

        // [THEN] Document submitted successfully
        Assert.AreEqual(MockServiceDocumentId(), EDocument."Avalara Document Id", 'Document Id should be set after activation + submit');
        Assert.AreEqual(Enum::"E-Document Status"::"In Progress", EDocument.Status, 'Should be In Progress');

        // [WHEN] GetResponse returns Complete
        SetDocumentStatus(DocumentStatus::Completed);
        JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"E-Document Get Response");
        LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);
        EDocument.FindLast();

        // [THEN] Fully processed
        Assert.AreEqual(Enum::"E-Document Status"::Processed, EDocument.Status, 'Should be Processed after activation + submit + complete');

        // [CLEANUP]
        LibraryPermission.SetOutsideO365Scope();
        ActivationHeader.DeleteAll();
        RestoreActivationMandate();
        ConnectionSetup.Get();
        ConnectionSetup."Company Id" := '';
        ConnectionSetup.Modify();

        TearDown();
    end;

    // ========================================================================
    // E2E: Connection Setup Card → Select Company → Submit
    // ========================================================================

    [Test]
    [HandlerFunctions('SelectCompany,HttpSubmitHandler')]
    procedure E2E_ConnectionSetup_SelectCompany_ThenSubmit()
    var
        ActivationMandate: Record "Activation Mandate";
        ConnectionSetup: Record "Connection Setup";
        EDocument: Record "E-Document";
        JobQueueEntry: Record "Job Queue Entry";
        ConnectionSetupCard: TestPage "Connection Setup Card";
    begin
        // [SCENARIO] User opens Connection Setup, selects company, then submits document
        Initialize();

        // [GIVEN] O365Full member
        LibraryPermission.SetO365Full();

        // [GIVEN] No company selected yet
        ConnectionSetup.Get();
        Assert.AreEqual('', ConnectionSetup."Company Id", 'Company should be empty before selection');

        // [WHEN] User selects company from Connection Setup Card
        ConnectionSetupCard.OpenView();
        ConnectionSetupCard.SelectCompanyId.Invoke();

        // [THEN] Company is populated
        ConnectionSetup.Get();
        Assert.AreEqual('610f55f3-76b6-42eb-a697-2b0b2e02a5bf', ConnectionSetup."Company Id", 'Company Id should be set after selection');
        Assert.AreEqual('MS Business Central Ltd - ELR SBX', ConnectionSetup."Company Name", 'Company Name should be set after selection');

        // [GIVEN] Mandate updated with selected company so SendEDocument lookup succeeds
        ActivationMandate.FindFirst();
        ActivationMandate."Company Id" := CopyStr(ConnectionSetup."Company Id", 1, MaxStrLen(ActivationMandate."Company Id"));
        ActivationMandate.Modify(true);

        // [GIVEN] Team member for document operations
        LibraryPermission.SetTeamMember();

        // [WHEN] Posting invoice and submitting
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);
        EDocument.FindLast();

        // [THEN] Document submitted with selected company context
        Assert.AreEqual(MockServiceDocumentId(), EDocument."Avalara Document Id", 'Document Id should be set after company selection + submit');
        Assert.AreEqual(Enum::"E-Document Status"::"In Progress", EDocument.Status, 'Should be In Progress');

        // [WHEN] Complete
        SetDocumentStatus(DocumentStatus::Completed);
        JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"E-Document Get Response");
        LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);
        EDocument.FindLast();

        // [THEN] Processed
        Assert.AreEqual(Enum::"E-Document Status"::Processed, EDocument.Status, 'Should be Processed');

        TearDown();
    end;

    // ========================================================================
    // E2E: Send Mode Toggle - Sandbox vs Production URL
    // ========================================================================

    [Test]
    [HandlerFunctions('HttpSubmitHandler')]
    procedure E2E_SendModeTest_SubmitSucceeds()
    var
        ConnectionSetup: Record "Connection Setup";
        EDocument: Record "E-Document";
    begin
        // [SCENARIO] With Send Mode set to Test, submit should still succeed via sandbox URLs
        Initialize();

        // [GIVEN] Send Mode set to Test
        LibraryPermission.SetOutsideO365Scope();
        ConnectionSetup.Get();
        ConnectionSetup."Avalara Send Mode" := Enum::"Avalara Send Mode"::Test;
        ConnectionSetup.Modify(true);

        // [GIVEN] Team member
        LibraryPermission.SetTeamMember();

        // [WHEN] Posting invoice and submitting
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);
        EDocument.FindLast();

        // [THEN] Document submitted successfully even in Test mode
        Assert.AreEqual(MockServiceDocumentId(), EDocument."Avalara Document Id", 'Document Id should be set in Test mode');
        Assert.AreEqual(Enum::"E-Document Status"::"In Progress", EDocument.Status, 'Should be In Progress in Test mode');

        // [CLEANUP] Reset to Production
        LibraryPermission.SetOutsideO365Scope();
        ConnectionSetup.Get();
        ConnectionSetup."Avalara Send Mode" := Enum::"Avalara Send Mode"::Production;
        ConnectionSetup.Modify(true);

        TearDown();
    end;

    // ========================================================================
    // E2E: Submit with Blocked Mandate → Unblock → Resend → Complete
    // ========================================================================

    [Test]
    [HandlerFunctions('EDocServicesPageHandler,HttpSubmitHandler')]
    procedure E2E_BlockedMandate_Unblock_Resend_Complete()
    var
        ActivationMandate: Record "Activation Mandate";
        EDocument: Record "E-Document";
        JobQueueEntry: Record "Job Queue Entry";
        EDocLogList: List of [Enum "E-Document Service Status"];
        EDocumentPage: TestPage "E-Document";
    begin
        // [SCENARIO] Mandate is blocked → submit fails → unblock mandate → resend → complete
        Initialize();

        // [GIVEN] Mandate is blocked
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

        // [WHEN] Posting invoice and running EDocument job queue
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);
        EDocument.FindLast();

        // [THEN] E-Document in error state due to blocked mandate
        Assert.AreEqual(Enum::"E-Document Status"::Error, EDocument.Status, 'Should be Error when mandate is blocked');
        Assert.AreEqual('', EDocument."Avalara Document Id", 'Document Id should not be set when mandate is blocked');

        // [WHEN] Admin unblocks the mandate
        LibraryPermission.SetOutsideO365Scope();
        ActivationMandate.FindFirst();
        ActivationMandate.Blocked := false;
        ActivationMandate.Modify(true);

        // [WHEN] User manually resends
        LibraryPermission.SetTeamMember();
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        EDocumentPage.Send_Promoted.Invoke();
        EDocumentPage.Close();

        EDocument.FindLast();

        // [THEN] E-Document is back to In Progress after resend
        Assert.AreEqual(Enum::"E-Document Status"::"In Progress", EDocument.Status, 'Should be In Progress after unblock + resend');
        Assert.AreEqual(MockServiceDocumentId(), EDocument."Avalara Document Id", 'Document Id should be set after resend');

        // [WHEN] GetResponse returns Complete
        SetDocumentStatus(DocumentStatus::Completed);
        JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"E-Document Get Response");
        LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);
        EDocument.FindLast();

        // [THEN] Fully processed
        Assert.AreEqual(Enum::"E-Document Status"::Processed, EDocument.Status, 'Should be Processed after unblock + resend + complete');

        // [THEN] Log chain shows: Exported → Sending Error → Pending Response → Sent
        VerifyOutboundFactboxValuesForSingleService(EDocument, Enum::"E-Document Service Status"::Sent, 4);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Sending Error");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        EDocLogList.Add(Enum::"E-Document Service Status"::Sent);
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        // [CLEANUP]
        RestoreActivationMandate();

        TearDown();
    end;

    // ========================================================================
    // E2E: Submit → HTTP Error on Status Check → Retry Status → Complete
    // ========================================================================

    [Test]
    [HandlerFunctions('HttpSubmitThenStatusErrorHandler')]
    procedure E2E_StatusCheck_HttpError_RetrySucceeds()
    var
        EDocument: Record "E-Document";
        JobQueueEntry: Record "Job Queue Entry";
        EDocLogList: List of [Enum "E-Document Service Status"];
    begin
        // [SCENARIO] Submit succeeds, first status check HTTP 500, retry status returns Complete
        Initialize();

        // [GIVEN] Team member
        LibraryPermission.SetTeamMember();

        // [WHEN] Posting invoice and submitting
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);
        EDocument.FindLast();

        // [THEN] Submission succeeded
        Assert.AreEqual(MockServiceDocumentId(), EDocument."Avalara Document Id", 'Document Id should be set');
        Assert.AreEqual(Enum::"E-Document Status"::"In Progress", EDocument.Status, 'Should be In Progress');

        // [WHEN] GetResponse fails with HTTP 500
        SetStatusHttpError(true);
        JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"E-Document Get Response");
        LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);
        EDocument.FindLast();

        // [THEN] E-Document in error state
        Assert.AreEqual(Enum::"E-Document Status"::Error, EDocument.Status, 'Should be Error after HTTP 500 on status check');

        // [THEN] Log: Exported → Pending Response → Sending Error
        VerifyOutboundFactboxValuesForSingleService(EDocument, Enum::"E-Document Service Status"::"Sending Error", 3);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Sending Error");
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        SetStatusHttpError(false);
        TearDown();
    end;

    // ========================================================================
    // E2E: Verify E-Document Page Shows All Status Transitions
    // ========================================================================

    [Test]
    [HandlerFunctions('HttpSubmitHandler')]
    procedure E2E_PageVerification_AllStatusTransitions()
    var
        EDocument: Record "E-Document";
        JobQueueEntry: Record "Job Queue Entry";
        EDocumentPage: TestPage "E-Document";
    begin
        // [SCENARIO] Verify E-Document page correctly reflects status at each lifecycle stage
        Initialize();

        // [GIVEN] Team member
        LibraryPermission.SetTeamMember();

        // [WHEN] Posting invoice
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);
        EDocument.FindLast();

        // [THEN] Page shows In Progress after submit
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        Assert.AreEqual(Format(Enum::"E-Document Status"::"In Progress"), EDocumentPage."Electronic Document Status".Value(), 'Status should be In Progress on page');
        Assert.AreEqual(Format(EDocument.Direction::Outgoing), EDocumentPage.Direction.Value(), 'Direction should be Outgoing');
        Assert.AreEqual(EDocument."Document No.", EDocumentPage."Document No.".Value(), 'Document No. should match');
        Assert.AreEqual('', EDocumentPage.ErrorMessagesPart."Message Type".Value(), 'No errors after submit');
        EDocumentPage.Close();

        // [WHEN] GetResponse returns Pending
        SetDocumentStatus(DocumentStatus::Pending);
        JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"E-Document Get Response");
        LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);
        EDocument.FindLast();

        // [THEN] Page still shows In Progress
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        Assert.AreEqual(Format(Enum::"E-Document Status"::"In Progress"), EDocumentPage."Electronic Document Status".Value(), 'Status should still be In Progress after Pending');
        Assert.AreEqual('', EDocumentPage.ErrorMessagesPart."Message Type".Value(), 'No errors after Pending');
        EDocumentPage.Close();

        // [WHEN] GetResponse returns Complete
        SetDocumentStatus(DocumentStatus::Completed);
        JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"E-Document Get Response");
        LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);
        EDocument.FindLast();

        // [THEN] Page shows Processed
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        Assert.AreEqual(Format(Enum::"E-Document Status"::Processed), EDocumentPage."Electronic Document Status".Value(), 'Status should be Processed on page');
        Assert.AreEqual('', EDocumentPage.ErrorMessagesPart."Message Type".Value(), 'No errors after Complete');
        EDocumentPage.Close();

        TearDown();
    end;

    // ========================================================================
    // E2E: Message Response Header + Events Populated During GetResponse
    // ========================================================================

    [Test]
    [HandlerFunctions('HttpSubmitHandler')]
    procedure E2E_MessageResponseHeader_PopulatedDuringGetResponse()
    var
        MessageEvent: Record "Avl Message Event";
        MessageResponseHeader: Record "Avl Message Response Header";
        EDocument: Record "E-Document";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [SCENARIO] After GetResponse with Complete, message response header and events should be populated
        Initialize();

        // [GIVEN] Clean message tables
        LibraryPermission.SetOutsideO365Scope();
        MessageResponseHeader.DeleteAll();
        MessageEvent.DeleteAll();

        // [GIVEN] Team member
        LibraryPermission.SetTeamMember();

        // [WHEN] Posting invoice and submitting
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);
        EDocument.FindLast();

        // [THEN] Document Id is set
        Assert.AreEqual(MockServiceDocumentId(), EDocument."Avalara Document Id", 'Document Id should be set');

        // [WHEN] GetResponse returns Complete (the response file has events with messages)
        SetDocumentStatus(DocumentStatus::Completed);
        JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"E-Document Get Response");
        LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);
        EDocument.FindLast();

        // [THEN] E-Document is Processed
        Assert.AreEqual(Enum::"E-Document Status"::Processed, EDocument.Status, 'Should be Processed');

        // [CLEANUP]
        LibraryPermission.SetOutsideO365Scope();
        MessageResponseHeader.DeleteAll();
        MessageEvent.DeleteAll();

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

        LibraryEDocument.SetupStandardPurchaseScenario(Vendor, EDocumentService, Enum::"E-Document Format"::"PEPPOL BIS 3.0", Enum::"Service Integration"::Avalara);
        EDocumentService.Validate("Auto Import", true);
        EDocumentService."Import Minutes between runs" := 10;
        EDocumentService."Import Start Time" := Time();
        EDocumentService.Modify();

        Vendor."VAT Registration No." := 'GB777777771';
        Vendor."Receive E-Document To" := Enum::"E-Document Type"::"Purchase Invoice";
        Vendor.Modify();

        IsInitialized := true;
    end;

    local procedure EnsurePostingSetup()
    var
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        Item: Record Item;
    begin
        // General Posting Setup for Customer's and Vendor's bus. groups
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

            if (Vendor."Gen. Bus. Posting Group" <> '') and (Vendor."Gen. Bus. Posting Group" <> Customer."Gen. Bus. Posting Group") then begin
                if not GeneralPostingSetup.Get(Vendor."Gen. Bus. Posting Group", GenProdPostingGroup.Code) then begin
                    GeneralPostingSetup.Init();
                    GeneralPostingSetup.Validate("Gen. Bus. Posting Group", Vendor."Gen. Bus. Posting Group");
                    GeneralPostingSetup.Validate("Gen. Prod. Posting Group", GenProdPostingGroup.Code);
                    GeneralPostingSetup.Insert(true);
                end;
                if GeneralPostingSetup."Purch. Account" = '' then begin
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
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
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

        if not PurchasesPayablesSetup.Get() then begin
            PurchasesPayablesSetup.Init();
            PurchasesPayablesSetup.Insert();
        end;
        if PurchasesPayablesSetup."Invoice Nos." = '' then
            PurchasesPayablesSetup."Invoice Nos." := LibraryERM.CreateNoSeriesCode();
        if PurchasesPayablesSetup."Credit Memo Nos." = '' then
            PurchasesPayablesSetup."Credit Memo Nos." := LibraryERM.CreateNoSeriesCode();
        if PurchasesPayablesSetup."Posted Invoice Nos." = '' then
            PurchasesPayablesSetup."Posted Invoice Nos." := LibraryERM.CreateNoSeriesCode();
        if PurchasesPayablesSetup."Posted Credit Memo Nos." = '' then
            PurchasesPayablesSetup."Posted Credit Memo Nos." := LibraryERM.CreateNoSeriesCode();
        PurchasesPayablesSetup.Modify(true);
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

    local procedure SetCompanyIdInConnectionSetup(Id: Text[100]; Name: Text[100])
    var
        ConnectionSetup: Record "Connection Setup";
    begin
        ConnectionSetup.Get();
        ConnectionSetup."Company Id" := Id;
        ConnectionSetup."Company Name" := Name;
        ConnectionSetup.Modify(true);
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

    local procedure MockServiceGuid(): Text
    begin
        exit('1590fa93-f12c-446c-8e41-c86d082fe3e0');
    end;

    local procedure MockServiceDocumentId(): Text
    begin
        exit('52f60401-44d0-4667-ad47-4afe519abb53');
    end;

    local procedure MockCreditMemoDocumentId(): Text
    begin
        exit('a1b2c3d4-e5f6-7890-abcd-ef1234567890');
    end;

    local procedure MockCompanyId(): Text[100]
    begin
        exit('610f55f3-76b6-42eb-a697-2b0b2e02a5bf');
    end;

    local procedure SetDocumentStatus(NewDocumentStatus: Option Completed,Pending,Error)
    begin
        this.DocumentStatus := NewDocumentStatus;
    end;

    local procedure SetCreditMemoDocumentStatus(NewStatus: Option Completed,Pending)
    begin
        this.CreditMemoDocumentStatus := NewStatus;
    end;

    local procedure SetSubmitHttpError(HttpError: Boolean)
    begin
        this.SubmitHttpError := HttpError;
    end;

    local procedure SetStatusHttpError(HttpError: Boolean)
    begin
        this.StatusHttpError := HttpError;
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
    internal procedure ServiceDownThenRecoverHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        Regex: Codeunit Regex;
        ConnectTokenFileTok: Label 'HttpResponseFiles/ConnectToken.txt', Locked = true;
        Http500FileTok: Label 'HttpResponseFiles/Http500.txt', Locked = true;
    begin
        case true of
            Regex.IsMatch(Request.Path, 'https?://.+/connect/token'):
                LoadResourceIntoHttpResponse(ConnectTokenFileTok, Response);
            else
                if SubmitHttpError then begin
                    LoadResourceIntoHttpResponse(Http500FileTok, Response);
                    Response.HttpStatusCode := 500;
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

    // ========================================================================
    // Modal Page Handlers
    // ========================================================================

    [ModalPageHandler]
    procedure SelectCompany(var CompanyList: TestPage "Company List")
    begin
        CompanyList.First();
        CompanyList.OK().Invoke();
    end;

    [ModalPageHandler]
    internal procedure EDocServicesPageHandler(var EDocServicesPage: TestPage "E-Document Services")
    begin
        EDocServicesPage.Filter.SetFilter(Code, EDocumentService.Code);
        EDocServicesPage.OK().Invoke();
    end;

    // ========================================================================
    // Response Helpers
    // ========================================================================

    local procedure LoadResourceIntoHttpResponse(ResourceText: Text; var Response: TestHttpResponseMessage)
    begin
        Response.Content.WriteFrom(NavApp.GetResourceAsText(ResourceText, TextEncoding::UTF8));
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
        case CreditMemoDocumentStatus of
            CreditMemoDocumentStatus::Completed:
                LoadResourceIntoHttpResponse(GetResponseCompleteCreditMemoFileTok, Response);

            CreditMemoDocumentStatus::Pending:
                LoadResourceIntoHttpResponse(GetResponsePendingFileTok, Response);
        end;
    end;

    var
        Customer: Record Customer;
        EDocumentService: Record "E-Document Service";
        Vendor: Record Vendor;
        Assert: Codeunit Assert;
        LibraryEDocument: Codeunit "Library - E-Document";
        LibraryERM: Codeunit "Library - ERM";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryPermission: Codeunit "Library - Lower Permissions";
        IsInitialized: Boolean;
        StatusHttpError: Boolean;
        SubmitHttpError: Boolean;
        PrevVATReportingDateValue: Enum "VAT Reporting Date Usage";
        IncorrectValueErr: Label 'Wrong value';
        CreditMemoDocumentStatus: Option Completed,Pending;
        DocumentStatus: Option Completed,Pending,Error;
        OriginalVATNumber: Text[20];
}
