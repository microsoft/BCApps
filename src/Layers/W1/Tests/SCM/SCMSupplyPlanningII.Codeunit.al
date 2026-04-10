codeunit 137071 "SCM Supply Planning -II"
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
        ConsumptionItemJournalTemplate: Record "Item Journal Template";
        ConsumptionItemJournalBatch: Record "Item Journal Batch";
        OutputItemJournalTemplate: Record "Item Journal Template";
        OutputItemJournalBatch: Record "Item Journal Batch";
        LocationYellow: Record Location;
        LocationRed: Record Location;
        LocationSilver: Record Location;
        LocationBlue: Record Location;
        LocationSilver2: Record Location;
        LocationGreen: Record Location;
        LocationInTransit: Record Location;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryCosting: Codeunit "Library - Costing";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        isInitialized: Boolean;
        RequisitionLineMustNotExist: Label 'Requisition Line must not exist for Item %1.';
        ItemFilter: Label '%1|%2', Locked = true;
        AvailabilityWarningConfirmationMessage: Label 'You do not have enough inventory to meet the demand for items in one or more lines.';
        ItemNotPlanned: Label 'Not all items were planned. A total of 1 items were not planned.';
        NothingToCreateMessage: Label 'There is nothing to create.';
        CannotChangeQuantityError: Label 'You cannot change Quantity because the order line is associated with sales order ';
        ProductionOrderMustNotExist: Label 'Production Order Must No Exist for Item %1.';
        ReservationEntryExistMsg: Label 'One or more reservation entries exist for the item with';
        ShipFieldErr: Label 'The Ship field on Sales Header is not correct.';
        ReceiveFieldErr: Label 'The Receive field on Purchase Header is not correct.';
        SalesOrderStatusErr: Label 'The Status of the Sales Order is not correct.';
        PurchaseOrderStatusErr: Label 'The Status of the Purchase Order is not correct.';
        RequisitionLineNoErr: Label 'There should be no extra empty line generated before the generated line with Item.';
        InventoryPickCreatedMsg: Label 'Number of Invt. Pick activities created';
        BinCodeInWarehouseEntryErr: Label 'Bin Code in Warehouse Entry is not correct.';
        QuantityInWarehouseEntryErr: Label 'Quantity in Warehouse Entry is not correct.';
        ReservationEntryErr: Label 'Reservation Entry with Item Ledger Entry is not empty.';
        NumberOfErrorsErr: Label 'Wrong number of errors.';
        ReservationEntrySurplusErr: Label 'Reservation Entry Surplus Quantity must be %1, actual value is %2.', Comment = '%1: Expected Quantity Value; %2: Actual Quantity Value.';
        PlanningComponentReseredQtyErr: Label 'In "Planning Component" table the fields "%1" is wrong.', Comment = '%1: Field Name';
        ItemTrackingOption: Option AssignLotNo,AssignSerialNo,AssignManualLotNo,AssignManualSN,VerifyTrackingQty;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanWithMPSPartialSalesShipUsingForecastOnSameDateLFLItem()
    var
        Item: Record Item;
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemJournalLine: Record "Item Journal Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        PlanningWorksheet: TestPage "Planning Worksheet";
        OldCombinedMPSMRPCalculation: Boolean;
    begin
        // Setup: Create Lot for Lot Item. Create Production Forecast with multiple Entries.
        Initialize();
        OldCombinedMPSMRPCalculation := UpdateManufacturingSetup(false);  // Combined MPS/MRP Calculation -FALSE.
        CreateLotForLotItem(Item);
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", WorkDate(), false);  // Boolean - FALSE, for single Forecast Entry.

        // Update Item inventory.
        UpdateInventory(ItemJournalLine, Item."No.", WorkDate(), ProductionForecastEntry[1]."Forecast Quantity" + LibraryRandom.RandDec(10, 2));  // Large Random Quantity Required.

        // Create Sales Order. Update Quantity To Ship on Sales Line. Post Sales Order.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", ItemJournalLine.Quantity + LibraryRandom.RandDec(10, 2));
        UpdateQuantityToShipOnSalesLine(SalesLine, ItemJournalLine.Quantity);  // Quantity to Ship equal to Item Inventory Quantity.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // Exercise: Calculate regenerative Plan with MPS - TRUE and MRP - FALSE for Planning Worksheet.
        CreateRequisitionWorksheetName(RequisitionWkshName);
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item."No.");

        // Verify: Verify Planning Worksheet for Quantities and Reference Order Type.
        VerifyRequisitionLineWithDueDate(
          Item, RequisitionLine."Action Message"::New, SalesLine.Quantity - SalesLine."Qty. to Ship", 0, SalesLine."Shipment Date");

        // Teardown.
        UpdateManufacturingSetup(OldCombinedMPSMRPCalculation);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanWithMPSSalesShipUsingForecastForParentLFLItemOnly()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        RequisitionLine2: Record "Requisition Line";
        InventorySetup: Record "Inventory Setup";
        PlanningWorksheet: TestPage "Planning Worksheet";
        OldCombinedMPSMRPCalculation: Boolean;
        ForecastDate: Date;
        NewShipmentDate: Date;
    begin
        // Setup: Create Lot for Lot Parent and Child Item. Create And Certify Production BOM.
        Initialize();
        OldCombinedMPSMRPCalculation := UpdateManufacturingSetup(false);  // Combined MPS/MRP Calculation of - FALSE.
        CreateLotForLotItem(ChildItem);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem."No.");
        CreateLotForLotItem(Item);
        UpdateProductionBOMNoOnItem(Item, ProductionBOMHeader."No.");

        ForecastDate := GetRequiredDate(10, 0, WorkDate(), 1);  // Forecast Date Relative to Workdate.
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", ForecastDate, true);  // Boolean - TRUE, for multiple Forecast Entries.

        // Create and Post Sales Order for Parent Item.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandDec(10, 2));  // Random Quantity not important.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // Exercise: Calculate regenerative Plan with MPS - TRUE and MRP - FALSE for Planning Worksheet.
        CreateRequisitionWorksheetName(RequisitionWkshName);
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item."No.");

        // Verify: Verify Planning Worksheet for Quantities and Reference Order Type for Parent Item.
        InventorySetup.Get();
        NewShipmentDate := CalcDate('<-' + Format(InventorySetup."Default Safety Lead Time"), SalesLine."Shipment Date");
        VerifyRequisitionLineWithDueDate(Item, RequisitionLine."Action Message"::New, SalesLine.Quantity, 0, NewShipmentDate);
        VerifyRequisitionLineWithDueDate(
          Item, RequisitionLine."Action Message"::New, ProductionForecastEntry[1]."Forecast Quantity (Base)", 0,
          ProductionForecastEntry[1]."Forecast Date");
        VerifyRequisitionLineWithDueDate(
          Item, RequisitionLine."Action Message"::New, ProductionForecastEntry[2]."Forecast Quantity (Base)", 0,
          ProductionForecastEntry[2]."Forecast Date");
        VerifyRequisitionLineWithDueDate(
          Item, RequisitionLine."Action Message"::New, ProductionForecastEntry[3]."Forecast Quantity (Base)", 0,
          ProductionForecastEntry[3]."Forecast Date");

        // Verify that no Requisition line is created for Child Item.
        FilterOnRequisitionLine(RequisitionLine2, ChildItem."No.");
        Assert.IsTrue(RequisitionLine2.IsEmpty, StrSubstNo(RequisitionLineMustNotExist, ChildItem."No."));

        // Teardown.
        UpdateManufacturingSetup(OldCombinedMPSMRPCalculation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanForSalesAndMultiPurchaseWithLocationAndVariant()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemVariant2: Record "Item Variant";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        Quantity: Decimal;
    begin
        // Setup: Create Lot for Lot Item with Stockkeeping Units.
        Initialize();
        CreateLotForLotItemSKUSetup(Item, ItemVariant, ItemVariant2, LocationYellow.Code, LocationRed.Code);
        Quantity := LibraryRandom.RandDec(5, 2);  // Random Quantity not important

        // Create Sales Order. Update Location and Variant Code on Sales Line.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", Quantity);
        UpdateLocationAndVariantOnSalesLine(SalesLine, LocationYellow.Code, ItemVariant.Code);

        // Create multiple Purchase Orders with different Locations and Variant.
        CreatePurchaseOrderWithLocationAndVariant(PurchaseHeader, Item."No.", LocationYellow.Code, ItemVariant.Code, Quantity);
        CreatePurchaseOrderWithLocationAndVariant(PurchaseHeader2, Item."No.", LocationRed.Code, ItemVariant2.Code, Quantity);

        // Exercise: Calculate Plan for Planning Worksheet with Location Yellow and Red Filter.
        CalcRegenPlanForPlanWkshWithLocation(Item."No.", Item."No.", LocationYellow.Code, LocationRed.Code);

        // Verify: Verify Planning Worksheet for Location, Variant, Action Message and Quantity.
        SelectPurchaseLine(PurchaseLine, Item."No.");
        VerifyRequisitionLineForLocationAndVariant(
          Item, RequisitionLine."Action Message"::New, SalesLine.Quantity, 0, SalesLine."Shipment Date", LocationYellow.Code,
          ItemVariant.Code);
        VerifyRequisitionLineForLocationAndVariant(
          Item, RequisitionLine."Action Message"::Cancel, 0, Quantity, PurchaseLine."Expected Receipt Date", LocationYellow.Code,
          ItemVariant.Code);
        VerifyRequisitionLineWithVariant(RequisitionLine."Action Message"::Cancel, 0, Quantity, LocationRed.Code, ItemVariant2.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanForSalesWithLocationAndVariant()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
    begin
        // Setup: Create Lot for Lot Item with Stockkeeping Units with single Location and Variant.
        Initialize();
        CreateLotForLotItemSKUSetup(Item, ItemVariant, ItemVariant, LocationYellow.Code, '');

        // Create Sales Order, update Location and Variant Code on Sales Line.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandDec(5, 2));  // Random Quantity not important.
        UpdateLocationAndVariantOnSalesLine(SalesLine, LocationYellow.Code, ItemVariant.Code);

        // Exercise: Calculate Plan for Planning Worksheet with Location Filter.
        CalcRegenPlanForPlanWkshWithLocation(Item."No.", Item."No.", LocationYellow.Code, '');

        // Verify: Verify Planning Worksheet for Location, Variant, Action Message and Quantity.
        VerifyRequisitionLineForLocationAndVariant(
          Item, RequisitionLine."Action Message"::New, SalesLine.Quantity, 0, SalesLine."Shipment Date", LocationYellow.Code,
          ItemVariant.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanForNewVariantOnProductionOrderComponent()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ItemVariant: Record "Item Variant";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
    begin
        // Setup: Create Lot for Lot Item with Stockkeeping Units with single Location and Variant. Create And Certify Production BOM.
        Initialize();
        CreateLotForLotItemSKUSetup(ChildItem, ItemVariant, ItemVariant, LocationYellow.Code, '');
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem."No.");
        CreateLotForLotItem(Item);
        UpdateProductionBOMNoOnItem(Item, ProductionBOMHeader."No.");

        // Create and Refresh Firm Planned Production Order and update Variant Code on Production Order Component.
        CreateAndRefreshFirmPlannedProductionOrderWithLocation(
          ProductionOrder, Item."No.", LocationYellow.Code, LibraryRandom.RandInt(10));  // Random Quantity not important.
        UpdateVariantCodeOnProdOrderComponent(ChildItem."No.", ItemVariant.Code);

        // Exercise: Calculate Plan for Production Order Component for Planning Worksheet with Location Filter.
        CalcRegenPlanForPlanWkshWithLocation(ChildItem."No.", ChildItem."No.", LocationYellow.Code, '');

        // Verify: Verify Planning Worksheet for Location, Variant, Action Message and Quantity.
        VerifyRequisitionLineForLocationAndVariant(
          ChildItem, RequisitionLine."Action Message"::New, ProductionOrder.Quantity, 0, ProductionOrder."Starting Date",
          LocationYellow.Code, ItemVariant.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanForSalesAndPurchaseWithoutVariantForDifferentLocations()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        Quantity: Decimal;
    begin
        // Setup: Create Lot for Lot Item with Stockkeeping Units.
        Initialize();
        CreateLotForLotItemSKUSetup(Item, ItemVariant, ItemVariant, LocationYellow.Code, LocationRed.Code);
        Quantity := LibraryRandom.RandDec(10, 2);  // Random Quantity not important.

        // Create Sales Order. Update Location Code on Sales Line. Variant Code is not updated.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", Quantity);
        UpdateLocationAndVariantOnSalesLine(SalesLine, LocationYellow.Code, '');

        // Create Purchase Order. Update Location Code on Purchase Line. Variant Code is not updated.
        CreatePurchaseOrderWithLocationAndVariant(PurchaseHeader, Item."No.", LocationRed.Code, '', Quantity);

        // Exercise: Calculate Plan for Planning Worksheet with Location Yellow and Red Filter.
        CalcRegenPlanForPlanWkshWithLocation(Item."No.", Item."No.", LocationYellow.Code, LocationRed.Code);

        // Verify: Verify Planning Worksheet for Location, Variant, Action Message and Quantity.
        SelectPurchaseLine(PurchaseLine, Item."No.");
        VerifyRequisitionLineForLocationAndVariant(
          Item, RequisitionLine."Action Message"::New, SalesLine.Quantity, 0, SalesLine."Shipment Date", LocationYellow.Code, '');
        VerifyRequisitionLineForLocationAndVariant(
          Item, RequisitionLine."Action Message"::Cancel, 0, PurchaseLine.Quantity, PurchaseLine."Expected Receipt Date", LocationRed.Code,
          '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanForSalesWithLocationAndNewVariantOnPlanningComponent()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ItemVariant: Record "Item Variant";
        ProductionBOMHeader: Record "Production BOM Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        PlanningComponent: Record "Planning Component";
    begin
        // Setup: Create Lot for Lot Item with Stockkeeping Units with single Location and Variant.
        Initialize();
        CreateLotForLotItemSKUSetup(ChildItem, ItemVariant, ItemVariant, LocationYellow.Code, '');
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem."No.");
        CreateLotForLotItem(Item);
        UpdateReplenishmentSystemOnItem(Item);
        UpdateProductionBOMNoOnItem(Item, ProductionBOMHeader."No.");

        // Create Sales Order. Update Location Code on Sales Line. Variant Code is not updated.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandInt(10));  // Random Quantity not important.
        UpdateLocationAndVariantOnSalesLine(SalesLine, LocationYellow.Code, '');

        // Calculate Plan for Planning Worksheet with Location Yellow Filter. Update Variant Code On Planning Component.
        CalcRegenPlanForPlanWkshWithLocation(Item."No.", Item."No.", LocationYellow.Code, '');
        SelectRequisitionLine(RequisitionLine, Item."No.");
        SelectPlanningComponent(PlanningComponent, RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name");
        UpdateVariantCodeOnPlanningComponent(PlanningComponent, ItemVariant.Code);

        // Exercise: Calculate Plan for Parent and Child Item for Planning Worksheet with single Location.
        CalcRegenPlanForPlanWkshWithLocation(Item."No.", ChildItem."No.", LocationYellow.Code, '');

        // Verify: Verify Planning Worksheet for Location, Action Message and Quantity. Variant is not updated for Planning Component on Planning Worksheet.
        VerifyRequisitionLineForLocationAndVariant(
          Item, RequisitionLine."Action Message"::New, SalesLine.Quantity, 0, SalesLine."Shipment Date", LocationYellow.Code, '');
        VerifyRequisitionLineForLocationAndVariant(
          ChildItem, RequisitionLine."Action Message"::New, SalesLine.Quantity, 0, PlanningComponent."Due Date", LocationYellow.Code, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanWithNegativeInventoryWithLocationAndVariant()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        RequisitionLine: Record "Requisition Line";
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
    begin
        // Setup: Create Lot for Lot Item with Stockkeeping Units with single Location and Variant.
        Initialize();
        CreateLotForLotItemSKUSetup(Item, ItemVariant, ItemVariant, LocationYellow.Code, '');

        // Update Inventory with Negative Adjustment.
        Quantity := LibraryRandom.RandDec(10, 2);  // Random Quantity not important
        UpdateInventoryWithLocationAndVariant(
          ItemJournalLine, Item."No.", Quantity, ItemJournalLine."Entry Type"::"Negative Adjmt.", LocationYellow.Code, ItemVariant.Code);

        // Exercise: Calculate Plan for Planning Worksheet with Location Yellow.
        CalcRegenPlanForPlanWkshWithLocation(Item."No.", Item."No.", LocationYellow.Code, '');

        // Verify: Verify Planning Worksheet for Location, Variant, Action Message and Quantity.
        VerifyRequisitionLineWithItem(
          Item, RequisitionLine."Action Message"::New, ItemJournalLine.Quantity, 0, LocationYellow.Code, ItemVariant.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcNetChangePlanWithSalesForLFLItems()
    var
        Item: Record Item;
        ChildItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        // Setup: Create Lot for Lot Parent and Child Item. Create and Certify Production BOM.
        Initialize();
        CreateLotForLotItemSetup(ChildItem, Item);

        // Create Sales Order for Parent Item.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandDec(10, 2));  // Random Quantity not important.

        // Exercise: Calculate Net Change Plan for Parent Item and Child Item.
        CalcNetChangePlanForPlanWkshForMultipleItems(Item."No.", ChildItem."No.");

        // Verify: Verify Planning Worksheet for Action Message, Quantity and Reference Order Type on Planning Worksheet.
        SelectProductionBOMLine(ProductionBOMLine, Item."Production BOM No.");
        VerifyRequisitionLineWithItem(Item, RequisitionLine."Action Message"::New, SalesLine.Quantity, 0, '', '');
        VerifyRequisitionLineWithItem(ChildItem, RequisitionLine."Action Message"::New, Round(SalesLine.Quantity, ChildItem."Rounding Precision", '>'), 0, '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcNetChangePlanWithSalesAndNewUOMForLFLChildItem()
    var
        Item: Record Item;
        ChildItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        PlanningComponent: Record "Planning Component";
    begin
        // Setup: Create Lot for Lot Parent and Child Item. Create and Certify Production BOM.
        Initialize();
        CreateLotForLotItemSetup(ChildItem, Item);

        // Create Sales Order with Parent Item.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandDec(10, 2));  // Random Quantity not important.

        // Calculate Plan for Planning Worksheet with Parent and Child Item.
        CalcRegenPlanForPlanWkshWithLocation(Item."No.", ChildItem."No.", '', '');

        // Update Quantity on Sales Line. Change Base Unit Of Measure on Child Item.
        UpdateQuantityOnSalesLine(SalesLine, SalesLine.Quantity + LibraryRandom.RandDec(10, 2));  // Quantity more than previous Quantity on Sales Line.
        CreateAndUpdateUnitOfMeasureOnItem(ChildItem);

        // Exercise: Calculate Net Change Plan for Parent Item and Child Item.
        CalcNetChangePlanForPlanWkshForMultipleItems(Item."No.", ChildItem."No.");

        // Verify: Verify Planning Worksheet for Action Message, Quantity and Reference Order Type on Planning Worksheet. Verify Unit of Measure is updated on Planning Worksheet for child Item.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        SelectPlanningComponent(PlanningComponent, RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name");
        VerifyRequisitionLineForUnitOfMeasure(
          Item, Item."Base Unit of Measure", RequisitionLine."Action Message"::New, SalesLine.Quantity, 0, SalesLine."Shipment Date");
        VerifyRequisitionLineForUnitOfMeasure(
          ChildItem, ChildItem."Base Unit of Measure", RequisitionLine."Action Message"::New, PlanningComponent."Expected Quantity", 0,
          PlanningComponent."Due Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcNetChangePlanWithSalesForNewLocationOnPlanningComponent()
    var
        Item: Record Item;
        ChildItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        PlanningComponent: Record "Planning Component";
    begin
        // Setup: Create Lot for Lot Parent and Child Item. Create and Certify Production BOM.
        Initialize();
        CreateLotForLotItemSetup(ChildItem, Item);

        // Create Sales Order for Parent Item.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandDec(10, 2));  // Random Quantity not important.

        // Calculate Plan for Planning Worksheet with Parent and Child Item.
        CalcRegenPlanForPlanWkshWithLocation(Item."No.", ChildItem."No.", '', '');

        // Update Location Code on Planning Component.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        UpdateLocationOnPlanningComponent(PlanningComponent, RequisitionLine, LocationYellow.Code);

        // Exercise: Calculate Net Change Plan for Parent Item and Child Item.
        CalcNetChangePlanForPlanWkshForMultipleItems(Item."No.", ChildItem."No.");

        // Verify: Verify Location is updated for Child Item on Requisition Line. Verify Action Message, Quantity and Reference Order Type on Planning Worksheet.
        VerifyRequisitionLineWithDueDate(Item, RequisitionLine."Action Message"::New, SalesLine.Quantity, 0, SalesLine."Shipment Date");
        VerifyRequisitionLineForLocationAndVariant(
          ChildItem, RequisitionLine."Action Message"::New, PlanningComponent."Expected Quantity", 0, PlanningComponent."Due Date",
          LocationYellow.Code, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcNetChangePlanWithoutAnyDemandLFLItem()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        EndDate: Date;
    begin
        // Setup: Create Lot for Lot Item.
        Initialize();
        CreateLotForLotItem(Item);

        // Exercise: Calculate Net Change Plan for Planning Worksheet without any demand.
        EndDate := GetRequiredDate(5, 10, WorkDate(), 1);
        LibraryPlanning.CalcNetChangePlanForPlanWksh(Item, WorkDate(), EndDate, false);

        // Verify: Verify that no Requisition line is created for Requisition Worksheet, when no demand exist.
        FilterOnRequisitionLine(RequisitionLine, Item."No.");
        Assert.IsTrue(RequisitionLine.IsEmpty, StrSubstNo(RequisitionLineMustNotExist, Item."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcNetChangePlanForFirmPlannedProdOrderForLFLParentItem()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProductionOrder2: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        // Setup: Create Lot for Lot Parent and Child Item. Create And Certify Production BOM.
        Initialize();
        CreateLotForLotItemSetup(ChildItem, Item);
        UpdateReplenishmentSystemOnItem(ChildItem);  // Update Replenishment System to Production Order on Child Item.

        // Create and Refresh Firm Planned Production Order.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ChildItem."No.", ProductionOrder.Status::"Firm Planned", LibraryRandom.RandDec(10, 2));  // Random Quantity not important for Test.

        // Calculate Plan for Planning Worksheet with Parent and Child Item.
        CalcRegenPlanForPlanWkshWithLocation(Item."No.", ChildItem."No.", '', '');

        // Create and Refresh Firm Planned Production Order for Parent Item.
        CreateAndRefreshProductionOrder(
          ProductionOrder2, Item."No.", ProductionOrder2.Status::"Firm Planned", LibraryRandom.RandDec(10, 2));  // Random Quantity not important for Test.

        // Exercise: Calculate Net Change Plan for Parent Item and Child Item.
        CalcNetChangePlanForPlanWkshForMultipleItems(Item."No.", ChildItem."No.");

        // Verify: Verify Item is updated on Requisition Line. Verify Action Message, Quantity and Reference Order Type on Planning Worksheet.
        SelectProductionBOMLine(ProductionBOMLine, Item."Production BOM No.");
        VerifyRequisitionLineWithItem(ChildItem, RequisitionLine."Action Message"::Cancel, 0, ProductionOrder.Quantity, '', '');
        VerifyRequisitionLineWithItem(Item, RequisitionLine."Action Message"::Cancel, 0, ProductionOrder2.Quantity, '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcNetChangePlanWithNewQuantityOnFirmPlannedProdOrder()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        ProductionOrder: Record "Production Order";
        EndDate: Date;
    begin
        // Setup: Create Lot for Lot Item. Create and Refresh Firm Planned Production Order.
        Initialize();
        CreateLotForLotItem(Item);
        UpdateReplenishmentSystemOnItem(Item);
        CreateAndRefreshProductionOrder(
          ProductionOrder, Item."No.", ProductionOrder.Status::"Firm Planned", LibraryRandom.RandDec(10, 2));  // Random Quantity not important for Test.

        // Calculate Regenerative Plan for Planning Worksheet.
        EndDate := GetRequiredDate(10, 30, WorkDate(), 1);  // End Date relative to Workdate.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), EndDate);

        // Update Quantity and Refresh Firm Planned Production Order.
        UpdateQuantityAndRefreshProductionOrder(
          ProductionOrder, Item."No.", ProductionOrder.Quantity + LibraryRandom.RandDec(10, 2));  // Quantity more than previous Quantity on Production Order.

        // Exercise: Calculate Net Change Plan for Planning Worksheet.
        LibraryPlanning.CalcNetChangePlanForPlanWksh(Item, WorkDate(), EndDate, false);

        // Verify: Verify Original Quantity is modified on Planning Worksheet.
        VerifyRequisitionLineWithDueDate(
          Item, RequisitionLine."Action Message"::Cancel, 0, ProductionOrder.Quantity, ProductionOrder."Due Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcNetChangePlanWithConsumptionJournalForLFLItem()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        ItemJournalLine: Record "Item Journal Line";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // Setup: Create Lot for Lot Parent and Child Item. Create And Certify Production BOM.
        Initialize();
        CreateLotForLotItemSetup(ChildItem, Item);
        UpdateReplenishmentSystemOnItem(ChildItem);

        // Create and Refresh Released Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, Item."No.", ProductionOrder.Status::Released, LibraryRandom.RandDec(10, 2));  // Random Quantity not important.

        // Calculate Regenerative Change Plan for Planning Worksheet for Parent Item and Child Item..
        CalcRegenPlanForPlanWkshWithLocation(Item."No.", ChildItem."No.", '', '');

        // Create and Post Consumption Journal. Make sure inventory has ChildItem more than the required for production
        UpdateInventory(ItemJournalLine, ChildItem."No.", WorkDate(), ProductionOrder.Quantity + LibraryRandom.RandInt(10));  // Larger Inventory Value required for Test.
        CreateAndPostConsumptionJournal(ProductionOrder."No.");

        // Create Sales Order For Child Item.
        CreateSalesOrder(SalesHeader, SalesLine, ChildItem."No.", ItemJournalLine.Quantity + LibraryRandom.RandDec(10, 2));  // Quantity more than Production Order Quantity.

        // Exercise: Calculate Net Change Plan for Planning Worksheet for Parent and Child Item.
        CalcNetChangePlanForPlanWkshForMultipleItems(Item."No.", ChildItem."No.");

        // Verify: Verify Planning Worksheet for Action Message, Quantity and Reference Order Type on Planning Worksheet.
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder.Status::Released, ProductionOrder."No.", ChildItem."No.");
        VerifyRequisitionLineWithItem(Item, RequisitionLine."Action Message"::Cancel, 0, ProductionOrder.Quantity, '', '');
        VerifyRequisitionLineWithItem(
          ChildItem, RequisitionLine."Action Message"::New,
          SalesLine.Quantity - (ItemJournalLine.Quantity - ProdOrderComponent."Expected Quantity"), 0, '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcNetChangePlanWithOutputJournalForLFLItem()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
    begin
        // Setup: Create Lot for Lot Parent and Child Item. Create And Certify Production BOM.
        Initialize();
        CreateLotForLotItemSetup(ChildItem, Item);
        UpdateReplenishmentSystemOnItem(ChildItem);

        // Create and Refresh Released Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, Item."No.", ProductionOrder.Status::Released, LibraryRandom.RandDec(10, 2));  // Random Quantity not important.

        // Calculate Regenerative Change Plan for Planning Worksheet for Parent Item and Child Item..
        CalcRegenPlanForPlanWkshWithLocation(Item."No.", ChildItem."No.", '', '');

        // Create and Post Output Journal.
        CreateAndPostOutputJournal(ProductionOrder."No.");

        // Create Sales Order For Child Item.
        CreateSalesOrder(SalesHeader, SalesLine, ChildItem."No.", ProductionOrder.Quantity + LibraryRandom.RandDec(10, 2));  // Quantity more than Production Order Quantity.

        // Exercise: Calculate Net Change Plan for Planning Worksheet for Parent and Child Item.
        CalcNetChangePlanForPlanWkshForMultipleItems(Item."No.", ChildItem."No.");

        // Verify: Verify Planning Worksheet for Action Message, Quantity and Reference Order Type on Planning Worksheet.
        VerifyRequisitionLineWithItem(Item, RequisitionLine."Action Message"::Cancel, 0, ProductionOrder.Quantity, '', '');
        VerifyRequisitionLineWithItem(ChildItem, RequisitionLine."Action Message"::New, SalesLine.Quantity, 0, '', '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PlanningErrorLogPageHandler')]
    [Scope('OnPrem')]
    procedure CalcRegenPlanWithRoutingStatusNewLFLItem()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup: Create Lot for Lot Item.
        Initialize();
        CreateLotForLotItem(Item);
        UpdateReplenishmentSystemOnItem(Item);

        // Create Routing With Status New and create Sales Order.
        CreateRoutingAndUpdateItem(Item);
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandDec(10, 2));  // Random Quantity not important.

        // Calculate Regenerative Plan for Planning Worksheet.
        LibraryVariableStorage.Enqueue(ItemNotPlanned);  // Required inside MessageHandler.
        CalculateRegenPlanForPlanningWorksheet(Item);

        // Verify: Verify that no Requisition line is created for Requisition Worksheet, Since Routing is not Certified.
        FilterOnRequisitionLine(RequisitionLine, Item."No.");
        Assert.IsTrue(RequisitionLine.IsEmpty, StrSubstNo(RequisitionLineMustNotExist, Item."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanWithSalesAndProdOrderWithAdjustCostItemEntriesLFLItem()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ProductionOrder: Record "Production Order";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProdOrderComponent: Record "Prod. Order Component";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Calculate Regenerative Plan] [Lot-for-Lot] [Production] [Sales]
        // [SCENARIO] Verify Quantities for Parent and Child Items are correct after Calculate Regeneration Plan: Production Order which expects child Qty greater than is on stock, plus Sales Order for parent Item.

        // [GIVEN] Lot for Lot parent and child Items (Costing Method is Average).
        Initialize();
        CreateLotForLotItemSetup(ChildItem, Item);
        UpdateCostingMethodToAverageOnItem(ChildItem);
        UpdateCostingMethodToAverageOnItem(Item);

        // [GIVEN] Child Item stock Qty X.
        UpdateInventory(ItemJournalLine, ChildItem."No.", WorkDate(), LibraryRandom.RandDec(10, 2));  // Inventory Value required for Test.

        // [GIVEN] Released Production for Parent Item of Qty (X + P).
        CreateAndRefreshProductionOrder(
          ProductionOrder, Item."No.", ProductionOrder.Status::Released, ItemJournalLine.Quantity + LibraryRandom.RandDec(10, 2));

        // Run Adjust Cost Item Entries report.
        LibraryCosting.AdjustCostItemEntries(StrSubstNo(ItemFilter, Item."No.", ChildItem."No."), '');

        // [GIVEN] Sales Order for Parent Item of Qty S.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", ProductionOrder.Quantity + LibraryRandom.RandDec(10, 2));

        // [WHEN] Run Calculate Plan for Planning Worksheet with Parent and Child Item.
        CalcRegenPlanForPlanWkshWithLocation(Item."No.", ChildItem."No.", '', '');

        // [THEN] Planning Worksheet for Parent: Action Message: Change Qty, from Qty S to Qty (X + P).
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder.Status::Released, ProductionOrder."No.", ChildItem."No.");
        VerifyRequisitionLineWithItem(
          Item, RequisitionLine."Action Message"::"Change Qty.", SalesLine.Quantity, ProductionOrder.Quantity, '', '');
        // [THEN] Planning Worksheet for Child: Action Message: New, Qty = (Child expected Qty from Production Order) - X.
        VerifyRequisitionLineWithItem(
            ChildItem, RequisitionLine."Action Message"::New, Round(SalesLine.Quantity, ChildItem."Rounding Precision", '>') - ItemJournalLine.Quantity, 0, '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanAndCarryOutWithSalesAndProdOrderWithAdjustCostItemEntriesLFLItem()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ProductionOrder: Record "Production Order";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProdOrderComponent: Record "Prod. Order Component";
        RequisitionLine: Record "Requisition Line";
        RequisitionLine2: Record "Requisition Line";
    begin
        // [FEATURE] [Carry Out Action Message] [Lot-for-Lot] [Production] [Sales]
        // [SCENARIO] Verify Quantities for Parent and Child Items are correct after Calculate Regeneration Plan and Carry Out with no Accepted lines: Production Order which expects child Qty greater than is on stock, plus Sales Order for parent Item.

        // [GIVEN] Lot for Lot parent and child Items (Costing Method is Average).
        Initialize();
        CreateLotForLotItemSetup(ChildItem, Item);
        UpdateCostingMethodToAverageOnItem(ChildItem);
        UpdateCostingMethodToAverageOnItem(Item);

        // [GIVEN] Child Item stock Qty = X.
        UpdateInventory(ItemJournalLine, ChildItem."No.", WorkDate(), LibraryRandom.RandDec(10, 2));  // Inventory Value required for Test.

        // [GIVEN] Released Production for Parent Item of Qty X + P.
        CreateAndRefreshProductionOrder(
          ProductionOrder, Item."No.", ProductionOrder.Status::Released, ItemJournalLine.Quantity + LibraryRandom.RandDec(10, 2));  // Quantity more than Inventory Quantity.

        // [GIVEN] Sales Order for Parent Item of Qty S.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", ProductionOrder.Quantity + LibraryRandom.RandDec(10, 2));

        // [GIVEN] Calculate Plan for Planning Worksheet with Parent and Child Item.
        CalcRegenPlanForPlanWkshWithLocation(Item."No.", ChildItem."No.", '', '');

        // Run Adjust Cost Item Entries report.
        LibraryCosting.AdjustCostItemEntries(StrSubstNo(ItemFilter, Item."No.", ChildItem."No."), '');

        // [WHEN] Carry Out Action Message for Planning Worksheet, Accept Action is FALSE (?), so Requisition Lines remain.
        CarryoutActionMessageForPlanWorksheet(RequisitionLine, Item."No.");
        CarryoutActionMessageForPlanWorksheet(RequisitionLine2, ChildItem."No.");

        // [THEN] Planning Worksheet for Parent: Action Message: Change Qty, from Qty S to Qty (X + P).
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder.Status::Released, ProductionOrder."No.", ChildItem."No.");
        VerifyRequisitionLineWithItem(
          Item, RequisitionLine."Action Message"::"Change Qty.", SalesLine.Quantity, ProductionOrder.Quantity, '', '');
        // [THEN] Planning Worksheet for Child: Action Message: New, Qty = (Child expected Qty from Production Order) - X.
        VerifyRequisitionLineWithItem(
          ChildItem, RequisitionLine."Action Message"::New, Round(SalesLine.Quantity, ChildItem."Rounding Precision", '>') - ItemJournalLine.Quantity, 0, '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcNetChangePlanWithMutipleSalesAndProdOrderLFLItem()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ProductionOrder: Record "Production Order";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeader2: Record "Sales Header";
        SalesLine2: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ShipmentDate: Date;
        Qty: Decimal;
    begin
        // Setup: Create Lot for Lot Item setup. Update Costing Method to Average on Parent and Child Item.
        Initialize();
        CreateLotForLotItemSetup(ChildItem, Item);
        UpdateCostingMethodToAverageOnItem(ChildItem);
        UpdateCostingMethodToAverageOnItem(Item);
        Qty := LibraryRandom.RandDecInDecimalRange(5, 10, 2);  // Random Quantity not important.

        // Update Inventory for Child Item.
        UpdateInventory(ItemJournalLine, ChildItem."No.", WorkDate(), Qty);  // Inventory Value required for Test.

        // Create and Refresh Released Production for Parent Item.
        CreateAndRefreshProductionOrder(ProductionOrder, Item."No.", ProductionOrder.Status::Released, Qty);

        // Create multiple Sales Order for Parent Item and Child Item.
        CreateSalesOrder(SalesHeader, SalesLine, ChildItem."No.", Qty);
        ShipmentDate := GetRequiredDate(10, 0, WorkDate(), 1);  // Shipment Date relative to Work Date.
        CreateSalesOrder(SalesHeader2, SalesLine2, Item."No.", SalesLine.Quantity + LibraryRandom.RandDec(10, 2));  // Quantity more than quantity of first Sales Order.
        UpdateShipmentDateOnSalesLine(SalesLine, ShipmentDate);

        // Calculate Plan for Planning Worksheet with Parent and Child Item.
        CalcRegenPlanForPlanWkshWithLocation(Item."No.", ChildItem."No.", '', '');

        // Delete Sales Order for Child item. Update Quantity on Sales Order for Parent item.
        SalesHeader.Delete(true);
        Qty := LibraryRandom.RandDec(5, 2);
        UpdateQuantityOnSalesLine(SalesLine2, Qty);  // Quantity less than previous quantity.

        // Exercise: Calculate Net Change Plan for Parent Item and Child Item.
        CalcNetChangePlanForPlanWkshForMultipleItems(Item."No.", ChildItem."No.");

        // Verify: Verify Planning Worksheet for Action Message, Quantity and Reference Order Type on Planning Worksheet.
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder.Status::Released, ProductionOrder."No.", ChildItem."No.");
        VerifyRequisitionLineWithItem(
          Item, RequisitionLine."Action Message"::"Change Qty.", SalesLine2.Quantity, ProductionOrder.Quantity, '', '');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DeleteRequisitionLineForItemHavingComponentWithLotTracking()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        RequisitionLine: Record "Requisition Line";
        ProductionOrder: Record "Production Order";
        Quantity: Decimal;
        EndDate: Date;
    begin
        // Setup: Create Lot for Lot Item setup. Update Lot specific Tracking and Lot Nos on Child Item.
        Initialize();
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        CreateLotForLotItemSetup(ChildItem, Item);
        UpdateTrackingAndLotNosOnItem(ChildItem, ItemTrackingCode.Code);

        // Update Inventory With Lot specific Tracking.
        Quantity := LibraryRandom.RandDec(10, 2);  // Random Quantity not important for test.
        UpdateInventoryWithTracking(ChildItem."No.", Quantity);

        // Create and Refresh Released Production Order. Open Tracking On Production Order Component.
        CreateAndRefreshProductionOrder(ProductionOrder, Item."No.", ProductionOrder.Status::Released, Quantity);
        LibraryVariableStorage.Enqueue(AvailabilityWarningConfirmationMessage);  // Required inside ConfirmHandler.
        OpenTrackingOnProductionOrderComponent(ProductionOrder, ChildItem."No.");

        // Calculate Plan for Planning Worksheet.
        EndDate := GetRequiredDate(10, 30, WorkDate(), 1);  // End Date relative to Workdate.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), EndDate);

        // Exercise: Delete the Requisition Line created on Planning Worksheet.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        RequisitionLine.Delete(true);

        // Verify: Verify the Requisition Line having tracking on its component is deleted successfully.
        FilterOnRequisitionLine(RequisitionLine, Item."No.");
        Assert.IsTrue(RequisitionLine.IsEmpty, StrSubstNo(RequisitionLineMustNotExist, Item."No."));
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanWithMPSWithMultiSalesLineOrderItemUsingForecast()
    var
        Item: Record Item;
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        PlanningWorksheet: TestPage "Planning Worksheet";
        OldCombinedMPSMRPCalculation: Boolean;
        ForecastDate: Date;
        ShipmentDate: Date;
    begin
        // Setup: Create Order Item. Create Production Forecast.
        Initialize();
        OldCombinedMPSMRPCalculation := UpdateManufacturingSetup(false);  // Combined MPS/MRP Calculation -FALSE.
        CreateOrderItem(Item);
        ForecastDate := GetRequiredDate(10, 0, WorkDate(), 1);  // Forecast Date Relative to Workdate.
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", ForecastDate, false);  // Boolean - FALSE, for single Forecast Entry.

        // Create Sales Order with multiple lines.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandDec(10, 2));
        ShipmentDate := GetRequiredDate(20, 20, WorkDate(), 1);  // Shipment Date relative to Work Date.
        LibrarySales.CreateSalesLineWithShipmentDate(
          SalesLine2, SalesHeader, SalesLine2.Type::Item, Item."No.", ShipmentDate, SalesLine.Quantity + LibraryRandom.RandDec(5, 2));  // Quantity more than Quantity on first Sales Line.

        // Exercise: Calculate Regenerative Plan with MPS - TRUE and MRP - FALSE for Planning Worksheet.
        CreateRequisitionWorksheetName(RequisitionWkshName);
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item."No.");

        // Verify: Verify Planning Worksheet for Quantities and Reference Order Type.
        VerifyRequisitionLineWithDueDate(Item, RequisitionLine."Action Message"::New, SalesLine.Quantity, 0, SalesLine."Shipment Date");
        VerifyRequisitionLineWithDueDate(Item, RequisitionLine."Action Message"::New, SalesLine2.Quantity, 0, SalesLine2."Shipment Date");
        VerifyRequisitionLineWithDueDate(
          Item, RequisitionLine."Action Message"::New, ProductionForecastEntry[1]."Forecast Quantity" - SalesLine2.Quantity, 0,
          ProductionForecastEntry[1]."Forecast Date");

        // Teardown.
        UpdateManufacturingSetup(OldCombinedMPSMRPCalculation);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanWithMPSWithSalesLineOrderItemWithNewSalesUOMUsingForecast()
    var
        Item: Record Item;
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        PlanningWorksheet: TestPage "Planning Worksheet";
        OldCombinedMPSMRPCalculation: Boolean;
        ForecastDate: Date;
    begin
        // Setup: Create Order Item. Update Item parameters. Create Production Forecast
        Initialize();
        OldCombinedMPSMRPCalculation := UpdateManufacturingSetup(false);  // Combined MPS/MRP Calculation -FALSE.
        CreateOrderItem(Item);
        UpdateUnitOfMeasuresOnItem(Item);  // Update Sales and Purchase Unit Of Measure and Include Inventory - FALSE on Item.
        ForecastDate := GetRequiredDate(10, 0, WorkDate(), 1);  // Forecast Date Relative to Workdate.
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", ForecastDate, false);  // Boolean - FALSE, for single Forecast Entry.

        // Create Sales Order.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandDec(10, 2));  // Random Quantity not important for Test.

        // Exercise: Calculate Regenerative Plan with MPS - TRUE and MRP - FALSE for Planning Worksheet.
        CreateRequisitionWorksheetName(RequisitionWkshName);
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item."No.");

        // Verify: Verify Planning Worksheet for Quantities and Reference Order Type. Verify Item Sales Unit Of Measure is updated on Requisition Line.
        VerifyRequisitionLineForUnitOfMeasure(
          Item, Item."Sales Unit of Measure", RequisitionLine."Action Message"::New, SalesLine.Quantity, 0, SalesLine."Shipment Date");
        VerifyRequisitionLineForUnitOfMeasure(
          Item, Item."Sales Unit of Measure", RequisitionLine."Action Message"::New, ProductionForecastEntry[1]."Forecast Quantity", 0,
          ProductionForecastEntry[1]."Forecast Date");

        // Teardown.
        UpdateManufacturingSetup(OldCombinedMPSMRPCalculation);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanWithTransferOrderAndForecastWithReschedulingPeriodLFLItem()
    var
        ChildItem: Record Item;
        Item: Record Item;
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        StockkeepingUnit: Record "Stockkeeping Unit";
        ProductionBOMHeader: Record "Production BOM Header";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        StockkeepingUnit2: Record "Stockkeeping Unit";
        ItemJournalLine: Record "Item Journal Line";
        Bin: Record Bin;
        RequisitionLine: Record "Requisition Line";
        PlanningWorksheet: TestPage "Planning Worksheet";
        ForecastDate: Date;
    begin
        // Setup: Create Lot for Lot Child Item. Create Lot for Lot Item and Stockkeeping Unit setup.
        Initialize();
        CreateLotForLotItem(ChildItem);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem."No.");
        CreateLotForLotItemSKUSetupWithTransfer(Item, StockkeepingUnit, StockkeepingUnit2, LocationSilver.Code, LocationBlue.Code);
        UpdateProductionBOMNoOnItem(Item, ProductionBOMHeader."No.");

        // Update Rescheduling Period and Dampener Period with random values. Lot Accumulation Period - 0D on Stockkeeping Units of Parent Item.
        UpdateLotForLotSKUPlanningParameters(StockkeepingUnit, GetRequiredPeriod(2, 5), GetRequiredPeriod(0, 3), '<0D>');
        UpdateLotForLotSKUPlanningParameters(StockkeepingUnit2, GetRequiredPeriod(2, 5), GetRequiredPeriod(0, 3), '<0D>');

        // Update Item inventory with Bin. Make sure item in inventory is < forecasted
        LibraryWarehouse.FindBin(Bin, LocationSilver.Code, '', 1);  // Find Bin of Index 1.
        UpdateInventoryWithLocationAndBin(
          ItemJournalLine, Item."No.", LocationSilver.Code, Bin.Code, 100 - LibraryRandom.RandDec(10, 2));  // Large Random Quantity Required.

        // Create Production Forecast.
        ForecastDate := LibraryRandom.RandDateFromInRange(WorkDate(), 6, 10); // Forecaset date is more than the transfer order date
        CreateProductionForecastSetupWithLocation(ProductionForecastEntry, Item."No.", LocationBlue.Code, ForecastDate, false);  // Boolean - FALSE, for single Forecast Entry.

        // Create Transfer Order where receipt date is between workdate and the forecast date.
        CreateTransferOrderWithReceiptDate(
          TransferHeader, Item."No.", LocationSilver.Code, LocationBlue.Code, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDateFromInRange(WorkDate(), 1, 5));

        // Exercise: Calculate Plan for Planning Worksheet.
        CreateRequisitionWorksheetName(RequisitionWkshName);
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item."No.");

        // Verify: Verify Planning Worksheet with Location, Action Message, Quantities and Reference Order Type.
        SelectTransferLine(TransferLine, TransferHeader."No.");
        VerifyRequisitionLineWithDueDate(
         Item, RequisitionLine."Action Message"::New, ProductionForecastEntry[1]."Forecast Quantity", 0,
         ProductionForecastEntry[1]."Forecast Date");
        VerifyRequisitionLineWithDueDateForTransfer(
          RequisitionLine."Action Message"::Cancel, 0, TransferLine.Quantity, TransferLine."Receipt Date", LocationBlue.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanWithTransferAndProdOrderWithReschedulingPeriodPlanningFlexibilityNoneLFLItem()
    begin
        PlanningWithTransferPlanningFlexibilityAndProdOrderWithReschedulingPeriodSKULFLItem(true);  // Planning Flexibility - None for Transfer Line.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanWithTransferAndProdOrderWithReschedulingPeriodLFLItem()
    begin
        PlanningWithTransferPlanningFlexibilityAndProdOrderWithReschedulingPeriodSKULFLItem(false);  // Planning Flexibility - Unlimited for Transfer Line.
    end;

    local procedure PlanningWithTransferPlanningFlexibilityAndProdOrderWithReschedulingPeriodSKULFLItem(PlanningFlexibilityNone: Boolean)
    var
        ChildItem: Record Item;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        StockkeepingUnit: Record "Stockkeeping Unit";
        ProductionBOMHeader: Record "Production BOM Header";
        StockkeepingUnit2: Record "Stockkeeping Unit";
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
        StartDate: Date;
        EndDate: Date;
    begin
        // Setup: Create Lot for Lot Child Item. Create Lot for Lot Item and Stockkeeping Unit setup.
        Initialize();
        CreateLotForLotItem(ChildItem);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem."No.");
        CreateLotForLotItemSKUSetupWithTransfer(Item, StockkeepingUnit, StockkeepingUnit2, LocationSilver.Code, LocationBlue.Code);
        UpdateReplenishmentSystemOnItem(Item);
        UpdateProductionBOMNoOnItem(Item, ProductionBOMHeader."No.");

        // Update Rescheduling Period and Dampener Period with random values. Lot Accumulation Period - 0D on Stockkeeping Units of Parent Item.
        UpdateLotForLotSKUPlanningParameters(StockkeepingUnit, GetRequiredPeriod(2, 5), GetRequiredPeriod(2, 0), '<0D>');
        UpdateLotForLotSKUPlanningParameters(StockkeepingUnit2, GetRequiredPeriod(2, 5), GetRequiredPeriod(2, 0), '<0D>');
        UpdateSKUReplenishmentSystem(StockkeepingUnit, StockkeepingUnit."Replenishment System"::"Prod. Order");  // Replenishment System Production Order.

        // Create and Refresh Released Production Order. Create Transfer Order.
        CreateAndRefreshFirmPlannedProductionOrderWithLocation(
          ProductionOrder, Item."No.", LocationSilver.Code, LibraryRandom.RandInt(10) + 10);  // Random Quantity not important.
        CreateTransferOrderWithReceiptDate(
          TransferHeader, Item."No.", LocationSilver.Code, LocationBlue.Code, LibraryRandom.RandDec(ProductionOrder.Quantity, 2));
        SelectTransferLine(TransferLine, TransferHeader."No.");
        if PlanningFlexibilityNone then
            UpdateTransferLinePlanningFlexibilityNone(TransferLine);  // Update Planning Flexibilty on Transfer Line - None.

        // Exercise: Calculate Plan for Planning Worksheet.
        StartDate := GetRequiredDate(20, 0, ProductionOrder."Due Date", -1);  // Start Date Relative to Receipt Date of Transfer Order.
        EndDate := GetRequiredDate(30, 0, TransferLine."Receipt Date", 1);  // End Date Relative to Receipt Date of Transfer Order.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, StartDate, EndDate);

        // Verify: Verify Planning Worksheet with Location, Action Message, Quantities and Reference Order Type.
        if PlanningFlexibilityNone then begin
            VerifyRequisitionLineWithDueDate(
              Item, RequisitionLine."Action Message"::Cancel, 0, ProductionOrder.Quantity, ProductionOrder."Due Date");
            VerifyRequisitionLineWithDueDate(
              Item, RequisitionLine."Action Message"::New, TransferLine.Quantity, 0, TransferLine."Receipt Date");
        end else begin
            VerifyRequisitionLineWithDueDate(
              Item, RequisitionLine."Action Message"::Cancel, 0, ProductionOrder.Quantity, ProductionOrder."Due Date");
            VerifyRequisitionLineWithDueDateForTransfer(
              RequisitionLine."Action Message"::Cancel, 0, TransferLine.Quantity, TransferLine."Receipt Date", LocationBlue.Code);
        end;
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanWithTransferAndForecastWithLotAccumulationPeriodLFLItem()
    var
        ChildItem: Record Item;
        Item: Record Item;
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        StockkeepingUnit: Record "Stockkeeping Unit";
        ProductionBOMHeader: Record "Production BOM Header";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        StockkeepingUnit2: Record "Stockkeeping Unit";
        ItemJournalLine: Record "Item Journal Line";
        Bin: Record Bin;
        RequisitionLine: Record "Requisition Line";
        PlanningWorksheet: TestPage "Planning Worksheet";
        ForecastDate: Date;
    begin
        // Setup: Create Lot for Lot Child Item. Create Lot for Lot Item and Stockkeeping Unit setup.
        Initialize();
        CreateLotForLotItem(ChildItem);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem."No.");
        CreateLotForLotItemSKUSetupWithTransfer(Item, StockkeepingUnit, StockkeepingUnit2, LocationSilver.Code, LocationBlue.Code);
        UpdateReplenishmentSystemOnItem(Item);
        UpdateProductionBOMNoOnItem(Item, ProductionBOMHeader."No.");

        // Update Rescheduling Period - 0D, Dampener Period - 0D. Lot Accumulation Period with random value on Stockkeeping Units of Parent Item.
        UpdateLotForLotSKUPlanningParameters(StockkeepingUnit, '<0D>', GetRequiredPeriod(2, 5), '<0D>');
        UpdateLotForLotSKUPlanningParameters(StockkeepingUnit2, '<0D>', GetRequiredPeriod(2, 5), '<0D>');

        // Update Item inventory with Location and Bin.
        LibraryWarehouse.FindBin(Bin, LocationSilver.Code, '', 1);  // Find Bin of Index 1.
        UpdateInventoryWithLocationAndBin(
         ItemJournalLine, Item."No.", LocationSilver.Code, Bin.Code, LibraryRandom.RandDec(10, 2) + 100);  // Large Random Quantity Required.

        // Create Production Forecast with multiple Entries.
        ForecastDate := GetRequiredDate(10, 0, WorkDate(), 1);  // Forecast Date Relative to Workdate.
        CreateProductionForecastSetupWithLocation(ProductionForecastEntry, Item."No.", LocationBlue.Code, ForecastDate, true);  // Boolean - TRUE, for multiple Forecast Entry.

        // Exercise: Calculate Plan for Planning Worksheet.
        CreateRequisitionWorksheetName(RequisitionWkshName);
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item."No.");

        // Verify: Verify Planning Worksheet with Action Message, Quantities and Reference Order Type.
        VerifyRequisitionLineWithDueDate(
          Item, RequisitionLine."Action Message"::New, ProductionForecastEntry[1]."Forecast Quantity", 0,
          ProductionForecastEntry[1]."Forecast Date");
        VerifyRequisitionLineWithDueDate(
          Item, RequisitionLine."Action Message"::New, ProductionForecastEntry[2]."Forecast Quantity", 0,
          ProductionForecastEntry[2]."Forecast Date");
        VerifyRequisitionLineWithDueDate(
          Item, RequisitionLine."Action Message"::New, ProductionForecastEntry[3]."Forecast Quantity", 0,
          ProductionForecastEntry[3]."Forecast Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanWithTransferOrderWithLotAccumulationPeriodPlanningFlexibiltyNoneLFLItem()
    begin
        PlanningWithTransferWithLotAccumulationPeriodSKULFLItem(true);  // Planning Flexibility - None for Transfer Lines.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanWithTransferOrderWithLotAccumulationPeriodLFLItem()
    begin
        PlanningWithTransferWithLotAccumulationPeriodSKULFLItem(false);  // Planning Flexibility - Unlimited for Transfer Lines.
    end;

    local procedure PlanningWithTransferWithLotAccumulationPeriodSKULFLItem(PlanningFlexibilityNone: Boolean)
    var
        ChildItem: Record Item;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        StockkeepingUnit: Record "Stockkeeping Unit";
        ProductionBOMHeader: Record "Production BOM Header";
        StockkeepingUnit2: Record "Stockkeeping Unit";
        ItemJournalLine: Record "Item Journal Line";
        Bin: Record Bin;
        RequisitionLine: Record "Requisition Line";
        StartDate: Date;
        EndDate: Date;
    begin
        // Setup: Create Lot for Lot Child Item. Create Lot for Lot Item and Stockkeeping Unit setup.
        Initialize();
        CreateLotForLotItem(ChildItem);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem."No.");
        CreateLotForLotItemSKUSetupWithTransfer(Item, StockkeepingUnit, StockkeepingUnit2, LocationSilver.Code, LocationBlue.Code);
        UpdateReplenishmentSystemOnItem(Item);
        UpdateProductionBOMNoOnItem(Item, ProductionBOMHeader."No.");

        // Update Rescheduling Period - 0D, Dampener Period - 0D. Lot Accumulation Period with random values on Stockkeeping Units of Parent Item.
        UpdateLotForLotSKUPlanningParameters(StockkeepingUnit, '<0D>', '<0D>', GetRequiredPeriod(2, 5));
        UpdateLotForLotSKUPlanningParameters(StockkeepingUnit2, '<0D>', '<0D>', GetRequiredPeriod(2, 5));
        UpdateSKUReplenishmentSystem(StockkeepingUnit, StockkeepingUnit."Replenishment System"::"Prod. Order");

        // Update Item inventory with Location and Bin.
        LibraryWarehouse.FindBin(Bin, LocationSilver.Code, '', 1);  // Find Bin of Index 1.
        UpdateInventoryWithLocationAndBin(
          ItemJournalLine, Item."No.", LocationSilver.Code, Bin.Code, LibraryRandom.RandDec(10, 2) + 100);  // Large Random Quantity Required.

        // Create Tansfer Order. Update Planning Flexibility - None On Transfer Line.
        CreateTransferOrderWithReceiptDate(
          TransferHeader, Item."No.", LocationBlue.Code, LocationSilver.Code, LibraryRandom.RandDec(10, 2));
        SelectTransferLine(TransferLine, TransferHeader."No.");
        if PlanningFlexibilityNone then
            UpdateTransferLinePlanningFlexibilityNone(TransferLine);

        // Exercise: Calculate Plan for Planning Worksheet.
        StartDate := GetRequiredDate(20, 0, TransferLine."Receipt Date", -1);  // Start Date relative to Receipt Date of Transfer Order.
        EndDate := GetRequiredDate(30, 0, TransferLine."Receipt Date", 1);  // End Date relative to Receipt Date of Transfer Order.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, StartDate, EndDate);

        // Verify: Verify Planning Worksheet with Location, Action Message, Quantities and Reference Order Type.
        if PlanningFlexibilityNone then
            VerifyRequisitionLineForLocationAndVariant(
              Item, RequisitionLine."Action Message"::New, TransferLine.Quantity, 0, TransferLine."Receipt Date", LocationBlue.Code, '')
        else
            VerifyRequisitionLineWithDueDateForTransfer(
              RequisitionLine."Action Message"::Cancel, 0, TransferLine.Quantity, TransferLine."Receipt Date", LocationSilver.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanWithReqWkshWithSalesQuantityGreaterThanMaxInventoryOnLocationMQItem()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemVariant: Record "Item Variant";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        StartDate: Date;
        EndDate: Date;
    begin
        // Setup: Create Maximum Quantity Item. Create Stockkeeping Unit.
        Initialize();
        CreateStockkeepingUnitForMaximumQtyItem(Item, ItemVariant, LocationBlue.Code);

        // Update Inventory With Location.
        UpdateInventoryWithLocationAndBin(ItemJournalLine, Item."No.", LocationBlue.Code, '', Item."Maximum Inventory");

        // Create Sales Order for Quantity more than Maximum Inventory.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", Item."Maximum Inventory" + LibraryRandom.RandDec(10, 2));
        UpdateLocationAndVariantOnSalesLine(SalesLine, LocationBlue.Code, '');

        // Update Quantity to Ship with Quantity equal to Maximum Inventory on Sales Order Line. Post Sales Order with Ship.
        UpdateQuantityToShipOnSalesLine(SalesLine, Item."Maximum Inventory");
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // Exercise: Calculate Plan for Requisition Worksheet.
        StartDate := GetRequiredDate(10, 0, ItemJournalLine."Posting Date", 1);  // Start Date greater than Posting Date of Item Journal.
        EndDate := GetRequiredDate(10, 0, StartDate, 1);  // End Date relative to Start Date.
        CalculatePlanForRequisitionWorksheet(RequisitionWkshName, Item."No.", '', StartDate, EndDate);

        // Verify: Verify Planning Worksheet with Location, Variant, Action Message, Quantities and Reference Order Type.
        VerifyRequisitionLineWithVariant(
          RequisitionLine."Action Message"::New, Item."Maximum Inventory", 0, LocationBlue.Code, ItemVariant.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyErrorOnPurchaseLineAfterCalcPlanForSalesOrderWithDropShipment()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
    begin
        // Setup: Create Order Item. Create Sales Order with Purchasing Code, Drop Shipment for Sales Line on Requisition Worksheet. Post Sales Order.
        Initialize();
        CreateOrderItem(Item);
        CreateSalesOrderWithPurchasingCode(SalesHeader, SalesLine, Item."No.", LocationSilver.Code, LibraryRandom.RandDec(10, 2));
        GetSalesOrderOnRequisitionWkshtAndCarryOutActionMsg(SalesLine, RequisitionLine);  // Drop Shipment On Requisition Line.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SelectPurchaseLine(PurchaseLine, Item."No.");
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No."); // Get the Purchase Header.
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);

        // Exercise: Update Quantity on Purchase Order Line which is linked with previously created Sales Order.
        asserterror UpdateQuantityOnPurchaseLine(Item."No.");

        // Verify: Verify error - Quantity cannot be changed because the order line is associated with Sales Order.
        Assert.ExpectedError(CannotChangeQuantityError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseBinOnBinContentForSalesAfterCalcPlanOfSalesWithDropShipment()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Bin: Record Bin;
    begin
        // Setup: Create Order Item. Create Sales Order with Purchasing Code, Drop Shipment for Sales Line on Requisition Worksheet.
        Initialize();
        CreateOrderItem(Item);
        CreateSalesOrderWithPurchasingCode(SalesHeader, SalesLine, Item."No.", LocationSilver.Code, LibraryRandom.RandDec(10, 2));
        GetSalesOrderOnRequisitionWkshtAndCarryOutActionMsg(SalesLine, RequisitionLine);  // Drop Shipment On Requisition Line. Carry out to generate a new Purchase Order.

        // Create second new Purchase Order with Location and Bin.
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.", LibraryRandom.RandDec(10, 2));
        LibraryWarehouse.FindBin(Bin, LocationSilver.Code, '', 1);  // Find Bin of Index 1.
        UpdateBinOnPurchaseLine(PurchaseLine, LocationSilver.Code, Bin.Code);

        // Exercise: Post Purchase Order.
        PostPurchaseDocument(PurchaseHeader);

        // Verify: Verify Bin Code of second Purchase Order is updated on Bin Content for Sales Order.
        VerifyBinContent(SalesLine, PurchaseLine."Bin Code");
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('MessageHandler')]
    procedure NothingToCreateMsgWhenInvtPutPickMovementAfterCalcPlanReqWkshWithCarryOutOrderItem()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeader2: Record "Sales Header";
        SalesLine2: Record "Sales Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        StartDate: Date;
        EndDate: Date;
    begin
        // Setup: Create Order Item. Update Inventory with Location.
        Initialize();
        CreateOrderItem(Item);
        UpdateInventoryWithLocationAndBin(ItemJournalLine, Item."No.", LocationSilver2.Code, '', LibraryRandom.RandDec(10, 2) + 100);  // Large Random Quantity Required.

        // Create Sales Order with random quantity.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandDec(10, 2));

        // Calculate Plan for Requisition Worksheet and Carry out Action Message.
        StartDate := WorkDate();
        EndDate := GetRequiredDate(30, 0, StartDate, 1);
        CalcPlanAndCarryOutActionMessage(Item, StartDate, EndDate);

        // Create new Sales Order with same Item for random Quantity.
        CreateSalesOrder(SalesHeader2, SalesLine2, Item."No.", LibraryRandom.RandDec(10, 2));

        // Exercise & Verify: Run Create Inventory Put-away Pick Movement report. Verifying message - Nothing to create in Message Handler, when trying to create Put or Pick movement for Sales Order.
        LibraryVariableStorage.Enqueue(NothingToCreateMessage);  // Required inside MessageHandler.
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Sales Order", SalesHeader2."No.", true, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanForItemCategoryCodeOnRequisitionLineForFRQItem()
    var
        Item: Record Item;
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        EndDate: Date;
    begin
        // Setup: Create FRQ Item with Item Category Code.
        Initialize();
        CreateFRQItem(Item);
        UpdateItemCategoryCode(Item);

        // Exercise: Calculate Plan for Requisition Worksheet.
        EndDate := GetRequiredDate(10, 0, WorkDate(), 1);  // End Date relative to WORKDATE.
        CalculatePlanForRequisitionWorksheet(RequisitionWkshName, Item."No.", '', WorkDate(), EndDate);

        // Verify: Verify Item Category of Item is updated on Requisition Line of Requisition Worksheet.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        RequisitionLine.TestField("Item Category Code", Item."Item Category Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalPlanForReqWkshForSalesCreatedFromBlanketOrder()
    var
        Item: Record Item;
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        RequisitionLine: Record "Requisition Line";
        OldCreditWarnings: Option;
        OldStockoutWarning: Boolean;
        QuantityToShip: Decimal;
        StartDate: Date;
        EndDate: Date;
    begin
        // Setup: Create Order Item, Create Sales Order from Blanket Order with new Quantity To Ship.
        Initialize();
        UpdateSalesReceivablesSetup(OldStockoutWarning, OldCreditWarnings, false, SalesReceivablesSetup."Credit Warnings"::"No Warning");
        CreateOrderItem(Item);
        QuantityToShip := LibraryRandom.RandDec(10, 2);
        CreateSalesOrderFromBlanketOrder(Item."No.", QuantityToShip);

        // Exercise: Calculate Plan for Requisition Worksheet.
        StartDate := GetRequiredDate(10, 0, WorkDate(), -1);  // Start Date less than WORKDATE
        EndDate := GetRequiredDate(10, 0, WorkDate(), 1);  // End Date more than to WORKDATE.
        CalculatePlanForRequisitionWorksheet(RequisitionWkshName, Item."No.", '', StartDate, EndDate);

        // Verify: Verify Requisition Worksheet Action Message, Quantity and Reference Order Type.
        VerifyRequisitionLineWithItem(Item, RequisitionLine."Action Message"::New, QuantityToShip, 0, '', '');

        // Teardown.
        UpdateSalesReceivablesSetup(OldStockoutWarning, OldCreditWarnings, OldStockoutWarning, OldCreditWarnings);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanWithReqWkshWithSKUAndPurchaseForMQItem()
    var
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        ItemJournalLine: Record "Item Journal Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        StartDate: Date;
        EndDate: Date;
    begin
        // Setup: Create Maximum Quantity Item.Create Stockkeeping Unit. Update Inventory With Location.
        Initialize();
        CreateMaximumQtyItem(Item, LibraryRandom.RandDec(50, 2) + 50);  // Large Random quantity for Maximum Inventory.
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, LocationSilver2.Code, Item."No.", '');
        UpdateInventoryWithLocationAndVariant(
          ItemJournalLine, Item."No.", LibraryRandom.RandDec(10, 2), ItemJournalLine."Entry Type"::"Positive Adjmt.",
          LocationSilver2.Code, '');

        // Create Purchase Order With Location.
        CreatePurchaseOrderWithLocationAndVariant(PurchaseHeader, Item."No.", LocationSilver2.Code, '', LibraryRandom.RandDec(10, 2));
        SelectPurchaseLine(PurchaseLine, Item."No.");

        // Exercise: Calculate Plan for Requisition Worksheet.
        StartDate := GetRequiredDate(10, 0, WorkDate(), -1);  // Start Date less than WORKDATE.
        EndDate := GetRequiredDate(10, 0, PurchaseLine."Expected Receipt Date", 1);  // End Date relative to Purchase Line Expected receipt Date.
        CalculatePlanForRequisitionWorksheet(RequisitionWkshName, Item."No.", Item."No.", StartDate, EndDate);

        // Verify: Verify Planning Worksheet Location,Action Message, Quantity and Reference Order Type.
        VerifyRequisitionLineWithItem(
          Item, RequisitionLine."Action Message"::New, Item."Maximum Inventory" - ItemJournalLine.Quantity, 0, LocationSilver2.Code, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanWithTransferAndDampenerPeriodForLFLItem()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        StockkeepingUnit: Record "Stockkeeping Unit";
        ItemVariant: Record "Item Variant";
        RequisitionLine: Record "Requisition Line";
        StartDate: Date;
        EndDate: Date;
    begin
        // Setup: Create Lot for Lot Item and Stockkeeping Unit setup.
        Initialize();
        CreateLFLItemWithVariantAndSKU(Item, ItemVariant, StockkeepingUnit, LocationSilver.Code);

        // Update Rescheduling Period - 0D, Dampener Period with random value and Lot Accumulation Period -0D  on Stockkeeping Unit of Item.
        UpdateLotForLotSKUPlanningParameters(StockkeepingUnit, '<0D>', GetRequiredPeriod(2, 5), '<0D>');

        // Create Tansfer Order.
        CreateTransferOrderWithReceiptDate(
          TransferHeader, Item."No.", LocationBlue.Code, LocationSilver.Code, LibraryRandom.RandDec(10, 2));
        SelectTransferLine(TransferLine, TransferHeader."No.");

        // Exercise: Calculate Plan for Planning Worksheet.
        StartDate := GetRequiredDate(20, 0, TransferLine."Receipt Date", -1);  // Start Date relative to Receipt Date of Transfer Order.
        EndDate := GetRequiredDate(30, 0, TransferLine."Receipt Date", 1);  // End Date relative to Receipt Date of Transfer Order.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, StartDate, EndDate);

        // Verify: Verify Planning Worksheet with Location, Action Message,Reference Order Type and effect of Dampener Period on Quantities.
        VerifyRequisitionLineWithDueDateForTransfer(
          RequisitionLine."Action Message"::Cancel, 0, TransferLine.Quantity, TransferLine."Receipt Date", LocationSilver.Code);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcPlanWithForecastAndDampenerPeriodForLFLItem()
    var
        Item: Record Item;
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        StockkeepingUnit: Record "Stockkeeping Unit";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ItemVariant: Record "Item Variant";
        RequisitionLine: Record "Requisition Line";
        PlanningWorksheet: TestPage "Planning Worksheet";
        ForecastDate: Date;
    begin
        // Setup: Create Lot for Lot Item and Stockkeeping Unit setup.
        Initialize();
        CreateLFLItemWithVariantAndSKU(Item, ItemVariant, StockkeepingUnit, LocationSilver.Code);

        // Update Rescheduling Period - 0D, Dampener Period with random value and Lot Accumulation Period -0D  on Stockkeeping Unit of Item.
        UpdateLotForLotSKUPlanningParameters(StockkeepingUnit, '<0D>', GetRequiredPeriod(2, 5), '<0D>');

        // Create Production Forecast with multiple Entries.
        ForecastDate := GetRequiredDate(10, 0, WorkDate(), 1);  // Forecast Date Relative to Workdate.
        CreateProductionForecastSetupWithLocation(ProductionForecastEntry, Item."No.", LocationBlue.Code, ForecastDate, true);  // Boolean - TRUE, for multiple Forecast Entry.

        // Exercise: Calculate Plan for Planning Worksheet.
        CreateRequisitionWorksheetName(RequisitionWkshName);
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item."No.");

        // Verify: Verify Planning Worksheet with Action Message, Reference Order Type and effect of Dampener Period on Quantities.
        VerifyRequisitionLineWithDueDate(
          Item, RequisitionLine."Action Message"::New, ProductionForecastEntry[1]."Forecast Quantity", 0,
          ProductionForecastEntry[1]."Forecast Date");
        VerifyRequisitionLineWithDueDate(
          Item, RequisitionLine."Action Message"::New, ProductionForecastEntry[2]."Forecast Quantity", 0,
          ProductionForecastEntry[2]."Forecast Date");
        VerifyRequisitionLineWithDueDate(
          Item, RequisitionLine."Action Message"::New, ProductionForecastEntry[3]."Forecast Quantity", 0,
          ProductionForecastEntry[3]."Forecast Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanAndReleasedProdOrderDeletedAfterCarryOutLFLItem()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Lot for Lot Item setup.
        CreateLotForLotItem(Item);

        // Create and Refresh Released Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, Item."No.", ProductionOrder.Status::Released, LibraryRandom.RandDec(10, 2));

        // Exercise: Calculate Plan for Planning Worksheet and Carry Out Action Message.
        CalcRegenPlanAndCarryOutActionMessage(Item);

        // Verify: Verify the Released Production Order having tracking on its component is deleted.
        ProductionOrder.SetRange("Source No.", Item."No.");
        ProductionOrder.SetRange(Status, ProductionOrder.Status::Released);
        Assert.IsTrue(ProductionOrder.IsEmpty, StrSubstNo(ProductionOrderMustNotExist, Item."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanTwiceForSKUSafetyStockQuantityForLFLItem()
    var
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        RequisitionLine: Record "Requisition Line";
    begin
        // Setup: Create Lot for Lot Item with Safety Stock Quantity. Create Stockkeeping Unit for Item.
        Initialize();
        CreateLotForLotItem(Item);
        UpdateReplenishmentSystemOnItem(Item);  // Update Replenishment System Production Order.
        UpdateItemSafetyStockQuantityAndLeadTimeCalculation(Item, '<0D>');  // Lead Time Calculation - 0D.
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, LocationBlue.Code, Item."No.", '');

        // Calculate Plan for Planning Worksheet.
        CalculateRegenPlanForPlanningWorksheet(Item);

        // Update Safety Stock Quantity on Stockkeeping Unit.
        UpdateSKUSafetyStockQuantity(StockkeepingUnit, Item."Safety Stock Quantity" + LibraryRandom.RandDec(10, 2));

        // Exercise: Calculate Plan for Planning Worksheet.
        CalculateRegenPlanForPlanningWorksheet(Item);

        // Verify: Verify Planning Worksheet Location and Action Message. Verify Safety Stock Quantity of Stockkeeping Unit of Item is updated on Requisition Line for Item.
        VerifyRequisitionLineWithItem(
          Item, RequisitionLine."Action Message"::New, StockkeepingUnit."Safety Stock Quantity", 0, LocationBlue.Code, '');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CalcRegenPlanForLotSpecificSalesAndTrackingOnRequisitionLineLFLItem()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
    begin
        // Setup: Create Lot for Lot Item. Update Lot specific Tracking and Lot Nos on Item.
        Initialize();
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        CreateLotForLotItem(Item);
        UpdateTrackingAndLotNosOnItem(Item, ItemTrackingCode.Code);

        // Create Sales Order. Assign Lot specific Tracking to Sales Line.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandDec(10, 2));
        LibraryVariableStorage.Enqueue(ItemTrackingOption::AssignLotNo);  // Used inside ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(AvailabilityWarningConfirmationMessage);  // Required inside ConfirmHandler.
        SalesLine.OpenItemTrackingLines();  // Assign Tracking on Sales Line using page Item Tracking Lines. Page Handler - ItemTrackingLinesPageHandler.

        // Exercise: Calculate Plan for Planning Worksheet.
        CalculateRegenPlanForPlanningWorksheet(Item);

        // Verify: Verify Tracking is also assigned to requisition Line for Item. Verified in ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(ItemTrackingOption::VerifyTrackingQty);  // Used inside ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(SalesLine.Quantity);  // Enqueue variable for Quantity(Base) on Item Tracking Lines Page.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        RequisitionLine.OpenItemTrackingLines();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure CalcRegenPlanTwiceForNewPurchaseAfterCarryOutLotSpecificTrackingLFLItem()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
    begin
        // Setup: Create Lot for Lot Item. Update Lot specific Tracking and Lot Nos on Item.
        Initialize();
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        CreateLotForLotItem(Item);
        UpdateTrackingAndLotNosOnItem(Item, ItemTrackingCode.Code);

        // Create Sales Order.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandDecInDecimalRange(10, 20, 2));

        // Calculate Plan for Planning Worksheet and Carry out Action Message.
        CalcRegenPlanAndCarryOutActionMessage(Item);

        // Update Quantity on Purchase Line created after Carry Out. Assign Lot Specific Tracking on Purchase Line. Post Purchase Order with Receive.
        AssignTrackingAndPostPurchaseWithReducedQuantity(PurchaseLine, Item."No.");

        // Exercise: Calculate Plan for Planning Worksheet.
        CalculateRegenPlanForPlanningWorksheet(Item);

        // Verify: Verify Planning Worksheet with Action Message, Reference Order Type and Quantity.
        VerifyRequisitionLineWithItem(Item, RequisitionLine."Action Message"::New, SalesLine.Quantity - PurchaseLine.Quantity, 0, '', '');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CalcRegenPlanTwiceTrackedTransferOrderDeletedAfterCarryOutLFLItem()
    var
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        ItemTrackingCode: Record "Item Tracking Code";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemVariant: Record "Item Variant";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        EndDate: Date;
    begin
        // Setup: Create Lot for Lot Item setup. Update Lot specific Tracking and Lot Nos on Child Item.
        Initialize();
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        CreateLFLItemWithVariantAndSKU(Item, ItemVariant, StockkeepingUnit, LocationSilver.Code);
        UpdateTrackingAndLotNosOnItem(Item, ItemTrackingCode.Code);

        // Create Tansfer Order. Open Tracking On Tansfer Line.
        CreateTransferOrderWithReceiptDate(
          TransferHeader, Item."No.", LocationBlue.Code, LocationSilver.Code, LibraryRandom.RandDec(10, 2));
        SelectTransferLine(TransferLine, TransferHeader."No.");
        LibraryVariableStorage.Enqueue(AvailabilityWarningConfirmationMessage);
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);  // Assign Tracking on Page Handler ItemTrackingPageHandler.

        // Calculate Plan for Requisition Worksheet.
        EndDate := GetRequiredDate(10, 30, WorkDate(), 1);  // End Date relative to Workdate.
        CalculatePlanForRequisitionWorksheet(RequisitionWkshName, Item."No.", '', WorkDate(), EndDate);

        // Create Sales Order with Location.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandDec(5, 2));
        UpdateLocationAndVariantOnSalesLine(SalesLine, LocationBlue.Code, '');
        LibraryVariableStorage.Enqueue(AvailabilityWarningConfirmationMessage);
        SalesLine.OpenItemTrackingLines();

        // Exercise: Calculate Plan for Planning Worksheet and Carry out Action Message.
        CalcPlanAndCarryOutActionMessage(Item, WorkDate(), EndDate);

        // Exercise: Post created purchase order.
        PostCarriedOutPurchaseOrder(Item."No.");

        // Exercise: Ship transfer order
        PostTransferHeader(TransferLine, TransferHeader);

        // Exercise: Select created Transfer Order.
        asserterror TransferHeader.Get(TransferHeader."No.");

        // Verify: Verify the Transfer Order having tracking attached to it, is deleted.
        Assert.ExpectedErrorCannotFind(Database::"Transfer Header");
    end;

    [Test]
    [HandlerFunctions('OrderPromisingPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningLineWhenCalculateCapableToPromiseForSales()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        PlannedDeliveryDate: Date;
    begin
        // Setup: Create Lot for Lot Item.
        Initialize();
        CreateLotForLotItem(Item);

        // Create Sales Order. Update Plannede Delivery date on Sales Line.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandDec(10, 2));
        PlannedDeliveryDate := GetRequiredDate(10, 30, SalesLine."Shipment Date", 1);  // Planned Delivery Date more than Shipment Date.
        UpdateSalesLinePlannedDeliveryDate(SalesLine, PlannedDeliveryDate);

        // Exercise: Open Order Promising Lines Page and Invoke Capable to Promise to create Requisition Worksheet Line.
        OpenOrderPromisingPage(SalesLine."Document No.");  // Using Page to avoid Due Date error - OrderPromisingPageHandler.

        // Verify: Verify Requisition Line with Action Message,Quantity and Due Date after Calculating Capable To Promise.
        VerifyRequisitionLineWithDueDate(
          Item, RequisitionLine."Action Message"::New, SalesLine.Quantity, 0, SalesLine."Planned Shipment Date");
    end;


    [Test]
    [HandlerFunctions('OrderPromisingPageHandler,ConfirmHandlerAnyMessage')]
    procedure MaintainRequisitionLinesWhenCreditMemoChanges()
    var
        Item: Record Item;
        SalesOrderHeader: Record "Sales Header";
        SalesCreditMemoPage: TestPage "Sales Credit Memo";
        SalesOrderLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        CustomerNo1: Code[20];
        CustomerNo2: Code[20];
    begin
        // Scenario: Create Sales Order, use Capable-to-Promise to create requisition lines.
        // Then, create a Credit Memo with the same "Document No."" and a "Sell-to Customer No.".
        // Then change the "Sell-to Customer No" and verify that the req lines are not removed.

        // Setup: Create Sales Order with location
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateSalesOrder(SalesOrderHeader, SalesOrderLine, Item."No.", LibraryRandom.RandDec(10, 2));
        SalesOrderLine.Validate("Location Code", LocationBlue.Code);
        SalesOrderLine.Modify(true);

        // Exercise: Open Order Promising Lines Page and Invoke Capable to Promise to create Requisition Worksheet Line.
        OpenOrderPromisingPage(SalesOrderHeader."No.");

        // Verify: Order Promising Line.
        RequisitionLine.SetRange("No.", Item."No.");
        Assert.IsTrue(RequisitionLine.FindFirst(), 'There should be at least one requisition line');

        // Exercise: Create a Sales Credit memo with the same "No." as the Order
        CustomerNo1 := LibrarySales.CreateCustomerNo();
        SalesCreditMemoPage.OpenNew();
        SalesCreditMemoPage."No.".SetValue(SalesOrderHeader."No.");
        SalesCreditMemoPage."Sell-to Customer Name".SetValue(CustomerNo1);
        SalesCreditMemoPage.SalesLines.New();
        SalesCreditMemoPage.SalesLines."No.".SetValue(Item."No.");

        // Exercise: Change the Sell-to Customer Name
        CustomerNo2 := LibrarySales.CreateCustomerNo();
        SalesCreditMemoPage."Sell-to Customer Name".SetValue(CustomerNo2);

        // Verify: The Requisition lines are still there
        RequisitionLine.SetRange("No.", Item."No.");
        Assert.IsTrue(RequisitionLine.FindFirst(), 'There should be at least one requisition line');
    end;


    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanReqWkshWithNewProdOrderComponentForFirmPlannedProdOrderLFLItem()
    var
        ChildItem: Record Item;
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderComponent2: Record "Prod. Order Component";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        StartDate: Date;
        EndDate: Date;
    begin
        // Setup: Create Lot for Lot Parent and Child Item. Create and Certify Production BOM. Update Safety Stock Quantity and Lead Time Calculation on Child item.
        Initialize();
        CreateLotForLotItemSetup(ChildItem, Item);
        UpdateItemSafetyStockQuantityAndLeadTimeCalculation(ChildItem, '<' + Format(LibraryRandom.RandInt(5) + 10) + 'W>');  // Random Lead Time Calculation.

        // Create and refresh Firm Planned Production Order. Create Production Order Components.
        CreateAndRefreshFirmPlannedProductionOrderWithLocation(ProductionOrder, Item."No.", '', LibraryRandom.RandDec(10, 2));
        CreateProdOrderComponent(ProductionOrder, ProdOrderComponent, ChildItem."No.");

        // Exercise: Calculate Plan for Requisition Worksheet.
        StartDate := GetRequiredDate(10, 0, ProdOrderComponent."Due Date", -1);  // Start Date less than Production Order Component Due date.
        EndDate := GetRequiredDate(10, 0, ProductionOrder."Due Date", 1);  // End Date more than Production Order Due Date.
        CalculatePlanForRequisitionWorksheet(RequisitionWkshName, Item."No.", ChildItem."No.", StartDate, EndDate);

        // Verify: Verify Planning Worksheet with Action Message, Reference Order Type and Quantity.
        ProdOrderComponent2.SetRange(Status, ProdOrderComponent.Status);
        ProdOrderComponent2.SetRange("Prod. Order No.", ProdOrderComponent."Prod. Order No.");
        ProdOrderComponent2.SetRange("Prod. Order Line No.", ProdOrderComponent."Prod. Order Line No.");
        ProdOrderComponent2.CalcSums("Expected Quantity");
        VerifyRequisitionLineWithItem(ChildItem, RequisitionLine."Action Message"::New, ChildItem."Safety Stock Quantity", 0, '', '');
        VerifyRequisitionLineWithDueDate(
          ChildItem, RequisitionLine."Action Message"::New, ProdOrderComponent2."Expected Quantity", 0, ProdOrderComponent."Due Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanReqWkshTwiceWithNewProdOrderComponentForProdAndPurchaseLFLItem()
    var
        ChildItem: Record Item;
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        StartDate: Date;
        EndDate: Date;
    begin
        // Setup: Create Lot for Lot Parent and Child Item. Create and Certify Production BOM. Update Safety Stock Quantity and Lead Time Calculation on Child item.Initialize();
        CreateLotForLotItemSetup(ChildItem, Item);
        UpdateItemSafetyStockQuantityAndLeadTimeCalculation(ChildItem, '<' + Format(LibraryRandom.RandInt(5) + 10) + 'W>');  // Random Lead Time Calculation.

        // Create and refresh Firm Planned Production Order. Create Production Order Components.
        CreateAndRefreshFirmPlannedProductionOrderWithLocation(ProductionOrder, Item."No.", '', LibraryRandom.RandDec(10, 2));
        CreateProdOrderComponent(ProductionOrder, ProdOrderComponent, ChildItem."No.");

        // Calculate Plan for Requisition Worksheet.
        StartDate := GetRequiredDate(10, 0, ProdOrderComponent."Due Date", -1);  // Start Date less than Production Order Component Due date.
        EndDate := GetRequiredDate(10, 0, ProductionOrder."Due Date", 1);  // End Date more than Production Order Due Date.
        CalculatePlanForRequisitionWorksheet(RequisitionWkshName, Item."No.", ChildItem."No.", StartDate, EndDate);

        // Create Purchase Order for Child Item.
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, ChildItem."No.", LibraryRandom.RandDec(10, 2));

        // Exercise: Calculate Plan for Requisition Worksheet.
        CalculatePlanForRequisitionWorksheet(RequisitionWkshName, Item."No.", ChildItem."No.", StartDate, EndDate);

        // Verify: Verify Planning Worksheet with Action Message, Reference Order Type and Quantity.
        VerifyRequisitionLineWithItem(ChildItem, RequisitionLine."Action Message"::New, ChildItem."Safety Stock Quantity", 0, '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanForSupplyDemandMismatchLocationLFLItem()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
    begin
        // Setup: Create Lot for Lot Item. Create Sales Order With Location.
        Initialize();
        CreateLotForLotItem(Item);
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandDec(10, 2));
        UpdateLocationAndVariantOnSalesLine(SalesLine, LocationYellow.Code, '');

        // Create Purchase Order with different Location than Sales Order.
        CreatePurchaseOrderWithLocationAndVariant(PurchaseHeader, Item."No.", LocationBlue.Code, '', SalesLine.Quantity);

        // Exercise: Calculate Plan for Planning Worksheet.
        CalculateRegenPlanForPlanningWorksheet(Item);

        // Verify: Verify Planning Worksheet for Location,Quantity, and Action Message when demand and supply have mismatch of Location.
        SelectPurchaseLine(PurchaseLine, Item."No.");
        VerifyRequisitionLineForLocationAndVariant(
          Item, RequisitionLine."Action Message"::New, SalesLine.Quantity, 0, SalesLine."Shipment Date", LocationYellow.Code, '');
        VerifyRequisitionLineForLocationAndVariant(
          Item, RequisitionLine."Action Message"::Cancel, 0, PurchaseLine.Quantity, PurchaseLine."Expected Receipt Date", LocationBlue.Code,
          '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanForTransferOrderItem()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        RequisitionLine: Record "Requisition Line";
    begin
        // Setup: Create Order Item. Create Transfer Order.
        Initialize();
        CreateOrderItem(Item);
        CreateTransferOrderWithReceiptDate(
          TransferHeader, Item."No.", LocationSilver.Code, LocationBlue.Code, LibraryRandom.RandDec(10, 2));

        // Exercise: Calculate Plan for Planning Worksheet.
        CalculateRegenPlanForPlanningWorksheet(Item);

        // Verify: Verify Planning Worksheet for Location,Quantity, and Action Message.
        SelectTransferLine(TransferLine, TransferHeader."No.");
        VerifyRequisitionLineWithDueDateForTransfer(
          RequisitionLine."Action Message"::Cancel, 0, TransferLine.Quantity, TransferLine."Receipt Date", LocationBlue.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanForPostedPurchaseAndTransferLFLItem()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        RequisitionLine: Record "Requisition Line";
        Quantity: Decimal;
    begin
        // Setup: Create Lot For Lot Item.
        Initialize();
        CreateLotForLotItem(Item);

        // Create Purchase Order with Location.Post Purchase Order.
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateAndPostPurchaseWithLocation(Item."No.", LocationBlue.Code, Quantity);

        // Create and Post Transfer Order.
        CreateTransferOrderWithReceiptDate(TransferHeader, Item."No.", LocationBlue.Code, LocationRed.Code, Quantity);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);  // Ship -TRUE.

        // Exercise: Calculate Plan for Planning Worksheet.
        CalculateRegenPlanForPlanningWorksheet(Item);

        // Verify: Verify that no Requisition line is created for Requisition Worksheet.
        FilterOnRequisitionLine(RequisitionLine, Item."No.");
        Assert.IsTrue(RequisitionLine.IsEmpty, StrSubstNo(RequisitionLineMustNotExist, Item."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanForSalesWithLocationCarryOutForTransferOrderLFLItem()
    begin
        // Setup: Calculate Plan for Planning Worksheet and Carry out Action Message with locations that are not Warehouse Locations.
        Initialize();
        CalcRegenPlanForSalesAndSKUNewTransferWithLocationsAfterCarryOutLFLItem(LocationRed.Code, LocationBlue.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanForSalesWithWarehouseLocationCarryOutForTransferOrderLFLItem()
    begin
        // Setup: Calculate Plan for Planning Worksheet and Carry out Action Message with Warehouse Locations.
        Initialize();
        CalcRegenPlanForSalesAndSKUNewTransferWithLocationsAfterCarryOutLFLItem(LocationSilver2.Code, LocationGreen.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerAnyMessage,ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure ItemLotNosOnShippedTransferOrderAfterSalesOrderDeleted()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TransferHeader: Record "Transfer Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup: Create Location.
        Initialize();

        // Create a new Item and define the Stockkeeping Unit.
        CreateOrderItem(Item);
        CreateLotNosAndStockkeepingUnitForItemWithTransfer(Item, LocationRed.Code, LocationBlue.Code);

        // Exercise: Create Sales Order with Locations.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandDec(10, 2));
        UpdateLocationAndVariantOnSalesLine(SalesLine, LocationBlue.Code, '');

        // Calculate Plan for Planning Worksheet and Carry out Action Message. Assign Lot Specific Tracking on Purchase Line. Post Purchase Order with Receive.
        CalcRegenPlanAndCarryOutActionMessage(Item);
        AssignTrackingAndPostPurchase(PurchaseLine, Item."No.");

        // Ship transfer order and delete Sales order.
        FindAndPostTransferHeaderByItemNo(TransferHeader, Item."No.");
        SalesHeader.Delete(true);

        // Receive transfer order.
        LibraryWarehouse.PostTransferOrder(TransferHeader, false, true);

        // Verify: Transfer Shipment can be post successfully.
        VerifyTransferShipment(Item."No.", LocationRed.Code, LocationBlue.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerAnyMessage,ItemTrackingPageHandlerForAssignSN,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure ItemSerialNosOnShippedTransferOrderAfterSalesOrderDeleted()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TransferHeader: Record "Transfer Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup: Create Location.
        Initialize();

        // Create a new Item and define the Stockkeeping Unit.
        CreateOrderItem(Item);
        CreateSerialNosAndStockkeepingUnitForItemWithTransfer(Item, LocationRed.Code, LocationBlue.Code);

        // Exercise: Create Sales Order with Locations.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandIntInRange(10, 2));
        UpdateLocationAndVariantOnSalesLine(SalesLine, LocationBlue.Code, '');

        // Calculate Plan for Planning Worksheet and Carry out Action Message. Assign Lot Specific Tracking on Purchase Line. Post Purchase Order with Receive.
        CalcRegenPlanAndCarryOutActionMessage(Item);
        AssignTrackingAndPostPurchase(PurchaseLine, Item."No.");

        // Ship transfer order and delete Sales order.
        FindAndPostTransferHeaderByItemNo(TransferHeader, Item."No.");
        SalesHeader.Delete(true);

        // Receive transfer order.
        LibraryWarehouse.PostTransferOrder(TransferHeader, false, true);

        // Verify: Transfer Shipment can be post successfully.
        VerifyTransferShipment(Item."No.", LocationRed.Code, LocationBlue.Code);
    end;

    local procedure CalcRegenPlanForSalesAndSKUNewTransferWithLocationsAfterCarryOutLFLItem(FromLocationCode: Code[10]; ToLocationCode: Code[10])
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Create Lot for Lot Item and Stockkeeping Unit on Locations.
        CreateLotForLotItem(Item);
        CreateSKUSetupWithTransfer(Item."No.", FromLocationCode, ToLocationCode);

        // Create Sales Order with Locations.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandDec(10, 2));
        UpdateLocationAndVariantOnSalesLine(SalesLine, ToLocationCode, '');

        // Exercise: Calculate Plan for Planning Worksheet and Carry out Action Message.
        CalcRegenPlanAndCarryOutActionMessage(Item);

        // Verfiy: Verify Transfer Order is created with required quantity successfully with both types of locations after Carry Out with Locations.
        VerifyTransferLine(Item."No.", FromLocationCode, SalesLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshProdOrderAfterDeleteRoutingLineWithComment()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ProductionOrder: Record "Production Order";
        WorkCenterNo: Code[20];
        Operation: Option Comment,Tool,Personnel,QualityMeasure;
    begin
        // Setup: Create item. Create routing with comment. Create and release sales order.
        Initialize();
        // Reordering Policy can be anyone except Order. Since reservation entry will be generated when select order
        // so that production order cannot be refreshed. Using Lot-for-Lot is easier than other available options.
        CreateItem(Item, Item."Reordering Policy"::"Lot-for-Lot", Item."Replenishment System"::"Prod. Order");
        WorkCenterNo := CreateRoutingWithOperationAndUpdateItem(Item, Operation::Comment);
        CreateAndReleaseSalesOrder(SalesHeader, Item."No.");

        // Exercise: Delete the routing line after Calculate Regenerative Plan, then Carry Out Action Message.
        DeletePlanningRoutingLineAndCarryOutActionMessage(Item, WorkCenterNo);

        // Verify: Production order can be refreshed successfully without error.
        VerifyProductionOrderWithRefresh(ProductionOrder, Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshProdOrderAfterDeleteRoutingLineWithTool()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ProductionOrder: Record "Production Order";
        WorkCenterNo: Code[20];
        Operation: Option Comment,Tool,Personnel,QualityMeasure;
    begin
        // Setup: Create item. Create routing with Tool. Create and release sales order.
        Initialize();
        // Reordering Policy can be anyone except Order. Since reservation entry will be generated when select order
        // so that production order cannot be refreshed. Using Lot-for-Lot is easier than other available options.
        CreateItem(Item, Item."Reordering Policy"::"Lot-for-Lot", Item."Replenishment System"::"Prod. Order");
        WorkCenterNo := CreateRoutingWithOperationAndUpdateItem(Item, Operation::Tool);
        CreateAndReleaseSalesOrder(SalesHeader, Item."No.");

        // Exercise: Delete the routing line after Calculate Regenerative Plan, then Carry Out Action Message.
        DeletePlanningRoutingLineAndCarryOutActionMessage(Item, WorkCenterNo);

        // Verify: Production order can be refreshed successfully without error.
        VerifyProductionOrderWithRefresh(ProductionOrder, Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshProdOrderAfterDeleteRoutingLineWithPersonnel()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ProductionOrder: Record "Production Order";
        WorkCenterNo: Code[20];
        Operation: Option Comment,Tool,Personnel,QualityMeasure;
    begin
        // Setup:  Create item. Create routing with personnel. Create and release sales order.
        Initialize();
        // Reordering Policy can be anyone except Order. Since reservation entry will be generated when select order
        // so that production order cannot be refreshed. Using Lot-for-Lot is easier than other available options.
        CreateItem(Item, Item."Reordering Policy"::"Lot-for-Lot", Item."Replenishment System"::"Prod. Order");
        WorkCenterNo := CreateRoutingWithOperationAndUpdateItem(Item, Operation::Personnel);
        CreateAndReleaseSalesOrder(SalesHeader, Item."No.");

        // Exercise: Delete the routing line after Calculate Regenerative Plan, then Carry Out Action Message.
        DeletePlanningRoutingLineAndCarryOutActionMessage(Item, WorkCenterNo);

        // Verify: Production order can be refreshed successfully without error.
        VerifyProductionOrderWithRefresh(ProductionOrder, Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshProdOrderAfterDeleteRoutingLineWithQualityMeasure()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ProductionOrder: Record "Production Order";
        WorkCenterNo: Code[20];
        Operation: Option Comment,Tool,Personnel,QualityMeasure;
    begin
        // Setup: Create item. Create routing with Quality measure.Create and release sales order.
        Initialize();
        // Reordering Policy can be anyone except Order. Since reservation entry will be generated when select order
        // so that production order cannot be refreshed. Using Lot-for-Lot is easier than other available options.
        CreateItem(Item, Item."Reordering Policy"::"Lot-for-Lot", Item."Replenishment System"::"Prod. Order");
        WorkCenterNo := CreateRoutingWithOperationAndUpdateItem(Item, Operation::QualityMeasure);
        CreateAndReleaseSalesOrder(SalesHeader, Item."No.");

        // Exercise: Delete the routing line after Calculate Regenerative Plan, then Carry Out Action Message.
        DeletePlanningRoutingLineAndCarryOutActionMessage(Item, WorkCenterNo);

        // Verify: Production order is refreshed successfully without error.
        VerifyProductionOrderWithRefresh(ProductionOrder, Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcNetChangePlanAfterInsertOneLineInPlanningComponent()
    var
        Item: Record Item;
        Item2: Record Item;
        PlanningComponent: Record "Planning Component";
        RequisitionLine: Record "Requisition Line";
        Quantity: Decimal;
        QuantityPer: Decimal;
    begin
        // Setup: Create sales order.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);
        QuantityPer := LibraryRandom.RandInt(10);
        CreateSalesOrderForRegenPlan(Item, Item2, Quantity);

        // Exercise: Calculate Regenerative Plan for Planning Worksheet.
        // Add one line in Planning Component. Then calculate Net Change Plan.
        CalculateRegenPlanForPlanningWorksheet(Item);
        SelectRequisitionLine(RequisitionLine, Item."No.");
        CreateOneLineOnPlanningComponent(PlanningComponent, RequisitionLine, Item2."No.", QuantityPer);
        CalcNetChangePlanForPlanWkshForMultipleItems(Item."No.", Item2."No.");

        // Verify: Verify calculate successfully and the added line in Planning Component is added in Planning worksheet.
        VerifyRequisitionLineWithAddedItem(RequisitionLine, Item2."No.", Quantity * QuantityPer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostItemJournalWithinItemAvailabilityWhenReservationEntryExist()
    begin
        PostItemJournalWithItemAvailabilityWhenReservationEntryExist(true); // No warning pops up when it has available Item.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostItemJournalOutOfItemAvailabilityWhenReservationEntryExist()
    begin
        PostItemJournalWithItemAvailabilityWhenReservationEntryExist(false); // Warning pops up when it hasn't available Item.
    end;

    local procedure PostItemJournalWithItemAvailabilityWhenReservationEntryExist(ItemAvailability: Boolean)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        Quantity: Decimal;
    begin
        // Setup: Create an Order Item.
        Initialize();
        CreateOrderItem(Item);
        Quantity := LibraryRandom.RandInt(10);

        // Create a Sales Order with Location.
        CreateSalesOrderWithLocation(SalesHeader, SalesLine, Item."No.", Quantity, LocationYellow.Code);

        // Calculate Plan and Carry Out Action Message. Post carried Purchase Order.
        CalculatePlanForRequisitionWorksheet(RequisitionWkshName, Item."No.", '', WorkDate(), WorkDate());
        CarryoutActionMessageForPlanWorksheet(RequisitionLine, Item."No.");
        PostCarriedOutPurchaseOrder(Item."No.");

        // Post Positive Adjustment in Item Journal.
        UpdateInventoryWithLocationAndVariant(
          ItemJournalLine, Item."No.", Quantity, ItemJournalLine."Entry Type"::"Positive Adjmt.", LocationYellow.Code, '');

        // Create Negative Adjustment with a new Batch in Item Journal.
        CreateItemJournalLineWithNewBatch(
          ItemJournalBatch, ItemJournalLine, Item."No.", Quantity, ItemJournalLine."Entry Type"::"Negative Adjmt.", LocationYellow.Code);

        // Exercise & Verify: Post Negative Adjustment with default Batch in Item Journal.
        if ItemAvailability then begin
            UpdateInventoryWithLocationAndVariant(
              ItemJournalLine, Item."No.", Quantity, ItemJournalLine."Entry Type"::"Negative Adjmt.", LocationYellow.Code, '');
            VerifyItemInventory(Item, Quantity); // Verify Item Inventory after posting Item Journal successfully.
        end else begin
            LibraryVariableStorage.Enqueue(ReservationEntryExistMsg); // Requied for ConfirmHandler.
            UpdateInventoryWithLocationAndVariant(
              ItemJournalLine, Item."No.", Quantity + 1, ItemJournalLine."Entry Type"::"Negative Adjmt.", LocationYellow.Code, ''); // Quantity needs greater than the positive qty.
            VerifyItemInventory(Item, (Quantity - 1)); // Verify Item Inventory after posting Item Journal successfully.
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReceivePurchaseOrderForDropShipment()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup: Create Order Item. Create Sales Order with Drop Shipment. Carry out Purchase Order by Requisition Worksheet.
        Initialize();
        CarryOutPurchaseOrderForDropShipmentOnReqWksh(Item, SalesHeader, SalesLine);

        // Exercise: Receive Purchase Order.
        SelectPurchaseLine(PurchaseLine, Item."No.");
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        SalesHeader.Get(SalesLine."Document Type"::Order, SalesLine."Document No."); // Get the Sales Header.

        // Verify: Verify the Ship Field is TRUE and Status is Released on Sales Header.
        VerifyShipAndStatusFieldOnSalesHeader(SalesHeader.Ship, SalesHeader.Status, true, SalesHeader.Status::Released);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipSalesOrderForDropShipment()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup: Create Order Item. Create Sales Order with Drop Shipment. Carry out Purchase Order by Requisition Worksheet.
        Initialize();
        CarryOutPurchaseOrderForDropShipmentOnReqWksh(Item, SalesHeader, SalesLine);

        // Exercise: Ship the Sales Order.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        SelectPurchaseLine(PurchaseLine, Item."No.");
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No."); // Get the Purchase Header.

        // Verify: Verify the Receive Field is TRUE and Status is Released on Purchase Header.
        VerifyReceiveAndStatusFieldOnPurchaseHeader(PurchaseHeader.Receive, PurchaseHeader.Status, true, PurchaseHeader.Status::Released);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcRegenPlanFromSalesOrderWithCombinedMPSAndMRP()
    begin
        CalcRegenPlanWithCombinedMPSAndMRP(true);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcRegenPlanFromProdForecastWithCombinedMPSAndMRP()
    begin
        CalcRegenPlanWithCombinedMPSAndMRP(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReCalcRegenPlanAfterDeleteOneRequisitionLineAtFirstCalculation()
    var
        Item: Record Item;
        Item2: Record Item;
        RequisitionLine: Record "Requisition Line";
        LineNo: Integer;
    begin
        // Verify no extra empty line generated before the generated line with Item when re-calc Regenerative Plan in Planning Worksheet.

        // Setup: Create two Maximum Items. Maximum Inventory must be greater than Reorder Point.
        Initialize();
        CreateMaximumQtyItem(Item, LibraryRandom.RandIntInRange(40, 50));
        CreateMaximumQtyItem(Item2, LibraryRandom.RandIntInRange(40, 50));

        // Calculate Regenerative Plan for two Items. Delete one Requisition Line.
        // Carry Out Action Message for Planning Worksheet.
        CalcRegenPlanForPlanWkshWithLocation(Item."No.", Item2."No.", '', '');
        LineNo := DeleteRequisitionLine(Item."No."); // Return Line No. 10000.
        CarryoutActionMessageForPlanWorksheet(RequisitionLine, Item2."No.");

        // Exercise: Re-calculate Regenerative Plan.
        CalculateRegenPlanForPlanningWorksheet(Item);

        // Verify: Verify no extra empty line generated before the generated line with Item.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        Assert.AreEqual(LineNo, RequisitionLine."Line No.", RequisitionLineNoErr);
    end;

    [Test]
    [HandlerFunctions('OrderPromisingPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostInventoryPickWhenCalculateCapableToPromiseForSalesNotReserveFromILE()
    begin
        // Verify Inventory Pick can be posted successfully when the Quantity on Pick exists in Inventory,
        // the quantity that is out of stock on Sales Order reserved from Requisition Line by Order Promising.
        PostInventoryPickWhenCalculateCapableToPromiseForSales(false); // Only reserve from Requsition Line.
    end;

    [Test]
    [HandlerFunctions('ReservationHandler,OrderPromisingPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostInventoryPickWhenCalculateCapableToPromiseForSalesReserveFromILE()
    begin
        // Verify Inventory Pick can be posted successfully when the Quantity on Pick exists in Inventory and is partially reserved from ILE,
        // the quantity that is out of stock on Sales Order reserved from Requisition Line by Order Promising.
        PostInventoryPickWhenCalculateCapableToPromiseForSales(true); // Reserve from ILE and Requsition Line.
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler,MessageHandler2,PlanningErrorLogPageHandler2')]
    [Scope('OnPrem')]
    procedure CalcPlanForSubChildItemWithBOMsUnderDevelopment()
    var
        Item: array[2] of Record Item;
        ChildItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        PlanningWorksheet: TestPage "Planning Worksheet";
    begin
        // [FEATURE] [Planning Worksheet] [Calculate Regenerative Plan] [Manufacturing]
        // [SCENARIO 375502] When two items are planned for replenishment and each has not certified BOM, two errors logged for each item respectively.

        // [GIVEN] Two Items with Prod Order replenishment, each has BOM with Status = "New"
        Initialize();
        CreateItem(ChildItem, ChildItem."Reordering Policy"::"Lot-for-Lot", ChildItem."Replenishment System"::Purchase);
        CreateProductionBOM(ProductionBOMHeader, ChildItem."No.");
        CreatePurchaseOrderWithLocationAndVariant(
          PurchaseHeader, ChildItem."No.", '', '', LibraryRandom.RandDecInRange(1000, 2000, 2));

        CreateItem(Item[1], Item[1]."Reordering Policy"::"Lot-for-Lot", Item[1]."Replenishment System"::"Prod. Order");
        UpdateProductionBOMNoOnItem(Item[1], ProductionBOMHeader."No.");
        CreateItem(Item[2], Item[2]."Reordering Policy"::"Lot-for-Lot", Item[2]."Replenishment System"::"Prod. Order");
        UpdateProductionBOMNoOnItem(Item[2], ProductionBOMHeader."No.");

        // [GIVEN] Create and Post Sales Order for Item 1 and Item 2.
        CreateSalesOrder(
          SalesHeader, SalesLine, Item[1]."No.", LibraryRandom.RandDecInRange(10, 20, 2));
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        Clear(SalesHeader);
        CreateSalesOrder(
          SalesHeader, SalesLine, Item[2]."No.", LibraryRandom.RandDecInRange(10, 20, 2));
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [WHEN] Calculate regenerative Plan.
        // [THEN] Two errors are logged for each Item respectively.
        CreateRequisitionWorksheetName(RequisitionWkshName);
        LibraryVariableStorage.Enqueue(Item[1]."No.");  // for CalculatePlanPlanWkshRequestPageHandler.
        LibraryVariableStorage.Enqueue(Item[2]."No.");  // for CalculatePlanPlanWkshRequestPageHandler.
        LibraryVariableStorage.Enqueue(Item[2]."No.");  // for PlanningErrorLogPageHandler2.
        LibraryVariableStorage.Enqueue(Item[1]."No.");  // for PlanningErrorLogPageHandler2.
        CalcRegenPlanForPlanningWkshPage(PlanningWorksheet, RequisitionWkshName.Name);
        // Verification is done in PlanningErrorLogPageHandler2.
    end;

    [Test]
    [HandlerFunctions('MessageHandler2')]
    [Scope('OnPrem')]
    procedure CalcRegenPlanForThreeMaketoOrderItemsWithInventoryOfChildItem()
    var
        ParentItem: array[2] of Record Item;
        ChildItem: Record Item;
        ChildRequisitionLine: Record "Requisition Line";
        ParentItemSafetyStockQty: array[2] of Decimal;
        ParentItemDemandQty: array[2] of Decimal;
        ItemFilter: Text;
        ShipmentDate: Date;
    begin
        // [FEATURE] [Planning Worksheet] [Calculate Regenerative Plan] [Manufacturing]
        // [SCENARIO 379441] For three Items with Prod Order replenishment "Ref. Order No." must be corresponding
        Initialize();

        // [GIVEN] First and Second Parent Items have same demand dates.
        ShipmentDate := WorkDate() + LibraryRandom.RandInt(30); // up to 1 month after WORKDATE

        // [GIVEN] Child Item with Prod Order replenishment, Manufacturing Policy: Make-to-Order, zero safety stock, nonzero inventory
        CreateZeroSafetyStockItemWithInventory(ChildItem);

        // [GIVEN] First Parent Item with Prod Order replenishment, Manufacturing Policy: Make-to-Order, nonzero safety stock
        ParentItemDemandQty[1] := LibraryRandom.RandInt(20) + 1; // demand more then 1
        ParentItemSafetyStockQty[1] := ParentItemDemandQty[1] * 10; // strong greater then demand
        CreateSafetyStockBOMItemWithDemand(
          ChildItem."No.", ParentItemSafetyStockQty[1], ParentItemDemandQty[1], ShipmentDate, ParentItem[1]);

        // [GIVEN] Second Parent Item with Prod Order replenishment, Manufacturing Policy: Make-to-Order, nonzero safety stock
        ParentItemDemandQty[2] := ParentItemDemandQty[1] + LibraryRandom.RandInt(10); // demand 1 and demand 2 - different values
        ParentItemSafetyStockQty[2] := ParentItemDemandQty[2] * 10; // strong greater then demand
        CreateSafetyStockBOMItemWithDemand(
          ChildItem."No.", ParentItemSafetyStockQty[2], ParentItemDemandQty[2], ShipmentDate, ParentItem[2]);

        // [WHEN] Calculate Regenerative Plan for Planning Worksheet with three Items.
        ItemFilter := StrSubstNo('%1|%2|%3', ChildItem."No.", ParentItem[1]."No.", ParentItem[2]."No.");
        CalcRegenPlanForPlanWkshWithItemFilterAndPeriod(ItemFilter, WorkDate(), ShipmentDate);

        // [THEN] Requisition Line for Child Item corresponding to First Parent Item must exist with same Qty and same "Ref. Order No."
        FilterChildRequisitionLineByNoAndQty(ParentItem[1]."No.", ChildItem."No.", ParentItemDemandQty[1], ChildRequisitionLine);
        Assert.RecordIsNotEmpty(ChildRequisitionLine);

        // [THEN] Requisition Line for Child Item corresponding to Second Parent Item must exist with same Qty and same "Ref. Order No."
        FilterChildRequisitionLineByNoAndQty(ParentItem[2]."No.", ChildItem."No.", ParentItemDemandQty[2], ChildRequisitionLine);
        Assert.RecordIsNotEmpty(ChildRequisitionLine);
    end;

    [Test]
    [HandlerFunctions('MessageHandler2')]
    [Scope('OnPrem')]
    procedure CalcRegenPlanForProdOrderItemWithDampenerQtyAndCheckSurplus()
    var
        Item: Record Item;
        ReservationEntry: Record "Reservation Entry";
        DampenerQuantity: Integer;
        ShipmentDate: Date;
    begin
        // [FEATURE] [Planning Worksheet] [Calculate Regenerative Plan] [Manufacturing]
        // [SCENARIO 379978] For Item with Prod Order replenishment and "Dampener Quantity" Surplus must be equal to "Dampener Quantity"
        Initialize();

        // [GIVEN] Item has Dampener Quantity.
        DampenerQuantity := LibraryRandom.RandInt(10);
        CreateItemWithDampenerQuantity(Item, DampenerQuantity);

        // [GIVEN] Sales Order For Item has Production Order, "Reserved Quantity" is less on the "Dampener Quantity".
        ShipmentDate := WorkDate() + LibraryRandom.RandIntInRange(30, 60); // up to 1 - 2 months after WORKDATE
        CreateSalesOrderForItemPlanProdOrderAndReduceQtyOnDampener(Item, ShipmentDate);

        // [WHEN] Calculate Regenerative Plan for Planning Worksheet with Item.
        CalcRegenPlanForPlanWkshWithItemFilterAndPeriod(Item."No.", WorkDate(), ShipmentDate);

        // [THEN] Reservation Entry for Item contains one row with Status Surplus.
        FilterSurplusReservationEntryByItemNo(ReservationEntry, Item."No.");
        Assert.RecordCount(ReservationEntry, 1);

        // [THEN] Reservation Entry Quantity with "Reservation Status" Surplus for Item is equal to "Dampener Quantity".
        ReservationEntry.FindFirst();
        Assert.AreEqual(
          DampenerQuantity, ReservationEntry.Quantity, StrSubstNo(ReservationEntrySurplusErr, DampenerQuantity, ReservationEntry));
    end;

    [Test]
    [HandlerFunctions('MessageHandler2')]
    [Scope('OnPrem')]
    procedure CheckPlanningComponentResQtys()
    var
        Item: Record Item;
        ChildItem: Record Item;
        PlanningComponent: Record "Planning Component";
        ReservationEntry: Record "Reservation Entry";
        ShipmentDate: Date;
        ItemFilter: Text;
    begin
        // [FEATURE] [Planning Component] [Reservation]
        // [SCENARIO 380209] When Item has only Base Unit Of Measure the fields "Reserved Quantity" and "Reserved Qty. (Base)" must be equal in "Planning Component" table
        Initialize();

        // [GIVEN] Prod. Order Lot For Lot Child Item.
        CreateProdOrderLotForLotReserveAlwaysItem(ChildItem);

        // [GIVEN] Prod. Order Lot For Lot Parent Item with Child Item as BOM.
        CreateProdOrderLotForLotProductionBOMItem(Item, ChildItem."No.");

        // [GIVEN] Demand For Parent Item, Quantity = X.
        ShipmentDate := CreateSalesOrderForItemRandomQuantity(Item);

        // [WHEN] Calculate Regenerative Plan for Planning Worksheet with both Items.
        ItemFilter := StrSubstNo('%1|%2', ChildItem."No.", Item."No.");
        CalcRegenPlanForPlanWkshWithItemFilterAndPeriod(ItemFilter, ShipmentDate, ShipmentDate);

        // [THEN] Planning Component for Child Item exists.
        FindPlanningComponentByItemNoAndCALCResQtys(PlanningComponent, ChildItem."No.");

        // [THEN] Reservation Entry of type Reservation for Planning Component and Child Item exists.
        FindReservationReservationEntryByItemNoForPlanningComponent(ReservationEntry, ChildItem."No.");

        // [THEN] "Planning Component"."Reserved Qty. (Base)" is equal to -"Reservation Entry"."Quantity (Base)" = X.
        Assert.AreEqual(
          PlanningComponent."Reserved Qty. (Base)", -ReservationEntry."Quantity (Base)",
          StrSubstNo(PlanningComponentReseredQtyErr, PlanningComponent.FieldName("Reserved Qty. (Base)")));

        // [THEN] "Planning Component"."Reserved Quantity" is equal to -"Reservation Entry".Quantity = X.
        Assert.AreEqual(
          PlanningComponent."Reserved Quantity", -ReservationEntry.Quantity,
          StrSubstNo(PlanningComponentReseredQtyErr, PlanningComponent.FieldName("Reserved Quantity")));
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DeleteReqLineWithoutPlanningComponentsInWorksheetWithFilterLikeName()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        PlanningWorksheet: TestPage "Planning Worksheet";
    begin
        // [FEATURE] [Reservation]
        // [SCENARIO 204345] Requisition line can be deleted with its reservation entries from a worksheet having a filter-like name.
        Initialize();

        // [GIVEN] Item "I" with Lot-for-Lot reordering policy.
        CreateLotForLotItem(Item);

        // [GIVEN] Sales order for item "I".
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandIntInRange(10, 20));
        UpdateShipmentDateOnSalesLine(SalesLine, LibraryRandom.RandDateFromInRange(WorkDate(), 30, 60));

        // [GIVEN] Planning worksheet "W" with filter-like name "20000000..".
        CreateRequisitionWorksheetWithGivenName(RequisitionWkshName, '20000000..');

        // [GIVEN] Regenerative plan in the worksheet "W" is calculated for item "I".
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, Item."No.", Item."No.");

        // [WHEN] Delete planning line for "I".
        DeleteRequisitionLine(Item."No.");

        // [THEN] The planning line is deleted.
        FilterOnRequisitionLine(RequisitionLine, Item."No.");
        Assert.RecordIsEmpty(RequisitionLine);

        // [THEN] Reservation entries for the planning line are deleted.
        VerifyReservationEntryIsEmpty(Item."No.", DATABASE::"Requisition Line");

        // Tear down.
        RequisitionWkshName.Delete(true);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler,MessageHandler2')]
    [Scope('OnPrem')]
    procedure DeleteReqLineWithPlanningComponentsInWorksheetWithFilterLikeName()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        PlanningWorksheet: TestPage "Planning Worksheet";
        ReqLineNo: Integer;
    begin
        // [FEATURE] [Planning Component] [Reservation]
        // [SCENARIO 204345] Requisition line can be deleted with its planning components and their reservation entries from a worksheet having a filter-like name.
        Initialize();

        // [GIVEN] Production item "P" with a purchased component "C", both with Lot-for-Lot reordering policy.
        CreateProductionItem(ProdItem, CompItem);

        // [GIVEN] Sales order for item "P".
        CreateSalesOrder(SalesHeader, SalesLine, ProdItem."No.", LibraryRandom.RandIntInRange(10, 20));
        UpdateShipmentDateOnSalesLine(SalesLine, LibraryRandom.RandDateFromInRange(WorkDate(), 30, 60));

        // [GIVEN] Planning worksheet "W" with filter-like name "..20000000".
        CreateRequisitionWorksheetWithGivenName(RequisitionWkshName, '..20000000');

        // [GIVEN] Regenerative plan in the worksheet "W" is calculated for items "P" and "C".
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, ProdItem."No.", CompItem."No.");

        // [WHEN] Delete planning line for "P".
        ReqLineNo := DeleteRequisitionLine(ProdItem."No.");

        // [THEN] The planning line is deleted.
        FilterOnRequisitionLine(RequisitionLine, ProdItem."No.");
        Assert.RecordIsEmpty(RequisitionLine);

        // [THEN] Planning component "C" for the deleted planning line is deleted too.
        VerifyPlanningComponentsAreEmpty(RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name, ReqLineNo);

        // [THEN] Reservation entries for the planning component are deleted.
        VerifyReservationEntryIsEmpty(CompItem."No.", DATABASE::"Planning Component");

        // Tear down.
        RequisitionWkshName.Delete(true);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ComponentTrackingNotDeletedWhenReplanningProduction()
    var
        ProdItem: Record Item;
        CompItem: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ItemJournalLine: Record "Item Journal Line";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ReservationEntry: Record "Reservation Entry";
        LotNo: Code[10];
    begin
        // [FEATURE] [Production] [Item Tracking]
        // [SCENARIO 232555] Item tracking entries for production component should not be deleted when replanning the production order

        Initialize();

        // [GIVEN] Manufactured item "MI" and a component "CI", both with "Lot-for-Lot" reordering policy
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        CreateLotForLotItemSetup(CompItem, ProdItem);

        // [GIVEN] Component "CI" is tracked by lot nos.
        UpdateTrackingAndLotNosOnItem(CompItem, ItemTrackingCode.Code);

        LotNo := LibraryUtility.GenerateGUID();
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, CompItem."No.", '', '', LibraryRandom.RandInt(100));
        LibraryVariableStorage.Enqueue(ItemTrackingOption::AssignManualLotNo);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(ItemJournalLine."Quantity (Base)");
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create a production order and assign lot no. "L" to the component
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ProdItem."No.", 1);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", CompItem."No.");

        LibraryVariableStorage.Enqueue(ItemTrackingOption::AssignManualLotNo);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(ProdOrderComponent."Quantity (Base)");
        ProdOrderComponent.OpenItemTrackingLines();

        // [GIVEN] Calculate requisition plan from planning worksheet for the item "MI". This results in an action message suggesting to delete the order.
        LibraryPlanning.CalcRegenPlanForPlanWksh(ProdItem, WorkDate(), WorkDate());

        // [WHEN] Calculate requisition plan from planning worksheet for the component "CI"
        LibraryPlanning.CalcRegenPlanForPlanWksh(CompItem, WorkDate(), WorkDate());

        // [THEN] Reservation entry with lot no. "L" has not been deleted
        ReservationEntry.SetRange("Item No.", CompItem."No.");
        ReservationEntry.SetRange("Source Type", DATABASE::"Prod. Order Component");
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Lot No.", LotNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankLotAccumulationPeriodInterpretedAsDayLongPeriod()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Lot-for-Lot] [Lot Accumulation Period]
        // [SCENARIO 300731] When a user runs planning for a production item together with its component set up for lot-for-lot reordering policy and blank lot accumulation period, the program joins several planning lines for the component into one supply.
        Initialize();

        Qty := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] Production items "P" and "C" with "Make-to-Stock" manufacturing policy.
        // [GIVEN] Item "C" is a component of "P".
        // [GIVEN] Item "P" is set up for "Order" reordering policy and item "C" for "Lot-for-Lot".
        CreateItem(ParentItem, ParentItem."Reordering Policy"::Order, ParentItem."Replenishment System"::"Prod. Order");
        CreateItem(ChildItem, ChildItem."Reordering Policy"::"Lot-for-Lot", ChildItem."Replenishment System"::"Prod. Order");
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem."No.");
        UpdateProductionBOMNoOnItem(ParentItem, ProductionBOMHeader."No.");

        // [GIVEN] Two sales order lines make a demand for item "P".
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ParentItem."No.", Qty);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ParentItem."No.", Qty);

        // [WHEN] Calculate regenerative plan for both "P" and "C".
        Item.SetFilter("No.", '%1|%2', ParentItem."No.", ChildItem."No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate()));

        // [THEN] One requisition line is generated for item "C" with the quantity enough to cover all demand.
        SelectRequisitionLine(RequisitionLine, ChildItem."No.");
        Assert.RecordCount(RequisitionLine, 1);
        RequisitionLine.TestField(Quantity, Qty * 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LotAccPeriodNotAppliedToLowLevelItemsRelatedToDifferentMTOProdOrders()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Lot-for-Lot] [Lot Accumulation Period] [Production Order] [Make-to-Order]
        // [SCENARIO 300731] When a user runs planning for a make-to-order chain of production items, and the low-level item is set up for lot-for-lot reordering policy, the program does not join planning lines for the low-level item.
        Initialize();

        Qty := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] Production items "P" and "C" with "Make-to-Order" manufacturing policy.
        // [GIVEN] Item "C" is a component of "P".
        // [GIVEN] Item "P" is set up for "Order" reordering policy and item "C" for "Lot-for-Lot".
        CreateMTOProdItem(ParentItem, ParentItem."Reordering Policy"::Order);
        CreateMTOProdItem(ChildItem, ChildItem."Reordering Policy"::"Lot-for-Lot");
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem."No.");
        UpdateProductionBOMNoOnItem(ParentItem, ProductionBOMHeader."No.");

        // [GIVEN] Two sales order lines make a demand for item "P".
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ParentItem."No.", Qty);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ParentItem."No.", Qty);

        // [WHEN] Calculate regenerative plan for both "P" and "C".
        Item.SetFilter("No.", '%1|%2', ParentItem."No.", ChildItem."No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate()));

        // [THEN] Two requisition lines are generated for item "C", one per each production order.
        SelectRequisitionLine(RequisitionLine, ChildItem."No.");
        Assert.RecordCount(RequisitionLine, 2);
        RequisitionLine.TestField(Quantity, Qty);
        RequisitionLine.Next();
        RequisitionLine.TestField(Quantity, Qty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderReorderingPolicyRespectedWhenSupplyCreatedForIntermdTransfer()
    var
        Item: Record Item;
        TransferSKU: Record "Stockkeeping Unit";
        PurchaseSKU: Record "Stockkeeping Unit";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        NoOfSalesOrders: Integer;
        i: Integer;
    begin
        // [FEATURE] [Stockkeeping Unit] [Transfer] [Order-to-Order Binding] [Purchase]
        // [SCENARIO 333528] Reordering policy "Order" is respected when a planned supply is planned to fulfill an intermediate requisition line for transfer.
        Initialize();
        NoOfSalesOrders := LibraryRandom.RandIntInRange(2, 4);

        SelectTransferRoute(LocationRed.Code, LocationBlue.Code);

        // [GIVEN] Item with two stockeeping units -
        // [GIVEN] "SKU-T" on location "Blue" is replenished with transfer from location "Red".
        // [GIVEN] "SKU-P" on location "Red" is replenished with purchase.
        // [GIVEN] Both SKUs are set up for "Order" reordering policy.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(PurchaseSKU, LocationRed.Code, Item."No.", '');
        PurchaseSKU.Validate("Replenishment System", PurchaseSKU."Replenishment System"::Purchase);
        PurchaseSKU.Validate("Reordering Policy", PurchaseSKU."Reordering Policy"::Order);
        PurchaseSKU.Modify(true);

        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(TransferSKU, LocationBlue.Code, Item."No.", '');
        TransferSKU.Validate("Replenishment System", TransferSKU."Replenishment System"::Transfer);
        TransferSKU.Validate("Transfer-from Code", LocationRed.Code);
        TransferSKU.Validate("Reordering Policy", TransferSKU."Reordering Policy"::Order);
        TransferSKU.Modify(true);

        // [GIVEN] Create 3 sales order on location "Blue".
        for i := 1 to NoOfSalesOrders do
            CreateSalesOrderWithLocation(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandInt(10), LocationBlue.Code);

        // [WHEN] Calculate regenerative plan.
        Item.SetRecFilter();
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // [THEN] 3 planning lines are created on location "Red".
        // [THEN] Each planning line on "Red" is a supply for transfer from "Red" to "Blue" to cover the sales demand.
        RequisitionLine.SetRange("Location Code", LocationRed.Code);
        SelectRequisitionLine(RequisitionLine, Item."No.");
        Assert.RecordCount(RequisitionLine, NoOfSalesOrders);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandlerForAssignSN,QuantityToCreatePageHandler,MessageHandler2')]
    [Scope('OnPrem')]
    procedure PostingInvtPickForItemWithNonSpecificItemTrackingAndPlannedFromReqLine()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        Qty: Decimal;
    begin
        // [FEATURE] [Item Tracking] [Reservation] [Order Tracking] [Inventory Pick]
        // [SCENARIO 374737] Inventory pick for sales order tracked against requisition line can be posted. The item is set up for non-specific serial no. tracking.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(5, 10);

        // [GIVEN] Location with required pick.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Item tracking code set up for non-specific serial no. tracking of sales orders.
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false);
        ItemTrackingCode.Validate("SN Sales Outbound Tracking", true);
        ItemTrackingCode.Modify(true);

        // [GIVEN] Lot-for-lot item with just created item tracking code.
        LibraryInventory.CreateTrackedItem(Item, '', LibraryUtility.GetGlobalNoSeriesCode(), ItemTrackingCode.Code);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Modify(true);

        // [GIVEN] Post 5 pcs of the item to inventory.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, '', Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] First sales order "A" for 4 pcs.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", Qty - 1, Location.Code, WorkDate());

        // [GIVEN] Second sales order "B" for 4 pcs.
        // [GIVEN] Assign 4 serial nos.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", Qty - 1, Location.Code, LibraryRandom.RandDate(5));
        SalesLine.OpenItemTrackingLines();
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Open requisition worksheet and calculate plan.
        Item.SetRecFilter();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, LibraryPlanning.SelectRequisitionTemplateName());
        LibraryPlanning.CalculatePlanForReqWksh(
          Item, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name, WorkDate(), WorkDate() + 30);

        // [WHEN] Create and post inventory pick from the second (tracked) sales order "B".
        CreateAndPostInventoryPickFromSalesOrder(SalesHeader."No.", Location.Code);

        // [THEN] The sales order "B" has been successfully shipped.
        SalesLine.Find();
        SalesLine.TestField("Quantity Shipped", SalesLine.Quantity);
    end;

    local procedure Initialize()
    var
        RequisitionLine: Record "Requisition Line";
        ReservationEntry: Record "Reservation Entry";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Supply Planning -II");
        LibrarySetupStorage.Restore();
        RequisitionLine.DeleteAll();
        ReservationEntry.DeleteAll();
        LibraryVariableStorage.Clear();
        LibraryRandom.Init();

        LibraryApplicationArea.EnableEssentialSetup();
        LibraryPlanning.SetUseForecastOnLocations(true);
        UpdateManufacturingSetup(true);

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Supply Planning -II");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        NoSeriesSetup();
        ItemJournalSetup();
        CreateLocationSetup();
        ConsumptionJournalSetup();
        OutputJournalSetup();
        DisableManufacturingPlanningWarning();

        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        LibrarySetupStorage.Save(DATABASE::"Manufacturing Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Supply Planning -II");
    end;

    local procedure NoSeriesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NoSeries: Record "No. Series";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Validate("Posted Shipment Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify(true);

        NoSeries.Get(SalesReceivablesSetup."Credit Memo Nos.");
        NoSeries."Manual Nos." := true;
        NoSeries.Modify();
    end;

    local procedure ItemJournalSetup()
    begin
        ItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalTemplate.Modify(true);

        ItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        ItemJournalBatch.Modify(true);
    end;

    local procedure CreateLocationSetup()
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationYellow);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationRed);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationGreen.Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationSilver2.Code, false);

        CreateAndUpdateLocation(LocationGreen, true, false, false, false, true, false);  // Location Green.
        CreateAndUpdateLocation(LocationSilver, true, false, false, false, false, false);  // Location Silver: Bin Mandatory TRUE.
        CreateAndUpdateLocation(LocationSilver2, false, true, true, false, false, false);  // Location Silver2: Bin Mandatory FALSE, Require Put Away, Require Pick TRUE.
        LibraryWarehouse.CreateNumberOfBins(LocationSilver.Code, '', '', LibraryRandom.RandInt(3) + 2, false);  // Random Integer value required for Number of Bins.
    end;

    local procedure ConsumptionJournalSetup()
    begin
        ConsumptionItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(ConsumptionItemJournalTemplate, ConsumptionItemJournalTemplate.Type::Consumption);

        ConsumptionItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(
          ConsumptionItemJournalBatch, ConsumptionItemJournalTemplate.Type, ConsumptionItemJournalTemplate.Name);
    end;

    local procedure OutputJournalSetup()
    begin
        OutputItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(OutputItemJournalTemplate, OutputItemJournalTemplate.Type::Output);

        OutputItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(
          OutputItemJournalBatch, OutputItemJournalTemplate.Type, OutputItemJournalTemplate.Name);
    end;

    local procedure CreateItem(var Item: Record Item; ReorderingPolicy: Enum "Reordering Policy"; ReplenishmentSystem: Enum "Replenishment System")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);
    end;

    local procedure CreateProductionItem(var ProdItem: Record Item; var CompItem: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateLotForLotItem(CompItem);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, CompItem."No.");
        CreateProdOrderLotForLotItem(ProdItem);
        UpdateProductionBOMNoOnItem(ProdItem, ProductionBOMHeader."No.");
    end;

    local procedure CreateMTOProdItem(var Item: Record Item; ReorderingPolicy: Enum "Reordering Policy")
    begin
        CreateItem(Item, ReorderingPolicy, Item."Replenishment System"::"Prod. Order");
        Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Order");
        Item.Modify(true);
    end;

    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    local procedure CalcRegenPlanWithCombinedMPSAndMRP(IsSales: Boolean)
    var
        ChildItem: Record Item;
        Item: Record Item;
        ProductionForecastEntry: array[3] of Record "Production Forecast Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        PlanningWorksheet: TestPage "Planning Worksheet";
        OldCombinedMPSMRPCalculation: Boolean;
    begin
        // Setup: Create BOM with component.
        Initialize();
        OldCombinedMPSMRPCalculation := UpdateManufacturingSetup(true); // Combined MPS/MRP Calculation -TRUE.
        CreateLotForLotItemSetup(ChildItem, Item);

        if IsSales then
            CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandDec(10, 2))
        else
            CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", WorkDate(), false); // Boolean - FALSE, for single Forecast Entry.

        // Exercise: Calculate regenerative Plan for Planning Worksheet.
        CreateRequisitionWorksheetName(RequisitionWkshName);
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, RequisitionWkshName.Name, Item."No.", ChildItem."No.");

        // Verify: Verify MPS Order field on Requisition Line.
        VerifyMPSOrderOnRequisitionLine(Item."No.", true);
        VerifyMPSOrderOnRequisitionLine(ChildItem."No.", false);

        // Teardown.
        UpdateManufacturingSetup(OldCombinedMPSMRPCalculation);
    end;

    local procedure CreateLotForLotItem(var Item: Record Item)
    begin
        // Create Lot-for-Lot Item.
        CreateItem(Item, Item."Reordering Policy"::"Lot-for-Lot", Item."Replenishment System"::Purchase);
        Item.Validate("Include Inventory", true);
        Item.Modify(true);
    end;

    local procedure CreateLotNosAndStockkeepingUnitForItemWithTransfer(Item: Record Item; FromLocationCode: Code[10]; ToLocationCode: Code[10])
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        // Create Lot Nos for Item.
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        UpdateTrackingAndLotNosOnItem(Item, ItemTrackingCode.Code);

        // Create Stockingkeeping Unit with transfer.
        CreateSKUSetupWithTransfer(Item."No.", FromLocationCode, ToLocationCode);
    end;

    local procedure CreateSerialNosAndStockkeepingUnitForItemWithTransfer(Item: Record Item; FromLocationCode: Code[10]; ToLocationCode: Code[10])
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        // Create Serial Nos for Item.
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false);
        UpdateTrackingAndSerialNosOnItem(Item, ItemTrackingCode.Code);

        // Create Stockingkeeping Unit with transfer.
        CreateSKUSetupWithTransfer(Item."No.", FromLocationCode, ToLocationCode);
    end;

    local procedure CreateOrderItem(var Item: Record Item)
    begin
        // Create Order Item.
        CreateItem(Item, Item."Reordering Policy"::Order, Item."Replenishment System"::Purchase);
    end;

    local procedure CreateMaximumQtyItem(var Item: Record Item; MaximumInventory: Decimal)
    begin
        // Create Maximum Quantity Item.
        CreateItem(Item, Item."Reordering Policy"::"Maximum Qty.", Item."Replenishment System"::Purchase);
        Item.Validate("Reorder Point", LibraryRandom.RandDec(10, 2) + 20);  // Large Random Value required for test.
        Item.Validate("Maximum Inventory", MaximumInventory);
        Item.Validate("Minimum Order Quantity", LibraryRandom.RandDec(5, 2));  // Random Quantity less than Reorder Point Quantity.
        Item.Validate("Maximum Order Quantity", MaximumInventory + LibraryRandom.RandDec(100, 2));  // Random Quantity more than Maximum Inventory.
        Item.Modify(true);
    end;

    local procedure CreateFRQItem(var Item: Record Item)
    begin
        // Create Fixed Reorder Quantity Item.
        CreateItem(Item, Item."Reordering Policy"::"Fixed Reorder Qty.", Item."Replenishment System"::Purchase);
        Item.Validate("Safety Stock Quantity", LibraryRandom.RandInt(10));
        Item.Validate("Reorder Point", LibraryRandom.RandInt(10) + 10);  // Reorder Point more than Safety Stock Quantity or Reorder Quantity.
        Item.Validate("Reorder Quantity", LibraryRandom.RandInt(5));
        Item.Modify(true);
    end;

    local procedure CreateProductionForecastSetup(var ProductionForecastEntry: array[3] of Record "Production Forecast Entry"; ItemNo: Code[20]; ForecastDate: Date; MultipleLine: Boolean)
    var
        ProductionForecastName: Record "Production Forecast Name";
    begin
        // Using Random Value and Dates based on WORKDATE.
        LibraryManufacturing.CreateProductionForecastName(ProductionForecastName);
        LibraryPlanning.SetDemandForecast(ProductionForecastName.Name);
        CreateAndUpdateProductionForecast(
          ProductionForecastEntry[1], ProductionForecastName.Name, ForecastDate, ItemNo, LibraryRandom.RandDec(10, 2) + 100);  // Large Random Quantity Required.
        if MultipleLine then begin
            CreateAndUpdateProductionForecast(
              ProductionForecastEntry[2], ProductionForecastName.Name, GetRandomDateUsingWorkDate(1), ItemNo,
              LibraryRandom.RandDec(10, 2) + 100);  // Large Random Quantity Required.
            CreateAndUpdateProductionForecast(
              ProductionForecastEntry[3], ProductionForecastName.Name, GetRandomDateUsingWorkDate(2), ItemNo,
              LibraryRandom.RandDec(10, 2) + 100);  // Large Random Quantity Required.
        end;
    end;

    local procedure CreateAndPostInventoryPickFromSalesOrder(SalesHeaderNo: Code[20]; LocationCode: Code[10])
    var
        WhseActivityHeader: Record "Warehouse Activity Header";
    begin
        LibraryWarehouse.CreateInvtPutPickMovement(
          WhseActivityHeader."Source Document"::"Sales Order", SalesHeaderNo, false, true, false);
        FindWhseActivityHeader(WhseActivityHeader, WhseActivityHeader.Type::"Invt. Pick", LocationCode);
        LibraryWarehouse.AutoFillQtyInventoryActivity(WhseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WhseActivityHeader, false);
    end;

    local procedure UpdateManufacturingSetup(NewCombinedMPSMRPCalculation: Boolean) OldCombinedMPSMRPCalculation: Boolean
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        OldCombinedMPSMRPCalculation := InventorySetup."Combined MPS/MRP Calculation";
        InventorySetup.Validate("Combined MPS/MRP Calculation", NewCombinedMPSMRPCalculation);
        InventorySetup.Modify(true);
    end;

    local procedure UpdateLocation(RequirePick: Boolean) OriginalRequirePick: Boolean
    begin
        OriginalRequirePick := LocationSilver."Require Pick";
        LocationSilver.Validate("Require Pick", RequirePick);
        LocationSilver.Modify(true);
        exit(OriginalRequirePick);
    end;

    local procedure CreateAndUpdateProductionForecast(var ProductionForecastEntry: Record "Production Forecast Entry"; Name: Code[10]; Date: Date; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionForecastEntry(ProductionForecastEntry, Name, ItemNo, '', Date, false);
        ProductionForecastEntry.Validate("Forecast Quantity (Base)", Quantity);
        ProductionForecastEntry.Modify(true);
    end;

    local procedure CreateLotForLotItemSetup(var ChildItem: Record Item; var Item: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateLotForLotItem(ChildItem);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem."No.");
        CreateLotForLotItem(Item);
        UpdateReplenishmentSystemOnItem(Item);
        UpdateProductionBOMNoOnItem(Item, ProductionBOMHeader."No.");
        ChildItem.Find(); // Refetch ChildItem as the 'Low-Level Code' has been updated
    end;

    local procedure CreateAndCertifyProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; ItemNo: Code[20])
    begin
        CreateProductionBOM(ProductionBOMHeader, ItemNo);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; ItemNo: Code[20])
    var
        ProductionBOMLine: Record "Production BOM Line";
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", 1);
    end;

    local procedure UpdateProductionBOMNoOnItem(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure UpdateInventory(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; PostingDate: Date; Quantity: Decimal)
    begin
        CreateItemJournalLine(ItemJournalBatch, ItemJournalLine, ItemJournalLine."Entry Type"::Purchase, ItemNo, Quantity);
        ItemJournalLine.Validate("Posting Date", PostingDate);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateRequisitionWorksheetName(var RequisitionWkshName: Record "Requisition Wksh. Name")
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        SelectRequisitionTemplate(ReqWkshTemplate, ReqWkshTemplate.Type::Planning);
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
    end;

    local procedure CreateRequisitionWorksheetWithGivenName(var RequisitionWkshName: Record "Requisition Wksh. Name"; NewName: Code[10])
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        SelectRequisitionTemplate(ReqWkshTemplate, ReqWkshTemplate.Type::Planning);
        RequisitionWkshName.Init();
        RequisitionWkshName.Validate("Worksheet Template Name", ReqWkshTemplate.Name);
        RequisitionWkshName.Validate(Name, NewName);
        RequisitionWkshName.Insert(true);
    end;

    local procedure CalcRegenPlanForPlanWkshPage(var PlanningWorksheet: TestPage "Planning Worksheet"; Name: Code[10]; ItemNo: Code[20]; ItemNo2: Code[20])
    begin
        // Regenerative Planning using Page required where Forecast is used.
        LibraryVariableStorage.Enqueue(ItemNo);  // Required for CalculatePlanPlanWkshRequestPageHandler.
        LibraryVariableStorage.Enqueue(ItemNo2);  // Required for CalculatePlanPlanWkshRequestPageHandler.
        Commit();  // Required for Test.
        OpenPlanningWorksheetPage(PlanningWorksheet, Name);
        PlanningWorksheet.CalculateRegenerativePlan.Invoke();  // Open report on Handler CalculatePlanPlanWkshRequestPageHandler.
        PlanningWorksheet.OK().Invoke();
    end;

    local procedure CalcRegenPlanForPlanningWkshPage(var PlanningWorksheet: TestPage "Planning Worksheet"; Name: Code[10])
    begin
        Commit();  // Required for Test.
        OpenPlanningWorksheetPage(PlanningWorksheet, Name);
        PlanningWorksheet.CalculateRegenerativePlan.Invoke();  // Open report on Handler CalculatePlanPlanWkshRequestPageHandler.
        PlanningWorksheet.OK().Invoke();
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity)
    end;

    local procedure CreateSalesOrderWithLocation(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Status: Enum "Production Order Status"; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateAndReleaseSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesOrder(SalesHeader, SalesLine, ItemNo, LibraryRandom.RandInt(10));
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateSalesOrderForRegenPlan(var Item: Record Item; var Item2: Record Item; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Reordering Policy can be anyone except blank. Replenishment System can be anyone.
        CreateItem(Item, Item."Reordering Policy"::Order, Item."Replenishment System"::"Prod. Order");
        CreateItem(Item2, Item2."Reordering Policy"::Order, Item2."Replenishment System"::"Prod. Order");
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", Quantity);
    end;

    local procedure UpdateShipmentDateOnSalesLine(var SalesLine: Record "Sales Line"; ShipmentDate: Date)
    begin
        SalesLine.Validate("Shipment Date", ShipmentDate);
        SalesLine.Modify(true);
    end;

    local procedure SelectRequisitionTemplate(var ReqWkshTemplate: Record "Req. Wksh. Template"; Type: Enum "Req. Worksheet Template Type")
    begin
        ReqWkshTemplate.SetRange(Type, Type);
        ReqWkshTemplate.SetRange(Recurring, false);
        ReqWkshTemplate.FindFirst();
    end;

    local procedure SelectProductionOrder(var ProductionOrder: Record "Production Order"; SourceNo: Code[20]; Status: Enum "Production Order Status")
    begin
        ProductionOrder.SetRange("Source No.", SourceNo);
        ProductionOrder.SetRange(Status, Status);
        ProductionOrder.FindFirst();
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

    local procedure UpdateQuantityOnSalesLine(var SalesLine: Record "Sales Line"; Quantity: Decimal)
    begin
        SalesLine.Validate(Quantity, Quantity);
        SalesLine.Modify(true);
    end;

    local procedure CreateAndPostConsumptionJournal(ProductionOrderNo: Code[20])
    begin
        LibraryInventory.ClearItemJournal(ConsumptionItemJournalTemplate, ConsumptionItemJournalBatch);
        LibraryManufacturing.CalculateConsumption(
          ProductionOrderNo, ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
        LibraryInventory.PostItemJournalLine(ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
    end;

    local procedure CalcRegenPlanForPlanWkshWithLocation(ItemNo: Code[20]; ItemNo2: Code[20]; LocationCode: Code[10]; LocationCode2: Code[10])
    var
        Item: Record Item;
    begin
        Item.SetFilter("No.", ItemFilter, ItemNo, ItemNo2);  // Filter Required for two Items.
        Item.SetFilter("Location Filter", '%1|%2', LocationCode, LocationCode2);  // Filter Required for two Locations.
        CalculateRegenPlanForPlanningWorksheet(Item);
    end;

    local procedure SelectPlanningComponent(var PlanningComponent: Record "Planning Component"; WorksheetTemplateName: Code[10]; WorksheetBatchName: Code[10])
    begin
        PlanningComponent.SetRange("Worksheet Template Name", WorksheetTemplateName);
        PlanningComponent.SetRange("Worksheet Batch Name", WorksheetBatchName);
        PlanningComponent.FindFirst();
    end;

    local procedure CreateItemJournalLine(var ItemJournalBatch: Record "Item Journal Batch"; var ItemJournalLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Quantity);
    end;

    local procedure CreateItemJournalLineWithNewBatch(var ItemJournalBatch: Record "Item Journal Batch"; var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; Quantity: Decimal; EntryType: Enum "Item Ledger Document Type"; LocationCode: Code[10])
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalBatch."Template Type"::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        CreateItemJournalLine(ItemJournalBatch, ItemJournalLine, EntryType, ItemNo, Quantity);
        UpadteLocationAndVariantOnItemJournalLine(ItemJournalLine, LocationCode, '');
    end;

    local procedure UpdateReplenishmentSystemOnItem(var Item: Record Item)
    begin
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Modify(true);
    end;

    local procedure CalcNetChangePlanForPlanWkshForMultipleItems(ItemNo: Code[20]; ItemNo2: Code[20])
    var
        Item: Record Item;
        EndDate: Date;
    begin
        Item.SetFilter("No.", ItemFilter, ItemNo, ItemNo2);  // Filter Required for two Items.
        EndDate := GetRequiredDate(10, 30, WorkDate(), 1);  // End Date relative to Workdate.
        LibraryPlanning.CalcNetChangePlanForPlanWksh(Item, WorkDate(), EndDate, false);
    end;

    local procedure CreateAndUpdateUnitOfMeasureOnItem(var Item: Record Item)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 1);
        UpdateBaseUnitOfMeasureOnItem(Item, ItemUnitOfMeasure.Code);
    end;

    local procedure SelectProductionBOMLine(var ProductionBOMLine: Record "Production BOM Line"; ProductionBOMNo: Code[20])
    begin
        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMNo);
        ProductionBOMLine.FindFirst();
    end;

    local procedure UpdateQuantityAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        SelectProductionOrder(ProductionOrder, ItemNo, ProductionOrder.Status::"Firm Planned");
        ProductionOrder.Validate(Quantity, Quantity);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure UpdateQuantityToShipOnSalesLine(var SalesLine: Record "Sales Line"; QtytoShip: Decimal)
    begin
        SalesLine.Validate("Qty. to Ship", QtytoShip);
        SalesLine.Modify(true);
    end;

    local procedure SelectPurchaseLine(var PurchaseLine: Record "Purchase Line"; No: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst();
    end;

    local procedure OpenPlanningWorksheetPage(var PlanningWorksheet: TestPage "Planning Worksheet"; Name: Code[10])
    begin
        PlanningWorksheet.OpenEdit();
        PlanningWorksheet.CurrentWkshBatchName.SetValue(Name);
    end;

    local procedure UpdateBaseUnitOfMeasureOnItem(var Item: Record Item; BaseUnitOfMeasure: Code[10])
    begin
        Item.Get(Item."No.");
        Item.Validate("Base Unit of Measure", BaseUnitOfMeasure);
        Item.Modify(true);
    end;

    local procedure CreateLotForLotItemSKUSetup(var Item: Record Item; var ItemVariant: Record "Item Variant"; var ItemVariant2: Record "Item Variant"; LocationCode: Code[10]; LocationCode2: Code[10])
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
        StockkeepingUnit2: Record "Stockkeeping Unit";
    begin
        CreateLFLItemWithVariantAndSKU(Item, ItemVariant, StockkeepingUnit, LocationCode);
        LibraryInventory.CreateItemVariant(ItemVariant2, Item."No.");
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit2, LocationCode2, Item."No.", ItemVariant2.Code);
    end;

    local procedure UpdateLocationAndVariantOnSalesLine(var SalesLine: Record "Sales Line"; LocationCode: Code[10]; VariantCode: Code[10])
    begin
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Variant Code", VariantCode);
        SalesLine.Modify(true);
    end;

    local procedure UpdateVariantCodeOnProdOrderComponent(ItemNo: Code[20]; VariantCode: Code[10])
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange("Item No.", ItemNo);
        ProdOrderComponent.FindFirst();
        ProdOrderComponent.Validate("Variant Code", VariantCode);
        ProdOrderComponent.Modify(true);
    end;

    local procedure UpdateVariantCodeOnPlanningComponent(var PlanningComponent: Record "Planning Component"; VariantCode: Code[10])
    begin
        PlanningComponent.Validate("Variant Code", VariantCode);
        PlanningComponent.Modify(true);
    end;

    local procedure CreateAndRefreshFirmPlannedProductionOrderWithLocation(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreatePurchaseOrderWithLocationAndVariant(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Variant Code", VariantCode);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateInventoryWithLocationAndVariant(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; Quantity: Decimal; EntryType: Enum "Item Ledger Document Type"; LocationCode: Code[10]; VariantCode: Code[10])
    begin
        CreateItemJournalLine(ItemJournalBatch, ItemJournalLine, EntryType, ItemNo, Quantity);
        UpadteLocationAndVariantOnItemJournalLine(ItemJournalLine, LocationCode, VariantCode);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure UpadteLocationAndVariantOnItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; LocationCode: Code[10]; VariantCode: Code[10])
    begin
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Variant Code", VariantCode);
        ItemJournalLine.Modify(true);
    end;

    local procedure UpdateLocationOnPlanningComponent(var PlanningComponent: Record "Planning Component"; RequisitionLine: Record "Requisition Line"; LocationCode: Code[10])
    begin
        SelectPlanningComponent(PlanningComponent, RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name");
        PlanningComponent.Validate("Location Code", LocationCode);
        PlanningComponent.Modify(true);
    end;

    local procedure SelectItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    begin
        ItemJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        ItemJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        ItemJournalLine.FindFirst();
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

    local procedure CreateWorkCenter(var WorkCenter: Record "Work Center")
    begin
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
    end;

    local procedure CreateRoutingAndUpdateItem(Item: Record Item)
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
    begin
        CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.");

        // Update Routing No on Item.
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);
    end;

    local procedure CreateRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; CenterNo: Code[20])
    var
        OperationNo: Code[10];
    begin
        // Random value used so that the Next Operation No is greater than the previous Operation No.
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, CenterNo, OperationNo, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));
    end;

    local procedure CreateRoutingCommentLine(RoutingLine: Record "Routing Line")
    var
        RoutingCommentLine: Record "Routing Comment Line";
    begin
        RoutingCommentLine.Init();
        RoutingCommentLine.Validate("Routing No.", RoutingLine."Routing No.");
        RoutingCommentLine.Validate("Operation No.", RoutingLine."Operation No.");
        RoutingCommentLine.Validate(Comment, RoutingLine."Operation No.");
        RoutingCommentLine.Insert(true);
    end;

    local procedure CreateRoutingToolLine(RoutingLine: Record "Routing Line")
    var
        RoutingTool: Record "Routing Tool";
    begin
        RoutingTool.Init();
        RoutingTool.Validate("Routing No.", RoutingLine."Routing No.");
        RoutingTool.Validate("Operation No.", RoutingLine."Operation No.");
        RoutingTool.Validate("No.", RoutingLine."Operation No.");
        RoutingTool.Insert(true);
    end;

    local procedure CreateRoutingPersonnelLine(RoutingLine: Record "Routing Line")
    var
        RoutingPersonnel: Record "Routing Personnel";
    begin
        RoutingPersonnel.Init();
        RoutingPersonnel.Validate("Routing No.", RoutingLine."Routing No.");
        RoutingPersonnel.Validate("Operation No.", RoutingLine."Operation No.");
        RoutingPersonnel.Validate("No.", RoutingLine."Operation No.");
        RoutingPersonnel.Insert(true);
    end;

    local procedure CreateRoutingWithOperationAndUpdateItem(Item: Record Item; Operation: Option Comment,Tool,Personnel,QualityMeasure): Code[20]
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
        QualityMeasure: Record "Quality Measure";
        RoutingQualityMeasure: Record "Routing Quality Measure";
    begin
        CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.");
        case Operation of
            Operation::Comment:
                CreateRoutingCommentLine(RoutingLine);
            Operation::Tool:
                CreateRoutingToolLine(RoutingLine);
            Operation::Personnel:
                CreateRoutingPersonnelLine(RoutingLine);
            Operation::QualityMeasure:
                begin
                    LibraryManufacturing.CreateQualityMeasure(QualityMeasure);
                    LibraryManufacturing.CreateRoutingQualityMeasureLine(RoutingQualityMeasure, RoutingLine, QualityMeasure);
                end;
        end;
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        // Update Routing No on Item.
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);

        exit(WorkCenter."No.");
    end;

    local procedure CreateOneLineOnPlanningComponent(var PlanningComponent: Record "Planning Component"; RequisitionLine: Record "Requisition Line"; ItemNo: Code[20]; QuantityPer: Decimal)
    begin
        LibraryPlanning.CreatePlanningComponent(PlanningComponent, RequisitionLine);
        PlanningComponent.Validate("Item No.", ItemNo);
        PlanningComponent.Validate("Quantity per", QuantityPer);
        PlanningComponent.Modify(true);
    end;

    local procedure DeletePlanningRoutingLineAndCarryOutActionMessage(Item: Record Item; WorkCenterNo: Code[20])
    var
        PlanningRoutingLine: Record "Planning Routing Line";
        RequisitionLine: Record "Requisition Line";
    begin
        CalculateRegenPlanForPlanningWorksheet(Item);
        PlanningRoutingLine.SetRange("No.", WorkCenterNo);
        PlanningRoutingLine.FindFirst();
        PlanningRoutingLine.Delete();
        AcceptActionMessage(RequisitionLine, Item."No.");
        CarryoutActionMessageForPlanWorksheet(RequisitionLine, Item."No.");
    end;

    local procedure DeleteRequisitionLine(ItemNo: Code[20]): Integer
    var
        RequisitionLine: Record "Requisition Line";
    begin
        SelectRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.Delete(true);
        exit(RequisitionLine."Line No.");
    end;

    local procedure FindLastOperationNo(RoutingNo: Code[20]): Code[10]
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        if RoutingLine.FindLast() then
            exit(RoutingLine."Operation No.");
    end;

    local procedure FindWhseActivityHeader(var WhseActivityHeader: Record "Warehouse Activity Header"; WhseActivityHeaderType: Enum "Warehouse Activity Type"; LocationCode: Code[10])
    begin
        WhseActivityHeader.SetRange(Type, WhseActivityHeaderType);
        WhseActivityHeader.SetRange("Location Code", LocationCode);
        WhseActivityHeader.FindFirst();
    end;

    local procedure FindWarehouseEntry(var WarehouseEntry: Record "Warehouse Entry"; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        WarehouseEntry.SetRange("Item No.", ItemNo);
        WarehouseEntry.SetRange("Location Code", LocationCode);
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::"Negative Adjmt.");
        WarehouseEntry.FindFirst();
    end;

    local procedure UpdateCostingMethodToAverageOnItem(var Item: Record Item)
    begin
        Item.Validate("Costing Method", Item."Costing Method"::Average);
        Item.Modify(true);
    end;

    local procedure FindProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; Status: Enum "Production Order Status"; ProdOrderNo: Code[20]; ItemNo: Code[20])
    begin
        ProdOrderComponent.SetRange(Status, Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComponent.SetRange("Item No.", ItemNo);
        ProdOrderComponent.FindFirst();
    end;

    local procedure CarryoutActionMessageForPlanWorksheet(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20])
    begin
        SelectRequisitionLine(RequisitionLine, ItemNo);
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
    end;

    local procedure UpdateInventoryWithTracking(ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalBatch, ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure OpenTrackingOnProductionOrderComponent(var ProductionOrder: Record "Production Order"; ItemNo: Code[20])
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder.Status::Released, ProductionOrder."No.", ItemNo);
        ProdOrderComponent.OpenItemTrackingLines();  // Assign Tracking on Page Handler ItemTrackingPageHandler.
    end;

    local procedure GetRequiredDate(Days: Integer; IncludeAdditionalPeriod: Integer; RelativeDate: Date; SignFactor: Integer) NewDate: Date
    begin
        // Calculating a New Date relative to WorkDate.
        NewDate :=
          CalcDate('<' + Format(SignFactor * LibraryRandom.RandInt(Days) + IncludeAdditionalPeriod) + 'D>', RelativeDate);
    end;

    local procedure GetRandomDateUsingWorkDate(Month: Integer) NewDate: Date
    begin
        // Calculating a New Date relative to work date for different supply and demands.
        NewDate := CalcDate('<' + Format(Month) + 'M>', WorkDate());
    end;

    local procedure UpdateTrackingAndLotNosOnItem(var Item: Record Item; ItemTrackingCode: Code[10])
    begin
        Item.Validate("Item Tracking Code", ItemTrackingCode);  // Assign Tracking Code.
        Item.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);
    end;

    local procedure UpdateTrackingAndSerialNosOnItem(var Item: Record Item; ItemTrackingCode: Code[10])
    begin
        Item.Validate("Item Tracking Code", ItemTrackingCode); // Assign Tracking Code.
        Item.Validate("Serial Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);
    end;

    local procedure UpdateUnitOfMeasuresOnItem(var Item: Record Item)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 1);
        Item.Validate("Include Inventory", false);
        Item.Validate("Purch. Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Validate("Sales Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Modify(true);
    end;

    local procedure CreateAndUpdateLocation(var Location: Record Location; BinMandatory: Boolean; RequirePutAway: Boolean; RequirePick: Boolean; RequireReceive: Boolean; RequireShipment: Boolean; PickAccordingToFEFO: Boolean)
    begin
        LibraryWarehouse.CreateLocationWMS(Location, BinMandatory, RequirePutAway, RequirePick, RequireReceive, RequireShipment);
        Location.Validate("Pick According to FEFO", PickAccordingToFEFO);
        Location.Modify(true);
    end;

    local procedure CreateLotForLotItemSKUSetupWithTransfer(var Item: Record Item; var StockkeepingUnit: Record "Stockkeeping Unit"; var StockkeepingUnit2: Record "Stockkeeping Unit"; LocationCode: Code[10]; LocationCode2: Code[10])
    var
        ItemVariant: Record "Item Variant";
    begin
        CreateLFLItemWithVariantAndSKU(Item, ItemVariant, StockkeepingUnit, LocationCode);
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit2, LocationCode2, Item."No.", ItemVariant.Code);
        UpdateSKUReplenishmentSystem(StockkeepingUnit, StockkeepingUnit."Replenishment System"::Purchase);
        UpdateSKUReplenishmentSystem(StockkeepingUnit2, StockkeepingUnit2."Replenishment System"::Transfer);
        UpdateSKUTransferFromCode(StockkeepingUnit2, LocationCode, LocationCode2);
    end;

    local procedure UpdateSKUTransferFromCode(var StockkeepingUnit: Record "Stockkeeping Unit"; LocationCode: Code[10]; LocationCode2: Code[10])
    begin
        SelectTransferRoute(LocationCode, LocationCode2);
        StockkeepingUnit.Validate("Transfer-from Code", LocationCode);
        StockkeepingUnit.Modify(true);
    end;

    local procedure UpdateProductionForecastEntry(var ProductionForecastEntry: Record "Production Forecast Entry"; Quantity: Decimal)
    begin
        ProductionForecastEntry.Validate("Forecast Quantity (Base)", Quantity);
        ProductionForecastEntry.Modify(true);
    end;

    local procedure CreateAndUpdateProductionForecastWithLocation(var ProductionForecastEntry: Record "Production Forecast Entry"; Name: Code[10]; Date: Date; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionForecastEntry(ProductionForecastEntry, Name, ItemNo, LocationCode, Date, false);
        UpdateProductionForecastEntry(ProductionForecastEntry, Quantity);
    end;

    local procedure CreateProductionForecastSetupWithLocation(var ProductionForecastEntry: array[3] of Record "Production Forecast Entry"; ItemNo: Code[20]; LocationCode: Code[10]; ForecastDate: Date; MultipleLine: Boolean)
    var
        ProductionForecastName: Record "Production Forecast Name";
    begin
        // Using Random Value and Dates based on WORKDATE.
        LibraryManufacturing.CreateProductionForecastName(ProductionForecastName);
        LibraryPlanning.SetDemandForecast(ProductionForecastName.Name);
        CreateAndUpdateProductionForecastWithLocation(
          ProductionForecastEntry[1], ProductionForecastName.Name, ForecastDate, ItemNo, LocationCode, LibraryRandom.RandDec(10, 2) +
          100);  // Large Random Quantity Required.
        if MultipleLine then begin
            CreateAndUpdateProductionForecastWithLocation(
              ProductionForecastEntry[2], ProductionForecastName.Name, GetRandomDateUsingWorkDate(1), ItemNo, LocationCode,
              ProductionForecastEntry[1]."Forecast Quantity" + LibraryRandom.RandDec(10, 2));  // Large Random Quantity Required.
            CreateAndUpdateProductionForecastWithLocation(
              ProductionForecastEntry[3], ProductionForecastName.Name, GetRandomDateUsingWorkDate(2), ItemNo, LocationCode,
              ProductionForecastEntry[2]."Forecast Quantity" + LibraryRandom.RandDec(10, 2));  // Large Random Quantity Required.
        end;
    end;

    local procedure CreateTransferOrderWithReceiptDate(var TransferHeader: Record "Transfer Header"; ItemNo: Code[20]; TransferFrom: Code[10]; TransferTo: Code[10]; Quantity: Decimal)
    var
        ReceiptDate: Date;
    begin
        ReceiptDate := GetRequiredDate(10, 0, WorkDate(), 1);
        CreateTransferOrderWithReceiptDate(TransferHeader, ItemNo, TransferFrom, TransferTo, Quantity, ReceiptDate);
    end;

    local procedure CreateTransferOrderWithReceiptDate(var TransferHeader: Record "Transfer Header"; ItemNo: Code[20]; TransferFrom: Code[10]; TransferTo: Code[10]; Quantity: Decimal; ReceiptDate: Date)
    var
        TransferLine: Record "Transfer Line";
    begin
        SelectTransferRoute(TransferFrom, TransferTo);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, TransferFrom, TransferTo, LocationInTransit.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        TransferLine.Validate("Receipt Date", ReceiptDate);
        TransferLine.Modify(true);
    end;

    local procedure SelectTransferLine(var TransferLine: Record "Transfer Line"; DocumentNo: Code[20])
    begin
        TransferLine.SetRange("Document No.", DocumentNo);
        TransferLine.FindFirst();
    end;

    local procedure GetRequiredPeriod(Days: Integer; IncludeAdditionalPeriod: Integer): Text[30]
    begin
        exit('<' + Format(LibraryRandom.RandInt(Days) + IncludeAdditionalPeriod) + 'D>');
    end;

    local procedure UpdateSKUReplenishmentSystem(var StockkeepingUnit: Record "Stockkeeping Unit"; ReplenishmentSystem: Enum "Replenishment System")
    begin
        StockkeepingUnit.Validate("Replenishment System", ReplenishmentSystem);
        StockkeepingUnit.Modify(true);
    end;

    local procedure UpdateLotForLotSKUPlanningParameters(var StockkeepingUnit: Record "Stockkeeping Unit"; ReschedulingPeriod: Text[30]; LotAccumulationPeriod: Text[30]; DampenerPeriod: Text[30])
    var
        ReschedulingPeriod2: DateFormula;
        LotAccumulationPeriod2: DateFormula;
        DampenerPeriod2: DateFormula;
    begin
        StockkeepingUnit.Validate("Reordering Policy", StockkeepingUnit."Reordering Policy"::"Lot-for-Lot");
        Evaluate(LotAccumulationPeriod2, LotAccumulationPeriod);
        Evaluate(ReschedulingPeriod2, ReschedulingPeriod);
        Evaluate(DampenerPeriod2, DampenerPeriod);
        StockkeepingUnit.Validate("Rescheduling Period", ReschedulingPeriod2);
        StockkeepingUnit.Validate("Dampener Period", DampenerPeriod2);
        StockkeepingUnit.Validate("Lot Accumulation Period", LotAccumulationPeriod2);
        StockkeepingUnit.Validate("Include Inventory", true);
        StockkeepingUnit.Modify(true);
    end;

    local procedure UpdateTransferLinePlanningFlexibilityNone(TransferLine: Record "Transfer Line")
    begin
        TransferLine.Validate("Planning Flexibility", TransferLine."Planning Flexibility"::None);
        TransferLine.Modify(true);
    end;

    local procedure UpdateInventoryWithLocationAndBin(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    begin
        CreateItemJournalLine(ItemJournalBatch, ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure SelectTransferRoute(TransferFrom: Code[10]; TransferTo: Code[10])
    var
        TransferRoute: Record "Transfer Route";
    begin
        TransferRoute.SetRange("Transfer-from Code", TransferFrom);
        TransferRoute.SetRange("Transfer-to Code", TransferTo);

        // If Transfer Not Found then Create it.
        if not TransferRoute.FindFirst() then begin
            LibraryWarehouse.CreateTransferRoute(TransferRoute, TransferFrom, TransferTo);
            TransferRoute.Validate("In-Transit Code", LocationInTransit.Code);
            TransferRoute.Modify(true);
        end;
    end;

    local procedure AreSameMessages(Message: Text[1024]; Message2: Text[1024]): Boolean
    begin
        exit(StrPos(Message, Message2) > 0);
    end;

    local procedure CreateSalesOrderWithPurchasingCode(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        Purchasing: Record Purchasing;
    begin
        CreatePurchasingCodeWithDropShipment(Purchasing);
        CreateSalesOrder(SalesHeader, SalesLine, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Purchasing Code", Purchasing.Code);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchasingCodeWithDropShipment(var Purchasing: Record Purchasing)
    begin
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Drop Shipment", true);
        Purchasing.Modify(true);
    end;

    local procedure GetSalesOrderOnRequisitionWkshtAndCarryOutActionMsg(var SalesLine: Record "Sales Line"; var RequisitionLine: Record "Requisition Line")
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RetrieveDimensionsFrom: Option Item,"Sales Line";
    begin
        CreateRequisitionWorksheetName(RequisitionWkshName);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        LibraryPlanning.GetSalesOrders(SalesLine, RequisitionLine, RetrieveDimensionsFrom::"Sales Line");
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');
    end;

    local procedure UpdateQuantityOnPurchaseLine(ItemNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        SelectPurchaseLine(PurchaseLine, ItemNo);
        PurchaseLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure ReduceQuantityOnPurchaseLine(ItemNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        SelectPurchaseLine(PurchaseLine, ItemNo);
        PurchaseLine.Validate(Quantity, LibraryRandom.RandDec(Round(PurchaseLine.Quantity, 1, '<'), 2));
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateBinOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; LocationCode: Code[10]; BinCode: Code[20])
    begin
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Bin Code", BinCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CalcPlanAndCarryOutActionMessage(var Item: Record Item; StartingDate: Date; EndingDate: Date)
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
    begin
        CalculatePlanForRequisitionWorksheet(RequisitionWkshName, Item."No.", Item."No.", StartingDate, EndingDate);
        AcceptActionMessage(RequisitionLine, Item."No.");
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');
    end;

    local procedure AcceptActionMessage(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20])
    begin
        SelectRequisitionLine(RequisitionLine, ItemNo);
        repeat
            RequisitionLine.Validate("Accept Action Message", true);
            RequisitionLine.Modify(true);
        until RequisitionLine.Next() = 0;
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure CarryOutPurchaseOrderForDropShipmentOnReqWksh(var Item: Record Item; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        RequisitionLine: Record "Requisition Line";
    begin
        CreateOrderItem(Item);
        CreateSalesOrderWithPurchasingCode(SalesHeader, SalesLine, Item."No.", LocationSilver.Code, LibraryRandom.RandDec(10, 2));
        GetSalesOrderOnRequisitionWkshtAndCarryOutActionMsg(SalesLine, RequisitionLine);  // Drop Shipment On Requisition Line.
    end;

    local procedure CreateStockkeepingUnitForMaximumQtyItem(var Item: Record Item; var ItemVariant: Record "Item Variant"; LocationCode: Code[10])
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        CreateMaximumQtyItem(Item, LibraryRandom.RandDec(50, 2) + 50);  // Large Quantity required for Maximum Inventory.
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, LocationCode, Item."No.", ItemVariant.Code);
    end;

    local procedure CalculatePlanForRequisitionWorksheet(var RequisitionWkshName: Record "Requisition Wksh. Name"; ItemNo: Code[20]; ItemNo2: Code[20]; StartDate: Date; EndDate: Date)
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        Item: Record Item;
    begin
        Item.SetFilter("No.", ItemFilter, ItemNo, ItemNo2);  // Filter Required for two Items.
        SelectRequisitionTemplate(ReqWkshTemplate, ReqWkshTemplate.Type::"Req.");
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        LibraryPlanning.CalculatePlanForReqWksh(Item, ReqWkshTemplate.Name, RequisitionWkshName.Name, StartDate, EndDate);
    end;

    local procedure UpdateItemCategoryCode(var Item: Record Item)
    var
        ItemCategory: Record "Item Category";
    begin
        LibraryInventory.CreateItemCategory(ItemCategory);
        Item.Validate("Item Category Code", ItemCategory.Code);
        Item.Modify(true);
    end;

    local procedure CreateLFLItemWithVariantAndSKU(var Item: Record Item; var ItemVariant: Record "Item Variant"; var StockkeepingUnit: Record "Stockkeeping Unit"; LocationCode: Code[10])
    begin
        CreateLotForLotItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, LocationCode, Item."No.", ItemVariant.Code);
    end;

    local procedure UpdateSalesReceivablesSetup(var OldStockoutWarning: Boolean; var OldCreditWarnings: Option; NewStockoutWarning: Boolean; NewCreditWarnings: Option)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        OldStockoutWarning := SalesReceivablesSetup."Stockout Warning";
        OldCreditWarnings := SalesReceivablesSetup."Credit Warnings";
        SalesReceivablesSetup.Validate("Stockout Warning", NewStockoutWarning);
        SalesReceivablesSetup.Validate("Credit Warnings", NewCreditWarnings);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure CreateSalesOrderFromBlanketOrder(ItemNo: Code[20]; QuantityToShip: Decimal)
    var
        SalesOrderHeader: Record "Sales Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        BlanketSalesOrderToOrder: Codeunit "Blanket Sales Order to Order";
    begin
        // Create Blanket Order and create Sales Order from Blanket Order.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order", '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2) + 10);  // Large random Quantity required.
        UpdateQuantityToShipOnSalesLine(SalesLine, QuantityToShip);  // Quantity to Ship less than Sales Line Quantity.
        BlanketSalesOrderToOrder.Run(SalesHeader);
        BlanketSalesOrderToOrder.GetSalesOrderHeader(SalesOrderHeader);
    end;

    local procedure CalculateRegenPlanForPlanningWorksheet(var Item: Record Item)
    var
        EndDate: Date;
    begin
        EndDate := GetRequiredDate(10, 30, WorkDate(), 1);  // End Date relative to Workdate.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), EndDate);
    end;

    local procedure AssignTrackingAndPostPurchaseWithReducedQuantity(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        ReduceQuantityOnPurchaseLine(ItemNo);
        SelectPurchaseLine(PurchaseLine, ItemNo);
        PurchaseLine.OpenItemTrackingLines();  // Assign Tracking on Page Handler ItemTrackingPageHandler.
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure AssignTrackingAndPostPurchase(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        SelectPurchaseLine(PurchaseLine, ItemNo);
        PurchaseLine.OpenItemTrackingLines(); // Assign Tracking on Page Handler ItemTrackingPageHandler.
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure CalcRegenPlanAndCarryOutActionMessage(var Item: Record Item)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        CalculateRegenPlanForPlanningWorksheet(Item);
        AcceptActionMessage(RequisitionLine, Item."No.");
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
    end;

    local procedure UpdateSKUSafetyStockQuantity(var StockkeepingUnit: Record "Stockkeeping Unit"; SafetyStockQuantity: Decimal)
    begin
        StockkeepingUnit.Validate("Safety Stock Quantity", SafetyStockQuantity);
        StockkeepingUnit.Modify(true);
    end;

    local procedure UpdateItemSafetyStockQuantityAndLeadTimeCalculation(var Item: Record Item; LeadTimeCalculation: Text[30])
    var
        LeadTimeCalculation2: DateFormula;
    begin
        Evaluate(LeadTimeCalculation2, LeadTimeCalculation);
        Item.Validate("Safety Stock Quantity", LibraryRandom.RandDec(10, 2));
        Item.Validate("Lead Time Calculation", LeadTimeCalculation2);
        Item.Modify(true);
    end;

    local procedure UpdateSalesLinePlannedDeliveryDate(var SalesLine: Record "Sales Line"; PlannedDeliveryDate: Date)
    begin
        SalesLine.Validate("Planned Delivery Date", PlannedDeliveryDate);
        SalesLine.Modify(true);
    end;

    local procedure SelectProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProdOrderNo: Code[20]; Status: Enum "Production Order Status")
    begin
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.SetRange(Status, Status);
        ProdOrderLine.FindFirst();
    end;

    local procedure CreateProdOrderComponent(ProductionOrder: Record "Production Order"; var ProdOrderComponent: Record "Prod. Order Component"; ItemNo: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        SelectProdOrderLine(ProdOrderLine, ProductionOrder."No.", ProductionOrder.Status);
        LibraryManufacturing.CreateProductionOrderComponent(
          ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", ProdOrderLine."Line No.");
        ProdOrderComponent.Validate("Item No.", ItemNo);
        ProdOrderComponent.Validate("Quantity per", LibraryRandom.RandDec(5, 2));
        ProdOrderComponent.Modify(true);
    end;

    local procedure CreateAndPostPurchaseWithLocation(ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseOrderWithLocationAndVariant(PurchaseHeader, ItemNo, LocationCode, '', Quantity);
        PostPurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateSKUSetupWithTransfer(ItemNo: Code[20]; LocationCode: Code[10]; LocationCode2: Code[10])
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
        StockkeepingUnit2: Record "Stockkeeping Unit";
    begin
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, LocationCode, ItemNo, '');
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit2, LocationCode2, ItemNo, '');
        UpdateSKUTransferFromCode(StockkeepingUnit2, LocationCode, LocationCode2);
        UpdateSKUReplenishmentSystem(StockkeepingUnit2, StockkeepingUnit2."Replenishment System"::Transfer);
    end;

    local procedure OpenOrderPromisingPage(SalesHeaderNo: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenView();
        SalesOrder.FILTER.SetFilter("No.", SalesHeaderNo);
        SalesOrder.SalesLines.OrderPromising.Invoke();  // Open OrderPromisingPageHandler.
    end;

    local procedure PostPurchaseDocument(PurchaseHeader: Record "Purchase Header")
    begin
        // Update Vendor Invoice No on Purchase Header.
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");  // Get Latest Instance, Important for Test.
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure SelectReferenceOrderType(var Item: Record Item; var RequisitionLine: Record "Requisition Line") RefOrderType: Enum "Requisition Ref. Order Type"
    begin
        if Item."Replenishment System" = Item."Replenishment System"::Purchase then
            RefOrderType := RequisitionLine."Ref. Order Type"::Purchase
        else
            RefOrderType := RequisitionLine."Ref. Order Type"::"Prod. Order";
    end;

    local procedure PostCarriedOutPurchaseOrder(ItemNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseLine."Document No.");
        PurchaseHeader.Validate(
          "Vendor Invoice No.", LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Invoice No."), DATABASE::"Purchase Header"));
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure PostTransferHeader(TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header")
    var
        Bin: Record Bin;
    begin
        Bin.SetRange("Location Code", TransferHeader."Transfer-to Code");
        Bin.FindFirst();
        TransferLine.Validate("Transfer-To Bin Code", Bin.Code);
        TransferLine.Modify(true);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);
    end;

    local procedure PostInventoryPickWhenCalculateCapableToPromiseForSales(ReserveFromILE: Boolean)
    var
        Item: Record Item;
        Bin: Record Bin;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemJournalLine: Record "Item Journal Line";
        OriginalRequirePick: Boolean;
    begin
        // Setup: Create a Item. Update Item inventory with Bin.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.FindBin(Bin, LocationSilver.Code, '', 1); // Find Bin of Index 1.
        OriginalRequirePick := UpdateLocation(true);
        UpdateInventoryWithLocationAndBin(
          ItemJournalLine, Item."No.", LocationSilver.Code, Bin.Code, LibraryRandom.RandIntInRange(10, 20));

        // Create Sales Order with Location. Open Order Promising Lines Page and Invoke Capable to Promise
        // and Accept to create Requisition Worksheet Line by OrderPromisingPageHandler.
        CreateSalesOrderWithLocation(
          SalesHeader, SalesLine, Item."No.", ItemJournalLine.Quantity - LibraryRandom.RandInt(5), LocationSilver.Code);
        if ReserveFromILE then
            SalesLine.ShowReservation(); // Partial reserved from ILE.

        // Reserved from Requisition Line.
        UpdateQuantityOnSalesLine(SalesLine, ItemJournalLine.Quantity + LibraryRandom.RandInt(5));
        OpenOrderPromisingPage(SalesLine."Document No.");
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // Exercise: Create Inventory pick from Sales Order.
        LibraryVariableStorage.Enqueue(InventoryPickCreatedMsg); // Required inside MessageHandler.
        CreateAndPostInventoryPickFromSalesOrder(SalesHeader."No.", LocationSilver.Code);

        // Verify: Verify Inventory Pick posted successfully.
        // Verify Reservation Entry is empty when reserved from ILE.
        VerifyWarehouseEntry(Item."No.", LocationSilver.Code, Bin.Code, -ItemJournalLine.Quantity);
        if ReserveFromILE then
            VerifyReservationEntryIsEmpty(Item."No.", DATABASE::"Item Ledger Entry");

        // Tear down.
        UpdateLocation(OriginalRequirePick);
    end;

    local procedure FindAndPostTransferHeaderByItemNo(var TransferHeader: Record "Transfer Header"; ItemNo: Code[20])
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SetRange("Item No.", ItemNo);
        TransferLine.FindFirst();
        TransferHeader.SetRange("No.", TransferLine."Document No.");
        TransferHeader.FindFirst();
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);
    end;

    local procedure CreateProdOrderLotForLotItem(var Item: Record Item)
    begin
        CreateLotForLotItem(Item);
        UpdateReplenishmentSystemOnItem(Item);
        // "Replenishment System"::"Prod. Order"
        Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking Only");
        Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Order");
        Item.Modify(true);
    end;

    local procedure CreateSafetyStockBOMItemWithDemand(ChildItemNo: Code[20]; SafetyStockQuantity: Decimal; DemandQuantity: Decimal; ShipmentDate: Date; var Item: Record Item)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateProdOrderLotForLotProductionBOMItem(Item, ChildItemNo);
        UpdateItemIncludeInventoryAndSafetyStockQuantity(Item, true, SafetyStockQuantity);
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", DemandQuantity);
        UpdateShipmentDateOnSalesLine(SalesLine, ShipmentDate);
    end;

    local procedure CreateZeroSafetyStockItemWithInventory(var Item: Record Item)
    begin
        CreateProdOrderLotForLotItem(Item);
        UpdateItemIncludeInventoryAndSafetyStockQuantity(Item, true, 0);
        CreateAndPostPurchaseWithLocation(Item."No.", '', LibraryRandom.RandInt(50)); // blank location
    end;

    local procedure CreateProdOrderLotForLotProductionBOMItem(var Item: Record Item; ChildItemNo: Code[20])
    var
        ParentProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateProdOrderLotForLotItem(Item);
        CreateAndCertifyProductionBOM(ParentProductionBOMHeader, ChildItemNo);
        UpdateProductionBOMNoOnItem(Item, ParentProductionBOMHeader."No.");
    end;

    local procedure UpdateItemIncludeInventoryAndSafetyStockQuantity(var Item: Record Item; IncludeInventory: Boolean; SafetyStockQuantity: Decimal)
    begin
        Item.Validate("Include Inventory", IncludeInventory);
        Item.Validate("Safety Stock Quantity", SafetyStockQuantity);
        Item.Modify(true);
    end;

    local procedure CalcRegenPlanForPlanWkshWithItemFilterAndPeriod(ItemFilter: Text; FromDate: Date; ToDate: Date)
    var
        Item: Record Item;
    begin
        Item.SetFilter("No.", ItemFilter);
        LibraryPlanning.CalcRegenPlanForPlanWkshPlanningParams(Item, FromDate, ToDate, true);
    end;

    local procedure GetParentRequisitionLineByNoAndQtyBase(ItemNo: Code[20]; Qty: Decimal; var RequisitionLine: Record "Requisition Line")
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.SetRange(Quantity, Qty);
        RequisitionLine.FindFirst();
    end;

    local procedure FilterChildRequisitionLineByNoAndQty(ParentItemNo: Code[20]; ChildItemNo: Code[20]; Qty: Decimal; var ChildRequisitionLine: Record "Requisition Line")
    var
        ParentRequisitionLine: Record "Requisition Line";
    begin
        GetParentRequisitionLineByNoAndQtyBase(ParentItemNo, Qty, ParentRequisitionLine);
        ChildRequisitionLine.SetRange("Worksheet Template Name", ParentRequisitionLine."Worksheet Template Name");
        ChildRequisitionLine.SetRange("Journal Batch Name", ParentRequisitionLine."Journal Batch Name");
        ChildRequisitionLine.SetFilter("Line No.", '<>%1', ParentRequisitionLine."Line No.");
        ChildRequisitionLine.SetRange(Type, ChildRequisitionLine.Type::Item);
        ChildRequisitionLine.SetRange("No.", ChildItemNo);
        ChildRequisitionLine.SetRange("Ref. Order No.", ParentRequisitionLine."Ref. Order No.");
        ChildRequisitionLine.SetRange(Quantity, ParentRequisitionLine.Quantity);
    end;

    local procedure CreateItemWithDampenerQuantity(var Item: Record Item; DampenerQuantity: Decimal): Code[20]
    begin
        CreateProdOrderLotForLotItem(Item);
        Item.Validate("Dampener Quantity", DampenerQuantity);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateSalesOrderForItemPlanProdOrderAndReduceQtyOnDampener(Item: Record Item; ShipmentDate: Date)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesOrderForItemQuantityMoreThenDampener(SalesHeader, SalesLine, Item, ShipmentDate);
        LibraryManufacturing.CreateProductionOrderFromSalesOrder(
            SalesHeader, "Production Order Status"::Released, "Create Production Order Type"::ItemOrder);
        SalesLine.Validate(Quantity, SalesLine.Quantity - Item."Dampener Quantity");
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrderForItemQuantityMoreThenDampener(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Item: Record Item; ShipmentDate: Date)
    var
        Quantity: Decimal;
    begin
        Quantity := LibraryRandom.RandInt(20);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Quantity + Item."Dampener Quantity");
        SalesLine.Validate("Shipment Date", ShipmentDate);
        SalesLine.Modify(true);
    end;

    local procedure FilterSurplusReservationEntryByItemNo(var ReservationEntry: Record "Reservation Entry"; ItemNo: Code[20])
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
    end;

    local procedure DisableManufacturingPlanningWarning()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Planning Warning", false);
        ManufacturingSetup.Modify(true);
    end;

    local procedure CreateProdOrderLotForLotReserveAlwaysItem(var Item: Record Item)
    begin
        CreateProdOrderLotForLotItem(Item);
        Item.Validate(Reserve, Item.Reserve::Always);
        Item.Modify(true);
    end;

    local procedure CreateSalesOrderForItemRandomQuantity(Item: Record Item): Date
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(2000));
        exit(SalesLine."Shipment Date");
    end;

    local procedure FindPlanningComponentByItemNoAndCALCResQtys(var PlanningComponent: Record "Planning Component"; ItemNo: Code[20])
    begin
        PlanningComponent.SetRange("Item No.", ItemNo);
        PlanningComponent.FindFirst();
        PlanningComponent.CalcFields("Reserved Qty. (Base)", "Reserved Quantity");
    end;

    local procedure FindReservationReservationEntryByItemNoForPlanningComponent(var ReservationEntry: Record "Reservation Entry"; ItemNo: Code[20])
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
        ReservationEntry.SetRange("Source Type", DATABASE::"Planning Component");
        ReservationEntry.FindFirst();
    end;

    local procedure VerifyPlanningComponentsAreEmpty(ReqWkshtTemplateName: Code[10]; ReqWkshtName: Code[10]; ReqWkshtLineNo: Integer)
    var
        PlanningComponent: Record "Planning Component";
    begin
        PlanningComponent.Init();
        PlanningComponent.SetRange("Worksheet Template Name", ReqWkshtTemplateName);
        PlanningComponent.SetRange("Worksheet Batch Name", ReqWkshtName);
        PlanningComponent.SetRange("Worksheet Line No.", ReqWkshtLineNo);
        Assert.RecordIsEmpty(PlanningComponent);
    end;

    local procedure VerifyRequisitionLineWithDueDateForItem(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20]; RefOrderType: Enum "Requisition Ref. Order Type"; DueDate: Date)
    begin
        RequisitionLine.SetRange("Due Date", DueDate);
        RequisitionLine.FindFirst();
        RequisitionLine.TestField("No.", ItemNo);
        RequisitionLine.TestField("Ref. Order Type", RefOrderType);
    end;

    local procedure VerifyRequisitionLineQuantityAndActionMessage(var RequisitionLine: Record "Requisition Line"; Quantity: Decimal; OriginalQuantity: Decimal; ActionMessage: Enum "Action Message Type")
    begin
        RequisitionLine.TestField(Quantity, Quantity);
        RequisitionLine.TestField("Original Quantity", OriginalQuantity);
        RequisitionLine.TestField("Action Message", ActionMessage);
    end;

    local procedure VerifyRequisitionLineWithItem(Item: Record Item; ActionMessage: Enum "Action Message Type"; Quantity: Decimal; OriginalQuantity: Decimal; LocationCode: Code[10]; VariantCode: Code[10])
    var
        RequisitionLine: Record "Requisition Line";
        RefOrderType: Enum "Requisition Ref. Order Type";
    begin
        RefOrderType := SelectReferenceOrderType(Item, RequisitionLine);
        SelectRequisitionLine(RequisitionLine, Item."No.");
        RequisitionLine.TestField("Variant Code", VariantCode);
        RequisitionLine.TestField("Unit of Measure Code", Item."Base Unit of Measure");
        RequisitionLine.TestField("Ref. Order Type", RefOrderType);
        RequisitionLine.TestField("Location Code", LocationCode);
        VerifyRequisitionLineQuantityAndActionMessage(RequisitionLine, Quantity, OriginalQuantity, ActionMessage);
    end;

    local procedure VerifyRequisitionLineWithDueDate(var Item: Record Item; ActionMessage: Enum "Action Message Type"; Quantity: Decimal; OriginalQuantity: Decimal; DueDate: Date)
    var
        RequisitionLine: Record "Requisition Line";
        RefOrderType: Enum "Requisition Ref. Order Type";
    begin
        RefOrderType := SelectReferenceOrderType(Item, RequisitionLine);
        VerifyRequisitionLineWithDueDateForItem(RequisitionLine, Item."No.", RefOrderType, DueDate);
        VerifyRequisitionLineQuantityAndActionMessage(RequisitionLine, Quantity, OriginalQuantity, ActionMessage);
    end;

    local procedure VerifyRequisitionLineWithDueDateForTransfer(ActionMessage: Enum "Action Message Type"; Quantity: Decimal; OriginalQuantity: Decimal; DueDate: Date; LocationCode: Code[10])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("Due Date", DueDate);
        RequisitionLine.FindFirst();
        RequisitionLine.TestField("Ref. Order Type", RequisitionLine."Ref. Order Type"::Transfer);
        RequisitionLine.TestField("Location Code", LocationCode);
        VerifyRequisitionLineQuantityAndActionMessage(RequisitionLine, Quantity, OriginalQuantity, ActionMessage);
    end;

    local procedure VerifyRequisitionLineForUnitOfMeasure(var Item: Record Item; UnitOfMeasureCode: Code[10]; ActionMessage: Enum "Action Message Type"; Quantity: Decimal; OriginalQuantity: Decimal; DueDate: Date)
    var
        RequisitionLine: Record "Requisition Line";
        RefOrderType: Enum "Requisition Ref. Order Type";
    begin
        RefOrderType := SelectReferenceOrderType(Item, RequisitionLine);
        VerifyRequisitionLineWithDueDateForItem(RequisitionLine, Item."No.", RefOrderType, DueDate);
        VerifyRequisitionLineQuantityAndActionMessage(RequisitionLine, Quantity, OriginalQuantity, ActionMessage);
        RequisitionLine.TestField("Unit of Measure Code", UnitOfMeasureCode);
    end;

    local procedure VerifyRequisitionLineForLocationAndVariant(var Item: Record Item; ActionMessage: Enum "Action Message Type"; Quantity: Decimal; OriginalQuantity: Decimal; DueDate: Date; LocationCode: Code[10]; VariantCode: Code[10])
    var
        RequisitionLine: Record "Requisition Line";
        RefOrderType: Enum "Requisition Ref. Order Type";
    begin
        RefOrderType := SelectReferenceOrderType(Item, RequisitionLine);
        VerifyRequisitionLineWithDueDateForItem(RequisitionLine, Item."No.", RefOrderType, DueDate);
        VerifyRequisitionLineQuantityAndActionMessage(RequisitionLine, Quantity, OriginalQuantity, ActionMessage);
        RequisitionLine.TestField("Location Code", LocationCode);
        RequisitionLine.TestField("Variant Code", VariantCode);
    end;

    local procedure VerifyRequisitionLineWithVariant(ActionMessage: Enum "Action Message Type"; Quantity: Decimal; OriginalQuantity: Decimal; LocationCode: Code[10]; VariantCode: Code[10])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("Variant Code", VariantCode);
        RequisitionLine.FindFirst();
        RequisitionLine.TestField("Location Code", LocationCode);
        VerifyRequisitionLineQuantityAndActionMessage(RequisitionLine, Quantity, OriginalQuantity, ActionMessage);
    end;

    local procedure VerifyMPSOrderOnRequisitionLine(ItemNo: Code[20]; IsMPSOrder: Boolean)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.FindFirst();
        RequisitionLine.TestField("MPS Order", IsMPSOrder);
    end;

    local procedure VerifyRequisitionLineWithAddedItem(RequisitionLine: Record "Requisition Line"; ItemNo: Code[20]; Qty: Decimal)
    begin
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.FindFirst();
        RequisitionLine.TestField(Quantity, Qty);
    end;

    local procedure VerifyBinContent(SalesLine: Record "Sales Line"; BinCode: Code[20])
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.SetRange("Item No.", SalesLine."No.");
        BinContent.SetRange("Location Code", SalesLine."Location Code");
        BinContent.FindFirst();
        BinContent.TestField("Bin Code", BinCode);
    end;

    local procedure VerifyTransferLine(ItemNo: Code[20]; TransferFromCode: Code[10]; Quantity: Decimal)
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SetRange(Status, TransferLine.Status::Open);
        TransferLine.SetRange("Item No.", ItemNo);
        TransferLine.FindFirst();
        TransferLine.TestField("Transfer-from Code", TransferFromCode);
        TransferLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyTransferShipment(ItemNo: Code[20]; TransferFromCode: Code[10]; TransferToCode: Code[10])
    var
        TransferShipmentLine: Record "Transfer Shipment Line";
    begin
        TransferShipmentLine.SetRange("Item No.", ItemNo);
        TransferShipmentLine.FindFirst();
        TransferShipmentLine.TestField("Transfer-from Code", TransferFromCode);
        TransferShipmentLine.TestField("Transfer-to Code", TransferToCode);
    end;

    local procedure VerifyProductionOrderWithRefresh(var ProductionOrder: Record "Production Order"; ItemNo: Code[20])
    begin
        ProductionOrder.SetRange(Status, ProductionOrder.Status::"Firm Planned");
        ProductionOrder.SetRange("Source No.", ItemNo);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false); // Calculate Lines, Routings & Component Need are TRUE
    end;

    local procedure VerifyItemInventory(var Item: Record Item; InventoryQty: Decimal)
    begin
        Item.CalcFields(Inventory);
        Item.TestField(Inventory, InventoryQty);
    end;

    local procedure VerifyShipAndStatusFieldOnSalesHeader(ActualShip: Boolean; ActualStatus: Enum "Sales Document Status"; ExpectedShip: Boolean; ExpectedStatus: Enum "Sales Document Status")
    begin
        Assert.AreEqual(ExpectedShip, ActualShip, ShipFieldErr);
        Assert.AreEqual(ExpectedStatus, ActualStatus, SalesOrderStatusErr);
    end;

    local procedure VerifyReceiveAndStatusFieldOnPurchaseHeader(ActualReceive: Boolean; ActualStatus: Enum "Purchase Document Status"; ExpectedReceive: Boolean; ExpectedStatus: Enum "Purchase Document Status")
    begin
        Assert.AreEqual(ExpectedReceive, ActualReceive, ReceiveFieldErr);
        Assert.AreEqual(ExpectedStatus, ActualStatus, PurchaseOrderStatusErr);
    end;

    local procedure VerifyWarehouseEntry(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        FindWarehouseEntry(WarehouseEntry, ItemNo, LocationCode);
        Assert.AreEqual(BinCode, WarehouseEntry."Bin Code", BinCodeInWarehouseEntryErr);
        Assert.AreEqual(Quantity, WarehouseEntry.Quantity, QuantityInWarehouseEntryErr);
    end;

    local procedure VerifyReservationEntryIsEmpty(ItemNo: Code[20]; SourceType: Integer)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Source Type", SourceType);
        Assert.IsTrue(ReservationEntry.IsEmpty, ReservationEntryErr);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculatePlanPlanWkshRequestPageHandler(var CalculatePlanPlanWksh: TestRequestPage "Calculate Plan - Plan. Wksh.")
    var
        ItemNo: Variant;
        ItemNo2: Variant;
    begin
        // Calculate Regenerative Plan using page. Required where Forecast is used.
        LibraryVariableStorage.Dequeue(ItemNo);
        LibraryVariableStorage.Dequeue(ItemNo2);
        CalculatePlanPlanWksh.Item.SetFilter("No.", StrSubstNo(ItemFilter, ItemNo, ItemNo2));
        CalculatePlanPlanWksh.MPS.SetValue(true);
        CalculatePlanPlanWksh.StartingDate.SetValue(WorkDate());
        CalculatePlanPlanWksh.EndingDate.SetValue(GetRandomDateUsingWorkDate(90));
        CalculatePlanPlanWksh.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Assign Lot No.".Invoke();  // Assign Lot No.
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandlerForAssignSN(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Assign Serial No.".Invoke(); // Assign Serial No.
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure QuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        TrackingQuantity: Variant;
        TrackingOption: Option;
    begin
        TrackingOption := LibraryVariableStorage.DequeueInteger();
        case TrackingOption of
            ItemTrackingOption::AssignLotNo:
                ItemTrackingLines."Assign Lot No.".Invoke();
            ItemTrackingOption::AssignManualLotNo:
                begin
                    ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                end;
            ItemTrackingOption::VerifyTrackingQty:
                begin
                    // Verify Quantity(Base) on Tracking Line.
                    ItemTrackingLines.First();
                    LibraryVariableStorage.Dequeue(TrackingQuantity);
                    ItemTrackingLines."Quantity (Base)".AssertEquals(TrackingQuantity);
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PlanningErrorLogPageHandler(var PlanningErrorLog: TestPage "Planning Error Log")
    begin
        PlanningErrorLog.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PlanningErrorLogPageHandler2(var PlanningErrorLog: TestPage "Planning Error Log")
    begin
        PlanningErrorLog.Last();
        repeat
            PlanningErrorLog."Item No.".AssertEquals(LibraryVariableStorage.DequeueText());
        until not PlanningErrorLog.Previous();
        Assert.AreEqual(0, LibraryVariableStorage.Length(), NumberOfErrorsErr);
        PlanningErrorLog.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OrderPromisingPageHandler(var OrderPromisingLines: TestPage "Order Promising Lines")
    begin
        OrderPromisingLines.CapableToPromise.Invoke();  // Capable To Promise will generate a new Requisition Line for the demand.
        OrderPromisingLines.AcceptButton.Invoke();
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
    procedure MessageHandler2(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.IsTrue(AreSameMessages(ConfirmMessage, ExpectedMessage), ConfirmMessage);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerAnyMessage(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Auto Reserve".Invoke();
    end;
}
