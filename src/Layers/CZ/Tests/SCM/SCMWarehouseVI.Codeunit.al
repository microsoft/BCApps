codeunit 137408 "SCM Warehouse VI"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [SCM]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPlanning: Codeunit "Library - Planning";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        PhysInvtCountMgt: Codeunit "Phys. Invt. Count.-Management";
        isInitialized: Boolean;
        CubageExceed: Label '%1 to place (%2) exceeds the available capacity (%3) on %4 %5.\Do you still want to use this %4 ?', Comment = '%1 = Cubage Caption, %2 = Total Value, %3 = Capacity Value, %4 = Bin Table, %5 = Bin Value';
        RelatedWarehouseActivityLineExistError: Label 'The %1 cannot be deleted when a related %2 exists.', Comment = '%1 = Prod. Order Component Table, %2 = Warehouse Activity Line Table.';
        RelatedWarehouseActivityLineExistError2: Label '%1 must not be changed when a %2 for this %3 exists:  in %3 %4=''%5'',%6=''%7'',%8=''%9'',%10=''%9''.', Comment = '%1 = Caption Item No., %2 = Warehouse Activity Line Table, %3 = Prod. Order Component Table, %4 = Caption Status, %5 = Value Status, %6 = Caption Prod. Order No., %7 = Value Prod. Order No., %8 = Caption Prod. Order Line No., %9 = Value Prod. Order Line No., %10 = Caption Line No.';
        UnknownFailure: Label 'Unknown Failure.';
        ConfirmMessage: Text[1024];
        TrackingActionStr: Option AssignLotNo,AssignSerialNo,SelectEntries,AssignGivenLotNo,AssignGivenLotAndSerialNo,AssistEditLotNo;
        QtyNotAvailableTxt: Label 'Quantity (Base) available must not be less than %1 in Bin Content', Comment = '%1: Field(Available Qty. to Take)';
        QuantityBaseAvailableMustNotBeLessThanErr: Label 'Quantity (Base) available must not be less than';
        AbsoluteValueEqualToQuantityErr: Label 'Absolute value of %1.%2 must be equal to the test quantity.', Comment = '%1 - tablename, %2 - fieldname.';
        RegisteringPickInterruptedErr: Label 'Registering pick has been interrupted.';
        LotNoNotAvailableInInvtErr: Label 'Lot No. %1 is not available in inventory, it has already been reserved for another document, or the quantity available is lower than the quantity to handle specified on the line.', Comment = '%1: Lot No.';
        InvtPickCreatedTxt: Label 'Number of Invt. Pick activities created';

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler,ItemTrackingSummaryHandler,MessageHandler,WhseItemTrackingLinesHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure RegisterReclassificationJournalWithItemTrackingLine()
    var
        Item: Record Item;
        Location: Record Location;
        WhseReclassificationJournal: TestPage "Whse. Reclassification Journal";
        Quantity: Decimal;
    begin
        // Test to validate Warehouse Entries after Registering Warehouse Reclassification Journal with Item Tracking Lines.

        // Setup: Create Location with Zones and Bins. Create Item with Item Tracking Code. Create and Register Put Away from Purchase Order.
        Initialize();
        CreateFullWarehouseSetup(Location);
        CreateItemWithItemTrackingCodeForLot(Item);
        Quantity := CreateAndRegisterPutAwayFromPurchaseOrder(Location.Code, Item."No.", true);

        // Exercise: Create and register Warehouse Reclassification Journal with Item Tracking.
        CreateWarehouseReclassJournal(WhseReclassificationJournal, Item."No.", Location.Code, Quantity);
        WhseReclassificationJournal.ItemTrackingLines.Invoke();
        WhseReclassificationJournal.Register.Invoke();

        // Verify: Verify Item ledger entries.
        VerifyItemLedgerEntry(Item."No.", false, -Quantity);
        VerifyItemLedgerEntry(Item."No.", true, Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler,ItemTrackingSummaryHandler,WhseItemTrackingLinesSetSNForItemLotTrackingHandler')]
    [Scope('OnPrem')]
    procedure CheckWhsReclassificationJournalWithItemTrackingLine()
    var
        Item: Record Item;
        Location: Record Location;
        WhseReclassificationJournal: TestPage "Whse. Reclassification Journal";
        Quantity: Decimal;
    begin
        //[SCENARIO 474795] Try to enter a Serial No. to a Warehouse Reclassification Journal Line with Item Tracking Code set to Lot No.
        Initialize();

        // [GIVEN] Create Location with Zones and Bins. Create Item with Item Tracking Code.         
        CreateFullWarehouseSetup(Location);
        CreateItemWithItemTrackingCodeForLot(Item);

        // [GIVEN] Create and Register Put Away from Purchase Order.
        Quantity := CreateAndRegisterPutAwayFromPurchaseOrder(Location.Code, Item."No.", true);

        // [GIVEN] Create Warehouse Reclassification Journal with Item Tracking.
        CreateWarehouseReclassJournal(WhseReclassificationJournal, Item."No.", Location.Code, Quantity);

        // [WHEN] try to enter "New Serial No." in "Whse. Item Tracking Lines" and Qty is <> 1, 
        // [THEN] system should throw error
        if Quantity <> 1 then
            asserterror WhseReclassificationJournal.ItemTrackingLines.Invoke()
        else
            WhseReclassificationJournal.ItemTrackingLines.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesSetSNForItemLotTrackingHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    begin
        WhseItemTrackingLines."Lot No.".AssistEdit();
        WhseItemTrackingLines."New Lot No.".SetValue(LibraryUtility.GenerateGUID());
        WhseItemTrackingLines."New Serial No.".SetValue(LibraryUtility.GenerateGUID());
        WhseItemTrackingLines.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('CalculateInventoryHandler')]
    [Scope('OnPrem')]
    procedure CalculateInventoryOnWarehousePhysicalInventoryJournal()
    var
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // Test to validate Warehouse Activity Line after running Calculate Inventory batch job.

        // Setup: Create Location with Zones and Bins. Create and Register Put Away from Purchase Order. Create and Release Sales Order. Run Calculate Inventory report.
        Initialize();
        CreateFullWarehouseSetup(Location);
        LibraryInventory.CreateItem(Item);
        Quantity := CreateAndRegisterPutAwayFromPurchaseOrder(Location.Code, Item."No.", false);
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, Item."No.", Location.Code, Quantity);
        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Type::"Physical Inventory", Location.Code);
        RunCalculateInventory(WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Location.Code, Item."No.");

        // Exercise: Create Pick from Sales Order.
        CreatePickFromSalesHeader(SalesHeader);

        // Verify: Verify Warehouse Activity Line.
        VerifyWarehouseActivityLine(
          SalesHeader."No.", Item."No.", WarehouseActivityLine."Activity Type"::Pick,
          WarehouseActivityLine."Source Document"::"Sales Order", Quantity);
    end;

    [Test]
    [HandlerFunctions('PutAwaySelectionHandler,MessageHandler,CreatePutAwayHandler')]
    [Scope('OnPrem')]
    procedure CreatePutAwayFromPutAwayWorksheetWithPartialQuantityToHandle()
    var
        Location: Record Location;
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PutAwayWorksheet: TestPage "Put-away Worksheet";
        QuantityToHandle: Decimal;
    begin
        // Create Put Away from Put Away Worksheet with partial Quantity to Handle.

        // Setup: Create Full Warehouse Setup. Create Warehouse Receipt from Purchase Order. Invoke Get Warehouse Documents from Put Away Worksheet.
        Initialize();
        CreateAndUpdateFullWareHouseSetup(Location);
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseLine, Location.Code);
        PutAwayWorksheet.OpenEdit();
        PutAwayWorksheet.GetWarehouseDocuments.Invoke();
        QuantityToHandle := LibraryRandom.RandInt(10);

        // Exercise: Update Quantity to Handle on Put Away Worksheet line and Invoke Create Put away from Pick Worksheet.
        PutAwayWorksheet."Qty. to Handle".SetValue(QuantityToHandle);
        Commit();  // COMMIT is required here.
        PutAwayWorksheet.CreatePutAway.Invoke();

        // Verify: Verify Warehouse Activity Line.
        VerifyWarehouseActivityLine(
          PurchaseLine."Document No.", PurchaseLine."No.", WarehouseActivityLine."Activity Type"::"Put-away",
          WarehouseActivityLine."Source Document"::"Purchase Order", QuantityToHandle);
    end;

    [Test]
    [HandlerFunctions('PutAwaySelectionHandler,MessageHandler,CreatePutAwayHandler')]
    [Scope('OnPrem')]
    procedure RegisterPutAwayWithPartialQuantityToHandle()
    var
        Location: Record Location;
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        PutAwayWorksheet: TestPage "Put-away Worksheet";
        QuantityToHandle: Decimal;
    begin
        // Create and Register Put Away from Put Away Worksheet with partial Quantity to Handle.

        // Setup: Create Full Warehouse Setup. Create Warehouse Receipt from Purchase Order. Invoke Get Warehouse Documents from Put Away Worksheet and Create Put Away.
        Initialize();
        CreateAndUpdateFullWareHouseSetup(Location);
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseLine, Location.Code);
        PutAwayWorksheet.OpenEdit();
        PutAwayWorksheet.GetWarehouseDocuments.Invoke();
        Commit();  // COMMIT is required here.
        PutAwayWorksheet.CreatePutAway.Invoke();
        QuantityToHandle := LibraryRandom.RandInt(10);

        // Exercise: Update Quantity to Handle on Put Away and Register the Put Away.
        UpdateQuantityToHandleInWarehouseActivityLine(PurchaseLine."Document No.", QuantityToHandle);
        RegisterWarehouseActivityHeader(Location.Code, WarehouseActivityHeader.Type::"Put-away");

        // Verify: Verify Warehouse Activity Line.
        VerifyQuantityHandledInWarehouseActivityLine(PurchaseLine."Document No.", PurchaseLine."No.", QuantityToHandle);
    end;

    [Test]
    [HandlerFunctions('PickSelectionHandler')]
    [Scope('OnPrem')]
    procedure ShippingAdviceOnPickWorksheet()
    var
        TransferHeader: Record "Transfer Header";
        Item: Record Item;
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        PickWorksheet: TestPage "Pick Worksheet";
    begin
        // Test and verify Shipping Advice on Pick Worksheet.

        // Setup: Create Initial Setup with Transfer Order. Create and release Warehouse Shipment from Transfer Order.
        Initialize();
        CreateInitialSetupWithTransferOrder(TransferHeader, LibraryInventory.CreateItem(Item));
        CreateAndReleaseWarehouseShipmentFromTransferOrder(TransferHeader);

        // Exercise: Invoke Get Warehouse Documents from Pick Worksheet.
        PickWorksheet.OpenEdit();
        PickWorksheet."Get Warehouse Documents".Invoke();

        // Verify: Verify Shipping Advice on Pick Worksheet must be Partial.
        VerifyShippingAdviceOnPickWorksheet(Item."No.", WhseWorksheetLine."Shipping Advice"::Partial);  // Use Default Shipping Advice as Partial updated from Transfer Order.
    end;

    [Test]
    [HandlerFunctions('PickSelectionHandler')]
    [Scope('OnPrem')]
    procedure ShippingAdviceOnPickWorksheetAfterUpdateTransferOrder()
    var
        TransferHeader: Record "Transfer Header";
        Item: Record Item;
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        PickWorksheet: TestPage "Pick Worksheet";
    begin
        // Test and verify Shipping Advice on Pick Worksheet must be updated after updating  Shipping Advice on Transfer Order.

        // Setup: Create Initial Setup with Transfer Order. Create and release Warehouse Shipment from Transfer Order. Invoke Get Warehouse Documents from Pick Worksheet.
        Initialize();
        CreateInitialSetupWithTransferOrder(TransferHeader, LibraryInventory.CreateItem(Item));
        CreateAndReleaseWarehouseShipmentFromTransferOrder(TransferHeader);
        PickWorksheet.OpenEdit();
        PickWorksheet."Get Warehouse Documents".Invoke();

        // Exercise: Reopen Transfer Order and change Shipping Advice.
        UpdateShippingAdviceOnTransferOrder(TransferHeader, TransferHeader."Shipping Advice"::Complete);

        // Verify: Verify Shipping Advice on Pick Worksheet must be Complete.
        VerifyShippingAdviceOnPickWorksheet(Item."No.", WhseWorksheetLine."Shipping Advice"::Complete);
    end;

    [Test]
    [HandlerFunctions('PickSelectionHandler,CreatePickHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure RegisteredPickFromPickWorksheet()
    var
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        // Test to validate Warehouse Registered Pick with Pick Worksheet.

        // Setup: Create initial setup for Pick Worksheet. Invoke Get Warehouse Documents from Pick Worksheet and Create Pick.
        Initialize();
        CreateInitialSetupForPick(SalesLine);
        GetWarehouseDocumentsAndCreatePick();

        // Exercise: Register Pick.
        RegisterWarehouseActivityHeader(SalesLine."Location Code", WarehouseActivityHeader.Type::Pick);

        // Verify: Verify Registered Pick.
        VerifyRegisteredWarehouseActivityLine(SalesLine, WarehouseActivityLine."Action Type"::Take);
        VerifyRegisteredWarehouseActivityLine(SalesLine, WarehouseActivityLine."Action Type"::Place);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandlerWithSerialNo,EnterQuantityToCreateHandler')]
    [Scope('OnPrem')]
    procedure GetBinContent()
    var
        Item: Record Item;
        Location: Record Location;
        BinCode: Code[20];
        Quantity: Decimal;
    begin
        // Test to verify Bin Content after Posting Item Journal Line.

        // Setup: Create Location,Item Tracking Code and Item. Create Item Journal Line, Post Item Journal Line.
        Initialize();
        CreateAndUpdateLocationForBinContent(Location);
        CreateItemWithItemTrackingCodeForSerialNo(Item);
        BinCode := AddBin(Location.Code);
        Quantity := LibraryRandom.RandInt(5);
        CreateAndPostItemJournalLineWithItemTracking(Item."No.", Location.Code, BinCode, Quantity);

        // Exercise: Run Report Warehouse Get Bin Content.
        RunWarehouseGetBinContentReport(Location.Code, Item."No.", BinCode);

        // Verify: Verify Quantity after running Report Warehouse Get Bin Content.
        VerifyQuantityInItemReclassification(Item."No.", Location.Code, BinCode, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NextCountingPeriodWithItem()
    var
        Item: Record Item;
        PhysInvtCountingPeriod: Record "Phys. Invt. Counting Period";
        PhysInvtCountManagement: Codeunit "Phys. Invt. Count.-Management";
        NextCountingStartDate: Date;
        NextCountingEndDate: Date;
    begin
        // Test and verify Next Counting Period on Item after updating Physical Inventory Counting Period.

        // Setup.
        Initialize();

        // Exercise: Create Item with Physical Inventory Counting Period.
        CreateItemWithPhysicalInventoryCountingPeriod(Item, PhysInvtCountingPeriod);

        // Verify: Verify Next Counting Period on Item.
        PhysInvtCountManagement.CalcPeriod(
          Item."Last Counting Period Update", NextCountingStartDate, NextCountingEndDate,
          PhysInvtCountingPeriod."Count Frequency per Year");
        Item.TestField("Next Counting Start Date", NextCountingStartDate);
        Item.TestField("Next Counting End Date", NextCountingEndDate);
    end;

    [Test]
    [HandlerFunctions('PhysicalInventoryItemSelectionHandler,CalculatePhysicalInventoryCountingHandler')]
    [Scope('OnPrem')]
    procedure PhysicalInventoryItemSelectionWithItem()
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        PhysInvtCountingPeriod: Record "Phys. Invt. Counting Period";
    begin
        // Test and verify Next Counting Period on Physical Inventory Item Selection page after updating Physical Inventory Counting Period on Item.

        // Setup: Create Item with Physical Inventory Counting Period.
        Initialize();
        CreateItemWithPhysicalInventoryCountingPeriod(Item, PhysInvtCountingPeriod);

        // Exercise: Run Calculate Counting Period from Physical Inventory Journal.
        CalcPhysInvtDatesAndRunCalculateCountingPeriodInPhysInvtJournal(
          ItemJournalBatch, Item."No.", Item."Last Counting Period Update", PhysInvtCountingPeriod."Count Frequency per Year");

        // Verify: Verify Next Counting Period on Physical Inventory Item Selection page. Verification is performed into PhysicalInventoryItemSelectionHandler function.
    end;

    [Test]
    [HandlerFunctions('PhysicalInventoryItemSelectionHandler,CalculatePhysicalInventoryCountingHandler')]
    [Scope('OnPrem')]
    procedure CalculateCountingPeriodFromPhysicalInventoryJournalWithItem()
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        PhysInvtCountingPeriod: Record "Phys. Invt. Counting Period";
    begin
        // Test and verify functionality of Calculate Counting Period from Physical Inventory Journal for Item.

        // Setup: Create Item with Physical Inventory Counting Period. Create and post Item Journal Line.
        Initialize();
        CreateItemWithPhysicalInventoryCountingPeriod(Item, PhysInvtCountingPeriod);
        CreateAndPostItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", '');

        // Exercise: Run Calculate Counting Period from Physical Inventory Journal.
        CalcPhysInvtDatesAndRunCalculateCountingPeriodInPhysInvtJournal(
          ItemJournalBatch, Item."No.", Item."Last Counting Period Update", PhysInvtCountingPeriod."Count Frequency per Year");

        // Verify: Verify Physical Inventory Journal Line.
        VerifyItemJournalLine(ItemJournalBatch, ItemJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NextCountingPeriodWithStockKeepingUnit()
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
        PhysInvtCountingPeriod: Record "Phys. Invt. Counting Period";
        PhysInvtCountManagement: Codeunit "Phys. Invt. Count.-Management";
        NextCountingStartDate: Date;
        NextCountingEndDate: Date;
    begin
        // Test and verify Next Counting Period on Stock keeping Unit after updating Physical Inventory Counting Period.

        // Setup: Create Stock Keeping Unit.
        Initialize();
        CreateStockKeepingUnit(StockkeepingUnit);

        // Exercise: Update Physical Inventory Counting Period on Stock Keeping Unit.
        UpdatePhysicalInventoryCountingPeriodOnStockKeepingUnit(StockkeepingUnit, PhysInvtCountingPeriod);

        // Verify: Verify Next Counting Period on Stock keeping Unit.
        PhysInvtCountManagement.CalcPeriod(
          StockkeepingUnit."Last Counting Period Update", NextCountingStartDate, NextCountingEndDate,
          PhysInvtCountingPeriod."Count Frequency per Year");
        StockkeepingUnit.TestField("Next Counting Start Date", NextCountingStartDate);
        StockkeepingUnit.TestField("Next Counting End Date", NextCountingEndDate);
    end;

    [Test]
    [HandlerFunctions('PhysicalInventoryItemSelectionHandler,CalculatePhysicalInventoryCountingHandler')]
    [Scope('OnPrem')]
    procedure PhysicalInventoryItemSelectionWithStockKeepingUnit()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        StockkeepingUnit: Record "Stockkeeping Unit";
        PhysInvtCountingPeriod: Record "Phys. Invt. Counting Period";
    begin
        // Test and verify Next Counting Period on Physical Inventory Item Selection page after updating Physical Inventory Counting Period on Stock keeping Unit.

        // Setup: Create Stock Keeping Unit. Update Physical Inventory Counting Period on Stock Keeping Unit.
        Initialize();
        CreateStockKeepingUnit(StockkeepingUnit);
        UpdatePhysicalInventoryCountingPeriodOnStockKeepingUnit(StockkeepingUnit, PhysInvtCountingPeriod);

        // Exercise: Run Calculate Counting Period from Physical Inventory Journal.
        CalcPhysInvtDatesAndRunCalculateCountingPeriodInPhysInvtJournal(
          ItemJournalBatch, StockkeepingUnit."Item No.", StockkeepingUnit."Last Counting Period Update",
          PhysInvtCountingPeriod."Count Frequency per Year");

        // Verify: Verify Next Counting Period on Physical Inventory Item Selection page. Verification is performed into PhysicalInventoryItemSelectionHandler function.
    end;

    [Test]
    [HandlerFunctions('PhysicalInventoryItemSelectionHandler,CalculatePhysicalInventoryCountingHandler')]
    [Scope('OnPrem')]
    procedure CalculateCountingPeriodFromPhysicalInventoryJournalWithStockKeepingUnit()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        StockkeepingUnit: Record "Stockkeeping Unit";
        PhysInvtCountingPeriod: Record "Phys. Invt. Counting Period";
    begin
        // Test and verify functionality of Calculate Counting Period from Physical Inventory Journal for Stock keeping Unit.

        // Setup: Create Stock Keeping Unit. Update Physical Inventory Counting Period on Stock Keeping Unit. Create and post Item Journal Line.
        Initialize();
        CreateStockKeepingUnit(StockkeepingUnit);
        UpdatePhysicalInventoryCountingPeriodOnStockKeepingUnit(StockkeepingUnit, PhysInvtCountingPeriod);
        CreateAndPostItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", StockkeepingUnit."Item No.", StockkeepingUnit."Location Code");

        // Exercise: Run Calculate Counting Period from Physical Inventory Journal.
        CalcPhysInvtDatesAndRunCalculateCountingPeriodInPhysInvtJournal(
          ItemJournalBatch, StockkeepingUnit."Item No.", StockkeepingUnit."Last Counting Period Update",
          PhysInvtCountingPeriod."Count Frequency per Year");

        // Verify: Verify Physical Inventory Journal Line.
        VerifyItemJournalLine(ItemJournalBatch, ItemJournalLine);
    end;

    [Test]
    [HandlerFunctions('PhysicalInventoryItemSelectionHandler,CalculatePhysicalInventoryCountingHandler')]
    [Scope('OnPrem')]
    procedure PhysicalInventoryItemSelectionFromWarehousePhysicalInventoryJournal()
    var
        Item: Record Item;
        Location: Record Location;
        PhysInvtCountingPeriod: Record "Phys. Invt. Counting Period";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
    begin
        // Test and verify Next Counting Period on Physical Inventory Item Selection page open from Warehouse Physical Inventory Journal after updating Physical Inventory Counting Period on Item.

        // Setup: Create full Warehouse Setup with Location. Create Item with Physical Inventory Counting Period.
        Initialize();
        CreateFullWarehouseSetup(Location);
        CreateItemWithPhysicalInventoryCountingPeriod(Item, PhysInvtCountingPeriod);

        // Exercise: Run Calculate Counting Period from Warehouse Physical Inventory Journal.
        CalcPhysInvtDatesAndRunCalculateCountingPeriodInWhseInvtJournal(
          WarehouseJournalBatch, Item."No.", Location.Code, Item."Last Counting Period Update",
          PhysInvtCountingPeriod."Count Frequency per Year");

        // Verify: Verify Next Counting Period on Physical Inventory Item Selection page. Verification is performed into PhysicalInventoryItemSelectionHandler function.
    end;

    [Test]
    [HandlerFunctions('PhysicalInventoryItemSelectionHandler,CalculatePhysicalInventoryCountingHandler')]
    [Scope('OnPrem')]
    procedure CalculateCountingPeriodFromWarehousePhysicalInventoryJournal()
    var
        Bin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        PhysInvtCountingPeriod: Record "Phys. Invt. Counting Period";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // Test and verify functionality of Calculate Counting Period from Warehouse Physical Inventory Journal for Item.

        // Setup: Create full Warehouse Setup with Location. Create Item with Physical Inventory Counting Period. Create and register Warehouse Journal Line. Calculate and post Warehouse Adjustment.
        Initialize();
        CreateFullWarehouseSetup(Location);
        CreateItemWithPhysicalInventoryCountingPeriod(Item, PhysInvtCountingPeriod);
        FindBin(Bin, Location.Code);
        CreateAndRegisterWarehouseJournalLine(
          WarehouseJournalLine, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Bin, Item."No.", LibraryRandom.RandDec(100, 2));  // Using random Quantity.
        CalculateAndPostWarehouseAdjustment(Item);

        // Exercise: Run Calculate Counting Period from Warehouse Physical Inventory Journal.
        CalcPhysInvtDatesAndRunCalculateCountingPeriodInWhseInvtJournal(
          WarehouseJournalBatch, Item."No.", Location.Code, Item."Last Counting Period Update",
          PhysInvtCountingPeriod."Count Frequency per Year");

        // Verify: Verify Warehouse Physical Inventory Journal Line.
        VerifyWarehouseJournalLine(WarehouseJournalBatch, WarehouseJournalLine);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ChangeItemNoOnProductionOrderLineError()
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // Test and verify error message on updating Item on Production Order Line.

        // Setup : Create Inventory Pick from Production Order.
        Initialize();
        CreateInventoryPickFromProductionOrder(Item, Item2, ProductionOrder);

        // Exercise : Update Item on Production Order Line.
        FindProductionOrderLine(ProdOrderLine, ProductionOrder."No.");
        asserterror ProdOrderLine.Validate("Item No.", Item2."No.");

        // Verify : Verify error message.
        Assert.AreEqual(
          StrSubstNo(RelatedWarehouseActivityLineExistError, ProdOrderComponent.TableCaption(), WarehouseActivityLine.TableCaption()),
          GetLastErrorText, UnknownFailure);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ChangeItemNoOnProductionOrderComponentError()
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Test and verify error message on updating Item on Production Order Component.

        // Setup : Create Inventory Pick from Production Order.
        Initialize();
        CreateInventoryPickFromProductionOrder(Item, Item2, ProductionOrder);

        // Exercise : Update Item on Production Order Component.
        FindProductionOrderComponent(ProdOrderComponent, ProductionOrder."No.");
        asserterror ProdOrderComponent.Validate("Item No.", Item."No.");

        // Verify : Verify error message.
        Assert.AreEqual(
              StrSubstNo(
                RelatedWarehouseActivityLineExistError2, ProdOrderComponent.FieldCaption("Item No."), WarehouseActivityLine.TableCaption(), ProdOrderComponent.TableCaption(),
                ProdOrderComponent.FieldCaption(Status), ProdOrderComponent.Status::Released, ProdOrderComponent.FieldCaption("Prod. Order No."), ProdOrderComponent."Prod. Order No.",
                ProdOrderComponent.FieldCaption("Prod. Order Line No."), ProdOrderComponent."Prod. Order Line No.", ProdOrderComponent.FieldCaption("Line No.")), GetLastErrorText, UnknownFailure);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinReplenishment()
    var
        Bin: Record Bin;
        Bin2: Record Bin;
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // Test and verify Bin Replenishment.

        // Setup: Create Initial Setup for Bin Replenishment.
        Initialize();
        CreateInitialSetupForBinReplenishment(Bin, Bin2, WarehouseJournalLine);

        // Exercise: Calculate Bin Replenishment.
        CalculateBinReplenishment(WarehouseJournalLine."Location Code");

        // Verify: Verify Movement Worksheet Line.
        VerifyMovementWorksheetLine(WarehouseJournalLine."Item No.", Bin.Code, Bin2.Code, WarehouseJournalLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('WhseSourceCreateDocumentHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateMovementWithBinReplenishment()
    var
        Bin: Record Bin;
        Bin2: Record Bin;
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Test and verify Create Movement after Bin Replenishment.

        // Setup: Create Initial Setup for Bin Replenishment. Calculate Bin Replenishment.
        Initialize();
        CreateInitialSetupForBinReplenishment(Bin, Bin2, WarehouseJournalLine);
        CalculateBinReplenishment(WarehouseJournalLine."Location Code");

        // Exercise: Create Movement.
        CreateMovement(WarehouseJournalLine."Item No.");

        // Verify: Verify values on Warehouse Movement.
        FindWarehouseActivityHeader(WarehouseActivityHeader, WarehouseJournalLine."Location Code", WarehouseActivityHeader.Type::Movement);
        VerifyWarehouseMovementLine(
          WarehouseActivityHeader, WarehouseActivityLine."Action Type"::Take, WarehouseJournalLine."Item No.", Bin.Code,
          WarehouseJournalLine.Quantity);
        VerifyWarehouseMovementLine(
          WarehouseActivityHeader, WarehouseActivityLine."Action Type"::Place, WarehouseJournalLine."Item No.", Bin2.Code,
          WarehouseJournalLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('WhseSourceCreateDocumentHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure RegisterMovementWithBinReplenishment()
    var
        Bin: Record Bin;
        Bin2: Record Bin;
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        RegisteredWhseActivityHdr: Record "Registered Whse. Activity Hdr.";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        // Test and verify Register Movement after Bin Replenishment.

        // Setup: Create Initial Setup for Bin Replenishment. Calculate Bin Replenishment. Create Movement.
        Initialize();
        CreateInitialSetupForBinReplenishment(Bin, Bin2, WarehouseJournalLine);
        CalculateBinReplenishment(WarehouseJournalLine."Location Code");
        CreateMovement(WarehouseJournalLine."Item No.");

        // Exercise: Register Movement.
        RegisterWarehouseActivityHeader(WarehouseJournalLine."Location Code", WarehouseActivityHeader.Type::Movement);

        // Verify: Verify values on Registered Warehouse Movement.
        FindRegisteredWarehouseActivityHeader(
          RegisteredWhseActivityHdr, WarehouseJournalLine."Location Code", RegisteredWhseActivityHdr.Type::Movement);
        VerifyRegisteredWarehouseMovementLine(
          RegisteredWhseActivityHdr, RegisteredWhseActivityLine."Action Type"::Take, WarehouseJournalLine."Item No.", Bin.Code,
          WarehouseJournalLine.Quantity);
        VerifyRegisteredWarehouseMovementLine(
          RegisteredWhseActivityHdr, RegisteredWhseActivityLine."Action Type"::Place, WarehouseJournalLine."Item No.", Bin2.Code,
          WarehouseJournalLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CubageExceedOnMovementWorksheet()
    var
        Bin: Record Bin;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        // Test and verify Cubage exceeds on Movement Worksheet.

        // Setup: Create Initial Setup for Movement Worksheet with Cubage.
        Initialize();
        CreateInitialSetupForMovementWorksheetWithCubage(ItemUnitOfMeasure, Bin);

        // Exercise: Create Movement Worksheet.
        CreateMovementWorksheet(ItemUnitOfMeasure, Bin);

        // Verify: Verify Cubage exceeds message on Movement Worksheet.
        Assert.AreEqual(
          StrSubstNo(
            CubageExceed, ItemUnitOfMeasure.FieldCaption(Cubage), ItemUnitOfMeasure.Cubage * ItemUnitOfMeasure.Cubage,
            ItemUnitOfMeasure.Cubage, Bin.TableCaption(), Bin.Code), ConfirmMessage, UnknownFailure);
    end;

    [Test]
    [HandlerFunctions('PickSelectionHandler,CreatePickHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AutofillQuantityToHandleInPickAfterCreatingTransferOrder()
    var
        Location: Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        Location2: Record Location;
        PurchaseLineQuantity: Decimal;
    begin
        // Test to verify Auto fill Quantity to Handle in Warehouse Pick after creating Transfer Order.

        // Setup: Create and register Put Away from Purchase Order. Create and release Warehouse Shipment from Transfer Order and create Pick.
        Initialize();
        CreateAndUpdateLocation(Location2, true, true);  // Used for To Location in Transfer order.
        CreateFullWarehouseSetup(Location);  // Used for From Location in Transfer order.
        LibraryInventory.CreateItem(Item);
        PurchaseLineQuantity := CreateAndRegisterPutAwayFromPurchaseOrder(Location.Code, Item."No.", false);
        CreateAndReleaseTransferOrder(TransferHeader, Location.Code, Location2.Code, Item."No.", PurchaseLineQuantity / 2);  // Quantity is divided by 2 as Transfer order Quantity should be less than Purchase line Quantity.
        CreateAndReleaseWarehouseShipmentFromTransferOrder(TransferHeader);
        GetWarehouseDocumentsAndCreatePick();

        // Exercise: Auto fill Quantity to Handle in Warehouse Pick.
        AutofillQuantityToHandle(TransferHeader."No.");

        // Verify: Quantity To Handle in Warehouse Activity Line.
        VerifyQuantityToHandleInWarehouseActivityLine(TransferHeader."No.", Item."No.", PurchaseLineQuantity / 2);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingPageHandler,ItemTrackingLinesSalesHandler,ItemTrackingSummaryHandler')]
    [Scope('OnPrem')]
    procedure RegisterPickWithAutoFillQuantityToHandle()
    var
        Bin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemUnitOfMeasure2: Record "Item Unit of Measure";
        SalesHeader: Record "Sales Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        // Test to create Pick by invoking Auto fill Quantity to Handle on Pick with Item Tracking and Unit of Measure Conversion.

        // Setup: Create Item with Item Tracking code, Second Item Unit of Measure and Location. Create and register Warehouse Item Journal. Create Sales Order, Warehouse Shipment and create Pick. Invoke Autofill Quantity to handle on Pick.
        Initialize();
        CreateItemWithItemTrackingCodeForLot(Item);
        ItemUnitOfMeasure.Get(Item."No.", Item."Base Unit of Measure");  // Get Base Item Unit of Measure.
        CreateItemUnitOfMeasure(ItemUnitOfMeasure2, ItemUnitOfMeasure);  // Create Second Item Unit of Measure.
        CreateAndUpdateFullWareHouseSetup(Location);
        FindBin(Bin, Location.Code);
        PostWhseJournalPositiveAdjmtWithItemTracking(Bin, Item, ItemUnitOfMeasure2."Qty. per Unit of Measure");

        CreateAndReleaseSalesOrderWithItemTracking(
          SalesHeader, Item."No.", ItemUnitOfMeasure."Qty. per Unit of Measure", ItemUnitOfMeasure2.Code, Location.Code);  // Create Sales Order with Second Unit of Measure.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SalesHeader."No.", WarehouseShipmentLine."Source Document"::"Sales Order");
        LibraryWarehouse.CreateWhsePick(WarehouseShipmentHeader);
        InvokeAutofillQuantityToHandleOnPick(Location.Code);

        // Exercise: Register the Pick.
        RegisterWarehouseActivityHeader(Location.Code, WarehouseActivityHeader.Type::Pick);

        // Verify: Warehouse Shipment line.
        VerifyWarehouseShipmentLine(
          WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.", Item."No.",
          ItemUnitOfMeasure."Qty. per Unit of Measure", 0);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingPageHandler,WhseSourceCreateDocumentHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateMovementWithBinReplenishmentWithMultipleLines()
    var
        Bin: Record Bin;
        Bin2: Record Bin;
        Bin3: Record Bin;
        Item: Record Item;
        Location: Record Location;
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        ExpirationDate: Date;
    begin
        // Setup: Create Location with Zones and Bins. Create Item with Item Tracking Code.
        Initialize();
        CreateFullWarehouseSetup(Location);
        UpdateParametersOnLocation(Location, true, true);
        CreateItemWithItemTrackingCodeWithExpirateDate(Item);

        // Find two Bins and create a fixed Bin with Bin Content.
        CreateAndFindBin(Bin, Bin2, Bin3, Item, Location.Code);

        // Create and register two Warehouse Item Journal Lines with Item Tracking and Expiration Date.
        ExpirationDate := CalcDate('<+' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Type::Item, Location.Code);

        CreateAndRegisterWarehouseItemJournalWithItemTracking(
          WarehouseJournalBatch, WarehouseJournalLine, Bin.Code, Location.Code, Bin."Zone Code",
          WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandInt(10), ExpirationDate,
          TrackingActionStr::AssignLotNo);
        CreateAndRegisterWarehouseItemJournalWithItemTracking(
          WarehouseJournalBatch, WarehouseJournalLine, Bin2.Code, Location.Code, Bin2."Zone Code",
          WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.",
          LibraryRandom.RandInt(10) + LibraryRandom.RandInt(5), ExpirationDate, TrackingActionStr::AssignLotNo);

        // Exercise: Calculate Bin Replenishment and create Movement.
        CalculateBinReplenishment(Location.Code);
        CreateMovement(Item."No.");

        // Verify: Verify the right sequence of Movement lines.
        VerifyWarehouseActivityLine2(Item."No.", Bin.Code, Bin2.Code);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure PostPartialWhseShipment()
    var
        SalesHeader: Record "Sales Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        LocationCode: Code[10];
        ItemNo: Code[20];
        Quantity: Decimal;
    begin
        // Setup: Create and Register Put Away from Purchase Order. Create and Release Sales Order.
        // Calculate plan from Order Planning. Make Orders for active Sales order. Create and Register Pick from Sale Order.
        Initialize();
        InitialSetupForMakeOrders(SalesHeader, ItemNo, LocationCode, Quantity);
        CreateAndRegisterPickFromSalesOrder(SalesHeader, LocationCode);

        // Exercise: Post partially Warehouse Shipment.
        PostWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");

        // Verify: Verify Warehouse Activity Line.
        VerifyWarehouseShipmentLine(
          WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.", ItemNo, Quantity, Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemAvailabilityByLocationHandler')]
    [Scope('OnPrem')]
    procedure ItemAvailabilityOnWarehouseReceipt()
    var
        PurchaseLine: Record "Purchase Line";
        WhseReceiptHeaderNo: Code[20];
    begin
        // Setup: Create Purchase Order and Realease it. Creat Warehouse Receipt from Purchase Order.
        Initialize();
        CreateWarehouseReceiptFromPurchaseOrder(PurchaseLine);

        // Exercise & Verify: Show Item Availability By Location On Whse. Receipt by page. No error pops up.
        WhseReceiptHeaderNo := FindWarehouseReceiptHeader(PurchaseLine."Document No.");
        ShowItemAvailabilityByLocationOnWhseReceiptByPage(WhseReceiptHeaderNo);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingPageHandler,WhseSourceCreateDocumentHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure MovementForMultipleBinsAndItemTrackingWithBlockBin()
    var
        Bin1: Record Bin;
        Bin2: Record Bin;
        Bin3: Record Bin;
        BinContent: Record "Bin Content";
        LocationCode: Code[10];
        ItemNo: Code[20];
        LotNo: array[20] of Code[20];
        LotNo2: array[20] of Code[20];
        Quantity: Integer;
    begin
        // Setup: Create Item and put it into Bin1 and Bin2 with different Lot No.
        Initialize();
        PutItemInDifferentBinsWithItemTracking(
          LocationCode, ItemNo, Bin1, Bin2, Bin3, LotNo, LotNo2, Quantity, TrackingActionStr::AssignLotNo);

        // Block Movement for Bin1
        // Update Bin Ranking for Bins: BinRanking1 = BinRanking3 > BinRanking2
        UpdateBlockMovementOnBinContent(BinContent, Bin1, ItemNo, BinContent."Block Movement"::All);
        UpdateBinRankingOnBins(LocationCode, Bin1, Bin2, Bin3);

        // Exercise: Calculate Bin Replenishment and create Movement.
        // Verify: Verify the Bin Code and Item Tracking No. is correct of Movement lines.
        CreateMovementAndVerifyMovementLinesForLot(LocationCode, ItemNo, Bin2.Code, LotNo2[1], Quantity);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingPageHandler,WhseSourceCreateDocumentHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure MovementForMultipleBinsAndItemTrackingWithBlockLotInfo()
    var
        Bin1: Record Bin;
        Bin2: Record Bin;
        Bin3: Record Bin;
        LocationCode: Code[10];
        ItemNo: Code[20];
        LotNo: array[20] of Code[20];
        LotNo2: array[20] of Code[20];
        Quantity: Integer;
    begin
        // Setup: Create Item and put it into Bin1 and Bin2 with different Lot No.
        Initialize();
        PutItemInDifferentBinsWithItemTracking(
          LocationCode, ItemNo, Bin1, Bin2, Bin3, LotNo, LotNo2, Quantity, TrackingActionStr::AssignLotNo);

        // Block Lot Information for Lot1 which put in Bin1
        BlockedLotNoInformation(ItemNo, LotNo[1], true);

        // Exercise: Calculate Bin Replenishment and create Movement.
        // Verify: Verify the Bin Code and Item Tracking No. is correct of Movement lines.
        CreateMovementAndVerifyMovementLinesForLot(LocationCode, ItemNo, Bin2.Code, LotNo2[1], Quantity);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingPageHandler,WhseSourceCreateDocumentHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure MovementForMultipleBinsAndItemTrackingWithBlockSNInfo()
    var
        Bin1: Record Bin;
        Bin2: Record Bin;
        Bin3: Record Bin;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LocationCode: Code[10];
        ItemNo: Code[20];
        SerialNo: array[20] of Code[50];
        SerialNo2: array[20] of Code[50];
        Quantity: Integer;
        i: Integer;
    begin
        // Setup: Create Item and put it into Bin1 and Bin2 with different Serial No.
        Initialize();
        PutItemInDifferentBinsWithItemTracking(
          LocationCode, ItemNo, Bin1, Bin2, Bin3, SerialNo, SerialNo2, Quantity, TrackingActionStr::AssignSerialNo);

        // Block Serial Information for Serials which put in Bin1
        for i := 1 to Quantity do
            BlockedSerialNoInformation(ItemNo, SerialNo[i], true);

        // Exercise: Calculate Bin Replenishment and create Movement.
        CalculateBinReplenishment(LocationCode);
        CreateMovement(ItemNo);

        // Verify: Verify the Bin Code and Item Tracking No. is correct of Movement lines.
        FindWarehouseActivityLine2(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Movement, WarehouseActivityLine."Action Type"::Take, ItemNo);
        for i := 1 to Quantity do
            VerifyWarehouseActivityLines(WarehouseActivityLine, Bin2.Code, '', SerialNo2[i], 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure SeveralMarkedItemsCalcPhysInvCntPeriod()
    var
        PhysInvtCountingPeriod: Record "Phys. Invt. Counting Period";
        Item: array[3] of Record Item;
        i: Integer;
    begin
        // [FEATURE] [Physical Inventory] [Counting Period]
        // [SCENARIO] Several marked items should be updated when call UpdateItemPhysInvtCount
        Initialize();

        for i := 1 to 3 do
            CreateItemWithPhysicalInventoryCountingPeriod(Item[i], PhysInvtCountingPeriod);

        // Mark only first and third Item
        Item[1].Mark(true);
        Item[1].Get(Item[3]."No.");
        Item[1].Mark(true);
        Item[1].MarkedOnly(true);
        PhysInvtCountMgt.UpdateItemPhysInvtCount(Item[1]);

        VerifyItemLastCountingPeriodUpdate(Item[1], WorkDate());
        VerifyItemLastCountingPeriodUpdate(Item[2], 0D);
        VerifyItemLastCountingPeriodUpdate(Item[3], WorkDate());
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure SeveralMarkedSKUsCalcPhysInvCntPeriod()
    var
        SKU: array[3] of Record "Stockkeeping Unit";
        i: Integer;
    begin
        // [FEATURE] [Physical Inventory] [Counting Period] [Stockkeeping Unit]
        // [SCENARIO] Several marked items should be updated when call UpdateItemPhysInvtCount
        Initialize();

        for i := 1 to 3 do
            CreateSKUWithPhysInvtCntPeriod(SKU[i]);

        // Mark only first and third SKU
        SKU[1].Mark(true);
        SKU[1].Get(SKU[3]."Location Code", SKU[3]."Item No.", SKU[3]."Variant Code");
        SKU[1].Mark(true);
        SKU[1].MarkedOnly(true);
        PhysInvtCountMgt.UpdateSKUPhysInvtCount(SKU[1]);

        VerifySKULastCountingPeriodUpdate(SKU[1], WorkDate());
        VerifySKULastCountingPeriodUpdate(SKU[2], 0D);
        VerifySKULastCountingPeriodUpdate(SKU[3], WorkDate());
    end;

    [Test]
    [HandlerFunctions('PhysicalInventoryItemSelectionHandler,CalculatePhysicalInventoryCountingHandler')]
    [Scope('OnPrem')]
    procedure LastCountingPeriodUpdateIsSetWhenPostingPhysInvtForTwoItems()
    var
        Item: array[2] of Record Item;
        Location: Record Location;
        PhysInvtCountingPeriod: Record "Phys. Invt. Counting Period";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // [FEATURE] [Physical Inventory] [Counting Period]
        // [SCENARIO 372190] "Last Counting Period Update" field is updated in Item card when posting physical inventory for 2 items in one batch

        // [GIVEN] Two items with physical inventory counting period
        CreateItemWithPhysicalInventoryCountingPeriod(Item[1], PhysInvtCountingPeriod);
        CreateItemWithPhysicalInventoryCountingPeriod(Item[2], PhysInvtCountingPeriod);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Quantity on inventory is greater than zero for both items
        LibraryInventory.PostPositiveAdjustment(Item[1], Location.Code, '', '', 1, WorkDate(), 0);
        LibraryInventory.PostPositiveAdjustment(Item[2], Location.Code, '', '', 1, WorkDate(), 0);

        // [GIVEN] Calculate physical inventory
        CalcPhysInvtDatesAndRunCalculateCountingPeriodInPhysInvtJournal(
          ItemJournalBatch, Item[1]."No." + '|' + Item[2]."No.", Item[1]."Last Counting Period Update",
          PhysInvtCountingPeriod."Count Frequency per Year");

        // [WHEN] Post physical inventory journal
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [THEN] "Last Counting Period Update" = WORKDATE in both items
        Item[1].Find();
        Item[1].TestField("Last Counting Period Update", WorkDate());
        Item[2].Find();
        Item[2].TestField("Last Counting Period Update", WorkDate());
    end;

    [Test]
    [HandlerFunctions('PhysicalInventoryItemSelectionHandler,CalculatePhysicalInventoryCountingHandler')]
    [Scope('OnPrem')]
    procedure LastCountingPeriodUpdateIsSetWhenPostingPhysInvtForTwoSKUs()
    var
        Item: Record Item;
        SKU: array[2] of Record "Stockkeeping Unit";
        PhysInvtCountingPeriod: Record "Phys. Invt. Counting Period";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // [FEATURE] [Physical Inventory] [Counting Period] [Stockkeeping Unit]
        // [SCENARIO 372190] "Last Counting Period Update" field is updated in Stockkeeping Unit card when posting physical inventory for 2 SKUs in one batch

        // [GIVEN] Two stockkeeping units with physical inventory counting period
        CreateSKUWithPhysInvtCntPeriod(SKU[1]);
        CreateSKUWithPhysInvtCntPeriod(SKU[2]);
        PhysInvtCountingPeriod.Get(SKU[2]."Phys Invt Counting Period Code");

        // [GIVEN] Quantity on inventory is greater than zero for both SKUs
        Item.Get(SKU[1]."Item No.");
        LibraryInventory.PostPositiveAdjustment(Item, SKU[1]."Location Code", '', '', 1, WorkDate(), 0);
        Item.Get(SKU[2]."Item No.");
        LibraryInventory.PostPositiveAdjustment(Item, SKU[2]."Location Code", '', '', 1, WorkDate(), 0);

        // [GIVEN] Calculate physical inventory
        CalcPhysInvtDatesAndRunCalculateCountingPeriodInPhysInvtJournal(
          ItemJournalBatch, SKU[1]."Item No." + '|' + SKU[2]."Item No.", SKU[1]."Last Counting Period Update",
          PhysInvtCountingPeriod."Count Frequency per Year");

        // [WHEN] Post physical inventory journal
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [THEN] "Last Counting Period Update" = WORKDATE in both stockkepping units
        SKU[1].Find();
        SKU[1].TestField("Last Counting Period Update", WorkDate());
        SKU[2].Find();
        SKU[2].TestField("Last Counting Period Update", WorkDate());
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CalculateCountingPeriodFromItemCard()
    var
        Item1: Record Item;
        Item2: Record Item;
        PhysInvtCountingPeriod: Record "Phys. Invt. Counting Period";
        ItemCard: TestPage "Item Card";
    begin
        // [FEATURE] [Physical Inventory] [Counting Period]
        // [SCENARIO] Calculate Counting Period from Item Card should take "No." directly from Item card, not from filters set

        // [GIVEN] Item "X" with "Phys Invt Counting Period Code" blank
        LibraryInventory.CreateItem(Item1);

        // [GIVEN] Item "Y" with "Phys Invt Counting Period Code" not blank
        CreateItemWithPhysicalInventoryCountingPeriod(Item2, PhysInvtCountingPeriod);

        // [GIVEN] Set filters on Item Card: "X","Y"
        ItemCard.OpenEdit();
        ItemCard.FILTER.SetFilter("No.", StrSubstNo('%1|%2', Item1."No.", Item2."No."));

        // [WHEN] Run Calculate Counting Period from Item "Y" Card
        ItemCard.GotoRecord(Item2);
        ItemCard.CalculateCountingPeriod.Invoke();

        // [THEN] Counting Period is 0D
        Item2.TestField("Last Counting Period Update", 0D);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandlerWithSerialNo,EnterQuantityToCreateHandler2,MessageHandler,PickSelectionHandler,CreatePickHandler')]
    [Scope('OnPrem')]
    procedure TransferLotTrackedItem()
    var
        Item: Record Item;
        Location: Record Location;
        Location2: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseEntry: Record "Warehouse Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        LotNo: Code[50];
        SerialNo: Code[50];
        Qty: Decimal;
    begin
        // [FEATURE] [Item Tracking] [Lot Specific Tracking]
        // [SCENARIO 136427] Can register Pick for Item With Lot specific tracking and Serial Purchase and Transfer Tracking.

        // [GIVEN] Item with Lot specific tracking including Warehouse Tracking, also SN Transfer Tracking and SN Purchase Tracking.
        Initialize();
        WarehouseSetupShipmentPostingPolicyShowErrorOn();

        CreateLotTrackedItemPartSerialTracked(Item);

        // [GIVEN] Location with Require Receive, Require Shipment and Require Pick.
        PrepareReceiveShipPickLocation(Location);

        // [GIVEN] Purchase Item to Location, assign Serial No and Lot No.
        Qty := 1;
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Location.Code, Item."No.", Qty);
        PurchaseLine.OpenItemTrackingLines();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        PostWarehouseReceipt(PurchaseHeader."No.");

        LotNo :=
          FindWarehouseEntry(
            WarehouseEntry, WarehouseEntry."Entry Type"::"Positive Adjmt.",
            Location."Receipt Bin Code", Item."No.");

        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.FindFirst();
        SerialNo := ItemLedgerEntry."Serial No.";

        // [GIVEN] Create Transfer for Item to simple Location, create Warehouse Shipment, create Pick.
        CreateAndUpdateLocation(Location2, false, false); // To Location
        CreateAndReleaseTransferOrder(TransferHeader, Location.Code, Location2.Code, Item."No.", Qty);
        CreateAndReleaseWarehouseShipmentFromTransferOrder(TransferHeader);
        GetWarehouseDocumentsAndCreatePick();

        // [GIVEN] Set Lot No for Pick lines created.
        SetWhseActivityLinesLotNo(Location.Code, WarehouseActivityHeader.Type::Pick, Item."No.", LotNo);

        // [GIVEN] Also assign a serial no.
        SetWhseActivityLinesSerialNo(Location.Code, WarehouseActivityHeader.Type::Pick, Item."No.", SerialNo);

        // [WHEN] Register Pick.
        RegisterWarehouseActivityHeader(Location.Code, WarehouseActivityHeader.Type::Pick);

        // [THEN] Reqistered successfully and Warehouse Entries for Movement contain Lot No.
        Assert.AreEqual(
          LotNo,
          FindWarehouseEntry(
            WarehouseEntry, WarehouseEntry."Entry Type"::Movement,
            Location."Receipt Bin Code", Item."No."),
          WarehouseEntry.FieldCaption("Lot No."));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler,WhseSourceCreateDocumentHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateMovementFromWorksheetInAdditionalUoM()
    var
        Location: Record Location;
        Zone: Record Zone;
        Bin: Record Bin;
        HighRankingBin: Record Bin;
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        BinContent: Record "Bin Content";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        // [FEATURE] [Warehouse] [Movement] [Bin Replenishment] [Breakbulk]
        // [SCENARIO 375684] Create Movement batch job in Warehouse Worksheet uses unit of measure from source bin content when creating movement activity

        Initialize();

        // [GIVEN] "Directed Put-away and Pick" location with "Pick according to FEFO" and "Allow Breakbulk" enabled
        CreateFullWarehouseSetup(Location);
        UpdateParametersOnLocation(Location, true, false);

        // [GIVEN] Item with lot no. tracking. Base unit of measure "UoM1", additional unit of measure "UoM2"
        CreateItemWithItemTrackingCodeForLot(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 1);

        // [GIVEN] Purchase and put-away item in base unit of measure "UoM1"
        CreateAndRegisterPutAwayFromPurchaseOrder(Location.Code, Item."No.", true);

        // [GIVEN] Bin with empty bin content in additional unit of measure "UoM2". Setup min. bin content quantity, so that it requires replenishment.
        FindZone(Zone, Location.Code);
        FindHighestRankingBin(HighRankingBin, Location.Code);
        CreateBinWithBinRanking(Bin, Location.Code, Zone.Code, LibraryWarehouse.SelectBinType(false, false, true, true), HighRankingBin."Bin Ranking" + 1);

        CreateBinContent(BinContent, Bin, Item, ItemUnitOfMeasure.Code, 1, 1);

        // [GIVEN] Calculate bin replenishment
        CalculateBinReplenishmentForBinContent(Location.Code, BinContent);
        WhseWorksheetLine.SetRange("Location Code", Location.Code);
        WhseWorksheetLine.FindFirst();
        Commit();

        // [WHEN] Create movement from warehouse worksheet
        WhseWorksheetLine.MovementCreate(WhseWorksheetLine);

        // [THEN] Movement activity created. Unit of measure in "Take" action is "UoM1", "Place" action - "UoM2"
        FindWarehouseActivityLine2(
          WhseActivityLine, WhseActivityLine."Activity Type"::Movement, WhseActivityLine."Action Type"::Take, Item."No.");
        WhseActivityLine.TestField("Unit of Measure Code", Item."Base Unit of Measure");
        FindWarehouseActivityLine2(
          WhseActivityLine, WhseActivityLine."Activity Type"::Movement, WhseActivityLine."Action Type"::Place, Item."No.");
        WhseActivityLine.TestField("Unit of Measure Code", ItemUnitOfMeasure.Code);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingPageHandler,ItemTrackingLinesSalesHandler,ItemTrackingSummaryHandler')]
    [Scope('OnPrem')]
    procedure RegenPlanItemTrackingNotUpdatedWhenNoPlanningSuggestionGenerated()
    var
        Item: Record Item;
        Location: Record Location;
        ItemTrackingCode: Record "Item Tracking Code";
        SalesHeader: Record "Sales Header";
        ReservEntry: Record "Reservation Entry";
        Bin: Record Bin;
        WhseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Quantity: Decimal;
        PickQty: Decimal;
    begin
        // [FEATURE] [Item Tracking] [Planning Worksheet] [Warehouse] [Pick]
        // [SCENARIO 375665] Planning worksheet does not change quantity to handle in item tracking entries when no planning suggestion is generated
        Initialize();

        // [GIVEN] Item "I" with Lot No. tracking and lot warehouse tracking
        CreateItemWithItemTrackingCodeForLot(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Modify(true);

        ItemTrackingCode.Get(Item."Item Tracking Code");
        ItemTrackingCode.Validate("Lot Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);
        CreateFullWarehouseSetup(Location);
        FindBin(Bin, Location.Code);

        // [GIVEN] Receive and put away 200 pcs of item "I" with lot no. = "L"
        Quantity := LibraryRandom.RandDecInRange(100, 200, 2);
        PickQty := LibraryRandom.RandInt(10);
        PostWhseJournalPositiveAdjmtWithItemTracking(Bin, Item, Quantity * 2);

        // [GIVEN] Create sales order for 100 pcs of item "I", assign lot no. = "L"
        CreateAndReleaseSalesOrderWithItemTracking(SalesHeader, Item."No.", Quantity, Item."Base Unit of Measure", Location.Code);
        CreatePickFromSalesHeader(SalesHeader);

        // [GIVEN] Pick 7 pcs
        UpdateQuantityToHandleInWarehouseActivityLine(SalesHeader."No.", PickQty);
        RegisterWarehouseActivityHeader(Location.Code, WhseActivityLine."Activity Type"::Pick);

        // [WHEN] Calculate regenerative plan from planning worksheet
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // [THEN] Reservation for the Sales Order has "Qty (Base)" = "Qty. to Handle (Base)" = "Qty. to Invoice (Base)" = -7
        ReservEntry.SetRange("Source Type", DATABASE::"Sales Line");
        ReservEntry.SetRange("Source ID", SalesHeader."No.");
        ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Reservation);
        ReservEntry.FindFirst();
        VerifyReservationEntryQty(ReservEntry, -PickQty, -PickQty, -PickQty);

        // [THEN] Tracking for the Sales Order has "Qty (Base)" = -93; "Qty. to Handle (Base)" = "Qty. to Invoice (Base)" = -7
        ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Tracking);
        ReservEntry.FindFirst();
        VerifyReservationEntryQty(ReservEntry, -(Quantity - PickQty), -PickQty, -PickQty);

        // [WHEN] Post the warehouse shipment.
        PostWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");

        // [THEN] Item tracking for the sales order line has "Qty (Base) = "Qty. to Handle (Base)" = "Qty. to Invoice (Base)" = -93.
        ReservEntry.SetRange("Reservation Status");
        ReservEntry.CalcSums("Quantity (Base)", "Qty. to Handle (Base)", "Qty. to Invoice (Base)");
        VerifyReservationEntryQty(ReservEntry, -(Quantity - PickQty), -(Quantity - PickQty), -(Quantity - PickQty));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler2,ItemTrackingSummaryHandler')]
    [Scope('OnPrem')]
    procedure WhseGetBinContentWithExistingPick()
    var
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        Quantity: Decimal;
    begin
        // [FEATURE] [Item Tracking] [Item Reclassification Journal] [Warehouse] [Pick]
        // [SCENARIO 378299] Can 'Get Bin Contents' for Tracked Item in Reclassification Journal if Pick exists.

        // [GIVEN] Create Lot Tracked Item, Quantity "Q" of Lot "L" available in Location with Bins.
        Initialize();
        PrepareReceiveShipPickLocation(Location);
        CreateItemWithItemTrackingCodeForLot(Item);
        Quantity := 2 * LibraryRandom.RandInt(100);
        LibraryVariableStorage.Enqueue(TrackingActionStr::AssignLotNo); // For ItemTrackingLinesHandler2
        CreateAndPostItemJournalLineWithItemTracking(Item."No.", Location.Code, Location."Receipt Bin Code", Quantity);

        // [GIVEN] Create Sales Order of Lot "L" and Quantity "Q" / 2, create Whse. Shipment and Pick.
        LibraryVariableStorage.Enqueue(TrackingActionStr::SelectEntries); // For ItemTrackingLinesHandler2
        CreateAndReleaseSalesOrderWithItemTracking(
          SalesHeader, Item."No.", Quantity / 2, Item."Base Unit of Measure", Location.Code);
        CreatePickFromSalesHeader(SalesHeader);

        // [WHEN] Open Item Reclassification Journal, run "Get Bin Contents".
        RunWarehouseGetBinContentReport(Location.Code, Item."No.", Location."Receipt Bin Code");

        // [THEN] Item Reclassification Journal Quantity = "Q" / 2.
        VerifyQuantityInItemReclassification(Item."No.", Location.Code, Location."Receipt Bin Code", Quantity / 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseGetBinContentPopulatesPostingNoSeries()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        NoSeries: Record "No. Series";
        BinCode: Code[20];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Item Reclassification Journal] [Get Bin Content]
        // [SCENARIO 234112] "Get Bin Content" function in reclassification journal copies "Posted No. Series" from the journal batch.
        Initialize();

        // [GIVEN] Item "I".
        ItemNo := LibraryInventory.CreateItemNo();

        // [GIVEN] WMS location with bin "B".
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        BinCode := AddBin(Location.Code);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Post positive inventory adjustment of item "I" into bin "B".
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, ItemNo, Location.Code, BinCode, LibraryRandom.RandInt(10));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] New item journal batch in reclassification journal template.
        // [GIVEN] "Posting No. Series" code in the batch = "X".
        LibraryUtility.CreateNoSeries(NoSeries, false, false, false);
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalTemplate.Type::Transfer);
        ItemJournalBatch.Validate("Posting No. Series", NoSeries.Code);
        ItemJournalBatch.Modify(true);

        // [WHEN] Open the new batch in the reclassification journal and run "Get Bin Content" filtered by bin "B".
        GetBinContentFromItemJournalLine(ItemJournalBatch, Location.Code, BinCode, ItemNo);

        // [THEN] A new line is created in the batch with "Posting No. Series" code = "X".
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch, ItemNo);
        ItemJournalLine.TestField("Posting No. Series", ItemJournalBatch."Posting No. Series");
    end;

    [Test]
    [HandlerFunctions('PhysicalInventoryItemSelectionHandler,CalculatePhysicalInventoryCountingHandler')]
    [Scope('OnPrem')]
    procedure CalculateCountingPeriodShowsOverdueItems()
    var
        Item: Record Item;
        PhysInvtCountingPeriod: Record "Phys. Invt. Counting Period";
        ItemJournalBatch: Record "Item Journal Batch";
        PhysInvtCountManagement: Codeunit "Phys. Invt. Count.-Management";
        NextCountingStartDate: Date;
        NextCountingEndDate: Date;
    begin
        // [FEATURE] [Item] [Physical Inventory] [Counting Period]
        // [SCENARIO 209449] Calculate Counting Period function should show items for which phys. inventory is overdue.
        Initialize();

        // [GIVEN] Weekly (52 times a year) phys. inventory counting period "CP".
        LibraryInventory.CreatePhysicalInventoryCountingPeriod(PhysInvtCountingPeriod);
        PhysInvtCountingPeriod.Validate("Count Frequency per Year", 52);
        PhysInvtCountingPeriod.Modify(true);

        // [GIVEN] Item "I" with "CP" counting period with last phys. inventory date earlier than a week ago, so its next counting period is overdue on WORKDATE.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Phys Invt Counting Period Code", PhysInvtCountingPeriod.Code);
        PhysInvtCountManagement.CalcPeriod(
          WorkDate() - LibraryRandom.RandIntInRange(10, 20), NextCountingStartDate, NextCountingEndDate,
          PhysInvtCountingPeriod."Count Frequency per Year");
        Item.Validate("Next Counting Start Date", NextCountingStartDate);
        Item.Validate("Next Counting End Date", NextCountingEndDate);
        Item.Modify(true);

        // [WHEN] Run Calculate Counting Period function in Phys. Inventory journal.
        LibraryVariableStorage.Enqueue(Item."No.");
        LibraryVariableStorage.Enqueue(NextCountingStartDate);
        LibraryVariableStorage.Enqueue(NextCountingEndDate);
        RunCalculateCountingPeriodFromPhysicalInventoryJournal(ItemJournalBatch);

        // [THEN] Item "I" is shown on the list of items for the next phys. inventory.
        // The verification is done in PhysicalInventoryItemSelectionHandler.
    end;

    [Test]
    [HandlerFunctions('PhysicalInventoryItemSelectionHandler,CalculatePhysicalInventoryCountingHandler')]
    [Scope('OnPrem')]
    procedure CalculateCountingPeriodShowsOverdueSKU()
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
        PhysInvtCountingPeriod: Record "Phys. Invt. Counting Period";
        ItemJournalBatch: Record "Item Journal Batch";
        PhysInvtCountManagement: Codeunit "Phys. Invt. Count.-Management";
        NextCountingStartDate: Date;
        NextCountingEndDate: Date;
    begin
        // [FEATURE] [Stockkeeping Unit] [Physical Inventory] [Counting Period]
        // [SCENARIO 211455] Calculate Counting Period function should show stockkeeping units for which phys. inventory is overdue.
        Initialize();

        // [GIVEN] Weekly (52 times a year) phys. inventory counting period "CP".
        LibraryInventory.CreatePhysicalInventoryCountingPeriod(PhysInvtCountingPeriod);
        PhysInvtCountingPeriod.Validate("Count Frequency per Year", 52);
        PhysInvtCountingPeriod.Modify(true);

        // [GIVEN] Stockkeeping Unit "SKU" with "CP" counting period with last phys. inventory date earlier than a week ago, so its next counting period is overdue on WORKDATE.
        CreateStockKeepingUnit(StockkeepingUnit);
        StockkeepingUnit.Validate("Phys Invt Counting Period Code", PhysInvtCountingPeriod.Code);
        PhysInvtCountManagement.CalcPeriod(
          WorkDate() - LibraryRandom.RandIntInRange(10, 20), NextCountingStartDate, NextCountingEndDate,
          PhysInvtCountingPeriod."Count Frequency per Year");
        StockkeepingUnit.Validate("Next Counting Start Date", NextCountingStartDate);
        StockkeepingUnit.Validate("Next Counting End Date", NextCountingEndDate);
        StockkeepingUnit.Modify(true);

        // [WHEN] Run Calculate Counting Period function in Phys. Inventory journal.
        LibraryVariableStorage.Enqueue(StockkeepingUnit."Item No.");
        LibraryVariableStorage.Enqueue(NextCountingStartDate);
        LibraryVariableStorage.Enqueue(NextCountingEndDate);
        RunCalculateCountingPeriodFromPhysicalInventoryJournal(ItemJournalBatch);

        // [THEN] "SKU" is shown on the list of stockkeeping units for the next phys. inventory.
        // The verification is done in PhysicalInventoryItemSelectionHandler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PositiveAdjmtQtyInBinContentCalculatedRegardlessOfWhseJournalEntryType()
    var
        BinContentFrom: Record "Bin Content";
        BinContentTo: Record "Bin Content";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        i: Integer;
    begin
        // [FEATURE] [Bin Content] [Warehouse Journal] [UT]
        // [SCENARIO 209800] "Pos. Adjmt. Qty" and "Positive Adjmt. Qty. (Base)" fields in Bin Content should be equal to the sum of Whse. Journal Lines with matching "To Bin Code", regardless of their "Entry Type".
        Initialize();

        // [GIVEN] Two bin contents "B1" and "B2" with same location, item, variant and unit of measure, but different bin codes.
        MockBinContent(BinContentFrom);
        CopyBinContent(BinContentTo, BinContentFrom);

        // [GIVEN] Warehouse journal lines "WJL" of all entry types with "To Bin Code" = "B2"."Bin Code".
        for i := WarehouseJournalLine."Entry Type"::"Negative Adjmt." to WarehouseJournalLine."Entry Type"::Movement do
            MockWarehouseJournalLine(WarehouseJournalLine, BinContentFrom, BinContentTo, i);

        // [WHEN] Calculate flow fields on "B2".
        BinContentTo.CalcFields("Pos. Adjmt. Qty.", "Positive Adjmt. Qty. (Base)");

        // [THEN] "B2"."Pos. Adjmt Qty." = sum of "WJL"."Qty. (Absolute)".
        // [THEN] "B2"."Positive Adjmt. Qty. (Base)" = sum of "WJL"."Qty. (Absolute, Base)".
        WarehouseJournalLine.SetRange("To Bin Code", BinContentTo."Bin Code");
        WarehouseJournalLine.CalcSums("Qty. (Absolute)", "Qty. (Absolute, Base)");
        BinContentTo.TestField("Pos. Adjmt. Qty.", WarehouseJournalLine."Qty. (Absolute)");
        BinContentTo.TestField("Positive Adjmt. Qty. (Base)", WarehouseJournalLine."Qty. (Absolute, Base)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NegativeAdjmtQtyInBinContentCalculatedRegardlessOfWhseJournalEntryType()
    var
        BinContentFrom: Record "Bin Content";
        BinContentTo: Record "Bin Content";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        i: Integer;
    begin
        // [FEATURE] [Bin Content] [Warehouse Journal] [UT]
        // [SCENARIO 209800] "Neg. Adjmt. Qty" and "Negative Adjmt. Qty. (Base)" fields in Bin Content should be equal to the sum of Whse. Journal Lines with matching "From Bin Code", regardless of their "Entry Type".
        Initialize();

        // [GIVEN] Two bin contents "B1" and "B2" with same location, item, variant and unit of measure, but different bin codes.
        MockBinContent(BinContentFrom);
        CopyBinContent(BinContentTo, BinContentFrom);

        // [GIVEN] Several warehouse journal lines "WJL" of all entry types with "From Bin Code" = "B1"."Bin Code".
        for i := WarehouseJournalLine."Entry Type"::"Negative Adjmt." to WarehouseJournalLine."Entry Type"::Movement do
            MockWarehouseJournalLine(WarehouseJournalLine, BinContentFrom, BinContentTo, i);

        // [WHEN] Calculate flow fields on "B1".
        BinContentFrom.CalcFields("Neg. Adjmt. Qty.", "Negative Adjmt. Qty. (Base)");

        // [THEN] "B1"."Neg. Adjmt Qty." = sum of "WJL"."Qty. (Absolute)".
        // [THEN] "B1"."Negative Adjmt. Qty. (Base)" = sum of "WJL"."Qty. (Absolute, Base)".
        WarehouseJournalLine.SetRange("From Bin Code", BinContentFrom."Bin Code");
        WarehouseJournalLine.CalcSums("Qty. (Absolute)", "Qty. (Absolute, Base)");
        BinContentFrom.TestField("Neg. Adjmt. Qty.", WarehouseJournalLine."Qty. (Absolute)");
        BinContentFrom.TestField("Negative Adjmt. Qty. (Base)", WarehouseJournalLine."Qty. (Absolute, Base)");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure WhsePickDecreasesAvailQtyToTakeFromBinViaWhseJournal()
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        SalesLine: Record "Sales Line";
        WhseReclassificationJournal: TestPage "Whse. Reclassification Journal";
    begin
        // [FEATURE] [Reclassification Journal] [Warehouse Pick] [Bin Content]
        // [SCENARIO 209800] Quantity in warehouse pick should not be available for moving to another bin via warehouse journal.
        Initialize();

        // [GIVEN] Item "I" is purchased and placed into bin "B1" on WMS-location.
        // [GIVEN] Released sales order for the purchased quantity of item "I".
        // [GIVEN] Warehouse shipment and pick for the sales order.
        CreateInitialSetupForPick(SalesLine);
        FindWarehouseShipmentHeader(
          WarehouseShipmentHeader, SalesLine."Document No.", WarehouseShipmentLine."Source Document"::"Sales Order");
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // [GIVEN] Warehouse Journal Line is created with a purpose to move part of quantity of "I" from bin "B1" to bin "B2".
        CreateWarehouseReclassJournal(WhseReclassificationJournal, SalesLine."No.", SalesLine."Location Code", LibraryRandom.RandInt(5));

        // [WHEN] Try to register the warehouse journal.
        asserterror WhseReclassificationJournal.Register.Invoke();

        // [THEN] Error message is thrown. The item is not available.
        Assert.ExpectedError(StrSubstNo(QtyNotAvailableTxt, WhseReclassificationJournal.Quantity));
    end;

    [Test]
    [HandlerFunctions('WhseSourceCreateDocumentHandler,WhseItemTrackingPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure WhseMovementForBinReplenishmentByFEFO()
    var
        Location: Record Location;
        BinContent: Record "Bin Content";
        Item: Record Item;
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LotNos: array[2] of Code[20];
        i: Integer;
    begin
        // [FEATURE] [Movement] [FEFO] [Bin Replenishment] [Item Tracking]
        // [SCENARIO 222190] FEFO order should be respected when warehouse movement is created to replenish lot quantity in bin from which a warehouse pick line exists.
        Initialize();

        // [GIVEN] "Directed Put-away and Pick" location with "Pick according to FEFO".
        CreateFullWarehouseSetup(Location);
        UpdateParametersOnLocation(Location, true, false);

        // [GIVEN] Lot-tracked item. Lot Nos. = "L1" and "L2".
        CreateItemWithItemTrackingCodeForLot(Item);
        for i := 1 to ArrayLen(LotNos) do
            LotNos[i] := LibraryUtility.GenerateGUID();

        // [GIVEN] Bin "B1" with high ranking is created on the location.
        // [GIVEN] Minimum quantity is set to 100, maximum quantity is set to 200 in the bin content for "B1".
        // [GIVEN] "B1" contains 50 pcs of lot "L1" with expiration date "D1".
        // [GIVEN] Since the minimum and maximum values are set, "B1" requires replenishment to its maximum value, that is, for 150 pcs.
        CreateBinAndRegisterWhseAdjustment(
          BinContent, Item, Location.Code, LotNos[1], 50, 100, 100, 200, WorkDate() + 1);

        // [GIVEN] Bin "B2" with low ranking is created on the location.
        // [GIVEN] "B2" contains 100 pcs of lot "L1" with expiration date "D1".
        CreateBinAndRegisterWhseAdjustment(
          BinContent, Item, Location.Code, LotNos[1], 100, 10, 0, 0, WorkDate() + 1);

        // [GIVEN] Bin "B3" with low ranking is created on the location.
        // [GIVEN] "B3" contains 100 pcs of lot "L2" with expiration date "D2" > "D1".
        CreateBinAndRegisterWhseAdjustment(
          BinContent, Item, Location.Code, LotNos[2], LibraryRandom.RandIntInRange(100, 200), 10, 0, 0, WorkDate() + 2);

        // [GIVEN] Post warehouse adjustment in the item ledger.
        CalculateAndPostWarehouseAdjustment(Item);

        // [GIVEN] Warehouse Pick for 50 pcs of lot "L1" from "B1" is created.
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, Item."No.", Location.Code, 50);
        CreatePickFromSalesHeader(SalesHeader);

        // [GIVEN] Bin replenishment is calculated in warehouse worksheet.
        CalculateBinReplenishmentForBinContent(Location.Code, BinContent);
        WhseWorksheetLine.SetRange("Location Code", Location.Code);
        WhseWorksheetLine.FindFirst();
        Commit();

        // [WHEN] Create movement from the warehouse worksheet.
        WhseWorksheetLine.MovementCreate(WhseWorksheetLine);

        // [THEN] Movement line for 100 pcs of lot "L1" is created.
        FindWarehouseActivityLine2(
          WhseActivityLine, WhseActivityLine."Activity Type"::Movement, WhseActivityLine."Action Type"::Take, Item."No.");
        WhseActivityLine.SetRange("Lot No.", LotNos[1]);
        WhseActivityLine.CalcSums("Qty. Outstanding (Base)");
        WhseActivityLine.TestField("Qty. Outstanding (Base)", 100);

        // [THEN] Movement line for 50 pcs of lot "L2" is created.
        WhseActivityLine.SetRange("Lot No.", LotNos[2]);
        WhseActivityLine.CalcSums("Qty. Outstanding (Base)");
        WhseActivityLine.TestField("Qty. Outstanding (Base)", 50);

        // The queue with stored variables is empty.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CalculateBinReplenishmentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalculateBinReplenishmentReportIsRunDirectly()
    var
        Bin: array[2] of Record Bin;
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        // [FEATURE] [Bin Replenishment]
        // [SCENARIO 233088] Calculate Bin Replenishment report can be run directly, not only from movement worksheet. That makes it possible to run the report on schedule using Job Queue functionality.
        Initialize();

        // [GIVEN] Location "L" with directed put-away and pick.
        // [GIVEN] Post whse. positive adjustment in a bin "B1" with lower ranking.
        // [GIVEN] Create bin "B2" with higher ranking and minimum quantity, so it requires a replenishment.
        CreateInitialSetupForBinReplenishment(Bin[1], Bin[2], WarehouseJournalLine);

        // [GIVEN] Movement worksheet template "MT", movement worksheet name "MN".
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Movement);
        LibraryWarehouse.SelectWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, WarehouseJournalLine."Location Code");

        // [WHEN] Run "Calculate Bin Replenishment" report and select Location Code = "L", worksheet template name = "MT", worksheet name = "MN" on the request page.
        Commit();
        LibraryVariableStorage.Enqueue(WarehouseJournalLine."Location Code");
        LibraryVariableStorage.Enqueue(WhseWorksheetTemplate.Name);
        LibraryVariableStorage.Enqueue(WhseWorksheetName.Name);
        REPORT.Run(REPORT::"Calculate Bin Replenishment", true);

        // [THEN] Movement worksheet line for replenishment bin "B2" from bin "B1" is created.
        FindWarehouseWorksheetLine(WhseWorksheetLine, WarehouseJournalLine."Item No.");
        WhseWorksheetLine.TestField("From Bin Code", Bin[1].Code);
        WhseWorksheetLine.TestField("To Bin Code", Bin[2].Code);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CalculateBinReplenishmentTestRequestPageHandler,WorksheetNamesListModalPageHandler')]
    [Scope('OnPrem')]
    procedure CalculateBinReplenishmentReportTestRequestPageFields()
    var
        Location: Record Location;
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
    begin
        // [FEATURE] [Bin Replenishment] [UI]
        // [SCENARIO 233088] You can select Worksheet Name on request page in Calculate Bin Replenishment report after you select Worksheet Template and location code. When you clear Worksheet Template, Worksheet Name is also cleared.
        Initialize();

        // [GIVEN] Directed put-away and pick location "L"
        CreateFullWarehouseSetup(Location);

        // [GIVEN] Worksheet Template "WT" and Worksheet Name "WN".
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Movement);
        LibraryWarehouse.SelectWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, Location.Code);

        // [WHEN] Select "L" and "WT" on the request page in Calculate Bin Replenishment report and look up list of worksheet names.
        Commit();
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(Location.Code);
        LibraryVariableStorage.Enqueue(WhseWorksheetTemplate.Name);
        REPORT.Run(REPORT::"Calculate Bin Replenishment", true);

        // [THEN] Worksheet Name "WN" is selected on the request page.
        Assert.AreEqual(
          WhseWorksheetName.Name, LibraryVariableStorage.DequeueText(),
          'Worksheet Name is not selected on the request page.');

        // [WHEN] Clear Worksheet Template Name on the request page.
        LibraryVariableStorage.Enqueue(2);
        LibraryVariableStorage.Enqueue(Location.Code);
        LibraryVariableStorage.Enqueue(WhseWorksheetTemplate.Name);
        LibraryVariableStorage.Enqueue(WhseWorksheetName.Name);
        REPORT.Run(REPORT::"Calculate Bin Replenishment", true);

        // [THEN] Worksheet Name is also cleared.
        Assert.AreEqual(
          '', LibraryVariableStorage.DequeueText(),
          'Worksheet Name is not cleared after Worksheet Template Name is cleared on the request page.');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler2,WhseItemTrackingLinesModalPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure BinContentCheckDecreaseLocationAlwaysPickWhseJournalDiffLot()
    var
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        ToBin: Record Bin;
        WarehouseJournalLine: Record "Warehouse Journal Line";
        LotNo: array[2] of Code[20];
        Quantity: Decimal;
    begin
        // [FEATURE] [Warehouse Journal]
        // [SCENARIO 254484] Decrease quantity in bin is checked according to lot no. when post warehouse journal.
        Initialize();

        Quantity := LibraryRandom.RandInt(10);
        LotNo[1] := LibraryUtility.GenerateGUID() + LibraryUtility.GenerateGUID();
        LotNo[2] := LibraryUtility.GenerateGUID() + LibraryUtility.GenerateGUID();

        // [GIVEN] Location "L" with Always Create Pick on
        CreateFullWarehouseSetup(Location);
        FindPutawayPickBin(Bin, Location.Code);
        FindAnotherBinInZone(ToBin, Bin);

        // [GIVEN] Item "I" with tracking code for lot
        CreateItemWithItemTrackingCodeForLot(Item);

        // [GIVEN] Inventory of "I" at "L" is quantity "Q" of lot "N" and some quantity of lot "M"
        UpdateInventoryInBinUsingWhseJournalWithLotNo(Bin, Item."No.", Quantity, LotNo[1]);
        UpdateInventoryInBinUsingWhseJournalWithLotNo(Bin, Item."No.", Quantity, LotNo[2]);

        // [GIVEN] Sales order of "I" at "L", lot "M" with some big insuficient quantity
        CreateSalesOrderWithPick(
          Item."No.", Location.Code, Bin."Zone Code", Bin.Code, LibraryRandom.RandIntInRange(1000, 2000), LotNo[1]);

        // [GIVEN] Warehouse journal line "J", movement of "I" at "L", quantity "Q" of lot "N"
        CreateMovementWarehouseJournalLine(WarehouseJournalLine, Bin, ToBin, Item."No.", Quantity, LotNo[2]);

        // [WHEN] Register "J"
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name",
          WarehouseJournalLine."Location Code", true);

        // [THEN] No errors occur and last "Warehouse Entry" has "Item No." = "I", Quantity = "Q" and "Lot No." = "N"
        VerifyLastWarehouseEntry(Item."No.", Quantity, LotNo[2]);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler2,WhseItemTrackingLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure BinContentCheckDecreaseWhseJournalSameLotSameQuantity()
    var
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        ToBin: Record Bin;
        WarehouseJournalLine: Record "Warehouse Journal Line";
        LotNo: Code[50];
        Quantity: Decimal;
    begin
        // [FEATURE] [Warehouse Journal] [Item Tracking]
        // [SCENARIO 254484] Post warehouse journal when stock assigned to an existing pick with lot tracking
        Initialize();
        WarehouseSetupShipmentPostingPolicyShowErrorOn();

        Quantity := LibraryRandom.RandInt(10);
        LotNo := LibraryUtility.GenerateGUID() + LibraryUtility.GenerateGUID();

        // [GIVEN] Location "L" bin mandatory, requires pick
        CreateFullWarehouseSetup(Location);
        FindPutawayPickBin(Bin, Location.Code);
        FindAnotherBinInZone(ToBin, Bin);

        // [GIVEN] Item "I" with tracking code for lot
        CreateItemWithItemTrackingCodeForLot(Item);

        // [GIVEN] Inventory of "I" at "L" with quantity "Q" and lot "N"
        UpdateInventoryInBinUsingWhseJournalWithLotNo(Bin, Item."No.", Quantity, LotNo);

        // [GIVEN] Sales order of "I" at "L", lot "N" with quantity "Q"
        CreateSalesOrderWithPick(
          Item."No.", Location.Code, Bin."Zone Code", Bin.Code, Quantity, LotNo);

        // [GIVEN] Warehouse journal line "J", movement of "I" at "L", quantity "Q" of lot "N"
        CreateMovementWarehouseJournalLine(WarehouseJournalLine, Bin, ToBin, Item."No.", Quantity, LotNo);

        // [WHEN] Register "J"
        asserterror LibraryWarehouse.RegisterWhseJournalLine(
            WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name",
            WarehouseJournalLine."Location Code", true);

        // [THEN] Error "Quantity (Base) available must not be less than ..." occurs
        Assert.ExpectedError(QuantityBaseAvailableMustNotBeLessThanErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinContentCheckDecreaseLocationAlwaysPickWhseJournalNoLotSameQuantity()
    var
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        ToBin: Record Bin;
        WarehouseJournalLine: Record "Warehouse Journal Line";
        Quantity: Decimal;
    begin
        // [FEATURE] [Warehouse Journal]
        // [SCENARIO 254484] Post warehouse journal when stock assigned to an existing pick.
        Initialize();

        Quantity := LibraryRandom.RandInt(10);

        // [GIVEN] Location "L" with Always Create Pick on
        CreateFullWarehouseSetup(Location);
        FindPutawayPickBin(Bin, Location.Code);
        FindAnotherBinInZone(ToBin, Bin);

        // [GIVEN] Item "I" without tracking
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Inventory of "I" at "L" is quantity "Q"
        LibraryWarehouse.UpdateInventoryInBinUsingWhseJournal(Bin, Item."No.", Quantity, false);

        // [GIVEN] Sales order of "I" at "L", with quantity "Q"
        CreateSalesOrderWithPick(
          Item."No.", Location.Code, Bin."Zone Code", Bin.Code, Quantity, '');

        // [GIVEN] Warehouse journal line "J", movement of "I" at "L", quantity "Q"
        CreateMovementWarehouseJournalLine(WarehouseJournalLine, Bin, ToBin, Item."No.", Quantity, '');

        // [WHEN] Register "J"
        asserterror LibraryWarehouse.RegisterWhseJournalLine(
            WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name",
            WarehouseJournalLine."Location Code", true);

        // [THEN] Error "Quantity (Base) available must not be less than ..." occurs
        Assert.ExpectedError(QuantityBaseAvailableMustNotBeLessThanErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingPageHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure RegisteringWhseReclassJournalWithFilterLikeLotAndSerialNo()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        Location: Record Location;
        BinContent: Record "Bin Content";
        WhseReclassificationJournal: TestPage "Whse. Reclassification Journal";
        NewBinCode: Code[20];
        LotNo: Code[50];
        SerialNo: Code[50];
    begin
        // [FEATURE] [Whse. Reclassification Journal] [Item Tracking]
        // [SCENARIO 280754] Whse. reclassification journal can be registered when serial no. and lot no. in item tracking have filter-like codes.
        Initialize();

        // [GIVEN] Lot "L" and serial no. "S", having codes with filter symbols (*,|,(,),..).
        LotNo := '(|**|||*()';
        SerialNo := '(*))..|..**';

        // [GIVEN] Lot and serial no. tracked item.
        CreateItemTrackingCodeWithExpirDateSetup(ItemTrackingCode, true, true, false, false);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify(true);

        // [GIVEN] The item is in inventory in bin "B1" on location with directed put-away and pick.
        // [GIVEN] Lot No. = "L", serial no. = "S".
        CreateFullWarehouseSetup(Location);
        LibraryVariableStorage.Enqueue(TrackingActionStr::AssignGivenLotAndSerialNo);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(SerialNo);
        LibraryWarehouse.UpdateInventoryOnLocationWithDirectedPutAwayAndPick(Item."No.", Location.Code, 1, true);

        // [GIVEN] Create warehouse reclassification journal in order to move the item from bin "B1" to bin "B2".
        // [GIVEN] Select lot and serial no. on the whse. reclassification journal line.
        CreateWarehouseReclassJournal(WhseReclassificationJournal, Item."No.", Location.Code, 1);
        LibraryVariableStorage.Enqueue(TrackingActionStr::AssignGivenLotAndSerialNo);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(SerialNo);
        WhseReclassificationJournal.ItemTrackingLines.Invoke();

        // [WHEN] Register the reclassification.
        NewBinCode := WhseReclassificationJournal."To Bin Code".Value();
        WhseReclassificationJournal.Register.Invoke();

        // [THEN] The reclassification journal has been successfully registered.
        // [THEN] The item is moved to bin "B2".
        BinContent.Get(Location.Code, NewBinCode, Item."No.", '', Item."Base Unit of Measure");
        BinContent.SetRange("Lot No. Filter", LotNo);
        BinContent.SetRange("Serial No. Filter", SerialNo);
        BinContent.CalcFields(Quantity);
        BinContent.TestField(Quantity, 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingPageHandler,WhseSourceCreateDocumentHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BreakbulkOnCreateMovementAtLocationFEFO()
    var
        Location: Record Location;
        BinFrom: Record Bin;
        BinTo: Record Bin;
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        QuantityToMove: Integer;
    begin
        // [FEATURE] [Movement] [Breakbulk] [FEFO]
        // [SCENARIO 284878] Creating Movement from Movement Worksheet with Breakbulk produces correct movement when FEFO results in multiple pick and place breakbulk lines
        Initialize();

        // [GIVEN] "Directed Put-away and Pick" location with "Pick according to FEFO" and "Allow Breakbulk" enabled
        CreateFullWarehouseSetup(Location);
        Location.Validate("Pick According to FEFO", true);
        Location.Modify();

        // [GIVEN] BinFrom with ranking = "X"
        FindBin(BinFrom, Location.Code);
        UpdateBinRankingOnBin(BinFrom, LibraryRandom.RandInt(100));

        // [GIVEN] BinTo with ranking "X"+1
        FindAnotherBinInZone(BinTo, BinFrom);
        UpdateBinRankingOnBin(BinTo, BinFrom."Bin Ranking" + 1);

        // [GIVEN] Item with Lot No. tracking. with Base Unit of Measure = "UoM1"
        CreateItemWithItemTrackingCodeForLot(Item);

        // [GIVEN] Additional Unit of Measure = "UoM2" for Item. Qty. per Unit of Measure = "Y"
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandIntInRange(5, 100));

        // [GIVEN] Lot1 and Lot2 for Item with "UoM2" and Quantity = 1 were created and released and posted
        CreateAndRegisterWhseJnlLineWithLotAndUoM(BinFrom, Item."No.", LibraryUtility.GenerateGUID(), 1, ItemUnitOfMeasure.Code);
        CreateAndRegisterWhseJnlLineWithLotAndUoM(BinFrom, Item."No.", LibraryUtility.GenerateGUID(), 1, ItemUnitOfMeasure.Code);
        LibraryWarehouse.PostWhseAdjustment(Item);

        // [GIVEN] Movement Worksheet Line was created with parameters to produce two breakbulk pick and two breakbulk put lines ("Y" < Quantity <= 2*"Y")
        QuantityToMove := LibraryRandom.RandIntInRange(
            ItemUnitOfMeasure."Qty. per Unit of Measure" + 1, ItemUnitOfMeasure."Qty. per Unit of Measure" * 2);
        CreateMovementWorksheetLine(WhseWorksheetLine, Location.Code, Item."No.", Item."Base Unit of Measure", BinTo.Code, QuantityToMove);

        Commit();

        // [WHEN] Movement is created for this item via "Create Movement" button
        WhseWorksheetLine.MovementCreate(WhseWorksheetLine);
        // Handled by WhseSourceCreateDocumentHandler and MessageHandler

        // [THEN] Activity with Type = Movement for this Location is created
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        WarehouseActivityHeader.SetRange(Type, WarehouseActivityHeader.Type::Movement);
        WarehouseActivityHeader.FindFirst();

        // [THEN] Movement contains 2 Take lines with Unit of Measure = "UoM2" for this BinFrom (breakbulk)
        VerifyWarehouseActivityLineCount(
          WarehouseActivityHeader."No.", BinFrom.Code, WarehouseActivityLine."Action Type"::Take, ItemUnitOfMeasure.Code, 2);

        // [THEN] Movement contains 2 Place lines with Unit of Measure = "UoM1" for this BinFrom (breakbulk)
        VerifyWarehouseActivityLineCount(
          WarehouseActivityHeader."No.", BinFrom.Code, WarehouseActivityLine."Action Type"::Place, Item."Base Unit of Measure", 2);

        // [THEN] Movement contains 2 Take lines with Unit of Measure = "UoM1" for this BinFrom (actual movement)
        VerifyWarehouseActivityLineCount(
          WarehouseActivityHeader."No.", BinFrom.Code, WarehouseActivityLine."Action Type"::Take, Item."Base Unit of Measure", 2);

        // [THEN] Movement contains 2 Place lines with Unit of Measure = "UoM1" for this BinTo (actual movement)
        VerifyWarehouseActivityLineCount(
          WarehouseActivityHeader."No.", BinTo.Code, WarehouseActivityLine."Action Type"::Place, Item."Base Unit of Measure", 2);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingPageHandler,WhseSourceCreateDocumentHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BreakbulkOnCreateMovementFromSeparateLots()
    var
        Location: Record Location;
        BinFrom: Record Bin;
        BinTo: Record Bin;
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        QuantityToMove: Integer;
    begin
        // [FEATURE] [Movement] [Breakbulk]
        // [SCENARIO 284878] Creating Movement from Movement Worksheet with Breakbulk produces correct movement when there are multiple lots of an item
        Initialize();

        // [GIVEN] "Directed Put-away and Pick" location with "Allow Breakbulk" enabled and "Pick according to FEFO" disabled
        CreateFullWarehouseSetup(Location);

        // [GIVEN] BinFrom with ranking = "X"
        FindBin(BinFrom, Location.Code);
        UpdateBinRankingOnBin(BinFrom, LibraryRandom.RandInt(100));

        // [GIVEN] BinTo with ranking "X"+1
        FindAnotherBinInZone(BinTo, BinFrom);
        UpdateBinRankingOnBin(BinTo, BinFrom."Bin Ranking" + 1);

        // [GIVEN] Item with Lot No. tracking. with Base Unit of Measure = "UoM1"
        CreateItemWithItemTrackingCodeForLot(Item);

        // [GIVEN] Additional Unit of Measure = "UoM2" for Item. Qty. per Unit of Measure = "Y"
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandIntInRange(5, 100));

        // [GIVEN] Lot1 and Lot2 for Item with "UoM2" and Quantity = 1 were created and released and posted
        CreateAndRegisterWhseJnlLineWithLotAndUoM(BinFrom, Item."No.", LibraryUtility.GenerateGUID(), 1, ItemUnitOfMeasure.Code);
        CreateAndRegisterWhseJnlLineWithLotAndUoM(BinFrom, Item."No.", LibraryUtility.GenerateGUID(), 1, ItemUnitOfMeasure.Code);
        LibraryWarehouse.PostWhseAdjustment(Item);

        // [GIVEN] Movement Worksheet Line was created with parameters to take breakbulk from 2 different lots ("Y" < Quantity <= 2*"Y")
        QuantityToMove := LibraryRandom.RandIntInRange(
            ItemUnitOfMeasure."Qty. per Unit of Measure" + 1, ItemUnitOfMeasure."Qty. per Unit of Measure" * 2);
        CreateMovementWorksheetLine(WhseWorksheetLine, Location.Code, Item."No.", Item."Base Unit of Measure", BinTo.Code, QuantityToMove);

        Commit();

        // [WHEN] Movement is created for this item via "Create Movement" button
        WhseWorksheetLine.MovementCreate(WhseWorksheetLine);
        // Handled by WhseSourceCreateDocumentHandler and MessageHandler

        // [THEN] Activity with Type = Movement for this Location is created
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        WarehouseActivityHeader.SetRange(Type, WarehouseActivityHeader.Type::Movement);
        WarehouseActivityHeader.FindFirst();

        // [THEN] Movement contains exactly 1 Take line with Unit of Measure = "UoM2" for this BinFrom (breakbulk)
        VerifyWarehouseActivityLineCount(
          WarehouseActivityHeader."No.", BinFrom.Code, WarehouseActivityLine."Action Type"::Take, ItemUnitOfMeasure.Code, 1);

        // [THEN] Movement contains exactly 1 Take line with Unit of Measure = "UoM1" for this BinFrom (breakbulk)
        VerifyWarehouseActivityLineCount(
          WarehouseActivityHeader."No.", BinFrom.Code, WarehouseActivityLine."Action Type"::Place, Item."Base Unit of Measure", 1);

        // [THEN] Movement contains exactly 1 Take line with Unit of Measure = "UoM1" for this BinFrom (actual movement)
        VerifyWarehouseActivityLineCount(
          WarehouseActivityHeader."No.", BinFrom.Code, WarehouseActivityLine."Action Type"::Take, Item."Base Unit of Measure", 1);

        // [THEN] Movement contains exactly 1 Take line with Unit of Measure = "UoM1" for this BinTo (actual movement)
        VerifyWarehouseActivityLineCount(
          WarehouseActivityHeader."No.", BinTo.Code, WarehouseActivityLine."Action Type"::Place, Item."Base Unit of Measure", 1);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure RegenPlanItemTrackingWhenTwoPartialPicksForTransfer()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        FromLocation: Record Location;
        InTransitLocation: Record Location;
        ToLocation: Record Location;
        ItemTrackingCode: Record "Item Tracking Code";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ReservationEntry: Record "Reservation Entry";
        Bin: Record Bin;
        WhseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Quantity: Decimal;
        QtyToPick1: Decimal;
        QtyToPick2: Decimal;
        QtyRemainingToPick: Decimal;
    begin
        // [FEATURE] [Item Tracking] [Planning Worksheet] [Warehouse] [Pick]
        // [SCENARIO 313975] Calc. Regenerative Plan correctly updates quantity to handle in Reservation Entries when no planning suggestion is generated
        // [SCENARIO 313975] and Transfer is partially picked twice with same Lot
        // [SCENARIO 368044] Sum of "Qty. to Handle" on item tracking is equal to the picked quantity.
        Initialize();
        Quantity := LibraryRandom.RandDecInRange(100, 200, 2);
        QtyToPick1 := Quantity / 2;
        QtyToPick2 := Quantity / 4;
        QtyRemainingToPick := Quantity - QtyToPick1 - QtyToPick2;

        // [GIVEN] Item "I" with Lot No. tracking and lot warehouse tracking
        CreateItemWithItemTrackingCodeForLot(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Validate("Safety Stock Quantity", 0);
        Item.Modify(true);
        ItemTrackingCode.Get(Item."Item Tracking Code");
        ItemTrackingCode.Validate("Lot Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);

        // [GIVEN] Received and put away 20 psc of item "I" with lot no. = "L" in location SILVER
        CreateFullWarehouseSetup(FromLocation);
        FindBin(Bin, FromLocation.Code);
        PostWhseJournalPositiveAdjmtWithItemTracking(Bin, Item, Quantity * 2);
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.FindFirst();

        // [GIVEN] Released Transfer from SILVER to BLUE with 10 pcs of item "I" and Created Warehouse Shipment
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        LibraryInventory.CreateTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", Quantity);
        LibraryInventory.ReleaseTransferOrder(TransferHeader);
        CreatePickFromTransferHeader(TransferHeader);

        // [GIVEN] Picked 5 PCS and then picked 3 PCS both with Lot "L"
        UpdateQuantityToHandleInWarehouseActivityLineWithLot(
          TransferHeader."No.", DATABASE::"Transfer Line", QtyToPick1, ItemLedgerEntry."Lot No.");
        RegisterWarehouseActivityHeader(FromLocation.Code, WhseActivityLine."Activity Type"::Pick);
        UpdateQuantityToHandleInWarehouseActivityLineWithLot(
          TransferHeader."No.", DATABASE::"Transfer Line", QtyToPick2, ItemLedgerEntry."Lot No.");
        RegisterWarehouseActivityHeader(FromLocation.Code, WhseActivityLine."Activity Type"::Pick);

        // [WHEN] Calculate regenerative plan from planning worksheet
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());
        // [THEN] 1st Outbound Tracking entry for Transfer has "Qty (Base)" = "Qty. to Handle (Base)" = "Qty. to Invoice (Base)" = - 5
        // [THEN] 2nd Outbound Tracking entry for Transfer has "Qty (Base)" = "Qty. to Handle (Base)" = "Qty. to Invoice (Base)" = - 3
        // [THEN] 3rd Outbound Tracking entry for Transfer has "Qty (Base)" -2; "Qty. to Handle (Base)" and "Qty. to Invoice (Base)" are <zero>
        // [THEN] 1st Inbound Surplus entry for Transfer has "Qty (Base)" = "Qty. to Handle (Base)" = "Qty. to Invoice (Base)" = 5
        // [THEN] 2nd Inbound Surplus entry for Transfer has "Qty (Base)" = "Qty. to Handle (Base)" = "Qty. to Invoice (Base)" = 3
        // [THEN] 3rd Inbound Surplus entry for Transfer has "Qty (Base)" 2; "Qty. to Handle (Base)" and "Qty. to Invoice (Base)" are <zero>
        ReservationEntry.SetSourceFilter(DATABASE::"Transfer Line", 0, TransferHeader."No.", -1, false);
        ReservationEntry.SetRange("Location Code", FromLocation.Code);
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Tracking);
        ReservationEntry.FindSet();
        VerifyReservationEntryQty(ReservationEntry, -QtyToPick1, -QtyToPick1, -QtyToPick1);
        ReservationEntry.Next();
        VerifyReservationEntryQty(ReservationEntry, -QtyToPick2, -QtyToPick2, -QtyToPick2);
        ReservationEntry.Next();
        VerifyReservationEntryQty(ReservationEntry, -QtyRemainingToPick, 0, 0);

        ReservationEntry.SetSourceFilter(DATABASE::"Transfer Line", 1, TransferHeader."No.", -1, false);
        ReservationEntry.SetRange("Location Code", ToLocation.Code);
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        ReservationEntry.FindSet();
        VerifyReservationEntryQty(ReservationEntry, QtyToPick1, QtyToPick1, QtyToPick1);
        ReservationEntry.Next();
        VerifyReservationEntryQty(ReservationEntry, QtyToPick2, QtyToPick2, QtyToPick2);
        ReservationEntry.Next();
        VerifyReservationEntryQty(ReservationEntry, QtyRemainingToPick, 0, 0);

        // [WHEN] Post the warehouse shipment.
        PostWarehouseShipment(WarehouseShipmentLine."Source Document"::"Outbound Transfer", TransferHeader."No.");

        // [THEN] Item tracking for the outbound transfer line has "Qty (Base) = "Qty. to Handle (Base)" = "Qty. to Invoice (Base)" = -2.
        ReservationEntry.Reset();
        ReservationEntry.SetSourceFilter(DATABASE::"Transfer Line", 0, TransferHeader."No.", -1, false);
        ReservationEntry.SetRange("Location Code", FromLocation.Code);
        ReservationEntry.CalcSums("Quantity (Base)", "Qty. to Handle (Base)", "Qty. to Invoice (Base)");
        VerifyReservationEntryQty(ReservationEntry, -QtyRemainingToPick, -QtyRemainingToPick, -QtyRemainingToPick);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BreakBulkWithUoMDifferentFromAnotherPickLine()
    var
        Location: Record Location;
        ProdItem: Record Item;
        CompItem: array[2] of Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        QtyPer: Decimal;
    begin
        // [FEATURE] [Pick] [Breakbulk] [Unit of Measure]
        // [SCENARIO 322091] Creating pick from production order on a location that allows breakbulk.
        Initialize();
        QtyPer := LibraryRandom.RandDecInDecimalRange(0.01, 0.99, 2);

        // [GIVEN] Location "White" with "Allow Breakbulk" = TRUE.
        CreateFullWarehouseSetup(Location);
        Location.Validate("Allow Breakbulk", true);
        Location.Modify(true);

        // [GIVEN] Production item "P" with two components "C1" and "C2".
        // [GIVEN] Base unit of measure of both components is "BOX".
        LibraryInventory.CreateItem(ProdItem);
        LibraryInventory.CreateItem(CompItem[1]);
        LibraryInventory.CreateItem(CompItem[2]);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, CompItem[2]."No.", QtyPer);

        // [GIVEN] Put 100 "BOX" of each component to a pick bin on the location.
        UpdateInventoryViaWarehouseJournal(CompItem, Location.Code);

        // [GIVEN] The production BOM of the manufacturing item is as follows:
        // [GIVEN] 1 "BOX" of component "C1";
        // [GIVEN] 1 "PACK" of component "C2", which is 1/5 of "BOX".
        LibraryInventory.CreateItem(ProdItem);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ProdItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CompItem[1]."No.", 1);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CompItem[2]."No.", 1);
        ProductionBOMLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        ProductionBOMLine.Modify(true);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
        UpdateItemManufacturing(ProdItem, ProductionBOMHeader."No.");

        // [GIVEN] Create and refresh production order for "P".
        CreateAndRefreshProdOrderOnLocation(ProductionOrder, ProdItem."No.", Location.Code, 1);

        // [WHEN] Create warehouse pick to collect the components.
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);

        // [THEN] The warehouse pick is created.
        // [THEN] A breakbulk line of 1 "BOX of "C2" is included in the pick.
        WarehouseActivityLine.SetFilter("Breakbulk No.", '<>%1', 0);
        FindWarehouseActivityLine2(
          WarehouseActivityLine,
          WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take, CompItem[2]."No.");
        WarehouseActivityLine.TestField("Unit of Measure Code", CompItem[2]."Base Unit of Measure");
        WarehouseActivityLine.TestField(Quantity, 1);
    end;

    [Test]
    [HandlerFunctions('DeleteRegisteredWhseDocsCancelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DeleteRegisteredWhseDocsPickCancel()
    var
        RegisteredWhseActivityHdr: Record "Registered Whse. Activity Hdr.";
        RegisteredWhsePicks: TestPage "Registered Whse. Picks";
    begin
        // [FEATURE] [Pick] [Delete Registered Whse. Docs] [UI]
        // [SCENARIO 323185] Registered Warehouse Picks aren't deleted if you press Cancel in RPH.
        Initialize();

        // [GIVEN] RegisteredWhseActivityHdr - "X", Type = 'Pick'
        CreateRegisteredDocument(RegisteredWhseActivityHdr, RegisteredWhseActivityHdr.Type::Pick);

        // [WHEN] Invoke 'Delete Registered Picks' on RegisteredWhsePicks page, invoke Cancel on RPH
        Commit();
        RegisteredWhsePicks.OpenEdit();
        RegisteredWhsePicks.FILTER.SetFilter("No.", RegisteredWhseActivityHdr."No.");
        RegisteredWhsePicks."Delete Registered Movements".Invoke();

        // [THEN] "X" isn't deleted
        RegisteredWhseActivityHdr.SetRange("Location Code", RegisteredWhseActivityHdr."Location Code");
        RegisteredWhseActivityHdr.SetRange(Type, RegisteredWhseActivityHdr.Type::Pick);
        Assert.RecordIsNotEmpty(RegisteredWhseActivityHdr);
    end;

    [Test]
    [HandlerFunctions('DeleteRegisteredWhseDocsCancelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DeleteRegisteredWhseDocMovementCancel()
    var
        RegisteredWhseActivityHdr: Record "Registered Whse. Activity Hdr.";
        RegisteredWhseMovements: TestPage "Registered Whse. Movements";
    begin
        // [FEATURE] [Movement] [Delete Registered Whse. Docs] [UI]
        // [SCENARIO 323185] Registered Warehouse Movements aren't deleted if you press Cancel in RPH.
        Initialize();

        // [GIVEN] RegisteredWhseActivityHdr - "X", Type = 'Movement'
        CreateRegisteredDocument(RegisteredWhseActivityHdr, RegisteredWhseActivityHdr.Type::Movement);

        // [WHEN] Invoke 'Delete Registered Movements' on RegisteredWhseMovements page, invoke Cancel on RPH
        Commit();
        RegisteredWhseMovements.OpenEdit();
        RegisteredWhseMovements.FILTER.SetFilter("No.", RegisteredWhseActivityHdr."No.");
        RegisteredWhseMovements."Delete Registered Movements".Invoke();

        // [THEN] "X" isn't deleted
        RegisteredWhseActivityHdr.SetRange("Location Code", RegisteredWhseActivityHdr."Location Code");
        RegisteredWhseActivityHdr.SetRange(Type, RegisteredWhseActivityHdr.Type::Movement);
        Assert.RecordIsNotEmpty(RegisteredWhseActivityHdr);
    end;

    [Test]
    [HandlerFunctions('DeleteRegisteredWhseDocsCancelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DeleteRegisteredWhseDocPutAwayCancel()
    var
        RegisteredWhseActivityHdr: Record "Registered Whse. Activity Hdr.";
        RegisteredWhsePutaways: TestPage "Registered Whse. Put-aways";
    begin
        // [FEATURE] [Put-Away] [Delete Registered Whse. Docs] [UI]
        // [SCENARIO 323185] Registered Warehouse Put-aways aren't deleted if you press Cancel in RPH.
        Initialize();

        // [GIVEN] RegisteredWhseActivityHdr - "X", Type = 'Put-away'
        CreateRegisteredDocument(RegisteredWhseActivityHdr, RegisteredWhseActivityHdr.Type::"Put-away");

        // [WHEN] Invoke 'Delete Registered Put-aways' on RegisteredWhsePutaways page, invoke Cancel on RPH
        Commit();
        RegisteredWhsePutaways.OpenEdit();
        RegisteredWhsePutaways.FILTER.SetFilter("No.", RegisteredWhseActivityHdr."No.");
        RegisteredWhsePutaways."Delete Registered Movements".Invoke();

        // [THEN] "X" isn't deleted
        RegisteredWhseActivityHdr.SetRange("Location Code", RegisteredWhseActivityHdr."Location Code");
        RegisteredWhseActivityHdr.SetRange(Type, RegisteredWhseActivityHdr.Type::"Put-away");
        Assert.RecordIsNotEmpty(RegisteredWhseActivityHdr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BreakBulkPickLinesAreRegisteredFirstToProvideQtyInSmallerUoM()
    var
        Location: Record Location;
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [FEATURE] [Pick] [Breakbulk] [Unit of Measure]
        // [SCENARIO 321982] Breakbulk lines in warehouse pick are registered first in order to provide quantity in smaller UoM.
        Initialize();

        // [GIVEN] Location "White" with "Allow Breakbulk" = TRUE.
        CreateFullWarehouseSetup(Location);
        Location.Validate("Allow Breakbulk", true);
        Location.Modify(true);

        // [GIVEN] Item with base unit of measure = "PCS" and alternate UoM = "BOX".
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandIntInRange(10, 20));

        // [GIVEN] Place 10 "BOX" to the location.
        UpdateInventoryViaWhseJournalWithAlternateUoM(Item, ItemUnitOfMeasure.Code, Location.Code);

        // [GIVEN] Sales order for 1 "PCS".
        // [GIVEN] Release the order, create shipment and pick.
        CreateSalesOrderWithLocation(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandInt(10), Location.Code);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        CreatePickFromSalesHeader(SalesHeader);

        // [GIVEN] Sort the pick lines by "Shelf or Bin".
        FindWarehouseActivityHeader(WarehouseActivityHeader, Location.Code, WarehouseActivityHeader.Type::Pick);
        WarehouseActivityHeader.Validate("Sorting Method", WarehouseActivityHeader."Sorting Method"::"Shelf or Bin");
        WarehouseActivityHeader.SortWhseDoc();
        WarehouseActivityHeader.Modify(true);

        // [WHEN] Register the warehouse pick respecting the sorting.
        WarehouseActivityLine.SetCurrentKey("Activity Type", "No.", "Sorting Sequence No.");
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
        CODEUNIT.Run(CODEUNIT::"Whse.-Activity-Register", WarehouseActivityLine);

        // [THEN] The pick is successfully registered.
        VerifyRegisteredWarehouseActivityLine(SalesLine, WarehouseActivityLine."Action Type"::Take);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure ErrorInRegisteringPickRollsBackWholeTransaction()
    var
        Location: Record Location;
        Bin: Record Bin;
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        RegisteredWhseActivityHdr: Record "Registered Whse. Activity Hdr.";
        BinContent: Record "Bin Content";
        SCMWarehouseVI: Codeunit "SCM Warehouse VI";
        LotNo: Code[50];
        Qty: Decimal;
    begin
        // [FEATURE] [Warehouse Pick] [Item Tracking]
        // [SCENARIO 339554] When an error occurs during registering pick, the whole register transaction is rolled back and no registered pick lines are created.
        Initialize();
        LotNo := LibraryUtility.GenerateGUID();
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Location with directed put-away and pick.
        CreateFullWarehouseSetup(Location);
        FindBin(Bin, Location.Code);

        // [GIVEN] Lot-tracked item.
        CreateItemTrackingCode(ItemTrackingCode);
        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCode.Code);

        // [GIVEN] Post 10 pcs to bin "B", assign lot no. = "L".
        UpdateInventoryInBinUsingWhseJournalWithLotNo(Bin, Item."No.", Qty, LotNo);

        // [GIVEN] Sales order for 10 pcs.
        // [GIVEN] Release the sales order, create warehouse shipment and pick.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", Qty, Location.Code, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        CreatePickFromSalesHeader(SalesHeader);

        // [GIVEN] Set lot no. = "L" on the pick lines.
        FindWarehouseActivityHeaderBySourceNo(WarehouseActivityHeader, Location.Code, SalesHeader."No.");
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.ModifyAll("Lot No.", LotNo, true);

        // [GIVEN] Subscribe to an event in Whse.-Activity-Register codeunit in order to raise an error after the item tracking is synchronized between the pick lines and the sales line.
        BindSubscription(SCMWarehouseVI);

        // [WHEN] Register the warehouse pick.
        asserterror LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] The expected error is thrown.
        Assert.ExpectedError(RegisteringPickInterruptedErr);

        // [THEN] No registered warehouse pick is created.
        RegisteredWhseActivityHdr.SetRange("Location Code", Location.Code);
        Assert.RecordIsEmpty(RegisteredWhseActivityHdr);

        // [THEN] 10 pcs remain in bin "B".
        FindBinContentWithBinCode(BinContent, Bin, Item."No.");
        BinContent.CalcFields(Quantity);
        BinContent.TestField(Quantity, Qty);

        // Tear down.
        UnbindSubscription(SCMWarehouseVI);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillOverReceiptCodeWhseRcptValidateOverReceiptQuantity()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        OverReceiptCode: Record "Over-Receipt Code";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        // [FEATURE] [Over-Receipt]
        // [SCENARIO] "Over-Receipt Code" is filled in with default value when validate "Over-Receipt Quantity"
        Initialize();

        // [GIVEN] Warehouse receipt       
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, true, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Location.Code, '', 100);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWarehouseReceiptLine(WarehouseReceiptLine, PurchaseHeader."No.");

        // [WHEN] Enter "Over-Receipt Quantity"
        WarehouseReceiptLine.Validate("Over-Receipt Quantity", 5);

        // [THEN] "Over-Receipt Code" is filled with default over-receipt code
        OverReceiptCode.SetRange(Default, true);
        OverReceiptCode.FindFirst();
        Assert.IsTrue(WarehouseReceiptLine."Over-Receipt Code" = OverReceiptCode.Code, 'Wrong over-receipt code');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillOverReceiptCodeWhseRcptValidateQtyToReceive()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        OverReceiptCode: Record "Over-Receipt Code";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        WarehouseReceipt: TestPage "Warehouse Receipt";
    begin
        // [FEATURE] [Over-Receipt] [UI]
        // [SCENARIO] "Over-Receipt Code" is filled in with default value when validate "Qty. To Receive"
        Initialize();

        // [GIVEN] Warehouse receipt       
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, true, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Location.Code, '', 100);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWarehouseReceiptLine(WarehouseReceiptLine, PurchaseHeader."No.");
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");

        // [WHEN] Enter "Qty. To Receive"
        WarehouseReceipt.OpenView();
        WarehouseReceipt.GoToRecord(WarehouseReceiptHeader);
        WarehouseReceipt.WhseReceiptLines."Qty. to Receive".SetValue(106);

        // [THEN] "Over-Receipt Code" is filled with default over-receipt code
        OverReceiptCode.SetRange(Default, true);
        OverReceiptCode.FindFirst();
        Assert.IsTrue(WarehouseReceipt.WhseReceiptLines."Over-Receipt Code".Value = OverReceiptCode.Code, 'Wrong over-receipt code');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehouseRcptOverReceiptQtyClearsAfterClearOverReceiptCode()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        WarehouseReceipt: TestPage "Warehouse Receipt";
        OverReceiptApprovalStatus: Enum "Over-Receipt Approval Status";
        OldQtyValue: Decimal;
    begin
        // [FEATURE] [Over-Receipt] [UI]
        // [SCENARIO] Over-Receipt quantity clears when Over-Receipt Code is cleared in Warehouse Receipt line
        Initialize();

        // [GIVEN] Warehouse receipt created from Purchaser Order "PO" with Quantity = Y      
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, true, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        OldQtyValue := 100;
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Location.Code, '', OldQtyValue);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWarehouseReceiptLine(WarehouseReceiptLine, PurchaseHeader."No.");
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");

        // [GIVEN] Enter "Qty to Receive" = >Y, 'Over-Receipt Code' is populated
        WarehouseReceipt.OpenEdit();
        WarehouseReceipt.FILTER.SetFilter("No.", WarehouseReceiptHeader."No.");
        WarehouseReceipt.WhseReceiptLines."Qty. to Receive".SetValue(106);
        Assert.AreNotEqual('', WarehouseReceipt.WhseReceiptLines."Over-Receipt Code".Value, 'Over-Receipt Code should not be empty');

        // [WHEN] 'Over-Receipt Code' is cleared
        WarehouseReceipt.WhseReceiptLines."Over-Receipt Code".SetValue('');

        // [THEN] "Over-Receipt Code" is cleared
        // [THEN] 'Over-Receipt Quantity' = 0, Quantity = Qty. to Receive = Qty. To Invoice = Y. 
        WarehouseReceipt.WhseReceiptLines."Over-Receipt Quantity".AssertEquals(0);
        WarehouseReceipt.WhseReceiptLines."Over-Receipt Code".AssertEquals('');
        WarehouseReceipt.WhseReceiptLines.Quantity.AssertEquals(OldQtyValue);
        WarehouseReceipt.WhseReceiptLines."Qty. to Receive".AssertEquals(OldQtyValue);
        PurchaseLine.Find();

        // [THEN] Purchase Line in Purchase Order "PO" has 'Over-Receipt Status' = '', 
        // [THEN] "Over-Receipt Quantity" = 0, Quantity = Y;.
        PurchaseLine.TestField("Over-Receipt Approval Status", OverReceiptApprovalStatus::" ");
        PurchaseLine.TestField("Over-Receipt Quantity", 0);
        PurchaseLine.TestField(Quantity, OldQtyValue);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingPageHandler,ItemTrackingSummarySelectLotHandler')]
    [Scope('OnPrem')]
    procedure QuantityAfterAssistEditWhseItemTrackingLines()
    var
        Bin: Record Bin;
        Location: Record Location;
        Item: Record Item;
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        BinContent: Record "Bin Content";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        LotNo: array[2] of Code[50];
        Quantity: Decimal;
        Index: Integer;
    begin
        // [FEATURE] [Whse. Item Tracking Line]
        // [SCENARIO 372110] Quantity after assist edit Lot No. on Whse. Item Tracking Lines shows available qty of selected lot
        Initialize();

        // [GIVEN] Location "WHITE" with full WMS Setup and employee created
        CreateFullWarehouseSetup(Location);
        FindBin(Bin, Location.Code);

        // [GIVEN] Item with lot warehouse tracking
        CreateItemWithItemTrackingCodeForLot(Item);

        // [GIVEN] Item purchased for location "WHITE": lots "LOT1","LOT2", each with Quantity = 10
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Type::Item, Location.Code);
        for Index := 1 to ArrayLen(LotNo) do begin
            LotNo[Index] := LibraryUtility.GenerateGUID();
            CreateAndRegisterWhseJnlLineWithLotAndUoM(
              Bin, Item."No.", LotNo[Index], Quantity, Item."Base Unit of Measure");
        end;
        LibraryWarehouse.PostWhseAdjustment(Item);

        // [GIVEN] Get Bin Content for Movement Worksheet for the Item, Lot "LOT1"
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Movement);
        WhseWorksheetLine."Worksheet Template Name" := WhseWorksheetTemplate.Name;
        BinContent.SetRange("Item No.", Item."No.");
        BinContent.SetRange("Lot No. Filter", LotNo[1]);
        LibraryWarehouse.WhseGetBinContent(
            BinContent, WhseWorksheetLine, WhseInternalPutAwayHeader, "Warehouse Destination Type 2"::MovementWorksheet);
        FindWarehouseWorksheetLine(WhseWorksheetLine, Item."No.");

        // [WHEN] Choose "Lot No." = "LOT2" on the Whse. Item Tracking Line for Whse. Worksheet Line with Assist Edit
        LibraryVariableStorage.Enqueue(TrackingActionStr::AssistEditLotNo);
        LibraryVariableStorage.Enqueue(LotNo[2]);
        WhseWorksheetLine.OpenItemTrackingLines();

        // [THEN] Quantity = 10 on the Whse. Item Tracking Line
        Assert.AreEqual(Quantity, LibraryVariableStorage.DequeueDecimal(), 'Incorrect quantity on the Whse. Item Tracking Line');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure CheckAvailQtyOnValidateLotNoOnWhsePickLineWithReservation()
    var
        Item: Record Item;
        Location: Record Location;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Qty: Decimal;
        NewLotNo: Code[50];
    begin
        // [FEATURE] [Pick] [Item Tracking] [Reservation]
        // [SCENARIO 377492] Lot availability is checked when a user validates Lot No. on warehouse pick line.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(50, 100);
        NewLotNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Lot-tracked item.
        CreateItemWithItemTrackingCodeForLot(Item);

        // [GIVEN] Location set up for required shipment and pick.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, true);

        // [GIVEN] Post 100 pcs of the item with lot "L1" to inventory.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, '', Qty);
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create sales order for 100 pcs.
        // [GIVEN] Reserve the sales order from inventory.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", Qty, Location.Code, WorkDate());
        LibrarySales.AutoReserveSalesLine(SalesLine);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Create warehouse shipment and pick.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SalesHeader."No.", WarehouseShipmentLine."Source Document"::"Sales Order");
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        LibraryWarehouse.FindWhseActivityLineBySourceDoc(
          WarehouseActivityLine, DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");

        // [WHEN] Set a non-existent lot no. "L2" on the pick line.
        asserterror WarehouseActivityLine.Validate("Lot No.", NewLotNo);

        // [THEN] An error message is thrown.
        // [THEN] "L2" is not available in inventory.
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(LotNoNotAvailableInInvtErr, NewLotNo));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler2,CreateInvtPickRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CheckAvailQtyOnPostingWhsePickLineWithItemTracking()
    var
        Item: Record Item;
        Location: Record Location;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseActivityPost: Codeunit "Whse.-Activity-Post";
        Qty1: Decimal;
        Qty2: Decimal;
        NewLotNo1: Code[50];
        NewLotNo2: Code[50];
    begin
        // [FEATURE] [Pick] [Item Tracking] [Reservation]
        // [SCENARIO 477719] Lot availability is checked when user post Inv. Pick.
        Initialize();
        Qty1 := LibraryRandom.RandIntInRange(50, 100);
        NewLotNo1 := LibraryUtility.GenerateGUID();
        Qty2 := LibraryRandom.RandIntInRange(50, 100);
        NewLotNo2 := LibraryUtility.GenerateGUID();

        // [GIVEN] Lot-tracked item.
        CreateItemWithItemTrackingCodeForLot(Item);

        // [GIVEN] Location set up for required shipment and pick.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);

        // [GIVEN] Post x pcs of the item with lot "L1" to inventory.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, '', Qty1);
        LibraryVariableStorage.Enqueue(TrackingActionStr::AssignGivenLotNo);
        LibraryVariableStorage.Enqueue(NewLotNo1);
        LibraryVariableStorage.Enqueue(Qty1);
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Post y pcs of the item with lot "L2" to inventory.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, '', Qty2);
        LibraryVariableStorage.Enqueue(TrackingActionStr::AssignGivenLotNo);
        LibraryVariableStorage.Enqueue(NewLotNo2);
        LibraryVariableStorage.Enqueue(Qty2);
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create and release sales order for x+y pcs.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", Qty1 + Qty2, Location.Code, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        Commit();

        // [GIVEN] Create invt. pick. and find a pick line.
        SalesHeader.CreateInvtPutAwayPick();
        LibraryWarehouse.FindWhseActivityLineBySourceDoc(
          WarehouseActivityLine, DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");
        WarehouseActivityLine.TestField("Lot No.", '');
        WarehouseActivityLine.TestField(Quantity, Qty1 + Qty2);


        // [WHEN] Set lot no. "L1" on the pick line for total qty. and update qty to handle.
        WarehouseActivityLine.Validate("Lot No.", NewLotNo1);
        WarehouseActivityLine.Modify();

        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.SetQtyToHandleWhseActivity(WarehouseActivityHeader, WarehouseActivityLine.Quantity);

        // [THEN] During the posting of the Inventory Pick, the error is thrown
        WhseActivityPost.SetInvoiceSourceDoc(false);
        WhseActivityPost.PrintDocument(false);
        WhseActivityPost.SetSuppressCommit(false);
        WhseActivityPost.ShowHideDialog(false);
        WhseActivityPost.SetIsPreview(false);
        asserterror WhseActivityPost.Run(WarehouseActivityLine);
        Assert.ExpectedError(StrSubstNo(LotNoNotAvailableInInvtErr, NewLotNo1));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateInvtPickRequestPageHandler(var CreateInvtPutawayPickMvmt: TestRequestPage "Create Invt Put-away/Pick/Mvmt")
    begin
        CreateInvtPutawayPickMvmt.CInvtPick.SetValue(true);
        CreateInvtPutawayPickMvmt.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotesTransferredToPostedWhseShipment()
    var
        SalesLine: Record "Sales Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header";
        RecordLink: Record "Record Link";
    begin
        // [SCENARIO 381211] Record links are transferred from Warehouse Shipment to Posted Warehouse Shipment
        // [FEATURE] [Warehouse Shipment] [Record Link]
        Initialize();

        // [GIVEN] Warehouse Shipment ready to be posted
        CreateInitialSetupForPick(SalesLine);
        FindWarehouseShipmentHeader(
          WarehouseShipmentHeader, SalesLine."Document No.", WarehouseShipmentLine."Source Document"::"Sales Order");
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        FindWarehouseActivityHeaderBySourceNo(WarehouseActivityHeader, SalesLine."Location Code", SalesLine."Document No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
        WarehouseShipmentHeader.Find();

        // [GIVEN] Record Link of Note type created for the Warehouse Shipment
        LibraryUtility.CreateRecordLink(WarehouseShipmentHeader);

        // [WHEN] Post Warehouse Shipment
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [THEN] Record Link created for the Posted Warehouse Shipment
        PostedWhseShipmentHeader.SetRange("Whse. Shipment No.", WarehouseShipmentHeader."No.");
        PostedWhseShipmentHeader.FindFirst();
        RecordLink.SetRange("Record ID", PostedWhseShipmentHeader.RecordId());
        Assert.RecordIsNotEmpty(RecordLink);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotesTransferredToPostedWhseReceipt()
    var
        PurchaseLine: Record "Purchase Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
        RecordLink: Record "Record Link";
    begin
        // [SCENARIO 381211] Record links are transferred from Warehouse Receipt to Posted Warehouse Receipt
        // [FEATURE] [Warehouse Receipt] [Record Link]
        Initialize();

        // [GIVEN] Warehouse Receipt ready to be posted
        CreateWarehouseReceiptFromPurchaseOrder(PurchaseLine);
        WarehouseReceiptHeader.Get(FindWarehouseReceiptHeader(PurchaseLine."Document No."));

        // [GIVEN] Record Link of Note type created for the Warehouse Receipt
        LibraryUtility.CreateRecordLink(WarehouseReceiptHeader);

        // [WHEN] Post Warehouse Receipt
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [THEN] Record Link created for the Posted Warehouse Receipt
        PostedWhseReceiptHeader.SetRange("Whse. Receipt No.", WarehouseReceiptHeader."No.");
        PostedWhseReceiptHeader.FindFirst();
        RecordLink.SetRange("Record ID", PostedWhseReceiptHeader.RecordId());
        Assert.RecordIsNotEmpty(RecordLink);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotesTransferredToRegisteredWhsePick()
    var
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        RegisteredWhseActivityHdr: Record "Registered Whse. Activity Hdr.";
        RecordLink: Record "Record Link";
    begin
        // [SCENARIO 381211] Record links are transferred from Warehouse Pick to Posted Warehouse Pick
        // [FEATURE] [Warehouse Pick] [Record Link]
        Initialize();

        // [GIVEN] Warehouse Pick ready to be registered
        CreateInitialSetupForPick(SalesLine);
        FindWarehouseShipmentHeader(
          WarehouseShipmentHeader, SalesLine."Document No.", WarehouseShipmentLine."Source Document"::"Sales Order");
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        FindWarehouseActivityHeaderBySourceNo(WarehouseActivityHeader, SalesLine."Location Code", SalesLine."Document No.");

        // [GIVEN] Record Link of Note type created for the Warehouse Pick
        LibraryUtility.CreateRecordLink(WarehouseActivityHeader);

        // [WHEN] Register the Warehouse Pick
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] Record Link created for the Registered Warehouse Pick
        FindRegisteredWarehouseActivityHeader(RegisteredWhseActivityHdr, SalesLine."Location Code", RegisteredWhseActivityHdr.Type::Pick);
        RecordLink.SetRange("Record ID", RegisteredWhseActivityHdr.RecordId());
        Assert.RecordIsNotEmpty(RecordLink);
    end;

    [Test]
    [HandlerFunctions('SourceDocumentsPageHandler')]
    [Scope('OnPrem')]
    procedure NotesTransferredToRegisteredInventoryMovement()
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        RegisteredInvtMovementHdr: Record "Registered Invt. Movement Hdr.";
        RecordLink: Record "Record Link";
    begin
        // [SCENARIO 381211] Record links are transferred from Inventory Movement to Posted Inventory Movement
        // [FEATURE] [Inventory Movement] [Record Link]
        Initialize();

        // [GIVEN] Inventory Movement ready to be registered
        CreateItemMovementSetup(WarehouseActivityHeader);
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);

        // [GIVEN] Record Link of Note type created for the Inventory Movement
        LibraryUtility.CreateRecordLink(WarehouseActivityHeader);

        // [WHEN] Register the Inventory Movement
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] Record Link created for the Registered Inventory Movement
        RegisteredInvtMovementHdr.SetRange("Invt. Movement No.", WarehouseActivityHeader."No.");
        RegisteredInvtMovementHdr.FindFirst();
        RecordLink.SetRange("Record ID", RegisteredInvtMovementHdr.RecordId());
        Assert.RecordIsNotEmpty(RecordLink);
    end;

    [Test]
    [HandlerFunctions('SourceDocumentsPageHandler')]
    [Scope('OnPrem')]
    procedure RegisteringDateIsSetInRegisteredInventoryMovement()
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        RegisteredInvtMovementHdr: Record "Registered Invt. Movement Hdr.";
    begin
        // [SCENARIO] The registering date of the Registered Inventory Movement must be set to the WorkDate
        // [FEATURE] [Inventory Movement]
        Initialize();

        // [GIVEN] Inventory Movement ready to be registered
        CreateItemMovementSetup(WarehouseActivityHeader);
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);

        // [WHEN] Register the Inventory Movement
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] Verify that the "Registering Date" of the Registered Inventory Movement is set
        RegisteredInvtMovementHdr.SetRange("Invt. Movement No.", WarehouseActivityHeader."No.");
        RegisteredInvtMovementHdr.FindFirst();
        Assert.AreEqual(WorkDate(), RegisteredInvtMovementHdr."Registering Date", RegisteredInvtMovementHdr.FieldCaption("Registering Date"));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler2')]
    [Scope('OnPrem')]
    procedure ItemTrackingOnPickAfterOrderToOrderPurchReceiptPosted()
    var
        Location: Record Location;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        // [FEATURE] [Reservation] [Order-to-Order Binding] [Receipt] [Shipment] [Item Tracking] [Pick]
        // [SCENARIO 374353] Posting warehouse pick for sales order after a warehouse receipt for the order-to-order bound purchase is posted in two iterations for a single lot no.
        Initialize();

        // [GIVEN] Location set up for directed put-away and pick.
        CreateFullWarehouseSetup(Location);

        // [GIVEN] Lot-tracked item with Reordering Policy = Order.
        CreateItemWithItemTrackingCodeForLot(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::Order);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);

        // [GIVEN] Sales order for 6 pcs.
        // [GIVEN] Create warehouse shipment.
        CreateSalesOrderWithLocation(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandIntInRange(5, 10), Location.Code);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [GIVEN] Calculate regenerative plan and carry out action message in order to create a supplying purchase order.
        CalcRegenPlanAndCarryOutActionMsg(Item);

        // [GIVEN] Release the purchase order and create warehouse receipt.
        PurchaseHeader.SetRange("Buy-from Vendor No.", Item."Vendor No.");
        PurchaseHeader.FindFirst();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // [GIVEN] Set "Qty. to Receipt" = 5 on the warehouse receipt line.
        // [GIVEN] Assign lot no.
        // [GIVEN] Post the receipt and warehouse put-away.
        FindWarehouseReceiptLine(WarehouseReceiptLine, PurchaseHeader."No.");
        WarehouseReceiptLine.Validate("Qty. to Receive", LibraryRandom.RandInt(SalesLine.Quantity - 1));
        WarehouseReceiptLine.Modify(true);
        LibraryVariableStorage.Enqueue(TrackingActionStr::AssignLotNo);
        WarehouseReceiptLine.OpenItemTrackingLines();
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
        FindWarehouseActivityHeaderBySourceNo(WarehouseActivityHeader, Location.Code, PurchaseHeader."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [GIVEN] Go back to the warehouse receipt.
        // [GIVEN] Set Quantity = 6 on the item tracking line for the same lot no.
        // [GIVEN] Post the receipt and warehouse put-away.
        WarehouseReceiptLine.Find();
        LibraryVariableStorage.Enqueue(TrackingActionStr::AssistEditLotNo);
        LibraryVariableStorage.Enqueue(WarehouseReceiptLine."Qty. (Base)");
        WarehouseReceiptLine.OpenItemTrackingLines();
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
        FindWarehouseActivityHeaderBySourceNo(WarehouseActivityHeader, Location.Code, PurchaseHeader."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [GIVEN] Open warehouse shipment for the sales order and create pick.
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SalesHeader."No.", WarehouseShipmentLine."Source Document"::"Sales Order");
        LibraryWarehouse.CreateWhsePick(WarehouseShipmentHeader);

        // [WHEN] Register the pick.
        FindWarehouseActivityHeaderBySourceNo(WarehouseActivityHeader, Location.Code, SalesHeader."No.");
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] The full quantity (6 pcs) have been picked.
        Item.CalcFields("Qty. Picked");
        Item.TestField("Qty. Picked", SalesLine.Quantity);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingPageHandler,WhseSourceCreateDocumentHandler,MessageHandler')]
    procedure CreateMovementByFEFOFromMvmtWorksheetWithQtyReserved()
    var
        Item: Record Item;
        Location: Record Location;
        Zone: Record Zone;
        Bin: array[2] of Record Bin;
        BinContent: Record "Bin Content";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Qty: Decimal;
        LotNo: Code[20];
        ExpirationDate: Date;
    begin
        // [FEATURE] [Item Tracking] [Reservation] [Movement Worksheet] [Movement] [FEFO]
        // [SCENARIO 393971] Stan can create movement by FEFO for bin replenishment when the quantity is reserved.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(20, 40);
        LotNo := LibraryUtility.GenerateGUID();
        ExpirationDate := LibraryRandom.RandDate(10);

        // [GIVEN] Location with directed put-away and pick, FEFO is enabled.
        CreateFullWarehouseSetup(Location);
        UpdateParametersOnLocation(Location, true, false);

        // [GIVEN] Lot-tracked item with mandatory expiration date.
        CreateItemWithItemTrackingCodeWithExpirateDate(Item);

        // [GIVEN] Post 40 pcs to bin "B1" in pick zone, assign lot no. "L" and expiration date "D".
        FindZone(Zone, Location.Code);
        FindBinAndUpdateBinRanking(Bin[1], Zone, '', 0);
        CreateAndRegisterWhseJnlLineWithLotAndExpDate(Bin[1], Item."No.", LotNo, ExpirationDate, Qty);
        CalculateAndPostWarehouseAdjustment(Item);

        // [GIVEN] Sales order for 40 pcs, reserve.
        CreateSalesOrderWithLocation(SalesHeader, SalesLine, Item."No.", Qty, Location.Code);
        LibrarySales.AutoReserveSalesLine(SalesLine);

        // [GIVEN] Open movement worksheet.
        // [GIVEN] Calculate bin replenishment to move the quantity to a bin with higher ranking "B2".
        // [GIVEN] "From Bin Code" = <blank> on movement worksheet line, the source bin will be selected by FEFO.
        FindBinAndUpdateBinRanking(Bin[2], Zone, Bin[1].Code, 1);
        CreateBinContent(BinContent, Bin[2], Item, Item."Base Unit of Measure", 1, Qty);
        CalculateBinReplenishmentForBinContent(Location.Code, BinContent);
        WhseWorksheetLine.SetRange("Location Code", Location.Code);
        WhseWorksheetLine.FindFirst();
        WhseWorksheetLine.TestField("From Bin Code", '');
        WhseWorksheetLine.TestField("To Bin Code", Bin[2].Code);

        // [WHEN] Create movement from the movement worksheet.
        Commit();
        WhseWorksheetLine.MovementCreate(WhseWorksheetLine);

        // [THEN] Warehouse movement has been created, lot no. = "L", expiration date = "D".
        FindWarehouseActivityLine2(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Movement, WarehouseActivityLine."Action Type"::Take, Item."No.");
        WarehouseActivityLine.TestField("Lot No.", LotNo);
        WarehouseActivityLine.TestField("Expiration Date", ExpirationDate);

        // [THEN] The movement can be registered.
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] 40 pcs have been moved to bin "B2".
        BinContent.Find();
        BinContent.CalcFields("Quantity (Base)");
        BinContent.TestField("Quantity (Base)", Qty);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingPageHandler')]
    procedure PickingByFEFOWhenQtyNonSpecificReservedFromILEHavingLotInBulkZone()
    var
        Location: Record Location;
        Zone: Record Zone;
        Bin: array[2] of Record Bin;
        Item: Record Item;
        SalesHeader: array[2] of Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Qty: Decimal;
        LotNo: array[2] of Code[20];
        ExpirationDate: Date;
    begin
        // [FEATURE] [Reservation] [Bin] [FEFO] [Pick] [Sales]
        // [SCENARIO 394500] Picking by FEFO of non-specifically reserved sales order takes lot no. with the earliest expiration date as it should, although the reservation is performed from item entry with an inappropriate lot no.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(20, 40);
        LotNo[1] := LibraryUtility.GenerateGUID();
        LotNo[2] := LibraryUtility.GenerateGUID();
        ExpirationDate := LibraryRandom.RandDate(10);

        // [GIVEN] Location with directed put-away and pick, FEFO is enabled.
        CreateFullWarehouseSetup(Location);
        UpdateParametersOnLocation(Location, true, false);

        // [GIVEN] Lot-tracked item with mandatory expiration date.
        CreateItemWithItemTrackingCodeWithExpirateDate(Item);

        // [GIVEN] Post 40 pcs to a bin in bulk zone, assign lot no. "L1" and expiration date "D1".
        LibraryWarehouse.FindZone(Zone, Location.Code, LibraryWarehouse.SelectBinType(false, false, true, false), false);
        FindBinAndUpdateBinRanking(Bin[1], Zone, '', 0);
        CreateAndRegisterWhseJnlLineWithLotAndExpDate(Bin[1], Item."No.", LotNo[1], ExpirationDate, Qty);
        CalculateAndPostWarehouseAdjustment(Item);

        // [GIVEN] Sales order "SO1" for 40 pcs, reserve.
        CreateSalesOrderWithLocation(SalesHeader[1], SalesLine, Item."No.", Qty, Location.Code);
        LibrarySales.AutoReserveSalesLine(SalesLine);

        // [GIVEN] Post 40 pcs to a bin in pick zone, assign lot no. "L2" and expiration date "D2" < "D1".
        LibraryWarehouse.FindZone(Zone, Location.Code, LibraryWarehouse.SelectBinType(false, false, true, true), false);
        FindBinAndUpdateBinRanking(Bin[2], Zone, '', 0);
        CreateAndRegisterWhseJnlLineWithLotAndExpDate(Bin[2], Item."No.", LotNo[2], WorkDate(), Qty);
        CalculateAndPostWarehouseAdjustment(Item);

        // [GIVEN] Sales order "SO2" for 40 pcs, reserve.
        CreateSalesOrderWithLocation(SalesHeader[2], SalesLine, Item."No.", Qty, Location.Code);
        LibrarySales.AutoReserveSalesLine(SalesLine);

        // [GIVEN] Create warehouse shipment from the sales order "SO1".
        LibrarySales.ReleaseSalesDocument(SalesHeader[1]);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader[1]);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SalesHeader[1]."No.", WarehouseShipmentLine."Source Document"::"Sales Order");

        // [WHEN] Create pick from the warehouse shipment.
        LibraryWarehouse.CreateWhsePick(WarehouseShipmentHeader);

        // [THEN] Lot No. = "L2", Expiration Date = "D2" on the pick line (according to FEFO).
        FindWarehouseActivityLine(WarehouseActivityLine, SalesHeader[1]."No.", WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.TestField("Lot No.", LotNo[2]);
        WarehouseActivityLine.TestField("Expiration Date", WorkDate());

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingPageHandler')]
    procedure PickingByFEFOWithSurplusEntriesCreatedByPlanning()
    var
        Location: Record Location;
        Zone: Record Zone;
        Bin: array[2] of Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Qty: Decimal;
        LotNo: array[2] of Code[20];
        ExpirationDate: Date;
    begin
        // [FEATURE] [FEFO] [Pick] [Sales] [Planning]
        // [SCENARIO 399593] Picking by FEFO having surplus reservation entries created by planning.
        Initialize();
        Qty := LibraryRandom.RandInt(10);
        ExpirationDate := LibraryRandom.RandDate(10);

        // [GIVEN] Location with directed put-away and pick, FEFO is enabled.
        CreateFullWarehouseSetup(Location);
        UpdateParametersOnLocation(Location, true, false);
        LibraryWarehouse.FindZone(Zone, Location.Code, LibraryWarehouse.SelectBinType(false, false, true, true), false);

        // [GIVEN] Lot-tracked item with mandatory expiration date and set up for planning.
        CreateItemWithItemTrackingCodeWithExpirateDate(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Modify(true);

        // [GIVEN] Post 10 pcs to a bin in pick zone, assign lot no. "L1" and expiration date "D1".
        // [GIVEN] Post 10 pcs to a bin in pick zone, assign lot no. "L2" and expiration date "D2" < "D1".
        LibraryWarehouse.FindBin(Bin[1], Location.Code, Zone.Code, 1);
        LibraryWarehouse.FindBin(Bin[2], Location.Code, Zone.Code, 2);
        LotNo[1] := LibraryUtility.GenerateGUID();
        CreateAndRegisterWhseJnlLineWithLotAndExpDate(Bin[1], Item."No.", LotNo[1], ExpirationDate, Qty);
        LotNo[2] := LibraryUtility.GenerateGUID();
        CreateAndRegisterWhseJnlLineWithLotAndExpDate(Bin[2], Item."No.", LotNo[2], WorkDate(), Qty);
        CalculateAndPostWarehouseAdjustment(Item);

        // [GIVEN] Sales order for 10 pcs, create warehouse shipment.
        CreateSalesOrderWithLocation(SalesHeader, SalesLine, Item."No.", Qty, Location.Code);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SalesHeader."No.", WarehouseShipmentLine."Source Document"::"Sales Order");

        // [GIVEN] Run the regenerative planning for the item.
        Item.SetRecFilter();
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // [WHEN] Create pick from the warehouse shipment.
        LibraryWarehouse.CreateWhsePick(WarehouseShipmentHeader);

        // [THEN] Lot No. = "L2", Expiration Date = "D2" on the pick line (according to FEFO).
        FindWarehouseActivityLine(WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.TestField("Lot No.", LotNo[2]);
        WarehouseActivityLine.TestField("Expiration Date", WorkDate());
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingPageHandler')]
    procedure PartialPickingOfProdOrderComponentsWithItemTracking()
    var
        Location: Record Location;
        Bin: Record Bin;
        CompItem: Record Item;
        ProdItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        Qty: Decimal;
    begin
        // [FEATURE] [Warehouse Pick] [Prod. Order Component] [Item Tracking] [FEFO]
        // [SCENARIO 397287] Picking a component after registering a previous pick and increasing quantity on the production order line.
        Initialize();
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Location with FEFO enabled.
        CreateFullWarehouseSetup(Location);
        UpdateParametersOnLocation(Location, true, false);

        // [GIVEN] Lot-tracked component item "C".
        // [GIVEN] Production item "P". "Quantity per" in the production BOM = 1.
        CreateItemWithItemTrackingCodeWithExpirateDate(CompItem);
        LibraryInventory.CreateItem(ProdItem);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, CompItem."No.", ProdItem."Base Unit of Measure", 1);
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Modify(true);

        // [GIVEN] Post 100 pcs of component "C" to inventory via Warehouse Item Journal.
        FindBin(Bin, Location.Code);
        CreateAndRegisterWhseJnlLineWithLotAndExpDate(
          Bin, CompItem."No.", LibraryUtility.GenerateGUID(), LibraryRandom.RandDate(30), LibraryRandom.RandIntInRange(50, 100));
        CalculateAndPostWarehouseAdjustment(CompItem);

        // [GIVEN] Released production order for 2 pcs of item "P".
        CreateAndRefreshProdOrderOnLocation(ProductionOrder, ProdItem."No.", Location.Code, 2 * Qty);

        // [GIVEN] Create warehouse pick and register it in two iterations, each for 1 pc.
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);
        UpdateQuantityToHandleInWarehouseActivityLine(ProductionOrder."No.", Qty);
        RegisterWarehouseActivityHeader(Location.Code, WarehouseActivityHeader.Type::Pick);
        RegisterWarehouseActivityHeader(Location.Code, WarehouseActivityHeader.Type::Pick);

        // [GIVEN] Increase quantity on the production order line to 3 pcs.
        FindProductionOrderLine(ProdOrderLine, ProductionOrder."No.");
        ProdOrderLine.Validate("Quantity (Base)", 3 * Qty);
        ProdOrderLine.Modify(true);

        // [WHEN] Create warehouse pick for the remaining 1 pc.
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);

        // [THEN] The warehouse pick can be registered.
        RegisterWarehouseActivityHeader(Location.Code, WarehouseActivityHeader.Type::Pick);

        // [THEN] All 3 pcs of the component "C" have been picked.
        FindProductionOrderComponent(ProdOrderComponent, ProductionOrder."No.");
        ProdOrderComponent.TestField("Qty. Picked", 3 * Qty);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingPageHandler')]
    procedure PickingByFEFOWithConsideringReservationAndPickForAnotherOrder()
    var
        Location: Record Location;
        Zone: Record Zone;
        Bin: Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNo: Code[20];
        Qty: Decimal;
        ExpirationDate: Date;
    begin
        // [FEATURE] [FEFO] [Pick] [Sales] [Reservation]
        // [SCENARIO 402464] Picking by FEFO with the proper consideration of existing pick and non-specific reservation of another sales order.
        Initialize();
        LotNo := LibraryUtility.GenerateGUID();
        Qty := LibraryRandom.RandInt(10);
        ExpirationDate := LibraryRandom.RandDate(10);

        // [GIVEN] Directed put-away and pick location with enabled FEFO.
        CreateFullWarehouseSetup(Location);
        UpdateParametersOnLocation(Location, true, false);
        LibraryWarehouse.FindZone(Zone, Location.Code, LibraryWarehouse.SelectBinType(false, false, true, true), false);
        LibraryWarehouse.FindBin(Bin, Location.Code, Zone.Code, 1);

        // [GIVEN] Lot-tracked item with mandatory expiration date.
        CreateItemWithItemTrackingCodeWithExpirateDate(Item);

        // [GIVEN] Post 10 pcs to the location via warehouse journal, assign lot no. "L", set up expiration date = "D".
        CreateAndRegisterWhseJnlLineWithLotAndExpDate(Bin, Item."No.", LotNo, ExpirationDate, 2 * Qty);
        CalculateAndPostWarehouseAdjustment(Item);

        // [GIVEN] First sales order for 5 pcs.
        // [GIVEN] Reserve the sales order from inventory.
        // [GIVEN] Release, create shipment and pick.
        CreateSalesOrderWithLocation(SalesHeader, SalesLine, Item."No.", Qty, Location.Code);
        LibrarySales.AutoReserveSalesLine(SalesLine);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SalesHeader."No.", WarehouseShipmentLine."Source Document"::"Sales Order");
        LibraryWarehouse.CreateWhsePick(WarehouseShipmentHeader);

        // [GIVEN] Second sales order for 5 pcs.
        // [GIVEN] Reserve, release, create warehouse shipment.
        CreateSalesOrderWithLocation(SalesHeader, SalesLine, Item."No.", Qty, Location.Code);
        LibrarySales.AutoReserveSalesLine(SalesLine);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SalesHeader."No.", WarehouseShipmentLine."Source Document"::"Sales Order");

        // [WHEN] Create pick for the warehouse shipment for the second sales order.
        LibraryWarehouse.CreateWhsePick(WarehouseShipmentHeader);

        // [THEN] Lot No. = "L" and Expiration Date = "D" on the pick line of type "Take".
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        LibraryWarehouse.FindWhseActivityLineBySourceDoc(
          WarehouseActivityLine, DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");

        WarehouseActivityLine.TestField("Bin Code", Bin.Code);
        WarehouseActivityLine.TestField("Lot No.", LotNo);
        WarehouseActivityLine.TestField("Expiration Date", ExpirationDate);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure NotesTransferredToPostedInventoryPick()
    var
        Location: Record Location;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        PostedInvtPickHeader: Record "Posted Invt. Pick Header";
        RecordLink: Record "Record Link";
    begin
        // [FEATURE] [Inventory Pick] [Record Link]
        // [SCENARIO 403945] Record links are transferred from inventory pick to posted inventory pick.
        Initialize();

        // [GIVEN] Location with required pick.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);

        // [GIVEN] Post inventory to the location.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, Item."No.", Location.Code, '', LibraryRandom.RandIntInRange(20, 40));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Sales order, release.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '',
          Item."No.", LibraryRandom.RandInt(10), Location.Code, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Create inventory pick, autofill quantity to handle.
        LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        WarehouseActivityHeader.FindFirst();
        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);

        // [GIVEN] Add a record link to the inventory pick.
        LibraryUtility.CreateRecordLink(WarehouseActivityHeader);

        // [WHEN] Post the inventory pick.
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] The record link has been transferred to posted inventory pick.
        PostedInvtPickHeader.SetRange("Invt Pick No.", WarehouseActivityHeader."No.");
        PostedInvtPickHeader.FindFirst();
        RecordLink.SetRange("Record ID", PostedInvtPickHeader.RecordId);
        Assert.RecordIsNotEmpty(RecordLink);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure NotesTransferredToPostedInventoryPutAway()
    var
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        PostedInvtPutAwayHeader: Record "Posted Invt. Put-away Header";
        RecordLink: Record "Record Link";
    begin
        // [FEATURE] [Inventory Put-away] [Record Link]
        // [SCENARIO 403945] Record links are transferred from inventory put-away to posted inventory put-away.
        Initialize();

        // [GIVEN] Location with required put-away.
        LibraryWarehouse.CreateLocationWMS(Location, false, true, false, false, false);

        // [GIVEN] Purchase order, release.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '',
          Item."No.", LibraryRandom.RandInt(10), Location.Code, WorkDate());
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Create inventory put-away, autofill quantity to handle.
        LibraryWarehouse.CreateInvtPutPickPurchaseOrder(PurchaseHeader);
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        WarehouseActivityHeader.FindFirst();
        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);

        // [GIVEN] Add a record link to the inventory put-away.
        LibraryUtility.CreateRecordLink(WarehouseActivityHeader);

        // [WHEN] Post the inventory put-away.
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] The record link has been transferred to posted inventory put-away.
        PostedInvtPutAwayHeader.SetRange("Invt. Put-away No.", WarehouseActivityHeader."No.");
        PostedInvtPutAwayHeader.FindFirst();
        RecordLink.SetRange("Record ID", PostedInvtPutAwayHeader.RecordId);
        Assert.RecordIsNotEmpty(RecordLink);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingPageHandler')]
    procedure PickingByFEFOWithNonSpecificSerialNoTrackingDPnPLocation()
    var
        Location: Record Location;
        Zone: Record Zone;
        Bin: Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        ReservationEntry: Record "Reservation Entry";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNo: Code[20];
        SerialNo: Code[20];
    begin
        // [FEATURE] [FEFO] [Pick] [Sales] [Item Tracking] [Directed Put-away and Pick]
        // [SCENARIO 404181] Picking by FEFO with lot warehouse tracking and non-specific serial no. tracking at location set up for directed put-away and pick.
        Initialize();
        LotNo := LibraryUtility.GenerateGUID();
        SerialNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Directed put-away and pick location with enabled FEFO.
        CreateFullWarehouseSetup(Location);
        UpdateParametersOnLocation(Location, true, false);
        LibraryWarehouse.FindZone(Zone, Location.Code, LibraryWarehouse.SelectBinType(false, false, true, true), false);
        LibraryWarehouse.FindBin(Bin, Location.Code, Zone.Code, 1);

        // [GIVEN] Lot-tracked item with mandatory expiration date.
        CreateItemWithItemTrackingCodeWithExpirateDate(Item);

        // [GIVEN] Post 10 pcs to the location via warehouse journal, assign lot no. "L", set up expiration date.
        CreateAndRegisterWhseJnlLineWithLotAndExpDate(
          Bin, Item."No.", LotNo, LibraryRandom.RandDate(10), LibraryRandom.RandIntInRange(10, 20));
        CalculateAndPostWarehouseAdjustment(Item);

        // [GIVEN] Sales order for 1 pc, select lot no. "L" and assign new serial no. "S1".
        CreateSalesOrderWithLocation(SalesHeader, SalesLine, Item."No.", 1, Location.Code);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine, SerialNo, LotNo, 1);

        // [GIVEN] Release the sales order, create warehouse shipment.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SalesHeader."No.", WarehouseShipmentLine."Source Document"::"Sales Order");

        // [WHEN] Create warehouse pick.
        LibraryWarehouse.CreateWhsePick(WarehouseShipmentHeader);

        // [THEN] A pick line has been created. Lot no. = "L".
        FindWarehouseActivityLine2(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take, Item."No.");
        WarehouseActivityLine.TestField("Lot No.", LotNo);

        // [THEN] The warehouse pick can be registered.
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] The warehouse shipment can be posted.
        WarehouseShipmentHeader.Find();
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
        SalesLine.Find();
        SalesLine.TestField("Quantity Shipped", 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure PickingByFEFOWithNonSpecificSerialNoTrackingNonDPnPLocation()
    var
        Location: Record Location;
        Bin: Record Bin;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        ReservationEntry: Record "Reservation Entry";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNo: Code[20];
        SerialNo: Code[20];
    begin
        // [FEATURE] [FEFO] [Pick] [Sales] [Item Tracking]
        // [SCENARIO 404181] Picking by FEFO with lot warehouse tracking and non-specific serial no. tracking at location set up for basic warehousing.
        Initialize();
        LotNo := LibraryUtility.GenerateGUID();
        SerialNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Location with mandatory bin, shipment, pick, and enabled FEFO.
        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, true);
        CreateWarehouseEmployee(Location.Code);
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        Location.Validate("Shipment Bin Code", Bin.Code);
        Location.Modify(true);
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');

        // [GIVEN] Lot-tracked item with mandatory expiration date.
        CreateItemWithItemTrackingCodeWithExpirateDate(Item);

        // [GIVEN] Post 10 pcs to the location via item journal, assign lot no. and expiration date.
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, Item."No.", Location.Code, Bin.Code, LibraryRandom.RandIntInRange(10, 20));
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJournalLine, '', LotNo, ItemJournalLine.Quantity);
        ReservationEntry.Validate("Expiration Date", LibraryRandom.RandDate(10));
        ReservationEntry.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Sales order for 1 pc, select lot no. "L" and assign new serial no. "S1".
        CreateSalesOrderWithLocation(SalesHeader, SalesLine, Item."No.", 1, Location.Code);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine, SerialNo, LotNo, 1);

        // [GIVEN] Release the sales order, create warehouse shipment.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SalesHeader."No.", WarehouseShipmentLine."Source Document"::"Sales Order");

        // [WHEN] Create warehouse pick.
        LibraryWarehouse.CreateWhsePick(WarehouseShipmentHeader);

        // [THEN] A pick line has been created. Lot no. = "L".
        FindWarehouseActivityLine2(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take, Item."No.");
        WarehouseActivityLine.TestField("Lot No.", LotNo);

        // [THEN] The warehouse pick can be registered.
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] The warehouse shipment can be posted.
        WarehouseShipmentHeader.Find();
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
        SalesLine.Find();
        SalesLine.TestField("Quantity Shipped", 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure ProperQuantityInPickWhenBinWithFirstExpiringLotIsBlocked()
    var
        Location: Record Location;
        Item: Record Item;
        Bin: array[3] of Record Bin;
        BinContent: Record "Bin Content";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNos: array[4] of Code[20];
        Qty: Decimal;
        i: Integer;
    begin
        // [FEATURE] [FEFO] [Pick] [Sales] [Item Tracking] [Bin]
        // [SCENARIO 412045] Proper quantity in pick by FEFO when the bin containing first expiring lot is blocked.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(10, 20);
        for i := 1 to ArrayLen(LotNos) do
            LotNos[i] := LibraryUtility.GenerateGUID();

        // [GIVEN] Location with mandatory bin, shipment, pick, and enabled FEFO.
        // [GIVEN] Bins "B1", "B2", and "B3". Bin "B1" is set up for shipment.
        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, true);
        CreateWarehouseEmployee(Location.Code);
        LibraryWarehouse.CreateBin(Bin[1], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        Location.Validate("Shipment Bin Code", Bin[1].Code);
        Location.Modify(true);
        LibraryWarehouse.CreateBin(Bin[2], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBin(Bin[3], Location.Code, LibraryUtility.GenerateGUID(), '', '');

        // [GIVEN] Lot-tracked item with mandatory expiration date.
        CreateItemWithItemTrackingCodeWithExpirateDate(Item);

        // [GIVEN] Post 4 item journal lines:
        // [GIVEN] Line 1: bin "B2", lot "L1", quantity = 5, expiration date = WorkDate() + 30 days.
        // [GIVEN] Line 2: bin "B2", lot "L2", quantity = 5, expiration date = WorkDate() + 40 days.
        // [GIVEN] Line 3: bin "B2", lot "L3", quantity = 5, expiration date = WorkDate() + 50 days.
        // [GIVEN] Line 4: bin "B3", lot "L4", quantity = 5, expiration date = WorkDate() + 20 days (the first expiring lot!)
        CreateAndPostItemJnlLineWithLotAndExpirationDate(Item."No.", LotNos[1], WorkDate() + 30, Location.Code, Bin[2].Code, Qty);
        CreateAndPostItemJnlLineWithLotAndExpirationDate(Item."No.", LotNos[2], WorkDate() + 40, Location.Code, Bin[2].Code, Qty);
        CreateAndPostItemJnlLineWithLotAndExpirationDate(Item."No.", LotNos[3], WorkDate() + 50, Location.Code, Bin[2].Code, Qty);
        CreateAndPostItemJnlLineWithLotAndExpirationDate(Item."No.", LotNos[4], WorkDate() + 20, Location.Code, Bin[3].Code, Qty);

        // [GIVEN] Block bin "B3" containing the first expiring lot "L4".
        FindBinContentWithBinCode(BinContent, Bin[3], Item."No.");
        BinContent.Validate("Block Movement", BinContent."Block Movement"::Outbound);
        BinContent.Modify(true);

        // [GIVEN] Sales order for 5 pcs, release.
        // [GIVEN] Create warehouse shipment and pick, note lot no. = "L1", register pick.
        CreateSalesOrderWithLocation(SalesHeader, SalesLine, Item."No.", Qty, Location.Code);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SalesHeader."No.", WarehouseShipmentLine."Source Document"::"Sales Order");
        LibraryWarehouse.CreateWhsePick(WarehouseShipmentHeader);
        FindWarehouseActivityLine2(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take, Item."No.");
        WarehouseActivityLine.TestField("Lot No.", LotNos[1]);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [GIVEN] Sales order for 10 pcs, release.
        // [GIVEN] Create warehouse shipment.
        CreateSalesOrderWithLocation(SalesHeader, SalesLine, Item."No.", 2 * Qty, Location.Code);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SalesHeader."No.", WarehouseShipmentLine."Source Document"::"Sales Order");

        // [WHEN] Create warehouse pick.
        LibraryWarehouse.CreateWhsePick(WarehouseShipmentHeader);

        // [THEN] Warehouse pick for 10 pcs is created - 5 pcs of lot "L2" and 5 pcs of lot "L3".
        FindWarehouseActivityLine2(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take, Item."No.");
        WarehouseActivityLine.TestField("Lot No.", LotNos[2]);
        WarehouseActivityLine.TestField(Quantity, Qty);

        WarehouseActivityLine.Next();
        WarehouseActivityLine.TestField("Lot No.", LotNos[3]);
        WarehouseActivityLine.TestField(Quantity, Qty);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingPageHandler')]
    procedure NonSpecificReservationWithOutstandingPickAsSpecificForFEFO()
    var
        Location: Record Location;
        Zone: Record Zone;
        Bin: array[2] of Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNos: array[2] of Code[20];
    begin
        // [FEATURE] [FEFO] [Reservation] [Item Tracking] [Pick]
        // [SCENARIO 415146] Non-specific reservation is considered specific for FEFO picking if the lot or serial no. is included in outstanding pick.
        Initialize();

        // [GIVEN] Location set up for directed put-away and pick and FEFO enabled.
        CreateFullWarehouseSetup(Location);
        UpdateParametersOnLocation(Location, true, false);
        LibraryWarehouse.FindZone(Zone, Location.Code, LibraryWarehouse.SelectBinType(false, false, true, true), false);

        // [GIVEN] Lot-tracked item with mandatory expiration date.
        CreateItemWithItemTrackingCodeWithExpirateDate(Item);

        // [GIVEN] Post 10 pcs to bin "B1", assign lot "L1" with expiration date = Workdate.
        // [GIVEN] Post 10 pcs to bin "B2", assign lot "L2" with expiration date = WorkDate() + 1 week.
        LibraryWarehouse.FindBin(Bin[1], Location.Code, Zone.Code, 1);
        LibraryWarehouse.FindBin(Bin[2], Location.Code, Zone.Code, 2);
        LotNos[1] := LibraryUtility.GenerateGUID();
        CreateAndRegisterWhseJnlLineWithLotAndExpDate(Bin[1], Item."No.", LotNos[1], WorkDate(), 10);
        LotNos[2] := LibraryUtility.GenerateGUID();
        CreateAndRegisterWhseJnlLineWithLotAndExpDate(Bin[2], Item."No.", LotNos[2], LibraryRandom.RandDate(10), 10);
        CalculateAndPostWarehouseAdjustment(Item);

        // [GIVEN] Sales order "SO1" for 5 pcs, auto reserve.
        // [GIVEN] Release the order, create warehouse shipment and pick.
        CreateSalesOrderWithLocation(SalesHeader, SalesLine, Item."No.", 5, Location.Code);
        LibrarySales.AutoReserveSalesLine(SalesLine);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        CreatePickFromSalesHeader(SalesHeader);

        // [GIVEN] Sales order "SO2" for 10 pcs, auto reserve.
        // [GIVEN] Release the order, create warehouse shipment.
        CreateSalesOrderWithLocation(SalesHeader, SalesLine, Item."No.", 10, Location.Code);
        LibrarySales.AutoReserveSalesLine(SalesLine);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN] Create pick for the order "SO2".
        CreatePickFromSalesHeader(SalesHeader);

        // [THEN] The pick suggests picking 5 pcs of lot "L1" from bin "B1" and 5 pcs of lot "L2" from bin "B2".
        // [THEN] First 5 pcs of lot "L1" are considered reserved by the sales order "SO1".
        FindWarehouseActivityHeaderBySourceNo(WarehouseActivityHeader, Location.Code, SalesHeader."No.");
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.FindFirst();
        VerifyWarehouseActivityLines(WarehouseActivityLine, Bin[1].Code, LotNos[1], '', 5);
        VerifyWarehouseActivityLines(WarehouseActivityLine, Bin[2].Code, LotNos[2], '', 5);
    end;

    [Test]
    procedure NoOverPickOnPlaceLineInWarehousePickWithBreakbulk()
    var
        Location: Record Location;
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Bin: array[2] of Record Bin;
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Qty: Decimal;
        QtyPer: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Breakbulk] [UoM]
        // [SCENARIO 440120] No overpick on place line in warehouse pick with breakbulk.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(5, 10);
        QtyPer := LibraryRandom.RandIntInRange(20, 40);

        // [GIVEN] Location set up for directed put-away and pick.
        CreateFullWarehouseSetup(Location);

        // [GIVEN] Item with base unit of measure = "PCS" and alternate UoM = "BOX" = 20 "PCS".
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", QtyPer);

        // [GIVEN] Locate bins "B1" and "B2".
        FindBin(Bin[1], Location.Code);
        FindAnotherBinInZone(Bin[2], Bin[1]);

        // [GIVEN] Post inventory via the warehouse journal: 2 "BOX" + 2 "PCS" into each bin.
        // [GIVEN] That makes 2 * (2 * 20 + 2) = 84 "PCS" in total.
        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Type::Item, Location.Code);
        for i := 1 to ArrayLen(Bin) do begin
            LibraryWarehouse.CreateWhseJournalLine(
              WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name,
              Location.Code, Bin[i]."Zone Code", Bin[i].Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Qty);
            WarehouseJournalLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
            WarehouseJournalLine.Modify();

            LibraryWarehouse.CreateWhseJournalLine(
              WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name,
              Location.Code, Bin[i]."Zone Code", Bin[i].Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Qty);
        end;
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name",
          WarehouseJournalLine."Location Code", true);
        LibraryWarehouse.PostWhseAdjustment(Item);

        // [GIVEN] Create sales order for 50 "PCS", release.
        Item.CalcFields(Inventory);
        CreateAndReleaseSalesOrder(
          SalesHeader, SalesLine, Item."No.", Location.Code, LibraryRandom.RandIntInRange(Item.Inventory / 2, Item.Inventory));

        // [WHEN] Create shipment and pick.
        CreatePickFromSalesHeader(SalesHeader);

        // [THEN] Sum of quantity to take = sum of quantity to place = 50 "PCS" in the warehouse pick.
        WarehouseActivityLine.SetRange("Breakbulk No.", 0);
        FindWarehouseActivityLine2(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take, Item."No.");
        WarehouseActivityLine.CalcSums(Quantity, "Qty. (Base)");
        WarehouseActivityLine.TestField(Quantity, SalesLine.Quantity);
        WarehouseActivityLine.TestField("Qty. (Base)", SalesLine."Quantity (Base)");

        FindWarehouseActivityLine2(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Place, Item."No.");
        WarehouseActivityLine.CalcSums(Quantity, "Qty. (Base)");
        WarehouseActivityLine.TestField(Quantity, SalesLine.Quantity);
        WarehouseActivityLine.TestField("Qty. (Base)", SalesLine."Quantity (Base)");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CreateMovementWithBinReplenishmentForBasicWarehouse()
    var
        Item: Record Item;
        Bin: Record Bin;
        Bin2: Record Bin;
        ItemJournalLine: Record "Item Journal Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] Test and verify Bin Replenishment is calculated and Inventory Movement created for basic warehouse.

        // [GIVEN] Setup: Create Initial Setup for Bin Replenishment. Calculate Bin Replenishment for basic warehouse.
        Initialize();
        CreateInitialSetupForBinReplenishment(Item, Bin, Bin2, ItemJournalLine);
        CalculateBinReplenishment(Bin."Location Code");

        // [WHEN] Exercise: Create Movement.
        CreateMovement(Item."No.");

        // [THEN] Verify: Verify values on Inventory Movement.
        FindWarehouseActivityHeader(WarehouseActivityHeader, Bin."Location Code", WarehouseActivityHeader.Type::"Invt. Movement");
        VerifyWarehouseMovementLine(WarehouseActivityHeader, WarehouseActivityLine."Action Type"::Take, Item."No.", Bin.Code, ItemJournalLine.Quantity);
        VerifyWarehouseMovementLine(WarehouseActivityHeader, WarehouseActivityLine."Action Type"::Place, Item."No.", Bin2.Code, ItemJournalLine.Quantity);
    end;

    [Test]
    procedure ExcludeShipmentBinFromPickingByFEFOAtNonDPnPLocation()
    var
        Item: Record Item;
        Location: Record Location;
        PickBin: Record Bin;
        ShipBin: Record Bin;
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNos: array[2] of Code[50];
        Qty: Decimal;
    begin
        // [FEATURE] [Item Tracking] [FEFO] [Pick]
        // [SCENARIO 450116] Picking by FEFO at non-directed put-away and pick location must exclude Shipment Bin Code.
        Initialize();
        Qty := LibraryRandom.RandInt(10);
        LotNos[1] := LibraryUtility.GenerateGUID();
        LotNos[2] := LibraryUtility.GenerateGUID();

        // [GIVEN] Location with required shipment and pick.
        // [GIVEN] Bin "A" is set up as a shipment bin.
        // [GIVEN] Bin "B" is just an ordinary bin.
        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, true);
        UpdateParametersOnLocation(Location, true, false);
        LibraryWarehouse.CreateBin(PickBin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBin(ShipBin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        Location.Validate("Shipment Bin Code", ShipBin.Code);
        Location.Modify(true);

        // [GIVEN] Lot-tracked item.
        // [GIVEN] Post 1 pc of lot "L1" to bin "A"
        // [GIVEN] Post 1 pc of lot "L2" to bin "B" using item journal.
        CreateItemWithItemTrackingCodeForLot(Item);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, ShipBin.Code, Qty);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJournalLine, '', LotNos[1], ItemJournalLine.Quantity);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, PickBin.Code, Qty);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJournalLine, '', LotNos[2], ItemJournalLine.Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create sales order for 1 pc, release.
        CreateSalesOrderWithLocation(SalesHeader, SalesLine, Item."No.", Qty, Location.Code);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN] Create warehouse shipment and pick.
        CreatePickFromSalesHeader(SalesHeader);

        // [THEN] Lot "L2" from bin "B" has been picked.
        FindWarehouseActivityLine2(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take,
          Item."No.");
        WarehouseActivityLine.TestField("Lot No.", LotNos[2]);
        WarehouseActivityLine.TestField("Bin Code", PickBin.Code);
    end;

    [Test]
    [HandlerFunctions('BinContentsListModalPageHandler')]
    procedure S469775_WhseReclassificationJournal_FromBinCodeLookupOpensBinContentPage()
    var
        Location: Record Location;
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WhseReclassificationJournal: TestPage "Whse. Reclassification Journal";
    begin
        // [FEATURE] [Whse. Reclassification Journal] [From Bin Code] [Bin Contents List]
        // [SCENARIO 469775] Warehouse Reclassification Journal - From Bin Code lookup opens Bin Contents List page.
        Initialize();

        // [GIVEN] Create Location with "Directed Put-away and Pick" and set Warehouse Employee for Location as default.
        CreateFullWarehouseSetup(Location);

        // [GIVEN] Create Warehouse Reclassification Journal.
        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, "Warehouse Journal Template Type"::Reclassification, Location.Code);
        Commit();

        // [GIVEN] Open Warehouse Reclassification Journal.
        WhseReclassificationJournal.OpenEdit();
        WhseReclassificationJournal.CurrentLocationCode.SetValue(Location.Code);
        WhseReclassificationJournal.CurrentJnlBatchName.SetValue(WarehouseJournalBatch.Name);
        WhseReclassificationJournal."Whse. Document No.".SetValue(WarehouseJournalBatch.Name);

        // [WHEN] Run "From Bin Code" field lookup.
        WhseReclassificationJournal."From Bin Code".Lookup(); // Uses BinContentsListModalPageHandler.

        // [THEN] Bin Contents List Modal Page is opened on "From Bin Code" field lookup.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure PostInventoryPickWhileCreatingNewPickOne()
    var
        Item: Record Item;
        Location: Record Location;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        SCMWarehouseVI: Codeunit "SCM Warehouse VI";
    begin
        // [FEATURE] [Inventory Pick]
        // [SCENARIO 474505] "Create Invt Put-away/Pick/Mvmt" report does not fail when Warehouse Request is deleted after the record is retrieved by the report.
        Initialize();

        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);

        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, '', LibraryRandom.RandInt(10));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        CreateSalesOrderWithLocation(SalesHeader, SalesLine, Item."No.", 1, Location.Code);
        SalesHeader.Validate("Shipping Advice", SalesHeader."Shipping Advice"::Complete);
        SalesHeader.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        WarehouseActivityHeader.FindFirst();
        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);

        BindSubscription(SCMWarehouseVI);
        LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);
        UnbindSubscription(SCMWarehouseVI);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure PostInventoryPickWhileCreatingNewPickTwo()
    var
        Item: Record Item;
        Location: Record Location;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        SCMWarehouseVI: Codeunit "SCM Warehouse VI";
    begin
        // [FEATURE] [Inventory Pick]
        // [SCENARIO 474505] "Create Inventory Pick/Movement" codeunit does not fail when Warehouse Request is deleted after the record is retrieved by the report.        
        Initialize();

        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);

        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, '', LibraryRandom.RandInt(10));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        CreateSalesOrderWithLocation(SalesHeader, SalesLine, Item."No.", 1, Location.Code);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        WarehouseActivityHeader.FindFirst();
        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);

        BindSubscription(SCMWarehouseVI);
        LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);
        UnbindSubscription(SCMWarehouseVI);
    end;

    [Test]
    procedure WhsePickWithItemTrackingForNegativePurchOrderLine()
    var
        Location: Record Location;
        PickBin, ShipmentBin : Record Bin;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        SerialNo: Code[50];
    begin
        // [SCENARIO 545340] User can register warehouse pick with item tracking for negative purchase order line.
        Initialize();
        SerialNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Location with mandatory bin, shipment, and pick.
        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, true);
        CreateWarehouseEmployee(Location.Code);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 2, false);
        LibraryWarehouse.FindBin(PickBin, Location.Code, '', 1);
        LibraryWarehouse.FindBin(ShipmentBin, Location.Code, '', 2);
        Location.Validate("Shipment Bin Code", ShipmentBin.Code);
        Location.Modify(true);

        // [GIVEN] Item with serial no. tracking.
        // [GIVEN] Post item journal line with serial no. to the location.
        CreateItemWithItemTrackingCodeForSerialNo(Item);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, PickBin.Code, 1);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJournalLine, SerialNo, '', ItemJournalLine.Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Negative purchase order line for -1 pc.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', Item."No.", -1, Location.Code, WorkDate());
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Create warehouse shipment from purchase order.
        LibraryWarehouse.CreateWhseShipmentFromPurchaseReturnOrder(PurchaseHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, PurchaseHeader."No.", WarehouseShipmentLine."Source Document"::"Purchase Order");

        // [GIVEN] Create warehouse pick.
        LibraryWarehouse.CreateWhsePick(WarehouseShipmentHeader);

        // [GIVEN] Assign serial no. to the pick lines.
        FindWarehouseActivityLine(WarehouseActivityLine, PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.ModifyAll("Serial No.", SerialNo, true);

        // [WHEN] Register warehouse pick.
        RegisterWarehouseActivityHeader(Location.Code, WarehouseActivityLine."Activity Type"::Pick);

        // [THEN] The warehouse pick is registered.
        // [THEN] The warehouse shipment can be posted.
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [THEN] The purchase order line is received, quantity received = -1.
        PurchaseLine.Find();
        PurchaseLine.TestField("Quantity Received", -1);
    end;

    [Test]
    [HandlerFunctions('PhysicalInventoryItemSelectionHandler,CalculatePhysicalInventoryCountingHandler')]
    [Scope('OnPrem')]
    procedure ReasonCodeTransferredToWhsePhysInvtJournalWithCalculateCountingPeriod()
    var
        Bin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        PhysInvtCountingPeriod: Record "Phys. Invt. Counting Period";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        ReasonCode: Record "Reason Code";
    begin
        // [SCENARIO 566142] Reason Code not transfered to Warehouse Physical Inventory Journal line with the 'Calculate Counting Period' functionality.
        Initialize();

        // [GIVEN] Setup: Create full Warehouse Setup with Location and Reason Code
        CreateFullWarehouseSetup(Location);
        LibraryERM.CreateReasonCode(ReasonCode);

        // [GIVEN] Create Item with Physical Inventory Counting Period.
        CreateItemWithPhysicalInventoryCountingPeriod(Item, PhysInvtCountingPeriod);
        FindBin(Bin, Location.Code);

        // [GIVEN] Create and register Warehouse Journal Line. Calculate and post Warehouse Adjustment.
        CreateAndRegisterWarehouseJournalLine(
            WarehouseJournalLine, WarehouseJournalLine."Entry Type"::"Positive Adjmt.",
            Bin, Item."No.", LibraryRandom.RandDec(100, 2));//, ReasonCode.Code);  // Using random Quantity.
        CalculateAndPostWarehouseAdjustment(Item);

        // [WHEN] Exercise: Run Calculate Counting Period from Warehouse Physical Inventory Journal.
        CalcPhysInvtDatesAndRunCalculateCountingPeriodInWhseInvtJournalReasonCode(
            WarehouseJournalBatch, Item."No.", Location.Code, Item."Last Counting Period Update",
            PhysInvtCountingPeriod."Count Frequency per Year", ReasonCode.Code);

        // [THEN] Verify Warehouse Physical Inventory Journal Line.
        VerifyWarehouseJournalLineWithReasonCode(WarehouseJournalBatch, WarehouseJournalLine, ReasonCode.Code);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure InvDiscPctAndAmtInSOIsNotZeroWhenCreateAndShipInvPickFromSOHavingInvDiscPctAndAmt()
    var
        Bin: Record Bin;
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseActivityPost: Codeunit "Whse.-Activity-Post";
        SalesOrder: TestPage "Sales Order";
        InvDiscountPct: Decimal;
    begin
        // [SCENARIO 256471] It should not be allowed to change location code in an inventory pick that has lines
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a Location.
        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, false);

        // [GIVEN] Create a Bin.
        LibraryWarehouse.CreateBin(Bin, Location.Code, Bin.Code, '', '');

        // [GIVEN] Create a Warehouse Employee.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Create a Customer and Validate "Currency Code".
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CreateCurrency());
        Customer.Modify(true);

        // [GIVEN] Create an Item Journal Line and Post it.
        CreateItemJournalLine(ItemJournalLine, Item."No.", Location.Code, LibraryRandom.RandIntInRange(20, 20), WorkDate(), Bin.Code, Item."Base Unit of Measure");
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Update Work Date.
        WorkDate(CalcDate('<CY+1M+1D>', WorkDate()));

        // [GIVEN] Create a Sales Header.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Currency Factor", LibraryRandom.RandIntInRange(2, 2));
        SalesHeader.Modify(true);

        // [GIVEN] Create a Sales Line and Validate "Location Code" and "Unit Price".
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(0));
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(1000, 1000));
        SalesLine.Modify(true);

        // [GIVEN] Generate and save Invoice Discount % in a Variable.
        InvDiscountPct := LibraryRandom.RandIntInRange(10, 10);

        // [GIVEN] Open Sales Order page and Set Invoice Disc. Pct.
        SalesOrder.OpenEdit();
        SalesOrder.GoToRecord(SalesHeader);
        SalesOrder.SalesLines."Invoice Disc. Pct.".SetValue(InvDiscountPct);
        SalesOrder.Close();

        // [GIVEN] Find Sales Header.
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");

        // [GIVEN] Release Sales Order.
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Create Invt. Pick from Sales Order.
        LibraryVariableStorage.Enqueue(InvtPickCreatedTxt);
        LibraryWarehouse.CreateInvtPutPickMovement(
            WarehouseActivityHeader."Source Document"::"Sales Order", SalesHeader."No.", false, true, false);

        // [GIVEN] Find Warehouse Activity Line.
        FindWarehouseActivityLine(
            WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
            WarehouseActivityLine."Activity Type"::"Invt. Pick");

        // [GIVEN] Find Warehouse Activity Header and Validate "Posting Date".
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        WarehouseActivityHeader.Validate("Posting Date", CalcDate('<CY+1M+14D>', WorkDate()));
        WarehouseActivityHeader.Modify(true);

        // [GIVEN] Validate "Qty. to Handle" in Warehouse Activity Line.
        WarehouseActivityLine.Validate("Qty. to Handle", WarehouseActivityLine.Quantity);
        WarehouseActivityLine.Modify(true);

        // [GIVEN] Update Work Date.
        WorkDate(WarehouseActivityHeader."Posting Date");

        // [GIVEN] Post Inventory Pick.
        WhseActivityPost.Run(WarehouseActivityLine);

        // [GIVEN] Find Sales Header.
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");

        // [WHEN] Open Sales Order page.
        SalesOrder.OpenEdit();
        SalesOrder.GoToRecord(SalesHeader);

        // [THEN] Invoice Disc. Pct. is equal to InvDiscountPct.
        SalesOrder.SalesLines."Invoice Disc. Pct.".AssertEquals(InvDiscountPct);
        SalesOrder.Close();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Warehouse VI");
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();
        // Clear global variables.
        Clear(ConfirmMessage);

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Warehouse VI");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        isInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"Warehouse Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Warehouse VI");
    end;

    local procedure WarehouseSetupShipmentPostingPolicyShowErrorOn()
    var
        WarehouseSetup: Record "Warehouse Setup";
    begin
        WarehouseSetup.Get();
        WarehouseSetup.Validate(
          "Shipment Posting Policy", WarehouseSetup."Shipment Posting Policy"::"Stop and show the first posting error");
        WarehouseSetup.Modify(true);
    end;

    local procedure AutofillQuantityToHandle(TransferHeaderNo: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, TransferHeaderNo, WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
    end;

    local procedure BlockedLotNoInformation(ItemNo: Code[20]; LotNo: Code[50]; BlockLot: Boolean)
    var
        LotNoInformation: Record "Lot No. Information";
    begin
        LibraryItemTracking.CreateLotNoInformation(LotNoInformation, ItemNo, '', LotNo);
        LotNoInformation.Validate(Blocked, BlockLot);
        LotNoInformation.Modify(true);
    end;

    local procedure BlockedSerialNoInformation(ItemNo: Code[20]; SerialNo: Code[50]; BlockLot: Boolean)
    var
        SerialNoInformation: Record "Serial No. Information";
    begin
        LibraryItemTracking.CreateSerialNoInformation(SerialNoInformation, ItemNo, '', SerialNo);
        SerialNoInformation.Validate(Blocked, BlockLot);
        SerialNoInformation.Modify(true);
    end;

    local procedure CalculateBinReplenishment(LocationCode: Code[10])
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.FindFirst();
        CalculateBinReplenishmentForBinContent(LocationCode, BinContent);
    end;

    local procedure CalculateBinReplenishmentForBinContent(LocationCode: Code[10]; BinContent: Record "Bin Content")
    var
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
    begin
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Movement);
        LibraryWarehouse.SelectWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, LocationCode);
        LibraryWarehouse.CalculateBinReplenishment(BinContent, WhseWorksheetName, LocationCode, true, false, false);
    end;

    local procedure CalcRegenPlanAndCarryOutActionMsg(Item: Record Item)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        Item.SetRecFilter();
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");
        RequisitionLine.FindFirst();
        RequisitionLine.Validate("Accept Action Message", true);
        RequisitionLine.Modify(true);

        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
    end;

    local procedure CreateAndCertifyProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; ItemNo3: Code[20]; UnitOfMeasureCode: Code[10]; QtyPer: Decimal)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UnitOfMeasureCode);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo3, QtyPer);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CalculateAndPostWarehouseAdjustment(Item: Record Item)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        SelectItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; LocationCode: Code[10])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        SelectItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo,
          LibraryRandom.RandDec(100, 2));  // Use random Quantity.
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostItemJournalLineWithItemTracking(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalLine: Record "Item Journal Line";
    begin
        SelectItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase, ItemNo,
          Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
        ItemJournalLine.OpenItemTrackingLines(true);  // Execute ItemTrackingLinesHandler for assigning Item Tracking lines.
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostItemJnlLineWithLotAndExpirationDate(ItemNo: Code[20]; LotNo: Code[20]; ExpirationDate: Date; LocationCode: Code[10]; BinCode: Code[20]; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, BinCode, Qty);
        LibraryItemTracking.CreateItemJournalLineItemTracking(
            ReservationEntry, ItemJournalLine, '', LotNo, ItemJournalLine.Quantity);
        ReservationEntry.Validate("Expiration Date", ExpirationDate);
        ReservationEntry.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; SourceNo: Code[20]; LocationCode: Code[10])
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, SourceNo,
          LibraryRandom.RandDec(10, 2));  // Use random Quantity.
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateAndRegisterPutAwayFromPurchaseOrder(LocationCode: Code[10]; ItemNo: Code[20]; IsTracking: Boolean): Decimal
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, LocationCode, ItemNo, LibraryRandom.RandDec(100, 2));
        if IsTracking then
            PurchaseLine.OpenItemTrackingLines();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        PostWarehouseReceipt(PurchaseHeader."No.");
        RegisterWarehouseActivityHeader(LocationCode, WarehouseActivityHeader.Type::"Put-away");
        exit(PurchaseLine.Quantity);
    end;

    local procedure CreateAndRegisterPickFromSalesOrder(var SalesHeader: Record "Sales Header"; LocationCode: Code[10])
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        CreatePickFromSalesHeader(SalesHeader);
        InvokeAutofillQuantityToHandleOnPick(LocationCode);
        RegisterWarehouseActivityHeader(LocationCode, WarehouseActivityHeader.Type::Pick);
    end;

    local procedure CreateAndRegisterWarehouseJournalLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; EntryType: Option; Bin: Record Bin; ItemNo: Code[20]; Quantity: Decimal)
    var
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
    begin
        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Type::Item, Bin."Location Code");
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Bin."Location Code",
          Bin."Zone Code", Bin.Code, EntryType, ItemNo, Quantity);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", WarehouseJournalLine."Location Code",
          true);
    end;

    local procedure CreateAndRegisterWarehouseItemJournalWithItemTracking(var WarehouseJournalBatch: Record "Warehouse Journal Batch"; var WarehouseJournalLine: Record "Warehouse Journal Line"; BinCode: Code[20]; LocationCode: Code[10]; ZoneCode: Code[10]; EntryType: Option; ItemNo: Code[20]; Quantity: Decimal; ExpirationDate: Date; TrackingAction: Option)
    begin
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name",
          WarehouseJournalBatch.Name, LocationCode, ZoneCode, BinCode, EntryType, ItemNo, Quantity);

        LibraryVariableStorage.Enqueue(TrackingAction);
        WarehouseJournalLine.OpenItemTrackingLines();
        if ExpirationDate <> 0D then
            UpdateExpirationDateOnWhseItemTrackingLine(ItemNo, '', ExpirationDate);

        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationCode, true);
    end;

    local procedure CreateAndRegisterWhseJnlLineWithLotAndExpDate(Bin: Record Bin; ItemNo: Code[20]; LotNo: Code[50]; ExpirationDate: Date; Quantity: Decimal)
    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Type::Item, Bin."Location Code");
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name,
          Bin."Location Code", Bin."Zone Code", Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);

        LibraryVariableStorage.Enqueue(TrackingActionStr::AssignGivenLotNo);
        LibraryVariableStorage.Enqueue(LotNo);
        WarehouseJournalLine.OpenItemTrackingLines();
        UpdateExpirationDateOnWhseItemTrackingLine(ItemNo, LotNo, ExpirationDate);

        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Bin."Location Code", true);
    end;

    local procedure CreateAndRegisterWhseJnlLineWithLotAndUoM(Bin: Record Bin; ItemNo: Code[20]; LotNo: Code[50]; Quantity: Decimal; UnitsOfMeasure: Code[10])
    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Type::Item, Bin."Location Code");
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name,
          Bin."Location Code", Bin."Zone Code", Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        WarehouseJournalLine.Validate("Unit of Measure Code", UnitsOfMeasure);
        WarehouseJournalLine.Modify();
        // Enqueue values for WhseItemTrackingLinesModalPageHandler
        LibraryVariableStorage.Enqueue(TrackingActionStr::AssignGivenLotNo);
        LibraryVariableStorage.Enqueue(LotNo);
        WarehouseJournalLine.OpenItemTrackingLines();
        LibraryVariableStorage.AssertEmpty();

        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Bin."Location Code", true);
    end;

    local procedure CreateWhseJournalLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; EntryType: Option; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; ZoneCode: Code[10]; BinCode: Code[20])
    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
    begin
        LibraryWarehouse.SelectWhseJournalTemplateName(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::Item);
        LibraryWarehouse.SelectWhseJournalBatchName(
          WarehouseJournalBatch, WarehouseJournalTemplate.Type, WarehouseJournalTemplate.Name, LocationCode);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name, LocationCode, ZoneCode, BinCode,
          EntryType, ItemNo, Quantity);
    end;

    local procedure CreateWarehouseReclassJournal(var WhseReclassificationJournal: TestPage "Whse. Reclassification Journal"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        BinContent: Record "Bin Content";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        BinCode: Code[20];
    begin
        FindBinContent(BinContent, ItemNo);
        BinCode := FindEmptyBin(LocationCode, BinContent."Zone Code");
        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Type::Reclassification, LocationCode);
        Commit();
        WhseReclassificationJournal.OpenEdit();
        WhseReclassificationJournal.CurrentLocationCode.SetValue(LocationCode);
        WhseReclassificationJournal.CurrentJnlBatchName.SetValue(WarehouseJournalBatch.Name);
        WhseReclassificationJournal."Whse. Document No.".SetValue(WarehouseJournalBatch.Name);
        WhseReclassificationJournal."Item No.".SetValue(ItemNo);
        WhseReclassificationJournal."From Zone Code".SetValue(BinContent."Zone Code");
        WhseReclassificationJournal."From Bin Code".SetValue(BinContent."Bin Code");
        WhseReclassificationJournal."To Zone Code".SetValue(BinContent."Zone Code");
        WhseReclassificationJournal."To Bin Code".SetValue(BinCode);
        WhseReclassificationJournal.Quantity.SetValue(Quantity);
    end;

    local procedure CreateAndRefreshProdOrderOnLocation(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, Qty);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, true);
    end;

    local procedure CreateAndReleasePurchaseOrder(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        CreateAndUpdatePurchaseLine(PurchaseLine, PurchaseHeader, ItemNo, LocationCode);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndReleaseSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        CreateSalesOrderWithLocation(SalesHeader, SalesLine, ItemNo, Quantity, LocationCode);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleaseSalesOrderWithItemTracking(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; ItemUnitOfMeasure: Code[10]; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesOrderWithLocation(SalesHeader, SalesLine, ItemNo, Quantity, LocationCode);
        UpdateUnitOfMeasureOnSalesLine(SalesLine, ItemUnitOfMeasure);
        SalesLine.OpenItemTrackingLines();
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleaseWarehouseShipmentFromSalesOrder(SalesHeader: Record "Sales Header"; LocationCode: Code[10])
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeader.SetRange("Location Code", LocationCode);
        WarehouseShipmentHeader.FindFirst();
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);
    end;

    local procedure CreateAndReleaseTransferOrder(var TransferHeader: Record "Transfer Header"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        TransferLine: Record "Transfer Line";
        Location: Record Location;
    begin
        CreateLocationInTransit(Location);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, Location.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
    end;

    local procedure CreateAndPostWarehouseReceiptFromPurchaseOrder(var PurchaseLine: Record "Purchase Line"; LocationCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
    begin
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, LocationCode, LibraryInventory.CreateItem(Item), LibraryRandom.RandIntInRange(50, 100));
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        PostWarehouseReceipt(PurchaseHeader."No.");
    end;

    local procedure CreateAndReleaseWarehouseShipmentFromTransferOrder(TransferHeader: Record "Transfer Header")
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);
        FindWarehouseShipmentHeader(
          WarehouseShipmentHeader, TransferHeader."No.", WarehouseShipmentLine."Source Document"::"Outbound Transfer");
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);
    end;

    local procedure CreateAndUpdateFullWareHouseSetup(var Location: Record Location)
    begin
        CreateFullWarehouseSetup(Location);
        Location.Validate("Use Put-away Worksheet", true);
        Location.Modify(true);
    end;

    local procedure CreateAndUpdateLocation(var Location: Record Location; RequireReceive: Boolean; RequireShipment: Boolean)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Require Put-away", true);
        Location.Validate("Always Create Put-away Line", true);
        Location.Validate("Require Receive", RequireReceive);
        Location.Validate("Require Pick", true);
        Location.Validate("Require Shipment", RequireShipment);
        if Location."Require Pick" then
            if Location."Require Shipment" then
                Location."Prod. Consump. Whse. Handling" := Location."Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)"
            else
                Location."Prod. Consump. Whse. Handling" := Location."Prod. Consump. Whse. Handling"::"Inventory Pick/Movement";

        if Location."Require Put-away" then
            Location."Prod. Output Whse. Handling" := Location."Prod. Output Whse. Handling"::"Inventory Put-away";

        Location.Modify(true);
    end;

    local procedure CreateAndUpdateLocationForBinContent(var Location: Record Location)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Modify(true);
    end;

    local procedure CreateAndUpdatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandIntInRange(10, 20));
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateBinContent(var BinContent: Record "Bin Content"; Bin: Record Bin; Item: Record Item; UnitOfMeasureCode: Code[10]; MinQty: Decimal; MaxQty: Decimal)
    begin
        LibraryWarehouse.CreateBinContent(
          BinContent, Bin."Location Code", Bin."Zone Code", Bin.Code, Item."No.", '', UnitOfMeasureCode);
        BinContent.Validate("Bin Type Code", FindBinType());
        BinContent.Validate("Bin Ranking", Bin."Bin Ranking");
        BinContent.Validate(Fixed, true);
        BinContent.Validate("Min. Qty.", MinQty);
        BinContent.Validate("Max. Qty.", MaxQty);
        BinContent.Modify(true);
    end;

    local procedure CreateAndFindBin(var Bin: Record Bin; var Bin2: Record Bin; var Bin3: Record Bin; Item: Record Item; LocationCode: Code[10])
    var
        BinContent: Record "Bin Content";
        Zone: Record Zone;
    begin
        FindZone(Zone, LocationCode);
        FindBinAndUpdateBinRanking(Bin, Zone, '', LibraryRandom.RandInt(100));
        FindBinAndUpdateBinRanking(Bin2, Zone, Bin.Code, Bin."Bin Ranking" + LibraryRandom.RandInt(10));
        CreateBinWithBinRanking(Bin3, LocationCode, Zone.Code, Zone."Bin Type Code", Bin2."Bin Ranking" + LibraryRandom.RandInt(10));
        CreateBinContent(
          BinContent, Bin3, Item, Item."Base Unit of Measure", LibraryRandom.RandInt(10), LibraryRandom.RandIntInRange(50, 100));
    end;

    local procedure CreateBinWithBinRanking(var Bin: Record Bin; LocationCode: Code[10]; ZoneCode: Code[10]; BinTypeCode: Code[10]; BinRanking: Integer)
    begin
        LibraryWarehouse.CreateBin(
          Bin, LocationCode,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), 1,
            LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))), ZoneCode, BinTypeCode);
        UpdateBinRankingOnBin(Bin, BinRanking);
    end;

    local procedure CreateBinAndRegisterWhseAdjustment(var BinContent: Record "Bin Content"; Item: Record Item; LocationCode: Code[10]; LotNo: Code[50]; QtyToRegister: Integer; BinRanking: Integer; QtyMin: Decimal; QtyMax: Decimal; ExpDate: Date)
    var
        Zone: Record Zone;
        Bin: Record Bin;
        PutPickBinType: Code[10];
    begin
        FindZone(Zone, LocationCode);
        PutPickBinType := LibraryWarehouse.SelectBinType(false, false, true, true);
        CreateBinWithBinRanking(Bin, LocationCode, Zone.Code, PutPickBinType, BinRanking);
        CreateBinContent(BinContent, Bin, Item, Item."Base Unit of Measure", QtyMin, QtyMax);
        CreateAndRegisterWhseJnlLineWithLotAndExpDate(Bin, Item."No.", LotNo, ExpDate, QtyToRegister);
    end;

    local procedure CreateFullWarehouseSetup(var Location: Record Location)
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);  // Value used for number of bin per zone.
        CreateWarehouseEmployee(Location.Code);
    end;

    local procedure CreateInitialSetupForBinReplenishment(var Bin: Record Bin; var Bin2: Record Bin; var WarehouseJournalLine: Record "Warehouse Journal Line")
    var
        Item: Record Item;
        Location: Record Location;
        Zone: Record Zone;
        BinContent: Record "Bin Content";
    begin
        LibraryInventory.CreateItem(Item);
        CreateAndUpdateFullWareHouseSetup(Location);
        FindZone(Zone, Location.Code);
        FindBinAndUpdateBinRanking(Bin, Zone, '', LibraryRandom.RandInt(10));  // Use random Bin Ranking.
        FindBinAndUpdateBinRanking(Bin2, Zone, Bin.Code, Bin."Bin Ranking" + LibraryRandom.RandInt(10));  // Use random Bin Ranking and value is required.
        CreateBinContent(BinContent, Bin2, Item, Item."Base Unit of Measure", LibraryRandom.RandDec(5, 2), LibraryRandom.RandDec(5, 2));
        CreateAndRegisterWarehouseJournalLine(
          WarehouseJournalLine, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Bin, Item."No.", BinContent."Min. Qty.");
    end;

    local procedure CreateInitialSetupForBinReplenishment(var Item: Record Item; var Bin1: Record Bin; var Bin2: Record Bin; var ItemJournalLine: Record "Item Journal Line")
    var
        Location: Record Location;
        Zone1: Record Zone;
        Zone2: Record Zone;
        BinContent: Record "Bin Content";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location."Bin Mandatory" := true;
        //Location.Validate("Directed Put-away and Pick", true);
        //Location.Validate("Use Cross-Docking", true);
        Location.Modify(true);
        CreateWarehouseEmployee(Location.Code);

        LibraryWarehouse.CreateZone(Zone1, '', Location.Code, '', '', '', 1, false);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, Zone1.Code, '', 2, false);

        LibraryWarehouse.CreateZone(Zone2, '', Location.Code, '', '', '', 2, false);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, Zone2.Code, '', 2, false);

        FindBinAndUpdateBinRanking(Bin1, Zone1, '', LibraryRandom.RandInt(10));  // Use random Bin Ranking.
        FindBinAndUpdateBinRanking(Bin2, Zone2, Bin1.Code, Bin1."Bin Ranking" + LibraryRandom.RandInt(10));  // Use random Bin Ranking and value is required.
        CreateBinContent(BinContent, Bin2, Item, Item."Base Unit of Measure", LibraryRandom.RandDec(5, 2), LibraryRandom.RandDec(5, 2));

        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, Item."No.", Location.Code, Bin1.Code, BinContent."Min. Qty.");
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateInitialSetupForMovementWorksheetWithCubage(var ItemUnitOfMeasure: Record "Item Unit of Measure"; var Bin: Record Bin)
    var
        Item: Record Item;
        Location: Record Location;
        Zone: Record Zone;
    begin
        LibraryInventory.CreateItem(Item);
        UpdateCubageOnItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.");
        CreateAndUpdateFullWareHouseSetup(Location);
        UpdateBinCapacityPolicyOnLocation(Location, Location."Bin Capacity Policy"::"Prohibit More Than Max. Cap.");
        FindZone(Zone, Location.Code);
        FindBinAndUpdateBinRanking(Bin, Zone, '', LibraryRandom.RandInt(10));  // Use random Bin Ranking.
        UpdateMaximumCubageOnBin(Bin, ItemUnitOfMeasure.Cubage);
    end;

    local procedure CreateInitialSetupForPick(var SalesLine: Record "Sales Line")
    var
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        CreateWarehouseReceiptFromPurchaseOrder(PurchaseLine);
        PostWarehouseReceipt(PurchaseLine."Document No.");
        RegisterWarehouseActivityHeader(PurchaseLine."Location Code", WarehouseActivityHeader.Type::"Put-away");
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, PurchaseLine."No.", PurchaseLine."Location Code", PurchaseLine.Quantity);
        CreateAndReleaseWarehouseShipmentFromSalesOrder(SalesHeader, SalesLine."Location Code");
    end;

    local procedure CreateInitialSetupWithTransferOrder(var TransferHeader: Record "Transfer Header"; ItemNo: Code[20])
    var
        Location: Record Location;
        Location2: Record Location;
    begin
        // Use Location as From Location and Location2 as To Location.
        CreateAndUpdateLocation(Location, true, true);
        CreateWarehouseEmployee(Location.Code);
        CreateAndUpdateLocation(Location2, true, true);
        CreateAndReleaseTransferOrder(TransferHeader, Location.Code, Location2.Code, ItemNo, LibraryRandom.RandDec(100, 2));  // Taking Random Quantity.
    end;

    local procedure CreateItemMovementSetup(var WarehouseActivityHeader: Record "Warehouse Activity Header")
    var
        Item: Record Item;
        Item2: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
    begin
        CreateItemSetup(Item, Item2, Location);
        CreateAndRefreshProductionOrder(ProductionOrder, Item."No.", Location.Code);
        LibraryWarehouse.CreateInventoryMovementHeader(WarehouseActivityHeader, Location.Code);
        LibraryVariableStorage.Enqueue(Location.Code);
        LibraryVariableStorage.Enqueue(ProductionOrder."No.");
        LibraryWarehouse.GetSourceDocInventoryMovement(WarehouseActivityHeader);
    end;

    local procedure CreateItemSetup(var Item: Record Item; var Item2: Record Item; var Location: Record Location)
    var
        ProductionBOMHeader: Record "Production BOM Header";
        Bin: Record Bin;
        WarehouseEmployee: Record "Warehouse Employee";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryWarehouse.CreateLocationWMS(Location, true, true, true, false, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 2, false);
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 1);
        Location.Validate("To-Production Bin Code", Bin.Code);
        Location.Modify(true);
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 2);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        CreateAndCertifyProductionBOM(
          ProductionBOMHeader, Item2."No.", Item."Base Unit of Measure", LibraryRandom.RandInt(10));
        Item.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item.Modify(true);
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, Item2."No.", Location.Code, Bin.Code, LibraryRandom.RandIntInRange(100, 200));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateInventoryPickFromProductionOrder(var Item: Record Item; var Item2: Record Item; var ProductionOrder: Record "Production Order")
    var
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        ProductionBOMHeader: Record "Production BOM Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        CreateAndUpdateLocation(Location, false, false);
        LibraryInventory.CreateItem(Item);  // Use Item for Parent Item.
        LibraryInventory.CreateItem(Item2);  // Use Item2 for Child Item.
        CreateAndCertifyProductionBOM(ProductionBOMHeader, Item2."No.", Item."Base Unit of Measure", LibraryRandom.RandInt(10));
        Item.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item.Modify(true);
        CreateAndPostItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Location.Code);
        CreateAndPostItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item2."No.", Location.Code);
        CreateAndRefreshProductionOrder(ProductionOrder, Item."No.", Location.Code);
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, true, false);
    end;

    local procedure CreateItemTrackingCode(var ItemTrackingCode: Record "Item Tracking Code")
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        ItemTrackingCode.Validate("Lot Specific Tracking", true);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);
    end;

    local procedure CreateItemTrackingCodeWithExpirDateSetup(var ItemTrackingCode: Record "Item Tracking Code"; Serial: Boolean; Lot: Boolean; ManExpirDateEntryReqd: Boolean; StrictExpirationPosting: Boolean)
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, Serial, Lot);
        ItemTrackingCode.Validate("SN Specific Tracking", Serial);
        ItemTrackingCode.Validate("SN Warehouse Tracking", Serial);
        ItemTrackingCode.Validate("Lot Specific Tracking", Lot);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", Lot);
        ItemTrackingCode.Validate("Use Expiration Dates", StrictExpirationPosting or ManExpirDateEntryReqd);
        ItemTrackingCode.Validate("Man. Expir. Date Entry Reqd.", ManExpirDateEntryReqd);
        ItemTrackingCode.Validate("Strict Expiration Posting", StrictExpirationPosting);
        ItemTrackingCode.Modify(true);
    end;

    local procedure CreateItemWithItemTrackingCodeWithExpirateDate(var Item: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        CreateItemTrackingCodeWithExpirDateSetup(ItemTrackingCode, false, true, true, true);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);
    end;

    local procedure CreateItemWithSNItemTrackingCodeWithExpirateDate(var Item: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        CreateItemTrackingCodeWithExpirDateSetup(ItemTrackingCode, true, false, true, true);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Validate("Serial Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);
    end;

    local procedure CreateItemUnitOfMeasure(var ItemUnitOfMeasure: Record "Item Unit of Measure"; ItemUnitOfMeasure2: Record "Item Unit of Measure")
    begin
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, ItemUnitOfMeasure2."Item No.",
          ItemUnitOfMeasure2."Qty. per Unit of Measure" + LibraryRandom.RandInt(10));  // Use random Quantity per Unit of Measure and value is required for test.
    end;

    local procedure UpdateInventoryInBinUsingWhseJournalWithLotNo(Bin: Record Bin; ItemNo: Code[20]; Quantity: Decimal; LotNo: Code[50])
    begin
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Quantity);
        LibraryWarehouse.UpdateInventoryInBinUsingWhseJournal(Bin, ItemNo, Quantity, true);
    end;

    local procedure CreateItemWithItemTrackingCodeForLot(var Item: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        CreateItemTrackingCode(ItemTrackingCode);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);
    end;

    local procedure CreateItemWithPhysicalInventoryCountingPeriod(var Item: Record Item; var PhysInvtCountingPeriod: Record "Phys. Invt. Counting Period")
    begin
        PhysInvtCountingPeriod.FindFirst();
        LibraryInventory.CreateItem(Item);
        Item.Validate("Phys Invt Counting Period Code", PhysInvtCountingPeriod.Code);
        Item.Modify(true);
    end;

    local procedure CreateItemTrackingCodeForSerialNo(var ItemTrackingCode: Record "Item Tracking Code")
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false);
        ItemTrackingCode.Validate(Description, ItemTrackingCode.Code);
        ItemTrackingCode.Validate("SN Specific Tracking", true);
        ItemTrackingCode.Validate("SN Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);
    end;

    local procedure CreateItemWithItemTrackingCodeForSerialNo(var Item: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        CreateItemTrackingCodeForSerialNo(ItemTrackingCode);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Validate("Serial Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);
    end;

    local procedure CreateItemWithVendorNo(VendorNo: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", VendorNo);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateLotTrackedItemPartSerialTracked(var Item: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        CreateItemTrackingCode(ItemTrackingCode);
        ItemTrackingCode.Validate("SN Transfer Tracking", true);
        ItemTrackingCode.Validate("SN Purchase Inbound Tracking", true);
        ItemTrackingCode.Modify(true);

        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Validate("Serial Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);
    end;

    local procedure CreateLocationInTransit(var Location: Record Location)
    begin
        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("Use As In-Transit", true);
        Location.Modify(true);
    end;

    local procedure CreateMovement(ItemNo: Code[20])
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        FindWarehouseWorksheetLine(WhseWorksheetLine, ItemNo);
        Commit();  // Commit is required.
        WhseWorksheetLine.MovementCreate(WhseWorksheetLine);
    end;

    local procedure CreateMovementWorksheet(ItemUnitOfMeasure: Record "Item Unit of Measure"; Bin: Record Bin)
    var
        MovementWorksheet: TestPage "Movement Worksheet";
    begin
        MovementWorksheet.OpenEdit();
        MovementWorksheet."Item No.".SetValue(ItemUnitOfMeasure."Item No.");
        MovementWorksheet."To Zone Code".SetValue(Bin."Zone Code");
        MovementWorksheet."To Bin Code".SetValue(Bin.Code);
        MovementWorksheet.Quantity.SetValue(ItemUnitOfMeasure.Cubage);
    end;

    local procedure CreateMovementWorksheetLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; LocationCode: Code[10]; ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; ToBinCode: Code[20]; Qty: Decimal)
    var
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        MovementWorksheetPage: TestPage "Movement Worksheet";
    begin
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Movement);
        LibraryWarehouse.SelectWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, LocationCode);
        LibraryWarehouse.CreateWhseWorksheetLine(
          WhseWorksheetLine, WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, LocationCode,
          "Warehouse Worksheet Template Type"::"Put-away");
        // Validation of Qty. to Handle depends on CurrFieldNo so we have to do this via UI
        MovementWorksheetPage.OpenEdit();
        MovementWorksheetPage.GotoRecord(WhseWorksheetLine);
        MovementWorksheetPage."Item No.".SetValue(ItemNo);
        MovementWorksheetPage."Unit of Measure Code".SetValue(UnitOfMeasureCode);
        MovementWorksheetPage."To Bin Code".SetValue(ToBinCode);
        MovementWorksheetPage.Quantity.SetValue(Qty);
        MovementWorksheetPage."Qty. to Handle".SetValue(Qty);
        MovementWorksheetPage.Close();
    end;

    local procedure CreateMovementAndVerifyMovementLinesForLot(LocationCode: Code[10]; ItemNo: Code[20]; BinCode: Code[20]; LotNo: Code[50]; Quantity: Integer)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Exercise: Calculate Bin Replenishment and create Movement.
        CalculateBinReplenishment(LocationCode);
        CreateMovement(ItemNo);

        // Verify: Verify the Bin Code and Item Tracking No. is correct of Movement lines.
        FindWarehouseActivityLine2(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Movement, WarehouseActivityLine."Action Type"::Take, ItemNo);
        VerifyWarehouseActivityLines(WarehouseActivityLine, BinCode, LotNo, '', Quantity);
    end;

    local procedure CreatePickFromSalesHeader(var SalesHeader: Record "Sales Header")
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SalesHeader."No.", WarehouseShipmentLine."Source Document"::"Sales Order");
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
    end;

    local procedure CreatePickFromTransferHeader(var TransferHeader: Record "Transfer Header")
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);
        FindWarehouseShipmentHeader(
          WarehouseShipmentHeader, TransferHeader."No.", WarehouseShipmentLine."Source Document"::"Outbound Transfer");
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);  // Taking Random Quantity.
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesOrderWithLocation(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateStockKeepingUnit(var StockkeepingUnit: Record "Stockkeeping Unit")
    var
        Item: Record Item;
        Location: Record Location;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Item.SetRange("No.", Item."No.");
        Item.SetRange("Location Filter", Location.Code);
        LibraryInventory.CreateStockKeepingUnit(Item, "SKU Creation Method"::Location, false, false);
        FindStockkeepingUnit(StockkeepingUnit, Item."No.", Location.Code);
    end;

    local procedure CreateSKUWithPhysInvtCntPeriod(var StockkeepingUnit: Record "Stockkeeping Unit")
    var
        PhysInvtCountingPeriod: Record "Phys. Invt. Counting Period";
    begin
        CreateStockKeepingUnit(StockkeepingUnit);
        StockkeepingUnit.SetRange("Location Code");
        StockkeepingUnit.SetRange("Item No.");
        PhysInvtCountingPeriod.FindFirst();
        StockkeepingUnit.Validate("Phys Invt Counting Period Code", PhysInvtCountingPeriod.Code);
        StockkeepingUnit.Modify(true);
    end;

    local procedure CreateWarehouseEmployee(LocationCode: Code[10])
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.SetRange("User ID", UserId);
        WarehouseEmployee.DeleteAll(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationCode, true);
    end;

    local procedure CreateWarehouseReceiptFromPurchaseOrder(var PurchaseLine: Record "Purchase Line")
    var
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
    begin
        CreateFullWarehouseSetup(Location);
        CreateAndReleasePurchaseOrder(PurchaseLine, LibraryInventory.CreateItem(Item), Location.Code);
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseLine."Document No.");
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
    end;

    local procedure PrepareReceiveShipPickLocation(var Location: Record Location)
    begin
        CreateAndUpdateLocationForBinContent(Location);
        // From Location
        Location.Validate("Require Receive", true);
        Location.Validate("Require Shipment", true);
        Location.Validate("Require Pick", true);
        Location.Validate("Receipt Bin Code", AddBin(Location.Code));
        Location.Validate("Shipment Bin Code", AddBin(Location.Code));
        Location.Modify(true);
        CreateWarehouseEmployee(Location.Code);
    end;

    local procedure CreateSalesOrderWithPick(ItemNo: Code[20]; LocationCode: Code[10]; ZoneCode: Code[10]; BinCode: Code[20]; Quantity: Decimal; LotNo: Code[50])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', ItemNo, Quantity, LocationCode, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        if LotNo <> '' then begin
            LibraryVariableStorage.Enqueue(TrackingActionStr::AssignGivenLotNo);
            LibraryVariableStorage.Enqueue(LotNo);
            LibraryVariableStorage.Enqueue(Quantity);
            SalesLine.OpenItemTrackingLines();
        end;

        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SalesHeader."No.", WarehouseShipmentLine."Source Document"::"Sales Order");

        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        FindWarehouseActivityHeaderBySourceNo(WarehouseActivityHeader, LocationCode, SalesHeader."No.");
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.ModifyAll("Bin Code", '', true);
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.FindFirst();

        WarehouseActivityLine.Validate(Quantity, Quantity);
        WarehouseActivityLine.Validate("Zone Code", ZoneCode);
        WarehouseActivityLine.Validate("Bin Code", BinCode);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure CreateMovementWarehouseJournalLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; FromBin: Record Bin; ToBin: Record Bin; ItemNo: Code[20]; Quantity: Decimal; LotNo: Code[50])
    begin
        CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalLine."Entry Type"::Movement,
          ItemNo, Quantity, FromBin."Location Code", FromBin."Zone Code", FromBin.Code);

        WarehouseJournalLine.Validate("From Zone Code", FromBin."Zone Code");
        WarehouseJournalLine.Validate("From Bin Code", FromBin.Code);

        WarehouseJournalLine.Validate("To Zone Code", ToBin."Zone Code");
        WarehouseJournalLine.Validate("To Bin Code", ToBin.Code);
        WarehouseJournalLine.Modify(true);

        if LotNo <> '' then begin
            LibraryVariableStorage.Enqueue(LotNo);
            LibraryVariableStorage.Enqueue(Quantity);
            WarehouseJournalLine.OpenItemTrackingLines();
        end;
    end;

    local procedure CreateRegisteredDocument(var RegisteredWhseActivityHdr: Record "Registered Whse. Activity Hdr."; ActivityType: Enum "Warehouse Activity Type")
    var
        Location: Record Location;
    begin
        RegisteredWhseActivityHdr.Init();
        RegisteredWhseActivityHdr.Type := ActivityType;
        RegisteredWhseActivityHdr."No." := LibraryUtility.GenerateGUID();
        RegisteredWhseActivityHdr."Location Code" := LibraryWarehouse.CreateLocation(Location);
        RegisteredWhseActivityHdr.Insert();
    end;

    local procedure AddBin(LocationCode: Code[10]): Code[20]
    var
        Bin: Record Bin;
    begin
        LibraryWarehouse.CreateBin(
          Bin, LocationCode,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), 1,
            LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))), '', '');
        exit(Bin.Code);
    end;

    local procedure SetWhseActivityLinesLotNo(LocationCode: Code[10]; ActivityType: Enum "Warehouse Activity Type"; ItemNo: Code[20]; LotNo: Code[50])
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityHeader(WarehouseActivityHeader, LocationCode, ActivityType);
        SetWarehouseActivityLineLotNo(
          WarehouseActivityHeader, WarehouseActivityLine."Action Type"::Take, ItemNo, LotNo);
        SetWarehouseActivityLineLotNo(
          WarehouseActivityHeader, WarehouseActivityLine."Action Type"::Place, ItemNo, LotNo);
    end;

    local procedure SetIncrementBatchName(WarehouseJournalBatch: Record "Warehouse Journal Batch"; Increment: Boolean)
    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
    begin
        WarehouseJournalTemplate.Get(WarehouseJournalBatch."Journal Template Name");
        if WarehouseJournalTemplate."Increment Batch Name" <> Increment then begin
            WarehouseJournalTemplate."Increment Batch Name" := Increment;
            WarehouseJournalTemplate.Modify();
        end;
    end;

    local procedure SetWhseActivityLinesSerialNo(LocationCode: Code[10]; ActivityType: Enum "Warehouse Activity Type"; ItemNo: Code[20]; SerialNo: Code[50])
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityHeader(WarehouseActivityHeader, LocationCode, ActivityType);
        SetWarehouseActivityLineSerialNo(
          WarehouseActivityHeader, WarehouseActivityLine."Action Type"::Take, ItemNo, SerialNo);
        SetWarehouseActivityLineSerialNo(
          WarehouseActivityHeader, WarehouseActivityLine."Action Type"::Place, ItemNo, SerialNo);
    end;

    local procedure FindBin(var Bin: Record Bin; LocationCode: Code[10])
    var
        Zone: Record Zone;
    begin
        FindZone(Zone, LocationCode);
        Bin.SetRange("Location Code", LocationCode);
        Bin.SetRange("Zone Code", Zone.Code);
        Bin.SetRange("Adjustment Bin", false);
        Bin.FindFirst();
    end;

    local procedure FindBinAndUpdateBinRanking(var Bin: Record Bin; Zone: Record Zone; BinCode: Code[20]; BinRanking: Integer)
    begin
        Bin.SetRange("Location Code", Zone."Location Code");
        Bin.SetRange("Zone Code", Zone.Code);
        Bin.SetFilter(Code, '<>%1', BinCode);
        Bin.FindFirst();
        Bin.Validate("Bin Ranking", BinRanking);
        Bin.Modify(true);
    end;

    local procedure FindHighestRankingBin(var Bin: Record Bin; LocationCode: Code[10])
    begin
        Bin.SetCurrentKey("Location Code", "Bin Ranking");
        Bin.SetAscending("Bin Ranking", false);
        Bin.SetRange("Location Code", LocationCode);
        Bin.FindFirst();
    end;

    local procedure FindBinContent(var BinContent: Record "Bin Content"; ItemNo: Code[20])
    begin
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.FindFirst();
    end;

    local procedure FindBinContentWithBinCode(var BinContent: Record "Bin Content"; Bin: Record Bin; ItemNo: Code[20])
    begin
        BinContent.SetRange("Location Code", Bin."Location Code");
        BinContent.SetRange("Zone Code", Bin."Zone Code");
        BinContent.SetRange("Bin Code", Bin.Code);
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.FindFirst();
    end;

    local procedure FindBinType(): Code[10]
    var
        BinType: Record "Bin Type";
    begin
        BinType.SetRange("Put Away", true);
        BinType.SetRange(Pick, true);
        BinType.FindFirst();
        exit(BinType.Code);
    end;

    local procedure FindEmptyBin(LocationCode: Code[10]; ZoneCode: Code[10]): Code[20]
    var
        Bin: Record Bin;
    begin
        Bin.SetRange("Location Code", LocationCode);
        Bin.SetRange("Zone Code", ZoneCode);
        Bin.SetRange(Empty, true);
        Bin.FindFirst();
        exit(Bin.Code);
    end;

    local procedure FindItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemJournalBatch: Record "Item Journal Batch"; ItemNo: Code[20])
    begin
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.FindFirst();
    end;

    local procedure FindProductionOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; ProductionOrderNo: Code[20])
    begin
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderComponent.FindFirst();
    end;

    local procedure FindProductionOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProductionOrderNo: Code[20])
    begin
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderLine.FindFirst();
    end;

    local procedure FindRegisteredWarehouseActivityHeader(var RegisteredWhseActivityHdr: Record "Registered Whse. Activity Hdr."; LocationCode: Code[10]; Type: Enum "Warehouse Activity Type")
    begin
        RegisteredWhseActivityHdr.SetRange("Location Code", LocationCode);
        RegisteredWhseActivityHdr.SetRange(Type, Type);
        RegisteredWhseActivityHdr.FindFirst();
    end;

    local procedure FindSerialNosInWarehouseEntry(BinCode: Code[20]; ItemNo: Code[20]; var SerialNo: array[20] of Code[50])
    var
        WarehouseEntry: Record "Warehouse Entry";
        i: Integer;
    begin
        FindWarehouseEntry(WarehouseEntry, WarehouseEntry."Entry Type"::"Positive Adjmt.", BinCode, ItemNo);
        for i := 1 to WarehouseEntry.Count do begin
            SerialNo[i] := WarehouseEntry."Serial No.";
            WarehouseEntry.Next();
        end;
    end;

    local procedure FindStockkeepingUnit(var StockkeepingUnit: Record "Stockkeeping Unit"; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        StockkeepingUnit.SetRange("Item No.", ItemNo);
        StockkeepingUnit.SetRange("Location Code", LocationCode);
        StockkeepingUnit.FindFirst();
    end;

    local procedure FindWarehouseActivityHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; LocationCode: Code[10]; ActivityType: Enum "Warehouse Activity Type")
    begin
        WarehouseActivityHeader.SetRange("Location Code", LocationCode);
        WarehouseActivityHeader.SetRange(Type, ActivityType);
        WarehouseActivityHeader.FindFirst();
    end;

    local procedure FindWarehouseActivityHeaderBySourceNo(var WarehouseActivityHeader: Record "Warehouse Activity Header"; LocationCode: Code[10]; SourceNo: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityHeader.SetRange("No.", WarehouseActivityLine."No.");
        WarehouseActivityHeader.FindFirst();
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure FindWarehouseActivityLine2(var WarehouseActivityLine: Record "Warehouse Activity Line"; ActivityType: Enum "Warehouse Activity Type"; ActionType: Enum "Warehouse Action Type"; ItemNo: Code[20])
    begin
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure FindWarehouseEntry(var WarehouseEntry: Record "Warehouse Entry"; EntryType: Option; BinCode: Code[20]; ItemNo: Code[20]): Code[50]
    begin
        WarehouseEntry.SetRange("Entry Type", EntryType);
        WarehouseEntry.SetRange("Bin Code", BinCode);
        WarehouseEntry.SetRange("Item No.", ItemNo);
        WarehouseEntry.FindFirst();
        exit(WarehouseEntry."Lot No.");
    end;

    local procedure FindWarehouseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceNo: Code[20])
    begin
        WarehouseReceiptLine.SetRange("Source Document", WarehouseReceiptLine."Source Document"::"Purchase Order");
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.FindFirst();
    end;

    local procedure FindWarehouseReceiptHeader(SourceNo: Code[20]): Code[20]
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        FindWarehouseReceiptLine(WarehouseReceiptLine, SourceNo);
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        exit(WarehouseReceiptHeader."No.");
    end;

    local procedure FindWarehouseShipmentHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document")
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("Source Document", SourceDocument);
        WarehouseShipmentLine.SetRange("Source No.", SourceNo);
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
    end;

    local procedure FindWarehouseWorksheetLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; ItemNo: Code[20])
    begin
        WhseWorksheetLine.SetRange("Item No.", ItemNo);
        WhseWorksheetLine.FindFirst();
    end;

    local procedure FindZone(var Zone: Record Zone; LocationCode: Code[10])
    begin
        Zone.SetRange("Location Code", LocationCode);
        Zone.SetRange("Bin Type Code", FindBinType());
        Zone.SetRange("Cross-Dock Bin Zone", false);
        Zone.FindFirst();
    end;

    local procedure FindPutawayPickBin(var Bin: Record Bin; LocationCode: Code[10])
    var
        Zone: Record Zone;
        BinTypeCode: Code[10];
    begin
        BinTypeCode := LibraryWarehouse.SelectBinType(false, false, true, true);
        LibraryWarehouse.FindZone(Zone, LocationCode, BinTypeCode, false);
        LibraryWarehouse.FindBin(Bin, LocationCode, Zone.Code, 0);
    end;

    local procedure FindAnotherBinInZone(var OtherBin: Record Bin; Bin: Record Bin)
    begin
        OtherBin.SetRange("Location Code", Bin."Location Code");
        OtherBin.SetFilter(Code, '<>%1', Bin.Code);
        OtherBin.SetRange("Zone Code", Bin."Zone Code");
        OtherBin.FindFirst();
    end;

    local procedure GetBinContentFromItemJournalLine(ItemJournalBatch: Record "Item Journal Batch"; LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20])
    var
        BinContent: Record "Bin Content";
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.Init();
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.Validate("Posting Date", WorkDate());
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Bin Code", BinCode);
        BinContent.SetRange("Item No.", ItemNo);
        LibraryWarehouse.WhseGetBinContentFromItemJournalLine(BinContent, ItemJournalLine);
    end;

    local procedure GetWarehouseDocumentsAndCreatePick()
    var
        PickWorksheet: TestPage "Pick Worksheet";
    begin
        PickWorksheet.OpenEdit();
        PickWorksheet."Get Warehouse Documents".Invoke();
        Commit();  // Commit required.
        PickWorksheet.CreatePick.Invoke();
    end;

    local procedure InvokeAutofillQuantityToHandleOnPick(LocationCode: Code[10])
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        WarehouseActivityHeader.SetRange("Location Code", LocationCode);
        WarehouseActivityHeader.FindFirst();
        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);
    end;

    local procedure InitialSetupForMakeOrders(var SalesHeader: Record "Sales Header"; var ItemNo: Code[20]; var LocationCode: Code[10]; var Quantity: Decimal)
    var
        Location: Record Location;
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
    begin
        CreateFullWarehouseSetup(Location);
        LocationCode := Location.Code;
        ItemNo := CreateItemWithVendorNo(LibraryPurchase.CreateVendorNo());
        Quantity := CreateAndRegisterPutAwayFromPurchaseOrder(LocationCode, ItemNo, false);
        CreateAndReleaseSalesOrder(
          SalesHeader, SalesLine, ItemNo, LocationCode, Quantity + LibraryRandom.RandDec(10, 2)); // To make sure Item is not enough on Inventory.
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);
        SetupReserveOnRequisitionLine(ItemNo, RequisitionLine.Type::Item);
        MakeSupplyOrdersActiveOrder(SalesHeader."No.");
    end;

    local procedure GetManufacturingUserTemplate(var ManufacturingUserTemplate: Record "Manufacturing User Template"; MakeOrder: Option; CreateProductionOrder: Enum "Planning Create Prod. Order")
    begin
        if not ManufacturingUserTemplate.Get(UserId) then
            LibraryPlanning.CreateManufUserTemplate(
              ManufacturingUserTemplate, UserId, MakeOrder, ManufacturingUserTemplate."Create Purchase Order"::"Make Purch. Orders",
              CreateProductionOrder, ManufacturingUserTemplate."Create Transfer Order"::"Make Trans. Orders");
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
          ManufacturingUserTemplate."Create Purchase Order"::"Make Purch. Orders");
    end;

    local procedure MakeSupplyOrders(var RequisitionLine: Record "Requisition Line"; MakeOrders: Option; CreateProductionOrder: Enum "Planning Create Purchase Order")
    var
        ManufacturingUserTemplate: Record "Manufacturing User Template";
    begin
        GetManufacturingUserTemplate(ManufacturingUserTemplate, MakeOrders, CreateProductionOrder);
        LibraryPlanning.MakeSupplyOrders(ManufacturingUserTemplate, RequisitionLine);
    end;

    local procedure MockBinContent(var BinContent: Record "Bin Content")
    begin
        BinContent.Init();
        BinContent."Location Code" := LibraryUtility.GenerateGUID();
        BinContent."Bin Code" := LibraryUtility.GenerateGUID();
        BinContent."Item No." := LibraryUtility.GenerateGUID();
        BinContent."Variant Code" := LibraryUtility.GenerateGUID();
        BinContent."Unit of Measure Code" := LibraryUtility.GenerateGUID();
        BinContent.Insert();
    end;

    local procedure CopyBinContent(var BinContentTo: Record "Bin Content"; BinContentFrom: Record "Bin Content")
    begin
        BinContentTo := BinContentFrom;
        BinContentTo."Bin Code" := LibraryUtility.GenerateGUID();
        BinContentTo.Insert();
    end;

    local procedure MockWarehouseJournalLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; BinContentFrom: Record "Bin Content"; BinContentTo: Record "Bin Content"; EntryType: Option)
    begin
        WarehouseJournalLine.Init();
        WarehouseJournalLine."Line No." := LibraryUtility.GetNewRecNo(WarehouseJournalLine, WarehouseJournalLine.FieldNo("Line No."));
        WarehouseJournalLine."Entry Type" := EntryType;
        WarehouseJournalLine."Location Code" := BinContentFrom."Location Code";
        WarehouseJournalLine."From Bin Code" := BinContentFrom."Bin Code";
        WarehouseJournalLine."To Bin Code" := BinContentTo."Bin Code";
        WarehouseJournalLine."Item No." := BinContentFrom."Item No.";
        WarehouseJournalLine."Variant Code" := BinContentFrom."Variant Code";
        WarehouseJournalLine."Unit of Measure Code" := BinContentFrom."Unit of Measure Code";
        WarehouseJournalLine."Qty. (Absolute)" := LibraryRandom.RandDec(10, 2);
        WarehouseJournalLine."Qty. (Absolute, Base)" := WarehouseJournalLine."Qty. (Absolute)" * LibraryRandom.RandInt(10);
        WarehouseJournalLine.Insert();
    end;

    local procedure PostWarehouseReceipt(SourceNo: Code[20])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptLine(WarehouseReceiptLine, SourceNo);
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure PostWarehouseShipment(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SourceNo, SourceDocument);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
    end;

    local procedure PostWhseJournalPositiveAdjmtWithItemTracking(Bin: Record Bin; Item: Record Item; Quantity: Decimal)
    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Type::Item, Bin."Location Code");
        CreateAndRegisterWarehouseItemJournalWithItemTracking(
          WarehouseJournalBatch, WarehouseJournalLine, Bin.Code, Bin."Location Code", Bin."Zone Code",
          WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity, 0D,
          TrackingActionStr::AssignLotNo);
        CalculateAndPostWarehouseAdjustment(Item);
    end;

    [HandlerFunctions('WhseItemTrackingPageHandler,WhseSourceCreateDocumentHandler,MessageHandler')]
    local procedure PutItemInDifferentBinsWithItemTracking(var LocationCode: Code[10]; var ItemNo: Code[20]; var Bin: Record Bin; var Bin2: Record Bin; var Bin3: Record Bin; var TrackingNo: array[20] of Code[50]; var TrackingNo2: array[20] of Code[50]; var Quantity: Integer; TrackingAction: Option)
    var
        Item: Record Item;
        Location: Record Location;
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseEntry: Record "Warehouse Entry";
        ExpirationDate: Date;
    begin
        // Create Location with Zones and Bins.
        CreateFullWarehouseSetup(Location);
        UpdateParametersOnLocation(Location, true, true); // NewPickAccordingToFEFO=True, NewAlwaysCreatePutAwayLine=True

        // Create Item with Item Tracking Code.
        case TrackingAction of
            TrackingActionStr::AssignLotNo:
                CreateItemWithItemTrackingCodeWithExpirateDate(Item);
            TrackingActionStr::AssignSerialNo:
                CreateItemWithSNItemTrackingCodeWithExpirateDate(Item);
        end;

        // Find two Bins and create a fixed Bin with Bin Content.
        CreateAndFindBin(Bin, Bin2, Bin3, Item, Location.Code);

        // Create and register two Warehouse Item Journal Lines with Item Tracking and Expiration Date.
        ExpirationDate := CalcDate('<+' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        Quantity := LibraryRandom.RandInt(10);
        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Type::Item, Location.Code);
        SetIncrementBatchName(WarehouseJournalBatch, true);

        CreateAndRegisterWarehouseItemJournalWithItemTracking(
          WarehouseJournalBatch, WarehouseJournalLine, Bin.Code, Location.Code, Bin."Zone Code",
          WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity, ExpirationDate, TrackingAction);
        CreateAndRegisterWarehouseItemJournalWithItemTracking(
          WarehouseJournalBatch, WarehouseJournalLine, Bin2.Code, Location.Code, Bin2."Zone Code",
          WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity, ExpirationDate, TrackingAction);

        // Return the Item No, Location Code and Lot No. / Serial No.
        ItemNo := Item."No.";
        LocationCode := Location.Code;

        case TrackingAction of
            TrackingActionStr::AssignLotNo:
                begin
                    TrackingNo[1] := FindWarehouseEntry(WarehouseEntry, WarehouseEntry."Entry Type"::"Positive Adjmt.", Bin.Code, Item."No.");
                    TrackingNo2[1] := FindWarehouseEntry(WarehouseEntry, WarehouseEntry."Entry Type"::"Positive Adjmt.", Bin2.Code, Item."No.");
                end;
            TrackingActionStr::AssignSerialNo:
                begin
                    FindSerialNosInWarehouseEntry(Bin.Code, Item."No.", TrackingNo);
                    FindSerialNosInWarehouseEntry(Bin2.Code, Item."No.", TrackingNo2);
                end;
        end;
    end;

    local procedure RegisterWarehouseActivityHeader(LocationCode: Code[10]; ActivityType: Enum "Warehouse Activity Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        WarehouseActivityHeader.SetRange("Location Code", LocationCode);
        WarehouseActivityHeader.SetRange(Type, ActivityType);
        WarehouseActivityHeader.FindFirst();
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure RunCalculateCountingPeriodFromPhysicalInventoryJournal(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        SelectItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::"Phys. Inventory");
        RunCalculateCountingPeriodFromPhysicalInventoryJournalBatch(ItemJournalBatch);
    end;

    local procedure RunCalculateCountingPeriodFromPhysicalInventoryJournalBatch(ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalLine: Record "Item Journal Line";
        PhysInvtCountManagement: Codeunit "Phys. Invt. Count.-Management";
    begin
        ItemJournalLine.Init();
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        PhysInvtCountManagement.InitFromItemJnl(ItemJournalLine);
        Commit();  // Commit is required.
        PhysInvtCountManagement.Run();
    end;

    local procedure RunCalculateCountingPeriodFromWarehousePhysicalInventoryJournal(var WarehouseJournalBatch: Record "Warehouse Journal Batch"; LocationCode: Code[10])
    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        PhysInvtCountManagement: Codeunit "Phys. Invt. Count.-Management";
    begin
        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Type::"Physical Inventory", LocationCode);
        WarehouseJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        WarehouseJournalBatch.Modify(true);
        WarehouseJournalLine.Init();
        WarehouseJournalLine.Validate("Journal Template Name", WarehouseJournalBatch."Journal Template Name");
        WarehouseJournalLine.Validate("Journal Batch Name", WarehouseJournalBatch.Name);
        WarehouseJournalLine.Validate("Location Code", LocationCode);
        PhysInvtCountManagement.InitFromWhseJnl(WarehouseJournalLine);
        Commit();  // Commit is required.
        PhysInvtCountManagement.Run();
    end;

    local procedure CalcPhysInvtDatesAndRunCalculateCountingPeriodInPhysInvtJournal(var ItemJournalBatch: Record "Item Journal Batch"; ItemFilter: Text; LastCountingDate: Date; CountFrequency: Integer)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        Item: Record Item;
        PhysInvtCountManagement: Codeunit "Phys. Invt. Count.-Management";
        NextCountingStartDate: Date;
        NextCountingEndDate: Date;
    begin
        PhysInvtCountManagement.CalcPeriod(LastCountingDate, NextCountingStartDate, NextCountingEndDate, CountFrequency);

        SelectItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::"Phys. Inventory");
        Item.SetFilter("No.", ItemFilter);
        Item.FindSet();
        repeat
            LibraryVariableStorage.Enqueue(Item."No.");
            LibraryVariableStorage.Enqueue(NextCountingStartDate);
            LibraryVariableStorage.Enqueue(NextCountingEndDate);
            RunCalculateCountingPeriodFromPhysicalInventoryJournalBatch(ItemJournalBatch);
        until Item.Next() = 0;
    end;

    local procedure CalcPhysInvtDatesAndRunCalculateCountingPeriodInWhseInvtJournal(var WarehouseJournalBatch: Record "Warehouse Journal Batch"; ItemNo: Code[20]; LocationCode: Code[10]; LastCountingDate: Date; CountFrequency: Integer)
    var
        PhysInvtCountManagement: Codeunit "Phys. Invt. Count.-Management";
        NextCountingStartDate: Date;
        NextCountingEndDate: Date;
    begin
        PhysInvtCountManagement.CalcPeriod(LastCountingDate, NextCountingStartDate, NextCountingEndDate, CountFrequency);

        LibraryVariableStorage.Enqueue(ItemNo);
        LibraryVariableStorage.Enqueue(NextCountingStartDate);
        LibraryVariableStorage.Enqueue(NextCountingEndDate);
        RunCalculateCountingPeriodFromWarehousePhysicalInventoryJournal(WarehouseJournalBatch, LocationCode);
    end;

    local procedure RunCalculateInventory(WarehouseJournalTemplateName: Code[10]; WarehouseJournalBatchName: Code[10]; LocationCode: Code[10]; ItemNo: Code[20])
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        BinContent: Record "Bin Content";
        WhseCalculateInventory: Report "Whse. Calculate Inventory";
    begin
        WarehouseJournalLine.Init();
        WarehouseJournalLine.Validate("Journal Template Name", WarehouseJournalTemplateName);
        WarehouseJournalLine.Validate("Journal Batch Name", WarehouseJournalBatchName);
        WarehouseJournalLine.Validate("Location Code", LocationCode);
        Commit();  // Commit is required to run the report.
        Clear(WhseCalculateInventory);
        BinContent.SetRange("Item No.", ItemNo);
        WhseCalculateInventory.SetTableView(BinContent);
        WhseCalculateInventory.SetWhseJnlLine(WarehouseJournalLine);
        WhseCalculateInventory.Run();
    end;

    local procedure RunWarehouseGetBinContentReport(LocationCode: Code[10]; ItemNo: Code[20]; BinCode: Code[20])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        SelectItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Transfer);
        GetBinContentFromItemJournalLine(ItemJournalBatch, LocationCode, BinCode, ItemNo);
    end;

    local procedure UpdateBinCapacityPolicyOnLocation(var Location: Record Location; BinCapacityPolicy: Option)
    begin
        Location.Validate("Bin Capacity Policy", BinCapacityPolicy);
        Location.Modify(true);
    end;

    local procedure UpdateCubageOnItemUnitOfMeasure(var ItemUnitOfMeasure: Record "Item Unit of Measure"; ItemNo: Code[20])
    begin
        ItemUnitOfMeasure.SetRange("Item No.", ItemNo);
        ItemUnitOfMeasure.FindFirst();

        // Use random values for Length, Width and Height.
        ItemUnitOfMeasure.Validate(Length, LibraryRandom.RandInt(5));
        ItemUnitOfMeasure.Validate(Width, LibraryRandom.RandInt(5));
        ItemUnitOfMeasure.Validate(Height, LibraryRandom.RandInt(5));
        ItemUnitOfMeasure.Modify(true);
    end;

    local procedure UpdateInventoryViaWarehouseJournal(Item: array[2] of Record Item; LocationCode: Code[10])
    var
        Bin: Record Bin;
        ItemToAdjust: Record Item;
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        ItemJournalLine: Record "Item Journal Line";
        ItemNoFilter: Text;
        i: Integer;
    begin
        FindBin(Bin, LocationCode);
        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Type::Item, LocationCode);
        for i := 1 to ArrayLen(Item) do begin
            ItemNoFilter += Item[i]."No." + '|';
            LibraryWarehouse.CreateWhseJournalLine(
              WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name,
              Bin."Location Code", Bin."Zone Code", Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.",
              Item[i]."No.", LibraryRandom.RandIntInRange(50, 100));
        end;
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationCode, true);

        ItemToAdjust.SetFilter("No.", CopyStr(ItemNoFilter, 1, StrLen(ItemNoFilter) - 1));
        LibraryWarehouse.CalculateWhseAdjustmentItemJournal(ItemToAdjust, WorkDate(), '');
        ItemJournalLine.SetRange("Location Code", LocationCode);
        ItemJournalLine.FindFirst();
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure UpdateInventoryViaWhseJournalWithAlternateUoM(Item: Record Item; UnitOfMeasureCode: Code[10]; LocationCode: Code[10])
    var
        Bin: Record Bin;
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        FindBin(Bin, LocationCode);
        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Type::Item, Bin."Location Code");
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name,
          Bin."Location Code", Bin."Zone Code", Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.",
          Item."No.", LibraryRandom.RandIntInRange(10, 20));
        WarehouseJournalLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        WarehouseJournalLine.Modify();
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Bin."Location Code", true);
        LibraryWarehouse.PostWhseAdjustment(Item);
    end;

    local procedure UpdateMaximumCubageOnBin(var Bin: Record Bin; MaximumCubage: Decimal)
    begin
        Bin.Validate("Maximum Cubage", MaximumCubage);
        Bin.Modify(true);
    end;

    local procedure UpdatePhysicalInventoryCountingPeriodOnStockKeepingUnit(var StockkeepingUnit: Record "Stockkeeping Unit"; var PhysInvtCountingPeriod: Record "Phys. Invt. Counting Period")
    begin
        PhysInvtCountingPeriod.FindFirst();
        StockkeepingUnit.Validate("Phys Invt Counting Period Code", PhysInvtCountingPeriod.Code);
        StockkeepingUnit.Modify(true);
    end;

    local procedure UpdateQuantityToHandleInWarehouseActivityLine(SourceNo: Code[20]; QuantityToHandle: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.Validate("Qty. to Handle", QuantityToHandle);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure UpdateQuantityToHandleInWarehouseActivityLineWithLot(SourceNo: Code[20]; SourceType: Integer; QuantityToHandle: Decimal; LotNo: Code[50])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Source Type", SourceType);
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.Validate("Qty. to Handle", QuantityToHandle);
            WarehouseActivityLine.Validate("Lot No.", LotNo);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure UpdateShippingAdviceOnTransferOrder(TransferHeader: Record "Transfer Header"; ShippingAdvice: Enum "Sales Header Shipping Advice")
    var
        ReleaseTransferDocument: Codeunit "Release Transfer Document";
    begin
        ReleaseTransferDocument.Reopen(TransferHeader);
        TransferHeader.Validate("Shipping Advice", ShippingAdvice);
        TransferHeader.Modify(true);
    end;

    local procedure UpdateUnitOfMeasureOnSalesLine(var SalesLine: Record "Sales Line"; ItemUnitOfMeasure: Code[10])
    begin
        SalesLine.Validate("Unit of Measure Code", ItemUnitOfMeasure);
        SalesLine.Modify(true);
    end;

    local procedure UpdateBinRankingOnBin(var Bin: Record Bin; BinRanking: Integer)
    begin
        Bin.Validate("Bin Ranking", BinRanking);
        Bin.Modify(true);
    end;

    local procedure UpdateBinRankingOnBins(LocationCode: Code[10]; var Bin: Record Bin; var Bin2: Record Bin; var Bin3: Record Bin)
    begin
        Bin.Get(LocationCode, Bin.Code);
        UpdateBinRankingOnBin(Bin, LibraryRandom.RandInt(100));
        UpdateBinRankingOnBin(Bin2, Bin."Bin Ranking" - LibraryRandom.RandInt(10));
        UpdateBinRankingOnBin(Bin3, Bin."Bin Ranking");
    end;

    local procedure UpdateBlockMovementOnBinContent(var BinContent: Record "Bin Content"; Bin: Record Bin; ItemNo: Code[20]; BlockMovement: Option)
    begin
        FindBinContentWithBinCode(BinContent, Bin, ItemNo);
        BinContent.Validate("Block Movement", BlockMovement);
        BinContent.Modify(true);
    end;

    local procedure UpdateItemManufacturing(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure UpdateParametersOnLocation(var Location: Record Location; NewPickAccordingToFEFO: Boolean; NewAlwaysCreatePutAwayLine: Boolean)
    begin
        Location.Validate("Pick According to FEFO", NewPickAccordingToFEFO);
        Location.Validate("Always Create Put-away Line", NewAlwaysCreatePutAwayLine);
        Location.Modify(true);
    end;

    local procedure UpdateExpirationDateOnWhseItemTrackingLine(ItemNo: Code[20]; LotNoFilter: Text; ExpirationDate: Date)
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
    begin
        WhseItemTrackingLine.SetRange("Item No.", ItemNo);
        WhseItemTrackingLine.SetFilter("Lot No.", LotNoFilter);
        if WhseItemTrackingLine.FindSet() then
            repeat
                WhseItemTrackingLine.Validate("Expiration Date", ExpirationDate);
                WhseItemTrackingLine.Modify(true);
            until WhseItemTrackingLine.Next() = 0
    end;

    local procedure SetupReserveOnRequisitionLine(No: Code[20]; LineType: Enum "Requisition Line Type")
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange(Type, LineType);
        RequisitionLine.SetRange("No.", No);
        RequisitionLine.FindFirst();
        RequisitionLine.Validate(Reserve, true);
        RequisitionLine.Modify(true);
    end;

    local procedure SelectItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; ItemJournalTemplateType: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplateType);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplateType, ItemJournalTemplate.Name);
        if ItemJournalBatch."No. Series" = '' then begin
            ItemJournalBatch.Validate("No. Series", ItemJournalTemplate."No. Series");
            ItemJournalBatch.Modify(true);
        end;
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure ShowItemAvailabilityByLocationOnWhseReceiptByPage(No: Code[20])
    var
        WarehouseReceipt: TestPage "Warehouse Receipt";
    begin
        WarehouseReceipt.OpenEdit();
        WarehouseReceipt.FILTER.SetFilter("No.", No);
        WarehouseReceipt.WhseReceiptLines.Location.Invoke(); // Invoke ItemAvailabilityByLocationHandler.
        WarehouseReceipt.OK().Invoke();
    end;

    local procedure SetWarehouseActivityLineLotNo(WarehouseActivityHeader: Record "Warehouse Activity Header"; ActionType: Enum "Warehouse Action Type"; ItemNo: Code[20]; LotNo: Code[50])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.Validate("Lot No.", LotNo);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure SetWarehouseActivityLineSerialNo(WarehouseActivityHeader: Record "Warehouse Activity Header"; ActionType: Enum "Warehouse Action Type"; ItemNo: Code[20]; SerialNo: Code[50])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.Validate("Serial No.", SerialNo);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure VerifyReservationEntryQty(ReservationEntry: Record "Reservation Entry"; QtyBase: Decimal; QtyToHandle: Decimal; QtyToInvoice: Decimal)
    begin
        ReservationEntry.TestField("Quantity (Base)", QtyBase);
        ReservationEntry.TestField("Qty. to Handle (Base)", QtyToHandle);
        ReservationEntry.TestField("Qty. to Invoice (Base)", QtyToInvoice);
    end;

    local procedure VerifyItemJournalLine(ItemJournalBatch: Record "Item Journal Batch"; ItemJournalLine: Record "Item Journal Line")
    begin
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch, ItemJournalLine."Item No.");
        ItemJournalLine.TestField(Quantity, ItemJournalLine.Quantity);
    end;

    local procedure VerifyItemLedgerEntry(ItemNo: Code[20]; Open: Boolean; Quantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Transfer);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange(Open, Open);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyMovementWorksheetLine(ItemNo: Code[20]; BinCode: Code[20]; BinCode2: Code[20]; Quantity: Decimal)
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        FindWarehouseWorksheetLine(WhseWorksheetLine, ItemNo);
        WhseWorksheetLine.TestField("From Bin Code", BinCode);
        WhseWorksheetLine.TestField("To Bin Code", BinCode2);
        WhseWorksheetLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyQuantityInItemReclassification(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Entry Type", ItemJournalLine."Entry Type"::Transfer);
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.SetRange("Location Code", LocationCode);
        ItemJournalLine.SetRange("Bin Code", BinCode);
        ItemJournalLine.FindFirst();
        ItemJournalLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyQuantityHandledInWarehouseActivityLine(SourceNo: Code[20]; ItemNo: Code[20]; QuantityHandled: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.TestField("Item No.", ItemNo);
            WarehouseActivityLine.TestField("Qty. Handled", QuantityHandled);
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure VerifyQuantityToHandleInWarehouseActivityLine(SourceNo: Code[20]; ItemNo: Code[20]; QuantityToHandle: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.TestField("Item No.", ItemNo);
            WarehouseActivityLine.TestField("Qty. to Handle", QuantityToHandle);
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure VerifyShippingAdviceOnPickWorksheet(ItemNo: Code[20]; ShippingAdvice: Enum "Sales Header Shipping Advice")
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        WhseWorksheetLine.SetRange("Item No.", ItemNo);
        WhseWorksheetLine.FindFirst();
        WhseWorksheetLine.TestField("Shipping Advice", ShippingAdvice);
    end;

    local procedure VerifyRegisteredWarehouseActivityLine(SalesLine: Record "Sales Line"; ActionType: Enum "Warehouse Action Type")
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        RegisteredWhseActivityLine.SetRange("Action Type", ActionType);
        RegisteredWhseActivityLine.SetRange("Source No.", SalesLine."Document No.");
        RegisteredWhseActivityLine.SetRange("Item No.", SalesLine."No.");
        RegisteredWhseActivityLine.FindFirst();
        RegisteredWhseActivityLine.SetRange(Quantity, SalesLine.Quantity);
    end;

    local procedure VerifyRegisteredWarehouseMovementLine(RegisteredWhseActivityHdr: Record "Registered Whse. Activity Hdr."; ActionType: Enum "Warehouse Action Type"; ItemNo: Code[20]; BinCode: Code[20]; Quantity: Decimal)
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        RegisteredWhseActivityLine.SetRange("Activity Type", RegisteredWhseActivityHdr.Type);
        RegisteredWhseActivityLine.SetRange("No.", RegisteredWhseActivityHdr."No.");
        RegisteredWhseActivityLine.SetRange("Action Type", ActionType);
        RegisteredWhseActivityLine.SetRange("Item No.", ItemNo);
        RegisteredWhseActivityLine.FindFirst();
        RegisteredWhseActivityLine.TestField("Bin Code", BinCode);
        RegisteredWhseActivityLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyWarehouseActivityLine(SourceNo: Code[20]; ItemNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; SourceDocument: Enum "Warehouse Activity Source Document"; Quantity: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.SetRange("Source Document", SourceDocument);
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.TestField("Item No.", ItemNo);
            WarehouseActivityLine.TestField(Quantity, Quantity);
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure VerifyWarehouseActivityLine2(ItemNo: Code[20]; BinCode: Code[20]; BinCode2: Code[20])
    var
        WarehouseEntry: Record "Warehouse Entry";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNo: Code[50];
        LotNo2: Code[20];
    begin
        LotNo := FindWarehouseEntry(WarehouseEntry, WarehouseEntry."Entry Type"::"Positive Adjmt.", BinCode, ItemNo);
        LotNo2 := FindWarehouseEntry(WarehouseEntry, WarehouseEntry."Entry Type"::"Positive Adjmt.", BinCode2, ItemNo);
        FindWarehouseActivityLine2(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Movement,
          WarehouseActivityLine."Action Type"::Take, ItemNo);

        WarehouseActivityLine.TestField("Bin Code", BinCode);
        WarehouseActivityLine.TestField("Lot No.", LotNo);
        WarehouseActivityLine.Next();
        WarehouseActivityLine.TestField("Bin Code", BinCode2);
        WarehouseActivityLine.TestField("Lot No.", LotNo2);
        WarehouseActivityLine.Next();
        WarehouseActivityLine.TestField("Bin Code", BinCode2);
        WarehouseActivityLine.TestField("Lot No.", LotNo2);
    end;

    local procedure VerifyWarehouseActivityLines(var WarehouseActivityLine: Record "Warehouse Activity Line"; BinCode: Code[20]; LotNo: Code[50]; SerialNo: Code[50]; Qty: Decimal)
    begin
        WarehouseActivityLine.TestField("Bin Code", BinCode);
        WarehouseActivityLine.TestField("Lot No.", LotNo);
        WarehouseActivityLine.TestField("Serial No.", SerialNo);
        WarehouseActivityLine.TestField(Quantity, Qty);
        WarehouseActivityLine.Next();
    end;

    local procedure VerifyWarehouseActivityLineCount(HeaderNo: Code[20]; BinCode: Code[20]; ActionType: Enum "Warehouse Action Type"; UnitOfMeasure: Code[10]; "Count": Integer)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("No.", HeaderNo);
        WarehouseActivityLine.SetRange("Bin Code", BinCode);
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.SetRange("Unit of Measure Code", UnitOfMeasure);
        Assert.RecordCount(WarehouseActivityLine, Count);
    end;

    local procedure VerifyWarehouseJournalLine(WarehouseJournalBatch: Record "Warehouse Journal Batch"; WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
        WarehouseJournalLine.SetRange("Journal Template Name", WarehouseJournalBatch."Journal Template Name");
        WarehouseJournalLine.SetRange("Journal Batch Name", WarehouseJournalBatch.Name);
        WarehouseJournalLine.SetRange("Item No.", WarehouseJournalLine."Item No.");
        WarehouseJournalLine.FindFirst();
        WarehouseJournalLine.TestField(Quantity, WarehouseJournalLine.Quantity);
    end;

    local procedure VerifyWarehouseMovementLine(WarehouseActivityHeader: Record "Warehouse Activity Header"; ActionType: Enum "Warehouse Action Type"; ItemNo: Code[20]; BinCode: Code[20]; Quantity: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField("Bin Code", BinCode);
        WarehouseActivityLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyWarehouseShipmentLine(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ItemNo: Code[20]; QtyPicked: Decimal; QtyShipped: Decimal)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("Source Document", SourceDocument);
        WarehouseShipmentLine.SetRange("Source No.", SourceNo);
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentLine.TestField("Item No.", ItemNo);
        WarehouseShipmentLine.TestField("Qty. Picked", QtyPicked);
        WarehouseShipmentLine.TestField("Qty. Shipped", QtyShipped);
    end;

    local procedure VerifyItemLastCountingPeriodUpdate(Item: Record Item; ExpDate: Date)
    begin
        Item.Find();
        Assert.AreEqual(ExpDate, Item."Last Counting Period Update", Item.FieldCaption("Last Counting Period Update"));
    end;

    local procedure VerifySKULastCountingPeriodUpdate(SKU: Record "Stockkeeping Unit"; ExpDate: Date)
    begin
        SKU.Find();
        Assert.AreEqual(ExpDate, SKU."Last Counting Period Update", SKU.FieldCaption("Last Counting Period Update"));
    end;

    local procedure VerifyLastWarehouseEntry(ItemNo: Code[20]; Quantity: Decimal; LotNo: Code[50])
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.FindLast();
        WarehouseEntry.TestField("Item No.", ItemNo);
        Assert.AreEqual(WarehouseEntry.Quantity, Quantity,
          StrSubstNo(AbsoluteValueEqualToQuantityErr, WarehouseEntry.TableName, WarehouseEntry.FieldName(Quantity)));
        WarehouseEntry.TestField("Lot No.", LotNo);
    end;

    local procedure VerifyWarehouseJournalLineWithReasonCode(
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line"; ReasonCode: Code[10])
    begin
        WarehouseJournalLine.SetRange("Journal Template Name", WarehouseJournalBatch."Journal Template Name");
        WarehouseJournalLine.SetRange("Journal Batch Name", WarehouseJournalBatch.Name);
        WarehouseJournalLine.SetRange("Item No.", WarehouseJournalLine."Item No.");
        WarehouseJournalLine.FindFirst();
        WarehouseJournalLine.TestField("Reason Code", ReasonCode);
    end;

    local procedure RunCalculateCountingPeriodFromWarehousePhysicalInventoryJournalReasonCode(
        var WarehouseJournalBatch: Record "Warehouse Journal Batch";
        LocationCode: Code[10]; ReasonCode: Code[10])
    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        PhysInvtCountManagement: Codeunit "Phys. Invt. Count.-Management";
    begin
        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Type::"Physical Inventory", LocationCode);
        WarehouseJournalTemplate.Get(WarehouseJournalBatch."Journal Template Name");
        WarehouseJournalTemplate."Reason Code" := ReasonCode;
        WarehouseJournalTemplate.Modify(true);
        WarehouseJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        WarehouseJournalBatch."Reason Code" := ReasonCode;
        WarehouseJournalBatch.Modify(true);
        WarehouseJournalLine.Init();
        WarehouseJournalLine.Validate("Journal Template Name", WarehouseJournalBatch."Journal Template Name");
        WarehouseJournalLine.Validate("Journal Batch Name", WarehouseJournalBatch.Name);
        WarehouseJournalLine.Validate("Location Code", LocationCode);
        PhysInvtCountManagement.InitFromWhseJnl(WarehouseJournalLine);
        Commit();  // Commit is required.
        PhysInvtCountManagement.Run();
    end;

    local procedure CalcPhysInvtDatesAndRunCalculateCountingPeriodInWhseInvtJournalReasonCode(
       var WarehouseJournalBatch: Record "Warehouse Journal Batch"; ItemNo: Code[20];
       LocationCode: Code[10]; LastCountingDate: Date; CountFrequency: Integer; ReasonCode: Code[10])
    var
        PhysInvtCountManagement: Codeunit "Phys. Invt. Count.-Management";
        NextCountingStartDate: Date;
        NextCountingEndDate: Date;
    begin
        PhysInvtCountManagement.CalcPeriod(LastCountingDate, NextCountingStartDate, NextCountingEndDate, CountFrequency);

        LibraryVariableStorage.Enqueue(ItemNo);
        LibraryVariableStorage.Enqueue(NextCountingStartDate);
        LibraryVariableStorage.Enqueue(NextCountingEndDate);
        RunCalculateCountingPeriodFromWarehousePhysicalInventoryJournalReasonCode(WarehouseJournalBatch, LocationCode, ReasonCode);
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; PostingDate: Date; BinCode: Code[20]; UnitOfMeasureCode: Code[10])
    begin
        LibraryInventory.CreateItemJnlLine(
            ItemJournalLine, ItemJournalLine."Entry Type"::Purchase, PostingDate, ItemNo,
            Quantity, LocationCode);
        ItemJournalLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        if BinCode <> '' then
            ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        FilterWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure FilterWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        WarehouseActivityLine.SetRange("Source Document", SourceDocument);
        if SourceNo <> '' then
            WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        Currency.Validate("Residual Gains Account", Currency."Realized Gains Acc.");
        Currency.Validate("Residual Losses Account", Currency."Realized Losses Acc.");
        Currency.Validate("Currency Factor", LibraryRandom.RandDecInDecimalRange(1.176471, 1.176471, 0));
        Currency.Modify(true);
        CreateCurrExchangeRate(Currency.Code, CalcDate('<CY+1D>', WorkDate()), LibraryRandom.RandDecInDecimalRange(0.5, 0.5, 0));
        CreateCurrExchangeRate(Currency.Code, CalcDate('<CY+1M+2D>', WorkDate()), LibraryRandom.RandDecInDecimalRange(0.75, 0.75, 0));
        CreateCurrExchangeRate(Currency.Code, CalcDate('<CY+1M+14D>', WorkDate()), LibraryRandom.RandDecInDecimalRange(0.85, 0.85, 0));
        exit(Currency.Code);
    end;

    procedure CreateCurrExchangeRate(CurrencyCode: Code[10]; StartingDate: Date; RelExchRateAmt: Decimal)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyExchangeRate.Init();
        CurrencyExchangeRate.Validate("Currency Code", CurrencyCode);
        CurrencyExchangeRate.Validate("Starting Date", StartingDate);
        CurrencyExchangeRate.Insert(true);

        CurrencyExchangeRate.Validate("Exchange Rate Amount", LibraryRandom.RandDecInDecimalRange(1.0, 1.0, 0));
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", LibraryRandom.RandDecInDecimalRange(1.0, 1.0, 0));

        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", RelExchRateAmt);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", RelExchRateAmt);
        CurrencyExchangeRate.Validate("Fix Exchange Rate Amount", CurrencyExchangeRate."Fix Exchange Rate Amount"::Currency);
        CurrencyExchangeRate.Modify(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Register", 'OnBeforeAutoReserveForSalesLine', '', false, false)]
    local procedure InvokeErrorOnRegisteringWarehousePick(var TempWhseActivLineToReserve: Record "Warehouse Activity Line" temporary; var IsHandled: Boolean)
    begin
        Error(RegisteringPickInterruptedErr);
    end;

    [EventSubscriber(ObjectType::Report, Report::"Create Invt Put-away/Pick/Mvmt", 'OnBeforeCheckWhseRequest', '', false, false)]
    local procedure PostInventoryPickOnCheckWhseRequest(var WarehouseRequest: Record "Warehouse Request")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        if WarehouseRequest."Shipping Advice" = WarehouseRequest."Shipping Advice"::Complete then begin
            WarehouseActivityHeader.SetRange("Location Code", WarehouseRequest."Location Code");
            WarehouseActivityHeader.FindFirst();
            LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, true);
        end;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Create Invt Put-away/Pick/Mvmt", 'OnAfterCheckWhseRequest', '', false, false)]
    local procedure CheckRecordIsSkippedAfterCheckWhseRequest(var WarehouseRequest: Record "Warehouse Request"; var SkipRecord: Boolean)
    begin
        Assert.IsTrue((WarehouseRequest."Shipping Advice" = WarehouseRequest."Shipping Advice"::Complete) = SkipRecord, '');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Inventory Pick/Movement", 'OnBeforeCheckSourceDoc', '', false, false)]
    local procedure PostInventoryPickOnCheckSourceDoc(WarehouseRequest: Record "Warehouse Request")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        if WarehouseRequest."Shipping Advice" = WarehouseRequest."Shipping Advice"::Partial then begin
            WarehouseActivityHeader.SetRange("Location Code", WarehouseRequest."Location Code");
            WarehouseActivityHeader.FindFirst();
            LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, true);
        end;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculateInventoryHandler(var WhseCalculateInventory: TestRequestPage "Whse. Calculate Inventory")
    begin
        WhseCalculateInventory.WhseDocumentNo.SetValue(LibraryRandom.RandInt(10));  // Value Not important for test.
        WhseCalculateInventory.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
        ConfirmMessage := Question;  // The variable ConfirmMessage is made Global as it is used in the handler.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreatePickHandler(var CreatePick: TestRequestPage "Create Pick")
    begin
        CreatePick.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreatePutAwayHandler(var WhseSourceCreateDocument: TestRequestPage "Whse.-Source - Create Document")
    begin
        WhseSourceCreateDocument.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantityToCreateHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantityToCreateHandler2(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.CreateNewLotNo.SetValue(true);
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Assign Lot No.".Invoke();
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesHandler2(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        case LibraryVariableStorage.DequeueInteger() of
            TrackingActionStr::AssignLotNo:
                ItemTrackingLines."Assign Lot No.".Invoke();
            TrackingActionStr::SelectEntries:
                ItemTrackingLines."Select Entries".Invoke();
            TrackingActionStr::AssignGivenLotNo:
                begin
                    ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueInteger());
                end;
            TrackingActionStr::AssistEditLotNo:
                ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesSalesHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Select Entries".Invoke();
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesHandlerWithSerialNo(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Assign Serial No.".Invoke();
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
    procedure ItemTrackingSummarySelectLotHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.FILTER.SetFilter("Lot No.", LibraryVariableStorage.DequeueText());
        ItemTrackingSummary.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SourceDocumentsPageHandler(var SourceDocuments: Page "Source Documents"; var Response: Action)
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        WarehouseRequest.SetRange("Location Code", LibraryVariableStorage.DequeueText());
        WarehouseRequest.SetRange("Source No.", LibraryVariableStorage.DequeueText());
        WarehouseRequest.FindFirst();
        SourceDocuments.SetRecord(WarehouseRequest);
        Response := ACTION::LookupOK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PutAwaySelectionHandler(var PutAwaySelection: TestPage "Put-away Selection")
    begin
        PutAwaySelection.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    begin
        WhseItemTrackingLines."Lot No.".AssistEdit();
        WhseItemTrackingLines."New Lot No.".SetValue(LibraryUtility.GenerateGUID());
        WhseItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingPageHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    var
        TrackingAction: Variant;
        ItemTrackingAction: Option;
        TrackingQuantity: Decimal;
    begin
        LibraryVariableStorage.Dequeue(TrackingAction);
        ItemTrackingAction := TrackingAction;
        TrackingQuantity := WhseItemTrackingLines.Quantity3.AsDecimal();

        case ItemTrackingAction of
            TrackingActionStr::AssignLotNo:
                begin
                    WhseItemTrackingLines."Lot No.".SetValue(LibraryUtility.GenerateGUID());
                    WhseItemTrackingLines.Quantity.SetValue(TrackingQuantity);
                end;
            TrackingActionStr::AssignGivenLotNo:
                begin
                    WhseItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                    WhseItemTrackingLines.Quantity.SetValue(TrackingQuantity);
                end;
            TrackingActionStr::AssignSerialNo:
                begin
                    WhseItemTrackingLines.First();
                    while TrackingQuantity > 0 do begin
                        TrackingQuantity -= 1;
                        WhseItemTrackingLines."Serial No.".SetValue(LibraryUtility.GenerateGUID());
                        WhseItemTrackingLines.Quantity.SetValue(1);
                        WhseItemTrackingLines.Next();
                    end;
                end;
            TrackingActionStr::AssignGivenLotAndSerialNo:
                begin
                    WhseItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                    WhseItemTrackingLines."Serial No.".SetValue(LibraryVariableStorage.DequeueText());
                    WhseItemTrackingLines.Quantity.SetValue(1);
                end;
            TrackingActionStr::AssistEditLotNo:
                begin
                    WhseItemTrackingLines."Lot No.".AssistEdit();
                    LibraryVariableStorage.Enqueue(WhseItemTrackingLines.Quantity.Value);
                end;
        end;
        WhseItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PickSelectionHandler(var PickSelection: TestPage "Pick Selection")
    begin
        PickSelection.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PhysicalInventoryItemSelectionHandler(var PhysInvtItemSelection: TestPage "Phys. Invt. Item Selection")
    begin
        PhysInvtItemSelection.FILTER.SetFilter("Item No.", LibraryVariableStorage.DequeueText());
        PhysInvtItemSelection.First();
        PhysInvtItemSelection."Next Counting Start Date".AssertEquals(LibraryVariableStorage.DequeueDate());
        PhysInvtItemSelection."Next Counting End Date".AssertEquals(LibraryVariableStorage.DequeueDate());
        PhysInvtItemSelection.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculatePhysicalInventoryCountingHandler(var CalculatePhysInvtCounting: TestRequestPage "Calculate Phys. Invt. Counting")
    begin
        CalculatePhysInvtCounting.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhseSourceCreateDocumentHandler(var WhseSourceCreateDocument: TestRequestPage "Whse.-Source - Create Document")
    begin
        WhseSourceCreateDocument.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MakeSupplyOrdersPageHandler(var MakeSupplyOrders: Page "Make Supply Orders";

    var
        Response: Action)
    begin
        Response := ACTION::LookupOK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemAvailabilityByLocationHandler(var ItemAvailabilityByLocation: Page "Item Availability by Location";

    var
        Response: Action)
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculateBinReplenishmentRequestPageHandler(var CalculateBinReplenishment: TestRequestPage "Calculate Bin Replenishment")
    begin
        CalculateBinReplenishment.LocCode.SetValue(LibraryVariableStorage.DequeueText());
        CalculateBinReplenishment.WorksheetTemplateName.SetValue(LibraryVariableStorage.DequeueText());
        CalculateBinReplenishment.WorksheetName.SetValue(LibraryVariableStorage.DequeueText());
        CalculateBinReplenishment.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculateBinReplenishmentTestRequestPageHandler(var CalculateBinReplenishment: TestRequestPage "Calculate Bin Replenishment")
    begin
        case LibraryVariableStorage.DequeueInteger() of
            1:
                begin
                    CalculateBinReplenishment.LocCode.SetValue(LibraryVariableStorage.DequeueText());
                    CalculateBinReplenishment.WorksheetTemplateName.SetValue(LibraryVariableStorage.DequeueText());

                    CalculateBinReplenishment.WorksheetName.Lookup();

                    LibraryVariableStorage.Enqueue(CalculateBinReplenishment.WorksheetName.Value);
                end;
            2:
                begin
                    CalculateBinReplenishment.LocCode.SetValue(LibraryVariableStorage.DequeueText());
                    CalculateBinReplenishment.WorksheetTemplateName.SetValue(LibraryVariableStorage.DequeueText());
                    CalculateBinReplenishment.WorksheetName.SetValue(LibraryVariableStorage.DequeueText());

                    CalculateBinReplenishment.WorksheetTemplateName.SetValue('');

                    LibraryVariableStorage.Enqueue(CalculateBinReplenishment.WorksheetName.Value);
                end;
        end;
        CalculateBinReplenishment.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WorksheetNamesListModalPageHandler(var WorksheetNamesList: TestPage "Worksheet Names List")
    begin
        WorksheetNamesList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesModalPageHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    begin
        WhseItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        WhseItemTrackingLines.Quantity.SetValue(LibraryVariableStorage.DequeueInteger());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure BinContentsListModalPageHandler(var BinContentsList: TestPage "Bin Contents List")
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DeleteRegisteredWhseDocsCancelRequestPageHandler(var DeleteRegisteredWhseDocs: TestRequestPage "Delete Registered Whse. Docs.")
    begin
        DeleteRegisteredWhseDocs.Cancel().Invoke();
    end;
}

