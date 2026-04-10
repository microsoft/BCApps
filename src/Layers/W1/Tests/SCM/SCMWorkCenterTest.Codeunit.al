codeunit 137800 "SCM Work Center Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Manufacturing] [SCM]
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPatterns: Codeunit "Library - Patterns";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPlanning: Codeunit "Library - Planning";
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        ShopCalendarMgt: Codeunit "Shop Calendar Management";
        IsInitialized: Boolean;
        ProdOrderNeedQtyErr: Label 'Wrong "Prod. Order Need (Qty.)" value';
        ProdOrderRtngLineDateErr: Label 'Wrong "Prod. Order Routing Line" Dates';
        ReqLineDatesErr: Label 'Wrong "Requisition Line" dates';
        ProdOrderCompDatesErr: Label 'Wrong "Prod. Order Component" dates';
        ProdOrderCapNeedRoundErr: Label 'Wrong "Prod Order Capacity Need" roundings';
        ProdOrderCapNeedDateInconsitencyErr: Label '''Prod. Order Capacity Need" DateTime values inconsistency';

    [Test]
    [Scope('OnPrem')]
    procedure ThirdShiftTimeRounding()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        RoutingLine: Record "Routing Line";
        MachineCenterNo: Code[20];
        WorkCenterNo: Code[20];
        SetupTime: Decimal;
        RunTime: Decimal;
        Quantity: Decimal;
        AllocatedTotal: Decimal;
        DayCapacity: Decimal;
        LastDayAllocated: Decimal;
        NumOfDaysNeeded: Integer;
        DayNum: Integer;
        CurrentDate: Date;
    begin
        // [SCENARIO] Verify Production Order Allocation Qty. on several days

        Initialize();
        UpdateMfgSetup(080000T, 230000T);
        WorkCenter.Init();
        SetupTime := 120.5;
        RunTime := 0.16123;
        Quantity := 45236;

        WorkCenterNo := CreateWorkCenter(CapacityUnitOfMeasure.Type::Minutes, CreateThreeShiftsShopCalendar(), WorkDate());
        MachineCenterNo := CreateMachineCenter(WorkCenterNo, WorkDate());
        CreateMachineCenterCCR(MachineCenterNo);
        CreateItem(Item, CreateSimpleRouting(RoutingLine.Type::"Machine Center", MachineCenterNo, SetupTime, RunTime, 0, 0));
        CreateProdOrder(Item, Quantity, WorkDate());

        // Prepare expected values
        DayCapacity := 24 * 60;
        LastDayAllocated := 23 * 60;
        AllocatedTotal :=
          Round(SetupTime + RunTime * Quantity, WorkCenter."Calendar Rounding Precision");
        NumOfDaysNeeded := Round(AllocatedTotal / DayCapacity, 1, '>');
        CurrentDate := CalcDate('<-1D>', WorkDate());

        // Verify Allocation Load per Day starting from Ending Day
        VerifyDayAllocatedQty(MachineCenterNo, CurrentDate, AllocatedTotal, LastDayAllocated);
        for DayNum := NumOfDaysNeeded - 1 downto 2 do
            VerifyDayAllocatedQty(MachineCenterNo, CurrentDate, AllocatedTotal, DayCapacity);
        VerifyDayAllocatedQty(MachineCenterNo, CurrentDate, AllocatedTotal, AllocatedTotal);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderCalcCapBackWaitTime()
    var
        Item: Record Item;
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        RoutingLine: Record "Routing Line";
        ProdOrderLine: Record "Prod. Order Line";
        MachineCenterNo: Code[20];
        WorkCenterNo: Code[20];
        ShopCalendarCode: Code[10];
        WaitTime: Decimal;
        DueDate: Date;
        StartingDate: Date;
        EndingDate: Date;
        MiddleDate: Date;
        Time: Time;
    begin
        // [SCENARIO] Verify Prod. Order Routing Line's dates when Wait Time is set

        Initialize();
        WaitTime := 15; // value is specific for rounding issues
        DueDate := CalcDate('<CW+5D>', WorkDate()); // next friday

        ShopCalendarCode := FindShopCalendar();
        WorkCenterNo := CreateWorkCenter(CapacityUnitOfMeasure.Type::Days, ShopCalendarCode, DueDate);
        MachineCenterNo := CreateMachineCenter(WorkCenterNo, DueDate);
        CreateMachineCenterCCR(MachineCenterNo);
        CreateItem(Item, CreateTwoLinesRouting(RoutingLine.Type::"Machine Center", MachineCenterNo, 0, 0, WaitTime, 0));

        CreateProdOrder(Item, LibraryRandom.RandDec(100, 2), DueDate);

        EndingDate := CalcDate('<-1D>', DueDate);
        StartingDate := CalcDate(StrSubstNo('<-%1D>', WaitTime * 2), EndingDate);
        MiddleDate := CalcDate(StrSubstNo('<-%1D>', WaitTime), EndingDate);

        ProdOrderLine.SetRange("Item No.", Item."No.");
        ProdOrderLine.FindFirst();
        Time := ProdOrderLine."Ending Time";

        VerifyFirstProdOrderMachineCenterRtngLineDates(MachineCenterNo, StartingDate, Time, MiddleDate, Time);
        VerifyLastProdOrderMachineCenterRtngLineDates(MachineCenterNo, MiddleDate, Time, EndingDate, Time);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemProdBOMSalesOrderAndPlanning()
    var
        WorkCenterNo: array[2] of Code[20];
        ParentItemNo: Code[20];
        ChildItemNo: array[2] of Code[20];
        CompProdTime: Decimal;
        ItemProdDate: Date;
        CompProdDate: Date;
        WorkDayEndTime: Time;
        StartingTime: Time;
    begin
        // [SCENARIO] Verify Routing Dates in case of Item with Prod. BOM after Sales Order and Planning Worksheet Reg. Plan.

        ItemProdBOMScenario(
          WorkCenterNo, ParentItemNo, ChildItemNo, ItemProdDate, CompProdDate, WorkDayEndTime, CompProdTime, false, false);

        StartingTime := WorkDayEndTime - CompProdTime;

        VerifyReqLineDates(ParentItemNo, ItemProdDate, StartingTime, ItemProdDate, WorkDayEndTime);
        VerifyReqLineDates(ChildItemNo[1], CompProdDate, StartingTime, CompProdDate, WorkDayEndTime);
        VerifyReqLineDates(ChildItemNo[2], CompProdDate, StartingTime, CompProdDate, WorkDayEndTime);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemProdBOMSalesOrderAndPlanningWithCCR()
    var
        WorkCenterNo: array[2] of Code[20];
        ParentItemNo: Code[20];
        ChildItemNo: array[2] of Code[20];
        CompProdTime: Decimal;
        ItemProdDate: Date;
        CompProdDate: Date;
        WorkDayEndTime: Time;
        StartingTime: array[2] of Time;
    begin
        // [SCENARIO] Verify Routing Dates in case of Item with Prod. BOM and CCR after Sales Order and Planning Worksheet Reg. Plan.

        ItemProdBOMScenario(
          WorkCenterNo, ParentItemNo, ChildItemNo, ItemProdDate, CompProdDate, WorkDayEndTime, CompProdTime, false, true);

        StartingTime[1] := WorkDayEndTime - CompProdTime;
        StartingTime[2] := StartingTime[1] - CompProdTime;

        VerifyReqLineDates(ParentItemNo, ItemProdDate, StartingTime[1], ItemProdDate, WorkDayEndTime);
        VerifyReqLineDates(ChildItemNo[1], CompProdDate, StartingTime[1], CompProdDate, WorkDayEndTime);
        VerifyReqLineDates(ChildItemNo[2], CompProdDate, StartingTime[2], CompProdDate, StartingTime[1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemProdBOMProdOrder()
    var
        WorkCenterNo: array[2] of Code[20];
        ParentItemNo: Code[20];
        ChildItemNo: array[2] of Code[20];
        CompProdTime: Decimal;
        ItemProdDate: Date;
        CompProdDate: Date;
        WorkDayEndTime: Time;
        StartingTime: Time;
    begin
        // [SCENARIO] Verify Routing Dates in case of Item with Prod. BOM after Prod. Order

        ItemProdBOMScenario(
          WorkCenterNo, ParentItemNo, ChildItemNo, ItemProdDate, CompProdDate, WorkDayEndTime, CompProdTime, true, false);

        StartingTime := WorkDayEndTime - CompProdTime;

        VerifyFirstProdOrderWorkCenterRtngLineDates(WorkCenterNo[1], ItemProdDate, StartingTime, ItemProdDate, WorkDayEndTime);
        VerifyProdOrderComponenDates(ChildItemNo[1], ItemProdDate, StartingTime);
        VerifyProdOrderComponenDates(ChildItemNo[2], ItemProdDate, StartingTime);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemProdBOMProdOrderWithCCR()
    var
        WorkCenterNo: array[2] of Code[20];
        ParentItemNo: Code[20];
        ChildItemNo: array[2] of Code[20];
        CompProdTime: Decimal;
        ItemProdDate: Date;
        CompProdDate: Date;
        WorkDayEndTime: Time;
        StartingTime: Time;
    begin
        // [SCENARIO] Verify Routing Dates in case of Item with Prod. BOM and CCR after Prod. Order

        ItemProdBOMScenario(
          WorkCenterNo, ParentItemNo, ChildItemNo, ItemProdDate, CompProdDate, WorkDayEndTime, CompProdTime, true, true);

        StartingTime := WorkDayEndTime - CompProdTime;

        VerifyFirstProdOrderWorkCenterRtngLineDates(WorkCenterNo[1], ItemProdDate, StartingTime, ItemProdDate, WorkDayEndTime);
        VerifyProdOrderComponenDates(ChildItemNo[1], ItemProdDate, StartingTime);
        VerifyProdOrderComponenDates(ChildItemNo[2], ItemProdDate, StartingTime);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FourShiftTimeRounding()
    var
        Item: array[4] of Record Item;
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        RoutingLine: Record "Routing Line";
        MachineCenterNo: array[4] of Code[20];
        WorkCenterNo: array[4] of Code[20];
        ShopCalendarCode: Code[10];
        RoutingNo: Code[20];
        SetupTime: Decimal;
        RunTime: Decimal;
        WaitTime: Decimal;
        MoveTime: Decimal;
        Quantity: Decimal;
        ItemNoFilter: Text;
        MachineCenterNoFilter: Text;
        i: Integer;
    begin
        // [FEATURE] [Capacity Constrained Resource] [Planning Worksheet]
        // [SCENARIO] Planning worksheet creates sequential production orders with consistent starting/ending dates when capacity constrained resource is used in production

        Initialize();
        UpdateMfgSetup(000000T, 235959T);
        SetupTime := 19;
        RunTime := 29;
        WaitTime := 39;
        MoveTime := 59;
        Quantity := 17;

        ShopCalendarCode := CreateFourShiftsShopCalendar();
        for i := 1 to 4 do begin
            WorkCenterNo[i] := CreateWorkCenter(CapacityUnitOfMeasure.Type::Minutes, ShopCalendarCode, WorkDate());
            MachineCenterNo[i] := CreateMachineCenter(WorkCenterNo[i], WorkDate());
        end;
        CreateMachineCenterCCR(MachineCenterNo[2]);

        RoutingNo := CreateFourLinesRouting(RoutingLine.Type::"Machine Center", MachineCenterNo, SetupTime, RunTime, WaitTime, MoveTime);
        for i := 1 to 4 do begin
            CreateItem(Item[i], RoutingNo);
            CreateReleaseSalesOrder(Item[i], Quantity, WorkDate());
        end;

        ItemNoFilter := StrSubstNo('%1|%2|%3|%4', Item[1]."No.", Item[2]."No.", Item[3]."No.", Item[4]."No.");
        Item[1].SetFilter("No.", ItemNoFilter);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item[1], WorkDate(), WorkDate());
        CarryOutActionFirmPlannedProdOrder(ItemNoFilter);

        MachineCenterNoFilter :=
          StrSubstNo('%1|%2|%3|%4', MachineCenterNo[1], MachineCenterNo[2], MachineCenterNo[3], MachineCenterNo[4]);
        VerifyProdOrderCapNeedRoundingAndDateConsistency(MachineCenterNoFilter);
        VerifyProdOrderCapNeedZeroAllocatedTimeNotExist(MachineCenterNoFilter);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvailableCapacityRoundedWhenRefreshingProdOrder()
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        RoutingLine: Record "Routing Line";
        Item: Record Item;
        ProdOrderCapNeed: Record "Prod. Order Capacity Need";
        WorkCenterNo: Code[20];
        WorkCenterCriticalLoad: Integer;
    begin
        // [FEATURE] [Capacity Constrained Resource]
        // [SCENARIO] Prodution order can be refreshed when allocated time is rounded due to capacity constrained resource restriction

        // [GIVEN] Create work center "W" with a capacity constraint, critical load = 97%
        WorkCenterNo := CreateWorkCenter(CapacityUnitOfMeasure.Type::Days, CreateThreeShiftsShopCalendar(), WorkDate());
        WorkCenterCriticalLoad := 77;
        CreateWorkCenterCCR(WorkCenterNo, WorkCenterCriticalLoad);
        // [GIVEN] Create routing with work center "W"
        CreateItem(Item, CreateSimpleRouting(RoutingLine.Type::"Work Center", WorkCenterNo, 0, 1, 0, 0));
        // [WHEN] Create and refresh production order
        CreateProdOrder(Item, 1, WorkDate());

        // [THEN] Production order successfully refreshed
        ProdOrderCapNeed.SetRange("Work Center No.", WorkCenterNo);
        ProdOrderCapNeed.SetRange(Date, CalcDate('<-1D>', WorkDate()));
        ProdOrderCapNeed.CalcSums("Allocated Time");
        Assert.AreNearlyEqual(WorkCenterCriticalLoad / 100, ProdOrderCapNeed."Allocated Time", 0.01, ProdOrderCapNeedRoundErr);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Work Center Test");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Work Center Test");
        IsInitialized := true;

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        ShopCalendarMgt.ClearInternals(); // clear single instance codeunit vars to avoid influence of other test codeunits
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Work Center Test");
    end;

    local procedure ItemProdBOMScenario(var WorkCenterNo: array[2] of Code[20]; var ParentItemNo: Code[20]; var ChildItemNo: array[2] of Code[20]; var ItemProdDate: Date; var CompProdDate: Date; var WorkDayEndTime: Time; var CompProdTime: Decimal; IsCreateProdOrder: Boolean; UseCCR: Boolean)
    var
        ParentItem: Record Item;
        ChildItem: array[2] of Record Item;
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        RoutingLine: Record "Routing Line";
        ShopCalendarCode: Code[10];
        OrderDate: Date;
        RunTime: Decimal;
        Quantity: Decimal;
        i: Integer;
    begin
        Initialize();
        RunTime := 60; // values are specific
        Quantity := 3;
        OrderDate := CalcDate('<CW+5D>', WorkDate()); // next friday

        ShopCalendarCode := FindShopCalendar();
        for i := 1 to 2 do
            WorkCenterNo[i] := CreateWorkCenter(CapacityUnitOfMeasure.Type::Minutes, ShopCalendarCode, OrderDate);

        if UseCCR then
            for i := 1 to 2 do
                CreateWorkCenterCCR(WorkCenterNo[i], 100);

        CreateItem(ParentItem, CreateSimpleRouting(RoutingLine.Type::"Work Center", WorkCenterNo[1], 0, RunTime, 0, 0));
        CreateItem(ChildItem[1], CreateSimpleRouting(RoutingLine.Type::"Work Center", WorkCenterNo[2], 0, RunTime, 0, 0));
        CreateItem(ChildItem[2], CreateSimpleRouting(RoutingLine.Type::"Work Center", WorkCenterNo[2], 0, RunTime, 0, 0));
        CreateProdBOMWithTwoItems(ParentItem, ChildItem[1]."No.", ChildItem[2]."No.");

        if IsCreateProdOrder then
            CreateProdOrder(ParentItem, Quantity, OrderDate)
        else begin
            CreateReleaseSalesOrder(ParentItem, Quantity, OrderDate);
            ParentItem.SetFilter("No.", '%1|%2|%3', ParentItem."No.", ChildItem[1]."No.", ChildItem[2]."No.");
            LibraryPlanning.CalcRegenPlanForPlanWksh(ParentItem, OrderDate, OrderDate);
        end;

        // Calculate Expected values
        ItemProdDate := CalcDate('<-1D>', OrderDate);
        CompProdDate := CalcDate('<-1D>', ItemProdDate);
        WorkDayEndTime := GetShopCalendarEndingTime(ShopCalendarCode);

        ParentItemNo := ParentItem."No.";
        ChildItemNo[1] := ChildItem[1]."No.";
        ChildItemNo[2] := ChildItem[2]."No.";
        CompProdTime := Quantity * RunTime * 60000;
    end;

    local procedure CreateMachineCenter(WorkCenterNo: Code[20]; DueDate: Date): Code[20]
    var
        MachineCenter: Record "Machine Center";
    begin
        LibraryManufacturing.CreateMachineCenter(MachineCenter, WorkCenterNo, 1);
        LibraryManufacturing.CalculateMachCenterCalendar(MachineCenter, CalcDate('<-2M>', DueDate), DueDate);
        exit(MachineCenter."No.");
    end;

    local procedure CreateWorkCenter(UOMType: Enum "Capacity Unit of Measure"; ShopCalendarCode: Code[10]; DueDate: Date): Code[20]
    var
        WorkCenter: Record "Work Center";
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
    begin
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, UOMType);
        WorkCenter.Validate("Unit of Measure Code", CapacityUnitOfMeasure.Code);
        WorkCenter.Validate("Shop Calendar Code", ShopCalendarCode);
        WorkCenter.Validate(Capacity, 1);
        WorkCenter.Modify(true);

        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-2M>', DueDate), DueDate);
        exit(WorkCenter."No.");
    end;

    local procedure CreateThreeShiftsShopCalendar(): Code[10]
    var
        ShopCalendar: Record "Shop Calendar";
        WorkShiftCodes: array[3] of Code[10];
    begin
        LibraryManufacturing.CreateShopCalendarCode(ShopCalendar);
        CreateThreeWorkShifts(WorkShiftCodes);
        UpdateThreeShiftsShopCalendarWorkingDays(ShopCalendar.Code, WorkShiftCodes);
        exit(ShopCalendar.Code);
    end;

    local procedure CreateThreeShiftsShopCalendarWorkDays(ShopCalendarCode: Code[10]; WorkShiftCode: Code[10]; DoW: Integer; WorkShiftNum: Integer)
    var
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        StartingTime: Time;
        EndingTime: Time;
    begin
        GetWorkShiftTimeThreeShifts(StartingTime, EndingTime, WorkShiftNum);
        LibraryManufacturing.CreateShopCalendarWorkingDays(
          ShopCalendarWorkingDays, ShopCalendarCode, DoW, WorkShiftCode, StartingTime, EndingTime);
    end;

    local procedure CreateThreeWorkShifts(var WorkShiftCodes: array[3] of Code[10])
    var
        WorkShift: Record "Work Shift";
        i: Integer;
    begin
        for i := 1 to ArrayLen(WorkShiftCodes) do begin
            LibraryManufacturing.CreateWorkShiftCode(WorkShift);
            WorkShiftCodes[i] := WorkShift.Code;
        end;
    end;

    local procedure CreateFourShiftsShopCalendar(): Code[10]
    var
        ShopCalendar: Record "Shop Calendar";
        WorkShiftCodes: array[4] of Code[10];
    begin
        LibraryManufacturing.CreateShopCalendarCode(ShopCalendar);
        CreateFourWorkShifts(WorkShiftCodes);
        UpdateFourShiftsShopCalendarWorkingDays(ShopCalendar.Code, WorkShiftCodes);
        exit(ShopCalendar.Code);
    end;

    local procedure CreateFourShiftsShopCalendarWorkDays(ShopCalendarCode: Code[10]; WorkShiftCode: Code[10]; DoW: Integer; WorkShiftNum: Integer)
    var
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        StartingTime: Time;
        EndingTime: Time;
    begin
        GetWorkShiftTimeFourShifts(StartingTime, EndingTime, WorkShiftNum);
        LibraryManufacturing.CreateShopCalendarWorkingDays(
          ShopCalendarWorkingDays, ShopCalendarCode, DoW, WorkShiftCode, StartingTime, EndingTime);
    end;

    local procedure CreateFourWorkShifts(var WorkShiftCodes: array[4] of Code[10])
    var
        WorkShift: Record "Work Shift";
        i: Integer;
    begin
        for i := 1 to ArrayLen(WorkShiftCodes) do begin
            LibraryManufacturing.CreateWorkShiftCode(WorkShift);
            WorkShiftCodes[i] := WorkShift.Code;
        end;
    end;

    local procedure CreateMachineCenterCCR(MachineCenterNo: Code[20])
    var
        CapacityConstrainedResource: Record "Capacity Constrained Resource";
    begin
        LibraryManufacturing.CreateCapacityConstrainedResource(
          CapacityConstrainedResource, CapacityConstrainedResource."Capacity Type"::"Machine Center", MachineCenterNo);
        CapacityConstrainedResource.Validate("Critical Load %", 100);
        CapacityConstrainedResource.Modify(true);
    end;

    local procedure CreateWorkCenterCCR(WorkCenterNo: Code[20]; CriticalLoad: Decimal)
    var
        CapacityConstrainedResource: Record "Capacity Constrained Resource";
    begin
        LibraryManufacturing.CreateCapacityConstrainedResource(
          CapacityConstrainedResource, CapacityConstrainedResource."Capacity Type"::"Work Center", WorkCenterNo);
        CapacityConstrainedResource.Validate("Critical Load %", CriticalLoad);
        CapacityConstrainedResource.Modify(true);
    end;

    local procedure CreateSimpleRouting(RoutingLineType: Enum "Capacity Type Routing"; MachineWorkCenterNo: Code[20]; SetupTime: Decimal; RunTime: Decimal; WaitTime: Decimal; MoveTime: Decimal): Code[20]
    var
        RoutingHeader: Record "Routing Header";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingHeader, RoutingLineType, MachineWorkCenterNo, SetupTime, RunTime, WaitTime, MoveTime);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        exit(RoutingHeader."No.");
    end;

    local procedure CreateTwoLinesRouting(RoutingLineType: Enum "Capacity Type Routing"; MachineWorkCenterNo: Code[20]; SetupTime: Decimal; RunTime: Decimal; WaitTime: Decimal; MoveTime: Decimal): Code[20]
    var
        RoutingHeader: Record "Routing Header";
        i: Integer;
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        for i := 1 to 2 do
            CreateRoutingLine(RoutingHeader, RoutingLineType, MachineWorkCenterNo, SetupTime, RunTime, WaitTime, MoveTime);

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        exit(RoutingHeader."No.");
    end;

    local procedure CreateFourLinesRouting(RoutingLineType: Enum "Capacity Type Routing"; MachineWorkCenterNo: array[4] of Code[20]; SetupTime: Decimal; RunTime: Decimal; WaitTime: Decimal; MoveTime: Decimal): Code[20]
    var
        RoutingHeader: Record "Routing Header";
        i: Integer;
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        for i := 1 to 3 do
            CreateRoutingLine(RoutingHeader, RoutingLineType, MachineWorkCenterNo[i], SetupTime, RunTime, WaitTime, MoveTime);
        CreateRoutingLine(RoutingHeader, RoutingLineType, MachineWorkCenterNo[4], 0, 0, 0, 0);

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        exit(RoutingHeader."No.");
    end;

    local procedure CreateRoutingLine(RoutingHeader: Record "Routing Header"; RoutingLineType: Enum "Capacity Type Routing"; MachineWorkCenterNo: Code[20]; SetupTime: Decimal; RunTime: Decimal; WaitTime: Decimal; MoveTime: Decimal)
    var
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '',
          LibraryUtility.GenerateRandomCode(RoutingLine.FieldNo("Operation No."), DATABASE::"Routing Line"),
          RoutingLineType, MachineWorkCenterNo);

        RoutingLine.Validate("Setup Time", SetupTime);
        RoutingLine.Validate("Run Time", RunTime);
        RoutingLine.Validate("Wait Time", WaitTime);
        RoutingLine.Validate("Move Time", MoveTime);
        RoutingLine.Modify();
    end;

    local procedure CreateItem(var Item: Record Item; RoutingHeaderNo: Code[20]): Code[20]
    begin
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::FIFO, LibraryPatterns.RandCost(Item));
        Item.Validate("Routing No.", RoutingHeaderNo);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Reordering Policy", Item."Reordering Policy"::Order);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateProdOrder(Item: Record Item; Quantity: Decimal; DueDate: Date)
    var
        ProductionOrder: Record "Production Order";
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ProductionOrder."Source Type"::Item, Item."No.", Quantity);
        ProductionOrder.SetUpdateEndDate();
        ProductionOrder.Validate("Due Date", DueDate);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, true);
    end;

    local procedure CreateProdBOMWithTwoItems(ParentItem: Record Item; ChildItemNo1: Code[20]; ChildItemNo2: Code[20])
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ParentItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ChildItemNo1, 1);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ChildItemNo2, 1);

        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify();

        ParentItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ParentItem.Modify();
    end;

    local procedure CreateReleaseSalesOrder(Item: Record Item; Quantity: Decimal; OrderDate: Date)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesOrder(SalesHeader, SalesLine, Item, '', '', Quantity, OrderDate, LibraryRandom.RandDec(1000, 2));
        SalesHeader.Validate("Shipment Date", OrderDate);
        SalesHeader.Modify();
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure GetWorkShiftTimeThreeShifts(var StartingTime: Time; var EndingTime: Time; WorkShiftNum: Integer)
    begin
        case WorkShiftNum of
            1:
                begin
                    StartingTime := 000000T;
                    EndingTime := 080000T;
                end;
            2:
                begin
                    StartingTime := 080000T;
                    EndingTime := 160000T;
                end;
            3:
                begin
                    StartingTime := 160000T;
                    EndingTime := 235959T;
                end;
        end;
    end;

    local procedure GetWorkShiftTimeFourShifts(var StartingTime: Time; var EndingTime: Time; WorkShiftNum: Integer)
    begin
        case WorkShiftNum of
            1:
                begin
                    StartingTime := 000000T;
                    EndingTime := 060000T;
                end;
            2:
                begin
                    StartingTime := 060000T;
                    EndingTime := 140000T;
                end;
            3:
                begin
                    StartingTime := 140000T;
                    EndingTime := 220000T;
                end;
            4:
                begin
                    StartingTime := 220000T;
                    EndingTime := 235959T;
                end;
        end;
    end;

    local procedure GetShopCalendarEndingTime(ShopCalendarCode: Code[10]): Time
    var
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
    begin
        ShopCalendarWorkingDays.SetRange("Shop Calendar Code", ShopCalendarCode);
        ShopCalendarWorkingDays.FindFirst();
        exit(ShopCalendarWorkingDays."Ending Time");
    end;

    local procedure FindShopCalendar(): Code[10]
    var
        ShopCalendar: Record "Shop Calendar";
    begin
        ShopCalendar.FindFirst();
        exit(ShopCalendar.Code);
    end;

    local procedure UpdateMfgSetup(StartingTime: Time; EndingTime: Time)
    var
        MfgSetup: Record "Manufacturing Setup";
    begin
        MfgSetup.Get();
        MfgSetup.Validate("Normal Starting Time", StartingTime);
        MfgSetup.Validate("Normal Ending Time", EndingTime);
        MfgSetup.Modify();
    end;

    local procedure UpdateThreeShiftsShopCalendarWorkingDays(ShopCalendarCode: Code[10]; WorkShiftCodes: array[3] of Code[10])
    var
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        DoW: Integer;
        i: Integer;
    begin
        for DoW := ShopCalendarWorkingDays.Day::Monday to ShopCalendarWorkingDays.Day::Sunday do
            for i := 1 to ArrayLen(WorkShiftCodes) do
                CreateThreeShiftsShopCalendarWorkDays(ShopCalendarCode, WorkShiftCodes[i], DoW, i);
    end;

    local procedure UpdateFourShiftsShopCalendarWorkingDays(ShopCalendarCode: Code[10]; WorkShiftCodes: array[4] of Code[10])
    var
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        DoW: Integer;
        i: Integer;
    begin
        for DoW := ShopCalendarWorkingDays.Day::Monday to ShopCalendarWorkingDays.Day::Sunday do
            for i := 1 to ArrayLen(WorkShiftCodes) do
                CreateFourShiftsShopCalendarWorkDays(ShopCalendarCode, WorkShiftCodes[i], DoW, i);
    end;

    local procedure CarryOutActionFirmPlannedProdOrder(ItemNoFilter: Text)
    var
        RequisitionLine: Record "Requisition Line";
        ProdOrderChoice: Option " ",Planned,"Firm Planned","Firm Planned & Print","Copy to Req. Wksh";
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetFilter("No.", ItemNoFilter);
        RequisitionLine.ModifyAll("Accept Action Message", true);
        RequisitionLine.FindFirst();
        LibraryPlanning.CarryOutPlanWksh(RequisitionLine, ProdOrderChoice::"Firm Planned", 0, 0, 0, '', '', '', '');
    end;

    local procedure VerifyDayAllocatedQty(MachineCenterNo: Code[20]; var Date: Date; var AllocatedTotal: Decimal; ExpectedQty: Decimal)
    var
        MachineCenter: Record "Machine Center";
    begin
        MachineCenter."No." := MachineCenterNo;
        MachineCenter.SetRange("Date Filter", Date);
        MachineCenter.CalcFields("Prod. Order Need (Qty.)");

        Assert.AreEqual(ExpectedQty, MachineCenter."Prod. Order Need (Qty.)", ProdOrderNeedQtyErr);

        Date := CalcDate('<-1D>', Date);
        AllocatedTotal -= ExpectedQty;
    end;

    local procedure VerifyFirstProdOrderMachineCenterRtngLineDates(MachineCenterNo: Code[20]; ExpStartDate: Date; ExpStartTime: Time; ExpEndDate: Date; ExpEndTime: Time)
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRtngLine.SetRange(Type, ProdOrderRtngLine.Type::"Machine Center");
        ProdOrderRtngLine.SetRange("No.", MachineCenterNo);
        ProdOrderRtngLine.FindFirst();
        VerifyProdOrderRtngLineDates(ProdOrderRtngLine, ExpStartDate, ExpStartTime, ExpEndDate, ExpEndTime);
    end;

    local procedure VerifyLastProdOrderMachineCenterRtngLineDates(MachineCenterNo: Code[20]; ExpStartDate: Date; ExpStartTime: Time; ExpEndDate: Date; ExpEndTime: Time)
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRtngLine.SetRange(Type, ProdOrderRtngLine.Type::"Machine Center");
        ProdOrderRtngLine.SetRange("No.", MachineCenterNo);
        ProdOrderRtngLine.FindLast();
        VerifyProdOrderRtngLineDates(ProdOrderRtngLine, ExpStartDate, ExpStartTime, ExpEndDate, ExpEndTime);
    end;

    local procedure VerifyFirstProdOrderWorkCenterRtngLineDates(WorkCenterNo: Code[20]; ExpStartDate: Date; ExpStartTime: Time; ExpEndDate: Date; ExpEndTime: Time)
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRtngLine.SetRange(Type, ProdOrderRtngLine.Type::"Work Center");
        ProdOrderRtngLine.SetRange("No.", WorkCenterNo);
        ProdOrderRtngLine.FindFirst();
        VerifyProdOrderRtngLineDates(ProdOrderRtngLine, ExpStartDate, ExpStartTime, ExpEndDate, ExpEndTime);
    end;

    local procedure VerifyProdOrderRtngLineDates(ProdOrderRtngLine: Record "Prod. Order Routing Line"; ExpStartDate: Date; ExpStartTime: Time; ExpEndDate: Date; ExpEndTime: Time)
    begin
        Assert.AreEqual(ExpStartDate, ProdOrderRtngLine."Starting Date", ProdOrderRtngLineDateErr);
        Assert.AreEqual(ExpStartTime, ProdOrderRtngLine."Starting Time", ProdOrderRtngLineDateErr);
        Assert.AreEqual(ExpEndDate, ProdOrderRtngLine."Ending Date", ProdOrderRtngLineDateErr);
        Assert.AreEqual(ExpEndTime, ProdOrderRtngLine."Ending Time", ProdOrderRtngLineDateErr);
    end;

    local procedure VerifyReqLineDates(ItemNo: Code[20]; StaringDate: Date; StartingTime: Time; EndingDate: Date; EndingTime: Time)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.FindFirst();
        Assert.AreEqual(StaringDate, RequisitionLine."Starting Date", ReqLineDatesErr);
        Assert.AreEqual(StartingTime, RequisitionLine."Starting Time", ReqLineDatesErr);
        Assert.AreEqual(EndingDate, RequisitionLine."Ending Date", ReqLineDatesErr);
        Assert.AreEqual(EndingTime, RequisitionLine."Ending Time", ReqLineDatesErr);
    end;

    local procedure VerifyProdOrderComponenDates(ItemNo: Code[20]; ExpDueDate: Date; ExpDueTime: Time)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange("Item No.", ItemNo);
        ProdOrderComponent.FindFirst();
        Assert.AreEqual(ExpDueDate, ProdOrderComponent."Due Date", ProdOrderCompDatesErr);
        Assert.AreEqual(ExpDueTime, ProdOrderComponent."Due Time", ProdOrderCompDatesErr);
    end;

    local procedure VerifyProdOrderCapNeedRoundingAndDateConsistency(MachineCenterNoFilter: Text)
    var
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
    begin
        ProdOrderCapacityNeed.SetRange(Type, ProdOrderCapacityNeed.Type::"Machine Center");
        ProdOrderCapacityNeed.SetFilter("No.", MachineCenterNoFilter);
        ProdOrderCapacityNeed.FindSet();
        repeat
            Assert.AreEqual(0, (ProdOrderCapacityNeed."Starting Time" - 000000T) mod 1000, ProdOrderCapNeedRoundErr);
            Assert.AreEqual(0, (ProdOrderCapacityNeed."Ending Time" - 000000T) mod 1000, ProdOrderCapNeedRoundErr);
            Assert.AreEqual(0, ProdOrderCapacityNeed."Allocated Time" mod 1, ProdOrderCapNeedRoundErr);
            Assert.AreEqual(0, ProdOrderCapacityNeed."Needed Time" mod 1, ProdOrderCapNeedRoundErr);
            Assert.AreEqual(ProdOrderCapacityNeed."Ending Time", DT2Time(ProdOrderCapacityNeed."Ending Date-Time"), ProdOrderCapNeedDateInconsitencyErr);
            Assert.AreEqual(ProdOrderCapacityNeed."Starting Time", DT2Time(ProdOrderCapacityNeed."Starting Date-Time"), ProdOrderCapNeedDateInconsitencyErr);
        until ProdOrderCapacityNeed.Next() = 0;
    end;

    local procedure VerifyProdOrderCapNeedZeroAllocatedTimeNotExist(MachineCenterNoFilter: Text)
    var
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
    begin
        ProdOrderCapacityNeed.SetRange(Type, ProdOrderCapacityNeed.Type::"Machine Center");
        ProdOrderCapacityNeed.SetRange("Allocated Time", 0);
        ProdOrderCapacityNeed.SetFilter("No.", MachineCenterNoFilter);
        Assert.RecordIsEmpty(ProdOrderCapacityNeed);
    end;
}

