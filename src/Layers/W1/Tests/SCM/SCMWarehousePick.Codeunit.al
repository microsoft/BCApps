codeunit 137055 "SCM Warehouse Pick"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [Pick] [SCM]
        isInitialized := false;
    end;

    var
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        LocationWhite: Record Location;
        LocationBlue: Record Location;
        LocationYellow: Record Location;
        LocationOrange: Record Location;
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        GlobalItemNo: Code[20];
        isInitialized: Boolean;
        LocationError: Label 'You cannot delete %1 because there are one or more ledger entries on this location.';
        ValidationError: Label 'Validation error for Field: %1';
        TransferMustBeShippedErr: Label 'Transfer order must be shipped.';
        QtyMismErr: Label 'Quantities mismatched for %1 and %2.', Comment = '%1, %2 - Tables Names.';
        ActionTypeMustNotBeEditableErr: Label '"Action Type" control must not be editable';
        UnitOfMeasureCodeMustNotBeEditableErr: Label '"Unit of Measure Code" control must not be editable';
        NoAllowedLocationsErr: Label 'Internal movement is not possible at any locations where you are a warehouse employee.';
        UnexpectedLocationCodeErr: Label 'Unexpected location code. Actual -  %1, Expected - %2', Comment = '%1 : Actual location code; %2 : expected location code.';
        LocationCodeMustNotOccurErr: Label 'Location code %1 must not occur.  Expected value - %2', Comment = '%1 : occured location code, %2 : expected location code.';
        ReturnQtyMismatchErr: Label 'The value in the %1 field in the %2 does not match.', Comment = '%1 :FieldCaption, %2:Table Caption';
        ReservationAction: Option AutoReserve,GetQuantities;
        PickQuantityErr: Label 'Expected picked quantity %1 %2, but got %3 %2', Comment = '%1, %3 - Quantity; %2 - Unit of Measure Code';
        ShipQtyErr: Label 'Sales line should be fully shipped with no residual quantity';

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure PickFromWarehouseShipmentForAlwaysPickLineTrue()
    var
        Item: Record Item;
        Zone: Record Zone;
        Zone2: Record Zone;
        Bin: Record Bin;
        Bin2: Record Bin;
        SalesHeader: Record "Sales Header";
        Quantity: Decimal;
    begin
        // Setup: Create Item, Create Partial Put Away and create Partial Pick from Warehouse Shipment for Sales Order.
        Initialize();
        UpdateLocationForAlwaysCreatePickLine(LocationWhite, true);  // Make Always  Pick line True is Checked on White Location.
        Quantity := 100 + LibraryRandom.RandDec(100, 2);  // Quantity for large value.
        CreateItemAndUpdateInventoryWithZone(Item, Zone, Bin, Quantity);
        CreateItemAndUpdateInventoryWithZone(Item, Zone2, Bin2, Quantity);

        CreatePutAwayForPurchaseOrder(LocationWhite.Code, Item."No.", Quantity / 4);  // Partial Put Away.
        CreateReleaseAndReserveSalesOrder(SalesHeader, LocationWhite.Code, Item."No.", Quantity / 2, true);  // Reserve -True and Reservation on Page handler.

        // Exercise: Create Pick For Warehouse Shipment From Sales Order.
        CreateWhseShipmentAndPick(SalesHeader);

        // Verify:  Verify Pick has been created.
        VerifyPick(SalesHeader."No.", Item."No.", LocationWhite.Code, Quantity / 2);  // Partial Pick.

        // Teardown: Make Always True Pick line is Unchecked on White Location.
        UpdateLocationForAlwaysCreatePickLine(LocationWhite, false);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure PickForAlwaysPickLineTrueWithNewQtyOnActivityLine()
    var
        Item: Record Item;
        Zone: Record Zone;
        Zone2: Record Zone;
        Bin: Record Bin;
        Bin2: Record Bin;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        Quantity: Decimal;
    begin
        // Setup : Create Item, Create Partial Put Away, Create Partial Pick from Warehouse Shipment for Sales Order and register Pick.
        Initialize();
        UpdateLocationForAlwaysCreatePickLine(LocationWhite, true);  // Make Always True Pick line is Checked on White Location.
        Quantity := 100 + LibraryRandom.RandDec(100, 2);  // Quantity for large value.
        CreateItemAndUpdateInventoryWithZone(Item, Zone, Bin, Quantity);
        CreateItemAndUpdateInventoryWithZone(Item, Zone2, Bin2, Quantity);
        CreatePutAwayForPurchaseOrder(LocationWhite.Code, Item."No.", Quantity / 2);  // Partial Quantity.
        CreateReleaseAndReserveSalesOrder(SalesHeader, LocationWhite.Code, Item."No.", Quantity / 4, true);  // Reserve -True and Reservation on Page handler.
        CreateWhseShipmentAndPick(SalesHeader);
        UpdateBinOnActivityLine(WarehouseActivityLine, SalesHeader."No.", Bin.Code, WarehouseActivityLine."Action Type"::Take);

        UpdateQuantityToHandleOnActivityLine(WarehouseActivityLine, SalesHeader."No.", LocationWhite.Code, Quantity / 4);  // Update Quantity on Activity Line.
        RegisterWarehouseActivity(SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
        CreateSalesOrder(SalesHeader2, LocationWhite.Code, Item."No.", Quantity / 4);  // Partial Quantity.
        CreateSalesLine(SalesHeader2, Item."No.", LocationWhite.Code, Quantity / 2);  // Partial Quantity.
        LibrarySales.ReleaseSalesDocument(SalesHeader2);

        // Exercise: Create Pick From Warehouse Shipment For Sales Order Of two Lines.
        CreateWhseShipmentAndPick(SalesHeader2);

        // Verify: Verify Two Picks Created For two Lines.
        VerifyPick(SalesHeader2."No.", Item."No.", LocationWhite.Code, Quantity / 4);
        VerifyPick(SalesHeader2."No.", Item."No.", LocationWhite.Code, Quantity / 2);

        // Teardown: Make Always True Pick line is Unchecked on white Location.
        UpdateLocationForAlwaysCreatePickLine(LocationWhite, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultiplePicksFromWarehouseShipmentReducedQty()
    var
        Item: Record Item;
        Zone: Record Zone;
        Bin: Record Bin;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityLine2: Record "Warehouse Activity Line";
        SalesHeader3: Record "Sales Header";
        Quantity: Decimal;
        ExpectedQuantity: Decimal;
    begin
        // Setup : Create Item, Create and Release Purchase Order, Create and Post Warehouse Receipt From Purchase order, Register Warehouse receipt,
        // Create multiple Partial Picks from Warehouse Shipment for Sales Order, Register Pick and update Quantity to Handle on Activity Line.
        Initialize();
        LibraryInventory.CreateItem(Item);
        Quantity := 100 + LibraryRandom.RandDec(100, 2);  // Quantity for large value.
        FindZone(Zone, LocationWhite.Code);
        LibraryWarehouse.FindBin(Bin, LocationWhite.Code, Zone.Code, 3);  // Find Bin for Zone for Index 3.
        UpdateInventoryUsingWhseAdjustmentPerZone(Item, LocationWhite.Code, Zone.Code, Bin.Code, Quantity);  // For large Quantity.

        CreateAndReleasePurchaseOrder(PurchaseHeader, LocationWhite.Code, Item."No.", Quantity - 1);  // Partial Put Away.
        CreateAndPostWhseReceiptFromPO(PurchaseHeader);
        RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");

        CreateReleaseAndReserveSalesOrder(SalesHeader, LocationWhite.Code, Item."No.", Quantity / 4, false);  // Reserve -False.
        CreateWhseShipmentAndPick(SalesHeader);
        RegisterWarehouseActivity(SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SalesHeader."No.");
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        CreateReleaseAndReserveSalesOrder(SalesHeader2, LocationWhite.Code, Item."No.", Quantity / 4, false);  // Reserve -False.
        CreateWhseShipmentAndPick(SalesHeader2);
        UpdateQuantityToHandleOnActivityLine(WarehouseActivityLine2, SalesHeader2."No.", LocationWhite.Code, Quantity / 4);  // Update Quantity on Activity Line.
        RegisterWarehouseActivity(SalesHeader2."No.", WarehouseActivityLine2."Activity Type"::Pick);

        CreateReleaseAndReserveSalesOrder(SalesHeader3, LocationWhite.Code, Item."No.", Quantity / 4, false);  // Reserve -False.

        // Exercise: Create Pick From Warehouse Shipment For Sales Order.
        CreateWhseShipmentAndPick(SalesHeader3);

        // Verify: Verify Pick has been created for Remaining Quantity Available only.
        ExpectedQuantity := Quantity - (Quantity / 4 + Quantity / 4 + Quantity / 4);  // Quantity calculated for Remaining Pick.
        VerifyRemainingQunatityOnPick(SalesHeader3."No.", Item."No.", LocationWhite.Code, ExpectedQuantity);
    end;

    [Test]
    [HandlerFunctions('PhysInvtItemSelectionPageHandler,CalculatePhysInvtCountingPageHandler')]
    [Scope('OnPrem')]
    procedure CalculateCountingPeriodForItem()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
    begin
        // Setup: Create Item with Physical Inventory Counting Period, create and post Purchase order, create blank Item Journal Line.
        Initialize();
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);  // Using Random value.
        UpdateItemForPhysicalInventoryCountingPeriod(Item);
        CreateAndPostPurchaseOrder(Item."No.", Quantity);
        GlobalItemNo := Item."No.";  // Asssign value to global variable.

        // Create Blank Item Journal Line.
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", '', 0.0);
        Commit();

        // Exercise: Calculate Counting Period.
        LibraryInventory.CalculateCountingPeriod(ItemJournalLine);

        // Verify: Verify calculated Quantity for Item in Item Journal Line.
        VerifyItemJournalLine(GlobalItemNo, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehouseShipmentWithMoreThanInventory()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Quantity: Decimal;
    begin
        // Setup: Create Item, Update inventory, Create Sales Order and release Sales Order.
        Initialize();
        Quantity := LibraryRandom.RandDec(100, 2);
        LibraryInventory.CreateItem(Item);
        UpdateItemInventory(Item."No.", LocationYellow.Code, '', Quantity);
        CreateSalesOrder(SalesHeader, LocationYellow.Code, Item."No.", Quantity + 100);  // Quantity more than available in Inventory.
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // Exercise: Create Whse Shipment from Sales Order.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // Verify: Verify the values on Whse Shipment created.
        FilterWarehouseShipmentLine(WarehouseShipmentLine, SalesHeader."No.");
        WarehouseShipmentLine.FindFirst();
        VerifyWarehouseShipmentLine(WarehouseShipmentLine, Item."No.", Quantity + 100);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteLocationWithOpenInventory()
    var
        Item: Record Item;
    begin
        // Setup: Create Item, update Inventory for Item.
        Initialize();
        LibraryInventory.CreateItem(Item);
        UpdateItemInventory(Item."No.", LocationBlue.Code, '', LibraryRandom.RandDec(100, 2));

        // Exercise: Delete Location.
        asserterror LocationBlue.Delete(true);

        // Verify: Verify that Location cannot be deleted if it has already open Item Ledger Entry.
        Assert.ExpectedError(StrSubstNo(LocationError, LocationBlue.Code));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseInternalMovementWithMoreThanBinQuantity()
    var
        Item: Record Item;
        Bin: Record Bin;
        InternalMovementHeader: Record "Internal Movement Header";
        InternalMovementLine: Record "Internal Movement Line";
        InternalMovement: TestPage "Internal Movement";
        Quantity: Decimal;
    begin
        // Setup: Create Item, update inventory, create an Internal Movement.
        Initialize();
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        LibraryWarehouse.FindBin(Bin, LocationOrange.Code, '', 2);
        UpdateItemInventory(Item."No.", LocationOrange.Code, Bin.Code, Quantity);
        CreateInternalMovement(InternalMovementHeader, LocationOrange.Code, Item."No.", Bin.Code, Quantity);
        OpenInternalMovementPage(InternalMovement, InternalMovementHeader."No.");

        // Exercise: Create Internal Movement Line for more than Quantity available in Inventory for Bin.
        asserterror InternalMovement.InternalMovementLines.Quantity.SetValue(Quantity + 100);

        // Verify: Verify the error for the available Quantity.
        Assert.ExpectedError(StrSubstNo(ValidationError, InternalMovementLine.FieldCaption(Quantity)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemJournalLineAfterWhseAdjustmentForMultipleItems()
    var
        Item: Record Item;
        Item2: Record Item;
        Zone: Record Zone;
        Bin: Record Bin;
    begin
        // Setup: Create multiple Items.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);

        // Create Warehouse Journal Lines and Calculate Warehouse Adjustment for both Items.
        FindZone(Zone, LocationWhite.Code);
        LibraryWarehouse.FindBin(Bin, LocationWhite.Code, Zone.Code, 2);  // Value required for Bin on the selected Zone.
        CreateWhseJournal(Item, LocationWhite.Code, Zone.Code, Bin.Code);
        CreateWhseJournal(Item2, LocationWhite.Code, Zone.Code, Bin.Code);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationWhite.Code, true);
        CalculateWhseAdjustmentForMultipleItems(ItemJournalBatch, Item."No.", Item2."No.");

        // Exercise: Post Item Journal Line For first Item only.
        PostItemJournalLine(Item."No.", LocationWhite.Code);

        // Verify: Verify after posting of first Item, second Item is still present on same Item Journal Worksheet.
        VerifyItemJournalLineBatchAndTemplateForItem(
          Item2."No.", LocationWhite.Code, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    [Test]
    [HandlerFunctions('CreateWhsePutAwayPickHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PickFromTransferOrderContainingEmptyLineCanBePosted()
    var
        Item: Record Item;
        PickLocation: Record Location;
        InTransitLocation: Record Location;
        TransferHeader: Record "Transfer Header";
        WhseActivLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // [FEATURE] [Transfer] [Inventory Pick]
        // [SCENARIO 362740] Inventory pick created from a transfer order containing a comment line (line without item no.) can be posted

        Initialize();

        LibraryInventory.CreateItem(Item);
        // [GIVEN] Location "L" with "Require Pick" = TRUE
        LibraryWarehouse.CreateLocationWMS(PickLocation, false, false, true, false, false);
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        Quantity := LibraryRandom.RandDec(100, 2);
        UpdateItemInventory(Item."No.", PickLocation.Code, '', Quantity);

        // [GIVEN] Transfer order, transfer from location "L", one line with item, another one - comment only
        CreateTransferOrderWithEmptyLine(TransferHeader, PickLocation.Code, LocationBlue.Code, InTransitLocation.Code, Item."No.", Quantity);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);

        // [GIVEN] Create inventory pick from transfer
        Commit();
        TransferHeader.CreateInvtPutAwayPick();

        FindWhseActivityLine(
          WhseActivLine, WhseActivLine."Activity Type"::"Invt. Pick", WhseActivLine."Action Type"::" ",
          PickLocation.Code, TransferHeader."No.");
        WhseActivLine.Validate("Qty. to Handle", Quantity);
        WhseActivLine.Modify(true);

        // [WHEN] Post inventory pick
        PostInventoryActivity(WhseActivLine."Activity Type", WhseActivLine."No.");

        // [THEN] Inventory pick is successfully posted
        VerifyTransferShipmentPosted(TransferHeader."No.", Item."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,WhseSourceCreateDocumentOKHandler')]
    [Scope('OnPrem')]
    procedure WhseActivityPickLocationNotRequirePickProductionOrder()
    var
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [FEATURE] [Production Order]
        // [SCENARIO 380898] For Production Order it's possible to create pick even if Location."Require Pick" is FALSE.
        Initialize();

        // [GIVEN] Location "L" with bins and "Require Pick" disabled.
        CreateLocationNotRequirePick(Location);

        // [GIVEN] Refreshed Production Order.
        CreateRefreshedProductionOrder(ProductionOrder, Location);

        // [WHEN] Create Pick
        ProductionOrder.CreatePick(UserId, 0, false, false, false);

        // [THEN] Corresponded Whse. Activity Line is created.
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick,
          WarehouseActivityLine."Action Type"::Place, Location.Code, ProductionOrder."No.");

        Assert.AreEqual(
          ProductionOrder.Quantity, WarehouseActivityLine.Quantity,
          StrSubstNo(QtyMismErr, ProductionOrder.TableName, WarehouseActivityLine.TableName));
    end;

    [Test]
    [HandlerFunctions('WhseChangeUnitOfMeasureRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ActionTypeNotEditableInChangeUoMRequestPage()
    var
        Item: Record Item;
        Zone: Record Zone;
        Bin: Record Bin;
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Change Unit Of Measure]
        // [SCENARIO 202744] Fields "Action Type" and "Unit Of Measure Code" in the request page of the report 7314 "Whse. Change Unit of Measure" should not be editable

        Initialize();

        // [GIVEN] Post some stock of item "I" on a location "L" with "Directed Put-away and Pick" enabled
        LibraryInventory.CreateItem(Item);
        FindZone(Zone, LocationWhite.Code);
        LibraryWarehouse.CreateBin(Bin, LocationWhite.Code, '', Zone.Code, LibraryWarehouse.SelectBinType(false, false, true, true));
        Qty := LibraryRandom.RandDec(100, 2);
        UpdateInventoryUsingWhseAdjustmentPerZone(Item, LocationWhite.Code, Zone.Code, Bin.Code, Qty);
        // [GIVEN] Create a sales order for item "I" on location "L". Create warehouse shipment, then pick
        CreateReleaseAndReserveSalesOrder(SalesHeader, Bin."Location Code", Item."No.", Qty, false);
        CreateWhseShipmentAndPick(SalesHeader);

        FindWhseActivityLine(WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take, LocationWhite.Code, SalesHeader."No.");

        // [WHEN] Run "Change Unit Of Measure" on the pick document
        LibraryWarehouse.ChangeUnitOfMeasure(WarehouseActivityLine);

        // [THEN] "Action Type" and "Quantity to Handle" are not editable
        // Verified in WhseChangeUnitOfMeasureRequestPageHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenWhseInternalMovementForUndefaultLocation()
    var
        Location: Record Location;
        InternalMovementHeader: Record "Internal Movement Header";
        WMSManagement: Codeunit "WMS Management";
        DefaultLocationCode: Code[10];
    begin
        // [FEATURE] [Internal Movement]
        // [SCENARIO 381770]  If user is warehouse employee to more then one locations and default location has "Directed Put-away and Pick" enabled, then not default location is used when Internal Movement Card opens.
        Initialize();

        // [GIVEN] Default Location "DL" with "Directed Put-away and Pick" enabled.
        DefaultLocationCode := WMSManagement.GetDefaultLocation();

        // [GIVEN] There are other locations with "Directed Put-away and Pick" disabled and "Bin Mandatory" enabled to which current user is warehouse employee.
        CreateLocationNotRequirePick(Location);

        // [WHEN] Internal Movement Card "IMC" opens
        InternalMovementHeader.Init();
        InternalMovementHeader.OpenInternalMovementHeader(InternalMovementHeader);

        // [THEN] "IMC"."Location Code" field value is not equal to "DL"."Code" field.
        InternalMovementHeader.FilterGroup := 2;
        Assert.AreNotEqual(DefaultLocationCode, InternalMovementHeader.GetFilter("Location Code"),
          StrSubstNo(UnexpectedLocationCodeErr, InternalMovementHeader.GetFilter("Location Code"), DefaultLocationCode));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenWhseInternalMovementForDefaultLocation()
    var
        InternalMovementHeader: Record "Internal Movement Header";
        WarehouseEmployee: Record "Warehouse Employee";
        WMSManagement: Codeunit "WMS Management";
        DefaultLocationCode: Code[10];
    begin
        // [FEATURE] [Internal Movement]
        // [SCENARIO 381770] If user is warehouse employee to more then one locations and default location has "Directed Put-away and Pick" disabled, "Bin Mandatory" enabled then default location is used when Internal Movement Card opens.
        Initialize();

        // [GIVEN] Default Location "DL" with "Directed Put-away and Pick" disabled, "Bin Mandatory" enabled.
        // [GIVEN] There are other locations with "Directed Put-away and Pick" disabled and "Bin Mandatory" enabled to which current user is warehouse employee.
        WarehouseEmployee.DeleteAll(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite.Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationOrange.Code, true);
        DefaultLocationCode := WMSManagement.GetDefaultLocation();

        // [WHEN] Internal Movement Card "IMC" opens
        InternalMovementHeader.Init();
        InternalMovementHeader.OpenInternalMovementHeader(InternalMovementHeader);

        // [THEN] "IMC"."Location Code" field value is equal to "DL"."Code" field.
        InternalMovementHeader.FilterGroup := 2;
        Assert.AreEqual(DefaultLocationCode, InternalMovementHeader.GetFilter("Location Code"),
          StrSubstNo(LocationCodeMustNotOccurErr, InternalMovementHeader.GetFilter("Location Code"), DefaultLocationCode));

        // Tear down.
        WarehouseEmployee.Reset();
        WarehouseEmployee.DeleteAll(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite.Code, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationOrange.Code, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetErrorWhenOpenWhseInternalMovementAndNoAllowedLocations()
    var
        InternalMovementHeader: Record "Internal Movement Header";
        WarehouseEmployee: Record "Warehouse Employee";
        WMSManagement: Codeunit "WMS Management";
        SavedBinMandatory: Boolean;
        SavedDirectedPutAwayAndPick: Boolean;
    begin
        // [FEATURE] [Internal Movement]
        // [SCENARIO 381770] If user is warehouse employee for only one location with "Directed Put-away and Pick" enabled error "No locations with allowed internal movements with permissions for you." occurs.
        Initialize();

        // [GIVEN] Default Location "DL" with "Directed Put-away and Pick" enabled.
        // [GIVEN] There are no other locations to which current user is warehouse employee.
        WarehouseEmployee.DeleteAll(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite.Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationOrange.Code, true);

        // Save to tear down.
        GetSetDirectedBinMandatoryAndPutAwayAndPickOnLocation(
          SavedBinMandatory, SavedDirectedPutAwayAndPick, WMSManagement.GetDefaultLocation(), true, true);

        // [WHEN] Internal Movement Card "IMC" opens
        InternalMovementHeader.Init();
        asserterror InternalMovementHeader.OpenInternalMovementHeader(InternalMovementHeader);

        // [THEN] Error "No locations with allowed internal movements with permissions for you." occurs.
        Assert.ExpectedError(NoAllowedLocationsErr);

        // Tear down.
        WarehouseEmployee.Reset();
        WarehouseEmployee.DeleteAll(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite.Code, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationOrange.Code, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure CompletePartiallyRegisteredPickOfATOComponent()
    var
        Zone: Record Zone;
        Bin: Record Bin;
        AsmItem: Record Item;
        CompItem: Record Item;
        BOMComponent: Record "BOM Component";
        SalesHeader: Record "Sales Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        RegisteredWhseActivityHdr: Record "Registered Whse. Activity Hdr.";
        AsmToOrderNo: Code[20];
        Qty: Decimal;
    begin
        // [FEATURE] [Assemble-to-Order]
        // [SCENARIO 261798] A pick of assemble-to-order component can be registered in two steps.
        Initialize();

        // [GIVEN] Assemble-to-order item "I".
        LibraryInventory.CreateItem(AsmItem);
        AsmItem.Validate("Replenishment System", AsmItem."Replenishment System"::Assembly);
        AsmItem.Validate("Assembly Policy", AsmItem."Assembly Policy"::"Assemble-to-Order");
        AsmItem.Modify(true);

        // [GIVEN] Purchased item "C" which is a component of "I".
        LibraryInventory.CreateItem(CompItem);
        LibraryInventory.CreateBOMComponent(
          BOMComponent, AsmItem."No.", BOMComponent.Type::Item, CompItem."No.", 1, CompItem."Base Unit of Measure");

        // [GIVEN] Post the positive adjustment for "Q" pcs of item "C" on location set up for directed put-away and pick.
        LibraryWarehouse.FindZone(Zone, LocationWhite.Code, LibraryWarehouse.SelectBinType(false, false, true, true), false);
        LibraryWarehouse.FindBin(Bin, LocationWhite.Code, Zone.Code, 1);
        Qty := LibraryRandom.RandIntInRange(20, 40);
        UpdateInventoryUsingWhseAdjustmentPerZone(CompItem, LocationWhite.Code, Zone.Code, Bin.Code, Qty);

        // [GIVEN] Released sales order for "Q" pcs of assembled item "I".
        CreateSalesOrder(SalesHeader, LocationWhite.Code, AsmItem."No.", Qty);
        AsmToOrderNo := FindAssemblyToOrderNo(AsmItem."No.");
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Create shipment and pick for the sales order.
        // [GIVEN] Update "Qty. to Handle" to register half a quantity first ("Q" / 2).
        // [GIVEN] Register the pick.
        CreateWhseShipmentAndPick(SalesHeader);
        UpdateQuantityToHandleOnActivityLine(WarehouseActivityLine, AsmToOrderNo, LocationWhite.Code, Qty div 2);
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::Pick, WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [GIVEN] Update "Qty. to Handle" in order to complete the pick.
        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);

        // [WHEN] Register the pick.
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] The pick is registered in full.
        Assert.RecordIsEmpty(WarehouseActivityLine);

        // [THEN] Two registered picks are in the database.
        RegisteredWhseActivityHdr.SetRange("Whse. Activity No.", WarehouseActivityHeader."No.");
        Assert.RecordCount(RegisteredWhseActivityHdr, 2);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostPickCreatedFromSalesOrderWhenDiffUoMAndQtyToHandleUpdatedInWHActivityLine()
    var
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        LocationCode: Code[10];
        ItemNo: Code[20];
        UoM: Code[10];
        QtyPerBaseUoM: Integer;
        Quantity: Decimal;
        QtyToHandle: Decimal;
    begin
        // [SCENARIO 297875] Base Quantities in Item Ledger Entry and Sales Shipment Line when Inventory Pick is created from Sales Order and posted
        // [SCENARIO 297875] in case UoMs differ and Qty. to Handle is updated in Warehouse Activity Line
        Initialize();
        Quantity := 1;
        QtyPerBaseUoM := 3;
        QtyToHandle := Round(Quantity / QtyPerBaseUoM, GetQtyRoundingPrecision());

        // [GIVEN] Location with Require Pick enabled
        LocationCode := CreateLocationWithRequirePickPutAway(true, false);

        // [GIVEN] Item with Base UoM 'PCS' and other UoM 'PACK' = 3 'PCS'
        CreateItemWithUoM(ItemNo, UoM, QtyPerBaseUoM);
        Item.Get(ItemNo);
        ItemUnitOfMeasure.Get(ItemNo, Item."Base Unit of Measure");
        ItemUnitOfMeasure.Validate("Qty. Rounding Precision", 1);
        ItemUnitOfMeasure.Modify(true);

        // [GIVEN] Posted purchase Item Journal Line with 1 'PCS'
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, '', Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Released Sales Order with with 1 'PACK'
        CreateSalesDocWithItemLocationQtyAndUoM(SalesHeader, SalesHeader."Document Type"::Order, ItemNo, LocationCode, Quantity, UoM);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Created Inventory Pick with Qty. to Handle = 0.33333
        CreateInvtPutPickFromSalesDoc(WarehouseActivityHeader, SalesHeader, "Warehouse Request Source Document"::"Sales Order");
        UpdateQtyToHandleInWhseActivityLine(WarehouseActivityHeader.Type, WarehouseActivityHeader."No.", QtyToHandle);

        // [WHEN] Post Inventory Pick
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, true);

        // [THEN] Item Ledger Entry has Quantity = -1
        VerifyItemLedgerEntryQty(ItemNo, "Item Ledger Document Type"::"Sales Shipment", LocationCode, -1);

        // [THEN] Posted Sales Shipment Line has Quantity (Base) = Qty. Invoiced (Base) = 1
        VerifySalesShipmentBaseQty(SalesHeader."Sell-to Customer No.", 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostPutAwayCreatedFromPurchOrderWhenDiffUoMAndQtyToHandleUpdatedInWHActivityLine()
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        LocationCode: Code[10];
        ItemNo: Code[20];
        UoM: Code[10];
        QtyPerBaseUoM: Integer;
        Quantity: Decimal;
        QtyToHandle: Decimal;
    begin
        // [SCENARIO 297875] Base Quantities in Item Ledger Entry and Purchase Receipt Line when Inventory Put-Away is created from Purchase Order and posted
        // [SCENARIO 297875] in case UoMs differ and Qty. to Handle is updated in Warehouse Activity Line
        Initialize();
        Quantity := 1;
        QtyPerBaseUoM := 3;
        QtyToHandle := Round(Quantity / QtyPerBaseUoM, GetQtyRoundingPrecision());

        // [GIVEN] Location with Require Put-Away enabled
        LocationCode := CreateLocationWithRequirePickPutAway(false, true);

        // [GIVEN] Item with Base UoM 'PCS' and other UoM 'PACK' = 3 'PCS'
        CreateItemWithUoM(ItemNo, UoM, QtyPerBaseUoM);

        // [GIVEN] Released Purchase Order with with 1 'PACK'
        CreatePurchaseDocWithItemLocationQtyAndUoM(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, ItemNo, LocationCode, Quantity, UoM);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Created Inventory Put-Away with Qty. to Handle = 0.33333
        CreateInvtPutPickFromPurchDoc(WarehouseActivityHeader, PurchaseHeader, "Warehouse Request Source Document"::"Purchase Order");
        UpdateQtyToHandleInWhseActivityLine(WarehouseActivityHeader.Type, WarehouseActivityHeader."No.", QtyToHandle);

        // [WHEN] Post Inventory Put-Away
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, true);

        // [THEN] Item Ledger Entry has Quantity = 0.99999
        VerifyItemLedgerEntryQty(ItemNo, "Item Ledger Document Type"::"Purchase Receipt", LocationCode, QtyPerBaseUoM * QtyToHandle);

        // [THEN] Posted Purchase Receipt Line has Quantity (Base) = Qty. Invoiced (Base) = 0.99999
        VerifyPurchRcptLineBaseQty(PurchaseHeader."Buy-from Vendor No.", QtyPerBaseUoM * QtyToHandle);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostPutAwayCreatedFromSalesReturnOrderWhenDiffUoMAndQtyToHandleUpdatedInWHActivityLine()
    var
        SalesHeader: Record "Sales Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        LocationCode: Code[10];
        ItemNo: Code[20];
        UoM: Code[10];
        QtyPerBaseUoM: Integer;
        Quantity: Decimal;
        QtyToHandle: Decimal;
    begin
        // [SCENARIO 297875] Base Quantities in Item Ledger Entry and Return Receipt Line when Inventory Put-Away is created from Return Sales Order and posted
        // [SCENARIO 297875] in case UoMs differ and Qty. to Handle is updated in Warehouse Activity Line
        Initialize();
        Quantity := 1;
        QtyPerBaseUoM := 3;
        QtyToHandle := Round(Quantity / QtyPerBaseUoM, GetQtyRoundingPrecision());

        // [GIVEN] Location with Require Put-Away enabled
        LocationCode := CreateLocationWithRequirePickPutAway(false, true);

        // [GIVEN] Item with Base UoM 'PCS' and other UoM 'PACK' = 3 'PCS'
        CreateItemWithUoM(ItemNo, UoM, QtyPerBaseUoM);

        // [GIVEN] Released Sales Return Order with with 1 'PACK'
        CreateSalesDocWithItemLocationQtyAndUoM(
          SalesHeader, SalesHeader."Document Type"::"Return Order", ItemNo, LocationCode, Quantity, UoM);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Created Inventory Put-Away with Qty. to Handle = 0.33333
        CreateInvtPutPickFromSalesDoc(WarehouseActivityHeader, SalesHeader, "Warehouse Request Source Document"::"Sales Return Order");
        UpdateQtyToHandleInWhseActivityLine(WarehouseActivityHeader.Type, WarehouseActivityHeader."No.", QtyToHandle);

        // [WHEN] Post Inventory Put-Away
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, true);

        // [THEN] Item Ledger Entry has Quantity = 0.99999
        VerifyItemLedgerEntryQty(ItemNo, "Item Ledger Document Type"::"Sales Return Receipt", LocationCode, QtyPerBaseUoM * QtyToHandle);

        // [THEN] Return Receipt Line has Quantity (Base) = Qty. Invoiced (Base) = 0.99999
        VerifyReturnReceiptLineBaseQty(SalesHeader."Sell-to Customer No.", QtyPerBaseUoM * QtyToHandle);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostPickCreatedFromPurchReturnOrderWhenDiffUoMAndQtyToHandleUpdatedInWHActivityLine()
    var
        ItemJournalLine: Record "Item Journal Line";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        LocationCode: Code[10];
        ItemNo: Code[20];
        UoM: Code[10];
        QtyPerBaseUoM: Integer;
        Quantity: Decimal;
        QtyToHandle: Decimal;
    begin
        // [SCENARIO 297875] Base Quantities in Item Ledger Entry and Return Shipment Line when Inventory Pick is created from Purchase Return Order and posted
        // [SCENARIO 297875] in case UoMs differ and Qty. to Handle is updated in Warehouse Activity Line
        Initialize();
        Quantity := 1;
        QtyPerBaseUoM := 3;
        QtyToHandle := Round(Quantity / QtyPerBaseUoM, GetQtyRoundingPrecision());

        // [GIVEN] Location with Require Pick enabled
        LocationCode := CreateLocationWithRequirePickPutAway(true, false);

        // [GIVEN] Item with Base UoM 'PCS' and other UoM 'PACK' = 3 'PCS'
        CreateItemWithUoM(ItemNo, UoM, QtyPerBaseUoM);

        // [GIVEN] Posted Purchase Item Journal Line with 1 'PACK'
        CreateItemJournalLineWithLocationQtyAndUoM(ItemJournalLine, ItemNo, LocationCode, Quantity, UoM);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Released Purchase Return Order with with 1 'PACK'
        CreatePurchaseDocWithItemLocationQtyAndUoM(
          PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", ItemNo, LocationCode, Quantity, UoM);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Created Inventory Pick with Qty. to Handle = 0.33333
        CreateInvtPutPickFromPurchDoc(WarehouseActivityHeader, PurchaseHeader, "Warehouse Request Source Document"::"Purchase Return Order");
        UpdateQtyToHandleInWhseActivityLine(WarehouseActivityHeader.Type, WarehouseActivityHeader."No.", QtyToHandle);

        // [WHEN] Post Inventory Pick
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, true);

        // [THEN] Item Ledger Entry has Quantity = -0.99999
        VerifyItemLedgerEntryQty(ItemNo, "Item Ledger Document Type"::"Purchase Return Shipment", LocationCode, -QtyPerBaseUoM * QtyToHandle);

        // [THEN] Return Shipment Line has Quantity (Base) = Qty. Invoiced (Base) = 0.99999
        VerifyReturnShipmentLineBaseQty(PurchaseHeader."Buy-from Vendor No.", QtyPerBaseUoM * QtyToHandle);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostPickCreatedFromTransferOrderWhenDiffUoMAndQtyToHandleUpdatedInWHActivityLine()
    var
        ItemJournalLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        FromLocationCode: Code[10];
        ToLocationCode: Code[10];
        InTransitLocationCode: Code[10];
        ItemNo: Code[20];
        UoM: Code[10];
        QtyPerBaseUoM: Integer;
        Quantity: Decimal;
        QtyToHandle: Decimal;
    begin
        // [SCENARIO 297875] Base Quantities in Item Ledger Entry and Transfer Shipment Line when Inventory Pick is created from Transfer Order and posted
        // [SCENARIO 297875] in case UoMs differ and Qty. to Handle is updated in Warehouse Activity Line
        Initialize();
        Quantity := 1;
        QtyPerBaseUoM := 3;
        QtyToHandle := Round(Quantity / QtyPerBaseUoM, GetQtyRoundingPrecision());

        // [GIVEN] Location SILVER with Require Pick enabled
        CreateTransferLocationsWithRequirePickPutAway(FromLocationCode, ToLocationCode, InTransitLocationCode);

        // [GIVEN] Item with Base UoM 'PCS' and other UoM 'PACK' = 3 'PCS'
        CreateItemWithUoM(ItemNo, UoM, QtyPerBaseUoM);
        Item.Get(ItemNo);
        ItemUnitOfMeasure.Get(ItemNo, Item."Base Unit of Measure");
        ItemUnitOfMeasure.Validate("Qty. Rounding Precision", 1);
        ItemUnitOfMeasure.Modify(true);

        // [GIVEN] Posted purchase Item Journal Line with 1 'PCS' in SILVER Location
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, FromLocationCode, '', Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Transfer Order from Location SILVER having In-Transit Location RED and 1 'PACK' was released
        CreateTransferOrderWithItemLocationQtyAndUoM(
          TransferHeader, ItemNo, FromLocationCode, ToLocationCode, InTransitLocationCode, Quantity, UoM);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);

        // [GIVEN] Created Inventory Pick with Qty. to Handle = 0.33333
        CreateInvtPutPickFromTrasferOrder(WarehouseActivityHeader, TransferHeader."No.", "Warehouse Request Source Document"::"Outbound Transfer", false, true);
        UpdateQtyToHandleInWhseActivityLine(WarehouseActivityHeader.Type, WarehouseActivityHeader."No.", QtyToHandle);

        // [WHEN] Post Inventory Pick
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, true);

        // [THEN] Transfer Shipment Item Ledger Entry for Location SILVER has Quantity = -1
        VerifyItemLedgerEntryQty(ItemNo, "Item Ledger Document Type"::"Transfer Shipment", FromLocationCode, -1);

        // [THEN] Transfer Shipment Item Ledger Entry for Location RED has Quantity = 1
        VerifyItemLedgerEntryQty(ItemNo, "Item Ledger Document Type"::"Transfer Shipment", InTransitLocationCode, 1);

        // [THEN] Posted Transfer Shipment Line has Quantity (Base) = 1
        VerifyTransferShipmentLineBaseQty(FromLocationCode, ToLocationCode, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostPutAwayCreatedFromTransferOrderWhenDiffUoMAndQtyToHandleUpdatedInWHActivityLine()
    var
        ItemJournalLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        FromLocationCode: Code[10];
        ToLocationCode: Code[10];
        InTransitLocationCode: Code[10];
        ItemNo: Code[20];
        UoM: Code[10];
        QtyPerBaseUoM: Integer;
        Quantity: Decimal;
        QtyToHandle: Decimal;
    begin
        // [SCENARIO 297875] Base Quantities in Item Ledger Entry and Transfer Receipt Line when Inventory Put-Away is created from Transfer Order and posted
        // [SCENARIO 297875] in case UoMs differ and Qty. to Handle is updated in Warehouse Activity Line
        Initialize();
        Quantity := 1;
        QtyPerBaseUoM := 3;
        QtyToHandle := Round(Quantity / QtyPerBaseUoM, GetQtyRoundingPrecision());

        // [GIVEN] Location RED with Require Put-Away enabled
        CreateTransferLocationsWithRequirePickPutAway(FromLocationCode, ToLocationCode, InTransitLocationCode);

        // [GIVEN] Item with Base UoM 'PCS' and other UoM 'PACK' = 3 'PCS'
        CreateItemWithUoM(ItemNo, UoM, QtyPerBaseUoM);

        // [GIVEN] Posted purchase Item Journal Line with 1 'PACK' in SILVER Location
        CreateItemJournalLineWithLocationQtyAndUoM(ItemJournalLine, ItemNo, FromLocationCode, Quantity, UoM);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Posted Transfer Order from Location SILVER to Location RED with In-Transit Location XXX and 1 'PACK' was posted
        CreateTransferOrderWithItemLocationQtyAndUoM(
          TransferHeader, ItemNo, FromLocationCode, ToLocationCode, InTransitLocationCode, Quantity, UoM);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        // [GIVEN] Released incoming Transfer Order from Location SILVER to Location RED
        FindTransferHeaderByFromToLocation(TransferHeader, FromLocationCode, ToLocationCode);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);

        // [GIVEN] Created Inventory Put-Away with Qty. to Handle = 0.33333
        CreateInvtPutPickFromTrasferOrder(WarehouseActivityHeader, TransferHeader."No.", "Warehouse Request Source Document"::"Inbound Transfer", true, false);
        UpdateQtyToHandleInWhseActivityLine(WarehouseActivityHeader.Type, WarehouseActivityHeader."No.", QtyToHandle);

        // [WHEN] Post Inventory Put-Away
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, true);

        // [THEN] Transfer Receipt Item Ledger Entry for Location SILVER has Quantity = 0.99999
        VerifyItemLedgerEntryQty(ItemNo, "Item Ledger Document Type"::"Transfer Receipt", ToLocationCode, QtyPerBaseUoM * QtyToHandle);

        // [THEN] Transfer Receipt Item Ledger Entry for Location XXX has Quantity = -0.99999
        VerifyItemLedgerEntryQty(ItemNo, "Item Ledger Document Type"::"Transfer Receipt", InTransitLocationCode, -QtyPerBaseUoM * QtyToHandle);

        // [THEN] Posted Transfer Receipt Line has Quantity (Base) = 0.99999
        VerifyTransferReceiptLineBaseQty(FromLocationCode, ToLocationCode, QtyPerBaseUoM * QtyToHandle);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostPickCreatedFromSalesOrderWhenDiffUoMAndQtyToHandleBaseUpdatedInWHActivityLine()
    var
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        LocationCode: Code[10];
        ItemNo: Code[20];
        UoM: Code[10];
        QtyPerBaseUoM: Integer;
        Quantity: Decimal;
    begin
        // [SCENARIO 297875] Base Quantities in Item Ledger Entry and Sales Shipment Line when Inventory Pick is created from Sales Order and posted
        // [SCENARIO 297875] in case UoMs differ and Qty. to Handle (Base) is updated in Warehouse Activity Line
        Initialize();
        Quantity := 1;
        QtyPerBaseUoM := 3;

        // [GIVEN] Location with Require Pick enabled
        LocationCode := CreateLocationWithRequirePickPutAway(true, false);

        // [GIVEN] Item with Base UoM 'PCS' and other UoM 'PACK' = 3 'PCS'
        CreateItemWithUoM(ItemNo, UoM, QtyPerBaseUoM);

        // [GIVEN] Posted purchase Item Journal Line with 1 'PCS'
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, '', Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Released Sales Order with with 1 'PACK'
        CreateSalesDocWithItemLocationQtyAndUoM(SalesHeader, SalesHeader."Document Type"::Order, ItemNo, LocationCode, Quantity, UoM);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Created Inventory Pick with Qty. to Handle (Base) = 1
        CreateInvtPutPickFromSalesDoc(WarehouseActivityHeader, SalesHeader, "Warehouse Request Source Document"::"Sales Order");
        UpdateQtyToHandleBaseInWhseActivityLine(WarehouseActivityHeader.Type, WarehouseActivityHeader."No.", Quantity);

        // [WHEN] Post Inventory Pick
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, true);

        // [THEN] Item Ledger Entry has Quantity = -1
        VerifyItemLedgerEntryQty(ItemNo, "Item Ledger Document Type"::"Sales Shipment", LocationCode, -Quantity);

        // [THEN] Posted Sales Shipment Line has Quantity (Base) = Qty. Invoiced (Base) = 1
        VerifySalesShipmentBaseQty(SalesHeader."Sell-to Customer No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostPutAwayCreatedFromPurchOrderWhenDiffUoMAndQtyToHandleBaseUpdatedInWHActivityLine()
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        LocationCode: Code[10];
        ItemNo: Code[20];
        UoM: Code[10];
        QtyPerBaseUoM: Integer;
        Quantity: Decimal;
    begin
        // [SCENARIO 297875] Base Quantities in Item Ledger Entry and Purchase Receipt Line when Inventory Put-Away is created from Purchase Order and posted
        // [SCENARIO 297875] in case UoMs differ and Qty. to Handle (Base) is updated in Warehouse Activity Line
        Initialize();
        Quantity := 1;
        QtyPerBaseUoM := 3;

        // [GIVEN] Location with Require Put-Away enabled
        LocationCode := CreateLocationWithRequirePickPutAway(false, true);

        // [GIVEN] Item with Base UoM 'PCS' and other UoM 'PACK' = 3 'PCS'
        CreateItemWithUoM(ItemNo, UoM, QtyPerBaseUoM);

        // [GIVEN] Released Purchase Order with with 1 'PACK'
        CreatePurchaseDocWithItemLocationQtyAndUoM(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, ItemNo, LocationCode, Quantity, UoM);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Created Inventory Put-Away with Qty. to Handle (Base) = 1
        CreateInvtPutPickFromPurchDoc(WarehouseActivityHeader, PurchaseHeader, "Warehouse Request Source Document"::"Purchase Order");
        UpdateQtyToHandleBaseInWhseActivityLine(WarehouseActivityHeader.Type, WarehouseActivityHeader."No.", Quantity);

        // [WHEN] Post Inventory Put-Away
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, true);

        // [THEN] Item Ledger Entry has Quantity = 1
        VerifyItemLedgerEntryQty(ItemNo, "Item Ledger Document Type"::"Purchase Receipt", LocationCode, Quantity);

        // [THEN] Posted Purchase Receipt Line has Quantity (Base) = Qty. Invoiced (Base) = 1
        VerifyPurchRcptLineBaseQty(PurchaseHeader."Buy-from Vendor No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostPutAwayCreatedFromSalesReturnOrderWhenDiffUoMAndQtyToHandleBaseUpdatedInWHActivityLine()
    var
        SalesHeader: Record "Sales Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        LocationCode: Code[10];
        ItemNo: Code[20];
        UoM: Code[10];
        QtyPerBaseUoM: Integer;
        Quantity: Decimal;
    begin
        // [SCENARIO 297875] Base Quantities in Item Ledger Entry and Return Receipt Line when Inventory Put-Away is created from Return Sales Order and posted
        // [SCENARIO 297875] in case UoMs differ and Qty. to Handle (Base) is updated in Warehouse Activity Line
        Initialize();
        Quantity := 1;
        QtyPerBaseUoM := 3;

        // [GIVEN] Location with Require Put-Away enabled
        LocationCode := CreateLocationWithRequirePickPutAway(false, true);

        // [GIVEN] Item with Base UoM 'PCS' and other UoM 'PACK' = 3 'PCS'
        CreateItemWithUoM(ItemNo, UoM, QtyPerBaseUoM);

        // [GIVEN] Released Sales Return Order with with 1 'PACK'
        CreateSalesDocWithItemLocationQtyAndUoM(
          SalesHeader, SalesHeader."Document Type"::"Return Order", ItemNo, LocationCode, Quantity, UoM);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Created Inventory Put-Away with Qty. to Handle (Base) = 1
        CreateInvtPutPickFromSalesDoc(WarehouseActivityHeader, SalesHeader, "Warehouse Request Source Document"::"Sales Return Order");
        UpdateQtyToHandleBaseInWhseActivityLine(WarehouseActivityHeader.Type, WarehouseActivityHeader."No.", Quantity);

        // [WHEN] Post Inventory Put-Away
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, true);

        // [THEN] Item Ledger Entry has Quantity = 1
        VerifyItemLedgerEntryQty(ItemNo, "Item Ledger Document Type"::"Sales Return Receipt", LocationCode, Quantity);

        // [THEN] Return Receipt Line has Quantity (Base) = Qty. Invoiced (Base) = 1
        VerifyReturnReceiptLineBaseQty(SalesHeader."Sell-to Customer No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostPickCreatedFromPurchReturnOrderWhenDiffUoMAndQtyToHandleBaseUpdatedInWHActivityLine()
    var
        ItemJournalLine: Record "Item Journal Line";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        LocationCode: Code[10];
        ItemNo: Code[20];
        UoM: Code[10];
        QtyPerBaseUoM: Integer;
        Quantity: Decimal;
    begin
        // [SCENARIO 297875] Base Quantities in Item Ledger Entry and Return Shipment Line when Inventory Pick is created from Purchase Return Order and posted
        // [SCENARIO 297875] in case UoMs differ and Qty. to Handle (Base) is updated in Warehouse Activity Line
        Initialize();
        Quantity := 1;
        QtyPerBaseUoM := 3;

        // [GIVEN] Location with Require Pick enabled
        LocationCode := CreateLocationWithRequirePickPutAway(true, false);

        // [GIVEN] Item with Base UoM 'PCS' and other UoM 'PACK' = 3 'PCS'
        CreateItemWithUoM(ItemNo, UoM, QtyPerBaseUoM);

        // [GIVEN] Posted Purchase Item Journal Line with 1 'PACK'
        CreateItemJournalLineWithLocationQtyAndUoM(ItemJournalLine, ItemNo, LocationCode, Quantity, UoM);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Released Purchase Return Order with with 1 'PACK'
        CreatePurchaseDocWithItemLocationQtyAndUoM(
          PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", ItemNo, LocationCode, Quantity, UoM);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Created Inventory Pick with Qty. to Handle (Base) = 1
        CreateInvtPutPickFromPurchDoc(WarehouseActivityHeader, PurchaseHeader, "Warehouse Request Source Document"::"Purchase Return Order");
        UpdateQtyToHandleBaseInWhseActivityLine(WarehouseActivityHeader.Type, WarehouseActivityHeader."No.", Quantity);

        // [WHEN] Post Inventory Pick
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, true);

        // [THEN] Item Ledger Entry has Quantity = -1
        VerifyItemLedgerEntryQty(ItemNo, "Item Ledger Document Type"::"Purchase Return Shipment", LocationCode, -Quantity);

        // [THEN] Return Shipment Line has Quantity (Base) = Qty. Invoiced (Base) = 1
        VerifyReturnShipmentLineBaseQty(PurchaseHeader."Buy-from Vendor No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostPickCreatedFromTransferOrderWhenDiffUoMAndQtyToHandleBaseUpdatedInWHActivityLine()
    var
        ItemJournalLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        FromLocationCode: Code[10];
        ToLocationCode: Code[10];
        InTransitLocationCode: Code[10];
        ItemNo: Code[20];
        UoM: Code[10];
        QtyPerBaseUoM: Integer;
        Quantity: Decimal;
    begin
        // [SCENARIO 297875] Base Quantities in Item Ledger Entry and Transfer Shipment Line when Inventory Pick is created from Transfer Order and posted
        // [SCENARIO 297875] in case UoMs differ and Qty. to Handle (Base) is updated in Warehouse Activity Line
        Initialize();
        Quantity := 1;
        QtyPerBaseUoM := 3;

        // [GIVEN] Location SILVER with Require Pick enabled
        CreateTransferLocationsWithRequirePickPutAway(FromLocationCode, ToLocationCode, InTransitLocationCode);

        // [GIVEN] Item with Base UoM 'PCS' and other UoM 'PACK' = 3 'PCS'
        CreateItemWithUoM(ItemNo, UoM, QtyPerBaseUoM);

        // [GIVEN] Posted purchase Item Journal Line with 1 'PCS' in SILVER Location
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, FromLocationCode, '', Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Transfer Order from Location SILVER having In-Transit Location RED and 1 'PACK' was released
        CreateTransferOrderWithItemLocationQtyAndUoM(
          TransferHeader, ItemNo, FromLocationCode, ToLocationCode, InTransitLocationCode, Quantity, UoM);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);

        // [GIVEN] Created Inventory Pick with Qty. to Handle (Base) = 1
        CreateInvtPutPickFromTrasferOrder(WarehouseActivityHeader, TransferHeader."No.", "Warehouse Request Source Document"::"Outbound Transfer", false, true);
        UpdateQtyToHandleBaseInWhseActivityLine(WarehouseActivityHeader.Type, WarehouseActivityHeader."No.", Quantity);

        // [WHEN] Post Inventory Pick
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, true);

        // [THEN] Item Ledger Entry for Location SILVER has Quantity = -1
        VerifyItemLedgerEntryQty(ItemNo, "Item Ledger Document Type"::"Transfer Shipment", FromLocationCode, -Quantity);

        // [THEN] Item Ledger Entry for Location RED has Quantity = 1
        VerifyItemLedgerEntryQty(ItemNo, "Item Ledger Document Type"::"Transfer Shipment", InTransitLocationCode, Quantity);

        // [THEN] Posted Transfer Shipment Line has Quantity (Base) = 1
        VerifyTransferShipmentLineBaseQty(FromLocationCode, ToLocationCode, Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostPutAwayCreatedFromTransferOrderWhenDiffUoMAndQtyToHandleBaseUpdatedInWHActivityLine()
    var
        ItemJournalLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        FromLocationCode: Code[10];
        ToLocationCode: Code[10];
        InTransitLocationCode: Code[10];
        ItemNo: Code[20];
        UoM: Code[10];
        QtyPerBaseUoM: Integer;
        Quantity: Decimal;
    begin
        // [SCENARIO 297875] Base Quantities in Item Ledger Entry and Transfer Receipt Line when Inventory Put-Away is created from Transfer Order and posted
        // [SCENARIO 297875] in case UoMs differ and Qty. to Handle (Base) is updated in Warehouse Activity Line
        Initialize();
        Quantity := 1;
        QtyPerBaseUoM := 3;

        // [GIVEN] Location RED with Require Put-Away enabled
        CreateTransferLocationsWithRequirePickPutAway(FromLocationCode, ToLocationCode, InTransitLocationCode);

        // [GIVEN] Item with Base UoM 'PCS' and other UoM 'PACK' = 3 'PCS'
        CreateItemWithUoM(ItemNo, UoM, QtyPerBaseUoM);

        // [GIVEN] Posted purchase Item Journal Line with 1 'PACK' in SILVER Location
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, FromLocationCode, '', Quantity);
        ItemJournalLine.Validate("Unit of Measure Code", UoM);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Posted Transfer Order from Location SILVER to Location RED with In-Transit Location XXX and 1 'PACK' was posted
        CreateTransferOrderWithItemLocationQtyAndUoM(
          TransferHeader, ItemNo, FromLocationCode, ToLocationCode, InTransitLocationCode, Quantity, UoM);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        // [GIVEN] Released incoming Transfer Order from Location SILVER to Location RED
        FindTransferHeaderByFromToLocation(TransferHeader, FromLocationCode, ToLocationCode);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);

        // [GIVEN] Created Inventory Put-Away with Qty. to Handle (Base) = 1
        CreateInvtPutPickFromTrasferOrder(WarehouseActivityHeader, TransferHeader."No.", "Warehouse Request Source Document"::"Inbound Transfer", true, false);
        UpdateQtyToHandleBaseInWhseActivityLine(WarehouseActivityHeader.Type, WarehouseActivityHeader."No.", Quantity);

        // [WHEN] Post Inventory Put-Away
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, true);

        // [THEN] Transfer Receipt Item Ledger Entry for Location SILVER has Quantity = 1
        VerifyItemLedgerEntryQty(ItemNo, "Item Ledger Document Type"::"Transfer Receipt", ToLocationCode, Quantity);

        // [THEN] Transfer Receipt Item Ledger Entry for Location XXX has Quantity = -1
        VerifyItemLedgerEntryQty(ItemNo, "Item Ledger Document Type"::"Transfer Receipt", InTransitLocationCode, -Quantity);

        // [THEN] Posted Transfer Receipt Line has Quantity (Base) = 1
        VerifyTransferReceiptLineBaseQty(FromLocationCode, ToLocationCode, Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler,AssembleToOrderLinesPageHandler,ReservationMultipleOptionPageHandler')]
    [Scope('OnPrem')]
    procedure ReservedRegisteredPickOfATOComponent()
    var
        Zone: Record Zone;
        Bin: Record Bin;
        AsmItem: Record Item;
        CompItem: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        AsmToOrderNo: Code[20];
        Qty: Decimal;
        QuantityPer: Decimal;
    begin
        // [FEATURE] [Assemble-to-Order] [Reservation]
        // [SCENARIO 349922] Picked and reserved assembly component is excluded correctly from the quantity available for reservation
        Initialize();

        // [GIVEN] Assemble-to-order item "I" assembled from 3 pcs of component item "C"
        QuantityPer := LibraryRandom.RandDec(10, 2);
        CreateATOItemWithComponent(AsmItem, CompItem, QuantityPer);

        // [GIVEN] Post the positive adjustment for 5 pcs of item "C" on location set up for directed put-away and pick
        Qty := LibraryRandom.RandDecInDecimalRange(QuantityPer, 2 * QuantityPer, 2);
        LibraryWarehouse.FindZone(Zone, LocationWhite.Code, LibraryWarehouse.SelectBinType(false, false, true, true), false);
        LibraryWarehouse.FindBin(Bin, LocationWhite.Code, Zone.Code, 1);
        UpdateInventoryUsingWhseAdjustmentPerZone(CompItem, LocationWhite.Code, Zone.Code, Bin.Code, Qty);

        // [GIVEN] Released Sales Order "SO1" for 1 pcs of assembled item "I" with "Q" pcs of item "C" reserved for assembly
        CreateSalesOrder(SalesHeader, LocationWhite.Code, AsmItem."No.", 1);
        LibraryVariableStorage.Enqueue(ReservationAction::AutoReserve);
        ShowAssemblyLinesSalesOrder(SalesHeader);
        AsmToOrderNo := FindAssemblyToOrderNo(AsmItem."No.");
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Create shipment and registered pick for the sales order "SO1"
        CreateWhseShipmentAndPick(SalesHeader);
        FindWhseActivityLine(
            WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take, LocationWhite.Code, AsmToOrderNo);
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::Pick, WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [GIVEN] Sales Order "SO2" for 1 pcs of assembled item "I"
        CreateSalesOrder(SalesHeader, LocationWhite.Code, AsmItem."No.", 1);

        // [WHEN] Open Reservation page for component "C" in Assemble-to-Order Lines for "SO2"
        LibraryVariableStorage.Enqueue(ReservationAction::GetQuantities);
        ShowAssemblyLinesSalesOrder(SalesHeader);

        // [THEN] "Qty. Allocated in Warehouse" = 2
        // [THEN] "Total Available Quantity" = 3
        Assert.AreEqual(QuantityPer, LibraryVariableStorage.DequeueDecimal(), 'Unexpected quantity allocated in warehouse.');
        Assert.AreEqual(Qty - QuantityPer, LibraryVariableStorage.DequeueDecimal(), 'Unexpected total available quantity.');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler,AssembleToOrderLinesPageHandler,ReservationMultipleOptionPageHandler')]
    [Scope('OnPrem')]
    procedure ReservedPickOfATOComponentWithSameBinAsOpenFloor()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Zone: Record Zone;
        Bin: Record Bin;
        AsmItem: Record Item;
        CompItem: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        AsmToOrderNo: Code[20];
        Qty: Decimal;
        QuantityPer: Decimal;
    begin
        // [FEATURE] [Assemble-to-Order] [Reservation]
        // [SCENARIO 349923] Picked and reserved assembly component is excluded correctly from the quantity available for reservation when "Open Shop Floor Bin Code" = "To-Assembly Bin Code" on a Location
        Initialize();

        // [GIVEN] "Open Shop Floor Bin Code" = "To-Assembly Bin Code" on Location "L" set up for directed put-away and pick
        CreateFullWarehouseSetup(Location);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        Location.Validate("Open Shop Floor Bin Code", Location."To-Assembly Bin Code");
        Location.Modify(true);

        // [GIVEN] Assemble-to-order item "I" assembled from 3 pcs of component item "C"
        QuantityPer := LibraryRandom.RandDec(10, 2);
        CreateATOItemWithComponent(AsmItem, CompItem, QuantityPer);

        // [GIVEN] Post the positive adjustment for 5 pcs of item "C" on location "L"
        Qty := LibraryRandom.RandDecInDecimalRange(QuantityPer, 2 * QuantityPer, 2);
        LibraryWarehouse.FindZone(Zone, Location.Code, LibraryWarehouse.SelectBinType(false, false, true, true), false);
        LibraryWarehouse.FindBin(Bin, Location.Code, Zone.Code, 1);
        UpdateInventoryUsingWhseAdjustmentPerZone(CompItem, Location.Code, Zone.Code, Bin.Code, Qty);

        // [GIVEN] Released Sales Order "SO1" for 1 pcs of assembled item "I" with "Q" pcs of item "C" reserved for assembly
        CreateSalesOrder(SalesHeader, Location.Code, AsmItem."No.", 1);
        LibraryVariableStorage.Enqueue(ReservationAction::AutoReserve);
        ShowAssemblyLinesSalesOrder(SalesHeader);
        AsmToOrderNo := FindAssemblyToOrderNo(AsmItem."No.");
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Create shipment and registered pick for the sales order "SO1"
        CreateWhseShipmentAndPick(SalesHeader);
        FindWhseActivityLine(
            WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take, Location.Code, AsmToOrderNo);
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::Pick, WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [GIVEN] Sales Order "SO2" for 1 pcs of assembled item "I"
        CreateSalesOrder(SalesHeader, Location.Code, AsmItem."No.", 1);

        // [WHEN] Open Reservation page for component "C" in Assemble-to-Order Lines for "SO2"
        LibraryVariableStorage.Enqueue(ReservationAction::GetQuantities);
        ShowAssemblyLinesSalesOrder(SalesHeader);

        // [THEN] "Qty. Allocated in Warehouse" = 2
        // [THEN] "Total Available Quantity" = 3
        Assert.AreEqual(QuantityPer, LibraryVariableStorage.DequeueDecimal(), 'Unexpected quantity allocated in warehouse.');
        Assert.AreEqual(Qty - QuantityPer, LibraryVariableStorage.DequeueDecimal(), 'Unexpected total available quantity.');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler,AssembleToOrderLinesPageHandler,ReservationMultipleOptionPageHandler')]
    [Scope('OnPrem')]
    procedure ReservedPickOfATOComponentWithSameBinAsProduction()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Zone: Record Zone;
        Bin: Record Bin;
        AsmItem: Record Item;
        CompItem: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        AsmToOrderNo: Code[20];
        Qty: Decimal;
        QuantityPer: Decimal;
    begin
        // [FEATURE] [Assemble-to-Order] [Reservation]
        // [SCENARIO 349923] Picked and reserved assembly component is excluded correctly from the quantity available for reservation when "Open Shop Floor Bin Code" = "To-Assembly Bin Code" on Location
        Initialize();

        // [GIVEN] "To-Production Bin Code" = "To-Assembly Bin Code" on Location "L" set up for directed put-away and pick
        CreateFullWarehouseSetup(Location);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        Location.Validate(Location."To-Production Bin Code", Location."To-Assembly Bin Code");
        Location.Modify(true);

        // [GIVEN] Assemble-to-order item "I" assembled from 3 pcs of component item "C"
        QuantityPer := LibraryRandom.RandDec(10, 2);
        CreateATOItemWithComponent(AsmItem, CompItem, QuantityPer);

        // [GIVEN] Post the positive adjustment for 5 pcs of item "C" on location "L"
        Qty := LibraryRandom.RandDecInDecimalRange(QuantityPer, 2 * QuantityPer, 2);
        LibraryWarehouse.FindZone(Zone, Location.Code, LibraryWarehouse.SelectBinType(false, false, true, true), false);
        LibraryWarehouse.FindBin(Bin, Location.Code, Zone.Code, 1);
        UpdateInventoryUsingWhseAdjustmentPerZone(CompItem, Location.Code, Zone.Code, Bin.Code, Qty);

        // [GIVEN] Released Sales Order "SO1" for 1 pcs of assembled item "I" with "Q" pcs of item "C" reserved for assembly
        CreateSalesOrder(SalesHeader, Location.Code, AsmItem."No.", 1);
        LibraryVariableStorage.Enqueue(ReservationAction::AutoReserve);
        ShowAssemblyLinesSalesOrder(SalesHeader);
        AsmToOrderNo := FindAssemblyToOrderNo(AsmItem."No.");
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Create shipment and registered pick for the sales order "SO1"
        CreateWhseShipmentAndPick(SalesHeader);
        FindWhseActivityLine(
            WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take, Location.Code, AsmToOrderNo);
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::Pick, WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [GIVEN] Sales Order "SO2" for 1 pcs of assembled item "I"
        CreateSalesOrder(SalesHeader, Location.Code, AsmItem."No.", 1);

        // [WHEN] Open Reservation page for component "C" in Assemble-to-Order Lines for "SO2"
        LibraryVariableStorage.Enqueue(ReservationAction::GetQuantities);
        ShowAssemblyLinesSalesOrder(SalesHeader);

        // [THEN] "Qty. Allocated in Warehouse" = 2
        // [THEN] "Total Available Quantity" = 3
        Assert.AreEqual(QuantityPer, LibraryVariableStorage.DequeueDecimal(), 'Unexpected quantity allocated in warehouse.');
        Assert.AreEqual(Qty - QuantityPer, LibraryVariableStorage.DequeueDecimal(), 'Unexpected total available quantity.');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PickingToBinHavingFilterSymbolInCode()
    var
        Location: Record Location;
        PickBin: Record Bin;
        ShipBin: Record Bin;
        ReceiveBin: Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Bin]
        // [SCENARIO 371983] Picking to a bin having filter symbols ('&','|') in code.
        Initialize();
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Location with bins and required shipment, pick and put-away.
        // [GIVEN] Create two bin codes containing filter symbols, set up them as "Shipment Bin Code" and "Receipt Bin Code" on location.
        LibraryWarehouse.CreateLocationWMS(Location, true, true, true, false, true);
        LibraryWarehouse.CreateBin(PickBin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBin(ShipBin, Location.Code, 'SHIP&-B|N', '', '');
        LibraryWarehouse.CreateBin(ReceiveBin, Location.Code, 'RECEIVE&-B|N', '', '');
        Location.Validate("Shipment Bin Code", ShipBin.Code);
        Location.Validate("Receipt Bin Code", ReceiveBin.Code);
        Location.Modify(true);

        // [GIVEN] Create item, post inventory to a pick bin.
        LibraryInventory.CreateItem(Item);
        UpdateItemInventory(Item."No.", Location.Code, PickBin.Code, Qty);

        // [GIVEN] Create sales order, release it and make a warehouse shipment.
        CreateSalesOrder(SalesHeader, Location.Code, Item."No.", Qty);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [WHEN] Create pick.
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SalesHeader."No.");
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // [THEN] A warehouse pick to the shipment bin has been created successfully.
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField("Bin Code", ShipBin.Code);
    end;

    [Test]
    [HandlerFunctions('CreateWhsePutAwayPickHandler,MessageHandler')]
    procedure SalesOrderWithNonInventoryItemsAndShippingAdviceCompleteForLocationRequiringPick()
    var
        Location: Record Location;
        ItemInventory: Record Item;
        ItemNonInventory: Record Item;
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO]
        Initialize();

        // [GIVEN] Location with pick required.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);

        // [GIVEN] Inventory- and non-inventory item.
        LibraryInventory.CreateItem(ItemInventory);
        UpdateItemInventory(ItemInventory."No.", Location.Code, '', 1);
        LibraryInventory.CreateNonInventoryTypeItem(ItemNonInventory);

        // [GIVEN] A released sales order with inventory- and non-inventory item.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        CreateSalesLine(SalesHeader, ItemNonInventory."No.", Location.Code, 1);
        CreateSalesLine(SalesHeader, ItemInventory."No.", Location.Code, 1);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] A customer with shipping advice set to complete.
        Customer.Get(SalesHeader."Sell-to Customer No.");
        Customer.Validate("Shipping Advice", Customer."Shipping Advice"::Complete);
        Customer.Modify(true);

        // [WHEN] Creating pick.
        Commit();
        SalesHeader.CreateInvtPutAwayPick();

        // [THEN] A warehouse pick for the inventory item has been created.
        WarehouseActivityLine.SetRange("Item No.", ItemInventory."No.");
        WarehouseActivityLine.FindFirst();

        // [THEN] No warehouse pick for the non-inventory item has been created.
        WarehouseActivityLine.SetRange("Item No.", ItemNonInventory."No.");
        Assert.IsTrue(WarehouseActivityLine.IsEmpty(), 'Expected no warehouse activity line for non-inventory item');
    end;

    [Test]
    procedure ShipmentBinIsNotIncludedInQtyInBreakbulk()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        QtyPer: Decimal;
        Qty: Decimal;
    begin
        // [FEATURE] [Breakbulk]
        // [SCENARIO 413644] Shipment bin (and any other bin not in pick zone) is not included in calculation of quantity in breakbulk.
        Initialize();
        QtyPer := LibraryRandom.RandIntInRange(2, 10);
        Qty := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] Item with base unit of measure "PCS" and alternate unit of measure "BOX" = 8 "PCS".
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", QtyPer);

        // [GIVEN] Post 5 "BOX" to inventory.
        // [GIVEN] Sales order for 40 "PCS", create warehouse shipment and pick, register the pick.
        UpdateInventoryUsingWhseJournalWithUoM(Item, LocationWhite.Code, ItemUnitOfMeasure.Code, Qty);
        CreateSalesOrder(SalesHeader, LocationWhite.Code, Item."No.", Qty * QtyPer);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        CreateWhseShipmentAndPick(SalesHeader);
        RegisterWarehouseActivity(SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);

        // [GIVEN] Post 5 "BOX" to inventory.
        // [GIVEN] Sales order for 40 "PCS", create warehouse shipment and pick, do not register the pick.
        UpdateInventoryUsingWhseJournalWithUoM(Item, LocationWhite.Code, ItemUnitOfMeasure.Code, Qty);
        CreateSalesOrder(SalesHeader, LocationWhite.Code, Item."No.", Qty * QtyPer);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        CreateWhseShipmentAndPick(SalesHeader);

        // [GIVEN] Post 5 "BOX" to inventory.
        // [GIVEN] Sales order for 40 "PCS".
        UpdateInventoryUsingWhseJournalWithUoM(Item, LocationWhite.Code, ItemUnitOfMeasure.Code, Qty);
        CreateSalesOrder(SalesHeader, LocationWhite.Code, Item."No.", Qty * QtyPer);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN] Create warehouse shipment and pick for the last sales order.
        CreateWhseShipmentAndPick(SalesHeader);

        // [THEN] Warehouse pick for 40 "PCS" is created.
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take,
          LocationWhite.Code, SalesHeader."No.");
        WarehouseActivityLine.SetRange("Breakbulk No.", 0);
        WarehouseActivityLine.CalcSums("Qty. (Base)");
        WarehouseActivityLine.TestField("Qty. (Base)", Qty * QtyPer);

        // [THEN] The pick can be successfully registered.
        RegisterWarehouseActivity(SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,PickSelectionModalPageHandler')]
    [Scope('OnPrem')]
    procedure CannotChangeReleasedProductionOrderStatusWhenWhseWorksheetLinesExist()
    var
        ProductionOrder: Record "Production Order";
        ProductionBOMHeader: Record "Production BOM Header";
        ParentItem: Record Item;
        ChildItem: Record Item;
        Quantity: Decimal;
        PickWorksheetPage: TestPage "Pick Worksheet";
    begin
        isInitialized := false;
        Initialize();

        // [GIVEN] Refreshed Production Order.
        LibraryInventory.CreateItem(ParentItem);
        LibraryInventory.CreateItem(ChildItem);
        Quantity := LibraryRandom.RandInt(10);
        UpdateItemInventory(ChildItem."No.", LocationWhite.Code, '', Quantity);

        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, ChildItem."No.", Quantity);
        ParentItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ParentItem.Modify(true);

        CreateProdOrder(
            ProductionOrder,
            ProductionOrder.Status::Released,
            ProductionOrder."Source Type"::Item,
            ParentItem."No.",
            LocationWhite.Code,
            Quantity
        );
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        CreateRefreshedProductionOrder(ProductionOrder, LocationWhite);

        // [WHEN] Pick Worksheet is used to get the source documents
        PickWorksheetPage.OpenEdit();
        PickWorksheetPage."Get Warehouse Documents".Invoke();
        PickWorksheetPage.Close();

        // [WHEN] Changing the status to finished.
        asserterror LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [THEN] An error is thrown.
        Assert.ExpectedError('Status must not be changed when a Whse. Worksheet Line');
    end;

    [Test]
    procedure ReservedQtyOnInventoryCalculatedCorrectlyForNonDPnPLocation()
    var
        Item: Record Item;
        Bin: Record Bin;
        BinType: Record "Bin Type";
        TempBinType: Record "Bin Type" temporary;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemTrackingSetup: Record "Item Tracking Setup";
        CreatePick: Codeunit "Create Pick";
        ReservedQty: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 437213] "Qty. Reserved on Inventory" used for available qty. for picking calculation must not depend on bin types for non-DPnP locations.
        Initialize();
        ReservedQty := LibraryRandom.RandIntInRange(10, 20);

        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.FindBin(Bin, LocationOrange.Code, '', 1);

        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, Item."No.", LocationOrange.Code, Bin.Code, LibraryRandom.RandIntInRange(50, 100));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", ReservedQty, LocationOrange.Code, WorkDate());
        LibrarySales.AutoReserveSalesLine(SalesLine);

        CutPasteBinTypes(TempBinType, BinType);

        Assert.AreEqual(
          ReservedQty,
          CreatePick.CalcReservedQtyOnInventory(Item."No.", LocationOrange.Code, '', ItemTrackingSetup), '');

        // Tear down
        CutPasteBinTypes(BinType, TempBinType);
    end;

    [Test]
    [HandlerFunctions('PickSelectionModalPageHandler,InsertNewProdOrderRoutingLine_ProdOrderRoutingModalPageHandler')]
    [Scope('OnPrem')]
    procedure S458884_CanChangeReleasedProductionOrderComponentWhenWhseWorksheetLinesExist()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProductionBOMHeader: Record "Production BOM Header";
        Quantity: Decimal;
        PickWorksheetPage: TestPage "Pick Worksheet";
        ReleasedProductionOrder: TestPage "Released Production Order";
    begin
        // [FEATURE] [UT] [Released Production Order] [Pick Worksheet] [Prod. Order Routing]
        // [SCENARIO 458884] Update "Released Production Order" Routing with Setup Time which changes Production Order Component Due Date.
        isInitialized := false;
        Initialize();

        // [GIVEN] Create Parent and Child Items. Parent Item is with Production BOM and Routing
        LibraryInventory.CreateItem(ParentItem);
        LibraryInventory.CreateItem(ChildItem);
        Quantity := LibraryRandom.RandInt(10);
        UpdateItemInventory(ChildItem."No.", LocationWhite.Code, '', Quantity);

        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, ChildItem."No.", Quantity);
        ParentItem.Validate("Replenishment System", ParentItem."Replenishment System"::"Prod. Order");
        ParentItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ParentItem.Validate("Routing No.", CreateRouting());
        ParentItem.Modify(true);

        // [GIVEN] Create and refresh Released Production Order
        CreateProdOrder(
            ProductionOrder,
            ProductionOrder.Status::Released,
            ProductionOrder."Source Type"::Item,
            ParentItem."No.",
            LocationWhite.Code,
            Quantity
        );
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [GIVEN] Pick Worksheet is used to get the source documents, without creating Warehouse Pick
        PickWorksheetPage.OpenEdit();
        PickWorksheetPage."Get Warehouse Documents".Invoke();
        PickWorksheetPage.Close();

        // [WHEN] Insert new Routing Line with Setup Time. Uses Handler InsertNewProdOrderRoutingLine_ProdOrderRoutingModalPageHandler
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);
        ReleasedProductionOrder.ProdOrderLines.Routing.Invoke();

        // [THEN] No error is thrown
    end;

    [Test]
    [HandlerFunctions('CreateWhsePutAwayPickHandler,MessageHandler')]
    procedure InventoryPickDocumentShouldBeCreatedWhenSalesOrderContainInventoriableAndNonInventoriableItem()
    var
        Bin: Record Bin;
        Location: Record Location;
        Customer: Record Customer;
        ItemInventory, ItemNonInventory : Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO 494571] Inventory Pick Document should be created for Inventory item when Sales Order contain inventoriable and Non-inventoriable item.
        Initialize();

        // [GIVEN] Create a warehouse location.
        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, true, false);

        // [GIVEN] Create a bin.
        LibraryWarehouse.CreateBin(Bin, Location.Code, '', '', '');

        // [GIVEN] Create a customer with shipping advice.
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Shipping Advice", Customer."Shipping Advice"::Complete);
        Customer.Modify(true);

        // [GIVEN] Create an inventory item.
        LibraryInventory.CreateItem(ItemInventory);

        // [GIVEN] Post inventory for an inventoriable item.
        UpdateItemInventory(ItemInventory."No.", Location.Code, Bin.Code, LibraryRandom.RandInt(100));

        // [GIVEN] Create a non-inventory item.
        LibraryInventory.CreateNonInventoryTypeItem(ItemNonInventory);

        // [GIVEN] Create a sales order for both items and release the document.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        CreateSalesLine(SalesHeader, ItemNonInventory."No.", Location.Code, 1);
        CreateSalesLine(SalesHeader, ItemInventory."No.", Location.Code, 1);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN] Create an inventory put-away document.
        Commit();
        SalesHeader.CreateInvtPutAwayPick();

        // [VERIFY] Verify the warehouse activity line is created for inventoriable item.
        WarehouseActivityLine.SetRange("Item No.", ItemInventory."No.");
        Assert.RecordCount(WarehouseActivityLine, 1);

        // [VERIFY] Verify the warehouse activity line is not created for non-inventoriable item.
        WarehouseActivityLine.SetRange("Item No.", ItemNonInventory."No.");
        Assert.RecordCount(WarehouseActivityLine, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CheckPurchReturnOrderReturnQtyShippedWhenNegativeQtyAndPartialPostingOfInventoryPutAway()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        LocationCode: Code[10];
        PartialQuantity: Decimal;
    begin
        // [SCENARIO 565208] Verify the 'Purchase Return Order Quantity to Ship' field when using a negative quantity and partial posting of the inventory put-away.
        Initialize();

        // [GIVEN] Create Location.
        LocationCode := CreateLocationWithRequirePickPutAway(true, true);

        // [GIVEN] Create a partial purchase return order with a negative quantity.
        PartialQuantity := CreatePurchaseReturnOrderAndPartialPost(PurchaseHeader, PurchaseLine, LocationCode);

        // [GIVEN] Create inventory put-away from the purchase return order.
        CreateInvtPutPickFromPurchDoc(WarehouseActivityHeader, PurchaseHeader, "Warehouse Request Source Document"::"Purchase Return Order");

        // [GIVEN] Update the 'Quantity to Handle' in the warehouse activity line.
        UpdateQtyToHandleInWhseActivityLine(WarehouseActivityHeader.Type, WarehouseActivityHeader."No.", PartialQuantity);

        // [WHEN] Received the inventory put-away document.
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] Verify the return quantity shipped in the purchase return order.
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        Assert.AreEqual(
            PurchaseLine."Return Qty. Shipped", -PartialQuantity,
            StrSubstNo(ReturnQtyMismatchErr, PurchaseLine."Return Qty. Shipped", PurchaseLine.TableCaption));
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('CreateInvtPutAwayPickRequestPageHandler,MessageHandler')]
    procedure InventoryPickRoundingCausesResidualQuantity()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        UnitOfMeasure: Record "Unit of Measure";
        Bin: Record Bin;
        TotalPickedQty: Decimal;
        QtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
        OrderQuantity: Decimal;
        BinCode: Code[20];
    begin
        // [SCENARIO 579500] Inventory pick rounding causes residual quantity When picking items with non-integer UOM conversion and very small 
        // Quantity Rounding Precision, the pick process may result in rounding residuals
        Initialize();

        // [GIVEN] Setup variables for rounding test with random values within problematic ranges
        SetStaticValues579500(QtyPerUOM, QtyRoundingPrecision, OrderQuantity);

        // [GIVEN] Generate random bin code
        BinCode := LibraryUtility.GenerateRandomCode(SalesLine.FieldNo("Bin Code"), Database::"Sales Line"); // Random bin code

        // [GIVEN] Create item with specific UOM configuration for rounding test and LOT tracking with expiration dates
        LibraryInventory.CreateItem(Item);
        SetupItemTrackingWithExpirationDates(Item);

        // [GIVEN] Add secondary UOM with problematic conversion factor and very small rounding precision
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, QtyPerUOM);
        ItemUnitOfMeasure.Validate("Qty. Rounding Precision", QtyRoundingPrecision);
        ItemUnitOfMeasure.Modify(true);

        // [GIVEN] Set Sales Unit of Measure to the secondary UOM
        Item.Validate("Sales Unit of Measure", UnitOfMeasure.Code);
        Item.Modify(true);

        // [GIVEN] Setup Location with Require Pick = YES and Pick According to FEFO = Yes
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Pick According to FEFO", true);
        Location.Modify(true);

        // [GIVEN] Add Warehouse Employee for location
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Create bin for the location
        LibraryWarehouse.CreateBin(Bin, Location.Code, BinCode, '', '');

        // [GIVEN] Add inventory for the item (sufficient for order quantity)
        CreateInventoryForLotAndExpiry579500(Item."No.", Location.Code, Bin.Code);

        // [GIVEN] Create Customer
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create Sales Order with random quantity 
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", OrderQuantity);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);

        // [GIVEN] Release Sales Order
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GiVEN] Create Inventory Pick from Sales Order
        Commit();
        SalesHeader.CreateInvtPutAwayPick();

        // [WHEN] autofill Qty. to Handle, post the pick
        PostInventoryActivity(WarehouseActivityHeader."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Pick");

        // [GIVEN] Get total picked quantity from Item Ledger Entries
        GetTotalPickedQuantity(Item."No.", Location.Code, QtyPerUOM, TotalPickedQty);

        // [THEN] Assert that picked quantity equals expected with tolerance for rounding
        Assert.AreNearlyEqual(OrderQuantity, TotalPickedQty, QtyRoundingPrecision * 10,
            StrSubstNo(PickQuantityErr, OrderQuantity, UnitOfMeasure.Code, TotalPickedQty));

        // [THEN] Validate that no residual quantity remains (no second pick is required) Check that sales line is fully shipped
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        Assert.AreEqual(SalesLine.Quantity, SalesLine."Quantity Shipped", ShipQtyErr);
    end;

    local procedure Initialize()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Warehouse Pick");
        WarehouseActivityLine.DeleteAll();
        Clear(GlobalItemNo);
        LibraryVariableStorage.Clear();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Warehouse Pick");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();
        NoSeriesSetup();
        CreateLocationSetup();
        ItemJournalSetup();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Warehouse Pick");
    end;

    local procedure CreateItemJournalLineWithLocationQtyAndUoM(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; UoM: Code[10])
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, '', Quantity);
        ItemJournalLine.Validate("Unit of Measure Code", UoM);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateInvtPutPickFromSalesDoc(var WarehouseActivityHeader: Record "Warehouse Activity Header"; SalesHeader: Record "Sales Header"; SourceDocument: Enum "Warehouse Request Source Document")
    begin
        LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);
        FindWhseActivityHeaderBySourceDocAndNo(WarehouseActivityHeader, SourceDocument, SalesHeader."No.");
    end;

    local procedure CreateInvtPutPickFromPurchDoc(var WarehouseActivityHeader: Record "Warehouse Activity Header"; PurchaseHeader: Record "Purchase Header"; SourceDocument: Enum "Warehouse Request Source Document")
    begin
        LibraryWarehouse.CreateInvtPutPickPurchaseOrder(PurchaseHeader);
        FindWhseActivityHeaderBySourceDocAndNo(WarehouseActivityHeader, SourceDocument, PurchaseHeader."No.");
    end;

    local procedure CreateInvtPutPickFromTrasferOrder(var WarehouseActivityHeader: Record "Warehouse Activity Header"; SourceNo: Code[20]; SourceDocument: Enum "Warehouse Request Source Document"; PutAway: Boolean; Pick: Boolean)
    begin
        LibraryWarehouse.CreateInvtPutPickMovement(SourceDocument, SourceNo, PutAway, Pick, false);
        FindWhseActivityHeaderBySourceDocAndNo(WarehouseActivityHeader, SourceDocument, SourceNo);
    end;

    local procedure CreateTransferOrderWithItemLocationQtyAndUoM(var TransferHeader: Record "Transfer Header"; ItemNo: Code[20]; FromLocationCode: Code[10]; ToLocationCode: Code[10]; InTransitLocationCode: Code[10]; Quantity: Decimal; UoM: Code[10])
    var
        TransferLine: Record "Transfer Line";
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, InTransitLocationCode);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        TransferLine.Validate("Unit of Measure Code", UoM);
        TransferLine.Modify(true);
        TransferLine.TestField(Quantity, 1);
        TransferLine.TestField("Quantity (Base)", 3);
    end;

    local procedure CreateTransferLocationsWithRequirePickPutAway(var FromLocationCode: Code[10]; var ToLocationCode: Code[10]; var InTransitLocation: Code[10])
    var
        Location: Record Location;
    begin
        FromLocationCode := CreateLocationWithRequirePickPutAway(true, false);
        ToLocationCode := CreateLocationWithRequirePickPutAway(false, true);
        LibraryWarehouse.CreateInTransitLocation(Location);
        InTransitLocation := Location.Code;
    end;

    local procedure CreateItemWithUoM(var ItemNo: Code[20]; var UoM: Code[10]; QtyPerBaseUoM: Integer)
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        LibraryInventory.CreateItem(Item);
        ItemNo := Item."No.";

        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        UoM := UnitOfMeasure.Code;
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, ItemNo, UoM, QtyPerBaseUoM);
    end;

    local procedure CreateSalesDocWithItemLocationQtyAndUoM(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; UoM: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSimpleItemSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item);
        SalesLine.Validate("No.", ItemNo);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate(Quantity, Quantity);
        SalesLine.Validate("Unit of Measure Code", UoM);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchaseDocWithItemLocationQtyAndUoM(var PurchaseHeader: Record "Purchase Header"; DocType: Enum "Purchase Document Type"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; UoM: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocType, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLineSimple(PurchaseLine, PurchaseHeader);
        PurchaseLine.Validate(Type, PurchaseLine.Type::Item);
        PurchaseLine.Validate("No.", ItemNo);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate(Quantity, Quantity);
        PurchaseLine.Validate("Unit of Measure Code", UoM);
        PurchaseLine.Modify(true);
    end;

    local procedure CutPasteBinTypes(var ToBinType: Record "Bin Type"; var FromBinType: Record "Bin Type")
    begin
        ToBinType.DeleteAll();
        if FromBinType.FindSet() then
            repeat
                ToBinType := FromBinType;
                FromBinType.Delete();
                ToBinType.Insert();
            until FromBinType.Next() = 0;
    end;

    local procedure NoSeriesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        WarehouseSetup: Record "Warehouse Setup";
    begin
        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);

        SalesSetup.Get();
        SalesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Validate("Posted Shipment Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Modify(true);

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Posted Receipt Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure ItemJournalSetup()
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
    end;

    local procedure CreateLocationSetup()
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.DeleteAll(true);
        CreateFullWarehouseSetup(LocationWhite);  // Location: White.
        LibraryWarehouse.CreateLocationWMS(LocationBlue, false, false, false, false, false);  // Location: Blue.
        LibraryWarehouse.CreateLocationWMS(LocationYellow, false, false, true, false, true);  // Location: Yellow. Require Shipment TRUE and Require Pick TRUE.
        LibraryWarehouse.CreateLocationWMS(LocationOrange, true, true, true, true, true);  // Location: Orange. Bin Mandatory True.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite.Code, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationOrange.Code, false);

        LibraryWarehouse.CreateNumberOfBins(LocationOrange.Code, '', '', LibraryRandom.RandInt(5) + 3, false);  // Value Required.
    end;

    local procedure CreateLocationNotRequirePick(var Location: Record Location)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Require Receive", true);
        Location.Validate("Require Shipment", true);
        Location.Validate("Require Pick", false);
        Location.Validate("Prod. Output Whse. Handling", "Prod. Output Whse. Handling"::"Inventory Put-away");
        Location.Validate("Prod. Consump. Whse. Handling", "Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)");
        Location.Modify(true);

        Location.Validate("Open Shop Floor Bin Code", CreateBinCode(Location.Code));
        Location.Validate("To-Production Bin Code", CreateBinCode(Location.Code));
        Location.Validate("From-Production Bin Code", CreateBinCode(Location.Code));
        Location.Validate("Receipt Bin Code", CreateBinCode(Location.Code));
        Location.Validate("Shipment Bin Code", CreateBinCode(Location.Code));

        Location.Modify(true);

        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
    end;

    local procedure CreateLocationWithRequirePickPutAway(RequirePick: Boolean; RequirePutAway: Boolean): Code[10]
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Require Pick", RequirePick);
        Location.Validate("Require Put-away", RequirePutAway);
        if RequirePutAway then
            Location.Validate("Always Create Put-away Line", true);
        Location.Modify(true);
        exit(Location.Code);
    end;

    local procedure CreateBinCode(LocationCode: Code[10]): Code[20]
    var
        Bin: Record Bin;
    begin
        LibraryWarehouse.CreateBin(Bin, LocationCode, LibraryUtility.GenerateGUID(), '', '');
        exit(Bin.Code);
    end;

    [Normal]
    local procedure CreateFullWarehouseSetup(var Location: Record Location)
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);  // Value used for number of bin per zone.
    end;

    local procedure UpdateQtyToHandleBaseInWhseActivityLine(ActivityType: Enum "Warehouse Activity Type"; WarehouseActivityHeaderNo: Code[20]; Quantity: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWhseActivityLineByActivityHeader(WarehouseActivityLine, ActivityType, WarehouseActivityHeaderNo);
        WarehouseActivityLine.Validate("Qty. to Handle (Base)", Quantity);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure UpdateQtyToHandleInWhseActivityLine(WarehouseActivityHeaderType: Enum "Warehouse Activity Type"; WarehouseActivityHeaderNo: Code[20]; Quantity: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWhseActivityLineByActivityHeader(WarehouseActivityLine, WarehouseActivityHeaderType, WarehouseActivityHeaderNo);
        WarehouseActivityLine.Validate("Qty. to Handle", Quantity);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure UpdateLocationForAlwaysCreatePickLine(var Location: Record Location; AlwaysCreatePickLine: Boolean)
    begin
        Location.Validate("Always Create Pick Line", AlwaysCreatePickLine);
        Location.Modify(true);
    end;

    local procedure UpdateInventoryUsingWhseAdjustmentPerZone(Item: Record Item; LocationCode: Code[10]; ZoneCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        LibraryWarehouse.WarehouseJournalSetup(LocationCode, WarehouseJournalTemplate, WarehouseJournalBatch);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationCode, ZoneCode, BinCode,
          WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
        CalculateAndPostWhseAdjustment(Item, LocationCode);
    end;

    local procedure CreateItemAndUpdateInventoryWithZone(var Item: Record Item; var Zone: Record Zone; var Bin: Record Bin; Quantity: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        FindZone(Zone, LocationWhite.Code);
        LibraryWarehouse.FindBin(Bin, LocationWhite.Code, Zone.Code, 2);  // Find Bin of Index 2 in the Zone.
        UpdateInventoryUsingWhseAdjustmentPerZone(Item, LocationWhite.Code, Zone.Code, Bin.Code, Quantity);  // For large Quantity.
    end;

    local procedure UpdateInventoryUsingWhseJournalWithUoM(Item: Record Item; LocationCode: Code[10]; UnitOfMeasureCode: Code[10]; Quantity: Decimal)
    var
        Zone: Record Zone;
        Bin: Record Bin;
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        LibraryWarehouse.FindZone(Zone, LocationCode, LibraryWarehouse.SelectBinType(false, false, true, true), false);
        LibraryWarehouse.FindBin(Bin, LocationCode, Zone.Code, 1);
        LibraryWarehouse.WarehouseJournalSetup(LocationCode, WarehouseJournalTemplate, WarehouseJournalBatch);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name,
          LocationCode, Zone.Code, Bin.Code,
          WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
        WarehouseJournalLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        WarehouseJournalLine.Modify(true);
        CalculateAndPostWhseAdjustment(Item, LocationCode);
    end;

    local procedure CreateATOItemWithComponent(var AsmItem: Record Item; var CompItem: Record Item; QuantityPer: Decimal)
    var
        BOMComponent: Record "BOM Component";
    begin
        LibraryInventory.CreateItem(AsmItem);
        AsmItem.Validate("Replenishment System", AsmItem."Replenishment System"::Assembly);
        AsmItem.Validate("Assembly Policy", AsmItem."Assembly Policy"::"Assemble-to-Order");
        AsmItem.Modify(true);
        LibraryInventory.CreateItem(CompItem);
        LibraryInventory.CreateBOMComponent(
          BOMComponent, AsmItem."No.", BOMComponent.Type::Item, CompItem."No.",
          QuantityPer, CompItem."Base Unit of Measure");
    end;

    local procedure CreateEmptyTransferLine(TransferHeader: Record "Transfer Header")
    var
        TransferLine: Record "Transfer Line";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(TransferLine);
        TransferLine.Validate("Document No.", TransferHeader."No.");
        TransferLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, TransferLine.FieldNo("Line No.")));
        TransferLine.Validate(Description, LibraryUtility.GenerateGUID());
        TransferLine.Insert(true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', ItemNo, Quantity, LocationCode, 0D);
    end;

    local procedure CreateAndReleasePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        CreatePurchaseOrder(PurchaseHeader, LocationCode, ItemNo, Quantity);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndPostWhseReceiptFromPO(var PurchaseHeader: Record "Purchase Header")
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
    end;

    local procedure CreateAndPostPurchaseOrder(ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseOrder(PurchaseHeader, '', ItemNo, Quantity);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreatePutAwayForPurchaseOrder(LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreateAndReleasePurchaseOrder(PurchaseHeader, LocationCode, ItemNo, Quantity);
        CreateAndPostWhseReceiptFromPO(PurchaseHeader);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        // Random values used are not important for test.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        CreateSalesLine(SalesHeader, ItemNo, LocationCode, Quantity)
    end;

    local procedure CreateSalesLine(SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateReleaseAndReserveSalesOrder(var SalesHeader: Record "Sales Header"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal; Reserve: Boolean)
    begin
        CreateSalesOrder(SalesHeader, LocationCode, ItemNo, Quantity);
        if Reserve then
            ReserveFromSalesOrder(SalesHeader."No.");
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateTransferOrderWithEmptyLine(var TransferHeader: Record "Transfer Header"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; InTransitLocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        TransferLine: Record "Transfer Line";
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, InTransitLocationCode);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        CreateEmptyTransferLine(TransferHeader);
    end;

    local procedure CreateRefreshedProductionOrder(var ProductionOrder: Record "Production Order"; Location: Record Location)
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        Quantity: Decimal;
    begin
        LibraryInventory.CreateItem(ParentItem);
        LibraryInventory.CreateItem(ChildItem);
        Quantity := LibraryRandom.RandInt(10);
        UpdateItemInventory(ChildItem."No.", Location.Code, Location."Receipt Bin Code", Quantity);

        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, ChildItem."No.", Quantity);
        ParentItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ParentItem.Modify(true);
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder."Source Type"::Item, ParentItem."No.", Location.Code, Quantity);
    end;

    local procedure CreateAndRefreshProdOrder(var ProductionOrder: Record "Production Order"; SourceType: Enum "Prod. Order Source Type"; SourceNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        CreateProdOrder(ProductionOrder, ProductionOrder.Status::Released, SourceType, SourceNo, LocationCode, Quantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateProdOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceType: Enum "Prod. Order Source Type"; SourceNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, SourceType, SourceNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
    end;

    local procedure GetQtyRoundingPrecision(): Decimal
    var
        UnitOfMeasureManagement: Codeunit "Unit of Measure Management";
    begin
        exit(UnitOfMeasureManagement.QtyRndPrecision());
    end;

    local procedure FindWhseActivityHeaderBySourceDocAndNo(var WarehouseActivityHeader: Record "Warehouse Activity Header"; SourceDoc: Enum "Warehouse Request Source Document"; SourceNo: Code[20])
    begin
        WarehouseActivityHeader.SetRange("Source Document", SourceDoc);
        WarehouseActivityHeader.SetRange("Source No.", SourceNo);
        WarehouseActivityHeader.FindFirst();
    end;

    local procedure FindWhseActivityLineByActivityHeader(var WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseActivityHeaderType: Enum "Warehouse Activity Type"; WarehouseActivityHeaderNo: Code[20])
    begin
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeaderType);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeaderNo);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure FindTransferHeaderByFromToLocation(var TransferHeader: Record "Transfer Header"; FromLocationCode: Code[10]; ToLocationCode: Code[10])
    begin
        TransferHeader.SetRange("Transfer-from Code", FromLocationCode);
        TransferHeader.SetRange("Transfer-to Code", ToLocationCode);
        TransferHeader.FindFirst();
    end;

    local procedure FilterOnWhseActivityLine(SourceNo: Code[20]; ActionType: Enum "Warehouse Action Type")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure FindAssemblyToOrderNo(ItemNo: Code[20]): Code[20]
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        AssemblyHeader.SetRange("Item No.", ItemNo);
        AssemblyHeader.FindFirst();
        exit(AssemblyHeader."No.");
    end;

    local procedure FindWhseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ActivityType: Enum "Warehouse Activity Type"; ActionType: Enum "Warehouse Action Type"; LocationCode: Code[10]; SourceNo: Code[20])
    begin
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.SetRange("No.", FindWarehouseActivityNo(SourceNo, ActivityType));
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.FindSet();
    end;

    local procedure ReserveFromSalesOrder(No: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", No);
        SalesOrder.SalesLines.Reserve.Invoke();  // Open Page - Reservation on ReservationPageHandler.
        SalesOrder.Close();
    end;

    local procedure ShowAssemblyLinesSalesOrder(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLine.ShowAsmToOrderLines();
    end;

    local procedure FilterWarehouseShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SourceNo: Code[20])
    begin
        WarehouseShipmentLine.SetRange("Source Document", WarehouseShipmentLine."Source Document"::"Sales Order");
        WarehouseShipmentLine.SetRange("Source No.", SourceNo);
        WarehouseShipmentLine.SetRange("Source Type", DATABASE::"Sales Line");
    end;

    local procedure FindWarehouseShipmentHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SourceNo: Code[20])
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        FilterWarehouseShipmentLine(WarehouseShipmentLine, SourceNo);
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
    end;

    local procedure PostWarehouseReceipt(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        WarehouseReceiptHeader.Get(FindWarehouseReceiptNo(SourceDocument, SourceNo));
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure FindWarehouseActivityNo(SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"): Code[20]
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindFirst();
        exit(WarehouseActivityLine."No.");
    end;

    local procedure FindWarehouseReceiptNo(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]): Code[20]
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WarehouseReceiptLine.SetRange("Source Document", SourceDocument);
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.FindFirst();
        exit(WarehouseReceiptLine."No.");
    end;

    local procedure FindZone(var Zone: Record Zone; LocationCode: Code[10])
    begin
        Zone.SetRange("Location Code", LocationCode);
        Zone.FindFirst();
    end;

    local procedure UpdateQuantityToHandleOnActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20]; LocationCode: Code[10]; QtyToHandle: Decimal)
    begin
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.SetRange("No.", FindWarehouseActivityNo(SourceNo, WarehouseActivityLine."Activity Type"::Pick));
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.Validate("Qty. to Handle", QtyToHandle);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure UpdateItemInventory(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
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
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure UpdateItemForPhysicalInventoryCountingPeriod(var Item: Record Item)
    var
        PhysInvtCountingPeriod: Record "Phys. Invt. Counting Period";
    begin
        LibraryInventory.CreatePhysicalInventoryCountingPeriod(PhysInvtCountingPeriod);
        Item.Validate("Phys Invt Counting Period Code", PhysInvtCountingPeriod.Code);
        Item.Modify(true);
    end;

    local procedure CalculateAndPostWhseAdjustment(Item: Record Item; LocationCode: Code[10])
    begin
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationCode, true);
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure UpdateBinOnActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20]; BinCode: Code[20]; ActionType: Enum "Warehouse Action Type")
    begin
        FindWhseActivityLine(WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, ActionType, LocationWhite.Code, SourceNo);
        WarehouseActivityLine.Validate("Bin Code", BinCode);
        WarehouseActivityLine.Modify(true);
    end;

    [Normal]
    local procedure RegisterWarehouseActivity(SourceNo: Code[20]; Type: Enum "Warehouse Activity Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        WarehouseActivityHeader.SetRange(Type, Type);
        WarehouseActivityHeader.SetRange("No.", FindWarehouseActivityNo(SourceNo, Type));
        WarehouseActivityHeader.FindFirst();
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure OpenInternalMovementPage(var InternalMovement: TestPage "Internal Movement"; No: Code[20])
    begin
        InternalMovement.OpenEdit();
        InternalMovement.FILTER.SetFilter("No.", No);
    end;

    local procedure CreateWhseShipmentAndPick(var SalesHeader: Record "Sales Header")
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SalesHeader."No.");
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
    end;

    local procedure CreateInternalMovement(var InternalMovementHeader: Record "Internal Movement Header"; LocationCode: Code[10]; ItemNo: Code[20]; BinCode: Code[20]; Quantity: Decimal)
    var
        InternalMovementLine: Record "Internal Movement Line";
    begin
        LibraryWarehouse.CreateInternalMovementHeader(InternalMovementHeader, LocationCode, '');
        LibraryWarehouse.CreateInternalMovementLine(InternalMovementHeader, InternalMovementLine, ItemNo, BinCode, '', Quantity);
    end;

    local procedure SelectItemJournalLineForLocation(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.SetRange("Location Code", LocationCode);
        ItemJournalLine.FindFirst();
    end;

    local procedure PostInventoryActivity(ActivityType: Enum "Warehouse Activity Type"; ActivityNo: Code[20])
    var
        WhseActivHeader: Record "Warehouse Activity Header";
    begin
        WhseActivHeader.Get(ActivityType, ActivityNo);
        LibraryWarehouse.PostInventoryActivity(WhseActivHeader, false);
    end;

    local procedure PostItemJournalLine(ItemNo: Code[20]; LocationCode: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        SelectItemJournalLineForLocation(ItemJournalLine, ItemNo, LocationCode);
        CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Batch", ItemJournalLine);
    end;

    local procedure CreateWhseJournal(Item: Record Item; LocationCode: Code[10]; ZoneCode: Code[10]; BinCode: Code[20])
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        LibraryWarehouse.WarehouseJournalSetup(LocationCode, WarehouseJournalTemplate, WarehouseJournalBatch);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationCode, ZoneCode, BinCode,
          WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandDec(10, 2));
    end;

    local procedure CalculateWhseAdjustmentForMultipleItems(ItemJournalBatch: Record "Item Journal Batch"; ItemNo: Code[20]; ItemNo2: Code[20])
    var
        Item: Record Item;
    begin
        Item.SetFilter("No.", '%1|%2', ItemNo, ItemNo2);
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
    end;

    local procedure GetSetDirectedBinMandatoryAndPutAwayAndPickOnLocation(var BinMandatoryOldValue: Boolean; var DirectedPutAwayAndPickOldValue: Boolean; LocationCode: Code[10]; BinMandatoryNewValue: Boolean; DirectedPutAwayAndPickNewValue: Boolean)
    var
        Location: Record Location;
    begin
        Location.Get(LocationCode);
        BinMandatoryOldValue := Location."Bin Mandatory";
        DirectedPutAwayAndPickOldValue := Location."Directed Put-away and Pick";
        Location.Validate("Bin Mandatory", BinMandatoryNewValue);
        Location.Validate("Directed Put-away and Pick", DirectedPutAwayAndPickNewValue);
        Location.Modify(true);
    end;

    local procedure VerifyItemLedgerEntryQty(ItemNo: Code[20]; DocType: Enum "Item Ledger Document Type"; LocationCode: Code[10]; Quantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Document Type", DocType);
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
        ItemLedgerEntry.FindLast();
        ItemLedgerEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifySalesShipmentBaseQty(CustNo: Code[20]; QtyBase: Decimal)
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentLine.SetRange("Sell-to Customer No.", CustNo);
        SalesShipmentLine.FindFirst();
        SalesShipmentLine.TestField("Quantity (Base)", QtyBase);
        SalesShipmentLine.TestField("Qty. Invoiced (Base)", QtyBase);
    end;

    local procedure VerifyPurchRcptLineBaseQty(VendorNo: Code[20]; QtyBase: Decimal)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange("Buy-from Vendor No.", VendorNo);
        PurchRcptLine.FindFirst();
        PurchRcptLine.TestField("Quantity (Base)", QtyBase);
        PurchRcptLine.TestField("Qty. Invoiced (Base)", QtyBase);
    end;

    local procedure VerifyReturnShipmentLineBaseQty(VendorNo: Code[20]; QtyBase: Decimal)
    var
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        ReturnShipmentLine.SetRange("Buy-from Vendor No.", VendorNo);
        ReturnShipmentLine.FindFirst();
        ReturnShipmentLine.TestField("Quantity (Base)", QtyBase);
        ReturnShipmentLine.TestField("Qty. Invoiced (Base)", QtyBase);
    end;

    local procedure VerifyReturnReceiptLineBaseQty(CustNo: Code[20]; QtyBase: Decimal)
    var
        ReturnReceiptLine: Record "Return Receipt Line";
    begin
        ReturnReceiptLine.SetRange("Sell-to Customer No.", CustNo);
        ReturnReceiptLine.FindFirst();
        ReturnReceiptLine.TestField("Quantity (Base)", QtyBase);
        ReturnReceiptLine.TestField("Qty. Invoiced (Base)", QtyBase);
    end;

    local procedure VerifyTransferShipmentLineBaseQty(FromLocationCode: Code[10]; ToLocationCode: Code[10]; Quantity: Decimal)
    var
        TransferShipmentLine: Record "Transfer Shipment Line";
    begin
        TransferShipmentLine.SetRange("Transfer-from Code", FromLocationCode);
        TransferShipmentLine.SetRange("Transfer-to Code", ToLocationCode);
        TransferShipmentLine.FindFirst();
        TransferShipmentLine.TestField("Quantity (Base)", Quantity);
    end;

    local procedure VerifyTransferReceiptLineBaseQty(FromLocationCode: Code[10]; ToLocationCode: Code[10]; Quantity: Decimal)
    var
        TransferReceiptLine: Record "Transfer Receipt Line";
    begin
        TransferReceiptLine.SetRange("Transfer-from Code", FromLocationCode);
        TransferReceiptLine.SetRange("Transfer-to Code", ToLocationCode);
        TransferReceiptLine.FindFirst();
        TransferReceiptLine.TestField("Quantity (Base)", Quantity);
    end;

    local procedure VerifyPick(SourceNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FilterOnWhseActivityLine(SourceNo, WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.SetRange(Quantity, Quantity);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField("Item No.", ItemNo);
        WarehouseActivityLine.TestField("Location Code", LocationCode);
    end;

    local procedure VerifyRemainingQunatityOnPick(SourceNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FilterOnWhseActivityLine(SourceNo, WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField("Item No.", ItemNo);
        WarehouseActivityLine.TestField("Location Code", LocationCode);
        WarehouseActivityLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyItemJournalLine(ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.FindFirst();
        ItemJournalLine.TestField("Entry Type", ItemJournalLine."Entry Type"::"Positive Adjmt.");
        ItemJournalLine.TestField("Qty. (Calculated)", Quantity);
    end;

    local procedure VerifyWarehouseShipmentLine(WarehouseShipmentLine: Record "Warehouse Shipment Line"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        WarehouseShipmentLine.TestField("Item No.", ItemNo);
        WarehouseShipmentLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyItemJournalLineBatchAndTemplateForItem(ItemNo: Code[20]; LocationCode: Code[10]; JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.SetRange("Location Code", LocationCode);
        ItemJournalLine.FindFirst();
        ItemJournalLine.TestField("Journal Template Name", JournalTemplateName);
        ItemJournalLine.TestField("Journal Batch Name", JournalBatchName);
    end;

    local procedure VerifyTransferShipmentPosted(TransferOrderNo: Code[20]; ItemNo: Code[20]; ExpectedQuantity: Decimal)
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SetRange("Document No.", TransferOrderNo);
        TransferLine.SetRange("Item No.", ItemNo);
        TransferLine.FindFirst();
        Assert.AreEqual(ExpectedQuantity, TransferLine."Quantity Shipped", TransferMustBeShippedErr);
    end;

    local procedure CreateRouting(): Code[20]
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
    begin
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', Format(LibraryRandom.RandInt(100)), RoutingLine.Type::"Work Center", WorkCenter."No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        exit(RoutingHeader."No.");
    end;

    local procedure CreatePurchaseReturnOrderAndPartialPost(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; LocationCode: Code[10]): Decimal
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), -LibraryRandom.RandIntInRange(10, 20));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1, 100, 2));
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Return Qty. to Ship", -LibraryRandom.RandIntInRange(2, 5));
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        exit(-PurchaseLine."Return Qty. to Ship");
    end;

    local procedure SetupItemTrackingWithExpirationDates(var Item: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryInventory.CreateItemTrackingCode(ItemTrackingCode);
        ItemTrackingCode.Validate("Lot Specific Tracking", true);
        ItemTrackingCode.Validate("Use Expiration Dates", true);
        ItemTrackingCode.Validate("Man. Expir. Date Entry Reqd.", true);
        ItemTrackingCode.Modify(true);

        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify(true);
    end;

    local procedure SetStaticValues579500(var QtyPerUOM: Decimal; var QtyRoundingPrecision: Decimal; var OrderQuantity: Decimal)
    begin
        QtyPerUOM := 2.888;
        QtyRoundingPrecision := 0.00001;
        OrderQuantity := 248;
    end;

    local procedure GetTotalPickedQuantity(ItemNo: Code[20]; LocationCode: Code[10]; QtyPerUOM: Decimal; var TotalPickedQty: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        TotalPickedQty := 0;
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        if ItemLedgerEntry.FindSet() then
            repeat
                TotalPickedQty += Abs(ItemLedgerEntry.Quantity) / QtyPerUOM;
            until ItemLedgerEntry.Next() = 0;
    end;

    local procedure PostInventoryActivity(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityHeader.SetRange("Source Document", SourceDocument);
        WarehouseActivityHeader.SetRange("Source No.", SourceNo);
        WarehouseActivityHeader.SetRange(Type, WarehouseActivityHeader.Type::"Invt. Pick");
        WarehouseActivityHeader.FindFirst();

        // Autofill Qty. to Handle
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        if WarehouseActivityLine.FindSet() then
            repeat
                WarehouseActivityLine.Validate("Qty. to Handle", WarehouseActivityLine.Quantity);
                WarehouseActivityLine.Modify(true);
            until WarehouseActivityLine.Next() = 0;

        // Post the pick (Ship)
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);
    end;

    local procedure CreateInventoryForLotAndExpiry579500(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20])
    var
        LotNo: array[10] of Code[50];
        ExpiryDate: array[10] of Date;
        Quantity: array[10] of Decimal;
        i: Integer;
    begin
        LotNo[1] := 'LOT01';
        LotNo[2] := 'LOT03';
        LotNo[3] := 'LOT06';
        LotNo[4] := 'LOT01';
        LotNo[5] := 'LOT02';
        LotNo[6] := 'LOT03';
        LotNo[7] := 'LOT04';
        LotNo[8] := 'LOT02';
        LotNo[9] := 'LOT03';
        LotNo[10] := 'LOT05';

        ExpiryDate[1] := 20251130D;
        ExpiryDate[2] := 20250925D;
        ExpiryDate[3] := 20250925D;
        ExpiryDate[4] := 20250925D;
        ExpiryDate[5] := 20251130D;
        ExpiryDate[6] := 20250925D;
        ExpiryDate[7] := 20250606D;
        ExpiryDate[8] := 20250616D;
        ExpiryDate[9] := 20250925D;
        ExpiryDate[10] := 20250713D;

        Quantity[1] := 434.97616;
        Quantity[2] := 17.3126;
        Quantity[3] := 17.0373;
        Quantity[4] := 4.13394;
        Quantity[5] := 4.34355;
        Quantity[6] := 151.33333;
        Quantity[7] := 40.01221;
        Quantity[8] := 1.78787;
        Quantity[9] := 42.73313;
        Quantity[10] := 4.013;

        for i := 1 to ArrayLen(LotNo) do
            UpdateItemInventoryWithLot(ItemNo, LocationCode, BinCode, Quantity[i], LotNo[i], ExpiryDate[i]);
    end;

    local procedure UpdateItemInventoryWithLot(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal; LotNo: Code[50]; ExpiryDate: Date)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        ItemJournalBatch.Validate("Item Tracking on Lines", true);
        ItemJournalBatch.Modify(true);

        LibraryInventory.CreateItemJournalLine(
            ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
            ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine."Lot No." := LotNo;
        ItemJournalLine."Expiration Date" := ExpiryDate;
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Reserve from Current Line".Invoke(); // Reserve Current line.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationMultipleOptionPageHandler(var Reservation: TestPage Reservation)
    var
        Quantity: Decimal;
    begin
        case LibraryVariableStorage.DequeueInteger() of
            ReservationAction::AutoReserve:
                Reservation."Reserve from Current Line".Invoke();
            ReservationAction::GetQuantities:
                begin
                    Evaluate(Quantity, Reservation.QtyAllocatedInWarehouse.Value());
                    LibraryVariableStorage.Enqueue(Quantity);
                    Evaluate(Quantity, Reservation.TotalAvailableQuantity.Value());
                    LibraryVariableStorage.Enqueue(Quantity);
                end;
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AssembleToOrderLinesPageHandler(var AssembletoOrderLines: TestPage "Assemble-to-Order Lines")
    begin
        AssembletoOrderLines."&Reserve".Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PhysInvtItemSelectionPageHandler(var PhysInvtItemSelection: TestPage "Phys. Invt. Item Selection")
    begin
        PhysInvtItemSelection.FILTER.SetFilter("Item No.", GlobalItemNo);
        PhysInvtItemSelection.OK().Invoke();  // Open Report- Calculate Phys.Invt. Counting on CalculatePhysInvtCountingPageHandler.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculatePhysInvtCountingPageHandler(var CalculatePhysInvtCounting: TestRequestPage "Calculate Phys. Invt. Counting")
    begin
        CalculatePhysInvtCounting.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateWhsePutAwayPickHandler(var CreateWhsePutAwayPick: TestRequestPage "Create Invt Put-away/Pick/Mvmt")
    begin
        CreateWhsePutAwayPick.CInvtPick.SetValue(true);
        CreateWhsePutAwayPick.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhseSourceCreateDocumentOKHandler(var WhseSourceCreateDocument: TestRequestPage "Whse.-Source - Create Document")
    begin
        WhseSourceCreateDocument.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhseChangeUnitOfMeasureRequestPageHandler(var WhseChangeUnitofMeasure: TestRequestPage "Whse. Change Unit of Measure")
    begin
        Assert.IsFalse(WhseChangeUnitofMeasure."Action Type".Editable(), ActionTypeMustNotBeEditableErr);
        Assert.IsFalse(WhseChangeUnitofMeasure."Unit of Measure Code".Editable(), UnitOfMeasureCodeMustNotBeEditableErr);

        WhseChangeUnitofMeasure.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PickSelectionModalPageHandler(var PickSelection: TestPage "Pick Selection")
    begin
        PickSelection.Last();
        PickSelection.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure InsertNewProdOrderRoutingLine_ProdOrderRoutingModalPageHandler(var ProdOrderRouting: TestPage "Prod. Order Routing")
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        LibraryManufacturing.CreateMachineCenterWithCalendar(MachineCenter, WorkCenter."No.", 1);

        ProdOrderRouting.Last();
        ProdOrderRouting.New();
        ProdOrderRouting."Operation No.".SetValue(LibraryUtility.GenerateRandomCode(ProdOrderRoutingLine.FieldNo("Operation No."), Database::"Prod. Order Routing Line"));
        ProdOrderRouting.Type.SetValue(ProdOrderRoutingLine.Type::"Machine Center".AsInteger());
        ProdOrderRouting."No.".SetValue(MachineCenter."No.");
        ProdOrderRouting."Setup Time".SetValue(100);
    end;

    [RequestPageHandler]
    procedure CreateInvtPutAwayPickRequestPageHandler(var CreateInvtPutAwayPickMvmt: TestRequestPage "Create Invt Put-away/Pick/Mvmt")
    begin
        CreateInvtPutAwayPickMvmt.CInvtPick.SetValue(true);
        CreateInvtPutAwayPickMvmt.OK().Invoke();
    end;
}

