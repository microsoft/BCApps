// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.ForNAV;

using Microsoft.eServices.EDocument;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;

codeunit 148221 "Integration Tests"
{
    Access = Internal;
    Subtype = Test;
    TestType = IntegrationTest;

    [Test]
    procedure SubmitDocument()
    var
        Header: Record "Sales Invoice Header";
        EDocument: Record "E-Document";
        EDocumentPage: TestPage "E-Document";
        EDocLogList: List of [Enum "E-Document Service Status"];
    begin
        // Steps:
        // Pending response -> Sent 
        Initialize();

        // [Given] Team member 
        LibraryPermission.SetTeamMember();

        // [When] Posting invoice and EDocument is created
        Header := LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);

        // [When] EDocument is fetched after running ForNAV SubmitDocument 
        EDocument.FindLast();

        // [Then] Document Id has been correctly set on E-Document, parsed from Integration response.
        Assert.AreEqual(Test.MockServiceDocumentId(), EDocument."ForNAV Edoc. ID", 'ForNAV integration failed to set Document Id on E-Document');
        Assert.AreEqual(Enum::"E-Document Status"::"In Progress", EDocument.Status, 'E-Document should be set to in progress');

        // [THEN] Open E-Document page
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        Assert.AreEqual(Format(EDocument.Direction::Outgoing), EDocumentPage.Direction.Value(), IncorrectValueErr);
        Assert.AreEqual(EDocument."Document No.", EDocumentPage."Document No.".Value(), IncorrectValueErr);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        // [THEN] E-Document Errors and Warnings has correct status
        Assert.AreEqual('', EDocumentPage.ErrorMessagesPart."Message Type".Value(), IncorrectValueErr);
        Assert.AreEqual('', EDocumentPage.ErrorMessagesPart.Description.Value(), IncorrectValueErr);
        EDocumentPage.Close();

        // [WHEN] Executing Get Response succesfully
        Test.CreateEvidence(EDocument, true);
        Codeunit.Run(Codeunit::"E-Document Get Response");

        // [When] EDocument is fetched after running ForNAV GetResponse 
        SelectLatestVersion();
        EDocument.FindLast();

        // [Then] E-Document is considered processed
        Assert.AreEqual(Enum::"E-Document Status"::Processed, EDocument.Status, 'E-Document should be set to processed');

        // [THEN] Open E-Document page
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        Assert.AreEqual(Format(EDocument.Direction::Outgoing), EDocumentPage.Direction.Value(), IncorrectValueErr);
        Assert.AreEqual(EDocument."Document No.", EDocumentPage."Document No.".Value(), IncorrectValueErr);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Sent");
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        // [THEN] E-Document Errors and Warnings has correct status
        EDocumentPage.Close();
    end;

    /// <summary>
    /// Test needs MockService running to work. 
    /// </summary>
    [Test]
    procedure SubmitDocument_Pending_Sent()
    var
        EDocument: Record "E-Document";
        EDocumentPage: TestPage "E-Document";
        EDocLogList: List of [Enum "E-Document Service Status"];
    begin
        // Steps:
        // Pending response -> Pending response -> Sent 
        Initialize();
        Test.SetStatusCode(200);

        // [Given] Team member 
        LibraryPermission.SetTeamMember();

        // [When] Posting invoice and EDocument is created
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);

        // [When] EDocument is fetched after running ForNAV SubmitDocument 
        EDocument.FindLast();

        // [Then] Document Id has been correctly set on E-Document, parsed from Integration response
        Assert.AreEqual(Test.MockServiceDocumentId(), EDocument."ForNAV Edoc. ID", 'ForNAV integration failed to set Document Id on E-Document');

        // [Then] E-Document is pending response as ForNAV is async
        Assert.AreEqual(Enum::"E-Document Status"::"In Progress", EDocument.Status, 'E-Document should be set to in progress');

        // [THEN] Open E-Document page
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        Assert.AreEqual(Format(EDocument.Direction::Outgoing), EDocumentPage.Direction.Value(), IncorrectValueErr);
        Assert.AreEqual(EDocument."Document No.", EDocumentPage."Document No.".Value(), IncorrectValueErr);

        // [THEN] E-Document Service Status has pending response
        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        // [THEN] E-Document Errors and Warnings has correct status
        EDocumentPage.Close();


        // [WHEN] Executing Get Response succesfully
        Codeunit.Run(Codeunit::"E-Document Get Response");

        // [When] EDocument is fetched after running ForNAV GetResponse 
        EDocument.FindLast();

        // [Then] E-Document is pending response as ForNAV is async
        Assert.AreEqual(Enum::"E-Document Status"::"In Progress", EDocument.Status, 'E-Document should be set to in progress');

        // [THEN] Open E-Document page
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        Assert.AreEqual(Format(EDocument.Direction::Outgoing), EDocumentPage.Direction.Value(), IncorrectValueErr);
        Assert.AreEqual(EDocument."Document No.", EDocumentPage."Document No.".Value(), IncorrectValueErr);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        // [THEN] E-Document Errors and Warnings has correct status
        EDocumentPage.Close();

        // [WHEN] Executing Get Response succesfully
        Test.CreateEvidence(EDocument, true);
        Codeunit.Run(Codeunit::"E-Document Get Response");

        // [When] EDocument is fetched after running ForNAV GetResponse 
        EDocument.FindLast();

        // [Then] E-Document is pending response as ForNAV is async
        Assert.AreEqual(Enum::"E-Document Status"::Processed, EDocument.Status, 'E-Document should be set to processed');

        // [THEN] Open E-Document page
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        Assert.AreEqual(Format(EDocument.Direction::Outgoing), EDocumentPage.Direction.Value(), IncorrectValueErr);
        Assert.AreEqual(EDocument."Document No.", EDocumentPage."Document No.".Value(), IncorrectValueErr);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        EDocLogList.Add(Enum::"E-Document Service Status"::Sent);
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        // [THEN] E-Document Errors and Warnings has correct status
        EDocumentPage.Close();
    end;

    [Test]
    [HandlerFunctions('EDocServicesPageHandler')]
    procedure SubmitDocument_Error_Sent()
    var
        EDocument: Record "E-Document";
        EDocumentPage: TestPage "E-Document";
        EDocLogList: List of [Enum "E-Document Service Status"];
    begin
        // Steps:
        // Pending response -> Error -> Pending response -> Sent 
        Initialize();
        Test.SetStatusCode(200);

        // [Given] Team member 
        LibraryPermission.SetTeamMember();

        // [When] Posting invoice and EDocument is created
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);

        // [When] EDocument is fetched after running ForNAV SubmitDocument 
        EDocument.FindLast();

        // [Then] Document Id has been correctly set on E-Document, parsed from Integration response
        Assert.AreEqual(Test.MockServiceDocumentId(), EDocument."ForNAV Edoc. ID", 'ForNAV integration failed to set Document Id on E-Document');

        // [Then] E-Document is pending response as ForNAV is async
        Assert.AreEqual(Enum::"E-Document Status"::"In Progress", EDocument.Status, 'E-Document should be set to in progress');

        // [THEN] Open E-Document page
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        Assert.AreEqual(Format(EDocument.Direction::Outgoing), EDocumentPage.Direction.Value(), IncorrectValueErr);
        Assert.AreEqual(EDocument."Document No.", EDocumentPage."Document No.".Value(), IncorrectValueErr);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        // [THEN] E-Document Errors and Warnings has correct status
        EDocumentPage.Close();

        // [WHEN] Executing Get Response succesfully
        test.CreateEvidence(EDocument, false);
        Codeunit.Run(Codeunit::"E-Document Get Response");

        // [When] EDocument is fetched after running ForNAV GetResponse 
        EDocument.FindLast();

        // [Then] E-Document is in error state
        Assert.AreEqual(Enum::"E-Document Status"::Error, EDocument.Status, 'E-Document should be set to error');

        // [THEN] Open E-Document page
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        Assert.AreEqual(Format(EDocument.Direction::Outgoing), EDocumentPage.Direction.Value(), IncorrectValueErr);
        Assert.AreEqual(EDocument."Document No.", EDocumentPage."Document No.".Value(), IncorrectValueErr);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Sending Error");
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        EDocumentPage.ErrorMessagesPart.First();
        // [THEN] E-Document Errors and Warnings has correct status
        Assert.AreEqual('Error', EDocumentPage.ErrorMessagesPart."Message Type".Value(), IncorrectValueErr);
        Assert.AreEqual('Rejected', EDocumentPage.ErrorMessagesPart.Description.Value(), IncorrectValueErr);

        EDocumentPage.Close();

        // Then user manually send 
        Test.CreateEvidence(EDocument, true);
        EDocument.FindLast();

        // [THEN] Open E-Document page and resend
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        EDocumentPage.Send_Promoted.Invoke();
        EDocumentPage.Close();

        EDocument.FindLast();
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);

        // [Then] E-Document is pending response as ForNAV is async
        Assert.AreEqual(Enum::"E-Document Status"::"In Progress", EDocument.Status, 'E-Document should be set to in progress');

        Assert.AreEqual(Format(EDocument.Direction::Outgoing), EDocumentPage.Direction.Value(), IncorrectValueErr);
        Assert.AreEqual(EDocument."Document No.", EDocumentPage."Document No.".Value(), IncorrectValueErr);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Sending Error");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        // [THEN] E-Document Errors and Warnings has correct status
        EDocumentPage.Close();

        Codeunit.Run(Codeunit::"E-Document Get Response");

        // [When] EDocument is fetched after running ForNAV GetResponse 

        EDocument.FindLast();

        // [Then] E-Document is pending response as ForNAV is async
        Assert.AreEqual(Enum::"E-Document Status"::Processed, EDocument.Status, 'E-Document should be set to processed');

        // [THEN] Open E-Document page
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        Assert.AreEqual(Format(EDocument.Direction::Outgoing), EDocumentPage.Direction.Value(), IncorrectValueErr);
        Assert.AreEqual(EDocument."Document No.", EDocumentPage."Document No.".Value(), IncorrectValueErr);

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Sending Error");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Pending Response");
        EDocLogList.Add(Enum::"E-Document Service Status"::Sent);
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        // [THEN] E-Document Errors and Warnings has correct status
        EDocumentPage.Close();
    end;

    /// <summary>
    /// Test needs MockService running to work. 
    /// </summary>
    [Test]
    procedure SubmitDocumentForNAVServiceDown()
    var
        EDocument: Record "E-Document";
        EDocumentPage: TestPage "E-Document";
        EDocLogList: List of [Enum "E-Document Service Status"];
    begin
        Initialize();
        Test.SetStatusCode(500);

        // [Given] Team member 
        LibraryPermission.SetTeamMember();

        // [When] Posting invoice and EDocument is created
        LibraryEDocument.PostInvoice(Customer);
        EDocument.FindLast();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);

        // [When] EDocument is fetched after running ForNAV SubmitDocument 
        EDocument.FindLast();

        Assert.AreEqual(Enum::"E-Document Status"::Error, EDocument.Status, 'E-Document should be set to error state when service is down.');
        Assert.AreEqual('', EDocument."ForNAV Edoc. ID", 'Document Id on E-Document should not be set.');

        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);

        // [THEN] E-Document has correct error status
        Assert.AreEqual(Format(EDocument.Status::Error), EDocumentPage."Electronic Document Status".Value(), IncorrectValueErr);
        Assert.AreEqual(Format(EDocument.Direction::Outgoing), EDocumentPage.Direction.Value(), IncorrectValueErr);
        Assert.AreEqual(EDocument."Document No.", EDocumentPage."Document No.".Value(), IncorrectValueErr);

        // [THEN] E-Document Service Status has correct error status

        Clear(EDocLogList);
        EDocLogList.Add(Enum::"E-Document Service Status"::"Exported");
        EDocLogList.Add(Enum::"E-Document Service Status"::"Sending Error");
        LibraryEDocument.AssertEDocumentLogs(EDocument, EDocumentService, EDocLogList);

        // [THEN] E-Document Errors and Warnings has correct status
        Assert.AreEqual('Error', EDocumentPage.ErrorMessagesPart."Message Type".Value(), IncorrectValueErr);
    end;

    /// <summary>
    /// Test needs MockService running to work. 
    /// </summary>
    [Test]
    procedure SubmitGetDocuments()
    var
        EDocument: Record "E-Document";
        PurchaseHeader: Record "Purchase Header";
        // proc: Codeunit "E-Document Processing";
        EDocServicePage: TestPage "E-Document Service";
    begin
        Initialize();
        Test.SetStatusCode(200);
        Test.SetVendorNo(Vendor."No.");

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
        //        EDocument.SetRange("Bill-to/Pay-to No.", Vendor."No.");
#pragma warning restore AA0210
        EDocument.FindLast();
        if PurchaseHeader.Get(EDocument."Document Record ID") then
            Assert.AreEqual(Vendor."No.", PurchaseHeader."Buy-from Vendor No.", 'Wrong Vendor');
    end;

    local procedure Initialize()
    var
        Setup: Record "ForNAV Peppol Setup";
        CompanyInformation: Record "Company Information";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        Test.CreateMockServiceDocumentId();
        LibraryPermission.SetOutsideO365Scope();

        GeneralLedgerSetup.GetRecordOnce();
        GeneralLedgerSetup."VAT Reporting Date Usage" := GeneralLedgerSetup."VAT Reporting Date Usage"::Disabled;
        GeneralLedgerSetup.Modify();

        if IsInitialized then
            exit;

        Test.Init();

        CompanyInformation.Get();
        if CompanyInformation."Name" = '' then
            CompanyInformation.Name := 'Test Company';
        CompanyInformation."VAT Registration No." := 'GB777777771';
        CompanyInformation.Modify();

        LibraryEDocument.SetupStandardVAT();
        EDocumentService.Get(Setup.GetForNAVCode());
        LibraryEDocument.SetupStandardSalesScenario(Customer, EDocumentService);

        LibraryEDocument.SetupStandardPurchaseScenario(Vendor, EDocumentService);
        EDocumentService.Validate("Auto Import", true);
        EDocumentService.Validate("Import Minutes between runs", 10);
        EDocumentService.Validate("Import Start Time", Time());
        EDocumentService.Modify(true);

        Vendor."VAT Registration No." := 'GB777777771';
        Vendor."Receive E-Document To" := Enum::"E-Document Type"::"Purchase Invoice";
        Vendor."Document Sending Profile" := Setup.GetForNAVCode();
        Vendor.Modify();

        Test.SetStatusCode(200);

        IsInitialized := true;
    end;

    [ModalPageHandler]
    internal procedure EDocServicesPageHandler(var EDocServicesPage: TestPage "E-Document Services")
    begin
        EDocServicesPage.Filter.SetFilter(Code, EDocumentService.Code);
        EDocServicesPage.OK().Invoke();
    end;

    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        EDocumentService: Record "E-Document Service";
        LibraryEDocument: Codeunit "Library - E-Document";
        LibraryPermission: Codeunit "Library - Lower Permissions";
        Assert: Codeunit Assert;
        Test: Codeunit "ForNAV Peppol Test";
        IsInitialized: Boolean;
        IncorrectValueErr: Label 'Wrong value';
}