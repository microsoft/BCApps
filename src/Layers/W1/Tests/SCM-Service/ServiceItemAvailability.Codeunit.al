// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Assembly.Document;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Setup;
using Microsoft.Service.Document;
using Microsoft.Service.Item;
using System.Environment.Configuration;
using System.TestLibraries.Utilities;

codeunit 136137 "Service Item Availability"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item Availability] [Service]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryJob: Codeunit "Library - Job";
        LibraryService: Codeunit "Library - Service";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        ServiceLines: TestPage "Service Lines";
        SupplyQuantity: Integer;
        DemandQuantity: Integer;
        IsInitialized: Boolean;
        DescriptionText: Label 'NTF_TEST_NTF_TEST';
        NoDataForExecutionError: Label 'No service item has a non-blocked customer and non-blocked item. Execution stops.';
        ItemNoNotFound: Label 'ItemNo not found.';
        RangeErrorMessage: Label 'RangeMin should be always greater than RangeMax.';
        QtyOnAsmComponentErr: Label 'Qty. on Asm. Component is not correct.';
        PeriodStartErrorMsg: Label 'Period Start date does not match';
        SuggestedProjectedInventoryErr: Label 'Wrong Suggested Projected Inventory Value';

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Item Availability");
        LibraryVariableStorage.Clear();
        // Clear the needed globals
        ClearGlobals();

        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Item Availability");

        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Item Availability");
    end;

    [Test]
    [HandlerFunctions('SendAvailabilityNotificationHandler,NotificationDetailsHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure ChangeLocationRefresh()
    var
        Item: Record Item;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        ItemCard: TestPage "Item Card";
        ItemAvailabilityByLocation: TestPage "Item Availability by Location";
        FoundFirstLocation: Boolean;
        FoundSecondLocation: Boolean;
        ServiceOrderNo: Code[20];
        SecondLocationName: Code[10];
        FirstLocationName: Code[10];
    begin
        // Test case: If supply and demand are calculated and the order is afterwards modified without closing the item availability
        // overview, the overview of availability should be updated when recalculating.

        // Initialize all variables
        Initialize();
        SupplyQuantity := RANDOMRANGE(2, 10);
        DemandQuantity := SupplyQuantity - 1;
        CreateItem(Item);
        FirstLocationName := CreateLocation();
        SecondLocationName := CreateLocation();

        // SETUP: Create supply and demand
        CreatePurchaseSupplyAtLocation(Item."No.", SupplyQuantity, FirstLocationName);
        ServiceOrderNo := CreateServiceDemandAtLocation(Item."No.", DemandQuantity, FirstLocationName);
        EditServiceLinesLocation(ServiceOrderNo, SecondLocationName);

        // EXECUTE: Open Item Availability by Location
        ItemCard.OpenView();
        MoveItemCardtoItemNo(ItemCard, Item);
        ItemAvailabilityByLocation.Trap();
        ItemCard.Location.Invoke();

        // VERIFY: The locations have the right supply and demand numbers
        FoundFirstLocation := false;
        FoundSecondLocation := false;
        repeat
            if ItemAvailabilityByLocation.ItemAvailLocLines.LocationCode.Value = FirstLocationName then begin
                AssertLocationDemandQuantities(0, SupplyQuantity, SupplyQuantity, ItemAvailabilityByLocation);
                FoundFirstLocation := true;
            end;
            if ItemAvailabilityByLocation.ItemAvailLocLines.LocationCode.Value = SecondLocationName then begin
                AssertLocationDemandQuantities(DemandQuantity, 0, -DemandQuantity, ItemAvailabilityByLocation);
                FoundSecondLocation := true;
            end;
        until not ItemAvailabilityByLocation.ItemAvailLocLines.Next();

        Assert.AreEqual(true, FoundSecondLocation, StrSubstNo('Verify that location %1 is found in the grid.', SecondLocationName));
        Assert.AreEqual(true, FoundFirstLocation, StrSubstNo('Verify that location %1 is found in the grid.', FirstLocationName));
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvailByLocBasicSupplyDemand()
    var
        Item: Record Item;
        ItemAvailabilityByLocation: TestPage "Item Availability by Location";
        ItemCard: TestPage "Item Card";
        FirstLocationName: Code[10];
        FoundLocationCount: Integer;
    begin
        // All initializations go here
        Initialize();
        SupplyQuantity := LibraryRandom.RandInt(10);
        DemandQuantity := SupplyQuantity;
        CreateItem(Item);
        FirstLocationName := CreateLocation();

        // SETUP: Create supply and demand to the location
        CreatePurchaseSupplyAtLocation(Item."No.", SupplyQuantity, FirstLocationName);
        CreateJobDemand(Item."No.", SupplyQuantity, FirstLocationName);

        // EXECUTE: Open the item availability by location
        ItemCard.OpenView();
        MoveItemCardtoItemNo(ItemCard, Item);

        ItemAvailabilityByLocation.Trap();
        ItemCard.Location.Invoke();

        // VERIFY: The demand is reflected in the Item availability by location overview:
        // VERIFY: There should be exactly one line with the correct values of:
        // VERIFY: 1) requirement, 2) receipt and 3) projected balance
        FoundLocationCount := 0;
        repeat
            if ItemAvailabilityByLocation.ItemAvailLocLines.LocationCode.Value = FirstLocationName then begin
                AssertLocationDemandQuantities(DemandQuantity, SupplyQuantity, DemandQuantity - SupplyQuantity,
                  ItemAvailabilityByLocation);
                FoundLocationCount := FoundLocationCount + 1;
            end;
        until not ItemAvailabilityByLocation.ItemAvailLocLines.Next();

        Assert.AreEqual(1, FoundLocationCount, 'Number of lines with supply and demand for the test location');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandFromJobsAndService()
    var
        Item: Record Item;
        StockKeepingCard: TestPage "Stockkeeping Unit Card";
        ItemNo: Code[20];
        FirstLocationName: Code[10];
        FirstJobQuantity: Integer;
        SecondJobQuantity: Integer;
        FirstServiceQuantity: Integer;
        SecondServiceQuantity: Integer;
    begin
        // Test Demand from Jobs and Service show up in Stockkeeping Unit Cards.
        // All initializations go here
        Initialize();

        CreateItem(Item);
        FirstLocationName := CreateLocation();
        FirstJobQuantity := -LibraryRandom.RandInt(10);
        SecondJobQuantity := LibraryRandom.RandInt(30);
        FirstServiceQuantity := LibraryRandom.RandInt(40);
        SecondServiceQuantity := LibraryRandom.RandInt(100);
        ItemNo := Item."No.";

        // SETUP: Create Job Demand for Item X, Quantity Q1 (Negative).
        // SETUP: Create Job Demand for Item X, Quantity Q2.
        // SETUP: Create Service Demand for Item X, Quantity Q3.
        // SETUP: Create Service Demand for Item X, Quantity Q4.
        // SETUP: Create new Stockkeeping Unit for Item X
        CreateJobDemand(Item."No.", FirstJobQuantity, FirstLocationName);
        CreateJobDemand(Item."No.", SecondJobQuantity, FirstLocationName);
        CreateServiceDemandAtLocation(Item."No.", FirstServiceQuantity, FirstLocationName);
        CreateServiceDemandAtLocation(Item."No.", SecondServiceQuantity, FirstLocationName);
        CreateStockkeepingUnit(ItemNo, FirstLocationName);

        // EXECUTE: Verify the demand is available on the sku page
        StockKeepingCard.OpenEdit();
        StockKeepingCard.FILTER.SetFilter("Item No.", ItemNo);
        StockKeepingCard.First();

        // VERIFY: Quantity from Job and Service Demand on Stockkeeping Unit Card Q1+Q2 and Q3+Q4
        Assert.AreEqual(
          ItemNo, StockKeepingCard."Item No.".Value, 'Itemno was found');
        Assert.AreEqual(
          FirstJobQuantity + SecondJobQuantity, StockKeepingCard."Qty. on Job Order".AsInteger(),
          'Quantity on Demands from Jobs is not correct');
        Assert.AreEqual(
          FirstServiceQuantity + SecondServiceQuantity, StockKeepingCard."Qty. on Service Order".AsInteger(),
          'Quantity on Demands from Service is not correct');

        // CLEANUP: Close the sku page
        StockKeepingCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvailByPeriodBasicSupplyDemand()
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
        ItemAvailabilityByPeriod: TestPage "Item Availability by Periods";
    begin
        // All initializations go here
        Initialize();
        SupplyQuantity := LibraryRandom.RandInt(12) + 6;
        DemandQuantity := SupplyQuantity - 5;

        // SETUP: Create supply and demand on the workdate of the system.
        CreateItem(Item);
        CreatePurchaseSupply(Item."No.", SupplyQuantity);
        CreateServiceDemand(Item."No.", DemandQuantity);

        // EXECUTE: Open the Item Availability By Period page.
        ItemCard.OpenView();
        MoveItemCardtoItemNo(ItemCard, Item);
        ItemAvailabilityByPeriod.Trap();
        ItemCard.Period.Invoke();
        SetDemandByPeriodFilters(ItemAvailabilityByPeriod, Item."No.", WorkDate());

        // VERIFY: The quantities in demand by period grid columns for the demand date
        // VERIFY: Gross Requirement, Scheduled Receipt and Projected Available Balance are correct.
        AssertDemandByPeriodQuantities(DemandQuantity, SupplyQuantity, SupplyQuantity - DemandQuantity, ItemAvailabilityByPeriod);
        ItemAvailabilityByPeriod.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvailByPeriodChangeNeededDate()
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
        ItemAvailabilityByPeriod: TestPage "Item Availability by Periods";
        ServiceOrderNo: Code[20];
        NeededByDate: Date;
    begin
        // All initializations go here
        Initialize();
        SupplyQuantity := RANDOMRANGE(2, 12);
        DemandQuantity := LibraryRandom.RandInt(SupplyQuantity - 1);

        // SETUP: Create supply and demand on the Workdate of the system.
        // SETUP: Modify the Needed By Date of the demand (service order).
        CreateItem(Item);
        CreatePurchaseSupply(Item."No.", SupplyQuantity);
        ServiceOrderNo := CreateServiceDemand(Item."No.", DemandQuantity);

        // EXECUTE: Open the Item Availability By Period page.
        NeededByDate := CalcDate('<+1D>', WorkDate());
        EditServiceLinesNeededDate(ServiceOrderNo, NeededByDate);

        ItemCard.OpenView();
        MoveItemCardtoItemNo(ItemCard, Item);
        ItemAvailabilityByPeriod.Trap();
        ItemCard.Period.Invoke();

        // VERIFY: The quantities in demand by period grid columns for demand date and work date
        // VERIFY: Gross Requirement, Scheduled Receipt and Projected Available Balance are correct.
        SetDemandByPeriodFilters(ItemAvailabilityByPeriod, Item."No.", WorkDate());
        AssertDemandByPeriodQuantities(0, SupplyQuantity, SupplyQuantity, ItemAvailabilityByPeriod);
        SetDemandByPeriodFilters(ItemAvailabilityByPeriod, Item."No.", NeededByDate);
        AssertDemandByPeriodQuantities(DemandQuantity, 0, SupplyQuantity - DemandQuantity, ItemAvailabilityByPeriod);
        ItemAvailabilityByPeriod.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvailByVarianBasicSupplyDemand()
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
        ItemAvailabilityByVariant: TestPage "Item Availability by Variant";
        DemandVariantCode: Code[10];
        FoundVariantCount: Integer;
    begin
        // All initializations go here
        Initialize();
        SupplyQuantity := RANDOMRANGE(2, 12);
        DemandQuantity := LibraryRandom.RandInt(SupplyQuantity - 1);

        // SETUP: Create supply and demand on the workdate of the system.
        CreateItemWithVariants(Item);
        DemandVariantCode := GetVariant(Item."No.", 1);
        CreatePurchaseSupplyVariant(Item."No.", SupplyQuantity, DemandVariantCode);
        CreateJobDemandVariant(Item."No.", DemandQuantity, DemandVariantCode);

        // EXECUTE: Open the Item Availability By Variant page.
        ItemCard.OpenView();
        MoveItemCardtoItemNo(ItemCard, Item);
        ItemAvailabilityByVariant.Trap();
        ItemCard.Variant.Invoke();

        // VERIFY: The quantities in demand by Variant grid columns
        // VERIFY: Columns: Gross Requirement, Scheduled Receipt and Projected Available Balance are correct.
        FoundVariantCount := 0;
        repeat
            if ItemAvailabilityByVariant.ItemAvailLocLines.Code.Value = DemandVariantCode then begin
                AssertVariantDemandQuantities(DemandQuantity, SupplyQuantity, SupplyQuantity - DemandQuantity, ItemAvailabilityByVariant);
                FoundVariantCount := FoundVariantCount + 1;
            end;
        until not ItemAvailabilityByVariant.ItemAvailLocLines.Next();

        Assert.AreEqual(1, FoundVariantCount, 'Number of lines with supply and demand for the Variant is 1.');
        ItemAvailabilityByVariant.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvailByVariantChangeVariant()
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
        ItemAvailabilityByVariant: TestPage "Item Availability by Variant";
        FirstVariantCode: Code[10];
        SecondVariantCode: Code[10];
        FoundFirstVariant: Boolean;
        FoundSecondVariant: Boolean;
    begin
        // All initializations go here
        Initialize();
        SupplyQuantity := RANDOMRANGE(2, 12);
        DemandQuantity := LibraryRandom.RandInt(SupplyQuantity - 1);

        // SETUP: Create supply and demand on the workdate of the system.
        CreateItemWithVariants(Item);
        FirstVariantCode := GetVariant(Item."No.", 1);
        SecondVariantCode := GetVariant(Item."No.", 2);
        CreatePurchaseSupplyVariant(Item."No.", SupplyQuantity, FirstVariantCode);
        CreateServiceDemandVariant(Item."No.", DemandQuantity, SecondVariantCode);

        // EXECUTE: Open the Item Availability By Variant page.
        ItemCard.OpenView();
        MoveItemCardtoItemNo(ItemCard, Item);
        ItemAvailabilityByVariant.Trap();
        ItemCard.Variant.Invoke();

        // VERIFY: The quantities in demand by Variant grid columns
        // VERIFY: Columns: Gross Requirement, Scheduled Receipt and Projected Available Balance are correct.
        FoundFirstVariant := false;
        FoundSecondVariant := false;
        repeat
            if ItemAvailabilityByVariant.ItemAvailLocLines.Code.Value = FirstVariantCode then begin
                AssertVariantDemandQuantities(0, SupplyQuantity, SupplyQuantity, ItemAvailabilityByVariant);
                FoundFirstVariant := true;
            end;
            if ItemAvailabilityByVariant.ItemAvailLocLines.Code.Value = SecondVariantCode then begin
                AssertVariantDemandQuantities(DemandQuantity, 0, -DemandQuantity, ItemAvailabilityByVariant);
                FoundSecondVariant := true;
            end;
        until not ItemAvailabilityByVariant.ItemAvailLocLines.Next();

        Assert.AreEqual(true, FoundFirstVariant, 'Found first variant');
        Assert.AreEqual(true, FoundSecondVariant, 'Found second variant');
        ItemAvailabilityByVariant.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckQtyOnAsmComponentForStockKeepingUnit()
    var
        ParentItem: Record Item;
        Item: Record Item;
        Location: Record Location;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        StockkeepingUnit: Record "Stockkeeping Unit";
        Quantity: Decimal;
        QuantityPer: Decimal;
        i: Integer;
    begin
        // SETUP: Create a new location for 3 items.
        LibraryWarehouse.CreateLocation(Location);

        for i := 1 to 3 do begin
            LibraryInventory.CreateItem(ParentItem);
            LibraryInventory.CreateItem(Item);

            // SETUP: Create Assembly Order.
            Quantity := LibraryRandom.RandDec(10, 2);
            QuantityPer := LibraryRandom.RandDec(10, 2);
            LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), ParentItem."No.", Location.Code, Quantity, '');
            LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, AssemblyLine.Type::Item, Item."No.", '', Quantity, QuantityPer, '');

            // EXECUTE: Create Stockkeeping Unit.
            CreateStockkeepingUnit(Item."No.", Location.Code);

            // VERIFY: Qty. on Asm. Component field is correct when location contains mutiple different items.
            StockkeepingUnit.SetRange("Item No.", Item."No.");
            StockkeepingUnit.FindFirst();
            StockkeepingUnit.CalcFields("Qty. on Asm. Component");
            Assert.AreEqual(Quantity * QuantityPer, StockkeepingUnit."Qty. on Asm. Component", QtyOnAsmComponentErr);
        end;
    end;

    [Test]
    [HandlerFunctions('ItemAvailByEventHandler')]
    [Scope('OnPrem')]
    procedure AvailByEventChangeNeededDate()
    var
        Item: Record Item;
        ServiceOrderNo: Code[20];
        PostingDate: Date;
        PostingDate1: Date;
        NeededByDate: Date;
    begin
        // All initializations go here
        Initialize();
        SupplyQuantity := RANDOMRANGE(2, 12);
        DemandQuantity := LibraryRandom.RandInt(SupplyQuantity - 1);
        PostingDate := CalcDate('<-1D>', WorkDate());
        PostingDate1 := CalcDate('<-1M>', PostingDate);
        NeededByDate := CalcDate('<+1Y>', PostingDate1);

        // SETUP: Create supply and demand with Purchase Order and Service Order.
        CreateItem(Item);
        CreatePurchaseSupply(Item."No.", SupplyQuantity);
        CreatePurchaseSupplyBasis(Item."No.", SupplyQuantity, '', '', PostingDate);
        CreatePurchaseSupplyBasis(Item."No.", SupplyQuantity, '', '', PostingDate1);
        ServiceOrderNo := CreateServiceDemand(Item."No.", DemandQuantity);
        EditServiceLinesNeededDate(ServiceOrderNo, NeededByDate);

        // Enqueue value for ItemAvailByEventHandler.
        LibraryVariableStorage.Enqueue(PostingDate1);
        LibraryVariableStorage.Enqueue(PostingDate);
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(NeededByDate);

        // EXECUTE: Open the Item Availability By Event page.
        // VERIFY: Verify Data is sorting correct by Date through handler.
        OpenItemAvailByEvent(Item);
    end;

    [Test]
    [HandlerFunctions('CheckBlanketItemAvailByEventHandler')]
    [Scope('OnPrem')]
    procedure AvailByEventBlanketSalesOrder()
    var
        Item: Record Item;
        Customer: Record Customer;
        BlanketSalesHeader: array[2] of Record "Sales Header";
        TotalQty: array[2] of Decimal;
        QtyToShip: array[2] of Decimal;
        ShipmentDate: array[2] of Date;
    begin
        // Verify Item Availability By Event in case of several Blanket Orders
        // with several lines and partial Sales Order from Blankets
        Initialize();
        UpdateSalesReceivablesSetup();
        CreateItem(Item);
        LibrarySales.CreateCustomer(Customer);
        ShipmentDate[1] := WorkDate();
        ShipmentDate[2] := CalcDate('<1M>', ShipmentDate[1]);

        CreateBlanketSalesOrderWith2Lines(BlanketSalesHeader[1], TotalQty[1], QtyToShip[1], Customer."No.", Item."No.", ShipmentDate);
        CreateBlanketSalesOrderWith2Lines(BlanketSalesHeader[2], TotalQty[2], QtyToShip[2], Customer."No.", Item."No.", ShipmentDate);

        LibraryVariableStorage.Enqueue(ShipmentDate[1]);
        LibraryVariableStorage.Enqueue(ShipmentDate[2]);
        LibraryVariableStorage.Enqueue(BlanketSalesHeader[1]."No.");
        LibraryVariableStorage.Enqueue(BlanketSalesHeader[2]."No.");
        LibraryVariableStorage.Enqueue(LibrarySales.BlanketSalesOrderMakeOrder(BlanketSalesHeader[1]));
        LibraryVariableStorage.Enqueue(LibrarySales.BlanketSalesOrderMakeOrder(BlanketSalesHeader[2]));
        LibraryVariableStorage.Enqueue(-TotalQty[1]);
        LibraryVariableStorage.Enqueue(-TotalQty[2]);
        LibraryVariableStorage.Enqueue(-QtyToShip[1]);
        LibraryVariableStorage.Enqueue(-QtyToShip[2]);

        // Verify Item Availability by Event through handler
        OpenItemAvailByEvent(Item);
    end;

    [Test]
    [HandlerFunctions('ItemAvailabilityByEventHandler')]
    [Scope('OnPrem')]
    procedure CheckReservedReceiptOnItemAvailabilityByEventPage()
    var
        Item: Record Item;
        Location: Record Location;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Qty1: Decimal;
        Qty2: Decimal;
    begin
        // [FEATURE] [Item Availability by Event] [Reservation]
        // [SCENARIO 364616] "Item Availability by Event" page should sum all reserved quantity from appropriate Item Ledger Entries when calculating "Reserved Receipt"
        Initialize();

        CreateItem(Item);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibrarySales.CreateCustomer(Customer);
        Qty1 := LibraryRandom.RandDec(10, 2);
        Qty2 := LibraryRandom.RandDec(10, 2);

        // [GIVEN] Two Item Ledger Entries for Item "I" on Location "L": "ILE1" and "ILE2"
        LibraryInventory.PostPositiveAdjustment(Item, Location.Code, '', '', Qty1, WorkDate(), LibraryRandom.RandDec(100, 2));
        LibraryInventory.PostPositiveAdjustment(Item, Location.Code, '', '', Qty2, WorkDate(), LibraryRandom.RandDec(100, 2));

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // [GIVEN] Sales Order Line "S1" with Reserved Quantity = "X" from "ILE1"
        CreateSalesLineWithReservedQuantity(SalesHeader, SalesLine, Location.Code, Item."No.", Qty1);

        // [GIVEN] Sales Order Line "S2" with Reserved Quantity = "Y" from "ILE2"
        CreateSalesLineWithReservedQuantity(SalesHeader, SalesLine, Location.Code, Item."No.", Qty2);

        // [WHEN] Open "Item Availability by Event" Page
        // [THEN] "Reserved Receipt" = "X" + "Y"
        LibraryVariableStorage.Enqueue(Qty1 + Qty2);
        OpenItemAvailByEvent(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckSuggestedProjectedInventory()
    var
        InventoryPageData: Record "Inventory Page Data";
        Dummy: Decimal;
        ExpectedSuggestedProjectedInventory: Decimal;
    begin
        // [SCENARIO 361049] "Suggested Projected Inventory" consider forecast in "Item Availability By Event"
        Initialize();

        // [GIVEN] Inventory Data with "Action Message Qty." = "W", "Remaining Forecast" = "X", "Gross Requirement" - "Y" and "Scheduled Receipt" = "Z"
        CreateInventoryPageData(InventoryPageData);
        ExpectedSuggestedProjectedInventory :=
              InventoryPageData."Action Message Qty." + InventoryPageData."Remaining Forecast" + InventoryPageData."Gross Requirement" + InventoryPageData."Scheduled Receipt";

        // [WHEN] Update Inventory on Inventory Page Data
        Dummy := 0.0;
        InventoryPageData.UpdateInventorys(Dummy, Dummy, Dummy);

        // [THEN] Suggested Projected Inventory = W + X + Y + Z
        Assert.AreEqual(ExpectedSuggestedProjectedInventory, InventoryPageData."Suggested Projected Inventory",
          SuggestedProjectedInventoryErr);
    end;

    [Normal]
    local procedure ClearGlobals()
    begin
        // Clear all global variables
        SupplyQuantity := 0;
        DemandQuantity := 0;
    end;

    local procedure UpdateSalesReceivablesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Stockout Warning", false);
        SalesReceivablesSetup.Modify();
    end;

    [Normal]
    local procedure CreateItem(var Item: Record Item)
    begin
        // Creates a new item. Wrapper for the library method.
        LibraryInventory.CreateItem(Item);
    end;

    [Normal]
    local procedure CreateItemWithVariants(var Item: Record Item)
    var
        ItemVariantA: Record "Item Variant";
        ItemVariantB: Record "Item Variant";
    begin
        // Creates a new item with a variant.
        CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariantA, Item."No.");
        ItemVariantA.Validate(Description, Item.Description);
        ItemVariantA.Modify();
        LibraryInventory.CreateItemVariant(ItemVariantB, Item."No.");
        ItemVariantB.Validate(Description, Item.Description);
        ItemVariantB.Modify();
    end;

    [Normal]
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

    local procedure CreatePurchaseSupplyVariant(ItemNo: Code[20]; Quantity: Integer; VariantCode: Code[10]): Code[20]
    begin
        // Creates a Purchase order for the given item After a source document date.
        exit(CreatePurchaseSupplyBasis(ItemNo, Quantity, '', VariantCode, WorkDate()));
    end;

    local procedure CreateSalesLineWithReservedQuantity(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; LocationCode: Code[10]; ItemNo: Code[20]; Qty: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Qty);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify();
        LibrarySales.AutoReserveSalesLine(SalesLine);
    end;

    local procedure CreateServiceDemandBasis(ItemNo: Code[20]; ItemQty: Integer; LocationCode: Code[10]; VariantCode: Code[10]; NeededBy: Date): Code[20]
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

    local procedure CreateServiceDemand(ItemNo: Code[20]; Quantity: Integer): Code[20]
    begin
        exit(CreateServiceDemandBasis(ItemNo, Quantity, '', '', WorkDate()));
    end;

    local procedure CreateServiceDemandAtLocation(ItemNo: Code[20]; Quantity: Integer; LocationCode: Code[10]): Code[20]
    begin
        exit(CreateServiceDemandBasis(ItemNo, Quantity, LocationCode, '', WorkDate()));
    end;

    local procedure CreateServiceDemandVariant(ItemNo: Code[20]; Quantity: Integer; VariantCode: Code[10]): Code[20]
    begin
        exit(CreateServiceDemandBasis(ItemNo, Quantity, '', VariantCode, WorkDate()));
    end;

    local procedure CreateStockkeepingUnit(ItemNo: Code[20]; LocationCode: Code[10])
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        if StockkeepingUnit.Get(LocationCode, ItemNo, '') then
            exit;

        StockkeepingUnit.Validate("Item No.", ItemNo);
        StockkeepingUnit.Validate("Location Code", LocationCode);
        StockkeepingUnit.Insert(true);
    end;

    local procedure CreateJobDemandAtBasis(ItemNo: Code[20]; ItemQuantity: Integer; LocationCode: Code[10]; VariantCode: Code[10]): Code[20]
    var
        Job: Record Job;
        JobTaskLine: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        DocNo: Code[20];
    begin
        // Create Job
        LibraryJob.CreateJob(Job);
        Job.Validate("Apply Usage Link", true);
        Job.Validate("Description 2", DescriptionText);
        Job.Modify();

        // Job Task Line:
        LibraryJob.CreateJobTask(Job, JobTaskLine);
        JobTaskLine.Modify();

        // Job Planning Line:
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTaskLine, JobPlanningLine);

        JobPlanningLine.Validate("Usage Link", true);
        DocNo := DelChr(Format(Today), '=', '-/') + '_' + DelChr(Format(Time), '=', ':');
        JobPlanningLine.Validate("Document No.", DocNo);
        JobPlanningLine.Validate("No.", ItemNo);
        JobPlanningLine.Validate(Quantity, ItemQuantity);
        JobPlanningLine.Validate("Location Code", LocationCode);
        JobPlanningLine.Validate("Variant Code", VariantCode);
        JobPlanningLine.Modify();

        exit(Job."No.");
    end;

    [Normal]
    local procedure CreateJobDemand(ItemNo: Code[20]; ItemQuantity: Integer; LocationCode: Code[10]): Code[20]
    begin
        exit(CreateJobDemandAtBasis(ItemNo, ItemQuantity, LocationCode, ''));
    end;

    [Normal]
    local procedure CreateJobDemandVariant(ItemNo: Code[20]; ItemQuantity: Integer; VariantCode: Code[10]): Code[20]
    begin
        exit(CreateJobDemandAtBasis(ItemNo, ItemQuantity, '', VariantCode));
    end;

    local procedure CreateBlanketSalesOrderWith2Lines(var SalesHeader: Record "Sales Header"; var TotalQty: Decimal; var QtyToShip: Decimal; CustNo: Code[20]; ItemNo: Code[20]; ShipmentDate: array[2] of Date)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order", CustNo);
        TotalQty := LibraryRandom.RandIntInRange(100, 1000);
        QtyToShip := LibraryRandom.RandInt(TotalQty - 1);
        LibrarySales.CreateSalesLineWithShipmentDate(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, ShipmentDate[1], TotalQty);
        LibrarySales.CreateSalesLineWithShipmentDate(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, ShipmentDate[2], TotalQty);
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Blanket Order");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.ModifyAll("Qty. to Ship", QtyToShip);
    end;

    local procedure CreateInventoryPageData(var InventoryPageData: Record "Inventory Page Data")
    begin
        if InventoryPageData.FindLast() then;

        InventoryPageData."Line No." += 1;
        InventoryPageData."Action Message Qty." := LibraryRandom.RandDec(100, 2);
        InventoryPageData."Remaining Forecast" := LibraryRandom.RandDec(100, 2);
        InventoryPageData."Gross Requirement" := LibraryRandom.RandDec(100, 2);
        InventoryPageData."Scheduled Receipt" := LibraryRandom.RandDec(100, 2);
        InventoryPageData.Insert();
    end;

    [Normal]
    local procedure EditServiceLinesLocation(ServiceOrderNo: Code[20]; LocationB: Code[10])
    var
        ServiceLinesToReturn: TestPage "Service Lines";
    begin
        OpenFirstServiceLines(ServiceLinesToReturn, ServiceOrderNo);
        ServiceLines := ServiceLinesToReturn;
        ServiceLinesToReturn."Location Code".Value(LocationB);
    end;

    [Normal]
    local procedure EditServiceLinesNeededDate(ServiceOrderNo: Code[20]; NeededByDate: Date)
    var
        ServiceLinesToReturn: TestPage "Service Lines";
    begin
        OpenFirstServiceLines(ServiceLinesToReturn, ServiceOrderNo);
        ServiceLines := ServiceLinesToReturn;
        ServiceLinesToReturn."Needed by Date".Value(Format(NeededByDate));
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

    [Normal]
    local procedure MoveItemCardtoItemNo(var ItemCard: TestPage "Item Card"; Item: Record Item)
    begin
        // Method is used to move item card to the desired item number.
        if not ItemCard.GotoRecord(Item) then
            Error(ItemNoNotFound);
    end;

    [Normal]
    local procedure OpenFirstServiceLines(ServiceLinesToReturn: TestPage "Service Lines"; ServiceOrderNo: Code[20])
    var
        ServiceHeader: Record "Service Header";
        ServiceLineToSelect: Record "Service Line";
    begin
        ServiceHeader.Get(ServiceHeader."Document Type"::Order, ServiceOrderNo);
        ServiceLinesToReturn.OpenEdit();

        ServiceLineToSelect.SetRange("Document Type", ServiceLineToSelect."Document Type"::Order);
        ServiceLineToSelect.SetRange("Document No.", ServiceOrderNo);
        ServiceLineToSelect.FindFirst();

        ServiceLinesToReturn.First();
        ServiceLinesToReturn.FILTER.SetFilter("Document Type", 'Order');
        ServiceLinesToReturn.FILTER.SetFilter("Document No.", ServiceOrderNo);
        ServiceLinesToReturn.FILTER.SetFilter("Line No.", Format(ServiceLineToSelect."Line No."));
        ServiceLinesToReturn.First();
    end;

    local procedure OpenItemAvailByEvent(Item: Record Item)
    var
        ItemCard: TestPage "Item Card";
    begin
        Commit();
        ItemCard.OpenView();
        MoveItemCardtoItemNo(ItemCard, Item);
        ItemCard."<Action110>".Invoke(); // <Action110> refers to Item Availability By Event.
    end;

    [Normal]
    local procedure RANDOMRANGE(RangeMin: Integer; RangeMax: Integer): Integer
    var
        RandomNumber: Integer;
    begin
        // Method returns a random value within a range
        if RangeMax <= RangeMin then
            Error(RangeErrorMessage);
        RandomNumber := RangeMin + LibraryRandom.RandInt(RangeMax - RangeMin + 1) - 1;
        exit(RandomNumber);
    end;

    [Normal]
    local procedure SetDemandByPeriodFilters(ItemAvailabilityByPeriod: TestPage "Item Availability by Periods"; ItemNo: Code[20]; FilterDate: Date)
    var
        StartDate: Date;
    begin
        ItemAvailabilityByPeriod.FILTER.SetFilter("No.", ItemNo);
        ItemAvailabilityByPeriod.ItemAvailLines.FILTER.SetFilter("Period Start", Format(FilterDate));
        ItemAvailabilityByPeriod.PeriodType.Value := 'Day';
        ItemAvailabilityByPeriod.ItemAvailLines.First();
        Evaluate(StartDate, ItemAvailabilityByPeriod.ItemAvailLines."Period Start".Value);
        Assert.AreEqual(FilterDate, StartDate, 'SetFilter returned record with correct date');
    end;

    [Normal]
    local procedure AssertDemandByPeriodQuantities(Demand: Integer; Supply: Integer; Forecasted: Integer; var ItemAvailabilityByPeriod: TestPage "Item Availability by Periods")
    begin
        Assert.AreEqual(
          Demand, ItemAvailabilityByPeriod.ItemAvailLines.GrossRequirement.AsInteger(), 'Column Gross Requirement Verified');
        Assert.AreEqual(
          Supply, ItemAvailabilityByPeriod.ItemAvailLines.ScheduledRcpt.AsInteger(), 'Column Scheduled Verified');
        Assert.AreEqual(
          Forecasted, ItemAvailabilityByPeriod.ItemAvailLines.ProjAvailableBalance.AsInteger(), 'Column Projected Available Balance');
    end;

    [Normal]
    local procedure AssertLocationDemandQuantities(Demand: Integer; Supply: Integer; Forecasted: Integer; var ItemAvailabilityByLocation: TestPage "Item Availability by Location")
    begin
        // Quantity assertions for the Item availability by location window
        Assert.AreEqual(
          Demand, ItemAvailabilityByLocation.ItemAvailLocLines.GrossRequirement.AsInteger(), 'Column Gross Requirement Verified');
        Assert.AreEqual(
          Supply, ItemAvailabilityByLocation.ItemAvailLocLines.ScheduledRcpt.AsInteger(), 'Column Scheduled Verified');
        Assert.AreEqual(
          Forecasted, ItemAvailabilityByLocation.ItemAvailLocLines.ProjAvailableBalance.AsInteger(), 'Column Projected Available Balance');
    end;

    [Normal]
    local procedure AssertVariantDemandQuantities(Demand: Integer; Supply: Integer; Forecasted: Integer; ItemAvailabilityByVariant: TestPage "Item Availability by Variant")
    begin
        // Quantity assertions for Item availability by variant window
        Assert.AreEqual(
          Demand, ItemAvailabilityByVariant.ItemAvailLocLines.GrossRequirement.AsInteger(), 'Column Gross Requirement Verified');
        Assert.AreEqual(
          Supply, ItemAvailabilityByVariant.ItemAvailLocLines.ScheduledRcpt.AsInteger(), 'Column Scheduled Verified');
        Assert.AreEqual(
          Forecasted, ItemAvailabilityByVariant.ItemAvailLocLines.ProjAvailableBalance.AsInteger(), 'Column Projected Available Balance');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemAvailByEventHandler(var ItemAvailabilityByEvent: TestPage "Item Availability by Event")
    var
        ExpectedPeriodStartDate: array[4] of Variant;
        i: Integer;
    begin
        for i := 1 to 4 do begin
            LibraryVariableStorage.Dequeue(ExpectedPeriodStartDate[i]);

            // Verify the Data is sorting correctly by date.
            Assert.AreEqual(ExpectedPeriodStartDate[i], ItemAvailabilityByEvent."Period Start".AsDate(), PeriodStartErrorMsg);
            ItemAvailabilityByEvent.Next();
        end;
        ItemAvailabilityByEvent.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemAvailabilityByEventHandler(var ItemAvailabilityByEvent: TestPage "Item Availability by Event")
    var
        Qty: Variant;
    begin
        LibraryVariableStorage.Dequeue(Qty);
        ItemAvailabilityByEvent."Reserved Receipt".AssertEquals(Qty);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CheckBlanketItemAvailByEventHandler(var ItemAvailabilityByEvent: TestPage "Item Availability by Event")
    var
        Value: Variant;
        PeriodStart: array[2] of Variant;
        BlanketOrderDocNo: array[2] of Variant;
        SalesOrderDocNo: array[2] of Variant;
        TotalQty: array[2] of Decimal;
        QtyToShip: array[2] of Decimal;
        QtyToShipBoth: Decimal;
        QtyToShipTotal: Decimal;
    begin
        LibraryVariableStorage.Dequeue(PeriodStart[1]);
        LibraryVariableStorage.Dequeue(PeriodStart[2]);
        LibraryVariableStorage.Dequeue(BlanketOrderDocNo[1]);
        LibraryVariableStorage.Dequeue(BlanketOrderDocNo[2]);
        LibraryVariableStorage.Dequeue(SalesOrderDocNo[1]);
        LibraryVariableStorage.Dequeue(SalesOrderDocNo[2]);
        LibraryVariableStorage.Dequeue(Value);
        Evaluate(TotalQty[1], Format(Value));
        LibraryVariableStorage.Dequeue(Value);
        Evaluate(TotalQty[2], Format(Value));
        LibraryVariableStorage.Dequeue(Value);
        Evaluate(QtyToShip[1], Format(Value));
        LibraryVariableStorage.Dequeue(Value);
        Evaluate(QtyToShip[2], Format(Value));

        QtyToShipBoth := QtyToShip[1] + QtyToShip[2];
        QtyToShipTotal := QtyToShipBoth + QtyToShipBoth;

        ItemAvailabilityByEvent.IncludeBlanketOrders.SetValue(true);
        VerifyInvtPagePeriodData(
          ItemAvailabilityByEvent, PeriodStart[1], BlanketOrderDocNo, SalesOrderDocNo,
          QtyToShipBoth, QtyToShipBoth, TotalQty, QtyToShip, QtyToShip[1]);
        VerifyInvtPagePeriodData(
          ItemAvailabilityByEvent, PeriodStart[2], BlanketOrderDocNo, SalesOrderDocNo,
          QtyToShipBoth, QtyToShipTotal, TotalQty, QtyToShip, QtyToShipBoth + QtyToShip[1]);
        ItemAvailabilityByEvent.OK().Invoke();
    end;

    local procedure VerifyInvtPagePeriodData(var ItemAvailabilityByEvent: TestPage "Item Availability by Event"; PeriodStart: Variant; BlanketOrderDocNo: array[2] of Variant; SalesOrderDocNo: array[2] of Variant; GrossTotal: Decimal; ProjectTotal: Decimal; TotalQty: array[2] of Decimal; QtyToShip: array[2] of Decimal; Projected1: Decimal)
    var
        InventoryPageData: Record "Inventory Page Data";
    begin
        ItemAvailabilityByEvent.Expand(true);
        VerifyInvtPageDataAndStepNext(
          ItemAvailabilityByEvent, PeriodStart, 0, '', GrossTotal, ProjectTotal, TotalQty[1] + TotalQty[2]);
        VerifyInvtPageDataAndStepNext(
          ItemAvailabilityByEvent, PeriodStart, InventoryPageData.Type::Sale, SalesOrderDocNo[1], QtyToShip[1], Projected1, 0);
        VerifyInvtPageDataAndStepNext(
          ItemAvailabilityByEvent, PeriodStart, InventoryPageData.Type::Sale, SalesOrderDocNo[2], QtyToShip[2], ProjectTotal, 0);
        VerifyInvtPageDataAndStepNext(
          ItemAvailabilityByEvent, PeriodStart, InventoryPageData.Type::"Blanket Sales Order",
          BlanketOrderDocNo[1], 0, ProjectTotal, TotalQty[1]);
        VerifyInvtPageDataAndStepNext(
          ItemAvailabilityByEvent, PeriodStart, InventoryPageData.Type::"Blanket Sales Order",
          BlanketOrderDocNo[2], 0, ProjectTotal, TotalQty[2]);
    end;

    local procedure VerifyInvtPageDataAndStepNext(var ItemAvailabilityByEvent: TestPage "Item Availability by Event"; PeriodStart: Variant; Type: Variant; DocumentNo: Variant; Gross: Decimal; Projected: Decimal; Forecast: Decimal)
    begin
        ItemAvailabilityByEvent."Period Start".AssertEquals(PeriodStart);
        ItemAvailabilityByEvent.Type.AssertEquals(Type);
        ItemAvailabilityByEvent."Document No.".AssertEquals(DocumentNo);
        ItemAvailabilityByEvent."Gross Requirement".AssertEquals(Gross);
        ItemAvailabilityByEvent."Projected Inventory".AssertEquals(Projected);
        ItemAvailabilityByEvent.Forecast.AssertEquals(Forecast);
        ItemAvailabilityByEvent.Next();
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendAvailabilityNotificationHandler(var Notification: Notification): Boolean
    var
        Item: Record Item;
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        Quantity: Integer;
        Inventory: Decimal;
        TotalQuantity: Decimal;
        ReservedQty: Decimal;
        SchedRcpt: Decimal;
        ReservedRcpt: Decimal;
        GrossReq: Decimal;
        ReservedReq: Decimal;
    begin
        Item.Get(ServiceLines."No.".Value);
        Assert.AreEqual(Notification.GetData('ItemNo'), Item."No.", 'Item No. was different than expected');
        Item.CalcFields(Inventory);
        Evaluate(Inventory, Notification.GetData('InventoryQty'));
        Assert.AreEqual(Inventory, Item.Inventory, 'Available Inventory was different than expected');
        Evaluate(Quantity, Notification.GetData('CurrentQuantity'));
        Evaluate(TotalQuantity, Notification.GetData('TotalQuantity'));
        Evaluate(ReservedQty, Notification.GetData('CurrentReservedQty'));
        Evaluate(ReservedReq, Notification.GetData('ReservedReq'));
        Evaluate(SchedRcpt, Notification.GetData('SchedRcpt'));
        Evaluate(GrossReq, Notification.GetData('GrossReq'));
        Evaluate(ReservedRcpt, Notification.GetData('ReservedRcpt'));
        Assert.AreEqual(TotalQuantity, Inventory - Quantity + (SchedRcpt - ReservedRcpt) - (GrossReq - ReservedReq),
          'Total quantity different than expected');
        Assert.AreEqual(Format(Quantity), ServiceLines.Quantity.Value, 'Quantity was different than expected');
        Assert.AreEqual(Notification.GetData('UnitOfMeasureCode'), ServiceLines."Unit of Measure Code".Value,
          'Unit of Measure different than expected');
        ItemCheckAvail.ShowNotificationDetails(Notification);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NotificationDetailsHandler(var ItemAvailabilityCheck: TestPage "Item Availability Check")
    var
        Item: Record Item;
    begin
        Item.Get(ServiceLines."No.".Value);
        Item.CalcFields(Inventory);
        ItemAvailabilityCheck.AvailabilityCheckDetails."No.".AssertEquals(Item."No.");
        ItemAvailabilityCheck.AvailabilityCheckDetails.Description.AssertEquals(Item.Description);
        ItemAvailabilityCheck.AvailabilityCheckDetails.CurrentQuantity.AssertEquals(ServiceLines.Quantity.Value);
        ItemAvailabilityCheck.InventoryQty.AssertEquals(Item.Inventory);
    end;
}

