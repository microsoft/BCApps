codeunit 137038 "SCM Transfers"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Planning] [SCM] [Transfer Order]
        isInitialized := false;
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        DummyTransferOrderPage: TestPage "Transfer Order";
        LocationCode: array[5] of Code[10];
        SourceDocument: Option ,"S. Order","S. Invoice","S. Credit Memo","S. Return Order","P. Order","P. Invoice","P. Credit Memo","P. Return Order","Inb. Transfer","Outb. Transfer","Prod. Consumption","Item Jnl.","Phys. Invt. Jnl.","Reclass. Jnl.","Consumption Jnl.","Output Jnl.","BOM Jnl.","Serv. Order","Job Jnl.","Assembly Consumption","Assembly Order";
        TrackingOption: Option AssignLotNo,AssignSerialNo,SelectEntries,ShowEntries,VerifyEntries,AssignManualLotNos;
        isInitialized: Boolean;
        NoOfLinesMustBeEqualErr: Label 'No. of Line Must Be Equal.';
        TransferOrderCountErr: Label 'Wrong Transfer Order''s count';
        ItemIsNotOnInventoryErr: Label 'Item %1 is not in inventory.', Locked = true;
        UpdateFromHeaderLinesQst: Label 'You may have changed a dimension.\\Do you want to update the lines?';
        UpdateLineDimQst: Label 'You have changed one or more dimensions on the';
        TransferOrderSubpageNotUpdatedErr: Label 'Transfer Order subpage is not updated.';
        AnotherItemWithSameDescTxt: Label 'We found an item with the description';
        RoundingTo0Err: Label 'Rounding of the field';
        RoundingErr: Label 'is of lower precision than expected';
        RoundingBalanceErr: Label 'This will cause the quantity and base quantity fields to be out of balance.';
        ILECorrectedAndNotErr: Label 'Expected same number of corrected and not corrected Item Ledger Entries for undone Transfer Shipment';
        ILEIncorrectSumErr: Label 'Expected sum of quantities to be 0 for Item Ledger Entries after undone Transfer Shipment';
        TransShptIncorrectSumErr: Label 'Expected sum of quantities to be 0 for Transfer Shipment Lines of undone Transfer Shipment';
        TransShptLineNotCorrectionErr: Label 'Expected Line of undone Transfer Shipment to have "Correction Line"=true, but it din''t';
        UndoneTransLineQtyErr: Label 'Expected Quantity to be 0 after Transfer Shipment was undone';
        DerivedTransLineErr: Label 'Expected no Derived Transfer Line i.e. line with "Derived From Line No." equal to original transfer line.';
        IncorrectSNUndoneErr: Label 'The Serial No. of the item on the transfer shipment line that was undone was different from the SN on the corresponding transfer line.';
        ApplToItemEntryErr: Label '%1 must be %2 in %3.', Comment = '%1 is Appl-to Item Entry, %2 is Item Ledger Entry No. and %3 is Transfer Line';
        VariantCodeMandatoryErr: Label '%1 must have a value in %2: Document No.=%3, Line No.=%4. It cannot be zero or empty.', Comment = '%1:Field Caption, %2: TableCaption, %3:Document No, %4: Line No.';

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderCalcNetChange()
    var
        SalesHeader: Record "Sales Header";
        RequisitionLine: Record "Requisition Line";
        ItemNo: array[4] of Code[20];
    begin
        // Setup  : Update Sales Setup. Create Transfer setup
        Initialize();
        UpdateSalesReceivablesSetup();
        CreateTransferSetup(SalesHeader, ItemNo, true);

        // Execute : Create Planning Worksheet and Calculate Net Change Plan.
        CreateReqLine(RequisitionLine);
        CalculateNetChangePlan(RequisitionLine, SalesHeader."Shipment Date", ItemNo);

        // Verify : Verify Seven Requisition Lines Exist in Planning Worksheet.
        // One Item Line for Item4 and Item1 each.Two Item Lines for Item3 and three Item lines for Item2.
        VerifyNumberOfRequisitionLine(ItemNo, 7);

        // Execute : Carry Out Action Message in Planning Worksheet.
        CarryOutActionMsgPlanSetup(RequisitionLine, ItemNo);

        // Verify : Verify no Requisition Lines Exist in Planning Worksheet after Carry Out Action Message in Requisition Worksheet.
        VerifyNumberOfRequisitionLine(ItemNo, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchOrdCalcNetChange()
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        RequisitionLine: Record "Requisition Line";
        ItemNo: array[4] of Code[20];
    begin
        // Setup  : Update Sales Setup. Create Transfer setup.
        Initialize();
        UpdateSalesReceivablesSetup();
        CreateTransferSetup(SalesHeader, ItemNo, true);

        // Create and Update Purchase Order for ItemNo2 with LocationCode4.
        CreatePurchaseOrder(PurchaseHeader, ItemNo[2], LibraryRandom.RandInt(10));
        UpdatePurchaseLine(PurchaseHeader, LocationCode[4]);

        // Execute : Create Planning Worksheet and Calculate Net Change Plan.
        CreateReqLine(RequisitionLine);
        CalculateNetChangePlan(RequisitionLine, SalesHeader."Shipment Date", ItemNo);

        // Verify : Verify ItemNo exist Planning Worksheet.
        VerifyItemNoExistInReqLine(ItemNo[1]);

        // Execute : Carry Out Action Message in Planning Worksheet.
        CarryOutActionMsgPlanSetup(RequisitionLine, ItemNo);

        // Verify : Verify no Requisition Lines Exist in Planning Worksheet after Carry Out Action Message in Requisition Worksheet.
        VerifyNumberOfRequisitionLine(ItemNo, 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure UndoTransferShipmentLine()
    var
        TransferHeader: Record "Transfer Header";
        QtyToShip: Integer;
    begin
        // [FEATURE 332164] [Transfer] [Order] [Undo Shipment]
        // [SCENARIO] Undo Transfer Shipment Line
        Initialize();
        QtyToShip := LibraryRandom.RandInt(10) + 1;

        // [GIVEN] A shipped transfer order with one line
        CreateAndShipTransferOrder(TransferHeader, QtyToShip, false, false);

        // [WHEN] The posted transfer shipment line is undone
        LibraryInventory.UndoTransferShipments(TransferHeader."No.");

        // [THEN] The Transfer Order has been completely unshipped
        VerifyTransferOrderCompletelyUnshipped(TransferHeader);

        // [THEN] The order can be fully shipped and received with no error
        ShipAndReceiveTransOrderFully(TransferHeader, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure UndoTransferShipmentLineWithRefDocChecking()
    var
        TransferHeader: Record "Transfer Header";
        QtyToShip: Integer;
    begin
        // [Transfer] [Order] [Undo Shipment] [Warehouse Entry]
        // [SCENARIO] Undo Transfer Shipment Line, and check if the Ref Doc is "Posted Transfer Shipment"
        // This test case initialize "Location" with "Bin". Only in this way the table "Warehouse Entry" can be updated.
        // For the other test, the table "Warehouse Entry" will not be updated for the "Location" does not contain "Bin".
        Initialize();
        QtyToShip := LibraryRandom.RandInt(10) + 1;

        // [GIVEN] A shipped transfer order with one line
        CreateAndShipTransferOrderWithBin(TransferHeader, QtyToShip);

        // [WHEN] The posted transfer shipment line is undone
        LibraryInventory.UndoTransferShipments(TransferHeader."No.");

        // [THEN] The Transfer Order has been completely unshipped
        VerifyTransferOrderCompletelyUnshippedWithRefDoc(TransferHeader);

        // [THEN] The order can be fully shipped and received with no error
        ShipAndReceiveTransOrderFully(TransferHeader, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure UndoTransferShipmentLineTwice()
    var
        TransferHeader: Record "Transfer Header";
        QtyToShip: Integer;
    begin
        // [FEATURE 332164] [Transfer] [Order] [Undo Shipment]
        // [SCENARIO] Check that Transfer Shipment Line can be posted and undone multiple times
        Initialize();
        QtyToShip := LibraryRandom.RandInt(10) + 1;

        // [GIVEN] A shipped Transfer Order with one line
        CreateAndShipTransferOrder(TransferHeader, QtyToShip, false, false);

        // [GIVEN] The Transfer Shipment Line is undone and posted again
        LibraryInventory.UndoTransferShipments(TransferHeader."No.");
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);

        // [WHEN] The posted Transfer Shipment is undone again
        LibraryInventory.UndoTransferShipments(TransferHeader."No.");

        // [THEN] The Transfer Order has been completely unshipped
        VerifyTransferOrderCompletelyUnshipped(TransferHeader);

        // [THEN] The order can be fully shipped and received with no error
        ShipAndReceiveTransOrderFully(TransferHeader, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure UndoPartiallyPostedTransShpt()
    var
        TransferHeader: Record "Transfer Header";
        QtyToShip: Integer;
    begin
        // [FEATURE 332164] [Transfer] [Order] [Undo Shipment]
        // [SCENARIO] Check that Transfer Shipment Line of partially shipped Transfer Order can be undone
        Initialize();
        QtyToShip := LibraryRandom.RandInt(10) + 5;

        // [GIVEN] A Transfer Order with one line fully shipped, one line partly shipped and one line not shipped.
        CreateAndShipTransferOrder(TransferHeader, QtyToShip, true, true);

        // [WHEN] All posted Transfer Shipment Lines are undone
        LibraryInventory.UndoTransferShipments(TransferHeader."No.");

        // [THEN] The Transfer Order has been completely unshipped
        VerifyTransferOrderCompletelyUnshipped(TransferHeader);

        // [THEN] The order can be fully shipped and received with no error
        ShipAndReceiveTransOrderFully(TransferHeader, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CannotReceiveTransOrderAfterUndoShpt()
    var
        TransferHeader: Record "Transfer Header";
        QtyToShip: Integer;
    begin
        // [FEATURE 332164] [Transfer] [Order] [Undo Shipment]
        // [SCENARIO] Check that Transfer Shipment cannot be received after it has been undone
        Initialize();
        QtyToShip := LibraryRandom.RandInt(10) + 1;

        /// [GIVEN] A shipped Transfer Order with one line
        CreateAndShipTransferOrder(TransferHeader, QtyToShip, false, false);

        // [GIVEN] The posted Transfer Shipment Line is undone
        LibraryInventory.UndoTransferShipments(TransferHeader."No.");

        // [THEN] The order can't be received
        asserterror ReceiveTransOrderFully(TransferHeader);
        Assert.ExpectedError('nothing to post');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CannotUndoShipmentOfReceivedLine()
    var
        TransferHeader: Record "Transfer Header";
        TransferLineA: Record "Transfer Line";
        TransferLineB: Record "Transfer Line";
        TransferShipmentLine: Record "Transfer Shipment Line";
        FromLocation: Record Location;
        ToLocation: Record Location;
        TransitLocation: Record Location;
        Item: Record Item;
        QtyToShip: Integer;
    begin
        // [FEATURE 332164] [Transfer] [Order] [Undo Shipment]
        // [SCENARIO] Check that Transfer Shipments cannot be undone if the Transfer Line they came from is already partially received
        QtyToShip := LibraryRandom.RandInt(10) + 1;

        /// [GIVEN] A Transfer Order with two lines
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(FromLocation);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(TransitLocation);
        LibraryInventory.CreateTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code, TransitLocation.Code);
        CreateItemWithPositiveInventory(Item, FromLocation.code, 2 * QtyToShip);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLineA, Item."No.", QtyToShip);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLineB, Item."No.", QtyToShip);

        // [GIVEN] Line A is shipped and received
        TransferLineB.Validate("Qty. to Ship", 0);
        TransferLineB.Modify();
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        // [GIVEN] Line B is shipped
        TransferLineB.Get(TransferHeader."No.", TransferLineB."Line No.");
        TransferLineB.Validate("Qty. to Ship", QtyToShip);
        TransferLineB.Modify();
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);

        // [WHEN] We attempt to undo Shipment A
        TransferShipmentLine.SetFilter("Transfer Order No.", TransferHeader."No.");
        TransferShipmentLine.SetRange("Trans. Order Line No.", TransferLineA."Line No.");
        asserterror LibraryInventory.UndoTransferShipmentLinesInFilter(TransferShipmentLine);

        // [THEN] It is not possible, because that line has been received
        Assert.ExpectedError('already been received');

        // [WHEN] We attempt to undo Shipment B
        TransferShipmentLine.SetRange("Trans. Order Line No.", TransferLineB."Line No.");
        LibraryInventory.UndoTransferShipmentLinesInFilter(TransferShipmentLine);

        // [THEN] Then no errors occur

        // [THEN] The order can be fully shipped and received with no error
        ShipAndReceiveTransOrderFully(TransferHeader, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,ItemTrackingLinesModalPageHandlerGeneric,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,PostedItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure UndoTransShpt_SNTracking()
    var
        TransferHeader: Record "Transfer Header";
        QtyToShip: Integer;
    begin
        // [FEATURE 332164] [Transfer] [Order] [Undo Shipment]
        // [SCENARIO] Check that Transfer Shipments with Serial No. Item Tracking can be undone 
        Initialize();
        QtyToShip := LibraryRandom.RandInt(10) + 1;

        // [GIVEN] A shipped Transfer Order with one line tracked with SN and QtyToShip is full Qty
        CreateAndShipTransferOrderWithTracking(TransferHeader, QtyToShip, false, true, false);

        // [WHEN] The posted Transfer Shipment Line is undone
        LibraryInventory.UndoTransferShipments(TransferHeader."No.");

        // [THEN] The Transfer Order has been completely unshipped
        VerifyTransferOrderCompletelyUnshipped(TransferHeader);

        // [THEN] The item tracking information on the order is reset to a pre-posting state
        VerifyTrackingNotShippedOnTransferOrder(TransferHeader);

        // [THEN] The order can be fully shipped and received with no error
        ShipAndReceiveTransOrderFully(TransferHeader, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,ItemTrackingLinesModalPageHandlerGeneric,ItemTrackingSummaryPageHandler,PostedItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure UndoTransShpt_LotTracking()
    var
        TransferHeader: Record "Transfer Header";
        QtyToShip: Integer;
    begin
        // [FEATURE 332164] [Transfer] [Order] [Undo Shipment]
        // [SCENARIO] Check that Transfer Shipments with Lot No. Item Tracking can be undone 
        Initialize();
        QtyToShip := LibraryRandom.RandInt(10) + 1;

        // [GIVEN] A shipped Transfer Order with one line tracked with Lot No. and QtyToShip is full Qty
        CreateAndShipTransferOrderWithTracking(TransferHeader, QtyToShip, true, true, false);

        // [WHEN] The posted Transfer Shipment Lines are undone
        LibraryInventory.UndoTransferShipments(TransferHeader."No.");

        // [THEN] The Transfer Order has been completely unshipped
        VerifyTransferOrderCompletelyUnshipped(TransferHeader);

        // [THEN] The item tracking information on the order is reset to a pre-posting state
        VerifyTrackingNotShippedOnTransferOrder(TransferHeader);

        // [THEN] The order can be fully shipped and received with no error
        ShipAndReceiveTransOrderFully(TransferHeader, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,ItemTrackingLinesModalPageHandlerGeneric,ItemTrackingSummaryPageHandler,PostedItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure UndoTransShpt_LotTracking_PartialPosting()
    var
        TransferHeader: Record "Transfer Header";
        QtyToShip: Integer;
    begin
        // [FEATURE 332164] [Transfer] [Order] [Undo Shipment]
        // [SCENARIO] Check that Transfer Shipments with Lot No., multiple lines and partial Qty. shipped can be undone 
        Initialize();
        QtyToShip := LibraryRandom.RandInt(10) + 1;

        // [GIVEN] A shipped Transfer Order with two lines tracked with Lot No. and partial qty is shipped
        CreateAndShipTransferOrderWithTracking(TransferHeader, QtyToShip, true, false, true);

        // [WHEN] The posted Transfer Shipment Line is undone
        LibraryInventory.UndoTransferShipments(TransferHeader."No.");

        // [THEN] The Transfer Order has been completely unshipped
        VerifyTransferOrderCompletelyUnshipped(TransferHeader);

        // [THEN] The item tracking information on the order is reset to a pre-posting state
        VerifyTrackingNotShippedOnTransferOrder(TransferHeader);

        // [THEN] The order can be fully shipped and received with no error
        ShipAndReceiveTransOrderFully(TransferHeader, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,ItemTrackingLinesModalPageHandlerGeneric,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure UndoTransShpt_LotTracking_AdditionalUoM()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemJournalLine: Record "Item Journal Line";
        InTransitLocation: Record Location;
        LocationFromCode: Code[10];
        LocationToCode: Code[10];
        QtyToShip: Integer;
    begin
        // [FEATURE 548762] [Transfer] [Order] [Undo Shipment] [Item Tracking] [additional UoM]
        // [SCENARIO] Check that Transfer Shipments with Lot No. Item Tracking and additional UoM can be undone 
        Initialize();

        // [GIVEN] From/To Locations and InTransit Location
        CreateLocations(LocationFromCode, LocationToCode);
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);

        // [GIVEN] Create tracked item with additional UoM        
        LibraryItemTracking.CreateLotItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 10);

        // [GIVEN] Add inventory in additional UoM and with Lot No.
        QtyToShip := LibraryRandom.RandInt(10);
        LibraryVariableStorage.Enqueue(TrackingOption::AssignLotNo);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", LocationFromCode, '', 2 * QtyToShip);
        ItemJournalLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        ItemJournalLine.Modify();
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] A shipped Transfer Order with one line tracked with Lot No. in additional UoM 
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFromCode, LocationToCode, InTransitLocation.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", QtyToShip);
        TransferLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        TransferLine.Modify();
        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries);
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);

        // [WHEN] The posted Transfer Shipment Lines are undone
        LibraryInventory.UndoTransferShipments(TransferHeader."No.");

        // [THEN] The Transfer Order has been completely unshipped
        VerifyTransferOrderCompletelyUnshipped(TransferHeader);

        // [THEN] The order can be fully shipped and received with no error
        ShipAndReceiveTransOrderFully(TransferHeader, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,ItemTrackingLinesModalPageHandlerGeneric,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure UndoTransShptLineFindsCorrectTrackingInfo()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: array[3] of Record "Transfer Line";
        TransferShipmentLine: Record "Transfer Shipment Line";
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReservationEntry: Record "Reservation Entry";
    begin
        // [FEATURE 332164] [Transfer] [Order] [Undo Shipment]
        // [SCENARIO] Check that UndoTransferShipment moves the correct Tracking Info back to the Order
        // when there are multiple identical Transfer Shipments 
        Initialize();

        // [GIVEN] A Transfer Order and an Item with Serial No. tracking
        CreateTransferOrderHeader(TransferHeader);
        LibraryItemTracking.CreateSerialItem(Item);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", TransferHeader."Transfer-from Code", '', 3);
        LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialNo);
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Three almost identical lines - only Serial Nos are different
        CreateTransferOrderLineAndAssignTracking(TransferHeader, TransferLine[1], Item."No.", 1, 0);
        CreateTransferOrderLineAndAssignTracking(TransferHeader, TransferLine[2], Item."No.", 1, 0);
        CreateTransferOrderLineAndAssignTracking(TransferHeader, TransferLine[3], Item."No.", 1, 0);

        // [GIVEN] The lines are each shipped individually
        ShipSingleTransferLine(TransferLine[1], 1);
        ShipSingleTransferLine(TransferLine[2], 1);
        ShipSingleTransferLine(TransferLine[3], 1);

        // [WHEN] The "middle" Shipment Line is undone
        TransferShipmentLine.SetFilter("Transfer Order No.", TransferHeader."No.");
        TransferShipmentLine.SetRange("Trans. Order Line No.", TransferLine[2]."Line No.");
        TransferShipmentLine.FindFirst();
        LibraryInventory.UndoTransferShipmentLinesInFilter(TransferShipmentLine);

        // [THEN] The Serial No. on the undone Shipment Line matches the one that has been moved back to the Order
        // Find the Reservation Entry on the Order Line
        ReservationEntry.SetRange("Source Type", Database::"Transfer Line");
        ReservationEntry.SetRange("Source Subtype", "Transfer Direction"::Outbound.AsInteger());
        ReservationEntry.SetFilter("Source ID", TransferHeader."No.");
        ReservationEntry.SetRange("Source Ref. No.", TransferLine[2]."Line No.");
        ReservationEntry.FindFirst();

        // Find the Item Ledger Entry for the undone shipment line
        ItemLedgerEntry.SetRange("Entry Type", "Item Ledger Entry Type"::Transfer);
        ItemLedgerEntry.SetFilter("Document No.", TransferShipmentLine."Document No.");
        ItemLedgerEntry.SetRange("Order Line No.", TransferLine[2]."Line No.");
        ItemLedgerEntry.FindFirst(); // There are multiple of these, but the SN is the same for all

        // Assert that they are equal
        Assert.AreEqual(ItemLedgerEntry."Serial No.", ReservationEntry."Serial No.", IncorrectSNUndoneErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,ItemTrackingLinesModalPageHandlerGeneric,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure UndoTransShptLineFailsIfReservEntryStatusChanged()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ReservationEntry: Record "Reservation Entry";
        QtyToShip: Integer;
    begin
        // [FEATURE 332164] [Transfer] [Order] [Undo Shipment]
        // [SCENARIO] A Transfer Shipment with Item Tracking is posted and has Reservation Entries on the To-Location. 
        //If the status if these change from Surplus, the Shipment cannot be undone.
        Initialize();

        Initialize();
        QtyToShip := LibraryRandom.RandInt(10) + 1;

        // [GIVEN] A shipped Transfer Order with one line tracked with SN and QtyToShip is full Qty
        CreateAndShipTransferOrderWithTracking(TransferHeader, QtyToShip, false, true, false);

        // Find the transfer line (Not the derived line)
        TransferLine.SetFilter("Document No.", TransferHeader."No.");
        TransferLine.SetRange("Derived From Line No.", 0);
        TransferLine.FindFirst();

        // [GIVEN] A Reservation Entry on the receiving end of the order changes status to "Reservation" (any other status than Surplus)
        FindFirstReservEntryOnDerivedLine(TransferLine, ReservationEntry);
        ReservationEntry."Reservation Status" := "Reservation Status"::Reservation;
        ReservationEntry.Modify();

        // [WHEN] We attempt to undo the posted Transfer Shipment Line 
        asserterror LibraryInventory.UndoTransferShipments(TransferHeader."No.");

        // [THEN] An error occurs, explaining that the line is reserved
        Assert.ExpectedError('this line is Reserved');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure UndoTransferShipmentLineWithUOM()
    var
        ItemUOM: Record "Item Unit of Measure";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        FromLocation: Record Location;
        ToLocation: Record Location;
        TransitLocation: Record Location;
        Item: Record Item;
        QtyToShip: Integer;
        QtyPerUOM: Integer;
    begin
        // [FEATURE 332164] [Transfer] [Order] [Undo Shipment]
        // [SCENARIO] Undo Transfer Shipment Line that has a Unit of Measure different from the Base UOM
        Initialize();
        QtyToShip := LibraryRandom.RandInt(10) + 1;
        QtyPerUOM := LibraryRandom.RandInt(10) + 1;

        // [GIVEN] locations
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(FromLocation);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(TransitLocation);

        // [GIVEN] Item with positive inventory on From-location
        CreateItemWithPositiveInventory(Item, FromLocation.Code, QtyPerUOM * QtyToShip);

        // [GIVEN] Unit of measure "BOX" containing "QtyPerUOM" of the base UOM
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUOM, Item."No.", QtyPerUOM);

        // [GIVEN] A Transfer Order with one line using UOM = BOX is created and posted
        LibraryInventory.CreateTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code, TransitLocation.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", QtyToShip);
        TransferLine.Validate("Unit of Measure Code", ItemUOM.Code);
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);

        // [WHEN] The Posted Transfer Shipment Line is undone
        LibraryInventory.UndoTransferShipments(TransferHeader."No.");

        // [THEN] The sum of the Item Ledger Entries on the From-location is QtyToShip*QtyPerUom again
        Assert.AreEqual(QtyToShip * QtyPerUOM, SumILEForItemOnLocation(Item."No.", FromLocation.Code), 'Wrong quantity on Transfer From-location after Undo Transfer Shipment with UOM conversion');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure UndoTransferShipmentForShipmentLinesWithQuantityZero()
    var
        TransferHeader: Record "Transfer Header";
        TransferShipmentLine: Record "Transfer Shipment Line";
        QtyToShip: Integer;
    begin
        // [FEATURE 332164] [Transfer] [Order] [Undo Shipment]
        // [SCENARIO] Undo Transfer Shipment Line
        Initialize();
        QtyToShip := LibraryRandom.RandInt(10) + 1;

        // [GIVEN] A shipped Transfer Order with one shipped line and one not shipped line
        CreateAndShipTransferOrder(TransferHeader, QtyToShip, false, true);

        // [WHEN] The posted Transfer Shipment Line is undone
        LibraryInventory.UndoTransferShipments(TransferHeader."No.");

        // [THEN] The Transfer Shipment Line with 0 quantity was not undone (So it doesn't have a correction line)
        TransferShipmentLine.SetRange("Transfer Order No.", TransferHeader."No.");
        TransferShipmentLine.SetRange(Quantity, 0);
        Assert.AreEqual(1, TransferShipmentLine.Count, 'Transfer Shipment Line with quantity 0 should not have been undone');
        TransferShipmentLine.FindFirst();
        Assert.IsFalse(TransferShipmentLine."Correction Line", 'Transfer Shipment Line with quantity 0 should not have been undone.');
    end;

    [HandlerFunctions('MessageHandler,SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestTransferOrderNotifications()
    var
        SalesHeader: Record "Sales Header";
        TransferLine: Record "Transfer Line";
        TempNotificationContext: Record "Notification Context" temporary;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        NbNotifs: Integer;
        ItemNo: array[4] of Code[20];
        TransferOrderNo: Code[20];
    begin
        // SCENARIO: Create a transfer order with a big quantity decrease the quantity and check the notification is recalled.
        Initialize();
        LibrarySales.SetStockoutWarning(true);
        CreateTransferSetup(SalesHeader, ItemNo, true);
        TransferOrderNo := CreateTransferOrder(
            TransferLine, LocationCode[4], LocationCode[2], ItemNo[2], CalcDate('<-1Y>', SalesHeader."Order Date"),
            LibraryRandom.RandInt(5));
        EditTransferOrderQuantity(TransferOrderNo, 1); // This will send a notification (no item in inventory)
        NotificationLifecycleMgt.GetTmpNotificationContext(TempNotificationContext);
        NbNotifs := TempNotificationContext.Count();

        // WHEN we decrease the quantity so the item is available (0 items ordered)
        EditTransferOrderQuantity(TransferOrderNo, 0);

        // THEN the item availability notification is recalled
        Assert.AreEqual(NbNotifs - 1, TempNotificationContext.Count, 'Unexpected number of notifications after decreasing the Quantity.');

        LibrarySales.SetStockoutWarning(false);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    local procedure EditTransferOrderQuantity(TransferOrderNo: Code[20]; TransferQuantity: Integer)
    begin
        // Method Edits Transfer Order Quantity.
        OpenTransferOrderPageByNo(TransferOrderNo, DummyTransferOrderPage);

        // EXECUTE: Change Transfer Quantity on Transfer Order Through UI.
        DummyTransferOrderPage.TransferLines.Quantity.Value(Format(TransferQuantity));
        DummyTransferOrderPage.Close();
    end;

    local procedure OpenTransferOrderPageByNo(TransferOrderNoToFind: Code[20]; TransferOrderToReturn: TestPage "Transfer Order")
    begin
        // Method Opens transfer order page for the transfer order no.
        TransferOrderToReturn.OpenEdit();
        Assert.IsTrue(
          TransferOrderToReturn.GotoKey(TransferOrderNoToFind),
          'Unable to locate transfer order with transfer no');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TransferOrdCalcNetChange()
    var
        SalesHeader: Record "Sales Header";
        ItemJournalLine: Record "Item Journal Line";
        TransferLine: Record "Transfer Line";
        RequisitionLine: Record "Requisition Line";
        ItemNo: array[4] of Code[20];
    begin
        // Setup  : Update Sales Setup. Create Transfer setup.
        Initialize();
        UpdateSalesReceivablesSetup();
        CreateTransferSetup(SalesHeader, ItemNo, true);

        // Create and Post Item Journal Line with Entry Type as Positive Adjustment.
        CreateAndPostItemJrnl(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo[3], LibraryRandom.RandInt(10) + 10);

        // Update Reordering Policy in SKU and Create Transfer Order.
        UpdateReorderingPolicy(LocationCode[4], ItemNo[2]);
        UpdateReorderingPolicy(LocationCode[2], ItemNo[2]);
        CreateTransferOrder(
          TransferLine, LocationCode[4], LocationCode[2], ItemNo[2], CalcDate('<-1Y>', SalesHeader."Order Date"),
          LibraryRandom.RandInt(5));

        // Execute : Create Planning Worksheet and Calculate Net Change Plan.
        CreateReqLine(RequisitionLine);
        CalculateNetChangePlan(RequisitionLine, SalesHeader."Shipment Date", ItemNo);

        // Verify : Verify Seven Requisition Lines Exist in Planning Worksheet.
        // One Item Line for Item4 and Item1 each.Two Item Lines for Item3 and Three Item lines for Item2.
        VerifyNumberOfRequisitionLine(ItemNo, 7);

        // Execute : Carry Out Action Message in Planning Worksheet.
        CarryOutActionMsgPlanSetup(RequisitionLine, ItemNo);

        // Verify : Verify no Requisition Lines Exist in Planning Worksheet after Carry Out Action Message in Requisition Worksheet.
        VerifyNumberOfRequisitionLine(ItemNo, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TransferPurchOrdeCalcNetChange()
    var
        SalesHeader: Record "Sales Header";
        TransferLine: Record "Transfer Line";
        PurchaseHeader: Record "Purchase Header";
        RequisitionLine: Record "Requisition Line";
        ItemNo: array[4] of Code[20];
    begin
        // Setup  : Update Sales Setup. Create Transfer setup.
        Initialize();
        UpdateSalesReceivablesSetup();
        CreateTransferSetup(SalesHeader, ItemNo, false);

        // Create Transfer Order.
        CreateTransferOrder(
          TransferLine, LocationCode[1], LocationCode[4], ItemNo[4], CalcDate('<3D>', WorkDate()), LibraryRandom.RandInt(5));

        // Create and Update Purchase Order for ItemNo2 with LocationCode4.
        CreatePurchaseOrder(PurchaseHeader, ItemNo[2], TransferLine.Quantity);
        UpdatePurchaseLine(PurchaseHeader, LocationCode[3]);

        // Execute : Create Planning Worksheet and Calculate Net Change Plan.
        CreateReqLine(RequisitionLine);
        CalculateNetChangePlan(RequisitionLine, TransferLine."Shipment Date", ItemNo);

        // Verify : Verify 8 req. lines are generated:
        // One Prod. Order for top item.
        // One Prod. Order and one Transfer Order for subassembly.
        // Cancel Purchase for end component, recreate Purchase Order for end component in different location, 2 Transfer Orders to bring the end component at the top item prod. location.
        // One Purchase Order for subassembly end component, at the subassembly prod. location.
        VerifyNumberOfRequisitionLine(ItemNo, 8);
        VerifyReqLineActMessageCancel(ItemNo[2]);

        // Execute : Carry Out Action Message in Planning Worksheet for Order Type Purchase.
        RequisitionLine.SetRange("Ref. Order Type", RequisitionLine."Ref. Order Type"::Purchase);
        RequisitionLine.FindSet();
        CarryOutActionMsgPlanSetup(RequisitionLine, ItemNo);

        // Verify : Verify 5 Requisition Lines are left in Planning Worksheet after purchase order messages have been carried out.
        VerifyNumberOfRequisitionLine(ItemNo, 5);
    end;

    [Test]
    [HandlerFunctions('CarryOutActionMsgPlanHandler')]
    [Scope('OnPrem')]
    procedure PlanningCombineTransfersSplit()
    var
        LocationCode: array[3] of Code[10];
    begin
        // Verify Transfer Orders are combined when planning transfer lines are splitted
        PlanningCombineTransfers(LocationCode, true);

        VerifyTransferOrderCount(LocationCode[1], LocationCode[2], 1);
        VerifyTransferOrderCount(LocationCode[1], LocationCode[3], 1);
    end;

    [Test]
    [HandlerFunctions('CarryOutActionMsgPlanHandler')]
    [Scope('OnPrem')]
    procedure PlanningNotCombineTransfersSplit()
    var
        LocationCode: array[3] of Code[10];
    begin
        // Verify Transfer Orders are not combined when planning transfer lines are splitted
        PlanningCombineTransfers(LocationCode, false);

        VerifyTransferOrderCount(LocationCode[1], LocationCode[2], 2);
        VerifyTransferOrderCount(LocationCode[1], LocationCode[3], 2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TransferChangeTransferTo()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
    begin
        // [FEATURE] [Transfer Order]
        // [SCENARIO] Can Change "Transfer-to Code" for Transfer Order if it contains description line.

        // [GIVEN] Transfer Order with description line.
        Initialize();
        CreateUpdateLocations();
        CreateTransferRoutes();

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationCode[1], LocationCode[4], LocationCode[5]);
        LibraryInventory.CreateTransferLine(
          TransferHeader, TransferLine, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(5));
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, '', 0);

        // [WHEN] Change "Transfer-to Code" in Transfer Header.
        TransferHeader.Validate("Transfer-to Code", LocationCode[2]);

        // [THEN] Transfer Line with description "Transfer-to Code" remains empty.
        TransferLine.TestField("Transfer-to Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferOrdApplyToILE()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TransferLine: Record "Transfer Line";
        TransferHeader: Record "Transfer Header";
    begin
        // [FEATURE] [Transfer] [Cost Application]
        // [SCENARIO] Field "Appl.-to Item Entry" is available for Transfer Order Lines.

        // [GIVEN] Item "I" available on Location "A", stock is positively adjusted by ILE no. "N"
        Initialize();
        CreateUpdateLocations();

        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::Average);
        Item.Modify();

        CreateTransferRoutes();
        CreateAndPostItemJnlWithCostLocationVariant(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandIntInRange(10, 20),
          LibraryRandom.RandIntInRange(10, 20), LocationCode[4], '');

        // [GIVEN] Create Transfer Order for Item "I" from Location "A" to Location "B". Apply to ILE "N".
        CreateTransferOrder(
          TransferLine, LocationCode[4], LocationCode[2], Item."No.", WorkDate(), LibraryRandom.RandInt(5));
        TransferLine.Validate("Appl.-to Item Entry", FindLastILENo(Item."No."));
        TransferLine.Modify();

        // [WHEN] Ship Transfer Order.
        TransferHeader.Get(TransferLine."Document No.");
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);

        // [THEN] Item Application Entry is created to ILE "N".
        VerifyItemApplicationEntry(Item."No.", TransferLine."Appl.-to Item Entry");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferOrdApplyToILECalcCost()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TransferLine: Record "Transfer Line";
        TransferHeader: Record "Transfer Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        LastCost: Decimal;
    begin
        // [FEATURE] [Transfer] [Cost Application] [Adjust Cost Item Entries]
        // [SCENARIO] Average cost Item is not adjusted when used transfer order with fixed application.

        // [GIVEN] Item "I" available on Location "A", stock is positively adjusted by 2 ILE: "1" of cost "X" and "2" of cost "Y"
        Initialize();
        CreateUpdateLocations();

        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::Average);
        Item.Modify();

        CreateTransferRoutes();
        CreateAndPostItemJnlWithCostLocationVariant(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandIntInRange(10, 20),
          LibraryRandom.RandIntInRange(10, 20), LocationCode[4], '');
        LastCost := LibraryRandom.RandIntInRange(30, 40);
        CreateAndPostItemJnlWithCostLocationVariant(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandIntInRange(10, 20),
          LastCost, LocationCode[4], '');

        // [GIVEN] Create Transfer Order for Item "I" from Location "A" to Location "B". Apply to ILE "N".
        CreateTransferOrder(
          TransferLine, LocationCode[4], LocationCode[2], Item."No.", WorkDate(), LibraryRandom.RandInt(5));
        TransferLine.Validate("Appl.-to Item Entry", FindLastILENo(Item."No."));
        TransferLine.Modify();

        // [GIVEN] Post Transfer Order.
        TransferHeader.Get(TransferLine."Document No.");
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        // [WHEN] Adjust Cost - Item Entries
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] Item Entries of Posted Transfer Order have cost "Y" of ILE "2".
        VerifyItemApplicationEntryCost(Item."No.", ItemLedgerEntry."Entry Type"::Transfer, LastCost);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToShipUpdatedManuallyOnNonWMSLocation()
    var
        Location: Record Location;
        WMSLocation: Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferOrder: TestPage "Transfer Order";
        Qty: Decimal;
    begin
        // [FEATURE] [Transfer]
        // [SCENARIO 377487] "Qty. to Ship" in transfer order can be updated when transferring from a non-WMS location and a warehouse receipt exists in the destination location
        Initialize();

        // [GIVEN] Location "L1" without WMS setup
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        // [GIVEN] Location "L2" with warehouse receipt requirement
        LibraryWarehouse.CreateLocationWMS(WMSLocation, false, false, false, true, false);

        Qty := LibraryRandom.RandIntInRange(100, 200);
        CreateItemWithPositiveInventory(Item, Location.Code, Qty * 2);

        // [GIVEN] Create transfer order from "L1" to "L2". Quantity = "Q", set "Qty. to Ship" = "Q" / 2
        CreateTransferOrderNoRoute(TransferHeader, TransferLine, Location.Code, WMSLocation.Code, Item."No.", '', Qty * 2);

        // [GIVEN] Post transfer shipment
        TransferLine.Validate("Qty. to Ship", Qty);
        TransferLine.Modify(true);
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);

        // [GIVEN] Create warehouse receipt on location "L2" from transfer order
        LibraryWarehouse.CreateWhseReceiptFromTO(TransferHeader);

        TransferOrder.OpenEdit();
        TransferOrder.GotoRecord(TransferHeader);
        // [WHEN] Change "Qty. to Ship" in transfer order line
        Qty := LibraryRandom.RandInt(TransferLine."Qty. to Ship" - 1);
        TransferOrder.TransferLines."Qty. to Ship".SetValue(Qty);
        TransferOrder.OK().Invoke();

        // [THEN] New value is accepted
        TransferLine.Find();
        TransferLine.TestField("Qty. to Ship", Qty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToReceiveUpdatedManuallyOnNonWMSLocation()
    var
        Location: Record Location;
        WMSLocation: Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferOrder: TestPage "Transfer Order";
        Qty: Decimal;
    begin
        // [FEATURE] [Transfer]
        // [SCENARIO 377487] "Qty. to Receive" in transfer order can be updated when transferring to a non-WMS location and a warehouse shipment exists in the source location
        Initialize();

        // [GIVEN] Location "L1" with warehouse shipment requirement
        LibraryWarehouse.CreateLocationWMS(WMSLocation, false, false, false, false, true);
        // [GIVEN] Location "L2" without WMS setup
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        Qty := LibraryRandom.RandIntInRange(100, 200);
        CreateItemWithPositiveInventory(Item, WMSLocation.Code, Qty * 2);

        // [GIVEN] Create transfer order from "L1" to "L2". Quantity = "Q"
        CreateTransferOrderNoRoute(TransferHeader, TransferLine, WMSLocation.Code, Location.Code, Item."No.", '', Qty * 2);
        // [GIVEN] Create warehouse shipment from transfer order, set "Qty. to Ship" = "Q" / 2 and post shipment
        CreateAndPostWhseShipmentFromTransferOrder(TransferHeader, Qty);

        TransferOrder.OpenEdit();
        TransferOrder.GotoRecord(TransferHeader);
        // [WHEN] Change "Qty. to Receive" in transfer order line
        Qty := LibraryRandom.RandInt(TransferLine."Quantity Shipped" - 1);
        TransferOrder.TransferLines."Qty. to Receive".SetValue(Qty);
        TransferOrder.OK().Invoke();

        // [THEN] New value is accepted
        TransferLine.Find();
        TransferLine.TestField("Qty. to Receive", Qty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyToShipCannotBeChangedManuallyOnNonWMSLocationForDirectTransferPosting()
    var
        Location: Record Location;
        WMSLocation: Record Location;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        Qty: Decimal;
        ExpectedErrorLbl: Label 'Qty. to Ship must be equal to ''%1''', Comment = '%1: Expected quantity';
    begin
        // [FEATURE] [Transfer]
        // [SCENARIO 377487] Warehouse shipment for direct transfer cannot be posted if "Qty. to Ship" has been changed manually
        Initialize();

        // [GIVEN] Location "L1" with warehouse shipment requirement
        LibraryWarehouse.CreateLocationWMS(WMSLocation, false, false, false, false, true);
        // [GIVEN] Location "L2" without WMS setup
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        EnableDirectTransfersInInventorySetup();

        Qty := LibraryRandom.RandIntInRange(100, 200);
        CreateItemWithPositiveInventory(Item, WMSLocation.Code, Qty * 2);

        // [GIVEN] Create transfer order from "L1" to "L2". Quantity = "Q"
        CreateTransferOrderNoRoute(TransferHeader, TransferLine, WMSLocation.Code, Location.Code, Item."No.", '', Qty * 2);
        TransferHeader.Validate("Direct Transfer", true);
        TransferHeader.Modify();

        // [GIVEN] Create warehouse shipment from transfer order, set "Qty. to Ship" = "Q" / 2
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);

        WarehouseShipmentLine.SetRange("Source Type", DATABASE::"Transfer Line");
        WarehouseShipmentLine.SetRange("Source No.", TransferHeader."No.");
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentLine.Validate("Qty. to Ship", Qty);
        WarehouseShipmentLine.Modify(true);

        // [WHEN] Try to post warehouse shipment
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        asserterror LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [THEN] Error is thrown informing that the quantity must be equal to "Q"
        Assert.ExpectedError(StrSubstNo(ExpectedErrorLbl, Qty * 2));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ChangeTransferLineItemNoAfterPostingError_Post()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: array[2] of Record "Transfer Line";
        TransferOrder: TestPage "Transfer Order";
        NewItemNo: Code[20];
    begin
        // [FEATURE] [Transfer Order]
        // [SCENARIO 378688] TransferLine."Item No." can be changed after posting error ("Post" action)
        Initialize();

        // [GIVEN] Transfer order with two lines: item "A", item "B" (items are not available on stock)
        PrepareSimpleTransferOrderWithTwoLines(TransferHeader, TransferLine);
        // [GIVEN] Try post (ship). An error occurs: "Item "A" is not in inventory."
        TransferOrder.OpenEdit();
        TransferOrder.GotoRecord(TransferHeader);
        asserterror TransferOrder.Post.Invoke();
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(ItemIsNotOnInventoryErr, TransferLine[1]."Item No."));
        // [GIVEN] Enter a new "Item No." into first transfer line: item "C"
        NewItemNo := LibraryInventory.CreateItemNo();
        TransferOrder.TransferLines."Item No.".SetValue(NewItemNo);

        // [WHEN] Move to the second transfer line
        TransferOrder.TransferLines.GotoRecord(TransferLine[2]);

        // [THEN] No error is occurred and first transfer line's "Item No." = "C"
        TransferLine[1].Find();
        Assert.AreEqual(NewItemNo, TransferLine[1]."Item No.", TransferLine[1].FieldCaption("Item No."));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ChangeTransferLineItemNoAfterPostingError_PostAndPrint()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: array[2] of Record "Transfer Line";
        TransferOrder: TestPage "Transfer Order";
        NewItem1No: Code[20];
    begin
        // [FEATURE] [Transfer Order]
        // [SCENARIO 378688] TransferLine."Item No." can be changed after posting error ("Post And Print" action)
        Initialize();

        // [GIVEN] Transfer order with two lines: item "A", item "B" (items are not available on stock)
        PrepareSimpleTransferOrderWithTwoLines(TransferHeader, TransferLine);
        // [GIVEN] Try post (ship). An error occurs: "Item "A" is not in inventory."
        TransferOrder.OpenEdit();
        TransferOrder.GotoRecord(TransferHeader);
        asserterror TransferOrder.PostAndPrint.Invoke();
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(ItemIsNotOnInventoryErr, TransferLine[1]."Item No."));
        // [GIVEN] Enter a new "Item No." into first transfer line: item "C"
        NewItem1No := LibraryInventory.CreateItemNo();
        TransferOrder.TransferLines."Item No.".SetValue(NewItem1No);

        // [WHEN] Move to the second transfer line
        TransferOrder.TransferLines.GotoRecord(TransferLine[2]);

        // [THEN] No error is occurred and first transfer line's "Item No." = "C"
        TransferLine[1].Find();
        Assert.AreEqual(NewItem1No, TransferLine[1]."Item No.", TransferLine[1].FieldCaption("Item No."));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SecondTansferOrderPostAfterPostingError_Post()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: array[2] of Record "Transfer Line";
        TransferOrder: TestPage "Transfer Order";
    begin
        // [FEATURE] [Transfer Order]
        // [SCENARIO 378688] Second "Post" of transfer order gets the same error as the first one: "Item X is not in inventory."
        Initialize();

        // [GIVEN] Transfer order with a new item "X" (not available on stock)
        PrepareSimpleTransferOrderWithTwoLines(TransferHeader, TransferLine);
        // [GIVEN] Try post (ship). An error occurs: "Item "X" is not in inventory."
        TransferOrder.OpenEdit();
        TransferOrder.GotoRecord(TransferHeader);
        asserterror TransferOrder.Post.Invoke();
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(ItemIsNotOnInventoryErr, TransferLine[1]."Item No."));

        // [WHEN] Try post again (ship).
        asserterror TransferOrder.Post.Invoke();

        // [THEN] The same error occurs: "Item "X" is not in inventory."
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(ItemIsNotOnInventoryErr, TransferLine[1]."Item No."));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SecondTansferOrderPostAfterPostingError_PostAndPrint()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: array[2] of Record "Transfer Line";
        TransferOrder: TestPage "Transfer Order";
    begin
        // [FEATURE] [Transfer Order]
        // [SCENARIO 378688] Second "Post And Print" of transfer order gets the same error as the first one: "Item X is not in inventory."
        Initialize();

        // [GIVEN] Transfer order with a new item "X" (not available on stock)
        PrepareSimpleTransferOrderWithTwoLines(TransferHeader, TransferLine);
        // [GIVEN] Try post (ship). An error occurs: "Item "X" is not in inventory."
        TransferOrder.OpenEdit();
        TransferOrder.GotoRecord(TransferHeader);
        asserterror TransferOrder.PostAndPrint.Invoke();
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(ItemIsNotOnInventoryErr, TransferLine[1]."Item No."));

        // [WHEN] Try post again (ship).
        asserterror TransferOrder.PostAndPrint.Invoke();

        // [THEN] The same error occurs: "Item "X" is not in inventory."
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(ItemIsNotOnInventoryErr, TransferLine[1]."Item No."));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SecondTansferOrderPostFromListPageAfterPostingError_Post()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: array[2] of Record "Transfer Line";
        TransferList: TestPage "Transfer Orders";
    begin
        // [FEATURE] [Transfer Order]
        // [SCENARIO 378688] Second "Post" of transfer order (from Transfer List page) gets the same error as the first one: "Item X is not in inventory."
        Initialize();

        // [GIVEN] Transfer order with a new item "X" (not available on stock)
        PrepareSimpleTransferOrderWithTwoLines(TransferHeader, TransferLine);
        // [GIVEN] Try post (ship) from "Transfer List" page. An error occurs: "Item "X" is not in inventory."
        TransferList.OpenEdit();
        TransferList.GotoRecord(TransferHeader);
        asserterror TransferList.Post.Invoke();
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(ItemIsNotOnInventoryErr, TransferLine[1]."Item No."));

        // [WHEN] Try post again (ship).
        asserterror TransferList.Post.Invoke();

        // [THEN] The same error occurs: "Item "X" is not in inventory."
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(ItemIsNotOnInventoryErr, TransferLine[1]."Item No."));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure SecondTansferOrderPostFromListPageAfterPostingError_PostAndPrint()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: array[2] of Record "Transfer Line";
        TransferList: TestPage "Transfer Orders";
    begin
        // [FEATURE] [Transfer Order]
        // [SCENARIO 378688] Second "Post And Print" of transfer order (from Transfer List page) gets the same error as the first one: "Item X is not in inventory."
        Initialize();

        // [GIVEN] Transfer order with a new item "X" (not available on stock)
        PrepareSimpleTransferOrderWithTwoLines(TransferHeader, TransferLine);
        // [GIVEN] Try post (ship) from "Transfer List" page. An error occurs: "Item "X" is not in inventory."
        TransferList.OpenEdit();
        TransferList.GotoRecord(TransferHeader);
        asserterror TransferList.PostAndPrint.Invoke();
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(ItemIsNotOnInventoryErr, TransferLine[1]."Item No."));

        // [WHEN] Try post again (ship).
        asserterror TransferList.PostAndPrint.Invoke();

        // [THEN] The same error occurs: "Item "X" is not in inventory."
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(ItemIsNotOnInventoryErr, TransferLine[1]."Item No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerForTransferHeaderDimUpdate')]
    [Scope('OnPrem')]
    procedure PartlyShippedLineDimChangeFromHeaderGlobalDimConfirmYes()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        DimensionValue: Record "Dimension Value";
    begin
        // [FEATURE] [Transfer] [Dimension] [Partial Posting]
        // [SCENARIO 378707] Shortcut Dimension 1 Code on Transfer Line is updated after the change of dimension value is confirmed on Transfer Header.
        Initialize();

        // [GIVEN] Transfer Order with partly shipped line
        CreatePartlyShipTransferOrder(TransferHeader, TransferLine);
        CreateGlobal1DimensionValue(DimensionValue);

        // [GIVEN] Transfer Header Shortcut Dimension 1 Code is being changed to "NewDimValue"
        // [GIVEN] Answer Yes to confirm lines dimension update (first confirmation)
        LibraryVariableStorage.Enqueue(true); // to reply Yes on second confirmation
        TransferHeader.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);

        // [WHEN] Answer Yes on shipped line update confirmation
        // The reply is inside the handler ConfirmHandlerForTransferHeaderDimUpdate

        // [THEN] Transfer Line dimension set contains "NewDimValue"
        TransferLine.GetBySystemId(TransferLine.SystemId);
        VerifyDimensionOnDimSet(TransferLine."Dimension Set ID", DimensionValue);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerForTransferHeaderDimUpdate')]
    [Scope('OnPrem')]
    procedure PartlyShippedLineDimChangeFromHeaderGlobalDimConfirmNo()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        DimensionValue: Record "Dimension Value";
        SavedDimSetID: Integer;
    begin
        // [FEATURE] [Transfer] [Dimension] [Partial Posting]
        // [SCENARIO 378707] Shortcut Dimension 1 Code on Transfer Line is not updated if the change of dimension value is not confirmed on Transfer Header.
        Initialize();

        // [GIVEN] Transfer Order with partly shipped line
        CreatePartlyShipTransferOrder(TransferHeader, TransferLine);
        SavedDimSetID := TransferLine."Dimension Set ID";
        CreateGlobal1DimensionValue(DimensionValue);

        // [GIVEN] Transfer Header Shortcut Dimension 1 Code is being changed to "NewDimValue"
        // [GIVEN] Answer Yes to confirm lines dimension update (first confirmation)
        LibraryVariableStorage.Enqueue(false); // to reply No on second confirmation
        asserterror TransferHeader.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);

        // [WHEN] Answer Yes on shipped line update confirmation
        // The reply is inside the handler ConfirmHandlerForTransferHeaderDimUpdate

        // [THEN] Transfer Line dimension set contains "NewDimValue"
        TransferLine.Find();
        TransferLine.TestField("Dimension Set ID", SavedDimSetID);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerForTransferHeaderDimUpdate,EditDimensionSetEntriesHandler')]
    [Scope('OnPrem')]
    procedure PartlyShippedLineDimChangeFromHeaderDimSetPageConfirmYes()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        DimensionValue: Record "Dimension Value";
        TransferOrder: TestPage "Transfer Order";
    begin
        // [FEATURE] [Transfer] [Dimension] [Partial Posting]
        // [SCENARIO 378707] Shortcut Dimension 1 Code on Transfer Line is updated after the change of dimension value is confirmed on Transfer Order page.
        Initialize();

        // [GIVEN] Transfer Order with partly shipped line
        CreatePartlyShipTransferOrder(TransferHeader, TransferLine);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);

        // [GIVEN] Transfer Header Shortcut Dimension 1 Code is being changed to "NewDimValue"
        // [GIVEN] Answer Yes to confirm lines dimension update (first confirmation)
        LibraryVariableStorage.Enqueue(DimensionValue."Dimension Code");
        LibraryVariableStorage.Enqueue(DimensionValue.Code);
        LibraryVariableStorage.Enqueue(true); // to reply Yes on second confirmation
        TransferOrder.OpenEdit();
        TransferOrder.FILTER.SetFilter("No.", TransferHeader."No.");
        TransferOrder.Dimensions.Invoke();

        // [WHEN] Answer Yes on shipped line update confirmation
        // The reply is inside the handler ConfirmHandlerForTransferHeaderDimUpdate

        // [THEN] Transfer Line dimension set contains "NewDimValue"
        TransferLine.GetBySystemId(TransferLine.SystemId);
        VerifyDimensionOnDimSet(TransferLine."Dimension Set ID", DimensionValue);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerForTransferHeaderDimUpdate,EditDimensionSetEntriesHandler')]
    [Scope('OnPrem')]
    procedure PartlyShippedLineDimChangeFromHeaderDimSetPageConfirmNo()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        DimensionValue: Record "Dimension Value";
        TransferOrder: TestPage "Transfer Order";
        SavedDimSetID: Integer;
    begin
        // [FEATURE] [Transfer] [Dimension] [Partial Posting]
        // [SCENARIO 378707] Shortcut Dimension 1 Code on Transfer Line is not updated if the change of dimension value is not confirmed on Transfer Order page.
        Initialize();

        // [GIVEN] Transfer Order with partly shipped line
        CreatePartlyShipTransferOrder(TransferHeader, TransferLine);
        SavedDimSetID := TransferLine."Dimension Set ID";
        LibraryDimension.CreateDimWithDimValue(DimensionValue);

        // [GIVEN] Transfer Header Shortcut Dimension 1 Code is being changed to "NewDimValue"
        // [GIVEN] Answer Yes to confirm lines dimension update (first confirmation)
        LibraryVariableStorage.Enqueue(DimensionValue."Dimension Code");
        LibraryVariableStorage.Enqueue(DimensionValue.Code);
        LibraryVariableStorage.Enqueue(false); // to reply No on second confirmation
        TransferOrder.OpenEdit();
        TransferOrder.FILTER.SetFilter("No.", TransferHeader."No.");
        asserterror TransferOrder.Dimensions.Invoke();

        // [WHEN] Answer Yes on shipped line update confirmation
        // The reply is inside the handler ConfirmHandlerForTransferHeaderDimUpdate

        // [THEN] Transfer Line dimension set contains "NewDimValue"
        TransferLine.Find();
        TransferLine.TestField("Dimension Set ID", SavedDimSetID);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PartlyShippedLineDimChangeFromLineGlobalDimConfirmYes()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        DimensionValue: Record "Dimension Value";
    begin
        // [FEATURE] [Transfer] [Dimension] [Partial Posting]
        // [SCENARIO 378707] Shortcut Dimension 1 Code on Transfer Line is updated after the change of dimension value is confirmed.
        Initialize();

        // [GIVEN] Transfer Order with partly shipped line
        CreatePartlyShipTransferOrder(TransferHeader, TransferLine);
        CreateGlobal1DimensionValue(DimensionValue);

        // [GIVEN] Transfer Header Shortcut Dimension 1 Code is being changed to "NewDimValue"
        LibraryVariableStorage.Enqueue(true); // to reply Yes on second confirmation
        TransferLine.Find();
        TransferLine.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);

        // [WHEN] Answer Yes on shipped line update confirmation

        // [THEN] Transfer Line dimension set contains "NewDimValue"
        VerifyDimensionOnDimSet(TransferLine."Dimension Set ID", DimensionValue);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure PartlyShippedLineDimChangeFromLineGlobalDimConfirmNo()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        DimensionValue: Record "Dimension Value";
        SavedDimSetID: Integer;
    begin
        // [FEATURE] [Transfer] [Dimension] [Partial Posting]
        // [SCENARIO 378707] Shortcut Dimension 1 Code on Transfer Line is not updated if the change of dimension value is not confirmed.
        Initialize();

        // [GIVEN] Transfer Order with partly shipped line
        CreatePartlyShipTransferOrder(TransferHeader, TransferLine);
        SavedDimSetID := TransferLine."Dimension Set ID";
        CreateGlobal1DimensionValue(DimensionValue);

        // [GIVEN] Transfer Header Shortcut Dimension 1 Code is being changed to "NewDimValue"
        TransferLine.Find();
        asserterror TransferLine.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);

        // [WHEN] Answer Yes on shipped line update confirmation

        // [THEN] Transfer Line dimension set contains "NewDimValue"
        TransferLine.TestField("Dimension Set ID", SavedDimSetID);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,EditDimensionSetEntriesHandler')]
    [Scope('OnPrem')]
    procedure PartlyShippedLineDimChangeFromLineDimSetPageConfirmYes()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        DimensionValue: Record "Dimension Value";
        TransferOrder: TestPage "Transfer Order";
    begin
        // [FEATURE] [Transfer] [Dimension] [Partial Posting]
        // [SCENARIO 378707] Shortcut Dimension 1 Code on Transfer Line is updated after the change of dimension value is confirmed on Transfer Order subpage.
        Initialize();

        // [GIVEN] Transfer Order with partly shipped line
        CreatePartlyShipTransferOrder(TransferHeader, TransferLine);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);

        // [GIVEN] Transfer Header Shortcut Dimension 1 Code is being changed to "NewDimValue"
        LibraryVariableStorage.Enqueue(DimensionValue."Dimension Code");
        LibraryVariableStorage.Enqueue(DimensionValue.Code);
        TransferOrder.OpenEdit();
        TransferOrder.FILTER.SetFilter("No.", TransferHeader."No.");
        TransferOrder.TransferLines.Dimensions.Invoke();

        // [WHEN] Answer Yes on shipped line update confirmation

        // [THEN] Transfer Line dimension set contains "NewDimValue"
        TransferLine.GetBySystemId(TransferLine.SystemId);
        VerifyDimensionOnDimSet(TransferLine."Dimension Set ID", DimensionValue);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo,EditDimensionSetEntriesHandler')]
    [Scope('OnPrem')]
    procedure PartlyShippedLineDimChangeFromLineDimSetPageConfirmNo()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        DimensionValue: Record "Dimension Value";
        TransferOrder: TestPage "Transfer Order";
        SavedDimSetID: Integer;
    begin
        // [FEATURE] [Transfer] [Dimension] [Partial Posting]
        // [SCENARIO 378707] Shortcut Dimension 1 Code on Transfer Line is not updated if the change of dimension value is not confirmed on Transfer Order subpage.
        Initialize();

        // [GIVEN] Transfer Order with partly shipped line
        CreatePartlyShipTransferOrder(TransferHeader, TransferLine);
        SavedDimSetID := TransferLine."Dimension Set ID";
        LibraryDimension.CreateDimWithDimValue(DimensionValue);

        // [GIVEN] Transfer Header Shortcut Dimension 1 Code is being changed to "NewDimValue"
        LibraryVariableStorage.Enqueue(DimensionValue."Dimension Code");
        LibraryVariableStorage.Enqueue(DimensionValue.Code);
        TransferOrder.OpenEdit();
        TransferOrder.FILTER.SetFilter("No.", TransferHeader."No.");
        asserterror TransferOrder.TransferLines.Dimensions.Invoke();

        // [WHEN] Answer Yes on shipped line update confirmation

        // [THEN] Transfer Line dimension set contains "NewDimValue"
        TransferLine.Find();
        TransferLine.TestField("Dimension Set ID", SavedDimSetID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequireReceiveCreatesInbdWhseRequestForShippedTransfer()
    var
        Location: Record Location;
        TransferHeader: array[2] of Record "Transfer Header";
        WarehouseRequest: Record "Warehouse Request";
    begin
        // [FEATURE] [Warehouse Request] [Warehouse Receipt]
        // [SCENARIO 381426] Warehouse Request is created for shipped not received Transfer Order when "Require Receipt" is set on destination Location. The status of the Whse. Request matches the status of the Transfer Order.
        Initialize();

        // [GIVEN] Item with inventory on Location "L1".
        // [GIVEN] Two partially shipped not received Transfer Orders "T1", "T2" from "L1" to Location "L2".
        CreateTwoPartlyShipTransferOrders(TransferHeader, true);

        // [GIVEN] "T2" is re-opened.
        LibraryWarehouse.ReopenTransferOrder(TransferHeader[2]);

        // [WHEN] Turn on "Require Receipt" on "L2".
        Location.Get(TransferHeader[1]."Transfer-to Code");
        Location.Validate("Require Receive", true);

        // [THEN] Warehouse Request with "Released" status is created for "T1".
        WarehouseRequest.Get(
          WarehouseRequest.Type::Inbound, Location.Code, DATABASE::"Transfer Line", 1, TransferHeader[1]."No.");
        WarehouseRequest.TestField("Document Status", TransferHeader[1].Status::Released);

        // [THEN] Warehouse Request with "Open" status is created for "T2".
        WarehouseRequest.Get(
          WarehouseRequest.Type::Inbound, Location.Code, DATABASE::"Transfer Line", 1, TransferHeader[2]."No.");
        WarehouseRequest.TestField("Document Status", TransferHeader[2].Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequirePutAwayCreatesInbdWhseRequestForShippedTransfer()
    var
        Location: Record Location;
        TransferHeader: array[2] of Record "Transfer Header";
        WarehouseRequest: Record "Warehouse Request";
    begin
        // [FEATURE] [Warehouse Request] [Inventory Put-away]
        // [SCENARIO 381426] Warehouse Request is created for shipped not received Transfer Order when "Require Put-away" is set on destination Location. The status of the Whse. Request matches the status of the Transfer Order.
        Initialize();

        // [GIVEN] Item with inventory on Location "L1".
        // [GIVEN] Two partially shipped not received Transfer Orders "T1", "T2" from "L1" to Location "L2".
        CreateTwoPartlyShipTransferOrders(TransferHeader, true);

        // [GIVEN] "T2" is re-opened.
        LibraryWarehouse.ReopenTransferOrder(TransferHeader[2]);

        // [WHEN] Turn on "Require Put-away" on "L2".
        Location.Get(TransferHeader[1]."Transfer-to Code");
        Location.Validate("Require Put-away", true);
        Location.Validate("Always Create Put-away Line", true);

        // [THEN] Warehouse Request with "Released" status is created for "T1".
        WarehouseRequest.Get(
          WarehouseRequest.Type::Inbound, Location.Code, DATABASE::"Transfer Line", 1, TransferHeader[1]."No.");
        WarehouseRequest.TestField("Document Status", TransferHeader[1].Status::Released);

        // [THEN] Warehouse Request with "Open" status is created for "T2".
        WarehouseRequest.Get(
          WarehouseRequest.Type::Inbound, Location.Code, DATABASE::"Transfer Line", 1, TransferHeader[2]."No.");
        WarehouseRequest.TestField("Document Status", TransferHeader[2].Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequireReceiveDoesNotCreateInbdWhseRequestForNotStartedTransfer()
    var
        Location: Record Location;
        TransferHeader: array[2] of Record "Transfer Header";
        WarehouseRequest: Record "Warehouse Request";
    begin
        // [FEATURE] [Warehouse Request]
        // [SCENARIO 381426] No Warehouse Request is created for not shipped Transfer Order when "Require Receipt" is set on destination Location.
        Initialize();

        // [GIVEN] Item with inventory on Location "L1".
        // [GIVEN] Not shipped Transfer Order "T" from "L1" to Location "L2".
        CreateTwoPartlyShipTransferOrders(TransferHeader, false);

        // [WHEN] Turn on "Require Receipt" on "L2".
        Location.Get(TransferHeader[1]."Transfer-to Code");
        Location.Validate("Require Receive", true);

        // [THEN] No Warehouse Request is created.
        WarehouseRequest.Init();
        WarehouseRequest.SetRange("Location Code", Location.Code);
        Assert.RecordIsEmpty(WarehouseRequest);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferCanBeReceivedWithNoWhseHandlingWhenRequireReceiptTurnedOnAndOff()
    var
        Location: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferReceiptHeader: Record "Transfer Receipt Header";
    begin
        // [FEATURE] [Warehouse Request]
        // [SCENARIO 381426] Transfer Order can be received with no warehouse handling when "Require Receipt" is turned on and then off on destination Location.
        Initialize();

        // [GIVEN] Item with inventory on Location "L1".
        // [GIVEN] Partly shipped Transfer Order "T" from "L1" to Location "L2".
        CreatePartlyShipTransferOrder(TransferHeader, TransferLine);

        // [GIVEN] "Require Receipt" on "L2" is turned on. This created Warehouse Request.
        Location.Get(TransferHeader."Transfer-to Code");
        Location.Validate("Require Receive", true);
        Location.Modify(true);

        // [GIVEN] "Require Receipt" on "L2" is turned off.
        Location.Validate("Require Receive", false);
        Location.Modify(true);

        // [WHEN] Post "T" with Receive option.
        LibraryWarehouse.PostTransferOrder(TransferHeader, false, true);

        // [THEN] Transfer Receipt to "L2" is posted.
        TransferReceiptHeader.Init();
        TransferReceiptHeader.SetRange("Transfer-to Code", Location.Code);
        Assert.RecordIsNotEmpty(TransferReceiptHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferOrderSubpageUpdatedAfterShipmentDateUpdatedOnHeader()
    var
        TransferOrder: TestPage "Transfer Order";
        ShipmentDateOnHeader: Date;
        ShipmentDateOnLine: Date;
    begin
        // [SCENARIO 380067] Shipment Date on Transfer Order subpage is updated after Shipment Date on the header page is updated directly.
        Initialize();
        UpdateSalesReceivablesSetup();

        // [GIVEN] Transfer Order with a new line on the subpage.
        CreateTransferOrderAndInitializeNewTransferLine(TransferOrder, '');

        // [WHEN] Update Shipment Date on Transfer Order header page.
        TransferOrder."Shipment Date".SetValue(LibraryRandom.RandDate(10));

        // [THEN] Shipment Date on the subpage is updated and becomes equal to Shipment Date on the header page.
        Evaluate(ShipmentDateOnHeader, TransferOrder."Shipment Date".Value);
        Evaluate(ShipmentDateOnLine, TransferOrder.TransferLines."Shipment Date".Value);
        Assert.AreEqual(ShipmentDateOnHeader, ShipmentDateOnLine, TransferOrderSubpageNotUpdatedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferOrderSubpageUpdatedAfterShippingTimeUpdatedOnHeader()
    var
        ShippingTime: DateFormula;
        TransferOrder: TestPage "Transfer Order";
        DateFormulaTok: Label '<%1D>', Comment = '%1 = Number of days';
    begin
        // [SCENARIO 380067] Receipt Date on Transfer Order subpage is updated after Receipt Date on the header page is updated through new Shipping Time.
        Initialize();
        UpdateSalesReceivablesSetup();

        // [GIVEN] Transfer Order with a new line on the subpage.
        CreateTransferOrderAndInitializeNewTransferLine(TransferOrder, '');

        // [WHEN] Update Shipping Time on Transfer Order header page.
        Evaluate(ShippingTime, StrSubstNo(DateFormulaTok, LibraryRandom.RandInt(10)));
        TransferOrder."Shipping Time".SetValue(ShippingTime);

        // [THEN] Receipt Date on the subpage is updated and becomes equal to Receipt Date on the header page.
        VerifyTransferReceiptDate(TransferOrder);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferOrderSubpageUpdatedAfterReceiptDateUpdatedOnHeader()
    var
        TransferOrder: TestPage "Transfer Order";
    begin
        // [SCENARIO 380067] Receipt Date on Transfer Order subpage is updated after Receipt Date on the header page is updated directly.
        Initialize();
        UpdateSalesReceivablesSetup();

        // [GIVEN] Transfer Order with a new line on the subpage.
        CreateTransferOrderAndInitializeNewTransferLine(TransferOrder, '');

        // [WHEN] Update Receipt Date on Transfer Order header page.
        TransferOrder."Receipt Date".SetValue(LibraryRandom.RandDate(10));

        // [THEN] Receipt Date on the subpage is updated and becomes equal to Receipt Date on the header page.
        VerifyTransferReceiptDate(TransferOrder);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferOrderSubpageUpdatedAfterOutboundWhseTimeUpdatedOnHeader()
    var
        OutboundWhseHandlingTime: DateFormula;
        TransferOrder: TestPage "Transfer Order";
        DateFormulaTok: Label '<%1D>', Comment = '%1 = Number of days';
    begin
        // [SCENARIO 380067] Receipt Date on Transfer Order subpage is updated after Receipt Date on the header page is updated through new Outbound Whse. Handling Time.
        Initialize();
        UpdateSalesReceivablesSetup();

        // [GIVEN] Transfer Order with a new line on the subpage.
        CreateTransferOrderAndInitializeNewTransferLine(TransferOrder, '');

        // [WHEN] Update Outbound Whse. Handling Time on Transfer Order header page.
        Evaluate(OutboundWhseHandlingTime, StrSubstNo(DateFormulaTok, LibraryRandom.RandInt(10)));
        TransferOrder."Outbound Whse. Handling Time".SetValue(OutboundWhseHandlingTime);

        // [THEN] Receipt Date on the subpage is updated and becomes equal to Receipt Date on the header page.
        VerifyTransferReceiptDate(TransferOrder);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferOrderSubpageUpdatedAfterInboundWhseTimeUpdatedOnHeader()
    var
        InboundWhseHandlingTime: DateFormula;
        TransferOrder: TestPage "Transfer Order";
        DateFormulaTok: Label '<%1D>', Comment = '%1 = Number of days';
    begin
        // [SCENARIO 380067] Receipt Date on Transfer Order subpage is updated after Receipt Date on the header page is updated through new Inbound Whse. Handling Time.
        Initialize();
        UpdateSalesReceivablesSetup();

        // [GIVEN] Transfer Order with a new line on the subpage.
        CreateTransferOrderAndInitializeNewTransferLine(TransferOrder, '');

        // [WHEN] Update Inbound Whse. Handling Time on Transfer Order header page.
        Evaluate(InboundWhseHandlingTime, StrSubstNo(DateFormulaTok, LibraryRandom.RandInt(10)));
        TransferOrder."Inbound Whse. Handling Time".SetValue(InboundWhseHandlingTime);

        // [THEN] Receipt Date on the subpage is updated and becomes equal to Receipt Date on the header page.
        VerifyTransferReceiptDate(TransferOrder);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferOrderSubpageUpdatedAfterShippingAgentUpdatedOnHeader()
    var
        TransferOrder: TestPage "Transfer Order";
        ShippingAgentCode: Code[10];
        ShippingAgentServiceCode: Code[10];
    begin
        // [SCENARIO 380067] Receipt Date on Transfer Order subpage is updated after Receipt Date on the header page is updated through new Shipping Agent Code.
        Initialize();
        UpdateSalesReceivablesSetup();

        // [GIVEN] Shipping Agent with Shipping Agent Service.
        CreateShippingAgentCodeAndService(ShippingAgentCode, ShippingAgentServiceCode);

        // [GIVEN] Transfer Order with a new line on the subpage.
        CreateTransferOrderAndInitializeNewTransferLine(TransferOrder, '');

        // [WHEN] Update Shipping Agent Code on Transfer Order header page.
        TransferOrder."Shipping Agent Code".SetValue(ShippingAgentCode);

        // [THEN] Receipt Date on the subpage is updated and becomes equal to Receipt Date on the header page.
        VerifyTransferReceiptDate(TransferOrder);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferOrderSubpageUpdatedAfterShippingAgentServiceUpdatedOnHeader()
    var
        TransferOrder: TestPage "Transfer Order";
        ShippingAgentCode: Code[10];
        ShippingAgentServiceCode: Code[10];
    begin
        // [SCENARIO 380067] Receipt Date on Transfer Order subpage is updated after Receipt Date on the header page is updated through new Shipping Agent Service Code.
        Initialize();
        UpdateSalesReceivablesSetup();

        // [GIVEN] Shipping Agent with Shipping Agent Service.
        CreateShippingAgentCodeAndService(ShippingAgentCode, ShippingAgentServiceCode);

        // [GIVEN] Transfer Order with Shipping Agent and a new line on the subpage.
        CreateTransferOrderAndInitializeNewTransferLine(TransferOrder, ShippingAgentCode);

        // [WHEN] Update Shipping Agent Service Code on Transfer Order header page.
        TransferOrder."Shipping Agent Service Code".SetValue(ShippingAgentServiceCode);

        // [THEN] Receipt Date on the subpage is updated and becomes equal to Receipt Date on the header page.
        VerifyTransferReceiptDate(TransferOrder);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExistedInbdRequestForTransferIsUpdated()
    var
        TransferHeader: Record "Transfer Header";
        WarehouseRequest: Record "Warehouse Request";
        WhseTransferRelease: Codeunit "Whse.-Transfer Release";
    begin
        // [FEATURE] [Warehouse Request] [UT]
        // [SCENARIO 381426] Existed inbound warehouse request is updated when CreateInboundWhseRequest function in Codeunit 5773 is called.
        Initialize();

        // [GIVEN] Transfer Order "T".
        MockTransferOrder(TransferHeader);

        // [GIVEN] Inbound warehouse request for "T".
        MockWhseRequest(WarehouseRequest.Type::Inbound, TransferHeader."Transfer-to Code", TransferHeader."No.");

        // [WHEN] Create inbound warehouse request for "T".
        WhseTransferRelease.InitializeWhseRequest(WarehouseRequest, TransferHeader, TransferHeader.Status);
        WhseTransferRelease.CreateInboundWhseRequest(WarehouseRequest, TransferHeader);

        // [THEN] Existed inbound warehouse request for "T" is updated.
        TransferHeader.CalcFields("Completely Received");
        FilterWhseRequest(
          WarehouseRequest, WarehouseRequest.Type::Inbound, TransferHeader."Transfer-to Code", 1, TransferHeader."No.");
        WarehouseRequest.FindFirst();
        VerifyWhseRequest(
          WarehouseRequest, TransferHeader, SourceDocument::"Inb. Transfer", TransferHeader."Completely Received",
          WarehouseRequest."Shipment Date", TransferHeader."Receipt Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewInbdRequestIsNotCreatedWhenCalledFromTransferOrder()
    var
        TransferHeader: Record "Transfer Header";
        WarehouseRequest: Record "Warehouse Request";
        WhseTransferRelease: Codeunit "Whse.-Transfer Release";
    begin
        // [FEATURE] [Warehouse Request] [UT]
        // [SCENARIO 381426] New inbound warehouse request is not created when CreateInboundWhseRequest function in Codeunit 5773 is called from Transfer Order.
        Initialize();

        // [GIVEN] Transfer Order "T".
        MockTransferOrder(TransferHeader);

        // [GIVEN] No inbound warehouse requests exist for "T".
        // [GIVEN] Creation of warehouse request is set to be invoked from the transfer order ("Release" button clicked on page).
        WhseTransferRelease.SetCallFromTransferOrder(true);

        // [WHEN] Create inbound warehouse request for "T".
        WhseTransferRelease.InitializeWhseRequest(WarehouseRequest, TransferHeader, TransferHeader.Status);
        WhseTransferRelease.CreateInboundWhseRequest(WarehouseRequest, TransferHeader);

        // [THEN] Inbound warehouse request for "T" is not created.
        FilterWhseRequest(
          WarehouseRequest, WarehouseRequest.Type::Inbound, TransferHeader."Transfer-to Code", 1, TransferHeader."No.");
        Assert.RecordIsEmpty(WarehouseRequest);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewInbdRequestForTransferIsCreatedWhenCalledIndirectly()
    var
        TransferHeader: Record "Transfer Header";
        WarehouseRequest: Record "Warehouse Request";
        WhseTransferRelease: Codeunit "Whse.-Transfer Release";
    begin
        // [FEATURE] [Warehouse Request] [UT]
        // [SCENARIO 381426] New inbound warehouse request is created when CreateInboundWhseRequest function in Codeunit 5773 is called indirectly if inbound request does not exist.
        Initialize();

        // [GIVEN] Transfer Order "T".
        MockTransferOrder(TransferHeader);

        // [GIVEN] No inbound warehouse requests exist for "T".
        // [GIVEN] Creation of warehouse request is set to be invoked not from the transfer order (i.e. on posting the transfer shipment).
        WhseTransferRelease.SetCallFromTransferOrder(false);

        // [WHEN] Create inbound warehouse request for "T".
        WhseTransferRelease.InitializeWhseRequest(WarehouseRequest, TransferHeader, TransferHeader.Status);
        WhseTransferRelease.CreateInboundWhseRequest(WarehouseRequest, TransferHeader);

        // [THEN] New inbound warehouse request for "T" is created.
        TransferHeader.CalcFields("Completely Received");
        FilterWhseRequest(
          WarehouseRequest, WarehouseRequest.Type::Inbound, TransferHeader."Transfer-to Code", 1, TransferHeader."No.");
        WarehouseRequest.FindFirst();
        VerifyWhseRequest(
          WarehouseRequest, TransferHeader, SourceDocument::"Inb. Transfer", TransferHeader."Completely Received",
          0D, TransferHeader."Receipt Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExistedOutbdRequestForTransferUpdated()
    var
        TransferHeader: Record "Transfer Header";
        WarehouseRequest: Record "Warehouse Request";
        WhseTransferRelease: Codeunit "Whse.-Transfer Release";
    begin
        // [FEATURE] [Warehouse Request] [UT]
        // [SCENARIO 381426] Existed outbound warehouse request is updated when CreateOutboundWhseRequest function in Codeunit 5773 is called.
        Initialize();

        // [GIVEN] Transfer Order "T".
        MockTransferOrder(TransferHeader);

        // [GIVEN] Outbound warehouse request for "T".
        MockWhseRequest(WarehouseRequest.Type::Outbound, TransferHeader."Transfer-from Code", TransferHeader."No.");

        // [WHEN] Create outbound warehouse request for "T".
        WhseTransferRelease.InitializeWhseRequest(WarehouseRequest, TransferHeader, TransferHeader.Status);
        WhseTransferRelease.CreateOutboundWhseRequest(WarehouseRequest, TransferHeader);

        // [THEN] Existed outbound warehouse request for "T" is updated.
        TransferHeader.CalcFields("Completely Shipped");
        FilterWhseRequest(
          WarehouseRequest, WarehouseRequest.Type::Outbound, TransferHeader."Transfer-from Code", 0, TransferHeader."No.");
        WarehouseRequest.FindFirst();
        VerifyWhseRequest(
          WarehouseRequest, TransferHeader, SourceDocument::"Outb. Transfer", TransferHeader."Completely Shipped",
          WarehouseRequest."Shipment Date", WarehouseRequest."Expected Receipt Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewOutbdRequestForTransferCreated()
    var
        TransferHeader: Record "Transfer Header";
        WarehouseRequest: Record "Warehouse Request";
        WhseTransferRelease: Codeunit "Whse.-Transfer Release";
    begin
        // [FEATURE] [Warehouse Request] [UT]
        // [SCENARIO 381426] New outbound warehouse request is created when CreateOutboundWhseRequest function in Codeunit 5773 is called if outbound request does not exist.
        Initialize();

        // [GIVEN] Transfer Order "T".
        MockTransferOrder(TransferHeader);

        // [GIVEN] No outbound warehouse requests exist for "T".

        // [WHEN] Create outbound warehouse request for "T".
        WhseTransferRelease.InitializeWhseRequest(WarehouseRequest, TransferHeader, TransferHeader.Status);
        WhseTransferRelease.CreateOutboundWhseRequest(WarehouseRequest, TransferHeader);

        // [THEN] New outbound warehouse request for "T" is created.
        TransferHeader.CalcFields("Completely Shipped");
        FilterWhseRequest(
          WarehouseRequest, WarehouseRequest.Type::Outbound, TransferHeader."Transfer-from Code", 0, TransferHeader."No.");
        WarehouseRequest.FindFirst();
        VerifyWhseRequest(
          WarehouseRequest, TransferHeader, SourceDocument::"Outb. Transfer", TransferHeader."Completely Shipped",
          WarehouseRequest."Shipment Date", 0D);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewWhseReceiptForTransferAfterAdditionalQtyShippedAndReceived()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        ItemJournalLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        QtyInUOM: Integer;
    begin
        // [FEATURE] [Warehouse Receipt]
        // [SCENARIO 235005] New warehouse receipt for transfer order includes only additional quantity shipped after existing warehouse receipts were created.
        Initialize();

        // [GIVEN] Location "L1" and "L2". "L2" is set up for required receipt.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationFrom);
        LibraryWarehouse.CreateLocationWMS(LocationTo, false, false, false, true, false);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);

        // [GIVEN] Item "I" with base unit of measure "PC" and alternate unit of measure "BOX". 1 "BOX" = 5 "PC".
        QtyInUOM := LibraryRandom.RandIntInRange(2, 5);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", QtyInUOM);

        // [GIVEN] 10 "BOX" of the item are in the inventory at location "L1".
        CreateAndPostItemJnlWithCostLocationVariant(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 10 * QtyInUOM, LibraryRandom.RandDec(10, 2), LocationFrom.Code, '');

        // [GIVEN] Transfer order for 10 "BOX" from location "L1" to location "L2".
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 10);
        TransferLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);

        // [GIVEN] Partially ship the transfer order. Shipped quantity = 5 "BOX".
        UpdatePartialQuantityToShip(TransferLine, 5);
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);

        // [GIVEN] Warehouse receipt "R1" at location "L2".
        // [GIVEN] Set "Qty. to Receive" = 2 "BOX" and post the receipt.
        CreateAndPostWhseReceiptFromTransferOrder(TransferHeader, 2);

        // [GIVEN] Post another partial shipment of the transfer. Shipped quantity = 3 "BOX".
        // [GIVEN] Now we have 8 "BOX" shipped and 2 "BOX" received, that is 6 "BOX" still in transit.
        // [GIVEN] 3 "BOX" out of 6 are to be posted by "R1".
        TransferLine.Find();
        UpdatePartialQuantityToShip(TransferLine, 3);
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);

        // [WHEN] Create another warehouse receipt "R2".
        LibraryWarehouse.CreateWhseReceiptFromTO(TransferHeader);

        // [THEN] Quantity on the warehouse receipt "R2" is equal to 5 "BOX" (6 "BOX" in transit + 2 "BOX" received - 3 "BOX" outstanding in "R1").
        // [THEN] "Qty. (Base)" = 25 "PC" (5 "PC" in each "BOX").
        FilterWhseReceiptLine(WarehouseReceiptLine, DATABASE::"Transfer Line", TransferHeader."No.");
        WarehouseReceiptLine.FindLast();
        WarehouseReceiptLine.TestField(Quantity, 5);
        WarehouseReceiptLine.TestField("Qty. (Base)", 5 * QtyInUOM);

        // [THEN] "Qty. to Receive" = 3 "BOX" (2 "BOX" were received by "R1").
        // [THEN] "Qty. to Receive (Base)" = 15 "PC".
        WarehouseReceiptLine.TestField("Qty. to Receive", 3);
        WarehouseReceiptLine.TestField("Qty. to Receive (Base)", 3 * QtyInUOM);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferFieldsAreReadOnlyOnPartiallyShippedTransferOrderPage()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferOrder: TestPage "Transfer Order";
    begin
        // [SCENARIO] Transfer fields are disabled on Transfer Order page when the document is partially shipped.
        Initialize();

        // [GIVEN] Transfer Order with partly shipped line
        CreatePartlyShipTransferOrder(TransferHeader, TransferLine);

        // [WHEN] Transfer Order is opened
        TransferOrder.OpenEdit();
        TransferOrder.GotoRecord(TransferHeader);

        // [THEN] Transfer related fields are not editable
        Assert.IsFalse(TransferOrder."Transfer-from Code".Editable(), 'Transfer-from Code is not expected to be editable.');
        Assert.IsFalse(TransferOrder."Transfer-to Code".Editable(), 'Transfer-to Code is not expected to be editable.');
        Assert.IsFalse(TransferOrder."In-Transit Code".Editable(), 'In-Transit Code is not expected to be editable.');
        Assert.IsFalse(TransferOrder."Transfer-from Address".Editable(), 'Transfer-from fields are not expected to be editable.');
        Assert.IsFalse(TransferOrder."Transfer-to Address".Editable(), 'Transfer-to fields are not expected to be editable.');
        Assert.IsFalse(TransferOrder."Shipping Agent Code".Editable(), 'Shipment fields are not expected to be editable.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferFieldsAreEditableOnTransferOrderPageWithNoShippedLines()
    var
        TransferOrder: TestPage "Transfer Order";
    begin
        // [SCENARIO] Transfer fields are editable on Transfer Order page with no shipped lines.
        Initialize();

        // [GIVEN] Transfer Order with new transfer line initialized
        // [WHEN] Transfer Order is opened
        CreateTransferOrderAndInitializeNewTransferLine(TransferOrder, '');

        // [THEN] Transfer related fields are not editable
        Assert.IsTrue(TransferOrder."Transfer-from Code".Editable(), 'Transfer-from Code is expected to be editable.');
        Assert.IsTrue(TransferOrder."Transfer-to Code".Editable(), 'Transfer-to Code is expected to be editable.');
        Assert.IsTrue(TransferOrder."In-Transit Code".Editable(), 'In-Transit Code is expected to be editable.');
        Assert.IsTrue(TransferOrder."Transfer-from Address".Editable(), 'Transfer-from fields are expected to be editable.');
        Assert.IsTrue(TransferOrder."Transfer-to Address".Editable(), 'Transfer-to fields are expected to be editable.');
        Assert.IsTrue(TransferOrder."Shipping Agent Code".Editable(), 'Shipment fields are expected to be editable.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShippingAgentServiceCodeFromWhseShpmtToTransferOrder()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ShippingAgentCode: array[2] of Code[10];
        ShippingAgentServiceCode: array[2] of Code[10];
    begin
        // [FEATURE] [Transfer Order] [Transfer Shipment] [Shipping Agent Service]
        // [SCENARIO 267371] Empty value of Shipping Agent Service Code must be transferred from Warehouse Shipment to Transfer Order when Warehouse Shipment is being posted

        Initialize();

        // [GIVEN] Create LocationFrom, LocationTo and LocationInTransit. LocationFrom is set up for Whse Shipment
        LibraryWarehouse.CreateLocationWMS(LocationFrom, false, false, false, false, true);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);

        // [GIVEN] Create Item with stock
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJnlWithCostLocationVariant(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.",
          LibraryRandom.RandIntInRange(5, 10), LibraryRandom.RandInt(100), LocationFrom.Code, '');

        // [GIVEN] Create Shipping Agent with service code
        CreateShippingAgentServiceCodeWith1YShippingTime(ShippingAgentCode[1], ShippingAgentServiceCode[1]);

        // [GIVEN] Create another Shipping Agent with empty service code
        CreateShippingAgentServiceCodeWith1YShippingTime(ShippingAgentCode[2], ShippingAgentServiceCode[2]);
        ShippingAgentServiceCode[2] := '';

        // [GIVEN] Create Transfer Order with Shipping Agent, Shipping Agent Service Code and single line
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);
        TransferHeader.Validate("Shipping Agent Code", ShippingAgentCode[1]);
        TransferHeader.Validate("Shipping Agent Service Code", ShippingAgentServiceCode[1]);
        TransferHeader.Modify(true);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", LibraryRandom.RandIntInRange(1, 5));

        // [GIVEN] Release Transfer Order and create whse. shipment
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);

        // [GIVEN] Find and modify "Shipping Agent Service Code" in whse. shipment using void value
        WarehouseShipmentHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(DATABASE::"Transfer Line", 0, TransferHeader."No."));
        WarehouseShipmentHeader.Validate("Shipping Agent Code", ShippingAgentCode[2]);
        WarehouseShipmentHeader.Validate("Shipping Agent Service Code", ShippingAgentServiceCode[2]);
        WarehouseShipmentHeader.Modify(true);

        // [WHEN] Post whse. shipment
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [THEN] Void value of Shipping Agent Service Code field is inherited from whse. shipment to Trasnsfer Header
        TransferHeader.Get(TransferHeader."No.");
        TransferHeader.TestField("Shipping Agent Service Code", ShippingAgentServiceCode[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatingItemNoOnTransferLineDoesNotSuggestChangingToAnotherItem()
    var
        Item: array[2] of Record Item;
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferOrder: TestPage "Transfer Order";
        Desc: Code[10];
        Desc2: Code[10];
        i: Integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 291763] The program does not suggest changing Item No. on transfer line when there are several items with the same description.
        Initialize();

        // [GIVEN] Two items "I1", "I2" with the same Description and "Description 2".
        Desc := LibraryUtility.GenerateGUID();
        Desc2 := LibraryUtility.GenerateGUID();
        for i := 1 to ArrayLen(Item) do begin
            LibraryInventory.CreateItem(Item[i]);
            Item[i].Description := Desc;
            Item[i]."Description 2" := Desc2;
            Item[i].Modify();
        end;

        // [GIVEN] Transfer order.
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationInTransit);
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);

        LibraryVariableStorage.Enqueue(AnotherItemWithSameDescTxt);

        // [WHEN] Open transfer order page and select item no. "I2" on a new transfer line.
        TransferOrder.OpenEdit();
        TransferOrder.GotoKey(TransferHeader."No.");
        TransferOrder.TransferLines."Item No.".SetValue(Item[2]."No.");
        TransferOrder.Close();

        // [THEN] No confirmation message is shown (the enqueued text is not handled).
        Assert.AreEqual(AnotherItemWithSameDescTxt, LibraryVariableStorage.DequeueText(), 'The program must not suggest another item no.');

        // [THEN] The selected item no. is saved.
        // [THEN] Description and "Description 2" are updated on the transfer line.
        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.FindFirst();
        TransferLine.TestField("Item No.", Item[2]."No.");
        TransferLine.TestField(Description, Desc);
        TransferLine.TestField("Description 2", Desc2);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseReceiptsModalPageHandler,PostedPurchaseReceiptLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure GetReceiptLinesSunshine()
    var
        Location: array[3] of Record Location;
        PurchRcptLine: Record "Purch. Rcpt. Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferOrder: TestPage "Transfer Order";
        i: Integer;
        PurchaseReceiptNo: array[3] of Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 278834] Function "Get Receipt Lines" creates transfer lines from selected purchase receipt lines
        Initialize();

        // [GIVEN] New location "LOC1"
        for i := 1 to 2 do
            LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[i]);
        LibraryWarehouse.CreateInTransitLocation(Location[3]);

        // [GIVEN] Post 3 purchase order receipts "PR1", "PR2", "PR3" on location "LOC1"
        for i := 1 to 3 do
            PurchaseReceiptNo[i] := CreatePostPurchOrder(Location[1].Code);
        // [GIVEN] purchase order "PR2" has line with item "ITEM1" and quantity "X"
        FindRandomReceiptLine(PurchaseReceiptNo[2], PurchRcptLine);

        // [GIVEN] Create transfer order from locaiton "LOC1" to "LOC2"
        LibraryWarehouse.CreateTransferHeader(TransferHeader, Location[1].Code, Location[2].Code, Location[3].Code);
        TransferOrder.OpenEdit();
        TransferOrder.FILTER.SetFilter("No.", TransferHeader."No.");

        // [WHEN] Run function "Get Receipt Lines"
        LibraryVariableStorage.Enqueue(PurchaseReceiptNo[2]); // Purchase Receipt to select
        LibraryVariableStorage.Enqueue(PurchRcptLine."No."); // Purchase Receipt Line to select
        TransferOrder.GetReceiptLines.Invoke();

        // [THEN] Opened list of purchase receipt headers filtered by location "LOC1"
        // [WHEN] Receipt "PR2" selected
        // [THEN] Opened list or purchase receipt lines filtered by "PR2" and location "LOC1"
        // [WHEN] Receipt line with item "ITEM1" selected
        // [THEN] Transfer line created with item "ITEM1" and quantity "X"
        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.FindLast();
        TransferLine.TestField("Item No.", PurchRcptLine."No.");
        TransferLine.TestField(Quantity, PurchRcptLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostTransferOrderPartiallyWhenItemIsBlocked_Direct()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        // [SCENARIO] Direct Transfer Order shipped with blocked item on a previously shipped line
        Initialize();

        // [GIVEN] Inventory Setup is configured for "Direct Transfer Posting" = "Receipt and Shipment"
        InventorySetup.Get();
        InventorySetup.Validate("Direct Transfer Posting", InventorySetup."Direct Transfer Posting"::"Receipt and Shipment");
        InventorySetup.Modify();

        PostTransferShipmentPartiallyWithBlockedItem(true); //DirectTransfer = true
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostTransferOrderPartiallyWhenItemIsBlocked_InTransitShipment()
    begin
        // [SCENARIO] Intransit Transfer Order shipped with blocked item on a previously shipped line
        Initialize();
        PostTransferShipmentPartiallyWithBlockedItem(false); //DirectTransfer = false
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostDirectTransferWithPartialShipmentEnableDirectTransfers()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        QtyToShip: Integer;
    begin
        // [FEATURE 463842] [Direct Transfer] [Order] [Partial Shipment]
        // [SCENARIO] Post partial shipment in direct transfer order with posting direct transfer
        Initialize();
        EnableDirectTransfersInInventorySetup();
        QtyToShip := LibraryRandom.RandInt(10) + 1;

        // [GIVEN] Locations "A" and "B".
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationFrom);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Post positive inventory adjustment to location "A".
        // [GIVEN] Post negative inventory adjustment from blank location.
        CreateAndPostItemJnlWithCostLocationVariant(
          "Item Ledger Entry Type"::"Positive Adjmt.", Item."No.", QtyToShip, 0, LocationFrom.Code, '');
        CreateAndPostItemJnlWithCostLocationVariant(
          "Item Ledger Entry Type"::"Negative Adjmt.", Item."No.", QtyToShip, 0, '', '');

        // [GIVEN] Direct transfer order from "A" to "B".
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, '');
        TransferHeader.Validate("Direct Transfer", true);
        TransferHeader.Modify(true);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", QtyToShip);

        // [WHEN] Post the direct transfer.
        asserterror TransferLine.Validate("Qty. to Ship", QtyToShip - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostTransferOrderWhenLocationFromContainsSpecialChars()
    var
        Location: array[2] of Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Item: Record Item;
    begin
        // [SCENARIO 315589] Transfer Order is posted in case Transfer From Location Code contains special characters, that are used in filters (=<>.@&()"|).
        Initialize();

        // [GIVEN] Locations "L1" and "L2". "L1" Code field contains special characters, that are used in filters.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[1]);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[2]);
        Location[1].Rename('=A<.@ &)"|');

        // [GIVEN] Item "I" at Location "L1".
        CreateItemWithPositiveInventory(Item, Location[1].Code, LibraryRandom.RandIntInRange(100, 200));

        // [GIVEN] Transfer Order for Item "I" with Transfer From = "L1", Transfer To = "L2".
        CreateTransferOrderNoRoute(
          TransferHeader, TransferLine, Location[1].Code, Location[2].Code, Item."No.", '', LibraryRandom.RandIntInRange(10, 20));

        // [WHEN] Post Transfer Order.
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        // [THEN] Transfer Order was posted.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostTransferOrderWhenVariantContainsSpecialChars()
    var
        Location: array[2] of Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Item: Record Item;
        VariantCode: Code[10];
    begin
        // [SCENARIO 315589] Transfer Order is posted in case Variant Code of an Item contains special characters, that are used in filters (=<>.@&()"|).
        Initialize();

        // [GIVEN] Locations "L1" and "L2".
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[1]);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[2]);

        // [GIVEN] Item "I" with Variant "V" at Location "L1". "V" contains special characters, that are used in filters.
        VariantCode := '=A>.C@ &D(';
        CreateItemWithVariantAndPositiveInventory(Item, Location[1].Code, VariantCode, LibraryRandom.RandIntInRange(100, 200));

        // [GIVEN] Transfer Order for Item "I" with Transfer From = "L1", Transfer To = "L2", Variant = "V".
        CreateTransferOrderNoRoute(
          TransferHeader, TransferLine, Location[1].Code, Location[2].Code, Item."No.", VariantCode, LibraryRandom.RandIntInRange(10, 20));

        // [WHEN] Post Transfer Order.
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        // [THEN] Transfer Order was posted.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingDirectTransferDoesNotApplyPosIntermdEntryToExistingILE()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        QtyOnStock: Decimal;
        QtyTransferred: Decimal;
    begin
        // [FEATURE] [Direct Transfer] [Item Application]
        // [SCENARIO 321891] Intermediate item entry with blank location is not applied to existing negative item entries while posting direct transfer.
        Initialize();
        QtyOnStock := LibraryRandom.RandIntInRange(100, 200);
        QtyTransferred := LibraryRandom.RandInt(10);

        // [GIVEN] Locations "A" and "B".
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationFrom);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Post positive inventory adjustment to location "A".
        // [GIVEN] Post negative inventory adjustment from blank location.
        CreateAndPostItemJnlWithCostLocationVariant(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", QtyOnStock, 0, LocationFrom.Code, '');
        CreateAndPostItemJnlWithCostLocationVariant(
          ItemJournalLine."Entry Type"::"Negative Adjmt.", Item."No.", QtyOnStock, 0, '', '');

        // [GIVEN] Direct transfer order from "A" to "B".
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, '');
        TransferHeader.Validate("Direct Transfer", true);
        TransferHeader.Modify(true);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", QtyTransferred);

        // [WHEN] Post the direct transfer.
        LibraryInventory.PostDirectTransferOrder(TransferHeader);

        // [THEN] The transfer order is posted successfully.
        Item.SetRange("Location Filter", LocationTo.Code);
        Item.CalcFields("Net Change");
        Item.TestField("Net Change", QtyTransferred);

        // [THEN] The negative adjustment entry remains unapplied.
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Negative Adjmt.");
        ItemLedgerEntry.SetRange("Location Code", '');
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField("Remaining Quantity", -QtyOnStock);
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseReceiptsModalPageHandler,PostedPurchaseReceiptLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure TransferOrderGetReceiptLinesUnitOfMeasureCodeAndVariant()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemVariant: Record "Item Variant";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: array[3] of Record Location;
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchaseReceiptNo: Code[20];
    begin
        // [FEATURE] [Get Receipt Lines] [Unit of Measure Code] [Item Variant]
        // [SCENARIO 328925] "Get Receipt Lines" function copies correct Unit Of Measure Code from the Receipt to Transfer Order Line
        // [SCENARIO 328925] "Get Receipt Lines" function copies correct Variant Code from the Receipt to Transfer Order Line
        Initialize();

        // [GIVEN] Item "ITEM1" with Unit of Measure Code "UOM1" and Item Variant "ITEM1V1"
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandDec(10, 2));
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] New locations "LOC1", "LOC2"
        LibraryWarehouse.CreateTransferLocations(Location[1], Location[2], Location[3]);

        // [GIVEN] Post purchase order receipt "PR1" on location "LOC1" with line for "ITEM1","UOM1","ITEM1V1"
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '',
          Item."No.", LibraryRandom.RandIntInRange(5, 10), Location[1].Code, 0D);
        PurchaseLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        PurchaseLine.Validate("Variant Code", ItemVariant.Code);
        PurchaseLine.Modify(true);
        PurchaseReceiptNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        PurchRcptLine.SetRange("Document No.", PurchaseReceiptNo);
        PurchRcptLine.FindFirst();

        // [GIVEN] Create transfer order from location "LOC1" to "LOC2"
        LibraryWarehouse.CreateTransferHeader(TransferHeader, Location[1].Code, Location[2].Code, Location[3].Code);

        // [WHEN] Run function "Get Receipt Lines" with Receipt "PR1" line with item "ITEM1" selected
        LibraryVariableStorage.Enqueue(PurchaseReceiptNo); // Purchase Receipt to select
        LibraryVariableStorage.Enqueue(PurchRcptLine."No."); // Purchase Receipt Line to select
        TransferHeader.GetReceiptLines();

        // [THEN] Transfer line created with item "ITEM1", Unit Of Measure Code = "UOM1", Variant Code = "ITEM1V1"
        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.SetRange("Item No.", PurchRcptLine."No.");
        TransferLine.FindFirst();
        TransferLine.TestField("Unit of Measure Code", ItemUnitOfMeasure.Code);
        TransferLine.TestField("Unit of Measure", PurchRcptLine."Unit of Measure");
        TransferLine.TestField("Variant Code", ItemVariant.Code);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPurchModalPageHandler,PostedTransferReceiptLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure AssignPostedTransferReceiptLinesBlankItemNoToItemChargePurchase()
    var
        TransferReceiptHeader: Record "Transfer Receipt Header";
        TransferReceiptLine: Record "Transfer Receipt Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [UT] [Transfer Receipt] [Item Charge] [Purchase]
        // [SCENARIO 335337] Transfer Receipt Lines with blank Item No. and zero Quantity can't be assigned to Item Charges
        Initialize();

        // [GIVEN] Transfer Receipt "TR1"
        TransferReceiptHeader.Init();
        TransferReceiptHeader."No." := LibraryUtility.GenerateRandomCode(
            TransferReceiptHeader.FieldNo("No."), DATABASE::"Transfer Receipt Header");
        TransferReceiptHeader.Insert();
        LibraryVariableStorage.Enqueue(TransferReceiptHeader."No.");

        // [GIVEN] Transfer Receipt Line "TR1",10000 for Item "ITEM1" with Quantity 10
        MockTransferReceiptLine(
          TransferReceiptLine, TransferReceiptHeader."No.", LibraryUtility.GenerateGUID(), '', LibraryRandom.RandDec(10, 0));
        LibraryVariableStorage.Enqueue(TransferReceiptLine."Item No.");

        // [GIVEN] Transfer Receipt Line "TR1",20000 with blank Item No., Description = "Description 1" (Comment line)
        MockTransferReceiptLine(
          TransferReceiptLine, TransferReceiptHeader."No.", '', LibraryUtility.GenerateGUID(), LibraryRandom.RandDec(10, 0));

        // [GIVEN] Transfer Receipt Line "TR1",30000 for Item "ITEM2" with Quantity 0
        MockTransferReceiptLine(TransferReceiptLine, TransferReceiptHeader."No.", LibraryUtility.GenerateGUID(), '', 0);

        // [GIVEN] Purchase Order with Item Charge Line "PO01",10000
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), LibraryRandom.RandDec(100, 0));

        // [WHEN] Invoke "Get Transfer Receipt Lines" action on the "Item Charge Assignment (Purch)" page for the Purchase Line "PO01",10000
        PurchaseLine.ShowItemChargeAssgnt();

        // [THEN] Only Transfer Receipt Line 10000 shown for the Transfer Receipt "TR1"
        // Verification done in PostedTransferReceiptLinesModalPageHandler

        LibraryVariableStorage.AssertEmpty();
    end;

    [HandlerFunctions('PostedTransferShipmentLinesHandler')]
    [Test]
    procedure TransferOrderQtyShippedDrillDown()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferOrder: TestPage "Transfer Order";
    begin
        // [FEATURE] [UI] [Transfer Order] 
        // [SCENARIO 335337] "Quantity Shipped" DrillDown filters lines by "Line No."
        Initialize();

        // [GIVEN] Partly shipped Transfer Order "T" from "L1" to Location "L2".
        CreatePartlyShipTransferOrder(TransferHeader, TransferLine);

        // [WHEN] "Quantity Shipped" DrillDown is being activated
        TransferOrder.OpenEdit();
        TransferOrder.Filter.SetFilter("No.", TransferHeader."No.");
        TransferOrder.TransferLines."Quantity Shipped".Drilldown();

        // [THEN] Opened page has filter by "Line No."
        Assert.AreEqual(Format(TransferLine."Line No."), LibraryVariableStorage.DequeueText(), 'Invalid filter');
    end;

    [HandlerFunctions('PostedTransferReceiptLinesHandler')]
    [Test]
    procedure TransferOrderQtyReceivedDrillDown()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferOrder: TestPage "Transfer Order";
    begin
        // [FEATURE] [UI] [Transfer Order] 
        // [SCENARIO 335337] "Quantity Received" DrillDown filters lines by "Line No."
        Initialize();

        // [GIVEN] Partly Received Transfer Order "T" from "L1" to Location "L2".
        CreatePartlyShipTransferOrder(TransferHeader, TransferLine);
        LibraryWarehouse.PostTransferOrder(TransferHeader, false, true);

        // [WHEN] "Quantity Received" DrillDown is being activated
        TransferOrder.OpenEdit();
        TransferOrder.Filter.SetFilter("No.", TransferHeader."No.");
        TransferOrder.TransferLines."Quantity Received".Drilldown();

        // [THEN] Opened page has filter by "Line No."
        Assert.AreEqual(Format(TransferLine."Line No."), LibraryVariableStorage.DequeueText(), 'Invalid filter');
    end;

    [HandlerFunctions('PostedTransferShipmentLinesGetDescriptionHandler')]
    [Test]
    procedure TransferOrderQtyShippedDrillDownSecondLine()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferOrder: TestPage "Transfer Order";
        Qty: Decimal;
    begin
        // [FEATURE] [UI] [Transfer Order] 
        // [SCENARIO 335337] "Quantity Shipped" DrillDown opens proper line when tranfer order shipped line by line
        Initialize();

        // [GIVEN] Transfer Order "T" from "L1" to Location "L2".
        CreateTransferOrderHeader(TransferHeader);
        Qty := LibraryRandom.RandIntInRange(100, 200);
        CreateItemWithPositiveInventory(Item, TransferHeader."Transfer-from Code", Qty * 2);

        // [GIVEN] Transfer order line for item "I" with "Qty to Ship" = 0 and Description = "D1"
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", Qty);
        TransferLine.Validate("Qty. to Ship", 0);
        TransferLine.Description := CopyStr(Format(CreateGuid()), 1, MaxStrLen(TransferLine.Description));
        TransferLine.Modify();

        // [GIVEN] Transfer order line for item "I" with "Qty to Ship" = 10 and Description = "D2"
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", Qty);
        TransferLine.Description := CopyStr(Format(CreateGuid()), 1, MaxStrLen(TransferLine.Description));
        TransferLine.Modify();

        // [GIVEN] Ship tranfer order 
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        // [WHEN] "Quantity Shipped" DrillDown is being activated for second line
        TransferOrder.OpenEdit();
        TransferOrder.Filter.SetFilter("No.", TransferHeader."No.");
        TransferOrder.TransferLines.Filter.SetFilter(Description, TransferLine.Description);
        TransferOrder.TransferLines."Quantity Shipped".Drilldown();

        // [THEN] Opened page has Description "D2"
        Assert.AreEqual(TransferLine.Description, LibraryVariableStorage.DequeueText(), 'Invalid transfer shipment line');
    end;

    [Test]
    procedure TransferOrderToShipmentPReservesShipmentMethodCode()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // [FEATURE] [Transfer Shipment]
        // [SCENARIO 373592] When creating Warehouse shipment from Transfer Order, the shipment method code is saved
        Initialize();

        // [GIVEN] Create LocationFrom, LocationTo and LocationInTransit. LocationFrom is set up for Whse Shipment
        LibraryWarehouse.CreateLocationWMS(LocationFrom, false, false, false, false, true);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);

        // [GIVEN] Create Item with stock
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJnlWithCostLocationVariant(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.",
          LibraryRandom.RandIntInRange(5, 10), LibraryRandom.RandInt(100), LocationFrom.Code, '');

        // [GIVEN] Create Transfer Order with Shipment Method Code = "XXX" and a line
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);
        TransferHeader.Validate("Shipment Method Code", CreateShipmentMethodCode());
        TransferHeader.Modify(true);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", LibraryRandom.RandIntInRange(1, 5));

        // [WHEN] Release Transfer Order and create whse. shipment
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);

        // [THEN] Warehouse Shipment has Shipment Method Code = "XXX"
        WarehouseShipmentHeader.Get(LibraryWarehouse.FindWhseShipmentNoBySourceDoc(DATABASE::"Transfer Line", 0, TransferHeader."No."));
        WarehouseShipmentHeader.TestField("Shipment Method Code", TransferHeader."Shipment Method Code");
    end;

    [Test]
    procedure TransferOrderPostingPreservesExternalDocumentNo()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: array[3] of Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ExpectedExternalDocumentNoLbl: Label 'External Document No. is expected on Item Ledger Entry.';
    begin
        // [FEATURE] [Transfer Order]
        // [SCENARIO] When creating and posting Transfer Order, External Document No. is preserved on Item Ledger Entry
        Initialize();

        // [GIVEN] Create LocationFrom, LocationTo and LocationInTransit.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[1]);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[2]);
        LibraryWarehouse.CreateInTransitLocation(Location[3]);

        // [GIVEN] Create Item with stock
        CreateItemWithPositiveInventory(Item, Location[1].Code, 10);

        // [GIVEN] Create Transfer Order with External Document No
        LibraryInventory.CreateTransferHeader(TransferHeader, Location[1].Code, Location[2].Code, Location[3].Code);
        TransferHeader.Validate("External Document No.", LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(TransferHeader."External Document No."), 0));
        TransferHeader.Modify();

        // [GIVEN] Create Transfer Line
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", LibraryRandom.RandIntInRange(1, 5));

        // [WHEN] Post transfer Order
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);  // Ship and receive

        // [THEN] Verify item ledger entries have the same External Document No.
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.", ItemLedgerEntry."Entry Type"::"Transfer", Location[1].Code, false);
        Assert.AreEqual(TransferHeader."External Document No.", ItemLedgerEntry."External Document No.", ExpectedExternalDocumentNoLbl);

        FindItemLedgerEntry(ItemLedgerEntry, Item."No.", ItemLedgerEntry."Entry Type"::"Transfer", Location[2].Code, true);
        Assert.AreEqual(TransferHeader."External Document No.", ItemLedgerEntry."External Document No.", ExpectedExternalDocumentNoLbl);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler')]
    procedure ShippingPartiallyPickedOutboundTransferFromLocationWithoutBins()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        LotNo: Code[50];
        Qty: Decimal;
    begin
        // [FEATURE] [Shipment] [Item Tracking] [Pick] [Basic Warehousing]
        // [SCENARIO 392298] Stan can post partial pick and shipment with item tracking for outbound transfer at location without bins.
        Initialize();
        LotNo := LibraryUtility.GenerateGUID();
        Qty := LibraryRandom.RandIntInRange(20, 40);

        // [GIVEN] Locations "From" with required shipment and pick, bin mandatory = FALSE.
        // [GIVEN] Locations "To" and "InTransit".
        LibraryWarehouse.CreateLocationWMS(LocationFrom, false, false, true, false, true);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationFrom.Code, false);

        // [GIVEN] Lot-tracked item.
        CreateLotTrackedItem(Item, false);

        // [GIVEN] Post 20 pcs of the item to inventory, assign lot no. "L1".
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", LocationFrom.Code, '', Qty);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Transfer order for 20 pcs "From" -> "To" via "InTransit"
        // [GIVEN] Assign lot "L1" to 10 pcs only.
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", Qty);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty / 2);
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);
        LibraryInventory.ReleaseTransferOrder(TransferHeader);

        // [GIVEN] Create warehouse shipment.
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);
        WarehouseShipmentHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(DATABASE::"Transfer Line", 0, TransferHeader."No."));

        // [GIVEN] Create pick from the shipment.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // [GIVEN] Set "Qty. to Handle" = 10 pcs and register the pick.
        LibraryWarehouse.FindWhseActivityLineBySourceDoc(
          WarehouseActivityLine, DATABASE::"Transfer Line", 0, TransferLine."Document No.", TransferLine."Line No.");
        WarehouseActivityLine.Validate("Qty. to Handle", Qty / 2);
        WarehouseActivityLine.Modify(true);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [WHEN] Post the warehouse shipment.
        WarehouseShipmentHeader.Find();
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [THEN] The transfer order has been successfully shipped.
        TransferLine.Find();
        TransferLine.TestField("Quantity Shipped", Qty / 2);

        // [THEN] Verified that an item entry for transfer with quantity = 10 pcs and lot no. "L1" has been posted.
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Transfer);
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField(Quantity, -Qty / 2);
        ItemLedgerEntry.TestField("Lot No.", LotNo);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingErrorThrownWhenInvalidQuantityEntered0OnTransferLine()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemUOM: Record "Item Unit of Measure";
        ItemNonBaseUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
    begin
        // [SCENARIO] A rounding error should be thrown if the entered base quantity does not match the rounding precision.
        Initialize();

        // [GIVEN] At transfer line using base UoM with rounding precision of 0.1.
        SetupForUoMTest(Item, TransferHeader, TransferLine, BaseUOM, NonBaseUOM, ItemUOM, ItemNonBaseUOM, 1, 6, 0.1);
        TransferLine.Validate("Unit of Measure Code", ItemUOM.Code);

        // [WHEN] Setting the quantity to 0.4.
        TransferLine.Validate(Quantity, 0.4);

        // [THEN] No error is thrown an base qty is 0.4.
        Assert.AreEqual(0.4, TransferLine."Quantity (Base)", 'Expected quantity to be 0.4.');

        // [WHEN] Setting the quantity to 0.41.
        asserterror TransferLine.Validate(Quantity, 0.41);

        // [THEN] An rounding error is thrown.
        Assert.ExpectedError(RoundingErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorThrownWhenQuantityIsRoundedTo0OnTransferLine()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemUOM: Record "Item Unit of Measure";
        ItemNonBaseUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
    begin
        // [SCENARIO] A rounding to 0 error should be thrown if the entered non-base quantity converted to the 
        // base quantity is rounded to zero.
        Initialize();

        // [GIVEN] A transfer line using non-base UoM with a rounding precision of 0.1.
        SetupForUoMTest(Item, TransferHeader, TransferLine, BaseUOM, NonBaseUOM, ItemUOM, ItemNonBaseUOM, 1, 6, 0.1);
        TransferLine.Validate("Unit of Measure Code", ItemNonBaseUOM.Code);

        // [WHEN] Setting the quantity to 1/6.
        TransferLine.Validate(Quantity, 1 / 6);

        // [THEN] Base quantity is 1 and no error is thrown.
        Assert.AreEqual(1, TransferLine."Quantity (Base)", 'Expected quantity to be 1.');

        // [WHEN] Setting the quantity to 1/121 (1 / 121 = 0.00826 * 6 = 0.04956, which gets rounded to 0).
        asserterror TransferLine.Validate(Quantity, 1 / 121);

        // [THEN] A rounding to zero error is thrown.
        Assert.ExpectedError(RoundingTo0Err);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferLineQuantityIsRoundedWithRoundingPrecisionSpecified()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemUOM: Record "Item Unit of Measure";
        ItemNonBaseUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
    begin
        // [SCENARIO] When converting to base UoM the specified rounding precision should be used.
        Initialize();

        // [GIVEN] A transfer line using non-base UoM with a rounding precision of 0.1.
        SetupForUoMTest(Item, TransferHeader, TransferLine, BaseUOM, NonBaseUOM, ItemUOM, ItemNonBaseUOM, 1, 6, 0.1);
        TransferLine.Validate("Unit of Measure Code", ItemNonBaseUOM.Code);

        // [WHEN] Setting the quantity to 1/3 (1/3 = 0.333333 * 6 = 1.99998, which gets rounded to 2).
        TransferLine.Validate(Quantity, 1 / 3);

        // [THEN] The base quantity is rounded to 2.
        Assert.AreEqual(2, TransferLine."Quantity (Base)", 'Expected value to be rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingBalanceErrThrownWhenInvalidQtyToShipEntered0OnTransferLine()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemUOM: Record "Item Unit of Measure";
        ItemNonBaseUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
    begin
        // [SCENARIO] A rounding error should be thrown if the entered base quantity does not match the rounding precision.
        Initialize();

        // [GIVEN] At transfer line using base UoM with rounding precision of 0.1.
        SetupForUoMTest(Item, TransferHeader, TransferLine, BaseUOM, NonBaseUOM, ItemUOM, ItemNonBaseUOM, 1, 6, 0.1);
        TransferLine.Validate("Unit of Measure Code", ItemUOM.Code);

        // [WHEN] Setting the quantity to 0.4.
        TransferLine.Validate(Quantity, 0.4);
        TransferLine.Validate("Qty. to Ship", 0.4);

        // [THEN] No error is thrown an base qty is 0.4.
        Assert.AreEqual(0.4, TransferLine."Qty. to Ship", 'Expected quantity to be 0.4.');

        // [WHEN] Setting the quantity to 0.39.
        asserterror TransferLine.Validate("Qty. to Ship", 0.39);

        // [THEN] An rounding error is thrown.
        Assert.ExpectedError(RoundingBalanceErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorThrownWhenQtyToShipIsRoundedTo0OnTransferLine()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemUOM: Record "Item Unit of Measure";
        ItemNonBaseUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
    begin
        // [SCENARIO] A rounding to 0 error should be thrown if the entered non-base quantity converted to the 
        // base quantity is rounded to zero.
        Initialize();

        // [GIVEN] A transfer line using non-base UoM with a rounding precision of 0.1.
        SetupForUoMTest(Item, TransferHeader, TransferLine, BaseUOM, NonBaseUOM, ItemUOM, ItemNonBaseUOM, 1, 6, 0.1);
        TransferLine.Validate("Unit of Measure Code", ItemNonBaseUOM.Code);

        // [WHEN] Setting the quantity to 1/6.
        TransferLine.Validate(Quantity, 1);
        TransferLine.Validate("Qty. to Ship", 1 / 6);

        // [THEN] Base quantity is 1 and no error is thrown.
        Assert.AreEqual(1, TransferLine."Qty. to Ship (Base)", 'Expected quantity to be 1.');

        // [WHEN] Setting the quantity to 1/121 (1 / 121 = 0.00826 * 6 = 0.04956, which gets rounded to 0).
        asserterror TransferLine.Validate("Qty. to Ship", 1 / 121);

        // [THEN] A rounding to zero error is thrown.
        Assert.ExpectedError(RoundingTo0Err);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferLineQtyToShipIsRoundedWithRoundingPrecisionSpecified()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemUOM: Record "Item Unit of Measure";
        ItemNonBaseUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
    begin
        // [SCENARIO] When converting to base UoM the specified rounding precision should be used.
        Initialize();

        // [GIVEN] A transfer line using non-base UoM with a rounding precision of 0.1.
        SetupForUoMTest(Item, TransferHeader, TransferLine, BaseUOM, NonBaseUOM, ItemUOM, ItemNonBaseUOM, 1, 6, 0.1);
        TransferLine.Validate("Unit of Measure Code", ItemNonBaseUOM.Code);

        // [WHEN] Setting the quantity to 1/3 (1/3 = 0.333333 * 6 = 1.99998, which gets rounded to 2).
        TransferLine.Validate(Quantity, 1);
        TransferLine.Validate("Qty. to Ship", 1 / 3);

        // [THEN] The base quantity is rounded to 2.
        Assert.AreEqual(2, TransferLine."Qty. to Ship (Base)", 'Expected value to be rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingBalanceErrorThrownWhenInvalidQtyToReceiveEntered0OnTransferLine()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemUOM: Record "Item Unit of Measure";
        ItemNonBaseUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
    begin
        // [SCENARIO] A rounding error should be thrown if the entered base quantity does not match the rounding precision.
        Initialize();

        // [GIVEN] At transfer line using base UoM with rounding precision of 0.1.
        SetupForUoMTest(Item, TransferHeader, TransferLine, BaseUOM, NonBaseUOM, ItemUOM, ItemNonBaseUOM, 1, 6, 0.1);
        TransferLine.Validate("Unit of Measure Code", ItemUOM.Code);

        // [WHEN] Setting the quantity to 0.4.
        TransferLine.Validate(Quantity, 0.4);
        TransferLine.Validate("Qty. to Ship", 0.4);
        TransferLine.Validate("Qty. to Receive", 0.4);

        // [THEN] No error is thrown an base qty is 0.4.
        Assert.AreEqual(0.4, TransferLine."Qty. to Receive (Base)", 'Expected quantity to be 0.4.');

        // [WHEN] Setting the quantity to 0.39.
        asserterror TransferLine.Validate("Qty. to Receive", 0.39);

        // [THEN] An rounding error is thrown.
        Assert.ExpectedError(RoundingBalanceErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorThrownWhenQtyToReceiveIsRoundedTo0OnTransferLine()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemUOM: Record "Item Unit of Measure";
        ItemNonBaseUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
    begin
        // [SCENARIO] A rounding to 0 error should be thrown if the entered non-base quantity converted to the 
        // base quantity is rounded to zero.
        Initialize();

        // [GIVEN] A transfer line using non-base UoM with a rounding precision of 0.1.
        SetupForUoMTest(Item, TransferHeader, TransferLine, BaseUOM, NonBaseUOM, ItemUOM, ItemNonBaseUOM, 1, 6, 0.1);
        TransferLine.Validate("Unit of Measure Code", ItemNonBaseUOM.Code);

        // [WHEN] Setting the quantity to 1/6.
        TransferLine.Validate(Quantity, 1);
        TransferLine.Validate("Qty. to Ship", 1 / 6);
        TransferLine.Validate("Qty. to Receive", 1 / 6);

        // [THEN] Base quantity is 1 and no error is thrown.
        Assert.AreEqual(1, TransferLine."Qty. to Receive (Base)", 'Expected quantity to be 1.');

        // [WHEN] Setting the quantity to 1/121 (1 / 121 = 0.00826 * 6 = 0.04956, which gets rounded to 0).
        asserterror TransferLine.Validate("Qty. to Receive", 1 / 121);

        // [THEN] A rounding to zero error is thrown.
        Assert.ExpectedError(RoundingTo0Err);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferLineQtyToReceiveIsRoundedWithRoundingPrecisionSpecified()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemUOM: Record "Item Unit of Measure";
        ItemNonBaseUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
    begin
        // [SCENARIO] When converting to base UoM the specified rounding precision should be used.
        Initialize();

        // [GIVEN] A transfer line using non-base UoM with a rounding precision of 0.1.
        SetupForUoMTest(Item, TransferHeader, TransferLine, BaseUOM, NonBaseUOM, ItemUOM, ItemNonBaseUOM, 1, 6, 0.1);
        TransferLine.Validate("Unit of Measure Code", ItemNonBaseUOM.Code);
        TransferLine.Validate(Quantity, 1);
        TransferLine.Validate("Qty. to Ship", 1 / 3);
        TransferLine.Modify();

        // [WHEN] Setting the quantity to 1/3 (1/3 = 0.333333 * 6 = 1.99998, which gets rounded to 2).
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        TransferLine.Validate("Qty. to Receive", 1 / 3);

        // [THEN] The base quantity is rounded to 2.
        Assert.AreEqual(2, TransferLine."Qty. to Receive (Base)", 'Expected value to be rounded correctly.');
    end;

    [Test]
    procedure SaveDimensionsWhenPostingDirectTransfer()
    var
        Item: Record Item;
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        Location: array[3] of Record Location;
        ItemJournalLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        DimensionSetID: Integer;
    begin
        // [FEATURE] [Direct Transfer] [Dimension]
        // [SCENARIO 404985] "Dimension Set ID" is populated on item entries generated by posting direct transfer.
        Initialize();

        // [GIVEN] Enable direct transfers.
        EnableDirectTransfersInInventorySetup();

        // [GIVEN] Item "I" with dimension.
        LibraryInventory.CreateItem(Item);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionItem(
            DefaultDimension, Item."No.", DimensionValue."Dimension Code", DimensionValue.Code);

        // [GIVEN] Locations "A", "B", and in-transit location.
        LibraryWarehouse.CreateTransferLocations(Location[1], Location[2], Location[3]);

        // [GIVEN] Post inventory adjustment of "I" to location "A".
        LibraryInventory.CreateItemJournalLineInItemTemplate(
            ItemJournalLine, Item."No.", Location[1].Code, '', LibraryRandom.RandIntInRange(10, 20));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create direct transfer order from "A" to "B".
        // [GIVEN] Dimension Set ID on the transfer line = "DimSetID".
        LibraryWarehouse.CreateTransferHeader(TransferHeader, Location[1].Code, Location[2].Code, '');
        TransferHeader.Validate("Direct Transfer", true);
        TransferHeader.Modify(true);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", LibraryRandom.RandInt(10));
        TransferLine.TestField("Dimension Set ID");
        DimensionSetID := TransferLine."Dimension Set ID";

        // [WHEN] Post the transfer order.
        LibraryInventory.PostDirectTransferOrder(TransferHeader);

        // [THEN] "Dimension Set ID" = "DimSetID" on item entry for posted transfer.
        ItemLedgerEntry.Get(FindLastILENo(Item."No."));
        ItemLedgerEntry.TestField("Dimension Set ID", DimensionSetID);
    end;

    [Test]
    procedure CanChangePostingDateOnReleasedDirectTransferOrder()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        LocationFromCode: Code[10];
        LocationToCode: Code[10];
    begin
        // [FEATURE] [Direct Transfer] [UT]
        // [SCENARIO 413543] Stan can change posting date on released direct transfer order.
        Initialize();

        CreateLocations(LocationFromCode, LocationToCode);

        LibraryWarehouse.CreateTransferHeader(TransferHeader, LocationFromCode, LocationToCode, '');
        TransferHeader.Validate("Direct Transfer", true);
        TransferHeader.Modify(true);
        LibraryWarehouse.CreateTransferLine(
            TransferHeader, TransferLine, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));

        LibraryInventory.ReleaseTransferOrder(TransferHeader);

        TransferHeader.Validate("Posting Date", WorkDate() + 30);

        Assert.AreNotEqual(TransferHeader."Posting Date", TransferHeader."Shipment Date", '');
        Assert.AreNotEqual(TransferHeader."Posting Date", TransferHeader."Receipt Date", '');
    end;

    [Test]
    procedure PostingDirectTransferDoesNotApplyNegIntermdEntryToExistingILE()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemApplicationEntry: Record "Item Application Entry";
        QtyOnStock: Decimal;
        QtyTransferred: Decimal;
        PositiveInterimILENo: Integer;
        NegativeInterimILENo: Integer;
    begin
        // [FEATURE] [Direct Transfer] [Item Application]
        // [SCENARIO 412614] Intermediate negative item entry with blank location is not applied to existing positive item entry while posting direct transfer.
        Initialize();
        QtyOnStock := LibraryRandom.RandIntInRange(100, 200);
        QtyTransferred := LibraryRandom.RandInt(10);

        // [GIVEN] Locations "A" and "B".
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationFrom);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Post positive inventory adjustment to location "A".
        // [GIVEN] Post positive inventory adjustment to blank location.
        CreateAndPostItemJnlWithCostLocationVariant(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", QtyOnStock, 0, LocationFrom.Code, '');
        CreateAndPostItemJnlWithCostLocationVariant(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", QtyOnStock, 0, '', '');

        // [GIVEN] Direct transfer order from "A" to "B".
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, '');
        TransferHeader.Validate("Direct Transfer", true);
        TransferHeader.Modify(true);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", QtyTransferred);

        // [WHEN] Post the direct transfer.
        LibraryInventory.PostDirectTransferOrder(TransferHeader);

        // [THEN] The transfer order is posted successfully.
        Item.SetRange("Location Filter", LocationTo.Code);
        Item.CalcFields("Net Change");
        Item.TestField("Net Change", QtyTransferred);

        // [THEN] The existing positive inventory adjustment to blank location remains unapplied.
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.", ItemLedgerEntry."Entry Type"::"Positive Adjmt.", '', true);
        ItemLedgerEntry.TestField("Remaining Quantity", QtyOnStock);

        // [THEN] Interim transfer entries at blank location are applied to each other.
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.", ItemLedgerEntry."Entry Type"::Transfer, '', true);
        PositiveInterimILENo := ItemLedgerEntry."Entry No.";
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.", ItemLedgerEntry."Entry Type"::Transfer, '', false);
        NegativeInterimILENo := ItemLedgerEntry."Entry No.";
        ItemApplicationEntry.GetInboundEntriesTheOutbndEntryAppliedTo(NegativeInterimILENo);
        ItemApplicationEntry.TestField("Inbound Item Entry No.", PositiveInterimILENo);
    end;

    [Test]
    procedure TransferOrderPartnerVATID_Post()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        TransferReceiptHeader: Record "Transfer Receipt Header";
        FromLocationCode: Code[10];
        ToLocationCode: Code[10];
        PartnerVATID: Text[20];
        Length: Integer;
    begin
        // [FEATURE] [Intrastat] [Partner VAT ID]
        // [SCENARIO 417835] Post Transfer Order with typed header field "Partner VAT ID"
        Initialize();
#pragma warning disable AA0139  // Code below still raises warning AA0139, although the overflow can never happen
        Length := MaxStrLen(TransferHeader."Partner VAT ID");
        PartnerVATID := CopyStr(LibraryUtility.GenerateRandomText(Length), 1, Length);
#pragma warning restore

        // [GIVEN] Item "I" on Location "A"
        CreateLocations(FromLocationCode, ToLocationCode);
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJnlWithCostLocationVariant(
            ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 1, 0, FromLocationCode, '');

        // [GIVEN] Transfer Order to transfer item "I" from location "A" to location "B",
        // [GIVEN] Transfer Order header's "Partner VAT ID" = "X",
        LibraryInventory.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, '');
        TransferHeader.Validate("Direct Transfer", true);
        TransferHeader.Validate("Partner VAT ID", PartnerVATID);
        TransferHeader.Modify(true);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 1);

        // [WHEN] Post Ship and Receive transfer order
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        // [THEN] Posted Transfer Shipment header's "Partner VAT ID" = "X"
        TransferShipmentHeader.SetRange("Transfer Order No.", TransferHeader."No.");
        TransferShipmentHeader.FindFirst();
        TransferShipmentHeader.TestField("Partner VAT ID", PartnerVATID);

        // [THEN] Posted Transfer Receipt header's "Partner VAT ID" = "X"
        TransferReceiptHeader.SetRange("Transfer Order No.", TransferHeader."No.");
        TransferReceiptHeader.FindFirst();
        TransferReceiptHeader.TestField("Partner VAT ID", PartnerVATID);
    end;

    [Test]
    procedure PostingDirectTransferWithItemTracking()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        LocationFromCode: Code[10];
        LocationToCode: Code[10];
        LotNo: Code[50];
    begin
        // [FEATURE] [Direct Transfer] [Item Tracking]
        // [SCENARIO 422832] Posting direct transfer with item tracking.
        Initialize();
        LotNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Enable direct transfers in Inventory Setup.
        EnableDirectTransfersInInventorySetup();

        // [GIVEN] Locations "From" and "To".
        CreateLocations(LocationFromCode, LocationToCode);

        // [GIVEN] Post inventory with lot no. "L" to location "From".
        LibraryItemTracking.CreateLotItem(Item);
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, Item."No.", LocationFromCode, '', LibraryRandom.RandIntInRange(10, 20));
        LibraryItemTracking.CreateItemJournalLineItemTracking(
          ReservationEntry, ItemJournalLine, '', LotNo, ItemJournalLine."Quantity (Base)");
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create direct transfer "From" -> "To", select lot no. "L".
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFromCode, LocationToCode, '');
        TransferHeader.Validate("Direct Transfer", true);
        TransferHeader.Modify(true);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", LibraryRandom.RandInt(10));
        LibraryItemTracking.CreateTransferOrderItemTracking(
          ReservationEntry, TransferLine, '', LotNo, TransferLine."Quantity (Base)");

        // [WHEN] Post the direct transfer.
        LibraryInventory.PostDirectTransferOrder(TransferHeader);

        // [THEN] The direct transfer is successfully posted.
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.", "Item Ledger Entry Type"::Transfer, LocationToCode, true);
        ItemLedgerEntry.TestField("Lot No.", LotNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferOrderCreateInboundWhseRequestShipAgentServCode()
    var
        TransferHeader: Record "Transfer Header";
        WarehouseRequest: Record "Warehouse Request";
        WhseTransferRelease: Codeunit "Whse.-Transfer Release";
        ShippingAgentCode: Code[10];
        ShippingAgentServiceCode: Code[10];
    begin
        // [SCENARIO 428923] Shipping Agent Service Code value is saved when Inbound Whse Request created from Transfer Order
        Initialize();

        // [GIVEN] Transfer Order "T".
        MockTransferOrder(TransferHeader);

        // [GIVEN] Create Shipping Agent with service code "SC"
        CreateShippingAgentServiceCodeWith1YShippingTime(ShippingAgentCode, ShippingAgentServiceCode);

        // [GIVEN] Set Transfer Header Shipping Agent Code and Shipping Agent Service Code = "SC"
        TransferHeader.Validate("Shipping Agent Code", ShippingAgentCode);
        TransferHeader.Validate("Shipping Agent Service Code", ShippingAgentServiceCode);
        TransferHeader.Modify();

        // [GIVEN] No inbound warehouse requests exist for "T".
        // [GIVEN] Creation of warehouse request is set to be invoked not from the transfer order (i.e. on posting the transfer shipment).
        WhseTransferRelease.SetCallFromTransferOrder(false);

        // [WHEN] Create inbound warehouse request for "T".
        WhseTransferRelease.InitializeWhseRequest(WarehouseRequest, TransferHeader, TransferHeader.Status);
        WhseTransferRelease.CreateInboundWhseRequest(WarehouseRequest, TransferHeader);

        // [THEN] New inbound warehouse request for "T" is created, Shipping Agent Service Code = "SC".
        FilterWhseRequest(
              WarehouseRequest, WarehouseRequest.Type::Inbound, TransferHeader."Transfer-to Code", 1, TransferHeader."No.");
        WarehouseRequest.FindFirst();
        WarehouseRequest.TestField("Shipping Agent Service Code", ShippingAgentServiceCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferOrderCreateOutboundWhseRequestShipAgentServCode()
    var
        TransferHeader: Record "Transfer Header";
        WarehouseRequest: Record "Warehouse Request";
        WhseTransferRelease: Codeunit "Whse.-Transfer Release";
        ShippingAgentCode: Code[10];
        ShippingAgentServiceCode: Code[10];
    begin
        // [SCENARIO 428923] Shipping Agent Service Code value is saved when Outbound Whse Request created from Transfer Order
        Initialize();

        // [GIVEN] Transfer Order "T".
        MockTransferOrder(TransferHeader);

        // [GIVEN] Create Shipping Agent with service code "SC"
        CreateShippingAgentServiceCodeWith1YShippingTime(ShippingAgentCode, ShippingAgentServiceCode);

        // [GIVEN] Set Transfer Header Shipping Agent Code and Shipping Agent Service Code = "SC"
        TransferHeader.Validate("Shipping Agent Code", ShippingAgentCode);
        TransferHeader.Validate("Shipping Agent Service Code", ShippingAgentServiceCode);
        TransferHeader.Modify();

        // [GIVEN] No inbound warehouse requests exist for "T".
        // [GIVEN] Creation of warehouse request is set to be invoked not from the transfer order (i.e. on posting the transfer shipment).
        WhseTransferRelease.SetCallFromTransferOrder(false);

        // [WHEN] Create outbound warehouse request for "T".
        WhseTransferRelease.InitializeWhseRequest(WarehouseRequest, TransferHeader, TransferHeader.Status);
        WhseTransferRelease.CreateOutboundWhseRequest(WarehouseRequest, TransferHeader);

        // [THEN] New outbound warehouse request for "T" is created, Shipping Agent Service Code = "SC".
        FilterWhseRequest(
              WarehouseRequest, WarehouseRequest.Type::Outbound, TransferHeader."Transfer-from Code", 0, TransferHeader."No.");
        WarehouseRequest.FindFirst();
        WarehouseRequest.TestField("Shipping Agent Service Code", ShippingAgentServiceCode);
    end;

    [Test]
    procedure PostTransferOrderWithCommentLine();
    var
        Location: array[3] of Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: array[2] of Record "Transfer Line";
        Item: Record Item;
        DescriptionText: Text[100];
    begin
        // [SCENARIO 455861] Intransit Transfer Order shipped with blocked item on a previously shipped line
        Initialize();

        // [GIVEN] Locations "L1" and "L2". "L1" Code field contains special characters, that are used in filters.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[1]);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[2]);

        // [GIVEN] An intransit location if it is not a direct transfer
        LibraryWarehouse.CreateInTransitLocation(Location[3]);

        // [GIVEN] Item with stock at Location "L1".
        CreateItemWithPositiveInventory(Item, Location[1].Code, 10);

        // [GIVEN] Transfer Order From = "L1" To = "L2". Intransit is "L3" (which is empty on direct transfer)
        LibraryInventory.CreateTransferHeader(TransferHeader, Location[1].Code, Location[2].Code, Location[3].Code);
        TransferHeader.VALIDATE("Direct Transfer", false);
        TransferHeader.Modify();

        // [GIVEN] Create Comment transfer line and one Item Line
        DescriptionText := LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(TransferLine[2].Description), 0);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine[1], Item."No.", 1);
        CreateCommentTransferLine(TransferHeader, TransferLine[2], DescriptionText);

        // [THEN] Post transfer Order
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);  // Ship and receive

        // [VERIFY] Verify posted transfer shipment and receipt has comment line posted.
        VerifyPostedTransferShipment(TransferHeader."No.", 2);
        VerifyPostedTransferReceipt(TransferHeader."No.", 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferOrderAddMultipleItems()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemsFilter: Text;
        NoOfLines: Integer;
    begin
        // [SCENARIO] Add multiple items using action Add Items
        Initialize();

        // [GIVEN] Transfer Order exists
        CreateTransferOrder(TransferHeader, TransferLine);

        // [GIVEN] Items exist
        NoOfLines := GetItemsFilter(ItemsFilter);

        // [WHEN] Multiple items should be added to the transfer order
        TransferLine.AddItems(ItemsFilter);

        // [THEN] All items were added
        TransferLine.SetRange("Document No.", TransferLine."Document No.");
        TransferLine.SetFilter("Line No.", '>%1', TransferLine."Line No.");
        Assert.RecordCount(TransferLine, NoOfLines);

        Item.SetFilter("No.", ItemsFilter);
        Item.FindSet();
        repeat
            TransferLine.SetRange("Item No.", Item."No.");
            Assert.RecordCount(TransferLine, 1);
        until Item.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ItemListModalPageHandler')]
    procedure SelectActiveItemsForTransfer()
    var
        Item: Record Item;
        ItemList: Page "Item List";
    begin
        // [SCENARIO] Only Inventory Items are available for add multiple items in transfers
        Initialize();

        // [GIVEN] Non-inventory and service items exist
        LibraryInventory.CreateNonInventoryTypeItem(Item);
        LibraryInventory.CreateServiceTypeItem(Item);

        // [WHEN] Item Selection page for adding multiple items is run
        ItemList.SelectActiveItemsForTransfer();

        // [THEN] ItemListModalPageHandler is called & checks within ItemListModalPageHandler are run
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,ItemTrackingLinesModalPageHandlerGeneric,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure UndoTransShptLineWhenLocationMandatory()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferShipmentLine: Record "Transfer Shipment Line";
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
    begin
        // [SCENARIO 473641] Posted Transfer Shipment and using Line > Undo Shipment generates an error and does not process the Undo correctly - 
        // "New Location Code must have a value..."
        Initialize();

        // [GIVEN] Set Location Mandatory on Inventory Setup
        InventorySetup.Get();
        InventorySetup.Validate("Location Mandatory", true);
        InventorySetup.Modify();

        // [GIVEN] Create Transfer Order
        CreateTransferOrderHeader(TransferHeader);

        // [GIVEN] Create Item with Serial No. Tracking
        LibraryItemTracking.CreateSerialItem(Item);

        // [GIVEN] Create Inventory of Item x.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", TransferHeader."Transfer-from Code", '', 3);
        LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialNo);
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create Transfer Order Line with Item Quantity 1
        CreateTransferOrderLineAndAssignTracking(TransferHeader, TransferLine, Item."No.", 1, 0);

        // [GIVEN] Create Transfer Shipment
        ShipSingleTransferLine(TransferLine, 1);

        // [WHEN] Undo Transfer Shipment
        TransferShipmentLine.SetFilter("Transfer Order No.", TransferHeader."No.");
        TransferShipmentLine.FindFirst();
        LibraryInventory.UndoTransferShipmentLinesInFilter(TransferShipmentLine);

        // [VERIFY] Verify Transfer Line has been updated correctly to the state it was in before posting
        VerifyTransLineUnshipped(TransferLine);
    end;

    [Test]
    [HandlerFunctions('CreateInvtPickRequestPageHandler,MessageHandler')]
    procedure S453705_PostingDirectTransferOrderviaInventoryPutAway()
    var
        Item: Record Item;
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        ItemJournalLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        DirectTransHeader: Record "Direct Trans. Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        LocationFromCode: Code[10];
        LocationToCode: Code[10];
    begin
        // [FEATURE] [Direct Transfer] [Inventory Put-Away]
        // [SCENARIO 453705] Posting Direct Transfer order via Inventory Put-Away.
        Initialize();

        // [GIVEN] Enable direct transfers in Inventory Setup.
        EnableDirectTransfersInInventorySetup();

        // [GIVEN] Create locations "From" and "To". "To" is a put-away Location.
        CreateLocations(LocationFromCode, LocationToCode);
        Location.Get(LocationToCode);
        Location.Validate("Require Put-away", true);
        Location.Modify();

        // [GIVEN] Set up warehouse employee for "To" location.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationToCode, false);

        // [GIVEN] Post inventory with item "I" to location "From".
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", LocationFromCode, '', LibraryRandom.RandIntInRange(10, 20));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create direct transfer "From" -> "To" for Item "I".
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFromCode, LocationToCode, '');
        TransferHeader.Validate("Direct Transfer", true);
        TransferHeader.Modify(true);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", LibraryRandom.RandInt(10));

        // [GIVEN] Release the transfer order.
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
        Commit();

        // [GIVEN] Create inventory put-away for the transfer order.
        TransferHeader.CreateInvtPutAwayPick();

        // [WHEN] Post inventory put-away.
        LibraryWarehouse.FindWhseActivityBySourceDoc(WarehouseActivityHeader, Database::"Transfer Line", 1, TransferHeader."No.", TransferLine."Line No.");
        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, true);

        // [THEN] The direct transfer is successfully posted.
        // [THEN] 1. Transfer Header is deleted
        TransferHeader.SetRange("No.", TransferLine."Document No.");
        Assert.RecordCount(TransferHeader, 0);

        // [THEN] 2. There is Direct Transfer Heder
        DirectTransHeader.SetRange("Transfer Order No.", TransferLine."Document No.");
        Assert.RecordCount(DirectTransHeader, 1);

        // [THEN] 3. There is Item Ledger Entry for the transfer.
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.", "Item Ledger Entry Type"::Transfer, LocationToCode, true);
        ItemLedgerEntry.TestField("Quantity", TransferLine."Quantity (Base)");
    end;

    [Test]
    procedure DimensionShortcutsOnPostedTransferShipmentReceiptSubforms()
    var
        Item: Record Item;
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        Location: array[3] of Record Location;
        ItemJournalLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        PostedTransferShipment: TestPage "Posted Transfer Shipment";
        PostedTranferReceipt: TestPage "Posted Transfer Receipt";
    begin
        // [FEATURE] [Transfer Shipment] [Transfer Receipt] [Dimension]
        // [SCENARIO 498094] Dimension shortcuts are properly updated on posted transfer shipment and receipt subform pages.
        Initialize();

        // [GIVEN] Create dimension and set it as a Shortcut Dimension 8 Code in General Ledger Setup.
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryERM.SetShortcutDimensionCode(8, DimensionValue."Dimension Code");

        // [GIVEN] Item "I" with the dimension.
        LibraryInventory.CreateItem(Item);
        LibraryDimension.CreateDefaultDimensionItem(
          DefaultDimension, Item."No.", DimensionValue."Dimension Code", DimensionValue.Code);

        // [GIVEN] Locations "A", "B", and in-transit location.
        LibraryWarehouse.CreateTransferLocations(Location[1], Location[2], Location[3]);

        // [GIVEN] Post inventory adjustment of "I" to location "A".
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, Item."No.", Location[1].Code, '', LibraryRandom.RandIntInRange(10, 20));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create transfer order from "A" to "B".
        LibraryWarehouse.CreateTransferHeader(TransferHeader, Location[1].Code, Location[2].Code, Location[3].Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", LibraryRandom.RandInt(10));

        // [WHEN] Ship and receive the transfer order.
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        // [THEN] Shortcut Dimension 8 Code is filled in on the posted transfer shipment subform.
        PostedTransferShipment.OpenView();
        PostedTransferShipment.Filter.SetFilter("Transfer-from Code", Location[1].Code);
        PostedTransferShipment.TransferShipmentLines.Filter.SetFilter("Item No.", Item."No.");
        PostedTransferShipment.TransferShipmentLines.ShortcutDimCode8.AssertEquals(DimensionValue.Code);
        PostedTransferShipment.Close();

        // [THEN] Shortcut Dimension 8 Code is filled in on the posted transfer receipt subform.
        PostedTranferReceipt.OpenView();
        PostedTranferReceipt.Filter.SetFilter("Transfer-to Code", Location[2].Code);
        PostedTranferReceipt.TransferReceiptLines.Filter.SetFilter("Item No.", Item."No.");
        PostedTranferReceipt.TransferReceiptLines.ShortcutDimCode8.AssertEquals(DimensionValue.Code);
        PostedTranferReceipt.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure AdjustCostOfUndoneTransferShipment()
    var
        Item: Record Item;
        InTransitLocation: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemLedgerEntryNo: Integer;
        LocationFromCode, LocationTOCode : Code[10];
        OldCost, NewCost : Decimal;
    begin
        // [FEATURE] [Transfer] [Undo Shipment] [Costing] [Adjust Cost - Item Entries]
        // [SCENARIO 496575] Item ledger entry for undone transfer shipment is adjusted with the correct cost.
        Initialize();
        OldCost := LibraryRandom.RandDec(100, 2);
        NewCost := LibraryRandom.RandDecInDecimalRange(101, 200, 2);

        // [GIVEN] Item "I".
        // [GIVEN] Locations "From" and "To".
        LibraryInventory.CreateItem(Item);
        CreateLocations(LocationFromCode, LocationToCode);
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);

        // [GIVEN] Post inventory adjustment of "I" to location "From". Unit Cost = 10.
        CreateAndPostItemJnlWithCostLocationVariant(
          "Item Ledger Entry Type"::"Positive Adjmt.", Item."No.", 1, OldCost, LocationFromCode, '');
        ItemLedgerEntryNo := FindLastILENo(Item."No.");

        // [GIVEN] Create transfer order from "From" to "To".
        // [GIVEN] Ship the transfer order.
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFromCode, LocationToCode, InTransitLocation.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 1);
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);

        // [GIVEN] Revaluate the item entry for the inventory adjustment, new cost = 12.
        CreateAndPostRevaluationJournal(Item."No.", ItemLedgerEntryNo, 1, NewCost);

        // [GIVEN] Adjust cost.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [WHEN] Undo the transfer shipment and run the cost adjustment.
        LibraryInventory.UndoTransferShipments(TransferHeader."No.");
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] Unit cost of "I" = 12.
        Item.Find();
        Item.TestField("Unit Cost", NewCost);

        // [THEN] Item ledger entry for the undone transfer shipment is adjusted. Unit Cost = 12.
        ItemLedgerEntry.Get(FindLastILENo(Item."No."));
        ItemLedgerEntry.TestField("Entry Type", ItemLedgerEntry."Entry Type"::Transfer);
        ItemLedgerEntry.TestField("Location Code", LocationFromCode);
        ItemLedgerEntry.TestField(Positive, true);
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        ItemLedgerEntry.TestField("Cost Amount (Actual)", NewCost);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('PostedPurchaseReceiptsModalPageHandler,PostedPurchRcptLinesModalPageHandler')]
    procedure GetReceiptLinesShowListOfPostedPurchRcptsHavingTransferFromCodeInLocationCodeOfPurchRcptLines()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        Location: Record Location;
        Location2: Record Location;
        Location3: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseHeader3: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        PurchaseLine3: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemLedgerEntryNo: Integer;
        PurchaseReceiptNo: Code[20];
        TransferOrder: TestPage "Transfer Order";
    begin
        // [SCENARIO 500597] Get Receipt Lines action on Transfer Order shows list of Posted Purchase Receipts having Transfer-from Code in Location Code of Purch Rcpt Lines and after selecting it populates Appl-to Item Entry field in Transfer Lines.
        Initialize();

        // [GIVEN] Create an Item and Validate Costing Method.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::FIFO);
        Item.Modify(true);

        // [GIVEN] Create two Locations with Inventory Posting Setup.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location2);

        // [GIVEN] Create another Location with Inventory Posting Setup 
        // And Validate Use As In-Transit.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location3);
        Location3.Validate("Use As In-Transit", true);
        Location3.Modify(true);

        // [GIVEN] Create a Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create and Post Purchase Receipt with Location Code on Header.
        CreateAndPostPurchRcptWithLocationCodeInPurchHeader(PurchaseHeader, PurchaseLine, Vendor, Item, Location);

        // [GIVEN] Create and Post Purchase Receipt 2 with Location Code on Header.
        CreateAndPostPurchRcptWithLocationCodeInPurchHeader(PurchaseHeader2, PurchaseLine2, Vendor, Item, Location);

        // [GIVEN] Create and Post Purchase Receipt 3 with Location Code on Line.
        PurchaseReceiptNo := CreateAndPostPurchRcptWithLocationCodeInPurchLine(
            PurchaseHeader3,
            PurchaseLine3,
            Vendor,
            Item,
            Location);

        // [GIVEN] Find and save Item Ledger Entry No. in a Variable.
        ItemLedgerEntry.SetRange("Document No.", PurchaseReceiptNo);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntryNo := ItemLedgerEntry."Entry No.";

        // [GIVEN] Find Purch. Rcpt Line.
        FindRandomReceiptLine(PurchaseReceiptNo, PurchRcptLine);

        // [GIVEN] Create Transfer Header.
        LibraryInventory.CreateTransferHeader(TransferHeader, Location.Code, Location2.Code, Location3.Code);

        // [GIVEN] Open Transfer Order page and run Get Receipt Line action.
        TransferOrder.OpenEdit();
        TransferOrder.GoToRecord(TransferHeader);
        LibraryVariableStorage.Enqueue(PurchaseReceiptNo);
        LibraryVariableStorage.Enqueue(PurchaseReceiptNo);
        LibraryVariableStorage.Enqueue(PurchRcptLine."No.");
        TransferOrder.GetReceiptLines.Invoke();

        // [WHEN] Find Transfer Line.
        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.FindFirst();

        // [VERIFY] Appl-to Item Entry and Item Ledger Entry No. are same.
        Assert.AreEqual(
            ItemLedgerEntryNo,
            TransferLine."Appl.-to Item Entry",
            StrSubstNo(
                ApplToItemEntryErr,
                TransferLine.FieldCaption("Appl.-to Item Entry"),
                ItemLedgerEntryNo,
                TransferLine.TableCaption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferPostingNotAllowedForDirectTransferWithDifferentQtyShipAndReceive()
    var
        Location: array[2] of Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: array[3] of Record "Transfer Line";
        Item: array[3] of Record Item;
        InventorySetup: Record "Inventory Setup";
    begin
        // [SCENARIO] Transfer posting is not allowed for Direct Transfer Orders where 'Qty. to Ship' and 'Qty. to Receive' are different.
        // https://dynamicssmb2.visualstudio.com/Dynamics%20SMB/_workitems/edit/502987
        Initialize();

        // [GIVEN] Inventory Setup is configured for "Direct Transfer Posting" = "Receipt and Shipment"
        InventorySetup.Get();
        InventorySetup.Validate("Direct Transfer Posting", InventorySetup."Direct Transfer Posting"::"Receipt and Shipment");
        InventorySetup.Modify();

        // [GIVEN] Locations "L1" and "L2".
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[1]);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[2]);

        // [GIVEN] Item with stock at Location "L1".
        CreateItemWithPositiveInventory(Item[1], Location[1].Code, 10);
        CreateItemWithPositiveInventory(Item[2], Location[1].Code, 10);
        CreateItemWithPositiveInventory(Item[3], Location[1].Code, 10);

        // [GIVEN] Transfer Order From = "L1" To = "L2". Intransit is empty on direct transfer.
        LibraryInventory.CreateTransferHeader(TransferHeader, Location[1].Code, Location[2].Code, '');
        TransferHeader.Validate("Direct Transfer", true);
        TransferHeader.Modify();

        // [GIVEN] Three transfer lines - one will not be posted yet
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine[1], Item[1]."No.", 1);
        TransferLine[1].Validate("Qty. to Ship", 0);
        TransferLine[1].Validate("Qty. to Receive", 0);
        TransferLine[1].Modify(true);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine[2], Item[2]."No.", 2);
        TransferLine[2].Validate("Qty. to Ship", 1);
        TransferLine[2].Validate("Qty. to Receive", 1);
        TransferLine[2].Modify(true);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine[3], Item[2]."No.", 3);
        TransferLine[3].Validate("Qty. to Ship", 3);
        TransferLine[3].Validate("Qty. to Receive", 3);
        TransferLine[3].Modify(true);

        // [GIVEN] One line of the transfer order is posted
        LibraryInventory.PostTransferHeader(TransferHeader, true, true); //Ship and receive

        // [GIVEN] On line 2, change the Qty. to Ship to 2 and Qty. to Receive to 0.
        TransferLine[2].Find();
        TransferLine[2].Validate("Qty. to Ship", 1);
        TransferLine[2].Validate("Qty. to Receive", 0);
        TransferLine[2].Modify(true);

        // [WHEN] Transfer Order is posted.
        asserterror CODEUNIT.Run(CODEUNIT::"TransferOrder-Post (Yes/No)", TransferHeader); //Ship and receive

        // [THEN] Error is shown that posting is not allowed.
        Assert.ExpectedError('The quantity to ship and quantity to receive must be equal in a direct transfer.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ItemTrackingLinesModalPageHandlerGeneric,CreateInvtPickPutAwayRequestPageHandler,ConfirmHandlerYes')]
    procedure InvPutAwayIsPostedFromTransferOrderHavingLotAndSerialTracking()
    var
        Item: Record Item;
        Location, Location2, Location3 : Record Location;
        Bin: Record Bin;
        Vendor: Record Vendor;
        WarehouseEmployee: Record "Warehouse Employee";
        ItemTrackingCode: Record "Item Tracking Code";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        InventoryPutawayPage: TestPage "Inventory Put-away";
        LotNo, LotNo2 : Code[20];
    begin
        // [SCENARIO 498778] Inventory Put-away created from a Transfer Order having Lot and Serial Tracking is posted without any error.
        Initialize();

        // [GIVEN] Create Location and Validate Put-away Bin Policy, Always Create Put-away Line and Pick According to FEFO.
        LibraryWarehouse.CreateLocationWMS(Location, true, true, true, false, false);
        Location.Validate("Put-away Bin Policy", Location."Put-away Bin Policy"::"Default Bin");
        Location.Validate("Always Create Put-away Line", true);
        Location.Validate("Pick According to FEFO", true);
        Location.Modify();

        // [GIVEN] Create Location 2.
        LibraryWarehouse.CreateLocationWMS(Location2, false, true, false, false, false);

        // [GIVEN] Create Bin.
        LibraryWarehouse.CreateBin(Bin, Location.Code, Bin.Code, '', '');

        // [GIVEN] Create In Transit Location 3.
        LibraryWarehouse.CreateInTransitLocation(Location3);

        // [GIVEN] Create Item Tracking code and Validate Use Expiration Dates, Man. Expir. Date Entry Reqd.
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, true);
        ItemTrackingCode.Validate("Use Expiration Dates", true);
        ItemTrackingCode.Validate("Man. Expir. Date Entry Reqd.", true);
        ItemTrackingCode.Modify(true);

        // [GIVEN] Create Warehouse Employees for Location and Location 2.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location2.Code, false);

        // [GIVEN] Create Item and Validate Item Tracking Code.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify(true);

        // [GIVEN] Create Purchase Header and Validate Location Code.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.Validate("Location Code", Location.Code);
        PurchaseHeader.Modify(true);

        // [GIVEN] Create Purchase Line.
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(5, 5));

        // [GIVEN] Generate and save Lot No and Lot No 2 in two different Variables.
        LotNo := LibraryUtility.GenerateGUID();
        LotNo2 := LibraryUtility.GenerateGUID();

        // [GIVEN] Open Item Tracking Lines page.
        LibraryVariableStorage.Enqueue(TrackingOption::AssignManualLotNos);
        LibraryVariableStorage.Enqueue(PurchaseLine.Quantity);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(LotNo2);
        PurchaseLine.OpenItemTrackingLines();

        // [GIVEN] Releases Purchase Order.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Create Inventory Put-away.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Purchase Order", PurchaseHeader."No.", true, false, false);

        // [GIVEN] Find Warehouse Activity Header.
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        WarehouseActivityHeader.FindFirst();

        // [GIVEN] Find and update Purchase Put-away Warehouse Activity Line.
        FindAndUpdatePurchPutAwayWarehouseActivityLine(WarehouseActivityLine, Item, Bin);

        // [GIVEN] Post Inventory Put-away.
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [GIVEN] Create Transfer Order.
        LibraryInventory.CreateTransferHeader(TransferHeader, Location.Code, Location2.Code, Location3.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", LibraryRandom.RandIntInRange(5, 5));

        // [GIVEN] Releases Transfer Order.
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
        Commit();

        // [GIVEN] Create Inventory Pick.
        LibraryVariableStorage.Enqueue(true);
        TransferHeader.CreateInvtPutAwayPick();

        // [GIVEN] Find Warehouse Activity Header.
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        WarehouseActivityHeader.FindFirst();

        // [GIVEN] Find and update Transfer Pick Warehouse Activity Line.
        FindAndUpdateTransferPickWarehouseActivityLine(WarehouseActivityLine, Item);

        // [GIVEN] Post Inventory Pick.
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [GIVEN] Create Inventory Put-away.
        LibraryVariableStorage.Enqueue(false);
        TransferHeader.CreateInvtPutAwayPick();

        // [GIVEN] Find Warehouse Activity Header.
        WarehouseActivityHeader.SetRange("Location Code", Location2.Code);
        WarehouseActivityHeader.FindFirst();

        // [GIVEN] Find and update Transfer Put-away Warehouse Activity line.
        FindAndUpdateTransferPutAwayWarehouseActivityLine(WarehouseActivityLine, Item);

        // [GIVEN] Open Inventory Put-away page and run Post action.
        InventoryPutawayPage.OpenEdit();
        InventoryPutawayPage.GoToRecord(WarehouseActivityHeader);
        InventoryPutawayPage."P&ost".Invoke();

        // [WHEN] Find Item Ledger Entry.
        ItemLedgerEntry.SetRange("Location Code", Location2.Code);
        ItemLedgerEntry.FindFirst();

        // [THEN] Item Ledger is found.
        Assert.IsFalse(ItemLedgerEntry.IsEmpty(), '');
    end;

    [Test]
    procedure ReleasingOfTransferOrderHavingTransferLineWithoutUOMGivesError()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
    begin
        // [SCENARIO 522444] When run Release action from a Transfer Order having a Transfer Line without 
        // Unit of Measure Code, then it gives error and the document is not released.
        Initialize();

        // [GIVEN] Create a Transfer Order.
        CreateTransferOrder(TransferHeader, TransferLine);

        // [WHEN] Validate Unit of Measure Code in Transfer Line.
        TransferLine.Validate("Unit of Measure Code", '');
        TransferLine.Modify(true);

        // [THEN] Error is shown and the Transfer Order is not released.
        asserterror LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure ForwardingCostToUndoTransferShipment()
    var
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        LocationA, LocationB, InTransitLocation : Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemChargePurchaseLine: Record "Purchase Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemLedgerEntry, OriginalTransferShipmentILE, UndoTransferShipmentILE : Record "Item Ledger Entry";
        Qty: Decimal;
        ItemUnitCost, ItemChargeUnitCost : Decimal;
    begin
        // [SCENARIO 592047] Cost forwarding to undo transfer shipment - verify that item ledger entry for undo has the same cost as original transfer shipment.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(5, 10);
        ItemUnitCost := LibraryRandom.RandDecInRange(10, 100, 2);
        ItemChargeUnitCost := LibraryRandom.RandDecInRange(100, 500, 2);

        // [GIVEN] Locations A, B, and In-Transit are set up
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationA);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationB);
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);

        // [GIVEN] An item and item charge are created
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemCharge(ItemCharge);

        // [GIVEN] Purchase order for item and item charge to location A
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Location Code", LocationA.Code);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader, Item."No.", Qty, ItemUnitCost);
        LibraryPurchase.CreatePurchaseLine(ItemChargePurchaseLine, PurchaseHeader, ItemChargePurchaseLine.Type::"Charge (Item)", ItemCharge."No.", 1);
        ItemChargePurchaseLine.Validate("Direct Unit Cost", ItemChargeUnitCost);
        ItemChargePurchaseLine.Modify(true);
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, ItemChargePurchaseLine, ItemChargeAssignmentPurch."Applies-to Doc. Type"::Order, PurchaseLine."Document No.",
          PurchaseLine."Line No.", PurchaseLine."No.");

        // [GIVEN] Purchase order is posted
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] First cost adjustment is run
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [GIVEN] Transfer order is created from location A to location B
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationA.Code, LocationB.Code, InTransitLocation.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", Qty);

        // [GIVEN] Transfer shipment is posted
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);

        // [GIVEN] Second cost adjustment is run after transfer shipment
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [GIVEN] Find and store the original transfer shipment item ledger entry for cost comparison
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Transfer);
        ItemLedgerEntry.SetRange("Location Code", LocationA.Code);
        ItemLedgerEntry.SetRange(Positive, false);
        ItemLedgerEntry.FindFirst();
        OriginalTransferShipmentILE := ItemLedgerEntry;

        // [WHEN] Transfer shipment is undone.
        LibraryInventory.UndoTransferShipments(TransferHeader."No.");

        // [THEN] Final cost adjustment is run after undo.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] Find the undo transfer shipment item ledger entry.
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Transfer);
        ItemLedgerEntry.SetRange("Location Code", LocationA.Code);
        ItemLedgerEntry.SetRange(Positive, true);
        ItemLedgerEntry.SetRange(Correction, true);
        ItemLedgerEntry.FindFirst();
        UndoTransferShipmentILE := ItemLedgerEntry;

        // [THEN] Verify that the undo transfer shipment has the same cost as the original transfer shipment
        OriginalTransferShipmentILE.CalcFields("Cost Amount (Actual)");
        UndoTransferShipmentILE.CalcFields("Cost Amount (Actual)");
        Assert.AreEqual(
            -OriginalTransferShipmentILE."Cost Amount (Actual)",
            UndoTransferShipmentILE."Cost Amount (Actual)",
            'The cost amount of the undo transfer shipment entry should match the original transfer shipment entry (with opposite sign)');
    end;

    [Test]
    procedure ReleaseTransferOrderWhenVariantMandatory()
    var
        InTransitLocation: Record Location;
        Item: Record Item;
        ItemVariant: array[2] of Record "Item Variant";
        FromLocation: Record Location;
        ToLocation: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
    begin
        // [SCENARIO 601487] Release Transfer Order when Variant Mandatory in Inventory Setup.
        Initialize();

        // [GIVEN] Create From/To Locations and InTransit Location
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(FromLocation);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);

        // [GIVEN] Create Item and two Variants
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant[1], Item."No.");
        LibraryInventory.CreateItemVariant(ItemVariant[2], Item."No.");

        // [GIVEN] Set Inventory Setup to require variant if exists
        SetVariantMandatoryInInventorySetup();

        // [GIVEN] Create Transfer Order and Line.
        LibraryInventory.CreateTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", LibraryRandom.RandIntInRange(10, 100));

        // [WHEN] Try to release the transfer order
        asserterror LibraryWarehouse.ReleaseTransferOrder(TransferHeader);

        // [THEN] Assert error matches expected label
        Assert.ExpectedError(
            StrSubstNo(
                VariantCodeMandatoryErr,
                TransferLine.FieldCaption("Variant Code"), TransferLine.TableCaption(),
                TransferLine."Document No.", TransferLine."Line No."));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Transfers");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Transfers");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateInventoryPostingSetup();

        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        LibrarySetupStorage.SaveGeneralLedgerSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Transfers");
    end;

    local procedure CreateLotTrackedItem(var Item: Record Item; WMSSpecific: Boolean)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateLotItem(Item);
        if not WMSSpecific then begin
            ItemTrackingCode.Get(Item."Item Tracking Code");
            ItemTrackingCode.Validate("Lot Warehouse Tracking", false);
            ItemTrackingCode.Modify(true);
        end;
    end;

    local procedure PlanningCombineTransfers(var LocationCode: array[3] of Code[10]; Combine: Boolean)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        Initialize();
        CreateTransferRouteSetup(LocationCode);
        MockReqTransferOrderLines(RequisitionLine, LocationCode);
        RunRequisitionCarryOutReport(RequisitionLine, Combine);
    end;

    local procedure UpdateSalesReceivablesSetup()
    begin
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibrarySales.SetStockoutWarning(false);
    end;

    local procedure PrepareSimpleTransferOrderWithTwoLines(var TransferHeader: Record "Transfer Header"; var TransferLine: array[2] of Record "Transfer Line")
    var
        Location: array[3] of Record Location;
        i: Integer;
    begin
        for i := 1 to 2 do
            LibraryWarehouse.CreateLocation(Location[i]);
        LibraryWarehouse.CreateInTransitLocation(Location[3]);

        LibraryWarehouse.CreateTransferHeader(TransferHeader, Location[1].Code, Location[2].Code, Location[3].Code);
        for i := 1 to ArrayLen(TransferLine) do
            LibraryWarehouse.CreateTransferLine(
              TransferHeader, TransferLine[i], LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(10, 20));
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        // Random values used are not important for test.
        LibraryManufacturing.CreateItemManufacturing(
          Item, Item."Costing Method", LibraryRandom.RandDec(50, 2) + LibraryRandom.RandDec(10, 2),
          Item."Reordering Policy"::Order, Item."Flushing Method", '', '');
        Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Order");
        Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking Only");
        Item.Modify(true);
    end;

    local procedure CreateLocations(var LocationFromCode: Code[10]; var LocationToCode: Code[10])
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
    begin
        LocationFromCode := LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationFrom);
        LocationToCode := LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);
    end;

    local procedure CreateUpdateLocations()
    var
        Location: Record Location;
        HandlingTime: DateFormula;
        HandlingTime2: DateFormula;
        k: Integer;
    begin
        // Values Used are important for Test.
        Evaluate(HandlingTime, '<1D>');
        Evaluate(HandlingTime2, '<0D>');

        for k := 1 to 5 do begin
            LibraryWarehouse.CreateLocation(Location);
            LocationCode[k] := Location.Code;
        end;

        // Update Locations.
        for k := 2 to 4 do
            UpdateLocation(LocationCode[k], false, HandlingTime2, HandlingTime2);

        UpdateLocation(LocationCode[1], false, HandlingTime, HandlingTime2);
        UpdateLocation(LocationCode[5], true, HandlingTime2, HandlingTime2);
    end;

    local procedure CreateAndPostRevaluationJournal(ItemNo: Code[20]; AppliesToEntry: Integer; InventoryValueRevalued: Decimal; UnitCostRevalued: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Revaluation);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::" ", ItemNo, 0);
        ItemJournalLine.Validate("Value Entry Type", ItemJournalLine."Value Entry Type"::Revaluation);
        ItemJournalLine.Validate("Applies-to Entry", AppliesToEntry);
        ItemJournalLine.Validate("Inventory Value (Revalued)", InventoryValueRevalued);
        ItemJournalLine.Validate("Unit Cost (Revalued)", UnitCostRevalued);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure PostTransferShipmentPartiallyWithBlockedItem(DirectTransfer: Boolean)
    var
        Location: array[3] of Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: array[2] of Record "Transfer Line";
        Item: array[2] of Record Item;
    begin
        // [GIVEN] Locations "L1" and "L2". "L1" Code field contains special characters, that are used in filters.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[1]);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[2]);

        // [GIVEN] An intransit location if it is not a direct transfer
        if not DirectTransfer then
            LibraryWarehouse.CreateInTransitLocation(Location[3]);

        // [GIVEN] Item with stock at Location "L1".
        CreateItemWithPositiveInventory(Item[1], Location[1].Code, 10);
        CreateItemWithPositiveInventory(Item[2], Location[1].Code, 10);

        // [GIVEN] Transfer Order From = "L1" To = "L2". Intransit is "L3" (which is empty on direct transfer)
        LibraryInventory.CreateTransferHeader(TransferHeader, Location[1].Code, Location[2].Code, Location[3].Code);
        TransferHeader.Validate("Direct Transfer", DirectTransfer);
        TransferHeader.Modify();

        // [GIVEN] Two transfer lines - one will not be posted yet
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine[1], Item[1]."No.", 1);
        TransferLine[1].Validate("Qty. to Ship", 0);
        TransferLine[1].Validate("Qty. to Receive", 0);
        TransferLine[1].Modify();
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine[2], Item[2]."No.", 1);

        // [GIVEN] One line of the transfer order is posted
        LibraryInventory.PostTransferHeader(TransferHeader, true, true); //Ship and receive
        TransferHeader.Get(TransferHeader."No.");
        Item[2].Get(Item[2]."No.");

        // [GIVEN] The item which was just posted is now "Blocked" 
        Item[2].Validate(Blocked, true);
        Item[2].Modify();

        // [WHEN] the other line is posted 
        TransferLine[1].Get(TransferLine[1]."Document No.", TransferLine[1]."Line No.");
        TransferLine[1].Validate("Qty. to Ship", 1);
        TransferLine[1].Modify(); //Qty. to receieve gets set to 1 automatically when shipped
        LibraryInventory.PostTransferHeader(TransferHeader, true, true); //Ship and receive

        // [THEN] No error occurs
    end;

    local procedure CreateUpdateStockKeepUnit(var StockkeepingUnit: Record "Stockkeeping Unit"; ItemNo: array[4] of Code[20])
    var
        Item: Record Item;
    begin
        Item.SetRange("No.", ItemNo[1], ItemNo[4]);
        Item.SetRange("Location Filter", LocationCode[1], LocationCode[4]);
        LibraryInventory.CreateStockKeepingUnit(Item, "SKU Creation Method"::Location, false, false);

        // Update Replenishment System in Stock Keeping Unit.
        UpdateStockKeepingUnit(LocationCode[1], ItemNo[4], StockkeepingUnit."Replenishment System"::"Prod. Order", '', '');
        UpdateStockKeepingUnit(LocationCode[4], ItemNo[4], StockkeepingUnit."Replenishment System"::Purchase, '', '');
        UpdateStockKeepingUnit(LocationCode[1], ItemNo[3], StockkeepingUnit."Replenishment System"::Transfer, '', LocationCode[2]);
        UpdateStockKeepingUnit(LocationCode[2], ItemNo[3], StockkeepingUnit."Replenishment System"::"Prod. Order", '', '');
        UpdateStockKeepingUnit(LocationCode[3], ItemNo[3], StockkeepingUnit."Replenishment System"::Purchase, '', '');
        UpdateStockKeepingUnit(LocationCode[4], ItemNo[3], StockkeepingUnit."Replenishment System"::Purchase, '', '');
        UpdateStockKeepingUnit(LocationCode[1], ItemNo[2], StockkeepingUnit."Replenishment System"::Transfer, '', LocationCode[2]);
        UpdateStockKeepingUnit(LocationCode[2], ItemNo[2], StockkeepingUnit."Replenishment System"::Transfer, '', LocationCode[4]);
        UpdateStockKeepingUnit(LocationCode[3], ItemNo[2], StockkeepingUnit."Replenishment System"::Purchase, '', '');
        UpdateStockKeepingUnit(
          LocationCode[4], ItemNo[2], StockkeepingUnit."Replenishment System"::Purchase, LibraryPurchase.CreateVendorNo(), '');
        UpdateStockKeepingUnit(LocationCode[1], ItemNo[1], StockkeepingUnit."Replenishment System"::Purchase, '', '');
        UpdateStockKeepingUnit(LocationCode[2], ItemNo[1], StockkeepingUnit."Replenishment System"::Purchase, '', '');
        UpdateStockKeepingUnit(LocationCode[3], ItemNo[1], StockkeepingUnit."Replenishment System"::Purchase, '', '');
        UpdateStockKeepingUnit(
          LocationCode[4], ItemNo[1], StockkeepingUnit."Replenishment System"::Purchase, LibraryPurchase.CreateVendorNo(), '');
    end;

    local procedure CreateProdBOM(var ProductionBOMHeader: Record "Production BOM Header"; ItemNo: Code[20]; ItemNo2: Code[20]; BaseUnitofMeasure: Code[10]; MultipleBOMLine: Boolean)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, BaseUnitofMeasure);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo, 1);
        if MultipleBOMLine then
            LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo2, 1);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateShippingAgentCodeAndService(var ShippingAgentCode: Code[10]; var ShippingAgentServiceCode: Code[10])
    var
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentServices: Record "Shipping Agent Services";
        ShippingTime: DateFormula;
    begin
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        Evaluate(ShippingTime, StrSubstNo('<%1D>', LibraryRandom.RandInt(10)));
        LibraryInventory.CreateShippingAgentService(ShippingAgentServices, ShippingAgent.Code, ShippingTime);
        ShippingAgentCode := ShippingAgent.Code;
        ShippingAgentServiceCode := ShippingAgentServices.Code;
    end;

    local procedure CreateShippingAgentServices(var ShippingAgent: Record "Shipping Agent"; var ShippingAgentServicesCode: array[6] of Code[10])
    var
        ShippingAgentServices: Record "Shipping Agent Services";
        ShippingTime: DateFormula;
        j: Integer;
    begin
        LibraryInventory.CreateShippingAgent(ShippingAgent);

        for j := 1 to 6 do begin
            Evaluate(ShippingTime, '<' + Format(j) + 'D>');
            LibraryInventory.CreateShippingAgentService(ShippingAgentServices, ShippingAgent.Code, ShippingTime);
            ShippingAgentServicesCode[j] := ShippingAgentServices.Code;
        end;
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        // Random values used are not important for test.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Create Purchase Order with One Item Line. Random values used are not important for test.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure CreateShipmentMethodCode(): Code[10]
    var
        ShipmentMethod: Record "Shipment Method";
    begin
        ShipmentMethod.Init();
        ShipmentMethod.Code := LibraryUtility.GenerateRandomCode(ShipmentMethod.FieldNo(Code), DATABASE::"Shipment Method");
        ShipmentMethod.Insert();
        exit(ShipmentMethod.Code);
    end;

    local procedure CreateTransferRoutes()
    var
        TransferRoute: Record "Transfer Route";
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentServicesCode: array[6] of Code[10];
        i: Integer;
        j: Integer;
        k: Integer;
    begin
        CreateShippingAgentServices(ShippingAgent, ShippingAgentServicesCode);

        // Transfer Route for LocationCode
        k := 1;
        for i := 1 to 4 do
            for j := i + 1 to 4 do begin
                LibraryWarehouse.CreateTransferRoute(TransferRoute, LocationCode[i], LocationCode[j]);
                UpdateTransferRoutes(TransferRoute, ShippingAgentServicesCode[k], ShippingAgent.Code);
                LibraryWarehouse.CreateTransferRoute(TransferRoute, LocationCode[j], LocationCode[i]);
                UpdateTransferRoutes(TransferRoute, ShippingAgentServicesCode[k], ShippingAgent.Code);
                k := k + 1;
            end;
    end;

    local procedure CreateReqLine(var RequisitionLine: Record "Requisition Line")
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        RequisitionWkshName.SetRange("Template Type", RequisitionWkshName."Template Type"::Planning);
        RequisitionWkshName.FindFirst();
        ClearReqWkshBatch(RequisitionWkshName);

        RequisitionLine.Init();
        RequisitionLine.Validate("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.Validate("Journal Batch Name", RequisitionWkshName.Name);
    end;

    local procedure CreateAndPostItemJrnl(EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20];
                                                         Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJrnl(ItemJournalLine, EntryType, ItemNo, Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostItemJnlWithCostLocationVariant(EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20];
                                                                               Qty: Decimal;
                                                                               Cost: Decimal;
                                                                               LocationCode: Code[10];
                                                                               VariantCode: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJrnl(ItemJournalLine, EntryType, ItemNo, Qty);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Variant Code", VariantCode);
        ItemJournalLine.Validate("Unit Cost", Cost);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostWhseShipmentFromTransferOrder(TransferHeader: Record "Transfer Header"; QtyToShip: Decimal)
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        if TransferHeader.Status = TransferHeader.Status::Open then
            LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);

        WarehouseShipmentLine.SetRange("Source Type", DATABASE::"Transfer Line");
        WarehouseShipmentLine.SetRange("Source No.", TransferHeader."No.");
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentLine.Validate("Qty. to Ship", QtyToShip);
        WarehouseShipmentLine.Modify(true);

        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
    end;

    local procedure CreateAndPostWhseReceiptFromTransferOrder(TransferHeader: Record "Transfer Header"; QtyToReceive: Decimal)
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        LibraryWarehouse.CreateWhseReceiptFromTO(TransferHeader);

        FilterWhseReceiptLine(WarehouseReceiptLine, DATABASE::"Transfer Line", TransferHeader."No.");
        WarehouseReceiptLine.FindFirst();
        WarehouseReceiptLine.Validate("Qty. to Receive", QtyToReceive);
        WarehouseReceiptLine.Modify(true);

        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure CreatePostPurchOrder(LocationCode: Code[10]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        i: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Location Code", LocationCode);
        PurchaseHeader.Modify();

        for i := 1 to LibraryRandom.RandIntInRange(3, 5) do
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
              LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(5, 10));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchRcptHeader.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PurchRcptHeader.FindLast();
        exit(PurchRcptHeader."No.");
    end;

    local procedure CreateItemJrnl(var ItemJournalLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20];
                                                                                                   Qty: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Qty);
    end;

    local procedure CreateItemWithPositiveInventory(var Item: Record Item; LocationCode: Code[10]; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJnlWithCostLocationVariant(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Qty, LibraryRandom.RandIntInRange(10, 20), LocationCode, '');
    end;

    local procedure CreateItemWithVariantAndPositiveInventory(var Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemVariant: Record "Item Variant";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateVariant(ItemVariant, Item);
        ItemVariant.Rename(Item."No.", VariantCode);
        CreateAndPostItemJnlWithCostLocationVariant(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Qty, LibraryRandom.RandIntInRange(10, 20), LocationCode, VariantCode);
    end;

    local procedure CreateItemWithPositiveInventoryAndBin(var Item: Record Item; LocationCode: Code[10]; BinCode: Code[20]; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", LocationCode, BinCode, Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateTransferOrderAndInitializeNewTransferLine(var TransferOrder: TestPage "Transfer Order"; ShippingAgentCode: Code[10])
    var
        TransferHeader: Record "Transfer Header";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
    begin
        LibraryWarehouse.CreateLocation(LocationFrom);
        LibraryWarehouse.CreateLocation(LocationTo);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);
        TransferHeader.Validate("Shipping Agent Code", ShippingAgentCode);
        TransferHeader.Modify(true);

        TransferOrder.OpenEdit();
        TransferOrder.FILTER.SetFilter("No.", TransferHeader."No.");
        TransferOrder.TransferLines.New();
        TransferOrder.TransferLines."Item No.".SetValue(LibraryInventory.CreateItemNo());
    end;

    local procedure CreateTransferOrder(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"): Code[20]
    var
        Item: Record Item;
        Location: Record Location;
    begin
        CreateTransferOrderNoRoute(
                TransferHeader,
                TransferLine,
                LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location),
                LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location),
                LibraryInventory.CreateItem(Item),
                '',
                LibraryRandom.RandDecInRange(1, 5, 2)
            );
        exit(TransferHeader."No.");
    end;

    local procedure GetItemsFilter(var ItemFilter: Text): Integer
    var
        Item: Record Item;
        ItemFilterTextBuilder: TextBuilder;
        Counter: Integer;
    begin
        for Counter := 1 to LibraryRandom.RandIntInRange(2, 5) do begin
            if Counter <> 1 then
                ItemFilterTextBuilder.Append('|');
            ItemFilterTextBuilder.Append(LibraryInventory.CreateItem(Item));
        end;
        ItemFilter := ItemFilterTextBuilder.ToText();
        exit(Counter);
    end;

    local procedure CreateTransferOrder(var TransferLine: Record "Transfer Line"; TransferfromCode: Code[10]; TransfertoCode: Code[10]; ItemNo: Code[20]; ReceiptDate: Date; Quantity: Decimal): Code[20]
    var
        TransferHeader: Record "Transfer Header";
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, TransferfromCode, TransfertoCode, LocationCode[5]);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        TransferLine.Validate("Receipt Date", ReceiptDate);
        TransferLine.Validate("Planning Flexibility", TransferLine."Planning Flexibility"::None);
        TransferLine.Modify(true);
        exit(TransferHeader."No.");
    end;

    local procedure CreateTransferOrderNoRoute(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; Qty: Decimal)
    var
        InTransitLocation: Record Location;
    begin
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        LibraryInventory.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, InTransitLocation.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Qty);
        TransferLine.Validate("Variant Code", VariantCode);
        TransferLine.Modify(true);
    end;

    local procedure CreateTransferRouteSetup(var LocationCode: array[3] of Code[10])
    var
        TransferRoute: Record "Transfer Route";
        Location: Record Location;
        i: Integer;
    begin
        for i := 1 to ArrayLen(LocationCode) do begin
            LibraryWarehouse.CreateLocation(Location);
            LocationCode[i] := Location.Code;
        end;
        LibraryWarehouse.CreateInTransitLocation(Location);

        TransferRoute.Init();
        TransferRoute.Validate("Transfer-from Code", LocationCode[1]);
        TransferRoute.Validate("Transfer-to Code", LocationCode[2]);
        TransferRoute.Validate("In-Transit Code", Location.Code);
        TransferRoute.Insert();
        TransferRoute.Validate("Transfer-to Code", LocationCode[3]);
        TransferRoute.Insert();
    end;

    local procedure CreateTransferSetup(var SalesHeader: Record "Sales Header"; var ItemNo: array[4] of Code[20]; CreateSalesOrderExist: Boolean)
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        StockkeepingUnit: Record "Stockkeeping Unit";
        i: Integer;
    begin
        // Create and Update Five Location.
        // Create Items and  Production BOMs.Attach BOM to Item.
        CreateUpdateLocations();
        for i := 1 to 4 do begin
            CreateItem(Item);
            ItemNo[i] := Item."No.";
        end;

        CreateProdBOM(ProductionBOMHeader, ItemNo[1], '', Item."Base Unit of Measure", false);
        UpdateItem(ItemNo[3], ProductionBOMHeader."No.");
        CreateProdBOM(ProductionBOMHeader, ItemNo[2], ItemNo[3], Item."Base Unit of Measure", true);
        UpdateItem(ItemNo[4], ProductionBOMHeader."No.");

        // Create Transfer Routes.
        // Create Stock keeping Unit for each Item at each Location.
        CreateTransferRoutes();
        CreateUpdateStockKeepUnit(StockkeepingUnit, ItemNo);

        // Create and Update Sales Order.
        if CreateSalesOrderExist then begin
            CreateSalesOrder(SalesHeader, Item."No.", LibraryRandom.RandInt(10));
            UpdateSalesLine(SalesHeader, LocationCode[1]);
        end;
    end;

    local procedure CreatePartlyShipTransferOrder(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line")
    var
        LocationFromCode: Code[10];
        LocationToCode: Code[10];
    begin
        CreateLocations(LocationFromCode, LocationToCode);
        CreateAndPostPartiallyShippedTransferOrder(TransferHeader, TransferLine, LocationFromCode, LocationToCode, true);
    end;

    local procedure CreateShippingAgentServiceCodeWith1YShippingTime(var ShippingAgentCode: Code[10]; var ShippingAgentServiceCode: Code[10])
    var
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentServices: Record "Shipping Agent Services";
        ShippingTime: DateFormula;
    begin
        Evaluate(ShippingTime, '<+1Y>');
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        LibraryInventory.CreateShippingAgentService(ShippingAgentServices, ShippingAgent.Code, ShippingTime);
        ShippingAgentCode := ShippingAgentServices."Shipping Agent Code";
        ShippingAgentServiceCode := ShippingAgentServices.Code;
    end;

    local procedure CreateTwoPartlyShipTransferOrders(var TransferHeader: array[2] of Record "Transfer Header"; Ship: Boolean)
    var
        TransferLine: Record "Transfer Line";
        LocationFromCode: Code[10];
        LocationToCode: Code[10];
    begin
        CreateLocations(LocationFromCode, LocationToCode);
        CreateAndPostPartiallyShippedTransferOrder(TransferHeader[1], TransferLine, LocationFromCode, LocationToCode, Ship);
        CreateAndPostPartiallyShippedTransferOrder(TransferHeader[2], TransferLine, LocationFromCode, LocationToCode, Ship);
    end;

    local procedure CreateAndPostPartiallyShippedTransferOrder(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; LocationFromCode: Code[10]; LocationToCode: Code[10]; Ship: Boolean)
    var
        Item: Record Item;
        Qty: Decimal;
    begin
        Qty := LibraryRandom.RandIntInRange(100, 200);
        CreateItemWithPositiveInventory(Item, LocationFromCode, Qty * 2);

        CreateTransferOrderNoRoute(TransferHeader, TransferLine, LocationFromCode, LocationToCode, Item."No.", '', Qty * 2);
        UpdatePartialQuantityToShip(TransferLine, TransferLine.Quantity * LibraryUtility.GenerateRandomFraction());

        LibraryWarehouse.PostTransferOrder(TransferHeader, Ship, false);
    end;

    local procedure CreateTransferOrderHeader(var TransferHeader: Record "Transfer Header")
    var
        InTransitLocation: Record Location;
        LocationFromCode: Code[10];
        LocationToCode: Code[10];
    begin
        CreateLocations(LocationFromCode, LocationToCode);
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFromCode, LocationToCode, InTransitLocation.Code);
    end;

    local procedure CreateGlobal1DimensionValue(var DimensionValue: Record "Dimension Value"): Code[20]
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue, GLSetup."Global Dimension 1 Code");
        exit(DimensionValue.Code);
    end;

    local procedure CarryOutActionMsgPlanSetup(var RequisitionLine: Record "Requisition Line"; ItemNo: array[4] of Code[20])
    begin
        // Update Vendor No in Requisition Worksheet and Carry Out Action Message.
        GenerateRequisitionWorksheet(RequisitionLine, ItemNo);
        RequisitionCarryOutActMessage(ItemNo);
    end;

    local procedure EnableDirectTransfersInInventorySetup()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Direct Transfer Posting", InventorySetup."Direct Transfer Posting"::"Direct Transfer");
        InventorySetup.Validate("Posted Direct Trans. Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        InventorySetup.Modify(true);
    end;

    local procedure FilterWhseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceType: Integer; SourceNo: Code[20])
    begin
        WarehouseReceiptLine.SetRange("Source Type", SourceType);
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
    end;

    local procedure MockReqTransferOrderLines(var RequisitionLine: Record "Requisition Line"; LocationCode: array[3] of Code[10])
    var
        Item: Record Item;
        i: Integer;
    begin
        CreateReqLine(RequisitionLine);
        LibraryInventory.CreateItem(Item);

        RequisitionLine."Accept Action Message" := true;
        RequisitionLine."Action Message" := RequisitionLine."Action Message"::New;
        RequisitionLine."Transfer-from Code" := LocationCode[1];
        RequisitionLine.Type := RequisitionLine.Type::Item;
        RequisitionLine."No." := Item."No.";
        RequisitionLine."Ref. Order Type" := RequisitionLine."Ref. Order Type"::Transfer;
        RequisitionLine."Transfer Shipment Date" := WorkDate();
        RequisitionLine."Due Date" := WorkDate();
        RequisitionLine.Quantity := LibraryRandom.RandDec(100, 2);

        for i := 1 to 4 do begin
            RequisitionLine."Line No." += 10000;
            RequisitionLine."Location Code" := LocationCode[3 - i mod 2];
            // 2,3,2,3
            RequisitionLine.Insert();
        end;
    end;

    local procedure MockTransferOrder(var TransferHeader: Record "Transfer Header")
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferHeader.Init();
        TransferHeader."No." := LibraryUtility.GenerateRandomCode(TransferHeader.FieldNo("No."), DATABASE::"Transfer Header");
        TransferHeader."Transfer-from Code" := LibraryUtility.GenerateGUID();
        TransferHeader."Transfer-to Code" := LibraryUtility.GenerateGUID();
        TransferHeader.Status := TransferHeader.Status::Open;
        TransferHeader."External Document No." := LibraryUtility.GenerateGUID();
        TransferHeader."Shipment Method Code" := LibraryUtility.GenerateGUID();
        TransferHeader."Shipping Agent Code" := LibraryUtility.GenerateGUID();
        TransferHeader."Shipping Advice" := TransferHeader."Shipping Advice"::Complete;
        TransferHeader."Shipment Date" := LibraryRandom.RandDate(10);
        TransferHeader."Receipt Date" := LibraryRandom.RandDateFromInRange(WorkDate(), 11, 20);
        TransferHeader.Insert();

        TransferLine.Init();
        TransferLine."Document No." := TransferHeader."No.";
        TransferLine."Transfer-from Code" := TransferHeader."Transfer-from Code";
        TransferLine."Transfer-to Code" := TransferHeader."Transfer-to Code";
        TransferLine.Quantity := LibraryRandom.RandInt(10);
        TransferLine."Quantity Shipped" := LibraryRandom.RandInt(10);
        TransferLine."Quantity Received" := LibraryRandom.RandInt(10);
        TransferLine."Completely Shipped" := (TransferLine."Quantity Shipped" = TransferLine.Quantity);
        TransferLine."Completely Received" := (TransferLine."Quantity Received" = TransferLine.Quantity);
        TransferLine.Insert();
    end;

    local procedure MockWhseRequest(RequestType: Enum "Warehouse Request Type"; LocCode: Code[10];
                                                     SourceNo: Code[20])
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        WarehouseRequest.Init();
        WarehouseRequest.Type := RequestType;
        WarehouseRequest."Location Code" := LocCode;
        WarehouseRequest."Source Type" := DATABASE::"Transfer Line";
        WarehouseRequest."Source Subtype" := Abs(RequestType.AsInteger() - 1);
        WarehouseRequest."Source No." := SourceNo;
        WarehouseRequest."Shipment Date" := WorkDate();
        WarehouseRequest."Expected Receipt Date" := WorkDate();
        WarehouseRequest.Insert();
    end;

    local procedure FilterWhseRequest(var WarehouseRequest: Record "Warehouse Request"; RequestType: Enum "Warehouse Request Type"; LocCode: Code[10];
                                                                                                         SourceSubtype: Option;
                                                                                                         SourceNo: Code[20])
    begin
        WarehouseRequest.SetRange(Type, RequestType);
        WarehouseRequest.SetRange("Location Code", LocCode);
        WarehouseRequest.SetRange("Source Type", DATABASE::"Transfer Line");
        WarehouseRequest.SetRange("Source Subtype", SourceSubtype);
        WarehouseRequest.SetRange("Source No.", SourceNo);
    end;

    local procedure MockTransferReceiptLine(var TransferReceiptLine: Record "Transfer Receipt Line"; DocumentNo: Code[20]; ItemNo: Code[20]; Desc: Text[100]; Qty: Decimal)
    begin
        TransferReceiptLine.Init();
        TransferReceiptLine."Document No." := DocumentNo;
        TransferReceiptLine."Line No." := LibraryUtility.GetNewRecNo(TransferReceiptLine, TransferReceiptLine.FieldNo("Line No."));
        TransferReceiptLine."Item No." := ItemNo;
        TransferReceiptLine.Description := Desc;
        TransferReceiptLine.Quantity := Qty;
        TransferReceiptLine.Insert();
    end;

    local procedure CalculateNetChangePlan(var RequisitionLine: Record "Requisition Line"; StartDate: Date; ItemNo: array[4] of Code[20])
    var
        Item: Record Item;
        CalculatePlanPlanWksh: Report "Calculate Plan - Plan. Wksh.";
    begin
        Item.SetRange("No.", ItemNo[1], ItemNo[4]);
        CalculatePlanPlanWksh.SetTemplAndWorksheet(
          RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name", true);
        CalculatePlanPlanWksh.SetTableView(Item);
        CalculatePlanPlanWksh.InitializeRequest(StartDate, CalcDate('<30D>', StartDate), false);
        CalculatePlanPlanWksh.UseRequestPage(false);
        CalculatePlanPlanWksh.RunModal();
        if not RequisitionLine.FindFirst() then
            RequisitionLine.SetUpNewLine(RequisitionLine);
    end;

    local procedure GenerateRequisitionWorksheet(var RequisitionLine: Record "Requisition Line"; ItemNo: array[4] of Code[20])
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        CarryOutActionMsgPlan: Report "Carry Out Action Msg. - Plan.";
        NewProdOrderChoice: Option " ",Planned,"Firm Planned","Firm Planned & Print","Copy to Req. Wksh";
        NewPurchOrderChoice: Option " ","Make Purch. Orders","Make Purch. Orders & Print","Copy to Req. Wksh";
        NewTransOrderChoice: Option " ","Make Trans. Orders","Make Trans. Orders & Print","Copy to Req. Wksh";
        NewAsmOrderChioce: Option " ","Make Assembly Orders","Make Assembly Orders & Print";
    begin
        // Update Accept Action Message in Planning Worksheet.
        UpdatePlanningWorkSheet(RequisitionLine, ItemNo);

        RequisitionWkshName.SetRange("Template Type", RequisitionWkshName."Template Type"::"Req.");
        RequisitionWkshName.FindFirst();
        CarryOutActionMsgPlan.SetReqWkshLine(RequisitionLine);
        CarryOutActionMsgPlan.InitializeRequest2(
          NewProdOrderChoice::Planned,
          NewPurchOrderChoice::"Copy to Req. Wksh",
          NewTransOrderChoice::"Copy to Req. Wksh",
          NewAsmOrderChioce::" ",
          RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name, RequisitionWkshName."Worksheet Template Name",
          RequisitionWkshName.Name);
        CarryOutActionMsgPlan.SetTableView(RequisitionLine);
        CarryOutActionMsgPlan.UseRequestPage(false);
        CarryOutActionMsgPlan.Run();
    end;

    local procedure FindRandomReceiptLine(PurchRcptNo: Code[20]; var PurchRcptLine: Record "Purch. Rcpt. Line")
    begin
        PurchRcptLine.SetRange("Document No.", PurchRcptNo);
        PurchRcptLine.Next(LibraryRandom.RandInt(PurchRcptLine.Count));
    end;

    local procedure UpdateLocation("Code": Code[10]; UseAsInTransit: Boolean; OutboundWhseHandlingTime: DateFormula; InboundWhseHandlingTime: DateFormula)
    var
        Location: Record Location;
    begin
        Location.Get(Code);
        Location.Validate("Use As In-Transit", UseAsInTransit);
        Location.Validate("Outbound Whse. Handling Time", OutboundWhseHandlingTime);
        Location.Validate("Inbound Whse. Handling Time", InboundWhseHandlingTime);
        Location.Modify(true);
        LibraryInventory.UpdateInventoryPostingSetup(Location);
    end;

    local procedure UpdateItem(ItemNo: Code[20]; ProductionBOMNo: Code[20])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure UpdateTransferRoutes(var TransferRoute: Record "Transfer Route"; ShippingAgentServiceCode: Code[10]; ShippingAgentCode: Code[10])
    begin
        TransferRoute.Validate("In-Transit Code", LocationCode[5]);
        TransferRoute.Validate("Shipping Agent Code", ShippingAgentCode);
        TransferRoute.Validate("Shipping Agent Service Code", ShippingAgentServiceCode);
        TransferRoute.Modify(true);
    end;

    local procedure UpdateStockKeepingUnit(LocationCode: Code[10]; ItemNo: Code[20]; ReplenishmentSystem: Enum "Replenishment System"; VendorNo: Code[20];
                                                                                                              TransferfromCode: Code[10])
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        FindStockKeepingUnit(StockkeepingUnit, LocationCode, ItemNo);
        StockkeepingUnit.Validate("Replenishment System", ReplenishmentSystem);
        StockkeepingUnit.Validate("Transfer-from Code", TransferfromCode);
        StockkeepingUnit.Validate("Vendor No.", VendorNo);
        StockkeepingUnit.Modify(true);
    end;

    local procedure UpdateReorderingPolicy(LocationCode: Code[10]; ItemNo: Code[20])
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        FindStockKeepingUnit(StockkeepingUnit, LocationCode, ItemNo);
        StockkeepingUnit.Validate("Reordering Policy", StockkeepingUnit."Reordering Policy"::"Lot-for-Lot");
        StockkeepingUnit.Validate("Include Inventory", true);
        StockkeepingUnit.Modify(true);
    end;

    local procedure UpdateSalesLine(SalesHeader: Record "Sales Header"; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindSet();
        repeat
            SalesLine.Validate("Location Code", LocationCode);
            SalesLine.Modify(true);
        until SalesLine.Next() = 0;
    end;

    local procedure UpdatePurchaseLine(PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindSet();
        repeat
            PurchaseLine.Validate("Location Code", LocationCode);
            PurchaseLine.Validate("Expected Receipt Date", CalcDate('<CM>', PurchaseHeader."Order Date"));
            PurchaseLine.Modify(true);
        until PurchaseLine.Next() = 0;
    end;

    local procedure UpdatePlanningWorkSheet(var RequisitionLine: Record "Requisition Line"; ItemNo: array[4] of Code[20])
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", ItemNo[1], ItemNo[4]);
        RequisitionLine.FindSet();
        repeat
            RequisitionLine.Validate("Accept Action Message", true);
            RequisitionLine.Modify(true);
        until RequisitionLine.Next() = 0;
    end;

    local procedure UpdatePartialQuantityToShip(var TransferLine: Record "Transfer Line"; QtyToShip: Decimal)
    begin
        TransferLine.Validate("Qty. to Ship", QtyToShip);
        TransferLine.Modify(true);
    end;

    local procedure FindStockKeepingUnit(var StockkeepingUnit: Record "Stockkeeping Unit"; LocationCode: Code[10]; ItemNo: Code[20])
    begin
        StockkeepingUnit.SetRange("Location Code", LocationCode);
        StockkeepingUnit.SetRange("Item No.", ItemNo);
        StockkeepingUnit.FindFirst();
    end;

    local procedure RequisitionCarryOutActMessage(ItemNo: array[4] of Code[20])
    var
        RequisitionLine: Record "Requisition Line";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", ItemNo[1], ItemNo[4]);
        RequisitionLine.FindSet();
        repeat
            RequisitionLine.Validate("Vendor No.", Vendor."No.");
            RequisitionLine.Modify(true);
        until RequisitionLine.Next() = 0;
        LibraryPlanning.CarryOutAMSubcontractWksh(RequisitionLine);
    end;

    local procedure RunRequisitionCarryOutReport(RequisitionLine: Record "Requisition Line"; CombineTransfers: Boolean)
    var
        CarryOutActionMsgPlan: Report "Carry Out Action Msg. - Plan.";
    begin
        Commit();
        LibraryVariableStorage.Enqueue(CombineTransfers);
        CarryOutActionMsgPlan.SetReqWkshLine(RequisitionLine);
        CarryOutActionMsgPlan.UseRequestPage(true);
        CarryOutActionMsgPlan.RunModal();
    end;

    local procedure ClearReqWkshBatch(RequisitionWkshName: Record "Requisition Wksh. Name")
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
        RequisitionLine.DeleteAll();
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20]; EntryType: Enum "Item Ledger Entry Type"; LocationCode: Code[10];
                                                                                                                          IsPositive: Boolean)
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
        ItemLedgerEntry.SetRange(Positive, IsPositive);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure FindLastILENo(ItemNo: Code[20]): Integer
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.SetRange("Item No.", ItemNo);
        ItemLedgEntry.FindLast();
        exit(ItemLedgEntry."Entry No.");
    end;

    local procedure VerifyNumberOfRequisitionLine(ItemNo: array[4] of Code[20]; NoOfLines: Integer)
    var
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        RequisitionWkshName.SetRange("Template Type", RequisitionWkshName."Template Type"::Planning);
        RequisitionWkshName.FindFirst();

        RequisitionLine.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.SetRange("No.", ItemNo[1], ItemNo[4]);
        Assert.AreEqual(NoOfLines, RequisitionLine.Count, NoOfLinesMustBeEqualErr);
    end;

    local procedure VerifyItemNoExistInReqLine(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.FindFirst();
    end;

    local procedure VerifyReqLineActMessageCancel(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("Action Message", RequisitionLine."Action Message"::Cancel);
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.FindFirst();
    end;

    local procedure VerifyTransferOrderCount(LocationFromCode: Code[10]; LocationToCode: Code[10]; ExpectedCount: Integer)
    var
        TransferHeader: Record "Transfer Header";
    begin
        TransferHeader.SetRange("Transfer-from Code", LocationFromCode);
        TransferHeader.SetRange("Transfer-to Code", LocationToCode);
        Assert.AreEqual(ExpectedCount, TransferHeader.Count, TransferOrderCountErr);
    end;

    local procedure VerifyTransferReceiptDate(var TransferOrder: TestPage "Transfer Order")
    var
        ReceiptDateOnHeader: Date;
        ReceiptDateOnLine: Date;
    begin
        Evaluate(ReceiptDateOnHeader, TransferOrder."Receipt Date".Value);
        Evaluate(ReceiptDateOnLine, TransferOrder.TransferLines."Receipt Date".Value);
        Assert.AreEqual(ReceiptDateOnHeader, ReceiptDateOnLine, TransferOrderSubpageNotUpdatedErr);
    end;

    local procedure VerifyItemApplicationEntry(ItemNo: Code[20]; AppliedToEntryNo: Integer)
    var
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        ItemApplicationEntry.SetRange("Item Ledger Entry No.", FindLastILENo(ItemNo));
        ItemApplicationEntry.FindLast();
        ItemApplicationEntry.SetRange("Item Ledger Entry No.", ItemApplicationEntry."Outbound Item Entry No.");
        ItemApplicationEntry.FindLast();
        ItemApplicationEntry.TestField("Inbound Item Entry No.", AppliedToEntryNo);
        ItemApplicationEntry.TestField("Cost Application", true);
    end;

    local procedure VerifyItemApplicationEntryCost(ItemNo: Code[20]; EntryType: Enum "Item Ledger Entry Type"; ExpectedCost: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.FindSet();
        repeat
            ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
            ItemLedgerEntry.TestField("Cost Amount (Actual)", ExpectedCost * ItemLedgerEntry.Quantity);
        until ItemLedgerEntry.Next() = 0;
    end;

    local procedure VerifyDimensionOnDimSet(DimSetID: Integer; DimensionValue: Record "Dimension Value")
    var
        TempDimensionSetEntry: Record "Dimension Set Entry" temporary;
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.GetDimensionSet(TempDimensionSetEntry, DimSetID);
        TempDimensionSetEntry.SetRange("Dimension Code", DimensionValue."Dimension Code");
        TempDimensionSetEntry.FindFirst();
        TempDimensionSetEntry.TestField("Dimension Value Code", DimensionValue.Code);
    end;

    local procedure VerifyWhseRequest(WarehouseRequest: Record "Warehouse Request"; TransferHeader: Record "Transfer Header"; SourceDoc: Option; IsCompletelyHandled: Boolean; ShipmentDate: Date; ReceiptDate: Date)
    begin
        WarehouseRequest.TestField("Source Document", SourceDoc);
        WarehouseRequest.TestField("Document Status", TransferHeader.Status);
        WarehouseRequest.TestField("External Document No.", TransferHeader."External Document No.");
        WarehouseRequest.TestField("Completely Handled", IsCompletelyHandled);
        WarehouseRequest.TestField("Shipment Method Code", TransferHeader."Shipment Method Code");
        WarehouseRequest.TestField("Shipping Agent Code", TransferHeader."Shipping Agent Code");
        WarehouseRequest.TestField("Destination Type", WarehouseRequest."Destination Type"::Location);
        WarehouseRequest.TestField("Destination No.", WarehouseRequest."Location Code");
        WarehouseRequest.TestField("Shipment Date", ShipmentDate);
        WarehouseRequest.TestField("Expected Receipt Date", ReceiptDate);
    end;

    local procedure SetupForUoMTest(
        var Item: Record Item;
        var TransferHeader: Record "Transfer Header";
        var TransferLine: Record "Transfer Line";
        var BaseUoM: Record "Unit of Measure";
        var NonBaseUOM: Record "Unit of Measure";
        var ItemUOM: Record "Item Unit of Measure";
        var ItemNonBaseUOM: Record "Item Unit of Measure";
        BaseQtyPerUOM: Integer;
        NonBaseQtyPerUOM: Integer;
        QtyRoundingPrecision: Decimal
    )
    var
        LocationA: Record Location;
        LocationB: Record Location;
        LocationTransit: Record Location;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemNonBaseUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        LibraryWarehouse.CreateTransferLocations(LocationA, LocationB, LocationTransit);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, LocationA.Code, LocationB.Code, '');
        TransferHeader.Validate("Direct Transfer", true);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 0);

        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
            ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
            ItemJournalLine."Entry Type"::Purchase, Item."No.", NonBaseQtyPerUOM
        );
        ItemJournalLine."Location Code" := LocationA.Code;
        ItemJournalLine."Posting Date" := CalcDate('<-1W>', WorkDate());
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure CreateAndShipTransferOrderWithBin(var TransferHeader: Record "Transfer Header"; QtyToShip: Integer)
    var
        Item: Record Item;
        FromLocation: Record Location;
        ToLocation: Record Location;
        TransferLine: Record "Transfer Line";
        FromLocationBin: Record Bin;
    begin

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ToLocation);
        LibraryWarehouse.CreateLocationWMS(FromLocation, true, false, false, false, false);
        LibraryWarehouse.CreateBin(FromLocationBin, FromLocation.Code, LibraryUtility.GenerateGUID(), '', '');

        // Create Transfer Order
        CreateItemWithPositiveInventoryAndBin(Item, FromLocation.code, FromLocationBin.Code, QtyToShip);
        CreateTransferOrderNoRoute(TransferHeader, TransferLine, FromLocation.Code, ToLocation.Code, Item."No.", '', QtyToShip);
        TransferLine.Validate("Transfer-From Bin Code", FromLocationBin.Code);
        TransferLine.Modify(true);

        // Ship the Transfer Order
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);
    end;

    local procedure CreateAndShipTransferOrder(var TransferHeader: Record "Transfer Header"; QtyToShip: Integer; PartlyShippedLine: Boolean; NotShippedLine: Boolean)
    var
        Item: Record Item;
        FromLocation: Record Location;
        ToLocation: Record Location;
        TransferLine: array[3] of Record "Transfer Line";
    begin
        // Create two locations with simple setup (no bins etc.)
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(FromLocation);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ToLocation);

        // Create Transfer Order
        CreateItemWithPositiveInventory(Item, FromLocation.code, QtyToShip);
        CreateTransferOrderNoRoute(TransferHeader, TransferLine[1], FromLocation.Code, ToLocation.Code, Item."No.", '', QtyToShip);

        if PartlyShippedLine then begin
            CreateItemWithPositiveInventory(Item, FromLocation.code, QtyToShip);
            LibraryInventory.CreateTransferLine(TransferHeader, TransferLine[2], Item."No.", QtyToShip / 2);
        end;

        if NotShippedLine then begin
            CreateItemWithPositiveInventory(Item, FromLocation.code, QtyToShip);
            LibraryInventory.CreateTransferLine(TransferHeader, TransferLine[3], Item."No.", 0);
        end;

        // Ship the Transfer Order
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);
    end;

    local procedure CreateAndShipTransferOrderWithTracking(var TransferHeader: Record "Transfer Header"; Quanitity: Integer; LotTracking: Boolean; ShipFullQty: Boolean; AdditionalLine: Boolean)
    var
        QtyToShip: Decimal;
    begin
        CreateTransferOrderHeader(TransferHeader);

        if ShipFullQty then
            QtyToShip := Quanitity
        else
            QtyToShip := Quanitity / 2;

        CreateTrackedTransferOrderLineWithItem(TransferHeader, Quanitity, QtyToShip, LotTracking);

        if AdditionalLine then
            CreateTrackedTransferOrderLineWithItem(TransferHeader, Quanitity, QtyToShip, LotTracking);

        // Ship the Transfer Order
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);
    end;

    local procedure CreateTrackedTransferOrderLineWithItem(var TransferHeader: Record "Transfer Header"; Quantity: Decimal; QtyToShip: Decimal; LotTracking: Boolean)
    var
        TransferLine: Record "Transfer Line";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Create tracked item with inventory
        if LotTracking then begin
            LibraryVariableStorage.Enqueue(TrackingOption::AssignLotNo);
            LibraryItemTracking.CreateLotItem(Item);
        end else begin
            LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialNo);
            LibraryItemTracking.CreateSerialItem(Item);
        end;
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", TransferHeader."Transfer-from Code", '', Quantity);
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        CreateTransferOrderLineAndAssignTracking(TransferHeader, TransferLine, Item."No.", Quantity, QtyToShip);
    end;

    local procedure ShipSingleTransferLine(TransferLine: Record "Transfer Line"; QtyToShip: Decimal)
    var
        TransferHeader: Record "Transfer Header";
        TransferLine2: record "Transfer Line";
    begin
        TransferLine2.SetFilter("Document No.", TransferLine."Document No.");
        TransferLine2.SetRange("Derived From Line No.", 0);
        TransferLine2.SetFilter("Line No.", StrSubstNo('<>%1', TransferLine."Line No."));
        TransferLine2.ModifyAll("Qty. to Ship", 0, true);

        TransferLine.Validate("Qty. to Ship", QtyToShip);
        TransferLine.Modify();

        TransferHeader.SetFilter("No.", TransferLine."Document No.");
        TransferHeader.FindFirst();
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);
    end;

    local procedure CreateTransferOrderLineAndAssignTracking(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; ItemNo: Code[20]; Quantity: Decimal; QtyToShip: Decimal)
    begin
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        TransferLine.Validate("Qty. to Ship", QtyToShip);
        TransferLine.Modify();
        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries);
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);
    end;

    local procedure VerifyTrackingNotShippedOnTransferOrder(var TransferHeader: Record "Transfer Header")
    var
        TransferLine: Record "Transfer Line";
        TransferShipmentHeader: Record "Transfer Shipment Header";
    begin
        // For each Transfer line
        TransferLine.SetFilter("Document No.", TransferHeader."No.");
        if TransferLine.FindSet() then
            repeat
                // Tracking page on transfer line is in unshipped state
                VerifyTrackingOnTransferLineAfterUndo(TransferLine, TransferLine.Quantity, TransferLine.Quantity);
            until TransferLine.Next() = 0;

        // For each Transfer Shipment related to the Transfer Order
        TransferShipmentHeader.SetFilter("Transfer Order No.", TransferHeader."No.");
        if TransferShipmentHeader.FindSet() then
            repeat
                VerifyPostedTransShptTrackingCancelsOut(TransferShipmentHeader."No.");
            until TransferShipmentHeader.Next() = 0;
    end;

    local procedure VerifyPostedTransShptTrackingCancelsOut(TransShptHeaderNo: Code[20])
    var
        TransShptLine: Record "Transfer Shipment Line";
        TrackedQty: Decimal;
    begin
        TrackedQty := 0;
        TransShptLine.SetFilter("Document No.", TransShptHeaderNo);
        if TransShptLine.FindSet() then
            repeat
                TransShptLine.ShowItemTrackingLines();
                TrackedQty := TrackedQty + LibraryVariableStorage.DequeueDecimal();
            until TransShptLine.Next() = 0;

        Assert.AreEqual(0, TrackedQty, 'Expected posted tracking lines qty to be 0 for undone Transfer Shipment, but i wasn''t');
    end;

    local procedure VerifyTrackingOnTransferLineAfterUndo(TransferLine: Record "Transfer Line"; TrackingQty: Decimal; TrackingQtyToHandle: Decimal)
    var
        TrackingOption: Option AssignLotNo,AssignSerialNo,SelectEntries,ShowEntries,VerifyEntries;
    begin
        // Verification done in ItemTrackingLinesModalPageHandlerGeneric. Enqueue values for ItemTrackingLinesModalPageHandlerGeneric.
        LibraryVariableStorage.Enqueue(TrackingOption::ShowEntries);
        LibraryVariableStorage.Enqueue(TrackingQty);
        LibraryVariableStorage.Enqueue(TrackingQtyToHandle);
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);
    end;

    local procedure SumILEForItemOnLocation(ItemNo: Code[20]; LocationCode: Code[10]): Decimal
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
        ItemLedgerEntry.CalcSums(Quantity);
        exit(ItemLedgerEntry.Quantity);
    end;

    local procedure VerifyTransferOrderCompletelyUnshipped(var TransferHeader: Record "Transfer Header")
    begin
        VerifyTransferLineUpdated(TransferHeader);
        VerifyRelatedTransferShipmentUndo(TransferHeader);
    end;

    local procedure VerifyTransferLineUpdated(var TransferHeader: Record "Transfer Header")
    var
        TransferLine: Record "Transfer Line";
    begin
        //For each Transfer Line on the order
        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.SetRange("Derived From Line No.", 0);
        if TransferLine.FindSet() then
            repeat
                // The Transfer Line has been updated correctly to the state it was in before posting
                VerifyTransLineUnshipped(TransferLine);
                // No derived transfer lines exists (Derived From original line - was added on posting)
                VerifyNoDerivedTransferLine(TransferHeader."No.", TransferLine."Line No.");
            until TransferLine.Next() = 0;
    end;

    local procedure VerifyRelatedTransferShipmentUndo(var TransferHeader: Record "Transfer Header")
    var
        TransferShipmentHeader: Record "Transfer Shipment Header";
    begin
        // Every Transfer Shipment related to the Transfer Order has been undone
        TransferShipmentHeader.SetFilter("Transfer Order No.", TransferHeader."No.");
        if TransferShipmentHeader.FindSet() then
            repeat
                VerifyTransferShipmentUndone(TransferShipmentHeader);
            until TransferShipmentHeader.Next() = 0;
    end;


    local procedure VerifyTransferOrderCompletelyUnshippedWithRefDoc(var TransferHeader: Record "Transfer Header")
    begin
        VerifyTransferLineUpdated(TransferHeader);
        VerifyRefDocOfWarehouseEntry(TransferHeader."No.");
        VerifyRelatedTransferShipmentUndo(TransferHeader);
    end;

    local procedure VerifyRefDocOfWarehouseEntry(SourceNo: Text[20])
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetRange("Source No.", SourceNo);
        WarehouseEntry.FindSet();
        repeat
            WarehouseEntry.TestField("Reference Document", WarehouseEntry."Reference Document"::"Posted T. Shipment");
        until WarehouseEntry.Next() = 0;
    end;

    local procedure VerifyTransferShipmentUndone(var TransferShipmentHeader: Record "Transfer Shipment Header")
    begin
        // A transfer shipment line has been added to cancel out the original
        VerifyTransShptLinesCancelOut(TransferShipmentHeader."No.");

        // Item ledger entries have been added to cancel out the original ones
        VerifyItemLedgerEntriesCancelOut(TransferShipmentHeader."No.", TransferShipmentHeader."Transfer-from Code");
        VerifyItemLedgerEntriesCancelOut(TransferShipmentHeader."No.", TransferShipmentHeader."In-Transit Code");
    end;

    local procedure ShipAndReceiveTransOrderFully(var TransferHeader: Record "Transfer Header"; WithTracking: Boolean)
    begin
        ShipTransOrderFully(TransferHeader, WithTracking);
        ReceiveTransOrderFully(TransferHeader);
    end;

    local procedure ShipTransOrderFully(var TransferHeader: Record "Transfer Header"; WithTracking: Boolean)
    var
        TransferLine: Record "Transfer Line";
        TrackingOption: Option AssignLotNo,AssignSerialNo,SelectEntries,ShowEntries,VerifyEntries;
    begin
        TransferLine.SetFilter("Document No.", TransferHeader."No.");
        if TransferLine.FindSet() then
            repeat
                TransferLine.InitQtyToShip();
                TransferLine.Modify();
                if WithTracking then begin
                    LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries);
                    TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);
                end;
            until TransferLine.Next() = 0;
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);
    end;

    local procedure ReceiveTransOrderFully(var TransferHeader: Record "Transfer Header")
    var
        TransferLine: Record "Transfer Line";
    begin
        if TransferLine.FindSet() then
            repeat
                TransferLine.InitQtyToReceive();
                TransferLine.Modify();
            until TransferLine.Next() = 0;
        LibraryInventory.PostTransferHeader(TransferHeader, false, true);
    end;

    local procedure VerifyNoDerivedTransferLine(TransOrderDocumentNo: Code[20]; OriginalTransLineNo: Integer)
    var
        DerivedTransferLine: Record "Transfer Line";
    begin
        DerivedTransferLine.SetFilter("Document No.", TransOrderDocumentNo);
        DerivedTransferLine.SetRange("Derived From Line No.", OriginalTransLineNo);
        Assert.AreEqual(0, DerivedTransferLine.Count, DerivedTransLineErr);
    end;

    local procedure FindFirstReservEntryOnDerivedLine(TransferLine: Record "Transfer Line"; var ReservationEntry: Record "Reservation Entry")
    var
        DerivedTransferLine: Record "Transfer Line";
    begin
        // Find the derived line
        DerivedTransferLine.SetFilter("Document No.", TransferLine."Document No.");
        DerivedTransferLine.SetRange("Derived From Line No.", TransferLine."Line No.");
        DerivedTransferLine.FindFirst();

        // Find a Reservation Entry on that line
        ReservationEntry.SetRange("Source Type", Database::"Transfer Line");
        ReservationEntry.SetRange("Source Subtype", "Transfer Direction"::Inbound.AsInteger());
        ReservationEntry.SetRange("Source ID", TransferLine."Document No.");
        ReservationEntry.SetRange("Source Prod. Order Line", TransferLine."Line No.");
        ReservationEntry.SetRange("Source Ref. No.", DerivedTransferLine."Line No.");
        ReservationEntry.FindFirst();
    end;

    local procedure VerifyTransLineUnshipped(TransferLine: Record "Transfer Line")
    begin
        TransferLine.Get(TransferLine."Document No.", TransferLine."Line No.");
        Assert.AreEqual(0, TransferLine."Quantity Shipped", UndoneTransLineQtyErr);
        Assert.AreEqual(0, TransferLine."Qty. Shipped (Base)", UndoneTransLineQtyErr);
        Assert.AreEqual(0, TransferLine."Qty. in Transit", UndoneTransLineQtyErr);
        Assert.AreEqual(0, TransferLine."Qty. in Transit (Base)", UndoneTransLineQtyErr);
    end;

    local procedure VerifyTransShptLinesCancelOut(TransferShptNo: Code[20])
    var
        TransferShipmentLine: Record "Transfer Shipment Line";
        QtySum: Decimal;
    begin
        QtySum := 0;
        TransferShipmentLine.SetRange("Document No.", TransferShptNo);
        TransferShipmentLine.SetFilter(Quantity, '<>0');
        Assert.AreEqual(0, TransferShipmentLine.Count mod 2, 'Expected an even no. of Transfer Shipment Lines for undone Transfer Shipment');
        TransferShipmentLine.FindSet();
        repeat
            QtySum := QtySum + TransferShipmentLine."Quantity (Base)";
            Assert.IsTrue(TransferShipmentLine."Correction Line", TransShptLineNotCorrectionErr);
        until TransferShipmentLine.Next() = 0;
        Assert.AreEqual(0, QtySum, TransShptIncorrectSumErr);
    end;

    local procedure VerifyItemLedgerEntriesCancelOut(TransShptNo: Code[20]; LocationCode: Code[10])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        QtySum: Decimal;
        NoOfCorrections: Integer;
        NoOfNonCorrections: Integer;
    begin
        ItemLedgerEntry.SetFilter("Document No.", TransShptNo);
        ItemLedgerEntry.SetFilter("Location Code", LocationCode);
        ItemLedgerEntry.FindSet();
        QtySum := 0;
        repeat
            QtySum := QtySum + ItemLedgerEntry."Quantity";
            if ItemLedgerEntry.Correction then
                NoOfCorrections := NoOfCorrections + 1
            else
                NoOfNonCorrections := NoOfNonCorrections + 1;
        until ItemLedgerEntry.Next() = 0;
        Assert.AreEqual(0, QtySum, ILEIncorrectSumErr);
        Assert.AreEqual(NoOfCorrections, NoOfNonCorrections, ILECorrectedAndNotErr);
    end;

    local procedure CreateCommentTransferLine(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; Description: Text[100])
    var
        RecRef: RecordRef;
    begin
        Clear(TransferLine);
        TransferLine.Init();
        TransferLine.Validate("Document No.", TransferHeader."No.");
        RecRef.GetTable(TransferLine);
        TransferLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, TransferLine.FieldNo("Line No.")));
        TransferLine.Insert(true);
        TransferLine.Validate(Description, Description);
        TransferLine.Modify(true);
    end;

    local procedure VerifyPostedTransferShipment(TransferOrderNo: Code[20]; LineCount: Integer)
    var
        TransferShipmentHeader: Record "Transfer Shipment Header";
        TransferShipmentLine: Record "Transfer Shipment Line";
    begin
        TransferShipmentHeader.SetRange("Transfer Order No.", TransferOrderNo);
        TransferShipmentHeader.FindFirst();
        TransferShipmentLine.SetFilter("Document No.", TransferShipmentHeader."No.");
        Assert.AreEqual(LineCount, TransferShipmentLine.Count(), '');
    end;

    local procedure VerifyPostedTransferReceipt(TransferOrderNo: Code[20]; LineCount: Integer)
    var
        TransferReceiptHeader: Record "Transfer Receipt Header";
        TransferReceiptLine: Record "Transfer Receipt Line";
    begin
        TransferReceiptHeader.SetRange("Transfer Order No.", TransferOrderNo);
        TransferReceiptHeader.FindFirst();
        TransferReceiptLine.SetFilter("Document No.", TransferReceiptHeader."No.");
        Assert.AreEqual(LineCount, TransferReceiptLine.Count(), '');
    end;

    local procedure CreateAndPostPurchRcptWithLocationCodeInPurchHeader(
        var PurchaseHeader: Record "Purchase Header";
        var PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        Item: Record Item;
        Location: Record Location)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.Validate("Location Code", Location.Code);
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine,
            PurchaseHeader,
            PurchaseLine.Type::Item,
            Item."No.",
            LibraryRandom.RandIntInRange(10, 10));

        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(15000));
        PurchaseLine.Modify(true);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure CreateAndPostPurchRcptWithLocationCodeInPurchLine(
        var PurchaseHeader: Record "Purchase Header";
        var PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        Item: Record Item;
        Location: Record Location): Code[20]
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine,
            PurchaseHeader,
            PurchaseLine.Type::Item,
            Item."No.",
            LibraryRandom.RandIntInRange(10, 10));

        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(15000));
        PurchaseLine.Modify(true);

        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false));
    end;

    local procedure UpdateItemTrackingLine(var ItemTrackingLines: TestPage "Item Tracking Lines"; LotNo: Code[20]; SerialNo: Code[20])
    begin
        ItemTrackingLines."Lot No.".SetValue(LotNo);
        ItemTrackingLines."Serial No.".SetValue(SerialNo);
        ItemTrackingLines."Quantity (Base)".SetValue(1);
    end;

    local procedure FindAndUpdatePurchPutAwayWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; Item: Record Item; Bin: Record Bin)
    begin
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        if WarehouseActivityLine.FindSet() then
            repeat
                WarehouseActivityLine.Validate("Bin Code", Bin.Code);
                WarehouseActivityLine.Validate("Expiration Date", CalcDate('<CM>', WorkDate()));
                WarehouseActivityLine.Validate("Qty. to Handle", LibraryRandom.RandInt(0));
                WarehouseActivityLine.Modify(true);
            until WarehouseActivityLine.Next() = 0;
    end;

    local procedure FindAndUpdateTransferPickWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; Item: Record Item)
    begin
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        if WarehouseActivityLine.FindSet() then
            repeat
                WarehouseActivityLine.Validate("Qty. to Handle", LibraryRandom.RandInt(0));
                WarehouseActivityLine.Modify(true);
            until WarehouseActivityLine.Next() = 0;
    end;

    local procedure FindAndUpdateTransferPutAwayWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; Item: Record Item)
    begin
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        if WarehouseActivityLine.FindSet() then
            repeat
                WarehouseActivityLine.Validate("Expiration Date", CalcDate('<CM>', WorkDate()));
                WarehouseActivityLine.Validate("Qty. to Handle", LibraryRandom.RandInt(0));
                WarehouseActivityLine.Modify(true);
            until WarehouseActivityLine.Next() = 0;
    end;

    local procedure SetVariantMandatoryInInventorySetup()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Variant Mandatory if Exists", true);
        InventorySetup.Modify(true);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CarryOutActionMsgPlanHandler(var CarryOutActionMsgPlan: TestRequestPage "Carry Out Action Msg. - Plan.")
    var
        Variant: Variant;
        TransOrderChoice: Option " ","Make Trans. Orders","Make Trans. Orders & Print","Copy to Req. Wksh";
    begin
        LibraryVariableStorage.Dequeue(Variant);
        CarryOutActionMsgPlan.TransOrderChoice.SetValue(TransOrderChoice::"Make Trans. Orders");
        CarryOutActionMsgPlan.CombineTransferOrders.SetValue(Variant);
        CarryOutActionMsgPlan.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure CreateInvtPickRequestPageHandler(var CreateInvtPutawayPickMvmt: TestRequestPage "Create Invt Put-away/Pick/Mvmt")
    begin
        CreateInvtPutawayPickMvmt.CreateInventorytPutAway.SetValue(true);
        CreateInvtPutawayPickMvmt.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure CreateInvtPickPutAwayRequestPageHandler(var CreateInvtPutawayPickMvmt: TestRequestPage "Create Invt Put-away/Pick/Mvmt")
    var
        Pick: Boolean;
    begin
        Pick := LibraryVariableStorage.DequeueBoolean();
        if Pick then
            CreateInvtPutawayPickMvmt.CInvtPick.SetValue(true)
        else
            CreateInvtPutawayPickMvmt.CreateInventorytPutAway.SetValue(true);
        CreateInvtPutawayPickMvmt.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerForTransferHeaderDimUpdate(Question: Text[1024]; var Reply: Boolean)
    begin
        case true of
            Question = UpdateFromHeaderLinesQst:
                Reply := true;
            StrPos(Question, UpdateLineDimQst) <> 0:
                Reply := LibraryVariableStorage.DequeueBoolean();
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseReceiptsModalPageHandler(var PostedPurchaseReceipts: Page "Posted Purchase Receipts";

    var
        Response: Action)
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        PurchRcptHeader.Get(LibraryVariableStorage.DequeueText());
        PostedPurchaseReceipts.SetRecord(PurchRcptHeader);

        Response := ACTION::LookupOK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseReceiptLinesModalPageHandler(var PostedPurchaseReceiptLines: Page "Posted Purchase Receipt Lines";

    var
        Response: Action)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange("No.", LibraryVariableStorage.DequeueText());
        PurchRcptLine.FindFirst();
        PostedPurchaseReceiptLines.SetRecord(PurchRcptLine);

        Response := ACTION::LookupOK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentPurchModalPageHandler(var ItemChargeAssignmentPurch: TestPage "Item Charge Assignment (Purch)")
    begin
        ItemChargeAssignmentPurch.GetTransferReceiptLines.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedTransferReceiptLinesModalPageHandler(var PostedTransferReceiptLines: TestPage "Posted Transfer Receipt Lines")
    begin
        PostedTransferReceiptLines.FILTER.SetFilter("Document No.", LibraryVariableStorage.DequeueText());
        PostedTransferReceiptLines.Last();
        PostedTransferReceiptLines."Item No.".AssertEquals(LibraryVariableStorage.DequeueText());
        Assert.IsFalse(PostedTransferReceiptLines.Previous(), 'Invalid number of records on the page');
    end;

    [ModalPageHandler]
    procedure ItemTrackingLinesModalPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ItemTrackingLinesModalPageHandlerGeneric(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        OptionString: Option AssignLotNo,AssignSerialNo,SelectEntries,ShowEntries,VerifyEntries,AssignManualLotNos;
        TrackingOption: Option;
        OptionValue: Variant;
        QtyVar: Variant;
        TrackingQtyToHandle: Decimal;
        TrackingQty: Decimal;
        LotNo: Code[20];
        SerialNo: Integer;
        Next: Boolean;
    begin
        LibraryVariableStorage.Dequeue(OptionValue);  // Dequeue variable.
        TrackingOption := OptionValue;  // To convert Variant into Option.
        case TrackingOption of
            OptionString::AssignLotNo:
                ItemTrackingLines."Assign Lot No.".Invoke();
            OptionString::AssignSerialNo:
                ItemTrackingLines."Assign Serial No.".Invoke();
            OptionString::SelectEntries:
                ItemTrackingLines."Select Entries".Invoke();
            OptionString::ShowEntries:
                begin
                    //Verify qty that has tracking
                    LibraryVariableStorage.Dequeue(QtyVar);  // Dequeue variable.
                    TrackingQtyToHandle := QtyVar;  // To convert Variant into Integer.
                    Assert.AreEqual(TrackingQtyToHandle, ItemTrackingLines.Handle1.AsDecimal(), 'Wrong quantity to handle on Item Tracking Lines page');

                    //Verify qty that should have tracking
                    LibraryVariableStorage.Dequeue(QtyVar);
                    TrackingQty := QtyVar;
                    Assert.AreEqual(TrackingQty, ItemTrackingLines.Quantity_ItemTracking.AsDecimal(), 'Wrong quantity using tracking on Item Tracking Lines page');
                end;
            OptionString::AssignManualLotNos:
                begin
                    TrackingQty := LibraryVariableStorage.DequeueDecimal();
                    repeat
                        SerialNo += 1;
                        if not Next then
                            LotNo := Format(LibraryVariableStorage.DequeueText());
                        UpdateItemTrackingLine(ItemTrackingLines, LotNo, Format(SerialNo));
                        ItemTrackingLines.Next();
                        TrackingQty -= 1;
                        if not Next then begin
                            Next := true;
                            LotNo := Format(LibraryVariableStorage.DequeueText());
                        end;
                    until TrackingQty = 0;
                end;
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedItemTrackingLinesHandler(var PostedItemTrackingLines: TestPage "Posted Item Tracking Lines")
    var
        QtySum: Decimal;
    begin
        QtySum := 0;
        repeat
            QtySum := QtySum + PostedItemTrackingLines.Quantity.AsDecimal();
        until not PostedItemTrackingLines.Next();
        LibraryVariableStorage.Enqueue(QtySum);
    end;


    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure QuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EditDimensionSetEntriesHandler(var EditDimensionSetEntries: TestPage "Edit Dimension Set Entries")
    begin
        EditDimensionSetEntries.New();
        EditDimensionSetEntries."Dimension Code".SetValue(LibraryVariableStorage.DequeueText());
        EditDimensionSetEntries.DimensionValueCode.SetValue(LibraryVariableStorage.DequeueText());
        EditDimensionSetEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedTransferShipmentLinesHandler(var PostedTransferShipmentLines: TestPage "Posted Transfer Shipment Lines")
    begin
        LibraryVariableStorage.Enqueue(PostedTransferShipmentLines.Filter.GetFilter("Line No."));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedTransferShipmentLinesGetDescriptionHandler(var PostedTransferShipmentLines: TestPage "Posted Transfer Shipment Lines")
    begin
        LibraryVariableStorage.Enqueue(PostedTransferShipmentLines.Description.Value);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedTransferReceiptLinesHandler(var PostedTransferReceiptLines: TestPage "Posted Transfer Receipt Lines")
    begin
        LibraryVariableStorage.Enqueue(PostedTransferReceiptLines.Filter.GetFilter("Line No."));
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1; // Ship
    end;

    [ModalPageHandler]
    procedure ItemListModalPageHandler(var ItemList: TestPage "Item List")
    begin
        // 0 = Item.Type::Inventory
        Assert.AreEqual('0', ItemList.Filter.GetFilter("Type"), 'Item List contains non-inventory items.');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchRcptLinesModalPageHandler(var PostedPurchaseReceiptLines: Page "Posted Purchase Receipt Lines"; var Response: Action)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange("Document No.", LibraryVariableStorage.DequeueText());
        PurchRcptLine.SetRange("No.", LibraryVariableStorage.DequeueText());
        PurchRcptLine.FindFirst();
        PostedPurchaseReceiptLines.SetRecord(PurchRcptLine);

        Response := ACTION::LookupOK;
    end;
}

