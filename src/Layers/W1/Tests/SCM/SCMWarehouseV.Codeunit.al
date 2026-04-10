codeunit 137056 "SCM Warehouse-V"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [SCM]
        IsInitialized := false;
    end;

    var
        LocationWhite: Record Location;
        LocationYellow: Record Location;
        LocationSilver: Record Location;
        LocationSilver2: Record Location;
        LocationSilver3: Record Location;
        LocationGreen: Record Location;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryPlanning: Codeunit "Library - Planning";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryRandom: Codeunit "Library - Random";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        IsInitialized: Boolean;
        NewUnitOfMeasure: Code[10];
        ReferenceText: Label '%1 %2.';
        QuantityError: Label 'Quantity must be %1 in %2.';
        NewUnitOfMeasure2: Code[10];
        NewUnitOfMeasure3: Code[10];
        UnitOfMeasureType: Option Default,PutAway,Sales;
        ItemTrackingLineActionType: Option Tracking,Verify;
        WhseItemTrackingPageHandlerBody: Option MultipleLotNo,LotSerialNo;
        TrackingQuantity: Decimal;
        VerifyTracking: Boolean;
        NumberOfLineError: Label 'Number of Lines must be same.';
        LotSpecific: Boolean;
        ExpirationDateError: Label 'Expiration Date must ';
        PostJournalLines: Label 'Do you want to register and post the journal lines';
        MovementCreated: Label 'Movement ';
        Serial: Boolean;
        SelectEntries: Boolean;
        QuantityMismatchErr: Label 'Qty. (Base) must not be greater than';
        ItemTrackingLineErr: Label 'The total Item Tracking Lines are not correct.';
        QuantityBaseErr: Label 'Quantity (Base) must be %1 for Item %2 in %3';
        WrongBinCodeErr: Label 'You must enter a %1';
        BinCodeNotFoundErr: Label 'Bin Code %1 not found in Warehouse Entry.';
        WhseJournalLineBinCodeErr: Label 'Bin Code in Warehouse Journal Line is not equal to Location Adjustment bin.';
        CannotUnapplyItemLedgEntryErr: Label 'Item ledger entry %1 cannot be left unapplied';
        AdjmtBinCodeMustHaveValueErr: Label 'Adjustment Bin Code must have a value in Location';
        WrongNeededQtyErr: Label 'Incorrect %1 in %2.', Comment = '%1: FieldCaption(Qty. Needed), %2: TableCaption(Whse. Cross-Dock Opportunity)';
        CrossDockQtyExceedsCrossDockQtyErr: Label 'The sum of the Qty. to Cross-Dock and Qty. Cross-Docked (Base) fields must not exceed the value in the Qty. to Cross-Dock field on the warehouse receipt line.';
        DescriptionContainDateErr: Label 'In %1 field %2 does not conatin any date', Comment = '%1 - Table Caption, %2 - Field Caption';
        ShipmentNoLbl: Label 'Shipment No. %1:', Comment = '%1 - Sales Shipment No.';

    [Test]
    [Scope('OnPrem')]
    procedure CrossDockWithFullWarehouseReceipt()
    begin
        // Setup.
        Initialize();
        CalculateCrossDockFromWarehouseReceipt(false);  // Partial Receipt FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CrossDockWithPartialWarehouseReceipt()
    begin
        // Setup.
        Initialize();
        CalculateCrossDockFromWarehouseReceipt(true);  // Partial Receipt TRUE.
    end;

    local procedure CalculateCrossDockFromWarehouseReceipt(PartialReceipt: Boolean)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity";
        Zone: Record Zone;
        Quantity: Integer;
    begin
        // Create Item, create and release Sales Order, create and release Purchase Order, create Put Away.
        Quantity := 100;  // Large value required.
        CreateWarehouseReceiptSetup(Item, SalesHeader, PurchaseHeader, LocationWhite.Code, Quantity, Quantity);

        if PartialReceipt then
            UpdateQtyToReceiveOnWhseReceipt(WarehouseReceiptLine, PurchaseHeader."No.", Quantity / 2);  // Partial Quantity.

        // Exercise: Calculate Cross Dock.
        FindWarehouseReceiptNo(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        CalculateCrossDock(WhseCrossDockOpportunity, WarehouseReceiptLine."No.", Item."No.");

        // Verify: Verify values on Whse Activity Line. Verify Cross Dock Quantity.
        FindZone(Zone, LocationWhite.Code, LibraryWarehouse.SelectBinType(false, false, true, true));  // Find Zone with Bin Type Of CROSS-DOCK.
        VerifyWhseReceiptLine(WarehouseReceiptLine, Zone.Code, LocationWhite."Cross-Dock Bin Code", '');

        if PartialReceipt then
            WhseCrossDockOpportunity.TestField("Qty. to Cross-Dock", Quantity / 2)
        else
            WhseCrossDockOpportunity.TestField("Qty. to Cross-Dock", Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CrossDockWithExistingWhseCrossDockOpportunity()
    var
        Item: Record Item;
        WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity";
        SalesHeader: Record "Sales Header";
        LocationCode: Code[10];
        FirstWhseReceiptLineNo: Code[20];
        SecondWhseReceiptLineNo: Code[20];
        InventoryQty: Decimal;
        PurchaseQty: Decimal;
        SalesQty: Decimal;
        PickQty: Decimal;
        CrossDockQty: Decimal;
    begin
        // [FEATURE] [Cross-Dock]
        // [SCENARIO 380301] Quantities in Whse. Cross-Dock Opportunity should be calculated with consideration of "Qty. to Cross-Dock", "Qty. to Pick" and "Picked Qty." already calculated for the same demand in another Receipt.
        Initialize();
        DefineQuantitiesForPurchaseAndSalesDocuments(InventoryQty, PurchaseQty, SalesQty, PickQty, CrossDockQty);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Purchase Order with posted Receipt "R1" and registered Put-away on full WMS Location with cross-docking enabled. Received Quantity = "Qr".
        // [GIVEN] Released Purchase Orders with Receipts "R2" and "R3".
        PrepareInventoryAndTwoOutstandingReceiptsForPurchaseOrders(
          LocationCode, FirstWhseReceiptLineNo, SecondWhseReceiptLineNo, Item."No.", InventoryQty, PurchaseQty);

        // [GIVEN] Released Sales Order for quantity "Qs" > "Qr".
        // [GIVEN] The Sales Order is partially shipped and partially picked. "Qty. to Pick" + "Picked Qty." = "Qr".
        CreateAndReleaseSalesOrderWithShipmentAndPartialPick(SalesHeader, Item."No.", LocationCode, SalesQty, PickQty);

        // [GIVEN] Cross-Dock Opportunity is calculated for Receipt "R2" and updated. New "Qty. to Cross-Dock" = "Qcd".
        CalculateCrossDockOpportunityForWhseReceipt(WhseCrossDockOpportunity, FirstWhseReceiptLineNo);
        WhseCrossDockOpportunity.Validate("Qty. to Cross-Dock", CrossDockQty);
        WhseCrossDockOpportunity.Modify(true);

        // [WHEN] Calculate quantity to cross-dock "Qcd2" for Receipt "R3".
        CalculateCrossDockOpportunityForWhseReceipt(WhseCrossDockOpportunity, SecondWhseReceiptLineNo);
        // [THEN] "Qty. Needed" is equal to "Qs" - "Qr" - "Qcd" in Whse. Cross-Dock Opportunity for Receipt "R3".
        // [THEN] "Qty. to Cross-Dock" is equal to "Qty. Needed".
        // [THEN] "Pick Qty." and "Picked Qty." are equal to 0.
        WhseCrossDockOpportunity.TestField("Qty. Needed", SalesQty - InventoryQty - CrossDockQty);
        WhseCrossDockOpportunity.TestField("Qty. to Cross-Dock", WhseCrossDockOpportunity."Qty. Needed");
        WhseCrossDockOpportunity.TestField("Pick Qty.", 0);
        WhseCrossDockOpportunity.TestField("Picked Qty.", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CrossDockForChangedUOMWithExistingWhseCrossDockOpportunity()
    var
        GLSetup: Record "General Ledger Setup";
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LocationCode: Code[10];
        FirstWhseReceiptLineNo: Code[20];
        SecondWhseReceiptLineNo: Code[20];
        InventoryQty: Decimal;
        PurchaseQty: Decimal;
        SalesQty: Decimal;
        PickQty: Decimal;
        CrossDockQty: Decimal;
        QtyPerUOM: Decimal;
    begin
        // [FEATURE] [Cross-Dock]
        // [SCENARIO 380301] If Unit of Measure code is changed in a demand, then "Needed Qty." in Whse. Cross-Dock Opportunity should be calculated for the new UOM code with consideration of "Qty. to Cross-Dock" in previous UOM.
        Initialize();
        GLSetup.Get();
        DefineQuantitiesForPurchaseAndSalesDocuments(InventoryQty, PurchaseQty, SalesQty, PickQty, CrossDockQty);

        // [GIVEN] Item with Base and additional Unit of Measure.
        LibraryInventory.CreateItem(Item);
        QtyPerUOM := LibraryRandom.RandIntInRange(2, 10);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", QtyPerUOM);

        // [GIVEN] Purchase Order with posted Receipt "R1" and registered Put-away on full WMS Location with cross-docking enabled. Received Quantity = "Qr".
        // [GIVEN] Released Purchase Orders with Receipts "R2" and "R3".
        PrepareInventoryAndTwoOutstandingReceiptsForPurchaseOrders(
          LocationCode, FirstWhseReceiptLineNo, SecondWhseReceiptLineNo, Item."No.", InventoryQty, PurchaseQty);

        // [GIVEN] Released Sales Order with Base UOM "UOM1" and quantity "Qs" > "Qr".
        CreateAndReleaseSalesOrderWithVariant(SalesHeader, SalesLine, Item."No.", SalesQty, LocationCode, '');

        // [GIVEN] Cross-Dock Opportunity is calculated for Receipt "R2" and updated. New "Qty. to Cross-Dock" = "Qcd".
        CalculateCrossDockOpportunityForWhseReceipt(WhseCrossDockOpportunity, FirstWhseReceiptLineNo);
        WhseCrossDockOpportunity.Validate("Qty. to Cross-Dock", CrossDockQty);
        WhseCrossDockOpportunity.Modify(true);

        // [GIVEN] Unit of Measure Code on the Sales Line is changed to "UOM2".
        UpdateUOMOnSalesLine(SalesHeader, SalesLine, ItemUnitOfMeasure.Code);

        // [WHEN] Calculate quantity to cross-dock "Qcd2" for Receipt "R3".
        CalculateCrossDockOpportunityForWhseReceipt(WhseCrossDockOpportunity, SecondWhseReceiptLineNo);
        // [THEN] "To-Src. Unit of Measure Code" in Whse. Cross-Dock Opportunity for Receipt "R3" = "UOM2".
        // [THEN] "Qty. Needed" is equal to "Qs" - ("Qcd" converted to "UOM2") in Whse. Cross-Dock Opportunity for Receipt "R3".
        WhseCrossDockOpportunity.TestField("To-Src. Unit of Measure Code", ItemUnitOfMeasure.Code);
        Assert.AreNearlyEqual(
          SalesQty - CrossDockQty / QtyPerUOM, WhseCrossDockOpportunity."Qty. Needed", GLSetup."Unit-Amount Rounding Precision",
          StrSubstNo(WrongNeededQtyErr, WhseCrossDockOpportunity.FieldCaption("Qty. Needed"), WhseCrossDockOpportunity.TableCaption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CrossDockForDecreasedQtyWithExistingWhseCrossDockOpportunity()
    var
        Item: Record Item;
        WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LocationCode: Code[10];
        FirstWhseReceiptLineNo: Code[20];
        SecondWhseReceiptLineNo: Code[20];
        InventoryQty: Decimal;
        PurchaseQty: Decimal;
        SalesQty: Decimal;
        PickQty: Decimal;
        CrossDockQty: Decimal;
    begin
        // [FEATURE] [Cross-Dock]
        // [SCENARIO 380301] If Quantity is decreased in a demand so that already defined "Qty. to Cross-Dock" covers the demand, then the next calculation of Whse. Cross-Dock opportunity shows no needed quantity to be cross-docked.
        Initialize();
        DefineQuantitiesForPurchaseAndSalesDocuments(InventoryQty, PurchaseQty, SalesQty, PickQty, CrossDockQty);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Purchase Order with posted Receipt "R1" and registered Put-away on full WMS Location with cross-docking enabled. Received Quantity = "Qr".
        // [GIVEN] Released Purchase Orders with Receipts "R2" and "R3".
        PrepareInventoryAndTwoOutstandingReceiptsForPurchaseOrders(
          LocationCode, FirstWhseReceiptLineNo, SecondWhseReceiptLineNo, Item."No.", InventoryQty, PurchaseQty);

        // [GIVEN] Released Sales Order with Base UOM "UOM1" and quantity "Qs1" > "Qr".
        CreateAndReleaseSalesOrderWithVariant(SalesHeader, SalesLine, Item."No.", SalesQty, LocationCode, '');

        // [GIVEN] Cross-Dock Opportunity is calculated for Receipt "R2" and updated. New "Qty. to Cross-Dock" = "Qcd".
        CalculateCrossDockOpportunityForWhseReceipt(WhseCrossDockOpportunity, FirstWhseReceiptLineNo);
        WhseCrossDockOpportunity.Validate("Qty. to Cross-Dock", CrossDockQty);
        WhseCrossDockOpportunity.Modify(true);

        // [GIVEN] Quantity in Sales Line is decreased to "Qs2" so it does not exceed already cross-docked quantity "Qcd".
        UpdateQuantityOnSalesLine(SalesHeader, SalesLine, LibraryRandom.RandInt(CrossDockQty));

        // [WHEN] Calculate quantity to cross-dock "Qcd2" for Receipt "R3".
        CalculateCrossDockOpportunityForWhseReceipt(WhseCrossDockOpportunity, SecondWhseReceiptLineNo);

        // [THEN] "Qty. Needed" = 0 in Whse. Cross-Dock Opportunity for Receipt "R3".
        WhseCrossDockOpportunity.TestField("Qty. Needed", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CrossDockWhenQtyReceivedYetNotPutAway()
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        ReceiptQty: Decimal;
        SalesQty: Decimal;
        CrossDockedQty: Decimal;
    begin
        // [FEATURE] [Cross-Dock]
        // [SCENARIO 380520] Qty. to Cross-Dock in Warehouse Receipt should consider the quantity that has been already received yet not put-away.
        Initialize();
        DefineSupplyAndDemandQtys(ReceiptQty, SalesQty, CrossDockedQty);

        // [GIVEN] WMS Location with cross-docking enabled.
        // [GIVEN] Released Sales Order. Sales quantity = "SQ".
        // [GIVEN] Released Purchase Order.
        // [GIVEN] Posted Warehouse Receipt "R1". Quantity "CDQ" is set to be cross-docked to meet the Sales Order.
        // [GIVEN] Released Purchase Order with Warehouse Receipt "R2".
        CreateWhseReceiptForCrossDockedItem(WarehouseReceiptLine, ReceiptQty, SalesQty, CrossDockedQty);

        // [WHEN] Calculate quantity to cross-dock for "R2".
        CalculateCrossDockSimple(WarehouseReceiptLine."No.");

        // [THEN] Quantity to cross-dock in the Receipt "R2" = "SQ" - "CDQ".
        WarehouseReceiptLine.Find();
        WarehouseReceiptLine.TestField("Qty. to Cross-Dock", SalesQty - CrossDockedQty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutofilledQtyToCrossDockEqualsToDemandOnSurplusReceipt()
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity";
        ReceiptQty: Decimal;
        SalesQty: Decimal;
        CrossDockedQty: Decimal;
    begin
        // [FEATURE] [Cross-Dock]
        // [SCENARIO 380520] Qty. to Cross-Dock in Whse. Cross-Dock Opportunity is automatically filled with the residual qty. to cross-dock if other receipts do not fully cover the demand.
        Initialize();
        DefineSupplyAndDemandQtys(ReceiptQty, SalesQty, CrossDockedQty);

        // [GIVEN] WMS Location with cross-docking enabled.
        // [GIVEN] Released Sales Order. Sales quantity = "SQ".
        // [GIVEN] Released Purchase Order.
        // [GIVEN] Posted Warehouse Receipt "R1". Quantity "CDQ" is set to be cross-docked to meet the Sales Order.
        // [GIVEN] Released Purchase Order with Warehouse Receipt "R2". Receipt quantity = "RQ".
        // [GIVEN] Quantity to receive yet not cross-docked ("RQ" - "CDQ") is enough to cover the Sales.
        CreateWhseReceiptForCrossDockedItem(WarehouseReceiptLine, ReceiptQty, SalesQty, CrossDockedQty);

        // [WHEN] Calculate Whse. Cross-Dock Opportunity for "R2" and automatically fill quantity to cross-dock.
        CalculateCrossDockOpportunityForWhseReceipt(WhseCrossDockOpportunity, WarehouseReceiptLine."No.");

        // [THEN] "Qty. to Cross-Dock" in the Whse. Cross-Dock Opportunity = "SQ" - "CDQ".
        WhseCrossDockOpportunity.TestField("Qty. to Cross-Dock", SalesQty - CrossDockedQty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutofilledQtyToCrossDockEqualsToReceiveNotCrossDockedOnLackingReceipt()
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity";
        ReceiptQty: Decimal;
        SalesQty: Decimal;
        CrossDockedQty: Decimal;
    begin
        // [FEATURE] [Cross-Dock]
        // [SCENARIO 380520] Qty. to Cross-Dock in Whse. Cross-Dock Opportunity is automatically filled with the quantity of the receipt if it does not cover the demand together with other receipts.
        Initialize();
        DefineSupplyAndDemandQtys(ReceiptQty, SalesQty, CrossDockedQty);
        ReceiptQty := 30;

        // [GIVEN] WMS Location with cross-docking enabled.
        // [GIVEN] Released Sales Order. Sales quantity = "SQ".
        // [GIVEN] Released Purchase Order.
        // [GIVEN] Posted Warehouse Receipt "R1". Quantity "CDQ" is set to be cross-docked to meet the Sales Order.
        // [GIVEN] Released Purchase Order with Warehouse Receipt "R2". Receipt quantity = "RQ".
        // [GIVEN] Quantity to receive yet not cross-docked ("RQ" - "CDQ") is not enough to cover the Sales.
        CreateWhseReceiptForCrossDockedItem(WarehouseReceiptLine, ReceiptQty, SalesQty, CrossDockedQty);

        // [WHEN] Calculate Whse. Cross-Dock Opportunity for "R2" and automatically fill quantity to cross-dock.
        CalculateCrossDockOpportunityForWhseReceipt(WhseCrossDockOpportunity, WarehouseReceiptLine."No.");

        // [THEN] "Qty. to Cross-Dock" in the Whse. Cross-Dock Opportunity = "RQ".
        WhseCrossDockOpportunity.TestField("Qty. to Cross-Dock", ReceiptQty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CrossDockOpportunityOutOfLimitsOfReceivedMinusCrossDockedQty()
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity";
        ReceiptQty: Decimal;
        SalesQty: Decimal;
        CrossDockedQty: Decimal;
    begin
        // [FEATURE] [Cross-Dock]
        // [SCENARIO 380520] Qty. to Cross-Dock in Whse. Cross-Dock Opportunity cannot exceed the quantity in the Receipt minus what has already been cross-docked.
        Initialize();
        DefineSupplyAndDemandQtys(ReceiptQty, SalesQty, CrossDockedQty);

        // [GIVEN] WMS Location with cross-docking enabled.
        // [GIVEN] Released Sales Order. Sales quantity = "SQ".
        // [GIVEN] Released Purchase Order.
        // [GIVEN] Posted Warehouse Receipt "R1". Quantity "CDQ" is set to be cross-docked to meet the Sales Order.
        // [GIVEN] Released Purchase Order with Warehouse Receipt "R2". Receipt quantity = "RQ".
        CreateWhseReceiptForCrossDockedItem(WarehouseReceiptLine, ReceiptQty, SalesQty, CrossDockedQty);

        // [GIVEN] Cross-Dock Opportunity for "R2".
        CalculateCrossDockOpportunityForWhseReceipt(WhseCrossDockOpportunity, WarehouseReceiptLine."No.");

        // [WHEN] Try to cross-dock all receiving quantity "RQ".
        asserterror WhseCrossDockOpportunity.Validate("Qty. to Cross-Dock", ReceiptQty);

        // [THEN] Error is thrown.
        Assert.ExpectedError(CrossDockQtyExceedsCrossDockQtyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CrossDockOppWithPartiallyPostedPutAwayToStorageBin()
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        Bin: Record Bin;
        ReceiptQty: Decimal;
        SalesQty: Decimal;
        CrossDockedQty: Decimal;
        PutawayQty: Decimal;
    begin
        // [FEATURE] [Cross-Dock]
        // [SCENARIO 381303] Overall cross-docked quantity equals to actual quantity in cross-dock bins, plus received quantity that has not been placed into a bin in bulk zone.
        Initialize();
        DefineSupplyAndDemandQtys(ReceiptQty, SalesQty, CrossDockedQty);

        // [GIVEN] WMS Location with cross-docking enabled.
        // [GIVEN] Released Sales Order. Sales quantity = "SQ".
        // [GIVEN] Released Purchase Order.
        // [GIVEN] Posted Warehouse Receipt "R1". Quantity to be cross-docked is set to "CDQ", which is less than "SQ".
        // [GIVEN] Released Purchase Order with Warehouse Receipt "R2".
        CreateWhseReceiptForCrossDockedItem(WarehouseReceiptLine, ReceiptQty, SalesQty, CrossDockedQty);

        // [GIVEN] Put-away is created after "R1" is posted.
        // [GIVEN] The put-away is partly (handled quantity = "HQ") registered to a bin in the bulk zone.
        FindBin(Bin, WarehouseReceiptLine."Location Code", false);
        PutawayQty := CrossDockedQty - LibraryRandom.RandInt(5);
        UpdateAndRegisterPutAway(WarehouseReceiptLine."Item No.", Bin."Location Code", Bin."Zone Code", Bin.Code, PutawayQty);

        // [WHEN] Calculate cross-dock quantity for Receipt "R2".
        CalculateCrossDockSimple(WarehouseReceiptLine."No.");

        // [THEN] Cross-docked quantity "X" = "CDQ" - "HQ".
        // [THEN] Quantity to be cross-docked for "R2" is equal to "SQ" - "X".
        WarehouseReceiptLine.Find();
        WarehouseReceiptLine.TestField("Qty. to Cross-Dock", SalesQty - (CrossDockedQty - PutawayQty));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CrossDockOppWithPartiallyPostedPutAwayToCrossDockBin()
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        Bin: Record Bin;
        ReceiptQty: Decimal;
        SalesQty: Decimal;
        CrossDockedQty: Decimal;
    begin
        // [FEATURE] [Cross-Dock]
        // [SCENARIO 381303] Overall cross-docked quantity equals to actual quantity in cross-dock bins, plus partially put-away received quantity if it has not been placed into a bin in bulk zone.
        Initialize();
        DefineSupplyAndDemandQtys(ReceiptQty, SalesQty, CrossDockedQty);

        // [GIVEN] WMS Location with cross-docking enabled.
        // [GIVEN] Released Sales Order. Sales quantity = "SQ".
        // [GIVEN] Released Purchase Order.
        // [GIVEN] Posted Warehouse Receipt "R1". Quantity to be cross-docked is set to "CDQ", which is less than "SQ".
        // [GIVEN] Released Purchase Order with Warehouse Receipt "R2".
        CreateWhseReceiptForCrossDockedItem(WarehouseReceiptLine, ReceiptQty, SalesQty, CrossDockedQty);

        // [GIVEN] Put-away is created after "R1" is posted.
        // [GIVEN] The put-away is partly registered to a cross-dock bin.
        FindBin(Bin, WarehouseReceiptLine."Location Code", true);
        UpdateAndRegisterPutAway(
          WarehouseReceiptLine."Item No.", Bin."Location Code", Bin."Zone Code", Bin.Code, CrossDockedQty - LibraryRandom.RandInt(5));

        // [WHEN] Calculate cross-dock quantity for Receipt "R2".
        CalculateCrossDockSimple(WarehouseReceiptLine."No.");

        // [THEN] Cross-docked quantity "X" = "CDQ", as nothing is placed into a bulk bin.
        // [THEN] Quantity to be cross-docked for "R2" is equal to "SQ" - "X".
        WarehouseReceiptLine.Find();
        WarehouseReceiptLine.TestField("Qty. to Cross-Dock", SalesQty - CrossDockedQty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CrossDockOppWithFullyPostedPutAway()
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        Bin: Record Bin;
        ReceiptQty: Decimal;
        SalesQty: Decimal;
        CrossDockedQty: Decimal;
    begin
        // [FEATURE] [Cross-Dock]
        // [SCENARIO 381303] Overall cross-docked quantity equals to actual quantity in cross-dock bins, if received quantity has been completely put-away into a bin in bulk zone.
        Initialize();
        DefineSupplyAndDemandQtys(ReceiptQty, SalesQty, CrossDockedQty);

        // [GIVEN] WMS Location with cross-docking enabled.
        // [GIVEN] Released Sales Order. Sales quantity = "SQ".
        // [GIVEN] Released Purchase Order.
        // [GIVEN] Posted Warehouse Receipt "R1". Quantity to be cross-docked is set to "CDQ", which is less than "SQ".
        // [GIVEN] Released Purchase Order with Warehouse Receipt "R2".
        CreateWhseReceiptForCrossDockedItem(WarehouseReceiptLine, ReceiptQty, SalesQty, CrossDockedQty);

        // [GIVEN] Put-away is created after "R1" is posted.
        // [GIVEN] The put-away is completely registered to a bin in bulk zone.
        FindBin(Bin, WarehouseReceiptLine."Location Code", false);
        UpdateAndRegisterPutAway(WarehouseReceiptLine."Item No.", Bin."Location Code", Bin."Zone Code", Bin.Code, CrossDockedQty);

        // [WHEN] Calculate cross-dock quantity for Receipt "R2".
        CalculateCrossDockSimple(WarehouseReceiptLine."No.");

        // [THEN] Cross-docked quantity "X" = 0, as everything is placed into a bulk bin.
        // [THEN] Quantity to be cross-docked for "R2" is equal to "SQ" - "X".
        WarehouseReceiptLine.Find();
        WarehouseReceiptLine.TestField("Qty. to Cross-Dock", SalesQty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PutAwayFromWhseReceiptWithCrossDock()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity";
        Zone: Record Zone;
        Quantity: Integer;
    begin
        // Setup: Create Item, create and release Sales Order, create and release Purchase Order, create Put Away.
        Initialize();
        Quantity := LibraryRandom.RandInt(100);
        CreateWarehouseReceiptSetup(Item, SalesHeader, PurchaseHeader, LocationWhite.Code, Quantity, Quantity);
        FindWarehouseReceiptNo(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        CalculateCrossDock(WhseCrossDockOpportunity, WarehouseReceiptLine."No.", Item."No.");

        // Exercise: Post Warehouse Receipt.
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");

        // Verify: Verify Cross Dock Quantity and verify values on Whse Activity Lines.
        WhseCrossDockOpportunity.TestField("Qty. to Cross-Dock", Quantity);
        FindZone(Zone, LocationWhite.Code, LibraryWarehouse.SelectBinType(false, false, true, true));  // Find Zone with Bin Type Of CROSS-DOCK.
        VerifyCrossDockEntriesOnWarehouseActivityLine(
          WarehouseActivityLine, LocationWhite.Code, Zone.Code, WarehouseActivityLine."Activity Type"::"Put-away", PurchaseHeader."No.",
          WarehouseActivityLine."Action Type"::Place, Quantity);
        FindZone(Zone, LocationWhite.Code, LibraryWarehouse.SelectBinType(true, false, false, false));  // Find Zone with Bin Type Of RECEIVE.
        VerifyCrossDockEntriesOnWarehouseActivityLine(
          WarehouseActivityLine, LocationWhite.Code, Zone.Code, WarehouseActivityLine."Activity Type"::"Put-away", PurchaseHeader."No.",
          WarehouseActivityLine."Action Type"::Take, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PickFromWhseShipmentWithCrossDock()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityLine2: Record "Warehouse Activity Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity";
        Zone: Record Zone;
        Quantity: Integer;
    begin
        // Setup: Create Item, create and release Sales Order, create and release Purchase Order, create Put Away, pos Whse Receipt and register Whse Activity.
        Initialize();
        Quantity := LibraryRandom.RandInt(100);
        CreateWarehouseReceiptSetup(Item, SalesHeader, PurchaseHeader, LocationWhite.Code, Quantity, Quantity);
        FindWarehouseReceiptNo(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        CalculateCrossDock(WhseCrossDockOpportunity, WarehouseReceiptLine."No.", Item."No.");
        PostWhseReceiptAndRegisterWhseActivity(PurchaseHeader."No.");

        // Exercise: Create Pick.
        CreateAndReleaseWhseShipment(SalesHeader, WarehouseShipmentHeader);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // Verify: Verify values on Whse Activity Lines.
        FindZone(Zone, LocationWhite.Code, LibraryWarehouse.SelectBinType(false, false, true, true));  // Find Zone with Bin Type Of CROSS-DOCK.
        VerifyCrossDockEntriesOnWarehouseActivityLine(
          WarehouseActivityLine2, LocationWhite.Code, Zone.Code, WarehouseActivityLine2."Activity Type"::Pick, SalesHeader."No.",
          WarehouseActivityLine."Action Type"::Take, Quantity);
        FindZone(Zone, LocationWhite.Code, LibraryWarehouse.SelectBinType(false, true, false, false));  // Find Zone with Bin Type Of SHIP.
        VerifyCrossDockEntriesOnWarehouseActivityLine(
          WarehouseActivityLine2, LocationWhite.Code, Zone.Code, WarehouseActivityLine2."Activity Type"::Pick, SalesHeader."No.",
          WarehouseActivityLine."Action Type"::Place, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BackOrderPartialDeliveryWithCrossDocking()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity";
        Zone: Record Zone;
        Quantity: Integer;
    begin
        // Setup: Create Item, create and release Sales Order, create and release Purchase Order, create Put Away, post Whse Receipt and register Whse Activity. Create Pick.
        Initialize();
        Quantity := LibraryRandom.RandInt(100) + 100;  // Large Integer value required.
        CreateWarehouseReceiptSetup(Item, SalesHeader, PurchaseHeader, LocationWhite.Code, Quantity, Quantity);
        UpdateQtyToReceiveOnWhseReceipt(WarehouseReceiptLine, PurchaseHeader."No.", Quantity / 2);  // Partial Quantity.
        CalculateCrossDock(WhseCrossDockOpportunity, WarehouseReceiptLine."No.", Item."No.");
        PostWhseReceiptAndRegisterWhseActivity(PurchaseHeader."No.");
        CreateAndReleaseWhseShipment(SalesHeader, WarehouseShipmentHeader);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // Exercise: Post Warehouse Shipment.
        RegisterWarehouseActivity(SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // Verify: Verify the Posted Whse Shipment Line.
        FindZone(Zone, LocationWhite.Code, LibraryWarehouse.SelectBinType(false, true, false, false));  // Find Zone with Bin Type Of SHIP.
        VerifyPostedWhseShipmentLine(
          SalesHeader."No.", Zone.Code, Quantity / 2, Item."Base Unit of Measure", WarehouseReceiptLine."Qty. per Unit of Measure",
          LocationWhite.Code);
    end;

    [Test]
    [HandlerFunctions('ReservationHandler')]
    [Scope('OnPrem')]
    procedure BackOrderFullDeliveryWithCrossDockingUsingReservation()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity";
        Zone: Record Zone;
        Quantity: Integer;
    begin
        // Setup: Create Item, create and release Sales Order with reservation, create and release Purchase Order, create Put Away, post Whse Receipt and register Whse Activity. Create Pick.
        Initialize();
        Quantity := LibraryRandom.RandInt(100);
        LibraryInventory.CreateItem(Item);
        CreateAndReleaseSalesOrderWithReservation(SalesHeader, Item."No.", Quantity, LocationWhite.Code);
        CreateAndReleasePurchaseOrder(PurchaseHeader, Item."No.", LocationWhite.Code, Quantity, '', '', false);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWarehouseReceiptNo(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        CalculateCrossDock(WhseCrossDockOpportunity, WarehouseReceiptLine."No.", Item."No.");
        PostWhseReceiptAndRegisterWhseActivity(PurchaseHeader."No.");
        CreateAndReleaseWhseShipment(SalesHeader, WarehouseShipmentHeader);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // Exercise: Post Warehouse Shipment.
        RegisterWarehouseActivity(SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // Verify: Verify the Posted Whse Shipment Line.
        FindZone(Zone, LocationWhite.Code, LibraryWarehouse.SelectBinType(false, true, false, false));  // Find Zone with Bin Type Of SHIP.
        VerifyPostedWhseShipmentLine(
          SalesHeader."No.", Zone.Code, Quantity, Item."Base Unit of Measure", WarehouseReceiptLine."Qty. per Unit of Measure",
          LocationWhite.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SpecialOrderWithCrossDocking()
    begin
        // Setup.
        Initialize();
        WarehouseCrossDockingWithSpecialOrder(false, false);  // Change UOM on Put Away and Pick FALSE.
    end;

    [Test]
    [HandlerFunctions('ChangeUOMRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeUOMOnPutAwayWithSpecialOrderCrossDocking()
    begin
        // Setup.
        Initialize();
        WarehouseCrossDockingWithSpecialOrder(true, false);  // Change UOM on Put Away TRUE.
    end;

    [Test]
    [HandlerFunctions('ChangeUOMRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeUOMOnPickWithSpecialOrderCrossDocking()
    begin
        // Setup.
        Initialize();
        WarehouseCrossDockingWithSpecialOrder(true, true);  // Change UOM on Put Away and Pick TRUE.
    end;

    local procedure WarehouseCrossDockingWithSpecialOrder(ChangeUOMOnPutAway: Boolean; ChangeUOMOnPick: Boolean)
    var
        Item: Record Item;
        Vendor: Record Vendor;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityLine2: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Quantity: Integer;
    begin
        // Create Item, Vendor, create and release Special Order, create Requisition Line. Get sales Order and perform Carry out Action Message, create Whse Receipt.
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        Quantity := LibraryRandom.RandInt(100);
        CreateAndReleaseSpecialOrder(SalesHeader, Item."No.", Quantity, LocationWhite.Code);
        CreateRequisitionLineAndCarryOutReqWorksheet(Item."No.", Vendor."No.");
        FindPurchaseHeader(PurchaseHeader, Vendor."No.", LocationWhite.Code);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWarehouseReceiptNo(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");

        // Exercise: Calculate Cross Dock.
        CalculateCrossDock(WhseCrossDockOpportunity, WarehouseReceiptLine."No.", Item."No.");

        // Verify: Verify the Quantity on Whse Cross Dock opportunity.
        WhseCrossDockOpportunity.TestField("Qty. to Cross-Dock", Quantity);
        WarehouseReceiptLine.TestField("Cross-Dock Bin Code", LocationWhite."Cross-Dock Bin Code");

        if ChangeUOMOnPutAway then begin
            CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandInt(10));
            NewUnitOfMeasure := ItemUnitOfMeasure.Code;  // Assign value to global variable.
            PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");

            // Exercise: Change Unit Of Measure on Put Away created.
            ChangeUnitOfMeasureOnWhseActivityLine(
              WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Put-away", LocationWhite.Code, PurchaseHeader."No.");
            RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");

            // Verify: Verify Registered Whse Activity Line.
            VerifyRegisteredWhseActivityLine(
              WarehouseActivityLine, ItemUnitOfMeasure.Code, ItemUnitOfMeasure."Qty. per Unit of Measure", WarehouseActivityLine.Quantity, '');
        end;

        if ChangeUOMOnPick then begin
            CreateAndReleaseWhseShipment(SalesHeader, WarehouseShipmentHeader);
            LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

            // Exercise: Change Unit Of Measure on Pick created.
            ChangeUnitOfMeasureOnWhseActivityLine(
              WarehouseActivityLine2, WarehouseActivityLine2."Activity Type"::Pick, LocationWhite.Code, SalesHeader."No.");
            FindWhseActivityLine(
              WarehouseActivityLine2, WarehouseActivityLine2."Activity Type"::Pick, LocationWhite.Code, SalesHeader."No.",
              WarehouseActivityLine2."Action Type"::Take);
            RegisterWarehouseActivity(SalesHeader."No.", WarehouseActivityLine2."Activity Type"::Pick);

            // Verify: Verify Registered Whse Activity Line.
            VerifyRegisteredWhseActivityLine(
              WarehouseActivityLine2, ItemUnitOfMeasure.Code, ItemUnitOfMeasure."Qty. per Unit of Measure", WarehouseActivityLine2.Quantity,
              '');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehouseReceiptUsingItemVariantsWithCrossDocking()
    begin
        // Setup.
        Initialize();
        WhseActivityUsingItemVariantsWithCrossDocking(false, false);  // Register Put Away and Pick FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegisterPutAwayUsingItemVariantsWithCrossDocking()
    begin
        // Setup.
        Initialize();
        WhseActivityUsingItemVariantsWithCrossDocking(true, false);  // Register Put Away TRUE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegisterPickUsingItemVariantsWithCrossDocking()
    begin
        // Setup.
        Initialize();
        WhseActivityUsingItemVariantsWithCrossDocking(true, true);  // Register Put Away and Pick TRUE.
    end;

    local procedure WhseActivityUsingItemVariantsWithCrossDocking(RegisterPutAway: Boolean; RegisterPick: Boolean)
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity";
        Zone: Record Zone;
        Quantity: Integer;
    begin
        // create Item, Item variant, Item variant setup with a back order, create Warehouse Receipt.
        Quantity := LibraryRandom.RandInt(100);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        CreateOrderWithItemVariantSetup(SalesHeader, PurchaseHeader, Item."No.", ItemVariant.Code, LocationWhite.Code, Quantity);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWarehouseReceiptNo(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");

        // Exercise: Calculate Cross Dock.
        CalculateCrossDock(WhseCrossDockOpportunity, WarehouseReceiptLine."No.", Item."No.");

        // Verify: Verify the Cross dock Opportunity and the values on Whse Receipt Line.
        WhseCrossDockOpportunity.TestField("Qty. to Cross-Dock", Quantity);
        FindZone(Zone, LocationWhite.Code, LibraryWarehouse.SelectBinType(false, false, true, true));  // Find Zone with Bin Type Of CROSS-DOCK.
        VerifyWhseReceiptLine(WarehouseReceiptLine, Zone.Code, LocationWhite."Cross-Dock Bin Code", ItemVariant.Code);

        if RegisterPutAway then begin
            // Exercise: Register the Put Away created.
            PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
            FindWhseActivityLine(
              WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Put-away", LocationWhite.Code, PurchaseHeader."No.",
              WarehouseActivityLine."Action Type"::Place);
            RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");

            // Verify: Verify the Registered Whse Activity.
            VerifyRegisteredWhseActivityLine(WarehouseActivityLine, Item."Base Unit of Measure", 1, Quantity, ItemVariant.Code);
        end;

        if RegisterPick then begin
            // Exercise: Create and release Whse Shipment, create Pick, register the Pick created.
            Clear(WarehouseActivityLine);
            CreateAndReleaseWhseShipment(SalesHeader, WarehouseShipmentHeader);
            LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
            FindWhseActivityLine(
              WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationWhite.Code, SalesHeader."No.",
              WarehouseActivityLine."Action Type"::Place);
            RegisterWarehouseActivity(SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);

            // Verify: Verify the Registered Whse Activity.
            VerifyRegisteredWhseActivityLine(WarehouseActivityLine, Item."Base Unit of Measure", 1, Quantity, ItemVariant.Code);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehouseReceiptWithWarehouseClassCrossDock()
    begin
        // Setup.
        Initialize();
        WarehouseActivityWithWarehouseClassCrossDock(false);  // Update Bin Code and Post on Whse Receipt FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostWhseReceiptWithWarehouseClassCrossDock()
    begin
        // Setup.
        Initialize();
        WarehouseActivityWithWarehouseClassCrossDock(true);  // Update Bin Code and Post on Whse Receipt TRUE.
    end;

    local procedure WarehouseActivityWithWarehouseClassCrossDock(UpdateBinAndPostWhseReceipt: Boolean)
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        WarehouseClass: Record "Warehouse Class";
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        Bin: Record Bin;
        WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        Zone: Record Zone;
        Quantity: Integer;
    begin
        // Create Item, create Product Group with Warehouse Class Code, create and relase Purchase Order, create Warehouse Receipt.
        Quantity := LibraryRandom.RandInt(100);
        CreateItemWithWarehouseClass(Item, WarehouseClass);
        CreateAndReleaseSalesOrderWithVariant(SalesHeader, SalesLine, Item."No.", Quantity, LocationWhite.Code, '');
        CreateAndReleasePurchaseOrder(PurchaseHeader, Item."No.", LocationWhite.Code, Quantity, '', '', false);
        CreateBinWithWarehouseClass(Bin, LocationWhite.Code, false, false, true, false, WarehouseClass.Code);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWarehouseReceiptNo(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");

        // Exercise: Calculate Crosss Dock.
        CalculateCrossDock(WhseCrossDockOpportunity, WarehouseReceiptLine."No.", Item."No.");

        // Verify: Verify the values on Warehouse Receipt line.
        FindZone(Zone, LocationWhite.Code, LibraryWarehouse.SelectBinType(false, false, true, true));  // Find Zone with Bin Type Of CROSS-DOCK.
        VerifyWhseReceiptLine(WarehouseReceiptLine, Zone.Code, LocationWhite."Cross-Dock Bin Code", '');

        if UpdateBinAndPostWhseReceipt then begin
            // Exercise: Update Bin Code on Whse Receipt Line. Post Whse Receipt created.
            CreateAndUpdateBinCodeOnWarehouseReceiptLine(Bin, LocationWhite.Code, Item."No.", WarehouseClass.Code);
            PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");

            // Verify: Verify the Posted Whse Receipt Line.
            VerifyPostedWhseReceiptLine(WarehouseReceiptLine."No.", Bin.Code, Quantity);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehouseShipmentWithWarehouseClassCode()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        WarehouseClass: Record "Warehouse Class";
        Bin: Record Bin;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        SalesHeader: Record "Sales Header";
        Quantity: Decimal;
    begin
        // Setup: Create Item with Warehouse class code, create and release sales Order, create Whse Shipment. Create and update Bin code on Whse Shipment Line.
        Initialize();
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateItemWithWarehouseClass(Item, WarehouseClass);
        CreateAndReleaseSalesOrderWithVariant(SalesHeader, SalesLine, Item."No.", Quantity, LocationWhite.Code, '');
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWhseShipmentNo(WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
        CreateAndUpdateBinCodeOnWarehouseShipmentLine(Bin, LocationWhite.Code, Item."No.", WarehouseClass.Code);

        // Exercise: Release Whse Shipment.
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);

        // Verify: Verify the values on Whse Shipment Line.
        VerifyWarehouseShipmentLine(WarehouseShipmentHeader."No.", Quantity, Bin.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UOMOnPickLines()
    begin
        // Setup.
        Initialize();
        UOMOnWarehouseEntries(false);  // Change UOM FALSE.
    end;

    [Test]
    [HandlerFunctions('ChangeUOMRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeUOMOnPickLines()
    begin
        // Setup.
        Initialize();
        UOMOnWarehouseEntries(true);  // Change UOM TRUE.
    end;

    local procedure UOMOnWarehouseEntries(ChangeUOM: Boolean)
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemUnitOfMeasure2: Record "Item Unit of Measure";
        ItemUnitOfMeasure3: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityLine2: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        ExpectedQuantity: Decimal;
        Quantity: Decimal;
    begin
        // Create Item with multiple Item Unit Of Measure, create and release Purchase Order, create Whse Receipt. Register Put Away.
        // Create and release Sales Order and whse Shipment.
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateMultipleItemUnitOfMeasureSetup(Item, ItemUnitOfMeasure, ItemUnitOfMeasure2, ItemUnitOfMeasure3);
        CreateAndReleasePurchaseOrder(PurchaseHeader, Item."No.", LocationWhite.Code, Quantity, '', '', false);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWarehouseReceiptNo(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Put-away", LocationWhite.Code, PurchaseHeader."No.",
          WarehouseActivityLine."Action Type"::Place);
        ExpectedQuantity := WarehouseActivityLine.Quantity / ItemUnitOfMeasure."Qty. per Unit of Measure";
        RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityHeader.Type::"Put-away");
        CreateAndReleaseSalesOrderWithVariant(SalesHeader, SalesLine, Item."No.", Quantity, LocationWhite.Code, '');
        CreateAndReleaseWhseShipment(SalesHeader, WarehouseShipmentHeader);
        NewUnitOfMeasure := ItemUnitOfMeasure.Code;  // Assign value to global variable.
        NewUnitOfMeasure2 := ItemUnitOfMeasure2.Code;  // Assign value to global variable.

        // Exercise: Create Pick.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // Verify: Verify the values on Whse Activity Line.
        FindWhseActivityLine(
          WarehouseActivityLine2, WarehouseActivityLine2."Activity Type"::Pick, LocationWhite.Code, SalesHeader."No.",
          WarehouseActivityLine2."Action Type"::Place);
        VerifyWhseActivityLine(
          WarehouseActivityLine2, WarehouseActivityLine2."Activity Type"::Pick, LocationWhite.Code, SalesHeader."No.",
          WarehouseActivityLine2."Action Type"::Place, ExpectedQuantity / 2, ItemUnitOfMeasure3.Code,
          ItemUnitOfMeasure3."Qty. per Unit of Measure");

        if ChangeUOM then begin
            // Exercise: Change Unit Of Measure on Pick Line.
            UnitOfMeasureType := UnitOfMeasureType::PutAway;
            LibraryWarehouse.ChangeUnitOfMeasure(WarehouseActivityLine2);

            // Verify: Verify the values on Whse Activity Line.
            VerifyWhseActivityLine(
              WarehouseActivityLine2, WarehouseActivityLine2."Activity Type"::Pick, LocationWhite.Code, SalesHeader."No.",
              WarehouseActivityLine2."Action Type"::Take, ExpectedQuantity, ItemUnitOfMeasure2.Code,
              ItemUnitOfMeasure2."Qty. per Unit of Measure");
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UOMOnWarehouseReceipt()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemUnitOfMeasure2: Record "Item Unit of Measure";
        ItemUnitOfMeasure3: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        Quantity: Decimal;
    begin
        // Setup: Create Item with multiple Item Unit Of Measure, create and release Purchase Order.
        Initialize();
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateMultipleItemUnitOfMeasureSetup(Item, ItemUnitOfMeasure, ItemUnitOfMeasure2, ItemUnitOfMeasure3);
        CreateAndReleasePurchaseOrder(PurchaseHeader, Item."No.", LocationWhite.Code, Quantity, '', '', false);

        // Exercise: Create Whse Receipt.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // Verify: Verify the Unit Of Measure on whse Receipt Line.
        FindWarehouseReceiptNo(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        WarehouseReceiptLine.TestField("Unit of Measure Code", ItemUnitOfMeasure.Code);
        WarehouseReceiptLine.TestField("Qty. per Unit of Measure", 1);  // Value required.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitOfMeasureOnPutAway()
    begin
        // Setup.
        Initialize();
        ChangeUOMOnPutAway(false);  // Change UOM FALSE.
    end;

    [Test]
    [HandlerFunctions('ChangeUOMRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PutAwayWithNewUOM()
    begin
        // Setup.
        Initialize();
        ChangeUOMOnPutAway(true);  // Change UOM TRUE.
    end;

    local procedure ChangeUOMOnPutAway(ChangeUOM: Boolean)
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemUnitOfMeasure2: Record "Item Unit of Measure";
        ItemUnitOfMeasure3: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        ExpectedQuantity: Decimal;
        Quantity: Decimal;
    begin
        // Setup: Create Item with multiple Item Unit Of Measure, create and release Purchase Order.
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateMultipleItemUnitOfMeasureSetup(Item, ItemUnitOfMeasure, ItemUnitOfMeasure2, ItemUnitOfMeasure3);
        CreateAndReleasePurchaseOrder(PurchaseHeader, Item."No.", LocationWhite.Code, Quantity, '', '', false);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWarehouseReceiptNo(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        // Assign values to global variables.
        NewUnitOfMeasure := ItemUnitOfMeasure.Code;
        NewUnitOfMeasure2 := ItemUnitOfMeasure2.Code;
        NewUnitOfMeasure3 := ItemUnitOfMeasure3.Code;

        // Exercise: Create Put Away.
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Put-away", LocationWhite.Code, PurchaseHeader."No.",
          WarehouseActivityLine."Action Type"::Place);
        ExpectedQuantity := WarehouseActivityLine.Quantity / ItemUnitOfMeasure."Qty. per Unit of Measure";

        // Verify: Verify the values on Whse Activity Line.
        VerifyWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Put-away", LocationWhite.Code, PurchaseHeader."No.",
          WarehouseActivityLine."Action Type"::Place, ExpectedQuantity, ItemUnitOfMeasure2.Code,
          ItemUnitOfMeasure2."Qty. per Unit of Measure");

        if ChangeUOM then begin
            // Exercise: Change Unit Of Measure on Whse Activity Line.
            UnitOfMeasureType := UnitOfMeasureType::Sales;
            LibraryWarehouse.ChangeUnitOfMeasure(WarehouseActivityLine);

            // Verify: Verify the values on Whse Activity Line.
            VerifyWhseActivityLine(
              WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Put-away", LocationWhite.Code, PurchaseHeader."No.",
              WarehouseActivityLine."Action Type"::Place, ExpectedQuantity / 2,
              ItemUnitOfMeasure3.Code, ItemUnitOfMeasure3."Qty. per Unit of Measure");
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UOMOnWarehouseShipmentLine()
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        SalesHeader: Record "Sales Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ExpectedQuantity: Decimal;
    begin
        // Setup: Create Item with multiple Item Unit Of Measure, create and release Purchase Order, create Whse Receipt. Register Put Away. Create and release Sales Order.
        Initialize();
        PostWhseReceiptWithUOMAndCreateSalesHeader(ItemUnitOfMeasure, ExpectedQuantity, SalesHeader, 1);

        // Exercise: Create and release Warehouse Shipment.
        CreateAndReleaseWhseShipment(SalesHeader, WarehouseShipmentHeader);

        // Verify: Verify that values on Whse Shipment Line.
        FindWhseShipmentNo(WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
        WarehouseShipmentLine.TestField("Unit of Measure Code", ItemUnitOfMeasure.Code);
        WarehouseShipmentLine.TestField("Qty. per Unit of Measure", ItemUnitOfMeasure."Qty. per Unit of Measure");
        WarehouseShipmentLine.TestField(Quantity, ExpectedQuantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UOMOnWarehouseReceiptWithSpecialOrder()
    begin
        // Setup.
        Initialize();
        UOMOnWarehouseEntriesWithSpecialOrder(false);  // UOM on Warehouse Receipt.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UOMOnPutAwayWithSpecialOrder()
    begin
        // Setup.
        Initialize();
        UOMOnWarehouseEntriesWithSpecialOrder(true);  // UOM on Put Away.
    end;

    local procedure UOMOnWarehouseEntriesWithSpecialOrder(UOMOnPutAway: Boolean)
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemUnitOfMeasure2: Record "Item Unit of Measure";
        ItemUnitOfMeasure3: Record "Item Unit of Measure";
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Integer;
        ExpectedQuantity: Decimal;
    begin
        // Create multiple Item Unit Of Measure, Vendor, create and release Special Order, create Requisition Line. Get sales Order and perform Carry out Action Message, Create Whse Receipt.
        CreateMultipleItemUnitOfMeasureSetup(Item, ItemUnitOfMeasure, ItemUnitOfMeasure2, ItemUnitOfMeasure3);
        Quantity := LibraryRandom.RandInt(100);
        CreateSpecialOrderWithItemUnitOfMeasureSetup(PurchaseHeader, SalesHeader, Item."No.", Quantity, LocationWhite.Code);

        // Exercise: Create Whse Receipt.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // Verify: Verify the Unit Of Measure entries on Whse Receipt Line.
        FindWarehouseReceiptNo(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        WarehouseReceiptLine.TestField("Unit of Measure Code", ItemUnitOfMeasure3.Code);
        WarehouseReceiptLine.TestField("Qty. per Unit of Measure", ItemUnitOfMeasure3."Qty. per Unit of Measure");  // Value required.

        if UOMOnPutAway then begin
            // Exercise: Craete Put away.
            PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
            FindWhseActivityLine(
              WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Put-away", LocationWhite.Code, PurchaseHeader."No.",
              WarehouseActivityLine."Action Type"::Place);
            ExpectedQuantity := WarehouseActivityLine.Quantity / ItemUnitOfMeasure."Qty. per Unit of Measure";

            // Verify: Verify the Unit Of Measure entries on Whse Put Away.
            VerifyWhseActivityLine(
              WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Put-away", LocationWhite.Code, PurchaseHeader."No.",
              WarehouseActivityLine."Action Type"::Place, ExpectedQuantity,
              ItemUnitOfMeasure2.Code, ItemUnitOfMeasure2."Qty. per Unit of Measure");
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UOMOnRegisteredPutAwayWithSpecialOrder()
    begin
        // Setup.
        Initialize();
        UOMOnWhseDocumentsWithSpecialOrder(true, false);  // UOM on Registered Put Away TRUE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UOMOnRegisteredPickWithSpecialOrder()
    begin
        // Setup.
        Initialize();
        UOMOnWhseDocumentsWithSpecialOrder(false, true);  // UOM Registered Pick TRUE.
    end;

    local procedure UOMOnWhseDocumentsWithSpecialOrder(UOMOnRegisteredPutAway: Boolean; UOMOnRegisteredPick: Boolean)
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemUnitOfMeasure2: Record "Item Unit of Measure";
        ItemUnitOfMeasure3: Record "Item Unit of Measure";
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityLine2: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        Quantity: Integer;
    begin
        // Create multiple Item Unit Of Measure, Vendor, create and release Special Order, create Requisition Line. Get sales Order and perform Carry out Action Message, Create Whse Receipt.
        CreateMultipleItemUnitOfMeasureSetup(Item, ItemUnitOfMeasure, ItemUnitOfMeasure2, ItemUnitOfMeasure3);
        Quantity := LibraryRandom.RandInt(100);
        CreateSpecialOrderWithItemUnitOfMeasureSetup(PurchaseHeader, SalesHeader, Item."No.", Quantity, LocationWhite.Code);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWarehouseReceiptNo(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Put-away", LocationWhite.Code, PurchaseHeader."No.",
          WarehouseActivityLine."Action Type"::Place);

        // Exercise: Register the Put Away.
        RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");

        if UOMOnRegisteredPutAway then
            // Verify: Verify the Unit Of Measure entries on Registered Put Away.
            VerifyRegisteredWhseActivityLine(
            WarehouseActivityLine, ItemUnitOfMeasure2.Code, ItemUnitOfMeasure2."Qty. per Unit of Measure", WarehouseActivityLine.Quantity,
            '');

        if UOMOnRegisteredPick then begin
            CreateAndReleaseWhseShipment(SalesHeader, WarehouseShipmentHeader);
            LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
            FindWhseActivityLine(
              WarehouseActivityLine2, WarehouseActivityLine2."Activity Type"::Pick, LocationWhite.Code, SalesHeader."No.",
              WarehouseActivityLine2."Action Type"::Place);

            // Exercise: Register the Pick created.
            RegisterWarehouseActivity(SalesHeader."No.", WarehouseActivityLine2."Activity Type"::Pick);

            // Verify: Verify the Unit Of Measure entries on Registerd Pick.
            VerifyRegisteredWhseActivityLine(
              WarehouseActivityLine2, ItemUnitOfMeasure3.Code, ItemUnitOfMeasure3."Qty. per Unit of Measure",
              WarehouseActivityLine2.Quantity, '');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UOMOnWarehouseShipmentLineWithPartialQuantity()
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        ExpectedQuantity: Decimal;
    begin
        // Setup: Create Item with multiple Item Unit Of Measure, create and release Purchase Order, create Whse Receipt. Register Put Away. Create and release Sales Order.
        Initialize();
        PostWhseReceiptWithUOMAndCreateSalesHeader(ItemUnitOfMeasure, ExpectedQuantity, SalesHeader, 2);

        // Exercise: Create and release Warehouse Shipment.
        CreateAndReleaseWhseShipment(SalesHeader, WarehouseShipmentHeader);

        // Verify: Verify that values on Whse Shipment Line.
        FindWhseShipmentNo(WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
        WarehouseShipmentLine.TestField("Unit of Measure Code", ItemUnitOfMeasure.Code);
        WarehouseShipmentLine.TestField("Qty. per Unit of Measure", ItemUnitOfMeasure."Qty. per Unit of Measure");
        WarehouseShipmentLine.TestField(Quantity, ExpectedQuantity);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PickFromPurchaseReturnOrderWithoutStrictExpirationSerialAndLot()
    begin
        // Setup.
        Initialize();
        PickFromPurchaseReturnOrder(false);  // Strict Expiration Posting FALSE.
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PickFromPurchaseReturnOrderWithStrictExpirationSerialAndLot()
    begin
        // Setup.
        Initialize();
        PickFromPurchaseReturnOrder(true);  // Strict Expiration Posting TRUE.
    end;

    local procedure PickFromPurchaseReturnOrder(StrictExpirationPosting: Boolean)
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Quantity: Decimal;
    begin
        // Create Item with Item Tracking Code, update Inventory, create and release Purchase Return Order and Create Warehouse Shipment.
        CreateItemTrackingCode(ItemTrackingCode, true, true, StrictExpirationPosting);  // Serial No and Lot No.
        CreateItemWithTrackingCode(Item, ItemTrackingCode.Code);
        LotSpecific := true;  // Assign value to Global variable.
        Quantity := LibraryRandom.RandInt(10);  // Integer value Required.
        TrackingQuantity := Quantity;  // Assign value to Global variable.
        UpdateInventoryAndAssignTrackingInWhseItemJournal(LocationWhite, Item, Quantity);
        CreateAndReleasePurchaseReturnOrder(PurchaseHeader, Item."No.", Quantity, LocationWhite.Code);
        LibraryWarehouse.CreateWhseShipmentFromPurchaseReturnOrder(PurchaseHeader);
        SelectWhseShipmentHeader(
          WarehouseShipmentHeader, WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Purchase Return Order",
          PurchaseHeader."No.");

        // Exercise: Create Pick.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // Verify: Verify the Item Tracking applied in the Item Ledger Entries and values on Pick Line.
        VerifyTrackingOnItemLedgerEntry(Item."No.", Quantity);
        VerifyWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationWhite.Code, PurchaseHeader."No.",
          WarehouseActivityLine."Action Type"::Take, 1, Item."Base Unit of Measure", WarehouseActivityLine."Qty. per Unit of Measure");

        if StrictExpirationPosting then begin
            // Exercise: Register Pick and Post Whse. Shipment.
            AssignSerialNoAndLotNoToWhseActivityLine(
              WarehouseActivityLine, WarehouseActivityLine."Action Type"::Take, Item."No.", LocationWhite.Code, PurchaseHeader."No.");
            AssignSerialNoAndLotNoToWhseActivityLine(
              WarehouseActivityLine, WarehouseActivityLine."Action Type"::Place, Item."No.", LocationWhite.Code, PurchaseHeader."No.");
            RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
            LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

            // Verify: Verify Whse. Item Tracking Lines in WhseItemTrackingLinesPageHandler and the values on the Posted Whse. Shipment.
            VerifyTracking := true;  // Assign value to Global variable.
            VerifyPostedWhseShipmentLine(
              PurchaseHeader."No.", WarehouseShipmentHeader."Zone Code", Quantity, Item."Base Unit of Measure",
              WarehouseShipmentLine."Qty. per Unit of Measure", LocationWhite.Code);
        end;
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PickFromPurchaseReturnOrderWithoutStrictExpirationWithSerialNo()
    begin
        // Setup.
        Initialize();
        PickFromPurchaseReturnOrderWithSerialNo(false);  // Strict Expiration Posting FALSE.
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PickFromPurchaseReturnOrderWithStrictExpirationWithSerialNo()
    begin
        // Setup.
        Initialize();
        PickFromPurchaseReturnOrderWithSerialNo(true);  // Strict Expiration Posting TRUE.
    end;

    local procedure PickFromPurchaseReturnOrderWithSerialNo(StrictExpirationPosting: Boolean)
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Quantity: Decimal;
    begin
        // Create Item with Item Tracking Code, update Inventory, create and release Purchase Return Order and Create Warehouse Shipment.
        CreateItemTrackingCode(ItemTrackingCode, false, true, StrictExpirationPosting);  // Serial No. Only.
        CreateItemWithTrackingCode(Item, ItemTrackingCode.Code);
        LotSpecific := false;  // Assign value to Global variable.
        Quantity := LibraryRandom.RandInt(10);  // Integer value Required.
        TrackingQuantity := Quantity;  // Assign value to Global variable.
        UpdateInventoryAndAssignTrackingInWhseItemJournal(LocationWhite, Item, Quantity);
        CreateAndReleasePurchaseReturnOrder(PurchaseHeader, Item."No.", Quantity, LocationWhite.Code);
        LibraryWarehouse.CreateWhseShipmentFromPurchaseReturnOrder(PurchaseHeader);
        SelectWhseShipmentHeader(
          WarehouseShipmentHeader, WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Purchase Return Order",
          PurchaseHeader."No.");

        // Exercise: Create Pick.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // Verify: Verify the Item Tracking applied in the Item Ledger Entries and values on Pick Line.
        LotSpecific := false;  // Assign value to Global variable.
        VerifyTrackingOnItemLedgerEntry(Item."No.", Quantity);
        VerifyWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationWhite.Code, PurchaseHeader."No.",
          WarehouseActivityLine."Action Type"::Take, 1, Item."Base Unit of Measure", WarehouseActivityLine."Qty. per Unit of Measure");

        if StrictExpirationPosting then begin
            // Exercise: Register whse Activity and Post Whse. Shipment.
            RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
            LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

            // Verify: Verify the values on Posted Whse. Shipment Line and Whse. Item Tracking Lines through WhseItemTrackingLinesPageHandler.
            VerifyTracking := true;  // Assign value to Global variable.
            VerifyPostedWhseShipmentLine(
              PurchaseHeader."No.", WarehouseShipmentHeader."Zone Code", Quantity, Item."Base Unit of Measure",
              WarehouseShipmentLine."Qty. per Unit of Measure", LocationWhite.Code);
        end;
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PickFromSalesOrderWithoutStrictExpirationSerialAndLot()
    begin
        // Setup.
        Initialize();
        PickFromSalesOrder(false);  // Strict Expiration Posting FALSE.
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PickFromSalesOrderWithStrictExpirationSerialAndLot()
    begin
        // Setup.
        Initialize();
        PickFromSalesOrder(true);  // Strict Expiration Posting TRUE.
    end;

    local procedure PickFromSalesOrder(StrictExpirationPosting: Boolean)
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Quantity: Decimal;
    begin
        // Create Item with Item Tracking Code, update Inventory, create and release Sales Order and create Warehouse Shipment.
        CreateItemTrackingCode(ItemTrackingCode, true, true, StrictExpirationPosting);  // Serial No and Lot No.
        CreateItemWithTrackingCode(Item, ItemTrackingCode.Code);
        LotSpecific := true;  // Assign value to Global variable.
        Quantity := LibraryRandom.RandInt(10);  // Integer value Required.
        TrackingQuantity := Quantity;  // Assign value to Global variable.
        UpdateInventoryAndAssignTrackingInWhseItemJournal(LocationWhite, Item, Quantity);
        CreateAndReleaseSalesOrderWithVariant(SalesHeader, SalesLine, Item."No.", Quantity, LocationWhite.Code, '');
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        SelectWhseShipmentHeader(
          WarehouseShipmentHeader, WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");

        // Exercise: Create Pick.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // Verify: Verify the Item Tracking applied in the Item Ledger Entries and values on Pick Line.
        VerifyTrackingOnItemLedgerEntry(Item."No.", Quantity);
        VerifyWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationWhite.Code, SalesHeader."No.",
          WarehouseActivityLine."Action Type"::Take, 1, Item."Base Unit of Measure", WarehouseActivityLine."Qty. per Unit of Measure");

        if StrictExpirationPosting then begin
            // Exercise: Register Pick and Post Whse. Shipment.
            AssignSerialNoAndLotNoToWhseActivityLine(
              WarehouseActivityLine, WarehouseActivityLine."Action Type"::Take, Item."No.", LocationWhite.Code, SalesHeader."No.");
            AssignSerialNoAndLotNoToWhseActivityLine(
              WarehouseActivityLine, WarehouseActivityLine."Action Type"::Place, Item."No.", LocationWhite.Code, SalesHeader."No.");
            RegisterWarehouseActivity(SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
            LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

            // Verify: Verify Whse. Item Tracking Lines in WhseItemTrackingLinesPageHandler and the values on the Posted Whse. Shipment Line.
            VerifyTracking := true;  // Assign value to Global variable.
            VerifyPostedWhseShipmentLine(
              SalesHeader."No.", WarehouseShipmentHeader."Zone Code", Quantity, Item."Base Unit of Measure",
              WarehouseShipmentLine."Qty. per Unit of Measure", LocationWhite.Code);
        end;
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PickFromSalesOrderWithoutStrictExpirationWithSerialNo()
    begin
        // Setup.
        Initialize();
        PickFromSalesOrderWithSerialNo(false);  // Strict Expiration Posting FALSE.
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PickFromSalesOrderWithStrictExpirationWithSerialNo()
    begin
        // Setup.
        Initialize();
        PickFromSalesOrderWithSerialNo(true);  // Strict Expiration Posting TRUE.
    end;

    local procedure PickFromSalesOrderWithSerialNo(StrictExpirationPosting: Boolean)
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Quantity: Decimal;
    begin
        // Create Item with Item Tracking Code, update Inventory, create and release Sales Order and Create Warehouse Shipment.
        CreateItemTrackingCode(ItemTrackingCode, false, true, StrictExpirationPosting);  // Serial No. Only.
        CreateItemWithTrackingCode(Item, ItemTrackingCode.Code);
        LotSpecific := false;  // Assign value to Global variable.
        Quantity := LibraryRandom.RandInt(10);  // Integer value Required.
        TrackingQuantity := Quantity;  // Assign value to Global variable.
        UpdateInventoryAndAssignTrackingInWhseItemJournal(LocationWhite, Item, Quantity);
        CreateAndReleaseSalesOrderWithVariant(SalesHeader, SalesLine, Item."No.", Quantity, LocationWhite.Code, '');
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        SelectWhseShipmentHeader(
          WarehouseShipmentHeader, WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");

        // Exercise: Create Pick.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // Verify: Verify the values on Pick Line and Whse. Item Tracking Lines applied in Item Ledger Entries.
        LotSpecific := false;  // Assign value to Global variable.
        VerifyTrackingOnItemLedgerEntry(Item."No.", Quantity);
        VerifyWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationWhite.Code, SalesHeader."No.",
          WarehouseActivityLine."Action Type"::Take, 1, Item."Base Unit of Measure", WarehouseActivityLine."Qty. per Unit of Measure");

        if StrictExpirationPosting then begin
            // Exercise: Register whse Activity and Post Whse. Shipment.
            RegisterWarehouseActivity(SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
            LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

            // Verify: Verify the values on Posted Whse. Shipment Line and Whse. Item tracking Lines in WhseItemTrackingLinesPageHandler.
            VerifyTracking := true;  // Assign value to Global variable.
            VerifyPostedWhseShipmentLine(
              SalesHeader."No.", WarehouseShipmentHeader."Zone Code", Quantity, Item."Base Unit of Measure",
              WarehouseShipmentLine."Qty. per Unit of Measure", LocationWhite.Code);
        end;
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure FullWarehousePutAwayFromPurchaseWithMultipleLinesAndLotNo()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Setup: Create Item with Item Tracking Code, create and release Purchase Order with multiple Lines, Warehouse Receipt.
        Initialize();
        TrackingQuantity := LibraryRandom.RandInt(10);  // Integer value Required.
        CreateLotTrackedItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLinesAndReleaseDocument(
          PurchaseHeader, Item."No.", LocationWhite.Code, TrackingQuantity, LibraryRandom.RandInt(10), true);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWarehouseReceiptNo(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        AssignTrackingToMultipleWhseReceiptLines(PurchaseHeader."No.", WarehouseReceiptLine."Source Document"::"Purchase Order");  // Assign Tracking on Page Handler LotItemTrackingPageHandler.

        // Exercise: Post Warehouse Receipt.
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // Verify: Verify the values on Warehouse Activity Lines and the Whse. Item Tracking applied in ItemTrackingPageHandler.
        VerifyTracking := true;  // Assign value to Global variable.
        VerifyMultipleWhseActivityLines(
          WarehouseActivityLine, TrackingQuantity, WarehouseActivityLine."Activity Type"::"Put-away", PurchaseHeader."No.",
          LocationWhite.Code, Item."Base Unit of Measure", WarehouseReceiptLine."Qty. per Unit of Measure");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure PartialWarehousePutAwayFromPurchaseWithMultipleLinesAndLotNo()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Setup: Create Item with Item Tracking Code, create and release Purchase Order with multiple Lines, Warehouse Receipt and post Warehouse Receipt.
        Initialize();
        TrackingQuantity := LibraryRandom.RandInt(10);  // Integer value Required.
        CreateLotTrackedItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLinesAndReleaseDocument(
          PurchaseHeader, Item."No.", LocationWhite.Code, TrackingQuantity, LibraryRandom.RandInt(10), true);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWarehouseReceiptNo(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        AssignTrackingToMultipleWhseReceiptLines(PurchaseHeader."No.", WarehouseReceiptLine."Source Document"::"Purchase Order");  // Assign Tracking on Page Handler LotItemTrackingPageHandler.
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // Exercise: Update Quantity To Handle on Whse Activity Lines.
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Put-away", LocationWhite.Code, PurchaseHeader."No.",
          WarehouseActivityLine."Action Type"::Place);
        UpdateQuantityToHandleOnWhseActivityLines(WarehouseActivityLine, TrackingQuantity / 2);

        // Verify: Verify the values on Warehouse Activity Lines and Whse. Item Tracking applied in ItemTrackingPageHandler.
        VerifyTracking := true;  // Assign value to Global variable.
        VerifyMultipleWhseActivityLines(
          WarehouseActivityLine, TrackingQuantity, WarehouseActivityLine."Activity Type"::"Put-away", PurchaseHeader."No.",
          LocationWhite.Code, Item."Base Unit of Measure", WarehouseReceiptLine."Qty. per Unit of Measure");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseReceiptWithLotNo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        DocumentNo: Code[20];
    begin
        // Setup: Create Item with Item Tracking Code, create Purchase Order and open Item Tracking Lines.
        Initialize();
        CreateLotTrackedItem(Item);
        TrackingQuantity := LibraryRandom.RandInt(10);  // Integer value Required.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLineWithLocationAndVariant(PurchaseHeader, PurchaseLine, Item."No.", '', TrackingQuantity, '');  // Location Blank.
        PurchaseLine.OpenItemTrackingLines();

        // Exercise: Post Purchase Order as Receive.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Verify: Verify the values on Purchase Receipt Line and the Item Tracking Lines in ItemTrackingPageHandler.
        VerifyTracking := true;  // Assign value to Global variable.
        VerifyPurchaseReceiptLine(DocumentNo, PurchaseHeader."No.", TrackingQuantity, '');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostedInventoryPutAwayWithExpirationDateAndLot()
    begin
        // Setup.
        Initialize();
        ExpirationDateOnInventoryPutAwayAndPick(false);  // Expiration Date on Posted Inventory Pick -FALSE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostedInventoryPickWithExpirationDateAndLot()
    begin
        // Setup.
        Initialize();
        ExpirationDateOnInventoryPutAwayAndPick(true);  // Expiration Date on Posted Inventory Pick -TRUE.
    end;

    local procedure ExpirationDateOnInventoryPutAwayAndPick(ExpirationDateOnPostedInventoryPick: Boolean)
    var
        Item: Record Item;
        Bin: Record Bin;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Create Item with Item Tracking Code, create and release Purchase Order, update Expiration Date On Reservation Entry. Create Inventory Put Away.
        TrackingQuantity := LibraryRandom.RandInt(10);  // Integer value Required.
        LibraryWarehouse.FindBin(Bin, LocationSilver.Code, '', 1);  // Find Bin of Index 1.
        CreateLotTrackedItem(Item);
        CreateAndReleasePurchaseOrder(PurchaseHeader, Item."No.", LocationSilver.Code, TrackingQuantity, '', '', true);
        UpdateExpirationDateOnReservationEntry(LocationSilver.Code, Item."No.");
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Purchase Order", PurchaseHeader."No.", true, false, false);
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Invt. Put-away", LocationSilver.Code, PurchaseHeader."No.",
          WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
        UpdateBinOnActivityLine(WarehouseActivityLine, Bin.Code);

        // Exercise: Post Inventory Put Away.
        PostInventoryPut(PurchaseHeader."No.");

        // Verify: Verify the entries on Posted Inventory Put Away Line. Verify that the same Expiration date on Inventory Put Away as Purchase Order. Verify Item tracking applied through ItemTrackingPageHandler.
        LotSpecific := true;  // Assign values to Global variables.
        VerifyTracking := true;
        VerifyPostedInventoryPutLine(PurchaseHeader."No.", LocationSilver.Code, Item."No.", WorkDate(), Bin.Code);

        if ExpirationDateOnPostedInventoryPick then begin
            // Exercise: Create Inventory Pick.
            Clear(WarehouseActivityLine);
            CreateAndReleaseSalesOrderWithVariant(SalesHeader, SalesLine, Item."No.", TrackingQuantity, LocationSilver.Code, '');
            SalesLine.OpenItemTrackingLines();
            LibraryWarehouse.CreateInvtPutPickMovement(
              WarehouseActivityHeader."Source Document"::"Sales Order", SalesHeader."No.", false, true, false);
            FindWhseActivityLine(
              WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Invt. Pick", LocationSilver.Code, SalesHeader."No.",
              WarehouseActivityLine."Action Type"::Take);
            WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
            PostInventoryPick(SalesHeader."No.", false);

            // Verify: Verify the Posted Inventory Pick Line. Verify that the same Expiration date on Inventory Pick as on Sales Order. Verify Item tracking applied through ItemTrackingPageHandler.
            VerifyTracking := true;   // Assign value to Global variable.
            VerifyPostedInventoryPickLine(SalesHeader."No.", LocationSilver.Code, Item."No.", WorkDate(), Bin.Code);
        end;
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure WarehousePickWithExpirationDateAndLot()
    begin
        // Setup.
        Initialize();
        ExpirationDateOnWhsePickLine(false);  // Change Expiration Date On Whse Pick - FALSE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure WarehousePickWithErrorChangedExpirationDateAndLot()
    begin
        // Setup.
        Initialize();
        ExpirationDateOnWhsePickLine(true);  // Change Expiration Date On Whse Pick - TRUE.
    end;

    local procedure ExpirationDateOnWhsePickLine(ChangeExpirationDate: Boolean)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Create Item with Item Tracking Code, create and release Purchase Order with multiple Lines and Warehouse Receipt. Update Expiration Date on Reservation Entry, post and register the Whse Receipt.
        // Create and release Sales Order and Whse Shipment.
        TrackingQuantity := LibraryRandom.RandInt(5);  // Integer value Required.
        WarehousePickChangeExpirationDateSetup(Item, SalesHeader, WarehouseShipmentHeader);

        // Exercise: Create Pick.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationWhite.Code, SalesHeader."No.",
          WarehouseActivityLine."Action Type"::Place);

        if ChangeExpirationDate then begin
            // Exercise: Change Expiration Date On Pick Line.
            asserterror ChangeExpirationDateOnActivityLine(WarehouseActivityLine);

            // Verify: Verify that Expiration Date can not be changed.
            Assert.ExpectedError(ExpirationDateError)
        end else begin
            UpdateTrackingOnWhseActivityLine(
              WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationWhite.Code, SalesHeader."No.");
            RegisterWarehouseActivity(SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
            LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

            // Verify: Verify Posted Whse Shipment Line. Verify Item tracking applied through ItemTrackingPageHandler.
            VerifyTracking := true;  // Assign value to Global variable.
            VerifyPostedWhseShipmentLine(
              SalesHeader."No.", WarehouseShipmentHeader."Zone Code", TrackingQuantity, Item."Base Unit of Measure",
              WarehouseActivityLine."Qty. per Unit of Measure", LocationWhite.Code);
        end;
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPutAwayWithExpirationDate()
    begin
        // Setup.
        Initialize();
        ExpirationDateOnInventoryPutAway(false);  // Change Expiration Date On Inventory Put Away FALSE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPutAwayWithErrorChangedExpirationDate()
    begin
        // Setup.
        Initialize();
        ExpirationDateOnInventoryPutAway(true);   // Change Expiration Date On Inventory Put Away TRUE.
    end;

    local procedure ExpirationDateOnInventoryPutAway(ChangeExpirationDate: Boolean)
    var
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Create Item with Item Tracking Code, create and release Purchase Order with multiple Lines.
        TrackingQuantity := LibraryRandom.RandInt(10);  // Integer value Required.

        LibraryWarehouse.CreateLocationWMS(Location, true, true, true, false, false);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', LibraryRandom.RandIntInRange(5, 10), false);
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 1);  // Find Bin of Index 1.
        CreateLotTrackedItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLinesAndReleaseDocument(
          PurchaseHeader, Item."No.", Location.Code, TrackingQuantity, LibraryRandom.RandInt(5), true);
        UpdateExpirationDateOnReservationEntry(Location.Code, Item."No.");

        // Exercise: Create Inventory Put Away.
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Purchase Order", PurchaseHeader."No.", true, false, false);

        // Verify: Verify the values on Whse Activity Line. Verify the same Expiration Date as on Purchase Order. Verify Item tracking applied through ItemTrackingPageHandler.
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Invt. Put-away", Location.Code, PurchaseHeader."No.",
          WarehouseActivityLine."Action Type"::Place);
        VerifyTracking := true;  // Assign value to Global variable.
        WarehouseActivityLine.TestField("Expiration Date", WorkDate());
        VerifyMultipleWhseActivityLines(
          WarehouseActivityLine, TrackingQuantity, WarehouseActivityLine."Activity Type"::"Invt. Put-away", PurchaseHeader."No.",
          Location.Code, Item."Base Unit of Measure", WarehouseActivityLine."Qty. per Unit of Measure");

        if ChangeExpirationDate then begin
            // Exercise: Change Expiration Date on Warehouse Activity Line or Post Inventory Pick.
            asserterror ChangeExpirationDateOnActivityLine(WarehouseActivityLine);

            // Verify: Verify the Expiration Date can not be changed.
            Assert.ExpectedError(ExpirationDateError);
        end;
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure ExpirationDateOnWarehousePutAwayWithLotNo()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Setup: Create Item with Item Tracking Code, create and release Purchase Order with multiple Lines and Warehouse Receipt. Update Expiration Date.
        Initialize();
        TrackingQuantity := LibraryRandom.RandInt(10);  // Integer value Required.
        CreateLotTrackedItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLinesAndReleaseDocument(
          PurchaseHeader, Item."No.", LocationWhite.Code, TrackingQuantity, LibraryRandom.RandInt(5), true);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        UpdateTrackingOnWhseReceiptLines(WarehouseReceiptHeader, WarehouseReceiptLine, PurchaseHeader."No.");
        UpdateExpirationDateOnReservationEntry(LocationWhite.Code, Item."No.");

        // Exercise: Post Warehouse Receipt.
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // Verify: Verify the values on Warehouse Activity Lines. Verify Item tracking applied through ItemTrackingPageHandler.
        VerifyTracking := true;  // Assign value to Global variable.
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Put-away", LocationWhite.Code, PurchaseHeader."No.",
          WarehouseActivityLine."Action Type"::Place);
        VerifyMultipleWhseActivityLines(
          WarehouseActivityLine, TrackingQuantity, WarehouseActivityLine."Activity Type"::"Put-away", PurchaseHeader."No.",
          LocationWhite.Code, Item."Base Unit of Measure", WarehouseReceiptLine."Qty. per Unit of Measure");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure WarehousePickWithUpdateBinOnWhseShipmentAndExpirationDate()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        Bin: Record Bin;
        Bin2: Record Bin;
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Setup: Create Item with Item Tracking Code, update Item Inventory, create and release Sales Order.
        Initialize();
        LibraryWarehouse.FindBin(Bin, LocationSilver2.Code, '', 1);  // Find Bin of Index 1.
        TrackingQuantity := LibraryRandom.RandInt(5);  // Integer value Required.
        CreateLotTrackedItem(Item);
        UpdateItemInventory(Item."No.", LocationSilver2.Code, Bin.Code, TrackingQuantity, true);  // Value required.
        CreateAndReleaseSalesOrderWithVariant(SalesHeader, SalesLine, Item."No.", TrackingQuantity, LocationSilver2.Code, '');
        SalesLine.OpenItemTrackingLines();
        CreateAndReleaseWhseShipment(SalesHeader, WarehouseShipmentHeader);
        UpdateExpirationDateOnReservationEntry(LocationSilver2.Code, Item."No.");
        LibraryWarehouse.ReopenWhseShipment(WarehouseShipmentHeader);
        LibraryWarehouse.FindBin(Bin2, LocationSilver2.Code, '', 2);  // Find Bin of Index 2.

        // Exercise: Update Bin on Warehouse Shipment Line and create Pick.
        UpdateBinOnWarehouseShipmentLine(Item."No.", Bin2.Code);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // Verify: Verify the values on Whse. Activity Line. Verify the Tracking applied in ItemTrackingPageHandler.
        VerifyTracking := true;  // Assign Value to Global variable.
        VerifyWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationSilver2.Code, SalesHeader."No.",
          WarehouseActivityLine."Action Type"::Take, TrackingQuantity, Item."Base Unit of Measure", SalesLine."Qty. per Unit of Measure");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,WhseItemTrackingLinesHandler,ItemTrackingSummaryHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure WhsePickChangeExpirationDateWithWhseReclassificationJournal()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Setup: Create Item with Item Tracking Code, create and release Purchase Order with multiple Lines and Warehouse Receipt. Update Expiration Date on Reservation Entry, post and register the Whse Receipt.
        // Create and release Sales Order and Whse Shipment.
        Initialize();
        TrackingQuantity := LibraryRandom.RandInt(5);  // Integer value Required.
        WarehousePickChangeExpirationDateSetup(Item, SalesHeader, WarehouseShipmentHeader);
        EnsureTrackingCodeUsesExpirationDate(Item."Item Tracking Code");
        asserterror CreateAndRegisterWarehouseReclassJournal(Item."No.", LocationWhite.Code, TrackingQuantity);
        Assert.ExpectedError(ExpirationDateError);

        // Exercise: Create Pick.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // Verify: Verify the Expiration Date can not be changed. Verify the Tracking applied in ItemTrackingPageHandler.
        VerifyTracking := true;  // Assign Value to Global variable.
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationWhite.Code, SalesHeader."No.",
          WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.TestField("Expiration Date", WorkDate());
        VerifyWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationWhite.Code, SalesHeader."No.",
          WarehouseActivityLine."Action Type"::Take, TrackingQuantity, Item."Base Unit of Measure",
          WarehouseActivityLine."Qty. per Unit of Measure");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,WhseItemTrackingLinesHandler,ItemTrackingSummaryHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure WhsePutAwayChangeExpirationDateWithWhseReclassificationJournal()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        // Setup: Create Item with Item Tracking Code, create and release Purchase Order with multiple Lines and Warehouse Receipt. Update Expiration Date on Reservation Entry, post and register the Whse Receipt.
        Initialize();
        TrackingQuantity := LibraryRandom.RandInt(5);  // Integer value Required.
        CreateLotTrackedItem(Item);
        EnsureTrackingCodeUsesExpirationDate(Item."Item Tracking Code");
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLinesAndReleaseDocument(
          PurchaseHeader, Item."No.", LocationWhite.Code, TrackingQuantity, LibraryRandom.RandIntInRange(2, 5), true);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        UpdateTrackingOnWhseReceiptLines(WarehouseReceiptHeader, WarehouseReceiptLine, PurchaseHeader."No.");
        UpdateExpirationDateOnReservationEntry(LocationWhite.Code, Item."No.");
        PostWhseReceiptAndRegisterWhseActivity(PurchaseHeader."No.");

        // Exercise: Create and register Whse Reclassification Journal.
        asserterror CreateAndRegisterWarehouseReclassJournal(Item."No.", LocationWhite.Code, TrackingQuantity);

        // Verify: Verify the Expiration Date can not be changed.
        Assert.ExpectedError(ExpirationDateError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandlerSerialNo')]
    [Scope('OnPrem')]
    procedure GetBinContentOnMovementWorksheetFromPutAwayWithSerialNo()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        // Setup: Create Item with Item Tracking Code, create and release Purchase Order, Assign serial No. on Purchase Line. Create, Post and register warehouse Receipt.
        Initialize();
        CreateItemTrackingCode(ItemTrackingCode, false, true, false);  // Serial No -True.
        LotSpecific := false;
        CreateItemWithTrackingCode(Item, ItemTrackingCode.Code);
        TrackingQuantity := LibraryRandom.RandInt(10) + 10;  // Integer value Required.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLineWithLocationAndVariant(PurchaseHeader, PurchaseLine, Item."No.", LocationWhite.Code, TrackingQuantity, '');  // Location Blank.
        PurchaseLine.OpenItemTrackingLines();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWarehouseReceiptNo(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
        RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityHeader.Type::"Put-away");

        // Exercise: Get Bin content on Movemt Worksheet.
        GetBinContentFromMovementWorksheet(WhseWorksheetLine, LocationWhite.Code, Item."No.");

        // Verify: Verify Entries on Movement Worksheet. Verify the Tracking applied in ItemTrackingPageHandlerSerialNo.
        VerifyTracking := true;  // Assign value to Global variable.
        VerifyWhseWorksheetLine(WhseWorksheetLine, LocationWhite.Code, Item."No.", Item."Base Unit of Measure", PurchaseLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('LotNoWhseItemTrackingPageHandler,WhseSourceCreateDocumentHandler,MovementCreatedMessageHandler')]
    [Scope('OnPrem')]
    procedure WhseMovementFromMovementWorksheetAfterGetBinContentWithLotNo()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        // Setup: Create Item with Item Tracking code, Assign Lot No tracking and Update expiration Date on Whse. Item Journal. Get Bin Content on Movement Worksheet.
        Initialize();
        TrackingQuantity := LibraryRandom.RandInt(10) + 10;  // Integer value Required.
        CreateItemTrackingCode(ItemTrackingCode, true, false, true);  // Lot No and Strict Expiration Posting True.
        CreateItemWithTrackingCode(Item, ItemTrackingCode.Code);
        UpdateInventoryAndAssignTrackingInWhseItemJournal(LocationWhite, Item, TrackingQuantity);
        GetBinContentFromMovementWorksheet(WhseWorksheetLine, LocationWhite.Code, Item."No.");
        Commit();

        // Exercise: Create Movement from Movement Worksheet.
        WhseWorksheetLine.MovementCreate(WhseWorksheetLine);

        // Verify: Verify the warehouse movement respects the quantities.
        VerifyWhseActivityLineForMovement(Item."No.", LocationWhite.Code, TrackingQuantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure BinCodeWithSalesPurchaseCrossTransaction()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Bin: Record Bin;
        Bin2: Record Bin;
        Bin3: Record Bin;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityLine3: Record "Warehouse Activity Line";
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        Quantity: Decimal;
    begin
        // Setup: Create Item, create Pick from Sales Order, create and post Warehouse Receipt from Purchase Order. Delete shipment and pick created and recreate Shipment and Pick from last Sales order.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.FindBin(Bin, LocationSilver2.Code, '', 1);  // Find Bin of Index 1.
        LibraryWarehouse.FindBin(Bin2, LocationSilver2.Code, '', 2);  // Find Bin of Index 2.
        LibraryWarehouse.FindBin(Bin3, LocationSilver2.Code, '', 3);  // Find Bin of Index 3.
        UpdateBinsOnLocation(LocationSilver2, Bin.Code, Bin2.Code);  // Receipt Bin Code, Shipment Bin Code.
        Quantity := LibraryRandom.RandDec(10, 2) + 10;
        UpdateItemInventory(Item."No.", LocationSilver2.Code, Bin.Code, Quantity, false);  // Use Tracking FALSE.
        UpdateItemInventory(Item."No.", LocationSilver2.Code, Bin2.Code, Quantity, false);  // Use Tracking FALSE.
        UpdateItemInventory(Item."No.", LocationSilver2.Code, Bin3.Code, Quantity, false);  // Use Tracking FALSE.

        CreateSalesOrderWithUpdatedBinAndPickSetup(
          SalesHeader, SalesLine, WarehouseShipmentHeader, Item."No.", LocationSilver2.Code, Bin2.Code, Quantity);
        CreatePutAwayWithPurchaseOrderSetup(
          PurchaseHeader, WarehouseReceiptLine, Item."No.", LocationSilver2.Code, Quantity - 5);
        DeleteWhseActivityLine(WarehouseActivityLine, LocationSilver2.Code, SalesHeader."No.");
        NotificationLifecycleMgt.RecallAllNotifications();
        DeleteWhseShipmentLine(WarehouseShipmentLine, WarehouseShipmentHeader, SalesHeader."No.");

        // Exercise: Recreate Warehouse Shipment and Pick from Sales Order.
        RecreatePickFromSalesOrder(SalesHeader, SalesLine, WarehouseShipmentHeader, Quantity);

        // Verify: Verify Bin Code on Action Type Take of Activity Line is same as shipment code of Location and verify other entries.
        FindWhseActivityLine(
          WarehouseActivityLine3, WarehouseActivityLine3."Activity Type"::Pick, LocationSilver2.Code, SalesHeader."No.",
          WarehouseActivityLine3."Action Type"::Place);
        WarehouseActivityLine3.TestField("Bin Code", Bin2.Code);
        VerifyWhseActivityLine(
          WarehouseActivityLine3, WarehouseActivityLine3."Activity Type"::Pick, LocationSilver2.Code, SalesHeader."No.",
          WarehouseActivityLine3."Action Type"::Take, Quantity, Item."Base Unit of Measure", 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandlerSerialAndLot,QuantityToCreatePageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostedInventoryPutAwayWithSerialAndLotNoAndExpirationDate()
    begin
        // Setup.
        Initialize();
        InventoryPutAwayAndPickWithSerialAndLotNo(false);  // Post Inventory Pick FALSE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandlerSerialAndLot,QuantityToCreatePageHandler,MessageHandler,ItemTrackingSummaryHandler')]
    [Scope('OnPrem')]
    procedure PostedInventoryPickWithSerialAndLotNoAndExpirationDate()
    begin
        // Setup.
        Initialize();
        InventoryPutAwayAndPickWithSerialAndLotNo(true);  // Post Inventory Pick TRUE.
    end;

    local procedure InventoryPutAwayAndPickWithSerialAndLotNo(PostInventoryPick: Boolean)
    var
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingCode2: Record "Item Tracking Code";
        Item: Record Item;
        Item2: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        WarehouseRequest: Record "Warehouse Request";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        Bin: Record Bin;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        // Create Items with Item Tracking code, create and release Purchase Order with multiple lines, create Inventory Put-Away.
        CreateItemTrackingCode(ItemTrackingCode, false, true, false);  // Serial No. specific.
        CreateItemTrackingCode(ItemTrackingCode2, true, false, false);  // Lot No. specific.
        CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code, true);  // Serial No. specific.
        CreateItemWithItemTrackingCode(Item2, ItemTrackingCode2.Code, false);  // Lot No. specific.
        LibraryWarehouse.FindBin(Bin, LocationSilver.Code, '', 1);  // Find Bin of Index 1.
        TrackingQuantity := LibraryRandom.RandInt(5) + 5;  // Global Tracking Quantity.
        CreatePurchaseOrderWithMultipleLines(
          PurchaseHeader, PurchaseLine, PurchaseLine2, Item."No.", Item2."No.", LocationSilver.Code, TrackingQuantity, Bin.Code);
        Serial := true;  // Global Serial.
        PurchaseLine.OpenItemTrackingLines();  // Open Tracking on Page Handler.
        Serial := false;  // Global Serial.
        PurchaseLine2.OpenItemTrackingLines();  // Open Tracking on Page Handler.
        UpdateExpirationDate(LocationSilver.Code, Item."No.", Item2."No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        SelectWarehouseRequestAndCreateInvPutAwayPick(
          WarehouseRequest, PurchaseHeader."No.", WarehouseRequest."Source Document"::"Purchase Order", DATABASE::"Purchase Line",
          LocationSilver.Code, true);  // PutAway Created.
        FindWhseActivityLineAndInvPutAwayPick(
          WarehouseActivityHeader, WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Invt. Put-away", LocationSilver.Code,
          PurchaseHeader."No.", WarehouseActivityLine."Action Type"::Place,
          WarehouseActivityHeader."Source Document"::"Purchase Order");

        // Exercise: Post Inventory Put Away.
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, true);

        // Verify: Verify the posted Inventory Put Away Line. Verify the Tracking applied in the handler.
        VerifyTracking := true;  // Assign value to Global variable.
        VerifyPostedInventoryPutLine(PurchaseHeader."No.", LocationSilver.Code, Item."No.", WorkDate(), Bin.Code);

        if PostInventoryPick then begin
            // Exercise: Create Sales Order with multiple lines and Inv. Pick. Post Invt. Pick.
            CreateSalesOrderWithMultipleLines(
              SalesHeader, SalesLine, SalesLine2, Item."No.", Item2."No.", LocationSilver.Code, TrackingQuantity);
            SelectEntries := true;  // Assign value to Global variable.
            SalesLine.OpenItemTrackingLines();  // Open Tracking on Page Handler.
            SalesLine2.OpenItemTrackingLines();  // Open Tracking on Page Handler.
            Clear(WarehouseActivityLine);
            LibrarySales.ReleaseSalesDocument(SalesHeader);
            SelectWarehouseRequestAndCreateInvPutAwayPick(
              WarehouseRequest, SalesHeader."No.", WarehouseRequest."Source Document"::"Sales Order", DATABASE::"Sales Line",
              LocationSilver.Code, false);  // Pick Created.
            FindWhseActivityLineAndInvPutAwayPick(
              WarehouseActivityHeader, WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Invt. Pick", LocationSilver.Code,
              SalesHeader."No.", WarehouseActivityLine."Action Type"::Take,
              WarehouseActivityHeader."Source Document"::"Sales Order");
            LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, true);

            // Verify: Verify the Posted Inv. Pick.
            VerifyPostedInventoryPickLine(SalesHeader."No.", LocationSilver.Code, Item."No.", WorkDate(), Bin.Code);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseGetBinContentFromItemJournalLine()
    var
        Bin: Record Bin;
        Item: Record Item;
        Quantity: Decimal;
    begin
        // Setup:  Create Item, update Item Inventory.
        Initialize();
        Quantity := LibraryRandom.RandDec(100, 2);
        LibraryWarehouse.FindBin(Bin, LocationSilver2.Code, '', 1);  // Find Bin of Index 1.
        LibraryInventory.CreateItem(Item);
        UpdateItemInventory(Item."No.", LocationSilver2.Code, Bin.Code, Quantity, false);  // Value required.

        // Exercise: Run Warehouse Get Bin Content Report from Item Journal Line.
        RunWarehouseGetBinContentReportFromItemJournalLine(Item."No.");

        // Verify: Verify Item Journal Line.
        VerifyItemJournalLine(Item."No.", Bin."Location Code", Bin.Code, Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandlerSerialNo')]
    [Scope('OnPrem')]
    procedure BinContentWithSerialNo()
    var
        Item: Record Item;
        Bin: Record Bin;
        PurchaseHeader: Record "Purchase Header";
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        // Setup: Create Item with Item Tracking Code, create and release Purchase Order.
        Initialize();
        TrackingQuantity := LibraryRandom.RandInt(10) + 10;  // Integer value Required.
        LibraryWarehouse.FindBin(Bin, LocationGreen.Code, '', 1);  // Find Bin of Index 1.
        CreateItemTrackingCode(ItemTrackingCode, false, true, false);  // Create Iten Tracking with Serial TRUE.
        CreateItemWithTrackingCode(Item, ItemTrackingCode.Code);
        CreateAndReleasePurchaseOrder(PurchaseHeader, Item."No.", LocationGreen.Code, TrackingQuantity, '', Bin.Code, true);

        // Exercise: Post the Purchase Order as Receive.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Verify: Verify Bin Content for the Bin and Tracking applied through ItemTrackingPageHandlerSerialNo.
        VerifyTracking := true;  // Assign value to Global variable.
        VerifyBinContent(Item."No.", LocationGreen.Code, Bin.Code);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure BinContentWithLotNo()
    var
        Item: Record Item;
        Bin: Record Bin;
        PurchaseHeader: Record "Purchase Header";
        Quantity: Integer;
    begin
        // Setup: Create Item with Item Tracking Code, create and release Purchase Order.
        Initialize();
        Quantity := LibraryRandom.RandInt(10) + 10;  // Integer value Required.
        TrackingQuantity := Quantity;
        LibraryWarehouse.FindBin(Bin, LocationSilver.Code, '', 1);  // Find Bin of Index 1.
        CreateLotTrackedItem(Item);
        CreateAndReleasePurchaseOrder(PurchaseHeader, Item."No.", LocationSilver.Code, Quantity, '', Bin.Code, true);

        // Exercise: Post the Purchase Order as Receive.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Verify: Verify Bin Content for the Bin and Tracking applied in ItemTrackingPageHandler.
        VerifyTracking := true;  // Assign value to Global variable.
        VerifyBinContent(Item."No.", LocationSilver.Code, Bin.Code);
    end;

    [Test]
    [HandlerFunctions('LotNoWhseItemTrackingPageHandler,WhseSourceCreateDocumentHandler,MovementCreatedMessageHandler')]
    [Scope('OnPrem')]
    procedure RegisterWhseMovementWithLotNoAndExpirationDate()
    begin
        // Setup.
        Initialize();
        WhseMovementFromMovementWorksheetWithLotNoAndExpirationDate(false);  // Expiarion Date on Registered Pick FALSE.
    end;

    [Test]
    [HandlerFunctions('LotNoWhseItemTrackingPageHandler,WhseSourceCreateDocumentHandler,ItemTrackingPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure RegisterPickWithWhseMovementWithLotNoAndExpirationDate()
    begin
        // Setup.
        Initialize();
        WhseMovementFromMovementWorksheetWithLotNoAndExpirationDate(true);  // Expiarion Date on Registered Pick TRUE.
    end;

    local procedure WhseMovementFromMovementWorksheetWithLotNoAndExpirationDate(ExpirationDateOnRegisteredPick: Boolean)
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseWorksheetLine2: Record "Whse. Worksheet Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityLine2: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Create Item with Item Tracking code, Assign Lot No tracking and update Expiration Date on Whse. Item Journal. Get Bin Content on Movement Worksheet.
        // Create Movement from Movement Worksheet.
        TrackingQuantity := LibraryRandom.RandInt(10) + 10;  // Integer value Required.
        CreateItemTrackingCode(ItemTrackingCode, true, false, true);  // Lot No True, Strict Expiration Posting TRUE.
        CreateItemWithTrackingCode(Item, ItemTrackingCode.Code);
        UpdateInventoryAndAssignTrackingInWhseItemJournal(LocationWhite, Item, TrackingQuantity);
        GetBinContentFromMovementWorksheet(WhseWorksheetLine, LocationWhite.Code, Item."No.");
        UpdateBinAndZoneOnWhseWorksheetLine(WhseWorksheetLine2, LocationWhite.Code);
        Commit();
        WhseWorksheetLine.MovementCreate(WhseWorksheetLine);
        FindWhseMovementLine(WarehouseActivityLine, Item."No.", WarehouseActivityLine."Activity Type"::Movement, LocationWhite.Code, '');
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type"::Movement, WarehouseActivityLine."No.");

        // Exercise: Register The Movement created.
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // Verify: Verify the values on Whse Movement created. Verify the Tracking applied in the handler.
        VerifyTracking := true;  // Assign value to Global variable.
        WarehouseActivityLine.TestField("Expiration Date", WorkDate());
        VerifyRegisteredWhseActivityLine(
          WarehouseActivityLine, Item."Base Unit of Measure", SalesLine."Qty. per Unit of Measure", WarehouseActivityLine.Quantity, '');

        if ExpirationDateOnRegisteredPick then begin
            CreateAndReleaseSalesOrderWithVariant(SalesHeader, SalesLine, Item."No.", TrackingQuantity, LocationWhite.Code, '');
            SalesLine.OpenItemTrackingLines();
            CreateAndReleaseWhseShipment(SalesHeader, WarehouseShipmentHeader);
            LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
            FindWhseActivityLine(
              WarehouseActivityLine2, WarehouseActivityLine2."Activity Type"::Pick, LocationWhite.Code, SalesHeader."No.",
              WarehouseActivityLine2."Action Type"::Take);

            // Exercise: Register the Pick created.
            RegisterWarehouseActivity(SalesHeader."No.", WarehouseActivityLine2."Activity Type"::Pick);

            // Verify: Verify the values on Whse Pick created.
            WarehouseActivityLine2.TestField("Expiration Date", WorkDate());
            VerifyRegisteredWhseActivityLine(
              WarehouseActivityLine2, Item."Base Unit of Measure", SalesLine."Qty. per Unit of Measure", WarehouseActivityLine2.Quantity, '');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeQuantityOnInternalPutAwayPageAfterGetBinContentOnce()
    var
        Item: Record Item;
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
        Quantity: Decimal;
    begin
        // Setup: Create Item, create whse item journal with item then adjust it in item journal.
        // Create Whse. Internal Put-Away by Get Bin Content.
        IsInitialized := false;
        Initialize();
        Quantity := LibraryRandom.RandInt(10);
        WhseInternalPutAwayHeader.Init();
        UpdateInvtAndCreateWhseInternalPutAwayByGetBinContent(Item, WhseInternalPutAwayHeader, Quantity, 1, false); // Get Bin Content once.

        // Exercise: Changing quantity greater than the original one in Whse. Internal Put-Away Line by page.
        asserterror ChangeQuantityInWhseInternalPutAwayLinePage(Item."No.", Quantity + LibraryRandom.RandInt(5));

        // Verify: Verify error message.
        Assert.ExpectedError(QuantityMismatchErr);
    end;

    [Test]
    [HandlerFunctions('WhseSourceCreateDocumentHandler')]
    [Scope('OnPrem')]
    procedure CreatePutAwayFromInternalPutAwayPageAfterGetBinContentTwice()
    var
        Item: Record Item;
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
    begin
        // Setup : Create Item, create whse item journal with item then adjust it in item journal.
        // Create Whse. Internal Put-Away by Get Bin Content.
        IsInitialized := false;
        Initialize();
        WhseInternalPutAwayHeader.Init();
        UpdateInvtAndCreateWhseInternalPutAwayByGetBinContent(Item, WhseInternalPutAwayHeader, LibraryRandom.RandInt(10), 2, true); // Get Bin Content twice.

        // Exercise: Create Put-Away from Whse. Internal Put-Away page.
        asserterror CreatePutAwayFromInternalPutAwayPage(WhseInternalPutAwayHeader."No.");

        // Verify: Verify error message.
        Assert.ExpectedError(QuantityMismatchErr);
    end;

    [Test]
    [HandlerFunctions('MultipleLotNoWhseItemTrackingPageHandler,WhseSourceCreateDocumentHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreatePutAwayFromInternalPutAwayWithLotNo()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        Bin: Record Bin;
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
        TrackingQuantity1: Decimal;
        TrackingQuantity2: Decimal;
        Quantity: Decimal;
    begin
        // Setup: Create Item tracking code with lot, create item, create whse item journal with lot tracking then adjust it in item journal.
        Initialize();
        WhseInternalPutAwayLine.Init();
        CreateItemTrackingCode(ItemTrackingCode, true, false, false);
        CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code, false);

        // Here the Qty will be LN and affect the sorting and verification, so Qty1 need to be in front of Qty2 in text ascending.
        TrackingQuantity1 := LibraryRandom.RandDecInRange(10, 20, 2);
        TrackingQuantity2 := LibraryRandom.RandDecInRange(30, 40, 2);
        Quantity := TrackingQuantity1 + TrackingQuantity2;
        LibraryVariableStorage.Enqueue(WhseItemTrackingPageHandlerBody::MultipleLotNo);
        LibraryVariableStorage.Enqueue(TrackingQuantity1); // This is Lot No. for 1st item tracking line.
        LibraryVariableStorage.Enqueue(TrackingQuantity2); // This is Lot No. for 2nd item tracking line.

        // Item tracking line with lot no will be arraged in MultipleLotNoWhseItemTrackingPageHandler
        UpdateInventoryAndAssignTrackingInWhseItemJournal(LocationWhite, Item, Quantity);

        // Exercise: Create 1st put-away partially from internal put-away.
        Bin.Get(LocationWhite.Code, LocationWhite."Cross-Dock Bin Code");
        CreatePutAwayFromInternalPutAway(
          WhseInternalPutAwayHeader, WhseInternalPutAwayLine, LocationWhite.Code,
          Bin."Zone Code", Bin.Code, Item."No.", true, TrackingQuantity1);
        // Create 2nd put-away from internal put-away.
        CreatePutAwayFromInternalPutAway(
          WhseInternalPutAwayHeader, WhseInternalPutAwayLine, LocationWhite.Code,
          Bin."Zone Code", Bin.Code, Item."No.", true, TrackingQuantity2);

        // Verify: Verify Lot No and quantity are correct in warehouse activity line.
        VerifyLotQuantitiesOnWhseActivityLines(
          Item."No.", Format(TrackingQuantity1), TrackingQuantity1, Format(TrackingQuantity2), TrackingQuantity2, true);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler,WhseSourceCreateDocumentHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreatePutAwayFromInternalPutAwayWithSeriesNo()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        Bin: Record Bin;
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
        Quantity: Integer;
    begin
        // Setup: Create Item Tracking Code with series, create item, create whse item journal with lot tracking then adjust it in item journal.
        Initialize();
        WhseInternalPutAwayLine.Init();
        CreateItemTrackingCode(ItemTrackingCode, false, true, false);
        CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code, true);
        Quantity := 2; // This case, only need two series tracking lines.
        TrackingQuantity := Quantity;
        LotSpecific := false; // Use SN to track.
        // Item tracking line with series no will be arraged in WhseItemTrackingLinesPageHandler.
        UpdateInventoryAndAssignTrackingInWhseItemJournal(LocationWhite, Item, Quantity);

        // Exercise: Create 1st put-away partially from internal put-away.
        Bin.Get(LocationWhite.Code, LocationWhite."Cross-Dock Bin Code");
        CreatePutAwayFromInternalPutAway(
          WhseInternalPutAwayHeader, WhseInternalPutAwayLine, LocationWhite.Code,
          Bin."Zone Code", Bin.Code, Item."No.", true, 1);
        // Create 2nd put-away from internal put-away.
        CreatePutAwayFromInternalPutAway(
          WhseInternalPutAwayHeader, WhseInternalPutAwayLine, LocationWhite.Code,
          Bin."Zone Code", Bin.Code, Item."No.", true, Quantity - 1);

        // Verify: Verify Series No and quantity are correct in warehouse activity line.
        // Item Tracking Lines are sorted by SN as ascending, so 1st line is 0, 2nd line is 1.
        VerifyLotQuantitiesOnWhseActivityLines(Item."No.", Format(0), 1, Format(1), 1, false);
    end;

    [Test]
    [HandlerFunctions('MultipleLotNoWhseItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure GetBinContentFromMovementWorksheetWithLotNo()
    var
        TrackingType: Option "None",Lot,PartialLot,Series;
        GetBinContent: Option "None",MovementWorksheet,InternalPutAway;
    begin
        // Test and verify Quantity in Movement Worksheet by Get Bin Content is consistent with the one
        // in Item Tracking Lines when there is outstanding quantity in opened Pick document using Lot No.
        GetBinContentWithLotNoAndSeriesNo(TrackingType::Lot, GetBinContent::MovementWorksheet, true);
    end;

    [Test]
    [HandlerFunctions('LotNoWhseItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure GetBinContentFromMovementWorksheetWithPartialLotNo()
    var
        TrackingType: Option "None",Lot,PartialLot,Series;
        GetBinContent: Option "None",MovementWorksheet,InternalPutAway;
    begin
        // Test and verify Quantity in Movement Worksheet by Get Bin Content is consistent with the one
        // in Item Tracking Lines when there is outstanding quantity in opened Pick document using Lot No. partially.
        GetBinContentWithLotNoAndSeriesNo(TrackingType::PartialLot, GetBinContent::MovementWorksheet, false);
    end;

    [Test]
    [HandlerFunctions('MultipleLotNoWhseItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure GetBinContentFromInternalPutAwayWithLotNo()
    var
        TrackingType: Option "None",Lot,PartialLot,Series;
        GetBinContent: Option "None",MovementWorksheet,InternalPutAway;
    begin
        // Test and verify Quantity in Internal Put-away by Get Bin Content is consistent with the one
        // in Item Tracking Lines when there is outstanding quantity in opened Pick document using Lot No.
        GetBinContentWithLotNoAndSeriesNo(TrackingType::Lot, GetBinContent::InternalPutAway, true);
    end;

    [Test]
    [HandlerFunctions('LotNoWhseItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure GetBinContentFromInternalPutAwayWithPartialLotNo()
    var
        TrackingType: Option "None",Lot,PartialLot,Series;
        GetBinContent: Option "None",MovementWorksheet,InternalPutAway;
    begin
        // Test and verify Quantity in Internal Put-away by Get Bin Content is consistent with the one
        // in Item Tracking Lines when there is outstanding quantity in opened Pick document using Lot No. partially.
        GetBinContentWithLotNoAndSeriesNo(TrackingType::PartialLot, GetBinContent::InternalPutAway, false);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure GetBinContentFromMovementWorksheetWithSeriesNo()
    var
        TrackingType: Option "None",Lot,PartialLot,Series;
        GetBinContent: Option "None",MovementWorksheet,InternalPutAway;
    begin
        // Test and verify Quantity in Movement Worksheet by Get Bin Content is consistent with the one
        // in Item Tracking Lines when there is outstanding quantity in opened Pick document using Series No.
        GetBinContentWithLotNoAndSeriesNo(TrackingType::Series, GetBinContent::MovementWorksheet, false);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure GetBinContentFromInternalPutAwayWithSeriesNo()
    var
        TrackingType: Option "None",Lot,PartialLot,Series;
        GetBinContent: Option "None",MovementWorksheet,InternalPutAway;
    begin
        // Test and verify Quantity in Internal Put-away by Get Bin Content is consistent with the one
        // in Item Tracking Lines when there is outstanding quantity in opened Pick document using Series No.
        GetBinContentWithLotNoAndSeriesNo(TrackingType::Series, GetBinContent::InternalPutAway, false);
    end;

    local procedure GetBinContentWithLotNoAndSeriesNo(TrackingType: Option "None",Lot,PartialLot,Series; GetBinContent: Option "None",MovementWorksheet,InternalPutAway; IsMultiple: Boolean)
    var
        Item: Record Item;
        Bin: Record Bin;
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
        TrackingQuantity2: Decimal;
    begin
        // Setup: General preparation for Get Bin Content with Lot No / Series No.
        Initialize();

        case TrackingType of
            TrackingType::Lot:
                TrackingQuantity2 := InitGetBinContentWithLotNoScenario(Item, IsMultiple);
            TrackingType::PartialLot:
                TrackingQuantity2 := InitGetBinContentWithLotNoScenario(Item, IsMultiple);
            TrackingType::Series:
                begin
                    TrackingQuantity2 := 1;
                    InitGetBinContentWithSeriesNoScenario(Item);
                end;
        end;

        // Exercise: Get Bin content on Movement Worksheet / Internal Put-away..
        case GetBinContent of
            GetBinContent::MovementWorksheet:
                GetBinContentFromMovementWorksheet(WhseWorksheetLine, LocationWhite.Code, Item."No.");
            GetBinContent::InternalPutAway:
                begin
                    Bin.Get(LocationWhite.Code, LocationWhite."Cross-Dock Bin Code");
                    CreateWhseInternalPutAway(WhseInternalPutAwayHeader, LocationWhite.Code, Bin."Zone Code", Bin.Code, Item."No.", 1);
                end;
        end;

        // Verify: Verify Warehouse Item Tracking Line is correct.
        // For Lot, Item Tracking Line should only contain one line and the Quantity Base should be TrackingQuantity2.
        // For Series, Item Tracking Line also shoulbe be one line and Quantity should be 1.
        // Since the first Lot / several Series are reserved for the pending pick document.
        VerifyWhseItemTrackingLines(WhseItemTrackingLine, Item."No.", 1, TrackingQuantity2);
    end;

    [Test]
    [HandlerFunctions('WhseSourceCreateDocumentHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreatePutAwayFromInternalPutAwayWithDedicatedBin()
    var
        Bin: Record Bin;
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // Test to verify Put-away can be created from Internal Put-away with Dedicated Bin.

        // Setup: Create a Bin with Dedicated. Create a Release Production Order with a new item. Create and post Output Journal.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        UpdateBinWithDedicated(Bin, LocationWhite);
        LibraryInventory.CreateItem(Item);
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", Quantity, LocationWhite.Code, Bin.Code);
        CreateAndPostOutputJournal(Item."No.", ProductionOrder."No.", Quantity);

        // Exercise: Create Put-away from Internal Put-away.
        WhseInternalPutAwayLine.Init();
        CreatePutAwayFromInternalPutAway(
          WhseInternalPutAwayHeader, WhseInternalPutAwayLine, LocationWhite.Code, Bin."Zone Code", Bin.Code, Item."No.", true, Quantity);

        // Verify: Verify Warehouse Activity Line is created successfully without any error and Bin Code is correct.
        VerifyBinCodeInWhseActivityLine(Item."No.", WarehouseActivityLine."Action Type"::Take, Bin.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CrossDockBinCodeForWhseActivityLine()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Location: Record Location;
        Quantity: Integer;
    begin
        IsInitialized := false; // Need re-create Location due to cannot update location with entries exist.
        Initialize();

        // Setup: Update Location
        Location.Get(LocationWhite.Code);
        UpdateLocation(Location.Code, Location."Cross-Dock Bin Code", Location."Adjustment Bin Code", false, true);

        // Create and release Sales Order. Create and release Purchase Order, create Warehouse Receipt
        Quantity := 4 * LibraryRandom.RandInt(25);
        CreateWarehouseReceiptSetup(Item, SalesHeader, PurchaseHeader, Location.Code, Quantity / 4, Quantity); // Sales Quantity is "Quantity / 4", Purchase Quantity is "Quantity"

        // Exercise: Calculate Cross Dock and Post Warehouse Receipt
        FindWarehouseReceiptNo(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        CalculateCrossDock(WhseCrossDockOpportunity, WarehouseReceiptLine."No.", Item."No.");
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");

        // Verify: Verify the Bin Code for the Cross Dock in Put-away
        VerifyCrossDockBinCodeForWhseActivityLine(
          WarehouseActivityLine."Activity Type"::"Put-away", Location.Code, PurchaseHeader."No.",
          WarehouseActivityLine."Action Type"::Place, Quantity / 4, Location."Cross-Dock Bin Code");

        // Exercise: Register Put-away and post Purchase Order
        RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify the Bin Code for the Cross Dock in Warehouse Entry
        VerifyBinCodeForWarehouseEntry(Item."No.", Location.Code, Quantity / 4, Location."Cross-Dock Bin Code");

        // Clear up the location setup
        UpdateLocation(
          Location.Code, Location."Cross-Dock Bin Code", Location."Adjustment Bin Code",
          Location."Directed Put-away and Pick", Location."Use Cross-Docking");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,MessageHandler,PostedPurchaseDocumentLinePageHandler')]
    [Scope('OnPrem')]
    procedure CalcRegenPlanWithPartialWarehousePick()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ReservationEntry: Record "Reservation Entry";
        LocationCode: Code[10];
        PickQty: Decimal;
    begin
        // Setup: Create Lot-for-Lot Item with Item Tracking Code. Create and release Purchase Order. Create and post Inventory Put Away.
        // Create and partially register Pick from Purchase Return order.
        Initialize();
        LocationCode := InitSetupItemAndLocaiton(Item);
        PickQty := LibraryRandom.RandInt(5);
        TrackingQuantity := PickQty + LibraryRandom.RandInt(5); // Integer value Required.
        CreateAndPostInvtPutAwayFromPurchaseOrder(PurchaseHeader, Item."No.", LocationCode, TrackingQuantity);
        CreateAndPartialRegisterPickFromPurchaseReturnOrder(PurchaseHeader, PickQty, 0, false);

        // Exercise: Calculate Regenerative Plan for Item.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // Verify: Verify Qty. to Handle(Base) on Reservation Entry.
        VerifyReservationEntry(Item."No.", ReservationEntry."Reservation Status"::Surplus, -PickQty);
    end;

    [Test]
    [HandlerFunctions('WhseSourceCreateDocumentHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure MovementWithUOMRoundingConversion()
    var
        Quantity: Decimal;
        ItemNo: Code[20];
    begin
        // Test to verify there is no UOM Rounding Coversion issue when register Movement using "Get Bin Content"

        // Setup: Create a Purchase Order, create and post whse. receipt, create and register Put-away using another UOM
        Initialize();
        ItemNo := RegisterWarehousePutawayWithDifferentUOM(Quantity);

        // Exercise: Create Movement by "Get Bin Content" in Movement Worksheet, Register Movement
        CreateAndRegisterMovementByGetBinContent(ItemNo, LocationWhite.Code);

        // Verify: Verify all items moved to the new bin - Quantity (Base) is correct in BIN Contents from the Item.
        VerifyBinContentForQuantity(ItemNo, Quantity);
    end;

    [Test]
    [HandlerFunctions('WhseSourceCreateDocumentHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure InternalPutawayWithUOMRoundingConversion()
    var
        ItemNo: Code[20];
        Quantity: Decimal;
    begin
        // Test to verify there is no UOM Rounding Coversion issue when register Whse. Internal Put-away using "Get Bin Content"

        // Setup: Create a Purchase Order, create and post whse. receipt, create and register Put-away using another UOM
        Initialize();
        ItemNo := RegisterWarehousePutawayWithDifferentUOM(Quantity);

        // Exercise: Create Whse. Internal Put-away by "Get Bin Content", create and register Put-away
        CreateAndRegisterPutAwayFromInternalPutAwayByGetBinContent(ItemNo, Quantity);

        // Verify: Verify all items moved to the new bin - Quantity (Base) is correct in BIN Contents from the Item.
        VerifyBinContentForQuantity(ItemNo, Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,MessageHandler,PostedPurchaseDocumentLineHandler')]
    [Scope('OnPrem')]
    procedure MultiplePartialPickFromWhseShipment()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        LocationCode: Code[10];
        PickQty: Decimal;
        PartialPickQty: Decimal;
    begin
        // Setup: Create Lot-for-Lot Item with Item Tracking Code. Create and release Purchase Order. Create and post Inventory Put Away.
        Initialize();
        LocationCode := InitSetupItemAndLocaiton(Item);
        PickQty := LibraryRandom.RandIntInRange(5, 10);
        PartialPickQty := LibraryRandom.RandInt(4); // To make sure not partial pick.
        TrackingQuantity := PickQty + LibraryRandom.RandIntInRange(5, 10); // Integer value Required.
        LibraryVariableStorage.Enqueue(ItemTrackingLineActionType::Tracking);
        CreateAndPostInvtPutAwayFromPurchaseOrder(PurchaseHeader, Item."No.", LocationCode, TrackingQuantity);

        // Exercise: Create and partially register Pick from Purchase Return order two times.
        CreateAndPartialRegisterPickFromPurchaseReturnOrder(PurchaseHeader, PickQty, PartialPickQty, true);

        // Verify: Verify Qty. to Handle(Base) on Item Tracking Lines.
        LibraryVariableStorage.Enqueue(ItemTrackingLineActionType::Verify);
        LibraryVariableStorage.Enqueue(PartialPickQty);
        FindWhseShipmentNo(WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Purchase Return Order", PurchaseHeader."No.");
        WarehouseShipmentLine.OpenItemTrackingLines(); // Verify Item Tracking lines through ItemTrackingPageHandler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BWCrossDockPickFromWhseShipment()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        Quantity: Integer;
    begin
        // Setup.
        Initialize();

        Quantity := LibraryRandom.RandInt(100) + 100;
        CreateWarehouseReceiptSetup(Item, SalesHeader, PurchaseHeader, LocationSilver3.Code, Quantity, Quantity * 2);

        // Exercise.
        FindWarehouseReceiptNo(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        CalculateCrossDockSimple(WarehouseReceiptLine."No.");
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");

        CreateAndReleaseWhseShipment(SalesHeader, WarehouseShipmentHeader);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // Verify.
        VerifyCrossDockBinCodeForWhseActivityLine(
          WarehouseActivityLine."Activity Type"::Pick, LocationSilver3.Code, SalesHeader."No.",
          WarehouseActivityLine."Action Type"::Take, Quantity, LocationSilver3."Cross-Dock Bin Code");
    end;

    [Test]
    [HandlerFunctions('MultipleLotNoWhseItemTrackingPageHandler,WhseSourceCreateDocumentHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreatePutAwayFromInternalPutAwayWithLotNoTwice()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        Bin: Record Bin;
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
        TrackingQuantity1: Decimal;
        TrackingQuantity2: Decimal;
        Quantity: Decimal;
        DeltaQty: Decimal;
    begin
        // Setup: Create Item tracking code with lot, create item, create whse item journal with lot tracking then adjust it in item journal.
        Initialize();
        WhseInternalPutAwayLine.Init();
        CreateItemTrackingCode(ItemTrackingCode, true, false, false);
        CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code, false);

        // Here the Qty will be LN and affect the sorting and verification, so Qty1 need to be in front of Qty2 in text ascending.
        TrackingQuantity1 := LibraryRandom.RandDecInRange(10, 20, 2);
        TrackingQuantity2 := LibraryRandom.RandDecInRange(30, 40, 2);
        Quantity := TrackingQuantity1 + TrackingQuantity2;
        DeltaQty := LibraryRandom.RandDecInRange(1, 4, 2);

        LibraryVariableStorage.Enqueue(WhseItemTrackingPageHandlerBody::MultipleLotNo);
        LibraryVariableStorage.Enqueue(TrackingQuantity1); // This is Lot No. for 1st item tracking line.
        LibraryVariableStorage.Enqueue(TrackingQuantity2); // This is Lot No. for 2nd item tracking line.

        // Item tracking line with lot no will be arraged in MultipleLotNoWhseItemTrackingPageHandler
        UpdateInventoryAndAssignTrackingInWhseItemJournal(LocationWhite, Item, Quantity);

        // Create 1st put-away partially from internal put-away.
        Bin.Get(LocationWhite.Code, LocationWhite."Cross-Dock Bin Code");
        CreatePutAwayFromInternalPutAwayWithLotSerialNos(
          WhseInternalPutAwayHeader, WhseInternalPutAwayLine, LocationWhite.Code,
          Bin."Zone Code", Bin.Code, Item."No.", Format(TrackingQuantity1), '', TrackingQuantity1 - DeltaQty);

        // Exercise: Create 2nd put-away from internal put-away.
        CreatePutAwayFromInternalPutAwayWithLotSerialNos(
          WhseInternalPutAwayHeader, WhseInternalPutAwayLine, LocationWhite.Code,
          Bin."Zone Code", Bin.Code, Item."No.", Format(TrackingQuantity1), '', DeltaQty);

        // Verify: Verify Lot No and quantity are correct in warehouse activity line.
        VerifyLotQuantitiesOnWhseActivityLines(
          Item."No.", Format(TrackingQuantity1), TrackingQuantity1 - DeltaQty,
          Format(TrackingQuantity1), DeltaQty, true);
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseDocumentLinePageHandler2,MessageHandler')]
    [Scope('OnPrem')]
    procedure CannotReturnPurchaseWhenOutOfInventory()
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ShipmentNo: Code[20];
        Quantity: Decimal;
        PrevNoNegInventory: Boolean;
    begin
        // [FEATURE] [Prevent Negative Inventory] [Return Shipment]
        // [SCENARIO 361861] Verify that cannot post Purchase Return Order with "Prevent Negative Inventory" set and no Item on hand.

        // [GIVEN] Set "Prevent Negative Inventory" to TRUE.
        Initialize();
        PrevNoNegInventory := SetPreventNegInventory(true);

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandInt(5);

        // [GIVEN] Purchase and sale Item, as result zero Quantity on stock.
        CreateAndReleasePurchaseOrder(PurchaseHeader, Item."No.", Location.Code, Quantity, '', '', false);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", Quantity, Location.Code);
        ShipmentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Purchase Return Order, lines acquired via Get Posted Document Lines to Reverse, use Original Quantity.
        CreateAndReleasePurchReturnOrderAfterGetPostedDocumentLinesToReverse(PurchaseHeader, PurchaseHeader."Buy-from Vendor No.");

        // [WHEN] Ship Purchase Return Order.
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Insufficient quantity error message appears.
        Assert.ExpectedError(StrSubstNo(CannotUnapplyItemLedgEntryErr, FindItemLedgEntryNo(ShipmentNo)));

        // Teardown.
        SetPreventNegInventory(PrevNoNegInventory);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InitializeWhseJournalLineItemTemplate()
    begin
        // [FEATURE] [Warehouse Journal] [UT]
        // [SCENARIO 376129] Adjustment bin code is copied from location to warehouse journal line while initializig the journal line in "Item" journal template

        Initialize();
        WarehouseItemJournalSetupSetTemplateType(LocationWhite.Code, WarehouseJournalTemplate.Type::Item);
        SetupWhseJournalLine(WarehouseJournalLine, LocationWhite.Code, '');
        WarehouseJournalLine.TestField("From Bin Code", LocationWhite."Adjustment Bin Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InitializeWhseJournalLinePhysicalInventoryTemplate()
    begin
        // [FEATURE] [Warehouse Journal] [UT]
        // [SCENARIO 376129] Adjustment bin code is copied from location to warehouse journal line while initializig the journal line in "Physical Inventory" journal template

        Initialize();
        WarehouseItemJournalSetupSetTemplateType(LocationWhite.Code, WarehouseJournalTemplate.Type::"Physical Inventory");
        SetupWhseJournalLine(WarehouseJournalLine, LocationWhite.Code, '');
        WarehouseJournalLine.TestField("From Bin Code", LocationWhite."Adjustment Bin Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InitializeWhseJournalLineReclassificationTemplate()
    begin
        // [FEATURE] [Warehouse Journal] [UT]
        // [SCENARIO 376129] Adjustment bin code is not copied from location to warehouse journal line while initializig the journal line in "Reclassification" journal template

        Initialize();
        WarehouseItemJournalSetupSetTemplateType(LocationWhite.Code, WarehouseJournalTemplate.Type::Reclassification);
        SetupWhseJournalLine(WarehouseJournalLine, LocationWhite.Code, '');
        WarehouseJournalLine.TestField("From Bin Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegisterWhseJournalLineOnLocationWithEmptyAdjmtBinCodeFails()
    var
        Location: Record Location;
        Item: Record Item;
    begin
        // [FEATURE] [Warehouse Journal] [Warehouse Physical Inventory]
        // [SCENARIO 376129] Whse. Physical Inventory should not be registered if adjustment bin is removed in location setup after the journal line is initialized
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create warehouse physical inventory journal line on location with adjustment bin filled
        CreateFullWarehouseSetup(Location);

        WarehouseItemJournalSetupSetTemplateType(Location.Code, WarehouseJournalTemplate.Type::"Physical Inventory");
        SetupWhseJournalLine(WarehouseJournalLine, Location.Code, Item."No.");
        WarehouseJournalLine.Insert(true);

        // [GIVEN] Clear adjustment bin code in the location setup
        Location.Validate("Adjustment Bin Code", '');
        Location.Modify(true);

        // [WHEN] Register warehouse journal line
        asserterror
          LibraryWarehouse.RegisterWhseJournalLine(
            WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Location.Code, true);

        // [THEN] Error message: "Adjustment Bin Code must have a value in Location"
        Assert.ExpectedError(AdjmtBinCodeMustHaveValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegisterPosAdjWhseItemLineWithBlankFromBinCode()
    var
        WhseDocumentNo: Code[20];
    begin
        // [FEATURE] [Warehouse Journal Line]
        // [SCENARIO 379012] Warehouse Journal Line for Positive Adjustment should be registered correctly if blank "From Bin Code" is set before that.
        Initialize();

        // [GIVEN] Whse. Item Journal Line for Positive Adjustment with blank "From Bin Code".
        WhseDocumentNo := CreatePositiveAdjmtWhseItemLineWithBlankFromBin();

        // [WHEN] Register Whse. Item Journal
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationWhite.Code, true);

        // [THEN] One line is created in Warehouse Entry.
        VerifyCountOfWarehouseEntry(WhseDocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegisterNegAdjWhseItemLineWithBlankToBinCode()
    var
        WhseDocumentNo: Code[20];
    begin
        // [FEATURE] [Warehouse Journal Line]
        // [SCENARIO 379012] Warehouse Journal Line for Negative Adjustment should be registered correctly if blank "To Bin Code" is set before that.
        Initialize();

        // [GIVEN] Warehouse Journal Line for Negative Adjustment with blank "To Bin Code".
        WhseDocumentNo := CreateNegAdjmtWhseItemLineWithBlankToBin();

        // [WHEN] Register Whse. Item Journal
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationWhite.Code, true);

        // [THEN] One line is created in Warehouse Entry.
        VerifyCountOfWarehouseEntry(WhseDocumentNo);
    end;

    [Test]
    [HandlerFunctions('CrossDockOpportunitiesModalPageHandler')]
    [Scope('OnPrem')]
    procedure CrossDockOppInTwoReceiptsSupplyingTwoSalesOrders()
    var
        Item: Record Item;
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseReceipt: TestPage "Warehouse Receipt";
    begin
        // [FEATURE] [Cross-Dock] [Cross-Dock Opportunity] [Warehouse Receipt]
        // [SCENARIO 359946] Setting cross-dock qty. after viewing cross-dock opportunities in a scenario when several sales orders are supplied by several receipts.
        Initialize();

        // [GIVEN] A location with cross-dock enabled.
        LibraryInventory.CreateItem(Item);
        CreateFullWarehouseSetup(Location);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Two sales orders, each for 15 pcs.
        CreateAndReleaseSalesOrderWithVariant(SalesHeader, SalesLine, Item."No.", 15, Location.Code, '');
        CreateAndReleaseSalesOrderWithVariant(SalesHeader, SalesLine, Item."No.", 15, Location.Code, '');

        // [GIVEN] Purchase order 1 for 100 pcs.
        // [GIVEN] Create warehouse receipt, set "Qty. to Receive" = 20 pcs and calculate cross-dock. "Qty. to Cross-Dock" = 20 pcs.
        // [GIVEN] Post the warehouse receipt.
        CreateAndReleasePurchaseOrderWithWhseReceipt(
          PurchaseHeader, WarehouseReceiptLine, Item."No.", Location.Code, 100);
        WarehouseReceiptLine.Validate("Qty. to Receive", 20);
        WarehouseReceiptLine.Modify(true);
        CalculateCrossDockSimple(WarehouseReceiptLine."No.");
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");

        // [GIVEN] Purchase order 2 for 10 pcs.
        // [GIVEN] Create warehouse receipt and calculate cross-dock. "Qty. to Cross-Dock" = 10 pcs.
        CreateAndReleasePurchaseOrderWithWhseReceipt(
          PurchaseHeader, WarehouseReceiptLine, Item."No.", Location.Code, 10);
        WarehouseReceipt.OpenEdit();
        WarehouseReceipt.FILTER.SetFilter("No.", WarehouseReceiptLine."No.");
        WarehouseReceipt.CalculateCrossDock.Invoke();

        // [WHEN] Open Whse. Cross-Dock Opportunity page, set "Qty. to Cross-Dock" = 5 and close the page.
        LibraryVariableStorage.Enqueue(5);
        WarehouseReceipt.WhseReceiptLines."Qty. to Cross-Dock".Lookup();

        // [THEN] "Qty. to Cross-Dock" is updated to 5 on the warehouse receipt.
        WarehouseReceipt.WhseReceiptLines."Qty. to Cross-Dock".AssertEquals(5);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CrossDockOppGreaterThanQtyToCrossDockError()
    var
        Item: Record Item;
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity";
    begin
        // [FEATURE] [Cross-Dock] [Cross-Dock Opportunity] [Warehouse Receipt]
        // [SCENARIO 359946] A user cannot set Qty. to Cross-Dock in Cross-Dock Opportunity greater than Qty. to Cross Dock on the receipt line.
        Initialize();

        // [GIVEN] A location with cross-dock enabled.
        LibraryInventory.CreateItem(Item);
        CreateFullWarehouseSetup(Location);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Sales order for 15 pcs.
        CreateAndReleaseSalesOrderWithVariant(SalesHeader, SalesLine, Item."No.", 15, Location.Code, '');

        // [GIVEN] Purchase order for 100 pcs.
        // [GIVEN] Create warehouse receipt, set "Qty. to Receive" = 30 pcs and calculate cross-dock. "Qty. to Cross-Dock" = 15 pcs.
        CreateAndReleasePurchaseOrderWithWhseReceipt(
          PurchaseHeader, WarehouseReceiptLine, Item."No.", Location.Code, 100);
        WarehouseReceiptLine.Validate("Qty. to Receive", 30);
        WarehouseReceiptLine.Modify(true);
        CalculateCrossDockSimple(WarehouseReceiptLine."No.");

        // [WHEN] Set "Qty. to Cross-Dock" = 20 on Whse. Cross-Dock Opportunity.
        WhseCrossDockOpportunity.SetRange("Item No.", Item."No.");
        WhseCrossDockOpportunity.FindFirst();
        asserterror WhseCrossDockOpportunity.Validate("Qty. to Cross-Dock", 20);

        // [THEN] An error is thrown. "Qty. to Cross-Dock" on the opportunity page cannot be greater than "Qty. to Cross-Dock" on the receipt line.
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(CrossDockQtyExceedsCrossDockQtyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CrossDockOppAutofillDistributesQtyBySalesOrders()
    var
        Item: Record Item;
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        SalesHeader: array[2] of Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity";
    begin
        // [FEATURE] [Cross-Dock] [Cross-Dock Opportunity] [Warehouse Receipt]
        // [SCENARIO 359946] Clicking on Autofill Qty. to Cross-Dock suggests distribution of quantity among sales orders.
        Initialize();

        // [GIVEN] A location with cross-dock enabled.
        LibraryInventory.CreateItem(Item);
        CreateFullWarehouseSetup(Location);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Two sales orders "S1", "S2", each for 15 pcs.
        CreateAndReleaseSalesOrderWithVariant(SalesHeader[1], SalesLine, Item."No.", 15, Location.Code, '');
        CreateAndReleaseSalesOrderWithVariant(SalesHeader[2], SalesLine, Item."No.", 15, Location.Code, '');

        // [GIVEN] Purchase order 1 for 100 pcs.
        // [GIVEN] Create warehouse receipt, set "Qty. to Receive" = 20 pcs and calculate cross-dock. "Qty. to Cross-Dock" = 20 pcs.
        // [GIVEN] Post the warehouse receipt.
        CreateAndReleasePurchaseOrderWithWhseReceipt(
          PurchaseHeader, WarehouseReceiptLine, Item."No.", Location.Code, 100);
        WarehouseReceiptLine.Validate("Qty. to Receive", 20);
        WarehouseReceiptLine.Modify(true);
        CalculateCrossDockSimple(WarehouseReceiptLine."No.");
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");

        // [GIVEN] Purchase order 2 for 100 pcs.
        // [GIVEN] Create warehouse receipt and calculate cross-dock. "Qty. to Cross-Dock" = 10 pcs.
        // [GIVEN] Increase "Qty. to Cross-Dock" on the receipt line from 10 to 20 pcs.
        CreateAndReleasePurchaseOrderWithWhseReceipt(
          PurchaseHeader, WarehouseReceiptLine, Item."No.", Location.Code, 100);
        CalculateCrossDockSimple(WarehouseReceiptLine."No.");
        WarehouseReceiptLine.Find();
        WarehouseReceiptLine.Validate("Qty. to Cross-Dock", 20);
        WarehouseReceiptLine.Modify(true);

        // [WHEN] View Whse. Cross-Dock Opportunities and run "Autofill Qty. to Cross-Dock".
        WhseCrossDockOpportunity.SetRange("Source Name/No.", WarehouseReceiptLine."No.");
        WhseCrossDockOpportunity.AutoFillQtyToCrossDock(WhseCrossDockOpportunity);

        // [THEN] 20 pcs is distributed among the sales orders.
        // [THEN] 15 pcs for the sales order "S1".
        WhseCrossDockOpportunity.SetRange("To Source No.", SalesHeader[1]."No.");
        WhseCrossDockOpportunity.CalcSums("Qty. to Cross-Dock");
        WhseCrossDockOpportunity.TestField("Qty. to Cross-Dock", 15);

        // [THEN] 5 pcs for the sales order "S2".
        WhseCrossDockOpportunity.SetRange("To Source No.", SalesHeader[2]."No.");
        WhseCrossDockOpportunity.CalcSums("Qty. to Cross-Dock");
        WhseCrossDockOpportunity.TestField("Qty. to Cross-Dock", 5);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        SequenceNoMgt.ClearState();
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Warehouse-V");
        LibraryVariableStorage.Clear();
        Clear(NewUnitOfMeasure);
        Clear(NewUnitOfMeasure2);
        Clear(NewUnitOfMeasure3);
        Clear(UnitOfMeasureType);
        Clear(TrackingQuantity);
        Clear(VerifyTracking);
        Clear(LotSpecific);
        Clear(Serial);
        Clear(SelectEntries);

        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Warehouse-V");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        CreateLocationSetup();
        NoSeriesSetup();
        ItemJournalSetup();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Warehouse-V");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWhseItemJnlLineWrongFromBinCode()
    var
        Item: Record Item;
        Zone: Record Zone;
        Bin: Record Bin;
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // Verify that error message appears if "From Bin Code" is not equal to Location "Adjustment Bin Code" for Positive Adjustment.

        // Setup.
        SetupWhseItemJnlLineWrongBinCode(Zone, Bin);

        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name,
          LocationWhite.Code, Zone.Code, Bin.Code,
          WarehouseJournalLine."Entry Type"::"Positive Adjmt.",
          LibraryInventory.CreateItem(Item), LibraryRandom.RandDecInRange(10, 1000, 2));

        WarehouseJournalLine."From Bin Code" := Bin.Code;
        WarehouseJournalLine.Modify();

        // Exercise.
        asserterror
          LibraryWarehouse.RegisterWhseJournalLine(
            WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationWhite.Code, true);

        // Verify.
        Assert.ExpectedError(StrSubstNo(WrongBinCodeErr, WarehouseJournalLine.FieldCaption("From Bin Code")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWhseItemJnlLineWrongToBinCode()
    var
        Item: Record Item;
        Zone: Record Zone;
        Bin: Record Bin;
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // Verify that error message appears if "To Bin Code" is not equal to Location "Adjustment Bin Code" for Negative Adjustment.

        // Setup.
        SetupWhseItemJnlLineWrongBinCode(Zone, Bin);

        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name,
          LocationWhite.Code, Zone.Code, Bin.Code,
          WarehouseJournalLine."Entry Type"::"Negative Adjmt.",
          LibraryInventory.CreateItem(Item), LibraryRandom.RandDecInRange(10, 1000, 2));

        WarehouseJournalLine."To Bin Code" := Bin.Code;
        WarehouseJournalLine.Modify();

        // Exercise.
        asserterror
          LibraryWarehouse.RegisterWhseJournalLine(
            WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationWhite.Code, true);

        // Verify.
        Assert.ExpectedError(StrSubstNo(WrongBinCodeErr, WarehouseJournalLine.FieldCaption("To Bin Code")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyWhseItemJnlLineWithPosAdjBinSetup()
    var
        Item: Record Item;
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // Verify that after Item No. validation "From Bin Code" is updated automatically to Location "Adjustment Bin Code" for positive adjustment lines.

        // Setup.
        Initialize();
        WarehouseItemJournalSetup(LocationWhite.Code);
        LibraryInventory.CreateItem(Item);
        SetupWhseJournalLine(WarehouseJournalLine, LocationWhite.Code, Item."No.");

        // Exercise.
        WarehouseJournalLine.Validate(Quantity, LibraryRandom.RandDecInRange(10, 100, 2));

        // Verify.
        Assert.AreEqual(
          LocationWhite."Adjustment Bin Code", WarehouseJournalLine."From Bin Code", WhseJournalLineBinCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyWhseItemJnlLineWithNegAdjBinSetup()
    var
        Item: Record Item;
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // Verify that after Item No. validation "To Bin Code" is updated automatically to Location "Adjustment Bin Code" for negative adjustment lines.

        // Setup.
        Initialize();
        WarehouseItemJournalSetup(LocationWhite.Code);
        LibraryInventory.CreateItem(Item);
        SetupWhseJournalLine(WarehouseJournalLine, LocationWhite.Code, Item."No.");

        // Exercise.
        WarehouseJournalLine.Validate(Quantity, -LibraryRandom.RandDecInRange(10, 100, 2));

        // Verify.
        Assert.AreEqual(
          LocationWhite."Adjustment Bin Code", WarehouseJournalLine."To Bin Code", WhseJournalLineBinCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateWhseItemJnlLineWithPosAdjBinSetup()
    var
        Item: Record Item;
        Zone: Record Zone;
        Bin: Record Bin;
        AdjustmentBinCode: Code[20];
    begin
        // Verify that for scenario when adjustment bin is set for Location during Warehouse Item Journal Line creation (positive adjustment), when trying to register lines error message appears because of wrong "Adjustment Bin Code".

        // Setup.
        SetupWhseItemJnlLineWrongBinCode(Zone, Bin);
        ClearWhiteLocationAdjBin();

        CreateWhseItemJournalLineWithWrongAdjBin(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationWhite.Code,
          Zone.Code, Bin.Code, LibraryInventory.CreateItem(Item), LibraryRandom.RandDecInRange(10, 1000, 2),
          AdjustmentBinCode);

        // Exercise.
        asserterror
          LibraryWarehouse.RegisterWhseJournalLine(
            WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationWhite.Code, true);

        // Verify.
        Assert.ExpectedError(StrSubstNo(WrongBinCodeErr, WarehouseJournalLine.FieldCaption("From Bin Code")));
        SetupAdjustmentBin(LocationWhite.Code, AdjustmentBinCode); // Restore Adjustment Bin Code.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateWhseItemJnlLineWithNegAdjBinSetup()
    var
        Item: Record Item;
        Zone: Record Zone;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        AdjBinToRestore: Code[20];
        Quantity: Decimal;
    begin
        // Verify that for scenario when adjustment bin is set for Location during Warehouse Item Journal Line creation (negative adjustment), "To Bin Code" is set correctly and after registering Warehouse Entry contains "Adjustment Bin Code".

        // Setup.
        SetupWhseItemJnlLineWrongBinCode(Zone, Bin);
        ClearWhiteLocationAdjBin();
        AdjBinToRestore := SetupAdjustmentBin(LocationWhite.Code, '');
        LibraryInventory.CreateItem(Item);

        LibraryWarehouse.CreateBinContent(
          BinContent, LocationWhite.Code, Zone.Code, Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        Quantity := LibraryRandom.RandDecInRange(10, 1000, 2);
        MockInventory(LocationWhite.Code, Zone.Code, Bin.Code, Item."No.", Item."Base Unit of Measure", 1, Quantity * 2);

        CreateWhseItemJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationWhite.Code,
          Zone.Code, Bin.Code, Item."No.", -1 * Quantity,
          AdjBinToRestore);

        // Exercise.
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationWhite.Code, true);

        // Verify.
        VerifyBinCodeInWhseEntry(Item."No.", LocationWhite."Adjustment Bin Code");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure WhseDocTypeAfterInvtPutAwayPost()
    var
        Item: Record Item;
        Bin: Record Bin;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseEntry: Record "Warehouse Entry";
        Qty: Decimal;
    begin
        // [FEATURE] [Inventory Put-Away]
        // [SCENARIO 377187] After posting Inventory Put-Away Warehouse Entry "Whse. Document Type" = " "

        // [GIVEN] Create Item, create and release Purchase Order.
        Initialize();
        LibraryInventory.CreateItem(Item);
        Qty := LibraryRandom.RandInt(10);  // Integer value Required.
        LibraryWarehouse.FindBin(Bin, LocationSilver.Code, '', 1);  // Find Bin of Index 1.

        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.", LocationSilver.Code, Qty, '', '');
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Create Inventory Put Away, autofill Qty to Handle.
        PrepareInvtPutAway(
          WarehouseActivityHeader."Source Document"::"Purchase Order", PurchaseHeader."No.",
          Item."No.", LocationSilver.Code, Bin.Code);

        // [WHEN] Post Inventory Put Away.
        PostInventoryPut(PurchaseHeader."No.");
        // [THEN] Warehouse Entry of Inventory Put-Away "Whse. Document Type" = " "
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Location Code", LocationSilver.Code);
        WarehouseEntry.FindFirst();
        WarehouseEntry.TestField("Whse. Document Type", WarehouseEntry."Whse. Document Type"::" ");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure WhseDocTypeAfterInvtPickPost()
    var
        Item: Record Item;
        Bin: Record Bin;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseRequest: Record "Warehouse Request";
        WarehouseEntry: Record "Warehouse Entry";
        Qty: Decimal;
    begin
        // [FEATURE] [Inventory Pick]
        // [SCENARIO 377187] After posting Inventory Pick Warehouse Entry "Whse. Document Type" = " "

        // [GIVEN] Create Item, create and release Purchase Order.
        Initialize();
        LibraryInventory.CreateItem(Item);
        Qty := LibraryRandom.RandInt(10);  // Integer value Required.
        LibraryWarehouse.FindBin(Bin, LocationSilver.Code, '', 1);  // Find Bin of Index 1.

        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.", LocationSilver.Code, Qty, '', '');
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Create Inventory Put Away, autofill Qty to Handle, post.
        PrepareInvtPutAway(
          WarehouseActivityHeader."Source Document"::"Purchase Order", PurchaseHeader."No.",
          Item."No.", LocationSilver.Code, Bin.Code);
        PostInventoryPut(PurchaseHeader."No.");

        // [GIVEN] Create Sales Order, release, Create Inventory Pick.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", Qty, LocationSilver.Code);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        SelectWarehouseRequestAndCreateInvPutAwayPick(
          WarehouseRequest, SalesHeader."No.", WarehouseRequest."Source Document"::"Sales Order", DATABASE::"Sales Line",
          LocationSilver.Code, false);  // Pick Created.
        Clear(WarehouseActivityHeader);
        Clear(WarehouseActivityLine);
        FindWhseActivityLineAndInvPutAwayPick(
          WarehouseActivityHeader, WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Invt. Pick", LocationSilver.Code,
          SalesHeader."No.", WarehouseActivityLine."Action Type"::Take,
          WarehouseActivityHeader."Source Document"::"Sales Order");

        // [WHEN] Post Inventory Pick
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, true);
        // [THEN] Warehouse Entry of Inventory Pick "Whse. Document Type" = " "
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Location Code", LocationSilver.Code);
        WarehouseEntry.FindLast();
        WarehouseEntry.TestField("Whse. Document Type", WarehouseEntry."Whse. Document Type"::" ");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure WhseDocTypeAfterInvtMovementPost()
    var
        Item: Record Item;
        Bin: Record Bin;
        Bin2: Record Bin;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseEntry: Record "Warehouse Entry";
        InternalMovementHeader: Record "Internal Movement Header";
        Qty: Decimal;
    begin
        // [FEATURE] [Inventory Movement]
        // [SCENARIO 377187] After registering Inventory Movement Warehouse Entry "Whse. Document Type" = " "

        // [GIVEN] Create Item, create and release Purchase Order.
        Initialize();
        LibraryInventory.CreateItem(Item);
        Qty := LibraryRandom.RandInt(10);  // Integer value Required.
        LibraryWarehouse.FindBin(Bin, LocationSilver.Code, '', 1);  // Find Bin of Index 1.
        LibraryWarehouse.FindBin(Bin2, LocationSilver.Code, '', 2);  // Find Bin of Index 1.

        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.", LocationSilver.Code, Qty, '', '');
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Create Inventory Put Away, autofill Qty to Handle, post.
        PrepareInvtPutAway(
          WarehouseActivityHeader."Source Document"::"Purchase Order", PurchaseHeader."No.",
          Item."No.", LocationSilver.Code, Bin.Code);
        PostInventoryPut(PurchaseHeader."No.");

        // [GIVEN] Create Internal Movement, create Inventory Movement from Internal Movement.
        CreateInternalMovement(InternalMovementHeader, LocationSilver, Bin2, Item, Bin, Qty);
        LibraryWarehouse.CreateInvtMvmtFromInternalMvmt(InternalMovementHeader);

        WarehouseActivityHeader.SetCurrentKey("Location Code");
        WarehouseActivityHeader.SetRange("Location Code", LocationSilver.Code);
        WarehouseActivityHeader.FindLast();
        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);

        // [WHEN] Register The Movement created.
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
        // [THEN] Warehouse Entry of Inventory Movement "Whse. Document Type" = " "
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Location Code", LocationSilver.Code);
        WarehouseEntry.FindFirst();
        WarehouseEntry.TestField("Whse. Document Type", WarehouseEntry."Whse. Document Type"::" ");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CheckDocDateAndPostingDateSameWhenLinkDocTopPostingDateAndCommentLineShowsOnlySalesShipmentNumberNotDate()
    var
        Bin: array[2] of Record Bin;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        SalesHeader: array[2] of Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        ShipmentNo: Code[20];
    begin
        // [SCENARIO 599965] Verify that when 'Link Document Date to Posting Date' is enabled in Sales & Receivables Setup then Document Date and Posting Date remain the same. Also confirm that when using the Get Shipment Line function, the added comment line shows only the Sales Shipment Number without any date.
        Initialize();

        // [GIVEN] Set Link Doc. Date To Posting Date true in Sales & Receivables Setup.
        SetLinkDocToPostingDate();

        // [GIVEN] Create Customer
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create Location with Bin.
        CreateLocationWithBin(Location, Bin[1]);

        // [GIVEN] Create second Bin.
        LibraryWarehouse.CreateBin(Bin[2], Location.Code, '', '', '');

        // [GIVEN] Update the Inventory Posting Setup in Location.
        LibraryInventory.UpdateInventoryPostingSetup(Location);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Create a new Item & Update the Item inventory Setup.
        LibraryInventory.CreateItem(Item);
        UpdateItemInventory(Item."No.", Location.Code, Bin[2].Code, LibraryRandom.RandIntInRange(100, 200), false);

        // [GIVEN] Create Sales Order with multiple line.
        CreateSalesOrderWithMultipleLine(SalesHeader[1], Customer."No.", Location.Code, Item."No.");

        // [GIVEN] Update the work date before processing the shipment.
        WorkDate := CalcDate('<10D>', WorkDate());

        // [GIVEN] Release the Sales order.
        LibrarySales.ReleaseSalesDocument(SalesHeader[1]);

        // [GIVEN] Create the Warehouse Shipment.
        CreateAndReleaseWhseShipment(SalesHeader[1], WarehouseShipmentHeader);
        FindWhseShipmentNo(WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader[1]."No.");

        // [GIVEN] Create the Pick document.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        FindWarehouseActivityNo(WarehouseActivityLine, SalesHeader[1]."No.", WarehouseActivityLine."Activity Type"::Pick);

        // [GIVEN] Register the Warehouse Activity.
        RegisterWarehouseActivity(SalesHeader[1]."No.", WarehouseActivityLine."Activity Type"::Pick);

        // [WHEN] Ship the warehouse shipment document.
        PostWarehouseShipment(SalesHeader[1]."No.", WarehouseShipmentLine."Source Document"::"Sales Order");

        // [THEN] Verify that Document Date and Posting Date are same when 'Link Document Date to Posting Date' is enabled in the Sales & Receivables Setup.
        ShipmentNo := VerifyDocumentDateAndPostingDateSame(SalesHeader[1]."No.");

        // [GIVEN] Create a Sales Header and set the Document Type to Invoice.
        LibrarySales.CreateSalesHeader(SalesHeader[2], SalesHeader[2]."Document Type"::Invoice, Customer."No.");
        LibraryVariableStorage.Enqueue(SalesHeader[1]."No.");

        // [WHEN] When getting Sales Shipment Lines in a sales invoice.
        GetSalesShipmentLines(SalesHeader[2]);

        // [THEN] Comment line displays only the shipment number not the date.
        VerifyCommentLineDescriptionHasOnlyShipmentNo(SalesHeader[2]."No.", ShipmentNo);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure CreateLocationSetup()
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.DeleteAll(true);
        CreateFullWarehouseSetup(LocationWhite);  // Location: White.
        LibraryWarehouse.CreateLocationWMS(LocationYellow, false, true, true, true, true);  // Location Yellow: Bin Mandatory FALSE.
        LibraryWarehouse.CreateLocationWMS(LocationSilver, true, true, true, false, false);  // Location Silver: Bin Mandatory FALSE, Require Shipment FALSE.
        LibraryWarehouse.CreateLocationWMS(LocationSilver2, true, true, true, true, true);  // Location Silver2: Bin Mandatory, Require Shipment TRUE.
        CreateAndUpdateCrossDockBWLocation(LocationSilver3);  // Location Silver3: Cross-Dock, no Directed Put-away and Pick.
        LibraryWarehouse.CreateLocationWMS(LocationGreen, true, false, false, false, false);  // Location Green: Bin Mandatory TRUE.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationGreen.Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite.Code, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationSilver.Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationSilver2.Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationSilver3.Code, false);
        LibraryWarehouse.CreateNumberOfBins(LocationSilver.Code, '', '', LibraryRandom.RandInt(3) + 2, false);  // Value Required.
        LibraryWarehouse.CreateNumberOfBins(LocationSilver2.Code, '', '', LibraryRandom.RandInt(3) + 2, false);  // Value Required.
        LibraryWarehouse.CreateNumberOfBins(LocationGreen.Code, '', '', LibraryRandom.RandInt(3) + 2, false);  // Value Required.
        CreateBinsForCrossDock(LocationSilver3);
    end;

    local procedure NoSeriesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        WarehouseSetup: Record "Warehouse Setup";
    begin
        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify(true);

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure ItemJournalSetup()
    begin
        Clear(ItemJournalTemplate);
        ItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalTemplate.Modify(true);

        Clear(ItemJournalBatch);
        ItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        AssignNoSeriesForItemJournalBatch(ItemJournalBatch, '');  // Value required.
    end;

    local procedure WarehouseItemJournalSetup(LocationCode: Code[10])
    begin
        WarehouseItemJournalSetupSetTemplateType(LocationCode, WarehouseJournalTemplate.Type::Item);
    end;

    local procedure WarehouseItemJournalSetupSetTemplateType(LocationCode: Code[10]; TemplateType: Enum "Warehouse Journal Template Type")
    begin
        Clear(WarehouseJournalTemplate);
        WarehouseJournalTemplate.Init();
        LibraryWarehouse.SelectWhseJournalTemplateName(WarehouseJournalTemplate, TemplateType);
        WarehouseJournalTemplate.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        WarehouseJournalTemplate.Modify(true);

        Clear(WarehouseJournalBatch);
        WarehouseJournalBatch.Init();
        LibraryWarehouse.SelectWhseJournalBatchName(
          WarehouseJournalBatch, WarehouseJournalTemplate.Type, WarehouseJournalTemplate.Name, LocationCode);
        WarehouseJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        WarehouseJournalBatch.Modify(true);
    end;

    local procedure CreateFullWarehouseSetup(var Location: Record Location)
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);  // Value used for number of bin per zone.
    end;

    local procedure CreateAndUpdateCrossDockBWLocation(var Location: Record Location)
    begin
        LibraryWarehouse.CreateLocationWMS(Location, true, true, true, true, true);
        Location.Validate("Use Cross-Docking", true);
        Evaluate(
          Location."Cross-Dock Due Date Calc.",
          '<' + Format(LibraryRandom.RandIntInRange(1, 12)) + 'M' + '>');
        Location.Modify(true);
    end;

    local procedure CreateBinsForCrossDock(var Location: Record Location)
    var
        Bin: Record Bin;
    begin
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', LibraryRandom.RandInt(3) + 3, false); // Regular Bins
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 1, true);
        // Cross-Dock Bin
        FindBinsForLocation(Bin, Location.Code, false);
        SetBinCode(Location."Receipt Bin Code", Bin);
        SetBinCode(Location."Shipment Bin Code", Bin);
        FindBinsForLocation(Bin, Location.Code, true);
        Location.Validate("Cross-Dock Bin Code", Bin.Code);
        Location.Modify();
    end;

    local procedure SetBinCode(var BinCode: Code[20]; var Bin: Record Bin)
    begin
        BinCode := Bin.Code;
        Bin.Next();
    end;

    local procedure FindBinsForLocation(var Bin: Record Bin; LocationCode: Code[20]; CrossDock: Boolean)
    begin
        Bin.SetRange("Location Code", LocationCode);
        Bin.SetRange("Cross-Dock Bin", CrossDock);
        Bin.FindSet();
    end;

    local procedure AssignNoSeriesForItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; NoSeries: Code[20])
    begin
        ItemJournalBatch.Validate("No. Series", NoSeries);
        ItemJournalBatch.Modify(true);
    end;

    local procedure AssignSerialNoAndLotNoToWhseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ActionType: Enum "Warehouse Action Type"; ItemNo: Code[20]; LocationCode: Code[10]; SourceNo: Code[20])
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        FindWhseEntry(WarehouseEntry, ItemNo, LocationCode);
        FindWhseActivityLine(WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationCode, SourceNo, ActionType);
        WarehouseEntry.FindFirst();
        WarehouseActivityLine.FindFirst();
        AssignSerialNoAndLotNo(WarehouseActivityLine, WarehouseEntry);  // For first line.
        FindNextLineAndAssignSerialNoAndLotNo(WarehouseActivityLine, WarehouseEntry);  // For Second Line.
        FindNextLineAndAssignSerialNoAndLotNo(WarehouseActivityLine, WarehouseEntry);  // For Last line.
    end;

    local procedure AssignSerialNoAndLotNo(var WarehouseActivityLine: Record "Warehouse Activity Line"; var WarehouseEntry: Record "Warehouse Entry")
    begin
        WarehouseActivityLine.Validate("Serial No.", WarehouseEntry."Serial No.");
        WarehouseActivityLine.Validate("Lot No.", WarehouseEntry."Lot No.");
        WarehouseActivityLine.Modify(true);
    end;

    local procedure AssignTrackingToMultipleWhseReceiptLines(SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document")
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FilterWarehouseReceiptLine(WarehouseReceiptLine, SourceNo, SourceDocument);
        WarehouseReceiptLine.FindSet();
        repeat
            WarehouseReceiptLine.OpenItemTrackingLines();  // Open Tracking on Page Handler.
        until WarehouseReceiptLine.Next() = 0;
    end;

    local procedure CreateAndReleaseSalesOrderWithVariant(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; VariantCode: Code[10])
    begin
        CreateSalesOrder(SalesHeader, SalesLine, ItemNo, Quantity, LocationCode);
        SalesLine.Validate("Variant Code", VariantCode);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleasePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; VariantCode: Code[10]; BinCode: Code[20]; Tracking: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        CreatePurchaseLineWithLocationAndVariant(PurchaseHeader, PurchaseLine, ItemNo, LocationCode, Quantity, VariantCode);
        PurchaseLine.Validate("Bin Code", BinCode);
        PurchaseLine.Modify(true);
        if Tracking then
            PurchaseLine.OpenItemTrackingLines();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndReleasePurchaseOrderWithWhseReceipt(var PurchaseHeader: Record "Purchase Header"; var WarehouseReceiptLine: Record "Warehouse Receipt Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        CreateAndReleasePurchaseOrder(PurchaseHeader, ItemNo, LocationCode, Quantity, '', '', false);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWarehouseReceiptNo(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
    end;

    local procedure CalculateCrossDock(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity"; No: Code[20]; ItemNo: Code[20])
    begin
        CalculateCrossDockSimple(No);
        WhseCrossDockOpportunity.SetCurrentKey("Item No.", "Location Code");
        WhseCrossDockOpportunity.SetRange("Item No.", ItemNo);
        WhseCrossDockOpportunity.SetRange("Location Code", LocationWhite.Code);
        WhseCrossDockOpportunity.FindFirst();
        WhseCrossDockOpportunity.AutoFillQtyToCrossDock(WhseCrossDockOpportunity);
        WhseCrossDockOpportunity.CalcSums("Qty. to Cross-Dock");
    end;

    local procedure CalculateCrossDockSimple(No: Code[20])
    var
        WarehouseReceipt: TestPage "Warehouse Receipt";
    begin
        WarehouseReceipt.OpenEdit();
        WarehouseReceipt.FILTER.SetFilter("No.", No);
        WarehouseReceipt.CalculateCrossDock.Invoke();
    end;

    local procedure CalculateCrossDockOpportunityForWhseReceipt(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity"; WhseReceiptLineNo: Code[20])
    begin
        CalculateCrossDockSimple(WhseReceiptLineNo);
        WhseCrossDockOpportunity.SetRange("Source Name/No.", WhseReceiptLineNo);
        WhseCrossDockOpportunity.FindFirst();
        WhseCrossDockOpportunity.AutoFillQtyToCrossDock(WhseCrossDockOpportunity);
        WhseCrossDockOpportunity.Find();
    end;

    local procedure ChangeExpirationDateOnActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        repeat
            WarehouseActivityLine.Validate("Expiration Date", CalcDate('<' + '+' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate()));  // Value required.
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure ChangeQuantityInWhseInternalPutAwayLinePage(ItemNo: Code[20]; NewQuantity: Decimal)
    var
        WhseInternalPutAwayLine: TestPage "Internal Put-away Subform";
    begin
        WhseInternalPutAwayLine.OpenEdit();
        WhseInternalPutAwayLine.FILTER.SetFilter("Item No.", ItemNo);
        WhseInternalPutAwayLine.Quantity.SetValue(NewQuantity);
        WhseInternalPutAwayLine.OK().Invoke();
    end;

    local procedure CreateAndReleaseWhseShipment(var SalesHeader: Record "Sales Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWhseShipmentNo(WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);
    end;

    local procedure CreateNegAdjmtWhseItemLineWithBlankToBin(): Code[20]
    var
        Item: Record Item;
        Zone: Record Zone;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        ItemQty: Decimal;
    begin
        ItemQty := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        WarehouseItemJournalSetup(LocationWhite.Code);
        FindZone(Zone, LocationWhite.Code, LibraryWarehouse.SelectBinType(false, false, true, true));
        FindBinWithZone(Bin, LocationWhite.Code, Zone.Code);

        LibraryWarehouse.CreateBinContent(
          BinContent, LocationWhite.Code, Zone.Code, Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        MockInventory(
          LocationWhite.Code, Zone.Code, Bin.Code, Item."No.", Item."Base Unit of Measure",
          LibraryInventory.GetQtyPerForItemUOM(Item."No.", Item."Base Unit of Measure"), ItemQty);

        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name,
          LocationWhite.Code, Zone.Code, Bin.Code, WarehouseJournalLine."Entry Type"::"Negative Adjmt.",
          Item."No.", -ItemQty);

        WarehouseJournalLine.Validate("To Bin Code", '');
        WarehouseJournalLine.Modify(true);
        exit(WarehouseJournalLine."Whse. Document No.");
    end;

    local procedure CreatePositiveAdjmtWhseItemLineWithBlankFromBin(): Code[20]
    var
        Item: Record Item;
        Zone: Record Zone;
        Bin: Record Bin;
    begin
        WarehouseItemJournalSetup(LocationWhite.Code);
        FindZone(Zone, LocationWhite.Code, LibraryWarehouse.SelectBinType(false, false, true, true));
        FindBinWithZone(Bin, LocationWhite.Code, Zone.Code);

        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name,
          LocationWhite.Code, Zone.Code, Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.",
          LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));

        WarehouseJournalLine.Validate("From Bin Code", '');
        WarehouseJournalLine.Modify(true);
        exit(WarehouseJournalLine."Whse. Document No.");
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

    local procedure CreateItemUnitOfMeasure(var ItemUnitOfMeasure: Record "Item Unit of Measure"; ItemNo: Code[20]; QtyPerUnitOfMeasure: Integer)
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, ItemNo, UnitOfMeasure.Code, QtyPerUnitOfMeasure);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', ItemNo, Quantity, LocationCode, 0D);
    end;

    local procedure CreateAndReleaseSalesOrderWithReservation(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesOrder(SalesHeader, SalesLine, ItemNo, Quantity, LocationCode);
        SalesLine.ShowReservation();  // Using ReservationHandler to reserve.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleaseSalesOrderWithShipmentAndPartialPick(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; PickedQuantity: Decimal)
    var
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreateAndReleaseSalesOrderWithVariant(SalesHeader, SalesLine, ItemNo, Quantity, LocationCode, '');
        CreateAndReleaseWhseShipment(SalesHeader, WarehouseShipmentHeader);
        FindWhseShipmentNo(WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        FindWarehouseActivityNo(WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
        repeat
            WarehouseActivityLine.Validate("Qty. to Handle", PickedQuantity);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;
        RegisterWarehouseActivity(SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
    end;

    local procedure CreateAndReleaseSpecialOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesOrder(SalesHeader, SalesLine, ItemNo, Quantity, LocationCode);
        UpdatePurchasingCodeOnSalesLine(SalesHeader);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateRequisitionLineAndCarryOutReqWorksheet(ItemNo: Code[20]; VendorNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Template Type"::"Req.");
        LibraryPlanning.GetSpecialOrder(RequisitionLine, ItemNo);

        // Update vendor No on Requisition Line.
        UpdateRequisitionLine(RequisitionLine, VendorNo, ItemNo);
        LibraryPlanning.CarryOutReqWksh(
          RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(),
          StrSubstNo(ReferenceText, RequisitionLine.FieldCaption("Vendor No."), RequisitionLine."Vendor No."));
    end;

    local procedure ChangeUnitOfMeasureOnWhseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ActivityType: Enum "Warehouse Activity Type"; LocationCode: Code[10]; SourceNo: Code[20])
    begin
        FindWhseActivityLine(WarehouseActivityLine, ActivityType, LocationCode, SourceNo, WarehouseActivityLine."Action Type"::Place);
        repeat
            LibraryWarehouse.ChangeUnitOfMeasure(WarehouseActivityLine);
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure CreateWarehouseReceiptSetup(var Item: Record Item; var SalesHeader: Record "Sales Header"; var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; SalesQuantity: Integer; PurchaseQuantity: Integer)
    var
        SalesLine: Record "Sales Line";
    begin
        LibraryInventory.CreateItem(Item);
        CreateAndReleaseSalesOrderWithVariant(SalesHeader, SalesLine, Item."No.", SalesQuantity, LocationCode, '');
        CreateAndReleasePurchaseOrder(PurchaseHeader, Item."No.", LocationCode, PurchaseQuantity, '', '', false);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
    end;

    local procedure CreateOrderWithItemVariantSetup(var SalesHeader: Record "Sales Header"; var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; Quantity: Integer)
    var
        SalesLine: Record "Sales Line";
    begin
        CreateAndReleaseSalesOrderWithVariant(SalesHeader, SalesLine, ItemNo, Quantity, LocationCode, VariantCode);
        CreateAndReleasePurchaseOrder(PurchaseHeader, ItemNo, LocationCode, Quantity, VariantCode, '', false)
    end;

    local procedure CreateItemWithWarehouseClass(var Item: Record Item; var WarehouseClass: Record "Warehouse Class")
    begin
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateWarehouseClass(WarehouseClass);
        Item.Validate("Warehouse Class Code", WarehouseClass.Code);
        Item.Modify();
    end;

    local procedure CreateItemWithReorderingPolicy(var Item: Record Item; ReorderingPolicy: Enum "Reordering Policy"; IncludeInventory: Boolean)
    begin
        CreateLotTrackedItem(Item);
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Validate("Include Inventory", IncludeInventory);
        Item.Modify(true);
    end;

    local procedure CreateBinWithWarehouseClass(var Bin: Record Bin; LocationCode: Code[10]; PutAway: Boolean; Pick: Boolean; Receive: Boolean; Ship: Boolean; WarehouseClassCode: Code[10])
    var
        Zone: Record Zone;
        BinTypeCode: Code[10];
    begin
        BinTypeCode := LibraryWarehouse.SelectBinType(Receive, Ship, PutAway, Pick);
        FindZone(Zone, LocationCode, BinTypeCode);
        LibraryWarehouse.CreateBin(
          Bin, LocationCode,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), 1,
            LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))), Zone.Code, BinTypeCode);
        UpdateBinWithWarehouseClassCode(Bin, WarehouseClassCode);
    end;

    local procedure CreateAndUpdateBinCodeOnWarehouseReceiptLine(var Bin: Record Bin; LocationCode: Code[10]; ItemNo: Code[20]; WarehouseClassCode: Code[10])
    begin
        CreateBinWithWarehouseClass(Bin, LocationCode, false, false, true, false, WarehouseClassCode);  // Bin Type Put Away.
        UpdateBinOnWarehouseReceiptLine(ItemNo, Bin.Code);
    end;

    local procedure CreateAndUpdateBinCodeOnWarehouseShipmentLine(var Bin: Record Bin; LocationCode: Code[10]; ItemNo: Code[20]; WarehouseClassCode: Code[10])
    begin
        CreateBinWithWarehouseClass(Bin, LocationCode, false, false, false, true, WarehouseClassCode);  // Bin Type Pick.
        UpdateBinOnWarehouseShipmentLine(ItemNo, Bin.Code);
    end;

    local procedure CreateMultipleItemUnitOfMeasureSetup(var Item: Record Item; var ItemUnitOfMeasure: Record "Item Unit of Measure"; var ItemUnitOfMeasure2: Record "Item Unit of Measure"; var ItemUnitOfMeasure3: Record "Item Unit of Measure")
    var
        QtyPerUnitOfMeasure: Integer;
    begin
        LibraryInventory.CreateItem(Item);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", 1);  // Value required.
        QtyPerUnitOfMeasure := 11; // Set QtyPerUnitOfMeasure as a prime number to repro UOM rounding conversion Issue
        CreateItemUnitOfMeasure(ItemUnitOfMeasure2, Item."No.", QtyPerUnitOfMeasure);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure3, Item."No.", 2 * QtyPerUnitOfMeasure);
        Item.Validate("Purch. Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Validate("Put-away Unit of Measure Code", ItemUnitOfMeasure2.Code);
        Item.Validate("Sales Unit of Measure", ItemUnitOfMeasure3.Code);
        Item.Modify(true);
    end;

    local procedure CreateSpecialOrderWithItemUnitOfMeasureSetup(var PurchaseHeader: Record "Purchase Header"; var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndReleaseSpecialOrder(SalesHeader, ItemNo, Quantity, LocationCode);
        CreateRequisitionLineAndCarryOutReqWorksheet(ItemNo, Vendor."No.");
        FindPurchaseHeader(PurchaseHeader, Vendor."No.", LocationCode);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndReleasePurchaseReturnOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", '');
        CreatePurchaseLineWithLocationAndVariant(PurchaseHeader, PurchaseLine, ItemNo, LocationCode, Quantity, '');
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndReleasePurchReturnOrderAfterGetPostedDocumentLinesToReverse(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", VendorNo);
        PurchaseHeader.GetPstdDocLinesToReverse();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateItemTrackingCode(var ItemTrackingCode: Record "Item Tracking Code"; Lot: Boolean; Serial: Boolean; StrictExpirationPosting: Boolean)
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, Serial, Lot);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", Lot);
        ItemTrackingCode.Validate("SN Warehouse Tracking", Serial);
        ItemTrackingCode.Validate("Use Expiration Dates", StrictExpirationPosting);
        ItemTrackingCode.Validate("Strict Expiration Posting", StrictExpirationPosting);
        ItemTrackingCode.Modify(true);
    end;

    local procedure CreateItemWithTrackingCode(var Item: Record Item; ItemTrackingCode: Code[10])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode);
        Item.Modify(true);
    end;

    local procedure CreatePurchaseLinesAndReleaseDocument(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; NoOfLine: Integer; Tracking: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
        Counter: Integer;
    begin
        for Counter := 1 to NoOfLine do begin
            CreatePurchaseLineWithLocationAndVariant(PurchaseHeader, PurchaseLine, ItemNo, LocationCode, Quantity, '');
            if Tracking then
                PurchaseLine.OpenItemTrackingLines();
        end;
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreatePurchaseLineWithLocationAndVariant(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; VariantCode: Code[10])
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Variant Code", VariantCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateLotTrackedItem(var Item: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        CreateItemTrackingCode(ItemTrackingCode, true, false, false);  // Create Iten Tracking with Lot TRUE.
        CreateItemWithTrackingCode(Item, ItemTrackingCode.Code);
    end;

    local procedure CreateAndRegisterWarehouseReclassJournal(ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WhseReclassificationJournal: TestPage "Whse. Reclassification Journal";
    begin
        FindBinContent(BinContent, ItemNo);
        FindBinWithZone(Bin, LocationCode, BinContent."Zone Code");
        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Type::Reclassification, LocationCode);
        WhseReclassificationJournal.OpenEdit();
        WhseReclassificationJournal.CurrentLocationCode.SetValue(LocationCode);
        WhseReclassificationJournal.CurrentJnlBatchName.SetValue(WarehouseJournalBatch.Name);
        WhseReclassificationJournal."Whse. Document No.".SetValue(WarehouseJournalBatch.Name);
        WhseReclassificationJournal."Item No.".SetValue(ItemNo);
        WhseReclassificationJournal."From Zone Code".SetValue(BinContent."Zone Code");
        WhseReclassificationJournal."From Bin Code".SetValue(BinContent."Bin Code");
        WhseReclassificationJournal."To Zone Code".SetValue(BinContent."Zone Code");
        WhseReclassificationJournal."To Bin Code".SetValue(Bin.Code);
        WhseReclassificationJournal.Quantity.SetValue(Quantity);
        WhseReclassificationJournal.ItemTrackingLines.Invoke();
        WhseReclassificationJournal.Register.Invoke();  // Invoke WhseItemTrackingLinesHandler Handler.
    end;

    local procedure CreateWhseWorksheetName(var WhseWorksheetName: Record "Whse. Worksheet Name"; LocationCode: Code[10])
    var
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
    begin
        WhseWorksheetTemplate.SetRange(Type, WhseWorksheetTemplate.Type::Movement);
        WhseWorksheetTemplate.FindFirst();
        LibraryWarehouse.CreateWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, LocationCode);
    end;

    local procedure CreateSalesOrderWithUpdatedBinAndPickSetup(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    begin
        CreateSalesOrder(SalesHeader, SalesLine, ItemNo, Quantity, LocationCode);
        SalesLine.Validate("Bin Code", BinCode);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        CreateAndReleaseWhseShipment(SalesHeader, WarehouseShipmentHeader);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
    end;

    local procedure CreatePutAwayWithPurchaseOrderSetup(var PurchaseHeader: Record "Purchase Header"; var WarehouseReceiptLine: Record "Warehouse Receipt Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        CreateAndReleasePurchaseOrderWithWhseReceipt(
          PurchaseHeader, WarehouseReceiptLine, ItemNo, LocationCode, Quantity);
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure CreateItemWithItemTrackingCode(var Item: Record Item; ItemTrackingCode: Code[10]; SerialNo: Boolean)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode);
        if SerialNo then
            Item.Validate("Serial Nos.", LibraryUtility.GetGlobalNoSeriesCode())
        else
            Item.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; VariantCode: Code[10]; BinCode: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLineWithLocationVariantAndBinCode(PurchaseHeader, PurchaseLine, ItemNo, LocationCode, Quantity, VariantCode, BinCode);
    end;

    local procedure CreatePurchaseLineWithLocationVariantAndBinCode(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; VariantCode: Code[10]; BinCode: Code[20])
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Variant Code", VariantCode);
        PurchaseLine.Validate("Bin Code", BinCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesOrderWithMultipleLines(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var SalesLine2: Record "Sales Line"; ItemNo: Code[20]; ItemNo2: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        CreateSalesOrder(SalesHeader, SalesLine, ItemNo, Quantity, LocationCode);
        CreateSalesLine(SalesHeader, SalesLine2, ItemNo2, LocationCode, Quantity);
    end;

    local procedure CreatePurchaseOrderWithMultipleLines(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var PurchaseLine2: Record "Purchase Line"; ItemNo: Code[20]; ItemNo2: Code[20]; LocationCode: Code[10]; Quantity: Decimal; BinCode: Code[20])
    begin
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, ItemNo, LocationCode, Quantity, '', BinCode);
        CreatePurchaseLineWithLocationVariantAndBinCode(PurchaseHeader, PurchaseLine2, ItemNo2, LocationSilver.Code, Quantity, '', BinCode);
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateWhseInternalPutAway(var WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header"; LocationCode: Code[10]; FromZonecode: Code[10]; FromBinCode: Code[20]; ItemNo: Code[20]; x: Integer)
    var
        i: Integer;
    begin
        LibraryWarehouse.CreateWhseInternalPutawayHdr(WhseInternalPutAwayHeader, LocationCode);
        WhseInternalPutAwayHeader.Validate("From Zone Code", FromZonecode);
        WhseInternalPutAwayHeader.Validate("From Bin Code", FromBinCode);
        WhseInternalPutAwayHeader.Modify(true);
        for i := 1 to x do
            GetBinContentFromWhseInternalPutAway(WhseInternalPutAwayHeader, LocationCode, ItemNo);
    end;

    local procedure CreateWhseInternalPutAwayWithItemTracking(var WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header"; LocationCode: Code[10]; FromZonecode: Code[10]; FromBinCode: Code[20]; ItemNo: Code[20]; Qty: Decimal; LotNo: Code[50]; SerialNo: Code[50])
    var
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
    begin
        LibraryWarehouse.CreateWhseInternalPutawayHdr(WhseInternalPutAwayHeader, LocationCode);
        WhseInternalPutAwayHeader.Validate("From Zone Code", FromZonecode);
        WhseInternalPutAwayHeader.Validate("From Bin Code", FromBinCode);
        WhseInternalPutAwayHeader.Modify(true);

        LibraryWarehouse.CreateWhseInternalPutawayLine(
          WhseInternalPutAwayHeader, WhseInternalPutAwayLine, ItemNo, Qty);
        LibraryVariableStorage.Enqueue(WhseItemTrackingPageHandlerBody::LotSerialNo);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(SerialNo);
        LibraryVariableStorage.Enqueue(Qty);
        WhseInternalPutAwayLine.OpenItemTrackingLines();
    end;

    local procedure CreateWhseReceiptForCrossDockedItem(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; ReceiptQty: Decimal; SalesQty: Decimal; CrossDockedQty: Decimal)
    var
        Item: Record Item;
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        LibraryInventory.CreateItem(Item);
        CreateFullWarehouseSetup(Location);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        CreateAndReleaseSalesOrderWithVariant(
          SalesHeader, SalesLine, Item."No.", SalesQty, Location.Code, '');

        CreateAndReleasePurchaseOrderWithWhseReceipt(
          PurchaseHeader, WarehouseReceiptLine, Item."No.", Location.Code, CrossDockedQty);
        CalculateCrossDockSimple(WarehouseReceiptLine."No.");
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        CreateAndReleasePurchaseOrderWithWhseReceipt(
          PurchaseHeader, WarehouseReceiptLine, Item."No.", Location.Code, ReceiptQty);
    end;

    local procedure CreatePickFromPurchaseReturnOrder(var PurchaseHeader: Record "Purchase Header")
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        LibraryWarehouse.CreateWhseShipmentFromPurchaseReturnOrder(PurchaseHeader);
        FindWhseShipmentNo(
          WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Purchase Return Order", PurchaseHeader."No.");
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
    end;

    local procedure CreateAndPartialRegisterPickFromPurchaseReturnOrder(var PurchaseHeader: Record "Purchase Header"; Qty: Decimal; PartialQty: Decimal; MultiplePick: Boolean)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        CreateAndReleasePurchReturnOrderAfterGetPostedDocumentLinesToReverse(PurchaseHeader, PurchaseHeader."Buy-from Vendor No.");
        CreatePickFromPurchaseReturnOrder(PurchaseHeader);
        FindWarehouseActivityNo(WarehouseActivityLine, PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
        UpdateQuantityToHandleOnWhseActivityLines(WarehouseActivityLine, Qty);
        RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::Pick);

        if MultiplePick then begin
            PostWarehouseShipment(PurchaseHeader."No.", WarehouseShipmentLine."Source Document"::"Purchase Return Order");
            FindWarehouseActivityNo(WarehouseActivityLine, PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
            UpdateQuantityToHandleOnWhseActivityLines(WarehouseActivityLine, PartialQty);
            RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
        end;
    end;

    local procedure CreateAndPostInvtPutAwayFromPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        CreateAndReleasePurchaseOrder(PurchaseHeader, ItemNo, LocationCode, Qty, '', '', true);
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Purchase Order", PurchaseHeader."No.", true, false, false);
        FindWarehouseActivityNo(WarehouseActivityLine, PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away");
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
        PostInventoryPut(PurchaseHeader."No.");
    end;

    local procedure CreateAndRegisterMovementByGetBinContent(ItemNo: Code[20]; LocationCode: Code[10])
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Bin: Record Bin;
    begin
        // Create Movement by "Get Bin Content" in Movement Worksheet
        GetBinContentFromMovementWorksheet(WhseWorksheetLine, LocationCode, ItemNo);
        Commit();
        WhseWorksheetLine.MovementCreate(WhseWorksheetLine);

        // Update Bin Code for Place line and Register Movement
        CreateBinWithWarehouseClass(Bin, LocationWhite.Code, false, false, true, false, ''); // Bin Type Put-away, with Warehouse Class Code = Blank
        UpdatePlaceBinCodeInMovement(WarehouseActivityLine, ItemNo, LocationCode, Bin.Code);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type"::Movement, WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure CreateAndRegisterPutAwayFromInternalPutAwayByGetBinContent(ItemNo: Code[20]; Quantity: Decimal)
    var
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Bin: Record Bin;
    begin
        // Create Whse. Internal Put-away by "Get Bin Content"
        Bin.Get(LocationWhite.Code, LocationWhite."Cross-Dock Bin Code");
        WhseInternalPutAwayLine.Init();
        CreatePutAwayFromInternalPutAway(
          WhseInternalPutAwayHeader, WhseInternalPutAwayLine, LocationWhite.Code, Bin."Zone Code", Bin.Code, ItemNo, false, Quantity);

        // Register Put-away
        RegisterWarehouseActivityWithItemNo(ItemNo, WarehouseActivityLine."Activity Type"::"Put-away",
          LocationWhite.Code, '', WarehouseActivityLine."Action Type"::Place);
    end;

    local procedure CreatePutAwayFromInternalPutAwayPage(WhseInternalPutAwayHeaderNo: Code[20])
    var
        WhseInternalPutAwayPage: TestPage "Whse. Internal Put-away";
    begin
        WhseInternalPutAwayPage.OpenEdit();
        WhseInternalPutAwayPage.FILTER.SetFilter("No.", WhseInternalPutAwayHeaderNo);
        WhseInternalPutAwayPage.CreatePutAway.Invoke();
    end;

    local procedure CreatePutAwayFromInternalPutAway(var WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header"; WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line"; LocationCode: Code[10]; ZoneCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; UpdateQty: Boolean; NewQuantity: Decimal)
    var
        WhseIntPutAwayRelease: Codeunit "Whse. Int. Put-away Release";
    begin
        CreateWhseInternalPutAway(WhseInternalPutAwayHeader, LocationCode, ZoneCode, BinCode, ItemNo, 1);
        WhseInternalPutAwayLine.SetRange("No.", WhseInternalPutAwayHeader."No.");
        WhseInternalPutAwayLine.FindFirst();
        if UpdateQty then
            WhseInternalPutAwayLine.Validate(Quantity, NewQuantity);
        WhseInternalPutAwayLine.Modify(true);
        WhseIntPutAwayRelease.Release(WhseInternalPutAwayHeader);
        WhseInternalPutAwayLine.CreatePutAwayDoc(WhseInternalPutAwayLine);
    end;

    local procedure CreatePutAwayFromInternalPutAwayWithLotSerialNos(var WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header"; WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line"; LocationCode: Code[10]; ZoneCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; LotNo: Code[50]; SerialNo: Code[50]; NewQuantity: Decimal)
    var
        WhseIntPutAwayRelease: Codeunit "Whse. Int. Put-away Release";
    begin
        CreateWhseInternalPutAwayWithItemTracking(
          WhseInternalPutAwayHeader, LocationCode, ZoneCode, BinCode, ItemNo, NewQuantity, LotNo, SerialNo);
        WhseIntPutAwayRelease.Release(WhseInternalPutAwayHeader);

        WhseInternalPutAwayLine.SetRange("No.", WhseInternalPutAwayHeader."No.");
        WhseInternalPutAwayLine.FindFirst();
        WhseInternalPutAwayLine.CreatePutAwayDoc(WhseInternalPutAwayLine);
    end;

    local procedure CreateAndRefreshReleasedProductionOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20])
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Validate("Bin Code", BinCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateAndPostOutputJournal(ItemNo: Code[20]; ProductionOrderNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Output);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryManufacturing.CreateOutputJournal(ItemJournalLine, ItemJournalTemplate, ItemJournalBatch, ItemNo, ProductionOrderNo);
        ItemJournalLine.Validate("Output Quantity", Quantity);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure DefineQuantitiesForPurchaseAndSalesDocuments(var InventoryQty: Decimal; var PurchaseQty: Decimal; var SalesQty: Decimal; var PickQty: Decimal; var CrossDockQty: Decimal)
    begin
        InventoryQty := LibraryRandom.RandIntInRange(41, 80);
        PurchaseQty := LibraryRandom.RandIntInRange(5000, 10000);
        SalesQty := LibraryRandom.RandIntInRange(100, 200);
        PickQty := LibraryRandom.RandIntInRange(10, 20);
        CrossDockQty := LibraryRandom.RandIntInRange(10, 20);
    end;

    local procedure DefineSupplyAndDemandQtys(var PurchaseQty: Decimal; var SalesQty: Decimal; var CrossDockQty: Decimal)
    begin
        PurchaseQty := LibraryRandom.RandIntInRange(100, 200);
        SalesQty := LibraryRandom.RandIntInRange(50, 80);
        CrossDockQty := LibraryRandom.RandIntInRange(10, 20);
    end;

    local procedure PostWhseReceiptWithUOMAndCreateSalesHeader(var ItemUnitOfMeasureToTest: Record "Item Unit of Measure"; var ExpectedQuantity: Decimal; var SalesHeader: Record "Sales Header"; Divider: Decimal)
    var
        Item: Record Item;
        ItemUnitOfMeasure1: Record "Item Unit of Measure";
        ItemUnitOfMeasure2: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        SalesLine: Record "Sales Line";
        Quantity: Decimal;
    begin
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateMultipleItemUnitOfMeasureSetup(Item, ItemUnitOfMeasure1, ItemUnitOfMeasure2, ItemUnitOfMeasureToTest);
        CreateAndReleasePurchaseOrder(PurchaseHeader, Item."No.", LocationYellow.Code, Quantity / Divider, '', '', false);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWarehouseReceiptNo(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        ExpectedQuantity := Quantity / ItemUnitOfMeasure1."Qty. per Unit of Measure" / Divider;
        CreateAndReleaseSalesOrderWithVariant(SalesHeader, SalesLine, Item."No.", Quantity / Divider, LocationYellow.Code, '');
    end;

    local procedure DeleteWhseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; LocationCode: Code[10]; SourceNo: Code[20])
    begin
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationCode, SourceNo,
          WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.Delete(true);
    end;

    local procedure DeleteWhseShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SourceNo: Code[20])
    begin
        FindWhseShipmentNo(WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Sales Order", SourceNo);
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.ReopenWhseShipment(WarehouseShipmentHeader);
        WarehouseShipmentLine.Delete(true);
    end;

    local procedure RecreatePickFromSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; Quantity: Decimal)
    begin
        UpdateQuantityOnSalesLine(SalesHeader, SalesLine, Quantity);
        CreateAndReleaseWhseShipment(SalesHeader, WarehouseShipmentHeader);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
    end;

    local procedure FindZone(var Zone: Record Zone; LocationCode: Code[10]; BinTypeCode: Code[20])
    begin
        Zone.SetRange("Location Code", LocationCode);
        Zone.SetRange("Bin Type Code", BinTypeCode);
        Zone.FindFirst();
    end;

    local procedure FindWhseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ActivityType: Enum "Warehouse Activity Type"; LocationCode: Code[10]; SourceNo: Code[20]; ActionType: Enum "Warehouse Action Type")
    begin
        FindWarehouseActivityNo(WarehouseActivityLine, SourceNo, ActivityType);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.FindSet();
    end;

    local procedure FindWarehouseActivityNo(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure FindWhseActivityLineByItem(var WarehouseActivityLine: Record "Warehouse Activity Line"; ActivityType: Enum "Warehouse Activity Type"; LocationCode: Code[10]; ItemNo: Code[20]; ActionType: Enum "Warehouse Action Type")
    begin
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.FindSet();
    end;

    local procedure FindWarehouseReceiptNo(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    begin
        WarehouseReceiptLine.SetRange("Source Document", SourceDocument);
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.FindFirst();
    end;

    local procedure FindWhseShipmentNo(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    begin
        WarehouseShipmentLine.SetRange("Source Document", SourceDocument);
        WarehouseShipmentLine.SetRange("Source No.", SourceNo);
        WarehouseShipmentLine.FindFirst();
    end;

    local procedure FindPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; BuyFromVendorNo: Code[20]; LocationCode: Code[10])
    begin
        PurchaseHeader.SetRange("Buy-from Vendor No.", BuyFromVendorNo);
        PurchaseHeader.SetRange("Location Code", LocationCode);
        PurchaseHeader.FindFirst();
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.FindFirst();
    end;

    local procedure FindRegisterWarehouseActivityLine(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; ActivityType: Enum "Warehouse Activity Type"; ActionType: Enum "Warehouse Action Type"; LocationCode: Code[10]; SourceNo: Code[20])
    begin
        RegisteredWhseActivityLine.SetRange("Activity Type", ActivityType);
        RegisteredWhseActivityLine.SetRange("Location Code", LocationCode);
        RegisteredWhseActivityLine.SetRange("Action Type", ActionType);
        RegisteredWhseActivityLine.SetRange("Source No.", SourceNo);
        RegisteredWhseActivityLine.FindFirst();
    end;

    local procedure FindWhseEntry(var WarehouseEntry: Record "Warehouse Entry"; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        WarehouseEntry.SetRange("Item No.", ItemNo);
        WarehouseEntry.SetRange("Location Code", LocationCode);
        WarehouseEntry.SetRange("Source Type", DATABASE::"Item Journal Line");
        WarehouseEntry.FindSet();
    end;

    local procedure FindNextLineAndAssignSerialNoAndLotNo(var WarehouseActivityLine: Record "Warehouse Activity Line"; var WarehouseEntry: Record "Warehouse Entry")
    begin
        WarehouseEntry.Next();
        WarehouseActivityLine.Next();
        AssignSerialNoAndLotNo(WarehouseActivityLine, WarehouseEntry);
    end;

    local procedure FilterWarehouseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document")
    begin
        WarehouseReceiptLine.SetRange("Source Document", SourceDocument);
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
    end;

    local procedure FindWarehouseActivityHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; SourceNo: Code[20])
    begin
        WarehouseActivityHeader.SetRange("Source No.", SourceNo);
        WarehouseActivityHeader.FindFirst();
    end;

    local procedure FindBin(var Bin: Record Bin; LocationCode: Code[10]; IsCrossDock: Boolean)
    var
        Zone: Record Zone;
    begin
        FindZone(Zone, LocationCode, LibraryWarehouse.SelectBinType(false, false, true, IsCrossDock));
        FindBinWithZone(Bin, LocationCode, Zone.Code);
    end;

    local procedure FindBinContent(var BinContent: Record "Bin Content"; ItemNo: Code[20])
    begin
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.FindFirst();
    end;

    local procedure FindBinWithZone(var Bin: Record Bin; LocationCode: Code[10]; ZoneCode: Code[10])
    begin
        Bin.SetRange("Location Code", LocationCode);
        Bin.SetRange("Zone Code", ZoneCode);
        Bin.FindFirst();
    end;

    local procedure FindWhseMovementLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ItemNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; LocationCode: Code[10]; SourceNo: Code[20])
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.FindSet();
    end;

    local procedure FindWhseActivityLineAndInvPutAwayPick(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var WarehouseActivityLine: Record "Warehouse Activity Line"; ActivityType: Enum "Warehouse Activity Type"; LocationCode: Code[10]; DocumentNo: Code[20]; ActionType: Enum "Warehouse Action Type"; SourceDocument: Enum "Warehouse Activity Source Document")
    begin
        FindWhseActivityLine(WarehouseActivityLine, ActivityType, LocationCode, DocumentNo, ActionType);
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
        FindInventoryPutAwayPick(WarehouseActivityHeader, ActivityType, SourceDocument, DocumentNo);
    end;

    local procedure FindInventoryPutAwayPick(var WarehouseActivityHeader: Record "Warehouse Activity Header"; Type: Enum "Warehouse Activity Type"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    begin
        WarehouseActivityHeader.SetRange(Type, Type);
        WarehouseActivityHeader.SetRange("Source Document", SourceDocument);
        WarehouseActivityHeader.SetRange("Source No.", SourceNo);
        WarehouseActivityHeader.FindFirst();
    end;

    local procedure FindItemLedgEntryNo(DocumentNo: Code[20]): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.FindFirst();
        exit(ItemLedgerEntry."Entry No.");
    end;

    local procedure GetBinContentFromMovementWorksheet(var WhseWorksheetLine: Record "Whse. Worksheet Line"; LocationCode: Code[10]; ItemNo: Code[20])
    var
        BinContent: Record "Bin Content";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
    begin
        CreateWhseWorksheetName(WhseWorksheetName, LocationCode);
        WhseWorksheetLine.Init();
        WhseWorksheetLine.Validate("Worksheet Template Name", WhseWorksheetName."Worksheet Template Name");
        WhseWorksheetLine.Validate(Name, WhseWorksheetName.Name);
        WhseWorksheetLine.Validate("Location Code", LocationCode);
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Item No.", ItemNo);
        WhseInternalPutAwayHeader.Init();
        LibraryWarehouse.WhseGetBinContent(
            BinContent, WhseWorksheetLine, WhseInternalPutAwayHeader, "Warehouse Destination Type 2"::MovementWorksheet);
    end;

    local procedure GetBinContentFromWhseInternalPutAway(WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header"; LocationCode: Code[10]; ItemNo: Code[20])
    var
        BinContent: Record "Bin Content";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        WhseWorksheetLine.Init();
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Item No.", ItemNo);
        // Use 1 for getting bin content from Whse. Internal Put-away.
        LibraryWarehouse.WhseGetBinContent(
            BinContent, WhseWorksheetLine, WhseInternalPutAwayHeader, "Warehouse Destination Type 2"::WhseInternalPutawayHeader);
    end;

    local procedure InitGetBinContentWithLotNoScenario(var Item: Record Item; IsMultiple: Boolean) TrackingQuantity2: Decimal
    var
        ItemTrackingCode: Record "Item Tracking Code";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        TrackingQuantity1: Decimal;
        ActionType: Enum "Warehouse Action Type";
    begin
        // Create Item with Item Tracking Code for Lot. Get Bin code from White location.
        CreateItemTrackingCode(ItemTrackingCode, true, false, false); // Set Lot No. as TRUE.
        CreateItemWithTrackingCode(Item, ItemTrackingCode.Code);

        // Update Inventory with Location and Lot No.
        TrackingQuantity1 := LibraryRandom.RandIntInRange(5, 20);
        TrackingQuantity2 := LibraryRandom.RandIntInRange(30, 40);
        TrackingQuantity := TrackingQuantity1 + TrackingQuantity2;
        if IsMultiple then begin
            LibraryVariableStorage.Enqueue(WhseItemTrackingPageHandlerBody::MultipleLotNo);
            LibraryVariableStorage.Enqueue(TrackingQuantity1); // This is Lot No. and Quantity (Base) for 1st item tracking line.
            LibraryVariableStorage.Enqueue(TrackingQuantity2); // This is Lot No. and Quantity (Base) for 2nd item tracking line.
        end;
        UpdateInventoryAndAssignTrackingInWhseItemJournal(LocationWhite, Item, TrackingQuantity);

        // Create Shipment from Sales Order. Create Pick from Shipment.
        CreateSalesOrderWithUpdatedBinAndPickSetup(
          SalesHeader, SalesLine, WarehouseShipmentHeader, Item."No.", LocationWhite.Code, '', TrackingQuantity1);

        // Update Lot No on Warehouse Activity Line.
        for ActionType := WarehouseActivityLine."Action Type"::Take to WarehouseActivityLine."Action Type"::Place do
            AssignSerialNoAndLotNoToWhseActivityLine(
              WarehouseActivityLine, ActionType, Item."No.", LocationWhite.Code, SalesHeader."No.");
    end;

    local procedure InitGetBinContentWithSeriesNoScenario(var Item: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
        ActionType: Enum "Warehouse Action Type";
    begin
        // Setup: Create Item with Item Tracking Code for SN. Get Bin code from White location.
        CreateItemTrackingCode(ItemTrackingCode, false, true, false); // Set Series No. as TRUE.
        CreateItemWithTrackingCode(Item, ItemTrackingCode.Code);

        // Update Inventory with Location and Series No.
        LotSpecific := false; // Assign value to Global variable.
        Quantity := LibraryRandom.RandIntInRange(3, 4);
        TrackingQuantity := Quantity;
        UpdateInventoryAndAssignTrackingInWhseItemJournal(LocationWhite, Item, Quantity);

        // Create Shipment from Sales Order. Create Pick from Shipment.
        CreateSalesOrderWithUpdatedBinAndPickSetup(
          SalesHeader, SalesLine, WarehouseShipmentHeader, Item."No.", LocationWhite.Code, '', Quantity - 1);

        // Update Series No on Warehouse Activity Lines.
        for ActionType := WarehouseActivityLine."Action Type"::Take to WarehouseActivityLine."Action Type"::Place do
            AssignSerialNoAndLotNoToWhseActivityLine(
              WarehouseActivityLine, ActionType, Item."No.", LocationWhite.Code, SalesHeader."No.");
    end;

    local procedure InitSetupItemAndLocaiton(var Item: Record Item): Code[10]
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWMS(Location, false, true, true, false, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        CreateItemWithReorderingPolicy(Item, Item."Reordering Policy"::"Lot-for-Lot", true);
        exit(Location.Code);
    end;

    local procedure PostWarehouseReceipt(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptNo(WarehouseReceiptLine, SourceDocument, SourceNo);
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure PostWarehouseShipment(PurchaseHeaderNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document")
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        FindWhseShipmentNo(WarehouseShipmentLine, SourceDocument, PurchaseHeaderNo);
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);  // Use FALSE for only Shipment.
    end;

    local procedure PostWhseReceiptAndRegisterWhseActivity(SourceNo: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        PostWarehouseReceipt(WarehouseActivityLine."Source Document"::"Purchase Order", SourceNo);
        RegisterWarehouseActivity(SourceNo, WarehouseActivityLine."Activity Type"::"Put-away");
    end;

    local procedure PostInventoryPick(SourceNo: Code[20]; AsInvoice: Boolean)
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        FindWarehouseActivityHeader(WarehouseActivityHeader, SourceNo);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, AsInvoice);
    end;

    local procedure PostInventoryPut(SourceNo: Code[20])
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        WarehouseActivityHeader.SetRange(Type, WarehouseActivityHeader.Type::"Invt. Put-away");
        FindWarehouseActivityHeader(WarehouseActivityHeader, SourceNo);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, true);
    end;

    local procedure PrepareInventoryAndTwoOutstandingReceiptsForPurchaseOrders(var LocationCode: Code[10]; var FirstWhseReceiptLineNo: Code[20]; var SecondWhseReceiptLineNo: Code[20]; ItemNo: Code[20]; InventoryQty: Decimal; PurchaseQty: Decimal)
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreateFullWarehouseSetup(Location);
        LocationCode := Location.Code;
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationCode, false);

        CreatePutAwayWithPurchaseOrderSetup(
          PurchaseHeader, WarehouseReceiptLine, ItemNo, LocationCode, InventoryQty);
        RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");

        CreateAndReleasePurchaseOrderWithWhseReceipt(
          PurchaseHeader, WarehouseReceiptLine, ItemNo, LocationCode, PurchaseQty);
        FirstWhseReceiptLineNo := WarehouseReceiptLine."No.";

        CreateAndReleasePurchaseOrderWithWhseReceipt(
          PurchaseHeader, WarehouseReceiptLine, ItemNo, LocationCode, PurchaseQty);
        SecondWhseReceiptLineNo := WarehouseReceiptLine."No.";
    end;

    local procedure RunWarehouseGetBinContentReportFromItemJournalLine(ItemNo: Code[20])
    var
        BinContent: Record "Bin Content";
        ItemJournalLine: Record "Item Journal Line";
    begin
        FindBinContent(BinContent, ItemNo);
        ItemJournalLine.Init();
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine."Posting Date" := WorkDate();
        LibraryWarehouse.WhseGetBinContentFromItemJournalLine(BinContent, ItemJournalLine);
    end;

    local procedure RegisterWarehouseActivity(SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityNo(WarehouseActivityLine, SourceNo, ActivityType);
        WarehouseActivityHeader.Get(ActivityType, WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure RegisterWarehouseActivityWithItemNo(ItemNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; LocationCode: Code[10]; SourceNo: Code[20]; ActionType: Enum "Warehouse Action Type")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        FindWhseActivityLine(WarehouseActivityLine, ActivityType, LocationCode, SourceNo, ActionType);
        WarehouseActivityHeader.Get(ActivityType, WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure RegisterWarehousePutawayWithDifferentUOM(var Quantity: Decimal): Code[20]
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemUnitOfMeasure2: Record "Item Unit of Measure";
        ItemUnitOfMeasure3: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Create Item with multiple Item Unit Of Measure, create and release Purchase Order.
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateMultipleItemUnitOfMeasureSetup(Item, ItemUnitOfMeasure, ItemUnitOfMeasure2, ItemUnitOfMeasure3);

        // Create and Post Whse Receipt. Register Put-away.
        CreatePutAwayWithPurchaseOrderSetup(
          PurchaseHeader, WarehouseReceiptLine, Item."No.", LocationWhite.Code, Quantity);
        RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");

        exit(Item."No.");
    end;

    local procedure SelectWhseShipmentHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; WarehouseShipmentLine: Record "Warehouse Shipment Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    begin
        FindWhseShipmentNo(WarehouseShipmentLine, SourceDocument, SourceNo);
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
    end;

    local procedure SelectWarehouseRequest(var WarehouseRequest: Record "Warehouse Request"; SourceNo: Code[20]; SourceDocument: Enum "Warehouse Request Source Document"; SourceType: Option; LocationCode: Code[10])
    begin
        WarehouseRequest.SetRange("Source No.", SourceNo);
        WarehouseRequest.SetRange("Source Document", SourceDocument);
        WarehouseRequest.SetRange("Source Type", SourceType);
        WarehouseRequest.SetRange("Location Code", LocationCode);
        WarehouseRequest.FindFirst();
    end;

    local procedure SelectWarehouseRequestAndCreateInvPutAwayPick(var WarehouseRequest: Record "Warehouse Request"; DocumentNo: Code[20]; SourceDocument: Enum "Warehouse Request Source Document"; SourceType: Option; LocationCode: Code[10]; PutAway: Boolean)
    begin
        SelectWarehouseRequest(WarehouseRequest, DocumentNo, SourceDocument, SourceType, LocationCode);
        if PutAway then
            LibraryWarehouse.CreateInvtPutAwayPick(WarehouseRequest, true, false, false)
        else
            LibraryWarehouse.CreateInvtPutAwayPick(WarehouseRequest, false, true, false);
    end;

    local procedure UpdateQtyToReceiveOnWhseReceipt(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceNo: Code[20]; QtyToReceive: Decimal)
    begin
        FindWarehouseReceiptNo(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", SourceNo);
        WarehouseReceiptLine.Validate("Qty. to Receive", QtyToReceive);
        WarehouseReceiptLine.Modify(true);
    end;

    local procedure UpdatePurchasingCodeOnSalesLine(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        Purchasing: Record Purchasing;
    begin
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Special Order", true);
        Purchasing.Modify(true);
        FindSalesLine(SalesLine, SalesHeader."Document Type"::Order, SalesHeader."No.");
        SalesLine.Validate("Purchasing Code", Purchasing.Code);
        SalesLine.Modify(true);
    end;

    local procedure UpdateRequisitionLine(var RequisitionLine: Record "Requisition Line"; VendorNo: Code[20]; No: Code[20])
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", No);
        RequisitionLine.FindFirst();
        RequisitionLine.Validate("Vendor No.", VendorNo);
        RequisitionLine.Modify(true);
    end;

    local procedure UpdateBinWithWarehouseClassCode(var Bin: Record Bin; WarehouseClassCode: Code[10])
    begin
        Bin.Validate("Warehouse Class Code", WarehouseClassCode);
        Bin.Modify(true);
    end;

    local procedure UpdateBinOnWarehouseReceiptLine(ItemNo: Code[20]; BinCode: Code[20])
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WarehouseReceiptLine.SetRange("Item No.", ItemNo);
        WarehouseReceiptLine.FindFirst();
        WarehouseReceiptLine.Validate("Bin Code", BinCode);
        WarehouseReceiptLine.Modify(true);
    end;

    local procedure UpdateBinOnWarehouseShipmentLine(ItemNo: Code[20]; BinCode: Code[20])
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("Item No.", ItemNo);
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentLine.Validate("Bin Code", BinCode);
        WarehouseShipmentLine.Modify(true);
    end;

    local procedure UpdateExpirationDateOnReservationEntry(LocationCode: Code[10]; ItemNo: Code[20])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Location Code", LocationCode);
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.FindSet();
        repeat
            ReservationEntry.Validate("Expiration Date", WorkDate());
            ReservationEntry.Modify(true);
        until ReservationEntry.Next() = 0;
    end;

    local procedure UpdateInventoryAndAssignTrackingInWhseItemJournal(Location: Record Location; Item: Record Item; Quantity: Decimal)
    begin
        WarehouseItemJournalSetup(Location.Code);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Location.Code, '',
          Location."Cross-Dock Bin Code",
          WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
        // Assign Serial No and Lot No through page handler.
        WarehouseJournalLine.OpenItemTrackingLines();
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Location.Code, true);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        AssignNoSeriesForItemJournalBatch(ItemJournalBatch, LibraryUtility.GetGlobalNoSeriesCode());
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        UpdateExpirationDateOnReservationEntry(Location.Code, Item."No.");
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        AssignNoSeriesForItemJournalBatch(ItemJournalBatch, '');
    end;

    local procedure UpdateInventoryWithWhseItemJournal(Location: Record Location; Item: Record Item; Quantity: Decimal)
    begin
        WarehouseItemJournalSetup(Location.Code);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Location.Code, '',
          Location."Cross-Dock Bin Code",
          WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Location.Code, true);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        AssignNoSeriesForItemJournalBatch(ItemJournalBatch, LibraryUtility.GetGlobalNoSeriesCode());
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure UpdateQuantityToHandleOnWhseActivityLines(var WarehouseActivityLine: Record "Warehouse Activity Line"; QtyToHandle: Decimal)
    begin
        repeat
            WarehouseActivityLine.Validate("Qty. to Handle", QtyToHandle);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure UpdateItemInventory(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal; Tracking: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
        if Tracking then
            ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure UpdateTrackingOnWhseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ActivityType: Enum "Warehouse Activity Type"; LocationCode: Code[10]; SourceNo: Code[20])
    begin
        FindWhseActivityLine(WarehouseActivityLine, ActivityType, LocationCode, SourceNo, WarehouseActivityLine."Action Type"::Take);
        repeat
            WarehouseActivityLine.Validate("Lot No.", Format(TrackingQuantity));
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure UpdateLocation(LocationCode: Code[10]; CrossDockBinCode: Code[20]; AdjustmentBinCode: Code[20]; DirectedPutawayAndPick: Boolean; UseCrossDocking: Boolean)
    var
        Location: Record Location;
    begin
        Location.Get(LocationCode);
        Location.Validate("Directed Put-away and Pick", DirectedPutawayAndPick);
        Location.Validate("Use Cross-Docking", UseCrossDocking);
        Location.Validate("Cross-Dock Bin Code", CrossDockBinCode);
        Location.Validate("Adjustment Bin Code", AdjustmentBinCode);
        Location.Modify(true);
    end;

    local procedure UpdateBinsOnLocation(var Location: Record Location; ReceiptBinCode: Code[20]; ShipmentBinCode: Code[20])
    begin
        Location.Validate("Receipt Bin Code", ReceiptBinCode);
        Location.Validate("Shipment Bin Code", ShipmentBinCode);
        Location.Modify(true);
    end;

    local procedure UpdateBinOnActivityLine(WarehouseActivityLine: Record "Warehouse Activity Line"; BinCode: Code[20])
    begin
        repeat
            WarehouseActivityLine.Validate("Bin Code", BinCode);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure UpdateQuantityOnSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Quantity: Decimal)
    begin
        LibrarySales.ReopenSalesDocument(SalesHeader);
        SalesLine.Validate(Quantity, Quantity);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure UpdateExpirationDate(LocationCode: Code[10]; ItemNo: Code[20]; ItemNo2: Code[20])
    begin
        UpdateExpirationDateOnReservationEntry(LocationCode, ItemNo);
        UpdateExpirationDateOnReservationEntry(LocationCode, ItemNo2);
    end;

    local procedure UpdateBinAndZoneOnWhseWorksheetLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; LocationCode: Code[10])
    begin
        WhseWorksheetLine.SetRange("Location Code", LocationCode);
        WhseWorksheetLine.FindFirst();
        WhseWorksheetLine.Validate("To Zone Code", WhseWorksheetLine."From Zone Code");
        WhseWorksheetLine.Validate("To Bin Code", WhseWorksheetLine."From Bin Code");
        WhseWorksheetLine.Modify(true);
    end;

    local procedure UpdatePlaceBinCodeInMovement(var WarehouseActivityLine: Record "Warehouse Activity Line"; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20])
    begin
        UpdatePlaceBinCode(WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Movement, ItemNo, LocationCode, BinCode, '');
    end;

    local procedure UpdatePlaceBinCode(var WarehouseActivityLine: Record "Warehouse Activity Line"; ActivityType: Enum "Warehouse Activity Type"; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; SourceNo: Code[20])
    begin
        FindWhseMovementLine(WarehouseActivityLine, ItemNo, ActivityType, LocationCode, SourceNo);
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.Validate("Bin Code", BinCode);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure PrepareInvtPutAway(SourceDocument: Enum "Warehouse Activity Source Document"; DocumentNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        LibraryWarehouse.CreateInvtPutPickMovement(SourceDocument, DocumentNo, true, false, false);
        UpdatePlaceBinCode(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Invt. Put-away", ItemNo,
          LocationCode, BinCode, DocumentNo);
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
    end;

    local procedure UpdateTrackingOnWhseReceiptLines(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceNo: Code[20])
    begin
        FindWarehouseReceiptNo(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", SourceNo);
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        AssignTrackingToMultipleWhseReceiptLines(SourceNo, WarehouseReceiptLine."Source Document"::"Purchase Order");  // Assign Tracking on Page Handler LotItemTrackingPageHandler.
    end;

    local procedure UpdateInvtAndCreateWhseInternalPutAwayByGetBinContent(var Item: Record Item; WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header"; Quantity: Decimal; GetBinContent: Integer; Release: Boolean)
    var
        Bin: Record Bin;
        WhseIntPutAwayRelease: Codeunit "Whse. Int. Put-away Release";
    begin
        LibraryInventory.CreateItem(Item);
        UpdateInventoryWithWhseItemJournal(LocationWhite, Item, Quantity);
        Bin.Get(LocationWhite.Code, LocationWhite."Cross-Dock Bin Code");
        CreateWhseInternalPutAway(WhseInternalPutAwayHeader, LocationWhite.Code, Bin."Zone Code", Bin.Code, Item."No.", GetBinContent);
        if Release then
            WhseIntPutAwayRelease.Release(WhseInternalPutAwayHeader);
    end;

    local procedure UpdateBinWithDedicated(var Bin: Record Bin; Location: Record Location)
    begin
        Bin.Get(Location.Code, Location."To-Production Bin Code");
        Bin.Validate(Dedicated, true);
        Bin.Modify(true);
    end;

    local procedure UpdateUOMOnSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; UOMCode: Code[10])
    begin
        LibrarySales.ReopenSalesDocument(SalesHeader);
        SalesLine.Validate("Unit of Measure Code", UOMCode);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure UpdateAndRegisterPutAway(ItemNo: Code[20]; LocationCode: Code[10]; ZoneCode: Code[10]; BinCode: Code[20]; QtyToHandle: Decimal)
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWhseActivityLineByItem(WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Put-away", LocationCode, ItemNo, WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.Validate("Qty. to Handle", QtyToHandle);
        WarehouseActivityLine.Modify(true);

        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.Validate("Qty. to Handle", QtyToHandle);
        WarehouseActivityLine.Validate("Zone Code", ZoneCode);
        WarehouseActivityLine.Validate("Bin Code", BinCode);
        WarehouseActivityLine.Modify(true);

        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure SetPreventNegInventory(PreventNegInventory: Boolean) PrevPreventNegInventory: Boolean
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        PrevPreventNegInventory := InventorySetup."Prevent Negative Inventory";
        InventorySetup."Prevent Negative Inventory" := PreventNegInventory;
        InventorySetup.Modify();
    end;

    local procedure WarehousePickChangeExpirationDateSetup(var Item: Record Item; var SalesHeader: Record "Sales Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        SalesLine: Record "Sales Line";
    begin
        CreateLotTrackedItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLinesAndReleaseDocument(
          PurchaseHeader, Item."No.", LocationWhite.Code, TrackingQuantity, LibraryRandom.RandIntInRange(2, 5), true);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWarehouseReceiptNo(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        AssignTrackingToMultipleWhseReceiptLines(PurchaseHeader."No.", WarehouseReceiptLine."Source Document"::"Purchase Order");  // Assign Tracking on Page Handler LotItemTrackingPageHandler.
        UpdateExpirationDateOnReservationEntry(LocationWhite.Code, Item."No.");
        PostWhseReceiptAndRegisterWhseActivity(PurchaseHeader."No.");
        CreateAndReleaseSalesOrderWithVariant(SalesHeader, SalesLine, Item."No.", TrackingQuantity, LocationWhite.Code, '');
        SalesLine.OpenItemTrackingLines();
        CreateAndReleaseWhseShipment(SalesHeader, WarehouseShipmentHeader);
        UpdateExpirationDateOnReservationEntry(LocationWhite.Code, Item."No.");
    end;

    local procedure VerifyBinContentForQuantity(ItemNo: Code[20]; QuantityBase: Decimal)
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.FindFirst();
        BinContent.CalcFields("Quantity (Base)");
        Assert.AreEqual(QuantityBase, BinContent."Quantity (Base)", StrSubstNo(QuantityBaseErr, QuantityBase, ItemNo, BinContent.TableCaption));
    end;

    local procedure VerifyWhseReceiptLine(WarehouseReceiptLine: Record "Warehouse Receipt Line"; CrossDockZoneCode: Code[10]; CrossDockBinCode: Code[20]; VariantCode: Code[20])
    begin
        WarehouseReceiptLine.TestField("Cross-Dock Zone Code", CrossDockZoneCode);
        WarehouseReceiptLine.TestField("Cross-Dock Bin Code", CrossDockBinCode);
        WarehouseReceiptLine.TestField("Variant Code", VariantCode);
    end;

    local procedure VerifyCrossDockEntriesOnWarehouseActivityLine(WarehouseActivityLine: Record "Warehouse Activity Line"; LocationCode: Code[10]; ZoneCode: Code[20]; ActivityType: Enum "Warehouse Activity Type"; SourceNo: Code[20]; ActionType: Enum "Warehouse Action Type"; Quantity: Decimal)
    begin
        FindWhseActivityLine(WarehouseActivityLine, ActivityType, LocationCode, SourceNo, ActionType);
        WarehouseActivityLine.TestField("Zone Code", ZoneCode);
        WarehouseActivityLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPostedWhseShipmentLine(SourceNo: Code[20]; ZoneCode: Code[10]; Quantity: Decimal; UnitOfMeasureCode: Code[20]; QtyPerUnitOfMeasure: Integer; LocationCode: Code[10])
    var
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
    begin
        PostedWhseShipmentLine.SetRange("Source No.", SourceNo);
        PostedWhseShipmentLine.FindFirst();
        PostedWhseShipmentLine.TestField("Unit of Measure Code", UnitOfMeasureCode);
        PostedWhseShipmentLine.TestField(Quantity, Quantity);
        PostedWhseShipmentLine.TestField("Zone Code", ZoneCode);
        PostedWhseShipmentLine.TestField("Qty. per Unit of Measure", QtyPerUnitOfMeasure);
        PostedWhseShipmentLine.TestField("Location Code", LocationCode);
    end;

    local procedure VerifyRegisteredWhseActivityLine(WarehouseActivityLine: Record "Warehouse Activity Line"; UnitOfMeasureCode: Code[10]; QtyPerUnitOfMeasure: Decimal; ExpectedQuantity: Decimal; VariantCode: Code[10])
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        FindRegisterWarehouseActivityLine(
          RegisteredWhseActivityLine, WarehouseActivityLine."Activity Type", WarehouseActivityLine."Action Type",
          WarehouseActivityLine."Location Code", WarehouseActivityLine."Source No.");
        RegisteredWhseActivityLine.TestField("Unit of Measure Code", UnitOfMeasureCode);
        RegisteredWhseActivityLine.TestField("Qty. per Unit of Measure", QtyPerUnitOfMeasure);
        RegisteredWhseActivityLine.TestField("Variant Code", VariantCode);
        Assert.AreNearlyEqual(
          ExpectedQuantity, RegisteredWhseActivityLine.Quantity, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(QuantityError, ExpectedQuantity, WarehouseActivityLine.TableCaption()));
    end;

    local procedure VerifyPostedWhseReceiptLine(WhseReceiptNo: Code[20]; BinCode: Code[20]; QtyCrossDocked: Decimal)
    var
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
    begin
        PostedWhseReceiptLine.SetRange("Whse. Receipt No.", WhseReceiptNo);
        PostedWhseReceiptLine.FindFirst();
        PostedWhseReceiptLine.TestField("Bin Code", BinCode);
        PostedWhseReceiptLine.TestField("Qty. Cross-Docked", QtyCrossDocked);
    end;

    local procedure VerifyWarehouseShipmentLine(No: Code[20]; Quantity: Decimal; BinCode: Code[20])
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("No.", No);
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentLine.TestField(Quantity, Quantity);
        WarehouseShipmentLine.TestField("Bin Code", BinCode);
    end;

    local procedure VerifyWhseActivityLine(WarehouseActivityLine: Record "Warehouse Activity Line"; ActivityType: Enum "Warehouse Activity Type"; LocationCode: Code[10]; SourceNo: Code[20]; ActionType: Enum "Warehouse Action Type"; ExpectedQuantity: Decimal; UnitOfMeasureCode: Code[10]; QtyPerUnitOfMeasure: Integer)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        FindWhseActivityLine(WarehouseActivityLine, ActivityType, LocationCode, SourceNo, ActionType);
        WarehouseActivityLine.TestField("Unit of Measure Code", UnitOfMeasureCode);
        WarehouseActivityLine.TestField("Qty. per Unit of Measure", QtyPerUnitOfMeasure);
        Assert.AreNearlyEqual(
          ExpectedQuantity, WarehouseActivityLine.Quantity, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(QuantityError, ExpectedQuantity, WarehouseActivityLine.TableCaption()));
        Assert.AreNearlyEqual(
          ExpectedQuantity, WarehouseActivityLine."Qty. Outstanding", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(QuantityError, ExpectedQuantity, WarehouseActivityLine.TableCaption()));
    end;

    local procedure VerifyMultipleWhseActivityLines(var WarehouseActivityLine: Record "Warehouse Activity Line"; ExpectedQuantity: Decimal; ActivityType: Enum "Warehouse Activity Type"; SourceNo: Code[20]; LocationCode: Code[10]; UnitOfMeasureCode: Code[10]; QtyPerUnitOfMeasure: Integer)
    begin
        repeat
            VerifyWhseActivityLine(
              WarehouseActivityLine, ActivityType, LocationCode, SourceNo, WarehouseActivityLine."Action Type"::Place, ExpectedQuantity,
              UnitOfMeasureCode, QtyPerUnitOfMeasure);
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure VerifyPurchaseReceiptLine(No: Code[20]; OrderNo: Code[20]; Quantity: Decimal; LocationCode: Code[20])
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptHeader.Get(No);
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        PurchRcptLine.FindFirst();
        PurchRcptLine.TestField("Order No.", OrderNo);
        PurchRcptLine.TestField(Quantity, Quantity);
        PurchRcptLine.TestField("Location Code", LocationCode);
    end;

    local procedure VerifyTrackingOnItemLedgerEntry(ItemNo: Code[20]; Quantity: Integer)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        LineCount: Integer;
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindSet();
        repeat
            if LotSpecific then
                ItemLedgerEntry.TestField("Lot No.")
            else
                ItemLedgerEntry.TestField("Serial No.");
            LineCount += 1;
        until ItemLedgerEntry.Next() = 0;
        Assert.AreEqual(Quantity, LineCount, NumberOfLineError);  // Verify Number of Item Ledger Entry line.
    end;

    local procedure VerifyPostedInventoryPickLine(SourceNo: Code[20]; LocationCode: Code[10]; ItemNo: Code[20]; ExpirationDate: Date; BinCode: Code[20])
    var
        PostedInvtPickLine: Record "Posted Invt. Pick Line";
    begin
        PostedInvtPickLine.SetRange("Source No.", SourceNo);
        PostedInvtPickLine.SetRange("Location Code", LocationCode);
        PostedInvtPickLine.FindFirst();
        PostedInvtPickLine.TestField("Item No.", ItemNo);
        PostedInvtPickLine.TestField("Expiration Date", ExpirationDate);
        PostedInvtPickLine.TestField("Bin Code", BinCode);
    end;

    local procedure VerifyPostedInventoryPutLine(SourceNo: Code[20]; LocationCode: Code[10]; ItemNo: Code[20]; ExpirationDate: Date; BinCode: Code[20])
    var
        PostedInvtPutAwayLine: Record "Posted Invt. Put-away Line";
    begin
        PostedInvtPutAwayLine.SetRange("Source No.", SourceNo);
        PostedInvtPutAwayLine.FindFirst();
        PostedInvtPutAwayLine.TestField("Location Code", LocationCode);
        PostedInvtPutAwayLine.TestField("Item No.", ItemNo);
        PostedInvtPutAwayLine.TestField("Expiration Date", ExpirationDate);
        PostedInvtPutAwayLine.TestField("Bin Code", BinCode);
    end;

    local procedure VerifyWhseActivityLineForMovement(ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Integer)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField("Location Code", LocationCode);
        WarehouseActivityLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyWhseWorksheetLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; LocationCode: Code[10]; ItemNo: Code[20]; UnitofMeasureCode: Code[10]; Quantity: Integer)
    begin
        WhseWorksheetLine.SetRange("Location Code", LocationCode);
        WhseWorksheetLine.FindFirst();
        WhseWorksheetLine.TestField("Item No.", ItemNo);
        WhseWorksheetLine.TestField("Unit of Measure Code", UnitofMeasureCode);
        WhseWorksheetLine.TestField(Quantity, Quantity);
        WhseWorksheetLine.TestField("Qty. to Handle", Quantity);
    end;

    local procedure VerifyBinContent(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20])
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.FindFirst();
        BinContent.TestField("Bin Code", BinCode);
        BinContent.TestField("Location Code", LocationCode);
    end;

    local procedure VerifyItemJournalLine(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.FindFirst();
        ItemJournalLine.TestField("Location Code", LocationCode);
        ItemJournalLine.TestField("Bin Code", BinCode);
        ItemJournalLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyReservationEntry(ItemNo: Code[20]; Status: Enum "Reservation Status"; QtyToHandleBase: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Reservation Status", Status);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Qty. to Handle (Base)", QtyToHandleBase);
    end;

    local procedure VerifyLotQuantitiesOnWhseActivityLines(ItemNo: Code[20]; LotNo1: Code[10]; Quantity1: Decimal; LotNo2: Code[10]; Quantity2: Decimal; Lot: Boolean)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.Find('-');
        VerifyWhseActivityLineWithSeriesOrLot(WarehouseActivityLine, LotNo1, Quantity1, Lot);
        WarehouseActivityLine.Next();
        VerifyWhseActivityLineWithSeriesOrLot(WarehouseActivityLine, LotNo2, Quantity2, Lot);
    end;

    local procedure VerifyWhseActivityLineWithSeriesOrLot(var WarehouseActivityLine: Record "Warehouse Activity Line"; TrackingNo: Code[10]; Quantity: Decimal; Lot: Boolean)
    begin
        if Lot then
            WarehouseActivityLine.TestField("Lot No.", TrackingNo)
        else
            WarehouseActivityLine.TestField("Serial No.", TrackingNo);
        WarehouseActivityLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyWhseItemTrackingLines(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; ItemNo: Code[20]; "Count": Integer; QuantityBase: Decimal)
    begin
        WhseItemTrackingLine.SetRange("Item No.", ItemNo);
        Assert.AreEqual(Count, WhseItemTrackingLine.Count, ItemTrackingLineErr);
        WhseItemTrackingLine.FindFirst();
        WhseItemTrackingLine.TestField("Quantity (Base)", QuantityBase);
    end;

    local procedure VerifyBinCodeInWhseActivityLine(ItemNo: Code[20]; ActionType: Enum "Warehouse Action Type"; BinCode: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField("Bin Code", BinCode);
    end;

    local procedure VerifyCrossDockBinCodeForWhseActivityLine(ActivityType: Enum "Warehouse Activity Type"; LocationCode: Code[10]; SourceNo: Code[20]; ActionType: Enum "Warehouse Action Type"; Qty: Decimal; BinCode: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWhseActivityLine(WarehouseActivityLine, ActivityType, LocationCode, SourceNo, ActionType);
        WarehouseActivityLine.SetRange(Quantity, Qty);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField("Bin Code", BinCode);
    end;

    local procedure VerifyBinCodeForWarehouseEntry(ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal; BinCode: Code[20])
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetRange("Item No.", ItemNo);
        WarehouseEntry.SetRange("Location Code", LocationCode);
        WarehouseEntry.SetRange(Quantity, Qty);
        WarehouseEntry.FindFirst();
        WarehouseEntry.TestField("Bin Code", BinCode);
    end;

    local procedure VerifyCountOfWarehouseEntry(WhseDocumentNo: Code[20])
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetRange("Whse. Document Type", WarehouseEntry."Whse. Document Type"::"Whse. Journal");
        WarehouseEntry.SetRange("Whse. Document No.", WhseDocumentNo);
        Assert.RecordCount(WarehouseEntry, 1);
    end;

    local procedure MultipleLotNoWhseItemTrackingPageHandlerBody(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    var
        TrackingQuantity1: Variant;
        TrackingQuantity2: Variant;
    begin
        LibraryVariableStorage.Dequeue(TrackingQuantity1);
        LibraryVariableStorage.Dequeue(TrackingQuantity2);
        WhseItemTrackingLines.First();
        WhseItemTrackingLines."Lot No.".SetValue(Format(TrackingQuantity1));
        WhseItemTrackingLines.Quantity.SetValue(Format(TrackingQuantity1));
        WhseItemTrackingLines.Next();
        WhseItemTrackingLines."Lot No.".SetValue(Format(TrackingQuantity2));
        WhseItemTrackingLines.Quantity.SetValue(Format(TrackingQuantity2));
        WhseItemTrackingLines.OK().Invoke();
    end;

    local procedure LotSerialNoWhseItemTrackingPageHandlerBody(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    var
        LotNoVar: Variant;
        SerialNoVar: Variant;
        QuantityVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(LotNoVar);
        LibraryVariableStorage.Dequeue(SerialNoVar);
        LibraryVariableStorage.Dequeue(QuantityVar);
        WhseItemTrackingLines.First();
        WhseItemTrackingLines."Lot No.".SetValue(LotNoVar);
        WhseItemTrackingLines."Serial No.".SetValue(SerialNoVar);
        WhseItemTrackingLines.Quantity.SetValue(QuantityVar);
        WhseItemTrackingLines.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MovementCreatedMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, MovementCreated) > 0, Message);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ChangeUOMRequestPageHandler(var WhseChangeUnitOfMeasure: TestRequestPage "Whse. Change Unit of Measure")
    begin
        case UnitOfMeasureType of
            UnitOfMeasureType::Default:
                WhseChangeUnitOfMeasure.UnitOfMeasureCode.SetValue(NewUnitOfMeasure);
            UnitOfMeasureType::PutAway:
                WhseChangeUnitOfMeasure.UnitOfMeasureCode.SetValue(NewUnitOfMeasure2);
            UnitOfMeasureType::Sales:
                WhseChangeUnitOfMeasure.UnitOfMeasureCode.SetValue(NewUnitOfMeasure3);
        end;
        WhseChangeUnitOfMeasure.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationHandler(var Reservation: TestPage Reservation)
    begin
        Reservation.AvailableToReserve.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesPageHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    begin
        WhseItemTrackingLines.First();
        repeat
            TrackingQuantity -= 1;
            WhseItemTrackingLines."Serial No.".SetValue(Format(TrackingQuantity));
            if LotSpecific then
                WhseItemTrackingLines."Lot No.".SetValue(Format(TrackingQuantity));
            WhseItemTrackingLines.Quantity.SetValue(1);
            WhseItemTrackingLines.Next();
        until TrackingQuantity = 0;

        if VerifyTracking then
            WhseItemTrackingLines.Quantity.AssertEquals(1);
        WhseItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines.First();
        ItemTrackingLines."Lot No.".SetValue(TrackingQuantity);
        ItemTrackingLines."Quantity (Base)".SetValue(TrackingQuantity);

        if VerifyTracking then
            ItemTrackingLines."Quantity (Base)".AssertEquals(TrackingQuantity);
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure LotNoWhseItemTrackingPageHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    begin
        WhseItemTrackingLines.First();
        WhseItemTrackingLines."Lot No.".SetValue(Format(TrackingQuantity));
        WhseItemTrackingLines.Quantity.SetValue(Format(TrackingQuantity));
        WhseItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandlerSerialAndLot(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        if not SelectEntries then
            if Serial then
                ItemTrackingLines."Assign Serial No.".Invoke()
            else
                ItemTrackingLines."Assign Lot No.".Invoke();

        if SelectEntries then
            ItemTrackingLines."Select Entries".Invoke();
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    begin
        WhseItemTrackingLines."Lot No.".AssistEdit();
        WhseItemTrackingLines."New Expiration Date".SetValue(CalcDate('<' + '+' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));
        WhseItemTrackingLines.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhseSourceCreateDocumentHandler(var WhseSourceCreateDocument: TestRequestPage "Whse.-Source - Create Document")
    begin
        WhseSourceCreateDocument.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CrossDockOpportunitiesModalPageHandler(var CrossDockOpportunities: TestPage "Cross-Dock Opportunities")
    begin
        CrossDockOpportunities."Qty. to Cross-Dock".SetValue(LibraryVariableStorage.DequeueDecimal());
        CrossDockOpportunities.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(ConfirmMessage, PostJournalLines) > 0, ConfirmMessage);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandlerSerialNo(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines.First();
        repeat
            TrackingQuantity -= 1;
            ItemTrackingLines."Serial No.".SetValue(Format(TrackingQuantity));
            ItemTrackingLines."Quantity (Base)".SetValue(1);
            ItemTrackingLines.Next();
        until TrackingQuantity = 0;

        if VerifyTracking then
            ItemTrackingLines."Quantity (Base)".AssertEquals(1);
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
    procedure MultipleLotNoWhseItemTrackingPageHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    var
        HandlerBodyVar: Variant;
        HandlerBody: Option;
    begin
        LibraryVariableStorage.Dequeue(HandlerBodyVar);
        HandlerBody := HandlerBodyVar;
        if HandlerBody = WhseItemTrackingPageHandlerBody::MultipleLotNo then
            MultipleLotNoWhseItemTrackingPageHandlerBody(WhseItemTrackingLines)
        else
            LotSerialNoWhseItemTrackingPageHandlerBody(WhseItemTrackingLines);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseDocumentLinePageHandler(var PostedPurchaseDocumentLines: TestPage "Posted Purchase Document Lines")
    var
        DocumentType: Option "Posted Receipts","Posted Invoices","Posted Return Shipments","Posted Cr. Memos";
    begin
        PostedPurchaseDocumentLines.PostedReceiptsBtn.SetValue(Format(DocumentType::"Posted Receipts"));
        PostedPurchaseDocumentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseDocumentLinePageHandler2(var PostedPurchaseDocumentLines: TestPage "Posted Purchase Document Lines")
    var
        DocumentType: Option "Posted Receipts","Posted Invoices","Posted Return Shipments","Posted Cr. Memos";
    begin
        PostedPurchaseDocumentLines.PostedReceiptsBtn.SetValue(Format(DocumentType::"Posted Receipts"));
        PostedPurchaseDocumentLines.OriginalQuantity.SetValue(true);
        PostedPurchaseDocumentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseDocumentLineHandler(var PostedPurchaseDocumentLines: TestPage "Posted Purchase Document Lines")
    var
        DocumentType: Option "Posted Receipts","Posted Invoices","Posted Return Shipments","Posted Cr. Memos";
    begin
        PostedPurchaseDocumentLines.PostedReceiptsBtn.SetValue(Format(DocumentType::"Posted Invoices"));
        PostedPurchaseDocumentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        DequeueVariable: Variant;
        Qty: Variant;
        ActionType: Option;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        ActionType := DequeueVariable;
        ItemTrackingLines.First();
        case ActionType of
            ItemTrackingLineActionType::Verify:
                begin
                    LibraryVariableStorage.Dequeue(Qty);
                    ItemTrackingLines."Qty. to Handle (Base)".AssertEquals(Qty);
                end;
            ItemTrackingLineActionType::Tracking:
                begin
                    ItemTrackingLines."Lot No.".SetValue(TrackingQuantity);
                    ItemTrackingLines."Quantity (Base)".SetValue(TrackingQuantity);
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    local procedure SetupAdjustmentBin(LocationCode: Code[10]; NewValue: Code[20]) PrevValue: Code[20]
    var
        Location: Record Location;
    begin
        Location.Get(LocationCode);
        PrevValue := Location."Adjustment Bin Code";
        Location.Validate("Adjustment Bin Code", NewValue);
        Location.Modify();
    end;

    local procedure MockInventory(LocationCode: Code[10]; ZoneCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; UOMCode: Code[10]; QtyPerUOM: Decimal; QtyToSet: Decimal)
    var
        WarehouseEntry: Record "Warehouse Entry";
        EntryNo: Integer;
    begin
        WarehouseEntry.FindLast();
        EntryNo := WarehouseEntry."Entry No." + 1;
        WarehouseEntry.Init();
        WarehouseEntry."Entry No." := EntryNo;
        WarehouseEntry."Location Code" := LocationCode;
        WarehouseEntry."Zone Code" := ZoneCode;
        WarehouseEntry."Bin Code" := BinCode;
        WarehouseEntry."Item No." := ItemNo;
        WarehouseEntry."Unit of Measure Code" := UOMCode;
        WarehouseEntry.Quantity := QtyToSet;
        WarehouseEntry."Qty. (Base)" := QtyToSet * QtyPerUOM;
        WarehouseEntry.Insert();
    end;

    local procedure SetupWhseJournalLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; LocationCode: Code[10]; ItemNo: Code[20])
    begin
        WarehouseJournalLine.Init();
        WarehouseJournalLine."Journal Template Name" := WarehouseJournalTemplate.Name;
        WarehouseJournalLine."Journal Batch Name" := WarehouseJournalBatch.Name;
        WarehouseJournalLine."Location Code" := LocationCode;
        Commit();
        WarehouseJournalLine.SetUpNewLine(WarehouseJournalLine);
        WarehouseJournalLine.Validate("Item No.", ItemNo);
    end;

    local procedure CreateWhseItemJournalLine(WhseJournalTemplateName: Code[10]; WhseJournalBatchName: Code[10]; LocationCode: Code[10]; ZoneCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; ItemQty: Decimal; AdjBinToRestore: Code[20])
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WhseItemJournal: TestPage "Whse. Item Journal";
    begin
        WarehouseJournalLine."Location Code" := LocationCode;
        WarehouseJournalLine."Journal Batch Name" := WhseJournalBatchName;
        WarehouseJournalLine.SetRange("Journal Template Name", WhseJournalTemplateName);

        Commit();
        WhseItemJournal.Trap();
        PAGE.Run(PAGE::"Whse. Item Journal", WarehouseJournalLine);

        asserterror WhseItemJournal."Item No.".SetValue(ItemNo);

        SetupAdjustmentBin(LocationCode, AdjBinToRestore);
        Commit();

        WhseItemJournal."Item No.".SetValue(ItemNo);
        WhseItemJournal.Quantity.SetValue(ItemQty);
        WhseItemJournal."Zone Code".SetValue(ZoneCode);
        WhseItemJournal."Bin Code".SetValue(BinCode);
        WhseItemJournal.OK().Invoke();
    end;

    local procedure CreateWhseItemJournalLineWithWrongAdjBin(WhseJournalTemplateName: Code[10]; WhseJournalBatchName: Code[10]; LocationCode: Code[10]; ZoneCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; ItemQty: Decimal; var AdjustmentBinCode: Code[20])
    var
        Zone: Record Zone;
        NewAdjustmentBin: Record Bin;
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WhseItemJournal: TestPage "Whse. Item Journal";
    begin
        LibraryWarehouse.CreateZone(
          Zone, LibraryUtility.GenerateGUID(), LocationWhite.Code,
          LibraryWarehouse.SelectBinType(false, false, false, false), '', '', 0, false);
        LibraryWarehouse.CreateBin(
          NewAdjustmentBin, LocationWhite.Code, LibraryUtility.GenerateGUID(), Zone.Code, Zone."Bin Type Code");
        WarehouseJournalLine."Location Code" := LocationCode;
        WarehouseJournalLine."Journal Batch Name" := WhseJournalBatchName;
        WarehouseJournalLine.SetRange("Journal Template Name", WhseJournalTemplateName);

        Commit();
        WhseItemJournal.Trap();
        PAGE.Run(PAGE::"Whse. Item Journal", WarehouseJournalLine);

        WhseItemJournal."Item No.".SetValue(ItemNo);
        WhseItemJournal.Quantity.SetValue(ItemQty);
        WhseItemJournal."Zone Code".SetValue(ZoneCode);
        WhseItemJournal."Bin Code".SetValue(BinCode);

        AdjustmentBinCode := SetupAdjustmentBin(LocationWhite.Code, NewAdjustmentBin.Code);
        WhseItemJournal.OK().Invoke();
    end;

    local procedure SetupWhseItemJnlLineWrongBinCode(var Zone: Record Zone; var Bin: Record Bin)
    begin
        Initialize();
        WarehouseItemJournalSetup(LocationWhite.Code);
        FindZone(Zone, LocationWhite.Code, LibraryWarehouse.SelectBinType(false, false, true, true));
        FindBinWithZone(Bin, LocationWhite.Code, Zone.Code);
    end;

    local procedure ClearWhiteLocationAdjBin()
    begin
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        CalculateWhseAdjustment(ItemJournalBatch, LibraryUtility.GenerateGUID());
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CalculateWhseAdjustment(ItemJournalBatch: Record "Item Journal Batch"; DocNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
        CalculateWhseAdjustment: Report "Calculate Whse. Adjustment";
    begin
        ItemJournalLine."Journal Template Name" := ItemJournalBatch."Journal Template Name";
        ItemJournalLine."Journal Batch Name" := ItemJournalBatch.Name;
        CalculateWhseAdjustment.UseRequestPage(false);
        CalculateWhseAdjustment.SetHideValidationDialog(true);
        CalculateWhseAdjustment.InitializeRequest(WorkDate(), DocNo);
        CalculateWhseAdjustment.SetItemJnlLine(ItemJournalLine);
        CalculateWhseAdjustment.RunModal();
    end;

    local procedure VerifyBinCodeInWhseEntry(ItemNo: Code[20]; BinCode: Code[20])
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetRange("Item No.", ItemNo);
        WarehouseEntry.SetRange("Bin Code", BinCode);
        Assert.IsFalse(WarehouseEntry.IsEmpty, StrSubstNo(BinCodeNotFoundErr, BinCode));
    end;

    local procedure CreateInternalMovement(var InternalMovementHeader: Record "Internal Movement Header"; Location: Record Location; ToBin: Record Bin; Item: Record Item; FromBin: Record Bin; Quantity: Decimal)
    var
        InternalMovementLine: Record "Internal Movement Line";
    begin
        LibraryWarehouse.CreateInternalMovementHeader(InternalMovementHeader, Location.Code, ToBin.Code);
        LibraryWarehouse.CreateInternalMovementLine(
          InternalMovementHeader, InternalMovementLine, Item."No.", FromBin.Code, ToBin.Code, Quantity);
        InternalMovementLine.Validate("From Bin Code", FromBin.Code);
        InternalMovementLine.Validate("To Bin Code", ToBin.Code);
        InternalMovementLine.Modify(true);
    end;

    local procedure EnsureTrackingCodeUsesExpirationDate(ItemTrackingCode: Code[10])
    var
        ItemTrackingCodeRec: Record "Item Tracking Code";
    begin
        ItemTrackingCodeRec.Get(ItemTrackingCode);
        if not ItemTrackingCodeRec."Use Expiration Dates" then begin
            ItemTrackingCodeRec.Validate("Use Expiration Dates", true);
            ItemTrackingCodeRec.Modify();
        end;
    end;

    local procedure SetLinkDocToPostingDate()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Link Doc. Date To Posting Date", true);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure CreateLocationWithBin(var Location: Record Location; var Bin: Record Bin)
    begin
        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, true);
        LibraryWarehouse.CreateBin(Bin, Location.Code, '', '', '');
        Location.Validate("Shipment Bin Code", Bin.Code);
        Location.Modify(true);
    end;

    local procedure CreateSalesOrderWithMultipleLine(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; LocationCode: Code[20]; ItemNo: Code[20])
    var
        SalesLine: array[2] of Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine[1], SalesHeader, SalesLine[1].Type::Item, ItemNo, LibraryRandom.RandDec(100, 2));
        SalesLine[1].Validate("Unit Price", LibraryRandom.RandIntInRange(10000, 20000));
        SalesLine[1].Validate(SalesLine[1]."Shipment Date", WorkDate(CalcDate('<7D>', WorkDate())));
        SalesLine[1].Modify(true);

        LibrarySales.CreateSalesLine(SalesLine[2], SalesHeader, SalesLine[2].Type::Item, ItemNo, LibraryRandom.RandIntInRange(5, 10));
        SalesLine[2].Validate("Unit Price", SalesLine[1]."Unit Price");
        SalesLine[2].Modify(true);
    end;

    local procedure VerifyDocumentDateAndPostingDateSame(SalesOrderNo: Code[20]): Code[20]
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        SalesShipmentHeader.SetRange("Order No.", SalesOrderNo);
        SalesShipmentHeader.FindFirst();
        Assert.AreEqual(SalesShipmentHeader."Posting Date", SalesShipmentHeader."Document Date", 'equal');

        exit(SalesShipmentHeader."No.");
    end;

    local procedure GetSalesShipmentLines(var SalesHeader: Record "Sales Header")
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesGetShpt: Codeunit "Sales-Get Shipment";
    begin
        SalesShipmentHeader.SetRange("Order No.", LibraryVariableStorage.DequeueText());
        SalesShipmentHeader.FindFirst();
        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
        SalesGetShpt.SetSalesHeader(SalesHeader);
        SalesGetShpt.CreateInvLines(SalesShipmentLine);
    end;

    local procedure VerifyCommentLineDescriptionHasOnlyShipmentNo(DocumentNo: Code[20]; ShipmentNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange(Type, SalesLine.Type::" ");
        SalesLine.SetRange("No.", '');
        SalesLine.FindFirst();
        Assert.AreEqual(
            SalesLine.Description, StrSubstNo(ShipmentNoLbl, ShipmentNo),
            StrSubstNo(
                DescriptionContainDateErr, SalesLine.TableCaption(), SalesLine.FieldCaption(Description)));
    end;
}

