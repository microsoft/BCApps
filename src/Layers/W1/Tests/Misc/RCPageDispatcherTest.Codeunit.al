codeunit 134681 "RC Page Dispatcher Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Role Center] [Dispatcher]
    end;

    var
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySales: Codeunit "Library - Sales";
        isInitialized: Boolean;

    [Test]
    procedure T001_PurchasePricesAsPurchasePriceLists()
    var
        AllObjWithCaption: Record AllObjWithCaption;
        TestPurchasePriceLists: TestPage "Purchase Price Lists";
    begin
        Initialize();
        // [GIVEN] New pricing feature is on
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        // [WHEN] Run "Role Center Page Dispatcher" as Page "Purchase Prices"
        TestPurchasePriceLists.Trap();
        RunRoleCenterPageDispatcher(AllObjWithCaption."Object Type"::Page, Page::"Purchase Prices");
        // [THEN] Page "Purchase Price Lists" is open
        TestPurchasePriceLists.Close();
    end;

    [Test]
    procedure T002_PurchaseLineDiscountsAsPurchasePriceLists()
    var
        AllObjWithCaption: Record AllObjWithCaption;
        TestPurchasePriceLists: TestPage "Purchase Price Lists";
    begin
        Initialize();
        // [GIVEN] New pricing feature is on
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        // [WHEN] Run "Role Center Page Dispatcher" as Page "Purchase Line Discounts"
        TestPurchasePriceLists.Trap();
        RunRoleCenterPageDispatcher(AllObjWithCaption."Object Type"::Page, Page::"Purchase Line Discounts");
        // [THEN] Page "Purchase Price Lists" is open
        TestPurchasePriceLists.Close();
    end;

    [Test]
    procedure T003_ResourceCostsAsPurchaseJobPriceLists()
    var
        AllObjWithCaption: Record AllObjWithCaption;
        TestPurchaseJobPriceLists: TestPage "Purchase Job Price Lists";
    begin
        Initialize();
        // [GIVEN] New pricing feature is on
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        // [WHEN] Run "Role Center Page Dispatcher" as Page "Resource Costs"
        TestPurchaseJobPriceLists.Trap();
        RunRoleCenterPageDispatcher(AllObjWithCaption."Object Type"::Page, Page::"Resource Costs");
        // [THEN] Page "Purchase Job Price Lists" is open
        TestPurchaseJobPriceLists.Close();
    end;

    [Test]
    procedure T004_ResourcePricesAsSalesJobPriceLists()
    var
        AllObjWithCaption: Record AllObjWithCaption;
        TestSalesJobPriceLists: TestPage "Sales Job Price Lists";
    begin
        Initialize();
        // [GIVEN] New pricing feature is on
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        // [WHEN] Run "Role Center Page Dispatcher" as Page "Resource Prices"
        TestSalesJobPriceLists.Trap();
        RunRoleCenterPageDispatcher(AllObjWithCaption."Object Type"::Page, Page::"Resource Prices");
        // [THEN] Page "Sales Job Price Lists" is open
        TestSalesJobPriceLists.Close();
    end;

    procedure T005_SalesPricesAsSalesPriceLists()
    var
        AllObjWithCaption: Record AllObjWithCaption;
        TestSalesPriceLists: TestPage "Sales Price Lists";
    begin
        Initialize();
        // [GIVEN] New pricing feature is on
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        // [WHEN] Run "Role Center Page Dispatcher" as Page "Sales Prices"
        TestSalesPriceLists.Trap();
        RunRoleCenterPageDispatcher(AllObjWithCaption."Object Type"::Page, Page::"Sales Prices");
        // [THEN] Page "Sales Price Lists" is open
        TestSalesPriceLists.Close();
    end;

    [Test]
    procedure T006_SalesLineDiscountsAsSalesPriceLists()
    var
        AllObjWithCaption: Record AllObjWithCaption;
        TestSalesPriceLists: TestPage "Sales Price Lists";
    begin
        Initialize();
        // [GIVEN] New pricing feature is on
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        // [WHEN] Run "Role Center Page Dispatcher" as Page "Sales Line Discounts"
        TestSalesPriceLists.Trap();
        RunRoleCenterPageDispatcher(AllObjWithCaption."Object Type"::Page, Page::"Sales Line Discounts");
        // [THEN] Page "Sales Price Lists" is open
        TestSalesPriceLists.Close();
    end;

    [Test]
    procedure T007_SalesPriceWorksheetAsPriceWorksheet()
    var
        AllObjWithCaption: Record AllObjWithCaption;
        TestPriceWorksheet: TestPage "Price Worksheet";
    begin
        Initialize();
        // [GIVEN] New pricing feature is on
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        // [WHEN] Run "Role Center Page Dispatcher" as Page "Sales Price Worksheet"
        TestPriceWorksheet.Trap();
        RunRoleCenterPageDispatcher(AllObjWithCaption."Object Type"::Page, Page::"Sales Price Worksheet");
        // [THEN] Page "Price Worksheet" is open
        TestPriceWorksheet.Close();
    end;

    [Test]
    procedure T008_ResourcePriceChangesAsPriceWorksheet()
    var
        AllObjWithCaption: Record AllObjWithCaption;
        TestPriceWorksheet: TestPage "Price Worksheet";
    begin
        Initialize();
        // [GIVEN] New pricing feature is on
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        // [WHEN] Run "Role Center Page Dispatcher" as Page "Resource Price Changes"
        TestPriceWorksheet.Trap();
        RunRoleCenterPageDispatcher(AllObjWithCaption."Object Type"::Page, Page::"Resource Price Changes");
        // [THEN] Page "Price Worksheet" is open
        TestPriceWorksheet.Close();
    end;

    [Test]
    [HandlerFunctions('ItemPriceListHandler')]
    procedure T009_ReportPriceListAsItemPriceList()
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        Initialize();
        // [GIVEN] New pricing feature is on
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        // [WHEN] Run "Role Center Page Dispatcher" as Report "Price List"
        RunRoleCenterPageDispatcher(AllObjWithCaption."Object Type"::Report, Report::"Price List");
        // [THEN] Report "Item Price List" is open
        // handled by ItemPriceListHandler
    end;

    [Test]
    [HandlerFunctions('ResPriceListHandler')]
    procedure T010_ReportPriceListAsItemPriceList()
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        Initialize();
        // [GIVEN] New pricing feature is on
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        // [WHEN] Run "Role Center Page Dispatcher" as Report "Resource - Price List"
        RunRoleCenterPageDispatcher(AllObjWithCaption."Object Type"::Report, Report::"Resource - Price List");
        // [THEN] Report "Res. Price List" is open
        // handled by ResPriceListHandler
    end;

    [Test]
    procedure T011_SuggestResPriceChgResAsPriceWorksheet()
    var
        AllObjWithCaption: Record AllObjWithCaption;
        TestPriceWorksheet: TestPage "Price Worksheet";
    begin
        Initialize();
        // [GIVEN] New pricing feature is on
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        // [WHEN] Run "Role Center Page Dispatcher" as Report "Suggest Res. Price Chg. (Res.)"
        TestPriceWorksheet.Trap();
        RunRoleCenterPageDispatcher(AllObjWithCaption."Object Type"::Report, Report::"Suggest Res. Price Chg. (Res.)");
        // [THEN] Page "Price Worksheet" is open
        TestPriceWorksheet.Close();
    end;

    [Test]
    procedure T012_SuggestResPriceChgPriceAsPriceWorksheet()
    var
        AllObjWithCaption: Record AllObjWithCaption;
        TestPriceWorksheet: TestPage "Price Worksheet";
    begin
        Initialize();
        // [GIVEN] New pricing feature is on
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        // [WHEN] Run "Role Center Page Dispatcher" as Report "Suggest Res. Price Chg.(Price)"
        TestPriceWorksheet.Trap();
        RunRoleCenterPageDispatcher(AllObjWithCaption."Object Type"::Report, Report::"Suggest Res. Price Chg.(Price)");
        // [THEN] Page "Price Worksheet" is open
        TestPriceWorksheet.Close();
    end;

    [Test]
    procedure T013_ImplementResPriceChangeAsPriceWorksheet()
    var
        AllObjWithCaption: Record AllObjWithCaption;
        TestPriceWorksheet: TestPage "Price Worksheet";
    begin
        Initialize();
        // [GIVEN] New pricing feature is on
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        // [WHEN] Run "Role Center Page Dispatcher" as Report "Implement Res. Price Change"
        TestPriceWorksheet.Trap();
        RunRoleCenterPageDispatcher(AllObjWithCaption."Object Type"::Report, Report::"Implement Res. Price Change");
        // [THEN] Page "Price Worksheet" is open
        TestPriceWorksheet.Close();
    end;

    [Test]
    [HandlerFunctions('ItemPriceListReportHandler,CustomerLookupHandler')]
    procedure TestItemPriceList()
    var
        CustomerNo, CustomerNo1 : Code[20];
    begin
        // [SCENARIO 572934] Item price list print report request page Assign-to field disabled
        // Setup: Set Report format to Print.
        Initialize();

        // [GIVEN] Create Customer
        CustomerNo := LibrarySales.CreateCustomerNo();

        // [GIVEN] Print Item Price List Report for Customer Created
        Commit();
        LibraryVariableStorage.Enqueue(CustomerNo);
        REPORT.Run(REPORT::"Item Price List");

        // [WHEN] Create Second Customer
        CustomerNo1 := LibrarySales.CreateCustomerNo();

        // [THEN] Item Price List Request Page should be open with Second Customer Filter
        Commit();
        LibraryVariableStorage.Enqueue(CustomerNo1);
        REPORT.Run(REPORT::"Item Price List");
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"RC Page Dispatcher Test");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"RC Page Dispatcher Test");


        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"RC Page Dispatcher Test");
    end;

    local procedure RunRoleCenterPageDispatcher(ObjType: Option; ObjID: Integer)
    var
        AllObjWithCaption: Record AllObjWithCaption;
        RoleCenterPageDispatcher: Page "Role Center Page Dispatcher";
        TestRoleCenterPageDispatcher: TestPage "Role Center Page Dispatcher";
    begin
        // Run "Role Center Page Dispatcher" as ObjType ObjID
        AllObjWithCaption.Get(ObjType, ObjId);
        RoleCenterPageDispatcher.SetRecord(AllObjWithCaption);
        TestRoleCenterPageDispatcher.Trap();
        asserterror RoleCenterPageDispatcher.Run();
        // Page "Role Center Page Dispatcher" is closed with an empty error
        Assert.ExpectedError('');
    end;

    local procedure FormatFileName(ReportCaption: Text) ReportFileName: Text
    begin
        ReportFileName := DelChr(ReportCaption, '=', '/') + '.pdf'
    end;

    [RequestPageHandler]
    procedure ItemPriceListHandler(var ItemPriceList: TestRequestPage "Item Price List")
    begin
        ItemPriceList.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure ResPriceListHandler(var ResPriceList: TestRequestPage "Res. Price List")
    begin
        ResPriceList.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure ItemPriceListReportHandler(var ItemPriceList: TestRequestPage "Item Price List")
    begin
        ItemPriceList.SourceType.SetValue(11);
        ItemPriceList.SourceNoCtrl.Lookup();
        ItemPriceList.Date.SetValue(WorkDate());
        ItemPriceList.SaveAsPdf(FormatFileName(ItemPriceList.Caption));
    end;

    [ModalPageHandler]
    procedure CustomerLookupHandler(var CustomerLookup: TestPage "Customer Lookup")
    begin
        CustomerLookup.Filter.SetFilter("No.", LibraryVariableStorage.DequeueText());
        CustomerLookup.OK().Invoke();
    end;
}