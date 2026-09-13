// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.SalesFR;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Setup;
#if CLEAN30
using System.Environment.Configuration;
using System.Reflection;
#endif
using System.TestLibraries.Utilities;

codeunit 148004 "ERM Sales Report"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales] [Report]
        isInitialized := false;
    end;

    var
        CompanyInformation: Record "Company Information";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
#if CLEAN30
        Assert: Codeunit Assert;
#endif
        isInitialized: Boolean;
#if CLEAN30
        SalesFRAppIdTok: Label '8df591a3-d767-4475-8bff-44b8b5527477', Locked = true;
#endif

    [Test]
    [HandlerFunctions('StandardSalesInvoiceRequestPageHandler')]
    procedure StandardSalesInvoice_HasSirenNo()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
    begin
        // [FEATURE] [Sales Invoice]
        // [SCENARIO 467032] Test Report "Standard Sales - Invoice FR" with Customer having SIREN No.
        Initialize();

        // [GIVEN] A Customer with a Siren No.
        CreateCustomerWithSirenNo(Customer);

        // [GIVEN] A Sales Invoice for this Customer
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer."No.");

        // [GIVEN] Posted Sales Invoice
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.SetRecFilter();

        // [WHEN] Run report "Standard Sales - Invoice FR" for Posted Sales Invoice
        LibraryVariableStorage.Enqueue(false); // DisplayShipmentInformation
#if CLEAN30
        Report.Run(Report::"Standard Sales - Invoice", true, false, SalesInvoiceHeader);
#else
        Report.Run(Report::"Standard Sales - Invoice FR", true, false, SalesInvoiceHeader);
#endif

        // [THEN] Report DataSet contains Customer."SIREN No." with caption
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('CustomerSirenNo', Customer.GetSIRENNoWithCaptionFR());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DraftSalesInvoiceRequestPageHandler')]
    procedure StandardSalesDraftInvoice_HasSirenNo()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
    begin
        // [FEATURE] [Sales Draft Invoice]
        // [SCENARIO 467032] Test Report "Stand. Sales-Draft Invoice FR" with Customer having SIREN No.
        Initialize();

        // [GIVEN] A Customer with a Siren No.
        CreateCustomerWithSirenNo(Customer);

        // [GIVEN] A Sales Invoice for this Customer
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer."No.");
        SalesHeader.SetRecFilter();
        Commit();

        // [WHEN] Run report "Stand. Sales-Draft Invoice FR" for Sales Invoice
        LibraryVariableStorage.Enqueue(true); // request page opened expectation
#if CLEAN30
        Report.Run(Report::"Standard Sales - Draft Invoice", true, false, SalesHeader);
#else
        Report.Run(Report::"Stand. Sales-Draft Invoice FR", true, false, SalesHeader);
#endif

        // [THEN] Report DataSet contains Customer."SIREN No." with caption
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('CustomerSirenNo', Customer.GetSIRENNoWithCaptionFR());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StdSalesCrMemoRequestPageHandler')]
    procedure StandardSalesCreditMemo_HasSirenNo()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        Customer: Record Customer;
    begin
        // [FEATURE] [Sales Credit Memo]
        // [SCENARIO 467032] Test Report "Standard Sales-Credit Memo FR" with Customer having SIREN No.
        Initialize();

        // [GIVEN] A Customer with a Siren No.
        CreateCustomerWithSirenNo(Customer);

        // [GIVEN] A Credit Memo for this Customer
        LibrarySales.CreateSalesCreditMemoForCustomerNo(SalesHeader, Customer."No.");

        // [GIVEN] Posted Sales Credit Memo
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesCrMemoHeader.SetRecFilter();

        // [WHEN] Run report "Standard Sales-Credit Memo FR" for Posted Sales Invoice
        LibraryVariableStorage.Enqueue(true); // DisplayShipmentInformation
#if CLEAN30
        Report.Run(Report::"Standard Sales - Credit Memo", true, false, SalesCrMemoHeader);
#else
        Report.Run(Report::"Standard Sales-Credit Memo FR", true, false, SalesCrMemoHeader);
#endif

        // [THEN] Report DataSet contains Customer."SIREN No." with caption
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('CustomerSirenNo', Customer.GetSIRENNoWithCaptionFR());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardSalesInvoiceRequestPageHandler')]
    procedure StandardSalesInvoice_VATPaidOnDebitsTrue()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [FEATURE] [Sales Invoice]
        // [SCENARIO 467032] Test Report "Standard Sales - Invoice FR" with "VAT Paid on Debits" = true.
        Initialize();

        // [GIVEN] Create a Sales Invoice with "VAT Paid on Debits" = true
        CreateSalesInvoiceWithVATPaidOnDebits(SalesHeader, true);

        // [GIVEN] Posted Sales Invoice
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.SetRecFilter();

        // [WHEN] Run report "Standard Sales - Invoice FR" for Posted Sales Invoice
        LibraryVariableStorage.Enqueue(false); // DisplayShipmentInformation
#if CLEAN30
        Report.Run(Report::"Standard Sales - Invoice", true, false, SalesInvoiceHeader);
#else
        Report.Run(Report::"Standard Sales - Invoice FR", true, false, SalesInvoiceHeader);
#endif

        // [THEN] Report DataSet contains a line with "VAT Paid on Debits"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('VATPaidOnDebits_Lbl', SalesInvoiceHeader.FieldCaption("VAT Paid on Debits FR"));
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StandardSalesInvoiceRequestPageHandler')]
    procedure StandardSalesInvoice_VATPaidOnDebitsFalse()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [FEATURE] [Sales Invoice]
        // [SCENARIO 467032] Test Report "Standard Sales - Invoice FR" with "VAT Paid on Debits" = false.
        Initialize();

        // [GIVEN] Create a Sales Invoice with "VAT Paid on Debits" = false
        CreateSalesInvoiceWithVATPaidOnDebits(SalesHeader, false);

        // [GIVEN] Posted Sales Invoice
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.SetRecFilter();

        // [WHEN] Run report "Standard Sales - Invoice FR" for Posted Sales Invoice
        LibraryVariableStorage.Enqueue(false); // DisplayShipmentInformation
#if CLEAN30
        Report.Run(Report::"Standard Sales - Invoice", true, false, SalesInvoiceHeader);
#else
        Report.Run(Report::"Standard Sales - Invoice FR", true, false, SalesInvoiceHeader);
#endif

        // [THEN] Report DataSet doesn't contain a line with "VAT Paid on Debits"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('VATPaidOnDebits_Lbl', '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DraftSalesInvoiceRequestPageHandler')]
    procedure StandardSalesDraftInvoice_VATPaidOnDebitsTrue()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales Draft Invoice]
        // [SCENARIO 467032] Test Report "Stand. Sales-Draft Invoice FR" with "VAT Paid on Debits" = true.
        Initialize();

        // [GIVEN] Create a Sales Invoice with "VAT Paid on Debits" = true
        CreateSalesInvoiceWithVATPaidOnDebits(SalesHeader, true);
        SalesHeader.SetRecFilter();
        Commit();

        // [WHEN] Run report "Stand. Sales-Draft Invoice FR" for Sales Invoice
        LibraryVariableStorage.Enqueue(true); // request page opened expectation
#if CLEAN30
        Report.Run(Report::"Standard Sales - Draft Invoice", true, false, SalesHeader);
#else
        Report.Run(Report::"Stand. Sales-Draft Invoice FR", true, false, SalesHeader);
#endif

        // [THEN] Report DataSet contains a line with "VAT Paid on Debits"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('VATPaidOnDebits_Lbl', SalesHeader.FieldCaption("VAT Paid on Debits FR"));
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DraftSalesInvoiceRequestPageHandler')]
    procedure StandardSalesDraftInvoice_VATPaidOnDebitsFalse()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales Draft Invoice]
        // [SCENARIO 467032] Test Report "Stand. Sales-Draft Invoice FR" with "VAT Paid on Debits" = false.
        Initialize();

        // [GIVEN] Create a Sales Invoice with "VAT Paid on Debits" = false
        CreateSalesInvoiceWithVATPaidOnDebits(SalesHeader, false);
        SalesHeader.SetRecFilter();
        Commit();

        // [WHEN] Run report "Stand. Sales-Draft Invoice FR" for Sales Invoice
        LibraryVariableStorage.Enqueue(true); // request page opened expectation
#if CLEAN30
        Report.Run(Report::"Standard Sales - Draft Invoice", true, false, SalesHeader);
#else
        Report.Run(Report::"Stand. Sales-Draft Invoice FR", true, false, SalesHeader);
#endif

        // [THEN] Report DataSet doesn't contain a line with "VAT Paid on Debits"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('VATPaidOnDebits_Lbl', '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StdSalesCrMemoRequestPageHandler')]
    procedure StandardSalesCreditMemo_VATPaidOnDebitsTrue()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // [FEATURE] [Sales Credit Memo]
        // [SCENARIO 467032] Test Report "Standard Sales-Credit Memo FR" with "VAT Paid on Debits" = true.
        Initialize();

        // [GIVEN] Create a Sales Credit Memo with "VAT Paid on Debits" = true
        CreateSalesCreditMemoWithVATPaidOnDebits(SalesHeader, true);

        // [GIVEN] Posted Sales Credit Memo
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesCrMemoHeader.SetRecFilter();

        // [WHEN] Run report "Standard Sales-Credit Memo FR" for Posted Sales Credit Memo
        LibraryVariableStorage.Enqueue(true); // DisplayShipmentInformation
#if CLEAN30
        REPORT.Run(REPORT::"Standard Sales - Credit Memo", true, false, SalesCrMemoHeader);
#else
        REPORT.Run(REPORT::"Standard Sales-Credit Memo FR", true, false, SalesCrMemoHeader);
#endif

        // [THEN] Report DataSet contains a line with "VAT Paid on Debits"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('VATPaidOnDebits_Lbl', SalesCrMemoHeader.FieldCaption("VAT Paid on Debits FR"));
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StdSalesCrMemoRequestPageHandler')]
    procedure StandardSalesCreditMemo_VATPaidOnDebitsFalse()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // [FEATURE] [Sales Credit Memo]
        // [SCENARIO 467032] Test Report "Standard Sales-Credit Memo FR" with "VAT Paid on Debits" = false.
        Initialize();

        // [GIVEN] Create a Sales Credit Memo with "VAT Paid on Debits" = false
        CreateSalesCreditMemoWithVATPaidOnDebits(SalesHeader, false);

        // [GIVEN] Posted Sales Credit Memo
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesCrMemoHeader.SetRecFilter();

        // [WHEN] Run report "Standard Sales-Credit Memo FR" for Posted Sales Credit Memo
        LibraryVariableStorage.Enqueue(true); // DisplayShipmentInformation
#if CLEAN30
        REPORT.Run(REPORT::"Standard Sales - Credit Memo", true, false, SalesCrMemoHeader);
#else
        REPORT.Run(REPORT::"Standard Sales-Credit Memo FR", true, false, SalesCrMemoHeader);
#endif

        // [THEN] Report DataSet doesn't contain a line with "VAT Paid on Debits"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('VATPaidOnDebits_Lbl', '');
        LibraryVariableStorage.AssertEmpty();
    end;

#if CLEAN30
    [Test]
    procedure FRLayoutsAreRegisteredOnW1Reports()
    var
        ReportLayoutList: Record "Report Layout List";
    begin
        // [SCENARIO] The FR layouts are published as layouts of the W1 reports, not of a copied report.
        Initialize();

        // [THEN] Each W1 report has the FR Word layout registered by the Sales FR app
        ReportLayoutList.SetRange("Application ID", SalesFRAppIdTok);

        ReportLayoutList.SetRange("Report ID", Report::"Standard Sales - Invoice");
        ReportLayoutList.SetRange(Name, 'StandardSalesInvoiceFR.docx');
        Assert.RecordIsNotEmpty(ReportLayoutList);

        ReportLayoutList.SetRange("Report ID", Report::"Standard Sales - Credit Memo");
        ReportLayoutList.SetRange(Name, 'StandardSalesCreditMemoFR.docx');
        Assert.RecordIsNotEmpty(ReportLayoutList);

        ReportLayoutList.SetRange("Report ID", Report::"Standard Sales - Draft Invoice");
        ReportLayoutList.SetRange(Name, 'StandardSalesDraftInvoiceFR.docx');
        Assert.RecordIsNotEmpty(ReportLayoutList);
    end;

    [Test]
    procedure FRLayoutIsSelectedAsDefault()
    var
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        SalesFRReportLayouts: Codeunit "Sales FR Report Layouts";
        EmptyGuid: Guid;
    begin
        // [SCENARIO] The FR Word layout is selected as the default layout for the W1 reports.
        Initialize();

        // [WHEN] The layout defaults are applied
        SalesFRReportLayouts.SetDefaultReportLayouts();

        // [THEN] The FR Word layout is the selected layout for each W1 report
        TenantReportLayoutSelection.Get(Report::"Standard Sales - Invoice", CopyStr(CompanyName(), 1, 30), EmptyGuid);
        Assert.AreEqual('StandardSalesInvoiceFR.docx', TenantReportLayoutSelection."Layout Name", 'Wrong layout for the sales invoice.');

        TenantReportLayoutSelection.Get(Report::"Standard Sales - Credit Memo", CopyStr(CompanyName(), 1, 30), EmptyGuid);
        Assert.AreEqual('StandardSalesCreditMemoFR.docx', TenantReportLayoutSelection."Layout Name", 'Wrong layout for the sales credit memo.');

        TenantReportLayoutSelection.Get(Report::"Standard Sales - Draft Invoice", CopyStr(CompanyName(), 1, 30), EmptyGuid);
        Assert.AreEqual('StandardSalesDraftInvoiceFR.docx', TenantReportLayoutSelection."Layout Name", 'Wrong layout for the draft sales invoice.');
    end;

    [Test]
    procedure CustomLayoutsAreRepointedToW1Reports()
    var
        TenantReportLayout: Record "Tenant Report Layout";
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        SalesFRReportLayouts: Codeunit "Sales FR Report Layouts";
        LayoutName: Text[250];
        LayoutAppId: Guid;
        EmptyGuid: Guid;
    begin
        // [SCENARIO] A tenant custom layout built on the copied FR report is moved to the W1 report.
        Initialize();

        // [GIVEN] A tenant custom layout on the copied report 10816, selected for this company
        LayoutName := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(LayoutName));
        LayoutAppId := CreateGuid();
        TenantReportLayout.Init();
        TenantReportLayout."Report ID" := 10816;
        TenantReportLayout.Name := LayoutName;
        TenantReportLayout."App ID" := LayoutAppId;
        TenantReportLayout."Layout Format" := TenantReportLayout."Layout Format"::Word;
        TenantReportLayout.Insert(true);

        if TenantReportLayoutSelection.Get(10816, CopyStr(CompanyName(), 1, 30), EmptyGuid) then
            TenantReportLayoutSelection.Delete(true);
        TenantReportLayoutSelection.Init();
        TenantReportLayoutSelection."Report ID" := 10816;
        TenantReportLayoutSelection."Company Name" := CopyStr(CompanyName(), 1, 30);
        TenantReportLayoutSelection."User ID" := EmptyGuid;
        TenantReportLayoutSelection."App ID" := LayoutAppId;
        TenantReportLayoutSelection."Layout Name" := LayoutName;
        TenantReportLayoutSelection.Insert(true);

        // [WHEN] The custom layouts are re-pointed
        SalesFRReportLayouts.RepointCustomLayouts();

        // [THEN] The layout now belongs to the W1 report
        TenantReportLayout.SetRange(Name, LayoutName);
        TenantReportLayout.SetRange("Report ID", Report::"Standard Sales - Invoice");
        Assert.RecordIsNotEmpty(TenantReportLayout);

        TenantReportLayout.SetRange("Report ID", 10816);
        Assert.RecordIsEmpty(TenantReportLayout);

        // [THEN] The selection follows the layout, so the custom layout is still the one printed
        Assert.IsTrue(
            TenantReportLayoutSelection.Get(Report::"Standard Sales - Invoice", CopyStr(CompanyName(), 1, 30), EmptyGuid),
            'The layout selection was not moved to the W1 report.');
        Assert.AreEqual(LayoutName, TenantReportLayoutSelection."Layout Name", 'The custom layout is no longer selected.');
        Assert.IsFalse(
            TenantReportLayoutSelection.Get(10816, CopyStr(CompanyName(), 1, 30), EmptyGuid),
            'The selection on the retired report was not removed.');
    end;

#endif
    local procedure Initialize()
    begin
        InitializeCompanyInformation();
        LibraryApplicationArea.DisableApplicationAreaSetup();
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM Sales Report");
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM Sales Report");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySales.SetInvoiceRounding(false);

        isInitialized := true;
        Commit();

        LibrarySetupStorage.Save(Database::"General Ledger Setup");
        LibrarySetupStorage.Save(Database::"Sales & Receivables Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM Sales Report");
    end;

    local procedure CreateCustomerWithSirenNo(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("SIREN No. FR", LibraryUtility.GenerateRandomNumericText(9));
        Customer.Modify(true);
    end;

    local procedure CreateSalesInvoiceWithVATPaidOnDebits(var SalesHeader: Record "Sales Header"; VATPaidOnDebits: Boolean)
    begin
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("VAT Paid on Debits FR", VATPaidOnDebits);
        SalesHeader.Modify();
    end;

    local procedure CreateSalesCreditMemoWithVATPaidOnDebits(var SalesHeader: Record "Sales Header"; VATPaidOnDebits: Boolean)
    begin
        LibrarySales.CreateSalesCreditMemoForCustomerNo(SalesHeader, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("VAT Paid on Debits FR", VATPaidOnDebits);
        SalesHeader.Modify();
    end;

    local procedure IsPaymentInfoAvailbleInCompanyInformation(): Boolean
    begin
        exit(
          ((CompanyInformation."Giro No." + CompanyInformation.IBAN + CompanyInformation."Bank Name" + CompanyInformation."Bank Branch No." + CompanyInformation."Bank Account No." + CompanyInformation."SWIFT Code") <> '') or
          CompanyInformation."Allow Blank Payment Info.");
    end;

    local procedure InitializeCompanyInformation()
    begin
        CompanyInformation.Get();
        if not IsPaymentInfoAvailbleInCompanyInformation() then begin
            CompanyInformation."Giro No." := '888-9999';
            CompanyInformation.IBAN := 'GB 12 CPBK 08929965044991';
            CompanyInformation."Bank Branch No." := 'BG99999';
            CompanyInformation."Bank Account No." := '99-99-888';
            CompanyInformation.Modify(false);
        end;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
#if CLEAN30
    procedure StandardSalesInvoiceRequestPageHandler(var StandardSalesInvoice: TestRequestPage "Standard Sales - Invoice")
#else
    procedure StandardSalesInvoiceRequestPageHandler(var StandardSalesInvoice: TestRequestPage "Standard Sales - Invoice FR")
#endif
    begin
        StandardSalesInvoice.DisplayShipmentInformation.SetValue(LibraryVariableStorage.DequeueBoolean());
        StandardSalesInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
#if CLEAN30
    procedure DraftSalesInvoiceRequestPageHandler(var StandardSalesDraftInvoice: TestRequestPage "Standard Sales - Draft Invoice")
#else
    procedure DraftSalesInvoiceRequestPageHandler(var StandardSalesDraftInvoice: TestRequestPage "Stand. Sales-Draft Invoice FR")
#endif
    begin
        // Consume the queued expectation so the test can assert the request page was opened exactly once.
        LibraryVariableStorage.DequeueBoolean();
        StandardSalesDraftInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
#if CLEAN30
    procedure StdSalesCrMemoRequestPageHandler(var StandardSalesCreditMemo: TestRequestPage "Standard Sales - Credit Memo")
#else
    procedure StdSalesCrMemoRequestPageHandler(var StandardSalesCreditMemo: TestRequestPage "Standard Sales-Credit Memo FR")
#endif
    begin
        if StandardSalesCreditMemo.Editable then;
        StandardSalesCreditMemo.DisplayShipmentInformation.SetValue(LibraryVariableStorage.DequeueBoolean());
        StandardSalesCreditMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
        Sleep(200);
    end;
}
