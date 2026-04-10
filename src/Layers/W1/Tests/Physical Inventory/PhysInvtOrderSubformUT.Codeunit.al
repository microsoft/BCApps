codeunit 137462 "Phys. Invt. Order Subform UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Physical Inventory] [Order] [UI]
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;

    [Test]
    [HandlerFunctions('EditDimensionSetEntriesPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowDimensionPhysInventoryOrderSubform()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        DimensionSetEntry: Record "Dimension Set Entry";
        PhysicalInventoryOrderSubf: Page "Physical Inventory Order Subf.";
    begin
        // [SCENARIO] validate the ShowDimension function of Page - 5005352, Phys. Inventory Order Subform.
        // Setup.
        Initialize();
        CreatePhysInventoryOrder(PhysInvtOrderHeader, PhysInvtOrderLine);
        UpdatePhysInventoryOrderLine(PhysInvtOrderLine);
        CreateDimension(DimensionSetEntry);
        PhysInvtOrderLine."Dimension Set ID" := DimensionSetEntry."Dimension Set ID";
        PhysInvtOrderLine.Modify();

        // Exercise & Verify: Invoke ShowDimension function in Phys. Inventory Order Subform and verify correct values created in EditDimensionSetEntriesPageHandler.
        PhysicalInventoryOrderSubf.SetRecord(PhysInvtOrderLine);
        PhysInvtOrderLine.ShowDimensions();  // Invokes EditDimensionSetEntriesPageHandler.
    end;


    [Test]
    [HandlerFunctions('ExpInvtOrderTrackingPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowExpInvtOrderTrackingPhysInventoryOrderSubform()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        ExpInvtOrderTracking: Record "Exp. Invt. Order Tracking";
    begin
        // [SCENARIO] validate the ShowExpectPhysInvtTrackLines function of Page - 5005352, Phys. Inventory Order Subform.
        // Setup.
        Initialize();
        CreatePhysInventoryOrder(PhysInvtOrderHeader, PhysInvtOrderLine);
        UpdatePhysInventoryOrderLine(PhysInvtOrderLine);
        UpdateExpInvtOrderTrackingOnPhysInventoryOrderLine(ExpInvtOrderTracking, PhysInvtOrderLine."Document No.");

        // Enqueue value for use in ExpectPhysInvTrackListPageHandler.
        LibraryVariableStorage.Enqueue(PhysInvtOrderLine."Document No.");
        LibraryVariableStorage.Enqueue(ExpInvtOrderTracking."Lot No.");
        LibraryVariableStorage.Enqueue(ExpInvtOrderTracking."Package No.");

        // Exercise & Verify: Invoke ShowExpectPhysInvtTrackLines function and verify correct values in ExpectPhysInvTrackListPageHandler.
        PhysInvtOrderLine.ShowExpectPhysInvtTrackLines();  // Invokes ExpectPhysInvTrackListPageHandler.
    end;

    [Test]
    [HandlerFunctions('PhysInventoryRecordingLinesPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowPhysInvtRecordingLinesPhysInventoryOrderSubform()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
    begin
        // [SCENARIO] validate the ShowPhysInvtRecordLines function of Page - 5005352, Phys. Inventory Order Subform.
        // Setup.
        Initialize();
        CreatePhysInventoryOrder(PhysInvtOrderHeader, PhysInvtOrderLine);
        UpdatePhysInventoryOrderLine(PhysInvtOrderLine);
        CreatePhysInventoryRecording(PhysInvtRecordLine, PhysInvtOrderLine."Document No.");
        LibraryVariableStorage.Enqueue(PhysInvtOrderLine."Document No.");  // Enqueue value for use in PhysInventoryRecordingLinesPageHandler.

        // Exercise & Verify: Invoke ShowPhysInvtRecordLines function and verify correct values in PhysInventoryRecordingLinesPageHandler
        PhysInvtOrderLine.ShowPhysInvtRecordingLines();  // Invokes PhysInventoryRecordingLinesPageHandler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTRUE,PhysInvtOrderSubformExpectedQtyHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CalculateQtyExpectedPhysInventoryOrderSubform()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysicalInventoryOrderSubf: Page "Physical Inventory Order Subf.";
    begin
        // [SCENARIO] validate the CalculateQtyExpected function of Page - 5005352, Phys. Inventory Order Subform.
        // Setup.
        Initialize();
        CreatePhysInventoryOrder(PhysInvtOrderHeader, PhysInvtOrderLine);
        UpdatePhysInventoryOrderLine(PhysInvtOrderLine);
        LibraryVariableStorage.Enqueue(PhysInvtOrderLine."Item No.");  // Enqueue value for use in PhysInvtOrderSubformExpectedQtyHandler.

        // Exercise & Verify: Invoke CalculateQtyExpected function in Phys. Inventory Order Subform and verify correct values in PhysInvtOrderSubformExpectedQtyHandler.
        PhysicalInventoryOrderSubf.SetRecord(PhysInvtOrderLine);
        PhysicalInventoryOrderSubf.CalculateQtyExpected();
        PhysicalInventoryOrderSubf.Run();  // Invokes PhysInvtOrderSubformExpectedQtyHandler.
    end;

    [Test]
    [HandlerFunctions('PhysInventoryLedgerEntriesPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowPhysInvtLedgerEntriesPhysInventoryOrderSubform()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInventoryLedgerEntry: Record "Phys. Inventory Ledger Entry";
    begin
        // [SCENARIO] validate the ShowPhysInvtLedgerEntries function of Page - 5005352, Phys. Inventory Order Subform.
        // Setup.
        Initialize();
        CreatePhysInventoryOrder(PhysInvtOrderHeader, PhysInvtOrderLine);
        UpdatePhysInventoryOrderLine(PhysInvtOrderLine);
        CreatePhysInventoryLedgerEntry(PhysInventoryLedgerEntry, PhysInvtOrderLine."Document No.");
        PhysInventoryLedgerEntry."Item No." := PhysInvtOrderLine."Item No.";
        PhysInventoryLedgerEntry.Modify();

        // Enqueue values for use in PhysInventoryLedgerEntriesPageHandler.
        LibraryVariableStorage.Enqueue(PhysInvtOrderLine."Document No.");
        LibraryVariableStorage.Enqueue(PhysInvtOrderLine."Item No.");

        // Exercise & Verify: Invoke ShowPhysInvtLedgerEntries function and verify correct values in PhysInventoryLedgerEntriesPageHandler.
        PhysInvtOrderLine.ShowPhysInvtLedgerEntries();  // Invokes PhysInventoryLedgerEntriesPageHandler.
    end;

    [Test]
    [HandlerFunctions('ItemLedgerEntriesPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowItemLedgerEntriesPhysInventoryOrderSubform()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [SCENARIO] validate the ShowItemLedgerEntries function of Page - 5005352, Phys. Inventory Order Subform.
        // Setup.
        Initialize();
        CreatePhysInventoryOrder(PhysInvtOrderHeader, PhysInvtOrderLine);
        UpdatePhysInventoryOrderLine(PhysInvtOrderLine);
        CreateItemLedgerEntry(ItemLedgerEntry, PhysInvtOrderLine."Document No.");
        ItemLedgerEntry."Item No." := PhysInvtOrderLine."Item No.";
        ItemLedgerEntry."Location Code" := PhysInvtOrderLine."Location Code";
        ItemLedgerEntry.Modify();

        // Enqueue values for use in ItemLedgerEntriesPageHandler.
        LibraryVariableStorage.Enqueue(PhysInvtOrderLine."Document No.");
        LibraryVariableStorage.Enqueue(PhysInvtOrderLine."Item No.");

        // Exercise & Verify: Invoke ShowItemLedgerEntries function and verify correct values in ItemLedgerEntriesPageHandler.
        PhysInvtOrderLine.ShowItemLedgerEntries();  // invokes ItemLedgerEntriesPageHandler.
    end;

    [Test]
    [HandlerFunctions('BinContentsListPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowBinContentItemPhyInventoryOrderSubform()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
    begin
        // [SCENARIO] validate the ShowBinContentItem function of Page - 5005352, Phys. Inventory Order Subform.
        // Setup.
        Initialize();
        CreatePhysInventoryOrder(PhysInvtOrderHeader, PhysInvtOrderLine);
        UpdatePhysInventoryOrderLine(PhysInvtOrderLine);
        CreateBinContent(PhysInvtOrderLine);
        LibraryVariableStorage.Enqueue(PhysInvtOrderLine."Item No.");  // Enqueue value for use in BinContentsListPageHandler.

        // Exercise & Verify: Invoke ShowBinContentItem function and verify correct values in BinContentsListPageHandler.
        PhysInvtOrderLine.ShowBinContentItem();  // Invokes BinContentsListPageHandler.
    end;

    [Test]
    [HandlerFunctions('BinContentsListForBinPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowBinContentBinPhysInventoryOrderSubform()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        Location: Record Location;
    begin
        // [SCENARIO] validate the ShowBinContentBin function of Page - 5005352, Phys. Inventory Order Subform.
        // Setup.
        Initialize();
        CreatePhysInventoryOrder(PhysInvtOrderHeader, PhysInvtOrderLine);
        UpdatePhysInventoryOrderLine(PhysInvtOrderLine);
        Location.Code := LibraryUTUtility.GetNewCode10();
        Location.Init();
        if Location.Insert() then;
        PhysInvtOrderLine."Location Code" := Location.Code;
        PhysInvtOrderLine."Bin Code" := LibraryUTUtility.GetNewCode();
        PhysInvtOrderLine.Modify();
        CreateBinContent(PhysInvtOrderLine);

        // Enqueue values for use in BinContentsListForBinPageHandler.
        LibraryVariableStorage.Enqueue(PhysInvtOrderLine."Location Code");
        LibraryVariableStorage.Enqueue(PhysInvtOrderLine."Bin Code");
        LibraryVariableStorage.Enqueue(PhysInvtOrderLine."Item No.");

        // Exercise & Verify: Invoke ShowBinContentBin function and verify correct values in BinContentsListForBinPageHandler.
        PhysInvtOrderLine.ShowBinContentBin();  // Invokes BinContentsListForBinPageHandler.
    end;

    [Test]
    [HandlerFunctions('PhysInvtItemTrackListPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowItemTrackingLinesAllPhysInventoryOrderSubform()
    var
        TrackingType: Option All,Positive,Negative;
    begin
        // [SCENARIO] validate the ShowItemTrackingLines(Which) function of Page - 5005352, Phys. Inventory Order Subform.
        // Setup.
        Initialize();
        ShowItemTrackingLinesPhysInventoryOrderSubform(TrackingType::All);
    end;

    [Test]
    [HandlerFunctions('PhysInvtItemTrackListPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowItemTrackingLineNegativePhysInventoryOrderSubform()
    var
        TrackingType: Option All,Positive,Negative;
    begin
        // [SCENARIO] validate the ShowItemTrackingLines(Which) function of Page - 5005352, Phys. Inventory Order Subform.
        // Setup.
        Initialize();
        ShowItemTrackingLinesPhysInventoryOrderSubform(TrackingType::Negative);
    end;

    local procedure ShowItemTrackingLinesPhysInventoryOrderSubform(TrackingType: Option)
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        CreatePhysInventoryOrder(PhysInvtOrderHeader, PhysInvtOrderLine);
        UpdatePhysInventoryOrderLine(PhysInvtOrderLine);
        UpdatePhysInventoryOrderStatusToFinished(PhysInvtOrderHeader);
        CreateReservationEntry(ReservationEntry, PhysInvtOrderLine);

        // Enqueue values for use in PhysInvtItemTrackListPageHandler.
        LibraryVariableStorage.Enqueue(PhysInvtOrderLine."Item No.");
        LibraryVariableStorage.Enqueue(ReservationEntry."Lot No.");

        // Exercise & Verify: Invoke ShowItemTrackingLines(Which) function and verify correct values in PhysInvtItemTrackListPageHandler.
        PhysInvtOrderLine.ShowItemTrackingLines(TrackingType);  // Invokes PhysInvtItemTrackListPageHandler.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowItemTrackingLinesAllPhysInventoryOrderSubformError()
    var
        TrackingType: Option All,Positive,Negative;
    begin
        // [SCENARIO] validate the error in ShowItemTrackingLines(Which) function of Page - 5005352, Phys. Inventory Order Subform.
        // Setup.
        ShowItemTrackingLinesPhysInventoryOrderSubformError(TrackingType::All);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowItemTrackingLinesNegativePhysInventoryOrderSubformError()
    var
        TrackingType: Option All,Positive,Negative;
    begin
        // [SCENARIO] validate the error in ShowItemTrackingLines(Which) function of Page - 5005352, Phys. Inventory Order Subform.
        // Setup.
        ShowItemTrackingLinesPhysInventoryOrderSubformError(TrackingType::Negative);
    end;

    local procedure ShowItemTrackingLinesPhysInventoryOrderSubformError(TrackingType: Option)
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        ExpInvtOrderTracking: Record "Exp. Invt. Order Tracking";
    begin
        CreatePhysInventoryOrder(PhysInvtOrderHeader, PhysInvtOrderLine);
        UpdatePhysInventoryOrderLine(PhysInvtOrderLine);
        UpdateExpInvtOrderTrackingOnPhysInventoryOrderLine(ExpInvtOrderTracking, PhysInvtOrderLine."Document No.");

        // Exercise: Invoke ShowItemTrackingLines(Which) function in Phys. Inventory Order Line.
        asserterror PhysInvtOrderLine.ShowItemTrackingLines(TrackingType);

        // Verify: Verify the Error Code, Status must be equal to 'Finished' in Phys. Inventory Order when invoking ShowItemTrackingLines(Which) of Phys. Inventory Order Subform.
        Assert.ExpectedErrorCode('TestField');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PostPhysInvtOrderWithTwoRecordingLinesDifferentExpirationDates()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        Bin: Record Bin;
        Item: Record Item;
        LotNos: array[2] of Code[20];
        Qty: array[2] of Decimal;
    begin
        // [FEATURE] [Warehouse] [Item Tracking] [Expiration Date]
        // [SCENARIO 382436] Physical inventory order with two recording lines containing the same item with different lot nos. and expiration dates, should post entries with correct expiration dates

        Initialize();

        // [GIVEN] Item "I" with lot tracking and lot expiration date control
        CreateLocationWithBin(Bin);
        CreateItemWithLotExpirationTracking(Item);

        LotNos[1] := LibraryUTUtility.GetNewCode();
        LotNos[2] := LibraryUTUtility.GetNewCode();
        Qty[1] := LibraryRandom.RandInt(20);
        Qty[2] := LibraryRandom.RandInt(20);

        // [GIVEN] Post positive adjustment for item "I". Lot "L1" with expiration date "D1", quantity = "X1", and  lot "L2", having expiration date "D2", quantity = "X2"
        PostItemJournalWithLotExpirationDates(Item."No.", Bin."Location Code", Bin.Code, LotNos, Qty);

        // [GIVEN] Create physical inventory order for item "I"
        LibraryInventory.CreatePhysInvtOrderHeader(PhysInvtOrderHeader);
        CreatePhysInventoryOrderLineOnLocation(
          PhysInvtOrderLine, PhysInvtOrderHeader."No.", Item."No.", Bin."Location Code", Bin.Code);

        // [GIVEN] Create physical inventory recoring with lines for each lot no. Record new quantity "Y1" > "X1" for lot "L1", and "Y2" > "X2" for lot "L2"
        LibraryInventory.CreatePhysInvtRecordHeader(PhysInvtRecordHeader, PhysInvtOrderHeader."No.");
        CreatePhysInventoryRecordingLineWithLotNo(
          PhysInvtRecordLine, PhysInvtOrderLine, PhysInvtRecordHeader."Recording No.", Bin."Location Code", Bin.Code,
          Qty[1] + LibraryRandom.RandInt(10), LotNos[1]);
        CreatePhysInventoryRecordingLineWithLotNo(
          PhysInvtRecordLine, PhysInvtOrderLine, PhysInvtRecordHeader."Recording No.", Bin."Location Code", Bin.Code,
          Qty[2] + LibraryRandom.RandInt(10), LotNos[2]);

        // [GIVEN] Calculate expected quantity
        FinishPhysInvtRecording(PhysInvtRecordHeader);

        PhysInvtOrderLine.Find();
        PhysInvtOrderLine.CalcQtyAndTrackLinesExpected();
        PhysInvtOrderLine.Modify(true);

        // [GIVEN] Finish the physical inventory order
        FinishPhysInvtOrder(PhysInvtOrderHeader);

        // [WHEN] Post physical inventory order
        PostPhysInvtOrder(PhysInvtOrderHeader);

        // [THEN] Total quantity of lot "L1" on inventory is "Y1", expiration date is "D1" for all entries. Quantity of "L2" is "Y2", expiration date "D2".
        VerifyItemPhysicalInventory(Item."No.", LotNos[1], WorkDate() + 1);
        VerifyItemPhysicalInventory(Item."No.", LotNos[2], WorkDate() + 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VariantMandatoryBlocksPhysInvtRec()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemJournalLine: Record "Item Journal Line";
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
    begin
        // [SLICE] [Option to make entry of Variant Code mandatory where variants exist]
        // [Deliveriable] When Alicia posts an order for an item with variants, the no-variants-selected rule is respected depending on settings
        Initialize();

        // [GIVEN] Item with available variants and Item."Variant Mandatory if Exists" = Yes
        LibraryInventory.CreateItem(Item);
        Item.Validate("Variant Mandatory if Exists", Item."Variant Mandatory if Exists"::Yes);
        Item.Modify();
        LibraryInventory.CreateVariant(ItemVariant, Item);

        // [GIVEN] Post the item to inventory.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', 100);
        ItemJournalLine.Validate("Variant Code", ItemVariant.Code);
        ItemJournalLine.Modify();
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Physical inventory order is created and remaining quantity calculated
        LibraryInventory.CreatePhysInvtOrderHeader(PhysInvtOrderHeader);
        LibraryInventory.CreatePhysInvtOrderLine(PhysInvtOrderLine, PhysInvtOrderHeader."No.", Item."No.");
        PhysInvtOrderLine.CalcQtyAndTrackLinesExpected();
        PhysInvtOrderLine.Modify();

        // [GIVEN] A recording for the physical inventory is created and finished
        LibraryInventory.CreatePhysInvtRecordHeader(PhysInvtRecordHeader, PhysInvtOrderHeader."No.");
        LibraryInventory.CreatePhysInvtRecordLine(
          PhysInvtRecordLine, PhysInvtOrderLine, PhysInvtRecordHeader."Recording No.", 1);
        Codeunit.Run(CODEUNIT::"Phys. Invt. Rec.-Finish", PhysInvtRecordHeader);

        // [WHEN] Order status is "finished"
        Codeunit.Run(CODEUNIT::"Phys. Invt. Order-Finish", PhysInvtOrderHeader);
        PhysInvtOrderHeader.Get(PhysInvtOrderHeader."No.");

        // [WHEN] Header is posted
        asserterror Codeunit.Run(Codeunit::"Phys. Invt. Order-Post", PhysInvtOrderHeader);

        // [THEN] Error is thrown indicating the Variant Code is missing
        Assert.ExpectedError(PhysInvtRecordLine.FieldCaption(PhysInvtRecordLine."Variant Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VariantMandatoryAllowsPhysInvtRec()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemJournalLine: Record "Item Journal Line";
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
    begin
        // [SLICE] [Option to make entry of Variant Code mandatory where variants exist]
        // [Deliveriable] When Alicia posts an order for an item with variants, the no-variants-selected rule is respected depending on settings
        Initialize();

        // [GIVEN] Item with available variants and Item."Variant Mandatory if Exists" = Yes
        LibraryInventory.CreateItem(Item);
        Item.Validate("Variant Mandatory if Exists", Item."Variant Mandatory if Exists"::Yes);
        Item.Modify();
        LibraryInventory.CreateVariant(ItemVariant, Item);

        // [GIVEN] Post the item to inventory.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', 100);
        ItemJournalLine.Validate("Variant Code", ItemVariant.Code);
        ItemJournalLine.Modify();
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Physical inventory order is created with variant 
        LibraryInventory.CreatePhysInvtOrderHeader(PhysInvtOrderHeader);
        LibraryInventory.CreatePhysInvtOrderLine(PhysInvtOrderLine, PhysInvtOrderHeader."No.", Item."No.");
        PhysInvtOrderLine.Validate("Variant Code", ItemVariant.Code);
        PhysInvtOrderLine.Modify();

        // [GIVEN] A recording for the physical inventory is created with variant code and finished
        LibraryInventory.CreatePhysInvtRecordHeader(PhysInvtRecordHeader, PhysInvtOrderHeader."No.");
        LibraryInventory.CreatePhysInvtRecordLine(
          PhysInvtRecordLine, PhysInvtOrderLine, PhysInvtRecordHeader."Recording No.", 1);
        PhysInvtRecordLine.Validate("Variant Code", ItemVariant.Code);
        PhysInvtRecordLine.Modify();
        Codeunit.Run(CODEUNIT::"Phys. Invt. Rec.-Finish", PhysInvtRecordHeader);
        PhysInvtOrderLine.Get(PhysInvtOrderLine."Document No.", PhysInvtOrderLine."Line No.");

        // Calculated remaining quantity
        PhysInvtOrderLine.CalcQtyAndTrackLinesExpected();
        PhysInvtOrderLine.Modify();

        // [GIVEN] Order status is "finished"
        Codeunit.Run(CODEUNIT::"Phys. Invt. Order-Finish", PhysInvtOrderHeader);
        PhysInvtOrderHeader.Get(PhysInvtOrderHeader."No.");
        PhysInvtOrderLine.Get(PhysInvtOrderLine."Document No.", PhysInvtOrderLine."Line No.");

        // [WHEN] Order is posted
        Codeunit.Run(Codeunit::"Phys. Invt. Order-Post", PhysInvtOrderHeader);

        // [THEN] No error is thrown 
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyingShelfNoFromPhysInvtLineToRecordingLine()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        MakePhysInvtRecording: Report "Make Phys. Invt. Recording";
    begin
        // [FEATURE] [Phys. Inventory Recording] [Shelf] [UT]
        // [SCENARIO 335399] "Shelf No." is copied from Phys. Inventory Order Line to Phys. Inventory Recording Line.
        Initialize();

        LibraryInventory.CreatePhysInvtOrderHeader(PhysInvtOrderHeader);
        LibraryInventory.CreatePhysInvtOrderLine(PhysInvtOrderLine, PhysInvtOrderHeader."No.", LibraryInventory.CreateItemNo());
        PhysInvtOrderLine."Shelf No." := LibraryUtility.GenerateGUID();
        PhysInvtOrderLine.Modify();

        MakePhysInvtRecording.InsertRecordingHeader(PhysInvtOrderHeader);
        MakePhysInvtRecording.InsertRecordingLine(PhysInvtOrderLine);

        PhysInvtRecordLine.SetRange("Item No.", PhysInvtOrderLine."Item No.");
        PhysInvtRecordLine.FindFirst();
        PhysInvtRecordLine.TestField("Shelf No.", PhysInvtOrderLine."Shelf No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PopulatingUseItemTrackingAndShelfNoWhenCreatePhysInvtRecordingLine()
    var
        Item: Record Item;
        Location: Record Location;
        SKU: Record "Stockkeeping Unit";
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
    begin
        // [FEATURE] [Phys. Inventory Recording] [Shelf]
        // [SCENARIO 335399] "Shelf No." and "Use Item Tracking" are filled from SKU when you manually add phys. inventory recording line.
        Initialize();

        // [GIVEN] Lot-tracked item "I" with Shelf No. = "A".
        CreateItemWithLotExpirationTracking(Item);
        Item.Validate("Shelf No.", LibraryUtility.GenerateGUID());
        Item.Modify(true);

        // [GIVEN] Create SKU for item "I" on location "L". Set Shelf No. = "B" on the SKU.
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(SKU, Location.Code, Item."No.", '');
        SKU.Validate("Shelf No.", LibraryUtility.GenerateGUID());
        SKU.Modify(true);

        // [GIVEN] Create phys. inventory order.
        // [GIVEN] Create phys. inventory recording from the order. Set location code = "L".
        LibraryInventory.CreatePhysInvtOrderHeader(PhysInvtOrderHeader);
        LibraryInventory.CreatePhysInvtOrderLine(PhysInvtOrderLine, PhysInvtOrderHeader."No.", Item."No.");
        LibraryInventory.CreatePhysInvtRecordHeader(PhysInvtRecordHeader, PhysInvtOrderHeader."No.");
        PhysInvtRecordHeader.Validate("Location Code", Location.Code);
        PhysInvtRecordHeader.Modify(true);

        // [WHEN] Create phys. inventory recording line with item "I".
        LibraryInventory.CreatePhysInvtRecordLine(
          PhysInvtRecordLine, PhysInvtOrderLine, PhysInvtRecordHeader."Recording No.", LibraryRandom.RandInt(10));

        // [THEN] "Shelf No." = "B" on the phys. inventory recording line.
        // [THEN] "Use Item Tracking" = TRUE on the line.
        PhysInvtRecordLine.TestField("Shelf No.", SKU."Shelf No.");
        PhysInvtRecordLine.TestField("Use Item Tracking", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangingLocationOrVariantOnPhysInvtOrderLineLooksForProperSKU()
    var
        Item: Record Item;
        SKU: array[2] of Record "Stockkeeping Unit";
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
    begin
        // [FEATURE] [Shelf] [SKU] [UT]
        // [SCENARIO 335399] Shelf No. from a proper stockkeeping unit is picked on phys. inventory order line when you change item no., location code and variant code.
        Initialize();

        LibraryInventory.CreateItem(Item);
        Item.Validate("Shelf No.", LibraryUtility.GenerateGUID());
        Item.Modify(true);

        CreateSKU(SKU[1], Item."No.");
        CreateSKU(SKU[2], Item."No.");

        LibraryInventory.CreatePhysInvtOrderHeader(PhysInvtOrderHeader);
        LibraryInventory.CreatePhysInvtOrderLine(PhysInvtOrderLine, PhysInvtOrderHeader."No.", Item."No.");
        PhysInvtOrderLine.TestField("Shelf No.", Item."Shelf No.");

        PhysInvtOrderLine.Validate("Location Code", SKU[1]."Location Code");
        PhysInvtOrderLine.TestField("Shelf No.", Item."Shelf No.");

        PhysInvtOrderLine.Validate("Variant Code", SKU[1]."Variant Code");
        PhysInvtOrderLine.TestField("Shelf No.", SKU[1]."Shelf No.");

        PhysInvtOrderLine.Validate("Variant Code", SKU[2]."Variant Code");
        PhysInvtOrderLine.TestField("Shelf No.", Item."Shelf No.");

        PhysInvtOrderLine.Validate("Location Code", SKU[2]."Location Code");
        PhysInvtOrderLine.TestField("Shelf No.", SKU[2]."Shelf No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangingLocationOrVariantOnPhysInvtRecordingLineLooksForProperSKU()
    var
        Item: Record Item;
        SKU: array[2] of Record "Stockkeeping Unit";
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
    begin
        // [FEATURE] [Phys. Inventory Recording] [Shelf] [SKU] [UT]
        // [SCENARIO 335399] Shelf No. from a proper stockkeeping unit is picked on phys. inventory recording line when you change item no., location code and variant code.
        Initialize();

        CreateItemWithLotExpirationTracking(Item);
        Item.Validate("Shelf No.", LibraryUtility.GenerateGUID());
        Item.Modify(true);

        CreateSKU(SKU[1], Item."No.");
        CreateSKU(SKU[2], Item."No.");

        LibraryInventory.CreatePhysInvtOrderHeader(PhysInvtOrderHeader);
        LibraryInventory.CreatePhysInvtOrderLine(PhysInvtOrderLine, PhysInvtOrderHeader."No.", Item."No.");
        LibraryInventory.CreatePhysInvtRecordHeader(PhysInvtRecordHeader, PhysInvtOrderHeader."No.");
        LibraryInventory.CreatePhysInvtRecordLine(
          PhysInvtRecordLine, PhysInvtOrderLine, PhysInvtRecordHeader."Recording No.", LibraryRandom.RandInt(10));
        PhysInvtRecordLine.TestField("Shelf No.", Item."Shelf No.");

        PhysInvtRecordLine.Validate("Location Code", SKU[1]."Location Code");
        PhysInvtRecordLine.TestField("Shelf No.", Item."Shelf No.");

        PhysInvtRecordLine.Validate("Variant Code", SKU[1]."Variant Code");
        PhysInvtRecordLine.TestField("Shelf No.", SKU[1]."Shelf No.");

        PhysInvtRecordLine.Validate("Variant Code", SKU[2]."Variant Code");
        PhysInvtRecordLine.TestField("Shelf No.", Item."Shelf No.");

        PhysInvtRecordLine.Validate("Location Code", SKU[2]."Location Code");
        PhysInvtRecordLine.TestField("Shelf No.", SKU[2]."Shelf No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UseItemTrackingEditableOnPhysInvtRecordingLine()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        PhysInventoryRecording: TestPage "Phys. Inventory Recording";
    begin
        // [FEATURE] [Phys. Inventory Recording]
        // [SCENARIO 335399] "Use Item Tracking" field is editable on phys. inventory recording line.
        Initialize();

        LibraryInventory.CreatePhysInvtOrderHeader(PhysInvtOrderHeader);
        LibraryInventory.CreatePhysInvtOrderLine(PhysInvtOrderLine, PhysInvtOrderHeader."No.", LibraryInventory.CreateItemNo());
        LibraryInventory.CreatePhysInvtRecordHeader(PhysInvtRecordHeader, PhysInvtOrderHeader."No.");
        LibraryInventory.CreatePhysInvtRecordLine(
          PhysInvtRecordLine, PhysInvtOrderLine, PhysInvtRecordHeader."Recording No.", LibraryRandom.RandInt(10));

        PhysInventoryRecording.OpenEdit();
        PhysInventoryRecording.FILTER.SetFilter("Order No.", PhysInvtRecordHeader."Order No.");
        Assert.IsTrue(PhysInventoryRecording.Lines."Use Item Tracking".Editable(), '');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Phys. Invt. Order Subform UT");
        LibraryVariableStorage.Clear();
        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Phys. Invt. Order Subform UT");

        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Phys. Invt. Order Subform UT");
    end;

    local procedure CreatePhysInventoryLedgerEntry(var PhysInventoryLedgerEntry: Record "Phys. Inventory Ledger Entry"; DocumentNo: Code[20])
    begin
        PhysInventoryLedgerEntry."Entry No." := SelectPhysInventoryLedgerEntryNo();
        PhysInventoryLedgerEntry."Document No." := DocumentNo;
        PhysInventoryLedgerEntry."Posting Date" := WorkDate();
        PhysInventoryLedgerEntry.Insert();
    end;

    local procedure CreateItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; DocumentNo: Code[20])
    begin
        ItemLedgerEntry."Entry No." := SelectItemLedgerEntryNo();
        ItemLedgerEntry."Document No." := DocumentNo;
        ItemLedgerEntry."Posting Date" := WorkDate();
        ItemLedgerEntry.Insert();
    end;

    local procedure CreatePhysInventoryOrder(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
        PhysInvtOrderHeader."No." := LibraryUTUtility.GetNewCode();
        PhysInvtOrderHeader."Posting Date" := WorkDate();
        PhysInvtOrderHeader.Insert();

        PhysInvtOrderLine."Document No." := PhysInvtOrderHeader."No.";
        PhysInvtOrderLine."Line No." := 1;
        PhysInvtOrderLine."Item No." := CreateItem();
        PhysInvtOrderLine.Insert();
    end;

    local procedure CreatePhysInventoryOrderLineOnLocation(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; PhysInventoryOrderNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20])
    begin
        LibraryInventory.CreatePhysInvtOrderLine(PhysInvtOrderLine, PhysInventoryOrderNo, ItemNo);
        PhysInvtOrderLine.Validate("Location Code", LocationCode);
        PhysInvtOrderLine.Validate("Bin Code", BinCode);
        PhysInvtOrderLine.Modify(true);
    end;

    local procedure CreatePhysInventoryRecording(var PhysInvtRecordLine: Record "Phys. Invt. Record Line"; OrderNo: Code[20])
    begin
        PhysInvtRecordLine."Order No." := OrderNo;
        PhysInvtRecordLine."Order Line No." := 1;
        PhysInvtRecordLine.Quantity := 1;
        PhysInvtRecordLine.Recorded := true;
        PhysInvtRecordLine.Insert();
    end;

    local procedure CreatePhysInventoryRecordingLineWithLotNo(var PhysInvtRecordLine: Record "Phys. Invt. Record Line"; PhysInvtOrderLine: Record "Phys. Invt. Order Line"; RecordingNo: Integer; LocationCode: Code[10]; BinCode: Code[20]; Qty: Decimal; LotNo: Code[50])
    begin
        LibraryInventory.CreatePhysInvtRecordLine(PhysInvtRecordLine, PhysInvtOrderLine, RecordingNo, 1);
        PhysInvtRecordLine.Validate("Location Code", LocationCode);
        PhysInvtRecordLine.Validate("Bin Code", BinCode);
        PhysInvtRecordLine.Validate("Lot No.", LotNo);
        PhysInvtRecordLine.Validate("Quantity (Base)", Qty);
        PhysInvtRecordLine.Modify(true);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        Item."No." := LibraryUTUtility.GetNewCode();
        Item.Insert();
        exit(Item."No.");
    end;

    local procedure CreateItemWithLotExpirationTracking(var Item: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryInventory.CreateItemTrackingCode(ItemTrackingCode);
        ItemTrackingCode.Validate("Lot Specific Tracking", true);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", true);
        ItemTrackingCode.Validate("Use Expiration Dates", true);
        ItemTrackingCode.Validate("Man. Expir. Date Entry Reqd.", true);
        ItemTrackingCode.Modify(true);

        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCode.Code);
    end;

    local procedure CreateSKU(var SKU: Record "Stockkeeping Unit"; ItemNo: Code[20])
    var
        Location: Record Location;
        ItemVariant: Record "Item Variant";
    begin
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateItemVariant(ItemVariant, ItemNo);
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(SKU, Location.Code, ItemNo, ItemVariant.Code);
        SKU.Validate("Shelf No.", LibraryUtility.GenerateGUID());
        SKU.Modify(true);
    end;

    local procedure CreateDimension(var DimensionSetEntry: Record "Dimension Set Entry")
    var
        DimensionValue: Record "Dimension Value";
        DimensionSetEntry2: Record "Dimension Set Entry";
    begin
        DimensionValue.Code := LibraryUTUtility.GetNewCode();
        DimensionValue."Dimension Code" := LibraryUTUtility.GetNewCode();
        DimensionValue.Insert();
        LibraryVariableStorage.Enqueue(DimensionValue.Code);  // Enqueue value for use in EditDimensionSetEntriesPageHandler.
        DimensionSetEntry2.FindLast();
        CreateDimensionSetEntry(DimensionSetEntry,
          DimensionSetEntry2."Dimension Set ID" + LibraryRandom.RandInt(10), DimensionSetEntry."Dimension Code", DimensionValue.Code);  // Should be greater than available Dimension Set ID.
    end;

    local procedure CreateLocationWithBin(var Bin: Record Bin)
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Modify(true);
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUTUtility.GetNewCode(), '', '');
    end;

    local procedure CreateReservationEntry(var ReservationEntry: Record "Reservation Entry"; PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
        ReservationEntry."Entry No." := SelectReservationEntryNo();
        ReservationEntry."Source Type" := DATABASE::"Phys. Invt. Order Line";
        ReservationEntry."Source ID" := PhysInvtOrderLine."Document No.";
        ReservationEntry."Source Ref. No." := PhysInvtOrderLine."Line No.";
        ReservationEntry."Item No." := PhysInvtOrderLine."Item No.";
        ReservationEntry."Lot No." := LibraryUTUtility.GetNewCode();
        ReservationEntry.Insert();
    end;

    local procedure CreateDimensionSetEntry(var DimensionSetEntry: Record "Dimension Set Entry"; DimensionSetID: Integer; DimensionCode: Code[20]; DimensionValueCode: Code[20])
    begin
        DimensionSetEntry."Dimension Set ID" := DimensionSetID;
        DimensionSetEntry."Dimension Code" := DimensionCode;
        DimensionSetEntry."Dimension Value Code" := DimensionValueCode;
        DimensionSetEntry.Insert();
    end;

    local procedure CreateBinContent(var PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    var
        BinContent: Record "Bin Content";
    begin
        BinContent."Item No." := PhysInvtOrderLine."Item No.";
        BinContent."Location Code" := PhysInvtOrderLine."Location Code";
        BinContent."Bin Code" := PhysInvtOrderLine."Bin Code";
        BinContent.Insert();
    end;

    local procedure PostItemJournalWithLotExpirationDates(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; LotNos: array[2] of Code[20]; Qty: array[2] of Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
        I: Integer;
        TotalQty: Decimal;
    begin
        for I := 1 to ArrayLen(Qty) do
            TotalQty += Qty[I];

        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, BinCode, TotalQty);

        LibraryVariableStorage.Enqueue(ArrayLen(LotNos));

        for I := 1 to ArrayLen(LotNos) do begin
            LibraryVariableStorage.Enqueue(LotNos[I]);
            LibraryVariableStorage.Enqueue(Qty[I]);
        end;

        ItemJournalLine.OpenItemTrackingLines(false);

        for I := 1 to ArrayLen(LotNos) do
            UpdateLotExpirationDate(ItemNo, LotNos[I], WorkDate() + I);

        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure FinishPhysInvtOrder(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header")
    begin
        CODEUNIT.Run(CODEUNIT::"Phys. Invt. Order-Finish", PhysInvtOrderHeader);
    end;

    local procedure FinishPhysInvtRecording(PhysInvtRecordHeader: Record "Phys. Invt. Record Header")
    begin
        CODEUNIT.Run(CODEUNIT::"Phys. Invt. Rec.-Finish", PhysInvtRecordHeader);
    end;

    local procedure PostPhysInvtOrder(PhysInvtOrderHeader: Record "Phys. Invt. Order Header")
    begin
        CODEUNIT.Run(CODEUNIT::"Phys. Invt. Order-Post", PhysInvtOrderHeader);
    end;

    local procedure SelectPhysInventoryLedgerEntryNo(): Integer
    var
        PhysInventoryLedgerEntry: Record "Phys. Inventory Ledger Entry";
    begin
        if PhysInventoryLedgerEntry.FindLast() then
            exit(PhysInventoryLedgerEntry."Entry No." + 1);
        exit(1);
    end;

    local procedure SelectItemLedgerEntryNo(): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        if ItemLedgerEntry.FindLast() then
            exit(ItemLedgerEntry."Entry No." + 1);
        exit(1);
    end;

    local procedure SelectReservationEntryNo(): Integer
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        if ReservationEntry.FindLast() then
            exit(ReservationEntry."Entry No." + 1);
        exit(1);
    end;

    local procedure UpdateLotExpirationDate(ItemNo: Code[20]; LotNo: Code[50]; NewExpirationDate: Date)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Lot No.", LotNo);
        ReservationEntry.ModifyAll("Expiration Date", NewExpirationDate, true);
    end;

    local procedure UpdatePhysInventoryOrderLine(var PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
        PhysInvtOrderLine."Entry Type" := PhysInvtOrderLine."Entry Type"::"Positive Adjmt.";
        PhysInvtOrderLine."Use Item Tracking" := true;
        PhysInvtOrderLine."Qty. Expected (Base)" := 1;
        PhysInvtOrderLine."On Recording Lines" := true;
        PhysInvtOrderLine."Qty. Exp. Calculated" := true;
        PhysInvtOrderLine.Modify();
    end;

    local procedure UpdatePhysInventoryOrderStatusToFinished(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header")
    begin
        PhysInvtOrderHeader.Status := PhysInvtOrderHeader.Status::Finished;
        PhysInvtOrderHeader.Modify();
    end;

    local procedure UpdateExpInvtOrderTrackingOnPhysInventoryOrderLine(var ExpInvtOrderTracking: Record "Exp. Invt. Order Tracking"; OrderNo: Code[20])
    begin
        ExpInvtOrderTracking."Order No" := OrderNo;
        ExpInvtOrderTracking."Order Line No." := 1;
        ExpInvtOrderTracking."Serial No." := LibraryUTUtility.GetNewCode();
        ExpInvtOrderTracking."Lot No." := LibraryUTUtility.GetNewCode();
        ExpInvtOrderTracking."Package No." := LibraryUTUtility.GetNewCode();
        ExpInvtOrderTracking."Quantity (Base)" := 1;
        ExpInvtOrderTracking.Insert();
    end;

    local procedure VerifyItemPhysicalInventory(ItemNo: Code[20]; LotNo: Code[50]; ExpirationDate: Date)
    var
        PstdPhysInvtRecordLine: Record "Pstd. Phys. Invt. Record Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        PstdPhysInvtRecordLine.SetRange("Item No.", ItemNo);
        PstdPhysInvtRecordLine.SetRange("Lot No.", LotNo);
        PstdPhysInvtRecordLine.FindFirst();

        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Lot No.", LotNo);
        ItemLedgerEntry.CalcSums(Quantity);
        ItemLedgerEntry.TestField(Quantity, PstdPhysInvtRecordLine.Quantity);
        ItemLedgerEntry.FindSet();
        repeat
            ItemLedgerEntry.TestField("Expiration Date", ExpirationDate);
        until ItemLedgerEntry.Next() = 0;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EditDimensionSetEntriesPageHandler(var EditDimensionSetEntries: TestPage "Edit Dimension Set Entries")
    var
        DimensionValueCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(DimensionValueCode);
        EditDimensionSetEntries.DimensionValueCode.AssertEquals(DimensionValueCode);
        EditDimensionSetEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ExpInvtOrderTrackingPageHandler(var ExpInvtOrderTracking: TestPage "Exp. Invt. Order Tracking")
    var
        OrderNo: Variant;
        LotNo: Variant;
        PackageNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(OrderNo);
        LibraryVariableStorage.Dequeue(LotNo);
        LibraryVariableStorage.Dequeue(PackageNo);
        ExpInvtOrderTracking."Order No".AssertEquals(OrderNo);
        ExpInvtOrderTracking."Lot No.".AssertEquals(LotNo);
        ExpInvtOrderTracking."Package No.".AssertEquals(PackageNo);
        ExpInvtOrderTracking.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PhysInventoryRecordingLinesPageHandler(var PhysInvtRecordingLines: TestPage "Phys. Invt. Recording Lines")
    var
        OrderNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(OrderNo);
        PhysInvtRecordingLines."Order No.".AssertEquals(OrderNo);
        PhysInvtRecordingLines.Recorded.AssertEquals(true);
        PhysInvtRecordingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PhysInventoryLedgerEntriesPageHandler(var PhysInventoryLedgerEntries: TestPage "Phys. Inventory Ledger Entries")
    var
        DocumentNo: Variant;
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        LibraryVariableStorage.Dequeue(ItemNo);
        PhysInventoryLedgerEntries."Document No.".AssertEquals(DocumentNo);
        PhysInventoryLedgerEntries."Item No.".AssertEquals(ItemNo);
        PhysInventoryLedgerEntries.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PhysInvtOrderSubformExpectedQtyHandler(var PhysicalInventoryOrderSubf: TestPage "Physical Inventory Order Subf.")
    var
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);
        PhysicalInventoryOrderSubf."Item No.".AssertEquals(ItemNo);
        PhysicalInventoryOrderSubf."Qty. Expected (Base)".AssertEquals(0);  // Qty Expected Base not calculated.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemLedgerEntriesPageHandler(var ItemLedgerEntries: TestPage "Item Ledger Entries")
    var
        DocumentNo: Variant;
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        LibraryVariableStorage.Dequeue(ItemNo);
        ItemLedgerEntries."Document No.".AssertEquals(DocumentNo);
        ItemLedgerEntries."Item No.".AssertEquals(ItemNo);
        ItemLedgerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure BinContentsListPageHandler(var BinContentsList: TestPage "Bin Contents List")
    var
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);
        BinContentsList."Item No.".AssertEquals(ItemNo);
        BinContentsList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure BinContentsListForBinPageHandler(var BinContentsList: TestPage "Bin Contents List")
    var
        ItemNo: Variant;
        BinCode: Variant;
        LocationCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(LocationCode);
        LibraryVariableStorage.Dequeue(BinCode);
        LibraryVariableStorage.Dequeue(ItemNo);
        BinContentsList."Location Code".AssertEquals(LocationCode);
        BinContentsList."Bin Code".AssertEquals(BinCode);
        BinContentsList."Item No.".AssertEquals(ItemNo);
        BinContentsList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PhysInvtItemTrackListPageHandler(var PhysInvtItemTrackList: TestPage "Phys. Invt. Item Track. List")
    var
        ItemNo: Variant;
        LotNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);
        LibraryVariableStorage.Dequeue(LotNo);
        PhysInvtItemTrackList."Item No.".AssertEquals(ItemNo);
        PhysInvtItemTrackList."Lot No.".AssertEquals(LotNo);
        PhysInvtItemTrackList.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTRUE(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        I: Integer;
    begin
        for I := 1 to LibraryVariableStorage.DequeueInteger() do begin
            ItemTrackingLines.New();
            ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
            ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
        end;
    end;
}

