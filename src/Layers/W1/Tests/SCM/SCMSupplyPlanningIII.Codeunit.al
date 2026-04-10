codeunit 137073 "SCM Supply Planning -III"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Planning] [Planning Worksheet] [SCM]
        isInitialized := false;
    end;

    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        OutputItemJournalTemplate: Record "Item Journal Template";
        OutputItemJournalBatch: Record "Item Journal Batch";
        LocationBlue: Record Location;
        LocationYellow: Record Location;
        LocationRed: Record Location;
        LocationInTransit: Record Location;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryService: Codeunit "Library - Service";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        isInitialized: Boolean;
        RequisitionLineMustNotExistErr: Label 'Requisition Line must not exist for Item %1.', Comment = '%1 - Item No';
        ItemNotPlannedMsg: Label 'Not all items were planned. A total of 1 items were not planned.';
        ItemFilterTxt: Label '%1|%2', Comment = 'Item No1 | Item No2';
        SuggestedQtyErrMsg: Label 'Suggested Quantity on planning lines must not be less than Maximum Inventory.';
        AvailabilityWarningConfirmationMsg: Label 'You do not have enough inventory to meet the demand for items in one or more lines';
        OrderDateChangeMsg: Label 'You have changed the Order Date on the sales header, which might affect the prices and discounts on the sales lines. You should review the lines and manually update prices and discounts if needed.';
        SameDateErrMsg: Label 'The dates must not be same.';
        ReservationEntryMustNotExistErr: Label 'Reservation Entry must not exist for Item %1.', Comment = '%1 - Item No';
        DeleteProductionForecastConfirmMessageQst: Label 'Demand forecast %1 has entries. Do you want to delete it anyway?', Comment = '%1 - Forcast No';
        ItemTrackingMode: Option " ","Assign Lot No.","Select Entries";
        QuantityNotCorrectErr: Label 'Quantity is not correct in Planning Worksheet';
        VersionsWillBeClosedMsg: Label 'All versions attached to the BOM will be closed. Close BOM?';
        CannotPurchaseItemMsg: Label 'You cannot purchase Item %1 because the Purchasing Blocked check box is selected on the Item card.';
        ProductionBlockedOutputItemErr: Label 'You cannot produce %1 %2 because the %3 is %4 on the %1 card.', Comment = '%1 - Table Caption (Item), %2 - Item No., %3 - Field Caption, %4 - Field Value';
        ProductionBlockedOutputItemVariantErr: Label 'You cannot produce variant %1 for %2 %3 because it is blocked for production output.', Comment = '%1 - Item Variant Code, %2 - Table Caption (Item), %3 - Item No.';

    [Test]
    [HandlerFunctions('MessageHandler,PlanningErrorLogPageHandler')]
    [Scope('OnPrem')]
    procedure CalcRegenPlanForBlockedLFLItem()
    var
        Item: Record Item;
    begin
        // Setup.
        Initialize();
        PlanForBlockedItem(Item."Replenishment System"::Purchase);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcNetChangePlanForBlockedLFLItem()
    var
        Item: Record Item;
    begin
        // Setup.
        Initialize();
        PlanForBlockedItem(Item."Replenishment System"::"Prod. Order");
    end;

    local procedure PlanForBlockedItem(ItemReplenishmentSystem: Enum "Replenishment System")
    var
        Item: Record Item;
    begin
        // Create Lot for Lot Item with required Replenishment system.
        CreateLotForLotItem(Item, ItemReplenishmentSystem, LibraryRandom.RandInt(10));
        UpdateItemBlocked(Item);

        // Exercise: Calculate Regenerative Plan for Planning Worksheet without any demand.
        if ItemReplenishmentSystem = Item."Replenishment System"::Purchase then begin
            LibraryVariableStorage.Enqueue(ItemNotPlannedMsg);  // Required inside MessageHandler.
            CalcRegenPlanForPlanWksh(Item."No.");
        end else
            CalcNetChangePlanForPlanWksh(Item."No.");

        // Verify: Verify that no Requisition line is created for Requisition Worksheet, when item is blocked.
        VerifyEmptyRequisitionLine(Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanWithOutputJournalForFRQItem()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
        DocNoIsProdOrderNo: Boolean;
    begin
        // Setup: Update Manufacturing Setup. Create Parent and Child Item hierarchy with Reorder policy - Fixed Reorder Qty. Create And Certify Production BOM.
        Initialize();
        DocNoIsProdOrderNo := UpdateManufacturingSetup(false);
        CreateFRQItemSetup(ChildItem, Item);

        // Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(10, 2));  // Random Quantity not important.

        // Create and Post Output Journal.
        CreateAndPostOutputJournal(ProductionOrder."No.");

        // Exercise: Calculate Regenerative Plan for parent item.
        CalcRegenPlanForPlanWksh(Item."No.");

        // Verify: Verify Planning Worksheet quantity and Ref. Order Type. New Production Order quantity is equal to Reorder Qty.
        VerifyRequisitionLineQty(Item."No.", Item."Reorder Quantity", RequisitionLine."Ref. Order Type"::"Prod. Order");

        // Teardown.
        UpdateManufacturingSetup(DocNoIsProdOrderNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningWorksheetLinesNotAffectedWhenDeletePurchaseAndCalcRegenPlanTwice()
    var
        Item: Record Item;
    begin
        // Setup.
        Initialize();
        RegenPlanNotAffectedByDeleteAndRecalculate(Item."Replenishment System"::Purchase);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningWorksheetLinesNotAffectedWhenDeleteProductionAndCalcRegenPlanTwice()
    var
        Item: Record Item;
    begin
        // Setup.
        Initialize();
        RegenPlanNotAffectedByDeleteAndRecalculate(Item."Replenishment System"::"Prod. Order");
    end;

    local procedure RegenPlanNotAffectedByDeleteAndRecalculate(ItemReplenishmentSystem: Enum "Replenishment System")
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        TempRequisitionLine: Record "Requisition Line" temporary;
    begin
        // Create Lot for Lot Item. Replenishment - Purchase  or Production Order with Sales Setup. Calculate Regenerative Plan and Carry Out Action message.
        CreateLotForLotItem(Item, ItemReplenishmentSystem, LibraryRandom.RandInt(10));
        CreateSalesOrder(SalesHeader, Item."No.", LibraryRandom.RandDec(10, 2));
        CalcRegenPlanAndCarryOutActionMessage(TempRequisitionLine, Item."No.");  // Temporary Requisition line record used later in verification.

        // Delete newly created Purchase Order Or Production Order.
        if ItemReplenishmentSystem = Item."Replenishment System"::Purchase then
            DeleteNewPurchaseOrder(Item."No.")
        else
            DeleteNewProductionOrder(Item."No.");

        // Exercise: Re-run Regenerative Plan to get the Planning lines again on Planning worksheet.
        CalcRegenPlanForPlanWksh(Item."No.");

        // Verify: Verify the Planning lines created next time are also the same.
        VerifyNewRequisitionLine(TempRequisitionLine, Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanForItemWithNegativeRoundingPrecision()
    begin
        // Setup.
        Initialize();
        CalcRegenPlanForItemWithRoundingPrecision(-LibraryRandom.RandInt(10));  // Negative Rounding Precision Value.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanForItemWithZeroRoundingPrecision()
    begin
        // Setup.
        Initialize();
        CalcRegenPlanForItemWithRoundingPrecision(0);  // Zero Rounding Precision Value.
    end;

    local procedure CalcRegenPlanForItemWithRoundingPrecision(RoundingPrecision: Decimal)
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        // Create Lot For Lot Item with Rounding Precision.
        CreateLotForLotItem(Item, Item."Replenishment System"::Purchase, LibraryRandom.RandInt(10));
        Item."Rounding Precision" := RoundingPrecision;  // Direct Assignment for Rounding Precision, Avoid validate Trigger because On Validate Trigger Rounding Precision must be Greater than Zero.
        Item.Modify(true);

        // Exercise: Calculate Regenerative Plan.
        CalcRegenPlanForPlanWksh(Item."No.");

        // Verify: Verify the Planning lines created without error.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        VerifyRequisitionLine(RequisitionLine, Item."Safety Stock Quantity", 0, RequisitionLine."Ref. Order Type"::Purchase);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanReqWkshPositiveAdjFRQItem()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup. Post Positive Adjustment for FRQ item and Calculate Plan for Requisition Worksheet. Verify Requisition Worksheet Lines.
        Initialize();
        CalculatePlanReqWorksheetForAdjustment(ItemJournalLine."Entry Type"::"Positive Adjmt.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanReqWkshNegativeAdjFRQItem()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup. Post Negative Adjustment for FRQ item and Calculate Plan for Requisition Worksheet. Verify Requisition Worksheet Lines.
        Initialize();
        CalculatePlanReqWorksheetForAdjustment(ItemJournalLine."Entry Type"::"Negative Adjmt.");
    end;

    local procedure CalculatePlanReqWorksheetForAdjustment(EntryType: Enum "Item Ledger Document Type")
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        RequisitionLine: Record "Requisition Line";
        AdjustmentQuantity: Decimal;
    begin
        // Create Fixed Reorder Quantity Item with planning parameters - Reorder Qty, Reorder Point and Safety Stock.
        CreateFRQItem(
          Item, Item."Replenishment System"::Purchase, LibraryRandom.RandInt(10) + 100, LibraryRandom.RandInt(10) + 10,
          LibraryRandom.RandInt(10));  // Quantity proportion required for test.

        // Post Positive or Negative Adjustment as required.
        AdjustmentQuantity := CreateAndPostItemJournalLine(Item."No.", EntryType);

        // Exercise: Calculate Plan from Requisition Worksheet.
        CalculatePlanForRequisitionWorksheet(Item);

        // Verify: Verify Requisition Worksheet lines depending on the adjustment type.
        if EntryType = ItemJournalLine."Entry Type"::"Positive Adjmt." then begin
            SelectRequisitionLine(RequisitionLine, Item."No.");
            VerifyRequisitionLine(RequisitionLine, Item."Reorder Quantity", 0, RequisitionLine."Ref. Order Type"::Purchase);
        end else begin
            VerifyRequisitionLineWithDueDate(Item."No.", AdjustmentQuantity, SelectDateWithSafetyLeadTime(WorkDate(), -1));
            VerifyRequisitionLineWithDueDate(Item."No.", Item."Safety Stock Quantity", WorkDate());
            VerifyRequisitionLineWithDueDate(Item."No.", Item."Reorder Quantity", SelectDateWithSafetyLeadTime(WorkDate(), 1));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanReqWkshForSalesFRQItem()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesQty: Decimal;
    begin
        // Setup: Create Fixed Reorder Quantity Item with planning parameters - Reorder Qty, Reorder Point and Safety Stock.
        Initialize();
        SalesQty := LibraryRandom.RandDec(10, 2);
        CreateFRQItem(Item, Item."Replenishment System"::Purchase, SalesQty + 100, SalesQty + 10, SalesQty);  // Quantity proportion required for test.

        // Create Sales Order with required quantity.
        CreateSalesOrder(SalesHeader, Item."No.", SalesQty);

        // Exercise: Calculate Plan from Requisition Worksheet.
        CalculatePlanForRequisitionWorksheet(Item);

        // Verify: Verify Requisition Worksheet lines.
        VerifyRequisitionLineWithDueDate(Item."No.", Item."Reorder Quantity", SelectDateWithSafetyLeadTime(WorkDate(), 1));
        VerifyRequisitionLineWithDueDate(Item."No.", SalesQty + Item."Safety Stock Quantity", WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanReqWkshForPurchaseFRQItem()
    var
        Item: Record Item;
        PurchaseQty: Decimal;
    begin
        // Setup: Create Fixed Reorder Quantity Item with planning parameters - Reorder Qty, Reorder Point and Safety Stock.
        Initialize();
        PurchaseQty := LibraryRandom.RandDec(10, 2);
        CreateFRQItem(Item, Item."Replenishment System"::Purchase, PurchaseQty + 100, PurchaseQty + 10, PurchaseQty);  // Quantity proportion required for test.

        // Create Purchase Order with required quantity.
        CreatePurchaseOrder(Item."No.", PurchaseQty);

        // Exercise: Calculate Plan from Requisition Worksheet.
        CalculatePlanForRequisitionWorksheet(Item);

        // Verify: Verify Requisition Worksheet lines.
        VerifyRequisitionLineWithDueDate(Item."No.", Item."Safety Stock Quantity", WorkDate());
        VerifyRequisitionLineWithDueDate(Item."No.", Item."Reorder Quantity", SelectDateWithSafetyLeadTime(WorkDate(), 1));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanReqWkshPositiveAdjMQItem()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Create Maximum Quantity Item with planning parameters - Max. Inventory. Post Positive Adjustment for Item.
        Initialize();
        CreateMQItem(Item, LibraryRandom.RandDec(5, 2) + 100, 0, 0);  // Reorder Point and Order Multiple not required.
        CreateAndPostItemJournalLine(Item."No.", ItemJournalLine."Entry Type"::"Positive Adjmt.");

        // Exercise: Calculate Plan from Requisition Worksheet.
        CalculatePlanForRequisitionWorksheet(Item);

        // Verify: Verify Requisition Worksheet line does not exist.
        VerifyEmptyRequisitionLine(Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanReqWkshForSalesMQItem()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesQty: Decimal;
    begin
        // Setup: Create Maximum Quantity Item with planning parameters - Max. Inventory. Create Sales Order.
        Initialize();
        CreateMQItem(Item, LibraryRandom.RandDec(5, 2) + 100, 0, 0);  // Reorder Point and Order Multiple not required.
        SalesQty := LibraryRandom.RandDec(10, 2);
        CreateSalesOrder(SalesHeader, Item."No.", SalesQty);

        // Exercise: Calculate Plan from Requisition Worksheet.
        CalculatePlanForRequisitionWorksheet(Item);

        // Verify: Verify Requisition Worksheet lines.
        VerifyRequisitionLineWithDueDate(Item."No.", SalesQty, WorkDate());
        VerifyRequisitionLineWithDueDate(Item."No.", Item."Maximum Inventory", SelectDateWithSafetyLeadTime(WorkDate(), 1));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SpecialSalesOrderOnReqWksheetFRQItem()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        SalesQty: Decimal;
    begin
        // Setup: Create Fixed Reorder Quantity Item with planning parameters - Reorder Qty, Reorder Point and Safety Stock.
        Initialize();
        SalesQty := LibraryRandom.RandDec(10, 2);
        CreateFRQItem(Item, Item."Replenishment System"::Purchase, SalesQty + 100, SalesQty + 10, SalesQty);  // Quantity proportion required for test.

        // Create and Release Sales Order with Purchasing Code as Special Order.
        CreateAndReleaseSalesOrderAsSpecialOrder(Item."No.", SalesQty);

        // Exercise: Get Sales Order as Special Order from Requisition Worksheet.
        CreateRequisitionLineFromSpecialOrder(Item."No.");

        // Verify: Verify Requisition Worksheet line values.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        VerifyRequisitionLine(RequisitionLine, SalesQty, 0, RequisitionLine."Ref. Order Type"::Purchase);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanPlanWkshWithDerivedDemandsUsingForecastOrderItem()
    var
        ChildItem: Record Item;
        Item: Record Item;
        ProductionForecastName: Record "Production Forecast Name";
        OldCombinedMPSMRPCalculation: Boolean;
        ForecastQty: Integer;
        ProdBOMQtyPer: Integer;
        NewPurchOrderDate: Date;
    begin
        // Setup: Update Manufacturing Setup. Create Order Items setup.
        Initialize();
        OldCombinedMPSMRPCalculation := UpdateManufacturingSetupCombinedMPSAndMRP(true);  // Combined MPS,MRP Calculation - TRUE.
        ProdBOMQtyPer := CreateOrderItemSetup(ChildItem, Item);

        // Create two Production forecast entries with different dates for same parent item.
        ForecastQty := CreateProductionForecastSetup(Item."No.", true, ProductionForecastName); // True for multiple entries.

        // Exercise: Calculate regenerative Plan from Planning Worksheet using page. Page Handler - CalculatePlanPlanWkshRequestPageHandler.
        CalcRegenPlanForPlanWkshPage(Item."No.", ChildItem."No.");

        // Verify: Verify Requisition Worksheet lines generated separately - for different forecasts and derived component demands.
        VerifyRequisitionLineWithDueDate(Item."No.", ForecastQty, WorkDate());
        NewPurchOrderDate := SelectDateWithSafetyLeadTime(WorkDate(), 1);
        VerifyRequisitionLineWithDueDate(Item."No.", ForecastQty, CalcDate('<1D>', NewPurchOrderDate));
        VerifyRequisitionLineWithDueDate(ChildItem."No.", ProdBOMQtyPer * ForecastQty, SelectDateWithSafetyLeadTime(WorkDate(), -1));
        VerifyRequisitionLineWithDueDate(ChildItem."No.", ProdBOMQtyPer * ForecastQty, SelectDateWithSafetyLeadTime(WorkDate(), 1));

        // Teardown.
        UpdateManufacturingSetup(OldCombinedMPSMRPCalculation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanPlanWkshWithDerivedDemandsUsingSalesOrderItem()
    var
        ChildItem: Record Item;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesQty: Decimal;
        EndDate: Date;
        OldCombinedMPSMRPCalculation: Boolean;
        ProdBOMQtyPer: Integer;
        NewPurchOrderDate: Date;
    begin
        // Setup: Update Manufacturing Setup. Create Order Items setup.
        Initialize();
        OldCombinedMPSMRPCalculation := UpdateManufacturingSetupCombinedMPSAndMRP(true);  // Combined MPS,MRP Calculation - TRUE.
        ProdBOMQtyPer := CreateOrderItemSetup(ChildItem, Item);

        // Create two Sales Order with different shipment dates for same parent item.
        SalesQty := LibraryRandom.RandInt(10);
        CreateSalesOrder(SalesHeader, Item."No.", SalesQty);
        CreateSalesOrder(SalesHeader2, Item."No.", SalesQty);
        UpdateShipmentDateOnSalesLine(SalesHeader2."No.", GetRequiredDate(1, 1, WorkDate()));  // Second Sales Order Shipment date close to WORKDATE.

        // Exercise: Calculate regenerative Plan from Planning Worksheet for both parent and child items.
        Item.SetFilter("No.", ItemFilterTxt, Item."No.", ChildItem."No.");  // Filter Required for two Items.
        EndDate := GetRequiredDate(10, 30, WorkDate());  // End Date relative to Workdate.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), EndDate);

        // Verify: Verify Requisition Worksheet lines generated separately - for different Sales orders and derived component demands.
        VerifyRequisitionLineWithDueDate(Item."No.", SalesQty, WorkDate());
        NewPurchOrderDate := SelectDateWithSafetyLeadTime(WorkDate(), 1);
        VerifyRequisitionLineWithDueDate(Item."No.", SalesQty, CalcDate('<1D>', NewPurchOrderDate));
        VerifyRequisitionLineWithDueDate(ChildItem."No.", ProdBOMQtyPer * SalesQty, SelectDateWithSafetyLeadTime(WorkDate(), -1));
        VerifyRequisitionLineWithDueDate(ChildItem."No.", ProdBOMQtyPer * SalesQty, SelectDateWithSafetyLeadTime(WorkDate(), 1));

        // Teardown.
        UpdateManufacturingSetup(OldCombinedMPSMRPCalculation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanPlanWkshWithMultiLineSalesExceedMaxInventoryMQItem()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesQty: Decimal;
        NewShipmentDate: Date;
        NewPurchOrderDate: Date;
    begin
        // Setup: Create Maximum Quantity Item with planning parameters - Max. Inventory.
        Initialize();
        CreateMQItem(Item, LibraryRandom.RandDec(5, 2) + 100, 0, 0);  // Reorder Point and Order Multiple not required.

        // Create Sales Order with two lines. Create second Sales Line with same Sales Qty but with Different Shipment date.
        SalesQty := LibraryRandom.RandDecInRange(10, 20, 2) + 100;
        CreateSalesOrder(SalesHeader, Item."No.", SalesQty);
        NewShipmentDate := GetRequiredDate(1, 1, WorkDate());  // Shipment Date relative to Work Date.
        LibrarySales.CreateSalesLineWithShipmentDate(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", NewShipmentDate, SalesQty);

        // Exercise: Calculate Regenerative Plan for the item.
        CalcRegenPlanForPlanWksh(Item."No.");

        // Verify: Verify Requisition Worksheet lines suggests required planning lines which respect Maximum inventory value with respect to dates.
        VerifyRequisitionLineWithDueDate(Item."No.", Item."Maximum Inventory", SelectDateWithSafetyLeadTime(WorkDate(), 1));
        VerifyRequisitionLineWithDueDate(Item."No.", SalesQty, WorkDate());
        NewPurchOrderDate := SelectDateWithSafetyLeadTime(WorkDate(), 1);
        VerifyRequisitionLineWithDueDate(Item."No.", SalesQty - Item."Maximum Inventory", CalcDate('<1D>', NewPurchOrderDate));
        NewPurchOrderDate := SelectDateWithSafetyLeadTime(NewPurchOrderDate, 1);
        VerifyRequisitionLineWithDueDate(
          Item."No.", Item."Maximum Inventory", CalcDate('<1D>', SelectDateWithSafetyLeadTime(NewPurchOrderDate, 1)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanReqWkshForPurchaseAndOrderMultipleMQItem()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        PurchaseQty: Decimal;
    begin
        // Setup: Create Maximum Quantity Item with planning parameters.
        Initialize();
        PurchaseQty := LibraryRandom.RandDec(5, 2);
        CreateMQItem(Item, PurchaseQty * 11, PurchaseQty, PurchaseQty * 7);  // Maximum Inventory, Reorder Point and Order Multiple.

        // Create Purchase Order with required quantity.
        CreatePurchaseOrder(Item."No.", PurchaseQty);

        // Exercise: Calculate Plan from Requisition Worksheet.
        CalculatePlanForRequisitionWorksheet(Item);

        // Verify: Verify Requisition Worksheet lines - Due to Order Multiple not an exact multiple of Maximum Inventory, the suggested qty exceeds Maximum Inventory.
        SelectRequisitionLineForActionMessage(RequisitionLine, Item."No.", RequisitionLine."Action Message"::New);
        Assert.IsTrue(RequisitionLine.Quantity > Item."Maximum Inventory", SuggestedQtyErrMsg);
        SelectRequisitionLineForActionMessage(RequisitionLine, Item."No.", RequisitionLine."Action Message"::Cancel);  // Verify the Purchase Order has been cancelled.
        VerifyRequisitionLine(RequisitionLine, 0, PurchaseQty, RequisitionLine."Ref. Order Type"::Purchase);  // Suggested Quantity - Zero.
    end;

    [Test]
    [HandlerFunctions('AssignSerialTrackingAndCheckTrackingQtyPageHandler,QuantityToCreatePageHandler,ConfirmHandlerTRUE')]
    [Scope('OnPrem')]
    procedure CalcPlanPlanWkshForSalesWithSerialTrackingLFLItem()
    var
        Item: Record Item;
        ItemTrackingCodeSNSpecific: Record "Item Tracking Code";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup: Create Lot for Lot Item. Update SN specific Tracking and Serial No on Item.
        Initialize();
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCodeSNSpecific, true, false);  // SN Specific Tracking - TRUE.
        CreateLotForLotItem(Item, Item."Replenishment System"::Purchase, LibraryRandom.RandInt(10));
        UpdateItemSerialNoTracking(Item, ItemTrackingCodeSNSpecific.Code);

        // Create Sales Order. Assign SN specific Tracking to Sales Line. Page Handler - AssignSerialTrackingAndCheckTrackingQtyPageHandler.
        CreateSalesOrder(SalesHeader, Item."No.", 1);  // Qty value required for single Serial Tracking line.
        AssignTrackingOnSalesLine(SalesLine, SalesHeader."No.");

        // Exercise: Calculate Regenerative Plan from Planning Worksheet.
        CalcRegenPlanForPlanWksh(Item."No.");

        // Verify: Verify Quantity and Tracking assigned on Requisition Line. Verified in AssignSerialTrackingAndCheckTrackingQtyPageHandler.
        VerifyTrackingOnRequisitionLine(Item."No.", SalesLine.Quantity);
        VerifyRequisitionLineWithDueDate(Item."No.", SalesLine.Quantity, SalesLine."Shipment Date");
    end;

    [Test]
    [HandlerFunctions('AssignLotTrackingAndCheckTrackingQtyPageHandler,CalculatePlanPlanWkshRequestPageHandler,ConfirmHandlerTRUE')]
    [Scope('OnPrem')]
    procedure CalcPlanPlanWkshForForecastAndSalesWithLotTrackingOrderItem()
    var
        Item: Record Item;
        ItemTrackingCodeLotSpecific: Record "Item Tracking Code";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProductionForecastName: Record "Production Forecast Name";
        ShipmentDate: Date;
        ForecastQty: Decimal;
    begin
        // Setup: Create Order Item. Update Lot specific Tracking and Lot No on Item.
        Initialize();
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCodeLotSpecific, false, true);  // SN Specific Tracking - FALSE.
        CreateItem(Item, Item."Reordering Policy"::Order, Item."Replenishment System"::Purchase);
        UpdateItemLotNoTracking(Item, ItemTrackingCodeLotSpecific.Code);

        // Create Production Forecast.
        ForecastQty := CreateProductionForecastSetup(Item."No.", false, ProductionForecastName); // Boolean - FALSE for single Forecast Entry.

        // Create Sales Order. Update Shipment date on Sales Line. Assign Lot Specific Tracking on Sales Line.Page Handler - AssignLotTrackingAndCheckTrackingQtyPageHandler.
        CreateSalesOrder(SalesHeader, Item."No.", LibraryRandom.RandDec(10, 2));
        ShipmentDate := GetRequiredDate(10, 30, WorkDate());
        UpdateShipmentDateOnSalesLine(SalesHeader."No.", ShipmentDate);
        AssignTrackingOnSalesLine(SalesLine, SalesHeader."No.");

        // Exercise: Calculate Regenerative Plan from Planning Worksheet. Using Page Handler - CalculatePlanPlanWkshRequestPageHandler.
        CalcRegenPlanForPlanWkshPage(Item."No.", Item."No.");

        // Verify: Verify Quantity and Tracking assigned on Requisition Line. Verified in AssignLotTrackingAndCheckTrackingQtyPageHandler.
        VerifyTrackingOnRequisitionLine(Item."No.", SalesLine.Quantity);
        VerifyRequisitionLineWithDueDate(Item."No.", SalesLine.Quantity, SalesLine."Shipment Date");
        VerifyRequisitionLineWithDueDate(Item."No.", ForecastQty - SalesLine.Quantity, WorkDate());
    end;

    [Test]
    [HandlerFunctions('AssignLotTrackingAndCheckTrackingQtyPageHandler,CalculatePlanPlanWkshRequestPageHandler,ConfirmHandlerTRUE')]
    [Scope('OnPrem')]
    procedure CalcPlanPlanWkshForForecastAndSalesWithLotTrackingMQItem()
    var
        Item: Record Item;
        ItemTrackingCodeLotSpecific: Record "Item Tracking Code";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProductionForecastName: Record "Production Forecast Name";
        ShipmentDate: Date;
        ForecastQty: Decimal;
    begin
        // Setup: Create Maximum Quantity Item. Update Lot specific Tracking and Lot No on Item.
        Initialize();
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCodeLotSpecific, false, true);  // SN Specific Tracking - FALSE.
        CreateMQItem(Item, LibraryRandom.RandDec(50, 2) + 50, 0, 0);  // Large Random quantity for Maximum Inventory.
        UpdateItemLotNoTracking(Item, ItemTrackingCodeLotSpecific.Code);

        // Create Production Forecast.
        ForecastQty := CreateProductionForecastSetup(Item."No.", false, ProductionForecastName); // Boolean - FALSE for single Forecast Entry.

        // Create Sales Order. Update Shipment date on Sales Line. Assign Lot Specific Tracking on Sales Line.Page Handler -  AssignLotTrackingAndCheckTrackingQtyPageHandler.
        CreateSalesOrder(SalesHeader, Item."No.", LibraryRandom.RandDec(10, 2));
        ShipmentDate := GetRequiredDate(10, 30, WorkDate());
        UpdateShipmentDateOnSalesLine(SalesHeader."No.", ShipmentDate);
        AssignTrackingOnSalesLine(SalesLine, SalesHeader."No.");

        // Exercise: Calculate Regenerative Plan from Planning Worksheet. Using Page Handler - CalculatePlanPlanWkshRequestPageHandler.
        CalcRegenPlanForPlanWkshPage(Item."No.", Item."No.");

        // Verify: Verify Quantity and Tracking assigned on Requisition Line. Verified in AssignLotTrackingAndCheckTrackingQtyPageHandler.
        VerifyTrackingOnRequisitionLine(Item."No.", 0);
        VerifyRequisitionLineWithDueDate(Item."No.", ForecastQty, WorkDate());
        VerifyRequisitionLineWithDueDate(Item."No.", Item."Maximum Inventory", SelectDateWithSafetyLeadTime(WorkDate(), 1));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanPlanWkshTransferForFRQItem()
    var
        Item: Record Item;
        TransferLine: Record "Transfer Line";
        RequisitionLine: Record "Requisition Line";
        TransferQty: Integer;
        EndDate: Date;
    begin
        // Setup: Create FRQ Item. Create Transfer Order.
        Initialize();
        TransferQty := LibraryRandom.RandInt(10) + 10;  // Random Quantity.
        CreateFRQItem(Item, Item."Replenishment System"::Purchase, TransferQty + 100, TransferQty + 10, TransferQty);  // Quantity proportion required for test.

        // Create Transfer Order.
        CreateTransferOrderWithTransferRoute(TransferLine, Item."No.", LocationYellow.Code, LocationRed.Code, TransferQty);

        // Exercise: Calculate regenerative Plan for Planning Worksheet.
        EndDate := GetRequiredDate(10, 20, WorkDate());  // End Date relative to Workdate.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), EndDate);
        // Verify: Verify lines in Planning Worksheet.
        VerifyRequisitionLineWithLocationActionAndRefOrderType(
          Item."No.", RequisitionLine."Ref. Order Type"::Transfer, LocationRed.Code, RequisitionLine."Action Message"::Cancel, 0, TransferQty, WorkDate());
        VerifyRequisitionLineWithLocationActionAndRefOrderType(
          Item."No.", RequisitionLine."Ref. Order Type"::Purchase, '', RequisitionLine."Action Message"::New, Item."Reorder Quantity", 0,
          SelectDateWithSafetyLeadTime(WorkDate(), 1));
        VerifyRequisitionLineWithLocationActionAndRefOrderType(
          Item."No.", RequisitionLine."Ref. Order Type"::Purchase, '', RequisitionLine."Action Message"::New, Item."Safety Stock Quantity", 0, WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanPlanWkshTransferForMQItem()
    var
        Item: Record Item;
        TransferLine: Record "Transfer Line";
        RequisitionLine: Record "Requisition Line";
        TransferQty: Integer;
        EndDate: Date;
    begin
        // Setup: Create Maximum Quantity Item.
        Initialize();
        CreateMQItem(Item, LibraryRandom.RandDec(5, 2) + 100, 0, 0);  // Reorder Point and Order Multiple not required.
        TransferQty := LibraryRandom.RandInt(10) + 10;  // Random Quantity.

        // Create Transfer Order.
        CreateTransferOrderWithTransferRoute(TransferLine, Item."No.", LocationYellow.Code, LocationRed.Code, TransferQty);

        // Exercise: Calculate regenerative Plan for Planning Worksheet.
        EndDate := GetRequiredDate(10, 20, WorkDate());  // End Date relative to Workdate.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), EndDate);
        // Verify: Verify lines in Planning Worksheet.
        VerifyRequisitionLineWithLocationActionAndRefOrderType(
          Item."No.", RequisitionLine."Ref. Order Type"::Transfer, LocationRed.Code, RequisitionLine."Action Message"::Cancel, 0, TransferQty, WorkDate());
        VerifyRequisitionLineWithLocationActionAndRefOrderType(
          Item."No.", RequisitionLine."Ref. Order Type"::Purchase, '', RequisitionLine."Action Message"::New, Item."Maximum Inventory", 0,
          SelectDateWithSafetyLeadTime(WorkDate(), 1));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanPlanWkshTransferForItemWithNoReorderingPolicy()
    var
        Item: Record Item;
        TransferLine: Record "Transfer Line";
        EndDate: Date;
    begin
        // Setup: Create Item without Reordering policy.
        Initialize();
        LibraryInventory.CreateItem(Item);

        // Create Transfer Order for required locations.
        CreateTransferOrderWithTransferRoute(
          TransferLine, Item."No.", LocationYellow.Code, LocationRed.Code, LibraryRandom.RandInt(10));

        // Exercise: Calculate regenerative Plan for Planning Worksheet.
        EndDate := GetRequiredDate(10, 20, WorkDate());  // End Date relative to Workdate.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), EndDate);

        // Verify: Verify no requisition Line created in Planning Worksheet after running regenerative plan.
        VerifyEmptyRequisitionLine(Item."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanPlanWkshForSalesWithNewOrderDateLFLItem()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        RequisitionLine: Record "Requisition Line";
        EndDate: Date;
    begin
        // Setup: Create Lot for Lot Item with Replenishment - Purchase.
        Initialize();
        CreateLotForLotItem(Item, Item."Replenishment System"::Purchase, LibraryRandom.RandInt(10));

        // Create Sales Order with new Order Date.
        CreateSalesOrder(SalesHeader, Item."No.", LibraryRandom.RandDec(10, 2));
        LibraryVariableStorage.Enqueue(OrderDateChangeMsg);  // Required inside MessageHandler.
        UpdateSalesHeaderOrderDate(SalesHeader);

        // Exercise: Calculate regenerative Plan from Planning Worksheet.
        EndDate := GetRequiredDate(10, 20, WorkDate());  // End Date relative to Workdate.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), EndDate);

        // Verify: Verify Requisition line Due date is not the same as Order date from Sales Line.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        Assert.AreNotEqual(RequisitionLine."Due Date", SalesHeader."Order Date", SameDateErrMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanReqWkshWithSalesAndPositiveAdjOrderItem()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        AdjustmentQuantity: Decimal;
    begin
        // Setup: Create Order Item with Replenishment - Purchase and Post positive adjustment. Create Sales Order.
        Initialize();
        CreateItem(Item, Item."Reordering Policy"::Order, Item."Replenishment System"::Purchase);
        AdjustmentQuantity := CreateAndPostItemJournalLine(Item."No.", ItemJournalLine."Entry Type"::"Positive Adjmt.");
        CreateSalesOrder(SalesHeader, Item."No.", AdjustmentQuantity);

        // Exercise: Calculate Plan from Requisition Worksheet.
        CalculatePlanForRequisitionWorksheet(Item);

        // Verify: Verify Requisition Worksheet lines.
        VerifyRequisitionLineWithDueDate(Item."No.", AdjustmentQuantity, WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanPlanWkshWithSKUAndSalesOnLocationMQItem()
    begin
        // Setup: Calculate Plan from Planning Worksheet and verify no lines generated at Location.
        Initialize();
        CalcPlanWithSKUAndSalesOnLocationMQItem(true);  // Boolean - TRUE for Calculate Regenerative Plan.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanReqWkshWithSKUAndSalesOnLocationMQItem()
    begin
        // Setup: Calculate Plan from Requisition Worksheet and verify no lines generated at Location.
        Initialize();
        CalcPlanWithSKUAndSalesOnLocationMQItem(false);  // Boolean - FALSE for Calculate Plan from Requisition Worksheet.
    end;

    local procedure CalcPlanWithSKUAndSalesOnLocationMQItem(CalcPlanPlanWksh: Boolean)
    var
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        SalesQty: Decimal;
    begin
        // Create MQ Item. Create SKU on Location.
        SalesQty := LibraryRandom.RandDec(5, 2);
        CreateMQItem(Item, SalesQty + 100, SalesQty, SalesQty + 10);  // Maximum Inventory, Reorder Point and Order Multiple.
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, LocationBlue.Code, Item."No.", '');
        UpdateItemInventoryOnLocation(Item."No.", LocationBlue.Code, SalesQty + 5);

        // Create Sales Order on Location.
        CreateSalesOrderWithLocation(Item."No.", SalesQty, LocationBlue.Code);

        // Exercise: Calculate Plan from Planning Worksheet or Requisition Worksheet.
        CalcPlanForPlanAndReqWksh(Item, CalcPlanPlanWksh);

        // Verify : Verify no requisition line exists for the given proportion of quantities at the required Location.
        VerifyEmptyRequisitionLine(Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanPlanWkshWithSKUAndSalesOnLocationOrderItem()
    begin
        // Setup: Calculate Plan from Planning Worksheet and verify worksheet lines generated at required Location.
        Initialize();
        CalcPlanWithSKUAndSalesOnLocationOrderItem(true);  // Boolean - TRUE for Calculate Regenerative Plan.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanReqWkshWithSKUAndSalesOnLocationOrderItem()
    begin
        // Setup: Calculate Plan from Requisition Worksheet and verify worksheet lines generated at required Location.
        Initialize();
        CalcPlanWithSKUAndSalesOnLocationOrderItem(false);  // Boolean - FALSE for Calculate Plan from Requisition Worksheet.
    end;

    local procedure CalcPlanWithSKUAndSalesOnLocationOrderItem(CalcPlanPlanWksh: Boolean)
    var
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        SalesQty: Decimal;
    begin
        // Create Order Item. Create SKU on Location.
        SalesQty := LibraryRandom.RandDec(5, 2);
        CreateItem(Item, Item."Reordering Policy"::Order, Item."Replenishment System"::Purchase);
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, LocationBlue.Code, Item."No.", '');
        UpdateItemInventoryOnLocation(Item."No.", LocationBlue.Code, SalesQty / 2);

        // Create Sales Order on Location.
        CreateSalesOrderWithLocation(Item."No.", SalesQty, LocationBlue.Code);

        // Exercise: Calculate Plan from Planning Worksheet or Requisition Worksheet.
        CalcPlanForPlanAndReqWksh(Item, CalcPlanPlanWksh);

        // Verify: Verify Requisition Worksheet lines at the required Location.
        VerifyRequisitionLineWithDueDate(Item."No.", SalesQty, WorkDate());
        VerifyLocationOnRequisitionLine(Item."No.", LocationBlue.Code);
    end;

    [Test]
    [HandlerFunctions('LotItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationEntryForItemJournalLotTrackingSKUAndLFLItem()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        // Setup: Create Lot for Lot Item with Stockkeeping Unit. Update Lot specific Tracking and Lot No.
        Initialize();
        CreateLotForLotItem(Item, Item."Replenishment System"::Purchase, LibraryRandom.RandInt(10));
        UpdateItemLotTrackingAndSKU(Item, LocationYellow.Code);

        // Create Item Journal With Location.
        CreateItemJournalWithLocation(ItemJournalLine, Item."No.", LocationYellow.Code);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");  // Enqueue for Page Handler - LotItemTrackingPageHandler.

        // Exercise: Assign Lot No on Item Journal Line.
        ItemJournalLine.OpenItemTrackingLines(false);

        // Verify: Verify quantity on Reservation Entry for location.
        VerifyReservationEntry(ReservationEntry, Item."No.", LocationYellow.Code, ItemJournalLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('LotItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure ItemLedgerEntryForPostedItemJournalLotTrackingSKUAndLFLItem()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Create Lot for Lot Item with Stockkeeping Unit. Update Lot specific Tracking and Lot No.
        Initialize();
        CreateLotForLotItem(Item, Item."Replenishment System"::"Prod. Order", LibraryRandom.RandInt(10));
        UpdateItemLotTrackingAndSKU(Item, LocationYellow.Code);

        // Create Item Journal With Location. Assign Lot No on Item Journal Line.
        CreateItemJournalWithLocation(ItemJournalLine, Item."No.", LocationYellow.Code);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");  // Enqueue for Page Handler - LotItemTrackingPageHandler.
        ItemJournalLine.OpenItemTrackingLines(false);

        // Exercise: Post Item Journal Line.
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // Verify: Verify Item Ledger Entry values for location.
        VerifyItemLedgerEntry(
          Item."No.", LocationYellow.Code, ItemJournalLine."Entry Type"::Purchase, ItemJournalLine.Quantity, ItemJournalLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReservationEntryForReleasedProdOrderWithSKUAndLFLItem()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Production Item setup with Lot Tracking and SKU and Verify no reservation takes place for Released Production Order.
        Initialize();
        ProdOrderWithSKUOnReservationEntryLFLItem(ProductionOrder.Status::Released);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReservationEntryForFirmPlannedProdOrderWithSKUAndLFLItem()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Production Item setup with Lot Tracking and SKU and Verify no reservation takes place for Firm Planned Production Order.
        Initialize();
        ProdOrderWithSKUOnReservationEntryLFLItem(ProductionOrder.Status::"Firm Planned");
    end;

    local procedure ProdOrderWithSKUOnReservationEntryLFLItem(Status: Enum "Production Order Status")
    var
        Item: Record Item;
    begin
        // Create Lot for Lot Item with Stockkeeping Unit. Update Lot specific Tracking and Lot No.
        CreateLotForLotItem(Item, Item."Replenishment System"::"Prod. Order", LibraryRandom.RandInt(10));
        UpdateItemLotTrackingAndSKU(Item, LocationYellow.Code);

        // Exercise: Create and Refresh Released or Firm Planned Production Order as required on Location.
        CreateAndRefreshProductionOrderWithLocation(Item."No.", LocationYellow.Code, Status);

        // Verify: Verify no reservation entry created for Item because tracking is not assigned on Production Order.
        VerifyEmptyReservationEntry(Item."No.", LocationYellow.Code);
    end;

    [Test]
    [HandlerFunctions('LotItemTrackingPageHandler,ConfirmHandlerTRUE')]
    [Scope('OnPrem')]
    procedure ReservationEntryForTransferOrderWithLotTrackingSKUAndLFLItem()
    var
        Item: Record Item;
        ReservationEntry: Record "Reservation Entry";
        TransferLine: Record "Transfer Line";
    begin
        // Setup: Create Lot for Lot Item with Stockkeeping Unit. Update Lot specific Tracking and Lot No. Create Transfer Order.
        Initialize();
        CreateLotForLotItem(Item, Item."Replenishment System"::Purchase, LibraryRandom.RandInt(10));
        UpdateItemLotTrackingAndSKU(Item, LocationYellow.Code);
        CreateTransferOrderWithTransferRoute(
          TransferLine, Item."No.", LocationYellow.Code, LocationRed.Code, LibraryRandom.RandDec(5, 2));

        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");  // Enqueue for Page Handler - LotItemTrackingPageHandler.
        LibraryVariableStorage.Enqueue(AvailabilityWarningConfirmationMsg);  // Required inside ConfirmHandler.

        // Exercise: Assign Lot No on Item Tracking Line of Transfer Line.
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);  // Assign Tracking on Page Handler ItemTrackingPageHandler.

        // Verify: Verify quantity and Source ID on Reservation Entry for required locations.
        VerifyReservationEntry(ReservationEntry, Item."No.", LocationYellow.Code, -TransferLine.Quantity);
        ReservationEntry.TestField("Source ID", TransferLine."Document No.");
        VerifyReservationEntry(ReservationEntry, Item."No.", LocationRed.Code, TransferLine.Quantity);
        ReservationEntry.TestField("Source ID", TransferLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('LotItemTrackingPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ItemLedgerEntryForPostedTransferOrderAsShipWithLotTrackingSKUAndLFLItem()
    begin
        // Setup: Create Item setup with Lot Tracking, SKU and Transfer Order setup with tracking. Verify Item Ledger Entry after posting as Ship.
        Initialize();
        ItemLedgerEntryForPostedTransferOrderWithLotTrackingSKUAndLFLItem(false);  // Receive - FALSE.
    end;

    [Test]
    [HandlerFunctions('LotItemTrackingPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ItemLedgerEntryForPostedTransferOrderAsReceiveWithLotTrackingSKUAndLFLItem()
    begin
        // Setup: Create Item setup with Lot Tracking, SKU and Transfer Order setup with tracking. Verify Item Ledger Entry after posting as Receive.
        Initialize();
        ItemLedgerEntryForPostedTransferOrderWithLotTrackingSKUAndLFLItem(true);  // Receive - TRUE.
    end;

    local procedure ItemLedgerEntryForPostedTransferOrderWithLotTrackingSKUAndLFLItem(Receive: Boolean)
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TransferLine: Record "Transfer Line";
        TransferHeader: Record "Transfer Header";
    begin
        // Create Lot for Lot Item with Stockkeeping Unit. Update Lot specific Tracking and Lot No.
        CreateLotForLotItem(Item, Item."Replenishment System"::Purchase, LibraryRandom.RandInt(10));
        UpdateItemLotTrackingAndSKU(Item, LocationYellow.Code);

        // Update Inventory for Item with Lot Tracking.
        CreateItemJournalWithLocation(ItemJournalLine, Item."No.", LocationYellow.Code);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");  // Enqueue for Page Handler - LotItemTrackingPageHandler.
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // Create Transfer Order With Lot specific tracking.
        Item.CalcFields(Inventory);
        CreateTransferOrderWithTransferRoute(
          TransferLine, Item."No.", LocationYellow.Code, LocationRed.Code, Item.Inventory - LibraryRandom.RandDec(5, 2));  // Quantity less than inventory.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");  // Enqueue for Page Handler - LotItemTrackingPageHandler.
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);

        // Exercise: Post Transfer As Ship or As Receive.
        TransferHeader.Get(TransferLine."Document No.");
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, Receive);

        // Verify: Verify Item Ledger Entry for posted Transfer Order.
        VerifyItemLedgerEntry(Item."No.", LocationYellow.Code, ItemJournalLine."Entry Type"::Purchase, Item.Inventory, Item.Inventory);
    end;

    [Test]
    [HandlerFunctions('LotItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationEntryWithCalcRegenPlanAndLotTrackingLFLItem()
    begin
        // Setup.
        Initialize();
        ReservationEntryWithCalcRegenPlanAndLotTracking(true);  // Boolean TRUE for LFL Item
    end;

    [Test]
    [HandlerFunctions('LotItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationEntryWithCalcRegenPlanAndLotTrackingFRQItem()
    begin
        // Setup.
        Initialize();
        ReservationEntryWithCalcRegenPlanAndLotTracking(false);  // Boolean FALSE for FRQ Item.
    end;

    local procedure ReservationEntryWithCalcRegenPlanAndLotTracking(LotForLot: Boolean)
    var
        Item: Record Item;
        ReservationEntry: Record "Reservation Entry";
        RequisitionLine: Record "Requisition Line";
    begin
        // Create Lot for Lot Item or FRQ Item as required with Stockkeeping Unit. Update Lot specific Tracking and Lot No.
        if LotForLot then
            CreateLotForLotItem(Item, Item."Replenishment System"::Purchase, LibraryRandom.RandInt(10))
        else
            CreateFRQItem(
              Item, Item."Replenishment System"::Purchase, LibraryRandom.RandInt(10) + 100, LibraryRandom.RandInt(10) + 10,
              LibraryRandom.RandInt(10));  // Quantity proportion required for test.
        UpdateItemLotTrackingAndSKU(Item, LocationYellow.Code);

        // Calculate Regenerative Plan on Planning Worksheet.
        CalcRegenPlanForPlanWksh(Item."No.");

        // Exercise: Assign Lot No Tracking on Requisition Line.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");  // Enqueue for Page Handler - LotItemTrackingPageHandler.
        RequisitionLine.OpenItemTrackingLines();

        // Verify: Verify quantity on Reservation Entry for location.
        VerifyReservationEntry(ReservationEntry, Item."No.", LocationYellow.Code, Item."Safety Stock Quantity");
    end;

    [Test]
    [HandlerFunctions('AssignSerialTrackingAndCheckTrackingQtyPageHandler,QuantityToCreatePageHandler,ConfirmHandlerTRUE,MessageHandlerWithoutValidate,CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcRegenPlanForProductionOrderAfterChangedDueDate()
    var
        Item: Record Item;
        ChildItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProductionBOMHeader: Record "Production BOM Header";
        ItemTrackingCodeSNSpecific: Record "Item Tracking Code";
        RequisitionLine: Record "Requisition Line";
        ReservationEntry: Record "Reservation Entry";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        Quantity: Integer;
        QuantityPer: Integer;
    begin
        // Setup: Create Item,Item Tracking Code,ProductionBOM. Update Item Tracking Code and Production BOM NO.
        Initialize();
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCodeSNSpecific, true, false);
        CreateItem(Item, Item."Reordering Policy"::Order, Item."Replenishment System"::"Prod. Order");
        CreateItem(ChildItem, Item."Reordering Policy"::Order, Item."Replenishment System"::Purchase);
        UpdateItemSerialNoTracking(Item, ItemTrackingCodeSNSpecific.Code);
        QuantityPer := LibraryRandom.RandIntInRange(2, 5); // QantityPer should not be one.
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, ChildItem."No.", QuantityPer);
        Item.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item.Modify(true);

        // Create Sales Order with Item Tracking. Create Production Order from Sales Order.
        Quantity := LibraryRandom.RandIntInRange(2, 10); // Quantity should not be one
        CreateSalesOrder(SalesHeader, Item."No.", Quantity);
        AssignTrackingOnSalesLine(SalesLine, SalesHeader."No.");
        LibraryManufacturing.CreateProductionOrderFromSalesOrder(
            SalesHeader, "Production Order Status"::"Firm Planned", "Create Production Order Type"::ItemOrder);

        SelectProdOrderLine(ProdOrderLine, Item."No.");
        ProdOrderLine.Validate("Due Date", CalcDate('<-2D>', WorkDate())); // Change Due Date on Firmed Prod Order Line.
        ProdOrderLine.Modify(true);

        ProductionOrder.Get(ProductionOrder.Status::"Firm Planned", ProdOrderLine."Prod. Order No.");
        ProductionOrder.Validate("Due Date", CalcDate('<-2D>', WorkDate())); // Change Due Date on Firmed Prod Order Header.
        ProductionOrder.Modify(true);

        // Exercise: Calculate Regenerative Plan from Planning Worksheet after changed Due Date on Production Order.
        CalcRegenPlanForPlanWkshPage(Item."No.", ChildItem."No.");

        // Verify: Verify Quantity on Planning Worksheet(Requisition Line) for Action Message with Reschedule & New.
        FilterReservationEntry(ReservationEntry, Item."No.", '');
        ReservationEntry.FindFirst();

        SelectRequisitionLineForActionMessage(RequisitionLine, Item."No.", RequisitionLine."Action Message"::Reschedule);
        VerifyRequisitionLine(RequisitionLine, Abs(ReservationEntry."Quantity (Base)"), 0,
          RequisitionLine."Ref. Order Type"::"Prod. Order");

        SelectRequisitionLineForActionMessage(RequisitionLine, ChildItem."No.", RequisitionLine."Action Message"::New);
        RequisitionLine.CalcSums(Quantity, "Original Quantity");
        RequisitionLine.TestField(Quantity, Quantity * QuantityPer);
        RequisitionLine.TestField("Original Quantity", 0);
        RequisitionLine.TestField("Ref. Order Type", RequisitionLine."Ref. Order Type"::Purchase);
        Assert.RecordCount(RequisitionLine, Quantity);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GrossReqAndScheduledRecAfterSalesOrderAndPlanWkshRegenPlan()
    var
        ChildItem: Record Item;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        BOMBuffer: Record "BOM Buffer";
    begin
        // Check quantity of "Gross Requirement" and "Scheduled Receipts" in BOM Tree
        // in case of Sales Order and Planning Worksheet's Regenerative Plan
        Initialize();
        CreateOrderItemSetup(ChildItem, Item);

        CreateSalesOrder(SalesHeader, Item."No.", LibraryRandom.RandInt(10));
        CalcRegenPlanForPlanWkshPage(Item."No.", ChildItem."No.");

        SelectSalesOrderLine(SalesLine, SalesHeader."No.");
        Item.SetFilter("No.", '%1|%2', Item."No.", ChildItem."No.");
        CreateBOMTree(BOMBuffer, Item, WorkDate());
        VerifyGrossReqAndScheduledRecOnBOMTree(BOMBuffer, Item."No.", 0, SalesLine.Quantity);
        VerifyGrossReqAndScheduledRecOnBOMTree(BOMBuffer, ChildItem."No.", 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanWkshForMQItemWithSKU()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        OrderMultiple: Integer;
    begin
        // [SCENARIO] Calculate Regenerative Plan for Maximum Qty of Item with SKU while "Location Mandatory" is false should create requisition line
        // [GIVEN] Create Item with SKU and Maximum Qty. Reordering Policy.
        Initialize();
        OrderMultiple := LibraryRandom.RandInt(10);
        CreateMQItem(Item, LibraryRandom.RandInt(10) * OrderMultiple, 0, OrderMultiple); // Reorder Point must be 0 to repro the bug.

        // [WHEN] Calculate Regenerative Plan on Planning Worksheet.
        CreateSKUAndCalcRegenPlan(Item."No.", LocationBlue.Code);

        // [THEN] ReqLine is created. Verify Location, Quantity and Action Message on Requisition Line.
        VerifyReqLine(Item."No.", LocationBlue.Code, Item."Maximum Inventory", RequisitionLine."Action Message"::New);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanWkshForFRQItemWithSKU()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        // Calculate Regenerative Plan for Fixed Reorder Qty Item with SKU. Verify requisition line will be generated.
        // Setup: Create Item with Fixed Reorder Qty. Reordering Policy.
        Initialize();
        CreateFRQItem(Item, Item."Replenishment System"::Purchase, LibraryRandom.RandInt(10), 0, 0); // Reorder Point and Safety Stock Quantity must be 0 to repro the bug.

        // Exercise: Create SKU for Item and calculate Regenerative Plan on Planning Worksheet.
        CreateSKUAndCalcRegenPlan(Item."No.", LocationBlue.Code);

        // Verify: Verify Location, Quantity and Action Message on Requisition Line.
        VerifyReqLine(Item."No.", LocationBlue.Code, Item."Reorder Quantity", RequisitionLine."Action Message"::New);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler,ConfirmHandlerTRUE')]
    [Scope('OnPrem')]
    procedure CalcRegenPlanWkshForProductionForecastName()
    var
        Item: Record Item;
        ProductionForecastName: Record "Production Forecast Name";
        RequisitionLine: Record "Requisition Line";
        ForecastQty: Decimal;
    begin
        // Verify no Requisition Line generated when Forecast Entry was removed

        // Setup: Create a new item and Producation Forecast.
        Initialize();
        CreateItem(Item, Item."Reordering Policy"::Order, Item."Replenishment System"::Purchase);
        ForecastQty := CreateProductionForecastSetup(Item."No.", false, ProductionForecastName); // FALSE for single Forecast Entry.

        // Calculate regenerative planning for the item. Verify quantity of the item on Requisition Line
        CalcRegenPlanForPlanWkshPage(Item."No.", Item."No.");
        VerifyRequisitionLineQty(Item."No.", ForecastQty, RequisitionLine."Ref. Order Type"::Purchase);

        // Exercise: Delete the created Producation Forecast and re-calculate regenerative planning for the item.
        DeleteProductionForecast(ProductionForecastName);
        CalcRegenPlanForPlanWkshPage(Item."No.", Item."No.");

        // Verify: Verify no requistion line exists for the item.
        VerifyEmptyRequisitionLine(Item."No.");
    end;

    [Test]
    [HandlerFunctions('LotItemTrackingPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure CalcRegenPlanForCancelExcessReplenishmentWithTracking()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        // Calculate Regenerative Plan for excess replenishment with item tracking. Verify Cancel requisition line will be generated.

        // Setup: Create Lot for Lot Item with Stockkeeping Unit. Update Lot specific Tracking and Lot No.
        Initialize();
        CreateLotForLotItem(Item, Item."Replenishment System"::Purchase, 0);
        UpdateItemLotTrackingAndSKU(Item, LocationYellow.Code);

        // Update Inventory for Item with Lot Tracking.
        CreateAndPostItemJournalWithLotTracking(Item."No.", LocationYellow.Code);
        Item.CalcFields(Inventory);

        // Create Transfer Order With Lot specific tracking.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries"); // Enqueue for Page Handler - LotItemTrackingPageHandler.
        CreateTransferOrderWithTracking(Item."No.", LocationYellow.Code, LocationRed.Code, Item.Inventory);

        // Create Purchase Order for Item
        CreatePurchaseOrderWithLocation(Item."No.", Item.Inventory, LocationYellow.Code);

        // Exercise: Calculate Regenerative Plan in Planning Worksheet
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), CalcDate('<CY>', WorkDate()));

        // Verify: A requisition line generated for cancel purchase replenishment
        SelectRequisitionLineForActionMessage(RequisitionLine, Item."No.", RequisitionLine."Action Message"::Cancel);
        Assert.AreEqual(Item.Inventory, RequisitionLine.Quantity, QuantityNotCorrectErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanWkshForMOQItemWithLowILEs()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        MOQ: Decimal;
        Delta: Decimal;
    begin
        // [SCENARIO 109058] Calculate Regenerative Plan for Item with "Maximum Order Quantity" and two supply ILEs, each having Quantity greater than "Maximum Order Quantity".

        // [GIVEN] Item With Lot-for-lot reordering policy, 'Maximum Order Quantity' = 'X'
        Initialize();
        Delta := LibraryRandom.RandDecInDecimalRange(1, 10, 2);
        MOQ := LibraryRandom.RandDecInDecimalRange(20, 100, 2);
        CreateMOQItem(Item, MOQ);
        // [GIVEN] Add two Inventory entries, each with Quantity = 'I' > 'X'.
        AddInventory(Item."No.", MOQ + Delta, '');
        AddInventory(Item."No.", MOQ + Delta, '');

        // [GIVEN] Sales Order with a line having Quantity = 2 * 'I'
        CreateSalesOrder(SalesHeader, Item."No.", 2 * (MOQ + Delta));

        // [WHEN] Calculating Regenerative Plan
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<-CM>', WorkDate()), CalcDate('<CY>', WorkDate()));

        // [THEN] No Requisition Line is created
        VerifyEmptyRequisitionLine(Item."No.");
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure UpdateLocationFilterOnProductionForecastPageAndCalcRegenPlan()
    var
        Location: Record Location;
        Item: Record Item;
        ProductionForecastName: Record "Production Forecast Name";
        RequisitionLine: Record "Requisition Line";
        DemandForecastCard: TestPage "Demand Forecast Card";
        Qty: Decimal;
    begin
        // [FEATURE] [Production Forecast]
        // [SCENARIO] Calculate regenerative plan from Demand Forecast Page after updating quantity to 0 and changing Location Code to blank.
        Initialize();

        // [GIVEN] Item "I", Location "L", Production Forecast "F", Quantity "Q", Date "D".
        CreateItem(Item, Item."Reordering Policy"::Order, Item."Replenishment System"::Purchase);

        LibraryWarehouse.CreateLocation(Location);
        LibraryManufacturing.CreateProductionForecastName(ProductionForecastName);
        Qty := LibraryRandom.RandIntInRange(10, 20);

        DemandForecastCard.OpenEdit();
        DemandForecastCard.GoToRecord(ProductionForecastName);
        DemandForecastCard."Forecast By Locations".SetValue(true);

        // [GIVEN] On Demand Forecast Page for Forecast "F" set Location Filter "L" and for Item "I" set Quantity "Q" for Date "D".
        DemandForecastCard."Location Filter".SetValue(Location.Code);
        UpdateDemandForecastVariantMatrixField(DemandForecastCard, Item, Qty);

        // [GIVEN] Revert previously created entry - on Production Forecast Page for Forecast "F" set Location Filter "L" and for Item "I" set Quantity 0 for Date "D".
        UpdateDemandForecastVariantMatrixField(DemandForecastCard, Item, 0);
        DemandForecastCard.Close();

        // [GIVEN] On Production Forecast Page for Forecast "F" disable forecast by locations and for Item "I" set Quantity "Q" for Date "D".
        DemandForecastCard.OpenEdit();
        DemandForecastCard.GoToRecord(ProductionForecastName);
        DemandForecastCard."Forecast By Locations".SetValue(false);
        UpdateDemandForecastVariantMatrixField(DemandForecastCard, Item, Qty);

        // [WHEN]  Calculate regenerative plan for the "I" using "F"
        LibraryPlanning.SetDemandForecast(ProductionForecastName.Name);
        CalcRegenPlanForPlanWkshPage(Item."No.", Item."No.");

        // [THEN]  Single Requisition Line is created, quantity is "Q", planning Location Code is blank.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        Assert.RecordCount(RequisitionLine, 1);
        RequisitionLine.FindFirst();
        RequisitionLine.TestField("Location Code", '');
        RequisitionLine.TestField(Quantity, Qty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningWorksheetPlansBlanketSalesOrdersWithDiffShipmentDates()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Qty: Integer;
    begin
        // [FEATURE] [Planning Worksheet] [Blanket Sales Order]
        // [SCENARIO 374729] Planning Worksheet plans all lines in blankes sales orders when 2 blanket orders for the same item have different shipment dates

        // [GIVEN] Item with "Purchase" replenishment system
        Qty := LibraryRandom.RandInt(10);
        CreateItem(Item, Item."Reordering Policy"::Order, Item."Replenishment System"::Purchase);
        // [GIVEN] Blanket sales order with 2 lines: 1 - "Shipment Date" = WorkDate(), 2 - "Shipment Date" = WorkDate() + 1, Quantity = "X" in both lines
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order", LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLineWithShipmentDate(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", WorkDate(), Qty);
        LibrarySales.CreateSalesLineWithShipmentDate(
          SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", CalcDate('<1D>', WorkDate()), Qty);

        // [GIVEN] Second blanket sales order. 1 line: Quantity = "X", "Shipment Date" = WORKDATE
        SalesHeader.Init();
        SalesHeader."No." := '';
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order", SalesHeader."Sell-to Customer No.");
        LibrarySales.CreateSalesLineWithShipmentDate(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", WorkDate(), Qty);

        // [WHEN] Claculate regenerative plan from planning worksheet
        CalcRegenPlanForPlanWksh(Item."No.");

        // [THEN] 2 purchase orders are planned: 2 * "X" pcs are planned on WorkDate(), "X" pcs on WorkDate() + 1
        VerifyRequisitionLineWithDueDate(Item."No.", Qty * 2, WorkDate());
        VerifyRequisitionLineWithDueDate(Item."No.", Qty, CalcDate('<1D>', WorkDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateRegenerativePlanWithComponentsAtLocationAndSKU()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Planning Worksheet] [Stockkeeping Unit]
        // [SCENARIO 375977] Calculate Regenerative Plan should consider Components at Location if SKU exists for another Location
        Initialize();

        // [GIVEN] Setup with Components at Location "X"
        LibraryManufacturing.SetComponentsAtLocation(LocationBlue.Code);
        UpdateLocationMandatory(false);

        // [GIVEN] Item "I" with "Fixed Reorder Qty." and "Reorder Quantity" = "Q"
        // [GIVEN] SKU for Item "I" at Location "Y"
        Qty := LibraryRandom.RandDec(10, 2);
        CreateFRQItem(Item, Item."Replenishment System"::Purchase, Qty + 100, Qty + 10, Qty);

        // [WHEN] Calculate Regenerative Plan
        CreateSKUAndCalcRegenPlan(Item."No.", LocationYellow.Code);

        // [THEN] Requisition Line for Item "I" is created with "Reorder Quantity" = "Q" at Location "X"
        FilterOnRequisitionLine(RequisitionLine, Item."No.");
        RequisitionLine.SetRange("Location Code", LocationBlue.Code);
        RequisitionLine.FindFirst();
        Assert.AreEqual(Qty + 100, RequisitionLine.Quantity, QuantityNotCorrectErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateRegenerativePlanWithLocationMandatoryAndNoSKU()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Planning Worksheet] [Stockkeeping Unit]
        // [SCENARIO] Calculate Regenerative Plan should not create Requisituion line if SKU does not exist while "Location Mandatory" is true
        Initialize();

        // [GIVEN] Inventory Setup with Location Mandatory = TRUE
        UpdateLocationMandatory(true);
        LibraryManufacturing.SetComponentsAtLocation('');

        // [GIVEN] Item "I" with no SKU
        Qty := LibraryRandom.RandDec(10, 2);
        CreateFRQItem(Item, Item."Replenishment System"::Purchase, Qty + 100, Qty + 10, Qty);

        // [WHEN] Calculate Regenerative Plan
        CalcRegenPlanForPlanWksh(Item."No.");

        // [THEN] Requisition Line for Item "I" is not created
        FilterOnRequisitionLine(RequisitionLine, Item."No.");
        Assert.RecordIsEmpty(RequisitionLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateRegenerativePlanWithNoSKUAndLocationMandatoryFalse()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Planning Worksheet] [Stockkeeping Unit]
        // [SCENARIO] Calculate Regenerative Plan should create Requisituion line if SKU does not exist while "Location Mandatory" is false
        Initialize();

        // [GIVEN] Inventory Setup with Location Mandatory = FALSE
        UpdateLocationMandatory(false);
        LibraryManufacturing.SetComponentsAtLocation('');

        // [GIVEN] Item "I" with no SKU
        Qty := LibraryRandom.RandDec(10, 2);
        CreateFRQItem(Item, Item."Replenishment System"::Purchase, Qty + 100, Qty + 10, Qty);

        // [WHEN] Calculate Regenerative Plan
        CalcRegenPlanForPlanWksh(Item."No.");

        // [THEN] Requisition Line for Item "I" is created with "Reorder Quantity" = "Q" at Location ""
        FilterOnRequisitionLine(RequisitionLine, Item."No.");
        RequisitionLine.SetRange("Location Code", '');
        RequisitionLine.FindFirst();
        Assert.AreEqual(Qty + 100, RequisitionLine.Quantity, QuantityNotCorrectErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateRegenerativePlanWithSKUOnComponentsLocation()
    var
        Item: Record Item;
        Location: Record Location;
        RequisitionLine: Record "Requisition Line";
        StockkeepingUnit: Record "Stockkeeping Unit";
        Qty: Decimal;
    begin
        // [FEATURE] [Stockkeeping Unit]
        // [SCENARIO 377474] Requisition should be planned for an item that has stockkeeping unit defined on manufacturing components location

        // [GIVEN] Item "I" with reordering policy = "Fixed Reorder Qty."
        CreateItem(Item, Item."Reordering Policy"::"Fixed Reorder Qty.", Item."Replenishment System"::Purchase);

        // [GIVEN] Stockkeeping unit for item "I", location "L", reordering policy = "Lot-for-Lot"
        LibraryWarehouse.CreateLocation(Location);
        CreateStockkeepingUnitWithReorderingPolicy(Location.Code, Item."No.", '', StockkeepingUnit."Reordering Policy"::"Lot-for-Lot");

        // [GIVEN] Create sales order: Item = "I", location = "L", Quantity = "Q"
        Qty := LibraryRandom.RandInt(100);
        CreateSalesOrderWithLocation(Item."No.", Qty, Location.Code);

        // [GIVEN] Set "Components at Location" = "L"
        LibraryManufacturing.SetComponentsAtLocation(Location.Code);

        // [WHEN] Calculate regenerative plan from planning worksheet
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // [THEN] Requisition line is created: "Q" pcs of item "I"
        SelectRequisitionLine(RequisitionLine, Item."No.");
        RequisitionLine.TestField(Quantity, Qty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateRegenerativePlanWithSKUOnComponentsLocationAndVariant()
    var
        Item: Record Item;
        Location: Record Location;
        ItemVariant: Record "Item Variant";
        RequisitionLine: Record "Requisition Line";
        StockkeepingUnit: Record "Stockkeeping Unit";
        Qty: Decimal;
    begin
        // [FEATURE] [Stockkeeping Unit]
        // [SCENARIO 377474] Requisition should be planned for an item that has stockkeeping unit defined on manufacturing components location with variant

        // [GIVEN] Item "I" with reordering policy = "Fixed Reorder Qty."
        CreateItem(Item, Item."Reordering Policy"::"Fixed Reorder Qty.", Item."Replenishment System"::Purchase);

        // [GIVEN] Stockkeeping unit for item "I", location "L", variant "V", reordering policy = "Lot-for-Lot"
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateVariant(ItemVariant, Item);

        CreateStockkeepingUnitWithReorderingPolicy(
          Location.Code, Item."No.", ItemVariant.Code, StockkeepingUnit."Reordering Policy"::"Lot-for-Lot");

        // [GIVEN] Create sales order: Item = "I", location = "L", Variant = "V", Quantity = "Q"
        Qty := LibraryRandom.RandInt(100);
        CreateSalesOrderWithLocationAndVariant(Item."No.", Qty, Location.Code, ItemVariant.Code);

        // [GIVEN] Set "Components at Location" = "L"
        LibraryManufacturing.SetComponentsAtLocation(Location.Code);

        // [WHEN] Calculate regenerative plan from planning worksheet
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // [THEN] Requisition line is created: "Q" pcs of item "I"
        SelectRequisitionLine(RequisitionLine, Item."No.");
        RequisitionLine.TestField(Quantity, Qty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyPlannedForBlanketOrderAndLinkedToItsLastLinesSalesOrderIsNotDuplicated()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        QtyToShipCoeffs: Text;
    begin
        // [FEATURE] [Planning Worksheet] [Blanket Sales Order]
        // [SCENARIO 202519] Supply planning for Blanket Sales Order with 3 lines and a Sales Order created out of its 2-nd and 3-rd line, is performed with a consideration of this Sales Order - the demands are not duplicated.
        Initialize();
        LibrarySales.SetStockoutWarning(false);

        // [GIVEN] Item "I" with reordering policy = "Order".
        CreateItem(Item, Item."Reordering Policy"::Order, Item."Replenishment System"::Purchase);

        // [GIVEN] Blanket Sales Order "BSO" that has 3 lines with item "I" and various qtys. and shipment dates.
        // [GIVEN] "Qty. to Ship" on the 1-st line of "BSO" is set to 0.
        // [GIVEN] Sales Order is created from "BSO" and includes its 2-nd and 3-rd line.
        QtyToShipCoeffs := '0,1,1';
        CreateSalesOrdersFromBlanketSalesOrderLines(SalesHeader, Item."No.", QtyToShipCoeffs);

        // [WHEN] Calculate Regenerative Plan for the item "I".
        CalcRegenPlanForPlanWksh(Item."No.");

        // [THEN] Three requisition lines are created.
        // [THEN] Each planned supply line meets required quantity on required shipment date.
        VerifyRequisitionLinesAgainstSalesLines(SalesHeader, Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyPlannedForBlanketOrderAndLinkedToItsFirstLineSalesOrderIsNotDuplicated()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        QtyToShipCoeffs: Text;
    begin
        // [FEATURE] [Planning Worksheet] [Blanket Sales Order]
        // [SCENARIO 202519] Supply planning for Blanket Sales Order with 3 lines and a Sales Order created out of its 1-st line, is performed with a consideration of this Sales Order - the demands are not duplicated.
        Initialize();
        LibrarySales.SetStockoutWarning(false);

        // [GIVEN] Item "I" with reordering policy = "Order".
        CreateItem(Item, Item."Reordering Policy"::Order, Item."Replenishment System"::Purchase);

        // [GIVEN] Blanket Sales Order "BSO" that has 3 lines with item "I" and various qtys. and shipment dates.
        // [GIVEN] "Qty. to Ship" on the 2-nd and 3-rd line of "BSO" is set to 0.
        // [GIVEN] Sales Order is created from "BSO" and includes its 1-st line.
        QtyToShipCoeffs := '1,0,0';
        CreateSalesOrdersFromBlanketSalesOrderLines(SalesHeader, Item."No.", QtyToShipCoeffs);

        // [WHEN] Calculate Regenerative Plan for the item "I".
        CalcRegenPlanForPlanWksh(Item."No.");

        // [THEN] Three requisition lines are created.
        // [THEN] Each planned supply line meets required quantity on required shipment date.
        VerifyRequisitionLinesAgainstSalesLines(SalesHeader, Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyPlannedForBlanketOrderAndLinkedToItsFirstAndLastLineSalesOrderIsNotDuplicated()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        QtyToShipCoeffs: Text;
    begin
        // [FEATURE] [Planning Worksheet] [Blanket Sales Order]
        // [SCENARIO 202519] Supply planning for Blanket Sales Order with 3 lines and a Sales Order created out of its 1-st and 3-rd line, is performed with a consideration of this Sales Order - the demands are not duplicated.
        Initialize();
        LibrarySales.SetStockoutWarning(false);

        // [GIVEN] Item "I" with reordering policy = "Order".
        CreateItem(Item, Item."Reordering Policy"::Order, Item."Replenishment System"::Purchase);

        // [GIVEN] Blanket Sales Order "BSO" that has 3 lines with item "I" and various qtys. and shipment dates.
        // [GIVEN] "Qty. to Ship" on the 2-nd line of "BSO" is set to 0.
        // [GIVEN] Sales Order is created from "BSO" and includes its 1-st and 3-rd line.
        QtyToShipCoeffs := '1,0,1';
        CreateSalesOrdersFromBlanketSalesOrderLines(SalesHeader, Item."No.", QtyToShipCoeffs);

        // [WHEN] Calculate Regenerative Plan for the item "I".
        CalcRegenPlanForPlanWksh(Item."No.");

        // [THEN] Three requisition lines are created.
        // [THEN] Each planned supply line meets required quantity on required shipment date.
        VerifyRequisitionLinesAgainstSalesLines(SalesHeader, Item."No.");
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshWithStartingDateRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcRegenPlanWkshForProductionForecastWithNonWorkingStartingDate()
    var
        Location: Record Location;
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        ProductionForecastName: Record "Production Forecast Name";
        CalendarCode: Code[10];
        ForecastQty: Decimal;
        StartingDate: Date;
        NWDates: Integer;
    begin
        // [FEATURE] [Production Forecast] [Calendar]
        // [SCENARIO 382413] When "Forecast Date" is equal to "Starting Date" in regenerative plan calculating and this date is non working result "Requisition Line"."Due Date" is moved back to previous working date.

        Initialize();

        // [GIVEN] "Starting Date" "SD" for regenerative plan calculating.
        StartingDate := CalcDate('<CM + 1M +1D>', WorkDate());
        NWDates := LibraryRandom.RandInt(5);

        // [GIVEN] Base Calendar "BC" with "ND" Nonworking Days in "BC" before "SD" including "SD".
        CalendarCode := CreateBaseCalendarAndChanges(StartingDate, NWDates);

        // [GIVEN] Location "L" with "Base Calendar Code" = "BC".
        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("Base Calendar Code", CalendarCode);
        Location.Modify(true);

        // [GIVEN] Item "I" with reordering policy = "Lot-for-Lot" and Stockkeeping unit for "I" at "L".
        CreateItem(Item, Item."Reordering Policy"::"Lot-for-Lot", Item."Replenishment System"::Purchase);
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, Location.Code, Item."No.", '');

        // [GIVEN] Production Forecast for "I" with entry with "Forecast Date" = "SD" and Quantity "Q".
        ForecastQty := CreateProductionForecastSetupAtDate(ProductionForecastName, Item."No.", StartingDate);

        // [WHEN] Calculate regenerative plan from planning worksheet with "Starting Date" "SD"
        CalcRegenPlanForPlanWkshPageWithStartingDate(Item."No.", Item."No.", StartingDate);

        // [THEN] Requisition line is created: quantity "Q" of item "I" with "Due Date" = "SD" - "ND"
        VerifyRequisitionLineWithDueDate(Item."No.", ForecastQty, StartingDate - NWDates);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerWithoutValidate')]
    [Scope('OnPrem')]
    procedure RescheduleCheckMultiLevelReservationMovingProductionOrderDueDateBackward()
    var
        TopLevelItem: Record Item;
        Level1Item: Record Item;
        Level2Item: Record Item;
        SalesHeader: Record "Sales Header";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Production Order] [Reservation] [Regenerative Plan]
        // [SCENARIO 205633] Having Sales Order as demand and Production Order as Supply after moving Production Order Due Date backward and rescheduling the multi-level reservation of production order components must be saved

        Initialize();

        // [GIVEN] Production Item with 3-level structure: top-level, level-1, level-2 - corresponding Items: "I0", "I1", "I2";
        // [GIVEN] "I0", "I1", "I2" have "Replenishment System" = "Prod. Order" and "Manufacturing Policy" = "Make-to-Order"
        // [GIVEN] "I0" has "Reordering Policy" = "Lot-for-Lot" and "Lot Accumulation Period" "LAP" and "Rescheduling Period" "RP" sufficient for rescheduling;
        // [GIVEN] "I1" and "I2" have "Reordering Policy" = Order;
        // [GIVEN] "I1" has "I2" as the "Production BOM", "I0" has "I1" as the "Production BOM";
        // [GIVEN] Sales Order "SO" for "I0" at Location "L" with "Shipment Date" SD as a demand;
        // [GIVEN] Calculate Regenerative Plan for "I0", "I1", "I2" at "L" and Carry Out Messages = new to create Production Order "PO" as a supply;
        CreateSalesOrderAndFirmPlannedProductionOrderAsDemandAndSupply(
          TopLevelItem, Level1Item, Level2Item, SalesHeader, LibraryRandom.RandDateFromInRange(WorkDate(), 7, 14), '<1Y>');

        // [GIVEN] Update "PO" "Due Date" backward (inside "LAP" and "RP") and refresh "PO";
        UpdateItemFirmPlannedProductionOrderDueDate(TopLevelItem."No.", -LibraryRandom.RandInt(5));

        // [GIVEN] Calculate Regenerative Plan for "I0", "I1", "I2" at "L", result proposed messages = Reschedule;
        // [WHEN] Carry Out Messages
        PlanWrkShtCalcRegenPlanAndCarryOutActionMessage(
          StrSubstNo('%1|%2|%3', TopLevelItem."No.", Level1Item."No.", Level2Item."No."),
          CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', SalesHeader."Shipment Date"), RequisitionLine."Action Message"::Reschedule);

        // [THEN] "I1" and "I2" each have 2 "Reservation Entry" with "Reservation Status" = Reservation at "L", "Source Type" "Prod. Order Line" or "Prod. Order Component".
        VerifyReservationEntryPairInsideProductionOrder(Level1Item."No.", Level2Item."No.", SalesHeader."Location Code");
    end;

    [Test]
    [HandlerFunctions('MessageHandlerWithoutValidate')]
    [Scope('OnPrem')]
    procedure RescheduleCheckMultiLevelReservationMovingProductionOrderDueDateForward()
    var
        TopLevelItem: Record Item;
        Level1Item: Record Item;
        Level2Item: Record Item;
        SalesHeader: Record "Sales Header";
        RequisitionLine: Record "Requisition Line";
        UpdatedDueDate: Date;
    begin
        // [FEATURE] [Production Order] [Reservation] [Regenerative Plan]
        // [SCENARIO 205633] Having Sales Order as demand and Production Order as Supply after moving Production Order Due Date forward and rescheduling the multi-level reservation of production order components must be saved

        Initialize();

        // [GIVEN] Production Item with 3-level structure: top-level, level-1, level-2 - corresponding Items: "I0", "I1", "I2";
        // [GIVEN] "I0", "I1", "I2" have "Replenishment System" = "Prod. Order" and "Manufacturing Policy" = "Make-to-Order"
        // [GIVEN] "I0" has "Reordering Policy" = "Lot-for-Lot" and "Lot Accumulation Period" "LAP" and "Rescheduling Period" "RP" sufficient for rescheduling;
        // [GIVEN] "I1" and "I2" have "Reordering Policy" = Order;
        // [GIVEN] "I1" has "I2" as the "Production BOM", "I0" has "I1" as the "Production BOM";
        // [GIVEN] Sales Order "SO" for "I0" at Location "L" with "Shipment Date" SD as a demand;
        // [GIVEN] Calculate Regenerative Plan for "I0", "I1", "I2" at "L" and Carry Out Messages = new to create Production Order "PO" as a supply;
        CreateSalesOrderAndFirmPlannedProductionOrderAsDemandAndSupply(
          TopLevelItem, Level1Item, Level2Item, SalesHeader, LibraryRandom.RandDateFromInRange(WorkDate(), 7, 14), '<1Y>');

        // [GIVEN] Update "PO" "Due Date" forward (inside "LAP" and "RP") and refresh "PO";
        UpdatedDueDate := UpdateItemFirmPlannedProductionOrderDueDate(TopLevelItem."No.", LibraryRandom.RandInt(5));

        // [GIVEN] Calculate Regenerative Plan for "I0", "I1", "I2" at "L", result proposed messages = Reschedule;
        // [WHEN] Carry Out Messages
        PlanWrkShtCalcRegenPlanAndCarryOutActionMessage(
          StrSubstNo('%1|%2|%3', TopLevelItem."No.", Level1Item."No.", Level2Item."No."),
          CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', UpdatedDueDate), RequisitionLine."Action Message"::Reschedule);

        // [THEN] "I1" and "I2" each have 2 "Reservation Entry" with "Reservation Status" = Reservation at "L", "Source Type" "Prod. Order Line" or "Prod. Order Component".
        VerifyReservationEntryPairInsideProductionOrder(Level1Item."No.", Level2Item."No.", SalesHeader."Location Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RescheduleCheckMultiLevelReservationMovingSalesOrderDueDateBackward()
    var
        TopLevelItem: Record Item;
        Level1Item: Record Item;
        Level2Item: Record Item;
        SalesHeader: Record "Sales Header";
        RequisitionLine: Record "Requisition Line";
        SavedShipmentDate: Date;
    begin
        // [FEATURE] [Production Order] [Reservation] [Regenerative Plan]
        // [SCENARIO 205633] Having Sales Order as demand and Production Order as Supply after moving Sales Order Shipment Date backward and rescheduling the multi-level reservation of production order components must be saved

        Initialize();

        // [GIVEN] Production Item with 3-level structure: top-level, level-1, level-2 - corresponding Items: "I0", "I1", "I2";
        // [GIVEN] "I0", "I1", "I2" have "Replenishment System" = "Prod. Order" and "Manufacturing Policy" = "Make-to-Order"
        // [GIVEN] "I0" has "Reordering Policy" = "Lot-for-Lot" and "Lot Accumulation Period" "LAP" and "Rescheduling Period" "RP" sufficient for rescheduling;
        // [GIVEN] "I1" and "I2" have "Reordering Policy" = Order;
        // [GIVEN] "I1" has "I2" as the "Production BOM", "I0" has "I1" as the "Production BOM";
        // [GIVEN] Sales Order "SO" for "I0" at Location "L" with "Shipment Date" SD as a demand;
        // [GIVEN] Calculate Regenerative Plan for "I0", "I1", "I2" at "L" and Carry Out Messages = new to create Production Order "PO" as a supply;
        CreateSalesOrderAndFirmPlannedProductionOrderAsDemandAndSupply(
          TopLevelItem, Level1Item, Level2Item, SalesHeader, LibraryRandom.RandDateFromInRange(WorkDate(), 7, 14), '<1Y>');

        // [GIVEN] Update "SO" "Shipment Date" backward (inside "LAP" and "RP");
        SavedShipmentDate := SalesHeader."Shipment Date";
        UpdateSalesHeaderShipmentDate(SalesHeader, -LibraryRandom.RandInt(5));

        // [GIVEN] Calculate Regenerative Plan for "I0", "I1", "I2" at "L", result proposed messages = Reschedule;
        // [WHEN] Carry Out Messages
        PlanWrkShtCalcRegenPlanAndCarryOutActionMessage(
          StrSubstNo('%1|%2|%3', TopLevelItem."No.", Level1Item."No.", Level2Item."No."),
          CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', SavedShipmentDate), RequisitionLine."Action Message"::Reschedule);

        // [THEN] "I1" and "I2" each have 2 "Reservation Entry" with "Reservation Status" = Reservation at "L", "Source Type" "Prod. Order Line" or "Prod. Order Component".
        VerifyReservationEntryPairInsideProductionOrder(Level1Item."No.", Level2Item."No.", SalesHeader."Location Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RescheduleCheckMultiLevelReservationMovingSalesOrderDueDateForward()
    var
        TopLevelItem: Record Item;
        Level1Item: Record Item;
        Level2Item: Record Item;
        SalesHeader: Record "Sales Header";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Production Order] [Reservation] [Regenerative Plan]
        // [SCENARIO 205633] Having Sales Order as demand and Production Order as Supply after moving Sales Order Shipment Date forward and rescheduling the multi-level reservation of production order components must be saved

        Initialize();

        // [GIVEN] Production Item with 3-level structure: top-level, level-1, level-2 - corresponding Items: "I0", "I1", "I2";
        // [GIVEN] "I0", "I1", "I2" have "Replenishment System" = "Prod. Order" and "Manufacturing Policy" = "Make-to-Order"
        // [GIVEN] "I0" has "Reordering Policy" = "Lot-for-Lot" and "Lot Accumulation Period" "LAP" and "Rescheduling Period" "RP" sufficient for rescheduling;
        // [GIVEN] "I1" and "I2" have "Reordering Policy" = Order;
        // [GIVEN] "I1" has "I2" as the "Production BOM", "I0" has "I1" as the "Production BOM";
        // [GIVEN] Sales Order "SO" for "I0" at Location "L" with "Shipment Date" SD as a demand;
        // [GIVEN] Calculate Regenerative Plan for "I0", "I1", "I2" at "L" and Carry Out Messages = new to create Production Order "PO" as a supply;
        CreateSalesOrderAndFirmPlannedProductionOrderAsDemandAndSupply(
          TopLevelItem, Level1Item, Level2Item, SalesHeader, LibraryRandom.RandDateFromInRange(WorkDate(), 7, 14), '<1Y>');

        // [GIVEN] Update "SO" "Shipment Date" forward (inside "LAP" and "RP");
        UpdateSalesHeaderShipmentDate(SalesHeader, LibraryRandom.RandInt(5));

        // [GIVEN] Calculate Regenerative Plan for "I0", "I1", "I2" at "L", result proposed messages = Reschedule;
        // [WHEN] Carry Out Messages
        PlanWrkShtCalcRegenPlanAndCarryOutActionMessage(
          StrSubstNo('%1|%2|%3', TopLevelItem."No.", Level1Item."No.", Level2Item."No."),
          CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', SalesHeader."Shipment Date"), RequisitionLine."Action Message"::Reschedule);

        // [THEN] "I1" and "I2" each have 2 "Reservation Entry" with "Reservation Status" = Reservation at "L", "Source Type" "Prod. Order Line" or "Prod. Order Component".
        VerifyReservationEntryPairInsideProductionOrder(Level1Item."No.", Level2Item."No.", SalesHeader."Location Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LotAccumulationFourDatesWithMoreThanPeriod()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        ShipmentDates: array[4] of Date;
        Quantities: array[4] of Decimal;
    begin
        // [FEATURE] [Lot Accumulation Period]
        // [SCENARIO 208102] For component with "Lot Accumulation Period" no accumulation occurs when demand due dates intervals exceed period
        Initialize();

        // [GIVEN] Production Lot-for-Lot Item "PI" with Component "CI" which has Lot Accumulation Period equal to one month, "Quantity per" = 1;
        CreateProdItemWithComponentWithMonthPlanningPeriods(ParentItem, ChildItem);

        // [GIVEN] Sales Order "SO" as demand for "PI", "SO" contains four lines "SL" with shipment dates each more than previous more than month;
        CreateFourDatesArrayWithMoreThanMonthInterval(ShipmentDates);
        CreateSalesOrderWithFourLinesOfSingleItemWithSpecifiedShipmentDates(Quantities, ParentItem."No.", ShipmentDates);

        // [WHEN] Calculate regenerative plan for "PI" and "CI"
        CalcRegenPlanForItemsRespectPlanningParamsFromNowToDate(
          StrSubstNo('%1|%2', ParentItem."No.", ChildItem."No."), CalcDate('<CW>', ShipmentDates[ArrayLen(ShipmentDates)]));

        // [THEN] Four requisition lines "RL" for "CI" are created: "RL"."Due Date"[i] = "SL"."Shipment Date"[i] - 1, "RL".Quantity[i] = "SL".Quantity[i].
        FilterOnRequisitionLine(RequisitionLine, ChildItem."No.");
        Assert.RecordCount(RequisitionLine, 4);
        VerifyRequisitionLineWithDueDateAndQuantity(ChildItem."No.", ShipmentDates[1] - 1, Quantities[1]);
        VerifyRequisitionLineWithDueDateAndQuantity(ChildItem."No.", ShipmentDates[2] - 1, Quantities[2]);
        VerifyRequisitionLineWithDueDateAndQuantity(ChildItem."No.", ShipmentDates[3] - 1, Quantities[3]);
        VerifyRequisitionLineWithDueDateAndQuantity(ChildItem."No.", ShipmentDates[4] - 1, Quantities[4]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LotAccumulationFourDatesInsidePeriod()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        ShipmentDates: array[4] of Date;
        Quantities: array[4] of Decimal;
    begin
        // [FEATURE] [Lot Accumulation Period]
        // [SCENARIO 208102] For component with "Lot Accumulation Period" supply is totally accumulated in single order when all demand due dates belong to single accumulation period
        Initialize();

        // [GIVEN] Production Lot-for-Lot Item "PI" with Component "CI" which has Lot Accumulation Period equal to one month, "Quantity per" = 1;
        CreateProdItemWithComponentWithMonthPlanningPeriods(ParentItem, ChildItem);

        // [GIVEN] Sales Order "SO" as demand for "PI", "SO" contains four lines "SL1", "SL2", "SL3", "SL4" with shipment dates all inside single month;
        CreateFourDatesArrayInsideMonthPeriod(ShipmentDates);
        CreateSalesOrderWithFourLinesOfSingleItemWithSpecifiedShipmentDates(Quantities, ParentItem."No.", ShipmentDates);

        // [WHEN] Calculate regenerative plan for "PI" and "CI"
        CalcRegenPlanForItemsRespectPlanningParamsFromNowToDate(
          StrSubstNo('%1|%2', ParentItem."No.", ChildItem."No."), CalcDate('<CW>', ShipmentDates[ArrayLen(ShipmentDates)]));

        // [THEN] Single requisition lines "RL" for "CI" is created: "RL"."Due Date"[i] = "SL1"."Shipment Date" - 1, "RL".Quantity = "SL1".Quantity + "SL2".Quantity + "SL3".Quantity + "SL4".Quantity.
        VerifyRequisitionLineWithDueDateAndQuantity(
          ChildItem."No.", ShipmentDates[1] - 1, Quantities[1] + Quantities[2] + Quantities[3] + Quantities[4]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LotAccumulationFourDatesAsTwoPairsEachInsidePeriod()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        ShipmentDates: array[4] of Date;
        Quantities: array[4] of Decimal;
    begin
        // [FEATURE] [Lot Accumulation Period]
        // [SCENARIO 208102] For component with "Lot Accumulation Period" two supplies are created when demand due dates belong to two different periods according to accumulation period
        Initialize();

        // [GIVEN] Production Lot-for-Lot Item "PI" with Component "CI" which has Lot Accumulation Period equal to one month, "Quantity per" = 1;
        CreateProdItemWithComponentWithMonthPlanningPeriods(ParentItem, ChildItem);

        // [GIVEN] Sales Order "SO" as demand for "PI", "SO" contains four lines "SL1", "SL2", "SL3", "SL4" with shipment dates as two pairs each inside month;
        CreateFourDatesArrayInsideTwoMonthsPeriodAsTwoPairsInsideMonth(ShipmentDates);
        CreateSalesOrderWithFourLinesOfSingleItemWithSpecifiedShipmentDates(Quantities, ParentItem."No.", ShipmentDates);

        // [WHEN] Calculate regenerative plan for "PI" and "CI"
        CalcRegenPlanForItemsRespectPlanningParamsFromNowToDate(
          StrSubstNo('%1|%2', ParentItem."No.", ChildItem."No."), CalcDate('<CW>', ShipmentDates[ArrayLen(ShipmentDates)]));

        // [THEN] Two requisition lines "RL1" and "RL2" for "CI" are created:
        // [THEN] "RL1"."Due Date" = "SL1"."Shipment Date" - 1, "RL1".Quantity = "SL1".Quantity + "SL2".Quantity,
        // [THEN ]"RL2"."Due Date" = "SL3"."Shipment Date" - 1, "RL2".Quantity = "SL3".Quantity + "SL4".Quantity
        FilterOnRequisitionLine(RequisitionLine, ChildItem."No.");
        Assert.RecordCount(RequisitionLine, 2);
        VerifyRequisitionLineWithDueDateAndQuantity(ChildItem."No.", ShipmentDates[1] - 1, Quantities[1] + Quantities[2]);
        VerifyRequisitionLineWithDueDateAndQuantity(ChildItem."No.", ShipmentDates[3] - 1, Quantities[3] + Quantities[4]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LotAccumulationFourDatesWhereSecondAndThirdAreInsidePeriodAndFirstAndFourthOutside()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        ShipmentDates: array[4] of Date;
        Quantities: array[4] of Decimal;
    begin
        // [FEATURE] [Lot Accumulation Period]
        // [SCENARIO 208102] For component with "Lot Accumulation Period" three supplies are created when demand due dates belong  to three different periods according to accumulation period
        Initialize();

        // [GIVEN] Production Lot-for-Lot Item "PI" with Component "CI" which has Lot Accumulation Period equal to one month, "Quantity per" = 1;
        CreateProdItemWithComponentWithMonthPlanningPeriods(ParentItem, ChildItem);

        // [GIVEN] Sales Order "SO" as demand for "PI", "SO" contains four lines "SL1", "SL2", "SL3", "SL4" with shipment dates where second and third are inside month and first and fourth outside;
        CreateFourDatesArrayWhereSecondAndThirdAreInsideMonthAndFirstAndFourthOutside(ShipmentDates);
        CreateSalesOrderWithFourLinesOfSingleItemWithSpecifiedShipmentDates(Quantities, ParentItem."No.", ShipmentDates);

        // [WHEN] Calculate regenerative plan for "PI" and "CI"
        CalcRegenPlanForItemsRespectPlanningParamsFromNowToDate(
          StrSubstNo('%1|%2', ParentItem."No.", ChildItem."No."), CalcDate('<CW>', ShipmentDates[ArrayLen(ShipmentDates)]));

        // [THEN] Three requisition lines "RL1", "RL2" and "RL3" for "CI" are created: "RL1"."Due Date" = "SL1"."Shipment Date" - 1, "RL1".Quantity = "SL1".Quantity + "SL2".Quantity, "RL2"."Due Date" = "SL2"."Shipment Date" - 1, "RL2".Quantity = "SL2".Quan
        FilterOnRequisitionLine(RequisitionLine, ChildItem."No.");
        Assert.RecordCount(RequisitionLine, 3);
        VerifyRequisitionLineWithDueDateAndQuantity(ChildItem."No.", ShipmentDates[1] - 1, Quantities[1]);
        VerifyRequisitionLineWithDueDateAndQuantity(ChildItem."No.", ShipmentDates[2] - 1, Quantities[2] + Quantities[3]);
        VerifyRequisitionLineWithDueDateAndQuantity(ChildItem."No.", ShipmentDates[4] - 1, Quantities[4]);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTRUE')]
    [Scope('OnPrem')]
    procedure CalcRegenPlanProdBOMClosedButVersionCertifiedWithStartingDate()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMVersion: Record "Production BOM Version";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Planning] [Version]
        // [SCENARIO 222065] Regenerative plan calculating is successful when Production BOM is Closed but its Production BOM Version has Status = Certified and specified "Starting Date"
        Initialize();

        // [GIVEN] Production BOM "PB" and its Production BOM Version "PBV" with specified "Starting Date"
        LibraryInventory.CreateItem(ChildItem);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem."No.");
        CreateProductionBOMVersionWithStartingDate(
          ProductionBOMVersion, ProductionBOMHeader."No.", ChildItem."Base Unit of Measure", CalcDate('<-1Y>', WorkDate()));

        LibraryVariableStorage.Enqueue(VersionsWillBeClosedMsg); // Enqueue for ConfirmHandlerTRUE

        // [GIVEN] "PB" has Status = Closed but "PBV" has Status = Certified
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Closed);
        ProductionBOMHeader.Modify(true);
        ProductionBOMVersion.Validate(Status, ProductionBOMVersion.Status::Certified);
        ProductionBOMVersion.Modify(true);

        // [GIVEN] Item "I" with "Production BOM No." = "PB"
        CreateProdOrderItemWithProductionBOM(ParentItem, ProductionBOMHeader."No.");

        // [GIVEN] Sales Order "SO" of "I" with Quantity "Q"
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(),
          ParentItem."No.", LibraryRandom.RandInt(5), '', WorkDate());

        // [WHEN] Calculate regenerative plan for "I"
        LibraryPlanning.CalcRegenPlanForPlanWksh(ParentItem, WorkDate(), WorkDate());

        // [THEN] "Requisition Line" "R" with "I" exists and has the same Quantity "Q"
        RequisitionLine.SetRange("No.", ParentItem."No.");
        RequisitionLine.FindFirst();
        RequisitionLine.TestField(Quantity, SalesLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NegativePlanningComponentCausesNoOrderPriorityErrorAndHandledAsSupply()
    var
        Item: array[2] of Record Item;
        ItemToPlan: Record Item;
        RequisitionLine: Record "Requisition Line";
        PlanningComponent: Record "Planning Component";
        Qty: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Planning Component]
        // [SCENARIO 266645] Negative planning component is handled as a supply by the planning engine.
        Initialize();

        Qty := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Items "A" and "B" set up for replenishment by production and reordering policy = "Maximum Qty.".
        for i := 1 to ArrayLen(Item) do begin
            CreateItem(Item[i], Item[i]."Reordering Policy"::"Maximum Qty.", Item[i]."Replenishment System"::"Prod. Order");
            Item[i].Validate("Maximum Inventory", Qty);
            Item[i].Modify(true);
        end;

        // [GIVEN] Calculate regenerative plan for items "A" and "B".
        ItemToPlan.SetFilter("No.", '%1|%2', Item[1]."No.", Item[2]."No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(ItemToPlan, WorkDate(), WorkDate());

        // [GIVEN] Make sure that planning lines are created for both items.
        ItemToPlan.CopyFilter("No.", RequisitionLine."No.");
        Assert.RecordCount(RequisitionLine, 2);

        // [GIVEN] Set up item "B" as a planning component for item "A" with a negative "Quantity per" = -1.
        RequisitionLine.SetRange("No.", Item[1]."No.");
        RequisitionLine.FindFirst();
        LibraryPlanning.CreatePlanningComponent(PlanningComponent, RequisitionLine);
        PlanningComponent.Validate("Item No.", Item[2]."No.");
        PlanningComponent.Validate("Quantity per", -1);
        PlanningComponent.Modify(true);

        // [WHEN] Calculate net change plan in the planning worksheet for items "A" and "B".
        LibraryPlanning.CalcNetChangePlanForPlanWksh(ItemToPlan, WorkDate(), WorkDate(), false);

        // [THEN] No error is raised.
        // [THEN] Requisition line is deleted for item "B", because its demand will be supplied by the planning component in "A".
        RequisitionLine.SetRange("No.", Item[1]."No.");
        Assert.RecordIsNotEmpty(RequisitionLine);
        RequisitionLine.SetRange("No.", Item[2]."No.");
        Assert.RecordIsEmpty(RequisitionLine);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanReqPageHandler,MessageHandlerWithoutValidate')]
    [Scope('OnPrem')]
    procedure CalcRegenerativePlanForBOMComponentWhenSalesLineExists()
    var
        BOMItem: Record Item;
        ChildItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        CalculatePlanPlanWksh: Report "Calculate Plan - Plan. Wksh.";
        Quantity: Decimal;
        QuantityPer: Decimal;
    begin
        // [FEATURE] [Regenerative Plan]
        // [SCENARIO 262519] MPS item (if at least one sales line is found) should be planned with all existing demands.

        Initialize();

        // [GIVEN] Create Items for BOM and for Component
        CreateItem(BOMItem, BOMItem."Reordering Policy"::"Fixed Reorder Qty.", BOMItem."Replenishment System"::"Prod. Order");
        CreateItem(ChildItem, ChildItem."Reordering Policy"::"Lot-for-Lot", ChildItem."Replenishment System"::"Prod. Order");

        // [GIVEN] Create BOM Header with a single component
        QuantityPer := LibraryRandom.RandInt(10);
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, ChildItem."No.", QuantityPer);
        BOMItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        BOMItem.Modify(true);

        // [GIVEN] Create Prod. Order for BOM
        Quantity := LibraryRandom.RandInt(10);
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, BOMItem."No.", Quantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [GIVEN] Create independent Sales Order for BOM Component
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ChildItem."No.", LibraryRandom.RandInt(5));

        // [GIVEN] Create Prod. Order for Sales Order
        LibraryManufacturing.CreateProductionOrderFromSalesOrder(
            SalesHeader, "Production Order Status"::Released, "Create Production Order Type"::ItemOrder);

        // [WHEN] Run regenerative plan from the planning worksheet, filtered by the component item, MPS=Yes, MRP=No
        LibraryPlanning.SelectRequisitionWkshName(RequisitionWkshName, RequisitionWkshName."Template Type"::Planning);
        CalculatePlanPlanWksh.SetTemplAndWorksheet(RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name, false);
        ChildItem.SetRange("No.", ChildItem."No.");
        CalculatePlanPlanWksh.SetTableView(ChildItem);
        Commit();
        CalculatePlanPlanWksh.Run();

        // [THEN] Requisition Line with BOM Component Item is created
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", ChildItem."No.");
        RequisitionLine.FindFirst();
        RequisitionLine.TestField(Quantity, Quantity * QuantityPer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningWithMaximumOrderQuantityRespectsLotAccumulationPeriod()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        SalesHeader: array[3] of Record "Sales Header";
        SalesLine: array[3] of Record "Sales Line";
        LotAccumulationPeriod: DateFormula;
        LotAccumulationPeriodText: Text;
        DemandDate: array[3] of Date;
        MaximumOrderQuantity: Decimal;
        DemandLineQuantity: Decimal;
        i: Integer;
        RecordCount: Integer;
    begin
        // [FEATURE] [Lot Accumulation Period] [Maximum Order Quantity]
        // [SCENARIO 264387] Planning with "Maximum Order Quantity" respects "Lot Accumulation Period".
        Initialize();

        // [GIVEN] Item "I" with "Lot Accumulation Period" = 2W and "Maximum Order Quantity" = 2000
        // [GIVEN] Sales Orders "S1", "S2", "S3" with shipment dates "D1", "D2", "D3" of "I"
        // [GIVEN] Each "SX" has quantity = 1500, "S1"."Shipment Date" = WorkDate(), "S1"."Shipment Date" < "S2"."Shipment Date" < "S3"."Shipment Date"
        DemandDate[1] := WorkDate();
        DemandDate[2] := DemandDate[1] + LibraryRandom.RandInt(20);
        DemandDate[3] := DemandDate[2] + LibraryRandom.RandInt(20);

        LotAccumulationPeriodText := StrSubstNo('<%1D>', DemandDate[3] - DemandDate[1]);

        Evaluate(LotAccumulationPeriod, LotAccumulationPeriodText);
        DemandLineQuantity := LibraryRandom.RandIntInRange(100, 200);
        MaximumOrderQuantity := LibraryRandom.RandIntInRange(10, 20);

        CreateItem(Item, Item."Reordering Policy"::"Lot-for-Lot", Item."Replenishment System"::Purchase);
        Item.Validate("Lot Accumulation Period", LotAccumulationPeriod);
        Item.Validate("Maximum Order Quantity", MaximumOrderQuantity);
        Item.Modify(true);

        for i := 1 to 3 do
            LibrarySales.CreateSalesDocumentWithItem(
              SalesHeader[i], SalesLine[i], SalesHeader[i]."Document Type"::Order, '', Item."No.", DemandLineQuantity, '', DemandDate[i]);

        // [WHEN] Calculate regenerative plan
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), DemandDate[3]);

        // [THEN] 3 "Requisition Line" "R1", "R2", "R3" are created, each "RX"."Due Date" = WorkDate(), "R1".Quantity = "R2".Quantity = 2000, "R3".Quantity = 500
        RecordCount := Round(DemandLineQuantity * 3 / MaximumOrderQuantity, 1, '>');
        RequisitionLine.SetRange("No.", Item."No.");
        RequisitionLine.SetRange("Due Date", WorkDate());
        Assert.RecordCount(RequisitionLine, RecordCount);

        RequisitionLine.SetRange(Quantity, MaximumOrderQuantity);
        Assert.RecordCount(RequisitionLine, RecordCount - 1);

        RequisitionLine.SetRange(Quantity, DemandLineQuantity * 3 - MaximumOrderQuantity * (RecordCount - 1));
        Assert.RecordCount(RequisitionLine, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerWithoutValidate')]
    [Scope('OnPrem')]
    procedure ProdOrderInheritsGenBusPostingGroupFromSalesOrderItemOrder()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [Production Order]
        // [SCENARIO 277381] When Released Prod. Order (Order Type is 'Item Order') is created from Sales Order, Gen. Bus. Posting group mustn't be inherited from Sales Order.
        Initialize();

        // [GIVEN] Create Item with Manufacturing Policy = "Make-to-Order" & Reordering Policy = Order
        LibraryInventory.CreateItem(Item);
        Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Order");
        Item.Validate("Reordering Policy", Item."Reordering Policy"::Order);
        Item.Modify(true);

        // [GIVEN] Create a Sales Order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(5));

        // [WHEN] Create a Released Prod. Order from the Sales Order; Order Type is 'Item Order'
        LibraryManufacturing.CreateProductionOrderFromSalesOrder(
            SalesHeader, "Production Order Status"::Released, "Create Production Order Type"::ItemOrder);
        ProductionOrder.SetRange("Source Type", ProductionOrder."Source Type"::Item);
        ProductionOrder.SetRange("Source No.", Item."No.");
        ProductionOrder.FindFirst();

        // [THEN] Check out if Gen. Bus. Posting Group field is empty
        ProductionOrder.TestField("Gen. Bus. Posting Group", '');
    end;

    [Test]
    [HandlerFunctions('MessageHandlerWithoutValidate')]
    [Scope('OnPrem')]
    procedure ProdOrderInheritsGenBusPostingGroupFromSalesOrderProjectOrder()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [Production Order]
        // [SCENARIO 304538] When Released Prod. Order (Order Type is 'Project Order') is created from Sales Order, Gen. Bus. Posting group is blank
        Initialize();

        // [GIVEN] Create Item with Manufacturing Policy = "Make-to-Order" & Reordering Policy = Order
        LibraryInventory.CreateItem(Item);
        Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Order");
        Item.Validate("Reordering Policy", Item."Reordering Policy"::Order);
        Item.Modify(true);

        // [GIVEN] Create a Sales Order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(5));

        // [WHEN] Create a Relerased Prod. Order from the Sales Order; Order Type is 'Project Order'
        LibraryManufacturing.CreateProductionOrderFromSalesOrder(
            SalesHeader, "Production Order Status"::Released, "Create Production Order Type"::ProjectOrder);
        ProductionOrder.SetRange("Source Type", ProductionOrder."Source Type"::"Sales Header");
        ProductionOrder.SetRange("Source No.", SalesHeader."No.");
        ProductionOrder.FindFirst();

        // [THEN] Check out if Gen. Bus. Posting Group field is blank
        ProductionOrder.TestField("Gen. Bus. Posting Group", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderValidatingSourceItemAfterSalesHeaderUT()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [Production Order] [UT]
        // [SCENARIO 304538] Gen. Bus. Posting group in Production order is empty after setting source to sales header and then to Item
        Initialize();

        // [GIVEN] Create Item with Manufacturing Policy = "Make-to-Order" & Reordering Policy = Order
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a Sales Order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(5));

        // [GIVEN] Production order
        ProductionOrder.Init();
        ProductionOrder.Validate(Status, ProductionOrder.Status::Released);
        ProductionOrder."No." := '';
        ProductionOrder.Insert(true);

        // [GIVEN] Validate source sales header
        ProductionOrder.Validate("Source Type", ProductionOrder."Source Type"::"Sales Header");
        ProductionOrder.Validate("Source No.", SalesLine."Document No.");
        ProductionOrder.Modify(true);

        // [WHEN] Change source to Item from Sales Header
        ProductionOrder.Validate("Source Type", ProductionOrder."Source Type"::Item);
        ProductionOrder.Validate("Source No.", Item."No.");
        ProductionOrder.Modify(true);

        // [THEN] Gen. Bus. Posting Group = blank
        ProductionOrder.TestField("Gen. Bus. Posting Group", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderValidatingSourceSalesHeaderUT()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [Production Order] [UT]
        // [SCENARIO 304538] Gen. Bus. Posting group in Production order is empty after setting source to sales header
        Initialize();

        // [GIVEN] Create Item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a Sales Order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(5));

        // [GIVEN] Production order
        ProductionOrder.Init();
        ProductionOrder.Validate(Status, ProductionOrder.Status::Released);
        ProductionOrder."No." := '';
        ProductionOrder.Insert(true);

        // [WHEN] Validate source sales header
        ProductionOrder.Validate("Source Type", ProductionOrder."Source Type"::"Sales Header");
        ProductionOrder.Validate("Source No.", SalesLine."Document No.");
        ProductionOrder.Modify(true);

        // [THEN] Gen. Bus. Posting Group = blank
        ProductionOrder.TestField("Gen. Bus. Posting Group", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderValidatingSourceItemUT()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [Production Order] [UT]
        // [SCENARIO 304538] Gen. Bus. Posting group in Production order is empty after setting source to sales header and then to Item
        Initialize();

        // [GIVEN] Create Item with Manufacturing Policy = "Make-to-Order" & Reordering Policy = Order
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Production order
        ProductionOrder.Init();
        ProductionOrder.Validate(Status, ProductionOrder.Status::Released);
        ProductionOrder."No." := '';
        ProductionOrder.Insert(true);

        // [WHEN] Validate source type Item
        ProductionOrder.Validate("Source Type", ProductionOrder."Source Type"::Item);
        ProductionOrder.Validate("Source No.", Item."No.");
        ProductionOrder.Modify(true);

        // [THEN] Gen. Bus. Posting Group = blank
        ProductionOrder.TestField("Gen. Bus. Posting Group", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CarryOutActionInsertProdOrderUT()
    var
        RequisitionLine: Record "Requisition Line";
        ProductionOrder: Record "Production Order";
        TempDocumentEntry: Record "Document Entry" temporary;
        MfgCarryOutAction: Codeunit "Mfg. Carry Out Action";
    begin
        // [FEATURE] [UT] [Production Order]
        // [SCENARIO 277381] Codeunit 99000813 InsertProductionOrder() on Reqisition Line with "Gen. Business Posting Group" <> '' doesn't fill "Gen. Business Posting Group" in Production Order
        Initialize();

        // [GIVEN] Mock Requisition Line
        CreateReqLine(RequisitionLine);
        RequisitionLine.TestField("Gen. Business Posting Group");

        // [WHEN] Call CarryOutAction.InsertProductionOrder()
        MfgCarryOutAction.InsertProductionOrder(RequisitionLine, "Planning Create Prod. Order"::Planned, TempDocumentEntry);

        // [THEN] "Gen. Bus. Posting Group" = blank in created Production order
        ProductionOrder.SetRange(Status, ProductionOrder.Status::Planned);
        ProductionOrder.SetRange("Source No.", RequisitionLine."No.");
        ProductionOrder.FindFirst();
        ProductionOrder.TestField("Gen. Bus. Posting Group", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CarryOutActionInsertProdOrderWithVariant()
    var
        RequisitionLine: Record "Requisition Line";
        ProductionOrder: Record "Production Order";
        TempDocumentEntry: Record "Document Entry" temporary;
        MfgCarryOutAction: Codeunit "Mfg. Carry Out Action";
    begin
        // [FEATURE] [Production Order] [Item Variant]
        // [SCENARIO 388994] Codeunit 99000813 InsertProductrionOrder() on Reqisition Line with Variant Code fill "Variant Code" in Production Order
        Initialize();

        // [GIVEN] Mock Requisition Line
        CreateReqLine(RequisitionLine);
        RequisitionLine.TestField("Gen. Business Posting Group");

        // [WHEN] Call CarryOutAction.InsertProductionOrder()
        MfgCarryOutAction.InsertProductionOrder(RequisitionLine, "Planning Create Prod. Order"::Planned, TempDocumentEntry);

        // [THEN] "Gen. Bus. Posting Group" = blank in created Production order
        ProductionOrder.SetRange(Status, ProductionOrder.Status::Planned);
        ProductionOrder.SetRange("Source No.", RequisitionLine."No.");
        ProductionOrder.FindFirst();
        ProductionOrder.TestField("Variant Code", RequisitionLine."Variant Code");
    end;

    [Test]
    procedure CalcRegenPlanWhenParentItemProducedOnHolidays()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        BaseCalendar: Record "Base Calendar";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        OldBaseCalendarCode: Code[10];
        ShipmentDate: Date;
    begin
        // [FEATURE] [Production Order] [Purchase] [Calendar]
        // [SCENARIO 412288] Due Date and Starting/Ending Dates of purchase Requisition Line when Calc Regen Plan for Item which is produced on holidays.
        Initialize();

        // [GIVEN] Company has Base Calendar with non-working days Saturday and Sunday each week.
        CreateBaseCalendarWithNonWorkingWeekends(BaseCalendar);
        OldBaseCalendarCode := UpdateBaseCalendarOnCompanyInformation(BaseCalendar.Code);
        LibraryApplicationArea.EnablePremiumSetup();

        // [GIVEN] Certified Production BOM "B" with Item "I2" with Replenishment System "Purchase". "I2" has Safety Lead Time "0D".
        // [GIVEN] Item "I1" with Replenishment System "Prod. Order", Safety Lead Time "0D" and with Production BOM "B".
        // [GIVEN] Certified Routing for Item "I1" with one line for Work Center that works 8 hours a day all week without holidays.
        // [GIVEN] Routing Line has Run Time = 600 minutes (10 hours), so it takes ~2 days for Work Center to produce "I1".
        CreateItem(ChildItem, ChildItem."Reordering Policy"::"Lot-for-Lot", ChildItem."Replenishment System"::Purchase);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem."No.");
        UpdateSafetyLeadTimeOnItem(ChildItem, '0D');
        CreateProductionItemWithOneLineRouting(Item, 600);
        UpdateProductionBOMOnItem(Item, ProductionBOMHeader."No.");
        UpdateSafetyLeadTimeOnItem(Item, '0D');

        // [GIVEN] Sales Order for Item "I1" with Shipment Date on Monday, 30.01.23.
        ShipmentDate := CalcDate('<1W + WD1>', WorkDate());
        LibrarySales.CreateSalesDocumentWithItem(
            SalesHeader, SalesLine, "Sales Document Type"::Order, '', Item."No.", 1, '', ShipmentDate);

        // [WHEN] Calculate regenerative plan for "I1" and "I2".
        Item.SetFilter("No.", ItemFilterTxt, Item."No.", ChildItem."No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, ShipmentDate - 10, ShipmentDate + 10);

        // [THEN] Two Requisition Lines are created.
        // [THEN] First line is for Prod. Order for "I1". Due Date = 30.01.23, Starting Date = 29.01 (Sunday), Ending Date = 30.01.
        // [THEN] Second line is for Purchase of "I2". Due Date = 29.01 (Sunday), Starting/Ending Date = 27.01 (Friday).
        VerifyRequisitionLineDates(
            Item."No.", RequisitionLine."Ref. Order Type"::"Prod. Order", "Action Message Type"::New, ShipmentDate, ShipmentDate - 1, ShipmentDate);
        VerifyRequisitionLineDates(
            ChildItem."No.", RequisitionLine."Ref. Order Type"::Purchase, "Action Message Type"::New, ShipmentDate - 1, ShipmentDate - 3, ShipmentDate - 3);

        // [WHEN] Carry Out Action Message for both Requisition Lines.
        RequisitionLine.SetFilter("No.", ItemFilterTxt, Item."No.", ChildItem."No.");
        RequisitionLine.FindFirst();
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);

        // [THEN] Purchase Order with one purchase line for Item "I2" is created.
        // [THEN] Purchase Line has Planned/Expected Receipt Date = 27.01 (Friday).
        VerifyPurchaseLineReceiptDates(
            "Purchase Document Type"::Order, ChildItem."Vendor No.", ChildItem."No.", ShipmentDate - 3, ShipmentDate - 3);

        // tear down
        UpdateBaseCalendarOnCompanyInformation(OldBaseCalendarCode);
    end;

    [Test]
    procedure RecalcRegenPlanWhenParentItemProducedOnHolidays()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        BaseCalendar: Record "Base Calendar";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        OldBaseCalendarCode: Code[10];
        ShipmentDate: Date;
    begin
        // [FEATURE] [Production Order] [Purchase] [Calendar]
        // [SCENARIO 412288] Recalculating Regeneration Plan when we have Purchase Order for Item with Receipt Date on Friday and this Item, when planned, has Due Date on Sunday.
        Initialize();

        // [GIVEN] Company has Base Calendar with non-working days Saturday and Sunday each week.
        CreateBaseCalendarWithNonWorkingWeekends(BaseCalendar);
        OldBaseCalendarCode := UpdateBaseCalendarOnCompanyInformation(BaseCalendar.Code);
        LibraryApplicationArea.EnablePremiumSetup();

        // [GIVEN] Certified Production BOM "B" with Item "I2" with Replenishment System "Purchase". "I2" has Safety Lead Time "0D".
        // [GIVEN] Item "I1" with Replenishment System "Prod. Order", Safety Lead Time "0D" and with Production BOM "B".
        // [GIVEN] Certified Routing for Item "I1" with one line for Work Center that works 8 hours a day all week without holidays.
        // [GIVEN] Routing Line has Run Time = 600 minutes (10 hours), so it takes ~2 days for Work Center to produce "I1".
        CreateItem(ChildItem, ChildItem."Reordering Policy"::"Lot-for-Lot", ChildItem."Replenishment System"::Purchase);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem."No.");
        UpdateSafetyLeadTimeOnItem(ChildItem, '0D');
        CreateProductionItemWithOneLineRouting(Item, 600);
        UpdateProductionBOMOnItem(Item, ProductionBOMHeader."No.");
        UpdateSafetyLeadTimeOnItem(Item, '0D');

        // [GIVEN] Sales Order for Item "I1" with Shipment Date on Monday, 30.01.23.
        ShipmentDate := CalcDate('<1W + WD1>', WorkDate());
        LibrarySales.CreateSalesDocumentWithItem(
            SalesHeader, SalesLine, "Sales Document Type"::Order, '', Item."No.", 1, '', ShipmentDate);

        // [GIVEN] Calculated regenerative plan for "I1" and "I2". Two Requisition Lines for producing "I1" and purchasing "I2" are created.
        Item.SetFilter("No.", ItemFilterTxt, Item."No.", ChildItem."No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, ShipmentDate - 10, ShipmentDate + 10);

        // [GIVEN] Carried Out Action Message for both Requisition Lines.
        RequisitionLine.SetFilter("No.", ItemFilterTxt, Item."No.", ChildItem."No.");
        RequisitionLine.FindFirst();
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);

        // [WHEN] Calculate regenerative plan for "I1" and "I2" again.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, ShipmentDate - 10, ShipmentDate + 10);

        // [THEN] No Requisition Lines are created for "I1" or "I2".
        RequisitionLine.SetFilter("No.", ItemFilterTxt, Item."No.", ChildItem."No.");
        Assert.RecordIsEmpty(RequisitionLine);

        // tear down
        UpdateBaseCalendarOnCompanyInformation(OldBaseCalendarCode);
    end;

    [Test]
    procedure CalcRegenPlanBackTwoProdItemsWhenChildItemWithWaitRunTime()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        ShipmentDate: Date;
    begin
        // [SCENARIO 415709] Calculate Regen. Plan for two production items when child item has Routing with Wait and Run time.
        Initialize();

        // [GIVEN] Certified Production BOM "B" with Item "I2" with Replenishment System "Prod. Order" and Manufacturing Policy "Make-to-Order".
        // [GIVEN] Item "I1" with Replenishment System "Prod. Order", Manufacturing Policy "Make-to-Order" and with Production BOM "B".
        // [GIVEN] Certified Routing for Item "I1" with one line for Work Center (works 0800 - 1600). Run Time is 7 hours.
        // [GIVEN] Certified Routing for Item "I2" with one line for Work Center (works 0800 - 1600). Run Time is 1 hour, Wait Time is 2 hours.
        CreateProductionItemWithOneLineRouting(ChildItem, 0, 60, 120, 0, 080000T, 160000T);
        UpdateManufacturingPolicyOnItem(ChildItem, "Manufacturing Policy"::"Make-to-Order");
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem."No.", 1);
        CreateProductionItemWithOneLineRouting(Item, 0, 420, 0, 0, 080000T, 160000T);
        UpdateManufacturingPolicyOnItem(Item, "Manufacturing Policy"::"Make-to-Order");
        UpdateProductionBOMOnItem(Item, ProductionBOMHeader."No.");

        // [GIVEN] Sales Order for Item "I1" with Shipment Date on Friday, 27.01.23.
        ShipmentDate := CalcDate('<1W + WD4>', WorkDate());
        LibrarySales.CreateSalesDocumentWithItem(
            SalesHeader, SalesLine, "Sales Document Type"::Order, '', Item."No.", 1, '', ShipmentDate);

        // [WHEN] Calculate regenerative plan for "I1" and "I2".
        Item.SetFilter("No.", ItemFilterTxt, Item."No.", ChildItem."No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, ShipmentDate - 10, ShipmentDate + 10);

        // [THEN] Two Requisition Lines are created.
        // [THEN] First line is for Prod. Order for "I1". Starting DateTime = 26.01 09:00, Ending DateTime = 26.01 16:00.
        // [THEN] Second line is for Prod. Order of "I2". Starting DateTime = 25.01 15:00, Ending DateTime = 26.01 09:00.
        VerifyRequisitionLineStartEndDateTime(
            Item."No.", RequisitionLine."Ref. Order Type"::"Prod. Order", "Action Message Type"::New,
            CreateDateTime(ShipmentDate - 1, 090000T), CreateDateTime(ShipmentDate - 1, 160000T));
        VerifyRequisitionLineStartEndDateTime(
            ChildItem."No.", RequisitionLine."Ref. Order Type"::"Prod. Order", "Action Message Type"::New,
            CreateDateTime(ShipmentDate - 2, 150000T), CreateDateTime(ShipmentDate - 1, 090000T));
    end;

    [Test]
    procedure CalcRegenPlanBackTwoProdItemsWhenChildItemWithWaitTimeOnly()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        ShipmentDate: Date;
    begin
        // [SCENARIO 415709] Calculate Regen. Plan for two production items when child item has Routing with Wait time only.
        Initialize();

        // [GIVEN] Certified Production BOM "B" with Item "I2" with Replenishment System "Prod. Order" and Manufacturing Policy "Make-to-Order".
        // [GIVEN] Item "I1" with Replenishment System "Prod. Order", Manufacturing Policy "Make-to-Order" and with Production BOM "B".
        // [GIVEN] Certified Routing for Item "I1" with one line for Work Center (works 0800 - 1600). Run Time is 7 hours.
        // [GIVEN] Certified Routing for Item "I2" with one line for Work Center (works 0800 - 1600). Wait Time is 2 hours.
        CreateProductionItemWithOneLineRouting(ChildItem, 0, 0, 120, 0, 080000T, 160000T);
        UpdateManufacturingPolicyOnItem(ChildItem, "Manufacturing Policy"::"Make-to-Order");
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem."No.");
        CreateProductionItemWithOneLineRouting(Item, 0, 420, 0, 0, 080000T, 160000T);
        UpdateManufacturingPolicyOnItem(Item, "Manufacturing Policy"::"Make-to-Order");
        UpdateProductionBOMOnItem(Item, ProductionBOMHeader."No.");

        // [GIVEN] Sales Order for Item "I1" with Shipment Date on Friday, 27.01.23.
        ShipmentDate := CalcDate('<1W + WD4>', WorkDate());
        LibrarySales.CreateSalesDocumentWithItem(
            SalesHeader, SalesLine, "Sales Document Type"::Order, '', Item."No.", 1, '', ShipmentDate);

        // [WHEN] Calculate regenerative plan for "I1" and "I2".
        Item.SetFilter("No.", ItemFilterTxt, Item."No.", ChildItem."No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, ShipmentDate - 10, ShipmentDate + 10);

        // [THEN] Two Requisition Lines are created.
        // [THEN] First line is for Prod. Order for "I1". Starting DateTime = 26.01 09:00, Ending DateTime = 26.01 16:00.
        // [THEN] Second line is for Prod. Order of "I2". Starting DateTime = 26.01 07:00, Ending DateTime = 26.01 09:00.
        VerifyRequisitionLineStartEndDateTime(
            Item."No.", RequisitionLine."Ref. Order Type"::"Prod. Order", "Action Message Type"::New,
            CreateDateTime(ShipmentDate - 1, 090000T), CreateDateTime(ShipmentDate - 1, 160000T));
        VerifyRequisitionLineStartEndDateTime(
            ChildItem."No.", RequisitionLine."Ref. Order Type"::"Prod. Order", "Action Message Type"::New,
            CreateDateTime(ShipmentDate - 1, 070000T), CreateDateTime(ShipmentDate - 1, 090000T));
    end;

    [Test]
    procedure CalcRegenPlanBackWhenWaitTimeOnHolidaysAndRunTime()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        ShipmentDate: Date;
    begin
        // [SCENARIO 415709] Calculate Regen. Plan for production item when it has Routing with Wait and Run time and Due Date on Monday.
        Initialize();

        // [GIVEN] Manufacturing Setup has Normal Starting Time 00:00:00 and Normal Ending Time 23:59:59.
        UpdateManufacturingSetupNormalStartingEndingTime(000000T, 235959T);

        // [GIVEN] Item "I1" with Replenishment System "Prod. Order".
        // [GIVEN] Certified Routing for Item "I1" with one line for Work Center (works 0800 - 1600). Wait Time is 2 hours, Run Time is 1 hour.
        CreateProductionItemWithOneLineRouting(Item, 0, 60, 120, 0, 080000T, 160000T);

        // [GIVEN] Sales Order for Item "I1" with Shipment Date on Monday, 30.01.23.
        ShipmentDate := CalcDate('<1W + WD1>', WorkDate());
        LibrarySales.CreateSalesDocumentWithItem(
            SalesHeader, SalesLine, "Sales Document Type"::Order, '', Item."No.", 1, '', ShipmentDate);

        // [WHEN] Calculate regenerative plan for "I1".
        Item.SetFilter("No.", Item."No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, ShipmentDate - 10, ShipmentDate + 10);

        // [THEN] Requisition Line with Prod. Order type for "I1" is created. Starting DateTime = 27.01 15:00 (Friday), Ending DateTime = 29.01 23:59:59 (Sunday).
        VerifyRequisitionLineStartEndDateTime(
            Item."No.", RequisitionLine."Ref. Order Type"::"Prod. Order", "Action Message Type"::New,
            CreateDateTime(ShipmentDate - 3, 150000T), CreateDateTime(ShipmentDate - 1, 235959T));
    end;

    [Test]
    procedure CalcRegenPlanBackWhenCapacityConstrainedResourceAndWaitTimeOnHolidays()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        ShipmentDate: Date;
    begin
        // [SCENARIO 415709] Calculate Regen. Plan for production item when it has Routing with Wait time only and Due Date on Monday.
        Initialize();

        // [GIVEN] Manufacturing Setup has Normal Starting Time 00:00:00 and Normal Ending Time 23:59:59.
        UpdateManufacturingSetupNormalStartingEndingTime(000000T, 235959T);

        // [GIVEN] Item "I1" with Replenishment System "Prod. Order".
        // [GIVEN] Certified Routing for Item "I1" with one line for Work Center "A" (works 0800 - 1600). Wait Time is 2 hours.
        // [GIVEN] Work Center "A" is a capacity constrained resource.
        CreateProductionItemWithOneLineRouting(Item, 0, 0, 120, 0, 080000T, 160000T);
        RoutingHeader.Get(Item."Routing No.");
        RoutingLine.SetRange("Routing No.", RoutingHeader."No.");
        RoutingLine.FindFirst();
        CreateCapacityConstrainedResourceForWorkCenter(RoutingLine."No.", 50);

        // [GIVEN] Sales Order for Item "I1" with Shipment Date on Monday, 30.01.23.
        ShipmentDate := CalcDate('<1W + WD1>', WorkDate());
        LibrarySales.CreateSalesDocumentWithItem(
            SalesHeader, SalesLine, "Sales Document Type"::Order, '', Item."No.", 1, '', ShipmentDate);

        // [WHEN] Calculate regenerative plan for "I1".
        Item.SetFilter("No.", Item."No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, ShipmentDate - 10, ShipmentDate + 10);

        // [THEN] Requisition Line with Prod. Order type for "I1" is created. Starting DateTime = 29.01 22:00 (Sunday), Ending DateTime = 29.01 23:59:59 (Sunday).
        VerifyRequisitionLineStartEndDateTime(
            Item."No.", RequisitionLine."Ref. Order Type"::"Prod. Order", "Action Message Type"::New,
            CreateDateTime(ShipmentDate - 1, 220000T), CreateDateTime(ShipmentDate - 1, 235959T));
    end;

    [Test]
    procedure CalcRegenPlanForwardTwoProdItemsWhenChildItemWithWaitRunTime()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        ShipmentDate: Date;
    begin
        // [SCENARIO 415709] Calculate Regen. Plan forward for two production items when child item has Routing with Wait and Run time.
        Initialize();

        // [GIVEN] Certified Production BOM "B" with Item "I2" with Replenishment System "Prod. Order" and Manufacturing Policy "Make-to-Order".
        // [GIVEN] Item "I1" with Replenishment System "Prod. Order", Manufacturing Policy "Make-to-Order" and with Production BOM "B".
        // [GIVEN] Certified Routing for Item "I1" with one line for Work Center (works 0800 - 1600). Run Time is 7 hours.
        // [GIVEN] Certified Routing for Item "I2" with one line for Work Center (works 0800 - 1600). Run Time is 1 hour, Wait Time is 2 hours.
        CreateProductionItemWithOneLineRouting(ChildItem, 0, 60, 120, 0, 080000T, 160000T);
        UpdateManufacturingPolicyOnItem(ChildItem, "Manufacturing Policy"::"Make-to-Order");
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem."No.", 1);
        CreateProductionItemWithOneLineRouting(Item, 0, 420, 0, 0, 080000T, 160000T);
        UpdateManufacturingPolicyOnItem(Item, "Manufacturing Policy"::"Make-to-Order");
        UpdateProductionBOMOnItem(Item, ProductionBOMHeader."No.");

        // [GIVEN] Sales Order for Item "I1" with Shipment Date on Friday, 27.01.23.
        ShipmentDate := CalcDate('<1W + WD4>', WorkDate());
        LibrarySales.CreateSalesDocumentWithItem(
            SalesHeader, SalesLine, "Sales Document Type"::Order, '', Item."No.", 1, '', ShipmentDate);

        // [GIVEN] Requisition Lines for "I1" and "I2".
        // [GIVEN] First line is for Prod. Order for "I1". Starting DateTime = 26.01 09:00, Ending DateTime = 26.01 16:00.
        // [GIVEN] Second line is for Prod. Order of "I2". Starting DateTime = 25.01 15:00, Ending DateTime = 26.01 09:00.
        Item.SetFilter("No.", ItemFilterTxt, Item."No.", ChildItem."No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, ShipmentDate - 10, ShipmentDate + 10);

        // [WHEN] Set Starting Time 14:00 for second Requisition Line with Item "I2".
        FilterOnRequisitionLine(RequisitionLine, ChildItem."No.");
        RequisitionLine.FindFirst();
        RequisitionLine.Validate("Starting Time", 140000T);
        RequisitionLine.Modify(true);

        // [THEN] Requisition Line for "I1" has Starting DateTime = 26.01 09:00, Ending DateTime = 26.01 16:00.
        // [THEN] Requisition Line for "I2" has Starting DateTime = 25.01 14:00, Ending DateTime = 25.01 17:00.
        VerifyRequisitionLineStartEndDateTime(
            Item."No.", RequisitionLine."Ref. Order Type"::"Prod. Order", "Action Message Type"::New,
            CreateDateTime(ShipmentDate - 1, 090000T), CreateDateTime(ShipmentDate - 1, 160000T));
        VerifyRequisitionLineStartEndDateTime(
            ChildItem."No.", RequisitionLine."Ref. Order Type"::"Prod. Order", "Action Message Type"::New,
            CreateDateTime(ShipmentDate - 2, 140000T), CreateDateTime(ShipmentDate - 2, 170000T));
    end;

    [Test]
    procedure CalcRegenPlanForwardTwoProdItemsWhenChildItemWithWaitTimeOnly()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        ShipmentDate: Date;
    begin
        // [SCENARIO 415709] Calculate Regen. Plan forward for two production items when child item has Routing with Wait time only.
        Initialize();

        // [GIVEN] Certified Production BOM "B" with Item "I2" with Replenishment System "Prod. Order" and Manufacturing Policy "Make-to-Order".
        // [GIVEN] Item "I1" with Replenishment System "Prod. Order", Manufacturing Policy "Make-to-Order" and with Production BOM "B".
        // [GIVEN] Certified Routing for Item "I1" with one line for Work Center (works 0800 - 1600). Run Time is 7 hours.
        // [GIVEN] Certified Routing for Item "I2" with one line for Work Center (works 0800 - 1600). Wait Time is 2 hours.
        CreateProductionItemWithOneLineRouting(ChildItem, 0, 0, 120, 0, 080000T, 160000T);
        UpdateManufacturingPolicyOnItem(ChildItem, "Manufacturing Policy"::"Make-to-Order");
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem."No.");
        CreateProductionItemWithOneLineRouting(Item, 0, 420, 0, 0, 080000T, 160000T);
        UpdateManufacturingPolicyOnItem(Item, "Manufacturing Policy"::"Make-to-Order");
        UpdateProductionBOMOnItem(Item, ProductionBOMHeader."No.");

        // [GIVEN] Sales Order for Item "I1" with Shipment Date on Friday, 27.01.23.
        ShipmentDate := CalcDate('<1W + WD4>', WorkDate());
        LibrarySales.CreateSalesDocumentWithItem(
            SalesHeader, SalesLine, "Sales Document Type"::Order, '', Item."No.", 1, '', ShipmentDate);

        // [GIVEN] Requisition Lines for "I1" and "I2".
        // [GIVEN] First line is for Prod. Order for "I1". Starting DateTime = 26.01 09:00, Ending DateTime = 26.01 16:00.
        // [GIVEN] Second line is for Prod. Order of "I2". Starting DateTime = 26.01 07:00, Ending DateTime = 26.01 09:00.
        Item.SetFilter("No.", ItemFilterTxt, Item."No.", ChildItem."No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, ShipmentDate - 10, ShipmentDate + 10);

        // [WHEN] Set Starting Time 06:00 for second Requisition Line with Item "I2".
        FilterOnRequisitionLine(RequisitionLine, ChildItem."No.");
        RequisitionLine.FindFirst();
        RequisitionLine.Validate("Starting Time", 060000T);
        RequisitionLine.Modify(true);

        // [THEN] Requisition Line for "I1" has Starting DateTime = 26.01 09:00, Ending DateTime = 26.01 16:00.
        // [THEN] Requisition Line for "I2" has Starting DateTime = 26.01 06:00, Ending DateTime = 26.01 08:00.
        VerifyRequisitionLineStartEndDateTime(
            Item."No.", RequisitionLine."Ref. Order Type"::"Prod. Order", "Action Message Type"::New,
            CreateDateTime(ShipmentDate - 1, 090000T), CreateDateTime(ShipmentDate - 1, 160000T));
        VerifyRequisitionLineStartEndDateTime(
            ChildItem."No.", RequisitionLine."Ref. Order Type"::"Prod. Order", "Action Message Type"::New,
            CreateDateTime(ShipmentDate - 1, 060000T), CreateDateTime(ShipmentDate - 1, 080000T));
    end;

    [Test]
    procedure CalcRegenPlanForwardWhenWaitTimeOnHolidaysAndRunMoveTime()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        ShipmentDate: Date;
    begin
        // [SCENARIO 415709] Calculate Regen. Plan forward for production item when it has Routing with Wait, Run and Move time and Wait time on holidays.
        Initialize();

        // [GIVEN] Manufacturing Setup has Normal Starting Time 00:00:00 and Normal Ending Time 23:59:59.
        UpdateManufacturingSetupNormalStartingEndingTime(000000T, 235959T);

        // [GIVEN] Item "I1" with Replenishment System "Prod. Order".
        // [GIVEN] Certified Routing for Item "I1" with one line for Work Center (works 0800 - 1600). Wait Time is 2 hours, Move Time is 1 hour.
        CreateProductionItemWithOneLineRouting(Item, 0, 60, 120, 60, 080000T, 235959T);

        // [GIVEN] Sales Order for Item "I1" with Shipment Date on Monday, 30.01.23.
        ShipmentDate := CalcDate('<1W + WD1>', WorkDate());
        LibrarySales.CreateSalesDocumentWithItem(
            SalesHeader, SalesLine, "Sales Document Type"::Order, '', Item."No.", 1, '', ShipmentDate);

        // [GIVEN] Requisition Line for "I1" with Starting DateTime = 27.01 15:00 (Friday), Ending DateTime = 29.01 23:59:59 (Sunday).
        Item.SetFilter("No.", Item."No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, ShipmentDate - 10, ShipmentDate + 10);

        // [WHEN] Set Starting Time 22:59:59 for Requisition Line with Item "I1".
        FilterOnRequisitionLine(RequisitionLine, Item."No.");
        RequisitionLine.FindFirst();
        RequisitionLine.Validate("Starting Time", 225959T);
        RequisitionLine.Modify(true);

        // [THEN] Requisition Line for "I1" has Starting DateTime = 27.01 22:59:59 (Friday), Ending DateTime = 30.01 09:00 (Monday).
        VerifyRequisitionLineStartEndDateTime(
            Item."No.", RequisitionLine."Ref. Order Type"::"Prod. Order", "Action Message Type"::New,
            CreateDateTime(ShipmentDate - 3, 225959T), CreateDateTime(ShipmentDate, 090000T));
    end;

    [Test]
    procedure CalcRegenPlanForwardWhenCapacityConstrainedResourceAndWaitTimeOnHolidays()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        ShipmentDate: Date;
    begin
        // [SCENARIO 415709] Calculate Regen. Plan forward for production item when it has Routing with Wait time only and Wait Time on holidays.
        Initialize();

        // [GIVEN] Manufacturing Setup has Normal Starting Time 00:00:00 and Normal Ending Time 23:59:59.
        UpdateManufacturingSetupNormalStartingEndingTime(000000T, 235959T);

        // [GIVEN] Item "I1" with Replenishment System "Prod. Order".
        // [GIVEN] Certified Routing for Item "I1" with one line for Work Center "A" (works 0800 - 1600). Wait Time is 2 hours.
        // [GIVEN] Work Center "A" is a capacity constrained resource.
        CreateProductionItemWithOneLineRouting(Item, 0, 0, 120, 0, 080000T, 160000T);
        RoutingHeader.Get(Item."Routing No.");
        RoutingLine.SetRange("Routing No.", RoutingHeader."No.");
        RoutingLine.FindFirst();
        CreateCapacityConstrainedResourceForWorkCenter(RoutingLine."No.", 50);

        // [GIVEN] Sales Order for Item "I1" with Shipment Date on Monday, 30.01.23.
        ShipmentDate := CalcDate('<1W + WD1>', WorkDate());
        LibrarySales.CreateSalesDocumentWithItem(
            SalesHeader, SalesLine, "Sales Document Type"::Order, '', Item."No.", 1, '', ShipmentDate);

        // [GIVEN] Requisition Line for "I1" with Starting DateTime = 29.01 22:00 (Sunday), Ending DateTime = 29.01 23:59:59 (Sunday).
        Item.SetFilter("No.", Item."No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, ShipmentDate - 10, ShipmentDate + 10);

        // [WHEN] Set Starting Time 21:00 for Requisition Line with Item "I1".
        FilterOnRequisitionLine(RequisitionLine, Item."No.");
        RequisitionLine.FindFirst();
        RequisitionLine.Validate("Starting Time", 210000T);
        RequisitionLine.Modify(true);

        // [THEN] Requisition Line for "I1" has Starting DateTime = 29.01 21:00 (Sunday), Ending DateTime = 29.01 23:00 (Sunday).
        VerifyRequisitionLineStartEndDateTime(
            Item."No.", RequisitionLine."Ref. Order Type"::"Prod. Order", "Action Message Type"::New,
            CreateDateTime(ShipmentDate - 1, 210000T), CreateDateTime(ShipmentDate - 1, 230000T));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure UnplannedPurchaseLineDoesNotAffectFollowingPlanning()
    var
        BlockedItem: Record Item;
        Item: Record Item;
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Blocked]
        // [SCENARIO 434325] If a planning line is not carried out due to the blocked item, this must not affect following planning lines.
        Initialize();

        // [GIVEN] Item "A" set up for blocked purchasing.
        LibraryInventory.CreateItem(BlockedItem);
        BlockedItem.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        BlockedItem.Validate("Purchasing Blocked", true);
        BlockedItem.Modify(true);

        // [GIVEN] Item "B" with vendor "V".
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);

        // [GIVEN] Create two lines in planning worksheet - one per items "A" and "B".
        LibraryPlanning.SelectRequisitionWkshName(RequisitionWkshName, RequisitionWkshName."Template Type"::Planning);
        CreateRequisitionLineForNewPurchase(RequisitionLine, RequisitionWkshName, BlockedItem."No.");
        CreateRequisitionLineForNewPurchase(RequisitionLine, RequisitionWkshName, Item."No.");

        // [WHEN] Carry out action messages.
        LibraryVariableStorage.Enqueue(StrSubstNo(CannotPurchaseItemMsg, BlockedItem."No."));
        RequisitionLine.SetFilter("No.", '%1|%2', BlockedItem."No.", Item."No.");
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);

        // [THEN] Purchase order for item "B" has been created.
        // [THEN] "Buy-from Vendor No." = "V" on the header and the line.
        PurchaseHeader.SetRange("Buy-from Vendor No.", Item."Vendor No.");
        PurchaseHeader.FindFirst();
        PurchaseLine.SetRange("No.", Item."No.");
        LibraryPurchase.FindFirstPurchLine(PurchaseLine, PurchaseHeader);
        PurchaseLine.TestField("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure GrossRequirementInItemAvailByBOMLevelDoNotIncludeSupplies()
    var
        ChildItem: Record Item;
        Item: Record Item;
        BOMBuffer: Record "BOM Buffer";
        ReceiptQty: Decimal;
        Quantities: array[4] of Decimal;
        ShipmentDates: array[4] of Date;
        i: Integer;
    begin
        // [FEATURE] [Item Availability by BOM]
        // [SCENARIO 457299] Gross Requirement in Item Availability by BOM Level respects Demand Date and does not consider supplies.
        Initialize();
        for i := 1 to ArrayLen(ShipmentDates) do
            ShipmentDates[i] := WorkDate() + 30 * i;
        ReceiptQty := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] Item with BOM.
        CreateOrderItemSetup(ChildItem, Item);

        // [GIVEN] Sales order with 4 lines -
        // [GIVEN] Line 1: Quantity = 50, Shipment Date = WorkDate() + 30 days.
        // [GIVEN] Line 2: Quantity = 100, Shipment Date = WorkDate() + 60 days.
        // [GIVEN] Line 3: Quantity = 150, Shipment Date = WorkDate() + 90 days.
        // [GIVEN] Line 4: Quantity = 200, Shipment Date = WorkDate() + 120 days.
        CreateSalesOrderWithFourLinesOfSingleItemWithSpecifiedShipmentDates(Quantities, Item."No.", ShipmentDates);

        // [GIVEN] Purchase order with Quantity = 10, Expected Receipt Date = WorkDate() + 70 days.
        CreatePurchaseOrderWithReceiptDate(Item."No.", ReceiptQty, WorkDate() + 70);

        // [WHEN] Calculate BOM tree for Item Availability by BOM level page with Demand Date = WorkDate() + 100 days.
        Item.SetRecFilter();
        CreateBOMTree(BOMBuffer, Item, WorkDate() + 100);

        // [THEN] Scheduled Receipt = 10.
        // [THEN] Gross Requirement includes the first three lines of the sales order and therefore equals to 50 + 100 + 150 = 300.
        VerifyGrossReqAndScheduledRecOnBOMTree(BOMBuffer, Item."No.", ReceiptQty, Quantities[1] + Quantities[2] + Quantities[3]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CarryOutActionShouldThrowErrorIfProductionBlockedIsOutputOnItem()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        TempDocumentEntry: Record "Document Entry" temporary;
        MfgCarryOutAction: Codeunit "Mfg. Carry Out Action";
    begin
        // [SCENARIO 382546] Verify "Carry Out Action" should throw error if "Production Blocked" is Output on "Item".
        Initialize();

        // [GIVEN] Create Requisition Line.
        CreateReqLine(RequisitionLine);

        // [GIVEN] Update "Production Blocked" on Item.
        Item.Get(RequisitionLine."No.");
        Item.Validate("Production Blocked", Item."Production Blocked"::Output);
        Item.Modify(true);

        // [WHEN] Call CarryOutAction.InsertProductionOrder().
        asserterror MfgCarryOutAction.InsertProductionOrder(RequisitionLine, "Planning Create Prod. Order"::Planned, TempDocumentEntry);

        // [VERIFY] Verify error message if "Production Blocked" is Output on Item.
        Assert.ExpectedError(StrSubstNo(ProductionBlockedOutputItemErr, Item.TableCaption(), Item."No.", Item.FieldCaption("Production Blocked"), Item."Production Blocked"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CarryOutActionShouldThrowErrorIfProductionBlockedIsOutputOnItemVariant()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        RequisitionLine: Record "Requisition Line";
        TempDocumentEntry: Record "Document Entry" temporary;
        MfgCarryOutAction: Codeunit "Mfg. Carry Out Action";
    begin
        // [SCENARIO 382546] Verify "Carry Out Action" should throw error if "Production Blocked" is Output on "Item Variant".
        Initialize();

        // [GIVEN] Create Requisition Line.
        CreateReqLine(RequisitionLine);

        // [GIVEN] Update "Production Blocked" on "Item Variant".
        ItemVariant.Get(RequisitionLine."No.", RequisitionLine."Variant Code");
        ItemVariant.Validate("Production Blocked", ItemVariant."Production Blocked"::Output);
        ItemVariant.Modify(true);

        // [WHEN] Call CarryOutAction.InsertProductionOrder().
        asserterror MfgCarryOutAction.InsertProductionOrder(RequisitionLine, "Planning Create Prod. Order"::Planned, TempDocumentEntry);

        // [VERIFY] Verify error message if "Production Blocked" is Output on "Item Variant".
        Assert.ExpectedError(StrSubstNo(ProductionBlockedOutputItemVariantErr, ItemVariant.Code, Item.TableCaption(), ItemVariant."Item No."));
    end;

    local procedure Initialize()
    var
        UntrackedPlanningElement: Record "Untracked Planning Element";
        RequisitionLine: Record "Requisition Line";
        ReservationEntry: Record "Reservation Entry";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Supply Planning -III");
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();
        UntrackedPlanningElement.DeleteAll();
        RequisitionLine.DeleteAll();
        ReservationEntry.DeleteAll();

        LibraryApplicationArea.EnableEssentialSetup();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Supply Planning -III");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        NoSeriesSetup();
        ItemJournalSetup();
        OutputJournalSetup();
        CreateLocationSetup();

        isInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        LibrarySetupStorage.Save(DATABASE::"Manufacturing Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Supply Planning -III");
    end;

    local procedure NoSeriesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify(true);

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure ItemJournalSetup()
    begin
        ItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalTemplate.Modify(true);

        ItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", '');  // Required to avoid Document No. mismatch.
        ItemJournalBatch.Modify(true);
    end;

    local procedure OutputJournalSetup()
    begin
        OutputItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(OutputItemJournalTemplate, OutputItemJournalTemplate.Type::Output);

        OutputItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(
          OutputItemJournalBatch, OutputItemJournalTemplate.Type, OutputItemJournalTemplate.Name);
    end;

    local procedure CreateLocationSetup()
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationYellow);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationRed);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);
    end;

    local procedure UpdateManufacturingSetup(DocNoIsProdOrderNo: Boolean) NewDocNoIsProdOrderNo: Boolean
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        NewDocNoIsProdOrderNo := ManufacturingSetup."Doc. No. Is Prod. Order No.";
        ManufacturingSetup.Validate("Doc. No. Is Prod. Order No.", DocNoIsProdOrderNo);
        ManufacturingSetup.Modify(true);
        exit(NewDocNoIsProdOrderNo);
    end;

    local procedure UpdateManufacturingSetupCombinedMPSAndMRP(NewCombinedMPSMRPCalculation: Boolean) OldCombinedMPSMRPCalculation: Boolean
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        OldCombinedMPSMRPCalculation := InventorySetup."Combined MPS/MRP Calculation";
        InventorySetup.Validate("Combined MPS/MRP Calculation", NewCombinedMPSMRPCalculation);
        InventorySetup.Modify(true);
    end;

    local procedure CreateSalesOrderAndFirmPlannedProductionOrderAsDemandAndSupply(var TopLevelItem: Record Item; var Level1Item: Record Item; var Level2Item: Record Item; var SalesHeader: Record "Sales Header"; ShipmentDate: Date; LotPeriod: Text)
    var
        Location: Record Location;
        RequisitionLine: Record "Requisition Line";
    begin
        LibraryWarehouse.CreateLocation(Location);
        CreateMakeToOrderCompoundItem(TopLevelItem, Level1Item, Level2Item, LotPeriod);
        CreateSalesOrderWithLocationAndShipmentDate(SalesHeader, TopLevelItem."No.", Location.Code, ShipmentDate);

        PlanWrkShtCalcRegenPlanAndCarryOutActionMessage(
          StrSubstNo('%1|%2|%3', TopLevelItem."No.", Level1Item."No.", Level2Item."No."),
          CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', ShipmentDate), RequisitionLine."Action Message"::New);
    end;

    local procedure CreateItem(var Item: Record Item; ReorderingPolicy: Enum "Reordering Policy"; ReplenishmentSystem: Enum "Replenishment System")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);
    end;

    local procedure CreateMakeToOrderItem(var Item: Record Item; ReorderingPolicy: Enum "Reordering Policy"; ProductionBOMNo: Code[20]; LotAccumulationPeriod: Text; ReschedulingPeriod: Text)
    var
        LotAccumulationPeriodDF: DateFormula;
        ReschedulingPeriodDF: DateFormula;
    begin
        Evaluate(LotAccumulationPeriodDF, LotAccumulationPeriod);
        Evaluate(ReschedulingPeriodDF, ReschedulingPeriod);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Order");
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Validate("Lot Accumulation Period", LotAccumulationPeriodDF);
        Item.Validate("Rescheduling Period", ReschedulingPeriodDF);
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure CreateMakeToOrderCompoundItem(var TopLevelItem: Record Item; var Level1Item: Record Item; var Level2Item: Record Item; LotPeriod: Text)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateMakeToOrderItem(Level2Item, Level2Item."Reordering Policy"::Order, ProductionBOMHeader."No.", '', '');
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, Level2Item."No.", 1);
        CreateMakeToOrderItem(Level1Item, Level1Item."Reordering Policy"::Order, ProductionBOMHeader."No.", '', '');
        Clear(ProductionBOMHeader);
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, Level1Item."No.", 1);
        CreateMakeToOrderItem(
          TopLevelItem, TopLevelItem."Reordering Policy"::"Lot-for-Lot", ProductionBOMHeader."No.", LotPeriod, LotPeriod);
    end;

    local procedure CreateLotForLotItem(var Item: Record Item; ItemReplenishmentSystem: Enum "Replenishment System"; SafetyStockQuantity: Decimal)
    begin
        // Create Lot-for-Lot Item.
        CreateItem(Item, Item."Reordering Policy"::"Lot-for-Lot", ItemReplenishmentSystem);
        Item.Validate("Safety Stock Quantity", SafetyStockQuantity);
        Item.Validate("Include Inventory", true);
        Item.Modify(true);
    end;

    local procedure CreateProdOrderItemWithProductionBOM(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure CreateFRQItem(var Item: Record Item; ItemReplenishmentSystem: Enum "Replenishment System"; ReorderQuantity: Decimal; ReorderPoint: Decimal; SafetyStockQty: Decimal)
    begin
        // Create Fixed Reorder Qty. Item.
        CreateItem(Item, Item."Reordering Policy"::"Fixed Reorder Qty.", ItemReplenishmentSystem);
        Item.Validate("Reorder Quantity", ReorderQuantity);
        Item.Validate("Reorder Point", ReorderPoint);
        Item.Validate("Safety Stock Quantity", SafetyStockQty);
        Item.Modify(true);
    end;

    local procedure CreateFRQItemSetup(var ChildItem: Record Item; var Item: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateFRQItem(
          ChildItem, Item."Replenishment System"::Purchase, LibraryRandom.RandInt(10) + 100,
          LibraryRandom.RandInt(10) + 10, LibraryRandom.RandInt(10));  // Quantity proportion required for test.
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem."No.");
        CreateFRQItem(
          Item, Item."Replenishment System"::"Prod. Order", LibraryRandom.RandInt(10) + 100,
          LibraryRandom.RandInt(10) + 10, LibraryRandom.RandInt(10));  // Quantity proportion required for test.
        UpdateItemProductionBOMNo(Item, ProductionBOMHeader."No.");
    end;

    local procedure CreateMQItem(var Item: Record Item; MaximumInventory: Decimal; ReorderPoint: Decimal; OrderMultiple: Decimal)
    begin
        // Create Maximum Qty. Item.
        CreateItem(Item, Item."Reordering Policy"::"Maximum Qty.", Item."Replenishment System"::Purchase);

        // Maximum Qty. Planning parameters.
        Item.Validate("Maximum Inventory", MaximumInventory);
        Item.Validate("Reorder Point", ReorderPoint);
        Item.Validate("Order Multiple", OrderMultiple);
        Item.Modify(true);
    end;

    local procedure CreateMOQItem(var Item: Record Item; MaximumOrderQty: Decimal)
    begin
        CreateItem(Item, Item."Reordering Policy"::"Lot-for-Lot", Item."Replenishment System"::Purchase);
        Item.Validate("Maximum Order Quantity", MaximumOrderQty);
        Item.Modify(true);
    end;

    local procedure CreateOrderItemSetup(var ChildItem: Record Item; var Item: Record Item) QtyPer: Integer
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // Create parent and child Order Items setup.
        CreateItem(ChildItem, ChildItem."Reordering Policy"::Order, ChildItem."Replenishment System"::Purchase);
        QtyPer := CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem."No.");
        CreateItem(Item, Item."Reordering Policy"::Order, Item."Replenishment System"::"Prod. Order");
        UpdateItemProductionBOMNo(Item, ProductionBOMHeader."No.");
    end;

    local procedure CreateProdItemWithComponentWithMonthPlanningPeriods(var ParentItem: Record Item; var ChildItem: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
        PlanningPeriodDateFormula: DateFormula;
    begin
        Evaluate(PlanningPeriodDateFormula, '<1M>');
        CreateItem(ChildItem, ChildItem."Reordering Policy"::"Lot-for-Lot", ChildItem."Replenishment System"::"Prod. Order");
        UpdateItemLotAccumulationPeriod(ChildItem, PlanningPeriodDateFormula);
        CreateItem(ParentItem, ParentItem."Reordering Policy"::Order, ParentItem."Replenishment System"::"Prod. Order");
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, ChildItem."No.", 1);
        UpdateItemProductionBOMNo(ParentItem, ProductionBOMHeader."No.");
    end;

    local procedure CreatePurchaseOrderWithLocation(ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseOrder(ItemNo, Quantity);
        SelectPurchaseOrderLine(PurchaseLine, ItemNo);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateTransferOrderWithTracking(ItemNo: Code[20]; FromLocationCode: Code[10]; ToLocationCode: Code[10]; Quantity: Decimal)
    var
        TransferLine: Record "Transfer Line";
    begin
        CreateTransferOrderWithTransferRoute(TransferLine, ItemNo, FromLocationCode, ToLocationCode, Quantity);
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);
    end;

    local procedure CreateBaseCalendarAndChanges(EndDate: Date; NonWorkDays: Integer): Code[10]
    var
        BaseCalendar: Record "Base Calendar";
        BaseCalendarChange: Record "Base Calendar Change";
        NWDate: Date;
        i: Integer;
    begin
        LibraryService.CreateBaseCalendar(BaseCalendar);
        BaseCalendarChange.Init();
        BaseCalendarChange."Base Calendar Code" := BaseCalendar.Code;
        NWDate := EndDate;
        for i := 1 to NonWorkDays do begin
            LibraryInventory.CreateBaseCalendarChange(
              BaseCalendarChange, BaseCalendar.Code, BaseCalendarChange."Recurring System"::"Annual Recurring",
              NWDate, BaseCalendarChange.Day::" ");
            NWDate -= 1;
        end;
        exit(BaseCalendar.Code);
    end;

    local procedure CreateBaseCalendarWithNonWorkingWeekends(var BaseCalendar: Record "Base Calendar")
    var
        BaseCalendarChange: Record "Base Calendar Change";
    begin
        LibraryService.CreateBaseCalendar(BaseCalendar);
        LibraryInventory.CreateBaseCalendarChange(
            BaseCalendarChange, BaseCalendar.Code, BaseCalendarChange."Recurring System"::"Weekly Recurring", 0D, BaseCalendarChange.Day::Saturday);
        LibraryInventory.CreateBaseCalendarChange(
            BaseCalendarChange, BaseCalendar.Code, BaseCalendarChange."Recurring System"::"Weekly Recurring", 0D, BaseCalendarChange.Day::Sunday);
    end;

    local procedure CreateWorkCenterWithShopCalendar(UOMType: Enum "Capacity Unit of Measure"; ShopCalendarCode: Code[10]; Efficiency: Decimal; Capacity: Decimal; DueDate: Date): Code[20]
    var
        WorkCenter: Record "Work Center";
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
    begin
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, UOMType);
        WorkCenter.Validate("Unit of Measure Code", CapacityUnitOfMeasure.Code);
        WorkCenter.Validate("Shop Calendar Code", ShopCalendarCode);
        WorkCenter.Validate(Efficiency, Efficiency);
        WorkCenter.Validate(Capacity, Capacity);
        WorkCenter.Modify(true);

        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-2M>', DueDate), CalcDate('<+2M>', DueDate));
        exit(WorkCenter."No.");
    end;

    local procedure CreateShopCalendarAllWeek(): Code[10]
    var
        ShopCalendar: Record "Shop Calendar";
        WorkShift: Record "Work Shift";
        ShopCalendWorkDays: Record "Shop Calendar Working Days";
        Day: Integer;
    begin
        LibraryManufacturing.CreateShopCalendarCode(ShopCalendar);
        LibraryManufacturing.CreateWorkShiftCode(WorkShift);
        for Day := ShopCalendWorkDays.Day::Monday to ShopCalendWorkDays.Day::Sunday do
            LibraryManufacturing.CreateShopCalendarWorkingDays(ShopCalendWorkDays, ShopCalendar.Code, Day, WorkShift.Code, 080000T, 160000T);
        exit(ShopCalendar.Code);
    end;

    local procedure CreateProductionItemWithOneLineRouting(var Item: Record Item; RunTime: Decimal)
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkCenterCode: Code[20];
    begin
        WorkCenterCode := CreateWorkCenterWithShopCalendar("Capacity Unit of Measure"::Minutes, CreateShopCalendarAllWeek(), 100, 1, WorkDate());
        CreateItem(Item, Item."Reordering Policy"::"Lot-for-Lot", Item."Replenishment System"::"Prod. Order");
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '10', "Capacity Type Routing"::"Work Center", WorkCenterCode);
        RoutingLine.Validate("Run Time", RunTime);
        RoutingLine.Modify(true);
        UpdateStatusOnRoutingHeader(RoutingHeader, "Routing Status"::Certified);
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);
    end;

    local procedure CreateProductionItemWithOneLineRouting(var Item: Record Item; SetupTime: Decimal; RunTime: Decimal; WaitTime: Decimal; MoveTime: Decimal; WorkCenterStartTime: Time; WorkCenterEndTime: Time)
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkCenterCode: Code[20];
    begin
        WorkCenterCode :=
            CreateWorkCenterWithShopCalendar(
                "Capacity Unit of Measure"::Minutes,
                LibraryManufacturing.UpdateShopCalendarWorkingDaysCustomTime(WorkCenterStartTime, WorkCenterEndTime), 100, 1, WorkDate());
        CreateItem(Item, Item."Reordering Policy"::"Lot-for-Lot", Item."Replenishment System"::"Prod. Order");
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '10', "Capacity Type Routing"::"Work Center", WorkCenterCode);
        RoutingLine.Validate("Setup Time", SetupTime);
        RoutingLine.Validate("Run Time", RunTime);
        RoutingLine.Validate("Wait Time", WaitTime);
        RoutingLine.Validate("Move Time", MoveTime);
        RoutingLine.Modify(true);
        UpdateStatusOnRoutingHeader(RoutingHeader, "Routing Status"::Certified);
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);
    end;

    local procedure CreateCapacityConstrainedResourceForWorkCenter(WorkCenterNo: Code[20]; CriticalLoadPct: Decimal)
    var
        CapacityConstrainedResource: Record "Capacity Constrained Resource";
    begin
        CapacityConstrainedResource.Init();
        CapacityConstrainedResource.Validate("Capacity Type", "Capacity Type"::"Work Center");
        CapacityConstrainedResource.Validate("Capacity No.", WorkCenterNo);
        CapacityConstrainedResource.Validate("Critical Load %", CriticalLoadPct);
        CapacityConstrainedResource.Insert(true);
    end;

    local procedure UpdateItemBlocked(var Item: Record Item)
    begin
        // Block Item.
        Item.Validate(Blocked, true);
        Item.Modify(true);
    end;

    local procedure UpdateItemProductionBOMNo(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity)
    end;

    local procedure CreateSalesOrderWithFourLinesOfSingleItemWithSpecifiedShipmentDates(var Quantities: array[4] of Decimal; ItemNo: Code[20]; ShipmentDates: array[4] of Date)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        i: Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        for i := 1 to ArrayLen(ShipmentDates) do begin
            Quantities[i] := LibraryRandom.RandIntInRange(100, 200);
            LibrarySales.CreateSalesLineWithShipmentDate(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, ShipmentDates[i], Quantities[i]);
        end;
    end;

    local procedure CreateSalesOrdersFromBlanketSalesOrderLines(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; QtyToShipCoeffs: Text)
    var
        SalesLine: Record "Sales Line";
        Coeff: Integer;
        i: Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order", LibrarySales.CreateCustomerNo());
        for i := 1 to 3 do begin
            Evaluate(Coeff, SelectStr(i, QtyToShipCoeffs));
            LibrarySales.CreateSalesLineWithShipmentDate(
              SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDate(30), LibraryRandom.RandInt(100));
            SalesLine.Validate("Qty. to Ship", Coeff * SalesLine."Qty. to Ship");
            SalesLine.Modify(true);
        end;

        LibrarySales.BlanketSalesOrderMakeOrder(SalesHeader);
    end;

    local procedure CreateProductionBOMVersionWithStartingDate(var ProductionBOMVersion: Record "Production BOM Version"; ProductionBOMNo: Code[20]; UnitOfMeasure: Code[10]; StartingDate: Date)
    begin
        LibraryManufacturing.CreateProductionBOMVersion(
          ProductionBOMVersion, ProductionBOMNo,
          LibraryUtility.GenerateRandomCode(ProductionBOMVersion.FieldNo("Version Code"), DATABASE::"Production BOM Version"),
          UnitOfMeasure);
        ProductionBOMVersion.Validate("Starting Date", StartingDate);
        ProductionBOMVersion.Validate(Status, ProductionBOMVersion.Status::Certified);
        ProductionBOMVersion.Modify(true);
    end;

    local procedure UpdateItemFirmPlannedProductionOrderDueDate(ItemNo: Code[20]; DateDelta: Integer) UpdatedDueDate: Date
    var
        ProductionOrder: Record "Production Order";
    begin
        FindFirmPlannedProductionOrderByItemNo(ProductionOrder, ItemNo);
        UpdatedDueDate := ProductionOrder."Due Date" + DateDelta;
        ProductionOrder.SetUpdateEndDate();
        ProductionOrder.Validate("Due Date", UpdatedDueDate);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure FindFirmPlannedProductionOrderByItemNo(var ProductionOrder: Record "Production Order"; ItemNo: Code[20])
    begin
        ProductionOrder.SetRange(Status, ProductionOrder.Status::"Firm Planned");
        ProductionOrder.SetRange("Source Type", ProductionOrder."Source Type"::Item);
        ProductionOrder.SetRange("Source No.", ItemNo);
        ProductionOrder.FindFirst();
    end;

    local procedure CreateAndCertifyProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; ItemNo: Code[20]) QtyPer: Integer
    begin
        QtyPer := LibraryRandom.RandInt(5);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ItemNo, QtyPer);
    end;

    local procedure CreateAndCertifyProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; ItemNo: Code[20]; QtyPer: Integer)
    var
        ProductionBOMLine: Record "Production BOM Line";
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", QtyPer);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure FilterOnRequisitionLine(var RequisitionLine: Record "Requisition Line"; No: Code[20])
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", No);
    end;

    local procedure SelectRequisitionLine(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20])
    begin
        FilterOnRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.FindSet();
    end;

    local procedure CreateAndRefreshReleasedProductionOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CalcRegenPlanForPlanWksh(ItemNo: Code[20])
    var
        Item: Record Item;
        EndDate: Date;
    begin
        Item.Get(ItemNo);
        EndDate := GetRequiredDate(10, 30, WorkDate());  // End Date relative to Workdate.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), EndDate);
    end;

    local procedure CalcRegenPlanForItemsRespectPlanningParamsFromNowToDate(ItemFilter: Text; ToDate: Date)
    var
        Item: Record Item;
    begin
        Item.SetFilter("No.", ItemFilter);
        LibraryPlanning.CalcRegenPlanForPlanWkshPlanningParams(Item, WorkDate(), ToDate, true);
    end;

    local procedure CalcNetChangePlanForPlanWksh(ItemNo: Code[20])
    var
        Item: Record Item;
        EndDate: Date;
    begin
        Item.Get(ItemNo);
        EndDate := GetRequiredDate(10, 30, WorkDate());  // End Date relative to Workdate.
        LibraryPlanning.CalcNetChangePlanForPlanWksh(Item, WorkDate(), EndDate, false);
    end;

    local procedure SelectItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    begin
        ItemJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        ItemJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        ItemJournalLine.FindFirst();
    end;

    local procedure SelectPurchaseOrderLine(var PurchaseLine: Record "Purchase Line"; No: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst();
    end;

    local procedure SelectProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ItemNo: Code[20])
    begin
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::"Firm Planned");
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst();
    end;

    local procedure CreateAndPostOutputJournal(ProductionOrderNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateOutputJournalWithExlpodeRouting(ProductionOrderNo);
        SelectItemJournalLine(ItemJournalLine, OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
    end;

    local procedure CreateOutputJournalWithExlpodeRouting(ProductionOrderNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.ClearItemJournal(OutputItemJournalTemplate, OutputItemJournalBatch);
        LibraryManufacturing.CreateOutputJournal(ItemJournalLine, OutputItemJournalTemplate, OutputItemJournalBatch, '', ProductionOrderNo);
        LibraryManufacturing.OutputJnlExplodeRoute(ItemJournalLine);
    end;

    local procedure CreateStockkeepingUnitWithReorderingPolicy(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; ReorderingPolicy: Enum "Reordering Policy")
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, LocationCode, ItemNo, VariantCode);
        StockkeepingUnit.Validate("Reordering Policy", ReorderingPolicy);
        StockkeepingUnit.Modify(true);
    end;

    local procedure CalcRegenPlanAndCarryOutActionMessage(var TempRequisitionLine: Record "Requisition Line" temporary; ItemNo: Code[20])
    begin
        CalcRegenPlanForPlanWksh(ItemNo);
        CopyRequisitionLineToTemp(TempRequisitionLine, ItemNo);  // Copy Lines to Temporary table so that it can be accessed later for verification.

        // Accept and Carry Out Action message.
        AcceptActionMessage(ItemNo);
        CarryOutActionMessage(ItemNo);
    end;

    local procedure PlanWrkShtCalcRegenPlanAndCarryOutActionMessage(ItemFilter: Text; FromDate: Date; ToDate: Date; ActionMessage: Enum "Action Message Type")
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        Item.SetFilter("No.", ItemFilter);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, FromDate, ToDate);
        RequisitionLine.SetFilter("No.", ItemFilter);
        RequisitionLine.SetRange("Ref. Order Type", RequisitionLine."Ref. Order Type"::"Prod. Order");
        RequisitionLine.SetRange("Action Message", ActionMessage);
        RequisitionLine.ModifyAll("Accept Action Message", true, true);
        RequisitionLine.FindFirst();
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
    end;

    local procedure CopyRequisitionLineToTemp(var TempRequisitionLine: Record "Requisition Line" temporary; ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        SelectRequisitionLine(RequisitionLine, ItemNo);
        repeat
            TempRequisitionLine := RequisitionLine;
            TempRequisitionLine.Insert();
        until RequisitionLine.Next() = 0;
    end;

    local procedure AcceptActionMessage(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        SelectRequisitionLine(RequisitionLine, ItemNo);
        repeat
            RequisitionLine.Validate("Accept Action Message", true);
            RequisitionLine.Modify(true);
        until RequisitionLine.Next() = 0;
    end;

    local procedure CarryOutActionMessage(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        SelectRequisitionLine(RequisitionLine, ItemNo);
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
    end;

    local procedure DeleteNewPurchaseOrder(ItemNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        SelectPurchaseOrderLine(PurchaseLine, ItemNo);
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseLine."Document No.");
        PurchaseHeader.Delete(true);
    end;

    local procedure DeleteNewProductionOrder(ItemNo: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
    begin
        SelectProdOrderLine(ProdOrderLine, ItemNo);
        ProductionOrder.Get(ProductionOrder.Status::"Firm Planned", ProdOrderLine."Prod. Order No.");
        ProductionOrder.Delete(true);
    end;

    local procedure DeleteProductionForecast(ProductionForecastName: Record "Production Forecast Name")
    begin
        LibraryVariableStorage.Enqueue(DeleteProductionForecastConfirmMessageQst);
        ProductionForecastName.Delete(true);
    end;

    local procedure GetRequiredDate(Days: Integer; IncludeAdditionalPeriod: Integer; RelativeDate: Date) NewDate: Date
    begin
        // Calculating a New Date relative to WorkDate or Lot Accumulation period dates.
        NewDate := CalcDate('<' + Format(LibraryRandom.RandInt(Days) + IncludeAdditionalPeriod) + 'D>', RelativeDate);
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; EntryType: Enum "Item Ledger Document Type") Quantity: Decimal
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItemJournalLine(ItemJournalLine, ItemNo, EntryType, Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure UpdateItemInventoryOnLocation(ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, ItemNo, ItemJournalLine."Entry Type"::"Positive Adjmt.", Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; EntryType: Enum "Item Ledger Document Type");
    begin
        CreateItemJournalLine(ItemJournalLine, ItemNo, EntryType, LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; EntryType: Enum "Item Ledger Document Type"; Quantity: Decimal);
    begin
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
            ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Quantity);
    end;

    local procedure CreateAndReleaseSalesOrderAsSpecialOrder(ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesOrder(SalesHeader, ItemNo, Quantity);
        UpdateSalesLinePurchasingCode(SalesHeader."No.");
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure UpdateSalesLinePurchasingCode(DocumentNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        Purchasing: Record Purchasing;
    begin
        CreatePurchasingCodeWithSpecialOrder(Purchasing);
        SelectSalesOrderLine(SalesLine, DocumentNo);
        SalesLine.Validate("Purchasing Code", Purchasing.Code);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchasingCodeWithSpecialOrder(var Purchasing: Record Purchasing)
    begin
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Special Order", true);
        Purchasing.Modify(true);
    end;

    local procedure CreateRequisitionLine(var RequisitionLine: Record "Requisition Line"; TemplateType: Enum "Req. Worksheet Template Type")
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        RequisitionWkshName.SetRange("Template Type", TemplateType);
        RequisitionWkshName.FindFirst();
        RequisitionLine.Init();
        RequisitionLine.Validate("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.Validate("Journal Batch Name", RequisitionWkshName.Name);
    end;

    local procedure CreateRequisitionLineFromSpecialOrder(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Template Type"::"Req.");
        LibraryPlanning.GetSpecialOrder(RequisitionLine, ItemNo);
    end;

    local procedure CreateRequisitionLineForNewPurchase(var RequisitionLine: Record "Requisition Line"; RequisitionWkshName: Record "Requisition Wksh. Name"; ItemNo: Code[20])
    begin
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", ItemNo);
        RequisitionLine.Validate(Quantity, LibraryRandom.RandInt(10));
        RequisitionLine.Validate("Action Message", RequisitionLine."Action Message"::New);
        RequisitionLine.Validate("Accept Action Message", true);
        RequisitionLine.Modify(true);
    end;

    local procedure CreatePurchaseOrder(ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure CreatePurchaseOrderWithReceiptDate(ItemNo: Code[20]; Quantity: Decimal; ExpectedReceiptDate: Date)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', ItemNo, Quantity, '', ExpectedReceiptDate);
    end;

    local procedure CalculatePlanForRequisitionWorksheet(Item: Record Item)
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        EndDate: Date;
    begin
        SelectRequisitionTemplate(ReqWkshTemplate, ReqWkshTemplate.Type::"Req.");
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        EndDate := GetRequiredDate(10, 30, WorkDate());  // End Date relative to Workdate.
        LibraryPlanning.CalculatePlanForReqWksh(Item, ReqWkshTemplate.Name, RequisitionWkshName.Name, WorkDate(), EndDate);
    end;

    local procedure SelectDateWithSafetyLeadTime(DateValue: Date; SignFactor: Integer): Date
    var
        InventorySetup: Record "Inventory Setup";
    begin
        // Add Safety lead time to the required date and return the Date value.
        InventorySetup.Get();
        if SignFactor < 0 then
            exit(CalcDate('<-' + Format(InventorySetup."Default Safety Lead Time") + '>', DateValue));
        exit(CalcDate('<' + Format(InventorySetup."Default Safety Lead Time") + '>', DateValue));
    end;

    local procedure SelectSalesOrderLine(var SalesLine: Record "Sales Line"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.FindFirst();
    end;

    local procedure FindSalesLines(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("No.", ItemNo);
        SalesLine.FindSet();
    end;

    local procedure CreateProductionForecastSetup(ItemNo: Code[20]; MultipleLines: Boolean; var ProductionForecastName: Record "Production Forecast Name") ForecastQty: Integer
    begin
        // Create Two Production Forecast with same random quantities but different dates, based on WORKDATE.
        LibraryManufacturing.CreateProductionForecastName(ProductionForecastName);
        LibraryPlanning.SetDemandForecast(ProductionForecastName.Name);

        ForecastQty := LibraryRandom.RandInt(10) + 100;   // Large Random Quantity Required.
        CreateAndUpdateProductionForecast(ProductionForecastName.Name, WorkDate(), ItemNo, ForecastQty);
        if MultipleLines then
            CreateAndUpdateProductionForecast(ProductionForecastName.Name, GetRequiredDate(1, 1, WorkDate()), ItemNo, ForecastQty);
    end;

    local procedure CreateProductionForecastSetupAtDate(var ProductionForecastName: Record "Production Forecast Name"; ItemNo: Code[20]; ForecastEntryDate: Date) ForecastQty: Integer
    begin
        LibraryManufacturing.CreateProductionForecastName(ProductionForecastName);
        LibraryPlanning.SetDemandForecast(ProductionForecastName.Name);
        ForecastQty := LibraryRandom.RandIntInRange(100, 1000);
        CreateAndUpdateProductionForecast(ProductionForecastName.Name, ForecastEntryDate, ItemNo, ForecastQty);
    end;

    local procedure CreateAndUpdateProductionForecast(Name: Code[10]; Date: Date; ItemNo: Code[20]; Quantity: Decimal)
    var
        ProductionForecastEntry: Record "Production Forecast Entry";
    begin
        LibraryManufacturing.CreateProductionForecastEntry(ProductionForecastEntry, Name, ItemNo, '', Date, false);  // Component Forecast - FALSE.
        ProductionForecastEntry.Validate("Forecast Quantity (Base)", Quantity);
        ProductionForecastEntry.Modify(true);
    end;

    local procedure CreateRequisitionWorksheetName(var RequisitionWkshName: Record "Requisition Wksh. Name")
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        SelectRequisitionTemplate(ReqWkshTemplate, ReqWkshTemplate.Type::Planning);
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
    end;

    local procedure SelectRequisitionTemplate(var ReqWkshTemplate: Record "Req. Wksh. Template"; Type: Enum "Req. Worksheet Template Type")
    begin
        ReqWkshTemplate.SetRange(Type, Type);
        ReqWkshTemplate.SetRange(Recurring, false);
        ReqWkshTemplate.FindFirst();
    end;

    local procedure UpdateShipmentDateOnSalesLine(DocumentNo: Code[20]; ShipmentDate: Date)
    var
        SalesLine: Record "Sales Line";
    begin
        SelectSalesOrderLine(SalesLine, DocumentNo);
        SalesLine.Validate("Shipment Date", ShipmentDate);
        SalesLine.Modify(true);
    end;

    local procedure CalcRegenPlanForPlanWkshPage(ItemNo: Code[20]; ItemNo2: Code[20])
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        PlanningWorksheet: TestPage "Planning Worksheet";
    begin
        // Regenerative Planning using Page required where Forecast is used.
        CreateRequisitionWorksheetName(RequisitionWkshName);
        LibraryVariableStorage.Enqueue(ItemNo);  // Enqueue Item No to be used on page for filtering.
        LibraryVariableStorage.Enqueue(ItemNo2);  // Enqueue Item No to be used on page for filtering.
        Commit();  // Required for Test.
        PlanningWorksheet.OpenEdit();
        PlanningWorksheet.CurrentWkshBatchName.SetValue(RequisitionWkshName.Name);
        PlanningWorksheet.CalculateRegenerativePlan.Invoke();  // Open Regenerative Planning report. Handler - CalculatePlanPlanWkshRequestPageHandler.
        PlanningWorksheet.OK().Invoke();
    end;

    local procedure CalcRegenPlanForPlanWkshPageWithStartingDate(ItemNo: Code[20]; ItemNo2: Code[20]; StartingDate: Date)
    begin
        LibraryVariableStorage.Enqueue(StartingDate);  // Enqueue Item No to be used on page for filtering. Other Handler - CalculatePlanPlanWkshWithStartingDateRequestPageHandler
        CalcRegenPlanForPlanWkshPage(ItemNo, ItemNo2);
    end;

    local procedure SelectReferenceOrderType(ItemNo: Code[20]) RefOrderType: Enum "Requisition Ref. Order Type"
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        Item.Get(ItemNo);
        if Item."Replenishment System" = Item."Replenishment System"::Purchase then
            RefOrderType := RequisitionLine."Ref. Order Type"::Purchase
        else
            RefOrderType := RequisitionLine."Ref. Order Type"::"Prod. Order";
    end;

    local procedure SelectRequisitionLineForActionMessage(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20]; ActionMessage: Enum "Action Message Type")
    begin
        FilterOnRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.SetRange("Action Message", ActionMessage);
        RequisitionLine.FindFirst();
    end;

    local procedure UpdateItemSerialNoTracking(var Item: Record Item; ItemTrackingCode: Code[10])
    begin
        Item.Validate("Item Tracking Code", ItemTrackingCode);  // Assign Tracking Code.
        Item.Validate("Serial Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);
    end;

    local procedure UpdateItemLotNoTracking(var Item: Record Item; ItemTrackingCode: Code[10])
    begin
        Item.Validate("Item Tracking Code", ItemTrackingCode);  // Assign Tracking Code.
        Item.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);
    end;

    local procedure UpdateItemLotAccumulationPeriod(var Item: Record Item; LotAccumulationPeriod: DateFormula)
    begin
        Item.Validate("Lot Accumulation Period", LotAccumulationPeriod);
        Item.Modify(true);
    end;

    local procedure SelectTransferRoute(TransferFrom: Code[10]; TransferTo: Code[10])
    var
        TransferRoute: Record "Transfer Route";
    begin
        // If Transfer Not Found then Create it.
        if not TransferRoute.Get(TransferFrom, TransferTo) then
            LibraryWarehouse.CreateTransferRoute(TransferRoute, TransferFrom, TransferTo);
    end;

    local procedure CreateTransferOrderWithTransferRoute(var TransferLine: Record "Transfer Line"; ItemNo: Code[20]; TransferFrom: Code[10]; TransferTo: Code[10]; Quantity: Decimal)
    var
        TransferHeader: Record "Transfer Header";
    begin
        SelectTransferRoute(TransferFrom, TransferTo);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, TransferFrom, TransferTo, LocationInTransit.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
    end;

    local procedure UpdateSalesHeaderOrderDate(var SalesHeader: Record "Sales Header")
    var
        NewOrderDate: Date;
    begin
        NewOrderDate := GetRequiredDate(10, 10, WorkDate());
        SalesHeader.Validate("Order Date", NewOrderDate);
        SalesHeader.Modify(true);
    end;

    local procedure UpdateSalesHeaderShipmentDate(var SalesHeader: Record "Sales Header"; DeltaDays: Integer)
    begin
        SalesHeader.Validate("Shipment Date", SalesHeader."Shipment Date" + DeltaDays);
        SalesHeader.Modify(true);
    end;

    local procedure AssignTrackingOnSalesLine(var SalesLine: Record "Sales Line"; DocumentNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(true);  // Boolean - TRUE used inside AssignSerialTrackingAndCheckTrackingQtyPageHandler or AssignLotTrackingAndCheckTrackingQtyPageHandler.
        SelectSalesOrderLine(SalesLine, DocumentNo);
        SalesLine.OpenItemTrackingLines();  // Assign Tracking on Sales Line using page - Item Tracking Lines.
    end;

    local procedure UpdateLocationOnSalesLine(DocumentNo: Code[20]; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        SelectSalesOrderLine(SalesLine, DocumentNo);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure UpdateVariantOnSalesLine(DocumentNo: Code[20]; VariantCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        SelectSalesOrderLine(SalesLine, DocumentNo);
        SalesLine.Validate("Variant Code", VariantCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrderWithLocation(ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesOrder(SalesHeader, ItemNo, Quantity);
        UpdateLocationOnSalesLine(SalesHeader."No.", LocationCode);
    end;

    local procedure CreateSalesOrderWithLocationAndShipmentDate(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10]; ShipmentDate: Date)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Validate("Shipment Date", ShipmentDate);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));
    end;

    local procedure CreateSalesOrderWithLocationAndVariant(ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; VariantCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesOrder(SalesHeader, ItemNo, Quantity);
        UpdateLocationOnSalesLine(SalesHeader."No.", LocationCode);
        UpdateVariantOnSalesLine(SalesHeader."No.", VariantCode);
    end;

    local procedure CalcPlanForPlanAndReqWksh(Item: Record Item; CalcPlanPlanWksh: Boolean)
    begin
        if CalcPlanPlanWksh then
            CalcRegenPlanForPlanWksh(Item."No.")
        else
            CalculatePlanForRequisitionWorksheet(Item);
    end;

    local procedure UpdateItemLotTrackingAndSKU(var Item: Record Item; LocationCode: Code[10])
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
        ItemTrackingCodeLotSpecific: Record "Item Tracking Code";
    begin
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, LocationCode, Item."No.", '');
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCodeLotSpecific, false, true);  // SN Specific Tracking - FALSE.
        UpdateItemLotNoTracking(Item, ItemTrackingCodeLotSpecific.Code);
    end;

    local procedure CreateItemJournalWithLocation(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        CreateItemJournalLine(ItemJournalLine, ItemNo, ItemJournalLine."Entry Type"::Purchase);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateAndPostItemJournalWithLotTracking(ItemNo: Code[20]; LocationCode: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalWithLocation(ItemJournalLine, ItemNo, LocationCode);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No."); // Enqueue for Page Handler - LotItemTrackingPageHandler.
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndRefreshProductionOrderWithLocation(ItemNo: Code[20]; LocationCode: Code[10]; Status: Enum "Production Order Status")
    var
        ProductionOrder: Record "Production Order";
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, Status, ProductionOrder."Source Type"::Item, ItemNo, LibraryRandom.RandDec(10, 2));
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateBOMTree(var BOMBuffer: Record "BOM Buffer"; var Item: Record Item; EndDate: Date)
    var
        CalculateBOMTree: Codeunit "Calculate BOM Tree";
    begin
        Item.SetRange("Date Filter", 0D, EndDate);
        CalculateBOMTree.SetShowTotalAvailability(true);
        CalculateBOMTree.GenerateTreeForManyItems(Item, BOMBuffer, "BOM Tree Type"::Availability);
        BOMBuffer.Find();
    end;

    local procedure UpdateManufacturingSetupNormalStartingEndingTime(StartingTime: Time; EndingTime: Time)
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Normal Starting Time", StartingTime);
        ManufacturingSetup.Validate("Normal Ending Time", EndingTime);
        ManufacturingSetup.Modify(true);
    end;

    local procedure UpdateLocationMandatory(NewLocationMandatory: Boolean)
    var
        InvtSetup: Record "Inventory Setup";
    begin
        InvtSetup.Get();
        InvtSetup.Validate("Location Mandatory", NewLocationMandatory);
        InvtSetup.Modify(true);
    end;

    local procedure CreateSKUAndCalcRegenPlan(ItemNo: Code[20]; LocationCode: Code[10])
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, LocationCode, ItemNo, '');
        CalcRegenPlanForPlanWksh(ItemNo);
    end;

    local procedure AddInventory(ItemNo: Code[20]; AdjustmentQty: Decimal; LocationCode: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.",
          ItemNo, AdjustmentQty);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure FilterReservationEntry(var ReservationEntry: Record "Reservation Entry"; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Location Code", LocationCode);
    end;

    local procedure FilterReservationEntryWithSourceType(var ReservationEntry: Record "Reservation Entry"; ItemNo: Code[20]; LocationCode: Code[10]; SourceTypeFilter: Text)
    begin
        FilterReservationEntry(ReservationEntry, ItemNo, LocationCode);
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
        ReservationEntry.SetFilter("Source Type", SourceTypeFilter);
    end;

    local procedure UpdateDemandForecastVariantMatrixField(var DemandForecastCard: TestPage "Demand Forecast Card"; Item: Record Item; Qty: Integer)
    begin
        DemandForecastCard.Matrix.Filter.SetFilter("No.", Item."No.");
        DemandForecastCard.Matrix.First();
        DemandForecastCard.Matrix.Field1.SetValue(Qty);
    end;

    local procedure UpdateProductionBOMOnItem(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure UpdateSafetyLeadTimeOnItem(var Item: Record Item; SafetyLeadTimeText: Text)
    var
        SafetyLeadTime: DateFormula;
    begin
        Evaluate(SafetyLeadTime, SafetyLeadTimeText);
        Item.Validate("Safety Lead Time", SafetyLeadTime);
        Item.Modify(true);
    end;

    local procedure UpdateBaseCalendarOnCompanyInformation(NewBaseCalendarCode: Code[10]) OldBaseCalendarCode: Code[10]
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        OldBaseCalendarCode := CompanyInformation."Base Calendar Code";
        CompanyInformation.Validate("Base Calendar Code", NewBaseCalendarCode);
        CompanyInformation.Modify(true);
    end;

    local procedure UpdateStatusOnRoutingHeader(var RoutingHeader: Record "Routing Header"; Status: Enum "Routing Status")
    begin
        RoutingHeader.Validate(Status, Status);
        RoutingHeader.Modify(true);
    end;

    local procedure UpdateManufacturingPolicyOnItem(var Item: Record Item; ManufacturingPolicy: Enum "Manufacturing Policy")
    begin
        Item.Validate("Manufacturing Policy", ManufacturingPolicy);
        Item.Modify(true);
    end;

    local procedure VerifyReservationEntryPairInsideProductionOrder(Level1ItemNo: Code[20]; Level2ItemNo: Code[20]; LocationCode: Code[10])
    var
        Level1ReservationEntry: Record "Reservation Entry";
        Level2ReservationEntry: Record "Reservation Entry";
    begin
        FilterReservationEntryWithSourceType(
          Level1ReservationEntry, Level1ItemNo, LocationCode,
          StrSubstNo('%1|%2', DATABASE::"Prod. Order Line", DATABASE::"Prod. Order Component"));
        FilterReservationEntryWithSourceType(
          Level2ReservationEntry, Level2ItemNo, LocationCode,
          StrSubstNo('%1|%2', DATABASE::"Prod. Order Line", DATABASE::"Prod. Order Component"));

        Assert.RecordCount(Level1ReservationEntry, 2);
        Assert.RecordCount(Level2ReservationEntry, 2);
    end;

    local procedure CreateFourDatesArrayInsideMonthPeriod(var Dates: array[4] of Date)
    var
        D: Date;
        i: Integer;
    begin
        D := WorkDate();
        for i := 1 to ArrayLen(Dates) do begin
            D += LibraryRandom.RandIntInRange(3, 6);
            Dates[i] := D;
        end;
    end;

    local procedure CreateFourDatesArrayWithMoreThanMonthInterval(var Dates: array[4] of Date)
    var
        D: Date;
        i: Integer;
    begin
        D := WorkDate();
        for i := 1 to ArrayLen(Dates) do begin
            D := CalcDate('<1M>', D) + LibraryRandom.RandIntInRange(3, 6);
            Dates[i] := D;
        end;
    end;

    local procedure CreateFourDatesArrayInsideTwoMonthsPeriodAsTwoPairsInsideMonth(var Dates: array[4] of Date)
    var
        D: Date;
        i: Integer;
    begin
        D := WorkDate();
        for i := 1 to 2 do begin
            D += LibraryRandom.RandIntInRange(15, 30);
            Dates[i] := D;
        end;
        D := CalcDate('<1M>', Dates[2]) + LibraryRandom.RandIntInRange(3, 6);
        for i := 3 to 4 do begin
            D += LibraryRandom.RandIntInRange(15, 30);
            Dates[i] := D;
        end;
    end;

    local procedure CreateFourDatesArrayWhereSecondAndThirdAreInsideMonthAndFirstAndFourthOutside(var Dates: array[4] of Date)
    begin
        Dates[1] := WorkDate() + LibraryRandom.RandIntInRange(3, 6);
        Dates[2] := CalcDate('<1M>', Dates[1]) + LibraryRandom.RandIntInRange(3, 6);
        Dates[3] := Dates[2] + LibraryRandom.RandIntInRange(15, 30);
        Dates[4] := CalcDate('<1M>', Dates[3]) + LibraryRandom.RandIntInRange(3, 6);
    end;

    local procedure CreateReqLine(var ReqLine: Record "Requisition Line")
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        StockkeepingUnit: Record "Stockkeeping Unit";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RoutingHeader: Record "Routing Header";
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::"Req.");
        ReqWkshTemplate.SetRange(Recurring, false);
        ReqWkshTemplate.FindFirst();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        LibraryManufacturing.CreateItemManufacturing(
          Item, Item."Costing Method", LibraryRandom.RandDec(100, 2),
          Item."Reordering Policy"::"Fixed Reorder Qty.", Item."Flushing Method", '', '');
        Item.Validate("Reorder Quantity", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);

        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, LocationBlue.Code, Item."No.", ItemVariant.Code);

        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify();

        StockkeepingUnit.Validate("Routing No.", RoutingHeader."No.");
        StockkeepingUnit.Modify();

        LibraryPlanning.CalculatePlanForReqWksh(Item, ReqWkshTemplate.Name, RequisitionWkshName.Name, WorkDate(), WorkDate());

        ReqLine.SetRange(Type, ReqLine.Type::Item);
        ReqLine.SetRange("No.", Item."No.");
        ReqLine.FindFirst();

        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        ReqLine.Validate("Gen. Business Posting Group", GenBusinessPostingGroup.Code);
        ReqLine.Modify(true);
    end;

    local procedure VerifyEmptyRequisitionLine(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        FilterOnRequisitionLine(RequisitionLine, ItemNo);
        Assert.IsTrue(RequisitionLine.IsEmpty, StrSubstNo(RequisitionLineMustNotExistErr, ItemNo));
    end;

    local procedure VerifyRequisitionLineQty(ItemNo: Code[20]; Quantity: Decimal; RefOrderType: Enum "Requisition Ref. Order Type")
    var
        RequisitionLine: Record "Requisition Line";
    begin
        SelectRequisitionLine(RequisitionLine, ItemNo);
        VerifyRequisitionLine(RequisitionLine, Quantity, 0, RefOrderType);
    end;

    local procedure VerifyRequisitionLineWithDueDateAndQuantity(ItemNo: Code[20]; DueDate: Date; Quantity: Decimal)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.SetRange("Due Date", DueDate);
        Assert.RecordCount(RequisitionLine, 1);
        RequisitionLine.FindFirst();
        RequisitionLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyReqLine(ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; ActionMessage: Enum "Action Message Type")
    var
        RequisitionLine: Record "Requisition Line";
    begin
        SelectRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.TestField("Location Code", LocationCode);
        RequisitionLine.TestField(Quantity, Quantity);
        RequisitionLine.TestField("Action Message", ActionMessage);
    end;

    local procedure VerifyNewRequisitionLine(TempRequisitionLine: Record "Requisition Line" temporary; ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        SelectRequisitionLine(RequisitionLine, ItemNo);
        VerifyRequisitionLine(
          RequisitionLine, TempRequisitionLine.Quantity, TempRequisitionLine."Original Quantity", TempRequisitionLine."Ref. Order Type");
    end;

    local procedure VerifyRequisitionLine(RequisitionLine: Record "Requisition Line"; Quantity: Decimal; OriginalQuantity: Decimal; RefOrderType: Enum "Requisition Ref. Order Type")
    begin
        RequisitionLine.TestField(Quantity, Quantity);
        RequisitionLine.TestField("Original Quantity", OriginalQuantity);
        RequisitionLine.TestField("Ref. Order Type", RefOrderType);
    end;

    local procedure VerifyRequisitionLineWithDueDate(ItemNo: Code[20]; Quantity: Decimal; DueDate: Date)
    var
        RequisitionLine: Record "Requisition Line";
        RefOrderType: Enum "Requisition Ref. Order Type";
    begin
        FilterOnRequisitionLine(RequisitionLine, ItemNo);
        RefOrderType := SelectReferenceOrderType(ItemNo);
        RequisitionLine.SetRange("Due Date", DueDate);
        RequisitionLine.FindFirst();
        VerifyRequisitionLine(RequisitionLine, Quantity, 0, RefOrderType);  // Original Qty - Zero.
    end;

    local procedure VerifyRequisitionLineWithLocationActionAndRefOrderType(ItemNo: Code[20]; RefOrderType: Enum "Requisition Ref. Order Type"; LocationCode: Code[10]; ActionMessage: Enum "Action Message Type"; Quantity: Decimal; OriginalQuantity: Decimal; DueDate: Date)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        FilterOnRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.SetRange("Location Code", LocationCode);
        RequisitionLine.SetRange("Ref. Order Type", RefOrderType);
        RequisitionLine.SetRange("Action Message", ActionMessage);
        RequisitionLine.SetRange("Due Date", DueDate);
        RequisitionLine.FindFirst();
        VerifyRequisitionLine(RequisitionLine, Quantity, OriginalQuantity, RefOrderType);  // Original Qty - Zero.
    end;

    local procedure VerifyRequisitionLinesAgainstSalesLines(SalesHeader: Record "Sales Header"; ItemNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
    begin
        FindSalesLines(SalesLine, SalesHeader, ItemNo);

        FilterOnRequisitionLine(RequisitionLine, ItemNo);
        Assert.RecordCount(RequisitionLine, SalesLine.Count);

        repeat
            VerifyRequisitionLineWithDueDate(SalesLine."No.", SalesLine.Quantity, SalesLine."Shipment Date");
        until SalesLine.Next() = 0;
    end;

    local procedure VerifyRequisitionLineDates(ItemNo: Code[20]; RefOrderType: Enum "Requisition Ref. Order Type"; ActionMessage: Enum "Action Message Type"; ExpDueDate: Date; ExpStartDate: Date; ExpEndDate: Date)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        FilterOnRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.SetRange("Ref. Order Type", RefOrderType);
        RequisitionLine.SetRange("Action Message", ActionMessage);
        RequisitionLine.FindFirst();
        RequisitionLine.TestField("Due Date", ExpDueDate);
        RequisitionLine.TestField("Starting Date", ExpStartDate);
        RequisitionLine.TestField("Ending Date", ExpEndDate);
    end;

    local procedure VerifyRequisitionLineStartEndDateTime(ItemNo: Code[20]; RefOrderType: Enum "Requisition Ref. Order Type"; ActionMessage: Enum "Action Message Type"; ExpStartingDateTime: DateTime; ExpEndingDateTime: DateTime)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        FilterOnRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.SetRange("Ref. Order Type", RefOrderType);
        RequisitionLine.SetRange("Action Message", ActionMessage);
        RequisitionLine.FindFirst();
        RequisitionLine.TestField("Starting Date-Time", ExpStartingDateTime);
        RequisitionLine.TestField("Ending Date-Time", ExpEndingDateTime);
    end;

    local procedure VerifyPurchaseLineReceiptDates(DocType: Enum "Purchase Document Type"; VendorNo: Code[20]; ItemNo: Code[20]; PlannedReceiptDate: Date; ExpectedReceiptDate: Date)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", DocType);
        PurchaseLine.SetRange("Buy-from Vendor No.", VendorNo);
        PurchaseLine.SetRange(Type, "Purchase Line Type"::Item);
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.FindFirst();
        PurchaseLine.TestField("Planned Receipt Date", PlannedReceiptDate);
        PurchaseLine.TestField("Expected Receipt Date", ExpectedReceiptDate);
    end;

    local procedure VerifyItemTrackingLineQty(ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        TrackingQuantity: Variant;
    begin
        ItemTrackingLines.First();
        LibraryVariableStorage.Dequeue(TrackingQuantity);
        ItemTrackingLines."Quantity (Base)".AssertEquals(TrackingQuantity);
    end;

    local procedure VerifyTrackingOnRequisitionLine(ItemNo: Code[20]; Quantity: Decimal)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        LibraryVariableStorage.Enqueue(false);  // Boolean - FALSE used inside AssignSerialTrackingAndCheckTrackingQtyPageHandler or AssignLotTrackingAndCheckTrackingQtyPageHandler.
        LibraryVariableStorage.Enqueue(Quantity);  // Enqueue Quantity(Base) for Item Tracking Lines Page.
        SelectRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.OpenItemTrackingLines();
    end;

    local procedure VerifyLocationOnRequisitionLine(ItemNo: Code[20]; LocationCode: Code[10])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        FilterOnRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.FindFirst();
        RequisitionLine.TestField("Location Code", LocationCode);
    end;

    local procedure VerifyReservationEntry(var ReservationEntry: Record "Reservation Entry"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        FilterReservationEntry(ReservationEntry, ItemNo, LocationCode);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyEmptyReservationEntry(ItemNo: Code[20]; LocationCode: Code[10])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        FilterReservationEntry(ReservationEntry, ItemNo, LocationCode);
        Assert.IsTrue(ReservationEntry.IsEmpty, StrSubstNo(ReservationEntryMustNotExistErr, ItemNo));
    end;

    local procedure VerifyItemLedgerEntry(ItemNo: Code[20]; LocationCode: Code[10]; EntryType: Enum "Item Ledger Document Type"; Quantity: Decimal; InvoicedQuantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField("Location Code", LocationCode);
        ItemLedgerEntry.TestField("Entry Type", EntryType);
        ItemLedgerEntry.TestField(Quantity, Quantity);
        ItemLedgerEntry.TestField("Invoiced Quantity", InvoicedQuantity);
    end;

    local procedure VerifyGrossReqAndScheduledRecOnBOMTree(var BOMBuffer: Record "BOM Buffer"; ItemNo: Code[20]; ScheduledReceiptsQty: Decimal; GrossRequirementQty: Decimal)
    begin
        BOMBuffer.SetRange("No.", ItemNo);
        BOMBuffer.FindFirst();
        Assert.AreEqual(ScheduledReceiptsQty, BOMBuffer."Scheduled Receipts", '');
        Assert.AreEqual(GrossRequirementQty, BOMBuffer."Gross Requirement", '');
    end;

    local procedure AreSameMessages(Message: Text[1024]; Message2: Text[1024]): Boolean
    begin
        exit(StrPos(Message, Message2) > 0);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculatePlanPlanWkshRequestPageHandler(var CalculatePlanPlanWksh: TestRequestPage "Calculate Plan - Plan. Wksh.")
    var
        ItemNo: Variant;
        ItemNo2: Variant;
        EndDate: Date;
    begin
        // Calculate Regenerative Plan using page. Required where Forecast is used.
        LibraryVariableStorage.Dequeue(ItemNo);
        LibraryVariableStorage.Dequeue(ItemNo2);
        EndDate := GetRequiredDate(10, 30, WorkDate());  // End Date relative to Workdate.
        CalculatePlanPlanWksh.Item.SetFilter("No.", StrSubstNo(ItemFilterTxt, ItemNo, ItemNo2));
        CalculatePlanPlanWksh.StartingDate.SetValue(WorkDate());
        CalculatePlanPlanWksh.EndingDate.SetValue(EndDate);
        CalculatePlanPlanWksh.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculatePlanPlanWkshWithStartingDateRequestPageHandler(var CalculatePlanPlanWksh: TestRequestPage "Calculate Plan - Plan. Wksh.")
    var
        ItemNo: Variant;
        ItemNo2: Variant;
        StartingDate: Date;
    begin
        // Calculate Regenerative Plan using page. Required where Forecast is used.
        StartingDate := LibraryVariableStorage.DequeueDate();
        LibraryVariableStorage.Dequeue(ItemNo);
        LibraryVariableStorage.Dequeue(ItemNo2);
        CalculatePlanPlanWksh.Item.SetFilter("No.", StrSubstNo(ItemFilterTxt, ItemNo, ItemNo2));
        CalculatePlanPlanWksh.StartingDate.SetValue(StartingDate);
        CalculatePlanPlanWksh.EndingDate.SetValue(CalcDate('<CM>', StartingDate));
        CalculatePlanPlanWksh.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PlanningErrorLogPageHandler(var PlanningErrorLog: TestPage "Planning Error Log")
    begin
        PlanningErrorLog.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        QueuedMsg: Variant;
    begin
        LibraryVariableStorage.Dequeue(QueuedMsg);
        Assert.IsTrue(AreSameMessages(Message, QueuedMsg), Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerWithoutValidate(Message: Text[1024])
    begin
        // This Handler function is used for handling Messages.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AssignLotTrackingAndCheckTrackingQtyPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        AssignTracking: Variant;
        AssignTracking2: Boolean;
    begin
        LibraryVariableStorage.Dequeue(AssignTracking);
        AssignTracking2 := AssignTracking;  // Required for variant to boolean.
        if AssignTracking2 then begin
            ItemTrackingLines."Assign Lot No.".Invoke();  // Assign Lot No.
            LibraryVariableStorage.Enqueue(AvailabilityWarningConfirmationMsg);  // Required inside ConfirmHandler.
            ItemTrackingLines.OK().Invoke();
        end else
            VerifyItemTrackingLineQty(ItemTrackingLines);  // Verify Quantity(Base) on Tracking Line.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AssignSerialTrackingAndCheckTrackingQtyPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        AssignTracking: Variant;
        AssignTracking2: Boolean;
    begin
        LibraryVariableStorage.Dequeue(AssignTracking);
        AssignTracking2 := AssignTracking;  // Required for variant to boolean.
        if AssignTracking2 then begin
            ItemTrackingLines."Assign Serial No.".Invoke();  // Assign Lot No.
            LibraryVariableStorage.Enqueue(AvailabilityWarningConfirmationMsg);  // Required inside ConfirmHandler.
            ItemTrackingLines.OK().Invoke();  // Calls up Enter Quantity to Create page handled by handler - QuantityToCreatePageHandler.
        end else
            VerifyItemTrackingLineQty(ItemTrackingLines);  // Verify Quantity(Base) on Tracking Line.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure QuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK().Invoke();  // Assign Serial Tracking on Enter Quantity to Create page.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure LotItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        DequeueVariable: Variant;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        ItemTrackingMode := DequeueVariable;
        case ItemTrackingMode of
            ItemTrackingMode::"Assign Lot No.":
                ItemTrackingLines."Assign Lot No.".Invoke();
            ItemTrackingMode::"Select Entries":
                ItemTrackingLines."Select Entries".Invoke();
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTRUE(ConfirmMessage: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.IsTrue(AreSameMessages(ConfirmMessage, ExpectedMessage), ConfirmMessage);
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculatePlanReqPageHandler(var CalculatePlanPlanWksh: TestRequestPage "Calculate Plan - Plan. Wksh.")
    begin
        CalculatePlanPlanWksh.MPS.SetValue(true);
        CalculatePlanPlanWksh.MRP.SetValue(false);
        CalculatePlanPlanWksh.StartingDate.SetValue(CalcDate('<-CY>', WorkDate()));
        CalculatePlanPlanWksh.EndingDate.SetValue(CalcDate('<CY>', WorkDate()));

        CalculatePlanPlanWksh.OK().Invoke();
    end;
}

