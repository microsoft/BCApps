codeunit 144010 "Company Field Report Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        CompanyInformation: Record "Company Information";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        Assert: Codeunit Assert;
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        TenDigitsTxt: Label '0123456789';
        LibraryERM: Codeunit "Library - ERM";
        VendorCrMemoNoTxt: Label '123';

    local procedure Initialize()
    var
        SalesAndReceivablesSetup: Record "Sales & Receivables Setup";
        FeatureKey: Record "Feature Key";
        FeatureKeyUpdateStatus: Record "Feature Data Update Status";
    begin
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibrarySales.SetStockoutWarning(false);
        LibraryVariableStorage.Clear();
        
        if FeatureKey.Get('ReminderTermsCommunicationTexts') then begin
            FeatureKey.Enabled := FeatureKey.Enabled::None;
            FeatureKey.Modify();
        end;
        if FeatureKeyUpdateStatus.Get('ReminderTermsCommunicationTexts', CompanyName()) then begin
            FeatureKeyUpdateStatus."Feature Status" := FeatureKeyUpdateStatus."Feature Status"::Disabled;
            FeatureKeyUpdateStatus.Modify();
        end;

        LibraryReportDataset.Reset();
        CompanyInformation.FindFirst();
        CompanyInformation."Business Identity Code" := TenDigitsTxt + TenDigitsTxt;
        CompanyInformation."Registered Home City" := TenDigitsTxt + TenDigitsTxt + TenDigitsTxt + TenDigitsTxt + TenDigitsTxt;
        CompanyInformation.Modify();

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

    local procedure CreateRefNumberSeries(StartIngNo: Code[20]): Code[10]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        LibraryUtility.CreateNoSeries(NoSeries, true, true, false);
        // Spcifically specify the ending No as numerical or the number series will not be numerical
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, StartIngNo, '9999');
        exit(NoSeries.Code);
    end;

    local procedure CreateSalesDocument(Type: Enum "Sales Document Type"; Post: Boolean): Text
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        DocumentNumber: Variant;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, Type, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(1000));
        if Post then
            DocumentNumber := LibrarySales.PostSalesDocument(SalesHeader, true, true)
        else
            DocumentNumber := SalesHeader."No.";
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
            PurchaseHeader."Vendor Cr. Memo No." := VendorCrMemoNoTxt;
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(1000));
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
        LibraryService: Codeunit "Library - Service";
        DocumentNumber: Variant;
    begin
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, Type, Customer."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
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
        LibraryService: Codeunit "Library - Service";
        DocumentNumber: Variant;
    begin
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractType, Customer."No.");
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        DocumentNumber := ServiceContractHeader."Contract No.";
        LibraryVariableStorage.Enqueue(DocumentNumber);
        Commit();
        exit(DocumentNumber);
    end;

    local procedure TestBusinessIdentityandHomeCity(ReportType: Integer)
    var
        CompanyInfoRegHomeCity: Variant;
        CompanyInfoBusinessIdCode: Variant;
        I: Integer;
    begin
        LibraryReportDataset.LoadDataSetFile();
        Assert.IsTrue(LibraryReportDataset.RowCount() > 0, 'Empty Dataset');
        for I := 0 to LibraryReportDataset.RowCount() - 1 do begin
            LibraryReportDataset.GetNextRow();
            case ReportType of
                0:
                    begin
                        LibraryReportDataset.GetElementValueInCurrentRow('CompanyInfoBusinessIdCode', CompanyInfoBusinessIdCode);
                        LibraryReportDataset.GetElementValueInCurrentRow('CompanyInfoRegHomeCity', CompanyInfoRegHomeCity);
                    end;
                1:
                    begin
                        LibraryReportDataset.GetElementValueInCurrentRow('BusinessIdCode_CompanyInfo', CompanyInfoBusinessIdCode);
                        LibraryReportDataset.GetElementValueInCurrentRow('RegHomeCity_CompanyInfo', CompanyInfoRegHomeCity);
                    end;
                2:
                    begin
                        LibraryReportDataset.GetElementValueInCurrentRow('CompanyInfoBusinessIdCode', CompanyInfoBusinessIdCode);
                        LibraryReportDataset.GetElementValueInCurrentRow('CompanyInfoegHomeCity', CompanyInfoRegHomeCity);
                    end;
                3:
                    begin
                        LibraryReportDataset.GetElementValueInCurrentRow('CompanyInfoBusinessIdentityCode', CompanyInfoBusinessIdCode);
                        LibraryReportDataset.GetElementValueInCurrentRow('CompanyInfoRegisteredHomeCity', CompanyInfoRegHomeCity);
                    end;
                4:
                    begin
                        LibraryReportDataset.GetElementValueInCurrentRow('CompanyInfoBusinessIDCode', CompanyInfoBusinessIdCode);
                        LibraryReportDataset.GetElementValueInCurrentRow('CompanyInfoRegHomeCity', CompanyInfoRegHomeCity);
                    end;
            end;
            Assert.AreEqual(CompanyInformation."Business Identity Code", CompanyInfoBusinessIdCode, 'Incorrect BusinessIdentityCode');
            Assert.AreEqual(CompanyInformation."Registered Home City", CompanyInfoRegHomeCity, 'Incorrect RegisteredHomeCity');
        end;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmUIHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATVIESDeclarationTaxAuthReportHandler(var VATVIESDeclarationTaxAuthReport: TestRequestPage "VAT- VIES Declaration Tax Auth")
    begin
        VATVIESDeclarationTaxAuthReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Test]
    [HandlerFunctions('VATVIESDeclarationTaxAuthReportHandler')]
    [Scope('OnPrem')]
    procedure VATVIESDeclarationTaxAuthReport()
    var
        VATVIESDeclarationTaxAuthReport: Report "VAT- VIES Declaration Tax Auth";
    begin
        Initialize();

        VATVIESDeclarationTaxAuthReport.UseRequestPage(true);
        VATVIESDeclarationTaxAuthReport.InitializeRequest(true, WorkDate(), WorkDate() + 365, '');
        VATVIESDeclarationTaxAuthReport.Run();
        TestBusinessIdentityandHomeCity(3);
    end;


    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StatementReportHandler(var StatementReport: TestRequestPage Statement)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetFilter(Amount, '<>0');
        CustLedgerEntry.FindFirst();
        StatementReport."Start Date".SetValue(CustLedgerEntry."Posting Date");
        StatementReport."End Date".SetValue(CustLedgerEntry."Posting Date");
        StatementReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Test]
    [HandlerFunctions('StatementReportHandler')]
    [Scope('OnPrem')]
    procedure TestStatementReport()
    var
        StatementReport: Report Statement;
    begin
        Initialize();
        StatementReport.UseRequestPage(true);
        StatementReport.Run();
        TestBusinessIdentityandHomeCity(0);
    end;

    local procedure ReminderMemoReportInit()
    var
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        Customer: Record Customer;
        Currency: Record Currency;
        Amount: Decimal;
    begin
        Initialize();

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
        Customer."Currency Code" := Currency.Code; // To execise code in Reminder Test Report for test coverage
        Customer.Modify();
        Commit();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReminderReportHandler(var ReminderReport: TestRequestPage Reminder)
    begin
        ReminderReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
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
        ReminderMemoReportInit();

        IssueRemindersReport.UseRequestPage(false);
        IssueRemindersReport.Run();
        ReminderReport.UseRequestPage(true);
        ReminderReport.Run();
        TestBusinessIdentityandHomeCity(0);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReminderTestReportHandler(var ReminderTestReport: TestRequestPage "Reminder - Test")
    begin
        ReminderTestReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Test]
    [HandlerFunctions('ReminderTestReportHandler')]
    [Scope('OnPrem')]
    procedure ReminderMemoTestReport()
    var
        ReminderTestReport: Report "Reminder - Test";
    begin
        Initialize();
        ReminderMemoReportInit();

        ReminderTestReport.UseRequestPage(true);
        ReminderTestReport.Run();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FinanceChargeMemoReportHandler(var FinanceChargeMemoReport: TestRequestPage "Finance Charge Memo")
    begin
        FinanceChargeMemoReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Test]
    [HandlerFunctions('FinanceChargeMemoReportHandler')]
    [Scope('OnPrem')]
    procedure FinanceChargeMemoReport()
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        FinanceChargeMemoReport: Report "Finance Charge Memo";
        CreateFinanceChargeMemos: Report "Create Finance Charge Memos";
        IssueFinanceChargeMemos: Report "Issue Finance Charge Memos";
        LibraryFinanceChargeMemo: Codeunit "Library - Finance Charge Memo";
        PostedDocumentNo: Variant;
    begin
        Initialize();

        PostedDocumentNo := CreateSalesDocument(SalesHeader."Document Type"::Invoice, true);
        LibraryFinanceChargeMemo.CreateFinanceChargeTermAndText(FinanceChargeTerms);
        SalesInvoiceHeader.Get(PostedDocumentNo);
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");
        Customer."Fin. Charge Terms Code" := FinanceChargeTerms.Code;
        Customer.Modify();

        Commit();
        CreateFinanceChargeMemos.UseRequestPage(false);
        CreateFinanceChargeMemos.InitializeRequest(SalesInvoiceHeader."Posting Date", SalesInvoiceHeader."Posting Date");
        CreateFinanceChargeMemos.Run();
        IssueFinanceChargeMemos.UseRequestPage(false);
        IssueFinanceChargeMemos.Run();
        FinanceChargeMemoReport.UseRequestPage(true);
        FinanceChargeMemoReport.Run();
        TestBusinessIdentityandHomeCity(0);
    end;


    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceReportHandler(var SalesInvoiceReport: TestRequestPage "Standard Sales - Invoice")
    var
        DocumentNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        SalesInvoiceReport.Header.SetFilter("No.", Format(DocumentNumber));

        SalesInvoiceReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
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
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesShipmentReportHandler(var SalesShipmentReport: TestRequestPage "Sales - Shipment")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        SalesInvoiceHeader.Get(DocumentNumber);
        SalesShipmentReport."Sales Shipment Header".SetFilter("Order No.", SalesInvoiceHeader."Order No.");

        SalesShipmentReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Test]
    [HandlerFunctions('SalesShipmentReportHandler')]
    [Scope('OnPrem')]
    procedure SalesShipmentReport()
    var
        SalesHeader: Record "Sales Header";
        SalesShipmentReport: Report "Sales - Shipment";
    begin
        Initialize();

        CreateSalesDocument(SalesHeader."Document Type"::Order, true);
        SalesShipmentReport.UseRequestPage(true);
        SalesShipmentReport.Run();
        TestBusinessIdentityandHomeCity(0);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BlanketSalesOrderReportHandler(var BlanketSalesOrderReport: TestRequestPage "Blanket Sales Order")
    var
        DocumentNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        BlanketSalesOrderReport."Sales Header".SetFilter("No.", Format(DocumentNumber));

        BlanketSalesOrderReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Test]
    [HandlerFunctions('BlanketSalesOrderReportHandler')]
    [Scope('OnPrem')]
    procedure BlanketSalesOrderReport()
    var
        SalesHeader: Record "Sales Header";
        BlanketSalesOrderReport: Report "Blanket Sales Order";
    begin
        Initialize();

        CreateSalesDocument(SalesHeader."Document Type"::"Blanket Order", false);
        BlanketSalesOrderReport.UseRequestPage(true);
        BlanketSalesOrderReport.Run();
        TestBusinessIdentityandHomeCity(0);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseQuoteReportHandler(var PurchaseQuoteReport: TestRequestPage "Purchase - Quote")
    var
        DocumentNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        PurchaseQuoteReport."Purchase Header".SetFilter("No.", Format(DocumentNumber));

        PurchaseQuoteReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Test]
    [HandlerFunctions('PurchaseQuoteReportHandler')]
    [Scope('OnPrem')]
    procedure PurchaseQuoteReport()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseQuoteReport: Report "Purchase - Quote";
    begin
        Initialize();

        CreatePurchaseDocument(PurchaseHeader."Document Type"::Quote, false);
        PurchaseQuoteReport.UseRequestPage(true);
        PurchaseQuoteReport.Run();
        TestBusinessIdentityandHomeCity(0);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderReportHandler(var PurchaseOrderReport: TestRequestPage "Order")
    var
        DocumentNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        PurchaseOrderReport."Purchase Header".SetFilter("No.", Format(DocumentNumber));

        PurchaseOrderReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderReportHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderReport()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrderReport: Report "Order";
    begin
        Initialize();

        CreatePurchaseDocument(PurchaseHeader."Document Type"::Order, false);
        PurchaseOrderReport.UseRequestPage(true);
        PurchaseOrderReport.Run();
        TestBusinessIdentityandHomeCity(0);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceReportHandler(var PurchaseInvoiceReport: TestRequestPage "Purchase - Invoice")
    var
        DocumentNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        PurchaseInvoiceReport."Purch. Inv. Header".SetFilter("No.", Format(DocumentNumber));

        PurchaseInvoiceReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Test]
    [HandlerFunctions('PurchaseInvoiceReportHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceReport()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoiceReport: Report "Purchase - Invoice";
    begin
        Initialize();

        CreatePurchaseDocument(PurchaseHeader."Document Type"::Invoice, true);
        PurchaseInvoiceReport.UseRequestPage(true);
        PurchaseInvoiceReport.Run();
        TestBusinessIdentityandHomeCity(0);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoReportHandler(var PurchaseCreditMemoReport: TestRequestPage "Purchase - Credit Memo")
    var
        DocumentNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        PurchaseCreditMemoReport."Purch. Cr. Memo Hdr.".SetFilter("No.", Format(DocumentNumber));

        PurchaseCreditMemoReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Test]
    [HandlerFunctions('PurchaseCreditMemoReportHandler')]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoReport()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemoReport: Report "Purchase - Credit Memo";
    begin
        Initialize();

        CreatePurchaseDocument(PurchaseHeader."Document Type"::"Credit Memo", true);
        PurchaseCreditMemoReport.UseRequestPage(true);
        PurchaseCreditMemoReport.Run();
        TestBusinessIdentityandHomeCity(0);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseReceiptReportHandler(var PurchaseReceiptReport: TestRequestPage "Purchase - Receipt")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        DocumentNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        PurchInvHeader.Get(DocumentNumber);
        PurchaseReceiptReport."Purch. Rcpt. Header".SetFilter("Order No.", PurchInvHeader."Order No.");

        PurchaseReceiptReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Test]
    [HandlerFunctions('PurchaseReceiptReportHandler')]
    [Scope('OnPrem')]
    procedure PurchaseReceiptReport()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseReceiptReport: Report "Purchase - Receipt";
    begin
        Initialize();

        CreatePurchaseDocument(PurchaseHeader."Document Type"::Order, true);
        PurchaseReceiptReport.UseRequestPage(true);
        PurchaseReceiptReport.Run();
        TestBusinessIdentityandHomeCity(0);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BlanketPurchaseOrderReportHandler(var BlanketPurchaseOrderReport: TestRequestPage "Blanket Purchase Order")
    var
        DocumentNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        BlanketPurchaseOrderReport."Purchase Header".SetFilter("No.", Format(DocumentNumber));

        BlanketPurchaseOrderReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Test]
    [HandlerFunctions('BlanketPurchaseOrderReportHandler')]
    [Scope('OnPrem')]
    procedure BlanketPurchaseOrderReport()
    var
        PurchaseHeader: Record "Purchase Header";
        BlanketPurchaseOrderReport: Report "Blanket Purchase Order";
    begin
        Initialize();

        CreatePurchaseDocument(PurchaseHeader."Document Type"::"Blanket Order", false);
        BlanketPurchaseOrderReport.UseRequestPage(true);
        BlanketPurchaseOrderReport.Run();
        TestBusinessIdentityandHomeCity(0);
    end;


    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceOrderReportHandler(var ServiceOrderReport: TestRequestPage "Service Order")
    var
        DocumentNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        ServiceOrderReport."Service Header".SetFilter("No.", Format(DocumentNumber));

        ServiceOrderReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Test]
    [HandlerFunctions('ServiceOrderReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderReport()
    var
        ServiceHeader: Record "Service Header";
        ServiceOrderReport: Report "Service Order";
    begin
        Initialize();

        CreateServiceDocument(ServiceHeader."Document Type"::Order, false);
        ServiceOrderReport.UseRequestPage(true);
        ServiceOrderReport.Run();
        TestBusinessIdentityandHomeCity(2);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceQuoteReportHandler(var ServiceQuoteReport: TestRequestPage "Service Quote")
    var
        DocumentNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        ServiceQuoteReport."Service Header".SetFilter("No.", Format(DocumentNumber));

        ServiceQuoteReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Test]
    [HandlerFunctions('ServiceQuoteReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceQuoteReport()
    var
        ServiceHeader: Record "Service Header";
        ServiceQuoteReport: Report "Service Quote";
    begin
        Initialize();

        CreateServiceDocument(ServiceHeader."Document Type"::Quote, false);
        ServiceQuoteReport.UseRequestPage(true);
        ServiceQuoteReport.Run();
        TestBusinessIdentityandHomeCity(0);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceInvoiceReportHandler(var ServiceInvoiceReport: TestRequestPage "Service - Invoice")
    var
        DocumentNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        ServiceInvoiceReport."Service Invoice Header".SetFilter("No.", Format(DocumentNumber));
        ServiceInvoiceReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Test]
    [HandlerFunctions('ServiceInvoiceReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceReport()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceReport: Report "Service - Invoice";
    begin
        Initialize();

        CreateServiceDocument(ServiceHeader."Document Type"::Invoice, true);
        ServiceInvoiceReport.UseRequestPage(true);
        ServiceInvoiceReport.Run();
        TestBusinessIdentityandHomeCity(4);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceContractReportHandler(var ServiceContractReport: TestRequestPage "Service Contract")
    var
        DocumentNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        ServiceContractReport."Service Contract Header".SetFilter("Contract No.", Format(DocumentNumber));

        ServiceContractReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Test]
    [HandlerFunctions('ServiceContractReportHandler,ConfirmUIHandler')]
    [Scope('OnPrem')]
    procedure ServiceContractReport()
    var
        FiledServiceContractHeader: Record "Filed Service Contract Header";
        ServiceContractReport: Report "Service Contract";
    begin
        Initialize();

        CreateServiceContract(FiledServiceContractHeader."Contract Type"::Contract);
        ServiceContractReport.UseRequestPage(true);
        ServiceContractReport.Run();
        TestBusinessIdentityandHomeCity(0);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceContractDetailReportHandler(var ServiceContractDetailReport: TestRequestPage "Service Contract-Detail")
    var
        DocumentNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        ServiceContractDetailReport."Service Contract Header".SetFilter("Contract No.", Format(DocumentNumber));

        ServiceContractDetailReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Test]
    [HandlerFunctions('ServiceContractDetailReportHandler,ConfirmUIHandler')]
    [Scope('OnPrem')]
    procedure ServiceContractDetailReport()
    var
        FiledServiceContractHeader: Record "Filed Service Contract Header";
        ServiceContractDetailReport: Report "Service Contract-Detail";
    begin
        Initialize();

        CreateServiceContract(FiledServiceContractHeader."Contract Type"::Contract);
        ServiceContractDetailReport.UseRequestPage(true);
        ServiceContractDetailReport.Run();
        TestBusinessIdentityandHomeCity(0);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceContractQuoteReportHandler(var ServiceContractQuoteReport: TestRequestPage "Service Contract Quote")
    var
        DocumentNumber: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        ServiceContractQuoteReport."Service Contract Header".SetFilter("Contract No.", Format(DocumentNumber));

        ServiceContractQuoteReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Test]
    [HandlerFunctions('ServiceContractQuoteReportHandler,ConfirmUIHandler')]
    [Scope('OnPrem')]
    procedure ServiceContractQuoteReport()
    var
        FiledServiceContractHeader: Record "Filed Service Contract Header";
        ServiceContractQuoteReport: Report "Service Contract Quote";
    begin
        Initialize();

        CreateServiceContract(FiledServiceContractHeader."Contract Type"::Quote);
        ServiceContractQuoteReport.UseRequestPage(true);
        ServiceContractQuoteReport.Run();
        TestBusinessIdentityandHomeCity(0);
    end;


}
