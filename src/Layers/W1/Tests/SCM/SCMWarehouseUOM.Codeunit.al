codeunit 137150 "SCM Warehouse UOM"
{
    Permissions = TableData "Whse. Item Tracking Line" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [SCM]
        isInitialized := false;
    end;

    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        OutputItemJournalTemplate: Record "Item Journal Template";
        OutputItemJournalBatch: Record "Item Journal Batch";
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingCode2: Record "Item Tracking Code";
        ItemTrackingCode3: Record "Item Tracking Code";
        ItemTrackingCode4: Record "Item Tracking Code";
        WarehouseEmployee: Record "Warehouse Employee";
        LocationBlue: Record Location;
        LocationGreen: Record Location;
        LocationIntransit: Record Location;
        LocationYellow: Record Location;
        LocationSilver: Record Location;
        LocationWhite: Record Location;
        LocationWhite2: Record Location;
        LocationWhite3: Record Location;
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryService: Codeunit "Library - Service";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        isInitialized: Boolean;
        ExceedsAvailableCapacity: Label '%1 to place (%2) exceeds the available capacity (%3) on %4 %5.', Comment = '%1= Field Caption,%2= Current capacity value,%3= Available Capacity,%4= Table Caption, %5= Field value.';
        BinContentMustBeDeleted: Label 'Bin Content must be deleted.';
        QuantityMustBeSame: Label 'Quantity must be same.';
        BinConfirmMessage: Label '\Do you still want to use this Bin ?';
        BlockMovementError: Label 'Block Movement must not be %1 in Bin Content Location Code=''%2'',Bin Code=''%3'',Item No.=''%4'',Variant Code='''',Unit of Measure Code=''%5''.', Comment = '%1 = Block Movement Value,%2 = Location Value,%3 = Bin Value,%4 = Item Value,%5 = Unit of Measure Value';
        ExpirationDateError: Label 'Expiration Date must not be %1 in Warehouse Activity Line Activity Type=''Invt. Put-away'',No.=''%2'',Line No.=''%3''.', Comment = '%1 = Date Value, %2 = Inventory Put Away No., %3 = Line No. ';
        ExpiredItemMsg: Label 'Some items were not included in the pick due to their expiration date.';
        PutAwayCreated: Label 'Number of Invt. Put-away activities created';
        PickCreated: Label 'Number of Invt. Pick activities created';
        InboundWarehouseCreated: Label 'Inbound Whse. Requests are created';
        PostJournalLines: Label 'Do you want to register and post the journal lines?';
        LinesRegistered: Label 'The journal lines were successfully registered';
        ChangeAffectExistingEntries: Label 'The change will not affect existing entries';
        TransferOrderDeleted: Label 'Transfer order %1 was successfully posted and is now deleted.', Comment = '%1 = Transfer Order No.';
        ProductionOrderCreated: Label 'Released Prod. Order';
        NothingToHandle: Label 'Nothing to handle.';
        JournalLinesPostedMsg: Label 'The journal lines were successfully posted.';
        CouldNotFindBinErr: Label 'Could not find Bin next to %1.';
        WrongTotalQtyErr: Label 'Wrong total quantity in registered pick lines.';
        ItemTrackingLineHandling: Option Create,"Use Existing";
        LotsAssignment: Option Partial,Complete;
        WhseActivLineQtyErr: Label 'Quantity in Warehouse Activity Line is not correct.';
        UnitOfMeasureCodeErr: Label 'Unit of Measure Code should be same';
        QuantityErr: Label 'Quantity is incorrect';
        ItemNoErr: Label 'Item No is incorrect';
        WhseReceiveIsRequiredErr: Label 'Warehouse Receive is required for Line No.';
        WhseShipmentIsRequiredErr: Label 'Warehouse Shipment is required for Line No.';
        BomLineType: Enum "Production BOM Line Type";
        CannotModifyUOMWithWhseEntriesErr: Label 'You cannot modify Item Unit of Measure', Comment = '%1 = Item Unit of Measure %2 = Code %3 = Item No.';
        QtyToHandleErr: Label '%1 must have a value', Comment = '%1 = Qty. to Handle';
        ItemTrackingMode: Option " ","Assign Lot No.","Select Lot No.","Select Entries","Assign Lot And Serial","Split Lot No.","Assign Serial No.","Select Multiple Lot No.";
        QuantityBaseAvailableMustNotBeLessErr: Label 'Quantity (Base) available must not be less than';
        WhsePickCreatedTxt: Label 'Pick activity no.';
        InsufficientQtyToPickInBinErr: Label 'The Qty. Outstanding (Base) %1 exceeds the quantity available to pick %2 of the Bin Content.', Comment = '%1: Field(Qty. Outstanding (Base)), %2: Quantity available to pick in bin.';
        UoMIsStillUsedError: Label 'You cannot delete the unit of measure because it is assigned to one or more records.';
        ItemTrackingQtyHandledErr: Label 'The Qty Handled (Base) is incorrect on the Item Tracking line.';
        QtyToHandleBaseErr: Label 'The Qty. to Handle (Base) is incorrect.';
        BinContentQtyErr: Label 'The quantity in the bin content was not updated.';

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure TFS360360_CreatePurcahseCreditMemoUsingCopyForLocationWithDirectedPutAwayPick()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO 360360.1] You can create Purchase Credit Memo for a Location with Directed Put-away and Pick using Copy Document (Purchase Line)
        Initialize();

        // [GIVEN] Create Purchase Order
        CreateReleasedPurchaseOrder(PurchaseHeader);
        // [GIVEN] Create and PostPost Whse. Receipt
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader);

        // [WHEN] Create Credit Memo using Copy Purchase Order
        asserterror CreateCreditMemoUsingCopyPurchase(PurchaseHeader."No.");

        // [THEN] Verify last error
        Assert.ExpectedError(WhseShipmentIsRequiredErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ProductionJournalHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TFS360360_CreateSalesCreditMemoUsingCopyForLocationWithDirectedPutAwayPick()
    var
        SalesHeaderNo: Code[20];
    begin
        // [SCENARIO 360360.2] You can create Sales Credit Memo for a Location with Directed Put-away and Pick using Copy Document (Sales Line)
        Initialize();

        // [GIVEN] Create a Movement Worksheet, Sales Order, Post Whse. Shipment, create Sales Credit Memo
        CreateAndPostWhseShptFromSalesOrderUsingMovement(SalesHeaderNo);

        // [WHEN] Create Credit Memo using Copy Sales Order
        asserterror CreateCreditMemoUsingCopySales(SalesHeaderNo);

        // [THEN] Verify last error
        Assert.ExpectedError(WhseReceiveIsRequiredErr);
    end;

    [Normal]
    local procedure TFS339073(ILEQuantity: Decimal; QtyPerUOM: Decimal; TransferQty: Decimal; CrossDockQty: Decimal)
    var
        ReservEntry: Record "Reservation Entry";
        WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNo1: Code[50];
        LotNo2: Code[50];
    begin
        ILEQuantity := 10;

        // Setup : Create lot tracked item, with additional UOM used for put-away.
        Initialize();
        CreateItem(Item, ItemTrackingCode.Code);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", QtyPerUOM);
        UpdateItemUOM(Item, Item."Base Unit of Measure", Item."Base Unit of Measure", ItemUnitOfMeasure.Code);

        // Post positive adjustment in non-warehouse location.
        LotNo1 := LibraryUtility.GenerateRandomCode(WarehouseActivityLine.FieldNo("Lot No."), DATABASE::"Warehouse Activity Line");
        LibraryItemTracking.PostPositiveAdjustmentWithItemTracking(Item, LocationBlue.Code, '', ILEQuantity, WorkDate(), '', LotNo1);
        LibraryItemTracking.PostPositiveAdjustmentWithItemTracking(Item, LocationBlue.Code, '', ILEQuantity, WorkDate(), '', LotNo1);

        LotNo2 := LibraryUtility.GenerateRandomCode(WarehouseActivityLine.FieldNo("Lot No."), DATABASE::"Warehouse Activity Line");
        LibraryItemTracking.PostPositiveAdjustmentWithItemTracking(Item, LocationBlue.Code, '', ILEQuantity, WorkDate(), '', LotNo2);
        LibraryItemTracking.PostPositiveAdjustmentWithItemTracking(Item, LocationBlue.Code, '', ILEQuantity, WorkDate(), '', LotNo2);

        // Create transfer order to WHITE, post shipment, create whse. receipt.
        CreateAndReleaseTransferOrder(TransferHeader, LocationBlue.Code, LocationWhite.Code, Item."No.", TransferQty, ItemUnitOfMeasure.Code);
        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.FindFirst();

        // Split the transfer quantity across lots or not.
        if TransferQty * QtyPerUOM <= 2 * ILEQuantity then
            LibraryItemTracking.CreateTransferOrderItemTracking(ReservEntry, TransferLine, '', LotNo1, TransferQty * QtyPerUOM)
        else begin
            LibraryItemTracking.CreateTransferOrderItemTracking(ReservEntry, TransferLine, '', LotNo1, 2 * ILEQuantity);
            LibraryItemTracking.CreateTransferOrderItemTracking(
              ReservEntry, TransferLine, '', LotNo2, TransferQty * QtyPerUOM - 2 * ILEQuantity);
        end;
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        LibraryWarehouse.CreateWhseReceiptFromTO(TransferHeader);

        // Force cross-dock.
        if CrossDockQty > 0 then
            CreateAndReleaseSalesOrder(SalesHeader, SalesLine, Item."No.", Item."Base Unit of Measure", LocationWhite.Code, CrossDockQty, false);
        FindWarehouseReceiptLine(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Inbound Transfer", TransferHeader."No.");
        LibraryWarehouse.CalculateCrossDockLines(
          WhseCrossDockOpportunity, '', WarehouseReceiptLine."No.", WarehouseReceiptLine."Location Code");

        // Exercise: Post receipt.
        LibraryVariableStorage.Enqueue(StrSubstNo(TransferOrderDeleted, TransferHeader."No."));  // Enqueue for MessageHandler.
        PostWarehouseReceipt(WarehouseReceiptLine."No.");

        // Verify: Put-away lines.
        // Put-away is not split across lots.
        if TransferQty * QtyPerUOM <= 2 * ILEQuantity then begin
            VerifyWhseActivityLine(
              WarehouseActivityLine, TransferHeader."No.", LotNo1, WarehouseActivityLine."Action Type"::Take, TransferQty * QtyPerUOM);

            if CrossDockQty > 0 then begin
                WarehouseActivityLine.SetRange("Bin Code", LocationWhite."Cross-Dock Bin Code");
                VerifyWhseActivityLine(
                  WarehouseActivityLine, TransferHeader."No.", LotNo1, WarehouseActivityLine."Action Type"::Place, CrossDockQty);

                WarehouseActivityLine.SetFilter("Bin Code", '<>%1', LocationWhite."Cross-Dock Bin Code");
                VerifyWhseActivityLine(
                  WarehouseActivityLine, TransferHeader."No.", LotNo1, WarehouseActivityLine."Action Type"::Place,
                  TransferQty * QtyPerUOM - CrossDockQty);
            end else begin
                WarehouseActivityLine.SetFilter("Bin Code", '<>%1', LocationWhite."Cross-Dock Bin Code");
                VerifyWhseActivityLine(
                  WarehouseActivityLine, TransferHeader."No.", LotNo1, WarehouseActivityLine."Action Type"::Place, TransferQty * QtyPerUOM);
            end;

            // Put-away is split across lots.
        end else begin
            VerifyWhseActivityLine(
              WarehouseActivityLine, TransferHeader."No.", LotNo1, WarehouseActivityLine."Action Type"::Take, 2 * ILEQuantity);
            VerifyWhseActivityLine(
              WarehouseActivityLine, TransferHeader."No.", LotNo2, WarehouseActivityLine."Action Type"::Take,
              TransferQty * QtyPerUOM - 2 * ILEQuantity);

            // How is the cross dock qty distributed across lots?
            case true of
                (CrossDockQty > 0) and (CrossDockQty <= 2 * ILEQuantity):
                    // Cross dock qty consumes only from Lot 1.
                    begin
                        WarehouseActivityLine.SetRange("Bin Code", LocationWhite."Cross-Dock Bin Code");
                        VerifyWhseActivityLine(
                          WarehouseActivityLine, TransferHeader."No.", LotNo1, WarehouseActivityLine."Action Type"::Place, CrossDockQty);

                        WarehouseActivityLine.SetFilter("Bin Code", '<>%1', LocationWhite."Cross-Dock Bin Code");
                        VerifyWhseActivityLine(
                          WarehouseActivityLine, TransferHeader."No.", LotNo1, WarehouseActivityLine."Action Type"::Place,
                          2 * ILEQuantity - CrossDockQty);
                        VerifyWhseActivityLine(
                          WarehouseActivityLine, TransferHeader."No.", LotNo2, WarehouseActivityLine."Action Type"::Place,
                          TransferQty * QtyPerUOM - 2 * ILEQuantity);
                    end;
                (CrossDockQty > 0) and (CrossDockQty > 2 * ILEQuantity) and (CrossDockQty <= TransferQty * QtyPerUOM):
                    // Cross dock qty consumes Lot 1 entirely and Lot 2 partially.
                    begin
                        WarehouseActivityLine.SetRange("Bin Code", LocationWhite."Cross-Dock Bin Code");
                        VerifyWhseActivityLine(
                          WarehouseActivityLine, TransferHeader."No.", LotNo1, WarehouseActivityLine."Action Type"::Place, 2 * ILEQuantity);
                        VerifyWhseActivityLine(
                          WarehouseActivityLine, TransferHeader."No.", LotNo2, WarehouseActivityLine."Action Type"::Place,
                          CrossDockQty - 2 * ILEQuantity);

                        WarehouseActivityLine.SetFilter("Bin Code", '<>%1', LocationWhite."Cross-Dock Bin Code");
                        VerifyWhseActivityLine(
                          WarehouseActivityLine, TransferHeader."No.", LotNo2, WarehouseActivityLine."Action Type"::Place,
                          TransferQty * QtyPerUOM - CrossDockQty);
                        asserterror VerifyWhseActivityLine(
                            WarehouseActivityLine, TransferHeader."No.", LotNo1, WarehouseActivityLine."Action Type"::Place, 0);
                        Assert.AssertNothingInsideFilter();
                    end;
                (CrossDockQty > 0) and (CrossDockQty > 2 * ILEQuantity) and (CrossDockQty > TransferQty * QtyPerUOM):
                    // Cross dock qty consumes both Lot 1 and Lot 2.
                    begin
                        WarehouseActivityLine.SetRange("Bin Code", LocationWhite."Cross-Dock Bin Code");
                        VerifyWhseActivityLine(
                          WarehouseActivityLine, TransferHeader."No.", LotNo1, WarehouseActivityLine."Action Type"::Place, 2 * ILEQuantity);
                        VerifyWhseActivityLine(
                          WarehouseActivityLine, TransferHeader."No.", LotNo2, WarehouseActivityLine."Action Type"::Place,
                          TransferQty * QtyPerUOM - 2 * ILEQuantity);

                        WarehouseActivityLine.SetFilter("Bin Code", '<>%1', LocationWhite."Cross-Dock Bin Code");
                        asserterror VerifyWhseActivityLine(
                            WarehouseActivityLine, TransferHeader."No.", LotNo1, WarehouseActivityLine."Action Type"::Place, 0);
                        Assert.AssertNothingInsideFilter();
                        asserterror VerifyWhseActivityLine(
                            WarehouseActivityLine, TransferHeader."No.", LotNo2, WarehouseActivityLine."Action Type"::Place, 0);
                        Assert.AssertNothingInsideFilter();
                    end;
                CrossDockQty = 0:
                    begin
                        VerifyWhseActivityLine(
                          WarehouseActivityLine, TransferHeader."No.", LotNo1, WarehouseActivityLine."Action Type"::Place, 2 * ILEQuantity);
                        VerifyWhseActivityLine(
                          WarehouseActivityLine, TransferHeader."No.", LotNo2, WarehouseActivityLine."Action Type"::Place,
                          TransferQty * QtyPerUOM - 2 * ILEQuantity);
                    end;
            end;
        end;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TFS339073_SameLotSameILEWithoutCrossDock()
    begin
        TFS339073(10, 8, 1, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TFS339073_SameLotSameILECrossDock()
    begin
        TFS339073(10, 8, 1, 5);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TFS339073_SameLotSplitILEWithoutCrossDock()
    begin
        TFS339073(10, 12, 1, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TFS339073_SameLotSplitILECrossDock()
    begin
        TFS339073(10, 12, 1, 5);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TFS339073_TwoLotsWithoutCrossDock()
    begin
        TFS339073(10, 12, 2, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TFS339073_TwoLotsCrossDockFirstLot()
    begin
        TFS339073(10, 12, 2, 15);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TFS339073_TwoLotsCrossDockBothLots()
    begin
        TFS339073(10, 12, 2, 22);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TFS339073_TwoLotsCrossDockWholeQty()
    begin
        TFS339073(10, 12, 2, 25);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinContentDeletedAfterRegisteringPick()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // Setup : Create Sales Order, Warehouse Shipment and Pick.
        Initialize();
        CreateItem(Item, '');
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandInt(5) + 1);  // Value required for multiple UOM with different conversion rate.
        FindBin(Bin, LocationWhite.Code, false, true, true);  // Find PICK Bin.
        Quantity := LibraryRandom.RandDec(100, 2);
        UpdateInventoryUsingWarehouseJournal(
          Bin, Item, Item."Base Unit of Measure", Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure", false, ItemTrackingMode::" ",
          WorkDate());
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, Item."No.", ItemUnitOfMeasure.Code, Bin."Location Code", Quantity, false);  // Use FALSE for without Tracking.
        CreatePickFromWarehouseShipment(SalesHeader);

        // Exercise : Register Pick.
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);

        // Verify : Verify empty Bin Content must be deleted.
        FindBinContent(BinContent, Bin, Item."No.");
        Assert.IsTrue(BinContent.IsEmpty, BinContentMustBeDeleted);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure QuantityToPlaceExceedsAvailableCapacityError()
    var
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // Setup : Create Bin Content with maximum Quantity. Create and release Purchase Order with multiple UOM.
        Initialize();
        CreateItem(Item, '');
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandInt(5) + 1);  // Value required for multiple UOM with different conversion rate.
        FindBin(Bin, LocationWhite.Code, true, false, false);  // Find RECEIVE Bin.
        CreateBinContent(BinContent, Bin, Item."No.", Item."Base Unit of Measure", LibraryRandom.RandDec(100, 2));
        CreateBinContent(BinContent, Bin, Item."No.", ItemUnitOfMeasure.Code, BinContent."Max. Qty.");
        Quantity := BinContent."Max. Qty." + LibraryRandom.RandDec(100, 2);
        CreateAndReleasePurchaseOrderWithMultipleUOM(
          PurchaseHeader, Item."No.", ItemUnitOfMeasure.Code, '', LocationWhite.Code, Quantity, false);  // Use FALSE for without Tracking.

        // Exercise.
        asserterror CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader);

        // Verify : Verify exceeds available capacity error message.
        Assert.ExpectedError(
          StrSubstNo(
            ExceedsAvailableCapacity, WarehouseActivityLine.FieldCaption("Qty. (Base)"),
            Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure",
            BinContent."Max. Qty.", BinContent.TableCaption(), BinContent."Bin Code"));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure WarehousePickFromSalesOrderUsingLotItemTrackingWithMultipleUOM()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        // Setup : Create and release Purchase Order with multiple UOM. Create Warehouse Receipt and Put Away. Create Sales Order, Warehouse Shipment and Pick.
        Initialize();
        CreateItem(Item, ItemTrackingCode.Code);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", 2);  // Value required for multiple UOM with different conversion rate.
        CreateAndReleasePurchaseOrderWithMultipleUOM(
          PurchaseHeader, Item."No.", Item."Base Unit of Measure", ItemUnitOfMeasure.Code, LocationWhite.Code,
          ItemUnitOfMeasure."Qty. per Unit of Measure", true);
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Lot No.");  // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
        CreateAndReleaseSalesOrder(
          SalesHeader, SalesLine, Item."No.", Item."Base Unit of Measure", LocationWhite.Code,
          ItemUnitOfMeasure."Qty. per Unit of Measure" / 2, true);  // Quantity must be less than available Inventory. Use TRUE for with Tracking.
        CreatePickFromWarehouseShipment(SalesHeader);

        // Exercise : Register Pick.
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);

        // Verify.
        VerifyRegisteredWhseActivityLine(
          RegisteredWhseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", RegisteredWhseActivityLine."Activity Type"::Pick,
          RegisteredWhseActivityLine."Action Type"::Take, SalesLine."Qty. per Unit of Measure",
          ItemUnitOfMeasure."Qty. per Unit of Measure", ItemUnitOfMeasure.Code);

        VerifyRegisteredWhseActivityLine(
          RegisteredWhseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", RegisteredWhseActivityLine."Activity Type"::Pick,
          RegisteredWhseActivityLine."Action Type"::Place, SalesLine.Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure",
          ItemUnitOfMeasure."Qty. per Unit of Measure", Item."Base Unit of Measure");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure WarehousePutAwayFromPurchaseOrderUsingLotItemTrackingWithPutAwayUOM()
    var
        Item: Record Item;
        ItemUnitOfMeasureSales: Record "Item Unit of Measure";
        ItemUnitOfMeasurePutAway: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        Quantity: Decimal;
    begin
        // Setup : Create and release Purchase Order with multiple UOM. Create Warehouse Receipt and Put Away.
        Initialize();
        CreateItemWithMultipleUOM(Item, ItemUnitOfMeasureSales, ItemUnitOfMeasurePutAway, ItemTrackingCode.Code);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndReleasePurchaseOrderWithMultipleUOM(
          PurchaseHeader, Item."No.", Item."Purch. Unit of Measure", Item."Put-away Unit of Measure Code", LocationWhite.Code, Quantity, true);  // Use TRUE for with Tracking.
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader);

        // Exercise : Register Put-Away.
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");

        // Verify.
        VerifyRegisteredWhseActivityLine(
          RegisteredWhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          RegisteredWhseActivityLine."Activity Type"::"Put-away",
          RegisteredWhseActivityLine."Action Type"::Take, Quantity, Quantity, Item."Purch. Unit of Measure");

        VerifyRegisteredWhseActivityLine(
          RegisteredWhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          RegisteredWhseActivityLine."Activity Type"::"Put-away",
          RegisteredWhseActivityLine."Action Type"::Place, Quantity / ItemUnitOfMeasurePutAway."Qty. per Unit of Measure", Quantity,
          ItemUnitOfMeasurePutAway.Code);  // Value required for test.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure WarehouseShipmentFromSalesOrderUsingLotItemTrackingWithPutAwayUOM()
    var
        Item: Record Item;
        ItemUnitOfMeasureSales: Record "Item Unit of Measure";
        ItemUnitOfMeasurePutAway: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseEntry: Record "Warehouse Entry";
        TempReservationEntry: Record "Reservation Entry" temporary;
        Quantity: Decimal;
    begin
        // Setup : Create and release Purchase Order with multiple UOM. Create Warehouse Receipt and Put Away. Create Sales Order, Warehouse Shipment and Pick.
        Initialize();
        CreateItemWithMultipleUOM(Item, ItemUnitOfMeasureSales, ItemUnitOfMeasurePutAway, ItemTrackingCode.Code);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndReleasePurchaseOrderWithMultipleUOM(
          PurchaseHeader, Item."No.", Item."Purch. Unit of Measure", Item."Put-away Unit of Measure Code", LocationWhite2.Code, Quantity,
          true);  // Use TRUE for with Tracking.
        CopyReservationEntry(TempReservationEntry, Item."No.");
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Lot No.");  // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
        CreateSalesLineWithUOM(SalesLine, SalesHeader, Item."No.", Item."Purch. Unit of Measure", LocationWhite2.Code, Quantity, true, true);  // Use TRUE for with Tracking.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Lot No.");  // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
        CreateSalesLineWithUOM(
          SalesLine, SalesHeader, Item."No.", Item."Put-away Unit of Measure Code", LocationWhite2.Code, Quantity / 2, true, false);  // Use Quantity / 2 for splitting into 2 lines required for test case.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Lot No.");  // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
        CreateSalesLineWithUOM(
          SalesLine, SalesHeader, Item."No.", Item."Put-away Unit of Measure Code", LocationWhite2.Code, Quantity / 2, true, false);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);

        // Exercise.
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);  // Use FALSE for only Shipment.

        // Verify : Warehouse Entries for Location, Bin, Lot No., Quantity and Quantity (Base).
        TempReservationEntry.FindSet();
        VerifyWarehouseEntry(
          WarehouseEntry."Entry Type"::"Positive Adjmt.", Item."No.", Item."Purch. Unit of Measure", LocationWhite2.Code,
          LocationWhite2."Receipt Bin Code", TempReservationEntry."Lot No.", Quantity, Quantity);
        VerifyWarehouseEntry(
          WarehouseEntry."Entry Type"::"Negative Adjmt.", Item."No.", Item."Purch. Unit of Measure", LocationWhite2.Code,
          LocationWhite2."Shipment Bin Code", TempReservationEntry."Lot No.", -Quantity, -Quantity);
        TempReservationEntry.Next();
        VerifyWarehouseEntry(
          WarehouseEntry."Entry Type"::"Positive Adjmt.", Item."No.", Item."Put-away Unit of Measure Code", LocationWhite2.Code,
          LocationWhite2."Receipt Bin Code",
          TempReservationEntry."Lot No.", Quantity, Quantity * ItemUnitOfMeasurePutAway."Qty. per Unit of Measure");
        VerifyWarehouseEntry(
          WarehouseEntry."Entry Type"::"Negative Adjmt.", Item."No.", Item."Put-away Unit of Measure Code", LocationWhite2.Code,
          LocationWhite2."Shipment Bin Code", TempReservationEntry."Lot No.", -SalesLine.Quantity, -SalesLine."Quantity (Base)");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure WarehouseShipmentFromSalesOrderUsingLotItemTrackingWithMultipleUOM()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TempReservationEntry: Record "Reservation Entry" temporary;
    begin
        // Setup : Create and release Purchase Order with multiple UOM. Create Warehouse Receipt and Put Away.
        Initialize();
        CreateItem(Item, ItemTrackingCode.Code);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandInt(5) + 1);  // Value required for multiple UOM with different conversion rate.
        CreateAndReleasePurchaseOrderWithMultipleUOM(
          PurchaseHeader, Item."No.", Item."Base Unit of Measure", ItemUnitOfMeasure.Code, LocationWhite2.Code,
          ItemUnitOfMeasure."Qty. per Unit of Measure", true);
        CopyReservationEntry(TempReservationEntry, Item."No.");
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");

        // Exercise.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Lot No.");  // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
        CreateAndPostWarehouseShipmentFromSalesOrder(
          SalesLine, Item."No.", Item."Base Unit of Measure", LocationWhite2.Code, ItemUnitOfMeasure."Qty. per Unit of Measure" / 2, true);

        // Verify : Item Ledger Entries for Location, Lot No., Quantity and Remaining Quantity.
        TempReservationEntry.FindSet();
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Purchase, Item."No.", Item."Base Unit of Measure", LocationWhite2.Code,
          TempReservationEntry."Lot No.", ItemUnitOfMeasure."Qty. per Unit of Measure", ItemUnitOfMeasure."Qty. per Unit of Measure");
        TempReservationEntry.Next();
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Purchase, Item."No.", ItemUnitOfMeasure.Code, LocationWhite2.Code, TempReservationEntry."Lot No.",
          ItemUnitOfMeasure."Qty. per Unit of Measure" * ItemUnitOfMeasure."Qty. per Unit of Measure",
          ItemUnitOfMeasure."Qty. per Unit of Measure" * ItemUnitOfMeasure."Qty. per Unit of Measure" - SalesLine.Quantity);
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Sale, Item."No.", Item."Base Unit of Measure", LocationWhite2.Code, TempReservationEntry."Lot No.",
          -SalesLine.Quantity, 0);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PartialWarehouseShipmentFromSalesOrderUsingLotItemTracking()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // Setup : Create and release Purchase Order with multiple UOM. Create Warehouse Receipt and Put Away.
        Initialize();
        CreateItem(Item, ItemTrackingCode.Code);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandDec(10, 5) + 1);  // Decimal value required for multiple UOM with different conversion rate.
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndReleasePurchaseOrderWithMultipleUOM(
          PurchaseHeader, Item."No.", ItemUnitOfMeasure.Code, '', LocationWhite2.Code, Quantity, true);  // Use TRUE for with Tracking.
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");

        // Exercise.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Lot No.");  // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
        CreateAndPostWarehouseShipmentFromSalesOrder(SalesLine, Item."No.", ItemUnitOfMeasure.Code, LocationWhite2.Code, Quantity / 2, true);  // Use Quantity / 2 for partial posting. Use TRUE for with Tracking.

        // Verify.
        VerifyRegisteredWhseActivityLine(
          RegisteredWhseActivityLine."Source Document"::"Sales Order", SalesLine."Document No.",
          RegisteredWhseActivityLine."Activity Type"::Pick,
          RegisteredWhseActivityLine."Action Type"::Take, SalesLine.Quantity, SalesLine."Quantity (Base)",
          SalesLine."Unit of Measure Code");

        VerifyRegisteredWhseActivityLine(
          RegisteredWhseActivityLine."Source Document"::"Sales Order", SalesLine."Document No.",
          RegisteredWhseActivityLine."Activity Type"::Pick,
          RegisteredWhseActivityLine."Action Type"::Place, SalesLine.Quantity, SalesLine."Quantity (Base)",
          SalesLine."Unit of Measure Code");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure FullWarehouseShipmentFromSalesOrderUsingLotItemTracking()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TempReservationEntry: Record "Reservation Entry" temporary;
        Quantity: Decimal;
    begin
        // Setup : Create and release Purchase Order with multiple UOM. Create Warehouse Receipt and Put Away. Create Sales Order, Warehouse Shipment and Pick. Post Warehouse Shipment.
        Initialize();
        CreateItem(Item, ItemTrackingCode.Code);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", 2);  // Decimal value required for multiple UOM with different conversion rate.
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndReleasePurchaseOrderWithMultipleUOM(
          PurchaseHeader, Item."No.", ItemUnitOfMeasure.Code, '', LocationWhite3.Code, Quantity, true);  // Use TRUE for with Tracking.
        CopyReservationEntry(TempReservationEntry, Item."No.");
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Lot No.");  // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
        CreateAndPostWarehouseShipmentFromSalesOrder(SalesLine, Item."No.", ItemUnitOfMeasure.Code, LocationWhite3.Code, Quantity / 2, true);  // Use Quantity / 2 for partial posting. Use TRUE for with Tracking.

        // Exercise.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Lot No.");  // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
        CreateAndPostWarehouseShipmentFromSalesOrder(SalesLine, Item."No.", ItemUnitOfMeasure.Code, LocationWhite3.Code, Quantity / 2, true);

        // Verify : Item Ledger Entries for Location, Lot No., Quantity and Remaining Quantity.
        TempReservationEntry.FindFirst();
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Purchase, Item."No.", ItemUnitOfMeasure.Code, LocationWhite3.Code, TempReservationEntry."Lot No.",
          Round(Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure", 0.00001), 0);
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Sale, Item."No.", ItemUnitOfMeasure.Code, LocationWhite3.Code, TempReservationEntry."Lot No.",
          -SalesLine."Quantity (Base)", 0);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure WarehouseShipmentFromSalesOrderUsingMultipleLotNoWithMultipleUOM()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Setup : Create and release Purchase Order with multiple UOM. Create Warehouse Receipt and Put Away.
        Initialize();
        CreateItem(Item, ItemTrackingCode.Code);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", 2);  // Value required for multiple UOM with different conversion rate.
        CreateAndReleasePurchaseOrderWithMultipleUOM(
          PurchaseHeader, Item."No.", Item."Base Unit of Measure", Item."Base Unit of Measure", LocationWhite3.Code,
          ItemUnitOfMeasure."Qty. per Unit of Measure", true);  // Use TRUE for with Tracking.
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");

        // Exercise.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");  // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
        CreateAndPostWarehouseShipmentFromSalesOrder(SalesLine, Item."No.", ItemUnitOfMeasure.Code, LocationWhite3.Code, 2, true);  // 2 required for the 2 Purchase Lines.

        // Verify.
        VerifyRegisteredWhseActivityLine(
          RegisteredWhseActivityLine."Source Document"::"Sales Order", SalesLine."Document No.",
          RegisteredWhseActivityLine."Activity Type"::Pick,
          RegisteredWhseActivityLine."Action Type"::Take, SalesLine.Quantity, SalesLine."Quantity (Base)" / 2, Item."Base Unit of Measure");

        VerifyRegisteredWhseActivityLine(
          RegisteredWhseActivityLine."Source Document"::"Sales Order", SalesLine."Document No.",
          RegisteredWhseActivityLine."Activity Type"::Pick,
          RegisteredWhseActivityLine."Action Type"::Place, SalesLine.Quantity / 2, SalesLine."Quantity (Base)" / 2, ItemUnitOfMeasure.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehouseShipmentFromSalesOrderWithDifferentSalesAndPurchaseUOM()
    var
        Item: Record Item;
        ItemUnitOfMeasurePurchase: Record "Item Unit of Measure";
        ItemUnitOfMeasureSales: Record "Item Unit of Measure";
        ItemUnitOfMeasurePutAway: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Quantity: Decimal;
    begin
        // Setup : Create Item with multiple UOM without Item Tracking. Create and release Purchase Order with multiple UOM. Create Warehouse Receipt and Put Away.
        Initialize();
        CreateItemWithMultipleUOM(Item, ItemUnitOfMeasureSales, ItemUnitOfMeasurePutAway, '');
        CreateItemUnitOfMeasure(ItemUnitOfMeasurePurchase, Item."No.", 2);  // Value required for multiple UOM with different conversion rate.
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndReleasePurchaseOrderWithMultipleUOM(
          PurchaseHeader, Item."No.", ItemUnitOfMeasurePurchase.Code, '', LocationWhite3.Code, Quantity, false);  // Use FALSE for without Tracking.
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");

        // Exercise.
        CreateAndPostWarehouseShipmentFromSalesOrder(
          SalesLine, Item."No.", Item."Sales Unit of Measure", LocationWhite3.Code,
          Quantity * ItemUnitOfMeasurePurchase."Qty. per Unit of Measure" / ItemUnitOfMeasureSales."Qty. per Unit of Measure", false);  // Use FALSE for without Tracking.

        // Verify : Item Ledger Entries for Location, Quantity and Remaining Quantity.
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Purchase, Item."No.", ItemUnitOfMeasurePurchase.Code, LocationWhite3.Code, '',
          Quantity * ItemUnitOfMeasurePurchase."Qty. per Unit of Measure", 0);
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Sale, Item."No.", ItemUnitOfMeasureSales.Code, LocationWhite3.Code, '',
          -SalesLine."Quantity (Base)", 0);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler,ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure WarehousePickFromSalesOrderUsingSameExpirationDateWithPickAccordingToFEFO()
    begin
        // Setup.
        Initialize();
        WarehousePickFromSalesOrderUsingLotItemTracking(true, true);  // Use Pick According To FEFO as True.
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler,ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure WarehousePickFromSalesOrderUsingDifferentExpirationDateWithPickAccordingToFEFO()
    begin
        // Setup.
        Initialize();
        WarehousePickFromSalesOrderUsingLotItemTracking(true, false);  // Use Pick According To FEFO as True.
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler,ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure WarehousePickFromSalesOrderUsingDifferentExpirationDateWithoutPickAccordingToFEFO()
    begin
        // Setup.
        Initialize();
        WarehousePickFromSalesOrderUsingLotItemTracking(false, true);  // Use Pick According To FEFO as False.
    end;

    local procedure WarehousePickFromSalesOrderUsingLotItemTracking(PickAccordingToFEFO: Boolean; SameExpirationDate: Boolean)
    var
        Bin: Record Bin;
        Item: Record Item;
        ItemUnitOfMeasureSales: Record "Item Unit of Measure";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ExpirationDates: array[3] of Date;
        OldPickAccordingToFEFO: Boolean;
    begin
        // Update Pick According to FEFO on Location. Create Item and update Inventory with Strict Expiration Posting Item Tracking Code. Create Pick from Sales Order.
        UpdatePickAccordingToFEFOOnLocation(LocationWhite2, OldPickAccordingToFEFO, PickAccordingToFEFO);
        CreateItem(Item, ItemTrackingCode2.Code);
        CreateItemUnitOfMeasure(ItemUnitOfMeasureSales, Item."No.", LibraryRandom.RandInt(5) + 1);  // Value required for multiple UOM with different conversion rate.
        UpdateItemUOM(Item, Item."Base Unit of Measure", ItemUnitOfMeasureSales.Code, ItemUnitOfMeasureSales.Code);
        FindBin(Bin, LocationWhite2.Code, false, true, true);  // Find PICK Bin.
        ExpirationDates[1] := WorkDate();
        ExpirationDates[2] := WorkDate();
        ExpirationDates[3] := WorkDate();
        if not SameExpirationDate then begin
            ExpirationDates[2] := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
            ExpirationDates[3] := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', ExpirationDates[3]);  // Value required for test.
        end;

        UpdateInventoryUsingWarehouseJournal(
          Bin, Item, ItemUnitOfMeasureSales.Code, ItemUnitOfMeasureSales."Qty. per Unit of Measure", true,
          ItemTrackingMode::"Assign Lot No.", ExpirationDates[1]);
        UpdateInventoryUsingWarehouseJournal(
          Bin, Item, ItemUnitOfMeasureSales.Code, ItemUnitOfMeasureSales."Qty. per Unit of Measure", true,
          ItemTrackingMode::"Assign Lot No.", ExpirationDates[2]);
        UpdateInventoryUsingWarehouseJournal(
          Bin, Item, Item."Base Unit of Measure", ItemUnitOfMeasureSales."Qty. per Unit of Measure", true,
          ItemTrackingMode::"Assign Lot No.", ExpirationDates[3]);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");  // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
        CreateAndReleaseSalesOrder(
          SalesHeader, SalesLine, Item."No.", ItemUnitOfMeasureSales.Code, Bin."Location Code",
          ItemUnitOfMeasureSales."Qty. per Unit of Measure" + 1, true);
        CreatePickFromWarehouseShipment(SalesHeader);

        // Exercise.
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);

        // Verify : Verify Lot No., Expiration Date and Quantity (Base) on Warehouse Activity Lines.
        VerifyRegisteredWhseActivityLines(SalesLine, SameExpirationDate);

        // Tear down.
        UpdatePickAccordingToFEFOOnLocation(LocationWhite2, OldPickAccordingToFEFO, OldPickAccordingToFEFO);
    end;

    [Test]
    [HandlerFunctions('CubageAndWeightExceedConfirmHandler')]
    [Scope('OnPrem')]
    procedure CubageToPlaceExceedsAvailableCapacityError()
    begin
        // Setup.
        Initialize();
        MaximumCubageAndWeightOnWarehousePutAway(LibraryRandom.RandInt(5), 0);  // Value required for Maximum Cubage.
    end;

    [Test]
    [HandlerFunctions('CubageAndWeightExceedConfirmHandler')]
    [Scope('OnPrem')]
    procedure WeightToPlaceExceedsAvailableCapacityError()
    begin
        // Setup.
        Initialize();
        MaximumCubageAndWeightOnWarehousePutAway(0, LibraryRandom.RandInt(5));  // Value required for Maximum Weight.
    end;

    local procedure MaximumCubageAndWeightOnWarehousePutAway(Length: Decimal; Weight: Decimal)
    var
        Item: Record Item;
        Bin: Record Bin;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        ExpectedError: Text[1024];
        Quantity: Decimal;
    begin
        // Create Item with Unit Of Measure having Cubage and Weight. Create and release Purchase Order. Create and post Warehouse Receipt.
        CreateItem(Item, '');
        UpdateCubageAndWeightOnItemUOM(ItemUnitOfMeasure, Item, Length, Weight);  // Use same Length, Width and Height.
        UpdateBinWithMaximumCubageAndWeight(
          Bin, LocationWhite.Code, LocationWhite."Receipt Bin Code", ItemUnitOfMeasure.Cubage, ItemUnitOfMeasure.Weight);
        Quantity := LibraryRandom.RandInt(100) + 1;  // Quantity must be greater than 1 required for test.
        CreateAndReleasePurchaseOrderWithMultipleUOM(
          PurchaseHeader, Item."No.", ItemUnitOfMeasure.Code, '', LocationWhite.Code, Quantity, false);  // Use FALSE for without Tracking.
        ExpectedError :=
          StrSubstNo(
            ExceedsAvailableCapacity, ItemUnitOfMeasure.FieldCaption(Cubage), Quantity * ItemUnitOfMeasure.Cubage,
            ItemUnitOfMeasure.Cubage, Bin.TableCaption(), Bin.Code);
        if Weight <> 0 then
            ExpectedError :=
              StrSubstNo(
                ExceedsAvailableCapacity, ItemUnitOfMeasure.FieldCaption(Weight), Quantity * ItemUnitOfMeasure.Weight,
                ItemUnitOfMeasure.Weight, Bin.TableCaption(), Bin.Code);

        LibraryVariableStorage.Enqueue(ExpectedError + BinConfirmMessage);  // Enqueue ExpectedError at index 1 for CubageAndWeightExceedConfirmHandler.

        // Exercise :
        asserterror CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader);

        // Verify : Verification is performed on CubageAndWeightExceedConfirmHandler.
        Assert.ExpectedError(ExpectedError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure UOMConversionOnMovementWorksheetUsingLotItemTracking()
    begin
        // Setup.
        Initialize();
        UOMConversionOnMovementUsingItemTracking(false);  // Use Movement as False.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure UOMConversionOnMovementUsingLotItemTracking()
    begin
        // Setup.
        Initialize();
        UOMConversionOnMovementUsingItemTracking(true);  // Use Movement as True.
    end;

    local procedure UOMConversionOnMovementUsingItemTracking(Movement: Boolean)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        TempReservationEntry: Record "Reservation Entry" temporary;
        Quantity: Decimal;
    begin
        // Create Item with multiple UOM with Item Tracking. Create and release Purchase Order. Create Warehouse Receipt and Put Away.
        CreateItem(Item, ItemTrackingCode.Code);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandInt(5) + 1);  // Value required for multiple UOM with different conversion rate.
        UpdateItemUOM(Item, ItemUnitOfMeasure.Code, '', '');
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndReleasePurchaseOrderWithMultipleUOM(
          PurchaseHeader, Item."No.", ItemUnitOfMeasure.Code, '', LocationWhite3.Code, Quantity, true);  // Use FALSE for without Tracking.
        CopyReservationEntry(TempReservationEntry, Item."No.");
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");

        // Exercise.
        GetBinContentOnMovementWorksheet(WhseWorksheetLine, LocationWhite3.Code, Item."No.");
        if Movement then
            CreateMovement(WhseWorksheetLine, Item."No.", ItemTrackingMode::" ", false);

        // Verify : UOM conversion on Movement Lines.
        if Movement then begin
            TempReservationEntry.FindFirst();
            VerifyMovementLine(
              WarehouseActivityLine."Action Type"::Take, Item."No.", Quantity, Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure",
              ItemUnitOfMeasure.Code, TempReservationEntry."Lot No.");
            VerifyMovementLine(
              WarehouseActivityLine."Action Type"::Place, Item."No.", Quantity, Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure",
              ItemUnitOfMeasure.Code, TempReservationEntry."Lot No.");
        end else
            VerifyWhseWorksheetLine(
              WhseWorksheetLine, Item."No.", Quantity, Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure", ItemUnitOfMeasure.Code);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure UOMConversionOnMovementUsingLotItemTrackingWithFEFO()
    var
        Bin: Record Bin;
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Quantity: Decimal;
        OldPickAccordingToFEFO: Boolean;
    begin
        // Setup : Update Pick According to FEFO on Location. Create Item and update Inventory with Strict Expiration Posting Item Tracking Code. Get Bin Content on Movement Worksheet.
        Initialize();
        UpdatePickAccordingToFEFOOnLocation(LocationWhite2, OldPickAccordingToFEFO, true);
        CreateItem(Item, ItemTrackingCode2.Code);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandInt(5) + 1);  // Value required for multiple UOM with different conversion rate.
        UpdateItemUOM(Item, ItemUnitOfMeasure.Code, ItemUnitOfMeasure.Code, '');
        FindBin(Bin, LocationWhite2.Code, false, true, true);  // Find PICK Bin.
        Quantity := LibraryRandom.RandDec(100, 2);
        UpdateInventoryUsingWarehouseJournal(Bin, Item, ItemUnitOfMeasure.Code, Quantity, true, ItemTrackingMode::"Assign Lot No.", WorkDate());
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Positive Adjmt.", Item."No.", ItemUnitOfMeasure.Code);
        GetBinContentOnMovementWorksheet(WhseWorksheetLine, LocationWhite2.Code, Item."No.");

        // Exercise : Create Movement.
        CreateMovement(WhseWorksheetLine, Item."No.", ItemTrackingMode::" ", false);

        // Verify : UOM conversion on Movement Lines.
        VerifyMovementLine(
          WarehouseActivityLine."Action Type"::Take, Item."No.", Quantity, Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure",
          ItemUnitOfMeasure.Code, ItemLedgerEntry."Lot No.");
        VerifyMovementLine(
          WarehouseActivityLine."Action Type"::Place, Item."No.", Quantity, Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure",
          ItemUnitOfMeasure.Code, ItemLedgerEntry."Lot No.");

        // Tear down.
        UpdatePickAccordingToFEFOOnLocation(LocationWhite2, OldPickAccordingToFEFO, OldPickAccordingToFEFO);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PutAwayUOMConversionOnBinContentAfterRegisterPutAwayWithItemTracking()
    begin
        // Setup.
        Initialize();
        PostWarehouseAdjustmentWithPutAwayUOMAfterRegisterPutAway(ItemTrackingCode2.Code, true, false);  // Use Item Tracking as True and Post Warehouse Adjustment as False.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,WhseItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PutAwayUOMConversionOnItemLedgerEntryAfterPostWarehouseAdjustmentWithItemTracking()
    begin
        // Setup.
        Initialize();
        PostWarehouseAdjustmentWithPutAwayUOMAfterRegisterPutAway(ItemTrackingCode2.Code, true, true);  // Use Item Tracking as True and Post Warehouse Adjustment as True.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PutAwayUOMConversionOnBinContentAfterRegisterPutAway()
    begin
        // Setup.
        Initialize();
        PostWarehouseAdjustmentWithPutAwayUOMAfterRegisterPutAway('', false, false);  // Use Item Tracking as False and Post Warehouse Adjustment as False.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PutAwayUOMConversionOnItemLedgerEntryAfterPostWarehouseAdjustment()
    begin
        // Setup.
        Initialize();
        PostWarehouseAdjustmentWithPutAwayUOMAfterRegisterPutAway('', false, true);  // Use Item Tracking as False and Post Warehouse Adjustment as True.
    end;

    local procedure PostWarehouseAdjustmentWithPutAwayUOMAfterRegisterPutAway(ItemTrackingCode: Code[10]; Tracking: Boolean; PostWarehouseAdjustment: Boolean)
    var
        Bin: Record Bin;
        Item: Record Item;
        ItemUnitOfMeasurePutAway: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TempReservationEntry: Record "Reservation Entry" temporary;
        Quantity: Decimal;
    begin
        // Create Item with Strict Expiration Posting Item Tracking Code. Create and Update Put Away UOM. Create and post Warehouse Receipt from Purchase Order.
        CreateItem(Item, ItemTrackingCode);
        CreateItemUnitOfMeasure(ItemUnitOfMeasurePutAway, Item."No.", 2);  // Value required for multiple UOM with different conversion rate.
        UpdateItemUOM(Item, '', '', ItemUnitOfMeasurePutAway.Code);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndReleasePurchaseOrderWithMultipleUOM(
          PurchaseHeader, Item."No.", Item."Base Unit of Measure", '', LocationWhite3.Code, Quantity, Tracking);  // Use TRUE for with Tracking.
        if Tracking then begin
            CopyReservationEntry(TempReservationEntry, Item."No.");
            TempReservationEntry.FindFirst();
        end;
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader);

        // Exercise : Register Put-Away.
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");
        FindRegisteredWhseActivityLine(
          RegisteredWhseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away", RegisteredWhseActivityLine."Action Type"::Place);
        Bin.Get(RegisteredWhseActivityLine."Location Code", RegisteredWhseActivityLine."Bin Code");
        if PostWarehouseAdjustment then
            UpdateInventoryUsingWarehouseJournal(
              Bin, Item, ItemUnitOfMeasurePutAway.Code, -Quantity / ItemUnitOfMeasurePutAway."Qty. per Unit of Measure", Tracking,
              ItemTrackingMode::"Select Lot No.", WorkDate());

        // Verify : Bin Content and Item Ledger Entry for Put Away UOM conversion.
        if PostWarehouseAdjustment then begin
            VerifyItemLedgerEntry(
              ItemLedgerEntry."Entry Type"::Purchase, Item."No.", Item."Base Unit of Measure", LocationWhite3.Code,
              TempReservationEntry."Lot No.", Quantity, 0);  // Use 0 for Remaining Quantity.
            VerifyItemLedgerEntry(
              ItemLedgerEntry."Entry Type"::"Negative Adjmt.", Item."No.", ItemUnitOfMeasurePutAway.Code, LocationWhite3.Code,
              TempReservationEntry."Lot No.", -Quantity, 0);  // Use 0 for Remaining Quantity.
        end else
            VerifyBinContent(Bin, Item."No.", Quantity / ItemUnitOfMeasurePutAway."Qty. per Unit of Measure", ItemUnitOfMeasurePutAway.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegisterPutAwayWithMoreThanMaximumQuantity()
    var
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemVariant: Record "Item Variant";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        // Setup : Create Bin Content with maximum Quantity. Create and release Purchase Order with Item Variant.
        Initialize();
        CreateItem(Item, '');
        CreateBinWithBinRanking(Bin, LocationWhite.Code, 0, true, false, false, false);  // Create RECEIVE Bin Value required for test.
        UpdateReceiptBinOnLocation(LocationWhite, Bin.Code);
        CreateBinContent(BinContent, Bin, Item."No.", Item."Base Unit of Measure", LibraryRandom.RandDec(100, 2));
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLineWithUOM(
          PurchaseLine, PurchaseHeader, Item."No.", Item."Base Unit of Measure", LocationWhite.Code,
          BinContent."Max. Qty." + LibraryRandom.RandDec(100, 2), false, ItemTrackingMode::"Assign Lot No.");  // Value required for test.
        UpdateItemVariantOnPurchaseLine(PurchaseLine, ItemVariant.Code);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader);

        // Exercise : Register Put Away.
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");

        // Verify.
        VerifyRegisteredWhseActivityLine(
          RegisteredWhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          RegisteredWhseActivityLine."Activity Type"::"Put-away",
          RegisteredWhseActivityLine."Action Type"::Take, PurchaseLine.Quantity, PurchaseLine.Quantity, Item."Base Unit of Measure");

        VerifyRegisteredWhseActivityLine(
          RegisteredWhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          RegisteredWhseActivityLine."Activity Type"::"Put-away",
          RegisteredWhseActivityLine."Action Type"::Place, PurchaseLine.Quantity, PurchaseLine.Quantity, Item."Base Unit of Measure");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegisterPutAwayWithBinRanking()
    var
        Bin: Record Bin;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseSourceFilter: Record "Warehouse Source Filter";
        Quantity: Decimal;
    begin
        // Setup : Create Bin with highest Bin Ranking. Create and post Warehouse Receipt from Purchase Order.
        Initialize();
        CreateItem(Item, '');
        CreateBinWithBinRanking(Bin, LocationWhite.Code, LibraryRandom.RandInt(100) + 200, false, false, true, true);  // Create PICK Bin Value required for test.
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndReleasePurchaseOrderWithMultipleUOM(
          PurchaseHeader, Item."No.", Item."Base Unit of Measure", '', LocationWhite.Code, Quantity, false);  // Use FALSE for without Tracking.
        CreateWarehouseReceiptHeaderWithLocation(WarehouseReceiptHeader, LocationWhite.Code);
        LibraryWarehouse.GetSourceDocumentsReceipt(WarehouseReceiptHeader, WarehouseSourceFilter, LocationWhite.Code);
        PostWarehouseReceipt(WarehouseReceiptHeader."No.");

        // Exercise : Register Put Away.
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");

        // Verify : Verify Bin with Bin Ranking.
        FindRegisteredWhseActivityLine(
          RegisteredWhseActivityLine, RegisteredWhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          RegisteredWhseActivityLine."Activity Type"::"Put-away", RegisteredWhseActivityLine."Action Type"::Place);
        RegisteredWhseActivityLine.TestField("Bin Code", Bin.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MovementWithBlockMovementAsAllOnBinContent()
    var
        BinContent: Record "Bin Content";
    begin
        // Setup.
        Initialize();
        MovementWithBlockMovementOnBinContent(BinContent."Block Movement"::All);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MovementWithBlockMovementAsOutboundlOnBinContent()
    var
        BinContent: Record "Bin Content";
    begin
        // Setup.
        Initialize();
        MovementWithBlockMovementOnBinContent(BinContent."Block Movement"::Outbound);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MovementWithBlockMovementAsInboundlOnBinContent()
    var
        BinContent: Record "Bin Content";
    begin
        // Setup.
        Initialize();
        MovementWithBlockMovementOnBinContent(BinContent."Block Movement"::Inbound);
    end;

    local procedure MovementWithBlockMovementOnBinContent(BlockMovement: Option)
    var
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Quantity: Decimal;
        BackupDefaultLocationCode: Code[20];
    begin
        // Create and post Warehouse Receipt from Purchase Order. Update Block Movement on Bin Content.
        CreateItem(Item, '');
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndReleasePurchaseOrderWithMultipleUOM(
          PurchaseHeader, Item."No.", Item."Base Unit of Measure", '', LocationWhite2.Code, Quantity, false);  // Use FALSE for without Tracking.
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");
        FindRegisteredWhseActivityLine(
          RegisteredWhseActivityLine, RegisteredWhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          RegisteredWhseActivityLine."Activity Type"::"Put-away", RegisteredWhseActivityLine."Action Type"::Place);
        Bin.Get(LocationWhite2.Code, RegisteredWhseActivityLine."Bin Code");
        UpdateBlockMovementOnBinContent(BinContent, Bin, Item."No.", BlockMovement);
        BackupDefaultLocationCode := UpdateDefaultLocationOnWarehouseEmployee(Bin."Location Code"); // Default Location required

        // Exercise : Create Movement from Movement Worksheet Line.
        if BinContent."Block Movement" = BinContent."Block Movement"::Inbound then begin
            CreateMovementWorksheetLine(Bin, Item."No.", Quantity);
            CreateMovement(WhseWorksheetLine, Item."No.", ItemTrackingMode::" ", false);
        end else
            asserterror CreateMovementWorksheetLine(Bin, Item."No.", Quantity);

        UpdateDefaultLocationOnWarehouseEmployee(BackupDefaultLocationCode); // Restore previous Default Location

        // Verify : Movement Line and error message.
        if BinContent."Block Movement" = BinContent."Block Movement"::Inbound then begin
            VerifyMovementLine(WarehouseActivityLine."Action Type"::Take, Item."No.", Quantity, Quantity, Item."Base Unit of Measure", '');
            VerifyMovementLine(WarehouseActivityLine."Action Type"::Place, Item."No.", Quantity, Quantity, Item."Base Unit of Measure", '');
        end else
            Assert.ExpectedError(
              StrSubstNo(
                BlockMovementError, BinContent."Block Movement", BinContent."Location Code", BinContent."Bin Code", BinContent."Item No.",
                BinContent."Unit of Measure Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CrossDockBinContentAfterRegisterPutAway()
    var
        Bin: Record Bin;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // Setup : Create and release Purchase Order. Create and post Warehouse Receipt. Update Cross Dock Bin on Put Away Line.
        Initialize();
        CreateItem(Item, '');
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndReleasePurchaseOrderWithMultipleUOM(
          PurchaseHeader, Item."No.", Item."Base Unit of Measure", '', LocationWhite.Code, Quantity, false);  // Use FALSE for without Tracking.
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader);
        Bin.Get(LocationWhite.Code, LocationWhite."Cross-Dock Bin Code");  // Find Cross Dock Bin.
        UpdateBinOnWarehouseActivityLine(
          Bin, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Place);

        // Exercise : Register Put away.
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");

        // Verify : Cross Dock Bin Content.
        VerifyBinContent(Bin, Item."No.", Quantity, Item."Base Unit of Measure");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UpdateDifferentExpirationDatesOnInventoryPutAwayErrorUsingLotAndSerialItemTracking()
    begin
        // Setup.
        Initialize();
        InventoryPickWithLotAndSerialItemTracking(true);  // Use True for error.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostInventoryPickUsingLotAndSerialItemTracking()
    begin
        // Setup.
        Initialize();
        InventoryPickWithLotAndSerialItemTracking(false);
    end;

    [HandlerFunctions('MessageHandler')]
    local procedure InventoryPickWithLotAndSerialItemTracking(ShowError: Boolean)
    var
        Bin: Record Bin;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Quantity: Decimal;
        ExpirationDate: Date;
    begin
        // Create Item with Serial and Lot Item Tracking. Create Inventory Put Away from Purchase Order.
        CreateItem(Item, ItemTrackingCode3.Code);  // Lot Serial Both.
        LibraryWarehouse.CreateBin(Bin, LocationSilver.Code, LibraryUtility.GenerateGUID(), '', '');
        Quantity := LibraryRandom.RandInt(100);  // Value required for test.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLineWithUOM(
          PurchaseLine, PurchaseHeader, Item."No.", Item."Base Unit of Measure", LocationSilver.Code, Quantity, true,
          ItemTrackingMode::"Assign Lot And Serial");
        UpdateBinOnPurchaseLine(PurchaseLine, Bin.Code);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        UpdateExpirationDateOnReservationEntry(Item."No.");
        LibraryVariableStorage.Enqueue(PutAwayCreated);  // Enqueue for MessageHandler.
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Purchase Order", PurchaseHeader."No.", true, false, false);
        ExpirationDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());

        // Exercise.
        if ShowError then
            asserterror UpdateExpirationDateOnInventoryPutAway(WarehouseActivityLine, PurchaseHeader."No.", ExpirationDate)
        else begin
            UpdateExpirationDateOnInventoryPutAway(WarehouseActivityLine, PurchaseHeader."No.", WorkDate());
            UpdateQuantityToHandleAndPostInventoryActivity(
              WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
              WarehouseActivityLine."Activity Type"::"Invt. Put-away", false);
            LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");  // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
            CreateAndReleaseSalesOrder(SalesHeader, SalesLine, Item."No.", Item."Base Unit of Measure", Bin."Location Code", Quantity, true);  // Use TRUE for with Tracking.
            LibraryVariableStorage.Enqueue(PickCreated);  // Enqueue for MessageHandler.
            LibraryWarehouse.CreateInvtPutPickMovement(
              WarehouseActivityHeader."Source Document"::"Sales Order", SalesHeader."No.", false, true, false);
            UpdateQuantityToHandleAndPostInventoryActivity(
              WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
              WarehouseActivityLine."Activity Type"::"Invt. Pick", false);
        end;

        // Verify : Error message and Posted Inventory Pick Line.
        if ShowError then
            Assert.ExpectedError(
              StrSubstNo(ExpirationDateError, ExpirationDate, WarehouseActivityLine."No.", WarehouseActivityLine."Line No."))
        else
            VerifyPostedInventoryPickLine(Bin, SalesHeader."No.", Item."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostInventoryPutAwayFromProductionOrder()
    var
        Bin: Record Bin;
        Bin2: Record Bin;
        ParentItem: Record Item;
        ComponentItem: Record Item;
        RoutingHeader: Record "Routing Header";
        ProductionBOMHeader: Record "Production BOM Header";
        ItemJournalLine: Record "Item Journal Line";
        ProductionOrder: Record "Production Order";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        WarehouseEntry: Record "Warehouse Entry";
        Quantity: Decimal;
    begin
        // Setup : Create and refresh Released Production Order.
        Initialize();
        CreateItem(ParentItem, '');
        CreateItem(ComponentItem, '');
        CreateAndCertifiyRouting(RoutingHeader);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ComponentItem."No.", ComponentItem."Base Unit of Measure", 1, BomLineType::Item);
        UpdateProductionBomAndRoutingOnItem(ParentItem, ProductionBOMHeader."No.", RoutingHeader."No.");
        LibraryWarehouse.CreateBin(Bin, LocationSilver.Code, LibraryUtility.GenerateGUID(), '', '');
        Quantity := LibraryRandom.RandInt(100);  // Value required for test.
        CreateAndPostItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", ComponentItem."No.", Quantity, Bin."Location Code", Bin.Code,
          false);
        LibraryWarehouse.CreateBin(Bin2, LocationSilver.Code, LibraryUtility.GenerateGUID(), '', '');
        CreateAndRefreshProductionOrder(ProductionOrder, ParentItem."No.", LocationSilver.Code, Bin2.Code, Quantity);

        // Exercise : Change Bin on Production Order Line.
        UpdateBinOnProdOrderLine(ParentItem."No.", Bin.Code);
        LibraryVariableStorage.Enqueue(InboundWarehouseCreated);  // Enqueue for MessageHandler.
        LibraryManufacturing.CreateInboundWhseReqFromProdOrder(ProductionOrder);
        LibraryVariableStorage.Enqueue(PutAwayCreated);  // Enqueue for MessageHandler.
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityLine."Source Document"::"Prod. Output", ProductionOrder."No.", true, false, false);
        UpdateQuantityToHandleAndPostInventoryActivity(
          WarehouseActivityLine."Source Document"::"Prod. Output", ProductionOrder."No.",
          WarehouseActivityLine."Activity Type"::"Invt. Put-away", false);

        // Verify.
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Output, ParentItem."No.", ParentItem."Base Unit of Measure", LocationSilver.Code, '', Quantity,
          Quantity);
        VerifyWarehouseEntry(
          WarehouseEntry."Entry Type"::"Positive Adjmt.", ParentItem."No.", ParentItem."Base Unit of Measure", LocationSilver.Code,
          Bin.Code, '', Quantity, Quantity);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler,CubageAndWeightExceedConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SplitLotNoUsingWarehouseReclassJournal()
    var
        Bin: Record Bin;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        WarehouseEntry: Record "Warehouse Entry";
        LotNo: Code[50];
        NewLotNo: Code[50];
        NewLotNo2: Code[50];
        Quantity: Decimal;
    begin
        // Setup.
        Initialize();
        CreateItem(Item, ItemTrackingCode.Code);
        FindBin(Bin, LocationWhite.Code, false, true, true);  // Find PICK Bin.
        Quantity := LibraryRandom.RandInt(100);
        UpdateInventoryUsingWarehouseJournal(
          Bin, Item, Item."Base Unit of Measure", Quantity, true, ItemTrackingMode::"Assign Lot No.", WorkDate());
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Positive Adjmt.", Item."No.", Item."Base Unit of Measure");
        LotNo := ItemLedgerEntry."Lot No.";

        // Exercise : Split Item Tracking Line on Warehouse Reclassification Journal.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Split Lot No.");  // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(LotNo);
        CreateAndRegisterWarehouseReclassJournal(Bin, Item."No.", Quantity, NewLotNo, NewLotNo2);

        // Verify : Warehouse Entry for Split Item Tracking Line.
        VerifyWarehouseEntry(
          WarehouseEntry."Entry Type"::Movement, Item."No.", Item."Base Unit of Measure", LocationWhite.Code, Bin.Code, NewLotNo,
          Quantity / 2, Quantity / 2);
        VerifyWarehouseEntry(
          WarehouseEntry."Entry Type"::Movement, Item."No.", Item."Base Unit of Measure", LocationWhite.Code, Bin.Code, NewLotNo2,
          Quantity / 2, Quantity / 2);

        // Verify : Item Ledger Entry for Split Item Tracking Line.
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Transfer, Item."No.", Item."Base Unit of Measure");
        VerifyItemLedgerEntries(ItemLedgerEntry, LocationWhite.Code, LotNo, -Quantity / 2); // Quantity of LotNo = -Quantity of NewLotNo = -Quantity / 2
        VerifyItemLedgerEntries(ItemLedgerEntry, LocationWhite.Code, NewLotNo, Quantity / 2);
        VerifyItemLedgerEntries(ItemLedgerEntry, LocationWhite.Code, LotNo, -Quantity / 2); // Quantity of LotNo = -Quantity of NewLotNo2 = -Quantity / 2
        VerifyItemLedgerEntries(ItemLedgerEntry, LocationWhite.Code, NewLotNo2, Quantity / 2);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReservationEntryAfterPostingSalesOrderAndItemJournal()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReservationEntry: Record "Reservation Entry";
    begin
        // [FEATURE] [Order Tracking]
        // [SCENARIO] Posting positive adjustment with greater quantity than sales order has for 'Tracking Only' item
        Initialize();

        // [GIVEN] Item with Order Tracking Policy - Tracking Only
        CreateItem(Item, ItemTrackingCode.Code);
        LibraryVariableStorage.Enqueue(ChangeAffectExistingEntries);  // Enqueue for MessageHandler.
        UpdateOrderTrackingPolicyAsTrackingOnlyOnItem(Item);

        // [GIVEN] Released sales order for the item with quantity = 6
        CreateAndReleaseSalesOrder(
          SalesHeader, SalesLine, Item."No.", Item."Base Unit of Measure", LocationYellow.Code, LibraryRandom.RandInt(100), false);  // Use FALSE for with Tracking.

        // [WHEN] Post positive adjustment for the item with quantity = 77 and Lot No. = "L1"
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");  // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
        CreateAndPostItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.",
          SalesLine.Quantity + LibraryRandom.RandInt(100), LocationYellow.Code, '', true);

        // [THEN] Reservation entry 'Tracking' exists with quantity = 6 for Lot No. "L1" with Untracked Surplus = No
        // [THEN] Reservation entry 'Surpus' exists with quantity = 71 for Lot No. "L1" with Untracked Surplus = No
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Positive Adjmt.", Item."No.", Item."Base Unit of Measure");
        VerifyReservationEntry(
          Item."No.", LocationYellow.Code, ItemLedgerEntry."Lot No.", ReservationEntry."Reservation Status"::Tracking,
          SalesLine.Quantity, false);
        VerifyReservationEntry(
          Item."No.", LocationYellow.Code, ItemLedgerEntry."Lot No.", ReservationEntry."Reservation Status"::Surplus,
          ItemJournalLine.Quantity - SalesLine.Quantity, false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReservationEntryAfterPostingSalesOrderAndItemJournalWithResidualSurplus()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReservationEntry: Record "Reservation Entry";
    begin
        // [FEATURE] [Order Tracking] [Untracked Surplus]
        // [SCENARIO 286154] Posting positive adjustment with less quantity than sales order has for 'Tracking Only' item
        Initialize();

        // [GIVEN] Item with Order Tracking Policy - Tracking Only
        CreateItem(Item, ItemTrackingCode.Code);
        LibraryVariableStorage.Enqueue(ChangeAffectExistingEntries);  // Enqueue for MessageHandler.
        UpdateOrderTrackingPolicyAsTrackingOnlyOnItem(Item);

        // [GIVEN] Released sales order for the item with quantity = 6
        CreateAndReleaseSalesOrder(
          SalesHeader, SalesLine, Item."No.", Item."Base Unit of Measure", LocationYellow.Code, LibraryRandom.RandIntInRange(10, 20), false);

        // [WHEN] Post positive adjustment for the item with quantity = 5
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");  // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
        CreateAndPostItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.",
          SalesLine.Quantity - 1, LocationYellow.Code, '', true);

        // [THEN] Reservation entry 'Tracking' exists with quantity = 5 for Lot No. "L1" with Untracked Surplus = No
        // [THEN] Reservation entry 'Tracking' exists with quantity = -5 without Lot No. with Untracked Surplus = Yes
        // [THEN] Reservation entry 'Surpus' exists with quantity = -1 without Lot No. with Untracked Surplus = Yes
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Positive Adjmt.", Item."No.", Item."Base Unit of Measure");
        VerifyReservationEntry(
          Item."No.", LocationYellow.Code, ItemLedgerEntry."Lot No.", ReservationEntry."Reservation Status"::Tracking,
          ItemJournalLine.Quantity, false);
        VerifyReservationEntry(
          Item."No.", LocationYellow.Code, '', ReservationEntry."Reservation Status"::Tracking,
          -ItemJournalLine.Quantity, true);
        VerifyReservationEntry(
          Item."No.", LocationYellow.Code, '', ReservationEntry."Reservation Status"::Surplus,
          ItemJournalLine.Quantity - SalesLine.Quantity, true);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReservationEntryAfterPostingWarehouseReceiptAndShipmentFromTransferOrder()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReservationEntry: Record "Reservation Entry";
        TransferHeader: Record "Transfer Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Setup : Create and release Sales Order. Create and post Item Journal Line. Create and release Transfer Order.
        Initialize();
        CreateItem(Item, ItemTrackingCode.Code);
        LibraryVariableStorage.Enqueue(ChangeAffectExistingEntries);  // Enqueue for MessageHandler.
        UpdateOrderTrackingPolicyAsTrackingOnlyOnItem(Item);
        CreateAndReleaseSalesOrder(
          SalesHeader, SalesLine, Item."No.", Item."Base Unit of Measure", LocationYellow.Code, LibraryRandom.RandInt(100), false);  // Use FALSE for with Tracking.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");  // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
        CreateAndPostItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.",
          SalesLine.Quantity + LibraryRandom.RandInt(100), LocationYellow.Code, '', true);
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Positive Adjmt.", Item."No.", Item."Base Unit of Measure");
        CreateAndReleaseTransferOrder(
          TransferHeader, LocationYellow.Code, LocationGreen.Code, Item."No.", ItemJournalLine.Quantity, Item."Base Unit of Measure");

        // Exercise : Create and post Warehouse Shipment and Receipt from Transfer Order.
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentLine."Source Document"::"Outbound Transfer", TransferHeader."No.");
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Outbound Transfer", TransferHeader."No.",
          WarehouseActivityLine."Activity Type"::Pick);
        UpdateLotNoOnWarehouseActivityLine(WarehouseActivityLine, ItemLedgerEntry."Lot No.");
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Outbound Transfer",
          TransferHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);  // Use FALSE for only Shipment.
        CreateAndPostWarehouseReceiptFromTransferOrder(TransferHeader);

        // Verify.
        VerifyReservationEntry(
          Item."No.", LocationGreen.Code, ItemLedgerEntry."Lot No.", ReservationEntry."Reservation Status"::Surplus,
          ItemJournalLine.Quantity, false);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure BinReplenishmentWithPutPickBinType()
    begin
        // Setup.
        Initialize();
        MovementAndPickAfterBinReplenishmentWithDifferentBinType(false, true, true, false, false, false);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure MovementAfterBinReplenishmentWithPutPickBinTypeUsingLotItemTracking()
    begin
        // Setup.
        Initialize();
        MovementAndPickAfterBinReplenishmentWithDifferentBinType(false, true, true, true, false, false);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure RegisterMovementAfterBinReplenishmentWithPutPickBinTypeUsingLotItemTracking()
    begin
        // Setup.
        Initialize();
        MovementAndPickAfterBinReplenishmentWithDifferentBinType(false, true, true, true, true, false);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure BinReplenishmentWithShipBinType()
    begin
        // Setup.
        Initialize();
        MovementAndPickAfterBinReplenishmentWithDifferentBinType(true, false, false, false, false, false);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure MovementAfterBinReplenishmentWithShipBinTypeUsingLotItemTracking()
    begin
        // Setup.
        Initialize();
        MovementAndPickAfterBinReplenishmentWithDifferentBinType(true, false, false, true, false, false);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure RegisterMovementAfterBinReplenishmentWithShipBinTypeUsingLotItemTracking()
    begin
        // Setup.
        Initialize();
        MovementAndPickAfterBinReplenishmentWithDifferentBinType(true, false, false, true, true, false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,WhseItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PickAfterBinReplenishmentWithShipBinTypeUsingLotItemTracking()
    begin
        // Setup.
        Initialize();
        MovementAndPickAfterBinReplenishmentWithDifferentBinType(true, false, false, true, true, true);
    end;

    local procedure MovementAndPickAfterBinReplenishmentWithDifferentBinType(Ship: Boolean; PutAway: Boolean; Pick: Boolean; Movement: Boolean; RegisterMovement: Boolean; CreateWarehousePick: Boolean)
    var
        Bin: Record Bin;
        Bin2: Record Bin;
        Bin3: Record Bin;
        BinContent: Record "Bin Content";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        LotNo: Code[50];
        LotNo2: Code[50];
        Quantity: Decimal;
    begin
        // Create Item with Lot Item Tracking. Update Inventory on different Zone and Bin.
        CreateItem(Item, ItemTrackingCode.Code);
        CreateBinWithBinRanking(Bin, LocationWhite.Code, LibraryRandom.RandInt(100), false, false, true, false);  // Create BULK Bin Value required for test.
        CreateBinWithBinRanking(Bin2, LocationWhite.Code, Bin."Bin Ranking" + LibraryRandom.RandInt(100), false, Ship, PutAway, Pick);  // Create PICK / SHIP Bin Value required for test.
        Quantity := LibraryRandom.RandInt(100);
        CreateBinContent(BinContent, Bin2, Item."No.", Item."Base Unit of Measure", Quantity + LibraryRandom.RandInt(100));
        UpdateInventoryUsingWarehouseJournal(
          Bin2, Item, Item."Base Unit of Measure", Quantity, true, ItemTrackingMode::"Assign Lot No.", WorkDate());
        UpdateInventoryUsingWarehouseJournal(
          Bin, Item, Item."Base Unit of Measure", Quantity, true, ItemTrackingMode::"Assign Lot No.", WorkDate());

        // Exercise.
        CalculateBinReplenishmentOnMovementWorksheet(Item."No.", LocationWhite.Code);

        // Verify.
        VerifyWhseWorksheetLine(WhseWorksheetLine, Item."No.", Quantity, Quantity, Item."Base Unit of Measure");

        if Movement then begin
            // Exercise.
            CreateMovement(WhseWorksheetLine, Item."No.", ItemTrackingMode::"Select Lot No.", true);

            // Verify.
            DequeueLotNo(LotNo);
            VerifyMovementLine(WarehouseActivityLine."Action Type"::Take, Item."No.", Quantity, Quantity, Item."Base Unit of Measure", LotNo);
            VerifyMovementLine(WarehouseActivityLine."Action Type"::Place, Item."No.", Quantity, Quantity, Item."Base Unit of Measure", LotNo);
        end;

        if RegisterMovement then begin
            // Exercise.
            RegisterWarehouseMovement(Item."No.", '');

            // Verify.
            VerifyRegisteredMovementLine(Bin, RegisteredWhseActivityLine."Action Type"::Take, Item."No.", Quantity, LotNo);
            VerifyRegisteredMovementLine(Bin2, RegisteredWhseActivityLine."Action Type"::Place, Item."No.", Quantity, LotNo);
        end;

        if CreateWarehousePick then begin
            // Exercise.
            FindBin(Bin3, LocationWhite.Code, false, true, true);  // Find PICK Bin.
            CreateWhseWorksheetLine(WhseWorksheetLine, Bin2, Bin3, Item."No.", Quantity * 2);  // Value required for test.
            CreateMovement(WhseWorksheetLine, Item."No.", ItemTrackingMode::"Select Multiple Lot No.", true);
            RegisterWarehouseMovement(Item."No.", WhseWorksheetLine."Worksheet Template Name");
            DequeueLotNo(LotNo);
            DequeueLotNo(LotNo2);
            LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");  // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
            CreateAndReleaseSalesOrder(SalesHeader, SalesLine, Item."No.", Item."Base Unit of Measure", Bin."Location Code", Quantity * 2, true);  // Value required for test.
            CreatePickFromWarehouseShipment(SalesHeader);

            // Verify.
            VerifyPickLine(
              WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take,
              WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", Item."No.", Item."Base Unit of Measure", LotNo,
              Quantity);
            VerifyPickLine(
              WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Place,
              WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", Item."No.", Item."Base Unit of Measure", LotNo,
              Quantity);
            VerifyPickLine(
              WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take,
              WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", Item."No.", Item."Base Unit of Measure", LotNo2,
              Quantity);
            VerifyPickLine(
              WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Place,
              WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", Item."No.", Item."Base Unit of Measure", LotNo2,
              Quantity);
        end;
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure PickFromWarehouseShipmentWithReservation()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
        Quantity2: Decimal;
    begin
        // Setup.
        Initialize();
        CreateItem(Item, '');
        Quantity := LibraryRandom.RandInt(100);
        Quantity2 := Quantity + LibraryRandom.RandInt(100);  // Value required for test.
        CreateAndReleasePurchaseOrderWithMultipleUOM(
          PurchaseHeader, Item."No.", Item."Base Unit of Measure", '', LocationWhite3.Code, Quantity2, false);
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");
        CreatePickFromWarehouseShipmentWithReservation(SalesHeader, Item, LocationWhite3.Code, Quantity);
        UpdateQuantityToHandleOnWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order",
          SalesHeader."No.", Quantity / 2);  // Value required for test.
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
        DeleteWarehouseActivity(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");

        // Exercise.
        CreatePickFromWarehouseShipmentWithReservation(
          SalesHeader, Item, LocationWhite3.Code, Quantity2 - Quantity + LibraryRandom.RandInt(100));  // Value required for test.

        // Verify.
        VerifyPickLine(
          WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take,
          WarehouseActivityLine."Source Document"::"Sales Order",
          SalesHeader."No.", Item."No.", Item."Base Unit of Measure", '', Quantity2 - Quantity);  // Value required for test.
        VerifyPickLine(
          WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Place,
          WarehouseActivityLine."Source Document"::"Sales Order",
          SalesHeader."No.", Item."No.", Item."Base Unit of Measure", '', Quantity2 - Quantity);  // Value required for test.
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPickWithReservation()
    var
        Bin: Record Bin;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
        Quantity2: Decimal;
    begin
        // Setup.
        Initialize();
        CreateItem(Item, '');
        Quantity := LibraryRandom.RandInt(100);
        Quantity2 := Quantity + LibraryRandom.RandInt(100);  // Value required for test.
        LibraryWarehouse.CreateBin(Bin, LocationSilver.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLineWithUOM(
          PurchaseLine, PurchaseHeader, Item."No.", Item."Base Unit of Measure", LocationSilver.Code, Quantity2, false, ItemTrackingMode::" ");
        UpdateBinOnPurchaseLine(PurchaseLine, Bin.Code);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryVariableStorage.Enqueue(PutAwayCreated);  // Enqueue for MessageHandler.
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Purchase Order", PurchaseHeader."No.", true, false, false);
        UpdateQuantityToHandleAndPostInventoryActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Invt. Put-away", false);
        CreateInventoryPickWithReservation(SalesHeader, Item, LocationSilver.Code, Quantity);
        UpdateQuantityToHandleAndPostInventoryActivity(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Pick",
          true);  // Value required for test.
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::"Invt. Pick");
        DeleteWarehouseActivity(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");

        // Exercise.
        CreateInventoryPickWithReservation(
          SalesHeader, Item, LocationSilver.Code, Quantity2 - Quantity + LibraryRandom.RandInt(100));  // Value required for test.

        // Verify.
        VerifyPickLine(
          WarehouseActivityLine."Activity Type"::"Invt. Pick", WarehouseActivityLine."Action Type"::Take,
          WarehouseActivityLine."Source Document"::"Sales Order",
          SalesHeader."No.", Item."No.", Item."Base Unit of Measure", '', Quantity2 - Quantity);  // Value required for test.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure PickFromWarehouseShipmentWithReservationUsingLotItemTracking()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // Setup.
        Initialize();
        CreateItem(Item, ItemTrackingCode.Code);
        Quantity := LibraryRandom.RandInt(100);
        CreateAndReleasePurchaseOrderWithMultipleUOM(
          PurchaseHeader, Item."No.", Item."Base Unit of Measure", Item."Base Unit of Measure", LocationWhite3.Code, Quantity, true);
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");
        CreateAndReleaseSalesOrderWithReservation(SalesHeader, Item, LocationWhite3.Code, Quantity);

        // Exercise.
        CreatePickFromWarehouseShipmentWithReservation(SalesHeader, Item, LocationWhite3.Code, Quantity);

        // Verify.
        VerifyPickLine(
          WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take,
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", Item."No.", Item."Base Unit of Measure", '', Quantity);
        VerifyPickLine(
          WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Place,
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", Item."No.", Item."Base Unit of Measure", '', Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PutAwayUOMConversionOnPickLine()
    var
        Item: Record Item;
        ItemUnitOfMeasurePutAway: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        Quantity: Decimal;
    begin
        // Setup : Create Item with Lot Item Tracking Code. Create and Update Put Away UOM. Create and post Warehouse Receipt from Purchase Order.
        Initialize();
        CreateItem(Item, ItemTrackingCode.Code);
        CreateItemUnitOfMeasure(ItemUnitOfMeasurePutAway, Item."No.", LibraryRandom.RandInt(5) + 1);  // Value required for multiple UOM with different conversion rate.
        UpdateItemUOM(Item, '', '', ItemUnitOfMeasurePutAway.Code);
        Quantity := LibraryRandom.RandInt(100);  // Value required for test.
        CreateAndReleasePurchaseOrderWithMultipleUOM(
          PurchaseHeader, Item."No.", Item."Base Unit of Measure", '', LocationWhite3.Code, Quantity, true);  // Use TRUE for with Tracking.
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");

        // Exercise : Create and post Warehouse Shipment From Sales Order.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");  // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
        CreateAndPostWarehouseShipmentFromSalesOrder(SalesLine, Item."No.", Item."Base Unit of Measure", LocationWhite3.Code, Quantity, true);  // Use True for with Item Tracking.

        // Verify : Verify Put Away UOM Conversion on Registered Warehouse Lines.
        VerifyRegisteredWhseActivityLine(
          RegisteredWhseActivityLine."Source Document"::"Sales Order", SalesLine."Document No.",
          RegisteredWhseActivityLine."Activity Type"::Pick,
          RegisteredWhseActivityLine."Action Type"::Take, Quantity / ItemUnitOfMeasurePutAway."Qty. per Unit of Measure", Quantity,
          ItemUnitOfMeasurePutAway.Code);  // Value required for test.
        VerifyRegisteredWhseActivityLine(
          RegisteredWhseActivityLine."Source Document"::"Sales Order", SalesLine."Document No.",
          RegisteredWhseActivityLine."Activity Type"::Pick, RegisteredWhseActivityLine."Action Type"::Place, Quantity, Quantity,
          Item."Base Unit of Measure");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PickFromWarehouseShipmentAfterPostingOutputFromProductionOrderUsingSerialItemTracking()
    begin
        // Setup.
        Initialize();
        RegisterPickAndPostWarehouseShipmentAfterPostingOutputFromProductionOrderUsingSerialItemTracking(false, false);  // Use Register Pick as FALSE and Post Warehouse Shipment as FALSE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure RegisterPickFromWarehouseShipmentAfterPostingOutputFromProductionOrderUsingSerialItemTracking()
    begin
        // Setup.
        Initialize();
        RegisterPickAndPostWarehouseShipmentAfterPostingOutputFromProductionOrderUsingSerialItemTracking(true, false);  // Use Register Pick as TRUE and Post Warehouse Shipment as FALSE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostWarehouseShipmentAfterPostingOutputFromProductionOrderUsingSerialItemTracking()
    begin
        // Setup.
        Initialize();
        RegisterPickAndPostWarehouseShipmentAfterPostingOutputFromProductionOrderUsingSerialItemTracking(true, true);  // Use Register Pick as TRUE and Post Warehouse Shipment as TRUE.
    end;

    local procedure RegisterPickAndPostWarehouseShipmentAfterPostingOutputFromProductionOrderUsingSerialItemTracking(RegisterPick: Boolean; PostWarehouseShipment: Boolean)
    var
        Bin: Record Bin;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Quantity: Decimal;
        Quantity2: Decimal;
        OldAlwaysCreatePickLine: Boolean;
    begin
        // Create Item with Serial Item Tracking. Create Warehouse Shipment from Sales Order. Create Production Order from Sales Order. Create and Post Output for Production Order.
        CreateItem(Item, ItemTrackingCode4.Code);
        UpdateAlwaysCreatePickLineOnLocation(LocationWhite3, OldAlwaysCreatePickLine, true);
        Quantity := LibraryRandom.RandInt(5);
        Quantity2 := Quantity + LibraryRandom.RandInt(5);  // Value required for test.
        CreateAndReleaseSalesOrder(
          SalesHeader, SalesLine, Item."No.", Item."Base Unit of Measure", LocationWhite3.Code, Quantity + Quantity2, false);  // Value required for test.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        LibraryVariableStorage.Enqueue(ProductionOrderCreated);  // Enqueue for MessageHandler.
        LibraryManufacturing.CreateProductionOrderFromSalesOrder(
            SalesHeader, ProductionOrder.Status::Released, "Create Production Order Type"::ItemOrder);
        FindProductionOrderLine(ProdOrderLine, Item."No.");
        CreateAndPostOutputJournalLineWithItemTracking(ItemJournalLine, ProdOrderLine, Quantity);
        CreateAndPostOutputJournalLineWithItemTracking(ItemJournalLine, ProdOrderLine, Quantity2);

        // Exercise.
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");

        // Verify.
        VerifyPickLines(WarehouseActivityLine."Action Type"::Take, SalesHeader."No.", Item."No.");
        VerifyPickLines(WarehouseActivityLine."Action Type"::Place, SalesHeader."No.", Item."No.");

        if RegisterPick then begin
            // Exercise.
            Bin.Get(LocationWhite3.Code, LocationWhite3."To-Production Bin Code");
            UpdateBinOnWarehouseActivityLine(
              Bin, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick,
              WarehouseActivityLine."Action Type"::Take);
            RegisterWarehouseActivity(
              WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);

            // Verify.
            VerifyRegisteredPickLines(WarehouseActivityLine."Action Type"::Take, SalesHeader."No.", Item."No.");
            VerifyRegisteredPickLines(WarehouseActivityLine."Action Type"::Place, SalesHeader."No.", Item."No.");
        end;

        if PostWarehouseShipment then begin
            // Exercise.
            LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);  // Use FALSE for only Shipment.

            // Verify.
            VerifyPostedWarehouseShipmentLine(SalesHeader."No.", Item."No.", Quantity + Quantity2);  // Value required for test.
        end;

        // Tear down.
        UpdateAlwaysCreatePickLineOnLocation(LocationWhite3, OldAlwaysCreatePickLine, OldAlwaysCreatePickLine);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,WhseItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,ReservationPageHandler,CubageAndWeightExceedConfirmHandler,ItemTrackingListPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPickFromProductionOrderAfterReserveProductionComponent()
    var
        Bin: Record Bin;
        Bin2: Record Bin;
        ComponentItem: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ParentItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ReservationEntry: Record "Reservation Entry";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // Setup : Create Parent Item and Component Item with Lot Item Tracking. Update Inventory of Component Item on different Location. Create and refresh Production Order. Reserve Production Order Component.
        Initialize();
        CreateItem(ParentItem, '');
        CreateItem(ComponentItem, ItemTrackingCode.Code);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ComponentItem."No.", ComponentItem."Base Unit of Measure", 1, BomLineType::Item);
        UpdateProductionBomAndRoutingOnItem(ParentItem, ProductionBOMHeader."No.", '');
        LibraryWarehouse.CreateBin(Bin, LocationSilver.Code, LibraryUtility.GenerateGUID(), '', '');
        Quantity := LibraryRandom.RandInt(100);  // Value required for test.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");  // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
        CreateAndPostItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", ComponentItem."No.", Quantity, Bin."Location Code", Bin.Code,
          true);
        Bin2.Get(LocationWhite3.Code, LocationWhite3."To-Production Bin Code");
        UpdateInventoryUsingWarehouseJournal(
          Bin2, ComponentItem, ComponentItem."Base Unit of Measure", Quantity, true, ItemTrackingMode::"Assign Lot No.", WorkDate());
        CreateAndRefreshProductionOrder(ProductionOrder, ParentItem."No.", LocationSilver.Code, Bin.Code, Quantity);
        ReserveProductionOrderComponent(ComponentItem."No.");

        // Exercise.
        LibraryVariableStorage.Enqueue(PickCreated);  // Enqueue for MessageHandler.
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, true, false);

        // Verify.
        FindItemLedgerEntry(
          ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Positive Adjmt.", ComponentItem."No.", ComponentItem."Base Unit of Measure");
        VerifyPickLine(
          WarehouseActivityLine."Activity Type"::"Invt. Pick", WarehouseActivityLine."Action Type"::Take,
          WarehouseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.", ComponentItem."No.",
          ComponentItem."Base Unit of Measure", ItemLedgerEntry."Lot No.", Quantity);
        VerifyReservationEntry(
          ComponentItem."No.", LocationSilver.Code, ItemLedgerEntry."Lot No.", ReservationEntry."Reservation Status"::Reservation,
          -Quantity, false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PostWarehouseShipmentWithDifferentPickCreatedByWarehouseShipmentAndPickWorksheetUsingLotItemTracking()
    begin
        // Setup.
        Initialize();
        WarehouseShipmentWithDifferentPicksUsingLotItemTracking(true);  // Use Pick Worksheet as TRUE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationEntryAfterPostingPartialWarehouseShipmentWithPartialPickUsingLotItemTracking()
    begin
        // Setup.
        Initialize();
        WarehouseShipmentWithDifferentPicksUsingLotItemTracking(false);  // Use Pick Worksheet as FALSE.
    end;

    local procedure WarehouseShipmentWithDifferentPicksUsingLotItemTracking(WithPickWorksheet: Boolean)
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        ReservationEntry: Record "Reservation Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Quantity: Decimal;
        Quantity2: Decimal;
    begin
        // Create Item with Lot Item Tracking. Create and post Warehouse Receipt from Purchase Order. Create Pick from Warehouse Shipment. Register partial Pick.
        // Purchase Order Qty = 83; Sales Order Qty = 83; Warehouse Shipment has Qty. To Handle = 6.
        CreateItem(Item, ItemTrackingCode.Code);
        Quantity := LibraryRandom.RandInt(100);
        Quantity2 := Quantity + LibraryRandom.RandInt(100);  // Value required for test.
        CreateAndReleasePurchaseOrderWithMultipleUOM(
          PurchaseHeader, Item."No.", Item."Base Unit of Measure", '', LocationWhite3.Code, Quantity + Quantity2, true);  // Value required for test.
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");  // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
        CreateAndReleaseSalesOrder(
          SalesHeader, SalesLine, Item."No.", Item."Base Unit of Measure", LocationWhite3.Code, Quantity + Quantity2, true);  // Value required for test.
        CreatePickFromWarehouseShipment(SalesHeader);
        UpdateQuantityToHandleOnWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", Quantity);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);

        if WithPickWorksheet then begin
            // Exercise : Delete remaining Pick. Create and register Pick for remaining Quantity from Pick Worksheet. Post Warehouse Shipment.
            DeleteWarehouseActivity(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
            GetWarehouseDocumentOnPickWorksheet(Item."No.", LocationWhite3.Code, false);
            RegisterWarehouseActivity(
              WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
            FindWarehouseShipmentLine(WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
            PostWarehouseShipment(WarehouseShipmentLine."No.");

            // Verify.
            VerifyPostedWarehouseShipmentLine(SalesHeader."No.", Item."No.", Quantity + Quantity2);  // Value required for test.
        end else begin
            // Exercise : Update Quantity To Ship on Warehouse Shipment Line and post Warehouse Shipment.
            // Update Warehouse Shipment with Qty. To Ship = 3
            FindWarehouseShipmentLine(WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
            UpdateQuantityToShipOnWarehouseShipmentLine(WarehouseShipmentLine, Quantity / 2);  // Value required for test.
            PostWarehouseShipment(WarehouseShipmentLine."No.");

            // Verify.
            // Item Ledger Entries with Qty 83, -3.
            // Reservation Entries: 'Reservation' with Qty -3 (= 6 / 2), 'Surplus' with Quantity -77 (83 - 3 posted - 3 reserved for whse.shipment)
            FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, Item."No.", Item."Base Unit of Measure");
            VerifyReservationEntry(
              Item."No.", LocationWhite3.Code, ItemLedgerEntry."Lot No.", ReservationEntry."Reservation Status"::Surplus,
              -Quantity2, false);  // Value required for test.
            VerifyReservationEntry(
              Item."No.", LocationWhite3.Code, ItemLedgerEntry."Lot No.", ReservationEntry."Reservation Status"::Reservation,
              -Quantity / 2, false);  // Value required for test.
        end;
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,ReservationPageHandler,ItemTrackingListPageHandler,MenuHandler,CubageAndWeightExceedConfirmHandler')]
    [Scope('OnPrem')]
    procedure PickFromWarehouseShipmentAfterPostingTransferOrderUsingLotItemTracking()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        TransferHeader: Record "Transfer Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Quantity: Decimal;
        Quantity2: Decimal;
    begin
        // Setup : Create Item with Lot Item Tracking. Create and post Purchase Order on Location Blue. Create and release Sales Order on Location White. Create Warehouse Shipment.
        // Create and post Transfer Order from Location Blue to Location White. Create and post Warehouse Receipt on Location Blue.
        Initialize();
        CreateItem(Item, ItemTrackingCode.Code);
        Quantity := LibraryRandom.RandInt(10);
        Quantity2 := Quantity + LibraryRandom.RandInt(10);  // Value required for test.
        CreateAndReleasePurchaseOrderWithMultipleUOM(
          PurchaseHeader, Item."No.", Item."Base Unit of Measure", '', LocationBlue.Code, Quantity, true);  // Use True for Item Tracking.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Post as Receive.
        CreateAndReleaseSalesOrderWithShipmentDate(SalesHeader, Item, LocationWhite3.Code, Quantity + Quantity2);  // Value required for test.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        CreateAndReleaseTransferOrder(
          TransferHeader, LocationBlue.Code, LocationWhite3.Code, Item."No.", Quantity, Item."Base Unit of Measure");
        ReserveQuantityAndPostTransferOrder(TransferHeader);
        CreateAndReleasePurchaseOrderWithMultipleUOM(
          PurchaseHeader2, Item."No.", Item."Base Unit of Measure", '', LocationWhite3.Code, Quantity2, true);  // Use True for Item Tracking.
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader2);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader2."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");

        // Exercise.
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");

        // Verify : Pick is created only for available Quantity.
        VerifyPickLine(
          WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take,
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", Item."No.", Item."Base Unit of Measure", '', Quantity2);
        VerifyPickLine(
          WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Place,
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", Item."No.", Item."Base Unit of Measure", '', Quantity2);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PickFromWarehouseShipmentOnlyForNonExpiredQuantity()
    var
        Bin: Record Bin;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
        Quantity2: Decimal;
        OldPickAccordingToFEFO: Boolean;
    begin
        // Setup : Update Pick According to FEFO on Location. Create Item and update Inventory with Strict Expiration Posting Item Tracking Code. Create and release Sales Order.
        Initialize();
        UpdatePickAccordingToFEFOOnLocation(LocationWhite3, OldPickAccordingToFEFO, true);
        CreateItem(Item, ItemTrackingCode2.Code);
        FindBin(Bin, LocationWhite3.Code, false, true, true);  // Find PICK Bin.
        Quantity := LibraryRandom.RandInt(10);
        Quantity2 := Quantity + LibraryRandom.RandInt(10);  // Value required for test.
        UpdateInventoryUsingWarehouseJournal(
          Bin, Item, Item."Base Unit of Measure", Quantity, true, ItemTrackingMode::"Assign Lot No.",
          CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate()));  // Value required for test.
        UpdateInventoryUsingWarehouseJournal(
          Bin, Item, Item."Base Unit of Measure", Quantity2, true, ItemTrackingMode::"Assign Lot No.",
          CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate()));  // Value required for test.
        CreateAndReleaseSalesOrder(
          SalesHeader, SalesLine, Item."No.", Item."Base Unit of Measure", Bin."Location Code", Quantity + Quantity2, false);  // Value required for test.

        // Exercise.
        CreatePickFromWarehouseShipment(SalesHeader);

        // Verify : Pick is created only for Non Expired Quantity.
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Positive Adjmt.", Item."No.", Item."Base Unit of Measure");
        VerifyPickLine(
          WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take,
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", Item."No.", Item."Base Unit of Measure",
          ItemLedgerEntry."Lot No.", Quantity);
        VerifyPickLine(
          WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Place,
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", Item."No.", Item."Base Unit of Measure",
          ItemLedgerEntry."Lot No.", Quantity);

        // Tear down.
        UpdatePickAccordingToFEFOOnLocation(LocationWhite3, OldPickAccordingToFEFO, OldPickAccordingToFEFO);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PickFromCombineWarehouseShipmentForSalesOrderWithDifferentUOM()
    var
        Bin: Record Bin;
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        Quantity: Decimal;
        Quantity2: Decimal;
    begin
        // Setup : Create Item with multiple UOM. Create a combine Warehouse Shipment for two Sales Order with different UOM.
        Initialize();
        CreateItem(Item, '');
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", 2);  // Value required for multiple UOM with different conversion rate.
        FindBin(Bin, LocationWhite3.Code, false, true, true);  // Find PICK Bin.
        Quantity := LibraryRandom.RandInt(10);
        Quantity2 := Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure";  // Value required for test.
        UpdateInventoryUsingWarehouseJournal(Bin, Item, Item."Base Unit of Measure", Quantity2, false, ItemTrackingMode::" ", WorkDate());  // Value required for test.
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, Item."No.", Item."Base Unit of Measure", Bin."Location Code", Quantity, false);
        CreateAndReleaseSalesOrder(SalesHeader2, SalesLine, Item."No.", ItemUnitOfMeasure.Code, Bin."Location Code", Quantity, false);
        CreateWarehouseShipmentWithGetSourceDocument(WarehouseShipmentHeader, Item."No.", Bin."Location Code");

        // Exercise.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // Verify.
        VerifyPickLine(
          WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take,
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", Item."No.", Item."Base Unit of Measure", '', Quantity);
        VerifyPickLine(
          WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Place,
          WarehouseActivityLine."Source Document"::"Sales Order",
          SalesHeader2."No.", Item."No.", ItemUnitOfMeasure.Code, '', (Quantity2 - Quantity) / ItemUnitOfMeasure."Qty. per Unit of Measure");  // Value required for test.
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PickFromWarehouseShipmentWithQuantityAvailableOnDifferentBinUsingLotItemTracking()
    var
        Bin: Record Bin;
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // Setup : Create Item with Lot Item Tracking. Update Inventory on different Bin. Create and release Sales Order. Create Pick from Warehouse Shipment.
        Initialize();
        CreateItem(Item, ItemTrackingCode.Code);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandInt(10) + 1);  // Value required for multiple UOM with different conversion rate.
        Quantity := ItemUnitOfMeasure."Qty. per Unit of Measure" * ItemUnitOfMeasure."Qty. per Unit of Measure";  // Value required for test.
        FindBin(Bin, LocationWhite3.Code, false, true, true);  // Find PICK Bin.
        UpdateInventoryUsingWarehouseJournal(
          Bin, Item, Item."Base Unit of Measure", Quantity / 2, true, ItemTrackingMode::"Assign Lot No.", WorkDate());  // Value required for test.
        Bin.Next();  // Find Next PICK Bin.
        UpdateInventoryUsingWarehouseJournal(
          Bin, Item, Item."Base Unit of Measure", Quantity / 2, true, ItemTrackingMode::"Assign Lot No.", WorkDate());  // Value required for test.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");  // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
        CreateAndReleaseSalesOrder(
          SalesHeader, SalesLine, Item."No.", ItemUnitOfMeasure.Code, Bin."Location Code", ItemUnitOfMeasure."Qty. per Unit of Measure", true);
        CreatePickFromWarehouseShipment(SalesHeader);

        // Exercise.
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);

        // Verify.
        VerifyRegisteredWhseActivityLine(
          RegisteredWhseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", RegisteredWhseActivityLine."Activity Type"::Pick,
          RegisteredWhseActivityLine."Action Type"::Take, Quantity / 2, Quantity / 2, Item."Base Unit of Measure");  // Value required for test.
        VerifyRegisteredWhseActivityLine(
          RegisteredWhseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", RegisteredWhseActivityLine."Activity Type"::Pick,
          RegisteredWhseActivityLine."Action Type"::Place, SalesLine.Quantity / 2, SalesLine."Quantity (Base)" / 2, ItemUnitOfMeasure.Code);  // Value required for test.
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PickFromWarehouseShipmentWithExpirationCalculationOnItem()
    var
        Bin: Record Bin;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
        OldPickAccordingToFEFO: Boolean;
    begin
        // Setup : Update Pick According to FEFO on Location. Create Item. Update Expiration Calculation on Item. Create and release Sales Order.
        Initialize();
        UpdatePickAccordingToFEFOOnLocation(LocationWhite3, OldPickAccordingToFEFO, true);
        CreateItem(Item, ItemTrackingCode.Code);
        UpdateExpirationCalculationOnItem(Item);
        FindBin(Bin, LocationWhite3.Code, false, true, true);  // Find PICK Bin.
        Quantity := LibraryRandom.RandInt(10);
        UpdateInventoryUsingWarehouseJournal(Bin, Item, Item."Base Unit of Measure", Quantity, true, ItemTrackingMode::"Assign Lot No.", 0D);  // Value required for test.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");  // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
        CreateAndReleaseSalesOrder(
          SalesHeader, SalesLine, Item."No.", Item."Base Unit of Measure", Bin."Location Code",
          Quantity + LibraryRandom.RandInt(10), true);  // Value required for test.

        // Exercise.
        CreatePickFromWarehouseShipment(SalesHeader);

        // Verify : Verify Expiration Date on Item Ledger Entry and related Pick lines.
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Positive Adjmt.", Item."No.", Item."Base Unit of Measure");
        ItemLedgerEntry.TestField("Expiration Date", CalcDate(Item."Expiration Calculation", WorkDate()));
        VerifyPickLine(
          WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take,
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", Item."No.", Item."Base Unit of Measure",
          ItemLedgerEntry."Lot No.", Quantity);
        VerifyPickLine(
          WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Place,
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", Item."No.", Item."Base Unit of Measure",
          ItemLedgerEntry."Lot No.", Quantity);

        // Tear down.
        UpdatePickAccordingToFEFOOnLocation(LocationWhite3, OldPickAccordingToFEFO, OldPickAccordingToFEFO);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure PickFromWarehouseShipmentWithQuantityAvailableOnBlockedBinContent()
    var
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // Setup : Create Item. Create and post Warehouse Receipt from Purchase Order. Block Outbound movement on Bin Content.
        Initialize();
        CreateItem(Item, '');
        Quantity := LibraryRandom.RandInt(100);
        CreateAndReleasePurchaseOrderWithMultipleUOM(
          PurchaseHeader, Item."No.", Item."Base Unit of Measure", '', LocationWhite3.Code, Quantity, false);  // Use FALSE for without Tracking.
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");
        FindRegisteredWhseActivityLine(
          RegisteredWhseActivityLine, RegisteredWhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          RegisteredWhseActivityLine."Activity Type"::"Put-away", RegisteredWhseActivityLine."Action Type"::Place);
        Bin.Get(LocationWhite3.Code, RegisteredWhseActivityLine."Bin Code");
        UpdateBlockMovementOnBinContent(BinContent, Bin, Item."No.", BinContent."Block Movement"::Outbound);

        // Exercise.
        asserterror CreatePickFromWarehouseShipmentWithReservation(SalesHeader, Item, LocationWhite3.Code, Quantity);

        // Verify : Verify Nothing to handle error message.
        Assert.ExpectedError(NothingToHandle);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ProductionJournalHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure RegisterPickFromWarehouseShipmentCreatedBeforeMoveSerialTrackedItemFromProdcutionBinToPickBin()
    var
        SalesHeaderNo: Code[20];
    begin
        Initialize();
        RegisterPickFromWarehouseShipmentCreatedBeforeMoveItemFromProdcutionBinToPickBin(
          SalesHeaderNo, ItemTrackingMode::"Assign Serial No.", ItemTrackingCode4.Code, true, false); // Use Serial Item Tracking.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ProductionJournalHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure RegisterPickFromWarehouseShipmentCreatedBeforeMoveLotTrackedItemFromProdcutionBinToPickBin()
    var
        SalesHeaderNo: Code[20];
    begin
        Initialize();
        RegisterPickFromWarehouseShipmentCreatedBeforeMoveItemFromProdcutionBinToPickBin(
          SalesHeaderNo, ItemTrackingMode::"Assign Lot No.", ItemTrackingCode.Code, false, true); // Use Lot Item Tracking.
    end;

    local procedure RegisterPickFromWarehouseShipmentCreatedBeforeMoveItemFromProdcutionBinToPickBin(var SalesHeaderNo: Code[20]; ItemTrackingModePar: Option; ItemTrackingCode: Code[10]; Serial: Boolean; Lot: Boolean)
    var
        ComponentItem: Record Item;
        ParentItem: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup : Create BOM with Item Tracking.
        CreateItemWithProductionBOMWithItemTracking(ParentItem, ComponentItem, ItemTrackingCode);

        // Exercise: Create Purchase Order for Child Item with Item Tracking.
        // Create and post Warehouse Receipt. Create and Register Put-Away.
        CreateAndRegisterPutAwayFromPurchaseOrder(
          PurchaseHeader, LocationWhite, ComponentItem."No.", ItemTrackingModePar, LibraryRandom.RandInt(5));

        // Create Sales Order for Parent Item with Item Tracking.
        CreateAndReleaseSalesOrderWithItemTracking(SalesHeader, SalesLine, ParentItem."No.",
          LocationWhite.Code, 1, true, ItemTrackingModePar); // 1 is used to avoid complexity when update Serial/Lot No. for registering pick.

        // Create Whse. Shipment from Sales Order.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // Create Prod. Order from Sales Order. Create Pick from Prod. Order. Register Pick. Post Production Journal.
        FindItemLedgerEntry(
          ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Purchase, ComponentItem."No.", ComponentItem."Base Unit of Measure");
        CreateAndRegisterPickFromProductionOrder(SalesHeader, ItemLedgerEntry, ParentItem."No.", Serial, Lot);

        // Move ParentItem From Production Bin to Pick Bin with Item Tracking.
        CreateAndRegisterWarehouseMovement(LocationWhite.Code, ParentItem."No.");

        // Verify: It is able to create and register Pick from previous Warehouse Shipment.
        CreateAndRegisterPickFromWarehouseShipment(SalesHeader);
        SalesHeaderNo := SalesHeader."No.";
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PostPartialWarehouseShipmentWithPartialPickFromTransferOrderUsingLotItemTracking()
    var
        ItemTracking: Option " ",Lot,Serial;
    begin
        // For Lot, the Qty is important to trigger the issue, here I use hardcode 5.
        Initialize();
        PostPartialWarehouseShipmentWithPartialPickFromTransferOrderUsingItemTracking(
          ItemTrackingMode::"Assign Lot No.", ItemTrackingCode.Code, 5, ItemTracking::Lot); // Use Lot Item Tracking.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PostPartialWarehouseShipmentWithPartialPickFromTransferOrderUsingSerialItemTracking()
    var
        ItemTracking: Option " ",Lot,Serial;
    begin
        // For Serial, it triggers issue first time with partial pick, 2 is ok for test and avoid complexity.
        Initialize();
        PostPartialWarehouseShipmentWithPartialPickFromTransferOrderUsingItemTracking(
          ItemTrackingMode::"Assign Serial No.", ItemTrackingCode4.Code, 2, ItemTracking::Serial); // Use Serial Item Tracking.
    end;

    local procedure PostPartialWarehouseShipmentWithPartialPickFromTransferOrderUsingItemTracking(ItemTrackingModePar: Option; ItemTrackingCode: Code[10]; Qty: Decimal; ItemTracking: Option " ",Lot,Serial)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        TransferHeader: Record "Transfer Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        // Setup : Create Item with Item Tracking. Create and post Warehouse Receipt. Create and Register Put-Away.
        CreateItem(Item, ItemTrackingCode);
        CreateAndRegisterPutAwayFromPurchaseOrder(PurchaseHeader, LocationWhite, Item."No.", ItemTrackingModePar, Qty);

        // Create and release Transfer Order from Location White to Location Blue with item tracking.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries"); // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
        CreateAndReleaseTransferOrderWithItemTracking(
          TransferHeader, LocationWhite.Code, LocationBlue.Code, Item."No.", Qty, true);

        // Exercise : Create Warehouse Shipment from Transfer Order, create Pick from Warehouse Shipment.
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentLine."Source Document"::"Outbound Transfer", TransferHeader."No.");

        // Verify : Verify Warehouse Shipment can be posted for partial registered Pick with item tracking.
        case ItemTracking of
            ItemTracking::Lot:
                UpdateQtyToHandleAndPostWarehouseShipmentForLot(TransferHeader, WarehouseShipmentHeader);
            ItemTracking::Serial:
                UpdateQtyToHandleAndPostWarehouseShipmentForSerial(TransferHeader, WarehouseShipmentHeader);
        end;
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PickFromSalesOrderUsingLotItemTrackingWithExpirationDate()
    var
        Bin: Record Bin;
        Item: Record Item;
        Item2: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityLine2: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // Setup : Create two items. Find the Pick Bin.
        Initialize();
        CreateItem(Item, ItemTrackingCode2.Code);
        CreateItem(Item2, '');
        Quantity := LibraryRandom.RandInt(10); // Intger type required for Serial No.
        FindBin(Bin, LocationWhite.Code, false, true, true); // Find PICK Bin.

        // Create and register Warehouse Item Journal using Item Tracking Line with Expiration Date < WORKDATE for Item.
        UpdateInventoryUsingWarehouseJournal(
          Bin, Item, Item."Base Unit of Measure", Quantity, true, ItemTrackingMode::"Assign Lot No.",
          CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));

        // Create and register Warehouse Item Journal using Item Tracking Line with Expiration Date > WORKDATE for Item.
        // To make sure there are available items not expired for pick.
        UpdateInventoryUsingWarehouseJournal(
          Bin, Item, Item."Base Unit of Measure", Quantity, true, ItemTrackingMode::"Assign Lot No.",
          CalcDate('<+' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));

        // Create and register Warehouse Item Journal for Item2 without Item Tracking.
        UpdateInventoryUsingWarehouseJournal(
          Bin, Item2, Item2."Base Unit of Measure", Quantity, false, ItemTrackingMode::" ", 0D);

        // Create and release Sales Order with two lines for Item and Item2.
        CreateAndReleaseSalesOrder(
          SalesHeader, SalesLine, Item."No.", Item."Base Unit of Measure", LocationWhite.Code, Quantity, false); // Use FALSE for without Tracking.
        CreateSalesLineForReleasedSalesOrder(
          SalesLine, SalesHeader, Item2."No.", Item2."Base Unit of Measure", LocationWhite.Code, Quantity, false, false); // Use FALSE for without Tracking and no Expiration Date.

        // Exercise : Create Pick from Warehouse Shipment.
        CreatePickFromWarehouseShipmentWithExpirationDate(SalesHeader);

        FindWarehousePickLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order",
          Item."No.", WarehouseActivityLine."Activity Type"::Pick);
        FindWarehousePickLine(
          WarehouseActivityLine2, WarehouseActivityLine2."Source Document"::"Sales Order",
          Item2."No.", WarehouseActivityLine2."Activity Type"::Pick);

        // Verify : Verify Item and Item2 were both picked into the same document.
        WarehouseActivityLine.TestField("No.", WarehouseActivityLine2."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesWithLotNoPageHandler')]
    [Scope('OnPrem')]
    procedure PickFromWarehouseShipmentAfterReleasingTransferOrderUsingLotWarehouseTracking()
    var
        Item: Record Item;
        TempWarehouseEntry: Record "Warehouse Entry" temporary;
        TransferHeader: Record "Transfer Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        SmallerQtyPerUnitOfMeasure: Decimal;
    begin
        // Setup : Create Item with multiple UOMs and Lot Item Tracking which has enabled Warehouse Item Tracking.
        // Create and release Purchase Order on Location White with multiple UOMS and Lots.
        // Create Warehouse Receipt on Location White, create Warehouse Put-Away.
        // Create and release Transfer Order from Location White to Location Blue. Assign Lot Item Tracking to each line in two steps. Release Transfer Order.
        // Create Warehouse Shipment from Transfer Order, generate Warehouse Pick.

        Initialize();
        AddBinsToLocation(LocationWhite.Code, false, false, true, true, false, 2);
        CreateItem(Item, ItemTrackingCode.Code);
        SmallerQtyPerUnitOfMeasure := 0.2;
        CreateAdditionalItemUOM(Item."No.", SmallerQtyPerUnitOfMeasure);
        CreateAdditionalItemUOM(
          Item."No.", SmallerQtyPerUnitOfMeasure * 10);

        PrepareDataForWarehouse(
          TempWarehouseEntry, Item, 3, true, 2);
        CreatePurchaseOrderAndPutAwayWithData(TempWarehouseEntry);
        ReorganizeDataForWarehouse(TempWarehouseEntry);
        CreateAndReleaseTransferOrderWithData(TransferHeader, TempWarehouseEntry, LocationBlue.Code, LotsAssignment::Partial);
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentLine."Source Document"::"Outbound Transfer", TransferHeader."No.");

        // Exercise : Register Pick.
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Outbound Transfer",
          TransferHeader."No.", WarehouseActivityLine."Activity Type"::Pick);

        // Verify : Pick is registered successfully, and calculated total base quantity equals to total base quantity in initial data.
        VerifyRegisteredPickLinesWithData(
          TempWarehouseEntry, WarehouseActivityLine."Activity Type"::Pick, TransferHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePickFromPickWorksheetWithPerWhseDocument()
    var
        Item: Record Item;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        SalesHeaderNo: array[2] of Code[20];
        Quantity: Decimal;
        i: Integer;
    begin
        // Setup: Create two Items and Sales Orders. Create and release Warehouse Shipment from each Sales Order.
        // Run Get Warehouse Document in Pick Worksheet to get all created Warehouse Shipments.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        FindBin(Bin, LocationWhite.Code, false, true, true); // Find PICK Bin.
        for i := 1 to 2 do begin
            CreateItem(Item, '');
            UpdateInventoryUsingWarehouseJournal(
              Bin, Item, Item."Base Unit of Measure", Quantity, false, ItemTrackingMode::" ", WorkDate());
            SalesHeaderNo[i] := CreateAndReleaseWarehouseShipmentFromSalesOrder(
                Item."No.", Item."Base Unit of Measure", Bin."Location Code", Quantity);
        end;

        // Update Block Movement for the 2nd Item in Bin Content.
        UpdateBlockMovementOnBinContent(BinContent, Bin, Item."No.", BinContent."Block Movement"::Outbound);

        // Exercise: Get Warehouse Document on Pick Worksheet.
        // Create Pick from Pick Worksheet with Per Whse. Document is TRUE.
        GetWarehouseDocumentOnPickWorksheet('', LocationWhite.Code, true); // Blank for Item No.

        // Verify: Verify Pick can be created successfully.
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeaderNo[1],
          WarehouseActivityLine."Activity Type"::Pick);
        Assert.AreEqual(Quantity, WarehouseActivityLine.Quantity, WhseActivLineQtyErr);
    end;

    [Test]
    [HandlerFunctions('BOMCostSharesPageHandler')]
    [Scope('OnPrem')]
    procedure BOMCostSharesWithMultipleUOM()
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ParentItem: Record Item;
        ComponentItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // Setup: Create Parent Item and Component Item. Create Unit of Measure of Parent Item.
        // Create Production BOM with the new created Unit of Measure for Parent Item.
        Initialize();
        CreateItem(ParentItem, '');
        CreateItem(ComponentItem, '');
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, ParentItem."No.", LibraryRandom.RandInt(5) + 1); // Value required for multiple UOM with different conversion rate.
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ComponentItem."No.", ItemUnitOfMeasure.Code, 1, BomLineType::Item);
        UpdateProductionBomAndRoutingOnItem(ParentItem, ProductionBOMHeader."No.", '');
        LibraryVariableStorage.Enqueue(ParentItem."Base Unit of Measure"); // Enqueue Value to verify the Unit of Measure Code.

        // Exercise: Run BOM Cost Shares Page.
        RunBOMCostSharesPage(ParentItem);

        // Verify: Verify the Unit of Measure Code on BOM Cost Shares page through BOMCostSharesPageHandler.
    end;

    [Test]
    [HandlerFunctions('MultipleBOMCostSharesPageHandler')]
    [Scope('OnPrem')]
    procedure MultipleBOMCostSharesWithMultipleUOM()
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        TopItemUnitOfMeasure: Record "Item Unit of Measure";
        ParentItem: Record Item;
        TopParentItem: Record Item;
        ComponentItem: Record Item;
        TopBOMQtyPer: Decimal;
        QtyPer: Decimal;
    begin
        // Setup: Create Parent Item and Component Item. Create Unit of Measure of Parent Item.
        // Create Production BOM with the new created Unit of Measure for Parent Item.
        // Create Unit of Measure of Top Parent Item.Create Production BOM with the new created Unit of Measure for Top Parent Item.
        Initialize();
        CreateItem(TopParentItem, '');
        CreateItem(ParentItem, '');
        CreateItem(ComponentItem, '');
        CreateAndCertifyProductionBOMWithUOM(ItemUnitOfMeasure, ParentItem, ComponentItem."No.", TopBOMQtyPer, BomLineType::Item);
        CreateAndCertifyProductionBOMWithUOM(TopItemUnitOfMeasure, TopParentItem, ParentItem."No.", QtyPer, BomLineType::Item);

        // Enqueue Values for MultipleBOMCostSharesPageHandler to verify values on page BOM Cost Shares.
        EnqueueValuesToVerifyBOMCostSharesPage(
          TopParentItem."No.", TopParentItem."Base Unit of Measure", TopItemUnitOfMeasure.Code, 1, 1, 0);
        EnqueueValuesToVerifyBOMCostSharesPage(
          ParentItem."No.", ParentItem."Base Unit of Measure", ItemUnitOfMeasure.Code,
          TopBOMQtyPer / TopItemUnitOfMeasure."Qty. per Unit of Measure",
          TopBOMQtyPer / TopItemUnitOfMeasure."Qty. per Unit of Measure", TopBOMQtyPer);

        EnqueueValuesToVerifyBOMCostSharesPage(
          ComponentItem."No.", ComponentItem."Base Unit of Measure", '', QtyPer / ItemUnitOfMeasure."Qty. per Unit of Measure",
          TopBOMQtyPer / TopItemUnitOfMeasure."Qty. per Unit of Measure" * QtyPer / ItemUnitOfMeasure."Qty. per Unit of Measure", QtyPer);

        // Exercise: Run BOM Cost Shares Page.
        RunBOMCostSharesPage(TopParentItem);

        // Verify: Verify values on BOM Cost Shares page through MultipleBOMCostSharesPageHandler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyPerTopItemInBOMCostSharesWithPhantomBOM()
    var
        TopParentItem: Record Item;
        ComponentItem: Record Item;
        TopItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ProductionBOMHeader: Record "Production BOM Header";
        BOMBuffer: Record "BOM Buffer";
        CalcBOMTree: Codeunit "Calculate BOM Tree";
        QtyPer: Decimal;
        ParentBOMHeaderNo: Code[20];
    begin
        // [FEATURE] [Production BOM] [Cost Shares]
        // [SCENARIO 363019] BOM Cost Shares report is generated for a BOM including a phantom BOM as a component
        Initialize();

        QtyPer := 2;

        // [GIVEN] Component Item with Unit of Measure = "Y"
        CreateItem(ComponentItem, '');
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, ComponentItem."No.", 2);

        // [GIVEN] Production BOM "A" including the component Item, "Qty. per" = "Q"
        CreateAndCertifyProductionBOM(
          ProductionBOMHeader, ComponentItem."No.", ItemUnitOfMeasure.Code, QtyPer, BomLineType::Item);
        ParentBOMHeaderNo := ProductionBOMHeader."No.";

        // [GIVEN] Production BOM "B" including Production BOM "A" with type = "Production BOM"
        // [GIVEN] Top Item with Unit of Measure = "X", Production BOM No = "B"
        CreateItem(TopParentItem, '');
        CreateItemUnitOfMeasure(TopItemUnitOfMeasure, TopParentItem."No.", 2);
        CreateAndCertifyProductionBOM(
          ProductionBOMHeader, ParentBOMHeaderNo, TopItemUnitOfMeasure.Code, QtyPer, BomLineType::"Production BOM");
        UpdateProductionBomAndRoutingOnItem(TopParentItem, ProductionBOMHeader."No.", '');

        // [WHEN] Generate BOM Cost Shares
        CalcBOMTree.GenerateTreeForOneItem(TopParentItem, BOMBuffer, 99981231D, "BOM Tree Type"::" ");

        // [THEN] "Qty. per Top Item" in the component line is "Q"
        FindBOMBufferLine(BOMBuffer, ComponentItem."No.");
        Assert.AreEqual(QtyPer, BOMBuffer."Qty. per Top Item", QuantityMustBeSame);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyPerTopItemInPhantomBOMIsMultipliedByParentQtyPer()
    var
        ComponentItem: Record Item;
        ParentItem: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ProductionBOMHeader: Record "Production BOM Header";
        BOMBuffer: Record "BOM Buffer";
        CalcBOMTree: Codeunit "Calculate BOM Tree";
        UOMMgt: Codeunit "Unit of Measure Management";
        ComponentQtyPer: Decimal;
        PhantomBOMQtyPer: Decimal;
    begin
        // [FEATURE] [Production BOM] [Cost Shares]
        // [SCENARIO 363174] Qty. per BOM Line and Qty. per Parent in Cost Shares report are multiplied by phantom bom "quantity per" for phantom bom lines
        Initialize();

        // [GIVEN] Low-level component item
        ComponentQtyPer := 2;
        PhantomBOMQtyPer := 2;

        CreateItem(ComponentItem, '');

        // [GIVEN] Production BOM "A" including the component Item, "Qty. per" = "Q1"
        CreateAndCertifyProductionBOM(
          ProductionBOMHeader, ComponentItem."No.", ComponentItem."Base Unit of Measure", ComponentQtyPer, BomLineType::Item);

        // [GIVEN] Top Item with Unit of Measure = "X", additional unit of measure with "Base UoM Quantity" = "Q2"
        CreateItem(ParentItem, '');
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, ParentItem."No.", 2);
        // [GIVEN] Production BOM "B" including Production BOM "A" with type = "Production BOM" (phantom BOM), "Qantity per" = "Q3"
        CreateAndCertifyProductionBOM(
          ProductionBOMHeader, ProductionBOMHeader."No.", ItemUnitOfMeasure.Code, PhantomBOMQtyPer, BomLineType::"Production BOM");
        UpdateProductionBomAndRoutingOnItem(ParentItem, ProductionBOMHeader."No.", '');

        // [WHEN] Generate BOM Cost Shares
        CalcBOMTree.GenerateTreeForOneItem(ParentItem, BOMBuffer, 99981231D, "BOM Tree Type"::" ");

        FindBOMBufferLine(BOMBuffer, ComponentItem."No.");

        // [THEN] Component item's "Quantity per BOM Line" = "Q1" * "Q3"
        Assert.AreEqual(ComponentQtyPer * PhantomBOMQtyPer, BOMBuffer."Qty. per BOM Line", QuantityMustBeSame);
        // [THEN] Component item's "Quantity per Parent" = "Q1" * "Q3" / "Q2"
        Assert.AreEqual(
          ComponentQtyPer * PhantomBOMQtyPer / UOMMgt.GetQtyPerUnitOfMeasure(ParentItem, ItemUnitOfMeasure.Code),
          BOMBuffer."Qty. per Parent", QuantityMustBeSame);
    end;

    [Test]
    [HandlerFunctions('ItemUOMHandler')]
    [Scope('OnPrem')]
    procedure OpenItemUnitOfMeasurePageWithNoTransactions()
    var
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
    begin
        // [FEATURE] [Item Unit of Measure]
        // [SCENARIO 371765] "Item Unit of Measure" Page should take "Base Unit of Measure" from Item if Item has no transaction
        Initialize();

        // [GIVEN] Item with "Base Unit Of Measure" = "X"
        LibraryInventory.CreateItem(Item);

        // [WHEN] Open "Item Unit of Measure" Page
        // [THEN] Page is opened with "Unit Of Measure" = "X"
        LibraryVariableStorage.Enqueue(Item."Base Unit of Measure");
        ItemUOM.SetRange("Item No.", Item."No.");
        PAGE.RunModal(0, ItemUOM);
    end;

    [Test]
    [HandlerFunctions('ItemUOMHandler')]
    [Scope('OnPrem')]
    procedure OpenItemUnitOfMeasurePageWithDifferentTransactions()
    var
        Item: Record Item;
        ItemUOM1: Record "Item Unit of Measure";
        ItemUOM2: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Item Unit of Measure]
        // [SCENARIO 371765] "Item Unit of Measure" Page should take correct "Unit of Measure" from Item if Item has multiple transaction with different UOM
        Initialize();

        // [GIVEN] Item with "Base Unit Of Measure" = "X", secondary UOM = "Y"
        // [GIVEN] Purchase Order Line for Item with UOM = "X"
        // [GIVEN] Purchase Order Line for Item with UOM = "Y"
        CreateItemWithMultipleUOM(Item, ItemUOM1, ItemUOM2, '');
        CreateAndReleasePurchaseOrderWithMultipleUOM(
          PurchaseHeader, Item."No.", Item."Purch. Unit of Measure", Item."Put-away Unit of Measure Code",
          LocationWhite3.Code, LibraryRandom.RandDec(100, 2), false);

        // [WHEN] Open "Item Unit of Measure" Page
        // [THEN] Page is opened with Unit Of Measure = "X"
        LibraryVariableStorage.Enqueue(ItemUOM1.Code);
        ItemUOM1.SetRange("Item No.", Item."No.");
        PAGE.RunModal(0, ItemUOM1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyPerUoMShouldAlignWithRoundingPrecision()
    var
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        BaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        // [SCENARIO 396617] Qty. per Unit of Measure's decimal place should align with Qty. Rounding Precision.
        // [GIVEN] An item with base UoM and rounding precision.
        Initialize();
        BaseQtyPerUOM := 1;
        QtyRoundingPrecision := Round(1 / LibraryRandom.RandIntInRange(10, 1000), 0.0001);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();
        Commit();

        // [WHEN] Adding a Non Base item UoM with Qty. per Unit of Measure unaligned with Rounding Precision.
        NonBaseQtyPerUOM := QtyRoundingPrecision / 10000;
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);

        // [THEN] Error is thrown as the Qty. per Unit of Measure's decimal place does not align with Rounding Precision.
        asserterror LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        // [GIVEN] A Non Base item UoM with Qty. per Unit of Measure aligned with Rounding Precision.
        NonBaseQtyPerUOM := QtyRoundingPrecision;
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        // [WHEN] Changing Qty. Rounding Precision to have number of decimal digits lower than Qty. per Unit of Measure.
        QtyRoundingPrecision := NonBaseQtyPerUOM * 10;
        // [THEN] Error is thrown as existing Non Base item's Qty. per Unit of Measure's decimal place does not align with Rounding Precision.
        asserterror ItemUOM.Validate("Qty. Rounding Precision", QtyRoundingPrecision);

    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteItemUnitOfMeasure()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        // [FEATURE] [Item Unit of Measure]
        // [SCENARIO 374969] Deleting Item Unit of Measure should be prohibited if Item has Warehouse Adjustment Entries
        Initialize();

        // [GIVEN] Item with secondary UoM = "X"
        LibraryInventory.CreateItem(Item);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandInt(10));

        // [GIVEN] Warehouse Adjustment Entry for Item in UoM = "X"
        MockWarehouseAdjustmentEntry(ItemUnitOfMeasure);

        // [WHEN] Delete Item UoM "X"
        asserterror ItemUnitOfMeasure.Delete(true);

        // [THEN] Error is thrown: "Cannot modify Item Unit of Measure"
        Assert.ExpectedError(CannotModifyUOMWithWhseEntriesErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteUnitOfMeasureWhileInUseInItems()
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
    begin
        // [FEATURE] [Item Unit of Measure]
        // Deleting Item Unit of Measure should be prohibited if UOM is still in use in an item
        Initialize();

        // [GIVEN] Item with secondary UoM = "X"
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItem(Item);
        Item."Base Unit of Measure" := UnitOfMeasure.Code;
        Item.Modify();

        // [WHEN] Delete UoM "X"
        asserterror UnitOfMeasure.Delete(true);

        // [THEN] Error is thrown: "Cannot delete a unit of measure that is still used."
        Assert.ExpectedError(UoMIsStillUsedError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteUnitOfMeasureThatIsNotUsed()
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        // [FEATURE] [Item Unit of Measure]
        // Deleting Item Unit of Measure should be prohibited if UOM is still in use in an item
        Initialize();

        // [GIVEN] Item with secondary UoM = "X"
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        // [WHEN] Delete Item UoM "X"
        // [THEN] The unit of measure is deleted
        UnitOfMeasure.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenameItemUnitOfMeasure()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        // [FEATURE] [Item Unit of Measure]
        // [SCENARIO 374969] Renaming Item Unit of Measure should be prohibited if Item has Warehouse Adjustment Entries
        Initialize();

        // [GIVEN] Item with secondary UoM = "X"
        LibraryInventory.CreateItem(Item);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandInt(10));

        // [GIVEN] Warehouse Adjustment Entry for Item in UoM = "X"
        MockWarehouseAdjustmentEntry(ItemUnitOfMeasure);

        // [WHEN] Rename Item UoM "X" to "Y"
        asserterror ItemUnitOfMeasure.Rename(Item."No.", LibraryUtility.GenerateGUID());

        // [THEN] Error is thrown: "Cannot modify Item Unit of Measure"
        Assert.ExpectedError(CannotModifyUOMWithWhseEntriesErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteItemUnitOfMeasureWhileOrderLineExists()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Item Unit of Measure]
        // [SCENARIO 375608] Deleting Item Unit of Measure should be prohibited if there is Order Line for that Item

        // [GIVEN] Item with secondary UoM = "X"
        LibraryInventory.CreateItem(Item);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandInt(10));

        // [GIVEN] Sales Order for Item in UoM = "X"
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, Item."No.", ItemUnitOfMeasure.Code, '', LibraryRandom.RandInt(10), false);

        // [WHEN] Delete Item UoM "X"
        asserterror ItemUnitOfMeasure.Delete(true);

        // [THEN] Error is thrown: "Cannot modify Item Unit of Measure"
        Assert.ExpectedError(CannotModifyUOMWithWhseEntriesErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MovementChangeUOM()
    var
        Item: Record Item;
        ItemUOM: array[2] of Record "Item Unit of Measure";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseMovement: TestPage "Warehouse Movement";
    begin
        // [FEATURE] [Movement] [Item Unit of Measure]
        // [SCENARIO 375782] Cannot change Unit of Measure for Movement Place line when "Qty. to Handle" = 0.

        // [GIVEN] Warehouse Movement for Item with multiple UOMs, "Qty. to Handle" = 0
        Initialize();
        CreateItemWithMultipleUOM(Item, ItemUOM[1], ItemUOM[2], '');
        MockMovement(WarehouseActivityHeader, Item."No.", ItemUOM[1]."Qty. per Unit of Measure");

        // [WHEN] Change Unit of Measure for Place line
        WarehouseMovement.Trap();
        WarehouseMovement.OpenEdit();
        WarehouseMovement.GotoRecord(WarehouseActivityHeader);
        WarehouseMovement.WhseMovLines.Last();
        asserterror WarehouseMovement.WhseMovLines.ChangeUnitOfMeasure.Invoke();

        // [THEN] Error message regarding "Qty. to Handle" = 0
        Assert.ExpectedError(
          StrSubstNo(QtyToHandleErr, WarehouseActivityLine.FieldCaption("Qty. to Handle")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyPerOnItemUnitOfMeasureInFinishedProdOrderLine()
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Item: Record Item;
        QtyPer: Decimal;
    begin
        // [FEATURE] [Item Unit of Measure] [Production Order]
        // [SCENARIO 377099] It should be possible to change "Qty. per Unit of Measure" of Item Unit of Measure if there are Finished Prod. Order Lines with posted Partial Consumption using this UoM
        Initialize();

        // [GIVEN] Nonbase Item UoM "A" with "Qty. per Unit of Measure" = "X"
        LibraryInventory.CreateItem(Item);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandInt(100));
        UpdateItemUOM(Item, Item."Base Unit of Measure", Item."Base Unit of Measure", ItemUnitOfMeasure.Code);

        // [GIVEN] Finished Production Order Line with partial posted consumption in UoM = "A"
        MockFinProdOrderLine(Item."No.", ItemUnitOfMeasure.Code);

        // [WHEN] Change "Qty. per Unit of Measure" of Item UoM "A" to "Y"
        QtyPer := LibraryRandom.RandInt(100);
        ItemUnitOfMeasure.Validate("Qty. per Unit of Measure", QtyPer);
        ItemUnitOfMeasure.Modify(true);

        // [THEN] Item UoM "A" has "Qty. per Unit of Measure" = "Y"
        ItemUnitOfMeasure.TestField("Qty. per Unit of Measure", QtyPer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyPerOnItemUnitOfMeasureInFinishedProdOrderComp()
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Item: Record Item;
        QtyPer: Decimal;
    begin
        // [FEATURE] [Item Unit of Measure] [Production Order]
        // [SCENARIO 377099] It should be possible to change "Qty. per Unit of Measure" of Item Unit of Measure if there are Finished Prod. Order Components with posted Partial Consumption using this UoM
        Initialize();

        // [GIVEN] Nonbase Item UoM "A" with "Qty. per Unit of Measure" = "X"
        LibraryInventory.CreateItem(Item);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandInt(100));
        UpdateItemUOM(Item, Item."Base Unit of Measure", Item."Base Unit of Measure", ItemUnitOfMeasure.Code);

        // [GIVEN] Finished Production Order Component with partial posted consumption in UoM = "A"
        MockFinProdOrderComp(Item."No.", ItemUnitOfMeasure.Code);

        // [WHEN] Change "Qty. per Unit of Measure" of Item UoM "A" to "Y"
        QtyPer := LibraryRandom.RandInt(100);
        ItemUnitOfMeasure.Validate("Qty. per Unit of Measure", QtyPer);
        ItemUnitOfMeasure.Modify(true);

        // [THEN] Item UoM "A" has "Qty. per Unit of Measure" = "Y"
        ItemUnitOfMeasure.TestField("Qty. per Unit of Measure", QtyPer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ForInventoryInDifferentUOMRegisterPickWhenOtherPickExists()
    var
        Item: Record Item;
        BaseItemUnitOfMeasure: Record "Item Unit of Measure";
        NonBaseItemUnitOfMeasure: Record "Item Unit of Measure";
        SalesHeader: array[2] of Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        QtyPer: Decimal;
        BaseUOMPurchQty: Decimal;
        NonBaseUOMPurchQty: Decimal;
        BaseUOMSalesQty: array[2] of Decimal;
    begin
        // [FEATURE] [Item Unit of Measure] [Pick]
        // [SCENARIO 380472] It should be possible to register Pick when other Picks exist according to total quantity base available in warehouse and not to take into account the quantities in different UOMs.
        Initialize();

        BaseUOMSalesQty[1] := LibraryRandom.RandIntInRange(2, 10);
        BaseUOMPurchQty := BaseUOMSalesQty[1] + LibraryRandom.RandInt(BaseUOMSalesQty[1] - 1);
        NonBaseUOMPurchQty := LibraryRandom.RandInt(10);
        QtyPer := LibraryRandom.RandIntInRange(5, 10);
        BaseUOMSalesQty[2] := BaseUOMPurchQty + (NonBaseUOMPurchQty * QtyPer) - BaseUOMSalesQty[1];

        // [GIVEN] Item with additional Unit of Measure. Base UOM - PCS, Non base - BOX, "Quantity Per" = 6.
        CreateItemWithNonBaseUOM(Item, BaseItemUnitOfMeasure, NonBaseItemUnitOfMeasure, QtyPer);

        // [GIVEN] Registered Put-away for this Item in both UOM - 5 PCS and 2 BOX.
        RegisterPutAwayForItemWithTwoUOM(
          LocationWhite2.Code, Item."No.", Item."Base Unit of Measure", BaseUOMPurchQty, NonBaseItemUnitOfMeasure.Code, NonBaseUOMPurchQty);

        // [GIVEN] Two Picks for two Sales Orders - P1 and P2, both in base UOM. P1 - 4 PCS, P2 - 13 PCS. Total pick quantity (4 + 13) is equal to total quantity available in warehouse (5 + 2 * 6).
        CreateSalesOrderAndPick(SalesHeader[1], LocationWhite2.Code, Item."No.", Item."Base Unit of Measure", BaseUOMSalesQty[1]);
        CreateSalesOrderAndPick(SalesHeader[2], LocationWhite2.Code, Item."No.", Item."Base Unit of Measure", BaseUOMSalesQty[2]);

        // [WHEN] Register pick P1, then P2. Sequence is important for test.
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader[1]."No.", WarehouseActivityLine."Activity Type"::Pick);

        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader[2]."No.", WarehouseActivityLine."Activity Type"::Pick);

        // [THEN] Both Picks are registered without errors.

        // [THEN] Quantity picked in Pick document P1 is 4. Quantity picked in Pick document P2 is 13.
        Assert.AreEqual(
          BaseUOMSalesQty[1],
          CalcTakenForPickQtyBaseOfItemWithUOMInSalesOrder(SalesHeader[1]."No.", Item."No.", BaseItemUnitOfMeasure.Code), WrongTotalQtyErr);
        Assert.AreEqual(
          BaseUOMSalesQty[2],
          CalcTakenForPickQtyBaseOfItemWithUOMInSalesOrder(SalesHeader[2]."No.", Item."No.", BaseItemUnitOfMeasure.Code), WrongTotalQtyErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure RegisterPickWhenNegativeAdjustmentAndATOExists()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseActivityLineTake: Record "Warehouse Activity Line";
        WarehouseActivityLinePlace: Record "Warehouse Activity Line";
        PurchQty: Decimal;
        SalesQty: Decimal;
        AssemblySalesQty: Decimal;
        InAssemblySalesQty: Decimal;
        RegisterPickQty: Decimal;
        QtyPer: Decimal;
        NegativeAdjstmntQty: Decimal;
    begin
        // [FEATURE] [Item Unit of Measure] [Pick] [Assembly]
        // [SCENARIO 380472] Registering a Pick should not be allowed when difference between Quantity in Warehouse Ledger Entry and sum of Quantity of Negative Adjustment in Warehouse Journal and Quantity in ATO is less then Quantity for Pick.
        Initialize();

        QtyPer := LibraryRandom.RandIntInRange(2, 5);
        SalesQty := LibraryRandom.RandIntInRange(10, 30);
        AssemblySalesQty := LibraryRandom.RandIntInRange(1, 5);
        InAssemblySalesQty := AssemblySalesQty * QtyPer;
        PurchQty := SalesQty + InAssemblySalesQty;
        RegisterPickQty := SalesQty - InAssemblySalesQty;
        NegativeAdjstmntQty := LibraryRandom.RandInt(SalesQty - 1);

        // [GIVEN] Assembled Item with one Component
        CreateAssembledItem(ParentItem, ChildItem, QtyPer);

        // [GIVEN] Registered Put-away for Component Item - 30 PCS.
        RegisterPutAwayForItem(LocationWhite2.Code, ChildItem."No.", PurchQty);

        // [GIVEN] Pick for ATO of this Component Item - 10 PCS.
        CreateAssembledItemSalesOrderAndAssemblyOrderPick(LocationWhite2.Code, ParentItem."No.", AssemblySalesQty);

        // [GIVEN] Pick for Sales Order this Component Item - 20 PCS.
        CreateSalesOrderAndPick(SalesHeader, LocationWhite2.Code, ChildItem."No.", ChildItem."Base Unit of Measure", SalesQty);

        FindWarehouseActivityLinesPairForPick(
          WarehouseActivityLineTake, WarehouseActivityLinePlace,
          WarehouseActivityLineTake."Source Document"::"Sales Order", SalesHeader."No.");

        // [GIVEN] Negative Adjustment - 2 PCS.
        CreateNegativeAdjmtWarehouseJournalLine(
          ChildItem, LocationWhite2.Code, WarehouseActivityLineTake."Bin Code", NegativeAdjstmntQty);

        // [WHEN] Try to register Pick

        // [THEN] Error 'Quantity (Base) available must not be less than ...' occurs.
        asserterror RegisterWarehouseActivity(WarehouseActivityLineTake."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLineTake."Activity Type"::Pick);

        Assert.ExpectedError(QuantityBaseAvailableMustNotBeLessErr);

        // [WHEN] Update "Qty. to Handle" for Pick = 10 and try to register Pick
        UpdateQtyToHandleOnWarehouseActivityLinesPair(WarehouseActivityLineTake, WarehouseActivityLinePlace, RegisterPickQty);

        RegisterWarehouseActivity(
          WarehouseActivityLineTake."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityLineTake."Activity Type"::Pick);

        // [THEN] Pick is registered without errors.

        // [THEN] Picked base quantity is equal to the "Qty. to Handle" for Pick = 10.
        Assert.AreEqual(
          RegisterPickQty,
          CalcTakenForPickQtyBaseOfItemWithUOMInSalesOrder(SalesHeader."No.", ChildItem."No.", ChildItem."Base Unit of Measure"),
          WrongTotalQtyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePickActionTypeTakeCorrectBinsForDifferentUOMsAndRanking()
    var
        Location: Record Location;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        QtyPer: Decimal;
        NoOfBins: Integer;
        PurchItemInLineBaseQty: Decimal;
        TotalPurchItemBaseQty: Decimal;
        SalesQtyInSalesUOM: array[2] of Decimal;
    begin
        // [FEATURE] [Item Unit of Measure] [Pick] [Bin Ranking]
        // [SCENARIO 381799] When UOMs of Warehouse Shipment are unaliquot to the quantities placed in bins can create warehouse pick correctly and post warehouse shipment.
        Initialize();

        // [GIVEN] WMS Location W with three Bins BIN1, BIN2, BIN3. BIN1 (first according to default sorting Bin) has maximal Bin Ranking.
        NoOfBins := 3;
        CreateFullWarehouseSetupWithNumberOfBinsAndSetRanking(Location, NoOfBins);

        // [GIVEN] Item I with Sales Unit Of Measure SUOM that Quantity Per is greater than one.
        QtyPer := LibraryRandom.RandIntInRange(5, 10);
        CreateItemWithSalesUOM(Item, QtyPer);

        // [GIVEN] Purchased Item I is placed at Warehouse W in different bins. Quantities in Bins are not aliquot to the SUOM Quantity Per.
        PurchItemInLineBaseQty := QtyPer * LibraryRandom.RandIntInRange(10, 100) + 1;
        TotalPurchItemBaseQty := PurchItemInLineBaseQty * NoOfBins;

        // [GIVEN] The Sales Order SO of Item I with two lines with SUOM. The total Quantity (Base) of SO covers the total inventory of Item I.
        SalesQtyInSalesUOM[1] :=
          LibraryRandom.RandIntInRange(PurchItemInLineBaseQty, TotalPurchItemBaseQty - PurchItemInLineBaseQty) / QtyPer;
        SalesQtyInSalesUOM[2] := TotalPurchItemBaseQty / QtyPer - SalesQtyInSalesUOM[1];

        // [WHEN] Realese Sales Order and create shipment and pick
        CreateWarehouseShipmentAndPickForItemAtLocationFromDifferentBins(
          SalesHeader, WarehouseShipmentHeader, Location.Code, Item."No.", NoOfBins, PurchItemInLineBaseQty, SalesQtyInSalesUOM);

        FindWarehouseActivityLineWithActionType(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take);

        // [THEN] The pick contains only one line Action Type Take for BIN1.
        // [THEN] The pick contains only one line Action Type Take for BIN2.
        // [THEN] The pick contains two lines Action Type Take for BIN3.
        VerifyWarehouseActivityLineActionPickActivityTake(WarehouseActivityLine);

        // [GIVEN] Register Warehouse Pick.
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);

        // [WHEN] Post Warehouse Shipment
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, true);

        // [THEN] The purchased Item I is sold completely and there is no any open Item Ledger Entry for I.
        ItemLedgerEntry.Init();
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange(Open, true);
        Assert.RecordIsEmpty(ItemLedgerEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PutAwayWithAutomaticBreakbulkToPutAwayUOM()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        QtyPerUOM: Decimal;
        PurchQty: Decimal;
    begin
        // [FEATURE] [Put-Away] [Breakbulk] [Item Unit of Measure]
        // [SCENARIO 216337] If a receipt is posted in a larger unit of measure, a put-away with automatically suggested breakbulk to the put-away unit of measure, can be registered.
        Initialize();
        QtyPerUOM := LibraryRandom.RandIntInRange(5, 10);
        PurchQty := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] Full WMS location "L" with Allow Breakbulk = FALSE.
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        Location.Validate("Allow Breakbulk", false);
        Location.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Item with Base Unit of Measure = "PCS" and alternate Unit of Measure = "BOX". "BOX" contains "X" units of "PCS".
        // [GIVEN] Put-away Unit of Measure Code in the item is "PCS".
        LibraryInventory.CreateItem(Item);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", QtyPerUOM);
        UpdateItemUOM(Item, ItemUnitOfMeasure.Code, '', Item."Base Unit of Measure");

        // [GIVEN] Posted receipt for "Y" units of "BOX".
        CreateAndReleasePurchaseOrder(PurchaseHeader, Location.Code, Item."No.", PurchQty);
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader);

        // [WHEN] Register Put-away.
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");

        // [THEN] The Put-away is successfully registered. "X" * "Y" units of "PCS" are placed into the storage bin.
        FindBin(Bin, Location.Code, false, true, true);
        VerifyBinContent(Bin, Item."No.", PurchQty * QtyPerUOM, Item."Put-away Unit of Measure Code");

        // [THEN] Receive bin is empty.
        FindBin(Bin, Location.Code, true, false, false);
        FindBinContent(BinContent, Bin, Item."No.");
        if BinContent.FindFirst() then begin
            BinContent.CalcFields(Quantity);
            Assert.AreEqual(0, BinContent.Quantity, 'Bin Content must be empty.');
        end;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DeleteItemUnitOfMeasureWhenNoLocationExists()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Location: Record Location;
    begin
        // [FEATURE] [Item Unit of Measure]
        // [SCENARIO 200270] Stan can delete Item Unit Of Measure even if there are no locations

        // [GIVEN] Item with secondary UoM = "X"
        LibraryInventory.CreateItem(Item);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandInt(10));

        // [GIVEN] No Locations in current database
        Location.DeleteAll();

        // [WHEN] Delete Item UoM "X"
        ItemUnitOfMeasure.Delete(true);

        // [THEN] Item UOM is deleted
        Assert.IsFalse(ItemUnitOfMeasure.Find(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeUOMOnProdOrderLineDoesNotConvertOverheadRate()
    var
        Item: Record Item;
        BaseItemUnitOfMeasure: Record "Item Unit of Measure";
        AlternateItemUnitOfMeasure: Record "Item Unit of Measure";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ReleasedProductionOrder: TestPage "Released Production Order";
        ProductionOrderStatistics: TestPage "Production Order Statistics";
    begin
        // [FEATURE] [Item Unit of Measure] [Production Order] [Overhead Rate]
        // [SCENARIO 266142] "Overhead Rate" on prod. order line is not recalculated when a user changes unit of measure code on the line.
        Initialize();

        // [GIVEN] Item "I" with base "PCS" and alternate unit of measure "PALLET".
        CreateItemWithNonBaseUOM(Item, BaseItemUnitOfMeasure, AlternateItemUnitOfMeasure, LibraryRandom.RandIntInRange(10, 20));

        // [GIVEN] Set "I"."Overhead Rate" = "X".
        Item.Validate("Overhead Rate", LibraryRandom.RandDecInRange(100, 200, 2));
        Item.Modify(true);

        // [GIVEN] Released production order for "q" PCS of item "I".
        CreateAndRefreshProductionOrder(ProductionOrder, Item."No.", '', '', LibraryRandom.RandIntInRange(10, 20));
        FindProductionOrderLine(ProdOrderLine, Item."No.");

        // [WHEN] Change "Unit of Measure Code" on the prod. order line to "PALLET". The base quantity is hence increased to "Q".
        ProdOrderLine.Validate("Unit of Measure Code", AlternateItemUnitOfMeasure.Code);
        ProdOrderLine.Modify(true);

        // [THEN] "Overhead Rate" on the line has not been recalculated and remains equal to "X".
        ProdOrderLine.TestField("Overhead Rate", Item."Overhead Rate");

        // [THEN] Expected cost on "Manufacturing Overhead" row on the statistics page shows "X" * "Q"
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GotoKey(ProductionOrder.Status, ProductionOrder."No.");
        ProductionOrderStatistics.Trap();
        ReleasedProductionOrder.Statistics.Invoke();
        ProductionOrderStatistics.MfgOverhead_ExpectedCost.AssertEquals(Item."Overhead Rate" * ProdOrderLine."Quantity (Base)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeBinCodeOnWhsePickWithAlternateUOMDoesNotRaiseConfirmIfNoAvailIssueOccurs()
    var
        Item: Record Item;
        BaseItemUnitOfMeasure: Record "Item Unit of Measure";
        AlternateItemUnitOfMeasure: Record "Item Unit of Measure";
        Zone: Record Zone;
        Bin: array[2] of Record Bin;
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Qty: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Item Unit of Measure] [Pick] [Bin Content]
        // [SCENARIO 264375] When you change bin code on warehouse pick line with alternate unit of measure to a bin, that has sufficient quantity to pick, a confirm with warning of lacking quantity to pick should not raise.
        Initialize();

        // [GIVEN] Location set up for directed put-away and pick.
        CreateFullWMSLocationAndFindPickZone(Zone);

        // [GIVEN] Item "I" with base unit of measure "KG" and alternate unit of measure "OZ". 1 "OZ" = 0.03 "KG".
        CreateItemWithNonBaseUOM(
          Item, BaseItemUnitOfMeasure, AlternateItemUnitOfMeasure, LibraryRandom.RandIntInRange(1, 99) / 1000);

        // [GIVEN] Pick bins "B1" and "B2" have 100 "OZ" of the item stored in each of them.
        Qty := LibraryRandom.RandIntInRange(100, 200);
        for i := 1 to ArrayLen(Bin) do begin
            LibraryWarehouse.FindBin(Bin[i], Zone."Location Code", Zone.Code, i);
            UpdateInventoryUsingWarehouseJournal(
              Bin[i], Item, AlternateItemUnitOfMeasure.Code, Qty, false, ItemTrackingMode::" ", WorkDate());
        end;

        // [GIVEN] Sales order for 10 "OZ" of item "I".
        // [GIVEN] Warehouse shipment and pick are created for the order.
        CreateSalesOrderAndPick(
          SalesHeader, Zone."Location Code", Item."No.", AlternateItemUnitOfMeasure.Code, LibraryRandom.RandIntInRange(10, 20));
        FindWarehousePickLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order",
          Item."No.", WarehouseActivityLine."Activity Type"::Pick);

        // [WHEN] Change bin code on the pick line from "B2" to "B1".
        UpdateBinOnWarehouseActivityLinePage(WarehouseActivityLine, Bin[1].Code);

        // [THEN] As long as bin "B1" have enough quantity to pick, the bin code is changed without confirmation.
        WarehouseActivityLine.Find();
        WarehouseActivityLine.TestField("Bin Code", Bin[1].Code);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerForMessageVerification')]
    [Scope('OnPrem')]
    procedure ChangeBinCodeOnWhsePickWithAlternateUOMRaisesWarningInCaseOfAvailIssue()
    var
        Item: Record Item;
        BaseItemUnitOfMeasure: Record "Item Unit of Measure";
        AlternateItemUnitOfMeasure: Record "Item Unit of Measure";
        Zone: Record Zone;
        Bin: array[2] of Record Bin;
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Qty: Decimal;
        QtyPerBaseUOM: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Item Unit of Measure] [Pick] [Bin Content] [UI]
        // [SCENARIO 264375] When you change bin code on warehouse pick line with alternate unit of measure to a bin, that has insufficient quantity to pick, a confirm with warning of lacking quantity should raise.
        Initialize();

        // [GIVEN] Location set up for directed put-away and pick.
        CreateFullWMSLocationAndFindPickZone(Zone);

        // [GIVEN] Item "I" with base unit of measure "KG" and alternate unit of measure "OZ". 1 "OZ" = 0.03 "KG".
        Qty := LibraryRandom.RandIntInRange(100, 200);
        QtyPerBaseUOM := LibraryRandom.RandIntInRange(1, 99) / 1000;
        CreateItemWithNonBaseUOM(
          Item, BaseItemUnitOfMeasure, AlternateItemUnitOfMeasure, QtyPerBaseUOM);

        // [GIVEN] Pick bin "B1" has 100 "OZ" of the item stored in it, pick bin "B2" has 200 "OZ".
        for i := 1 to ArrayLen(Bin) do begin
            LibraryWarehouse.FindBin(Bin[i], Zone."Location Code", Zone.Code, i);
            UpdateInventoryUsingWarehouseJournal(
              Bin[i], Item, AlternateItemUnitOfMeasure.Code, Qty * i, false, ItemTrackingMode::" ", WorkDate());
        end;

        // [GIVEN] Sales order for 200 "OZ" of item "I".
        // [GIVEN] Warehouse shipment and pick are created for the order.
        CreateSalesOrderAndPick(
          SalesHeader, Zone."Location Code", Item."No.", AlternateItemUnitOfMeasure.Code, Qty * 2);
        FindWarehousePickLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order",
          Item."No.", WarehouseActivityLine."Activity Type"::Pick);

        // [WHEN] Change bin code on the pick line from "B2" to "B1".
        UpdateBinOnWarehouseActivityLinePage(WarehouseActivityLine, Bin[1].Code);

        // [THEN] A confirmation is required to change the bin code. The quantities in the confirm message are shown in "KG".
        Assert.ExpectedMessage(
          StrSubstNo(InsufficientQtyToPickInBinErr, 2 * Qty * QtyPerBaseUOM, Qty * QtyPerBaseUOM),
          LibraryVariableStorage.DequeueText());

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeUOMOnAssemblyHeaderDoesNotConvertOverheadRate()
    var
        Item: Record Item;
        BaseItemUnitOfMeasure: Record "Item Unit of Measure";
        AlternateItemUnitOfMeasure: Record "Item Unit of Measure";
        AssemblyHeader: Record "Assembly Header";
    begin
        // [FEATURE] [Item Unit of Measure] [Assembly Order] [Overhead Rate]
        // [SCENARIO 272590] "Overhead Rate" on assembly order is not recalculated when a user changes "Unit of Measure Code".
        Initialize();

        // [GIVEN] Item "I" with base "PCS" and alternate unit of measure "PALLET".
        CreateItemWithNonBaseUOM(Item, BaseItemUnitOfMeasure, AlternateItemUnitOfMeasure, LibraryRandom.RandIntInRange(10, 20));

        // [GIVEN] Set "I"."Overhead Rate" = 10.
        Item.Validate("Overhead Rate", LibraryRandom.RandDecInRange(10, 20, 2));
        Item.Modify(true);

        // [GIVEN] Assembly order for 10 "PCS" of item "I".
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), Item."No.", '', LibraryRandom.RandInt(10), '');

        // [WHEN] Change "Unit of Measure Code" on the assembly order to "PALLET".
        AssemblyHeader.Validate("Unit of Measure Code", AlternateItemUnitOfMeasure.Code);

        // [THEN] "Overhead Rate" has not been recalculated and remains equal to 10.
        AssemblyHeader.TestField("Overhead Rate", Item."Overhead Rate");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeUOMOnRequisitionLineDoesNotConvertOverheadRate()
    var
        Item: Record Item;
        BaseItemUnitOfMeasure: Record "Item Unit of Measure";
        AlternateItemUnitOfMeasure: Record "Item Unit of Measure";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Item Unit of Measure] [Requisition Line] [Overhead Rate]
        // [SCENARIO 272590] "Overhead Rate" on requisition line is not recalculated when a user changes "Unit of Measure Code".
        Initialize();

        // [GIVEN] Item "I" with base "PCS" and alternate unit of measure "PALLET".
        CreateItemWithNonBaseUOM(Item, BaseItemUnitOfMeasure, AlternateItemUnitOfMeasure, LibraryRandom.RandIntInRange(10, 20));

        // [GIVEN] Set "I"."Overhead Rate" = 10.
        Item.Validate("Overhead Rate", LibraryRandom.RandDecInRange(10, 20, 2));
        Item.Modify(true);

        // [GIVEN] Requisition line for 10 "PCS" of item "I".
        LibraryPlanning.SelectRequisitionWkshName(RequisitionWkshName, RequisitionWkshName."Template Type"::Planning);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", Item."No.");
        RequisitionLine.Validate(Quantity, LibraryRandom.RandInt(10));
        RequisitionLine.Modify(true);

        // [WHEN] Change "Unit of Measure Code" on the requisition line to "PALLET".
        RequisitionLine.Validate("Unit of Measure Code", AlternateItemUnitOfMeasure.Code);

        // [THEN] "Overhead Rate" has not been recalculated and remains equal to 10.
        RequisitionLine.TestField("Overhead Rate", Item."Overhead Rate");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeUOMOnPlanningComponentDoesNotConvertOverheadRate()
    var
        Item: Record Item;
        BaseItemUnitOfMeasure: Record "Item Unit of Measure";
        AlternateItemUnitOfMeasure: Record "Item Unit of Measure";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        PlanningComponent: Record "Planning Component";
        UnitCost: Decimal;
    begin
        // [FEATURE] [Item Unit of Measure] [Planning Component] [Overhead Rate]
        // [SCENARIO 272590] "Overhead Rate" on planning component is not recalculated when a user changes "Unit of Measure Code". However, in order to calculate "Direct Unit Cost", the program multiplies "Overhead Rate" by "Qty. per Unit of Measure".
        Initialize();

        UnitCost := LibraryRandom.RandDecInRange(100, 200, 2);

        // [GIVEN] Item "I" with base "PCS" and alternate unit of measure "PALLET". 1 "PALLET" = 20 "PCS".
        CreateItemWithNonBaseUOM(Item, BaseItemUnitOfMeasure, AlternateItemUnitOfMeasure, LibraryRandom.RandIntInRange(10, 20));
        Item.Validate("Unit Cost", UnitCost);
        Item.Modify(true);

        // [GIVEN] Set "I"."Overhead Rate" = 10.
        Item.Validate("Overhead Rate", LibraryRandom.RandDecInRange(10, 20, 2));
        Item.Modify(true);
        // [GIVEN] Planning component for 10 "PCS" of item "I" and "Unit Cost" = 200.
        LibraryPlanning.SelectRequisitionWkshName(RequisitionWkshName, RequisitionWkshName."Template Type"::Planning);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        LibraryPlanning.CreatePlanningComponent(PlanningComponent, RequisitionLine);
        PlanningComponent.Validate("Item No.", Item."No.");
        PlanningComponent.Validate(Quantity, LibraryRandom.RandInt(10));
        // [WHEN] Change "Unit of Measure Code" on the planning component to "PALLET".
        PlanningComponent.Validate("Unit of Measure Code", AlternateItemUnitOfMeasure.Code);
        // [THEN] "Unit Cost" is recalculated to 200 * 20 = 4000.
        PlanningComponent.TestField("Unit Cost", UnitCost * PlanningComponent."Qty. per Unit of Measure");
        // [THEN] "Overhead Rate" has not been recalculated and remains equal to 10.
        PlanningComponent.TestField("Overhead Rate", Item."Overhead Rate");
        // [THEN] "Direct Unit Cost" is on the planning component is equal to 20 * (200 - 10) = 3800.
        PlanningComponent.TestField("Direct Unit Cost", PlanningComponent."Unit Cost" - PlanningComponent."Overhead Rate" * PlanningComponent."Qty. per Unit of Measure");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OverheadAmountOnValidatingExpectedQtyOnPlanningCompWithOverheadRate()
    var
        Item: Record Item;
        BaseItemUnitOfMeasure: Record "Item Unit of Measure";
        AlternateItemUnitOfMeasure: Record "Item Unit of Measure";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        PlanningComponent: Record "Planning Component";
    begin
        // [FEATURE] [Item Unit of Measure] [Planning Component] [Overhead Rate]
        // [SCENARIO 272590] "Overhead Rate" on planning component is not recalculated when a user changes "Expected Quantity". However, in order to calculate "Overhead Amount" the program multiplies "Overhead Rate" by "Qty. per Unit of Measure".
        Initialize();

        // [GIVEN] Item "I" with base "PCS" and alternate unit of measure "PALLET". 1 "PALLET" = 20 "PCS".
        CreateItemWithNonBaseUOM(Item, BaseItemUnitOfMeasure, AlternateItemUnitOfMeasure, LibraryRandom.RandIntInRange(10, 20));

        // [GIVEN] Set "I"."Overhead Rate" = 10.
        Item.Validate("Overhead Rate", LibraryRandom.RandDecInRange(10, 20, 2));
        Item.Modify(true);
        // [GIVEN] Planning Component for 10 "PCS" of item "I".
        // [GIVEN] "Unit of Measure Code" on the planning component is changed to "PALLET".
        LibraryPlanning.SelectRequisitionWkshName(RequisitionWkshName, RequisitionWkshName."Template Type"::Planning);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        LibraryPlanning.CreatePlanningComponent(PlanningComponent, RequisitionLine);
        PlanningComponent.Validate("Item No.", Item."No.");
        PlanningComponent.Validate(Quantity, LibraryRandom.RandInt(10));
        PlanningComponent.Validate("Unit of Measure Code", AlternateItemUnitOfMeasure.Code);
        // [WHEN] Set "Expected Quantity" on the planning component to 5 "PALLET".
        PlanningComponent.Validate("Expected Quantity", LibraryRandom.RandIntInRange(2, 5));
        // [THEN] "Overhead Rate" has not been recalculated and remains equal to 10.
        PlanningComponent.TestField("Overhead Rate", Item."Overhead Rate");
        // [THEN] "Overhead Amount" on the planning component is equal to 5 * 10 * 20 = 1000.
        PlanningComponent.TestField("Overhead Amount", PlanningComponent."Expected Quantity" * PlanningComponent."Overhead Rate" * PlanningComponent."Qty. per Unit of Measure");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseUoMOnSalesWhenSalesUoMBlank()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Unit of Measure] [Sales] [UT]
        // [SCENARIO 359651] "Base Unit of Measure" on Item is used by default on a new sales line if "Sales Unit of Measure" is blank.
        Initialize();

        LibraryInventory.CreateItem(Item);
        Item.Validate("Sales Unit of Measure", '');
        Item.Modify(true);

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", 0, '', WorkDate());

        SalesLine.TestField("Unit of Measure Code", Item."Base Unit of Measure");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseUoMOnServiceWhenSalesUoMBlank()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Unit of Measure] [Service] [UT]
        // [SCENARIO 359651] "Base Unit of Measure" on Item is used by default on a new service line if "Sales Unit of Measure" is blank.
        Initialize();

        LibraryInventory.CreateItem(Item);
        Item.Validate("Sales Unit of Measure", '');
        Item.Modify(true);

        LibraryService.CreateServiceDocumentWithItemServiceLine(ServiceHeader, ServiceHeader."Document Type"::Order);
        FindServiceLine(ServiceLine, ServiceHeader);

        ServiceLine.Validate("No.", Item."No.");

        ServiceLine.TestField("Unit of Measure Code", Item."Base Unit of Measure");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseUoMOnPurchaseWhenPurchUoMBlank()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Unit of Measure] [Purchase] [UT]
        // [SCENARIO 359651] "Base Unit of Measure" on Item is used by default on a new purchase line if "Purch. Unit of Measure" is blank.
        Initialize();

        LibraryInventory.CreateItem(Item);
        Item.Validate("Purch. Unit of Measure", '');
        Item.Modify(true);

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', Item."No.", 0, '', WorkDate());

        PurchaseLine.TestField("Unit of Measure Code", Item."Base Unit of Measure");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseUoMOnItemJnlLineWhenUoMBlank()
    var
        Item: Record Item;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Unit of Measure] [Item Journal Line] [UT]
        // [SCENARIO 359651] "Base Unit of Measure" on Item is used by default on a new item journal line for purchase if "Purch. Unit of Measure" is blank.
        Initialize();

        LibraryInventory.CreateItem(Item);
        Item.Validate("Purch. Unit of Measure", '');
        Item.Modify(true);

        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase, Item."No.", 0);

        ItemJournalLine.TestField("Unit of Measure Code", Item."Base Unit of Measure");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotPostSalesForItemWithBlankUoM()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Unit of Measure] [Sales]
        // [SCENARIO 359651] Cannot post item-type sales line with blank "Unit of Measure Code".
        Initialize();

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '',
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10), '', WorkDate());
        SalesLine.Validate("Unit of Measure Code", '');
        SalesLine.Modify(true);

        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, false);

        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(SalesLine.FieldCaption("Unit of Measure Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotPostServiceForItemWithBlankUoM()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Unit of Measure] [Service]
        // [SCENARIO 359651] Cannot post item-type service line with blank "Unit of Measure Code".
        Initialize();

        LibraryService.CreateServiceDocumentWithItemServiceLine(ServiceHeader, ServiceHeader."Document Type"::Order);
        FindServiceLine(ServiceLine, ServiceHeader);
        ServiceLine.Validate("Unit of Measure Code", '');
        ServiceLine.Modify(true);

        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(ServiceLine.FieldCaption("Unit of Measure Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotPostPurchaseForItemWithBlankUoM()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Unit of Measure] [Purchase]
        // [SCENARIO 359651] Cannot post item-type purchase line with blank "Unit of Measure Code".
        Initialize();

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '',
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10), '', WorkDate());
        PurchaseLine.Validate("Unit of Measure Code", '');
        PurchaseLine.Modify(true);

        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(PurchaseLine.FieldCaption("Unit of Measure Code"));
    end;

    [Test]
    [HandlerFunctions('ProductionJournalUnitOfMeasureCodeErrorHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure S463638_CannotPostProductionJournalForItemWithBlankUoM()
    var
        Item: Record Item;
        ReleasedProductionOrder: TestPage "Released Production Order";
    begin
        // [FEATURE] [Unit of Measure] [Released Production Order] [Production Journal]
        // [SCENARIO 463638] Cannot post Production Journal line with blank "Unit of Measure Code".
        Initialize();

        // [GIVEN] Create Item "I".
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Released Production Order with Item "I" in line, without "Unit of Measure Code".
        ReleasedProductionOrder.OpenNew();
        ReleasedProductionOrder."Location Code".SetValue(LocationWhite.Code);
        ReleasedProductionOrder.ProdOrderLines."Item No.".SetValue(Item."No.");
        ReleasedProductionOrder.ProdOrderLines.Quantity.SetValue(2);
        ReleasedProductionOrder.ProdOrderLines."Unit of Measure Code".SetValue('');

        // [WHEN] Open Production Journal.
        // [THEN] Post Production Journal raises error that "Unit of Measure Code" cannot be empty.
        ReleasedProductionOrder.ProdOrderLines.ProductionJournal.Invoke(); // Uses ProductionJournalUnitOfMeasureCodeErrorHandler.
    end;

    [Test]
    procedure VerifyRoundingOnWarehousePickForAdditionalUoM()
    var
        Item: Record Item;
        Bin: Record Bin;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        SalesHeader: Record "Sales Header";
        WarehouseActivityLineTake: Record "Warehouse Activity Line";
        WarehouseActivityLinePlace: Record "Warehouse Activity Line";
        BaseUOMCode, AltUOMCode : Code[10];
    begin
        // [SCENARIO 466774] Verify Rounding On Warehouse Pick For Additional UoM and defined Rounding Precision
        Initialize();

        // [GIVEN] Create Location Setup with Warehouse Employee on default White Location
        CreateLocationSetup();

        // [GIVEN] Find Bin
        FindBin(Bin, LocationWhite.Code);

        // [GIVEN] Create Item with additional UoM
        CreateItemWithAdditionalUOMs(Item, BaseUOMCode, AltUOMCode, 12);

        // [GIVEN] Register Warehouse Journal
        CreateAndRegisterWarehouseJournalLine(Bin, Item, 1000, Item."Base Unit of Measure");

        // [GIVEN] Calculate Warehouse Adjustment and Post Item Journal Line
        CalculateWarehouseAdjustmentAndPostItemJournalLine(Item);

        // [GIVEN] Create Sales Order
        CreateAndReleaseSalesOrderAtLocationWithAdditionalUoM(SalesHeader, Item."No.", LocationWhite.Code, 4, AltUOMCode);

        // [GIVEN] Create Warehouse Shipment and Pick from Sales Order
        CreateWarehouseShipmentAndPickFromSalesOrder(WarehouseShipmentHeader, SalesHeader);

        // [GIVEN] Find Warehouse Activity Lines
        FindWarehousePickTypeLine(
          WarehouseActivityLineTake, WarehouseActivityLineTake."Source Document"::"Sales Order",
          Item."No.", WarehouseActivityLineTake."Activity Type"::Pick, WarehouseActivityLineTake."Action Type"::Take);
        FindWarehousePickTypeLine(
          WarehouseActivityLinePlace, WarehouseActivityLinePlace."Source Document"::"Sales Order",
          Item."No.", WarehouseActivityLinePlace."Activity Type"::Pick, WarehouseActivityLinePlace."Action Type"::Place);

        // [WHEN] Update "Qty. to Handle"
        UpdateQtyToHandleOnWarehouseActivityLinesPair(WarehouseActivityLineTake, WarehouseActivityLinePlace, 35, 35 / 12);

        // [THEN] Verify result
        Assert.IsTrue(WarehouseActivityLineTake."Qty. to Handle (Base)" = 35, QtyToHandleBaseErr);
        Assert.IsTrue(WarehouseActivityLinePlace."Qty. to Handle (Base)" = 35, QtyToHandleBaseErr);
    end;

    [Test]
    procedure QtyPerUnitofMeasureFieldInBinContentPageDefaultsTo1ForAnItemHasDifferentUOMWithQuantityForThisWhenManuallyAddingLine()
    var
        Item: Record Item;
        BaseUnitOfMeasure: Record "Unit of Measure";
        UnitOfMeasure: Record "Unit of Measure";
        ItemCard: TestPage "Item Card";
        BinContentPage: TestPage "Bin Content";
        QtyOfUOMPerUOM: Decimal;
    begin
        // [SCENARIO 575737] 'Qty. Per Unit of Measure' field in the Bin Content Page defaults to 1 for an Item that has different UOM with quantity for this field greater than 1, when manually adding a Bin Content Line
        Initialize();

        //[GIVEN] Create Item with Multiple Unit of Measure
        QtyOfUOMPerUOM := 2 + LibraryRandom.RandInt(3);
        CreateItemWithMultipleUOM(Item, BaseUnitOfMeasure, UnitOfMeasure, QtyOfUOMPerUOM);

        //[GIVEN] Update sales unit of Measure And Purch. unit of Measure field
        Item."Sales Unit of Measure" := UnitOfMeasure.Code;
        Item."Purch. Unit of Measure" := UnitOfMeasure.Code;
        Item.Modify();

        //[WHEN] Insert New line in Bin Content
        ItemCard.OpenView();
        ItemCard.GoToRecord(Item);
        BinContentPage.Trap();
        ItemCard."&Bin Contents".Invoke();
        BinContentPage."Location Code".SetValue('Silver');
        BinContentPage."Bin Code".SetValue('S-01-0001');
        BinContentPage."Unit of Measure Code".SetValue(UnitOfMeasure.Code);
        BinContentPage.New();

        //[THEN] Verify 'Qty. per Unit of Measure' field have xRec value in new line
    end;

    [Test]
    procedure WarningMessageWhenMaxQuantityExceedsForQtyAndCubage()
    var
        Bin, Bin2 : Record Bin;
        BinContent: Record "Bin Content";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Location: Record Location;
        UnitOfMeasure: array[3] of Record "Unit of Measure";
        Zone: array[3] of Record Zone;
        i: Integer;
    begin
        // [SCENARIO 571432] When calculating Bin Replenishment in a movement worksheet wrong capacity warnings appear due to wrong calculation.
        Initialize();

        // [GIVEN] Create 3 Units Of Measure.
        for i := 1 to 3 do
            LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure[i]);//PCS,PACK,BOX

        // [GIVEN] Create Full Warehouse Location and Validate Bin Capacity Policy.
        LibraryWarehouse.CreateFullWMSLocation(Location, LibraryRandom.RandInt(2));
        Location.Validate("Bin Capacity Policy", Location."Bin Capacity Policy"::"Allow More Than Max. Capacity");
        Location.Validate("Always Create Put-away Line", true);
        Location.Modify(true);

        // [GIVEN] Create 2 Zone for Pick And PutAway
        LibraryWarehouse.CreateZone(Zone[1], '', Location.Code, LibraryWarehouse.SelectBinType(false, false, false, true), '', '', 0, false);
        LibraryWarehouse.CreateZone(Zone[2], '', Location.Code, LibraryWarehouse.SelectBinType(false, false, true, false), '', '', 0, false);

        // [GIVEN] Create Bin For Zone Pick
        FindZone(Zone[3], Location.Code, LibraryWarehouse.SelectBinType(false, false, false, true));
        LibraryWarehouse.CreateBin(Bin, Zone[3]."Location Code", LibraryUtility.GenerateGUID(), Zone[3].Code, Zone[3]."Bin Type Code");
        Bin.Validate("Maximum Cubage", LibraryRandom.RandIntInRange(6250000, 7250000));
        Bin.Validate("Maximum Weight", LibraryRandom.RandIntInRange(150, 750));
        Bin.Modify(true);

        // [GIVEN] Create Bin For Zone PutAway
        Zone[3].Reset();
        FindZone(Zone[3], Location.Code, LibraryWarehouse.SelectBinType(false, false, true, false));
        LibraryWarehouse.CreateBin(Bin2, Zone[3]."Location Code", LibraryUtility.GenerateGUID(), Zone[3].Code, Zone[3]."Bin Type Code");
        Bin2.Validate("Maximum Weight", LibraryRandom.RandIntInRange(1000, 2000));
        Bin2.Modify(true);

        // [GIVEN] Create an Item and Validate Base Unit of Measure.
        CreateItem(Item, '');
        Item.Validate("Base Unit of Measure", UnitOfMeasure[1].Code);
        Item.Modify(true);

        // [GIVEN] Create 3 Item Unit Of Measure.
        ItemUnitOfMeasure.SetRange("Item No.", Item."No.");
        ItemUnitOfMeasure.FindFirst();
        UpdateItemUnitOfMeasure(ItemUnitOfMeasure, 5, 5, 5);
        ItemUnitOfMeasure.Reset();
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure[2].Code, 10);
        UpdateItemUnitOfMeasure(ItemUnitOfMeasure, 50, 50, 50);
        ItemUnitOfMeasure.Reset();
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure[3].Code, 100);
        UpdateItemUnitOfMeasure(ItemUnitOfMeasure, 500, 500, 500);

        // [GIVEN] Create two Bin Content for Item with MaxQty And MinQty.
        CreateBinContent(BinContent, Bin, Item."No.", UnitOfMeasure[2].Code, 24, 50, true, false);
        CreateBinContent(BinContent, Bin2, Item."No.", UnitOfMeasure[3].Code, 0, 0, false, true);

        // [GIVEN] Create 2 Warehouse Item Journal Lines.
        CreateWarehouseJournalBatch(WarehouseJournalBatch, Location.Code);
        CreateWarehouseItemJournalLine(Location.Code, Item."No.", WorkDate(), Bin, 5, UnitOfMeasure[2].Code, WarehouseJournalBatch);
        CreateWarehouseItemJournalLine(Location.Code, Item."No.", WorkDate(), Bin2, 10, UnitOfMeasure[3].Code, WarehouseJournalBatch);

        // [WHEN] Register Whse. Journal Line ,Calculate Warehouse Adjustment and Post Item Journal Lines.
        LibraryWarehouse.RegisterWhseJournalLine(WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Location.Code, true);
        CalculateWhseAdjustment(ItemJournalBatch, Item);
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, Item."No.");
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [WHEN] Run Calculate Bin Replenishment Report.
        RunCalculateBinReplenishmentReport(Location.Code, Item."No.");

        // [THEN] Check Bin Content have Updated Quantity and Calculate Bin Replenishment without Confirmation Message for Quantity and Cubage.
        CheckBinContent(BinContent, Location.Code, Item."No.");//Assert 
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckTheSystemDoesNotDisplayWarningWhenCubageOrWeightInformationIsMissingForItem()
    var
        Item: Record Item;
        Bin: Record Bin;
        SecondBin: Record Bin;
        BinContent: Record "Bin Content";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Location: Record Location;
        UnitOfMeasure: array[3] of Record "Unit of Measure";
        Zone: array[3] of Record Zone;
        i: Integer;
    begin
        // [SCENARIO 591790] Check that the system does not display a warning when cubage or weight information is missing for the item
        Initialize();

        // [GIVEN] Create 3 Units Of Measure.
        for i := 1 to 3 do
            LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure[i]);

        // [GIVEN] Create Warehouse Location and Validate Bin Capacity Policy.
        LibraryWarehouse.CreateFullWMSLocation(Location, LibraryRandom.RandInt(2));
        Location.Validate("Bin Capacity Policy", Location."Bin Capacity Policy"::"Allow More Than Max. Capacity");
        Location.Validate("Always Create Put-away Line", true);
        Location.Modify(true);

        // [GIVEN] Create 2 Zone
        LibraryWarehouse.CreateZone(Zone[1], '', Location.Code, LibraryWarehouse.SelectBinType(false, false, false, true), '', '', 0, false);
        LibraryWarehouse.CreateZone(Zone[2], '', Location.Code, LibraryWarehouse.SelectBinType(false, false, true, false), '', '', 0, false);
        FindZone(Zone[3], Location.Code, LibraryWarehouse.SelectBinType(false, false, false, true));
        LibraryWarehouse.CreateBin(Bin, Zone[3]."Location Code", LibraryUtility.GenerateGUID(), Zone[3].Code, Zone[3]."Bin Type Code");
        Bin.Validate("Maximum Cubage", LibraryRandom.RandIntInRange(6250000, 7250000));
        Bin.Validate("Maximum Weight", LibraryRandom.RandIntInRange(150, 750));
        Bin.Modify(true);

        // [GIVEN] Create Bin For Zone PutAway
        Zone[3].Reset();
        FindZone(Zone[3], Location.Code, LibraryWarehouse.SelectBinType(false, false, true, false));
        LibraryWarehouse.CreateBin(SecondBin, Zone[3]."Location Code", LibraryUtility.GenerateGUID(), Zone[3].Code, Zone[3]."Bin Type Code");
        SecondBin.Validate("Maximum Weight", LibraryRandom.RandIntInRange(1000, 2000));
        SecondBin.Modify(true);

        // [GIVEN] Create an Item and Validate Base Unit of Measure.
        CreateItem(Item, '');
        Item.Validate("Base Unit of Measure", UnitOfMeasure[1].Code);
        Item.Modify(true);

        // [GIVEN] Create 3 Item Unit Of Measure.
        ItemUnitOfMeasure.SetRange("Item No.", Item."No.");
        ItemUnitOfMeasure.FindFirst();
        UpdateItemUnitOfMeasure(ItemUnitOfMeasure, 5, 5, 5);
        ItemUnitOfMeasure.Reset();
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure[2].Code, 10);
        UpdateItemUnitOfMeasure(ItemUnitOfMeasure, 50, 50, 50);
        ItemUnitOfMeasure.Reset();
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure[3].Code, 100);
        UpdateItemUnitOfMeasure(ItemUnitOfMeasure, 500, 500, 500);

        // [GIVEN] Create Bin Content for Item with MaxQty And MinQty.
        CreateBinContent(BinContent, Bin, Item."No.", UnitOfMeasure[2].Code, 24, 50, true, false);

        // [GIVEN] Create Warehouse Item Journal Line and Register
        CreateWarehouseJournalBatch(WarehouseJournalBatch, Location.Code);
        CreateWarehouseItemJournalLine(Location.Code, Item."No.", WorkDate(), Bin, 5, UnitOfMeasure[2].Code, WarehouseJournalBatch);
        LibraryWarehouse.RegisterWhseJournalLine(WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Location.Code, true);

        // [When] Create Bin Content for Item with MaxQty And MinQty.
        CreateBinContent(BinContent, SecondBin, Item."No.", UnitOfMeasure[3].Code, 1, 10, false, true);

        // [THEN] Check that warning message not appears when trying to set Max Qty for Bin Content.
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Warehouse UOM");
        LibraryVariableStorage.Clear();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Warehouse UOM");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        CreateLocationSetup();
        NoSeriesSetup();
        LibraryInventory.ItemJournalSetup(ItemJournalTemplate, ItemJournalBatch);
        OutputJournalSetup();
        CreateItemTrackingCode(ItemTrackingCode, false, true, false, true);  // Lot Item Tracking.
        CreateItemTrackingCode(ItemTrackingCode2, false, true, true, true);  // Lot With Strict Expiration Posting Item Tracking.
        CreateItemTrackingCode(ItemTrackingCode3, true, true, false, true);  // Both Lot and Serial Item Tracking.
        CreateItemTrackingCode(ItemTrackingCode4, true, false, false, false);  // Serial Item Tracking.
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Warehouse UOM");
    end;

    local procedure NoSeriesSetup()
    var
        WarehouseSetup: Record "Warehouse Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);
        WarehouseSetup.Validate(
          "Receipt Posting Policy", WarehouseSetup."Receipt Posting Policy"::"Stop and show the first posting error");
        WarehouseSetup.Modify(true);

        SalesSetup.Get();
        SalesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Modify(true);

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure OutputJournalSetup()
    begin
        Clear(OutputItemJournalTemplate);
        OutputItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(OutputItemJournalTemplate, OutputItemJournalTemplate.Type::Output);
        OutputItemJournalTemplate.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        OutputItemJournalTemplate.Modify(true);

        Clear(OutputItemJournalBatch);
        OutputItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(
          OutputItemJournalBatch, OutputItemJournalTemplate.Type, OutputItemJournalTemplate.Name);
        OutputItemJournalBatch.Modify(true);
    end;

    local procedure CreateLocationSetup()
    begin
        WarehouseEmployee.DeleteAll(true);
        CreateFullWarehouseSetup(LocationWhite);  // Location: White.
        LocationWhite.Validate("Bin Capacity Policy", LocationWhite."Bin Capacity Policy"::"Prohibit More Than Max. Cap.");
        LocationWhite.Modify(true);
        CreateFullWarehouseSetup(LocationWhite2);  // New White Location is required for Test with multiple UOM.
        CreateFullWarehouseSetup(LocationWhite3);  // New White Location is required for Test with multiple UOM.
        LibraryWarehouse.CreateLocationWMS(LocationSilver, true, true, true, false, false);
        LibraryWarehouse.CreateLocationWMS(LocationYellow, false, true, true, true, true);
        LibraryWarehouse.CreateLocationWMS(LocationGreen, false, true, true, true, true);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue);
        LibraryWarehouse.CreateInTransitLocation(LocationIntransit);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite.Code, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite2.Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite3.Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationSilver.Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationYellow.Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationGreen.Code, false);
    end;

    [Normal]
    local procedure CreateFullWarehouseSetup(var Location: Record Location)
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);  // Value used for number of bin per zone.
    end;

    local procedure CreateFullWarehouseSetupWithNumberOfBinsAndSetRanking(var Location: Record Location; NumberOfBins: Integer)
    var
        Zone: Record Zone;
        WarehouseEmployeeLoc: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, NumberOfBins);
        WarehouseEmployeeLoc.SetRange("User ID", UserId);
        WarehouseEmployeeLoc.DeleteAll(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployeeLoc, Location.Code, true);
        LibraryInventory.UpdateInventoryPostingSetup(Location);
        Zone.SetRange("Location Code", Location.Code);
        Zone.FindSet();
        repeat
            SetBinRankingForFirstBinAtZone(Zone);
        until Zone.Next() = 0;
    end;

    local procedure CreateFullWMSLocationAndFindPickZone(var Zone: Record Zone)
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        FindZone(Zone, Location.Code, LibraryWarehouse.SelectBinType(false, false, true, true));
    end;

    local procedure SetBinRankingForFirstBinAtZone(Zone: Record Zone)
    var
        Bin: Record Bin;
    begin
        Bin.SetRange("Location Code", Zone."Location Code");
        Bin.SetRange("Zone Code", Zone.Code);
        Bin.FindFirst();
        Bin.Validate("Bin Ranking", 100);
        Bin.Modify(true);
    end;

    local procedure CreateAdditionalItemUOM(ItemNo: Code[20]; QtyPerUnitOfMeasure: Decimal)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        UnitOfMeasure.SetFilter(Code, GetItemUOMCodeFilter(ItemNo));
        UnitOfMeasure.FindFirst();
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, ItemNo, UnitOfMeasure.Code, QtyPerUnitOfMeasure);
    end;

    local procedure PrepareDataForWarehouse(var TempWarehouseEntry: Record "Warehouse Entry" temporary; Item: Record Item; NumberOfBins: Integer; UseLots: Boolean; NumberOfEqualLots: Integer)
    var
        Bin: Record Bin;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Counter: Integer;
        UseBaseUOM: Boolean;
    begin
        ItemUnitOfMeasure.SetCurrentKey("Item No.", "Qty. per Unit of Measure");
        ItemUnitOfMeasure.SetRange("Item No.", Item."No.");
        ItemUnitOfMeasure.SetFilter(Code, '<>' + Item."Base Unit of Measure");
        ItemUnitOfMeasure.Ascending(false);
        ItemUnitOfMeasure.FindSet();
        if UseLots then
            TempWarehouseEntry."Lot No." := LibraryUtility.GenerateGUID();
        for Counter := 1 to NumberOfBins do begin
            TempWarehouseEntry."Entry No." += 1;
            TempWarehouseEntry."Line No." += 10000;
            TempWarehouseEntry.Dedicated := true;
            // "New Line" flag
            TempWarehouseEntry."Location Code" := LocationWhite.Code;
            TempWarehouseEntry."Item No." := Item."No.";

            if UseBaseUOM then begin
                TempWarehouseEntry."Unit of Measure Code" := Item."Base Unit of Measure";
                TempWarehouseEntry."Qty. per Unit of Measure" := 1;
            end else begin
                TempWarehouseEntry."Unit of Measure Code" := ItemUnitOfMeasure.Code;
                TempWarehouseEntry."Qty. per Unit of Measure" := ItemUnitOfMeasure."Qty. per Unit of Measure";
            end;
            UseBaseUOM := ItemUnitOfMeasure.Next() = 0;

            TempWarehouseEntry.Validate(Quantity, 10 * LibraryRandom.RandIntInRange(1, 10));
            if UseLots and (NumberOfEqualLots <= 0) then
                TempWarehouseEntry."Lot No." := LibraryUtility.GenerateGUID();
            FindNextBin(TempWarehouseEntry."Bin Code", Bin, LocationWhite.Code, false, true, true);
            // Find PICK Bin.
            TempWarehouseEntry.Validate("Bin Code", Bin.Code);
            TempWarehouseEntry.Insert();
            NumberOfEqualLots -= 1;
        end;
    end;

    local procedure CreatePurchaseOrderAndPutAwayWithData(var TempWarehouseEntry: Record "Warehouse Entry" temporary)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        TempWarehouseEntry.FindSet();
        repeat
            CreatePurchaseLineWithUOMAndLotNo(
              PurchaseLine, PurchaseHeader, TempWarehouseEntry."Item No.", TempWarehouseEntry."Unit of Measure Code", TempWarehouseEntry."Location Code",
              TempWarehouseEntry.Quantity, TempWarehouseEntry."Lot No.");
        until TempWarehouseEntry.Next() = 0;
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader);
        PlaceToBinsAndRegisterWarehouseActivity(
          TempWarehouseEntry, WarehouseActivityLine."Source Document"::"Purchase Order",
          PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");
    end;

    local procedure ReorganizeDataForWarehouse(var TempWarehouseEntry: Record "Warehouse Entry" temporary)
    var
        QtyToShipBase: Decimal;
        FirstLotNo: Code[50];
    begin
        TempWarehouseEntry.Reset();
        TempWarehouseEntry.FindFirst();
        // First line
        FirstLotNo := TempWarehouseEntry."Lot No.";
        QtyToShipBase := TempWarehouseEntry."Qty. per Unit of Measure" - 1;
        SetQtyAndLotValues(TempWarehouseEntry, TempWarehouseEntry.Quantity - 1, '');
        TempWarehouseEntry.Modify();
        TempWarehouseEntry.Next();
        // Second line
        SetQtyAndLotValues(
          TempWarehouseEntry, TempWarehouseEntry.Quantity + Round(QtyToShipBase / TempWarehouseEntry."Qty. per Unit of Measure", 0.00001), '');
        TempWarehouseEntry.Modify();
        TempWarehouseEntry.FindLast();
        // Last line
        TempWarehouseEntry."Entry No." += 1;
        TempWarehouseEntry.Dedicated := false;
        // "New Line" flag
        SetQtyAndLotValues(TempWarehouseEntry, Round(1 / TempWarehouseEntry."Qty. per Unit of Measure", 0.00001), FirstLotNo);
        TempWarehouseEntry.Insert();
    end;

    local procedure CreateAndReleaseTransferOrderWithData(var TransferHeader: Record "Transfer Header"; var TempWarehouseEntry: Record "Warehouse Entry" temporary; ToLocationCode: Code[10]; LotsAssignment: Option Partial,Complete)
    var
        TransferLine: Record "Transfer Line";
        PartQuantity: Decimal;
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, LocationWhite.Code, ToLocationCode, LocationIntransit.Code);
        TempWarehouseEntry.FindSet();
        repeat
            ProcessTransferLineWithData(TempWarehouseEntry, TransferHeader, TransferLine);
            case LotsAssignment of
                LotsAssignment::Partial:
                    begin
                        PartQuantity := LibraryRandom.RandIntInRange(1, TempWarehouseEntry.Quantity * TransferLine."Qty. per Unit of Measure");
                        LibraryVariableStorage.Enqueue(ItemTrackingLineHandling::Create);
                        LibraryVariableStorage.Enqueue(TempWarehouseEntry."Lot No.");
                        LibraryVariableStorage.Enqueue(PartQuantity);
                        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);

                        LibraryVariableStorage.Enqueue(ItemTrackingLineHandling::"Use Existing");
                        LibraryVariableStorage.Enqueue(TempWarehouseEntry."Lot No.");
                        LibraryVariableStorage.Enqueue(TempWarehouseEntry.Quantity * TransferLine."Qty. per Unit of Measure");
                        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);
                    end;
                LotsAssignment::Complete:
                    begin
                        LibraryVariableStorage.Enqueue(ItemTrackingLineHandling::Create);
                        LibraryVariableStorage.Enqueue(TempWarehouseEntry."Lot No.");
                        LibraryVariableStorage.Enqueue(TempWarehouseEntry.Quantity * TransferLine."Qty. per Unit of Measure");
                        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);
                    end;
            end;
        until TempWarehouseEntry.Next() = 0;
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
    end;

    local procedure AddBinsToLocation(LocationCode: Code[10]; Receive: Boolean; Ship: Boolean; PutAway: Boolean; Pick: Boolean; IsCrossDock: Boolean; NumberOfBins: Integer)
    var
        Bin: Record Bin;
    begin
        FindBin(Bin, LocationCode, Receive, PutAway, Pick);
        LibraryWarehouse.CreateNumberOfBins(
          LocationCode, LibraryWarehouse.GetZoneForBin(LocationCode, Bin.Code),
          LibraryWarehouse.SelectBinType(Receive, Ship, PutAway, Pick), NumberOfBins, IsCrossDock);
    end;

    local procedure ProcessTransferLineWithData(var TempWarehouseEntry: Record "Warehouse Entry" temporary; TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line")
    begin
        if TempWarehouseEntry.Dedicated then begin
            // "New Line" flag
            LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, TempWarehouseEntry."Item No.", TempWarehouseEntry.Quantity);
            TransferLine.Validate("Unit of Measure Code", TempWarehouseEntry."Unit of Measure Code");
        end else
            TransferLine.Validate(Quantity, TransferLine.Quantity + TempWarehouseEntry.Quantity);
        TransferLine.Modify();
    end;

    local procedure GetTotalBaseQtyOfData(var TempWarehouseEntry: Record "Warehouse Entry" temporary; var BinCodeFilter: Text) Result: Decimal
    begin
        BinCodeFilter := '<>''''';
        TempWarehouseEntry.FindSet();
        repeat
            BinCodeFilter += '&<>' + TempWarehouseEntry."Bin Code";
            Result += TempWarehouseEntry.Quantity * TempWarehouseEntry."Qty. per Unit of Measure";
        until TempWarehouseEntry.Next() = 0;
    end;

    local procedure GetTotalBaseQty(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; BinCodeFilter: Text) Result: Decimal
    begin
        RegisteredWhseActivityLine.SetRange("Action Type", RegisteredWhseActivityLine."Action Type"::Place);
        RegisteredWhseActivityLine.SetFilter("Bin Code", BinCodeFilter);
        RegisteredWhseActivityLine.FindSet();
        repeat
            Result += RegisteredWhseActivityLine.Quantity * RegisteredWhseActivityLine."Qty. per Unit of Measure";
        until RegisteredWhseActivityLine.Next() = 0;
    end;

    local procedure GetItemUOMCodeFilter(ItemNo: Code[20]) Result: Text
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        Result := '<>''''';
        ItemUnitOfMeasure.SetRange("Item No.", ItemNo);
        ItemUnitOfMeasure.FindSet();
        repeat
            Result += '&<>' + ItemUnitOfMeasure.Code;
        until ItemUnitOfMeasure.Next() = 0;
    end;

    local procedure SetQtyAndLotValues(var TempWarehouseEntry: Record "Warehouse Entry" temporary; Qty: Decimal; LotNo: Code[50])
    begin
        TempWarehouseEntry.Validate(Quantity, Qty);
        if LotNo <> '' then
            TempWarehouseEntry.Validate("Lot No.", LotNo);
    end;

    local procedure CalculateBinReplenishmentOnMovementWorksheet(ItemNo: Code[20]; LocationCode: Code[10])
    var
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        BinContent: Record "Bin Content";
    begin
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Movement);
        LibraryWarehouse.SelectWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, LocationWhite.Code);
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.FindFirst();
        LibraryWarehouse.CalculateBinReplenishment(BinContent, WhseWorksheetName, LocationCode, true, false, false);
    end;

    local procedure CopyReservationEntry(var ReservationEntry2: Record "Reservation Entry"; ItemNo: Code[20])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.FindSet();
        repeat
            ReservationEntry2.Init();
            ReservationEntry2 := ReservationEntry;
            ReservationEntry2.Insert();
        until ReservationEntry.Next() = 0;
    end;

    local procedure CreateAndCertifyProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; QtyPer: Decimal; Type: Enum "Production BOM Line Type")
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UnitOfMeasureCode);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', Type, ItemNo, QtyPer);  // Value required for test.
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateAndCertifyProductionBOMWithUOM(var ItemUnitOfMeasure: Record "Item Unit of Measure"; var ParentItem: Record Item; ComponentItemNo: Code[20]; var QtyPer: Decimal; Type: Enum "Production BOM Line Type")
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        QtyPer := 2;
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, ParentItem."No.", 2);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ComponentItemNo, ItemUnitOfMeasure.Code, QtyPer, Type);
        UpdateProductionBomAndRoutingOnItem(ParentItem, ProductionBOMHeader."No.", '');
    end;

    local procedure CreateAndCertifiyRouting(var RoutingHeader: Record "Routing Header")
    var
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
    begin
        WorkCenter.FindFirst();
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', Format(LibraryRandom.RandInt(10)), RoutingLine.Type::"Work Center", WorkCenter."No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateAndPostItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20];
                                                                                                                 Quantity: Decimal;
                                                                                                                 LocationCode: Code[10];
                                                                                                                 BinCode: Code[20];
                                                                                                                 Tracking: Boolean)
    begin
        ItemJournalBatch.Validate("No. Series", '');
        ItemJournalBatch.Modify(true);
        LibraryInventory.CreateItemJournalLine(
ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
        if Tracking then
            ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostOutputJournalLineWithItemTracking(var ItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record "Prod. Order Line"; OutputQuantity: Decimal)
    begin
        LibraryInventory.ClearItemJournal(OutputItemJournalTemplate, OutputItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::Output, ProdOrderLine."Item No.", 0);  // Use 0 for Quantity.
        ItemJournalLine.Validate("Source No.", ProdOrderLine."Item No.");
        ItemJournalLine.Validate("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.Validate("Order No.", ProdOrderLine."Prod. Order No.");
        ItemJournalLine.Validate("Order Line No.", ProdOrderLine."Line No.");
        ItemJournalLine.Validate("Location Code", ProdOrderLine."Location Code");
        ItemJournalLine.Validate("Bin Code", ProdOrderLine."Bin Code");
        ItemJournalLine.Validate("Output Quantity", OutputQuantity);
        ItemJournalLine.Modify(true);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Serial No.");  // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
    end;

    local procedure CreateReleasedPurchaseOrder(var PurchaseHeader: Record "Purchase Header")
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Quantity: Decimal;
    begin
        CreateItem(Item, ItemTrackingCode.Code);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandDec(10, 5) + 1);  // Decimal value required for multiple UOM with different conversion rate.
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndReleasePurchaseOrderWithMultipleUOM(
          PurchaseHeader, Item."No.", ItemUnitOfMeasure.Code, '', LocationWhite.Code, Quantity, true);  // Use TRUE for with Tracking.
    end;

    local procedure CreateWarehouseShipmentAndPickForItemAtLocationFromDifferentBins(var SalesHeader: Record "Sales Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; LocationCode: Code[10]; ItemNo: Code[20]; NoOfPurchLines: Integer; PurchItemInLineBaseQty: Decimal; SalesQtyInSalesUOM: array[2] of Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreateAndReleasePurchaseOrderAtLocationWithQtyOfLinesForTheSameItem(
          PurchaseHeader, LocationCode, ItemNo, PurchItemInLineBaseQty, NoOfPurchLines);
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader);
        PlacePutawayToPickZoneDifferentBins(PurchaseHeader."No.");
        CreateAndReleaseSalesOrderAtLocationWithTwoLinesOfSingleItem(SalesHeader, ItemNo, LocationCode, SalesQtyInSalesUOM);
        CreateWarehouseShipmentAndPickFromSalesOrder(WarehouseShipmentHeader, SalesHeader);
    end;

    local procedure CreateWarehouseShipmentAndPickFromSalesOrder(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SalesHeader: Record "Sales Header")
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
    end;

    local procedure CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader: Record "Purchase Header")
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWarehouseReceiptLine(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        PostWarehouseReceipt(WarehouseReceiptLine."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyHandledInPutAwayWithBreakbulkAndItemTracking()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        BoxUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        ReservationEntry: Record "Reservation Entry";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        BoxesToPurchase: Decimal;
        QtyPerBox: Decimal;
        BoxesToPutAway: Decimal;
    begin
        // Created for fix of bug 446567 - Register put-away registers wrong quantity
        // Put-away of a tracked item with breakbulk from large to small unit of measure must register correct Qty handled in Item Tracking Line
        Initialize();
        BoxesToPurchase := LibraryRandom.RandIntInRange(10, 20);
        QtyPerBox := LibraryRandom.RandIntInRange(5, 10);
        BoxesToPutAway := LibraryRandom.RandIntInRange(1, 4);

        // [GIVEN] Full WMS location with Allow Breakbulk = TRUE.
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        Location.Validate("Allow Breakbulk", true);
        Location.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Item with item tracking and Base Unit of Measure = "PCS" and alternate Unit of Measure = "BOX"
        LibraryInventory.CreateItem(Item);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", true);
        ItemTrackingCode.Modify();
        CreateItemUnitOfMeasure(BoxUnitOfMeasure, Item."No.", QtyPerBox);

        // [GIVEN] Put-away Unit of Measure Code in the item is base unit
        UpdateItemUOM(Item, BoxUnitOfMeasure.Code, '', Item."Base Unit of Measure");
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify();

        // [GIVEN] A purchase order for PurchQty of the item in "BOX" UOM
        CreateAndReleasePurchaseOrder(PurchaseHeader, Location.Code, Item."No.", BoxesToPurchase);

        // [GIVEN] Posted receipt for full quantity with lot item tracking
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWarehouseReceiptLine(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        LibraryItemTracking.CreateWhseReceiptItemTracking(ReservationEntry, WarehouseReceiptLine, '', LibraryRandom.RandText(5), QtyPerBox * BoxesToPurchase);
        PostWarehouseReceipt(WarehouseReceiptLine."No.");

        // [WHEN] All generated warehouse activities are registered including breakbulk and actual Put-away activities
        RegisterAllWarehouseActivies(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          BoxesToPutAway * QtyPerBox);

        // [THEN] The Item Tracking Line has registered the correct "Qty Handled (Base)"
        // Only the put-away activities should contribute to the "Qty Handled" - not breakbulk activities
        FilterWhseItemTrackingLineByWhseReceipt(WarehouseReceiptLine, WhseItemTrackingLine);
        WhseItemTrackingLine.SetLoadFields("Quantity Handled (Base)");
        WhseItemTrackingLine.FindFirst();
        Assert.AreEqual(QtyPerBox * BoxesToPutAway, WhseItemTrackingLine."Quantity Handled (Base)", ItemTrackingQtyHandledErr);
    end;

    [Test]
    [HandlerFunctions('ChangeUOMRequestPageHandler')]
    procedure VerifyRegisterWarehouseMovementForAdditionalUnitOfMeasureOnPlaceLine()
    var
        Item: Record Item;
        Bin: Record Bin;
        BoxUnitOfMeasure: Record "Item Unit of Measure";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO 456130] Verify Register Warehouse Movement for additional Unit of Measure on place line
        Initialize();

        // [GIVEN] Create Location Setup with Warehouse Employee on default White Location
        CreateLocationSetup();

        // [GIVEN] Item with Base Unit of Measure = "PCS" and additional Unit of Measure = "BOX"
        LibraryInventory.CreateItem(Item);
        CreateItemUnitOfMeasure(BoxUnitOfMeasure, Item."No.", 6500);
        LibraryVariableStorage.Enqueue(BoxUnitOfMeasure.Code);

        // [GIVEN] Find Bin
        FindBin(Bin, LocationWhite.Code);

        // [GIVEN] Create and Register Warehouse Journal Line
        CreateAndRegisterWarehouseJournalLine(Bin, Item, 8000, Item."Base Unit of Measure");

        // [GIVEN] Calculate Warehouse Adjustment and Post Item Journal Line
        CalculateWarehouseAdjustmentAndPostItemJournalLine(Item);

        // [GIVEN] Create Warehouse Movement
        CreateMovementWorksheetLine(Bin, Item."No.", 8000);
        CreateMovement(WhseWorksheetLine, Item."No.", ItemTrackingMode::" ", false);

        // [WHEN] Change Unit of Measure on Place Line
        FindPlaceWhseActivityLine(WarehouseActivityLine, Item."No.");
        LibraryWarehouse.ChangeUnitOfMeasure(WarehouseActivityLine);

        // [THEN] Verify Warehouse Movement can be register
        RegisterWarehouseMovement(Item."No.", '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure WarningMessageWhenMaxQuantityExceedsForBin()
    var
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        Quantity: Decimal;
    begin
        // [SCENARIO 542681] Warning message when max. quantity is exceeded for a Bin when register a put-away.
        Initialize();

        // [GIVEN] Create Full Warehouse Location and Validate Bin Capacity Policy.
        LibraryWarehouse.CreateFullWMSLocation(Location, LibraryRandom.RandInt(2));
        Location.Validate("Bin Capacity Policy", Location."Bin Capacity Policy"::"Prohibit More Than Max. Cap.");
        Location.Modify(true);

        // [GIVEN] Create an Item.
        CreateItem(Item, '');

        // [GIVEN] Create Unit Of Measure.
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandInt(5) + 1);

        // [GIVEN] Find Reciving Bin.
        FindBin(Bin, Location.Code, true, false, false);

        // [GIVEN] Create two Bin Content.
        CreateBinContent(BinContent, Bin, Item."No.", Item."Base Unit of Measure", LibraryRandom.RandDec(100, 2));
        CreateBinContent(BinContent, Bin, Item."No.", ItemUnitOfMeasure.Code, BinContent."Max. Qty.");

        // [GIVEN] Calculate and Store Quantity.
        Quantity := BinContent."Max. Qty." + LibraryRandom.RandDec(100, 2);

        // [GIVEN] Create and Release Purchase Order.
        CreateAndReleasePurchaseOrderWithMultipleUOM(
            PurchaseHeader, Item."No.", ItemUnitOfMeasure.Code, '',
            Location.Code, Quantity, false);

        // [GIVEN] Create Warehouse Receipt From Purchase Order.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // [GIVEN] Find Warehouse Receipt Line of Purchase Order.
        FindWarehouseReceiptLine(
            WarehouseReceiptLine,
            WarehouseReceiptLine."Source Document"::"Purchase Order",
            PurchaseHeader."No.");

        // [WHEN] Post Warehouse Receipt From Purchase Order.
        asserterror PostWarehouseReceipt(WarehouseReceiptLine."No.");

        // [THEN] Error should occour when Maximum Quantity Exceeds for a Bin.
        Assert.ExpectedError(
            StrSubstNo(
                ExceedsAvailableCapacity,
                WarehouseActivityLine.FieldCaption("Qty. (Base)"),
                Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure",
                BinContent."Max. Qty.",
                BinContent.TableCaption(),
                BinContent."Bin Code"));
    end;

    local procedure FindBin(var Bin: Record Bin; LocationCode: Code[10])
    var
        Zone: Record Zone;
    begin
        FindZone(Zone, LocationCode, LibraryWarehouse.SelectBinType(false, false, true, true));
        LibraryWarehouse.CreateBin(Bin, Zone."Location Code", LibraryUtility.GenerateGUID(), Zone.Code, Zone."Bin Type Code");
    end;

    local procedure FindPlaceWhseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ItemNo: Code[20])
    begin
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure CreateAndRegisterWarehouseJournalLine(Bin: Record Bin; Item: Record Item; Quantity: Decimal; UnitOfMeasureCode: Code[10])
    var
        WhseJnlBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        LibraryWarehouse.CreateWarehouseJournalBatch(WhseJnlBatch, WarehouseJournalTemplate.Type::Item, Bin."Location Code");
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WhseJnlBatch."Journal Template Name", WhseJnlBatch.Name, Bin."Location Code",
          Bin."Zone Code", Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
        WarehouseJournalLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        WarehouseJournalLine.Modify(true);
        LibraryWarehouse.RegisterWhseJournalLine(
          WhseJnlBatch."Journal Template Name", WhseJnlBatch.Name, Bin."Location Code", true);
    end;

    local procedure CalculateWarehouseAdjustmentAndPostItemJournalLine(var Item: Record Item)
    begin
        CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Item, true);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure CreateItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; Type: Enum "Item Journal Template Type"; NoSeries: Boolean)
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, Type);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        if NoSeries then begin
            ItemJournalBatch.Validate("No. Series", LibraryERM.CreateNoSeriesCode());
            ItemJournalBatch.Modify(true);
        end;
    end;

    local procedure CreateAndPostWarehouseReceiptFromTransferOrder(var TransferHeader: Record "Transfer Header")
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        LibraryWarehouse.CreateWhseReceiptFromTO(TransferHeader);
        FindWarehouseReceiptLine(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Inbound Transfer", TransferHeader."No.");
        LibraryVariableStorage.Enqueue(StrSubstNo(TransferOrderDeleted, TransferHeader."No."));  // Enqueue for MessageHandler.
        PostWarehouseReceipt(WarehouseReceiptLine."No.");
    end;

    local procedure CreateAndPostWarehouseShipmentFromSalesOrder(var SalesLine: Record "Sales Line"; ItemNo: Code[20]; ItemUnitOfMeasureCode: Code[10]; LocationCode: Code[10]; Quantity: Decimal; Tracking: Boolean)
    var
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, ItemNo, ItemUnitOfMeasureCode, LocationCode, Quantity, Tracking);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);  // Use FALSE for only Shipment.
    end;

    local procedure CreateAndPostWhseShptFromSalesOrderUsingMovement(var SalesHeaderNo: Code[20])
    begin
        RegisterPickFromWarehouseShipmentCreatedBeforeMoveItemFromProdcutionBinToPickBin(
          SalesHeaderNo, ItemTrackingMode::"Assign Lot No.", ItemTrackingCode.Code, false, true); // Use Lot Item Tracking.

        PostAndInvoiceWhseShpt(SalesHeaderNo);
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Validate("Bin Code", BinCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateAndRegisterWarehouseReclassJournal(Bin: Record Bin; ItemNo: Code[20]; Quantity: Decimal; var NewLotNo: Code[50]; var NewLotNo2: Code[50])
    var
        WhseReclassificationJournal: TestPage "Whse. Reclassification Journal";
        DequeueVariable: Variant;
    begin
        WhseReclassificationJournal.OpenEdit();
        WhseReclassificationJournal."Item No.".SetValue(ItemNo);
        WhseReclassificationJournal."From Zone Code".SetValue(Bin."Zone Code");
        WhseReclassificationJournal."From Bin Code".SetValue(Bin.Code);
        WhseReclassificationJournal."To Zone Code".SetValue(Bin."Zone Code");
        WhseReclassificationJournal."To Bin Code".SetValue(Bin.Code);
        WhseReclassificationJournal.Quantity.SetValue(Quantity);
        WhseReclassificationJournal.ItemTrackingLines.Invoke();
        LibraryVariableStorage.Dequeue(DequeueVariable);
        NewLotNo := DequeueVariable;
        LibraryVariableStorage.Dequeue(DequeueVariable);
        NewLotNo2 := DequeueVariable;
        LibraryVariableStorage.Enqueue(PostJournalLines);  // Enqueue for MessageHandler.
        LibraryVariableStorage.Enqueue(LinesRegistered);  // Enqueue for MessageHandler.
        WhseReclassificationJournal.Register.Invoke();
    end;

    local procedure CreateAndReleasePurchaseOrderWithMultipleUOM(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; UnitOfMeasureCode2: Code[10]; LocationCode: Code[10]; Quantity: Decimal; Tracking: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        if UnitOfMeasureCode <> '' then
            CreatePurchaseLineWithUOM(
              PurchaseLine, PurchaseHeader, ItemNo, UnitOfMeasureCode, LocationCode, Quantity, Tracking, ItemTrackingMode::"Assign Lot No.");
        if UnitOfMeasureCode2 <> '' then
            CreatePurchaseLineWithUOM(
              PurchaseLine, PurchaseHeader, ItemNo, UnitOfMeasureCode2, LocationCode, Quantity, Tracking, ItemTrackingMode::"Assign Lot No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndReleasePurchaseOrderWithTwoUOM(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; ItemNo: Code[20]; UnitOfMeasure1Code: Code[10]; Quantity1: Decimal; UnitOfMeasure2Code: Code[10]; Quantity2: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLineWithUOM(
          PurchaseLine, PurchaseHeader, ItemNo, UnitOfMeasure1Code, LocationCode, Quantity1, false, ItemTrackingMode::" ");
        CreatePurchaseLineWithUOM(
          PurchaseLine, PurchaseHeader, ItemNo, UnitOfMeasure2Code, LocationCode, Quantity2, false, ItemTrackingMode::" ");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndReleasePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndReleasePurchaseOrderAtLocationWithQtyOfLinesForTheSameItem(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; ItemNo: Code[20]; QuantityOfItemInLine: Decimal; QuantityOfLines: Integer)
    var
        PurchaseLine: Record "Purchase Line";
        i: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Location Code", LocationCode);
        PurchaseHeader.Modify(true);
        for i := 1 to QuantityOfLines do
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, QuantityOfItemInLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndReleasePurchaseOrderWithItemTracking(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; Tracking: Boolean; ItemTrackingModePar: Option)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
        if Tracking then begin
            LibraryVariableStorage.Enqueue(ItemTrackingModePar); // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
            PurchaseLine.OpenItemTrackingLines();
        end;
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndReleaseSalesOrderWithItemTracking(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; Tracking: Boolean; ItemTrackingModePar: Option)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
        if Tracking then begin
            LibraryVariableStorage.Enqueue(ItemTrackingModePar); // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
            SalesLine.OpenItemTrackingLines();
        end;
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleaseSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; LocationCode: Code[10]; Quantity: Decimal; Tracking: Boolean)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        CreateSalesLineWithUOM(SalesLine, SalesHeader, ItemNo, UnitOfMeasureCode, LocationCode, Quantity, Tracking, false);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleaseSalesOrderWithReservation(var SalesHeader: Record "Sales Header"; Item: Record Item; LocationCode: Code[10]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        Clear(SalesHeader);  // Required for multiple Sales Order.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        CreateSalesLineWithUOM(SalesLine, SalesHeader, Item."No.", Item."Base Unit of Measure", LocationCode, Quantity, false, false);
        SalesLine.ShowReservation();
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleaseSalesOrderWithShipmentDate(var SalesHeader: Record "Sales Header"; Item: Record Item; LocationCode: Code[10]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        CreateSalesLineWithUOM(SalesLine, SalesHeader, Item."No.", Item."Base Unit of Measure", LocationCode, Quantity, false, false);
        SalesLine.Validate("Shipment Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));  // Value required for test.
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleaseSalesOrderAtLocationWithTwoLinesOfSingleItem(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: array[2] of Decimal)
    var
        SalesLine: Record "Sales Line";
        i: Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify(true);
        for i := 1 to 2 do
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity[i]);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleaseTransferOrder(var TransferHeader: Record "Transfer Header"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal; ItemUnitOfMeasure: Code[10])
    var
        TransferLine: Record "Transfer Line";
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, LocationIntransit.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        TransferLine.Validate("Unit of Measure Code", ItemUnitOfMeasure);
        TransferLine.Modify(true);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
    end;

    local procedure CreateAndReleaseTransferOrderWithItemTracking(var TransferHeader: Record "Transfer Header"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal; LastLotNo: Boolean)
    var
        TransferLine: Record "Transfer Line";
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, LocationIntransit.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        LibraryVariableStorage.Enqueue(LastLotNo); // Enqueue LastLotNo for ItemTrackingSummaryPageHandler.
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
    end;

    local procedure CreateAndReleaseWarehouseShipmentFromSalesOrder(ItemNo: Code[20]; BaseUnitofMeasure: Code[10]; LocationCode: Code[10]; Quantity: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, ItemNo, BaseUnitofMeasure, LocationCode, Quantity, false); // Use FALSE for without Tracking.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindAndReleaseWarehouseShipmentLine(SalesHeader."No.");
        exit(SalesHeader."No.");
    end;

    local procedure CreateSalesOrderAndPick(var SalesHeader: Record "Sales Header"; LocationCode: Code[10]; ItemNo: Code[20]; UnitofMeasure: Code[10]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, ItemNo, UnitofMeasure, LocationCode, Quantity, false); // Use FALSE for without Tracking.
        CreatePickFromWarehouseShipment(SalesHeader);
    end;

    local procedure CreateAssembledItemSalesOrderAndAssemblyOrderPick(LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Shipment Date", WorkDate() + 1);
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Qty. to Assemble to Order", Quantity);
        SalesLine.Validate("Shipment Date", WorkDate() + 1);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        AssemblyHeader.SetRange("Item No.", ItemNo);
        AssemblyHeader.FindFirst();
        LibraryAssembly.ReleaseAO(AssemblyHeader);

        LibraryVariableStorage.Enqueue(WhsePickCreatedTxt); // Enqueue for MessageHandler.

        LibraryAssembly.CreateWhsePick(AssemblyHeader, UserId, 0, false, false, false);
    end;

    local procedure CreateBinWithBinRanking(var Bin: Record Bin; LocationCode: Code[10]; BinRanking: Integer; Receive: Boolean; Ship: Boolean; PutAway: Boolean; Pick: Boolean)
    var
        Zone: Record Zone;
    begin
        FindZone(Zone, LocationCode, LibraryWarehouse.SelectBinType(Receive, Ship, PutAway, Pick));
        LibraryWarehouse.CreateBin(Bin, Zone."Location Code", LibraryUtility.GenerateGUID(), Zone.Code, Zone."Bin Type Code");
        Bin.Validate("Bin Ranking", BinRanking);
        Bin.Modify(true);
    end;

    local procedure CreateBinContent(var BinContent: Record "Bin Content"; Bin: Record Bin; ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; MaxQty: Decimal)
    begin
        LibraryWarehouse.CreateBinContent(BinContent, Bin."Location Code", Bin."Zone Code", Bin.Code, ItemNo, '', UnitOfMeasureCode);
        BinContent.Validate(Fixed, true);
        BinContent.Validate("Bin Type Code", Bin."Bin Type Code");
        BinContent.Validate("Bin Ranking", Bin."Bin Ranking");
        BinContent.Validate("Min. Qty.", MaxQty);
        BinContent.Validate("Max. Qty.", MaxQty);
        BinContent.Modify(true);
    end;

    local procedure CreateItemWithProductionBOMWithItemTracking(var ParentItem: Record Item; var ComponentItem: Record Item; ItemTrackingCode: Code[10])
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateItem(ParentItem, ItemTrackingCode);
        CreateItem(ComponentItem, ItemTrackingCode);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ComponentItem."No.", ComponentItem."Base Unit of Measure", 1, BomLineType::Item);
        UpdateProductionBomAndRoutingOnItem(ParentItem, ProductionBOMHeader."No.", '');
    end;

    local procedure CreateInventoryPickWithReservation(var SalesHeader: Record "Sales Header"; Item: Record Item; LocationCode: Code[10]; Quantity: Decimal)
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        CreateAndReleaseSalesOrderWithReservation(SalesHeader, Item, LocationCode, Quantity);
        LibraryVariableStorage.Enqueue(PickCreated);  // Enqueue for MessageHandler.
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Sales Order", SalesHeader."No.", false, true, false);
    end;

    local procedure CreateItem(var Item: Record Item; ItemTrackingCode: Code[10])
    begin
        if ItemTrackingCode <> '' then
            LibraryInventory.CreateTrackedItem(
              Item, LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(), ItemTrackingCode)
        else
            LibraryInventory.CreateItem(Item);
    end;

    local procedure CreateItemTrackingCode(var ItemTrackingCode: Record "Item Tracking Code"; Serial: Boolean; Lot: Boolean; StrictExpirationPosting: Boolean; UseExpirationDates: Boolean)
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, Serial, Lot);
        ItemTrackingCode.Validate("SN Warehouse Tracking", Serial);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", Lot);
        ItemTrackingCode.Validate("Use Expiration Dates", UseExpirationDates);
        ItemTrackingCode.Validate("Man. Expir. Date Entry Reqd.", StrictExpirationPosting);
        ItemTrackingCode.Validate("Strict Expiration Posting", StrictExpirationPosting);
        ItemTrackingCode.Modify(true);
    end;

    local procedure CreateItemUnitOfMeasure(var ItemUnitOfMeasure: Record "Item Unit of Measure"; ItemNo: Code[20]; QtyPerUnitOfMeasure: Decimal)
    begin
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, ItemNo, QtyPerUnitOfMeasure);
    end;

    local procedure CreateItemWithMultipleUOM(var Item: Record Item; var ItemUnitOfMeasureSales: Record "Item Unit of Measure"; var ItemUnitOfMeasurePutAway: Record "Item Unit of Measure"; ItemTrackingCode: Code[10])
    begin
        CreateItem(Item, ItemTrackingCode);
        CreateItemUnitOfMeasure(ItemUnitOfMeasureSales, Item."No.", LibraryRandom.RandInt(5) + 1);  // Value required for multiple UOM with different conversion rate.
        CreateItemUnitOfMeasure(ItemUnitOfMeasurePutAway, Item."No.", LibraryRandom.RandInt(5) + 1);  // Value required for multiple UOM with different conversion rate.
        UpdateItemUOM(Item, Item."Base Unit of Measure", ItemUnitOfMeasureSales.Code, ItemUnitOfMeasurePutAway.Code);
    end;

    local procedure CreateItemWithNonBaseUOM(var Item: Record Item; var BaseItemUnitOfMeasure: Record "Item Unit of Measure"; var NonBaseItemUnitOfMeasure: Record "Item Unit of Measure"; QtyPer: Decimal)
    begin
        CreateItem(Item, '');
        CreateItemUnitOfMeasure(NonBaseItemUnitOfMeasure, Item."No.", QtyPer);
        BaseItemUnitOfMeasure.Get(Item."No.", Item."Base Unit of Measure");
    end;

    local procedure CreateItemWithSalesUOM(var Item: Record Item; QtyPer: Decimal)
    var
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, QtyPer);
        Item.Validate("Sales Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Modify(true);
    end;

    local procedure CreateAssembledItem(var ParentItem: Record Item; var ChildItem: Record Item; QtyPer: Integer)
    var
        BOMComponent: Record "BOM Component";
    begin
        LibraryInventory.CreateItem(ParentItem);
        ParentItem.Validate("Replenishment System", ParentItem."Replenishment System"::Assembly);
        ParentItem.Validate("Assembly Policy", ParentItem."Assembly Policy"::"Assemble-to-Order");
        ParentItem.Modify(true);

        LibraryInventory.CreateItem(ChildItem);

        LibraryInventory.CreateBOMComponent(
          BOMComponent, ParentItem."No.", BOMComponent.Type::Item, ChildItem."No.", 1, ParentItem."Base Unit of Measure");
        BOMComponent.Validate("Quantity per", QtyPer);
        BOMComponent.Modify(true);
    end;

    local procedure CreateMovement(var WhseWorksheetLine: Record "Whse. Worksheet Line"; ItemNo: Code[20]; ItemTrackingModePar: Option; Tracking: Boolean)
    begin
        WhseWorksheetLine.SetRange("Item No.", ItemNo);
        WhseWorksheetLine.FindFirst();
        if Tracking then begin
            LibraryVariableStorage.Enqueue(ItemTrackingModePar);
            LibraryVariableStorage.Enqueue(false);
            WhseWorksheetLine.OpenItemTrackingLines();
        end;
        LibraryWarehouse.WhseSourceCreateDocument(WhseWorksheetLine, "Whse. Activity Sorting Method"::None, false, false, false);
    end;

    local procedure CreateMovementWorksheetLine(Bin: Record Bin; ItemNo: Code[20]; Quantity: Decimal)
    var
        Bin2: Record Bin;
        MovementWorksheet: TestPage "Movement Worksheet";
    begin
        MovementWorksheet.OpenEdit();
        MovementWorksheet."Item No.".SetValue(ItemNo);
        MovementWorksheet."From Zone Code".SetValue(Bin."Zone Code");
        MovementWorksheet."From Bin Code".SetValue(Bin.Code);
        FindBin(Bin2, Bin."Location Code", false, true, false);  // Find BULK Bin.
        MovementWorksheet."To Zone Code".SetValue(Bin2."Zone Code");
        MovementWorksheet."To Bin Code".SetValue(Bin2.Code);
        MovementWorksheet.Quantity.SetValue(Quantity);
        MovementWorksheet.OK().Invoke();
    end;

    local procedure CreateAndRegisterWarehouseMovement(LocationCode: Code[10]; ItemNo: Code[20])
    var
        Bin: Record Bin;
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        FindBin(Bin, LocationWhite.Code, false, true, true); // Find PICK Bin.
        GetBinContentOnMovementWorksheet(WhseWorksheetLine, LocationCode, ItemNo);
        WhseWorksheetLine.SetRange("Item No.", ItemNo);
        WhseWorksheetLine.FindFirst();
        WhseWorksheetLine.Validate("To Zone Code", Bin."Zone Code");
        WhseWorksheetLine.Validate("To Bin Code", Bin.Code);
        WhseWorksheetLine.Modify(true);
        CreateMovement(WhseWorksheetLine, ItemNo, ItemTrackingMode::" ", false);
        RegisterWarehouseMovement(ItemNo, '');
    end;

    local procedure CreateAndRegisterPutAwayFromPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; Location: Record Location; ItemNo: Code[20]; ItemTrackingModePar: Option; Qty: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Bin: Record Bin;
    begin
        CreateAndReleasePurchaseOrderWithItemTracking(PurchaseHeader, ItemNo, Location.Code, Qty, true, ItemTrackingModePar);
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader);

        Bin.Get(Location.Code, Location."Cross-Dock Bin Code"); // Find Cross Dock Bin.
        UpdateBinOnWarehouseActivityLine(
          Bin, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Place);

        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order",
          PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");
    end;

    local procedure CreateAndRegisterPickFromProductionOrder(var SalesHeader: Record "Sales Header"; ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20]; Serial: Boolean; Lot: Boolean)
    var
        ProductionOrder: Record "Production Order";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        LibraryVariableStorage.Enqueue(ProductionOrderCreated); // Enqueue for MessageHandler.
        LibraryManufacturing.CreateProductionOrderFromSalesOrder(
            SalesHeader, ProductionOrder.Status::Released, "Create Production Order Type"::ItemOrder);
        FindProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ItemNo);
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);

        UpdateTrackingNoOnWarehouseActivityLine(
          WarehouseActivityLine, ItemLedgerEntry,
          ProductionOrder."No.", WarehouseActivityLine."Action Type"::Take, Serial, Lot);
        UpdateTrackingNoOnWarehouseActivityLine(
          WarehouseActivityLine, ItemLedgerEntry,
          ProductionOrder."No.", WarehouseActivityLine."Action Type"::Place, Serial, Lot);

        RegisterWarehouseActivity(WarehouseActivityLine."Source Document"::"Prod. Consumption",
          ProductionOrder."No.", WarehouseActivityLine."Activity Type"::Pick);

        // Open Production Journal and Post. Handler used -ProductionJournalHandler.
        OpenProductionJournalForReleasedProductionOrder(ItemNo);
    end;

    local procedure CreateAndRegisterPickFromWarehouseShipment(var SalesHeader: Record "Sales Header")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        FindWarehouseShipmentLine(WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
    end;

    local procedure CreatePick(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        FindWarehouseShipmentLine(WarehouseShipmentLine, SourceDocument, SourceNo);
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
    end;

    local procedure CreatePickFromWarehouseShipment(SalesHeader: Record "Sales Header")
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
    end;

    local procedure CreatePickFromWarehouseShipmentWithExpirationDate(SalesHeader: Record "Sales Header")
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        LibraryVariableStorage.Enqueue(ExpiredItemMsg); // Enqueue value for MessageHandler.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
    end;

    local procedure CreatePickFromWarehouseShipmentWithReservation(var SalesHeader: Record "Sales Header"; Item: Record Item; LocationCode: Code[10]; Quantity: Decimal)
    begin
        CreateAndReleaseSalesOrderWithReservation(SalesHeader, Item, LocationCode, Quantity);
        CreatePickFromWarehouseShipment(SalesHeader);
    end;

    local procedure CreatePurchaseLineWithUOM(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; LocationCode: Code[10]; Quantity: Decimal; Tracking: Boolean; ItemTrackingModePar: Option)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
        if Tracking then begin
            LibraryVariableStorage.Enqueue(ItemTrackingModePar);  // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
            PurchaseLine.OpenItemTrackingLines();
            ReservationEntry.SetRange("Item No.", ItemNo);
            ReservationEntry.ModifyAll("Expiration Date", WorkDate(), true);
        end
    end;

    local procedure CreateCreditMemoUsingCopyPurchase(PurchHeaderNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
    begin
        PurchaseHeader.Init();
        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::"Credit Memo");
        PurchaseHeader.Insert(true);

        CopyDocMgt.SetProperties(true, false, false, false, false, false, false);
        CopyDocMgt.CopyPurchDoc("Purchase Document Type From"::"Posted Receipt", GetPurchRcptNo(PurchHeaderNo), PurchaseHeader);
    end;

    local procedure CreateCreditMemoUsingCopySales(SalesHeaderNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
    begin
        SalesHeader.Init();
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::"Credit Memo");
        SalesHeader.Insert(true);

        CopyDocMgt.SetProperties(true, false, false, false, false, false, false);
        CopyDocMgt.CopySalesDoc("Sales Document Type From"::"Posted Invoice", GetSalesInvoiceNo(SalesHeaderNo), SalesHeader);
    end;

    local procedure CreatePurchaseLineWithUOMAndLotNo(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; LocationCode: Code[10]; Quantity: Decimal; LotNo: Code[50])
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);

        if LotNo = '' then
            exit;

        LibraryVariableStorage.Enqueue(ItemTrackingLineHandling::Create);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(PurchaseLine."Quantity (Base)");
        PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure PlaceToBinsAndRegisterWarehouseActivity(var TempWarehouseEntry: Record "Warehouse Entry" temporary; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20];
                                                                                                                                            ActivityType: Enum "Warehouse Activity Type")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.FindSet();
        repeat
            TempWarehouseEntry.SetRange("Line No.", WarehouseActivityLine."Source Line No.");
            TempWarehouseEntry.FindFirst();
            WarehouseActivityLine.Validate(
              "Zone Code",
              LibraryWarehouse.GetZoneForBin(TempWarehouseEntry."Location Code", TempWarehouseEntry."Bin Code"));
            WarehouseActivityLine.Validate("Bin Code", TempWarehouseEntry."Bin Code");
            WarehouseActivityLine.Modify();
        until WarehouseActivityLine.Next() = 0;
        RegisterWarehouseActivity(SourceDocument, SourceNo, ActivityType);
    end;

    local procedure CreateSalesLineWithUOM(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; LocationCode: Code[10]; Quantity: Decimal; Tracking: Boolean; LastLotNo: Boolean)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
        if Tracking then begin
            LibraryVariableStorage.Enqueue(LastLotNo);  // Enqueue LastLotNo at index 1 for ItemTrackingSummaryPageHandler.
            SalesLine.OpenItemTrackingLines();
        end
    end;

    local procedure CreateSalesLineForReleasedSalesOrder(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; LocationCode: Code[10]; Quantity: Decimal; Tracking: Boolean; LastLotNo: Boolean)
    begin
        LibrarySales.ReopenSalesDocument(SalesHeader);
        CreateSalesLineWithUOM(SalesLine, SalesHeader, ItemNo, UnitOfMeasureCode, LocationCode, Quantity, Tracking, LastLotNo);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateWarehouseReceiptHeaderWithLocation(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; LocationCode: Code[10])
    begin
        LibraryWarehouse.CreateWarehouseReceiptHeader(WarehouseReceiptHeader);
        WarehouseReceiptHeader.Validate("Location Code", LocationCode);
        WarehouseReceiptHeader.Modify(true);
    end;

    local procedure CreateWarehouseShipmentHeaderWithLocation(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; LocationCode: Code[10])
    begin
        LibraryWarehouse.CreateWarehouseShipmentHeader(WarehouseShipmentHeader);
        WarehouseShipmentHeader.Validate("Location Code", LocationCode);
        WarehouseShipmentHeader.Modify(true);
    end;

    local procedure CreateWarehouseShipmentWithGetSourceDocument(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; ItemNo: Code[20]; LocationCode: Code[10])
    var
        WarehouseSourceFilter: Record "Warehouse Source Filter";
    begin
        CreateWarehouseShipmentHeaderWithLocation(WarehouseShipmentHeader, LocationCode);
        LibraryWarehouse.CreateWarehouseSourceFilter(WarehouseSourceFilter, WarehouseSourceFilter.Type::Outbound);
        WarehouseSourceFilter.Validate("Sales Orders", true);
        WarehouseSourceFilter.Validate("Item No. Filter", ItemNo);
        WarehouseSourceFilter.Modify(true);
        LibraryWarehouse.GetSourceDocumentsShipment(WarehouseShipmentHeader, WarehouseSourceFilter, LocationWhite3.Code);
    end;

    local procedure CreateWhseWorksheetLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; FromBin: Record Bin; ToBin: Record Bin; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryWarehouse.CreateWhseWorksheetLine(
          WhseWorksheetLine, WhseWorksheetLine."Worksheet Template Name", WhseWorksheetLine.Name, LocationWhite.Code, "Warehouse Worksheet Document Type"::" ");
        WhseWorksheetLine.Validate("Item No.", ItemNo);
        WhseWorksheetLine.Validate("From Zone Code", FromBin."Zone Code");
        WhseWorksheetLine.Validate("From Bin Code", FromBin.Code);
        WhseWorksheetLine.Validate("To Zone Code", ToBin."Zone Code");
        WhseWorksheetLine.Validate("To Bin Code", ToBin.Code);
        WhseWorksheetLine.Validate(Quantity, Quantity);
        WhseWorksheetLine.Validate("Qty. to Handle", Quantity);
        WhseWorksheetLine.Modify(true);
    end;

    local procedure CreateNegativeAdjmtWarehouseJournalLine(Item: Record Item; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    var
        Bin: Record Bin;
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        Bin.Get(LocationCode, BinCode);
        LibraryWarehouse.WarehouseJournalSetup(Bin."Location Code", WarehouseJournalTemplate, WarehouseJournalBatch);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Bin."Location Code",
          Bin."Zone Code", '', WarehouseJournalLine."Entry Type"::"Negative Adjmt.", Item."No.", -Quantity);
        WarehouseJournalLine.Validate("Unit of Measure Code", Item."Base Unit of Measure");
        WarehouseJournalLine.Validate("Bin Code", Bin.Code);
        WarehouseJournalLine.Modify(true);
    end;

    local procedure MockMovement(var WarehouseActivityHeader: Record "Warehouse Activity Header"; ItemNo: Code[20]; QtyBase: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Bin: Record Bin;
    begin
        Clear(WarehouseActivityHeader);
        WarehouseActivityHeader.Validate("Location Code", LocationWhite.Code);
        WarehouseActivityHeader.Validate(Type, WarehouseActivityHeader.Type::Movement);
        WarehouseActivityHeader.Insert(true);

        FindBin(Bin, LocationWhite.Code, false, true, true); // Pick Bin
        MockWhseActivityLine(
          WarehouseActivityHeader, WarehouseActivityLine."Action Type"::Take, ItemNo, Bin.Code, QtyBase, 0);
        FindBin(Bin, LocationWhite.Code, true, false, false); // Receive Bin
        MockWhseActivityLine(
          WarehouseActivityHeader, WarehouseActivityLine."Action Type"::Place, ItemNo, Bin.Code, QtyBase, 0);
    end;

    local procedure MockWhseActivityLine(WarehouseActivityHeader: Record "Warehouse Activity Header"; ActionType: Enum "Warehouse Action Type"; ItemNo: Code[20];
                                                                                                                      BinCode: Code[20];
                                                                                                                      QtyBase: Decimal;
                                                                                                                      QtyToHandleBase: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine."Activity Type" := WarehouseActivityHeader.Type;
        WarehouseActivityLine."No." := WarehouseActivityHeader."No.";

        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type");
        WarehouseActivityLine.SetRange("No.", WarehouseActivityLine."No.");
        if WarehouseActivityLine.FindLast() then;

        WarehouseActivityLine.Init();
        WarehouseActivityLine."Line No." := WarehouseActivityLine."Line No." + 10000;
        WarehouseActivityLine."Action Type" := ActionType;
        WarehouseActivityLine."Location Code" := WarehouseActivityHeader."Location Code";
        WarehouseActivityLine."Bin Code" := BinCode;
        WarehouseActivityLine."Item No." := ItemNo;
        WarehouseActivityLine."Qty. (Base)" := QtyBase;
        WarehouseActivityLine."Qty. to Handle (Base)" := QtyToHandleBase;
        WarehouseActivityLine.Insert();
    end;

    local procedure MockFinProdOrderLine(ItemNo: Code[20]; ItemUoMCode: Code[10])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.Init();
        ProdOrderLine.Status := ProdOrderLine.Status::Finished;
        ProdOrderLine."Item No." := ItemNo;
        ProdOrderLine."Remaining Quantity" := LibraryRandom.RandInt(5);
        ProdOrderLine."Unit of Measure Code" := ItemUoMCode;
        ProdOrderLine.Insert();
    end;

    local procedure MockFinProdOrderComp(ItemNo: Code[20]; ItemUoMCode: Code[10])
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        ProdOrderComp.Init();
        ProdOrderComp.Status := ProdOrderComp.Status::Finished;
        ProdOrderComp."Item No." := ItemNo;
        ProdOrderComp."Remaining Quantity" := LibraryRandom.RandInt(5);
        ProdOrderComp."Unit of Measure Code" := ItemUoMCode;
        ProdOrderComp.Insert();
    end;

    local procedure DeleteWarehouseActivity(ActivityType: Enum "Warehouse Activity Type"; No: Code[20])
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        WarehouseActivityHeader.Get(ActivityType, No);
        WarehouseActivityHeader.Delete(true);
    end;

    local procedure DequeueLotNo(var LotNo: Code[50])
    var
        DequeueVariable: Variant;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        LotNo := DequeueVariable;
    end;

    local procedure EnqueueValuesToVerifyBOMCostSharesPage(ItemNo: Code[20]; UnitofMeasureCode: Code[10]; BOMUnitofMeasureCode: Code[10]; QtyPerParent: Decimal; QtyPerTopItem: Decimal; BOMLineQtyPer: Decimal)
    begin
        LibraryVariableStorage.Enqueue(ItemNo);
        LibraryVariableStorage.Enqueue(UnitofMeasureCode);
        LibraryVariableStorage.Enqueue(BOMUnitofMeasureCode);
        LibraryVariableStorage.Enqueue(QtyPerParent);
        LibraryVariableStorage.Enqueue(QtyPerTopItem);
        LibraryVariableStorage.Enqueue(BOMLineQtyPer);
    end;

    local procedure GetSalesInvoiceNo(SalesHeaderNo: Code[20]): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("Order No.", SalesHeaderNo);
        SalesInvoiceHeader.FindFirst();
        exit(SalesInvoiceHeader."No.");
    end;

    local procedure GetPurchRcptNo(PurchHeaderNo: Code[20]): Code[20]
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        PurchRcptHeader.SetRange("Order No.", PurchHeaderNo);
        PurchRcptHeader.FindFirst();
        exit(PurchRcptHeader."No.");
    end;

    local procedure FillWhseItemTrackingLines(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines"; OldLotNo: Code[50]; Quantity: Decimal)
    var
        NewLotNo: Code[50];
    begin
        NewLotNo := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(NewLotNo);  // Enqueue NewLotNo.
        WhseItemTrackingLines."Lot No.".SetValue(OldLotNo);
        WhseItemTrackingLines."New Lot No.".SetValue(NewLotNo);
        WhseItemTrackingLines.Quantity.SetValue(Quantity);
    end;

    local procedure FindBin(var Bin: Record Bin; LocationCode: Code[10]; Receive: Boolean; PutAway: Boolean; Pick: Boolean)
    var
        Zone: Record Zone;
    begin
        FindZone(Zone, LocationCode, LibraryWarehouse.SelectBinType(Receive, false, PutAway, Pick));
        LibraryWarehouse.FindBin(Bin, Zone."Location Code", Zone.Code, 1) // Use 1 for Index.
    end;

    local procedure FindNextBin(BinCode: Code[20]; var Bin: Record Bin; LocationCode: Code[10]; Receive: Boolean; PutAway: Boolean; Pick: Boolean)
    var
        Zone: Record Zone;
    begin
        FindZone(Zone, LocationCode, LibraryWarehouse.SelectBinType(Receive, false, PutAway, Pick));
        LibraryWarehouse.FindBin(Bin, Zone."Location Code", Zone.Code, 1); // Use 1 for Index.
        if BinCode = '' then
            exit;
        Bin.FindSet();
        repeat
            if Bin.Code = BinCode then
                if Bin.Next() = 0 then
                    Assert.Fail(StrSubstNo(CouldNotFindBinErr, BinCode))
                else
                    exit;
        until Bin.Next() = 0;
    end;

    local procedure FindBinContent(var BinContent: Record "Bin Content"; Bin: Record Bin; ItemNo: Code[20])
    begin
        BinContent.SetRange("Location Code", Bin."Location Code");
        BinContent.SetRange("Zone Code", Bin."Zone Code");
        BinContent.SetRange("Bin Code", Bin.Code);
        BinContent.SetRange("Item No.", ItemNo);
    end;

    local procedure FindBOMBufferLine(var BOMBuffer: Record "BOM Buffer"; ItemNo: Code[20])
    begin
        BOMBuffer.SetRange(Type, BOMBuffer.Type::Item);
        BOMBuffer.SetRange("No.", ItemNo);
        BOMBuffer.FindFirst();
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20];
                                                                                                        UnitOfMeasureCode: Code[10])
    begin
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Unit of Measure Code", UnitOfMeasureCode);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure FindProductionOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ItemNo: Code[20])
    begin
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst();
    end;

    local procedure FindProductionOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceNo: Code[20])
    begin
        ProductionOrder.SetRange(Status, Status);
        ProductionOrder.SetRange("Source No.", SourceNo);
        ProductionOrder.FindFirst();
    end;

    local procedure FindWarehouseActivityLineForPick(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20];
                                                                                                                                      ActivityType: Enum "Warehouse Activity Type";
                                                                                                                                      ActionType: Enum "Warehouse Action Type")
    begin
        WarehouseActivityLine.SetRange("Source Document", SourceDocument);
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure FindWarehouseActivityLinesPairForPick(var WarehouseActivityLineTake: Record "Warehouse Activity Line"; var WarehouseActivityLinePlace: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    begin
        FindWarehouseActivityLineForPick(
          WarehouseActivityLineTake, SourceDocument, SourceNo, WarehouseActivityLineTake."Activity Type"::Pick,
          WarehouseActivityLineTake."Action Type"::Take);
        FindWarehouseActivityLineForPick(
WarehouseActivityLinePlace, SourceDocument, SourceNo, WarehouseActivityLinePlace."Activity Type"::Pick,
WarehouseActivityLinePlace."Action Type"::Place);
    end;

    local procedure FindRegisteredWhseActivityLine(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20];
                                                                                                                                                ActivityType: Enum "Warehouse Activity Type";
                                                                                                                                                ActionType: Enum "Warehouse Action Type")
    begin
        RegisteredWhseActivityLine.SetRange("Source Document", SourceDocument);
        RegisteredWhseActivityLine.SetRange("Source No.", SourceNo);
        RegisteredWhseActivityLine.SetRange("Activity Type", ActivityType);
        RegisteredWhseActivityLine.SetRange("Action Type", ActionType);
        RegisteredWhseActivityLine.FindFirst();
    end;

    local procedure FindZone(var Zone: Record Zone; LocationCode: Code[10]; BinTypeCode: Code[10])
    begin
        Zone.SetRange("Location Code", LocationCode);
        Zone.SetRange("Bin Type Code", BinTypeCode);
        Zone.SetRange("Cross-Dock Bin Zone", false);
        Zone.FindFirst();
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20];
                                                                                                                               ActivityType: Enum "Warehouse Activity Type")
    begin
        WarehouseActivityLine.SetRange("Source Document", SourceDocument);
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure FindWarehouseActivityLineWithActionType(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20];
                                                                                                                                             ActivityType: Enum "Warehouse Activity Type";
                                                                                                                                             ActionType: Enum "Warehouse Action Type")
    begin
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
    end;

    local procedure FindWarehousePickLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; ItemNo: Code[20];
                                                                                                                           ActivityType: Enum "Warehouse Activity Type")
    begin
        WarehouseActivityLine.SetRange("Source Document", SourceDocument);
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure FindWarehouseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    begin
        WarehouseReceiptLine.SetRange("Source Document", SourceDocument);
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.FindFirst();
    end;

    local procedure FindWarehouseShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    begin
        WarehouseShipmentLine.SetRange("Source Document", SourceDocument);
        WarehouseShipmentLine.SetRange("Source No.", SourceNo);
        WarehouseShipmentLine.FindFirst();
    end;

    local procedure FindAndReleaseWarehouseShipmentLine(SalesHeaderNo: Code[20])
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WhseShipmentRelease: Codeunit "Whse.-Shipment Release";
    begin
        FindWarehouseShipmentLine(WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeaderNo);
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        WhseShipmentRelease.Release(WarehouseShipmentHeader);
    end;

    local procedure FindServiceLine(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindFirst();
    end;

    local procedure GetBinContentOnMovementWorksheet(var WhseWorksheetLine: Record "Whse. Worksheet Line"; LocationCode: Code[10]; ItemNo: Code[20])
    var
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        BinContent: Record "Bin Content";
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
    begin
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Movement);
        LibraryWarehouse.SelectWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, LocationCode);
        WhseWorksheetLine.DeleteAll(true);
        WhseWorksheetLine.Init();
        WhseWorksheetLine.Validate("Worksheet Template Name", WhseWorksheetName."Worksheet Template Name");
        WhseWorksheetLine.Validate(Name, WhseWorksheetName.Name);
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Item No.", ItemNo);
        WhseInternalPutAwayHeader.Init();
        LibraryWarehouse.WhseGetBinContent(
            BinContent, WhseWorksheetLine, WhseInternalPutAwayHeader, "Warehouse Destination Type 2"::MovementWorksheet);
    end;

    local procedure GetWarehouseDocumentOnPickWorksheet(ItemNo: Code[20]; LocationCode: Code[10]; PerWhseDoc: Boolean)
    var
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhsePickRequest: Record "Whse. Pick Request";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Pick);
        LibraryWarehouse.SelectWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, LocationCode);
        WhsePickRequest.SetRange("Location Code", LocationCode);
        LibraryWarehouse.GetOutboundSourceDocuments(WhsePickRequest, WhseWorksheetName, LocationCode);
        if ItemNo <> '' then begin
            WhseWorksheetLine.SetRange("Item No.", ItemNo);
            WhseWorksheetLine.FindFirst();
        end;
        LibraryWarehouse.CreatePickFromPickWorksheet(
          WhseWorksheetLine, WhseWorksheetLine."Line No.", WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name,
          LocationCode, '', 0, 0, "Whse. Activity Sorting Method"::None, false, false, false, false, PerWhseDoc, false, false);
    end;

    local procedure CalcTakenForPickQtyBaseOfItemWithUOMInSalesOrder(DocNo: Code[20]; ItemNo: Code[20]; UOMCode: Code[10]): Decimal
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        RegisteredWhseActivityLine.SetRange("Source Document", RegisteredWhseActivityLine."Source Document"::"Sales Order");
        RegisteredWhseActivityLine.SetRange("Source No.", DocNo);
        RegisteredWhseActivityLine.SetRange("Activity Type", RegisteredWhseActivityLine."Activity Type"::Pick);
        RegisteredWhseActivityLine.SetRange("Action Type", RegisteredWhseActivityLine."Action Type"::Take);
        RegisteredWhseActivityLine.SetRange("Item No.", ItemNo);
        RegisteredWhseActivityLine.SetRange("Unit of Measure Code", UOMCode);
        RegisteredWhseActivityLine.CalcSums("Qty. (Base)");
        exit(RegisteredWhseActivityLine."Qty. (Base)");
    end;

    local procedure RegisterPutAwayForItemWithTwoUOM(LocationCode: Code[10]; ItemNo: Code[20]; UnitOfMeasure1Code: Code[10]; Quantity1: Decimal; UnitOfMeasure2Code: Code[10]; Quantity2: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreateAndReleasePurchaseOrderWithTwoUOM(
          PurchaseHeader, LocationCode, ItemNo, UnitOfMeasure1Code, Quantity1, UnitOfMeasure2Code, Quantity2);

        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order",
          PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");
    end;

    local procedure RegisterPutAwayForItem(LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreateAndReleasePurchaseOrder(PurchaseHeader, LocationCode, ItemNo, Quantity);

        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order",
          PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");
    end;

    local procedure MockWarehouseAdjustmentEntry(ItemUnitOfMeasure: Record "Item Unit of Measure")
    var
        WarehouseEntry: Record "Warehouse Entry";
        Bin: Record Bin;
        NewEntryNo: Integer;
    begin
        Bin.Get(LocationWhite.Code, LocationWhite."Adjustment Bin Code");
        WarehouseEntry.FindLast();
        NewEntryNo := WarehouseEntry."Entry No." + 1;
        WarehouseEntry.Init();
        WarehouseEntry."Entry No." := NewEntryNo;
        WarehouseEntry."Item No." := ItemUnitOfMeasure."Item No.";
        WarehouseEntry."Unit of Measure Code" := ItemUnitOfMeasure.Code;
        WarehouseEntry."Zone Code" := Bin."Zone Code";
        WarehouseEntry.Insert();
    end;

    local procedure OpenProductionJournalForReleasedProductionOrder(ItemNo: Code[20])
    var
        ReleasedProductionOrder: TestPage "Released Production Order";
    begin
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.FILTER.SetFilter("Source No.", ItemNo);
        ReleasedProductionOrder.ProdOrderLines.ProductionJournal.Invoke(); // Open Production Journal.
    end;

    local procedure PostWarehouseReceipt(WarehouseReceiptNo: Code[20])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        WarehouseReceiptHeader.Get(WarehouseReceiptNo);
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure PostWarehouseShipment(WarehouseShipmentNo: Code[20])
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        WarehouseShipmentHeader.Get(WarehouseShipmentNo);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);  // Use FALSE for only Shipment.
    end;

    local procedure PostAndInvoiceWhseShpt(SalesHeaderNo: Code[20])
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        FindWarehouseShipmentLine(WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeaderNo);
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, true);
    end;

    local procedure RegisterWarehouseActivity(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20];
                                                                  ActivityType: Enum "Warehouse Activity Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure RegisterAllWarehouseActivies(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20];
                                                                     BaseQtyToHandle: Decimal)
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Source Document", SourceDocument);
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        if WarehouseActivityLine.FindSet() then
            repeat
                WarehouseActivityLine.Validate("Qty. to Handle (Base)", BaseQtyToHandle);
                WarehouseActivityLine.Modify();
            until WarehouseActivityLine.Next() = 0;
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure RegisterWarehouseMovement(ItemNo: Code[20]; SourceNo: Code[20])
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::" ", SourceNo, WarehouseActivityLine."Activity Type"::Movement);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure FilterWhseItemTrackingLineByWhseReceipt(WarehouseReceiptLine: Record "Warehouse Receipt Line"; var WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    var
        PostedWarehouseReceiptHeader: Record "Posted Whse. Receipt Header";
    begin
        PostedWarehouseReceiptHeader.SetCurrentKey("Whse. Receipt No.");
        PostedWarehouseReceiptHeader.SetLoadFields("No.");
        PostedWarehouseReceiptHeader.SetRange("Whse. Receipt No.", WarehouseReceiptLine."No.");
        PostedWarehouseReceiptHeader.FindFirst();
        WhseItemTrackingLine.SetRange("Source Type", DATABASE::"Posted Whse. Receipt Line");
        WhseItemTrackingLine.SetRange("Source Subtype", 0);
        WhseItemTrackingLine.SetRange("Source ID", PostedWarehouseReceiptHeader."No.");
    end;

    local procedure ReserveProductionOrderComponent(ItemNo: Code[20])
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange("Item No.", ItemNo);
        ProdOrderComponent.FindFirst();
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");  // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(false);
        ProdOrderComponent.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(LibraryInventory.GetReservConfirmText());  // Enqueue for MessageHandler.
        ProdOrderComponent.ShowReservation();
    end;

    local procedure ReserveQuantityAndPostTransferOrder(var TransferHeader: Record "Transfer Header")
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.FindFirst();
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");  // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(false);
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);  // Use 0 for Shipment Item Tracking.
        LibraryVariableStorage.Enqueue(LibraryInventory.GetReservConfirmText());
        TransferLine.ShowReservation();
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);
    end;

    local procedure RunBOMCostSharesPage(var Item: Record Item)
    var
        BOMCostShares: Page "BOM Cost Shares";
    begin
        BOMCostShares.InitItem(Item);
        BOMCostShares.Run();
    end;

    local procedure PlacePutawayToPickZoneDifferentBins(PurchaseOrderNo: Code[20])
    var
        Bin: Record Bin;
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLineWithActionType(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseOrderNo,
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Place);

        FindBin(Bin, WarehouseActivityLine."Location Code", false, true, true);

        Bin.FindSet();
        repeat
            WarehouseActivityLine.Validate("Zone Code", Bin."Zone Code");
            WarehouseActivityLine.Validate("Bin Code", Bin.Code);
            WarehouseActivityLine.Modify(true);
        until (WarehouseActivityLine.Next() = 0) and (Bin.Next() = 0);

        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseOrderNo, WarehouseActivityLine."Activity Type"::"Put-away");
    end;

    local procedure UpdateAlwaysCreatePickLineOnLocation(var Location: Record Location; var OldAlwaysCreatePickLine: Boolean; NewAlwaysCreatePickLine: Boolean)
    begin
        OldAlwaysCreatePickLine := Location."Always Create Pick Line";
        Location.Validate("Always Create Pick Line", NewAlwaysCreatePickLine);
        Location.Modify(true);
    end;

    local procedure UpdateBinOnProdOrderLine(ItemNo: Code[20]; BinCode: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst();
        ProdOrderLine.Validate("Bin Code", BinCode);
        ProdOrderLine.Modify(true);
    end;

    local procedure UpdateBinOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; BinCode: Code[20])
    begin
        PurchaseLine.Validate("Bin Code", BinCode);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateBinOnWarehouseActivityLine(Bin: Record Bin; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20];
                                                                                          ActivityType: Enum "Warehouse Activity Type";
                                                                                          ActionType: Enum "Warehouse Action Type")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.Validate("Zone Code", Bin."Zone Code");
            WarehouseActivityLine.Validate("Bin Code", Bin.Code);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure UpdateBinOnWarehouseActivityLinePage(WarehouseActivityLine: Record "Warehouse Activity Line"; BinCode: Code[20])
    var
        WarehousePick: TestPage "Warehouse Pick";
    begin
        WarehousePick.OpenEdit();
        WarehousePick.GotoKey(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        WarehousePick.WhseActivityLines."Bin Code".SetValue(BinCode);
    end;

    local procedure UpdateBinWithMaximumCubageAndWeight(var Bin: Record Bin; LocationCode: Code[10]; BinCode: Code[20]; MaximumCubage: Decimal; MaximumWeight: Decimal)
    begin
        Bin.SetRange("Location Code", LocationCode);
        Bin.SetRange(Code, BinCode);
        Bin.FindFirst();
        Bin.Validate("Maximum Cubage", MaximumCubage);
        Bin.Validate("Maximum Weight", MaximumWeight);
        Bin.Modify(true);
    end;

    local procedure UpdateBlockMovementOnBinContent(var BinContent: Record "Bin Content"; Bin: Record Bin; ItemNo: Code[20]; BlockMovement: Option)
    begin
        FindBinContent(BinContent, Bin, ItemNo);
        BinContent.FindFirst();
        BinContent.Validate("Block Movement", BlockMovement);
        BinContent.Modify(true);
    end;

    local procedure UpdateCubageAndWeightOnItemUOM(var ItemUnitOfMeasure: Record "Item Unit of Measure"; Item: Record Item; Length: Decimal; Weight: Decimal)
    begin
        ItemUnitOfMeasure.Get(Item."No.", Item."Base Unit of Measure");
        ItemUnitOfMeasure.Validate(Length, Length);
        ItemUnitOfMeasure.Validate(Width, Length);
        ItemUnitOfMeasure.Validate(Height, Length);
        ItemUnitOfMeasure.Validate(Weight, Weight);
        ItemUnitOfMeasure.Modify(true);
    end;

    local procedure UpdateDefaultLocationOnWarehouseEmployee(LocationCode: Code[20]) PreviousDefaultLocationCode: Code[20]
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.SetRange("User ID", UserId);
        WarehouseEmployee.SetRange(Default, true);
        WarehouseEmployee.FindFirst();
        WarehouseEmployee.Validate(Default, false);
        WarehouseEmployee.Modify(true);
        PreviousDefaultLocationCode := WarehouseEmployee."Location Code";

        WarehouseEmployee.SetRange(Default, false);
        WarehouseEmployee.SetRange("Location Code", LocationCode);
        WarehouseEmployee.FindFirst();
        WarehouseEmployee.Validate(Default, true);
        WarehouseEmployee.Modify(true);
    end;

    local procedure UpdateExpirationCalculationOnItem(var Item: Record Item)
    var
        ExpirationCalculation: DateFormula;
    begin
        Evaluate(ExpirationCalculation, Format(LibraryRandom.RandInt(5)) + 'M');  // Value required for test.
        Item.Validate("Expiration Calculation", ExpirationCalculation);
        Item.Modify(true);
    end;

    local procedure UpdateExpirationDateOnReservationEntry(ItemNo: Code[20])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.FindLast();
        ReservationEntry.Validate("Expiration Date", 0D);  // Value required for test.
        ReservationEntry.Modify(true);
    end;

    local procedure UpdateExpirationDateOnInventoryPutAway(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20]; ExpirationDate: Date)
    begin
        WarehouseActivityLine.SetRange("Expiration Date", 0D);
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", SourceNo,
          WarehouseActivityLine."Activity Type"::"Invt. Put-away");
        WarehouseActivityLine.Validate("Expiration Date", ExpirationDate);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure UpdateExpirationDateOnWhseItemTrackingLine(ItemNo: Code[20]; ExpirationDate: Date)
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
    begin
        WhseItemTrackingLine.SetRange("Item No.", ItemNo);
        WhseItemTrackingLine.FindFirst();
        WhseItemTrackingLine.Validate("Expiration Date", ExpirationDate);
        WhseItemTrackingLine.Modify(true);
    end;

    local procedure UpdatePickAccordingToFEFOOnLocation(var Location: Record Location; var OldPickAccordingToFEFO: Boolean; NewPickAccordingToFEFO: Boolean)
    begin
        OldPickAccordingToFEFO := Location."Pick According to FEFO";
        Location.Validate("Pick According to FEFO", NewPickAccordingToFEFO);
        Location.Modify(true);
    end;

    local procedure UpdateInventoryUsingWarehouseJournal(Bin: Record Bin; Item: Record Item; UnitOfMeasureCode: Code[10]; Quantity: Decimal; Tracking: Boolean; ItemTrackingModePar: Option; ExpirationDate: Date)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        LibraryWarehouse.WarehouseJournalSetup(Bin."Location Code", WarehouseJournalTemplate, WarehouseJournalBatch);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Bin."Location Code",
          Bin."Zone Code", '', WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
        WarehouseJournalLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        WarehouseJournalLine.Validate("Bin Code", Bin.Code);
        WarehouseJournalLine.Modify(true);
        if Tracking then begin
            LibraryVariableStorage.Enqueue(ItemTrackingModePar);  // Enqueue ItemTrackingMode for WhseItemTrackingLinesPageHandler.
            if ItemTrackingModePar = ItemTrackingMode::"Select Lot No." then
                LibraryVariableStorage.Enqueue(false);
            WarehouseJournalLine.OpenItemTrackingLines();
            if (ItemTrackingModePar = ItemTrackingMode::"Assign Lot No.") and (ExpirationDate <> 0D) then
                UpdateExpirationDateOnWhseItemTrackingLine(Item."No.", ExpirationDate)
        end;
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Bin."Location Code", true);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure UpdateItemUOM(var Item: Record Item; PurchUnitOfMeasure: Code[10]; SalesUnitOfMeasure: Code[10]; PutAwayUnitOfMeasureCode: Code[10])
    begin
        Item.Validate("Purch. Unit of Measure", PurchUnitOfMeasure);
        Item.Validate("Sales Unit of Measure", SalesUnitOfMeasure);
        Item.Validate("Put-away Unit of Measure Code", PutAwayUnitOfMeasureCode);
        Item.Modify(true);
    end;

    local procedure UpdateItemVariantOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; VariantCode: Code[10])
    begin
        PurchaseLine.Validate("Variant Code", VariantCode);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateLotNoOnWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; LotNo: Code[50])
    begin
        WarehouseActivityLine.Validate("Lot No.", LotNo);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure UpdateSerialNoOnWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SerialNo: Code[50])
    begin
        WarehouseActivityLine.Validate("Serial No.", SerialNo);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure UpdateTrackingNoOnWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ItemLedgerEntry: Record "Item Ledger Entry"; DocumentNo: Code[20]; ActionType: Enum "Warehouse Action Type"; Serial: Boolean;
                                                                                                                                                                                                            Lot: Boolean)
    begin
        FindWarehouseActivityLineForPick(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Prod. Consumption", DocumentNo,
          WarehouseActivityLine."Activity Type"::Pick, ActionType);
        if Serial then
            UpdateSerialNoOnWarehouseActivityLine(WarehouseActivityLine, ItemLedgerEntry."Serial No.");
        if Lot then
            UpdateLotNoOnWarehouseActivityLine(WarehouseActivityLine, ItemLedgerEntry."Lot No.");
    end;

    local procedure UpdateOrderTrackingPolicyAsTrackingOnlyOnItem(var Item: Record Item)
    begin
        Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking Only");
        Item.Modify(true);
    end;

    local procedure UpdateProductionBomAndRoutingOnItem(var Item: Record Item; ProductionBOMNo: Code[20]; RoutingNo: Code[20])
    begin
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify(true);
    end;

    local procedure UpdateReceiptBinOnLocation(Location: Record Location; ReceiptBinCode: Code[20])
    begin
        Location.Validate("Receipt Bin Code", ReceiptBinCode);
        Location.Modify(true);
    end;

    local procedure UpdateQuantityToHandleAndPostInventoryActivity(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20];
                                                                                       ActivityType: Enum "Warehouse Activity Type";
                                                                                       Partial: Boolean)
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.Validate("Qty. to Handle", WarehouseActivityLine.Quantity);
            if Partial then
                WarehouseActivityLine.Validate("Qty. to Handle", WarehouseActivityLine.Quantity / 2);  // Value required for test.
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;

        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, true);  // Post as Invoice.
    end;

    local procedure UpdateQuantityToHandleOnWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocumentType: Enum "Warehouse Activity Source Document"; SourceNo: Code[20];
                                                                                                                                                       Quantity: Decimal)
    begin
        FindWarehouseActivityLine(
          WarehouseActivityLine, SourceDocumentType, SourceNo, WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.Validate("Qty. to Handle", Quantity);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure UpdateQuantityToHandleOnWarehouseActivityLine2(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocumentType: Enum "Warehouse Activity Source Document"; SourceNo: Code[20];
                                                                                                                                                        ActionType: Enum "Warehouse Action Type";
                                                                                                                                                        Quantity: Decimal)
    begin
        FindWarehouseActivityLineForPick(
          WarehouseActivityLine, SourceDocumentType, SourceNo, WarehouseActivityLine."Activity Type"::Pick, ActionType);
        WarehouseActivityLine.Validate("Qty. to Handle", Quantity);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure UpdateQtyToHandleAndPostWarehouseShipmentForLot(var TransferHeader: Record "Transfer Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        i: Integer;
    begin
        // For Lot: it triggers error message when you process transfer order and try to post second time warehouse shipment for partial registered pick.
        // Here I should update Qty. to Handle and post Shipment for two times.
        for i := 1 to 2 do begin
            UpdateQuantityToHandleOnWarehouseActivityLine(
              WarehouseActivityLine, WarehouseShipmentLine."Source Document"::"Outbound Transfer", TransferHeader."No.", 1); // 1 is required for test.
            RegisterWarehouseActivity(
              WarehouseActivityLine."Source Document"::"Outbound Transfer",
              TransferHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
            LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false); // Use FALSE for only Shipment.
        end;
    end;

    local procedure UpdateQtyToHandleAndPostWarehouseShipmentForSerial(var TransferHeader: Record "Transfer Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        // For Serial: it triggers error message when you process transfer order and try to post first time warehouse shipment for partial registered pick.
        // Here I just update Qty. to Handle and post Shipment for one time.
        UpdateQuantityToHandleOnWarehouseActivityLine2(
          WarehouseActivityLine, WarehouseShipmentLine."Source Document"::"Outbound Transfer",
          TransferHeader."No.", WarehouseActivityLine."Action Type"::Take, 0); // 0 is required for test.
        UpdateQuantityToHandleOnWarehouseActivityLine2(
          WarehouseActivityLine, WarehouseShipmentLine."Source Document"::"Outbound Transfer",
          TransferHeader."No.", WarehouseActivityLine."Action Type"::Place, 0); // 0 is required for test.

        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Outbound Transfer",
          TransferHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false); // Use FALSE for only Shipment.
    end;

    local procedure UpdateQuantityToShipOnWarehouseShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; QuantityToShip: Decimal)
    begin
        WarehouseShipmentLine.Validate("Qty. to Ship", QuantityToShip);
        WarehouseShipmentLine.Modify(true);
    end;

    local procedure UpdateQtyToHandleOnWarehouseActivityLinesPair(var WarehouseActivityLineTake: Record "Warehouse Activity Line"; var WarehouseActivityLinePlace: Record "Warehouse Activity Line"; QtyToHandle: Decimal)
    begin
        WarehouseActivityLineTake.Validate("Qty. to Handle", QtyToHandle);
        WarehouseActivityLineTake.Modify(true);
        WarehouseActivityLinePlace.Validate("Qty. to Handle", QtyToHandle);
        WarehouseActivityLinePlace.Modify(true);
    end;

    local procedure VerifyBinContent(Bin: Record Bin; ItemNo: Code[20]; Quantity: Decimal; UnitOfMeasureCode: Code[10])
    var
        BinContent: Record "Bin Content";
    begin
        FindBinContent(BinContent, Bin, ItemNo);
        BinContent.FindFirst();
        BinContent.CalcFields(Quantity);
        BinContent.TestField(Quantity, Quantity);
        BinContent.TestField("Unit of Measure Code", UnitOfMeasureCode);
    end;

    local procedure VerifyItemLedgerEntry(EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20];
                                                         UnitOfMeasureCode: Code[10];
                                                         LocationCode: Code[10];
                                                         LotNo: Code[50];
                                                         Quantity: Decimal;
                                                         RemainingQuantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, EntryType, ItemNo, UnitOfMeasureCode);
        ItemLedgerEntry.TestField("Location Code", LocationCode);
        ItemLedgerEntry.TestField("Lot No.", LotNo);
        ItemLedgerEntry.TestField(Quantity, Quantity);
        ItemLedgerEntry.TestField("Remaining Quantity", RemainingQuantity);
    end;

    local procedure VerifyItemLedgerEntries(var ItemLedgerEntry: Record "Item Ledger Entry"; LocationCode: Code[10]; LotNo: Code[50]; Quantity: Decimal)
    begin
        ItemLedgerEntry.TestField("Location Code", LocationCode);
        ItemLedgerEntry.TestField("Lot No.", LotNo);
        ItemLedgerEntry.TestField(Quantity, Quantity);
        ItemLedgerEntry.Next();
    end;

    local procedure VerifyMovementLine(ActionType: Enum "Warehouse Action Type"; ItemNo: Code[20];
                                                       Quantity: Decimal;
                                                       QtyBase: Decimal;
                                                       UnitOfMeasureCode: Code[10];
                                                       LotNo: Code[50])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::" ", '', WarehouseActivityLine."Activity Type"::Movement);
        WarehouseActivityLine.TestField(Quantity, Quantity);
        WarehouseActivityLine.TestField("Qty. (Base)", QtyBase);
        WarehouseActivityLine.TestField("Unit of Measure Code", UnitOfMeasureCode);
        WarehouseActivityLine.TestField("Lot No.", LotNo);
    end;

    local procedure VerifyPostedInventoryPickLine(Bin: Record Bin; SourceNo: Code[20]; ItemNo: Code[20])
    var
        PostedInvtPickLine: Record "Posted Invt. Pick Line";
    begin
        PostedInvtPickLine.SetRange("Source No.", SourceNo);
        PostedInvtPickLine.SetRange("Location Code", Bin."Location Code");
        PostedInvtPickLine.SetRange("Bin Code", Bin.Code);
        PostedInvtPickLine.FindSet();
        repeat
            PostedInvtPickLine.TestField("Item No.", ItemNo);
            PostedInvtPickLine.TestField("Expiration Date", WorkDate());  // Value required for test.
            PostedInvtPickLine.TestField(Quantity, 1);  // Value required for test.
            PostedInvtPickLine.TestField("Lot No.");
            PostedInvtPickLine.TestField("Serial No.");
        until PostedInvtPickLine.Next() = 0;
    end;

    local procedure VerifyPostedWarehouseShipmentLine(SourceNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
    begin
        PostedWhseShipmentLine.SetRange("Source Document", PostedWhseShipmentLine."Source Document"::"Sales Order");
        PostedWhseShipmentLine.SetRange("Source No.", SourceNo);
        PostedWhseShipmentLine.SetRange("Item No.", ItemNo);
        PostedWhseShipmentLine.FindFirst();
        PostedWhseShipmentLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyRegisteredMovementLine(Bin: Record Bin; ActionType: Enum "Warehouse Action Type"; ItemNo: Code[20];
                                                                                  Quantity: Decimal;
                                                                                  LotNo: Code[50])
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        RegisteredWhseActivityLine.SetRange("Item No.", ItemNo);
        FindRegisteredWhseActivityLine(
          RegisteredWhseActivityLine, RegisteredWhseActivityLine."Source Document", '',
          RegisteredWhseActivityLine."Activity Type"::Movement, ActionType);
        RegisteredWhseActivityLine.TestField("Location Code", Bin."Location Code");
        RegisteredWhseActivityLine.TestField("Zone Code", Bin."Zone Code");
        RegisteredWhseActivityLine.TestField("Bin Code", Bin.Code);
        RegisteredWhseActivityLine.TestField(Quantity, Quantity);
        RegisteredWhseActivityLine.TestField("Lot No.", LotNo);
    end;

    local procedure VerifyRegisteredPickLines(ActionType: Enum "Warehouse Action Type"; SourceNo: Code[20];
                                                              ItemNo: Code[20])
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        FindRegisteredWhseActivityLine(
          RegisteredWhseActivityLine, RegisteredWhseActivityLine."Source Document"::"Sales Order", SourceNo,
          RegisteredWhseActivityLine."Activity Type"::Pick, ActionType);
        RegisteredWhseActivityLine.FindSet();
        repeat
            RegisteredWhseActivityLine.TestField("Item No.", ItemNo);
            RegisteredWhseActivityLine.TestField(Quantity, 1);  // Value required for Serial No. Item Tracking.
            RegisteredWhseActivityLine.TestField("Serial No.");
        until RegisteredWhseActivityLine.Next() = 0;
    end;

    local procedure VerifyRegisteredPickLinesWithData(var TempWarehouseEntry: Record "Warehouse Entry" temporary; ActionType: Enum "Warehouse Action Type"; SourceNo: Code[20])
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        InitialTotalQty: Decimal;
        BinCodeFilter: Text;
    begin
        FindRegisteredWhseActivityLine(
          RegisteredWhseActivityLine, RegisteredWhseActivityLine."Source Document"::"Outbound Transfer", SourceNo,
          RegisteredWhseActivityLine."Activity Type"::Pick, ActionType);
        InitialTotalQty := GetTotalBaseQtyOfData(TempWarehouseEntry, BinCodeFilter);
        Assert.AreEqual(
          InitialTotalQty, GetTotalBaseQty(RegisteredWhseActivityLine, BinCodeFilter), WrongTotalQtyErr);
    end;

    local procedure VerifyRegisteredWhseActivityLines(SalesLine: Record "Sales Line"; SameExpirationDate: Boolean)
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Quantity: Decimal;
    begin
        FindRegisteredWhseActivityLine(
          RegisteredWhseActivityLine, RegisteredWhseActivityLine."Source Document"::"Sales Order", SalesLine."Document No.",
          RegisteredWhseActivityLine."Activity Type"::Pick, RegisteredWhseActivityLine."Action Type"::Take);
        RegisteredWhseActivityLine.FindSet();
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Positive Adjmt.");
        ItemLedgerEntry.SetRange("Item No.", SalesLine."No.");
        ItemLedgerEntry.FindSet();
        if not SameExpirationDate then
            ItemLedgerEntry.Next();
        repeat
            RegisteredWhseActivityLine.TestField("Item No.", SalesLine."No.");
            RegisteredWhseActivityLine.TestField("Lot No.", ItemLedgerEntry."Lot No.");
            RegisteredWhseActivityLine.TestField("Expiration Date", ItemLedgerEntry."Expiration Date");
            Quantity += RegisteredWhseActivityLine."Qty. (Base)";
            ItemLedgerEntry.Next();
        until RegisteredWhseActivityLine.Next() = 0;
        Assert.AreEqual(SalesLine.Quantity, Quantity / SalesLine."Qty. per Unit of Measure", QuantityMustBeSame);
    end;

    local procedure VerifyRegisteredWhseActivityLine(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20];
                                                                         ActivityType: Enum "Warehouse Activity Type";
                                                                         ActionType: Enum "Warehouse Action Type";
                                                                         Quantity: Decimal;
                                                                         QtyBase: Decimal;
                                                                         UnitOfMeasureCode: Code[10])
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        FindRegisteredWhseActivityLine(RegisteredWhseActivityLine, SourceDocument, SourceNo, ActivityType, ActionType);
        RegisteredWhseActivityLine.TestField(Quantity, Quantity);
        RegisteredWhseActivityLine.TestField("Qty. (Base)", QtyBase);
        RegisteredWhseActivityLine.TestField("Unit of Measure Code", UnitOfMeasureCode);
    end;

    local procedure VerifyReservationEntry(ItemNo: Code[20]; LocationCode: Code[10]; LotNo: Code[50]; ReservationStatus: Enum "Reservation Status"; Quantity: Decimal;
                                                                                                                             UntrackedSurplus: Boolean)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Location Code", LocationCode);
        ReservationEntry.SetRange("Reservation Status", ReservationStatus);
        ReservationEntry.SetRange("Lot No.", LotNo);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Quantity (Base)", Quantity);
        ReservationEntry.TestField("Untracked Surplus", UntrackedSurplus);
    end;

    local procedure VerifyWarehouseEntry(EntryType: Option; ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20]; LotNo: Code[50]; Quantity: Decimal; QtyBase: Decimal)
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetRange("Entry Type", EntryType);
        WarehouseEntry.SetRange("Item No.", ItemNo);
        WarehouseEntry.SetRange("Unit of Measure Code", UnitOfMeasureCode);
        WarehouseEntry.SetRange("Lot No.", LotNo);
        WarehouseEntry.FindFirst();
        WarehouseEntry.TestField("Location Code", LocationCode);
        WarehouseEntry.TestField("Bin Code", BinCode);
        WarehouseEntry.TestField(Quantity, Quantity);
        WarehouseEntry.TestField("Qty. (Base)", QtyBase);
    end;

    local procedure VerifyPickLine(ActivityType: Enum "Warehouse Activity Type"; ActionType: Enum "Warehouse Action Type";
                                                     SourceDocument: Enum "Warehouse Activity Source Document";
                                                     SourceNo: Code[20];
                                                     ItemNo: Code[20];
                                                     UnitOfMeasureCode: Code[10];
                                                     LotNo: Code[50];
                                                     Quantity: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.SetRange("Lot No.", LotNo);
        WarehouseActivityLine.SetRange("Unit of Measure Code", UnitOfMeasureCode);
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        WarehouseActivityLine.TestField("Item No.", ItemNo);
        WarehouseActivityLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPickLines(ActionType: Enum "Warehouse Action Type"; SourceNo: Code[20];
                                                    ItemNo: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SourceNo,
          WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.TestField("Item No.", ItemNo);
            WarehouseActivityLine.TestField(Quantity, 1);  // Value required for Serial No. Item Tracking.
            WarehouseActivityLine.TestField("Serial No.");
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure VerifyWhseWorksheetLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; ItemNo: Code[20]; Quantity: Decimal; QtyBase: Decimal; UnitOfMeasureCode: Code[10])
    begin
        WhseWorksheetLine.SetRange("Item No.", ItemNo);
        WhseWorksheetLine.FindFirst();
        WhseWorksheetLine.TestField(Quantity, Quantity);
        WhseWorksheetLine.TestField("Qty. (Base)", QtyBase);
        WhseWorksheetLine.TestField("Unit of Measure Code", UnitOfMeasureCode);
    end;

    [Normal]
    local procedure VerifyWhseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; DocumentNo: Code[20]; LotNo: Code[50]; ActionType: Enum "Warehouse Action Type"; ExpQty: Decimal)
    begin
        WarehouseActivityLine.SetRange("Source Document", WarehouseActivityLine."Source Document"::"Inbound Transfer");
        WarehouseActivityLine.SetRange("Source No.", DocumentNo);
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.SetRange("Lot No.", LotNo);
        WarehouseActivityLine.FindFirst();
        Assert.AreEqual(1, WarehouseActivityLine.Count, WarehouseActivityLine.GetFilters);
        Assert.AreEqual(ExpQty, WarehouseActivityLine."Qty. (Base)", WarehouseActivityLine.GetFilters);
    end;

    local procedure VerifyBOMCostSharesPage(var BOMCostShares: TestPage "BOM Cost Shares")
    var
        UnitofMeasureCode: Variant;
        BOMUnitofMeasureCode: Variant;
        ItemNo: Variant;
        QtyPerParent: Variant;
        QtyPerTopItem: Variant;
        BOMLineQtyPer: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);
        LibraryVariableStorage.Dequeue(UnitofMeasureCode);
        LibraryVariableStorage.Dequeue(BOMUnitofMeasureCode);
        LibraryVariableStorage.Dequeue(QtyPerParent);
        LibraryVariableStorage.Dequeue(QtyPerTopItem);
        LibraryVariableStorage.Dequeue(BOMLineQtyPer);

        Assert.AreEqual(ItemNo, Format(BOMCostShares."No."), ItemNoErr);
        Assert.AreEqual(UnitofMeasureCode, Format(BOMCostShares."Unit of Measure Code"), UnitOfMeasureCodeErr);
        Assert.AreEqual(BOMUnitofMeasureCode, Format(BOMCostShares."BOM Unit of Measure Code"), UnitOfMeasureCodeErr);
        Assert.AreEqual(QtyPerParent, BOMCostShares."Qty. per Parent".AsDecimal(), QuantityErr);
        Assert.AreEqual(QtyPerTopItem, BOMCostShares."Qty. per Top Item".AsDecimal(), QuantityErr);
    end;

    local procedure VerifyWarehouseActivityLineActionPickActivityTake(var WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        Bin: Record Bin;
        MaxRankingBinCode: Code[20];
        FirstNotRankingBinCode: Code[20];
        LastBinCode: Code[20];
    begin
        Bin.SetRange("Location Code", WarehouseActivityLine."Location Code");
        Bin.SetRange("Zone Code", WarehouseActivityLine."Zone Code");

        Bin.SetFilter("Bin Ranking", '>%1', 0);
        Bin.FindFirst();
        MaxRankingBinCode := Bin.Code;

        Bin.SetFilter("Bin Ranking", '=%1', 0);
        Bin.FindFirst();
        FirstNotRankingBinCode := Bin.Code;

        Bin.FindLast();
        LastBinCode := Bin.Code;

        WarehouseActivityLine.SetRange("Bin Code", MaxRankingBinCode);
        Assert.RecordCount(WarehouseActivityLine, 1);

        WarehouseActivityLine.SetRange("Bin Code", FirstNotRankingBinCode);
        Assert.RecordCount(WarehouseActivityLine, 1);

        WarehouseActivityLine.SetRange("Bin Code", LastBinCode);
        Assert.RecordCount(WarehouseActivityLine, 2);
    end;

    local procedure UpdateQtyToHandleOnWarehouseActivityLinesPair(var WarehouseActivityLineTake: Record "Warehouse Activity Line"; var WarehouseActivityLinePlace: Record "Warehouse Activity Line"; QtyToHandleTake: Decimal; QtyToHandlePlace: Decimal)
    begin
        WarehouseActivityLineTake.Validate("Qty. to Handle", QtyToHandleTake);
        WarehouseActivityLineTake.Modify(true);
        WarehouseActivityLinePlace.Validate("Qty. to Handle", QtyToHandlePlace);
        WarehouseActivityLinePlace.Modify(true);
    end;

    local procedure FindWarehousePickTypeLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; ItemNo: Code[20];
                                                                                                                               ActivityType: Enum "Warehouse Activity Type";
                                                                                                                               ActionType: Enum "Warehouse Action Type")
    begin
        WarehouseActivityLine.Reset();
        WarehouseActivityLine.SetRange("Source Document", SourceDocument);
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.Findfirst();
    end;

    local procedure CreateAndReleaseSalesOrderAtLocationWithAdditionalUoM(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; UoMCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Unit of Measure Code", UoMCode);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateItemWithAdditionalUOMs(var Item: Record Item; var BaseUOMCode: Code[10]; var AltUOMCode: Code[10]; QtyPerAltUOM: Decimal)
    var
        AdditionalItemUOM: Record "Item Unit of Measure";
        BaseItemUnitOfMeasure: Record "Item Unit of Measure";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(AdditionalItemUOM, Item."No.", UnitOfMeasure.Code, QtyPerAltUOM);
        BaseItemUnitOfMeasure.Get(Item."No.", Item."Base Unit of Measure");
        BaseItemUnitOfMeasure.Validate("Qty. Rounding Precision", 1);
        BaseItemUnitOfMeasure.Modify(true);
        BaseUOMCode := Item."Base Unit of Measure";
        AltUOMCode := AdditionalItemUOM.Code;
    end;

    local procedure CreateItemWithMultipleUOM(var Item: Record Item; var BaseUnitOfMeasure: Record "Unit of Measure"; var UnitOfMeasure: Record "Unit of Measure"; QtyPerUnitOfMeasure: Decimal)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUnitOfMeasure);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", BaseUnitOfMeasure.Code, 1);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, QtyPerUnitOfMeasure);
    end;

    local procedure RunCalculateBinReplenishmentReport(LocationCode: Code[20]; ItemNo: code[20])
    var
        BinContent: Record "Bin Content";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        CalculateBinReplenishmentReport: Report "Calculate Bin Replenishment";
    begin
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Movement);
        LibraryWarehouse.SelectWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, LocationCode);
        CalculateBinReplenishmentReport.InitializeRequest(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name,
            LocationCode, true, true, false);
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.FindSet();
        CalculateBinReplenishmentReport.SetTableView(BinContent);
        CalculateBinReplenishmentReport.UseRequestPage(false);
        CalculateBinReplenishmentReport.Run();
    end;

    local procedure CheckBinContent(var BinContent: Record "Bin Content"; LocationCode: Code[20]; ItemNo: code[20])
    begin
        BinContent.Reset();
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Item No.", ItemNo);
        if BinContent.FindSet() then
            repeat
                BinContent.CalcFields(Quantity);
                Assert.AreNotEqual(0, BinContent.Quantity, BinContentQtyErr);
            until BinContent.Next() = 0;
    end;

    local procedure FindItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10]; ItemNo: Code[20])
    begin
        FilterItemJournalLine(ItemJournalLine, JournalTemplateName, JournalBatchName, ItemNo);
        ItemJournalLine.FindSet();
    end;

    local procedure FilterItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10]; ItemNo: Code[20])
    begin
        ItemJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        ItemJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        ItemJournalLine.SetRange("Item No.", ItemNo);
    end;

    local procedure CalculateWhseAdjustment(var ItemJournalBatch: Record "Item Journal Batch"; var Item: Record Item)
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Item, true);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
    end;

    local procedure CreateWarehouseItemJournalLine(LocationCode: Code[10]; ItemNo: Code[20]; RegisteringDate: Date; Bin: Record Bin; Qty: Decimal; UnitOfMesureCode: Code[10]; WarehouseJournalBatchRec: Record "Warehouse Journal Batch")
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        LibraryWarehouse.CreateWhseJournalLine(WarehouseJournalLine, WarehouseJournalBatchRec."Journal Template Name",
            WarehouseJournalBatchRec.Name, LocationCode, Bin."Zone Code", Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Qty);
        WarehouseJournalLine.Validate("Registering Date", RegisteringDate);
        WarehouseJournalLine.Validate("Unit of Measure Code", UnitOfMesureCode);
        WarehouseJournalLine.Modify(true);
    end;

    local procedure CreateWarehouseJournalBatch(var WarehouseJournalBatch: Record "Warehouse Journal Batch"; LocationCode: Code[10])
    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
    begin
        LibraryWarehouse.SelectWhseJournalTemplateName(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::Item);
        LibraryWarehouse.CreateWhseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Name, LocationCode);
    end;

    local procedure CreateBinContent(var BinContent: Record "Bin Content"; Bin: Record Bin; ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; MinQty: Decimal; MaxQty: Decimal; Fixed: Boolean; Default: Boolean)
    begin
        LibraryWarehouse.CreateBinContent(BinContent, Bin."Location Code", Bin."Zone Code", Bin.Code, ItemNo, '', UnitOfMeasureCode);
        BinContent.Validate(Fixed, Fixed);
        BinContent.Validate(Default, Default);
        BinContent.Validate("Bin Type Code", Bin."Bin Type Code");
        BinContent.Validate("Bin Ranking", Bin."Bin Ranking");
        BinContent.Validate("Min. Qty.", MinQty);
        BinContent.Validate("Max. Qty.", MaxQty);
        BinContent.Modify(true);
    end;

    local procedure UpdateItemUnitOfMeasure(Var ItemUnitOfMeasure: Record "Item Unit of Measure"; Height: Decimal; Width: Decimal; Length: Decimal)
    begin
        ItemUnitOfMeasure.Validate(Height, Height);
        ItemUnitOfMeasure.Validate(Width, Width);
        ItemUnitOfMeasure.Validate(Length, Length);
        ItemUnitOfMeasure.Modify(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        DequeueVariable: Variant;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        ItemTrackingMode := DequeueVariable;
        case ItemTrackingMode of
            ItemTrackingMode::"Assign Lot No.":
                ItemTrackingLines."Assign Lot No.".Invoke();
            ItemTrackingMode::"Select Lot No.":
                ItemTrackingLines."Lot No.".AssistEdit();
            ItemTrackingMode::"Select Entries":
                ItemTrackingLines."Select Entries".Invoke();
            ItemTrackingMode::"Assign Lot And Serial":
                begin
                    LibraryVariableStorage.Enqueue(true);
                    ItemTrackingLines."Assign Serial No.".Invoke();
                end;
            ItemTrackingMode::"Assign Serial No.":
                begin
                    LibraryVariableStorage.Enqueue(false);
                    ItemTrackingLines."Assign Serial No.".Invoke();
                end;
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesWithLotNoPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        DequeueLineHandleType: Variant;
        LotNo: Variant;
        QuantityBase: Variant;
        ItemTrackingLineHandleType: Option;
    begin
        LibraryVariableStorage.Dequeue(DequeueLineHandleType);
        ItemTrackingLineHandleType := DequeueLineHandleType;
        LibraryVariableStorage.Dequeue(LotNo);
        LibraryVariableStorage.Dequeue(QuantityBase);

        case ItemTrackingLineHandleType of
            ItemTrackingLineHandling::Create:
                begin
                    ItemTrackingLines.Last();
                    ItemTrackingLines.Next();
                    ItemTrackingLines."Lot No.".SetValue(LotNo);
                    ItemTrackingLines."Quantity (Base)".SetValue(QuantityBase);
                end;
            ItemTrackingLineHandling::"Use Existing":
                begin
                    ItemTrackingLines.FILTER.SetFilter("Lot No.", LotNo);
                    ItemTrackingLines.First();
                    ItemTrackingLines."Quantity (Base)".SetValue(QuantityBase);
                end;
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    var
        DequeueVariable: Variant;
        LastLotNo: Boolean;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        LastLotNo := DequeueVariable;
        if LastLotNo then
            ItemTrackingSummary.First();
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesPageHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    var
        DequeueVariable: Variant;
        OldLotNo: Code[50];
        Quantity: Decimal;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        ItemTrackingMode := DequeueVariable;
        case ItemTrackingMode of
            ItemTrackingMode::"Assign Lot No.":
                begin
                    WhseItemTrackingLines."Lot No.".SetValue(LibraryUtility.GenerateGUID());  // Use random Lot No. because value is not important for test.
                    WhseItemTrackingLines.Quantity.SetValue(WhseItemTrackingLines.Quantity3.AsDecimal());
                end;
            ItemTrackingMode::"Select Lot No.":
                begin
                    WhseItemTrackingLines."Lot No.".AssistEdit();
                    LibraryVariableStorage.Enqueue(WhseItemTrackingLines."Lot No.".Value);
                end;
            ItemTrackingMode::"Split Lot No.":
                begin
                    Quantity := WhseItemTrackingLines.Quantity3.AsDecimal() / 2;  // Value required for test.
                    LibraryVariableStorage.Dequeue(DequeueVariable);
                    OldLotNo := DequeueVariable;
                    FillWhseItemTrackingLines(WhseItemTrackingLines, OldLotNo, Quantity);
                    WhseItemTrackingLines.Next();
                    FillWhseItemTrackingLines(WhseItemTrackingLines, OldLotNo, Quantity);
                end;
            ItemTrackingMode::"Select Multiple Lot No.":
                begin
                    WhseItemTrackingLines."Lot No.".AssistEdit();
                    LibraryVariableStorage.Enqueue(true);
                    LibraryVariableStorage.Enqueue(WhseItemTrackingLines."Lot No.".Value);
                    WhseItemTrackingLines.Next();
                    WhseItemTrackingLines."Lot No.".AssistEdit();
                    LibraryVariableStorage.Enqueue(WhseItemTrackingLines."Lot No.".Value);
                end;
        end;
        WhseItemTrackingLines.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure CubageAndWeightExceedConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    var
        DequeueVariable: Variant;
        LocalConfirmMessage: Text[1024];
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        LocalConfirmMessage := DequeueVariable;
        Assert.IsTrue(StrPos(ConfirmMessage, LocalConfirmMessage) > 0, ConfirmMessage);
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        DequeueVariable: Variant;
        LocalMessage: Text[1024];
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        LocalMessage := DequeueVariable;
        Assert.IsTrue(StrPos(Message, LocalMessage) > 0, Message);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    var
        DequeueVariable: Variant;
        CreateNewLotNo: Boolean;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        CreateNewLotNo := DequeueVariable;
        EnterQuantityToCreate.CreateNewLotNo.SetValue(CreateNewLotNo);
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Reserve from Current Line".Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingListPageHandler(var ItemTrackingList: TestPage "Item Tracking List")
    begin
        ItemTrackingList.OK().Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure MenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerForMessageVerification(Question: Text[1024]; var Reply: Boolean)
    begin
        LibraryVariableStorage.Enqueue(Question);
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalHandler(var ProductionJournal: TestPage "Production Journal")
    begin
        LibraryVariableStorage.Enqueue(JournalLinesPostedMsg); // Required inside MessageHandler.
        ProductionJournal.Post.Invoke();
        ProductionJournal.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalUnitOfMeasureCodeErrorHandler(var ProductionJournal: TestPage "Production Journal")
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Item No.", ProductionJournal."Item No.".Value());
        ItemJournalLine.FindFirst();

        asserterror ProductionJournal.Post.Invoke();

        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(ItemJournalLine.FieldCaption("Unit of Measure Code"));
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure BOMCostSharesPageHandler(var BOMCostShares: TestPage "BOM Cost Shares")
    var
        UnitofMeasureCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(UnitofMeasureCode);
        Assert.AreEqual(UnitofMeasureCode, Format(BOMCostShares."Unit of Measure Code"), UnitOfMeasureCodeErr);
        BOMCostShares.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure MultipleBOMCostSharesPageHandler(var BOMCostShares: TestPage "BOM Cost Shares")
    begin
        VerifyBOMCostSharesPage(BOMCostShares);

        BOMCostShares.Expand(true);
        BOMCostShares.Next();
        VerifyBOMCostSharesPage(BOMCostShares);

        BOMCostShares.Expand(true);
        BOMCostShares.Next();
        VerifyBOMCostSharesPage(BOMCostShares);
        BOMCostShares.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemUOMHandler(var ItemUnitsofMeasure: TestPage "Item Units of Measure")
    begin
        ItemUnitsofMeasure.Code.AssertEquals(LibraryVariableStorage.DequeueText());
    end;

    [RequestPageHandler]
    procedure ChangeUOMRequestPageHandler(var WhseChangeUnitOfMeasure: TestRequestPage "Whse. Change Unit of Measure")
    begin
        WhseChangeUnitOfMeasure.UnitOfMeasureCode.SetValue(LibraryVariableStorage.DequeueText());
        WhseChangeUnitOfMeasure.OK().Invoke();
    end;
}
