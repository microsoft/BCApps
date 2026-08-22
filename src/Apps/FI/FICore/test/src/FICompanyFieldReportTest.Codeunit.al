namespace Microsoft.Finance.FinancialReports;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Reminder;
using Microsoft.Sales.Setup;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Reports;
using Microsoft.Service.Test;
using System.Environment.Configuration;
using System.TestLibraries.Utilities;

codeunit 148150 "FI Company Field Report Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        CompanyInformation: Record "Company Information";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryService: Codeunit "Library - Service";
        LibraryERM: Codeunit "Library - ERM";
        FIVIESFeatureHandler: Codeunit "FI VIES Feature Handler";
        Assert: Codeunit Assert;
        BusinessIdentityCodeTxt: Text[20];
        RegisteredHomeCityTxt: Text[50];
        VendorCrMemoNoTok: Label '123', Locked = true;
        ServiceSuppliesCode4CaptionLbl: Label 'Total Value of Service Supplies(Code 4)';

    local procedure Initialize()
    var
        SalesAndReceivablesSetup: Record "Sales & Receivables Setup";
        PurchasesAndPayablesSetup: Record "Purchases & Payables Setup";
        FeatureKey: Record "Feature Key";
        FeatureKeyUpdateStatus: Record "Feature Data Update Status";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        BusinessIdentityCodeTxt := '01234567890123456789';
        RegisteredHomeCityTxt := '01234567890123456789012345678901234567890123456789';

        LibraryVariableStorage.Clear();
        LibraryReportDataset.Reset();
        FIVIESFeatureHandler.SetEnabled(false);

        CompanyInformation.Get();
        CompanyInformation."VAT Registration No." := 'FI12345678';
        CompanyInformation."Business Identity Code" := BusinessIdentityCodeTxt;
        CompanyInformation."Registered Home City" := RegisteredHomeCityTxt;
        CompanyInformation."Allow Blank Payment Info." := true;
        CompanyInformation.Modify();

        LibrarySales.SetCreditWarningsToNoWarnings();
        LibrarySales.SetStockoutWarning(false);
        LibraryERM.SetLCYCode('EUR');
        LibraryService.SetupServiceMgtNoSeries();

        if FeatureKey.Get('ReminderTermsCommunicationTexts') then begin
            FeatureKey.Enabled := FeatureKey.Enabled::None;
            FeatureKey.Modify();
        end;
        if FeatureKeyUpdateStatus.Get('ReminderTermsCommunicationTexts', CompanyName()) then begin
            FeatureKeyUpdateStatus."Feature Status" := FeatureKeyUpdateStatus."Feature Status"::Disabled;
            FeatureKeyUpdateStatus.Modify();
        end;

        SalesAndReceivablesSetup.Get();
        PurchasesAndPayablesSetup.Get();
        if SalesAndReceivablesSetup."Order Nos." = '' then
            LibrarySales.SetOrderNoSeriesInSetup();
        if (SalesAndReceivablesSetup."Posted Invoice Nos." = '') or (SalesAndReceivablesSetup."Posted Shipment Nos." = '') or
           (SalesAndReceivablesSetup."Posted Credit Memo Nos." = '')
        then
            LibrarySales.SetPostedNoSeriesInSetup();
        if PurchasesAndPayablesSetup."Quote Nos." = '' then
            LibraryPurchase.SetQuoteNoSeriesInSetup();
        if PurchasesAndPayablesSetup."Order Nos." = '' then
            LibraryPurchase.SetOrderNoSeriesInSetup();
        if (PurchasesAndPayablesSetup."Posted Invoice Nos." = '') or (PurchasesAndPayablesSetup."Posted Receipt Nos." = '') or
           (PurchasesAndPayablesSetup."Posted Credit Memo Nos." = '')
        then
            LibraryPurchase.SetPostedNoSeriesInSetup();

        SalesAndReceivablesSetup.Get();
        PurchasesAndPayablesSetup.Get();
        if SalesAndReceivablesSetup."Quote Nos." = '' then
            LibraryUtility.UpdateSetupNoSeriesCode(Database::"Sales & Receivables Setup", SalesAndReceivablesSetup.FieldNo("Quote Nos."));
        if SalesAndReceivablesSetup."Blanket Order Nos." = '' then
            LibraryUtility.UpdateSetupNoSeriesCode(Database::"Sales & Receivables Setup", SalesAndReceivablesSetup.FieldNo("Blanket Order Nos."));
        if SalesAndReceivablesSetup."Invoice Nos." = '' then
            LibraryUtility.UpdateSetupNoSeriesCode(Database::"Sales & Receivables Setup", SalesAndReceivablesSetup.FieldNo("Invoice Nos."));
        if SalesAndReceivablesSetup."Reminder Nos." = '' then
            LibraryUtility.UpdateSetupNoSeriesCode(Database::"Sales & Receivables Setup", SalesAndReceivablesSetup.FieldNo("Reminder Nos."));
        if SalesAndReceivablesSetup."Issued Reminder Nos." = '' then
            LibraryUtility.UpdateSetupNoSeriesCode(Database::"Sales & Receivables Setup", SalesAndReceivablesSetup.FieldNo("Issued Reminder Nos."));
        if SalesAndReceivablesSetup."Fin. Chrg. Memo Nos." = '' then
            LibraryUtility.UpdateSetupNoSeriesCode(Database::"Sales & Receivables Setup", SalesAndReceivablesSetup.FieldNo("Fin. Chrg. Memo Nos."));
        if SalesAndReceivablesSetup."Issued Fin. Chrg. M. Nos." = '' then
            LibraryUtility.UpdateSetupNoSeriesCode(Database::"Sales & Receivables Setup", SalesAndReceivablesSetup.FieldNo("Issued Fin. Chrg. M. Nos."));
        if PurchasesAndPayablesSetup."Blanket Order Nos." = '' then
            LibraryUtility.UpdateSetupNoSeriesCode(Database::"Purchases & Payables Setup", PurchasesAndPayablesSetup.FieldNo("Blanket Order Nos."));
        if PurchasesAndPayablesSetup."Invoice Nos." = '' then
            LibraryUtility.UpdateSetupNoSeriesCode(Database::"Purchases & Payables Setup", PurchasesAndPayablesSetup.FieldNo("Invoice Nos."));
        if PurchasesAndPayablesSetup."Credit Memo Nos." = '' then
            LibraryUtility.UpdateSetupNoSeriesCode(Database::"Purchases & Payables Setup", PurchasesAndPayablesSetup.FieldNo("Credit Memo Nos."));

        SalesAndReceivablesSetup.Get();
        SalesAndReceivablesSetup."Reference Nos." := CreateRefNumberSeries('1000');
        SalesAndReceivablesSetup."Print Reference No." := false;
        SalesAndReceivablesSetup."Invoice No." := false;
        SalesAndReceivablesSetup."Customer No." := false;
        SalesAndReceivablesSetup.Date := false;
        SalesAndReceivablesSetup."Default Number" := '';
        SalesAndReceivablesSetup.Modify();

        Commit();
    end;

    [Test]
    [HandlerFunctions('StandardSalesQuoteReportRequestPageHandler')]
    procedure RegisteredHomeCityInStandardSalesQuote()
    var
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
        RequestPageXML: Text;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] The registered home city is included in a standard sales quote.
        Initialize();

        // [GIVEN] Sales quote "SQ".
        DocumentNo := CreateSalesDocument(SalesHeader."Document Type"::Quote);

        // [WHEN] The standard sales quote report is run for "SQ".
        RequestPageXML := Report.RunRequestPage(Report::"Standard Sales - Quote", RequestPageXML);
        SalesHeader.SetRange("No.", DocumentNo);
        LibraryReportDataset.RunReportAndLoad(Report::"Standard Sales - Quote", SalesHeader, RequestPageXML);

        // [THEN] The dataset contains the registered home city and its caption.
        LibraryReportDataset.AssertElementWithValueExists('CompanyLegalOffice', RegisteredHomeCityTxt);
        LibraryReportDataset.AssertElementWithValueExists('CompanyLegalOffice_Lbl', CompanyInformation.FieldCaption(CompanyInformation."Registered Home City"));
    end;

    [Test]
    procedure CompanyFieldsInVATVIESDeclaration()
    var
        FICoreVIESDeclarationFeature: Codeunit "FICore VIES Decl. Feature";
        EmptyRecordVariant: Variant;
        RequestPageXML: Text;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Finnish company fields are included in the VIES declaration when the feature is enabled.
        Initialize();

        // [GIVEN] The FI VIES declaration feature is enabled and VAT VIES entry "VE" exists.
        FIVIESFeatureHandler.SetEnabled(true);
        Assert.IsTrue(FICoreVIESDeclarationFeature.IsEnabled(), 'The FI VIES feature should be enabled for the test.');
        CreateVATVIESEntry();

        // [WHEN] The VIES declaration report is run.
        RequestPageXML := GetVATVIESDeclarationRequestPageXML();
        LibraryReportDataset.RunReportAndLoad(Report::"VAT- VIES Declaration Tax Auth", EmptyRecordVariant, RequestPageXML);

        // [THEN] The dataset contains the Finnish company fields and captions.
        LibraryReportDataset.AssertElementWithValueExists('CompanyInfoBusinessIdentityCode', BusinessIdentityCodeTxt);
        LibraryReportDataset.AssertElementWithValueExists('BusinessIdentityCodeCaption', CompanyInformation.FieldCaption(CompanyInformation."Business Identity Code"));
        LibraryReportDataset.AssertElementWithValueExists('CompanyInfoRegisteredHomeCity', RegisteredHomeCityTxt);
        LibraryReportDataset.AssertElementWithValueExists('RegHomeCityCaption', CompanyInformation.FieldCaption(CompanyInformation."Registered Home City"));
        LibraryReportDataset.AssertElementWithValueExists('ServiceSuppliesCode4Caption', ServiceSuppliesCode4CaptionLbl);
    end;

    [Test]
    procedure CompanyFieldsNotInVATVIESDeclarationWhenFeatureDisabled()
    var
        EmptyRecordVariant: Variant;
        RequestPageXML: Text;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Finnish company fields are excluded from the VIES declaration when the feature is disabled.
        Initialize();

        // [GIVEN] The FI VIES declaration feature is disabled and VAT VIES entry "VE" exists.
        CreateVATVIESEntry();

        // [WHEN] The VIES declaration report is run.
        RequestPageXML := GetVATVIESDeclarationRequestPageXML();
        LibraryReportDataset.RunReportAndLoad(Report::"VAT- VIES Declaration Tax Auth", EmptyRecordVariant, RequestPageXML);

        // [THEN] The Finnish company fields and captions are empty in the dataset.
        LibraryReportDataset.AssertElementWithValueExists('CompanyInfoBusinessIdentityCode', '');
        LibraryReportDataset.AssertElementWithValueExists('BusinessIdentityCodeCaption', '');
        LibraryReportDataset.AssertElementWithValueExists('CompanyInfoRegisteredHomeCity', '');
        LibraryReportDataset.AssertElementWithValueExists('RegHomeCityCaption', '');
        LibraryReportDataset.AssertElementWithValueExists('ServiceSuppliesCode4Caption', '');
    end;

    local procedure CreateRefNumberSeries(StartingNo: Code[20]): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        LibraryUtility.CreateNoSeries(NoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, StartingNo, '9999');
        exit(NoSeries.Code);
    end;

    local procedure CreateVATVIESEntry()
    var
        CountryRegion: Record "Country/Region";
        VATEntry: Record "VAT Entry";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        CountryRegion.Code := LibraryUtility.GenerateRandomCode(CountryRegion.FieldNo(Code), Database::"Country/Region");
        CountryRegion."EU Country/Region Code" := CountryRegion.Code;
        CountryRegion.Insert();

        if VATEntry.FindLast() then;
        VATEntry.Init();
        VATEntry."Entry No." += 1;
        VATEntry.Type := VATEntry.Type::Sale;
        VATEntry."Posting Date" := WorkDate();
        VATEntry."VAT Reporting Date" := WorkDate();
        VATEntry."Country/Region Code" := CountryRegion.Code;
        VATEntry."VAT Registration No." := LibraryUtility.GenerateGUID();
        VATEntry."Bill-to/Pay-to No." := LibraryUtility.GenerateGUID();
        VATEntry.Base := LibraryRandom.RandDec(1000, 2);
        VATEntry.Insert();

        Commit();
    end;

    local procedure CreateSalesDocument(Type: Enum "Sales Document Type"): Code[20]
    begin
        exit(CreateSalesDocument(Type, false, false));
    end;

    local procedure CreateSalesDocument(Type: Enum "Sales Document Type"; Post: Boolean): Code[20]
    begin
        exit(CreateSalesDocument(Type, Post, true));
    end;

    local procedure CreateSalesDocument(Type: Enum "Sales Document Type"; Post: Boolean; EnqueueDocumentNumber: Boolean): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        DocumentNumber: Code[20];
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, Type, Customer."No.");
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::Item,
            CreateItemNo(Customer."Gen. Bus. Posting Group", Customer."VAT Bus. Posting Group"), LibraryRandom.RandInt(1000));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 1000, 2));
        SalesLine.Modify(true);
        if Post then
            DocumentNumber := LibrarySales.PostSalesDocument(SalesHeader, true, true)
        else
            DocumentNumber := SalesHeader."No.";
        if EnqueueDocumentNumber then
            LibraryVariableStorage.Enqueue(DocumentNumber);

        Commit();

        exit(DocumentNumber);
    end;

    local procedure CreatePurchaseDocument(Type: Enum "Purchase Document Type"; Post: Boolean): Text
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        DocumentNumber: Variant;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, Type, Vendor."No.");
        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::"Credit Memo" then
            PurchaseHeader."Vendor Cr. Memo No." := VendorCrMemoNoTok;
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
            CreateItemNo(Vendor."Gen. Bus. Posting Group", Vendor."VAT Bus. Posting Group"), LibraryRandom.RandInt(1000));
        if Post then
            DocumentNumber := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true)
        else
            DocumentNumber := PurchaseHeader."No.";
        LibraryVariableStorage.Enqueue(DocumentNumber);
        Commit();
        exit(DocumentNumber);
    end;

    local procedure CreateServiceDocument(Type: Enum "Service Document Type"; Post: Boolean): Text
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceLine: Record "Service Line";
        Customer: Record Customer;
        DocumentNumber: Variant;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, Type, Customer."No.");
        LibraryService.CreateServiceLine(
            ServiceLine, ServiceHeader, ServiceLine.Type::Item,
            CreateItemNo(Customer."Gen. Bus. Posting Group", Customer."VAT Bus. Posting Group"));
        ServiceLine.Validate(Quantity, 1);
        ServiceLine.Modify();
        if Post then begin
            LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
            ServiceInvoiceHeader.FindLast();
            DocumentNumber := ServiceInvoiceHeader."No.";
        end else
            DocumentNumber := ServiceHeader."No.";
        LibraryVariableStorage.Enqueue(DocumentNumber);
        Commit();
        exit(DocumentNumber);
    end;

    local procedure CreateServiceContract(ServiceContractType: Enum "Service Contract Type"): Text
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        Customer: Record Customer;
        ServiceItem: Record "Service Item";
        DocumentNumber: Variant;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractType, Customer."No.");
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        DocumentNumber := ServiceContractHeader."Contract No.";
        LibraryVariableStorage.Enqueue(DocumentNumber);
        Commit();
        exit(DocumentNumber);
    end;

    local procedure CreateItemNo(GenBusPostingGroup: Code[20]; VATBusPostingGroup: Code[20]): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        Item: Record Item;
        Location: Record Location;
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusPostingGroup, GenProductPostingGroup.Code);
        LibraryERM.SetGeneralPostingSetupSalesAccounts(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupPurchAccounts(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupInvtAccounts(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupMfgAccounts(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupPrepAccounts(GeneralPostingSetup);
        GeneralPostingSetup.Modify(true);

        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("VAT Identifier", VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandIntInRange(1, 25));
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);

        Item.Get(LibraryInventory.CreateItemNoWithPostingSetup(GenProductPostingGroup.Code, VATProductPostingGroup.Code));
        LibraryInventory.UpdateInventoryPostingSetup(Location, Item."Inventory Posting Group");

        exit(Item."No.");
    end;

    local procedure InitializeReminderMemoReport()
    var
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        Customer: Record Customer;
        Currency: Record Currency;
        Amount: Decimal;
    begin
        ReminderHeader.DeleteAll();
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateReminderHeader(ReminderHeader);
        ReminderHeader.Validate("Customer No.", Customer."No.");
        ReminderHeader.Modify(true);
        LibraryERM.CreateReminderLine(ReminderLine, ReminderHeader."No.", ReminderLine.Type::"G/L Account");
        Amount := LibraryRandom.RandDecInDecimalRange(1, 100, 2);
        ReminderLine.Validate("Remaining Amount", Amount);
        ReminderLine.Validate(Amount, Amount);
        ReminderLine.Modify(true);
        LibraryERM.CreateCurrency(Currency);
        Customer."Currency Code" := Currency.Code;
        Customer.Modify();
        Commit();
    end;

    local procedure AssertCompanyFieldsInLoadedDataset(BusinessIdentityCodeElement: Text; RegisteredHomeCityElement: Text)
    var
        ActualBusinessIdentityCode: Variant;
        ActualRegisteredHomeCity: Variant;
        RowIndex: Integer;
    begin
        Assert.IsTrue(LibraryReportDataset.RowCount() > 0, 'Empty Dataset');
        for RowIndex := 0 to LibraryReportDataset.RowCount() - 1 do begin
            LibraryReportDataset.GetNextRow();
            LibraryReportDataset.GetElementValueInCurrentRow(BusinessIdentityCodeElement, ActualBusinessIdentityCode);
            LibraryReportDataset.GetElementValueInCurrentRow(RegisteredHomeCityElement, ActualRegisteredHomeCity);
            Assert.AreEqual(BusinessIdentityCodeTxt, ActualBusinessIdentityCode, 'Incorrect BusinessIdentityCode');
            Assert.AreEqual(RegisteredHomeCityTxt, ActualRegisteredHomeCity, 'Incorrect RegisteredHomeCity');
        end;
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure AssertLoadedDatasetIsNotEmpty()
    begin
        Assert.IsTrue(LibraryReportDataset.RowCount() > 0, 'Empty Dataset');
    end;

    local procedure GetVATVIESDeclarationRequestPageXML(): Text
    var
        RequestPageXMLTxt: Label '<?xml version="1.0" standalone="yes"?><ReportParameters name="VAT- VIES Declaration Tax Auth" id="19"><Options><Field name="UseAmtsInAddCurr">true</Field><Field name="StartDate">%1</Field><Field name="EndDate">%2</Field><Field name="VATRegistrationNoFilter"></Field></Options><DataItems></DataItems></ReportParameters>', Comment = '%1 = Start Date, %2 = End Date', Locked = true;
    begin
        exit(StrSubstNo(RequestPageXMLTxt, Format(WorkDate(), 0, 9), Format(WorkDate() + 365, 0, 9)));
    end;

    local procedure AssertRegisteredHomeCityInLoadedStandardReport()
    begin
        LibraryReportDataset.AssertElementWithValueExists('CompanyLegalOffice', RegisteredHomeCityTxt);
        LibraryReportDataset.AssertElementWithValueExists(
            'CompanyLegalOffice_Lbl', CompanyInformation.FieldCaption(CompanyInformation."Registered Home City"));
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StatementReportHandler')]
    [Scope('OnPrem')]
    procedure TestStatementReport()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedDocumentNo: Code[20];
        RequestPageXML: Text;
    begin
        Initialize();
        PostedDocumentNo := CreateSalesDocument(SalesHeader."Document Type"::Invoice, true, false);
        SalesInvoiceHeader.Get(PostedDocumentNo);
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");
        Customer.SetRecFilter();
        RequestPageXML := Report.RunRequestPage(Report::Statement, RequestPageXML);
        LibraryReportDataset.RunReportAndLoad(Report::Statement, Customer, RequestPageXML);
        AssertCompanyFieldsInLoadedDataset('CompanyInfoBusinessIdCode', 'CompanyInfoRegHomeCity');
    end;

    [RequestPageHandler]
    procedure StatementReportHandler(var StatementReport: TestRequestPage Statement)
    begin
        StatementReport."Start Date".SetValue(WorkDate());
        StatementReport."End Date".SetValue(WorkDate());
        StatementReport.IncludeAllCustomerswithLE.SetValue(true);
        StatementReport.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('ReminderReportHandler')]
    [Scope('OnPrem')]
    procedure ReminderMemoReport()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        IssueRemindersReport: Report "Issue Reminders";
        RequestPageXML: Text;
    begin
        Initialize();
        InitializeReminderMemoReport();

        IssueRemindersReport.UseRequestPage(false);
        IssueRemindersReport.Run();
        IssuedReminderHeader.FindLast();
        RequestPageXML := Report.RunRequestPage(Report::Reminder, RequestPageXML);
        IssuedReminderHeader.SetRecFilter();
        LibraryReportDataset.RunReportAndLoad(Report::Reminder, IssuedReminderHeader, RequestPageXML);
        AssertCompanyFieldsInLoadedDataset('CompanyInfoBusinessIdCode', 'CompanyInfoRegHomeCity');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReminderReportHandler(var ReminderReport: TestRequestPage Reminder)
    begin
        ReminderReport.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('ReminderTestReportHandler')]
    [Scope('OnPrem')]
    procedure ReminderMemoTestReport()
    var
        ReminderHeader: Record "Reminder Header";
        RequestPageXML: Text;
    begin
        Initialize();
        InitializeReminderMemoReport();

        ReminderHeader.FindLast();
        RequestPageXML := Report.RunRequestPage(Report::"Reminder - Test", RequestPageXML);
        ReminderHeader.SetRecFilter();
        LibraryReportDataset.RunReportAndLoad(Report::"Reminder - Test", ReminderHeader, RequestPageXML);
        AssertLoadedDatasetIsNotEmpty();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReminderTestReportHandler(var ReminderTestReport: TestRequestPage "Reminder - Test")
    begin
        ReminderTestReport.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('FinanceChargeMemoReportHandler')]
    [Scope('OnPrem')]
    procedure FinanceChargeMemoReport()
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        VATPostingSetup: Record "VAT Posting Setup";
        CreateFinanceChargeMemos: Report "Create Finance Charge Memos";
        LibraryFinanceChargeMemo: Codeunit "Library - Finance Charge Memo";
        PostedDocumentNo: Code[20];
        RequestPageXML: Text;
    begin
        Initialize();

        PostedDocumentNo := CreateSalesDocument(SalesHeader."Document Type"::Invoice, true, false);
        LibraryFinanceChargeMemo.CreateFinanceChargeTermAndText(FinanceChargeTerms);
        SalesInvoiceHeader.Get(PostedDocumentNo);
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, Customer."VAT Bus. Posting Group", '');
        Customer."Fin. Charge Terms Code" := FinanceChargeTerms.Code;
        Customer.Modify();

        Commit();
        Customer.SetRecFilter();
        CreateFinanceChargeMemos.SetTableView(Customer);
        CreateFinanceChargeMemos.UseRequestPage(false);
        CreateFinanceChargeMemos.InitializeRequest(
            CalcDate('<1Y>', SalesInvoiceHeader."Posting Date"), CalcDate('<1Y>', SalesInvoiceHeader."Posting Date"));
        CreateFinanceChargeMemos.Run();
        FinanceChargeMemoHeader.SetRange("Customer No.", Customer."No.");
        FinanceChargeMemoHeader.FindFirst();
        LibraryERM.IssueFinanceChargeMemo(FinanceChargeMemoHeader);
        IssuedFinChargeMemoHeader.SetRange("Customer No.", Customer."No.");
        IssuedFinChargeMemoHeader.FindFirst();
        LibraryVariableStorage.Enqueue(IssuedFinChargeMemoHeader."No.");
        RequestPageXML := Report.RunRequestPage(Report::"Finance Charge Memo", RequestPageXML);
        IssuedFinChargeMemoHeader.SetRecFilter();
        LibraryReportDataset.RunReportAndLoad(Report::"Finance Charge Memo", IssuedFinChargeMemoHeader, RequestPageXML);
        AssertCompanyFieldsInLoadedDataset('CompanyInfoBusinessIdCode', 'CompanyInfoRegHomeCity');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FinanceChargeMemoReportHandler(var FinanceChargeMemoRequestPage: TestRequestPage "Finance Charge Memo")
    begin
        FinanceChargeMemoRequestPage."Issued Fin. Charge Memo Header".SetFilter("No.", LibraryVariableStorage.DequeueText());
        FinanceChargeMemoRequestPage.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceReportHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceReport()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentNumber: Code[20];
        RequestPageXML: Text;
    begin
        Initialize();

        DocumentNumber := CreateSalesDocument(SalesHeader."Document Type"::Invoice, true);
        RequestPageXML := Report.RunRequestPage(Report::"Standard Sales - Invoice", RequestPageXML);
        SalesInvoiceHeader.SetRange("No.", DocumentNumber);
        LibraryReportDataset.RunReportAndLoad(Report::"Standard Sales - Invoice", SalesInvoiceHeader, RequestPageXML);
        AssertRegisteredHomeCityInLoadedStandardReport();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceReportHandler(var SalesInvoiceRequestPage: TestRequestPage "Standard Sales - Invoice")
    var
        DocumentNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        SalesInvoiceRequestPage.Header.SetFilter("No.", Format(DocumentNumber));
        SalesInvoiceRequestPage.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('SalesShipmentReportHandler')]
    [Scope('OnPrem')]
    procedure SalesShipmentReport()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        DocumentNumber: Code[20];
        RequestPageXML: Text;
    begin
        Initialize();

        DocumentNumber := CreateSalesDocument(SalesHeader."Document Type"::Order, true);
        RequestPageXML := Report.RunRequestPage(Report::"Sales - Shipment", RequestPageXML);
        SalesInvoiceHeader.Get(DocumentNumber);
        SalesShipmentHeader.SetRange("Order No.", SalesInvoiceHeader."Order No.");
        LibraryReportDataset.RunReportAndLoad(Report::"Sales - Shipment", SalesShipmentHeader, RequestPageXML);
        AssertCompanyFieldsInLoadedDataset('CompanyInfoBusinessIdCode', 'CompanyInfoRegHomeCity');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesShipmentReportHandler(var SalesShipmentRequestPage: TestRequestPage "Sales - Shipment")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        SalesInvoiceHeader.Get(Format(DocumentNumber));
        SalesShipmentRequestPage."Sales Shipment Header".SetFilter("Order No.", SalesInvoiceHeader."Order No.");
        SalesShipmentRequestPage.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('BlanketSalesOrderReportHandler')]
    [Scope('OnPrem')]
    procedure BlanketSalesOrderReport()
    var
        SalesHeader: Record "Sales Header";
        DocumentNumber: Code[20];
        RequestPageXML: Text;
    begin
        Initialize();

        DocumentNumber := CreateSalesDocument(SalesHeader."Document Type"::"Blanket Order", false);
        RequestPageXML := Report.RunRequestPage(Report::"Blanket Sales Order", RequestPageXML);
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Blanket Order");
        SalesHeader.SetRange("No.", DocumentNumber);
        LibraryReportDataset.RunReportAndLoad(Report::"Blanket Sales Order", SalesHeader, RequestPageXML);
        AssertCompanyFieldsInLoadedDataset('CompanyInfoBusinessIdCode', 'CompanyInfoRegHomeCity');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BlanketSalesOrderReportHandler(var BlanketSalesOrderRequestPage: TestRequestPage "Blanket Sales Order")
    var
        DocumentNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        BlanketSalesOrderRequestPage."Sales Header".SetFilter("No.", Format(DocumentNumber));
        BlanketSalesOrderRequestPage.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('PurchaseQuoteReportHandler')]
    [Scope('OnPrem')]
    procedure PurchaseQuoteReport()
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentNumber: Text;
        RequestPageXML: Text;
    begin
        Initialize();

        DocumentNumber := CreatePurchaseDocument(PurchaseHeader."Document Type"::Quote, false);
        RequestPageXML := Report.RunRequestPage(Report::"Purchase - Quote", RequestPageXML);
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Quote);
        PurchaseHeader.SetRange("No.", DocumentNumber);
        LibraryReportDataset.RunReportAndLoad(Report::"Purchase - Quote", PurchaseHeader, RequestPageXML);
        AssertCompanyFieldsInLoadedDataset('CompanyInfoBusinessIdCode', 'CompanyInfoRegHomeCity');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseQuoteReportHandler(var PurchaseQuoteRequestPage: TestRequestPage "Purchase - Quote")
    var
        DocumentNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        PurchaseQuoteRequestPage."Purchase Header".SetFilter("No.", Format(DocumentNumber));
        PurchaseQuoteRequestPage.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderReportHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderReport()
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentNumber: Text;
        RequestPageXML: Text;
    begin
        Initialize();

        DocumentNumber := CreatePurchaseDocument(PurchaseHeader."Document Type"::Order, false);
        RequestPageXML := Report.RunRequestPage(Report::Order, RequestPageXML);
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("No.", DocumentNumber);
        LibraryReportDataset.RunReportAndLoad(Report::Order, PurchaseHeader, RequestPageXML);
        AssertCompanyFieldsInLoadedDataset('CompanyInfoBusinessIdCode', 'CompanyInfoRegHomeCity');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderReportHandler(var PurchaseOrderRequestPage: TestRequestPage Order)
    var
        DocumentNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        PurchaseOrderRequestPage."Purchase Header".SetFilter("No.", Format(DocumentNumber));
        PurchaseOrderRequestPage.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('PurchaseInvoiceReportHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceReport()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        DocumentNumber: Text;
        RequestPageXML: Text;
    begin
        Initialize();

        DocumentNumber := CreatePurchaseDocument(PurchaseHeader."Document Type"::Invoice, true);
        RequestPageXML := Report.RunRequestPage(Report::"Purchase - Invoice", RequestPageXML);
        PurchInvHeader.SetRange("No.", DocumentNumber);
        LibraryReportDataset.RunReportAndLoad(Report::"Purchase - Invoice", PurchInvHeader, RequestPageXML);
        AssertCompanyFieldsInLoadedDataset('CompanyInfoBusinessIdCode', 'CompanyInfoRegHomeCity');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceReportHandler(var PurchaseInvoiceRequestPage: TestRequestPage "Purchase - Invoice")
    var
        DocumentNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        PurchaseInvoiceRequestPage."Purch. Inv. Header".SetFilter("No.", Format(DocumentNumber));
        PurchaseInvoiceRequestPage.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('PurchaseCreditMemoReportHandler')]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoReport()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        DocumentNumber: Text;
        RequestPageXML: Text;
    begin
        Initialize();

        DocumentNumber := CreatePurchaseDocument(PurchaseHeader."Document Type"::"Credit Memo", true);
        RequestPageXML := Report.RunRequestPage(Report::"Purchase - Credit Memo", RequestPageXML);
        PurchCrMemoHeader.SetRange("No.", DocumentNumber);
        LibraryReportDataset.RunReportAndLoad(Report::"Purchase - Credit Memo", PurchCrMemoHeader, RequestPageXML);
        AssertCompanyFieldsInLoadedDataset('CompanyInfoBusinessIdCode', 'CompanyInfoRegHomeCity');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoReportHandler(var PurchaseCreditMemoRequestPage: TestRequestPage "Purchase - Credit Memo")
    var
        DocumentNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        PurchaseCreditMemoRequestPage."Purch. Cr. Memo Hdr.".SetFilter("No.", Format(DocumentNumber));
        PurchaseCreditMemoRequestPage.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('PurchaseReceiptReportHandler')]
    [Scope('OnPrem')]
    procedure PurchaseReceiptReport()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        DocumentNumber: Text;
        RequestPageXML: Text;
    begin
        Initialize();

        DocumentNumber := CreatePurchaseDocument(PurchaseHeader."Document Type"::Order, true);
        RequestPageXML := Report.RunRequestPage(Report::"Purchase - Receipt", RequestPageXML);
        PurchInvHeader.Get(DocumentNumber);
        PurchRcptHeader.SetRange("Order No.", PurchInvHeader."Order No.");
        LibraryReportDataset.RunReportAndLoad(Report::"Purchase - Receipt", PurchRcptHeader, RequestPageXML);
        AssertCompanyFieldsInLoadedDataset('CompanyInfoBusinessIdCode', 'CompanyInfoRegHomeCity');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseReceiptReportHandler(var PurchaseReceiptRequestPage: TestRequestPage "Purchase - Receipt")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        DocumentNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        PurchInvHeader.Get(Format(DocumentNumber));
        PurchaseReceiptRequestPage."Purch. Rcpt. Header".SetFilter("Order No.", PurchInvHeader."Order No.");
        PurchaseReceiptRequestPage.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('BlanketPurchaseOrderReportHandler')]
    [Scope('OnPrem')]
    procedure BlanketPurchaseOrderReport()
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentNumber: Text;
        RequestPageXML: Text;
    begin
        Initialize();

        DocumentNumber := CreatePurchaseDocument(PurchaseHeader."Document Type"::"Blanket Order", false);
        RequestPageXML := Report.RunRequestPage(Report::"Blanket Purchase Order", RequestPageXML);
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::"Blanket Order");
        PurchaseHeader.SetRange("No.", DocumentNumber);
        LibraryReportDataset.RunReportAndLoad(Report::"Blanket Purchase Order", PurchaseHeader, RequestPageXML);
        AssertCompanyFieldsInLoadedDataset('CompanyInfoBusinessIdCode', 'CompanyInfoRegHomeCity');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BlanketPurchaseOrderReportHandler(var BlanketPurchaseOrderRequestPage: TestRequestPage "Blanket Purchase Order")
    var
        DocumentNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        BlanketPurchaseOrderRequestPage."Purchase Header".SetFilter("No.", Format(DocumentNumber));
        BlanketPurchaseOrderRequestPage.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('ServiceOrderReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderReport()
    var
        ServiceHeader: Record "Service Header";
        DocumentNumber: Text;
        RequestPageXML: Text;
    begin
        Initialize();

        DocumentNumber := CreateServiceDocument(ServiceHeader."Document Type"::Order, false);
        RequestPageXML := Report.RunRequestPage(Report::"Service Order (FI)", RequestPageXML);
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::Order);
        ServiceHeader.SetRange("No.", DocumentNumber);
        LibraryReportDataset.RunReportAndLoad(Report::"Service Order (FI)", ServiceHeader, RequestPageXML);
        AssertCompanyFieldsInLoadedDataset('CompanyInfoBusinessIdCode', 'CompanyInfoegHomeCity');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceOrderReportHandler(var ServiceOrderRequestPage: TestRequestPage "Service Order (FI)")
    var
        DocumentNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        ServiceOrderRequestPage."Service Header".SetFilter("No.", Format(DocumentNumber));
        ServiceOrderRequestPage.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('ServiceQuoteReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceQuoteReport()
    var
        ServiceHeader: Record "Service Header";
        DocumentNumber: Text;
        RequestPageXML: Text;
    begin
        Initialize();

        DocumentNumber := CreateServiceDocument(ServiceHeader."Document Type"::Quote, false);
        RequestPageXML := Report.RunRequestPage(Report::"Service Quote (FI)", RequestPageXML);
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::Quote);
        ServiceHeader.SetRange("No.", DocumentNumber);
        LibraryReportDataset.RunReportAndLoad(Report::"Service Quote (FI)", ServiceHeader, RequestPageXML);
        AssertCompanyFieldsInLoadedDataset('CompanyInfoBusinessIdCode', 'CompanyInfoRegHomeCity');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceQuoteReportHandler(var ServiceQuoteRequestPage: TestRequestPage "Service Quote (FI)")
    var
        DocumentNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        ServiceQuoteRequestPage."Service Header".SetFilter("No.", Format(DocumentNumber));
        ServiceQuoteRequestPage.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('ServiceInvoiceReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceReport()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        DocumentNumber: Text;
        RequestPageXML: Text;
    begin
        Initialize();

        DocumentNumber := CreateServiceDocument(ServiceHeader."Document Type"::Invoice, true);
        RequestPageXML := Report.RunRequestPage(Report::"Service - Invoice (FI)", RequestPageXML);
        ServiceInvoiceHeader.SetRange("No.", DocumentNumber);
        LibraryReportDataset.RunReportAndLoad(Report::"Service - Invoice (FI)", ServiceInvoiceHeader, RequestPageXML);
        AssertCompanyFieldsInLoadedDataset('CompanyInfoBusinessIDCode', 'CompanyInfoRegHomeCity');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceInvoiceReportHandler(var ServiceInvoiceRequestPage: TestRequestPage "Service - Invoice (FI)")
    var
        DocumentNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        ServiceInvoiceRequestPage."Service Invoice Header".SetFilter("No.", Format(DocumentNumber));
        ServiceInvoiceRequestPage.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('ServiceContractReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceContractReport()
    var
        ServiceContractHeader: Record "Service Contract Header";
        DocumentNumber: Text;
        RequestPageXML: Text;
    begin
        Initialize();

        DocumentNumber := CreateServiceContract(ServiceContractHeader."Contract Type"::Contract);
        RequestPageXML := Report.RunRequestPage(Report::"Service Contract (FI)", RequestPageXML);
        ServiceContractHeader.SetRange("Contract Type", ServiceContractHeader."Contract Type"::Contract);
        ServiceContractHeader.SetRange("Contract No.", DocumentNumber);
        LibraryReportDataset.RunReportAndLoad(Report::"Service Contract (FI)", ServiceContractHeader, RequestPageXML);
        AssertCompanyFieldsInLoadedDataset('CompanyInfoBusinessIdCode', 'CompanyInfoRegHomeCity');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceContractReportHandler(var ServiceContractRequestPage: TestRequestPage "Service Contract (FI)")
    var
        DocumentNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        ServiceContractRequestPage."Service Contract Header".SetFilter("Contract No.", Format(DocumentNumber));
        ServiceContractRequestPage.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('ServiceContractQuoteReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceContractQuoteReport()
    var
        ServiceContractHeader: Record "Service Contract Header";
        DocumentNumber: Text;
        RequestPageXML: Text;
    begin
        Initialize();

        DocumentNumber := CreateServiceContract(ServiceContractHeader."Contract Type"::Quote);
        RequestPageXML := Report.RunRequestPage(Report::"Service Contract Quote (FI)", RequestPageXML);
        ServiceContractHeader.SetRange("Contract Type", ServiceContractHeader."Contract Type"::Quote);
        ServiceContractHeader.SetRange("Contract No.", DocumentNumber);
        LibraryReportDataset.RunReportAndLoad(Report::"Service Contract Quote (FI)", ServiceContractHeader, RequestPageXML);
        AssertCompanyFieldsInLoadedDataset('CompanyInfoBusinessIdCode', 'CompanyInfoRegHomeCity');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceContractQuoteReportHandler(var ServiceContractQuoteRequestPage: TestRequestPage "Service Contract Quote (FI)")
    var
        DocumentNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        ServiceContractQuoteRequestPage."Service Contract Header".SetFilter("Contract No.", Format(DocumentNumber));
        ServiceContractQuoteRequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure StandardSalesQuoteReportRequestPageHandler(var StandardSalesQuote: TestRequestPage "Standard Sales - Quote")
    begin
        StandardSalesQuote.OK().Invoke();
    end;

}
