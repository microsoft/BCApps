codeunit 137054 "SCM Supply Planning"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Planning] [SCM]
        isInitialized := false;
    end;

    var
        GlobalPurchaseHeader: array[2] of Record "Purchase Header";
        GlobalSalesHeader: array[3] of Record "Sales Header";
        GlobalProductionOrder: array[5] of Record "Production Order";
        GlobalTransferHeader: array[3] of Record "Transfer Header";
        GlobalAssemblyHeader: array[3] of Record "Assembly Header";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        OutputItemJournalTemplate: Record "Item Journal Template";
        OutputItemJournalBatch: Record "Item Journal Batch";
        LocationBlue: Record Location;
        LocationRed: Record Location;
        RequisitionLine: Record "Requisition Line";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryService: Codeunit "Library - Service";
        LibraryRandom: Codeunit "Library - Random";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryAssembly: Codeunit "Library - Assembly";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        NumberOfLineEqualError: Label 'Number of Lines must be same.';
        NumberOfLineNotEqualError: Label 'Number of Lines must not be same.';
        GlobalItemNo: Code[20];
        MaximumOrderQuantityErr: Label 'Quantity(%1) on RequisitionLine is more than Maximum Order Quantity(%2) of the Item.';
        SafetyStockQuantityErr: Label 'After calculating supply and demand of the Item, its inventory(%1) does not meet Safety Stock Quantity(%2). Supply should meet both demand and Safety Stock Quantity.';
        RequisitionLineNotEmptyErr: Label 'There should be no Requisition Line.';
        OrderDateErr: Label 'Order Date (%1) on Requisition Line is not equal to Order Date (%2) on Purchase Line.';
        ExceptionMsg: Label 'Exception: The projected available inventory is below Safety Stock Quantity %1 on %2.';
        RequisitionWorksheetErr: Label 'Requisition Worksheet cannot be used to create Prod. Order replenishment.';
        ReqLineOrderDateErr: Label 'Order Date (%1) on Requisition Line is not equal to Starting Date on Planning Worksheet.';
        ExpectedReceiptDateErr: Label 'Expected Receipt Date in Reservation Entry is not correct.';
        DemandTypeOption: Option "Sales Order","Transfer Order","Released Prod. Order",Assembly,"Purchase Return";
        SupplyTypeOption: array[5] of Option "None",Released,FirmPlanned,Purchase,"Sales Return",Transfer,Assembly,Planning;
        ReservationOption: Option "No Reservation","Reserve from Supply","Reserve from Demand";
        CouldNotChangeSupplyTxt: Label 'The supply type could not be changed in order';
        WrongMessageTxt: Label 'Wrong message appears.';
        QuantityErr: Label 'Quantity on Requisition Line is incorrect';
        LineCountErr: Label 'Wrong line count in planning worksheet.';
        ProjectedInventoryNegativeMsg: Label 'Projected inventory goes negative.';
        ConfirmTok: Label 'Confirm';
        AvailabilityTok: Label 'Availability';
        ReservationEntryTok: Label 'ReservationEntry';

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyOutsideReschedPeriodWeekReplenishProdOrder()
    begin
        // [FEATURE] [Resheduling Period]
        Initialize();
        DemandSupplyReschedulingPeriodWeek('<1W>', false);  // Rescheduling Period, Action Message Reschedule -False.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyPartialInReschedPeriodTwoWeekReplenishProdOrder()
    begin
        // [FEATURE] [Resheduling Period]
        Initialize();
        DemandSupplyReschedulingPeriodWeek('<2W>', true);  // Rescheduling Period, Action Message Reschedule -True.
    end;

    local procedure DemandSupplyReschedulingPeriodWeek(ReschedulingPeriod: Text[30]; ActionMessageReschedule: Boolean)
    var
        Item: Record Item;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        Initialize();

        // Create Item with planning parameters.
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", ReschedulingPeriod, ReschedulingPeriod, true, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.

        // Create Demand - Supply setup with Random Values taking Global Variable for Sales, Purchase and Production.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(30), GetRandomDateUsingWorkDate(50), 0D);  // Dates based on WORKDATE.
        CreateDemandQuantity(DemandQuantityValue, LibraryRandom.RandDec(10, 2) + 60, LibraryRandom.RandDec(10, 2) + 180, 0);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 2);  // Number of Sales Order.

        CreateSupplyType(SupplyType, SupplyType::FirmPlanned, SupplyType::Purchase, SupplyType::None, SupplyType::None, SupplyType::None);
        CreateSupplyDate(SupplyDateValue, GetRandomDateUsingWorkDate(40), GetRandomDateUsingWorkDate(5), 0D, 0D, 0D);  // Dates based on WORKDATE.
        CreateSupplyQuantity(SupplyQuantityValue, DemandQuantityValue[1], LibraryRandom.RandDec(10, 2) + 40, 0, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, Item."No.", Item."No.", '');

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));  // Dates based on WORKDATE.

        // Verify: Verify Planning Worksheet lines for different Action Messages.
        // Action Message: Cancel.
        VerifyRequisitionLine(Item."No.", RequisitionLine."Action Message"::Cancel, SupplyDateValue[2], SupplyQuantityValue[2], 0, 0D, '', '');

        // Action Message: New.
        VerifyRequisitionLine(Item."No.", RequisitionLine."Action Message"::New, DemandDateValue[2], 0, DemandQuantityValue[2], 0D, '', '');

        // Action Message: Reschedule otherwise Cancel and New.
        if ActionMessageReschedule then begin
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::Reschedule, DemandDateValue[1], 0, DemandQuantityValue[1], SupplyDateValue[1], '',
              '');
            VerifyRequisitionLineCount(3);  // Expected no of lines in Planning Worksheet. Value important.
        end else begin
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::Cancel, SupplyDateValue[1], SupplyQuantityValue[1], 0, 0D, '', '');
            VerifyRequisitionLine(Item."No.", RequisitionLine."Action Message"::New, DemandDateValue[1], 0, DemandQuantityValue[1], 0D, '', '');
            VerifyRequisitionLineCount(4);  // Expected no of lines in Planning Worksheet. Value important.
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyOutsideReschedPeriodWithoutReserveFlexibilityNoneReplenishProdOrder()
    begin
        // [FEATURE] [Resheduling Period]
        Initialize();
        DemandSupplyOutsideReschedulingPeriodFlexibilityNone(false);  // Reserve -False;
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,AvailableSalesLinesPageHandler')]
    [Scope('OnPrem')]
    procedure DemandSupplyOutsideReschedPeriodWithReserveFlexibilityNoneReplenishProdOrder()
    begin
        // [FEATURE] [Resheduling Period]
        Initialize();
        DemandSupplyOutsideReschedulingPeriodFlexibilityNone(true);  // Reserve -True;
    end;

    local procedure DemandSupplyOutsideReschedulingPeriodFlexibilityNone(Reserve: Boolean)
    var
        Item: Record Item;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        Initialize();

        // Create Item with planning parameters.
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1W>', '<1W>', true, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.

        // Create Demand - Supply setup with Reservation if required and Random Values taking Global Variable for Sales, Purchase and Production.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(30), GetRandomDateUsingWorkDate(50), 0D);  // Dates based on WORKDATE.
        CreateDemandQuantity(DemandQuantityValue, LibraryRandom.RandDec(10, 2) + 60, LibraryRandom.RandDec(10, 2) + 180, 0);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 2);  // Number of Sales Order.

        CreateSupplyType(SupplyType, SupplyType::FirmPlanned, SupplyType::Purchase, SupplyType::None, SupplyType::None, SupplyType::None);
        CreateSupplyDate(SupplyDateValue, GetRandomDateUsingWorkDate(40), GetRandomDateUsingWorkDate(5), 0D, 0D, 0D);  // Dates based on WORKDATE.
        CreateSupplyQuantity(SupplyQuantityValue, DemandQuantityValue[1], LibraryRandom.RandDec(10, 2) + 40, 0, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, Item."No.", Item."No.", '');
        UpdatePlanningFlexibilityOnProduction(GlobalProductionOrder[1]."No.", GlobalProductionOrder[1].Status);

        if Reserve then
            ReservePurchaseLine(GlobalPurchaseHeader[1]."No.");  // Reservation on Page Handler ReservationPageHandler.

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));  // Dates based on WORKDATE.

        // Verify: Verify Planning Worksheet lines for different Action Messages.
        // Action Message: New.
        VerifyRequisitionLine(Item."No.", RequisitionLine."Action Message"::New, DemandDateValue[1], 0, DemandQuantityValue[1], 0D, '', '');

        // Action Message: New otherwise Cancel and New.
        if Reserve then begin
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::New, DemandDateValue[2], 0,
              DemandQuantityValue[2] - DemandQuantityValue[1] - SupplyQuantityValue[2], 0D, '', '');
            VerifyRequisitionLineCount(2);  // Expected no of lines in Planning Worksheet. Value important.
        end else begin
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::Cancel, SupplyDateValue[2], SupplyQuantityValue[2], 0, 0D, '', '');
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::New, DemandDateValue[2], 0, DemandQuantityValue[2] - DemandQuantityValue[1], 0D,
              '', '');
            VerifyRequisitionLineCount(3);  // Expected no of lines in Planning Worksheet. Value important.
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyInReschedPeriodTwoMonthWithProdOrderReplenishProdOrder()
    begin
        // [FEATURE] [Resheduling Period] [Lot Accumulation Period]
        Initialize();
        DemandSupplyInReschedulingPeriodMonth(true);  // Production -True.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyInReschedPeriodTwoMonthWithoutProdOrderReplenishProdOrder()
    begin
        // [FEATURE] [Resheduling Period] [Lot Accumulation Period]
        Initialize();
        DemandSupplyInReschedulingPeriodMonth(false);  // Production -False.
    end;

    local procedure DemandSupplyInReschedulingPeriodMonth(Production: Boolean)
    var
        Item: Record Item;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        Initialize();

        // Create Item with Planning parameters.
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<2M>', '<2M>', true, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.

        // Create Demand - Supply setup with Random Values taking Global Variable for Sales, Purchase and Production.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(30), GetRandomDateUsingWorkDate(50), 0D);  // Dates based on WORKDATE.
        CreateDemandQuantity(DemandQuantityValue, LibraryRandom.RandDec(10, 2) + 60, LibraryRandom.RandDec(10, 2) + 180, 0);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 2);  // Number of Sales Order.

        CreateSupplyDate(SupplyDateValue, GetRandomDateUsingWorkDate(40), GetRandomDateUsingWorkDate(5), 0D, 0D, 0D);  // Dates based on WORKDATE.
        CreateSupplyQuantity(SupplyQuantityValue, DemandQuantityValue[1], LibraryRandom.RandDec(10, 2) + 40, 0, 0, 0);
        if Production then begin
            CreateSupplyType(SupplyType, SupplyType::FirmPlanned, SupplyType::None, SupplyType::None, SupplyType::None, SupplyType::None);
            CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, Item."No.", '', '');
            UpdatePlanningFlexibilityOnProduction(GlobalProductionOrder[1]."No.", GlobalProductionOrder[1].Status);
        end;
        CreatePurchaseOrder(GlobalPurchaseHeader[1], Item."No.", SupplyQuantityValue[2], SupplyDateValue[2]);  // Dates based on WORKDATE.

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));  // Dates based on WORKDATE.

        // Verify: Verify Planning Worksheet lines for Action Message: Reschedule and Change Quantity.
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::"Resched. & Chg. Qty.", DemandDateValue[1], SupplyQuantityValue[2],
          DemandQuantityValue[2] + DemandQuantityValue[1], SupplyDateValue[2], '', '');
        VerifyRequisitionLineCount(1);  // Expected no of lines in Planning Worksheet. Value important.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyOutsideReschedPeriodCarryOutActionMessageReplenishProdOrder()
    var
        Item: Record Item;
        PlanningLinesCountBeforeCarryOut: Integer;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        // [FEATURE] [Resheduling Period] [Lot Accumulation Period]

        // Setup: Create Item with Planning parameters.
        Initialize();
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1W>', '<1W>', true, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.

        // Create Demand - Supply setup with Random Values taking Global Variable for Sales, Purchase and Production.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(30), GetRandomDateUsingWorkDate(50), 0D);  // Dates based on WORKDATE.
        CreateDemandQuantity(DemandQuantityValue, LibraryRandom.RandDec(10, 2) + 60, LibraryRandom.RandDec(10, 2) + 180, 0);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 2);  // Number of Sales Order.

        CreateSupplyType(SupplyType, SupplyType::FirmPlanned, SupplyType::Purchase, SupplyType::None, SupplyType::None, SupplyType::None);
        CreateSupplyDate(SupplyDateValue, GetRandomDateUsingWorkDate(40), GetRandomDateUsingWorkDate(5), 0D, 0D, 0D);  // Dates based on WORKDATE.
        CreateSupplyQuantity(SupplyQuantityValue, DemandQuantityValue[1], LibraryRandom.RandDec(10, 2) + 40, 0, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, Item."No.", Item."No.", '');

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));  // Dates based on WORKDATE.

        // Exercise: Carry Out Action Message on Planning Worksheet lines.
        AcceptActionMessageAndCarryOutActionMessagePlan(Item."No.", PlanningLinesCountBeforeCarryOut);

        // Verify: Verify that all the Planning Worksheet Lines are cleared after Carry Out Action message.
        VerifyPlanningWorksheetEmpty(PlanningLinesCountBeforeCarryOut, Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyOutsideReschedPeriodWeekReplenishPurchase()
    begin
        // [FEATURE] [Resheduling Period] [Lot Accumulation Period]
        Initialize();
        DemandSupplyReschedulingPeriodForReplenishmentPurchase('<1W>', false);  // Action Message Reschedule -False.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyPartialInReschedPeriodYearReplenishPurchase()
    begin
        // [FEATURE] [Resheduling Period] [Lot Accumulation Period]
        Initialize();
        DemandSupplyReschedulingPeriodForReplenishmentPurchase('<1Y>', true);  // Action Message Reschedule -True.
    end;

    local procedure DemandSupplyReschedulingPeriodForReplenishmentPurchase(ReschedulingPeriod: Text[30]; ActionMessageReschedule: Boolean)
    var
        Item: Record Item;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        Initialize();

        // Create Item with planning parameters.
        CreateLFLItem(Item, Item."Replenishment System"::Purchase, ReschedulingPeriod, ReschedulingPeriod, true, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.

        // Create Demand - Supply setup with Random Values taking Global Variable for Sales and Purchase.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(30), GetRandomDateUsingWorkDate(50), 0D);  // Dates based on WORKDATE.
        CreateDemandQuantity(DemandQuantityValue, LibraryRandom.RandDec(10, 2) + 60, LibraryRandom.RandDec(10, 2) + 180, 0);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 2);  // Number of Sales Order.

        CreateSupplyType(SupplyType, SupplyType::Purchase, SupplyType::None, SupplyType::None, SupplyType::None, SupplyType::None);
        CreateSupplyDate(SupplyDateValue, GetRandomDateUsingWorkDate(5), 0D, 0D, 0D, 0D);  // Dates based on WORKDATE.
        CreateSupplyQuantity(SupplyQuantityValue, LibraryRandom.RandDec(10, 2) + 40, 0, 0, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, '', Item."No.", '');

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));  // Dates based on WORKDATE.

        // Verify: Verify Planning Worksheet lines for different Action Messages.
        if ActionMessageReschedule then begin
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::"Resched. & Chg. Qty.", DemandDateValue[1], SupplyQuantityValue[1],
              DemandQuantityValue[1] + DemandQuantityValue[2], SupplyDateValue[1], '', '');
            VerifyRequisitionLineCount(1);  // Expected no of lines in Planning Worksheet. Value important.
        end else begin
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::Cancel, SupplyDateValue[1], SupplyQuantityValue[1], 0, 0D, '', '');
            VerifyRequisitionLine(Item."No.", RequisitionLine."Action Message"::New, DemandDateValue[1], 0, DemandQuantityValue[1], 0D, '', '');
            VerifyRequisitionLine(Item."No.", RequisitionLine."Action Message"::New, DemandDateValue[2], 0, DemandQuantityValue[2], 0D, '', '');
            VerifyRequisitionLineCount(3);  // Expected no of lines in Planning Worksheet. Value important.
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyWithoutReserveFlexibilityNoneReplenishPurchase()
    begin
        // [FEATURE] [Resheduling Period] [Lot Accumulation Period]

        Initialize();
        DemandSupplyInReschedulingPeriodMonthFlexibilityNone(
          ReservationOption::"No Reservation", DemandTypeOption::"Sales Order", SupplyTypeOption::Purchase, '');
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,AvailableSalesLinesPageHandler')]
    [Scope('OnPrem')]
    procedure DemandSupplyWithReserveFlexibilityNoneReplenishPurchase()
    begin
        // [FEATURE] [Available - Sales Lines] [Sales] [Purchase] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Sales Lines" page when demand is Sales Order, and supply - Purchase Order
        Initialize();
        DemandSupplyInReschedulingPeriodMonthFlexibilityNone(
          ReservationOption::"Reserve from Supply", DemandTypeOption::"Sales Order", SupplyTypeOption::Purchase, '');
    end;

    local procedure DemandSupplyInReschedulingPeriodMonthFlexibilityNone(Reserve: Option "No Reservation","Reserve from Supply","Reserve from Demand"; NewDemandType: Option; NewSupplyType: Option; LocationCode: Code[10])
    var
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
        SupplyQuantityValue: array[5] of Decimal;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SafetyLeadTime: DateFormula;
    begin
        Initialize();

        // Create Item with planning parameters.
        InventorySetup.Get();
        Evaluate(SafetyLeadTime, '<0D>');
        UpdateDefaultSafetyLeadTimeOnInventorySetup(SafetyLeadTime);

        CreateLFLItemWithDemandAndSupply(
          Item, DemandDateValue, DemandQuantityValue, SupplyQuantityValue, NewDemandType, NewSupplyType, LocationCode);

        case Reserve of
            Reserve::"Reserve from Supply":
                ReserveFromSupply(NewSupplyType);
            Reserve::"Reserve from Demand":
                ReserveFromDemand(NewDemandType);
        end;

        // Exercise: Calculate Regenerative Plan.
        Item.SetRange("No.", Item."No.");
        if LocationCode <> '' then
            Item.SetRange("Location Filter", LocationCode);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));  // Dates based on WORKDATE.

        // Verify: Verify Planning Worksheet lines for different Action Messages.
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::New, DemandDateValue[1], 0,
          DemandQuantityValue[1] + DemandQuantityValue[2] - SupplyQuantityValue[1], 0D, LocationCode, '');
        VerifyRequisitionLineCount(1);  // Expected no of lines in Planning Worksheet. Value important.

        UpdateDefaultSafetyLeadTimeOnInventorySetup(InventorySetup."Default Safety Lead Time");
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,AvailableSalesLinesPageHandler')]
    [Scope('OnPrem')]
    procedure DemandSupplyWithReserveFlexibilityNoneReplenishProdOrder()
    begin
        // [FEATURE] [Available - Sales Lines] [Sales] [Production] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Sales Lines" page when demand is Sales Order, and supply - Production Order
        Initialize();
        DemandSupplyInReschedulingPeriodMonthFlexibilityNone(
          ReservationOption::"Reserve from Supply", DemandTypeOption::"Sales Order", SupplyTypeOption::Released, '');
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,AvailableSalesLinesPageHandler')]
    [Scope('OnPrem')]
    procedure DemandSupplyWithReserveFlexibilityNoneReplenishSalesReturn()
    begin
        // [FEATURE] [Available - Sales Lines] [Sales] [Sales Return] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Sales Lines" page when demand is Sales Order, and supply - Sales Return Order
        Initialize();
        DemandSupplyInReschedulingPeriodMonthFlexibilityNone(
          ReservationOption::"Reserve from Supply", DemandTypeOption::"Sales Order", SupplyTypeOption::"Sales Return", '');
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,AvailableSalesLinesPageHandler,InboundTransferStrMenuHandler')]
    [Scope('OnPrem')]
    procedure DemandSupplyWithReserveFlexibilityNoneReplenishTransfer()
    var
        Location: Record Location;
    begin
        // [FEATURE] [Available - Sales Lines] [Sales] [Transfer] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Sales Lines" page when demand is Sales Order, and supply - Transfer Order
        Initialize();
        LibraryWarehouse.CreateLocation(Location);
        DemandSupplyInReschedulingPeriodMonthFlexibilityNone(
          ReservationOption::"Reserve from Supply", DemandTypeOption::"Sales Order", SupplyTypeOption::Transfer, Location.Code);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,AvailableSalesLinesCancelReservationPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure DemandSupplyWithReserveCancelReservationFromSupply()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseOrder: TestPage "Purchase Order";
        Quantity: Decimal;
    begin
        // [FEATURE] [Available - Sales Lines] [Sales] [Reservation]
        // [SCENARIO] Reservation should be cancelled when "Cancel Reservation" action is run in "Available - Sales Lines" page
        Initialize();

        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDecInRange(100, 200, 2);
        CreatePurchaseOrder(PurchaseHeader, Item."No.", Quantity, WorkDate());
        CreateSalesOrder(SalesHeader, Item."No.", Quantity, WorkDate());

        SelectSalesLine(SalesLine, SalesHeader."No.");
        LibrarySales.AutoReserveSalesLine(SalesLine);

        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseOrder.PurchLines.Reserve.Invoke();
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,AvailablePurchaseLinesCancelReservationPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure DemandSupplyWithReserveCancelReservationFromDemand()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        Quantity: Decimal;
    begin
        // [FEATURE] [Available - Purchase Lines] [Purchase] [Reservation]
        // [SCENARIO] Reservation should be cancelled when "Cancel Reservation" action is run in "Available - Purchase Lines" page
        Initialize();

        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDecInRange(100, 200, 2);
        CreatePurchaseOrder(PurchaseHeader, Item."No.", Quantity, WorkDate());
        CreateSalesOrder(SalesHeader, Item."No.", Quantity, WorkDate());

        SelectSalesLine(SalesLine, SalesHeader."No.");
        LibrarySales.AutoReserveSalesLine(SalesLine);

        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesOrder.SalesLines.Reserve.Invoke();
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,AvailableTransferLinesPageHandler')]
    [Scope('OnPrem')]
    procedure DemandTransferSupplyWithReserveFlexibilityNoneReplenishPurchase()
    var
        Location: Record Location;
    begin
        // [FEATURE] [Available - Transfer Lines] [Purchase] [Transfer] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Transfer Lines" page when demand is Transfer Order, and supply - Purchase Order
        Initialize();
        LibraryWarehouse.CreateLocation(Location);
        DemandSupplyInReschedulingPeriodMonthFlexibilityNone(
          ReservationOption::"Reserve from Supply", DemandTypeOption::"Transfer Order", SupplyTypeOption::Purchase, Location.Code);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,AvailableTransferLinesPageHandler')]
    [Scope('OnPrem')]
    procedure DemandTransferSupplyWithReserveFlexibilityNoneReplenishSalesReturn()
    var
        Location: Record Location;
    begin
        // [FEATURE] [Available - Transfer Lines] [Sales Return] [Transfer] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Transfer Lines" page when demand is Transfer Order, and supply - Sales Return Order
        Initialize();
        LibraryWarehouse.CreateLocation(Location);
        DemandSupplyInReschedulingPeriodMonthFlexibilityNone(
          ReservationOption::"Reserve from Supply", DemandTypeOption::"Transfer Order", SupplyTypeOption::"Sales Return", Location.Code);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,AvailableTransferLinesPageHandler')]
    [Scope('OnPrem')]
    procedure DemandTransferSupplyWithReserveFlexibilityNoneReplenishAssembly()
    var
        Location: Record Location;
    begin
        // [FEATURE] [Available - Transfer Lines] [Transfer] [Assembly] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Transfer Lines" page when demand is Transfer Order, and supply - Assembly Order
        Initialize();
        LibraryWarehouse.CreateLocation(Location);
        DemandSupplyInReschedulingPeriodMonthFlexibilityNone(
          ReservationOption::"Reserve from Supply", DemandTypeOption::"Transfer Order", SupplyTypeOption::Assembly, Location.Code);
    end;

    [Test]
    [HandlerFunctions('OutboundTransferStrMenuHandler,ReservationPageHandler,AvailableAssemblyHeadersPageHandler')]
    [Scope('OnPrem')]
    procedure DemandTransferSupplyWithReserveFlexibilityNoneReplenishAssemblyReserveFromDemand()
    var
        Location: Record Location;
    begin
        // [FEATURE] [Available - Assembly Lines] [Transfer] [Assembly] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Assembly Lines" page when demand is Transfer Order, and supply - Assembly Order
        Initialize();
        LibraryWarehouse.CreateLocation(Location);
        DemandSupplyInReschedulingPeriodMonthFlexibilityNone(
          ReservationOption::"Reserve from Demand", DemandTypeOption::"Transfer Order", SupplyTypeOption::Assembly, Location.Code);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,AvailableTransferLinesPageHandler')]
    [Scope('OnPrem')]
    procedure DemandTransferSupplyWithReserveFlexibilityNoneReplenishProdOrder()
    var
        Location: Record Location;
    begin
        // [FEATURE] [Available - Transfer Lines] [Transfer] [Production] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Transfer Lines" page when demand is Transfer Order, and supply - Production Order
        Initialize();
        LibraryWarehouse.CreateLocation(Location);
        DemandSupplyInReschedulingPeriodMonthFlexibilityNone(
          ReservationOption::"Reserve from Supply", DemandTypeOption::"Transfer Order", SupplyTypeOption::Released, Location.Code);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,AvailableSalesLinesPageHandler')]
    [Scope('OnPrem')]
    procedure DemandSaleSupplyWithReserveFlexibilityNoneReplenishAssembly()
    begin
        // [FEATURE] [Available - Sales Lines] [Sales] [Assembly] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Sales Lines" page when demand is Sales Order, and supply - Assembly Order
        Initialize();
        DemandSupplyInReschedulingPeriodMonthFlexibilityNone(
          ReservationOption::"Reserve from Supply", DemandTypeOption::"Sales Order", SupplyTypeOption::Assembly, '');
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,AvailableAssemblyLinesPageHandler')]
    [Scope('OnPrem')]
    procedure DemandAssemblySupplyWithReserveFlexibilityNoneReplenishSalesReturn()
    begin
        // [FEATURE] [Available - Assembly Lines] [Sales Return] [Assembly] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Assembly Lines" page when demand is Assembly Order, and supply - Sales Return Order
        Initialize();
        DemandSupplyInReschedulingPeriodMonthFlexibilityNone(
          ReservationOption::"Reserve from Supply", DemandTypeOption::Assembly, SupplyTypeOption::"Sales Return", '');
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,AvailableProdOrderCompPageHandler')]
    [Scope('OnPrem')]
    procedure DemandProdOrderSupplyWithReserveFlexibilityNoneReplenishPurchaseReserveFromSupply()
    begin
        // [FEATURE] [Available - Prod. Order Lines] [Purchase] [Production] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Prod. Order Lines" page when demand is Production Order, and supply - Purchase Order
        Initialize();
        DemandSupplyInReschedulingPeriodMonthFlexibilityNone(
          ReservationOption::"Reserve from Supply", DemandTypeOption::"Released Prod. Order", SupplyTypeOption::Purchase, '');
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,AvailablePurchaseLinesPageHandler')]
    [Scope('OnPrem')]
    procedure DemandProdOrderSupplyWithReserveFlexibilityNoneReplenishPurchaseReserveFromDemand()
    begin
        // [FEATURE] [Available - Purchase Lines] [Purchase] [Production] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Purchase Lines" page when demand is Production Order, and supply - Purchase Order
        Initialize();
        DemandSupplyInReschedulingPeriodMonthFlexibilityNone(
          ReservationOption::"Reserve from Demand", DemandTypeOption::"Released Prod. Order", SupplyTypeOption::Purchase, '');
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,AvailableProdOrderCompPageHandler')]
    [Scope('OnPrem')]
    procedure DemandProdOrderSupplySalesReturnReserveFromSupply()
    begin
        // [FEATURE] [Available - Prod. Order Lines] [Sales Return] [Production] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Prod. Order Lines" page when demand is Production Order, and supply - Sales Return Order
        Initialize();
        DemandSupplyInReschedulingPeriodMonthFlexibilityNone(
          ReservationOption::"Reserve from Supply", DemandTypeOption::"Released Prod. Order", SupplyTypeOption::"Sales Return", '');
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,AvailableProdOrderLinesPageHandler')]
    [Scope('OnPrem')]
    procedure DemandSaleSupplyWithReserveFlexibilityNoneReplenishProdOrderReserveFromDemand()
    begin
        // [FEATURE] [Available - Prod. Order Lines] [Sales] [Production] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Prod. Order Lines" page when demand is Sales Order, and supply - Production Order
        Initialize();
        DemandSupplyInReschedulingPeriodMonthFlexibilityNone(
          ReservationOption::"Reserve from Demand", DemandTypeOption::"Sales Order", SupplyTypeOption::Released, '');
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,AvailablePurchaseLinesPageHandler')]
    [Scope('OnPrem')]
    procedure DemandPurchReturnSupplyWithReserveFlexibilityNoneReplenishPurchase()
    begin
        // [FEATURE] [Available - Purchase Lines] [Purchase] [Purchase Return] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Purchase Lines" page when demand is Purchase Return Order, and supply - Purchase Order
        Initialize();
        DemandSupplyInReschedulingPeriodMonthFlexibilityNone(
          ReservationOption::"Reserve from Demand", DemandTypeOption::"Purchase Return", SupplyTypeOption::Purchase, '');
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,AvailableProdOrderLinesPageHandler')]
    [Scope('OnPrem')]
    procedure DemandPurchReturnSupplyWithReserveFlexibilityNoneReplenishProdOrder()
    begin
        // [FEATURE] [Available - Prod. Order Lines] [Purchase Return] [Production] [Reservation]
        // [SCENARIO] Item can be reserved from "Available - Prod. Order Lines" page when demand is Purchase Return Order, and supply - Production Order
        Initialize();
        DemandSupplyInReschedulingPeriodMonthFlexibilityNone(
          ReservationOption::"Reserve from Demand", DemandTypeOption::"Purchase Return", SupplyTypeOption::Released, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyInReschedPeriodCarryOutActionMessageReplenishPurchase()
    var
        Item: Record Item;
        PlanningLinesCountBeforeCarryOut: Integer;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        // [FEATURE] [Resheduling Period] [Lot Accumulation Period] [Carry Out Action Message]
        // Setup: Create Item with planning parameters.
        Initialize();
        CreateLFLItem(Item, Item."Replenishment System"::Purchase, '<1Y>', '<1Y>', true, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.

        // Create Demand - Supply Scenario with Random Value taking Global Variable for Sales and Purchase.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(30), GetRandomDateUsingWorkDate(50), 0D);  // Dates based on WORKDATE.
        CreateDemandQuantity(DemandQuantityValue, LibraryRandom.RandDec(10, 2) + 60, LibraryRandom.RandDec(10, 2) + 180, 0);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 2);  // Number of Sales Order.

        CreateSupplyType(SupplyType, SupplyType::Purchase, SupplyType::None, SupplyType::None, SupplyType::None, SupplyType::None);
        CreateSupplyDate(SupplyDateValue, GetRandomDateUsingWorkDate(5), 0D, 0D, 0D, 0D);  // Dates based on WORKDATE.
        CreateSupplyQuantity(SupplyQuantityValue, LibraryRandom.RandDec(10, 2) + 40, 0, 0, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, '', Item."No.", '');
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));  // Dates based on WORKDATE.

        // Exercise: Carry Out Action Message on Planning Worksheet lines.
        AcceptActionMessageAndCarryOutActionMessagePlan(Item."No.", PlanningLinesCountBeforeCarryOut);

        // Verify: Verify that all the Planning Worksheet Lines are cleared after Carry Out Action message.
        VerifyPlanningWorksheetEmpty(PlanningLinesCountBeforeCarryOut, Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyOnMultipleLocations()
    var
        Item: Record Item;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        // [FEATURE] [Resheduling Period] [Lot Accumulation Period]

        // Setup: Create Item with Planning parameters.
        Initialize();
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1Y>', '<1Y>', true, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.

        // Create Supply and Demand with Random Value taking Global Variable for Sales and Production and different locations- Blue and Red.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(80), GetRandomDateUsingWorkDate(60), GetRandomDateUsingWorkDate(60));  // Dates based on WORKDATE.
        CreateDemandQuantity(
          DemandQuantityValue, LibraryRandom.RandDec(5, 2) + 80, LibraryRandom.RandDec(5, 2) + 40,
          LibraryRandom.RandDec(5, 2) + 10);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 3);  // Number of Sales Order.

        CreateSupplyType(SupplyType, SupplyType::FirmPlanned, SupplyType::None, SupplyType::None, SupplyType::None, SupplyType::None);
        CreateSupplyDate(SupplyDateValue, GetRandomDateUsingWorkDate(15), 0D, 0D, 0D, 0D);  // Dates based on WORKDATE.
        CreateSupplyQuantity(SupplyQuantityValue, LibraryRandom.RandDec(5, 2) + 20, 0, 0, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, Item."No.", '', LocationBlue.Code);

        UpdateLocationForSales(GlobalSalesHeader[2]."No.", LocationRed.Code);
        UpdateLocationForSales(GlobalSalesHeader[3]."No.", LocationBlue.Code);

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(90));  // Dates based on WORKDATE.

        // Verify: Verify Planning Worksheet lines for Action messages on all locations.
        VerifyRequisitionLine(Item."No.", RequisitionLine."Action Message"::New, DemandDateValue[1], 0, DemandQuantityValue[1], 0D, '', '');
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::New, DemandDateValue[2], 0, DemandQuantityValue[2], 0D, LocationRed.Code, '');
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::"Resched. & Chg. Qty.", DemandDateValue[3], SupplyQuantityValue[1],
          DemandQuantityValue[3], SupplyDateValue[1], LocationBlue.Code, '');
        VerifyRequisitionLineCount(3);  // Expected no of lines in Planning Worksheet. Value important.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyOnMultipleLocationsWithPlanningForProductionLocation()
    var
        Item: Record Item;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        // [FEATURE] [Resheduling Period] [Lot Accumulation Period]

        // Setup: Create Item with Planning parameters.
        Initialize();
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1Y>', '<1Y>', true, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.

        // Create Supply and Demand with Random Value taking Global Variable for Sales and Production and different locations- Blue and Red.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(80), GetRandomDateUsingWorkDate(60), GetRandomDateUsingWorkDate(60));  // Dates based on WORKDATE.
        CreateDemandQuantity(
          DemandQuantityValue, LibraryRandom.RandDec(5, 2) + 80, LibraryRandom.RandDec(5, 2) + 40,
          LibraryRandom.RandDec(5, 2) + 10);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 3);  // Number of Sales Order.

        CreateSupplyType(SupplyType, SupplyType::FirmPlanned, SupplyType::None, SupplyType::None, SupplyType::None, SupplyType::None);
        CreateSupplyDate(SupplyDateValue, GetRandomDateUsingWorkDate(15), 0D, 0D, 0D, 0D);  // Dates based on WORKDATE.
        CreateSupplyQuantity(SupplyQuantityValue, LibraryRandom.RandDec(5, 2) + 20, 0, 0, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, Item."No.", '', LocationBlue.Code);

        UpdateLocationForSales(GlobalSalesHeader[2]."No.", LocationRed.Code);
        UpdateLocationForSales(GlobalSalesHeader[3]."No.", LocationBlue.Code);

        // Exercise: Calculate Regenerative Plan for Location Blue only.
        Item.SetRange("No.", Item."No.");
        Item.SetRange("Location Filter", LocationBlue.Code);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(90));  // Dates based on WORKDATE.

        // Verify: Verify Planning Worksheet lines for Location - Blue.
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::"Resched. & Chg. Qty.", DemandDateValue[3], SupplyQuantityValue[1],
          DemandQuantityValue[3], SupplyDateValue[1], LocationBlue.Code, '');
        VerifyRequisitionLineCount(1);  // Expected no of lines in Planning Worksheet. Value important.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyOnMultipleLocationsWithPlanningForSalesLocation()
    var
        Item: Record Item;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        // [FEATURE] [Resheduling Period] [Lot Accumulation Period]

        // Setup: Create Item with Planning parameters.
        Initialize();
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1Y>', '<1Y>', true, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.

        // Create Supply and Demand with Random Value taking Global Variable for Sales and Production and different locations- Blue and Red.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(80), GetRandomDateUsingWorkDate(60), GetRandomDateUsingWorkDate(60));  // Dates based on WORKDATE.
        CreateDemandQuantity(
          DemandQuantityValue, LibraryRandom.RandDec(5, 2) + 80, LibraryRandom.RandDec(5, 2) + 40,
          LibraryRandom.RandDec(5, 2) + 10);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 3);  // Number of Sales Order.

        CreateSupplyType(SupplyType, SupplyType::FirmPlanned, SupplyType::None, SupplyType::None, SupplyType::None, SupplyType::None);
        CreateSupplyDate(SupplyDateValue, GetRandomDateUsingWorkDate(15), 0D, 0D, 0D, 0D);  // Dates based on WORKDATE.
        CreateSupplyQuantity(SupplyQuantityValue, LibraryRandom.RandDec(5, 2) + 20, 0, 0, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, Item."No.", '', LocationBlue.Code);

        UpdateLocationForSales(GlobalSalesHeader[2]."No.", LocationRed.Code);
        UpdateLocationForSales(GlobalSalesHeader[3]."No.", LocationBlue.Code);

        // Exercise: Calculate Regenerative Plan for Location Red only.
        Item.SetRange("No.", Item."No.");
        Item.SetRange("Location Filter", LocationRed.Code);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(90));  // Dates based on WORKDATE.

        // Verify: Verify Planning Worksheet lines for Location - Red.
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::New, DemandDateValue[2], 0, DemandQuantityValue[2], 0D, LocationRed.Code, '');
        VerifyRequisitionLineCount(1);  // Expected no of lines in Planning Worksheet. Value important.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyOnMultipleLocationsWithVariant()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        SalesLine: Record "Sales Line";
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        // [FEATURE] [Resheduling Period] [Lot Accumulation Period] [Variant]

        // Setup: Create Item with Planning parameters.
        Initialize();
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1Y>', '<1Y>', true, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.

        // Create Supply and Demand with Random Value taking Global Variable for Sales and Production and different locations with Variant.
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(80), GetRandomDateUsingWorkDate(60), GetRandomDateUsingWorkDate(60));  // Dates based on WORKDATE.
        CreateDemandQuantity(
          DemandQuantityValue, LibraryRandom.RandDec(5, 2) + 80, LibraryRandom.RandDec(5, 2) + 40,
          LibraryRandom.RandDec(5, 2) + 10);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 3);  // Number of Sales Order.

        CreateSupplyType(SupplyType, SupplyType::FirmPlanned, SupplyType::None, SupplyType::None, SupplyType::None, SupplyType::None);
        CreateSupplyDate(SupplyDateValue, GetRandomDateUsingWorkDate(15), 0D, 0D, 0D, 0D);  // Dates based on WORKDATE.
        CreateSupplyQuantity(SupplyQuantityValue, LibraryRandom.RandDec(5, 2) + 20, 0, 0, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, Item."No.", '', LocationBlue.Code);

        UpdateLocationForSales(GlobalSalesHeader[2]."No.", LocationRed.Code);
        UpdateLocationForSales(GlobalSalesHeader[3]."No.", LocationBlue.Code);
        UpdateVariantOnSales(SalesLine, GlobalSalesHeader[1]."No.", ItemVariant.Code);

        // Exercise: Calculate Regenerative Plan with Variant Filter only.
        Item.SetRange("No.", Item."No.");
        Item.SetRange("Variant Filter", ItemVariant.Code);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(90));  // Dates based on WORKDATE.

        // Verify: Verify Planning Worksheet lines for Item with Variant.
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::New, DemandDateValue[1], 0, DemandQuantityValue[1], 0D, '', ItemVariant.Code);
        VerifyRequisitionLineCount(1);  // Expected no of lines in Planning Worksheet. Value important.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyOnMultipleLocationsCarryOutActionMessage()
    var
        Item: Record Item;
        PlanningLinesCountBeforeCarryOut: Integer;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        // [FEATURE] [Resheduling Period] [Lot Accumulation Period] [Carry Out Action Message]

        // Setup: Create Item with Planning parameters.
        Initialize();
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1Y>', '<1Y>', true, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.

        // Create Supply and Demand with Random Value taking Global Variable for Sales and Production and different locations.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(80), GetRandomDateUsingWorkDate(60), GetRandomDateUsingWorkDate(60));  // Dates based on WORKDATE.
        CreateDemandQuantity(
          DemandQuantityValue, LibraryRandom.RandDec(5, 2) + 80, LibraryRandom.RandDec(5, 2) + 40,
          LibraryRandom.RandDec(5, 2) + 10);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 3);  // Number of Sales Order.

        CreateSupplyType(SupplyType, SupplyType::FirmPlanned, SupplyType::None, SupplyType::None, SupplyType::None, SupplyType::None);
        CreateSupplyDate(SupplyDateValue, GetRandomDateUsingWorkDate(15), 0D, 0D, 0D, 0D);  // Dates based on WORKDATE.
        CreateSupplyQuantity(SupplyQuantityValue, LibraryRandom.RandDec(5, 2) + 20, 0, 0, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, Item."No.", '', LocationBlue.Code);

        UpdateLocationForSales(GlobalSalesHeader[2]."No.", LocationRed.Code);
        UpdateLocationForSales(GlobalSalesHeader[3]."No.", LocationBlue.Code);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(90));  // Dates based on WORKDATE.

        // Exercise: Carry Out Action Message on Planning Worksheet lines.
        AcceptActionMessageAndCarryOutActionMessagePlan(Item."No.", PlanningLinesCountBeforeCarryOut);

        // Verify: Verify that all the Planning Worksheet Lines are cleared after Carry Out Action message.
        VerifyPlanningWorksheetEmpty(PlanningLinesCountBeforeCarryOut, Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyFromSafetyStockOnly()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Safety Stock]

        // Setup: Create Item with Safety Stock without supply or demand.
        Initialize();
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1Y>', '<1Y>', true, LibraryRandom.RandDec(5, 2) + 10, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(90));

        // Verify: Verify Planning Worksheet lines for Order Line generated for Safety Stock Qty.
        VerifyRequisitionLine(Item."No.", RequisitionLine."Action Message"::New, WorkDate(), 0, Item."Safety Stock Quantity", 0D, '', '');
        VerifyRequisitionLineCount(1);  // Expected no of lines in Planning Worksheet. Value important.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyWithSafetyStock()
    var
        Item: Record Item;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        // [FEATURE] [Safety Stock]

        // Setup: Create Item with Planning parameters.
        Initialize();
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1Y>', '<1Y>', true, LibraryRandom.RandDec(5, 2) + 10, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.

        // Create Demand - Supply Scenario With Random Value taking Global Variable for Sales and Purchase.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(10), GetRandomDateUsingWorkDate(15), GetRandomDateUsingWorkDate(25));  // Dates based on WORKDATE.
        CreateDemandQuantity(
          DemandQuantityValue, LibraryRandom.RandDec(5, 2) + 15, LibraryRandom.RandDec(5, 2),
          LibraryRandom.RandDec(5, 2) + 10);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 3);  // Number of Sales Order.

        CreateSupplyType(SupplyType, SupplyType::Purchase, SupplyType::None, SupplyType::None, SupplyType::None, SupplyType::None);
        CreateSupplyDate(SupplyDateValue, GetRandomDateUsingWorkDate(20), 0D, 0D, 0D, 0D);  // Dates based on WORKDATE.
        CreateSupplyQuantity(SupplyQuantityValue, LibraryRandom.RandDec(5, 2) + 5, 0, 0, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, '', Item."No.", '');

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(90));  // Dates based on WORKDATE.

        // Verify: Verify Planning Worksheet lines.
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::New, WorkDate(), 0,
          Item."Safety Stock Quantity" + DemandQuantityValue[1] + DemandQuantityValue[2] + DemandQuantityValue[3], 0D, '', '');
        VerifyRequisitionLine(Item."No.", RequisitionLine."Action Message"::Cancel, SupplyDateValue[1], SupplyQuantityValue[1], 0, 0D, '', '');
        VerifyRequisitionLineCount(2);  // Expected no of lines in Planning Worksheet. Value important.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyWithSafetyStockWithInventory()
    var
        Item: Record Item;
        SafetyStockQty: Decimal;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        // [FEATURE] [Safety Stock]

        // Setup: Create Item with Planning parameters.
        Initialize();
        SafetyStockQty := LibraryRandom.RandDec(5, 2) + 5;
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1Y>', '<1Y>', true, SafetyStockQty, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.

        // Create Demand - Supply scenario with random values taking Global Variable for Sales and Purchase.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(10), GetRandomDateUsingWorkDate(15), GetRandomDateUsingWorkDate(25));  // Dates based on WORKDATE.
        CreateDemandQuantity(
          DemandQuantityValue, SafetyStockQty, LibraryRandom.RandDec(5, 2), LibraryRandom.RandDec(5, 2) + 10);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 3);  // Number of Sales Order.

        CreateSupplyType(SupplyType, SupplyType::Purchase, SupplyType::None, SupplyType::None, SupplyType::None, SupplyType::None);
        CreateSupplyDate(SupplyDateValue, GetRandomDateUsingWorkDate(20), 0D, 0D, 0D, 0D);  // Dates based on WORKDATE.
        CreateSupplyQuantity(SupplyQuantityValue, LibraryRandom.RandDec(5, 2) + 5, 0, 0, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, '', Item."No.", '');
        UpdateItemInventory(Item."No.", 2 * SafetyStockQty);  // Values important for test.

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(90));  // Dates based on WORKDATE.

        // Verify: Verify Planning Worksheet lines.
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::"Resched. & Chg. Qty.", DemandDateValue[2], SupplyQuantityValue[1],
          DemandQuantityValue[2] + DemandQuantityValue[3], SupplyDateValue[1], '', '');
        VerifyRequisitionLineCount(1);  // Expected no of lines in Planning Worksheet. Value important.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyWithoutSafetyStockAndInventory()
    var
        Item: Record Item;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        // [FEATURE] [Resheduling Period] [Lot Accumulation Period]

        // Setup: Create Item with Planning parameters.
        Initialize();
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1Y>', '<1Y>', false, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.

        // Create Demand - Supply Scenario with random values taking Global Variable for Sales and Purchase.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(10), GetRandomDateUsingWorkDate(15), GetRandomDateUsingWorkDate(25));  // Dates based on WORKDATE.
        CreateDemandQuantity(
          DemandQuantityValue, LibraryRandom.RandDec(5, 2) + 15, LibraryRandom.RandDec(5, 2),
          LibraryRandom.RandDec(5, 2) + 10);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 3);  // Number of Sales Order.

        CreateSupplyType(SupplyType, SupplyType::Purchase, SupplyType::None, SupplyType::None, SupplyType::None, SupplyType::None);
        CreateSupplyDate(SupplyDateValue, GetRandomDateUsingWorkDate(20), 0D, 0D, 0D, 0D);  // Dates based on WORKDATE.
        CreateSupplyQuantity(SupplyQuantityValue, LibraryRandom.RandDec(5, 2) + 5, 0, 0, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, '', Item."No.", '');

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(90));  // Dates based on WORKDATE.

        // Verify: Verify Planning Worksheet lines.
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::"Resched. & Chg. Qty.", DemandDateValue[1], SupplyQuantityValue[1],
          DemandQuantityValue[1] + DemandQuantityValue[2] + DemandQuantityValue[3], SupplyDateValue[1], '', '');
        VerifyRequisitionLineCount(1);  // Expected no of lines in Planning Worksheet. Value important.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandWithSafetyStockAndInventory()
    var
        Item: Record Item;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
    begin
        // [FEATURE] [Resheduling Period] [Lot Accumulation Period] [Safety Stock]

        // Setup: Create Item with Planning parameters.
        Initialize();
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<2W>', '<2W>', true, LibraryRandom.RandDec(5, 2) + 10, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.

        // Create Demand only  with random values taking Global Variable for Sales.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(10), GetRandomDateUsingWorkDate(15), GetRandomDateUsingWorkDate(25));  // Dates based on WORKDATE.
        CreateDemandQuantity(
          DemandQuantityValue, LibraryRandom.RandDec(5, 2) + 15, LibraryRandom.RandDec(5, 2),
          LibraryRandom.RandDec(5, 2) + 10);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 3);  // Number of Sales Order.

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(90));  // Dates based on WORKDATE.

        // Verify: Verify Planning Worksheet lines.
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::New, WorkDate(), 0, Item."Safety Stock Quantity" + DemandQuantityValue[1], 0D, '', '');
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::New, DemandDateValue[2], 0, DemandQuantityValue[2] + DemandQuantityValue[3], 0D, '',
          '');
        VerifyRequisitionLineCount(2);  // Expected no of lines in Planning Worksheet. Value important.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyFromPurchaseWithoutSafetyStock()
    var
        Item: Record Item;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        // [FEATURE] [Resheduling Period] [Lot Accumulation Period]

        // Setup: Create Item with Planning parameters.
        Initialize();
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<2W>', '<2W>', false, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.

        // Create Supply only  with random values taking Global Variable for Purchase.
        CreateSupplyType(SupplyType, SupplyType::Purchase, SupplyType::None, SupplyType::None, SupplyType::None, SupplyType::None);
        CreateSupplyDate(SupplyDateValue, GetRandomDateUsingWorkDate(20), 0D, 0D, 0D, 0D);  // Dates based on WORKDATE.
        CreateSupplyQuantity(SupplyQuantityValue, LibraryRandom.RandDec(5, 2) + 5, 0, 0, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, '', Item."No.", '');

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(90));  // Dates based on WORKDATE.

        // Verify: Verify Planning Worksheet lines.
        VerifyRequisitionLine(Item."No.", RequisitionLine."Action Message"::Cancel, SupplyDateValue[1], SupplyQuantityValue[1], 0, 0D, '', '');
        VerifyRequisitionLineCount(1);  // Expected no of lines in Planning Worksheet. Value important.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyWithSafetyStockCarryOutActionMessage()
    var
        Item: Record Item;
        PlanningLinesCountBeforeCarryOut: Integer;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        // [FEATURE] [Carry Out Action Message]

        // Setup: Create Item with Planning parameters.
        Initialize();
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1Y>', '<1Y>', true, LibraryRandom.RandDec(5, 2) + 10, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.

        // Create Demand - Supply Scenario with random values taking Global Variable for Sales and Purchase.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(10), GetRandomDateUsingWorkDate(15), GetRandomDateUsingWorkDate(25));  // Dates based on WORKDATE.
        CreateDemandQuantity(
          DemandQuantityValue, LibraryRandom.RandDec(5, 2) + 15, LibraryRandom.RandDec(5, 2),
          LibraryRandom.RandDec(5, 2) + 10);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 3);  // Number of Sales Order.

        CreateSupplyType(SupplyType, SupplyType::Purchase, SupplyType::None, SupplyType::None, SupplyType::None, SupplyType::None);
        CreateSupplyDate(SupplyDateValue, GetRandomDateUsingWorkDate(20), 0D, 0D, 0D, 0D);  // Dates based on WORKDATE.
        CreateSupplyQuantity(SupplyQuantityValue, LibraryRandom.RandDec(5, 2) + 5, 0, 0, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, '', Item."No.", '');
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(90));  // Dates based on WORKDATE.

        // Exercise: Carry Out Action Message on Planning Worksheet lines.
        AcceptActionMessageAndCarryOutActionMessagePlan(Item."No.", PlanningLinesCountBeforeCarryOut);

        // Verify: Verify that all the Planning Worksheet Lines are cleared after Carry Out Action message.
        VerifyPlanningWorksheetEmpty(PlanningLinesCountBeforeCarryOut, Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyLessThanDampenerWithoutActionMessage()
    begin
        // [FEATURE] [Dampener Quantity]
        Initialize();
        SupplyWithDampenerQuantity(LibraryRandom.RandDec(10, 2) + 50, LibraryRandom.RandDec(5, 2) + 5, false);  // Dampener quantity greater than Purchase Qty.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyMoreThanDampenerWithActionMessage()
    begin
        // [FEATURE] [Dampener Quantity]
        Initialize();
        SupplyWithDampenerQuantity(LibraryRandom.RandDec(10, 2) + 50, LibraryRandom.RandDec(5, 2) + 100, true);  // Dampener quantity less than Purchase Qty.
    end;

    local procedure SupplyWithDampenerQuantity(DampenerQty: Decimal; PurchaseQty: Decimal; ActionMessageCancel: Boolean)
    var
        Item: Record Item;
        RequisitionLine2: Record "Requisition Line";
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        Initialize();

        // Create Item with supply and Dampener Quantity to avoid frequent action messages.
        CreateLFLItem(Item, Item."Replenishment System"::Purchase, '<1Y>', '<1Y>', true, 0, DampenerQty);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.

        // Create Supply only  with random values taking Global Variable for Purchase.
        CreateSupplyType(SupplyType, SupplyType::Purchase, SupplyType::None, SupplyType::None, SupplyType::None, SupplyType::None);
        CreateSupplyDate(SupplyDateValue, GetRandomDateUsingWorkDate(30), 0D, 0D, 0D, 0D);  // Dates based on WORKDATE.
        CreateSupplyQuantity(SupplyQuantityValue, PurchaseQty, 0, 0, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, '', Item."No.", '');

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));

        // Verify: Verify action messages if supply more than dampener else check that no lines is generated on Planning worksheet.
        if ActionMessageCancel then begin
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::Cancel, SupplyDateValue[1], SupplyQuantityValue[1], 0, 0D, '', '');
            VerifyRequisitionLineCount(1);  // Expected no of lines in Planning Worksheet. Value important.
        end else begin
            RequisitionLine2.SetRange("No.", Item."No.");
            Assert.AreEqual(0, RequisitionLine2.Count, NumberOfLineEqualError);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyInReschedulingWithoutLotAccumulation()
    begin
        // [FEATURE] [Resheduling Period]

        Initialize();
        DemandSupplyWithReschedulingOnly('<1Y>');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyOutsideReschedulingWithoutLotAccumulation()
    begin
        // [FEATURE] [Resheduling Period]

        Initialize();
        DemandSupplyWithReschedulingOnly('<1W>');
    end;

    local procedure DemandSupplyWithReschedulingOnly(ReschedulingPeriod: Text[30])
    var
        Item: Record Item;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        Initialize();

        // Create Item with Planning parameters.
        CreateLFLItem(Item, Item."Replenishment System"::Purchase, ReschedulingPeriod, '<0D>', true, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.

        // Create Demand - Supply Scenario with random values taking Global Variable for Sales and Purchase.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(30), 0D, 0D);  // Dates based on WORKDATE.
        CreateDemandQuantity(DemandQuantityValue, LibraryRandom.RandDec(5, 2) + 20, 0, 0);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 1);  // Number of Sales Order.

        CreateSupplyType(SupplyType, SupplyType::Purchase, SupplyType::None, SupplyType::None, SupplyType::None, SupplyType::None);
        CreateSupplyDate(SupplyDateValue, GetRandomDateUsingWorkDate(30), 0D, 0D, 0D, 0D);  // Dates based on WORKDATE.
        CreateSupplyQuantity(SupplyQuantityValue, LibraryRandom.RandDec(5, 2) + 10, 0, 0, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, '', Item."No.", '');

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));

        // Verify: Verify planning worksheet.
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::"Change Qty.", DemandDateValue[1], SupplyQuantityValue[1], DemandQuantityValue[1],
          0D, '', '');
        VerifyRequisitionLineCount(1);  // Expected no of lines in Planning Worksheet. Value important.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyInLotAccumulationPeriodWithoutRescheduling()
    begin
        // [FEATURE] [Lot Accumulation Period]

        Initialize();
        DemandSupplyWithLotAccumulationOnly('<1W>');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyOutsideLotAccumulationPeriodWithoutRescheduling()
    begin
        // [FEATURE] [Lot Accumulation Period]

        Initialize();
        DemandSupplyWithLotAccumulationOnly('<1Y>');
    end;

    local procedure DemandSupplyWithLotAccumulationOnly(LotAccumulationPeriod: Text[30])
    var
        Item: Record Item;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        Initialize();

        // Create Item with Planning parameters.
        CreateLFLItem(Item, Item."Replenishment System"::Purchase, '<0D>', LotAccumulationPeriod, true, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.

        // Create Demand - Supply Scenario with random values taking Global Variable for Sales and Purchase.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(30), 0D, 0D);  // Dates based on WORKDATE.
        CreateDemandQuantity(DemandQuantityValue, LibraryRandom.RandDec(5, 2) + 20, 0, 0);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 1);  // Number of Sales Order.

        CreateSupplyType(SupplyType, SupplyType::Purchase, SupplyType::None, SupplyType::None, SupplyType::None, SupplyType::None);
        CreateSupplyDate(SupplyDateValue, GetRandomDateUsingWorkDate(30), 0D, 0D, 0D, 0D);  // Dates based on WORKDATE.
        CreateSupplyQuantity(SupplyQuantityValue, LibraryRandom.RandDec(5, 2) + 10, 0, 0, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, '', Item."No.", '');

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));

        // Verify: Verify planning worksheet.
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::"Change Qty.", DemandDateValue[1], SupplyQuantityValue[1], DemandQuantityValue[1],
          0D, '', '');
        VerifyRequisitionLineCount(1);  // Expected no of lines in Planning Worksheet. Value important.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyWithDifferentReschedulingAndLotAccumulation()
    var
        Item: Record Item;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        // [FEATURE] [Resheduling Period] [Lot Accumulation Period]
        // Setup: Create Item with Planning parameters.
        Initialize();
        CreateLFLItem(Item, Item."Replenishment System"::Purchase, '<1W>', '<1Y>', true, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.

        // Create Demand - Supply Scenario with random values taking Global Variable for Sales and Purchase.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(30), 0D, 0D);  // Dates based on WORKDATE.
        CreateDemandQuantity(DemandQuantityValue, LibraryRandom.RandDec(5, 2) + 20, 0, 0);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 1);  // Number of Sales Order.

        CreateSupplyType(SupplyType, SupplyType::Purchase, SupplyType::None, SupplyType::None, SupplyType::None, SupplyType::None);
        CreateSupplyDate(SupplyDateValue, GetRandomDateUsingWorkDate(30), 0D, 0D, 0D, 0D);  // Dates based on WORKDATE.
        CreateSupplyQuantity(SupplyQuantityValue, LibraryRandom.RandDec(5, 2) + 10, 0, 0, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, '', Item."No.", '');

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));

        // Verify: Verify planning worksheet.
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::"Change Qty.", DemandDateValue[1], SupplyQuantityValue[1], DemandQuantityValue[1],
          0D, '', '');
        VerifyRequisitionLineCount(1);  // Expected no of lines in Planning Worksheet. Value important.
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,AvailableProdOrderLineReservePageHandler')]
    [Scope('OnPrem')]
    procedure DemandSupplyInReschedulingAndFirstFromFirstReservationForLFLItem()
    var
        ItemNo: Code[20];
        DummyCount: Integer;
    begin
        // [FEATURE] [Planning Worksheet] [Sales Order] [Production Order] [Reservation]
        // [SCENARIO 379964] The sequence of supply and demand documents, in which the earliest demand is reserved from the earliest supply, should provide continious Item availability after the supplies are rescheduled.
        Initialize();

        // [GIVEN] Item with Lot-for-Lot Reordering Policy and Rescheduling Period.
        // [GIVEN] Two Sales Orders "S1", "S2" (sorted by Shipment Date) within the Rescheduling Period.
        // [GIVEN] Two Released Production Orders "P1", "P2" (sorted by Due Date) within the Rescheduling Period.
        // [GIVEN] Sales Order "S1" is reserved from Production Order "P1".
        // [GIVEN] Regenerative Plan is calculated.
        PrepareSupplyAndDemandWithReservationAndCalcRegenPlan(ItemNo, 1, 1);

        // [WHEN] Carry Out Action Message.
        AcceptActionMessageAndCarryOutActionMessagePlan(ItemNo, DummyCount);

        // [THEN] Projected inventory for Item never goes negative.
        VerifyProjectedInventory(ItemNo);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,AvailableProdOrderLineReservePageHandler')]
    [Scope('OnPrem')]
    procedure DemandSupplyInReschedulingAndFirstFromLastReservationForLFLItem()
    var
        ItemNo: Code[20];
        DummyCount: Integer;
    begin
        // [FEATURE] [Planning Worksheet] [Sales Order] [Production Order] [Reservation]
        // [SCENARIO 379964] The sequence of supply and demand documents, in which the earliest demand is reserved from the latest supply, should provide continious Item availability after the supplies are rescheduled.
        Initialize();

        // [GIVEN] Item with Lot-for-Lot Reordering Policy and Rescheduling Period.
        // [GIVEN] Two Sales Orders "S1", "S2" (sorted by Shipment Date) within the Rescheduling Period.
        // [GIVEN] Two Released Production Orders "P1", "P2" (sorted by Due Date) within the Rescheduling Period.
        // [GIVEN] Sales Order "S1" is reserved from Production Order "P2".
        // [GIVEN] Regenerative Plan is calculated.
        PrepareSupplyAndDemandWithReservationAndCalcRegenPlan(ItemNo, 1, 2);

        // [WHEN] Carry Out Action Message.
        AcceptActionMessageAndCarryOutActionMessagePlan(ItemNo, DummyCount);

        // [THEN] Projected inventory for Item never goes negative.
        VerifyProjectedInventory(ItemNo);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,AvailableProdOrderLineReservePageHandler')]
    [Scope('OnPrem')]
    procedure DemandSupplyInReschedulingAndLastFromFirstReservationForLFLItem()
    var
        ItemNo: Code[20];
        DummyCount: Integer;
    begin
        // [FEATURE] [Planning Worksheet] [Sales Order] [Production Order] [Reservation]
        // [SCENARIO 379964] The sequence of supply and demand documents, in which the latest demand is reserved from the earliest supply, should provide continious Item availability after the supplies are rescheduled.
        Initialize();

        // [GIVEN] Item with Lot-for-Lot Reordering Policy and Rescheduling Period.
        // [GIVEN] Two Sales Orders "S1", "S2" (sorted by Shipment Date) within the Rescheduling Period.
        // [GIVEN] Two Released Production Orders "P1", "P2" (sorted by Due Date) within the Rescheduling Period.
        // [GIVEN] Sales Order "S2" is reserved from Production Order "P1".
        // [GIVEN] Regenerative Plan is calculated.
        PrepareSupplyAndDemandWithReservationAndCalcRegenPlan(ItemNo, 2, 1);

        // [WHEN] Carry Out Action Message.
        AcceptActionMessageAndCarryOutActionMessagePlan(ItemNo, DummyCount);

        // [THEN] Projected inventory for Item never goes negative.
        VerifyProjectedInventory(ItemNo);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,AvailableProdOrderLineReservePageHandler')]
    [Scope('OnPrem')]
    procedure DemandSupplyInReschedulingAndLastFromLastReservationForLFLItem()
    var
        ItemNo: Code[20];
        DummyCount: Integer;
    begin
        // [FEATURE] [Planning Worksheet] [Sales Order] [Production Order] [Reservation]
        // [SCENARIO 379964] The sequence of supply and demand documents, in which the latest demand is reserved from the latest supply, should provide continious Item availability after the supplies are rescheduled.
        Initialize();

        // [GIVEN] Item with Lot-for-Lot Reordering Policy and Rescheduling Period.
        // [GIVEN] Two Sales Orders "S1", "S2" (sorted by Shipment Date) within the Rescheduling Period.
        // [GIVEN] Two Released Production Orders "P1", "P2" (sorted by Due Date) within the Rescheduling Period.
        // [GIVEN] Sales Order "S2" is reserved from Production Order "P2".
        // [GIVEN] Regenerative Plan is calculated.
        PrepareSupplyAndDemandWithReservationAndCalcRegenPlan(ItemNo, 2, 2);

        // [WHEN] Carry Out Action Message.
        AcceptActionMessageAndCarryOutActionMessagePlan(ItemNo, DummyCount);

        // [THEN] Projected inventory for Item never goes negative.
        VerifyProjectedInventory(ItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyReschedulingPeriodInWeek()
    var
        Item: Record Item;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        // [FEATURE] [Resheduling Period] [Lot Accumulation Period]
        // Setup: Create Item with Planning parameters.
        Initialize();
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1W>', '<1W>', true, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.

        // Create Demand - Supply Scenario with random values taking Global Variable for Sales and Production.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(6), GetRandomDateUsingWorkDate(8), 0D);  // Dates based on WORKDATE.
        CreateDemandQuantity(DemandQuantityValue, LibraryRandom.RandDec(5, 2) + 10, LibraryRandom.RandDec(5, 2) + 30, 0);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 2);  // Number of Sales Order.

        CreateSupplyType(SupplyType, SupplyType::Released, SupplyType::Released, SupplyType::None, SupplyType::None, SupplyType::None);
        CreateSupplyDate(SupplyDateValue, GetRandomDateUsingWorkDate(5), GetRandomDateUsingWorkDate(7), 0D, 0D, 0D);  // Dates based on WORKDATE.
        CreateSupplyQuantity(SupplyQuantityValue, LibraryRandom.RandDec(5, 2) + 5, LibraryRandom.RandDec(5, 2) + 15, 0, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, Item."No.", '', '');

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(30));

        // Verify: Verify planning worksheet.
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::"Resched. & Chg. Qty.", DemandDateValue[1], SupplyQuantityValue[1],
          DemandQuantityValue[1] + DemandQuantityValue[2], SupplyDateValue[1], '', '');
        VerifyRequisitionLine(Item."No.", RequisitionLine."Action Message"::Cancel, SupplyDateValue[2], SupplyQuantityValue[2], 0, 0D, '', '');
        VerifyRequisitionLineCount(2);  // Expected no of lines in Planning Worksheet. Value important.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyReschedulingPeriodInWeekWithOutput()
    var
        Item: Record Item;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        // [FEATURE] [Resheduling Period] [Lot Accumulation Period]
        // Setup: Create Item with Planning parameters.
        Initialize();
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1W>', '<1W>', true, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.

        // Create Demand - Supply Scenario with random values taking Global Variable for Sales and Production.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(6), GetRandomDateUsingWorkDate(8), 0D);  // Dates based on WORKDATE.
        CreateDemandQuantity(DemandQuantityValue, LibraryRandom.RandDec(5, 2) + 10, LibraryRandom.RandDec(5, 2) + 30, 0);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 2);  // Number of Sales Order.

        CreateSupplyType(SupplyType, SupplyType::Released, SupplyType::Released, SupplyType::None, SupplyType::None, SupplyType::None);
        CreateSupplyDate(SupplyDateValue, GetRandomDateUsingWorkDate(5), GetRandomDateUsingWorkDate(7), 0D, 0D, 0D);  // Dates based on WORKDATE.
        CreateSupplyQuantity(SupplyQuantityValue, LibraryRandom.RandDec(5, 2) + 5, LibraryRandom.RandDec(5, 2) + 15, 0, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, Item."No.", '', '');
        CreateAndPostOutputJournal(Item."No.", GlobalProductionOrder[1]."No.");

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(30));

        // Verify: Verify planning worksheet.
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::"Resched. & Chg. Qty.", DemandDateValue[1], SupplyQuantityValue[2],
          DemandQuantityValue[1] + DemandQuantityValue[2] - SupplyQuantityValue[1], SupplyDateValue[2], '', '');
        VerifyRequisitionLineCount(1);  // Expected no of lines in Planning Worksheet. Value important.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyReschedulingPeriodInWeekWithSalesVariant()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        ItemVariant: Record "Item Variant";
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        // [FEATURE] [Resheduling Period] [Lot Accumulation Period] [Variant]
        // Setup: Create Item with Planning parameters.

        Initialize();
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1W>', '<1W>', true, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // Create Demand - Supply Scenario with random values taking Global Variable for Sales and Production.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(6), GetRandomDateUsingWorkDate(8), 0D);  // Dates based on WORKDATE.
        CreateDemandQuantity(DemandQuantityValue, LibraryRandom.RandDec(5, 2) + 10, LibraryRandom.RandDec(5, 2) + 30, 0);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 2);  // Number of Sales Order.

        CreateSupplyType(SupplyType, SupplyType::Released, SupplyType::Released, SupplyType::None, SupplyType::None, SupplyType::None);
        CreateSupplyDate(SupplyDateValue, GetRandomDateUsingWorkDate(5), GetRandomDateUsingWorkDate(7), 0D, 0D, 0D);  // Dates based on WORKDATE.
        CreateSupplyQuantity(SupplyQuantityValue, LibraryRandom.RandDec(5, 2) + 5, LibraryRandom.RandDec(5, 2) + 15, 0, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, Item."No.", '', '');

        CreateAndPostOutputJournal(Item."No.", GlobalProductionOrder[1]."No.");
        UpdateVariantOnSales(SalesLine, GlobalSalesHeader[1]."No.", ItemVariant.Code);

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(30));

        // Verify: Verify planning worksheet.
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::"Resched. & Chg. Qty.", DemandDateValue[2], SupplyQuantityValue[2],
          DemandQuantityValue[2] - SupplyQuantityValue[1], SupplyDateValue[2], '', '');
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::New, DemandDateValue[1], 0, DemandQuantityValue[1], 0D, '', ItemVariant.Code);
        VerifyRequisitionLineCount(2);  // Expected no of lines in Planning Worksheet. Value important.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyReschedulingPeriodInWeekWithProductionVariant()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        ItemVariant: Record "Item Variant";
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        // [FEATURE] [Resheduling Period] [Lot Accumulation Period] [Variant]
        // Setup: Create Item with Planning parameters.
        Initialize();
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1W>', '<1W>', true, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // Create Demand - Supply Scenario with random values taking Global Variable for Sales and Production.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(6), GetRandomDateUsingWorkDate(8), 0D);  // Dates based on WORKDATE.
        CreateDemandQuantity(DemandQuantityValue, LibraryRandom.RandDec(5, 2) + 10, LibraryRandom.RandDec(5, 2) + 30, 0);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 2);  // Number of Sales Order.

        CreateSupplyType(SupplyType, SupplyType::Released, SupplyType::Released, SupplyType::None, SupplyType::None, SupplyType::None);
        CreateSupplyDate(SupplyDateValue, GetRandomDateUsingWorkDate(5), GetRandomDateUsingWorkDate(7), 0D, 0D, 0D);  // Dates based on WORKDATE.
        CreateSupplyQuantity(SupplyQuantityValue, LibraryRandom.RandDec(5, 2) + 5, LibraryRandom.RandDec(5, 2) + 15, 0, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, Item."No.", '', '');

        CreateAndPostOutputJournal(Item."No.", GlobalProductionOrder[1]."No.");
        UpdateVariantOnSales(SalesLine, GlobalSalesHeader[1]."No.", ItemVariant.Code);
        UpdateVariantOnProduction(GlobalProductionOrder[2]."No.", GlobalProductionOrder[2].Status, ItemVariant.Code);

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(30));

        // Verify: Verify planning worksheet.
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::"Resched. & Chg. Qty.", DemandDateValue[1], SupplyQuantityValue[2],
          DemandQuantityValue[1], SupplyDateValue[2], '', ItemVariant.Code);
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::New, DemandDateValue[2], 0, DemandQuantityValue[2] - SupplyQuantityValue[1], 0D, '',
          '');
        VerifyRequisitionLineCount(2);  // Expected no of lines in Planning Worksheet. Value important.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyWithReschedulingPeriodWeekWithoutChildItem()
    begin
        // [FEATURE] [Resheduling Period] [Production BOM]

        Initialize();
        DemandSupplyWithProdBOM(false);  // ChildItem -False.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyWithReschedulingPeriodWeekWithoutProdBOMOnItem()
    begin
        // [FEATURE] [Resheduling Period] [Production BOM]

        Initialize();
        DemandSupplyWithProdBOM(true);  // ChildItem -True.
    end;

    local procedure DemandSupplyWithProdBOM(ChildItem: Boolean)
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        Initialize();

        // Create Item with Planning parameters.
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1W>', '<1W>', true, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.
        if ChildItem then
            CreateChildItemSetup(Item2, Item."Base Unit of Measure", ProductionBOMHeader, '<1W>');  // Rescheduling Period

        // Create Demand - Supply Scenario with random values taking Global Variable for Sales and Production.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(25), GetRandomDateUsingWorkDate(55), 0D);  // Dates based on WORKDATE.
        CreateDemandQuantity(DemandQuantityValue, LibraryRandom.RandInt(100) + 800, LibraryRandom.RandInt(100) + 1000, 0);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 2);  // Number of Sales Order.

        CreateSupplyType(SupplyType, SupplyType::Released, SupplyType::Released, SupplyType::Released, SupplyType::None, SupplyType::None);
        CreateSupplyDate(
          SupplyDateValue, GetRandomDateUsingWorkDate(15), GetRandomDateUsingWorkDate(25), GetRandomDateUsingWorkDate(50), 0D, 0D);  // Dates based on WORKDATE.
        CreateSupplyQuantity(SupplyQuantityValue, DemandQuantityValue[2], DemandQuantityValue[2], DemandQuantityValue[2], 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, Item."No.", '', '');

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));  // Dates based on WORKDATE
        if ChildItem then
            LibraryPlanning.CalcRegenPlanForPlanWksh(Item2, WorkDate(), GetRandomDateUsingWorkDate(60));  // Dates based on WORKDATE

        // Verify: Verify planning worksheet.
        VerifyRequisitionLine(Item."No.", RequisitionLine."Action Message"::Cancel, SupplyDateValue[1], SupplyQuantityValue[1], 0, 0D, '', '');
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::"Change Qty.", SupplyDateValue[2], SupplyQuantityValue[2], DemandQuantityValue[1],
          0D, '', '');
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::Reschedule, DemandDateValue[2], 0, SupplyQuantityValue[3], SupplyDateValue[3], '', '');
        VerifyRequisitionLineCount(3);  // Expected no of lines in Planning Worksheet. Value important.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyWithReschedulingPeriodWeekWithProdBOMOnItem()
    begin
        // [FEATURE] [Resheduling Period] [Production BOM]

        Initialize();
        DemandSupplyWithProdComponentAndProdBOM(false);  // ProductionComponent -True;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyWithReschedulingPeriodWeekWithProdComponent()
    begin
        // [FEATURE] [Resheduling Period] [Production BOM]

        Initialize();
        DemandSupplyWithProdComponentAndProdBOM(true);  // ProductionComponent -True;
    end;

    local procedure DemandSupplyWithProdComponentAndProdBOM(ProductionComponent: Boolean)
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        RequisitionLine2: Record "Requisition Line";
        PlanningComponent: Record "Planning Component";
        Direction: Option Forward,Backward;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        Initialize();

        // Create Item with Planning parameters.
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1W>', '<1W>', true, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.
        CreateChildItemSetup(Item2, Item."Base Unit of Measure", ProductionBOMHeader, '<1W>');  // Rescheduling Period

        // Create Demand - Supply Scenario with random values taking Global Variable for Sales and Production.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(25), GetRandomDateUsingWorkDate(55), 0D);  // Dates based on WORKDATE.
        CreateDemandQuantity(DemandQuantityValue, LibraryRandom.RandInt(100) + 800, LibraryRandom.RandInt(100) + 1000, 0);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 2);  // Number of Sales Order.

        CreateSupplyType(SupplyType, SupplyType::Released, SupplyType::Released, SupplyType::Released, SupplyType::None, SupplyType::None);
        CreateSupplyDate(
          SupplyDateValue, GetRandomDateUsingWorkDate(15), GetRandomDateUsingWorkDate(25), GetRandomDateUsingWorkDate(50), 0D, 0D);  // Dates based on WORKDATE.
        CreateSupplyQuantity(SupplyQuantityValue, DemandQuantityValue[2], DemandQuantityValue[2], DemandQuantityValue[2], 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, Item."No.", '', '');

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));  // Dates based on WORKDATE
        UpdateItem(Item, Item.FieldNo("Production BOM No."), ProductionBOMHeader."No.");

        if ProductionComponent then
            CreateProdOrderComponent(GlobalProductionOrder[2], Item2."No.");

        // Exercise: Calculate Regenerative Plan.
        FilterRequisitionLine(RequisitionLine2, Item."No.");
        LibraryPlanning.RefreshPlanningLine(RequisitionLine2, Direction::Backward, true, true);

        // Verify: Verify planning worksheet.
        PlanningComponent.SetRange("Item No.", Item2."No.");
        Assert.AreEqual(0, PlanningComponent.Count, NumberOfLineEqualError);  // Zero for empty line.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyWithReschedulingPeriodWeekParentAndChildItem()
    begin
        // [FEATURE] [Resheduling Period] [Production BOM]

        Initialize();
        DemandSupplyWithParentAndChildItem('<1W>', true);  // ReschedulingPeriod - One Week and Reschedule as True.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyWithReschedulingPeriodYearParentAndChildItem()
    begin
        // [FEATURE] [Resheduling Period] [Production BOM]

        Initialize();
        DemandSupplyWithParentAndChildItem('<1Y>', false);  // ReschedulingPeriod - One Year and Reschedule as False.
    end;

    local procedure DemandSupplyWithParentAndChildItem(ReschedulingPeriod: Text[30]; Reschedule: Boolean)
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        Initialize();

        // Create Item with Planning parameters.
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", ReschedulingPeriod, ReschedulingPeriod, true, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.
        CreateChildItemSetup(Item2, Item."Base Unit of Measure", ProductionBOMHeader, '<1W>');  // Rescheduling Period
        UpdateItem(Item, Item.FieldNo("Production BOM No."), ProductionBOMHeader."No.");

        // Create Demand - Supply Scenario with random values taking Global Variable for Sales and Production.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(25), GetRandomDateUsingWorkDate(55), 0D);  // Dates based on WORKDATE.
        CreateDemandQuantity(DemandQuantityValue, LibraryRandom.RandInt(100) + 800, LibraryRandom.RandInt(100) + 1000, 0);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 2);  // Number of Sales Order.

        CreateSupplyType(SupplyType, SupplyType::Released, SupplyType::Released, SupplyType::Released, SupplyType::None, SupplyType::None);
        CreateSupplyDate(
          SupplyDateValue, GetRandomDateUsingWorkDate(15), GetRandomDateUsingWorkDate(25), GetRandomDateUsingWorkDate(50), 0D, 0D);  // Dates based on WORKDATE.
        CreateSupplyQuantity(SupplyQuantityValue, DemandQuantityValue[2], DemandQuantityValue[2], DemandQuantityValue[2], 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, Item."No.", '', '');

        // Exercise: Calculate Regenerative Plan.
        Item.SetFilter("No.", '%1|%2', Item."No.", Item2."No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));  // Dates based on WORKDATE

        // Verify: Verify planning worksheet.
        if Reschedule then begin
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::Cancel, SupplyDateValue[1], SupplyQuantityValue[1], 0, 0D, '', '');
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::"Change Qty.", SupplyDateValue[2], SupplyQuantityValue[2],
              DemandQuantityValue[1], 0D, '', '');
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::Reschedule, DemandDateValue[2], 0, SupplyQuantityValue[3], SupplyDateValue[3], '',
              '');
            VerifyRequisitionLine(
              Item2."No.", RequisitionLine."Action Message"::New, SelectDateWithSafetyLeadTime(DemandDateValue[1], -1), 0,
              DemandQuantityValue[1], 0D, '', '');
            VerifyRequisitionLine(
              Item2."No.", RequisitionLine."Action Message"::New, SelectDateWithSafetyLeadTime(DemandDateValue[2], -1), 0,
              DemandQuantityValue[2], 0D, '', '');
            VerifyRequisitionLineCount(5);  // Expected no of lines in Planning Worksheet. Value important.
        end else begin
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::"Resched. & Chg. Qty.", DemandDateValue[1], SupplyQuantityValue[1],
              SupplyQuantityValue[2] + DemandQuantityValue[1], SupplyDateValue[1], '', '');
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::Cancel, SupplyDateValue[2], SupplyQuantityValue[2], 0, 0D, '', '');
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::Cancel, SupplyDateValue[3], SupplyQuantityValue[3], 0, 0D, '', '');
            VerifyRequisitionLine(
              Item2."No.", RequisitionLine."Action Message"::New, SelectDateWithSafetyLeadTime(DemandDateValue[1], -1), 0,
              DemandQuantityValue[1] + DemandQuantityValue[2], 0D, '', '');
            VerifyRequisitionLineCount(4);  // Expected no of lines in Planning Worksheet. Value important.
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyCarryOutActionMessageParentItem()
    begin
        // [FEATURE] [Resheduling Period] [Production BOM] [Carry Out Action Message]

        Initialize();
        DemandSupplyCarryOutActionMessageParentAndChildItem(false);  // CarryOutActionMsgForChild -False.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyCarryOutActionMessageChildItem()
    begin
        // [FEATURE] [Resheduling Period] [Production BOM] [Carry Out Action Message]

        Initialize();
        DemandSupplyCarryOutActionMessageParentAndChildItem(true);  // CarryOutActionMsgForChild -True.
    end;

    local procedure DemandSupplyCarryOutActionMessageParentAndChildItem(CarryOutActionMsgForChild: Boolean)
    var
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        PlanningLinesCountBeforeCarryOut: Integer;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        Initialize();

        // Create Item with Planning parameters.
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1Y>', '<1Y>', true, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.
        CreateChildItemSetup(Item2, Item."Base Unit of Measure", ProductionBOMHeader, '<1Y>');  // Rescheduling Period
        UpdateItem(Item, Item.FieldNo("Production BOM No."), ProductionBOMHeader."No.");

        // Create Demand - Supply Scenario with random values taking Global Variable for Sales and Production.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(25), GetRandomDateUsingWorkDate(55), 0D);  // Dates based on WORKDATE.
        CreateDemandQuantity(DemandQuantityValue, LibraryRandom.RandInt(100) + 800, LibraryRandom.RandInt(100) + 1000, 0);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 2);  // Number of Sales Order.

        CreateSupplyType(SupplyType, SupplyType::Released, SupplyType::Released, SupplyType::Released, SupplyType::None, SupplyType::None);
        CreateSupplyDate(
          SupplyDateValue, GetRandomDateUsingWorkDate(15), GetRandomDateUsingWorkDate(25), GetRandomDateUsingWorkDate(50), 0D, 0D);  // Dates based on WORKDATE.
        CreateSupplyQuantity(SupplyQuantityValue, DemandQuantityValue[2], DemandQuantityValue[2], DemandQuantityValue[2], 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, Item."No.", '', '');

        Item3.SetFilter("No.", '%1|%2', Item."No.", Item2."No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item3, WorkDate(), GetRandomDateUsingWorkDate(60));  // Dates based on WORKDATE
        AcceptActionMessageAndCarryOutActionMessagePlan(Item."No.", PlanningLinesCountBeforeCarryOut);
        if CarryOutActionMsgForChild then
            AcceptActionMessageAndCarryOutActionMessagePlan(Item2."No.", PlanningLinesCountBeforeCarryOut);

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item3, WorkDate(), GetRandomDateUsingWorkDate(60));  // Dates based on WORKDATE

        // Verify: Verify planning worksheet.
        VerifyPlanningWorksheetEmpty(PlanningLinesCountBeforeCarryOut, Item."No.");
        if CarryOutActionMsgForChild then
            VerifyPlanningWorksheetEmpty(PlanningLinesCountBeforeCarryOut, Item2."No.")
        else begin
            VerifyRequisitionLine(
              Item2."No.", RequisitionLine."Action Message"::New, SelectDateWithSafetyLeadTime(DemandDateValue[1], -1), 0,
              DemandQuantityValue[1] + DemandQuantityValue[2], 0D, '', '');
            VerifyRequisitionLineCount(1);  // Expected no of lines in Planning Worksheet. Value important.
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyWithPurchaseOfChildItem()
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        // [FEATURE] [Resheduling Period] [Production BOM]

        // Setup: Create Item with Planning parameters.
        Initialize();
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1Y>', '<1Y>', true, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.
        CreateChildItemSetup(Item2, Item."Base Unit of Measure", ProductionBOMHeader, '<1Y>');  // Rescheduling Period
        UpdateItem(Item, Item.FieldNo("Production BOM No."), ProductionBOMHeader."No.");

        // Create Demand - Supply Scenario with random values taking Global Variable for Sales, Production and Purchase.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(12), 0D, 0D);  // Dates based on WORKDATE.
        CreateDemandQuantity(DemandQuantityValue, LibraryRandom.RandInt(10) + 900, 0, 0);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 2);  // Number of Sales Order.

        CreateSupplyType(SupplyType, SupplyType::Released, SupplyType::Released, SupplyType::Purchase, SupplyType::None, SupplyType::None);
        CreateSupplyDate(
          SupplyDateValue, GetRandomDateUsingWorkDate(5), GetRandomDateUsingWorkDate(45), GetRandomDateUsingWorkDate(25), 0D, 0D);  // Dates based on WORKDATE.
        CreateSupplyQuantity(
          SupplyQuantityValue, LibraryRandom.RandInt(10) + 1000, LibraryRandom.RandInt(10) + 800,
          LibraryRandom.RandInt(10) + 1100, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, Item."No.", Item2."No.", '');

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item2, WorkDate(), GetRandomDateUsingWorkDate(60));

        // Verify: Verify planning worksheet.
        VerifyRequisitionLine(
          Item2."No.", RequisitionLine."Action Message"::"Resched. & Chg. Qty.", SelectDateWithSafetyLeadTime(SupplyDateValue[1], -1),
          SupplyQuantityValue[3], SupplyQuantityValue[1] + SupplyQuantityValue[2], SupplyDateValue[3], '', '');
        VerifyRequisitionLineCount(1);  // Expected no of lines in Planning Worksheet. Value important.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModifyDueDateOnRequisitionLineWithBaseCalendar()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        InventorySetup: Record "Inventory Setup";
        SalesHeader: Record "Sales Header";
        PlanningWorksheet: TestPage "Planning Worksheet";
        DefaultSafetyLeadTime: Integer;
    begin
        // [FEATURE] [Base Calendar]

        // Calculate Regenerative Plan (LFL Item) with Base Calender. Modify "Due Date" and verify "Ending Date" in Requisition line.
        // Have a dependency on DemandSupplyWithChildItemOnRequisitionWorksheetNewBatch,DemandSupplyWithParentItemOnRequisitionWorksheetNewBatch running together.
        Initialize();
        InventorySetup.Get();

        // Setup: Create Base Calendar, set Sunday as working day, other days as non-working day, create Vendor, bind the calendar
        // to the Vendor, create a Lot-For-Lot Item, set the vendor as the supplier. Create a Sales Order, set the shipment date
        // of the sales line as Saturday, set InventorySetup."Default Safety Lead Time" to random value.
        DefaultSafetyLeadTime := LibraryRandom.RandInt(10);
        SetupDemandWithBaseCalendar(Item, SalesHeader, CalcDate('<WD6>', GetRandomDateUsingWorkDate(30)), DefaultSafetyLeadTime);

        // Calculate Regenerative Plan on Planning worksheet.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));

        // Open Planning Worksheet page and go to the generated requisition line.
        FindRequisitionLine(RequisitionLine, Item."No.");
        PlanningWorksheet.OpenEdit();
        PlanningWorksheet.GotoRecord(RequisitionLine);

        // Exercise: Update Due Date from Planning Worksheet page.
        PlanningWorksheet."Due Date".SetValue(CalcDate('<WD6>', RequisitionLine."Ending Date"));

        // Verify: Verify calculating Ending Date from Due Date doesn't need to consider Vendor's calendar.
        FindRequisitionLine(RequisitionLine, Item."No.");
        RequisitionLine.TestField("Ending Date", PlanningWorksheet."Due Date".AsDate() - DefaultSafetyLeadTime);

        // Tear Down.
        UpdateDefaultSafetyLeadTimeOnInventorySetup(InventorySetup."Default Safety Lead Time");
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DemandSupplyWithChildItemOnRequisitionWorksheetNewBatch()
    begin
        // [FEATURE] [Production BOM]

        Initialize();
        DemandSupplyOnRequisitionWorksheetNewBatch(false);  // Child Item -False.
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DemandSupplyWithParentItemOnRequisitionWorksheetNewBatch()
    begin
        // [FEATURE] [Production BOM]

        Initialize();
        DemandSupplyOnRequisitionWorksheetNewBatch(true);  // Child Item -True.
    end;

    local procedure DemandSupplyOnRequisitionWorksheetNewBatch(ChildItem: Boolean)
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        PlanningWorksheet: TestPage "Planning Worksheet";
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        Initialize();

        // Create Item with Planning parameters.
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1Y>', '<1Y>', true, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.
        CreateChildItemSetup(Item2, Item."Base Unit of Measure", ProductionBOMHeader, '<1Y>');  // Rescheduling Period
        UpdateItem(Item, Item.FieldNo("Production BOM No."), ProductionBOMHeader."No.");

        // Create Demand - Supply Scenario with random values taking Global Variable for Sales, Production and Purchase.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(12), 0D, 0D);  // Dates based on WORKDATE.
        CreateDemandQuantity(DemandQuantityValue, LibraryRandom.RandInt(10) + 900, 0, 0);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 2);  // Number of Sales Order.

        CreateSupplyType(SupplyType, SupplyType::Released, SupplyType::Released, SupplyType::Purchase, SupplyType::None, SupplyType::None);
        CreateSupplyDate(
          SupplyDateValue, GetRandomDateUsingWorkDate(5), GetRandomDateUsingWorkDate(45), GetRandomDateUsingWorkDate(25), 0D, 0D);  // Dates based on WORKDATE.
        CreateSupplyQuantity(
          SupplyQuantityValue, LibraryRandom.RandInt(10) + 1000, LibraryRandom.RandInt(10) + 800,
          LibraryRandom.RandInt(10) + 1100, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, Item."No.", Item2."No.", '');
        CreateRequisitionWorksheetName(RequisitionWkshName, ReqWkshTemplate.Type::Planning);
        if ChildItem then
            GlobalItemNo := Item2."No." // Assign Global Variable for Page Handler.
        else
            GlobalItemNo := Item."No.";  // Assign Global Variable for Page Handler.

        // Exercise: Calculate Regenerative Plan.
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name);

        // Verify: Verify planning worksheet.
        OpenPlanningWorksheetPage(PlanningWorksheet, RequisitionWkshName.Name);
        if ChildItem then begin
            VerifyPlanningWorksheet(
              PlanningWorksheet, RequisitionLine."Action Message"::"Resched. & Chg. Qty.", GlobalItemNo,
              SelectDateWithSafetyLeadTime(SupplyDateValue[1], -1), SupplyQuantityValue[3], SupplyQuantityValue[1] + SupplyQuantityValue[2],
              SupplyDateValue[3]);
            VerifyRequisitionLineCount(1);  // Expected no of lines in Planning Worksheet. Value important.
        end else begin
            VerifyPlanningWorksheet(
              PlanningWorksheet, RequisitionLine."Action Message"::"Resched. & Chg. Qty.", GlobalItemNo, DemandDateValue[1],
              SupplyQuantityValue[1], DemandQuantityValue[1], SupplyDateValue[1]);
            PlanningWorksheet.Next();
            VerifyPlanningWorksheet(
              PlanningWorksheet, RequisitionLine."Action Message"::Cancel, GlobalItemNo, SupplyDateValue[2], SupplyQuantityValue[2], 0, 0D);
            VerifyRequisitionLineCount(2);  // Expected no of lines in Planning Worksheet. Value important.
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyWithChildAndParentItemWithoutDefaultDampenerPeriod()
    begin
        // [FEATURE] [Production BOM] [Rescheduling Period] [Lot Accumulation Period]

        // Setup: Create Item with Planning parameters.
        Initialize();
        DemandSupplyWithChildAndParentItemDefaultDampenerPeriod(false);  // Dampener Period -False.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyWithChildAndParentItemWithDefaultDampenerPeriod()
    begin
        // [FEATURE] [Production BOM] [Rescheduling Period] [Lot Accumulation Period] [Dampener Period]

        // Setup: Create Item with Planning parameters.
        Initialize();
        DemandSupplyWithChildAndParentItemDefaultDampenerPeriod(true);  // Dampener Period -True.
    end;

    local procedure DemandSupplyWithChildAndParentItemDefaultDampenerPeriod(DampenerPeriod: Boolean)
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        InventorySetup: Record "Inventory Setup";
        DefaultDampenerPeriod: DateFormula;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        Initialize();

        // Create Item with Planning parameters.
        InventorySetup.Get();
        if DampenerPeriod then begin
            Evaluate(DefaultDampenerPeriod, '<2W>');
            UpdateInventorySetup(DefaultDampenerPeriod);
        end;
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1Y>', '<1Y>', true, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.
        CreateChildItemSetup(Item2, Item."Base Unit of Measure", ProductionBOMHeader, '<1Y>');  // Rescheduling Period
        UpdateItem(Item, Item.FieldNo("Production BOM No."), ProductionBOMHeader."No.");

        // Create Demand - Supply Scenario with random values taking Global Variable for Sales, Production and Purchase.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(12), 0D, 0D);  // Dates based on WORKDATE.
        CreateDemandQuantity(DemandQuantityValue, LibraryRandom.RandInt(10) + 900, 0, 0);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 2);  // Number of Sales Order.

        CreateSupplyType(SupplyType, SupplyType::Released, SupplyType::Released, SupplyType::Purchase, SupplyType::None, SupplyType::None);
        CreateSupplyDate(
          SupplyDateValue, GetRandomDateUsingWorkDate(5), GetRandomDateUsingWorkDate(45), GetRandomDateUsingWorkDate(25), 0D, 0D);  // Dates based on WORKDATE.
        CreateSupplyQuantity(
          SupplyQuantityValue, LibraryRandom.RandInt(10) + 1000, LibraryRandom.RandInt(10) + 800,
          LibraryRandom.RandInt(10) + 1100, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, Item."No.", Item2."No.", '');

        // Exercise: Calculate Regenerative Plan.
        Item.SetFilter("No.", '%1|%2', Item."No.", Item2."No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));

        // Verify: Verify planning worksheet.
        VerifyRequisitionLine(Item."No.", RequisitionLine."Action Message"::Cancel, SupplyDateValue[2], SupplyQuantityValue[2], 0, 0D, '', '');
        if DampenerPeriod then begin
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::"Change Qty.", SupplyDateValue[1], SupplyQuantityValue[1],
              DemandQuantityValue[1], 0D, '', '');
            VerifyRequisitionLine(
              Item2."No.", RequisitionLine."Action Message"::"Resched. & Chg. Qty.", SelectDateWithSafetyLeadTime(SupplyDateValue[1], -1),
              SupplyQuantityValue[3], DemandQuantityValue[1], SupplyDateValue[3], '', '');
        end else begin
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::"Resched. & Chg. Qty.", DemandDateValue[1], SupplyQuantityValue[1],
              DemandQuantityValue[1], SupplyDateValue[1], '', '');
            VerifyRequisitionLine(
              Item2."No.", RequisitionLine."Action Message"::"Resched. & Chg. Qty.", SelectDateWithSafetyLeadTime(DemandDateValue[1], -1),
              SupplyQuantityValue[3], DemandQuantityValue[1], SupplyDateValue[3], '', '');
        end;
        VerifyRequisitionLineCount(3);  // Expected no of lines in Planning Worksheet. Value important.
        // Tear Down.
        UpdateInventorySetup(InventorySetup."Default Dampener Period");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyWithPurchaseOfChildItemCarryOutActionMessage()
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        PlanningLinesCountBeforeCarryOut: Integer;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        // [FEATURE] [Production BOM] [Rescheduling Period] [Lot Accumulation Period] [Carry Out Action Message]

        // Setup: Create Item with Planning parameters.
        Initialize();
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1Y>', '<1Y>', true, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.
        CreateChildItemSetup(Item2, Item."Base Unit of Measure", ProductionBOMHeader, '<1Y>');  // Rescheduling Period
        UpdateItem(Item, Item.FieldNo("Production BOM No."), ProductionBOMHeader."No.");

        // Create Demand - Supply Scenario with random values taking Global Variable for Sales, Production and Purchase.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(12), 0D, 0D);  // Dates based on WORKDATE.
        CreateDemandQuantity(DemandQuantityValue, LibraryRandom.RandInt(10) + 900, 0, 0);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 2);  // Number of Sales Order.

        CreateSupplyType(SupplyType, SupplyType::Released, SupplyType::Released, SupplyType::Purchase, SupplyType::None, SupplyType::None);
        CreateSupplyDate(
          SupplyDateValue, GetRandomDateUsingWorkDate(5), GetRandomDateUsingWorkDate(45), GetRandomDateUsingWorkDate(25), 0D, 0D);  // Dates based on WORKDATE.
        CreateSupplyQuantity(
          SupplyQuantityValue, LibraryRandom.RandInt(10) + 1000, LibraryRandom.RandInt(10) + 800,
          LibraryRandom.RandInt(10) + 1100, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, Item."No.", Item2."No.", '');

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));
        AcceptActionMessageAndCarryOutActionMessagePlan(Item."No.", PlanningLinesCountBeforeCarryOut);

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));

        // Verify: Verify planning worksheet.
        VerifyPlanningWorksheetEmpty(PlanningLinesCountBeforeCarryOut, Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateRegenerativePlanWithPositiveAdjustment()
    var
        Item: Record Item;
        RequisitionLine2: Record "Requisition Line";
    begin
        // Setup: Create Item with Planning parameters.
        Initialize();
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1W>', '<1W>', true, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.
        UpdateItemInventory(Item."No.", LibraryRandom.RandDec(5, 2));

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));  // Dates based on WORKDATE.

        // Verify: Verify Empty planning worksheet.
        RequisitionLine2.SetRange("No.", Item."No.");
        Assert.AreEqual(0, RequisitionLine2.Count, NumberOfLineEqualError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandWithPositiveAdjustment()
    begin
        // [FEATURE] [Rescheduling Period] [Lot Accumulation Period] [Carry Out Action Message]

        Initialize();
        DemandWithPositiveAdjustmentAndCarryOutActionMessage(false) // Change Quantity on Demand as False.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandWithChangeQtyAfterCarryOutActionMessage()
    begin
        // [FEATURE] [Rescheduling Period] [Lot Accumulation Period] [Carry Out Action Message]

        Initialize();
        DemandWithPositiveAdjustmentAndCarryOutActionMessage(true) // Change Quantity on Demand as True.
    end;

    local procedure DemandWithPositiveAdjustmentAndCarryOutActionMessage(ChangeQuantityOnDemand: Boolean)
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        PlanningLinesCountBeforeCarryOut: Integer;
        Quantity: Decimal;
    begin
        Initialize();

        // Create Item with Planning parameters.
        Quantity := LibraryRandom.RandDec(5, 2) + 50;  // Using Random Value.
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1W>', '<1W>', true, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.
        UpdateItemInventory(Item."No.", Quantity);

        // Create Demand setup with Random Values taking Global Variable for Sales.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(5), GetRandomDateUsingWorkDate(10), GetRandomDateUsingWorkDate(15));  // Dates based on WORKDATE.
        CreateDemandQuantity(
          DemandQuantityValue, LibraryRandom.RandDec(5, 2) + 30, LibraryRandom.RandDec(5, 2) + 40,
          LibraryRandom.RandDec(5, 2) + 20);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 3);  // Number of Sales Order.
        if ChangeQuantityOnDemand then begin
            CalcRegenPlanAndCarryOutActionMessagePlan(Item, PlanningLinesCountBeforeCarryOut);
            UpdateQuantityForSales(SalesLine, GlobalSalesHeader[1]."No.", LibraryRandom.RandDec(5, 2) + 60);  // Using Random Values.
        end;

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));  // Dates based on WORKDATE.

        // Verify: Verify planning worksheet.
        if ChangeQuantityOnDemand then begin
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::"Resched. & Chg. Qty.", DemandDateValue[1],
              DemandQuantityValue[1] + DemandQuantityValue[2] + DemandQuantityValue[3] - Quantity,
              SalesLine.Quantity + DemandQuantityValue[2] - Quantity, DemandDateValue[2], '', '');
            VerifyRequisitionLine(Item."No.", RequisitionLine."Action Message"::New, DemandDateValue[3], 0, DemandQuantityValue[3], 0D, '', '');
            VerifyRequisitionLineCount(2);  // Expected no of lines in Planning Worksheet. Value important.
        end else begin
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::New, DemandDateValue[2], 0,
              DemandQuantityValue[1] + DemandQuantityValue[2] + DemandQuantityValue[3] - Quantity, 0D, '', '');
            VerifyRequisitionLineCount(1);  // Expected no of lines in Planning Worksheet. Value important.
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandWithMultipleChangeQtyAfterCarryOutActionMessage()
    begin
        // [FEATURE] [Rescheduling Period] [Lot Accumulation Period] [Carry Out Action Message]

        Initialize();
        DemandWithMultipleChangeQtyAndCarryOutActionMessage(false);  // Carry Out Action Message as False.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandWithPositiveAdjustmentCarryOutActionMessage()
    begin
        // [FEATURE] [Rescheduling Period] [Lot Accumulation Period] [Carry Out Action Message]

        Initialize();
        DemandWithMultipleChangeQtyAndCarryOutActionMessage(true);  // Carry Out Action Message as True.
    end;

    local procedure DemandWithMultipleChangeQtyAndCarryOutActionMessage(CarryOutActionMessage: Boolean)
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        PlanningLinesCountBeforeCarryOut: Integer;
        Quantity: Decimal;
    begin
        Initialize();

        // Create Item with Planning parameters.
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1W>', '<1W>', true, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.
        Quantity := LibraryRandom.RandDec(5, 2) + 50;  // Using Random Values.
        UpdateItemInventory(Item."No.", Quantity);

        // Create Demand setup with Random Values taking Global Variable for Sales.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(5), GetRandomDateUsingWorkDate(10), GetRandomDateUsingWorkDate(15));  // Dates based on WORKDATE.
        CreateDemandQuantity(DemandQuantityValue, Quantity - 20, Quantity - 10, Quantity - 30);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 3);  // Number of Sales Order.

        CalcRegenPlanAndCarryOutActionMessagePlan(Item, PlanningLinesCountBeforeCarryOut);
        UpdateQuantityForSales(SalesLine, GlobalSalesHeader[1]."No.", LibraryRandom.RandDec(5, 2) + 60);  // Using Random Values.

        CalcRegenPlanAndCarryOutActionMessagePlan(Item, PlanningLinesCountBeforeCarryOut);
        UpdateQuantityForSales(SalesLine2, GlobalSalesHeader[1]."No.", LibraryRandom.RandDec(5, 2) + 5);  // Using Random Values.
        CreateSalesOrder(SalesHeader, Item."No.", Quantity, GetRandomDateUsingWorkDate(20));
        if CarryOutActionMessage then
            CalcRegenPlanAndCarryOutActionMessagePlan(Item, PlanningLinesCountBeforeCarryOut);

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));  // Dates based on WORKDATE.

        // Verify: Verify planning worksheet. Verify that all the Planning Worksheet Lines are cleared after Carry Out Action message.
        if CarryOutActionMessage then
            VerifyPlanningWorksheetEmpty(PlanningLinesCountBeforeCarryOut, Item."No.")
        else begin
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::Cancel, DemandDateValue[1],
              SalesLine.Quantity + DemandQuantityValue[2] - Quantity, 0, 0D, '', '');
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::"Change Qty.", GetRandomDateUsingWorkDate(15), DemandQuantityValue[3],
              DemandQuantityValue[2] + DemandQuantityValue[3] + SalesLine2.Quantity, 0D, '', '');
            VerifyRequisitionLineCount(2);  // Expected no of lines in Planning Worksheet. Value important.
        end;
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DemandWithForecast()
    var
        Item: Record Item;
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        InventorySetup: Record "Inventory Setup";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        PlanningWorksheet: TestPage "Planning Worksheet";
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
    begin
        // [FEATURE] [Rescheduling Period] [Lot Accumulation Period] [Production Forecast]

        // Setup: Create Item with Planning parameters.
        Initialize();
        InventorySetup.Get();
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1W>', '<1W>', true, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.
        GlobalItemNo := Item."No.";  // Assign Global Variable for Page Handler.
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", false);

        // Create Demand setup with Random Values taking Global Variable for Sales.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(5), 0D, 0D);  // Dates based on WORKDATE.
        CreateDemandQuantity(DemandQuantityValue, LibraryRandom.RandDec(5, 2) + 210, 0, 0);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 1);  // Number of Sales Order.
        RequisitionWkshName.FindFirst();

        // Exercise: Calculate Regenerative Plan.
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name);

        // Verify: Verify planning worksheet.
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::New, WorkDate(), 0, ProductionForecastEntry[1]."Forecast Quantity", 0D, '', '');
        VerifyRequisitionLineCount(1);  // Expected no of lines in Planning Worksheet. Value important.

        // Tear Down.
        UpdateForecastOnInventorySetup(
          InventorySetup."Current Demand Forecast", InventorySetup."Use Forecast on Locations");
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DemandSupplyWithForecastWithoutPostSalesOrder()
    begin
        // [FEATURE] [Rescheduling Period] [Lot Accumulation Period] [Production Forecast]

        Initialize();
        DemandSupplyWithForecast(false);  // Post Sales Order as False.
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DemandSupplyWithForecastWithPostSalesOrder()
    begin
        // [FEATURE] [Rescheduling Period] [Lot Accumulation Period] [Production Forecast]

        Initialize();
        DemandSupplyWithForecast(true);  // Post Sales Order as True.
    end;

    local procedure DemandSupplyWithForecast(PostSalesOrder: Boolean)
    var
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        PlanningWorksheet: TestPage "Planning Worksheet";
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        Initialize();

        // Create Item with Planning parameters.
        InventorySetup.Get();
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1W>', '<1W>', true, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.
        GlobalItemNo := Item."No.";  // Assign Global Variable for Page Handler.
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", true);

        // Create Demand - Supply setup with Random Values taking Global Variable for Sales,Production and Purchase.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(4), GetRandomDateUsingWorkDate(56), 0D);  // Dates based on WORKDATE.
        CreateDemandQuantity(DemandQuantityValue, LibraryRandom.RandDec(5, 2) + 240, LibraryRandom.RandDec(5, 2) + 210, 0);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 2);  // Number of Sales Order.

        CreateSupplyType(SupplyType, SupplyType::FirmPlanned, SupplyType::Purchase, SupplyType::Purchase, SupplyType::None, SupplyType::None);
        CreateSupplyDate(
          SupplyDateValue, GetRandomDateUsingWorkDate(55), GetRandomDateUsingWorkDate(33), GetRandomDateUsingWorkDate(80), 0D, 0D);  // Dates based on WORKDATE.
        CreateSupplyQuantity(
          SupplyQuantityValue, LibraryRandom.RandDec(5, 2) + 270, LibraryRandom.RandDec(5, 2) + 260,
          LibraryRandom.RandDec(5, 2) + 220, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, Item."No.", Item."No.", '');

        if PostSalesOrder then
            UpdatePostingDateAndPostMultipleSalesOrder(
              GlobalSalesHeader[1], GlobalSalesHeader[2], GetRandomDateUsingWorkDate(4), GetRandomDateUsingWorkDate(56));

        // Exercise: Calculate Regenerative Plan.
        RequisitionWkshName.FindFirst();
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name);

        // Verify: Verify planning worksheet.
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::New, ProductionForecastEntry[2]."Forecast Date", 0,
          ProductionForecastEntry[2]."Forecast Quantity" - DemandQuantityValue[2], 0D, '', '');
        VerifyRequisitionLine(Item."No.", RequisitionLine."Action Message"::Cancel, SupplyDateValue[2], SupplyQuantityValue[2], 0, 0D, '', '');
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::New, ProductionForecastEntry[3]."Forecast Date", 0,
          ProductionForecastEntry[3]."Forecast Quantity", 0D, '', '');
        VerifyRequisitionLine(Item."No.", RequisitionLine."Action Message"::Cancel, SupplyDateValue[3], SupplyQuantityValue[3], 0, 0D, '', '');
        if PostSalesOrder then begin
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::New, SelectDateWithSafetyLeadTime(WorkDate(), -1), 0,
              DemandQuantityValue[1] + DemandQuantityValue[2], 0D, '', '');
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::Cancel, SupplyDateValue[1], SupplyQuantityValue[1], 0, 0D, '', '');
        end else begin
            VerifyRequisitionLine(Item."No.", RequisitionLine."Action Message"::New, DemandDateValue[1], 0, DemandQuantityValue[1], 0D, '', '');
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::"Resched. & Chg. Qty.", DemandDateValue[2], SupplyQuantityValue[1],
              DemandQuantityValue[2], SupplyDateValue[1], '', '');
        end;
        VerifyRequisitionLineCount(6);  // Expected no of lines in Planning Worksheet. Value important.
        // Tear Down.
        UpdateForecastOnInventorySetup(
          InventorySetup."Current Demand Forecast", InventorySetup."Use Forecast on Locations");
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DemandSupplyWithForecastChangeReschedPeriodWithoutPostPurchaseOrder()
    begin
        // [FEATURE] [Rescheduling Period] [Lot Accumulation Period] [Production Forecast]

        Initialize();
        DemandSupplyWithForecastChangeReschedPeriod(false);  // Post Purchase Order as False.
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DemandSupplyWithForecastChangeReschedPeriodWithPostPurchaseOrder()
    begin
        // [FEATURE] [Rescheduling Period] [Lot Accumulation Period] [Production Forecast]

        Initialize();
        DemandSupplyWithForecastChangeReschedPeriod(true);  // Post Purchase Order as True.
    end;

    local procedure DemandSupplyWithForecastChangeReschedPeriod(PostPurchaseOrder: Boolean)
    var
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        PlanningWorksheet: TestPage "Planning Worksheet";
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        Initialize();

        // Create Item with Planning parameters.
        InventorySetup.Get();
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1W>', '<1W>', true, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.
        GlobalItemNo := Item."No.";  // Assign Global Variable for Page Handler.
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", true);

        // Create Demand - Supply setup with Random Values taking Global Variable for Sales,Production and Purchase.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(4), GetRandomDateUsingWorkDate(56), 0D);  // Dates based on WORKDATE.
        CreateDemandQuantity(DemandQuantityValue, LibraryRandom.RandDec(5, 2) + 240, LibraryRandom.RandDec(5, 2) + 210, 0);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 2);  // Number of Sales Order.

        CreateSupplyType(SupplyType, SupplyType::FirmPlanned, SupplyType::Purchase, SupplyType::Purchase, SupplyType::None, SupplyType::None);
        CreateSupplyDate(
          SupplyDateValue, GetRandomDateUsingWorkDate(55), GetRandomDateUsingWorkDate(33), GetRandomDateUsingWorkDate(80), 0D, 0D);  // Dates based on WORKDATE.
        CreateSupplyQuantity(
          SupplyQuantityValue, LibraryRandom.RandDec(5, 2) + 270, LibraryRandom.RandDec(5, 2) + 260,
          LibraryRandom.RandDec(5, 2) + 220, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, Item."No.", Item."No.", '');

        UpdatePostingDateAndPostMultipleSalesOrder(
          GlobalSalesHeader[1], GlobalSalesHeader[2], GetRandomDateUsingWorkDate(4), GetRandomDateUsingWorkDate(56));
        RequisitionWkshName.FindFirst();
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name);
        ChangePeriodForItem(Item, '<20D>', '<20D>');  // Rescheduling Period, Lot Accumulation Period.

        if PostPurchaseOrder then
            LibraryPurchase.PostPurchaseDocument(GlobalPurchaseHeader[1], true, false);

        // Exercise: Calculate Regenerative Plan.
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name);

        // Verify: Verify planning worksheet.
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::"Resched. & Chg. Qty.", ProductionForecastEntry[3]."Forecast Date",
          SupplyQuantityValue[1], ProductionForecastEntry[3]."Forecast Quantity", SupplyDateValue[1], '', '');
        VerifyRequisitionLine(Item."No.", RequisitionLine."Action Message"::Cancel, SupplyDateValue[3], SupplyQuantityValue[3], 0, 0D, '', '');
        if PostPurchaseOrder then begin
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::New, SelectDateWithSafetyLeadTime(WorkDate(), -1), 0,
              DemandQuantityValue[1] + DemandQuantityValue[2] - SupplyQuantityValue[2], 0D, '', '');
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::New, ProductionForecastEntry[2]."Forecast Date", 0,
              ProductionForecastEntry[2]."Forecast Quantity" - DemandQuantityValue[2], 0D, '', '');
        end else begin
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::New, SelectDateWithSafetyLeadTime(WorkDate(), -1), 0,
              DemandQuantityValue[1] + DemandQuantityValue[2], 0D, '', '');
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::"Resched. & Chg. Qty.", ProductionForecastEntry[2]."Forecast Date",
              SupplyQuantityValue[2], ProductionForecastEntry[2]."Forecast Quantity" - DemandQuantityValue[2], SupplyDateValue[2], '', '');
        end;
        VerifyRequisitionLineCount(4);  // Expected no of lines in Planning Worksheet. Value important.

        // Tear Down.
        UpdateForecastOnInventorySetup(
          InventorySetup."Current Demand Forecast", InventorySetup."Use Forecast on Locations");
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DemandSupplyWithForecastAndCarryOutActionMessage()
    var
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        PlanningWorksheet: TestPage "Planning Worksheet";
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        PlanningLinesCountBeforeCarryOut: Integer;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        // [FEATURE] [Rescheduling Period] [Lot Accumulation Period] [Production Forecast] [Carry Out Action Message]

        // Setup: Create Item with Planning parameters.
        Initialize();
        InventorySetup.Get();
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1W>', '<1W>', true, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.
        GlobalItemNo := Item."No.";  // Assign Global Variable for Page Handler.
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", true);

        // Create Demand - Supply setup with Random Values taking Global Variable for Sales,Production and Purchase.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(4), GetRandomDateUsingWorkDate(56), 0D);  // Dates based on WORKDATE.
        CreateDemandQuantity(DemandQuantityValue, LibraryRandom.RandDec(5, 2) + 240, LibraryRandom.RandDec(5, 2) + 210, 0);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 2);  // Number of Sales Order.

        CreateSupplyType(SupplyType, SupplyType::FirmPlanned, SupplyType::Purchase, SupplyType::Purchase, SupplyType::None, SupplyType::None);
        CreateSupplyDate(
          SupplyDateValue, GetRandomDateUsingWorkDate(55), GetRandomDateUsingWorkDate(33), GetRandomDateUsingWorkDate(80), 0D, 0D);  // Dates based on WORKDATE.
        CreateSupplyQuantity(
          SupplyQuantityValue, LibraryRandom.RandDec(5, 2) + 270, LibraryRandom.RandDec(5, 2) + 260,
          LibraryRandom.RandDec(5, 2) + 220, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, Item."No.", Item."No.", '');

        UpdatePostingDateAndPostMultipleSalesOrder(
          GlobalSalesHeader[1], GlobalSalesHeader[2], GetRandomDateUsingWorkDate(4), GetRandomDateUsingWorkDate(56));
        RequisitionWkshName.FindFirst();
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name);
        ChangePeriodForItem(Item, '<20D>', '<20D>');  // Rescheduling Period, Lot Accumulation Period.
        LibraryPurchase.PostPurchaseDocument(GlobalPurchaseHeader[1], true, false);
        CalcRegenPlanAndCarryOutActionMessagePlan(Item, PlanningLinesCountBeforeCarryOut);

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));  // Dates based on WORKDATE.

        // Verify: Verify that all the Planning Worksheet Lines are cleared after Carry Out Action message.
        VerifyPlanningWorksheetEmpty(PlanningLinesCountBeforeCarryOut, Item."No.");

        // Tear Down.
        UpdateForecastOnInventorySetup(
          InventorySetup."Current Demand Forecast", InventorySetup."Use Forecast on Locations");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandWithMultipleUOMReschedPeriodWeek()
    begin
        // [FEATURE] [Rescheduling Period] [Lot Accumulation Period] [Item Unit of Measure]
        Initialize();
        DemandSupplyWithMultipleUOM(false);  // Supply as False.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyWithMultipleUOMReschedPeriodWeek()
    begin
        // [FEATURE] [Rescheduling Period] [Lot Accumulation Period] [Item Unit of Measure]
        Initialize();
        DemandSupplyWithMultipleUOM(true);  // Supply as True.
    end;

    local procedure DemandSupplyWithMultipleUOM(Supply: Boolean)
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemUnitOfMeasure2: Record "Item Unit of Measure";
        Quantity: Decimal;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        Initialize();

        // Setup: Create Item with Planning parameters.
        Quantity := LibraryRandom.RandDec(5, 2) + 80;  // Using Random Value.
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1W>', '<1W>', true, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.
        UpdateItemInventory(Item."No.", Quantity);
        CreateMultipleItemUnitOfMeasure(ItemUnitOfMeasure, ItemUnitOfMeasure2, Item."No.");

        // Create Demand -Supply setup with multiples UOM with Random Values taking Global Variable for Sales and Purchase.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(5), GetRandomDateUsingWorkDate(10), GetRandomDateUsingWorkDate(15));  // Dates based on WORKDATE.
        CreateDemandQuantity(
          DemandQuantityValue, LibraryRandom.RandDec(5, 2) + 30, LibraryRandom.RandDec(5, 2) + 40,
          LibraryRandom.RandDec(5, 2) + 20);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 3);  // Number of Sales Order.
        UpdateUnitOfMeasureForSales(GlobalSalesHeader[1]."No.", ItemUnitOfMeasure.Code);
        UpdateUnitOfMeasureForSales(GlobalSalesHeader[3]."No.", ItemUnitOfMeasure2.Code);

        if Supply then begin
            CreateSupplyType(SupplyType, SupplyType::Purchase, SupplyType::Purchase, SupplyType::None, SupplyType::None, SupplyType::None);
            CreateSupplyDate(SupplyDateValue, GetRandomDateUsingWorkDate(5), GetRandomDateUsingWorkDate(17), 0D, 0D, 0D);  // Dates based on WORKDATE.
            CreateSupplyQuantity(SupplyQuantityValue, DemandQuantityValue[1], LibraryRandom.RandDec(5, 2) + 10, 0, 0, 0);
            CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, '', Item."No.", '');
            UpdateUnitOfMeasureForPurchase(GlobalPurchaseHeader[1]."No.", ItemUnitOfMeasure.Code);
        end;

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));  // Dates based on WORKDATE.

        // Verify: Verify Planning Worksheet lines.
        if Supply then begin
            VerifyRequisitionLine(Item."No.", RequisitionLine."Action Message"::"Change Qty.", DemandDateValue[1], SupplyQuantityValue[1],
              DemandQuantityValue[1] +
              DemandQuantityValue[2] /
              ItemUnitOfMeasure."Qty. per Unit of Measure" - Quantity / ItemUnitOfMeasure."Qty. per Unit of Measure", 0D, '', '');
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::"Resched. & Chg. Qty.", DemandDateValue[3], SupplyQuantityValue[2],
              ItemUnitOfMeasure2."Qty. per Unit of Measure" * DemandQuantityValue[3], SupplyDateValue[2], '', '');
        end else begin
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::New, DemandDateValue[1], 0,
              ItemUnitOfMeasure."Qty. per Unit of Measure" * DemandQuantityValue[1] + DemandQuantityValue[2] - Quantity, 0D, '', '');
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::New, DemandDateValue[3], 0,
              ItemUnitOfMeasure2."Qty. per Unit of Measure" * DemandQuantityValue[3], 0D, '', '');
        end;
        VerifyRequisitionLineCount(2);  // Expected no of lines in Planning Worksheet. Value important.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyWithMultipleUOMCarryOutActionMessage()
    begin
        // [FEATURE] [Rescheduling Period] [Lot Accumulation Period] [Item Unit of Measure] [Carry Out Action Message]
        Initialize();
        DemandSupplyWithMultipleUOMWithCarryOutActionMessage(false);  // Calculate Regenerative Plan After Carry Out Action Message - FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyWithMultipleUOMCarryOutActionMessageAndRerunRegenerativePlan()
    begin
        // [FEATURE] [Rescheduling Period] [Lot Accumulation Period] [Item Unit of Measure] [Carry Out Action Message]
        Initialize();
        DemandSupplyWithMultipleUOMWithCarryOutActionMessage(true);  // Calculate Regenerative Plan After Carry Out Action Message - TRUE.
    end;

    local procedure DemandSupplyWithMultipleUOMWithCarryOutActionMessage(CalculateRegenerativePlanAfterCarryOutActionMessage: Boolean)
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemUnitOfMeasure2: Record "Item Unit of Measure";
        Quantity: Decimal;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        PlanningLinesCountBeforeCarryOut: Integer;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        Initialize();

        // Setup: Create Item with Planning parameters.
        Quantity := LibraryRandom.RandDec(5, 2) + 80;  // Using Random Value.
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1W>', '<1W>', true, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.
        UpdateItemInventory(Item."No.", Quantity);
        CreateMultipleItemUnitOfMeasure(ItemUnitOfMeasure, ItemUnitOfMeasure2, Item."No.");

        // Create Demand - Supply setup with multiple UOMs with Random Values taking Global Variable for Sales and Purchase Order.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(5), GetRandomDateUsingWorkDate(10), GetRandomDateUsingWorkDate(15));  // Dates based on WORKDATE.
        CreateDemandQuantity(
          DemandQuantityValue, LibraryRandom.RandDec(5, 2) + 30, LibraryRandom.RandDec(5, 2) + 40,
          LibraryRandom.RandDec(5, 2) + 20);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 3);  // Number of Sales Order.
        UpdateUnitOfMeasureForSales(GlobalSalesHeader[1]."No.", ItemUnitOfMeasure.Code);
        UpdateUnitOfMeasureForSales(GlobalSalesHeader[3]."No.", ItemUnitOfMeasure2.Code);

        CreateSupplyType(SupplyType, SupplyType::Purchase, SupplyType::Purchase, SupplyType::None, SupplyType::None, SupplyType::None);
        CreateSupplyDate(SupplyDateValue, GetRandomDateUsingWorkDate(5), GetRandomDateUsingWorkDate(17), 0D, 0D, 0D);  // Dates based on WORKDATE.
        CreateSupplyQuantity(SupplyQuantityValue, DemandQuantityValue[1], LibraryRandom.RandDec(5, 2) + 10, 0, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, '', Item."No.", '');
        UpdateUnitOfMeasureForPurchase(GlobalPurchaseHeader[1]."No.", ItemUnitOfMeasure.Code);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));  // Dates based on WORKDATE.

        // Exercise: Accept and Carry out Action message.
        AcceptActionMessageAndCarryOutActionMessagePlan(Item."No.", PlanningLinesCountBeforeCarryOut);

        // Verify: Verify Purchase Line.
        VerifyPurchaseLine(
          GlobalPurchaseHeader[1]."No.",
          DemandQuantityValue[1] +
          DemandQuantityValue[2] /
          ItemUnitOfMeasure."Qty. per Unit of Measure" - Quantity / ItemUnitOfMeasure."Qty. per Unit of Measure");
        VerifyPurchaseLine(GlobalPurchaseHeader[2]."No.", ItemUnitOfMeasure2."Qty. per Unit of Measure" * DemandQuantityValue[3]);

        if CalculateRegenerativePlanAfterCarryOutActionMessage then begin
            // Exercise: Calculate Regenerative Plan.
            LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));  // Dates based on WORKDATE.

            // Verify: Verify that all the Planning Worksheet Lines are cleared after Carry Out Action message.
            VerifyPlanningWorksheetEmpty(PlanningLinesCountBeforeCarryOut, Item."No.")
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandWithMaximumOrderQuantity()
    var
        Item: Record Item;
        RequisitionLine2: Record "Requisition Line";
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
    begin
        // [FEATURE] [Rescheduling Period] [Lot Accumulation Period] [Maximum Order Quantity]

        // Setup: Create Item with Planning parameters.
        Initialize();
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<2W>', '<2W>', true, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.
        UpdateItem(Item, Item.FieldNo("Maximum Order Quantity"), LibraryRandom.RandDec(5, 2) + 9);  // Maximum Order Quantity.

        // Create Demand setup with Random Values taking Global Variable for Sales.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(5), 0D, 0D);  // Dates based on WORKDATE.
        CreateDemandQuantity(DemandQuantityValue, LibraryRandom.RandDec(5, 2) + 30, 0, 0);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 1);  // Number of Sales Order.

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));  // Dates based on WORKDATE.

        // Verify: Verify Planning Worksheet lines.
        VerifyRequisitionLineForMaximumOrderQuantity(
          RequisitionLine2, Item."No.", RequisitionLine."Action Message"::New, DemandDateValue[1], Item."Maximum Order Quantity", 0D,
          DemandQuantityValue[1] div Item."Maximum Order Quantity");
        RequisitionLine2.TestField(Quantity, DemandQuantityValue[1] mod Item."Maximum Order Quantity");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandWithMaximumOrderQuantityAndChangeQtyOnDemand()
    begin
        // [FEATURE] [Rescheduling Period] [Lot Accumulation Period] [Maximum Order Quantity]
        Initialize();
        DemandSupplyWithMaximumOrderQuantityAndChangeQty(false);  // Supply as False.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyWithMaximumOrderQuantityAndChangeQtyOnDemand()
    begin
        // [FEATURE] [Rescheduling Period] [Lot Accumulation Period] [Maximum Order Quantity]
        Initialize();
        DemandSupplyWithMaximumOrderQuantityAndChangeQty(true);  // Supply as True.
    end;

    local procedure DemandSupplyWithMaximumOrderQuantityAndChangeQty(Supply: Boolean)
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        RequisitionLine2: Record "Requisition Line";
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        PlanningLinesCountBeforeCarryOut: Integer;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        Initialize();

        // Setup: Create Item with Planning parameters.
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<2W>', '<2W>', true, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.
        UpdateItem(Item, Item.FieldNo("Maximum Order Quantity"), LibraryRandom.RandDec(5, 2) + 9);  // Maximum Order Quantity.

        // Create Demand -Supply setup with Random Values taking Global Variable for Sales and Purchase.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(5), 0D, 0D);  // Dates based on WORKDATE.
        CreateDemandQuantity(DemandQuantityValue, LibraryRandom.RandDec(5, 2) + 30, 0, 0);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 1);  // Number of Sales Order.

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));  // Dates based on WORKDATE.
        AcceptActionMessageAndCarryOutActionMessagePlan(Item."No.", PlanningLinesCountBeforeCarryOut);
        UpdateQuantityForSales(SalesLine, GlobalSalesHeader[1]."No.", DemandQuantityValue[1] + 5);

        if Supply then begin
            UpdateShipmentDateForSales(SalesLine, GlobalSalesHeader[1]."No.", GetRandomDateUsingWorkDate(15));
            CreateSupplyType(SupplyType, SupplyType::Purchase, SupplyType::None, SupplyType::None, SupplyType::None, SupplyType::None);
            CreateSupplyDate(SupplyDateValue, GetRandomDateUsingWorkDate(11), 0D, 0D, 0D, 0D);  // Dates based on WORKDATE.
            CreateSupplyQuantity(SupplyQuantityValue, LibraryRandom.RandDec(5, 2) + 60, 0, 0, 0, 0);
            CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, '', Item."No.", '');
        end;

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));  // Dates based on WORKDATE.

        // Verify: Verify Planning Worksheet lines.
        if Supply then begin
            VerifyRequisitionLineForMaximumOrderQuantity(
              RequisitionLine2, Item."No.", RequisitionLine."Action Message"::Reschedule, SalesLine."Shipment Date",
              Item."Maximum Order Quantity", DemandDateValue[1], (DemandQuantityValue[1] div Item."Maximum Order Quantity") - 1);
            SelectRequisitionLineForActionMessage(
              RequisitionLine2, Item."No.", RequisitionLine."Action Message"::"Resched. & Chg. Qty.", SalesLine."Shipment Date");
            VerifyQuantityAndDateOnRequisitionLine(
              RequisitionLine2, DemandDateValue[1], Item."Maximum Order Quantity", DemandQuantityValue[1] mod Item."Maximum Order Quantity");
            RequisitionLine2.Next();
            VerifyQuantityAndDateOnRequisitionLine(
              RequisitionLine2, SupplyDateValue[1], SalesLine.Quantity mod Item."Maximum Order Quantity", SupplyQuantityValue[1]);
        end else begin
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::"Change Qty.", DemandDateValue[1],
              DemandQuantityValue[1] mod Item."Maximum Order Quantity", Item."Maximum Order Quantity", 0D, '', '');
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::New, DemandDateValue[1], 0,
              SalesLine.Quantity -
              DemandQuantityValue[1] + DemandQuantityValue[1] mod Item."Maximum Order Quantity" - Item."Maximum Order Quantity", 0D, '', '');
            VerifyRequisitionLineCount(2);  // Expected no of lines in Planning Worksheet. Value important.
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyWithMaximumOrderQuantityAndCarryOutActionMessage()
    begin
        // [FEATURE] [Rescheduling Period] [Lot Accumulation Period] [Maximum Order Quantity] [Carry Out Action Message]
        Initialize();
        DemandSupplyWithMaximumOrderQuantityWithCarryOutActionMessage(false);  // Change Quantity on Purchase as False.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyWithMaximumOrderQuantityCarryOutActionMessageAndChangeQtyOnSupply()
    begin
        // [FEATURE] [Rescheduling Period] [Lot Accumulation Period] [Maximum Order Quantity] [Carry Out Action Message]
        Initialize();
        DemandSupplyWithMaximumOrderQuantityWithCarryOutActionMessage(true);  // Change Quantity on Purchase as True.
    end;

    local procedure DemandSupplyWithMaximumOrderQuantityWithCarryOutActionMessage(ChangeQuantityOnPurchase: Boolean)
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        PlanningLinesCountBeforeCarryOut: Integer;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        // Setup: Create Item with Planning parameters.
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<2W>', '<2W>', true, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.
        UpdateItem(Item, Item.FieldNo("Maximum Order Quantity"), LibraryRandom.RandDec(5, 2) + 9);  // Maximum Order Quantity.

        // Create Demand -Supply setup with Random Values taking Global Variable for Sales.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(5), 0D, 0D);  // Dates based on WORKDATE.
        CreateDemandQuantity(DemandQuantityValue, LibraryRandom.RandDec(5, 2) + 30, 0, 0);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 1);  // Number of Sales Order.

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));  // Dates based on WORKDATE.
        AcceptActionMessageAndCarryOutActionMessagePlan(Item."No.", PlanningLinesCountBeforeCarryOut);
        UpdateQuantityForSales(SalesLine, GlobalSalesHeader[1]."No.", DemandQuantityValue[1] + 5);
        UpdateShipmentDateForSales(SalesLine, GlobalSalesHeader[1]."No.", GetRandomDateUsingWorkDate(15));

        CreateSupplyType(SupplyType, SupplyType::Purchase, SupplyType::None, SupplyType::None, SupplyType::None, SupplyType::None);
        CreateSupplyDate(SupplyDateValue, GetRandomDateUsingWorkDate(11), 0D, 0D, 0D, 0D);  // Dates based on WORKDATE.
        CreateSupplyQuantity(SupplyQuantityValue, LibraryRandom.RandDec(5, 2) + 60, 0, 0, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, '', Item."No.", '');
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));  // Dates based on WORKDATE.
        AcceptActionMessageAndCarryOutActionMessagePlan(Item."No.", PlanningLinesCountBeforeCarryOut);

        if ChangeQuantityOnPurchase then
            UpdateQuantityForPurchase(PurchaseLine, GlobalPurchaseHeader[1]."No.", Item."Maximum Order Quantity");

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));  // Dates based on WORKDATE.

        // Verify: Verify Planning Worksheet Lines and all the Planning Worksheet Lines are cleared after Carry Out Action message.
        if ChangeQuantityOnPurchase then begin
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::"Change Qty.", SalesLine."Shipment Date", Item."Maximum Order Quantity",
              SalesLine.Quantity mod Item."Maximum Order Quantity", 0D, '', '');
            VerifyRequisitionLineCount(1);  // Expected no of lines in Planning Worksheet. Value important.
        end else
            VerifyPlanningWorksheetEmpty(PlanningLinesCountBeforeCarryOut, Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandAfterSupplyForFRQItem()
    begin
        // [FEATURE] [Fixed Reorder Quantity]
        Initialize();
        DemandSupplyForItemWithReorderPointPolicy(true, false);  // FRQ Item, Carry out action message - FALSE,  Calculate regenerative plan only.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyForFRQItemCarryOutActionMessage()
    begin
        // [FEATURE] [Fixed Reorder Quantity] [Carry Out Action Message]
        Initialize();
        DemandSupplyForItemWithReorderPointPolicy(true, true);  // FRQ Item, Carry out action message.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandAfterSupplyForMQItem()
    begin
        // [FEATURE] [Maximum Order Quantity]
        Initialize();
        DemandSupplyForItemWithReorderPointPolicy(false, false);  // MQ Item, Carry out action message - FALSE,  Calculate regenerative plan only.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyForMQItemCarryOutActionMessage()
    begin
        // [FEATURE] [Maximum Order Quantity] [Carry Out Action Message]
        Initialize();
        DemandSupplyForItemWithReorderPointPolicy(false, true);  // MQ Item, Carry out action message.
    end;

    local procedure DemandSupplyForItemWithReorderPointPolicy(FRQItem: Boolean; CarryOutActionMessage: Boolean)
    var
        Item: Record Item;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        PlanningLinesCountBeforeCarryOut: Integer;
        NewProdOrderDate: Date;
        PlanningWorksheetQuantity: Decimal;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        // Create Item with planning parameters.
        CreateReorderPointPolicyItem(Item, FRQItem, LibraryRandom.RandDec(5, 2) + 500, 0, 0);  // Reorder Qty or Maximum Inventory, Reorder Point, Safety Stock Qty.

        // Create Demand - Supply setup with Random Values taking Global Variable for Sales and Production.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(20), 0D, 0D);  // Dates based on WORKDATE.
        CreateDemandQuantity(DemandQuantityValue, LibraryRandom.RandDec(5, 2) + 900, 0, 0);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 1);  // Number of Sales Order.

        CreateSupplyType(SupplyType, SupplyType::Released, SupplyType::None, SupplyType::None, SupplyType::None, SupplyType::None);
        CreateSupplyDate(SupplyDateValue, GetRandomDateUsingWorkDate(10), 0D, 0D, 0D, 0D);  // Dates based on WORKDATE.
        CreateSupplyQuantity(SupplyQuantityValue, LibraryRandom.RandDec(5, 2) + 1200, 0, 0, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, Item."No.", '', '');
        PlanningWorksheetQuantity := SelectItemQuantity(Item, FRQItem);

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));  // Dates based on WORKDATE.

        if CarryOutActionMessage then begin
            // Exercise: Carry Out Action Message on Planning Worksheet lines.
            AcceptActionMessageAndCarryOutActionMessagePlan(Item."No.", PlanningLinesCountBeforeCarryOut);

            // Verify: Verify that all the Planning Worksheet Lines are cleared after Carry Out Action message.
            VerifyPlanningWorksheetEmpty(PlanningLinesCountBeforeCarryOut, Item."No.");
        end else begin
            // Verify: Verify Planning Worksheet.
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::New, SelectDateWithSafetyLeadTime(WorkDate(), 1), 0, PlanningWorksheetQuantity, 0D,
              '', '');
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::Cancel, SupplyDateValue[1], SupplyQuantityValue[1], 0, 0D, '', '');
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::New, DemandDateValue[1], 0, DemandQuantityValue[1] - PlanningWorksheetQuantity,
              0D, '', '');
            NewProdOrderDate := SelectDateWithSafetyLeadTime(DemandDateValue[1], 1);
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::New, CalcDate('<1D>', NewProdOrderDate), 0, PlanningWorksheetQuantity, 0D, '', '');
            VerifyRequisitionLineCount(4);  // Expected no of lines in Planning Worksheet. Value important.
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandLessThanReorderQtyAndBeforeSupplyForFRQItem()
    begin
        // [FEATURE] [Fixed Reorder Quantity]
        Initialize();
        DemandLessThanReorderQtyAndBeforeSupply(true);  // FRQ Item.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandLessThanReorderQtyAndBeforeSupplyForMQItem()
    begin
        // [FEATURE] [Maximum Order Quantity]
        Initialize();
        DemandLessThanReorderQtyAndBeforeSupply(false);  // MQ Item.
    end;

    local procedure DemandLessThanReorderQtyAndBeforeSupply(FRQItem: Boolean)
    var
        Item: Record Item;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        PlanningWorksheetQuantity: Decimal;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        // Create Item with planning parameters.
        CreateReorderPointPolicyItem(Item, FRQItem, LibraryRandom.RandDec(5, 2) + 1000, 0, 0);  // Reorder Qty or Maximum Inventory, Reorder Point, Safety Stock Qty.

        // Create Demand - Supply setup with Random Values taking Global Variable for Sales and Production.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(10), 0D, 0D);  // Dates based on WORKDATE.
        CreateDemandQuantity(DemandQuantityValue, LibraryRandom.RandDec(5, 2) + 100, 0, 0);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 1);  // Number of Sales Order.

        CreateSupplyType(SupplyType, SupplyType::Released, SupplyType::None, SupplyType::None, SupplyType::None, SupplyType::None);
        CreateSupplyDate(SupplyDateValue, GetRandomDateUsingWorkDate(20), 0D, 0D, 0D, 0D);  // Dates based on WORKDATE.
        CreateSupplyQuantity(SupplyQuantityValue, LibraryRandom.RandDec(5, 2) + 1200, 0, 0, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, Item."No.", '', '');
        PlanningWorksheetQuantity := SelectItemQuantity(Item, FRQItem);

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));  // Dates based on WORKDATE.

        // Verify: Verify Planning Worksheet.
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::New, SelectDateWithSafetyLeadTime(WorkDate(), 1), 0, PlanningWorksheetQuantity, 0D, '',
          '');
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::"Change Qty.", SupplyDateValue[1], SupplyQuantityValue[1], DemandQuantityValue[1],
          0D, '', '');
        VerifyRequisitionLineCount(2);  // Expected no of lines in Planning Worksheet. Value important.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandMoreThanReorderQtyForFRQItem()
    begin
        // [FEATURE] [Fixed Reorder Quantity]
        Initialize();
        DemandMoreThanReorderAndMaxInventory(true);  // FRQ Item.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandMoreThanMaximumInventoryForMQItem()
    begin
        // [FEATURE] [Maximum Order Quantity]
        Initialize();
        DemandMoreThanReorderAndMaxInventory(false);  // MQ Item.
    end;

    local procedure DemandMoreThanReorderAndMaxInventory(FRQItem: Boolean)
    var
        Item: Record Item;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        NewProdOrderDate: Date;
        PlanningWorksheetQuantity: Decimal;
    begin
        // Create Item with planning parameters.
        CreateReorderPointPolicyItem(Item, FRQItem, LibraryRandom.RandDec(5, 2) + 1000, 0, 0);  // Reorder Qty or Maximum Inventory, Reorder Point, Safety Stock Qty.

        // Create Demand - Supply setup with Random Values taking Global Variable for Sales.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(10), GetRandomDateUsingWorkDate(30), 0D);  // Dates based on WORKDATE.
        CreateDemandQuantity(DemandQuantityValue, LibraryRandom.RandDec(5, 2) + 900, LibraryRandom.RandDec(5, 2) + 200, 0);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 2);  // Number of Sales Order.
        PlanningWorksheetQuantity := SelectItemQuantity(Item, FRQItem);

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));  // Dates based on WORKDATE.

        // Verify: Verify Planning Worksheet.
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::New, SelectDateWithSafetyLeadTime(WorkDate(), 1), 0, PlanningWorksheetQuantity, 0D, '',
          '');
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::New, DemandDateValue[2], 0,
          DemandQuantityValue[1] + DemandQuantityValue[2] - PlanningWorksheetQuantity, 0D, '', '');
        NewProdOrderDate := SelectDateWithSafetyLeadTime(DemandDateValue[2], 1);
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::New, CalcDate('<1D>', NewProdOrderDate), 0, PlanningWorksheetQuantity, 0D, '', '');
        VerifyRequisitionLineCount(3);  // Expected no of lines in Planning Worksheet. Value important.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyForFRQItemWithReorderPoint()
    begin
        // [FEATURE] [Fixed Reorder Quantity] [Reorder Point]
        Initialize();
        DemandSupplyWithReorderPoint(true);  // FRQ Item.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyForMQItemWithReorderPoint()
    begin
        // [FEATURE] [Maximum Order Quantity] [Reorder Point]
        Initialize();
        DemandSupplyWithReorderPoint(false);  // MQ Item.
    end;

    local procedure DemandSupplyWithReorderPoint(FRQItem: Boolean)
    var
        Item: Record Item;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        NewProdOrderDate: Date;
        PlanningWorksheetQuantity: Decimal;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
    begin
        // Create Item with planning parameters.
        CreateReorderPointPolicyItem(Item, FRQItem, LibraryRandom.RandDec(5, 2) + 1000, LibraryRandom.RandDec(5, 2) + 200, 0);  // Reorder Quantity or Maximum Inventory, Reorder Point, Safety Stock Qty.

        // Create Demand - Supply setup with Random Values taking Global Variable for Sales and Production.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(10), GetRandomDateUsingWorkDate(30), 0D);  // Dates based on WORKDATE.
        CreateDemandQuantity(DemandQuantityValue, LibraryRandom.RandDec(5, 2) + 900, LibraryRandom.RandDec(5, 2) + 200, 0);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 2);  // Number of Sales Order.

        CreateSupplyType(SupplyType, SupplyType::Released, SupplyType::None, SupplyType::None, SupplyType::None, SupplyType::None);
        CreateSupplyDate(SupplyDateValue, GetRandomDateUsingWorkDate(20), 0D, 0D, 0D, 0D);  // Dates based on WORKDATE.
        CreateSupplyQuantity(SupplyQuantityValue, LibraryRandom.RandDec(5, 2) + 1200, 0, 0, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, Item."No.", '', '');
        PlanningWorksheetQuantity := SelectItemQuantity(Item, FRQItem);

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));  // Dates based on WORKDATE.

        // Verify: Verify Planning Worksheet.
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::New, SelectDateWithSafetyLeadTime(WorkDate(), 1), 0, PlanningWorksheetQuantity, 0D, '',
          '');
        NewProdOrderDate := SelectDateWithSafetyLeadTime(DemandDateValue[1], 1);
        if FRQItem then
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::New, CalcDate('<1D>', NewProdOrderDate), 0, PlanningWorksheetQuantity, 0D, '', '')
        else
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::New, CalcDate('<1D>', NewProdOrderDate), 0, DemandQuantityValue[1], 0D, '', '');
        VerifyRequisitionLine(Item."No.", RequisitionLine."Action Message"::Cancel, SupplyDateValue[1], SupplyQuantityValue[1], 0, 0D, '', '');
        VerifyRequisitionLineCount(3);  // Expected no of lines in Planning Worksheet. Value important.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandOnlyForFRQItemWithReorderPointAndSafetyStock()
    begin
        // [FEATURE] [Fixed Reorder Quantity] [Reorder Point] [Safety Stock]
        Initialize();
        DemandOnlyForWithReorderPointAndSafetyStock(true);  // FRQ Item.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandOnlyForMQItemWithReorderPointAndSafetyStock()
    begin
        // [FEATURE] [Maximum Order Quantity] [Reorder Point] [Safety Stock]
        Initialize();
        DemandOnlyForWithReorderPointAndSafetyStock(false);  // MQ Item.
    end;

    local procedure DemandOnlyForWithReorderPointAndSafetyStock(FRQItem: Boolean)
    var
        Item: Record Item;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
    begin
        // Create Item with planning parameters.
        CreateReorderPointPolicyItem(
          Item, FRQItem, LibraryRandom.RandDec(5, 2) + 500, LibraryRandom.RandDec(5, 2) + 50,
          LibraryRandom.RandDec(5, 2) + 10);  // Reorder Quantity or Maximum Inventory, Reorder Point, Safety Stock.

        // Create Demand - Supply setup with Random Values taking Global Variable for Sales.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(20), 0D, 0D);  // Dates based on WORKDATE.
        CreateDemandQuantity(DemandQuantityValue, LibraryRandom.RandDec(5, 2) + 100, 0, 0);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 1);  // Number of Sales Order.

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));  // Dates based on WORKDATE.

        // Verify: Verify Planning Worksheet.
        if FRQItem then
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::New, SelectDateWithSafetyLeadTime(WorkDate(), 1), 0, Item."Reorder Quantity", 0D, '', '')
        else
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::New, SelectDateWithSafetyLeadTime(WorkDate(), 1), 0,
              Item."Maximum Inventory" - Item."Safety Stock Quantity", 0D, '', '');
        VerifyRequisitionLine(Item."No.", RequisitionLine."Action Message"::New, WorkDate(), 0, Item."Safety Stock Quantity", 0D, '', '');
        VerifyRequisitionLineCount(2);  // Expected no of lines in Planning Worksheet. Value important.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandLessThanMaximumInventoryWithReorderPointMQItem()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Maximum Order Quantity] [Reorder Point] [Maximum Inventory]
        Initialize();
        CreateMQItem(
          Item, Item."Replenishment System"::Purchase, LibraryRandom.RandInt(10) + 50, LibraryRandom.RandInt(10) + 20, 0);  // Item Maximum Inventory greater than Item Reorder Point. Safety Stock is Zero.
        DemandWithReorderPointAndMaxInventory(Item, Item."Reorder Point" + 1);  // Sales Quantity greater than Reorder Point but Less than Maximum Inventory.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandEqualsMaximumInventoryMQItem()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Maximum Order Quantity] [Reorder Point] [Maximum Inventory]
        Initialize();
        CreateMQItem(
          Item, Item."Replenishment System"::Purchase, LibraryRandom.RandInt(10) + 50, LibraryRandom.RandInt(10) + 20, 0);  // Item Maximum Inventory greater than Item Reorder Point. Safety Stock is Zero.
        DemandWithReorderPointAndMaxInventory(Item, Item."Maximum Inventory");  // Sales Qty equals Maximum Inventory.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandEqualsMaximumInventoryAndReorderPointMQItem()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Maximum Order Quantity] [Reorder Point] [Maximum Inventory]
        Initialize();
        CreateMQItem(
          Item, Item."Replenishment System"::Purchase, LibraryRandom.RandInt(10) + 50, LibraryRandom.RandInt(10) + 20, 0);  // Item Maximum Inventory greater than Item Reorder Point. Safety Stock is Zero.
        DemandWithReorderPointAndMaxInventory(Item, Item."Maximum Inventory" + Item."Reorder Point");  // Sales Qty equals Sum of Maximum Inventory and Reorder Point.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandGreaterThanMaximumInventoryAndReorderPointMQItem()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Maximum Order Quantity] [Reorder Point] [Maximum Inventory]
        Initialize();
        CreateMQItem(
          Item, Item."Replenishment System"::Purchase, LibraryRandom.RandInt(10) + 50, LibraryRandom.RandInt(10) + 20, 0);  // Item Maximum Inventory greater than Item Reorder Point. Safety Stock is Zero.
        DemandWithReorderPointAndMaxInventory(Item, Item."Maximum Inventory" + Item."Reorder Point" + 1);  // Sales Qty greater than Sum of Maximum Inventory and Reorder Point.
    end;

    local procedure DemandWithReorderPointAndMaxInventory(Item: Record Item; SalesQty: Decimal)
    var
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
    begin
        // [FEATURE] [Reorder Point] [Maximum Inventory]

        // Create Demand setup with Random Values.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(0), 0D, 0D);  // Shipment Date is WORKDATE.
        CreateDemandQuantity(DemandQuantityValue, SalesQty, 0, 0);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 1);  // Number of Sales Order : 1.

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(30));  // Dates based on WORKDATE. Planning Period - 1 Month, covers Sales shipments.

        // Verify: Verify Planning Worksheet.
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::New, SelectDateWithSafetyLeadTime(WorkDate(), 1), 0, Item."Maximum Inventory", 0D, '', '');
        VerifyRequisitionLine(Item."No.", RequisitionLine."Action Message"::New, DemandDateValue[1], 0, SalesQty, 0D, '', '');
        VerifyRequisitionLineCount(2);  // Expected no of lines in Planning Worksheet. Count Value important.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandLessThanExistingInventoryAndMaximumInventoryMQItem()
    var
        Item: Record Item;
        ReorderPoint: Integer;
    begin
        // [FEATURE] [Maximum Order Quantity] [Reorder Point] [Maximum Inventory]
        Initialize();

        ReorderPoint := LibraryRandom.RandInt(10) + 20;
        CreateMQItem(
          Item, Item."Replenishment System"::Purchase, 2 * ReorderPoint, ReorderPoint, 0);  // Item Maximum Inventory greater than Item Reorder Point. Safety Stock is Zero.
        DemandWithReorderPointMaxInventoryAndExistingInventory(Item, true, Item."Maximum Inventory" - 1, Item."Reorder Point" + 1);  // Boolean - Existing Inventory More than Sales Quantity.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandMoreThanExistingInventoryLessThanMaximumInventoryMQItem()
    var
        Item: Record Item;
        ReorderPoint: Integer;
    begin
        // [FEATURE] [Maximum Order Quantity] [Reorder Point] [Maximum Inventory]
        Initialize();

        ReorderPoint := LibraryRandom.RandInt(10) + 20;
        CreateMQItem(
            Item, Item."Replenishment System"::Purchase, 2 * ReorderPoint - 1, ReorderPoint, 0);  // Item Maximum Inventory greater than Item Reorder Point. Safety Stock is Zero.
        DemandWithReorderPointMaxInventoryAndExistingInventory(Item, false, Item."Reorder Point" - 1, Item."Reorder Point" + 1);  // Boolean - Existing Inventory less than Sales Qty and less than Maximum Inventory.
    end;

    local procedure DemandWithReorderPointMaxInventoryAndExistingInventory(Item: Record Item; ExistingInventoryMoreThanDemand: Boolean; InventoryQty: Decimal; SalesQty: Decimal)
    var
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        NewPurchOrderDate: Date;
    begin
        // Update Item with inventory.
        UpdateItemInventory(Item."No.", InventoryQty);

        // Create Demand setup with Random Values.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(0), 0D, 0D);  // Shipment Date is WORKDATE.
        CreateDemandQuantity(DemandQuantityValue, SalesQty, 0, 0);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 1);  // Number of Sales Order : 1.

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(30));  // Dates based on WORKDATE. Planning Period - 1 Month, must cover any shipments.

        // Verify: Verify Planning Worksheet.
        Item.CalcFields(Inventory);
        NewPurchOrderDate := SelectDateWithSafetyLeadTime(DemandDateValue[1], 1);
        if ExistingInventoryMoreThanDemand then begin
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::New, CalcDate('<1D>', NewPurchOrderDate), 0,
              Item."Maximum Inventory" - (Item.Inventory - SalesQty), 0D, '', '');
            VerifyRequisitionLineCount(1);  // Expected no of lines in Planning Worksheet. Count Value important.
        end else begin
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::New, SelectDateWithSafetyLeadTime(WorkDate(), 1), 0,
              Item."Maximum Inventory" - Item.Inventory, 0D, '', '');
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::New, DemandDateValue[1], 0, SalesQty - Item.Inventory, 0D, '', '');
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::New, CalcDate('<1D>', NewPurchOrderDate), 0, Item.Inventory, 0D, '', '');
            VerifyRequisitionLineCount(3);  // Expected no of lines in Planning Worksheet. Count Value important.
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandLessThanMaxInventoryMQItem()
    var
        Item: Record Item;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        PlanningWorksheetQuantity: Decimal;
    begin
        // [FEATURE] [Maximum Order Quantity] [Reorder Point] [Maximum Inventory]
        Initialize();

        // Create Maximum Quantity Item with planning parameters - Max. Inventory.
        CreateMQItem(Item, Item."Replenishment System"::Purchase, LibraryRandom.RandDec(5, 2) + 100, 0, 0);

        // Create Demand - with Random Values taking Global Variable for Sales. Sales Qty less than Max. Inventory.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(10), 0D, 0D);  // Dates based on WORKDATE.
        CreateDemandQuantity(DemandQuantityValue, LibraryRandom.RandDec(5, 2), 0, 0);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 1);  // Number of Sales Order.
        PlanningWorksheetQuantity := SelectItemQuantity(Item, false);  // False for Maximum Inventory.

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));  // Date based on WORKDATE.

        // Verify: Verify Requisition lines on Planning Worksheet.
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::New, SelectDateWithSafetyLeadTime(WorkDate(), 1), 0, PlanningWorksheetQuantity, 0D, '',
          '');
        VerifyRequisitionLineCount(1);  // Expected no of lines in Planning Worksheet. Value important.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandForMQItemReplenishPurchaseWithMaxInventoryCarryOutAM()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Maximum Order Quantity] [Reorder Point] [Maximum Inventory] [Carry Out Action Message]
        Initialize();
        DemandWithMaximumInventory(Item."Replenishment System"::Purchase);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandForMQItemReplenishProdOrderWithMaxInventoryCarryOutAM()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Maximum Order Quantity] [Reorder Point] [Maximum Inventory] [Carry Out Action Message]
        Initialize();
        DemandWithMaximumInventory(Item."Replenishment System"::"Prod. Order");
    end;

    [Test]
    [HandlerFunctions('CheckOrderExistsMessageHandler')]
    [Scope('OnPrem')]
    procedure DemandChangingWithDeletionPlanningWorksheetLineProductionOrder()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
        DummyCount: Integer;
    begin
        // [FEATURE] [Planning Worksheet] [Production]
        // [SCENARIO 378897] Carry Out Action Message should not delete requisition line and give warning if production order was deleted after creating from Carry Out Action Message.

        Initialize();

        // [GIVEN] Create Sales Order and connected Product Order by using Carry Out Action Message.
        // [GIVEN] Calculate Regenerative Plan after updating Sales Order.
        CreatePlanWkshLineWithChangeQtyActionMessage(Item, Item."Replenishment System"::"Prod. Order", LibraryRandom.RandInt(50));

        // [GIVEN] Delete Production Order.
        ProductionOrder.Get(ProductionOrder.Status::"Firm Planned", GetOrderNo(Item."No."));
        ProductionOrder.Delete(true);

        // [WHEN] Carry out planning lines in Production Order.
        AcceptActionMessageAndCarryOutActionMessagePlan(Item."No.", DummyCount);

        // [THEN] 'The supply type could not be changed in order.' message appeared.
        // Verification is done in CheckOrderExistsMessageHandler
        // [THEN] Requisition line exists for deleted Production Order.
        FilterRequisitionLine(RequisitionLine, Item."No.");
        Assert.RecordIsNotEmpty(RequisitionLine);
    end;

    [Test]
    [HandlerFunctions('CheckOrderExistsMessageHandler')]
    [Scope('OnPrem')]
    procedure DemandChangingWithDeletionPlanningWorksheetLineAssemblyOrder()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        RequisitionLine: Record "Requisition Line";
        DummyCount: Integer;
    begin
        // [FEATURE] [Planning Worksheet] [Assembly]
        // [SCENARIO 378897] Carry Out Action Message should not delete requisition line and give warning if assembly order was deleted after creating from Carry Out Action Message.

        Initialize();

        // [GIVEN] Create Sales Order and connected Assembly Order by using Carry Out Action Message.
        // [GIVEN] Calculate Regenerative Plan after updating Sales Order.
        CreatePlanWkshLineWithChangeQtyActionMessage(Item, Item."Replenishment System"::Assembly, LibraryRandom.RandInt(50));

        // [GIVEN] Delete Assembly Order.
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, GetOrderNo(Item."No."));
        AssemblyHeader.Delete(true);

        // [WHEN] Carry out planning lines in Assembly Order.
        AcceptActionMessageAndCarryOutActionMessagePlan(Item."No.", DummyCount);

        // [THEN] 'The supply type could not be changed in order.' message appeared.
        // Verification is done in CheckOrderExistsMessageHandler.
        // [THEN] Requisition line exists for deleted Assembly Order.
        FilterRequisitionLine(RequisitionLine, Item."No.");
        Assert.RecordIsNotEmpty(RequisitionLine);
    end;

    [Test]
    [HandlerFunctions('CheckOrderExistsMessageHandler')]
    [Scope('OnPrem')]
    procedure DemandChangingWithDeletionPlanningWorksheetLinePurchaseOrder()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        RequisitionLine: Record "Requisition Line";
        DummyCount: Integer;
    begin
        // [FEATURE] [Planning Worksheet] [Purchase]
        // [SCENARIO 378897] Carry Out Action Message should not delete requisition line and give warning if purchase order was deleted after creating from Carry Out Action Message.

        Initialize();

        // [GIVEN] Create Sales Order and connected Purchase Order by using Carry Out Action Message.
        // [GIVEN] Calculate Regenerative Plan after updating Sales Order.
        CreatePlanWkshLineWithChangeQtyActionMessage(Item, Item."Replenishment System"::Purchase, LibraryRandom.RandInt(50));

        // [GIVEN] Delete Purchase Order.
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, GetOrderNo(Item."No."));
        PurchaseHeader.Delete(true);

        // [WHEN] Carry out planning lines in Purchase Order.
        AcceptActionMessageAndCarryOutActionMessagePlan(Item."No.", DummyCount);

        // [THEN] 'The supply type could not be changed in order.'error message appeared.
        // Verification is done in CheckOrderExistsMessageHandler.
        // [THEN] Requisition line exists for deleted Assembly Order.
        FilterRequisitionLine(RequisitionLine, Item."No.");
        Assert.RecordIsNotEmpty(RequisitionLine);
    end;

    local procedure DemandWithMaximumInventory(ReplenishmentSystem: Enum "Replenishment System")
    var
        Item: Record Item;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        PlanningWorksheetQuantity: Decimal;
        PlanningLinesCountBeforeCarryOut: Integer;
    begin
        // Create Maximum Quantity Item with planning parameters.
        CreateMQItem(Item, ReplenishmentSystem, LibraryRandom.RandDec(5, 2) + 100, 0, 0);

        // Create Demand - with Random Values taking Global Variable for Sales. Sales Qty less than Max. Inventory.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(10), 0D, 0D);  // Dates based on WORKDATE.
        CreateDemandQuantity(DemandQuantityValue, LibraryRandom.RandDec(5, 2), 0, 0);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 1);  // Number of Sales Order.
        PlanningWorksheetQuantity := SelectItemQuantity(Item, false);  // False for Maximum Inventory.

        // Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));  // Date based on WORKDATE.

        // Exercise: Accept and Carry Out Action Message for Planning Worksheet lines.
        AcceptActionMessageAndCarryOutActionMessagePlan(Item."No.", PlanningLinesCountBeforeCarryOut);

        // Verify: Verify Planning Worksheet Lines are cleared after Carry Out Action message and New Purchase or Production Order is created with required quantity.
        VerifyPlanningWorksheetEmpty(PlanningLinesCountBeforeCarryOut, Item."No.");
        if ReplenishmentSystem = Item."Replenishment System"::Purchase then
            VerifyPurchaseOrderQuantity(Item."No.", PlanningWorksheetQuantity)
        else
            VerifyProdOrderQuantity(Item."No.", PlanningWorksheetQuantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandForMQItemReplenishPurchaseCarryOutAMWithFlexibilityNone()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Maximum Order Quantity] [Carry Out Action Message]
        Initialize();
        DemandForMQItemCarryOutAMWithFlexibilityNone(Item."Replenishment System"::Purchase)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandForMQItemReplenishProdOrderCarryOutAMWithFlexibilityNone()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Maximum Order Quantity] [Carry Out Action Message]
        Initialize();
        DemandForMQItemCarryOutAMWithFlexibilityNone(Item."Replenishment System"::"Prod. Order")
    end;

    local procedure DemandForMQItemCarryOutAMWithFlexibilityNone(ReplenishmentSystem: Enum "Replenishment System")
    var
        Item: Record Item;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        PlanningLinesCountBeforeCarryOut: Integer;
    begin
        // Create Maximum Quantity Item with planning parameter - Max. Inventory.
        CreateMQItem(Item, ReplenishmentSystem, LibraryRandom.RandDec(10, 2) + 100, 0, 0);

        // Create Demand - with Random Values taking Global Variable for Sales.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(10), 0D, 0D);  // Dates based on WORKDATE.
        CreateDemandQuantity(DemandQuantityValue, LibraryRandom.RandDec(10, 2), 0, 0);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 1);  // Number of Sales Order.

        // Calculate Regenerative Plan and update Planning Flexibility to None on the generated Requisition Line.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(30));  // Date based on WORKDATE.
        UpdatePlanningFlexibilityOnRequisition(Item."No.");

        // Exercise: Accept and Carry Out Action Message for Planning Worksheet lines.
        AcceptActionMessageAndCarryOutActionMessagePlan(Item."No.", PlanningLinesCountBeforeCarryOut);

        // Verify: Verify created Purchase or Production Order line has Planning Flexibility - None.
        if ReplenishmentSystem = Item."Replenishment System"::Purchase then
            VerifyPurchaseOrderPlanningFlexibility(Item."No.")
        else
            VerifyProdOrderPlanningFlexibility(Item."No.");
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DemandSupplyWithMaximumOrderQtyWithPurchaseOrderAndItemInventory()
    var
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        PlanningWorksheet: TestPage "Planning Worksheet";
    begin
        // [FEATURE] [Maximum Order Quantity]

        // Setup: Create Item, create Purchase Order, update Item Inventory.
        Initialize();

        // Create Lot For Lot Item and demand on Production Forecast.
        // First TRUE: create a Purchase Order, second TRUE: update Item Inventory.
        GeneralSetupForPlanningWorksheet(Item, ProductionForecastEntry, RequisitionWkshName, true, true);

        // Exercise: Calculate Regenerative Plan.
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name);

        // Verify: Verify planning worksheet.
        // Verify quantity on RequisitionLine of Planning Worksheet was less than Maximum Order Quantity of the Item.
        // Verify supply have met demand and Safety Stock Quantity.
        VerifyPlanWkshLineForMaximumOrderQuantity(ProductionForecastEntry, Item, PlanningWorksheet, RequisitionWkshName.Name);

        // Tear Down.
        UpdateForecastOnInventorySetup(
          InventorySetup."Current Demand Forecast", InventorySetup."Use Forecast on Locations");
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DemandSupplyWithMaximumOrderQtyWithPurchaseOrder()
    var
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        PlanningWorksheet: TestPage "Planning Worksheet";
    begin
        // [FEATURE] [Maximum Order Quantity]

        // Setup: Create Item, create Purchase Order.
        Initialize();

        // Create Lot For Lot Item and demand on Production Forecast.
        // TRUE: create a Purchase Order,FALSE: no Item Inventory.
        GeneralSetupForPlanningWorksheet(Item, ProductionForecastEntry, RequisitionWkshName, true, false);

        // Exercise: Calculate Regenerative Plan.
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name);

        // Verify: Verify planning worksheet.
        // Verify quantity on RequisitionLine of Planning Worksheet was less than Maximum Order Quantity of the Item.
        // Verify supply have met demand and Safety Stock Quantity.
        VerifyPlanWkshLineForMaximumOrderQuantity(ProductionForecastEntry, Item, PlanningWorksheet, RequisitionWkshName.Name);

        // Tear Down.
        UpdateForecastOnInventorySetup(
          InventorySetup."Current Demand Forecast", InventorySetup."Use Forecast on Locations");
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DemandSupplyWithMaximumOrderQtyWithItemInventory()
    var
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        PlanningWorksheet: TestPage "Planning Worksheet";
    begin
        // [FEATURE] [Maximum Order Quantity]

        // Setup: Create Item, update Item Inventory.
        Initialize();

        // Create Lot For Lot Item and demand on Production Forecast.
        // FALSE: do not create a Purchase Order, TRUE: update Item Inventory.
        GeneralSetupForPlanningWorksheet(Item, ProductionForecastEntry, RequisitionWkshName, false, true);

        // Exercise: Calculate Regenerative Plan.
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name);

        // Verify: Verify planning worksheet.
        // Verify quantity on RequisitionLine of Planning Worksheet was less than Maximum Order Quantity of the Item.
        // Verify supply have met demand and Safety Stock Quantity.
        VerifyPlanWkshLineForMaximumOrderQuantity(ProductionForecastEntry, Item, PlanningWorksheet, RequisitionWkshName.Name);

        // Tear Down.
        UpdateForecastOnInventorySetup(
          InventorySetup."Current Demand Forecast", InventorySetup."Use Forecast on Locations");
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DemandSupplyWithMaximumOrderQtyWithoutPurchaseOrderAndItemInventory()
    var
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        PlanningWorksheet: TestPage "Planning Worksheet";
    begin
        // [FEATURE] [Maximum Order Quantity]

        // Setup: Create Item.
        Initialize();

        // Create Lot For Lot Item and demand on Production Forecast.
        // First FALSE: do not create a Purchase Order, second FALSE: no Item Inventory.
        GeneralSetupForPlanningWorksheet(Item, ProductionForecastEntry, RequisitionWkshName, false, false);

        // Exercise: Calculate Regenerative Plan.
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name);

        // Verify: Verify planning worksheet.
        // Verify quantity on RequisitionLine of Planning Worksheet was less than Maximum Order Quantity of the Item.
        // Verify supply have met demand and Safety Stock Quantity.
        VerifyPlanWkshLineForMaximumOrderQuantity(ProductionForecastEntry, Item, PlanningWorksheet, RequisitionWkshName.Name);

        // Tear Down.
        UpdateForecastOnInventorySetup(
          InventorySetup."Current Demand Forecast", InventorySetup."Use Forecast on Locations");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandSupplyWithBaseCalendarForPlanningWorksheet()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        InventorySetup: Record "Inventory Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Base Calendar]

        // Calculate Regenerative Plan (LFL Item) with Base Calender and Carry out Action Message.
        // Verify "Expected Receipt Date" in Purchase order is consistent with "Shipment Date" of the Sales Demand.
        Initialize();
        InventorySetup.Get();

        // Setup: Create Base Calendar, set Sunday as working day, other days as non-working day, Create Vendor, bind the calendar
        // to the Vendor, create a Lot-For-Lot Item, set the vendor as the supplier. Create a Sales Order, set the shipment date
        // of the sales line as Friday, set InventorySetup."Default Safety Lead Time" to 0D.
        SetupDemandWithBaseCalendar(Item, SalesHeader, CalcDate('<WD5>', GetRandomDateUsingWorkDate(30)), 0);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60)); // Calculate Regenerative Plan on Planning worksheet
        SelectSalesLine(SalesLine, SalesHeader."No.");
        SelectRequisitionLineForActionMessage(
          RequisitionLine, Item."No.", RequisitionLine."Action Message"::New, SalesLine."Shipment Date");

        // Exercise: Carry out action message on the planning worksheet.
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);

        // Verify: Verify Expected Receipt Date = SalesLine."Shipment Date", Planned Receipt Date = SalesLine."Shipment Date",
        // and Order Date is the latest working day (Sunday) before the Planned Receipt Date.
        VerifyDateOnPurchaseLine(
          Item."No.", SalesLine."Shipment Date", SalesLine."Shipment Date", CalcDate('<-WD7>', SalesLine."Shipment Date"));

        // Exercise: Calculate Regenerative Plan on Planning worksheet again.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));

        // Verify: No requisition line exists for the item.
        FilterRequisitionLine(RequisitionLine, Item."No.");
        Assert.IsTrue(RequisitionLine.IsEmpty, RequisitionLineNotEmptyErr);

        // Tear Down.
        UpdateDefaultSafetyLeadTimeOnInventorySetup(InventorySetup."Default Safety Lead Time");
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure DemandSupplyWithBaseCalendarForOrderPlanning()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        InventorySetup: Record "Inventory Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Base Calendar] [Order Planning]

        // Calculate Order Planning with Base Calender and Make to Order.
        // Verify "Expected Receipt Date" in Purchase order is consistent with "Shipment Date" of the Sales Demand.
        Initialize();
        InventorySetup.Get();

        // Setup: Create Base Calendar, set Sunday as working day, other days as non-working day, Create Vendor, bind the calendar
        // to the Vendor, create a Lot-For-Lot Item, set the vendor as the supplier. Create a Sales Order, set the shipment date
        // of the sales line as Friday, set InventorySetup."Default Safety Lead Time" to 0D.
        SetupDemandWithBaseCalendar(Item, SalesHeader, CalcDate('<WD5>', WorkDate()), 0);

        // Exercise: Calculate Order Planning for Sales Order.
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // Find the requisition line in Order Planning.
        FilterRequisitionLine(RequisitionLine, Item."No.");
        RequisitionLine.FindFirst();
        SelectSalesLine(SalesLine, SalesHeader."No.");

        // Verify: Due Date of Requisition Line equals the Shipment Date of Sales demand.
        RequisitionLine.TestField("Due Date", SalesLine."Shipment Date");

        // Exercise: Make the requisition line to Purchase Order
        MakeSupplyOrdersActiveOrder(SalesHeader."No.");

        // Verify: Verify Expected Receipt Date = SalesLine."Shipment Date", Planned Receipt Date = SalesLine."Shipment Date",
        // and Order Date is the latest working day (Sunday) before the Planned Receipt Date.
        VerifyDateOnPurchaseLine(
          Item."No.", SalesLine."Shipment Date", SalesLine."Shipment Date", CalcDate('<-WD7>', SalesLine."Shipment Date"));

        // Tear Down.
        UpdateDefaultSafetyLeadTimeOnInventorySetup(InventorySetup."Default Safety Lead Time");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculatePlanningWorksheetWithBaseCalendar()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        InventorySetup: Record "Inventory Setup";
        SalesHeader: Record "Sales Header";
        DefaultSafetyLeadTime: Integer;
    begin
        // [FEATURE] [Base Calendar]

        // Calculate Regenerative Plan (Maximum Qty. Item) with Base Calender. Verify "Due Date" in Requisition line.
        Initialize();
        InventorySetup.Get();

        // Setup: Create Base Calendar, set Sunday as working day, other days as non-working day, create Vendor, bind the calendar
        // to the Vendor, create an Item with Reordering Policy = Maximum Qty., set the vendor as the supplier. Create a Sales Order, set the shipment date
        // of the sales line as Saturday, set InventorySetup."Default Safety Lead Time" to random value.
        DefaultSafetyLeadTime := LibraryRandom.RandInt(10);
        SetupDemandWithBaseCalendar(Item, SalesHeader, CalcDate('<WD6>', GetRandomDateUsingWorkDate(30)), DefaultSafetyLeadTime);
        UpdateItemReorderingPolicy(Item, Item."Reordering Policy"::"Maximum Qty.");

        // Exercise: Calculate Regenerative Plan on Planning worksheet.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));

        // Verify: Find the requistion line and verify calculating Due Date from Ending Date doesn't need to consider Vendor's calendar.
        FindRequisitionLine(RequisitionLine, Item."No.");
        RequisitionLine.TestField("Due Date", RequisitionLine."Ending Date" + DefaultSafetyLeadTime);

        // Tear Down.
        UpdateDefaultSafetyLeadTimeOnInventorySetup(InventorySetup."Default Safety Lead Time");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculatePlanningWorksheetAndCarryOutWithBaseCalendar()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        InventorySetup: Record "Inventory Setup";
        SalesHeader: Record "Sales Header";
        PurchaseLine: Record "Purchase Line";
        OrderDate: Date;
    begin
        // [FEATURE] [Base Calendar] [Carry Out Action Message]

        // Calculate Regenerative Plan (LFL Item) with Base Calender and carry out Purchase Order.
        // Verify "Order Date" in Requisition line is consistent with the "Order Date" on carried out Purchase Line.
        Initialize();
        InventorySetup.Get();

        // Setup: Create Base Calendar, set Sunday as working day, other days as non-working day, create Vendor, bind the calendar
        // to the Vendor, create a Lot-For-Lot Item with setting Lead Time Calculation, set the vendor as the supplier. Create a Sales Order, set the shipment date
        // of the sales line as Saturday, set InventorySetup."Default Safety Lead Time" to random value.
        SetupDemandWithBaseCalendar(Item, SalesHeader, CalcDate('<WD6>', GetRandomDateUsingWorkDate(30)), LibraryRandom.RandInt(10));
        UpdateItemLeadTimeCalculation(Item, LibraryRandom.RandInt(10));

        // Exercise: Calculate Regenerative Plan on Planning worksheet.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));
        FindRequisitionLine(RequisitionLine, Item."No.");
        OrderDate := RequisitionLine."Order Date";

        // Carry out action message on the planning worksheet.
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
        FilterPurchaseOrderLine(PurchaseLine, Item."No.");

        // Verify: Verify "Order Date" in Requisition line consistent with the "Order Date" on carried out Purchase Line.
        Assert.AreEqual(PurchaseLine."Order Date", OrderDate, StrSubstNo(OrderDateErr, OrderDate, PurchaseLine."Order Date"));

        // Tear Down.
        UpdateDefaultSafetyLeadTimeOnInventorySetup(InventorySetup."Default Safety Lead Time");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculatePlanningWorksheetWithFilledMaximumQuantity()
    var
        Item: Record Item;
        PositiveAdjustmentQuantity: Integer;
        MaxOrderQuantity: Integer;
    begin
        // [FEATURE] [Planning Worksheet] [Sales Order]
        // [SCENARIO 379231] Calculate Regenerative Plan should suggest correct quantity if supply with Source Type = "Item Ledger Entry" and Source Type = "Prod. Order Line" exists.
        Initialize();

        PositiveAdjustmentQuantity := LibraryRandom.RandInt(10);
        MaxOrderQuantity := LibraryRandom.RandIntInRange(PositiveAdjustmentQuantity, 100);

        // [GIVEN] Lot-For-Lot Item with Minimum and Maximum Order Quantity.
        CreateLFLItemWithMaximumAndMinimumOrderQuantity(Item, MaxOrderQuantity);

        // [GIVEN] Posted positive adjustment and Sales Order with three lines with Quantity = "X".
        PostPositiveAdjustmentAndCreateSalesOrderWithThreeLines(Item, PositiveAdjustmentQuantity, MaxOrderQuantity);

        // [GIVEN] Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // [GIVEN] Carry out first line in Planning Worksheet with Quantity = 2 * "X".
        ChangeQuantityAndAcceptActionMessageInRequisitionLine(Item."No.", 2 * MaxOrderQuantity);
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);

        // [WHEN] Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // [THEN] Planning Worksheet has one line with Quantity = "X".
        FilterRequisitionLine(RequisitionLine, Item."No.");
        VerifyPlanningWorksheetQuantityAndLineCount(RequisitionLine, MaxOrderQuantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProductionOrderStatusChangingWhenRequisitionLineExist()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [Planning Worksheet] [Production]
        // [SCENARIO 378897] Changing Production Order Status should pass successfully if connected requisition line in Planning Worksheet exists.
        Initialize();

        // [GIVEN] Create Sales Order and connected Product Order by using Carry Out Action Message.
        // [GIVEN] Calculate Regenerative Plan after updating Sales Order.
        CreatePlanWkshLineWithChangeQtyActionMessage(Item, Item."Replenishment System"::"Prod. Order", LibraryRandom.RandInt(50));

        // [GIVEN] Change Production Order status to Released.
        LibraryManufacturing.ChangeStatusFirmPlanToReleased(GetOrderNo(Item."No."));

        // [THEN] Production Order Status is Released.
        ProductionOrder.Get(ProductionOrder.Status::Released, GetOrderNo(Item."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyWithCompanyBaseCalendarCode()
    var
        Item: Record Item;
        ServiceMgtSetup: Record "Service Mgt. Setup";
        OldBaseCalendarCode: Code[10];
        ExpectedDate: Date;
    begin
        // [FEATURE] [Base Calendar]
        Initialize();

        // Setup: Create Vendor, Item and add Base Calendar Code to Company Information.
        CreateItemWithVendorNoReorderingPolicy(Item);

        ServiceMgtSetup.Get();
        OldBaseCalendarCode := UpdateCompanyInformationBaseCalendarCode(ServiceMgtSetup."Base Calendar Code");

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), CalcDate('<CY>', WorkDate()));
        FindRequisitionLine(RequisitionLine, Item."No.");

        // Verify: verify Order Date in created requisition line.
        ExpectedDate := FindClosestWorkingDay(ServiceMgtSetup, WorkDate());
        Assert.AreEqual(ExpectedDate, RequisitionLine."Order Date", StrSubstNo(ReqLineOrderDateErr, ExpectedDate));

        // Tear Down.
        UpdateCompanyInformationBaseCalendarCode(OldBaseCalendarCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyWithoutCompanyBaseCalendarCode()
    var
        Item: Record Item;
    begin
        Initialize();

        // Setup: Create Vendor with blank Base Calendar Code, Item.
        CreateItemWithVendorNoReorderingPolicy(Item);

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), CalcDate('<CY>', WorkDate()));
        FindRequisitionLine(RequisitionLine, Item."No.");

        // Verify: verify Order Date in created requisition line.
        Assert.AreEqual(WorkDate(), RequisitionLine."Order Date", StrSubstNo(ReqLineOrderDateErr, WorkDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyWithCompanyAndVendorBaseCalendarCode()
    var
        Item: Record Item;
        ServiceMgtSetup: Record "Service Mgt. Setup";
        OldBaseCalendarCode: Code[10];
        VendorNo: Code[20];
        ExpectedDate: Date;
    begin
        // [FEATURE] [Base Calendar]
        Initialize();

        // Setup: Create Vendor with Base Calendar Code, Item
        // and add Base Calendar Code to Company Information.
        VendorNo := CreateItemWithVendorNoReorderingPolicy(Item);

        ServiceMgtSetup.Get();
        OldBaseCalendarCode := UpdateCompanyInformationBaseCalendarCode(ServiceMgtSetup."Base Calendar Code");
        UpdateVendorBaseCalendarCode(VendorNo, ServiceMgtSetup."Base Calendar Code");

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), CalcDate('<CY>', WorkDate()));
        FindRequisitionLine(RequisitionLine, Item."No.");

        // Verify: verify Order Date in created requisition line.
        ExpectedDate := FindClosestWorkingDay(ServiceMgtSetup, WorkDate());
        Assert.AreEqual(ExpectedDate, RequisitionLine."Order Date", StrSubstNo(ReqLineOrderDateErr, ExpectedDate));

        // Tear Down.
        UpdateCompanyInformationBaseCalendarCode(OldBaseCalendarCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateOrderPlanningWithBaseCalendar()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        InventorySetup: Record "Inventory Setup";
        SalesHeader: Record "Sales Header";
        OrderPromisingSetup: Record "Order Promising Setup";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        DefaultSafetyLeadTime: Integer;
        OldReqTemplateType: Enum "Req. Worksheet Template Type";
    begin
        // [FEATURE] [Base Calendar] [Order Planning]

        // Calculate Order Planning (LFL Item) with Base Calender. Verify "Ending Date" in Requisition line.
        Initialize();
        InventorySetup.Get();
        OrderPromisingSetup.Get();
        ReqWkshTemplate.Get(OrderPromisingSetup."Order Promising Template");
        if ReqWkshTemplate.Type <> ReqWkshTemplate.Type::Planning then begin
            OldReqTemplateType := ReqWkshTemplate.Type;
            ReqWkshTemplate.Type := ReqWkshTemplate.Type::Planning;
            ReqWkshTemplate.Modify();
        end;

        // Setup: Create Base Calendar, set Sunday as working day, other days as non-working day, create Vendor, bind the calendar
        // to the Vendor, create a Lot-For-Lot Item, set the vendor as the supplier. Create a Sales Order, set the shipment date
        // of the sales line as Saturday, set InventorySetup."Default Safety Lead Time" to random value.
        DefaultSafetyLeadTime := LibraryRandom.RandInt(10);
        SetupDemandWithBaseCalendar(Item, SalesHeader, CalcDate('<WD6>', WorkDate()), DefaultSafetyLeadTime);

        // Exercise: Calculate Order Planning for Sales Order.
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // Verify: Find the requistion line and verify calculating Ending Date from Due Date doesn't need to consider Vendor's calendar.
        FindRequisitionLine(RequisitionLine, Item."No.");
        RequisitionLine.TestField("Ending Date", RequisitionLine."Due Date" - DefaultSafetyLeadTime);

        // Tear Down.
        UpdateDefaultSafetyLeadTimeOnInventorySetup(InventorySetup."Default Safety Lead Time");
        if ReqWkshTemplate.Type <> OldReqTemplateType then begin
            ReqWkshTemplate.Type := OldReqTemplateType;
            ReqWkshTemplate.Modify();
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculatePlanningWorksheetWithBaseCalendarAndItemVendorForLotForLotItem()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Base Calendar]
        // Calculate Regenerative Plan (LFL Item) with Base Calender and Item Vendor. Verify "Ending Date" in Requisition line.
        Initialize();

        CalculatePlanningWorksheetWithBaseCalendarAndItemVendor(Item."Reordering Policy"::"Lot-for-Lot");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculatePlanningWorksheetWithBaseCalendarAndItemVendorForOrderItem()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Base Calendar]
        // Calculate Regenerative Plan (Order Item) with Base Calender and Item Vendor. Verify "Ending Date" in Requisition line.
        Initialize();

        CalculatePlanningWorksheetWithBaseCalendarAndItemVendor(Item."Reordering Policy"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcReqWkshForFRQItemWithSupply()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        OrderDate: Date;
    begin
        // [FEATURE] [Fixed Reorder Quantity] [Lead Time Calculation]

        // Calculate Plan (FRQ Item) on Requisition Worksheet with Supply for blank Location. Verify Requisition Worksheet.

        // Setup: Create Item with Reordering Policy = Fixed Reorder Qty., set Item's Lead Time Calculation.
        // Create a Purchase Line for Item and Quantity greater than Item's Reorder Point.
        // Exercise: Calculate Plan for Item with Starting Date = Ending Date = PurchaseLine."Order Date".
        // Verify: Verify no error pops up.
        Initialize();
        CreatePurchOrdWithFRQItemAndCalculatePlan(Item, OrderDate, false); // FALSE indicates no location code on Purchase Line

        // Verify: No Requisition Line calculated since the Quantity on Purchase Line is greater than Item's Reorder Point.
        FilterRequisitionLine(RequisitionLine, Item."No.");
        Assert.IsTrue(RequisitionLine.IsEmpty, RequisitionLineNotEmptyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcReqWkshForFRQItemWithSupplyForLocation()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        InventorySetup: Record "Inventory Setup";
        OrderDate: Date;
    begin
        // [FEATURE] [Fixed Reorder Quantity] [Lead Time Calculation]

        // Calculate Plan (FRQ Item) on Requisition Worksheet with Supply for specified Location. Verify Requisition Worksheet.

        // Setup: Create Item with Reordering Policy = Fixed Reorder Qty., set Item's Lead Time Calculation.
        // Create a Purchase Line with Location Code for Item and Quantity greater than Item's Reorder Point.
        // Exercise: Calculate Plan for Item with Starting Date = Ending Date = PurchaseLine."Order Date".
        // Verify: Verify no error pops up.
        Initialize();
        CreatePurchOrdWithFRQItemAndCalculatePlan(Item, OrderDate, true); // TRUE indicates filling location code on Purchase Line

        // Verify: 1 Requisition Line for blank Location with New Action Message is calculated.
        InventorySetup.Get();
        SelectRequisitionLineForActionMessage(
          RequisitionLine, Item."No.", RequisitionLine."Action Message"::New,
          CalcDate(InventorySetup."Default Safety Lead Time", CalcDate(Item."Lead Time Calculation", OrderDate)));
        RequisitionLine.TestField(Quantity, Item."Reorder Quantity");
        RequisitionLine.TestField("Location Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateRegenerativePlanForFRQWithExceptionLine()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        UntrackedPlanningElement: Record "Untracked Planning Element";
        Quantity: Decimal;
    begin
        // [FEATURE] [Fixed Reorder Quantity] [Order Multiple]

        // Calculate Regenerative Plan (FRQ Item) with Exception Line when Order Multiple is set on Item.
        // Verify Order Multiple should not be respected for the Exception Line.

        // Setup: Create FRQ Item. Update Order Multiple. Create Sales Order.
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(30, 35);
        CreateAndUpdateFRQItem(
          Item, Item."Replenishment System"::Purchase, LibraryRandom.RandInt(20),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(5),
          LibraryRandom.RandIntInRange(25, 28));
        CreateSalesOrder(SalesHeader, Item."No.", Quantity, WorkDate());

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(5));

        // Verify: Verify Quantity is correct without respecting by Order Multiple with Exception Line in Planning Worksheet.
        // Quantity equals to the demand in Sales order plus the Safety Stock Quantity.
        FindUntrackedPlanningElementLine(
          UntrackedPlanningElement, Item."No.", StrSubstNo(ExceptionMsg, Item."Safety Stock Quantity", WorkDate()));
        VerifyQuantityOnRequisitionLine(
          Item."No.", UntrackedPlanningElement."Worksheet Line No.", Quantity + Item."Safety Stock Quantity");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcReqWkshWithReplenishmentIsProdOrderInSKU()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Maximum Order Quantity] [Stockkeeping Unit]

        // Calculate Plan (MQ Item) on Requisition Worksheet with Replenishement = Prod. Order in SKU.

        // Setup: Create Item. Create SKU.
        // Item Maximum Inventory is greater than Item Reorder Point. Safety Stock is Zero.
        Initialize();
        CreateMQItem(
          Item, Item."Replenishment System"::Purchase, LibraryRandom.RandInt(10) + 20,
          LibraryRandom.RandInt(10) + 10, 0);
        CreateAndUpdateStockKeepingUnit(Item, LocationBlue.Code, Item."Replenishment System"::"Prod. Order");

        // Exercise: Calculate Plan in Requisition Worksheet.
        CalculatePlanForReqWksh(Item, WorkDate(), WorkDate());

        // Verify: Verify the line with Replenishment = Prod. Order not be generated in Requisition Worksheet.
        FilterRequisitionLine(RequisitionLine, Item."No.");
        Assert.IsTrue(RequisitionLine.IsEmpty, RequisitionLineNotEmptyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReCalcPlanForReschedulePlanningLinesAfterDeleteFirstPlanningLine()
    var
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DemandDateValue: array[3] of Date;
        PlanningLinesCountBeforeCarryOut: Integer;
    begin
        // Re-calculate Regenerative plan in the Planning Worksheet for Reschedule Planning Lines after deleting the first Planning Line.
        // Verify no message pops up and the count of Requistion Lines.

        // Setup: Create Item with Planning parameters and BOM. Create a Sales Order.
        Initialize();
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(10), GetRandomDateUsingWorkDate(20), 0D);
        CreateItemWithPlanningParametersAndBOM(Item, Item2, '<1M>', '<' + Format(LibraryRandom.RandInt(10)) + 'D>', true);
        CreateSalesOrder(SalesHeader, Item."No.", LibraryRandom.RandInt(5), DemandDateValue[1]);

        // Calculate Regenerative Plan and Carry Out Action Message.
        Item3.SetFilter("No.", '%1|%2', Item."No.", Item2."No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item3, WorkDate(), DemandDateValue[1]);
        AcceptActionMessageAndCarryOutActionMessagePlan(Item."No.", PlanningLinesCountBeforeCarryOut);
        AcceptActionMessageAndCarryOutActionMessagePlan(Item2."No.", PlanningLinesCountBeforeCarryOut);

        // Exercise: Update the Shipment Date within the rescheduling period on Sales Order, then Calculate Regenerative Plan.
        // Delete the first line in the Planning Worksheet then Re-Calculate Regenerative Plan.
        UpdateShipmentDateForSales(SalesLine, SalesHeader."No.", DemandDateValue[2]);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item3, WorkDate(), DemandDateValue[2]);
        DeleteFirstRequisitionLine(10000); // Line No. is important, here is an empty line.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item3, WorkDate(), DemandDateValue[2]);

        // Verify: Verify no error message pops up and there are two Requistion Lines for Parent Item and Child Item.
        VerifyRequisitionLineCount(2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateReplenishmentInRequsitionWorksheet()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Requisition Worksheet]

        // Test an error pops up when updating Replenishment to Prod. Order in Req. Worksheet.

        // Setup: Create Item. Item Maximum Inventory is greater than Item Reorder Point. Safety Stock is Zero.
        Initialize();
        CreateMQItem(
          Item, Item."Replenishment System"::Purchase, LibraryRandom.RandInt(10) + 20,
          LibraryRandom.RandInt(10) + 10, 0);

        // Exercise: Calculate Plan in Requisition Worksheet and update Replenishment to Prod. Order.
        CalculatePlanForReqWksh(Item, WorkDate(), WorkDate());
        FindRequisitionLine(RequisitionLine, Item."No.");
        asserterror RequisitionLine.Validate("Replenishment System", RequisitionLine."Replenishment System"::"Prod. Order");

        // Verify: Verify the error message.
        Assert.ExpectedError(RequisitionWorksheetErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReCalcPlngWkshAfterDemandDateChangedAndQuantityIncreased()
    begin
        // [FEATURE] [Reservation]

        // Recalculate Regenerative Plan (Order Item) after Shipment Date is changed and demand Quantity increased,
        // and then delete the Requisition Line. Test and verify Expected Receipt Date in Reservation Entry is correct.
        Initialize();

        ReCalcPlngWkshAfterDemandChanged(LibraryRandom.RandIntInRange(40, 50));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReCalcPlngWkshAfterDemandDateChangedAndQuantityDecreased()
    begin
        // [FEATURE] [Reservation]

        // Recalculate Regenerative Plan (Order Item) after Shipment Date is changed and demand Quantity decreased,
        // and then delete the Requisition Line. Test and verify Expected Receipt Date in Reservation Entry is correct.
        Initialize();

        ReCalcPlngWkshAfterDemandChanged(LibraryRandom.RandInt(10));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanWithMaximumInventoryLessThenOne()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReqLine: Record "Requisition Line";
        ReorderPoint: Decimal;
        MaxQty: Decimal;
        Qty: Decimal;
    begin
        // [FEATURE] [Calculate Regenerative Plan]
        // [SCENARIO 377525] Calculate Regenerative Plan should process correctly if "Reorder Point" and "Maximum Inventory" are less than 1
        Initialize();

        // [GIVEN] Item with Maximum Inventory "M" and Reorder Point "R". "R" < "M" < 1
        ReorderPoint := LibraryRandom.RandDecInDecimalRange(0, 0.5, 2);
        MaxQty := LibraryRandom.RandDecInDecimalRange(0.51, 1, 2);
        CreateMQItem(Item, Item."Replenishment System"::Purchase, MaxQty, ReorderPoint, 0);

        // [GIVEN] Sales Order for Item of Quantity = "Q"
        Qty := LibraryRandom.RandInt(10);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Qty);

        // [WHEN] Calculate Regenerative Plan
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));
        // [THEN] Two Requisition Line are created for Item: with Quantity = "M" and "Q" accordingly
        ReqLine.SetRange("No.", Item."No.");
        ReqLine.FindSet();
        Assert.AreEqual(MaxQty, ReqLine.Quantity, QuantityErr);
        ReqLine.Next();
        Assert.AreEqual(Qty, ReqLine.Quantity, QuantityErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuppliesRescheduledIfCancelNewActionsBlockedByLargeDampenerQty()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        ProdItemNo: Code[20];
        CompItemNo: Code[20];
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        PlanningLinesCount: Integer;
        i: Integer;
    begin
        // [FEATURE] [Calculate Regenerative Plan] [Dampener Quantity]
        // [SCENARIO 381346] Purchases for Lot-for-Lot component Items should be rescheduled to supply production, if "cancel"+"new" actions are not permitted by Dampener Quantity larger than quantity of the purchases.
        Initialize();

        // [GIVEN] Purchased component Item with Lot-for-Lot reordering policy and Dampener Quantity = "DQ".
        // [GIVEN] Production Item with BOM containing the component Item.
        CreateProductionItemWithLFLComponent(ProdItemNo, CompItemNo);

        // [GIVEN] Sequence of sales orders for the production Item. Quantity to be shipped is less than "DQ". Shipment Dates are "D1", "D2", "D3".
        SetDemandDates(DemandDateValue, 1, 30);
        CreateDemandQuantity(
          DemandQuantityValue, LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), LibraryRandom.RandInt(10));
        CreateDemand(DemandDateValue, DemandQuantityValue, ProdItemNo, 3);

        // [GIVEN] Regenerative Plan for both items is calculated, action messages are accepted.
        Item.SetFilter("No.", '%1|%2', ProdItemNo, CompItemNo);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), CalcDate('<+1Y>', WorkDate()));
        AcceptActionMessageAndCarryOutActionMessagePlan(ProdItemNo, PlanningLinesCount);
        AcceptActionMessageAndCarryOutActionMessagePlan(CompItemNo, PlanningLinesCount);

        // [GIVEN] Shipment dates are shifted forward, so supplies will precede demands. New Shipment Dates are "D1+", "D2+", "D3+".
        SetDemandDates(DemandDateValue, 90, 120);
        for i := 1 to ArrayLen(DemandDateValue) do
            UpdateShipmentDateForSales(SalesLine, GlobalSalesHeader[i]."No.", DemandDateValue[i]);

        // [WHEN] Recalculate the Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), CalcDate('<+1Y>', WorkDate()));

        // [THEN] Due Dates for supplies of the component Item are suggested one day before "D1+", "D2+", "D3+".
        VerifyDueDatesOnRequisitionLine(CompItemNo, DemandDateValue);
    end;

    [Test]
    [HandlerFunctions('AssemblyAvailabilityModalPageHandler,ConfirmHandlerYes,SendAssemblyAvailabilityNotificationHandler')]
    [Scope('OnPrem')]
    procedure AssemblyOrderWithReservationChangeStartingDate()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        NameValueBuffer: Record "Name/Value Buffer";
        SCMSupplyPlanning: Codeunit "SCM Supply Planning";
    begin
        // [SCENARIO 381886] Stan can increase "Starting date" in assembly order when it has related reservation entries.
        Initialize();

        // [GIVEN] Assembly Order having two reservation entries created via Planning Worksheet.
        CreateMQItemAssembly(Item);
        CreateAssemblyOrderFromPlanningWorksheet(AssemblyHeader, Item);

        NameValueBuffer.DeleteAll();
        BindSubscription(SCMSupplyPlanning);

        // [WHEN] Increase "Starting date" in assembly order
        AssemblyHeader.Validate("Starting Date", CalcDate('<1D>', AssemblyHeader."Starting Date"));
        AssemblyHeader.Modify(true);

        // [THEN] Assembly Avalailability dialog appeared => Confirmation dialog appeared => Reservation entries modified
        Assert.RecordCount(NameValueBuffer, 4);
        NameValueBuffer.FindSet();
        NameValueBuffer.TestField(Name, AvailabilityTok);
        NameValueBuffer.Next();
        VerifyNameValueBufferSequence(NameValueBuffer, ConfirmTok);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('AssemblyAvailabilityModalPageHandler,ConfirmHandlerYes,SendAssemblyAvailabilityNotificationHandler')]
    [Scope('OnPrem')]
    procedure AssemblyOrderWithReservationChangeEndingDate()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        NameValueBuffer: Record "Name/Value Buffer";
        SCMSupplyPlanning: Codeunit "SCM Supply Planning";
    begin
        // [SCENARIO 381886] Stan can increase "Ending date" in assembly order when it has related reservation entries.
        Initialize();

        // [GIVEN] Assembly Order having two reservation entries created via Planning Worksheet.
        CreateMQItemAssembly(Item);
        CreateAssemblyOrderFromPlanningWorksheet(AssemblyHeader, Item);

        NameValueBuffer.DeleteAll();
        BindSubscription(SCMSupplyPlanning);

        // [WHEN] Increase "Ending date" in assembly order
        AssemblyHeader.Validate("Ending Date", CalcDate('<1D>', AssemblyHeader."Ending Date"));
        AssemblyHeader.Modify(true);

        // [THEN] Assembly Avalailability dialog appeared => Confirmation dialog appeared => Reservation entries modified
        Assert.RecordCount(NameValueBuffer, 4);
        NameValueBuffer.FindSet();
        NameValueBuffer.TestField(Name, AvailabilityTok);
        NameValueBuffer.Next();
        VerifyNameValueBufferSequence(NameValueBuffer, ConfirmTok);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('AssemblyAvailabilityModalPageHandler,SendAssemblyAvailabilityNotificationHandler')]
    [Scope('OnPrem')]
    procedure AssemblyOrderWithReservationChangeDueDate()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        NameValueBuffer: Record "Name/Value Buffer";
        SCMSupplyPlanning: Codeunit "SCM Supply Planning";
    begin
        // [SCENARIO 381886] Stan can increase "Due date" in assembly order when it has related reservation entries.
        Initialize();

        // [GIVEN] Assembly Order having two reservation entries created via Planning Worksheet.
        CreateMQItemAssembly(Item);
        CreateAssemblyOrderFromPlanningWorksheet(AssemblyHeader, Item);

        NameValueBuffer.DeleteAll();
        BindSubscription(SCMSupplyPlanning);

        // [WHEN] Increase "Due date" in assembly order
        AssemblyHeader.Validate("Due Date", CalcDate('<1D>', AssemblyHeader."Due Date"));
        AssemblyHeader.Modify(true);

        // [THEN] Assembly Avalailability dialog appeared => Reservation entries modified
        Assert.RecordCount(NameValueBuffer, 3);
        NameValueBuffer.FindFirst();
        VerifyNameValueBufferSequence(NameValueBuffer, AvailabilityTok);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyNotReplannedIfItExceedsDemandLessOrEqualThanDampenerQtyMinusSafetyStock()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Planning Worksheet] [Dampener Quantity] [Safety Stock]
        // [SCENARIO 205829] Supply that exceeds demand by more than Dampener Qty. should not be replanned if with the consideration of safety stock it makes that difference less or equal than the Dampener Qty.
        Initialize();

        // [GIVEN] Item with Lot-for-Lot reordering policy. Dampener Qty. = "D". Safety stock qty. = "S" (e.g. "D" = 10, "S" = 5).
        // [GIVEN] Two purchases of the item for "QP1" and "QP2" pcs correspondently (e.g. "QP1" = 40, "QP2" = 50).
        // [GIVEN] Sales order of the item for "QS", so that "QP1" + "QP2" - "QS" > "D", but "QP1" + "QP2" - "QS" - "S" <= "D". (E.g. "QS" = 75).
        PrepareSupplyAndDemandWithDampenerQtyAndSafetyStock(Item, 10, 5, LibraryRandom.RandIntInRange(11, 15));

        // [WHEN] Calculate regenerative plan for the period that includes the second purchase only.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate() + 1, GetRandomDateUsingWorkDate(90));

        // [THEN] No planning lines are created. No change is suggested for the purchase.
        FilterRequisitionLine(RequisitionLine, Item."No.");
        Assert.RecordIsEmpty(RequisitionLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SupplyReplannedIfItExceedsDemandMoreThanDampenerQtyMinusSafetyStock()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PurchaseLine: Record "Purchase Line";
        ExceedingQty: Decimal;
        SafetyStockQty: Decimal;
    begin
        // [FEATURE] [Planning Worksheet] [Dampener Quantity] [Safety Stock]
        // [SCENARIO 205829] Supply that exceeds demand plus safety stock for more than Dampener Qty. should be replanned.
        Initialize();

        // [GIVEN] Item with Lot-for-Lot reordering policy. Dampener Qty. = "D". Safety stock qty. = "S" (e.g. "D" = 10, "S" = 5).
        // [GIVEN] Two purchases of the item for "QP1" and "QP2" pcs correspondently (e.g. "QP1" = 40, "QP2" = 50).
        // [GIVEN] Sales order of the item for "QS", so that "QP1" + "QP2" - "QS" - "S" > "D". (E.g. "QS" = 60).
        SafetyStockQty := 5;
        ExceedingQty := LibraryRandom.RandIntInRange(16, 20);
        PrepareSupplyAndDemandWithDampenerQtyAndSafetyStock(Item, 10, SafetyStockQty, ExceedingQty);

        // [WHEN] Calculate regenerative plan for the period that includes the second purchase only.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate() + 1, GetRandomDateUsingWorkDate(90));

        // [THEN] The purchase is suggested to be replanned so that "QP1" + "QP2" = "QS" + "S" (in the example, new "QP2" = 25).
        SelectPurchaseLine(PurchaseLine, GlobalPurchaseHeader[2]."No.");
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::"Change Qty.", PurchaseLine."Expected Receipt Date", PurchaseLine.Quantity,
          PurchaseLine.Quantity - ExceedingQty + SafetyStockQty, 0D, '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_ItemAvailByLocationDateFilterMonth()
    var
        ItemCard: TestPage "Item Card";
        ItemAvailabilitybyLocation: TestPage "Item Availability by Location";
        ExpectedDate: Date;
    begin
        // [FEATURE] [UI] [Item Availability]
        // [SCENARIO 210915] Date Filter is filter from the beginning of month to the end of month when open "Item Availability By Location" page with "Item Period Length" = Month

        Initialize();

        // [GIVEN] Work date is 01.01.2017
        // [GIVEN] Item Card is opened
        SetupItemCardScenario(ItemCard);

        // [GIVEN] "Item Availability by Location" page is opened from Item Card
        ItemAvailabilitybyLocation.Trap();
        ItemCard.Location.Invoke();
        ExpectedDate := GetCurrentDate(ItemAvailabilitybyLocation.FILTER.GetFilter("Date Filter"));

        // [WHEN] Set "Item Period Length" = Month on "Item Availability By Location" page
        ItemAvailabilitybyLocation.ItemPeriodLength.SetValue('Month');

        // [THEN] "Date Filter" is "01.01.2017..31.01.2017" on "Item Availability By Location" page
        ItemAvailabilitybyLocation.DateFilter.AssertEquals(
          StrSubstNo('%1..%2', CalcDate('<-CM>', ExpectedDate), CalcDate('<CM>', ExpectedDate)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_ItemAvailByLocationDateFilterNextPeriod()
    var
        ItemCard: TestPage "Item Card";
        ItemAvailabilitybyLocation: TestPage "Item Availability by Location";
        ExpectedDate: Date;
    begin
        // [FEATURE] [UI] [Item Availability]
        // [SCENARIO 210915] Date Filter is next period when press "Next Period" on "Item Availability By Location" page

        Initialize();

        // [GIVEN] Work date is 01.01.2017
        // [GIVEN] Item Card is opened
        SetupItemCardScenario(ItemCard);

        // [GIVEN] "Item Availability by Location" page is opened from Item Card with "Item Period Length" = Month
        ItemAvailabilitybyLocation.Trap();
        ItemCard.Location.Invoke();
        ItemAvailabilitybyLocation.ItemPeriodLength.SetValue('Month');
        ExpectedDate := CalcDate('<1M>', GetCurrentDate(ItemAvailabilitybyLocation.FILTER.GetFilter("Date Filter")));

        // [WHEN] Press "Next Period" on "Item Availability By Location" page
        ItemAvailabilitybyLocation.NextPeriod.Invoke();

        // [WHEN] "Date Filter" is "01.02.2017..28.02.2017" on "Item Availability By Location" page
        ItemAvailabilitybyLocation.DateFilter.AssertEquals(
          StrSubstNo('%1..%2', CalcDate('<-CM>', ExpectedDate), CalcDate('<CM>', ExpectedDate)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_ItemAvailByLocationDateFilterPrevPeriod()
    var
        ItemCard: TestPage "Item Card";
        ItemAvailabilitybyLocation: TestPage "Item Availability by Location";
        ExpectedDate: Date;
    begin
        // [FEATURE] [UI] [Item Availability]
        // [SCENARIO 210915] Date Filter is previous period when press "Previous Period" on "Item Availability By Location" page

        Initialize();

        // [GIVEN] Work date is 01.01.2017
        // [GIVEN] Item Card is opened
        SetupItemCardScenario(ItemCard);

        // [GIVEN] "Item Availability by Location" page is opened from Item Card with "Item Period Length" = Month
        ItemAvailabilitybyLocation.Trap();
        ItemCard.Location.Invoke();
        ItemAvailabilitybyLocation.ItemPeriodLength.SetValue('Month');
        ExpectedDate := CalcDate('<-1M>', GetCurrentDate(ItemAvailabilitybyLocation.FILTER.GetFilter("Date Filter")));

        // [WHEN] Press "Next Previous" on "Item Availability By Location" page
        ItemAvailabilitybyLocation.PreviousPeriod.Invoke();

        // [WHEN] "Date Filter" is "01.12.2016..31.12.2016" on "Item Availability By Location" page
        ItemAvailabilitybyLocation.DateFilter.AssertEquals(
          StrSubstNo('%1..%2', CalcDate('<-CM>', ExpectedDate), CalcDate('<CM>', ExpectedDate)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_ItemAvailByVariantDateFilterMonth()
    var
        ItemCard: TestPage "Item Card";
        ItemAvailabilitybyVariant: TestPage "Item Availability by Variant";
        ExpectedDate: Date;
    begin
        // [FEATURE] [UI] [Item Availability]
        // [SCENARIO 210915] Date Filter is filter from the beginning of month to the end of month when open "Item Availability By Variant" page with "Item Period Length" = Month

        Initialize();

        // [GIVEN] Work date is 01.01.2017
        // [GIVEN] Item Card is opened
        SetupItemCardScenario(ItemCard);

        // [GIVEN] "Item Availability by Variant" page is opened from Item Card
        ItemAvailabilitybyVariant.Trap();
        ItemCard.Variant.Invoke();
        ExpectedDate := GetCurrentDate(ItemAvailabilitybyVariant.FILTER.GetFilter("Date Filter"));

        // [WHEN] Set "Item Period Length" = Month on "Item Availability By Variant" page
        ItemAvailabilitybyVariant.PeriodType.SetValue('Month');

        // [THEN] "Date Filter" is "01.01.2017..31.01.2017" on "Item Availability By Variant" page
        ItemAvailabilitybyVariant.DateFilter.AssertEquals(
          StrSubstNo('%1..%2', CalcDate('<-CM>', ExpectedDate), CalcDate('<CM>', ExpectedDate)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_ItemAvailByVariantDateFilterNextPeriod()
    var
        ItemCard: TestPage "Item Card";
        ItemAvailabilitybyVariant: TestPage "Item Availability by Variant";
        ExpectedDate: Date;
    begin
        // [FEATURE] [UI] [Item Availability]
        // [SCENARIO 210915] Date Filter is next period when press "Next Period" on "Item Availability By Variant" page

        Initialize();

        // [GIVEN] Work date is 01.01.2017
        // [GIVEN] Item Card is opened
        SetupItemCardScenario(ItemCard);

        // [GIVEN] "Item Availability by Variant" page is opened from Item Card with "Period Type" = Month
        ItemAvailabilitybyVariant.Trap();
        ItemCard.Variant.Invoke();
        ItemAvailabilitybyVariant.PeriodType.SetValue('Month');
        ExpectedDate := CalcDate('<1M>', GetCurrentDate(ItemAvailabilitybyVariant.FILTER.GetFilter("Date Filter")));

        // [WHEN] Press "Next Period" on "Item Availability By Variant" page
        ItemAvailabilitybyVariant.NextPeriod.Invoke();

        // [WHEN] "Date Filter" is "01.02.2017..28.02.2017" on "Item Availability By Variant" page
        ItemAvailabilitybyVariant.DateFilter.AssertEquals(
          StrSubstNo('%1..%2', CalcDate('<-CM>', ExpectedDate), CalcDate('<CM>', ExpectedDate)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_ItemAvailByVariantDateFilterPrevPeriod()
    var
        ItemCard: TestPage "Item Card";
        ItemAvailabilitybyVariant: TestPage "Item Availability by Variant";
        ExpectedDate: Date;
    begin
        // [FEATURE] [UI] [Item Availability]
        // [SCENARIO 210915] Date Filter is previous period when press "Previous Period" on "Item Availability By Variant" page

        Initialize();

        // [GIVEN] Work date is 01.01.2017
        // [GIVEN] Item Card is opened
        SetupItemCardScenario(ItemCard);

        // [GIVEN] "Item Availability by Variant" page is opened from Item Card with "Period Type" = Month
        ItemAvailabilitybyVariant.Trap();
        ItemCard.Variant.Invoke();
        ItemAvailabilitybyVariant.PeriodType.SetValue('Month');
        ExpectedDate := CalcDate('<-1M>', GetCurrentDate(ItemAvailabilitybyVariant.FILTER.GetFilter("Date Filter")));

        // [WHEN] Press "Next Previous" on "Item Availability By Variant" page
        ItemAvailabilitybyVariant.PreviousPeriod.Invoke();

        // [WHEN] "Date Filter" is "01.12.2016..31.12.2016" on "Item Availability By Variant" page
        ItemAvailabilitybyVariant.DateFilter.AssertEquals(
          StrSubstNo('%1..%2', CalcDate('<-CM>', ExpectedDate), CalcDate('<CM>', ExpectedDate)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderReorderingPolicyRespectedForAssemblyComponent()
    var
        AsmItem: Record Item;
        CompItem: Record Item;
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [Assembly]
        // [SCENARIO 213101] For each requisition line replesenting an assembled item, should be created its own requisition line for the component item, if the component has Reordering Policy = Order.
        Initialize();

        // [GIVEN] Assembled item "I" with Reordering Policy = Order.
        CreateItem(AsmItem, AsmItem."Replenishment System"::Assembly);
        UpdateItemReorderingPolicy(AsmItem, AsmItem."Reordering Policy"::Order);

        // [GIVEN] Component item "C" with Reordering Policy = Order. Quantity of the component per 1 pc of "I" = 1.
        CreateItem(CompItem, CompItem."Replenishment System"::Purchase);
        UpdateItemReorderingPolicy(CompItem, CompItem."Reordering Policy"::Order);
        CreateBOMComponent(AsmItem."No.", CompItem."No.", 1);

        // [GIVEN] Three sales orders for "I", quantity on the orders = "Q1", "Q2", "Q3".
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(30), GetRandomDateUsingWorkDate(60), GetRandomDateUsingWorkDate(90));
        CreateDemandQuantity(DemandQuantityValue, LibraryRandom.RandInt(50), LibraryRandom.RandInt(50), LibraryRandom.RandInt(50));
        CreateDemand(DemandDateValue, DemandQuantityValue, AsmItem."No.", 3);

        // [WHEN] Calculate regenerative plan for both "I" and "C".
        Item.SetFilter("No.", '%1|%2', AsmItem."No.", CompItem."No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(90));

        // [THEN] 3 lines are created for the component item "C".
        FilterRequisitionLine(RequisitionLine, CompItem."No.");
        Assert.RecordCount(RequisitionLine, 3);

        // [THEN] Quantities on these lines are equal to "Q1", "Q2", "Q3".
        for i := 1 to ArrayLen(DemandQuantityValue) do begin
            RequisitionLine.Next();
            RequisitionLine.TestField(Quantity, DemandQuantityValue[i]);
        end;
    end;

    [Test]
    procedure DemandThreeSuppliesWithMaxOrderQuantityThirdSupplyHasLessDueDate()
    var
        Item: Record Item;
        DemandDateValue: array[3] of Date;
        SupplyDateValue: array[5] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyType: array[5] of Option;
    begin
        // [FEATURE] [Maximum Order Quantity]
        // [SCENARIO 386066] Calculate regenerative plan for one demand and three supplies when "Maximum Order Quantity" is set and the third supply has "Due Date" < Demand's "Due Date".
        Initialize();

        // [GIVEN] Item with Replenishment System = "Prod. Order" and with Maximum Order Quantity = 10.
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1Y>', '<1Y>', true, 0, 0);
        UpdateItem(Item, Item.FieldNo("Maximum Order Quantity"), 10);
        CreateAndUpdateStockKeepingUnit(Item, LocationBlue.Code, Item."Replenishment System"::"Prod. Order");
        UpdateMaxOrderQtyOnSKU(Item."No.", LocationBlue.Code, 10);

        // [GIVEN] One demand with "Due Date" = 20.02.2021 and with Quantity = 30.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(20), 0D, 0D);
        CreateDemandQuantity(DemandQuantityValue, 30, 0, 0);
        CreateDemandOnLocation(DemandTypeOption::"Sales Order", DemandDateValue, DemandQuantityValue, Item."No.", 1, LocationBlue.Code);

        // [GIVEN] Three supplies, each has Quantity = 10.
        // [GIVEN] First two supplies have Due Date = 20.02.2021. The third one has Due Date = 15.02.2021, which is less than demand's Due Date.
        CreateSupplyType(
          SupplyType, SupplyTypeOption::FirmPlanned, SupplyTypeOption::FirmPlanned,
          SupplyTypeOption::FirmPlanned, SupplyTypeOption::None, SupplyTypeOption::None);
        CreateSupplyDate(
          SupplyDateValue, GetRandomDateUsingWorkDate(20), GetRandomDateUsingWorkDate(20), GetRandomDateUsingWorkDate(15), 0D, 0D);
        CreateSupplyQuantity(SupplyQuantityValue, 10, 10, 10, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, Item."No.", '', LocationBlue.Code);

        // [WHEN] Calculate Regenerative Plan.
        Item.SetRecFilter();
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));

        // [THEN] One Requisition Line is created. It has Action Message = "Reschedule", Original Due Date = 15.02.2021, Due Date = 20.02.2021, Quantity = 10.
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::Reschedule, DemandDateValue[1],
          0, SupplyQuantityValue[3], SupplyDateValue[3], LocationBlue.Code, '');
        VerifyRequisitionLineCount(1);
    end;

    [Test]
    procedure DemandThreeSuppliesWithMaxOrderQuantityThirdSupplyHasLessDueDateAndLessQty()
    var
        Item: Record Item;
        DemandDateValue: array[3] of Date;
        SupplyDateValue: array[5] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyType: array[5] of Option;
    begin
        // [FEATURE] [Maximum Order Quantity]
        // [SCENARIO 386066] Calculate regenerative plan for one demand and three supplies when "Maximum Order Quantity" is set and the third supply has "Due Date" < Demand's "Due Date" and Quantity < Maximum Order Quantity of Item.
        Initialize();

        // [GIVEN] Item with Replenishment System = "Prod. Order" and with Maximum Order Quantity = 10.
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1Y>', '<1Y>', true, 0, 0);
        UpdateItem(Item, Item.FieldNo("Maximum Order Quantity"), 10);
        CreateAndUpdateStockKeepingUnit(Item, LocationBlue.Code, Item."Replenishment System"::"Prod. Order");
        UpdateMaxOrderQtyOnSKU(Item."No.", LocationBlue.Code, 10);

        // [GIVEN] One demand with "Due Date" = 20.02.2021 and with Quantity = 24.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(20), 0D, 0D);
        CreateDemandQuantity(DemandQuantityValue, 24, 0, 0);
        CreateDemandOnLocation(DemandTypeOption::"Sales Order", DemandDateValue, DemandQuantityValue, Item."No.", 1, LocationBlue.Code);

        // [GIVEN] Three supplies, first two have Quantity = 10, the third one has Quantity = 4.
        // [GIVEN] First two supplies have Due Date = 20.02.2021. The third one has Due Date = 15.02.2021, which is less than demand's Due Date.
        CreateSupplyType(
          SupplyType, SupplyTypeOption::FirmPlanned, SupplyTypeOption::FirmPlanned,
          SupplyTypeOption::FirmPlanned, SupplyTypeOption::None, SupplyTypeOption::None);
        CreateSupplyDate(
          SupplyDateValue, GetRandomDateUsingWorkDate(20), GetRandomDateUsingWorkDate(20), GetRandomDateUsingWorkDate(15), 0D, 0D);
        CreateSupplyQuantity(SupplyQuantityValue, 10, 10, 4, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, Item."No.", '', LocationBlue.Code);

        // [WHEN] Calculate Regenerative Plan.
        Item.SetRecFilter();
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));

        // [THEN] Two Requisition Lines are created. The first line has Action Message = "Resched. & Chg. Qty.", Original Due Date = 15.02.2021, Due Date = 20.02.2021, Original Quantity = 4, Quantity = 10.
        // [THEN] The second line has Action Message = "Change Qty.", Due Date = 20.02.2021, Original Quantity = 10, Quantity = 4.
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::"Resched. & Chg. Qty.", DemandDateValue[1], SupplyQuantityValue[3],
          Item."Maximum Order Quantity", SupplyDateValue[3], LocationBlue.Code, '');
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::"Change Qty.", DemandDateValue[1], SupplyQuantityValue[2],
          SupplyQuantityValue[2] - (Item."Maximum Order Quantity" - SupplyQuantityValue[3]), 0D, LocationBlue.Code, '');
        VerifyRequisitionLineCount(2);
    end;

    [Test]
    procedure DemandFourSuppliesWithMaxOrderQtyFirstTwoSameDueDateLastTwoLessDueDate()
    var
        Item: Record Item;
        DemandDateValue: array[3] of Date;
        SupplyDateValue: array[5] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyType: array[5] of Option;
    begin
        // [FEATURE] [Maximum Order Quantity]
        // [SCENARIO 395054] Calculate regenerative plan for one demand and four supplies when "Maximum Order Quantity" is set, two supplies have Due Date = Demand's "Due Date", two supplies have "Due Date" < Demand's "Due Date".
        Initialize();

        // [GIVEN] Item with Replenishment System = "Prod. Order" and with Maximum Order Quantity = 10.
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1Y>', '<1Y>', true, 0, 0);
        UpdateItem(Item, Item.FieldNo("Maximum Order Quantity"), 10);
        CreateAndUpdateStockKeepingUnit(Item, LocationBlue.Code, Item."Replenishment System"::"Prod. Order");
        UpdateMaxOrderQtyOnSKU(Item."No.", LocationBlue.Code, 10);

        // [GIVEN] One demand with "Due Date" = 20.02.2021 and with Quantity = 40.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(20), 0D, 0D);
        CreateDemandQuantity(DemandQuantityValue, 40, 0, 0);
        CreateDemandOnLocation(DemandTypeOption::"Sales Order", DemandDateValue, DemandQuantityValue, Item."No.", 1, LocationBlue.Code);

        // [GIVEN] Four supplies, each has Quantity = 10.
        // [GIVEN] First two supplies have Due Date = 20.02.2021. The last two have Due Date = 15.02.2021 and 16.02.2021, which is less than demand's Due Date.
        CreateSupplyType(
          SupplyType, SupplyTypeOption::FirmPlanned, SupplyTypeOption::FirmPlanned,
          SupplyTypeOption::FirmPlanned, SupplyTypeOption::FirmPlanned, SupplyTypeOption::None);
        CreateSupplyDate(
          SupplyDateValue, GetRandomDateUsingWorkDate(20), GetRandomDateUsingWorkDate(20),
          GetRandomDateUsingWorkDate(15), GetRandomDateUsingWorkDate(16), 0D);
        CreateSupplyQuantity(SupplyQuantityValue, 10, 10, 10, 10, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, Item."No.", '', LocationBlue.Code);

        // [WHEN] Calculate Regenerative Plan.
        Item.SetRecFilter();
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));

        // [THEN] Two Requisition Lines are created. They have Action Message = "Reschedule", Original Due Date = 15.02.2021 / 16.02.2021, Due Date = 20.02.2021, Quantity = 10.
        VerifyRequisitionLineWithOriginalDueDate(
          Item."No.", RequisitionLine."Action Message"::Reschedule, SupplyDateValue[3],
          DemandDateValue[1], 0, SupplyQuantityValue[3], LocationBlue.Code);
        VerifyRequisitionLineWithOriginalDueDate(
          Item."No.", RequisitionLine."Action Message"::Reschedule, SupplyDateValue[4],
          DemandDateValue[1], 0, SupplyQuantityValue[4], LocationBlue.Code);
        VerifyRequisitionLineCount(2);
    end;

    [Test]
    procedure DemandFourSuppliesWithMaxOrderQtyFirstTwoSameDueDateLastTwoLessDueDateAndLastLessQty()
    var
        Item: Record Item;
        DemandDateValue: array[3] of Date;
        SupplyDateValue: array[5] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyType: array[5] of Option;
    begin
        // [FEATURE] [Maximum Order Quantity]
        // [SCENARIO 395054] Calculate regenerative plan for one demand and four supplies when "Maximum Order Quantity" is set, two supplies have Due Date = Demand's "Due Date", two supplies have "Due Date" < Demand's "Due Date", last one has Quantity < Maximum Order Quantity of SKU.
        Initialize();

        // [GIVEN] Item with Replenishment System = "Prod. Order" and with Maximum Order Quantity = 10. Lot Accumulation Period = ''.
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1Y>', '', true, 0, 0);
        UpdateItem(Item, Item.FieldNo("Maximum Order Quantity"), 10);
        CreateAndUpdateStockKeepingUnit(Item, LocationBlue.Code, Item."Replenishment System"::"Prod. Order");
        UpdateMaxOrderQtyOnSKU(Item."No.", LocationBlue.Code, 10);

        // [GIVEN] One demand with "Due Date" = 20.02.2021 and with Quantity = 34.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(20), 0D, 0D);
        CreateDemandQuantity(DemandQuantityValue, 34, 0, 0);
        CreateDemandOnLocation(DemandTypeOption::"Sales Order", DemandDateValue, DemandQuantityValue, Item."No.", 1, LocationBlue.Code);

        // [GIVEN] Four supplies, first three have Quantity = 10, the forth one has Quantity = 4.
        // [GIVEN] First two supplies have Due Date = 20.02.2021. The last two have Due Date = 15.02.2021 and 16.02.2021, which is less than demand's Due Date.
        CreateSupplyType(
          SupplyType, SupplyTypeOption::FirmPlanned, SupplyTypeOption::FirmPlanned,
          SupplyTypeOption::FirmPlanned, SupplyTypeOption::FirmPlanned, SupplyTypeOption::None);
        CreateSupplyDate(
          SupplyDateValue, GetRandomDateUsingWorkDate(20), GetRandomDateUsingWorkDate(20),
          GetRandomDateUsingWorkDate(15), GetRandomDateUsingWorkDate(16), 0D);
        CreateSupplyQuantity(SupplyQuantityValue, 10, 10, 10, 4, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, Item."No.", '', LocationBlue.Code);

        // [WHEN] Calculate Regenerative Plan.
        Item.SetRecFilter();
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));

        // [THEN] Two Requisition Lines are created. The first line has Action Message = "Reschedule", Original Due Date = 15.02.2021, Due Date = 20.02.2021, Quantity = 10.
        // [THEN] The second line has Action Message = "Reschedule", Original Due Date = 16.02.2021, Due Date = 20.02.2021, Quantity = 4.
        VerifyRequisitionLineWithOriginalDueDate(
          Item."No.", RequisitionLine."Action Message"::Reschedule, SupplyDateValue[3],
          DemandDateValue[1], 0, SupplyQuantityValue[3], LocationBlue.Code);
        VerifyRequisitionLineWithOriginalDueDate(
          Item."No.", RequisitionLine."Action Message"::Reschedule, SupplyDateValue[4],
          DemandDateValue[1], 0, SupplyQuantityValue[4], LocationBlue.Code);
        VerifyRequisitionLineCount(2);
    end;

    [Test]
    procedure ThreeDemandsThreeSuppliesWithMaxOrderQtyFirstSameDueDateLastTwoLessDueDate()
    var
        Item: Record Item;
        DemandDateValue: array[3] of Date;
        SupplyDateValue: array[5] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyType: array[5] of Option;
    begin
        // [FEATURE] [Maximum Order Quantity]
        // [SCENARIO 395054] Calculate regenerative plan for three demands and three supplies when "Maximum Order Quantity" is set, one supply has Due Date = Demand's "Due Date", two have "Due Date" < Demand's "Due Date".
        Initialize();

        // [GIVEN] Item with Replenishment System = "Prod. Order" and with Maximum Order Quantity = 10. Lot Accumulation Period = ''.
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1Y>', '', true, 0, 0);
        UpdateItem(Item, Item.FieldNo("Maximum Order Quantity"), 10);
        CreateAndUpdateStockKeepingUnit(Item, LocationBlue.Code, Item."Replenishment System"::"Prod. Order");
        UpdateMaxOrderQtyOnSKU(Item."No.", LocationBlue.Code, 10);

        // [GIVEN] Three demands with "Due Date" = 20.02.2021, 16.02.2021, 18.02.2021 and each with Quantity = 10.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(20), GetRandomDateUsingWorkDate(16), GetRandomDateUsingWorkDate(18));
        CreateDemandQuantity(DemandQuantityValue, 10, 10, 10);
        CreateDemandOnLocation(DemandTypeOption::"Sales Order", DemandDateValue, DemandQuantityValue, Item."No.", 3, LocationBlue.Code);

        // [GIVEN] Three supplies, each has Quantity = 10.
        // [GIVEN] First supply has Due Date = 20.02.2021 (= demand's Due Date). The last two have Due Date = 12.02.2021 and 14.02.2021 (< demand's Due Date).
        CreateSupplyType(
          SupplyType, SupplyTypeOption::FirmPlanned, SupplyTypeOption::FirmPlanned,
          SupplyTypeOption::FirmPlanned, SupplyTypeOption::None, SupplyTypeOption::None);
        CreateSupplyDate(
          SupplyDateValue, GetRandomDateUsingWorkDate(20), GetRandomDateUsingWorkDate(12),
          GetRandomDateUsingWorkDate(14), 0D, 0D);
        CreateSupplyQuantity(SupplyQuantityValue, 10, 10, 10, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, Item."No.", '', LocationBlue.Code);

        // [WHEN] Calculate Regenerative Plan.
        Item.SetRecFilter();
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));

        // [THEN] Two Requisition Lines are created. They have Action Message = "Reschedule", Original Due Date = 12.02.2021 / 14.02.2021, Due Date = 16.02.2021 / 18.02.2021, Quantity = 10.
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::Reschedule, DemandDateValue[2],
          0, SupplyQuantityValue[2], SupplyDateValue[2], LocationBlue.Code, '');
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::Reschedule, DemandDateValue[3],
          0, SupplyQuantityValue[3], SupplyDateValue[3], LocationBlue.Code, '');
        VerifyRequisitionLineCount(2);
    end;

    [Test]
    procedure ThreeDemandsThreeSuppliesWithMaxOrderQtyFirstSameDueDateLastTwoLessDueDateAndLessQty()
    var
        Item: Record Item;
        DemandDateValue: array[3] of Date;
        SupplyDateValue: array[5] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyType: array[5] of Option;
    begin
        // [FEATURE] [Maximum Order Quantity]
        // [SCENARIO 395054] Calculate regenerative plan for three demands and three supplies when "Maximum Order Quantity" is set, one supply has Due Date = Demand's "Due Date", two have "Due Date" < Demand's "Due Date", last one has Quantity < Maximum Order Quantity of SKU.
        Initialize();

        // [GIVEN] Item with Replenishment System = "Prod. Order" and with Maximum Order Quantity = 10. Lot Accumulation Period = ''.
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1Y>', '', true, 0, 0);
        UpdateItem(Item, Item.FieldNo("Maximum Order Quantity"), 10);
        CreateAndUpdateStockKeepingUnit(Item, LocationBlue.Code, Item."Replenishment System"::"Prod. Order");
        UpdateMaxOrderQtyOnSKU(Item."No.", LocationBlue.Code, 10);

        // [GIVEN] Three demands with "Due Date" = 20.02.2021, 16.02.2021, 18.02.2021; first two have Quantity = 10, the last one has Quantity = 4.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(20), GetRandomDateUsingWorkDate(16), GetRandomDateUsingWorkDate(18));
        CreateDemandQuantity(DemandQuantityValue, 10, 10, 4);
        CreateDemandOnLocation(DemandTypeOption::"Sales Order", DemandDateValue, DemandQuantityValue, Item."No.", 3, LocationBlue.Code);

        // [GIVEN] Three supplies, first two have Quantity = 10, the third one has Quantity = 4.
        // [GIVEN] First supply has Due Date = 20.02.2021 (= demand's Due Date). The last two have Due Date = 12.02.2021 and 14.02.2021 (< demand's Due Date).
        CreateSupplyType(
          SupplyType, SupplyTypeOption::FirmPlanned, SupplyTypeOption::FirmPlanned,
          SupplyTypeOption::FirmPlanned, SupplyTypeOption::None, SupplyTypeOption::None);
        CreateSupplyDate(
          SupplyDateValue, GetRandomDateUsingWorkDate(20), GetRandomDateUsingWorkDate(12),
          GetRandomDateUsingWorkDate(14), 0D, 0D);
        CreateSupplyQuantity(SupplyQuantityValue, 10, 10, 4, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, Item."No.", '', LocationBlue.Code);

        // [WHEN] Calculate Regenerative Plan.
        Item.SetRecFilter();
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));

        // [THEN] Two Requisition Lines are created. They have Action Message = "Reschedule", Original Due Date = 12.02.2021 / 14.02.2021, Due Date = 16.02.2021 / 18.02.2021, Quantity = 10 and 4.
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::Reschedule, DemandDateValue[2],
          0, SupplyQuantityValue[2], SupplyDateValue[2], LocationBlue.Code, '');
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::Reschedule, DemandDateValue[3],
          0, SupplyQuantityValue[3], SupplyDateValue[3], LocationBlue.Code, '');
        VerifyRequisitionLineCount(2);
    end;

    [Test]
    procedure ThreeDemandsThreeSuppliesWithMinMaxOrderQtyLotAccumPeriodSetLessQtyFirstSameDueDate()
    var
        Item: Record Item;
        DemandDateValue: array[3] of Date;
        SupplyDateValue: array[5] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyType: array[5] of Option;
    begin
        // [FEATURE] [Maximum Order Quantity] [Minimum Order Quantity]
        // [SCENARIO 386848] Calculate regenerative plan for three demands and three supplies when Minimum / Maximum Order Quantity and Lot Accumulation Period are set, demands' Quantity < Minimum Order Quantity of SKU, supplies' Due Date = Due Date of first demand.
        Initialize();

        // [GIVEN] Item with Replenishment System = "Prod. Order" and with Maximum Order Quantity = Minimum Order Quantity = 14. Lot Accumulation Period = 1Y.
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1Y>', '<1Y>', true, 0, 0);
        UpdateItem(Item, Item.FieldNo("Maximum Order Quantity"), 14);
        UpdateItem(Item, Item.FieldNo("Minimum Order Quantity"), 14);
        CreateAndUpdateStockKeepingUnit(Item, LocationBlue.Code, Item."Replenishment System"::"Prod. Order");
        UpdateMinOrderQtyOnSKU(Item."No.", LocationBlue.Code, 14);
        UpdateMaxOrderQtyOnSKU(Item."No.", LocationBlue.Code, 14);

        // [GIVEN] Three demands with "Due Date" = 20.02.2021, 16.02.2021, 18.02.2021; all three have Quantity = 10.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(20), GetRandomDateUsingWorkDate(16), GetRandomDateUsingWorkDate(18));
        CreateDemandQuantity(DemandQuantityValue, 10, 10, 10);
        CreateDemandOnLocation(DemandTypeOption::"Sales Order", DemandDateValue, DemandQuantityValue, Item."No.", 3, LocationBlue.Code);

        // [GIVEN] Three supplies with Quantity = 14 and Due Date = 16.02.2021.
        CreateSupplyType(
          SupplyType, SupplyTypeOption::FirmPlanned, SupplyTypeOption::FirmPlanned,
          SupplyTypeOption::FirmPlanned, SupplyTypeOption::None, SupplyTypeOption::None);
        CreateSupplyDate(
          SupplyDateValue, GetRandomDateUsingWorkDate(16), GetRandomDateUsingWorkDate(16), GetRandomDateUsingWorkDate(16), 0D, 0D);
        CreateSupplyQuantity(SupplyQuantityValue, 14, 14, 14, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, Item."No.", '', LocationBlue.Code);

        // [WHEN] Calculate Regenerative Plan.
        Item.SetRecFilter();
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));

        // [THEN] Requisition Lines are not created.
        VerifyRequisitionLineCount(0);
    end;

    [Test]
    procedure ThreeDemandsThreeSuppliesWithMinMaxOrderQtyLotAccumPeriodNotSetLessQtyFirstSameDueLessQty()
    var
        Item: Record Item;
        DemandDateValue: array[3] of Date;
        SupplyDateValue: array[5] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyType: array[5] of Option;
    begin
        // [FEATURE] [Maximum Order Quantity] [Minimum Order Quantity]
        // [SCENARIO 386848] Calculate regenerative plan for three demands and three supplies when Minimum / Maximum Order Quantity are set, Lot Accumulation Period = '', demands' Quantity < Minimum Order Quantity of SKU, supplies' Due Date = Due Date of first demand.
        Initialize();

        // [GIVEN] Item with Replenishment System = "Prod. Order" and with Maximum Order Quantity = Minimum Order Quantity = 14. Lot Accumulation Period = ''.
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1Y>', '', true, 0, 0);
        UpdateItem(Item, Item.FieldNo("Maximum Order Quantity"), 14);
        UpdateItem(Item, Item.FieldNo("Minimum Order Quantity"), 14);
        CreateAndUpdateStockKeepingUnit(Item, LocationBlue.Code, Item."Replenishment System"::"Prod. Order");
        UpdateMinOrderQtyOnSKU(Item."No.", LocationBlue.Code, 14);
        UpdateMaxOrderQtyOnSKU(Item."No.", LocationBlue.Code, 14);

        // [GIVEN] Three demands with "Due Date" = 20.02.2021, 16.02.2021, 18.02.2021; all three have Quantity = 10.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(20), GetRandomDateUsingWorkDate(16), GetRandomDateUsingWorkDate(18));
        CreateDemandQuantity(DemandQuantityValue, 10, 10, 10);
        CreateDemandOnLocation(DemandTypeOption::"Sales Order", DemandDateValue, DemandQuantityValue, Item."No.", 3, LocationBlue.Code);

        // [GIVEN] Three supplies with Quantity = 14 and Due Date = 16.02.2021.
        CreateSupplyType(
          SupplyType, SupplyTypeOption::FirmPlanned, SupplyTypeOption::FirmPlanned,
          SupplyTypeOption::FirmPlanned, SupplyTypeOption::None, SupplyTypeOption::None);
        CreateSupplyDate(
          SupplyDateValue, GetRandomDateUsingWorkDate(16), GetRandomDateUsingWorkDate(16), GetRandomDateUsingWorkDate(16), 0D, 0D);
        CreateSupplyQuantity(SupplyQuantityValue, 14, 14, 14, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, Item."No.", '', LocationBlue.Code);

        // [WHEN] Calculate Regenerative Plan.
        Item.SetRecFilter();
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));

        // [THEN] Two Requisition Lines are created. They have Action Message = "Reschedule", Original Due Date = 16.02.2021, Due Date = 18.02.2021 / 20.02.2021, Quantity = 14.
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::Reschedule, DemandDateValue[1],
          0, SupplyQuantityValue[1], SupplyDateValue[1], LocationBlue.Code, '');
        VerifyRequisitionLine(
          Item."No.", RequisitionLine."Action Message"::Reschedule, DemandDateValue[3],
          0, SupplyQuantityValue[3], SupplyDateValue[3], LocationBlue.Code, '');
        VerifyRequisitionLineCount(2);
    end;

    [Test]
    procedure ThreeDemandsThreeSuppliesWithMaxOrderQtyLotAccumPeriodSetSameQtySameDueDate()
    var
        Item: Record Item;
        DemandDateValue: array[3] of Date;
        SupplyDateValue: array[5] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyType: array[5] of Option;
    begin
        // [FEATURE] [Maximum Order Quantity]
        // [SCENARIO 386848] Calculate regenerative plan for three demands and three supplies when Maximum Order Quantity and Lot Accumulation Period are set, supplies' Due Date = demands' "Due Date" (different dates), all demands have Quantity < Maximum Order Quantity of SKU.
        Initialize();

        // [GIVEN] Item with Replenishment System = "Prod. Order" and with Maximum Order Quantity = 12. Lot Accumulation Period = 1Y.
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1Y>', '<1Y>', true, 0, 0);
        UpdateItem(Item, Item.FieldNo("Maximum Order Quantity"), 12);
        CreateAndUpdateStockKeepingUnit(Item, LocationBlue.Code, Item."Replenishment System"::"Prod. Order");
        UpdateMaxOrderQtyOnSKU(Item."No.", LocationBlue.Code, 12);

        // [GIVEN] Three demands with "Due Date" = 20.02.2021, 16.02.2021, 18.02.2021; first two have Quantity = 10, the last one has Quantity = 6.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(20), GetRandomDateUsingWorkDate(16), GetRandomDateUsingWorkDate(18));
        CreateDemandQuantity(DemandQuantityValue, 10, 10, 6);
        CreateDemandOnLocation(DemandTypeOption::"Sales Order", DemandDateValue, DemandQuantityValue, Item."No.", 3, LocationBlue.Code);

        // [GIVEN] Three supplies, first two have Quantity = 10, the third one has Quantity = 6.
        // [GIVEN] Supplies have Due Date = 20.02.2021, 16.02.2021, 18.02.2021 (= demand's Due Date).
        CreateSupplyType(
          SupplyType, SupplyTypeOption::FirmPlanned, SupplyTypeOption::FirmPlanned,
          SupplyTypeOption::FirmPlanned, SupplyTypeOption::None, SupplyTypeOption::None);
        CreateSupplyDate(
          SupplyDateValue, GetRandomDateUsingWorkDate(20), GetRandomDateUsingWorkDate(16), GetRandomDateUsingWorkDate(18), 0D, 0D);
        CreateSupplyQuantity(SupplyQuantityValue, 10, 10, 6, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, Item."No.", '', LocationBlue.Code);

        // [WHEN] Calculate Regenerative Plan.
        Item.SetRecFilter();
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));

        // [THEN] Three Requisition Lines are created. The first line has Action Message = "Change Qty.", Due Date = 16.02.2021, Original Quantity = 10, Quantity = 12.
        // [THEN] The second line has Action Message = "Resched. & Chg. Qty.", Original Due Date = 18.02.2021, Due Date = 16.02.2021, Original Quantity = 6, Quantity = 12.
        // [THEN] The third line has Action Message = "Resched. & Chg. Qty.", Original Due Date = 20.02.2021, Due Date = 16.02.2021, Original Quantity = 10, Quantity = 2.
        VerifyRequisitionLineWithOriginalDueDate(
          Item."No.", RequisitionLine."Action Message"::"Change Qty.", 0D, DemandDateValue[2],
          SupplyQuantityValue[2], Item."Maximum Order Quantity", LocationBlue.Code);
        VerifyRequisitionLineWithOriginalDueDate(
          Item."No.", RequisitionLine."Action Message"::"Resched. & Chg. Qty.", SupplyDateValue[3], DemandDateValue[2],
          SupplyQuantityValue[3], Item."Maximum Order Quantity", LocationBlue.Code);
        VerifyRequisitionLineWithOriginalDueDate(
          Item."No.", RequisitionLine."Action Message"::"Resched. & Chg. Qty.", SupplyDateValue[1], DemandDateValue[2],
          SupplyQuantityValue[1], SupplyQuantityValue[1] - (2 * Item."Maximum Order Quantity" - SupplyQuantityValue[2] - SupplyQuantityValue[3]), LocationBlue.Code);
        VerifyRequisitionLineCount(3);
    end;

    [Test]
    procedure ThreeDemandsThreeSuppliesWithMaxOrderQtyLotAccumPeriodNotSetSameQtySameDueDate()
    var
        Item: Record Item;
        DemandDateValue: array[3] of Date;
        SupplyDateValue: array[5] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyQuantityValue: array[5] of Decimal;
        SupplyType: array[5] of Option;
    begin
        // [FEATURE] [Maximum Order Quantity]
        // [SCENARIO 386848] Calculate regenerative plan for three demands and three supplies when Maximum Order Quantity is set, Lot Accumulation Period = '', supplies' Due Date = demands' "Due Date" (different dates), all demands have Quantity < Maximum Order Quantity of SKU.
        Initialize();

        // [GIVEN] Item with Replenishment System = "Prod. Order" and with Maximum Order Quantity = 12. Lot Accumulation Period = ''.
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", '<1Y>', '', true, 0, 0);
        UpdateItem(Item, Item.FieldNo("Maximum Order Quantity"), 12);
        CreateAndUpdateStockKeepingUnit(Item, LocationBlue.Code, Item."Replenishment System"::"Prod. Order");
        UpdateMaxOrderQtyOnSKU(Item."No.", LocationBlue.Code, 12);

        // [GIVEN] Three demands with "Due Date" = 20.02.2021, 16.02.2021, 18.02.2021; first two have Quantity = 10, the last one has Quantity = 6.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(20), GetRandomDateUsingWorkDate(16), GetRandomDateUsingWorkDate(18));
        CreateDemandQuantity(DemandQuantityValue, 10, 10, 6);
        CreateDemandOnLocation(DemandTypeOption::"Sales Order", DemandDateValue, DemandQuantityValue, Item."No.", 3, LocationBlue.Code);

        // [GIVEN] Three supplies, first two have Quantity = 10, the third one has Quantity = 6.
        // [GIVEN] Supplies have Due Date = 20.02.2021, 16.02.2021, 18.02.2021 (= demand's Due Date).
        CreateSupplyType(
          SupplyType, SupplyTypeOption::FirmPlanned, SupplyTypeOption::FirmPlanned,
          SupplyTypeOption::FirmPlanned, SupplyTypeOption::None, SupplyTypeOption::None);
        CreateSupplyDate(
          SupplyDateValue, GetRandomDateUsingWorkDate(20), GetRandomDateUsingWorkDate(16), GetRandomDateUsingWorkDate(18), 0D, 0D);
        CreateSupplyQuantity(SupplyQuantityValue, 10, 10, 6, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, Item."No.", '', LocationBlue.Code);

        // [WHEN] Calculate Regenerative Plan.
        Item.SetRecFilter();
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));

        // [THEN] Requisition Lines are not created.
        VerifyRequisitionLineCount(0);
    end;

    [Test]
    procedure ItemAvailByLocationDoesNotIncludeDropShipment()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        ItemCard: TestPage "Item Card";
        ItemAvailabilityByLocation: TestPage "Item Availability by Location";
    begin
        // [FEATURE] [Item Availability] [Location] [Drop Shipment]
        // [SCENARIO 407018] Item Availability by Location page does not show drop shipment in either "Gross Requirements" or "Planned Receipts".
        Initialize();

        CreateItem(Item, Item."Replenishment System"::Purchase);

        // [GIVEN] Sales order for drop shipment.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", LibraryRandom.RandInt(10), LocationBlue.Code, WorkDate());
        SalesLine.Validate("Drop Shipment", true);
        SalesLine.Modify(true);

        CreateRequisitionWorksheetName(RequisitionWkshName, RequisitionWkshName."Template Type"::"Req.");
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);

        // [WHEN] Open requisition worksheet and invoke "Drop Shipment" -> "Get Sales Orders"
        LibraryPlanning.GetSalesOrders(SalesLine, RequisitionLine, 0);

        // [THEN] Requisition line is created.
        // [THEN] "Drop Shipment" = TRUE on the requisition line.
        FindRequisitionLine(RequisitionLine, Item."No.");
        RequisitionLine.TestField("Drop Shipment");
        Assert.IsTrue(RequisitionLine.IsDropShipment(), '');

        // [THEN] "Gross Requirement" = 0 and "Planned Receipts" = 0 on Item Availability by Location page.
        ItemCard.OpenView();
        ItemCard.FILTER.SetFilter("No.", Item."No.");
        ItemAvailabilityByLocation.Trap();
        ItemCard.Location.Invoke();

        ItemAvailabilityByLocation.FILTER.SetFilter("No.", Item."No.");
        ItemAvailabilityByLocation.ItemAvailLocLines.FILTER.SetFilter(Code, LocationBlue.Code);
        ItemAvailabilityByLocation.ItemAvailLocLines.First();
        ItemAvailabilityByLocation.ItemAvailLocLines.GrossRequirement.AssertEquals(0);
        ItemAvailabilityByLocation.ItemAvailLocLines.PlannedOrderRcpt.AssertEquals(0);
        ItemAvailabilityByLocation.ItemAvailLocLines.ProjAvailableBalance.AssertEquals(0);
        ItemAvailabilityByLocation.Close();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Supply Planning");
        ClearGlobals();
        LibraryVariableStorage.Clear();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Supply Planning");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        NoSeriesSetup();
        LocationSetup();
        ItemJournalSetup();
        OutputJournalSetup();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Supply Planning");
    end;

    local procedure ClearGlobals()
    var
        ReservationEntry: Record "Reservation Entry";
        UntrackedPlanningElement: Record "Untracked Planning Element";
    begin
        ReservationEntry.DeleteAll();
        UntrackedPlanningElement.DeleteAll();
        RequisitionLine.Reset();
        RequisitionLine.DeleteAll();

        Clear(GlobalSalesHeader);
        Clear(GlobalPurchaseHeader);
        Clear(GlobalProductionOrder);
        Clear(GlobalItemNo);
    end;

    local procedure NoSeriesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Posted Receipt Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Customer Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Validate("Posted Shipment Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure LocationSetup()
    begin
        CreateAndUpdateLocation(LocationBlue);  // Location: Blue.
        CreateAndUpdateLocation(LocationRed);  // Location: Red.
    end;

    local procedure ItemJournalSetup()
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
    end;

    local procedure OutputJournalSetup()
    begin
        LibraryInventory.SelectItemJournalTemplateName(OutputItemJournalTemplate, OutputItemJournalTemplate.Type::Output);
        LibraryInventory.SelectItemJournalBatchName(
          OutputItemJournalBatch, OutputItemJournalTemplate.Type, OutputItemJournalTemplate.Name);
        OutputItemJournalBatch.Modify(true);
    end;

    local procedure CalculatePlanningWorksheetWithBaseCalendarAndItemVendor(ReorderingPolicy: Enum "Reordering Policy")
    var
        Item: Record Item;
        ItemVendor: Record "Item Vendor";
        RequisitionLine: Record "Requisition Line";
        InventorySetup: Record "Inventory Setup";
        SalesHeader: Record "Sales Header";
        DefaultSafetyLeadTime: Integer;
    begin
        Initialize();
        InventorySetup.Get();

        // Setup: Create Base Calendar, set Sunday as working day, other days as non-working day, create Vendor, bind the calendar
        // to the Vendor, create an Item. Create a Sales Order, set the shipment date of the sales line as Saturday,
        // set InventorySetup."Default Safety Lead Time" to random value. Create Item Vendor.
        DefaultSafetyLeadTime := LibraryRandom.RandInt(10);
        SetupDemandWithBaseCalendar(Item, SalesHeader, CalcDate('<WD6>', GetRandomDateUsingWorkDate(30)), DefaultSafetyLeadTime);
        UpdateItemReorderingPolicy(Item, ReorderingPolicy);
        CreateItemVendor(ItemVendor, Item, LibraryRandom.RandInt(5));
        UpdateItemVendorNo(Item, ''); // Clear the Vendor No. on Item Card.

        // Calculate Regenerative Plan on Planning worksheet.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));
        FindRequisitionLine(RequisitionLine, Item."No.");

        // Exercise: Fill in the Vendor No., then Due Date or Ending Date will be recalculated.
        UpdateVendorNoOnRequisitionLine(RequisitionLine, ItemVendor."Vendor No.");

        // Verify: Verify calculating Ending Date from Due Date or calculating Due Date from Ending Date doesn't need to consider Vendor's calendar.
        RequisitionLine.TestField("Ending Date", CalcDate('<-' + Format(DefaultSafetyLeadTime) + 'D>', RequisitionLine."Due Date"));

        // Tear Down.
        UpdateDefaultSafetyLeadTimeOnInventorySetup(InventorySetup."Default Safety Lead Time");
    end;

    local procedure ReCalcPlngWkshAfterDemandChanged(Quantity: Decimal)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        PlanningLinesCountBeforeCarryOut: Integer;
    begin
        // Setup: Create and update Item. Create Sales Order.
        Initialize();
        CreateAndUpdateOrderItem(Item);
        CreateSalesOrder(SalesHeader, Item."No.", LibraryRandom.RandIntInRange(20, 30), WorkDate());

        // Calculate Plan and Carry Out Action Message in Planning Worksheet.
        // Update Quantity and Shipment Date for Sales.
        CalcRegenPlanAndCarryOutActionMessagePlan(Item, PlanningLinesCountBeforeCarryOut);
        UpdateQuantityForSales(SalesLine, SalesHeader."No.", Quantity);
        UpdateShipmentDateForSales(
          SalesLine, SalesHeader."No.", GetRandomDateUsingWorkDate(LibraryRandom.RandInt(20)));

        // Exercise: Re-calc Plan for Planning Worksheet, then delete the Requisition Line.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), SalesLine."Shipment Date");
        FindRequisitionLine(RequisitionLine, Item."No.");
        RequisitionLine.Delete();

        // Verify: Verify the Excepted Receipt Date in Reservation Entry.
        VerifyExpectedReceiptDateOnReservationEntry(Item."No.", WorkDate());
    end;

    local procedure CreateAndUpdateLocation(var Location: Record Location)
    begin
        LibraryWarehouse.CreateLocation(Location);
    end;

    local procedure CreateAssemblyDemand(var AssemblyHeader: Record "Assembly Header"; DueDate: Date; ParentItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        ComponentItem: Record Item;
    begin
        LibraryInventory.CreateItem(ComponentItem);
        CreateAssemblyOrder(AssemblyHeader, DueDate, ComponentItem."No.", ParentItemNo, Quantity, LocationCode);
    end;

    local procedure CreateAssemblySupply(var AssemblyHeader: Record "Assembly Header"; DueDate: Date; ParentItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        ComponentItem: Record Item;
    begin
        LibraryInventory.CreateItem(ComponentItem);
        CreateAssemblyOrder(AssemblyHeader, DueDate, ParentItemNo, ComponentItem."No.", Quantity, LocationCode);
    end;

    local procedure CreateAssemblyOrder(var AssemblyHeader: Record "Assembly Header"; DueDate: Date; ParentItemNo: Code[20]; ComponentItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        AssemblyLine: Record "Assembly Line";
    begin
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, DueDate, ParentItemNo, LocationCode, Quantity, '');
        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, ComponentItemNo, '', Quantity, 1, '');
    end;

    local procedure CreateAssemblyOrderFromPlanningWorksheet(var AssemblyHeader: Record "Assembly Header"; Item: Record Item)
    var
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SalesQuantity: Decimal;
        DummyCount: Integer;
    begin
        SalesQuantity := Item."Maximum Inventory" + Item."Reorder Point" + 1;
        CreateDemandDate(DemandDateValue, WorkDate(), 0D, 0D); // Shipment Date is WORKDATE.
        CreateDemandQuantity(DemandQuantityValue, SalesQuantity, 0, 0);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 1); // Number of Sales Order : 1.

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate() + 30); // Dates based on WORKDATE. Planning Period - 1 Month, covers Sales shipments.
        AcceptActionMessageAndCarryOutActionMessagePlan(Item."No.", DummyCount);
        AssemblyHeader.SetRange("Item No.", Item."No.");
        AssemblyHeader.FindFirst();
    end;

    local procedure CreateLFLItem(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System"; ReschedulingPeriod: Text[30]; LotAccumulationPeriod: Text[30]; IncludeInventory: Boolean; SafetyStockQty: Decimal; DampenerQty: Decimal)
    begin
        CreateItem(Item, ReplenishmentSystem);

        // Lot-for-Lot Planning parameters.
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Validate("Include Inventory", IncludeInventory);
        UpdatePlanningPeriodForItem(Item, ReschedulingPeriod, LotAccumulationPeriod);
        Item.Validate("Dampener Quantity", DampenerQty);
        Item.Validate("Rounding Precision", 0.01);
        UpdateItem(Item, Item.FieldNo("Safety Stock Quantity"), SafetyStockQty);
    end;

    local procedure CreateLFLItemWithDemandAndSupply(var Item: Record Item; var DemandDateValue: array[5] of Date; var DemandQuantityValue: array[5] of Decimal; var SupplyQuantityValue: array[5] of Decimal; NewDemandType: Option; NewSupplyType: Option; LocationCode: Code[10])
    var
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase,"Sales Return";
        SupplyDateValue: array[5] of Date;
    begin
        CreateLFLItem(Item, Item."Replenishment System"::Purchase, '<1M>', '<1M>', true, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.

        // Create Demand - Supply Scenario with Random Value taking Global Variable for Sales and Purchase, with reservation if required.
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(30), GetRandomDateUsingWorkDate(50), 0D);  // Dates based on WORKDATE.
        CreateDemandQuantity(DemandQuantityValue, LibraryRandom.RandDec(10, 2) + 60, LibraryRandom.RandDec(10, 2) + 180, 0);
        CreateDemandOnLocation(NewDemandType, DemandDateValue, DemandQuantityValue, Item."No.", 2, LocationCode);  // Number of Sales Order.

        CreateSupplyType(SupplyType, NewSupplyType, SupplyType::None, SupplyType::None, SupplyType::None, SupplyType::None);
        CreateSupplyDate(SupplyDateValue, GetRandomDateUsingWorkDate(5), 0D, 0D, 0D, 0D);  // Dates based on WORKDATE.
        CreateSupplyQuantity(SupplyQuantityValue, LibraryRandom.RandDec(10, 2) + 40, 0, 0, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, Item."No.", Item."No.", LocationCode);
        UpdatePlanningFlexibilityOnSupplyDoc(NewSupplyType);
    end;

    local procedure CreateLFLItemWithSettingPlanningTab(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Validate("Include Inventory", true);
        // Only Setup Include Inventory as TRUE if set value in Safety Stock Quantity.
        Item.Validate("Safety Stock Quantity", LibraryRandom.RandInt(100));
        Item.Validate("Minimum Order Quantity", LibraryRandom.RandInt(100));
        Item.Validate("Maximum Order Quantity", LibraryRandom.RandIntInRange(100, 200));
        Item.Validate("Order Multiple", LibraryRandom.RandInt(100));
        Item.Modify(true);
    end;

    local procedure CreateLFLItemWithVendorNo(var Item: Record Item; VendorNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Validate("Vendor No.", VendorNo);
        Item.Modify(true);
    end;

    local procedure CreateLFLItemWithMaximumAndMinimumOrderQuantity(var Item: Record Item; Quantity: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Validate("Minimum Order Quantity", Quantity);
        Item.Validate("Maximum Order Quantity", Quantity);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Modify(true);
    end;

    local procedure CreateItemWithVendorNoReorderingPolicy(var Item: Record Item): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Fixed Reorder Qty.");
        Item.Validate("Vendor No.", Vendor."No.");
        Item.Validate("Replenishment System", Item."Replenishment System"::Purchase);
        Item.Validate("Reorder Quantity", LibraryRandom.RandInt(1000));
        UpdateItemLeadTimeCalculation(Item, LibraryRandom.RandIntInRange(10, 15));
        Item.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateProductionItemWithLFLComponent(var ProdItemNo: Code[20]; var CompItemNo: Code[20])
    var
        ProdItem: Record Item;
        CompItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateLFLItem(CompItem, CompItem."Replenishment System"::Purchase, '1Y', '', false, 0, 100);
        CreateItem(ProdItem, ProdItem."Replenishment System"::"Prod. Order");
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ProdItem."Base Unit of Measure", CompItem."No.");
        UpdateItem(ProdItem, ProdItem.FieldNo("Production BOM No."), ProductionBOMHeader."No.");
        UpdateItem(ProdItem, ProdItem.FieldNo("Reordering Policy"), ProdItem."Reordering Policy"::Order);

        ProdItemNo := ProdItem."No.";
        CompItemNo := CompItem."No.";
    end;

    local procedure CreateFRQItem(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System"; ReorderQuantity: Decimal; ReorderPoint: Decimal; SafetyStockQty: Decimal)
    begin
        CreateItem(Item, ReplenishmentSystem);

        // Fixed Reorder Qty. Planning parameters.
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Fixed Reorder Qty.");
        Item.Validate("Reorder Quantity", ReorderQuantity);
        Item.Validate("Reorder Point", ReorderPoint);
        UpdateItem(Item, Item.FieldNo("Safety Stock Quantity"), SafetyStockQty);
    end;

    local procedure CreateAndUpdateOrderItem(var Item: Record Item)
    begin
        CreateItem(Item, Item."Replenishment System"::Purchase);
        UpdateItemReorderingPolicy(Item, Item."Reordering Policy"::Order);
        UpdateItemVendorNo(Item, LibraryPurchase.CreateVendorNo());
    end;

    local procedure CreateMQItem(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System"; MaximumInventory: Decimal; ReorderPoint: Decimal; SafetyStockQty: Decimal)
    begin
        CreateItem(Item, ReplenishmentSystem);

        // Maximum Qty. Planning parameters.
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Maximum Qty.");
        Item.Validate("Maximum Inventory", MaximumInventory);
        Item.Validate("Reorder Point", ReorderPoint);
        UpdateItem(Item, Item.FieldNo("Safety Stock Quantity"), SafetyStockQty);
    end;

    local procedure CreateMQItemAssembly(var Item: Record Item)
    var
        ChildItem: Record Item;
    begin
        CreateMQItem(
          Item, Item."Replenishment System"::Assembly, LibraryRandom.RandInt(10) + 50, LibraryRandom.RandInt(10) + 20, 0);  // Item Maximum Inventory greater than Item Reorder Point. Safety Stock is Zero.

        LibraryInventory.CreateItem(ChildItem);
        CreateBOMComponent(Item."No.", ChildItem."No.", LibraryRandom.RandInt(3));
    end;

    local procedure CreateItem(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System")
    begin
        LibraryInventory.CreateItem(Item);
        UpdateItem(Item, Item.FieldNo("Replenishment System"), ReplenishmentSystem);
    end;

    local procedure CreateItemWithPlanningParametersAndBOM(var Item: Record Item; var Item2: Record Item; ReschedulingPeriod: Text[30]; LotAccumulationPeriod: Text[30]; IncludeInventory: Boolean)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateLFLItem(Item, Item."Replenishment System"::"Prod. Order", ReschedulingPeriod, LotAccumulationPeriod, IncludeInventory, 0, 0);
        CreateChildItemSetup(Item2, Item."Base Unit of Measure", ProductionBOMHeader, ReschedulingPeriod);
        UpdateItem(Item, Item.FieldNo("Production BOM No."), ProductionBOMHeader."No.");
    end;

    local procedure CreateItemVendor(var ItemVendor: Record "Item Vendor"; Item: Record Item; LeadTimeCalculation: Integer)
    begin
        LibraryInventory.CreateItemVendor(ItemVendor, Item."Vendor No.", Item."No.");
        Evaluate(ItemVendor."Lead Time Calculation", Format(LeadTimeCalculation) + 'D');
        ItemVendor.Modify(true);
    end;

    local procedure CreateAndUpdateFRQItem(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System"; ReorderQuantity: Decimal; ReorderPoint: Decimal; SafetyStockQty: Decimal; OrderMultiple: Decimal)
    begin
        CreateFRQItem(Item, ReplenishmentSystem, ReorderQuantity, ReorderPoint, SafetyStockQty);
        Item.Validate("Order Multiple", OrderMultiple);
        Item.Modify(true);
    end;

    local procedure CreateAndUpdateStockKeepingUnit(var Item: Record Item; LocationCode: Code[10]; ReplenishmentSystem: Enum "Replenishment System")
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        Item.SetRange("Location Filter", LocationCode);
        LibraryInventory.CreateStockKeepingUnit(Item, "SKU Creation Method"::Location, false, false); // Use False for Item InInventory Only and Replace Previous SKUs fields.
        StockkeepingUnit.Get(LocationCode, Item."No.", ''); // Use blank value for Variant Code.
        StockkeepingUnit.Validate("Replenishment System", ReplenishmentSystem);
        StockkeepingUnit.Modify(true);
    end;

    local procedure CreateProductionOrderDemand(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Quantity: Decimal; DueDate: Date; LocationCode: Code[10])
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", Quantity, DueDate, LocationCode);
        CreateProdOrderComponent(ProductionOrder, ItemNo);
    end;

    local procedure CreateTransferDemand(var TransferHeader: Record "Transfer Header"; ItemNo: Code[20]; Quantity: Decimal; ShipmentDate: Date; FromLocationCode: Code[10])
    var
        ToLocation: Record Location;
    begin
        LibraryWarehouse.CreateLocation(ToLocation);
        CreateTransferOrder(TransferHeader, ItemNo, Quantity, ShipmentDate, FromLocationCode, ToLocation.Code);
    end;

    local procedure CreateTransferSupply(var TransferHeader: Record "Transfer Header"; ItemNo: Code[20]; Quantity: Decimal; ShipmentDate: Date; ToLocationCode: Code[10])
    var
        FromLocation: Record Location;
    begin
        LibraryWarehouse.CreateLocation(FromLocation);
        CreateTransferOrder(TransferHeader, ItemNo, Quantity, ShipmentDate, FromLocation.Code, ToLocationCode);
    end;

    local procedure GetOrderNo(ItemNo: Code[20]): Code[20]
    var
        RequisitionLine: Record "Requisition Line";
    begin
        FilterRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.FindFirst();
        exit(RequisitionLine."Ref. Order No.");
    end;

    local procedure UpdatePlanningPeriodForItem(var Item: Record Item; ReschedulingPeriod: Text[30]; LotAccumulationPeriod: Text[30])
    var
        ReschedulingPeriod2: DateFormula;
        LotAccumulationPeriod2: DateFormula;
    begin
        Evaluate(ReschedulingPeriod2, ReschedulingPeriod);
        Evaluate(LotAccumulationPeriod2, LotAccumulationPeriod);
        Item.Validate("Rescheduling Period", ReschedulingPeriod2);
        Item.Validate("Lot Accumulation Period", LotAccumulationPeriod2);
    end;

    local procedure UpdateItem(var Item: Record Item; FieldNo: Integer; Value: Variant)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        // Update Item based on Field and its corresponding value.
        RecRef.GetTable(Item);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Validate(Value);
        RecRef.SetTable(Item);
        Item.Modify(true);
    end;

    local procedure UpdateItemInventory(ItemNo: Code[20]; ItemQty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, ItemQty);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure UpdateItemReorderingPolicy(var Item: Record Item; ReorderingPolicy: Enum "Reordering Policy")
    begin
        Item.Validate("Reordering Policy", ReorderingPolicy);
        if ReorderingPolicy = Item."Reordering Policy"::"Maximum Qty." then
            Item.Validate("Maximum Inventory", LibraryRandom.RandInt(50));
        Item.Modify(true);
    end;

    local procedure UpdateItemLeadTimeCalculation(var Item: Record Item; LeadTimeCalculation: Integer)
    begin
        Evaluate(Item."Lead Time Calculation", Format(LeadTimeCalculation) + 'D');
        Item.Modify(true);
    end;

    local procedure ChangeQuantityAndAcceptActionMessageInRequisitionLine(ItemNo: Code[20]; MaximumOrderQuantity: Decimal)
    begin
        SelectRequisitionLineForActionMessage(RequisitionLine, ItemNo, RequisitionLine."Action Message"::New, WorkDate());
        RequisitionLine.Validate(Quantity, MaximumOrderQuantity);
        RequisitionLine.Validate("Accept Action Message", true);
        RequisitionLine.Modify(true);
    end;

    local procedure UpdateItemVendorNo(var Item: Record Item; VendorNo: Code[20])
    begin
        Item.Validate("Vendor No.", VendorNo);
        Item.Modify(true);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; ItemNo: Code[20]; Quantity: Decimal; ExpectedReceiptDate: Date; LocationCode: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, '');
        PurchaseHeader.Validate("Location Code", LocationCode);
        PurchaseHeader.Modify(true);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, ItemNo, Quantity, ExpectedReceiptDate);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal; ExpectedReceiptDate: Date)
    begin
        CreatePurchaseOrderOnLocation(PurchaseHeader, ItemNo, Quantity, ExpectedReceiptDate, '');
    end;

    local procedure CreatePurchaseOrderWithNewVendor(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal; ExpectedReceiptDate: Date)
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, ItemNo, Quantity, ExpectedReceiptDate);
    end;

    local procedure CreatePurchaseOrderOnLocation(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal; ExpectedReceiptDate: Date; LocationCode: Code[10])
    begin
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, ItemNo, Quantity, ExpectedReceiptDate, LocationCode);
    end;

    local procedure CreatePurchaseLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Quantity: Decimal; ExpectedReceiptDate: Date)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Expected Receipt Date", ExpectedReceiptDate);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; ItemNo: Code[20]; Quantity: Decimal; ShipmentDate: Date; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, '');
        SalesHeader.Validate(
          "External Document No.", LibraryUtility.GenerateRandomCode(SalesHeader.FieldNo("External Document No."), DATABASE::"Sales Header"));
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify(true);
        CreateSalesLine(SalesHeader, SalesLine, ItemNo, Quantity, ShipmentDate);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; ShipmentDate: Date)
    begin
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, ItemNo, Quantity, ShipmentDate, '');
    end;

    local procedure CreateSalesOrderOnLocation(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; ShipmentDate: Date; LocationCode: Code[10])
    begin
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, ItemNo, Quantity, ShipmentDate, LocationCode);
    end;

    local procedure CreateSalesReturnOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; ShipmentDate: Date; LocationCode: Code[10])
    begin
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Return Order", ItemNo, Quantity, ShipmentDate, LocationCode);
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Decimal; ShipmentDate: Date)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Shipment Date", ShipmentDate);
        SalesLine.Modify(true);
    end;

    local procedure CreateTransferOrder(var TransferHeader: Record "Transfer Header"; ItemNo: Code[20]; Quantity: Decimal; ShipmentDate: Date; FromLocationCode: Code[10]; ToLocationCode: Code[10])
    var
        InTransitLocation: Record Location;
        TransferRoute: Record "Transfer Route";
        TransferLine: Record "Transfer Line";
    begin
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        LibraryWarehouse.CreateTransferRoute(TransferRoute, FromLocationCode, ToLocationCode);

        LibraryInventory.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, InTransitLocation.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        TransferLine.Validate("Shipment Date", ShipmentDate);
        TransferLine.Modify(true);
    end;

    local procedure CreateSalesOrderAndConnectedOrder(var SalesHeader: Record "Sales Header"; Item: Record Item; Quantity: Decimal)
    var
        DummyCount: Integer;
    begin
        CreateSalesOrder(SalesHeader, Item."No.", Quantity, WorkDate());
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), LibraryRandom.RandDate(7));
        AcceptActionMessageAndCarryOutActionMessagePlan(Item."No.", DummyCount);
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; ItemNo: Code[20]; Quantity: Decimal; DueDate: Date; LocationCode: Code[10])
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
        if Status = ProductionOrder.Status::Released then
            UpdateDueDateOnReleasedProdOrder(ProductionOrder."No.", DueDate)
        else
            UpdateDueDateOnFirmPlannedProdOrder(ProductionOrder."No.", DueDate);
        Commit();  // Need to COMMIT the changes in page before fetching Production Order again in the next step.

        // Retrieve the updated instance of Production Order and Refresh.
        ProductionOrder.Get(Status, ProductionOrder."No.");
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure UpdateDueDateOnFirmPlannedProdOrder(ProdOrderNo: Code[20]; DueDate: Date)
    var
        FirmPlannedProdOrder: TestPage "Firm Planned Prod. Order";
    begin
        FirmPlannedProdOrder.OpenEdit();
        FirmPlannedProdOrder.FILTER.SetFilter("No.", ProdOrderNo);
        FirmPlannedProdOrder."Due Date".SetValue(DueDate);
        FirmPlannedProdOrder.OK().Invoke();
    end;

    local procedure UpdateDueDateOnReleasedProdOrder(ProdOrderNo: Code[20]; DueDate: Date)
    var
        ReleasedProductionOrder: TestPage "Released Production Order";
    begin
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.FILTER.SetFilter("No.", ProdOrderNo);
        ReleasedProductionOrder."Due Date".SetValue(DueDate);
        ReleasedProductionOrder.OK().Invoke();
    end;

    local procedure ReserveFromSupply(ReservationSource: Option)
    begin
        case ReservationSource of
            SupplyTypeOption::Purchase:
                ReservePurchaseLine(GlobalPurchaseHeader[1]."No.");
            SupplyTypeOption::Released:
                ReserveProdOrderLine(GlobalProductionOrder[1]."No.");
            SupplyTypeOption::"Sales Return":
                ReserveSalesReturnLine(GlobalSalesHeader[1]."No.");
            SupplyTypeOption::Transfer:
                ReserveTransferLine(GlobalTransferHeader[1]."No.");
            SupplyTypeOption::Assembly:
                ReserveAssemblyHeader(GlobalAssemblyHeader[1]."No.");
        end;
    end;

    local procedure ReserveFromDemand(ReservationSource: Option)
    begin
        case ReservationSource of
            DemandTypeOption::"Sales Order":
                ReserveSalesLine(GlobalSalesHeader[1]."No.");
            DemandTypeOption::"Purchase Return":
                ReservePurchaseReturnLine(GlobalPurchaseHeader[2]."No.");
            DemandTypeOption::"Released Prod. Order":
                ReserveProdOrderComponent(GlobalProductionOrder[1]."No.");
            DemandTypeOption::"Transfer Order":
                ReserveTransferLine(GlobalTransferHeader[1]."No.");
        end;
    end;

    local procedure ReserveAssemblyHeader(No: Code[20])
    var
        AssemblyOrder: TestPage "Assembly Order";
    begin
        AssemblyOrder.OpenEdit();
        AssemblyOrder.FILTER.SetFilter("No.", No);
        AssemblyOrder."&Reserve".Invoke();
    end;

    local procedure ReserveProdOrderComponent(No: Code[20])
    var
        ReleasedProdOrder: TestPage "Released Production Order";
        ProdOrderComponents: TestPage "Prod. Order Components";
    begin
        ProdOrderComponents.Trap();
        ReleasedProdOrder.OpenEdit();
        ReleasedProdOrder.FILTER.SetFilter("No.", No);
        ReleasedProdOrder.ProdOrderLines.Components.Invoke(); // Components

        ProdOrderComponents.Reserve.Invoke();
    end;

    local procedure ReserveProdOrderLine(No: Code[20])
    var
        ReleasedProdOrder: TestPage "Released Production Order";
    begin
        ReleasedProdOrder.OpenEdit();
        ReleasedProdOrder.FILTER.SetFilter("No.", No);
        ReleasedProdOrder.ProdOrderLines."&Reserve".Invoke();  // Open the Page - Reservation on Handler ReservationPageHandler.
    end;

    local procedure ReservePurchaseLine(No: Code[20])
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", No);
        PurchaseOrder.PurchLines.Reserve.Invoke();  // Open the Page - Reservation on Handler ReservationPageHandler.
    end;

    local procedure ReservePurchaseReturnLine(No: Code[20])
    var
        PurchReturnOrder: TestPage "Purchase Return Order";
    begin
        PurchReturnOrder.OpenEdit();
        PurchReturnOrder.FILTER.SetFilter("No.", No);
        PurchReturnOrder.PurchLines.Reserve.Invoke();  // Open the Page - Reservation on Handler ReservationPageHandler.
    end;

    local procedure ReserveSalesLine(No: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", No);
        SalesOrder.SalesLines.Reserve.Invoke();  // Open the Page - Reservation on Handler ReservationPageHandler.
    end;

    local procedure ReserveSalesReturnLine(No: Code[20])
    var
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.FILTER.SetFilter("No.", No);
        SalesReturnOrder.SalesLines.Reserve.Invoke();  // Open the Page - Reservation on Handler ReservationPageHandler.
    end;

    local procedure ReserveTransferLine(No: Code[20])
    var
        TransferOrder: TestPage "Transfer Order";
    begin
        TransferOrder.OpenEdit();
        TransferOrder.FILTER.SetFilter("No.", No);
        TransferOrder.TransferLines.Reserve.Invoke();  // Open the Page - Reservation on Handler ReservationPageHandler.
    end;

    local procedure UpdatePlanningFlexibilityOnSupplyDoc(SupplyType: Option)
    var
        ProductionOrder: Record "Production Order";
    begin
        case SupplyType of
            SupplyTypeOption::Released:
                UpdatePlanningFlexibilityOnProduction(GlobalProductionOrder[1]."No.", ProductionOrder.Status::Released);
            SupplyTypeOption::FirmPlanned:
                UpdatePlanningFlexibilityOnProduction(GlobalProductionOrder[1]."No.", ProductionOrder.Status::"Firm Planned");
            SupplyTypeOption::Purchase:
                UpdatePlanningFlexibilityOnPurchase(GlobalPurchaseHeader[1]."No.");
            SupplyTypeOption::Transfer:
                UpdatePlanningFlexibilityOnTransfer(GlobalTransferHeader[1]."No.");
            SupplyTypeOption::Assembly:
                UpdatePlanningFlexibilityOnAssembly(GlobalAssemblyHeader[1]."No.");
        end;
    end;

    local procedure UpdatePlanningFlexibilityOnAssembly(DocumentNo: Code[20])
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, DocumentNo);
        AssemblyHeader.Validate("Planning Flexibility", AssemblyHeader."Planning Flexibility"::None);
        AssemblyHeader.Modify(true);
    end;

    local procedure UpdatePlanningFlexibilityOnPurchase(DocumentNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        SelectPurchaseLine(PurchaseLine, DocumentNo);
        PurchaseLine.Validate("Planning Flexibility", PurchaseLine."Planning Flexibility"::None);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdatePlanningFlexibilityOnProduction(ProdOrderNo: Code[20]; Status: Enum "Production Order Status")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        SelectProdOrderLine(ProdOrderLine, ProdOrderNo, Status);
        ProdOrderLine.Validate("Planning Flexibility", ProdOrderLine."Planning Flexibility"::None);
        ProdOrderLine.Modify(true);
    end;

    local procedure UpdatePlanningFlexibilityOnRequisition(ItemNo: Code[20])
    var
        RequisitionLine2: Record "Requisition Line";
    begin
        FilterRequisitionLine(RequisitionLine2, ItemNo);
        RequisitionLine2.FindFirst();
        RequisitionLine2.Validate("Planning Flexibility", RequisitionLine2."Planning Flexibility"::None);
        RequisitionLine2.Modify(true);
    end;

    local procedure UpdatePlanningFlexibilityOnTransfer(DocumentNo: Code[20])
    var
        TransferLine: Record "Transfer Line";
    begin
        SelectTransferLine(TransferLine, DocumentNo);
        TransferLine.Validate("Planning Flexibility", TransferLine."Planning Flexibility"::None);
        TransferLine.Modify(true);
    end;

    local procedure SelectProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProdOrderNo: Code[20]; Status: Enum "Production Order Status")
    begin
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.SetRange(Status, Status);
        ProdOrderLine.FindFirst();
    end;

    local procedure SelectSalesLine(var SalesLine: Record "Sales Line"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst();
    end;

    local procedure SelectPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindFirst();
    end;

    local procedure SelectTransferLine(var TransferLine: Record "Transfer Line"; DocumentNo: Code[20])
    begin
        TransferLine.SetRange("Document No.", DocumentNo);
        TransferLine.FindFirst();
    end;

    local procedure GetRandomDateUsingWorkDate(Day: Integer) NewDate: Date
    begin
        // Calculating a New Date relative to work date for different supply and demands.
        NewDate := CalcDate('<' + Format(Day) + 'D>', WorkDate());
    end;

    local procedure GeneralSetupForPlanningWorksheet(var Item: Record Item; var ProductionForecastEntry: array[3] of Record "Production Forecast Entry"; var RequisitionWkshName: Record "Requisition Wksh. Name"; CreatePurchOrder: Boolean; AddItemInventory: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreateLFLItemWithSettingPlanningTab(Item); // Create Lot For Lot Item with planning parameters.
        GlobalItemNo := Item."No."; // Assign Global Variable for CalculatePlanPlanWkshRequestPageHandler.
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", true); // Create Demand on Production Forecast

        // create a Purchase Line and let its Expected Receipt Date between the date of first demand(WORKDATE) and the date of second demand(WORKDATE+16D).
        if CreatePurchOrder then
            CreatePurchaseOrder(
              PurchaseHeader, Item."No.", LibraryRandom.RandInt(100), GetRandomDateUsingWorkDate(LibraryRandom.RandInt(15)));
        if AddItemInventory then
            UpdateItemInventory(Item."No.", LibraryRandom.RandInt(100));
        RequisitionWkshName.FindFirst();
    end;

    local procedure AcceptActionMessage(ItemNo: Code[20]; var PlanningLinesCountBeforeCarryOut: Integer)
    var
        VendorNo: Code[20];
    begin
        FilterRequisitionLine(RequisitionLine, ItemNo);
        PlanningLinesCountBeforeCarryOut := RequisitionLine.Count();
        VendorNo := LibraryPurchase.CreateVendorNo();
        RequisitionLine.FindSet();
        repeat
            if RequisitionLine."Ref. Order Type" = RequisitionLine."Ref. Order Type"::Purchase then
                RequisitionLine.Validate("Vendor No.", VendorNo);
            RequisitionLine.Validate("Accept Action Message", true);
            RequisitionLine.Modify(true);
        until RequisitionLine.Next() = 0;
    end;

    local procedure UpdateVariantOnSales(var SalesLine: Record "Sales Line"; SalesHeaderNo: Code[20]; VariantCode: Code[10])
    begin
        SelectSalesLine(SalesLine, SalesHeaderNo);
        SalesLine.Validate("Variant Code", VariantCode);
        SalesLine.Modify(true);
    end;

    local procedure UpdateVariantOnProduction(ProductionOrderNo: Code[20]; Status: Enum "Production Order Status"; VariantCode: Code[10])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        SelectProdOrderLine(ProdOrderLine, ProductionOrderNo, Status);
        ProdOrderLine.Validate("Variant Code", VariantCode);
        ProdOrderLine.Modify(true);
    end;

    local procedure SelectRequisitionLineForActionMessage(var RequisitionLine2: Record "Requisition Line"; No: Code[20]; ActionMessage: Enum "Action Message Type"; DueDate: Date)
    begin
        FilterRequisitionLine(RequisitionLine2, No);
        RequisitionLine2.SetRange("Action Message", ActionMessage);
        RequisitionLine2.SetRange("Due Date", DueDate);
        RequisitionLine2.FindFirst();
    end;

    local procedure DeleteFirstRequisitionLine(LineNo: Integer)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("Line No.", LineNo);
        RequisitionLine.FindFirst();
        RequisitionLine.Delete(true);
    end;

    local procedure FindClosestWorkingDay(ServiceMgtSetup: Record "Service Mgt. Setup"; BaseDate: Date): Date
    var
        CustomizedCalendarChange: Record "Customized Calendar Change";
        CalendarManagement: Codeunit "Calendar Management";
    begin
        CalendarManagement.SetSource(ServiceMgtSetup, CustomizedCalendarChange);
        CustomizedCalendarChange.Date := BaseDate + 1;
        repeat
            CustomizedCalendarChange.Date -= 1;
            CalendarManagement.CheckDateStatus(CustomizedCalendarChange);
        until not CustomizedCalendarChange.Nonworking;
        exit(CustomizedCalendarChange.Date);
    end;

    local procedure FilterRequisitionLine(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20])
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", ItemNo);
    end;

    local procedure FindRequisitionLine(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20])
    begin
        FilterRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.FindFirst();
    end;

    local procedure UpdateVendorNoOnRequisitionLine(var RequisitionLine: Record "Requisition Line"; VendorNo: Code[20])
    begin
        RequisitionLine.Validate("Vendor No.", VendorNo);
        RequisitionLine.Modify(true);
    end;

    local procedure CreateAndPostOutputJournal(ItemNo: Code[20]; ProductionOrderNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.ClearItemJournal(OutputItemJournalTemplate, OutputItemJournalBatch);
        LibraryManufacturing.CreateOutputJournal(
          ItemJournalLine, OutputItemJournalTemplate, OutputItemJournalBatch, ItemNo, ProductionOrderNo);
        ItemJournalLine.Validate("Output Quantity", LibraryRandom.RandDec(5, 2));  // Used Random Value for Output Quantity.
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(OutputItemJournalTemplate.Name, OutputItemJournalBatch.Name);
    end;

    local procedure CreateAndCertifyProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; BaseUnitOfMeasure: Code[10]; No: Code[20])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, BaseUnitOfMeasure);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, No, 1);  // Use One for Quantity per.
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateBOMComponent(ParentItemNo: Code[20]; ChildItemNo: Code[20]; QuantityPer: Decimal)
    var
        BOMComponent: Record "BOM Component";
    begin
        LibraryInventory.CreateBOMComponent(BOMComponent, ParentItemNo, BOMComponent.Type::Item, ChildItemNo, QuantityPer, '');
    end;

    local procedure CreateProdOrderComponent(ProductionOrder: Record "Production Order"; ItemNo: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        SelectProdOrderLine(ProdOrderLine, ProductionOrder."No.", ProductionOrder.Status);
        LibraryManufacturing.CreateProductionOrderComponent(
          ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", ProdOrderLine."Line No.");
        ProdOrderComponent.Validate("Item No.", ItemNo);
        ProdOrderComponent.Validate("Quantity per", 1);  // Used One for Quantity per.
        ProdOrderComponent.Modify(true);
    end;

    local procedure AcceptActionMessageAndCarryOutActionMessagePlan(ItemNo: Code[20]; var PlanningLinesCountBeforeCarryOut: Integer)
    var
        RequisitionLine2: Record "Requisition Line";
    begin
        AcceptActionMessage(ItemNo, PlanningLinesCountBeforeCarryOut);
        FilterRequisitionLine(RequisitionLine2, ItemNo);
        RequisitionLine2.FindFirst();
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine2);
    end;

    local procedure CreateChildItemSetup(var Item: Record Item; BaseUnitOfMeasure: Code[10]; var ProductionBOMHeader: Record "Production BOM Header"; ReschedulingPeriod: Text[30])
    begin
        CreateLFLItem(Item, Item."Replenishment System"::Purchase, ReschedulingPeriod, ReschedulingPeriod, true, 0, 0);  // Rescheduling Period, Lot Accumulation Period, Include Inventory, Safety Stock, Dampener Qty.
        CreateAndCertifyProductionBOM(ProductionBOMHeader, BaseUnitOfMeasure, Item."No.");
    end;

    local procedure CreateDemandDate(var DemandDateValue: array[3] of Date; DemandDate: Date; DemandDate2: Date; DemandDate3: Date)
    begin
        // Taking an Array of 3 for Demand document Dates.
        DemandDateValue[1] := DemandDate;
        DemandDateValue[2] := DemandDate2;
        DemandDateValue[3] := DemandDate3;
    end;

    local procedure CreateDemandQuantity(var DemandQuantityValue: array[3] of Decimal; DemandQuantity: Decimal; DemandQuantity2: Decimal; DemandQuantity3: Decimal)
    begin
        // Taking an Array of 3 for Demand document Quantity.
        DemandQuantityValue[1] := DemandQuantity;
        DemandQuantityValue[2] := DemandQuantity2;
        DemandQuantityValue[3] := DemandQuantity3;
    end;

    local procedure CreateSupplyDate(var SupplyDateValue: array[5] of Date; SupplyDate: Date; SupplyDate2: Date; SupplyDate3: Date; SupplyDate4: Date; SupplyDate5: Date)
    begin
        // Taking an Array of 5 for Supply document Dates.
        SupplyDateValue[1] := SupplyDate;
        SupplyDateValue[2] := SupplyDate2;
        SupplyDateValue[3] := SupplyDate3;
        SupplyDateValue[4] := SupplyDate4;
        SupplyDateValue[5] := SupplyDate5;
    end;

    local procedure CreateSupplyQuantity(var SupplyQuantityValue: array[5] of Decimal; SupplyQuantity: Decimal; SupplyQuantity2: Decimal; SupplyQuantity3: Decimal; SupplyQuantity4: Decimal; SupplyQuantity5: Decimal)
    begin
        // Taking an Array of 5 for Supply document Quantity.
        SupplyQuantityValue[1] := SupplyQuantity;
        SupplyQuantityValue[2] := SupplyQuantity2;
        SupplyQuantityValue[3] := SupplyQuantity3;
        SupplyQuantityValue[4] := SupplyQuantity4;
        SupplyQuantityValue[5] := SupplyQuantity5;
    end;

    local procedure CreateSupply(SupplyDateValue: array[5] of Date; SupplyQuantityValue: array[5] of Decimal; SupplyType: array[5] of Option; ItemNo: Code[20]; ItemNo2: Code[20]; LocationCode: Code[10])
    var
        "Count": Integer;
        PurchaseCounter: Integer;
    begin
        // Create Production Order and Purchase Order.
        PurchaseCounter := 0;
        for Count := 1 to 5 do   // Using Array size. Value important.
            case SupplyType[Count] of
                SupplyTypeOption::Released:
                    CreateAndRefreshProductionOrder(
                      GlobalProductionOrder[Count], GlobalProductionOrder[1].Status::Released, ItemNo, SupplyQuantityValue[Count],
                      SupplyDateValue[Count], LocationCode);  // Dates based on WORKDATE.
                SupplyTypeOption::FirmPlanned:
                    CreateAndRefreshProductionOrder(
                      GlobalProductionOrder[Count], GlobalProductionOrder[1].Status::"Firm Planned", ItemNo, SupplyQuantityValue[Count],
                      SupplyDateValue[Count], LocationCode);  // Dates based on WORKDATE.
                SupplyTypeOption::Purchase:
                    begin
                        PurchaseCounter += 1;
                        CreatePurchaseOrderOnLocation(
                          GlobalPurchaseHeader[PurchaseCounter], ItemNo2, SupplyQuantityValue[Count], SupplyDateValue[Count], LocationCode);  // Dates based on WORKDATE.
                    end;
                SupplyTypeOption::"Sales Return":
                    CreateSalesReturnOrder(GlobalSalesHeader[Count], ItemNo2, SupplyQuantityValue[Count], SupplyDateValue[Count], LocationCode);
                SupplyTypeOption::Transfer:
                    CreateTransferSupply(GlobalTransferHeader[Count], ItemNo2, SupplyQuantityValue[Count], SupplyDateValue[Count], LocationCode);
                SupplyTypeOption::Assembly:
                    CreateAssemblySupply(GlobalAssemblyHeader[Count], SupplyDateValue[Count], ItemNo, SupplyQuantityValue[Count], LocationCode);
            end;
    end;

    local procedure CreateDemand(DemandDateValue: array[3] of Date; DemandQuantityValue: array[3] of Decimal; ItemNo: Code[20]; NoOfSalesOrder: Integer)
    var
        DemandType: Option "Sales Order","Transfer Order","Released Prod. Order";
    begin
        CreateDemandOnLocation(DemandType::"Sales Order", DemandDateValue, DemandQuantityValue, ItemNo, NoOfSalesOrder, '');
    end;

    local procedure CreateDemandOnLocation(DemandType: Option; DemandDateValue: array[3] of Date; DemandQuantityValue: array[3] of Decimal; ItemNo: Code[20]; NoOfDemandOrders: Integer; LocationCode: Code[10])
    var
        "Count": Integer;
    begin
        for Count := 1 to NoOfDemandOrders do
            case DemandType of
                DemandTypeOption::"Sales Order":
                    CreateSalesOrderOnLocation(GlobalSalesHeader[Count], ItemNo, DemandQuantityValue[Count], DemandDateValue[Count], LocationCode);
                DemandTypeOption::"Transfer Order":
                    CreateTransferDemand(GlobalTransferHeader[Count], ItemNo, DemandQuantityValue[Count], DemandDateValue[Count], LocationCode);
                DemandTypeOption::"Released Prod. Order":
                    CreateProductionOrderDemand(
                      GlobalProductionOrder[Count], ItemNo, DemandQuantityValue[Count], DemandDateValue[Count], LocationCode);
                DemandTypeOption::Assembly:
                    CreateAssemblyDemand(GlobalAssemblyHeader[Count], DemandDateValue[Count], ItemNo, DemandQuantityValue[Count], LocationCode);
                DemandTypeOption::"Purchase Return":
                    CreatePurchaseDocument(
                      GlobalPurchaseHeader[Count], GlobalPurchaseHeader[Count]."Document Type"::"Return Order",
                      ItemNo, DemandQuantityValue[Count], DemandDateValue[Count], LocationCode);
            end;
    end;

    local procedure CreatePurchOrdWithFRQItem(var Item: Record Item; var PurchaseHeaderNo: Code[20])
    var
        InventorySetup: Record "Inventory Setup";
        PurchaseHeader: Record "Purchase Header";
    begin
        CreateFRQItem(
          Item, Item."Replenishment System"::Purchase, LibraryRandom.RandDecInRange(11, 20, 2),
          LibraryRandom.RandDec(10, 2), 0); // Safety Stock must be 0 to repro bug in TFS346168
        Evaluate(Item."Lead Time Calculation", '<' + Format(LibraryRandom.RandInt(5)) + 'M>');
        Item.Modify(true);
        InventorySetup.Get();
        CreatePurchaseOrderWithNewVendor(
          PurchaseHeader, Item."No.", LibraryRandom.RandDecInRange(11, 20, 2),
          CalcDate(InventorySetup."Default Safety Lead Time", CalcDate(Item."Lead Time Calculation", WorkDate())));
        PurchaseHeaderNo := PurchaseHeader."No.";
    end;

    local procedure CreatePurchOrdWithFRQItemAndCalculatePlan(var Item: Record Item; var OrderDate: Date; UseLocation: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeaderNo: Code[20];
    begin
        CreatePurchOrdWithFRQItem(Item, PurchaseHeaderNo);
        if UseLocation then
            UpdateLocationForPurchase(PurchaseLine, PurchaseHeaderNo, LocationBlue.Code)
        else
            SelectPurchaseLine(PurchaseLine, PurchaseHeaderNo);
        CalculatePlanForReqWksh(Item, PurchaseLine."Order Date", PurchaseLine."Order Date");
        OrderDate := PurchaseLine."Order Date";
    end;

    local procedure CreatePlanWkshLineWithChangeQtyActionMessage(var Item: Record Item; ItemReplenishmentSystem: Enum "Replenishment System"; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateLFLItem(Item, ItemReplenishmentSystem, '<1W>', '<1W>', true, 0, 0);
        CreateSalesOrderAndConnectedOrder(SalesHeader, Item, Quantity);
        UpdateQuantityForSales(SalesLine, SalesHeader."No.", Quantity + LibraryRandom.RandInt(5));
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), LibraryRandom.RandDate(60));
    end;

    local procedure SetupItemCardScenario(var ItemCard: TestPage "Item Card")
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);

        ItemCard.OpenView();
        ItemCard.GotoRecord(Item);
    end;

    local procedure UpdateLocationForSales(DocumentNo: Code[20]; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
        ShipmentDate: Date;
    begin
        SelectSalesLine(SalesLine, DocumentNo);
        ShipmentDate := SalesLine."Shipment Date";
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Shipment Date", ShipmentDate);
        SalesLine.Modify(true);
    end;

    local procedure UpdateLocationForPurchase(var PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20]; LocationCode: Code[10])
    var
        ExpectedReceiptDate: Date;
    begin
        SelectPurchaseLine(PurchaseLine, DocumentNo);
        ExpectedReceiptDate := PurchaseLine."Expected Receipt Date";
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Expected Receipt Date", ExpectedReceiptDate);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateInventorySetup(DefaultDampenerPeriod: DateFormula)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Default Dampener Period", DefaultDampenerPeriod);
        InventorySetup.Modify(true);
    end;

    local procedure UpdateCompanyInformationBaseCalendarCode(BaseCalendarCode: Code[10]) OldBaseCalendarCode: Code[10]
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        OldBaseCalendarCode := CompanyInformation."Base Calendar Code";
        CompanyInformation.Validate("Base Calendar Code", BaseCalendarCode);
        CompanyInformation.Modify(true);
    end;

    local procedure UpdateVendorBaseCalendarCode(VendorNo: Code[20]; BaseCalendarCode: Code[10])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        Vendor.Validate("Base Calendar Code", BaseCalendarCode);
        Vendor.Modify(true);
    end;

    local procedure CreateRequisitionWorksheetName(var RequisitionWkshName: Record "Requisition Wksh. Name"; ReqWkshTemplateType: Enum "Req. Worksheet Template Type")
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplateType);
        ReqWkshTemplate.SetRange(Recurring, false);
        ReqWkshTemplate.FindFirst();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
    end;

    local procedure CalcRegenPlanForPlanWkshPage(var PlanningWorksheet: TestPage "Planning Worksheet"; Name: Code[10])
    begin
        Commit();
        OpenPlanningWorksheetPage(PlanningWorksheet, Name);
        PlanningWorksheet.CalculateRegenerativePlan.Invoke();  // Open report on Handler CalculatePlanPlanWkshRequestPageHandler.
        PlanningWorksheet.OK().Invoke();
    end;

    local procedure CalculatePlanForReqWksh(Item: Record Item; StartingDate: Date; EndingDate: Date)
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        CreateRequisitionWorksheetName(RequisitionWkshName, ReqWkshTemplate.Type::"Req.");
        LibraryPlanning.CalculatePlanForReqWksh(
          Item, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name, StartingDate, EndingDate);
    end;

    local procedure UpdateQuantityForSales(var SalesLine: Record "Sales Line"; DocumentNo: Code[20]; Quantity: Decimal)
    begin
        SelectSalesLine(SalesLine, DocumentNo);
        SalesLine.Validate(Quantity, Quantity);
        SalesLine.Modify(true);
    end;

    local procedure CalcRegenPlanAndCarryOutActionMessagePlan(Item: Record Item; var PlanningLinesCountBeforeCarryOut: Integer)
    begin
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), GetRandomDateUsingWorkDate(60));  // Dates based on WORKDATE.
        AcceptActionMessageAndCarryOutActionMessagePlan(Item."No.", PlanningLinesCountBeforeCarryOut);
    end;

    local procedure UpdateForecastOnInventorySetup(CurrentDemandForecast: Code[10]; UseForecastOnLocations: Boolean)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Current Demand Forecast", CurrentDemandForecast);
        InventorySetup.Validate("Use Forecast on Locations", UseForecastOnLocations);
        InventorySetup.Modify(true);
    end;

    local procedure ChangePeriodForItem(var Item: Record Item; ReschedulingPeriod: Text[30]; LotAccumulationPeriod: Text[30])
    begin
        Item.Get(Item."No.");
        UpdatePlanningPeriodForItem(Item, ReschedulingPeriod, LotAccumulationPeriod);
        Item.Modify(true);
    end;

    local procedure CreateProductionForecastSetup(var ProductionForecastEntry: array[3] of Record "Production Forecast Entry"; ItemNo: Code[20]; Multiple: Boolean)
    var
        ProductionForecastName: Record "Production Forecast Name";
    begin
        // Using Random Value and Dates based on WORKDATE.
        LibraryManufacturing.CreateProductionForecastName(ProductionForecastName);
        UpdateForecastOnInventorySetup(ProductionForecastName.Name, true);
        CreateAndUpdateProductionForecast(
          ProductionForecastEntry[1], ProductionForecastName.Name, WorkDate(), ItemNo, LibraryRandom.RandDec(5, 2) + 230);
        if Multiple then begin
            CreateAndUpdateProductionForecast(
              ProductionForecastEntry[2], ProductionForecastName.Name, GetRandomDateUsingWorkDate(16), ItemNo,
              LibraryRandom.RandDec(5, 2) + 250);
            CreateAndUpdateProductionForecast(
              ProductionForecastEntry[3], ProductionForecastName.Name, GetRandomDateUsingWorkDate(64), ItemNo,
              LibraryRandom.RandDec(5, 2) + 290);
        end;
    end;

    local procedure CreateAndUpdateProductionForecast(var ProductionForecastEntry: Record "Production Forecast Entry"; Name: Code[10]; Date: Date; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionForecastEntry(ProductionForecastEntry, Name, ItemNo, '', Date, false);
        ProductionForecastEntry.Validate("Forecast Quantity (Base)", Quantity);
        ProductionForecastEntry.Modify(true);
    end;

    local procedure UpdatePostingDateAndPostSalesOrder(var SalesHeader: Record "Sales Header"; PostingDate: Date)
    begin
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure OpenPlanningWorksheetPage(var PlanningWorksheet: TestPage "Planning Worksheet"; Name: Code[10])
    begin
        PlanningWorksheet.OpenEdit();
        PlanningWorksheet.CurrentWkshBatchName.SetValue(Name);
    end;

    local procedure CreateMultipleItemUnitOfMeasure(var ItemUnitOfMeasure: Record "Item Unit of Measure"; var ItemUnitOfMeasure2: Record "Item Unit of Measure"; ItemNo: Code[20])
    var
        UnitOfMeasure: Record "Unit of Measure";
        UnitOfMeasure2: Record "Unit of Measure";
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure2);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, UnitOfMeasure.Code, ItemNo, LibraryRandom.RandInt(5) + 10);  // Using Random Value.
        CreateItemUnitOfMeasure(ItemUnitOfMeasure2, UnitOfMeasure2.Code, ItemNo, LibraryRandom.RandInt(5) + 15);  // Using Random Value.
    end;

    local procedure CreateItemUnitOfMeasure(var ItemUnitOfMeasure: Record "Item Unit of Measure"; UnitOfMeasureCode: Code[10]; ItemNo: Code[20]; QtyPerUnitOfMeasure: Decimal)
    begin
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, ItemNo, UnitOfMeasureCode, QtyPerUnitOfMeasure);
    end;

    local procedure UpdateUnitOfMeasureForSales(DocumentNo: Code[20]; UnitOfMeasureCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        SelectSalesLine(SalesLine, DocumentNo);
        SalesLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        SalesLine.Modify(true);
    end;

    local procedure UpdateUnitOfMeasureForPurchase(DocumentNo: Code[20]; UnitOfMeasureCode: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        SelectPurchaseLine(PurchaseLine, DocumentNo);
        PurchaseLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateShipmentDateForSales(var SalesLine: Record "Sales Line"; DocumentNo: Code[20]; ShipmentDate: Date)
    begin
        SelectSalesLine(SalesLine, DocumentNo);
        SalesLine.Validate("Shipment Date", ShipmentDate);
        SalesLine.Modify(true);
    end;

    local procedure UpdateQuantityForPurchase(var PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20]; Quantity: Decimal)
    begin
        SelectPurchaseLine(PurchaseLine, DocumentNo);
        PurchaseLine.Validate(Quantity, Quantity);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdatePostingDateAndPostMultipleSalesOrder(var SalesHeader: Record "Sales Header"; var SalesHeader2: Record "Sales Header"; PostingDate: Date; PostingDate2: Date)
    begin
        UpdatePostingDateAndPostSalesOrder(SalesHeader, PostingDate);
        UpdatePostingDateAndPostSalesOrder(SalesHeader2, PostingDate2);
    end;

    local procedure UpdateDefaultSafetyLeadTimeOnInventorySetup(DefaultSafetyLeadTime: DateFormula)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Default Safety Lead Time", DefaultSafetyLeadTime);
        InventorySetup.Modify(true);
    end;

    local procedure UpdateMinOrderQtyOnSKU(ItemNo: Code[20]; LocationCode: Code[10]; MinOrderQty: Decimal)
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        StockkeepingUnit.Get(LocationCode, ItemNo, '');
        StockkeepingUnit.Validate("Minimum Order Quantity", MinOrderQty);
        StockkeepingUnit.Modify(true);
    end;

    local procedure UpdateMaxOrderQtyOnSKU(ItemNo: Code[20]; LocationCode: Code[10]; MaxOrderQty: Decimal)
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        StockkeepingUnit.Get(LocationCode, ItemNo, '');
        StockkeepingUnit.Validate("Maximum Order Quantity", MaxOrderQty);
        StockkeepingUnit.Modify(true);
    end;

    local procedure PostPositiveAdjustmentAndCreateSalesOrderWithThreeLines(Item: Record Item; PositiveAdjustmentQuantity: Decimal; MaximumOrderQuantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
    begin
        UpdateItemInventory(Item."No.", PositiveAdjustmentQuantity);
        CreateSalesOrder(SalesHeader, Item."No.", MaximumOrderQuantity, WorkDate());
        CreateSalesLine(SalesHeader, SalesLine[1], Item."No.", MaximumOrderQuantity, WorkDate());
        CreateSalesLine(SalesHeader, SalesLine[2], Item."No.", MaximumOrderQuantity, WorkDate());
    end;

    local procedure SelectDateWithSafetyLeadTime(DateValue: Date; SignFactor: Integer): Date
    var
        InventorySetup: Record "Inventory Setup";
    begin
        // Add Safety lead time to the required date and return the Date value.
        InventorySetup.Get();
        if SignFactor < 0 then
            exit(CalcDate('<' + '-' + Format(InventorySetup."Default Safety Lead Time") + '>', DateValue));
        exit(CalcDate('<' + Format(InventorySetup."Default Safety Lead Time") + '>', DateValue));
    end;

    local procedure SelectItemQuantity(Item: Record Item; FRQItem: Boolean) PlanningWorksheetQty: Decimal
    begin
        if FRQItem then
            PlanningWorksheetQty := Item."Reorder Quantity"
        else
            PlanningWorksheetQty := Item."Maximum Inventory";
    end;

    local procedure CreateReorderPointPolicyItem(var Item: Record Item; FRQItem: Boolean; Quantity: Decimal; ReorderPoint: Decimal; SafetyStockQty: Decimal)
    begin
        if FRQItem then
            CreateFRQItem(Item, Item."Replenishment System"::"Prod. Order", Quantity, ReorderPoint, SafetyStockQty)
        else
            CreateMQItem(Item, Item."Replenishment System"::"Prod. Order", Quantity, ReorderPoint, SafetyStockQty);
    end;

    local procedure CreateSupplyType(var SupplyTypeValue: array[5] of Option "None",Released,FirmPlanned,Purchase; SupplyType: Option; SupplyType2: Option; SupplyType3: Option; SupplyType4: Option; SupplyType5: Option)
    begin
        // Taking an Array of 5 for Supply document Type.
        SupplyTypeValue[1] := SupplyType;
        SupplyTypeValue[2] := SupplyType2;
        SupplyTypeValue[3] := SupplyType3;
        SupplyTypeValue[4] := SupplyType4;
        SupplyTypeValue[5] := SupplyType5;
    end;

    local procedure CreateBaseCalendarWithBaseCalendarChange(var BaseCalendar: Record "Base Calendar")
    var
        BaseCalendarChange: Record "Base Calendar Change";
        I: Integer;
    begin
        LibraryService.CreateBaseCalendar(BaseCalendar);
        for I := BaseCalendarChange.Day::Monday to BaseCalendarChange.Day::Saturday do
            LibraryInventory.CreateBaseCalendarChange(
              BaseCalendarChange, BaseCalendar.Code, BaseCalendarChange."Recurring System"::"Weekly Recurring", 0D, I);  // Use 0D for Date.
    end;

    local procedure CreateVendorWithBaseCalendarCode(var Vendor: Record Vendor; BaseCalendarCode: Code[10])
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Base Calendar Code", BaseCalendarCode);
        Vendor.Modify(true);
    end;

    local procedure FilterFirmPlannedProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ItemNo: Code[20])
    begin
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::"Firm Planned");
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst();
    end;

    local procedure SetupDemandWithBaseCalendar(var Item: Record Item; var SalesHeader: Record "Sales Header"; ShipmentDate: Date; SafetyLeadTime: Integer)
    var
        BaseCalendar: Record "Base Calendar";
        Vendor: Record Vendor;
        DefaultSafetyLeadTime: DateFormula;
    begin
        Evaluate(DefaultSafetyLeadTime, '<' + Format(SafetyLeadTime) + 'D>');
        UpdateDefaultSafetyLeadTimeOnInventorySetup(DefaultSafetyLeadTime);

        CreateBaseCalendarWithBaseCalendarChange(BaseCalendar);
        CreateVendorWithBaseCalendarCode(Vendor, BaseCalendar.Code);
        CreateLFLItemWithVendorNo(Item, Vendor."No.");
        CreateSalesOrder(SalesHeader, Item."No.", LibraryRandom.RandInt(10), ShipmentDate);
    end;

    local procedure FilterPurchaseOrderLine(var PurchaseLine: Record "Purchase Line"; No: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst();
    end;

    local procedure FindUntrackedPlanningElementLine(var UntrackedPlanningElement: Record "Untracked Planning Element"; No: Code[20]; Source: Text)
    begin
        UntrackedPlanningElement.SetRange("Item No.", No);
        UntrackedPlanningElement.SetRange(Source, Source);
        UntrackedPlanningElement.FindFirst();
    end;

    local procedure MakeSupplyOrdersActiveOrder(DemandOrderNo: Code[20])
    var
        ManufacturingUserTemplate: Record "Manufacturing User Template";
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("Demand Order No.", DemandOrderNo);
        RequisitionLine.FindFirst();
        MakeSupplyOrders(
          RequisitionLine, ManufacturingUserTemplate."Make Orders"::"The Active Order",
          ManufacturingUserTemplate."Create Production Order"::"Firm Planned");
    end;

    local procedure MakeSupplyOrders(var RequisitionLine: Record "Requisition Line"; MakeOrders: Option; CreateProductionOrder: Enum "Planning Create Prod. Order")
    var
        ManufacturingUserTemplate: Record "Manufacturing User Template";
    begin
        GetManufacturingUserTemplate(ManufacturingUserTemplate, MakeOrders, CreateProductionOrder);
        LibraryPlanning.MakeSupplyOrders(ManufacturingUserTemplate, RequisitionLine);
    end;

    local procedure PrepareSupplyAndDemandWithinReschedulingPeriod(Item: Record Item)
    var
        SupplyQuantityValue: array[5] of Decimal;
        DemandQuantityValue: array[3] of Decimal;
        SupplyDateValue: array[5] of Date;
        DemandDateValue: array[3] of Date;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
        Quantity: Decimal;
        Dates: array[4] of Date;
        i: Integer;
    begin
        Quantity := LibraryRandom.RandInt(10);

        Dates[1] := WorkDate();
        for i := 2 to ArrayLen(Dates) do // ascending sequence of dates
            Dates[i] := LibraryRandom.RandDateFrom(Dates[i - 1], LibraryRandom.RandInt(20));

        CreateSupplyType(SupplyType, SupplyType::Released, SupplyType::Released, SupplyType::None, SupplyType::None, SupplyType::None);
        CreateSupplyDate(SupplyDateValue, Dates[1], Dates[2], 0D, 0D, 0D);
        CreateSupplyQuantity(SupplyQuantityValue, Quantity, Quantity, 0, 0, 0);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, Item."No.", '', '');

        CreateDemandDate(DemandDateValue, Dates[3], Dates[4], 0D);
        CreateDemandQuantity(DemandQuantityValue, Quantity, Quantity, 0);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 2);
    end;

    local procedure PrepareSupplyAndDemandWithReservationAndCalcRegenPlan(var ItemNo: Code[20]; ReservToDocIndex: Integer; ReservFromDocIndex: Integer)
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        CreateLFLItem(
          Item, Item."Replenishment System"::"Prod. Order", '<' + Format(LibraryRandom.RandIntInRange(20, 50)) + 'W>', '', true, 0, 0);
        ItemNo := Item."No.";

        PrepareSupplyAndDemandWithinReschedulingPeriod(Item);

        LibraryVariableStorage.Enqueue(GlobalProductionOrder[ReservFromDocIndex]."No.");
        SelectSalesLine(SalesLine, GlobalSalesHeader[ReservToDocIndex]."No.");
        SalesLine.ShowReservation();

        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), CalcDate('<+1Y>', WorkDate()));
    end;

    local procedure PrepareSupplyAndDemandWithDampenerQtyAndSafetyStock(var Item: Record Item; DampenerQty: Decimal; SafetyStock: Decimal; ExceedingQty: Decimal)
    var
        SupplyQuantityValue: array[5] of Decimal;
        SupplyDateValue: array[5] of Date;
        DemandDateValue: array[3] of Date;
        DemandQuantityValue: array[3] of Decimal;
        SupplyType: array[5] of Option "None",Released,FirmPlanned,Purchase;
        DampenerPeriod: DateFormula;
    begin
        CreateLFLItem(Item, Item."Replenishment System"::Purchase, '<1Y>', '<1Y>', true, SafetyStock, DampenerQty);
        Evaluate(DampenerPeriod, '<1Y>');
        UpdateItem(Item, Item.FieldNo("Dampener Period"), DampenerPeriod);

        CreateSupplyType(SupplyType, SupplyType::Purchase, SupplyType::Purchase, SupplyType::None, SupplyType::None, SupplyType::None);
        CreateSupplyQuantity(SupplyQuantityValue, LibraryRandom.RandIntInRange(30, 50), LibraryRandom.RandIntInRange(30, 50), 0, 0, 0);
        CreateSupplyDate(SupplyDateValue, WorkDate(), GetRandomDateUsingWorkDate(30), 0D, 0D, 0D);
        CreateSupply(SupplyDateValue, SupplyQuantityValue, SupplyType, Item."No.", Item."No.", '');

        CreateDemandQuantity(
          DemandQuantityValue, SupplyQuantityValue[1] + SupplyQuantityValue[2] - ExceedingQty, 0, 0);
        CreateDemandDate(DemandDateValue, GetRandomDateUsingWorkDate(60), 0D, 0D);
        CreateDemand(DemandDateValue, DemandQuantityValue, Item."No.", 1);
    end;

    local procedure GetManufacturingUserTemplate(var ManufacturingUserTemplate: Record "Manufacturing User Template"; MakeOrder: Option; CreateProductionOrder: Enum "Planning Create Prod. Order")
    begin
        if not ManufacturingUserTemplate.Get(UserId) then
            LibraryPlanning.CreateManufUserTemplate(
              ManufacturingUserTemplate, UserId, MakeOrder, ManufacturingUserTemplate."Create Purchase Order"::"Make Purch. Orders",
              CreateProductionOrder, ManufacturingUserTemplate."Create Transfer Order"::"Make Trans. Orders");
    end;

    local procedure GetCurrentDate(DateFilter: Text[35]) Date: Date
    var
        DateString: Text;
        Position: Integer;
    begin
        Position := StrPos(DateFilter, '..');
        if Position = 0 then
            DateString := DateFilter
        else
            DateString := CopyStr(DateFilter, Position + 2);

        Evaluate(Date, DateString);
    end;

    local procedure InsertTempItemLedgerEntry(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; Qty: Decimal; Date: Date)
    var
        EntryNo: Integer;
    begin
        if TempItemLedgerEntry.FindLast() then
            EntryNo := TempItemLedgerEntry."Entry No." + 1
        else
            EntryNo := 1;

        TempItemLedgerEntry.Init();
        TempItemLedgerEntry."Entry No." := EntryNo;
        TempItemLedgerEntry.Quantity := Qty;
        TempItemLedgerEntry."Posting Date" := Date;
        TempItemLedgerEntry.Insert();
    end;

    local procedure SetDemandDates(var DemandDateValue: array[3] of Date; FromRange: Integer; ToRange: Integer)
    begin
        DemandDateValue[1] := LibraryRandom.RandDateFromInRange(WorkDate(), FromRange, ToRange);
        DemandDateValue[2] := LibraryRandom.RandDateFromInRange(DemandDateValue[1], FromRange, ToRange);
        DemandDateValue[3] := LibraryRandom.RandDateFromInRange(DemandDateValue[2], FromRange, ToRange);
    end;

    local procedure VerifyRequisitionLine(No: Code[20]; ActionMessage: Enum "Action Message Type"; DueDate: Date; OriginalQuantity: Decimal; Quantity: Decimal; OriginalDueDate: Date; LocationCode: Code[10]; VariantCode: Code[10])
    var
        RequisitionLine2: Record "Requisition Line";
    begin
        SelectRequisitionLineForActionMessage(RequisitionLine2, No, ActionMessage, DueDate);
        VerifyQuantityAndDateOnRequisitionLine(RequisitionLine2, OriginalDueDate, Quantity, OriginalQuantity);
        RequisitionLine2.TestField("Location Code", LocationCode);
        RequisitionLine2.TestField("Variant Code", VariantCode);
    end;

    local procedure VerifyRequisitionLineWithOriginalDueDate(No: Code[20]; ActionMessage: Enum "Action Message Type"; OriginalDueDate: Date; DueDate: Date; OriginalQuantity: Decimal; QuantityValue: Decimal; LocationCode: Code[10])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        FilterRequisitionLine(RequisitionLine, No);
        RequisitionLine.SetRange("Action Message", ActionMessage);
        RequisitionLine.SetRange("Original Due Date", OriginalDueDate);
        RequisitionLine.FindFirst();
        RequisitionLine.TestField("Due Date", DueDate);
        RequisitionLine.TestField(Quantity, QuantityValue);
        RequisitionLine.TestField("Original Quantity", OriginalQuantity);
        RequisitionLine.TestField("Location Code", LocationCode);
    end;

    local procedure VerifyPlanningWorksheetEmpty(PlanningLinesCountBeforeCarryOut: Integer; ItemNo: Code[20])
    var
        RequisitionLine2: Record "Requisition Line";
    begin
        RequisitionLine2.SetRange("No.", ItemNo);
        Assert.AreNotEqual(PlanningLinesCountBeforeCarryOut, RequisitionLine2.Count, NumberOfLineNotEqualError);
        Assert.AreEqual(0, RequisitionLine2.Count, NumberOfLineEqualError);
    end;

    local procedure VerifyPlanningWorksheet(var PlanningWorksheet: TestPage "Planning Worksheet"; ActionMessage: Enum "Action Message Type"; No: Code[20]; DueDate: Date; OriginalQuantity: Decimal; Quantity: Decimal; OriginalDueDate: Date)
    begin
        // Verification of Planning Worksheet using page.
        PlanningWorksheet."Action Message".AssertEquals(ActionMessage);
        PlanningWorksheet."No.".AssertEquals(No);
        PlanningWorksheet."Due Date".AssertEquals(DueDate);
        PlanningWorksheet."Original Quantity".AssertEquals(OriginalQuantity);
        PlanningWorksheet.Quantity.AssertEquals(Quantity);
        PlanningWorksheet."Original Due Date".AssertEquals(OriginalDueDate);
    end;

    local procedure VerifyPlanningWorksheetQuantityAndLineCount(RequisitionLine: Record "Requisition Line"; ExpectedQuantity: Decimal)
    begin
        Assert.AreEqual(1, RequisitionLine.Count, LineCountErr);
        RequisitionLine.FindFirst();
        RequisitionLine.TestField(Quantity, ExpectedQuantity);
    end;

    local procedure VerifyPurchaseLine(DocumentNo: Code[20]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        SelectPurchaseLine(PurchaseLine, DocumentNo);
        Assert.AreEqual(Round(Quantity, UOMMgt.QtyRndPrecision()), PurchaseLine.Quantity, PurchaseLine.FieldCaption(Quantity));
    end;

    local procedure VerifyRequisitionLineForMaximumOrderQuantity(var RequisitionLine2: Record "Requisition Line"; No: Code[20]; ActionMessage: Enum "Action Message Type"; DueDate: Date; Quantity: Decimal; OriginalDueDate: Date; NoOfLine: Integer)
    var
        "Count": Integer;
    begin
        SelectRequisitionLineForActionMessage(RequisitionLine2, No, ActionMessage, DueDate);
        for Count := 1 to NoOfLine do begin
            VerifyQuantityAndDateOnRequisitionLine(RequisitionLine2, OriginalDueDate, Quantity, 0);
            RequisitionLine2.Next();
        end;
    end;

    local procedure VerifyQuantityAndDateOnRequisitionLine(var RequisitionLine2: Record "Requisition Line"; OriginalDueDate: Date; Quantity: Decimal; OriginalQuantity: Decimal)
    var
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        Assert.AreEqual(Round(Quantity, UOMMgt.QtyRndPrecision()), RequisitionLine2.Quantity, RequisitionLine2.FieldCaption(Quantity));
        Assert.AreEqual(OriginalDueDate, RequisitionLine2."Original Due Date", RequisitionLine2.FieldCaption("Original Due Date"));
        Assert.AreEqual(
            Round(OriginalQuantity, UOMMgt.QtyRndPrecision()), RequisitionLine2."Original Quantity", RequisitionLine2.FieldCaption("Original Quantity"));
    end;

    local procedure VerifyRequisitionLineCount(ExpectedReqLinesCount: Integer)
    var
        RequisitionLine2: Record "Requisition Line";
    begin
        RequisitionLine2.SetFilter("No.", '<>''''');
        Assert.AreEqual(ExpectedReqLinesCount, RequisitionLine2.Count, NumberOfLineEqualError);
    end;

    local procedure VerifyPurchaseOrderQuantity(ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        FilterPurchaseOrderLine(PurchaseLine, ItemNo);
        PurchaseLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyProdOrderQuantity(ItemNo: Code[20]; Quantity: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        FilterFirmPlannedProdOrderLine(ProdOrderLine, ItemNo);
        ProdOrderLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPurchaseOrderPlanningFlexibility(ItemNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        FilterPurchaseOrderLine(PurchaseLine, ItemNo);
        PurchaseLine.TestField("Planning Flexibility", PurchaseLine."Planning Flexibility"::None);
    end;

    local procedure VerifyProdOrderPlanningFlexibility(ItemNo: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        FilterFirmPlannedProdOrderLine(ProdOrderLine, ItemNo);
        ProdOrderLine.TestField("Planning Flexibility", ProdOrderLine."Planning Flexibility"::None);
    end;

    local procedure VerifyPlanWkshLineForMaximumOrderQuantity(ProductionForecastEntry: array[3] of Record "Production Forecast Entry"; Item: Record Item; PlanningWorksheet: TestPage "Planning Worksheet"; RequisitionWkshName: Code[10])
    var
        RequisitionLine: Record "Requisition Line";
        i: Integer;
        DemandQuantity: Decimal;
        SupplyQuantity: Integer;
    begin
        for i := 1 to ArrayLen(ProductionForecastEntry) do
            DemandQuantity += ProductionForecastEntry[i]."Forecast Quantity";
        OpenPlanningWorksheetPage(PlanningWorksheet, RequisitionWkshName);

        // Verify quantity on RequisitionLine was less than Maximum Order Quantity of the Item.
        RequisitionLine.SetRange("No.", Item."No.");
        RequisitionLine.FindSet();
        repeat
            SupplyQuantity += RequisitionLine.Quantity;
            Assert.IsTrue(
              RequisitionLine.Quantity <= Item."Maximum Order Quantity",
              StrSubstNo(MaximumOrderQuantityErr, RequisitionLine.Quantity, Item."Maximum Order Quantity"));
        until RequisitionLine.Next() = 0;

        // Verify supply have met demand and Safety Stock Quantity.
        Item.CalcFields(Inventory);
        Assert.IsTrue(
          Item.Inventory + SupplyQuantity - DemandQuantity >= Item."Safety Stock Quantity",
          StrSubstNo(SafetyStockQuantityErr, Item.Inventory + SupplyQuantity - DemandQuantity, Item."Safety Stock Quantity"));
    end;

    local procedure VerifyDateOnPurchaseLine(ItemNo: Code[20]; ExpectedReceiptDate: Date; PlannedReceiptDate: Date; OrderDate: Date)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        FilterPurchaseOrderLine(PurchaseLine, ItemNo);
        PurchaseLine.TestField("Expected Receipt Date", ExpectedReceiptDate);
        PurchaseLine.TestField("Planned Receipt Date", PlannedReceiptDate);
        PurchaseLine.TestField("Order Date", OrderDate);
    end;

    local procedure VerifyQuantityOnRequisitionLine(No: Code[20]; LineNo: Integer; Quantity: Decimal)
    begin
        FilterRequisitionLine(RequisitionLine, No);
        RequisitionLine.SetRange("Line No.", LineNo);
        RequisitionLine.FindFirst();
        RequisitionLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyDueDatesOnRequisitionLine(ItemNo: Code[20]; DueDates: array[3] of Date)
    var
        RequisitionLine: Record "Requisition Line";
        i: Integer;
    begin
        FindRequisitionLine(RequisitionLine, ItemNo);
        for i := 1 to ArrayLen(DueDates) do begin
            RequisitionLine.TestField("Due Date", DueDates[i] - 1);
            RequisitionLine.Next();
        end;
    end;

    local procedure VerifyExpectedReceiptDateOnReservationEntry(ItemNo: Code[20]; ExpectedReceiptDate: Date)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.FindFirst();
        Assert.AreEqual(ExpectedReceiptDate, ReservationEntry."Expected Receipt Date", ExpectedReceiptDateErr);
    end;

    local procedure VerifyProjectedInventory(ItemNo: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
        SalesLine: Record "Sales Line";
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        ProjectedInventory: Decimal;
    begin
        ProdOrderLine.SetRange("Item No.", ItemNo);
        if ProdOrderLine.FindSet() then
            repeat
                InsertTempItemLedgerEntry(TempItemLedgerEntry, ProdOrderLine.Quantity, ProdOrderLine."Due Date");
            until ProdOrderLine.Next() = 0;

        SalesLine.SetRange("No.", ItemNo);
        if SalesLine.FindSet() then
            repeat
                InsertTempItemLedgerEntry(TempItemLedgerEntry, -SalesLine.Quantity, SalesLine."Shipment Date");
            until SalesLine.Next() = 0;

        TempItemLedgerEntry.SetCurrentKey("Item No.", "Posting Date");
        if TempItemLedgerEntry.FindSet() then
            repeat
                ProjectedInventory += TempItemLedgerEntry.Quantity;
                Assert.IsTrue(ProjectedInventory >= 0, ProjectedInventoryNegativeMsg);
            until TempItemLedgerEntry.Next() = 0;
    end;

    local procedure VerifyNameValueBufferSequence(var NameValueBuffer: Record "Name/Value Buffer"; FirstToken: Text)
    begin
        NameValueBuffer.TestField(Name, FirstToken);
        NameValueBuffer.Next();
        NameValueBuffer.TestField(Name, ReservationEntryTok);
        NameValueBuffer.Next();
        NameValueBuffer.TestField(Name, ReservationEntryTok);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation.AvailableToReserve.Invoke();  // Open the page - Available Sales Line, on Handler AvailableSalesLinesPageHandler.
        Reservation.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableProdOrderLineReservePageHandler(var AvailableProdOrderLines: TestPage "Available - Prod. Order Lines")
    var
        ProdOrderNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ProdOrderNo);
        AvailableProdOrderLines.FILTER.SetFilter("Prod. Order No.", Format(ProdOrderNo));
        AvailableProdOrderLines.Reserve.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableAssemblyHeadersPageHandler(var AvailableAssemblyHeaders: TestPage "Available - Assembly Headers")
    begin
        AvailableAssemblyHeaders.FILTER.SetFilter("No.", GlobalAssemblyHeader[2]."No.");
        AvailableAssemblyHeaders.Reserve.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableAssemblyLinesPageHandler(var AvailableAssemblyLines: TestPage "Available - Assembly Lines")
    begin
        AvailableAssemblyLines.FILTER.SetFilter("Document No.", GlobalAssemblyHeader[2]."No.");
        AvailableAssemblyLines.Reserve.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableSalesLinesPageHandler(var AvailableSalesLines: TestPage "Available - Sales Lines")
    begin
        AvailableSalesLines.FILTER.SetFilter("Document No.", GlobalSalesHeader[2]."No.");
        AvailableSalesLines.Reserve.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableProdOrderCompPageHandler(var AvailableProdOrderComp: TestPage "Available - Prod. Order Comp.")
    begin
        AvailableProdOrderComp.FILTER.SetFilter("Prod. Order No.", GlobalProductionOrder[2]."No.");
        AvailableProdOrderComp.Reserve.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableProdOrderLinesPageHandler(var AvailableProdOrderLines: TestPage "Available - Prod. Order Lines")
    begin
        AvailableProdOrderLines.FILTER.SetFilter("Prod. Order No.", GlobalProductionOrder[2]."No.");
        AvailableProdOrderLines.Reserve.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableSalesLinesCancelReservationPageHandler(var AvailableSalesLines: TestPage "Available - Sales Lines")
    begin
        AvailableSalesLines.CancelReservation.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailablePurchaseLinesPageHandler(var AvailablePurchaseLines: TestPage "Available - Purchase Lines")
    begin
        AvailablePurchaseLines.Reserve.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailablePurchaseLinesCancelReservationPageHandler(var AvailablePurchaseLines: TestPage "Available - Purchase Lines")
    begin
        AvailablePurchaseLines.CancelReservation.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableTransferLinesPageHandler(var AvailableTransferLines: TestPage "Available - Transfer Lines")
    begin
        AvailableTransferLines.FILTER.SetFilter("Document No.", GlobalTransferHeader[2]."No.");
        AvailableTransferLines.Reserve.Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculatePlanPlanWkshRequestPageHandler(var CalculatePlanPlanWksh: TestRequestPage "Calculate Plan - Plan. Wksh.")
    begin
        // Calculate Regenerative Plan using page.
        CalculatePlanPlanWksh.Item.SetFilter("No.", GlobalItemNo);
        CalculatePlanPlanWksh.StartingDate.SetValue(WorkDate());
        CalculatePlanPlanWksh.EndingDate.SetValue(GetRandomDateUsingWorkDate(90));
        CalculatePlanPlanWksh.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MakeSupplyOrdersPageHandler(var MakeSupplyOrders: Page "Make Supply Orders"; var Response: Action)
    begin
        Response := ACTION::LookupOK;
    end;

    local procedure InsertNameValueBufferEntry(NewName: Text[30])
    var
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        NameValueBuffer.Init();
        NameValueBuffer.Name := NewName;
        NameValueBuffer.Insert();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
        InsertNameValueBufferEntry(ConfirmTok);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AssemblyAvailabilityModalPageHandler(var AsmAvailabilityCheck: TestPage "Assembly Availability Check")
    begin
        InsertNameValueBufferEntry(AvailabilityTok);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendAssemblyAvailabilityNotificationHandler(var Notification: Notification): Boolean
    var
        AssemblyLineManagement: Codeunit "Assembly Line Management";
    begin
        AssemblyLineManagement.ShowNotificationDetails(Notification);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnBeforeModifyEvent', '', false, false)]
    local procedure InsertRecordBufferOnBeforeModifyEvent(var Rec: Record "Reservation Entry"; var xRec: Record "Reservation Entry"; RunTrigger: Boolean)
    begin
        InsertNameValueBufferEntry(ReservationEntryTok);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure InboundTransferStrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 2;  // Reserve inbound transfer
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure OutboundTransferStrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1;  // Reserve outbound transfer
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure CheckOrderExistsMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, CouldNotChangeSupplyTxt) > 0, WrongMessageTxt);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

