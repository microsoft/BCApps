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
#if not CLEAN30
using System.Environment.Configuration;
#endif
#if CLEAN30
using System.Reflection;
#endif
using System.TestLibraries.Utilities;

codeunit 148004 "ERM Sales Report"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

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
        Assert: Codeunit Assert;
        isInitialized: Boolean;
        SIRENNoWithCaptionTok: Label '%1: %2', Locked = true;
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
        // [SCENARIO 467032] Test Report "Standard Sales - Invoice" with Customer having SIREN No.
        Initialize();

        // [GIVEN] A Customer with a Siren No.
        CreateCustomerWithSirenNo(Customer);

        // [GIVEN] A Sales Invoice for this Customer
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer."No.");

        // [GIVEN] Posted Sales Invoice
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.SetRecFilter();

        // [WHEN] Run report "Standard Sales - Invoice" for Posted Sales Invoice
        LibraryVariableStorage.Enqueue(false); // DisplayShipmentInformation
        Report.Run(Report::"Standard Sales - Invoice", true, false, SalesInvoiceHeader);

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
        // [SCENARIO 467032] Test Report "Standard Sales - Draft Invoice" with Customer having SIREN No.
        Initialize();

        // [GIVEN] A Customer with a Siren No.
        CreateCustomerWithSirenNo(Customer);

        // [GIVEN] A Sales Invoice for this Customer
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer."No.");
        SalesHeader.SetRecFilter();
        Commit();

        // [WHEN] Run report "Standard Sales - Draft Invoice" for Sales Invoice
        LibraryVariableStorage.Enqueue(true); // request page opened expectation
        Report.Run(Report::"Standard Sales - Draft Invoice", true, false, SalesHeader);

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
        // [SCENARIO 467032] Test Report "Standard Sales - Credit Memo" with Customer having SIREN No.
        Initialize();

        // [GIVEN] A Customer with a Siren No.
        CreateCustomerWithSirenNo(Customer);

        // [GIVEN] A Credit Memo for this Customer
        LibrarySales.CreateSalesCreditMemoForCustomerNo(SalesHeader, Customer."No.");

        // [GIVEN] Posted Sales Credit Memo
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesCrMemoHeader.SetRecFilter();

        // [WHEN] Run report "Standard Sales - Credit Memo" for Posted Sales Invoice
        LibraryVariableStorage.Enqueue(true); // DisplayShipmentInformation
        Report.Run(Report::"Standard Sales - Credit Memo", true, false, SalesCrMemoHeader);

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
        // [SCENARIO 467032] Test Report "Standard Sales - Invoice" with "VAT Paid on Debits" = true.
        Initialize();

        // [GIVEN] Create a Sales Invoice with "VAT Paid on Debits" = true
        CreateSalesInvoiceWithVATPaidOnDebits(SalesHeader, true);

        // [GIVEN] Posted Sales Invoice
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.SetRecFilter();

        // [WHEN] Run report "Standard Sales - Invoice" for Posted Sales Invoice
        LibraryVariableStorage.Enqueue(false); // DisplayShipmentInformation
        Report.Run(Report::"Standard Sales - Invoice", true, false, SalesInvoiceHeader);

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
        // [SCENARIO 467032] Test Report "Standard Sales - Invoice" with "VAT Paid on Debits" = false.
        Initialize();

        // [GIVEN] Create a Sales Invoice with "VAT Paid on Debits" = false
        CreateSalesInvoiceWithVATPaidOnDebits(SalesHeader, false);

        // [GIVEN] Posted Sales Invoice
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.SetRecFilter();

        // [WHEN] Run report "Standard Sales - Invoice" for Posted Sales Invoice
        LibraryVariableStorage.Enqueue(false); // DisplayShipmentInformation
        Report.Run(Report::"Standard Sales - Invoice", true, false, SalesInvoiceHeader);

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
        // [SCENARIO 467032] Test Report "Standard Sales - Draft Invoice" with "VAT Paid on Debits" = true.
        Initialize();

        // [GIVEN] Create a Sales Invoice with "VAT Paid on Debits" = true
        CreateSalesInvoiceWithVATPaidOnDebits(SalesHeader, true);
        SalesHeader.SetRecFilter();
        Commit();

        // [WHEN] Run report "Standard Sales - Draft Invoice" for Sales Invoice
        LibraryVariableStorage.Enqueue(true); // request page opened expectation
        Report.Run(Report::"Standard Sales - Draft Invoice", true, false, SalesHeader);

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
        // [SCENARIO 467032] Test Report "Standard Sales - Draft Invoice" with "VAT Paid on Debits" = false.
        Initialize();

        // [GIVEN] Create a Sales Invoice with "VAT Paid on Debits" = false
        CreateSalesInvoiceWithVATPaidOnDebits(SalesHeader, false);
        SalesHeader.SetRecFilter();
        Commit();

        // [WHEN] Run report "Standard Sales - Draft Invoice" for Sales Invoice
        LibraryVariableStorage.Enqueue(true); // request page opened expectation
        Report.Run(Report::"Standard Sales - Draft Invoice", true, false, SalesHeader);

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
        // [SCENARIO 467032] Test Report "Standard Sales - Credit Memo" with "VAT Paid on Debits" = true.
        Initialize();

        // [GIVEN] Create a Sales Credit Memo with "VAT Paid on Debits" = true
        CreateSalesCreditMemoWithVATPaidOnDebits(SalesHeader, true);

        // [GIVEN] Posted Sales Credit Memo
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesCrMemoHeader.SetRecFilter();

        // [WHEN] Run report "Standard Sales - Credit Memo" for Posted Sales Credit Memo
        LibraryVariableStorage.Enqueue(true); // DisplayShipmentInformation
        REPORT.Run(REPORT::"Standard Sales - Credit Memo", true, false, SalesCrMemoHeader);

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
        // [SCENARIO 467032] Test Report "Standard Sales - Credit Memo" with "VAT Paid on Debits" = false.
        Initialize();

        // [GIVEN] Create a Sales Credit Memo with "VAT Paid on Debits" = false
        CreateSalesCreditMemoWithVATPaidOnDebits(SalesHeader, false);

        // [GIVEN] Posted Sales Credit Memo
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesCrMemoHeader.SetRecFilter();

        // [WHEN] Run report "Standard Sales - Credit Memo" for Posted Sales Credit Memo
        LibraryVariableStorage.Enqueue(true); // DisplayShipmentInformation
        REPORT.Run(REPORT::"Standard Sales - Credit Memo", true, false, SalesCrMemoHeader);

        // [THEN] Report DataSet doesn't contain a line with "VAT Paid on Debits"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('VATPaidOnDebits_Lbl', '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure StandardSalesInvoice_UsesFRFieldsPerDocument()
    begin
        // [SCENARIO] Each invoice prints the active FR values, including cleared values, without synchronizing legacy fields.
        VerifyInvoiceFieldSource(true);
    end;

    [Test]
    procedure StandardSalesCreditMemo_UsesFRFieldsPerDocument()
    begin
        // [SCENARIO] Each credit memo prints the active FR values, including cleared values, without synchronizing legacy fields.
        VerifyCreditMemoFieldSource(true);
    end;

    [Test]
    procedure StandardSalesDraftInvoice_UsesFRFieldsPerDocument()
    begin
        // [SCENARIO] Each draft invoice prints the active FR values, including cleared values, without synchronizing legacy fields.
        VerifyDraftInvoiceFieldSource(true);
    end;

#if not CLEAN30
    [Test]
    procedure StandardSalesInvoice_UsesLegacyFieldsWhenFeatureDisabled()
    begin
        // [SCENARIO] Disabled Sales FR preserves each invoice's legacy values even when the FR fields differ.
        VerifyInvoiceFieldSource(false);
    end;

    [Test]
    procedure StandardSalesCreditMemo_UsesLegacyFieldsWhenFeatureDisabled()
    begin
        // [SCENARIO] Disabled Sales FR preserves each credit memo's legacy values even when the FR fields differ.
        VerifyCreditMemoFieldSource(false);
    end;

    [Test]
    procedure StandardSalesDraftInvoice_UsesLegacyFieldsWhenFeatureDisabled()
    begin
        // [SCENARIO] Disabled Sales FR preserves each draft invoice's legacy values even when the FR fields differ.
        VerifyDraftInvoiceFieldSource(false);
    end;
#endif

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

#endif
    local procedure Initialize()
    begin
        InitializeCompanyInformation();
        LibraryApplicationArea.DisableApplicationAreaSetup();
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM Sales Report");
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();
        Clear(LibraryReportDataset);
#if not CLEAN30
        SetSalesFRFeatureEnabled(true);
#endif

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
        Customer.Validate("SIREN No. FR", CopyStr(LibraryUtility.GenerateRandomNumericText(9), 1, MaxStrLen(Customer."SIREN No. FR")));
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

    local procedure VerifyInvoiceFieldSource(FeatureEnabled: Boolean)
    var
        Customer: array[2] of Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: array[2] of Record "Sales Invoice Header";
        ReportSalesInvoiceHeader: Record "Sales Invoice Header";
        Index: Integer;
    begin
        InitializeReportFieldSource(FeatureEnabled);

        for Index := 1 to ArrayLen(Customer) do begin
            CreateCustomerWithDivergentSirenNo(Customer[Index], Index = 2);
            LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer[Index]."No.");
            SetDivergentVATFields(SalesHeader, Index = 2);
            SalesInvoiceHeader[Index].Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
            SalesInvoiceHeader[Index].TestField("VAT Paid on Debits FR", Index = 2);
        end;
        ReportSalesInvoiceHeader.SetFilter("No.", '%1|%2', SalesInvoiceHeader[1]."No.", SalesInvoiceHeader[2]."No.");
        Commit();

        LibraryReportDataset.RunReportAndLoad(Report::"Standard Sales - Invoice", ReportSalesInvoiceHeader, '');

        for Index := 1 to ArrayLen(Customer) do begin
            AssertReportFields(SalesInvoiceHeader[Index]."No.", Customer[Index], Index = 2, FeatureEnabled, SalesInvoiceHeader[Index].FieldCaption("VAT Paid on Debits FR"));
            SalesInvoiceHeader[Index].Get(SalesInvoiceHeader[Index]."No.");
            SalesInvoiceHeader[Index].TestField("VAT Paid on Debits FR", Index = 2);
#if not CLEAN30
#pragma warning disable AL0432
            SalesInvoiceHeader[Index].TestField("VAT Paid on Debits", Index = 1);
#pragma warning restore AL0432
#endif
        end;
    end;

    local procedure VerifyCreditMemoFieldSource(FeatureEnabled: Boolean)
    var
        Customer: array[2] of Record Customer;
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: array[2] of Record "Sales Cr.Memo Header";
        ReportSalesCrMemoHeader: Record "Sales Cr.Memo Header";
        Index: Integer;
    begin
        InitializeReportFieldSource(FeatureEnabled);

        for Index := 1 to ArrayLen(Customer) do begin
            CreateCustomerWithDivergentSirenNo(Customer[Index], Index = 2);
            LibrarySales.CreateSalesCreditMemoForCustomerNo(SalesHeader, Customer[Index]."No.");
            SetDivergentVATFields(SalesHeader, Index = 2);
            SalesCrMemoHeader[Index].Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
            SalesCrMemoHeader[Index].TestField("VAT Paid on Debits FR", Index = 2);
        end;
        ReportSalesCrMemoHeader.SetFilter("No.", '%1|%2', SalesCrMemoHeader[1]."No.", SalesCrMemoHeader[2]."No.");
        Commit();

        LibraryReportDataset.RunReportAndLoad(Report::"Standard Sales - Credit Memo", ReportSalesCrMemoHeader, '');

        for Index := 1 to ArrayLen(Customer) do begin
            AssertReportFields(SalesCrMemoHeader[Index]."No.", Customer[Index], Index = 2, FeatureEnabled, SalesCrMemoHeader[Index].FieldCaption("VAT Paid on Debits FR"));
            SalesCrMemoHeader[Index].Get(SalesCrMemoHeader[Index]."No.");
            SalesCrMemoHeader[Index].TestField("VAT Paid on Debits FR", Index = 2);
#if not CLEAN30
#pragma warning disable AL0432
            SalesCrMemoHeader[Index].TestField("VAT Paid on Debits", Index = 1);
#pragma warning restore AL0432
#endif
        end;
    end;

    local procedure VerifyDraftInvoiceFieldSource(FeatureEnabled: Boolean)
    var
        Customer: array[2] of Record Customer;
        SalesHeader: array[2] of Record "Sales Header";
        ReportSalesHeader: Record "Sales Header";
        Index: Integer;
    begin
        InitializeReportFieldSource(FeatureEnabled);

        for Index := 1 to ArrayLen(Customer) do begin
            CreateCustomerWithDivergentSirenNo(Customer[Index], Index = 2);
            LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader[Index], Customer[Index]."No.");
            SetDivergentVATFields(SalesHeader[Index], Index = 2);
        end;
        ReportSalesHeader.SetRange("Document Type", ReportSalesHeader."Document Type"::Invoice);
        ReportSalesHeader.SetFilter("No.", '%1|%2', SalesHeader[1]."No.", SalesHeader[2]."No.");
        Commit();

        LibraryReportDataset.RunReportAndLoad(Report::"Standard Sales - Draft Invoice", ReportSalesHeader, '');

        for Index := 1 to ArrayLen(Customer) do begin
            AssertReportFields(SalesHeader[Index]."No.", Customer[Index], Index = 2, FeatureEnabled, SalesHeader[Index].FieldCaption("VAT Paid on Debits FR"));
            SalesHeader[Index].Get(SalesHeader[Index]."Document Type", SalesHeader[Index]."No.");
            SalesHeader[Index].TestField("VAT Paid on Debits FR", Index = 2);
#if not CLEAN30
#pragma warning disable AL0432
            SalesHeader[Index].TestField("VAT Paid on Debits", Index = 1);
#pragma warning restore AL0432
#endif
        end;
    end;

    local procedure InitializeReportFieldSource(FeatureEnabled: Boolean)
    begin
        Initialize();
#if not CLEAN30
        SetSalesFRFeatureEnabled(FeatureEnabled);
#else
        Assert.IsTrue(FeatureEnabled, 'Sales FR is always enabled in clean builds.');
#endif
    end;

    local procedure CreateCustomerWithDivergentSirenNo(var Customer: Record Customer; ClearSIRENNo: Boolean)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("SIREN No. FR", '222222222');
        if ClearSIRENNo then
            Customer.Validate("SIREN No. FR", '');
#if not CLEAN30
#pragma warning disable AL0432
        if ClearSIRENNo then
            Customer.Validate("SIREN No.", '333333333')
        else
            Customer.Validate("SIREN No.", '111111111');
#pragma warning restore AL0432
#endif
        Customer.Modify(true);
    end;

    local procedure SetDivergentVATFields(var SalesHeader: Record "Sales Header"; VATPaidOnDebits: Boolean)
    begin
        SalesHeader.Validate("VAT Paid on Debits FR", VATPaidOnDebits);
#if not CLEAN30
#pragma warning disable AL0432
        SalesHeader.Validate("VAT Paid on Debits", not VATPaidOnDebits);
#pragma warning restore AL0432
#endif
        SalesHeader.Modify();
    end;

    local procedure AssertReportFields(DocumentNo: Code[20]; Customer: Record Customer; VATPaidOnDebits: Boolean; FeatureEnabled: Boolean; VATCaption: Text)
    var
        StoredCustomer: Record Customer;
        ExpectedSIRENNo: Text;
        ExpectedVATText: Text;
    begin
        if FeatureEnabled then
            ExpectedSIRENNo := StrSubstNo(SIRENNoWithCaptionTok, Customer.FieldCaption("SIREN No. FR"), Customer."SIREN No. FR")
#if not CLEAN30
        else begin
#pragma warning disable AL0432
            ExpectedSIRENNo := StrSubstNo(SIRENNoWithCaptionTok, Customer.FieldCaption("SIREN No."), Customer."SIREN No.");
#pragma warning restore AL0432
            VATPaidOnDebits := not VATPaidOnDebits;
        end;
#else
        else
            Assert.Fail('Sales FR cannot be disabled in clean builds.');
#endif
        if VATPaidOnDebits then
            ExpectedVATText := VATCaption;

        LibraryReportDataset.MoveToRow(LibraryReportDataset.FindRow('DocumentNo', DocumentNo) + 1);
        LibraryReportDataset.AssertCurrentRowValueEquals('CustomerSirenNo', ExpectedSIRENNo);
        LibraryReportDataset.AssertCurrentRowValueEquals('VATPaidOnDebits_Lbl', ExpectedVATText);

        StoredCustomer.Get(Customer."No.");
        StoredCustomer.TestField("SIREN No. FR", Customer."SIREN No. FR");
#if not CLEAN30
#pragma warning disable AL0432
        StoredCustomer.TestField("SIREN No.", Customer."SIREN No.");
#pragma warning restore AL0432
#endif
    end;

#if not CLEAN30
#pragma warning disable AL0432
    local procedure SetSalesFRFeatureEnabled(Enabled: Boolean)
    var
        FeatureKey: Record "Feature Key";
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        SalesFR: Codeunit "Sales FR";
    begin
        FeatureKey.Get(SalesFR.GetFeatureKeyId());

        if not FeatureDataUpdateStatus.Get(FeatureKey.ID, CompanyName()) then begin
            FeatureDataUpdateStatus.Init();
            FeatureDataUpdateStatus."Feature Key" := FeatureKey.ID;
            FeatureDataUpdateStatus."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(FeatureDataUpdateStatus."Company Name"));
            FeatureDataUpdateStatus."Data Update Required" := FeatureKey."Data Update Required";
            FeatureDataUpdateStatus.Insert();
        end;
        if Enabled then
            FeatureDataUpdateStatus."Feature Status" := FeatureDataUpdateStatus."Feature Status"::Complete
        else
            FeatureDataUpdateStatus."Feature Status" := FeatureDataUpdateStatus."Feature Status"::Disabled;
        FeatureDataUpdateStatus.Modify();

        Assert.AreEqual(Enabled, SalesFR.IsEnabled(), 'The effective Sales FR feature state must match the report scenario.');
    end;
#pragma warning restore AL0432
#endif

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
    procedure StandardSalesInvoiceRequestPageHandler(var StandardSalesInvoice: TestRequestPage "Standard Sales - Invoice")
    begin
        StandardSalesInvoice.DisplayShipmentInformation.SetValue(LibraryVariableStorage.DequeueBoolean());
        StandardSalesInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DraftSalesInvoiceRequestPageHandler(var StandardSalesDraftInvoice: TestRequestPage "Standard Sales - Draft Invoice")
    begin
        // Consume the queued expectation so the test can assert the request page was opened exactly once.
        LibraryVariableStorage.DequeueBoolean();
        StandardSalesDraftInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StdSalesCrMemoRequestPageHandler(var StandardSalesCreditMemo: TestRequestPage "Standard Sales - Credit Memo")
    begin
        if StandardSalesCreditMemo.Editable then;
        StandardSalesCreditMemo.DisplayShipmentInformation.SetValue(LibraryVariableStorage.DequeueBoolean());
        StandardSalesCreditMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
        Sleep(200);
    end;
}
