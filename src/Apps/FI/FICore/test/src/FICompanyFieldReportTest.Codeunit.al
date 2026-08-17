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
        // [Scenario] Test FI Core extension subscriber for the field "Registered Home City"
        Initialize();

        DocumentNo := CreateSalesDocument(SalesHeader."Document Type"::Quote);

        // [THEN] The even should be triggered in OnInitReport
        RequestPageXML := Report.RunRequestPage(Report::"Standard Sales - Quote", RequestPageXML);

        SalesHeader.SetRange("No.", DocumentNo);
        LibraryReportDataset.RunReportAndLoad(Report::"Standard Sales - Quote", SalesHeader, RequestPageXML);

        // [THEN] Element should be correctly initialized
        LibraryReportDataset.AssertElementWithValueExists('CompanyLegalOffice', RegisteredHomeCityTxt);
        LibraryReportDataset.AssertElementWithValueExists('CompanyLegalOffice_Lbl', CompanyInformation.FieldCaption(CompanyInformation."Registered Home City"));
    end;

    [Test]
    [HandlerFunctions('VATVIESDeclarationTaxAuthReportRequestPageHandler')]
    procedure CompanyFieldsInVATVIESDeclaration()
    var
        VATVIESDeclarationTaxAuthReport: Report "VAT- VIES Declaration Tax Auth";
    begin
        // [Scenario] Test FI Core extension subscriber for Finnish company fields in the VIES declaration.
        Initialize();
        FIVIESFeatureHandler.SetEnabled(true);
        CreateVATVIESEntry();

        // [WHEN] The VAT VIES declaration report is run.
        VATVIESDeclarationTaxAuthReport.UseRequestPage(true);
        VATVIESDeclarationTaxAuthReport.InitializeRequest(true, WorkDate(), WorkDate() + 365, '');
        VATVIESDeclarationTaxAuthReport.Run();

        // [THEN] Finnish company fields and captions are initialized in the report dataset.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('CompanyInfoBusinessIdentityCode', BusinessIdentityCodeTxt);
        LibraryReportDataset.AssertElementWithValueExists('BusinessIdentityCodeCaption', CompanyInformation.FieldCaption(CompanyInformation."Business Identity Code"));
        LibraryReportDataset.AssertElementWithValueExists('CompanyInfoRegisteredHomeCity', RegisteredHomeCityTxt);
        LibraryReportDataset.AssertElementWithValueExists('RegHomeCityCaption', CompanyInformation.FieldCaption(CompanyInformation."Registered Home City"));
        LibraryReportDataset.AssertElementWithValueExists('ServiceSuppliesCode4Caption', ServiceSuppliesCode4CaptionLbl);
    end;

    [Test]
    [HandlerFunctions('VATVIESDeclarationTaxAuthReportRequestPageHandler')]
    procedure CompanyFieldsNotInVATVIESDeclarationWhenFeatureDisabled()
    var
        VATVIESDeclarationTaxAuthReport: Report "VAT- VIES Declaration Tax Auth";
    begin
        // [Scenario] Finnish company fields are not added to the VIES declaration when the feature is disabled.
        Initialize();
        CreateVATVIESEntry();

        // [WHEN] The VAT VIES declaration report is run.
        VATVIESDeclarationTaxAuthReport.UseRequestPage(true);
        VATVIESDeclarationTaxAuthReport.InitializeRequest(true, WorkDate(), WorkDate() + 365, '');
        VATVIESDeclarationTaxAuthReport.Run();

        // [THEN] Finnish company fields and captions remain empty in the report dataset.
        LibraryReportDataset.LoadDataSetFile();
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

    local procedure AssertCompanyFields(BusinessIdentityCodeElement: Text; RegisteredHomeCityElement: Text)
    var
        ActualBusinessIdentityCode: Variant;
        ActualRegisteredHomeCity: Variant;
        RowIndex: Integer;
    begin
        LibraryReportDataset.LoadDataSetFile();
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

    local procedure AssertDatasetIsNotEmpty()
    begin
        LibraryReportDataset.LoadDataSetFile();
        Assert.IsTrue(LibraryReportDataset.RowCount() > 0, 'Empty Dataset');
    end;

    local procedure AssertRegisteredHomeCityInStandardReport()
    begin
        LibraryReportDataset.LoadDataSetFile();
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
        StatementReport: Report Statement;
        PostedDocumentNo: Code[20];
    begin
        Initialize();
        PostedDocumentNo := CreateSalesDocument(SalesHeader."Document Type"::Invoice, true, false);
        SalesInvoiceHeader.Get(PostedDocumentNo);
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");
        Customer.SetRecFilter();
        StatementReport.SetTableView(Customer);
        LibraryVariableStorage.Enqueue(SalesInvoiceHeader."Posting Date");
        StatementReport.UseRequestPage(true);
        StatementReport.Run();
        AssertCompanyFields('CompanyInfoBusinessIdCode', 'CompanyInfoRegHomeCity');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StatementReportHandler(var StatementReport: TestRequestPage Statement)
    var
        PostingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(PostingDate);
        StatementReport."Start Date".SetValue(PostingDate);
        StatementReport."End Date".SetValue(PostingDate);
        StatementReport.IncludeAllCustomerswithLE.SetValue(true);
        StatementReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Test]
    [HandlerFunctions('ReminderReportHandler')]
    [Scope('OnPrem')]
    procedure ReminderMemoReport()
    var
        ReminderReport: Report Reminder;
        IssueRemindersReport: Report "Issue Reminders";
    begin
        Initialize();
        InitializeReminderMemoReport();

        IssueRemindersReport.UseRequestPage(false);
        IssueRemindersReport.Run();
        ReminderReport.UseRequestPage(true);
        ReminderReport.Run();
        AssertCompanyFields('CompanyInfoBusinessIdCode', 'CompanyInfoRegHomeCity');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReminderReportHandler(var ReminderReport: TestRequestPage Reminder)
    begin
        ReminderReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Test]
    [HandlerFunctions('ReminderTestReportHandler')]
    [Scope('OnPrem')]
    procedure ReminderMemoTestReport()
    var
        ReminderTestReport: Report "Reminder - Test";
    begin
        Initialize();
        InitializeReminderMemoReport();

        ReminderTestReport.UseRequestPage(true);
        ReminderTestReport.Run();
        AssertDatasetIsNotEmpty();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReminderTestReportHandler(var ReminderTestReport: TestRequestPage "Reminder - Test")
    begin
        ReminderTestReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
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
        FinanceChargeMemo: Report "Finance Charge Memo";
        CreateFinanceChargeMemos: Report "Create Finance Charge Memos";
        LibraryFinanceChargeMemo: Codeunit "Library - Finance Charge Memo";
        PostedDocumentNo: Code[20];
    begin
        Initialize();

        PostedDocumentNo := CreateSalesDocument(SalesHeader."Document Type"::Invoice, true, false);
        LibraryFinanceChargeMemo.CreateFinanceChargeTermAndText(FinanceChargeTerms);
        SalesInvoiceHeader.Get(PostedDocumentNo);
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");
        Customer."Fin. Charge Terms Code" := FinanceChargeTerms.Code;
        Customer.Modify();

        Commit();
        Customer.SetRecFilter();
        CreateFinanceChargeMemos.SetTableView(Customer);
        CreateFinanceChargeMemos.UseRequestPage(false);
        CreateFinanceChargeMemos.InitializeRequest(CalcDate('<2M>', SalesInvoiceHeader."Posting Date"), SalesInvoiceHeader."Posting Date");
        CreateFinanceChargeMemos.Run();
        FinanceChargeMemoHeader.SetRange("Customer No.", Customer."No.");
        FinanceChargeMemoHeader.FindFirst();
        LibraryERM.IssueFinanceChargeMemo(FinanceChargeMemoHeader);
        IssuedFinChargeMemoHeader.SetRange("Customer No.", Customer."No.");
        IssuedFinChargeMemoHeader.FindFirst();
        LibraryVariableStorage.Enqueue(IssuedFinChargeMemoHeader."No.");
        FinanceChargeMemo.UseRequestPage(true);
        FinanceChargeMemo.Run();
        AssertCompanyFields('CompanyInfoBusinessIdCode', 'CompanyInfoRegHomeCity');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FinanceChargeMemoReportHandler(var FinanceChargeMemoRequestPage: TestRequestPage "Finance Charge Memo")
    begin
        FinanceChargeMemoRequestPage."Issued Fin. Charge Memo Header".SetFilter("No.", LibraryVariableStorage.DequeueText());
        FinanceChargeMemoRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceReportHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceReport()
    var
        SalesHeader: Record "Sales Header";
        StandardSalesInvoice: Report "Standard Sales - Invoice";
    begin
        Initialize();

        CreateSalesDocument(SalesHeader."Document Type"::Invoice, true);
        StandardSalesInvoice.UseRequestPage(true);
        StandardSalesInvoice.Run();
        AssertRegisteredHomeCityInStandardReport();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceReportHandler(var SalesInvoiceRequestPage: TestRequestPage "Standard Sales - Invoice")
    var
        DocumentNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        SalesInvoiceRequestPage.Header.SetFilter("No.", Format(DocumentNumber));
        SalesInvoiceRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Test]
    [HandlerFunctions('SalesShipmentReportHandler')]
    [Scope('OnPrem')]
    procedure SalesShipmentReport()
    var
        SalesHeader: Record "Sales Header";
        SalesShipment: Report "Sales - Shipment";
    begin
        Initialize();

        CreateSalesDocument(SalesHeader."Document Type"::Order, true);
        SalesShipment.UseRequestPage(true);
        SalesShipment.Run();
        AssertCompanyFields('CompanyInfoBusinessIdCode', 'CompanyInfoRegHomeCity');
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
        SalesShipmentRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Test]
    [HandlerFunctions('BlanketSalesOrderReportHandler')]
    [Scope('OnPrem')]
    procedure BlanketSalesOrderReport()
    var
        SalesHeader: Record "Sales Header";
        BlanketSalesOrder: Report "Blanket Sales Order";
    begin
        Initialize();

        CreateSalesDocument(SalesHeader."Document Type"::"Blanket Order", false);
        BlanketSalesOrder.UseRequestPage(true);
        BlanketSalesOrder.Run();
        AssertCompanyFields('CompanyInfoBusinessIdCode', 'CompanyInfoRegHomeCity');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BlanketSalesOrderReportHandler(var BlanketSalesOrderRequestPage: TestRequestPage "Blanket Sales Order")
    var
        DocumentNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        BlanketSalesOrderRequestPage."Sales Header".SetFilter("No.", Format(DocumentNumber));
        BlanketSalesOrderRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Test]
    [HandlerFunctions('PurchaseQuoteReportHandler')]
    [Scope('OnPrem')]
    procedure PurchaseQuoteReport()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseQuote: Report "Purchase - Quote";
    begin
        Initialize();

        CreatePurchaseDocument(PurchaseHeader."Document Type"::Quote, false);
        PurchaseQuote.UseRequestPage(true);
        PurchaseQuote.Run();
        AssertCompanyFields('CompanyInfoBusinessIdCode', 'CompanyInfoRegHomeCity');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseQuoteReportHandler(var PurchaseQuoteRequestPage: TestRequestPage "Purchase - Quote")
    var
        DocumentNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        PurchaseQuoteRequestPage."Purchase Header".SetFilter("No.", Format(DocumentNumber));
        PurchaseQuoteRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderReportHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderReport()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: Report Order;
    begin
        Initialize();

        CreatePurchaseDocument(PurchaseHeader."Document Type"::Order, false);
        PurchaseOrder.UseRequestPage(true);
        PurchaseOrder.Run();
        AssertCompanyFields('CompanyInfoBusinessIdCode', 'CompanyInfoRegHomeCity');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderReportHandler(var PurchaseOrderRequestPage: TestRequestPage Order)
    var
        DocumentNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        PurchaseOrderRequestPage."Purchase Header".SetFilter("No.", Format(DocumentNumber));
        PurchaseOrderRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Test]
    [HandlerFunctions('PurchaseInvoiceReportHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceReport()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: Report "Purchase - Invoice";
    begin
        Initialize();

        CreatePurchaseDocument(PurchaseHeader."Document Type"::Invoice, true);
        PurchaseInvoice.UseRequestPage(true);
        PurchaseInvoice.Run();
        AssertCompanyFields('CompanyInfoBusinessIdCode', 'CompanyInfoRegHomeCity');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceReportHandler(var PurchaseInvoiceRequestPage: TestRequestPage "Purchase - Invoice")
    var
        DocumentNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        PurchaseInvoiceRequestPage."Purch. Inv. Header".SetFilter("No.", Format(DocumentNumber));
        PurchaseInvoiceRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Test]
    [HandlerFunctions('PurchaseCreditMemoReportHandler')]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoReport()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemo: Report "Purchase - Credit Memo";
    begin
        Initialize();

        CreatePurchaseDocument(PurchaseHeader."Document Type"::"Credit Memo", true);
        PurchaseCreditMemo.UseRequestPage(true);
        PurchaseCreditMemo.Run();
        AssertCompanyFields('CompanyInfoBusinessIdCode', 'CompanyInfoRegHomeCity');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoReportHandler(var PurchaseCreditMemoRequestPage: TestRequestPage "Purchase - Credit Memo")
    var
        DocumentNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        PurchaseCreditMemoRequestPage."Purch. Cr. Memo Hdr.".SetFilter("No.", Format(DocumentNumber));
        PurchaseCreditMemoRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Test]
    [HandlerFunctions('PurchaseReceiptReportHandler')]
    [Scope('OnPrem')]
    procedure PurchaseReceiptReport()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseReceipt: Report "Purchase - Receipt";
    begin
        Initialize();

        CreatePurchaseDocument(PurchaseHeader."Document Type"::Order, true);
        PurchaseReceipt.UseRequestPage(true);
        PurchaseReceipt.Run();
        AssertCompanyFields('CompanyInfoBusinessIdCode', 'CompanyInfoRegHomeCity');
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
        PurchaseReceiptRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Test]
    [HandlerFunctions('BlanketPurchaseOrderReportHandler')]
    [Scope('OnPrem')]
    procedure BlanketPurchaseOrderReport()
    var
        PurchaseHeader: Record "Purchase Header";
        BlanketPurchaseOrder: Report "Blanket Purchase Order";
    begin
        Initialize();

        CreatePurchaseDocument(PurchaseHeader."Document Type"::"Blanket Order", false);
        BlanketPurchaseOrder.UseRequestPage(true);
        BlanketPurchaseOrder.Run();
        AssertCompanyFields('CompanyInfoBusinessIdCode', 'CompanyInfoRegHomeCity');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BlanketPurchaseOrderReportHandler(var BlanketPurchaseOrderRequestPage: TestRequestPage "Blanket Purchase Order")
    var
        DocumentNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        BlanketPurchaseOrderRequestPage."Purchase Header".SetFilter("No.", Format(DocumentNumber));
        BlanketPurchaseOrderRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Test]
    [HandlerFunctions('ServiceOrderReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderReport()
    var
        ServiceHeader: Record "Service Header";
        ServiceOrder: Report "Service Order (FI)";
    begin
        Initialize();

        CreateServiceDocument(ServiceHeader."Document Type"::Order, false);
        ServiceOrder.UseRequestPage(true);
        ServiceOrder.Run();
        AssertCompanyFields('CompanyInfoBusinessIdCode', 'CompanyInfoegHomeCity');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceOrderReportHandler(var ServiceOrderRequestPage: TestRequestPage "Service Order (FI)")
    var
        DocumentNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        ServiceOrderRequestPage."Service Header".SetFilter("No.", Format(DocumentNumber));
        ServiceOrderRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Test]
    [HandlerFunctions('ServiceQuoteReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceQuoteReport()
    var
        ServiceHeader: Record "Service Header";
        ServiceQuote: Report "Service Quote (FI)";
    begin
        Initialize();

        CreateServiceDocument(ServiceHeader."Document Type"::Quote, false);
        ServiceQuote.UseRequestPage(true);
        ServiceQuote.Run();
        AssertCompanyFields('CompanyInfoBusinessIdCode', 'CompanyInfoRegHomeCity');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceQuoteReportHandler(var ServiceQuoteRequestPage: TestRequestPage "Service Quote (FI)")
    var
        DocumentNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        ServiceQuoteRequestPage."Service Header".SetFilter("No.", Format(DocumentNumber));
        ServiceQuoteRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Test]
    [HandlerFunctions('ServiceInvoiceReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceReport()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoice: Report "Service - Invoice (FI)";
    begin
        Initialize();

        CreateServiceDocument(ServiceHeader."Document Type"::Invoice, true);
        ServiceInvoice.UseRequestPage(true);
        ServiceInvoice.Run();
        AssertCompanyFields('CompanyInfoBusinessIDCode', 'CompanyInfoRegHomeCity');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceInvoiceReportHandler(var ServiceInvoiceRequestPage: TestRequestPage "Service - Invoice (FI)")
    var
        DocumentNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        ServiceInvoiceRequestPage."Service Invoice Header".SetFilter("No.", Format(DocumentNumber));
        ServiceInvoiceRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Test]
    [HandlerFunctions('ServiceContractReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceContractReport()
    var
        FiledServiceContractHeader: Record "Filed Service Contract Header";
        ServiceContract: Report "Service Contract (FI)";
    begin
        Initialize();

        CreateServiceContract(FiledServiceContractHeader."Contract Type"::Contract);
        ServiceContract.UseRequestPage(true);
        ServiceContract.Run();
        AssertCompanyFields('CompanyInfoBusinessIdCode', 'CompanyInfoRegHomeCity');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceContractReportHandler(var ServiceContractRequestPage: TestRequestPage "Service Contract (FI)")
    var
        DocumentNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        ServiceContractRequestPage."Service Contract Header".SetFilter("Contract No.", Format(DocumentNumber));
        ServiceContractRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Test]
    [HandlerFunctions('ServiceContractQuoteReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceContractQuoteReport()
    var
        FiledServiceContractHeader: Record "Filed Service Contract Header";
        ServiceContractQuote: Report "Service Contract Quote (FI)";
    begin
        Initialize();

        CreateServiceContract(FiledServiceContractHeader."Contract Type"::Quote);
        ServiceContractQuote.UseRequestPage(true);
        ServiceContractQuote.Run();
        AssertCompanyFields('CompanyInfoBusinessIdCode', 'CompanyInfoRegHomeCity');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceContractQuoteReportHandler(var ServiceContractQuoteRequestPage: TestRequestPage "Service Contract Quote (FI)")
    var
        DocumentNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        ServiceContractQuoteRequestPage."Service Contract Header".SetFilter("Contract No.", Format(DocumentNumber));
        ServiceContractQuoteRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    procedure StandardSalesQuoteReportRequestPageHandler(var StandardSalesQuote: TestRequestPage "Standard Sales - Quote")
    begin
    end;

    [RequestPageHandler]
    procedure VATVIESDeclarationTaxAuthReportRequestPageHandler(var VATVIESDeclarationTaxAuthReport: TestRequestPage "VAT- VIES Declaration Tax Auth")
    begin
        VATVIESDeclarationTaxAuthReport.SaveAsXml(
            LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}
