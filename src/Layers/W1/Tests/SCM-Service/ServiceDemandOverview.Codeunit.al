// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Availability;
using Microsoft.Service.Document;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Requisition;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Manufacturing.Document;
using Microsoft.Inventory.Transfer;
using Microsoft.Inventory.Location;
using Microsoft.Assembly.Document;
using Microsoft.Service.Item;
using Microsoft.Projects.Project.Job;
using Microsoft.Sales.Customer;

codeunit 136131 "Service Demand Overview"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Demand Overview]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryJob: Codeunit "Library - Job";
        DescriptionText: Label 'NTF_TEST_NTF_TEST';
        NoDataForExecutionError: Label 'No service item has a non-blocked customer and non-blocked item. Execution stops.';
        LibraryService: Codeunit "Library - Service";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        ShipmentDateDocumentError: Label 'No Sales Line found with sales order no %1.';
        LibrarySales: Codeunit "Library - Sales";
        DemandOverviewAllFilter: Label 'All Demands';
        DemandOverviewSaleFilter: Label 'Sales Demand';
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryRandom: Codeunit "Library - Random";
        ItemNo: Code[20];
        NoDate: Integer;
        IsInitialized: Boolean;
        ReceiptDateDocumentError: Label 'No Purchase Line found with sales order no %1.';
        LineCountError: Label 'No. of Lines in %1 must be equal to %2.';
        OriginalQuantity: Decimal;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Demand Overview");
        // Clear the needed globals
        ClearGlobals();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Demand Overview");

        // Setup demonstration data
        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        // Set the Stockout warning to checked in receivables setup
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Demand Overview");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StartDateNoEndDateQtySumCheck()
    var
        Item: Record Item;
        DemandOverview: TestPage "Demand Overview";
        FirstPurchaseQuantity: Integer;
        SecondPurchaseQuantity: Integer;
        FirstSaleQuantity: Integer;
        SecondSaleQuantity: Integer;
        PurchaseOrderNo: Code[20];
        ExpectedRows: Integer;
        SalesOrderNo: Code[20];
        QuantitySum: Integer;
        ActualRowCount: Integer;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Sales demand, start date filter, no end date. Set start date = W - 5. All supply and demand should be shown. The quantity sum should be 4.
        Initialize();
        FirstPurchaseQuantity := LibraryRandom.RandIntInRange(3, 12);
        SecondPurchaseQuantity := LibraryRandom.RandIntInRange(3, 7);
        FirstSaleQuantity := FirstPurchaseQuantity - 2;
        SecondSaleQuantity := SecondPurchaseQuantity - 2;
        ExpectedRows := 7;

        // [GIVEN] Create Supply and demand.
        CreateItem(Item, Item."Reordering Policy"::" ");
        PurchaseOrderNo := CreatePurchaseSupply(Item."No.", FirstPurchaseQuantity);
        CreatePurchaseSupplyAfter(Item."No.", SecondPurchaseQuantity, GetReceiptDate(PurchaseOrderNo));
        SalesOrderNo := CreateSalesDemand(Item."No.", FirstSaleQuantity);
        CreateSalesDemandAfter(Item."No.", SecondSaleQuantity, GetShipmentDate(SalesOrderNo));

        // [WHEN] Open Demand overview and set the needed fields.
        DemandOverview.OpenEdit();
        SetItemOnlyFilter(DemandOverview, Item."No.");
        DemandOverview.Calculate.Invoke();

        // [THEN] The number of rows returned and the total sum of quantities returned matches.
        ActualRowCount := 0;
        repeat
            if not DemandOverview.IsExpanded then
                DemandOverview.Expand(true);
            if DemandOverview.QuantityText.Value <> '' then
                QuantitySum := QuantitySum + DemandOverview.QuantityText.AsInteger();
            ActualRowCount := ActualRowCount + 1;
        until not DemandOverview.Next();

        Assert.AreEqual(FirstPurchaseQuantity + SecondPurchaseQuantity - FirstSaleQuantity - SecondSaleQuantity, QuantitySum,
          'Sum of quantities of all lines');
        Assert.AreEqual(ExpectedRows, ActualRowCount, 'No. of expected rows match');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StartDateEndFilterTests()
    var
        Item: Record Item;
        DemandOverview: TestPage "Demand Overview";
        SalesOrderNo: Code[20];
        PurchaseQuantity: Integer;
        SaleQuantity: Integer;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Sales demand, Supply on WorkDate(), Demand on WorkDate(), WorkDate() + 1, WorkDate() + 2. Start date and end date are both before supply and demand.

        Initialize();
        PurchaseQuantity := LibraryRandom.RandInt(100);
        SaleQuantity := PurchaseQuantity;

        CreateItem(Item, Item."Reordering Policy"::" ");
        CreatePurchaseSupply(Item."No.", PurchaseQuantity);

        // [GIVEN] Create one row of supply on work date.
        // [GIVEN] Create one row of Demand on work date,work date + 1, work date + 2.
        SalesOrderNo := CreateSalesDemand(Item."No.", SaleQuantity);
        SalesOrderNo := CreateSalesDemandAfter(Item."No.", SaleQuantity, GetShipmentDate(SalesOrderNo));
        SalesOrderNo := CreateSalesDemandAfter(Item."No.", SaleQuantity, GetShipmentDate(SalesOrderNo));

        // [WHEN] Open demand overview
        DemandOverview.OpenView();

        // [THEN] When Start Date and end date are before supply and demand no lines are shown.
        // [THEN] When Start date before supply and demand, end Date on WorkDate() + 1, 6 lines are shown.
        // [THEN] When Start Date on WorkDate() + 1 and end date is blank, 5 lines are shown.
        // [THEN] When Start Date and end date are after supply and demand no lines are shown.
        // [THEN] When Start Date and end date are blank all lines (8) are shown.
        SetAndVerifyDateFilters(DemandOverview, Item."No.", -10, -8, NoDate, 0);
        SetAndVerifyDateFilters(DemandOverview, Item."No.", -10, 1, NoDate, 6);
        SetAndVerifyDateFilters(DemandOverview, Item."No.", 1, NoDate, NoDate, 5);
        SetAndVerifyDateFilters(DemandOverview, Item."No.", 10, 20, NoDate, 0);
        SetAndVerifyDateFilters(DemandOverview, Item."No.", NoDate, NoDate, NoDate, 8);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyDemandAllDemandTypes()
    var
        Item: Record Item;
        DemandOverview: TestPage "Demand Overview";
        PurchaseQuantity: Integer;
        SaleQuantity: Integer;
        JobQuantity: Integer;
        ServiceQuantity: Integer;
    begin
        // [FEATURE] [Sales] [Service] [Job]
        // [SCENARIO] The demand overview page should contain one line of each category.
        Initialize();
        PurchaseQuantity := LibraryRandom.RandIntInRange(11, 15);
        SaleQuantity := LibraryRandom.RandInt(3);
        JobQuantity := LibraryRandom.RandInt(7);
        ServiceQuantity := PurchaseQuantity - SaleQuantity - JobQuantity;

        // [GIVEN] Create supply, Create demand of types sales, service, job.
        CreateItem(Item, Item."Reordering Policy"::" ");
        CreatePurchaseSupply(Item."No.", PurchaseQuantity);
        CreateJobDemand(Item."No.", JobQuantity);
        CreateServiceDemand(Item."No.", ServiceQuantity);
        CreateSalesDemand(Item."No.", SaleQuantity);

        // [WHEN] open demand overview page. Set filter on item no and all demand types only.
        DemandOverview.OpenEdit();
        SetItemOnlyFilter(DemandOverview, Item."No.");
        DemandOverview.Calculate.Invoke();

        // [THEN] The number of rows returned and the sum of quantities returned.
        VerifyOverviewLineQuantities(DemandOverview, 'Sales', 1, -SaleQuantity);
        VerifyOverviewLineQuantities(DemandOverview, 'Project', 1, -JobQuantity);
        VerifyOverviewLineQuantities(DemandOverview, 'Service', 1, -ServiceQuantity);
        VerifyOverviewLineQuantities(DemandOverview, 'Purchase', 1, PurchaseQuantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyDemandUnusedItemFilter()
    var
        Item: Record Item;
        UnusedItem: Record Item;
        DemandOverview: TestPage "Demand Overview";
        Quantity: Integer;
    begin
        // [FEATURE] [Sales] [Service] [Job]
        // [SCENARO] When running demand overview for the unused item, no lines should be shown.
        Initialize();
        Quantity := LibraryRandom.RandInt(12);

        // [GIVEN] Create demand of types job, sales, service for item 1.
        CreateItem(Item, Item."Reordering Policy"::" ");
        CreatePurchaseSupply(Item."No.", Quantity);
        CreateJobDemand(Item."No.", Quantity);
        CreateServiceDemand(Item."No.", Quantity);
        CreateSalesDemand(Item."No.", Quantity);

        // [WHEN] Run demand overview for item 2.
        CreateItem(UnusedItem, Item."Reordering Policy"::" ");
        DemandOverview.OpenEdit();
        SetItemOnlyFilter(DemandOverview, UnusedItem."No.");
        DemandOverview.Calculate.Invoke();

        // [THEN] No lines are returned when no supply and demand have been created.
        Assert.AreEqual(0, CountOverviewGridLines(DemandOverview), 'Verify no rows are listed when filtering on a unused Item');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyDemandLocationFilter()
    var
        Item: Record Item;
        DemandOverview: TestPage "Demand Overview";
        Quantity: Integer;
        LocationCode: Code[10];
    begin
        // [FEATURE] [Sales] [Service] [Job]
        // [SCENARO] When running demand overview without location limitation, all lines should be shown. When running demand overview for a location without supply or demand, no lines should be shown.

        Initialize();
        Quantity := LibraryRandom.RandInt(12);

        // [GIVEN] Create demand of types job, sales, service for item in location A.
        LocationCode := CreateLocation();
        CreateItem(Item, Item."Reordering Policy"::" ");
        CreatePurchaseSupplyAtLocation(Item."No.", Quantity, LocationCode);
        CreateJobDemandAtLocation(Item."No.", Quantity, LocationCode);
        CreateServiceDemandAtLocation(Item."No.", Quantity, LocationCode);
        CreateSalesDemandAtLocation(Item."No.", Quantity, LocationCode);

        // [WHEN] Run demand overview for Location B.
        DemandOverview.OpenEdit();
        SetItemOnlyFilter(DemandOverview, Item."No.");
        DemandOverview.LocationFilter.Value(Format(CreateLocation()));
        DemandOverview.Calculate.Invoke();

        // [THEN] No lines are returned when no supply and demand have been created in location B.
        Assert.AreEqual(0, CountOverviewGridLines(DemandOverview), 'Verify no rows are listed when filtering on a unused Location');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyDemandSameVariantFilter()
    var
        Item: Record Item;
        DemandOverview: TestPage "Demand Overview";
        Quantity: Integer;
        ActualRowsCount: Integer;
    begin
        // [FEATURE] [Sales] [Service] [Job]
        // [SCENARIO] When running demand overview without variant filter or for variant 1, all lines should be shown. When running demand overview for another variant, no lines should be shown.

        Initialize();
        Quantity := LibraryRandom.RandInt(12);

        // [GIVEN] Create Supply and Demand to Variant no. 1
        CreateItemWithVariants(Item);
        CreatePurchaseSupplyForVariant(Item."No.", Quantity, 1);
        CreateJobDemandForVariant(Item."No.", Quantity, 1);
        CreateServiceDemandForVariant(Item."No.", Quantity, 1);
        CreateSalesDemandForVariant(Item."No.", Quantity, 1);

        // [WHEN] Open Demand Overview and set Demand to Variant no. 1 and count lines (count1).
        // [WHEN] Open Demand Overview and set Demand to Variant no. 2 and count lines (count2) .
        DemandOverview.OpenEdit();
        SetItemOnlyFilter(DemandOverview, Item."No.");
        DemandOverview.VariantFilter.Value(Format(GetVariant(Item."No.", 1)));
        DemandOverview.Calculate.Invoke();
        ActualRowsCount := CountOverviewGridLines(DemandOverview);
        DemandOverview.VariantFilter.Value(Format(GetVariant(Item."No.", 2)));
        DemandOverview.Calculate.Invoke();

        // [THEN] count1 matches the no. of supply and demand lines created.
        // [THEN] count2 is zero as no lines have been created for variant 2.
        Assert.AreEqual(0, CountOverviewGridLines(DemandOverview), 'Verify no rows are listed when filtering on a unused variant');
        Assert.AreEqual(6, ActualRowsCount, 'Verify rows are listed when filtering on a used variant');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderBlankNeededByDate()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        ServiceLines: TestPage "Service Lines";
        PurchaseQuantity: Integer;
        ServiceQuantity: Integer;
        PurchaseOrderNo: Code[20];
        ServiceOrderNo: Code[20];
    begin
        // [FEATURE] [Service]
        // [SCENARIO] Service demand, start date filter, no end date. Set start date = W - 5. All supply and demand should be shown. The quantity sum should be 4.
        Initialize();
        PurchaseQuantity := LibraryRandom.RandIntInRange(2, 10);
        ServiceQuantity := LibraryRandom.RandInt(PurchaseQuantity - 1);

        // [GIVEN] Create suppply and  service demand.
        CreateItem(Item, Item."Reordering Policy"::" ");
        PurchaseOrderNo := CreatePurchaseSupply(Item."No.", PurchaseQuantity);
        CreatePurchaseSupplyAfter(Item."No.", PurchaseQuantity, GetReceiptDate(PurchaseOrderNo));

        // [WHEN] Edit the needed by date in Service line and blank it.
        ServiceOrderNo := CreateServiceDemand(Item."No.", ServiceQuantity);
        OpenFirstServiceLines(ServiceLines, ServiceOrderNo);
        ServiceLines.First();
        asserterror ServiceLines."Needed by Date".Value := '';

        // [THEN] The validation error text is displayed and matches expected.
        Assert.ExpectedTestFieldError(ServiceLine.FieldCaption("Needed by Date"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculatePlanForServiceAndJobDemand()
    var
        Item: Record Item;
        Quantity: Decimal;
    begin
        // [FEATURE] [Job] [Service]
        // [SCENARIO] Check Planning Lines for Sevice and Job Demand using Reordering Policy as Order after running Calculate Regenerative Plan.

        // [GIVEN] Create Item with Reordering Policy as Order, Create demand for Service and Job.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItem(Item, Item."Reordering Policy"::Order);
        CreateJobDemand(Item."No.", Quantity);
        CreateServiceDemand(Item."No.", Quantity);

        // [WHEN] Calculate Regenerative Plan. Using Random Date for Order Date.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // [THEN] Verify: Verify Planning Worksheet Lines.
        VerifyRequisitionLine(Item."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationForServiceAndJobDemand()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Job] [Service] [Planning Worksheet] [Reservation] [Reordering Policy]
        // [SCENARIO] Check Planning Lines Reservation for Sevice and Job Demand using Reordering Policy as Order after running Calculate Regenerative Plan.

        // [GIVEN] Create Item with Reordering Policy as Order, Create demand for Service and Job, Calculate Regenerative Plan. Using Random Date for Order Date.
        Initialize();
        CreateItem(Item, Item."Reordering Policy"::Order);
        ItemNo := Item."No.";  // Assigning global variables as required in Page Handler.
        OriginalQuantity := LibraryRandom.RandDec(10, 2);
        CreateJobDemand(Item."No.", OriginalQuantity);
        CreateServiceDemand(Item."No.", OriginalQuantity);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // [WHEN] Filter Planning Worksheet Lines for Item and run Reserve.
        FilterRequisitionLine(RequisitionLine, Item."No.");
        RequisitionLine.ShowReservation();

        // [THEN] Demand is fully reserved
        // Verification Done on ReservationPageHandler.
    end;

    [Test]
    [HandlerFunctions('ReservationActionsPageHandler,AvailableJobPlanningLinesPageHandler,ReservationEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationQuantityForJobDemand()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Job] [Planning Worksheet] [Reservation] [Reordering Policy]
        // [SCENARIO] Check Available Job Planning Lines and Reservation Entries from Reservation using Reordering Policy as Order after running Calculate Regenerative Plan.

        // [GIVEN] Create Item with Reordering Policy as Order, Create demand for Service and Job, Calculate Regenerative Plan. Using Random Date for Order Date.
        Initialize();
        CreateItem(Item, Item."Reordering Policy"::Order);
        ItemNo := Item."No."; // Assigning global variables as required in Page Handler.
        OriginalQuantity := LibraryRandom.RandDec(10, 2);
        CreateJobDemand(Item."No.", OriginalQuantity);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // [WHEN] Filter Planning Worksheet Lines for Item and run Reserve.
        FilterRequisitionLine(RequisitionLine, Item."No.");
        RequisitionLine.ShowReservation();

        // [THEN] Demand is fully reserved
        // Verification Done on AvailableJobPlanningLinesPageHandler and ReservationEntriesPageHandler.
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandlerAvailableToReserve,AvailableJobPlanningLinesReservePageHandler')]
    [Scope('OnPrem')]
    procedure ReservationQuantityForJobDemandAndPurchaseSupply()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Available - Job Planning Lines] [Job] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Job Planning Lines" page when demand is Job Planning Line, and supply - Purchase Order

        Initialize();
        // [GIVEN] Job planning line and purchase order for the same item "I" with quantity "X"
        CreateItem(Item, Item."Reordering Policy"::Order);
        ItemNo := Item."No."; // Assigning global variables as required in Page Handler.
        OriginalQuantity := LibraryRandom.RandDec(10, 2);
        CreateJobDemand(Item."No.", OriginalQuantity);

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', ItemNo, OriginalQuantity, '', WorkDate());

        // [WHEN] Open "Available - Job Planning Lines" page and run "Reserve" action
        PurchaseLine.ShowReservation();

        // [THEN] Full supply quantity is reserved
    end;

    [Test]
    [HandlerFunctions('ReservationActionsPageHandler,AvailableServiceLinesPageHandler,ReservationEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationQuantityForServiceDemand()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Available - Service Lines] [Service] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Service Lines" page when demand is Service Line, and supply - Purchase Order

        // [GIVEN] Create Item with Reordering Policy as Order, Create demand for Service and Job, Calculate Regenerative Plan. Using Random Date for Order Date.
        Initialize();
        CreateItem(Item, Item."Reordering Policy"::Order);
        ItemNo := Item."No."; // Assigning global variables as required in Page Handler.
        OriginalQuantity := LibraryRandom.RandDec(10, 2);
        CreateServiceDemand(Item."No.", OriginalQuantity);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // [WHEN] Filter Planning Worksheet Lines for Item and run Reserve.
        FilterRequisitionLine(RequisitionLine, Item."No.");
        RequisitionLine.ShowReservation();

        // [THEN] Demand is fully reserved
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandlerAvailableToReserve,AvailableJobPlanningLinesCancelReservationPageHandler,ConfirmTrueHandler')]
    [Scope('OnPrem')]
    procedure ReservationQuantityForJobDemandCancelReservation()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Available - Job Planning Lines] [Job] [Reservation]
        // [SCENARIO] Cancel reservation from "Available - Job Planning Lines" page

        // [GIVEN] Create Item "I" and job demand for this item
        Initialize();
        CreateItem(Item, Item."Reordering Policy"::Order);
        ItemNo := Item."No."; // Assigning global variables as required in Page Handler.
        OriginalQuantity := LibraryRandom.RandDec(10, 2);
        CreateJobDemand(Item."No.", OriginalQuantity);

        // [GIVEN] Create purchase supply for item "I" and autoreserve it.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', ItemNo, OriginalQuantity, '', WorkDate());
        AutoReservePurchaseLine(PurchaseLine, OriginalQuantity);

        // [WHEN] Open "Available - Job Planning Lines" page and cancel reservation
        PurchaseLine.ShowReservation();

        // [THEN] Reserved quantity is 0
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandlerAvailableToReserve,AvailableServiceLinesCancelReservationPageHandler,ConfirmTrueHandler')]
    [Scope('OnPrem')]
    procedure ReservationQuantityForServiceDemandCancelReservation()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Available - Service Lines] [Service] [Reservation]
        // [SCENARIO] Cancel reservation from "Available - Service Lines" page

        // [GIVEN] Create Item "I" and service demand for this item
        Initialize();
        CreateItem(Item, Item."Reordering Policy"::Order);
        ItemNo := Item."No."; // Assigning global variables as required in Page Handler.
        OriginalQuantity := LibraryRandom.RandDec(10, 2);
        CreateServiceDemand(Item."No.", OriginalQuantity);

        // [GIVEN] Create purchase order for item "I" and autoreserve it.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', ItemNo, OriginalQuantity, '', WorkDate());
        AutoReservePurchaseLine(PurchaseLine, OriginalQuantity);

        // [WHEN] Open "Available - Service Lines" page and cancel reservation
        PurchaseLine.ShowReservation();

        // [THEN] Reserved quantity is 0
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandlerAvailableToReserve,AvailableServiceLinesReservePageHandler')]
    [Scope('OnPrem')]
    procedure ReservationQuantityForServiceDemandAndPurchaseSupply()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Available - Service Lines] [Service] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Service Lines" page when demand is Service Line, and supply - Purchase Order

        Initialize();
        CreateItem(Item, Item."Reordering Policy"::Order);
        ItemNo := Item."No."; // Assigning global variables as required in Page Handler.
        OriginalQuantity := LibraryRandom.RandDec(10, 2);
        CreateServiceDemand(Item."No.", OriginalQuantity);

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', ItemNo, OriginalQuantity, '', WorkDate());

        PurchaseLine.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandlerAvailableToReserve,AvailableServiceLinesReservePageHandler')]
    [Scope('OnPrem')]
    procedure ReservationQuantityForServiceDemandAndSalesReturnSupplyReserveFromSupply()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Available - ServiceLines] [Service] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Service Lines" page when demand is Service Line, and supply - Sales Return Order

        Initialize();
        CreateItem(Item, Item."Reordering Policy"::Order);
        ItemNo := Item."No."; // Assigning global variables as required in Page Handler.
        OriginalQuantity := LibraryRandom.RandDec(10, 2);
        CreateServiceDemand(Item."No.", OriginalQuantity);

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '', ItemNo, OriginalQuantity, '', WorkDate());

        SalesLine.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandlerAvailableToReserve,AvailableSalesLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationQuantityForServiceDemandAndSalesReturnSupplyReserveFromDemand()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Available - Sales Lines] [Sales] [Service] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Sales Lines" page when demand is Service Line, and supply - Sales Return Order

        Initialize();
        CreateItem(Item, Item."Reordering Policy"::Order);
        ItemNo := Item."No."; // Assigning global variables as required in Page Handler.
        OriginalQuantity := LibraryRandom.RandDec(10, 2);

        FindServiceLine(ServiceLine, ServiceLine."Document Type"::Order, CreateServiceDemand(Item."No.", OriginalQuantity));
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '', ItemNo, OriginalQuantity, '', WorkDate());

        ServiceLine.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandlerAvailableToReserve,AvailableJobPlanningLinesReservePageHandler')]
    [Scope('OnPrem')]
    procedure ReservationQuantityForJobDemandAndSalesReturnSupplyReserveFromSupply()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Available - Job Planning Lines] [Job] [Sales Return] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Job Planning Lines" page when demand is Job Planning Line, and supply - Sales Return Order

        Initialize();
        CreateItem(Item, Item."Reordering Policy"::Order);
        ItemNo := Item."No."; // Assigning global variables as required in Page Handler.
        OriginalQuantity := LibraryRandom.RandDec(10, 2);
        CreateJobDemand(Item."No.", OriginalQuantity);

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '', ItemNo, OriginalQuantity, '', WorkDate());

        SalesLine.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandlerAvailableToReserve,AvailableSalesLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationQuantityForJobDemandAndSalesReturnSupplyReserveFromDemand()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Available - Sales Lines] [Job] [Sales Return] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Sales Lines" page when demand is Job Planning Line, and supply - Sales Return Order
        Initialize();
        CreateItem(Item, Item."Reordering Policy"::Order);
        ItemNo := Item."No."; // Assigning global variables as required in Page Handler.
        OriginalQuantity := LibraryRandom.RandDec(10, 2);

        JobPlanningLine.SetRange("Job No.", CreateJobDemand(Item."No.", OriginalQuantity));
        JobPlanningLine.FindFirst();

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '', ItemNo, OriginalQuantity, '', WorkDate());
        JobPlanningLine.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandlerAvailableToReserve,AvailablePurchaseLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationQuantityForServiceDemandAndPurchaseSupplyReserveFromDemand()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Available - Purchase Lines] [Service] [Purchase] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Purchase Lines" page when demand is Service Line, and supply - Purchase Order
        Initialize();
        CreateItem(Item, Item."Reordering Policy"::Order);
        ItemNo := Item."No."; // Assigning global variables as required in Page Handler.
        OriginalQuantity := LibraryRandom.RandDec(10, 2);

        FindServiceLine(ServiceLine, ServiceLine."Document Type"::Order, CreateServiceDemand(Item."No.", OriginalQuantity));

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', ItemNo, OriginalQuantity, '', WorkDate());
        ServiceLine.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandlerAvailableToReserve,AvailablePurchaseLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationQuantityForJobDemandAndPurchaseSupplyReserveFromDemand()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Available - Purchase Lines] [Job] [Purchase] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Purchase Lines" page when demand is Job Planning Line, and supply - Purchase Order
        Initialize();
        CreateItem(Item, Item."Reordering Policy"::Order);
        ItemNo := Item."No."; // Assigning global variables as required in Page Handler.
        OriginalQuantity := LibraryRandom.RandDec(10, 2);

        JobPlanningLine.SetRange("Job No.", CreateJobDemand(Item."No.", OriginalQuantity));
        JobPlanningLine.FindFirst();

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', ItemNo, OriginalQuantity, '', WorkDate());
        JobPlanningLine.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandlerAvailableToReserve,AvailableServiceLinesReservePageHandler')]
    [Scope('OnPrem')]
    procedure ReservationQuantityForServiceDemandAndProdOrderSupplyReserveFromSupply()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // [FEATURE] [Available - Service Lines] [Service] [Production] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Service Lines" page when demand is Sercice Line, and supply - Production Order
        Initialize();
        CreateItem(Item, Item."Reordering Policy"::Order);
        ItemNo := Item."No."; // Assigning global variables as required in Page Handler.
        OriginalQuantity := LibraryRandom.RandDec(10, 2);
        CreateServiceDemand(Item."No.", OriginalQuantity);

        CreateAndRefreshProductionOrder(ProductionOrder, Item."No.", OriginalQuantity);
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");

        ProdOrderLine.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandlerAvailableToReserve,AvailableJobPlanningLinesReservePageHandler')]
    [Scope('OnPrem')]
    procedure ReservationQuantityForJobDemandAndProdOrderSupplyReserveFromSupply()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // [FEATURE] [Available - Job Planning Lines] [Job] [Production] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Job Planning Lines" page when demand is Job Planning Line, and supply - Production Order
        Initialize();
        CreateItem(Item, Item."Reordering Policy"::Order);
        ItemNo := Item."No."; // Assigning global variables as required in Page Handler.
        OriginalQuantity := LibraryRandom.RandDec(10, 2);
        CreateJobDemand(Item."No.", OriginalQuantity);

        CreateAndRefreshProductionOrder(ProductionOrder, Item."No.", OriginalQuantity);
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");

        ProdOrderLine.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandlerAvailableToReserve,AvailableProdOrderLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationQuantityForServiceDemandAndProdOrderSupplyReserveFromDemand()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Available - Prod. Order Lines] [Production] [Service] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Prod. Order Lines" page when demand is Service Line, and supply - Production Order
        Initialize();
        CreateItem(Item, Item."Reordering Policy"::Order);
        ItemNo := Item."No."; // Assigning global variables as required in Page Handler.
        OriginalQuantity := LibraryRandom.RandDec(10, 2);
        FindServiceLine(ServiceLine, ServiceLine."Document Type"::Order, CreateServiceDemand(Item."No.", OriginalQuantity));

        CreateAndRefreshProductionOrder(ProductionOrder, Item."No.", OriginalQuantity);

        ServiceLine.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandlerAvailableToReserve,AvailableProdOrderLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationQuantityForJobDemandAndProdOrderSupplyReserveFromDemand()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [FEATURE] [Available - Prod. Order Lines] [Production] [Job] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Prod. Order Lines" page when demand is Job Planning Line, and supply - Production Order
        Initialize();
        CreateItem(Item, Item."Reordering Policy"::Order);
        ItemNo := Item."No."; // Assigning global variables as required in Page Handler.
        OriginalQuantity := LibraryRandom.RandDec(10, 2);
        JobPlanningLine.SetRange("Job No.", CreateJobDemand(Item."No.", OriginalQuantity));
        JobPlanningLine.FindFirst();

        CreateAndRefreshProductionOrder(ProductionOrder, Item."No.", OriginalQuantity);

        JobPlanningLine.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ReservationPageHandlerAvailableToReserve,AvailableServiceLinesReservePageHandler')]
    [Scope('OnPrem')]
    procedure ReservationQuantityForServiceDemandAndTransferSupplyReserveFromSupply()
    var
        Item: Record Item;
        TransferLine: Record "Transfer Line";
        FromLocation: Record Location;
        ToLocation: Record Location;
    begin
        // [FEATURE] [Available - Service Lines] [Service] [Transfer] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Service Lines" page when demand is Service Line, and supply - Transfer Order
        Initialize();
        CreateItem(Item, Item."Reordering Policy"::Order);
        ItemNo := Item."No."; // Assigning global variables as required in Page Handler.
        OriginalQuantity := LibraryRandom.RandDec(10, 2);

        LibraryWarehouse.CreateLocation(FromLocation);
        LibraryWarehouse.CreateLocation(ToLocation);
        CreateServiceDemandBasis(Item."No.", OriginalQuantity, ToLocation.Code, '', WorkDate());
        CreateTransferOrder(TransferLine, FromLocation.Code, ToLocation.Code, Item."No.", OriginalQuantity);

        TransferLine.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ReservationPageHandlerAvailableToReserve,AvailableJobPlanningLinesReservePageHandler')]
    [Scope('OnPrem')]
    procedure ReservationQuantityForJobDemandAndTransferSupplyReserveFromSupply()
    var
        Item: Record Item;
        TransferLine: Record "Transfer Line";
        FromLocation: Record Location;
        ToLocation: Record Location;
    begin
        // [FEATURE] [Available - Job Planning Lines] [Job] [Transfer] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Job Planning Lines" page when demand is Job Planning Line, and supply - Transfer Order
        Initialize();
        CreateItem(Item, Item."Reordering Policy"::Order);
        ItemNo := Item."No."; // Assigning global variables as required in Page Handler.
        OriginalQuantity := LibraryRandom.RandDec(10, 2);
        CreateJobDemand(Item."No.", OriginalQuantity);

        LibraryWarehouse.CreateLocation(FromLocation);
        LibraryWarehouse.CreateLocation(ToLocation);

        CreateJobDemandAtBasis(Item."No.", OriginalQuantity, ToLocation.Code, '', WorkDate());
        CreateTransferOrder(TransferLine, FromLocation.Code, ToLocation.Code, Item."No.", OriginalQuantity);

        TransferLine.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandlerAvailableToReserve,AvailableTransferLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationQuantityForServiceDemandAndTransferSupplyReserveFromDemand()
    var
        Item: Record Item;
        TransferLine: Record "Transfer Line";
        FromLocation: Record Location;
        ToLocation: Record Location;
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Available - Transfer Lines] [Service] [Transfer] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Transfer Lines" page when demand is Service Line, and supply - Transfer Order
        Initialize();
        CreateItem(Item, Item."Reordering Policy"::Order);
        ItemNo := Item."No."; // Assigning global variables as required in Page Handler.
        OriginalQuantity := LibraryRandom.RandDec(10, 2);

        LibraryWarehouse.CreateLocation(FromLocation);
        LibraryWarehouse.CreateLocation(ToLocation);

        FindServiceLine(
          ServiceLine, ServiceLine."Document Type"::Order,
          CreateServiceDemandBasis(Item."No.", OriginalQuantity, ToLocation.Code, '', WorkDate()));
        CreateTransferOrder(TransferLine, FromLocation.Code, ToLocation.Code, Item."No.", OriginalQuantity);

        ServiceLine.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandlerAvailableToReserve,AvailableTransferLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationQuantityForJobDemandAndTransferSupplyReserveFromDemand()
    var
        Item: Record Item;
        TransferLine: Record "Transfer Line";
        FromLocation: Record Location;
        ToLocation: Record Location;
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [FEATURE] [Available - Transfer Lines] [Job] [Transfer] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Transfer Lines" page when demand is Job Planning Line, and supply - Transfer Order
        Initialize();
        CreateItem(Item, Item."Reordering Policy"::Order);
        ItemNo := Item."No."; // Assigning global variables as required in Page Handler.
        OriginalQuantity := LibraryRandom.RandDec(10, 2);
        CreateJobDemand(Item."No.", OriginalQuantity);

        LibraryWarehouse.CreateLocation(FromLocation);
        LibraryWarehouse.CreateLocation(ToLocation);

        JobPlanningLine.SetRange("Job No.", CreateJobDemandAtBasis(Item."No.", OriginalQuantity, ToLocation.Code, '', WorkDate()));
        JobPlanningLine.FindFirst();

        CreateTransferOrder(TransferLine, FromLocation.Code, ToLocation.Code, Item."No.", OriginalQuantity);

        JobPlanningLine.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandlerAvailableToReserve,AvailableServiceLinesReservePageHandler')]
    [Scope('OnPrem')]
    procedure ReservationQuantityForServiceDemandAndAssemblySupplyReserveFromSupply()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
    begin
        // [FEATURE] [Available - Service Lines] [Service] [Assembly] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Service Lines" page when demand is Service Line, and supply - Assembly Order
        Initialize();
        CreateItem(Item, Item."Reordering Policy"::Order);
        ItemNo := Item."No."; // Assigning global variables as required in Page Handler.
        OriginalQuantity := LibraryRandom.RandDec(10, 2);
        CreateServiceDemand(Item."No.", OriginalQuantity);

        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), Item."No.", '', OriginalQuantity, '');
        AssemblyHeader.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandlerAvailableToReserve,AvailableJobPlanningLinesReservePageHandler')]
    [Scope('OnPrem')]
    procedure ReservationQuantityForJobDemandAndAssemblySupplyReserveFromSupply()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
    begin
        // [FEATURE] [Available - Job Planning Lines] [Job] [Assembly] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Job Planning Lines" page when demand is Job Planning Line, and supply - Assembly Order
        Initialize();
        CreateItem(Item, Item."Reordering Policy"::Order);
        ItemNo := Item."No."; // Assigning global variables as required in Page Handler.
        OriginalQuantity := LibraryRandom.RandDec(10, 2);
        CreateJobDemand(Item."No.", OriginalQuantity);

        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), Item."No.", '', OriginalQuantity, '');
        AssemblyHeader.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandlerAvailableToReserve,AvailableAssemblyHeadersPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationQuantityForServiceDemandAndAssemblySupplyReserveFromDemand()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Available - Assembly Lines] [Service] [Assembly] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Assembly Lines" page when demand is Service Line, and supply - Assembly Order
        Initialize();
        CreateItem(Item, Item."Reordering Policy"::Order);
        ItemNo := Item."No."; // Assigning global variables as required in Page Handler.
        OriginalQuantity := LibraryRandom.RandDec(10, 2);

        FindServiceLine(
          ServiceLine, ServiceLine."Document Type"::Order, CreateServiceDemand(Item."No.", OriginalQuantity));

        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), Item."No.", '', OriginalQuantity, '');
        ServiceLine.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandlerAvailableToReserve,AvailableAssemblyHeadersPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationQuantityForJobDemandAndAssemblySupplyReserveFromDemand()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [FEATURE] [Available - Assembly Lines] [Job] [Assembly] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Assembly Lines" page when demand is Job Planning Line, and supply - Assembly Order
        Initialize();
        CreateItem(Item, Item."Reordering Policy"::Order);
        ItemNo := Item."No."; // Assigning global variables as required in Page Handler.
        OriginalQuantity := LibraryRandom.RandDec(10, 2);

        JobPlanningLine.SetRange("Job No.", CreateJobDemand(Item."No.", OriginalQuantity));
        JobPlanningLine.FindFirst();

        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), Item."No.", '', OriginalQuantity, '');
        JobPlanningLine.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandlerAvailableToReserve,AvailableJobPlanningLinesDrillDownPageHandler,ReservationEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationQuantityForJobDemandDrillDownReservEntries()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Available - Job Planning Lines] [Job] [Reservation]
        // [SCENARIO] Drill down "Current Reserve Quantity" in "Available - Job Planning Lines" shows correct reserved quantity

        // [GIVEN] Create item "I" with job planning demand and purchase supply, quantity = "X". Autoreserve supply
        Initialize();
        CreateItem(Item, Item."Reordering Policy"::Order);
        ItemNo := Item."No."; // Assigning global variables as required in Page Handler.
        OriginalQuantity := LibraryRandom.RandDec(10, 2);
        CreateJobDemand(Item."No.", OriginalQuantity);
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', ItemNo, OriginalQuantity, '', WorkDate());

        AutoReservePurchaseLine(PurchaseLine, OriginalQuantity);

        // [WHEN] Open "Available - Job Planning Lines" page and run drill down action in "Current Reserved Quantity" field
        PurchaseLine.ShowReservation();

        // [THEN] Total quantity in reservation entries = "X"
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandlerAvailableToReserve,AvailableServiceLinesDrillDownPageHandler,ReservationEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationQuantityForServiceDemandDrillDownReservEntries()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Available - Job Planning Lines] [Job] [Reservation]
        // [SCENARIO] Drill down "Current Reserve Quantity" in "Available - Job Planning Lines" shows correct reserved quantity

        // [GIVEN] Create item "I" with service demand and purchase supply, quantity = "X". Autoreserve supply
        Initialize();
        CreateItem(Item, Item."Reordering Policy"::Order);
        ItemNo := Item."No."; // Assigning global variables as required in Page Handler.
        OriginalQuantity := LibraryRandom.RandDec(10, 2);
        CreateServiceDemand(Item."No.", OriginalQuantity);

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', ItemNo, OriginalQuantity, '', WorkDate());

        AutoReservePurchaseLine(PurchaseLine, OriginalQuantity);

        // [WHEN] Open "Available - Service Lines" page and run drill down action in "Current Reserved Quantity" field
        PurchaseLine.ShowReservation();

        // [THEN] Total quantity in reservation entries = "X"
    end;

    local procedure AddBiasToWorkDate(DateBias: Integer): Date
    var
        TheDate: Date;
        BiasString: DateFormula;
    begin
        TheDate := WorkDate();
        if DateBias <> 0 then begin
            Evaluate(BiasString, '<' + Format(DateBias) + 'D>');
            TheDate := CalcDate(BiasString, TheDate);
        end;
        exit(TheDate);
    end;

    local procedure AutoReservePurchaseLine(PurchaseLine: Record "Purchase Line"; Quantity: Decimal)
    var
        ReservMgt: Codeunit "Reservation Management";
        FullAutoReservation: Boolean;
    begin
        ReservMgt.SetReservSource(PurchaseLine);
        ReservMgt.AutoReserve(FullAutoReservation, '', WorkDate(), Quantity, Quantity);
    end;

    local procedure ClearGlobals()
    begin
        // Clear all global variables
        NoDate := -10000;
        ItemNo := '';
        OriginalQuantity := 0;
    end;

    local procedure ClearDemandTypeAndNoFilter(DemandOverview: TestPage "Demand Overview")
    begin
        DemandOverview.DemandType.Value(DemandOverviewAllFilter);
        DemandOverview.DemandType.Value(DemandOverviewSaleFilter);
        DemandOverview.DemandNoCtrl.Value('');
        DemandOverview.DemandType.Value(DemandOverviewAllFilter);
    end;

    local procedure CountOverviewGridLines(DemandOverview: TestPage "Demand Overview"): Integer
    var
        RowsCount: Integer;
    begin
        RowsCount := 0;
        DemandOverview.First();
        if DemandOverview."Item No.".Value = '' then
            exit(RowsCount);
        repeat
            if not DemandOverview.IsExpanded then
                DemandOverview.Expand(true);
            RowsCount := RowsCount + 1;
        until not DemandOverview.Next();

        DemandOverview.First();
        exit(RowsCount);
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateItem(var Item: Record Item; ReorderingPolicy: Enum "Reordering Policy")
    begin
        // Creates a new item. Wrapper for the library method.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Modify(true);
    end;

    local procedure CreateLocation(): Code[10]
    var
        Location: Record Location;
    begin
        // Creates a new Location. Wrapper for the library method.
        LibraryWarehouse.CreateLocation(Location);
        exit(Location.Code);
    end;

    local procedure CreatePurchaseSupplyBasis(ItemNo: Code[20]; Quantity: Integer; LocationCode: Code[10]; VariantCode: Code[10]; ReceiptDate: Date): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Creates a Purchase order for the given item.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate(Quantity, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Variant Code", VariantCode);
        PurchaseLine.Validate("Expected Receipt Date", ReceiptDate);
        PurchaseLine.Modify();
        exit(PurchaseHeader."No.");
    end;

    local procedure CreatePurchaseSupply(ItemNo: Code[20]; ItemQuantity: Integer): Code[20]
    begin
        // Creates a Purchase order for the given item.
        exit(CreatePurchaseSupplyBasis(ItemNo, ItemQuantity, '', '', WorkDate()));
    end;

    local procedure CreatePurchaseSupplyAtLocation(ItemNo: Code[20]; ItemQuantity: Integer; LocationCode: Code[10]): Code[20]
    begin
        // Creates a Purchase order for the given item at the specified location.
        exit(CreatePurchaseSupplyBasis(ItemNo, ItemQuantity, LocationCode, '', WorkDate()));
    end;

    local procedure CreatePurchaseSupplyForVariant(ItemNo: Code[20]; ItemQuantity: Integer; VariantNo: Integer): Code[20]
    begin
        // Creates a Purchase order for the given item.
        exit(CreatePurchaseSupplyBasis(ItemNo, ItemQuantity, '', GetVariant(ItemNo, VariantNo), WorkDate()));
    end;

    local procedure CreatePurchaseSupplyAfter(ItemNo: Code[20]; Quantity: Integer; ReceiptDate: Date): Code[20]
    begin
        // Creates a Purchase order for the given item After a source document date.
        exit(CreatePurchaseSupplyBasis(ItemNo, Quantity, '', '', CalcDate('<+1D>', ReceiptDate)));
    end;

    local procedure CreateServiceDemandBasis(ItemNo: Code[20]; ItemQty: Decimal; LocationCode: Code[10]; VariantCode: Code[10]; NeededBy: Date): Code[20]
    var
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        FindServiceItem(ServiceItem);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        ServiceHeader.Validate("Bill-to Name", DescriptionText);
        ServiceHeader.Modify();

        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        ServiceItemLine.Validate("Line No.", 10000);
        ServiceItemLine.Modify();

        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        ServiceLine.SetHideReplacementDialog(true);
        ServiceLine.Validate(Quantity, ItemQty);
        ServiceLine.Validate("Location Code", LocationCode);
        ServiceLine.Validate("Variant Code", VariantCode);
        ServiceLine.Validate("Needed by Date", NeededBy);
        ServiceLine.Validate("Variant Code", VariantCode);
        ServiceLine.Modify();

        exit(ServiceHeader."No.");
    end;

    local procedure CreateServiceDemand(ItemNo: Code[20]; Quantity: Decimal): Code[20]
    begin
        exit(CreateServiceDemandBasis(ItemNo, Quantity, '', '', WorkDate()));
    end;

    local procedure CreateServiceDemandForVariant(ItemNo: Code[20]; Quantity: Integer; VariantNo: Integer): Code[20]
    begin
        exit(CreateServiceDemandBasis(ItemNo, Quantity, '', GetVariant(ItemNo, VariantNo), WorkDate()));
    end;

    local procedure CreateServiceDemandAtLocation(ItemNo: Code[20]; Quantity: Integer; LocationCode: Code[10]): Code[20]
    begin
        exit(CreateServiceDemandBasis(ItemNo, Quantity, LocationCode, '', WorkDate()));
    end;

    local procedure CreateJobDemandAtBasis(ItemNo: Code[20]; ItemQuantity: Decimal; LocationCode: Code[10]; VariantCode: Code[10]; PlanDate: Date): Code[20]
    var
        Job: Record Job;
        JobTaskLine: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        DocumentNo: Code[20];
    begin
        LibraryJob.CreateJob(Job);
        Job.Validate("Apply Usage Link", true);
        Job.Validate("Description 2", DescriptionText);
        Job.Modify();

        // Job Task Line:
        LibraryJob.CreateJobTask(Job, JobTaskLine);
        JobTaskLine.Modify();

        // Job Planning Line:
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget,
          JobPlanningLine.Type::Item, JobTaskLine, JobPlanningLine);

        JobPlanningLine.Validate("Planning Date", PlanDate);
        JobPlanningLine.Validate("Usage Link", true);

        DocumentNo := DelChr(Format(Today), '=', '-/') + '_' + DelChr(Format(Time), '=', ':');
        JobPlanningLine.Validate("Document No.", DocumentNo);
        JobPlanningLine.Validate("No.", ItemNo);
        JobPlanningLine.Validate("Location Code", LocationCode);
        JobPlanningLine.Validate("Variant Code", VariantCode);
        JobPlanningLine.Validate(Quantity, ItemQuantity);
        JobPlanningLine.Modify();

        exit(Job."No.");
    end;

    local procedure CreateJobDemand(ItemNo: Code[20]; ItemQuantity: Decimal): Code[20]
    begin
        exit(CreateJobDemandAtBasis(ItemNo, ItemQuantity, '', '', WorkDate()));
    end;

    local procedure CreateJobDemandAtLocation(ItemNo: Code[20]; ItemQuantity: Integer; LocationCode: Code[10]): Code[20]
    begin
        exit(CreateJobDemandAtBasis(ItemNo, ItemQuantity, LocationCode, '', WorkDate()));
    end;

    local procedure CreateJobDemandForVariant(ItemNo: Code[20]; ItemQuantity: Integer; VariantNo: Integer): Code[20]
    begin
        exit(CreateJobDemandAtBasis(ItemNo, ItemQuantity, '', GetVariant(ItemNo, VariantNo), WorkDate()));
    end;

    local procedure CreateItemWithVariants(var Item: Record Item)
    var
        ItemVariantA: Record "Item Variant";
        ItemVariantB: Record "Item Variant";
    begin
        // Creates a new item with a variant.
        CreateItem(Item, Item."Reordering Policy"::" ");
        LibraryInventory.CreateItemVariant(ItemVariantA, Item."No.");
        ItemVariantA.Validate(Description, Item.Description);
        ItemVariantA.Modify();
        LibraryInventory.CreateItemVariant(ItemVariantB, Item."No.");
        ItemVariantB.Validate(Description, Item.Description);
        ItemVariantB.Modify();
    end;

    local procedure CreateSalesDemandBasis(ItemNo: Code[20]; Quantity: Integer; LocationCode: Code[10]; VariantCode: Code[10]; ShipDate: Date): Code[20]
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
    begin
        // Creates a sales order for the given item.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Shipment Date", ShipDate);
        SalesLine.Validate("Variant Code", VariantCode);
        SalesLine.Modify();
        exit(SalesHeader."No.");
    end;

    local procedure CreateSalesDemand(ItemNo: Code[20]; ItemQuantity: Integer): Code[20]
    begin
        // Creates a sales order for the given item.
        exit(CreateSalesDemandBasis(ItemNo, ItemQuantity, '', '', WorkDate()));
    end;

    local procedure CreateSalesDemandAfter(ItemNo: Code[20]; Quantity: Integer; ShipDate: Date): Code[20]
    begin
        // Creates sales order after a source document date.
        exit(CreateSalesDemandBasis(ItemNo, Quantity, '', '', CalcDate('<+1D>', ShipDate)));
    end;

    local procedure CreateSalesDemandAtLocation(ItemNo: Code[20]; Quantity: Integer; LocationCode: Code[10]): Code[20]
    begin
        // Creates sales order for a specific item at a specified date.
        exit(CreateSalesDemandBasis(ItemNo, Quantity, LocationCode, '', WorkDate()));
    end;

    local procedure CreateSalesDemandForVariant(ItemNo: Code[20]; Quantity: Integer; VariantNo: Integer): Code[20]
    begin
        // Creates sales order for a specific item at a specified date.
        exit(CreateSalesDemandBasis(ItemNo, Quantity, '', GetVariant(ItemNo, VariantNo), WorkDate()));
    end;

    local procedure CreateTransferOrder(var TransferLine: Record "Transfer Line"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        TransferHeader: Record "Transfer Header";
        InTransitLocation: Record Location;
    begin
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        LibraryInventory.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, InTransitLocation.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
    end;

    local procedure FilterRequisitionLine(var RequisitionLine: Record "Requisition Line"; No: Code[20])
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", No);
        RequisitionLine.FindSet();
    end;

    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; Status: Enum "Production Order Status"; ProdOrderNo: Code[20])
    begin
        ProdOrderLine.SetRange(Status, Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.FindFirst();
    end;

    local procedure FindServiceItem(var ServiceItem: Record "Service Item")
    var
        Item: Record Item;
        Customer: Record Customer;
    begin
        Clear(ServiceItem);
        if ServiceItem.FindFirst() then
            repeat
                Customer.Get(ServiceItem."Customer No.");
                Item.Get(ServiceItem."Item No.");
                if (Customer.Blocked = Customer.Blocked::" ") and not Item.Blocked then
                    exit;
            until ServiceItem.Next() = 0;
        Error(NoDataForExecutionError);
    end;

    local procedure FindServiceLine(var ServiceLine: Record "Service Line"; DocumentType: Enum "Service Document Type"; DocumentNo: Code[20])
    begin
        ServiceLine.SetRange("Document Type", DocumentType);
        ServiceLine.SetRange("Document No.", DocumentNo);
        ServiceLine.FindFirst();
    end;

    local procedure GetReceiptDate(PurchaseHeaderNo: Code[20]): Date
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Method returns the expected receipt date from a purchase order.
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", PurchaseHeaderNo);
        PurchaseLine.FindFirst();
        if PurchaseLine.Count > 0 then
            exit(PurchaseLine."Expected Receipt Date");
        Error(ReceiptDateDocumentError, PurchaseHeaderNo);
    end;

    local procedure GetShipmentDate(SalesHeaderNo: Code[20]): Date
    var
        SalesLine: Record "Sales Line";
    begin
        // Method returns the shipment date from a sales order.
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesHeaderNo);
        SalesLine.FindFirst();
        if SalesLine.Count > 0 then
            exit(SalesLine."Shipment Date");
        Error(ShipmentDateDocumentError, SalesHeaderNo);
    end;

    local procedure GetVariant(ItemNo: Code[20]; VarNo: Integer): Code[10]
    var
        ItemVariant: Record "Item Variant";
    begin
        ItemVariant.SetRange("Item No.", ItemNo);
        ItemVariant.Find('-');
        if VarNo > 1 then
            ItemVariant.Next(VarNo - 1);
        exit(ItemVariant.Code);
    end;

    local procedure OpenFirstServiceLines(ServiceLinesToReturn: TestPage "Service Lines"; ServiceOrderNo: Code[20])
    var
        ServiceHeader: Record "Service Header";
        ServiceLineToSelect: Record "Service Line";
    begin
        ServiceHeader.Get(ServiceHeader."Document Type"::Order, ServiceOrderNo);
        ServiceLinesToReturn.OpenEdit();

        FindServiceLine(ServiceLineToSelect, ServiceLineToSelect."Document Type"::Order, ServiceOrderNo);

        ServiceLinesToReturn.First();
        ServiceLinesToReturn.FILTER.SetFilter("Document Type", 'Order');
        ServiceLinesToReturn.FILTER.SetFilter("Document No.", ServiceOrderNo);
        ServiceLinesToReturn.FILTER.SetFilter("Line No.", Format(ServiceLineToSelect."Line No."));
        ServiceLinesToReturn.First();
    end;

    local procedure SetItemOnlyFilter(DemandOverview: TestPage "Demand Overview"; ItemNo: Code[20])
    begin
        ClearDemandTypeAndNoFilter(DemandOverview);
        DemandOverview.ItemFilter.Value(ItemNo);
    end;

    local procedure SetDateFilters(DemandOverview: TestPage "Demand Overview"; StartDateBias: Integer; EndDateBias: Integer; NoDateBias: Integer)
    var
        StartDate: Date;
        EndDate: Date;
    begin
        if StartDateBias <> NoDateBias then begin
            StartDate := AddBiasToWorkDate(StartDateBias);
            DemandOverview.StartDate.Value(Format(StartDate));
        end else
            DemandOverview.StartDate.Value('');

        if EndDateBias <> NoDateBias then begin
            EndDate := AddBiasToWorkDate(EndDateBias);
            DemandOverview.EndDate.Value(Format(EndDate));
        end else
            DemandOverview.EndDate.Value('');
    end;

    local procedure SetAndVerifyDateFilters(DemandOverview: TestPage "Demand Overview"; ItemNo: Code[20]; StartDateBias: Integer; EndDateBias: Integer; NoDateBias: Integer; ExpectedRowsCount: Integer)
    begin
        SetItemOnlyFilter(DemandOverview, ItemNo);
        SetDateFilters(DemandOverview, StartDateBias, EndDateBias, NoDateBias);
        DemandOverview.Calculate.Invoke();

        VerifyOveriewGridForDates(DemandOverview, StartDateBias, EndDateBias, NoDateBias, ExpectedRowsCount);
    end;

    local procedure VerifyOveriewGridForDates(DemandOverview: TestPage "Demand Overview"; StartDateBias: Integer; EndDateBias: Integer; NoDateBias: Integer; ExpectedRowsCount: Integer)
    var
        StartDate: Date;
        EndDate: Date;
        RowDate: Date;
        ActualRowCount: Integer;
    begin
        // Method verifies that all date listed in the grid are with in the date interval
        // Method verifes the actual count of rows matched the expected rows count
        ActualRowCount := 0;

        if StartDateBias <> NoDateBias then
            StartDate := AddBiasToWorkDate(StartDateBias);
        if EndDateBias <> NoDateBias then
            EndDate := AddBiasToWorkDate(EndDateBias);
        DemandOverview.First();

        if DemandOverview."Item No.".Value <> '' then
            repeat
                if not DemandOverview.IsExpanded then
                    DemandOverview.Expand(true);
                ActualRowCount := ActualRowCount + 1;
                if DemandOverview.Date.Value <> '' then begin
                    Evaluate(RowDate, DemandOverview.Date.Value);
                    if StartDateBias <> NoDateBias then
                        Assert.IsTrue(StartDate <= RowDate, 'Start Date Should be lesser than or equal to row date');
                    if EndDateBias <> NoDateBias then
                        Assert.IsTrue(EndDate >= RowDate, 'End Date Should be Greater than or equal to row date');
                end;
            until not DemandOverview.Next();

        Assert.AreEqual(ExpectedRowsCount, ActualRowCount, 'No. of expected rows match');
    end;

    local procedure VerifyOverviewLineQuantities(DemandOverview: TestPage "Demand Overview"; DemandLineType: Text[30]; ExpectedRowsCount: Integer; ExpectedQuantitySum: Integer)
    var
        ActualRowsCount: Integer;
        QuantitySum: Integer;
    begin
        DemandOverview.First();
        repeat
            if not DemandOverview.IsExpanded then
                DemandOverview.Expand(true);
            if Format(DemandOverview.SourceTypeText.Value) = DemandLineType then begin
                ActualRowsCount := ActualRowsCount + 1;
                if DemandOverview.QuantityText.Value <> '' then
                    QuantitySum := QuantitySum + DemandOverview.QuantityText.AsInteger();
            end;
        until not DemandOverview.Next();

        Assert.AreEqual(ExpectedRowsCount, ActualRowsCount, 'No. of rows match');
        Assert.AreEqual(ExpectedQuantitySum, QuantitySum, 'Sum of line Quantities matches');
    end;

    local procedure VerifyRequisitionLine(No: Code[20]; Quantity: Decimal)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        FilterRequisitionLine(RequisitionLine, No);
        Assert.AreEqual(2, RequisitionLine.Count, StrSubstNo(LineCountError, RequisitionLine.TableCaption(), 2));
        repeat
            RequisitionLine.TestField("Action Message", RequisitionLine."Action Message"::New);
            RequisitionLine.TestField("Due Date", WorkDate());
            RequisitionLine.TestField(Quantity, Quantity);
            RequisitionLine.TestField("Location Code", '');
        until RequisitionLine.Next() = 0;
    end;

    local procedure VerifyReservationLine(Reservation: TestPage Reservation; SummaryType: Text[80])
    begin
        Reservation."Summary Type".AssertEquals(SummaryType);
        Reservation."Total Quantity".AssertEquals(OriginalQuantity);
        Reservation.TotalReservedQuantity.AssertEquals(OriginalQuantity);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPageHandler(var Reservation: TestPage Reservation)
    var
        ServiceLine: Record "Service Line";
        JobPlanningLine: Record "Job Planning Line";
        SummaryType: Text[80];
    begin
        // Verify Item No., Service Line, Job Planning Line and Current Reserved Quantity on Reservation Page.
        Reservation.ItemNo.AssertEquals(ItemNo);
        Reservation.First();
        SummaryType := CopyStr(StrSubstNo('%1', ServiceLine.TableCaption()), 1, MaxStrLen(SummaryType));
        VerifyReservationLine(Reservation, SummaryType);
        Reservation.Next();
        SummaryType := CopyStr(StrSubstNo('%1, %2', JobPlanningLine.TableCaption(), JobPlanningLine.Status), 1, MaxStrLen(SummaryType));
        VerifyReservationLine(Reservation, SummaryType);
        Reservation.FILTER.SetFilter("Current Reserved Quantity", Format(-OriginalQuantity));
        Reservation.First();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationActionsPageHandler(var Reservation: TestPage Reservation)
    begin
        // Verify Reserved Quantity on Available Job Planning Lines Page and on Reservation Entries Page.
        Reservation."Total Quantity".DrillDown();
        Reservation.TotalReservedQuantity.DrillDown();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPageHandlerAvailableToReserve(var Reservation: TestPage Reservation)
    begin
        Reservation.AvailableToReserve.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableAssemblyHeadersPageHandler(var AvailableAssemblyHeaders: TestPage "Available - Assembly Headers")
    begin
        AvailableAssemblyHeaders.Reserve.Invoke();
        AvailableAssemblyHeaders."Reserved Qty. (Base)".AssertEquals(OriginalQuantity);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableJobPlanningLinesPageHandler(var AvailableJobPlanningLines: TestPage "Available - Job Planning Lines")
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        // Verify Status, Reserved Quantity and "Remaining Qty. (Base)" on Available Job Planning Lines Page.
        AvailableJobPlanningLines.Status.AssertEquals(JobPlanningLine.Status::Order);
        AvailableJobPlanningLines."Reserved Quantity".AssertEquals(OriginalQuantity);
        AvailableJobPlanningLines."Remaining Qty. (Base)".AssertEquals(OriginalQuantity);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableJobPlanningLinesDrillDownPageHandler(var AvailableJobPlanningLines: TestPage "Available - Job Planning Lines")
    begin
        AvailableJobPlanningLines.ReservedQuantity.DrillDown();  // Current Reserved Quantity
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableJobPlanningLinesCancelReservationPageHandler(var AvailableJobPlanningLines: TestPage "Available - Job Planning Lines")
    begin
        AvailableJobPlanningLines.CancelReservation.Invoke();
        AvailableJobPlanningLines."Reserved Quantity".AssertEquals(0);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableJobPlanningLinesReservePageHandler(var AvailableJobPlanningLines: TestPage "Available - Job Planning Lines")
    begin
        AvailableJobPlanningLines.Reserve.Invoke();
        AvailableJobPlanningLines."Reserved Quantity".AssertEquals(OriginalQuantity);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableServiceLinesPageHandler(var AvailableServiceLines: TestPage "Available - Service Lines")
    begin
        // Verify Reserved Quantity and "Remaining Qty. (Base)" on Available Service Lines Page.
        AvailableServiceLines."Reserved Qty. (Base)".AssertEquals(OriginalQuantity);
        AvailableServiceLines."Outstanding Qty. (Base)".AssertEquals(OriginalQuantity);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableServiceLinesDrillDownPageHandler(var AvailableServiceLines: TestPage "Available - Service Lines")
    begin
        AvailableServiceLines.ReservedQuantity.DrillDown();  // Current Reserved Quantity
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableServiceLinesCancelReservationPageHandler(var AvailableServiceLines: TestPage "Available - Service Lines")
    begin
        AvailableServiceLines.CancelReservation.Invoke();
        AvailableServiceLines."Reserved Qty. (Base)".AssertEquals(0);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableServiceLinesReservePageHandler(var AvailableServiceLines: TestPage "Available - Service Lines")
    begin
        AvailableServiceLines.Reserve.Invoke();
        AvailableServiceLines."Reserved Qty. (Base)".AssertEquals(OriginalQuantity);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailablePurchaseLinesPageHandler(var AvailablePurchaseLines: TestPage "Available - Purchase Lines")
    begin
        AvailablePurchaseLines.Reserve.Invoke();
        AvailablePurchaseLines."Reserved Qty. (Base)".AssertEquals(OriginalQuantity);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableSalesLinesPageHandler(var AvailableSalesLines: TestPage "Available - Sales Lines")
    begin
        AvailableSalesLines.Reserve.Invoke();
        AvailableSalesLines."Reserved Qty. (Base)".AssertEquals(OriginalQuantity);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableTransferLinesPageHandler(var AvailableTransferLines: TestPage "Available - Transfer Lines")
    begin
        AvailableTransferLines.Reserve.Invoke();
        AvailableTransferLines."Reserved Qty. Inbnd. (Base)".AssertEquals(OriginalQuantity);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableProdOrderLinesPageHandler(var AvailableProdOrderLines: TestPage "Available - Prod. Order Lines")
    begin
        AvailableProdOrderLines.Reserve.Invoke();
        AvailableProdOrderLines."Reserved Qty. (Base)".AssertEquals(OriginalQuantity);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationEntriesPageHandler(var ReservationEntries: TestPage "Reservation Entries")
    begin
        // Verify "Quantity (Base)" on Reservation Entries Page.
        ReservationEntries."Quantity (Base)".AssertEquals(-OriginalQuantity);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmTrueHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Options: Text; var Choice: Integer; Instruction: Text)
    begin
        Choice := 2;
    end;
}

