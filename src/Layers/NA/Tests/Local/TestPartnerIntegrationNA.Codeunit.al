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

    [EventSubscriber(ObjectType::Page, Page::"Sales Credit Memo Stats.", 'OnAfterCalculateSalesTax', '', false, false)]
    local procedure OnAfterCalculateSalesTaxSalesCreditMemoStats(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; var SalesTaxAmountLine: Record "Sales Tax Amount Line"; var SalesTaxAmountLine2: Record "Sales Tax Amount Line"; var SalesTaxCalculationOverridden: Boolean)
    begin
        InsertDataTypeBuffer(OnAfterCalculateSalesTaxStatisticsTxt);
    end;

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

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchOrderStatsPageHandler(var PurchaseOrderStats: TestPage "Purchase Order Stats.")
    begin
        PurchaseOrderStats.OK().Invoke();
    end;

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
