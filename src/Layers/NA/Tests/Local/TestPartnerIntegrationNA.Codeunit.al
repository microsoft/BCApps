codeunit 141041 "Test Partner Integration NA"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Integration Event]
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        ErrorEventSuscriptionErr: Label 'There are %1 events with error:%2.';
        OnBeforeCalculateSalesTaxStatisticsTxt: Label 'OnBeforeCalculateSalesTaxStats';
#if not CLEAN26
        LibraryPurchase: Codeunit "Library - Purchase";
#endif
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryService: Codeunit "Library - Service";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;
        OnAfterCalculateSalesTaxStatisticsTxt: Label 'OnAfterCalculateSalesTaxStats';
        SalesStatsTxt: Label 'OnBeforeSalesStats';
        ServiceStatsTxt: Label 'OnBeforeServiceStats';
        SalesStatsValidateTxt: Label 'OnBeforeServiceValideStats';
        OnFillInvPostingBufferServAmtsMgtTxt: Label 'OnFillInvPostingBufferServ';
        OnBeforeUpdateSalesTaxOnLinesTxt: Label 'OnBeforeUpdateSalesTaxOnLines';
        OnBeforePostUpdateOrderLineTxt: Label 'OnBeforePostUpdateOrderLine';

    [Scope('OnPrem')]
    procedure Initialize()
    var
        DataTypeBufferNA: Record "Data Type Buffer NA";
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
        TaxJurisdiction: Record "Tax Jurisdiction";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        NoSeries: Record "No. Series";
        MarketingSetup: Record "Marketing Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        TaxGroup: Record "Tax Group";
    begin
        DataTypeBufferNA.DeleteAll(true);

        if IsInitialized then
            exit;

        TaxArea.Init();
        TaxArea.Code := 'X';
        TaxArea.Insert();

        TaxAreaLine.Init();
        TaxAreaLine."Tax Area" := 'X';
        TaxAreaLine."Tax Jurisdiction Code" := 'X';
        TaxAreaLine.Insert();

        TaxJurisdiction.Init();
        TaxJurisdiction.Code := 'X';
        TaxJurisdiction.Insert();

        TaxGroup.Init();
        TaxGroup.Code := 'X';
        TaxGroup.Insert();

        NoSeries.DeleteAll();
        ServiceMgtSetup.DeleteAll();
        SalesReceivablesSetup.DeleteAll();
        PurchasesPayablesSetup.DeleteAll();

        SalesReceivablesSetup."Blanket Order Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup."Quote Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup."Order Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup."Invoice Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup."Credit Memo Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup."Posted Credit Memo Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup."Posted Invoice Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup."Return Order Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup.Insert();

        PurchasesPayablesSetup."Order Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup."Invoice Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup."Posted Invoice Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup.Insert();

        if not ServiceMgtSetup.Get() then
            ServiceMgtSetup.Insert();

        LibraryService.SetupServiceMgtNoSeries();

        LibraryUtility.UpdateSetupNoSeriesCode(
          DATABASE::"Service Mgt. Setup", ServiceMgtSetup.FieldNo("Service Quote Nos."));

        LibraryUtility.UpdateSetupNoSeriesCode(
          DATABASE::"Service Mgt. Setup", ServiceMgtSetup.FieldNo("Service Order Nos."));

        LibraryUtility.UpdateSetupNoSeriesCode(
          DATABASE::"Service Mgt. Setup", ServiceMgtSetup.FieldNo("Service Invoice Nos."));

        LibraryUtility.UpdateSetupNoSeriesCode(
          DATABASE::"Service Mgt. Setup", ServiceMgtSetup.FieldNo("Service Credit Memo Nos."));

        LibraryUtility.UpdateSetupNoSeriesCode(
          DATABASE::"Sales & Receivables Setup", SalesReceivablesSetup.FieldNo("Blanket Order Nos."));

        LibraryUtility.UpdateSetupNoSeriesCode(
          DATABASE::"Marketing Setup", MarketingSetup.FieldNo("Contact Nos."));

        IsInitialized := true;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSubscriptionTableHasNoErrors()
    var
        EventSubscription: Record "Event Subscription";
        SubscribersWithError: Text;
        ErrorEventsCounter: Integer;
    begin
        // [SCENARIO] The Event Subscription table has no errors.
        LibraryLowerPermissions.SetO365Basic();
        EventSubscription.SetFilter("Error Information", '<>%1', '');
        ErrorEventsCounter := EventSubscription.Count;
        if EventSubscription.FindSet() then
            repeat
                SubscribersWithError += StrSubstNo(' %1.%2="%3"', EventSubscription."Subscriber Codeunit ID", EventSubscription."Subscriber Function", EventSubscription."Error Information");
            until EventSubscription.Next() = 0;
        if ErrorEventsCounter > 0 then
            Error(ErrorEventSuscriptionErr, ErrorEventsCounter, SubscribersWithError);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesStatsModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestSalesQuoteOnBeforeCalculateSalesTaxStatistics()
    var
        SalesHeader: Record "Sales Header";
        TestPartnerIntegrationNA: Codeunit "Test Partner Integration NA";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Calling the Statistics action on Sales Quote card will trigger OnBeforeCalculateSalesTaxStatistics.

        // [GIVEN] Sales Quote
        Initialize();
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote);
        BindSubscription(TestPartnerIntegrationNA);

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetOutsideO365Scope();
        // [WHEN] Click the Statistics
        SalesQuote.Trap();
        SalesQuote.OpenView();
        SalesQuote.Statistics.Invoke();

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
        VerifyDataTypeBuffer(SalesStatsTxt);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesStatsModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestSalesQuotesOnBeforeCalculateSalesTaxStatistics()
    var
        SalesHeader: Record "Sales Header";
        TestPartnerIntegrationNA: Codeunit "Test Partner Integration NA";
        SalesQuotes: TestPage "Sales Quotes";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Calling the Statistics action on Sales Quote list will trigger OnBeforeCalculateSalesTaxStatistics.

        // [GIVEN] Sales Quote
        Initialize();
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote);
        BindSubscription(TestPartnerIntegrationNA);

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetOutsideO365Scope();
        // [WHEN] Click the Statistics
        SalesQuotes.Trap();
        SalesQuotes.OpenView();
        SalesQuotes.Statistics.Invoke();

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
        VerifyDataTypeBuffer(SalesStatsTxt);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandler')]
    [Scope('OnPrem')]
    procedure TestSalesOrderOnBeforeCalculateSalesTaxStatistics()
    var
        SalesHeader: Record "Sales Header";
        TestPartnerIntegrationNA: Codeunit "Test Partner Integration NA";
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO] Calling the Statistics action on Sales Order card will trigger OnBeforeCalculateSalesTaxStatistics.

        // [GIVEN] Sales Order
        Initialize();
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order);
        BindSubscription(TestPartnerIntegrationNA);

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetOutsideO365Scope();
        // [WHEN] Click the Statistics
        SalesOrder.Trap();
        SalesOrder.OpenView();
        SalesOrder.Statistics.Invoke();

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
        VerifyDataTypeBuffer(SalesStatsTxt);
    end;
#endif
#if not CLEAN27
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '27.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandler,SalesDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestSalesShipmentOnBeforeCalculateSalesTaxStatistics()
    var
        SalesHeader: Record "Sales Header";
        DataTypeBufferNA: Record "Data Type Buffer NA";
        TestPartnerIntegrationNA: Codeunit "Test Partner Integration NA";
        SalesOrderShipment: TestPage "Sales Order Shipment";
    begin
        // [SCENARIO] Calling the Statistics action on Sales Order Shipment card will trigger OnBeforeCalculateSalesTaxStatistics.

        // [GIVEN] Sales Order
        Initialize();
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order);
        Commit();
        BindSubscription(TestPartnerIntegrationNA);

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetOutsideO365Scope();
        // [WHEN] Click the Statistics
        SalesOrderShipment.Trap();
        SalesOrderShipment.OpenView();
        SalesOrderShipment.Statistics.Invoke();

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
        VerifyDataTypeBuffer(SalesStatsTxt);

        DataTypeBufferNA.DeleteAll(true);

        // [WHEN] Click the Print Report Action
        SalesOrderShipment."Test Report".Invoke();

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
    end;
#endif
#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandler')]
    [Scope('OnPrem')]
    procedure TestSalesOrdersOnBeforeCalculateSalesTaxStatistics()
    var
        SalesHeader: Record "Sales Header";
        TestPartnerIntegrationNA: Codeunit "Test Partner Integration NA";
        SalesOrderList: TestPage "Sales Order List";
    begin
        // [SCENARIO] Calling the Statistics action on Sales Order list will trigger OnBeforeCalculateSalesTaxStatistics.

        // [GIVEN] Sales Order
        Initialize();
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order);
        BindSubscription(TestPartnerIntegrationNA);

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetOutsideO365Scope();
        // [WHEN] Click the Statistics
        SalesOrderList.Trap();
        SalesOrderList.OpenView();
        SalesOrderList.Statistics.Invoke();

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
        VerifyDataTypeBuffer(SalesStatsTxt);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandler,SalesDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestSalesOrderInvoiceOnBeforeCalculateSalesTaxStatistics()
    var
        SalesHeader: Record "Sales Header";
        DataTypeBufferNA: Record "Data Type Buffer NA";
        TestPartnerIntegrationNA: Codeunit "Test Partner Integration NA";
        SalesOrderInvoice: TestPage "Sales Order Invoice";
    begin
        // [SCENARIO] Calling the Statistics action on Sales Order Invoice card will trigger OnBeforeCalculateSalesTaxStatistics.

        // [GIVEN] Sales Invoice
        Initialize();
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order);
        BindSubscription(TestPartnerIntegrationNA);

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetOutsideO365Scope();
        // [WHEN] Click the Statistics
        SalesOrderInvoice.Trap();
        SalesOrderInvoice.OpenView();
        SalesOrderInvoice.Statistics.Invoke();

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
        VerifyDataTypeBuffer(SalesStatsTxt);

        DataTypeBufferNA.DeleteAll(true);

        // [WHEN] Click the Print Report Action
        SalesOrderInvoice."Test Report".Invoke();

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandler')]
    [Scope('OnPrem')]
    procedure TestSalesInvoiceOnBeforeCalculateSalesTaxStatistics()
    var
        SalesHeader: Record "Sales Header";
        TestPartnerIntegrationNA: Codeunit "Test Partner Integration NA";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [SCENARIO] Calling the Statistics action on Sales Invoice card will trigger OnBeforeCalculateSalesTaxStatistics.

        // [GIVEN] Sales Invoice
        Initialize();
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice);
        BindSubscription(TestPartnerIntegrationNA);

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetOutsideO365Scope();
        // [WHEN] Click the Statistics
        SalesInvoice.Trap();
        SalesInvoice.OpenView();
        SalesInvoice.Statistics.Invoke();

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
        VerifyDataTypeBuffer(SalesStatsTxt);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandler')]
    [Scope('OnPrem')]
    procedure TestSalesInvoicesOnBeforeCalculateSalesTaxStatistics()
    var
        SalesHeader: Record "Sales Header";
        TestPartnerIntegrationNA: Codeunit "Test Partner Integration NA";
        SalesInvoiceList: TestPage "Sales Invoice List";
    begin
        // [SCENARIO] Calling the Statistics action on Sales Invoice list will trigger OnBeforeCalculateSalesTaxStatistics.

        // [GIVEN] Sales Invoice
        Initialize();
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice);
        BindSubscription(TestPartnerIntegrationNA);

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetOutsideO365Scope();
        // [WHEN] Click the Statistics
        SalesInvoiceList.Trap();
        SalesInvoiceList.OpenView();
        SalesInvoiceList.Statistics.Invoke();

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
        VerifyDataTypeBuffer(SalesStatsTxt);
    end;
#endif
#if not CLEAN27
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '27.0')]
    [Test]
    [HandlerFunctions('SalesInvoiceStatsPageHandler')]
    [Scope('OnPrem')]
    procedure TestPostedSalesInvoiceOnBeforeCalculateSalesTaxStatistics()
    var
        SalesHeader: Record "Sales Header";
        TestPartnerIntegrationNA: Codeunit "Test Partner Integration NA";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // [SCENARIO] Calling the Statistics action on Posted Sales Invoice will trigger OnBeforeCalculateSalesTaxStatistics.

        // [GIVEN] Posted Sales Invoice
        Initialize();
        CreateSalesInvoice(SalesHeader);
        BindSubscription(TestPartnerIntegrationNA);

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetOutsideO365Scope();
        // [WHEN] Click the Statistics
        PostedSalesInvoice.Trap();
        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.Statistics.Invoke();

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
        VerifyDataTypeBuffer(SalesStatsTxt);
    end;
#endif
    [Test]
    [Scope('OnPrem')]
    procedure TestPostSalesOrderOnBeforePostUpdateOrderLine()
    var
        SalesHeader: Record "Sales Header";
        TestPartnerIntegrationNA: Codeunit "Test Partner Integration NA";
    begin
        // [SCENARIO] Posting a Sales Order will trigger OnBeforePostUpdateOrderLine.

        // [GIVEN] Sales Order
        Initialize();
        BindSubscription(TestPartnerIntegrationNA);

        // [WHEN] COD80.OnRun is executed
        PostSalesOrder(SalesHeader);

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnBeforePostUpdateOrderLineTxt);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandler')]
    [Scope('OnPrem')]
    procedure TestSalesCreditMemoOnBeforeCalculateSalesTaxStatistics()
    var
        SalesHeader: Record "Sales Header";
        TestPartnerIntegrationNA: Codeunit "Test Partner Integration NA";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [SCENARIO] Calling the Statistics action on Sales Credit Memo will trigger OnBeforeCalculateSalesTaxStatistics.

        // [GIVEN] Sales Credit Memo
        Initialize();
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        BindSubscription(TestPartnerIntegrationNA);

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetOutsideO365Scope();
        // [WHEN] Click the Statistics
        SalesCreditMemo.Trap();
        SalesCreditMemo.OpenView();
        SalesCreditMemo.Statistics.Invoke();

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
        VerifyDataTypeBuffer(SalesStatsTxt);
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandler')]
    [Scope('OnPrem')]
    procedure TestSalesReturnOrderOnBeforeCalculateSalesTaxStatistics()
    var
        SalesHeader: Record "Sales Header";
        TestPartnerIntegrationNA: Codeunit "Test Partner Integration NA";
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // [SCENARIO] Calling the Statistics action on Sales Order Return card will trigger OnBeforeCalculateSalesTaxStatistics.

        // [GIVEN] Sales Return Order
        Initialize();
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order");
        BindSubscription(TestPartnerIntegrationNA);

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetOutsideO365Scope();
        // [WHEN] Click the Statistics
        SalesReturnOrder.Trap();
        SalesReturnOrder.OpenView();
        SalesReturnOrder.Statistics.Invoke();

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
        VerifyDataTypeBuffer(SalesStatsTxt);
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandler')]
    [Scope('OnPrem')]
    procedure TestSalesReturnOrdersOnBeforeCalculateSalesTaxStatistics()
    var
        SalesHeader: Record "Sales Header";
        TestPartnerIntegrationNA: Codeunit "Test Partner Integration NA";
        SalesReturnOrderList: TestPage "Sales Return Order List";
    begin
        // [SCENARIO] Calling the Statistics action on Sales Order Return list will trigger OnBeforeCalculateSalesTaxStatistics.

        // [GIVEN] Sales Return Order
        Initialize();
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order");
        BindSubscription(TestPartnerIntegrationNA);

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetOutsideO365Scope();
        // [WHEN] Click the Statistics
        SalesReturnOrderList.Trap();
        SalesReturnOrderList.OpenView();
        SalesReturnOrderList.Statistics.Invoke();

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
        VerifyDataTypeBuffer(SalesStatsTxt);
    end;
#endif
#if not CLEAN27
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '27.0')]
    [Test]
    [HandlerFunctions('SalesCreditMemoStatsPageHandler')]
    [Scope('OnPrem')]
    procedure TestPostedSalesCreditMemoOnBeforeCalculateSalesTaxStatistics()
    var
        SalesHeader: Record "Sales Header";
        TestPartnerIntegrationNA: Codeunit "Test Partner Integration NA";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        // [SCENARIO] Calling the Statistics action on the Posted Sales Credit Memo card page will trigger OnAfterCalculateSalesTaxStatistics.

        // [GIVEN] Posted Sales Credit Memo
        Initialize();
        CreateSalesCreditMemo(SalesHeader);
        BindSubscription(TestPartnerIntegrationNA);

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetOutsideO365Scope();
        // [WHEN] Click the Statistics
        PostedSalesCreditMemo.Trap();
        PostedSalesCreditMemo.OpenView();
        PostedSalesCreditMemo.Statistics.Invoke();

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
        VerifyDataTypeBuffer(OnAfterCalculateSalesTaxStatisticsTxt);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '27.0')]
    [Test]
    [HandlerFunctions('SalesCreditMemoStatsPageHandler')]
    [Scope('OnPrem')]
    procedure TestPostedSalesCreditMemosOnBeforeCalculateSalesTaxStatistics()
    var
        SalesHeader: Record "Sales Header";
        TestPartnerIntegrationNA: Codeunit "Test Partner Integration NA";
        PostedSalesCreditMemos: TestPage "Posted Sales Credit Memos";
    begin
        // [SCENARIO] Calling the Statistics action on the Posted Sales Credit Memos list page will trigger OnAfterCalculateSalesTaxStatistics.

        // [GIVEN] Posted Sales Credit Memo
        Initialize();
        CreateSalesCreditMemo(SalesHeader);
        BindSubscription(TestPartnerIntegrationNA);

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetOutsideO365Scope();
        // [WHEN] Click the Statistics
        PostedSalesCreditMemos.Trap();
        PostedSalesCreditMemos.OpenView();
        PostedSalesCreditMemos.Statistics.Invoke();

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
        VerifyDataTypeBuffer(OnAfterCalculateSalesTaxStatisticsTxt);
    end;
#endif
    [Test]
    [Scope('OnPrem')]
    procedure TestSalesPostPrepaymentsOnBeforeUpdateSalesTaxOnLines()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TestPartnerIntegrationNA: Codeunit "Test Partner Integration NA";
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
        DocumentType: Option Invoice,"Credit Memo";
    begin
        // [SCENARIO] Calling Sales-Post Prepayments.FillInvPostingBuffer will trigger OnFillInvPostingBuffer.

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] Service Header
        Initialize();
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice);
        CreateSalesLine(SalesLine, SalesHeader);

        BindSubscription(TestPartnerIntegrationNA);

        // [WHEN] Serv-Amounts Mgt.FillInvPostingBuffer
        SalesPostPrepayments.UpdateSalesTaxOnLines(SalesLine, false, DocumentType::Invoice);

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnBeforeUpdateSalesTaxOnLinesTxt);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandler')]
    [Scope('OnPrem')]
    procedure TestBlanketSalesOrderOnBeforeCalculateSalesTaxStatistics()
    var
        SalesHeader: Record "Sales Header";
        TestPartnerIntegrationNA: Codeunit "Test Partner Integration NA";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
    begin
        // [SCENARIO] Calling the Statistics action on Sales Blanket Order card will trigger OnBeforeCalculateSalesTaxStatistics.

        // [GIVEN] Sales Blanket Order
        Initialize();
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order");
        BindSubscription(TestPartnerIntegrationNA);

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetOutsideO365Scope();
        // [WHEN] Click the Statistics
        BlanketSalesOrder.Trap();
        BlanketSalesOrder.OpenView();
        BlanketSalesOrder.Statistics.Invoke();

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
        VerifyDataTypeBuffer(SalesStatsTxt);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandler')]
    [Scope('OnPrem')]
    procedure TestBlanketSalesOrdersOnBeforeCalculateSalesTaxStatistics()
    var
        SalesHeader: Record "Sales Header";
        TestPartnerIntegrationNA: Codeunit "Test Partner Integration NA";
        BlanketSalesOrders: TestPage "Blanket Sales Orders";
    begin
        // [SCENARIO] Calling the Statistics action on Blanket Sales Order list will trigger OnBeforeCalculateSalesTaxStatistics.

        // [GIVEN] Sales Blanket Order
        Initialize();
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order");
        BindSubscription(TestPartnerIntegrationNA);

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetOutsideO365Scope();
        // [WHEN] Click the Statistics
        BlanketSalesOrders.Trap();
        BlanketSalesOrders.OpenView();
        BlanketSalesOrders.Statistics.Invoke();

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
        VerifyDataTypeBuffer(SalesStatsTxt);
    end;
#endif

    [Test]
    [HandlerFunctions('SalesBlanketOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestBlanketSalesOrderReport()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TestPartnerIntegrationNA: Codeunit "Test Partner Integration NA";
    begin
        // [SCENARIO] Calling Report Sales Blanket Order will trigger OnAfterCalculateSalesTax.

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] Sales Header
        Initialize();
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order");
        CreateSalesLine(SalesLine, SalesHeader);
        Commit();

        BindSubscription(TestPartnerIntegrationNA);

        // [WHEN] Report Sales Blanket Order is executed
        REPORT.Run(REPORT::"Sales Blanket Order");

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnAfterCalculateSalesTaxStatisticsTxt);
    end;

    [Test]
    [HandlerFunctions('SalesOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestSalesOrderReport()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TestPartnerIntegrationNA: Codeunit "Test Partner Integration NA";
    begin
        // [SCENARIO] Calling Report Sales Order will trigger OnAfterCalculateSalesTax.

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] Sales Header
        Initialize();
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order);
        CreateSalesLine(SalesLine, SalesHeader);
        Commit();

        BindSubscription(TestPartnerIntegrationNA);

        // [WHEN] Report Sales Order is executed
        REPORT.Run(REPORT::"Sales Order");

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnAfterCalculateSalesTaxStatisticsTxt);
    end;

    [Test]
    [HandlerFunctions('SalesQuoteRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestSalesQuoteReport()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TestPartnerIntegrationNA: Codeunit "Test Partner Integration NA";
    begin
        // [SCENARIO] Calling Report Sales Quote will trigger OnAfterCalculateSalesTax.

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] Sales Header
        Initialize();
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote);
        CreateSalesLine(SalesLine, SalesHeader);
        Commit();

        BindSubscription(TestPartnerIntegrationNA);

        // [WHEN] Report Sales Quote is executed
        REPORT.Run(REPORT::"Sales Quote NA");

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnAfterCalculateSalesTaxStatisticsTxt);
    end;

    [Test]
    [HandlerFunctions('SalesDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestSalesDocumentTestReport()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TestPartnerIntegrationNA: Codeunit "Test Partner Integration NA";
    begin
        // [SCENARIO] Calling Report Sales Document Test will trigger OnAfterCalculateSalesTax.

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] Sales Header
        Initialize();
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order);
        CreateSalesLine(SalesLine, SalesHeader);
        Commit();

        BindSubscription(TestPartnerIntegrationNA);

        // [WHEN] Report Sales Document Test is executed
        REPORT.Run(REPORT::"Sales Document - Test", true, false, SalesHeader);

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnAfterCalculateSalesTaxStatisticsTxt);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatsPageHandler')]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderOnBeforeCalculateSalesTaxStatistics()
    var
        PurchaseHeader: Record "Purchase Header";
        TestPartnerIntegrationNA: Codeunit "Test Partner Integration NA";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Calling the Statistics action on Purchase Order card will trigger OnBeforeCalculateSalesTaxStatistics.

        // [GIVEN] Purchase Header
        Initialize();
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        BindSubscription(TestPartnerIntegrationNA);

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetOutsideO365Scope();
        // [WHEN] Click the Statistics
        PurchaseOrder.Trap();
        PurchaseOrder.OpenView();
        PurchaseOrder.Statistics.Invoke();

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
    end;
#endif

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatsPageHandler')]
    [Scope('OnPrem')]
    procedure TestPurchaseOrdersOnBeforeCalculateSalesTaxStatistics()
    var
        PurchaseHeader: Record "Purchase Header";
        TestPartnerIntegrationNA: Codeunit "Test Partner Integration NA";
        PurchaseOrderList: TestPage "Purchase Order List";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Calling the Statistics action on Purchase Order list will trigger OnBeforeCalculateSalesTaxStatistics.

        // [GIVEN] Purchase Header
        Initialize();
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        BindSubscription(TestPartnerIntegrationNA);

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetOutsideO365Scope();
        // [WHEN] Click the Statistics
        PurchaseOrderList.Trap();
        PurchaseOrderList.OpenView();
        PurchaseOrderList.Statistics.Invoke();

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
    end;
#endif

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseInvoiceStatsPageHandler')]
    [Scope('OnPrem')]
    procedure TestPurchaseInvoiceOnBeforeCalculateSalesTaxStatistics()
    var
        PurchaseHeader: Record "Purchase Header";
        TestPartnerIntegrationNA: Codeunit "Test Partner Integration NA";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Calling the Statistics action on Purchase Invoice card will trigger OnBeforeCalculateSalesTaxStatistics.

        // [GIVEN] Purchase Header
        Initialize();
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);
        BindSubscription(TestPartnerIntegrationNA);

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetOutsideO365Scope();
        // [WHEN] Click the Statistics
        PurchaseInvoice.Trap();
        PurchaseInvoice.OpenView();
        PurchaseInvoice.Statistics.Invoke();

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
    end;

    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseInvoiceStatsPageHandler')]
    [Scope('OnPrem')]
    procedure TestPurchaseInvoicesOnBeforeCalculateSalesTaxStatistics()
    var
        PurchaseHeader: Record "Purchase Header";
        TestPartnerIntegrationNA: Codeunit "Test Partner Integration NA";
        PurchaseInvoices: TestPage "Purchase Invoices";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Calling the Statistics action on Purchase Invoices list will trigger OnBeforeCalculateSalesTaxStatistics.

        // [GIVEN] Purchase Header
        Initialize();
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);
        BindSubscription(TestPartnerIntegrationNA);

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetOutsideO365Scope();
        // [WHEN] Click the Statistics
        PurchaseInvoices.Trap();
        PurchaseInvoices.OpenView();
        PurchaseInvoices.Statistics.Invoke();

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
    end;
#endif

#if not CLEAN26
    [Obsolete('Use events in OpenStatistics() procedure in table Service Header', '26.0')]
    [Test]
    [HandlerFunctions('ServiceStatsPageHandler')]
    [Scope('OnPrem')]
    procedure TestServiceQuoteOnBeforeCalculateSalesTaxStatistics()
    var
        ServiceHeader: Record "Service Header";
        TestPartnerIntegrationNA: Codeunit "Test Partner Integration NA";
        ServiceQuote: TestPage "Service Quote";
    begin
        // [FEATURE] [Service]
        // [SCENARIO] Calling the Statistics action on Service Quote card will trigger OnBeforeCalculateSalesTaxStatistics.

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] Service Quote
        Initialize();

        CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote);
        BindSubscription(TestPartnerIntegrationNA);

        // [WHEN] Click the Statistics
        ServiceQuote.Trap();
        ServiceQuote.OpenView();
        ServiceQuote.Statistics.Invoke();

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
        VerifyDataTypeBuffer(ServiceStatsTxt);
        VerifyDataTypeBuffer(SalesStatsValidateTxt);
    end;

    [Obsolete('Use events in OpenStatistics() procedure in table Service Header', '26.0')]
    [Test]
    [HandlerFunctions('ServiceStatsPageHandler')]
    [Scope('OnPrem')]
    procedure TestServiceQuotesOnBeforeCalculateSalesTaxStatistics()
    var
        ServiceHeader: Record "Service Header";
        TestPartnerIntegrationNA: Codeunit "Test Partner Integration NA";
        ServiceQuotes: TestPage "Service Quotes";
    begin
        // [FEATURE] [Service]
        // [SCENARIO] Calling the Statistics action on Service Quote list will trigger OnBeforeCalculateSalesTaxStatistics.

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] Service Quote
        Initialize();

        CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote);
        BindSubscription(TestPartnerIntegrationNA);

        // [WHEN] Click the Statistics
        ServiceQuotes.Trap();
        ServiceQuotes.OpenView();
        ServiceQuotes.Statistics.Invoke();

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
        VerifyDataTypeBuffer(ServiceStatsTxt);
        VerifyDataTypeBuffer(SalesStatsValidateTxt);
    end;

    [Obsolete('Use events in OpenStatistics() procedure in table Service Header', '26.0')]
    [Test]
    [HandlerFunctions('ServiceOrderStatsPageHandler')]
    [Scope('OnPrem')]
    procedure TestServiceOrderOnBeforeCalculateSalesTaxStatistics()
    var
        ServiceHeader: Record "Service Header";
        TestPartnerIntegrationNA: Codeunit "Test Partner Integration NA";
        ServiceOrder: TestPage "Service Order";
    begin
        // [SCENARIO] Calling the Statistics action on Service Order card will trigger OnBeforeCalculateSalesTaxStatistics.

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] Service Order
        Initialize();

        CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order);
        BindSubscription(TestPartnerIntegrationNA);

        // [WHEN] Click the Statistics
        ServiceOrder.Trap();
        ServiceOrder.OpenView();
        ServiceOrder.Statistics.Invoke();

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
        VerifyDataTypeBuffer(ServiceStatsTxt);
        VerifyDataTypeBuffer(SalesStatsValidateTxt);
    end;

    [Obsolete('Use events in OpenStatistics() procedure in table Service Header', '26.0')]
    [Test]
    [HandlerFunctions('ServiceOrderStatsPageHandler')]
    [Scope('OnPrem')]
    procedure TestServiceOrdersOnBeforeCalculateSalesTaxStatistics()
    var
        ServiceHeader: Record "Service Header";
        TestPartnerIntegrationNA: Codeunit "Test Partner Integration NA";
        ServiceOrders: TestPage "Service Orders";
    begin
        // [SCENARIO] Calling the Statistics action on Service Order list will trigger OnBeforeCalculateSalesTaxStatistics.

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] Service Order
        Initialize();

        CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order);
        BindSubscription(TestPartnerIntegrationNA);

        // [WHEN] Click the Statistics
        ServiceOrders.Trap();
        ServiceOrders.OpenView();
        ServiceOrders.Statistics.Invoke();

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
        VerifyDataTypeBuffer(ServiceStatsTxt);
        VerifyDataTypeBuffer(SalesStatsValidateTxt);
    end;

    [Obsolete('Use events in OpenStatistics() procedure in table Service Header', '26.0')]
    [Test]
    [HandlerFunctions('ServiceStatsPageHandler')]
    [Scope('OnPrem')]
    procedure TestServiceInvoiceOnBeforeCalculateSalesTaxStatistics()
    var
        ServiceHeader: Record "Service Header";
        TestPartnerIntegrationNA: Codeunit "Test Partner Integration NA";
        ServiceInvoice: TestPage "Service Invoice";
    begin
        // [SCENARIO] Calling the Statistics action on Service Invoice card will trigger OnBeforeCalculateSalesTaxStatistics.

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] Service Invoice
        Initialize();

        CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice);
        BindSubscription(TestPartnerIntegrationNA);

        // [WHEN] Click the Statistics
        ServiceInvoice.Trap();
        ServiceInvoice.OpenView();
        ServiceInvoice.Statistics.Invoke();

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
        VerifyDataTypeBuffer(ServiceStatsTxt);
        VerifyDataTypeBuffer(SalesStatsValidateTxt);
    end;

    [Obsolete('Use events in OpenStatistics() procedure in table Service Header', '26.0')]
    [Test]
    [HandlerFunctions('ServiceStatsPageHandler')]
    [Scope('OnPrem')]
    procedure TestServiceInvoicesOnBeforeCalculateSalesTaxStatistics()
    var
        ServiceHeader: Record "Service Header";
        TestPartnerIntegrationNA: Codeunit "Test Partner Integration NA";
        ServiceInvoices: TestPage "Service Invoices";
    begin
        // [SCENARIO] Calling the Statistics action on Service Invoice list will trigger OnBeforeCalculateSalesTaxStatistics.

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] Service Invoice
        Initialize();

        CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice);
        BindSubscription(TestPartnerIntegrationNA);

        // [WHEN] Click the Statistics
        ServiceInvoices.Trap();
        ServiceInvoices.OpenView();
        ServiceInvoices.Statistics.Invoke();

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
        VerifyDataTypeBuffer(ServiceStatsTxt);
        VerifyDataTypeBuffer(SalesStatsValidateTxt);
    end;

    [Obsolete('Use events in OpenStatistics() procedure in table Service Header', '26.0')]
    [Test]
    [HandlerFunctions('ServiceInvoiceStatsPageHandler')]
    [Scope('OnPrem')]
    procedure TestPostedServiceInvoiceOnBeforeCalculateSalesTaxStatistics()
    var
        ServiceHeader: Record "Service Header";
        TestPartnerIntegrationNA: Codeunit "Test Partner Integration NA";
        PostedServiceInvoice: TestPage "Posted Service Invoice";
    begin
        // [SCENARIO] Calling the Statistics action on Posted Service Invoice card page will trigger OnBeforeCalculateSalesTaxStatistics.

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] Service Invoice
        Initialize();

        CreateServiceInvoice(ServiceHeader);
        BindSubscription(TestPartnerIntegrationNA);

        // [WHEN] Click the Statistics
        PostedServiceInvoice.Trap();
        PostedServiceInvoice.OpenView();
        PostedServiceInvoice.Statistics.Invoke();

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnAfterCalculateSalesTaxStatisticsTxt);
    end;

    [Obsolete('Use events in OpenStatistics() procedure in table Service Header', '26.0')]
    [Test]
    [HandlerFunctions('ServiceInvoiceStatsPageHandler')]
    [Scope('OnPrem')]
    procedure TestPostedServiceInvoicesOnBeforeCalculateSalesTaxStatistics()
    var
        ServiceHeader: Record "Service Header";
        TestPartnerIntegrationNA: Codeunit "Test Partner Integration NA";
        PostedServiceInvoices: TestPage "Posted Service Invoices";
    begin
        // [SCENARIO] Calling the Statistics action on Posted Service Invoices List page will trigger OnBeforeCalculateSalesTaxStatistics.

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] Service Invoice
        Initialize();

        CreateServiceInvoice(ServiceHeader);
        BindSubscription(TestPartnerIntegrationNA);

        // [WHEN] Click the Statistics
        PostedServiceInvoices.Trap();
        PostedServiceInvoices.OpenView();
        PostedServiceInvoices.Statistics.Invoke();

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnAfterCalculateSalesTaxStatisticsTxt);
    end;

    [Obsolete('Use events in OpenStatistics() procedure in table Service Header', '26.0')]
    [Test]
    [HandlerFunctions('ServiceStatsPageHandler')]
    [Scope('OnPrem')]
    procedure TestServiceCreditMemoOnBeforeCalculateSalesTaxStatistics()
    var
        ServiceHeader: Record "Service Header";
        TestPartnerIntegrationNA: Codeunit "Test Partner Integration NA";
        ServiceCreditMemo: TestPage "Service Credit Memo";
    begin
        // [SCENARIO] Calling the Statistics action on Service Credit Memo card will trigger OnBeforeCalculateSalesTaxStatistics.

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] Service Credit Memo
        Initialize();

        CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo");
        BindSubscription(TestPartnerIntegrationNA);

        // [WHEN] Click the Statistics
        ServiceCreditMemo.Trap();
        ServiceCreditMemo.OpenView();
        ServiceCreditMemo.Statistics.Invoke();

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
        VerifyDataTypeBuffer(ServiceStatsTxt);
        VerifyDataTypeBuffer(SalesStatsValidateTxt);
    end;

    [Obsolete('Use events in OpenStatistics() procedure in table Service Header', '26.0')]
    [Test]
    [HandlerFunctions('ServiceStatsPageHandler')]
    [Scope('OnPrem')]
    procedure TestServiceCreditMemosOnBeforeCalculateSalesTaxStatistics()
    var
        ServiceHeader: Record "Service Header";
        TestPartnerIntegrationNA: Codeunit "Test Partner Integration NA";
        ServiceCreditMemos: TestPage "Service Credit Memos";
    begin
        // [SCENARIO] Calling the Statistics action on Service Credit Memos list will trigger OnBeforeCalculateSalesTaxStatistics.

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] Service Credit Memo
        Initialize();

        CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo");
        BindSubscription(TestPartnerIntegrationNA);

        // [WHEN] Click the Statistics
        ServiceCreditMemos.Trap();
        ServiceCreditMemos.OpenView();
        ServiceCreditMemos.Statistics.Invoke();

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
        VerifyDataTypeBuffer(ServiceStatsTxt);
        VerifyDataTypeBuffer(SalesStatsValidateTxt);
    end;

    [Obsolete('Use events in OpenStatistics() procedure in table Service Header', '26.0')]
    [Test]
    [HandlerFunctions('ServiceCreditMemoStatsPageHandler')]
    [Scope('OnPrem')]
    procedure TestPostedServiceCreditMemoOnBeforeCalculateSalesTaxStatistics()
    var
        ServiceHeader: Record "Service Header";
        TestPartnerIntegrationNA: Codeunit "Test Partner Integration NA";
        PostedServiceCreditMemo: TestPage "Posted Service Credit Memo";
    begin
        // [SCENARIO] Calling the Statistics action on Posted Service Credit Memo card page will trigger OnBeforeCalculateSalesTaxStatistics.

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] Posted Service Credit Memo
        Initialize();

        CreateServiceCreditMemo(ServiceHeader);
        BindSubscription(TestPartnerIntegrationNA);

        // [WHEN] Click the Statistics
        PostedServiceCreditMemo.Trap();
        PostedServiceCreditMemo.OpenView();
        PostedServiceCreditMemo.Statistics.Invoke();

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnAfterCalculateSalesTaxStatisticsTxt);
    end;

    [Obsolete('Use events in OpenStatistics() procedure in table Service Header', '26.0')]
    [Test]
    [HandlerFunctions('ServiceCreditMemoStatsPageHandler')]
    [Scope('OnPrem')]
    procedure TestPostedServiceCreditMemosOnBeforeCalculateSalesTaxStatistics()
    var
        ServiceHeader: Record "Service Header";
        TestPartnerIntegrationNA: Codeunit "Test Partner Integration NA";
        PostedServiceCreditMemos: TestPage "Posted Service Credit Memos";
    begin
        // [SCENARIO] Calling the Statistics action on Posted Service Credit Memos list page will trigger OnBeforeCalculateSalesTaxStatistics.

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetOutsideO365Scope();
        // [GIVEN] Posted Service Credit Memo
        Initialize();

        CreateServiceCreditMemo(ServiceHeader);
        BindSubscription(TestPartnerIntegrationNA);

        // [WHEN] Click the Statistics
        PostedServiceCreditMemos.Trap();
        PostedServiceCreditMemos.OpenView();
        PostedServiceCreditMemos.Statistics.Invoke();

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnAfterCalculateSalesTaxStatisticsTxt);
    end;
#endif
    [Test]
    [HandlerFunctions('ServiceOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestServiceOrderReport()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TestPartnerIntegrationNA: Codeunit "Test Partner Integration NA";
    begin
        // [SCENARIO] Calling Report Service Order will trigger OnAfterCalculateSalesTax.

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] Service Order
        Initialize();

        CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order);
        CreateServiceLine(ServiceLine, ServiceHeader);
        Commit();
        BindSubscription(TestPartnerIntegrationNA);

        // [WHEN] Report Sales Order is executed
        REPORT.Run(REPORT::"Service Order");

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnAfterCalculateSalesTaxStatisticsTxt);
    end;

    [Test]
    [HandlerFunctions('ServiceQuoteRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestServiceQuoteReport()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TestPartnerIntegrationNA: Codeunit "Test Partner Integration NA";
    begin
        // [SCENARIO] Calling Report Service Quote will trigger OnAfterCalculateSalesTax.

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] Service Header
        Initialize();
        CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote);
        CreateServiceLine(ServiceLine, ServiceHeader);
        Commit();

        BindSubscription(TestPartnerIntegrationNA);

        // [WHEN] Report Service Quote is executed
        REPORT.Run(REPORT::"Service Quote");

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnAfterCalculateSalesTaxStatisticsTxt);
    end;

    [Test]
    [HandlerFunctions('ServiceDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestServiceDocumentTestReport()
    var
        ServiceHeader: Record "Service Header";
        TestPartnerIntegrationNA: Codeunit "Test Partner Integration NA";
    begin
        // [SCENARIO] Calling Report Service Document Test will trigger OnAfterCalculateSalesTax.

        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] Service Header
        Initialize();
        CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order);
        Commit();

        BindSubscription(TestPartnerIntegrationNA);

        // [WHEN] Report Service Document Test is executed
        REPORT.Run(REPORT::"Service Document - Test");

        // [THEN] Integration Events have fired.
        VerifyDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [EventSubscriber(ObjectType::Page, Page::"Sales Quote", 'OnBeforeCalculateSalesTaxStatistics', '', false, false)]
    local procedure OnBeforeCalculateSalesTaxStatisticsSalesQuote(var SalesHeader: Record "Sales Header"; ShowDialog: Boolean)
    begin
        InsertDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [EventSubscriber(ObjectType::Page, Page::"Sales Quotes", 'OnBeforeCalculateSalesTaxStatistics', '', false, false)]
    local procedure OnBeforeCalculateSalesTaxStatisticsSalesQuotes(var SalesHeader: Record "Sales Header"; ShowDialog: Boolean)
    begin
        InsertDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [EventSubscriber(ObjectType::Page, Page::"Sales Order", 'OnBeforeCalculateSalesTaxStatistics', '', false, false)]
    local procedure OnBeforeCalculateSalesTaxStatisticsSalesOrder(var SalesHeader: Record "Sales Header"; ShowDialog: Boolean)
    begin
        InsertDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [EventSubscriber(ObjectType::Page, Page::"Sales Order Shipment", 'OnBeforeCalculateSalesTaxStatistics', '', false, false)]
    local procedure OnBeforeCalculateSalesTaxStatisticsSalesOrderShipment(var SalesHeader: Record "Sales Header"; ShowDialog: Boolean)
    begin
        InsertDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [EventSubscriber(ObjectType::Page, Page::"Sales Order List", 'OnBeforeCalculateSalesTaxStatistics', '', false, false)]
    local procedure OnBeforeCalculateSalesTaxStatisticsSalesOrders(var SalesHeader: Record "Sales Header"; ShowDialog: Boolean)
    begin
        InsertDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [EventSubscriber(ObjectType::Page, Page::"Blanket Sales Order", 'OnBeforeCalculateSalesTaxStatistics', '', false, false)]
    local procedure OnBeforeCalculateSalesTaxStatisticsBlanketSalesOrder(var SalesHeader: Record "Sales Header"; ShowDialog: Boolean)
    begin
        InsertDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [EventSubscriber(ObjectType::Page, Page::"Blanket Sales Orders", 'OnBeforeCalculateSalesTaxStatistics', '', false, false)]
    local procedure OnBeforeCalculateSalesTaxStatisticsBlanketSalesOrders(var SalesHeader: Record "Sales Header"; ShowDialog: Boolean)
    begin
        InsertDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [EventSubscriber(ObjectType::Page, Page::"Sales Order Invoice", 'OnBeforeCalculateSalesTaxStatistics', '', false, false)]
    local procedure OnBeforeCalculateSalesTaxStatisticsSalesOrderInvoice(var SalesHeader: Record "Sales Header"; ShowDialog: Boolean)
    begin
        InsertDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [EventSubscriber(ObjectType::Page, Page::"Sales Invoice", 'OnBeforeCalculateSalesTaxStatistics', '', false, false)]
    local procedure OnBeforeCalculateSalesTaxStatisticsSalesInvoice(var SalesHeader: Record "Sales Header"; ShowDialog: Boolean)
    begin
        InsertDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [EventSubscriber(ObjectType::Page, Page::"Sales Invoice List", 'OnBeforeCalculateSalesTaxStatistics', '', false, false)]
    local procedure OnBeforeCalculateSalesTaxStatisticsSalesInvoices(var SalesHeader: Record "Sales Header"; ShowDialog: Boolean)
    begin
        InsertDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [EventSubscriber(ObjectType::Page, Page::"Posted Sales Invoice", 'OnBeforeCalculateSalesTaxStatistics', '', false, false)]
    local procedure OnBeforeCalculateSalesTaxStatisticsPostedSalesInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        InsertDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [EventSubscriber(ObjectType::Page, Page::"Sales Credit Memo", 'OnBeforeCalculateSalesTaxStatistics', '', false, false)]
    local procedure OnBeforeCalculateSalesTaxStatisticsSalesCreditMemo(var SalesHeader: Record "Sales Header"; ShowDialog: Boolean)
    begin
        InsertDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [EventSubscriber(ObjectType::Page, Page::"Sales Return Order", 'OnBeforeCalculateSalesTaxStatistics', '', false, false)]
    local procedure OnBeforeCalculateSalesTaxStatisticsSalesReturnOrder(var SalesHeader: Record "Sales Header"; ShowDialog: Boolean)
    begin
        InsertDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [EventSubscriber(ObjectType::Page, Page::"Sales Return Order List", 'OnBeforeCalculateSalesTaxStatistics', '', false, false)]
    local procedure OnBeforeCalculateSalesTaxStatisticsSalesReturnOrders(var SalesHeader: Record "Sales Header"; ShowDialog: Boolean)
    begin
        InsertDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [EventSubscriber(ObjectType::Page, Page::"Posted Sales Credit Memo", 'OnBeforeCalculateSalesTaxStatistics', '', false, false)]
    local procedure OnBeforeCalculateSalesTaxStatisticsPostedSalesCreditMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        InsertDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [EventSubscriber(ObjectType::Page, Page::"Posted Sales Credit Memos", 'OnBeforeCalculateSalesTaxStatistics', '', false, false)]
    local procedure OnBeforeCalculateSalesTaxStatisticsPostedSalesCreditMemos(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        InsertDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
    end;
#endif

    [EventSubscriber(ObjectType::Page, Page::"Sales Credit Memo Stats.", 'OnAfterCalculateSalesTax', '', false, false)]
    local procedure OnAfterCalculateSalesTaxSalesCreditMemoStats(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; var SalesTaxAmountLine: Record "Sales Tax Amount Line"; var SalesTaxAmountLine2: Record "Sales Tax Amount Line"; var SalesTaxCalculationOverridden: Boolean)
    begin
        InsertDataTypeBuffer(OnAfterCalculateSalesTaxStatisticsTxt);
    end;

#if not CLEAN26
    [EventSubscriber(ObjectType::Page, Page::"Purchase Order", 'OnBeforeCalculateSalesTaxStatistics', '', false, false)]
    local procedure OnBeforeCalculateSalesTaxStatisticsPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ShowDialog: Boolean)
    begin
        InsertDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Purchase Order List", 'OnBeforeCalculateSalesTaxStatistics', '', false, false)]
    local procedure OnBeforeCalculateSalesTaxStatisticsPurchaseOrders(var PurchaseHeader: Record "Purchase Header"; ShowDialog: Boolean)
    begin
        InsertDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Purchase Invoice", 'OnBeforeCalculateSalesTaxStatistics', '', false, false)]
    local procedure OnBeforeCalculateSalesTaxStatisticsPurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; ShowDialog: Boolean)
    begin
        InsertDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Purchase Invoices", 'OnBeforeCalculateSalesTaxStatistics', '', false, false)]
    local procedure OnBeforeCalculateSalesTaxStatisticsPurchaseInvoices(var PurchaseHeader: Record "Purchase Header"; ShowDialog: Boolean)
    begin
        InsertDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
    end;
#endif

#if not CLEAN26
    [Obsolete('Use events in OpenStatistics() procedure in table Service Header', '26.0')]
    [EventSubscriber(ObjectType::Page, Page::"Service Quote", 'OnBeforeCalculateSalesTaxStatistics', '', false, false)]
    local procedure OnBeforeCalculateSalesTaxStatisticsServiceQuote(var ServiceHeader: Record "Service Header"; ShowDialog: Boolean)
    begin
        InsertDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
    end;

    [Obsolete('Use events in OpenStatistics() procedure in table Service Header', '26.0')]
    [EventSubscriber(ObjectType::Page, Page::"Service Quotes", 'OnBeforeCalculateSalesTaxStatistics', '', false, false)]
    local procedure OnBeforeCalculateSalesTaxStatisticsServiceQuotes(var ServiceHeader: Record "Service Header"; ShowDialog: Boolean)
    begin
        InsertDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
    end;

    [Obsolete('Use events in OpenStatistics() procedure in table Service Header', '26.0')]
    [EventSubscriber(ObjectType::Page, Page::"Service Order", 'OnBeforeCalculateSalesTaxStatistics', '', false, false)]
    local procedure OnBeforeCalculateSalesTaxStatisticsServiceOrder(var ServiceHeader: Record "Service Header"; ShowDialog: Boolean)
    begin
        InsertDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
    end;

    [Obsolete('Use events in OpenStatistics() procedure in table Service Header', '26.0')]
    [EventSubscriber(ObjectType::Page, Page::"Service Orders", 'OnBeforeCalculateSalesTaxStatistics', '', false, false)]
    local procedure OnBeforeCalculateSalesTaxStatisticsServiceOrders(var ServiceHeader: Record "Service Header"; ShowDialog: Boolean)
    begin
        InsertDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
    end;

    [Obsolete('Use events in OpenStatistics() procedure in table Service Header', '26.0')]
    [EventSubscriber(ObjectType::Page, Page::"Service Invoice", 'OnBeforeCalculateSalesTaxStatistics', '', false, false)]
    local procedure OnBeforeCalculateSalesTaxStatisticsServiceInvoice(var ServiceHeader: Record "Service Header"; ShowDialog: Boolean)
    begin
        InsertDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
    end;

    [Obsolete('Use events in OpenStatistics() procedure in table Service Header', '26.0')]
    [EventSubscriber(ObjectType::Page, Page::"Service Invoices", 'OnBeforeCalculateSalesTaxStatistics', '', false, false)]
    local procedure OnBeforeCalculateSalesTaxStatisticsServiceInvoices(var ServiceHeader: Record "Service Header"; ShowDialog: Boolean)
    begin
        InsertDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
    end;

    [Obsolete('Use events in OpenStatistics() procedure in table Service Header', '26.0')]
    [EventSubscriber(ObjectType::Page, Page::"Service Credit Memo", 'OnBeforeCalculateSalesTaxStatistics', '', false, false)]
    local procedure OnBeforeCalculateSalesTaxStatisticsServiceCreditMemo(var ServiceHeader: Record "Service Header"; ShowDialog: Boolean)
    begin
        InsertDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
    end;

    [Obsolete('Use events in OpenStatistics() procedure in table Service Header', '26.0')]
    [EventSubscriber(ObjectType::Page, Page::"Service Credit Memos", 'OnBeforeCalculateSalesTaxStatistics', '', false, false)]
    local procedure OnBeforeCalculateSalesTaxStatisticsServiceCreditMemos(var ServiceHeader: Record "Service Header"; ShowDialog: Boolean)
    begin
        InsertDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
    end;
#endif
    [EventSubscriber(ObjectType::Page, Page::"Service Invoice Stats.", 'OnAfterCalculateSalesTax', '', false, false)]
    local procedure OnAfterCalculateSalesTaxServiceInvoice(var ServiceInvoiceLine: Record "Service Invoice Line"; var SalesTaxAmountLine: Record "Sales Tax Amount Line"; var SalesTaxAmountLine2: Record "Sales Tax Amount Line"; var SalesTaxCalculationOverridden: Boolean)
    begin
        InsertDataTypeBuffer(OnAfterCalculateSalesTaxStatisticsTxt);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Sales Stats.", 'OnBeforeCalculateSalesTaxSalesStats', '', false, false)]
    local procedure OnBeforeCalculateSalesStats(var SalesHeader: Record "Sales Header"; var SalesTaxAmountLine: Record "Sales Tax Amount Line"; var SalesTaxAmountLine2: Record "Sales Tax Amount Line"; var SalesTaxCalculationOverridden: Boolean)
    begin
        InsertDataTypeBuffer(SalesStatsTxt);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Sales Order Stats.", 'OnBeforeCalculateSalesTaxSalesOrderStats', '', false, false)]
    local procedure OnBeforeCalculateSalesOrderStats(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var i: Integer; var SalesTaxAmountLine1: Record "Sales Tax Amount Line"; var SalesTaxAmountLine2: Record "Sales Tax Amount Line"; var SalesTaxAmountLine3: Record "Sales Tax Amount Line"; var SalesTaxAmountLine4: Record "Sales Tax Amount Line"; var SalesTaxCalculationOverridden: Boolean)
    begin
        InsertDataTypeBuffer(SalesStatsTxt);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Sales Invoice Stats.", 'OnAfterCalculateSalesTax', '', false, false)]
    local procedure OnAfterCalculateSalesInvoiceStats(var SalesInvoiceLine: Record "Sales Invoice Line"; var SalesTaxAmountLine: Record "Sales Tax Amount Line"; var SalesTaxAmountLine2: Record "Sales Tax Amount Line"; var SalesTaxCalculationOverridden: Boolean)
    begin
        InsertDataTypeBuffer(SalesStatsTxt);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Service Stats.", 'OnAfterCalculateSalesTax', '', false, false)]
    local procedure OnAfterCalculateServiceStats(var Handled: Boolean; var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var i: Integer; var TempSalesTaxAmountLine1: Record "Sales Tax Amount Line" temporary; var TempSalesTaxAmountLine2: Record "Sales Tax Amount Line" temporary; var TempSalesTaxAmountLine3: Record "Sales Tax Amount Line" temporary; var SalesTaxAmountLineParm: Record "Sales Tax Amount Line")
    begin
        InsertDataTypeBuffer(ServiceStatsTxt);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Service Order Stats.", 'OnAfterCalculateSalesTax', '', false, false)]
    local procedure OnAfterCalculateServiceOrderStats(var Handled: Boolean; var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var i: Integer; var TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary; var TempSalesTaxAmountLine2: Record "Sales Tax Amount Line" temporary; var TempSalesTaxAmountLine3: Record "Sales Tax Amount Line" temporary; var SalesTaxAmountLine: Record "Sales Tax Amount Line")
    begin
        InsertDataTypeBuffer(ServiceStatsTxt);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Service Credit Memo Stats.", 'OnAfterCalculateSalesTax', '', false, false)]
    local procedure OnAfterCalculateServiceCreditMemoStats(var ServiceCrMemoLine: Record "Service Cr.Memo Line"; var TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary; var TempSalesTaxAmountLine2: Record "Sales Tax Amount Line" temporary; var SalesTaxCalculationOverridden: Boolean)
    begin
        InsertDataTypeBuffer(OnAfterCalculateSalesTaxStatisticsTxt);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Service Stats.", 'OnAfterCalculateSalesTaxValidate', '', false, false)]
    local procedure OnBeforeCalculateSalesStatsValidate(var i: Integer)
    begin
        InsertDataTypeBuffer(SalesStatsValidateTxt);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Service Order Stats.", 'OnAfterCalculateSalesTaxValidate', '', false, false)]
    local procedure OnBeforeCalculateSalesOrderStatsValidate(var i: Integer)
    begin
        InsertDataTypeBuffer(SalesStatsValidateTxt);
    end;

    // replaces [EventSubscriber(ObjectType::Codeunit, Codeunit::"Serv-Amounts Mgt.", 'OnFillInvPostingBuffer', '', false, false)]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service Post Invoice Events", 'OnAfterPrepareInvoicePostingBuffer', '', false, false)]
    local procedure OnFillInvPostingBufferServAmtsMgt()
    begin
        InsertDataTypeBuffer(OnFillInvPostingBufferServAmtsMgtTxt);
    end;

#if not CLEAN28
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Serv-Documents Mgt.", 'OnBeforeCalculateSalesTax', '', false, false)]
    local procedure OnBeforeCalculateSalesTaxServDocumentsMgt(var SalesTaxCalculationOverridden: Boolean; var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary)
    begin
        InsertDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
        SalesTaxCalculationOverridden := true;
    end;
#endif

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Serv-Documents Mgt. NA", 'OnBeforeCalculateSalesTax', '', false, false)]
    local procedure OnBeforeCalculateSalesTaxServDocumentsMgtNA(var SalesTaxCalculationOverridden: Boolean; var ServiceHeader: Record "Service Header"; var TempServiceLine: Record "Service Line" temporary; var TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary)
    begin
        InsertDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
        SalesTaxCalculationOverridden := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post Prepayments", 'OnBeforeUpdateSalesTaxOnLines', '', false, false)]
    local procedure OnBeforeUpdateSalesTaxOnLines(var SalesLine: Record "Sales Line"; var ValidTaxAreaCode: Boolean)
    begin
        InsertDataTypeBuffer(OnBeforeUpdateSalesTaxOnLinesTxt);
    end;

    [EventSubscriber(ObjectType::Report, Report::"Sales Blanket Order", 'OnAfterCalculateSalesTax', '', false, false)]
    local procedure OnAfterCalculateSalesTaxSalesBlanketOrderReport(var SalesHeaderParm: Record "Sales Header"; var SalesLinePam: Record "Sales Line"; var TaxAmount: Decimal; var TaxLiable: Decimal)
    begin
        InsertDataTypeBuffer(OnAfterCalculateSalesTaxStatisticsTxt);
    end;

    [EventSubscriber(ObjectType::Report, Report::"Sales Order", 'OnAfterCalculateSalesTax', '', false, false)]
    local procedure OnAfterCalculateSalesTaxSalesOrderReport(var SalesHeaderParm: Record "Sales Header"; var SalesLineParm: Record "Sales Line"; var TaxAmount: Decimal; var TaxLiable: Decimal)
    begin
        InsertDataTypeBuffer(OnAfterCalculateSalesTaxStatisticsTxt);
    end;

    [EventSubscriber(ObjectType::Report, Report::"Sales Quote NA", 'OnAfterCalculateSalesTax', '', false, false)]
    local procedure OnAfterCalculateSalesTaxSalesQuoteReport(var SalesHeaderParm: Record "Sales Header"; var SalesLineParm: Record "Sales Line"; var TaxAmount: Decimal; var TaxLiable: Decimal)
    begin
        InsertDataTypeBuffer(OnAfterCalculateSalesTaxStatisticsTxt);
    end;

    [EventSubscriber(ObjectType::Report, Report::"Sales Document - Test", 'OnBeforeCalculateSalesTax', '', false, false)]
    local procedure OnAfterCalculateSalesTaxSalesDocumentTestReport(var SalesHeaderParm: Record "Sales Header"; var SalesTaxAmountLineParm: Record "Sales Tax Amount Line"; var SalesTaxCalculationOverridden: Boolean)
    begin
        InsertDataTypeBuffer(OnAfterCalculateSalesTaxStatisticsTxt);
    end;

#if not CLEAN28
    [EventSubscriber(ObjectType::Report, Report::"Service Quote", 'OnAfterCalculateSalesTax', '', false, false)]
    local procedure OnAfterCalculateSalesTaxServiceQuoteReport(var ServiceHeaderParm: Record "Service Header"; var ServiceLine: Record "Service Line"; var SalesTaxAmountLineParm: Record "Sales Tax Amount Line")
    begin
        InsertDataTypeBuffer(OnAfterCalculateSalesTaxStatisticsTxt);
    end;
#endif

    [EventSubscriber(ObjectType::Report, Report::"Service Quote-Sales Tax", 'OnAfterCalculateSalesTax', '', false, false)]
    local procedure OnAfterCalculateSalesTaxServiceQuoteSalesTaxReport(var ServiceHeaderParm: Record "Service Header"; var ServiceLine: Record "Service Line"; var SalesTaxAmountLineParm: Record "Sales Tax Amount Line")
    begin
        InsertDataTypeBuffer(OnAfterCalculateSalesTaxStatisticsTxt);
    end;

#if not CLEAN28
    [EventSubscriber(ObjectType::Report, Report::"Service Document - Test", 'OnBeforeCalculateSalesTax', '', false, false)]
    local procedure OnBeforeCalculateSalesTaxServiceDocumentTestReport(var ServiceHeader: Record "Service Header"; var SalesTaxAmountLine: Record "Sales Tax Amount Line"; var SalesTaxCalculationOverridden: Boolean)
    begin
        InsertDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
    end;
#endif

    [EventSubscriber(ObjectType::Report, Report::"Service Document - Test NA", 'OnBeforeCalculateSalesTax', '', false, false)]
    local procedure OnBeforeCalculateSalesTaxServiceDocumentTestNAReport(var ServiceHeader: Record "Service Header"; var SalesTaxAmountLine: Record "Sales Tax Amount Line"; var SalesTaxCalculationOverridden: Boolean)
    begin
        InsertDataTypeBuffer(OnBeforeCalculateSalesTaxStatisticsTxt);
    end;

#if not CLEAN28
    [EventSubscriber(ObjectType::Report, Report::"Service Order", 'OnAfterCalculateSalesTax', '', false, false)]
    local procedure OnAfterCalculateSalesTaxServiceOrderReport(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var SalesTaxAmountLine: Record "Sales Tax Amount Line")
    begin
        InsertDataTypeBuffer(OnAfterCalculateSalesTaxStatisticsTxt);
    end;
#endif

    [EventSubscriber(ObjectType::Report, Report::"Service Order-Sales Tax", 'OnAfterCalculateSalesTax', '', false, false)]
    local procedure OnAfterCalculateSalesTaxServiceOrderSalesTaxReport(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var SalesTaxAmountLine: Record "Sales Tax Amount Line")
    begin
        InsertDataTypeBuffer(OnAfterCalculateSalesTaxStatisticsTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostUpdateOrderLine', '', false, false)]
    local procedure OnBeforePostUpdateOrderLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        InsertDataTypeBuffer(OnBeforePostUpdateOrderLineTxt);
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    begin
        SalesHeader.DeleteAll();

        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, LibrarySales.CreateCustomerNo());
        SalesHeader."Tax Area Code" := 'X';  // Note this will force the NA specific pages to open.
        SalesHeader.Modify();
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header")
    begin
        SalesLine.DeleteAll();

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', 1);
        SalesLine."Tax Group Code" := 'X';
        SalesLine.Modify();
    end;
#if not CLEAN27
    local procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesHeader.DeleteAll();
        SalesInvoiceHeader.DeleteAll();

        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesHeader."Tax Area Code" := 'X';  // Note this will force the NA specific pages to open.
        SalesHeader.Modify();
        Commit();

        CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);
    end;
#endif
    local procedure PostSalesOrder(var SalesHeader: Record "Sales Header")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        SalesHeader.DeleteAll();
        SalesInvoiceHeader.DeleteAll();

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Invoice := true;
        SalesHeader.Modify();
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDecInRange(1, 100, 2), LibraryRandom.RandDecInRange(1, 100, 2));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(100));
        SalesLine."Qty. to Invoice" := SalesLine.Quantity;
        SalesLine."Qty. Shipped Not Invoiced" := SalesLine.Quantity;
        SalesLine.Modify();
        Commit();

        CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);
    end;
#if not CLEAN27
    local procedure CreateSalesCreditMemo(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        Item: Record Item;
    begin
        SalesHeader.DeleteAll();
        SalesCrMemoHeader.DeleteAll();

        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDecInRange(1, 100, 2), LibraryRandom.RandDecInRange(1, 100, 2));
        Item."Tax Group Code" := 'X';
        Item.Modify();

        CreateSalesLine(SalesLine, SalesHeader);

        CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);
    end;
#endif
#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseHeader.DeleteAll();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, LibraryPurchase.CreateVendorNo());
        PurchaseHeader."Tax Area Code" := 'X'; // Note this will force the NA specific pages to open.
        PurchaseHeader.Modify();

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', 1);
        PurchaseLine."Tax Group Code" := 'X';
        PurchaseLine.Modify();
    end;
#endif

    local procedure CreateServiceHeader(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type")
    begin
        ServiceHeader.DeleteAll();
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, '');
        ServiceHeader."Tax Area Code" := 'X';  // Note this will force the NA specific pages to open.
        ServiceHeader.Modify();
    end;

    local procedure CreateServiceLine(var ServiceLine: Record "Service Line"; var ServiceHeader: Record "Service Header")
    begin
        ServiceLine.DeleteAll();

        LibraryService.CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, ServiceLine.Type::Item, '', 1);
        ServiceLine."Tax Group Code" := 'X';
        ServiceLine.Modify();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    local procedure CreateServiceInvoice(var ServiceHeader: Record "Service Header")
    var
        ServiceItem: Record "Service Item";
        ServiceLine: Record "Service Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceHeader.DeleteAll();
        ServiceInvoiceHeader.DeleteAll();

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, '');
        ServiceHeader."Tax Area Code" := 'X';  // Note this will force the NA specific pages to open.
        ServiceHeader.Modify();

        LibraryService.CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ServiceItem."No.", 1);
        ServiceLine."Tax Group Code" := 'X';
        ServiceLine.Modify();

        CODEUNIT.Run(CODEUNIT::"Service-Post", ServiceHeader);
    end;
#endif

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    local procedure CreateServiceCreditMemo(var ServiceHeader: Record "Service Header")
    var
        ServiceItem: Record "Service Item";
        ServiceLine: Record "Service Line";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
    begin
        ServiceHeader.DeleteAll();
        ServiceCrMemoHeader.DeleteAll();
        ServiceCrMemoLine.DeleteAll();
        CustLedgerEntry.DeleteAll();

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", '');
        ServiceHeader."Tax Area Code" := 'X';  // Note this will force the NA specific pages to open.
        ServiceHeader."Posting No." := 'X';
        ServiceHeader.Modify();

        LibraryService.CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ServiceItem."No.", 1);

        CODEUNIT.Run(CODEUNIT::"Service-Post", ServiceHeader);
    end;
#endif

    [Scope('OnPrem')]
    procedure VerifyDataTypeBuffer(VerifyText: Text)
    var
        DataTypeBufferNA: Record "Data Type Buffer NA";
    begin
        DataTypeBufferNA.SetRange(Text, VerifyText);
        Assert.IsFalse(DataTypeBufferNA.IsEmpty, 'The event was not executed');
    end;

    [Scope('OnPrem')]
    procedure InsertDataTypeBuffer(EventText: Text)
    var
        DataTypeBufferNA: Record "Data Type Buffer NA";
    begin
        if DataTypeBufferNA.FindLast() then;

        DataTypeBufferNA.Init();
        DataTypeBufferNA.ID += 1;
        DataTypeBufferNA.Text := CopyStr(EventText, 1, 30);
        DataTypeBufferNA.Insert(true);
        Commit();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesStatsModalPageHandler(var SalesStatistics: TestPage "Sales Stats.")
    begin
        SalesStatistics.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatsPageHandler(var SalesOrderStats: TestPage "Sales Order Stats.")
    begin
        SalesOrderStats.OK().Invoke();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatsPageHandler(var PurchaseOrderStats: TestPage "Purchase Order Stats.")
    begin
        PurchaseOrderStats.OK().Invoke();
    end;
#endif

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchOrderStatsPageHandler(var PurchaseOrderStats: TestPage "Purchase Order Stats.")
    begin
        PurchaseOrderStats.OK().Invoke();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceStatsPageHandler(var PurchaseStats: TestPage "Purchase Stats.")
    begin
        PurchaseStats.OK().Invoke();
    end;
#endif

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceStatsPageHandler(var SalesInvoiceStats: TestPage "Sales Invoice Stats.")
    begin
        SalesInvoiceStats.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesCreditMemoStatsPageHandler(var SalesCreditMemoStats: TestPage "Sales Credit Memo Stats.")
    begin
        SalesCreditMemoStats.OK().Invoke();
    end;

#if not CLEAN26
    [Obsolete('Use events in OpenStatistics() procedure in table Service Header', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceStatsPageHandler(var ServiceStats: TestPage "Service Stats.")
    begin
        ServiceStats.OK().Invoke();
    end;

    [Obsolete('Use events in OpenStatistics() procedure in table Service Header', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceOrderStatsPageHandler(var ServiceOrderStats: TestPage "Service Order Stats.")
    begin
        ServiceOrderStats.OK().Invoke();
    end;

    [Obsolete('Use events in OpenStatistics() procedure in table Service Header', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceInvoiceStatsPageHandler(var ServiceInvoiceStats: TestPage "Service Invoice Stats.")
    begin
        ServiceInvoiceStats.OK().Invoke();
    end;

    [Obsolete('Use events in OpenStatistics() procedure in table Service Header', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoStatsPageHandler(var ServiceCreditMemoStats: TestPage "Service Credit Memo Stats.")
    begin
        ServiceCreditMemoStats.OK().Invoke();
    end;
#endif
    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesBlanketOrderRequestPageHandler(var SalesBlanketOrder: TestRequestPage "Sales Blanket Order")
    begin
        SalesBlanketOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesQuoteRequestPageHandler(var SalesQuote: TestRequestPage "Sales Quote NA")
    begin
        SalesQuote.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderRequestPageHandler(var SalesOrder: TestRequestPage "Sales Order")
    begin
        SalesOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesDocumentTestRequestPageHandler(var SalesDocumentTest: TestRequestPage "Sales Document - Test")
    begin
        SalesDocumentTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceQuoteRequestPageHandler(var ServiceQuote: TestRequestPage "Service Quote")
    begin
        ServiceQuote.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceDocumentTestRequestPageHandler(var ServiceDocumentTest: TestRequestPage "Service Document - Test")
    begin
        ServiceDocumentTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceOrderRequestPageHandler(var ServiceOrder: TestRequestPage "Service Order")
    begin
        ServiceOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}
