codeunit 137460 "Phys. Invt. Item Tracking"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Physical Inventory]
        isInitialized := false;
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        isInitialized: Boolean;
        AlreadyExistsErr: Label 'already exists';
        CurrentSaveValuesId: Integer;
        RoundingTo0Err: Label 'Rounding of the field';
        RoundingErr: Label 'is of lower precision than expected';
        LinesCreatedMsg: Label '%1 new lines have been created.', Comment = '%1 = counter';
        BlockedItemMsg: Label 'There is at least one blocked item or item variant that was skipped.';//'There is at least one blocked item that was skipped.';

    [Test]
    [HandlerFunctions('CalcPhysOrderLinesRequestPageHandler,CalculateQuantityExpectedStrMenuHandler,ConfirmHandlerTRUE,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostedPhysInventoryOrderWithoutTrackingPositive()
    var
        Location: Record Location;
        Item: Record Item;
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
    begin
        // [SCENARIO] "Pos. Qty. (Base)" in posted order shows difference if recorded quantity is greater than expected quantity.
        Initialize();
        // [GIVEN] Phys. Inventory Order with for one Item (without item tracking), where "Qty. Expected (Base)" is 5.
        // [GIVEN] Finished Recording, where "Quantity" is 7
        CreatePhysInventoryOrderWithFinishedRecording(PhysInvtOrderHeader, Item, Location, 5, 7);

        // [WHEN] Finish Phys. Inventory Order and post it.
        FinishAndPostPhysInventoryOrder(PhysInvtOrderHeader);

        // [THEN] Posted Phys. Inventory Order, where "Pos. Qty. (Base)" is 2, "Neg. Qty. (Base)" is 0
        VerifyPostedPosNegQtyInOrderLine(PhysInvtOrderHeader."Posting No.", Item."No.", Location.Code, 2, 0);
    end;

    [Test]
    [HandlerFunctions('CalcPhysOrderLinesRequestPageHandler,CalculateQuantityExpectedStrMenuHandler,ConfirmHandlerTRUE,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostedPhysInventoryOrderWithoutTrackingNegative()
    var
        Location: Record Location;
        Item: Record Item;
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
    begin
        // [SCENARIO] "Neg. Qty. (Base)" in posted order shows difference if recorded quantity is smaller than expected quantity .
        Initialize();
        // [GIVEN] Phys. Inventory Order with for one Item (without item tracking), where "Qty. Expected (Base)" is 3.
        // [GIVEN] Finished Recording, where "Quantity" is 1.
        CreatePhysInventoryOrderWithFinishedRecording(PhysInvtOrderHeader, Item, Location, 3, 1);

        // [WHEN] Finish Phys. Inventory Order and post it.
        FinishAndPostPhysInventoryOrder(PhysInvtOrderHeader);

        // [THEN] Posted Phys. Inventory Order, where "Pos. Qty. (Base)" is 0, "Neg. Qty. (Base)" is 2
        VerifyPostedPosNegQtyInOrderLine(PhysInvtOrderHeader."Posting No.", Item."No.", Location.Code, 0, 2);
    end;

    [Test]
    [HandlerFunctions('PhysInventoryOrderLinesPageHandler,ConfirmHandlerTRUE')]
    [Scope('OnPrem')]
    procedure PhysInventoryOrderShowDuplicateLine()
    var
        Item: Record Item;
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
    begin
        // Setup.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreatePhysInventoryOrderHeader(PhysInvtOrderHeader, '');  // Location is blank.
        CreatePhysInventoryLine(PhysInvtOrderLine, PhysInvtOrderHeader."No.", Item."No.");
        CreatePhysInventoryLine(PhysInvtOrderLine, PhysInvtOrderHeader."No.", Item."No.");  // Create second Phys. Inventory Order Line.

        // Exercise & Verify: Show Duplicate Phys. Inventory Order Line. Verify the Duplicate Line in PhysInventoryOrderLinesPageHandler.
        LibraryVariableStorage.Enqueue(PhysInvtOrderLine."Item No.");
        ShowDuplicatePhysInventoryLine(PhysInvtOrderHeader."No.");
    end;

    [Test]
    [HandlerFunctions('PostedPhysInvtOrderDiffReportHandler,ConfirmHandlerTRUE')]
    [Scope('OnPrem')]
    procedure PostAndPrintPhysInventoryOrderLine()
    var
        Item: Record Item;
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
    begin
        // Setup.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreatePhysInventoryOrderHeader(PhysInvtOrderHeader, '');  // Location is blank.
        CreatePhysInventoryLine(PhysInvtOrderLine, PhysInvtOrderHeader."No.", Item."No.");
        CODEUNIT.Run(CODEUNIT::"Phys. Invt. Order-Finish (Y/N)", PhysInvtOrderHeader);  // Finish Phys. Inventory Order.

        // [WHEN] Post and Print Phys. Inventory Order.
        CODEUNIT.Run(CODEUNIT::"Phys. Invt. Order-Post + Print", PhysInvtOrderHeader);

        // [THEN] Verify Posted Phys. Inventory Order Line. Verify the Location Code is blank.
        VerifyPostedPhysInventoryOrderLine(PhysInvtOrderHeader."No.", Item."No.", '');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,CalcPhysOrderLinesRequestPageHandler,CalculateQuantityExpectedStrMenuHandler,ConfirmHandlerTRUE,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostedPhysInventoryOrderWithMaxDescriptionItem()
    var
        Item: Record Item;
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
    begin
        // [FEATURE] [Item Tracking]
        // [GIVEN] Create Item with max length Description and Description2, Create Phys. Inventory Header.
        Initialize();
        CreateItemWithMaxLengthDescription(Item);
        LibraryVariableStorage.Enqueue(false); // Enqueue value for use in ItemTrackingPageHandler.
        CreateAndPostItemJournalLine('', Item."No.", false); // Set Location to blank.
        CreatePhysInventoryOrderHeader(PhysInvtOrderHeader, '');

        // Exercise and Verify: Calculate Phys. Inventory Order Line and verify no overflow errors pop up.
        CalculatePhysInventoryLine(PhysInvtOrderHeader, '', Item."No.");

        // Exercise and Verify: Verify Phys. Inventory Recording can be created successfully as no overflow errors pop up.
        CreatePhysInventoryRecordingWithTracking(
          PhysInvtRecordLine, PhysInvtOrderHeader, PhysInvtOrderLine, Item."No.", LibraryRandom.RandDec(10, 2));
        FinishPhysInventoryRecording(PhysInvtRecordLine, PhysInvtOrderHeader."No."); // Change Phys. Inventory Recording Status to Finished.

        // Exercise and Verify: Finish Phys. Inventory Order, verify it can be posted successfully and no overflow errors pop up
        // when Description and Description2 are copied to Posted phys. Invt. Order and Posted phys. Invt. Recording page.
        FinishAndPostPhysInventoryOrder(PhysInvtOrderHeader);

        // [THEN] The Description and Description2 fields of Item on Posted phys. Invt. Order and Posted phys. Invt. Recording page.
        VerifyDescriptionOnPostedPhysInventoryOrderLine(PhysInvtOrderHeader."No.", Item.Description, Item."Description 2");
        VerifyDescriptionOnPostedPhysInventoryRecordingLine(Item);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSetSerialNoPageHandler,CalcPhysOrderLinesRequestPageHandler,CalculateQuantityExpectedStrMenuHandler,ConfirmHandlerTRUE,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostInventoryWithTwoIdenticalSerialNo()
    var
        Item: Record Item;
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        NewPhysInvtRecordLine: Record "Phys. Invt. Record Line";
        BinContent: Record "Bin Content";
        BinCode: array[2] of Code[20];
        SN: array[2] of Code[20];
    begin
        // [FEATURE] [Inventory Recording] [Item Tracking]
        // [SCENARIO 257226] The same "Serial No." can be processed twice in inventory recording if an item is moving from one bin to another.
        Initialize();

        // [GIVEN] Item with "Serial No." "SN1" is stored at bin "Bin1", with "Serial No." "SN2" at bin "Bin2"
        CreatePhysInventoryOfSNTrackingItem(PhysInvtOrderHeader, Item, BinCode, SN);

        // [GIVEN] Inventory Order and Recording with 3 lines "L1" - "L3" are created
        // [GIVEN] "L1" contains "Bin1", "SN1", Quantity 1
        FindAndUpdatePhysInvtRecordingLine(PhysInvtRecordLine, Item."No.", BinCode[1], BinCode[1], SN[1], 1);

        // [GIVEN] "L2" contains "Bin2", "SN2", Quantity 0
        FindAndUpdatePhysInvtRecordingLine(PhysInvtRecordLine, Item."No.", BinCode[2], BinCode[2], SN[2], 0);

        // [GIVEN] "L3" contains "Bin1", "SN2", Quantity 1
        CopyPhysInvtRecordingLine(NewPhysInvtRecordLine, PhysInvtRecordLine);
        UpdatePhysInvtRecordingLine(NewPhysInvtRecordLine, BinCode[1], SN[2], 1);

        // [WHEN] Finish recording and "IO" and post "IO"
        FinishPhysInventoryRecording(PhysInvtRecordLine, PhysInvtOrderHeader."No.");
        FinishAndPostPhysInventoryOrder(PhysInvtOrderHeader);

        // [THEN] Quantities of Bin Content for "I" are 1 for "Bin1" and "SN1" and 1 for "Bin1" and "SN2"
        VerifyBinContent(Item, PhysInvtOrderHeader."Location Code", BinCode[1], SN[1], 1);
        VerifyBinContent(Item, PhysInvtOrderHeader."Location Code", BinCode[1], SN[2], 1);

        // [THEN] Bin Content for "Bin2" doesn't present
        BinContent.SetRange("Item No.", Item."No.");
        BinContent.SetRange("Location Code", PhysInvtOrderHeader."Location Code");
        BinContent.SetRange("Bin Code", BinCode[2]);
        Assert.RecordIsEmpty(BinContent);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSetSerialNoPageHandler,CalcPhysOrderLinesRequestPageHandler,CalculateQuantityExpectedStrMenuHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryRecordingExcessingSerialNoError()
    var
        Item: Record Item;
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        BinCode: array[2] of Code[20];
        SN: array[2] of Code[20];
    begin
        // [FEATURE] [Inventory Recording] [Item Tracking]
        // [SCENARIO 257226] When try to post excessing "Serial No." in "Phys. Invt. Record Line" error "Serial No. XXXXXX for item XXXXXX already exists." occurs.
        Initialize();

        // [GIVEN] Item with "Serial No." "SN1" is stored at bin "Bin1", with "Serial No." "SN2" at bin "Bin2"
        CreatePhysInventoryOfSNTrackingItem(PhysInvtOrderHeader, Item, BinCode, SN);

        // [GIVEN] Inventory Order and Recording with 2 lines "L1", "L2" are created
        // [GIVEN] "L1" contains "Bin1", "SN1", Quantity 1
        FindAndUpdatePhysInvtRecordingLine(PhysInvtRecordLine, Item."No.", BinCode[1], BinCode[1], SN[1], 1);

        // [WHEN] Try to set "SN1" and Quantity 1 to "L2"
        FindPhysInvtRecordingLine(PhysInvtRecordLine, Item."No.", BinCode[2]);
        asserterror UpdatePhysInvtRecordingLine(PhysInvtRecordLine, BinCode[2], SN[1], 1);

        // [THEN] Error "Serial No. XXXXXX for item XXXXXX already exists." occurs
        Assert.ExpectedError(AlreadyExistsErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CalcPhysInvtOrderLinesWhenLastUsedBinDeleted()
    var
        Location: Record Location;
        Bin: Record Bin;
        ItemJournalLine: Record "Item Journal Line";
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        ItemNo: Code[20];
        ExpectedQty: Integer;
    begin
        // [SCENARIO 311486] When last used Bin is deleted then report Calc. Phys. Invt. Order Lines generates lines for existing Bins, and no error
        Initialize();
        ItemNo := LibraryInventory.CreateItemNo();
        ExpectedQty := LibraryRandom.RandInt(10);

        // [GIVEN] Location with Bins "B1" and B2"
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Modify(true);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 2, false);

        // [GIVEN] Bin "B1" had 10 PCS of Item
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 1);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, Location.Code, Bin.Code, ExpectedQty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Positive and Negative Adjustments each for 5 PCS of the Item and Bin "B2"
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 2);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, Location.Code, Bin.Code, LibraryRandom.RandInt(10));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, Location.Code, Bin.Code, ItemJournalLine.Quantity);
        ItemJournalLine.Validate("Entry Type", ItemJournalLine."Entry Type"::"Negative Adjmt.");
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Bin "B2" was deleted
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 2); // required to prevent error when Bin is deleted
        Bin.Delete(true);
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 1);

        // [GIVEN] Phys. Invt. Order
        LibraryInventory.CreatePhysInvtOrderHeader(PhysInvtOrderHeader);

        // [WHEN] Run report Calc. Phys. Invt. Order Lines for the Item with Calc. Qty. Expected enabled
        CalculatePhysInvtOrderLines(PhysInvtOrderHeader, ItemNo, '', true, true, false);

        // [THEN] Phys. Invt. Order Line is created with 10 PCS and Bin "B1"
        PhysInvtOrderLine.SetRange("Document No.", PhysInvtOrderHeader."No.");
        Assert.RecordCount(PhysInvtOrderLine, 1);
        PhysInvtOrderLine.FindFirst();
        PhysInvtOrderLine.TestField("Bin Code", Bin.Code);
        PhysInvtOrderLine.TestField("Qty. Expected (Base)", ExpectedQty);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CalcPhysInvtOrderBinsWhenLastUsedBinDeleted()
    var
        Location: Record Location;
        Bin: Record Bin;
        ItemJournalLine: Record "Item Journal Line";
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        ItemNo: Code[20];
    begin
        // [SCENARIO 311486] When last used Bin is deleted then report Calc. Phys. Invt. Order Bins generates lines for existing Bin, and no error
        Initialize();
        ItemNo := LibraryInventory.CreateItemNo();

        // [GIVEN] Location with Bins "B1" and B2"
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Modify(true);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 2, false);

        // [GIVEN] Bin "B1" had 10 PCS of Item
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 1);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, Location.Code, Bin.Code, LibraryRandom.RandInt(10));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Positive and Negative Adjustments each for 5 PCS of the Item and Bin "B2"
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 2);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, Location.Code, Bin.Code, LibraryRandom.RandInt(10));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, Location.Code, Bin.Code, ItemJournalLine.Quantity);
        ItemJournalLine.Validate("Entry Type", ItemJournalLine."Entry Type"::"Negative Adjmt.");
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Bin "B2" was deleted
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 2); // required to prevent error when Bin is deleted
        Bin.Delete(true);
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 1);

        // [GIVEN] Phys. Invt. Order
        LibraryInventory.CreatePhysInvtOrderHeader(PhysInvtOrderHeader);

        // [WHEN] Run report Calc. Phys. Invt. Order Bins for the Item with Calc. Qty. Expected enabled
        RunCalcPhysInvtOrderBins(PhysInvtOrderHeader, Bin);

        // [THEN] Phys. Invt. Order Line is created with Bin "B1"
        PhysInvtOrderLine.SetRange("Document No.", PhysInvtOrderHeader."No.");
        Assert.RecordCount(PhysInvtOrderLine, 1);
        PhysInvtOrderLine.FindFirst();
        PhysInvtOrderLine.TestField("Bin Code", Bin.Code);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerValidateText')]
    procedure CalcPhysInvtBinMultipleWhseEntriesWithoutWarning()
    var
        Location: Record Location;
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        Bin: Record Bin;
        ItemNo: Code[20];
        I: Integer;
    begin
        // [FEATURE] [Warehouse] [Bin] [Order]
        // [SCENARIO] No warning on calc. physical inventory order on bins when the item is not blocked

        Initialize();

        // [GIVEN] Warehouse location with one bin "B"; item "I"
        CreateLocationAndBin(Location, true);
        ItemNo := LibraryInventory.CreateItemNo();
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 1);

        // [GIVEN] Post 3 separate positive adjustment entries for item "I" on bin "B"
        for I := 1 to 3 do
            CreateAndPostItemJournalLineWithoutTracking(Location.Code, ItemNo, Bin.Code, LibraryRandom.RandInt(100));

        // [GIVEN] Create a physical inventory order
        LibraryInventory.CreatePhysInvtOrderHeader(PhysInvtOrderHeader);

        // [WHEN] Run "Calc. Phys. Invt. Order (Bins)" for the bin "B"
        // [THEN] Message is displayed informing that one order line was created
        LibraryVariableStorage.Enqueue(StrSubstNo(LinesCreatedMsg, 1));
        RunCalcPhysInvtOrderBins(PhysInvtOrderHeader, Bin);

        // [THEN] One physical inventory order line exists for item "I"
        PhysInvtOrderLine.SetRange("Item No.", ItemNo);
        Assert.RecordCount(PhysInvtOrderLine, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerValidateText')]
    procedure CalcPhysInvtBinBlockedItemWarning()
    var
        Location: Record Location;
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        Item: array[2] of Record Item;
        Bin: Record Bin;
        I: Integer;
    begin
        // [FEATURE] [Warehouse] [Bin] [Order]
        // [SCENARIO] Calc. Phys. Invt. Order (Bins) report displays a warning if an item is blocked

        Initialize();

        // [GIVEN] Warehouse location with one bin "B"; two items "I1" and "I2"
        CreateLocationAndBin(Location, true);
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 1);

        // [GIVEN] Post positive adjustment for items "I1" and "I2" on the bin "B"
        for I := 1 to ArrayLen(Item) do begin
            LibraryInventory.CreateItem(Item[I]);
            CreateAndPostItemJournalLineWithoutTracking(Location.Code, Item[I]."No.", Bin.Code, LibraryRandom.RandInt(100));
        end;

        // [GIVEN] Block item "I2"
        Item[2].Find();
        Item[2].Validate(Blocked, true);
        Item[2].Modify(true);

        // [GIVEN] Create a physical inventory order
        LibraryInventory.CreatePhysInvtOrderHeader(PhysInvtOrderHeader);

        // [WHEN] Run "Calc. Phys. Invt. Order (Bins)" for the bin "B"
        // [THEN] Message is displayed informing that there are blocked items that have been skipped
        // [THEN] Message is displayed informing that one order line was created
        LibraryVariableStorage.Enqueue(BlockedItemMsg);
        LibraryVariableStorage.Enqueue(StrSubstNo(LinesCreatedMsg, 1));
        RunCalcPhysInvtOrderBins(PhysInvtOrderHeader, Bin);

        // [THEN] One physical inventory order line exists for item "I1"
        PhysInvtOrderLine.SetRange("Item No.", Item[1]."No.");
        Assert.RecordCount(PhysInvtOrderLine, 1);

        // [THEN] No physical inventory order lines exist for item "I2"
        PhysInvtOrderLine.SetRange("Item No.", Item[2]."No.");
        Assert.RecordIsEmpty(PhysInvtOrderLine);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,CalcPhysOrderLinesRequestPageHandler,CalculateQuantityExpectedStrMenuHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ErrorThrownWhenBaseQtyIsRoundedTo0OnPhysInvtRecordLine()
    var
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        BaseUOM: Record "Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        // [SCENARIO] Error is thrown when base quantity is rounded to 0
        Initialize();

        // [GIVEN] Item with two unit of measures and Physical Inventory
        QtyRoundingPrecision := Round(1 / LibraryRandom.RandIntInRange(2, 10), 0.00001);
        NonBaseQtyPerUOM := Round(LibraryRandom.RandInt(5), QtyRoundingPrecision);
        CreateItemWithLotTrackingAndPhysInventory(PhysInvtRecordLine, BaseUOM, NonBaseUOM, NonBaseQtyPerUOM, QtyRoundingPrecision);
        PhysInvtRecordLine.Validate("Unit of Measure Code", NonBaseUOM.Code);

        // [WHEN] Quantity is set to a number that will round the base quantity to 0
        asserterror PhysInvtRecordLine.Validate(Quantity, 1 / LibraryRandom.RandIntInRange(100, 1000));

        // [THEN] Error is thrown
        Assert.ExpectedError(RoundingTo0Err);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,CalcPhysOrderLinesRequestPageHandler,CalculateQuantityExpectedStrMenuHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ErrorThrownWhenQtyIsRoundedTo0OnPhysInvtRecordLine()
    var
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        BaseUOM: Record "Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        // [SCENARIO] Error is thrown when quantity is rounded to 0
        Initialize();

        // [GIVEN] Item with two unit of measures and Physical Inventory
        QtyRoundingPrecision := Round(1 / LibraryRandom.RandIntInRange(2, 10), 0.00001);
        NonBaseQtyPerUOM := Round(LibraryRandom.RandInt(5), QtyRoundingPrecision);
        CreateItemWithLotTrackingAndPhysInventory(PhysInvtRecordLine, BaseUOM, NonBaseUOM, NonBaseQtyPerUOM, QtyRoundingPrecision);
        PhysInvtRecordLine.Validate("Unit of Measure Code", BaseUOM.Code);

        // [WHEN] Quantity is set to a number that will get rounded to 0
        asserterror PhysInvtRecordLine.Validate(Quantity, 1 / LibraryRandom.RandIntInRange(100, 1000));

        // [THEN] Error is thrown
        Assert.ExpectedError(RoundingErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,CalcPhysOrderLinesRequestPageHandler,CalculateQuantityExpectedStrMenuHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BaseQtyIsRoundedWithRoundingPrecisionSpecifiedOnPhysInvtRecordLine()
    var
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        BaseUOM: Record "Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        // [SCENARIO] Base quantity is rounded with the specified rounding precision
        Initialize();

        // [GIVEN] Item with two unit of measures and Physical Inventory
        QtyRoundingPrecision := Round(1 / LibraryRandom.RandIntInRange(2, 10), 0.00001);
        NonBaseQtyPerUOM := Round(LibraryRandom.RandInt(5), QtyRoundingPrecision);
        CreateItemWithLotTrackingAndPhysInventory(PhysInvtRecordLine, BaseUOM, NonBaseUOM, NonBaseQtyPerUOM, QtyRoundingPrecision);
        PhysInvtRecordLine.Validate("Unit of Measure Code", NonBaseUOM.Code);

        // [WHEN] Quantity is set to a number
        PhysInvtRecordLine.Validate(Quantity, LibraryRandom.RandDecInDecimalRange(5, 10, 2));

        // [THEN] Base quantity is rounded using the specified rounding precision
        Assert.AreEqual(Round(PhysInvtRecordLine.Quantity * NonBaseQtyPerUOM, QtyRoundingPrecision), PhysInvtRecordLine."Quantity (Base)", 'Base quantity is not rounded correctly.');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,CalcPhysOrderLinesRequestPageHandler,CalculateQuantityExpectedStrMenuHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BaseQtyIsRoundedWithRoundingPrecisionUnspecifiedOnPhysInvtRecordLine()
    var
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        BaseUOM: Record "Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
        QtyToSet: Decimal;
    begin
        // [SCENARIO] Base quantity is rounded with the default rounding precision
        Initialize();

        // [GIVEN] Item with two unit of measures and Physical Inventory
        QtyRoundingPrecision := 0;
        NonBaseQtyPerUOM := LibraryRandom.RandInt(5);
        CreateItemWithLotTrackingAndPhysInventory(PhysInvtRecordLine, BaseUOM, NonBaseUOM, NonBaseQtyPerUOM, QtyRoundingPrecision);
        PhysInvtRecordLine.Validate("Unit of Measure Code", NonBaseUOM.Code);

        // [WHEN] Quantity is set to a number
        QtyToSet := LibraryRandom.RandDecInDecimalRange(5, 10, 6);
        PhysInvtRecordLine.Validate(Quantity, QtyToSet);

        // [THEN] Quantity is rounded with the default rounding precision
        Assert.AreEqual(Round(QtyToSet, 0.00001), PhysInvtRecordLine.Quantity, 'Qty. is not rounded correctly.');

        // [THEN] Base quantity is rounded using the default rounding precision
        Assert.AreEqual(Round(PhysInvtRecordLine.Quantity * NonBaseQtyPerUOM, 0.00001), PhysInvtRecordLine."Quantity (Base)", 'Base quantity is not rounded correctly.');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,CalcPhysOrderLinesRequestPageHandler,CalculateQuantityExpectedStrMenuHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BaseQtyIsRoundedWithRoundingPrecisionOnPhysInvtRecordLine()
    var
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        BaseUOM: Record "Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        // [SCENARIO] Base quantity is rounded with the specified rounding precision
        Initialize();

        // [GIVEN] Item with two unit of measures and Physical Inventory
        QtyRoundingPrecision := Round(1 / LibraryRandom.RandIntInRange(2, 10), 0.00001);
        NonBaseQtyPerUOM := Round(LibraryRandom.RandIntInRange(5, 10), QtyRoundingPrecision);
        CreateItemWithLotTrackingAndPhysInventory(PhysInvtRecordLine, BaseUOM, NonBaseUOM, NonBaseQtyPerUOM, QtyRoundingPrecision);
        PhysInvtRecordLine.Validate("Unit of Measure Code", NonBaseUOM.Code);

        // [WHEN] Quantity is set to a number that will round the base quantity to a number closer to max
        PhysInvtRecordLine.Validate(Quantity, (NonBaseQtyPerUOM - 1) / NonBaseQtyPerUOM);

        // [THEN] Base quantity is rounded using the specified rounding precision
        Assert.AreEqual(Round(NonBaseQtyPerUOM - 1, QtyRoundingPrecision), PhysInvtRecordLine."Quantity (Base)", 'Base quantity is not rounded correctly.');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ConfirmHandlerTRUE,MessageHandler')]
    procedure NegativeRecordingWithItemTrackingFromLocationWithBin()
    var
        Location: Record Location;
        Item: Record Item;
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        LotNo: Code[50];
    begin
        // [FEATURE] [Item Tracking] [Warehouse]
        // [SCENARIO 402604] Stan can post physical inventory order for negative adjustment with item tracking at location with mandatory bin.
        Initialize();

        // [GIVEN] Lot-tracked item.
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Post 20 pcs of the item to inventory, assign lot no. "L".
        LibraryVariableStorage.Enqueue(false);
        CreateLocation(Location, Item."No.", true);
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Positive Adjmt.", Item."No.");
        LotNo := ItemLedgerEntry."Lot No.";

        // [GIVEN] Create physical inventory order, calculate lines.
        LibraryInventory.CreatePhysInvtOrderHeader(PhysInvtOrderHeader);
        CalculatePhysInvtOrderLines(PhysInvtOrderHeader, Item."No.", '', true, true, false);

        // [GIVEN] Create phys. inventory recording for 15 pcs, select lot no. "L".
        // [GIVEN] Finish the recording.
        CreatePhysInventoryRecordingWithTracking(
          PhysInvtRecordLine, PhysInvtOrderHeader, PhysInvtOrderLine, Item."No.", LibraryRandom.RandInt(10));
        FinishPhysInventoryRecording(PhysInvtRecordLine, PhysInvtOrderHeader."No.");

        // [WHEN] Finish and post the phys. inventory order (negative adjustment for 5 pcs).
        FinishAndPostPhysInventoryOrder(PhysInvtOrderHeader);

        // [THEN] The physical inventory order is successfully posted.
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Negative Adjmt.", Item."No.");
        ItemLedgerEntry.TestField("Lot No.", LotNo);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ConfirmHandlerTRUE,MessageHandler')]
    procedure PostPhysInventoryOrderWithPositiveNegativeAdjustmentLine()
    var
        Location: Record Location;
        Item: Record Item;
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtRecordLine: array[2] of Record "Phys. Invt. Record Line";
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PstdPhysInvtOrderHeader: Record "Pstd. Phys. Invt. Order Hdr";
        Bin: Record Bin;
        PhysInvtCalcQtyOne: Codeunit "Phys. Invt.-Calc. Qty. One";
        BinCode: array[2] of Code[20];
    begin
        // [SCENARIO 428294] Post Phys. Inventory Order with added positive adjustment should not show error
        Initialize();

        // [GIVEN] Lot-tracked item.
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Post 20 pcs of the item to inventory, assign lot no. "L".
        LibraryVariableStorage.Enqueue(false);
        CreateLocation(Location, Item."No.", true);
        // [GIVEN] Bins: Bin1 and Bin2
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 1);
        BinCode[1] := Bin.Code;
        LibraryWarehouse.CreateBin(Bin, Location.Code, 'Bin2', '', '');
        BinCode[2] := Bin.Code;
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Positive Adjmt.", Item."No.");

        // [GIVEN] Create physical inventory order, calculate lines.
        LibraryInventory.CreatePhysInvtOrderHeader(PhysInvtOrderHeader);
        CalculatePhysInvtOrderLines(PhysInvtOrderHeader, Item."No.", '', true, true, false);

        // [GIVEN] Create phys. inventory recording for 15 pcs, select lot no. "L".
        // [GIVEN] Add additional Phys. Inventory recording with Serial No. and quantity 1.
        CreatePhysInventoryRecordingWithTracking(
          PhysInvtRecordLine[1], PhysInvtOrderHeader, PhysInvtOrderLine, Item."No.", LibraryRandom.RandInt(10));
        PhysInvtRecordHeader.Get(PhysInvtOrderHeader."No.", PhysInvtRecordLine[1]."Recording No.");
        PhysInvtRecordHeader.Validate("Allow Recording Without Order", true);
        PhysInvtRecordHeader.Modify();
        FindPhysInvtRecordingLine(PhysInvtRecordLine[1], Item."No.", BinCode[1]);
        PhysInvtRecordLine[1].Validate("Serial No.", 'SN1');
        PhysInvtRecordLine[1].Modify();

        CreatePhysInvtRecordLine(
          PhysInvtRecordLine[2], PhysInvtOrderLine, PhysInvtRecordHeader."Recording No.", 1);
        PhysInvtRecordLine[2].Validate("Location Code", PhysInvtRecordLine[1]."Location Code");
        PhysInvtRecordLine[2].Validate("Lot No.", PhysInvtRecordLine[1]."Lot No.");
        PhysInvtRecordLine[2].Validate("Bin Code", BinCode[2]);
        PhysInvtRecordLine[2].Validate("Serial No.", 'SN2');
        PhysInvtRecordLine[2].Modify();

        // [GIVEN] Finish the recording.
        FinishPhysInventoryRecording(PhysInvtRecordLine[1], PhysInvtOrderHeader."No.");

        // [GIVEN] Calculate expected quantity for added line of Phys. Inventory Order
        FindPhysInventoryOrderLine(PhysInvtOrderLine, PhysInvtOrderHeader."No.");
        PhysInvtOrderLine.Next();
        PhysInvtCalcQtyOne.Run(PhysInvtOrderLine);

        // [WHEN] Finish and post the phys. inventory order (negative adjustment for 5 pcs and positive for 1 pcs)
        FinishAndPostPhysInventoryOrder(PhysInvtOrderHeader);

        // [THEN] The physical inventory order is successfully posted.
        PstdPhysInvtOrderHeader.SetRange("Pre-Assigned No.", PhysInvtOrderHeader."No.");
        Assert.RecordCount(PstdPhysInvtOrderHeader, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CalcPhysInvtOrderLinesForItemWithoutTransactionsWithItemWithoutTransactionsLocationMandatory()
    var
        Item: Record Item;
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
    begin
        Initialize();

        // [GIVEN] Location is mandatory
        SetLocationMandatory(true);

        // [GIVEN] Item exists
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Physical Inventory Order
        LibraryInventory.CreatePhysInvtOrderHeader(PhysInvtOrderHeader);

        // [WHEN] Run report Calc. Physical Inventory Order Lines for the Item with Include Items With No Transactions enabled
        CalculatePhysInvtOrderLines(PhysInvtOrderHeader, Item."No.", '', true, true, true);

        // [THEN] Physical Inventory Order Line is created for every location without mandatory bin
        PhysInvtOrderLine.SetRange("Document No.", PhysInvtOrderHeader."No.");
        Assert.RecordCount(PhysInvtOrderLine, GetNoOfLocationsWithoutBinMandatory());

        // [THEN] Physical Inventory Order Lines are created with 0 PCS
        PhysInvtOrderLine.FindSet();
        repeat
            PhysInvtOrderLine.TestField("Qty. Expected (Base)", 0);
        until PhysInvtOrderLine.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CalcPhysInvtOrderLinesForItemWithoutTransactionsWithItemWithoutTransactionsLocationNotMandatory()
    var
        Item: Record Item;
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
    begin
        Initialize();

        // [GIVEN] Location is not mandatory
        SetLocationMandatory(false);

        // [GIVEN] Item exists
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Physical Inventory Order
        LibraryInventory.CreatePhysInvtOrderHeader(PhysInvtOrderHeader);

        // [WHEN] Run report Calc. Physical Inventory Order Lines for the Item with Include Items With No Transactions enabled
        CalculatePhysInvtOrderLines(PhysInvtOrderHeader, Item."No.", '', true, true, true);

        // [THEN] Physical Inventory Order Line is created for every location without mandatory bin + for empty location
        PhysInvtOrderLine.SetRange("Document No.", PhysInvtOrderHeader."No.");
        Assert.RecordCount(PhysInvtOrderLine, (GetNoOfLocationsWithoutBinMandatory() + 1));

        // [THEN] Physical Inventory Order Lines are created with 0 PCS
        PhysInvtOrderLine.FindSet();
        repeat
            PhysInvtOrderLine.TestField("Qty. Expected (Base)", 0);
        until PhysInvtOrderLine.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CalcPhysInvtOrderLinesForItemVariantsWithoutTransactionsWithItemVariantsWithoutTransactionsLocationMandatory()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
    begin
        Initialize();

        // [GIVEN] Location is mandatory
        SetLocationMandatory(true);

        // [GIVEN] Item exists with variant not mandatory
        LibraryInventory.CreateItem(Item);
        SetVariantMandatory(Item, false);

        // [GIVEN] Two different item variants exist
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        Clear(ItemVariant);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] Physical Inventory Order
        LibraryInventory.CreatePhysInvtOrderHeader(PhysInvtOrderHeader);

        // [WHEN] Run report Calc. Physical Inventory Order Lines for the Item with Include Item Variants With No Transactions enabled
        CalculatePhysInvtOrderLines(PhysInvtOrderHeader, Item."No.", '', true, true, true);

        // [THEN] Physical Inventory Order Lines are created for all combinations of locations and variants and for item without variant code
        PhysInvtOrderLine.SetRange("Document No.", PhysInvtOrderHeader."No.");
        Assert.RecordCount(PhysInvtOrderLine, 3 * GetNoOfLocationsWithoutBinMandatory());

        // [THEN] Physical Inventory Order Lines are created with 0 PCS
        PhysInvtOrderLine.FindSet();
        repeat
            PhysInvtOrderLine.TestField("Qty. Expected (Base)", 0);
        until PhysInvtOrderLine.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CalcPhysInvtOrderLinesForItemVariantsWithoutTransactionsWithItemVariantsWithoutTransactionsLocationNotMandatory()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
    begin
        Initialize();

        // [GIVEN] Location is mandatory
        SetLocationMandatory(false);

        // [GIVEN] Item exists with variant not mandatory
        LibraryInventory.CreateItem(Item);
        SetVariantMandatory(Item, false);

        // [GIVEN] Two different item variants exist
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        Clear(ItemVariant);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] Physical Inventory Order
        LibraryInventory.CreatePhysInvtOrderHeader(PhysInvtOrderHeader);

        // [WHEN] Run report Calc. Physical Inventory Order Lines for the Item with Include Item Variants With No Transactions enabled
        CalculatePhysInvtOrderLines(PhysInvtOrderHeader, Item."No.", '', true, true, true);

        // [THEN] Physical Inventory Order Lines are created for all combinations of locations and variants and for item without variant code + for empty location
        PhysInvtOrderLine.SetRange("Document No.", PhysInvtOrderHeader."No.");
        Assert.RecordCount(PhysInvtOrderLine, 3 * (GetNoOfLocationsWithoutBinMandatory() + 1));

        // [THEN] Physical Inventory Order Lines are created with 0 PCS
        PhysInvtOrderLine.FindSet();
        repeat
            PhysInvtOrderLine.TestField("Qty. Expected (Base)", 0);
        until PhysInvtOrderLine.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,MessageHandler')]
    procedure CalcPhysInvtOrderLinesForItemWithoutTransactionsWithItemWithTransactions()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
    begin
        Initialize();

        // [GIVEN] Location is not mandatory
        SetLocationMandatory(false);

        // [GIVEN] Item without mandatory variants with transactions exists
        CreateItemWithItemTrackingCode(Item, CreateItemTrackingCode(true, false));
        SetVariantMandatory(Item, false);
        LibraryVariableStorage.Enqueue(false);
        CreateAndPostItemJournalLine('', Item."No.", false);
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.");

        // [GIVEN] Physical Inventory Order
        LibraryInventory.CreatePhysInvtOrderHeader(PhysInvtOrderHeader);

        // [WHEN] Run report Calc. Physical Inventory Order Lines for the Item with Include Items With No Transactions enabled
        CalculatePhysInvtOrderLines(PhysInvtOrderHeader, Item."No.", '=''''', true, true, true);

        // [THEN] Physical Inventory Order Line is created with the qty. equal to created Item Ledger Entry
        PhysInvtOrderLine.SetRange("Document No.", PhysInvtOrderHeader."No.");
        Assert.RecordCount(PhysInvtOrderLine, 1);
        PhysInvtOrderLine.FindFirst();
        PhysInvtOrderLine.TestField("Qty. Expected (Base)", ItemLedgerEntry.Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CalcPhysInvtOrderLinesNotForItemWithoutTransactionsWithoutItemWithTransactionsLocationMandatory()
    var
        Item: Record Item;
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
    begin
        Initialize();

        // [GIVEN] Location is mandatory
        SetLocationMandatory(true);

        // [GIVEN] Item exists
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Physical Inventory Order
        LibraryInventory.CreatePhysInvtOrderHeader(PhysInvtOrderHeader);

        // [WHEN] Run report Calc. Physical Inventory Order Lines for the Item with Include Items With No Transactions enabled
        CalculatePhysInvtOrderLines(PhysInvtOrderHeader, Item."No.", '', true, true, false);

        // [THEN] Physical Inventory Order Line is not created
        PhysInvtOrderLine.SetRange("Document No.", PhysInvtOrderHeader."No.");
        Assert.RecordIsEmpty(PhysInvtOrderLine);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CalcPhysInvtOrderLinesNotForItemWithoutTransactionsWithoutItemWithTransactionsLocationNotMandatory()
    var
        Item: Record Item;
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
    begin
        Initialize();

        // [GIVEN] Location is not mandatory
        SetLocationMandatory(false);

        // [GIVEN] Item exists
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Physical Inventory Order
        LibraryInventory.CreatePhysInvtOrderHeader(PhysInvtOrderHeader);

        // [WHEN] Run report Calc. Physical Inventory Order Lines for the Item with Include Items With No Transactions enabled
        CalculatePhysInvtOrderLines(PhysInvtOrderHeader, Item."No.", '', true, true, false);

        // [THEN] Physical Inventory Order Line is not created
        PhysInvtOrderLine.SetRange("Document No.", PhysInvtOrderHeader."No.");
        Assert.RecordIsEmpty(PhysInvtOrderLine);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Phys. Invt. Item Tracking");
        DeleteObjectOptionsIfNeeded();
        LibraryRandom.Init();

        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Phys. Invt. Item Tracking");
        LibraryVariableStorage.Clear();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Phys. Invt. Item Tracking");
    end;

    local procedure CreateItemWithItemTrackingCode(var Item: Record Item; ItemTrackingCode: Code[10])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode);
        Item.Validate("Serial Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);
    end;

    local procedure CreateItemWithMaxLengthDescription(var Item: Record Item)
    begin
        CreateItemWithItemTrackingCode(Item, CreateItemTrackingCode(true, false)); // Item Tracking Code with Lot No is TRUE.
        Item.Validate(Description, PadStr(Item.Description, MaxStrLen(Item.Description), '0'));
        Item.Validate("Description 2", PadStr(Item."Description 2", MaxStrLen(Item."Description 2"), '0'));
        Item.Modify(true);
    end;

    local procedure CreateItemTrackingCode(LotSpecificTracking: Boolean; SNSpecificTracking: Boolean): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, SNSpecificTracking, LotSpecificTracking);
        ItemTrackingCode.Validate("SN Warehouse Tracking", SNSpecificTracking);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", LotSpecificTracking);
        ItemTrackingCode.Modify(true);
        exit(ItemTrackingCode.Code);
    end;

    local procedure CreatePhysInventoryOrderHeader(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; LocationCode: Code[10])
    begin
        PhysInvtOrderHeader.Init();
        PhysInvtOrderHeader.Insert(true);
        PhysInvtOrderHeader.Validate("Location Code", LocationCode);
        PhysInvtOrderHeader.Modify(true);
    end;

    local procedure CreatePhysInventoryLine(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; DocumentNo: Code[20]; ItemNo: Code[20])
    var
        RecRef: RecordRef;
    begin
        PhysInvtOrderLine.Init();
        PhysInvtOrderLine.Validate("Document No.", DocumentNo);
        RecRef.GetTable(PhysInvtOrderLine);
        PhysInvtOrderLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, PhysInvtOrderLine.FieldNo("Line No.")));
        PhysInvtOrderLine.Insert(true);
        PhysInvtOrderLine.Validate("Item No.", ItemNo);
        PhysInvtOrderLine.Validate("On Recording Lines", true);
        PhysInvtOrderLine.Validate("Qty. Exp. Calculated", true);
        PhysInvtOrderLine.Modify(true);
    end;

    local procedure CreateLocationAndBin(var Location: Record Location; BinMandatory: Boolean)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", BinMandatory);
        Location.Modify(true);
        if BinMandatory then
            LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 1, false);  // No. of Bins.
    end;

    local procedure CreateBinMandatoryLocationWithTwoBins(var Location: Record Location; BinCode: array[2] of Code[20])
    var
        Bin: Record Bin;
    begin
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        LibraryWarehouse.CreateBin(Bin, Location.Code, BinCode[1], '', '');
        LibraryWarehouse.CreateBin(Bin, Location.Code, BinCode[2], '', '');
    end;

    local procedure CreateLocation(var Location: Record Location; ItemNo: Code[20]; BinMandatory: Boolean)
    begin
        CreateLocationAndBin(Location, BinMandatory);
        CreateAndPostItemJournalLine(Location.Code, ItemNo, BinMandatory);
    end;

    local procedure CreateAndPostItemJournalLine(LocationCode: Code[10]; ItemNo: Code[20]; BinMandatory: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        Bin: Record Bin;
    begin
        ItemJournalLine.DeleteAll();
        SelectItemJournalBatch(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, LibraryRandom.RandInt(10) + 10);  // Large value required.
        ItemJournalLine.Validate("Location Code", LocationCode);
        if BinMandatory then begin
            LibraryWarehouse.FindBin(Bin, LocationCode, '', 1);  // Bin Index.
            ItemJournalLine.Validate("Bin Code", Bin.Code);
        end;
        ItemJournalLine.Modify(true);
        ItemJournalLine.OpenItemTrackingLines(false);  // Invokes ItemTrackingPageHandler.
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostItemJournalLineWithBinAndSN(LocationCode: Code[10]; ItemNo: Code[20]; BinCode: Code[20]; SerialNo: Code[50])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.DeleteAll();
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, BinCode, 1);
        LibraryVariableStorage.Enqueue(SerialNo); // Enqueue value for use in ItemTrackingSetSerialNoPageHandler
        ItemJournalLine.OpenItemTrackingLines(false);  // Invokes ItemTrackingPageHandler.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostItemJournalLineWithoutTracking(LocationCode: Code[10]; ItemNo: Code[20]; BinCode: Code[20]; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.DeleteAll();
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, BinCode, Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreatePhysInventoryRecordingWithTracking(var PhysInvtRecordLine: Record "Phys. Invt. Record Line"; var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        PhysInvtOrderHeader.SetRange("No.", PhysInvtOrderHeader."No.");
        REPORT.RunModal(REPORT::"Make Phys. Invt. Recording", false, false, PhysInvtOrderHeader);
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Positive Adjmt.", ItemNo);
        FindPhysInventoryOrderLine(PhysInvtOrderLine, PhysInvtOrderHeader."No.");
        PhysInvtRecordLine.Get(PhysInvtOrderLine."Document No.", 1, PhysInvtOrderLine."Line No.");  // 1 used for Recording No.
        PhysInvtRecordLine.Validate(Quantity, Quantity);  // Validate Less than Inventory Quantity.

        // Update Tracking on Phys. Inventory Recording Line.
        PhysInvtRecordLine.Validate("Serial No.", ItemLedgerEntry."Serial No.");
        PhysInvtRecordLine.Validate("Lot No.", ItemLedgerEntry."Lot No.");
        PhysInvtRecordLine.Modify(true);
    end;

    local procedure CreatePhysInventoryOrderWithRecording(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; LocationCode: Code[10]; ItemNo: Code[20])
    begin
        CreatePhysInventoryOrderHeader(PhysInvtOrderHeader, LocationCode);
        CalculatePhysInventoryLine(PhysInvtOrderHeader, LocationCode, ItemNo);
        PhysInvtOrderHeader.SetRange("No.", PhysInvtOrderHeader."No.");
        REPORT.RunModal(REPORT::"Make Phys. Invt. Recording", false, false, PhysInvtOrderHeader);
    end;

    local procedure CreatePhysInventoryOrderWithFinishedRecording(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var Item: Record Item; var Location: Record Location; ExpectedQty: Decimal; RecordedQty: Decimal)
    var
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateAndPostItemJournalLineWithoutTracking(Location.Code, Item."No.", '', ExpectedQty);
        CreatePhysInventoryOrderWithRecording(PhysInvtOrderHeader, Location.Code, Item."No.");
        FindAndUpdatePhysInvtRecordingLine(PhysInvtRecordLine, Item."No.", '', '', '', RecordedQty);
        FinishPhysInventoryRecording(PhysInvtRecordLine, PhysInvtOrderHeader."No.");  // Change Phys. Inventory Recording Status to Finished.
    end;

    local procedure CreatePhysInventoryOfSNTrackingItem(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; var Item: Record Item; var BinCode: array[2] of Code[20]; var SN: array[2] of Code[20])
    var
        Location: Record Location;
        i: Integer;
    begin
        for i := 1 to 2 do begin
            BinCode[i] := LibraryUtility.GenerateGUID() + LibraryUtility.GenerateGUID();
            SN[i] := LibraryUtility.GenerateGUID() + LibraryUtility.GenerateGUID();
        end;
        CreateItemWithItemTrackingCode(Item, CreateItemTrackingCode(false, true));
        CreateBinMandatoryLocationWithTwoBins(Location, BinCode);
        for i := 1 to 2 do
            CreateAndPostItemJournalLineWithBinAndSN(Location.Code, Item."No.", BinCode[i], SN[i]);
        CreatePhysInventoryOrderWithRecording(PhysInvtOrderHeader, Location.Code, Item."No.");
    end;

    local procedure CalculatePhysInvtOrderLines(PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; ItemNo: Code[20]; LocationFilter: Text; CalcQtyExpected: Boolean; ZeroQty: Boolean; IncludeItemWithNoTransaction: Boolean)
    var
        Item: Record Item;
        CalcPhysInvtOrderLines: Report "Calc. Phys. Invt. Order Lines";
    begin
        Item.Get(ItemNo);
        Item.SetRecFilter();
        if LocationFilter <> '' then
            Item.SetFilter("Location Filter", LocationFilter);
        Clear(CalcPhysInvtOrderLines);
        CalcPhysInvtOrderLines.SetPhysInvtOrderHeader(PhysInvtOrderHeader);
        CalcPhysInvtOrderLines.InitializeRequest(ZeroQty, CalcQtyExpected, IncludeItemWithNoTransaction);
        CalcPhysInvtOrderLines.UseRequestPage(false);
        CalcPhysInvtOrderLines.SetTableView(Item);
        CalcPhysInvtOrderLines.Run();
    end;

    local procedure RunCalcPhysInvtOrderBins(PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; Bin: Record Bin)
    var
        CalcPhysInvtOrderBins: Report "Calc. Phys. Invt. Order (Bins)";
    begin
        Bin.SetRecFilter();
        Clear(CalcPhysInvtOrderBins);
        CalcPhysInvtOrderBins.SetPhysInvtOrderHeader(PhysInvtOrderHeader);
        CalcPhysInvtOrderBins.UseRequestPage(false);
        CalcPhysInvtOrderBins.SetTableView(Bin);
        CalcPhysInvtOrderBins.Run();
    end;

    local procedure CalculatePhysInventoryLine(PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; LocationCode: Code[10]; ItemNo: Code[20])
    var
        PhysInventoryOrder: TestPage "Physical Inventory Order";
    begin
        Commit();  // COMMIT required for explicit commit used in CalculateLines - OnAction, Page 5005350 Phys. Inventory Order.
        // Enqueue value for use in CalcPhysOrderLinesRequestPageHandler.
        LibraryVariableStorage.Enqueue(LocationCode);
        LibraryVariableStorage.Enqueue(ItemNo);
        PhysInventoryOrder.OpenEdit();
        PhysInventoryOrder.FILTER.SetFilter("No.", PhysInvtOrderHeader."No.");
        PhysInventoryOrder.CalculateLines.Invoke();  // Invokes CalcPhysOrderLinesRequestPageHandler.
        CODEUNIT.Run(CODEUNIT::"Phys. Invt.-Calc. Qty. All", PhysInvtOrderHeader);
    end;

    local procedure CopyPhysInvtRecordingLine(var CopyOfPhysInvtRecordLine: Record "Phys. Invt. Record Line"; PhysInvtRecordLine: Record "Phys. Invt. Record Line")
    var
        LineNo: Integer;
    begin
        CopyOfPhysInvtRecordLine.SetRange("Order No.", PhysInvtRecordLine."Order No.");
        CopyOfPhysInvtRecordLine.SetRange("Recording No.", PhysInvtRecordLine."Recording No.");
        CopyOfPhysInvtRecordLine.FindLast();
        LineNo := CopyOfPhysInvtRecordLine."Line No." + 10000;
        Clear(CopyOfPhysInvtRecordLine);
        CopyOfPhysInvtRecordLine := PhysInvtRecordLine;
        CopyOfPhysInvtRecordLine."Line No." := LineNo;
        CopyOfPhysInvtRecordLine.Insert();
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        FindItemLedgerEntry(ItemLedgerEntry, ItemNo);
    end;

    local procedure FindPhysInventoryOrderLine(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; DocumentNo: Code[20])
    begin
        PhysInvtOrderLine.SetRange("Document No.", DocumentNo);
        PhysInvtOrderLine.FindFirst();
    end;

    local procedure FindPhysInvtRecordingLine(var PhysInvtRecordLine: Record "Phys. Invt. Record Line"; ItemNo: Code[20]; BinCode: Code[20])
    begin
        PhysInvtRecordLine.SetRange("Item No.", ItemNo);
        PhysInvtRecordLine.SetRange("Bin Code", BinCode);
        PhysInvtRecordLine.FindFirst();
    end;

    local procedure FindAndUpdatePhysInvtRecordingLine(var PhysInvtRecordLine: Record "Phys. Invt. Record Line"; ItemNo: Code[20]; OldBinCode: Code[20]; NewBinCode: Code[20]; SN: Code[20]; Quantity: Decimal)
    begin
        FindPhysInvtRecordingLine(PhysInvtRecordLine, ItemNo, OldBinCode);
        UpdatePhysInvtRecordingLine(PhysInvtRecordLine, NewBinCode, SN, Quantity);
    end;

    local procedure UpdatePhysInvtRecordingLine(PhysInvtRecordLine: Record "Phys. Invt. Record Line"; BinCode: Code[20]; SN: Code[20]; Quantity: Decimal)
    begin
        PhysInvtRecordLine.Validate("Bin Code", BinCode);
        PhysInvtRecordLine.Validate("Serial No.", SN);
        PhysInvtRecordLine.Validate(Quantity, Quantity);
        PhysInvtRecordLine.Modify(true);
    end;

    local procedure FinishAndPostPhysInventoryOrder(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header")
    begin
        CODEUNIT.Run(CODEUNIT::"Phys. Invt. Order-Finish (Y/N)", PhysInvtOrderHeader);
        CODEUNIT.Run(CODEUNIT::"Phys. Invt. Order-Post (Y/N)", PhysInvtOrderHeader);
    end;

    local procedure FinishPhysInventoryRecording(PhysInvtRecordLine: Record "Phys. Invt. Record Line"; PhysInventoryOrderHeaderNo: Code[20])
    var
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
    begin
        PhysInvtRecordHeader.Get(PhysInventoryOrderHeaderNo, PhysInvtRecordLine."Recording No.");
        CODEUNIT.Run(CODEUNIT::"Phys. Invt. Rec.-Finish (Y/N)", PhysInvtRecordHeader);
    end;

    local procedure SelectItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", '');  // Blank No Series required to avoid Document No mismatch.
        ItemJournalBatch.Modify(true);
    end;

    local procedure ShowDuplicatePhysInventoryLine(No: Code[20])
    var
        PhysInventoryOrder: TestPage "Physical Inventory Order";
    begin
        LibraryVariableStorage.Enqueue(No);
        PhysInventoryOrder.OpenEdit();
        PhysInventoryOrder.FILTER.SetFilter("No.", No);
        PhysInventoryOrder."Show &Duplicate Lines".Invoke();  // Invokes PhysInventoryOrderLinesPageHandler.
    end;

    local procedure VerifyPostedPhysInventoryOrderLine(PreAssignedNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10])
    var
        PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr";
        PstdPhysInvtOrderLine: Record "Pstd. Phys. Invt. Order Line";
    begin
        PstdPhysInvtOrderHdr.SetRange("Pre-Assigned No.", PreAssignedNo);
        PstdPhysInvtOrderHdr.FindFirst();
        PstdPhysInvtOrderLine.SetRange("Document No.", PstdPhysInvtOrderHdr."No.");
        PstdPhysInvtOrderLine.FindFirst();
        PstdPhysInvtOrderLine.TestField("Item No.", ItemNo);
        PstdPhysInvtOrderLine.TestField("Location Code", LocationCode);
    end;

    local procedure VerifyPostedPosNegQtyInOrderLine(OrderNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; PosQty: Decimal; NegQty: Decimal)
    var
        PstdPhysInvtOrderLine: Record "Pstd. Phys. Invt. Order Line";
    begin
        PstdPhysInvtOrderLine.SetRange("Document No.", OrderNo);
        PstdPhysInvtOrderLine.SetRange("Item No.", ItemNo);
        PstdPhysInvtOrderLine.SetRange("Location Code", LocationCode);
        PstdPhysInvtOrderLine.FindFirst();
        PstdPhysInvtOrderLine.TestField("Quantity (Base)", PosQty + NegQty);
        PstdPhysInvtOrderLine.TestField("Pos. Qty. (Base)", PosQty);
        PstdPhysInvtOrderLine.TestField("Neg. Qty. (Base)", NegQty);
    end;

    local procedure VerifyDescriptionOnPostedPhysInventoryOrderLine(PreAssignedNo: Code[20]; Description: Text; Description2: Text)
    var
        PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr";
        PstdPhysInvtOrderLine: Record "Pstd. Phys. Invt. Order Line";
    begin
        PstdPhysInvtOrderHdr.SetRange("Pre-Assigned No.", PreAssignedNo);
        PstdPhysInvtOrderHdr.FindFirst();

        PstdPhysInvtOrderLine.SetRange("Document No.", PstdPhysInvtOrderHdr."No.");
        PstdPhysInvtOrderLine.FindFirst();
        PstdPhysInvtOrderLine.TestField(Description, Description);
        PstdPhysInvtOrderLine.TestField("Description 2", Description2);
    end;

    local procedure VerifyDescriptionOnPostedPhysInventoryRecordingLine(Item: Record Item)
    var
        PstdPhysInvtRecordLine: Record "Pstd. Phys. Invt. Record Line";
    begin
        PstdPhysInvtRecordLine.SetRange("Item No.", Item."No.");
        PstdPhysInvtRecordLine.FindFirst();
        PstdPhysInvtRecordLine.TestField(Description, Item.Description);
        PstdPhysInvtRecordLine.TestField("Description 2", Item."Description 2");
    end;

    local procedure VerifyBinContent(Item: Record Item; LocationCode: Code[10]; BinCode: Code[20]; SerialNo: Code[50]; Quantity: Integer)
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Bin Code", BinCode);
        BinContent.SetRange("Item No.", Item."No.");
        BinContent.SetRange("Variant Code", '');
        BinContent.SetRange("Unit of Measure Code", Item."Base Unit of Measure");
        BinContent.FindFirst();
        BinContent.SetRange("Serial No. Filter", SerialNo);
        BinContent.CalcFields("Quantity (Base)");
        BinContent.TestField("Quantity (Base)", Quantity);
    end;

    local procedure CreatePhysInvtRecordLine(var PhysInvtRecordLine: Record "Phys. Invt. Record Line"; PhysInvtOrderLine: Record "Phys. Invt. Order Line"; RecordingNo: Integer; Qty: Decimal)
    begin
        PhysInvtRecordLine.Validate("Order No.", PhysInvtOrderLine."Document No.");
        PhysInvtRecordLine.Validate("Recording No.", RecordingNo);
        PhysInvtRecordLine.Validate("Line No.", LibraryUtility.GetNewRecNo(PhysInvtRecordLine, PhysInvtRecordLine.FieldNo("Line No.")));
        PhysInvtRecordLine.Validate("Item No.", PhysInvtOrderLine."Item No.");
        PhysInvtRecordLine.Validate(Quantity, Qty);
        PhysInvtRecordLine.Validate(Recorded, true);
        PhysInvtRecordLine.Insert(true);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalcPhysOrderLinesRequestPageHandler(var CalcPhysInvtOrderLines: TestRequestPage "Calc. Phys. Invt. Order Lines")
    var
        LocationFilter: Variant;
        No: Variant;
    begin
        CurrentSaveValuesId := REPORT::"Calc. Phys. Invt. Order Lines";
        LibraryVariableStorage.Dequeue(LocationFilter);
        LibraryVariableStorage.Dequeue(No);
        CalcPhysInvtOrderLines.Item.SetFilter("Location Filter", LocationFilter);
        CalcPhysInvtOrderLines.Item.SetFilter("No.", No);
        CalcPhysInvtOrderLines.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalcPhysOrderLinesBinsRequestPageHandler(var CalcPhysInvtOrderBins: TestRequestPage "Calc. Phys. Invt. Order (Bins)")
    var
        LocationCode: Variant;
        ItemFilter: Variant;
    begin
        CurrentSaveValuesId := REPORT::"Calc. Phys. Invt. Order (Bins)";
        LibraryVariableStorage.Dequeue(LocationCode);
        LibraryVariableStorage.Dequeue(ItemFilter);
        CalcPhysInvtOrderBins.Bin.SetFilter("Location Code", LocationCode);
        CalcPhysInvtOrderBins.Bin.SetFilter("Item Filter", ItemFilter);
        CalcPhysInvtOrderBins.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PhysInventoryOrderLinesPageHandler(var PhysInventoryOrderLines: TestPage "Physical Inventory Order Lines")
    var
        DocumentNo: Variant;
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);
        LibraryVariableStorage.Dequeue(DocumentNo);
        PhysInventoryOrderLines.FILTER.SetFilter("Document No.", DocumentNo);
        PhysInventoryOrderLines.Last();
        PhysInventoryOrderLines.FILTER.SetFilter("Item No.", ItemNo);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        Serial: Variant;
        SerialNo: Boolean;
    begin
        LibraryVariableStorage.Dequeue(Serial);
        SerialNo := Serial;
        if SerialNo then
            ItemTrackingLines."Assign Serial No.".Invoke() // Assign Serial No.
        else
            ItemTrackingLines."Assign Lot No.".Invoke();  // Assign Lot No.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedItemTrackingLinesPageHandler(var PostedItemTrackingLines: TestPage "Posted Item Tracking Lines")
    var
        LotNo: Variant;
        Quantity: Variant;
    begin
        LibraryVariableStorage.Dequeue(LotNo);
        LibraryVariableStorage.Dequeue(Quantity);
        PostedItemTrackingLines."Lot No.".AssertEquals(LotNo);
        PostedItemTrackingLines.Quantity.AssertEquals(Quantity);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure CalculateQuantityExpectedStrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1;  // Used for All Order Lines.
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure PostedPhysInvtOrderDiffReportHandler(var PostedPhysInvtOrderDiff: Report "Posted Phys. Invt. Order Diff.")
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerValidateText(Message: Text[1024])
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Message);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTRUE(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSetSerialNoPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Serial No.".SetValue(LibraryVariableStorage.DequeueText());
        ItemTrackingLines."Quantity (Base)".SetValue(1);
    end;

    local procedure DeleteObjectOptionsIfNeeded()
    var
        LibraryReportValidation: Codeunit "Library - Report Validation";
    begin
        LibraryReportValidation.DeleteObjectOptions(CurrentSaveValuesId);
    end;

    local procedure CreateItemWithLotTrackingAndPhysInventory(
        var PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        var BaseUOM: Record "Unit of Measure";
        var NonBaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal
    )
    var
        Location: Record Location;
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
    begin
        CreateItemWithItemTrackingCode(Item, CreateItemTrackingCode(true, false));
        LibraryVariableStorage.Enqueue(false);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, 1);

        if QtyRoundingPrecision <> 0 then begin
            ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
            ItemUOM.Modify();
        end;
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();

        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        CreateLocation(Location, Item."No.", false);
        CreatePhysInventoryOrderHeader(PhysInvtOrderHeader, Location.Code);
        CalculatePhysInventoryLine(PhysInvtOrderHeader, Location.Code, Item."No.");
        CreatePhysInventoryRecordingWithTracking(PhysInvtRecordLine, PhysInvtOrderHeader, PhysInvtOrderLine, Item."No.", 0);
    end;

    local procedure GetNoOfLocationsWithoutBinMandatory() NoOfLocations: Integer
    var
        Location: Record Location;
    begin
        if Location.FindSet() then
            repeat
                if not Location.BinMandatory(Location.Code) then
                    NoOfLocations += 1;
            until Location.Next() = 0;
    end;

    local procedure SetLocationMandatory(NewLocationMandatory: Boolean)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Location Mandatory", NewLocationMandatory);
        InventorySetup.Modify();
    end;

    local procedure SetVariantMandatory(var Item: Record Item; NewVariantMandatory: Boolean)
    begin
        if NewVariantMandatory then
            Item.Validate("Variant Mandatory if Exists", Item."Variant Mandatory if Exists"::Yes)
        else
            Item.Validate("Variant Mandatory if Exists", Item."Variant Mandatory if Exists"::No);
        Item.Modify();
    end;
}
