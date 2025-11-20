codeunit 137020 "SCM Planning"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Planning] [SCM]
        IsInitialized := false;
    end;

    var
        LocationSilver: Record Location;
        LocationBlue: Record Location;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        IsInitialized: Boolean;
        RunRegPlanMsg: Label 'you must run a regenerative planning.';
        DaysInMonthFormula: DateFormula;
        PlanningStartDate: DateFormula;
        PlanningEndDate: DateFormula;
        StringsMustBeIdenticalErr: Label 'Strings must be identical.';
        RoutingType: Option Serial,Parallel;
        SalesHeaderMustNotBeFoundErr: Label 'Sales Header must not be found.';

    local procedure GlobalSetup()
    begin
        NoSeriesSetup();

        LocationSetup(LocationSilver, true);
        LocationSetup(LocationBlue, false);

        DisableWarnings();
    end;

    local procedure NoSeriesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        SalesSetup.Validate("Customer Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Modify(true);

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Vendor Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure ItemSetup(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System"; SafetyLeadTime: Text[30])
    begin
        LibraryInventory.CreateItem(Item);

        Item.Validate("Replenishment System", ReplenishmentSystem);
        Evaluate(Item."Safety Lead Time", SafetyLeadTime);

        Item.Modify(true);
    end;

    local procedure LFLItemSetup(var Item: Record Item; IncludeInventory: Boolean; ReschedulingPeriod: Text[30]; LotAccumulationPeriod: Text[30]; DampenerPeriod: Text[30]; DampenerQuantity: Integer; SafetyStock: Integer; LotSize: Integer)
    begin
        ItemSetup(Item, Item."Replenishment System"::Purchase, '<0D>');

        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Validate("Include Inventory", IncludeInventory);
        Evaluate(Item."Lot Accumulation Period", LotAccumulationPeriod);
        Evaluate(Item."Rescheduling Period", ReschedulingPeriod);
        Evaluate(Item."Dampener Period", DampenerPeriod);
        Item.Validate("Dampener Quantity", DampenerQuantity);
        Item.Validate("Safety Stock Quantity", SafetyStock);
        Item.Validate("Lot Size", LotSize);

        Item.Modify(true);
    end;

    local procedure MaxQtyItemSetup(var Item: Record Item; ReorderPoint: Integer; MaximumInventory: Integer; OverflowLevel: Integer; TimeBucket: Text[30]; DampenerQuantity: Integer; SafetyStock: Integer; SafetyLeadTime: Text[30]; LotSize: Integer)
    begin
        ItemSetup(Item, Item."Replenishment System"::Purchase, SafetyLeadTime);

        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Maximum Qty.");
        Item.Validate("Reorder Point", ReorderPoint);
        Item.Validate("Maximum Inventory", MaximumInventory);
        Item.Validate("Overflow Level", OverflowLevel);
        Evaluate(Item."Time Bucket", TimeBucket);
        Item.Validate("Dampener Quantity", DampenerQuantity);
        Item.Validate("Safety Stock Quantity", SafetyStock);
        Item.Validate("Lot Size", LotSize);

        Item.Modify(true);
    end;

    local procedure FixedReorderQtyItemSetup(var Item: Record Item; ReorderPoint: Integer; ReorderQuantity: Integer; OverflowLevel: Integer; TimeBucket: Text[30]; DampenerQuantity: Integer; SafetyStock: Integer; SafetyLeadTime: Text[30]; LotSize: Integer)
    begin
        ItemSetup(Item, Item."Replenishment System"::Purchase, SafetyLeadTime);

        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Fixed Reorder Qty.");
        Item.Validate("Reorder Point", ReorderPoint);
        Item.Validate("Reorder Quantity", ReorderQuantity);
        Item.Validate("Overflow Level", OverflowLevel);
        Evaluate(Item."Time Bucket", TimeBucket);
        Item.Validate("Dampener Quantity", DampenerQuantity);
        Item.Validate("Safety Stock Quantity", SafetyStock);
        Item.Validate("Lot Size", LotSize);

        Item.Modify(true);
    end;

    local procedure OrderItemSetup(var Item: Record Item; DampenerPeriod: Text[30])
    begin
        ItemSetup(Item, Item."Replenishment System"::Purchase, '<0D>');

        Item.Validate("Reordering Policy", Item."Reordering Policy"::Order);
        Evaluate(Item."Dampener Period", DampenerPeriod);

        Item.Modify(true);
    end;

    local procedure LocationSetup(var Location: Record Location; BinMandatory: Boolean)
    var
        Bin: Record Bin;
        WarehouseEmployee: Record "Warehouse Employee";
        BinCount: Integer;
    begin
        Clear(Location);
        Location.Init();

        Clear(Bin);
        Bin.Init();

        Clear(WarehouseEmployee);
        WarehouseEmployee.Init();

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        // Skip validate trigger for bin mandatory to improve performance.
        Location."Bin Mandatory" := BinMandatory;
        Location.Modify(true);

        if BinMandatory then
            for BinCount := 1 to 4 do
                LibraryWarehouse.CreateBin(Bin, Location.Code, 'bin' + Format(BinCount), '', '');

        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
    end;

    local procedure UpdatePlanningSetup()
    var
        InventorySetup: Record "Inventory Setup";
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Components at Location", '');
        ManufacturingSetup.Modify(true);

        InventorySetup.Get();
        InventorySetup.Validate("Current Demand Forecast", '');
        InventorySetup.Validate("Use Forecast on Locations", true);
        InventorySetup.Validate("Combined MPS/MRP Calculation", true);
        Evaluate(InventorySetup."Default Safety Lead Time", '<1D>');
        Evaluate(InventorySetup."Default Dampener Period", '');
        InventorySetup.Validate("Default Dampener %", 0);
        InventorySetup.Validate("Blank Overflow Level", InventorySetup."Blank Overflow Level"::"Allow Default Calculation");
        InventorySetup.Modify(true);
    end;

    local procedure SetDampenerTime(DampenerTime: Text[30])
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        Evaluate(InventorySetup."Default Dampener Period", DampenerTime);
        InventorySetup.Modify(true);
    end;

    local procedure SetBlankOverflowLevel(DampenerOption: Option)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Blank Overflow Level", DampenerOption);
        InventorySetup.Modify(true);
    end;

    local procedure DisableWarnings()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Stockout Warning", false);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Item: Record Item; SalesQty: Integer; ShipmentDate: Date)
    begin
        Clear(SalesHeader);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", SalesQty);
        SalesLine.Validate("Shipment Date", ShipmentDate);
        SalesLine.Modify(true);
    end;

    local procedure AddSalesOrderLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Item: Record Item; SalesQty: Integer; ShipmentDate: Date)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", SalesQty);
        SalesLine.Validate("Shipment Date", ShipmentDate);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrderWith2Lines(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Item: Record Item; SalesQty1: Integer; ShipmentDate1: Date; SalesQty2: Integer; ShipmentDate2: Date)
    begin
        CreateSalesOrder(SalesHeader, SalesLine, Item, SalesQty1, ShipmentDate1);
        AddSalesOrderLine(SalesHeader, SalesLine, Item, SalesQty2, ShipmentDate2);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Item: Record Item; PurchaseQty: Integer; ReceiptDate: Date)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        AddPurchaseOrderLine(PurchaseHeader, PurchaseLine, Item, PurchaseQty, ReceiptDate);
    end;

    local procedure AddPurchaseOrderLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Item: Record Item; PurchaseQty: Integer; ReceiveDate: Date)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", PurchaseQty);
        PurchaseLine.Validate("Expected Receipt Date", ReceiveDate);
        PurchaseLine.Modify(true);
    end;

    local procedure MakeItemInventory(ItemNo: Code[20]; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, '', '', Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure PurchaseSalesPlan(Item: Record Item; PurchaseQty: Integer; ReceivingDate: Date; SalesQty: Integer; ShipmentDate: Date)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, PurchaseQty, ReceivingDate);

        CreateSalesOrder(SalesHeader, SalesLine, Item, SalesQty, ShipmentDate);

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));
    end;

    local procedure FinalAssert(var RequisitionLine: Record "Requisition Line"; Item: Record Item)
    begin
        // After carrying out all the messages and re-running the planning wksheet, no new lines should be suggested
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);
        AssertNoLinesForItem(Item);
    end;

    local procedure PopulateWithVendorAndCarryOut(var RequisitionLine: Record "Requisition Line"; Item: Record Item)
    var
        VendorNo: Code[20];
    begin
        Clear(RequisitionLine);
        VendorNo := LibraryPurchase.CreateVendorNo();
        RequisitionLine.SetCurrentKey(Type, "No.", "Variant Code", "Location Code", "Starting Date");
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");
        if RequisitionLine.FindSet() then
            repeat
                RequisitionLine.Validate("Vendor No.", VendorNo);
                RequisitionLine.Validate("Accept Action Message", true);
                RequisitionLine.Modify(true);
            until RequisitionLine.Next() = 0;

        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
    end;

    local procedure SalesPlanCarryOutChgSalesPlan(Item: Record Item; SalesQty: Integer; ShipmentDate: Date; NewShipmentDate: Date)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
    begin
        CreateSalesOrder(SalesHeader, SalesLine, Item, SalesQty, ShipmentDate);

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        SalesLine.Validate("Shipment Date", NewShipmentDate);
        SalesLine.Modify(true);

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));
    end;

    local procedure SalePlanCarryOutCancelSalePlan(Item: Record Item; SalesQty: Integer; ShipmentDate: Date)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
    begin
        CreateSalesOrder(SalesHeader, SalesLine, Item, SalesQty, ShipmentDate);

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        SalesHeader.Delete(true);

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));
    end;

    local procedure TestSetup()
    begin
        UpdatePlanningSetup();
    end;

    local procedure AssertPlanningLine(Item: Record Item; ActionMsg: Enum "Action Message Type"; OrigDueDate: Date; DueDate: Date; OrigQty: Decimal; Quantity: Decimal; RefOrderType: Enum "Requisition Ref. Order Type"; NoOfLines: Integer)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetCurrentKey(Type, "No.", "Variant Code", "Location Code", "Starting Date");
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");

        RequisitionLine.SetRange("Action Message", ActionMsg);
        RequisitionLine.SetRange("Original Due Date", OrigDueDate);
        RequisitionLine.SetRange("Due Date", DueDate);
        RequisitionLine.SetRange("Original Quantity", OrigQty);
        RequisitionLine.SetRange(Quantity, Quantity);
        RequisitionLine.SetRange("Ref. Order Type", RefOrderType);
        Assert.AreEqual(NoOfLines, RequisitionLine.Count, 'There is no line within the filter: ' + RequisitionLine.GetFilters);
    end;

    local procedure AssertTrackedQty(ItemNo: Code[20]; ReqQty: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.Reset();
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        ReservationEntry.CalcSums("Quantity (Base)");

        Assert.AreEqual(ReqQty, ReservationEntry."Quantity (Base)", 'Expected Surplus Quantity was wrong in the reservation entries.');
    end;

    local procedure AssertNoLinesForItem(Item: Record Item)
    begin
        AssertNumberOfLinesForItem(Item, 0);
    end;

    local procedure AssertNumberOfLinesForItem(Item: Record Item; NoOfLines: Integer)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetCurrentKey(Type, "No.", "Variant Code", "Location Code", "Starting Date");
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");

        Assert.AreEqual(NoOfLines, RequisitionLine.Count, 'There should be ' + Format(NoOfLines) +
          ' line(s) in the planning worksheet for item ' + Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrder_CarryOut()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '', '', '', 0, 0, 0);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Modify(true);

        // Create demands
        CreateSalesOrder(SalesHeader, SalesLine, Item, 100, WorkDate());
        CreateSalesOrder(SalesHeader, SalesLine, Item, 100, WorkDate() + 1);

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate() - 1, WorkDate() + 1);

        // Carry out two lines
        RequisitionLine.SetFilter("No.", Item."No.");
        RequisitionLine.FindFirst();
        Assert.AreEqual(2, RequisitionLine.Count,
          'Unexpected number of requisition lines after creating two demands and planning for lot-for-lot replenished item.');
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);

        // Validate structure and data of carried out production orders
        ProdOrder.SetRange("Source No.", Item."No.");
        ProdOrder.FindSet();
        Assert.AreEqual(2, ProdOrder.Count,
          'Unexpected number of production orders after creating two demands and planning for lot-for-lot/prod. order replenished item, and carrying out.');

        repeat
            ProdOrderLine.SetRange(Status, ProdOrder.Status);
            ProdOrderLine.SetRange("Prod. Order No.", ProdOrder."No.");
            Assert.AreEqual(1, ProdOrderLine.Count,
              'A single production order line per production order expected after carrying out.');
            ProdOrderLine.FindFirst();
            Assert.AreEqual(Item."No.", ProdOrderLine."Item No.",
              'Wrong item no. on production order line after carrying out');
            Assert.AreEqual(100, ProdOrderLine.Quantity,
              'Wrong quantity on production order line after carrying out');
        until ProdOrder.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC1TC11ReschedPeriod()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '<5D>', '', '', 0, 0, 0);

        // Exercise
        PurchaseSalesPlan(Item, 10, CalcDate('<+11D>', WorkDate()), 10, CalcDate('<+5D>', WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Cancel, 0D, CalcDate('<+11D>', WorkDate()), 10, 0,
          RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+5D>', WorkDate()), 0, 10,
          RequisitionLine."Ref. Order Type"::Purchase, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC1TC12ReschedPeriod()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '<5D>', '', '', 0, 0, 0);

        // Exercise
        PurchaseSalesPlan(Item, 10, CalcDate('<+10D>', WorkDate()), 10, CalcDate('<+5D>', WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Reschedule, CalcDate('<+10D>', WorkDate()), CalcDate('<+5D>', WorkDate()), 0, 10,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC1TC13ReschedPeriod()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '<5D>', '', '', 0, 0, 0);

        // Exercise
        PurchaseSalesPlan(Item, 15, CalcDate('<+10D>', WorkDate()), 10, CalcDate('<+5D>', WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::"Resched. & Chg. Qty.", CalcDate('<+10D>', WorkDate()),
          CalcDate('<+5D>', WorkDate()), 15, 10, RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC1TC18ReschedPeriod()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '<5D>', '', '', 0, 0, 0);

        // Exercise
        SalesPlanCarryOutChgSalesPlan(Item, 10, CalcDate('<+11D>', WorkDate()), CalcDate('<+5D>', WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Cancel, 0D, CalcDate('<+11D>', WorkDate()), 10, 0,
          RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+5D>', WorkDate()), 0, 10,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC1TC19ReschedPeriod()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '<5D>', '', '', 0, 0, 0);

        // Exercise
        SalesPlanCarryOutChgSalesPlan(Item, 10, CalcDate('<+10D>', WorkDate()), CalcDate('<+5D>', WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Reschedule, CalcDate('<+10D>', WorkDate()), CalcDate('<+5D>', WorkDate()), 0, 10,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC1TC110ReschedPeriod()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '', '', '', 0, 0, 0);

        // Exercise
        PurchaseSalesPlan(Item, 10, CalcDate('<+6D>', WorkDate()), 10, CalcDate('<+5D>', WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Cancel, 0D, CalcDate('<+6D>', WorkDate()), 10, 0,
          RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+5D>', WorkDate()), 0, 10,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC1TC111ReschedPeriod()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '<0D>', '', '', 0, 0, 0);

        // Exercise
        PurchaseSalesPlan(Item, 10, CalcDate('<+6D>', WorkDate()), 10, CalcDate('<+5D>', WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Cancel, 0D, CalcDate('<+6D>', WorkDate()), 10, 0,
          RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+5D>', WorkDate()), 0, 10,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC2TC21DampenerPeriod()
    var
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '<100D>', '<14D>', '<5D>', 0, 0, 0);

        // Exercise
        PurchaseSalesPlan(Item, 10, CalcDate('<+5D>', WorkDate()), 10, CalcDate('<+10D>', WorkDate()));

        // Verify planning worksheet lines
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC2TC22DampenerPeriod()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '<3D>', '<14D>', '<5D>', 0, 0, 0);

        // Exercise
        PurchaseSalesPlan(Item, 10, CalcDate('<+11D>', WorkDate()), 10, CalcDate('<+5D>', WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Cancel, 0D, CalcDate('<+11D>', WorkDate()), 10, 0,
          RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+5D>', WorkDate()), 0, 10,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC2TC23DampenerPeriod()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '<7D>', '<14D>', '<5D>', 0, 0, 0);

        // Exercise
        PurchaseSalesPlan(Item, 10, CalcDate('<+5D>', WorkDate()), 10, CalcDate('<+11D>', WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Reschedule, CalcDate('<+5D>', WorkDate()),
          CalcDate('<+11D>', WorkDate()), 0, 10, RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC2TC24DampenerPeriod()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '<100D>', '<14D>', '<5D>', 0, 0, 0);

        // Exercise
        PurchaseSalesPlan(Item, 10, CalcDate('<+5D>', WorkDate()), 15, CalcDate('<+10D>', WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::"Change Qty.", 0D,
          CalcDate('<+5D>', WorkDate()), 10, 15, RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC2TC25DampenerPeriod()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '<3D>', '<14D>', '<5D>', 0, 0, 0);

        // Exercise
        PurchaseSalesPlan(Item, 10, CalcDate('<+5D>', WorkDate()), 5, CalcDate('<+11D>', WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Cancel, 0D,
          CalcDate('<+5D>', WorkDate()), 10, 0, RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate('<+11D>', WorkDate()), 0, 5, RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC2TC26DampenerPeriod()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '<7D>', '<14D>', '<5D>', 0, 0, 0);

        // Exercise
        PurchaseSalesPlan(Item, 10, CalcDate('<+5D>', WorkDate()), 15, CalcDate('<+11D>', WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::"Resched. & Chg. Qty.", CalcDate('<+5D>', WorkDate()),
          CalcDate('<+11D>', WorkDate()), 10, 15, RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC2TC27DampenerPeriod()
    var
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<5D>');
        LFLItemSetup(Item, true, '<100D>', '<14D>', '', 0, 0, 0);

        // Exercise
        PurchaseSalesPlan(Item, 10, CalcDate('<+5D>', WorkDate()), 10, CalcDate('<+10D>', WorkDate()));

        // Verify planning worksheet lines
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC2TC28DampenerPeriod()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<5D>');
        LFLItemSetup(Item, true, '<3D>', '<14D>', '', 0, 0, 0);

        // Exercise
        PurchaseSalesPlan(Item, 10, CalcDate('<+5D>', WorkDate()), 10, CalcDate('<+11D>', WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Cancel, 0D,
          CalcDate('<+5D>', WorkDate()), 10, 0, RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate('<+11D>', WorkDate()), 0, 10, RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC2TC29DampenerPeriod()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<5D>');
        LFLItemSetup(Item, true, '<7D>', '<14D>', '', 0, 0, 0);

        // Exercise
        PurchaseSalesPlan(Item, 10, CalcDate('<+5D>', WorkDate()), 10, CalcDate('<+11D>', WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Reschedule, CalcDate('<+5D>', WorkDate()),
          CalcDate('<+11D>', WorkDate()), 0, 10, RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC2TC210DampenerPeriod()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<5D>');
        LFLItemSetup(Item, true, '<100D>', '<14D>', '', 0, 0, 0);

        // Exercise
        PurchaseSalesPlan(Item, 10, CalcDate('<+5D>', WorkDate()), 15, CalcDate('<+10D>', WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::"Change Qty.", 0D,
          CalcDate('<+5D>', WorkDate()), 10, 15, RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC2TC211DampenerPeriod()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<5D>');
        LFLItemSetup(Item, true, '<3D>', '<14D>', '', 0, 0, 0);

        // Exercise
        PurchaseSalesPlan(Item, 10, CalcDate('<+5D>', WorkDate()), 5, CalcDate('<+11D>', WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Cancel, 0D,
          CalcDate('<+5D>', WorkDate()), 10, 0, RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate('<+11D>', WorkDate()), 0, 5, RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC2TC212DampenerPeriod()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<5D>');
        LFLItemSetup(Item, true, '<7D>', '<14D>', '', 0, 0, 0);

        // Exercise
        PurchaseSalesPlan(Item, 10, CalcDate('<+5D>', WorkDate()), 15, CalcDate('<+11D>', WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::"Resched. & Chg. Qty.", CalcDate('<+5D>', WorkDate()),
          CalcDate('<+11D>', WorkDate()), 10, 15, RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC2TC215DampenerPeriod()
    var
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LFLItemSetup(Item, true, '<100D>', '<14D>', '<5D>', 0, 0, 0);

        // Exercise
        SalesPlanCarryOutChgSalesPlan(Item, 10, CalcDate('<+5D>', WorkDate()), CalcDate('<+10D>', WorkDate()));

        // Verify planning worksheet lines
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC2TC216DampenerPeriod()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('');
        LFLItemSetup(Item, true, '', '<14D>', '', 0, 0, 0);

        // Exercise
        PurchaseSalesPlan(Item, 10, CalcDate('<+5D>', WorkDate()), 10, CalcDate('<+6D>', WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Cancel, 0D,
          CalcDate('<+5D>', WorkDate()), 10, 0, RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate('<+6D>', WorkDate()), 0, 10, RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC2TC217DampenerPeriod()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<0D>');
        LFLItemSetup(Item, true, '', '<14D>', '<0D>', 0, 0, 0);

        // Exercise
        PurchaseSalesPlan(Item, 10, CalcDate('<+5D>', WorkDate()), 10, CalcDate('<+6D>', WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Cancel, 0D,
          CalcDate('<+5D>', WorkDate()), 10, 0, RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate('<+6D>', WorkDate()), 0, 10, RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC2TC218DampenerPeriod()
    var
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        OrderItemSetup(Item, '<5D>');

        // Exercise
        SalesPlanCarryOutChgSalesPlan(Item, 10, CalcDate('<+5D>', WorkDate()), CalcDate('<+10D>', WorkDate()));

        // Verify planning worksheet lines
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC2TC219DampenerPeriod()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        OrderItemSetup(Item, '<5D>');

        // Exercise
        SalesPlanCarryOutChgSalesPlan(Item, 10, CalcDate('<+5D>', WorkDate()), CalcDate('<+11D>', WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Reschedule, CalcDate('<+5D>', WorkDate()),
          CalcDate('<+11D>', WorkDate()), 0, 10, RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC2TC220DampenerPeriod()
    var
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<5D>');
        OrderItemSetup(Item, '');

        // Exercise
        SalesPlanCarryOutChgSalesPlan(Item, 10, CalcDate('<+5D>', WorkDate()), CalcDate('<+10D>', WorkDate()));

        // Verify planning worksheet lines
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC2TC221DampenerPeriod()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<5D>');
        OrderItemSetup(Item, '<0D>');

        // Exercise
        SalesPlanCarryOutChgSalesPlan(Item, 10, CalcDate('<+5D>', WorkDate()), CalcDate('<+6D>', WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Reschedule, CalcDate('<+5D>', WorkDate()),
          CalcDate('<+6D>', WorkDate()), 0, 10, RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC2TC222DampenerPeriod()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<5D>');
        OrderItemSetup(Item, '');

        // Exercise
        SalesPlanCarryOutChgSalesPlan(Item, 10, CalcDate('<+5D>', WorkDate()), CalcDate('<+11D>', WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Reschedule, CalcDate('<+5D>', WorkDate()),
          CalcDate('<+11D>', WorkDate()), 0, 10, RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC2TC223DampenerPeriod()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('');
        OrderItemSetup(Item, '');

        // Exercise
        SalesPlanCarryOutChgSalesPlan(Item, 10, CalcDate('<+5D>', WorkDate()), CalcDate('<+6D>', WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Reschedule, CalcDate('<+5D>', WorkDate()),
          CalcDate('<+6D>', WorkDate()), 0, 10, RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC2TC224DampenerPeriod()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<0D>');
        OrderItemSetup(Item, '');

        // Exercise
        SalesPlanCarryOutChgSalesPlan(Item, 10, CalcDate('<+5D>', WorkDate()), CalcDate('<+6D>', WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Reschedule, CalcDate('<+5D>', WorkDate()),
          CalcDate('<+6D>', WorkDate()), 0, 10, RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC2TC225DampenerPeriod()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        OrderItemSetup(Item, '<100D>');

        // Exercise
        SalePlanCarryOutCancelSalePlan(Item, 10, CalcDate('<+11D>', WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Cancel, 0D,
          CalcDate('<+11D>', WorkDate()), 10, 0, RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC3TC31LotAccumulationPeriod()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<0D>');
        LFLItemSetup(Item, true, '', '<5D>', '', 0, 0, 0);

        // Exercise
        CreateSalesOrderWith2Lines(SalesHeader, SalesLine, Item, 10, CalcDate('<+5D>', WorkDate()), 20, CalcDate('<+10D>', WorkDate()));
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+5D>', WorkDate()), 0, 30,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC3TC32LotAccumulationPeriod()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<0D>');
        LFLItemSetup(Item, true, '', '<5D>', '', 0, 0, 0);

        // Exercise
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, 10, CalcDate('<+5D>', WorkDate()));
        CreateSalesOrderWith2Lines(SalesHeader, SalesLine, Item, 10, CalcDate('<+5D>', WorkDate()), 20, CalcDate('<+10D>', WorkDate()));
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::"Change Qty.", 0D, CalcDate('<+5D>', WorkDate()), 10, 30,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC3TC33LotAccumulationPeriod()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<0D>');
        LFLItemSetup(Item, true, '', '<5D>', '', 0, 0, 0);

        // Exercise
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, 50, CalcDate('<+5D>', WorkDate()));
        CreateSalesOrderWith2Lines(SalesHeader, SalesLine, Item, 10, CalcDate('<+5D>', WorkDate()), 20, CalcDate('<+10D>', WorkDate()));
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::"Change Qty.", 0D, CalcDate('<+5D>', WorkDate()), 50, 30,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC3TC34LotAccumulationPeriod()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<0D>');
        LFLItemSetup(Item, true, '', '<5D>', '', 0, 0, 0);

        // Exercise
        CreateSalesOrderWith2Lines(SalesHeader, SalesLine, Item, 10, CalcDate('<+5D>', WorkDate()), 20, CalcDate('<+11D>', WorkDate()));
        AddSalesOrderLine(SalesHeader, SalesLine, Item, 30, CalcDate('<+20D>', WorkDate()));
        AddSalesOrderLine(SalesHeader, SalesLine, Item, 20, CalcDate('<+14D>', WorkDate()));
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 3);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+5D>', WorkDate()), 0, 10,
          RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+11D>', WorkDate()), 0, 40,
          RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+20D>', WorkDate()), 0, 30,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC3TC35LotAccumulationPeriod()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<0D>');
        LFLItemSetup(Item, true, '', '<5D>', '', 0, 0, 0);

        // Exercise
        CreateSalesOrderWith2Lines(SalesHeader, SalesLine, Item, 10, CalcDate('<+5D>', WorkDate()), 20, CalcDate('<+11D>', WorkDate()));
        AddSalesOrderLine(SalesHeader, SalesLine, Item, 30, CalcDate('<+20D>', WorkDate()));
        AddSalesOrderLine(SalesHeader, SalesLine, Item, 20, CalcDate('<+14D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change last sales line
        SalesLine.Validate("Shipment Date", CalcDate('<+6D>', WorkDate()));
        SalesLine.Modify(true);

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::"Change Qty.", 0D, CalcDate('<+5D>', WorkDate()), 10, 30,
          RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::"Change Qty.", 0D, CalcDate('<+11D>', WorkDate()), 40, 20,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC3TC310LotAccumulationPeriod()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<0D>');
        LFLItemSetup(Item, true, '', '', '', 0, 0, 0);

        // Exercise
        CreateSalesOrderWith2Lines(SalesHeader, SalesLine, Item, 10, CalcDate('<+5D>', WorkDate()), 20, CalcDate('<+5D>', WorkDate()));
        AddSalesOrderLine(SalesHeader, SalesLine, Item, 30, CalcDate('<+6D>', WorkDate()));
        AddSalesOrderLine(SalesHeader, SalesLine, Item, 40, CalcDate('<+10D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 3);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+5D>', WorkDate()), 0, 30,
          RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+6D>', WorkDate()), 0, 30,
          RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+10D>', WorkDate()), 0, 40,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC3TC311LotAccumulationPeriod()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<0D>');
        LFLItemSetup(Item, true, '', '<0D>', '', 0, 0, 0);

        // Exercise
        CreateSalesOrderWith2Lines(SalesHeader, SalesLine, Item, 10, CalcDate('<+5D>', WorkDate()), 20, CalcDate('<+5D>', WorkDate()));
        AddSalesOrderLine(SalesHeader, SalesLine, Item, 30, CalcDate('<+6D>', WorkDate()));
        AddSalesOrderLine(SalesHeader, SalesLine, Item, 40, CalcDate('<+10D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 3);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+5D>', WorkDate()), 0, 30,
          RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+6D>', WorkDate()), 0, 30,
          RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+10D>', WorkDate()), 0, 40,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC3TC312LotAccumulationPeriod()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<0D>');
        LFLItemSetup(Item, true, '<3D>', '<5D>', '', 0, 0, 0);

        // Exercise
        CreateSalesOrderWith2Lines(SalesHeader, SalesLine, Item, 10, CalcDate('<+6D>', WorkDate()), 30, CalcDate('<+11D>', WorkDate()));
        AddSalesOrderLine(SalesHeader, SalesLine, Item, 20, CalcDate('<+7D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+6D>', WorkDate()), 0, 60,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change last sales line
        SalesLine.Validate("Shipment Date", CalcDate('<+5D>', WorkDate()));
        SalesLine.Modify(true);

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::"Resched. & Chg. Qty.", CalcDate('<+6D>', WorkDate()),
          CalcDate('<+5D>', WorkDate()), 60, 30, RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+11D>', WorkDate()), 0, 30,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC3TC313LotAccumulationPeriod()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<0D>');
        LFLItemSetup(Item, true, '<2D>', '<5D>', '', 0, 0, 0);

        // Exercise
        CreateSalesOrderWith2Lines(SalesHeader, SalesLine, Item, 10, CalcDate('<+8D>', WorkDate()), 30, CalcDate('<+11D>', WorkDate()));
        AddSalesOrderLine(SalesHeader, SalesLine, Item, 20, CalcDate('<+9D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+8D>', WorkDate()), 0, 60,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change last sales line
        SalesLine.Validate("Shipment Date", CalcDate('<+5D>', WorkDate()));
        SalesLine.Modify(true);

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 3);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Cancel, 0D, CalcDate('<+8D>', WorkDate())
          , 60, 0, RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+5D>', WorkDate()), 0, 30,
          RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+11D>', WorkDate()), 0, 30,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC3TC314LotAccumulationPeriod()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<0D>');
        LFLItemSetup(Item, true, '<100D>', '<5D>', '<3D>', 0, 0, 0);

        // Exercise
        CreateSalesOrderWith2Lines(SalesHeader, SalesLine, Item, 30, CalcDate('<+11D>', WorkDate()), 20, CalcDate('<+8D>', WorkDate()));
        AddSalesOrderLine(SalesHeader, SalesLine, Item, 10, CalcDate('<+6D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+6D>', WorkDate()), 0, 60,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change last sales line
        SalesLine.Validate("Shipment Date", CalcDate('<+8D>', WorkDate()));
        SalesLine.Modify(true);

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC3TC315LotAccumulationPeriod()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<0D>');
        LFLItemSetup(Item, true, '<7D>', '<5D>', '<3D>', 0, 0, 0);

        // Exercise
        CreateSalesOrderWith2Lines(SalesHeader, SalesLine, Item, 30, CalcDate('<+10D>', WorkDate()), 20, CalcDate('<+9D>', WorkDate()));
        AddSalesOrderLine(SalesHeader, SalesLine, Item, 10, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+5D>', WorkDate()), 0, 60,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change last sales line
        SalesLine.Validate("Shipment Date", CalcDate('<+9D>', WorkDate()));
        SalesLine.Modify(true);

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Reschedule, CalcDate('<+5D>', WorkDate()),
          CalcDate('<+9D>', WorkDate()), 0, 60, RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC3TC316LotAccumulationPeriod()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<0D>');
        LFLItemSetup(Item, true, '<3D>', '<5D>', '<3D>', 0, 0, 0);

        // Exercise
        CreateSalesOrderWith2Lines(SalesHeader, SalesLine, Item, 30, CalcDate('<+10D>', WorkDate()), 20, CalcDate('<+9D>', WorkDate()));
        AddSalesOrderLine(SalesHeader, SalesLine, Item, 10, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+5D>', WorkDate()), 0, 60,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change last sales line
        SalesLine.Validate("Shipment Date", CalcDate('<+9D>', WorkDate()));
        SalesLine.Modify(true);

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Cancel, 0D, CalcDate('<+5D>', WorkDate()),
          60, 0, RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate('<+9D>', WorkDate()), 0, 60, RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC3TC317LotAccumulationPeriod()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<0D>');
        LFLItemSetup(Item, true, '<7D>', '<5D>', '<3D>', 0, 0, 0);

        // Exercise
        CreateSalesOrderWith2Lines(SalesHeader, SalesLine, Item, 30, CalcDate('<+10D>', WorkDate()), 20, CalcDate('<+9D>', WorkDate()));
        AddSalesOrderLine(SalesHeader, SalesLine, Item, 10, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+5D>', WorkDate()), 0, 60,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change last sales line
        SalesLine.Validate("Shipment Date", CalcDate('<+9D>', WorkDate()));
        SalesLine.Validate(Quantity, 5);
        SalesLine.Modify(true);

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::"Resched. & Chg. Qty.", CalcDate('<+5D>', WorkDate()),
          CalcDate('<+9D>', WorkDate()), 60, 55, RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC3TC318LotAccumulationPeriod()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<0D>');
        LFLItemSetup(Item, true, '<100D>', '<5D>', '<30D>', 0, 0, 0);

        // Exercise
        CreateSalesOrder(SalesHeader, SalesLine, Item, 10, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+5D>', WorkDate()), 0, 10,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change last sales line
        SalesLine.Validate("Shipment Date", CalcDate('<+9D>', WorkDate()));
        SalesLine.Modify(true);

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC3TC319LotAccumulationPeriod()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<0D>');
        LFLItemSetup(Item, true, '<10D>', '<5D>', '<30D>', 0, 0, 0);

        // Exercise
        CreateSalesOrder(SalesHeader, SalesLine, Item, 10, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+5D>', WorkDate()), 0, 10,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change last sales line
        SalesLine.Validate("Shipment Date", CalcDate('<+11D>', WorkDate()));
        SalesLine.Modify(true);

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Reschedule, CalcDate('<+5D>', WorkDate()),
          CalcDate('<+11D>', WorkDate()), 0, 10, RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC3TC320LotAccumulationPeriod()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<0D>');
        LFLItemSetup(Item, true, '<5D>', '<5D>', '<30D>', 0, 0, 0);

        // Exercise
        CreateSalesOrder(SalesHeader, SalesLine, Item, 10, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+5D>', WorkDate()), 0, 10,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change last sales line
        SalesLine.Validate("Shipment Date", CalcDate('<+11D>', WorkDate()));
        SalesLine.Modify(true);

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Cancel, 0D, CalcDate('<+5D>', WorkDate()),
          10, 0, RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+11D>', WorkDate()),
          0, 10, RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC3TC321LotAccumulationPeriod()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<30D>');
        LFLItemSetup(Item, true, '<100D>', '<5D>', '', 0, 0, 0);

        // Exercise
        CreateSalesOrder(SalesHeader, SalesLine, Item, 10, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+5D>', WorkDate()), 0, 10,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change last sales line
        SalesLine.Validate("Shipment Date", CalcDate('<+9D>', WorkDate()));
        SalesLine.Modify(true);

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC3TC322LotAccumulationPeriod()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<30D>');
        LFLItemSetup(Item, true, '<10D>', '<5D>', '', 0, 0, 0);

        // Exercise
        CreateSalesOrder(SalesHeader, SalesLine, Item, 10, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+5D>', WorkDate()), 0, 10,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change last sales line
        SalesLine.Validate("Shipment Date", CalcDate('<+11D>', WorkDate()));
        SalesLine.Modify(true);

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Reschedule, CalcDate('<+5D>', WorkDate()),
          CalcDate('<+11D>', WorkDate()), 0, 10, RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC3TC323LotAccumulationPeriod()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<30D>');
        LFLItemSetup(Item, true, '<5D>', '<5D>', '', 0, 0, 0);

        // Exercise
        CreateSalesOrder(SalesHeader, SalesLine, Item, 10, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+5D>', WorkDate()), 0, 10,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change last sales line
        SalesLine.Validate("Shipment Date", CalcDate('<+11D>', WorkDate()));
        SalesLine.Modify(true);

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Cancel, 0D, CalcDate('<+5D>', WorkDate()),
          10, 0, RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+11D>', WorkDate()),
          0, 10, RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC3TC324LotAccumulationPeriod()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<0D>');
        LFLItemSetup(Item, true, '<5D>', '<5D>', '<30D>', 0, 0, 0);

        // Exercise
        CreateSalesOrderWith2Lines(SalesHeader, SalesLine, Item, 20, CalcDate('<+9D>', WorkDate()), 10, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+5D>', WorkDate()), 0, 30,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change last sales line
        SalesLine.Validate("Shipment Date", CalcDate('<+10D>', WorkDate()));
        SalesLine.Modify(true);

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC3TC325LotAccumulationPeriod()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<0D>');
        LFLItemSetup(Item, true, '<5D>', '<5D>', '<30D>', 0, 0, 0);

        // Exercise
        CreateSalesOrderWith2Lines(SalesHeader, SalesLine, Item, 10, CalcDate('<+5D>', WorkDate()), 20, CalcDate('<+9D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+5D>', WorkDate()), 0, 30,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change last sales line
        SalesLine.Validate("Shipment Date", CalcDate('<+14D>', WorkDate()));
        SalesLine.Modify(true);

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::"Change Qty.", 0D, CalcDate('<+5D>', WorkDate()),
          30, 10, RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+14D>', WorkDate()),
          0, 20, RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC3TC326LotAccumulationPeriod()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<0D>');
        LFLItemSetup(Item, true, '<5D>', '<5D>', '<30D>', 0, 0, 0);

        // Exercise
        CreateSalesOrderWith2Lines(SalesHeader, SalesLine, Item, 10, CalcDate('<+5D>', WorkDate()), 20, CalcDate('<+9D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+5D>', WorkDate()), 0, 30,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Delete the sales order
        SalesHeader.Delete(true);

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Cancel, 0D, CalcDate('<+5D>', WorkDate()),
          30, 0, RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC4TC41TimeBucket()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<0D>');
        MaxQtyItemSetup(Item, 20, 100, 100, '<5D>', 0, 5, '<2D>', 40);

        // Create inventory
        MakeItemInventory(Item."No.", 21);

        // Create demand
        CreateSalesOrder(SalesHeader, SalesLine, Item, 1, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+9D>', WorkDate()), 0, 80,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC4TC42TimeBucket()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<0D>');
        MaxQtyItemSetup(Item, 20, 100, 100, '<5D>', 0, 5, '<2D>', 40);

        // Create inventory
        MakeItemInventory(Item."No.", 21);

        // Create demand
        CreateSalesOrderWith2Lines(SalesHeader, SalesLine, Item, 1, CalcDate('<+5D>', WorkDate()), 10, CalcDate('<+10D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+9D>', WorkDate()), 0, 80,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC4TC43TimeBucket()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<0D>');
        MaxQtyItemSetup(Item, 20, 100, 100, '<5D>', 0, 5, '<2D>', 40);

        // Create inventory
        MakeItemInventory(Item."No.", 21);

        // Create demand
        CreateSalesOrder(SalesHeader, SalesLine, Item, 1, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+9D>', WorkDate()), 0, 80,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Delete the sales order
        SalesHeader.Delete(true);

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::"Change Qty.", 0D, CalcDate('<+9D>', WorkDate()),
          80, 79, RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC4TC44TimeBucket()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<0D>');
        MaxQtyItemSetup(Item, 20, 100, 100, '<5D>', 0, 5, '<2D>', 40);

        // Create inventory
        MakeItemInventory(Item."No.", 21);

        // Create demand
        CreateSalesOrderWith2Lines(SalesHeader, SalesLine, Item, 1, CalcDate('<+5D>', WorkDate()), 10, CalcDate('<+10D>', WorkDate()));
        AddSalesOrderLine(SalesHeader, SalesLine, Item, 81, CalcDate('<+11D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+9D>', WorkDate()), 0, 80,
          RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+14D>', WorkDate()), 0, 91,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC4TC45TimeBucket()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<0D>');
        MaxQtyItemSetup(Item, 20, 100, 100, '<5D>', 0, 5, '<2D>', 40);

        // Create inventory
        MakeItemInventory(Item."No.", 21);

        // Create demand
        CreateSalesOrderWith2Lines(SalesHeader, SalesLine, Item, 1, CalcDate('<+5D>', WorkDate()), 10, CalcDate('<+10D>', WorkDate()));
        AddSalesOrderLine(SalesHeader, SalesLine, Item, 81, CalcDate('<+11D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+9D>', WorkDate()), 0, 80,
          RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+14D>', WorkDate()), 0, 91,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change the last sales line
        SalesLine.Validate("Shipment Date", CalcDate('<+9D>', WorkDate()));
        SalesLine.Modify(true);

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC4TC46TimeBucket()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<0D>');
        FixedReorderQtyItemSetup(Item, 20, 100, 120, '<5D>', 0, 5, '<2D>', 0);

        // Create inventory
        MakeItemInventory(Item."No.", 21);

        // Create demand
        CreateSalesOrder(SalesHeader, SalesLine, Item, 1, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+9D>', WorkDate()), 0, 100,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC4TC47TimeBucket()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<0D>');
        FixedReorderQtyItemSetup(Item, 20, 100, 120, '<5D>', 0, 5, '<2D>', 0);

        // Create inventory
        MakeItemInventory(Item."No.", 21);

        // Create demand
        CreateSalesOrderWith2Lines(SalesHeader, SalesLine, Item, 1, CalcDate('<+5D>', WorkDate()), 10, CalcDate('<+10D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+9D>', WorkDate()), 0, 100,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC4TC48TimeBucket()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<0D>');
        FixedReorderQtyItemSetup(Item, 20, 100, 120, '<5D>', 0, 5, '<2D>', 0);

        // Create inventory
        MakeItemInventory(Item."No.", 21);

        // Create demand
        CreateSalesOrder(SalesHeader, SalesLine, Item, 1, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+9D>', WorkDate()), 0, 100,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Delete the sales order
        SalesHeader.Delete(true);

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::"Change Qty.", 0D, CalcDate('<+9D>', WorkDate()),
          100, 99, RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC4TC49TimeBucket()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<0D>');
        FixedReorderQtyItemSetup(Item, 20, 100, 120, '<5D>', 0, 5, '<2D>', 0);

        // Create inventory
        MakeItemInventory(Item."No.", 21);

        // Create demand
        CreateSalesOrderWith2Lines(SalesHeader, SalesLine, Item, 1, CalcDate('<+5D>', WorkDate()), 10, CalcDate('<+10D>', WorkDate()));
        AddSalesOrderLine(SalesHeader, SalesLine, Item, 91, CalcDate('<+11D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Validate
        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+9D>', WorkDate()), 0, 100,
          RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+14D>', WorkDate()), 0, 100,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC4TC410TimeBucket()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        SetDampenerTime('<0D>');
        FixedReorderQtyItemSetup(Item, 20, 100, 120, '<5D>', 0, 5, '<2D>', 0);

        // Create inventory
        MakeItemInventory(Item."No.", 21);

        // Create demand
        CreateSalesOrderWith2Lines(SalesHeader, SalesLine, Item, 1, CalcDate('<+5D>', WorkDate()), 10, CalcDate('<+10D>', WorkDate()));
        AddSalesOrderLine(SalesHeader, SalesLine, Item, 91, CalcDate('<+11D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Intermediate validate
        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+9D>', WorkDate()), 0, 100,
          RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+14D>', WorkDate()), 0, 100,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change the last sales line
        SalesLine.Validate("Shipment Date", CalcDate('<+9D>', WorkDate()));
        SalesLine.Modify(true);

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC5TC51DampenerQuantity()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LibraryPlanning.SetDefaultDampenerPercent(10);
        SetDampenerTime('<0D>');
        MaxQtyItemSetup(Item, 20, 100, 0, '<5D>', 4, 5, '<1D>', 40);

        // Create inventory
        MakeItemInventory(Item."No.", 21);

        // Create demand
        CreateSalesOrder(SalesHeader, SalesLine, Item, 5, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+8D>', WorkDate()), 0, 84,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change the last sales line
        SalesLine.Validate(Quantity, 1);
        SalesLine.Modify(true);

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC5TC52DampenerQuantity()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LibraryPlanning.SetDefaultDampenerPercent(10);
        SetDampenerTime('<0D>');
        MaxQtyItemSetup(Item, 20, 100, 0, '<5D>', 4, 5, '<1D>', 40);

        // Create inventory
        MakeItemInventory(Item."No.", 21);

        // Create demand
        CreateSalesOrder(SalesHeader, SalesLine, Item, 6, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+8D>', WorkDate()), 0, 85,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change the last sales line
        SalesLine.Validate(Quantity, 1);
        SalesLine.Modify(true);

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::"Change Qty.", 0D, CalcDate('<+8D>', WorkDate()), 85, 80,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC5TC53DampenerQuantity()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LibraryPlanning.SetDefaultDampenerPercent(10);
        SetDampenerTime('<0D>');
        MaxQtyItemSetup(Item, 20, 100, 0, '<5D>', 0, 5, '<1D>', 40);

        // Create inventory
        MakeItemInventory(Item."No.", 21);

        // Create demand
        CreateSalesOrder(SalesHeader, SalesLine, Item, 5, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+8D>', WorkDate()), 0, 84,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change the last sales line
        SalesLine.Validate(Quantity, 1);
        SalesLine.Modify(true);

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC5TC54DampenerQuantity()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LibraryPlanning.SetDefaultDampenerPercent(10);
        SetDampenerTime('<0D>');
        MaxQtyItemSetup(Item, 20, 100, 0, '<5D>', 0, 5, '<1D>', 40);

        // Create inventory
        MakeItemInventory(Item."No.", 21);

        // Create demand
        CreateSalesOrder(SalesHeader, SalesLine, Item, 6, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+8D>', WorkDate()), 0, 85,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change the last sales line
        SalesLine.Validate(Quantity, 1);
        SalesLine.Modify(true);

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::"Change Qty.", 0D, CalcDate('<+8D>', WorkDate()), 85, 80,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC5TC55DampenerQuantity()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LibraryPlanning.SetDefaultDampenerPercent(0);
        SetDampenerTime('<0D>');
        MaxQtyItemSetup(Item, 20, 100, 0, '<5D>', 0, 5, '<1D>', 40);

        // Create inventory
        MakeItemInventory(Item."No.", 21);

        // Create demand
        CreateSalesOrder(SalesHeader, SalesLine, Item, 2, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+8D>', WorkDate()), 0, 81,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change the last sales line
        SalesLine.Validate(Quantity, 1);
        SalesLine.Modify(true);

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::"Change Qty.", 0D, CalcDate('<+8D>', WorkDate()), 81, 80,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC5TC56DampenerQuantity()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LibraryPlanning.SetDefaultDampenerPercent(10);
        SetDampenerTime('<0D>');
        FixedReorderQtyItemSetup(Item, 20, 100, 0, '<5D>', 4, 5, '<1D>', 40);

        // Create inventory
        MakeItemInventory(Item."No.", 30);

        // Create demand
        CreateSalesOrder(SalesHeader, SalesLine, Item, 24, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+8D>', WorkDate()), 0, 100,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change the last sales line
        SalesLine.Validate(Quantity, 6);
        SalesLine.Modify(true);

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC5TC57DampenerQuantity()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LibraryPlanning.SetDefaultDampenerPercent(10);
        SetDampenerTime('<0D>');
        FixedReorderQtyItemSetup(Item, 20, 100, 0, '<5D>', 4, 5, '<1D>', 40);

        // Create inventory
        MakeItemInventory(Item."No.", 30);

        // Create demand
        CreateSalesOrder(SalesHeader, SalesLine, Item, 24, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+8D>', WorkDate()), 0, 100,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change the last sales line
        SalesLine.Validate(Quantity, 5);
        SalesLine.Modify(true);

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::"Change Qty.", 0D, CalcDate('<+8D>', WorkDate()), 100, 95,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC5TC58DampenerQuantity()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LibraryPlanning.SetDefaultDampenerPercent(10);
        SetDampenerTime('<0D>');
        FixedReorderQtyItemSetup(Item, 20, 100, 0, '<5D>', 0, 5, '<1D>', 40);

        // Create inventory
        MakeItemInventory(Item."No.", 30);

        // Create demand
        CreateSalesOrder(SalesHeader, SalesLine, Item, 24, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+8D>', WorkDate()), 0, 100,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change the last sales line
        SalesLine.Validate(Quantity, 6);
        SalesLine.Modify(true);

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC5TC59DampenerQuantity()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LibraryPlanning.SetDefaultDampenerPercent(10);
        SetDampenerTime('<0D>');
        FixedReorderQtyItemSetup(Item, 20, 100, 0, '<5D>', 0, 5, '<1D>', 40);

        // Create inventory
        MakeItemInventory(Item."No.", 30);

        // Create demand
        CreateSalesOrder(SalesHeader, SalesLine, Item, 24, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+8D>', WorkDate()), 0, 100,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change the last sales line
        SalesLine.Validate(Quantity, 5);
        SalesLine.Modify(true);

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::"Change Qty.", 0D, CalcDate('<+8D>', WorkDate()), 100, 95,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC5TC510DampenerQuantity()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LibraryPlanning.SetDefaultDampenerPercent(0);
        SetDampenerTime('<0D>');
        FixedReorderQtyItemSetup(Item, 20, 100, 0, '<5D>', 0, 5, '<1D>', 40);

        // Create inventory
        MakeItemInventory(Item."No.", 30);

        // Create demand
        CreateSalesOrder(SalesHeader, SalesLine, Item, 24, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+8D>', WorkDate()), 0, 100,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change the last sales line
        SalesLine.Validate(Quantity, 9);
        SalesLine.Modify(true);

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::"Change Qty.", 0D, CalcDate('<+8D>', WorkDate()), 100, 99,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC5TC511DampenerQuantity()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LibraryPlanning.SetDefaultDampenerPercent(10);
        LFLItemSetup(Item, true, '', '<10D>', '', 4, 0, 40);

        // Create demand
        CreateSalesOrder(SalesHeader, SalesLine, Item, 10, CalcDate('<+10D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+10D>', WorkDate()), 0, 10,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change the last sales line
        SalesLine.Validate(Quantity, 6);
        SalesLine.Modify(true);

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC5TC512DampenerQuantity()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LibraryPlanning.SetDefaultDampenerPercent(10);
        LFLItemSetup(Item, true, '', '<10D>', '', 4, 0, 40);

        // Create demand
        CreateSalesOrder(SalesHeader, SalesLine, Item, 10, CalcDate('<+10D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+10D>', WorkDate()), 0, 10,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change the last sales line
        SalesLine.Validate(Quantity, 5);
        SalesLine.Modify(true);

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::"Change Qty.", 0D, CalcDate('<+10D>', WorkDate()), 10, 5,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC5TC513DampenerQuantity()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LibraryPlanning.SetDefaultDampenerPercent(10);
        LFLItemSetup(Item, true, '', '<10D>', '', 0, 0, 40);

        // Create demand
        CreateSalesOrder(SalesHeader, SalesLine, Item, 10, CalcDate('<+10D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+10D>', WorkDate()), 0, 10,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change the last sales line
        SalesLine.Validate(Quantity, 6);
        SalesLine.Modify(true);

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC5TC514DampenerQuantity()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LibraryPlanning.SetDefaultDampenerPercent(10);
        LFLItemSetup(Item, true, '', '<10D>', '', 0, 0, 40);

        // Create demand
        CreateSalesOrder(SalesHeader, SalesLine, Item, 10, CalcDate('<+10D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+10D>', WorkDate()), 0, 10,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change the last sales line
        SalesLine.Validate(Quantity, 5);
        SalesLine.Modify(true);

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::"Change Qty.", 0D, CalcDate('<+10D>', WorkDate()), 10, 5,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC5TC515DampenerQuantity()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LibraryPlanning.SetDefaultDampenerPercent(10);
        LFLItemSetup(Item, true, '', '<10D>', '', 0, 0, 0);

        // Create demand
        CreateSalesOrder(SalesHeader, SalesLine, Item, 10, CalcDate('<+10D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+10D>', WorkDate()), 0, 10,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change the last sales line
        SalesLine.Validate(Quantity, 9);
        SalesLine.Modify(true);

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::"Change Qty.", 0D, CalcDate('<+10D>', WorkDate()), 10, 9,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC6TC61OverflowLevel()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // [FEATURE] [Overflow]
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LibraryPlanning.SetDefaultDampenerPercent(0);
        SetDampenerTime('<0D>');
        MaxQtyItemSetup(Item, 20, 100, 101, '<5D>', 0, 5, '<1D>', 0);

        // Create inventory
        MakeItemInventory(Item."No.", 30);

        // Create demand
        CreateSalesOrder(SalesHeader, SalesLine, Item, 20, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+8D>', WorkDate()), 0, 90,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change the last sales line
        SalesLine.Validate(Quantity, 2);
        SalesLine.Modify(true);

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::"Change Qty.", 0D, CalcDate('<+8D>', WorkDate()), 90, 73,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC6TC62OverflowLevel()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // [FEATURE] [Overflow]
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LibraryPlanning.SetDefaultDampenerPercent(0);
        SetDampenerTime('<0D>');
        MaxQtyItemSetup(Item, 20, 100, 101, '<5D>', 0, 5, '<1D>', 0);

        // Create inventory
        MakeItemInventory(Item."No.", 30);

        // Create demand
        CreateSalesOrder(SalesHeader, SalesLine, Item, 20, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+8D>', WorkDate()), 0, 90,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change the last sales line
        SalesLine.Validate(Quantity, 19);
        SalesLine.Modify(true);

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC6TC63OverflowLevel()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
    begin
        // [FEATURE] [Overflow]
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LibraryPlanning.SetDefaultDampenerPercent(0);
        SetDampenerTime('<0D>');
        SetBlankOverflowLevel(InventorySetup."Blank Overflow Level"::"Use Item/SKU Values Only");
        MaxQtyItemSetup(Item, 20, 100, 0, '<5D>', 0, 5, '<1D>', 0);

        // Create inventory
        MakeItemInventory(Item."No.", 30);

        // Create demand
        CreateSalesOrder(SalesHeader, SalesLine, Item, 20, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+8D>', WorkDate()), 0, 90,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change the last sales line
        SalesLine.Validate(Quantity, 2);
        SalesLine.Modify(true);

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC6TC64OverflowLevel()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
    begin
        // [FEATURE] [Overflow]
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LibraryPlanning.SetDefaultDampenerPercent(0);
        SetDampenerTime('<0D>');
        SetBlankOverflowLevel(InventorySetup."Blank Overflow Level"::"Allow Default Calculation");
        MaxQtyItemSetup(Item, 20, 100, 0, '<5D>', 0, 5, '<1D>', 0);

        // Create inventory
        MakeItemInventory(Item."No.", 30);

        // Create demand
        CreateSalesOrder(SalesHeader, SalesLine, Item, 20, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+8D>', WorkDate()), 0, 90,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change the last sales line
        SalesLine.Validate(Quantity, 2);
        SalesLine.Modify(true);

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::"Change Qty.", 0D, CalcDate('<+8D>', WorkDate()), 90, 72,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC6TC65OverflowLevel()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
    begin
        // [FEATURE] [Overflow]
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LibraryPlanning.SetDefaultDampenerPercent(0);
        SetDampenerTime('<0D>');
        SetBlankOverflowLevel(InventorySetup."Blank Overflow Level"::"Allow Default Calculation");
        MaxQtyItemSetup(Item, 20, 100, 101, '<5D>', 0, 5, '<1D>', 0);

        // Create inventory
        MakeItemInventory(Item."No.", 30);

        // Create demand
        CreateSalesOrder(SalesHeader, SalesLine, Item, 20, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+8D>', WorkDate()), 0, 90,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change the last sales line
        SalesLine.Validate(Quantity, 19);
        SalesLine.Modify(true);

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC6TC66OverflowLevel()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
    begin
        // [FEATURE] [Overflow]
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LibraryPlanning.SetDefaultDampenerPercent(0);
        SetDampenerTime('<0D>');
        SetBlankOverflowLevel(InventorySetup."Blank Overflow Level"::"Allow Default Calculation");
        MaxQtyItemSetup(Item, 20, 100, 101, '<5D>', 5, 5, '<1D>', 0);

        // Create inventory
        MakeItemInventory(Item."No.", 30);

        // Create demand
        CreateSalesOrder(SalesHeader, SalesLine, Item, 20, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+8D>', WorkDate()), 0, 90,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change the last sales line
        SalesLine.Validate(Quantity, 14);
        SalesLine.Modify(true);

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC6TC67OverflowLevel()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
    begin
        // [FEATURE] [Overflow]
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LibraryPlanning.SetDefaultDampenerPercent(0);
        SetDampenerTime('<0D>');
        SetBlankOverflowLevel(InventorySetup."Blank Overflow Level"::"Allow Default Calculation");
        MaxQtyItemSetup(Item, 20, 100, 101, '<5D>', 5, 5, '<1D>', 0);

        // Create inventory
        MakeItemInventory(Item."No.", 30);

        // Create demand
        CreateSalesOrder(SalesHeader, SalesLine, Item, 20, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+8D>', WorkDate()), 0, 90,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change the last sales line
        SalesLine.Validate(Quantity, 13);
        SalesLine.Modify(true);

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::"Change Qty.", 0D, CalcDate('<+8D>', WorkDate()), 90, 84,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC6TC68OverflowLevel()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // [FEATURE] [Overflow]
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LibraryPlanning.SetDefaultDampenerPercent(0);
        SetDampenerTime('<0D>');
        FixedReorderQtyItemSetup(Item, 20, 80, 101, '<5D>', 0, 5, '<1D>', 0);

        // Create inventory
        MakeItemInventory(Item."No.", 30);

        // Create demand
        CreateSalesOrder(SalesHeader, SalesLine, Item, 20, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+8D>', WorkDate()), 0, 80,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change the last sales line
        SalesLine.Validate(Quantity, 2);
        SalesLine.Modify(true);

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::"Change Qty.", 0D, CalcDate('<+8D>', WorkDate()), 80, 73,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC6TC69OverflowLevel()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // [FEATURE] [Overflow]
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LibraryPlanning.SetDefaultDampenerPercent(0);
        SetDampenerTime('<0D>');
        FixedReorderQtyItemSetup(Item, 20, 80, 101, '<5D>', 0, 5, '<1D>', 0);

        // Create inventory
        MakeItemInventory(Item."No.", 30);

        // Create demand
        CreateSalesOrder(SalesHeader, SalesLine, Item, 20, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+8D>', WorkDate()), 0, 80,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change the last sales line
        SalesLine.Validate(Quantity, 9);
        SalesLine.Modify(true);

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC6TC610OverflowLevel()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
    begin
        // [FEATURE] [Overflow]
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LibraryPlanning.SetDefaultDampenerPercent(0);
        SetDampenerTime('<0D>');
        SetBlankOverflowLevel(InventorySetup."Blank Overflow Level"::"Use Item/SKU Values Only");
        FixedReorderQtyItemSetup(Item, 20, 80, 0, '<5D>', 0, 5, '<1D>', 0);

        // Create inventory
        MakeItemInventory(Item."No.", 30);

        // Create demand
        CreateSalesOrder(SalesHeader, SalesLine, Item, 20, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+8D>', WorkDate()), 0, 80,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change the last sales line
        SalesLine.Validate(Quantity, 2);
        SalesLine.Modify(true);

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC6TC611OverflowLevel()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
    begin
        // [FEATURE] [Overflow]
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LibraryPlanning.SetDefaultDampenerPercent(0);
        SetDampenerTime('<0D>');
        SetBlankOverflowLevel(InventorySetup."Blank Overflow Level"::"Allow Default Calculation");
        FixedReorderQtyItemSetup(Item, 20, 80, 0, '<5D>', 0, 5, '<1D>', 0);

        // Create inventory
        MakeItemInventory(Item."No.", 30);

        // Create demand
        CreateSalesOrder(SalesHeader, SalesLine, Item, 20, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+8D>', WorkDate()), 0, 80,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change the last sales line
        SalesLine.Validate(Quantity, 2);
        SalesLine.Modify(true);

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::"Change Qty.", 0D, CalcDate('<+8D>', WorkDate()), 80, 72,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC6TC612OverflowLevel()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
    begin
        // [FEATURE] [Overflow]
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LibraryPlanning.SetDefaultDampenerPercent(0);
        SetDampenerTime('<0D>');
        SetBlankOverflowLevel(InventorySetup."Blank Overflow Level"::"Allow Default Calculation");
        FixedReorderQtyItemSetup(Item, 20, 80, 101, '<5D>', 0, 5, '<1D>', 0);

        // Create inventory
        MakeItemInventory(Item."No.", 30);

        // Create demand
        CreateSalesOrder(SalesHeader, SalesLine, Item, 20, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+8D>', WorkDate()), 0, 80,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change the last sales line
        SalesLine.Validate(Quantity, 19);
        SalesLine.Modify(true);

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC6TC613OverflowLevel()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
    begin
        // [FEATURE] [Overflow]
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LibraryPlanning.SetDefaultDampenerPercent(0);
        SetDampenerTime('<0D>');
        SetBlankOverflowLevel(InventorySetup."Blank Overflow Level"::"Allow Default Calculation");
        FixedReorderQtyItemSetup(Item, 20, 80, 101, '<5D>', 5, 5, '<1D>', 0);

        // Create inventory
        MakeItemInventory(Item."No.", 30);

        // Create demand
        CreateSalesOrder(SalesHeader, SalesLine, Item, 20, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+8D>', WorkDate()), 0, 80,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change the last sales line
        SalesLine.Validate(Quantity, 4);
        SalesLine.Modify(true);

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC6TC614OverflowLevel()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
    begin
        // [FEATURE] [Overflow]
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LibraryPlanning.SetDefaultDampenerPercent(0);
        SetDampenerTime('<0D>');
        SetBlankOverflowLevel(InventorySetup."Blank Overflow Level"::"Allow Default Calculation");
        FixedReorderQtyItemSetup(Item, 20, 80, 101, '<5D>', 5, 5, '<1D>', 0);

        // Create inventory
        MakeItemInventory(Item."No.", 30);

        // Create demand
        CreateSalesOrder(SalesHeader, SalesLine, Item, 20, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+8D>', WorkDate()), 0, 80,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change the last sales line
        SalesLine.Validate(Quantity, 3);
        SalesLine.Modify(true);

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::"Change Qty.", 0D, CalcDate('<+8D>', WorkDate()), 80, 74,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC6TC615OverflowLevel()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
    begin
        // [FEATURE] [Overflow]
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LibraryPlanning.SetDefaultDampenerPercent(0);
        SetDampenerTime('<0D>');
        SetBlankOverflowLevel(InventorySetup."Blank Overflow Level"::"Allow Default Calculation");
        MaxQtyItemSetup(Item, 20, 100, 5, '<5D>', 0, 5, '<1D>', 0);

        // Create inventory
        MakeItemInventory(Item."No.", 30);

        // Create demand
        CreateSalesOrder(SalesHeader, SalesLine, Item, 20, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+8D>', WorkDate()), 0, 90,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change the last sales line
        SalesLine.Validate(Quantity, 19);
        SalesLine.Modify(true);

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::"Change Qty.", 0D, CalcDate('<+8D>', WorkDate()), 90, 89,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC6TC616OverflowLevel()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
    begin
        // [FEATURE] [Overflow]
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LibraryPlanning.SetDefaultDampenerPercent(0);
        SetDampenerTime('<0D>');
        SetBlankOverflowLevel(InventorySetup."Blank Overflow Level"::"Use Item/SKU Values Only");
        MaxQtyItemSetup(Item, 20, 100, 5, '<5D>', 0, 5, '<1D>', 0);

        // Create inventory
        MakeItemInventory(Item."No.", 30);

        // Create demand
        CreateSalesOrder(SalesHeader, SalesLine, Item, 20, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+8D>', WorkDate()), 0, 90,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change the last sales line
        SalesLine.Validate(Quantity, 19);
        SalesLine.Modify(true);

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::"Change Qty.", 0D, CalcDate('<+8D>', WorkDate()), 90, 89,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC6TC617OverflowLevel()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
    begin
        // [FEATURE] [Overflow]
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LibraryPlanning.SetDefaultDampenerPercent(0);
        SetDampenerTime('<0D>');
        SetBlankOverflowLevel(InventorySetup."Blank Overflow Level"::"Allow Default Calculation");
        FixedReorderQtyItemSetup(Item, 20, 80, 5, '<5D>', 0, 5, '<1D>', 0);

        // Create inventory
        MakeItemInventory(Item."No.", 30);

        // Create demand
        CreateSalesOrder(SalesHeader, SalesLine, Item, 20, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+8D>', WorkDate()), 0, 80,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change the last sales line
        SalesLine.Validate(Quantity, 9);
        SalesLine.Modify(true);

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::"Change Qty.", 0D, CalcDate('<+8D>', WorkDate()), 80, 79,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC6TC618OverflowLevel()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
    begin
        // [FEATURE] [Overflow]
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LibraryPlanning.SetDefaultDampenerPercent(0);
        SetDampenerTime('<0D>');
        SetBlankOverflowLevel(InventorySetup."Blank Overflow Level"::"Allow Default Calculation");
        FixedReorderQtyItemSetup(Item, 20, 80, 5, '<5D>', 0, 5, '<1D>', 0);

        // Create inventory
        MakeItemInventory(Item."No.", 30);

        // Create demand
        CreateSalesOrder(SalesHeader, SalesLine, Item, 20, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+8D>', WorkDate()), 0, 80,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change the last sales line
        SalesLine.Validate(Quantity, 10);
        SalesLine.Modify(true);

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC6TC619OverflowLevel()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
    begin
        // [FEATURE] [Overflow]
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LibraryPlanning.SetDefaultDampenerPercent(0);
        SetDampenerTime('<0D>');
        SetBlankOverflowLevel(InventorySetup."Blank Overflow Level"::"Use Item/SKU Values Only");
        FixedReorderQtyItemSetup(Item, 20, 80, 5, '<5D>', 0, 5, '<1D>', 0);

        // Create inventory
        MakeItemInventory(Item."No.", 30);

        // Create demand
        CreateSalesOrder(SalesHeader, SalesLine, Item, 20, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+8D>', WorkDate()), 0, 80,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change the last sales line
        SalesLine.Validate(Quantity, 9);
        SalesLine.Modify(true);

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::"Change Qty.", 0D, CalcDate('<+8D>', WorkDate()), 80, 79,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Final verification
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SC6TC620OverflowLevel()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
    begin
        // [FEATURE] [Overflow]
        // Setup
        Initialize();

        // Test setup
        TestSetup();
        LibraryPlanning.SetDefaultDampenerPercent(0);
        SetDampenerTime('<0D>');
        SetBlankOverflowLevel(InventorySetup."Blank Overflow Level"::"Use Item/SKU Values Only");
        FixedReorderQtyItemSetup(Item, 20, 80, 5, '<5D>', 0, 5, '<1D>', 0);

        // Create inventory
        MakeItemInventory(Item."No.", 30);

        // Create demand
        CreateSalesOrder(SalesHeader, SalesLine, Item, 20, CalcDate('<+5D>', WorkDate()));

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+8D>', WorkDate()), 0, 80,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        // Carry out
        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        // Change the last sales line
        SalesLine.Validate(Quantity, 10);
        SalesLine.Modify(true);

        // Run planning
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify planning worksheet lines
        AssertNoLinesForItem(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseBringingInventoryAboveOverflowLevelSuggestedCanceled()
    var
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Overflow]
        // [SCENARIO 267949] The planning engine suggests canceling the supply that brings inventory above the overflow level.
        Initialize();

        // [GIVEN] Overflow level by default is equal to "Reorder Point" + "Minimum Order Quantity".
        SetBlankOverflowLevel(InventorySetup."Blank Overflow Level"::"Allow Default Calculation");

        // [GIVEN] Item with "Reorder Point" = 10 pcs, "Minimum Order Quantity" = 20 pcs, the overflow level is hence = 30 pcs.
        FixedReorderQtyItemSetup(Item, 10, 1, 0, '', 0, 0, '', 0);
        Item.Validate("Minimum Order Quantity", 20);
        Item.Modify(true);

        // [GIVEN] Post the initial inventory for 11 pcs on 01-Jan.
        MakeItemInventory(Item."No.", 11);

        // [GIVEN] Three sales lines for 1 pc each on 05-Jan., 10-Jan., 15-Jan. respectively.
        CreateSalesOrder(SalesHeader, SalesLine, Item, 1, WorkDate() + 5);
        AddSalesOrderLine(SalesHeader, SalesLine, Item, 1, WorkDate() + 10);
        AddSalesOrderLine(SalesHeader, SalesLine, Item, 1, WorkDate() + 15);

        // [GIVEN] Purchase order for 20 pcs on 05-Jan. This purchase meets the reorder point requirement.
        // [GIVEN] The inventory on 05-Jan. = 30 pcs (11 - 1 + 20)
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, 20, WorkDate() + 5);

        // [GIVEN] Another purchase order for 22 pcs on 20-Jan.
        // [GIVEN] The inventory before the purchase is 28 pcs, but the purchase makes it 50 pcs, which is above the overflow level of 30 pcs.
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, 22, WorkDate() + 20);

        // [WHEN] Calculate regenerative plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate() + 30);

        // [THEN] The second purchase is suggested to be canceled.
        // [THEN] Without the minimum order requirement the planning engine would have suggested decreasing the purchase from 22 to 1 pc.
        // [THEN] Now the maximum allowed decrease is only 2 pcs (from 22 pcs to 20 pcs), that will not be enough to stay below the overflow level.
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(
          Item, RequisitionLine."Action Message"::Cancel, 0D, WorkDate() + 20, 22, 0, RequisitionLine."Ref. Order Type"::Purchase, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AU959450N5YU_SafetyStock()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        TestSetup();
        MaxQtyItemSetup(Item, 0, 10, 0, '<0D>', 0, 4, '<0D>', 0);

        // Exercise
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));
        AssertNumberOfLinesForItem(Item, 2);

        // Verify
        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BE209606YG6Y_MaxInv()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        TestSetup();
        MaxQtyItemSetup(Item, 2000, 5000, 0, '<0D>', 0, 1000, '<0D>', 0);

        // Exercise
        MakeItemInventory(Item."No.", 50);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify
        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate(PlanningStartDate, WorkDate()), 0, 950,
          RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate(PlanningStartDate, WorkDate()), 0, 4000,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NL687689SHU2_ROP()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        TestSetup();
        FixedReorderQtyItemSetup(Item, 40000, 40000, 0, '<0D>', 0, 0, '<0D>', 0);
        Item.Validate("Maximum Order Quantity", 10000);
        Item.Modify(true);

        // Exercise
        MakeItemInventory(Item."No.", 50);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify
        AssertNumberOfLinesForItem(Item, 4);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate(PlanningStartDate, WorkDate()), 0, 10000,
          RequisitionLine."Ref. Order Type"::Purchase, 4);

        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XXXXXXXXXXXX_MaxInv()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        TestSetup();
        MaxQtyItemSetup(Item, 0, 250, 0, '<1M>', 0, 0, '<0D>', 0);

        // Exercise
        CreateSalesOrderWith2Lines(SalesHeader, SalesLine, Item, 100, CalcDate('<+2D>', WorkDate()), 150, CalcDate('<+4D>', WorkDate()));
        AddSalesOrderLine(SalesHeader, SalesLine, Item, 100, CalcDate('<+6D>', WorkDate()));
        AddSalesOrderLine(SalesHeader, SalesLine, Item, 50, CalcDate('<+8D>', WorkDate()));
        AddSalesOrderLine(SalesHeader, SalesLine, Item, 100, CalcDate('<+10D>', WorkDate()));
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify
        AssertNumberOfLinesForItem(Item, 5);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate(PlanningStartDate, WorkDate()), 0, 250,
          RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+6D>', WorkDate()), 0, 100,
          RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+8D>', WorkDate()), 0, 50,
          RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+10D>', WorkDate()), 0, 100,
          RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(DaysInMonthFormula, CalcDate('<-1D>', CalcDate(PlanningStartDate, WorkDate()))), 0, 250,
          RequisitionLine."Ref. Order Type"::Purchase, 1);// 1M-1D+Planningstartdate

        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DE937204GJUH_MaxInv()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        TestSetup();
        MaxQtyItemSetup(Item, 10, 100, 0, '<1M>', 0, 0, '<0D>', 0);

        // Exercise
        CreateSalesOrderWith2Lines(SalesHeader, SalesLine, Item, 120, CalcDate('<+1W>', WorkDate()), 80, CalcDate('<+2W>', WorkDate()));
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify
        AssertNumberOfLinesForItem(Item, 4);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate(PlanningStartDate, WorkDate()), 0, 100,
          RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+1W>', WorkDate()), 0, 20,
          RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<+2W>', WorkDate()), 0, 80,
          RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D,
          CalcDate(DaysInMonthFormula, CalcDate('<-1D>', CalcDate(PlanningStartDate, WorkDate()))), 0, 100,
          RequisitionLine."Ref. Order Type"::Purchase, 1);// 1M-1D+Planningstartdate

        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AU83381476XT_MaxInv()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        TestSetup();
        MaxQtyItemSetup(Item, 17, 25, 0, '<0D>', 0, 4, '<5D>', 0);

        // Exercise
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify
        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate(PlanningStartDate, WorkDate()), 0, 4,
          RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<5D>', CalcDate(PlanningStartDate, WorkDate())), 0, 21,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure HQ634879PFTC_Surplus()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        TestSetup();
        MaxQtyItemSetup(Item, 50, 100, 0, '<0D>', 0, 20, '<0D>', 0);
        LibraryVariableStorage.Enqueue(RunRegPlanMsg);  // Handled in Message Handler.
        Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking Only");
        Item.Modify(true);

        // Exercise
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify
        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate(PlanningStartDate, WorkDate()), 0, 20,
          RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate(PlanningStartDate, WorkDate()), 0, 80,
          RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertTrackedQty(Item."No.", 100);

        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DE6056398K8T_ReorderCycle()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup
        Initialize();

        TestSetup();
        MaxQtyItemSetup(Item, 0, 50, 0, '<5D>', 0, 0, '<3D>', 0);

        Item.SetFilter("Location Filter", '%1', LocationBlue.Code);
        LibraryInventory.CreateStockKeepingUnit(Item, "SKU Creation Method"::Location, false, false);

        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", LocationBlue.Code, '', 10);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        CreateSalesOrder(SalesHeader, SalesLine, Item, 30, CalcDate('<+5D>', CalcDate(PlanningStartDate, WorkDate())));
        SalesLine.Validate("Location Code", LocationBlue.Code);
        SalesLine.Modify(true);

        // Exercise
        Item.SetRange("Location Filter", LocationBlue.Code);
        Item.SetRange("No.", Item."No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));
        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<1D>', WorkDate()), 0, 20,
          RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<5D>', WorkDate()), 0, 50,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        PopulateWithVendorAndCarryOut(RequisitionLine, Item);

        AddSalesOrderLine(SalesHeader, SalesLine, Item, 20, WorkDate());
        SalesLine.Validate("Location Code", LocationBlue.Code);
        SalesLine.Modify(true);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify
        AssertNumberOfLinesForItem(Item, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate('<1D>', WorkDate()), 0, 20,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DE790799VL86_MaxInv()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        TestSetup();
        MaxQtyItemSetup(Item, 2, 3, 0, '<0D>', 0, 0, '<0D>', 0);

        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, 100, CalcDate(PlanningStartDate, WorkDate()));
        AddPurchaseOrderLine(PurchaseHeader, PurchaseLine, Item, 100, CalcDate('<+1D>', CalcDate(PlanningStartDate, WorkDate())));
        AddPurchaseOrderLine(PurchaseHeader, PurchaseLine, Item, 100, CalcDate('<+2D>', CalcDate(PlanningStartDate, WorkDate())));

        // Exercise
        Item.SetFilter("No.", Item."No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        AssertNumberOfLinesForItem(Item, 3);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::"Change Qty.", 0D, CalcDate(PlanningStartDate, WorkDate()), 100, 3,
          RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Cancel, 0D, CalcDate('<1D>', CalcDate(PlanningStartDate, WorkDate())), 100, 0,
          RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::Cancel, 0D, CalcDate('<2D>', CalcDate(PlanningStartDate, WorkDate())), 100, 0,
          RequisitionLine."Ref. Order Type"::Purchase, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HQ123245YK8R_SST_and_ROP()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        TestSetup();
        MaxQtyItemSetup(Item, 9, 10, 0, '<0D>', 0, 8, '<0D>', 0);

        // Exercise
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate(PlanningStartDate, WorkDate()), CalcDate(PlanningEndDate, WorkDate()));

        // Verify
        AssertNumberOfLinesForItem(Item, 2);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate(PlanningStartDate, WorkDate()), 0, 8,
          RequisitionLine."Ref. Order Type"::Purchase, 1);
        AssertPlanningLine(Item, RequisitionLine."Action Message"::New, 0D, CalcDate(PlanningStartDate, WorkDate()), 0, 2,
          RequisitionLine."Ref. Order Type"::Purchase, 1);

        FinalAssert(RequisitionLine, Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CaptionOfPlanningRoutingContainsFullDescriptionsOfItemAndOfRequisitionWorksheet()
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        PlanningRoutingLine: Record "Planning Routing Line";
        RequisitionLine: Record "Requisition Line";
        ActualPlanningRoutingLineCaption: Text;
        ExpectedPlanningRoutingLineCaption: Text;
    begin
        // [FEATURE] [Planning] [Routing] [Worksheet] [UT]
        // [SCENARIO 260806] The caption of planning routing contains full descriptions of item and of requisition worksheet.
        Initialize();

        MockRequisitionWkshNameWithDescription(
          RequisitionWkshName,
          CopyStr(
            LibraryUtility.GenerateRandomText(MaxStrLen(RequisitionWkshName.Description)), 1, MaxStrLen(RequisitionWkshName.Description)));

        // [GIVEN] Requisition line with long worksheet name and long description
        MockRequisitionLine(
          RequisitionLine, RequisitionWkshName, RequisitionLine.Type::Item,
          LibraryUtility.GenerateRandomCode(RequisitionLine.FieldNo("No."), DATABASE::"Requisition Line"),
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(RequisitionLine.Description)), 1, MaxStrLen(RequisitionLine.Description)));

        // [WHEN] Open planning routing page
        MockPlanningRoutingLine(PlanningRoutingLine, RequisitionLine);

        // [THEN] Caption of the page contains both worksheet name and desription
        ExpectedPlanningRoutingLineCaption :=
          PlanningCaption(PlanningRoutingLine."Worksheet Batch Name", RequisitionWkshName, RequisitionLine);
        ActualPlanningRoutingLineCaption := PlanningRoutingLine.Caption();
        Assert.AreEqual(
          CopyStr(ExpectedPlanningRoutingLineCaption, 1, MaxStrLen(ExpectedPlanningRoutingLineCaption)),
          CopyStr(ActualPlanningRoutingLineCaption, 1, MaxStrLen(ActualPlanningRoutingLineCaption)), StringsMustBeIdenticalErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CaptionOfPlanningComponentContainsFullDescriptionsOfItemAndOfRequisitionWorksheet()
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        PlanningComponent: Record "Planning Component";
        RequisitionLine: Record "Requisition Line";
        ActualPlanningRoutingLineCaption: Text;
        ExpectedPlanningRoutingLineCaption: Text;
    begin
        // [FEATURE] [Planning] [Routing] [Worksheet] [UT]
        // [SCENARIO 260806] The caption of planning components contains full descriptions of item and of requisition worksheet.
        Initialize();

        MockRequisitionWkshNameWithDescription(
          RequisitionWkshName,
          CopyStr(
            LibraryUtility.GenerateRandomText(MaxStrLen(RequisitionWkshName.Description)), 1, MaxStrLen(RequisitionWkshName.Description)));

        // [GIVEN] Requisition line with long worksheet name and long description
        MockRequisitionLine(
          RequisitionLine, RequisitionWkshName, RequisitionLine.Type::Item,
          LibraryUtility.GenerateRandomCode(RequisitionLine.FieldNo("No."), DATABASE::"Requisition Line"),
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(RequisitionLine.Description)), 1, MaxStrLen(RequisitionLine.Description)));

        // [WHEN] Open planning components page
        MockPlanningComponent(PlanningComponent, RequisitionLine);

        // [THEN] Caption of the page contains both worksheet name and desription
        ExpectedPlanningRoutingLineCaption :=
          PlanningCaption(PlanningComponent."Worksheet Batch Name", RequisitionWkshName, RequisitionLine);
        ActualPlanningRoutingLineCaption := PlanningComponent.Caption();
        Assert.AreEqual(
          CopyStr(ExpectedPlanningRoutingLineCaption, 1, MaxStrLen(ExpectedPlanningRoutingLineCaption)),
          CopyStr(ActualPlanningRoutingLineCaption, 1, MaxStrLen(ActualPlanningRoutingLineCaption)), StringsMustBeIdenticalErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningRoutingLineSetPreviousAndNext()
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        OperationNo: array[3] of Code[10];
        I: Integer;
    begin
        // [FEATURE] [Routing]
        // [SCENARIO 291617] "Next/Previous Operation No." are automatically relinked on deletion of Planning Routing Lines
        Initialize();

        // [GIVEN] Requisition Line with Routing Type "Serial"
        MockRequisitionWkshNameWithDescription(
          RequisitionWkshName,
          CopyStr(
            LibraryUtility.GenerateRandomText(MaxStrLen(RequisitionWkshName.Description)), 1, MaxStrLen(RequisitionWkshName.Description)));
        MockRequisitionLine(
          RequisitionLine,
          RequisitionWkshName,
          RequisitionLine.Type::Item,
          LibraryUtility.GenerateRandomCode(RequisitionLine.FieldNo("No."), DATABASE::"Requisition Line"),
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(RequisitionLine.Description)), 1, MaxStrLen(RequisitionLine.Description)));
        RequisitionLine."Routing Type" := RoutingType::Serial;
        RequisitionLine.Modify();

        // [GIVEN] 3 Planning Routing Lines for the Requisition Line with "Operation No." = 10,20,30
        for I := 1 to ArrayLen(OperationNo) do
            OperationNo[I] := Format(I * 10 + LibraryRandom.RandInt(5));
        MockPlanningRoutingLineWithNos(PlanningRoutingLine, RequisitionLine, OperationNo[1], OperationNo[2], '');
        MockPlanningRoutingLineWithNos(PlanningRoutingLine, RequisitionLine, OperationNo[2], OperationNo[3], OperationNo[1]);
        MockPlanningRoutingLineWithNos(PlanningRoutingLine, RequisitionLine, OperationNo[3], '', OperationNo[2]);

        // [WHEN] Call "SetPreviousAndNext" on the middle Planning Routing Line
        PlanningRoutingLine.Next(-1);
        PlanningRoutingLine.SetPreviousAndNext();

        // [THEN] "Next Operation No." = 30 on the first Prod. Order Routing Line
        PlanningRoutingLine.FindFirst();
        PlanningRoutingLine.TestField("Next Operation No.", OperationNo[3]);

        // [THEN] "Previous Operation No." = 10 on the last Prod. Order Routing Line
        PlanningRoutingLine.FindLast();
        PlanningRoutingLine.TestField("Previous Operation No.", OperationNo[1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoDemandsWithinLeadTimeCalculationDoNotCauseOverflow()
    var
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        Location: Record Location;
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        RequisitionLine: Record "Requisition Line";
        LeadTimeCalculation: DateFormula;
        ShipDate1: Date;
        ShipDate2: Date;
        StartDate: Date;
        EndDate: Date;
        MaxInventory: Integer;
        ReorderPoint: Integer;
        Qty1: Integer;
        Qty2: Integer;
    begin
        // [SCENARIO 314353] When Demand Shipment Dates are within the Lead Time Calculation in Sales Order and qtys do not cause inventory underflow
        // [SCENARIO 314353] Then no additional planning suggestions are generated after 1st one is carried out
        Initialize();
        Evaluate(LeadTimeCalculation, '<20D>');
        ShipDate1 := WorkDate();
        ShipDate2 := CalcDate('<7D>', WorkDate());
        StartDate := CalcDate('<-CY>', WorkDate());
        EndDate := CalcDate('<CY>', WorkDate());
        MaxInventory := 43;
        ReorderPoint := 35;
        Qty1 := 15;
        Qty2 := 10;

        // [GIVEN] Item had SKU with Reordering Policy = Max. Qty; Lead Time Calculation = 20D, Max. Inventory = 43 PCS and Reorder Point = 35 PCS
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, Location.Code, Item."No.", '');
        StockkeepingUnit.Validate("Replenishment System", StockkeepingUnit."Replenishment System"::Purchase);
        StockkeepingUnit.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        StockkeepingUnit.Validate("Reordering Policy", StockkeepingUnit."Reordering Policy"::"Maximum Qty.");
        StockkeepingUnit.Validate("Lead Time Calculation", LeadTimeCalculation);
        StockkeepingUnit.Validate("Maximum Inventory", MaxInventory);
        StockkeepingUnit.Validate("Reorder Point", ReorderPoint);
        StockkeepingUnit.Modify(true);

        // [GIVEN] Sales Order with 2 Lines: 15 PCS and Shipment Date = 11/07/2021 and 10 PCS and Shipment Date 26/07/2021
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(), Item."No.", Qty1, Location.Code,
          ShipDate1);
        LibrarySales.CreateSalesLineWithShipmentDate(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", ShipDate2, Qty2);

        // [GIVEN] Calculated Regenerative Plan for this Item for the year 2021
        // [GIVEN] 3 Requisition Lines were created: 1st with 43 PCS, 2nd with 15 PCS and the last one with 10 PCS
        // [GIVEN] Carried out all action messages
        LibraryPlanning.CalcRegenPlanForPlanWkshPlanningParams(Item, StartDate, EndDate, true);
        RequisitionLine.SetRange("No.", Item."No.");
        Assert.RecordCount(RequisitionLine, 3);
        RequisitionLine.CalcSums(Quantity);
        RequisitionLine.TestField(Quantity, MaxInventory + Qty1 + Qty2);
        RequisitionLine.ModifyAll("Accept Action Message", true);
        RequisitionLine.FindFirst();
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);

        // [WHEN] Calculate Regenerative Plan again
        LibraryPlanning.CalcRegenPlanForPlanWkshPlanningParams(Item, StartDate, EndDate, true);

        // [THEN] No new Requisition Lines created
        Assert.RecordIsEmpty(RequisitionLine);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandlerWithStopAndShowFirstError')]
    [Scope('OnPrem')]
    procedure FixedReorderPlanningWhenReorderQtyBlankAndStopAndShowFirstError()
    var
        Item: Record Item;
    begin
        // [SCENARIO 324730] When Planning with Fixed Reorder Qty. and Reorder Quantity is zero in Item without SKU
        // [SCENARIO 324730] Then error message refers to Item No. when Stop and Show First Error is enabled.
        Initialize();

        // [GIVEN] Item 1000 had Reordering Policy = Fixed Reorder Qty. and Reorder Quantity = <zero>; Reorder Point = 20
        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Fixed Reorder Qty.");
        Item.Validate("Reorder Quantity", 0);
        Item.Validate("Reorder Point", LibraryRandom.RandInt(10));
        Item.Modify(true);
        Commit();

        // [WHEN] Calculate Regenerative Plan for this year with Stop and Show First Error enabled
        asserterror CalcRegenPlanWithStopAndShowFirstError(Item, CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate()));

        // [THEN] Error 'Reorder Quantity must have a value in Item: No.=1000. It cannot be zero or empty.'
        Assert.ExpectedTestFieldError(Item.FieldCaption("Reorder Quantity"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningWithLeadTimeCalculationDoesNotSuggestAboveMaxQty()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        LeadTimeCalculation: DateFormula;
        MaxQty: Decimal;
        InvtQty: Decimal;
        SalesQty: Decimal;
    begin
        // [FEATURE] [Maximum Inventory] [Lead Time Calculation]
        // [SCENARIO 343547] Planning engine must keep the inventory on the maximum level when the reorder point is crossed more than once within Lead Time Calculation period.
        Initialize();
        Evaluate(LeadTimeCalculation, '<60D>');
        MaxQty := 50;
        InvtQty := 25;
        SalesQty := 5;

        // [GIVEN] Item with "Maximum Qty." reordering policy.
        // [GIVEN] Max. inventory = 50. Reorder point = 46.
        // [GIVEN] Lead time calculation = 60 days.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Maximum Qty.");
        Item.Validate("Lead Time Calculation", LeadTimeCalculation);
        Item.Validate("Maximum Inventory", MaxQty);
        Item.Validate("Reorder Point", MaxQty - SalesQty + 1);
        Item.Modify(true);

        // [GIVEN] Post 25 qty. to the inventory.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', InvtQty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Two sales lines each for 5 qty.
        // [GIVEN] The reorder point will thus be crossed three times - for the inventory and each sales line.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLineWithShipmentDate(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", WorkDate() + 5, SalesQty);
        LibrarySales.CreateSalesLineWithShipmentDate(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", WorkDate() + 10, SalesQty);

        // [WHEN] Calculate regenerative plan starting from WORKDATE.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), CalcDate('<CY>', WorkDate()));

        // [THEN] Three planning lines are created.
        // [THEN] The resulting inventory with the consideration of the planning lines is 50 qty. (= Max. Inventory of the item).
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");
        RequisitionLine.CalcSums(Quantity);
        Assert.RecordCount(RequisitionLine, 3);
        Assert.AreEqual(MaxQty, InvtQty - 2 * SalesQty + RequisitionLine.Quantity, 'Wrong planned quantity.');
    end;

    [Test]
    [HandlerFunctions('MessageHandlers')]
    procedure ItemOrderTrackingPolicyTrackingOnlyAndPlanningReservationForDropShipItem()
    var
        Customer: Record Customer;
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        Location: Record Location;
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SalesHeader: array[2] of Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        Vendor: Record Vendor;
    begin
        // [SCENARIO 556539] Item setup for Order Tracking Policy in Tracking Only and Planning for this Drop Ship item.
        Initialize();

        // [GIVEN] Create a Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create an Item and Validate Reorder Policy, Tracking Policy, Reorder point and Quantity.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Fixed Reorder Qty.");
        Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking Only");
        Item.Validate("Reorder Point", LibraryRandom.RandIntInRange(70, 75));
        Item.Validate("Reorder Quantity", LibraryRandom.RandIntInRange(120, 120));
        Item.Validate("Vendor No.", Vendor."No.");
        Item.Modify(true);

        // [GIVEN] Create Location with Inventory Posting Setup.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Validate Component at Location in Manufacturing Setup.
        LibraryManufacturing.SetComponentsAtLocation(Location.Code);

        // [GIVEN] Select Item Journal Template.
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);

        // [GIVEN] Select Item Journal Batch Name.
        LibraryInventory.SelectItemJournalBatchName(
          ItemJournalBatch,
          ItemJournalBatch."Template Type"::Item,
          ItemJournalTemplate.Name);

        // [GIVEN] Create an Item Journal.
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);

        // [GIVEN] Create an Item Journal Line and Validate Location Code in Item Journal Line.
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine,
          ItemJournalBatch."Journal Template Name",
          ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.",
          Item."No.",
          LibraryRandom.RandIntInRange(5, 5));
        ItemJournalLine.Validate("Location Code", Location.Code);
        ItemJournalLine.Modify(true);

        // [GIVEN] Post an Item Journal.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create an Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create a Sales Order with Drop Shipment.
        CreateSalesOrderWithDropShipment(SalesHeader[1], SalesLine[1], Location, Customer, Item);

        // [GIVEN] Create Requisition Worksheet Name and Calculate Plan.
        CreateRequisitionWkshNameAndCalculatePlan(RequisitionWkshName, Item);

        // [GIVEN] Find REquisition Line.
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");
        RequisitionLine.FindFirst();

        // [GIVEN] Run Get Sales Order in Requisition Line.
        RunGetSalesOrders(SalesLine[1], RequisitionLine);

        // [GIVEN] Run Carry Out Requisition Line.
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');

        // [GIVEN] Post Sales Order for Shipment Only.
        LibrarySales.PostSalesDocument(SalesHeader[1], true, false);

        // [GIVEN] Create Sales Order with Drop Shipment.
        CreateSalesOrderWithDropShipment(SalesHeader[2], SalesLine[2], Location, Customer, Item);

        // [GIVEN] Create Requisition Worksheet Name.
        CreateRequisitionWkshNameAndCalculatePlan(RequisitionWkshName, Item);

        // [GIVEN] Create Requisition Line and Validate Worksheet Template Name, Journal Batch Name, Type and No. in Requisition Line.
        RequisitionLine.Init();
        RequisitionLine.Validate("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.Validate("Journal Batch Name", RequisitionWkshName.Name);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", Item."No.");
        RequisitionLine.Insert(true);

        // [GIVEN] Run Get Sales Orders in Requisition Line.
        RunGetSalesOrders(SalesLine[2], RequisitionLine);

        // [GIVEN] Find the Requisition Line.
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");
        RequisitionLine.SetRange("Location Code", Location.Code);
        RequisitionLine.FindFirst();

        // [GIVEN] Run Carry out Requisition Worksheet.
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');

        // [WHEN] Post Sales Order with Shipment only.
        LibrarySales.PostSalesDocument(SalesHeader[2], true, false);

        // [THEN] Sales Order should be Posted and Sales Shipment Line is created.
        SalesShipmentLine.SetRange("No.", Item."No.");
        SalesShipmentLine.SetRange("Location Code", Location.Code);
        SalesShipmentLine.FindFirst();
        Assert.RecordIsNotEmpty(SalesShipmentLine);
    end;

    [Test]
    [HandlerFunctions('MessageHandlers')]
    [Scope('OnPrem')]
    procedure SOWithSpecOrderPurchCodeAndLotforLotItemWithTrackOnlyOrderTrackPolicyIsPostedAfterCalcRegPlan()
    var
        Customer: Record Customer;
        Item: Record Item;
        Vendor: Record Vendor;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Purchasing: Record Purchasing;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO 558518] Sales Order having Special Order Purchasing Code and Item with 
        // Order Tracking Policy as Tracking Only and Reorder Policy as Lot-for-Lot is posted 
        // Without any error after running Calculate Regenrative Plan.
        Initialize();

        // [GIVEN] Create a Location with Inventory Posting Setup.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create a Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create an Item and Validate Reordering Policy, 
        // Order Tracking Policy and Vendor No.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking Only");
        Item.Validate("Vendor No.", Vendor."No.");
        Item.Modify(true);

        // [GIVEN] Create a Purchase Header.
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader,
            PurchaseHeader."Document Type"::Order,
            Vendor."No.");

        // [GIVEN] Create a Purchase Line.
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine,
            PurchaseHeader,
            PurchaseLine.Type::Item,
            Item."No.",
            LibraryRandom.RandInt(0));

        // [GIVEN] Validate Location Code.
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);

        // [GIVEN] Release Purchase Order.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Create a Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create a Purchasing and Validate Special Order.
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Special Order", true);
        Purchasing.Modify(true);

        // [GIVEN] Create a Sales Header.
        LibrarySales.CreateSalesHeader(
            SalesHeader,
            SalesHeader."Document Type"::Order,
            Customer."No.");

        // [GIVEN] Create a Sales Line and Validate Location Code and Purchasing Code.
        LibrarySales.CreateSalesLine(
            SalesLine,
            SalesHeader,
            SalesLine.Type::Item,
            Item."No.",
            LibraryRandom.RandInt(0));

        // [GIVEN] Validate Location Code and Purchasing Code in Sales Line.
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Validate("Purchasing Code", Purchasing.Code);
        SalesLine.Modify(true);

        // [GIVEN] Release Sales Order.
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Get Sales Order On Requisition Worksheet and run Carry Our Action Msg.
        GetSalesOrderOnReqWkshtAndCarryOutActionMsg(Item."No.");

        // [GIVEN] Reopen Sales Order.
        LibrarySales.ReopenSalesDocument(SalesHeader);

        // [GIVEN] Validate Planned Shipment Date in Sales Line.
        SalesLine.Validate("Planned Shipment Date", CalcDate('<+14D>', SalesLine."Planned Shipment Date"));

        // [GIVEN] Release Sales Order.
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(
            Item,
            CalcDate('<-CY>', WorkDate()),
            CalcDate('<CY>', WorkDate()));

        // [WHEN] Post Sales Order.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Sales Header is not found.
        Assert.IsFalse(
            SalesHeader.Get(SalesHeader."Document Type"::Order, SalesHeader."No."),
            SalesHeaderMustNotBeFoundErr);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Planning");
        LibraryVariableStorage.Clear();

        LibraryApplicationArea.EnableEssentialSetup();

        // Initialize setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Planning");

        // Setup Demonstration data.
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        GlobalSetup();

        Evaluate(DaysInMonthFormula, Format('<+%1D>', CalcDate('<1M>') - Today));
        Evaluate(PlanningStartDate, '<+2D>');
        Evaluate(PlanningEndDate, '<+11M>');

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Planning");
    end;

    local procedure CalcRegenPlanWithStopAndShowFirstError(Item: Record Item; FromDate: Date; ToDate: Date)
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        CalculatePlanPlanWksh: Report "Calculate Plan - Plan. Wksh.";
    begin
        LibraryPlanning.SelectRequisitionWkshName(RequisitionWkshName, RequisitionWkshName."Template Type"::Planning);
        CalculatePlanPlanWksh.InitializeRequest(FromDate, ToDate, true);
        CalculatePlanPlanWksh.SetTemplAndWorksheet(RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name, true);
        Item.SetRange("No.", Item."No.");
        CalculatePlanPlanWksh.SetTableView(Item);
        CalculatePlanPlanWksh.UseRequestPage(true);
        CalculatePlanPlanWksh.Run();
    end;

    local procedure PlanningCaption(WorksheetBatchName: Code[10]; RequisitionWkshName: Record "Requisition Wksh. Name"; RequisitionLine: Record "Requisition Line"): Text
    begin
        exit(
          StrSubstNo('%1 %2 %3 %4 %5',
            WorksheetBatchName, RequisitionWkshName.Description,
            RequisitionLine.Type, RequisitionLine."No.", RequisitionLine.Description));
    end;

    local procedure MockRequisitionWkshNameWithDescription(var RequisitionWkshName: Record "Requisition Wksh. Name"; Description: Text[100])
    begin
        RequisitionWkshName."Worksheet Template Name" :=
          LibraryUtility.GenerateRandomCode(RequisitionWkshName.FieldNo("Worksheet Template Name"), DATABASE::"Requisition Wksh. Name");
        RequisitionWkshName.Name :=
          LibraryUtility.GenerateRandomCode(RequisitionWkshName.FieldNo(Name), DATABASE::"Requisition Wksh. Name");
        RequisitionWkshName.Description := Description;
        RequisitionWkshName.Insert();
    end;

    local procedure MockRequisitionLine(var RequisitionLine: Record "Requisition Line"; RequisitionWkshName: Record "Requisition Wksh. Name"; Type: Enum "Requisition Line Type"; No: Code[20]; Description: Text[100])
    begin
        RequisitionLine."Worksheet Template Name" := RequisitionWkshName."Worksheet Template Name";
        RequisitionLine."Journal Batch Name" := RequisitionWkshName.Name;
        RequisitionLine."Line No." := LibraryUtility.GetNewRecNo(RequisitionLine, RequisitionLine.FieldNo("Line No."));
        RequisitionLine.Type := Type;
        RequisitionLine."No." := No;
        RequisitionLine.Description := Description;
        RequisitionLine.Insert();
    end;

    local procedure MockPlanningRoutingLine(var PlanningRoutingLine: Record "Planning Routing Line"; RequisitionLine: Record "Requisition Line")
    begin
        PlanningRoutingLine."Worksheet Template Name" := RequisitionLine."Worksheet Template Name";
        PlanningRoutingLine."Worksheet Batch Name" := RequisitionLine."Journal Batch Name";
        PlanningRoutingLine."Worksheet Line No." := RequisitionLine."Line No.";
        PlanningRoutingLine.Insert();

        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
    end;

    local procedure MockPlanningRoutingLineWithNos(var PlanningRoutingLine: Record "Planning Routing Line"; RequisitionLine: Record "Requisition Line"; OperationNo: Code[10]; NextOperationNo: Code[10]; PrevOperationNo: Code[10])
    begin
        PlanningRoutingLine."Worksheet Template Name" := RequisitionLine."Worksheet Template Name";
        PlanningRoutingLine."Worksheet Batch Name" := RequisitionLine."Journal Batch Name";
        PlanningRoutingLine."Worksheet Line No." := RequisitionLine."Line No.";
        PlanningRoutingLine."Operation No." := OperationNo;
        PlanningRoutingLine."Next Operation No." := NextOperationNo;
        PlanningRoutingLine."Previous Operation No." := PrevOperationNo;
        PlanningRoutingLine.Insert();

        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
    end;

    local procedure MockPlanningComponent(var PlanningComponent: Record "Planning Component"; RequisitionLine: Record "Requisition Line")
    begin
        PlanningComponent."Worksheet Template Name" := RequisitionLine."Worksheet Template Name";
        PlanningComponent."Worksheet Batch Name" := RequisitionLine."Journal Batch Name";
        PlanningComponent."Worksheet Line No." := RequisitionLine."Line No.";
        PlanningComponent.Insert();

        PlanningComponent.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningComponent.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        PlanningComponent.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
    end;

    local procedure FindPurchasingCode(): Code[10]
    var
        Purchasing: Record Purchasing;
        RecordRef: RecordRef;
    begin
        Purchasing.Init();
        Purchasing.SetRange("Drop Shipment", true);
        RecordRef.GetTable(Purchasing);
        LibraryUtility.FindRecord(RecordRef);
        RecordRef.SetTable(Purchasing);
        exit(Purchasing.Code);
    end;

    local procedure RunGetSalesOrders(SalesLine: Record "Sales Line"; RequisitionLine: Record "Requisition Line")
    var
        GetSalesOrders: Report "Get Sales Orders";
        RetrieveDimensions: Option Item,"Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type");
        SalesLine.SetRange("Document No.", SalesLine."Document No.");
        Clear(GetSalesOrders);
        GetSalesOrders.SetTableView(SalesLine);
        GetSalesOrders.InitializeRequest(RetrieveDimensions::"Sales Line");
        GetSalesOrders.SetReqWkshLine(RequisitionLine, 0);
        GetSalesOrders.UseRequestPage(false);
        GetSalesOrders.RunModal();
    end;

    local procedure CreateSalesOrderWithDropShipment(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Location: Record Location; Customer: Record Customer; Item: Record Item)
    begin
        LibrarySales.CreateSalesHeader(
          SalesHeader,
          SalesHeader."Document Type"::Order,
          Customer."No.");
        SalesHeader.Validate("Location Code", Location.Code);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          Item."No.", LibraryRandom.RandIntInRange(500, 2));
        SalesLine.Validate("Purchasing Code", FindPurchasingCode());
        SalesLine.Modify(true);
    end;

    local procedure CreateRequisitionWkshNameAndCalculatePlan(var RequisitionWkshName: Record "Requisition Wksh. Name"; Item: Record Item)
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::"Req.");
        ReqWkshTemplate.SetRange(Recurring, false);
        ReqWkshTemplate.FindFirst();
        ReqWkshTemplate."Increment Batch Name" := true;
        ReqWkshTemplate.Modify();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        LibraryPlanning.CalculatePlanForReqWksh(Item, ReqWkshTemplate.Name, RequisitionWkshName.Name, WorkDate() - LibraryRandom.RandIntInRange(365, 365), WorkDate());
    end;

    local procedure GetSalesOrderOnReqWkshtAndCarryOutActionMsg(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::"Req.");
        ReqWkshTemplate.FindFirst();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, ReqWkshTemplate.Name, RequisitionWkshName.Name);
        LibraryPlanning.GetSpecialOrder(RequisitionLine, ItemNo);
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text[1024])
    var
        DequeueVariable: Variant;
        LocalMessage: Text[1024];
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        LocalMessage := DequeueVariable;
        Assert.IsTrue(StrPos(Msg, LocalMessage) > 0, Msg);
    end;

    [MessageHandler]
    procedure MessageHandlers(Msg: Text[1024])
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculatePlanPlanWkshRequestPageHandlerWithStopAndShowFirstError(var CalculatePlanPlanWksh: TestRequestPage "Calculate Plan - Plan. Wksh.")
    begin
        CalculatePlanPlanWksh.NoPlanningResiliency.SetValue(true);
        CalculatePlanPlanWksh.OK().Invoke();
    end;
}

