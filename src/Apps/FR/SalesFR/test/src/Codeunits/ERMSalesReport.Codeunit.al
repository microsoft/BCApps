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
        isInitialized: Boolean;

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
        Report.Run(Report::"Standard Sales - Invoice FR", true, false, SalesInvoiceHeader);

        // [THEN] Report DataSet contains Customer."SIREN No." with caption
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('CustomerSirenNo', Customer.GetSIRENNoWithCaptionFR());
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
        Report.Run(Report::"Stand. Sales-Draft Invoice FR", true, false, SalesHeader);

        // [THEN] Report DataSet contains Customer."SIREN No." with caption
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('CustomerSirenNo', Customer.GetSIRENNoWithCaptionFR());
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
        Report.Run(Report::"Standard Sales-Credit Memo FR", true, false, SalesCrMemoHeader);

        // [THEN] Report DataSet contains Customer."SIREN No." with caption
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('CustomerSirenNo', Customer.GetSIRENNoWithCaptionFR());
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
        Report.Run(Report::"Standard Sales - Invoice FR", true, false, SalesInvoiceHeader);

        // [THEN] Report DataSet contains a line with "VAT Paid on Debits"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('VATPaidOnDebits_Lbl', SalesInvoiceHeader.FieldCaption("VAT Paid on Debits FR"));
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
        Report.Run(Report::"Standard Sales - Invoice FR", true, false, SalesInvoiceHeader);

        // [THEN] Report DataSet doesn't contain a line with "VAT Paid on Debits"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('VATPaidOnDebits_Lbl', '');
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
        Report.Run(Report::"Stand. Sales-Draft Invoice FR", true, false, SalesHeader);

        // [THEN] Report DataSet contains a line with "VAT Paid on Debits"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('VATPaidOnDebits_Lbl', SalesHeader.FieldCaption("VAT Paid on Debits FR"));
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
        Report.Run(Report::"Stand. Sales-Draft Invoice FR", true, false, SalesHeader);

        // [THEN] Report DataSet doesn't contain a line with "VAT Paid on Debits"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('VATPaidOnDebits_Lbl', '');
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
        REPORT.Run(REPORT::"Standard Sales-Credit Memo FR", true, false, SalesCrMemoHeader);

        // [THEN] Report DataSet contains a line with "VAT Paid on Debits"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('VATPaidOnDebits_Lbl', SalesCrMemoHeader.FieldCaption("VAT Paid on Debits FR"));
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
        REPORT.Run(REPORT::"Standard Sales-Credit Memo FR", true, false, SalesCrMemoHeader);

        // [THEN] Report DataSet doesn't contain a line with "VAT Paid on Debits"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('VATPaidOnDebits_Lbl', '');
    end;

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
    procedure StandardSalesInvoiceRequestPageHandler(var StandardSalesInvoice: TestRequestPage "Standard Sales - Invoice FR")
    begin
        StandardSalesInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DraftSalesInvoiceRequestPageHandler(var StandardSalesDraftInvoice: TestRequestPage "Stand. Sales-Draft Invoice FR")
    begin
        StandardSalesDraftInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StdSalesCrMemoRequestPageHandler(var StandardSalesCreditMemo: TestRequestPage "Standard Sales-Credit Memo FR")
    begin
        if StandardSalesCreditMemo.Editable then;
        StandardSalesCreditMemo.DisplayShipmentInformation.SetValue(true);
        StandardSalesCreditMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
        Sleep(200);
    end;
}
