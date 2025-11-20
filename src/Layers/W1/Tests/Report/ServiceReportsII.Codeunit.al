codeunit 136905 "Service Reports - II"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Reports] [Service]
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        AmountMustMatchError: Label '%1 must match with report.';
        ExistError: Label '%1 must exist.';
        ItemNo: Code[20];
        SetHandler: Boolean;
        ValidationError: Label '%1 must be %2 in Report.';
        TableName: Label 'DocEntryTableName';
        NoOfRecords: Label 'DocEntryNoofRecords';
        ExpectedConfirm: Label 'The Credit Memo doesn''t have a Corrected Invoice No. Do you want to continue?';
        CustNoCaption: Label 'CustNo_CustLedgEntry';
        AmtCaption: Label 'Amount_CustLedgEntry';
        AmtLCYCaption: Label 'AmtLCY_CustLedgEntry';
        CrMemoLineNoXMLCap: Label 'LineNo_ServCrMemoLine';
        DescrServCrMemoLineXMLCap: Label 'Desc_ServCrMemoLine';
        PostingDateCaptionXMLCap: Label 'PostedRcptDate';
        CrMemoLineVATIdXMLCap: Label 'VATIdentifier_ServCrMemoLine';
        QtyCrMemoLineCap: Label 'Quantity_ServCrMemoLine';
        UnitPriceCrMemoLineCap: Label 'UnitPrice_ServCrMemoLine';
        CrMemoLineDiscCaptionXMLCap: Label 'LineDisc_ServCrMemoLine';
        AmtCaptionCrMemoLineCap: Label 'Amt_ServCrMemoLine';
        ServiceItemGroupCap: Label 'ServItemGroupCode_ServItemLine', Locked = true;
        ServiceShipItemLineNoCap: Label 'LnNo_ServiceShptItemLn', Locked = true;
        ServiceShipHeaderNoCap: Label 'No_ServiceShptHrd', Locked = true;
        FilterNotFoundinXMLErr: Label 'Field: %1 Value:%2 not found in xml', Locked = true;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Reports - II");
        LibraryVariableStorage.Clear();
        Clear(LibraryReportDataset);
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Reports - II");

        LibrarySales.SetInvoiceRounding(false);
        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateAccountInCustomerPostingGroup();

        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Reports - II");
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,MessageHandler,ServiceContractTemplateHandler,ContractInvoicingReportHandler')]
    [Scope('OnPrem')]
    procedure CreateContractInvoiceReport()
    var
        ServiceContractHeader: Record "Service Contract Header";
        CurrentWorkDate: Date;
    begin
        // Test that program generates the entry after execute the Create Contract Invoices report
        // when the Service Contracts is signed on before the Work Date.

        // 1. Setup: Create and Sign Service Contract.
        Initialize();
        CreateServiceContract(ServiceContractHeader);
        ModifyServiceContractHeader(ServiceContractHeader);
        LibraryService.SignContract(ServiceContractHeader);
        Commit();

        // 2. Exercise: Run Create Contract Invoices Report.
        CurrentWorkDate := WorkDate();
        WorkDate := CalcDate(ServiceContractHeader."Service Period", WorkDate());
        RunCreateContractInvoices(ServiceContractHeader);

        // 3. Verify: Verify Entry with Customer No..
        LibraryReportDataset.LoadDataSetFile();

        LibraryReportDataset.SetRange('ContractNo1_ServContract', ServiceContractHeader."Contract No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), ServiceContractHeader.FieldCaption("Contract No."));
        LibraryReportDataset.AssertCurrentRowValueEquals('CustNo_ServContract', ServiceContractHeader."Customer No.");

        // 4. Cleanup: Cleanup the WorkDate.
        WorkDate := CurrentWorkDate;
    end;

    [Test]
    [HandlerFunctions('ServiceOrderWithQuantityHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderWithQuantity()
    var
        Item: Record Item;
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
    begin
        // Test that value of Quantity,Unit Price and Amount in Service Order matches the value Quantity,Unit Price and Amount In corresponding Service Line Table.

        // 1. Setup: Create a Service Order - Service Header, Service Item Line, Service Line and Calculate Amount.
        Initialize();
        CreateItem(Item);
        LibraryService.CreateServiceItem(ServiceItem, '');
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        CreateServiceLineWithItem(ServiceLine, ServiceHeader, ServiceItem."No.", Item."No.");

        // 2. Exercise: Generate Service Order Report.
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceHeader.SetRange("No.", ServiceHeader."No.");
        Commit();
        REPORT.Run(REPORT::"Service Order", true, true, ServiceHeader);

        // 3. Verify: Test that value of Quantity,Unit Price and Amount in Service Order matches the value Quantity,Unit Price and Amount In corresponding Service Line Table.
        VerifyServiceOrderWithQuantity(ServiceLine);
    end;

    [Test]
    [HandlerFunctions('ServiceOrderWithQuantityHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderInvoicedQuantity()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ShowQuantity: Option Quantity,"Quantity Invoiced";
    begin
        // Test that value of Serial No in Service Order matches the value Serial No in corresponding Service Item Line Table.

        // 1. Setup: Create a Service Order - Service Header, Service Item Line.
        Initialize();
        ServiceItemWithSerialAndGroup(ServiceItem, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // 2. Exercise: Generate Service Order Report.
        RunServiceOrderReport(ServiceHeader, false, ShowQuantity::"Quantity Invoiced");

        // 3. Verify: that value of Serial No in Service Order matches the value Serial No in corresponding Service Item Line Table.

        LibraryReportDataset.LoadDataSetFile();

        LibraryReportDataset.SetRange(ServiceItemGroupCap, ServiceItem."Service Item Group Code");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(),
          StrSubstNo(FilterNotFoundinXMLErr,
            ServiceItem.FieldCaption("Service Item Group Code"),
            ServiceItem."Service Item Group Code"));

        LibraryReportDataset.AssertCurrentRowValueEquals('SerialNo_ServItemLine', ServiceItem."Serial No.");
    end;

    [Test]
    [HandlerFunctions('ServiceOrderWithQuantityHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderWithComments()
    var
        Item: Record Item;
        ServiceCommentLineFault: Record "Service Comment Line";
        ServiceCommentLineResolution: Record "Service Comment Line";
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
        ShowQuantity: Option Quantity,"Quantity Invoiced";
    begin
        // Test that the Service Item Line Comments is generated in Report.

        // 1. Setup: Create a Service Order - Service Header, Service Item Line, Service Line and Comments.
        Initialize();
        CreateItem(Item);
        LibraryService.CreateServiceItem(ServiceItem, '');
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        CreateServiceLineWithItem(ServiceLine, ServiceHeader, ServiceItem."No.", Item."No.");
        LibraryService.CreateCommentLineForServHeader(
          ServiceCommentLineFault,
          ServiceItemLine,
          ServiceCommentLineFault.Type::Fault);
        LibraryService.CreateCommentLineForServHeader(
          ServiceCommentLineResolution,
          ServiceItemLine,
          ServiceCommentLineResolution.Type::Resolution);

        // 2. Exercise: Generate Service Order Report.
        RunServiceOrderReport(ServiceHeader, false, ShowQuantity::Quantity);

        // 3. Verify: Check that the Service Item Line Comments is generated in Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Comment_ResolutionComment', ServiceCommentLineResolution.Comment);
        Assert.IsTrue(LibraryReportDataset.GetNextRow(),
          StrSubstNo(FilterNotFoundinXMLErr,
            ServiceCommentLineResolution.FieldCaption(Comment),
            ServiceCommentLineResolution.Comment));

        LibraryReportDataset.AssertCurrentRowValueEquals(ServiceItemGroupCap, ServiceItem."Service Item Group Code");
        LibraryReportDataset.SetRange('Comment_FaultComment', ServiceCommentLineFault.Comment);
        Assert.IsTrue(LibraryReportDataset.GetNextRow(),
          StrSubstNo(FilterNotFoundinXMLErr,
            ServiceCommentLineFault.FieldCaption(Comment),
            ServiceCommentLineFault.Comment));
        LibraryReportDataset.AssertCurrentRowValueEquals(ServiceItemGroupCap, ServiceItem."Service Item Group Code");
    end;

    [Test]
    [HandlerFunctions('ServiceOrderWithQuantityHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderWithDimension()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        DimensionSetEntry: Record "Dimension Set Entry";
        ShowQuantity: Option Quantity,"Quantity Invoiced";
    begin
        // Test that the Service Header Dimension is generated in Report.

        // 1. Setup: Create Customer, Service Order - Service Header with Dimension, Service Item Line.
        Initialize();
        LibraryService.CreateServiceItem(ServiceItem, CreateCustomer(''));
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        CreateDimensionForHeader(ServiceHeader);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, ServiceHeader."Dimension Set ID");

        // 2. Exercise: Generate Service Order Report.
        RunServiceOrderReport(ServiceHeader, true, ShowQuantity::Quantity);

        // 3. Verify: Check that the Service Header Dimension is generated in Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_ServHeader', ServiceHeader."No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(),
          StrSubstNo(FilterNotFoundinXMLErr,
            ServiceHeader.FieldCaption("No."),
            ServiceHeader."No."));
        LibraryReportDataset.AssertCurrentRowValueEquals('DimText',
          StrSubstNo('%1 %2', DimensionSetEntry."Dimension Code",
            DimensionSetEntry."Dimension Value Code"));
    end;

    [Test]
    [HandlerFunctions('ServiceProfitOrdersHandler')]
    [Scope('OnPrem')]
    procedure ServiceProfitOrders()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        // [FEATURE] [UI] [Report Service Profit Serv. Orders]
        // [SCENARIO] Verify Service Profit Service Order Report data correctness for Show Detail = FALSE.

        // [GIVEN] Shipped and Invoiced Service Order.
        Initialize();
        CreateServiceOrder(ServiceLine, '', 0D, 0D);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [WHEN] Run report "Service Profit Service Order" with Show Detail FALSE.
        SaveServiceProfitServiceOrders(false, ServiceHeader."No.");

        // [THEN] Report data is correct.
        LibraryReportDataset.LoadDataSetFile();
        FindServiceLedgerEntry(ServiceLedgerEntry, ServiceHeader."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('OrderNoDesc_ServShptHeader', ServiceHeader."No." + ' ');
        VerifyServiceProfitOrderReport(ServiceLedgerEntry);
    end;

    [Test]
    [HandlerFunctions('ServiceProfitOrdersShowDetailHandler')]
    [Scope('OnPrem')]
    procedure ServiceProfitOrdersShowDetail()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        // [FEATURE] [UI] [Report Service Profit Serv. Orders]
        // [SCENARIO] Verify Service Profit Service Order Report data correctness for Show Detail = TRUE.

        // [GIVEN] Shipped and Invoiced Service Order.
        Initialize();
        CreateServiceOrder(ServiceLine, '', 0D, 0D);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [WHEN] Run report "Service Profit Service Order" with Show Detail TRUE.
        SaveServiceProfitServiceOrders(true, ServiceHeader."No.");

        // [THEN] Report data is correct.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();
        FindServiceLedgerEntry(ServiceLedgerEntry, ServiceHeader."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('EntryNo_ServLedgEntryNo', ServiceLedgerEntry."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Quantity', ServiceLedgerEntry.Quantity);
        VerifyServiceProfitOrderReport(ServiceLedgerEntry);
    end;

    [Test]
    [HandlerFunctions('ServiceProfitOrdersShowDetailHandler')]
    [Scope('OnPrem')]
    procedure ServiceProfitOrdersShowDetailMultiLines()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [UI] [Report Service Profit Serv. Orders]
        // [SCENARIO] Check Service Profit Service Order Report with Show Detail Option True.

        // [GIVEN] Shipped and Invoiced Service Order having multiple lines.
        Initialize();
        CreateServiceOrderMultiLines(ServiceLine);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // [WHEN] Run report "Service Profit Service Order" with Show Detail TRUE.
        SaveServiceProfitServiceOrders(true, ServiceHeader."No.");

        // [THEN] Report values are correct.
        VerifyServiceProfitOrderReportMultiLines(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('InvoiceESConfirmHandler,ServiceCreditMemoReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceCreditMemo()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [UI] [Report Service - Credit Memo]
        // [SCENARIO] Check Service Credit Memo Report with Show Detail option FALSE.

        // [GIVEN] Posted Service Credit Memo.
        Initialize();
        CreateItem(Item);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", '');
        CreateServiceLineWithItem(ServiceLine, ServiceHeader, '', Item."No.");
        ExecuteConfirmHandlerInvoiceES();
        LibraryService.PostServiceOrder(ServiceHeader, false, false, false);

        // [WHEN] Run report "Service Credit Memo Report" with Show Detail FALSE.
        SaveServiceCreditMemo(false, ServiceHeader."No.");

        // [THEN] Values on the report are correct.
        LibraryReportDataset.LoadDataSetFile();
        VerifyServiceCreditMemoReport(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('InvoiceESConfirmHandler,ServiceCreditMemoReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoShowDetail()
    var
        Item: Record Item;
        DimensionSetEntry: Record "Dimension Set Entry";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [UI] [Report Service - Credit Memo]
        // [SCENARIO] Check dimension entry on Service Credit Memo Report with Show Detail option TRUE.

        // [GIVEN] Posted Service Credit Memo with dimension values.
        Initialize();
        CreateItem(Item);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", CreateCustomer(''));
        CreateDimensionForHeader(ServiceHeader);
        CreateServiceLineWithItem(ServiceLine, ServiceHeader, '', Item."No.");
        ExecuteConfirmHandlerInvoiceES();
        LibraryService.PostServiceOrder(ServiceHeader, false, false, false);
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, ServiceHeader."Dimension Set ID");

        // [WHEN] Run report "Save Service Credit Memo" with Show Detail TRUE.
        SaveServiceCreditMemo(true, ServiceHeader."No.");

        // [THEN] Dimension Entry on Report is correct.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('DimText',
          StrSubstNo('%1 - %2', DimensionSetEntry."Dimension Code",
            DimensionSetEntry."Dimension Value Code"));

        Assert.IsTrue(LibraryReportDataset.GetNextRow(),
          StrSubstNo(FilterNotFoundinXMLErr,
            DimensionSetEntry.FieldCaption("Dimension Code"),
            DimensionSetEntry."Dimension Code"));
    end;

    [Test]
    [HandlerFunctions('ServiceShipmentReportlHandler')]
    [Scope('OnPrem')]
    procedure ServiceShipment()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [UI] [Report Service - Shipment]
        // [SCENARIO] Check Service Shipment Report with Default Options.

        // [GIVEN] Posted Service Order.
        Initialize();
        CreateItem(Item);
        LibraryService.CreateServiceItem(ServiceItem, '');
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        CreateServiceLineWithItem(ServiceLine, ServiceHeader, ServiceItem."No.", Item."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [WHEN] Run report "Service Shipment" with Default Options.
        SaveServiceShipment(false, false, false, ServiceHeader."No.");

        // [THEN] Values on Service Shipment Report are correct.
        VerifyServiceShipmentReport(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ServiceShipmentReportlHandler')]
    [Scope('OnPrem')]
    procedure ServiceShipmentInternalInfo()
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // [FEATURE] [UI] [Report Service - Shipment]
        // [SCENARIO] Check Service Shipment Report with Show Internal Information TRUE.

        // [GIVEN] Posted Service Order with dimension values.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CreateCustomer(''));
        CreateDimensionForHeader(ServiceHeader);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        CreateServiceLine(ServiceHeader, Item."No.", ServiceItemLine."Line No.", LibraryRandom.RandDec(10, 2));
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, ServiceHeader."Dimension Set ID");

        // [WHEN] Run report "Service Shipment" with Show Internal Information TRUE.
        SaveServiceShipment(true, false, false, ServiceHeader."No.");

        // [THEN] Dimension Values on Service Shipment Report are correct.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange(ServiceShipHeaderNoCap, FindServiceShipmentHeader(ServiceHeader."No."));
        Assert.IsTrue(LibraryReportDataset.GetNextRow(),
          StrSubstNo(FilterNotFoundinXMLErr,
            ServiceHeader.FieldCaption("No."),
            ServiceHeader."No."));

        LibraryReportDataset.AssertCurrentRowValueEquals('DimText',
          StrSubstNo('%1 - %2', DimensionSetEntry."Dimension Code",
            DimensionSetEntry."Dimension Value Code"));
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServiceShipmentReportlHandler')]
    [Scope('OnPrem')]
    procedure ServiceShipmentUndoShipment()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        // [FEATURE] [UI] [Report Service - Shipment]
        // [SCENARIO] Check Service Shipment Report after Doing Undo Shipment for Posted Shipment.

        // [GIVEN] Shipped Service Order, then Undo Shipment.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        CreateServiceLine(ServiceHeader, Item."No.", ServiceItemLine."Line No.", LibraryRandom.RandDec(10, 2));
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        UndoShipment(ServiceHeader."No.");

        // [WHEN] Run report "Service Shipment" with Show Correction Line TRUE.
        SaveServiceShipment(false, true, false, ServiceHeader."No.");

        // [THEN] Undone Quantity Invoiced on Report is correct.
        VerifyServiceShipmentReport(ServiceHeader."No.");

        ServiceShipmentLine.SetRange("Document No.", FindServiceShipmentHeader(ServiceHeader."No."));
        ServiceShipmentLine.FindLast();

        LibraryReportDataset.SetRange('QtyInvoiced_ServShptLine', -ServiceShipmentLine."Quantity Invoiced");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(),
          StrSubstNo(FilterNotFoundinXMLErr,
            ServiceShipmentLine.FieldCaption("Quantity Invoiced"),
            -ServiceShipmentLine."Quantity Invoiced"));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,SignContractConfirmHandler,ServiceLinesPageHandler,ItemTrackingSummaryPageHandler,MessageHandler,ServiceShipmentReportlHandler')]
    [Scope('OnPrem')]
    procedure ServiceShipmentShowSN()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemJournalLine: Record "Item Journal Line";
        ServiceItemLine: Record "Service Item Line";
        ServiceHeader: Record "Service Header";
        ItemJournal: TestPage "Item Journal";
    begin
        // [FEATURE] [UI] [Report Service - Shipment]
        // [SCENARIO] Check Service Shipment Report With option Show Lot/SN Appendix TRUE.

        // [GIVEN] Posted Service Order with Item having Item Tracking with Serial Nos.
        Initialize();
        Clear(ItemNo);
        CreateItemJournalLine(ItemJournalLine, CreateItemWithItemTrackingCode());
        ItemNo := ItemJournalLine."Item No.";  // Storing Item No. in Global Variable to use it in Page Handler.
        ItemJournal.OpenEdit();
        ItemJournal.CurrentJnlBatchName.SetValue(ItemJournalLine."Journal Batch Name");
        SetHandler := true;  // Setting Handler's value as TRUE to execute Assign Serial No. Action on Item Tracking Lines Page.
        ItemJournal.ItemTrackingLines.Invoke();
        ItemJournal.Post.Invoke();
        Commit();
        LibraryUtility.GenerateGUID();  // Hack to fix New General Batch Creation issue with Generate GUID.

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CreateCustomer(''));
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        CreateServiceLine(ServiceHeader, ItemNo, ServiceItemLine."Line No.", ItemJournalLine.Quantity);
        SetHandler := false;  // Setting Handler's value as FALSE to execute Select Entries Action on Item Tracking Lines Page.
        OpenServiceOrderPage(ServiceHeader);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [WHEN] Run report "Service Shipment" with Show Lot/Serial No. Appendix as TRUE.
        SaveServiceShipment(false, false, true, ServiceHeader."No.");

        // [THEN] Serial No. on Service Shipment Report is correct.
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.FindFirst();

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('TrackingSpecBufSerialNo', ItemLedgerEntry."Serial No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(),
          StrSubstNo(ExistError, ItemLedgerEntry."Serial No."));
    end;

    [Test]
    [HandlerFunctions('ServiceProfitItemsHandler')]
    [Scope('OnPrem')]
    procedure ServiceProfitItems()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [UI] [Report Service Profit Service Items]
        // [SCENARIO] Check Service Profit Service Items Report with Show Detail Option FALSE.

        // [GIVEN] Posted Service Order.
        Initialize();
        CreateServiceOrder(ServiceLine, '', 0D, 0D);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [WHEN] Run report "Service Profit Service Items" with Show Detail Option FALSE.
        SaveServiceProfitServiceItems(false, ServiceLine."Service Item No.");

        // [THEN] Verify Different Values on Saved Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();
        VerifyServiceProfitItemsReport(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ServiceProfitItemsShowDetailHandler')]
    [Scope('OnPrem')]
    procedure ServiceProfitItemsShowDetail()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [UI] [Report Service Profit Service Items]
        // [SCENARIO] Check Service Profit Service Items Report with Show Details Option TRUE.

        // [GIVEN] Posted Service Order.
        Initialize();
        CreateServiceOrder(ServiceLine, '', 0D, 0D);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [WHEN] Run report "Service Profit Service Items" with Show Detail Option TRUE.
        SaveServiceProfitServiceItems(true, ServiceLine."Service Item No.");

        // [THEN] Verify values on the Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_ServItem', ServiceLine."Service Item No.");
        LibraryReportDataset.GetNextRow();
        VerifyServiceProfitItemsReport(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,ServicePricingProfitabilityReportlHandler')]
    [Scope('OnPrem')]
    procedure ServicePricingProfitability()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceLine: Record "Service Line";
        ServicePriceGroup: Record "Service Price Group";
        ServPricingProfitability: Report "Serv. Pricing Profitability";
    begin
        // [FEATURE] [UI] [Report Serv. Pricing Profitability]
        // [SCENARIO] Check Service Pricing Profitability Report.

        // [GIVEN] Posted Service Order having service price group in item line.
        Initialize();
        CreateItem(Item);
        LibraryService.CreateServicePriceGroup(ServicePriceGroup);
        CreateServicePriceGroupSetup(ServicePriceGroup.Code);
        LibraryService.CreateServiceItem(ServiceItem, CreateCustomer(''));
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        CreateItemLineWithPriceGroup(ServiceHeader, ServiceItem."No.", ServicePriceGroup.Code);
        CreateServiceLineWithItem(ServiceLine, ServiceHeader, ServiceItem."No.", Item."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [WHEN] Run report "Service Pricing Profitability".
        Clear(ServPricingProfitability);
        ServicePriceGroup.SetRange(Code, ServicePriceGroup.Code);
        ServPricingProfitability.SetTableView(ServicePriceGroup);
        Commit();
        ServPricingProfitability.Run();

        // [THEN] Values in the Report are correct.
        VerifyServicePricingReport(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('NavigatePageHandler,DocumentEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DocumentEntriesForServiceShipment()
    begin
        // [FEATURE] [UI] [Page Navigate]
        // [SCENARIO] Verify that number of entries are correct in report "Navigate" for shipped service order

        // [GIVEN] Shipped Service Order.
        // [WHEN] "Navigate" invoked.
        // [THEN] Number of document entries/item ledger entries/service ledger entries/value entries are correct.
        NavigateForServiceShipment(0D, 0D);
    end;

    [Test]
    [HandlerFunctions('NavigatePageHandler,DocumentEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DocumentEntriesForServiceShipmentWithWarrantyEntry()
    var
        WarrantyLedgerEntry: Record "Warranty Ledger Entry";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [UI] [Page Navigate]
        // [SCENARIO] Verify that number of warranty ledger entries are correct in report "Navigate" for shipped service order

        // [GIVEN] Shipped Service Order.
        // [WHEN] "Navigate" invoked.
        DocumentNo := NavigateForServiceShipment(WorkDate(), CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));

        // [THEN] Number of warranty ledger entries are correct.
        WarrantyLedgerEntry.SetRange("Document No.", DocumentNo);
        VerifyDocumentEntriesReport(WarrantyLedgerEntry.TableCaption(), WarrantyLedgerEntry.Count);
    end;

    [Test]
    [HandlerFunctions('StandardSalesProFormaInvRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyTaxAmountOnStandardSalesProFormaInv()
    var
        SalesHeader: Record "Sales Header";
        TaxArea: Record "Tax Area";
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        Item: Record Item;
        GeneralLedgerSetup: Record "General Ledger Setup";
        DocumentPrint: Codeunit "Document-Print";
        AutoFormat: Codeunit "Auto Format";
        AutoFormatType: Enum "Auto Format";
    begin
        // [SCENARIO 449267]Verify the Tax Amount on the Pro Forma Invoice should match the Tax Amount from the Sales Header
        Initialize();

        // [GIVEN] Create Tax Area with Lines
        GeneralLedgerSetup.Get();
        CreateTaxAreaWithTaxAreaLine(TaxArea);

        // [GIVEN] Create Sales Header, Sales Line
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesLine."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Tax Liable", true);
        SalesHeader.Validate("Tax Area Code", TaxArea.Code);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));  // Using Random value for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));  // Using Random value for Unit Price.
        SalesLine.Modify(true);

        // [WHEN] Run the report 1302 "Standard Sales - Pro Forma Inv"
        DocumentPrint.PrintProformaSalesInvoice(SalesHeader);

        // [THEN] Verify the TotalVATAmount value in report 1302
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('TotalVATAmount', Format((SalesLine."Amount Including VAT" - SalesLine.Amount), 0, AutoFormat.ResolveAutoFormat(AutoFormatType::AmountFormat, GeneralLedgerSetup."LCY Code")));
    end;

    local procedure NavigateForServiceShipment(WarrantyStartingDate: Date; WarrantyEndingDate: Date): Code[20]
    var
        ServiceHeader: Record "Service Header";
        PostedServiceShipment: TestPage "Posted Service Shipment";
        DummyAmt: Decimal;
    begin
        // Setup: Create Service Order and Post it as Ship.
        Initialize();
        CreateAndPostServiceOrder(
          ServiceHeader, '', WarrantyStartingDate, WarrantyEndingDate, false, false, DummyAmt);  // False for Invoice and Show Amount In LCY.
        PostedServiceShipment.OpenEdit();
        PostedServiceShipment.FILTER.SetFilter("No.", ServiceHeader."Last Shipping No.");

        // Exercise.
        PostedServiceShipment."&Navigate".Invoke();  // Invoking Navigate.

        // Verify.
        VerifyDocumentEntriesForServiceShipment(ServiceHeader."Last Shipping No.");
        exit(ServiceHeader."Last Shipping No.");
    end;

    [Test]
    [HandlerFunctions('NavigatePageHandler,DocumentEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DocumentEntriesForServiceInvoiceInFCY()
    var
        ServiceHeader: Record "Service Header";
        PostedServiceInvoice: TestPage "Posted Service Invoice";
        Amt: Decimal;
    begin
        // [FEATURE] [UI] [Page Navigate]
        // [SCENARIO] Verify that correctness of Document Entries in "Navigate" report for Service Invoice with Currency and Show Amount In FCY.

        // [GIVEN] Shipped and Invoiced Service Order
        Initialize();
        CreateAndPostServiceOrder(
          ServiceHeader, CreateCurrencyAndExchangeRate(), 0D, 0D, true, false, Amt); // True for Invoice and False for Show Amount In LCY.

        PostedServiceInvoice.OpenEdit();
        PostedServiceInvoice.FILTER.SetFilter("No.", ServiceHeader."Last Posting No.");

        // [WHEN] "Navigate" invoked.
        PostedServiceInvoice."&Navigate".Invoke(); // Invoking Navigate.

        // [THEN] Number of entries and amount are correct.
        VerifyDocumentEntriesForServiceInvoice(ServiceHeader."Last Posting No.", ServiceHeader."Customer No.", Amt, AmtCaption);
    end;

    [Test]
    [HandlerFunctions('NavigatePageHandler,DocumentEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DocumentEntriesForServiceInvoiceInLCY()
    var
        ServiceHeader: Record "Service Header";
        PostedServiceInvoice: TestPage "Posted Service Invoice";
        Amt: Decimal;
    begin
        // [FEATURE] [UI] [Page Navigate]
        // [SCENARIO] Verify that correctness of Document Entries in "Navigate" report for Service Invoice With Currency and Show Amount In LCY.

        // [GIVEN] Shipped and Invoiced Service Order, Amount showed in LCY
        Initialize();
        CreateAndPostServiceOrder(
          ServiceHeader, CreateCurrencyAndExchangeRate(), 0D, 0D, true, true, Amt);  // True for Invoice and Show Amount In LCY.
        PostedServiceInvoice.OpenEdit();
        PostedServiceInvoice.FILTER.SetFilter("No.", ServiceHeader."Last Posting No.");

        // [WHEN] "Navigate" invoked.
        PostedServiceInvoice."&Navigate".Invoke();  // Invoking Navigate.

        // [THEN] Number of entries and amount are correct.
        VerifyDocumentEntriesForServiceInvoice(
          ServiceHeader."Last Posting No.", ServiceHeader."Customer No.",
          Amt / ServiceHeader."Currency Factor", AmtLCYCaption);
    end;

    [Test]
    [HandlerFunctions('NavigatePageHandler,DocumentEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DocumentEntriesForServiceCreditMemoInFCY()
    var
        ServiceLine: Record "Service Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [UI] [Page Navigate]
        // [SCENARIO] Verify correctness of Document Entries in "Navigate" report for Service Credit Memo with Currency and Show Amount In FCY.

        // [GIVEN] Shipped and Invoiced Service Order
        // [WHEN] "Navigate" invoked.
        Initialize();
        DocumentNo :=
          CreateAndPostServiceCrMemo(ServiceLine, CreateCurrencyAndExchangeRate(), false);  // False for Show Amount In LCY.

        // [THEN] Number of entries and amount are correct.
        VerifyDocumentEntriesForServiceCrMemo(
          DocumentNo, ServiceLine."Customer No.", -ServiceLine."Amount Including VAT", AmtCaption);
    end;

    [Test]
    [HandlerFunctions('NavigatePageHandler,DocumentEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DocumentEntriesForServiceCreditMemoInLCY()
    var
        ServiceLine: Record "Service Line";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [UI] [Page Navigate]
        // [SCENARIO] Verify correctness of Document Entries in "Navigate" report for Service Credit Memo With Currency and Show Amount In LCY.

        // [GIVEN] Shipped and Invoiced Service Order
        // [WHEN] "Navigate" invoked.
        Initialize();
        DocumentNo :=
          CreateAndPostServiceCrMemo(ServiceLine, CreateCurrencyAndExchangeRate(), true);  // True for Show Amount In LCY.

        // [THEN] Number of entries and amount are correct.
        ServiceCrMemoHeader.Get(DocumentNo);
        VerifyDocumentEntriesForServiceCrMemo(
          DocumentNo, ServiceLine."Customer No.",
          -ServiceLine."Amount Including VAT" / ServiceCrMemoHeader."Currency Factor", AmtLCYCaption);
    end;

    [Test]
    [HandlerFunctions('SignContractConfirmHandler,MessageHandler,ServiceContractTemplateHandler')]
    [Scope('OnPrem')]
    procedure ServiceContractNumbersConbinedInInvoiceLines()
    var
        ServiceContractHeader: array[2] of Record "Service Contract Header";
        CustomerNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [SCENARIO 215205] All service contract numbers must be added into the combined Service Invoice Lines.
        Initialize();

        // [GIVEN] Customer with Two Service Contracts signed and Service Invoices created - "SI1" ad "SI2".
        PrepareCustomerWithTwoContracts(ServiceContractHeader, CustomerNo);

        // [WHEN] Run "Create Contract Invoices" report to create single combined Invoice from "SI1" and "SI2".
        RunCreateContractInvoicesForCustomer(CustomerNo, InvoiceNo);

        // [THEN] Created combined service invoice lines contains service item descriptions from both "SI1" and "SI2".
        VerifyServiceInvoiceLinesDescription(ServiceContractHeader, InvoiceNo);
    end;

    local procedure CreateAndPostServiceOrder(var ServiceHeader: Record "Service Header"; CurrencyCode: Code[10]; WarrantyStartingDate: Date; WarrantyEndingDate: Date; Invoice: Boolean; ShowAmountInLCY: Boolean; var AmtInclVAT: Decimal)
    var
        ServiceLine: Record "Service Line";
    begin
        CreateServiceOrder(ServiceLine, CurrencyCode, WarrantyStartingDate, WarrantyEndingDate);
        AmtInclVAT := ServiceLine."Amount Including VAT";
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");

        LibraryService.PostServiceOrder(ServiceHeader, true, false, Invoice);
        LibraryVariableStorage.Enqueue(ShowAmountInLCY);  // Enqueue value for DocumentEntriesRequestPageHandler.

        AmtInclVAT += ExcludeInvRndingAdjmt(ServiceHeader."Customer No.");
    end;

    local procedure CreateAndPostServiceCrMemo(var ServiceLine: Record "Service Line"; CurrencyCode: Code[10]; ShowAmountInLCY: Boolean) DocumentNo: Code[20]
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        PostedServiceCreditMemo: TestPage "Posted Service Credit Memo";
    begin
        // Setup: Create Service Credit Memo and post.
        CreateItem(Item);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", CreateCustomer(CurrencyCode));
        CreateServiceLineWithItem(ServiceLine, ServiceHeader, '', Item."No.");
        LibraryService.PostServiceOrder(ServiceHeader, false, false, false);
        LibraryVariableStorage.Enqueue(ShowAmountInLCY);  // Enqueue value for DocumentEntriesRequestPageHandler.
        DocumentNo := ServiceHeader."Last Posting No.";
        PostedServiceCreditMemo.OpenEdit();
        PostedServiceCreditMemo.FILTER.SetFilter("No.", ServiceHeader."Last Posting No.");

        // Exercise.
        PostedServiceCreditMemo."&Navigate".Invoke();  // Invoking Navigate.

        ServiceLine."Amount Including VAT" += ExcludeCrMemoRndingAdjmt(ServiceHeader."Customer No.");
    end;

    local procedure CreateCurrencyAndExchangeRate(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);

        // Create Currency Exchange Rate.
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateCustomer(CurrencyCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateDimensionForHeader(var ServiceHeader: Record "Service Header")
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        ServiceHeader.Validate(
          "Dimension Set ID", LibraryDimension.CreateDimSet(ServiceHeader."Dimension Set ID", Dimension.Code, DimensionValue.Code));
        ServiceHeader.Modify(true);
    end;

    local procedure CreateItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        ItemJournalTemplate.SetRange(Recurring, false);
        ItemJournalTemplate.SetRange(Type, ItemJournalTemplate.Type::Item);
        LibraryInventory.FindItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        CreateItemJournalBatch(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase,
          ItemNo, LibraryRandom.RandInt(10));  // Use integer Random Value for Quantity for Item Tracking.

        // Validate Document No. as combination of Journal Batch Name and Line No.
        ItemJournalLine.Validate("Document No.", ItemJournalLine."Journal Batch Name" + Format(ItemJournalLine."Line No."));
        ItemJournalLine.Modify(true);
        Commit();
    end;

    local procedure CreateItemWithItemTrackingCode(): Code[20]
    var
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", FindItemTrackingCode());
        Item.Validate("Serial Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateServiceContract(var ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceContractAccountGroup: Record "Service Contract Account Group";
        ServicePeriod: DateFormula;
    begin
        // Create Service Item, Service Contract Header, Service Contract Line.
        LibraryService.FindContractAccountGroup(ServiceContractAccountGroup);
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, '');
        ServiceContractHeader.Validate("Serv. Contract Acc. Gr. Code", ServiceContractAccountGroup.Code);
        Evaluate(ServicePeriod, '<' + Format(LibraryRandom.RandInt(12)) + 'M>'); // Use Random because value is not important.
        ServiceContractHeader.Validate("Service Period", ServicePeriod);
        ServiceContractHeader.Modify(true);
        CreateServiceContractLine(ServiceContractHeader);
    end;

    local procedure CreateServiceContractLine(ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceItem: Record "Service Item";
        ServiceContractLine: Record "Service Contract Line";
    begin
        LibraryService.CreateServiceItem(ServiceItem, ServiceContractHeader."Customer No.");
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");

        // Use Random because value is not important.
        ServiceContractLine.Validate("Line Cost", LibraryRandom.RandDec(100, 2));
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandDec(100, 2));
        ServiceContractLine.Modify(true);
    end;

    local procedure CreateServiceLine(ServiceHeader: Record "Service Header"; ItemNo: Code[20]; ServiceItemLineNo: Integer; Quantity: Decimal)
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLineNo);
        ServiceLine.Validate(Quantity, Quantity);
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceLineWithItem(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ServiceItemNo: Code[20]; ItemNo: Code[20])
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        ServiceLine.Validate("Service Item No.", ServiceItemNo);
        ServiceLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));  // Use Random Quantity.
        ServiceLine.Modify(true);
    end;

    local procedure ModifyServiceLineQtyToConsume(var ServiceLine: Record "Service Line"; Qty: Decimal)
    begin
        ServiceLine.Validate("Qty. to Consume", Qty);
        ServiceLine.Modify(true);
    end;

    local procedure CreateServicePriceGroupSetup(ServicePriceGroupCode: Code[10])
    var
        ServPriceGroupSetup: Record "Serv. Price Group Setup";
    begin
        LibraryService.CreateServPriceGroupSetup(ServPriceGroupSetup, ServicePriceGroupCode, '', '');
        ServPriceGroupSetup.Validate("Adjustment Type", ServPriceGroupSetup."Adjustment Type"::Fixed);
        ServPriceGroupSetup.Validate(Amount, LibraryRandom.RandDec(100, 2));  // Take Random Value for Amount.
        ServPriceGroupSetup.Modify(true);
    end;

    local procedure CreateServiceOrder(var ServiceLine: Record "Service Line"; CurrencyCode: Code[10]; WarrantyStartingDate: Date; WarrantyEndingDate: Date)
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceHeader: Record "Service Header";
    begin
        CreateItem(Item);
        LibraryService.CreateServiceItem(ServiceItem, CreateCustomer(CurrencyCode));
        ServiceItem.Validate("Warranty Starting Date (Labor)", WarrantyStartingDate);
        ServiceItem.Validate("Warranty Ending Date (Labor)", WarrantyEndingDate);
        ServiceItem.Modify(true);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        CreateServiceLineWithItem(ServiceLine, ServiceHeader, ServiceItem."No.", Item."No.");
    end;

    local procedure CreateServiceOrderMultiLines(var ServiceLine: Record "Service Line")
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceHeader: Record "Service Header";
        i: Integer;
    begin
        CreateItem(Item);
        LibraryService.CreateServiceItem(ServiceItem, CreateCustomer(''));
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        for i := 1 to LibraryRandom.RandIntInRange(2, 5) do begin
            CreateServiceLineWithItem(ServiceLine, ServiceHeader, ServiceItem."No.", Item."No.");
            ModifyServiceLineQtyToConsume(ServiceLine, ServiceLine.Quantity / 2);
        end;
    end;

    local procedure CreateItemLineWithPriceGroup(ServiceHeader: Record "Service Header"; ServiceItemNo: Code[20]; ServicePriceGroupCode: Code[10])
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItemNo);
        ServiceItemLine.Validate("Service Price Group Code", ServicePriceGroupCode);
        ServiceItemLine.Modify(true);
    end;

    local procedure PrepareCustomerWithTwoContracts(var ServiceContractHeader: array[2] of Record "Service Contract Header"; var CustomerNo: Code[20])
    var
        i: Integer;
    begin
        CustomerNo := LibrarySales.CreateCustomerNo();
        for i := 1 to ArrayLen(ServiceContractHeader) do begin
            LibraryService.CreateServiceContractHeader(
              ServiceContractHeader[i], ServiceContractHeader[i]."Contract Type"::Contract, CustomerNo);
            CreateServiceContractLine(ServiceContractHeader[i]);
            ModifyServiceContractHeader(ServiceContractHeader[i]);
            ServiceContractHeader[i].TestField("Combine Invoices", true);
            LibraryService.SignContract(ServiceContractHeader[i]);
        end;
    end;

    local procedure ExecuteConfirmHandlerInvoiceES()
    begin
        if Confirm(StrSubstNo(ExpectedConfirm)) then;
    end;

    local procedure FindItemTrackingCode(): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        ItemTrackingCode.SetRange("SN Specific Tracking", true);
        ItemTrackingCode.FindFirst();
        exit(ItemTrackingCode.Code);
    end;

    local procedure FindServiceCrMemoHeader(PreAssignedNo: Code[20]): Code[20]
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        ServiceCrMemoHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        ServiceCrMemoHeader.FindFirst();
        exit(ServiceCrMemoHeader."No.");
    end;

    local procedure FindServiceLedgerEntry(var ServiceLedgerEntry: Record "Service Ledger Entry"; OrderNo: Code[20])
    begin
        ServiceLedgerEntry.SetRange("Document Type", ServiceLedgerEntry."Document Type"::Shipment);
        ServiceLedgerEntry.SetRange("Document No.", FindServiceShipmentHeader(OrderNo));
        ServiceLedgerEntry.FindFirst();
    end;

    local procedure FindServiceLedgerEntryConsume(var ServiceLedgerEntry: Record "Service Ledger Entry"; OrderNo: Code[20])
    begin
        ServiceLedgerEntry.SetRange("Document Type", ServiceLedgerEntry."Document Type"::Shipment);
        ServiceLedgerEntry.SetRange("Document No.", FindServiceShipmentHeader(OrderNo));
        ServiceLedgerEntry.SetRange("Entry Type", ServiceLedgerEntry."Entry Type"::Consume);
        ServiceLedgerEntry.FindSet();
    end;

    local procedure FindServiceShipmentHeader(OrderNo: Code[20]): Code[20]
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
    begin
        ServiceShipmentHeader.SetRange("Order No.", OrderNo);
        ServiceShipmentHeader.FindFirst();
        exit(ServiceShipmentHeader."No.");
    end;

    local procedure ModifyServiceContractHeader(var ServiceContractHeader: Record "Service Contract Header")
    begin
        ServiceContractHeader.CalcFields("Calcd. Annual Amount");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractHeader."Calcd. Annual Amount");
        ServiceContractHeader.Validate("Starting Date", WorkDate());
        ServiceContractHeader.Validate("Price Update Period", ServiceContractHeader."Service Period");
        ServiceContractHeader.Modify(true);
    end;

    local procedure OpenServiceOrderPage(ServiceHeader: Record "Service Header")
    var
        ServiceOrder: TestPage "Service Order";
    begin
        ServiceOrder.OpenEdit();
        ServiceOrder.FILTER.SetFilter("Document Type", Format(ServiceHeader."Document Type"));
        ServiceOrder.FILTER.SetFilter("No.", ServiceHeader."No.");
        ServiceOrder.ServItemLines."Service Lines".Invoke();
        Commit();
    end;

    local procedure RunCreateContractInvoices(ServiceContractHeader: Record "Service Contract Header")
    var
        CreateContractInvoices: Report "Create Contract Invoices";
        CreateInvoices: Option "Create Invoices","Print Only";
    begin
        Clear(CreateContractInvoices);
        ServiceContractHeader.SetRange("Contract Type", ServiceContractHeader."Contract Type");
        ServiceContractHeader.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        CreateContractInvoices.SetTableView(ServiceContractHeader);
        CreateContractInvoices.SetOptions(WorkDate(), WorkDate(), CreateInvoices::"Print Only");
        CreateContractInvoices.UseRequestPage(false);
        CreateContractInvoices.Run();
    end;

    local procedure RunCreateContractInvoicesForCustomer(CustomerNo: Code[20]; var InvoiceNo: Code[20])
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        CreateContractInvoices: Report "Create Contract Invoices";
        NoSeries: Codeunit "No. Series";
        CreateInvoices: Option "Create Invoices","Print Only";
    begin
        ServiceContractHeader.SetRange("Contract Type", ServiceContractHeader."Contract Type"::Contract);
        ServiceContractHeader.SetRange("Customer No.", CustomerNo);
        ServiceMgtSetup.Get();
        InvoiceNo := NoSeries.PeekNextNo(ServiceMgtSetup."Contract Invoice Nos.");

        Clear(CreateContractInvoices);
        CreateContractInvoices.SetTableView(ServiceContractHeader);
        CreateContractInvoices.SetOptions(WorkDate(), CalcDate('<-CM+1M>', WorkDate()), CreateInvoices::"Create Invoices");
        CreateContractInvoices.UseRequestPage(false);
        CreateContractInvoices.Run();
    end;

    local procedure RunServiceOrderReport(ServiceHeader: Record "Service Header"; ShowInternalInformation: Boolean; ShowQuantity: Option)
    var
        ServiceOrder: Report "Service Order";
    begin
        Clear(ServiceOrder);
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceHeader.SetRange("No.", ServiceHeader."No.");

        ServiceOrder.SetTableView(ServiceHeader);
        ServiceOrder.InitializeRequest(ShowInternalInformation, ShowQuantity);
        Commit();
        ServiceOrder.Run();
    end;

    local procedure SaveServiceCreditMemo(ShowDetail: Boolean; PreAssignedNo: Code[20])
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceCreditMemo: Report "Service - Credit Memo";
    begin
        Clear(ServiceCreditMemo);
        ServiceCrMemoHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        ServiceCreditMemo.SetTableView(ServiceCrMemoHeader);
        ServiceCreditMemo.InitializeRequest(ShowDetail);
        Commit();
        ServiceCreditMemo.Run();
    end;

    local procedure SaveServiceProfitServiceItems(ShowDetail: Boolean; No: Code[20])
    var
        ServiceItem: Record "Service Item";
        ServiceProfitServiceItems: Report "Service Profit (Service Items)";
    begin
        Clear(ServiceProfitServiceItems);
        ServiceItem.SetRange("No.", No);
        ServiceProfitServiceItems.SetTableView(ServiceItem);
        ServiceProfitServiceItems.InitializeRequest(ShowDetail);
        Commit();
        ServiceProfitServiceItems.Run();
    end;

    local procedure SaveServiceProfitServiceOrders(ShowDetail: Boolean; OrderNo: Code[20])
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceProfitServOrders: Report "Service Profit (Serv. Orders)";
    begin
        Clear(ServiceProfitServOrders);
        ServiceShipmentHeader.SetRange("Order No.", OrderNo);
        ServiceProfitServOrders.SetTableView(ServiceShipmentHeader);
        ServiceProfitServOrders.InitializeRequest(ShowDetail);
        Commit();
        REPORT.Run(REPORT::"Service Profit (Serv. Orders)", true, true, ServiceShipmentHeader);
    end;

    local procedure SaveServiceShipment(ShowInternalInfo: Boolean; ShowCorrectionLine: Boolean; ShowLotSerialNoAppendix: Boolean; OrderNo: Code[20])
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceShipment: Report "Service - Shipment";
    begin
        Clear(ServiceShipment);
        ServiceShipmentHeader.SetRange("Order No.", OrderNo);
        ServiceShipment.SetTableView(ServiceShipmentHeader);
        ServiceShipment.InitializeRequest(ShowInternalInfo, ShowCorrectionLine, ShowLotSerialNoAppendix);
        Commit();
        ServiceShipment.Run();
    end;

    local procedure ServiceItemWithSerialAndGroup(var ServiceItem: Record "Service Item"; CustomerNo: Code[20])
    var
        ServiceItemGroup: Record "Service Item Group";
    begin
        LibraryService.CreateServiceItemGroup(ServiceItemGroup);
        LibraryService.CreateServiceItem(ServiceItem, CustomerNo);
        ServiceItem.Validate("Service Item Group Code", ServiceItemGroup.Code);
        ServiceItem.Validate(
          "Serial No.",
          CopyStr(
            LibraryUtility.GenerateRandomCode(ServiceItem.FieldNo("Serial No."), DATABASE::"Service Item"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Service Item", ServiceItem.FieldNo("Serial No."))));
        ServiceItem.Modify(true);
    end;

    local procedure UndoShipment(No: Code[20])
    var
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        ServiceShipmentLine.SetRange("Document No.", FindServiceShipmentHeader(No));
        ServiceShipmentLine.FindFirst();
        CODEUNIT.Run(CODEUNIT::"Undo Service Shipment Line", ServiceShipmentLine);
    end;

    local procedure VerifyDocumentEntriesReport(RowValue: Text; ColumnValue: Decimal)
    begin
        LibraryReportDataset.SetRange(TableName, RowValue);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(NoOfRecords, ColumnValue);
    end;

    local procedure VerifyDocumentEntriesForServiceShipment(DocumentNo: Code[20])
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
        PostedServiceShipment: Page "Posted Service Shipment";
    begin
        LibraryReportDataset.LoadDataSetFile();
        ServiceShipmentHeader.SetRange("No.", DocumentNo);
        VerifyDocumentEntriesReport(PostedServiceShipment.Caption, ServiceShipmentHeader.Count);
        VerifyItemLedgerEntry(DocumentNo);
        VerifyServiceLedgerAndValueEntry(DocumentNo);
    end;

    local procedure VerifyDocumentEntriesForServiceInvoice(DocumentNo: Code[20]; CustomerNo: Code[20]; Amount: Decimal; AmountCaption: Text[1024])
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        PostedServiceInvoice: Page "Posted Service Invoice";
    begin
        LibraryReportDataset.LoadDataSetFile();
        ServiceInvoiceHeader.SetRange("No.", DocumentNo);
        VerifyDocumentEntriesReport(PostedServiceInvoice.Caption, ServiceInvoiceHeader.Count);
        VerifyLedgerEntries(DocumentNo, CustomerNo, Amount, AmountCaption);
    end;

    local procedure VerifyDocumentEntriesForServiceCrMemo(DocumentNo: Code[20]; CustomerNo: Code[20]; Amount: Decimal; AmountCaption: Text[1024])
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        PostedServiceCreditMemo: Page "Posted Service Credit Memo";
    begin
        LibraryReportDataset.LoadDataSetFile();
        ServiceCrMemoHeader.SetRange("No.", DocumentNo);
        VerifyDocumentEntriesReport(PostedServiceCreditMemo.Caption, ServiceCrMemoHeader.Count);
        VerifyItemLedgerEntry(DocumentNo);
        VerifyLedgerEntries(DocumentNo, CustomerNo, Amount, AmountCaption);
    end;

    local procedure VerifyItemLedgerEntry(DocumentNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        VerifyDocumentEntriesReport(ItemLedgerEntry.TableCaption(), ItemLedgerEntry.Count);
    end;

    local procedure VerifyLedgerEntries(DocumentNo: Code[20]; CustomerNo: Code[20]; Amount: Decimal; AmountCaption: Text[1024])
    var
        GLEntry: Record "G/L Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        VATEntry: Record "VAT Entry";
    begin
        VerifyServiceLedgerAndValueEntry(DocumentNo);

        GLEntry.SetRange("Document No.", DocumentNo);
        VerifyDocumentEntriesReport(GLEntry.TableCaption(), GLEntry.Count);

        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        VerifyDocumentEntriesReport(CustLedgerEntry.TableCaption(), CustLedgerEntry.Count);
        LibraryReportDataset.SetRange(CustNoCaption, CustomerNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(AmountCaption, Amount);

        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        VerifyDocumentEntriesReport(DetailedCustLedgEntry.TableCaption(), DetailedCustLedgEntry.Count);

        VATEntry.SetRange("Document No.", DocumentNo);
        VerifyDocumentEntriesReport(VATEntry.TableCaption(), VATEntry.Count);
    end;

    local procedure SwapMonthAndDay(DateString: Text) SwappedDateString: Text
    var
        Day: Text;
        Month: Text;
        Year: Text;
        DateStringWithoutDay: Text;
    begin
        Day := CopyStr(DateString, 1, StrPos(DateString, '-') - 1);
        DateStringWithoutDay := DelStr(DateString, 1, StrPos(DateString, '-'));
        Month := CopyStr(DateStringWithoutDay, 1, StrPos(DateStringWithoutDay, '-') - 1);
        Year := DelStr(DateStringWithoutDay, 1, StrPos(DateStringWithoutDay, '-'));
        SwappedDateString := StrSubstNo('%2-%1-%3', Day, Month, Year);
    end;

    local procedure VerifyServiceLedgerAndValueEntry(DocumentNo: Code[20])
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
        ServiceLedgerEntry.SetRange("Document No.", DocumentNo);
        VerifyDocumentEntriesReport(ServiceLedgerEntry.TableCaption(), ServiceLedgerEntry.Count);

        ValueEntry.SetRange("Document No.", DocumentNo);
        VerifyDocumentEntriesReport(ValueEntry.TableCaption(), ValueEntry.Count);
    end;

    local procedure VerifyServiceCreditMemoReport(ServiceCrMemoNo: Code[20])
    var
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        FoundVariant: Variant;
        PostingDate: Date;
        DateString: Text;
        ExpectedDescription: Text;
        ExpectedVATIdentifier: Code[20];
    begin
        ServiceCrMemoLine.SetRange("Document No.", FindServiceCrMemoHeader(ServiceCrMemoNo));
        ServiceCrMemoLine.FindFirst();
        LibraryReportDataset.SetRange(CrMemoLineNoXMLCap, '10000');
        LibraryReportDataset.GetNextRow();
        // Description:
        LibraryReportDataset.FindCurrentRowValue(DescrServCrMemoLineXMLCap, FoundVariant);
        ExpectedDescription := FoundVariant;
        ServiceCrMemoLine.TestField(Description, ExpectedDescription);
        // Posting Date:
        LibraryReportDataset.FindCurrentRowValue(PostingDateCaptionXMLCap, FoundVariant);
        DateString := ConvertStr(FoundVariant, '/', '-');
        if not Evaluate(PostingDate, DateString) then
            Evaluate(PostingDate, SwapMonthAndDay(DateString));

        ServiceCrMemoLine.TestField("Posting Date", PostingDate);
        // VAT Identifier:
        LibraryReportDataset.FindCurrentRowValue(CrMemoLineVATIdXMLCap, FoundVariant);
        ExpectedVATIdentifier := FoundVariant;
        if ExpectedVATIdentifier = '' then
            ServiceCrMemoLine.TestField("VAT Identifier", '')
        else
            ServiceCrMemoLine.TestField("VAT Identifier", ExpectedVATIdentifier);

        VerifyElementNumeralValue(
          QtyCrMemoLineCap,
          ServiceCrMemoLine.Quantity,
          0,
          StrSubstNo(ValidationError, QtyCrMemoLineCap, ServiceCrMemoLine.Quantity));

        VerifyElementNumeralValue(
          UnitPriceCrMemoLineCap,
          ServiceCrMemoLine."Unit Price",
          0,
          StrSubstNo(ValidationError, UnitPriceCrMemoLineCap, ServiceCrMemoLine."Unit Price"));

        VerifyElementNumeralValue(
          CrMemoLineDiscCaptionXMLCap,
          ServiceCrMemoLine."Line Discount %",
          0,
          StrSubstNo(ValidationError, CrMemoLineDiscCaptionXMLCap, ServiceCrMemoLine."Line Discount %"));

        VerifyElementNumeralValue(
          AmtCaptionCrMemoLineCap,
          ServiceCrMemoLine.Amount,
          0,
          StrSubstNo(ValidationError, AmtCaptionCrMemoLineCap, ServiceCrMemoLine.Amount));
    end;

    local procedure VerifyServiceOrderWithQuantity(ServiceLine: Record "Service Line")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Amount: Variant;
    begin
        LibraryReportDataset.LoadDataSetFile();

        LibraryReportDataset.SetRange('Type_ServLine', Format(ServiceLine.Type));
        LibraryReportDataset.GetNextRow();

        LibraryReportDataset.AssertCurrentRowValueEquals('Qty', ServiceLine.Quantity);
        LibraryReportDataset.AssertCurrentRowValueEquals('UnitPrice_ServLine', ServiceLine."Unit Price");

        GeneralLedgerSetup.Get();

        LibraryReportDataset.FindCurrentRowValue('Amt', Amount);

        Assert.AreNearlyEqual(
          ServiceLine.Quantity * ServiceLine."Unit Price" -
          ServiceLine.Quantity * ServiceLine."Unit Price" * ServiceLine."Line Discount %" / 100,
          Amount, GeneralLedgerSetup."Amount Rounding Precision", StrSubstNo(AmountMustMatchError, Amount));
    end;

    local procedure VerifyServicePricingReport(ServiceOrderNo: Code[20])
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
        ActualProfit: Variant;
        ProfitAmount: Decimal;
        AmountPlusDiscount: Decimal;
    begin
        LibraryReportDataset.LoadDataSetFile();
        FindServiceLedgerEntry(ServiceLedgerEntry, ServiceOrderNo);

        ProfitAmount := ServiceLedgerEntry."Amount (LCY)" + ServiceLedgerEntry."Discount Amount" - ServiceLedgerEntry."Cost Amount";

        LibraryReportDataset.SetRange('CustNo_ServShpItemLine', ServiceLedgerEntry."Customer No.");
        LibraryReportDataset.GetNextRow();

        LibraryReportDataset.AssertCurrentRowValueEquals('UsageAmt', ServiceLedgerEntry."Amount (LCY)");
        LibraryReportDataset.AssertCurrentRowValueEquals('InvoiceAmt',
          ServiceLedgerEntry."Amount (LCY)" + ServiceLedgerEntry."Discount Amount");
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'DiscountAmt',
          ServiceLedgerEntry."Discount Amount");
        LibraryReportDataset.AssertCurrentRowValueEquals('CostAmt', ServiceLedgerEntry."Cost Amount");
        LibraryReportDataset.AssertCurrentRowValueEquals('ProfitAmt', ProfitAmount);
        LibraryReportDataset.FindCurrentRowValue('Profit', ActualProfit);

        AmountPlusDiscount := ServiceLedgerEntry."Amount (LCY)" + ServiceLedgerEntry."Discount Amount";
        Assert.AreEqual(
          Round(ActualProfit),
          Round(ProfitAmount * 100 / AmountPlusDiscount),
          'Rounded Profits match');
    end;

    local procedure VerifyServiceProfitItemsReport(ServiceOrderNo: Code[20])
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
        ProfitAmount: Decimal;
    begin
        FindServiceLedgerEntry(ServiceLedgerEntry, ServiceOrderNo);
        ProfitAmount := ServiceLedgerEntry."Amount (LCY)" - ServiceLedgerEntry."Cost Amount";

        LibraryReportDataset.AssertCurrentRowValueEquals('SalesAmount', ServiceLedgerEntry."Amount (LCY)");
        LibraryReportDataset.AssertCurrentRowValueEquals('DiscountAmount', ServiceLedgerEntry."Discount Amount");
        LibraryReportDataset.AssertCurrentRowValueEquals('CostAmount', ServiceLedgerEntry."Cost Amount");
        LibraryReportDataset.AssertCurrentRowValueEquals('ProfitAmount', ProfitAmount);
    end;

    local procedure VerifyServiceProfitOrderReport(ServiceLedgerEntry: Record "Service Ledger Entry")
    begin
        LibraryReportDataset.AssertCurrentRowValueEquals('AmountLCY', ServiceLedgerEntry."Amount (LCY)");
        LibraryReportDataset.AssertCurrentRowValueEquals('CostAmount', ServiceLedgerEntry."Cost Amount");
        LibraryReportDataset.AssertCurrentRowValueEquals('DiscountAmount', ServiceLedgerEntry."Discount Amount");
    end;

    local procedure VerifyServiceShipmentReport(ServiceOrderNo: Code[20])
    var
        ServiceShipmentLine: Record "Service Shipment Line";
        Variant: Variant;
        FoundRow: Boolean;
        DoLoop: Boolean;
        RowValue: Integer;
    begin
        ServiceShipmentLine.SetRange("Document No.", FindServiceShipmentHeader(ServiceOrderNo));
        ServiceShipmentLine.FindFirst();

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange(ServiceShipHeaderNoCap, ServiceShipmentLine."Document No.");
        LibraryReportDataset.SetRange(ServiceShipItemLineNoCap, ServiceShipmentLine."Service Item Line No.");
        FoundRow := false;
        DoLoop := true;
        while DoLoop do begin
            DoLoop := LibraryReportDataset.GetNextRow();
            if DoLoop then begin
                FoundRow := LibraryReportDataset.CurrentRowHasElement(ServiceShipItemLineNoCap);
                Variant := RowValue;
                LibraryReportDataset.FindCurrentRowValue(ServiceShipItemLineNoCap, Variant);
                RowValue := Variant;
                if RowValue = ServiceShipmentLine."Service Item Line No." then begin
                    DoLoop := false;
                    FoundRow := true;
                end
            end
        end;
        Assert.IsTrue(FoundRow,
          StrSubstNo('Found Service Item: %1 for header : %2',
            ServiceShipmentLine."Document No.",
            ServiceShipmentLine."Service Item Line No."));
        LibraryReportDataset.AssertCurrentRowValueEquals('No_ServiceShptItemLn', ServiceShipmentLine."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('ServShptLnDescription', ServiceShipmentLine.Description);
        LibraryReportDataset.AssertCurrentRowValueEquals('UnitofMeasure_ServShptLn', ServiceShipmentLine."Unit of Measure");
        LibraryReportDataset.AssertCurrentRowValueEquals('Qty_ServiceShptItemLn', ServiceShipmentLine.Quantity);
        LibraryReportDataset.AssertCurrentRowValueEquals('QtyInvoiced_ServShptLine', ServiceShipmentLine."Quantity Invoiced");
    end;

    local procedure VerifyElementNumeralValue(ElementName: Text; ExpectedNumeral: Decimal; Tolerance: Decimal; ErrTxt: Text[1024])
    var
        ActualNumeral: Variant;
    begin
        LibraryReportDataset.FindCurrentRowValue(ElementName, ActualNumeral);
        if Tolerance = 0 then
            Assert.AreEqual(ExpectedNumeral, ActualNumeral, ErrTxt)
        else
            Assert.AreNearlyEqual(ExpectedNumeral, ActualNumeral, Tolerance, ErrTxt);
    end;

    local procedure VerifyServiceProfitOrderReportMultiLines(ServiceHeaderNo: Code[20])
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        LibraryReportDataset.LoadDataSetFile();
        FindServiceLedgerEntryConsume(ServiceLedgerEntry, ServiceHeaderNo);
        repeat
            LibraryReportDataset.GetNextRow();
            LibraryReportDataset.AssertCurrentRowValueEquals('EntryNo_ServLedgEntryNo', ServiceLedgerEntry."No.");
            LibraryReportDataset.GetNextRow();
            LibraryReportDataset.AssertCurrentRowValueEquals('Quantity', -ServiceLedgerEntry.Quantity);
            LibraryReportDataset.AssertCurrentRowValueEquals('CostAmount', -ServiceLedgerEntry."Cost Amount");
        until ServiceLedgerEntry.Next() = 0;
    end;

    local procedure VerifyServiceInvoiceLinesDescription(ServiceContractHeader: array[2] of Record "Service Contract Header"; InvoiceNo: Code[20])
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        i: Integer;
    begin
        ServiceHeader.Get(ServiceHeader."Document Type"::Invoice, InvoiceNo);
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange(Type, ServiceLine.Type::" ");
        for i := 1 to ArrayLen(ServiceContractHeader) do begin
            ServiceLine.SetFilter(Description, StrSubstNo('Service Contract: %1', ServiceContractHeader[i]."Contract No."));
            Assert.RecordIsNotEmpty(ServiceLine);
        end;
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItemWithUnitPriceUnitCostAndPostingGroup(
            Item,
            LibraryRandom.RandDec(100, 2),
            LibraryRandom.RandDec(100, 2)
        );
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure SignContractConfirmHandler(SignContractMessage: Text[1024]; var Result: Boolean)
    begin
        // Confirmation message handler to Sign Service Contract.
        Result := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceContractTemplateHandler(var ServiceContractTemplateList: Page "Service Contract Template List";

    var
        Response: Action)
    begin
        Response := ACTION::LookupOK;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ContractInvoicingReportHandler(var ContractInvoicing: TestRequestPage "Contract Invoicing")
    begin
        ContractInvoicing.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        Commit();
        if SetHandler then
            ItemTrackingLines."Assign Serial No.".Invoke()
        else
            ItemTrackingLines."Select Entries".Invoke();
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
        Commit();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure QuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceLinesPageHandler(var ServiceLines: TestPage "Service Lines")
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLines.FILTER.SetFilter(Type, Format(ServiceLine.Type::Item));
        ServiceLines.FILTER.SetFilter("No.", ItemNo);
        ServiceLines.ItemTrackingLines.Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure InvoiceESConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := (Question = ExpectedConfirm);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure NavigatePageHandler(var Navigate: TestPage Navigate)
    begin
        Navigate.Print.Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DocumentEntriesRequestPageHandler(var DocumentEntries: TestRequestPage "Document Entries")
    var
        ShowAmountInLCY: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowAmountInLCY);  // Dequeue variable.
        DocumentEntries.PrintAmountsInLCY.SetValue(ShowAmountInLCY);  // Setting Show Amount In LCY option.
        DocumentEntries.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceOrderWithQuantityHandler(var ServiceOrder: TestRequestPage "Service Order")
    begin
        ServiceOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceProfitItemsShowDetailHandler(var ServiceProfitServiceItems: TestRequestPage "Service Profit (Service Items)")
    begin
        ServiceProfitServiceItems.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceProfitItemsHandler(var ServiceProfitServiceItems: TestRequestPage "Service Profit (Service Items)")
    begin
        ServiceProfitServiceItems.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoReportHandler(var ServiceCreditMemo: TestRequestPage "Service - Credit Memo")
    begin
        ServiceCreditMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceProfitOrdersHandler(var ServiceProfitServOrders: TestRequestPage "Service Profit (Serv. Orders)")
    begin
        ServiceProfitServOrders.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceProfitOrdersShowDetailHandler(var ServiceProfitServOrders: TestRequestPage "Service Profit (Serv. Orders)")
    begin
        ServiceProfitServOrders.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure ExcludeInvRndingAdjmt(CustNo: Code[20]): Decimal
    var
        ServInvHeader: Record "Service Invoice Header";
        ServInvLine: Record "Service Invoice Line";
    begin
        ServInvHeader.SetRange("Customer No.", CustNo);
        if not ServInvHeader.FindLast() then
            exit(0);

        ServInvLine.SetRange("Document No.", ServInvHeader."No.");
        ServInvLine.SetRange(Type, ServInvLine.Type::"G/L Account");
        ServInvLine.SetFilter(Amount, '>%1&<%2', -1, 1);
        if ServInvLine.FindFirst() then
            exit(ServInvLine."Amount Including VAT");
    end;

    local procedure ExcludeCrMemoRndingAdjmt(CustNo: Code[20]): Decimal
    var
        ServCrMemoHeader: Record "Service Cr.Memo Header";
        ServCrMemoLine: Record "Service Cr.Memo Line";
    begin
        ServCrMemoHeader.SetRange("Customer No.", CustNo);
        if not ServCrMemoHeader.FindLast() then
            exit(0);

        ServCrMemoLine.SetRange("Document No.", ServCrMemoHeader."No.");
        ServCrMemoLine.SetRange(Type, ServCrMemoLine.Type::"G/L Account");
        ServCrMemoLine.SetFilter(Amount, '>%1&<%2', -1, 1);
        if ServCrMemoLine.FindFirst() then
            exit(ServCrMemoLine."Amount Including VAT");
    end;

    local procedure CreateTaxAreaWithTaxAreaLine(var TaxArea: Record "Tax Area"): Code[10]
    var
        TaxAreaLine: Record "Tax Area Line";
        TaxDetail: Record "Tax Detail";
    begin
        CreateTaxDetailWithJurisdiction(TaxDetail);
        TaxArea.Code := LibraryUTUtility.GetNewCode();
        // TFS ID 387685: Check that TaxArea with maxstrlen Description doesn't raise StringOverflow
        TaxArea.Description := LibraryUtility.GenerateRandomXMLText(MaxStrLen(TaxArea.Description));
        TaxArea.Insert();
        TaxAreaLine."Tax Area" := TaxArea.Code;
        TaxAreaLine."Tax Jurisdiction Code" := TaxDetail."Tax Jurisdiction Code";
        TaxAreaLine.Insert();
        exit(TaxDetail."Tax Group Code");
    end;

    local procedure CreateTaxDetailWithJurisdiction(var TaxDetail: Record "Tax Detail")
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        TaxJurisdiction.Code := LibraryUTUtility.GetNewCode10();
        TaxJurisdiction.Insert();
        TaxDetail."Tax Jurisdiction Code" := TaxJurisdiction.Code;
        TaxDetail."Tax Group Code" := LibraryUTUtility.GetNewCode10();
        TaxDetail."Tax Below Maximum" := LibraryRandom.RandDecInRange(5, 10, 2);
        TaxDetail.Insert();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceShipmentReportlHandler(var ServiceShipment: TestRequestPage "Service - Shipment")
    begin
        ServiceShipment.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServicePricingProfitabilityReportlHandler(var ServPricingProfitability: TestRequestPage "Serv. Pricing Profitability")
    begin
        ServPricingProfitability.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardSalesProFormaInvRequestPageHandler(var StandardSalesProFormaInv: TestRequestPage "Standard Sales - Pro Forma Inv")
    begin
        StandardSalesProFormaInv.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

