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
using Microsoft.Foundation.Company;
using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Setup;
using System.Threading;
using System.Utilities;

codeunit 133626 "Integration Tests"
{

    Permissions = tabledata "Connection Setup" = rimd,
                  tabledata "E-Document" = r;
    Subtype = Test;
    TestHttpRequestPolicy = AllowOutboundFromHandler;
    TestType = UnitTest;

    [Test]
    [HandlerFunctions('HttpSubmitHandler')]
    procedure SubmitDocument()
    var
        EDocument: Record "E-Document";
        JobQueueEntry: Record "Job Queue Entry";
        EDocLogList: List of [Enum "E-Document Service Status"];
        EDocumentPage: TestPage "E-Document";
    begin
        // Steps:
        // Pending response -> Sent 
        Initialize();

        // [Given] Team member 
        LibraryPermission.SetTeamMember();

        // [When] Posting invoice and EDocument is created
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);

        // [When] EDocument is fetched after running Avalara SubmitDocument 
        EDocument.FindLast();

        // [Then] Document Id has been correctly set on E-Document, parsed from Integration response.
        Assert.AreEqual(MockServiceDocumentId(), EDocument."Avalara Document Id", 'Avalara integration failed to set Document Id on E-Document');
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
        SetDocumentStatus(DocumentStatus::Completed);
        JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"E-Document Get Response");
        LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);

        // [When] EDocument is fetched after running Avalara GetResponse 
        EDocument.FindLast();

        // [Then] E-Document is considered processed
        Assert.AreEqual(Enum::"E-Document Status"::Processed, EDocument.Status, 'E-Document should be set to processed');

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

        TearDown();
    end;

    [Test]
    [HandlerFunctions('HttpSubmitHandler')]
    procedure SubmitDocument_Pending_Sent()
    var
        EDocument: Record "E-Document";
        JobQueueEntry: Record "Job Queue Entry";
        EDocLogList: List of [Enum "E-Document Service Status"];
        EDocumentPage: TestPage "E-Document";
    begin
        // Steps:
        // Pending response -> Pending response -> Sent 
        Initialize();

        // [Given] Team member 
        LibraryPermission.SetTeamMember();

        // [When] Posting invoice and EDocument is created
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);

        // [When] EDocument is fetched after running Avalara SubmitDocument 
        EDocument.FindLast();

        // [Then] Document Id has been correctly set on E-Document, parsed from Integration response
        Assert.AreEqual(MockServiceDocumentId(), EDocument."Avalara Document Id", 'Avalara integration failed to set Document Id on E-Document');

        // [Then] E-Document is pending response as Avalara is async
        Assert.AreEqual(Enum::"E-Document Status"::"In Progress", EDocument.Status, 'E-Document should be set to in progress');

        // [THEN] Open E-Document page
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        Assert.AreEqual(Format(EDocument.Direction::Outgoing), EDocumentPage.Direction.Value(), IncorrectValueErr);
        Assert.AreEqual(EDocument."Document No.", EDocumentPage."Document No.".Value(), IncorrectValueErr);

        // [THEN] E-Document Service Status has pending response
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
        SetDocumentStatus(DocumentStatus::Pending);
        JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"E-Document Get Response");
        LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);

        // [When] EDocument is fetched after running Avalara GetResponse 
        EDocument.FindLast();

        // [Then] E-Document is pending response as Avalara is async
        Assert.AreEqual(Enum::"E-Document Status"::"In Progress", EDocument.Status, 'E-Document should be set to in progress');

        // [THEN] Open E-Document page
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        Assert.AreEqual(Format(EDocument.Direction::Outgoing), EDocumentPage.Direction.Value(), IncorrectValueErr);
        Assert.AreEqual(EDocument."Document No.", EDocumentPage."Document No.".Value(), IncorrectValueErr);

        // [THEN] E-Document Service Status has pending response
        VerifyOutboundFactboxValuesForSingleService(EDocument, Enum::"E-Document Service Status"::"Pending Response", 3);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        // [THEN] E-Document Errors and Warnings has correct status
        Assert.AreEqual('', EDocumentPage.ErrorMessagesPart."Message Type".Value(), IncorrectValueErr);
        Assert.AreEqual('', EDocumentPage.ErrorMessagesPart.Description.Value(), IncorrectValueErr);
        EDocumentPage.Close();

        // [WHEN] Executing Get Response succesfully
        SetDocumentStatus(DocumentStatus::Completed);
        JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"E-Document Get Response");
        LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);

        // [When] EDocument is fetched after running Avalara GetResponse 
        EDocument.FindLast();

        // [Then] E-Document is pending response as Avalara is async
        Assert.AreEqual(Enum::"E-Document Status"::Processed, EDocument.Status, 'E-Document should be set to processed');

        // [THEN] Open E-Document page
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        Assert.AreEqual(Format(EDocument.Direction::Outgoing), EDocumentPage.Direction.Value(), IncorrectValueErr);
        Assert.AreEqual(EDocument."Document No.", EDocumentPage."Document No.".Value(), IncorrectValueErr);

        // [THEN] E-Document Service Status has pending response
        VerifyOutboundFactboxValuesForSingleService(EDocument, Enum::"E-Document Service Status"::Sent, 4);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        EDocLogList.Add(Enum::"E-Document Service Status"::Sent);
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        // [THEN] E-Document Errors and Warnings has correct status
        Assert.AreEqual('', EDocumentPage.ErrorMessagesPart."Message Type".Value(), IncorrectValueErr);
        Assert.AreEqual('', EDocumentPage.ErrorMessagesPart.Description.Value(), IncorrectValueErr);
        EDocumentPage.Close();

        TearDown();
    end;

    [Test]
    [HandlerFunctions('EDocServicesPageHandler,HttpSubmitHandler')]
    procedure SubmitDocument_Error_Sent()
    var
        EDocument: Record "E-Document";
        JobQueueEntry: Record "Job Queue Entry";
        EDocLogList: List of [Enum "E-Document Service Status"];
        EDocumentPage: TestPage "E-Document";
    begin
        // Steps:
        // Pending response -> Error -> Pending response -> Sent 
        Initialize();

        // [Given] Team member 
        LibraryPermission.SetTeamMember();

        // [When] Posting invoice and EDocument is created
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);

        // [When] EDocument is fetched after running Avalara SubmitDocument 
        EDocument.FindLast();

        // [Then] Document Id has been correctly set on E-Document, parsed from Integration response
        Assert.AreEqual(MockServiceDocumentId(), EDocument."Avalara Document Id", 'Avalara integration failed to set Document Id on E-Document');

        // [Then] E-Document is pending response as Avalara is async
        Assert.AreEqual(Enum::"E-Document Status"::"In Progress", EDocument.Status, 'E-Document should be set to in progress');

        // [THEN] Open E-Document page
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        Assert.AreEqual(Format(EDocument.Direction::Outgoing), EDocumentPage.Direction.Value(), IncorrectValueErr);
        Assert.AreEqual(EDocument."Document No.", EDocumentPage."Document No.".Value(), IncorrectValueErr);

        // [THEN] E-Document Service Status has pending response
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
        SetDocumentStatus(DocumentStatus::Error);
        JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"E-Document Get Response");
        LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);

        // [When] EDocument is fetched after running Avalara GetResponse 
        EDocument.FindLast();

        // [Then] E-Document is in error state
        Assert.AreEqual(Enum::"E-Document Status"::Error, EDocument.Status, 'E-Document should be set to error');

        // [THEN] Open E-Document page
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        Assert.AreEqual(Format(EDocument.Direction::Outgoing), EDocumentPage.Direction.Value(), IncorrectValueErr);
        Assert.AreEqual(EDocument."Document No.", EDocumentPage."Document No.".Value(), IncorrectValueErr);

        // [THEN] E-Document Service Status has sending error
        VerifyOutboundFactboxValuesForSingleService(EDocument, Enum::"E-Document Service Status"::"Sending Error", 3);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Sending Error");
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        EDocumentPage.ErrorMessagesPart.First();
        // [THEN] E-Document Errors and Warnings has correct status
        Assert.AreEqual('Error', EDocumentPage.ErrorMessagesPart."Message Type".Value(), IncorrectValueErr);
        Assert.AreEqual('Document started processing', EDocumentPage.ErrorMessagesPart.Description.Value(), IncorrectValueErr);

        EDocumentPage.ErrorMessagesPart.Next();
        // [THEN] E-Document Errors and Warnings has correct status
        Assert.AreEqual('Error', EDocumentPage.ErrorMessagesPart."Message Type".Value(), IncorrectValueErr);
        Assert.AreEqual('Wrong data in send xml', EDocumentPage.ErrorMessagesPart.Description.Value(), IncorrectValueErr);

        EDocumentPage.ErrorMessagesPart.Next();
        // [THEN] E-Document Errors and Warnings has correct status
        Assert.AreEqual('Error', EDocumentPage.ErrorMessagesPart."Message Type".Value(), IncorrectValueErr);
        Assert.AreEqual('An error has been identified in the submitted document.', EDocumentPage.ErrorMessagesPart.Description.Value(), IncorrectValueErr);

        EDocumentPage.Close();

        // Then user manually send 

        EDocument.FindLast();

        // [THEN] Open E-Document page and resend
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        EDocumentPage.Send_Promoted.Invoke();
        EDocumentPage.Close();

        EDocument.FindLast();
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);

        // [Then] E-Document is pending response as Avalara is async
        Assert.AreEqual(Enum::"E-Document Status"::"In Progress", EDocument.Status, 'E-Document should be set to in progress');

        Assert.AreEqual(Format(EDocument.Direction::Outgoing), EDocumentPage.Direction.Value(), IncorrectValueErr);
        Assert.AreEqual(EDocument."Document No.", EDocumentPage."Document No.".Value(), IncorrectValueErr);

        // [THEN] E-Document Service Status has pending response
        VerifyOutboundFactboxValuesForSingleService(EDocument, Enum::"E-Document Service Status"::"Pending Response", 4);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Sending Error");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        // [THEN] E-Document Errors and Warnings has correct status
        Assert.AreEqual('', EDocumentPage.ErrorMessagesPart."Message Type".Value(), IncorrectValueErr);
        Assert.AreEqual('', EDocumentPage.ErrorMessagesPart.Description.Value(), IncorrectValueErr);
        EDocumentPage.Close();

        SetDocumentStatus(DocumentStatus::Completed);

        JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"E-Document Get Response");
        LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);

        // [When] EDocument is fetched after running Avalara GetResponse 

        EDocument.FindLast();

        // [Then] E-Document is pending response as Avalara is async
        Assert.AreEqual(Enum::"E-Document Status"::Processed, EDocument.Status, 'E-Document should be set to processed');

        // [THEN] Open E-Document page
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        Assert.AreEqual(Format(EDocument.Direction::Outgoing), EDocumentPage.Direction.Value(), IncorrectValueErr);
        Assert.AreEqual(EDocument."Document No.", EDocumentPage."Document No.".Value(), IncorrectValueErr);

        // [THEN] E-Document Service Status has pending response
        VerifyOutboundFactboxValuesForSingleService(EDocument, Enum::"E-Document Service Status"::Sent, 5);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Sending Error");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        EDocLogList.Add(Enum::"E-Document Service Status"::Sent);
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        // [THEN] E-Document Errors and Warnings has correct status
        Assert.AreEqual('', EDocumentPage.ErrorMessagesPart."Message Type".Value(), IncorrectValueErr);
        Assert.AreEqual('', EDocumentPage.ErrorMessagesPart.Description.Value(), IncorrectValueErr);
        EDocumentPage.Close();

        TearDown();
    end;

    [Test]
    [HandlerFunctions('ServiceDownHandler')]
    procedure SubmitDocumentAvalaraServiceDown()
    var
        EDocument: Record "E-Document";
        EDocLogList: List of [Enum "E-Document Service Status"];
        EDocumentPage: TestPage "E-Document";
    begin
        Initialize();

        // [Given] Team member 
        LibraryPermission.SetTeamMember();

        // [When] Posting invoice and EDocument is created
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);

        // [When] EDocument is fetched after running Avalara SubmitDocument 
        EDocument.FindLast();

        Assert.AreEqual(Enum::"E-Document Status"::Error, EDocument.Status, 'E-Document should be set to error state when service is down.');
        Assert.AreEqual('', EDocument."Avalara Document Id", 'Document Id on E-Document should not be set.');

        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);

        // [THEN] E-Document has correct error status
        Assert.AreEqual(Format(EDocument.Status::Error), EDocumentPage."Electronic Document Status".Value(), IncorrectValueErr);
        Assert.AreEqual(Format(EDocument.Direction::Outgoing), EDocumentPage.Direction.Value(), IncorrectValueErr);
        Assert.AreEqual(EDocument."Document No.", EDocumentPage."Document No.".Value(), IncorrectValueErr);

        // [THEN] E-Document Service Status has correct error status
        VerifyOutboundFactboxValuesForSingleService(EDocument, Enum::"E-Document Service Status"::"Sending Error", 2);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Sending Error");
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        // [THEN] E-Document Errors and Warnings has correct status
        Assert.AreEqual('Error', EDocumentPage.ErrorMessagesPart."Message Type".Value(), IncorrectValueErr);
        Assert.AreEqual('Error Code: 500, Error Message: The HTTP request is not successful. An internal server error occurred.', EDocumentPage.ErrorMessagesPart.Description.Value(), IncorrectValueErr);

        TearDown();
    end;

    [Test]
    [HandlerFunctions('HttpSubmitHandler')]
    procedure SubmitGetDocuments()
    var
        Currency: Record Currency;
        EDocument: Record "E-Document";
        PurchaseHeader: Record "Purchase Header";
        EDocServicePage: TestPage "E-Document Service";
    begin
        Initialize();
        SetCompanyIdInConnectionSetup(MockCompanyId(), 'Mock Name');

        // Use date and currency exchange rate in document that is loaded
        WorkDate(DMY2Date(8, 4, 2024));
        Currency.Init();
        Currency.Validate(Code, 'XYZ');
        Currency.Insert(true);
        LibraryERM.CreateExchangeRate('XYZ', WorkDate(), 1, 1);

        // Open and close E-Doc page creates auto import job due to setting
        EDocServicePage.OpenView();
        EDocServicePage.GoToRecord(EDocumentService);
        EDocServicePage."Resolve Unit Of Measure".SetValue(false);
        EDocServicePage."Lookup Item Reference".SetValue(true);
        EDocServicePage."Lookup Item GTIN".SetValue(false);
        EDocServicePage."Lookup Account Mapping".SetValue(false);
        EDocServicePage."Validate Line Discount".SetValue(false);
        EDocServicePage.Close();

        // Manually fire job queue job to import
        if EDocument.FindLast() then
            EDocument.SetFilter("Entry No", '>%1', EDocument."Entry No");

        LibraryEDocument.RunImportJob();

        // Assert that we have Purchase Invoice created
#pragma warning disable AA0210
        EDocument.SetRange("Document Type", EDocument."Document Type"::"Purchase Invoice");
        EDocument.SetRange("Bill-to/Pay-to No.", Vendor."No.");
#pragma warning restore AA0210
        EDocument.FindLast();
        PurchaseHeader.Get(EDocument."Document Record ID");
        Assert.AreEqual(Vendor."No.", PurchaseHeader."Buy-from Vendor No.", 'Wrong Vendor');

        TearDown();
    end;

    [Test]
    [HandlerFunctions('SelectCompany,HttpSubmitHandler')]
    procedure OpenCompanyList()
    var
        ConnectionSetup: Record "Connection Setup";
        ConnectionSetupCard: TestPage "Connection Setup Card";
    begin
        Initialize();

        // [GIVEN] O365Full member 
        LibraryPermission.SetO365Full();

        // [THEN] No company has been selected
        ConnectionSetup.Get();
        Assert.AreEqual('', ConnectionSetup."Company Id", 'Has to be empty before selecting company');
        Assert.AreEqual('', ConnectionSetup."Company Name", 'Has to be empty before selecting company');

        // [WHEN] User click SelectCompanyId action on page
        ConnectionSetupCard.OpenView();
        ConnectionSetupCard.SelectCompanyId.Invoke();

        // Selection of company handled by SelectCompany modal handler...

        // [THEN] Company is populated in connection setup 
        ConnectionSetup.Get();
        Assert.AreEqual('610f55f3-76b6-42eb-a697-2b0b2e02a5bf', ConnectionSetup."Company Id", 'Has to be empty before selecting company');
        Assert.AreEqual('MS Business Central Ltd - ELR SBX', ConnectionSetup."Company Name", 'Has to be empty before selecting company');

        TearDown();
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

    local procedure Initialize()
    var
        CompanyInformation: Record "Company Information";
        ConnectionSetup: Record "Connection Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        AvalaraAuth: Codeunit Authenticator;
        KeyGuid: Guid;
    begin
        LibraryPermission.SetOutsideO365Scope();

        GeneralLedgerSetup.Get();
        if GeneralLedgerSetup."LCY Code" = '' then begin
            GeneralLedgerSetup."LCY Code" := 'GBP';
            GeneralLedgerSetup.Modify();
        end;
        PrevVATReportingDateValue := GeneralLedgerSetup."VAT Reporting Date Usage";
        GeneralLedgerSetup."VAT Reporting Date Usage" := Enum::"VAT Reporting Date Usage"::Disabled;
        GeneralLedgerSetup.Modify();

        EnsureSalesSetup();

        // Clean up token between runs
        if ConnectionSetup.Get() then
            if IsolatedStorage.Delete(ConnectionSetup."Token - Key", DataScope::Company) then;

        ConnectionSetup.DeleteAll();
        AvalaraAuth.CreateConnectionSetupRecord();

        ConnectionSetup.Get();
        AvalaraAuth.SetClientId(KeyGuid, SecretText.SecretStrSubstNo(MockServiceGuid()));
        ConnectionSetup."Client Id - Key" := KeyGuid;
        AvalaraAuth.SetClientSecret(KeyGuid, SecretText.SecretStrSubstNo(MockServiceGuid()));
        ConnectionSetup."Client Secret - Key" := KeyGuid;
        ConnectionSetup.Modify(true);

        CompanyInformation.Get();
        if CompanyInformation.Name = '' then begin
            CompanyInformation.Name := 'Test Company';
            CompanyInformation.Modify();
        end;
        OriginalVATNumber := CompanyInformation."VAT Registration No.";
        CompanyInformation."VAT Registration No." := 'GB777777771';
        CompanyInformation.Modify();

        // Verify Customer, Vendor, and EDocumentService still exist (may have been rolled back between tests)
        if IsInitialized then
            if not Customer.Get(Customer."No.") or not Vendor.Get(Vendor."No.") or not EDocumentService.Get(EDocumentService.Code) then
                IsInitialized := false;

        if IsInitialized then
            exit;

        EnsureVATBusinessPostingGroup();
        LibraryEDocument.SetupStandardVAT();
        LibraryEDocument.SetupStandardSalesScenario(Customer, EDocumentService, Enum::"E-Document Format"::"PEPPOL BIS 3.0", Enum::"Service Integration"::Avalara);
        EDocumentService."Avalara Mandate" := 'GB-Test-Mandate';

        LibraryEDocument.SetupStandardPurchaseScenario(Vendor, EDocumentService, Enum::"E-Document Format"::"PEPPOL BIS 3.0", Enum::"Service Integration"::Avalara);
        EDocumentService.Validate("Auto Import", true);
        EDocumentService."Import Minutes between runs" := 10;
        EDocumentService."Import Start Time" := Time();
        EDocumentService.Modify();

        CreateActivationMandate();

        Vendor."VAT Registration No." := 'GB777777771';
        Vendor."Receive E-Document To" := Enum::"E-Document Type"::"Purchase Invoice";
        Vendor.Modify();

        IsInitialized := true;
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

    local procedure MockServiceGuid(): Text
    begin
        exit('1590fa93-f12c-446c-8e41-c86d082fe3e0');
    end;

    local procedure MockServiceDocumentId(): Text
    begin
        exit('52f60401-44d0-4667-ad47-4afe519abb53');
    end;

    local procedure MockCompanyId(): Text[100]
    begin
        exit('610f55f3-76b6-42eb-a697-2b0b2e02a5bf');
    end;

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

    [HttpClientHandler]
    internal procedure HttpSubmitHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        Regex: Codeunit Regex;
        CompaniesFileTok: Label 'Companies.txt', Locked = true;
        ConnectTokenFileTok: Label 'ConnectToken.txt', Locked = true;
        DownloadDocumentFileTok: Label 'DownloadDocument.txt', Locked = true;
        GetDocumentsFileTok: Label 'GetDocuments.txt', Locked = true;
        SubmitDocumentFileTok: Label 'SubmitDocument.txt', Locked = true;
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
        exit(true);
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

    [HttpClientHandler]
    internal procedure ServiceDownHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        Http500FileTok: Label 'Http500.txt', Locked = true;
    begin
        LoadResourceIntoHttpResponse(Http500FileTok, Response);
        Response.HttpStatusCode := 500;
        exit(true);
    end;

    local procedure LoadResourceIntoHttpResponse(ResourceText: Text; var Response: TestHttpResponseMessage)
    begin
        Response.Content.WriteFrom(NavApp.GetResourceAsText(ResourceText, TextEncoding::UTF8));
    end;

    local procedure SetDocumentStatus(NewDocumentStatus: Option Completed,Pending,Error)
    begin
        this.DocumentStatus := NewDocumentStatus;
    end;

    local procedure GetStatusResponse(var Response: TestHttpResponseMessage)
    var
        GetResponseCompleteFileTok: Label 'GetResponseComplete.txt', Locked = true;
        GetResponseErrorFileTok: Label 'GetResponseError.txt', Locked = true;
        GetResponsePendingFileTok: Label 'GetResponsePending.txt', Locked = true;
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

    local procedure CreateActivationMandate()
    var
        ActivationMandate: Record "Activation Mandate";
    begin
        ActivationMandate.SetRange("Country Mandate", 'GB-Test-Mandate');
        ActivationMandate.SetRange("Mandate Type", '');
        ActivationMandate.SetRange("Company Id", '');
        if not ActivationMandate.IsEmpty() then
            exit;

        ActivationMandate.Init();
        ActivationMandate."Activation ID" := CreateGuid();
        ActivationMandate."Country Mandate" := 'GB-Test-Mandate';
        ActivationMandate."Country Code" := 'GB';
        ActivationMandate."Mandate Type" := '';
        ActivationMandate."Company Id" := '';
        ActivationMandate.Activated := true;
        ActivationMandate.Blocked := false;
        ActivationMandate.Insert();
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
        PrevVATReportingDateValue: Enum "VAT Reporting Date Usage";
        IncorrectValueErr: Label 'Wrong value';
        DocumentStatus: Option Completed,Pending,Error;
        OriginalVATNumber: Text[20];
}
